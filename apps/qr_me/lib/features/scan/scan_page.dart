import 'dart:async';

import 'package:camera/camera.dart' show CameraException, FlashMode, availableCameras;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/qr_palette.dart';
import '../../app/routes.dart';
import '../../data/database.dart' show QrSource;
import '../../l10n/generated/app_localizations.dart';
import '../../services/readability_check.dart';

/// La lettura: fotocamera a tutto schermo con il mirino, torcia, «Da immagine»
/// (develop_microapps.md F17.1.6). Gratis (F17.0 punto 6).
///
/// ⚑ La fotocamera e la decodifica sono di `flutter_zxing` (`ReaderWidget`: plugin `camera` +
/// ZXing C++ via FFI), su Android e su iOS. Niente ML Kit: decisione del proprietario del
/// 2026-10-09, «niente dati a Google» (F17.1.10). Del `ReaderWidget` si usano solo l'anteprima
/// e la decodifica: i suoi pulsanti (torcia, galleria, cambio fotocamera) e la sua cornice sono
/// spenti, perche' doppioni dei nostri.
///
/// ⚑ **Solo QR** (`Format.qrCode`): i codici a barre dei prodotti non sono il mestiere
/// dell'app e farebbero scattare letture accidentali inquadrando una scatola.
///
/// ⚑ Permesso negato → stato vuoto, ma «Da immagine» resta usabile: non serve la fotocamera.
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  /// La parte dell'inquadratura in cui ZXing cerca, come frazione del lato corto del fotogramma.
  /// ⚑ Piu' larga del mirino disegnato (`_Viewfinder.sideFraction`): con l'anteprima a
  /// riempimento il fotogramma deborda dallo schermo, quindi a parita' di frazione la zona letta
  /// e' gia' piu' grande del mirino; il margine in piu' perdona un QR inquadrato storto.
  static const double cropPercent = 0.8;

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  /// La fotocamera montata. ⚑ Falsa mentre e' aperta la pagina del risultato: si smonta il
  /// `ReaderWidget`, che cosi' spegne davvero la fotocamera (con la pagina coperta continuerebbe
  /// a leggere fotogrammi e a scaldare il telefono). Al ritorno si rimonta e riparte.
  bool _cameraOn = true;

  /// Cambia a ogni «Riprova»: una chiave nuova rifa' da capo il `ReaderWidget`, che richiede
  /// il permesso e riapre la fotocamera.
  int _attempt = 0;

  /// Il controller della fotocamera quando e' pronta (dal `ReaderWidget`), per la torcia.
  CameraController? _camera;

  /// Perche' la fotocamera non e' partita; `null` se va (o sta partendo).
  Object? _error;

  /// La torcia c'e' e risponde. ⚑ Si scopre solo provandola: l'emulatore e molti frontali non
  /// l'hanno, e `setFlashMode` fallisce. Al primo errore il pulsante sparisce.
  bool _torchUsable = true;
  bool _torchOn = false;

  /// ☠ Il `ReaderWidget` consegna la stessa lettura anche piu' volte (e una gia' in volo puo'
  /// arrivare dopo lo smontaggio): senza questo, una sola inquadratura aprirebbe due pagine del
  /// risultato una sopra l'altra.
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    unawaited(_checkCameras());
  }

  /// ☠ Senza nessuna fotocamera il `ReaderWidget` non segnala niente e resta nero per sempre:
  /// lo si scopre qui e si mostra lo stato d'errore.
  Future<void> _checkCameras() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty && mounted) setState(() => _error = StateError('nessuna fotocamera'));
    } on Object catch (e) {
      // L'errore vero lo riporta il ReaderWidget (onControllerCreated).
      MicroLog.w('availableCameras: $e');
    }
  }

  void _onController(CameraController? controller, Exception? error) {
    if (!mounted) return;
    setState(() {
      _camera = controller;
      _torchOn = false;
      if (error != null) {
        MicroLog.w('fotocamera: $error');
        _error = error;
      }
    });
  }

  Future<void> _toggleTorch() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    final on = !_torchOn;
    try {
      await camera.setFlashMode(on ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torchOn = on);
    } on Object catch (e) {
      MicroLog.w('torcia: $e');
      if (mounted) setState(() => _torchUsable = false);
    }
  }

  /// Spegne la fotocamera, apre il risultato e la riaccende al ritorno.
  /// [source] e' una chiave di [QrSource].
  Future<void> _showResult(String raw, String source) async {
    setState(() {
      _cameraOn = false;
      _camera = null;
      _torchOn = false;
    });
    await context.push(Routes.scanResult, extra: ScanResultArgs(raw: raw, source: source));
    // Tornati dal risultato si legge di nuovo.
    if (!mounted) return;
    setState(() => _cameraOn = true);
    _handling = false;
  }

  void _onScan(Code code) {
    if (_handling || !_cameraOn || !mounted) return;
    final raw = code.text;
    if (raw == null || raw.isEmpty) return;
    _handling = true;
    unawaited(HapticFeedback.lightImpact());
    unawaited(_showResult(raw, QrSource.scanned));
  }

  /// «Da immagine»: il selettore di sistema, poi ZXing sul file.
  Future<void> _fromImage() async {
    final l = L.of(context);
    final path = await ref.read(pickImageProvider)();
    if (path == null || !mounted) return;
    List<String> values;
    try {
      values = await ref.read(qrImageReaderProvider).read(path);
    } on QrReaderUnavailable {
      if (mounted) MicroSnack.error(context, l.scan_readerUnavailable);
      return;
    }
    if (!mounted) return;
    if (values.isEmpty) {
      MicroSnack.show(context, l.share_noQrInImage);
      return;
    }
    if (_handling) return;
    _handling = true;
    await _showResult(values.first, QrSource.image);
  }

  void _retry() {
    setState(() {
      _error = null;
      _camera = null;
      _torchUsable = true;
      _attempt++;
    });
    unawaited(_checkCameras());
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    final error = _error;
    final camera = _camera;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l.scan_title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        // ☠ Il titolo del tema ha un colore suo (`p.ink`) che vince su `foregroundColor`: nel
        // tema chiaro era quasi nero su nero (visto sull'emulatore in F17.7). Bianco esplicito.
        titleTextStyle: p.title(size: 20, color: Colors.white),
        actions: [
          if (error == null &&
              camera != null &&
              _torchUsable &&
              camera.description.lensDirection == CameraLensDirection.back)
            IconButton(
              tooltip: l.scan_torch,
              icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
              onPressed: () => unawaited(_toggleTorch()),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (error != null)
            _ScanError(error: error, onRetry: _retry)
          else if (_cameraOn)
            ReaderWidget(
              key: ValueKey(_attempt),
              onScan: _onScan,
              onControllerCreated: _onController,
              codeFormat: Format.qrCode,
              // ⚑ QR chiari su fondo scuro si incontrano (adesivi, schermi in tema scuro): li
              // si legge. Il secondo tentativo, invertito, scatta solo se il primo fallisce.
              tryInverted: true,
              cropPercent: ScanPage.cropPercent,
              resolution: ResolutionPreset.high,
              lensDirection: CameraLensDirection.back,
              // Doppioni dei nostri: la cornice e' `_Viewfinder`, la torcia sta nella barra,
              // la galleria e' «Da immagine» (che passa da qrImageReaderProvider).
              showScannerOverlay: false,
              showFlashlight: false,
              showGallery: false,
              showToggleCamera: false,
              // ⚑ Dopo una lettura non serve una pausa: la pagina smonta la fotocamera da se'.
              scanDelaySuccess: Duration.zero,
              // Fra un fotogramma senza QR e il successivo: reattivo senza bruciare batteria.
              scanDelay: const Duration(milliseconds: 150),
            ),
          // ⚑ Mirino e «Inquadra il QR» solo con la fotocamera: sopra lo stato del permesso
          // negato (visto sull'emulatore) gli angoli incorniciavano il messaggio d'errore.
          if (error == null)
            IgnorePointer(
              child: CustomPaint(painter: _Viewfinder(color: p.accent)),
            ),
          Positioned(
            left: MicroSpacing.l,
            right: MicroSpacing.l,
            bottom: MicroSpacing.xl,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: MicroSpacing.m),
                      child: Text(
                        l.scan_hint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  FilledButton.icon(
                    key: const ValueKey('scan_fromImage'),
                    onPressed: () => unawaited(_fromImage()),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l.scan_fromImage),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La fotocamera non parte: permesso negato o nessuna fotocamera.
class _ScanError extends StatelessWidget {
  const _ScanError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  /// Permesso negato: `CameraAccessDenied` su Android (CameraX) e iOS, piu' la variante di iOS
  /// `CameraAccessDeniedWithoutPrompt` (negato in passato: il sistema non lo richiede piu').
  /// ⚑ Per prefisso: i codici sono stringhe dei plugin, non un enum.
  static bool isDenied(Object error) =>
      error is CameraException && error.code.startsWith('CameraAccessDenied');

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final denied = isDenied(error);
    // ⚑ «Apri le impostazioni» solo su iOS (`app-settings:`): su Android aprire la pagina dei
    // permessi dell'app richiede un plugin in piu' (permission_handler) per un solo pulsante.
    // Li' «Riprova» richiede di nuovo il permesso, se il sistema lo consente ancora.
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: MicroEmptyState(
        icon: Icons.no_photography_outlined,
        title: denied ? l.scan_deniedTitle : l.scan_errorTitle,
        message: denied ? l.scan_deniedBody : l.scan_errorBody,
        actionLabel: denied && ios ? l.scan_openSettings : l.common_retry,
        onAction: denied && ios ? () => unawaited(launchUrl(Uri.parse('app-settings:'))) : onRetry,
      ),
    );
  }
}

/// Il mirino: quattro angoli verdi attorno a un quadrato centrale.
class _Viewfinder extends CustomPainter {
  const _Viewfinder({required this.color});

  final Color color;

  /// Il lato del mirino, come frazione del lato corto dello schermo. ⚑ Minore di
  /// `ScanPage.cropPercent`: la zona in cui ZXing cerca deve contenere il mirino.
  static const double sideFraction = 0.66;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * sideFraction;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero) - const Offset(0, 40),
      width: side,
      height: side,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final arm = side * 0.14;
    for (final (corner, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(corner, corner + Offset(arm * dx, 0), paint)
        ..drawLine(corner, corner + Offset(0, arm * dy), paint);
    }
  }

  @override
  bool shouldRepaint(_Viewfinder old) => old.color != color;
}

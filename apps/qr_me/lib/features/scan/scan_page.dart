import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
/// ⚑ **Solo QR** (`BarcodeFormat.qrCode`): i codici a barre dei prodotti non sono il mestiere
/// dell'app e farebbero scattare letture accidentali inquadrando una scatola.
///
/// ⚑ Permesso negato → stato vuoto, ma «Da immagine» resta usabile: non serve la fotocamera.
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  /// ☠ Lo scanner consegna la stessa lettura piu' volte al secondo: senza questo, una sola
  /// inquadratura aprirebbe tre pagine del risultato una sopra l'altra.
  bool _handling = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .firstOrNull;
    if (raw == null) return;
    _handling = true;
    unawaited(HapticFeedback.lightImpact());
    await _controller.stop();
    if (!mounted) return;
    await context.push(
      Routes.scanResult,
      extra: ScanResultArgs(raw: raw, source: QrSource.scanned),
    );
    // Tornati dal risultato si legge di nuovo.
    if (!mounted) return;
    _handling = false;
    await _controller.start();
  }

  /// «Da immagine»: il selettore di sistema, poi lo scanner sul file.
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
    await _controller.stop();
    if (!mounted) return;
    await context.push(
      Routes.scanResult,
      extra: ScanResultArgs(raw: values.first, source: QrSource.image),
    );
    if (mounted) await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = QrPalette.of(context);
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
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) => switch (state.torchState) {
              TorchState.unavailable => const SizedBox.shrink(),
              final torch => IconButton(
                tooltip: l.scan_torch,
                icon: Icon(torch == TorchState.on ? Icons.flash_on : Icons.flash_off),
                onPressed: () => unawaited(_controller.toggleTorch()),
              ),
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (c) => unawaited(_onDetect(c)),
            errorBuilder: (context, error) =>
                _ScanError(error: error, onRetry: () => unawaited(_controller.start())),
          ),
          // ⚑ Mirino e «Inquadra il QR» solo con la fotocamera accesa: sopra lo stato del
          // permesso negato (visto sull'emulatore) gli angoli incorniciavano il messaggio d'errore.
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) => state.error != null
                ? const SizedBox.shrink()
                : IgnorePointer(
                    child: CustomPaint(painter: _Viewfinder(color: p.accent)),
                  ),
          ),
          Positioned(
            left: MicroSpacing.l,
            right: MicroSpacing.l,
            bottom: MicroSpacing.xl,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (context, state, _) => state.error != null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: MicroSpacing.m),
                            child: Text(
                              l.scan_hint,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
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

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
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

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * 0.66;
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

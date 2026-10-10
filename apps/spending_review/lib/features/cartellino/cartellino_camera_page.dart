import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/sr_palette.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/fotocamera.dart';
import '../../services/lettura_service.dart';
import '../common/mirino.dart';

/// Cosa legge il mirino: un cartellino o l'etichetta della bilancia.
enum ModoLettura { cartellino, bilancia }

/// Il mirino del cartellino (develop_microapps.md F12.1.12, `/cartellino`).
///
/// - Anteprima a tutto schermo, **mirino orizzontale** al centro (86% della larghezza, 4:3: i
///   cartellini sono larghi), angoli verdi, velo nero al 55% fuori. «Inquadra un cartellino, da
///   vicino». Primo uso: «Lo scritto a mano non lo leggo» (una volta).
/// - Interruttore **Cartellino | Bilancia** (default Cartellino). ⚑ Un'etichetta della bilancia si
///   riconosce da sola anche in modo Cartellino (`LetturaService.cartellino`): l'interruttore serve
///   solo a forzare. Niente terzo tasto sulla pagina della spesa (F12.0 punto 4).
/// - Scatto 72 dp, torcia a sinistra (sparisce al primo errore), «Da una foto» a destra.
/// - Allo scatto: foto → ritaglio al mirino (isolate) → lettura, con «Leggo…» sul mirino; la
///   fotocamera resta **montata**. Il risultato torna con `pop(RisultatoCartellino)`.
/// ☠ Le foto si cancellano: l'originale nel ritaglio, il ritaglio nella lettura (F12.1.13).
class CartellinoCameraPage extends ConsumerStatefulWidget {
  const CartellinoCameraPage({this.modoIniziale = ModoLettura.cartellino, super.key});

  final ModoLettura modoIniziale;

  /// Il mirino del cartellino: 86% della larghezza, 4:3.
  static Rect mirino(Size area) => rettangoloMirino(area, larghezza: 0.86, rapporto: 4 / 3);

  @override
  ConsumerState<CartellinoCameraPage> createState() => _CartellinoCameraPageState();
}

class _CartellinoCameraPageState extends ConsumerState<CartellinoCameraPage> {
  late ModoLettura _modo = widget.modoIniziale;
  Obiettivo? _obiettivo;
  bool _pronta = false;
  Object? _errore;
  bool _leggo = false;
  bool _torciaUsabile = true;
  bool _torcia = false;
  bool _attesaImpostazioni = false;
  Size? _area;
  late final AppLifecycleListener _ciclo;

  @override
  void initState() {
    super.initState();
    // ☠ Si riprova solo al ritorno dalle impostazioni, non a ogni ripresa: il dialogo del permesso
    // stesso mette l'attivita' in pausa, e un «riprova a ogni ripresa» lo richiederebbe in un giro
    // senza fine (lezione di QR Me).
    _ciclo = AppLifecycleListener(
      onResume: () {
        if (!_attesaImpostazioni || !mounted) return;
        _attesaImpostazioni = false;
        if (_errore != null) unawaited(_apri());
      },
    );
    unawaited(_apri());
  }

  @override
  void dispose() {
    _ciclo.dispose();
    unawaited(_obiettivo?.chiudi());
    super.dispose();
  }

  Future<void> _apri() async {
    await _obiettivo?.chiudi();
    final o = ref.read(obiettivoProvider)();
    setState(() {
      _obiettivo = o;
      _pronta = false;
      _errore = null;
      _torciaUsabile = true;
      _torcia = false;
    });
    try {
      await o.apri();
      if (mounted) setState(() => _pronta = true);
    } on Object catch (e) {
      MicroLog.w('fotocamera: $e');
      if (mounted) setState(() => _errore = e);
    }
  }

  Future<void> _torciaCambia() async {
    final o = _obiettivo;
    if (o == null) return;
    final ok = await o.torcia(!_torcia);
    if (!mounted) return;
    setState(() {
      if (ok) {
        _torcia = !_torcia;
      } else {
        _torciaUsabile = false;
      }
    });
  }

  void _suggerimentoVisto() {
    if (!ref.read(suggerimentoMirinoVistoProvider)) {
      unawaited(ref.read(suggerimentoMirinoVistoProvider.notifier).set(true));
    }
  }

  Future<void> _scatta() async {
    final o = _obiettivo;
    final area = _area;
    if (o == null || area == null || _leggo || !_pronta) return;
    setState(() => _leggo = true);
    _suggerimentoVisto();
    try {
      final foto = await o.scatta();
      final ritaglio = await ref.read(ritaglioProvider)(
        foto,
        inFrazioni(CartellinoCameraPage.mirino(area), area),
        anteprima: area,
      );
      await _leggi(ritaglio);
    } on Object catch (e) {
      MicroLog.w('scatto del cartellino: $e');
      if (mounted) MicroSnack.error(context, L.of(context).cartellino_scattoFallito);
    } finally {
      if (mounted) setState(() => _leggo = false);
    }
  }

  Future<void> _daUnaFoto() async {
    if (_leggo) return;
    final percorsi = await ref.read(scegliFotoProvider)(multiple: false);
    if (percorsi.isEmpty || !mounted) return;
    setState(() => _leggo = true);
    try {
      await _leggi(percorsi.first);
    } finally {
      if (mounted) setState(() => _leggo = false);
    }
  }

  Future<void> _leggi(String percorso) async {
    final r = await ref.read(letturaServiceProvider).cartellino(percorso, forzaBilancia: _modo == ModoLettura.bilancia);
    if (!mounted) return;
    context.pop<RisultatoCartellino>(r);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final errore = _errore;
    final o = _obiettivo;
    final suggerimento = !ref.watch(suggerimentoMirinoVistoProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_modo == ModoLettura.cartellino ? l.cartellino_titolo : l.bilancia_titolo,
            style: const TextStyle(color: Colors.white)),
      ),
      body: LayoutBuilder(
        builder: (context, vincoli) {
          final area = Size(vincoli.maxWidth, vincoli.maxHeight);
          _area = area;
          final mirino = CartellinoCameraPage.mirino(area);
          return Stack(
            fit: StackFit.expand,
            children: [
              // ⚑ L'errore lascia libera la fascia in basso: «Da una foto» resta sul nero, leggibile
              // anche col tema chiaro, e usabile senza fotocamera.
              if (errore != null)
                Positioned.fill(
                  bottom: 150,
                  child: ErroreFotocamera(
                    errore: errore,
                    onRiprova: () => unawaited(_apri()),
                    onImpostazioni: () async =>
                        _attesaImpostazioni = await ref.read(impostazioniSistemaProvider).apri(),
                  ),
                )
              else if (o != null && _pronta)
                Positioned.fill(child: o.anteprima()),
              if (errore == null) ...[
                IgnorePointer(child: CustomPaint(painter: PittoreMirino(mirino: mirino, colore: p.accento))),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 12,
                  child: Center(
                    child: SegmentedButton<ModoLettura>(
                      key: const ValueKey('cartellino_modo'),
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                        foregroundColor: Colors.white,
                        selectedBackgroundColor: p.accento,
                        selectedForegroundColor: p.suAccento,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      segments: [
                        ButtonSegment(value: ModoLettura.cartellino, label: Text(l.cartellino_modoCartellino)),
                        ButtonSegment(value: ModoLettura.bilancia, label: Text(l.cartellino_modoBilancia)),
                      ],
                      selected: {_modo},
                      onSelectionChanged: (s) => setState(() => _modo = s.first),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: mirino.bottom + 12,
                  child: Column(
                    children: [
                      Text(
                        _modo == ModoLettura.cartellino ? l.cartellino_inquadra : l.bilancia_inquadra,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      if (suggerimento) ...[
                        const SizedBox(height: 8),
                        Text(
                          l.cartellino_scrittoAMano,
                          key: const ValueKey('cartellino_suggerimento'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_leggo)
                  Positioned.fromRect(
                    rect: mirino,
                    child: Center(
                      child: Container(
                        key: const ValueKey('cartellino_leggo'),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(24)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p.accento)),
                            const SizedBox(width: 10),
                            Text(l.cartellino_leggo, style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
              Positioned(
                left: 8,
                right: 8,
                bottom: 12,
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 84,
                        child: (errore == null && _pronta && _torciaUsabile)
                            ? BottoneTondo(
                                key: const ValueKey('cartellino_torcia'),
                                icona: _torcia ? Icons.flash_on : Icons.flash_off,
                                etichetta: l.fotocamera_torcia,
                                onTap: () => unawaited(_torciaCambia()),
                              )
                            : null,
                      ),
                      BottoneScatto(
                        key: const ValueKey('cartellino_scatta'),
                        semantica: l.fotocamera_scatta,
                        colore: p.accento,
                        onTap: (errore == null && _pronta && !_leggo) ? () => unawaited(_scatta()) : null,
                      ),
                      BottoneTondo(
                        key: const ValueKey('cartellino_daFoto'),
                        icona: Icons.photo_library_outlined,
                        etichetta: l.fotocamera_daFoto,
                        onTap: _leggo ? null : () => unawaited(_daUnaFoto()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

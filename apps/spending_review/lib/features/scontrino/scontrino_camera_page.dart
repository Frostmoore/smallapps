import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/micro_ocr.dart' show OcrNonDisponibile;

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/sr_palette.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/fotocamera.dart';
import '../common/mirino.dart';

/// Lo scontrino (develop_microapps.md F12.1.12, `/scontrino`, **Pro**: la rotta e' avvolta in
/// `ProGate(FeatureKey.documentScan)`).
///
/// - Mirino **verticale** (88% della larghezza, 3:5): «Inquadra lo scontrino dritto, tutto in
///   larghezza».
/// - Dopo lo scatto: le miniature e due bottoni, **Leggi** e **Aggiungi un pezzo**. ⚑ Fino a
///   **4** foto dello stesso scontrino, dall'alto in basso: uno scontrino di 40 righe in una foto
///   sola ha i caratteri troppo piccoli; `UnisciParti` toglie le righe ripetute fra un pezzo e
///   l'altro.
/// - «Da una foto»: anche piu' foto insieme (lo scontrino lungo lo si fotografa a casa con calma).
/// - **Leggi** → `LetturaService.scontrino` → con una spesa contata il **confronto**, altrimenti la
///   **registrazione** dallo scontrino (F12.0 punto 4: entrambe le cose).
/// ☠ Le foto non lette si cancellano all'uscita dalla pagina; quelle lette le cancella la lettura.
class ScontrinoCameraPage extends ConsumerStatefulWidget {
  const ScontrinoCameraPage({super.key});

  /// Il massimo dei pezzi di uno scontrino.
  static const int massimoParti = 4;

  /// Il mirino dello scontrino: 88% della larghezza, 3:5.
  static Rect mirino(Size area) => rettangoloMirino(area, larghezza: 0.88, rapporto: 3 / 5, alzato: 60);

  @override
  ConsumerState<ScontrinoCameraPage> createState() => _ScontrinoCameraPageState();
}

class _ScontrinoCameraPageState extends ConsumerState<ScontrinoCameraPage> {
  Obiettivo? _obiettivo;
  bool _pronta = false;
  Object? _errore;
  bool _lavoro = false;
  bool _attesaImpostazioni = false;
  bool _torciaUsabile = true;
  bool _torcia = false;
  Size? _area;

  /// I pezzi gia' fotografati (ritagliati), in ordine.
  final List<String> _parti = [];

  /// Si sta inquadrando (true) o si guardano i pezzi fatti (false).
  bool _inScatto = true;
  late final AppLifecycleListener _ciclo;

  @override
  void initState() {
    super.initState();
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
    // ☠ I pezzi non letti (si esce senza «Leggi») non restano sul telefono.
    for (final f in _parti) {
      unawaited(Fotocamera.cancellaSeEsiste(f));
    }
    super.dispose();
  }

  Future<void> _apri() async {
    await _obiettivo?.chiudi();
    final o = ref.read(obiettivoProvider)();
    setState(() {
      _obiettivo = o;
      _pronta = false;
      _errore = null;
    });
    try {
      await o.apri();
      if (mounted) setState(() => _pronta = true);
    } on Object catch (e) {
      MicroLog.w('fotocamera dello scontrino: $e');
      if (mounted) setState(() => _errore = e);
    }
  }

  Future<void> _scatta() async {
    final o = _obiettivo;
    final area = _area;
    if (o == null || area == null || _lavoro || !_pronta) return;
    setState(() => _lavoro = true);
    try {
      final foto = await o.scatta();
      final ritaglio = await ref.read(ritaglioProvider)(
        foto,
        inFrazioni(ScontrinoCameraPage.mirino(area), area),
        anteprima: area,
      );
      if (!mounted) {
        await Fotocamera.cancellaSeEsiste(ritaglio);
        return;
      }
      setState(() {
        _parti.add(ritaglio);
        _inScatto = false;
      });
    } on Object catch (e) {
      MicroLog.w('scatto dello scontrino: $e');
      if (mounted) MicroSnack.error(context, L.of(context).cartellino_scattoFallito);
    } finally {
      if (mounted) setState(() => _lavoro = false);
    }
  }

  Future<void> _daFoto() async {
    if (_lavoro) return;
    final scelte = await ref.read(scegliFotoProvider)(multiple: true);
    if (scelte.isEmpty || !mounted) return;
    final posto = ScontrinoCameraPage.massimoParti - _parti.length;
    for (final extra in scelte.skip(posto)) {
      unawaited(Fotocamera.cancellaSeEsiste(extra));
    }
    setState(() {
      _parti.addAll(scelte.take(posto));
      _inScatto = false;
    });
  }

  void _togli(int i) {
    final f = _parti.removeAt(i);
    unawaited(Fotocamera.cancellaSeEsiste(f));
    setState(() => _inScatto = _parti.isEmpty);
  }

  Future<void> _leggi() async {
    if (_parti.isEmpty || _lavoro) return;
    final l = L.of(context);
    setState(() => _lavoro = true);
    final parti = List.of(_parti);
    // La lettura le cancella: non vanno cancellate due volte all'uscita.
    _parti.clear();
    try {
      final letto = await ref.read(letturaServiceProvider).scontrino(parti);
      if (!mounted) return;
      if (letto.lettura.righe.isEmpty && letto.lettura.totale == null) {
        MicroSnack.show(context, l.scontrino_nienteLetto, icon: Icons.receipt_long_outlined);
        setState(() => _inScatto = true);
        return;
      }
      final contate = ref.read(spesaInCorsoProvider).value?.righe ?? const [];
      context.pushReplacement(contate.isNotEmpty ? Routes.confronto : Routes.registra, extra: letto);
    } on OcrNonDisponibile {
      if (mounted) MicroSnack.error(context, l.scontrino_ocrAssente);
    } on Object catch (e) {
      MicroLog.w('lettura dello scontrino: $e');
      if (mounted) MicroSnack.error(context, l.scontrino_nienteLetto);
    } finally {
      if (mounted) setState(() => _lavoro = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final errore = _errore;
    final o = _obiettivo;
    final pieno = _parti.length >= ScontrinoCameraPage.massimoParti;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _parti.isEmpty ? l.scontrino_titolo : l.scontrino_titoloParti(_parti.length),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, vincoli) {
          final area = Size(vincoli.maxWidth, vincoli.maxHeight);
          _area = area;
          final mirino = ScontrinoCameraPage.mirino(area);
          final inScatto = _inScatto && !pieno;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (errore != null)
                Positioned.fill(
                  bottom: 170,
                  child: ErroreFotocamera(
                    errore: errore,
                    onRiprova: () => unawaited(_apri()),
                    onImpostazioni: () async =>
                        _attesaImpostazioni = await ref.read(impostazioniSistemaProvider).apri(),
                  ),
                )
              else if (o != null && _pronta && inScatto)
                Positioned.fill(child: o.anteprima()),
              if (errore == null && inScatto) ...[
                IgnorePointer(child: CustomPaint(painter: PittoreMirino(mirino: mirino, colore: p.accento))),
                Positioned(
                  left: 24,
                  right: 24,
                  top: 12,
                  child: Text(
                    _parti.isEmpty ? l.scontrino_inquadra : l.scontrino_inquadraPezzo(_parti.length + 1),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              if (!inScatto)
                Positioned.fill(
                  bottom: 170,
                  child: _Pezzi(parti: _parti, onTogli: _togli),
                ),
              if (_lavoro)
                Center(
                  child: Container(
                    key: const ValueKey('scontrino_lavoro'),
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
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: SafeArea(
                  top: false,
                  child: inScatto
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: 84,
                              child: (errore == null && _pronta && _torciaUsabile)
                                  ? BottoneTondo(
                                      icona: _torcia ? Icons.flash_on : Icons.flash_off,
                                      etichetta: l.fotocamera_torcia,
                                      onTap: () async {
                                        final ok = await o?.torcia(!_torcia) ?? false;
                                        if (!mounted) return;
                                        setState(() {
                                          if (ok) {
                                            _torcia = !_torcia;
                                          } else {
                                            _torciaUsabile = false;
                                          }
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            BottoneScatto(
                              key: const ValueKey('scontrino_scatta'),
                              semantica: l.fotocamera_scatta,
                              colore: p.accento,
                              onTap: (errore == null && _pronta && !_lavoro) ? () => unawaited(_scatta()) : null,
                            ),
                            BottoneTondo(
                              key: const ValueKey('scontrino_daFoto'),
                              icona: Icons.photo_library_outlined,
                              etichetta: l.fotocamera_daFoto,
                              onTap: _lavoro ? null : () => unawaited(_daFoto()),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton.icon(
                              key: const ValueKey('scontrino_leggi'),
                              onPressed: _lavoro || _parti.isEmpty ? null : () => unawaited(_leggi()),
                              icon: const Icon(Icons.document_scanner_outlined),
                              label: Text(l.scontrino_leggi),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              key: const ValueKey('scontrino_aggiungiPezzo'),
                              onPressed: _lavoro || pieno ? null : () => setState(() => _inScatto = true),
                              icon: const Icon(Icons.add_a_photo_outlined),
                              label: Text(pieno ? l.scontrino_massimoPezzi(ScontrinoCameraPage.massimoParti) : l.scontrino_aggiungiPezzo),
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

/// Le miniature dei pezzi fotografati, nell'ordine, con la X per toglierne uno.
class _Pezzi extends StatelessWidget {
  const _Pezzi({required this.parti, required this.onTogli});

  final List<String> parti;
  final ValueChanged<int> onTogli;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final (i, f) in parti.indexed)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                // ⚑ F12.7: il Center allenta la larghezza imposta da Expanded, cosi' lo Stack prende
                // la misura della FOTO (contain, stretta e alta per uno scontrino) e non della
                // cella: prima la X stava nell'angolo della cella, lontana dalla foto stretta.
                child: Center(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(f),
                          key: ValueKey('scontrino_pezzo_$i'),
                          fit: BoxFit.contain,
                          cacheWidth: 400,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: Colors.white10,
                            alignment: Alignment.center,
                            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 28)),
                          ),
                        ),
                      ),
                      Positioned(
                        // Dentro la foto, non a cavallo del bordo: fuori dallo Stack il tocco non arriva.
                        top: 0,
                        right: 0,
                        child: IconButton.filledTonal(
                          tooltip: l.scontrino_togliPezzo(i + 1),
                          onPressed: () => onTogli(i),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

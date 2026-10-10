import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/micro_ocr.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../app/sr_palette.dart';
import '../../domain/lettura/bilancia_parser.dart';
import '../../domain/lettura/cartellino_parser.dart';
import '../../domain/lettura/scontrino_parser.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/fotocamera.dart';
import '../common/una_mano.dart';

/// La pagina di sviluppo dell'OCR (develop_microapps.md F12.1.12, `/dev/ocr`), **solo** se
/// `kDebugMode` o `--dart-define=SR_DEV=true` (`rottaDevAttiva`): in release la rotta non esiste,
/// e `main` si ferma se una release e' compilata con SR_DEV.
///
/// Scatta o sceglie una foto, mostra le righe lette con i riquadri disegnati sopra, il risultato
/// dei tre parser, e **«Esporta fixture»**: un JSON nel formato di F12.1.17 (righe e riquadri,
/// **senza immagine**) condiviso con `share_plus`. ⚑ E' lo strumento per raccogliere le fixture di
/// **Vision** dall'iPad e quelle delle foto vere del proprietario (F12.7).
/// ☠ Qui la foto resta finche' si e' nella pagina (va mostrata), e si cancella all'uscita. Nella
/// fixture la `verita'` e' vuota: si scrive a mano, e il nome del campione si sceglie prima di
/// copiarla nella cartella del banco.
class OcrDevPage extends ConsumerStatefulWidget {
  const OcrDevPage({super.key});

  @override
  ConsumerState<OcrDevPage> createState() => _OcrDevPageState();
}

enum _Tipo { cartellino, bilancia, scontrino }

class _OcrDevPageState extends ConsumerState<OcrDevPage> {
  String? _foto;
  ui.Size? _dimensione;
  List<RigaOcr> _righe = const [];
  _Tipo _tipo = _Tipo.cartellino;
  bool _lavoro = false;
  String? _errore;
  Duration? _tempo;

  @override
  void dispose() {
    final f = _foto;
    if (f != null) unawaited(Fotocamera.cancellaSeEsiste(f));
    super.dispose();
  }

  Future<void> _prendi({required bool fotocamera}) async {
    final String? percorso;
    if (fotocamera) {
      percorso = (await ImagePicker().pickImage(source: ImageSource.camera))?.path;
    } else {
      final scelte = await ref.read(scegliFotoProvider)(multiple: false);
      percorso = scelte.isEmpty ? null : scelte.first;
    }
    if (percorso == null || !mounted) return;
    final vecchia = _foto;
    if (vecchia != null) unawaited(Fotocamera.cancellaSeEsiste(vecchia));
    final bytes = await File(percorso).readAsBytes();
    final immagine = await decodeImageFromList(bytes);
    setState(() {
      _foto = percorso;
      _dimensione = ui.Size(immagine.width.toDouble(), immagine.height.toDouble());
      _righe = const [];
      _errore = null;
    });
    immagine.dispose();
    await _leggi();
  }

  Future<void> _leggi() async {
    final f = _foto;
    if (f == null) return;
    setState(() => _lavoro = true);
    final cronometro = Stopwatch()..start();
    try {
      final righe = await ref
          .read(ocrEngineProvider)
          .leggi(f, modo: _tipo == _Tipo.scontrino ? OcrModo.scontrino : OcrModo.cartellino);
      if (mounted) setState(() => _righe = righe);
    } on Object catch (e) {
      if (mounted) setState(() => _errore = '$e');
    } finally {
      cronometro.stop();
      if (mounted) {
        setState(() {
          _lavoro = false;
          _tempo = cronometro.elapsed;
        });
      }
    }
  }

  Future<void> _esporta() async {
    final f = _foto;
    if (f == null) return;
    final motore = await ref.read(ocrEngineProvider).nome();
    final nome = p.basenameWithoutExtension(f);
    final json = const JsonEncoder.withIndent(' ').convert({
      'campione': p.basename(f),
      'tipo': _tipo.name,
      'licenza': '',
      'motore': motore,
      'creato': CivilDate.fromDateTime(DateTime.now()).toIso(),
      'righe': [for (final r in _righe) r.toJson()],
      'verita': <Object>[],
    });
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'fixture_$nome.json'));
    await file.writeAsString(json);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'application/json')]));
  }

  String _risultati() {
    final buffer = StringBuffer();
    buffer.writeln('cartellino: ${const CartellinoParser().interpreta(_righe).proposte}');
    buffer.writeln('bilancia riconosciuta: ${const BilanciaParser().riconosce(_righe)}');
    buffer.writeln('bilancia: ${const BilanciaParser().interpreta(_righe)}');
    final s = const ScontrinoParser().interpreta(_righe);
    buffer.writeln('scontrino: negozio ${s.negozioMostrato}, data ${s.data}, totale ${s.totale}, '
        'righe ${s.righe.length}, quadra ${s.quadra}, ignorate ${s.righeIgnorate}');
    for (final r in s.righe) {
      buffer.writeln('  $r');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final pal = SrPalette.of(context);
    final f = _foto;
    final dim = _dimensione;
    return PaginaUnaMano(
      titolo: l.dev_titolo,
      corpo: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<_Tipo>(
            segments: [for (final t in _Tipo.values) ButtonSegment(value: t, label: Text(t.name))],
            selected: {_tipo},
            onSelectionChanged: (s) {
              setState(() => _tipo = s.first);
              unawaited(_leggi());
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _lavoro ? null : () => unawaited(_prendi(fotocamera: true)),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l.fotocamera_scatta),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _lavoro ? null : () => unawaited(_prendi(fotocamera: false)),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l.fotocamera_daFoto),
                ),
              ),
            ],
          ),
          if (_lavoro) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          if (_errore != null) Padding(padding: const EdgeInsets.all(8), child: Text(_errore!, style: TextStyle(color: pal.rosso))),
          if (f != null && dim != null) ...[
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: dim.width / dim.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(f), fit: BoxFit.fill),
                  CustomPaint(painter: _Riquadri(_righe, pal.accento)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('${_righe.length} righe · ${_tempo?.inMilliseconds ?? 0} ms', style: stileEtichetta(pal)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _righe.isEmpty ? null : () => unawaited(_esporta()),
              icon: const Icon(Icons.ios_share),
              label: Text(l.dev_esporta),
            ),
            const SizedBox(height: 12),
            SelectableText(_risultati(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(height: 12),
            for (final r in _righe)
              Text('${r.testo}   (c ${r.confidenza.toStringAsFixed(2)})', style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _Riquadri extends CustomPainter {
  _Riquadri(this.righe, this.colore);

  final List<RigaOcr> righe;
  final Color colore;

  @override
  void paint(Canvas canvas, Size size) {
    final tratto = Paint()
      ..color = colore
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final r in righe) {
      final q = r.riquadro;
      canvas.drawRect(
        Rect.fromLTWH(q.sinistra * size.width, q.alto * size.height, q.larghezza * size.width, q.altezza * size.height),
        tratto,
      );
    }
  }

  @override
  bool shouldRepaint(_Riquadri old) => old.righe != righe;
}

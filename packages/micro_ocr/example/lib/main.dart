// App di prova di micro_ocr (F12.2b): legge tutte le immagini di una cartella con il motore
// vero della piattaforma (Android PP-OCRv5/ORT 1.28.0, iOS Vision) e mostra testo e tempi.
//
// La cartella si passa con --dart-define=F12_DIR=...; di default quella dell'app sullo
// storage esterno di Android, dove `adb push` arriva senza permessi:
//   adb push foto.jpg /sdcard/Android/data/com.smp.micro_ocr_example/files/f12/
// ☠ Le foto dei campioni NON vanno nel repo (licenze e dati personali): solo push temporanei.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:micro_ocr/micro_ocr.dart';

const cartellaDefault = String.fromEnvironment(
  'F12_DIR',
  defaultValue: '/data/user/0/com.smp.micro_ocr_example/files/f12',
);

void main() => runApp(const EsempioApp());

/// Una lettura: nome del file, millisecondi, righe.
class Lettura {
  const Lettura(this.file, this.ms, this.righe);
  final String file;
  final int ms;
  final List<RigaOcr> righe;
}

/// Legge ogni .jpg/.png di [cartella] (ordine alfabetico): i nomi che iniziano con "s" in modo
/// scontrino, gli altri cartellino. Stampa una riga `MICRO_OCR|<json>` per immagine, che il
/// banco di parita' raccoglie dal log.
Future<List<Lettura>> leggiCartella(OcrEngine motore, String cartella) async {
  final dir = Directory(cartella);
  if (!dir.existsSync()) return const [];
  final file =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => RegExp(r'\.(jpe?g|png)$', caseSensitive: false).hasMatch(f.path))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final out = <Lettura>[];
  for (final f in file) {
    final nome = f.uri.pathSegments.last;
    final modo = nome.startsWith('s') ? OcrModo.scontrino : OcrModo.cartellino;
    final sw = Stopwatch()..start();
    final righe = await motore.leggi(f.path, modo: modo);
    sw.stop();
    out.add(Lettura(nome, sw.elapsedMilliseconds, righe));
    final json = jsonEncode({
      'file': nome,
      'ms': sw.elapsedMilliseconds,
      'righe': [for (final r in righe) r.toJson()],
    });
    debugPrint('MICRO_OCR|$json', wrapWidth: 1 << 20);
  }
  return out;
}

class EsempioApp extends StatefulWidget {
  const EsempioApp({super.key});

  @override
  State<EsempioApp> createState() => _EsempioAppState();
}

class _EsempioAppState extends State<EsempioApp> {
  final OcrEngine _motore = CanaleOcrEngine();
  String _stato = 'Preparo il motore...';
  List<Lettura> _letture = const [];

  @override
  void initState() {
    super.initState();
    _avvia();
  }

  Future<void> _avvia() async {
    try {
      final nome = await _motore.nome();
      final sw = Stopwatch()..start();
      await _motore.prepara();
      final prepara = sw.elapsedMilliseconds;
      debugPrint('MICRO_OCR_PREPARA|$nome|$prepara');
      if (!mounted) return;
      setState(() => _stato = '$nome, prepara() $prepara ms. Leggo $cartellaDefault');
      final letture = await leggiCartella(_motore, cartellaDefault);
      if (!mounted) return;
      setState(() {
        _letture = letture;
        _stato = '$nome, prepara() $prepara ms, ${letture.length} immagini';
      });
    } on OcrNonDisponibile catch (e) {
      if (!mounted) return;
      setState(() => _stato = 'OCR non disponibile: ${e.causa}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('micro_ocr')),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(_stato),
            for (final l in _letture)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l.file}: ${l.ms} ms, ${l.righe.length} righe',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(l.righe.map((r) => r.testo).join(' | ')),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

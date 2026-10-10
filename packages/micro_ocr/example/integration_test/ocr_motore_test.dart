// Sul dispositivo (Android ORT e iOS Vision): un PNG GENERATO dal test con «PASTA 500 g» e
// «2,49» disegnati con dart:ui, letto dal motore vero → deve contenere «2,49» (F12.1.17).
// ⚑ Immagine generata e non un campione: niente file con licenze o dati nel repo, e il testo
// atteso e' noto con certezza.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:micro_ocr/micro_ocr.dart';

Future<String> _disegnaCartellino() async {
  const w = 800.0, h = 500.0;
  final registratore = ui.PictureRecorder();
  final canvas = Canvas(registratore);
  canvas.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);
  void scrivi(String testo, double dimensione, Offset dove) {
    final p = TextPainter(
      text: TextSpan(
        text: testo,
        style: TextStyle(color: Colors.black, fontSize: dimensione, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(canvas, dove);
  }

  scrivi('PASTA 500 g', 64, const Offset(60, 60));
  scrivi('2,49', 160, const Offset(60, 200));
  final immagine = await registratore.endRecording().toImage(w.toInt(), h.toInt());
  final png = await immagine.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${Directory.systemTemp.path}/micro_ocr_cartellino.png');
  await file.writeAsBytes(png!.buffer.asUint8List());
  return file.path;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('il motore vero legge 2,49 da un cartellino disegnato', (tester) async {
    final percorso = await tester.runAsync(_disegnaCartellino);
    final motore = CanaleOcrEngine();
    final nome = (await tester.runAsync(motore.nome))!;
    expect(nome, anyOf('vision', 'ppocrv5-ort-1.28.0'));
    await tester.runAsync(motore.prepara);
    final sw = Stopwatch()..start();
    final righe = (await tester.runAsync(() => motore.leggi(percorso!, modo: OcrModo.cartellino)))!;
    debugPrint('MICRO_OCR_MOTORE|$nome|${sw.elapsedMilliseconds} ms|${righe.map((r) => r.testo).join(' | ')}');
    expect(righe.map((r) => r.testo).join(' '), contains('2,49'));
    for (final r in righe) {
      expect(r.riquadro.sinistra, inInclusiveRange(0, 1));
      expect(r.riquadro.alto, inInclusiveRange(0, 1));
      expect(r.riquadro.basso, lessThanOrEqualTo(1.0001));
      expect(r.confidenza, inInclusiveRange(0, 1));
    }
    // Il «2,49» sta sotto «PASTA»: l'asse y deve essere dall'alto (☠ Vision lo capovolge).
    final prezzo = righe.firstWhere((r) => r.testo.contains('2,49'));
    final pasta = righe.where((r) => r.testo.toUpperCase().contains('PASTA'));
    if (pasta.isNotEmpty) expect(prezzo.riquadro.centroY, greaterThan(pasta.first.riquadro.centroY));
    await tester.runAsync(motore.rilascia);
  });

  testWidgets('un file che non esiste diventa OcrNonDisponibile', (tester) async {
    final motore = CanaleOcrEngine();
    Object? errore;
    await tester.runAsync(() async {
      try {
        await motore.leggi('/non/esiste.jpg', modo: OcrModo.cartellino);
      } on OcrNonDisponibile catch (e) {
        errore = e;
      }
    });
    expect(errore, isA<OcrNonDisponibile>());
  });
}

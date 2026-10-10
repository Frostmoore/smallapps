// Banco di parita' sul dispositivo (F12.2b, F12.1.9): legge le immagini di F12_DIR con il
// motore vero e stampa una riga `MICRO_OCR|<json>` per immagine; il confronto con RapidOCR lo
// fa lo script del banco sul PC. Salta se la cartella non c'e'.
//   adb push <campioni> /sdcard/Android/data/com.smp.micro_ocr_example/files/f12/
//   flutter test integration_test/ocr_parita_test.dart [--dart-define=F12_DIR=...]
// ☠ I campioni non entrano mai nel repo: si cancellano dal dispositivo dopo la prova.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:micro_ocr/micro_ocr.dart';
import 'package:micro_ocr_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('parita: legge la cartella dei campioni', (tester) async {
    if (!Directory(cartellaDefault).existsSync()) {
      markTestSkipped('cartella $cartellaDefault assente');
      return;
    }
    final motore = CanaleOcrEngine();
    final letture = (await tester.runAsync(() async {
      await motore.prepara();
      return leggiCartella(motore, cartellaDefault);
    }))!;
    expect(letture, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 20)));
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Le licenze di terzi che non arrivano da un pacchetto Dart (develop_microapps.md F12.1.12,
/// `ImpostazioniPage` > Informazioni > Licenze): `showLicensePage` mostra solo quelle dei
/// pacchetti pub, e il motore OCR e i font sono altro.
///
/// - **PaddleOCR / RapidOCR** (Apache-2.0: i modelli PP-OCRv5 dentro `micro_ocr`) e **ONNX
///   Runtime 1.28.0** (MIT) solo su **Android**, dove sono davvero nell'app (su iPhone legge Vision,
///   del sistema). ⚑ Apache-2.0 chiede di distribuire il testo della licenza con il software.
/// - **Plus Jakarta Sans** e **Space Grotesk** (SIL OFL 1.1) ovunque.
///
/// ⚑ Le licenze si leggono pigramente (il registro chiama il generatore solo quando la pagina
/// delle licenze si apre): niente costo all'avvio.
void registraLicenze({TargetPlatform? piattaforma}) {
  final android = (piattaforma ?? defaultTargetPlatform) == TargetPlatform.android;
  LicenseRegistry.addLicense(() async* {
    if (android) {
      yield LicenseEntryWithLineBreaks(
        const ['PaddleOCR (PP-OCRv5)', 'RapidOCR'],
        await rootBundle.loadString('assets/licenses/paddleocr-rapidocr.txt'),
      );
      yield LicenseEntryWithLineBreaks(
        const ['ONNX Runtime'],
        await rootBundle.loadString('assets/licenses/onnxruntime.txt'),
      );
    }
    yield LicenseEntryWithLineBreaks(
      const ['Plus Jakarta Sans'],
      await rootBundle.loadString('assets/fonts/OFL-PlusJakartaSans.txt'),
    );
    yield LicenseEntryWithLineBreaks(
      const ['Space Grotesk'],
      await rootBundle.loadString('assets/fonts/OFL-SpaceGrotesk.txt'),
    );
  });
}

/// OCR solo sul telefono (F12.2b): iOS Vision, Android PP-OCRv5 su ONNX Runtime 1.28.0.
///
/// Barrel completo (usa `flutter/services`). Il dominio delle app importa invece
/// `package:micro_ocr/riga_ocr.dart`, che e' Dart puro.
library;

export 'src/canale_ocr_engine.dart';
export 'src/fake_ocr_engine.dart';
export 'src/ocr_engine.dart';
export 'src/riga_ocr.dart';

import 'riga_ocr.dart';

/// Il motore OCR visto dall'app. Una sola interfaccia per Vision (iOS), PP-OCR
/// (Android) e il finto dei test: la piattaforma sceglie il motore, l'app non ha
/// `if (Platform.isIOS)` (F12.1.9).
abstract interface class OcrEngine {
  /// 'vision' su iOS, 'ppocrv5-ort-1.28.0' su Android, 'fake' nei test. Finisce nelle fixture.
  Future<String> nome();

  /// Carica i modelli (Android: ≈ 0,5–1 s la prima volta). Idempotente. Si chiama dopo il primo frame.
  Future<void> prepara();

  /// Legge un'immagine JPEG/PNG gia' su disco. L'ordine delle righe non e' garantito.
  Future<List<RigaOcr>> leggi(String percorsoImmagine, {required OcrModo modo});

  /// Libera le sessioni (Android). Il prossimo leggi() le ricarica.
  Future<void> rilascia();
}

/// Il motore non c'e' o non puo' leggere (plugin assente, modelli non caricabili,
/// immagine illeggibile). L'app ripiega sul tastierino.
class OcrNonDisponibile implements Exception {
  const OcrNonDisponibile(this.causa);
  final Object causa;

  @override
  String toString() => 'OcrNonDisponibile: $causa';
}

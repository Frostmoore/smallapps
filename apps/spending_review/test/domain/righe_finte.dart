import 'package:micro_ocr/riga_ocr.dart';

/// Una riga OCR scritta a mano per i test dei parser: testo e riquadro normalizzato
/// (x, y in alto a sinistra, larghezza, altezza). ⚑ Prodotti e nomi inventati: si riproduce la
/// DISPOSIZIONE del campione citato, non il suo contenuto (F12.1.4).
RigaOcr r(String testo, double x, double y, double w, double h, {double c = 0.95}) => RigaOcr(
  testo: testo,
  riquadro: Riquadro(sinistra: x, alto: y, larghezza: w, altezza: h),
  confidenza: c,
);

/// Una riga di scontrino: descrizione a sinistra e importo a destra, alla riga [n] (altezza 0,02).
List<RigaOcr> rigaScontrino(int n, String sinistra, [String? destra]) => [
  r(sinistra, 0.05, 0.05 + n * 0.025, 0.5, 0.02),
  if (destra != null) r(destra, 0.8, 0.05 + n * 0.025, 0.15, 0.02),
];

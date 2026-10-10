import 'package:micro_ocr/riga_ocr.dart';
import 'package:spending_review/domain/lettura/bilancia_parser.dart';
import 'package:spending_review/domain/lettura/cartellino_parser.dart';
import 'package:spending_review/domain/lettura/scontrino_parser.dart';
import 'package:spending_review/services/lettura_service.dart';

/// Le letture finte degli screenshot e del video: righe OCR scritte a mano, passate ai parser
/// VERI. ⚑ Perche' finte: il simulatore non ha una fotocamera, e le foto vere dei campioni non
/// stanno nel repo (licenze, dati personali). Perche' passate ai parser veri e non scritte gia'
/// interpretate: cosi' il foglio fotografato e' esattamente quello che l'app mostra leggendo un
/// cartellino fatto cosi' (prezzo grande, barrato piccolo, bollino «−23%»). Stessa forma di
/// `test/domain/righe_finte.dart`: riquadro normalizzato (x, y, larghezza, altezza).
RigaOcr _r(String testo, double x, double y, double w, double h) => RigaOcr(
  testo: testo,
  riquadro: Riquadro(sinistra: x, alto: y, larghezza: w, altezza: h),
  confidenza: 0.95,
);

/// Un cartellino in offerta: 2,29 con il pieno 2,99 barrato e il bollino −23% (disposizione del
/// campione c33). Un prodotto che NON e' nella spesa d'esempio: il foglio propone «Aggiungi».
RisultatoCartellino cartellinoFinto({required bool english}) => LettoCartellino(
  const CartellinoParser().interpreta([
    _r(english ? 'COCOA SHORTBREAD' : 'FROLLINI AL CACAO', 0.10, 0.10, 0.50, 0.05),
    _r('350 G', 0.10, 0.17, 0.40, 0.05),
    _r('2,29', 0.30, 0.30, 0.30, 0.16),
    _r('2,99', 0.30, 0.52, 0.15, 0.05),
    _r('-23%', 0.70, 0.30, 0.15, 0.08),
    _r('6,54 €/kg', 0.60, 0.70, 0.25, 0.04),
  ]),
);

/// L'etichetta della bilancia: 0,612 kg × 12,90 €/kg = 7,89 (peso, €/kg e importo coerenti).
RisultatoCartellino bilanciaFinta({required bool english}) {
  final l = const BilanciaParser().interpreta([
    _r(english ? 'SMOKED CHEESE' : 'PROVOLA AFFUMICATA', 0.10, 0.05, 0.60, 0.06),
    _r('PESO NETTO kg', 0.10, 0.20, 0.30, 0.05),
    _r('0,612', 0.10, 0.26, 0.20, 0.06),
    _r('€/kg', 0.45, 0.20, 0.15, 0.05),
    _r('12,90', 0.45, 0.26, 0.20, 0.06),
    _r('IMPORTO €', 0.70, 0.20, 0.25, 0.05),
    _r('7,89', 0.70, 0.26, 0.25, 0.09),
  ]);
  if (l == null) throw StateError('etichetta finta non letta dal parser');
  return LettaBilancia(l);
}

/// Lo scontrino della spesa d'esempio (`kDemoInCorso` in lib/dev/demo_data.dart): le stesse
/// righe, ma il caffe' a 4,29 invece del 3,49 del cartellino (offerta non applicata) e il
/// sacchetto in piu'. Totale 27,56 contro 26,61 contati: «Differenza da guardare» +0,95.
ScontrinoLetto scontrinoFinto({required bool english}) {
  final corpo = <(String, String?)>[
    (english ? 'WHOLE MILK 1L 10%' : 'LATTE INTERO 1L 10%', '2,58'),
    (english ? 'DURUM PASTA 500G 4%' : 'PASTA SEMOLA 500G 4%', '2,67'),
    (english ? 'OFFER 3X2' : 'OFFERTA 3X2', '-0,89'),
    (english ? 'GROUND COFFEE 250G 22%' : 'CAFFE MACINATO 250G 22%', '4,29'),
    (english ? 'CHERRY TOMATOES 4%' : 'POMODORI CILIEGINI 4%', '1,90'),
    ('0,486 kg x 3,90 €/kg', null),
    (english ? 'MOZZARELLA 125G 4%' : 'MOZZARELLA 125G 4%', '1,98'),
    (english ? 'EXTRA VIRGIN OIL 1L 4%' : 'OLIO EXTRAVERGINE 1L 4%', '8,99'),
    (english ? 'DISH SOAP 22%' : 'DETERSIVO PIATTI 22%', '1,49'),
    (english ? 'BANANAS 4%' : 'BANANE 4%', '2,00'),
    ('1,120 kg x 1,79 €/kg', null),
    (english ? 'BREAD 4%' : 'PANE COMUNE 4%', '2,40'),
    (english ? 'SHOPPING BAG 22%' : 'SHOPPER BIODEGR. 22%', '0,15'),
  ];
  var n = 0;
  List<RigaOcr> riga(String sinistra, [String? destra]) {
    final y = 0.03 + n++ * 0.03;
    return [
      _r(sinistra, 0.05, y, 0.5, 0.022),
      if (destra != null) _r(destra, 0.78, y, 0.17, 0.022),
    ];
  }

  final righe = [
    ...riga(english ? 'SUNNY MARKET S.R.L.' : 'SUPERMERCATO SOLE S.R.L.'),
    ...riga('VIA ROMA 1 - 00100 ROMA'),
    ...riga('P.IVA 01234567890'),
    ...riga('DOCUMENTO COMMERCIALE'),
    ...riga('di vendita o prestazione'),
    ...riga('DESCRIZIONE IVA', 'Prezzo(€)'),
    for (final (d, i) in corpo) ...riga(d, i),
    ...riga('TOTALE COMPLESSIVO', '27,56'),
    ...riga('Pagamento elettronico', '27,56'),
  ];
  return ScontrinoLetto(lettura: const ScontrinoParser().interpreta(righe, oggi: DateTime.now()));
}

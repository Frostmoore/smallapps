import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/riga_ocr.dart';
import 'package:spending_review/domain/arrotonda.dart';
import 'package:spending_review/domain/lettura/bilancia_parser.dart';
import 'package:spending_review/domain/quantita.dart';

import 'righe_finte.dart';

/// F12.1.5: l'etichetta della bilancia. I numeri dei campioni sono fatti, non immagini.
void main() {
  const parser = BilanciaParser();
  Money e(int c) => Money.cents(c);

  /// Un'etichetta con le parole chiave: prodotto, peso netto, €/kg, importo (e la tara, se c'e').
  List<RigaOcr> etichetta(String peso, String alKg, String totale, {String? tara}) => [
    r('FILETTO DI PESCE', 0.10, 0.05, 0.60, 0.06),
    r('PESO NETTO kg', 0.10, 0.20, 0.30, 0.05),
    r(peso, 0.10, 0.26, 0.20, 0.06),
    r('€/kg', 0.45, 0.20, 0.15, 0.05),
    r(alKg, 0.45, 0.26, 0.20, 0.06),
    r('IMPORTO €', 0.70, 0.20, 0.25, 0.05),
    r(totale, 0.70, 0.26, 0.25, 0.09),
    if (tara != null) r('TARA kg $tara', 0.10, 0.40, 0.30, 0.04),
  ];

  group('le 9 verita\' dei campioni sono coerenti con Arrotonda (F12.1.5)', () {
    const casi = <(String, String, String, String)>[
      ('b01', '0,258', '29,90', '7,71'),
      ('b02', '0,326', '5,90', '1,92'),
      ('b03', '0,160', '7,39', '1,18'),
      ('b04', '0,099', '280,00', '27,72'),
      ('b05', '0,494', '44,99', '22,23'),
      ('b06', '0,500', '5,86', '2,93'),
      ('b07', '1,082', '1,59', '1,72'),
      ('b08', '0,225', '12,00', '2,70'),
      ('b09', '0,314', '8,90', '2,79'),
    ];
    for (final (nome, peso, alKg, totale) in casi) {
      test('$nome: $peso × $alKg = $totale', () {
        final l = parser.interpreta(etichetta(peso, alKg, totale))!;
        expect(l.coerente, isTrue);
        expect(l.totale, e(int.parse(totale.replaceAll(',', ''))));
        expect(l.pesoNetto, AMisura(int.parse(peso.replaceAll(',', '')), UnitaMisura.kg));
        expect(Arrotonda.perMisura(l.alKg!, l.pesoNetto!.millesimi), l.totale);
        expect(l.utile, isTrue);
        expect(l.prodotto, 'FILETTO DI PESCE');
      });
    }
  });

  test('tara presente e ignorata nel conto (come b01, b02, b04)', () {
    final l = parser.interpreta(etichetta('0,258', '29,90', '7,71', tara: '0,012'))!;
    expect(l.tara, const AMisura(12, UnitaMisura.kg));
    expect(l.pesoNetto, const AMisura(258, UnitaMisura.kg));
    expect(l.totale, e(771));
  });

  test('senza parole chiave: la ricerca combinatoria trova la tripla coerente', () {
    final l = parser.interpreta([
      r('FORMAGGIO', 0.1, 0.05, 0.4, 0.06),
      r('0,326', 0.1, 0.3, 0.2, 0.06),
      r('5,90', 0.4, 0.3, 0.2, 0.06),
      r('1,92', 0.7, 0.3, 0.2, 0.09),
      r('3,33', 0.7, 0.6, 0.2, 0.04), // un numero estraneo (un codice, un altro prezzo)
    ])!;
    expect(l.totale, e(192));
    expect(l.alKg, e(590));
    expect(l.coerente, isTrue);
  });

  test('due etichette sovrapposte (come b06): vince quella con la tripla coerente', () {
    final l = parser.interpreta([
      r('SALSICCIA', 0.1, 0.05, 0.4, 0.06),
      r('0,500', 0.1, 0.30, 0.2, 0.06),
      r('5,86', 0.4, 0.30, 0.2, 0.06),
      r('2,93', 0.7, 0.30, 0.2, 0.09),
      r('0,731', 0.1, 0.60, 0.2, 0.06),
      r('8,37', 0.4, 0.60, 0.2, 0.06),
      r('9,99', 0.7, 0.60, 0.2, 0.09), // 0,731 × 8,37 = 6,12: non coerente
    ])!;
    expect(l.totale, e(293));
    expect(l.coerente, isTrue);
  });

  test('peso in grammi: «258 g»', () {
    final l = parser.interpreta([
      r('FILETTO', 0.1, 0.05, 0.4, 0.06),
      r('258 g', 0.1, 0.3, 0.2, 0.06),
      r('29,90 €/kg', 0.4, 0.3, 0.3, 0.06),
      r('7,71', 0.75, 0.3, 0.2, 0.09),
    ])!;
    expect(l.pesoNetto, const AMisura(258, UnitaMisura.kg));
    expect(l.totale, e(771));
    expect(l.coerente, isTrue);
  });

  test('totale incoerente: coerente false, ma il totale e\' quello stampato', () {
    final l = parser.interpreta(etichetta('0,258', '29,90', '7,99'))!;
    expect(l.coerente, isFalse);
    expect(l.totale, e(799));
  });

  test('riconosce: la «firma» della bilancia (peso a 3 decimali + tripla coerente)', () {
    expect(parser.riconosce(etichetta('0,258', '29,90', '7,71')), isTrue);
    expect(parser.riconosce([r('PASTA', 0.1, 0.1, 0.4, 0.06), r('1,99', 0.3, 0.3, 0.3, 0.15)]), isFalse);
    expect(parser.riconosce(etichetta('0,258', '29,90', '7,99')), isFalse);
  });

  test('niente importi: non e\' un\'etichetta', () {
    expect(parser.interpreta([r('SOLO TESTO', 0.1, 0.1, 0.5, 0.1)]), isNull);
    expect(parser.interpreta(const []), isNull);
  });
}

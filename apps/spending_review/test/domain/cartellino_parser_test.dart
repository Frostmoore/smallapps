import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/riga_ocr.dart';
import 'package:spending_review/domain/lettura/cartellino_parser.dart';
import 'package:spending_review/domain/offerta.dart';
import 'package:spending_review/domain/quantita.dart';

import 'righe_finte.dart';

/// F12.1.4: i casi della tabella della specsheet, con righe OCR scritte a mano che riproducono la
/// disposizione del campione citato (prodotti e nomi inventati).
void main() {
  const parser = CartellinoParser();
  Money e(int c) => Money.cents(c);
  PropostaCartellino prima(List<RigaOcr> righe) => parser.interpreta(righe).proposte.first;

  test('c01 Tigros «3x1 anziche\'»: prezzo pieno 3,19 con NxM(3,1), al kg 10,60, alternativa 1,06', () {
    final p = prima([
      r('PROSCIUTTO COTTO', 0.20, 0.10, 0.40, 0.06),
      r('1', 0.30, 0.30, 0.10, 0.20),
      r('06', 0.41, 0.31, 0.08, 0.10),
      r('3x1', 0.60, 0.30, 0.15, 0.08),
      r("anziche' € 3,19 al pz", 0.55, 0.55, 0.35, 0.06),
      r('€ 10,60 al kg', 0.10, 0.75, 0.30, 0.05),
    ]);
    expect(p.prezzo, e(319));
    expect(p.offerta, const OffertaNxM(prendi: 3, paghi: 1));
    expect(p.unitario, PrezzoUnitario(e(1060), UnitaMisura.kg));
    expect(p.alternative, [e(106)]);
    expect(p.nome, 'PROSCIUTTO COTTO');
  });

  test('c11 «2+1»: grande 1,26, piccolo 1,89 → prezzo 1,89 con NxM(3,2)', () {
    final p = prima([
      r('FORMAGGIO MORBIDO', 0.20, 0.10, 0.50, 0.06),
      r('1,26', 0.30, 0.30, 0.30, 0.15),
      r('2+1', 0.70, 0.30, 0.15, 0.08),
      r('1,89', 0.30, 0.50, 0.15, 0.05),
      r('5,04 €/kg', 0.30, 0.60, 0.20, 0.04),
    ]);
    expect(p.prezzo, e(189));
    expect(p.offerta, const OffertaNxM(prendi: 3, paghi: 2));
  });

  test('c14: «… 200 g», 1,99, «9,95 €/kg» piccolo → formato 200 g e controllo riuscito', () {
    final p = prima([
      r('SAPONE NEUTRO X2 200 g', 0.10, 0.10, 0.60, 0.06),
      r('1,99', 0.30, 0.30, 0.30, 0.15),
      r('9,95 €/kg', 0.60, 0.50, 0.20, 0.04),
    ]);
    expect(p.prezzo, e(199));
    expect(p.formato, const AMisura(200, UnitaMisura.kg));
    expect(p.unitario, PrezzoUnitario(e(995), UnitaMisura.kg));
    expect(p.affidabilita, greaterThan(0.9)); // +0,2 del controllo formato
  });

  test('c16: «… GR.600», 3,59, «5,99 €/kg» → 3,59 (3,59/0,6 = 5,98: dentro la tolleranza)', () {
    final p = prima([
      r('CREMA SPALMABILE BICCH.BIRRA GR.600', 0.10, 0.10, 0.70, 0.06),
      r('3,59', 0.30, 0.30, 0.30, 0.15),
      r('5,99 €/kg', 0.60, 0.50, 0.20, 0.04),
    ]);
    expect(p.prezzo, e(359));
    expect(p.formato, const AMisura(600, UnitaMisura.kg));
    expect(p.affidabilita, greaterThan(0.9));
  });

  test('c19: «… 50 cl», 21,90, «43,80 €/l» → prezzo al litro', () {
    final p = prima([
      r('DISTILLATO DI PERE 50 cl', 0.10, 0.10, 0.60, 0.06),
      r('21,90', 0.30, 0.30, 0.35, 0.15),
      r('43,80 €/l', 0.60, 0.50, 0.20, 0.04),
    ]);
    expect(p.prezzo, e(2190));
    expect(p.unitario, PrezzoUnitario(e(4380), UnitaMisura.l));
  });

  test('c20: «… 6x180 ml», 1,98, «1,84 €/lt» → formato 1080 ml, controllo dentro la tolleranza', () {
    final p = prima([
      r('ACQUA TONICA 6x180 ml', 0.10, 0.10, 0.60, 0.06),
      r('1,98', 0.30, 0.30, 0.30, 0.15),
      r('1,84 €/lt', 0.60, 0.50, 0.20, 0.04),
    ]);
    expect(p.prezzo, e(198));
    expect(p.formato, const AMisura(1080, UnitaMisura.l));
    expect(p.unitario, PrezzoUnitario(e(184), UnitaMisura.l));
    expect(p.affidabilita, greaterThan(0.9));
  });

  test('c22: due prezzi grandi lontani → 2 proposte, la piu\' vicina al centro prima', () {
    final l = parser.interpreta([
      r('FARINA TIPO 0', 0.05, 0.20, 0.35, 0.05),
      r('0,99', 0.10, 0.30, 0.25, 0.15),
      r('SEMOLA BIOLOGICA', 0.60, 0.55, 0.35, 0.05),
      r('1,64', 0.65, 0.65, 0.25, 0.15),
      r('1,64 €/kg', 0.65, 0.85, 0.20, 0.04),
    ]);
    expect(l.proposte, hasLength(2));
    expect(l.proposte[0].prezzo, e(99));
    expect(l.proposte[0].nome, 'FARINA TIPO 0');
    expect(l.proposte[1].prezzo, e(164));
    expect(l.proposte[1].nome, 'SEMOLA BIOLOGICA');
  });

  test('c26: «132,00» e «1.100,00 €/kg» → unitario con le migliaia', () {
    final p = prima([
      r('CARCIOFINI SOTT\'OLIO 120 g', 0.10, 0.10, 0.60, 0.06),
      r('132,00', 0.30, 0.30, 0.35, 0.15),
      r('1.100,00 €/kg', 0.60, 0.50, 0.25, 0.04),
    ]);
    expect(p.prezzo, e(13200));
    expect(p.unitario, PrezzoUnitario(e(110000), UnitaMisura.kg));
  });

  test('c28: 1,98 e bollino «-40%» → OffertaPercentuale(40), 1 pezzo costa 1,19', () {
    final p = prima([
      r('INSALATA MISTA 200 G', 0.10, 0.10, 0.60, 0.06),
      r('1,98', 0.30, 0.30, 0.30, 0.15),
      r('-40%', 0.75, 0.25, 0.15, 0.10),
      r('Al kg € 9,90', 0.60, 0.55, 0.20, 0.04),
    ]);
    expect(p.prezzo, e(198));
    expect(p.offerta, const OffertaPercentuale(40));
    expect(p.offerta!.totale(p.prezzo!, 1), e(119));
    expect(p.unitario, PrezzoUnitario(e(990), UnitaMisura.kg));
  });

  test('c29: 1,49 grande, 2,99 piccolo, «-50%» → 1,49 con OffertaPrezzoBarrato(2,99)', () {
    final p = prima([
      r('ULTIMI GIORNI', 0.10, 0.10, 0.50, 0.06),
      r('1,49', 0.30, 0.30, 0.30, 0.15),
      r('2,99', 0.30, 0.50, 0.15, 0.06),
      r('-50%', 0.70, 0.30, 0.15, 0.08),
    ]);
    expect(p.prezzo, e(149));
    expect(p.offerta, OffertaPrezzoBarrato(e(299)));
    expect(p.prezzoPieno, e(299));
  });

  test('c30: 0,99 e «-30%» → 1 pezzo 0,69 (sconto 0,297 → 0,30)', () {
    final p = prima([
      r('RUCOLA', 0.10, 0.10, 0.40, 0.06),
      r('0,99', 0.30, 0.30, 0.30, 0.15),
      r('-30%', 0.70, 0.30, 0.15, 0.08),
    ]);
    expect(p.offerta, const OffertaPercentuale(30));
    expect(p.offerta!.totale(p.prezzo!, 1), e(69));
  });

  test('c33: «229» fuso grande, 2,99 piccolo, «-23%» → 2,29 (fuso) e barrato 2,99', () {
    final p = prima([
      r('MACINATO DI POLLO', 0.10, 0.10, 0.50, 0.05),
      r('CONFEZIONE 300 G', 0.10, 0.17, 0.40, 0.05),
      r('229', 0.30, 0.30, 0.30, 0.16),
      r('2,99', 0.30, 0.52, 0.15, 0.05),
      r('-23%', 0.70, 0.30, 0.15, 0.08),
    ]);
    expect(p.prezzo, e(229));
    expect(p.offerta, OffertaPrezzoBarrato(e(299)));
  });

  test('c02/c03: «ZUCCHINE», «1,48 €/kg» → a misura, unitario 1,48/kg', () {
    final p = prima([r('ZUCCHINE', 0.20, 0.20, 0.40, 0.08), r('1,48 €/kg', 0.20, 0.35, 0.40, 0.15)]);
    expect(p.aMisura, isTrue);
    expect(p.prezzo, isNull);
    expect(p.unitario, PrezzoUnitario(e(148), UnitaMisura.kg));
    expect(p.nome, 'ZUCCHINE');
  });

  test('c23: 2,50 e «0%» → nessuna offerta', () {
    final p = prima([r('MANIGLIE', 0.10, 0.10, 0.40, 0.06), r('2,50', 0.30, 0.30, 0.30, 0.15), r('0%', 0.70, 0.30, 0.10, 0.08)]);
    expect(p.prezzo, e(250));
    expect(p.offerta, isNull);
  });

  test('c04: sole lettere, nessuna cifra → lettura vuota', () {
    expect(parser.interpreta([r('FRIGGITELLI', 0.2, 0.2, 0.5, 0.1), r('ITALIA', 0.2, 0.4, 0.3, 0.08)]).vuota, isTrue);
    expect(parser.interpreta(const []).vuota, isTrue);
  });

  group('prezzo con la carta fedelta\' (risposta D4: chiedi ogni volta)', () {
    final righe = [
      r('BISCOTTI AL BURRO', 0.10, 0.10, 0.50, 0.06),
      r('2,49', 0.10, 0.30, 0.30, 0.12),
      r('con carta 1,99', 0.50, 0.30, 0.40, 0.12),
    ];

    test('entrambi i prezzi, marcati: il foglio chiede quale', () {
      final p = prima(righe);
      expect(p.carta, DoppioPrezzoCarta(conCarta: e(199), senzaCarta: e(249)));
      expect(p.prezzo, e(199));
      expect(p.offerta, OffertaPrezzoConCarta(e(249)));
    });

    test('scelta «senza carta»: 2,49 e nessuna offerta; «con carta»: 1,99 e l\'offerta', () {
      final p = prima(righe);
      final senza = p.scegliCarta(conCarta: false);
      expect(senza.prezzo, e(249));
      expect(senza.offerta, isNull);
      expect(senza.carta, isNull);
      final con = p.scegliCarta(conCarta: true);
      expect(con.prezzo, e(199));
      expect(con.offerta, OffertaPrezzoConCarta(e(249)));
    });
  });

  test('righe con confidenza bassa o riquadri minuscoli: rumore, scartate', () {
    final l = parser.interpreta([
      r('9,99', 0.3, 0.3, 0.3, 0.15, c: 0.2),
      r('8,88', 0.3, 0.6, 0.01, 0.01),
    ]);
    expect(l.vuota, isTrue);
  });
}

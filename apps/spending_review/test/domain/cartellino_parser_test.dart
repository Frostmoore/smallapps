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

  // ⚑ F12.7: le regole trovate sui RITAGLI DEL MIRINO (un cartellino per foto,
  // test/fixtures/ocr/ppocrv5-mirino), ciascuna con la disposizione del ritaglio che l'ha chiesta.
  group('F12.7, ritagli del mirino', () {
    test('c11: «250 g: 1,89 € - Soit le kg: 7,56 €» → 1,89 NON e\' al kg (il «le kg» e\' del numero dopo)', () {
      final p = prima([
        r('2+1', 0.40, 0.08, 0.25, 0.21),
        r('Soit le kg: 5,04 €', 0.54, 0.69, 0.13, 0.04),
        r('PIECE DE 250 g: 1,89 € - Soit le kg: 7,56 €', 0.19, 0.85, 0.37, 0.05),
      ]);
      expect(p.prezzo, e(189));
      expect(p.offerta, const OffertaNxM(prendi: 3, paghi: 2));
      // Due prezzi al kg: quello che torna col prezzo effettivo (1,26 / 0,25 kg = 5,04).
      expect(p.unitario, PrezzoUnitario(e(504), UnitaMisura.kg));
    });

    test('c01: «3x1», «3 PEZZI € 3,18», «anziche\' € 3,19 al pz» e il 1,06 grande non letto → 3,19 con NxM(3,1)', () {
      final p = prima([
        r('3x1', 0.05, 0.07, 0.23, 0.22),
        r('3 PEZZI € 3,18', 0.51, 0.16, 0.37, 0.08),
        r('PROSCIUTTO COTTO', 0.08, 0.39, 0.27, 0.07),
        r('anziche € 3,19 al pz', 0.51, 0.66, 0.40, 0.08),
        r('€ 10,60 al kg', 0.09, 0.69, 0.27, 0.09),
      ]);
      expect(p.prezzo, e(319));
      expect(p.offerta, const OffertaNxM(prendi: 3, paghi: 1));
      expect(p.unitario, PrezzoUnitario(e(1060), UnitaMisura.kg));
      expect(p.nome, isNot(contains('PEZZI')));
    });

    test('c27/c10: «/ k9» e «ol ku» sono «al kg» letti storti', () {
      final peck = parser.interpreta([
        r('FUNGHI SOTT\'OLIO 670 g', 0.24, 0.57, 0.63, 0.06),
        r('€126,00', 0.13, 0.83, 0.25, 0.07),
        r('€ 188,06 / k9', 0.62, 0.84, 0.23, 0.06),
      ]).proposte;
      expect(peck, hasLength(1));
      expect(peck.single.prezzo, e(12600));
      expect(peck.single.unitario, PrezzoUnitario(e(18806), UnitaMisura.kg));

      final bietola = prima([
        r('VERDURA', 0.11, 0.20, 0.36, 0.15),
        r('1,79', 0.38, 0.45, 0.34, 0.33),
        r('ol ku', 0.16, 0.71, 0.08, 0.07, c: 0.51),
      ]);
      expect(bietola.aMisura, isTrue);
      expect(bietola.unitario, PrezzoUnitario(e(179), UnitaMisura.kg));
    });

    test('c18: «AILC.12,80» (€ letto «C.») → 12,80 al litro', () {
      final p = prima([
        r('c 6,40', 0.53, 0.37, 0.25, 0.20),
        r('AILC.12,80', 0.27, 0.45, 0.17, 0.05),
        r('CREMA DI LIMONE', 0.26, 0.56, 0.27, 0.07),
      ]);
      expect(p.prezzo, e(640));
      expect(p.unitario, PrezzoUnitario(e(1280), UnitaMisura.l));
    });

    test('c15: «Alkg» piccolo a sinistra seguito da un frammento («2») e\' del valore illeggibile, non del prezzo grande', () {
      final p = prima([
        r('1,97', 0.54, 0.38, 0.23, 0.22),
        r('Alkg', 0.24, 0.49, 0.10, 0.06),
        r('2', 0.32, 0.49, 0.03, 0.04, c: 0.55),
      ]);
      expect(p.prezzo, e(197));
      expect(p.aMisura, isFalse);
    });

    test('c22: «1/kg» stampato sulla confezione e\' una quantita\', non un\'etichetta «al kg»', () {
      final p = prima([
        r('1/kg', 0.20, 0.18, 0.22, 0.21),
        r('€ 0,99', 0.54, 0.30, 0.25, 0.19),
        r('FARINA PER PIZZA', 0.30, 0.50, 0.22, 0.05),
      ]);
      expect(p.prezzo, e(99));
      expect(p.unitario, isNull);
    });

    test('c33: due prezzi grandi uguali legati dal «-23%» → 2,29 col barrato 2,99, una proposta sola', () {
      final l = parser.interpreta([
        r('MACINATO DI TACCHINO 270G', 0.20, 0.16, 0.57, 0.07),
        r('SE SCADE ENTRO IL', 0.21, 0.24, 0.32, 0.06),
        r('SE SCADE OLTRE IL', 0.56, 0.25, 0.28, 0.05),
        r('299', 0.66, 0.35, 0.17, 0.21),
        r('229', 0.33, 0.35, 0.18, 0.21),
        r('-23%', 0.23, 0.37, 0.11, 0.08),
      ]);
      expect(l.proposte, hasLength(1));
      final p = l.proposte.single;
      expect(p.prezzo, e(229));
      expect(p.prezzoPieno, e(299));
      expect(p.offerta, OffertaPrezzoBarrato(e(299)));
      expect(p.nome, isNot(contains('SCADE')));
    });

    test('c28: «SCONTO» sopra «40» (il «%» non letto) → OffertaPercentuale(40)', () {
      final p = prima([
        r('INSALATA MISTA 200 G', 0.00, 0.35, 0.72, 0.11),
        r('SCONTO', 0.76, 0.37, 0.23, 0.10),
        r('40', 0.74, 0.45, 0.22, 0.23),
        r('1,98', 0.48, 0.52, 0.28, 0.24),
      ]);
      expect(p.prezzo, e(198));
      expect(p.offerta, const OffertaPercentuale(40));
    });

    test('un «40» da solo SENZA «sconto» vicino non e\' una percentuale', () {
      final p = prima([
        r('52', 0.69, 0.16, 0.14, 0.17),
        r('VERDURA', 0.11, 0.20, 0.36, 0.15),
        r('1,79', 0.38, 0.45, 0.34, 0.33),
      ]);
      expect(p.offerta, isNull);
    });

    test('c31: bollino «-30% SCONTO ALLA CASSA» senza prezzo → proposta col solo sconto, prezzo da battere', () {
      final l = parser.interpreta([
        r('30', 0.57, 0.28, 0.28, 0.30),
        r('ULTIMI GIORNI', 0.18, 0.32, 0.37, 0.14),
        r('%', 0.82, 0.43, 0.06, 0.10),
        r('SCONTO', 0.60, 0.58, 0.21, 0.10),
        r('ALLA CASSA', 0.55, 0.64, 0.28, 0.12),
      ]);
      expect(l.proposte, hasLength(1));
      expect(l.proposte.single.prezzo, isNull);
      expect(l.proposte.single.offerta, const OffertaPercentuale(30));
      expect(l.proposte.single.affidabilita, lessThan(0.6)); // il foglio dice «Controlla il prezzo»
    });

    test('Vision c30: «0.99-» (la coda del € letta come meno) e\' 0,99, non uno sconto', () {
      final p = prima([
        r('30%', 0.24, 0.17, 0.32, 0.17),
        r('SCONTO', 0.24, 0.32, 0.30, 0.08),
        r('SOLO A', 0.63, 0.62, 0.18, 0.12),
        r('0.99-', 0.54, 0.66, 0.35, 0.25),
      ]);
      expect(p.prezzo, e(99));
      expect(p.offerta, const OffertaPercentuale(30));
    });

    test('Vision c33: «(23%» e «229» piu\' basso di «€ 299» → 2,29 col barrato 2,99', () {
      final p = prima([
        r('€ 299', 0.58, 0.35, 0.26, 0.22),
        r('(23%', 0.23, 0.38, 0.10, 0.05),
        r('229', 0.34, 0.38, 0.15, 0.15),
      ]);
      expect(p.prezzo, e(229));
      expect(p.offerta, OffertaPrezzoBarrato(e(299)));
    });

    test('Vision c01: «3*1», «106» fuso, «3 PEZZI € 3,18» e «anziche\' € 3,19» → 3,19 (l\'anziche\' vince sul 3,18)', () {
      final p = prima([
        r('3*1', 0.23, 0.30, 0.14, 0.10),
        r('3 PEZZI € 3,18', 0.53, 0.33, 0.24, 0.055),
        r('106', 0.53, 0.40, 0.26, 0.19),
        r('anziche € 3,19 al pz', 0.53, 0.67, 0.26, 0.06),
      ]);
      expect(p.prezzo, e(319));
      expect(p.offerta, const OffertaNxM(prendi: 3, paghi: 1));
    });

    test('un meno DAVANTI resta uno sconto: «-0,40» non diventa un prezzo', () {
      final l = parser.interpreta([r('-0,40', 0.3, 0.3, 0.3, 0.15)]);
      expect(l.vuota, isTrue);
    });

    test('Esselunga: il nome stampato SOTTO il prezzo si prende se sopra non c\'e\' niente', () {
      final p = prima([
        r('€ 3,59', 0.53, 0.49, 0.25, 0.17),
        r('il Prezzochiaro', 0.20, 0.50, 0.25, 0.06),
        r('Al kg € 5,99', 0.20, 0.57, 0.20, 0.06),
        r('CREMA SPALMABILE GR. 600', 0.20, 0.70, 0.40, 0.06),
        r('PZ 696', 0.30, 0.76, 0.10, 0.04),
      ]);
      expect(p.prezzo, e(359));
      expect(p.nome, 'CREMA SPALMABILE GR. 600');
    });

    test('Vision: lettere cirilliche gemelle riportate alle latine («ВIЕTA» → «BIETA»)', () {
      final p = prima([
        r('ВIЕTA/CОSTA', 0.11, 0.20, 0.36, 0.15),
        r('1,79', 0.38, 0.45, 0.34, 0.33),
      ]);
      expect(p.nome, 'BIETA/COSTA');
    });

    test('Vision c33: «• с 819/Кg» (al kg senza virgola) non fa del prezzo grande un prezzo al kg', () {
      final p = prima([
        r('€ 299', 0.58, 0.35, 0.26, 0.22),
        r('(23%', 0.23, 0.38, 0.10, 0.05),
        r('229', 0.34, 0.38, 0.15, 0.15),
        r('• с 819/Кg', 0.39, 0.51, 0.15, 0.05),
      ]);
      expect(p.prezzo, e(229));
      expect(p.aMisura, isFalse);
    });
  });
}


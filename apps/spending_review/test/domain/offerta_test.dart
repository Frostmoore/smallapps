import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/domain/offerta.dart';

/// F12.1.3: la tabella delle offerte, per q = 1..7, e il JSON tollerante.
void main() {
  Money e(int c) => Money.cents(c);

  test('NxM 3x2 a 1,89: p × ((q ~/ 3) × 2 + q % 3)', () {
    const o = OffertaNxM(prendi: 3, paghi: 2);
    final attesi = {1: 189, 2: 378, 3: 378, 4: 567, 5: 756, 6: 756, 7: 945};
    for (final MapEntry(key: q, value: c) in attesi.entries) {
      expect(o.totale(e(189), q), e(c), reason: 'q = $q');
    }
  });

  test('NxM 3x1 a 3,19 (c01): 3 pezzi costano 3,19, non 3 × 1,06', () {
    const o = OffertaNxM(prendi: 3, paghi: 1);
    final attesi = {1: 319, 2: 638, 3: 319, 4: 638, 5: 957, 6: 638, 7: 957};
    for (final MapEntry(key: q, value: c) in attesi.entries) {
      expect(o.totale(e(319), q), e(c), reason: 'q = $q');
    }
    expect(o.effettivo(e(319)), e(106));
  });

  test('2x1 (= «1+1»)', () {
    const o = OffertaNxM(prendi: 2, paghi: 1);
    expect([for (var q = 1; q <= 7; q++) o.totale(e(250), q).cents], [250, 250, 500, 500, 750, 750, 1000]);
  });

  test('Percentuale −40% su 1,98: 1,19 a pezzo', () {
    const o = OffertaPercentuale(40);
    for (var q = 1; q <= 7; q++) {
      expect(o.totale(e(198), q), e(119 * q), reason: 'q = $q');
    }
  });

  test('Prezzo barrato e prezzo con carta: p × q (informative)', () {
    const b = OffertaPrezzoBarrato(Money.cents(299));
    const c = OffertaPrezzoConCarta(Money.cents(249));
    for (var q = 1; q <= 7; q++) {
      expect(b.totale(e(149), q), e(149 * q));
      expect(c.totale(e(199), q), e(199 * q));
    }
  });

  test('Secondo a −50% su 3,00: q = 3 → 9,00 − 1,50 = 7,50', () {
    const o = OffertaSecondoAPercento(50);
    expect([for (var q = 1; q <= 7; q++) o.totale(e(300), q).cents], [300, 450, 750, 900, 1200, 1350, 1650]);
  });

  group('JSON', () {
    test('andata e ritorno di ogni offerta', () {
      const offerte = <Offerta>[
        OffertaNxM(prendi: 3, paghi: 2),
        OffertaPercentuale(30),
        OffertaPrezzoBarrato(Money.cents(299)),
        OffertaSecondoAPercento(50),
        OffertaPrezzoConCarta(Money.cents(249)),
      ];
      for (final o in offerte) {
        expect(Offerta.fromJson(o.toJson()), o);
      }
    });

    test('tollerante: null, tipo sconosciuto, campi sbagliati → null', () {
      expect(Offerta.fromJson(null), isNull);
      expect(Offerta.fromJson({'tipo': 'futuro', 'x': 1}), isNull);
      expect(Offerta.fromJson({'tipo': 'nxm', 'prendi': 2, 'paghi': 3}), isNull);
      expect(Offerta.fromJson({'tipo': 'nxm', 'prendi': 'tre', 'paghi': 2}), isNull);
      expect(Offerta.fromJson({'tipo': 'percentuale', 'percento': 0}), isNull);
      expect(Offerta.fromJson({'tipo': 'percentuale', 'percento': 100}), isNull);
      expect(Offerta.fromJson({'tipo': 'barrato'}), isNull);
      expect(Offerta.fromJson({}), isNull);
    });

    test('numeri arrivati come double (JSON di un altro motore) si accettano se interi', () {
      expect(Offerta.fromJson({'tipo': 'nxm', 'prendi': 3.0, 'paghi': 2.0}), const OffertaNxM(prendi: 3, paghi: 2));
    });
  });
}

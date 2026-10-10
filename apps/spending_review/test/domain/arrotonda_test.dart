import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/domain/arrotonda.dart';

/// F12.1.3: arrotondamenti al centesimo «mezzo in su», in interi.
void main() {
  group('mezzoInSu', () {
    test('mezzo in su, non al pari (bancario)', () {
      expect(Arrotonda.mezzoInSu(945, 1, 10), 95); // 94,5 → 95
      expect(Arrotonda.mezzoInSu(925, 1, 10), 93); // 92,5 → 93 (il bancario darebbe 92)
      expect(Arrotonda.mezzoInSu(944, 1, 10), 94);
    });

    test('negativi simmetrici: si arrotonda il valore assoluto', () {
      expect(Arrotonda.mezzoInSu(-945, 1, 10), -95);
      expect(Arrotonda.mezzoInSu(-944, 1, 10), -94);
      expect(Arrotonda.mezzoInSu(945, -1, 10), -95);
    });

    test('divisore dispari: 1,5 → 2 (la formula «+ d/2» sbaglierebbe)', () {
      expect(Arrotonda.mezzoInSu(3, 1, 2), 2);
      expect(Arrotonda.mezzoInSu(1, 3, 2), 2);
      expect(Arrotonda.mezzoInSu(189, 2, 3), 126); // 1,89 × 2/3 = 1,26 (c11)
      expect(Arrotonda.mezzoInSu(319, 1, 3), 106); // 3,19 × 1/3 = 1,063 → 1,06 (c01)
    });

    test('zero', () => expect(Arrotonda.mezzoInSu(0, 999, 7), 0));
  });

  group('perMisura: le 9 etichette della bilancia dei campioni (F12.1.5)', () {
    const casi = <(String, int, int, int)>[
      ('b01', 258, 2990, 771),
      ('b02', 326, 590, 192),
      ('b03', 160, 739, 118),
      ('b04', 99, 28000, 2772),
      ('b05', 494, 4499, 2223),
      ('b06', 500, 586, 293),
      ('b07', 1082, 159, 172),
      ('b08', 225, 1200, 270),
      ('b09', 314, 890, 279),
    ];
    for (final (nome, grammi, alKg, totale) in casi) {
      test('$nome: $grammi g × ${alKg / 100} €/kg = ${totale / 100}', () {
        expect(Arrotonda.perMisura(Money.cents(alKg), grammi), Money.cents(totale));
      });
    }
  });

  group('perMisura: le 4 righe pesate di s03', () {
    test('0,248 × 12,50 = 3,10', () => expect(Arrotonda.perMisura(Money.cents(1250), 248), Money.cents(310)));
    test('0,186 × 14,00 = 2,60', () => expect(Arrotonda.perMisura(Money.cents(1400), 186), Money.cents(260)));
    test('0,126 × 7,50 = 0,945 → 0,95 (half-up, non 0,94)', () {
      expect(Arrotonda.perMisura(Money.cents(750), 126), Money.cents(95));
    });
    test('0,098 × 7,50 = 0,735 → 0,74', () => expect(Arrotonda.perMisura(Money.cents(750), 98), Money.cents(74)));
  });

  group('scontoPercentuale: si arrotonda lo SCONTO', () {
    test('c29: 2,99 −50% → sconto 1,495 → 1,50, prezzo 1,49', () {
      final sconto = Arrotonda.scontoPercentuale(Money.cents(299), 50);
      expect(sconto, Money.cents(150));
      expect(Money.cents(299) - sconto, Money.cents(149));
    });
    test('c30: 0,99 −30% → sconto 0,297 → 0,30, prezzo 0,69', () {
      expect(Money.cents(99) - Arrotonda.scontoPercentuale(Money.cents(99), 30), Money.cents(69));
    });
    test('c28: 1,98 −40% → sconto 0,792 → 0,79, prezzo 1,19', () {
      expect(Money.cents(198) - Arrotonda.scontoPercentuale(Money.cents(198), 40), Money.cents(119));
    });
  });
}

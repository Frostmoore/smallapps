import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:scorte_calore/domain/consumption.dart';
import 'package:scorte_calore/domain/fuel_source.dart';
import 'package:scorte_calore/domain/fuel_units.dart';
import 'package:scorte_calore/domain/quantity_converter.dart';

/// F5.3: consumo medio, autonomia, qualita' della stima. I casi della tabella "Test
/// obbligatori" sono i primi otto, nello stesso ordine.
void main() {
  const calc = ConsumptionCalculator();
  final pellet = FuelSourceSpec.withDefaults(id: 1, name: 'Stufa', fuelType: FuelType.pellet);

  CivilDate ott(int giorno) => CivilDate(2026, 10, giorno);
  Measurement m(int giorno, double q) => Measurement.absolute(date: ott(giorno), quantity: q);

  group('test obbligatori (F5.3)', () {
    test('tre misurazioni decrescenti a distanza regolare: calcolo base', () {
      final e = calc.estimate(
        measurements: [m(1, 30), m(6, 25), m(11, 20)],
        source: pellet,
        today: ott(11),
      );
      expect(e.dailyRate, closeTo(1, 1e-9));
      expect(e.currentQuantity, 20);
      expect(e.daysRemaining, 20);
      expect(e.depletionDate, ott(31));
      expect(e.reorderDate, ott(24)); // 7 giorni prima
      expect(e.intervalsUsed, 2);
      expect(e.spanDays, 10);
      expect(e.quality, EstimateQuality.good);
      expect(e.isActionable, isTrue);
    });

    test('rifornimento a meta serie: l intervallo di salita e scartato', () {
      final serie = [m(1, 30), m(6, 25), m(8, 60), m(13, 50)];
      final intervalli = calc.buildIntervals(serie);
      expect(intervalli.map((i) => '${i.from}>${i.to}'), [
        '2026-10-01>2026-10-06',
        '2026-10-08>2026-10-13',
      ]);
      final e = calc.estimate(measurements: serie, source: pellet, today: ott(13));
      // (5 + 10) / (5 + 5): il salto da 25 a 60 non e' consumo, e non lo diventa in negativo.
      expect(e.dailyRate, closeTo(1.5, 1e-9));
      expect(e.daysRemaining, 33); // floor(50 / 1,5)
    });

    test('due misurazioni identiche: insufficient, nessuna divisione per zero', () {
      final e = calc.estimate(measurements: [m(1, 20), m(5, 20)], source: pellet, today: ott(5));
      expect(e.quality, EstimateQuality.insufficient);
      expect(e.dailyRate, isNull);
      expect(e.daysRemaining, isNull);
      expect(e.depletionDate, isNull);
      expect(e.reorderDate, isNull);
      expect(e.isActionable, isFalse);
    });

    test('una sola misurazione: insufficient', () {
      final e = calc.estimate(measurements: [m(1, 20)], source: pellet, today: ott(1));
      expect(e.quality, EstimateQuality.insufficient);
      expect(e.intervalsUsed, 0);
      expect(e.currentQuantity, 20);
      expect(e.dailyRate, isNull);
    });

    test('intervalli di durata molto diversa: la media e ponderata per la durata', () {
      // 2 giorni a 5/giorno, poi 20 giorni a 1/giorno.
      final e = calc.estimate(
        measurements: [m(1, 100), m(3, 90), m(23, 70)],
        source: pellet,
        today: ott(23),
      );
      // Ponderata: 30 / 22 = 1,36. La media delle velocita' darebbe (5 + 1) / 2 = 3.
      expect(e.dailyRate, closeTo(30 / 22, 1e-9));
      expect(e.daysRemaining, 51); // floor(70 / 1,3636)
    });

    test('otto intervalli: solo gli ultimi 5 sono usati', () {
      // I primi 3 intervalli consumano 10 al giorno, gli ultimi 5 uno al giorno.
      final serie = [
        m(1, 200), m(3, 180), m(5, 160), m(7, 140), //
        m(9, 138), m(11, 136), m(13, 134), m(15, 132), m(17, 130),
      ];
      expect(calc.buildIntervals(serie), hasLength(8));
      final e = calc.estimate(measurements: serie, source: pellet, today: ott(17));
      expect(e.intervalsUsed, 5);
      expect(e.spanDays, 10);
      expect(e.dailyRate, closeTo(1, 1e-9));
    });

    test('misurazioni nello stesso giorno: vince l ultima, niente intervallo a zero giorni', () {
      final serie = [m(1, 30), m(1, 28), m(6, 23)];
      final intervalli = calc.buildIntervals(serie);
      expect(intervalli, hasLength(1));
      expect(intervalli.single.days, 5);
      expect(intervalli.single.consumed, 5); // da 28, non da 30
      expect(calc.normalize(serie).map((x) => x.quantity), [28, 23]);
    });

    test('percentuale con usableFraction 0,8: 43% di 1000 L sono 344 L', () {
      final gpl = FuelSourceSpec.withDefaults(
        id: 2,
        name: 'Bombolone',
        fuelType: FuelType.lpg,
        tankCapacity: 1000,
      );
      final conv = QuantityConverter(gpl);
      Measurement letta(int giorno, double percento) => Measurement(
        date: ott(giorno),
        quantity: conv.fromPercentage(percento),
        enteredAs: EnteredAs.percentage,
        rawInput: percento,
      );
      final e = calc.estimate(
        measurements: [letta(1, 53), letta(11, 43)],
        source: gpl,
        today: ott(11),
      );
      expect(e.currentQuantity, closeTo(344, 1e-9));
      // 10 punti di manometro in 10 giorni = 80 L utili in 10 giorni.
      expect(e.dailyRate, closeTo(8, 1e-9));
      expect(e.daysRemaining, 43);
    });
  });

  group('qualita della stima', () {
    test('meno di 3 giorni di dati: insufficient anche se la velocita c e', () {
      final e = calc.estimate(measurements: [m(1, 10), m(3, 8)], source: pellet, today: ott(3));
      expect(e.spanDays, 2);
      expect(e.quality, EstimateQuality.insufficient);
      expect(e.dailyRate, isNull);
    });

    test('un solo intervallo, anche lungo: low', () {
      final e = calc.estimate(measurements: [m(1, 40), m(21, 20)], source: pellet, today: ott(21));
      expect(e.quality, EstimateQuality.low);
      expect(e.intervalsUsed, 1);
    });

    test('due intervalli ma meno di 10 giorni: low', () {
      final e = calc.estimate(
        measurements: [m(1, 20), m(4, 17), m(8, 13)],
        source: pellet,
        today: ott(8),
      );
      expect(e.spanDays, 7);
      expect(e.quality, EstimateQuality.low);
    });

    test('solo rifornimenti: insufficient', () {
      final e = calc.estimate(measurements: [m(1, 10), m(5, 50)], source: pellet, today: ott(5));
      expect(e.intervalsUsed, 0);
      expect(e.quality, EstimateQuality.insufficient);
    });

    test('nessuna misurazione: insufficient, quantita zero, niente anello', () {
      final e = calc.estimate(measurements: const [], source: pellet, today: ott(1));
      expect(e.quality, EstimateQuality.insufficient);
      expect(e.currentQuantity, 0);
      expect(e.lastMeasurementDate, isNull);
      expect(e.percentRemaining, isNull);
    });

    test('minIntervalDays scarta gli intervalli troppo corti', () {
      const lento = ConsumptionCalculator(minIntervalDays: 3);
      final intervalli = lento.buildIntervals([m(1, 30), m(2, 29), m(10, 21)]);
      expect(intervalli.map((i) => i.days), [8]);
    });
  });

  group('date', () {
    final serie = [m(1, 30), m(6, 25), m(11, 20)];

    test('l esaurimento si conta dall ultima misura: senza misure nuove non slitta', () {
      final e = calc.estimate(measurements: serie, source: pellet, today: ott(21));
      expect(e.depletionDate, ott(31)); // come se oggi fosse l'11
      expect(e.daysRemaining, 10);
      expect(e.reorderDate, ott(24));
    });

    test('esaurimento gia passato: zero giorni, mai negativi', () {
      final e = calc.estimate(measurements: serie, source: pellet, today: CivilDate(2026, 11, 5));
      expect(e.daysRemaining, 0);
      expect(e.depletionDate, ott(31));
    });

    test('scorta a zero: esaurita il giorno dell ultima misura', () {
      final e = calc.estimate(measurements: [m(1, 10), m(11, 0)], source: pellet, today: ott(11));
      expect(e.depletionDate, ott(11));
      expect(e.daysRemaining, 0);
    });

    test('l anticipo del riordino segue warningDays della fonte', () {
      final e = calc.estimate(
        measurements: serie,
        source: pellet.copyWith(warningDays: 10),
        today: ott(11),
      );
      expect(e.reorderDate, ott(21));
    });

    test('la quantita stimata a una data scende col consumo e non va sotto zero', () {
      final e = calc.estimate(measurements: serie, source: pellet, today: ott(11));
      expect(e.projectedQuantityOn(ott(24)), closeTo(7, 1e-9));
      expect(e.projectedQuantityOn(ott(9)), 20); // prima dell'ultima misura: la misura
      expect(e.projectedQuantityOn(CivilDate(2026, 12, 1)), 0);
    });
  });

  group('residuo rispetto all ultimo rifornimento', () {
    test('senza rifornimenti il riferimento e la prima misura', () {
      final e = calc.estimate(
        measurements: [m(1, 40), m(6, 35), m(11, 30)],
        source: pellet,
        today: ott(11),
      );
      expect(e.referenceQuantity, 40);
      expect(e.fractionRemaining, closeTo(0.75, 1e-9));
      expect(e.percentRemaining, 75);
    });

    test('dopo un rifornimento il riferimento e la quantita subito dopo', () {
      final e = calc.estimate(
        measurements: [m(1, 30), m(6, 5), m(8, 60), m(13, 45)],
        source: pellet,
        today: ott(13),
      );
      expect(e.referenceQuantity, 60);
      expect(e.percentRemaining, 75);
    });

    test('vale anche con una stima insufficient: l anello si disegna lo stesso', () {
      final e = calc.estimate(measurements: [m(1, 20)], source: pellet, today: ott(1));
      expect(e.quality, EstimateQuality.insufficient);
      expect(e.percentRemaining, 100);
    });

    test('riferimento a zero: niente percentuale invece di una divisione per zero', () {
      final e = calc.estimate(measurements: [m(1, 0)], source: pellet, today: ott(1));
      expect(e.fractionRemaining, isNull);
    });
  });

  test('ConsumptionInterval.rate e consumo diviso giorni', () {
    final i = ConsumptionInterval(from: ott(1), to: ott(5), consumed: 6, days: 4);
    expect(i.rate, 1.5);
  });
}

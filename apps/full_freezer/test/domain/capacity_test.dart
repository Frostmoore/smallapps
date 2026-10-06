import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/domain/capacity.dart';
import 'package:full_freezer/domain/units.dart';

/// F4.3b e F4.9: quanto e' pieno un freezer, e quando avvisare.
void main() {
  const est = CapacityEstimator();

  group('modelli', () {
    test('sono ordinati dal piu piccolo al piu grande, con chiavi uniche', () {
      final litri = FreezerModels.all.map((m) => m.liters).toList();
      expect(litri, [...litri]..sort());
      final keys = FreezerModels.all.map((m) => m.key);
      expect(keys.toSet().length, keys.length);
      expect(keys, isNot(contains(FreezerModels.customKey)));
    });

    test('i valori delle schede tecniche (F4.3b)', () {
      expect(FreezerModels.byKey('ice_box')!.liters, 15);
      expect(FreezerModels.byKey('combi_compact')!.liters, 70);
      expect(FreezerModels.byKey('upright_tall')!.liters, 270);
      expect(FreezerModels.byKey('chest_large')!.liters, 350);
      expect(FreezerModels.byKey('custom'), isNull);
    });
  });

  group('stima dell ingombro', () {
    test('per ogni unita', () {
      expect(est.estimateLiters(quantity: 2, unit: Units.portions), closeTo(0.8, 1e-9));
      expect(est.estimateLiters(quantity: 1, unit: Units.kilograms), closeTo(1.3, 1e-9));
      expect(est.estimateLiters(quantity: 500, unit: Units.grams), closeTo(0.65, 1e-9));
      expect(est.estimateLiters(quantity: 3, unit: Units.packs), closeTo(2.4, 1e-9));
      expect(est.estimateLiters(quantity: 1, unit: Units.liters), closeTo(1.1, 1e-9));
    });

    test('i pezzi dipendono dalla categoria', () {
      expect(est.estimateLiters(quantity: 2, unit: Units.pieces, categoryKey: 'ice_cream'), 2.0);
      expect(est.estimateLiters(quantity: 5, unit: Units.pieces, categoryKey: 'fruit'), closeTo(1.0, 1e-9));
      // Categoria sconosciuta o assente: come "altro".
      expect(est.estimateLiters(quantity: 1, unit: Units.pieces), closeTo(0.4, 1e-9));
    });

    test('mai zero: il database rifiuterebbe la riga', () {
      expect(est.estimateLiters(quantity: 1, unit: Units.grams), greaterThan(0));
    });
  });

  group('riempimento', () {
    test('si conta l 80% della capacita nominale', () {
      // 100 litri nominali -> 80 utili; 40 litri dentro -> 50%.
      final f = est.fill(capacityLiters: 100, calibration: 1, itemLiters: [10, 30]);
      expect(f.usableLiters, 80);
      expect(f.fraction, closeTo(0.5, 1e-9));
      expect(f.percent, 50);
      expect(f.level, FillLevel.normal);
    });

    test('freezer vuoto: frazione 0, senza divisioni per zero', () {
      final f = est.fill(capacityLiters: 70, calibration: 1, itemLiters: const []);
      expect(f.fraction, 0);
      expect(f.level, FillLevel.empty);
    });

    test('oltre il 100% la percentuale si ferma a 100, il livello e full', () {
      final f = est.fill(capacityLiters: 15, calibration: 1, itemLiters: [20]);
      expect(f.fraction, greaterThan(1));
      expect(f.percent, 100);
      expect(f.level, FillLevel.full);
    });

    test('soglie esatte: 85% e full, sotto il 20% e empty', () {
      expect(est.fill(capacityLiters: 100, calibration: 1, itemLiters: [68]).level, FillLevel.full);
      expect(est.fill(capacityLiters: 100, calibration: 1, itemLiters: [67.9]).level, FillLevel.normal);
      expect(est.fill(capacityLiters: 100, calibration: 1, itemLiters: [16]).level, FillLevel.normal);
      expect(est.fill(capacityLiters: 100, calibration: 1, itemLiters: [15.9]).level, FillLevel.empty);
    });

    test('la taratura moltiplica i litri stimati', () {
      final f = est.fill(capacityLiters: 100, calibration: 1.5, itemLiters: [32]);
      expect(f.fraction, closeTo(0.6, 1e-9));
    });
  });

  group('taratura', () {
    test('60% dichiarato su 40% stimato da 1,5', () {
      expect(est.calibrate(estimatedFraction: 0.4, declaredFraction: 0.6), closeTo(1.5, 1e-9));
    });

    test('limitata fra 0,25 e 4', () {
      expect(est.calibrate(estimatedFraction: 0.05, declaredFraction: 0.9), 4);
      expect(est.calibrate(estimatedFraction: 0.9, declaredFraction: 0.05), 0.25);
    });

    test('con la stima a zero non c e niente da tarare', () {
      expect(est.calibrate(estimatedFraction: 0, declaredFraction: 0.5), 1);
    });

    test('due tarature di seguito non si moltiplicano', () {
      const items = [32.0];
      // Prima taratura: l'utente dice 60%.
      final primo = est.calibrate(
        estimatedFraction: est.rawFraction(capacityLiters: 100, itemLiters: items),
        declaredFraction: 0.6,
      );
      // Seconda: dice di nuovo 60%. Sulla stima GREZZA il fattore resta lo stesso.
      final secondo = est.calibrate(
        estimatedFraction: est.rawFraction(capacityLiters: 100, itemLiters: items),
        declaredFraction: 0.6,
      );
      expect(secondo, closeTo(primo, 1e-9));
      final f = est.fill(capacityLiters: 100, calibration: secondo, itemLiters: items);
      expect(f.fraction, closeTo(0.6, 1e-9));
    });
  });

  group('avvisi con isteresi (F4.9)', () {
    const policy = CapacityAlertPolicy();

    test('un freezer nuovo e vuoto non avvisa mai "quasi vuoto"', () {
      expect(policy.decide(fraction: 0.05, lastLevel: AlertLevel.empty).send, isNull);
    });

    test('superato l 85% avvisa una volta sola', () {
      final primo = policy.decide(fraction: 0.86, lastLevel: null);
      expect(primo.send, AlertLevel.full);
      final ancora = policy.decide(fraction: 0.90, lastLevel: primo.newLastLevel);
      expect(ancora.send, isNull);
    });

    test('dopo "pieno" non riavvisa finche non scende sotto il 70%', () {
      // Scende all'80%: ancora "pieno" in memoria, nessun avviso nemmeno se risale.
      var d = policy.decide(fraction: 0.80, lastLevel: AlertLevel.full);
      expect(d.newLastLevel, AlertLevel.full);
      expect(policy.decide(fraction: 0.86, lastLevel: d.newLastLevel).send, isNull);
      // Scende al 65%: riarmato.
      d = policy.decide(fraction: 0.65, lastLevel: AlertLevel.full);
      expect(d.newLastLevel, isNull);
      expect(policy.decide(fraction: 0.86, lastLevel: d.newLastLevel).send, AlertLevel.full);
    });

    test('il freezer riempito e poi svuotato avvisa "quasi vuoto"', () {
      // Riempito al 50%: si riarma l'avviso di vuoto ereditato dalla creazione.
      final riempito = policy.decide(fraction: 0.5, lastLevel: AlertLevel.empty);
      expect(riempito.newLastLevel, isNull);
      final svuotato = policy.decide(fraction: 0.15, lastLevel: riempito.newLastLevel);
      expect(svuotato.send, AlertLevel.empty);
    });

    test('dopo "vuoto" non riavvisa finche non risale sopra il 40%', () {
      final d = policy.decide(fraction: 0.30, lastLevel: AlertLevel.empty);
      expect(d.newLastLevel, AlertLevel.empty);
      expect(policy.decide(fraction: 0.10, lastLevel: d.newLastLevel).send, isNull);
    });
  });
}

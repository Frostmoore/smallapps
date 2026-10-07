import 'package:flutter_test/flutter_test.dart';
import 'package:scorte_calore/domain/fuel_source.dart';
import 'package:scorte_calore/domain/fuel_units.dart';

/// F5.4 e F5.2: unita', unita' ammesse per combustibile e default della fonte.
void main() {
  group('catalogo delle unita', () {
    test('ci sono le otto chiavi del piano, una volta ciascuna', () {
      final keys = FuelUnits.all.map((u) => u.key).toList();
      expect(keys.toSet().length, keys.length);
      expect(keys.toSet(), {
        'bags',
        'kg',
        'pallets',
        'liters',
        'percent',
        'quintals',
        'steres',
        'crates',
      });
    });

    test('byKey trova l unita, una chiave sconosciuta lancia invece di ripiegare', () {
      expect(FuelUnits.byKey('bags').key, 'bags');
      expect(() => FuelUnits.byKey('barili'), throwsArgumentError);
      expect(FuelUnits.tryByKey('barili'), isNull);
      expect(FuelUnits.tryByKey(null), isNull);
    });

    test('il peso unitario si chiede solo per i contenitori, mai per gli steri', () {
      final conPeso = FuelUnits.all.where((u) => u.supportsWeight).map((u) => u.key).toSet();
      expect(conPeso, {'bags', 'pallets', 'crates'});
      expect(FuelUnits.byKey('steres').supportsWeight, isFalse);
    });
  });

  group('unita ammesse per combustibile', () {
    test('pellet: sacchi, chili, bancali', () {
      expect(FuelUnits.forType(FuelType.pellet).map((u) => u.key), ['bags', 'kg', 'pallets']);
    });

    test('GPL e gasolio: litri e percentuale', () {
      expect(FuelUnits.forType(FuelType.lpg).map((u) => u.key), ['liters', 'percent']);
      expect(FuelUnits.forType(FuelType.diesel).map((u) => u.key), ['liters', 'percent']);
    });

    test('legna: quintali, steri, cassette, chili', () {
      expect(FuelUnits.forType(FuelType.wood).map((u) => u.key), [
        'quintals',
        'steres',
        'crates',
        'kg',
      ]);
    });

    test('biomassa: chili, quintali, sacchi', () {
      expect(FuelUnits.forType(FuelType.biomass).map((u) => u.key), ['kg', 'quintals', 'bags']);
    });

    test('l unita predefinita e ammessa ed e la prima proposta dal wizard', () {
      for (final t in FuelType.values) {
        expect(FuelUnits.isAllowed(t, t.defaultUnitKey), isTrue, reason: t.key);
        expect(FuelUnits.forType(t).first, FuelUnits.defaultFor(t), reason: t.key);
      }
      expect(FuelUnits.isAllowed(FuelType.pellet, 'liters'), isFalse);
    });
  });

  group('combustibili e default', () {
    test('le chiavi salvate nel database sono stabili e si rileggono', () {
      expect(FuelType.values.map((t) => t.key), ['pellet', 'lpg', 'diesel', 'wood', 'biomass']);
      for (final t in FuelType.values) {
        expect(FuelType.byKey(t.key), t);
      }
      expect(FuelType.byKey('carbone'), isNull);
    });

    test('frazione utile 0,80 solo per il GPL, 1,0 per gli altri', () {
      expect(FuelType.lpg.defaultUsableFraction, 0.80);
      for (final t in FuelType.values.where((t) => t != FuelType.lpg)) {
        expect(t.defaultUsableFraction, 1.0, reason: t.key);
      }
    });

    test('solo GPL e gasolio hanno un serbatoio', () {
      expect(FuelType.values.where((t) => t.usesTank), [FuelType.lpg, FuelType.diesel]);
    });

    test('una fonte nuova prende unita, frazione utile e 7 giorni di anticipo', () {
      final s = FuelSourceSpec.withDefaults(
        id: 1,
        name: 'Bombolone',
        fuelType: FuelType.lpg,
        tankCapacity: 1000,
      );
      expect(s.unitKey, 'liters');
      expect(s.usableFraction, 0.80);
      expect(s.warningDays, 7);
      expect(s.usableCapacity, closeTo(800, 1e-9));
    });

    test('enteredAs: chiavi del database stabili', () {
      expect(EnteredAs.byKey('absolute'), EnteredAs.absolute);
      expect(EnteredAs.byKey('percentage'), EnteredAs.percentage);
      expect(EnteredAs.byKey('altro'), isNull);
    });
  });
}

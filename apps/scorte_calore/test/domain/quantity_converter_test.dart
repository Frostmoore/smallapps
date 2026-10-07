import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:scorte_calore/domain/fuel_source.dart';
import 'package:scorte_calore/domain/fuel_units.dart';
import 'package:scorte_calore/domain/quantity_converter.dart';

/// F5.4 e F5.2: percentuale del manometro, chili, e ricalcolo dopo un cambio di capacita'.
void main() {
  final gpl = FuelSourceSpec.withDefaults(
    id: 1,
    name: 'Bombolone',
    fuelType: FuelType.lpg,
    tankCapacity: 1000,
  );

  group('percentuale del manometro', () {
    test('43% di 1000 L con frazione utile 0,8 sono 344 L, non 430', () {
      final c = QuantityConverter(gpl);
      expect(c.supportsPercentage, isTrue);
      expect(c.fromPercentage(43), closeTo(344, 1e-9));
    });

    test('toPercentage e l inverso di fromPercentage', () {
      final c = QuantityConverter(gpl);
      expect(c.toPercentage(344), closeTo(43, 1e-9));
      expect(c.toPercentage(c.fromPercentage(71.5)), closeTo(71.5, 1e-9));
    });

    test('il gasolio con frazione 1,0 usa la capacita intera', () {
      final gasolio = FuelSourceSpec.withDefaults(
        id: 2,
        name: 'Cisterna',
        fuelType: FuelType.diesel,
        tankCapacity: 1000,
      );
      expect(QuantityConverter(gasolio).fromPercentage(43), closeTo(430, 1e-9));
    });

    test('con l unita percent la quantita e la percentuale stessa', () {
      final c = QuantityConverter(gpl.copyWith(unitKey: FuelUnits.percent));
      expect(c.fromPercentage(43), 43);
      expect(c.toPercentage(43), 43);
    });

    test('senza capacita niente percentuali: lancia invece di inventare', () {
      final pellet = FuelSourceSpec.withDefaults(id: 3, name: 'Stufa', fuelType: FuelType.pellet);
      final c = QuantityConverter(pellet);
      expect(c.supportsPercentage, isFalse);
      expect(() => c.fromPercentage(50), throwsStateError);
      expect(() => c.toPercentage(5), throwsStateError);
    });
  });

  group('chili', () {
    FuelSourceSpec fonte(String unitKey, {double? peso}) => FuelSourceSpec(
      id: 9,
      name: 'x',
      fuelType: FuelType.wood,
      unitKey: unitKey,
      unitWeightKg: peso,
      usableFraction: 1,
    );

    test('chili e quintali si convertono senza bisogno del peso', () {
      expect(QuantityConverter(fonte('kg')).toKilograms(250), 250);
      expect(QuantityConverter(fonte('quintals')).toKilograms(2.5), closeTo(250, 1e-9));
    });

    test('12 sacchi da 15 kg sono 180 kg', () {
      expect(QuantityConverter(fonte('bags', peso: 15)).toKilograms(12), closeTo(180, 1e-9));
    });

    test('un contenitore senza peso, i litri e la percentuale non si convertono', () {
      expect(QuantityConverter(fonte('bags')).toKilograms(12), isNull);
      expect(QuantityConverter(fonte('crates', peso: 0)).toKilograms(3), isNull);
      expect(QuantityConverter(gpl).toKilograms(300), isNull);
      expect(QuantityConverter(fonte('percent')).toKilograms(40), isNull);
    });

    test('gli steri non si convertono nemmeno se un peso c e', () {
      expect(QuantityConverter(fonte('steres', peso: 500)).toKilograms(2), isNull);
    });
  });

  group('ricalcolo dal valore digitato', () {
    final giorno = CivilDate(2026, 10, 1);
    final letta = Measurement(
      date: giorno,
      quantity: 344,
      enteredAs: EnteredAs.percentage,
      rawInput: 43,
    );
    final contata = Measurement.absolute(date: giorno, quantity: 300);

    test('cambiando la capacita, una misura in percentuale si ricalcola dal 43%', () {
      final c = QuantityConverter(gpl.copyWith(tankCapacity: 1500));
      final r = c.recompute(letta);
      expect(r.quantity, closeTo(516, 1e-9));
      expect(r.rawInput, 43);
      expect(r.enteredAs, EnteredAs.percentage);
      expect(r.date, giorno);
    });

    test('cambiando la frazione utile, idem', () {
      final c = QuantityConverter(gpl.copyWith(usableFraction: 0.85));
      expect(c.recompute(letta).quantity, closeTo(365.5, 1e-9));
    });

    test('una misura digitata come quantita resta com e', () {
      final c = QuantityConverter(gpl.copyWith(tankCapacity: 1500));
      expect(c.recompute(contata), contata);
    });

    test('se la fonte perde la capacita la misura resta invariata, non si perde', () {
      const senza = FuelSourceSpec(
        id: 1,
        name: 'Bombolone',
        fuelType: FuelType.lpg,
        unitKey: 'liters',
        usableFraction: 0.8,
      );
      expect(QuantityConverter(senza).recompute(letta), letta);
    });

    test('recomputeAll mantiene l ordine', () {
      final c = QuantityConverter(gpl.copyWith(tankCapacity: 1500));
      final r = c.recomputeAll([contata, letta]);
      expect(r.map((m) => m.quantity), [300, closeTo(516, 1e-9)]);
    });
  });
}

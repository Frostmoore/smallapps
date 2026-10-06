import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/domain/categories.dart';
import 'package:full_freezer/domain/text_norm.dart';
import 'package:full_freezer/domain/units.dart';

/// F4.2 / F4.8: la normalizzazione dei nomi e le tabelle di dominio.
void main() {
  group('normalizeName', () {
    test('cercare "pure" deve trovare "Purè"', () {
      expect(normalizeName('Purè'), 'pure');
    });

    test('minuscolo, senza accenti, spazi ripuliti', () {
      expect(normalizeName('  Pasta   al  FORNO '), 'pasta al forno');
      expect(normalizeName('Caffè, tè e ragù'), 'caffe, te e ragu');
      expect(normalizeName('Crème brûlée'), 'creme brulee');
    });

    test('l\'apostrofo tipografico diventa quello semplice', () {
      expect(normalizeName('Pan d’arancio'), normalizeName("Pan d'arancio"));
    });
  });

  group('categorie', () {
    test('le chiavi sono uniche e si ritrovano', () {
      final keys = ItemCategories.all.map((c) => c.key).toList();
      expect(keys.toSet().length, keys.length);
      for (final c in ItemCategories.all) {
        expect(ItemCategories.byKey(c.key), same(c));
      }
      expect(ItemCategories.byKey('custom:3'), isNull);
      expect(ItemCategories.byKey(null), isNull);
    });

    test('i promemoria suggeriti sono quelli del piano (F4.2)', () {
      expect(ItemCategories.fish.defaultReminderDays, 120);
      expect(ItemCategories.vegetables.defaultReminderDays, 240);
      expect(ItemCategories.bread.defaultReminderDays, 90);
      expect(ItemCategories.meatRed.defaultReminderDays, 180);
    });
  });

  test('le unita\' note e quella di ripiego', () {
    expect(Units.isKnown(Units.fallback), isTrue);
    expect(Units.isKnown('porzioni'), isFalse);
    expect(Units.all.toSet().length, Units.all.length);
  });
}

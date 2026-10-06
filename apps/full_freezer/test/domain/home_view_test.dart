import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/data/database.dart';
import 'package:full_freezer/domain/categories.dart';
import 'package:full_freezer/domain/category_guess.dart';
import 'package:full_freezer/domain/home_view.dart';
import 'package:micro_core/micro_core.dart';

/// F4.4: le sezioni della home e la deduzione della categoria (F4.5).
void main() {
  final oggi = CivilDate(2026, 10, 6);

  Freezer freezer(int id, {double liters = 100, double calibration = 1}) => Freezer(
    id: id,
    name: 'F$id',
    modelKey: 'custom',
    capacityLiters: liters,
    calibration: calibration,
    sortOrder: id,
    createdAt: 0,
  );

  Item item(int id, int freezerId, int giorniFa, {String? category, int? reminder, double liters = 1}) => Item(
    id: id,
    freezerId: freezerId,
    name: 'I$id',
    nameNorm: 'i$id',
    category: category,
    quantity: 1,
    unit: 'portions',
    frozenAt: oggi.addDays(-giorniFa).toIso(),
    reminderAfterDays: reminder,
    volumeLiters: liters,
    volumeManual: false,
    status: 'stored',
    createdAt: 0,
  );

  HomeView view(List<Item> items, {int? selected, List<Freezer>? freezers}) => buildHomeView(
    freezers: freezers ?? [freezer(1), freezer(2)],
    storedItems: items,
    selectedFreezerId: selected,
    today: oggi,
  );

  test('un alimento sta in una sezione sola', () {
    final v = view([
      item(1, 1, 200, reminder: 100), // old
      item(2, 1, 85, reminder: 100), // watch
      item(3, 1, 10, reminder: 100), // fresh
    ]);
    expect(v.useSoon.map((r) => r.item.id), [1, 2]);
    expect(v.rest.map((r) => r.item.id), [3]);
    expect(v.totalCount, 3);
  });

  test('"Da usare prima" mostra i 5 piu vecchi, il resto dietro "vedi tutti"', () {
    final v = view([for (var i = 1; i <= 8; i++) item(i, 1, 300 + i, reminder: 100)]);
    expect(v.useSoon, hasLength(useSoonPreview));
    expect(v.useSoonTotal, 8);
    expect(v.useSoonAll, hasLength(8));
    // Il piu' vecchio (308 giorni, id 8) per primo.
    expect(v.useSoon.first.item.id, 8);
  });

  test('il piu vecchio senza promemoria resta in "Tutto il resto" ma in cima', () {
    final v = view([item(1, 1, 10), item(2, 1, 900)]);
    expect(v.useSoon, isEmpty);
    expect(v.rest.map((r) => r.item.id), [2, 1]);
  });

  test('il freezer selezionato filtra le righe ma "Dove sono" li conta tutti', () {
    final v = view([item(1, 1, 5), item(2, 2, 5), item(3, 2, 6)], selected: 2);
    expect(v.rest.map((r) => r.item.id), [3, 2]);
    expect(v.freezers.map((s) => s.count), [1, 2]);
    expect(v.selectedFill, isNotNull);
  });

  test('con "Tutti" non c e un riempimento unico', () {
    expect(view([item(1, 1, 5)]).selectedFill, isNull);
  });

  test('il riempimento per freezer usa litri, capacita e taratura', () {
    final v = view(
      [item(1, 1, 5, liters: 20), item(2, 1, 5, liters: 20)],
      freezers: [freezer(1, liters: 100, calibration: 1.5)],
      selected: 1,
    );
    // 40 L x 1,5 = 60 su 80 utili -> 75%.
    expect(v.selectedFill!.percent, 75);
  });

  group('deduzione della categoria', () {
    test('le parole note, in italiano e in inglese', () {
      expect(guessCategory('Spezzatino di manzo'), 'meat_red');
      expect(guessCategory('Petto di pollo'), 'meat_white');
      expect(guessCategory('Bastoncini di pesce'), 'fish');
      expect(guessCategory('Piselli'), 'vegetables');
      expect(guessCategory('Lasagne della nonna'), 'prepared');
      expect(guessCategory('Ragù'), 'prepared');
      expect(guessCategory('Frozen peas'), 'vegetables');
    });

    test('solo parole intere: "panettone" e "panna" non sono pane', () {
      expect(guessCategory('Panettone'), isNull);
      expect(guessCategory('Panna'), isNull);
      expect(guessCategory('Pane'), 'bread');
    });

    test('meglio nessuna categoria che una sbagliata', () {
      expect(guessCategory('Pasta al forno'), isNull);
      expect(guessCategory('Ice cubes'), isNull);
      expect(guessCategory('Qualcosa'), isNull);
    });

    test('ogni categoria del dizionario esiste', () {
      for (final key in guessedCategoryKeys) {
        expect(ItemCategories.byKey(key), isNotNull, reason: key);
      }
    });
  });
}

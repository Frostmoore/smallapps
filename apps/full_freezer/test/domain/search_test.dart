import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/data/database.dart';
import 'package:full_freezer/domain/search.dart';
import 'package:full_freezer/domain/text_norm.dart';

/// F4.8: la ricerca insensibile ad accenti e maiuscole, su nome e note.
void main() {
  Item item(int id, String name, {String? note}) => Item(
    id: id,
    freezerId: 1,
    name: name,
    nameNorm: normalizeName(name),
    quantity: 1,
    unit: 'portions',
    frozenAt: '2026-10-01',
    volumeLiters: 0.4,
    volumeManual: false,
    status: 'stored',
    createdAt: 0,
    note: note,
  );

  final items = [
    item(1, 'Purè di patate'),
    item(2, 'Sugo della nonna'),
    item(3, 'Spezzatino', note: 'avanzato dal pranzo di Natale'),
    item(4, 'PANE'),
  ];

  test('cercare "pure" trova "Purè"', () {
    expect(searchItems(items, 'pure').map((i) => i.id), [1]);
  });

  test('maiuscole indifferenti, nei due sensi', () {
    expect(searchItems(items, 'pane').map((i) => i.id), [4]);
    expect(searchItems(items, 'SUGO').map((i) => i.id), [2]);
  });

  test('cerca anche nelle note, senza accenti', () {
    expect(searchItems(items, 'natale').map((i) => i.id), [3]);
  });

  test('tutte le parole, in qualunque ordine', () {
    expect(searchItems(items, 'nonna sugo').map((i) => i.id), [2]);
    expect(searchItems(items, 'sugo pane'), isEmpty);
  });

  test('una ricerca vuota non mostra niente', () {
    expect(searchItems(items, '   '), isEmpty);
  });

  test('l ordine ricevuto resta (il piu vecchio per primo)', () {
    expect(searchItems(items, 'a').map((i) => i.id), [1, 2, 3, 4]);
  });
}

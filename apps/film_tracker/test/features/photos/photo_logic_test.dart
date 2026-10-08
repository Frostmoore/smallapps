import 'package:film_tracker/features/photos/photo_logic.dart';
import 'package:flutter_test/flutter_test.dart';

/// F6.9: la logica pura di riordino, copertina e spazio occupato.
void main() {
  group('reorderIds (indice finale, come ReorderableListView.onReorderItem)', () {
    const ids = [10, 20, 30, 40];

    test('in avanti', () {
      expect(reorderIds(ids, 0, 2), [20, 30, 10, 40]);
      expect(reorderIds(ids, 0, 3), [20, 30, 40, 10]);
    });

    test("all'indietro", () {
      expect(reorderIds(ids, 3, 0), [40, 10, 20, 30]);
      expect(reorderIds(ids, 2, 1), [10, 30, 20, 40]);
    });

    test('sul posto non cambia niente', () {
      expect(reorderIds(ids, 1, 1), ids);
    });

    test('indici fuori misura non rompono e non perdono foto', () {
      expect(reorderIds(ids, 9, 0), ids);
      expect(reorderIds(ids, 0, 99), [20, 30, 40, 10]);
      expect(reorderIds(ids, 2, -5), [30, 10, 20, 40]);
      expect(reorderIds(const [], 0, 0), isEmpty);
    });

    test('non modifica la lista ricevuta', () {
      final original = [1, 2, 3];
      reorderIds(original, 0, 2);
      expect(original, [1, 2, 3]);
    });
  });

  group('coverAfterDelete', () {
    test('cancellare un\'altra foto lascia la copertina', () {
      expect(coverAfterDelete(idsInOrder: [1, 2, 3], currentCover: 2, deletedId: 3), 2);
    });

    test('cancellare la copertina passa alla prima foto rimasta', () {
      expect(coverAfterDelete(idsInOrder: [1, 2, 3], currentCover: 1, deletedId: 1), 2);
      expect(coverAfterDelete(idsInOrder: [1, 2, 3], currentCover: 3, deletedId: 3), 1);
    });

    test('senza copertina, la prende la prima foto rimasta', () {
      expect(coverAfterDelete(idsInOrder: [1, 2], currentCover: null, deletedId: 1), 2);
    });

    test('cancellata l\'ultima foto, nessuna copertina', () {
      expect(coverAfterDelete(idsInOrder: [5], currentCover: 5, deletedId: 5), isNull);
      expect(coverAfterDelete(idsInOrder: const [], currentCover: null, deletedId: 5), isNull);
    });
  });

  group('formatBytes', () {
    test('unita\' decimali e separatore della lingua', () {
      expect(formatBytes(0, 'it'), '0 B');
      expect(formatBytes(999, 'it'), '999 B');
      expect(formatBytes(850000, 'it'), '850 KB');
      expect(formatBytes(12300000, 'it'), '12,3 MB');
      expect(formatBytes(12300000, 'en'), '12.3 MB');
      expect(formatBytes(230000000, 'it'), '230 MB');
      expect(formatBytes(1200000000, 'it'), '1,2 GB');
      expect(formatBytes(5000000, 'it'), '5 MB');
    });
  });

  group('ImportProgress', () {
    test('frazione e copia', () {
      const p = ImportProgress(done: 1, total: 4);
      expect(p.fraction, 0.25);
      expect(p.copyWith(done: 4).fraction, 1);
      expect(p.copyWith(cancelling: true).cancelling, isTrue);
      expect(const ImportProgress(done: 0, total: 0).fraction, 1);
    });
  });
}

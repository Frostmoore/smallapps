import 'package:film_tracker/domain/film_catalog.dart';
import 'package:film_tracker/domain/film_types.dart';
import 'package:flutter_test/flutter_test.dart';

/// F6.2: il catalogo precaricato e le chiavi stabili dei formati e dei processi.
void main() {
  test('le 25 emulsioni del piano, senza doppioni', () {
    expect(kFilmCatalog, hasLength(25));
    expect({for (final s in kFilmCatalog) s.displayName}, hasLength(25));
    expect(
      [for (final s in kFilmCatalog) s.displayName],
      containsAll(<String>[
        'Kodak Gold 200',
        'Kodak Portra 400',
        'Kodak Tri-X 400',
        'Ilford HP5+',
        'Ilford XP2 Super',
        'Fomapan 400',
        'Fujifilm Velvia 50',
        'Cinestill 800T',
        'Lomography Color 400',
      ]),
    );
  });

  test('processi e ISO di qualche voce che e\' facile sbagliare', () {
    CatalogStock s(String name) => kFilmCatalog.singleWhere((c) => c.displayName == name);
    // XP2 e' un bianco e nero cromogenico: si sviluppa in C-41.
    expect(s('Ilford XP2 Super').process, FilmProcess.c41);
    expect(s('Fujifilm Velvia 50').process, FilmProcess.e6);
    expect(s('Fujifilm Provia 100F').process, FilmProcess.e6);
    expect(s('Ilford FP4+').iso, 125);
    expect(s('Kodak Tri-X 400').process, FilmProcess.bw);
    expect(kFilmCatalog.every((c) => c.format == FilmFormat.mm35), isTrue);
  });

  test('le chiavi salvate nel database sono quelle del piano e tornano indietro', () {
    expect([for (final f in FilmFormat.values) f.key], ['35mm', '120', '110', 'large', 'other']);
    expect([for (final p in FilmProcess.values) p.key], ['C-41', 'E-6', 'BW', 'ECN-2', 'other']);
    expect(
      [for (final k in RollImageKind.values) k.key],
      ['contactSheet', 'print', 'scan', 'other'],
    );
    for (final f in FilmFormat.values) {
      expect(FilmFormat.byKey(f.key), f);
    }
    for (final p in FilmProcess.values) {
      expect(FilmProcess.byKey(p.key), p);
    }
    for (final k in RollImageKind.values) {
      expect(RollImageKind.byKey(k.key), k);
    }
    expect(FilmFormat.byKey('8mm'), isNull);
    expect(FilmProcess.byKey(null), isNull);
  });

  test('fotogrammi preimpostati per formato', () {
    expect(FilmFormat.mm35.defaultFrames, 36);
    expect(FilmFormat.medium120.defaultFrames, 12);
    expect(FilmFormat.mm110.defaultFrames, 24);
  });
}

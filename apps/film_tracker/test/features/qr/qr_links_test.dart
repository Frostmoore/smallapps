import 'package:film_tracker/app/routes.dart';
import 'package:film_tracker/data/database.dart';
import 'package:film_tracker/data/film_repository.dart';
import 'package:film_tracker/domain/film_types.dart';
import 'package:film_tracker/features/qr/qr_links.dart';
import 'package:flutter_test/flutter_test.dart';

/// F6.12: il link del QR del rullino, l'unico testo che entra nell'app da fuori.
void main() {
  int? seq(String s) => sequenceFromUri(Uri.parse(s));

  group('sequenceFromUri', () {
    test('legge la forma che scriviamo nel QR', () {
      expect(seq(rollQrData(17)), 17);
      expect(rollQrData(17), 'filmtracker://roll/17');
    });

    test('tollera barra finale, host vuoto e maiuscole nello schema e nell\'host', () {
      expect(seq('filmtracker://roll/17/'), 17);
      expect(seq('filmtracker:///roll/17'), 17);
      expect(seq('FilmTracker://ROLL/3'), 3);
      expect(seq('filmtracker://roll/007'), 7);
    });

    test('rifiuta altri schemi e altri percorsi', () {
      expect(seq('https://roll/17'), isNull);
      expect(seq('fulfreezer://roll/17'), isNull);
      expect(seq('filmtracker://camera/17'), isNull);
      expect(seq('filmtracker://roll'), isNull);
      expect(seq('filmtracker://roll/'), isNull);
      expect(seq('filmtracker://roll/17/edit'), isNull);
      expect(seq('filmtracker://rolls/17'), isNull);
    });

    test('rifiuta numeri non positivi, segni, esponenti, esadecimali e numeri enormi', () {
      expect(seq('filmtracker://roll/0'), isNull);
      expect(seq('filmtracker://roll/-1'), isNull);
      expect(seq('filmtracker://roll/+17'), isNull);
      expect(seq('filmtracker://roll/1e3'), isNull);
      expect(seq('filmtracker://roll/0x11'), isNull);
      expect(seq('filmtracker://roll/17abc'), isNull);
      expect(seq('filmtracker://roll/%2017'), isNull);
      expect(seq('filmtracker://roll/1234567890'), isNull);
    });
  });

  group('locationForRollLink', () {
    late AppDatabase db;
    late FilmRepository repo;

    setUp(() {
      db = AppDatabase.memory();
      repo = FilmRepository(db);
    });
    tearDown(() => db.close());

    Future<int> roll() => repo.addRoll(filmName: 'Kodak Portra 400', format: FilmFormat.mm35, nominalIso: 400, frames: 36);

    test('porta al dettaglio del rullino con quel numero, per id', () async {
      await roll();
      final second = await roll();
      expect(await locationForRollLink(Uri.parse(rollQrData(2)), repo), Routes.rollOf(second));
    });

    test('null per un rullino che non c\'e\' o un link non nostro', () async {
      await roll();
      expect(await locationForRollLink(Uri.parse(rollQrData(9)), repo), isNull);
      expect(await locationForRollLink(Uri.parse('https://example.com'), repo), isNull);
    });

    test('listenRollLinks apre solo i link validi di rullini esistenti', () async {
      final id = await roll();
      final opened = <String>[];
      final sub = listenRollLinks(
        links: Stream.fromIterable([
          Uri.parse('filmtracker://roll/1'),
          Uri.parse('filmtracker://roll/5'),
          Uri.parse('other://roll/1'),
        ]),
        repository: () => repo,
        open: opened.add,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(opened, [Routes.rollOf(id)]);
    });
  });
}

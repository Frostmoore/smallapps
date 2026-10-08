import 'package:drift/drift.dart' show Value;
import 'package:film_tracker/data/database.dart';
import 'package:film_tracker/data/film_repository.dart';
import 'package:film_tracker/domain/film_catalog.dart';
import 'package:film_tracker/domain/film_types.dart';
import 'package:film_tracker/domain/roll_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
// I vincoli CHECK e UNIQUE violati arrivano come eccezione di sqlite3, non di drift.
import 'package:sqlite3/sqlite3.dart' show SqliteException;

/// F6.2: i vincoli dello schema e le regole che il repository fa rispettare a ogni scrittura.
void main() {
  late AppDatabase db;
  late FilmRepository repo;
  final now = DateTime.utc(2026, 10, 8, 12);

  setUp(() {
    db = AppDatabase.memory();
    repo = FilmRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  CivilDate d(String iso) => CivilDate.parse(iso);

  Future<int> roll({
    String film = 'Kodak Portra 400',
    int? cameraId,
    int? stockId,
    RollStatus status = RollStatus.loaded,
    int? costCents,
  }) => repo.addRoll(
    filmStockId: stockId,
    filmName: film,
    format: FilmFormat.mm35,
    nominalIso: 400,
    cameraId: cameraId,
    loadedAt: d('2026-09-01'),
    frames: 36,
    status: status,
    costCents: costCents,
  );

  StoredImage img(String name) => StoredImage(
    path: 'images/rolls/$name.jpg',
    thumbPath: 'thumbs/rolls/$name.jpg',
    width: 1600,
    height: 1067,
    bytes: 300000,
    createdAt: now,
  );

  group('catalogo', () {
    test('al primo avvio ci sono le 25 pellicole del catalogo, nessuna personalizzata', () async {
      final stocks = await repo.allStocks();
      expect(stocks, hasLength(kFilmCatalog.length));
      expect(stocks.every((s) => !s.isCustom), isTrue);
      expect(
        stocks.map((s) => s.displayName).toSet(),
        kFilmCatalog.map((c) => c.displayName).toSet(),
      );
      final portra = stocks.singleWhere((s) => s.displayName == 'Kodak Portra 400');
      expect(portra.iso, 400);
      expect(portra.processEnum, FilmProcess.c41);
      expect(portra.formatEnum, FilmFormat.mm35);
    });

    test('ordinate per marca e nome', () async {
      final brands = (await repo.allStocks()).map((s) => s.brand).toList();
      expect(brands.first, 'Cinestill');
      expect(brands.last, 'Lomography');
    });

    test('seedCatalog rilanciato non crea doppioni', () async {
      await db.seedCatalog();
      expect(await repo.allStocks(), hasLength(kFilmCatalog.length));
    });

    test('una pellicola personalizzata si aggiunge, si modifica e si cancella', () async {
      final id = await repo.addCustomStock(
        brand: ' Kodak ',
        name: 'Vision3 250D',
        iso: 250,
        process: FilmProcess.ecn2,
        format: FilmFormat.mm35,
      );
      final s = (await repo.stockById(id))!;
      expect(s.isCustom, isTrue);
      expect(s.brand, 'Kodak');
      await repo.updateCustomStock(s.copyWith(iso: 200));
      expect((await repo.stockById(id))!.iso, 200);
      await repo.deleteCustomStock(id);
      expect(await repo.stockById(id), isNull);
    });

    test('un doppione a meno di maiuscole e\' rifiutato e indica l\'esistente', () async {
      final portra = (await repo.allStocks()).singleWhere(
        (s) => s.displayName == 'Kodak Portra 400',
      );
      await expectLater(
        repo.addCustomStock(
          brand: 'kodak',
          name: 'PORTRA 400 ',
          iso: 400,
          process: FilmProcess.c41,
          format: FilmFormat.mm35,
        ),
        throwsA(isA<DuplicateFilmStockException>().having((e) => e.existingId, 'id', portra.id)),
      );
      // Lo stesso nome in un altro formato e' un'altra pellicola.
      await repo.addCustomStock(
        brand: 'Kodak',
        name: 'Portra 400',
        iso: 400,
        process: FilmProcess.c41,
        format: FilmFormat.medium120,
      );
    });

    test('le pellicole del catalogo non si modificano ne\' si cancellano', () async {
      final gold = (await repo.allStocks()).first;
      await expectLater(repo.deleteCustomStock(gold.id), throwsArgumentError);
      await expectLater(repo.updateCustomStock(gold.copyWith(iso: 1)), throwsArgumentError);
    });

    test('cancellare una pellicola lascia il rullino con il suo filmName', () async {
      final id = await repo.addCustomStock(
        brand: 'Rollei',
        name: 'Retro 80S',
        iso: 80,
        process: FilmProcess.bw,
        format: FilmFormat.mm35,
      );
      final r = await roll(film: 'Rollei Retro 80S', stockId: id);
      await repo.deleteCustomStock(id);
      final after = (await repo.rollById(r))!;
      expect(after.filmStockId, isNull);
      expect(after.filmName, 'Rollei Retro 80S');
    });

    test(
      'le piu\' usate: per numero di rullini, poi per uso piu\' recente, al massimo 5',
      () async {
        final stocks = await repo.allStocks();
        int idOf(String n) => stocks.singleWhere((s) => s.displayName == n).id;
        final portra = idOf('Kodak Portra 400');
        final hp5 = idOf('Ilford HP5+');
        final gold = idOf('Kodak Gold 200');
        await roll(stockId: hp5);
        await roll(stockId: portra);
        await roll(stockId: portra);
        await roll(stockId: gold); // stesso conteggio di HP5+, ma piu' recente
        for (final n in ['Kodak Ektar 100', 'Fujifilm C200', 'Cinestill 800T']) {
          await roll(stockId: idOf(n));
        }
        final top = await repo.mostUsedStocks();
        expect(top, hasLength(5));
        expect(top[0].id, portra);
        // Tutte le altre hanno un rullino: vince la piu' recente, cioe' l'ultima inserita.
        expect(top[1].displayName, 'Cinestill 800T');
        expect(top.map((s) => s.id), isNot(contains(hp5)));
        expect(await repo.mostUsedStocks(limit: 1), hasLength(1));
      },
    );
  });

  group('macchine', () {
    test('si aggiungono in fondo e contano i loro rullini', () async {
      final a = await repo.addCamera(
        manufacturer: 'Olympus',
        model: 'OM-2',
        format: FilmFormat.mm35,
      );
      final b = await repo.addCamera(
        manufacturer: 'Yashica',
        model: 'Mat-124G',
        format: FilmFormat.medium120,
      );
      final c = await repo.addCamera(manufacturer: 'Nikon', model: 'FM2', format: FilmFormat.mm35);
      expect([for (final x in await repo.allCameras()) x.id], [a, b, c]);
      expect(await repo.cameraCount(), 3);
      await roll(cameraId: a);
      await roll(cameraId: a);
      await roll(cameraId: b);
      await roll();
      expect(await repo.rollCountByCamera(), {a: 2, b: 1});
      await repo.reorderCameras([c, a, b]);
      expect([for (final x in await repo.allCameras()) x.id], [c, a, b]);
    });

    test('disattivata sparisce dalla scelta ma resta nell\'inventario', () async {
      final a = await repo.addCamera(
        manufacturer: 'Olympus',
        model: 'OM-2',
        format: FilmFormat.mm35,
      );
      await repo.setCameraActive(a, false);
      expect(await repo.allCameras(activeOnly: true), isEmpty);
      expect(await repo.allCameras(), hasLength(1));
    });

    test('cancellarla stacca i rullini, non li cancella', () async {
      final a = await repo.addCamera(
        manufacturer: 'Olympus',
        model: 'OM-2',
        format: FilmFormat.mm35,
      );
      final r = await roll(cameraId: a);
      await repo.deleteCamera(a);
      expect((await repo.rollById(r))!.cameraId, isNull);
    });

    test('il formato fuori dal catalogo delle chiavi e\' rifiutato dal CHECK', () async {
      await expectLater(
        db
            .into(db.cameras)
            .insert(CamerasCompanion.insert(manufacturer: 'X', model: 'Y', format: '8mm')),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('rullini', () {
    test('sequenceNumber e\' max + 1, anche dopo una cancellazione in mezzo', () async {
      expect(await repo.nextSequenceNumber(), 1);
      final a = await roll();
      final b = await roll();
      final c = await roll();
      expect(
        [
          for (final id in [a, b, c]) (await repo.rollById(id))!.sequenceNumber,
        ],
        [1, 2, 3],
      );
      await repo.deleteRollAndCollectImagePaths(b);
      final e = await roll();
      expect((await repo.rollById(e))!.sequenceNumber, 4);
      expect((await repo.rollBySequence(4))!.id, e);
      expect(await repo.rollBySequence(2), isNull);
    });

    test('sequenceNumber e\' UNIQUE nello schema', () async {
      await roll();
      await expectLater(
        db
            .into(db.filmRolls)
            .insert(
              FilmRollsCompanion.insert(
                sequenceNumber: 1,
                filmName: 'X',
                format: '35mm',
                nominalIso: 100,
                exposedIso: 100,
                frames: 36,
                status: 'loaded',
                createdAt: 0,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('valori di default: ISO esposto = nominale, createdAt dall\'orologio', () async {
      final r = (await repo.rollById(await roll()))!;
      expect(r.exposedIso, 400);
      expect(r.isPushPull, isFalse);
      expect(r.statusEnum, RollStatus.loaded);
      expect(r.section, RollSection.inCamera);
      expect(r.createdAt, now.millisecondsSinceEpoch);
      expect(r.loadedDate, d('2026-09-01'));
    });

    test('i CHECK: stato sconosciuto, fine prima del caricamento, costo negativo', () async {
      final id = await roll();
      final r = (await repo.rollById(id))!;
      await expectLater(
        (db.update(
          db.filmRolls,
        )..where((t) => t.id.equals(id))).write(const FilmRollsCompanion(status: Value('lost'))),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        repo.updateRoll(r.copyWith(finishedAt: const Value('2026-08-01'))),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        repo.updateRoll(r.copyWith(costCents: const Value(-1))),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(repo.updateRoll(r.copyWith(frames: 0)), throwsA(isA<SqliteException>()));
    });

    test('updateRoll non tocca stato, numero e copertina', () async {
      final id = await roll();
      final r = (await repo.rollById(id))!;
      await repo.updateRoll(
        r.copyWith(
          title: const Value('  Praga  '),
          status: 'archived',
          sequenceNumber: 99,
          exposedIso: 800,
        ),
      );
      final after = (await repo.rollById(id))!;
      expect(after.title, 'Praga');
      expect(after.exposedIso, 800);
      expect(after.isPushPull, isTrue);
      expect(after.status, 'loaded');
      expect(after.sequenceNumber, 1);
    });

    test('setRollStatus: ammesse passano, vietate lanciano, force passa sempre', () async {
      final id = await roll();
      await repo.setRollStatus(id, RollStatus.exposed);
      expect((await repo.rollById(id))!.statusEnum, RollStatus.exposed);
      await expectLater(
        repo.setRollStatus(id, RollStatus.printed),
        throwsA(isA<RollTransitionException>()),
      );
      await repo.setRollStatus(id, RollStatus.printed, force: true);
      expect((await repo.rollById(id))!.statusEnum, RollStatus.printed);
      // Lo stesso stato non e' un errore.
      await repo.setRollStatus(id, RollStatus.printed);
      await expectLater(repo.setRollStatus(999, RollStatus.exposed), throwsStateError);
    });

    test(
      'markFinished: data di fine e loaded -> exposed; in un altro stato solo la data',
      () async {
        final id = await roll();
        await repo.markFinished(id, d('2026-09-20'));
        var r = (await repo.rollById(id))!;
        expect(r.finishedDate, d('2026-09-20'));
        expect(r.statusEnum, RollStatus.exposed);
        await repo.setRollStatus(id, RollStatus.sentForDevelopment);
        await repo.markFinished(id, d('2026-09-21'));
        r = (await repo.rollById(id))!;
        expect(r.finishedDate, d('2026-09-21'));
        expect(r.statusEnum, RollStatus.sentForDevelopment);
      },
    );

    test('le sezioni della home filtrano per stato, dal numero piu\' alto', () async {
      final a = await roll();
      final b = await roll(status: RollStatus.exposed);
      final c = await roll(status: RollStatus.sentForDevelopment);
      final e = await roll(status: RollStatus.printed);
      final f = await roll(status: RollStatus.archived);
      List<int> ids(List<FilmRoll> rs) => [for (final r in rs) r.id];
      expect(ids(await repo.allRolls(section: RollSection.inCamera)), [b, a]);
      expect(ids(await repo.allRolls(section: RollSection.atLab)), [c]);
      expect(ids(await repo.allRolls(section: RollSection.archive)), [f, e]);
      expect(ids(await repo.allRolls()), [f, e, c, b, a]);
    });
  });

  group('sviluppo e stampe', () {
    test('al massimo uno sviluppo: il secondo salvataggio sostituisce il primo', () async {
      final r = await roll();
      final first = await repo.saveDevelopment(
        rollId: r,
        laboratory: 'Fotoservice',
        submittedAt: d('2026-09-21'),
        developmentCostCents: 1200,
      );
      final second = await repo.saveDevelopment(
        rollId: r,
        laboratory: 'Labo',
        submittedAt: d('2026-09-21'),
        returnedAt: d('2026-09-30'),
        process: FilmProcess.c41,
      );
      expect(second, first);
      final dev = (await repo.developmentFor(r))!;
      expect(dev.laboratory, 'Labo');
      expect(dev.returnedDate, d('2026-09-30'));
      // Riscrive tutto: il costo non passato e' tornato null.
      expect(dev.developmentCostCents, isNull);
      expect(dev.processEnum, FilmProcess.c41);
      expect(await db.select(db.developments).get(), hasLength(1));
    });

    test('lo schema rifiuta un secondo sviluppo scritto a mano (UNIQUE)', () async {
      final r = await roll();
      await repo.saveDevelopment(rollId: r);
      await expectLater(
        db.into(db.developments).insert(DevelopmentsCompanion.insert(filmRollId: r)),
        throwsA(isA<SqliteException>()),
      );
    });

    test('il ritorno non puo\' precedere la consegna', () async {
      final r = await roll();
      await expectLater(
        repo.saveDevelopment(rollId: r, submittedAt: d('2026-09-10'), returnedAt: d('2026-09-09')),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        repo.addPrintOrder(rollId: r, submittedAt: d('2026-09-10'), returnedAt: d('2026-09-09')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('stampe multiple, dalla consegna piu\' vecchia; senza data in fondo', () async {
      final r = await roll();
      final senzaData = await repo.addPrintOrder(rollId: r, laboratory: 'Labo', numberOfPrints: 2);
      final tardi = await repo.addPrintOrder(rollId: r, submittedAt: d('2026-12-01'));
      final presto = await repo.addPrintOrder(
        rollId: r,
        laboratory: '  Fotoservice ',
        submittedAt: d('2026-10-01'),
        format: '10x15',
        numberOfPrints: 36,
        costCents: 1800,
      );
      final prints = await repo.printsFor(r);
      expect([for (final p in prints) p.id], [presto, tardi, senzaData]);
      expect(prints.first.laboratory, 'Fotoservice');
      await repo.updatePrintOrder(prints.first.copyWith(costCents: const Value(2000)));
      expect((await repo.printById(presto))!.costCents, 2000);
      await repo.deletePrintOrder(tardi);
      expect(await repo.printsFor(r), hasLength(2));
    });

    test('suggestedStatus legge sviluppo e stampe del rullino', () async {
      final r = await roll(status: RollStatus.exposed);
      expect(await repo.suggestedStatus(r), RollStatus.exposed);
      await repo.saveDevelopment(rollId: r, submittedAt: d('2026-09-21'));
      expect(await repo.suggestedStatus(r), RollStatus.sentForDevelopment);
      await repo.saveDevelopment(
        rollId: r,
        submittedAt: d('2026-09-21'),
        returnedAt: d('2026-09-28'),
      );
      expect(await repo.suggestedStatus(r), RollStatus.developed);
      await repo.addPrintOrder(
        rollId: r,
        submittedAt: d('2026-10-01'),
        returnedAt: d('2026-10-05'),
      );
      expect(await repo.suggestedStatus(r), RollStatus.printed);
      expect(await repo.suggestedStatus(999), isNull);
    });

    test('i laboratori usati: dal piu\' frequente, senza doppioni di maiuscole', () async {
      final r1 = await roll();
      final r2 = await roll();
      await repo.saveDevelopment(rollId: r1, laboratory: 'Fotoservice');
      await repo.saveDevelopment(rollId: r2, laboratory: 'Labo');
      await repo.addPrintOrder(rollId: r1, laboratory: 'labo ');
      await repo.addPrintOrder(rollId: r1, laboratory: 'Alfa');
      await repo.addPrintOrder(rollId: r2, laboratory: '   ');
      expect(await repo.usedLaboratories(), ['Labo', 'Alfa', 'Fotoservice']);
    });
  });

  group('immagini e cancellazioni', () {
    test('la prima immagine diventa la copertina; l\'ordine e\' quello di inserimento', () async {
      final r = await roll();
      final a = await repo.addImage(rollId: r, image: img('a'));
      final b = await repo.addImage(rollId: r, image: img('b'), kind: RollImageKind.print);
      expect((await repo.rollById(r))!.coverImageId, a);
      expect([for (final i in await repo.imagesFor(r)) i.id], [a, b]);
      await repo.reorderImages([b, a]);
      expect([for (final i in await repo.imagesFor(r)) i.id], [b, a]);
      await repo.setCoverImage(r, b);
      expect((await repo.rollById(r))!.coverImageId, b);
    });

    test('la copertina deve essere un\'immagine dello stesso rullino', () async {
      final r1 = await roll();
      final r2 = await roll();
      final altrui = await repo.addImage(rollId: r2, image: img('x'));
      await expectLater(repo.setCoverImage(r1, altrui), throwsArgumentError);
    });

    test('cancellare la copertina lascia il rullino senza (setNull)', () async {
      final r = await roll();
      final a = await repo.addImage(rollId: r, image: img('a'));
      final stored = await repo.deleteImage(a);
      expect(stored!.path, 'images/rolls/a.jpg');
      expect((await repo.rollById(r))!.coverImageId, isNull);
      expect(await repo.deleteImage(a), isNull);
    });

    test(
      'cancellare un rullino porta via sviluppo, stampe e immagini e restituisce i file',
      () async {
        final r = await roll();
        final altro = await roll();
        await repo.saveDevelopment(rollId: r, laboratory: 'Labo');
        await repo.addPrintOrder(rollId: r);
        await repo.addPrintOrder(rollId: r);
        await repo.addImage(rollId: r, image: img('a'));
        await repo.addImage(rollId: r, image: img('b'));
        await repo.addImage(rollId: altro, image: img('c'));

        final paths = await repo.deleteRollAndCollectImagePaths(r);
        expect(paths, [
          'images/rolls/a.jpg',
          'thumbs/rolls/a.jpg',
          'images/rolls/b.jpg',
          'thumbs/rolls/b.jpg',
        ]);
        expect(await repo.rollById(r), isNull);
        expect(await repo.developmentFor(r), isNull);
        expect(await repo.printsFor(r), isEmpty);
        expect(await repo.imagesFor(r), isEmpty);
        // L'altro rullino non e' toccato.
        expect(await repo.imagesFor(altro), hasLength(1));
        expect(await repo.allImagePaths(), {'images/rolls/c.jpg', 'thumbs/rolls/c.jpg'});
      },
    );
  });

  group('stream e righe composte', () {
    test('watchRollItems unisce macchina, sviluppo, stampe e copertina', () async {
      final cam = await repo.addCamera(
        manufacturer: 'Olympus',
        model: 'OM-2',
        format: FilmFormat.mm35,
      );
      final r = await roll(cameraId: cam, status: RollStatus.developed);
      await repo.saveDevelopment(rollId: r, laboratory: 'Labo', returnedAt: d('2026-09-30'));
      await repo.addPrintOrder(rollId: r, costCents: 900);
      final cover = await repo.addImage(rollId: r, image: img('a'));
      await roll(); // in macchina: non deve comparire nell'archivio

      final items = await repo.watchRollItems(section: RollSection.archive).first;
      expect(items, hasLength(1));
      final it = items.single;
      expect(it.camera!.displayName, 'Olympus OM-2');
      expect(it.development!.laboratory, 'Labo');
      expect(it.prints.single.costCents, 900);
      expect(it.cover!.id, cover);
      expect(it.section, RollSection.archive);
    });

    test('lo stream si riemette quando cambia una tabella collegata', () async {
      final r = await roll();
      final stream = repo.watchRollItems();
      final seen = <int?>[];
      final sub = stream.listen((items) => seen.add(items.single.development?.id));
      await pumpEventQueue();
      await repo.saveDevelopment(rollId: r, laboratory: 'Labo');
      await pumpEventQueue();
      await sub.cancel();
      expect(seen.first, isNull);
      expect(seen.last, isNotNull);
    });

    test('statsRolls: la data e\' il caricamento, o il giorno di creazione', () async {
      final r = await roll(costCents: 1890);
      await repo.saveDevelopment(rollId: r, laboratory: 'Labo', developmentCostCents: 1000);
      await repo.addPrintOrder(rollId: r, laboratory: 'Labo', costCents: 500);
      await repo.addRoll(filmName: 'X', format: FilmFormat.mm35, nominalIso: 100, frames: 36);
      final s = await repo.statsRolls();
      expect(s, hasLength(2));
      final senzaData = s.firstWhere((x) => x.filmName == 'X');
      expect(senzaData.date, CivilDate.fromDateTime(now));
      final conData = s.firstWhere((x) => x.filmName == 'Kodak Portra 400');
      expect(conData.date, d('2026-09-01'));
      expect(conData.development!.developmentCostCents, 1000);
      expect(conData.prints.single.costCents, 500);
    });
  });
}

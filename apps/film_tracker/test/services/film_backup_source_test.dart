import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:film_tracker/data/database.dart';
import 'package:film_tracker/data/film_repository.dart';
import 'package:film_tracker/domain/film_types.dart';
import 'package:film_tracker/domain/roll_status.dart';
import 'package:film_tracker/services/film_backup_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

/// F6.11: il backup completo **con le immagini** fa andata e ritorno. Il file e' lo ZIP vero
/// di `BackupService` (data.json + images/), scritto e riletto da disco fra due "telefoni":
/// due database in memoria e due cartelle documenti diverse.
void main() {
  // Due database distinti (telefono vecchio e nuovo): l'avviso di drift riguarda chi condivide
  // lo stesso file, non questo caso.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late AppDatabase vecchioDb;
  late FilmRepository vecchio;
  late AppPaths vecchiePaths;
  late AppDatabase nuovoDb;
  late FilmRepository nuovo;
  late AppPaths nuovePaths;
  final now = DateTime.utc(2026, 10, 8, 12);
  CivilDate d(String iso) => CivilDate.parse(iso);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('ft_backup_');
    vecchioDb = AppDatabase.memory();
    vecchio = FilmRepository(vecchioDb, clock: () => now);
    vecchiePaths = AppPaths.underRoot(Directory('${tmp.path}/vecchio'));
    nuovoDb = AppDatabase.memory();
    nuovo = FilmRepository(nuovoDb, clock: () => now.add(const Duration(days: 1)));
    nuovePaths = AppPaths.underRoot(Directory('${tmp.path}/nuovo'));
  });

  tearDown(() async {
    await vecchioDb.close();
    await nuovoDb.close();
    await tmp.delete(recursive: true);
  });

  /// Un'immagine "salvata da ImageStore": i due file su disco e la riga nel database. I byte
  /// sono finti ma distinti, cosi' il ripristino si verifica byte per byte.
  Future<int> foto(FilmRepository repo, AppPaths paths, int rollId, String nome, {RollImageKind kind = RollImageKind.contactSheet}) async {
    final image = StoredImage(
      path: 'images/rolls/$nome.jpg',
      thumbPath: 'images/thumbs/rolls/$nome.jpg',
      width: 1600,
      height: 1067,
      bytes: 3,
      createdAt: now,
    );
    for (final (rel, tag) in [(image.path, 'full'), (image.thumbPath, 'thumb')]) {
      final f = paths.resolve(rel);
      await f.parent.create(recursive: true);
      await f.writeAsString('$tag-$nome');
    }
    return repo.addImage(rollId: rollId, image: image, kind: kind);
  }

  /// Il telefono vecchio: due macchine (una dismessa), una pellicola personalizzata, tre
  /// rullini. Il #2 ha sviluppo, due stampe, tre foto e la copertina sulla seconda.
  Future<void> riempi() async {
    final om2 = await vecchio.addCamera(manufacturer: 'Olympus', model: 'OM-2', format: FilmFormat.mm35);
    final rollei = await vecchio.addCamera(manufacturer: 'Rollei', model: '35', format: FilmFormat.mm35, note: 'della nonna');
    await vecchio.setCameraActive(rollei, false);
    final vision = await vecchio.addCustomStock(
      brand: 'Kodak',
      name: 'Vision3 250D',
      iso: 250,
      process: FilmProcess.ecn2,
      format: FilmFormat.mm35,
    );
    final portra = (await vecchio.allStocks()).firstWhere((s) => s.brand == 'Kodak' && s.name == 'Portra 400' && s.format == '35mm');

    await vecchio.addRoll(
      filmStockId: portra.id,
      filmName: 'Kodak Portra 400',
      format: FilmFormat.mm35,
      nominalIso: 400,
      cameraId: om2,
      loadedAt: d('2026-01-10'),
      frames: 36,
      costCents: 1590,
      status: RollStatus.archived,
    );
    final due = await vecchio.addRoll(
      filmStockId: vision,
      filmName: 'Kodak Vision3 250D',
      format: FilmFormat.mm35,
      nominalIso: 250,
      exposedIso: 500,
      cameraId: rollei,
      loadedAt: d('2026-03-01'),
      finishedAt: d('2026-03-20'),
      frames: 36,
      title: 'Praga',
      note: 'push di uno stop',
      costCents: 1200,
      status: RollStatus.printed,
    );
    await vecchio.saveDevelopment(
      rollId: due,
      laboratory: 'Fotoservice',
      submittedAt: d('2026-03-21'),
      returnedAt: d('2026-03-30'),
      developmentCostCents: 900,
      scanCostCents: 500,
      process: FilmProcess.ecn2,
    );
    await vecchio.addPrintOrder(rollId: due, laboratory: 'Fotoservice', format: '10x15', numberOfPrints: 12, costCents: 600);
    await vecchio.addPrintOrder(rollId: due, laboratory: 'Lab Roma', submittedAt: d('2026-05-02'));
    await foto(vecchio, vecchiePaths, due, 'a');
    final b = await foto(vecchio, vecchiePaths, due, 'b', kind: RollImageKind.print);
    await foto(vecchio, vecchiePaths, due, 'c', kind: RollImageKind.scan);
    await vecchio.setCoverImage(due, b);

    await vecchio.addRoll(filmName: 'Ilford HP5 Plus', format: FilmFormat.medium120, nominalIso: 400, frames: 12);
  }

  /// Crea lo ZIP sul telefono vecchio.
  Future<File> backup() async {
    final service = BackupService(paths: vecchiePaths, appVersion: 'test');
    final created = await service.createBackup(FilmBackupSource(vecchioDb, paths: vecchiePaths), includeImages: true);
    expect(created.isOk, isTrue, reason: '${created.errorOrNull}');
    final file = created.valueOrNull!;
    expect(file.path, endsWith('.zip'));
    return file;
  }

  Future<Result<void>> ripristina(File file, ImportMode mode) => BackupService(paths: nuovePaths, appVersion: 'test')
      .restore(file, FilmBackupSource(nuovoDb, paths: nuovePaths), mode: mode);

  group('sostituisci tutto', () {
    test('riporta macchine, pellicole, rullini, sviluppo, stampe, foto e copertina', () async {
      await riempi();
      final zip = await backup();

      // Il telefono nuovo ha gia' un rullino con una foto: deve sparire, file compreso.
      final suo = await nuovo.addRoll(filmName: 'Fomapan 100', format: FilmFormat.mm35, nominalIso: 100, frames: 36);
      await foto(nuovo, nuovePaths, suo, 'vecchia');
      expect(nuovePaths.resolve('images/rolls/vecchia.jpg').existsSync(), isTrue);

      final esito = await ripristina(zip, ImportMode.replaceAll);
      expect(esito.isOk, isTrue, reason: '${esito.errorOrNull}');

      final cams = await nuovo.allCameras();
      expect(cams.map((c) => '${c.manufacturer} ${c.model} ${c.active}'), ['Olympus OM-2 true', 'Rollei 35 false']);
      expect(cams.last.note, 'della nonna');

      final rolls = await nuovo.allRolls();
      expect(rolls.map((r) => (r.sequenceNumber, r.filmName)), [
        (3, 'Ilford HP5 Plus'),
        (2, 'Kodak Vision3 250D'),
        (1, 'Kodak Portra 400'),
      ], reason: 'i numeri restano quelli delle etichette QR, il Fomapan non c\'e\' piu\'');

      final due = rolls.firstWhere((r) => r.sequenceNumber == 2);
      expect(due.exposedIso, 500);
      expect(due.loadedAt, '2026-03-01');
      expect(due.finishedAt, '2026-03-20');
      expect(due.title, 'Praga');
      expect(due.note, 'push di uno stop');
      expect(due.costCents, 1200);
      expect(due.statusEnum, RollStatus.printed);
      expect((await nuovo.cameraById(due.cameraId!))!.model, '35');
      final stock = (await nuovo.stockById(due.filmStockId!))!;
      expect((stock.name, stock.isCustom), ('Vision3 250D', true), reason: 'la pellicola personalizzata torna e si ricollega');
      final uno = rolls.firstWhere((r) => r.sequenceNumber == 1);
      expect((await nuovo.stockById(uno.filmStockId!))!.name, 'Portra 400', reason: 'il catalogo si ritrova da marca, nome, formato');

      final dev = (await nuovo.developmentFor(due.id))!;
      expect((dev.laboratory, dev.submittedAt, dev.returnedAt, dev.developmentCostCents, dev.scanCostCents, dev.process),
          ('Fotoservice', '2026-03-21', '2026-03-30', 900, 500, 'ECN-2'));
      final prints = await nuovo.printsFor(due.id);
      expect(prints.map((p) => (p.laboratory, p.numberOfPrints, p.costCents, p.submittedAt)).toSet(), {
        ('Fotoservice', 12, 600, null),
        ('Lab Roma', null, null, '2026-05-02'),
      });

      // Le foto: righe nell'ordine, tipo, copertina, e file identici a quelli di partenza.
      final images = await nuovo.imagesFor(due.id);
      expect(images.map((i) => i.path), ['images/rolls/a.jpg', 'images/rolls/b.jpg', 'images/rolls/c.jpg']);
      expect(images.map((i) => i.kindEnum), [RollImageKind.contactSheet, RollImageKind.print, RollImageKind.scan]);
      expect(due.coverImageId, images[1].id, reason: 'la copertina e\' la seconda foto, ricucita dopo l\'inserimento');
      for (final i in images) {
        final nome = i.path.split('/').last.replaceAll('.jpg', '');
        expect(await nuovePaths.resolve(i.path).readAsString(), 'full-$nome');
        expect(await nuovePaths.resolve(i.thumbPath).readAsString(), 'thumb-$nome');
      }

      // La foto del rullino sostituito non resta orfana sul telefono.
      expect(nuovePaths.resolve('images/rolls/vecchia.jpg').existsSync(), isFalse);
      expect(nuovePaths.resolve('images/thumbs/rolls/vecchia.jpg').existsSync(), isFalse);

      expect(await FilmBackupSource(nuovoDb).counts(), {'rolls': 3, 'cameras': 2, 'images': 3});
    });

    test('ripristinare sullo stesso telefono non perde le foto che il file riscrive', () async {
      await riempi();
      final zip = await backup();
      final esito = await BackupService(paths: vecchiePaths, appVersion: 'test')
          .restore(zip, FilmBackupSource(vecchioDb, paths: vecchiePaths), mode: ImportMode.replaceAll);
      expect(esito.isOk, isTrue);
      expect(await vecchiePaths.resolve('images/rolls/b.jpg').readAsString(), 'full-b');
      expect(await vecchio.allRolls(), hasLength(3));
    });
  });

  group('aggiungi', () {
    test('tiene i rullini del telefono, rinumera solo i numeri occupati e non duplica le macchine', () async {
      await riempi();
      final zip = await backup();

      final om2 = await nuovo.addCamera(manufacturer: 'olympus', model: 'om-2 ', format: FilmFormat.mm35);
      await nuovo.addRoll(filmName: 'Fomapan 100', format: FilmFormat.mm35, nominalIso: 100, frames: 36, cameraId: om2);

      final esito = await ripristina(zip, ImportMode.mergeKeepExisting);
      expect(esito.isOk, isTrue, reason: '${esito.errorOrNull}');

      final rolls = await nuovo.allRolls();
      expect(rolls.map((r) => (r.sequenceNumber, r.filmName)).toSet(), {
        (1, 'Fomapan 100'),
        (2, 'Kodak Vision3 250D'),
        (3, 'Ilford HP5 Plus'),
        (4, 'Kodak Portra 400'),
      }, reason: 'il #1 era occupato: il Portra prende il primo libero dopo il massimo, gli altri tengono il loro');

      final cams = await nuovo.allCameras();
      expect(cams, hasLength(2), reason: 'OM-2 a meno di maiuscole e spazi e\' la stessa macchina');
      expect(rolls.firstWhere((r) => r.filmName == 'Kodak Portra 400').cameraId, om2);
      expect(cams.last.sortOrder, greaterThan(cams.first.sortOrder), reason: 'le macchine nuove vanno in fondo');

      final due = rolls.firstWhere((r) => r.sequenceNumber == 2);
      expect(await nuovo.imagesFor(due.id), hasLength(3));
      expect(await nuovePaths.resolve('images/rolls/c.jpg').readAsString(), 'full-c');

      // Lo stesso backup una seconda volta non duplica niente.
      expect((await ripristina(zip, ImportMode.mergeKeepExisting)).isOk, isTrue);
      expect(await nuovo.allRolls(), hasLength(4));
      expect(await nuovo.allCameras(), hasLength(2));
      expect((await nuovo.allStocks()).where((s) => s.isCustom), hasLength(1));
    });
  });

  group('file rovinati', () {
    Future<Map<String, Object?>> payload() async =>
        (jsonDecode(jsonEncode(await FilmBackupSource(vecchioDb).exportPayload())) as Map).cast<String, Object?>();

    test('un percorso d\'immagine fuori dalla cartella dell\'app e\' un FormatException e non scrive niente', () async {
      await riempi();
      final p = await payload();
      final roll = (p['rolls']! as List).cast<Map<String, Object?>>().firstWhere((r) => r['sequenceNumber'] == 2);
      ((roll['images']! as List).first as Map)['path'] = 'images/../../segreti.txt';

      await nuovo.addRoll(filmName: 'Fomapan 100', format: FilmFormat.mm35, nominalIso: 100, frames: 36);
      await expectLater(
        FilmBackupSource(nuovoDb, paths: nuovePaths).importPayload(p, mode: ImportMode.replaceAll),
        throwsA(isA<FormatException>()),
      );
      expect((await nuovo.allRolls()).single.filmName, 'Fomapan 100', reason: 'transazione annullata');
    });

    test('uno stato sconosciuto o un campo del tipo sbagliato sono FormatException', () async {
      await riempi();
      final p = await payload();
      (p['rolls']! as List).cast<Map<String, Object?>>().first['status'] = 'perso';
      await expectLater(
        FilmBackupSource(nuovoDb).importPayload(p, mode: ImportMode.replaceAll),
        throwsA(isA<FormatException>()),
      );
      final q = await payload();
      (q['rolls']! as List).cast<Map<String, Object?>>().first['frames'] = 'trentasei';
      await expectLater(
        FilmBackupSource(nuovoDb).importPayload(q, mode: ImportMode.replaceAll),
        throwsA(isA<FormatException>()),
      );
      expect(await nuovo.allRolls(), isEmpty);
    });
  });
}

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/film_catalog.dart';
import '../domain/film_types.dart';
import '../domain/roll_status.dart';
import 'tables.dart';

export 'tables.dart' show filmFormatKeys, filmProcessKeys, rollImageKindKeys, rollStatusKeys;

part 'database.g.dart';

/// Il database di Film Tracker.
///
/// Le date di calendario sono TEXT `YYYY-MM-DD` (ADR-008), gli istanti millisecondi UTC, i
/// soldi centesimi interi. Le query vivono in `FilmRepository`, non qui: il database dichiara
/// la forma dei dati, il repository le regole per scriverli (numero progressivo, transizioni
/// di stato, copertina dello stesso rullino), che nessun vincolo SQL puo' esprimere.
@DriftDatabase(tables: [Cameras, FilmStocks, FilmRolls, Developments, PrintOrders, RollImages])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Database su file, nella cartella documenti dell'app.
  factory AppDatabase.open() => AppDatabase(_openConnection());

  /// Database in memoria, per i test. Non tocca il disco. Il catalogo e' gia' caricato.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // ⚑ Il catalogo si carica alla **creazione**, una volta sola: non a ogni avvio, che
      // resusciterebbe le pellicole che l'utente ha cancellato o ritoccato. Le voci aggiunte
      // in futuro a kFilmCatalog arriveranno agli utenti esistenti con una migrazione.
      await seedCatalog();
    },
    beforeOpen: (details) async {
      // ☠ `PRAGMA foreign_keys` non e' attivo di default in SQLite e va impostato su ogni
      // connessione. Senza, i cascade sono decorativi: cancellare un rullino lascerebbe
      // sviluppi, stampe e immagini orfani. Stessa trappola gia' pagata nelle altre app.
      await customStatement('PRAGMA foreign_keys = ON');
    },
    // Alla versione 1 non esistono migrazioni. Il ramo resta scritto perche' la prima
    // modifica di schema dovra' incrementare schemaVersion E aggiungere qui il passo, con il
    // suo test: senza, il primo aggiornamento in produzione cancella i dati degli utenti.
    onUpgrade: (m, from, to) async {
      throw UnsupportedError(
        'Migrazione da schema $from a $to non implementata. '
        'Aggiungere il passo in AppDatabase.migration e il relativo test.',
      );
    },
  );

  /// Scrive [kFilmCatalog] in `film_stocks` (`isCustom` false), saltando le voci gia'
  /// presenti (`UNIQUE(brand, name, format)`). La chiama `onCreate`; e' pubblica per il
  /// ripristino di un backup e per una futura migrazione che aggiunga emulsioni.
  Future<void> seedCatalog() => batch((b) {
    b.insertAll(filmStocks, [
      for (final s in kFilmCatalog)
        FilmStocksCompanion.insert(
          brand: s.brand,
          name: s.name,
          iso: s.iso,
          process: s.process.key,
          format: s.format.key,
        ),
    ], mode: InsertMode.insertOrIgnore);
  });
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'film_tracker.sqlite'));

  // ☠ Su Android la cartella temporanea di sistema non e' scrivibile dal processo dell'app:
  // senza questa riga VACUUM e alcuni ORDER BY grandi falliscono con "unable to open
  // database file", e solo su dispositivo, mai in test. Vedi apps/trashcan.
  sqlite3.tempDirectory = (await getTemporaryDirectory()).path;

  // Su un isolate separato: le query non bloccano il thread della UI.
  return NativeDatabase.createInBackground(file);
});

// ── Dalle righe al dominio ──────────────────────────────────────────────────
//
// ⚑ Le righe restano righe (le schermate hanno bisogno di id, note, sortOrder) e il dominio
// si chiede esplicitamente nel punto in cui serve, come in Scorte Calore. ☠ Una chiave
// sconosciuta lancia StateError invece di ripiegare su un default: con i CHECK dello schema
// succede solo con un backup scritto da una versione futura, e un dato sbagliato in silenzio
// e' peggio di un errore visibile.

extension CameraToDomain on Camera {
  FilmFormat get formatEnum =>
      FilmFormat.byKey(format) ?? (throw StateError('Macchina $id: formato "$format"'));

  /// "Olympus OM-2".
  String get displayName => '$manufacturer $model';
}

extension FilmStockToDomain on FilmStock {
  FilmFormat get formatEnum =>
      FilmFormat.byKey(format) ?? (throw StateError('Pellicola $id: formato "$format"'));

  FilmProcess get processEnum =>
      FilmProcess.byKey(process) ?? (throw StateError('Pellicola $id: processo "$process"'));

  /// "Kodak Portra 400": quello che `film_rolls.filmName` copia.
  String get displayName => '$brand $name';
}

extension FilmRollToDomain on FilmRoll {
  RollStatus get statusEnum =>
      RollStatus.byKey(status) ?? (throw StateError('Rullino $id: stato "$status"'));

  FilmFormat get formatEnum =>
      FilmFormat.byKey(format) ?? (throw StateError('Rullino $id: formato "$format"'));

  RollSection get section => const RollStatusMachine().sectionFor(statusEnum);

  CivilDate? get loadedDate => CivilDate.tryParse(loadedAt);

  CivilDate? get finishedDate => CivilDate.tryParse(finishedAt);

  /// Push o pull: ISO di esposizione diverso dal nominale.
  bool get isPushPull => exposedIso != nominalIso;

  DateTime get createdAtUtc => DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true);
}

extension DevelopmentToDomain on Development {
  CivilDate? get submittedDate => CivilDate.tryParse(submittedAt);

  CivilDate? get returnedDate => CivilDate.tryParse(returnedAt);

  /// Null se non indicato; StateError su una chiave sconosciuta.
  FilmProcess? get processEnum => process == null
      ? null
      : FilmProcess.byKey(process) ?? (throw StateError('Sviluppo $id: processo "$process"'));

  LabEvent toLabEvent() =>
      LabEvent(submittedAt: submittedDate, returnedAt: returnedDate, selfDeveloped: selfDeveloped);
}

extension PrintOrderToDomain on PrintOrder {
  CivilDate? get submittedDate => CivilDate.tryParse(submittedAt);

  CivilDate? get returnedDate => CivilDate.tryParse(returnedAt);

  LabEvent toLabEvent() => LabEvent(submittedAt: submittedDate, returnedAt: returnedDate);
}

extension RollImageToDomain on RollImage {
  RollImageKind get kindEnum =>
      RollImageKind.byKey(kind) ?? (throw StateError('Immagine $id: tipo "$kind"'));

  /// Per `ImageStore.delete`, che vuole uno `StoredImage`.
  StoredImage toStoredImage() => StoredImage(
    path: path,
    thumbPath: thumbPath,
    width: width,
    height: height,
    bytes: bytes,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
  );
}

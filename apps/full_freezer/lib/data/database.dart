import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'tables.dart';

export 'tables.dart' show ItemStatus, MovementKind;

part 'database.g.dart';

/// Il database di Full Freezer.
///
/// Le date di calendario sono TEXT `YYYY-MM-DD` (ADR-008); gli istanti sono millisecondi UTC.
/// Le query vivono in `FreezerRepository`, non qui: il database dichiara la forma dei dati,
/// il repository le regole per scriverli (per esempio la coerenza fra `freezerId` e
/// `compartmentId`, che nessun vincolo SQL puo' esprimere).
@DriftDatabase(tables: [Freezers, Compartments, Items, ItemMovements, CustomCategories])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Database su file, nella cartella documenti dell'app.
  factory AppDatabase.open() => AppDatabase(_openConnection());

  /// Database in memoria, per i test. Non tocca il disco.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      // ☠ `PRAGMA foreign_keys` non e' attivo di default in SQLite e va impostato su ogni
      // connessione. Senza, i `references(... onDelete: cascade)` sono decorativi:
      // cancellare un freezer lascerebbe alimenti orfani, contati nel riempimento di un
      // freezer che non esiste piu'. Stessa trappola gia' pagata in TrashCan.
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
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'full_freezer.sqlite'));

  // ☠ Su Android la cartella temporanea di sistema non e' scrivibile dal processo dell'app:
  // senza questa riga VACUUM e alcuni ORDER BY grandi falliscono con "unable to open
  // database file", e solo su dispositivo, mai in test. Vedi apps/trashcan.
  sqlite3.tempDirectory = (await getTemporaryDirectory()).path;

  // Su un isolate separato: le query non bloccano il thread della UI.
  return NativeDatabase.createInBackground(file);
});

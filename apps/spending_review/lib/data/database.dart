import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

/// Il database di Spending Review: `negozi`, `spese`, `righe` (develop_microapps.md F12.1.10).
///
/// Le query e le regole che nessun vincolo SQL puo' esprimere (una spesa si crea pigramente,
/// i totali si scrivono alla chiusura, le spese oltre le 5 si nascondono e non si cancellano)
/// vivono in `SpesaRepository`, non qui. Stesso schema di QR Me e Film Tracker.
@DriftDatabase(tables: [Negozi, Spese, Righe])
class SpendingDatabase extends _$SpendingDatabase {
  SpendingDatabase(super.e);

  /// Database su file, nella cartella documenti dell'app.
  factory SpendingDatabase.open() => SpendingDatabase(_openConnection());

  /// Database in memoria, per i test. Non tocca il disco.
  factory SpendingDatabase.memory() => SpendingDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Alla versione 1 non esistono migrazioni. Il ramo resta scritto perche' la prima modifica di
    // schema dovra' incrementare schemaVersion E aggiungere qui il passo, con il suo test sulla
    // base di drift_schemas/drift_schema_v1.json: senza, il primo aggiornamento in produzione
    // cancella i dati degli utenti (§10).
    onUpgrade: (m, from, to) async {
      throw UnsupportedError(
        'Migrazione da schema $from a $to non implementata. '
        'Aggiungere il passo in SpendingDatabase.migration e il relativo test.',
      );
    },
    // ☠ Le chiavi esterne in SQLite sono SPENTE di default, connessione per connessione: senza
    // questa riga ON DELETE CASCADE (righe di una spesa) e ON DELETE SET NULL (negozio eliminato)
    // non farebbero niente, e resterebbero righe orfane.
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'spending_review.sqlite'));

  // ☠ Su Android la cartella temporanea di sistema non e' scrivibile dal processo dell'app: senza
  // questa riga VACUUM e alcuni ORDER BY grandi falliscono con "unable to open database file", e
  // solo su dispositivo, mai in test. Vedi apps/trashcan.
  sqlite3.tempDirectory = (await getTemporaryDirectory()).path;

  // ⚑ Fuori dai backup automatici (regola «dati solo sul telefono»): su Android con
  // allowBackup="false" nel manifest, su iOS con `isExcludedFromBackup` sulla cartella Documents/
  // intera, a ogni avvio, in ios/Runner/AppDelegate.swift. Se il file cambia nome o cartella, va
  // aggiornato anche li'.

  // Su un isolate separato: le query non bloccano il thread della UI.
  return NativeDatabase.createInBackground(file);
});

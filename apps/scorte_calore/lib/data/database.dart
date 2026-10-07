import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/fuel_source.dart';
import '../domain/fuel_units.dart';
import 'tables.dart';

export 'tables.dart' show enteredAsKeys, fuelTypeKeys, fuelUnitKeys;

part 'database.g.dart';

/// Il database di Scorte Calore.
///
/// Le date di calendario sono TEXT `YYYY-MM-DD` (ADR-008); gli istanti sono millisecondi UTC.
/// Le query vivono in `ScorteRepository`, non qui: il database dichiara la forma dei dati,
/// il repository le regole per scriverli (per esempio che la quantita' di una misura in
/// percentuale sia sempre quella che la capacita' attuale della fonte da' al valore grezzo,
/// che nessun vincolo SQL puo' esprimere).
@DriftDatabase(tables: [FuelSources, StockMeasurements, Purchases, CalendarReminders])
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
      // cancellare una fonte lascerebbe misurazioni e acquisti orfani, che finirebbero nelle
      // statistiche e nel CSV di una fonte che non esiste piu'. Stessa trappola gia' pagata
      // in TrashCan e Full Freezer.
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
  final file = File(p.join(dir.path, 'scorte_calore.sqlite'));

  // ☠ Su Android la cartella temporanea di sistema non e' scrivibile dal processo dell'app:
  // senza questa riga VACUUM e alcuni ORDER BY grandi falliscono con "unable to open
  // database file", e solo su dispositivo, mai in test. Vedi apps/trashcan.
  sqlite3.tempDirectory = (await getTemporaryDirectory()).path;

  // Su un isolate separato: le query non bloccano il thread della UI.
  return NativeDatabase.createInBackground(file);
});

/// Da riga di `fuel_sources` al modello del dominio.
///
/// ⚑ **Perche' le righe restano righe e il dominio si chiede esplicitamente**: le schermate
/// hanno bisogno di `active`, `sortOrder`, `createdAt` e dell'id, che `FuelSourceSpec` non
/// porta; i calcoli hanno bisogno dei tipi forti (`FuelType`, non una stringa). Una
/// conversione per lettura, nel punto in cui si calcola, tiene il dominio libero da Drift
/// senza inventare un terzo modello.
extension FuelSourceToDomain on FuelSource {
  /// ☠ Lancia [StateError] su un combustibile sconosciuto invece di ripiegare su `pellet`:
  /// con i CHECK dello schema succede solo con un backup scritto da una versione futura, e
  /// una stima calcolata sul combustibile sbagliato e' peggio di un errore visibile.
  FuelType get fuelTypeEnum =>
      FuelType.byKey(fuelType) ??
      (throw StateError('Fonte $id: combustibile sconosciuto "$fuelType"'));

  FuelUnit get fuelUnit => FuelUnits.byKey(unit);

  FuelSourceSpec toSpec() => FuelSourceSpec(
    id: id,
    name: name,
    fuelType: fuelTypeEnum,
    unitKey: unit,
    unitWeightKg: unitWeightKg,
    tankCapacity: tankCapacity,
    usableFraction: usableFraction,
    warningDays: warningDays,
    costPerUnitCents: costPerUnitCents,
  );
}

/// Da riga di `stock_measurements` al modello del dominio (senza id e nota).
extension StockMeasurementToDomain on StockMeasurement {
  CivilDate get civilDate => CivilDate.parse(date);

  EnteredAs get enteredAsEnum =>
      EnteredAs.byKey(enteredAs) ??
      (throw StateError('Misurazione $id: enteredAs sconosciuto "$enteredAs"'));

  Measurement toMeasurement() => Measurement(
    date: civilDate,
    quantity: quantity,
    enteredAs: enteredAsEnum,
    rawInput: rawInput,
  );
}

/// Una serie di righe in una serie del dominio, nello stesso ordine: l'ingresso di
/// `ConsumptionCalculator.estimate`.
extension StockMeasurementListToDomain on Iterable<StockMeasurement> {
  List<Measurement> toMeasurements() => map((r) => r.toMeasurement()).toList(growable: false);
}

extension PurchaseToDomain on Purchase {
  CivilDate get civilDate => CivilDate.parse(date);
}

extension CalendarReminderToDomain on CalendarReminder {
  CivilDate get calculatedCivilDate => CivilDate.parse(calculatedDate);
}

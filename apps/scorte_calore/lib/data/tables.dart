// I vincoli `check(...)` di Drift citano la colonna dentro il suo stesso getter: e' la forma
// documentata da Drift, che legge la definizione senza mai eseguirla. Il lint la scambia per
// una ricorsione infinita.
// ignore_for_file: recursive_getters
import 'package:drift/drift.dart';

import '../domain/fuel_source.dart';
import '../domain/fuel_units.dart';

/// Le tabelle di Scorte Calore (develop_microapps.md F5.2).
///
/// Convenzioni comuni a tutto il monorepo (ADR-008): le **date di calendario** sono TEXT
/// `YYYY-MM-DD` (`date`, `calculatedDate`), perche' "misurato il 3 marzo" non ha fuso orario;
/// gli **istanti** veri (`createdAt`, `lastSyncedAt`) sono millisecondi UTC.
///
/// ⚑ **Le chiavi ammesse nei CHECK vengono dal dominio** (`FuelType.key`, `FuelUnits.all`,
/// `EnteredAs.key`), non da una lista copiata qui: una chiave aggiunta al dominio e
/// dimenticata qui sarebbe rifiutata dal database solo in produzione. ☠ Il CHECK pero' entra
/// nello schema al momento della creazione della tabella: aggiungere una chiave dopo il
/// rilascio richiede una migrazione che ricrei la tabella (SQLite non modifica i CHECK).

/// Le chiavi di `fuel_sources.fuelType`.
final List<String> fuelTypeKeys = [for (final t in FuelType.values) t.key];

/// Le chiavi di `fuel_sources.unit`.
final List<String> fuelUnitKeys = [for (final u in FuelUnits.all) u.key];

/// Le chiavi di `stock_measurements.enteredAs`.
final List<String> enteredAsKeys = [for (final e in EnteredAs.values) e.key];

/// Una fonte di calore: "Stufa soggiorno" (pellet), "Bombolone giardino" (GPL).
///
/// Si mappa su `FuelSourceSpec` con `FuelSourceToDomain.toSpec()` (in `database.dart`): restano
/// fuori `active`, `sortOrder` e `createdAt`, che ai calcoli non servono.
class FuelSources extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Il nome dato dall'utente. E' un dato, non un testo dell'app.
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// `FuelType.key`: `pellet` | `lpg` | `diesel` | `wood` | `biomass`.
  TextColumn get fuelType => text().check(fuelType.isIn(fuelTypeKeys))();

  /// Chiave in `FuelUnits`. ⚑ Il CHECK accetta tutte le unita' del catalogo; che l'unita' sia
  /// ammessa **per quel combustibile** (niente "litri di pellet") lo controlla
  /// `ScorteRepository` con `FuelUnits.isAllowed`: un CHECK che incrocia due colonne con
  /// una mappa del dominio sarebbe illeggibile e andrebbe migrato a ogni unita' nuova.
  TextColumn get unit => text().check(unit.isIn(fuelUnitKeys))();

  /// Peso in kg di un sacco/cesta. Opzionale, solo informativo (F5.4).
  RealColumn get unitWeightKg => real().nullable().check(unitWeightKg.isBiggerThanValue(0))();

  /// Capacita' **nominale** del serbatoio, in litri, per `lpg`/`diesel`. Il CHECK lascia
  /// passare NULL (in SQL `NULL > 0` e' sconosciuto, e un CHECK sconosciuto passa).
  RealColumn get tankCapacity => real().nullable().check(tankCapacity.isBiggerThanValue(0))();

  /// Frazione della capacita' nominale davvero utilizzabile, in (0, 1].
  ///
  /// ☠ Il GPL non si riempie mai oltre l'80%: il manometro va moltiplicato per la capacita'
  /// **utile**, non per la nominale (F5.2). Nessun default SQL: il default dipende dal
  /// combustibile (`FuelType.defaultUsableFraction`) e lo mette il repository. Zero e'
  /// escluso: una fonte con capacita' utile nulla trasformerebbe ogni percentuale in 0.
  RealColumn get usableFraction => real().check(
    usableFraction.isBiggerThanValue(0) & usableFraction.isSmallerOrEqualValue(1),
  )();

  /// Giorni di anticipo del riordino rispetto all'esaurimento stimato.
  IntColumn get warningDays => integer()
      .withDefault(const Constant(FuelType.defaultWarningDays))
      .check(warningDays.isBiggerOrEqualValue(0))();

  IntColumn get costPerUnitCents =>
      integer().nullable().check(costPerUnitCents.isBiggerOrEqualValue(0))();

  /// Una fonte disattivata (stufa dismessa) sparisce da dashboard, notifiche e widget ma
  /// conserva lo storico. Cancellarla invece porta via tutto (cascade).
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// Ordine nella dashboard (trascinamento). Non e' nella tabella di F5.2: ⚑ aggiunto per
  /// coerenza con Full Freezer, dove l'ordine dei freezer e' dell'utente e non dell'id.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();
}

/// Una misurazione della scorta. Si mappa su `Measurement` con `toMeasurement()`.
///
/// ☠ **Una misurazione al giorno**: `UNIQUE(fuelSourceId, date)`. Due misure nella stessa
/// data darebbero un intervallo di zero giorni e una divisione per zero nel calcolatore;
/// la seconda sovrascrive la prima (`ScorteRepository.upsertMeasurement`).
class StockMeasurements extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get fuelSourceId =>
      integer().references(FuelSources, #id, onDelete: KeyAction.cascade)();

  /// `YYYY-MM-DD` (ADR-008). Il formato a larghezza fissa fa coincidere l'ordine del testo
  /// con quello cronologico: `ORDER BY date` e `date >= ?` funzionano senza conversioni.
  TextColumn get date => text().withLength(min: 10, max: 10)();

  /// Nell'unita' della fonte, gia' convertita. Zero e' ammesso: la stufa a secco esiste.
  RealColumn get quantity => real().check(quantity.isBiggerOrEqualValue(0))();

  /// `absolute` | `percentage`: cosa ha digitato l'utente.
  TextColumn get enteredAs => text().check(enteredAs.isIn(enteredAsKeys))();

  /// Il valore digitato, prima della conversione.
  ///
  /// ⚑ **Perche' si conserva** (F5.2): se l'utente cambia capacita' o frazione utile dopo
  /// dieci misure in percentuale, le quantita' si ricalcolano da qui
  /// (`ScorteRepository.recomputeMeasurements`). Una lettura di manometro sopra il 100% non
  /// esiste: il CHECK la rifiuta solo per `percentage`.
  RealColumn get rawInput => real().check(
    rawInput.isBiggerOrEqualValue(0) &
        (enteredAs.equals(EnteredAs.absolute.key) | rawInput.isSmallerOrEqualValue(100)),
  )();

  TextColumn get note => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {fuelSourceId, date},
  ];
}

/// Un acquisto di combustibile (F5.11): costo medio per unita' e spesa stagionale.
///
/// ⚑ Un acquisto **non** crea una misurazione: "ho comprato 70 sacchi" non dice quanti ce
/// ne sono adesso (magari ne restavano 5). La scorta la dice solo una misurazione.
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get fuelSourceId =>
      integer().references(FuelSources, #id, onDelete: KeyAction.cascade)();

  /// `YYYY-MM-DD` (ADR-008).
  TextColumn get date => text().withLength(min: 10, max: 10)();

  /// Nell'unita' della fonte. ⚑ Strettamente positiva, a differenza della scorta: un
  /// acquisto di zero non e' un acquisto, e falserebbe il costo medio per unita'.
  RealColumn get quantity => real().check(quantity.isBiggerThanValue(0))();

  /// ⚑ Nullable, anche se F5.2 non lo dice: la legna regalata dal vicino o lo scontrino
  /// perso non devono impedire di registrare l'acquisto. Il costo medio conta solo gli
  /// acquisti con un costo.
  IntColumn get totalCostCents =>
      integer().nullable().check(totalCostCents.isBiggerOrEqualValue(0))();

  TextColumn get supplier => text().nullable()();

  TextColumn get note => text().nullable()();
}

/// L'evento di riordino messo nel calendario del telefono (F5.10, Pro). Uno per fonte.
///
/// ☠ Cancellare la fonte cancella questa riga (cascade), **non** l'evento nel calendario:
/// quello sta fuori dal database. Chi elimina una fonte deve prima chiedere a
/// `CalendarSyncService.deleteEvent` di toglierlo, leggendo qui calendario ed evento.
class CalendarReminders extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get fuelSourceId =>
      integer().unique().references(FuelSources, #id, onDelete: KeyAction.cascade)();

  /// Il calendario che contiene l'evento. ⚑ Non e' nella tabella di F5.2, ma
  /// `CalendarSyncService.deleteEvent(calendarId, eventId)` e `upsertReorderEvent` lo
  /// chiedono: senza, un evento creato non si potrebbe piu' aggiornare ne' cancellare.
  TextColumn get calendarId => text().withLength(min: 1, max: 255)();

  /// L'id dell'evento restituito da `device_calendar_plus`.
  TextColumn get externalEventId => text().withLength(min: 1, max: 255)();

  /// La `reorderDate` con cui l'evento e' stato scritto, `YYYY-MM-DD`. Serve a capire se la
  /// stima e' cambiata di piu' di 3 giorni e va **proposto** l'aggiornamento (F5.10).
  TextColumn get calculatedDate => text().withLength(min: 10, max: 10)();

  IntColumn get createdAt => integer()();

  IntColumn get lastSyncedAt => integer()();
}

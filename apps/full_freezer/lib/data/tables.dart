// I vincoli `check(...)` di Drift citano la colonna dentro il suo stesso getter: e' la forma
// documentata da Drift, che legge la definizione senza mai eseguirla. Il lint la scambia per
// una ricorsione infinita.
// ignore_for_file: recursive_getters
import 'package:drift/drift.dart';

/// Le tabelle di Full Freezer (develop_microapps.md F4.2).
///
/// Convenzioni comuni a tutto il monorepo (ADR-008): le **date di calendario** sono TEXT
/// `YYYY-MM-DD` (`frozenAt`), perche' "congelato il 3 marzo" non ha fuso orario; gli
/// **istanti** veri (`createdAt`, `removedAt`, `at`) sono millisecondi UTC.

/// Un freezer: "Freezer cucina", "Pozzetto in garage".
///
/// ⚑ La capacita' e' salvata in litri, non solo come modello: se un giorno si corregge il
/// valore tipico di un modello in `FreezerModels`, i freezer gia' creati non devono cambiare
/// riempimento sotto gli occhi dell'utente. `modelKey` resta per mostrare il disegno e per
/// proporre di nuovo lo stesso modello.
class Freezers extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// Chiave in `FreezerModels` (F4.3b), oppure `custom` se i litri li ha scritti l'utente.
  TextColumn get modelKey => text().withLength(min: 1, max: 32)();

  /// Litri **nominali** del vano congelatore. La capienza utile la calcola
  /// `CapacityEstimator` (80%).
  RealColumn get capacityLiters => real().check(capacityLiters.isBiggerThanValue(0))();

  /// Taratura da "quanto e' pieno davvero?" (F4.3b). 1.0 = la stima cosi' com'e'.
  RealColumn get calibration => real().withDefault(const Constant(1.0))();

  /// L'ultimo avviso di capienza mandato: `full`, `empty` o null (F4.9, isteresi).
  ///
  /// ⚑ Parte da `empty` e non da null: un freezer appena creato e' vuoto, e non deve mai
  /// ricevere un "quasi vuoto" (develop_microapps.md F4.9).
  TextColumn get lastAlertLevel => text().nullable().withDefault(const Constant('empty'))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();
}

/// Uno scomparto dentro un freezer: "Cassetto 2", "Ripiano in alto".
class Compartments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get freezerId => integer().references(Freezers, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Un alimento nel freezer. Il cuore dell'app.
@TableIndex(name: 'idx_items_status_frozen', columns: {#status, #frozenAt})
@TableIndex(name: 'idx_items_freezer', columns: {#freezerId})
@TableIndex(name: 'idx_items_name_norm', columns: {#nameNorm})
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// ⚑ **Ridondante rispetto a `compartmentId`, e voluto** (F4.2): un alimento puo' stare in
  /// un freezer senza scomparti. Ricavarlo con una join costringerebbe a uno scomparto
  /// fittizio "Nessuno". La coerenza la garantisce `FreezerRepository`, che quando c'e' uno
  /// scomparto ne copia il freezer.
  IntColumn get freezerId => integer().references(Freezers, #id, onDelete: KeyAction.cascade)();

  /// Cancellare uno scomparto non cancella gli alimenti: restano nel freezer, senza scomparto.
  IntColumn get compartmentId =>
      integer().nullable().references(Compartments, #id, onDelete: KeyAction.setNull)();

  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// `name` normalizzato da `normalizeName` (minuscolo, senza accenti): la ricerca e
  /// l'autocompletamento lavorano su questa colonna (F4.8).
  TextColumn get nameNorm => text()();

  /// Chiave in `ItemCategories`, o di una categoria personalizzata (`custom:<id>`).
  TextColumn get category => text().nullable()();

  RealColumn get quantity => real().check(quantity.isBiggerThanValue(0))();

  /// Chiave in `Units`.
  TextColumn get unit => text().withLength(min: 1, max: 16)();

  /// Data di congelamento, `YYYY-MM-DD` (ADR-008).
  TextColumn get frozenAt => text().withLength(min: 10, max: 10)();

  /// Promemoria personalizzato in giorni; null = quello della categoria.
  IntColumn get reminderAfterDays => integer().nullable()();

  /// Ingombro **dell'intera riga** (quantita' compresa), in litri (F4.3b).
  RealColumn get volumeLiters => real().check(volumeLiters.isBiggerThanValue(0))();

  /// True se l'utente ha corretto l'ingombro: da li' la stima non lo tocca piu'.
  BoolColumn get volumeManual => boolean().withDefault(const Constant(false))();

  /// Percorso **relativo** della foto (F1.11): i percorsi assoluti cambiano fra un
  /// ripristino e l'altro, e su iOS a ogni aggiornamento dell'app.
  TextColumn get photoPath => text().nullable()();

  TextColumn get note => text().nullable()();

  /// `stored` | `consumed` | `discarded`. Gli alimenti usciti **non si cancellano**: servono
  /// allo storico e alle statistiche Pro (F4.7).
  TextColumn get status => text()
      .withDefault(const Constant(ItemStatus.stored))
      .check(status.isIn(const [ItemStatus.stored, ItemStatus.consumed, ItemStatus.discarded]))();

  /// Istante dell'uscita, ms UTC. Null finche' l'alimento e' nel freezer.
  IntColumn get removedAt => integer().nullable()();

  IntColumn get createdAt => integer()();
}

/// I valori di `items.status`.
abstract final class ItemStatus {
  static const String stored = 'stored';
  static const String consumed = 'consumed';
  static const String discarded = 'discarded';
}

/// Lo storico dei movimenti di un alimento (F4.7, letto dalle statistiche Pro).
class ItemMovements extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get itemId => integer().references(Items, #id, onDelete: KeyAction.cascade)();

  /// `stored` | `consumed` | `discarded` | `moved` | `restored` (uscita annullata).
  TextColumn get kind => text().withLength(min: 1, max: 16)();

  IntColumn get at => integer()();

  IntColumn get fromCompartmentId => integer().nullable()();

  IntColumn get toCompartmentId => integer().nullable()();
}

/// I valori di `item_movements.kind`.
abstract final class MovementKind {
  static const String stored = 'stored';
  static const String consumed = 'consumed';
  static const String discarded = 'discarded';
  static const String moved = 'moved';
  static const String restored = 'restored';
}

/// Categorie definite dall'utente (Pro, `FeatureKey.customCategories`).
class CustomCategories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  TextColumn get iconKey => text().withLength(min: 1, max: 32)();

  IntColumn get colorValue => integer()();

  IntColumn get defaultReminderDays => integer().nullable()();
}

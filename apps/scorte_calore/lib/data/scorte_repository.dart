import 'package:drift/drift.dart';
import 'package:micro_core/micro_core.dart';

import '../domain/fuel_source.dart';
import '../domain/fuel_units.dart';
import '../domain/quantity_converter.dart';
import 'database.dart';

/// Tutte le scritture e le letture dei dati di Scorte Calore.
///
/// ⚑ **Perche' un repository e non query sparse nelle pagine**: alcune regole non si
/// possono scrivere come vincoli SQL e vanno rispettate a ogni scrittura, quindi devono
/// passare da una porta sola:
/// 1. l'unita' di una fonte e' ammessa per il suo combustibile (`FuelUnits.isAllowed`);
/// 2. la quantita' di una misura in percentuale e' sempre `fromPercentage(rawInput)` con la
///    configurazione **attuale** della fonte: alla scrittura e ogni volta che capacita',
///    frazione utile o unita' cambiano (`recomputeMeasurements`);
/// 3. una misura al giorno per fonte: la seconda sovrascrive la prima (`upsertMeasurement`).
/// Dimenticarne una in una pagina non darebbe nessun errore: darebbe una stima sbagliata di
/// un quarto, che l'utente scopre restando senza GPL.
///
/// ⚑ **Righe in uscita, dominio in entrata dove il dominio basta.** Le letture restituiscono
/// le righe Drift (`FuelSource`, `StockMeasurement`, `Purchase`, `CalendarReminder`): le
/// schermate hanno bisogno di id, nota, `active`, `sortOrder`, che i modelli del dominio non
/// portano di proposito. I calcoli convertono nel punto in cui servono con `toSpec()` e
/// `toMeasurements()` (`database.dart`). Le scritture accettano il dominio quando il dominio
/// descrive tutta la scrittura (`updateSource(FuelSourceSpec)`, `upsertMeasurement(...,
/// Measurement)`), parametri con nome quando l'oggetto non esiste ancora e non ha un id
/// (`addSource`, `addPurchase`).
///
/// I limiti del piano gratuito (una fonte, 90 giorni di storico) **non** stanno qui: li
/// applica la UI con `FeatureGate`. I dati non sanno del Pro.
class ScorteRepository {
  ScorteRepository(this._db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  int _nowMs() => _clock().toUtc().millisecondsSinceEpoch;

  // ── Fonti ─────────────────────────────────────────────────────────────────

  /// Le fonti nell'ordine dell'utente. Con [activeOnly] solo quelle attive (dashboard,
  /// notifiche, widget); senza, anche le disattivate (impostazioni, storico).
  Stream<List<FuelSource>> watchSources({bool activeOnly = false}) =>
      _sourcesQuery(activeOnly).watch();

  Future<List<FuelSource>> allSources({bool activeOnly = false}) =>
      _sourcesQuery(activeOnly).get();

  SimpleSelectStatement<$FuelSourcesTable, FuelSource> _sourcesQuery(bool activeOnly) {
    final q = _db.select(_db.fuelSources);
    if (activeOnly) q.where((t) => t.active.equals(true));
    return q
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.id),
      ]);
  }

  Future<FuelSource?> sourceById(int id) =>
      (_db.select(_db.fuelSources)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<FuelSource?> watchSource(int id) =>
      (_db.select(_db.fuelSources)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Crea una fonte in fondo all'elenco, con i default del suo combustibile per quello che
  /// non viene passato: unita' `fuelType.defaultUnitKey`, frazione utile
  /// `fuelType.defaultUsableFraction` (0,80 per il GPL), anticipo 7 giorni.
  ///
  /// Lancia [ArgumentError] se [unitKey] non e' ammessa per [fuelType]. La scorta iniziale
  /// del wizard (F5.5) e' una misurazione: la UI chiama [upsertMeasurement] subito dopo.
  Future<int> addSource({
    required String name,
    required FuelType fuelType,
    String? unitKey,
    double? unitWeightKg,
    double? tankCapacity,
    double? usableFraction,
    int warningDays = FuelType.defaultWarningDays,
    int? costPerUnitCents,
  }) async {
    final unit = unitKey ?? fuelType.defaultUnitKey;
    _requireUnitAllowed(fuelType, unit);
    final count = await _db.fuelSources.count().getSingle();
    return _db
        .into(_db.fuelSources)
        .insert(
          FuelSourcesCompanion.insert(
            name: name.trim(),
            fuelType: fuelType.key,
            unit: unit,
            unitWeightKg: Value(unitWeightKg),
            tankCapacity: Value(tankCapacity),
            usableFraction: usableFraction ?? fuelType.defaultUsableFraction,
            warningDays: Value(warningDays),
            costPerUnitCents: Value(costPerUnitCents),
            sortOrder: Value(count),
            createdAt: _nowMs(),
          ),
        );
  }

  /// Riscrive la configurazione della fonte `spec.id` con **tutti** i campi di [spec]
  /// (un campo null in [spec] diventa null nel database: e' cosi' che si toglie una
  /// capacita' o un costo). `active`, `sortOrder` e `createdAt` non si toccano.
  ///
  /// Se cambiano capacita', frazione utile o unita', ricalcola le misure in percentuale
  /// nella stessa transazione ([recomputeMeasurements]): non esiste un istante in cui la
  /// fonte ha la capacita' nuova e le misure quella vecchia.
  ///
  /// Lancia [ArgumentError] se l'unita' non e' ammessa per il combustibile, [StateError] se
  /// la fonte non esiste.
  Future<void> updateSource(FuelSourceSpec spec) => _db.transaction(() async {
    _requireUnitAllowed(spec.fuelType, spec.unitKey);
    final before = await sourceById(spec.id);
    if (before == null) throw StateError('Fonte ${spec.id} inesistente');
    await (_db.update(_db.fuelSources)..where((t) => t.id.equals(spec.id))).write(
      FuelSourcesCompanion(
        name: Value(spec.name.trim()),
        fuelType: Value(spec.fuelType.key),
        unit: Value(spec.unitKey),
        unitWeightKg: Value(spec.unitWeightKg),
        tankCapacity: Value(spec.tankCapacity),
        usableFraction: Value(spec.usableFraction),
        warningDays: Value(spec.warningDays),
        costPerUnitCents: Value(spec.costPerUnitCents),
      ),
    );
    if (before.tankCapacity != spec.tankCapacity ||
        before.usableFraction != spec.usableFraction ||
        before.unit != spec.unitKey) {
      await recomputeMeasurements(spec.id);
    }
  });

  /// Attiva o disattiva una fonte. Una fonte disattivata conserva misure e acquisti.
  Future<void> setSourceActive(int id, bool active) =>
      (_db.update(_db.fuelSources)..where((t) => t.id.equals(id))).write(
        FuelSourcesCompanion(active: Value(active)),
      );

  /// Cancella una fonte **con misure, acquisti e promemoria** (cascade). La UI chiede
  /// conferma. ☠ L'evento nel calendario del telefono non e' nel database: va tolto prima
  /// con `CalendarSyncService.deleteEvent`, leggendo [reminderFor].
  Future<void> deleteSource(int id) =>
      (_db.delete(_db.fuelSources)..where((t) => t.id.equals(id))).go();

  /// Riscrive l'ordine delle fonti secondo la lista di id ricevuta (trascinamento).
  Future<void> reorderSources(List<int> idsInOrder) => _db.transaction(() async {
    for (var i = 0; i < idsInOrder.length; i++) {
      await (_db.update(_db.fuelSources)..where((t) => t.id.equals(idsInOrder[i]))).write(
        FuelSourcesCompanion(sortOrder: Value(i)),
      );
    }
  });

  // ── Misurazioni ───────────────────────────────────────────────────────────

  /// Le misure di una fonte, **dalla piu' vecchia** (l'ordine del calcolatore e dei grafici).
  /// Con [since] solo quelle da quella data compresa in poi.
  Stream<List<StockMeasurement>> watchMeasurements(int sourceId, {CivilDate? since}) =>
      _measurementsQuery(sourceId, since).watch();

  Future<List<StockMeasurement>> allMeasurements(int sourceId) =>
      _measurementsQuery(sourceId, null).get();

  /// Le misure da [since] compresa in poi, dalla piu' vecchia.
  ///
  /// ⚑ Serve al limite di 90 giorni del piano gratuito (`FeatureKey.fullHistory`): il
  /// repository offre la query, **quale** data passare lo decide la UI con `FeatureGate`.
  Future<List<StockMeasurement>> measurementsSince(int sourceId, CivilDate since) =>
      _measurementsQuery(sourceId, since).get();

  SimpleSelectStatement<$StockMeasurementsTable, StockMeasurement> _measurementsQuery(
    int sourceId,
    CivilDate? since,
  ) => _db.select(_db.stockMeasurements)
    ..where((t) {
      final mine = t.fuelSourceId.equals(sourceId);
      // Il confronto fra testi YYYY-MM-DD coincide con quello fra date (ADR-008).
      return since == null ? mine : mine & t.date.isBiggerOrEqualValue(since.toIso());
    })
    ..orderBy([(t) => OrderingTerm(expression: t.date)]);

  /// L'ultima misura della fonte, o null: il valore con cui la bottom sheet di
  /// aggiornamento preimposta il campo (F5.7).
  Future<StockMeasurement?> latestMeasurement(int sourceId) =>
      (_db.select(_db.stockMeasurements)
            ..where((t) => t.fuelSourceId.equals(sourceId))
            ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
            ..limit(1))
          .getSingleOrNull();

  /// Salva la misura [m] della fonte [sourceId]; se in quella data ce n'e' gia' una, la
  /// **sostituisce** (nota compresa: una [note] null cancella la vecchia). Restituisce l'id
  /// della riga, che resta lo stesso in caso di sostituzione.
  ///
  /// ⚑ La quantita' la normalizza il repository, non chi chiama:
  /// - `absolute`: `rawInput` diventa la quantita' (e' quella digitata);
  /// - `percentage`: la quantita' diventa `QuantityConverter(fonte).fromPercentage(rawInput)`
  ///   con la configurazione attuale. Cosi' la regola 2 della classe vale dalla prima
  ///   scrittura, anche se la UI ha arrotondato la conversione mostrata.
  ///
  /// Lancia [StateError] se la fonte non esiste, [ArgumentError] se la misura e' in
  /// percentuale e la fonte non ha una capacita' utile (la UI non deve offrire lo switch).
  Future<int> upsertMeasurement(int sourceId, Measurement m, {String? note}) =>
      _db.transaction(() async {
        final source = await sourceById(sourceId);
        if (source == null) throw StateError('Fonte $sourceId inesistente');
        final Measurement normalized;
        if (m.enteredAs == EnteredAs.percentage) {
          final converter = QuantityConverter(source.toSpec());
          if (!converter.supportsPercentage) {
            throw ArgumentError.value(m, 'm', 'La fonte $sourceId non ha una capacita\' utile');
          }
          normalized = m.withQuantity(converter.fromPercentage(m.rawInput));
        } else {
          normalized = Measurement.absolute(date: m.date, quantity: m.quantity);
        }
        final companion = StockMeasurementsCompanion.insert(
          fuelSourceId: sourceId,
          date: normalized.date.toIso(),
          quantity: normalized.quantity,
          enteredAs: normalized.enteredAs.key,
          rawInput: normalized.rawInput,
          note: Value(_blankToNull(note)),
        );
        final row = await _db
            .into(_db.stockMeasurements)
            .insertReturning(
              companion,
              onConflict: DoUpdate(
                (_) => companion,
                target: [_db.stockMeasurements.fuelSourceId, _db.stockMeasurements.date],
              ),
            );
        return row.id;
      });

  Future<void> deleteMeasurement(int id) =>
      (_db.delete(_db.stockMeasurements)..where((t) => t.id.equals(id))).go();

  /// Riapplica `QuantityConverter.recompute` a tutte le misure della fonte con la sua
  /// configurazione **attuale**: le misure in percentuale si ricalcolano dal valore grezzo,
  /// quelle assolute restano come sono. Restituisce quante righe sono cambiate.
  ///
  /// La chiama [updateSource] quando cambiano capacita', frazione utile o unita'; e'
  /// pubblica per il ripristino di un backup scritto con una configurazione diversa.
  ///
  /// ☠ Se la fonte ha perso la capacita', le misure in percentuale restano **invariate**
  /// (vedi `QuantityConverter.recompute`): un campo lasciato vuoto un momento non deve
  /// azzerare mesi di dati. Torneranno giuste quando la capacita' verra' rimessa.
  Future<int> recomputeMeasurements(int sourceId) => _db.transaction(() async {
    final source = await sourceById(sourceId);
    if (source == null) return 0;
    final converter = QuantityConverter(source.toSpec());
    final rows = await (_db.select(_db.stockMeasurements)
          ..where(
            (t) =>
                t.fuelSourceId.equals(sourceId) &
                t.enteredAs.equals(EnteredAs.percentage.key),
          ))
        .get();
    var changed = 0;
    for (final r in rows) {
      final q = converter.recompute(r.toMeasurement()).quantity;
      if (q == r.quantity) continue;
      await (_db.update(_db.stockMeasurements)..where((t) => t.id.equals(r.id))).write(
        StockMeasurementsCompanion(quantity: Value(q)),
      );
      changed++;
    }
    return changed;
  });

  // ── Acquisti ──────────────────────────────────────────────────────────────

  /// Gli acquisti, **i piu' recenti per primi**; con [sourceId] null, di tutte le fonti.
  Stream<List<Purchase>> watchPurchases({int? sourceId}) => _purchasesQuery(sourceId).watch();

  Future<List<Purchase>> allPurchases({int? sourceId}) => _purchasesQuery(sourceId).get();

  SimpleSelectStatement<$PurchasesTable, Purchase> _purchasesQuery(int? sourceId) {
    final q = _db.select(_db.purchases);
    if (sourceId != null) q.where((t) => t.fuelSourceId.equals(sourceId));
    return q
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ]);
  }

  Future<Purchase?> purchaseById(int id) =>
      (_db.select(_db.purchases)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Registra un acquisto. Non crea una misurazione (vedi `Purchases` in `tables.dart`).
  Future<int> addPurchase({
    required int sourceId,
    required CivilDate date,
    required double quantity,
    int? totalCostCents,
    String? supplier,
    String? note,
  }) => _db
      .into(_db.purchases)
      .insert(
        PurchasesCompanion.insert(
          fuelSourceId: sourceId,
          date: date.toIso(),
          quantity: quantity,
          totalCostCents: Value(totalCostCents),
          supplier: Value(_blankToNull(supplier)),
          note: Value(_blankToNull(note)),
        ),
      );

  /// Salva le modifiche a un acquisto esistente (la riga intera, come `copyWith` la lascia).
  Future<void> updatePurchase(Purchase purchase) => _db
      .update(_db.purchases)
      .replace(
        purchase.copyWith(
          supplier: Value(_blankToNull(purchase.supplier)),
          note: Value(_blankToNull(purchase.note)),
        ),
      );

  Future<void> deletePurchase(int id) =>
      (_db.delete(_db.purchases)..where((t) => t.id.equals(id))).go();

  // ── Promemoria nel calendario (Pro, F5.10) ────────────────────────────────

  Future<CalendarReminder?> reminderFor(int sourceId) =>
      (_db.select(_db.calendarReminders)..where((t) => t.fuelSourceId.equals(sourceId)))
          .getSingleOrNull();

  Stream<List<CalendarReminder>> watchReminders() => _db.select(_db.calendarReminders).watch();

  /// Ricorda l'evento di riordino della fonte: uno per fonte, il secondo sostituisce il
  /// primo. `createdAt` resta quello della prima scrittura, `lastSyncedAt` diventa adesso.
  Future<void> upsertReminder({
    required int sourceId,
    required String calendarId,
    required String externalEventId,
    required CivilDate calculatedDate,
  }) => _db.transaction(() async {
    final now = _nowMs();
    final existing = await reminderFor(sourceId);
    if (existing == null) {
      await _db
          .into(_db.calendarReminders)
          .insert(
            CalendarRemindersCompanion.insert(
              fuelSourceId: sourceId,
              calendarId: calendarId,
              externalEventId: externalEventId,
              calculatedDate: calculatedDate.toIso(),
              createdAt: now,
              lastSyncedAt: now,
            ),
          );
    } else {
      await (_db.update(_db.calendarReminders)..where((t) => t.id.equals(existing.id))).write(
        CalendarRemindersCompanion(
          calendarId: Value(calendarId),
          externalEventId: Value(externalEventId),
          calculatedDate: Value(calculatedDate.toIso()),
          lastSyncedAt: Value(now),
        ),
      );
    }
  });

  /// Dimentica l'evento della fonte (dopo averlo tolto dal calendario).
  Future<void> deleteReminder(int sourceId) =>
      (_db.delete(_db.calendarReminders)..where((t) => t.fuelSourceId.equals(sourceId))).go();

  // ── Segnale di modifica ───────────────────────────────────────────────────

  /// Un segnale a ogni modifica di fonti, misure, acquisti o promemoria: lo usano lo
  /// scheduler delle notifiche (F5.8) e il widget, cosi' nessuno deve ricordarsi di
  /// chiamarli.
  Stream<void> watchAnyChange() => _db.tableUpdates(
    TableUpdateQuery.onAllTables([
      _db.fuelSources,
      _db.stockMeasurements,
      _db.purchases,
      _db.calendarReminders,
    ]),
  );

  // ── Regole interne ────────────────────────────────────────────────────────

  static void _requireUnitAllowed(FuelType type, String unitKey) {
    if (!FuelUnits.isAllowed(type, unitKey)) {
      throw ArgumentError.value(unitKey, 'unitKey', 'Unita\' non ammessa per ${type.key}');
    }
  }

  /// Una nota o un fornitore fatti di soli spazi sono "niente", non una stringa vuota da
  /// mostrare nel CSV.
  static String? _blankToNull(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}

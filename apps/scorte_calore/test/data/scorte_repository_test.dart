import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:scorte_calore/data/database.dart';
import 'package:scorte_calore/data/scorte_repository.dart';
import 'package:scorte_calore/domain/consumption.dart';
import 'package:scorte_calore/domain/fuel_source.dart';
import 'package:scorte_calore/domain/fuel_units.dart';
// I vincoli CHECK violati arrivano come eccezione di sqlite3, non di drift.
import 'package:sqlite3/sqlite3.dart' show SqliteException;

/// F5.2: i vincoli dello schema e le regole che il repository fa rispettare a ogni scrittura.
void main() {
  late AppDatabase db;
  late ScorteRepository repo;
  var now = DateTime.utc(2026, 10, 7, 12);

  setUp(() {
    db = AppDatabase.memory();
    now = DateTime.utc(2026, 10, 7, 12);
    repo = ScorteRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  CivilDate d(String iso) => CivilDate.parse(iso);

  Future<int> gpl({double capacity = 1000}) =>
      repo.addSource(name: 'Bombolone', fuelType: FuelType.lpg, tankCapacity: capacity);

  Future<int> pellet([String name = 'Stufa soggiorno']) =>
      repo.addSource(name: name, fuelType: FuelType.pellet);

  Measurement perc(String iso, double percent) => Measurement(
    date: d(iso),
    quantity: 0, // la calcola il repository
    enteredAs: EnteredAs.percentage,
    rawInput: percent,
  );

  /// Una scrittura SQL diretta, per provare i CHECK senza passare dalle regole del repository.
  Future<int> rawSource({
    String fuelType = 'pellet',
    String unit = 'bags',
    double usableFraction = 1,
    double? tankCapacity,
    double? unitWeightKg,
  }) => db
      .into(db.fuelSources)
      .insert(
        FuelSourcesCompanion.insert(
          name: 'X',
          fuelType: fuelType,
          unit: unit,
          usableFraction: usableFraction,
          tankCapacity: Value(tankCapacity),
          unitWeightKg: Value(unitWeightKg),
          createdAt: 0,
        ),
      );

  group('fonti', () {
    test('una fonte nuova prende i default del suo combustibile', () async {
      final g = (await repo.sourceById(await gpl()))!;
      // ☠ F5.2: il GPL si riempie all'80%, la frazione utile parte da 0,80.
      expect(g.usableFraction, 0.8);
      expect(g.unit, FuelUnits.liters);
      expect(g.warningDays, 7);
      expect(g.active, isTrue);
      expect(g.createdAt, now.millisecondsSinceEpoch);
      final p = (await repo.sourceById(await pellet()))!;
      expect(p.usableFraction, 1.0);
      expect(p.unit, FuelUnits.bags);
      expect(p.tankCapacity, isNull);
    });

    test('la riga si converte nel FuelSourceSpec del dominio', () async {
      final id = await repo.addSource(
        name: ' Caldaia ',
        fuelType: FuelType.diesel,
        unitKey: FuelUnits.percent,
        tankCapacity: 1500,
        warningDays: 10,
        costPerUnitCents: 165,
      );
      final spec = (await repo.sourceById(id))!.toSpec();
      expect(
        spec,
        FuelSourceSpec(
          id: id,
          name: 'Caldaia',
          fuelType: FuelType.diesel,
          unitKey: FuelUnits.percent,
          tankCapacity: 1500,
          usableFraction: 1.0,
          warningDays: 10,
          costPerUnitCents: 165,
        ),
      );
    });

    test('un\'unita\' non ammessa per il combustibile e\' rifiutata dal repository', () async {
      expect(
        () => repo.addSource(name: 'X', fuelType: FuelType.pellet, unitKey: FuelUnits.liters),
        throwsArgumentError,
      );
      final id = await pellet();
      final spec = (await repo.sourceById(id))!.toSpec();
      expect(() => repo.updateSource(spec.copyWith(unitKey: FuelUnits.steres)), throwsArgumentError);
    });

    test('le fonti si accodano, si riordinano e si filtrano per attive', () async {
      final a = await pellet('A');
      final b = await pellet('B');
      final c = await pellet('C');
      expect((await repo.allSources()).map((s) => s.name), ['A', 'B', 'C']);
      await repo.reorderSources([c, a, b]);
      expect((await repo.allSources()).map((s) => s.name), ['C', 'A', 'B']);
      await repo.setSourceActive(a, false);
      expect((await repo.allSources(activeOnly: true)).map((s) => s.name), ['C', 'B']);
      expect((await repo.allSources()).length, 3);
    });

    test('updateSource riscrive tutti i campi, anche togliendo un valore', () async {
      final id = await repo.addSource(
        name: 'Stufa',
        fuelType: FuelType.pellet,
        unitWeightKg: 15,
        costPerUnitCents: 590,
      );
      // copyWith non sa mettere null: si costruisce lo spec intero, come fara' la UI.
      final s = (await repo.sourceById(id))!.toSpec();
      await repo.updateSource(
        FuelSourceSpec(
          id: id,
          name: 'Stufa cucina',
          fuelType: s.fuelType,
          unitKey: s.unitKey,
          usableFraction: s.usableFraction,
          warningDays: 5,
        ),
      );
      final after = (await repo.sourceById(id))!;
      expect(after.name, 'Stufa cucina');
      expect(after.unitWeightKg, isNull);
      expect(after.costPerUnitCents, isNull);
      expect(after.warningDays, 5);
      expect(after.active, isTrue);
    });

    test('aggiornare una fonte inesistente e\' un errore', () {
      final ghost = FuelSourceSpec.withDefaults(id: 99, name: 'X', fuelType: FuelType.pellet);
      expect(() => repo.updateSource(ghost), throwsStateError);
    });
  });

  group('vincoli dello schema', () {
    test('capacita\' zero o negativa rifiutata, NULL ammessa', () async {
      expect(() => rawSource(tankCapacity: 0), throwsA(isA<SqliteException>()));
      expect(() => rawSource(tankCapacity: -5), throwsA(isA<SqliteException>()));
      expect(await rawSource(), isPositive);
    });

    test('frazione utile in (0, 1]', () async {
      expect(() => rawSource(usableFraction: 0), throwsA(isA<SqliteException>()));
      expect(() => rawSource(usableFraction: 1.2), throwsA(isA<SqliteException>()));
      expect(await rawSource(usableFraction: 1), isPositive);
    });

    test('peso unitario positivo se presente', () {
      expect(() => rawSource(unitWeightKg: 0), throwsA(isA<SqliteException>()));
    });

    test('combustibile e unita\' devono essere chiavi note', () {
      expect(() => rawSource(fuelType: 'carbone'), throwsA(isA<SqliteException>()));
      expect(() => rawSource(unit: 'tonnellate'), throwsA(isA<SqliteException>()));
    });

    test('le liste dei CHECK vengono dal dominio', () {
      expect(fuelTypeKeys, ['pellet', 'lpg', 'diesel', 'wood', 'biomass']);
      expect(fuelUnitKeys, containsAll(<String>['bags', 'liters', 'percent', 'steres']));
      expect(enteredAsKeys, ['absolute', 'percentage']);
    });

    test('misura: quantita\' negativa, enteredAs ignoto e percentuale > 100 rifiutati', () async {
      final id = await pellet();
      Future<int> raw(double q, String entered, double rawInput) => db
          .into(db.stockMeasurements)
          .insert(
            StockMeasurementsCompanion.insert(
              fuelSourceId: id,
              date: '2026-10-01',
              quantity: q,
              enteredAs: entered,
              rawInput: rawInput,
            ),
          );
      expect(() => raw(-1, 'absolute', -1), throwsA(isA<SqliteException>()));
      expect(() => raw(5, 'stima', 5), throwsA(isA<SqliteException>()));
      expect(() => raw(5, 'percentage', 120), throwsA(isA<SqliteException>()));
      // Un assoluto sopra 100 e' normale: 430 litri.
      expect(await raw(430, 'absolute', 430), isPositive);
    });

    test('acquisto: quantita\' zero e costo negativo rifiutati', () async {
      final id = await pellet();
      expect(
        () => repo.addPurchase(sourceId: id, date: d('2026-10-01'), quantity: 0),
        throwsA(isA<SqliteException>()),
      );
      expect(
        () => repo.addPurchase(
          sourceId: id,
          date: d('2026-10-01'),
          quantity: 10,
          totalCostCents: -1,
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('le foreign key sono attive: cancellare una fonte porta via tutto', () async {
      // Senza PRAGMA foreign_keys resterebbero misure e acquisti orfani nel CSV.
      final id = await gpl();
      await repo.upsertMeasurement(id, perc('2026-10-01', 50));
      await repo.addPurchase(sourceId: id, date: d('2026-10-01'), quantity: 400);
      await repo.upsertReminder(
        sourceId: id,
        calendarId: 'cal',
        externalEventId: 'ev',
        calculatedDate: d('2026-11-01'),
      );
      await repo.deleteSource(id);
      expect(await db.select(db.stockMeasurements).get(), isEmpty);
      expect(await db.select(db.purchases).get(), isEmpty);
      expect(await db.select(db.calendarReminders).get(), isEmpty);
    });

    test('una misura per una fonte inesistente e\' rifiutata', () {
      expect(
        () => repo.upsertMeasurement(42, Measurement.absolute(date: d('2026-10-01'), quantity: 3)),
        throwsStateError,
      );
    });
  });

  group('misurazioni', () {
    test('una misura al giorno: la seconda sovrascrive la prima, stesso id', () async {
      final id = await pellet();
      final first = await repo.upsertMeasurement(
        id,
        Measurement.absolute(date: d('2026-10-01'), quantity: 20),
        note: 'mattina',
      );
      final second = await repo.upsertMeasurement(
        id,
        Measurement.absolute(date: d('2026-10-01'), quantity: 18),
      );
      expect(second, first);
      final rows = await repo.allMeasurements(id);
      expect(rows, hasLength(1));
      expect(rows.single.quantity, 18);
      // La nota vecchia non sopravvive: la misura e' sostituita per intero.
      expect(rows.single.note, isNull);
    });

    test('lo stesso giorno su due fonti diverse non e\' un conflitto', () async {
      final a = await pellet('A');
      final b = await pellet('B');
      final m = Measurement.absolute(date: d('2026-10-01'), quantity: 5);
      await repo.upsertMeasurement(a, m);
      await repo.upsertMeasurement(b, m);
      expect(await db.select(db.stockMeasurements).get(), hasLength(2));
    });

    test('il vincolo UNIQUE regge anche senza il repository', () async {
      final id = await pellet();
      StockMeasurementsCompanion row() => StockMeasurementsCompanion.insert(
        fuelSourceId: id,
        date: '2026-10-01',
        quantity: 1,
        enteredAs: 'absolute',
        rawInput: 1,
      );
      await db.into(db.stockMeasurements).insert(row());
      expect(() => db.into(db.stockMeasurements).insert(row()), throwsA(isA<SqliteException>()));
    });

    test('in ordine di data, qualunque sia l\'ordine di inserimento', () async {
      final id = await pellet();
      for (final iso in ['2026-10-05', '2026-09-20', '2026-10-01']) {
        await repo.upsertMeasurement(id, Measurement.absolute(date: d(iso), quantity: 1));
      }
      expect((await repo.allMeasurements(id)).map((m) => m.date), [
        '2026-09-20',
        '2026-10-01',
        '2026-10-05',
      ]);
      expect((await repo.latestMeasurement(id))!.date, '2026-10-05');
    });

    test('measurementsSince include la data limite e solo quella fonte', () async {
      final id = await pellet('A');
      final other = await pellet('B');
      for (final iso in ['2026-06-01', '2026-07-09', '2026-08-15']) {
        await repo.upsertMeasurement(id, Measurement.absolute(date: d(iso), quantity: 1));
      }
      await repo.upsertMeasurement(other, Measurement.absolute(date: d('2026-08-01'), quantity: 1));
      final since = d('2026-10-07').addDays(-90); // 2026-07-09
      expect((await repo.measurementsSince(id, since)).map((m) => m.date), [
        '2026-07-09',
        '2026-08-15',
      ]);
      expect((await repo.watchMeasurements(id, since: since).first).length, 2);
    });

    test('la percentuale la converte il repository: 43% di 1000 L utili 0,8 = 344 L', () async {
      final id = await gpl();
      await repo.upsertMeasurement(id, perc('2026-10-01', 43));
      final row = (await repo.allMeasurements(id)).single;
      expect(row.quantity, closeTo(344, 1e-9));
      expect(row.enteredAs, EnteredAs.percentage.key);
      expect(row.rawInput, 43);
    });

    test('un assoluto salva il valore grezzo uguale alla quantita\'', () async {
      final id = await pellet();
      await repo.upsertMeasurement(
        id,
        // Un chiamante distratto passa un rawInput incoerente: il repository lo allinea.
        Measurement(date: d('2026-10-01'), quantity: 12, enteredAs: EnteredAs.absolute, rawInput: 99),
      );
      expect((await repo.allMeasurements(id)).single.rawInput, 12);
    });

    test('una percentuale su una fonte senza capacita\' e\' un errore', () async {
      final id = await pellet();
      expect(() => repo.upsertMeasurement(id, perc('2026-10-01', 50)), throwsArgumentError);
      expect(await repo.allMeasurements(id), isEmpty);
    });

    test('deleteMeasurement toglie solo quella riga', () async {
      final id = await pellet();
      final a = await repo.upsertMeasurement(id, Measurement.absolute(date: d('2026-10-01'), quantity: 9));
      await repo.upsertMeasurement(id, Measurement.absolute(date: d('2026-10-02'), quantity: 8));
      await repo.deleteMeasurement(a);
      expect((await repo.allMeasurements(id)).map((m) => m.date), ['2026-10-02']);
    });

    test('le righe arrivano al calcolatore come Measurement del dominio', () async {
      final id = await pellet();
      for (final (iso, q) in [('2026-09-01', 30.0), ('2026-09-11', 20.0), ('2026-09-21', 10.0)]) {
        await repo.upsertMeasurement(id, Measurement.absolute(date: d(iso), quantity: q));
      }
      final source = (await repo.sourceById(id))!.toSpec();
      final series = (await repo.allMeasurements(id)).toMeasurements();
      expect(series.first, Measurement.absolute(date: d('2026-09-01'), quantity: 30));
      final e = const ConsumptionCalculator().estimate(
        measurements: series,
        source: source,
        today: d('2026-09-21'),
      );
      expect(e.dailyRate, 1.0);
      expect(e.quality, EstimateQuality.good);
    });
  });

  group('ricalcolo dopo un cambio di configurazione', () {
    test('cambiare la capacita\' ricalcola le percentuali, non gli assoluti', () async {
      final id = await gpl(capacity: 1000);
      await repo.upsertMeasurement(id, perc('2026-10-01', 50)); // 400 L
      await repo.upsertMeasurement(id, Measurement.absolute(date: d('2026-10-05'), quantity: 350));
      final spec = (await repo.sourceById(id))!.toSpec();
      await repo.updateSource(spec.copyWith(tankCapacity: 2000));
      final rows = await repo.allMeasurements(id);
      expect(rows[0].quantity, closeTo(800, 1e-9)); // 50% di 2000 x 0,8
      expect(rows[0].rawInput, 50);
      expect(rows[1].quantity, 350);
    });

    test('cambiare la frazione utile ricalcola', () async {
      final id = await gpl(capacity: 1000);
      await repo.upsertMeasurement(id, perc('2026-10-01', 50));
      final spec = (await repo.sourceById(id))!.toSpec();
      await repo.updateSource(spec.copyWith(usableFraction: 0.85));
      expect((await repo.allMeasurements(id)).single.quantity, closeTo(425, 1e-9));
    });

    test('rinominare la fonte non riscrive le misure', () async {
      final id = await gpl();
      await repo.upsertMeasurement(id, perc('2026-10-01', 50));
      final spec = (await repo.sourceById(id))!.toSpec();
      await repo.updateSource(spec.copyWith(name: 'Bombolone nuovo'));
      // Le misure sono gia' coerenti con la configurazione: un ricalcolo non cambia niente.
      expect(await repo.recomputeMeasurements(id), 0);
      expect((await repo.allMeasurements(id)).single.quantity, closeTo(400, 1e-9));
    });

    test('togliere la capacita\' lascia le misure com\'erano', () async {
      final id = await gpl();
      await repo.upsertMeasurement(id, perc('2026-10-01', 50));
      final s = (await repo.sourceById(id))!.toSpec();
      await repo.updateSource(
        FuelSourceSpec(
          id: id,
          name: s.name,
          fuelType: s.fuelType,
          unitKey: s.unitKey,
          usableFraction: s.usableFraction,
        ),
      );
      expect((await repo.sourceById(id))!.tankCapacity, isNull);
      expect((await repo.allMeasurements(id)).single.quantity, closeTo(400, 1e-9));
    });

    test('passare all\'unita\' percentuale riporta le percentuali al valore grezzo', () async {
      final id = await gpl();
      await repo.upsertMeasurement(id, perc('2026-10-01', 43));
      final spec = (await repo.sourceById(id))!.toSpec();
      await repo.updateSource(spec.copyWith(unitKey: FuelUnits.percent));
      expect((await repo.allMeasurements(id)).single.quantity, 43);
    });

    test('recomputeMeasurements su una fonte inesistente non fa niente', () async {
      expect(await repo.recomputeMeasurements(404), 0);
    });
  });

  group('acquisti', () {
    test('si creano, si modificano, si cancellano, i piu\' recenti per primi', () async {
      final a = await pellet('A');
      final b = await pellet('B');
      final p1 = await repo.addPurchase(
        sourceId: a,
        date: d('2026-09-01'),
        quantity: 70,
        totalCostCents: 41300,
        supplier: '  Agraria Rossi ',
      );
      await repo.addPurchase(sourceId: a, date: d('2026-10-01'), quantity: 30, supplier: '   ');
      await repo.addPurchase(sourceId: b, date: d('2026-09-15'), quantity: 10);

      final ofA = await repo.allPurchases(sourceId: a);
      expect(ofA.map((p) => p.date), ['2026-10-01', '2026-09-01']);
      expect(ofA.first.supplier, isNull); // solo spazi = niente
      expect(ofA.first.totalCostCents, isNull); // costo sconosciuto ammesso
      expect(ofA.last.supplier, 'Agraria Rossi');
      expect((await repo.allPurchases()).length, 3);

      final row = (await repo.purchaseById(p1))!;
      await repo.updatePurchase(row.copyWith(quantity: 72, note: const Value('consegna')));
      final updated = (await repo.purchaseById(p1))!;
      expect(updated.quantity, 72);
      expect(updated.note, 'consegna');
      expect(updated.civilDate, d('2026-09-01'));

      await repo.deletePurchase(p1);
      expect(await repo.purchaseById(p1), isNull);
      expect((await repo.watchPurchases(sourceId: a).first).length, 1);
    });

    test('un acquisto non crea una misurazione', () async {
      final id = await pellet();
      await repo.addPurchase(sourceId: id, date: d('2026-10-01'), quantity: 70);
      expect(await repo.allMeasurements(id), isEmpty);
    });
  });

  group('promemoria nel calendario', () {
    test('uno per fonte: il secondo aggiorna, createdAt resta', () async {
      final id = await pellet();
      await repo.upsertReminder(
        sourceId: id,
        calendarId: 'c1',
        externalEventId: 'e1',
        calculatedDate: d('2026-11-01'),
      );
      final created = now.millisecondsSinceEpoch;
      now = DateTime.utc(2026, 10, 9, 8);
      await repo.upsertReminder(
        sourceId: id,
        calendarId: 'c1',
        externalEventId: 'e2',
        calculatedDate: d('2026-11-05'),
      );
      final r = (await repo.reminderFor(id))!;
      expect(r.externalEventId, 'e2');
      expect(r.calculatedCivilDate, d('2026-11-05'));
      expect(r.createdAt, created);
      expect(r.lastSyncedAt, now.millisecondsSinceEpoch);
      expect((await repo.watchReminders().first).length, 1);

      await repo.deleteReminder(id);
      expect(await repo.reminderFor(id), isNull);
    });

    test('UNIQUE(fuelSourceId) regge anche senza il repository', () async {
      final id = await pellet();
      CalendarRemindersCompanion row() => CalendarRemindersCompanion.insert(
        fuelSourceId: id,
        calendarId: 'c',
        externalEventId: 'e',
        calculatedDate: '2026-11-01',
        createdAt: 0,
        lastSyncedAt: 0,
      );
      await db.into(db.calendarReminders).insert(row());
      expect(() => db.into(db.calendarReminders).insert(row()), throwsA(isA<SqliteException>()));
    });
  });

  group('watch', () {
    test('watchMeasurements emette di nuovo dopo un upsert', () async {
      final id = await pellet();
      final emissions = <int>[];
      final sub = repo.watchMeasurements(id).listen((l) => emissions.add(l.length));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.upsertMeasurement(id, Measurement.absolute(date: d('2026-10-01'), quantity: 4));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, [0, 1]);
      await sub.cancel();
    });

    test('watchSources(activeOnly) segue attivazione e ordine', () async {
      final a = await pellet('A');
      await pellet('B');
      final seen = <List<String>>[];
      final sub = repo.watchSources(activeOnly: true).listen((l) => seen.add([for (final s in l) s.name]));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.setSourceActive(a, false);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(seen.first, ['A', 'B']);
      expect(seen.last, ['B']);
      await sub.cancel();
    });

    test('watchAnyChange avvisa per fonti, misure, acquisti e promemoria', () async {
      final id = await pellet();
      var signals = 0;
      final sub = repo.watchAnyChange().listen((_) => signals++);
      Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

      await repo.upsertMeasurement(id, Measurement.absolute(date: d('2026-10-01'), quantity: 4));
      await settle();
      final afterMeasure = signals;
      expect(afterMeasure, greaterThan(0));

      await repo.addPurchase(sourceId: id, date: d('2026-10-01'), quantity: 10);
      await settle();
      final afterPurchase = signals;
      expect(afterPurchase, greaterThan(afterMeasure));

      await repo.upsertReminder(
        sourceId: id,
        calendarId: 'c',
        externalEventId: 'e',
        calculatedDate: d('2026-11-01'),
      );
      await settle();
      expect(signals, greaterThan(afterPurchase));
      await sub.cancel();
    });
  });
}

import 'package:drift/drift.dart';
import 'package:micro_core/micro_core.dart';

import '../domain/recurrence.dart';
import 'database.dart';

/// Le scritture sul database, in un posto solo.
///
/// ⚑ Perché un repository e non i DAO generati da Drift usati direttamente dalle pagine:
/// quasi ogni scrittura qui tocca più tabelle e deve restare coerente. Creare un tipo di
/// rifiuto senza la sua regola produce una voce che non genera mai una raccolta, e
/// l'utente la vede come "l'app non funziona". Tenendo le operazioni composte in un posto
/// solo, la transazione è garantita e la sequenza è leggibile.
class TrashcanRepository {
  const TrashcanRepository(this.db);

  final AppDatabase db;

  // ── Calendari ────────────────────────────────────────────────────────────────────

  Future<int> createCalendar({
    required String name,
    String notificationTime = '20:00',
  }) async {
    final maxOrder = await _maxCalendarOrder();
    return db.into(db.collectionCalendars).insert(
      CollectionCalendarsCompanion.insert(
        name: name,
        notificationTime: Value(notificationTime),
        sortOrder: Value(maxOrder + 1),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> renameCalendar(int id, String name) =>
      (db.update(db.collectionCalendars)..where((c) => c.id.equals(id)))
          .write(CollectionCalendarsCompanion(name: Value(name)));

  Future<void> setCalendarNotification(
    int id, {
    required String time,
    String? secondTime,
    bool? enabled,
  }) =>
      (db.update(db.collectionCalendars)..where((c) => c.id.equals(id))).write(
        CollectionCalendarsCompanion(
          notificationTime: Value(time),
          secondNotificationTime: Value(secondTime),
          enabled: enabled == null ? const Value.absent() : Value(enabled),
        ),
      );

  /// Cancella il calendario. Tipi, regole ed eccezioni seguono per cascata.
  Future<void> deleteCalendar(int id) =>
      (db.delete(db.collectionCalendars)..where((c) => c.id.equals(id))).go();

  Future<int> _maxCalendarOrder() async {
    final row = await (db.selectOnly(db.collectionCalendars)
          ..addColumns([db.collectionCalendars.sortOrder.max()]))
        .getSingle();
    return row.read(db.collectionCalendars.sortOrder.max()) ?? 0;
  }

  // ── Tipi di rifiuto ──────────────────────────────────────────────────────────────

  Future<int> createWasteType({
    required int calendarId,
    required String name,
    required String iconKey,
    required int colorValue,
    int? sortOrder,
  }) async {
    final order = sortOrder ?? (await _maxWasteTypeOrder(calendarId)) + 1;
    return db.into(db.wasteTypes).insert(
      WasteTypesCompanion.insert(
        calendarId: calendarId,
        name: name,
        iconKey: iconKey,
        colorValue: colorValue,
        sortOrder: Value(order),
      ),
    );
  }

  Future<void> updateWasteType(
    int id, {
    String? name,
    String? iconKey,
    int? colorValue,
    bool? notificationsEnabled,
  }) =>
      (db.update(db.wasteTypes)..where((t) => t.id.equals(id))).write(
        WasteTypesCompanion(
          name: name == null ? const Value.absent() : Value(name),
          iconKey: iconKey == null ? const Value.absent() : Value(iconKey),
          colorValue: colorValue == null ? const Value.absent() : Value(colorValue),
          notificationsEnabled:
              notificationsEnabled == null ? const Value.absent() : Value(notificationsEnabled),
        ),
      );

  Future<void> deleteWasteType(int id) =>
      (db.delete(db.wasteTypes)..where((t) => t.id.equals(id))).go();

  /// Riordina i tipi secondo la sequenza data. Una sola transazione.
  Future<void> reorderWasteTypes(List<int> orderedIds) => db.transaction(() async {
    for (var i = 0; i < orderedIds.length; i++) {
      await (db.update(db.wasteTypes)..where((t) => t.id.equals(orderedIds[i])))
          .write(WasteTypesCompanion(sortOrder: Value(i)));
    }
  });

  Future<int> _maxWasteTypeOrder(int calendarId) async {
    final row = await (db.selectOnly(db.wasteTypes)
          ..addColumns([db.wasteTypes.sortOrder.max()])
          ..where(db.wasteTypes.calendarId.equals(calendarId)))
        .getSingle();
    return row.read(db.wasteTypes.sortOrder.max()) ?? -1;
  }

  // ── Regole ───────────────────────────────────────────────────────────────────────

  /// Sostituisce **tutte** le regole di un tipo con quella data.
  ///
  /// ⚑ Sostituisce invece di aggiungere perché è quello che l'utente si aspetta quando
  /// modifica i giorni di raccolta di un tipo: nell'interfaccia c'è un solo insieme di
  /// giorni, non una collezione di regole sovrapposte. Le regole multiple restano
  /// possibili nel modello, ma non è l'editor a crearle.
  Future<void> setWeeklyRule({
    required int wasteTypeId,
    required Set<int> weekdays,
    CivilDate? startDate,
    CivilDate? endDate,
  }) => _replaceRule(
    wasteTypeId,
    RecurrenceRulesCompanion.insert(
      wasteTypeId: wasteTypeId,
      kind: 'weekly',
      weekdaysMask: Value(WeekdayMask.fromSet(weekdays)),
      startDate: (startDate ?? CivilDate.today()).toIso(),
      endDate: Value(endDate?.toIso()),
    ),
  );

  Future<void> setEveryNWeeksRule({
    required int wasteTypeId,
    required Set<int> weekdays,
    required int intervalWeeks,
    required CivilDate anchorDate,
    CivilDate? startDate,
    CivilDate? endDate,
  }) => _replaceRule(
    wasteTypeId,
    RecurrenceRulesCompanion.insert(
      wasteTypeId: wasteTypeId,
      kind: 'everyNWeeks',
      weekdaysMask: Value(WeekdayMask.fromSet(weekdays)),
      intervalWeeks: Value(intervalWeeks),
      anchorDate: Value(anchorDate.toIso()),
      startDate: (startDate ?? CivilDate.today()).toIso(),
      endDate: Value(endDate?.toIso()),
    ),
  );

  Future<void> setMonthlyDayRule({
    required int wasteTypeId,
    required int dayOfMonth,
    CivilDate? startDate,
    CivilDate? endDate,
  }) => _replaceRule(
    wasteTypeId,
    RecurrenceRulesCompanion.insert(
      wasteTypeId: wasteTypeId,
      kind: 'monthlyDay',
      dayOfMonth: Value(dayOfMonth),
      startDate: (startDate ?? CivilDate.today()).toIso(),
      endDate: Value(endDate?.toIso()),
    ),
  );

  Future<void> setMonthlyNthWeekdayRule({
    required int wasteTypeId,
    required int nth,
    required int weekday,
    CivilDate? startDate,
    CivilDate? endDate,
  }) => _replaceRule(
    wasteTypeId,
    RecurrenceRulesCompanion.insert(
      wasteTypeId: wasteTypeId,
      kind: 'monthlyNthWeekday',
      nthOfMonth: Value(nth),
      weekday: Value(weekday),
      startDate: (startDate ?? CivilDate.today()).toIso(),
      endDate: Value(endDate?.toIso()),
    ),
  );

  Future<void> setManualDatesRule({
    required int wasteTypeId,
    required List<CivilDate> dates,
    CivilDate? startDate,
    CivilDate? endDate,
  }) => _replaceRule(
    wasteTypeId,
    RecurrenceRulesCompanion.insert(
      wasteTypeId: wasteTypeId,
      kind: 'manual',
      manualDatesCsv: Value(dates.map((d) => d.toIso()).join(',')),
      startDate: (startDate ?? CivilDate.today()).toIso(),
      endDate: Value(endDate?.toIso()),
    ),
  );

  /// Sostituisce tutte le regole di un tipo con la ricorrenza data, di qualunque forma.
  ///
  /// I cinque metodi tipizzati qui sopra restano perche' descrivono l'intenzione al
  /// chiamante ("imposta una regola settimanale") e perche' i test li usano. Questo invece
  /// serve all'editor delle regole, che lavora su un [Recurrence] gia' costruito e non sa
  /// quale forma abbia: senza, l'editor dovrebbe fare uno switch per richiamare il metodo
  /// giusto, cioe' duplicare lo switch che sta gia' in [RecurrenceToRow].
  Future<void> setRule({required int wasteTypeId, required Recurrence recurrence}) =>
      _replaceRule(wasteTypeId, recurrence.toCompanion(wasteTypeId));

  Future<void> clearRules(int wasteTypeId) =>
      (db.delete(db.recurrenceRules)..where((r) => r.wasteTypeId.equals(wasteTypeId))).go();

  Future<void> _replaceRule(int wasteTypeId, RecurrenceRulesCompanion rule) =>
      db.transaction(() async {
        await clearRules(wasteTypeId);
        await db.into(db.recurrenceRules).insert(rule);
      });

  Future<Recurrence?> ruleOf(int wasteTypeId) async {
    final row = await (db.select(db.recurrenceRules)
          ..where((r) => r.wasteTypeId.equals(wasteTypeId))
          ..limit(1))
        .getSingleOrNull();
    return row?.toDomain();
  }

  // ── Eccezioni ────────────────────────────────────────────────────────────────────

  Future<int> skipCollection({required int wasteTypeId, required CivilDate date, String? note}) =>
      db.into(db.collectionExceptions).insert(
        CollectionExceptionsCompanion.insert(
          wasteTypeId: wasteTypeId,
          originalDate: Value(date.toIso()),
          skipped: const Value(true),
          note: Value(note),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  Future<int> moveCollection({
    required int wasteTypeId,
    required CivilDate from,
    required CivilDate to,
    String? note,
  }) => db.into(db.collectionExceptions).insert(
    CollectionExceptionsCompanion.insert(
      wasteTypeId: wasteTypeId,
      originalDate: Value(from.toIso()),
      replacementDate: Value(to.toIso()),
      note: Value(note),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
  );

  Future<int> addExtraCollection({
    required int wasteTypeId,
    required CivilDate date,
    String? note,
  }) => db.into(db.collectionExceptions).insert(
    CollectionExceptionsCompanion.insert(
      wasteTypeId: wasteTypeId,
      replacementDate: Value(date.toIso()),
      note: Value(note),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
  );

  Future<void> removeException(int id) =>
      (db.delete(db.collectionExceptions)..where((e) => e.id.equals(id))).go();

  Stream<List<ExceptionRow>> watchExceptions(int calendarId) {
    final query = db.select(db.collectionExceptions).join([
      innerJoin(db.wasteTypes, db.wasteTypes.id.equalsExp(db.collectionExceptions.wasteTypeId)),
    ])..where(db.wasteTypes.calendarId.equals(calendarId));
    return query.watch().map(
      (rows) => rows.map((r) => r.readTable(db.collectionExceptions)).toList(),
    );
  }

  // ── Operazioni composte ──────────────────────────────────────────────────────────

  /// Crea un calendario completo dal wizard iniziale, in una transazione sola.
  ///
  /// ⚑ Una transazione e non una sequenza di scritture: se l'app venisse chiusa a metà
  /// del wizard, l'utente si ritroverebbe un calendario con tre tipi su cinque e nessun
  /// modo di capire cosa manca. O tutto o niente.
  Future<int> createCalendarFromWizard({
    required String name,
    required String notificationTime,
    required List<WizardWasteType> types,
  }) => db.transaction(() async {
    final calendarId = await createCalendar(name: name, notificationTime: notificationTime);
    for (var i = 0; i < types.length; i++) {
      final type = types[i];
      final typeId = await createWasteType(
        calendarId: calendarId,
        name: type.name,
        iconKey: type.iconKey,
        colorValue: type.colorValue,
        sortOrder: i,
      );
      if (type.weekdays.isNotEmpty) {
        await setWeeklyRule(wasteTypeId: typeId, weekdays: type.weekdays);
      }
    }
    return calendarId;
  });
}

/// Un tipo di rifiuto scelto nel wizard, con i suoi giorni.
class WizardWasteType {
  const WizardWasteType({
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.weekdays,
  });

  final String name;
  final String iconKey;
  final int colorValue;
  final Set<int> weekdays;

  WizardWasteType copyWith({Set<int>? weekdays, String? name}) => WizardWasteType(
    name: name ?? this.name,
    iconKey: iconKey,
    colorValue: colorValue,
    weekdays: weekdays ?? this.weekdays,
  );
}

/// Traduzione dominio -> riga per le regole: l'inverso di `RecurrenceRuleMapper.toDomain`.
///
/// Le due direzioni vivono in file diversi perche' la lettura deve tollerare righe storte
/// (import, versioni future) e restituire `null`, mentre la scrittura parte da un oggetto
/// gia' valido per costruzione e non puo' fallire. Se si tocca una delle due, si controlla
/// l'altra: sono l'unico punto in cui la tabella "larga" delle regole viene interpretata.
extension RecurrenceToRow on Recurrence {
  RecurrenceRulesCompanion toCompanion(int wasteTypeId) => switch (this) {
    WeeklyRecurrence(:final weekdays) => RecurrenceRulesCompanion.insert(
      wasteTypeId: wasteTypeId,
      kind: 'weekly',
      weekdaysMask: Value(WeekdayMask.fromSet(weekdays)),
      startDate: startDate.toIso(),
      endDate: Value(endDate?.toIso()),
    ),
    EveryNWeeksRecurrence(:final weekdays, :final intervalWeeks, :final anchor) =>
      RecurrenceRulesCompanion.insert(
        wasteTypeId: wasteTypeId,
        kind: 'everyNWeeks',
        weekdaysMask: Value(WeekdayMask.fromSet(weekdays)),
        intervalWeeks: Value(intervalWeeks),
        anchorDate: Value(anchor.toIso()),
        startDate: startDate.toIso(),
        endDate: Value(endDate?.toIso()),
      ),
    MonthlyDayRecurrence(:final dayOfMonth) => RecurrenceRulesCompanion.insert(
      wasteTypeId: wasteTypeId,
      kind: 'monthlyDay',
      dayOfMonth: Value(dayOfMonth),
      startDate: startDate.toIso(),
      endDate: Value(endDate?.toIso()),
    ),
    MonthlyNthWeekdayRecurrence(:final nth, :final weekday) => RecurrenceRulesCompanion.insert(
      wasteTypeId: wasteTypeId,
      kind: 'monthlyNthWeekday',
      nthOfMonth: Value(nth),
      weekday: Value(weekday),
      startDate: startDate.toIso(),
      endDate: Value(endDate?.toIso()),
    ),
    ManualDatesRecurrence(:final dates) => RecurrenceRulesCompanion.insert(
      wasteTypeId: wasteTypeId,
      kind: 'manual',
      manualDatesCsv: Value((dates.toList()..sort()).map((d) => d.toIso()).join(',')),
      startDate: startDate.toIso(),
      endDate: Value(endDate?.toIso()),
    ),
  };
}

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/occurrence_engine.dart';
import '../domain/recurrence.dart';
import 'tables.dart';

part 'database.g.dart';

/// Il database di TrashCan.
///
/// Tutte le date di calendario sono TEXT `YYYY-MM-DD` (ADR-008); solo `createdAt` è un
/// istante vero, in millisecondi UTC.
@DriftDatabase(
  tables: [CollectionCalendars, WasteTypes, RecurrenceRules, CollectionExceptions],
)
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
      // ☠ `PRAGMA foreign_keys` non è attivo di default in SQLite e va impostato su
      // ogni connessione. Senza, i `references(... onDelete: cascade)` delle tabelle
      // sono decorativi: cancellare un calendario lascerebbe tipi, regole ed eccezioni
      // orfani, e la home mostrerebbe raccolte di calendari che non esistono più.
      await customStatement('PRAGMA foreign_keys = ON');
    },
    // Alla versione 1 non esistono ancora migrazioni: non c'è nessuna versione
    // precedente da cui salire. Il ramo resta scritto perché la prima modifica di schema
    // dovrà incrementare schemaVersion E aggiungere qui il passo corrispondente, con il
    // test che lo verifica (F3.2.6). Senza, il primo aggiornamento in produzione
    // cancella i dati degli utenti.
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
  final file = File(p.join(dir.path, 'trashcan.sqlite'));

  // ☠ Su Android la cartella temporanea di sistema non è scrivibile dal processo
  // dell'app: senza questa riga, le operazioni che SQLite esegue su file temporanei
  // (VACUUM, alcuni ORDER BY su tabelle grandi) falliscono con "unable to open database
  // file", e solo su dispositivo, mai in test.
  sqlite3.tempDirectory = (await getTemporaryDirectory()).path;

  // `createInBackground` apre il database su un isolate separato: le query non bloccano
  // il thread della UI. Costa una copia dei dati per messaggio, irrilevante per le
  // dimensioni in gioco qui.
  return NativeDatabase.createInBackground(file);
});

/// Un calendario con tutto ciò che serve per disegnarlo e per calcolare le raccolte.
class CalendarBundle {
  const CalendarBundle({
    required this.calendar,
    required this.wasteTypes,
    required this.rules,
  });

  final CollectionCalendar calendar;
  final List<WasteType> wasteTypes;

  /// Le regole già tradotte in oggetti di dominio, con le loro eccezioni.
  final List<RuleWithExceptions> rules;

  WasteType? typeOf(int id) {
    for (final t in wasteTypes) {
      if (t.id == id) return t;
    }
    return null;
  }
}

extension AppDatabaseQueries on AppDatabase {
  /// Tutti i calendari, ordinati.
  Stream<List<CollectionCalendar>> watchCalendars() =>
      (select(collectionCalendars)..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.id),
          ]))
          .watch();

  Future<int> countCalendars() async {
    final row = await (selectOnly(collectionCalendars)
          ..addColumns([collectionCalendars.id.count()]))
        .getSingle();
    return row.read(collectionCalendars.id.count()) ?? 0;
  }

  Stream<List<WasteType>> watchWasteTypes(int calendarId) =>
      (select(wasteTypes)
            ..where((t) => t.calendarId.equals(calendarId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.sortOrder),
              (t) => OrderingTerm(expression: t.id),
            ]))
          .watch();

  /// Il pacchetto completo di un calendario, ricalcolato a ogni modifica dei dati.
  ///
  /// ⚑ È l'unico punto in cui le righe del database diventano oggetti di dominio. Le
  /// pagine non vedono mai una `RecurrenceRule` grezza: vedono una `Recurrence` già
  /// tipizzata, e non possono sbagliare a interpretare le colonne nullable.
  Stream<CalendarBundle?> watchBundle(int calendarId) {
    final calendarStream =
        (select(collectionCalendars)..where((t) => t.id.equals(calendarId))).watchSingleOrNull();

    return calendarStream.asyncMap((calendar) async {
      if (calendar == null) return null;
      final types = await (select(wasteTypes)
            ..where((t) => t.calendarId.equals(calendarId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.sortOrder),
              (t) => OrderingTerm(expression: t.id),
            ]))
          .get();
      return CalendarBundle(
        calendar: calendar,
        wasteTypes: types,
        rules: await _rulesFor(types),
      );
    });
  }

  /// Come [watchBundle] ma una tantum.
  Future<CalendarBundle?> loadBundle(int calendarId) async {
    final calendar = await (select(
      collectionCalendars,
    )..where((t) => t.id.equals(calendarId))).getSingleOrNull();
    if (calendar == null) return null;
    final types = await (select(wasteTypes)
          ..where((t) => t.calendarId.equals(calendarId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .get();
    return CalendarBundle(calendar: calendar, wasteTypes: types, rules: await _rulesFor(types));
  }

  Future<List<RuleWithExceptions>> _rulesFor(List<WasteType> types) async {
    if (types.isEmpty) return const <RuleWithExceptions>[];
    final ids = types.map((t) => t.id).toList();

    final ruleRows = await (select(recurrenceRules)..where((r) => r.wasteTypeId.isIn(ids))).get();
    final exceptionRows = await (select(
      collectionExceptions,
    )..where((e) => e.wasteTypeId.isIn(ids))).get();

    final exceptionsByType = <int, List<CollectionException>>{};
    for (final row in exceptionRows) {
      final mapped = row.toDomain();
      if (mapped == null) continue;
      (exceptionsByType[row.wasteTypeId] ??= <CollectionException>[]).add(mapped);
    }

    final sortOrderByType = {for (final t in types) t.id: t.sortOrder};

    final result = <RuleWithExceptions>[];
    for (final row in ruleRows) {
      final recurrence = row.toDomain();
      if (recurrence == null) continue;
      result.add(
        RuleWithExceptions(
          wasteTypeId: row.wasteTypeId,
          recurrence: recurrence,
          exceptions: exceptionsByType[row.wasteTypeId] ?? const <CollectionException>[],
          sortOrder: sortOrderByType[row.wasteTypeId] ?? 0,
        ),
      );
    }
    return result;
  }
}

/// Traduzione riga → dominio per le regole.
extension RecurrenceRuleMapper on RecurrenceRule {
  /// `null` se la riga è incoerente con il proprio `kind`.
  ///
  /// ⚑ Non lancia: una riga storta, arrivata da un import o da una versione futura,
  /// deve far sparire quella regola, non rendere l'app inutilizzabile.
  Recurrence? toDomain() {
    final start = CivilDate.tryParse(startDate);
    if (start == null) return null;
    final end = CivilDate.tryParse(endDate);
    final days = WeekdayMask.toSet(weekdaysMask);

    switch (kind) {
      case 'weekly':
        if (days.isEmpty) return null;
        return WeeklyRecurrence(weekdays: days, startDate: start, endDate: end);

      case 'everyNWeeks':
        final interval = intervalWeeks;
        final anchor = CivilDate.tryParse(anchorDate);
        if (days.isEmpty || interval == null || interval < 2 || anchor == null) return null;
        return EveryNWeeksRecurrence(
          weekdays: days,
          intervalWeeks: interval,
          anchorDate: anchor,
          startDate: start,
          endDate: end,
        );

      case 'monthlyDay':
        final day = dayOfMonth;
        if (day == null || day < 1 || day > 31) return null;
        return MonthlyDayRecurrence(dayOfMonth: day, startDate: start, endDate: end);

      case 'monthlyNthWeekday':
        final nth = nthOfMonth;
        final wd = weekday;
        if (nth == null || wd == null) return null;
        if (nth != -1 && (nth < 1 || nth > 5)) return null;
        if (wd < DateTime.monday || wd > DateTime.sunday) return null;
        return MonthlyNthWeekdayRecurrence(
          nth: nth,
          weekday: wd,
          startDate: start,
          endDate: end,
        );

      case 'manual':
        final csv = manualDatesCsv;
        if (csv == null || csv.isEmpty) return null;
        final dates = csv
            .split(',')
            .map((s) => CivilDate.tryParse(s.trim()))
            .whereType<CivilDate>()
            .toList();
        if (dates.isEmpty) return null;
        return ManualDatesRecurrence(dates: dates, startDate: start, endDate: end);

      default:
        return null;
    }
  }
}

/// Traduzione riga → dominio per le eccezioni.
extension CollectionExceptionMapper on ExceptionRow {
  CollectionException? toDomain() {
    final original = CivilDate.tryParse(originalDate);
    final replacement = CivilDate.tryParse(replacementDate);
    final mapped = CollectionException(
      id: id,
      wasteTypeId: wasteTypeId,
      originalDate: original,
      replacementDate: replacement,
      skipped: skipped,
      note: note,
    );
    return mapped.isWellFormed ? mapped : null;
  }
}

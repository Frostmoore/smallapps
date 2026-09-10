import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:trashcan/data/database.dart';
import 'package:trashcan/data/tables.dart';
import 'package:trashcan/domain/recurrence.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  Future<int> makeCalendar([String name = 'Casa']) => db
      .into(db.collectionCalendars)
      .insert(
        CollectionCalendarsCompanion.insert(
          name: name,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  Future<int> makeWasteType(int calendarId, {String name = 'Organico', int sortOrder = 0}) => db
      .into(db.wasteTypes)
      .insert(
        WasteTypesCompanion.insert(
          calendarId: calendarId,
          name: name,
          iconKey: 'compost',
          colorValue: 0xFF6D8B3C,
          sortOrder: Value(sortOrder),
        ),
      );

  group('vincoli di integrità', () {
    test('le foreign key sono attive: cancellare un calendario porta via tutto', () async {
      // Se PRAGMA foreign_keys non fosse ON, questo test passerebbe con 1 tipo residuo,
      // e in produzione la home mostrerebbe raccolte di calendari inesistenti.
      final calendarId = await makeCalendar();
      final typeId = await makeWasteType(calendarId);
      await db
          .into(db.recurrenceRules)
          .insert(
            RecurrenceRulesCompanion.insert(
              wasteTypeId: typeId,
              kind: 'weekly',
              startDate: '2026-01-01',
              weekdaysMask: Value(WeekdayMask.fromSet({DateTime.monday})),
            ),
          );
      await db
          .into(db.collectionExceptions)
          .insert(
            CollectionExceptionsCompanion.insert(
              wasteTypeId: typeId,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              originalDate: const Value('2026-12-25'),
              skipped: const Value(true),
            ),
          );

      await (db.delete(db.collectionCalendars)..where((t) => t.id.equals(calendarId))).go();

      expect(await db.select(db.wasteTypes).get(), isEmpty);
      expect(await db.select(db.recurrenceRules).get(), isEmpty);
      expect(await db.select(db.collectionExceptions).get(), isEmpty);
    });

    test('un tipo di rifiuto non può appartenere a un calendario inesistente', () async {
      expect(
        () => db
            .into(db.wasteTypes)
            .insert(
              WasteTypesCompanion.insert(
                calendarId: 999,
                name: 'Fantasma',
                iconKey: 'trash',
                colorValue: 0xFF000000,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('mappatura regole', () {
    Future<Recurrence?> mapped(RecurrenceRulesCompanion companion) async {
      await db.into(db.recurrenceRules).insert(companion);
      final row = await db.select(db.recurrenceRules).getSingle();
      return row.toDomain();
    }

    late int typeId;
    setUp(() async {
      final calendarId = await makeCalendar();
      typeId = await makeWasteType(calendarId);
    });

    test('weekly', () async {
      final r = await mapped(
        RecurrenceRulesCompanion.insert(
          wasteTypeId: typeId,
          kind: 'weekly',
          startDate: '2026-01-01',
          weekdaysMask: Value(WeekdayMask.fromSet({DateTime.monday, DateTime.thursday})),
        ),
      );
      expect(r, isA<WeeklyRecurrence>());
      expect((r! as WeeklyRecurrence).weekdays, {DateTime.monday, DateTime.thursday});
    });

    test('everyNWeeks conserva ancora e intervallo', () async {
      final r = await mapped(
        RecurrenceRulesCompanion.insert(
          wasteTypeId: typeId,
          kind: 'everyNWeeks',
          startDate: '2026-01-01',
          weekdaysMask: Value(WeekdayMask.fromSet({DateTime.wednesday})),
          intervalWeeks: const Value(2),
          anchorDate: const Value('2026-09-09'),
        ),
      );
      expect(r, isA<EveryNWeeksRecurrence>());
      final e = r! as EveryNWeeksRecurrence;
      expect(e.intervalWeeks, 2);
      expect(e.anchor, CivilDate.parse('2026-09-09'));
    });

    test('monthlyNthWeekday con ultimo del mese', () async {
      final r = await mapped(
        RecurrenceRulesCompanion.insert(
          wasteTypeId: typeId,
          kind: 'monthlyNthWeekday',
          startDate: '2026-01-01',
          nthOfMonth: const Value(-1),
          weekday: const Value(DateTime.friday),
        ),
      );
      expect(r, isA<MonthlyNthWeekdayRecurrence>());
      expect((r! as MonthlyNthWeekdayRecurrence).nth, -1);
    });

    test('manual scarta le date illeggibili invece di lanciare', () async {
      final r = await mapped(
        RecurrenceRulesCompanion.insert(
          wasteTypeId: typeId,
          kind: 'manual',
          startDate: '2026-01-01',
          manualDatesCsv: const Value('2026-03-01, non-una-data ,2026-04-01'),
        ),
      );
      expect(r, isA<ManualDatesRecurrence>());
      expect((r! as ManualDatesRecurrence).dates, hasLength(2));
    });

    group('righe incoerenti diventano null, non eccezioni', () {
      test('weekly senza giorni', () async {
        expect(
          await mapped(
            RecurrenceRulesCompanion.insert(
              wasteTypeId: typeId,
              kind: 'weekly',
              startDate: '2026-01-01',
            ),
          ),
          isNull,
        );
      });

      test('everyNWeeks senza ancora', () async {
        expect(
          await mapped(
            RecurrenceRulesCompanion.insert(
              wasteTypeId: typeId,
              kind: 'everyNWeeks',
              startDate: '2026-01-01',
              weekdaysMask: Value(WeekdayMask.fromSet({DateTime.monday})),
              intervalWeeks: const Value(2),
            ),
          ),
          isNull,
        );
      });

      test('everyNWeeks con intervallo 1', () async {
        expect(
          await mapped(
            RecurrenceRulesCompanion.insert(
              wasteTypeId: typeId,
              kind: 'everyNWeeks',
              startDate: '2026-01-01',
              weekdaysMask: Value(WeekdayMask.fromSet({DateTime.monday})),
              intervalWeeks: const Value(1),
              anchorDate: const Value('2026-09-09'),
            ),
          ),
          isNull,
        );
      });

      test('kind sconosciuto, per esempio da una versione futura', () async {
        expect(
          await mapped(
            RecurrenceRulesCompanion.insert(
              wasteTypeId: typeId,
              kind: 'lunar_eclipse',
              startDate: '2026-01-01',
            ),
          ),
          isNull,
        );
      });

      test('startDate illeggibile', () async {
        expect(
          await mapped(
            RecurrenceRulesCompanion.insert(
              wasteTypeId: typeId,
              kind: 'weekly',
              startDate: '01/01/2026',
              weekdaysMask: Value(WeekdayMask.fromSet({DateTime.monday})),
            ),
          ),
          isNull,
        );
      });
    });
  });

  group('mappatura eccezioni', () {
    late int typeId;
    setUp(() async {
      final calendarId = await makeCalendar();
      typeId = await makeWasteType(calendarId);
    });

    Future<dynamic> mappedException(CollectionExceptionsCompanion c) async {
      await db.into(db.collectionExceptions).insert(c);
      final row = await db.select(db.collectionExceptions).getSingle();
      return row.toDomain();
    }

    test('le tre forme valide passano', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(
        await mappedException(
          CollectionExceptionsCompanion.insert(
            wasteTypeId: typeId,
            createdAt: now,
            originalDate: const Value('2026-12-25'),
            skipped: const Value(true),
          ),
        ),
        isNotNull,
      );
    });

    test('una forma non prevista viene scartata', () async {
      // Nessuna data: non è né salto, né spostamento, né straordinaria.
      expect(
        await mappedException(
          CollectionExceptionsCompanion.insert(
            wasteTypeId: typeId,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
        isNull,
      );
    });
  });

  group('bundle', () {
    test('raccoglie tipi e regole, e propaga il sortOrder al motore', () async {
      final calendarId = await makeCalendar();
      final organico = await makeWasteType(calendarId, name: 'Organico', sortOrder: 1);
      final carta = await makeWasteType(calendarId, name: 'Carta', sortOrder: 0);

      for (final (typeId, day) in [
        (organico, DateTime.monday),
        (carta, DateTime.wednesday),
      ]) {
        await db
            .into(db.recurrenceRules)
            .insert(
              RecurrenceRulesCompanion.insert(
                wasteTypeId: typeId,
                kind: 'weekly',
                startDate: '2026-01-01',
                weekdaysMask: Value(WeekdayMask.fromSet({day})),
              ),
            );
      }

      final bundle = await db.loadBundle(calendarId);
      expect(bundle, isNotNull);
      expect(bundle!.wasteTypes.map((t) => t.name), ['Carta', 'Organico']);
      expect(bundle.rules, hasLength(2));
      expect(bundle.typeOf(organico)?.name, 'Organico');
      expect(bundle.typeOf(9999), isNull);

      final ordini = {for (final r in bundle.rules) r.wasteTypeId: r.sortOrder};
      expect(ordini[carta], 0);
      expect(ordini[organico], 1);
    });

    test('un calendario inesistente restituisce null', () async {
      expect(await db.loadBundle(4242), isNull);
    });

    test('un calendario senza tipi restituisce un bundle vuoto, non null', () async {
      final calendarId = await makeCalendar();
      final bundle = await db.loadBundle(calendarId);
      expect(bundle, isNotNull);
      expect(bundle!.wasteTypes, isEmpty);
      expect(bundle.rules, isEmpty);
    });

    test('le regole illeggibili spariscono dal bundle senza far fallire il resto', () async {
      final calendarId = await makeCalendar();
      final typeId = await makeWasteType(calendarId);
      await db
          .into(db.recurrenceRules)
          .insert(
            RecurrenceRulesCompanion.insert(
              wasteTypeId: typeId,
              kind: 'weekly',
              startDate: '2026-01-01',
              weekdaysMask: Value(WeekdayMask.fromSet({DateTime.monday})),
            ),
          );
      await db
          .into(db.recurrenceRules)
          .insert(
            RecurrenceRulesCompanion.insert(
              wasteTypeId: typeId,
              kind: 'weekly',
              startDate: '2026-01-01',
            ),
          );

      final bundle = await db.loadBundle(calendarId);
      expect(bundle!.rules, hasLength(1), reason: 'la regola senza giorni viene scartata');
    });
  });

  group('conteggi e stream', () {
    test('countCalendars', () async {
      expect(await db.countCalendars(), 0);
      await makeCalendar('Casa');
      await makeCalendar('Mare');
      expect(await db.countCalendars(), 2);
    });

    test('watchCalendars emette a ogni inserimento', () async {
      final emissions = <int>[];
      final sub = db.watchCalendars().listen((rows) => emissions.add(rows.length));
      await makeCalendar('Casa');
      await pumpEventQueue();
      await makeCalendar('Mare');
      await pumpEventQueue();
      await sub.cancel();
      expect(emissions.last, 2);
    });
  });
}

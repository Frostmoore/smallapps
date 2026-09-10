import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:trashcan/data/database.dart';
import 'package:trashcan/data/repository.dart';
import 'package:trashcan/domain/recurrence.dart';
import 'package:trashcan/services/trashcan_backup_source.dart';

/// Esportazione e reimportazione dei dati di TrashCan.
///
/// ⚑ Perché questi test contano più della media: un import è distruttivo e irreversibile.
/// Un difetto qui non produce un messaggio d'errore, produce un utente che ha perso il
/// calendario che aveva configurato a mano leggendo il volantino del Comune. E il caso in
/// cui si usa questa funzione è, per definizione, quello in cui l'utente non ha una copia
/// da cui rifare.
void main() {
  late AppDatabase db;
  late TrashcanRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = TrashcanRepository(db);
  });
  tearDown(() => db.close());

  Future<int> seed({String calendarName = 'Casa'}) async {
    final calendarId = await repo.createCalendar(name: calendarName);
    final organic = await repo.createWasteType(
      calendarId: calendarId,
      name: 'Organico',
      iconKey: 'compost',
      colorValue: 0xFF6D8B3C,
    );
    await repo.setWeeklyRule(
      wasteTypeId: organic,
      weekdays: {DateTime.tuesday, DateTime.friday},
    );
    await repo.skipCollection(wasteTypeId: organic, date: CivilDate(2026, 12, 25));

    final paper = await repo.createWasteType(
      calendarId: calendarId,
      name: 'Carta',
      iconKey: 'paper',
      colorValue: 0xFF2E6DA4,
      sortOrder: 1,
    );
    await repo.setEveryNWeeksRule(
      wasteTypeId: paper,
      weekdays: {DateTime.wednesday},
      intervalWeeks: 2,
      anchorDate: CivilDate(2026, 9, 9),
    );
    return calendarId;
  }

  test('un giro completo su un database vuoto ricostruisce tutto', () async {
    await seed();
    final payload = await TrashcanBackupSource(db).exportPayload();

    // Un secondo database, come fosse un telefono nuovo.
    final fresh = AppDatabase.memory();
    addTearDown(fresh.close);
    await TrashcanBackupSource(
      fresh,
    ).importPayload(payload, mode: ImportMode.replaceAll);

    final calendars = await fresh.allCalendars();
    expect(calendars, hasLength(1));
    expect(calendars.single.name, 'Casa');

    final bundle = await fresh.loadBundle(calendars.single.id);
    expect(bundle!.wasteTypes.map((t) => t.name), ['Organico', 'Carta']);
    expect(bundle.rules, hasLength(2));

    final organicRule = bundle.rules.firstWhere(
      (r) => bundle.typeOf(r.wasteTypeId)!.name == 'Organico',
    );
    expect(organicRule.recurrence, isA<WeeklyRecurrence>());
    expect(organicRule.exceptions, hasLength(1));

    final paperRule = bundle.rules.firstWhere(
      (r) => bundle.typeOf(r.wasteTypeId)!.name == 'Carta',
    );
    // L'ancora distingue i mercoledi' pari dai dispari: perderla sposta meta' delle
    // raccolte di una settimana, e nessuno se ne accorge finche' il camion non passa.
    expect((paperRule.recurrence as EveryNWeeksRecurrence).anchor, CivilDate(2026, 9, 9));
    expect((paperRule.recurrence as EveryNWeeksRecurrence).intervalWeeks, 2);
  });

  test('replaceAll cancella quello che c-era', () async {
    await seed(calendarName: 'Vecchio');
    final payload = <String, Object?>{
      'calendars': [
        {'name': 'Nuovo', 'wasteTypes': <Object?>[]},
      ],
    };

    await TrashcanBackupSource(db).importPayload(payload, mode: ImportMode.replaceAll);

    final calendars = await db.allCalendars();
    expect(calendars.map((c) => c.name), ['Nuovo']);
  });

  test('mergeKeepExisting non tocca quello che c-e e non duplica', () async {
    await seed(calendarName: 'Casa');
    final payload = <String, Object?>{
      'calendars': [
        {'name': 'Casa', 'wasteTypes': <Object?>[]},
        {'name': 'Mare', 'wasteTypes': <Object?>[]},
      ],
    };

    await TrashcanBackupSource(db).importPayload(payload, mode: ImportMode.mergeKeepExisting);

    final calendars = await db.allCalendars();
    expect(calendars.map((c) => c.name).toList()..sort(), ['Casa', 'Mare']);

    // "Casa" e' rimasto quello di prima, con dentro i suoi tipi: non e' stato
    // sostituito da quello vuoto del file.
    final casa = calendars.firstWhere((c) => c.name == 'Casa');
    final bundle = await db.loadBundle(casa.id);
    expect(bundle!.wasteTypes, hasLength(2));
  });

  test('esportare un solo calendario esporta solo quello', () async {
    final first = await seed(calendarName: 'Casa');
    await seed(calendarName: 'Mare');

    final payload = await TrashcanBackupSource(db, onlyCalendarId: first).exportPayload();
    final calendars = payload['calendars']! as List<Object?>;
    expect(calendars, hasLength(1));
    expect((calendars.single! as Map)['name'], 'Casa');
  });

  test('i conteggi mostrati prima del ripristino sono quelli veri', () async {
    await seed();
    final counts = await TrashcanBackupSource(db).counts();
    expect(counts['calendars'], 1);
    expect(counts['wasteTypes'], 2);
    expect(counts['rules'], 2);
  });

  group('file storti', () {
    test('un payload senza calendari non fa niente e non lancia', () async {
      await TrashcanBackupSource(db).importPayload(<String, Object?>{}, mode: ImportMode.mergeKeepExisting);
      expect(await db.allCalendars(), isEmpty);
    });

    test('un calendario senza nome viene saltato, gli altri passano', () async {
      final payload = <String, Object?>{
        'calendars': [
          {'wasteTypes': <Object?>[]},
          {'name': '', 'wasteTypes': <Object?>[]},
          {'name': 'Buono', 'wasteTypes': <Object?>[]},
        ],
      };
      await TrashcanBackupSource(db).importPayload(payload, mode: ImportMode.replaceAll);
      expect((await db.allCalendars()).map((c) => c.name), ['Buono']);
    });

    test('una regola illeggibile fa perdere la regola, non il tipo di rifiuto', () async {
      final payload = <String, Object?>{
        'calendars': [
          {
            'name': 'Casa',
            'wasteTypes': [
              {
                'name': 'Organico',
                'iconKey': 'compost',
                'colorValue': 123,
                // Manca `startDate`: il mapper di lettura la scarterebbe comunque.
                'rules': [
                  {'kind': 'weekly', 'weekdaysMask': 4},
                ],
              },
            ],
          },
        ],
      };
      await TrashcanBackupSource(db).importPayload(payload, mode: ImportMode.replaceAll);

      final calendar = (await db.allCalendars()).single;
      final bundle = await db.loadBundle(calendar.id);
      expect(bundle!.wasteTypes, hasLength(1), reason: 'il tipo deve sopravvivere');
      expect(bundle.rules, isEmpty, reason: 'la regola storta sparisce');
    });

    test('tipi di dato inattesi vengono convertiti o ignorati senza lanciare', () async {
      final payload = <String, Object?>{
        'calendars': [
          {
            'name': 'Casa',
            'enabled': 'true', // stringa invece di booleano
            'sortOrder': '3', // stringa invece di intero
            'wasteTypes': [
              {
                'name': 'Organico',
                'colorValue': 1.0, // double invece di intero
                'notificationsEnabled': 0, // intero invece di booleano
                'rules': 'non una lista',
                'exceptions': null,
              },
            ],
          },
        ],
      };
      await TrashcanBackupSource(db).importPayload(payload, mode: ImportMode.replaceAll);

      final calendar = (await db.allCalendars()).single;
      expect(calendar.enabled, isTrue);
      expect(calendar.sortOrder, 3);
      final bundle = await db.loadBundle(calendar.id);
      expect(bundle!.wasteTypes.single.notificationsEnabled, isFalse);
    });
  });
}

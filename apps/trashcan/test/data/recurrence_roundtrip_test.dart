import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:trashcan/data/database.dart';
import 'package:trashcan/data/repository.dart';
import 'package:trashcan/domain/recurrence.dart';

/// Andata e ritorno tra dominio e tabella per tutte e cinque le forme di ricorrenza.
///
/// ⚑ Perché questo test esiste: la tabella delle regole è volutamente "larga", con molte
/// colonne nullable di cui solo alcune valide per ciascun `kind`. Scrittura e lettura vivono
/// in due file diversi (`RecurrenceToRow` in repository.dart, `RecurrenceRuleMapper` in
/// database.dart) e nulla nel compilatore lega le due. Se una scrive `anchorDate` e l'altra
/// la pretende obbligatoria, la regola sparisce alla riapertura dell'app: il tipo di rifiuto
/// resta, i giorni no, e l'utente lo scopre quando il camion è già passato.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  Future<int> makeWasteType() async {
    final calendarId = await db
        .into(db.collectionCalendars)
        .insert(
          CollectionCalendarsCompanion.insert(
            name: 'Casa',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    return db
        .into(db.wasteTypes)
        .insert(
          WasteTypesCompanion.insert(
            calendarId: calendarId,
            name: 'Organico',
            iconKey: 'compost',
            colorValue: 0xFF6D8B3C,
          ),
        );
  }

  /// Scrive la ricorrenza con `setRule` e la rilegge dal database.
  Future<Recurrence?> roundTrip(Recurrence recurrence) async {
    final typeId = await makeWasteType();
    final repo = TrashcanRepository(db);
    await repo.setRule(wasteTypeId: typeId, recurrence: recurrence);
    return repo.ruleOf(typeId);
  }

  final start = CivilDate(2026, 9, 1);

  test('settimanale sopravvive al giro completo', () async {
    final original = WeeklyRecurrence(
      weekdays: {DateTime.tuesday, DateTime.friday},
      startDate: start,
    );
    expect(await roundTrip(original), original);
  });

  test('a settimane alterne conserva intervallo e ancora', () async {
    final original = EveryNWeeksRecurrence(
      weekdays: {DateTime.wednesday},
      intervalWeeks: 2,
      anchorDate: CivilDate(2026, 9, 9),
      startDate: start,
    );
    final read = await roundTrip(original);
    expect(read, original);
    // L'ancora e' cio' che distingue "i mercoledi pari" dai "mercoledi dispari": se si
    // perdesse, meta' delle raccolte finirebbe nella settimana sbagliata.
    expect((read! as EveryNWeeksRecurrence).anchor, CivilDate(2026, 9, 9));
  });

  test('mensile per giorno del mese sopravvive al giro completo', () async {
    final original = MonthlyDayRecurrence(dayOfMonth: 15, startDate: start);
    expect(await roundTrip(original), original);
  });

  test('mensile per ennesimo giorno della settimana conserva anche -1 = ultimo', () async {
    final original = MonthlyNthWeekdayRecurrence(
      nth: -1,
      weekday: DateTime.friday,
      startDate: start,
    );
    final read = await roundTrip(original);
    expect(read, original);
    expect((read! as MonthlyNthWeekdayRecurrence).nth, -1);
  });

  test('date manuali sopravvivono al giro completo, ordinate', () async {
    final original = ManualDatesRecurrence(
      dates: [CivilDate(2026, 10, 3), CivilDate(2026, 9, 12)],
      startDate: start,
    );
    final read = await roundTrip(original);
    expect(read, original);
  });

  test('la data di fine viene conservata quando c-e, e resta nulla quando non c-e', () async {
    final withEnd = WeeklyRecurrence(
      weekdays: {DateTime.monday},
      startDate: start,
      endDate: CivilDate(2026, 12, 31),
    );
    expect((await roundTrip(withEnd))!.endDate, CivilDate(2026, 12, 31));

    final withoutEnd = WeeklyRecurrence(weekdays: {DateTime.monday}, startDate: start);
    expect((await roundTrip(withoutEnd))!.endDate, isNull);
  });

  test('setRule sostituisce la regola precedente invece di affiancarla', () async {
    // Due regole per lo stesso tipo produrrebbero raccolte doppie: l'editor mostra un solo
    // insieme di giorni, quindi l'utente non avrebbe modo di vedere ne' togliere la vecchia.
    final typeId = await makeWasteType();
    final repo = TrashcanRepository(db);
    await repo.setRule(
      wasteTypeId: typeId,
      recurrence: WeeklyRecurrence(weekdays: {DateTime.monday}, startDate: start),
    );
    await repo.setRule(
      wasteTypeId: typeId,
      recurrence: MonthlyDayRecurrence(dayOfMonth: 4, startDate: start),
    );

    final rows = await (db.select(
      db.recurrenceRules,
    )..where((r) => r.wasteTypeId.equals(typeId))).get();
    expect(rows, hasLength(1));
    expect(rows.single.kind, 'monthlyDay');
  });
}

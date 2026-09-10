import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:trashcan/data/database.dart';
import 'package:trashcan/data/repository.dart';
import 'package:trashcan/domain/occurrence_engine.dart';

/// Le eccezioni di un tipo di rifiuto **senza regola** devono restare visibili.
///
/// ☠ È il caso degli ingombranti: nessun calendario fisso, solo raccolte prenotate una
/// alla volta. `_rulesFor` costruiva la lista partendo dalle righe di `recurrence_rules`,
/// quindi un tipo senza regola non compariva affatto, e con lui sparivano le sue eccezioni.
/// `OccurrenceEngine.expand` itera sulle regole: la raccolta straordinaria non sarebbe mai
/// stata generata. L'utente inserisce una data, la vede sparire e non ha modo di capire
/// perché.
void main() {
  late AppDatabase db;
  late TrashcanRepository repo;
  late int calendarId;

  setUp(() async {
    db = AppDatabase.memory();
    repo = TrashcanRepository(db);
    calendarId = await repo.createCalendar(name: 'Casa');
  });
  tearDown(() => db.close());

  test('una raccolta straordinaria su un tipo senza regola arriva fino al motore', () async {
    final typeId = await repo.createWasteType(
      calendarId: calendarId,
      name: 'Ingombranti',
      iconKey: 'bulky',
      colorValue: 0xFF7A5C3E,
    );
    final date = CivilDate.today().addDays(10);
    await repo.addExtraCollection(wasteTypeId: typeId, date: date);

    final bundle = await db.loadBundle(calendarId);
    expect(
      bundle!.rules,
      hasLength(1),
      reason: 'il tipo senza regola deve comunque portare con se le sue eccezioni',
    );

    const engine = OccurrenceEngine();
    final occurrences = engine.expand(
      rules: bundle.rules,
      from: CivilDate.today(),
      to: CivilDate.today().addDays(30),
    );
    expect(occurrences, hasLength(1));
    expect(occurrences.single.date, date);
    expect(occurrences.single.origin, OccurrenceOrigin.extra);
  });

  test('la ricorrenza sintetica non genera raccolte di suo', () async {
    final typeId = await repo.createWasteType(
      calendarId: calendarId,
      name: 'Ingombranti',
      iconKey: 'bulky',
      colorValue: 0xFF7A5C3E,
    );
    // Un'eccezione che salta una raccolta inesistente: non deve produrre niente, ma non
    // deve nemmeno far comparire date dal nulla.
    await repo.skipCollection(wasteTypeId: typeId, date: CivilDate.today().addDays(3));

    final bundle = await db.loadBundle(calendarId);
    const engine = OccurrenceEngine();
    final occurrences = engine.expand(
      rules: bundle!.rules,
      from: CivilDate.today(),
      to: CivilDate.today().addDays(365),
    );
    expect(occurrences, isEmpty);
  });

  test('un tipo che ha una regola non viene duplicato', () async {
    final typeId = await repo.createWasteType(
      calendarId: calendarId,
      name: 'Carta',
      iconKey: 'paper',
      colorValue: 0xFF2E6DA4,
    );
    await repo.setWeeklyRule(wasteTypeId: typeId, weekdays: {DateTime.monday});
    await repo.addExtraCollection(wasteTypeId: typeId, date: CivilDate.today().addDays(2));

    final bundle = await db.loadBundle(calendarId);
    expect(bundle!.rules, hasLength(1));
    expect(bundle.rules.single.exceptions, hasLength(1));
  });
}

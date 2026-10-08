import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:scorte_calore/data/database.dart';
import 'package:scorte_calore/data/scorte_repository.dart';
import 'package:scorte_calore/domain/fuel_units.dart';
import 'package:scorte_calore/services/calendar_sync.dart';

/// Un calendario finto: gli eventi stanno in una mappa, come in un telefono.
class _FakeGateway implements CalendarGateway {
  bool granted = true;
  List<CalendarChoice> calendars = const [
    CalendarChoice(id: 'lavoro', name: 'Lavoro'),
    CalendarChoice(id: 'casa', name: 'Casa', isPrimary: true),
  ];
  final Map<String, ({String calendarId, String title, CivilDate day})> events = {};
  int _next = 0;

  @override
  Future<bool> requestAccess() async => granted;

  @override
  Future<List<CalendarChoice>> writableCalendars() async => calendars;

  @override
  Future<String> createAllDay({
    required String calendarId,
    required String title,
    required String description,
    required CivilDate day,
  }) async {
    final id = 'evt-${++_next}';
    events[id] = (calendarId: calendarId, title: title, day: day);
    return id;
  }

  @override
  Future<void> updateAllDay({
    required String eventId,
    required String title,
    required String description,
    required CivilDate day,
  }) async {
    final e = events[eventId];
    if (e == null) throw const CalendarEventMissing();
    events[eventId] = (calendarId: e.calendarId, title: title, day: day);
  }

  @override
  Future<void> delete(String eventId) async {
    if (events.remove(eventId) == null) throw const CalendarEventMissing();
  }
}

void main() {
  late AppDatabase db;
  late ScorteRepository repo;
  late _FakeGateway gateway;
  late CalendarSyncService service;
  late FuelSource stufa;
  const texts = (title: 'Riordino Pellet · Stufa', description: 'Autonomia stimata fino al 9 dicembre.');

  setUp(() async {
    db = AppDatabase.memory();
    repo = ScorteRepository(db);
    gateway = _FakeGateway();
    service = CalendarSyncService(repo, gateway);
    final id = await repo.addSource(name: 'Stufa', fuelType: FuelType.pellet);
    stufa = (await repo.allSources()).singleWhere((s) => s.id == id);
  });
  tearDown(() => db.close());

  Future<Result<String>> scrivi(CivilDate date, {String? existing}) => service.upsertReorderEvent(
    source: stufa,
    date: date,
    calendarId: 'casa',
    texts: texts,
    existingEventId: existing,
  );

  test('i calendari arrivano col principale per primo', () async {
    final r = await service.availableCalendars();
    expect(r.valueOrNull!.map((c) => c.id), ['casa', 'lavoro']);
  });

  test('permesso negato o nessun calendario: errori con il loro codice', () async {
    gateway.granted = false;
    expect((await service.availableCalendars()).errorOrNull!.code, CalendarSyncService.errDenied);
    expect((await scrivi(CivilDate(2026, 12, 1))).errorOrNull!.code, CalendarSyncService.errDenied);
    expect(gateway.events, isEmpty);
    gateway
      ..granted = true
      ..calendars = const [];
    expect((await service.availableCalendars()).errorOrNull!.code, CalendarSyncService.errNoCalendar);
  });

  test('crea l evento di un giorno e se lo ricorda con la data scritta', () async {
    final id = (await scrivi(CivilDate(2026, 12, 1))).valueOrNull!;
    expect(gateway.events[id]!.day, CivilDate(2026, 12, 1));
    final r = (await repo.reminderFor(stufa.id))!;
    expect(r.externalEventId, id);
    expect(r.calendarId, 'casa');
    expect(r.calculatedDate, '2026-12-01');
  });

  test('aggiornare sposta lo stesso evento, senza duplicarlo', () async {
    final id = (await scrivi(CivilDate(2026, 12, 1))).valueOrNull!;
    final again = (await scrivi(CivilDate(2026, 12, 8), existing: id)).valueOrNull!;
    expect(again, id);
    expect(gateway.events, hasLength(1));
    expect(gateway.events[id]!.day, CivilDate(2026, 12, 8));
    expect((await repo.reminderFor(stufa.id))!.calculatedDate, '2026-12-08');
  });

  test('un evento cancellato a mano dal calendario si ricrea', () async {
    final id = (await scrivi(CivilDate(2026, 12, 1))).valueOrNull!;
    gateway.events.clear();
    final nuovo = (await scrivi(CivilDate(2026, 12, 8), existing: id)).valueOrNull!;
    expect(nuovo, isNot(id));
    expect(gateway.events.keys, [nuovo]);
    expect((await repo.reminderFor(stufa.id))!.externalEventId, nuovo);
  });

  test('forgetSource toglie l evento e il promemoria, anche se l evento era gia sparito', () async {
    await scrivi(CivilDate(2026, 12, 1));
    await service.forgetSource(stufa.id);
    expect(gateway.events, isEmpty);
    expect(await repo.reminderFor(stufa.id), isNull);

    await scrivi(CivilDate(2026, 12, 1));
    gateway.events.clear();
    await service.forgetSource(stufa.id);
    expect(await repo.reminderFor(stufa.id), isNull);
  });

  test('forgetAll toglie gli eventi di tutte le fonti (prima di un ripristino)', () async {
    await scrivi(CivilDate(2026, 12, 1));
    final altra = await repo.addSource(name: 'GPL', fuelType: FuelType.lpg);
    final gpl = (await repo.allSources()).singleWhere((s) => s.id == altra);
    await service.upsertReorderEvent(source: gpl, date: CivilDate(2026, 11, 2), calendarId: 'lavoro', texts: texts);
    expect(gateway.events, hasLength(2));
    await service.forgetAll();
    expect(gateway.events, isEmpty);
    expect(await repo.watchReminders().first, isEmpty);
  });

  test('la proposta di aggiornamento parte oltre i 3 giorni, in entrambe le direzioni', () {
    final scritta = CivilDate(2026, 12, 10);
    expect(CalendarSyncService.drifted(scritta, CivilDate(2026, 12, 13)), isFalse);
    expect(CalendarSyncService.drifted(scritta, CivilDate(2026, 12, 7)), isFalse);
    expect(CalendarSyncService.drifted(scritta, CivilDate(2026, 12, 14)), isTrue);
    expect(CalendarSyncService.drifted(scritta, CivilDate(2026, 12, 6)), isTrue);
  });
}

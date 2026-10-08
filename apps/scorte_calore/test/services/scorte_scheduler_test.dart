import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:scorte_calore/app/feature_limits.dart';
import 'package:scorte_calore/app/routes.dart';
import 'package:scorte_calore/data/database.dart';
import 'package:scorte_calore/data/scorte_repository.dart';
import 'package:scorte_calore/domain/fuel_source.dart';
import 'package:scorte_calore/domain/fuel_units.dart';
import 'package:scorte_calore/l10n/generated/app_localizations.dart';
import 'package:scorte_calore/services/scorte_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un `NotificationService` finto: registra cosa gli viene consegnato invece di parlare con
/// il plugin. `implements` e non `extends`: il costruttore vero e' privato.
class _FakeNotifications implements NotificationService {
  List<ScheduledNotification> scheduled = [];
  int cancelAllCalls = 0;

  @override
  Future<int> replaceSchedule(Iterable<ScheduledNotification> wanted) async {
    scheduled = wanted.toList();
    return scheduled.length;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled = [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// F5.8: le notifiche di riordino, dallo scheduler al servizio.
void main() {
  late AppDatabase db;
  late ScorteRepository repo;
  late SettingsStore settings;
  late _FakeNotifications fake;
  // Mercoledi' 7 ottobre 2026, mezzogiorno, ora locale.
  final now = DateTime(2026, 10, 7, 12);

  /// [switchOn] null: l'interruttore mai toccato, cioe' il default.
  Future<void> setUpWith({required bool? switchOn}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (switchOn != null) 'sc_test.${SettingKeys.notificationsEnabled}': switchOn,
    });
    settings = await SettingsStore.create(namespace: 'sc_test');
  }

  setUp(() async {
    db = AppDatabase.memory();
    repo = ScorteRepository(db, clock: () => now.toUtc());
    fake = _FakeNotifications();
    await setUpWith(switchOn: true);
  });
  tearDown(() => db.close());

  ScorteScheduler scheduler({required bool pro, String lang = 'it'}) => ScorteScheduler(
    repo: repo,
    settings: settings,
    gate: FeatureGate(limits: scorteFeatureLimits, isPro: pro),
    l: lookupL(Locale(lang)),
    notifications: fake,
    clock: () => now,
  );

  Future<void> misura(int source, String iso, double sacchi) =>
      repo.upsertMeasurement(source, Measurement.absolute(date: CivilDate.parse(iso), quantity: sacchi));

  /// Pellet in sacchi, anticipo 7 giorni. 60 → 40 in 10 giorni, 40 → 28 in 6: 2 sacchi al
  /// giorno. 28 sacchi il 6/10 → esaurimento il 20/10, riordino il 13/10.
  Future<int> pelletConStima() async {
    final id = await repo.addSource(name: 'Stufa soggiorno', fuelType: FuelType.pellet);
    await misura(id, '2026-09-20', 60);
    await misura(id, '2026-09-30', 40);
    await misura(id, '2026-10-06', 28);
    return id;
  }

  test('senza Pro: nessuna notifica, e quelle gia pianificate si cancellano', () async {
    await pelletConStima();
    fake.scheduled = [
      ScheduledNotification(id: 11, localWhen: DateTime(2026, 10, 13, 10), title: 'vecchia', body: '', channelId: scorteChannelId),
    ];
    await scheduler(pro: false).rescheduleAll();
    expect(fake.scheduled, isEmpty);
    expect(fake.cancelAllCalls, 1);
  });

  test('con Pro ma interruttore spento (il default): nessuna notifica', () async {
    await setUpWith(switchOn: null);
    await pelletConStima();
    await scheduler(pro: true).rescheduleAll();
    expect(fake.scheduled, isEmpty);
    expect(fake.cancelAllCalls, 1);
  });

  test('con Pro e interruttore acceso: riordino e superamento con id, ora e testo', () async {
    final id = await pelletConStima();
    await scheduler(pro: true).rescheduleAll();

    expect(fake.scheduled, hasLength(2));
    final reorder = fake.scheduled.firstWhere((n) => n.id == id * 10 + 1);
    final overdue = fake.scheduled.firstWhere((n) => n.id == id * 10 + 2);

    // Alle 10:00 locali della data di riordino, e 3 giorni dopo.
    expect(reorder.localWhen, DateTime(2026, 10, 13, 10));
    expect(overdue.localWhen, DateTime(2026, 10, 16, 10));

    // Il 13/10 mancano 7 giorni al 20/10 e restano 28 - 2 x 7 = 14 sacchi.
    expect(reorder.title, 'Stufa soggiorno: è ora di riordinare');
    expect(reorder.body, 'Pellet: potrebbe terminare tra circa 7 giorni. Ti restano circa 14 sacchi.');
    expect(overdue.title, 'Stufa soggiorno: data di riordino superata');
    expect(overdue.body, startsWith('Hai superato la data prevista di riordino (Pellet).'));

    for (final n in fake.scheduled) {
      expect(n.channelId, scorteChannelId);
      expect(n.payload, Routes.home);
      expect(n.exact, isFalse, reason: 'F5.8: inexactAllowWhileIdle');
    }
    expect(settings.getInstant(SettingKeys.lastRescheduleAt), now.toUtc());
  });

  test('i testi seguono la lingua dello scheduler', () async {
    await pelletConStima();
    await scheduler(pro: true, lang: 'en').rescheduleAll();
    final reorder = fake.scheduled.firstWhere((n) => n.id % 10 == 1);
    expect(reorder.title, 'Stufa soggiorno: time to reorder');
    expect(reorder.body, 'Pellets could run out in about 7 days. About 14 bags left.');
  });

  test('stima insufficiente (una misura sola): nessuna notifica', () async {
    final id = await repo.addSource(name: 'Bombolone', fuelType: FuelType.lpg, tankCapacity: 1000);
    await repo.upsertMeasurement(id, Measurement.absolute(date: CivilDate(2026, 10, 6), quantity: 500));
    await scheduler(pro: true).rescheduleAll();
    expect(fake.scheduled, isEmpty);
    // Con il Pro e l'interruttore acceso non si cancella "tutto": si consegna un piano vuoto,
    // che `replaceSchedule` usa per togliere le pendenti.
    expect(fake.cancelAllCalls, 0);
  });

  test('una misura nuova (rifornimento) ripianifica: date nuove, stessi id', () async {
    final id = await pelletConStima();
    final s = scheduler(pro: true);
    await s.rescheduleAll();
    expect(fake.scheduled.map((n) => n.localWhen), contains(DateTime(2026, 10, 13, 10)));

    // Il 7/10 arrivano 60 sacchi: e' un rifornimento, non entra nella media (sempre 2 al
    // giorno). 60 / 2 = 30 giorni → esaurimento il 6/11, riordino il 30/10, superamento il 2/11.
    await misura(id, '2026-10-07', 60);
    await s.rescheduleAll();
    expect(fake.scheduled.map((n) => n.localWhen).toSet(), {DateTime(2026, 10, 30, 10), DateTime(2026, 11, 2, 10)});
    expect(fake.scheduled.map((n) => n.id).toSet(), {id * 10 + 1, id * 10 + 2},
        reason: 'stessi id: ripianificare sostituisce, non duplica');
    final reorder = fake.scheduled.firstWhere((n) => n.id == id * 10 + 1);
    // Il 30/10: 60 - 2 x 23 = 14 sacchi, 7 giorni all'esaurimento.
    expect(reorder.body, 'Pellet: potrebbe terminare tra circa 7 giorni. Ti restano circa 14 sacchi.');
  });

  test('misurata dopo la data di riordino: niente superamento', () async {
    final id = await pelletConStima();
    // Il 14/10 (riordino era il 13/10) restano 12 sacchi: sempre 2 al giorno, esaurimento
    // il 20/10. Il riordino e' passato e chi ha appena misurato sa gia' come sta.
    final dopo = DateTime(2026, 10, 14, 8);
    await misura(id, '2026-10-14', 12);
    final s = ScorteScheduler(
      repo: repo,
      settings: settings,
      gate: FeatureGate(limits: scorteFeatureLimits, isPro: true),
      l: lookupL(const Locale('it')),
      notifications: fake,
      clock: () => dopo,
    );
    await s.rescheduleAll();
    expect(fake.scheduled, isEmpty);
  });

  test('una fonte disattivata o eliminata non lascia notifiche orfane', () async {
    final id = await pelletConStima();
    final s = scheduler(pro: true);
    await s.rescheduleAll();
    expect(fake.scheduled, hasLength(2));
    await repo.setSourceActive(id, false);
    await s.rescheduleAll();
    expect(fake.scheduled, isEmpty);

    await repo.setSourceActive(id, true);
    await s.rescheduleAll();
    expect(fake.scheduled, hasLength(2));
    await repo.deleteSource(id);
    await s.rescheduleAll();
    expect(fake.scheduled, isEmpty);
  });
}

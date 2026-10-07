import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/app/feature_limits.dart';
import 'package:full_freezer/data/database.dart';
import 'package:full_freezer/data/freezer_repository.dart';
import 'package:full_freezer/domain/capacity.dart';
import 'package:full_freezer/domain/units.dart';
import 'package:full_freezer/l10n/generated/app_localizations.dart';
import 'package:full_freezer/services/freezer_scheduler.dart';
import 'package:full_freezer/services/notification_plan.dart';
import 'package:micro_core/micro_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F4.9: il piano delle notifiche.
void main() {
  group('date del riepilogo', () {
    test('settimanale: le prossime domeniche, oggi compreso se e domenica', () {
      final domenica = CivilDate(2026, 10, 11);
      expect(domenica.weekday, DateTime.sunday);
      final d = digestDates(CivilDate(2026, 10, 7), DigestFrequency.weekly);
      expect(d.first, domenica);
      expect(d[1], CivilDate(2026, 10, 18));
      expect(d, hasLength(8));
      expect(digestDates(domenica, DigestFrequency.weekly).first, domenica);
    });

    test('ogni due settimane e ogni quattro', () {
      final b = digestDates(CivilDate(2026, 10, 7), DigestFrequency.biweekly);
      expect(b[1], CivilDate(2026, 10, 25));
      final m = digestDates(CivilDate(2026, 10, 7), DigestFrequency.monthly);
      expect(m[1], CivilDate(2026, 11, 8));
    });
  });

  group('testo del riepilogo', () {
    Item item(int id, String name, String frozenAt, String? category) => Item(
      id: id,
      freezerId: 1,
      name: name,
      nameNorm: name.toLowerCase(),
      category: category,
      quantity: 1,
      unit: 'portions',
      frozenAt: frozenAt,
      volumeLiters: 0.4,
      volumeManual: false,
      status: 'stored',
      createdAt: 0,
    );

    test('conta chi sara vecchio QUEL giorno, con i giorni di quel giorno', () {
      // Pesce: promemoria a 120 giorni. Congelato il 1 giugno.
      final items = [item(1, 'Merluzzo', '2026-06-01', 'fish')];
      // Il 7 ottobre ha 128 giorni: gia' vecchio.
      expect(digestFor(items, CivilDate(2026, 10, 7))!.oldestDays, 128);
      // Tre settimane dopo: 149, non 128.
      expect(digestFor(items, CivilDate(2026, 10, 28))!.oldestDays, 149);
    });

    test('chi invecchia nel frattempo entra nei riepiloghi successivi', () {
      // Pane: promemoria a 90. Congelato il 20 luglio -> 79 giorni il 7/10, 100 il 28/10.
      final items = [item(1, 'Pane', '2026-07-20', 'bread')];
      expect(digestFor(items, CivilDate(2026, 10, 7)), isNull);
      expect(digestFor(items, CivilDate(2026, 10, 28))!.oldCount, 1);
    });

    test('il piu vecchio e quello con piu giorni', () {
      final items = [
        item(1, 'Pane', '2026-06-01', 'bread'),
        item(2, 'Spezzatino', '2026-01-01', 'meat_red'),
      ];
      final c = digestFor(items, CivilDate(2026, 10, 7))!;
      expect(c.oldCount, 2);
      expect(c.oldest, 'Spezzatino');
    });

    test('senza niente di vecchio, niente riepilogo', () {
      expect(digestFor([item(1, 'Gelato', '2026-10-01', 'ice_cream')], CivilDate(2026, 10, 7)), isNull);
    });
  });

  group('orari degli avvisi di capienza', () {
    test('quasi pieno: subito', () {
      final now = DateTime(2026, 10, 7, 19, 30);
      expect(alertTime(full: true, now: now).difference(now).inSeconds, 10);
    });

    test('quasi vuoto: il sabato successivo alle 10', () {
      // 7 ottobre 2026 e' mercoledi': sabato 10 alle 10.
      expect(alertTime(full: false, now: DateTime(2026, 10, 7, 19)), DateTime(2026, 10, 10, 10));
      // Sabato alle 9: oggi alle 10.
      expect(alertTime(full: false, now: DateTime(2026, 10, 10, 9)), DateTime(2026, 10, 10, 10));
      // Sabato alle 11: il sabato dopo.
      expect(alertTime(full: false, now: DateTime(2026, 10, 10, 11)), DateTime(2026, 10, 17, 10));
    });

    test('un avviso in coda si conserva e si rilegge uguale, con un id stabile', () {
      final a = PendingAlert(freezerId: 3, full: false, when: DateTime(2026, 10, 10, 10));
      final b = PendingAlert.decode(a.encode())!;
      expect((b.freezerId, b.full, b.when), (3, false, DateTime(2026, 10, 10, 10)));
      expect(b.notificationId, a.notificationId);
      expect(PendingAlert.decode('rotto'), isNull);
    });
  });

  group('FreezerScheduler.evaluateCapacity', () {
    late AppDatabase db;
    late FreezerRepository repo;
    late SettingsStore settings;
    final now = DateTime(2026, 10, 7, 19);

    setUp(() async {
      // Gli avvisi partono spenti: qui si accendono, come farebbe l'utente.
      SharedPreferences.setMockInitialValues(<String, Object>{'ff_test.${SettingKeys.notificationsEnabled}': true});
      settings = await SettingsStore.create(namespace: 'ff_test');
      db = AppDatabase.memory();
      repo = FreezerRepository(db, clock: () => now);
    });
    tearDown(() => db.close());

    FreezerScheduler scheduler({required bool pro}) => FreezerScheduler(
      repo: repo,
      settings: settings,
      gate: FeatureGate(limits: freezerFeatureLimits, isPro: pro),
      l: lookupL(const Locale('it')),
      clock: () => now,
    );

    Future<void> riempi(int freezer, double litri) => repo.addItem(
      NewItem(
        name: 'X',
        freezerId: freezer,
        quantity: 1,
        unit: Units.portions,
        frozenAt: CivilDate(2026, 10, 1),
        volumeLiters: litri,
      ),
    );

    test('oltre l 85% con il Pro: un avviso "quasi pieno" in coda', () async {
      final f = await repo.addFreezer(name: 'Cucina', modelKey: 'custom', capacityLiters: 100);
      await riempi(f, 70); // 70 su 80 utili = 87,5%
      await scheduler(pro: true).evaluateCapacity();
      expect((await repo.freezerById(f))!.lastAlertLevel, AlertLevel.full);
      final coda = settings.getStringList(NotificationSettingKeys.pendingAlerts);
      expect(coda, hasLength(1));
      expect(PendingAlert.decode(coda.single)!.full, isTrue);
    });

    test('senza Pro nessun avviso, ma lo stato dell isteresi si aggiorna', () async {
      final f = await repo.addFreezer(name: 'Cucina', modelKey: 'custom', capacityLiters: 100);
      await riempi(f, 70);
      await scheduler(pro: false).evaluateCapacity();
      expect((await repo.freezerById(f))!.lastAlertLevel, AlertLevel.full);
      expect(settings.getStringList(NotificationSettingKeys.pendingAlerts), isEmpty);
    });

    test('"quasi pieno" cita il piu vecchio del freezer', () async {
      final f = await repo.addFreezer(name: 'Cucina', modelKey: 'custom', capacityLiters: 100);
      await riempi(f, 70);
      await repo.addItem(
        NewItem(
          name: 'Spezzatino',
          freezerId: f,
          quantity: 1,
          unit: Units.portions,
          frozenAt: CivilDate(2026, 5, 23),
          volumeLiters: 1,
        ),
      );
      final body = scheduler(pro: true).capacityAlertBody(full: true, percent: 89, items: await repo.storedItems());
      expect(body, 'È pieno al 89%: prima di congelare altro, comincia da Spezzatino, il più vecchio.');
    });

    test('il riepilogo aggiunge una riga per i freezer pieni o quasi vuoti, non per quelli vuoti', () async {
      final pieno = await repo.addFreezer(name: 'Cucina', modelKey: 'custom', capacityLiters: 100);
      final scarso = await repo.addFreezer(name: 'Garage', modelKey: 'custom', capacityLiters: 100);
      await repo.addFreezer(name: 'Cantina', modelKey: 'custom', capacityLiters: 100);
      await repo.addFreezer(name: 'Mezzo', modelKey: 'custom', capacityLiters: 100);
      await riempi(pieno, 70);
      await riempi(scarso, 2);
      final mezzo = (await repo.allFreezers()).last.id;
      await riempi(mezzo, 40);
      final righe = scheduler(pro: true).digestCapacityLines(await repo.allFreezers(), await repo.storedItems());
      expect(righe, ['Cucina è pieno al 88%.', 'Garage è pieno solo al 3%.']);
    });

    test('un freezer nuovo e vuoto non manda "quasi vuoto"', () async {
      final f = await repo.addFreezer(name: 'Cucina', modelKey: 'custom', capacityLiters: 100);
      await riempi(f, 1);
      await scheduler(pro: true).evaluateCapacity();
      expect(settings.getStringList(NotificationSettingKeys.pendingAlerts), isEmpty);
    });
  });
}

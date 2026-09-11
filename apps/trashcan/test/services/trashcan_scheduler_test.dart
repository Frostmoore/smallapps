import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashcan/app/feature_limits.dart';
import 'package:trashcan/data/database.dart';
import 'package:trashcan/data/repository.dart';
import 'package:trashcan/services/trashcan_scheduler.dart';

/// Il piano delle notifiche.
///
/// ⚑ Perché tanti test su una cosa che "manda solo un avviso": una notifica sbagliata non
/// dà nessun segnale di errore. Se arriva la mattina della raccolta invece della sera
/// prima, o se non arriva affatto, l'utente non vede un crash: vede il camion che passa e
/// il bidone in casa. È l'unico difetto di quest'app che si paga fuori dallo schermo, e
/// l'unico modo di accorgersene prima è verificare il piano qui.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late TrashcanRepository repo;
  late SettingsStore settings;

  setUp(() async {
    db = AppDatabase.memory();
    repo = TrashcanRepository(db);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    settings = await SettingsStore.create(namespace: 'trashcan_test');
  });
  tearDown(() => db.close());

  /// Il pianificatore con un cancello dato.
  ///
  /// ⛑ Il default e' **Pro**, non gratuito: dal 2026-09-11 i promemoria sono tutti dietro
  /// il paywall, quindi con un cancello gratuito ogni test sul contenuto del piano
  /// verificherebbe soltanto che il piano e' vuoto. Il caso gratuito ha un test suo, qui
  /// sotto, che e' il posto giusto per fissarlo.
  TrashcanScheduler schedulerWith({FeatureGate? gate}) => TrashcanScheduler(
    db: db,
    settings: settings,
    gate: gate ?? const FeatureGate.unlimited(),
    appName: 'TrashCan',
  );

  /// Il cancello del piano gratuito vero.
  const free = FeatureGate(limits: trashcanFeatureLimits, isPro: false);

  /// Un cancello che concede i promemoria ma non il secondo orario: serve a dimostrare che
  /// le due chiavi sono indipendenti, cosa che il piano gratuito da solo non mostrerebbe
  /// perche' li nega entrambi.
  const singleReminder = FeatureGate(
    limits: <FeatureKey, FeatureLimit>{
      FeatureKey.notifications: FeatureLimit.open(),
      FeatureKey.multipleNotifications: FeatureLimit.locked(),
    },
    isPro: false,
  );

  /// Un calendario con un tipo di rifiuto raccolto nei giorni indicati.
  Future<int> seedCalendar({
    String name = 'Casa',
    String typeName = 'Organico',
    Set<int> weekdays = const {DateTime.tuesday},
    String time = '20:00',
    String? secondTime,
  }) async {
    final calendarId = await repo.createCalendar(name: name, notificationTime: time);
    if (secondTime != null) {
      await repo.setCalendarNotification(calendarId, time: time, secondTime: secondTime);
    }
    final typeId = await repo.createWasteType(
      calendarId: calendarId,
      name: typeName,
      iconKey: 'compost',
      colorValue: 0xFF6D8B3C,
    );
    await repo.setWeeklyRule(wasteTypeId: typeId, weekdays: weekdays);
    return calendarId;
  }

  // Martedi' 15 settembre 2026. Le raccolte del martedi' hanno il promemoria il lunedi'.
  final monday = CivilDate(2026, 9, 14);
  final morning = DateTime(2026, 9, 14, 8);

  test('nel piano gratuito non si pianifica nessun promemoria', () async {
    // ☠ Il controllo sta nel pianificatore e non solo nell'interfaccia: una notifica gia'
    // consegnata ad Android sopravvive alla perdita del diritto, e senza questo un rimborso
    // lascerebbe arrivare promemoria per i sessanta giorni successivi.
    await seedCalendar();
    final plan = await schedulerWith(gate: free).computeSchedule(today: monday, now: morning);
    expect(plan, isEmpty);
  });

  test('il promemoria arriva la sera prima della raccolta, all-orario del calendario', () async {
    await seedCalendar();
    final plan = await schedulerWith().computeSchedule(today: monday, now: morning);

    expect(plan, isNotEmpty);
    final first = plan.first;
    // Raccolta martedi' 15, promemoria lunedi' 14 alle 20:00.
    expect(first.localWhen, DateTime(2026, 9, 14, 20));
    expect(first.body, contains('Organico'));
  });

  test('piu-tipi lo stesso giorno danno UNA notifica che li elenca tutti', () async {
    final calendarId = await seedCalendar();
    final second = await repo.createWasteType(
      calendarId: calendarId,
      name: 'Carta',
      iconKey: 'paper',
      colorValue: 0xFF2E6DA4,
    );
    await repo.setWeeklyRule(wasteTypeId: second, weekdays: {DateTime.tuesday});

    final plan = await schedulerWith().computeSchedule(today: monday, now: morning);
    final forThatEvening = plan.where((n) => n.localWhen == DateTime(2026, 9, 14, 20)).toList();

    // Due notifiche identiche a un minuto di distanza sono il modo piu' rapido per farsi
    // silenziare: deve restarne una sola, con tutti e due i nomi.
    expect(forThatEvening, hasLength(1));
    expect(forThatEvening.single.body, contains('Organico'));
    expect(forThatEvening.single.body, contains('Carta'));
  });

  test('un tipo con i promemoria spenti non compare', () async {
    final calendarId = await seedCalendar();
    final quiet = await repo.createWasteType(
      calendarId: calendarId,
      name: 'Vetro',
      iconKey: 'glass',
      colorValue: 0xFF3B7A6B,
    );
    await repo.setWeeklyRule(wasteTypeId: quiet, weekdays: {DateTime.thursday});
    await repo.updateWasteType(quiet, notificationsEnabled: false);

    final plan = await schedulerWith().computeSchedule(today: monday, now: morning);
    expect(plan.every((n) => !n.body.contains('Vetro')), isTrue);
  });

  test('un calendario disattivato non produce niente', () async {
    final calendarId = await seedCalendar();
    await repo.setCalendarNotification(calendarId, time: '20:00', enabled: false);

    final plan = await schedulerWith().computeSchedule(today: monday, now: morning);
    expect(plan, isEmpty);
  });

  test('una raccolta saltata non genera il promemoria', () async {
    final calendarId = await seedCalendar();
    final bundle = await db.loadBundle(calendarId);
    final typeId = bundle!.wasteTypes.single.id;
    await repo.skipCollection(wasteTypeId: typeId, date: CivilDate(2026, 9, 15));

    final plan = await schedulerWith().computeSchedule(today: monday, now: morning);
    expect(
      plan.where((n) => n.localWhen == DateTime(2026, 9, 14, 20)),
      isEmpty,
      reason: 'la raccolta del 15 e saltata: nessun promemoria il 14',
    );
  });

  test('un promemoria gia- passato non si pianifica', () async {
    await seedCalendar();
    // Sono le 22:00 di lunedi': le 20:00 di stasera sono passate.
    final plan = await schedulerWith().computeSchedule(
      today: monday,
      now: DateTime(2026, 9, 14, 22),
    );
    expect(plan.every((n) => n.localWhen.isAfter(DateTime(2026, 9, 14, 22))), isTrue);
  });

  test('senza il diritto ai promemoria multipli il secondo orario viene ignorato', () async {
    await seedCalendar(time: '18:00', secondTime: '21:00');

    final plan = await schedulerWith(gate: singleReminder).computeSchedule(
      today: monday,
      now: morning,
    );
    final thatEvening = plan.where((n) => n.localWhen.day == 14).toList();
    expect(thatEvening, hasLength(1));
    expect(thatEvening.single.localWhen, DateTime(2026, 9, 14, 18));
  });

  test('col Pro il secondo orario viene pianificato, in ordine di ora', () async {
    await seedCalendar(time: '21:00', secondTime: '18:00');

    final pro = await schedulerWith().computeSchedule(today: monday, now: morning);
    final thatEvening = pro.where((n) => n.localWhen.day == 14).toList()
      ..sort((a, b) => a.localWhen.compareTo(b.localWhen));
    expect(thatEvening, hasLength(2));
    expect(thatEvening.first.localWhen, DateTime(2026, 9, 14, 18));
    expect(thatEvening.last.localWhen, DateTime(2026, 9, 14, 21));
  });

  test('il piano non supera mai il limite di Android ed e- ordinato', () async {
    // Raccolta tutti i giorni per 60 giorni: 60 promemoria, sotto il limite. Con due
    // calendari si superano le 64 e la troncatura deve intervenire.
    await seedCalendar(name: 'Casa', weekdays: {for (var d = 1; d <= 7; d++) d});
    await seedCalendar(name: 'Mare', typeName: 'Indifferenziato', weekdays: {
      for (var d = 1; d <= 7; d++) d,
    });

    final plan = await schedulerWith().computeSchedule(today: monday, now: morning);
    expect(plan.length, TrashcanScheduler.maxScheduled);
    for (var i = 1; i < plan.length; i++) {
      expect(
        plan[i].localWhen.isBefore(plan[i - 1].localWhen),
        isFalse,
        reason: 'il piano deve essere ordinato: la troncatura taglia le piu lontane',
      );
    }
  });

  test('col secondo calendario il titolo diventa il nome del calendario', () async {
    await seedCalendar(name: 'Casa');
    final single = await schedulerWith().computeSchedule(today: monday, now: morning);
    expect(single.first.title, 'TrashCan');

    await seedCalendar(name: 'Casa al mare', typeName: 'Indifferenziato');
    final many = await schedulerWith().computeSchedule(today: monday, now: morning);
    expect(many.map((n) => n.title), contains('Casa al mare'));
  });

  test('gli id sono stabili tra due calcoli successivi', () async {
    await seedCalendar();
    final first = await schedulerWith().computeSchedule(today: monday, now: morning);
    final second = await schedulerWith().computeSchedule(today: monday, now: morning);

    // ☠ Se gli id cambiassero, replaceSchedule aggiungerebbe invece di sovrascrivere e la
    // stessa notifica arriverebbe piu' volte. Vedi NotificationIds.forOccurrence.
    expect(first.map((n) => n.id).toList(), second.map((n) => n.id).toList());
  });

  test('il payload e- il percorso interno con il calendario', () async {
    final calendarId = await seedCalendar();
    final plan = await schedulerWith().computeSchedule(today: monday, now: morning);
    expect(plan.first.payload, '/day/2026-09-15?calendar=$calendarId');
  });

  group('parseTime', () {
    test('accetta un orario valido', () {
      expect(parseTime('07:05'), const TimeOfDay(hour: 7, minute: 5));
    });

    test('rifiuta le stringhe storte invece di lanciare', () {
      // L'orario arriva dal database e puo' venire da un import: deve far ripiegare sul
      // default, non impedire la pianificazione di tutte le notifiche dell'app.
      for (final bad in ['', '25:00', '10:70', 'venti', '20', '20:00:00', null]) {
        expect(parseTime(bad), isNull, reason: 'parseTime($bad)');
      }
    });

    test('formatTime e- l-inverso', () {
      expect(formatTime(const TimeOfDay(hour: 9, minute: 0)), '09:00');
      expect(parseTime(formatTime(const TimeOfDay(hour: 23, minute: 59))),
          const TimeOfDay(hour: 23, minute: 59));
    });
  });
}

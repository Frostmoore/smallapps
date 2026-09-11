import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

import '../app/locale_resolution.dart';
import '../app/routes.dart';
import '../data/database.dart';
import '../domain/occurrence_engine.dart';
import '../l10n/generated/app_localizations.dart';

/// Il canale Android delle notifiche di TrashCan.
///
/// ⚑ Un canale solo: su Android l'utente può silenziare i canali singolarmente, e
/// spezzare i promemoria in più canali significa offrire un modo per silenziarne metà
/// senza accorgersene. L'unica cosa che questa app notifica è "domani raccolgono X".
const MicroNotificationChannel trashcanChannel = MicroNotificationChannel(
  id: 'trashcan_reminders',
  name: 'Collection reminders',
  description: 'Evening reminder the day before a collection',
  importance: MicroImportance.high,
);

/// Costruisce il piano delle notifiche di TrashCan e lo consegna al sistema.
///
/// ⚑ Perché il calcolo è separato dalla consegna ([computeSchedule] non tocca il plugin):
/// il piano è la parte che può sbagliare in modo silenzioso e costoso, cioè una notifica
/// alla sera sbagliata o mancante, e va testato senza un dispositivo. Il plugin invece è
/// una consegna meccanica di una lista già decisa.
class TrashcanScheduler implements NotificationScheduler {
  TrashcanScheduler({
    required this.db,
    required this.settings,
    required this.gate,
    required this.appName,
    this.notifications,
  });

  final AppDatabase db;
  final SettingsStore settings;
  final FeatureGate gate;
  final String appName;

  /// `null` nei test e finché il servizio non è pronto: il calcolo funziona lo stesso, e
  /// [rescheduleAll] semplicemente non ha nessuno a cui consegnare.
  final NotificationService? notifications;

  /// Quanto lontano si guarda. Sessanta giorni con raccolte quotidiane fanno già più delle
  /// 64 notifiche che Android accetta: allungare l'orizzonte non aggiungerebbe niente.
  static const int horizonDays = 60;

  /// Il limite di Android alle notifiche in attesa per applicazione.
  static const int maxScheduled = 64;

  static const OccurrenceEngine _engine = OccurrenceEngine();

  /// `true` quando c'e' un servizio a cui consegnare il piano.
  bool get isReady => notifications != null;

  @override
  Future<void> cancelAll() async {
    await notifications?.cancelAll();
    await settings.remove(SettingKeys.lastRescheduleAt);
  }

  /// `true` se il piano dell'utente comprende i promemoria.
  ///
  /// ☠ Il controllo sta **qui**, nel punto in cui il piano viene consegnato ad Android, e
  /// non solo nella pagina delle impostazioni. Una notifica gia' pianificata sopravvive
  /// alla scadenza del diritto: se si gating-asse solo l'interfaccia, chi compra, si fa
  /// rimborsare e poi disinstalla la pagina continuerebbe a ricevere promemoria per i
  /// sessanta giorni successivi.
  bool get _allowed => gate.allows(FeatureKey.notifications);

  @override
  Future<void> rescheduleAll() async {
    final service = notifications;
    if (service == null) return;
    if (!_allowed || !settings.getBool(SettingKeys.notificationsEnabled, orElse: true)) {
      await service.cancelAll();
      return;
    }
    final plan = await computeSchedule();
    final scheduled = await service.replaceSchedule(plan);
    MicroLog.d('notifiche ripianificate: $scheduled');
    await RescheduleGuard(settings).markRescheduled();
  }

  /// Ripianifica solo se è passato abbastanza tempo dall'ultima volta.
  ///
  /// È la variante da chiamare al ritorno in primo piano. Dopo una modifica ai dati si usa
  /// [rescheduleAll], che non guarda l'orologio: lì il piano è certamente cambiato.
  Future<void> rescheduleIfStale() async {
    if (!RescheduleGuard(settings).shouldReschedule()) return;
    await rescheduleAll();
  }

  /// Il piano completo, ordinato per istante e troncato a [maxScheduled].
  Future<List<ScheduledNotification>> computeSchedule({CivilDate? today, DateTime? now}) async {
    if (!_allowed) return const <ScheduledNotification>[];
    final base = today ?? CivilDate.today();
    final moment = now ?? DateTime.now();
    final l = lookupL(
      resolveAppLocale(WidgetsBinding.instance.platformDispatcher.locales, kSupportedLocales),
    );

    final calendars = await db.allCalendars();
    // Il nome del calendario va nel titolo solo se ce n'è più d'uno: con un calendario solo
    // sarebbe una parola in più su ogni notifica che non distingue niente.
    final showCalendarName = calendars.length > 1;

    final planned = <ScheduledNotification>[];

    for (final calendar in calendars) {
      if (!calendar.enabled) continue;
      final bundle = await db.loadBundle(calendar.id);
      if (bundle == null) continue;

      final silenced = <int>{
        for (final type in bundle.wasteTypes)
          if (!type.notificationsEnabled) type.id,
      };
      final rules = bundle.rules.where((r) => !silenced.contains(r.wasteTypeId)).toList();
      if (rules.isEmpty) continue;

      final occurrences = _engine.expand(
        rules: rules,
        from: base,
        to: base.addDays(horizonDays),
      );

      // Una notifica per giorno, non una per tipo: tre bidoni lo stesso martedì sono tre
      // notifiche identiche a un minuto di distanza, e l'utente le silenzia tutte.
      final byDate = <CivilDate, List<CollectionOccurrence>>{};
      for (final occurrence in occurrences) {
        (byDate[occurrence.date] ??= <CollectionOccurrence>[]).add(occurrence);
      }

      final times = timesFor(calendar);

      for (final entry in byDate.entries) {
        final names = <String>[
          for (final occurrence in entry.value)
            if (bundle.typeOf(occurrence.wasteTypeId)?.name case final name?) name,
        ];
        if (names.isEmpty) continue;

        // ⚑ Il promemoria arriva la sera **prima**: è quando si porta fuori il bidone.
        // Notificare la mattina della raccolta significa notificare a camion passato.
        final evening = entry.key.addDays(-1);

        for (var slot = 0; slot < times.length; slot++) {
          final when = evening.toLocalDateTime(times[slot].hour, times[slot].minute);
          // Le notifiche nel passato non si pianificano: il plugin le consegnerebbe
          // subito, e riaprire l'app di sera farebbe suonare il promemoria di stamattina.
          if (!when.isAfter(moment)) continue;

          planned.add(
            ScheduledNotification(
              id: NotificationIds.forOccurrence(calendar.id, entry.key, slot),
              localWhen: when,
              title: showCalendarName ? calendar.name : appName,
              body: l.notifications_body(names.join(', ')),
              channelId: trashcanChannel.id,
              // ⚑ Il payload è il percorso interno, non un URL con schema: chi riceve il
              // tocco lo passa dritto a go_router. Un secondo formato da tradurre sarebbe
              // un secondo posto in cui sbagliare, e il sintomo di un errore qui è una
              // notifica che si tocca e non porta da nessuna parte.
              payload: '${Routes.dayOf(entry.key.toIso())}?calendar=${calendar.id}',
              exact: true,
            ),
          );
        }
      }
    }

    planned.sort((a, b) => a.localWhen.compareTo(b.localWhen));
    return planned.take(maxScheduled).toList();
  }

  /// Gli orari di promemoria di un calendario.
  ///
  /// Nel piano gratuito uno solo. Col Pro anche il secondo, se impostato: chi ha figli
  /// piccoli mette 18:00 e 21:00 perché alle 18 è in piedi e alle 21 se n'è dimenticato.
  ///
  /// Il piano parlava di "fino a tre" orari: la tabella `collection_calendars` ne prevede
  /// due, e due coprono il caso reale. Aggiungere il terzo vuol dire una migrazione, e si
  /// farà solo se qualcuno lo chiede.
  List<TimeOfDay> timesFor(CollectionCalendar calendar) {
    final first = parseTime(calendar.notificationTime) ?? const TimeOfDay(hour: 20, minute: 0);
    if (!gate.allows(FeatureKey.multipleNotifications)) return [first];
    final second = parseTime(calendar.secondNotificationTime);
    if (second == null || second == first) return [first];
    return [first, second]..sort((a, b) => a.hour * 60 + a.minute - (b.hour * 60 + b.minute));
  }
}

/// `HH:mm` → [TimeOfDay], oppure `null` se la stringa non è un orario.
///
/// ⚑ Non lancia: l'orario arriva dal database e può essere stato scritto da un import o da
/// una versione futura. Un orario illeggibile deve far ripiegare sul default, non impedire
/// la pianificazione di tutte le notifiche dell'app.
TimeOfDay? parseTime(String? value) {
  if (value == null) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

/// [TimeOfDay] → `HH:mm`, la forma con cui l'orario sta in tabella.
String formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

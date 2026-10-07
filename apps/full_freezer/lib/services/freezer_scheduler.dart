import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import '../app/routes.dart';
import '../data/database.dart';
import '../data/freezer_repository.dart';
import '../domain/capacity.dart';
import '../l10n/generated/app_localizations.dart';
import 'notification_plan.dart';

/// Il canale delle notifiche di Full Freezer.
const MicroNotificationChannel freezerChannel = MicroNotificationChannel(
  id: 'freezer_alerts',
  name: 'Freezer alerts',
  description: "What's been in too long, and when the freezer is nearly full or empty",
);

/// Le preferenze delle notifiche.
abstract final class NotificationSettingKeys {
  static const String digestFrequency = 'digest_frequency';
  static const String pendingAlerts = 'pending_capacity_alerts';
}

/// Consegna il piano delle notifiche ad Android e iOS (develop_microapps.md F4.9).
///
/// ☠ Il controllo del Pro sta **qui**, dove il piano viene consegnato, e non solo nella
/// pagina delle impostazioni: una notifica gia' pianificata sopravvive alla fine del diritto
/// (rimborso), e controllando solo l'interfaccia continuerebbe ad arrivare per settimane.
/// Stessa trappola gia' disinnescata in TrashCan.
class FreezerScheduler implements NotificationScheduler {
  FreezerScheduler({
    required this.repo,
    required this.settings,
    required this.gate,
    required this.l,
    this.notifications,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FreezerRepository repo;
  final SettingsStore settings;
  final FeatureGate gate;
  final L l;

  /// `null` nei test e finche' il servizio non e' pronto.
  final NotificationService? notifications;
  final DateTime Function() _clock;

  static const CapacityAlertPolicy _policy = CapacityAlertPolicy();
  static const CapacityEstimator _capacity = CapacityEstimator();

  bool get isReady => notifications != null;

  /// Pro e interruttore acceso.
  bool get allowed =>
      gate.allows(FeatureKey.notifications) &&
      settings.getBool(SettingKeys.notificationsEnabled, orElse: false);

  DigestFrequency get frequency => switch (settings.getString(NotificationSettingKeys.digestFrequency)) {
    'biweekly' => DigestFrequency.biweekly,
    'monthly' => DigestFrequency.monthly,
    _ => DigestFrequency.weekly,
  };

  @override
  Future<void> cancelAll() async {
    await notifications?.cancelAll();
    await settings.remove(NotificationSettingKeys.pendingAlerts);
  }

  /// Valuta la capienza di ogni freezer dopo una modifica e, se una soglia e' stata
  /// attraversata, mette in coda l'avviso (develop_microapps.md F4.9, `CapacityAlertPolicy`).
  ///
  /// ⚑ `lastAlertLevel` si aggiorna **sempre**, anche senza Pro o con le notifiche spente:
  /// e' lo stato dell'isteresi. Se si aggiornasse solo con le notifiche attive, chi le accende
  /// con il freezer gia' pieno riceverebbe subito un "quasi pieno" vecchio di settimane.
  Future<void> evaluateCapacity() async {
    final now = _clock();
    final freezers = await repo.allFreezers();
    final stored = await repo.storedItems();
    final pending = _readPending();
    var changed = false;

    for (final f in freezers) {
      final mine = [for (final i in stored) if (i.freezerId == f.id) i];
      final fill = _capacity.fill(
        capacityLiters: f.capacityLiters,
        calibration: f.calibration,
        itemLiters: mine.map((i) => i.volumeLiters),
      );
      final decision = _policy.decide(fraction: fill.fraction, lastLevel: f.lastAlertLevel);
      if (decision.newLastLevel != f.lastAlertLevel) {
        await repo.setLastAlertLevel(f.id, decision.newLastLevel);
      }
      final send = decision.send;
      if (send == null || !allowed) continue;
      // Un avviso nuovo sostituisce quelli ancora in coda per lo stesso freezer: "quasi
      // vuoto" per sabato non ha piu' senso se nel frattempo il freezer si e' riempito.
      pending.removeWhere((a) => a.freezerId == f.id);
      pending.add(PendingAlert(freezerId: f.id, full: send == AlertLevel.full, when: alertTime(full: send == AlertLevel.full, now: now)));
      changed = true;
    }
    if (changed) await _writePending(pending);
  }

  /// Ricostruisce tutto il piano: riepiloghi e avvisi di capienza in coda.
  @override
  Future<void> rescheduleAll() async {
    final service = notifications;
    if (service == null) return;
    if (!allowed) {
      await cancelAll();
      return;
    }
    final now = _clock();
    final today = CivilDate.fromDateTime(now);
    final stored = await repo.storedItems();
    final freezers = {for (final f in await repo.allFreezers()) f.id: f};
    final capacityLines = digestCapacityLines(freezers.values, stored);

    final wanted = <ScheduledNotification>[];
    for (final day in digestDates(today, frequency)) {
      final content = digestFor(stored, day);
      if (content == null) continue;
      wanted.add(
        ScheduledNotification(
          id: digestId(day),
          localWhen: day.toLocalDateTime(digestHour),
          title: l.notif_digestTitle,
          body: [
            if (content.oldCount == 1)
              l.notif_digestOne(content.oldest, content.oldestDays)
            else
              l.notif_digestMany(content.oldCount, content.oldest, content.oldestDays),
            ...capacityLines,
          ].join(' '),
          channelId: freezerChannel.id,
          payload: Routes.useSoon,
        ),
      );
    }

    // Gli avvisi di capienza ancora futuri; quelli passati escono dalla coda.
    // Un minuto di tolleranza: un "quasi pieno" pianificato fra 10 secondi non deve sparire
    // perche' la ripianificazione arriva un attimo dopo.
    final pending = _readPending()..removeWhere((a) => a.when.isBefore(now.subtract(const Duration(minutes: 1))));
    for (final a in pending) {
      final f = freezers[a.freezerId];
      if (f == null) continue;
      final mine = [for (final i in stored) if (i.freezerId == f.id) i];
      final fill = _capacity.fill(
        capacityLiters: f.capacityLiters,
        calibration: f.calibration,
        itemLiters: mine.map((i) => i.volumeLiters),
      );
      wanted.add(
        ScheduledNotification(
          id: a.notificationId,
          localWhen: a.when,
          title: a.full ? l.notif_fullTitle(f.name) : l.notif_emptyTitle(f.name),
          body: capacityAlertBody(full: a.full, percent: fill.percent, items: mine),
          channelId: freezerChannel.id,
          payload: Routes.freezerOf(f.id),
        ),
      );
    }
    await _writePending(pending);
    await service.replaceSchedule(wanted);
    await settings.setInstant(SettingKeys.lastRescheduleAt, now.toUtc());
  }

  /// Il testo di un avviso di capienza. "Quasi pieno" cita il piu' vecchio del freezer
  /// (F4.9): "consuma qualcosa" non dice cosa, "comincia dallo spezzatino" si'.
  @visibleForTesting
  String capacityAlertBody({required bool full, required int percent, required List<Item> items}) {
    if (!full) return l.notif_emptyBody(percent);
    final oldest = ([...items]..sort((a, b) => a.frozenAt.compareTo(b.frozenAt))).firstOrNull;
    return oldest == null ? l.notif_fullBody(percent) : l.notif_fullBodyOldest(percent, oldest.name);
  }

  /// Le righe che il riepilogo aggiunge per ogni freezer pieno o quasi vuoto (F4.9).
  ///
  /// ⚑ Il riempimento e' quello di adesso, non quello del giorno del riepilogo: lo spazio
  /// cambia solo quando cambiano i dati, e ogni modifica ripianifica tutto.
  ///
  /// ⚑ Un freezer **senza niente dentro** non entra: "quasi vuoto" ogni settimana su un
  /// freezer appena creato sarebbe un rimprovero, non un'informazione (stessa ragione per
  /// cui `lastAlertLevel` parte da `empty`).
  @visibleForTesting
  List<String> digestCapacityLines(Iterable<Freezer> freezers, List<Item> stored) => [
    for (final f in freezers)
      if (stored.where((i) => i.freezerId == f.id).toList() case final mine when mine.isNotEmpty)
        if (_capacity.fill(
              capacityLiters: f.capacityLiters,
              calibration: f.calibration,
              itemLiters: mine.map((i) => i.volumeLiters),
            ) case final fill)
          if (fill.fraction >= _capacity.fullAt)
            l.notif_digestFull(f.name, fill.percent)
          else if (fill.fraction < _capacity.emptyAt)
            l.notif_digestEmpty(f.name, fill.percent),
  ];

  List<PendingAlert> _readPending() => [
    for (final raw in settings.getStringList(NotificationSettingKeys.pendingAlerts))
      if (PendingAlert.decode(raw) case final a?) a,
  ];

  Future<void> _writePending(List<PendingAlert> alerts) =>
      settings.setStringList(NotificationSettingKeys.pendingAlerts, [for (final a in alerts) a.encode()]);
}

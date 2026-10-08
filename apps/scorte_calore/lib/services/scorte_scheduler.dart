import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import '../app/labels.dart';
import '../app/routes.dart';
import '../data/database.dart';
import '../data/scorte_repository.dart';
import '../domain/consumption.dart';
import '../domain/fuel_units.dart';
import '../domain/reorder_plan.dart';
import '../l10n/generated/app_localizations.dart';

/// L'id del canale Android delle notifiche di riordino.
///
/// ☠ Non si cambia mai: Android lega al canale le scelte dell'utente (suono, silenzioso,
/// spento). Un id nuovo e' un canale nuovo, e chi aveva silenziato il vecchio si ritrova le
/// notifiche con il suono.
const String scorteChannelId = 'scorte_reorder';

/// Il canale delle notifiche di riordino, con nome e descrizione nella lingua del telefono.
///
/// ⚑ Una funzione e non una costante come in Full Freezer: il nome del canale si legge in
/// Impostazioni di sistema → Notifiche, e un "Reorder reminders" in un telefono italiano
/// e' un testo inglese che l'app mostra senza saperlo. Android aggiorna nome e descrizione
/// a ogni `createNotificationChannel` con lo stesso id, quindi cambiare lingua funziona.
MicroNotificationChannel scorteChannel(L l) => MicroNotificationChannel(
  id: scorteChannelId,
  name: l.notif_channelName,
  description: l.notif_channelDescription,
);

/// Consegna ad Android e iOS le notifiche di riordino e di superamento (develop_microapps.md
/// F5.8): per ogni fonte attiva, misure → stima → [ReorderPlanner.plan] → notifiche.
///
/// ☠ Il controllo del Pro sta **qui**, dove il piano viene consegnato, e non solo
/// nell'interruttore delle impostazioni: una notifica gia' pianificata sopravvive alla fine
/// del diritto (rimborso), e controllando solo l'interfaccia continuerebbe ad arrivare. Senza
/// Pro o con l'interruttore spento [rescheduleAll] cancella tutto. Stessa trappola gia'
/// disinnescata in TrashCan e Full Freezer.
///
/// ⚑ Tutto il piano si ricalcola da zero e si consegna con `replaceSchedule`, che cancella
/// le notifiche pendenti non piu' volute: una fonte eliminata o disattivata, o una stima
/// diventata insufficiente, non lasciano notifiche orfane, senza dover tenere traccia di
/// cosa era stato pianificato prima.
class ScorteScheduler implements NotificationScheduler {
  ScorteScheduler({
    required this.repo,
    required this.settings,
    required this.gate,
    required this.l,
    this.notifications,
    this.calculator = const ConsumptionCalculator(),
    this.planner = const ReorderPlanner(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ScorteRepository repo;
  final SettingsStore settings;
  final FeatureGate gate;

  /// Le traduzioni con cui si compongono i testi: le notifiche si scrivono fuori da ogni
  /// widget, quindi la lingua la sceglie chi crea lo scheduler (quella del telefono).
  final L l;

  /// `null` finche' il servizio non e' pronto (arriva dopo il primo frame).
  final NotificationService? notifications;

  final ConsumptionCalculator calculator;
  final ReorderPlanner planner;
  final DateTime Function() _clock;

  bool get isReady => notifications != null;

  /// Pro **e** interruttore acceso.
  ///
  /// ☠ L'interruttore parte spento (`orElse: false`): il permesso si chiede solo quando lo
  /// si accende (vedi `NotificationsEnabled` in `notification_providers.dart`).
  bool get allowed =>
      gate.allows(FeatureKey.notifications) &&
      settings.getBool(SettingKeys.notificationsEnabled, orElse: false);

  @override
  Future<void> cancelAll() async {
    await notifications?.cancelAll();
  }

  /// Ricalcola tutto il piano e lo sostituisce a quello pianificato.
  @override
  Future<void> rescheduleAll() async {
    final service = notifications;
    if (service == null) return;
    if (!allowed) {
      await cancelAll();
      return;
    }
    final now = _clock();
    await service.replaceSchedule(await buildSchedule(now: now));
    await settings.setInstant(SettingKeys.lastRescheduleAt, now.toUtc());
  }

  /// Le notifiche volute adesso, per tutte le fonti attive, gia' con i testi.
  ///
  /// Non controlla il Pro: lo fa [rescheduleAll]. Separato per i test e perche' il calcolo
  /// non tocca il servizio.
  @visibleForTesting
  Future<List<ScheduledNotification>> buildSchedule({DateTime? now}) async {
    final at = now ?? _clock();
    final today = CivilDate.fromDateTime(at);
    final out = <ScheduledNotification>[];
    for (final source in await repo.allSources(activeOnly: true)) {
      // ☠ Un id fuori dallo schema delle notifiche (`ReorderPlanner.maxSourceId`) fa lanciare
      // `notificationId`: si salta la fonte invece di perdere il piano di tutte le altre.
      if (source.id > ReorderPlanner.maxSourceId) continue;
      final spec = source.toSpec();
      final estimate = calculator.estimate(
        measurements: (await repo.allMeasurements(source.id)).toMeasurements(),
        source: spec,
        today: today,
      );
      // `plan` restituisce [] con la stima insufficiente: avvisare su una stima non
      // calcolabile e' peggio che tacere (F5.8).
      for (final p in planner.plan(source: spec, estimate: estimate, now: at)) {
        out.add(toScheduled(p));
      }
    }
    return out;
  }

  /// Una notifica del dominio diventa una notifica da consegnare, con i testi dagli ARB.
  ///
  /// ⚑ `exact: false` → `inexactAllowWhileIdle` (F5.8): un promemoria di riordino che arriva
  /// alle 10:12 invece che alle 10:00 non cambia niente, e il permesso degli alarm esatti
  /// Play lo contesta a chi non e' una sveglia.
  ///
  /// ⚑ Il payload e' la home: e' li' che si vede la stima e si aggiorna la scorta (lo
  /// storico per fonte esiste, ma per riordinare serve la stima, non le misure passate).
  @visibleForTesting
  ScheduledNotification toScheduled(PlannedNotification p) {
    final fuel = FuelType.byKey(p.fuelTypeKey);
    final fuelLabel = fuel == null ? p.fuelTypeKey : fuelName(l, fuel);
    final (title, body) = switch (p.kind) {
      ReorderNotificationKind.reorder => (
        l.notif_reorderTitle(p.sourceName),
        l.notif_reorderBody(fuelLabel, p.daysUntilDepletion, formatAmount(l, p.unitKey, p.projectedQuantity)),
      ),
      ReorderNotificationKind.overdue => (l.notif_overdueTitle(p.sourceName), l.notif_overdueBody(fuelLabel)),
    };
    return ScheduledNotification(
      id: p.id,
      localWhen: p.fireAt,
      title: title,
      body: body,
      channelId: scorteChannelId,
      payload: Routes.home,
    );
  }
}

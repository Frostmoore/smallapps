import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/trashcan_scheduler.dart';

/// Le impostazioni dei promemoria.
///
/// ⚑ Perché questa pagina spiega invece di limitarsi a chiedere: i due permessi che
/// servono (notifiche e orario esatto) sono entrambi rifiutabili, e un utente che rifiuta
/// senza capire cosa perde poi valuta l'app in base a promemoria che non arrivano. Ogni
/// richiesta qui dice cosa succede se si dice di no, e cosa continua a funzionare
/// comunque.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool? _permissionGranted;
  bool? _exactAllowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPermissions());
  }

  Future<void> _refreshPermissions() async {
    final service = await ref.read(notificationServiceProvider.future);
    final exact = await service.canScheduleExactAlarms();
    if (!mounted) return;
    setState(() => _exactAllowed = exact);
  }

  Future<void> _askPermission() async {
    final service = await ref.read(notificationServiceProvider.future);
    final outcome = await service.ensurePermission();
    if (!mounted) return;
    setState(
      () => _permissionGranted =
          outcome == PermissionOutcome.granted || outcome == PermissionOutcome.notRequired,
    );
    await ref.read(schedulerProvider).rescheduleAll();
  }

  Future<void> _askExact() async {
    final service = await ref.read(notificationServiceProvider.future);
    await service.requestExactAlarmPermission();
    // Il permesso si concede in una schermata di sistema: al ritorno si rilegge lo stato
    // invece di fidarsi del valore restituito, che dice solo "ho aperto le impostazioni".
    await _refreshPermissions();
    await ref.read(schedulerProvider).rescheduleAll();
  }

  Future<void> _pickTime({required bool second}) async {
    final calendar = ref.read(activeCalendarProvider);
    if (calendar == null) return;

    final gate = ref.read(featureGateProvider);
    if (second && !gate.allows(FeatureKey.multipleNotifications)) {
      await showTrashcanPaywall(context, ref, highlight: FeatureKey.multipleNotifications);
      return;
    }
    if (!mounted) return;

    final current = second
        ? parseTime(calendar.secondNotificationTime)
        : parseTime(calendar.notificationTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked == null) return;

    await ref
        .read(repositoryProvider)
        .setCalendarNotification(
          calendar.id,
          time: second ? calendar.notificationTime : formatTime(picked),
          secondTime: second ? formatTime(picked) : calendar.secondNotificationTime,
        );
  }

  Future<void> _clearSecond() async {
    final calendar = ref.read(activeCalendarProvider);
    if (calendar == null) return;
    await ref
        .read(repositoryProvider)
        .setCalendarNotification(calendar.id, time: calendar.notificationTime);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final enabled = ref.watch(notificationsEnabledProvider);
    final calendar = ref.watch(activeCalendarProvider);
    final gate = ref.watch(featureGateProvider);
    final second = parseTime(calendar?.secondNotificationTime);
    final allowed = gate.allows(FeatureKey.notifications);

    return Scaffold(
      appBar: AppBar(title: Text(l.notifications_title)),
      body: SafeArea(
        child: ListView(
          padding: MicroSpacing.page,
          children: [
            // ⛑ Senza il Pro la pagina non mostra un interruttore spento: mostra cosa si
            // compra e come. Un interruttore che non si muove insegna solo che l'app e'
            // rotta, e non dice dove andare.
            if (!allowed) ...[
              MicroCard(
                accent: Theme.of(context).colorScheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.paywall_benefitRemindersTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: MicroCard.foregroundOn(Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    MicroSpacing.gapS,
                    Text(
                      l.paywall_benefitRemindersBody,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MicroCard.foregroundOn(Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              MicroSpacing.gapL,
              MicroPrimaryButton(
                label: l.gate_seePro,
                onPressed: () => unawaited(
                  showTrashcanPaywall(context, ref, highlight: FeatureKey.notifications),
                ),
              ),
            ],

            if (allowed) ...
            [
            MicroCard(
              padding: MicroSpacing.cardTight,
              child: SwitchListTile(
                value: enabled,
                title: Text(l.notifications_enabledLabel),
                // La frase spiega **quando** arriva il promemoria. Il testo del permesso
                // ("senza notifiche l'app perde gran parte del suo senso") appartiene alla
                // richiesta del permesso, non a un interruttore gia' acceso: li' suona
                // come una minaccia.
                subtitle: Text(l.onboarding_notificationHelp),
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => ref.read(notificationsEnabledProvider.notifier).set(value),
              ),
            ),

            if (enabled) ...[
              if (_permissionGranted == false) ...[
                MicroSpacing.gapL,
                _WarningCard(
                  icon: Icons.notifications_off_outlined,
                  title: l.notifications_permissionTitle,
                  body: l.notifications_permissionBody,
                  actionLabel: l.common_retry,
                  onAction: _askPermission,
                ),
              ],

              // ⚑ L'avviso sull'orario esatto compare solo quando il permesso manca
              // davvero: mostrarlo sempre "per sicurezza" trasforma un'informazione utile
              // in rumore che si impara a ignorare.
              if (_exactAllowed == false) ...[
                MicroSpacing.gapL,
                _WarningCard(
                  icon: Icons.schedule_outlined,
                  title: l.notifications_exactAlarmTitle,
                  body: l.notifications_exactAlarmBody,
                  actionLabel: l.notifications_exactAlarmOpenSettings,
                  onAction: _askExact,
                ),
              ],

              MicroSpacing.gapXL,
              MicroSectionHeader(title: l.notifications_timeLabel),
              MicroCard(
                padding: EdgeInsets.zero,
                child: MicroListTile(
                  title: calendar?.notificationTime ?? '20:00',
                  leading: const Icon(Icons.schedule),
                  onTap: () => _pickTime(second: false),
                ),
              ),

              MicroSpacing.gapL,
              MicroCard(
                padding: EdgeInsets.zero,
                child: MicroListTile(
                  title: second == null ? l.notifications_secondTimeLabel : formatTime(second),
                  subtitle: l.paywall_benefitNotificationsBody,
                  leading: const Icon(Icons.more_time),
                  trailingText: gate.allows(FeatureKey.multipleNotifications)
                      ? (second == null ? null : l.common_delete)
                      : 'PRO',
                  onTap: () {
                    // Toccare la riga quando un secondo orario c'e' gia' lo toglie: e'
                    // l'unico modo di annullarlo, e un secondo bottone accanto sarebbe piu'
                    // ingombrante di quanto la funzione meriti.
                    unawaited(
                      second != null && gate.allows(FeatureKey.multipleNotifications)
                          ? _clearSecond()
                          : _pickTime(second: true),
                    );
                  },
                ),
              ),
            ],
            ],
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MicroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.error),
              MicroSpacing.hGapM,
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          MicroSpacing.gapM,
          Text(body, style: theme.textTheme.bodyMedium),
          MicroSpacing.gapM,
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}

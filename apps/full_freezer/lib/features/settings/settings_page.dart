import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/freezer_palette.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/freezer_widget.dart';
import '../common/ghiaccio.dart';
import '../freezers/freezer_actions.dart';
import '../freezers/freezer_widgets.dart';
import 'data_actions.dart';

/// Le impostazioni: il Pro, i freezer, gli avvisi, i numeri, i dati, l'acquisto, l'aspetto.
///
/// ⚑ La scheda del Pro sta in cima e si tocca tutta (non solo il pulsante): in TrashCan il
/// riquadro Pro delle impostazioni non rispondeva al tocco, e il proprietario l'ha trovato
/// rotto al primo giro (2026-10-06).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = FreezerPalette.of(context);
    final pro = ref.watch(isProProvider);
    final freezers = ref.watch(freezersProvider).value ?? const <Freezer>[];
    final items = ref.watch(storedItemsProvider).value ?? const <Item>[];
    final removed = ref.watch(removedItemsProvider).value ?? const <Item>[];
    final alertsOn = ref.watch(notificationsEnabledProvider);
    final frequency = ref.watch(digestFrequencyProvider);
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          _ProCard(pro: pro),
          GhiaccioSectionLabel(text: l.settings_freezers, padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
          for (final f in freezers)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GhiaccioTile(
                leading: FreezerSilhouette(iconKey: silhouetteKeyFor(f.modelKey), size: 26),
                title: f.name,
                subtitle: l.home_itemCount(items.where((i) => i.freezerId == f.id).length),
                trailing: Icon(Icons.chevron_right, color: p.inkMuted),
                onTap: () => context.push(Routes.freezerOf(f.id)),
              ),
            ),
          GhiaccioTile(
            leading: const Icon(Icons.add),
            title: l.home_addFreezer,
            // Il piano gratuito ne ha uno: lo si dice prima del tocco, non solo dopo.
            subtitle: pro || freezers.isEmpty ? null : l.settings_addFreezerPro,
            trailing: pro || freezers.isEmpty ? null : const ProBadge(),
            onTap: () => unawaited(openNewFreezer(context, ref)),
          ),
          GhiaccioSectionLabel(text: l.settings_alerts, padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
          GhiaccioTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: l.settings_alertsToggle,
            subtitle: l.settings_alertsBody,
            trailing: pro
                ? Switch(
                    value: alertsOn,
                    onChanged: (v) => unawaited(_setAlerts(context, ref, v)),
                  )
                : const ProBadge(),
            onTap: pro
                ? () => unawaited(_setAlerts(context, ref, !alertsOn))
                : () => unawaited(showFreezerPaywall(context, ref, highlight: FeatureKey.notifications)),
          ),
          if (pro && alertsOn) ...[
            const SizedBox(height: 6),
            GhiaccioTile(
              leading: const Icon(Icons.event_repeat_outlined),
              title: l.settings_frequency,
              subtitle: switch (frequency) {
                'biweekly' => l.freq_biweekly,
                'monthly' => l.freq_monthly,
                _ => l.freq_weekly,
              },
              trailing: Icon(Icons.chevron_right, color: p.inkMuted),
              onTap: () async {
                final picked = await showModalBottomSheet<String>(
                  context: context,
                  showDragHandle: true,
                  builder: (sheet) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final (key, label) in [
                          ('weekly', l.freq_weekly),
                          ('biweekly', l.freq_biweekly),
                          ('monthly', l.freq_monthly),
                        ])
                          ListTile(
                            title: Text(label),
                            trailing: key == frequency ? const Icon(Icons.check) : null,
                            onTap: () => Navigator.of(sheet).pop(key),
                          ),
                      ],
                    ),
                  ),
                );
                if (picked != null) await ref.read(digestFrequencyProvider.notifier).set(picked);
              },
            ),
          ],
          GhiaccioSectionLabel(text: l.settings_numbers, padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
          GhiaccioTile(
            leading: const Icon(Icons.insights_outlined),
            title: l.stats_title,
            // Senza Pro si dice quante uscite ci sono gia' (develop_microapps.md F4.7): il dato
            // l'utente l'ha gia' prodotto, il Pro glielo fa vedere.
            subtitle: pro ? l.stats_subtitle : l.stats_lockedSubtitle(removed.length),
            trailing: pro ? Icon(Icons.chevron_right, color: p.inkMuted) : const ProBadge(),
            onTap: () => unawaited(openProFeature(context, ref, FeatureKey.statistics, Routes.stats)),
          ),
          const SizedBox(height: 6),
          GhiaccioTile(
            leading: const Icon(Icons.history),
            title: l.history_title,
            subtitle: l.history_count(removed.length),
            trailing: pro ? Icon(Icons.chevron_right, color: p.inkMuted) : const ProBadge(),
            onTap: () => unawaited(openProFeature(context, ref, FeatureKey.fullHistory, Routes.history)),
          ),
          GhiaccioSectionLabel(text: l.settings_data, padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
          GhiaccioTile(
            leading: const Icon(Icons.label_outline),
            title: l.categories_title,
            subtitle: l.categories_settingsBody,
            trailing: pro ? Icon(Icons.chevron_right, color: p.inkMuted) : const ProBadge(),
            onTap: () => unawaited(openProFeature(context, ref, FeatureKey.customCategories, Routes.categories)),
          ),
          const SizedBox(height: 6),
          GhiaccioTile(
            leading: const Icon(Icons.table_view_outlined),
            title: l.csv_export,
            subtitle: l.csv_exportBody,
            trailing: pro ? null : const ProBadge(),
            onTap: () => unawaited(exportCsv(context, ref)),
          ),
          const SizedBox(height: 6),
          GhiaccioTile(
            leading: const Icon(Icons.save_alt),
            title: l.backup_create,
            subtitle: l.backup_createBody,
            trailing: pro ? null : const ProBadge(),
            onTap: () => unawaited(createBackup(context, ref)),
          ),
          const SizedBox(height: 6),
          // Il ripristino e' gratis: vedi restoreBackup in data_actions.dart.
          GhiaccioTile(
            leading: const Icon(Icons.settings_backup_restore),
            title: l.backup_restore,
            subtitle: l.backup_restoreBody,
            onTap: () => unawaited(restoreBackup(context, ref)),
          ),
          GhiaccioSectionLabel(text: l.settings_purchase, padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
          GhiaccioTile(
            leading: const Icon(Icons.restore),
            title: l.paywall_restore,
            subtitle: defaultTargetPlatform == TargetPlatform.iOS ? l.settings_restoreApple : l.settings_restoreGoogle,
            onTap: () async {
              final service = ref.read(entitlementProvider.notifier).service;
              final result = await service.restorePurchases();
              if (!context.mounted) return;
              result.fold(
                ok: (_) => MicroSnack.show(context, service.isPro ? l.paywall_thanks : l.paywall_restoredNothing),
                err: (error) => MicroSnack.error(context, error.message),
              );
            },
          ),
          // ⚑ Solo dove il widget esiste (lezione di TrashCan: mostrarla e poi dire "non
          // supportato" al tocco fa sembrare l'app difettosa).
          if (FreezerWidget.available) ...[
            const SizedBox(height: 6),
            GhiaccioTile(
              leading: const Icon(Icons.widgets_outlined),
              title: l.widget_addTitle,
              subtitle: l.widget_addBody,
              onTap: () => unawaited(_pinWidget(context, l)),
            ),
          ],
          GhiaccioSectionLabel(text: l.settings_appearance, padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
          GhiaccioTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: l.settings_theme,
            subtitle: switch (mode) {
              ThemeMode.light => l.theme_light,
              ThemeMode.dark => l.theme_dark,
              ThemeMode.system => l.theme_system,
            },
            trailing: Icon(Icons.chevron_right, color: p.inkMuted),
            onTap: () async {
              final picked = await showModalBottomSheet<ThemeMode>(
                context: context,
                showDragHandle: true,
                builder: (sheet) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (m, label) in [
                        (ThemeMode.system, l.theme_system),
                        (ThemeMode.light, l.theme_light),
                        (ThemeMode.dark, l.theme_dark),
                      ])
                        ListTile(
                          title: Text(label),
                          trailing: m == mode ? const Icon(Icons.check) : null,
                          onTap: () => Navigator.of(sheet).pop(m),
                        ),
                    ],
                  ),
                ),
              );
              if (picked != null) await ref.read(themeModeProvider.notifier).set(picked);
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              l.settings_version(appVersion),
              style: TextStyle(color: p.inkMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accende o spegne gli avvisi. Accendendoli si chiede il permesso: e' il momento in cui
/// l'utente ha un motivo per dire di si' (non al primo avvio, quando un no e' definitivo).
Future<void> _setAlerts(BuildContext context, WidgetRef ref, bool on) async {
  final l = L.of(context);
  if (on) {
    final service = await ref.read(notificationServiceProvider.future);
    final outcome = await service.ensurePermission();
    if (outcome == PermissionOutcome.denied || outcome == PermissionOutcome.permanentlyDenied) {
      if (context.mounted) MicroSnack.error(context, l.settings_alertsDenied);
      return;
    }
  }
  await ref.read(notificationsEnabledProvider.notifier).set(on);
  if (on) {
    // Subito la valutazione della capienza: chi accende gli avvisi con il freezer quasi pieno
    // deve saperlo adesso, non alla prossima modifica.
    await ref.read(schedulerProvider).evaluateCapacity();
    await ref.read(schedulerProvider).rescheduleAll();
  }
}

/// Chiede al launcher di aggiungere il widget; su iPhone spiega i gesti (non c'e' un'API).
Future<void> _pinWidget(BuildContext context, L l) async {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    MicroSnack.show(context, l.widget_addIos);
    return;
  }
  final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
  if (!context.mounted) return;
  if (!supported) {
    MicroSnack.show(context, l.widget_addUnsupported);
    return;
  }
  await HomeWidget.requestPinWidget(qualifiedAndroidName: FreezerWidget.androidName);
}

/// La scheda del Pro, blu notte come la testata.
class _ProCard extends ConsumerWidget {
  const _ProCard({required this.pro});

  final bool pro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = FreezerPalette.of(context);
    return Material(
      color: p.night,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: pro ? null : () => unawaited(showFreezerPaywall(context, ref)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(pro ? Icons.verified : Icons.ac_unit, color: p.ice, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pro ? l.pro_activeTitle : l.paywall_headline,
                      style: TextStyle(color: p.onNight, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pro ? l.paywall_thanks : l.pro_ctaBody,
                      style: TextStyle(color: p.onNightMuted, fontSize: 14, height: 1.35),
                    ),
                  ],
                ),
              ),
              if (!pro) Icon(Icons.chevron_right, color: p.onNight),
            ],
          ),
        ),
      ),
    );
  }
}

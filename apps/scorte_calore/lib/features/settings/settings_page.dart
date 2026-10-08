import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/scorte_widget.dart';
import 'data_section.dart';
import 'notifications_section.dart';

/// Le impostazioni: il Pro, le notifiche, il widget, i dati, il ripristino dell'acquisto, il
/// tema.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final pro = ref.watch(isProProvider);
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.settings_title)),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          // ⚑ La riga del Pro risponde al tocco su tutta la sua superficie: in TrashCan il
          // riquadro non rispondeva e il proprietario l'ha trovato rotto.
          ListTile(
            leading: Icon(pro ? Icons.verified : Icons.local_fire_department_outlined),
            title: Text(pro ? l.settings_proActive : l.settings_proCta),
            subtitle: pro ? Text(l.paywall_thanks) : null,
            trailing: pro ? null : const ProBadge(),
            onTap: pro ? null : () => unawaited(showScortePaywall(context, ref)),
          ),
          // ⚑ Ogni parte dell'app aggiunge la sua sezione con UNA riga qui, scritta in un file
          // suo (features/settings/*_section.dart): notifiche, calendario, dati, widget.
          const Divider(),
          const NotificationsSection(),
          if (ScorteWidget.available)
            ListTile(
              leading: const Icon(Icons.widgets_outlined),
              title: Text(l.widget_addTitle),
              subtitle: Text(l.widget_addBody),
              onTap: () => unawaited(_pinWidget(context, l)),
            ),
          const DataSection(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(l.paywall_restore),
            subtitle:
                Text(defaultTargetPlatform == TargetPlatform.iOS ? l.settings_restoreApple : l.settings_restoreGoogle),
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
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: Text(l.settings_theme),
            subtitle: Text(switch (mode) {
              ThemeMode.light => l.theme_light,
              ThemeMode.dark => l.theme_dark,
              ThemeMode.system => l.theme_system,
            }),
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
          MicroSpacing.gapXL,
          Center(child: Text(l.settings_version(appVersion), style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// Su Android chiede al launcher di aggiungere il widget; dove non si puo' (iOS, launcher
/// vecchi) spiega come farlo a mano. Il widget e' gratuito (ADR-019).
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
  await HomeWidget.requestPinWidget(qualifiedAndroidName: ScorteWidget.androidName);
}

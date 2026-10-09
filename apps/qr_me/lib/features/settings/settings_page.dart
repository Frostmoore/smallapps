import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/neon.dart';
import '../common/qr_actions.dart';
import 'data_section.dart';

/// Le impostazioni (develop_microapps.md F17.1.6): cronologia, Pro, dati, tema, informazioni,
/// informativa privacy.
///
/// ⚑ La cronologia **per prima**: dentro ci finiscono password del Wi-Fi e testi privati, e chi
/// condivide cose riservate deve trovare subito come spegnerla (F17.0 punto 7).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final pro = ref.watch(isProProvider);
    final mode = ref.watch(themeModeProvider);
    final historyOn = ref.watch(historyEnabledProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.settings_title)),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          SectionLabel(l.history_title),
          SwitchListTile(
            key: const ValueKey('settings_history'),
            secondary: const Icon(Icons.history),
            title: Text(l.settings_historyOn),
            subtitle: Text(l.settings_historyBody),
            value: historyOn,
            onChanged: (v) => unawaited(ref.read(historyEnabledProvider.notifier).set(v)),
          ),
          ListTile(
            key: const ValueKey('settings_clearHistory'),
            leading: const Icon(Icons.delete_sweep_outlined),
            title: Text(l.history_clear),
            onTap: () async {
              final ok = await MicroConfirmSheet.show(
                context,
                title: l.history_clearTitle,
                message: l.history_clearBody,
                confirmLabel: l.history_clear,
                cancelLabel: l.common_cancel,
                destructive: true,
              );
              if (!ok) return;
              await ref.read(repositoryProvider).clearHistory();
              if (context.mounted) MicroSnack.success(context, l.history_cleared);
            },
          ),
          SectionLabel(l.settings_proLabel),
          // ⚑ La riga del Pro risponde al tocco su tutta la sua superficie (lezione di TrashCan).
          ListTile(
            leading: Icon(pro ? Icons.verified : Icons.workspace_premium_outlined),
            title: Text(pro ? l.settings_proActive : l.settings_proCta),
            subtitle: pro ? Text(l.paywall_thanks) : null,
            trailing: pro ? null : const ProBadge(),
            onTap: pro ? null : () => unawaited(showQrPaywall(context, ref)),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(l.paywall_restore),
            subtitle: Text(
              defaultTargetPlatform == TargetPlatform.iOS
                  ? l.settings_restoreApple
                  : l.settings_restoreGoogle,
            ),
            onTap: () async {
              final service = ref.read(entitlementProvider.notifier).service;
              final result = await service.restorePurchases();
              if (!context.mounted) return;
              result.fold(
                ok: (_) => MicroSnack.show(
                  context,
                  service.isPro ? l.paywall_thanks : l.paywall_restoredNothing,
                ),
                err: (error) => MicroSnack.error(context, error.message),
              );
            },
          ),
          // La scheda «Io» del modulo Contatto (F17.10 punto 2): modificabile anche da qui.
          SectionLabel(l.home_formsLabel),
          ListTile(
            key: const ValueKey('settings_myContact'),
            leading: const Icon(Icons.badge_outlined),
            title: Text(l.myContact_title),
            subtitle: Text(switch (ref.watch(myContactProvider)) {
              final me? => me.name,
              null => l.myContact_none,
            }),
            trailing: pro ? null : const ProBadge(),
            onTap: () => unawaited(openMyContact(context, ref)),
          ),
          const DataSection(),
          SectionLabel(l.settings_appLabel),
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
                        (ThemeMode.dark, l.theme_dark),
                        (ThemeMode.light, l.theme_light),
                        (ThemeMode.system, l.theme_system),
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
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l.settings_privacy),
            onTap: () => unawaited(_info(context, l.settings_privacy, l.settings_privacyBody)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.settings_about),
            subtitle: Text(l.settings_version(appVersion)),
            onTap: () => unawaited(_info(context, l.appTitle, l.settings_aboutBody)),
          ),
        ],
      ),
    );
  }

  static Future<void> _info(BuildContext context, String title, String body) => showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(body)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: Text(L.of(dialog).common_close),
        ),
      ],
    ),
  );
}

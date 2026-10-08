import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../photos/photo_storage_tile.dart';
import 'data_section.dart';

/// Le impostazioni: il Pro, il ripristino dell'acquisto, il tema, "I tuoi dati" (statistiche,
/// PDF, CSV, backup e ripristino, F6.10-F6.11) e lo spazio occupato dalle foto (F6.9).
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
          // ⚑ La riga del Pro risponde al tocco su tutta la sua superficie (lezione di TrashCan).
          ListTile(
            leading: Icon(pro ? Icons.verified : Icons.camera_roll_outlined),
            title: Text(pro ? l.settings_proActive : l.settings_proCta),
            subtitle: pro ? Text(l.paywall_thanks) : null,
            trailing: pro ? null : const ProBadge(),
            onTap: pro ? null : () => unawaited(showFilmPaywall(context, ref)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(l.paywall_restore),
            subtitle: Text(defaultTargetPlatform == TargetPlatform.iOS ? l.settings_restoreApple : l.settings_restoreGoogle),
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
          const Divider(),
          // Statistiche, PDF dell'anno, CSV, backup e ripristino (F6.10, F6.11).
          const DataSection(),
          // Lo spazio occupato dalle foto e "libera spazio" (F6.9).
          const PhotoStorageTile(),
          MicroSpacing.gapXL,
          Center(child: Text(l.settings_version(appVersion), style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final mode = ref.watch(themeModeProvider);
    final entitlement = ref.watch(entitlementProvider);
    final installId = ref.watch(installIdProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings_title)),
      body: SafeArea(
        child: ListView(
          padding: MicroSpacing.page,
          children: [
            MicroSectionHeader(title: l.settings_appearance),
            MicroCard(
              padding: MicroSpacing.cardTight,
              // RadioGroup e' la forma nuova: groupValue e onChanged sui singoli
              // RadioListTile sono deprecati da Flutter 3.32.
              child: RadioGroup<ThemeMode>(
                groupValue: mode,
                onChanged: (value) {
                  if (value != null) ref.read(themeModeProvider.notifier).set(value);
                },
                child: Column(
                  children: [
                    for (final entry in <(ThemeMode, String)>[
                      (ThemeMode.system, l.settings_themeSystem),
                      (ThemeMode.light, l.settings_themeLight),
                      (ThemeMode.dark, l.settings_themeDark),
                    ])
                      RadioListTile<ThemeMode>(
                        value: entry.$1,
                        title: Text(entry.$2),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ),
            MicroSpacing.gapXL,
            MicroSectionHeader(title: l.paywall_headline),
            MicroCard(
              child: Row(
                children: [
                  Icon(
                    entitlement.isPro ? Icons.verified : Icons.lock_outline,
                    color: entitlement.isPro
                        ? Theme.of(context).colorScheme.success
                        : Theme.of(context).colorScheme.mutedText,
                  ),
                  MicroSpacing.hGapM,
                  Expanded(
                    child: Text(
                      entitlement.isPro ? l.paywall_thanks : l.paywall_subhead,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (!entitlement.isPro) const ProBadge(),
                ],
              ),
            ),
            MicroSpacing.gapXL,
            MicroSectionHeader(title: l.settings_about),
            MicroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.settings_version(appVersion)),
                  if (installId != null) ...[
                    MicroSpacing.gapM,
                    Text(l.settings_installId, style: Theme.of(context).textTheme.cardTitle),
                    SelectableText(
                      installId.short,
                      style: Theme.of(context).textTheme.numeric,
                    ),
                    Text(
                      l.settings_installIdHelp,
                      style: Theme.of(context).textTheme.cardMeta.copyWith(
                        color: Theme.of(context).colorScheme.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

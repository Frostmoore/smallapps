import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/app_themes.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/trashcan_widget.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// Applica il colore scelto, o apre il paywall se non se ne ha diritto.
  static Future<void> _pickSeed(BuildContext context, WidgetRef ref, Color color) async {
    if (!ref.read(featureGateProvider).allows(FeatureKey.themeCustomization)) {
      await showTrashcanPaywall(context, ref, highlight: FeatureKey.themeCustomization);
      return;
    }
    await ref.read(seedColorProvider.notifier).set(color);
  }

  /// Chiede al launcher di aggiungere il widget.
  ///
  /// ☠ Non tutti i launcher lo supportano, e chi non lo supporta non restituisce un
  /// errore: semplicemente non succede niente. Si controlla prima e si spiega come fare a
  /// mano, altrimenti l'utente tocca, non vede niente e conclude che l'app e' rotta.
  static Future<void> _pinWidget(BuildContext context, L l) async {
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!context.mounted) return;
    if (!supported) {
      MicroSnack.show(context, l.widget_addUnsupported);
      return;
    }
    await HomeWidget.requestPinWidget(qualifiedAndroidName: TrashcanWidget.qualifiedName);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final mode = ref.watch(themeModeProvider);
    final gate = ref.watch(featureGateProvider);
    final seed = ref.watch(seedColorProvider);
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
            MicroSectionHeader(
              title: l.settings_appColour,
              trailing: gate.allows(FeatureKey.themeCustomization)
                  ? null
                  : const ProBadge(compact: true),
            ),
            MicroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.settings_appColourBody,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  MicroSpacing.gapL,
                  Wrap(
                    spacing: MicroSpacing.s,
                    runSpacing: MicroSpacing.s,
                    children: [
                      for (final entry in AppSeeds.all)
                        _SeedSwatch(
                          color: entry.color,
                          selected: entry.color.toARGB32() == seed.toARGB32(),
                          // ⛑ Il cancello sta sul tocco, non sull'aspetto: le pastiglie si
                          // vedono tutte anche senza Pro. Nasconderle vorrebbe dire che
                          // nessuno sa che la personalizzazione esiste, e una funzione che
                          // nessuno vede non si vende.
                          onTap: () => unawaited(_pickSeed(context, ref, entry.color)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            MicroSpacing.gapXL,
            MicroSectionHeader(title: l.settings_calendar),
            MicroCard(
              padding: EdgeInsets.zero,
              child: MicroListTile(
                title: l.exceptions_title,
                subtitle: l.exceptions_emptyHint,
                leading: const Icon(Icons.event_busy_outlined),
                onTap: () => context.push(Routes.exceptions),
              ),
            ),
            MicroSpacing.gapS,
            MicroCard(
              padding: EdgeInsets.zero,
              child: MicroListTile(
                title: l.notifications_title,
                subtitle: l.notifications_enabledLabel,
                leading: const Icon(Icons.notifications_outlined),
                onTap: () => context.push(Routes.notifications),
              ),
            ),
            MicroSpacing.gapS,
            MicroCard(
              padding: EdgeInsets.zero,
              child: MicroListTile(
                title: l.widget_addTitle,
                subtitle: l.widget_addBody,
                leading: const Icon(Icons.widgets_outlined),
                onTap: () => _pinWidget(context, l),
              ),
            ),
            MicroSpacing.gapS,
            MicroCard(
              padding: EdgeInsets.zero,
              child: MicroListTile(
                title: l.backup_title,
                subtitle: l.backup_shareCalendarBody,
                leading: const Icon(Icons.ios_share),
                onTap: () => context.push(Routes.backup),
              ),
            ),
            MicroSpacing.gapXL,
            MicroSectionHeader(title: l.paywall_headline),
            MicroCard(
              padding: EdgeInsets.zero,
              child: MicroListTile(
                title: l.restore_title,
                subtitle: l.restore_playBody,
                leading: const Icon(Icons.phonelink_setup_outlined),
                onTap: () => context.push(Routes.restore),
              ),
            ),
            MicroSpacing.gapS,
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


/// Una pastiglia di colore nel selettore del tema.
class _SeedSwatch extends StatelessWidget {
  const _SeedSwatch({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22),
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
            : null,
      ),
      child: selected
          ? Icon(Icons.check, size: 20, color: MicroCard.foregroundOn(color))
          : null,
    ),
  );
}

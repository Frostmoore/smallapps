import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../domain/consumption.dart';
import '../../l10n/generated/app_localizations.dart';
import '../stock/update_sheet.dart';

/// La dashboard (F5.6): una scheda per ogni fonte attiva.
///
/// ⚑ Interfaccia **essenziale** per scelta del proprietario (F5.0 punto 6): prima si prova
/// che l'app risponde bene alla domanda, poi si scelgono le direzioni grafiche.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final sources = ref.watch(sourcesProvider).value ?? const <FuelSource>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            tooltip: l.settings_title,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          for (final s in sources) ...[_SourceCard(source: s), MicroSpacing.gapL],
          OutlinedButton.icon(
            onPressed: () => unawaited(openNewSource(context, ref)),
            icon: const Icon(Icons.add),
            label: Text(l.home_addSource),
          ),
        ],
      ),
    );
  }
}

/// Apre la creazione di una fonte, passando dal paywall se il piano gratuito e' pieno.
Future<void> openNewSource(BuildContext context, WidgetRef ref) async {
  final count = ref.read(sourcesProvider).value?.length ?? 0;
  if (!ref.read(featureGateProvider).withinLimit(FeatureKey.unlimitedEntities, count)) {
    final unlocked = await showScortePaywall(context, ref, highlight: FeatureKey.unlimitedEntities);
    if (!unlocked || !context.mounted) return;
  }
  if (context.mounted) await context.push(Routes.sourceNew);
}

class _SourceCard extends ConsumerWidget {
  const _SourceCard({required this.source});

  final FuelSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final e = ref.watch(estimateProvider(source.id));
    final today = ref.watch(todayProvider);
    String day(CivilDate d) => DateFormat.MMMMd(locale).format(d.toLocalMidnight());

    final hasData = e != null && e.lastMeasurementDate != null;
    final stale = hasData && e.lastMeasurementDate!.daysUntil(today) > 14;

    return MicroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source.name, style: text.titleLarge),
                    Text(fuelName(l, source.fuelTypeEnum), style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                tooltip: l.common_edit,
                icon: const Icon(Icons.tune),
                onPressed: () => context.push(Routes.sourceEditOf(source.id)),
              ),
            ],
          ),
          MicroSpacing.gapM,
          if (hasData)
            Row(
              children: [
                MicroProgressRing(
                  value: e.fractionRemaining ?? 0,
                  centerLabel: e.percentRemaining == null ? '–' : '${e.percentRemaining}%',
                  size: 96,
                ),
                MicroSpacing.hGapL,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatAmount(l, source.unit, e.currentQuantity), style: text.headlineSmall),
                      Text(l.home_remaining, style: text.bodySmall),
                      MicroSpacing.gapS,
                      if (e.isActionable)
                        Text(l.home_days(e.daysRemaining ?? 0), style: text.titleMedium?.copyWith(color: scheme.primary))
                      else
                        Text(l.home_needMore, style: text.bodyMedium),
                    ],
                  ),
                ),
              ],
            )
          else
            Text(l.home_needMore, style: text.bodyMedium),
          if (hasData && e.isActionable) ...[
            MicroSpacing.gapM,
            if (e.dailyRate != null) Text(l.home_rate(formatAmount(l, source.unit, e.dailyRate!, minDecimals: 1))),
            if (e.reorderDate != null)
              Text(
                e.reorderDate!.isBefore(today) ? l.home_reorderPast(day(e.reorderDate!)) : l.home_reorder(day(e.reorderDate!)),
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            if (e.depletionDate != null) Text(l.home_runsOut(day(e.depletionDate!))),
            if (e.quality == EstimateQuality.low) ...[
              MicroSpacing.gapXS,
              Text(l.home_provisional(e.intervalsUsed), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ],
          if (hasData) ...[
            MicroSpacing.gapS,
            Row(
              children: [
                Expanded(child: Text(l.home_lastUpdate(day(e.lastMeasurementDate!)), style: text.bodySmall)),
                if (stale)
                  Chip(
                    label: Text(l.home_stale),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: scheme.tertiaryContainer,
                  ),
              ],
            ),
          ],
          MicroSpacing.gapM,
          MicroPrimaryButton(label: l.home_update, onPressed: () => unawaited(showUpdateSheet(context, source))),
        ],
      ),
    );
  }
}

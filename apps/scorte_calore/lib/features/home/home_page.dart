import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/scorte_palette.dart';
import '../../data/database.dart';
import '../../domain/consumption.dart';
import '../../l10n/generated/app_localizations.dart';
import '../stock/update_sheet.dart';

/// La home "A · Brace" (scelta del proprietario, 2026-10-07).
///
/// - In testata, su blu notte, la fonte principale: i giorni di autonomia enormi in arancio
///   brace, la barra del residuo, il riquadro della data di riordino.
/// - Sotto, le altre fonti come righe compatte: toccarne una la porta in testata.
/// - In fondo, fisso, "Aggiorna scorta" della fonte in testata: il gesto piu' frequente.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = ScortePalette.of(context);
    final sources = ref.watch(sourcesProvider).value ?? const <FuelSource>[];
    final hero = ref.watch(heroSourceProvider);
    final others = [for (final s in sources) if (s.id != hero?.id) s];

    // La testata e' blu notte: icone chiare nella barra di stato anche nel tema chiaro.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            if (hero != null) _Hero(source: hero) else _EmptyHero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (others.isNotEmpty) ...[
                    Text(
                      l.home_otherSources,
                      style: TextStyle(fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: p.inkMuted),
                    ),
                    const SizedBox(height: 12),
                    for (final s in others) ...[_SourceRow(source: s), const SizedBox(height: 10)],
                  ],
                  TextButton.icon(
                    onPressed: () => unawaited(openNewSource(context, ref)),
                    icon: const Icon(Icons.add),
                    label: Text(l.home_addSource),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: hero == null
            ? null
            : SafeArea(
                minimum: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: SizedBox(
                  height: 58,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.flame,
                      foregroundColor: p.onFlame,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => unawaited(showUpdateSheet(context, hero)),
                    icon: const Icon(Icons.add),
                    label: Text(l.home_update),
                  ),
                ),
              ),
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

String _day(BuildContext context, CivilDate d) =>
    DateFormat.MMMMd(Localizations.localeOf(context).toLanguageTag()).format(d.toLocalMidnight());

/// La testata blu notte con la fonte principale.
class _Hero extends ConsumerWidget {
  const _Hero({required this.source});

  final FuelSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = ScortePalette.of(context);
    final e = ref.watch(estimateProvider(source.id));
    final today = ref.watch(todayProvider);
    final top = MediaQuery.paddingOf(context).top;
    final hasData = e != null && e.lastMeasurementDate != null;
    final stale = hasData && e.lastMeasurementDate!.daysUntil(today) > 14;
    final etichetta = '${source.name} · ${fuelName(l, source.fuelTypeEnum)}'.toUpperCase();

    return Container(
      padding: EdgeInsets.fromLTRB(22, top + 14, 22, 24),
      decoration: BoxDecoration(
        color: p.night,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etichetta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: p.emberLabel),
                    ),
                    const SizedBox(height: 2),
                    if (hasData)
                      Text(
                        l.home_amountLeft(formatAmount(l, source.unit, e.currentQuantity)),
                        style: TextStyle(fontSize: 15, color: p.onNightMuted),
                      ),
                  ],
                ),
              ),
              _NightButton(
                tooltip: l.common_edit,
                icon: Icons.tune,
                onPressed: () => context.push(Routes.sourceEditOf(source.id)),
              ),
              const SizedBox(width: 8),
              _NightButton(
                tooltip: l.settings_title,
                icon: Icons.settings_outlined,
                onPressed: () => context.push(Routes.settings),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (hasData && e.isActionable) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${e.daysRemaining ?? 0}',
                  style: TextStyle(fontSize: 92, height: 0.85, fontWeight: FontWeight.w800, letterSpacing: -3, color: p.ember),
                ),
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.home_daysWord(e.daysRemaining ?? 0),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.onNight),
                      ),
                      Text(l.home_autonomy, style: TextStyle(fontSize: 14, color: p.onNightMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ] else
            Text(l.home_needMore, style: TextStyle(fontSize: 18, height: 1.35, color: p.onNight)),
          if (hasData) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: e.fractionRemaining ?? 0,
                minHeight: 10,
                backgroundColor: p.track,
                color: p.ember,
              ),
            ),
            const SizedBox(height: 8),
            DefaultTextStyle(
              style: TextStyle(fontSize: 13, color: p.onNightMuted),
              child: Row(
                children: [
                  if (e.percentRemaining != null) Expanded(child: Text(l.home_fromRefill(e.percentRemaining!))),
                  if (e.dailyRate != null) Text(l.home_perDay(formatAmount(l, source.unit, e.dailyRate!, minDecimals: 1))),
                ],
              ),
            ),
          ],
          if (hasData && e.reorderDate != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: p.nightRaised, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, color: p.badge, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 15, color: p.onNight),
                        children: [
                          TextSpan(
                            text: e.reorderDate!.isBefore(today)
                                ? l.home_reorderBoxPast(_day(context, e.reorderDate!))
                                : l.home_reorderBox(_day(context, e.reorderDate!)),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (e.depletionDate != null) TextSpan(text: ' · ${l.home_runsOutShort(_day(context, e.depletionDate!))}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (hasData && (e.quality == EstimateQuality.low || stale)) ...[
            const SizedBox(height: 10),
            Text(
              stale ? l.home_stale : l.home_provisional(e.intervalsUsed),
              style: TextStyle(fontSize: 13, color: p.badge),
            ),
          ],
        ],
      ),
    );
  }
}

/// La testata quando non c'e' ancora nessuna fonte (dopo averle cancellate tutte).
class _EmptyHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = ScortePalette.of(context);
    final l = L.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(22, MediaQuery.paddingOf(context).top + 24, 22, 28),
      decoration: BoxDecoration(color: p.night, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28))),
      child: Text(l.source_intro, style: TextStyle(fontSize: 18, height: 1.35, color: p.onNight)),
    );
  }
}

class _NightButton extends StatelessWidget {
  const _NightButton({required this.tooltip, required this.icon, required this.onPressed});

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = ScortePalette.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        backgroundColor: p.nightRaised,
        foregroundColor: p.onNight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.nightBorder),
        ),
      ),
    );
  }
}

/// Una delle altre fonti: toccarla la porta in testata.
class _SourceRow extends ConsumerWidget {
  const _SourceRow({required this.source});

  final FuelSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = ScortePalette.of(context);
    final e = ref.watch(estimateProvider(source.id));
    final hasData = e != null && e.lastMeasurementDate != null;
    final detail = !hasData
        ? l.home_needMore
        : e.dailyRate == null
        ? formatAmount(l, source.unit, e.currentQuantity)
        : l.home_rowDetail(
            formatAmount(l, source.unit, e.currentQuantity),
            formatAmount(l, source.unit, e.dailyRate!, minDecimals: 1),
          );

    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => unawaited(ref.read(selectedSourceProvider.notifier).select(source.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: p.iconTile, borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.local_fire_department_outlined, color: p.onIconTile, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink)),
                    const SizedBox(height: 2),
                    Text(detail, style: TextStyle(fontSize: 13, color: p.inkMuted)),
                  ],
                ),
              ),
              if (hasData && e.isActionable)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${e.daysRemaining ?? 0}',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: p.onIconTile),
                    ),
                    Text(l.home_daysWord(e.daysRemaining ?? 0), style: TextStyle(fontSize: 12, color: p.inkMuted)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

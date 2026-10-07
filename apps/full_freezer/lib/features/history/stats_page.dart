import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/freezer_palette.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../domain/stats.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/ghiaccio.dart';
import '../items/item_pickers.dart';

/// Le statistiche dello spreco (Pro, F4.10). Ci si arriva dalle impostazioni, che passano
/// dal paywall per chi non ha il Pro.
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  StatsPeriod _period = StatsPeriod.year;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = FreezerPalette.of(context);
    final removed = ref.watch(removedItemsProvider).value ?? const <Item>[];
    final stats = computeStats(removed, period: _period, now: DateTime.now());
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(title: Text(l.stats_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          SegmentedButton<StatsPeriod>(
            segments: [
              ButtonSegment(value: StatsPeriod.month, label: Text(l.stats_month)),
              ButtonSegment(value: StatsPeriod.year, label: Text(l.stats_year)),
              ButtonSegment(value: StatsPeriod.all, label: Text(l.stats_all)),
            ],
            selected: {_period},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _period = s.first),
          ),
          const SizedBox(height: 16),
          if (stats.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.stats_empty, textAlign: TextAlign.center, style: TextStyle(color: p.inkMuted, height: 1.4)),
            )
          else ...[
            // Il pannello blu notte: la quota buttata in grande.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: p.night, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.stats_wastedLabel.toUpperCase(),
                    style: TextStyle(color: p.ice, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${(stats.wasteRate * 100).round()}'),
                        TextSpan(text: '%', style: TextStyle(fontSize: 28, color: p.ice)),
                      ],
                    ),
                    style: TextStyle(
                      color: p.onNight,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.stats_wastedLine(stats.discarded, stats.total),
                    style: TextStyle(color: p.onNightMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _NumberTile(
                      value: stats.averageDays == null ? '–' : stats.averageDays!.round().toString(),
                      unit: l.home_daysUnit(stats.averageDays?.round() ?? 0),
                      label: l.stats_averageStay,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NumberTile(
                      value: stats.mostWastedCategory == null ? '–' : '${stats.mostWastedCount}',
                      unit: stats.mostWastedCategory == null ? '' : categoryName(l, stats.mostWastedCategory),
                      label: l.stats_mostWasted,
                      leading: stats.mostWastedCategory == null
                          ? null
                          : categoryGlyph(stats.mostWastedCategory, size: 22, color: p.old),
                    ),
                  ),
                ],
              ),
            ),
          ],
          GhiaccioSectionLabel(text: l.stats_months, padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
          _MonthChart(months: stats.months, locale: locale),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: p.accent, label: l.item_consume),
              const SizedBox(width: 18),
              _Legend(color: p.old, label: l.item_discard),
            ],
          ),
          const SizedBox(height: 18),
          GhiaccioTile(
            leading: const Icon(Icons.history),
            title: l.history_title,
            subtitle: l.history_count(removed.length),
            trailing: Icon(Icons.chevron_right, color: p.inkMuted),
            onTap: () => context.push(Routes.history),
          ),
        ],
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.value, required this.unit, required this.label, this.leading});

  final String value;
  final String unit;
  final String label;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final p = FreezerPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                      TextSpan(text: ' $unit', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.ink, height: 1.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: p.inkMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Il grafico degli ultimi sei mesi: per ogni mese, due barre affiancate (consumato,
/// buttato). Disegnato a mano: per sei coppie di barre una libreria di grafici e' un plugin
/// in piu' da tenere aggiornato senza dare niente in cambio.
class _MonthChart extends StatelessWidget {
  const _MonthChart({required this.months, required this.locale});

  final List<MonthBar> months;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final p = FreezerPalette.of(context);
    final peak = math.max(1, months.fold<int>(0, (m, b) => math.max(m, math.max(b.consumed, b.discarded))));
    const barMax = 120.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final m in months)
            Expanded(
              child: Semantics(
                label: '${DateFormat.MMMM(locale).format(DateTime(m.year, m.month))}: ${m.consumed}, ${m.discarded}',
                child: Column(
                  children: [
                    SizedBox(
                      height: barMax,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _Bar(height: barMax * m.consumed / peak, color: p.accent),
                          const SizedBox(width: 3),
                          _Bar(height: barMax * m.discarded / peak, color: p.old),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat.MMM(locale).format(DateTime(m.year, m.month)),
                      style: TextStyle(color: p.inkMuted, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    // Anche zero si vede come un trattino: "niente" e' un dato, non un buco nel grafico.
    height: math.max(3, height),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: FreezerPalette.of(context).inkMuted, fontSize: 12)),
    ],
  );
}

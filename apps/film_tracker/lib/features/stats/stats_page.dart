import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../data/database.dart';
import '../../domain/film_stats.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/film_strip.dart';
import '../common/pro_gate.dart';
import '../settings/data_section.dart';

/// Le statistiche e i costi per anno solare (F6.10, Pro, `FeatureKey.statistics`).
///
/// I numeri li fa `FilmStatsCalculator` (dominio, gia' testato); la pagina sceglie l'anno e li
/// mostra. Gli ingressi arrivano da `statsRollsProvider`, che si riemette a ogni modifica di
/// rullini, sviluppi e stampe: la pagina aperta si aggiorna da sola.
///
/// ⚑ **`ProGate` sulla pagina** e non solo sulla voce di menu (F6.0 punto 7): un `push`
/// diretto (la voce della home, una pagina futura) senza il Pro mostra il lucchetto.
///
/// ☠ **Il costo per fotogramma e' una stima** (F6.10): si calcola sui fotogrammi nominali, e
/// non tutti vengono scattati o riescono. La pagina lo scrive nel titolo ("stima"), nel valore
/// ("≈") e in una riga di spiegazione: presentarlo come dato esatto sarebbe falso.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const ProGate(feature: FeatureKey.statistics, child: _StatsView());
}

class _StatsView extends ConsumerStatefulWidget {
  const _StatsView();

  @override
  ConsumerState<_StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends ConsumerState<_StatsView> {
  /// L'anno scelto; null = il piu' recente con rullini.
  int? _year;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final rolls = ref.watch(statsRollsProvider);
    final years = ref.watch(statsYearsProvider);
    // ⚑ Un anno scelto che non ha piu' rullini (cancellati, o spostati di data) torna al
    // piu' recente invece di mostrare una pagina di zeri.
    final year = (_year != null && years.contains(_year)) ? _year! : years.firstOrNull;
    final stats = year == null ? null : ref.watch(yearStatsProvider(year));

    final Widget body;
    if (rolls.hasError && !rolls.hasValue) {
      body = MicroEmptyState(
        icon: Icons.error_outline,
        title: l.home_loadError,
        message: l.home_loadErrorBody,
        actionLabel: l.common_retry,
        onAction: () => ref.invalidate(statsRollsProvider),
      );
    } else if (!rolls.hasValue) {
      body = const Center(child: CircularProgressIndicator());
    } else if (year == null || stats == null) {
      body = MicroEmptyState(icon: Icons.insights_outlined, title: l.stats_emptyTitle, message: l.stats_emptyBody);
    } else {
      body = ListView(
        padding: MicroSpacing.page,
        children: [
          _YearPicker(years: years, selected: year, onSelected: (y) => setState(() => _year = y)),
          MicroSpacing.gapL,
          _StatsContent(stats: stats),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.stats_title),
        actions: [
          if (year != null)
            IconButton(
              key: const ValueKey('stats_pdf'),
              tooltip: l.report_title,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => unawaited(createYearReport(context, ref, year: year)),
            ),
        ],
      ),
      body: body,
    );
  }
}

/// Gli anni con rullini, dal piu' recente, come chip: di solito sono due o tre, e un menu a
/// tendina nasconderebbe che ce ne sono altri.
class _YearPicker extends StatelessWidget {
  const _YearPicker({required this.years, required this.selected, required this.onSelected});

  final List<int> years;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final y in years)
          Padding(
            padding: const EdgeInsets.only(right: MicroSpacing.s),
            child: ChoiceChip(
              key: ValueKey('stats_year_$y'),
              label: Text(y.toString()),
              selected: y == selected,
              onSelected: (_) => onSelected(y),
            ),
          ),
      ],
    ),
  );
}

class _StatsContent extends ConsumerWidget {
  const _StatsContent({required this.stats});

  final YearStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final s = stats;
    final cameras = ref.watch(camerasProvider).value ?? const <Camera>[];
    final topCamera = cameras.where((c) => c.id == s.topCameraId).firstOrNull;
    final perFrame = s.estimatedCentsPerFrame;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: MicroStatTile(
                key: const ValueKey('stats_rolls'),
                icon: Icons.camera_roll_outlined,
                label: l.stats_rolls,
                value: '${s.rollCount}',
              ),
            ),
            MicroSpacing.hGapM,
            Expanded(
              child: MicroStatTile(
                key: const ValueKey('stats_frames'),
                icon: Icons.grid_view,
                label: l.stats_potentialFrames,
                value: '${s.potentialFrames}',
                hint: l.stats_potentialFramesHint,
              ),
            ),
          ],
        ),

        MicroSpacing.gapL,
        SectionLabel(l.stats_perMonth),
        MonthlyRollsChart(rollsPerMonth: s.rollsPerMonth),

        MicroSpacing.gapL,
        SectionLabel(l.stats_spending),
        if (s.totalCents == 0)
          Text(l.stats_noCosts, style: muted)
        else
          MicroCard(
            child: Column(
              children: [
                _AmountRow(label: l.stats_film, cents: s.filmCents),
                _AmountRow(label: l.stats_development, cents: s.developmentCents),
                _AmountRow(label: l.stats_scans, cents: s.scanCents),
                _AmountRow(label: l.stats_prints, cents: s.printCents),
                const Divider(),
                _AmountRow(key: const ValueKey('stats_total'), label: l.stats_total, cents: s.totalCents, strong: true),
              ],
            ),
          ),

        if (s.averageCentsPerRoll != null) ...[
          MicroSpacing.gapL,
          SectionLabel(l.stats_averages),
          MicroStatTile(
            key: const ValueKey('stats_perRoll'),
            icon: Icons.payments_outlined,
            label: l.stats_perRoll,
            value: formatCents(l, s.averageCentsPerRoll!),
            hint: l.stats_perRollHint(s.costedRollCount),
          ),
          if (perFrame != null) ...[
            MicroSpacing.gapM,
            MicroStatTile(
              key: const ValueKey('stats_perFrame'),
              icon: Icons.crop_square,
              label: l.stats_perFrame,
              // ⚑ Arrotondato al centesimo solo qui: il dominio lo tiene `double`.
              value: l.stats_perFrameValue(formatCents(l, perFrame.round())),
              hint: l.stats_perFrameHint,
            ),
          ],
        ],

        MicroSpacing.gapL,
        SectionLabel(l.stats_mostUsed),
        MicroCard(
          child: Column(
            children: [
              _RankRow(
                key: const ValueKey('stats_topEmulsion'),
                icon: Icons.camera_roll_outlined,
                label: l.stats_topEmulsion,
                name: s.topEmulsion?.name,
                detail: s.topEmulsion == null ? null : l.stats_rollsCount(s.topEmulsion!.count),
              ),
              _RankRow(
                key: const ValueKey('stats_topCamera'),
                icon: Icons.photo_camera_outlined,
                label: l.stats_topCamera,
                name: topCamera?.displayName,
                detail: topCamera == null ? null : l.stats_rollsCount(s.topCameraRolls),
              ),
              _RankRow(
                key: const ValueKey('stats_topLab'),
                icon: Icons.science_outlined,
                label: l.stats_topLab,
                name: s.topLaboratory?.name,
                detail: s.topLaboratory == null ? null : l.stats_timesCount(s.topLaboratory!.count),
              ),
            ],
          ),
        ),
        if (s.selfDevelopedCount > 0) ...[
          MicroSpacing.gapS,
          Text(l.stats_selfDeveloped(s.selfDevelopedCount), style: muted),
        ],
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.cents, this.strong = false, super.key});

  final String label;
  final int cents;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final style = strong ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MicroSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(formatCents(l, cents), style: style),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.icon, required this.label, this.name, this.detail, super.key});

  final IconData icon;
  final String label;
  final String? name;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(name ?? l.stats_noneYet),
      subtitle: Text(detail == null ? label : '$label · $detail'),
    );
  }
}

// ── Grafico ─────────────────────────────────────────────────────────────────

/// Il grafico a barre dei rullini per mese (F6.10): dodici barre, gennaio a sinistra, con il
/// numero sopra ogni barra non vuota e l'iniziale del mese sotto.
///
/// ⚑ **Disegnato con `CustomPainter`, niente `fl_chart`**, come i grafici di Scorte Calore
/// (`apps/scorte_calore/lib/features/history/charts.dart`): dodici rettangoli non valgono un
/// pacchetto in piu' da compilare su due piattaforme. ⚑ Niente asse verticale: con il numero
/// scritto sopra ogni barra un asse direbbe la stessa cosa due volte, e i numeri sono piccoli
/// (raramente piu' di dieci rullini in un mese).
///
/// Per i lettori di schermo il disegno non dice niente: la `Semantics` porta l'elenco
/// "gen 2, feb 0, ...".
class MonthlyRollsChart extends StatelessWidget {
  const MonthlyRollsChart({required this.rollsPerMonth, this.height = 160, super.key})
    : assert(rollsPerMonth.length == 12, 'servono dodici mesi');

  /// Dodici interi, gennaio in posizione 0 (`YearStats.rollsPerMonth`).
  final List<int> rollsPerMonth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final scheme = Theme.of(context).colorScheme;
    final narrow = DateFormat('MMMMM', locale);
    final short = DateFormat.MMM(locale);
    final months = [for (var m = 1; m <= 12; m++) DateTime(2000, m)];
    final semantics = [
      for (var i = 0; i < 12; i++) '${short.format(months[i])} ${rollsPerMonth[i]}',
    ].join(', ');
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: MonthlyBarsPainter(
            values: rollsPerMonth,
            labels: [for (final m in months) narrow.format(m).toUpperCase()],
            bar: scheme.primary,
            empty: scheme.outlineVariant,
            text: scheme.onSurfaceVariant,
            valueText: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Il disegno di [MonthlyRollsChart]. Pubblico perche' un test ne controlli `shouldRepaint`.
class MonthlyBarsPainter extends CustomPainter {
  MonthlyBarsPainter({
    required this.values,
    required this.labels,
    required this.bar,
    required this.empty,
    required this.text,
    required this.valueText,
  });

  final List<int> values;
  final List<String> labels;
  final Color bar;
  final Color empty;
  final Color text;
  final Color valueText;

  static const double _bottomGutter = 20;
  static const double _topGutter = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final peak = values.fold<int>(0, math.max);
    final plot = Rect.fromLTRB(0, _topGutter, size.width, size.height - _bottomGutter);
    final slot = plot.width / values.length;
    final barWidth = math.min(slot * 0.6, 28.0);
    final labelStyle = TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w600);
    final valueStyle = TextStyle(color: valueText, fontSize: 11, fontWeight: FontWeight.w700);

    // La linea di base, perche' i mesi vuoti non sembrino un disegno mancante.
    canvas.drawLine(
      Offset(plot.left, plot.bottom),
      Offset(plot.right, plot.bottom),
      Paint()
        ..color = empty
        ..strokeWidth = 1,
    );

    for (var i = 0; i < values.length; i++) {
      final cx = plot.left + slot * (i + 0.5);
      final v = values[i];
      if (v > 0 && peak > 0) {
        final h = plot.height * v / peak;
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - barWidth / 2, plot.bottom - h, barWidth, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rect, Paint()..color = bar);
        _paintText(canvas, '$v', valueStyle, Offset(cx, plot.bottom - h - 2), above: true);
      }
      _paintText(canvas, labels[i], labelStyle, Offset(cx, plot.bottom + 4), above: false);
    }
  }

  void _paintText(Canvas canvas, String s, TextStyle style, Offset at, {required bool above}) {
    final tp = TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(at.dx - tp.width / 2, above ? at.dy - tp.height : at.dy));
    tp.dispose();
  }

  @override
  bool shouldRepaint(MonthlyBarsPainter old) =>
      !_sameList(old.values, values) ||
      !_sameList(old.labels, labels) ||
      old.bar != bar ||
      old.empty != empty ||
      old.text != text ||
      old.valueText != valueText;

  static bool _sameList<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

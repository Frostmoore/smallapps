import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/formats.dart';
import '../../app/labels.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../app/scorte_palette.dart';
import '../../data/database.dart';
import '../../domain/consumption.dart';
import '../../domain/fuel_source.dart';
import '../../domain/fuel_units.dart';
import '../../l10n/generated/app_localizations.dart';
import '../purchases/purchases_page.dart';
import 'charts.dart';

/// La fonte dello storico, anche se disattivata (`sourcesProvider` porta solo le attive).
final _historySourceProvider = StreamProvider.autoDispose.family<FuelSource?, int>(
  (ref, id) => ref.watch(repositoryProvider).watchSource(id),
);

/// Il primo giorno visibile nello storico del piano gratuito, o null con il Pro.
///
/// ⚑ `freeMax: 90` di `FeatureKey.fullHistory` vuol dire **90 giorni di calendario, oggi
/// compreso**: da `oggi - 89` in poi. Il valore si legge dal gate e non si riscrive qui, cosi'
/// cambiarlo in `feature_limits.dart` basta.
CivilDate? historyStart(FeatureGate gate, CivilDate today) {
  if (gate.isPro) return null;
  final days = gate.freeLimitOf(FeatureKey.fullHistory);
  if (days == null) return null;
  return today.addDays(-(days - 1));
}

/// Lo storico delle misurazioni di una fonte (develop_microapps.md F5.9).
///
/// - In alto i due grafici (Pro, `FeatureKey.statistics`); senza Pro un riquadro col badge
///   che apre il paywall.
/// - L'accesso ad acquisti e costi (Pro, F5.11).
/// - Le misure raggruppate per mese, dalla piu' recente, ognuna eliminabile con "Annulla".
/// - Nel piano gratuito solo gli ultimi 90 giorni (`FeatureKey.fullHistory`), e in fondo
///   quante misure piu' vecchie si vedono col Pro.
///
/// ⚑ **Il limite dei 90 giorni si applica in memoria** a `measurementsProvider` (tutte le
/// misure della fonte) invece di chiedere al repository `watchMeasurements(since:)`: la
/// stessa lista serve gia' alla stima della testata (un solo stream aperto), il delta della
/// prima misura visibile si calcola con la precedente anche se e' nascosta, e si sa quante
/// misure il gratuito non mostra (il numero nell'invito al Pro).
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({required this.sourceId, super.key});

  final int sourceId;

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  /// Le misure appena eliminate, nascoste subito.
  ///
  /// ☠ Un `Dismissible` scartato deve sparire dall'albero **nello stesso frame**, altrimenti
  /// Flutter lancia "A dismissed Dismissible widget is still part of the tree"; lo stream di
  /// Drift arriva un attimo dopo la cancellazione. Toglierle qui chiude la finestra.
  final Set<int> _gone = {};

  Future<void> _delete(StockMeasurement row) async {
    final l = L.of(context);
    final repo = ref.read(repositoryProvider);
    setState(() => _gone.add(row.id));
    await repo.deleteMeasurement(row.id);
    if (!mounted) return;
    MicroSnack.show(
      context,
      l.history_deleted,
      actionLabel: l.history_undo,
      // ⚑ Si rimette con `upsertMeasurement`, non con un insert della riga: le regole della
      // misura (una al giorno, percentuale ricalcolata sulla capacita' attuale) passano da
      // una porta sola. L'id cambia, ed e' indifferente.
      onAction: () => unawaited(repo.upsertMeasurement(widget.sourceId, row.toMeasurement(), note: row.note)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = ScortePalette.of(context);
    final sourceAsync = ref.watch(_historySourceProvider(widget.sourceId));
    final source = sourceAsync.value;
    final all = ref.watch(measurementsProvider(widget.sourceId)).value;
    final gate = ref.watch(featureGateProvider);
    final today = ref.watch(todayProvider);

    // Una fonte che non esiste (eliminata, o un deep link sbagliato): pagina vuota, non una
    // rotellina eterna.
    if (sourceAsync.hasValue && source == null) return Scaffold(appBar: AppBar());
    if (source == null || all == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    final rows = [for (final r in all) if (!_gone.contains(r.id)) r];
    final start = historyStart(gate, today);
    final visible = start == null ? rows : [for (final r in rows) if (!r.civilDate.isBefore(start)) r];
    final hidden = rows.length - visible.length;
    final previous = {for (var i = 1; i < rows.length; i++) rows[i].id: rows[i - 1]};

    return Scaffold(
      appBar: AppBar(title: Text('${l.history_title} · ${source.name}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          if (gate.allows(FeatureKey.statistics))
            _Charts(source: source, rows: rows)
          else
            _LockedCharts(onTap: () => unawaited(showScortePaywall(context, ref, highlight: FeatureKey.statistics))),
          const SizedBox(height: 10),
          _PurchasesTile(onTap: () => unawaited(openPurchases(context, ref, source.id)), locked: !gate.allows(FeatureKey.statistics)),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.history_empty, textAlign: TextAlign.center, style: TextStyle(color: p.inkMuted)),
            )
          else
            for (final month in _byMonth(visible.reversed)) ...[
              _MonthLabel(date: month.first.civilDate),
              _MonthCard(
                children: [
                  for (final r in month)
                    _MeasurementRow(
                      key: ValueKey(r.id),
                      row: r,
                      previous: previous[r.id],
                      unitKey: source.unit,
                      onDelete: () => unawaited(_delete(r)),
                    ),
                ],
              ),
            ],
          if (hidden > 0 && start != null) ...[
            const SizedBox(height: 18),
            _FreeLimitCard(
              days: gate.freeLimitOf(FeatureKey.fullHistory) ?? 0,
              hidden: hidden,
              onTap: () => unawaited(showScortePaywall(context, ref, highlight: FeatureKey.fullHistory)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le misure in gruppi per mese, nell'ordine ricevuto.
List<List<StockMeasurement>> _byMonth(Iterable<StockMeasurement> rows) {
  final out = <List<StockMeasurement>>[];
  for (final r in rows) {
    final d = r.civilDate;
    if (out.isNotEmpty) {
      final last = out.last.first.civilDate;
      if (last.year == d.year && last.month == d.month) {
        out.last.add(r);
        continue;
      }
    }
    out.add([r]);
  }
  return out;
}

String _locale(BuildContext context) => Localizations.localeOf(context).toLanguageTag();

/// I due grafici su una scheda bianca, con il titolo, l'unita' e la legenda.
class _Charts extends ConsumerWidget {
  const _Charts({required this.source, required this.rows});

  final FuelSource source;
  final List<StockMeasurement> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = ScortePalette.of(context);
    final measurements = rows.toMeasurements();
    const calc = ConsumptionCalculator();
    final sorted = calc.normalize(measurements);
    final unit = unitName(l, source.unit, 2);
    final title = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink);

    if (sorted.length < 2) {
      return _Card(
        child: Text(l.chart_notEnough, style: TextStyle(color: p.inkMuted, height: 1.4)),
      );
    }
    final intervals = calc.buildIntervals(sorted);
    final rate = ref.watch(estimateProvider(source.id))?.dailyRate;
    final day = DateFormat.yMMMd(_locale(context));
    final from = day.format(sorted.first.date.toLocalMidnight());
    final to = day.format(sorted.last.date.toLocalMidnight());

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l.chart_stockTitle} · $unit', style: title),
          const SizedBox(height: 12),
          Semantics(
            label: l.chart_stockSemantics(sorted.length, from, to),
            child: ExcludeSemantics(child: StockChart(measurements: sorted)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [
              _Legend(color: p.ember, label: l.chart_reading),
              _Legend(color: p.night, label: l.chart_refill),
            ],
          ),
          const SizedBox(height: 22),
          Text('${l.chart_rateTitle} · $unit', style: title),
          const SizedBox(height: 12),
          if (intervals.isEmpty)
            Text(l.chart_notEnough, style: TextStyle(color: p.inkMuted))
          else ...[
            Semantics(
              label: l.chart_rateSemantics(intervals.length),
              child: ExcludeSemantics(
                child: RateChart(
                  intervals: intervals,
                  firstDay: sorted.first.date,
                  lastDay: sorted.last.date,
                  estimateRate: rate,
                ),
              ),
            ),
            if (rate != null) ...[
              const SizedBox(height: 8),
              _Legend(color: p.night, label: l.chart_estimate, dashed: true),
            ],
          ],
        ],
      ),
    );
  }
}

/// Al posto dei grafici, senza il Pro: cosa sono e il badge che apre il paywall.
class _LockedCharts extends StatelessWidget {
  const _LockedCharts({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = ScortePalette.of(context);
    return Material(
      color: p.night,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.insights_outlined, color: p.ember, size: 34),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l.chart_lockedTitle,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.onNight),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const ProBadge(compact: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(l.chart_lockedBody, style: TextStyle(fontSize: 14, height: 1.35, color: p.onNightMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La porta verso acquisti e costi, col badge se manca il Pro.
class _PurchasesTile extends StatelessWidget {
  const _PurchasesTile({required this.onTap, required this.locked});

  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = ScortePalette.of(context);
    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: p.iconTile, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.euro_outlined, color: p.onIconTile),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.history_purchases, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink)),
                    Text(l.history_purchasesHint, style: TextStyle(fontSize: 13, color: p.inkMuted)),
                  ],
                ),
              ),
              if (locked) const ProBadge(compact: true),
              Icon(Icons.chevron_right, color: p.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
    decoration: BoxDecoration(color: ScortePalette.of(context).card, borderRadius: BorderRadius.circular(20)),
    child: child,
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.dashed = false});

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (dashed)
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Container(width: 4, height: 2, margin: const EdgeInsets.only(right: 2), color: color),
          ],
        )
      else
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: ScortePalette.of(context).inkMuted, fontSize: 12)),
    ],
  );
}

/// "OTTOBRE 2026", sopra le misure del mese.
class _MonthLabel extends StatelessWidget {
  const _MonthLabel({required this.date});

  final CivilDate date;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
    child: Text(
      DateFormat.yMMMM(_locale(context)).format(date.toLocalMidnight()).toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        color: ScortePalette.of(context).inkMuted,
      ),
    ),
  );
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: ColoredBox(
      color: ScortePalette.of(context).card,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            children[i],
          ],
        ],
      ),
    ),
  );
}

/// Una misura: la quantita', quanto e' cambiata dalla precedente, la lettura del manometro e
/// la nota. Si elimina scorrendo o col cestino (tutti e due con "Annulla").
class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({
    required this.row,
    required this.previous,
    required this.unitKey,
    required this.onDelete,
    super.key,
  });

  final StockMeasurement row;
  final StockMeasurement? previous;
  final String unitKey;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = ScortePalette.of(context);
    final locale = _locale(context);
    final date = row.civilDate.toLocalMidnight();
    final prev = previous;
    final details = <String>[
      if (prev != null && row.quantity > prev.quantity)
        l.history_refillDelta(formatAmount(l, unitKey, row.quantity - prev.quantity))
      else if (prev != null && row.quantity < prev.quantity)
        // U+2212, il meno tipografico: il trattino si confonde con un separatore.
        '−${formatAmount(l, unitKey, prev.quantity - row.quantity)}',
      if (row.enteredAs == EnteredAs.percentage.key && unitKey != FuelUnits.percent)
        l.history_gauge(formatQuantity(row.rawInput, locale)),
      if (row.note != null) row.note!,
    ];
    final refill = prev != null && row.quantity > prev.quantity;

    return Dismissible(
      key: ValueKey('m${row.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  Text('${row.civilDate.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.ink)),
                  Text(
                    DateFormat.E(locale).format(date),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatAmount(l, unitKey, row.quantity),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details.join(' · '),
                      style: TextStyle(fontSize: 13, color: refill ? p.onIconTile : p.inkMuted),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: l.common_delete,
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: p.inkMuted, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il limite del piano gratuito: quante misure piu' vecchie ci sono, e il paywall.
class _FreeLimitCard extends StatelessWidget {
  const _FreeLimitCard({required this.days, required this.hidden, required this.onTap});

  final int days;
  final int hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = ScortePalette.of(context);
    return Material(
      color: p.iconTile,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.history, color: p.onIconTile),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.history_freeLimitTitle(days), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
                    const SizedBox(height: 2),
                    Text(l.history_freeLimitBody(hidden), style: TextStyle(fontSize: 13, color: p.inkMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const ProBadge(compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

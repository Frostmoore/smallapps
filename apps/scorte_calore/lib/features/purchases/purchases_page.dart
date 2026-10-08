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
import '../../app/scorte_palette.dart';
import '../../data/database.dart';
import '../../domain/costs.dart';
import '../../l10n/generated/app_localizations.dart';
import 'purchase_editor_sheet.dart';

/// Apre gli acquisti della fonte [sourceId], passando dal paywall se manca il Pro.
///
/// ⚑ Il paywall prima di aprire e non solo il `ProGate` della rotta: chi tocca "Acquisti e
/// costi" senza Pro vede subito cosa compra, invece di una pagina col lucchetto. Il
/// `ProGate` in `app.dart` resta per le porte nuove (un deep link, un widget).
Future<void> openPurchases(BuildContext context, WidgetRef ref, int sourceId) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.statistics)) {
    final unlocked = await showScortePaywall(context, ref, highlight: FeatureKey.statistics);
    if (!unlocked || !context.mounted) return;
  }
  if (context.mounted) await context.push(Routes.purchasesOf(sourceId));
}

/// Centesimi in euro scritti come nella lingua: "364,00 €" in italiano, "€364.00" in
/// inglese. Con [decimals] 0 gli euro interi della cifra grande in testata.
String formatEuro(num cents, String locale, {int decimals = 2}) =>
    NumberFormat.simpleCurrency(locale: locale, name: 'EUR', decimalDigits: decimals).format(cents / 100);

/// Le righe `Purchase` nel modello dei costi.
List<PurchaseEntry> toPurchaseEntries(Iterable<Purchase> rows) => [
  for (final r in rows) PurchaseEntry(date: r.civilDate, quantity: r.quantity, totalCostCents: r.totalCostCents),
];

final _purchaseSourceProvider = StreamProvider.autoDispose.family<FuelSource?, int>(
  (ref, id) => ref.watch(repositoryProvider).watchSource(id),
);

final _purchasesProvider = StreamProvider.autoDispose.family<List<Purchase>, int>(
  (ref, id) => ref.watch(repositoryProvider).watchPurchases(sourceId: id),
);

/// Gli acquisti di una fonte, con la spesa della stagione e il costo medio per unita'
/// (develop_microapps.md F5.11). Pagina intera Pro: il router la avvolge in
/// `ProGate(feature: FeatureKey.statistics)`.
///
/// - In testata, su blu notte, la spesa dell'inverno corrente (o di quello appena finito, fra
///   aprile e settembre: `HeatingSeason.latest`).
/// - Sotto, prezzo medio per unita' (di tutti gli acquisti con un costo) e quantita' comprata
///   nell'inverno; poi gli inverni precedenti, uno per riga, per confrontarli.
/// - L'elenco degli acquisti, dal piu' recente: toccarne uno lo modifica, scorrerlo lo
///   elimina (con "Annulla").
class PurchasesPage extends ConsumerStatefulWidget {
  const PurchasesPage({required this.sourceId, super.key});

  final int sourceId;

  @override
  ConsumerState<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends ConsumerState<PurchasesPage> {
  /// ☠ Come nello storico: un `Dismissible` scartato deve sparire nello stesso frame, lo
  /// stream di Drift arriva dopo.
  final Set<int> _gone = {};

  Future<void> _delete(Purchase row) async {
    final l = L.of(context);
    final repo = ref.read(repositoryProvider);
    setState(() => _gone.add(row.id));
    await repo.deletePurchase(row.id);
    if (!mounted) return;
    MicroSnack.show(
      context,
      l.purchase_deleted,
      actionLabel: l.purchase_undo,
      onAction: () => unawaited(
        repo.addPurchase(
          sourceId: row.fuelSourceId,
          date: row.civilDate,
          quantity: row.quantity,
          totalCostCents: row.totalCostCents,
          supplier: row.supplier,
          note: row.note,
        ),
      ),
    );
  }

  void _edit(FuelSource source, List<Purchase> rows, [Purchase? row]) => unawaited(
    showPurchaseEditor(
      context,
      source,
      purchase: row,
      lastSupplier: rows.map((r) => r.supplier).nonNulls.firstOrNull,
      onDelete: row == null ? null : () => unawaited(_delete(row)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = ScortePalette.of(context);
    final sourceAsync = ref.watch(_purchaseSourceProvider(widget.sourceId));
    final source = sourceAsync.value;
    final all = ref.watch(_purchasesProvider(widget.sourceId)).value;
    final today = ref.watch(todayProvider);

    // Una fonte che non esiste (eliminata, o un deep link sbagliato): pagina vuota, non una
    // rotellina eterna.
    if (sourceAsync.hasValue && source == null) return Scaffold(appBar: AppBar());
    if (source == null || all == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    final rows = [for (final r in all) if (!_gone.contains(r.id)) r];
    final entries = toPurchaseEntries(rows);
    final season = HeatingSeason.latest(today);
    final seasonT = seasonTotals(entries, season);
    final overall = PurchaseTotals.of(entries);
    final previous = [for (final s in totalsBySeason(entries)) if (s.$1 != season) s];

    return Scaffold(
      appBar: AppBar(title: Text('${l.purchase_title} · ${source.name}')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: p.flame,
        foregroundColor: p.onFlame,
        onPressed: () => _edit(source, rows),
        icon: const Icon(Icons.add),
        label: Text(l.purchase_add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          _SeasonPanel(season: season, totals: seasonT),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _NumberTile(
                    value: overall.averageCentsPerUnit == null
                        ? '–'
                        : l.costs_perUnit(
                            formatEuro(
                              overall.averageCentsPerUnit!,
                              _locale(context),
                              // Il GPL e il gasolio costano meno di un euro al litro e si contano al millesimo.
                              decimals: overall.averageCentsPerUnit! < 100 ? 3 : 2,
                            ),
                            unitName(l, source.unit, 1),
                          ),
                    label: l.costs_averagePrice,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberTile(
                    value: formatAmount(l, source.unit, seasonT.quantity),
                    label: l.costs_seasonQuantity,
                  ),
                ),
              ],
            ),
          ),
          if (previous.isNotEmpty) ...[
            _SectionLabel(text: l.costs_seasonsTitle),
            _Card(
              children: [
                for (final (s, t) in previous)
                  ListTile(
                    title: Text(l.costs_seasonName(s.shortLabel), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
                    subtitle: Text(formatAmount(l, source.unit, t.quantity), style: TextStyle(color: p.inkMuted)),
                    trailing: Text(
                      formatEuro(t.totalCostCents, _locale(context)),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
                    ),
                  ),
              ],
            ),
          ],
          _SectionLabel(text: l.purchase_title.toUpperCase()),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.purchase_empty, textAlign: TextAlign.center, style: TextStyle(color: p.inkMuted, height: 1.4)),
            )
          else
            _Card(
              children: [
                for (final r in rows)
                  _PurchaseRow(
                    key: ValueKey(r.id),
                    row: r,
                    unitKey: source.unit,
                    onTap: () => _edit(source, rows, r),
                    onDelete: () => unawaited(_delete(r)),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          Text(l.costs_seasonRule, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: p.inkMuted)),
        ],
      ),
    );
  }
}

String _locale(BuildContext context) => Localizations.localeOf(context).toLanguageTag();

/// Il pannello blu notte: la spesa dell'inverno in grande.
class _SeasonPanel extends StatelessWidget {
  const _SeasonPanel({required this.season, required this.totals});

  final HeatingSeason season;
  final PurchaseTotals totals;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = ScortePalette.of(context);
    final cents = totals.totalCostCents;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: p.night, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.costs_seasonSpent(season.shortLabel),
            style: TextStyle(fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: p.emberLabel),
          ),
          const SizedBox(height: 8),
          Text(
            // Gli euro interi in grande: i centesimi di una stagione di pellet non dicono niente.
            formatEuro(cents, _locale(context), decimals: cents % 100 == 0 ? 0 : 2),
            style: TextStyle(fontSize: 48, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: p.ember),
          ),
          if (totals.uncostedCount > 0) ...[
            const SizedBox(height: 8),
            Text(l.costs_uncosted(totals.uncostedCount), style: TextStyle(fontSize: 13, color: p.onNightMuted)),
          ],
        ],
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = ScortePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.ink, height: 1.15)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: p.inkMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: ScortePalette.of(context).inkMuted),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Material(
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

/// Un acquisto: data, quantita', costo (o "senza costo"), fornitore.
class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow({required this.row, required this.unitKey, required this.onTap, required this.onDelete, super.key});

  final Purchase row;
  final String unitKey;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = ScortePalette.of(context);
    final locale = _locale(context);
    final cents = row.totalCostCents;
    final sub = [
      DateFormat.yMMMd(locale).format(row.civilDate.toLocalMidnight()),
      if (row.supplier != null) row.supplier!,
    ].join(' · ');
    return Dismissible(
      key: ValueKey('p${row.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onTap,
        title: Text(formatAmount(l, unitKey, row.quantity), style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
        subtitle: Text(sub, style: TextStyle(color: p.inkMuted)),
        trailing: Text(
          cents == null ? l.purchase_noCost : formatEuro(cents, locale),
          style: cents == null
              ? TextStyle(fontSize: 13, color: p.inkMuted)
              : TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
        ),
      ),
    );
  }
}

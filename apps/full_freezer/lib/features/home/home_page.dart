import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../domain/home_view.dart';
import '../../l10n/generated/app_localizations.dart';
import '../freezers/freezer_widgets.dart';
import '../items/quick_add_sheet.dart';
import 'item_row_tile.dart';

/// La home di Full Freezer (develop_microapps.md F4.4).
///
/// 1. Testata: freezer guardato (o "Tutti"), quanti prodotti, "N da usare presto" e, per un
///    freezer, la barra di riempimento.
/// 2. "Da usare prima": i prodotti watch/old, i piu' vecchi per primi, al massimo 5.
/// 3. "Tutto il resto": dal piu' vecchio al piu' nuovo.
/// 4. "Dove sono": i freezer con conteggio e riempimento.
/// 5. Il pulsante grande "Metti nel freezer".
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final view = ref.watch(homeViewProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            tooltip: l.home_addFreezer,
            icon: const Icon(Icons.add_home_work_outlined),
            onPressed: () => context.push(Routes.freezerNew),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(showQuickAdd(context, ref)),
        icon: const Icon(Icons.add),
        label: Text(l.home_add),
      ),
      body: view == null
          ? const SizedBox.shrink()
          : ListView(
              // Spazio in fondo: l'ultima riga non deve finire sotto il pulsante.
              padding: const EdgeInsets.fromLTRB(MicroSpacing.l, MicroSpacing.s, MicroSpacing.l, 112),
              children: [
                _Header(view: view),
                MicroSpacing.gapL,
                if (view.isEmpty)
                  MicroEmptyState(
                    icon: Icons.kitchen_outlined,
                    title: l.home_emptyTitle,
                    message: l.home_emptyBody,
                  ),
                if (view.useSoonTotal > 0) ...[
                  MicroSectionHeader(
                    title: l.home_useSoon,
                    count: '${view.useSoonTotal}',
                    trailing: view.useSoonTotal > view.useSoon.length
                        ? TextButton(
                            onPressed: () => context.push(Routes.useSoon),
                            child: Text(l.home_seeAll),
                          )
                        : null,
                  ),
                  for (final r in view.useSoon)
                    Padding(
                      padding: const EdgeInsets.only(bottom: MicroSpacing.xs),
                      child: ItemRowTile(row: r, showFreezer: view.selectedFreezer == null),
                    ),
                  MicroSpacing.gapL,
                ],
                if (view.rest.isNotEmpty) ...[
                  MicroSectionHeader(title: l.home_rest, count: '${view.rest.length}'),
                  for (final r in view.rest)
                    Padding(
                      padding: const EdgeInsets.only(bottom: MicroSpacing.xs),
                      child: ItemRowTile(row: r, showFreezer: view.selectedFreezer == null),
                    ),
                  MicroSpacing.gapL,
                ],
                MicroSectionHeader(title: l.home_where),
                for (final s in view.freezers) _FreezerRow(summary: s),
              ],
            ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.view});

  final HomeView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final freezers = ref.watch(freezersProvider).value ?? const <Freezer>[];
    final fill = view.selectedFill;

    return MicroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (freezers.length > 1)
            DropdownButton<int?>(
              value: view.selectedFreezer?.id,
              isDense: true,
              underline: const SizedBox.shrink(),
              style: text.titleMedium?.copyWith(color: scheme.onSurface),
              items: [
                DropdownMenuItem<int?>(value: null, child: Text(l.home_allFreezers)),
                for (final f in freezers) DropdownMenuItem<int?>(value: f.id, child: Text(f.name)),
              ],
              onChanged: (id) => unawaited(ref.read(selectedFreezerProvider.notifier).select(id)),
            )
          else
            Text(view.selectedFreezer?.name ?? '', style: text.titleMedium),
          MicroSpacing.gapXS,
          Text(l.home_itemCount(view.totalCount), style: text.bodyMedium),
          if (view.useSoonTotal > 0) ...[
            MicroSpacing.gapXS,
            Text(
              l.home_useSoonCount(view.useSoonTotal),
              style: text.titleSmall?.copyWith(color: scheme.warning, fontWeight: FontWeight.w700),
            ),
          ],
          if (fill != null) ...[
            MicroSpacing.gapM,
            FillBar(fill: fill),
          ],
        ],
      ),
    );
  }
}

class _FreezerRow extends StatelessWidget {
  const _FreezerRow({required this.summary});

  final FreezerSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final f = summary.freezer;
    return Padding(
      padding: const EdgeInsets.only(bottom: MicroSpacing.s),
      child: MicroCard(
        onTap: () => context.push(Routes.freezerOf(f.id)),
        child: Row(
          children: [
            FreezerSilhouette(iconKey: silhouetteKeyFor(f.modelKey), size: 44),
            MicroSpacing.hGapM,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.name, style: Theme.of(context).textTheme.titleSmall),
                  Text(l.home_itemCount(summary.count), style: Theme.of(context).textTheme.bodySmall),
                  MicroSpacing.gapXS,
                  FillBar(fill: summary.fill, height: 8),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// "Vedi tutti" di "Da usare prima": tutti i watch/old, i piu' vecchi per primi.
class UseSoonPage extends ConsumerWidget {
  const UseSoonPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final view = ref.watch(homeViewProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.home_useSoon)),
      body: view == null
          ? const SizedBox.shrink()
          : ListView(
              padding: MicroSpacing.page,
              children: [
                for (final r in view.useSoonAll)
                  Padding(
                    padding: const EdgeInsets.only(bottom: MicroSpacing.xs),
                    child: ItemRowTile(row: r, showFreezer: view.selectedFreezer == null),
                  ),
              ],
            ),
    );
  }
}

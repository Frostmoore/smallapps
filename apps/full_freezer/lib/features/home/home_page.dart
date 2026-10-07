import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/formats.dart';
import '../../app/freezer_palette.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../domain/home_view.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/ghiaccio.dart';
import '../freezers/freezer_widgets.dart';
import '../items/quick_add_sheet.dart';
import 'item_row_tile.dart';

/// La home di Full Freezer, interfaccia "A · Ghiaccio" (decisione del 2026-10-07).
///
/// 1. Testata blu notte: il freezer, quanti prodotti, il riempimento in grande con
///    l'asticella, e il bollino "N da usare".
/// 2. "Da usare prima": schede a due colonne con i giorni in grande (al massimo 4 + "vedi
///    tutti": le schede occupano il doppio di una riga).
/// 3. "Tutto il resto": righe con l'icona della categoria.
/// 4. "Dove sono": solo con piu' di un freezer (con uno solo, la testata e' il freezer).
/// 5. Il pulsante largo "Metti nel freezer", fisso in fondo.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = FreezerPalette.of(context);
    final view = ref.watch(homeViewProvider);
    final compartments = ref.watch(compartmentsByFreezerProvider).value ?? const <int, List<Compartment>>{};
    String? compartmentName(Item i) {
      if (i.compartmentId == null) return null;
      for (final c in compartments[i.freezerId] ?? const <Compartment>[]) {
        if (c.id == i.compartmentId) return c.name;
      }
      return null;
    }

    // La testata e' blu notte: icone chiare nella barra di stato, anche nel tema chiaro.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
      body: view == null
          ? const SizedBox.shrink()
          : Stack(
              children: [
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _NightHeader(view: view),
                    if (view.isEmpty) _EmptyHint(),
                    if (view.useSoonTotal > 0) ...[
                      GhiaccioSectionLabel(
                        text: l.home_useSoon,
                        trailing: view.useSoonTotal > _cardsShown
                            ? TextButton(
                                onPressed: () => context.push(Routes.useSoon),
                                child: Text(l.home_seeAll),
                              )
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _CardGrid(
                          children: [
                            for (final r in view.useSoonAll.take(_cardsShown))
                              UseSoonCard(
                                row: r,
                                subtitle: itemSubtitle(
                                  context,
                                  r,
                                  showFreezer: view.selectedFreezer == null,
                                  compartment: compartmentName(r.item),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (view.rest.isNotEmpty) ...[
                      GhiaccioSectionLabel(text: '${l.home_rest} · ${view.rest.length}'),
                      for (final r in view.rest)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                          child: ItemRowTile(
                            row: r,
                            subtitle: itemSubtitle(
                              context,
                              r,
                              showFreezer: view.selectedFreezer == null,
                              compartment: compartmentName(r.item),
                            ),
                          ),
                        ),
                    ],
                    if (view.freezers.length > 1) ...[
                      GhiaccioSectionLabel(text: l.home_where),
                      for (final s in view.freezers) _FreezerRow(summary: s),
                    ],
                    // Spazio per il pulsante fisso in fondo.
                    const SizedBox(height: 112),
                  ],
                ),
                // Sotto la barra di stato resta sempre il blu notte: scorrendo, il contenuto
                // non deve finire sotto l'ora e la batteria.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: MediaQuery.paddingOf(context).top,
                  child: ColoredBox(color: p.night),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18 + MediaQuery.paddingOf(context).bottom,
                  child: _AddButton(
                    label: l.home_add,
                    onPressed: () => unawaited(showQuickAdd(context, ref)),
                    palette: p,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

/// Quante schede di "Da usare prima" si mostrano prima del "vedi tutti".
const int _cardsShown = 4;

/// La testata blu notte.
class _NightHeader extends ConsumerWidget {
  const _NightHeader({required this.view});

  final HomeView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = FreezerPalette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final freezers = ref.watch(freezersProvider).value ?? const <Freezer>[];
    final fill = view.selectedFill;
    final selected = view.selectedFreezer;
    final title = selected?.name ?? l.home_allFreezers;

    return Container(
      decoration: BoxDecoration(
        color: p.night,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(22, MediaQuery.paddingOf(context).top + 18, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FreezerPicker(title: title, freezers: freezers, selectedId: selected?.id),
                    const SizedBox(height: 2),
                    Text(
                      l.home_itemCount(view.totalCount),
                      style: TextStyle(
                        color: p.onNight,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              _NightIconButton(
                tooltip: l.home_addFreezer,
                icon: Icons.add_home_work_outlined,
                onPressed: () => context.push(Routes.freezerNew),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (fill != null) ...[
                FillGauge(fill: fill, height: 92, track: p.nightRaised, color: p.gaugeFill),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: selected == null ? null : () => context.push(Routes.freezerOf(selected.id)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${fill.percent}'),
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
                        const SizedBox(height: 4),
                        Text(
                          l.fill_headerLine(
                            formatLiters(fill.usedLiters, locale),
                            formatLiters(fill.usableLiters, locale),
                          ),
                          style: TextStyle(color: p.onNightMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                Expanded(
                  child: Text(
                    l.home_allFreezersHint,
                    style: TextStyle(color: p.onNightMuted, fontSize: 14),
                  ),
                ),
              if (view.useSoonTotal > 0) ...[
                const SizedBox(width: 12),
                _Badge(count: view.useSoonTotal, label: l.home_badgeLabel),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Il nome del freezer guardato; con piu' freezer e' un menu per cambiarlo.
class _FreezerPicker extends ConsumerWidget {
  const _FreezerPicker({required this.title, required this.freezers, required this.selectedId});

  final String title;
  final List<Freezer> freezers;
  final int? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = FreezerPalette.of(context);
    final label = Text(
      title.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: p.ice, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6),
    );
    if (freezers.length < 2) return label;
    return PopupMenuButton<int?>(
      tooltip: l.home_allFreezers,
      padding: EdgeInsets.zero,
      onSelected: (id) => unawaited(ref.read(selectedFreezerProvider.notifier).select(id == -1 ? null : id)),
      itemBuilder: (_) => [
        PopupMenuItem<int?>(value: -1, child: Text(l.home_allFreezers)),
        for (final f in freezers) PopupMenuItem<int?>(value: f.id, child: Text(f.name)),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: label),
          Icon(Icons.expand_more, size: 18, color: p.ice),
        ],
      ),
    );
  }
}

class _NightIconButton extends StatelessWidget {
  const _NightIconButton({required this.tooltip, required this.icon, required this.onPressed});

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = FreezerPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.nightRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.nightBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox.square(dimension: 44, child: Icon(icon, size: 20, color: p.onNight)),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = FreezerPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: p.badge, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(color: p.onBadge, fontSize: 24, fontWeight: FontWeight.w800, height: 1),
          ),
          Text(label, style: TextStyle(color: p.onBadge, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Due colonne di schede di altezza uguale per riga.
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: 10),
              Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox.shrink()),
            ],
          ),
        ),
      );
      if (i + 2 < children.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }
}

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = FreezerPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 0),
      child: Column(
        children: [
          Icon(Icons.ac_unit, size: 48, color: p.accent),
          const SizedBox(height: 16),
          Text(
            l.home_emptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.ink, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            l.home_emptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.inkMuted, fontSize: 15, height: 1.4),
          ),
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
    final p = FreezerPalette.of(context);
    final f = summary.freezer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Material(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push(Routes.freezerOf(f.id)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                FreezerSilhouette(iconKey: silhouetteKeyFor(f.modelKey), size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name, style: TextStyle(color: p.ink, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(l.home_itemCount(summary.count), style: TextStyle(color: p.inkMuted, fontSize: 12)),
                      const SizedBox(height: 6),
                      FillBar(fill: summary.fill, height: 8),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: p.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onPressed, required this.palette});

  final String label;
  final VoidCallback onPressed;
  final FreezerPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: palette.accent.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: palette.accent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 24, color: palette.onAccent),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(color: palette.onAccent, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
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
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                _CardGrid(
                  children: [
                    for (final r in view.useSoonAll)
                      UseSoonCard(
                        row: r,
                        subtitle: itemSubtitle(context, r, showFreezer: view.selectedFreezer == null),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

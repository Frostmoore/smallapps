import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../data/database.dart';
import '../../domain/film_types.dart';
import '../../l10n/generated/app_localizations.dart';
import 'custom_stock_sheet.dart';

/// Il catalogo delle pellicole (F6.4): ricerca, gruppi per marca, ISO e processo di ognuna.
///
/// Le pellicole **personalizzate** si creano, si modificano e si cancellano da qui; quelle
/// del catalogo no (il repository lo rifiuta comunque), e la pagina non offre nemmeno il
/// menu. ⚑ Si mostrano tutte e due nella stessa lista, con un'etichetta sulle personalizzate:
/// chi cerca "Portra" non deve sapere in quale delle due liste sta.
class StocksPage extends ConsumerStatefulWidget {
  const StocksPage({super.key});

  @override
  ConsumerState<StocksPage> createState() => _StocksPageState();
}

class _StocksPageState extends ConsumerState<StocksPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Una pellicola corrisponde se marca, nome, "marca nome" o ISO contengono la ricerca.
  bool _matches(FilmStock s, String q) {
    if (q.isEmpty) return true;
    final full = '${s.brand} ${s.name}'.toLowerCase();
    return full.contains(q) || '${s.iso}' == q;
  }

  Future<void> _delete(FilmStock stock) async {
    final l = L.of(context);
    final ok = await MicroConfirmSheet.show(
      context,
      title: l.stock_deleteTitle('${stock.brand} ${stock.name}'),
      message: l.stock_deleteBody,
      confirmLabel: l.common_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await ref.read(repositoryProvider).deleteCustomStock(stock.id);
    if (mounted) MicroSnack.show(context, l.stock_deleted);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final stocks = ref.watch(filmStocksProvider);
    final q = _search.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: Text(l.stock_title)),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('stock_add'),
        onPressed: () => unawaited(showCustomStockSheet(context, ref)),
        icon: const Icon(Icons.add),
        label: Text(l.stock_add),
      ),
      body: stocks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final shown = [for (final s in all) if (_matches(s, q)) s];
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(MicroSpacing.l, MicroSpacing.s, MicroSpacing.l, MicroSpacing.s),
                sliver: SliverToBoxAdapter(
                  child: SearchBar(
                    controller: _search,
                    hintText: l.stock_search,
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (_search.text.isNotEmpty)
                        IconButton(
                          tooltip: l.common_cancel,
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(_search.clear),
                        ),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              if (shown.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: MicroEmptyState(
                    icon: Icons.search_off,
                    title: l.stock_noResults,
                    message: l.stock_noResultsBody,
                    actionLabel: l.stock_add,
                    onAction: () => unawaited(showCustomStockSheet(context, ref)),
                  ),
                )
              else
                SliverPadding(
                  // Spazio in fondo per il pulsante flottante.
                  padding: const EdgeInsets.only(bottom: 96),
                  sliver: SliverList.list(children: _grouped(context, shown)),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Le righe con l'intestazione di ogni marca. Il repository le da' gia' in ordine di marca
  /// e nome senza maiuscole, quindi basta aprire un gruppo a ogni cambio di marca.
  List<Widget> _grouped(BuildContext context, List<FilmStock> stocks) {
    final l = L.of(context);
    final out = <Widget>[];
    String? brand;
    for (final s in stocks) {
      if (s.brand.toLowerCase() != brand) {
        brand = s.brand.toLowerCase();
        out.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(MicroSpacing.l, MicroSpacing.l, MicroSpacing.l, 0),
            child: MicroSectionHeader(title: s.brand),
          ),
        );
      }
      out.add(_StockTile(stock: s, onEdit: () => unawaited(showEditCustomStockSheet(context, ref, s)), onDelete: () => unawaited(_delete(s)), l: l));
    }
    return out;
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.stock, required this.onEdit, required this.onDelete, required this.l});

  final FilmStock stock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final L l;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final process = FilmProcess.byKey(stock.process);
    final format = FilmFormat.byKey(stock.format);
    final details = [
      'ISO ${stock.iso}',
      if (process != null) processName(l, process),
      if (format != null) formatName(l, format),
    ].join(' · ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: MicroSpacing.l),
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: scheme.onSurfaceVariant,
        child: Text('${stock.iso}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
      title: Text(stock.name),
      subtitle: Text(details),
      onTap: stock.isCustom ? onEdit : null,
      trailing: !stock.isCustom
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(l.stock_customBadge),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l.common_edit)),
                    PopupMenuItem(value: 'delete', child: Text(l.common_delete)),
                  ],
                ),
              ],
            ),
    );
  }
}

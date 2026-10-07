import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/freezer_palette.dart';
import '../../app/providers.dart';
import '../../data/database.dart';
import '../../domain/aging.dart';
import '../../domain/home_view.dart';
import '../../domain/search.dart';
import '../../l10n/generated/app_localizations.dart';
import '../home/item_row_tile.dart';

/// La ricerca (develop_microapps.md F4.8): campo in alto, risultati mentre si scrive, con
/// dove sta ogni alimento e da quanti giorni.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = FreezerPalette.of(context);
    final items = ref.watch(storedItemsProvider).value ?? const <Item>[];
    final freezers = ref.watch(freezersProvider).value ?? const <Freezer>[];
    final compartments = ref.watch(compartmentsByFreezerProvider).value ?? const <int, List<Compartment>>{};
    final today = ref.watch(todayProvider);
    final found = searchItems(items, _query.text);
    final freezerName = {for (final f in freezers) f.id: f.name};
    String? compartmentName(Item i) {
      for (final c in compartments[i.freezerId] ?? const <Compartment>[]) {
        if (c.id == i.compartmentId) return c.name;
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l.search_hint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          if (_query.text.isNotEmpty)
            IconButton(
              tooltip: l.search_clear,
              icon: const Icon(Icons.close),
              onPressed: () => setState(_query.clear),
            ),
        ],
      ),
      body: _query.text.trim().isEmpty
          ? _Hint(text: l.search_empty, color: p.inkMuted)
          : found.isEmpty
          ? _Hint(text: l.search_noResults(_query.text.trim()), color: p.inkMuted)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              itemCount: found.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final item = found[i];
                final row = ItemRow(
                  item: item,
                  aging: const AgingCalculator().evaluate(
                    frozenAt: CivilDate.parse(item.frozenAt),
                    reminderAfterDays: item.reminderAfterDays,
                    categoryKey: item.category,
                    today: today,
                  ),
                  freezerName: freezerName[item.freezerId] ?? '',
                );
                return ItemRowTile(
                  row: row,
                  // Nella ricerca "dove sta" e' la risposta: freezer e scomparto sempre.
                  subtitle: itemSubtitle(
                    context,
                    row,
                    showFreezer: freezers.length > 1,
                    compartment: compartmentName(item),
                  ),
                );
              },
            ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 15, height: 1.4)),
  );
}

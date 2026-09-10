import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/waste_presets.dart';
import '../../features/rules/rule_summary.dart';
import '../../l10n/generated/app_localizations.dart';

/// L'elenco dei tipi di rifiuto del calendario attivo.
class WasteTypesPage extends ConsumerWidget {
  const WasteTypesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final bundle = ref.watch(activeBundleProvider).value;
    final types = bundle?.wasteTypes ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l.wasteTypes_title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.wasteTypeNew),
        icon: const Icon(Icons.add),
        label: Text(l.common_add),
      ),
      body: SafeArea(
        child: types.isEmpty
            ? MicroEmptyState(
                icon: Icons.delete_outline,
                title: l.wasteTypes_empty,
                message: l.wasteTypes_emptyHint,
                actionLabel: l.common_add,
                onAction: () => context.push(Routes.wasteTypeNew),
              )
            : ReorderableListView(
                padding: MicroSpacing.page,
                // ⚑ La maniglia è esplicita e sta a destra: il trascinamento con pressione
                // prolungata esiste di default ma non si vede, e una funzione che nessuno
                // scopre vale quanto una che non c'è. In più, sulla riga intera il tocco
                // lungo entrerebbe in conflitto col menu delle eccezioni (F3.7).
                buildDefaultDragHandles: false,
                onReorderItem: (oldIndex, newIndex) =>
                    _reorder(ref, types.map((t) => t.id).toList(), oldIndex, newIndex),
                children: [
                  for (var index = 0; index < types.length; index++)
                    Padding(
                      key: ValueKey(types[index].id),
                      padding: const EdgeInsets.only(bottom: MicroSpacing.s),
                      child: MicroCard(
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            Expanded(
                              child: MicroListTile(
                                title: types[index].name,
                                subtitle: _describeRule(context, ref, types[index].id),
                                leading: Icon(
                                  WasteIcons.resolve(types[index].iconKey),
                                  color: Color(types[index].colorValue),
                                ),
                                onTap: () =>
                                    context.push(Routes.wasteTypeEditOf(types[index].id)),
                              ),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(right: MicroSpacing.m),
                                child: Icon(
                                  Icons.drag_handle,
                                  color: Theme.of(context).colorScheme.mutedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  /// Applica lo spostamento di una voce e riscrive l'ordine di tutte.
  ///
  /// ☠ Il callback è `onReorderItem` e non `onReorder`: quest'ultimo consegna un
  /// `newIndex` già incrementato quando si trascina verso il basso, e chi non applica la
  /// correzione ottiene ogni spostamento in giù una posizione più avanti del punto in cui
  /// l'utente ha lasciato il dito. `onReorderItem` la applica al posto nostro ed è il
  /// motivo per cui `onReorder` è deprecato: qui l'indice arriva già buono.
  void _reorder(WidgetRef ref, List<int> ids, int oldIndex, int newIndex) {
    final reordered = [...ids];
    reordered.insert(newIndex, reordered.removeAt(oldIndex));
    ref.read(repositoryProvider).reorderWasteTypes(reordered);
  }

  /// Un riassunto della regola, letto dal bundle già in memoria.
  ///
  /// Non si interroga il database qui: il bundle contiene già le regole tradotte, e una
  /// query per riga trasformerebbe una lista di dieci voci in dieci letture.
  String _describeRule(BuildContext context, WidgetRef ref, int wasteTypeId) {
    final l = L.of(context);
    final bundle = ref.watch(activeBundleProvider).value;
    final rule = bundle?.rules.where((r) => r.wasteTypeId == wasteTypeId).firstOrNull;
    if (rule == null) return l.rules_empty;
    return describeRecurrence(context, rule.recurrence);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/formats.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../domain/capacity.dart';
import '../../domain/home_view.dart';
import '../../l10n/generated/app_localizations.dart';
import 'freezer_widgets.dart';

final compartmentsProvider = StreamProvider.family<List<Compartment>, int>(
  (ref, freezerId) => ref.watch(repositoryProvider).watchCompartments(freezerId),
);

/// Un freezer: quanto e' pieno, la taratura, gli scomparti (develop_microapps.md F4.6).
class FreezerPage extends ConsumerWidget {
  const FreezerPage({required this.freezerId, super.key});

  final int freezerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final freezers = ref.watch(freezersProvider).value ?? const <Freezer>[];
    final items = ref.watch(storedItemsProvider).value ?? const <Item>[];
    final freezer = freezers.where((f) => f.id == freezerId).firstOrNull;
    if (freezer == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final view = buildHomeView(
      freezers: [freezer],
      storedItems: items,
      selectedFreezerId: freezer.id,
      today: ref.watch(todayProvider),
    );
    final summary = view.freezers.single;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final text = Theme.of(context).textTheme;
    final compartments = ref.watch(compartmentsProvider(freezer.id)).value ?? const <Compartment>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(freezer.name),
        actions: [
          IconButton(
            tooltip: l.common_edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(Routes.freezerEditOf(freezer.id)),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') unawaited(_delete(context, ref, freezer, summary.count));
            },
            itemBuilder: (_) => [PopupMenuItem(value: 'delete', child: Text(l.freezer_delete))],
          ),
        ],
      ),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          MicroCard(
            child: Row(
              children: [
                FreezerSilhouette(iconKey: silhouetteKeyFor(freezer.modelKey), size: 72),
                MicroSpacing.hGapL,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.fill_percentBig(summary.fill.percent), style: text.headlineMedium),
                      MicroSpacing.gapXS,
                      Text(
                        l.fill_liters(
                          formatLiters(summary.fill.usedLiters, locale),
                          formatLiters(summary.fill.usableLiters, locale),
                        ),
                        style: text.bodyMedium,
                      ),
                      Text(l.home_itemCount(summary.count), style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          MicroSpacing.gapM,
          FillBar(fill: summary.fill, height: 14, showLabel: false),
          MicroSpacing.gapM,
          Text(
            '${freezerModelName(l, freezer.modelKey)} · ${formatLiters(freezer.capacityLiters, locale)}',
            style: text.bodySmall,
          ),
          MicroSpacing.gapM,
          OutlinedButton.icon(
            icon: const Icon(Icons.tune),
            label: Text(l.calibrate_button),
            onPressed: () => unawaited(_calibrate(context, ref, freezer, items)),
          ),
          if (freezer.calibration != 1.0)
            TextButton(
              onPressed: () => unawaited(ref.read(repositoryProvider).setCalibration(freezer.id, 1)),
              child: Text(l.calibrate_reset),
            ),
          MicroSpacing.gapXL,
          MicroSectionHeader(
            title: l.compartments_title,
            trailing: IconButton(
              tooltip: l.compartments_add,
              icon: const Icon(Icons.add),
              onPressed: () => unawaited(_addCompartment(context, ref, freezer.id)),
            ),
          ),
          if (compartments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: MicroSpacing.s),
              child: Text(l.compartments_empty, style: text.bodySmall),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: true,
              // onReorderItem da' l'indice di arrivo gia' corretto per l'elemento tolto.
              onReorderItem: (from, to) {
                final ids = [for (final c in compartments) c.id];
                final moved = ids.removeAt(from);
                ids.insert(to, moved);
                unawaited(ref.read(repositoryProvider).reorderCompartments(ids));
              },
              children: [
                for (final c in compartments)
                  ListTile(
                    key: ValueKey(c.id),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.view_agenda_outlined),
                    title: Text(c.name),
                    subtitle: Text(
                      l.home_itemCount(items.where((i) => i.compartmentId == c.id).length),
                    ),
                    onTap: () => unawaited(_renameCompartment(context, ref, c)),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _calibrate(BuildContext context, WidgetRef ref, Freezer f, List<Item> items) async {
    const est = CapacityEstimator();
    final liters = [for (final i in items) if (i.freezerId == f.id) i.volumeLiters];
    final current = est.fill(capacityLiters: f.capacityLiters, calibration: f.calibration, itemLiters: liters);
    final declared = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (_) => _CalibrateSheet(initial: current.fraction.clamp(0.0, 1.0)),
    );
    if (declared == null) return;
    // ☠ La taratura si calcola sulla stima GREZZA, non su quella gia' tarata (F4.3b).
    final factor = est.calibrate(
      estimatedFraction: est.rawFraction(capacityLiters: f.capacityLiters, itemLiters: liters),
      declaredFraction: declared,
    );
    await ref.read(repositoryProvider).setCalibration(f.id, factor);
  }

  Future<void> _addCompartment(BuildContext context, WidgetRef ref, int freezerId) async {
    final l = L.of(context);
    final name = await _askName(context, title: l.compartments_add, hint: l.compartments_hint);
    if (name == null) return;
    await ref.read(repositoryProvider).addCompartment(freezerId, name);
  }

  Future<void> _renameCompartment(BuildContext context, WidgetRef ref, Compartment c) async {
    final l = L.of(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l.common_rename),
              onTap: () => Navigator.of(sheet).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l.compartments_delete),
              subtitle: Text(l.compartments_deleteHint),
              onTap: () => Navigator.of(sheet).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    final repo = ref.read(repositoryProvider);
    if (result == 'delete') {
      await repo.deleteCompartment(c.id);
    } else if (result == 'rename') {
      final name = await _askName(context, title: l.common_rename, initial: c.name);
      if (name != null) await repo.renameCompartment(c.id, name);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Freezer f, int count) async {
    final l = L.of(context);
    final ok = await MicroConfirmSheet.show(
      context,
      title: l.freezer_deleteTitle(f.name),
      message: count == 0 ? l.freezer_deleteEmpty : l.freezer_deleteBody(count),
      confirmLabel: l.freezer_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    context.pop();
    await ref.read(repositoryProvider).deleteFreezer(f.id);
  }
}

Future<String?> _askName(BuildContext context, {required String title, String? hint, String? initial}) {
  final l = L.of(context);
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.of(dialog).pop(v.trim().isEmpty ? null : v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialog).pop(), child: Text(l.common_cancel)),
        FilledButton(
          onPressed: () {
            final v = controller.text.trim();
            Navigator.of(dialog).pop(v.isEmpty ? null : v);
          },
          child: Text(l.common_save),
        ),
      ],
    ),
  );
}

/// "Quanto e' pieno davvero?": uno slider, partendo da quello che l'app stima.
class _CalibrateSheet extends StatefulWidget {
  const _CalibrateSheet({required this.initial});

  final double initial;

  @override
  State<_CalibrateSheet> createState() => _CalibrateSheetState();
}

class _CalibrateSheetState extends State<_CalibrateSheet> {
  late double _value = (widget.initial * 20).round() / 20;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(MicroSpacing.l, 0, MicroSpacing.l, MicroSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.calibrate_title, style: text.titleMedium),
            MicroSpacing.gapXS,
            Text(l.calibrate_body, style: text.bodySmall),
            MicroSpacing.gapL,
            Text(l.fill_percentBig((_value * 100).round()), textAlign: TextAlign.center, style: text.headlineSmall),
            Slider(
              value: _value,
              divisions: 20,
              label: '${(_value * 100).round()}%',
              onChanged: (v) => setState(() => _value = v),
            ),
            MicroSpacing.gapM,
            MicroPrimaryButton(label: l.common_save, onPressed: () => Navigator.of(context).pop(_value)),
          ],
        ),
      ),
    );
  }
}

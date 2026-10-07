import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/formats.dart';
import '../../app/providers.dart';
import '../../data/database.dart';
import '../../domain/aging.dart';
import '../../domain/capacity.dart';
import '../../domain/units.dart';
import '../../l10n/generated/app_localizations.dart';
import 'item_draft.dart';
import 'item_photo.dart';
import 'item_pickers.dart';

/// L'inserimento completo e la modifica di un alimento (develop_microapps.md F4.5).
///
/// Con [itemId] modifica un alimento esistente; altrimenti ne crea uno partendo da
/// [draft] (quello che si era scritto nell'inserimento rapido) o da una bozza vuota.
///
class ItemEditPage extends ConsumerStatefulWidget {
  const ItemEditPage({this.itemId, this.draft, super.key});

  final int? itemId;
  final ItemDraft? draft;

  @override
  ConsumerState<ItemEditPage> createState() => _ItemEditPageState();
}

class _ItemEditPageState extends ConsumerState<ItemEditPage> {
  ItemDraft? _d;
  Item? _original;
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _note = TextEditingController();
  final _reminder = TextEditingController();
  bool _saving = false;

  /// Le foto scattate in questa pagina. Se l'utente esce senza salvare, o ne scatta una e
  /// poi un'altra, quelle non usate si cancellano: altrimenti restano file orfani che fanno
  /// crescere lo spazio occupato senza che nessuno capisca perche'.
  final Set<String> _photosTaken = <String>{};
  bool _saved = false;
  late final AppPaths _paths = ref.read(appPathsProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    ItemDraft d;
    final id = widget.itemId;
    if (id != null) {
      final item = await ref.read(repositoryProvider).itemById(id);
      if (item == null) {
        if (mounted) context.pop();
        return;
      }
      _original = item;
      d = ItemDraft.fromItem(item);
    } else {
      // Una foto scattata nel foglio rapido e' ora di questa pagina: se si esce senza
      // salvare, si cancella anche lei.
      final fromSheet = widget.draft?.photoPath;
      if (fromSheet != null) _photosTaken.add(fromSheet);
      d = widget.draft ??
          ItemDraft(
            freezerId: (ref.read(freezersProvider).value ?? const <Freezer>[]).first.id,
            frozenAt: ref.read(todayProvider),
          );
    }
    _name.text = d.name;
    // Senza separatori delle migliaia: e' un campo da modificare, non un testo da leggere.
    _quantity.text = d.quantity == d.quantity.roundToDouble()
        ? d.quantity.round().toString()
        : d.quantity.toString();
    _note.text = d.note ?? '';
    _reminder.text = d.reminderAfterDays?.toString() ?? '';
    if (mounted) setState(() => _d = d);
  }

  @override
  void dispose() {
    if (!_saved) {
      for (final photo in _photosTaken) {
        unawaited(deleteItemPhoto(_paths, photo));
      }
    }
    _name.dispose();
    _quantity.dispose();
    _note.dispose();
    _reminder.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final d = _d;
    if (d == null || !d.isValid || _saving) return;
    setState(() => _saving = true);
    d.note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final repo = ref.read(repositoryProvider);
    final original = _original;
    if (original == null) {
      await repo.addItem(d.toNewItem());
    } else {
      // Un cambio di posizione passa da moveItem, che scrive il movimento `moved`: con il
      // solo updateItem lo spostamento non lasciava traccia (regola 3 del repository,
      // trovato rileggendo il codice per l'atlante il 2026-10-07).
      if (original.freezerId != d.freezerId || original.compartmentId != d.compartmentId) {
        await repo.moveItem(original.id, freezerId: d.freezerId, compartmentId: d.compartmentId);
      }
      await repo.updateItem(d.applyTo(original));
    }
    _saved = true;
    // Le foto non piu' usate: quelle scattate e poi sostituite, e la vecchia se e' cambiata.
    final orfane = {..._photosTaken, ?original?.photoPath}..remove(d.photoPath);
    for (final photo in orfane) {
      await deleteItemPhoto(_paths, photo);
    }
    if (mounted) context.pop();
  }

  Future<void> _remove({required bool consumed}) async {
    final original = _original;
    if (original == null) return;
    final l = L.of(context);
    final repo = ref.read(repositoryProvider);
    await repo.removeItem(original.id, consumed: consumed);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(consumed ? l.item_consumed(original.name) : l.item_discarded(original.name)),
        action: SnackBarAction(label: l.common_undo, onPressed: () => unawaited(repo.undoRemoval(original.id))),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _duplicate() async {
    final original = _original;
    if (original == null) return;
    final l = L.of(context);
    await ref.read(repositoryProvider).duplicateAsToday(original.id, today: ref.read(todayProvider));
    if (!mounted) return;
    MicroSnack.success(context, l.item_duplicated(original.name));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final d = _d;
    if (d == null) return Scaffold(appBar: AppBar());
    final locale = Localizations.localeOf(context).toLanguageTag();
    final text = Theme.of(context).textTheme;
    final freezers = ref.watch(freezersProvider).value ?? const <Freezer>[];
    final compartments = ref.watch(compartmentsByFreezerProvider).value ?? const <int, List<Compartment>>{};
    final freezer = freezers.where((f) => f.id == d.freezerId).firstOrNull;
    final compartment =
        (compartments[d.freezerId] ?? const <Compartment>[]).where((c) => c.id == d.compartmentId).firstOrNull;
    final aging = const AgingCalculator().evaluate(
      frozenAt: d.frozenAt,
      reminderAfterDays: d.reminderAfterDays,
      categoryKey: d.category,
      today: ref.watch(todayProvider),
    );
    final defaultReminder = const AgingCalculator().defaultReminderFor(d.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(_original == null ? l.item_newTitle : l.item_editTitle),
        actions: [
          if (_original != null)
            PopupMenuButton<String>(
              onSelected: (v) => unawaited(switch (v) {
                'duplicate' => _duplicate(),
                'discard' => _remove(consumed: false),
                _ => _remove(consumed: true),
              }),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'duplicate', child: Text(l.item_duplicate)),
                // Un alimento gia' uscito non si consuma una seconda volta.
                if (_original!.status == ItemStatus.stored) ...[
                  PopupMenuItem(value: 'consume', child: Text(l.item_consume)),
                  PopupMenuItem(value: 'discard', child: Text(l.item_discard)),
                ],
              ],
            ),
        ],
      ),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          // Un alimento uscito (dallo storico, F4.7): lo si dice e lo si puo' rimettere dentro.
          if (_original case final o? when o.status != ItemStatus.stored)
            Padding(
              padding: const EdgeInsets.only(bottom: MicroSpacing.m),
              child: MicroCard(
                child: Row(
                  children: [
                    Icon(o.status == ItemStatus.consumed ? Icons.check_circle_outline : Icons.delete_outline),
                    MicroSpacing.hGapM,
                    Expanded(
                      child: Text(o.status == ItemStatus.consumed ? l.item_wasConsumed : l.item_wasDiscarded),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref.read(repositoryProvider).undoRemoval(o.id);
                        if (context.mounted) context.pop();
                      },
                      child: Text(l.item_putBack),
                    ),
                  ],
                ),
              ),
            ),
          // F4.5b: la foto, gratis. In cima perche' e' la cosa che si riconosce piu' in fretta.
          ItemPhotoEditor(
            photoPath: d.photoPath,
            onChanged: (path) => setState(() {
              if (path != null) _photosTaken.add(path);
              d.photoPath = path;
            }),
          ),
          MicroSpacing.gapM,
          TextField(
            controller: _name,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.quickAdd_nameLabel),
            onChanged: (v) => setState(() => d.setName(v)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: categoryGlyph(d.category),
            title: Text(l.item_category),
            subtitle: Text(categoryName(l, d.category, ref.watch(customCategoriesProvider).value ?? const [])),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final choice = await chooseCategory(context, ref, d.category);
              if (choice == null) return;
              final (key, reminder) = choice;
              setState(() {
                d.setCategory(key.isEmpty ? null : key);
                if (reminder != null) {
                  d.reminderAfterDays = reminder;
                  _reminder.text = '$reminder';
                }
              });
            },
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l.item_quantity),
                  onChanged: (v) {
                    final q = parseUserNumber(v);
                    if (q != null && q > 0) setState(() => d.quantity = q);
                  },
                ),
              ),
              MicroSpacing.hGapM,
              DropdownButton<String>(
                value: d.unit,
                items: [
                  for (final u in Units.all) DropdownMenuItem(value: u, child: Text(unitName(l, u, d.quantity))),
                ],
                onChanged: (u) => setState(() => d.unit = u ?? d.unit),
              ),
            ],
          ),
          MicroSpacing.gapM,
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(l.item_frozenAt),
            subtitle: Text(
              '${DateFormat.yMMMMd(locale).format(d.frozenAt.toLocalMidnight())} · ${l.item_daysAgo(aging.days)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final today = ref.read(todayProvider);
              final picked = await showDatePicker(
                context: context,
                initialDate: d.frozenAt.toLocalMidnight(),
                firstDate: today.addYears(-5).toLocalMidnight(),
                lastDate: today.toLocalMidnight(),
              );
              if (picked != null) setState(() => d.frozenAt = CivilDate.fromDateTime(picked));
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.kitchen_outlined),
            title: Text(l.item_location),
            subtitle: Text(
              compartment == null ? (freezer?.name ?? '') : '${freezer?.name} · ${compartment.name}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await pickLocation(
                context,
                freezers: freezers,
                compartments: compartments,
                freezerId: d.freezerId,
                compartmentId: d.compartmentId,
              );
              if (picked != null) {
                setState(() {
                  d.freezerId = picked.freezerId;
                  d.compartmentId = picked.compartmentId;
                });
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(l.item_volume),
            subtitle: Text(
              d.volumeManual
                  ? l.item_volumeManual(formatLiters(d.volumeLiters, locale))
                  : l.item_volumeAuto(formatLiters(d.volumeLiters, locale)),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final choice = await pickSize(
                context,
                quantity: d.quantity,
                estimate: const CapacityEstimator().estimateLiters(
                  quantity: d.quantity,
                  unit: d.unit,
                  categoryKey: d.category,
                ),
                manual: d.volumeManual,
              );
              if (choice == null) return;
              setState(() {
                switch (choice) {
                  case SizeLiters(:final liters):
                    d.setManualVolume(liters);
                  case SizeAuto():
                    d.resetVolume();
                }
              });
            },
          ),
          MicroSpacing.gapS,
          TextField(
            controller: _reminder,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l.item_reminder,
              helperText: defaultReminder == null
                  ? l.item_reminderHelpNone
                  : l.item_reminderHelp(defaultReminder),
              helperMaxLines: 3,
              suffixText: l.item_reminderSuffix,
            ),
            onChanged: (v) {
              final n = int.tryParse(v.trim());
              setState(() => d.reminderAfterDays = (n != null && n > 0) ? n : null);
            },
          ),
          MicroSpacing.gapS,
          // F4.2, "Trappola di prodotto": il promemoria non e' una scadenza.
          Text(l.item_reminderDisclaimer, style: text.bodySmall),
          MicroSpacing.gapM,
          TextField(
            controller: _note,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.item_note),
          ),
          MicroSpacing.gapXL,
          MicroPrimaryButton(
            label: l.common_save,
            loading: _saving,
            onPressed: d.isValid ? () => unawaited(_save()) : null,
          ),
        ],
      ),
    );
  }
}

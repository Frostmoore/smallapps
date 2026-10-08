import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/formats.dart';
import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../data/database.dart';
import '../../l10n/generated/app_localizations.dart';

/// Apre il foglio per aggiungere ([purchase] null) o modificare un acquisto della fonte
/// [source] (F5.11): data, quantita' nell'unita' della fonte, costo totale in euro
/// facoltativo, fornitore e nota facoltativi.
///
/// [onDelete], se c'e', aggiunge il pulsante "Elimina": il foglio si chiude e la pagina fa
/// la cancellazione con il suo "Annulla" (lo snack deve vivere sulla pagina, non sul foglio
/// che sparisce). [lastSupplier] precompila il fornitore di un acquisto nuovo: di solito e'
/// lo stesso di ogni anno.
Future<void> showPurchaseEditor(
  BuildContext context,
  FuelSource source, {
  Purchase? purchase,
  String? lastSupplier,
  VoidCallback? onDelete,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _PurchaseEditor(source: source, purchase: purchase, lastSupplier: lastSupplier, onDelete: onDelete),
);

/// Gli euro digitati in centesimi interi: "420" -> 42000, "5,195" -> 520 (arrotondato al
/// centesimo). Null per un campo vuoto, un testo non numerico o un numero negativo.
///
/// ⚑ Il costo si salva in centesimi interi (`totalCostCents`) perche' le somme in `double`
/// sbagliano all'ultimo centesimo; si arrotonda qui, una volta sola, all'ingresso.
int? parseEuroCents(String input) {
  final v = parseUserNumber(input);
  if (v == null || v < 0 || v.isNaN || v.isInfinite) return null;
  return (v * 100).round();
}

class _PurchaseEditor extends ConsumerStatefulWidget {
  const _PurchaseEditor({required this.source, this.purchase, this.lastSupplier, this.onDelete});

  final FuelSource source;
  final Purchase? purchase;
  final String? lastSupplier;
  final VoidCallback? onDelete;

  @override
  ConsumerState<_PurchaseEditor> createState() => _PurchaseEditorState();
}

class _PurchaseEditorState extends ConsumerState<_PurchaseEditor> {
  final _quantity = TextEditingController();
  final _cost = TextEditingController();
  final _supplier = TextEditingController();
  final _note = TextEditingController();
  late CivilDate _date = widget.purchase?.civilDate ?? ref.read(todayProvider);
  bool _saving = false;
  bool _filled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Qui e non in initState: i numeri si scrivono con la virgola o il punto della lingua.
    if (_filled) return;
    _filled = true;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final p = widget.purchase;
    if (p != null) {
      _quantity.text = formatQuantity(p.quantity, locale);
      final cents = p.totalCostCents;
      if (cents != null) _cost.text = formatQuantity(cents / 100, locale);
      _supplier.text = p.supplier ?? '';
      _note.text = p.note ?? '';
    } else {
      _supplier.text = widget.lastSupplier ?? '';
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    _cost.dispose();
    _supplier.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _qty {
    final v = parseUserNumber(_quantity.text);
    // ⚑ Strettamente positiva, come vuole il CHECK di `purchases.quantity`.
    return v == null || v <= 0 || v.isNaN || v.isInfinite ? null : v;
  }

  /// Il costo e' valido se vuoto (facoltativo) o se e' un numero >= 0.
  bool get _costOk => _cost.text.trim().isEmpty || parseEuroCents(_cost.text) != null;

  bool get _valid => _qty != null && _costOk;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.toLocalMidnight(),
      firstDate: DateTime(2000),
      lastDate: ref.read(todayProvider).toLocalMidnight(),
    );
    if (picked != null) setState(() => _date = CivilDate.fromDateTime(picked));
  }

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final cents = _cost.text.trim().isEmpty ? null : parseEuroCents(_cost.text);
    final old = widget.purchase;
    if (old == null) {
      await repo.addPurchase(
        sourceId: widget.source.id,
        date: _date,
        quantity: _qty!,
        totalCostCents: cents,
        supplier: _supplier.text,
        note: _note.text,
      );
    } else {
      await repo.updatePurchase(
        old.copyWith(
          date: _date.toIso(),
          quantity: _qty,
          totalCostCents: Value(cents),
          supplier: Value(_supplier.text),
          note: Value(_note.text),
        ),
      );
    }
    if (!mounted) return;
    final l = L.of(context);
    Navigator.of(context).pop();
    MicroSnack.success(context, l.purchase_saved);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final editing = widget.purchase != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(MicroSpacing.l, 0, MicroSpacing.l, MicroSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${editing ? l.purchase_editTitle : l.purchase_newTitle} · ${widget.source.name}',
                style: text.titleLarge,
              ),
              MicroSpacing.gapS,
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(l.purchase_date),
                subtitle: Text(DateFormat.yMMMMd(locale).format(_date.toLocalMidnight())),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
              TextField(
                key: const ValueKey('purchase_quantity'),
                controller: _quantity,
                autofocus: !editing,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: text.headlineSmall,
                decoration: InputDecoration(
                  labelText: l.purchase_quantity,
                  suffixText: unitName(l, widget.source.unit, 2),
                ),
                onChanged: (_) => setState(() {}),
              ),
              MicroSpacing.gapM,
              TextField(
                key: const ValueKey('purchase_cost'),
                controller: _cost,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l.purchase_cost,
                  helperText: l.purchase_costHelp,
                  suffixText: '€',
                  errorText: _costOk ? null : ' ',
                ),
                onChanged: (_) => setState(() {}),
              ),
              MicroSpacing.gapM,
              TextField(
                key: const ValueKey('purchase_supplier'),
                controller: _supplier,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.purchase_supplier, helperText: l.common_optional),
              ),
              MicroSpacing.gapM,
              TextField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.purchase_note, helperText: l.common_optional),
              ),
              MicroSpacing.gapL,
              MicroPrimaryButton(
                label: l.common_save,
                loading: _saving,
                onPressed: _valid && !_saving ? () => unawaited(_save()) : null,
              ),
              if (editing && widget.onDelete != null) ...[
                MicroSpacing.gapS,
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onDelete!();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.common_delete),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

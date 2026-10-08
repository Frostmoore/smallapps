import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../data/database.dart';
import '../../l10n/generated/app_localizations.dart';
import 'lab_fields.dart';

/// Un ordine di stampa del rullino (F6.7): un rullino ne ha **N**, anche a mesi di distanza e
/// da laboratori diversi. [printId] null crea un ordine nuovo, altrimenti lo modifica.
///
/// Campi: laboratorio (con i nomi gia' usati), consegna, ritorno, formato ("10x15"), numero
/// di stampe, costo, nota. Salvando una stampa tornata, il rullino passa a `printed`
/// ([applySuggestedStatus]): stessa regola dello sviluppo, perche' il dettaglio del rullino
/// non deve dire "sviluppato" accanto a stampe gia' ritirate.
class PrintPage extends ConsumerStatefulWidget {
  const PrintPage({required this.rollId, this.printId, super.key});

  final int rollId;

  /// Null per un ordine nuovo.
  final int? printId;

  @override
  ConsumerState<PrintPage> createState() => _PrintPageState();
}

/// I formati di stampa piu' comuni, proposti come scorciatoie sotto il campo. Il campo resta
/// libero: i laboratori scrivono i formati ciascuno a modo suo.
const List<String> _commonPrintFormats = ['10x15', '13x18', '15x20', '20x30'];

class _PrintPageState extends ConsumerState<PrintPage> {
  final _laboratory = TextEditingController();
  final _format = TextEditingController();
  final _count = TextEditingController();
  final _cost = TextEditingController();
  final _note = TextEditingController();
  CivilDate? _submitted;
  CivilDate? _returned;

  /// L'ordine come letto, per `copyWith` al salvataggio.
  PrintOrder? _order;

  /// Null finche' non si e' letto; false se rullino o ordine non esistono.
  bool? _found;
  bool _saving = false;

  bool get _isNew => widget.printId == null;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final repo = ref.read(repositoryProvider);
    final roll = await repo.rollById(widget.rollId);
    final order = _isNew ? null : await repo.printById(widget.printId!);
    if (!mounted) return;
    // ⚑ Un ordine di un altro rullino (link costruito male) si tratta come inesistente: la
    // pagina salverebbe con il `filmRollId` dell'ordine e non con quello del percorso.
    final ok = roll != null && (_isNew || (order != null && order.filmRollId == widget.rollId));
    final locale = Localizations.localeOf(context).toLanguageTag();
    setState(() {
      _found = ok;
      if (!ok) return;
      if (order == null) {
        _submitted = ref.read(todayProvider);
        // Il laboratorio dell'ultima volta: di solito si stampa dove si sviluppa.
        final labs = ref.read(laboratoriesProvider).value;
        if (labs != null && labs.isNotEmpty) _laboratory.text = labs.first;
        return;
      }
      _order = order;
      _laboratory.text = order.laboratory ?? '';
      _submitted = order.submittedDate;
      _returned = order.returnedDate;
      _format.text = order.format ?? '';
      _count.text = order.numberOfPrints?.toString() ?? '';
      _cost.text = costCentsToText(order.costCents, locale);
      _note.text = order.note ?? '';
    });
  }

  @override
  void dispose() {
    for (final c in [_laboratory, _format, _count, _cost, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Il numero di stampe: vuoto (null) o un intero > 0, come vuole il CHECK dello schema.
  int? get _countValue => int.tryParse(_count.text.trim());

  bool get _countOk => _count.text.trim().isEmpty || (_countValue != null && _countValue! > 0);

  bool get _valid => _countOk && isCostTextValid(_cost.text);

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final l = L.of(context);
    final cents = parseCostCents(_cost.text);
    final old = _order;
    if (old == null) {
      await repo.addPrintOrder(
        rollId: widget.rollId,
        laboratory: _laboratory.text,
        submittedAt: _submitted,
        returnedAt: _returned,
        format: _format.text,
        numberOfPrints: _countValue,
        costCents: cents,
        note: _note.text,
      );
    } else {
      await repo.updatePrintOrder(
        old.copyWith(
          laboratory: Value(_laboratory.text),
          submittedAt: Value(_submitted?.toIso()),
          returnedAt: Value(_returned?.toIso()),
          format: Value(_format.text),
          numberOfPrints: Value(_countValue),
          costCents: Value(cents),
          note: Value(_note.text),
        ),
      );
    }
    final status = await applySuggestedStatus(repo, widget.rollId);
    if (!mounted) return;
    MicroSnack.success(context, status == null ? l.print_saved : labSavedMessage(l, status));
    // Se la pagina non si puo' chiudere (e' la prima della pila) torna modificabile.
    final closed = await Navigator.of(context).maybePop();
    if (!closed && mounted) setState(() => _saving = false);
  }

  Future<void> _delete() async {
    final l = L.of(context);
    final ok = await MicroConfirmSheet.show(
      context,
      title: l.print_deleteTitle,
      message: l.print_deleteBody,
      confirmLabel: l.common_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    // Come per lo sviluppo, lo stato del rullino non cambia da solo.
    await ref.read(repositoryProvider).deletePrintOrder(widget.printId!);
    if (!mounted) return;
    MicroSnack.show(context, l.print_deleted);
    await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final found = _found;
    if (found == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!found) {
      return Scaffold(
        appBar: AppBar(),
        body: MicroEmptyState(icon: Icons.help_outline, title: l.print_missingTitle, message: l.print_missingBody),
      );
    }
    final today = ref.watch(todayProvider);
    final labs = ref.watch(laboratoriesProvider).value ?? const <String>[];
    final earliest = CivilDate(1950, 1, 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l.print_newTitle : l.print_editTitle),
        actions: [
          if (!_isNew)
            IconButton(tooltip: l.common_delete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          SuggestionTextField(
            fieldKey: const ValueKey('print_laboratory'),
            controller: _laboratory,
            suggestions: labs,
            label: l.print_laboratory,
            helperText: l.common_optional,
            maxLength: 80,
          ),
          LabDateTile(
            key: const ValueKey('print_submitted'),
            label: l.print_submittedAt,
            icon: Icons.outbox_outlined,
            value: _submitted,
            firstDate: earliest,
            lastDate: _returned ?? today,
            onChanged: (d) => setState(() => _submitted = d),
          ),
          LabDateTile(
            key: const ValueKey('print_returned'),
            label: l.print_returnedAt,
            icon: Icons.move_to_inbox_outlined,
            value: _returned,
            firstDate: _submitted ?? earliest,
            lastDate: today,
            onChanged: (d) => setState(() => _returned = d),
          ),
          MicroSpacing.gapL,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  key: const ValueKey('print_format'),
                  controller: _format,
                  maxLength: 40,
                  decoration: InputDecoration(labelText: l.print_format, hintText: l.print_formatHint),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              MicroSpacing.hGapM,
              Expanded(
                flex: 2,
                child: TextField(
                  key: const ValueKey('print_count'),
                  controller: _count,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l.print_count,
                    errorText: _countOk ? null : l.print_countInvalid,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: MicroSpacing.s,
            children: [
              for (final f in _commonPrintFormats)
                ChoiceChip(
                  label: Text(f),
                  selected: _format.text.trim() == f,
                  onSelected: (_) => setState(() => _format.text = f),
                ),
            ],
          ),
          MicroSpacing.gapL,
          CostField(
            fieldKey: const ValueKey('print_cost'),
            controller: _cost,
            label: l.print_cost,
            onChanged: () => setState(() {}),
          ),
          MicroSpacing.gapM,
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(labelText: l.print_note, helperText: l.common_optional),
          ),
          MicroSpacing.gapXL,
          MicroPrimaryButton(
            label: l.common_save,
            loading: _saving,
            onPressed: _valid && !_saving ? () => unawaited(_save()) : null,
          ),
        ],
      ),
    );
  }
}

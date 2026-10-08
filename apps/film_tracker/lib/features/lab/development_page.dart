import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../data/database.dart';
import '../../domain/film_types.dart';
import '../../l10n/generated/app_localizations.dart';
import 'lab_fields.dart';

/// Lo sviluppo di un rullino (F6.7): **al massimo uno** per rullino. La stessa pagina lo crea
/// e lo modifica: `FilmRepository.saveDevelopment` sostituisce quello esistente.
///
/// Campi: laboratorio (con i nomi gia' usati), consegna, ritorno, costo dello sviluppo, costo
/// delle scansioni, processo (preimpostato da quello della pellicola), "sviluppato in casa",
/// nota. Salvando, il rullino passa allo stato che lo sviluppo suggerisce
/// ([applySuggestedStatus], dove sta il perche' lo si fa senza chiedere).
///
/// ⚑ **"Sviluppato in casa" nasconde laboratorio e consegna**: non c'e' un laboratorio a cui
/// consegnare, e uno sviluppo in casa si registra a cose fatte (`LabEvent.isReturned` lo
/// considera tornato con o senza date). Resta la data, chiamata "Sviluppato il", che e'
/// `returnedAt`: e' quella che la timeline del rullino mostra.
class DevelopmentPage extends ConsumerStatefulWidget {
  const DevelopmentPage({required this.rollId, super.key});

  final int rollId;

  @override
  ConsumerState<DevelopmentPage> createState() => _DevelopmentPageState();
}

class _DevelopmentPageState extends ConsumerState<DevelopmentPage> {
  final _laboratory = TextEditingController();
  final _devCost = TextEditingController();
  final _scanCost = TextEditingController();
  final _note = TextEditingController();
  CivilDate? _submitted;
  CivilDate? _returned;
  FilmProcess? _process;
  bool _selfDeveloped = false;

  /// C'e' gia' uno sviluppo salvato: mostra "Elimina".
  bool _exists = false;

  /// Null finche' non si e' letto; false se il rullino non esiste (cancellato, link vecchio).
  bool? _rollFound;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Legge una volta sola rullino, sviluppo e pellicola: e' un modulo, non una vista che
  /// segue il database (un aggiornamento a meta' compilazione cancellerebbe cio' che si scrive).
  Future<void> _load() async {
    final repo = ref.read(repositoryProvider);
    final roll = await repo.rollById(widget.rollId);
    if (!mounted) return;
    if (roll == null) {
      setState(() => _rollFound = false);
      return;
    }
    final dev = await repo.developmentFor(widget.rollId);
    final stockId = roll.filmStockId;
    final stock = dev == null && stockId != null ? await repo.stockById(stockId) : null;
    if (!mounted) return;
    final locale = Localizations.localeOf(context).toLanguageTag();
    setState(() {
      _rollFound = true;
      if (dev != null) {
        _exists = true;
        _laboratory.text = dev.laboratory ?? '';
        _submitted = dev.submittedDate;
        _returned = dev.returnedDate;
        _devCost.text = costCentsToText(dev.developmentCostCents, locale);
        _scanCost.text = costCentsToText(dev.scanCostCents, locale);
        _process = dev.processEnum;
        _selfDeveloped = dev.selfDeveloped;
        _note.text = dev.note ?? '';
      } else {
        // Uno sviluppo nuovo si registra di solito il giorno in cui si consegna il rullino.
        _submitted = ref.read(todayProvider);
        // Il processo della pellicola (C-41 per una Portra): F6.7. Si cambia per il
        // cross-processing o per una pellicola senza riga nel catalogo.
        _process = stock?.processEnum;
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_laboratory, _devCost, _scanCost, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => isCostTextValid(_devCost.text) && isCostTextValid(_scanCost.text);

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final l = L.of(context);
    await repo.saveDevelopment(
      rollId: widget.rollId,
      laboratory: _selfDeveloped ? null : _laboratory.text,
      submittedAt: _selfDeveloped ? null : _submitted,
      returnedAt: _returned,
      developmentCostCents: parseCostCents(_devCost.text),
      scanCostCents: parseCostCents(_scanCost.text),
      process: _process,
      selfDeveloped: _selfDeveloped,
      note: _note.text,
    );
    final status = await applySuggestedStatus(repo, widget.rollId);
    if (!mounted) return;
    // Lo snack prima di chiudere: lo ScaffoldMessenger e' quello dell'app e sopravvive alla
    // pagina, il context no.
    MicroSnack.success(context, labSavedMessage(l, status));
    // Se la pagina non si puo' chiudere (e' la prima della pila) torna modificabile.
    final closed = await Navigator.of(context).maybePop();
    if (!closed && mounted) {
      setState(() {
        _saving = false;
        _exists = true;
      });
    }
  }

  Future<void> _delete() async {
    final l = L.of(context);
    final ok = await MicroConfirmSheet.show(
      context,
      title: l.dev_deleteTitle,
      message: l.dev_deleteBody,
      confirmLabel: l.common_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    // ⚑ Lo stato del rullino non cambia: si cancella di solito uno sviluppo registrato per
    // sbaglio, e lo stato giusto lo sa solo l'utente (lo corregge dal dettaglio).
    await ref.read(repositoryProvider).deleteDevelopment(widget.rollId);
    if (!mounted) return;
    MicroSnack.show(context, l.dev_deleted);
    await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final text = Theme.of(context).textTheme;
    final found = _rollFound;
    if (found == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!found) {
      return Scaffold(
        appBar: AppBar(),
        body: MicroEmptyState(icon: Icons.help_outline, title: l.dev_rollMissingTitle, message: l.dev_rollMissingBody),
      );
    }
    final today = ref.watch(todayProvider);
    final labs = ref.watch(laboratoriesProvider).value ?? const <String>[];
    final earliest = CivilDate(1950, 1, 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(_exists ? l.dev_editTitle : l.dev_newTitle),
        actions: [
          if (_exists)
            IconButton(tooltip: l.common_delete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          SwitchListTile(
            key: const ValueKey('dev_self'),
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.science_outlined),
            title: Text(l.dev_selfDeveloped),
            subtitle: Text(l.dev_selfDevelopedHelp),
            value: _selfDeveloped,
            onChanged: (v) => setState(() => _selfDeveloped = v),
          ),
          MicroSpacing.gapS,
          if (!_selfDeveloped) ...[
            SuggestionTextField(
              fieldKey: const ValueKey('dev_laboratory'),
              controller: _laboratory,
              suggestions: labs,
              label: l.dev_laboratory,
              helperText: l.common_optional,
              maxLength: 80,
            ),
            LabDateTile(
              key: const ValueKey('dev_submitted'),
              label: l.dev_submittedAt,
              icon: Icons.outbox_outlined,
              value: _submitted,
              firstDate: earliest,
              lastDate: _returned ?? today,
              onChanged: (d) => setState(() => _submitted = d),
            ),
          ],
          LabDateTile(
            key: const ValueKey('dev_returned'),
            label: _selfDeveloped ? l.dev_developedOn : l.dev_returnedAt,
            icon: Icons.move_to_inbox_outlined,
            value: _returned,
            firstDate: (_selfDeveloped ? null : _submitted) ?? earliest,
            lastDate: today,
            onChanged: (d) => setState(() => _returned = d),
          ),
          MicroSpacing.gapL,
          Text(l.dev_process, style: text.titleSmall),
          MicroSpacing.gapS,
          Wrap(
            spacing: MicroSpacing.s,
            runSpacing: MicroSpacing.s,
            children: [
              for (final p in FilmProcess.values)
                ChoiceChip(
                  label: Text(processName(l, p)),
                  selected: p == _process,
                  // Un secondo tocco toglie la scelta: il processo e' facoltativo.
                  onSelected: (sel) => setState(() => _process = sel ? p : null),
                ),
            ],
          ),
          MicroSpacing.gapL,
          CostField(
            fieldKey: const ValueKey('dev_cost'),
            controller: _devCost,
            label: l.dev_developmentCost,
            onChanged: () => setState(() {}),
          ),
          MicroSpacing.gapM,
          CostField(
            fieldKey: const ValueKey('dev_scanCost'),
            controller: _scanCost,
            label: l.dev_scanCost,
            onChanged: () => setState(() {}),
          ),
          MicroSpacing.gapM,
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(labelText: l.dev_note, helperText: l.common_optional),
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

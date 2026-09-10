import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../domain/occurrence_engine.dart';
import '../../domain/recurrence.dart';
import '../../l10n/generated/app_localizations.dart';
import 'rule_summary.dart';
import 'weekday_labels.dart';

/// Il risultato dell'editor.
///
/// ⚑ Serve un tipo apposta perché due esiti diversi finirebbero altrimenti sullo stesso
/// valore: "ho annullato" e "ho tolto i giorni di raccolta" sono entrambi `null` se si
/// restituisce direttamente un `Recurrence?`. Chiudere la pagina col tasto indietro
/// cancellerebbe la regola esistente, che è esattamente il genere di perdita di dati
/// silenziosa che nessuno segnala come bug e tutti subiscono.
@immutable
class RuleEditorResult {
  const RuleEditorResult(this.recurrence);

  /// `null` significa "questo tipo di rifiuto non ha giorni di raccolta".
  final Recurrence? recurrence;
}

/// Le cinque forme che una regola può assumere.
enum _Kind { weekly, everyNWeeks, monthlyDay, monthlyNthWeekday, manual }

/// L'editor di una regola di ricorrenza, che cambia forma in base al tipo scelto.
///
/// ⚑ Perché l'anteprima live delle prossime sei date: "ogni due settimane a partire da
/// mercoledì 8" non è verificabile a mente. Mostrare le date mentre si modifica la regola
/// elimina la classe di errore più costosa dell'app, cioè un calendario configurato male che
/// manda notifiche sbagliate per mesi senza che l'utente capisca perché.
///
/// ⚑ Perché lavora su un valore e non sul database: l'editor viene aperto anche mentre si
/// crea un tipo di rifiuto che non esiste ancora e quindi non ha un id. Restituendo un
/// [Recurrence] al chiamante, la stessa pagina serve la creazione e la modifica, e nessuno
/// scrive righe che poi vanno ripulite se l'utente annulla.
class RuleEditorPage extends StatefulWidget {
  const RuleEditorPage({required this.typeName, this.accent, this.initial, super.key});

  final String typeName;
  final Color? accent;
  final Recurrence? initial;

  @override
  State<RuleEditorPage> createState() => _RuleEditorPageState();
}

class _RuleEditorPageState extends State<RuleEditorPage> {
  late _Kind _kind;
  Set<int> _weekdays = <int>{};
  int _intervalWeeks = 2;
  late CivilDate _anchor;
  int _dayOfMonth = 1;
  int _nth = 1;
  int _nthWeekday = DateTime.monday;
  final List<CivilDate> _manualDates = <CivilDate>[];
  late CivilDate _startDate;
  CivilDate? _endDate;

  @override
  void initState() {
    super.initState();
    final today = CivilDate.today();
    _anchor = today;
    _startDate = widget.initial?.startDate ?? today;
    _endDate = widget.initial?.endDate;

    switch (widget.initial) {
      case WeeklyRecurrence(:final weekdays):
        _kind = _Kind.weekly;
        _weekdays = <int>{...weekdays};
      case EveryNWeeksRecurrence(:final weekdays, :final intervalWeeks, :final anchor):
        _kind = _Kind.everyNWeeks;
        _weekdays = <int>{...weekdays};
        _intervalWeeks = intervalWeeks;
        _anchor = anchor;
      case MonthlyDayRecurrence(:final dayOfMonth):
        _kind = _Kind.monthlyDay;
        _dayOfMonth = dayOfMonth;
      case MonthlyNthWeekdayRecurrence(:final nth, :final weekday):
        _kind = _Kind.monthlyNthWeekday;
        _nth = nth;
        _nthWeekday = weekday;
      case ManualDatesRecurrence(:final dates):
        _kind = _Kind.manual;
        _manualDates.addAll(dates.toList()..sort());
      case null:
        _kind = _Kind.weekly;
    }
  }

  /// La regola descritta dallo stato corrente, o `null` se non è ancora completa.
  Recurrence? get _draft => switch (_kind) {
    _Kind.weekly => _weekdays.isEmpty
        ? null
        : WeeklyRecurrence(weekdays: _weekdays, startDate: _startDate, endDate: _endDate),
    _Kind.everyNWeeks => _weekdays.isEmpty
        ? null
        : EveryNWeeksRecurrence(
            weekdays: _weekdays,
            intervalWeeks: _intervalWeeks,
            anchorDate: _anchor,
            startDate: _startDate,
            endDate: _endDate,
          ),
    _Kind.monthlyDay => MonthlyDayRecurrence(
      dayOfMonth: _dayOfMonth,
      startDate: _startDate,
      endDate: _endDate,
    ),
    _Kind.monthlyNthWeekday => MonthlyNthWeekdayRecurrence(
      nth: _nth,
      weekday: _nthWeekday,
      startDate: _startDate,
      endDate: _endDate,
    ),
    // ☠ La data d'inizio delle date manuali è la più vecchia dell'elenco, non quella
    // ereditata dalla regola precedente: una data anteriore alla data d'inizio viene
    // scartata da Recurrence.occursOn, e l'utente vedrebbe sparire dall'anteprima una data
    // che ha appena aggiunto, senza spiegazione.
    _Kind.manual => _manualDates.isEmpty
        ? null
        : ManualDatesRecurrence(
            dates: _manualDates,
            startDate: _manualDates.reduce((a, b) => a.isBefore(b) ? a : b),
            endDate: _endDate,
          ),
  };

  List<CivilDate> get _preview {
    final draft = _draft;
    if (draft == null) return const <CivilDate>[];
    const engine = OccurrenceEngine();
    final rule = RuleWithExceptions(wasteTypeId: 0, recurrence: draft);
    return engine.nextN(6, rules: [rule]).map((o) => o.date).toList();
  }

  Future<void> _pickAnchor() async {
    final picked = await _pickDate(initial: _anchor);
    if (picked != null) setState(() => _anchor = picked);
  }

  Future<void> _addManualDate() async {
    final picked = await _pickDate(initial: _manualDates.isEmpty ? CivilDate.today() : _manualDates.last);
    if (picked == null) return;
    setState(() {
      if (!_manualDates.contains(picked)) {
        _manualDates
          ..add(picked)
          ..sort();
      }
    });
  }

  /// L'intervallo del selettore parte un anno indietro perché una regola a settimane
  /// alterne può avere l'ancora nel passato: è comunque la stessa fase del ciclo.
  Future<CivilDate?> _pickDate({required CivilDate initial}) async {
    final today = CivilDate.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.toLocalMidnight(),
      firstDate: today.addYears(-1).toLocalMidnight(),
      lastDate: today.addYears(3).toLocalMidnight(),
    );
    return picked == null ? null : CivilDate.fromDateTime(picked);
  }

  void _save() => Navigator.of(context).pop(RuleEditorResult(_draft));

  Future<void> _remove() async {
    final l = L.of(context);
    final confirmed = await MicroConfirmSheet.show(
      context,
      title: l.rules_remove,
      message: l.wasteTypes_deleteConfirmBody,
      confirmLabel: l.common_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    Navigator.of(context).pop(const RuleEditorResult(null));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final accent = widget.accent ?? theme.colorScheme.primary;
    final draft = _draft;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.typeName),
        actions: [
          if (widget.initial != null)
            IconButton(
              icon: const Icon(Icons.event_busy_outlined),
              tooltip: l.rules_remove,
              onPressed: _remove,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: MicroSpacing.page,
          children: [
            MicroSectionHeader(title: l.rules_kindLabel),
            Wrap(
              spacing: MicroSpacing.s,
              runSpacing: MicroSpacing.s,
              children: [
                for (final kind in _Kind.values)
                  MicroChip(
                    label: _kindLabel(l, kind),
                    selected: kind == _kind,
                    color: accent,
                    onTap: () => setState(() => _kind = kind),
                  ),
              ],
            ),
            MicroSpacing.gapXL,
            ..._bodyFor(_kind, l, accent),
            MicroSpacing.gapXL,
            MicroSectionHeader(title: l.rules_previewTitle),
            MicroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft == null ? l.rules_previewNone : l.rules_previewHelp,
                    style: theme.textTheme.cardMeta.copyWith(color: theme.colorScheme.mutedText),
                  ),
                  if (_preview.isNotEmpty) MicroSpacing.gapM,
                  for (final date in _preview)
                    Text(_formatDate(context, date), style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            MicroSpacing.gapXXL,
            MicroPrimaryButton(
              label: l.common_save,
              onPressed: draft == null ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _bodyFor(_Kind kind, L l, Color accent) => switch (kind) {
    _Kind.weekly => [
      MicroSectionHeader(title: l.rules_weekdaysLabel),
      WeekdayPicker(selected: _weekdays, color: accent, onToggle: _toggleWeekday),
    ],
    _Kind.everyNWeeks => [
      MicroSectionHeader(title: l.rules_weekdaysLabel),
      WeekdayPicker(selected: _weekdays, color: accent, onToggle: _toggleWeekday),
      MicroSpacing.gapXL,
      MicroSectionHeader(title: l.rules_intervalLabel),
      _Stepper(
        value: _intervalWeeks,
        min: 2,
        max: 12,
        onChanged: (v) => setState(() => _intervalWeeks = v),
      ),
      MicroSpacing.gapXL,
      MicroSectionHeader(title: l.rules_anchorLabel),
      MicroCard(
        padding: EdgeInsets.zero,
        child: MicroListTile(
          title: _formatDate(context, _anchor),
          subtitle: l.rules_anchorHelp,
          leading: const Icon(Icons.event_outlined),
          onTap: _pickAnchor,
        ),
      ),
    ],
    _Kind.monthlyDay => [
      MicroSectionHeader(title: l.rules_dayOfMonthLabel),
      Wrap(
        spacing: MicroSpacing.s,
        runSpacing: MicroSpacing.s,
        children: [
          for (var day = 1; day <= 31; day++)
            _NumberBox(
              value: day,
              selected: day == _dayOfMonth,
              color: accent,
              onTap: () => setState(() => _dayOfMonth = day),
            ),
        ],
      ),
    ],
    _Kind.monthlyNthWeekday => [
      MicroSectionHeader(title: l.rules_nthLabel),
      Wrap(
        spacing: MicroSpacing.s,
        runSpacing: MicroSpacing.s,
        children: [
          for (final nth in const [1, 2, 3, 4, -1])
            MicroChip(
              label: nthLabel(l, nth),
              selected: nth == _nth,
              color: accent,
              onTap: () => setState(() => _nth = nth),
            ),
        ],
      ),
      MicroSpacing.gapXL,
      MicroSectionHeader(title: l.rules_weekdaysLabel),
      // Qui il giorno è uno solo: toccarne un altro sostituisce, non aggiunge.
      WeekdayPicker(
        selected: <int>{_nthWeekday},
        color: accent,
        onToggle: (weekday) => setState(() => _nthWeekday = weekday),
      ),
    ],
    _Kind.manual => [
      MicroSectionHeader(title: l.rules_manualDatesLabel, count: '${_manualDates.length}'),
      if (_manualDates.isEmpty)
        Text(
          l.rules_manualEmpty,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.mutedText),
        )
      else
        MicroCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final date in _manualDates)
                MicroListTile(
                  title: _formatDate(context, date),
                  dense: true,
                  accent: accent,
                  onTap: () => setState(() => _manualDates.remove(date)),
                  trailingText: l.common_delete,
                ),
            ],
          ),
        ),
      MicroSpacing.gapM,
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _addManualDate,
          icon: const Icon(Icons.add),
          label: Text(l.rules_manualAdd),
        ),
      ),
    ],
  };

  void _toggleWeekday(int weekday) => setState(() {
    if (!_weekdays.remove(weekday)) _weekdays.add(weekday);
  });

  String _kindLabel(L l, _Kind kind) => switch (kind) {
    _Kind.weekly => l.rules_kindWeekly,
    _Kind.everyNWeeks => l.rules_kindEveryNWeeks(_intervalWeeks),
    _Kind.monthlyDay => l.rules_kindMonthlyDay,
    _Kind.monthlyNthWeekday => l.rules_kindMonthlyNthWeekday,
    _Kind.manual => l.rules_kindManual,
  };
}

String _formatDate(BuildContext context, CivilDate date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('EEEE d MMMM y', locale).format(date.toLocalMidnight());
}

/// Un contatore con meno e più, per l'intervallo di settimane.
///
/// Un campo di testo qui costringerebbe ad aprire la tastiera per cambiare 2 in 3, e a
/// gestire l'input non numerico. I valori utili sono pochi e contigui.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => MicroCard(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text('$value', style: Theme.of(context).textTheme.headlineSmall),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    ),
  );
}

/// Una casella numerata, per scegliere il giorno del mese.
class _NumberBox extends StatelessWidget {
  const _NumberBox({
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: MicroRadius.chip,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : scheme.surfaceContainerHighest,
          borderRadius: MicroRadius.chip,
        ),
        child: Text(
          '$value',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? MicroCard.foregroundOn(color) : scheme.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

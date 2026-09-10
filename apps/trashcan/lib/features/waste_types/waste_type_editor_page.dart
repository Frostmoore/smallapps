import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/waste_presets.dart';
import '../../domain/occurrence_engine.dart';
import '../../domain/recurrence.dart';
import '../../features/rules/rule_editor_page.dart';
import '../../features/rules/rule_summary.dart';
import '../../features/rules/weekday_labels.dart';
import '../../l10n/generated/app_localizations.dart';

/// Crea o modifica un tipo di rifiuto con i suoi giorni di raccolta.
///
/// ⚑ L'anteprima delle prossime sei date è la parte che conta davvero. "Ogni due
/// settimane a partire da mercoledì" è difficile da verificare mentalmente, e mostrare le
/// date mentre si modifica elimina la classe di errore più comune: un calendario
/// configurato male che manda notifiche sbagliate per mesi, senza che l'utente capisca
/// perché.
class WasteTypeEditorPage extends ConsumerStatefulWidget {
  const WasteTypeEditorPage({this.wasteTypeId, super.key});

  final int? wasteTypeId;

  @override
  ConsumerState<WasteTypeEditorPage> createState() => _WasteTypeEditorPageState();
}

class _WasteTypeEditorPageState extends ConsumerState<WasteTypeEditorPage> {
  final TextEditingController _name = TextEditingController();
  String _iconKey = 'trash';
  Color _color = WastePalette.colors.first;

  /// La regola in corso di modifica, non ancora scritta sul database.
  ///
  /// ⚑ Perché un [Recurrence] e non un semplice insieme di giorni: da qui si arriva anche
  /// alle regole a settimane alterne e a quelle mensili. Tenendo un solo campo, la riga di
  /// cerchietti dei giorni e l'editor completo modificano lo stesso valore e non possono
  /// dire due cose diverse. Se invece si tenesse un `Set<int>` accanto a un `Recurrence`,
  /// salvare dopo aver toccato prima uno e poi l'altro darebbe risultati che dipendono
  /// dall'ordine dei tocchi.
  Recurrence? _recurrence;

  bool _loaded = false;
  bool _saving = false;

  bool get _isNew => widget.wasteTypeId == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _loadOnce() {
    if (_loaded || _isNew) return;
    final bundle = ref.read(activeBundleProvider).value;
    final type = bundle?.typeOf(widget.wasteTypeId!);
    if (type == null) return;
    _name.text = type.name;
    _iconKey = type.iconKey;
    _color = Color(type.colorValue);
    _recurrence = bundle?.rules
        .where((r) => r.wasteTypeId == type.id)
        .firstOrNull
        ?.recurrence;
    _loaded = true;
  }

  Future<void> _save() async {
    final l = L.of(context);
    final calendar = ref.read(activeCalendarProvider);
    if (calendar == null) return;
    if (_name.text.trim().isEmpty) {
      MicroSnack.error(context, l.wasteTypes_nameLabel);
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final id = _isNew
        ? await repo.createWasteType(
            calendarId: calendar.id,
            name: _name.text.trim(),
            iconKey: _iconKey,
            colorValue: _color.toARGB32(),
          )
        : widget.wasteTypeId!;

    if (!_isNew) {
      await repo.updateWasteType(
        id,
        name: _name.text.trim(),
        iconKey: _iconKey,
        colorValue: _color.toARGB32(),
      );
    }

    // Nessuna regola significa "questo tipo esiste ma non ha ancora un calendario":
    // si cancella la regola invece di lasciarne una vuota, che non genererebbe nulla e
    // sarebbe indistinguibile da un difetto.
    final recurrence = _recurrence;
    if (recurrence == null) {
      await repo.clearRules(id);
    } else {
      await repo.setRule(wasteTypeId: id, recurrence: recurrence);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l = L.of(context);
    final confirmed = await MicroConfirmSheet.show(
      context,
      title: l.wasteTypes_deleteConfirmTitle(_name.text),
      message: l.wasteTypes_deleteConfirmBody,
      confirmLabel: l.common_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await ref.read(repositoryProvider).deleteWasteType(widget.wasteTypeId!);
    if (mounted) Navigator.of(context).pop();
  }

  /// Apre l'editor completo delle regole.
  ///
  /// ⚑ `Navigator.push` e non `go_router`: questo editor è un sotto-passaggio che
  /// restituisce un valore al chiamante, non una destinazione raggiungibile da un deep
  /// link. Dargli una rotta dichiarata significherebbe poterci arrivare da una notifica
  /// senza il tipo di rifiuto da modificare in mano.
  Future<void> _openRuleEditor() async {
    final l = L.of(context);
    final result = await Navigator.of(context).push<RuleEditorResult>(
      MaterialPageRoute(
        builder: (_) => RuleEditorPage(
          typeName: _name.text.trim().isEmpty ? l.rules_title : _name.text.trim(),
          accent: _color,
          initial: _recurrence,
        ),
      ),
    );
    if (result == null) return; // annullato: si tiene la regola che c'era
    setState(() => _recurrence = result.recurrence);
  }

  /// I giorni della settimana, quando la regola è settimanale.
  ///
  /// La riga di cerchietti si mostra solo per le regole settimanali, che sono la
  /// stragrande maggioranza. Per tutte le altre forme un insieme di giorni non basta a
  /// descrivere la regola, e mostrarlo lo stesso farebbe credere che modificarlo la
  /// cambi tutta.
  Set<int>? get _weeklyDays => switch (_recurrence) {
    WeeklyRecurrence(:final weekdays) => weekdays,
    null => const <int>{},
    _ => null,
  };

  void _toggleWeekday(int weekday) {
    final current = _weeklyDays;
    if (current == null) return;
    final next = <int>{...current};
    if (!next.remove(weekday)) next.add(weekday);
    setState(() {
      _recurrence = next.isEmpty
          ? null
          : WeeklyRecurrence(
              weekdays: next,
              startDate: _recurrence?.startDate ?? CivilDate.today(),
              endDate: _recurrence?.endDate,
            );
    });
  }

  /// Le prossime sei raccolte secondo la regola in corso di modifica.
  List<CivilDate> get _preview {
    final recurrence = _recurrence;
    if (recurrence == null) return const <CivilDate>[];
    const engine = OccurrenceEngine();
    final rule = RuleWithExceptions(wasteTypeId: 0, recurrence: recurrence);
    return engine.nextN(6, rules: [rule]).map((o) => o.date).toList();
  }

  @override
  Widget build(BuildContext context) {
    _loadOnce();
    final l = L.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weeklyDays = _weeklyDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l.wasteTypes_addTitle : l.wasteTypes_editTitle),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l.common_delete,
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: MicroSpacing.page,
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.wasteTypes_nameLabel),
            ),
            MicroSpacing.gapXL,
            MicroSectionHeader(title: l.wasteTypes_colourLabel),
            Wrap(
              spacing: MicroSpacing.s,
              runSpacing: MicroSpacing.s,
              children: [
                for (final color in WastePalette.colors)
                  InkWell(
                    onTap: () => setState(() => _color = color),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: color.toARGB32() == _color.toARGB32()
                            ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            MicroSpacing.gapXL,
            MicroSectionHeader(title: l.wasteTypes_iconLabel),
            Wrap(
              spacing: MicroSpacing.s,
              runSpacing: MicroSpacing.s,
              children: [
                for (final key in WasteIcons.allKeys)
                  InkWell(
                    onTap: () => setState(() => _iconKey = key),
                    borderRadius: MicroRadius.chip,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: key == _iconKey
                            ? _color
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: MicroRadius.chip,
                      ),
                      child: Icon(
                        WasteIcons.resolve(key),
                        size: 20,
                        color: key == _iconKey
                            ? MicroCard.foregroundOn(_color)
                            : theme.colorScheme.mutedText,
                      ),
                    ),
                  ),
              ],
            ),
            MicroSpacing.gapXL,
            MicroSectionHeader(
              title: l.rules_title,
              trailing: TextButton(
                onPressed: _openRuleEditor,
                child: Text(l.rules_advanced),
              ),
            ),
            if (weeklyDays != null)
              WeekdayPicker(selected: weeklyDays, color: _color, onToggle: _toggleWeekday)
            else
              MicroCard(
                padding: EdgeInsets.zero,
                child: MicroListTile(
                  // Niente sottotitolo: il riassunto e' gia' la riga che conta, e ripetere
                  // "Altre opzioni" sotto al bottone omonimo aggiunge rumore, non aiuto.
                  title: describeRecurrence(context, _recurrence!),
                  leading: const Icon(Icons.event_repeat_outlined),
                  accent: _color,
                  onTap: _openRuleEditor,
                ),
              ),
            if (_preview.isNotEmpty) ...[
              MicroSpacing.gapXL,
              MicroSectionHeader(title: l.rules_previewTitle),
              MicroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.rules_previewHelp,
                      style: theme.textTheme.cardMeta.copyWith(
                        color: theme.colorScheme.mutedText,
                      ),
                    ),
                    MicroSpacing.gapM,
                    for (final date in _preview)
                      Text(
                        DateFormat('EEEE d MMMM', locale).format(date.toLocalMidnight()),
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
            ],
            MicroSpacing.gapXXL,
            MicroPrimaryButton(label: l.common_save, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

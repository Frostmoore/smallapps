import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/waste_presets.dart';
import '../../domain/occurrence_engine.dart';
import '../../domain/recurrence.dart';
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
  Set<int> _weekdays = <int>{};
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
    final rule = bundle?.rules.where((r) => r.wasteTypeId == type.id).firstOrNull;
    final recurrence = rule?.recurrence;
    if (recurrence is WeeklyRecurrence) _weekdays = <int>{...recurrence.weekdays};
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

    // Nessun giorno scelto significa "questo tipo esiste ma non ha ancora un calendario":
    // si cancella la regola invece di lasciarne una vuota, che non genererebbe nulla e
    // sarebbe indistinguibile da un difetto.
    if (_weekdays.isEmpty) {
      await repo.clearRules(id);
    } else {
      await repo.setWeeklyRule(wasteTypeId: id, weekdays: _weekdays);
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

  /// Le prossime sei raccolte secondo la regola in corso di modifica.
  List<CivilDate> get _preview {
    if (_weekdays.isEmpty) return const <CivilDate>[];
    const engine = OccurrenceEngine();
    final rule = RuleWithExceptions(
      wasteTypeId: 0,
      recurrence: WeeklyRecurrence(weekdays: _weekdays, startDate: CivilDate.today()),
    );
    return engine.nextN(6, rules: [rule]).map((o) => o.date).toList();
  }

  @override
  Widget build(BuildContext context) {
    _loadOnce();
    final l = L.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

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
                        color: key == _iconKey ? _color : theme.colorScheme.surfaceContainerHighest,
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
            MicroSectionHeader(title: l.rules_weekdaysLabel),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
                  _DayCircle(
                    label: _weekdayInitial(locale, weekday),
                    selected: _weekdays.contains(weekday),
                    color: _color,
                    onTap: () => setState(() {
                      if (!_weekdays.remove(weekday)) _weekdays.add(weekday);
                    }),
                  ),
              ],
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
                      style: theme.textTheme.cardMeta.copyWith(color: theme.colorScheme.mutedText),
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

/// L'iniziale del giorno nella lingua del dispositivo.
///
/// ☠ In inglese lunedì e martedì iniziano entrambi per M, e giovedì e martedì per T: con
/// una sola lettera due colonne su sette diventano indistinguibili. In italiano una
/// lettera basta e sta meglio su schermi stretti.
String _weekdayInitial(String locale, int weekday) {
  // 2026-09-07 è un lunedì: sommando il giorno della settimana si ottiene la data giusta.
  final sample = DateTime(2026, 9, 6 + weekday);
  final name = DateFormat('EEEE', locale).format(sample);
  return name.substring(0, locale.startsWith('it') ? 1 : 2).toUpperCase();
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: MicroDuration.quick,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? color : scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? MicroCard.foregroundOn(color) : scheme.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

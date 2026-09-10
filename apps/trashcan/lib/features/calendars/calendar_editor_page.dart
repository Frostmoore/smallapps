import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/trashcan_scheduler.dart';

/// Crea o rinomina un calendario, e ne imposta l'orario del promemoria.
class CalendarEditorPage extends ConsumerStatefulWidget {
  const CalendarEditorPage({this.calendarId, super.key});

  final int? calendarId;

  @override
  ConsumerState<CalendarEditorPage> createState() => _CalendarEditorPageState();
}

class _CalendarEditorPageState extends ConsumerState<CalendarEditorPage> {
  final TextEditingController _name = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _loaded = false;
  bool _saving = false;

  bool get _isNew => widget.calendarId == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _loadOnce() {
    if (_loaded) return;
    if (_isNew) {
      _loaded = true;
      return;
    }
    final calendar = ref
        .read(calendarsProvider)
        .value
        ?.where((c) => c.id == widget.calendarId)
        .firstOrNull;
    if (calendar == null) return;
    _name.text = calendar.name;
    _time = parseTime(calendar.notificationTime) ?? _time;
    _loaded = true;
  }

  Future<void> _save() async {
    final l = L.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      MicroSnack.error(context, l.calendars_nameLabel);
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    if (_isNew) {
      final id = await repo.createCalendar(name: name, notificationTime: formatTime(_time));
      // Il calendario appena creato diventa quello attivo: chi lo crea vuole configurarlo,
      // e lasciarlo dietro a quello di prima costringerebbe a un passaggio in piu' che
      // nessuno si aspetta.
      ref.read(selectedCalendarProvider.notifier).select(id);
    } else {
      await repo.renameCalendar(widget.calendarId!, name);
      await repo.setCalendarNotification(widget.calendarId!, time: formatTime(_time));
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l = L.of(context);
    final confirmed = await MicroConfirmSheet.show(
      context,
      title: l.calendars_deleteConfirmTitle(_name.text),
      message: l.calendars_deleteConfirmBody,
      confirmLabel: l.common_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!confirmed) return;
    // Si toglie prima la selezione: cancellare il calendario attivo lascerebbe per un
    // istante un id che non esiste piu', e la home leggerebbe un pacchetto nullo.
    ref.read(selectedCalendarProvider.notifier).select(null);
    await ref.read(repositoryProvider).deleteCalendar(widget.calendarId!);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    _loadOnce();
    final l = L.of(context);
    final count = ref.watch(calendarsProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l.calendars_addTitle : l.calendars_editTitle),
        actions: [
          // L'ultimo calendario non si cancella: senza, la home non avrebbe niente da
          // mostrare e l'app tornerebbe al wizard iniziale come se fosse appena installata.
          if (!_isNew && count > 1)
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
              autofocus: _isNew,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.calendars_nameLabel),
            ),
            MicroSpacing.gapXL,
            MicroSectionHeader(title: l.notifications_timeLabel),
            MicroCard(
              padding: EdgeInsets.zero,
              child: MicroListTile(
                title: formatTime(_time),
                subtitle: l.onboarding_notificationHelp,
                leading: const Icon(Icons.schedule),
                onTap: _pickTime,
              ),
            ),
            MicroSpacing.gapXXL,
            MicroPrimaryButton(label: l.common_save, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

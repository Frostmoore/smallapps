import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/paywall_config.dart';
import '../../app/scorte_palette.dart';
import '../../data/database.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/calendar_providers.dart';
import '../../services/calendar_sync.dart';

/// La riga del calendario sotto il riquadro del riordino, nella testata della home.
///
/// Tre stati:
/// - nessun evento → "Aggiungi al calendario" (con il badge Pro se serve);
/// - evento allineato alla stima → "Nel calendario", il tocco offre di toglierlo;
/// - stima spostata di piu' di 3 giorni → la frase che lo dice e "Aggiorna evento".
///   ⚑ E' questa la "proposta" di F5.10: l'evento si sposta solo dopo il tocco.
class CalendarReminderBar extends ConsumerWidget {
  const CalendarReminderBar({required this.source, required this.reorderDate, this.depletionDate, super.key});

  final FuelSource source;
  final CivilDate reorderDate;
  final CivilDate? depletionDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = ScortePalette.of(context);
    final pro = ref.watch(isProProvider);
    final reminder = ref.watch(remindersProvider).value?[source.id];
    final written = CivilDate.tryParse(reminder?.calculatedDate);
    final drifted = written != null && CalendarSyncService.drifted(written, reorderDate);
    final style = TextButton.styleFrom(
      foregroundColor: p.badge,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );

    if (reminder == null || written == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          style: style,
          onPressed: () => unawaited(_add(context, ref)),
          icon: const Icon(Icons.edit_calendar_outlined, size: 18),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.calendar_add),
              if (!pro) ...[const SizedBox(width: 8), const ProBadge()]
            ],
          ),
        ),
      );
    }
    if (drifted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.calendar_drift(_day(context, written)), style: TextStyle(fontSize: 13, color: p.onNightMuted)),
          TextButton.icon(
            style: style,
            onPressed: () => unawaited(_write(context, ref, reminder.calendarId, reminder.externalEventId)),
            icon: const Icon(Icons.update, size: 18),
            label: Text(l.calendar_update),
          ),
        ],
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        style: style.copyWith(foregroundColor: WidgetStatePropertyAll(p.onNightMuted)),
        onPressed: () => unawaited(_offerRemove(context, ref, reminder)),
        icon: const Icon(Icons.event_available, size: 18),
        label: Text(l.calendar_inCalendar),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l = L.of(context);
    if (!ref.read(featureGateProvider).allows(FeatureKey.calendarSync)) {
      final unlocked = await showScortePaywall(context, ref, highlight: FeatureKey.calendarSync);
      if (!unlocked || !context.mounted) return;
    }
    final calendars = await ref.read(calendarSyncProvider).availableCalendars();
    if (!context.mounted) return;
    final list = calendars.valueOrNull;
    if (list == null) {
      _showError(context, l, calendars.errorOrNull);
      return;
    }
    final picked = list.length == 1 ? list.single : await _pick(context, l, list);
    if (picked == null || !context.mounted) return;
    await _write(context, ref, picked.id, null);
  }

  Future<void> _write(BuildContext context, WidgetRef ref, String calendarId, String? eventId) async {
    final l = L.of(context);
    final result = await ref.read(calendarSyncProvider).upsertReorderEvent(
      source: source,
      date: reorderDate,
      calendarId: calendarId,
      existingEventId: eventId,
      texts: (
        title: l.calendar_eventTitle(fuelName(l, source.fuelTypeEnum), source.name),
        description: l.calendar_eventBody(depletionDate == null ? '–' : _day(context, depletionDate!)),
      ),
    );
    if (!context.mounted) return;
    result.fold(
      ok: (_) => MicroSnack.success(
        context,
        eventId == null ? l.calendar_added(_day(context, reorderDate)) : l.calendar_updated(_day(context, reorderDate)),
      ),
      err: (e) => _showError(context, l, e),
    );
  }

  Future<void> _offerRemove(BuildContext context, WidgetRef ref, CalendarReminder reminder) async {
    final l = L.of(context);
    final remove = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.event_busy),
          title: Text(l.calendar_remove),
          onTap: () => Navigator.of(sheet).pop(true),
        ),
      ),
    );
    if (remove != true || !context.mounted) return;
    await ref.read(calendarSyncProvider).forgetSource(source.id);
    if (context.mounted) MicroSnack.show(context, l.calendar_removed);
  }

  static Future<CalendarChoice?> _pick(BuildContext context, L l, List<CalendarChoice> list) =>
      showModalBottomSheet<CalendarChoice>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheet) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(l.calendar_pick, style: Theme.of(sheet).textTheme.titleLarge),
              ),
              for (final c in list)
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: Text(c.name),
                  subtitle: c.account == null || c.account == c.name ? null : Text(c.account!),
                  onTap: () => Navigator.of(sheet).pop(c),
                ),
            ],
          ),
        ),
      );

  static void _showError(BuildContext context, L l, MicroError? e) => MicroSnack.error(
        context,
        switch (e?.code) {
          CalendarSyncService.errDenied => l.calendar_denied,
          CalendarSyncService.errNoCalendar => l.calendar_none,
          _ => l.calendar_failed,
        },
      );

  static String _day(BuildContext context, CivilDate d) =>
      DateFormat.MMMMd(Localizations.localeOf(context).toLanguageTag()).format(d.toLocalMidnight());
}

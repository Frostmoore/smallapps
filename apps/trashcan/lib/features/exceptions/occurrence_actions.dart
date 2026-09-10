import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/waste_presets.dart';
import '../../data/database.dart';
import '../../domain/occurrence_engine.dart';
import '../../l10n/generated/app_localizations.dart';

/// Il menu che si apre toccando una raccolta: salta, sposta, aggiungi.
///
/// ⚑ Perché le eccezioni sono in un menu contestuale e non in una pagina di
/// impostazioni: il momento in cui si scopre che una raccolta salta è quello in cui si
/// guarda il calendario, non quello in cui si aprono le impostazioni. Un'eccezione che
/// costa quattro tocchi non viene inserita, e l'app resta con un calendario che l'utente
/// sa essere sbagliato.
Future<void> showOccurrenceActions(
  BuildContext context,
  WidgetRef ref, {
  required CollectionOccurrence occurrence,
}) async {
  final l = L.of(context);
  final bundle = ref.read(activeBundleProvider).value;
  final type = bundle?.typeOf(occurrence.wasteTypeId);
  if (type == null) return;

  final accent = Color(type.colorValue);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final dateLabel = DateFormat('EEEE d MMMM', locale).format(occurrence.date.toLocalMidnight());

  final action = await showModalBottomSheet<_Action>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MicroSpacing.l,
              MicroSpacing.l,
              MicroSpacing.l,
              MicroSpacing.s,
            ),
            child: Row(
              children: [
                Icon(WasteIcons.resolve(type.iconKey), color: accent),
                MicroSpacing.hGapL,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.name, style: Theme.of(sheetContext).textTheme.titleMedium),
                      Text(
                        dateLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(sheetContext).colorScheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Una raccolta straordinaria non si "salta": si toglie. Offrire entrambe le voci
          // creerebbe due modi di ottenere lo stesso risultato, con due righe diverse in
          // tabella e nessun vantaggio.
          if (occurrence.origin != OccurrenceOrigin.extra)
            ListTile(
              leading: const Icon(Icons.event_busy_outlined),
              title: Text(l.exceptions_skip),
              onTap: () => Navigator.of(sheetContext).pop(_Action.skip),
            ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: Text(l.exceptions_move),
            onTap: () => Navigator.of(sheetContext).pop(_Action.move),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: Text(l.exceptions_extra),
            onTap: () => Navigator.of(sheetContext).pop(_Action.extra),
          ),
          if (occurrence.origin != OccurrenceOrigin.regular)
            ListTile(
              leading: const Icon(Icons.undo),
              title: Text(l.exceptions_removeConfirm),
              onTap: () => Navigator.of(sheetContext).pop(_Action.revert),
            ),
          MicroSpacing.gapM,
        ],
      ),
    ),
  );

  if (action == null || !context.mounted) return;

  final repo = ref.read(repositoryProvider);
  final existing = findExceptionFor(bundle, occurrence);

  switch (action) {
    case _Action.skip:
      // Se la raccolta era già stata spostata, l'eccezione vecchia va tolta: lasciarne due
      // sullo stesso giorno significa una regola che dice "sposta" e una che dice "salta",
      // e il risultato dipenderebbe dall'ordine di lettura delle righe.
      if (existing != null) await repo.removeException(existing.id);
      await repo.skipCollection(
        wasteTypeId: occurrence.wasteTypeId,
        date: occurrence.originalDate ?? occurrence.date,
      );
      if (context.mounted) MicroSnack.show(context, l.exceptions_addedSkip);

    case _Action.move:
      final picked = await _pickDate(context, initial: occurrence.date);
      if (picked == null || !context.mounted) return;
      if (existing != null) await repo.removeException(existing.id);
      if (occurrence.origin == OccurrenceOrigin.extra) {
        await repo.addExtraCollection(wasteTypeId: occurrence.wasteTypeId, date: picked);
      } else {
        await repo.moveCollection(
          wasteTypeId: occurrence.wasteTypeId,
          from: occurrence.originalDate ?? occurrence.date,
          to: picked,
        );
      }
      if (context.mounted) MicroSnack.show(context, l.exceptions_addedMove);

    case _Action.extra:
      final picked = await _pickDate(context, initial: occurrence.date);
      if (picked == null || !context.mounted) return;
      await repo.addExtraCollection(wasteTypeId: occurrence.wasteTypeId, date: picked);
      if (context.mounted) MicroSnack.show(context, l.exceptions_addedExtra);

    case _Action.revert:
      if (existing != null) await repo.removeException(existing.id);
  }
}

enum _Action { skip, move, extra, revert }

/// L'eccezione che ha prodotto questa raccolta, se ce n'è una.
///
/// ⚑ Si cerca invece di portarla dentro [CollectionOccurrence] perché il motore delle
/// ricorrenze è puro e non conosce gli id del database: dargliene uno lo legherebbe alla
/// persistenza e renderebbe i suoi 40 test dipendenti da Drift. Qui il costo è una ricerca
/// lineare su una manciata di righe, una volta per tocco.
CollectionException? findExceptionFor(CalendarBundle? bundle, CollectionOccurrence occurrence) {
  if (bundle == null) return null;
  final rule = bundle.rules.where((r) => r.wasteTypeId == occurrence.wasteTypeId).firstOrNull;
  if (rule == null) return null;

  return switch (occurrence.origin) {
    OccurrenceOrigin.regular => null,
    OccurrenceOrigin.extra => rule.exceptions
        .where((e) => e.isExtra && e.replacementDate == occurrence.date)
        .firstOrNull,
    OccurrenceOrigin.moved => rule.exceptions
        .where(
          (e) =>
              e.isMove &&
              e.replacementDate == occurrence.date &&
              e.originalDate == occurrence.originalDate,
        )
        .firstOrNull,
  };
}

Future<CivilDate?> _pickDate(BuildContext context, {required CivilDate initial}) async {
  final today = CivilDate.today();
  final picked = await showDatePicker(
    context: context,
    initialDate: initial.toLocalMidnight(),
    firstDate: today.addDays(-30).toLocalMidnight(),
    lastDate: today.addYears(2).toLocalMidnight(),
  );
  return picked == null ? null : CivilDate.fromDateTime(picked);
}

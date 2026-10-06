import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/waste_presets.dart';
import '../../data/database.dart';
import '../../domain/occurrence_engine.dart';
import '../../l10n/generated/app_localizations.dart';
import 'occurrence_actions.dart';

/// Aggiunge un'eccezione partendo dalla pagina delle eccezioni.
///
/// ☠ **Quella pagina elencava le eccezioni ma non permetteva di crearne.** Si creavano solo
/// toccando una raccolta nella home, che mostra i prossimi sette giorni: per saltare la
/// raccolta di Natale a novembre bisognava aspettare dicembre. Il proprietario, il
/// 2026-10-06: «a che serve quell'interfaccia?». Aveva ragione.
///
/// ⚑ **Tre passi, e il terzo non e' nuovo.** Si sceglie il rifiuto, poi la raccolta da
/// cambiare, e da li' si apre lo stesso menu che si apre toccando una raccolta nella home
/// ([showOccurrenceActions]): salta, sposta, rimuovi. Due menu per la stessa cosa
/// finirebbero per comportarsi in modo diverso, e su un calendario un comportamento diverso
/// e' un bidone dimenticato.
///
/// ⚑ La raccolta si sceglie da un **elenco delle prossime**, non da un calendario libero:
/// cosi' non si puo' "saltare" un giorno in cui quel rifiuto non passa. Solo la raccolta
/// straordinaria chiede una data libera, perche' e' l'unica che puo' cadere ovunque.
Future<void> showAddException(BuildContext context, WidgetRef ref) async {
  final l = L.of(context);
  final bundle = ref.read(activeBundleProvider).value;
  if (bundle == null) return;

  if (bundle.wasteTypes.isEmpty) {
    MicroSnack.show(context, l.exceptions_noTypes);
    return;
  }

  final type = await _chooseType(context, l, bundle);
  if (type == null || !context.mounted) return;

  final scelta = await _chooseCollection(context, l, bundle, type);
  if (scelta == null || !context.mounted) return;

  switch (scelta) {
    case _Straordinaria():
      final picked = await showDatePicker(
        context: context,
        initialDate: CivilDate.today().toLocalMidnight(),
        firstDate: CivilDate.today().toLocalMidnight(),
        lastDate: CivilDate.today().addYears(2).toLocalMidnight(),
      );
      if (picked == null || !context.mounted) return;
      await ref
          .read(repositoryProvider)
          .addExtraCollection(wasteTypeId: type.id, date: CivilDate.fromDateTime(picked));
      if (context.mounted) MicroSnack.show(context, l.exceptions_addedExtra);
    case _Raccolta(:final occurrence):
      await showOccurrenceActions(context, ref, occurrence: occurrence);
  }
}

/// Quante raccolte si propongono. Un anno per un rifiuto settimanale, di piu' per gli altri.
const int _raccolteProposte = 52;

/// Fino a quando si cercano: le eccezioni servono soprattutto per le feste di fine anno.
const int _giorniCercati = 400;

Future<WasteType?> _chooseType(BuildContext context, L l, CalendarBundle bundle) =>
    showModalBottomSheet<WasteType>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MicroSpacing.l,
                0,
                MicroSpacing.l,
                MicroSpacing.s,
              ),
              child: Text(l.exceptions_pickType, style: Theme.of(sheet).textTheme.titleMedium),
            ),
            for (final type in bundle.wasteTypes)
              ListTile(
                leading: Icon(WasteIcons.resolve(type.iconKey), color: Color(type.colorValue)),
                title: Text(type.name),
                onTap: () => Navigator.of(sheet).pop(type),
              ),
            MicroSpacing.gapM,
          ],
        ),
      ),
    );

Future<_Scelta?> _chooseCollection(
  BuildContext context,
  L l,
  CalendarBundle bundle,
  WasteType type,
) {
  final oggi = CivilDate.today();
  final prossime = const OccurrenceEngine()
      .expand(rules: bundle.rules, from: oggi, to: oggi.addDays(_giorniCercati))
      .where((o) => o.wasteTypeId == type.id)
      .take(_raccolteProposte)
      .toList();
  final locale = Localizations.localeOf(context).toLanguageTag();

  return showModalBottomSheet<_Scelta>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, scroll) => SafeArea(
        child: ListView(
          controller: scroll,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MicroSpacing.l,
                0,
                MicroSpacing.l,
                MicroSpacing.s,
              ),
              child: Text(
                l.exceptions_pickCollection(type.name),
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
            ),
            // In cima, perche' e' la sola che non parte da una raccolta esistente.
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(l.exceptions_extra),
              onTap: () => Navigator.of(sheet).pop(const _Straordinaria()),
            ),
            const Divider(),
            if (prossime.isEmpty)
              Padding(
                padding: const EdgeInsets.all(MicroSpacing.l),
                child: Text(l.exceptions_noUpcoming),
              ),
            for (final occurrence in prossime)
              ListTile(
                leading: Icon(
                  WasteIcons.resolve(type.iconKey),
                  color: Color(type.colorValue),
                ),
                title: Text(
                  DateFormat('EEEE d MMMM', locale).format(occurrence.date.toLocalMidnight()),
                ),
                // Una raccolta gia' cambiata lo dice: chi la tocca deve sapere che sta
                // modificando un'eccezione, non la regola.
                subtitle: switch (occurrence.origin) {
                  OccurrenceOrigin.regular => null,
                  OccurrenceOrigin.moved => Text(
                    l.exceptions_movedFromTo(
                      DateFormat('EEEE d MMMM', locale).format(
                        (occurrence.originalDate ?? occurrence.date).toLocalMidnight(),
                      ),
                      DateFormat('EEEE d MMMM', locale).format(occurrence.date.toLocalMidnight()),
                    ),
                  ),
                  OccurrenceOrigin.extra => Text(l.exceptions_extraBadge),
                },
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(sheet).pop(_Raccolta(occurrence)),
              ),
            MicroSpacing.gapM,
          ],
        ),
      ),
    ),
  );
}

sealed class _Scelta {
  const _Scelta();
}

final class _Straordinaria extends _Scelta {
  const _Straordinaria();
}

final class _Raccolta extends _Scelta {
  const _Raccolta(this.occurrence);

  final CollectionOccurrence occurrence;
}

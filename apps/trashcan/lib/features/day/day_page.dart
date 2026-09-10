import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/waste_presets.dart';
import '../../domain/occurrence_engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../exceptions/occurrence_actions.dart';

/// Il giorno singolo: dove porta il tocco su una notifica.
///
/// ⚑ Perché la notifica non apre semplicemente la home: chi la tocca ha in mente una data
/// precisa, quella di domani. Aprire la home lo costringe a ritrovarla, e se nel frattempo
/// è passata la mezzanotte la home mostra un altro giorno. La data nel percorso rende il
/// collegamento indipendente da quando viene toccato.
class DayPage extends ConsumerStatefulWidget {
  const DayPage({required this.date, this.calendarId, super.key});

  /// `null` se la data nel percorso non è leggibile: succede con un collegamento vecchio o
  /// storpiato, e si mostra la pagina vuota invece di far crollare l'app.
  final CivilDate? date;

  final int? calendarId;

  @override
  ConsumerState<DayPage> createState() => _DayPageState();
}

class _DayPageState extends ConsumerState<DayPage> {
  @override
  void initState() {
    super.initState();
    // La notifica porta con sé il calendario che l'ha generata: con più calendari, aprire
    // il giorno senza cambiare quello attivo mostrerebbe le raccolte della casa sbagliata.
    // Si fa dopo il primo frame perché toccare un provider durante initState di un
    // ConsumerState significa modificarlo mentre l'albero si sta costruendo.
    final calendarId = widget.calendarId;
    if (calendarId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(selectedCalendarProvider) == calendarId) return;
      ref.read(selectedCalendarProvider.notifier).select(calendarId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = widget.date;
    final bundle = ref.watch(activeBundleProvider).value;

    final occurrences = date == null
        ? const <CollectionOccurrence>[]
        : ref.watch(occurrencesProvider).where((o) => o.date == date).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          date == null
              ? l.appTitle
              : DateFormat('EEEE d MMMM', locale).format(date.toLocalMidnight()),
        ),
      ),
      body: SafeArea(
        child: occurrences.isEmpty
            ? MicroEmptyState(
                icon: Icons.event_available_outlined,
                title: l.day_empty,
                message: l.home_noUpcomingHint,
              )
            : ListView(
                padding: MicroSpacing.page,
                children: [
                  for (final occurrence in occurrences)
                    Padding(
                      padding: const EdgeInsets.only(bottom: MicroSpacing.s),
                      child: MicroCard(
                        padding: EdgeInsets.zero,
                        child: MicroListTile(
                          title: bundle?.typeOf(occurrence.wasteTypeId)?.name ?? '—',
                          subtitle: describeEveningOf(context, occurrence),
                          accent: Color(
                            bundle?.typeOf(occurrence.wasteTypeId)?.colorValue ?? 0xFF888888,
                          ),
                          leading: Icon(
                            WasteIcons.resolve(
                              bundle?.typeOf(occurrence.wasteTypeId)?.iconKey,
                            ),
                            color: Color(
                              bundle?.typeOf(occurrence.wasteTypeId)?.colorValue ?? 0xFF888888,
                            ),
                          ),
                          onTap: () => showOccurrenceActions(context, ref, occurrence: occurrence),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// "Da portare fuori giovedì sera", oppure la nota dell'eccezione se c'è.
String describeEveningOf(BuildContext context, CollectionOccurrence occurrence) {
  final l = L.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final note = occurrence.note;
  if (note != null && note.isNotEmpty) return note;

  final evening = occurrence.date.addDays(-1);
  final today = CivilDate.today();
  if (evening == today) return l.home_whenThisEvening;
  if (evening == today.addDays(1)) return l.home_whenTomorrowEvening;
  return l.home_whenOnWeekdayEvening(
    DateFormat('EEEE', locale).format(evening.toLocalMidnight()),
  );
}

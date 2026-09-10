import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/waste_presets.dart';
import '../../data/database.dart';
import '../../domain/occurrence_engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../exceptions/occurrence_actions.dart';

/// La home.
///
/// ⚑ Struttura decisa dalle specifiche e non negoziabile: il blocco "Stasera" occupa
/// mezzo schermo. L'app viene aperta di sera, spesso di fretta e con le mani occupate: la
/// risposta deve essere leggibile a un metro di distanza senza mettere a fuoco. Tutto il
/// resto è secondario.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final calendar = ref.watch(activeCalendarProvider);
    final bundle = ref.watch(activeBundleProvider).value;
    final tonight = ref.watch(tonightProvider);
    final next = ref.watch(nextOccurrenceProvider);
    final week = ref.watch(upcomingWeekProvider);

    // ⛑ Toccare una raccolta apre il menu delle eccezioni. Il piano prevedeva il tocco
    // lungo; qui c'e' anche il tocco semplice perche' una riga che non fa niente e' un
    // vicolo cieco, e il menu non compie di per se' nessuna azione distruttiva.
    void openActions(CollectionOccurrence occurrence) =>
        unawaited(showOccurrenceActions(context, ref, occurrence: occurrence));

    return Scaffold(
      appBar: AppBar(
        title: Text(calendar?.name ?? l.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l.wasteTypes_title,
            onPressed: () => context.push(Routes.wasteTypes),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.settings_title,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: MicroSpacing.page,
          children: [
            _TonightBlock(occurrences: tonight, bundle: bundle, onTap: openActions),
            MicroSpacing.gapXL,
            if (next != null) _NextCollection(occurrence: next, bundle: bundle),
            if (week.isNotEmpty) ...[
              MicroSpacing.gapXL,
              MicroSectionHeader(title: l.home_next7Days),
              MicroCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final occurrence in week)
                      _WeekRow(occurrence: occurrence, bundle: bundle, onTap: openActions),
                  ],
                ),
              ),
            ],
            if (bundle != null && bundle.wasteTypes.isEmpty) ...[
              MicroSpacing.gapXL,
              MicroEmptyState(
                icon: Icons.event_available_outlined,
                title: l.home_noUpcoming,
                message: l.home_noUpcomingHint,
                actionLabel: l.common_add,
                onAction: () => context.push(Routes.wasteTypeNew),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Il blocco che risponde alla domanda per cui l'app esiste.
class _TonightBlock extends StatelessWidget {
  const _TonightBlock({required this.occurrences, required this.bundle, required this.onTap});

  final List<CollectionOccurrence> occurrences;
  final CalendarBundle? bundle;
  final ValueChanged<CollectionOccurrence> onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);

    if (occurrences.isEmpty) {
      return MicroCard(
        padding: const EdgeInsets.symmetric(
          horizontal: MicroSpacing.l,
          vertical: MicroSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.home_tonightTitle.toUpperCase(),
              style: theme.textTheme.sectionLabel.copyWith(
                color: theme.colorScheme.mutedText,
              ),
            ),
            MicroSpacing.gapM,
            Text(l.home_tonightEmpty, style: theme.textTheme.headlineSmall),
          ],
        ),
      );
    }

    // Con più tipi la stessa sera si usa il colore del primo come sfondo e si elencano
    // tutti: dividere in più card renderebbe meno leggibile proprio il caso in cui
    // l'utente ha più cose da ricordarsi.
    final first = bundle?.typeOf(occurrences.first.wasteTypeId);
    final accent = first == null ? theme.colorScheme.primary : Color(first.colorValue);

    return MicroCard(
      accent: accent,
      padding: const EdgeInsets.symmetric(
        horizontal: MicroSpacing.l,
        vertical: MicroSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.home_tonightTitle.toUpperCase(),
            style: theme.textTheme.sectionLabel.copyWith(
              color: MicroCard.foregroundOn(accent).withValues(alpha: 0.75),
            ),
          ),
          MicroSpacing.gapM,
          for (final occurrence in occurrences)
            Padding(
              padding: const EdgeInsets.only(bottom: MicroSpacing.s),
              child: InkWell(
                onTap: () => onTap(occurrence),
                child: Row(
                children: [
                  Icon(
                    WasteIcons.resolve(bundle?.typeOf(occurrence.wasteTypeId)?.iconKey),
                    size: 34,
                  ),
                  MicroSpacing.hGapL,
                  Expanded(
                    child: Text(
                      bundle?.typeOf(occurrence.wasteTypeId)?.name ?? '—',
                      style: theme.textTheme.displaySmall?.copyWith(height: 1.1),
                    ),
                  ),
                  if (occurrence.origin != OccurrenceOrigin.regular)
                    Icon(
                      occurrence.origin == OccurrenceOrigin.extra
                          ? Icons.add_circle_outline
                          : Icons.swap_horiz,
                      size: 20,
                    ),
                ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NextCollection extends StatelessWidget {
  const _NextCollection({required this.occurrence, required this.bundle});

  final CollectionOccurrence occurrence;
  final CalendarBundle? bundle;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final type = bundle?.typeOf(occurrence.wasteTypeId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MicroSectionHeader(title: l.home_nextCollection),
        MicroCard(
          child: Row(
            children: [
              Icon(WasteIcons.resolve(type?.iconKey), color: Color(type?.colorValue ?? 0xFF888888)),
              MicroSpacing.hGapL,
              Expanded(
                child: Text(
                  l.home_nextIn(
                    type?.name ?? '—',
                    describeEvening(context, occurrence.date),
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.occurrence, required this.bundle, required this.onTap});

  final CollectionOccurrence occurrence;
  final CalendarBundle? bundle;
  final ValueChanged<CollectionOccurrence> onTap;

  @override
  Widget build(BuildContext context) {
    final type = bundle?.typeOf(occurrence.wasteTypeId);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final label = DateFormat('EEEE d MMMM', locale).format(occurrence.date.toLocalMidnight());

    return MicroListTile(
      title: type?.name ?? '—',
      subtitle: label,
      accent: Color(type?.colorValue ?? 0xFF888888),
      dense: true,
      onTap: () => onTap(occurrence),
    );
  }
}

/// "stasera", "domani sera", oppure "giovedì sera".
///
/// ⚑ Si parla sempre di **sera** perché è quando si porta fuori il bidone: dire
/// "giovedì" per una raccolta che avviene giovedì mattina farebbe perdere la raccolta a
/// chi legge di giovedì pomeriggio.
String describeEvening(BuildContext context, CivilDate collectionDate) {
  final l = L.of(context);
  final today = CivilDate.today();
  // La sera in cui portare fuori è quella **precedente** alla raccolta.
  final evening = collectionDate.addDays(-1);

  if (evening == today) return l.home_whenThisEvening;
  if (evening == today.addDays(1)) return l.home_whenTomorrowEvening;

  final locale = Localizations.localeOf(context).toLanguageTag();
  final weekday = DateFormat('EEEE', locale).format(evening.toLocalMidnight());
  return l.home_whenOnWeekdayEvening(weekday);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../l10n/generated/app_localizations.dart';

/// L'elenco dei calendari, e il punto in cui si vende il Pro.
///
/// ⚑ Il secondo calendario è la ragione per cui qualcuno paga: la seconda casa, casa dei
/// genitori, l'ufficio. Per questo il limite non si nasconde e non si scopre a sorpresa
/// dopo aver compilato un modulo: il bottone "aggiungi" resta visibile e cliccabile, e
/// porta al paywall spiegando esattamente cosa sblocca. Un bottone grigio che non fa
/// niente insegna solo che l'app è rotta.
class CalendarsPage extends ConsumerWidget {
  const CalendarsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final calendars = ref.watch(calendarsProvider).value ?? const <CollectionCalendar>[];
    final active = ref.watch(activeCalendarProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.calendars_title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref, calendars.length),
        icon: const Icon(Icons.add),
        label: Text(l.common_add),
      ),
      body: SafeArea(
        child: ListView(
          padding: MicroSpacing.page,
          children: [
            for (final calendar in calendars)
              Padding(
                padding: const EdgeInsets.only(bottom: MicroSpacing.s),
                child: MicroCard(
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Expanded(
                        child: MicroListTile(
                          title: calendar.name,
                          subtitle: calendar.notificationTime,
                          leading: Icon(
                            calendar.id == active?.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: calendar.id == active?.id
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.mutedText,
                          ),
                          // Toccare la riga sceglie il calendario e torna indietro: e'
                          // l'azione per cui si apre questa pagina nove volte su dieci.
                          // La modifica sta dietro all'icona, che e' un bersaglio distinto.
                          onTap: () {
                            ref.read(selectedCalendarProvider.notifier).select(calendar.id);
                            context.pop();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: l.common_edit,
                        onPressed: () => context.push(Routes.calendarEditOf(calendar.id)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref, int currentCount) async {
    final gate = ref.read(featureGateProvider);
    if (!gate.withinLimit(FeatureKey.unlimitedEntities, currentCount)) {
      final unlocked = await showTrashcanPaywall(
        context,
        ref,
        highlight: FeatureKey.unlimitedEntities,
      );
      if (!unlocked || !context.mounted) return;
    }
    if (!context.mounted) return;
    await context.push(Routes.calendarNew);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/waste_presets.dart';
import '../../domain/occurrence_engine.dart';
import '../../l10n/generated/app_localizations.dart';

/// L'elenco delle deroghe attive: raccolte saltate, spostate e straordinarie.
///
/// ⚑ Perché esiste anche questa pagina, visto che le eccezioni si creano dalla home: una
/// deroga inserita mesi prima diventa invisibile appena esce dalla finestra dei prossimi
/// giorni. Senza un posto dove vederle tutte, l'unico modo di scoprire perché una raccolta
/// "manca" sarebbe aspettare che arrivi.
class ExceptionsPage extends ConsumerWidget {
  const ExceptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final bundle = ref.watch(activeBundleProvider).value;

    // Ordinate per data di riferimento: è l'ordine in cui l'utente le ritrova nel
    // calendario, e l'unico che rende scorrevole un elenco lungo.
    final entries =
        <({CollectionException exception, String typeName, Color colour, String iconKey})>[
          for (final rule in bundle?.rules ?? const <RuleWithExceptions>[])
            for (final exception in rule.exceptions)
              if (bundle?.typeOf(rule.wasteTypeId) case final type?)
                (
                  exception: exception,
                  typeName: type.name,
                  colour: Color(type.colorValue),
                  iconKey: type.iconKey,
                ),
        ]..sort((a, b) => _sortKey(a.exception).compareTo(_sortKey(b.exception)));

    return Scaffold(
      appBar: AppBar(title: Text(l.exceptions_title)),
      body: SafeArea(
        child: entries.isEmpty
            ? MicroEmptyState(
                icon: Icons.event_busy_outlined,
                title: l.exceptions_empty,
                message: l.exceptions_emptyHint,
              )
            : ListView(
                padding: MicroSpacing.page,
                children: [
                  for (final entry in entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: MicroSpacing.s),
                      child: MicroCard(
                        padding: EdgeInsets.zero,
                        child: MicroListTile(
                          title: entry.typeName,
                          subtitle: describeException(context, entry.exception),
                          accent: entry.colour,
                          leading: Icon(
                            WasteIcons.resolve(entry.iconKey),
                            color: entry.colour,
                          ),
                          onTap: () => _remove(context, ref, entry.exception),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, CollectionException e) async {
    final l = L.of(context);
    final confirmed = await MicroConfirmSheet.show(
      context,
      title: l.exceptions_removeConfirm,
      message: l.exceptions_removeConfirmBody,
      confirmLabel: l.common_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(repositoryProvider).removeException(e.id);
  }
}

/// La data su cui ordinare: quella in cui l'eccezione si manifesta.
CivilDate _sortKey(CollectionException e) =>
    e.replacementDate ?? e.originalDate ?? CivilDate.fromEpochDay(0);

/// "Saltata il giovedì 24 dicembre", "Spostata dal … al …", "Raccolta straordinaria il …".
String describeException(BuildContext context, CollectionException e) {
  final l = L.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  String fmt(CivilDate d) => DateFormat('EEEE d MMMM', locale).format(d.toLocalMidnight());

  if (e.isSkip) return l.exceptions_skippedOn(fmt(e.originalDate!));
  if (e.isMove) return l.exceptions_movedFromTo(fmt(e.originalDate!), fmt(e.replacementDate!));
  if (e.isExtra) return l.exceptions_extraOn(fmt(e.replacementDate!));
  // Una riga che non è nessuna delle tre forme non dovrebbe arrivare fin qui: il mapper la
  // scarta. Se ci arriva, meglio una riga vuota che un crash nella lista.
  return '';
}

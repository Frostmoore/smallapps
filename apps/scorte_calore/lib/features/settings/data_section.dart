import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../data/database.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/calendar_providers.dart';
import '../../services/csv_export.dart';
import '../../services/scorte_backup_source.dart';

/// Il servizio di backup di micro_core, con le cartelle dell'app e la sua versione.
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(paths: ref.watch(appPathsProvider), appVersion: appVersion),
);

/// La sezione "I tuoi dati" delle impostazioni (F5.11): esporta in CSV (Pro), backup
/// completo (Pro), ripristina da un backup (gratis).
///
/// ⚑ Le voci Pro **si vedono anche senza il Pro**, con il badge: toccarle apre il paywall con
/// quella funzione evidenziata. Nasconderle vorrebbe dire non far sapere che esistono.
class DataSection extends ConsumerWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final gate = ref.watch(featureGateProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: MicroSpacing.m),
          child: MicroSectionHeader(title: l.data_title),
        ),
        ListTile(
          leading: const Icon(Icons.table_view_outlined),
          title: Text(l.csv_export),
          subtitle: Text(l.csv_exportBody),
          trailing: gate.allows(FeatureKey.csvExport) ? null : const ProBadge(),
          onTap: () => unawaited(exportCsv(context, ref)),
        ),
        ListTile(
          leading: const Icon(Icons.save_alt),
          title: Text(l.backup_create),
          subtitle: Text(l.backup_createBody),
          trailing: gate.allows(FeatureKey.backupRestore) ? null : const ProBadge(),
          onTap: () => unawaited(createBackup(context, ref)),
        ),
        // Il ripristino e' gratis: vedi restoreBackup qui sotto.
        ListTile(
          leading: const Icon(Icons.settings_backup_restore),
          title: Text(l.backup_restore),
          subtitle: Text(l.backup_restoreBody),
          onTap: () => unawaited(restoreBackup(context, ref)),
        ),
      ],
    );
  }
}

/// Esporta misurazioni e acquisti di **tutte** le fonti (anche le disattivate) in CSV e li
/// condivide (Pro).
///
/// ⚑ Tutto lo storico, non solo gli ultimi 90 giorni: il CSV e' Pro, e chi ha il Pro vede lo
/// storico completo (F5.9). Un CSV tagliato sarebbe un dato che sparisce senza avviso.
Future<void> exportCsv(BuildContext context, WidgetRef ref) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.csvExport)) {
    await showScortePaywall(context, ref, highlight: FeatureKey.csvExport);
    return;
  }
  final l = L.of(context);
  final repo = ref.read(repositoryProvider);
  final sources = await repo.allSources();
  final measurements = <StockMeasurement>[
    for (final s in sources) ...await repo.allMeasurements(s.id),
  ];
  final file = await exportScorteCsv(
    paths: ref.read(appPathsProvider),
    l: l,
    sources: sources,
    measurements: measurements,
    purchases: await repo.allPurchases(),
    today: ref.read(todayProvider),
  );
  await ref.read(backupServiceProvider).shareBackup(file, subject: l.csv_subject);
}

/// Crea il backup completo e lo condivide (Pro). Un JSON solo: Scorte Calore non ha foto.
Future<void> createBackup(BuildContext context, WidgetRef ref) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.backupRestore)) {
    await showScortePaywall(context, ref, highlight: FeatureKey.backupRestore);
    return;
  }
  final l = L.of(context);
  final service = ref.read(backupServiceProvider);
  final result = await service.createBackup(ScorteBackupSource(ref.read(databaseProvider)), label: l.appTitle);
  if (!context.mounted) return;
  await result.fold(
    ok: (file) => service.shareBackup(file, subject: l.backup_subject),
    err: (_) async => MicroSnack.error(context, l.backup_createFailed),
  );
}

/// Ripristina da un backup: sceglie il file, mostra cosa contiene, chiede come, poi agisce.
///
/// ⚑ **Gratis**, al contrario della creazione: chi passa a un telefono nuovo deve poter
/// riavere i suoi dati anche prima di aver ripristinato l'acquisto. Il Pro si vende sulla
/// creazione del backup, non sul diritto di riaverli (stessa scelta di Full Freezer).
///
/// ☠ Un ripristino "sostituisci tutto" e' irreversibile: il riepilogo prima della conferma e'
/// il solo modo per accorgersi di aver scelto il file sbagliato (lezione di TrashCan).
///
/// ☠ "Sostituisci tutto" cancella anche le righe dei promemoria del calendario, ma non gli
/// eventi gia' scritti nel calendario del telefono: per questo, prima di sostituire, li
/// toglie `CalendarSyncService.forgetAll` (F5.10).
Future<void> restoreBackup(BuildContext context, WidgetRef ref) async {
  final l = L.of(context);
  final service = ref.read(backupServiceProvider);
  final file = await service.pickBackupFile();
  if (file == null || !context.mounted) return;

  final inspected = await service.inspect(file);
  if (!context.mounted) return;
  final manifest = inspected.valueOrNull;
  // Un backup di un'altra app si riconosce gia' qui: meglio dirlo prima di chiedere come
  // ripristinarlo che dopo.
  if (manifest == null || manifest.schemaId != ScorteBackupSource.id) {
    // Il messaggio di MicroError e' per i log: all'utente si dice cosa e' successo.
    MicroSnack.error(context, l.backup_failed);
    return;
  }

  final mode = await showModalBottomSheet<ImportMode>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(MicroSpacing.l, 0, MicroSpacing.l, MicroSpacing.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.backup_restoreTitle, style: Theme.of(sheet).textTheme.titleLarge),
                MicroSpacing.gapXS,
                Text(
                  l.backup_restoreSummary(
                    manifest.itemCounts['sources'] ?? 0,
                    manifest.itemCounts['measurements'] ?? 0,
                    manifest.itemCounts['purchases'] ?? 0,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: Text(l.backup_modeReplace),
            subtitle: Text(l.backup_modeReplaceBody),
            onTap: () => Navigator.of(sheet).pop(ImportMode.replaceAll),
          ),
          ListTile(
            leading: const Icon(Icons.merge_type),
            title: Text(l.backup_modeMerge),
            subtitle: Text(l.backup_modeMergeBody),
            onTap: () => Navigator.of(sheet).pop(ImportMode.mergeKeepExisting),
          ),
          MicroSpacing.gapM,
        ],
      ),
    ),
  );
  if (mode == null || !context.mounted) return;

  // ☠ "Sostituisci tutto" cancella i promemoria (cascade), non gli eventi nel calendario.
  //   Si leggono PRIMA (dopo la riga che dice quale evento togliere non c'e' piu') e si
  //   tolgono DOPO, solo se il ripristino e' riuscito: con un file rotto gli eventi restano.
  //   Il backup non li riporta (vedi ScorteBackupSource): vanno rimessi dalla home.
  final orphans = mode == ImportMode.replaceAll
      ? await ref.read(repositoryProvider).watchReminders().first
      : const <CalendarReminder>[];
  if (!context.mounted) return;

  final restored = await service.restore(file, ScorteBackupSource(ref.read(databaseProvider)), mode: mode);
  if (restored.isOk) {
    final calendar = ref.read(calendarSyncProvider);
    for (final r in orphans) {
      await calendar.deleteEvent(r.calendarId, r.externalEventId);
    }
  }
  if (!context.mounted) return;
  await restored.fold(
    ok: (_) async {
      // Con almeno una fonte il redirect del router deve portare alla home, non al wizard
      // della prima fonte (un telefono nuovo che ripristina non l'ha mai completato).
      final hasSources = (await ref.read(repositoryProvider).allSources()).isNotEmpty;
      if (hasSources) await ref.read(settingsProvider).setBool(SettingKeys.onboardingDone, true);
      if (context.mounted) MicroSnack.success(context, l.backup_restored);
    },
    err: (_) async => MicroSnack.error(context, l.backup_failed),
  );
}

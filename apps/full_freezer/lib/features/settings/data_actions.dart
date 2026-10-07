import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../data/database.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/csv_export.dart';
import '../../services/freezer_backup_source.dart';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(paths: ref.watch(appPathsProvider), appVersion: appVersion),
);

/// Esporta in CSV quello che c'e' nel freezer e lo condivide (Pro).
Future<void> exportCsv(BuildContext context, WidgetRef ref) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.csvExport)) {
    await showFreezerPaywall(context, ref, highlight: FeatureKey.csvExport);
    return;
  }
  final l = L.of(context);
  final file = await exportStoredCsv(
    paths: ref.read(appPathsProvider),
    l: l,
    items: ref.read(storedItemsProvider).value ?? const <Item>[],
    freezers: ref.read(freezersProvider).value ?? const <Freezer>[],
    compartments: ref.read(compartmentsByFreezerProvider).value ?? const <int, List<Compartment>>{},
    today: ref.read(todayProvider),
    customCategories: ref.read(customCategoriesProvider).value ?? const <CustomCategory>[],
  );
  await ref.read(backupServiceProvider).shareBackup(file, subject: l.csv_subject);
}

/// Crea il backup completo, foto comprese, e lo condivide (Pro).
Future<void> createBackup(BuildContext context, WidgetRef ref) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.backupRestore)) {
    await showFreezerPaywall(context, ref, highlight: FeatureKey.backupRestore);
    return;
  }
  final l = L.of(context);
  final service = ref.read(backupServiceProvider);
  final result = await service.createBackup(
    FreezerBackupSource(ref.read(databaseProvider)),
    label: l.appTitle,
    // Le foto sono gratis e fanno parte dei dati: un backup senza lascerebbe il telefono
    // nuovo pieno di miniature rotte.
    includeImages: true,
  );
  if (!context.mounted) return;
  await result.fold(
    ok: (file) => service.shareBackup(file, subject: l.backup_subject),
    err: (error) async => MicroSnack.error(context, error.message),
  );
}

/// Ripristina da un backup: sceglie il file, mostra cosa contiene, chiede come, poi agisce.
///
/// ⚑ **Gratis**, al contrario della creazione: chi passa a un telefono nuovo deve poter
/// riavere i suoi dati anche prima di aver ripristinato l'acquisto. Il Pro si vende sulla
/// creazione del backup, non sul diritto di riaverli.
///
/// ☠ Un ripristino "sostituisci tutto" e' irreversibile: il riepilogo prima della conferma e'
/// il solo modo per accorgersi di aver scelto il file sbagliato (lezione di TrashCan).
Future<void> restoreBackup(BuildContext context, WidgetRef ref) async {
  final l = L.of(context);
  final service = ref.read(backupServiceProvider);
  final file = await service.pickBackupFile();
  if (file == null || !context.mounted) return;

  final inspected = await service.inspect(file);
  if (!context.mounted) return;
  final manifest = inspected.valueOrNull;
  if (manifest == null) {
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
                    manifest.itemCounts['freezers'] ?? 0,
                    manifest.itemCounts['items'] ?? 0,
                    manifest.itemCounts['history'] ?? 0,
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

  final restored = await service.restore(file, FreezerBackupSource(ref.read(databaseProvider)), mode: mode);
  if (!context.mounted) return;
  await restored.fold(
    ok: (_) async {
      // Il freezer guardato puo' non esistere piu': si torna a "Tutti".
      await ref.read(selectedFreezerProvider.notifier).select(null);
      await ref.read(settingsProvider).setBool(SettingKeys.onboardingDone, true);
      if (context.mounted) MicroSnack.success(context, l.backup_restored);
    },
    err: (_) async => MicroSnack.error(context, l.backup_failed),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/trashcan_backup_source.dart';

/// Backup completo e condivisione di un singolo calendario.
///
/// ⚑ Perché la condivisione è gratuita e il backup no: condividere è un canale di
/// acquisizione, cioè un utente che ne porta un altro, mentre il backup è una comodità
/// personale. Si regala l'acquisizione e si vende la comodità, non il contrario. Per lo
/// stesso motivo l'**import** è gratuito: chi riceve un calendario deve poterlo aprire
/// anche senza aver comprato niente, altrimenti il canale non funziona.
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Esporta il solo calendario attivo e lo passa al foglio di condivisione.
  Future<void> _shareCalendar() async {
    final calendar = ref.read(activeCalendarProvider);
    if (calendar == null) return;

    final service = ref.read(backupServiceProvider);
    final source = TrashcanBackupSource(
      ref.read(databaseProvider),
      onlyCalendarId: calendar.id,
    );
    final result = await service.createBackup(source, label: calendar.name);
    if (!mounted) return;

    await result.fold(
      ok: (file) => service.shareBackup(file, subject: calendar.name),
      err: (error) async => MicroSnack.error(context, error.message),
    );
  }

  Future<void> _createBackup() async {
    final l = L.of(context);
    final gate = ref.read(featureGateProvider);
    if (!gate.allows(FeatureKey.backupRestore)) {
      await showTrashcanPaywall(context, ref, highlight: FeatureKey.backupRestore);
      return;
    }
    if (!mounted) return;

    final service = ref.read(backupServiceProvider);
    final result = await service.createBackup(TrashcanBackupSource(ref.read(databaseProvider)));
    if (!mounted) return;

    await result.fold(
      ok: (file) async {
        MicroSnack.show(context, l.backup_created);
        await service.shareBackup(file);
      },
      err: (error) async => MicroSnack.error(context, error.message),
    );
  }

  /// Sceglie un file, mostra cosa contiene, e solo dopo la conferma tocca i dati.
  ///
  /// ☠ Un ripristino è distruttivo e irreversibile. Senza il riepilogo, chi sbaglia file
  /// se ne accorge quando il calendario è già sparito, e non ha modo di tornare indietro.
  Future<void> _restore() async {
    final l = L.of(context);
    final service = ref.read(backupServiceProvider);
    final source = TrashcanBackupSource(ref.read(databaseProvider));

    final file = await service.pickBackupFile();
    if (file == null) {
      if (mounted) MicroSnack.show(context, l.backup_nothingPicked);
      return;
    }

    final inspected = await service.inspect(file);
    if (!mounted) return;
    final manifest = inspected.valueOrNull;
    if (manifest == null) {
      MicroSnack.error(context, inspected.errorOrNull!.message);
      return;
    }

    final mode = await _askMode(manifest);
    if (mode == null || !mounted) return;

    final restored = await service.restore(file, source, mode: mode);
    if (!mounted) return;
    restored.fold(
      ok: (_) {
        // La selezione si azzera: il calendario che era attivo può non esistere più, e
        // un id che punta al nulla lascerebbe la home vuota senza spiegazione.
        ref.read(selectedCalendarProvider.notifier).select(null);
        MicroSnack.show(context, l.backup_restored);
      },
      err: (error) => MicroSnack.error(context, error.message),
    );
  }

  Future<ImportMode?> _askMode(BackupManifest manifest) {
    final l = L.of(context);
    final summary = l.backup_restoreSummary(
      manifest.itemCounts['calendars'] ?? 0,
      manifest.itemCounts['wasteTypes'] ?? 0,
      manifest.itemCounts['rules'] ?? 0,
    );

    return showModalBottomSheet<ImportMode>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(MicroSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.backup_restoreConfirmTitle,
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  MicroSpacing.gapS,
                  Text(summary, style: Theme.of(sheetContext).textTheme.bodyMedium),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: Text(l.backup_modeMerge),
              subtitle: Text(l.backup_modeMergeBody),
              onTap: () => Navigator.of(sheetContext).pop(ImportMode.mergeKeepExisting),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_sweep_outlined,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(l.backup_modeReplace),
              subtitle: Text(l.backup_modeReplaceBody),
              onTap: () => Navigator.of(sheetContext).pop(ImportMode.replaceAll),
            ),
            MicroSpacing.gapM,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final gate = ref.watch(featureGateProvider);
    final calendar = ref.watch(activeCalendarProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.backup_title)),
      body: SafeArea(
        child: ListView(
          padding: MicroSpacing.page,
          children: [
            MicroCard(
              padding: EdgeInsets.zero,
              child: MicroListTile(
                title: l.backup_shareCalendarTitle,
                subtitle: calendar == null
                    ? l.backup_shareCalendarBody
                    : '${calendar.name} — ${l.backup_shareCalendarBody}',
                leading: const Icon(Icons.ios_share),
                onTap: _busy ? null : () => _run(_shareCalendar),
              ),
            ),
            MicroSpacing.gapL,
            MicroCard(
              padding: EdgeInsets.zero,
              child: MicroListTile(
                title: l.backup_createTitle,
                subtitle: l.backup_createBody,
                leading: const Icon(Icons.save_alt),
                trailingText: gate.allows(FeatureKey.backupRestore) ? null : 'PRO',
                onTap: _busy ? null : () => _run(_createBackup),
              ),
            ),
            MicroSpacing.gapL,
            MicroCard(
              padding: EdgeInsets.zero,
              child: MicroListTile(
                title: l.backup_restoreTitle,
                subtitle: l.backup_restoreBody,
                leading: const Icon(Icons.folder_open),
                onTap: _busy ? null : () => _run(_restore),
              ),
            ),
            if (_busy) ...[
              MicroSpacing.gapXL,
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../data/qr_backup_source.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/neon.dart';

/// «I tuoi dati»: backup (Pro, `backupRestore`) e ripristino (gratis), come Film Tracker.
///
/// ⚑ La voce Pro **si vede anche senza il Pro**, con il badge: toccarla apre il paywall con
/// quella funzione evidenziata. Nasconderla vorrebbe dire non far sapere che esiste.
class DataSection extends ConsumerWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final gate = ref.watch(featureGateProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(l.data_title),
        ListTile(
          key: const ValueKey('data_backup'),
          leading: const Icon(Icons.save_alt),
          title: Text(l.backup_create),
          subtitle: Text(l.backup_createBody),
          trailing: gate.allows(FeatureKey.backupRestore) ? null : const ProBadge(),
          onTap: () => unawaited(createBackup(context, ref)),
        ),
        ListTile(
          key: const ValueKey('data_restore'),
          leading: const Icon(Icons.settings_backup_restore),
          title: Text(l.backup_restore),
          subtitle: Text(l.backup_restoreBody),
          onTap: () => unawaited(restoreBackup(context, ref)),
        ),
      ],
    );
  }
}

/// Crea il backup completo **con i loghi** (uno ZIP) e lo condivide (Pro).
Future<void> createBackup(BuildContext context, WidgetRef ref) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.backupRestore)) {
    await showQrPaywall(context, ref, highlight: FeatureKey.backupRestore);
    return;
  }
  final l = L.of(context);
  final service = ref.read(backupServiceProvider);
  final source = QrBackupSource(ref.read(databaseProvider), paths: ref.read(appPathsProvider));
  final result = await _withProgress(
    context,
    l.backup_creating,
    () => service.createBackup(source, label: l.appTitle, includeImages: true),
  );
  if (!context.mounted) return;
  await result.fold(
    ok: (file) => service.shareBackup(file, subject: l.backup_subject),
    err: (_) async => MicroSnack.error(context, l.backup_createFailed),
  );
}

/// Ripristina da un backup: sceglie il file, mostra cosa contiene, chiede come, poi agisce.
///
/// ⚑ **Gratis**: chi passa a un telefono nuovo deve riavere i suoi dati anche prima di aver
/// ripristinato l'acquisto. Il Pro si vende sulla creazione del backup.
///
/// ☠ «Sostituisci tutto» e' irreversibile, loghi compresi: il riepilogo prima della conferma e'
/// il solo modo per accorgersi di aver scelto il file sbagliato.
Future<void> restoreBackup(BuildContext context, WidgetRef ref) async {
  final l = L.of(context);
  final service = ref.read(backupServiceProvider);
  final file = await service.pickBackupFile();
  if (file == null || !context.mounted) return;

  final inspected = await service.inspect(file);
  if (!context.mounted) return;
  final manifest = inspected.valueOrNull;
  if (manifest == null || manifest.schemaId != QrBackupSource.id) {
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
                    manifest.itemCounts['favorites'] ?? 0,
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

  final restored = await _withProgress(
    context,
    l.backup_restoring,
    () => service.restore(
      file,
      QrBackupSource(ref.read(databaseProvider), paths: ref.read(appPathsProvider)),
      mode: mode,
    ),
  );
  if (!context.mounted) return;
  restored.fold(
    ok: (_) => MicroSnack.success(context, l.backup_restored),
    err: (_) => MicroSnack.error(context, l.backup_failed),
  );
}

/// Esegue [work] con un dialogo d'attesa che non si chiude toccando fuori.
Future<T> _withProgress<T>(BuildContext context, String message, Future<T> Function() work) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              MicroSpacing.hGapL,
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    return await work();
  } finally {
    navigator.pop();
  }
}

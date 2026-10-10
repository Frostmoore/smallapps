import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/entitlement.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../data/database.dart' show Negozio;
import '../../data/spending_backup_source.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/csv_export.dart';
import '../common/scelte.dart';

/// «I tuoi dati» (develop_microapps.md F12.1.12, `ImpostazioniPage`; come Film Tracker): backup
/// **Pro** (`backupRestore`), ripristino **gratis**, CSV **Pro** (`csvExport`).
///
/// ⚑ Le voci Pro **si vedono anche senza il Pro**, col badge: toccarle apre il paywall con quella
/// funzione evidenziata. Nasconderle vorrebbe dire non far sapere che esistono.
/// ⚑ Il ripristino e' gratis: chi passa a un telefono nuovo deve riavere le sue spese anche prima
/// di aver ripristinato l'acquisto.
class DataSection extends ConsumerWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final gate = ref.watch(featureGateProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Sezione(l.dati_titolo),
        ListTile(
          key: const ValueKey('dati_backup'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.save_alt),
          title: Text(l.backup_crea),
          subtitle: Text(l.backup_creaTesto),
          trailing: gate.allows(FeatureKey.backupRestore) ? null : const ProBadge(),
          onTap: () => unawaited(creaBackup(context, ref)),
        ),
        ListTile(
          key: const ValueKey('dati_ripristino'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.settings_backup_restore),
          title: Text(l.backup_ripristina),
          subtitle: Text(l.backup_ripristinaTesto),
          onTap: () => unawaited(ripristinaBackup(context, ref)),
        ),
        ListTile(
          key: const ValueKey('dati_csv'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.table_chart_outlined),
          title: Text(l.csv_titolo),
          subtitle: Text(l.csv_testo),
          trailing: gate.allows(FeatureKey.csvExport) ? null : const ProBadge(),
          onTap: () => unawaited(esportaCsv(context, ref)),
        ),
      ],
    );
  }
}

/// Crea il backup (un JSON: nessuna immagine da conservare, F12.1.10) e lo condivide (Pro).
Future<void> creaBackup(BuildContext context, WidgetRef ref) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.backupRestore)) {
    await showSrPaywall(context, ref, highlight: FeatureKey.backupRestore);
    return;
  }
  final l = L.of(context);
  final service = ref.read(backupServiceProvider);
  final result = await _conAttesa(
    context,
    l.backup_inCorso,
    () => service.createBackup(ref.read(backupSourceProvider), label: l.appTitle),
  );
  if (!context.mounted) return;
  await result.fold(
    ok: (file) => service.shareBackup(file, subject: l.backup_oggetto),
    err: (_) async => MicroSnack.error(context, l.backup_creaFallito),
  );
}

/// Ripristina da un backup: sceglie il file, mostra cosa contiene, chiede come, poi agisce.
/// ☠ «Sostituisci tutto» e' irreversibile: il riepilogo prima della conferma e' il solo modo per
/// accorgersi di aver scelto il file sbagliato.
Future<void> ripristinaBackup(BuildContext context, WidgetRef ref) async {
  final l = L.of(context);
  final service = ref.read(backupServiceProvider);
  final file = await service.pickBackupFile();
  if (file == null || !context.mounted) return;
  final manifest = (await service.inspect(file)).valueOrNull;
  if (!context.mounted) return;
  if (manifest == null || manifest.schemaId != SpendingBackupSource.id) {
    MicroSnack.error(context, l.backup_fallito);
    return;
  }
  final modo = await showModalBottomSheet<ImportMode>(
    context: context,
    showDragHandle: true,
    builder: (foglio) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.backup_ripristinaTitolo, style: Theme.of(foglio).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(l.backup_riepilogo(manifest.itemCounts['spese'] ?? 0, manifest.itemCounts['negozi'] ?? 0)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: Text(l.backup_modoSostituisci),
            subtitle: Text(l.backup_modoSostituisciTesto),
            onTap: () => Navigator.of(foglio).pop(ImportMode.replaceAll),
          ),
          ListTile(
            leading: const Icon(Icons.merge_type),
            title: Text(l.backup_modoUnisci),
            subtitle: Text(l.backup_modoUnisciTesto),
            onTap: () => Navigator.of(foglio).pop(ImportMode.mergeKeepExisting),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
  if (modo == null || !context.mounted) return;
  final fatto = await _conAttesa(
    context,
    l.backup_ripristinoInCorso,
    () => service.restore(file, ref.read(backupSourceProvider), mode: modo),
  );
  if (!context.mounted) return;
  fatto.fold(
    ok: (_) => MicroSnack.success(context, l.backup_ripristinato),
    err: (_) => MicroSnack.error(context, l.backup_fallito),
  );
}

/// L'export CSV di tutte le spese chiuse (Pro), condiviso come file.
Future<void> esportaCsv(BuildContext context, WidgetRef ref) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.csvExport)) {
    await showSrPaywall(context, ref, highlight: FeatureKey.csvExport);
    return;
  }
  final l = L.of(context);
  final repo = ref.read(spesaRepositoryProvider);
  final chiuse = await repo.osservaChiuse().first;
  final negozi = {for (final Negozio n in await repo.osservaNegozi().first) n.id: n.nome};
  if (!context.mounted) return;
  if (chiuse.isEmpty) {
    MicroSnack.show(context, l.csv_vuoto);
    return;
  }
  try {
    final testo = ref.read(csvExportProvider).costruisci(chiuse, negozi, l: l);
    final paths = ref.read(appPathsProvider);
    if (!paths.exports.existsSync()) await paths.exports.create(recursive: true);
    final file = paths.file(paths.exports, CsvExport.nomeFile(CivilDate.fromDateTime(DateTime.now())));
    await file.writeAsString(testo, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'text/csv')], subject: l.csv_titolo));
  } on Object catch (e, s) {
    MicroLog.e('export CSV', error: e, stackTrace: s);
    if (context.mounted) MicroSnack.error(context, l.csv_fallito);
  }
}

/// Esegue [lavoro] con un dialogo d'attesa che non si chiude toccando fuori.
Future<T> _conAttesa<T>(BuildContext context, String messaggio, Future<T> Function() lavoro) async {
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
              const SizedBox(width: 16),
              Expanded(child: Text(messaggio)),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    return await lavoro();
  } finally {
    navigator.pop();
  }
}

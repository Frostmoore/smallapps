import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';
import 'package:printing/printing.dart';

import '../../app/entitlement.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../domain/film_stats.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/csv_export.dart';
import '../../services/film_backup_source.dart';
import '../../services/year_report.dart';
import '../common/film_strip.dart';

/// Il servizio di backup di micro_core, con le cartelle dell'app e la sua versione.
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(paths: ref.watch(appPathsProvider), appVersion: appVersion),
);

/// La sezione "I tuoi dati" delle impostazioni (F6.10, F6.11): statistiche, PDF dell'anno,
/// CSV e backup (Pro), ripristino (gratis).
///
/// ⚑ Le voci Pro **si vedono anche senza il Pro**, con il badge: toccarle apre il paywall con
/// quella funzione evidenziata. Nasconderle vorrebbe dire non far sapere che esistono (stessa
/// scelta di Scorte Calore).
class DataSection extends ConsumerWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final gate = ref.watch(featureGateProvider);
    Widget? badge(FeatureKey key) => gate.allows(key) ? null : const ProBadge();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: MicroSpacing.m),
          child: SectionLabel(l.data_title),
        ),
        ListTile(
          key: const ValueKey('data_stats'),
          leading: const Icon(Icons.insights_outlined),
          title: Text(l.stats_title),
          subtitle: Text(l.data_statsBody),
          trailing: badge(FeatureKey.statistics),
          onTap: () => unawaited(openStats(context, ref)),
        ),
        ListTile(
          key: const ValueKey('data_report'),
          leading: const Icon(Icons.picture_as_pdf_outlined),
          title: Text(l.report_title),
          subtitle: Text(l.report_body),
          trailing: badge(FeatureKey.pdfReport),
          onTap: () => unawaited(createYearReport(context, ref)),
        ),
        ListTile(
          key: const ValueKey('data_csv'),
          leading: const Icon(Icons.table_view_outlined),
          title: Text(l.csv_export),
          subtitle: Text(l.csv_exportBody),
          trailing: badge(FeatureKey.csvExport),
          onTap: () => unawaited(exportCsv(context, ref)),
        ),
        ListTile(
          key: const ValueKey('data_backup'),
          leading: const Icon(Icons.save_alt),
          title: Text(l.backup_create),
          subtitle: Text(l.backup_createBody),
          trailing: badge(FeatureKey.backupRestore),
          onTap: () => unawaited(createBackup(context, ref)),
        ),
        // Il ripristino e' gratis: vedi restoreBackup qui sotto.
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

/// Apre le statistiche (Pro). Senza il Pro apre il paywall invece della pagina: arrivare a
/// un lucchetto per poi toccare "Sblocca" sarebbe un passaggio in piu'. La pagina ha
/// comunque il suo `ProGate`.
Future<void> openStats(BuildContext context, WidgetRef ref) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.statistics)) {
    await showFilmPaywall(context, ref, highlight: FeatureKey.statistics);
    return;
  }
  await context.push(Routes.stats);
}

/// Crea il PDF di riepilogo dell'anno [year] (Pro) e chiede se stamparlo o condividerlo.
/// Senza [year] lo chiede all'utente quando ci sono rullini in piu' anni.
///
/// ⚑ Gli ingressi si leggono **adesso** dal repository e non dai provider della pagina delle
/// statistiche: dalle impostazioni quegli stream non sono mai stati ascoltati, e il loro
/// `value` sarebbe vuoto.
Future<void> createYearReport(BuildContext context, WidgetRef ref, {int? year}) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.pdfReport)) {
    await showFilmPaywall(context, ref, highlight: FeatureKey.pdfReport);
    return;
  }
  final l = L.of(context);
  final repo = ref.read(repositoryProvider);
  const calculator = FilmStatsCalculator();
  final statsRolls = await repo.statsRolls();
  if (!context.mounted) return;

  var chosen = year;
  if (chosen == null) {
    final years = calculator.years(statsRolls);
    if (years.isEmpty) {
      MicroSnack.show(context, l.report_noRolls);
      return;
    }
    chosen = years.length == 1 ? years.single : await _pickYear(context, l, years);
    if (chosen == null || !context.mounted) return;
  }
  final y = chosen;

  final paths = ref.read(appPathsProvider);
  final today = ref.read(todayProvider);
  Uint8List? bytes;
  try {
    bytes = await _withProgress(context, l.report_building, () async {
      final items = rollsOfYear(await repo.rollItems(), y);
      final stats = calculator.forYear(y, statsRolls);
      final topCamera = stats.topCameraId == null ? null : await repo.cameraById(stats.topCameraId!);
      return buildYearReport(
        l: l,
        stats: stats,
        rolls: [
          for (final i in items) YearReportRoll(item: i, images: await repo.imagesFor(i.roll.id)),
        ],
        font: await loadReportFont(),
        readImage: (relative) => AtomicFile.readBytesOrNull(paths.resolve(relative)),
        today: today,
        topCameraName: topCamera == null ? null : '${topCamera.manufacturer} ${topCamera.model}',
      );
    });
  } on Object catch (error, stack) {
    // `on Object`: un'immagine rovinata puo' far lanciare un Error al pacchetto pdf, e
    // l'utente deve vedere "riprova", non un crash.
    MicroLog.e('PDF annuale fallito', error: error, stackTrace: stack);
  }
  if (!context.mounted) return;
  final pdf = bytes;
  if (pdf == null) {
    MicroSnack.error(context, l.report_failed);
    return;
  }

  final fileName = 'film-tracker-$y.pdf';
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(MicroSpacing.l, 0, MicroSpacing.l, MicroSpacing.s),
            child: Text(l.report_ready(y.toString()), style: Theme.of(sheet).textTheme.titleLarge),
          ),
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: Text(l.report_print),
            subtitle: Text(l.report_printBody),
            onTap: () => Navigator.of(sheet).pop('print'),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: Text(l.report_share),
            subtitle: Text(l.report_shareBody),
            onTap: () => Navigator.of(sheet).pop('share'),
          ),
          MicroSpacing.gapM,
        ],
      ),
    ),
  );
  switch (action) {
    case 'print':
      // L'anteprima di sistema: da li' si stampa o si salva come PDF (Android e iOS).
      await Printing.layoutPdf(onLayout: (_) async => pdf, name: fileName);
    case 'share':
      // ⚑ Lo stesso canale di CSV e backup (share_plus, gia' in micro_core), non
      // `Printing.sharePdf`: un modo solo di condividere file in tutta l'app.
      final file = paths.file(paths.exports, fileName);
      await AtomicFile.writeBytes(file, pdf);
      await ref.read(backupServiceProvider).shareBackup(file, subject: l.report_subject(y.toString()));
  }
}

Future<int?> _pickYear(BuildContext context, L l, List<int> years) => showModalBottomSheet<int>(
  context: context,
  showDragHandle: true,
  builder: (sheet) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(MicroSpacing.l, 0, MicroSpacing.l, MicroSpacing.s),
          child: Text(l.report_chooseYear, style: Theme.of(sheet).textTheme.titleLarge),
        ),
        for (final y in years)
          ListTile(title: Text(y.toString()), onTap: () => Navigator.of(sheet).pop(y)),
      ],
    ),
  ),
);

/// Esporta **tutti** i rullini in CSV e li condivide (Pro).
Future<void> exportCsv(BuildContext context, WidgetRef ref) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.csvExport)) {
    await showFilmPaywall(context, ref, highlight: FeatureKey.csvExport);
    return;
  }
  final l = L.of(context);
  final file = await exportRollsCsv(
    paths: ref.read(appPathsProvider),
    l: l,
    items: await ref.read(repositoryProvider).rollItems(),
    today: ref.read(todayProvider),
  );
  await ref.read(backupServiceProvider).shareBackup(file, subject: l.csv_subject);
}

/// Crea il backup completo **con le foto** (uno ZIP) e lo condivide (Pro).
Future<void> createBackup(BuildContext context, WidgetRef ref) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.backupRestore)) {
    await showFilmPaywall(context, ref, highlight: FeatureKey.backupRestore);
    return;
  }
  final l = L.of(context);
  final service = ref.read(backupServiceProvider);
  final source = FilmBackupSource(ref.read(databaseProvider), paths: ref.read(appPathsProvider));
  // ⚑ Con qualche centinaio di foto lo ZIP richiede secondi: senza un segno di vita l'utente
  // tocca di nuovo e ne parte un secondo.
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
/// ⚑ **Gratis**, al contrario della creazione: chi passa a un telefono nuovo deve poter
/// riavere i suoi dati anche prima di aver ripristinato l'acquisto. Il Pro si vende sulla
/// creazione del backup, non sul diritto di riaverli (stessa scelta di Full Freezer e Scorte
/// Calore).
///
/// ☠ Un ripristino "sostituisci tutto" e' irreversibile, foto comprese: il riepilogo prima
/// della conferma e' il solo modo per accorgersi di aver scelto il file sbagliato.
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
  if (manifest == null || manifest.schemaId != FilmBackupSource.id) {
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
                    manifest.itemCounts['rolls'] ?? 0,
                    manifest.itemCounts['cameras'] ?? 0,
                    manifest.itemCounts['images'] ?? 0,
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
      FilmBackupSource(ref.read(databaseProvider), paths: ref.read(appPathsProvider)),
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


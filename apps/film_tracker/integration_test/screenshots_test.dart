import 'dart:io';

import 'package:film_tracker/app/app_config.dart';
import 'package:film_tracker/app/routes.dart';
import 'package:film_tracker/features/photos/image_store_provider.dart';
import 'package:film_tracker/l10n/generated/app_localizations.dart';
import 'package:film_tracker/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// La lingua degli screenshot: `--dart-define=LINGUA=it` oppure `en`.
const String lingua = String.fromEnvironment('LINGUA', defaultValue: 'it');

/// Percorre l'app con i dati di esempio (foto comprese) e segnala ogni schermata da fotografare.
///
/// `ssh mac 'bash ~/microapps/tool/screenshots_ios.sh <UDID> it <cartella> film_tracker'`
///
/// Come in Scorte Calore: lo scatto lo fa il computer quando legge `SCATTO:<nome>` (cosi' esce
/// la barra di stato in posa), e i testi cercati vengono da `lookupL`, cosi' lo stesso codice
/// gira nelle due lingue. Serve `--dart-define=FT_DEMO=true`, che passa lo script.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot per gli store', (tester) async {
    binding.platformDispatcher.localesTestValue = <Locale>[Locale(lingua)];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);
    final l = lookupL(Locale(lingua));

    // Da zero: preferenze, database, foto e acquisto (il Pro di un giro precedente vive in
    // `entitlement.json`: senza cancellarlo il paywall non c'e').
    final config = buildFilmConfig();
    final settings = await SettingsStore.create(namespace: config.appId);
    await settings.clearNamespace();
    final documents = await getApplicationDocumentsDirectory();
    for (final suffix in const ['', '-wal', '-shm']) {
      final file = File('${p.join(documents.path, 'film_tracker.sqlite')}$suffix');
      if (file.existsSync()) file.deleteSync();
    }
    final paths = await AppPaths.forApp(appId: config.appId);
    final immagini = paths.resolve('images/$rollImageBucket').parent;
    if (immagini.existsSync()) immagini.deleteSync(recursive: true);
    final acquisto = paths.file(paths.support, 'entitlement.json');
    if (acquisto.existsSync()) acquisto.deleteSync();

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));

    Future<void> scatto(String nome) async {
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      // ignore: avoid_print
      print('SCATTO:$nome');
      await Future<void>.delayed(const Duration(seconds: 4));
    }

    GoRouter router() => GoRouter.of(tester.element(find.byType(Scaffold).first));

    Future<void> vai(String percorso) async {
      router().go(Routes.home);
      await tester.pumpAndSettle();
      router().push(percorso).ignore();
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    // ── La home: rullini in macchina e in laboratorio ─────────────────────────────
    await scatto('home');

    // ── Il foglio provini dell'archivio ──────────────────────────────────────────
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await scatto('provino');

    // ── Il dettaglio di "Dolomiti" (#3): cronologia e costi ──────────────────────────
    await vai(Routes.rollOf(3));
    await scatto('dettaglio');

    // ── Le sue foto: la prima a schermo intero ────────────────────────────────────
    final miniatura = find.byType(RollImageThumb);
    await tester.scrollUntilVisible(miniatura.first, 400, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(miniatura.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await scatto('foto');

    // ── L'etichetta QR ─────────────────────────────────────────────────────────
    await vai(Routes.qrOf(3));
    await scatto('qr');

    // ── Il Pro, dalle statistiche ───────────────────────────────────────────────
    //
    // ⚑ Il paywall NON va nelle schede (il prezzo cambia da paese a paese): serve ad Apple,
    // che per approvare il prodotto vuole lo screenshot della schermata in cui lo si compra.
    await vai(Routes.stats);
    await tester.tap(find.text(l.paywall_buy).first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await scatto('paywall-revisione');
    await tester.tap(find.byType(MicroPrimaryButton).last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();

    // Sbloccato: le statistiche dell'anno.
    await vai(Routes.stats);
    await scatto('statistiche');
  });
}

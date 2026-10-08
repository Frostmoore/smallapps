import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scorte_calore/app/app_config.dart';
import 'package:scorte_calore/app/routes.dart';
import 'package:scorte_calore/l10n/generated/app_localizations.dart';
import 'package:scorte_calore/main.dart' as app;

/// La lingua degli screenshot: `--dart-define=LINGUA=it` oppure `en`.
const String lingua = String.fromEnvironment('LINGUA', defaultValue: 'it');

/// Percorre l'app con i dati di esempio e segnala ogni schermata da fotografare.
///
/// `ssh mac 'bash ~/microapps/tool/screenshots_ios.sh <UDID> it <cartella> scorte_calore'`
///
/// Come in Full Freezer: lo scatto lo fa il computer quando legge `SCATTO:<nome>` (cosi' esce
/// la barra di stato in posa), e i testi cercati vengono da `lookupL`, cosi' lo stesso codice
/// gira nelle due lingue. Serve `--dart-define=SC_DEMO=true`, che passa lo script: i dati di
/// esempio si scrivono all'avvio, con i nomi nella lingua del giro.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot per gli store', (tester) async {
    binding.platformDispatcher.localesTestValue = <Locale>[Locale(lingua)];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);
    final l = lookupL(Locale(lingua));

    // Da zero: preferenze, database e acquisto (il Pro di un giro precedente vive in
    // `entitlement.json`: senza cancellarlo il paywall non c'e').
    final config = buildScorteConfig();
    final settings = await SettingsStore.create(namespace: config.appId);
    await settings.clearNamespace();
    final documents = await getApplicationDocumentsDirectory();
    final support = await getApplicationSupportDirectory();
    for (final dir in [documents.path, support.path]) {
      for (final suffix in const ['', '-wal', '-shm']) {
        final file = File('${p.join(dir, 'scorte_calore.sqlite')}$suffix');
        if (file.existsSync()) file.deleteSync();
      }
    }
    final paths = await AppPaths.forApp(appId: config.appId);
    final acquisto = paths.file(paths.support, 'entitlement.json');
    if (acquisto.existsSync()) acquisto.deleteSync();

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    Future<void> scatto(String nome) async {
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 800));
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

    // ── La home: la stufa in testata ───────────────────────────────────────────
    await scatto('home');

    // ── Il bombolone: la lettura del manometro diventa litri utili ─────────────────
    await tester.tap(find.text(lingua == 'it' ? 'Bombolone GPL' : 'LPG tank'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text(l.home_update));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '42');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await scatto('aggiornamento');
    Navigator.of(tester.element(find.byType(TextField).first)).pop();
    await tester.pumpAndSettle();
    // Di nuovo la stufa in testata, per le pagine successive.
    await tester.tap(find.text(lingua == 'it' ? 'Stufa soggiorno' : 'Living room stove'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // ── Il Pro, dal riquadro bloccato dei grafici ───────────────────────────────
    //
    // ⚑ Il paywall NON va nelle schede (il prezzo cambia da paese a paese): serve ad Apple,
    // che per approvare il prodotto vuole lo screenshot della schermata in cui lo si compra.
    await vai(Routes.historyOf(1));
    await tester.tap(find.byType(ProBadge).first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await scatto('paywall-revisione');
    await tester.tap(find.byType(MicroPrimaryButton).last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();

    // Sbloccato: lo storico con i grafici, poi acquisti e costi.
    await vai(Routes.historyOf(1));
    await scatto('storico');

    await vai(Routes.purchasesOf(1));
    await scatto('costi');

    router().go(Routes.home);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await scatto('home-pro');
  });
}

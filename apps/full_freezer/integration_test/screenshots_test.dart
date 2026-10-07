import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/app/app_config.dart';
import 'package:full_freezer/app/routes.dart';
import 'package:full_freezer/l10n/generated/app_localizations.dart';
import 'package:full_freezer/main.dart' as app;
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// La lingua degli screenshot: `--dart-define=LINGUA=it` oppure `en`.
const String lingua = String.fromEnvironment('LINGUA', defaultValue: 'it');

/// Percorre l'app con i dati di esempio e segnala ogni schermata da fotografare.
///
/// `ssh mac 'bash ~/microapps/tool/screenshots_ios.sh <UDID> it <cartella> full_freezer'`
///
/// Come in TrashCan (vedi `apps/trashcan/integration_test/screenshots_test.dart`): lo scatto
/// lo fa il computer quando legge `SCATTO:<nome>`, perche' cosi' esce anche la barra di
/// stato in posa; i testi cercati vengono da `lookupL`, cosi' lo stesso codice gira nelle
/// due lingue. Serve `--dart-define=FF_DEMO=true` (lo passa lo script): i dati di esempio
/// si scrivono all'avvio, con i nomi nella lingua del giro.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot per gli store', (tester) async {
    binding.platformDispatcher.localesTestValue = <Locale>[Locale(lingua)];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);
    final l = lookupL(Locale(lingua));

    // Da zero: preferenze, database e acquisto. Il Pro comprato in un giro precedente vive
    // in `entitlement.json` (lezione di TrashCan): senza cancellarlo il paywall non c'e'.
    final config = buildFreezerConfig();
    final settings = await SettingsStore.create(namespace: config.appId);
    await settings.clearNamespace();
    final documents = await getApplicationDocumentsDirectory();
    for (final suffix in const ['', '-wal', '-shm']) {
      final file = File('${p.join(documents.path, 'full_freezer.sqlite')}$suffix');
      if (file.existsSync()) file.deleteSync();
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
      // `push` e non `go`: le pagine hanno la freccia indietro, come quando ci si arriva a mano.
      router().push(percorso).ignore();
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    // ── La home ─────────────────────────────────────────────────────────────
    await scatto('home');

    // ── L'inserimento rapido, con un nome gia' scritto ─────────────────────────────
    await tester.tap(find.text(l.home_add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, lingua == 'it' ? 'Lasagne della nonna' : "Grandma's lasagne");
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await scatto('inserimento');
    Navigator.of(tester.element(find.byType(TextField).first)).pop();
    await tester.pumpAndSettle();

    // ── La ricerca senza accenti: "ragu" trova "Ragu'" ───────────────────────────────
    await vai(Routes.search);
    await tester.enterText(find.byType(TextField).first, lingua == 'it' ? 'pol' : 'sau');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await scatto('ricerca');

    // ── Il freezer: riempimento e scomparti ────────────────────────────────────────
    await vai(Routes.freezerOf(1));
    await scatto('freezer');

    // ── Il Pro, dal lucchetto delle statistiche ──────────────────────────────────────
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

    // Sbloccato: la stessa pagina ora mostra le statistiche.
    await vai(Routes.stats);
    await scatto('statistiche');

    await vai(Routes.history);
    await scatto('storico');
  });
}

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

/// La lingua del video: `--dart-define=LINGUA=it` oppure `en`.
const String lingua = String.fromEnvironment('LINGUA', defaultValue: 'it');

/// Il giro dell'app per l'anteprima video dell'App Store (15–30 secondi).
///
/// `ssh mac 'bash ~/microapps/apps/scorte_calore/tool/anteprima_app_store.sh <UDID> it'`
///
/// Lo script registra lo schermo fra `REGISTRA` e `FINE`. Prima di `REGISTRA` il test sblocca
/// il Pro (fuori dall'inquadratura: il prezzo cambia da paese a paese e Apple non lo vuole nei
/// video), dopo `FINE` non succede piu' niente. I tempi sono scelti per stare sotto i 30 s.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('anteprima per l App Store', (tester) async {
    binding.platformDispatcher.localesTestValue = <Locale>[Locale(lingua)];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);
    final l = lookupL(Locale(lingua));

    final config = buildScorteConfig();
    final settings = await SettingsStore.create(namespace: config.appId);
    await settings.clearNamespace();
    final documents = await getApplicationDocumentsDirectory();
    for (final suffix in const ['', '-wal', '-shm']) {
      final file = File('${p.join(documents.path, 'scorte_calore.sqlite')}$suffix');
      if (file.existsSync()) file.deleteSync();
    }
    final paths = await AppPaths.forApp(appId: config.appId);
    final acquisto = paths.file(paths.support, 'entitlement.json');
    if (acquisto.existsSync()) acquisto.deleteSync();

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    GoRouter router() => GoRouter.of(tester.element(find.byType(Scaffold).first));

    // Il Pro, a telecamera spenta: serve per i grafici.
    router().push(Routes.historyOf(1)).ignore();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byType(ProBadge).first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byType(MicroPrimaryButton).last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    router().go(Routes.home);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    Future<void> pausa(int ms) async {
      final fine = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(fine)) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    // ignore: avoid_print
    print('REGISTRA');
    await pausa(3500);

    // Il bombolone in testata, poi la lettura del manometro.
    await tester.tap(find.text(lingua == 'it' ? 'Bombolone GPL' : 'LPG tank'));
    await pausa(2200);
    await tester.tap(find.text(l.home_update));
    await pausa(1200);
    final campo = find.byType(TextField).first;
    for (final testo in const ['4', '42']) {
      await tester.enterText(campo, testo);
      await pausa(500);
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await pausa(2600);
    Navigator.of(tester.element(campo)).pop();
    await pausa(900);

    // Di nuovo la stufa, poi lo storico con i grafici.
    await tester.tap(find.text(lingua == 'it' ? 'Stufa soggiorno' : 'Living room stove'));
    await pausa(1500);
    router().push(Routes.historyOf(1)).ignore();
    await pausa(3200);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await pausa(2000);

    // Acquisti e costi.
    router().pop();
    await pausa(500);
    router().push(Routes.purchasesOf(1)).ignore();
    await pausa(3500);
    router().pop();
    await pausa(2500);

    // ignore: avoid_print
    print('FINE');
    await pausa(1000);
  });
}

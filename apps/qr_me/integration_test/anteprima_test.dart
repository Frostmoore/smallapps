import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qr_me/app/app_config.dart';
import 'package:qr_me/app/routes.dart';
import 'package:qr_me/data/database.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/main.dart' as app;

/// La lingua del video: `--dart-define=LINGUA=it` oppure `en`.
const String lingua = String.fromEnvironment('LINGUA', defaultValue: 'it');

/// Il giro dell'app per l'anteprima video dell'App Store (15–30 secondi).
///
/// `ssh mac 'bash ~/microapps/apps/qr_me/tool/anteprima_app_store.sh <UDID> it'`
///
/// Lo script registra lo schermo fra `REGISTRA` e `FINE`. Il giro: la home, il Wi-Fi di casa a
/// tutto schermo, il suo stile con la verifica «Leggibile», il modulo Wi-Fi, un link letto e
/// rimostrato come QR. Niente paywall (il prezzo cambia da paese a paese e Apple non lo vuole
/// nei video): il Pro si compra con il gateway finto **prima** di `REGISTRA`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('anteprima per l App Store', (tester) async {
    binding.platformDispatcher.localesTestValue = <Locale>[Locale(lingua)];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);

    final config = buildQrConfig();
    final settings = await SettingsStore.create(namespace: config.appId);
    await settings.clearNamespace();
    final documents = await getApplicationDocumentsDirectory();
    for (final suffix in const ['', '-wal', '-shm']) {
      final file = File('${p.join(documents.path, 'qr_me.sqlite')}$suffix');
      if (file.existsSync()) file.deleteSync();
    }
    final paths = await AppPaths.forApp(appId: config.appId);
    final acquisto = paths.file(paths.support, 'entitlement.json');
    if (acquisto.existsSync()) acquisto.deleteSync();

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));
    GoRouter router() => GoRouter.of(tester.element(find.byType(Scaffold).first));

    Future<void> pausa(int ms) async {
      final fine = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(fine)) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    // Il Pro, fuori dalla registrazione: paywall dal modulo Wi-Fi e acquisto finto.
    await tester.tap(find.byKey(const ValueKey('form_chip_wifi')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byType(MicroPrimaryButton).last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    router().go(Routes.home);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // ignore: avoid_print
    print('REGISTRA');
    await pausa(3000);

    // Il Wi-Fi di casa (riga 1) a tutto schermo.
    router().push(Routes.qrOf(1)).ignore();
    await pausa(3200);

    // Il suo stile: la verifica di leggibilita' compare da sola.
    await tester.tap(find.byKey(const ValueKey('action_style')));
    await pausa(4200);
    router().pop();
    await pausa(600);
    router().pop();
    await pausa(800);

    // Il modulo Wi-Fi in modifica.
    router().push(Routes.formOf(QrKind.wifi, id: 1)).ignore();
    await pausa(3000);
    router().pop();
    await pausa(800);

    // Un link letto, poi di nuovo come QR.
    router()
        .push(
          Routes.scanResult,
          extra: const ScanResultArgs(raw: 'https://smpmicroapps.it/contatti', source: QrSource.scanned),
        )
        .ignore();
    await pausa(3000);
    await tester.tap(find.byKey(const ValueKey('result_show')));
    await pausa(3000);
    router().go(Routes.home);
    await pausa(2000);

    // ignore: avoid_print
    print('FINE');
    await pausa(1000);
  });
}

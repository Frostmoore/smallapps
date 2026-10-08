import 'dart:io';

import 'package:film_tracker/app/app_config.dart';
import 'package:film_tracker/app/routes.dart';
import 'package:film_tracker/features/photos/image_store_provider.dart';
import 'package:film_tracker/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// La lingua del video: `--dart-define=LINGUA=it` oppure `en`.
const String lingua = String.fromEnvironment('LINGUA', defaultValue: 'it');

/// Il giro dell'app per l'anteprima video dell'App Store (15–30 secondi).
///
/// `ssh mac 'bash ~/microapps/apps/film_tracker/tool/anteprima_app_store.sh <UDID> it'`
///
/// Lo script registra lo schermo fra `REGISTRA` e `FINE`. Il giro: la home, il foglio provini,
/// un rullino con la sua cronologia, una foto a schermo intero, l'etichetta QR. Niente paywall
/// (il prezzo cambia da paese a paese e Apple non lo vuole nei video).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('anteprima per l App Store', (tester) async {
    binding.platformDispatcher.localesTestValue = <Locale>[Locale(lingua)];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);

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

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));
    GoRouter router() => GoRouter.of(tester.element(find.byType(Scaffold).first));

    Future<void> pausa(int ms) async {
      final fine = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(fine)) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> scorri(double dy, int passi) async {
      for (var i = 0; i < passi; i++) {
        await tester.drag(find.byType(Scrollable).first, Offset(0, dy / passi));
        await pausa(60);
      }
    }

    // ignore: avoid_print
    print('REGISTRA');
    await pausa(3200);

    // Giu' fino al foglio provini, con calma.
    await scorri(-900, 12);
    await pausa(2600);

    // Un rullino dell'archivio: "Dolomiti" (#3), la cronologia.
    router().push(Routes.rollOf(3)).ignore();
    await pausa(2800);
    await scorri(-600, 8);
    await pausa(1200);

    // La sua prima foto a schermo intero.
    final miniatura = find.byType(RollImageThumb);
    await tester.scrollUntilVisible(miniatura.first, 300, scrollable: find.byType(Scrollable).first);
    await pausa(500);
    await tester.tap(miniatura.first);
    await pausa(3000);
    router().pop();
    await pausa(800);

    // L'etichetta QR.
    router().push(Routes.qrOf(3)).ignore();
    await pausa(3200);
    router().go(Routes.home);
    await pausa(2200);

    // ignore: avoid_print
    print('FINE');
    await pausa(1000);
  });
}

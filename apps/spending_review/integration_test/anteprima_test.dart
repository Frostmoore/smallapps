import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:spending_review/app/app_config.dart';
import 'package:spending_review/app/routes.dart';
import 'package:spending_review/domain/tastierino.dart';
import 'package:spending_review/features/spesa/azioni_spesa.dart';
import 'package:spending_review/features/spesa/spesa_page.dart';
import 'package:spending_review/main.dart' as app;

import 'letture_finte.dart';

/// La lingua del video: `--dart-define=LINGUA=it` oppure `en`.
const String lingua = String.fromEnvironment('LINGUA', defaultValue: 'it');

/// Il giro dell'app per l'anteprima video dell'App Store (15–30 secondi).
///
/// `ssh mac 'bash ~/microapps/apps/spending_review/tool/anteprima_app_store.sh <UDID> it'`
///
/// Lo script registra lo schermo fra `REGISTRA` e `FINE` (~27 s, Apple vuole 15–30). Il giro: la
/// spesa col budget, lo scontrino confrontato con il conto, un cartellino letto e aggiunto (il
/// totale sale), l'etichetta della bilancia aggiunta, «2 × 1,49 +» sul tastierino, le statistiche
/// col budget del mese, lo storico. ⚑ Lo scontrino PRIMA delle aggiunte: dopo, il confronto
/// mostrerebbe le righe nuove come «non sullo scontrino». Niente paywall (il prezzo cambia da
/// paese a paese e Apple non lo vuole nei video): il Pro si compra con il gateway finto **prima**
/// di `REGISTRA`. Letture finte come negli screenshot (`letture_finte.dart`).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('anteprima per l App Store', (tester) async {
    binding.platformDispatcher.localesTestValue = <Locale>[Locale(lingua)];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);
    final english = lingua != 'it';

    final config = buildSrConfig();
    final settings = await SettingsStore.create(namespace: config.appId);
    await settings.clearNamespace();
    final documents = await getApplicationDocumentsDirectory();
    for (final suffix in const ['', '-wal', '-shm']) {
      final file = File('${p.join(documents.path, 'spending_review.sqlite')}$suffix');
      if (file.existsSync()) file.deleteSync();
    }
    final paths = await AppPaths.forApp(appId: config.appId);
    final acquisto = paths.file(paths.support, 'entitlement.json');
    if (acquisto.existsSync()) acquisto.deleteSync();

    await app.main();

    Future<void> pausa(int ms) async {
      final fine = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(fine)) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    await pausa(4000);
    GoRouter router() => GoRouter.of(tester.element(find.byType(Scaffold).first));
    BuildContext spesa() => tester.element(find.byType(SpesaPage));
    WidgetRef ref() => spesa() as WidgetRef;
    Future<void> tasto(TastoTastierino t) async {
      await tester.tap(find.byKey(ValueKey('tasto_${t.name}')));
      await pausa(260);
    }

    // Il Pro, fuori dalla registrazione: paywall dal tasto Scontrino e acquisto finto.
    await tester.tap(find.byKey(const ValueKey('spesa_scontrino')));
    await pausa(2000);
    await tester.tap(find.byType(MicroPrimaryButton).last);
    await pausa(3000);
    router().go(Routes.spesa);
    await pausa(1500);
    ScaffoldMessenger.of(spesa()).clearSnackBars();
    await pausa(500);

    // ignore: avoid_print
    print('REGISTRA');
    await pausa(2500);

    // Lo scontrino alla cassa: +0,95, il caffe' e il sacchetto.
    router().push(Routes.confronto, extra: scontrinoFinto(english: english)).ignore();
    await pausa(3800);
    router().go(Routes.spesa);
    await pausa(900);

    // Un cartellino in offerta, aggiunto: il totale sale.
    unawaited(gestisciRisultatoCartellino(spesa(), ref(), cartellinoFinto(english: english)));
    await pausa(2800);
    await tester.tap(find.byKey(const ValueKey('conferma_aggiungi')));
    await pausa(1500);

    // L'etichetta della bilancia, aggiunta.
    unawaited(gestisciRisultatoCartellino(spesa(), ref(), bilanciaFinta(english: english)));
    await pausa(2600);
    await tester.tap(find.byKey(const ValueKey('bilancia_aggiungi')));
    await pausa(1500);

    // Il tastierino «alla cassa»: 2 × 1,49 +.
    for (final t in [TastoTastierino.c2, TastoTastierino.per, TastoTastierino.c1, TastoTastierino.c4, TastoTastierino.c9]) {
      await tasto(t);
    }
    await pausa(500);
    await tasto(TastoTastierino.piu);
    await pausa(1500);

    // Le statistiche col budget del mese, poi lo storico.
    router().push(Routes.statistiche).ignore();
    await pausa(3200);
    router().go(Routes.spesa);
    await pausa(500);
    router().push(Routes.storico).ignore();
    await pausa(2500);
    router().go(Routes.spesa);
    await pausa(1500);

    // ignore: avoid_print
    print('FINE');
    await pausa(1000);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

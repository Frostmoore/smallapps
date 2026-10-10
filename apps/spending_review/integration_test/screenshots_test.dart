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
import 'package:spending_review/app/providers.dart';
import 'package:spending_review/app/routes.dart';
import 'package:spending_review/domain/tastierino.dart';
import 'package:spending_review/features/spesa/azioni_spesa.dart';
import 'package:spending_review/features/spesa/spesa_page.dart';
import 'package:spending_review/main.dart' as app;

import 'letture_finte.dart';

/// La lingua degli screenshot: `--dart-define=LINGUA=it` oppure `en`.
const String lingua = String.fromEnvironment('LINGUA', defaultValue: 'it');

/// Percorre l'app con i dati di esempio e segnala ogni schermata da fotografare: paywall (solo
/// per la revisione dell'IAP), spesa, cartellino, bilancia, scontrino, statistiche, storico.
///
/// `ssh mac 'bash ~/microapps/tool/screenshots_ios.sh <UDID> it <cartella> spending_review'`
///
/// Come in QR Me: lo scatto lo fa il computer quando legge `SCATTO:<nome>` (cosi' esce la barra di
/// stato in posa). Serve `--dart-define=SR_DEMO=true`, che passa lo script.
///
/// ⚑ Cartellino, bilancia e scontrino NON passano dalla fotocamera (il simulatore non ne ha una):
/// le righe OCR finte di `letture_finte.dart` vanno ai parser veri, e il risultato entra nel giro
/// vero dell'app (`gestisciRisultatoCartellino`, la rotta del confronto) da dove ci entrerebbe dopo
/// lo scatto. I fogli e le pagine fotografati sono quelli veri.
/// ☠ Niente `pumpAndSettle` dopo l'acquisto: il Pro apre il mirino dello scontrino, e la sua
/// rotellina (fotocamera assente) non si ferma mai. Si aspetta a tempo con [pausa].
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot per gli store', (tester) async {
    binding.platformDispatcher.localesTestValue = <Locale>[Locale(lingua)];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);
    final english = lingua != 'it';

    // Da zero: preferenze, database e acquisto (il Pro di un giro precedente vive in
    // `entitlement.json`: senza cancellarlo il paywall non c'e').
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
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> scatto(String nome) async {
      await pausa(1200);
      // ignore: avoid_print
      print('SCATTO:$nome');
      await pausa(4000);
    }

    await pausa(4000);
    GoRouter router() => GoRouter.of(tester.element(find.byType(Scaffold).first));
    BuildContext spesa() => tester.element(find.byType(SpesaPage));
    WidgetRef ref() => spesa() as WidgetRef;

    Future<void> chiudiFoglio(Key chiave) async {
      Navigator.of(tester.element(find.byKey(chiave))).pop();
      await pausa(800);
    }

    // ── Il paywall, dal tasto Scontrino ──────────────────────────────────────────────
    //
    // ⚑ Il paywall NON va nelle schede (il prezzo cambia da paese a paese): serve ad Apple, che per
    // approvare il prodotto vuole lo screenshot della schermata in cui lo si compra.
    await tester.tap(find.byKey(const ValueKey('spesa_scontrino')));
    await pausa(2000);
    await scatto('paywall-revisione');
    await tester.tap(find.byType(MicroPrimaryButton).last);
    await pausa(3000);
    router().go(Routes.spesa);
    await pausa(1500);
    ScaffoldMessenger.of(spesa()).clearSnackBars();
    await pausa(500);

    // ── LA schermata: la spesa in corso col budget, e «2 × 1,49» sul tastierino ──────────
    for (final t in [TastoTastierino.c2, TastoTastierino.per, TastoTastierino.c1, TastoTastierino.c4, TastoTastierino.c9]) {
      await tester.tap(find.byKey(ValueKey('tasto_${t.name}')));
      await pausa(150);
    }
    await scatto('spesa');
    ref().read(tastierinoProvider.notifier).svuota();

    // ── Il cartellino interpretato: prezzo, barrato, €/kg ────────────────────────────
    unawaited(gestisciRisultatoCartellino(spesa(), ref(), cartellinoFinto(english: english)));
    await pausa(1500);
    await scatto('cartellino');
    await chiudiFoglio(const ValueKey('conferma_aggiungi'));

    // ── L'etichetta della bilancia ─────────────────────────────────────────────────
    unawaited(gestisciRisultatoCartellino(spesa(), ref(), bilanciaFinta(english: english)));
    await pausa(1500);
    await scatto('bilancia');
    await chiudiFoglio(const ValueKey('bilancia_aggiungi'));

    // ── Lo scontrino alla cassa: il confronto con il contato ───────────────────────────
    router().push(Routes.confronto, extra: scontrinoFinto(english: english)).ignore();
    await pausa(2000);
    await scatto('scontrino');

    // ── Le statistiche col budget del mese (Pro) ─────────────────────────────────────
    router().go(Routes.spesa);
    await pausa(800);
    router().push(Routes.statistiche).ignore();
    await pausa(2000);
    await scatto('statistiche');

    // ── Lo storico, tutte le spese (Pro) ───────────────────────────────────────────
    router().go(Routes.spesa);
    await pausa(800);
    router().push(Routes.storico).ignore();
    await pausa(2000);
    await scatto('storico');
  }, timeout: const Timeout(Duration(minutes: 6)));
}

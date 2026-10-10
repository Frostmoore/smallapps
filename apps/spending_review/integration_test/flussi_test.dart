// I flussi principali sul dispositivo (F12.7), con il motore OCR VERO (Vision su iOS, PP-OCRv5 su
// Android), il database vero e le foto dei campioni:
//   flutter test integration_test/flussi_test.dart -d <simulatore> --dart-define=SR_FOTO=/tmp/f12vision
// ☠ Le foto NON stanno nel repo (licenze, dati personali): SR_FOTO punta a una cartella fuori
// (sul simulatore iOS un percorso del Mac si legge direttamente). Senza SR_FOTO il test salta.
//
// ⚑ L'unica cosa sostituita e' il SELETTORE di sistema delle foto (`scegliFotoProvider`), che un
// test non puo' toccare: restituisce una COPIA della foto del campione nella cartella temporanea
// dell'app, cioe' quello che fa image_picker. Cosi' il test dimostra anche che dopo la lettura la
// copia sparisce (F12.1.13). Il Pro e' finto (override di `isProProvider`), come in BILLING=fake.
// Fra un passo e l'altro stampa «SR_PASSO|<nome>» e aspetta 3 s: il tempo per uno screenshot
// (`xcrun simctl io booted screenshot`).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spending_review/app/app.dart';
import 'package:spending_review/app/app_config.dart';
import 'package:spending_review/app/entitlement.dart';
import 'package:spending_review/app/feature_limits.dart';
import 'package:spending_review/app/providers.dart';

const _cartellaFoto = String.fromEnvironment('SR_FOTO');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cartellino dalla galleria, bilancia, scontrino col Pro finto', (tester) async {
    if (_cartellaFoto.isEmpty || !Directory(_cartellaFoto).existsSync()) {
      markTestSkipped('SR_FOTO assente: le foto dei campioni non stanno nel repo');
      return;
    }
    final config = buildSrConfig();
    final paths = await AppPaths.forApp(appId: '${config.appId}_flussi');
    await paths.ensureAll();
    final settings = await SettingsStore.create(namespace: '${config.appId}_flussi');
    final temp = (await getTemporaryDirectory()).path;
    final copie = <String>[];
    var prossime = <String>[];

    Future<List<String>> scegli({required bool multiple}) async {
      final out = <String>[];
      for (final nome in prossime) {
        final copia = '$temp/sr_flussi_${copie.length}_$nome';
        File('$_cartellaFoto/$nome').copySync(copia);
        copie.add(copia);
        out.add(copia);
      }
      return out;
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          appPathsProvider.overrideWithValue(paths),
          settingsProvider.overrideWithValue(settings),
          scegliFotoProvider.overrideWithValue(scegli),
          isProProvider.overrideWithValue(true),
          featureGateProvider.overrideWithValue(FeatureGate(limits: srFeatureLimits, isPro: true)),
        ],
        child: const SpendingReviewApp(),
      ),
    );

    Future<void> aspetta(Finder f, {int secondi = 25}) async {
      for (var i = 0; i < secondi * 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (f.evaluate().isNotEmpty) return;
      }
      fail('non e\' comparso: $f');
    }

    Future<void> passo(String nome) async {
      // ignore: avoid_print
      print('SR_PASSO|$nome');
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    String testo(Key k) {
      final w = tester.widget(find.byKey(k));
      return w is Text ? (w.data ?? '') : '';
    }

    // 0. La spesa vuota.
    await aspetta(find.byKey(const ValueKey('spesa_cartellino')));
    await passo('home');

    // 1. Cartellino dalla galleria (ritaglio Esselunga «3,59 / Al kg 5,99»).
    prossime = ['c16_esselunga_nutkao_r0.jpg'];
    await tester.tap(find.byKey(const ValueKey('spesa_cartellino')));
    await aspetta(find.byKey(const ValueKey('cartellino_daFoto')));
    await passo('mirino');
    final sw = Stopwatch()..start();
    await tester.tap(find.byKey(const ValueKey('cartellino_daFoto')));
    await aspetta(find.byKey(const ValueKey('conferma_aggiungi')));
    // ignore: avoid_print
    print('SR_TEMPO|cartellino|${sw.elapsedMilliseconds}');
    await passo('conferma_cartellino');
    await tester.tap(find.byKey(const ValueKey('conferma_aggiungi')));
    await aspetta(find.byKey(const ValueKey('spesa_totale')));
    await passo('dopo_cartellino');
    // ignore: avoid_print
    print('SR_TOTALE|dopo il cartellino|${testo(const ValueKey('spesa_totale'))}');

    // 2. Etichetta della bilancia (Pam, orata 0,258 kg × 29,90 = 7,71), riconosciuta da sola.
    prossime = ['b01_pam_orata.jpg'];
    await tester.tap(find.byKey(const ValueKey('spesa_cartellino')));
    await aspetta(find.byKey(const ValueKey('cartellino_daFoto')));
    sw.reset();
    await tester.tap(find.byKey(const ValueKey('cartellino_daFoto')));
    await aspetta(find.byKey(const ValueKey('bilancia_aggiungi')).hitTestable());
    // ignore: avoid_print
    print('SR_TEMPO|bilancia|${sw.elapsedMilliseconds}');
    await passo('conferma_bilancia');
    await tester.tap(find.byKey(const ValueKey('bilancia_aggiungi')));
    await aspetta(find.byKey(const ValueKey('spesa_totale')));
    await passo('dopo_bilancia');
    // ignore: avoid_print
    print('SR_TOTALE|dopo la bilancia|${testo(const ValueKey('spesa_totale'))}');

    // 3. Scontrino (Pro): Emme Piu', totale 6,15 con uno sconto «0,40-».
    prossime = ['s06_emmepiu_offerta.jpg'];
    await tester.tap(find.byKey(const ValueKey('spesa_scontrino')));
    await aspetta(find.byKey(const ValueKey('scontrino_daFoto')));
    await tester.tap(find.byKey(const ValueKey('scontrino_daFoto')));
    await aspetta(find.byKey(const ValueKey('scontrino_leggi')));
    await passo('scontrino_miniature');
    sw.reset();
    await tester.tap(find.byKey(const ValueKey('scontrino_leggi')));
    await aspetta(find.byKey(const ValueKey('confronto_chiudi')));
    // ignore: avoid_print
    print('SR_TEMPO|scontrino|${sw.elapsedMilliseconds}');
    await passo('confronto');
    await tester.tap(find.byKey(const ValueKey('confronto_chiudi')));
    await aspetta(find.byKey(const ValueKey('chiusura_salva')));
    await passo('chiusura');
    await tester.tap(find.byKey(const ValueKey('chiusura_salva')));
    // Dopo «Salva» l'app apre lo storico (la spesa appena chiusa in cima), non la spesa nuova.
    for (var i = 0; i < 100 && find.byKey(const ValueKey('chiusura_salva')).evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byKey(const ValueKey('chiusura_salva')), findsNothing);
    await passo('storico');

    // ☠ Privacy (F12.1.13): nessuna copia delle foto resta nella cartella temporanea.
    expect([for (final c in copie) if (File(c).existsSync()) c], isEmpty);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

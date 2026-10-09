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

/// La lingua degli screenshot: `--dart-define=LINGUA=it` oppure `en`.
const String lingua = String.fromEnvironment('LINGUA', defaultValue: 'it');

/// Il link «letto» dello screenshot del risultato: il sito della piattaforma, una pagina vera.
const String linkLetto = 'https://smpmicroapps.it/contatti';

/// Percorre l'app con i dati di esempio e segnala ogni schermata da fotografare.
///
/// `ssh mac 'bash ~/microapps/tool/screenshots_ios.sh <UDID> it <cartella> qr_me'`
///
/// Come in Film Tracker: lo scatto lo fa il computer quando legge `SCATTO:<nome>` (cosi' esce la
/// barra di stato in posa). Serve `--dart-define=QM_DEMO=true`, che passa lo script. Il Wi-Fi di
/// casa dei dati di esempio e' la riga 1 (la prima scritta in un database vuoto).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot per gli store', (tester) async {
    binding.platformDispatcher.localesTestValue = <Locale>[Locale(lingua)];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);

    // Da zero: preferenze, database, loghi e acquisto (il Pro di un giro precedente vive in
    // `entitlement.json`: senza cancellarlo il paywall non c'e').
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

    Future<void> scatto(String nome, {Duration attesa = Duration.zero}) async {
      await tester.pumpAndSettle();
      if (attesa > Duration.zero) await tester.pumpAndSettle(attesa);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      // ignore: avoid_print
      print('SCATTO:$nome');
      await Future<void>.delayed(const Duration(seconds: 4));
    }

    GoRouter router() => GoRouter.of(tester.element(find.byType(Scaffold).first));

    Future<void> vai(String percorso, {Object? extra}) async {
      router().go(Routes.home);
      await tester.pumpAndSettle();
      router().push(percorso, extra: extra).ignore();
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    // ── Il paywall, dal modulo Wi-Fi ───────────────────────────────────────────
    //
    // ⚑ Il paywall NON va nelle schede (il prezzo cambia da paese a paese): serve ad Apple,
    // che per approvare il prodotto vuole lo screenshot della schermata in cui lo si compra.
    await tester.tap(find.byKey(const ValueKey('form_chip_wifi')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await scatto('paywall-revisione');
    await tester.tap(find.byType(MicroPrimaryButton).last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();

    // ── La home: preferiti e recenti, gia' col Pro (niente lucchetti) ──────────────
    router().go(Routes.home);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await scatto('home');

    // ── IL QR: il Wi-Fi di casa, stile Neon con il logo ─────────────────────────────
    await vai(Routes.qrOf(1));
    await scatto('qr', attesa: const Duration(seconds: 1));

    // ── Lo stile dello stesso QR: colori, forme, logo, «Leggibile» ──────────────────
    await tester.tap(find.byKey(const ValueKey('action_style')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    // La verifica di leggibilita' parte 600 ms dopo l'apertura e rilegge il PNG con ZXing.
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await scatto('stile', attesa: const Duration(seconds: 1));

    // ── Il modulo Wi-Fi, aperto in modifica: campi pieni e anteprima ─────────────────
    await vai(Routes.formOf(QrKind.wifi, id: 1));
    await scatto('modulo');

    // ── Il risultato di una lettura: un link, col dominio in evidenza ──────────────
    await vai(Routes.scanResult, extra: const ScanResultArgs(raw: linkLetto, source: QrSource.scanned));
    await scatto('lettura');
  });
}

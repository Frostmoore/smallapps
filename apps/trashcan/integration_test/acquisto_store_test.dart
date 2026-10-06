import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:trashcan/app/app_config.dart';
import 'package:trashcan/app/routes.dart';
import 'package:trashcan/l10n/generated/app_localizations.dart';
import 'package:trashcan/main.dart' as app;

/// Il paywall con lo **store vero**, non quello finto.
///
/// `flutter test integration_test/acquisto_store_test.dart -d DISPOSITIVO --dart-define=BILLING=store`
///
/// ☠ Esiste per il 2026-10-06: su iPhone il pulsante d'acquisto girava all'infinito e il
/// riquadro Pro delle impostazioni non rispondeva al tocco. Nessun test a tavolino poteva
/// vederlo, perche' il gateway finto risponde sempre col prodotto. Qui risponde lo store
/// del sistema: su un simulatore o un emulatore di solito **non** restituisce il prodotto,
/// ed e' proprio il caso che va provato.
///
/// Cosa dimostra: dal riquadro Pro delle impostazioni si apre il paywall, e entro il tempo
/// massimo la rotellina sparisce. O arriva il prezzo, o arriva un messaggio con "Riprova".
/// Mai l'attesa eterna.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('il paywall con lo store vero non gira all infinito', (tester) async {
    binding.platformDispatcher.localesTestValue = const <Locale>[Locale('it')];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);
    final l = lookupL(const Locale('it'));

    final config = buildTrashcanConfig();
    expect(
      config.billingMode,
      BillingMode.store,
      reason: 'va lanciato con --dart-define=BILLING=store, altrimenti prova il finto',
    );

    final settings = await SettingsStore.create(namespace: config.appId);
    await settings.clearNamespace();
    final documents = await getApplicationDocumentsDirectory();
    for (final suffix in const ['', '-wal', '-shm']) {
      final file = File(p.join(documents.path, 'trashcan.sqlite$suffix'));
      if (file.existsSync()) file.deleteSync();
    }
    final paths = await AppPaths.forApp(appId: config.appId);
    final acquisto = paths.file(paths.support, 'entitlement.json');
    if (acquisto.existsSync()) acquisto.deleteSync();

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Il minimo dell'onboarding: un tipo di rifiuto e fine.
    await tester.tap(find.text(l.onboarding_start));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.common_next));
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.waste_organic));
    await tester.pump();
    await tester.tap(find.text(l.common_next));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.onboarding_finish));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Il riquadro Pro delle impostazioni, quello che non rispondeva al tocco.
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(Routes.settings);
    await tester.pumpAndSettle();
    final riquadro = find.text(l.paywall_subhead);
    await tester.scrollUntilVisible(riquadro, 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(riquadro);
    await tester.pumpAndSettle();
    expect(find.text(l.paywall_restore), findsOneWidget, reason: 'il paywall non si e aperto');

    // Si aspetta fino al tempo massimo del catalogo, piu' un margine.
    final limite = DateTime.now().add(EntitlementService.catalogTimeout + const Duration(seconds: 10));
    // Tre esiti accettabili, e uno solo inaccettabile: la rotellina ancora accesa.
    bool c(String t) => find.textContaining(t).evaluate().isNotEmpty;
    String? esito() {
      if (c('Sblocca Pro —')) return 'prezzo arrivato';
      if (c(l.paywall_productUnavailable)) return 'messaggio con Riprova';
      if (c(l.paywall_unavailable)) return 'store assente su questo dispositivo';
      return null;
    }

    while (esito() == null && DateTime.now().isBefore(limite)) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    // ignore: avoid_print
    print('ESITO:${esito() ?? "ROTELLINA ANCORA ACCESA"}');
    expect(esito(), isNotNull, reason: 'la rotellina gira ancora dopo il tempo massimo');
    expect(find.byType(CircularProgressIndicator), findsNothing);
    if (esito() == 'messaggio con Riprova') expect(find.text(l.common_retry), findsOneWidget);
  });
}

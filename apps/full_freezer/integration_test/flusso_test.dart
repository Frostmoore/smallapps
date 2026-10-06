import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/app/app_config.dart';
import 'package:full_freezer/l10n/generated/app_localizations.dart';
import 'package:full_freezer/main.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Il flusso vero, sul dispositivo: primo freezer, inserimento rapido, home, freezer.
///
/// `flutter test integration_test/flusso_test.dart -d DISPOSITIVO`
///
/// Cosa dimostra:
/// 1. al primo avvio si sceglie il modello e si arriva alla home;
/// 2. **il vincolo di F4.5**: un alimento si salva in meno di 4 tocchi (il test li conta e
///    fallisce se sono di piu');
/// 3. l'alimento compare in home e il freezer si riempie.
///
/// Stampa `SCATTO:<nome>` nei punti in cui conviene fotografare lo schermo: lo scatto lo
/// fa uno script esterno con adb, come per TrashCan.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('primo freezer, inserimento rapido in meno di 4 tocchi, home', (tester) async {
    binding.platformDispatcher.localesTestValue = const <Locale>[Locale('it')];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);
    final l = lookupL(const Locale('it'));

    // Si parte da zero: preferenze e database cancellati.
    final config = buildFreezerConfig();
    final settings = await SettingsStore.create(namespace: config.appId);
    await settings.clearNamespace();
    final documents = await getApplicationDocumentsDirectory();
    for (final suffix in const ['', '-wal', '-shm']) {
      final file = File(p.join(documents.path, 'full_freezer.sqlite$suffix'));
      if (file.existsSync()) file.deleteSync();
    }

    Future<void> scatto(String nome) async {
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      // ignore: avoid_print
      print('SCATTO:$nome');
      await Future<void>.delayed(const Duration(seconds: 3));
    }

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 1. Primo avvio: il modello.
    expect(find.text(l.onboarding_title), findsOneWidget);
    await scatto('01-primo-freezer');
    await tester.tap(find.text(l.freezerModel_combi_compact));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(l.onboarding_start), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text(l.onboarding_start));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text(l.home_emptyTitle), findsOneWidget);
    await scatto('02-home-vuota');

    // 2. Inserimento rapido, contando i tocchi.
    var tocchi = 0;
    Future<void> tocca(Finder f) async {
      tocchi++;
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    await tocca(find.text(l.home_add));
    await tester.enterText(find.byType(TextField).first, 'Spezzatino di manzo');
    await tester.pumpAndSettle();
    await scatto('03-inserimento-rapido');
    await tocca(find.widgetWithText(FilledButton, l.common_save).last);
    expect(tocchi, lessThan(4), reason: 'F4.5: meno di 4 tocchi per salvare un alimento');
    // ignore: avoid_print
    print('TOCCHI:$tocchi');

    // Un secondo, con un'altra unita', per vedere le righe.
    await tester.tap(find.text(l.home_add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Piselli');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.unit_packs(2)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l.common_save).last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 3. La home con gli alimenti.
    expect(find.text('Spezzatino di manzo'), findsOneWidget);
    expect(find.text('Piselli'), findsOneWidget);
    await Future<void>.delayed(const Duration(seconds: 5)); // lo snackbar sparisce
    await scatto('04-home');

    // 4. La pagina del freezer.
    await tester.scrollUntilVisible(find.byIcon(Icons.chevron_right).last, 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byIcon(Icons.chevron_right).last);
    await tester.pumpAndSettle();
    expect(find.text(l.calibrate_button), findsOneWidget);
    await scatto('05-freezer');
  });
}

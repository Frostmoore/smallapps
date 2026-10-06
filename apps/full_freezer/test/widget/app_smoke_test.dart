import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/app/app.dart';
import 'package:full_freezer/app/app_config.dart';
import 'package:full_freezer/app/locale_resolution.dart';
import 'package:full_freezer/app/providers.dart';
import 'package:micro_core/micro_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F4.1: l'app parte, usa il blu dell'icona e parla la lingua giusta.
void main() {
  Future<void> avvia(WidgetTester tester, Locale locale) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final settings = await SettingsStore.create(namespace: 'full_freezer');
    tester.platformDispatcher.localesTestValue = <Locale>[locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(buildFreezerConfig()),
          settingsProvider.overrideWithValue(settings),
        ],
        child: const FullFreezerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('in italiano mostra la home vuota in italiano', (tester) async {
    await avvia(tester, const Locale('it', 'IT'));
    expect(find.text('Il freezer è vuoto'), findsOneWidget);
  });

  testWidgets('in tedesco ripiega sull inglese, non sull italiano', (tester) async {
    await avvia(tester, const Locale('de'));
    expect(find.text('Your freezer is empty'), findsOneWidget);
  });

  test('il tema nasce dal blu dell icona e dal font previsto', () {
    final config = buildFreezerConfig();
    expect(config.seedColor, const Color(0xFF0461E5));
    expect(config.fontFamily, 'PlusJakartaSans');
    expect(config.proSku, 'fullfreezer_pro_lifetime');
  });

  test('l inglese e il ripiego: e il primo delle lingue supportate', () {
    expect(kSupportedLocales.first, const Locale('en'));
    expect(resolveAppLocale(const [Locale('it', 'CH')], kSupportedLocales), const Locale('it'));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/app/app.dart';
import 'package:full_freezer/app/app_config.dart';
import 'package:full_freezer/app/locale_resolution.dart';
import 'package:full_freezer/app/providers.dart';
import 'package:full_freezer/data/database.dart';
import 'package:micro_core/micro_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L'app intera: primo avvio, lingue, home con dati.
///
/// ⚑ Il database non c'e': si sostituiscono i flussi che le pagine leggono. Un database
/// Drift vero dentro `testWidgets` resta appeso, perche' FakeAsync congela l'I/O di SQLite
/// (trappola gia' pagata in TrashCan, vedi apps/trashcan/test/widget/harness.dart). Che i
/// dati siano calcolati bene lo dimostrano i test del repository e di `buildHomeView`.
void main() {
  final oggi = CivilDate(2026, 10, 6);

  Freezer freezer() => const Freezer(
    id: 1,
    name: 'Freezer cucina',
    modelKey: 'combi_compact',
    capacityLiters: 70,
    calibration: 1,
    lastAlertLevel: 'empty',
    sortOrder: 0,
    createdAt: 0,
  );

  Item item(int id, String name, String frozenAt, {String? category}) => Item(
    id: id,
    freezerId: 1,
    name: name,
    nameNorm: name.toLowerCase(),
    category: category,
    quantity: 2,
    unit: 'portions',
    frozenAt: frozenAt,
    volumeLiters: 0.8,
    volumeManual: false,
    status: 'stored',
    createdAt: 0,
  );

  Future<void> avvia(
    WidgetTester tester,
    Locale locale, {
    bool onboarded = false,
    List<Item> items = const <Item>[],
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (onboarded) 'full_freezer.${SettingKeys.onboardingDone}': true,
    });
    final settings = await SettingsStore.create(namespace: 'full_freezer');
    tester.platformDispatcher.localesTestValue = <Locale>[locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(buildFreezerConfig()),
          settingsProvider.overrideWithValue(settings),
          todayProvider.overrideWithValue(oggi),
          freezersProvider.overrideWith((ref) => Stream.value([freezer()])),
          storedItemsProvider.overrideWith((ref) => Stream.value(items)),
          compartmentsByFreezerProvider.overrideWith((ref) => Stream.value(const <int, List<Compartment>>{})),
        ],
        child: const FullFreezerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('al primo avvio si sceglie il freezer, in italiano', (tester) async {
    await avvia(tester, const Locale('it', 'IT'));
    expect(find.text('Il tuo freezer'), findsOneWidget);
    expect(find.text('Frigo combinato 180 cm'), findsOneWidget);
    // Il nome proposto e' gia' scritto.
    expect(find.text('Freezer cucina'), findsOneWidget);
  });

  testWidgets('in tedesco ripiega sull inglese, non sull italiano', (tester) async {
    await avvia(tester, const Locale('de'));
    expect(find.text('Your freezer'), findsOneWidget);
  });

  testWidgets('la home: il piu vecchio in "Da usare prima", il resto sotto, e il riempimento', (tester) async {
    await avvia(
      tester,
      const Locale('it'),
      onboarded: true,
      items: [
        // Pesce: promemoria 120 giorni. 130 giorni fa -> old.
        item(1, 'Merluzzo', '2026-05-29', category: 'fish'),
        item(2, 'Piselli', '2026-09-30', category: 'vegetables'),
      ],
    );
    // MicroSectionHeader scrive i titoli in maiuscolo.
    expect(find.text('DA USARE PRIMA'), findsOneWidget);
    expect(find.text('Merluzzo'), findsOneWidget);
    expect(find.text('TUTTO IL RESTO'), findsOneWidget);
    expect(find.text('Piselli'), findsOneWidget);
    expect(find.text('1 da usare presto'), findsOneWidget);
    // 1,6 litri su 56 utili (70 x 80%) -> 3%.
    expect(find.text('Pieno al 3%'), findsWidgets);
    // L'ordine: Merluzzo sopra Piselli.
    expect(
      tester.getTopLeft(find.text('Merluzzo')).dy,
      lessThan(tester.getTopLeft(find.text('Piselli')).dy),
    );
  });

  testWidgets('la home vuota invita ad aggiungere', (tester) async {
    await avvia(tester, const Locale('it'), onboarded: true);
    expect(find.text('Il freezer è vuoto'), findsOneWidget);
    expect(find.text('Metti nel freezer'), findsOneWidget);
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/app/app.dart';
import 'package:full_freezer/app/app_config.dart';
import 'package:full_freezer/app/providers.dart';
import 'package:full_freezer/data/database.dart';
import 'package:full_freezer/data/freezer_repository.dart';
import 'package:micro_core/micro_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F4.13: il vincolo dell'app, **misurato**. Dall'apertura al prodotto salvato al massimo
/// 4 interazioni (develop_microapps.md F4.5): se un giorno qualcuno aggiunge un campo
/// obbligatorio o una conferma, questo test fallisce.
///
/// ⚑ Un test di widget e non di integrazione: quelli sull'emulatore restano appesi alla
/// connessione con la VM (provato il 2026-10-06). Il repository e' finto perche' Drift
/// dentro `testWidgets` si blocca (FakeAsync congela l'I/O di SQLite, lezione di TrashCan):
/// che `addItem` scriva bene lo dimostrano i test del repository.
class _RepoFinto extends FreezerRepository {
  _RepoFinto(super.db);

  final salvati = <NewItem>[];

  @override
  Future<int> addItem(NewItem item) async {
    salvati.add(item);
    return salvati.length;
  }

  @override
  Future<List<String>> suggestNames(String prefix, {int limit = 8}) async =>
      'lasagne della nonna'.startsWith(prefix.toLowerCase()) ? const ['Lasagne della nonna'] : const [];
}

void main() {
  late _RepoFinto repo;
  var interazioni = 0;

  Future<void> tocca(WidgetTester tester, Finder f) async {
    interazioni++;
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> scrivi(WidgetTester tester, String testo) async {
    // Scrivere il nome conta come UNA interazione, qualunque sia la sua lunghezza.
    interazioni++;
    await tester.enterText(find.byType(TextField).first, testo);
    await tester.pumpAndSettle();
  }

  Future<void> avvia(WidgetTester tester) async {
    interazioni = 0;
    SharedPreferences.setMockInitialValues(<String, Object>{'full_freezer.${SettingKeys.onboardingDone}': true});
    final settings = await SettingsStore.create(namespace: 'full_freezer');
    tester.platformDispatcher.localesTestValue = const <Locale>[Locale('it', 'IT')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final db = AppDatabase.memory();
    addTearDown(db.close);
    repo = _RepoFinto(db);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(buildFreezerConfig()),
          settingsProvider.overrideWithValue(settings),
          todayProvider.overrideWithValue(CivilDate(2026, 10, 7)),
          repositoryProvider.overrideWithValue(repo),
          freezersProvider.overrideWith(
            (ref) => Stream.value(const [
              Freezer(
                id: 1,
                name: 'Freezer cucina',
                modelKey: 'combi_compact',
                capacityLiters: 70,
                calibration: 1,
                lastAlertLevel: 'empty',
                sortOrder: 0,
                createdAt: 0,
              ),
            ]),
          ),
          storedItemsProvider.overrideWith((ref) => Stream.value(const <Item>[])),
          removedItemsProvider.overrideWith((ref) => Stream.value(const <Item>[])),
          customCategoriesProvider.overrideWith((ref) => Stream.value(const <CustomCategory>[])),
          compartmentsByFreezerProvider.overrideWith((ref) => Stream.value(const <int, List<Compartment>>{})),
          notificationSyncProvider.overrideWith((ref) {}),
        ],
        child: const FullFreezerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('percorso minimo: "+", nome, Salva = 3 interazioni', (tester) async {
    await avvia(tester);
    await tocca(tester, find.text('Metti nel freezer'));
    await scrivi(tester, 'Spezzatino');
    await tocca(tester, find.text('Salva'));

    expect(repo.salvati.single.name, 'Spezzatino');
    expect(repo.salvati.single.category, 'meat_red', reason: 'la categoria si deduce dal nome');
    expect(interazioni, lessThanOrEqualTo(4));
    expect(find.text('Spezzatino è nel freezer'), findsOneWidget);
  });

  testWidgets('con un suggerimento: "+", due lettere, suggerimento, Salva = 4 interazioni', (tester) async {
    await avvia(tester);
    await tocca(tester, find.text('Metti nel freezer'));
    await scrivi(tester, 'la');
    await tocca(tester, find.text('Lasagne della nonna'));
    await tocca(tester, find.text('Salva'));

    expect(repo.salvati.single.name, 'Lasagne della nonna');
    expect(interazioni, lessThanOrEqualTo(4));
  });
}

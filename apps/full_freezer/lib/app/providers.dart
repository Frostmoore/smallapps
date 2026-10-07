import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../data/freezer_repository.dart';
import '../domain/home_view.dart';

/// I provider radice dell'app.
///
/// ⚑ Perche' tutto passa da qui e niente e' globale: un singleton in una variabile di
/// modulo non si puo' sostituire nei test, e obbliga a inizializzare in `main` cose che
/// servono solo a una schermata. Con i provider l'inizializzazione e' pigra e ogni test
/// inietta il proprio doppio con un `override`. Stesso schema di apps/trashcan.

/// Sovrascritti in `main()`: senza, l'app non parte.
final appConfigProvider = Provider<MicroAppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider va sovrascritto in main()'),
);

final appPathsProvider = Provider<AppPaths>(
  (ref) => throw UnimplementedError('appPathsProvider va sovrascritto in main()'),
);

final settingsProvider = Provider<SettingsStore>(
  (ref) => throw UnimplementedError('settingsProvider va sovrascritto in main()'),
);

/// Il database, aperto alla prima lettura e chiuso con il `ProviderScope`.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<FreezerRepository>(
  (ref) => FreezerRepository(ref.watch(databaseProvider)),
);

/// Le preferenze proprie di Full Freezer. Stanno qui e non in `SettingKeys` di micro_core
/// perche' non riguardano le altre app.
abstract final class FreezerSettingKeys {
  /// Il freezer guardato in home; assente = "Tutti".
  static const String selectedFreezer = 'selected_freezer';

  /// Ultimo freezer, scomparto e unita' usati nell'inserimento rapido (F4.5: "posizione =
  /// ultima usata", "unita' = ultima usata"). Sono le scelte che si ripetono sempre uguali.
  static const String lastFreezer = 'last_freezer';
  static const String lastCompartment = 'last_compartment';
  static const String lastUnit = 'last_unit';
}

/// "Oggi", in un provider: i test lo fissano e le pagine non leggono mai l'orologio da sole.
///
/// ⚑ Si ricalcola quando l'app torna in primo piano (lo invalida `FullFreezerApp`): chi
/// lascia l'app aperta da ieri deve vedere i giorni di oggi.
final todayProvider = Provider<CivilDate>((ref) => CivilDate.today());

final freezersProvider = StreamProvider<List<Freezer>>(
  (ref) => ref.watch(repositoryProvider).watchFreezers(),
);

final storedItemsProvider = StreamProvider<List<Item>>(
  (ref) => ref.watch(repositoryProvider).watchStoredItems(),
);

/// Gli alimenti usciti, i piu' recenti per primi (storico e statistiche, F4.7).
final removedItemsProvider = StreamProvider<List<Item>>(
  (ref) => ref.watch(repositoryProvider).watchRemovedItems(),
);

/// Gli scomparti di tutti i freezer, raggruppati per freezer.
final compartmentsByFreezerProvider = StreamProvider<Map<int, List<Compartment>>>(
  (ref) => ref.watch(repositoryProvider).watchAllCompartments().map((all) {
    final map = <int, List<Compartment>>{};
    for (final c in all) {
      (map[c.freezerId] ??= <Compartment>[]).add(c);
    }
    return map;
  }),
);

/// `true` dopo che il primo freezer e' stato creato.
///
/// ⚑ Una preferenza e non "esiste almeno un freezer": il redirect del router deve
/// rispondere subito, mentre lo stream del database arriva dopo il primo frame. Con la
/// query, l'app aprirebbe l'onboarding per un istante anche a chi l'ha gia' fatto.
final onboardingDoneProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).getBool(SettingKeys.onboardingDone, orElse: false),
);

/// Il freezer guardato in home, o null per "Tutti". Persistito.
class SelectedFreezer extends Notifier<int?> {
  @override
  int? build() {
    final saved = ref.watch(settingsProvider).getInt(FreezerSettingKeys.selectedFreezer, orElse: -1);
    return saved < 0 ? null : saved;
  }

  Future<void> select(int? freezerId) async {
    state = freezerId;
    final settings = ref.read(settingsProvider);
    if (freezerId == null) {
      await settings.remove(FreezerSettingKeys.selectedFreezer);
    } else {
      await settings.setInt(FreezerSettingKeys.selectedFreezer, freezerId);
    }
  }
}

final selectedFreezerProvider = NotifierProvider<SelectedFreezer, int?>(SelectedFreezer.new);

/// La home pronta da disegnare. Null finche' i dati non sono arrivati.
final homeViewProvider = Provider<HomeView?>((ref) {
  final freezers = ref.watch(freezersProvider).value;
  final items = ref.watch(storedItemsProvider).value;
  if (freezers == null || items == null) return null;
  var selected = ref.watch(selectedFreezerProvider);
  // Un freezer selezionato e poi cancellato: si torna a "Tutti" invece di una home vuota.
  if (selected != null && !freezers.any((f) => f.id == selected)) selected = null;
  // Con un freezer solo, "Tutti" e quel freezer sono la stessa cosa: si mostra il freezer,
  // cosi' la testata ha la sua barra di riempimento.
  if (selected == null && freezers.length == 1) selected = freezers.single.id;
  return buildHomeView(
    freezers: freezers,
    storedItems: items,
    selectedFreezerId: selected,
    today: ref.watch(todayProvider),
  );
});

/// Il tema scelto dall'utente, persistito.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.watch(settingsProvider).getString(SettingKeys.themeMode);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsProvider).setString(SettingKeys.themeMode, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

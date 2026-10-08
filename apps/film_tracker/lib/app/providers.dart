import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../data/film_repository.dart';
import '../domain/film_stats.dart';
import '../domain/roll_status.dart';

/// I provider radice dell'app.
///
/// ⚑ Perche' tutto passa da qui e niente e' globale: un singleton in una variabile di
/// modulo non si puo' sostituire nei test, e obbliga a inizializzare in `main` cose che
/// servono solo a una schermata. Con i provider l'inizializzazione e' pigra e ogni test
/// inietta il proprio doppio con un `override`. Stesso schema di Scorte Calore, Full Freezer e TrashCan.

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

/// "Oggi", in un provider: i test lo fissano e le pagine non leggono mai l'orologio da sole.
/// Si ricalcola quando l'app torna in primo piano (lo invalida `FilmTrackerApp`).
final todayProvider = Provider<CivilDate>((ref) => CivilDate.today());

/// Il tema scelto dall'utente, persistito.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.watch(settingsProvider).getString(SettingKeys.themeMode);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      // ⚑ Scuro di default (F6.1): le foto su fondo chiaro perdono contrasto.
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsProvider).setString(SettingKeys.themeMode, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Il database, aperto alla prima lettura e chiuso con il `ProviderScope`.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<FilmRepository>(
  (ref) => FilmRepository(ref.watch(databaseProvider)),
);

// ── Stream per la UI ─────────────────────────────────────────────────────────

/// Tutte le macchine (attive e dismesse), nell'ordine dell'utente: l'inventario (F6.5).
final camerasProvider = StreamProvider<List<Camera>>(
  (ref) => ref.watch(repositoryProvider).watchCameras(),
);

/// Solo le macchine attive: la scelta nel form del rullino.
final activeCamerasProvider = StreamProvider<List<Camera>>(
  (ref) => ref.watch(repositoryProvider).watchCameras(activeOnly: true),
);

/// Quante macchine esistono: il conteggio per `FeatureKey.secondaryEntities`.
final cameraCountProvider = StreamProvider<int>(
  (ref) => ref.watch(repositoryProvider).watchCameraCount(),
);

/// `cameraId -> rullini scattati` (le macchine senza rullini non ci sono: `?? 0`).
final rollCountByCameraProvider = StreamProvider<Map<int, int>>(
  (ref) => ref.watch(repositoryProvider).watchRollCountByCamera(),
);

/// Il catalogo delle pellicole, per marca e nome.
final filmStocksProvider = StreamProvider<List<FilmStock>>(
  (ref) => ref.watch(repositoryProvider).watchStocks(),
);

/// Le cinque pellicole piu' usate: la selezione rapida del form del rullino (F6.4).
final mostUsedStocksProvider = StreamProvider<List<FilmStock>>(
  (ref) => ref.watch(repositoryProvider).watchMostUsedStocks(),
);

/// Le card di una sezione della home (F6.8), dal numero piu' alto.
final rollItemsProvider = StreamProvider.family<List<RollListItem>, RollSection>(
  (ref, section) => ref.watch(repositoryProvider).watchRollItems(section: section),
);

/// Tutti i rullini con i loro eventi (lista completa, ricerca).
final allRollItemsProvider = StreamProvider<List<RollListItem>>(
  (ref) => ref.watch(repositoryProvider).watchRollItems(),
);

/// Un rullino per id (dettaglio); null se cancellato.
final rollProvider = StreamProvider.family<FilmRoll?, int>(
  (ref, id) => ref.watch(repositoryProvider).watchRoll(id),
);

/// Lo sviluppo di un rullino, per id del rullino.
final developmentProvider = StreamProvider.family<Development?, int>(
  (ref, rollId) => ref.watch(repositoryProvider).watchDevelopment(rollId),
);

/// Le stampe di un rullino, per id del rullino.
final printsProvider = StreamProvider.family<List<PrintOrder>, int>(
  (ref, rollId) => ref.watch(repositoryProvider).watchPrints(rollId),
);

/// Le immagini di un rullino, per id del rullino.
final rollImagesProvider = StreamProvider.family<List<RollImage>, int>(
  (ref, rollId) => ref.watch(repositoryProvider).watchImages(rollId),
);

/// I laboratori gia' usati, dal piu' frequente: l'autocompletamento (F6.7).
final laboratoriesProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(repositoryProvider).watchLaboratories(),
);

/// Gli ingressi delle statistiche (F6.10).
final statsRollsProvider = StreamProvider<List<StatsRoll>>(
  (ref) => ref.watch(repositoryProvider).watchStatsRolls(),
);

/// Gli anni con almeno un rullino, dal piu' recente.
final statsYearsProvider = Provider<List<int>>((ref) {
  final rolls = ref.watch(statsRollsProvider).value ?? const <StatsRoll>[];
  return const FilmStatsCalculator().years(rolls);
});

/// Le statistiche di un anno; null finche' i dati non sono arrivati.
final yearStatsProvider = Provider.family<YearStats?, int>((ref, year) {
  final rolls = ref.watch(statsRollsProvider).value;
  if (rolls == null) return null;
  return const FilmStatsCalculator().forYear(year, rolls);
});

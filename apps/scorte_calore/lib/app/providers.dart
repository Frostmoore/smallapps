import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../data/scorte_repository.dart';
import '../domain/consumption.dart';

/// I provider radice dell'app.
///
/// ⚑ Perche' tutto passa da qui e niente e' globale: un singleton in una variabile di
/// modulo non si puo' sostituire nei test, e obbliga a inizializzare in `main` cose che
/// servono solo a una schermata. Con i provider l'inizializzazione e' pigra e ogni test
/// inietta il proprio doppio con un `override`. Stesso schema di Full Freezer e TrashCan.

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
/// Si ricalcola quando l'app torna in primo piano (lo invalida `ScorteCaloreApp`).
final todayProvider = Provider<CivilDate>((ref) => CivilDate.today());

/// `true` dopo che la prima fonte e' stata configurata.
///
/// ⚑ Una preferenza e non "esiste almeno una fonte": il redirect del router deve rispondere
/// subito, mentre il database arriva dopo il primo frame (lezione di Full Freezer).
final onboardingDoneProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).getBool(SettingKeys.onboardingDone, orElse: false),
);

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

/// Il database, aperto alla prima lettura e chiuso con il `ProviderScope`.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<ScorteRepository>((ref) => ScorteRepository(ref.watch(databaseProvider)));

/// Le fonti attive, nell'ordine scelto dall'utente.
final sourcesProvider = StreamProvider<List<FuelSource>>(
  (ref) => ref.watch(repositoryProvider).watchSources(activeOnly: true),
);

/// Le misurazioni di una fonte, in ordine di data.
final measurementsProvider = StreamProvider.family<List<StockMeasurement>, int>(
  (ref, sourceId) => ref.watch(repositoryProvider).watchMeasurements(sourceId),
);

/// La stima di una fonte, ricalcolata a ogni misurazione e a ogni cambio di giorno.
///
/// ⚑ Usa **tutte** le misurazioni anche nel piano gratuito: il limite dei 90 giorni (F5.9)
/// riguarda cosa si vede nello storico, non la stima, che comunque usa solo gli ultimi 5
/// intervalli.
final estimateProvider = Provider.family<ConsumptionEstimate?, int>((ref, sourceId) {
  final sources = ref.watch(sourcesProvider).value;
  final rows = ref.watch(measurementsProvider(sourceId)).value;
  final source = sources?.where((s) => s.id == sourceId).firstOrNull;
  if (source == null || rows == null) return null;
  return const ConsumptionCalculator().estimate(
    measurements: rows.toMeasurements(),
    source: source.toSpec(),
    today: ref.watch(todayProvider),
  );
});

/// La fonte mostrata nella testata della home ("A · Brace"), persistita.
///
/// ⚑ Una preferenza e non sempre "la prima": chi ha stufa e bombolone guarda di solito una
/// delle due, e la riga toccata deve restare in testata anche dopo aver chiuso l'app.
class SelectedSource extends Notifier<int?> {
  static const String key = 'selected_source';

  @override
  int? build() {
    final saved = ref.watch(settingsProvider).getInt(key, orElse: -1);
    return saved < 0 ? null : saved;
  }

  Future<void> select(int sourceId) async {
    state = sourceId;
    await ref.read(settingsProvider).setInt(key, sourceId);
  }
}

final selectedSourceProvider = NotifierProvider<SelectedSource, int?>(SelectedSource.new);

/// La fonte in testata: quella scelta se esiste ancora, altrimenti la prima.
final heroSourceProvider = Provider<FuelSource?>((ref) {
  final sources = ref.watch(sourcesProvider).value ?? const <FuelSource>[];
  if (sources.isEmpty) return null;
  final chosen = ref.watch(selectedSourceProvider);
  return sources.where((s) => s.id == chosen).firstOrNull ?? sources.first;
});

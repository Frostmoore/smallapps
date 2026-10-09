import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../data/qr_repository.dart';

/// I provider radice dell'app (§8.T).
///
/// ⚑ Perche' tutto passa da qui e niente e' globale: un singleton in una variabile di modulo
/// non si puo' sostituire nei test, e obbliga a inizializzare in `main` cose che servono solo
/// a una schermata. Con i provider l'inizializzazione e' pigra e ogni test inietta il proprio
/// doppio con un `override`. Stesso schema di Film Tracker.

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

/// Le chiavi delle preferenze proprie di QR Me (quelle comuni sono in `SettingKeys`).
abstract final class QrSettingKeys {
  /// Cronologia accesa (default) o spenta (F17.0 punto 7).
  static const String historyEnabled = 'history_enabled';
}

/// Il tema scelto dall'utente, persistito.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.watch(settingsProvider).getString(SettingKeys.themeMode);
    return switch (saved) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      // ⚑ Chiaro di default (F17.2c): un QR e' nero su bianco, e l'app che lo mostra nasce
      // chiara. La pagina del QR resta leggibile anche in scuro (riquadro col suo sfondo).
      _ => ThemeMode.light,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsProvider).setString(SettingKeys.themeMode, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// La cronologia accesa o spenta (F17.0 punto 7), persistita.
///
/// ⚑ Spenta, le pagine non chiamano `QrRepository.recordShown`: il QR si mostra da
/// `QrDisplayArgs` in memoria. Il repository non lo sa e non deve saperlo.
class HistoryEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsProvider).getBool(QrSettingKeys.historyEnabled, orElse: true);

  Future<void> set(bool enabled) async {
    state = enabled;
    await ref.read(settingsProvider).setBool(QrSettingKeys.historyEnabled, enabled);
  }
}

final historyEnabledProvider = NotifierProvider<HistoryEnabledNotifier, bool>(HistoryEnabledNotifier.new);

/// Il database, aperto alla prima lettura e chiuso con il `ProviderScope`.
final databaseProvider = Provider<QrDatabase>((ref) {
  final db = QrDatabase.open();
  ref.onDispose(db.close);
  return db;
});

/// Le immagini dell'app: i loghi foto (bucket `QrLogoFiles.bucket`).
final imageStoreProvider = Provider<ImageStore>((ref) => ImageStore(paths: ref.watch(appPathsProvider)));

final repositoryProvider = Provider<QrRepository>(
  (ref) => QrRepository(ref.watch(databaseProvider), images: ref.watch(imageStoreProvider)),
);

// ── Stream per la UI ─────────────────────────────────────────────────────────

/// La cronologia, dal piu' recente.
final historyProvider = StreamProvider<List<QrCode>>((ref) => ref.watch(repositoryProvider).watchHistory());

/// I preferiti, per titolo.
final favoritesProvider = StreamProvider<List<QrCode>>((ref) => ref.watch(repositoryProvider).watchFavorites());

/// Quanti preferiti: il conteggio per `FeatureKey.unlimitedEntities`.
final favoriteCountProvider = StreamProvider<int>((ref) => ref.watch(repositoryProvider).watchFavoriteCount());

/// Una riga per id (la pagina del QR salvato); null se cancellata.
final qrCodeProvider = StreamProvider.family<QrCode?, int>(
  (ref, id) => ref.watch(repositoryProvider).watchById(id),
);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';


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

// Database e repository arrivano con il data layer (F6.2).

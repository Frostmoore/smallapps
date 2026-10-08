import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'app/locale_resolution.dart';
import 'app/providers.dart';
import 'data/database.dart';
import 'dev/demo_data.dart';

/// L'avvio di Film Tracker: il minimo indispensabile (configurazione, cartelle, preferenze).
///
/// ⚑ Database, notifiche e store li inizializzano i provider, pigramente: farlo prima del
/// primo frame produce una schermata bianca all'avvio (stesso schema di Scorte Calore).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = buildFilmConfig();
  // Fa fallire subito una release compilata con il billing finto, che sbloccherebbe il Pro a
  // chiunque tocchi il pulsante.
  config.assertUsableInRelease();

  final paths = await AppPaths.forApp(appId: config.appId);
  await paths.ensureAll();
  MicroLog.init(file: paths.file(paths.logs, 'film_tracker.log'));

  FlutterError.onError = (details) {
    MicroLog.e('flutter', error: details.exception, stackTrace: details.stack);
    FlutterError.presentError(details);
  };

  final settings = await SettingsStore.create(namespace: config.appId);
  await _recordLaunch(settings);

  // Solo in sviluppo, con --dart-define=FT_DEMO=true: riempie un database senza rullini con
  // dati di esempio, prima di runApp (stesso schema di Scorte Calore).
  if (demoEnabled) {
    final db = AppDatabase.open();
    final lingua = resolveAppLocale(
      WidgetsBinding.instance.platformDispatcher.locales,
      kSupportedLocales,
    );
    await seedDemoData(db, english: lingua.languageCode != 'it');
    await db.close();
  }

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appPathsProvider.overrideWithValue(paths),
        settingsProvider.overrideWithValue(settings),
      ],
      child: const FilmTrackerApp(),
    ),
  );
}

/// Conta gli avvii e registra il primo: servono a decidere quando chiedere una recensione.
Future<void> _recordLaunch(SettingsStore settings) async {
  final count = settings.getInt(SettingKeys.launchCount, orElse: 0);
  await settings.setInt(SettingKeys.launchCount, count + 1);
  if (settings.getInstant(SettingKeys.firstLaunchAt) == null) {
    await settings.setInstant(SettingKeys.firstLaunchAt, DateTime.now().toUtc());
  }
}

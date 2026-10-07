import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'app/locale_resolution.dart';
import 'app/providers.dart';
import 'data/database.dart';
import 'dev/demo_data.dart';

/// L'avvio di Full Freezer.
///
/// Qui dentro si fa il minimo indispensabile: leggere la configurazione, risolvere le
/// cartelle, aprire le preferenze.
///
/// ⚑ Il database, le notifiche e lo store li inizializzano i provider, pigramente: farlo
/// prima del primo frame produce una schermata bianca all'avvio, il difetto piu' notato
/// dagli utenti e il piu' penalizzato dalle Android Vitals. Stesso schema di TrashCan.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = buildFreezerConfig();
  // Fa fallire subito una release compilata con il billing finto, che sbloccherebbe il
  // Pro a chiunque tocchi il pulsante.
  config.assertUsableInRelease();

  final paths = await AppPaths.forApp(appId: config.appId);
  await paths.ensureAll();
  MicroLog.init(file: paths.file(paths.logs, 'full_freezer.log'));

  // Gli errori di Flutter finiscono nel log dell'app: in release `print` non arriva da
  // nessuna parte, e senza questo un crash di rendering sarebbe invisibile.
  FlutterError.onError = (details) {
    MicroLog.e('flutter', error: details.exception, stackTrace: details.stack);
    FlutterError.presentError(details);
  };

  final settings = await SettingsStore.create(namespace: config.appId);
  await _recordLaunch(settings);

  // Solo in sviluppo, con --dart-define=FF_DEMO=true: riempie un database vuoto con dati di
  // esempio. Va fatto PRIMA di runApp, perche' il router decide subito se mostrare il primo
  // avvio; usa una connessione sua, chiusa prima che l'app apra la propria.
  if (demoEnabled) {
    final db = AppDatabase.open();
    final lingua = resolveAppLocale(WidgetsBinding.instance.platformDispatcher.locales, kSupportedLocales);
    await seedDemoData(db, settings, english: lingua.languageCode != 'it');
    await db.close();
  }

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appPathsProvider.overrideWithValue(paths),
        settingsProvider.overrideWithValue(settings),
      ],
      child: const FullFreezerApp(),
    ),
  );
}

/// Conta gli avvii e registra il primo: servono a decidere quando chiedere una
/// recensione, e non si possono ricostruire a posteriori.
Future<void> _recordLaunch(SettingsStore settings) async {
  final count = settings.getInt(SettingKeys.launchCount, orElse: 0);
  await settings.setInt(SettingKeys.launchCount, count + 1);
  if (settings.getInstant(SettingKeys.firstLaunchAt) == null) {
    await settings.setInstant(SettingKeys.firstLaunchAt, DateTime.now().toUtc());
  }
}

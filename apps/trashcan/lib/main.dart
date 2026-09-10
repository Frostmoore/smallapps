import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'app/providers.dart';

/// L'avvio di TrashCan.
///
/// Qui dentro si fa il minimo indispensabile e nient'altro: leggere la configurazione,
/// risolvere le cartelle, aprire le preferenze.
///
/// ⚑ Perché non si apre il database e non si inizializzano le notifiche qui: sono
/// operazioni che richiedono decine di millisecondi ciascuna, e farle prima del primo
/// frame produce una schermata bianca all'avvio. È il difetto più notato dagli utenti e
/// il più penalizzato dalle Android Vitals. Tutto il resto lo inizializzano i provider,
/// pigramente, quando serve davvero.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = buildTrashcanConfig();
  // Fa fallire subito una release compilata con il billing finto, che sbloccherebbe il
  // Pro a chiunque tocchi il pulsante.
  config.assertUsableInRelease();

  final paths = await AppPaths.forApp(appId: config.appId);
  await paths.ensureAll();
  MicroLog.init(file: paths.file(paths.logs, 'trashcan.log'));

  // Gli errori di Flutter finiscono nel log dell'app: in release `print` non arriva da
  // nessuna parte, e senza questo un crash di rendering sarebbe invisibile.
  FlutterError.onError = (details) {
    MicroLog.e('flutter', error: details.exception, stackTrace: details.stack);
    FlutterError.presentError(details);
  };

  final settings = await SettingsStore.create(namespace: config.appId);
  await _recordLaunch(settings);

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appPathsProvider.overrideWithValue(paths),
        settingsProvider.overrideWithValue(settings),
      ],
      child: const TrashcanApp(),
    ),
  );
}

/// Conta gli avvii e registra il primo.
///
/// Serve a decidere quando ha senso chiedere una recensione: mai al primo avvio, mai
/// prima di una settimana. Sono due numeri che vanno raccolti dal principio, perché non
/// si possono ricostruire a posteriori.
Future<void> _recordLaunch(SettingsStore settings) async {
  final count = settings.getInt(SettingKeys.launchCount, orElse: 0);
  await settings.setInt(SettingKeys.launchCount, count + 1);
  if (settings.getInstant(SettingKeys.firstLaunchAt) == null) {
    await settings.setInstant(SettingKeys.firstLaunchAt, DateTime.now().toUtc());
  }
}

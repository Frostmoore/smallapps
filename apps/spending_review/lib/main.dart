import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'app/licenze.dart';
import 'app/providers.dart';
import 'app/routes.dart';

/// L'avvio di Spending Review: il minimo indispensabile (configurazione, cartelle, preferenze).
///
/// ⚑ Database e motore OCR li inizializzano i provider, pigramente: farlo prima del primo frame
/// produce una schermata bianca all'avvio (§8.T). Qui conta doppio: chi apre l'app e' alla cassa o
/// fra gli scaffali, e il tastierino deve esserci subito (obiettivo ≤ 1,5 s, F12.1.18).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = buildSrConfig();
  // Fa fallire subito una release compilata con il billing finto, che sbloccherebbe il Pro a
  // chiunque tocchi il pulsante.
  config.assertUsableInRelease();
  // ☠ La pagina di sviluppo dell'OCR (`/dev/ocr`, F12.1.12) esporta le righe lette: in una release
  // pubblicata non deve esistere. Una release compilata con SR_DEV acceso si ferma qui.
  if (kReleaseMode && kSrDev) throw StateError('SR_DEV=true in una build di release');

  final paths = await AppPaths.forApp(appId: config.appId);
  await paths.ensureAll();
  MicroLog.init(file: paths.file(paths.logs, 'spending_review.log'));

  FlutterError.onError = (details) {
    MicroLog.e('flutter', error: details.exception, stackTrace: details.stack);
    FlutterError.presentError(details);
  };

  // Le licenze del motore OCR e dei font (lette pigramente, solo se si apre la pagina).
  registraLicenze();

  final settings = await SettingsStore.create(namespace: config.appId);
  await _recordLaunch(settings);

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appPathsProvider.overrideWithValue(paths),
        settingsProvider.overrideWithValue(settings),
      ],
      child: const SpendingReviewApp(),
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

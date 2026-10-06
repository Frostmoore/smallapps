import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../features/home/home_page.dart';
import '../l10n/generated/app_localizations.dart';
import 'locale_resolution.dart';
import 'providers.dart';
import 'routes.dart';

/// Il router dell'app.
///
/// ⚑ Perche' `go_router` e non `Navigator` imperativo (ADR-005): le notifiche e il widget
/// aprono l'app con un deep link, e con una catena di `push` il deep link si rompe quando
/// l'app viene aperta da fredda, cioe' proprio nel caso che conta.
///
/// Il redirect verso l'onboarding arriva con F4.6, quando esiste la creazione del primo
/// freezer: senza un freezer l'app non ha niente da mostrare.
GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (_, __) => const HomePage()),
  ],
);

class FullFreezerApp extends ConsumerStatefulWidget {
  const FullFreezerApp({super.key});

  @override
  ConsumerState<FullFreezerApp> createState() => _FullFreezerAppState();
}

class _FullFreezerAppState extends ConsumerState<FullFreezerApp> {
  // Il router si costruisce una volta sola: ricrearlo a ogni build azzererebbe la
  // cronologia di navigazione a ogni cambio di stato.
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: MicroTheme.light(seed: config.seedColor, fontFamily: config.fontFamily),
      darkTheme: MicroTheme.dark(seed: config.seedColor, fontFamily: config.fontFamily),
      themeMode: ref.watch(themeModeProvider),
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeListResolutionCallback: resolveAppLocale,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../features/exceptions/exceptions_page.dart';
import '../features/home/home_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/settings/settings_page.dart';
import '../features/waste_types/waste_type_editor_page.dart';
import '../features/waste_types/waste_types_page.dart';
import '../l10n/generated/app_localizations.dart';
import 'locale_resolution.dart';
import 'providers.dart';
import 'routes.dart';

/// Il router dell'app.
///
/// ⚑ Perché `go_router` e non `Navigator` imperativo (ADR-005): le notifiche e il widget
/// Android aprono l'app con un deep link, e con una catena di `push` il deep link si
/// rompe quando l'app viene aperta da fredda, cioè proprio nel caso che conta.
GoRouter buildRouter(WidgetRef ref) => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (_, __) => const HomePage()),
    GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingPage()),
    GoRoute(path: Routes.wasteTypes, builder: (_, __) => const WasteTypesPage()),
    GoRoute(path: Routes.wasteTypeNew, builder: (_, __) => const WasteTypeEditorPage()),
    GoRoute(
      path: Routes.wasteTypeEdit,
      builder: (_, state) => WasteTypeEditorPage(
        wasteTypeId: int.tryParse(state.pathParameters['wasteTypeId'] ?? ''),
      ),
    ),
    GoRoute(path: Routes.exceptions, builder: (_, __) => const ExceptionsPage()),
    GoRoute(path: Routes.settings, builder: (_, __) => const SettingsPage()),
  ],
  // Chi non ha ancora fatto il wizard viene portato lì, da qualunque punto entri:
  // anche da un deep link, che altrimenti mostrerebbe una home vuota e incomprensibile.
  redirect: (context, state) {
    final done = ref.read(onboardingDoneProvider);
    final goingToOnboarding = state.matchedLocation == Routes.onboarding;
    if (!done && !goingToOnboarding) return Routes.onboarding;
    if (done && goingToOnboarding) return Routes.home;
    return null;
  },
);

class TrashcanApp extends ConsumerStatefulWidget {
  const TrashcanApp({super.key});

  @override
  ConsumerState<TrashcanApp> createState() => _TrashcanAppState();
}

class _TrashcanAppState extends ConsumerState<TrashcanApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    // Il router si costruisce una volta sola: ricrearlo a ogni build azzererebbe la
    // cronologia di navigazione a ogni cambio di stato.
    _router ??= buildRouter(ref);

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

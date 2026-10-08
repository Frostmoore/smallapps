import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../features/home/home_page.dart';
import '../features/settings/settings_page.dart';
import '../l10n/generated/app_localizations.dart';
import 'locale_resolution.dart';
import 'providers.dart';
import 'routes.dart';

/// Il router dell'app.
///
/// ⚑ `go_router` e non `Navigator` imperativo (ADR-005): il QR del rullino (F6.12) apre una
/// pagina con un percorso, e senza un router dichiarativo ogni ingresso andrebbe scritto a mano.
GoRouter buildRouter(WidgetRef ref) => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (_, __) => const HomePage()),
    GoRoute(path: Routes.settings, builder: (_, __) => const SettingsPage()),
  ],
);

/// L'app.
class FilmTrackerApp extends ConsumerStatefulWidget {
  const FilmTrackerApp({super.key});

  @override
  ConsumerState<FilmTrackerApp> createState() => _FilmTrackerAppState();
}

class _FilmTrackerAppState extends ConsumerState<FilmTrackerApp> {
  late final GoRouter _router = buildRouter(ref);
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    // "Oggi" si ricalcola tornando in primo piano: i giorni in macchina e in laboratorio
    // si contano in giorni.
    _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(todayProvider));
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      // `fidelity`: l'ambra resta quella del piano invece del bruno che Material ricaverebbe
      // dal seme (stessa scelta delle altre app). La palette definitiva arriva con le
      // proposte grafiche (F6.0 punto 6).
      theme: MicroTheme.light(seed: config.seedColor, fontFamily: config.fontFamily, variant: DynamicSchemeVariant.fidelity),
      darkTheme: MicroTheme.dark(seed: config.seedColor, fontFamily: config.fontFamily, variant: DynamicSchemeVariant.fidelity),
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

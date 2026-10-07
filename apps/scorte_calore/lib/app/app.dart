import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../l10n/generated/app_localizations.dart';
import 'locale_resolution.dart';
import 'providers.dart';
import 'routes.dart';

/// Il router dell'app.
///
/// ⚑ `go_router` e non `Navigator` imperativo (ADR-005): notifiche e widget aprono pagine
/// con un percorso, e senza un router dichiarativo ogni ingresso andrebbe scritto a mano.
GoRouter buildRouter(WidgetRef ref) => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (_, __) => const _Provvisoria()),
    GoRoute(path: Routes.welcome, builder: (_, __) => const _Provvisoria()),
  ],
  // Senza una fonte configurata non c'e' niente da mostrare: si parte dal primo avvio.
  redirect: (_, state) {
    final done = ref.read(onboardingDoneProvider);
    if (!done && state.matchedLocation != Routes.welcome) return Routes.welcome;
    return null;
  },
);

/// L'app.
class ScorteCaloreApp extends ConsumerStatefulWidget {
  const ScorteCaloreApp({super.key});

  @override
  ConsumerState<ScorteCaloreApp> createState() => _ScorteCaloreAppState();
}

class _ScorteCaloreAppState extends ConsumerState<ScorteCaloreApp> {
  late final GoRouter _router = buildRouter(ref);
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    // "Oggi" si ricalcola tornando in primo piano: l'autonomia si conta in giorni.
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
      // `fidelity`: l'arancio resta quello acceso della fiamma invece del bruno che Material
      // ricaverebbe dal seme (stessa scelta di Full Freezer col suo blu).
      theme: MicroTheme.light(
        seed: config.seedColor,
        fontFamily: config.fontFamily,
        variant: DynamicSchemeVariant.fidelity,
      ),
      darkTheme: MicroTheme.dark(
        seed: config.seedColor,
        fontFamily: config.fontFamily,
        variant: DynamicSchemeVariant.fidelity,
      ),
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

/// La pagina provvisoria del bootstrap (F5.1): la sostituiscono il primo avvio (F5.5) e la
/// dashboard (F5.6).
class _Provvisoria extends StatelessWidget {
  const _Provvisoria();

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(L.of(context).appTitle)));
}

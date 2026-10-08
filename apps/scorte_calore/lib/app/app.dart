import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../features/common/pro_gate.dart';
import '../features/history/history_page.dart';
import '../features/home/home_page.dart';
import '../features/purchases/purchases_page.dart';
import '../features/settings/settings_page.dart';
import '../features/sources/source_editor_page.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/notification_providers.dart';
import '../services/widget_sync.dart';
import 'locale_resolution.dart';
import 'providers.dart';
import 'routes.dart';
import 'scorte_palette.dart';

/// Il router dell'app.
///
/// ⚑ `go_router` e non `Navigator` imperativo (ADR-005): notifiche e widget aprono pagine
/// con un percorso, e senza un router dichiarativo ogni ingresso andrebbe scritto a mano.
GoRouter buildRouter(WidgetRef ref) => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (_, __) => const HomePage()),
    GoRoute(path: Routes.welcome, builder: (_, __) => const SourceEditorPage(firstRun: true)),
    GoRoute(path: Routes.settings, builder: (_, __) => const SettingsPage()),
    // ⚑ `new` prima di `:sourceId`: go_router prova le rotte in ordine.
    GoRoute(
      path: Routes.sourceNew,
      builder: (_, __) => ProGate(
        feature: FeatureKey.unlimitedEntities,
        allowed: (gate) => gate.withinLimit(FeatureKey.unlimitedEntities, ref.read(sourcesProvider).value?.length ?? 0),
        child: const SourceEditorPage(),
      ),
    ),
    GoRoute(
      path: Routes.sourceEdit,
      builder: (_, s) => SourceEditorPage(sourceId: int.tryParse(s.pathParameters['sourceId'] ?? '')),
    ),
    GoRoute(
      path: Routes.history,
      builder: (_, s) => HistoryPage(sourceId: int.tryParse(s.pathParameters['sourceId'] ?? '') ?? -1),
    ),
    // ☠ Protetta sulla pagina (ProGate), non solo da `openPurchases`: un deep link non passa
    // dalla porta col paywall.
    GoRoute(
      path: Routes.purchases,
      builder: (_, s) => ProGate(
        feature: FeatureKey.statistics,
        child: PurchasesPage(sourceId: int.tryParse(s.pathParameters['sourceId'] ?? '') ?? -1),
      ),
    ),
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
  StreamSubscription<String>? _taps;

  @override
  void initState() {
    super.initState();
    // "Oggi" si ricalcola tornando in primo piano: l'autonomia si conta in giorni.
    // Tornando in primo piano si ripianificano anche le notifiche: le date di riordino
    // dipendono da "oggi".
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.invalidate(todayProvider);
        unawaited(ref.read(scorteSchedulerProvider).rescheduleAll());
      },
    );
    // Il tocco su una notifica (ad app aperta o che la fa partire) apre il suo percorso.
    ref.listenManual(notificationServiceProvider, (_, next) {
      final service = next.value;
      if (service == null || _taps != null) return;
      _taps = service.taps.listen(_openPayload);
      final launch = service.consumeLaunchPayload();
      if (launch != null) _openPayload(launch);
    }, fireImmediately: true);
  }

  /// ☠ Il payload oggi e' la home: senza il controllo la home finirebbe due volte nella pila.
  void _openPayload(String payload) {
    _router.go(Routes.home);
    if (payload != Routes.home) unawaited(_router.push(payload));
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    unawaited(_taps?.cancel());
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    // Widget e notifiche seguono i dati da soli (widget_sync.dart, notification_providers.dart).
    ref
      ..watch(widgetSyncProvider)
      ..watch(widgetRefreshProvider)
      ..watch(notificationSyncProvider);
    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      // `fidelity`: l'arancio resta quello acceso della fiamma invece del bruno che Material
      // ricaverebbe dal seme (stessa scelta di Full Freezer col suo blu).
      // Sopra, il fondo caldo e i colori "A · Brace" (ScortePalette).
      theme: withScorteLook(
        MicroTheme.light(seed: config.seedColor, fontFamily: config.fontFamily, variant: DynamicSchemeVariant.fidelity),
        ScortePalette.light,
      ),
      darkTheme: withScorteLook(
        MicroTheme.dark(seed: config.seedColor, fontFamily: config.fontFamily, variant: DynamicSchemeVariant.fidelity),
        ScortePalette.dark,
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


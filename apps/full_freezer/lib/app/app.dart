import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../features/freezers/freezer_editor_page.dart';
import '../features/freezers/freezer_page.dart';
import '../features/home/home_page.dart';
import '../features/items/item_draft.dart';
import '../features/items/item_edit_page.dart';
import '../l10n/generated/app_localizations.dart';
import 'locale_resolution.dart';
import 'providers.dart';
import 'routes.dart';

/// Il router dell'app.
///
/// ⚑ Perche' `go_router` e non `Navigator` imperativo (ADR-005): le notifiche e il widget
/// aprono l'app con un deep link, e con una catena di `push` il deep link si rompe quando
/// l'app viene aperta da fredda, cioe' proprio nel caso che conta.
GoRouter buildRouter(WidgetRef ref) => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (_, __) => const HomePage()),
    GoRoute(
      path: Routes.welcome,
      builder: (_, __) => const FreezerEditorPage(firstRun: true),
    ),
    GoRoute(path: Routes.useSoon, builder: (_, __) => const UseSoonPage()),
    // ⚑ `new` prima di `:freezerId`: go_router prova le rotte in ordine, e "new" e' anche
    // un valore valido per il parametro.
    GoRoute(path: Routes.freezerNew, builder: (_, __) => const FreezerEditorPage()),
    GoRoute(
      path: Routes.freezerEdit,
      builder: (_, s) => FreezerEditorPage(freezerId: int.tryParse(s.pathParameters['freezerId'] ?? '')),
    ),
    GoRoute(
      path: Routes.freezer,
      builder: (_, s) => FreezerPage(freezerId: int.tryParse(s.pathParameters['freezerId'] ?? '') ?? -1),
    ),
    GoRoute(
      path: Routes.itemNew,
      builder: (_, s) => ItemEditPage(draft: s.extra is ItemDraft ? s.extra! as ItemDraft : null),
    ),
    GoRoute(
      path: Routes.itemEdit,
      builder: (_, s) => ItemEditPage(itemId: int.tryParse(s.pathParameters['itemId'] ?? '')),
    ),
  ],
  // Chi non ha ancora creato il primo freezer viene portato li', da qualunque punto entri:
  // anche da un deep link, che altrimenti mostrerebbe una home senza freezer.
  redirect: (context, state) {
    final done = ref.read(onboardingDoneProvider);
    final goingToWelcome = state.matchedLocation == Routes.welcome;
    if (!done && !goingToWelcome) return Routes.welcome;
    if (done && goingToWelcome) return Routes.home;
    return null;
  },
);

class FullFreezerApp extends ConsumerStatefulWidget {
  const FullFreezerApp({super.key});

  @override
  ConsumerState<FullFreezerApp> createState() => _FullFreezerAppState();
}

class _FullFreezerAppState extends ConsumerState<FullFreezerApp> {
  // Il router si costruisce una volta sola: ricrearlo a ogni build azzererebbe la
  // cronologia di navigazione a ogni cambio di stato.
  late final GoRouter _router = buildRouter(ref);
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    // Al ritorno in primo piano "oggi" si ricalcola: chi ha lasciato l'app aperta da ieri
    // deve vedere i giorni di oggi, non quelli di ieri.
    _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(todayProvider));
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

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

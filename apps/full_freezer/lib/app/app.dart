import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:micro_core/micro_core.dart';

import '../features/categories/custom_categories_page.dart';
import '../features/freezers/freezer_editor_page.dart';
import '../features/freezers/freezer_page.dart';
import '../features/history/history_page.dart';
import '../features/history/stats_page.dart';
import '../features/home/home_page.dart';
import '../features/items/item_draft.dart';
import '../features/items/item_edit_page.dart';
import '../features/search/search_page.dart';
import '../features/settings/settings_page.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/freezer_widget.dart';
import 'freezer_palette.dart';
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
    GoRoute(path: Routes.search, builder: (_, __) => const SearchPage()),
    GoRoute(path: Routes.settings, builder: (_, __) => const SettingsPage()),
    GoRoute(path: Routes.stats, builder: (_, __) => const StatsPage()),
    GoRoute(path: Routes.history, builder: (_, __) => const HistoryPage()),
    GoRoute(path: Routes.categories, builder: (_, __) => const CustomCategoriesPage()),
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
  StreamSubscription<String>? _taps;
  StreamSubscription<Uri?>? _widgetTaps;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        // "Oggi" si ricalcola: chi ha lasciato l'app aperta da ieri deve vedere i giorni di
        // oggi. E il piano delle notifiche si rifa': i testi dei riepiloghi dipendono dai
        // giorni, che nel frattempo sono cambiati.
        ref.invalidate(todayProvider);
        unawaited(ref.read(schedulerProvider).rescheduleAll());
      },
    );

    // Il servizio delle notifiche arriva dopo il primo frame: ci si iscrive appena c'e'.
    ref.listenManual(notificationServiceProvider, (_, next) {
      final service = next.value;
      if (service == null || _taps != null) return;
      _taps = service.taps.listen(_openPayload);
      // Se l'app era chiusa, il tocco che l'ha aperta non passa dallo stream.
      final launch = service.consumeLaunchPayload();
      if (launch != null) _openPayload(launch);
    }, fireImmediately: true);

    // Il tocco sul widget (F4.11): `fullfreezer:///use-soon` porta a "Da usare prima".
    if (FreezerWidget.available) {
      // Dopo il primo frame: prima il router non ha ancora la sua posizione iniziale, e un
      // `go` fatto in initState verrebbe sovrascritto (app aperta dal widget da chiusa).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(HomeWidget.initiallyLaunchedFromHomeWidget().then(_openWidgetUri));
      });
      _widgetTaps = HomeWidget.widgetClicked.listen(_openWidgetUri);
    }
  }

  void _openWidgetUri(Uri? uri) {
    // Solo percorsi noti: un link costruito altrove non deve aprire pagine a caso.
    if (uri?.scheme == Routes.scheme && uri?.path == Routes.useSoon) _openPayload(Routes.useSoon);
  }

  /// Apre la pagina della notifica lasciandosi dietro la home: con il solo `go`, il tasto
  /// indietro uscirebbe dall'app invece di tornare alla home (trappola gia' pagata in
  /// TrashCan).
  void _openPayload(String payload) {
    _router.go(Routes.home);
    unawaited(_router.push(payload));
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    unawaited(_taps?.cancel());
    unawaited(_widgetTaps?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    // Tiene vivo il collegamento fra le modifiche ai dati e il piano delle notifiche.
    ref.watch(notificationSyncProvider);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      // `fidelity`: il blu resta quello acceso dell'icona invece del blu ardesia che
      // Material ricaverebbe dal seme (scoperto sul primo giro sull'emulatore, 2026-10-06).
      // Sopra, il fondo e i colori dell'interfaccia "Ghiaccio" (FreezerPalette).
      theme: withFreezerLook(
        MicroTheme.light(
          seed: config.seedColor,
          fontFamily: config.fontFamily,
          variant: DynamicSchemeVariant.fidelity,
        ),
        FreezerPalette.light,
      ),
      darkTheme: withFreezerLook(
        MicroTheme.dark(
          seed: config.seedColor,
          fontFamily: config.fontFamily,
          variant: DynamicSchemeVariant.fidelity,
        ),
        FreezerPalette.dark,
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

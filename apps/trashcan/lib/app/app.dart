import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../features/backup/backup_page.dart';
import '../features/calendars/calendar_editor_page.dart';
import '../features/calendars/calendars_page.dart';
import '../features/day/day_page.dart';
import '../features/exceptions/exceptions_page.dart';
import '../features/home/home_page.dart';
import '../features/notifications/notifications_page.dart';
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
    GoRoute(path: Routes.calendars, builder: (_, __) => const CalendarsPage()),
    GoRoute(path: Routes.calendarNew, builder: (_, __) => const CalendarEditorPage()),
    GoRoute(
      path: Routes.calendarEdit,
      builder: (_, state) => CalendarEditorPage(
        calendarId: int.tryParse(state.pathParameters['calendarId'] ?? ''),
      ),
    ),
    GoRoute(path: Routes.wasteTypes, builder: (_, __) => const WasteTypesPage()),
    GoRoute(path: Routes.wasteTypeNew, builder: (_, __) => const WasteTypeEditorPage()),
    GoRoute(
      path: Routes.wasteTypeEdit,
      builder: (_, state) => WasteTypeEditorPage(
        wasteTypeId: int.tryParse(state.pathParameters['wasteTypeId'] ?? ''),
      ),
    ),
    GoRoute(
      path: Routes.day,
      builder: (_, state) => DayPage(
        date: CivilDate.tryParse(state.pathParameters['date']),
        calendarId: int.tryParse(state.uri.queryParameters['calendar'] ?? ''),
      ),
    ),
    GoRoute(path: Routes.exceptions, builder: (_, __) => const ExceptionsPage()),
    GoRoute(path: Routes.settings, builder: (_, __) => const SettingsPage()),
    GoRoute(path: Routes.notifications, builder: (_, __) => const NotificationsPage()),
    GoRoute(path: Routes.backup, builder: (_, __) => const BackupPage()),
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
  AppLifecycleListener? _lifecycle;
  StreamSubscription<String>? _taps;

  @override
  void initState() {
    super.initState();

    // ⛑ Al ritorno in primo piano si ripianifica solo se e' passata un'ora: e' il
    // guardiano che evita mezzo secondo di attesa a ogni apertura. Le modifiche ai dati
    // passano invece da notificationSyncProvider, che non guarda l'orologio.
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(ref.read(schedulerProvider).rescheduleIfStale()),
    );

    // Il servizio di notifiche arriva in un secondo momento: ci si iscrive appena c'e'.
    ref.listenManual(notificationServiceProvider, (_, next) {
      final service = next.value;
      if (service == null || _taps != null) return;
      _taps = service.taps.listen(_openPayload);
      // Se l'app era chiusa, il tocco che l'ha aperta non e' passato dallo stream: il
      // payload sta li' ad aspettare e si consuma una volta sola.
      final launch = service.consumeLaunchPayload();
      if (launch != null) _openPayload(launch);
    }, fireImmediately: true);
  }

  /// Apre il percorso arrivato da una notifica, lasciandosi dietro la home.
  ///
  /// ☠ Con il solo `go` la pagina del giorno diventa un vicolo cieco: `go` sostituisce
  /// lo stack, l'AppBar non ha la freccia indietro e il tasto di sistema esce dall'app
  /// invece di portare alla home. Chi tocca la notifica si ritrova fuori dall'app al primo
  /// gesto istintivo. Si va prima alla home e poi si impila il giorno, cosi' il ritorno
  /// indietro fa quello che tutti si aspettano.
  void _openPayload(String payload) {
    final router = _router;
    if (router == null) return;
    router.go(Routes.home);
    router.push(payload);
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    unawaited(_taps?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    // Tiene in vita il collegamento fra le modifiche ai dati e il piano delle notifiche.
    ref.watch(notificationSyncProvider);
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

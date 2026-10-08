import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../features/cameras/camera_editor_page.dart';
import '../features/cameras/cameras_page.dart';
import '../features/home/home_page.dart';
import '../features/lab/development_page.dart';
import '../features/lab/print_page.dart';
import '../features/photos/photo_viewer_page.dart';
import '../features/qr/qr_links.dart';
import '../features/qr/qr_page.dart';
import '../features/rolls/roll_detail_page.dart';
import '../features/rolls/roll_editor_page.dart';
import '../features/settings/settings_page.dart';
import '../features/stats/stats_page.dart';
import '../features/stocks/stocks_page.dart';
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
    // ⚑ `new` prima di `:rollId`: go_router prova le rotte in ordine.
    GoRoute(path: Routes.rollNew, builder: (_, __) => const RollEditorPage()),
    GoRoute(path: Routes.roll, builder: (_, s) => RollDetailPage(rollId: _id(s, 'rollId'))),
    GoRoute(path: Routes.rollEdit, builder: (_, s) => RollEditorPage(rollId: _id(s, 'rollId'))),
    GoRoute(
      path: Routes.photo,
      builder: (_, s) => PhotoViewerPage(rollId: _id(s, 'rollId'), imageId: _id(s, 'imageId')),
    ),
    GoRoute(path: Routes.qr, builder: (_, s) => QrPage(rollId: _id(s, 'rollId'))),
    GoRoute(path: Routes.development, builder: (_, s) => DevelopmentPage(rollId: _id(s, 'rollId'))),
    // ⚑ `prints/new` prima di `prints/:printId`. ☠ Per stampe e macchine `-1` (e non null) su un
    // id illeggibile: null vuol dire "nuova", e per le macchine aggirerebbe il paywall.
    GoRoute(path: Routes.printNew, builder: (_, s) => PrintPage(rollId: _id(s, 'rollId'))),
    GoRoute(
      path: Routes.printEdit,
      builder: (_, s) => PrintPage(rollId: _id(s, 'rollId'), printId: _id(s, 'printId')),
    ),
    GoRoute(path: Routes.cameras, builder: (_, __) => const CamerasPage()),
    // Protetta sulla pagina: NewCameraGate aspetta il conteggio delle macchine e poi usa ProGate.
    GoRoute(path: Routes.cameraNew, builder: (_, __) => const NewCameraGate()),
    GoRoute(path: Routes.cameraEdit, builder: (_, s) => CameraEditorPage(cameraId: _id(s, 'cameraId'))),
    GoRoute(path: Routes.stocks, builder: (_, __) => const StocksPage()),
    // Protetta sulla pagina con ProGate (F6.10).
    GoRoute(path: Routes.stats, builder: (_, __) => const StatsPage()),
  ],
);

/// Un id dal percorso. ☠ `tryParse` e non `parse`: un link scritto a mano con un id non
/// numerico darebbe un'eccezione nel builder; con -1 la pagina dice "non esiste piu'".
int _id(GoRouterState s, String name) => int.tryParse(s.pathParameters[name] ?? '') ?? -1;

/// L'app.
class FilmTrackerApp extends ConsumerStatefulWidget {
  const FilmTrackerApp({super.key});

  @override
  ConsumerState<FilmTrackerApp> createState() => _FilmTrackerAppState();
}

class _FilmTrackerAppState extends ConsumerState<FilmTrackerApp> {
  late final GoRouter _router = buildRouter(ref);
  AppLifecycleListener? _lifecycle;
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    // "Oggi" si ricalcola tornando in primo piano: i giorni in macchina e in laboratorio
    // si contano in giorni.
    _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(todayProvider));
    // Il QR del rullino (F6.12): filmtracker://roll/<n> apre il suo dettaglio con `push`, cosi'
    // la freccia indietro riporta alla home. ⚑ `app_links` e non il deep link di Flutter, che
    // userebbe `go` e perderebbe la pila (pagato con Full Freezer). Lo stream consegna anche il
    // link che ha aperto l'app da chiusa.
    _links = listenRollLinks(
      links: AppLinks().uriLinkStream,
      repository: () => ref.read(repositoryProvider),
      open: (location) => unawaited(_router.push(location)),
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    unawaited(_links?.cancel());
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

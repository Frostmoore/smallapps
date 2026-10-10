import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../features/cartellino/cartellino_camera_page.dart';
import '../features/chiusura/chiusura_page.dart';
import '../features/common/pro_gate.dart';
import '../features/dev/ocr_dev_page.dart';
import '../features/impostazioni/impostazioni_page.dart';
import '../features/impostazioni/negozi_page.dart';
import '../features/scontrino/confronto_page.dart';
import '../features/scontrino/registra_scontrino_page.dart';
import '../features/scontrino/scontrino_camera_page.dart';
import '../features/spesa/spesa_page.dart';
import '../features/statistiche/statistiche_page.dart';
import '../features/storico/dettaglio_spesa_page.dart';
import '../features/storico/storico_page.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/lettura_service.dart';
import 'locale_resolution.dart';
import 'providers.dart';
import 'routes.dart';
import 'sr_palette.dart';

/// Il router dell'app (develop_microapps.md F12.1.11).
///
/// ⚑ **Tutte le rotte sono figlie di `/`**: un `go('/storico/5')` (dopo «Salva la spesa» dallo
/// scontrino) costruisce la pila `/` → `/storico` → `/storico/5`, e «indietro» riporta sempre alla
/// spesa invece di chiudere l'app.
/// ⚑ **`ProGate` sulla rotta** per Scontrino (con confronto e registrazione) e Statistiche
/// (F12.0 punto 11): un `push` diretto non deve aprire una pagina Pro gratis. ☠ Non un `redirect`
/// di go_router (lezione di Full Freezer: pila con `/` due volte e pagina d'errore).
/// ⚑ `/dev/ocr` esiste solo con [devAttiva] (`rottaDevAttiva(kDebugMode, SR_DEV)`): in release la
/// rotta non c'e' proprio, e un link porta a «Non trovato». Lo prova test/widget/dev_route_test.dart.
GoRouter buildRouter({required bool devAttiva}) => GoRouter(
  initialLocation: Routes.spesa,
  routes: [
    GoRoute(
      path: Routes.spesa,
      builder: (_, __) => const SpesaPage(),
      routes: [
        GoRoute(
          path: _figlia(Routes.cartellino),
          builder: (_, s) => CartellinoCameraPage(
            modoIniziale: s.uri.queryParameters['modo'] == 'bilancia' ? ModoLettura.bilancia : ModoLettura.cartellino,
          ),
        ),
        GoRoute(
          path: _figlia(Routes.scontrino),
          builder: (_, __) => const ProGate(feature: FeatureKey.documentScan, child: ScontrinoCameraPage()),
          routes: [
            GoRoute(
              path: 'confronto',
              builder: (_, s) => switch (s.extra) {
                final ScontrinoLetto letto =>
                  ProGate(feature: FeatureKey.documentScan, child: ConfrontoPage(letto: letto)),
                _ => const _NotFoundPage(),
              },
            ),
            GoRoute(
              path: 'registra',
              builder: (_, s) => switch (s.extra) {
                final ScontrinoLetto letto =>
                  ProGate(feature: FeatureKey.documentScan, child: RegistraScontrinoPage(letto: letto)),
                _ => const _NotFoundPage(),
              },
            ),
          ],
        ),
        GoRoute(
          path: _figlia(Routes.chiudi),
          builder: (_, s) => ChiusuraPage(args: s.extra is ChiusuraArgs ? s.extra! as ChiusuraArgs : const ChiusuraArgs()),
        ),
        GoRoute(
          path: _figlia(Routes.storico),
          builder: (_, __) => const StoricoPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, s) => switch (_id(s)) {
                final int id => DettaglioSpesaPage(id: id),
                null => const _NotFoundPage(),
              },
            ),
          ],
        ),
        GoRoute(
          path: _figlia(Routes.statistiche),
          builder: (_, __) => const ProGate(feature: FeatureKey.statistics, child: StatistichePage()),
        ),
        GoRoute(
          path: _figlia(Routes.impostazioni),
          builder: (_, __) => ImpostazioniPage(devAttiva: devAttiva),
          routes: [GoRoute(path: 'negozi', builder: (_, __) => const NegoziPage())],
        ),
        if (devAttiva) GoRoute(path: _figlia(Routes.devOcr), builder: (_, __) => const OcrDevPage()),
      ],
    ),
  ],
  errorBuilder: (_, __) => const _NotFoundPage(),
);

/// Il percorso di una rotta figlia di `/`: senza la barra iniziale.
String _figlia(String assoluto) => assoluto.substring(1);

/// L'`:id` numerico, come Film Tracker: un id illeggibile porta a «Non trovato».
int? _id(GoRouterState s) => int.tryParse(s.pathParameters['id'] ?? '');

/// L'app.
class SpendingReviewApp extends ConsumerStatefulWidget {
  const SpendingReviewApp({super.key});

  @override
  ConsumerState<SpendingReviewApp> createState() => _SpendingReviewAppState();
}

class _SpendingReviewAppState extends ConsumerState<SpendingReviewApp> {
  late final GoRouter _router = buildRouter(devAttiva: rottaDevAttiva(debug: kDebugMode, srDev: kSrDev));
  Timer? _preparazione;

  @override
  void initState() {
    super.initState();
    // ⚑ Il motore OCR si prepara 3 secondi dopo il primo frame (F12.1.13, come pruneOrphanLogos di
    // QR Me): la prima lettura non paga il caricamento dei modelli (0,5-1 s su Android), e l'avvio
    // non lo paga nemmeno (il tastierino deve esserci subito, F12.1.18). Un motore assente non e'
    // un errore: lo dira' la prima lettura.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preparazione = Timer(const Duration(seconds: 3), () {
        unawaited(ref.read(ocrEngineProvider).prepara().catchError((Object e) => MicroLog.w('OCR non pronto: $e')));
      });
    });
  }

  @override
  void dispose() {
    _preparazione?.cancel();
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
      // «C · Una mano» (F12.0 punto 6): scura di default, con la sua versione chiara derivata.
      // Corpo Plus Jakarta Sans, numeri Space Grotesk.
      theme: withSrLook(
        MicroTheme.light(
          seed: config.seedColor,
          fontFamily: config.fontFamily,
          displayFontFamily: kNumeriFont,
          variant: DynamicSchemeVariant.fidelity,
        ),
        SrPalette.chiaro,
      ),
      darkTheme: withSrLook(
        MicroTheme.dark(
          seed: config.seedColor,
          fontFamily: config.fontFamily,
          displayFontFamily: kNumeriFont,
          variant: DynamicSchemeVariant.fidelity,
        ),
        SrPalette.scuro,
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

/// Un percorso che non porta a niente: un id illeggibile, una pagina aperta senza argomenti.
class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(L.of(context).common_notFound, textAlign: TextAlign.center),
      ),
    ),
  );
}

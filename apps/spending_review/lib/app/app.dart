import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../features/spesa/spesa_page.dart';
import '../l10n/generated/app_localizations.dart';
import 'locale_resolution.dart';
import 'providers.dart';
import 'routes.dart';
import 'sr_palette.dart';

/// Il router dell'app (develop_microapps.md F12.1.11).
///
/// ⚑ Bootstrap (F12.2c): registrata solo `/`. Le altre rotte di `Routes` arrivano con le loro
/// pagine in F12.4, con `ProGate` **sulla rotta** per Scontrino e Statistiche (F12.0 punto 11:
/// un `push` diretto non deve aprire una pagina Pro gratis) e `/dev/ocr` solo se
/// `rottaDevAttiva(...)`. Fino ad allora un percorso sconosciuto porta a «Non trovato».
GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.spesa,
  routes: [GoRoute(path: Routes.spesa, builder: (_, __) => const SpesaPage())],
  errorBuilder: (_, __) => const _NotFoundPage(),
);

/// L'app.
class SpendingReviewApp extends ConsumerStatefulWidget {
  const SpendingReviewApp({super.key});

  @override
  ConsumerState<SpendingReviewApp> createState() => _SpendingReviewAppState();
}

class _SpendingReviewAppState extends ConsumerState<SpendingReviewApp> {
  late final GoRouter _router = buildRouter();

  // ⚑ In F12.4 qui, 3 secondi dopo il primo frame, `OcrEngine.prepara()` (F12.1.13): la prima
  // lettura non paga il caricamento dei modelli, e l'avvio non lo paga nemmeno.

  @override
  void dispose() {
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

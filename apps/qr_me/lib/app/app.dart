import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../domain/qr_content.dart';
import '../features/common/pro_gate.dart';
import '../features/display/qr_display_page.dart';
import '../features/forms/form_page.dart';
import '../features/history/history_page.dart';
import '../features/home/home_page.dart';
import '../features/saved/saved_page.dart';
import '../features/scan/scan_page.dart';
import '../features/scan/scan_result_page.dart';
import '../features/settings/settings_page.dart';
import '../features/style/style_page.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/share_router.dart';
import 'entitlement.dart';
import 'locale_resolution.dart';
import 'paywall_config.dart';
import 'providers.dart';
import 'qr_palette.dart';
import 'routes.dart';

/// Il router dell'app, con tutte le rotte di develop_microapps.md F17.1.5.
///
/// ⚑ `ProGate` **sulla rotta** per moduli e stile (F17.0 punto 11): un `push` diretto (un link
/// scritto domani, un pulsante dimenticato) non deve aprire una pagina Pro gratis. I pulsanti
/// controllano comunque il Pro prima di aprire (`lib/features/common/qr_actions.dart`), per
/// mostrare subito il paywall invece del lucchetto.
GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (_, __) => const HomePage()),
    GoRoute(
      path: Routes.show,
      // Senza argomenti (un percorso scritto a mano) non c'e' niente da mostrare.
      builder: (_, s) => switch (s.extra) {
        final QrDisplayArgs args => QrDisplayPage.args(args),
        _ => const _NotFoundPage(),
      },
    ),
    GoRoute(
      path: Routes.qr,
      builder: (_, s) => _id(s) < 0 ? const _NotFoundPage() : QrDisplayPage.saved(_id(s)),
    ),
    GoRoute(path: Routes.scan, builder: (_, __) => const ScanPage()),
    GoRoute(
      path: Routes.scanResult,
      builder: (_, s) => switch (s.extra) {
        final ScanResultArgs args => ScanResultPage(args: args),
        _ => const _NotFoundPage(),
      },
    ),
    GoRoute(
      path: Routes.form,
      builder: (_, s) {
        final kind = formKindOf(s.pathParameters['kind']);
        if (kind == null) return const _NotFoundPage();
        // `?id=` illeggibile: pagina "non trovato", non un modulo nuovo che sembri una modifica.
        final rawId = s.uri.queryParameters['id'];
        if (rawId != null && int.tryParse(rawId) == null) return const _NotFoundPage();
        return ProGate(
          feature: FeatureKey.customCategories,
          child: FormPage(kind: kind, id: rawId == null ? null : int.parse(rawId)),
        );
      },
    ),
    GoRoute(
      path: Routes.style,
      builder: (_, s) => switch (s.extra) {
        final StyleArgs args => ProGate(
          feature: FeatureKey.themeCustomization,
          child: StylePage(args: args),
        ),
        _ => const _NotFoundPage(),
      },
    ),
    GoRoute(path: Routes.saved, builder: (_, __) => const SavedPage()),
    GoRoute(path: Routes.history, builder: (_, __) => const HistoryPage()),
    GoRoute(path: Routes.settings, builder: (_, __) => const SettingsPage()),
    GoRoute(path: Routes.pro, builder: (_, __) => const _PaywallRoutePage()),
  ],
  errorBuilder: (_, __) => const _NotFoundPage(),
);

/// Un id dal percorso. ☠ `tryParse` e non `parse`: un percorso scritto a mano con un id non
/// numerico darebbe un'eccezione nel builder; con -1 la pagina dice "non trovato".
int _id(GoRouterState s) => int.tryParse(s.pathParameters['id'] ?? '') ?? -1;

/// Il tipo di un modulo da `/form/:kind`; null se sconosciuto o senza modulo (testo, link).
QrKind? formKindOf(String? name) {
  final kind = QrKind.values.asNameMap()[name];
  return kFormKinds.contains(kind) ? kind : null;
}

/// L'app.
class QrMeApp extends ConsumerStatefulWidget {
  const QrMeApp({super.key});

  @override
  ConsumerState<QrMeApp> createState() => _QrMeAppState();
}

class _QrMeAppState extends ConsumerState<QrMeApp> {
  late final GoRouter _router = buildRouter();

  /// Per i messaggi della condivisione (immagine senza QR): arrivano fuori da ogni pagina.
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  ShareIntake? _intake;

  @override
  void initState() {
    super.initState();
    // ⚑ Dopo il primo frame: il router deve esistere ed essere montato prima di un `push`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final intake = ShareIntake(
        inbox: ref.read(shareInboxProvider),
        router: ref.read(shareRouterProvider),
        goRouter: _router,
        onOutcome: _onShareOutcome,
      );
      _intake = intake;
      unawaited(intake.start());
    });
  }

  void _onShareOutcome(ShareOutcome outcome) {
    final context = _messenger.currentContext;
    if (context == null) return;
    final l = L.of(context);
    final message = switch (outcome) {
      ShareOutcome.noQrInImage => l.share_noQrInImage,
      ShareOutcome.readerUnavailable => l.scan_readerUnavailable,
      _ => null,
    };
    if (message != null) _messenger.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    unawaited(_intake?.dispose());
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
      scaffoldMessengerKey: _messenger,
      // La grafica «A · Neon» (F17.6, scelta del proprietario il 2026-10-09): scura di default,
      // con la sua versione chiara. Corpo Plus Jakarta Sans, titoli Space Grotesk.
      theme: withQrLook(
        MicroTheme.light(
          seed: config.seedColor,
          fontFamily: config.fontFamily,
          displayFontFamily: kTitleFont,
          variant: DynamicSchemeVariant.fidelity,
        ),
        QrPalette.light,
      ),
      darkTheme: withQrLook(
        MicroTheme.dark(
          seed: config.seedColor,
          fontFamily: config.fontFamily,
          displayFontFamily: kTitleFont,
          variant: DynamicSchemeVariant.fidelity,
        ),
        QrPalette.dark,
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

/// Un percorso che non porta a niente: un id illeggibile, un tipo di modulo sconosciuto, una
/// pagina aperta senza i suoi argomenti.
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

/// `/pro`: il paywall come pagina (§8.T). Dal codice si preferisce `showQrPaywall`, che
/// evidenzia la funzione che l'ha innescato.
class _PaywallRoutePage extends ConsumerWidget {
  const _PaywallRoutePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(entitlementProvider);
    return PaywallPage(
      config: buildQrPaywall(L.of(context)),
      service: ref.read(entitlementProvider.notifier).service,
    );
  }
}

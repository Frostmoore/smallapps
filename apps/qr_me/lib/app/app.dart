import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../domain/qr_content.dart';
import '../features/common/pro_gate.dart';
import '../l10n/generated/app_localizations.dart';
import 'entitlement.dart';
import 'locale_resolution.dart';
import 'paywall_config.dart';
import 'providers.dart';
import 'routes.dart';

/// Il router dell'app, con tutte le rotte di develop_microapps.md F17.1.5.
///
/// ⚑ Le pagine vere arrivano con F17.4: fino ad allora ogni rotta mostra [_TodoPage] con il
/// suo titolo, cosi' i percorsi, gli argomenti e le protezioni Pro sono gia' quelli definitivi
/// e chi scrive una pagina sostituisce una riga.
///
/// ⚑ `ProGate` **sulla rotta** per moduli e stile (F17.0 punto 11): un `push` diretto (un link
/// scritto domani, un pulsante dimenticato) non deve aprire una pagina Pro gratis.
GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (_, __) => const _TodoPage(_Title.home)),
    GoRoute(
      path: Routes.show,
      // Senza argomenti (un percorso scritto a mano) non c'e' niente da mostrare.
      builder: (_, s) => s.extra is QrDisplayArgs ? const _TodoPage(_Title.show) : const _NotFoundPage(),
    ),
    GoRoute(
      path: Routes.qr,
      builder: (_, s) => _id(s) < 0 ? const _NotFoundPage() : const _TodoPage(_Title.show),
    ),
    GoRoute(path: Routes.scan, builder: (_, __) => const _TodoPage(_Title.scan)),
    GoRoute(
      path: Routes.scanResult,
      builder: (_, s) => s.extra is ScanResultArgs ? const _TodoPage(_Title.scanResult) : const _NotFoundPage(),
    ),
    GoRoute(
      path: Routes.form,
      builder: (_, s) {
        final kind = formKindOf(s.pathParameters['kind']);
        if (kind == null) return const _NotFoundPage();
        // `?id=` illeggibile: pagina "non trovato", non un modulo nuovo che sembri una modifica.
        final rawId = s.uri.queryParameters['id'];
        if (rawId != null && int.tryParse(rawId) == null) return const _NotFoundPage();
        return const ProGate(feature: FeatureKey.customCategories, child: _TodoPage(_Title.form));
      },
    ),
    GoRoute(
      path: Routes.style,
      builder: (_, s) => s.extra is StyleArgs
          ? const ProGate(feature: FeatureKey.themeCustomization, child: _TodoPage(_Title.style))
          : const _NotFoundPage(),
    ),
    GoRoute(path: Routes.saved, builder: (_, __) => const _TodoPage(_Title.saved)),
    GoRoute(path: Routes.history, builder: (_, __) => const _TodoPage(_Title.history)),
    GoRoute(path: Routes.settings, builder: (_, __) => const _TodoPage(_Title.settings)),
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
      // ⚑ Material puro dal seme verde, provvisorio: la grafica la decidono le proposte di F17.6.
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

enum _Title { home, show, scan, scanResult, form, style, saved, history, settings }

/// Segnaposto di una pagina che arriva con F17.4: il titolo e «In arrivo».
class _TodoPage extends StatelessWidget {
  const _TodoPage(this.title);

  final _Title title;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final text = switch (title) {
      _Title.home => l.appTitle,
      _Title.show => l.show_title,
      _Title.scan => l.scan_title,
      _Title.scanResult => l.scanResult_title,
      _Title.form => l.form_title,
      _Title.style => l.style_title,
      _Title.saved => l.saved_title,
      _Title.history => l.history_title,
      _Title.settings => l.settings_title,
    };
    return Scaffold(
      appBar: AppBar(title: Text(text)),
      body: Center(child: Text(l.common_comingSoon)),
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

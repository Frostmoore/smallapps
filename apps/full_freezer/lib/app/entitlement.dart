import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import 'app_config.dart';
import 'feature_limits.dart';
import 'providers.dart';

/// Il Pro di Full Freezer: gateway dello store, entitlement, `FeatureGate`.
///
/// ☠ **Debito, aperto il 2026-10-07**: questo file e' identico alla parte corrispondente di
/// `apps/trashcan/lib/app/providers.dart`. Due copie sono sopportabili; alla terza app
/// (Scorte Calore) `EntitlementView` e `EntitlementNotifier` vanno spostati in `micro_core`
/// insieme, altrimenti la prossima correzione al flusso d'acquisto (come quella della
/// rotellina eterna del 2026-10-06) andra' fatta tre volte.

/// La versione dell'app, in un posto solo: compare nel backup, nelle chiamate al server
/// e nelle informazioni.
const String appVersion = '1.0.0';

final installIdProvider = FutureProvider<InstallId>(
  (ref) => InstallId.load(appId: ref.watch(appConfigProvider).appId),
);

final purchaseGatewayProvider = Provider<PurchaseGateway>((ref) {
  final config = ref.watch(appConfigProvider);
  final gateway = switch (config.billingMode) {
    BillingMode.store => StorePurchaseGateway(),
    // Il gateway finto parte senza Pro: in sviluppo si vuole vedere il paywall.
    // Il prezzo vero del Pro di Full Freezer: lo screenshot del paywall per la revisione di
    // Apple viene da qui, e con il 2,39 € predefinito (quello di TrashCan) sarebbe sbagliato.
    BillingMode.fake => FakePurchaseGateway.withProduct(config.proSku, formattedPrice: '3,99 €'),
  };
  ref.onDispose(gateway.dispose);
  return gateway;
});

/// Lo stato dell'entitlement come lo vede la UI: un valore immutabile dietro un `Notifier`,
/// invece del `ChangeNotifier` del servizio (Riverpod 3 ha spostato
/// `ChangeNotifierProvider` fra le API legacy). Rende esplicito cosa fa ridisegnare la UI.
@immutable
class EntitlementView {
  const EntitlementView({
    required this.entitlement,
    required this.busy,
    required this.storeAvailable,
    this.product,
    this.error,
  });

  final Entitlement entitlement;
  final bool busy;
  final bool storeAvailable;
  final MicroProduct? product;
  final MicroError? error;

  bool get isPro => entitlement.isPro;
  bool get isPending => entitlement.isPending;

  @override
  bool operator ==(Object other) =>
      other is EntitlementView &&
      other.entitlement == entitlement &&
      other.busy == busy &&
      other.storeAvailable == storeAvailable &&
      other.product?.id == product?.id &&
      other.product?.formattedPrice == product?.formattedPrice &&
      other.error?.code == error?.code;

  @override
  int get hashCode => Object.hash(entitlement, busy, storeAvailable, product?.id, error?.code);
}

class EntitlementNotifier extends Notifier<EntitlementView> {
  EntitlementService? _service;

  /// Il servizio, per invocare le azioni. La UI legge lo stato da [state].
  EntitlementService get service => _service!;

  @override
  EntitlementView build() {
    final config = ref.watch(appConfigProvider);
    final paths = ref.watch(appPathsProvider);
    final installId = ref.watch(installIdProvider).value;

    // Il server licenze c'e' solo se la build riceve MA_LICENSE_URL e MA_APP_SECRET (come
    // TrashCan su Android). Senza, il servizio lavora in locale con lo store.
    final api = (config.serverEnabled && installId != null)
        ? LicenseApiClient(
            baseUri: config.licenseBaseUrl!,
            appId: licenseAppId,
            appSecret: config.appSecret,
            installId: installId.value,
            appVersion: appVersion,
          )
        : null;

    final service = EntitlementService(
      appId: licenseAppId,
      proSku: config.proSku,
      gateway: ref.watch(purchaseGatewayProvider),
      store: EntitlementStore(file: paths.file(paths.support, 'entitlement.json')),
      installId: installId ?? InstallId.fixed('00000000-0000-0000-0000-000000000000'),
      api: api,
    );
    _service = service;
    service.addListener(_sync);
    ref.onDispose(() {
      service.removeListener(_sync);
      service.dispose();
      api?.close();
    });

    // Il bootstrap parte da solo: dimenticarlo vorrebbe dire un'app che non si accorge di
    // un acquisto gia' fatto.
    unawaited(service.bootstrap());
    return _snapshot(service);
  }

  void _sync() {
    final service = _service;
    if (service == null) return;
    state = _snapshot(service);
  }

  static EntitlementView _snapshot(EntitlementService service) => EntitlementView(
    entitlement: service.current,
    busy: service.isBusy,
    storeAvailable: service.storeAvailable,
    product: service.proProduct,
    error: service.lastError,
  );
}

final entitlementProvider = NotifierProvider<EntitlementNotifier, EntitlementView>(
  EntitlementNotifier.new,
);

final isProProvider = Provider<bool>((ref) => ref.watch(entitlementProvider).isPro);

final featureGateProvider = Provider<FeatureGate>(
  (ref) => FeatureGate(limits: freezerFeatureLimits, isPro: ref.watch(isProProvider)),
);

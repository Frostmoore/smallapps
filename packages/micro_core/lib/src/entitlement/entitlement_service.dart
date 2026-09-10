import 'dart:async';

import 'package:flutter/foundation.dart';

import '../billing/purchase_gateway.dart';
import '../install/install_id.dart';
import '../util/micro_log.dart';
import '../util/result.dart';
import 'entitlement.dart';
import 'entitlement_store.dart';
import 'license_api_client.dart';

/// Tiene insieme store locale, gateway di acquisto e License Server.
///
/// Implementa ADR-007. La regola che governa tutto: **un utente che ha pagato resta Pro**
/// in aereo, in cantina e nel 2031 quando il server sarà spento. Nessun percorso di
/// questo codice può togliere il Pro per un errore di rete.
class EntitlementService extends ChangeNotifier {
  EntitlementService({
    required this.appId,
    required this.proSku,
    required this.gateway,
    required this.store,
    required this.installId,
    this.api,
    this.serverSyncInterval = const Duration(hours: 24),
  });

  /// I ritardi fra un tentativo di verifica e il successivo, dopo un acquisto riuscito.
  ///
  /// ⚑ Tre tentativi e poi basta: l'entitlement locale è già stato scritto, quindi
  /// l'utente sta già usando il Pro. La verifica serve al registro sul server, non a lui.
  /// Insistere di più consumerebbe batteria per un beneficio che non è suo.
  static const List<Duration> verifyBackoff = <Duration>[
    Duration(seconds: 2),
    Duration(seconds: 8),
    Duration(seconds: 30),
  ];

  final String appId;
  final String proSku;

  /// Pubblici e finali: servono ai test per iniettare i doppi, e sono di sola lettura.
  final PurchaseGateway gateway;
  final EntitlementStore store;
  final InstallId installId;

  /// `null` quando l'app non ha un License Server configurato. Tutto continua a
  /// funzionare: cambia solo che nessuno verifica lato server (ADR-007).
  final LicenseApi? api;

  final Duration serverSyncInterval;

  StreamSubscription<PurchaseEvent>? _sub;
  final Set<String> _verifiedTokens = <String>{};

  /// ☠ Il servizio ha lavoro asincrono in volo (verifica con backoff, sincronizzazione
  /// col server) che può concludersi dopo `dispose()`. Senza questo flag, `notifyListeners`
  /// verrebbe chiamato su un `ChangeNotifier` distrutto: in debug è un'eccezione, in
  /// release è un accesso a memoria di un oggetto che non c'è più.
  bool _disposed = false;

  Entitlement _current = const Entitlement(
    appId: '',
    status: ProStatus.free,
    source: EntitlementSource.none,
  );
  bool _busy = false;
  bool _storeAvailable = false;
  List<MicroProduct> _products = const <MicroProduct>[];
  MicroError? _lastError;
  DateTime? _lastServerSync;

  Entitlement get current => _current;
  bool get isPro => _current.isPro;
  bool get isPending => _current.isPending;
  bool get isBusy => _busy;
  bool get storeAvailable => _storeAvailable;
  List<MicroProduct> get products => _products;
  MicroProduct? get proProduct =>
      _products.where((p) => p.id == proSku).firstOrNull;
  MicroError? get lastError => _lastError;

  /// Prepara il servizio. **L'ordine dei passi è vincolante.**
  ///
  /// 1. Legge lo stato locale e lo notifica **subito**: la UI non aspetta la rete.
  /// 2. Apre il gateway. Se lo store non c'è, si esce restando con lo stato locale.
  /// 3. Ascolta gli eventi, deduplicando per token.
  /// 4. Chiede un ripristino silenzioso: gli acquisti già posseduti riemergono.
  /// 5. Sincronizza con il server solo se è passato l'intervallo previsto.
  Future<void> bootstrap() async {
    _current = await store.read(appId);
    if (_disposed) return;
    notifyListeners();

    _storeAvailable = await gateway.isAvailable();
    if (!_storeAvailable) {
      MicroLog.i('store non disponibile: resto sull\'entitlement locale');
      return;
    }

    await gateway.init();
    _sub ??= gateway.events.listen(_onPurchaseEvent);

    final loaded = await gateway.loadProducts({proSku});
    loaded.fold(ok: (list) => _products = list, err: (e) => _lastError = e);

    await gateway.restorePurchases();
    if (_disposed) return;
    notifyListeners();

    unawaited(_syncFromServerIfDue());
  }

  Future<Result<void>> buyPro() async {
    final product = proProduct;
    if (product == null) {
      final error = const MicroError(
        code: BillingErrorCodes.productNotFound,
        message: 'Prodotto Pro non disponibile',
      );
      _fail(error);
      return Err(error);
    }
    _setBusy(true);
    final result = await gateway.buy(
      product,
      obfuscatedAccountId: installId.obfuscatedAccountId,
    );
    // Il busy si spegne quando arriva l'evento, non qui: `buy` ritorna appena il foglio
    // di pagamento è stato aperto, non quando l'utente ha finito.
    result.fold(ok: (_) {}, err: _fail);
    return result;
  }

  Future<Result<void>> restorePurchases() async {
    _setBusy(true);
    final result = await gateway.restorePurchases();
    _setBusy(false);
    result.fold(ok: (_) {}, err: _fail);
    return result;
  }

  /// Forza una sincronizzazione con il server, ignorando l'intervallo.
  Future<void> refreshFromServer() => _syncFromServer();

  Future<Result<RestoreCode>> createRestoreCode() async {
    final client = api;
    if (client == null) {
      return const Err(
        MicroError(code: MicroErrorCodes.unauthorized, message: 'Nessun server configurato'),
      );
    }
    return client.createRestoreCode();
  }

  Future<Result<void>> claimRestoreCode(String code) async {
    final client = api;
    if (client == null) {
      return const Err(
        MicroError(code: MicroErrorCodes.unauthorized, message: 'Nessun server configurato'),
      );
    }
    final result = await client.claimRestoreCode(code);
    return result.fold(
      ok: (server) {
        _applyServer(server);
        return const Ok(null);
      },
      err: Err.new,
    );
  }

  /// Concede il Pro senza passare da un acquisto. **Solo in debug.**
  Future<void> debugGrantPro() async {
    assert(kDebugMode, 'debugGrantPro non deve esistere in release');
    await _apply(
      _current.copyWith(
        status: ProStatus.pro,
        source: EntitlementSource.local,
        productId: proSku,
        verifiedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_sub?.cancel());
    unawaited(gateway.dispose());
    api?.close();
    super.dispose();
  }

  Future<void> _onPurchaseEvent(PurchaseEvent event) async {
    switch (event) {
      case PurchasePending():
        await _apply(_current.copyWith(status: ProStatus.pending, productId: event.productId));
        _setBusy(false);

      case PurchaseCanceled():
        _setBusy(false);
        // Un annullamento non cambia lo stato: chi era Pro resta Pro, chi non lo era
        // resta com'era. Non è un errore e non va mostrato come tale.
        if (_current.isPending) {
          await _apply(_current.copyWith(status: ProStatus.free));
        }

      case PurchaseFailed(:final code, :final message):
        _setBusy(false);
        _fail(MicroError(code: code, message: message));
        if (_current.isPending) await _apply(_current.copyWith(status: ProStatus.free));

      case PurchaseSucceeded():
        await _onPurchaseSucceeded(event);
    }
  }

  Future<void> _onPurchaseSucceeded(PurchaseSucceeded event) async {
    _setBusy(false);
    if (event.productId != proSku) return;

    // ☠ L'entitlement si scrive PRIMA di chiamare il server. Se l'ordine si invertisse e
    // la rete fosse assente, l'utente pagherebbe e non vedrebbe lo sblocco.
    await _apply(
      Entitlement(
        appId: appId,
        status: ProStatus.pro,
        source: EntitlementSource.play,
        productId: event.productId,
        purchaseToken: event.purchaseToken,
        purchasedAt: event.purchasedAt,
        verifiedAt: DateTime.now().toUtc(),
      ),
    );

    // ☠ Poi si riconosce l'acquisto: senza, Google rimborsa da solo dopo 3 giorni.
    await gateway.completePurchase(event);

    // La verifica sul server viene per ultima, ed è opzionale.
    if (!_verifiedTokens.add(event.purchaseToken)) return;
    unawaited(_verifyWithRetry(event));
  }

  Future<void> _verifyWithRetry(PurchaseSucceeded event) async {
    final client = api;
    if (client == null) return;

    for (var attempt = 0; attempt <= verifyBackoff.length; attempt++) {
      final result = await client.verifyPurchase(
        sku: event.productId,
        purchaseToken: event.purchaseToken,
        orderId: event.orderId,
      );
      final server = result.valueOrNull;
      if (server != null) {
        _applyServer(server);
        return;
      }
      if (attempt < verifyBackoff.length) await Future<void>.delayed(verifyBackoff[attempt]);
    }
    // Falliti tutti i tentativi: l'utente è comunque Pro in locale. Il registro sul
    // server si allineerà alla prossima sincronizzazione.
    MicroLog.w('verifica acquisto non riuscita, entitlement locale resta valido');
  }

  Future<void> _syncFromServerIfDue() async {
    final last = _lastServerSync;
    if (last != null && DateTime.now().toUtc().difference(last) < serverSyncInterval) return;
    await _syncFromServer();
  }

  Future<void> _syncFromServer() async {
    final client = api;
    if (client == null) return;
    final result = await client.fetchEntitlement();
    _lastServerSync = DateTime.now().toUtc();
    result.fold(
      ok: _applyServer,
      err: (error) {
        // ☠ Qui non si tocca `_current`. Mai. Un timeout, un 500 o un DNS che non
        // risolve non sono prove che l'utente non abbia pagato. Il test
        // `offline_never_downgrades_test.dart` esiste per impedire che qualcuno
        // "semplifichi" aggiungendo un declassamento in questo ramo.
        MicroLog.i('sync entitlement non riuscita: ${error.code}');
      },
    );
  }

  void _applyServer(ServerEntitlement server) {
    unawaited(
      _apply(
        Entitlement(
          appId: appId,
          status: server.status,
          source: EntitlementSource.server,
          productId: server.productId ?? _current.productId,
          purchaseToken: _current.purchaseToken,
          purchasedAt: server.purchasedAt ?? _current.purchasedAt,
          verifiedAt: server.serverTime,
          revokedAt: server.revokedAt,
        ),
      ),
    );
  }

  /// Applica un candidato solo se **supera** quello corrente secondo ADR-007.
  Future<void> _apply(Entitlement candidate) async {
    if (!candidate.supersedes(_current)) {
      MicroLog.d('entitlement scartato: $candidate non supera $_current');
      return;
    }
    _current = candidate;
    await store.write(candidate);
    MicroLog.i('entitlement aggiornato', data: candidate);
    if (!_disposed) notifyListeners();
  }

  void _setBusy(bool value) {
    if (_busy == value || _disposed) return;
    _busy = value;
    notifyListeners();
  }

  void _fail(MicroError error) {
    _lastError = error;
    if (!_disposed) notifyListeners();
  }
}

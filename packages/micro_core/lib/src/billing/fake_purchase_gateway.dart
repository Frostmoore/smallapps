import 'dart:async';

import 'package:uuid/uuid.dart';

import '../util/result.dart';
import 'purchase_gateway.dart';

/// Come deve andare a finire il prossimo acquisto, con il gateway finto.
enum FakeOutcome {
  success,
  canceled,
  failed,
  /// L'acquisto resta in elaborazione e non si conclude mai.
  ///
  /// ⚑ È il caso più insidioso da gestire nella UI e quello che nessuno prova, perché con
  /// Play reale è raro e non riproducibile a comando. Qui si riproduce sempre.
  pendingForever,
  unavailable,
}

/// Gateway in memoria, deterministico. Non parla con nessuno store.
///
/// Serve a sviluppare l'intero flusso del paywall dal primo giorno, senza dipendere da
/// Play Console (ADR-006), e a testarlo senza rete.
class FakePurchaseGateway implements PurchaseGateway {
  FakePurchaseGateway({
    List<MicroProduct> catalog = const <MicroProduct>[],
    this.latency = const Duration(milliseconds: 600),
    this.outcome = FakeOutcome.success,
    bool startsOwned = false,
  }) : _catalog = List<MicroProduct>.unmodifiable(catalog) {
    if (startsOwned && catalog.isNotEmpty) _owned.add(catalog.first.id);
  }

  /// Catalogo di comodo per i test, con un prodotto Pro già pronto.
  factory FakePurchaseGateway.withProduct(
    String productId, {
    String formattedPrice = '2,99 €',
    FakeOutcome outcome = FakeOutcome.success,
    Duration latency = Duration.zero,
    bool startsOwned = false,
  }) => FakePurchaseGateway(
    catalog: [
      MicroProduct(
        id: productId,
        title: 'Pro',
        description: 'Sblocca tutto, per sempre',
        formattedPrice: formattedPrice,
        rawPriceMicros: 2990000,
        currencyCode: 'EUR',
      ),
    ],
    latency: latency,
    outcome: outcome,
    startsOwned: startsOwned,
  );

  final List<MicroProduct> _catalog;
  final Set<String> _owned = <String>{};
  final Set<String> _acknowledged = <String>{};
  final StreamController<PurchaseEvent> _events = StreamController<PurchaseEvent>.broadcast();
  final Map<String, String> _tokens = <String, String>{};

  /// Modificabile a runtime, per pilotare il caso successivo da un pannello di debug.
  FakeOutcome outcome;
  Duration latency;

  bool _initialized = false;

  bool owns(String productId) => _owned.contains(productId);

  bool wasAcknowledged(String productId) => _acknowledged.contains(productId);

  @override
  Future<bool> isAvailable() async => outcome != FakeOutcome.unavailable;

  @override
  Future<void> init() async => _initialized = true;

  @override
  Stream<PurchaseEvent> get events => _events.stream;

  @override
  Future<Result<List<MicroProduct>>> loadProducts(Set<String> productIds) async {
    await _wait();
    if (outcome == FakeOutcome.unavailable) {
      return const Err(
        MicroError(
          code: BillingErrorCodes.unavailable,
          message: 'Billing non disponibile (gateway finto)',
        ),
      );
    }
    return Ok(_catalog.where((p) => productIds.contains(p.id)).toList());
  }

  @override
  Future<Result<void>> buy(MicroProduct product, {required String obfuscatedAccountId}) async {
    assert(_initialized, 'buy() prima di init()');
    await _wait();

    switch (outcome) {
      case FakeOutcome.unavailable:
        return const Err(
          MicroError(
            code: BillingErrorCodes.unavailable,
            message: 'Billing non disponibile (gateway finto)',
          ),
        );

      case FakeOutcome.canceled:
        _events.add(PurchaseCanceled(product.id));
        return const Ok(null);

      case FakeOutcome.failed:
        _events.add(
          PurchaseFailed(
            product.id,
            code: BillingErrorCodes.storeError,
            message: 'Errore simulato dello store',
          ),
        );
        return const Ok(null);

      case FakeOutcome.pendingForever:
        _events.add(PurchasePending(product.id));
        return const Ok(null);

      case FakeOutcome.success:
        _events
          ..add(PurchasePending(product.id))
          ..add(_succeed(product.id, restored: false));
        return const Ok(null);
    }
  }

  @override
  Future<Result<void>> restorePurchases() async {
    await _wait();
    if (outcome == FakeOutcome.unavailable) {
      return const Err(
        MicroError(
          code: BillingErrorCodes.unavailable,
          message: 'Billing non disponibile (gateway finto)',
        ),
      );
    }
    for (final id in _owned) {
      _events.add(_succeed(id, restored: true));
    }
    return const Ok(null);
  }

  @override
  Future<void> completePurchase(PurchaseSucceeded event) async {
    _acknowledged.add(event.productId);
  }

  @override
  Future<void> dispose() async {
    if (!_events.isClosed) await _events.close();
  }

  /// Concede il prodotto senza passare dal flusso di acquisto. Solo per i test.
  void grant(String productId) => _owned.add(productId);

  void reset() {
    _owned.clear();
    _acknowledged.clear();
    _tokens.clear();
    outcome = FakeOutcome.success;
  }

  PurchaseSucceeded _succeed(String productId, {required bool restored}) {
    _owned.add(productId);
    // Lo stesso prodotto conserva lo stesso token fra un ripristino e l'altro: è così
    // che si comporta Play, ed è la condizione che rende osservabile la deduplica del
    // servizio di entitlement.
    final token = _tokens.putIfAbsent(productId, () => const Uuid().v4());
    return PurchaseSucceeded(
      productId,
      purchaseToken: token,
      orderId: 'FAKE.${token.substring(0, 8)}',
      purchasedAt: DateTime.now().toUtc(),
      restored: restored,
    );
  }

  Future<void> _wait() => latency == Duration.zero ? Future<void>.value() : Future.delayed(latency);
}

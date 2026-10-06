import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../util/micro_log.dart';
import '../util/result.dart';
import 'purchase_gateway.dart';

/// Il gateway vero, su Google Play Billing.
class StorePurchaseGateway implements PurchaseGateway {
  StorePurchaseGateway({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  final StreamController<PurchaseEvent> _events = StreamController<PurchaseEvent>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// I token già visti in questa sessione.
  ///
  /// ☠ `in_app_purchase` consegna sullo stream anche gli acquisti passati **all'avvio**,
  /// non solo dopo `restorePurchases()`. Senza deduplica, lo stesso acquisto produce due
  /// verifiche al server e due snackbar "grazie per l'acquisto".
  final Set<String> _seenTokens = <String>{};

  @override
  Stream<PurchaseEvent> get events => _events.stream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<void> init() async {
    _sub ??= _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object error, StackTrace stack) {
        MicroLog.e('purchaseStream in errore', error: error, stackTrace: stack);
      },
    );
  }

  @override
  Future<Result<List<MicroProduct>>> loadProducts(Set<String> productIds) async {
    try {
      final response = await _iap.queryProductDetails(productIds);
      if (response.error != null) {
        return Err(
          MicroError(
            code: BillingErrorCodes.storeError,
            message: response.error!.message,
            cause: response.error,
          ),
        );
      }
      if (response.notFoundIDs.isNotEmpty) {
        // ☠ Non è per forza un bug del codice. Su Play un prodotto non è interrogabile
        // finché l'AAB non è pubblicato su un canale, e la propagazione richiede ore. Su
        // iOS lo store non restituisce **nessun** prodotto finché l'accordo per le app a
        // pagamento non è attivo in App Store Connect, anche se il prodotto è pronto.
        // Il servizio lo tratta come `CatalogState.missing`, non come un successo.
        MicroLog.w('prodotti non trovati nello store: ${response.notFoundIDs.join(", ")}');
      }
      return Ok(response.productDetails.map(_toMicroProduct).toList());
    } on Exception catch (error, stack) {
      MicroLog.e('queryProductDetails fallita', error: error, stackTrace: stack);
      return Err(MicroError.unexpected(error, stack));
    }
  }

  @override
  Future<Result<void>> buy(MicroProduct product, {required String obfuscatedAccountId}) async {
    try {
      final response = await _iap.queryProductDetails({product.id});
      final details = response.productDetails.where((d) => d.id == product.id).firstOrNull;
      if (details == null) {
        return const Err(
          MicroError(
            code: BillingErrorCodes.productNotFound,
            message: 'Prodotto non disponibile nello store',
          ),
        );
      }

      // `buyNonConsumable` e non `buyConsumable`: il Pro è per sempre e non va consumato.
      // Consumarlo lo renderebbe riacquistabile, cioè addebitabile due volte.
      await _iap.buyNonConsumable(purchaseParam: _parametro(details, obfuscatedAccountId));
      return const Ok(null);
    } on Exception catch (error, stack) {
      MicroLog.e('acquisto fallito', error: error, stackTrace: stack);
      return Err(MicroError.unexpected(error, stack));
    }
  }

  /// Il parametro d'acquisto giusto per il negozio su cui giriamo.
  ///
  /// ☠ `GooglePlayPurchaseParam` è l'**unico** punto di tutto il gateway legato a Play:
  /// interrogare il catalogo, comprare, ripristinare e ascoltare lo stream sono identici
  /// sui due negozi. Passandolo su iOS, `in_app_purchase` lo rifiuta a runtime, quindi il
  /// difetto non si vede compilando: si vede quando qualcuno tocca il pulsante d'acquisto.
  ///
  /// ⚑ Si guarda [defaultTargetPlatform] e non `Platform.isAndroid` perché il secondo
  /// legge `dart:io`, che nei test non c'è modo di far mentire: con `defaultTargetPlatform`
  /// un test può verificare entrambi i rami su qualunque macchina.
  PurchaseParam _parametro(ProductDetails details, String? obfuscatedAccountId) =>
      defaultTargetPlatform == TargetPlatform.android
      ? GooglePlayPurchaseParam(
          productDetails: details,
          applicationUserName: obfuscatedAccountId,
        )
      : PurchaseParam(productDetails: details, applicationUserName: obfuscatedAccountId);

  @override
  Future<Result<void>> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      return const Ok(null);
    } on Exception catch (error, stack) {
      MicroLog.e('ripristino acquisti fallito', error: error, stackTrace: stack);
      return Err(MicroError.unexpected(error, stack));
    }
  }

  @override
  Future<void> completePurchase(PurchaseSucceeded event) async {
    // Il plugin tiene traccia degli acquisti da completare: si ricava quello giusto dal
    // token, invece di conservare il PurchaseDetails, che non sopravvive a un riavvio.
    final pending = _pendingByToken.remove(event.purchaseToken);
    if (pending == null) return;
    if (!pending.pendingCompletePurchase) return;
    try {
      await _iap.completePurchase(pending);
      MicroLog.i('acquisto riconosciuto', data: event.productId);
    } on Exception catch (error, stack) {
      // ☠ Se questa fallisce e non viene ritentata entro 3 giorni, Google rimborsa
      // automaticamente. Il ritentativo avviene al prossimo avvio, perché lo stream
      // riconsegna l'acquisto non riconosciuto.
      MicroLog.e('riconoscimento acquisto fallito', error: error, stackTrace: stack);
    }
  }

  final Map<String, PurchaseDetails> _pendingByToken = <String, PurchaseDetails>{};

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    if (!_events.isClosed) await _events.close();
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _events.add(PurchasePending(purchase.productID));

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final token = purchase.purchaseID ?? purchase.verificationData.serverVerificationData;
          if (!_seenTokens.add(token)) continue;
          _pendingByToken[token] = purchase;
          _events.add(
            PurchaseSucceeded(
              purchase.productID,
              purchaseToken: purchase.verificationData.serverVerificationData,
              orderId: purchase.purchaseID,
              purchasedAt: _parseDate(purchase.transactionDate),
              restored: purchase.status == PurchaseStatus.restored,
            ),
          );

        case PurchaseStatus.canceled:
          _events.add(PurchaseCanceled(purchase.productID));

        case PurchaseStatus.error:
          _events.add(
            PurchaseFailed(
              purchase.productID,
              code: purchase.error?.code ?? BillingErrorCodes.storeError,
              message: purchase.error?.message ?? 'Errore sconosciuto dello store',
            ),
          );
      }
    }
  }

  static DateTime _parseDate(String? raw) {
    final ms = int.tryParse(raw ?? '');
    return ms == null
        ? DateTime.now().toUtc()
        : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  static MicroProduct _toMicroProduct(ProductDetails d) => MicroProduct(
    id: d.id,
    title: d.title,
    description: d.description,
    formattedPrice: d.price,
    rawPriceMicros: (d.rawPrice * 1000000).round(),
    currencyCode: d.currencyCode,
  );
}

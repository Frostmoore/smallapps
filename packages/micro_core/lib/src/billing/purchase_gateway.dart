import 'package:meta/meta.dart';

import '../util/money.dart';
import '../util/result.dart';

/// Un prodotto acquistabile, come lo descrive lo store.
@immutable
class MicroProduct {
  const MicroProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.formattedPrice,
    required this.rawPriceMicros,
    required this.currencyCode,
  });

  final String id;
  final String title;
  final String description;

  /// Il prezzo **già localizzato dallo store**, per esempio "2,99 €".
  ///
  /// ☠ È questo che va mostrato nel paywall, mai un prezzo scritto nel codice. Google
  /// applica prezzi diversi per paese, promozioni e valute: un prezzo hard-coded è
  /// sbagliato per la maggior parte degli utenti e, quando diverge da quello che
  /// addebitano davvero, è anche un problema legale.
  final String formattedPrice;

  /// Prezzo in milionesimi di unità di valuta, come lo dà Play.
  final int rawPriceMicros;

  final String currencyCode;

  Money get price => Money.cents((rawPriceMicros / 10000).round(), currency: currencyCode);

  @override
  String toString() => 'MicroProduct($id, $formattedPrice)';
}

/// Cosa è successo a un acquisto.
@immutable
sealed class PurchaseEvent {
  const PurchaseEvent(this.productId);

  final String productId;
}

/// Pagamento avviato ma non ancora concluso.
///
/// ⚑ Non è un caso di scuola: succede con i pagamenti che richiedono conferma bancaria e
/// con i metodi "paga in contanti" disponibili in alcuni paesi. La UI deve mostrare
/// "in elaborazione" e **non** lasciare l'utente su uno spinner infinito.
final class PurchasePending extends PurchaseEvent {
  const PurchasePending(super.productId);
}

/// Acquisto valido. Va riconosciuto e trasformato in entitlement.
final class PurchaseSucceeded extends PurchaseEvent {
  const PurchaseSucceeded(
    super.productId, {
    required this.purchaseToken,
    required this.purchasedAt,
    required this.restored,
    this.orderId,
  });

  /// La chiave reale dell'acquisto: è questa che il server verifica presso Google.
  final String purchaseToken;

  final String? orderId;
  final DateTime purchasedAt;

  /// `true` se arriva da un ripristino e non da un acquisto appena fatto. Serve alla UI
  /// per non dire "grazie per l'acquisto" a chi ha solo reinstallato l'app.
  final bool restored;
}

/// L'utente ha chiuso il foglio di pagamento. Non è un errore.
final class PurchaseCanceled extends PurchaseEvent {
  const PurchaseCanceled(super.productId);
}

/// L'acquisto è fallito per un motivo tecnico.
final class PurchaseFailed extends PurchaseEvent {
  const PurchaseFailed(super.productId, {required this.code, required this.message});

  final String code;
  final String message;
}

/// Il confine fra l'app e lo store.
///
/// Esiste per poter sviluppare e testare tutto il flusso del paywall senza aver caricato
/// l'app su un canale di Play Console (ADR-006). L'implementazione si sceglie a compile
/// time con `--dart-define=BILLING=fake|play`.
abstract interface class PurchaseGateway {
  /// `false` su un dispositivo senza Play Services. L'app deve restare usabile.
  Future<bool> isAvailable();

  Future<void> init();

  /// Gli eventi di acquisto, inclusi quelli **già presenti all'avvio**.
  Stream<PurchaseEvent> get events;

  Future<Result<List<MicroProduct>>> loadProducts(Set<String> productIds);

  Future<Result<void>> buy(MicroProduct product, {required String obfuscatedAccountId});

  /// Rimette sullo stream gli acquisti già posseduti da questo account.
  Future<Result<void>> restorePurchases();

  /// Conferma allo store che l'acquisto è stato consegnato all'utente.
  ///
  /// ☠ **Un acquisto non riconosciuto entro 3 giorni viene rimborsato automaticamente da
  /// Google.** È la causa numero uno dei rimborsi inspiegabili. Va chiamata **dopo** aver
  /// scritto l'entitlement in locale, e va ritentata all'avvio per gli acquisti pendenti.
  Future<void> completePurchase(PurchaseSucceeded event);

  Future<void> dispose();
}

/// Codici d'errore specifici del billing.
abstract final class BillingErrorCodes {
  static const String unavailable = 'billing_unavailable';
  static const String productNotFound = 'product_not_found';
  static const String alreadyOwned = 'already_owned';
  static const String userCanceled = 'user_canceled';
  static const String storeError = 'store_error';
}

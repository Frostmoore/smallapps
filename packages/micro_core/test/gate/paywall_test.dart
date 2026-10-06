import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

const String _sku = 'testapp_pro_lifetime';

/// Il paywall quando il prezzo del Pro non arriva.
///
/// ☠ Esiste per il difetto del 2026-10-06: su iPhone il pulsante d'acquisto mostrava una
/// rotellina per sempre, perche' lo store non restituiva il prodotto e niente lo chiedeva
/// di nuovo. Il test di stato dice che il servizio sa distinguere; questo dice che **la
/// schermata** lo mostra, ed e' la schermata che decide se qualcuno puo' pagare.
void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('micro_paywall_'));
  tearDown(() {
    try {
      temp.deleteSync(recursive: true);
    } on FileSystemException {
      // la ripulisce il sistema
    }
  });

  EntitlementService servizio(_Catalogo gateway) => EntitlementService(
    appId: 'testapp',
    proSku: _sku,
    gateway: gateway,
    store: EntitlementStore(file: File('${temp.path}/entitlement.json')),
    installId: InstallId.fixed('11111111-2222-3333-4444-555555555555'),
  );

  PaywallConfig config() => PaywallConfig(
    appName: 'Test',
    headline: 'Pro',
    subhead: 'Un pagamento unico',
    benefits: const [],
    buyLabel: (price) => price == null ? 'Sblocca' : 'Sblocca - $price',
    restoreLabel: 'Ripristina',
    pendingLabel: 'In elaborazione',
    thanksLabel: 'Grazie',
    nothingToRestoreLabel: 'Niente da ripristinare',
    unavailableLabel: 'Nessuno store',
    productUnavailableLabel: 'Il prezzo non e arrivato',
    retryLabel: 'Riprova',
    oneTimeNotice: 'Per sempre',
  );

  testWidgets('senza prezzo mostra il motivo e un Riprova, non una rotellina', (tester) async {
    final gateway = _Catalogo();
    final service = servizio(gateway);
    await tester.runAsync(service.bootstrap);

    await tester.pumpWidget(
      MaterialApp(home: PaywallPage(config: config(), service: service)),
    );
    // L'apertura richiede di nuovo il prezzo: si lascia finire.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    expect(find.text('Il prezzo non e arrivato'), findsOneWidget);
    expect(find.text('Riprova'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Il prodotto compare, l'utente tocca Riprova, il pulsante d'acquisto arriva col prezzo.
    gateway.prodotti = [_pro];
    await tester.tap(find.text('Riprova'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    expect(find.text('Sblocca - 2,39 €'), findsOneWidget);
    expect(find.text('Il prezzo non e arrivato'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
}

const MicroProduct _pro = MicroProduct(
  id: _sku,
  title: 'Pro',
  description: 'Sblocca tutto',
  formattedPrice: '2,39 €',
  rawPriceMicros: 2390000,
  currencyCode: 'EUR',
);

class _Catalogo extends FakePurchaseGateway {
  _Catalogo() : super(latency: Duration.zero);

  List<MicroProduct> prodotti = const <MicroProduct>[];

  @override
  Future<Result<List<MicroProduct>>> loadProducts(Set<String> productIds) async =>
      Ok(prodotti.where((p) => productIds.contains(p.id)).toList());
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

const String appId = 'testapp';
const String sku = 'testapp_pro_lifetime';

/// Attende finché [condition] è vera, oppure si arrende dopo [timeout].
///
/// ⚑ `pumpEventQueue()` da solo non basta qui: la catena acquisto → entitlement → file
/// passa per una scrittura su disco, e il numero di giri della coda necessari dipende
/// dalla piattaforma. Aspettare una condizione invece di un numero fisso di giri rende il
/// test deterministico ovunque.
/// Aspetta che [condition] diventi vera, o che scada il tempo.
///
/// ☠ La condizione puo' essere **asincrona** e viene attesa. Prima accettava solo una
/// funzione sincrona, e chi doveva leggere da disco lanciava la lettura con `unawaited`
/// assegnando il risultato a una variabile esterna. Con letture che si accavallano, la
/// risposta di una lettura vecchia arriva dopo quella nuova e la sovrascrive: la variabile
/// torna indietro, la condizione non si stabilizza e il test fallisce una volta su tre.
/// Un test che fallisce a caso e' peggio di un test che non c'e', perche' insegna a
/// rilanciare invece che a guardare.
Future<void> waitUntil(
  FutureOr<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

/// Un client che fallisce sempre, come farebbe la rete assente.
class _OfflineApi implements LicenseApi {
  int calls = 0;

  Future<Result<T>> _fail<T>() async {
    calls++;
    return const Err(
      MicroError(code: MicroErrorCodes.network, message: 'Server non raggiungibile'),
    );
  }

  @override
  Future<Result<ServerEntitlement>> verifyPurchase({
    required String sku,
    required String purchaseToken,
    String? orderId,
  }) => _fail();

  @override
  Future<Result<ServerEntitlement>> fetchEntitlement() => _fail();

  @override
  Future<Result<RestoreCode>> createRestoreCode() => _fail();

  @override
  Future<Result<ServerEntitlement>> claimRestoreCode(String code) => _fail();

  @override
  void close() {}
}

/// Un client che risponde sempre con lo stato dato.
class _FakeApi implements LicenseApi {
  _FakeApi(this.status);

  ProStatus status;
  int verifyCalls = 0;

  ServerEntitlement get _entitlement => ServerEntitlement(
    status: status,
    productId: sku,
    purchasedAt: DateTime.utc(2026, 9, 1),
    revokedAt: status == ProStatus.revoked ? DateTime.utc(2026, 9, 5) : null,
    serverTime: DateTime.utc(2026, 9, 10),
  );

  @override
  Future<Result<ServerEntitlement>> verifyPurchase({
    required String sku,
    required String purchaseToken,
    String? orderId,
  }) async {
    verifyCalls++;
    return Ok(_entitlement);
  }

  @override
  Future<Result<ServerEntitlement>> fetchEntitlement() async => Ok(_entitlement);

  @override
  Future<Result<RestoreCode>> createRestoreCode() async =>
      Ok(RestoreCode(code: 'ABCD2345', expiresAt: DateTime.utc(2026, 9, 17)));

  @override
  Future<Result<ServerEntitlement>> claimRestoreCode(String code) async => Ok(_entitlement);

  @override
  void close() {}
}

void main() {
  late Directory temp;
  late EntitlementStore store;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('micro_ent_');
    store = EntitlementStore(file: File('${temp.path}/entitlement.json'));
  });

  tearDown(() {
    // Su Windows la cancellazione fallisce se un handle e' ancora aperto: e' rumore di
    // pulizia, non un difetto del codice sotto test, e non deve far fallire il test.
    try {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    } on FileSystemException {
      // la cartella temporanea la ripulisce il sistema
    }
  });

  EntitlementService build({required FakePurchaseGateway gateway, LicenseApi? api}) =>
      EntitlementService(
    appId: appId,
    proSku: sku,
    gateway: gateway,
    store: store,
    installId: InstallId.fixed('11111111-2222-3333-4444-555555555555'),
    api: api,
  );

  group('proprieta delle dipendenze', () {
    test('chiudere il servizio NON chiude il gateway che gli e stato passato', () async {
      // ☠ Questo test esiste per un difetto trovato sull'emulatore, non a tavolino.
      //
      // EntitlementService.dispose() chiudeva il gateway ricevuto per iniezione. In
      // TrashCan il gateway vive in un provider di Riverpod e il servizio viene ricreato
      // appena l'id di installazione finisce di caricarsi, cioe' sempre, a ogni avvio. Il
      // primo servizio chiudeva il gateway, il secondo ne riceveva uno gia' chiuso, e da
      // quel momento ogni acquisto falliva con "Cannot add new events after calling close".
      //
      // Sintomo per l'utente: il bottone "Sblocca Pro" gira all'infinito. Cioe' nessuno
      // puo' comprare, in un'app il cui unico ricavo e' quell'acquisto.
      final gateway = FakePurchaseGateway.withProduct(sku);
      final first = build(gateway: gateway);
      await first.bootstrap();
      first.dispose();

      // Il gateway deve essere ancora vivo: chi lo ha costruito non lo ha chiuso.
      final second = build(gateway: gateway);
      await second.bootstrap();
      final result = await second.buyPro();
      expect(result, isNot(isA<Err<void>>()));

      await pumpEventQueue();
      expect(
        second.isPro,
        isTrue,
        reason: 'un acquisto dopo la ricreazione del servizio deve andare a buon fine',
      );
      second.dispose();
      await gateway.dispose();
    });
  });

  group('supersedes: la regola che protegge chi ha pagato (ADR-007)', () {
    const free = Entitlement(
      appId: appId,
      status: ProStatus.free,
      source: EntitlementSource.none,
    );
    const proDaPlay = Entitlement(
      appId: appId,
      status: ProStatus.pro,
      source: EntitlementSource.play,
    );
    const proDaServer = Entitlement(
      appId: appId,
      status: ProStatus.pro,
      source: EntitlementSource.server,
    );

    test('un Pro promuove un free', () {
      expect(proDaPlay.supersedes(free), isTrue);
    });

    test('un free NON declassa un Pro, da nessuna fonte pari o inferiore', () {
      for (final source in EntitlementSource.values) {
        final candidato = Entitlement(appId: appId, status: ProStatus.free, source: source);
        if (source.trust <= EntitlementSource.play.trust) {
          expect(
            candidato.supersedes(proDaPlay),
            isFalse,
            reason: 'free da ${source.name} non deve togliere un Pro da play',
          );
        }
      }
    });

    test('solo una revoca dal server toglie il Pro', () {
      const revocaServer = Entitlement(
        appId: appId,
        status: ProStatus.revoked,
        source: EntitlementSource.server,
      );
      const revocaLocale = Entitlement(
        appId: appId,
        status: ProStatus.revoked,
        source: EntitlementSource.local,
      );
      expect(revocaServer.supersedes(proDaServer), isTrue);
      expect(revocaLocale.supersedes(proDaPlay), isFalse);
    });

    test('una revoca dal server non viene sovrascritta da un Pro successivo', () {
      const revoca = Entitlement(
        appId: appId,
        status: ProStatus.revoked,
        source: EntitlementSource.server,
      );
      expect(proDaPlay.supersedes(revoca), isFalse);
    });

    test('a parita di stato vince la fonte piu affidabile', () {
      expect(proDaServer.supersedes(proDaPlay), isTrue);
      expect(proDaPlay.supersedes(proDaServer), isFalse);
    });

    test('a parita di stato e fonte vince la verifica piu recente', () {
      final vecchio = proDaServer.copyWith(verifiedAt: DateTime.utc(2026, 1, 1));
      final nuovo = proDaServer.copyWith(verifiedAt: DateTime.utc(2026, 9, 1));
      expect(nuovo.supersedes(vecchio), isTrue);
      expect(vecchio.supersedes(nuovo), isFalse);
    });
  });

  group('offline non declassa mai (ADR-007)', () {
    test('un Pro salvato resta Pro anche se il server e irraggiungibile', () async {
      await store.write(
        const Entitlement(
          appId: appId,
          status: ProStatus.pro,
          source: EntitlementSource.play,
          productId: sku,
          purchaseToken: 'token-storico',
        ),
      );

      final api = _OfflineApi();
      final service = build(
        gateway: FakePurchaseGateway.withProduct(sku, startsOwned: true),
        api: api,
      );
      await service.bootstrap();
      await waitUntil(() => api.calls > 0);

      expect(service.isPro, isTrue, reason: 'il server offline non puo togliere il Pro');
      expect(api.calls, greaterThan(0), reason: 'il tentativo va comunque fatto');
      service.dispose();
    });

    test('senza store disponibile resta l entitlement locale', () async {
      await store.write(
        const Entitlement(
          appId: appId,
          status: ProStatus.pro,
          source: EntitlementSource.play,
          productId: sku,
        ),
      );
      final service = build(
        gateway: FakePurchaseGateway.withProduct(sku, outcome: FakeOutcome.unavailable),
      );
      await service.bootstrap();

      expect(service.storeAvailable, isFalse);
      expect(service.isPro, isTrue);
      service.dispose();
    });
  });

  group('acquisto', () {
    test('senza rete l acquisto sblocca comunque il Pro in locale', () async {
      final gateway = FakePurchaseGateway.withProduct(sku);
      final service = build(gateway: gateway, api: _OfflineApi());
      await service.bootstrap();
      expect(service.isPro, isFalse);

      await service.buyPro();
      await waitUntil(() => service.isPro);

      expect(service.isPro, isTrue);
      expect(service.current.source, EntitlementSource.play);
      service.dispose();
    });

    test('l acquisto viene riconosciuto allo store', () async {
      // Senza acknowledge Google rimborsa da solo dopo 3 giorni.
      final gateway = FakePurchaseGateway.withProduct(sku);
      final service = build(gateway: gateway);
      await service.bootstrap();
      await service.buyPro();
      await waitUntil(() => gateway.wasAcknowledged(sku));

      expect(gateway.wasAcknowledged(sku), isTrue);
      service.dispose();
    });

    test('lo stato finisce su disco, non solo in memoria', () async {
      final service = build(gateway: FakePurchaseGateway.withProduct(sku));
      await service.bootstrap();
      await service.buyPro();

      // Si aspetta il FILE, non lo stato in memoria: `_apply` pubblica il nuovo stato
      // subito e persiste dopo, perche' l'utente deve vedere lo sblocco senza attendere
      // il disco. La finestra fra le due cose e' minima ma esiste, e il test deve
      // verificare la persistenza, non la reattivita'.
      var persistito = Entitlement.free(appId);
      await waitUntil(() async {
        persistito = await store.read(appId);
        return persistito.isPro;
      });
      service.dispose();

      expect(persistito.isPro, isTrue);
      expect(persistito.purchaseToken, isNotNull);
    });

    test('se il foglio di pagamento non si apre, lo spinner si spegne', () async {
      // ☠ Questo test esiste per il caso che si presenta **appena si pubblica**: il
      // prodotto in-app non e' ancora stato creato su Play, oppure il dispositivo del
      // tester non ha Play Services aggiornati. `buy` fallisce subito e nessun evento di
      // acquisto arrivera' mai. Il codice spegneva il busy solo sull'evento, quindi il
      // bottone "Sblocca Pro" restava a girare per sempre, senza messaggio e senza
      // possibilita' di riprovare.
      final gateway = FakePurchaseGateway.withProduct(sku);
      final service = build(gateway: gateway);
      await service.bootstrap();

      // Il catalogo e' stato caricato, ma da ora in poi lo store non risponde piu'.
      gateway.outcome = FakeOutcome.unavailable;

      final result = await service.buyPro();
      await pumpEventQueue();

      expect(result.isErr, isTrue);
      expect(service.isBusy, isFalse, reason: 'niente spinner infinito');
      expect(service.lastError, isNotNull, reason: 'e va anche detto a chi guarda');
      expect(service.isPro, isFalse);
      service.dispose();
    });

    test('senza prodotto a catalogo non si accende nemmeno lo spinner', () async {
      // Il caso di prima, ma un passo prima: su Play il prodotto non esiste ancora, quindi
      // il catalogo torna vuoto e non c'e' proprio niente da comprare.
      final service = build(gateway: FakePurchaseGateway());
      await service.bootstrap();

      final result = await service.buyPro();

      expect(result.isErr, isTrue);
      expect(service.isBusy, isFalse);
      expect(service.lastError?.code, BillingErrorCodes.productNotFound);
      service.dispose();
    });

    test('un acquisto annullato non concede niente e non e un errore', () async {
      final service = build(
        gateway: FakePurchaseGateway.withProduct(sku, outcome: FakeOutcome.canceled),
      );
      await service.bootstrap();
      await service.buyPro();
      await pumpEventQueue();

      expect(service.isPro, isFalse);
      expect(service.isBusy, isFalse, reason: 'niente spinner infinito');
      service.dispose();
    });

    test('un acquisto in attesa mette in pending, non in Pro', () async {
      final service = build(
        gateway: FakePurchaseGateway.withProduct(sku, outcome: FakeOutcome.pendingForever),
      );
      await service.bootstrap();
      await service.buyPro();
      await waitUntil(() => service.isPending);

      expect(service.isPending, isTrue);
      expect(service.isPro, isFalse);
      expect(service.isBusy, isFalse);
      service.dispose();
    });

    test('un acquisto fallito lascia lo stato invariato e registra l errore', () async {
      final service = build(
        gateway: FakePurchaseGateway.withProduct(sku, outcome: FakeOutcome.failed),
      );
      await service.bootstrap();
      await service.buyPro();
      await waitUntil(() => service.lastError != null);

      expect(service.isPro, isFalse);
      expect(service.lastError, isNotNull);
      service.dispose();
    });
  });

  group('deduplica', () {
    test('lo stesso token non viene verificato due volte', () async {
      // in_app_purchase riconsegna gli acquisti passati a ogni avvio: senza deduplica
      // ogni ripristino genererebbe una nuova verifica al server.
      final gateway = FakePurchaseGateway.withProduct(sku, startsOwned: true);
      final api = _FakeApi(ProStatus.pro);
      final service = build(gateway: gateway, api: api);
      await service.bootstrap();
      await pumpEventQueue();

      await service.restorePurchases();
      await pumpEventQueue();
      await service.restorePurchases();
      await pumpEventQueue();

      expect(api.verifyCalls, lessThanOrEqualTo(1));
      service.dispose();
    });
  });

  group('server', () {
    test('una revoca dal server toglie il Pro', () async {
      await store.write(
        const Entitlement(
          appId: appId,
          status: ProStatus.pro,
          source: EntitlementSource.play,
          productId: sku,
        ),
      );
      final service = build(
        gateway: FakePurchaseGateway.withProduct(sku),
        api: _FakeApi(ProStatus.revoked),
      );
      await service.bootstrap();
      await service.refreshFromServer();
      await waitUntil(() => !service.isPro);

      expect(service.isPro, isFalse);
      expect(service.current.status, ProStatus.revoked);
      service.dispose();
    });

    test('il codice di ripristino concede il Pro', () async {
      final service = build(
        gateway: FakePurchaseGateway.withProduct(sku),
        api: _FakeApi(ProStatus.pro),
      );
      await service.bootstrap();
      final result = await service.claimRestoreCode('ABCD2345');
      await waitUntil(() => service.isPro);

      expect(result.isOk, isTrue);
      expect(service.isPro, isTrue);
      expect(service.current.source, EntitlementSource.server);
      service.dispose();
    });

    test('senza server configurato il codice di ripristino fallisce con grazia', () async {
      final service = build(gateway: FakePurchaseGateway.withProduct(sku));
      await service.bootstrap();
      final result = await service.createRestoreCode();

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.code, MicroErrorCodes.unauthorized);
      service.dispose();
    });
  });

  group('store su disco', () {
    test('un file corrotto degrada a gratuito senza lanciare', () async {
      await store.file.writeAsString('{ questo non e json');
      final letto = await store.read(appId);
      expect(letto.isPro, isFalse);
    });

    test('un entitlement di un altra app non concede niente', () async {
      await store.file.writeAsString(
        jsonEncode(
          const Entitlement(
            appId: 'un_altra_app',
            status: ProStatus.pro,
            source: EntitlementSource.server,
          ).toJson(),
        ),
      );
      final letto = await store.read(appId);
      expect(letto.isPro, isFalse);
    });

    test('uno stato sconosciuto da una versione futura non concede niente', () async {
      await store.file.writeAsString(
        jsonEncode(<String, Object?>{
          'appId': appId,
          'status': 'super_pro_del_futuro',
          'source': 'server',
        }),
      );
      final letto = await store.read(appId);
      expect(letto.isPro, isFalse);
    });

    test('round-trip completo', () async {
      final originale = Entitlement(
        appId: appId,
        status: ProStatus.pro,
        source: EntitlementSource.server,
        productId: sku,
        purchaseToken: 'tok',
        purchasedAt: DateTime.utc(2026, 9, 1),
        verifiedAt: DateTime.utc(2026, 9, 10),
      );
      await store.write(originale);
      final riletto = await store.read(appId);
      expect(riletto, originale);
      expect(riletto.purchasedAt, originale.purchasedAt);
    });
  });

  group('il prezzo del Pro: nessuna rotellina eterna', () {
    // ☠ Questo gruppo esiste per il difetto del 2026-10-06. Su iPhone lo store rispondeva
    //   "prodotto non trovato" senza errori; il servizio teneva l'elenco vuoto, non lo
    //   richiedeva piu', e il paywall girava per sempre. Nessuno poteva comprare il Pro.

    test('se lo store non conosce il prodotto, lo stato dice "mancante", non "in arrivo"', () async {
      final service = build(gateway: _CatalogoVariabile());
      addTearDown(service.dispose);
      await service.bootstrap();

      expect(service.proProduct, isNull);
      expect(service.catalogState, CatalogState.missing);
    });

    test('quando il prodotto compare, ricaricare lo trova senza riavviare l app', () async {
      final gateway = _CatalogoVariabile();
      final service = build(gateway: gateway);
      addTearDown(service.dispose);
      await service.bootstrap();
      expect(service.catalogState, CatalogState.missing);

      gateway.prodotti = [_pro];
      await service.reloadProducts();

      expect(service.catalogState, CatalogState.ready);
      expect(service.proProduct?.formattedPrice, '2,39 €');
    });

    test('uno store che non risponde diventa "fallito" dopo il tempo massimo', () async {
      fakeAsync((tempo) {
        final service = build(gateway: _CatalogoVariabile(blocca: true));
        addTearDown(service.dispose);
        unawaited(service.bootstrap());
        tempo.flushMicrotasks();
        expect(service.catalogState, CatalogState.loading);

        tempo.elapse(EntitlementService.catalogTimeout + const Duration(seconds: 1));
        expect(service.catalogState, CatalogState.failed);
        expect(service.lastError?.code, BillingErrorCodes.timeout);
      });
    });

    test('un errore dello store diventa "fallito", e si puo riprovare', () async {
      final gateway = _CatalogoVariabile(fallisce: true);
      final service = build(gateway: gateway);
      addTearDown(service.dispose);
      await service.bootstrap();
      expect(service.catalogState, CatalogState.failed);

      gateway
        ..fallisce = false
        ..prodotti = [_pro];
      await service.reloadProducts();
      expect(service.catalogState, CatalogState.ready);
    });

    test('se lo store torna, riconnettersi trova il prezzo senza riavviare', () async {
      final gateway = _CatalogoVariabile()
        ..disponibile = false
        ..prodotti = [_pro];
      final service = build(gateway: gateway);
      addTearDown(service.dispose);
      await service.bootstrap();
      expect(service.storeAvailable, isFalse);

      gateway.disponibile = true;
      await service.reconnectStore();

      expect(service.storeAvailable, isTrue);
      expect(service.catalogState, CatalogState.ready);
    });

    test('senza store il catalogo non si chiede nemmeno', () async {
      final service = build(
        gateway: FakePurchaseGateway.withProduct(sku, outcome: FakeOutcome.unavailable),
      );
      addTearDown(service.dispose);
      await service.bootstrap();
      await service.reloadProducts();
      expect(service.catalogState, CatalogState.idle);
    });
  });
}

const MicroProduct _pro = MicroProduct(
  id: sku,
  title: 'Pro',
  description: 'Sblocca tutto',
  formattedPrice: '2,39 €',
  rawPriceMicros: 2390000,
  currencyCode: 'EUR',
);

/// Un gateway il cui catalogo si puo' cambiare durante il test, o bloccare.
class _CatalogoVariabile extends FakePurchaseGateway {
  _CatalogoVariabile({this.blocca = false, this.fallisce = false}) : super(latency: Duration.zero);

  List<MicroProduct> prodotti = const <MicroProduct>[];
  final bool blocca;
  bool fallisce;
  bool disponibile = true;

  @override
  Future<bool> isAvailable() async => disponibile;

  @override
  Future<Result<List<MicroProduct>>> loadProducts(Set<String> productIds) {
    if (blocca) return Completer<Result<List<MicroProduct>>>().future;
    if (fallisce) {
      return Future.value(
        const Err(MicroError(code: BillingErrorCodes.storeError, message: 'store giu')),
      );
    }
    return Future.value(Ok(prodotti.where((p) => productIds.contains(p.id)).toList()));
  }
}

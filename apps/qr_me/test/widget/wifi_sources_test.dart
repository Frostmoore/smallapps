import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_me/app/providers.dart';
import 'package:qr_me/app/routes.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/domain/qr_decoder.dart';
import 'package:qr_me/features/forms/form_page.dart';
import 'package:qr_me/services/wifi_name_reader.dart';

import 'qr_test_harness.dart';

/// F17.10 punto 1: il Wi-Fi senza compilare a mano. Le tre strade (QR inquadrato, immagine, rete
/// connessa con la password incollata) e i messaggi quando non vanno.
void main() {
  late List<Object?> shown;

  /// La fotocamera finta di `/scan/wifi`: un pulsante che torna con [scanned], come fa la
  /// `ScanPage` in modalita' solo Wi-Fi quando legge una rete.
  List<RouteBase> routes({WifiContent? scanned}) => [
    GoRoute(
      path: '/',
      builder: (_, __) => const FormPage(kind: QrKind.wifi),
    ),
    GoRoute(
      path: Routes.scanWifi,
      builder: (context, _) => Scaffold(
        body: TextButton(
          key: const ValueKey('fake_scan_read'),
          onPressed: () => context.pop(scanned),
          child: const Text('LEGGI'),
        ),
      ),
    ),
    captureRoute(Routes.show, shown),
  ];

  setUp(() => shown = []);

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  QrDisplayArgs single() => shown.single! as QrDisplayArgs;

  testWidgets('si parte dalle strade, non dal modulo vuoto', (tester) async {
    await pumpQr(tester, routes: routes(), pro: true);
    for (final k in [
      'wifi_source_scan',
      'wifi_source_image',
      'wifi_source_connected',
      'wifi_manual',
    ]) {
      expect(find.byKey(ValueKey(k)), findsOneWidget, reason: k);
    }
    expect(find.byKey(const ValueKey('form_submit')), findsNothing);
    expect(find.text('Inquadra il QR della rete'), findsOneWidget);
    expect(find.text('La rete a cui sei connesso'), findsOneWidget);
  });

  testWidgets('QR della rete inquadrato → un QR con gli stessi dati, senza modulo', (tester) async {
    const casa = WifiContent(ssid: 'Casa;1', password: 'pa:ss', hidden: true);
    await pumpQr(tester, routes: routes(scanned: casa), pro: true, historyOn: false);
    await tap(tester, 'wifi_source_scan');
    await tap(tester, 'fake_scan_read');
    expect(single().content, casa);
    expect(single().payload, r'WIFI:T:WPA;S:Casa\;1;P:pa\:ss;H:true;;');
  });

  testWidgets('inquadrare e tornare indietro senza leggere non salva niente', (tester) async {
    await pumpQr(tester, routes: routes(), pro: true, historyOn: false);
    await tap(tester, 'wifi_source_scan');
    await tap(tester, 'fake_scan_read'); // torna con null
    expect(shown, isEmpty);
    expect(find.byKey(const ValueKey('wifi_source_scan')), findsOneWidget);
  });

  testWidgets('da un\'immagine: la rete fra piu\' QR si trova e si mostra', (tester) async {
    await pumpQr(
      tester,
      routes: routes(),
      pro: true,
      historyOn: false,
      reader: FakeQrReader(['https://app-del-gestore.it', 'WIFI:S:Ufficio;T:WPA;P:12345678;;']),
      extra: [pickImageProvider.overrideWithValue(() async => '/foto/router.jpg')],
    );
    await tap(tester, 'wifi_source_image');
    expect(single().content, const WifiContent(ssid: 'Ufficio', password: '12345678'));
  });

  testWidgets('un\'immagine con un QR che non e\' una rete: messaggio, nessun salvataggio', (
    tester,
  ) async {
    final h = await pumpQr(
      tester,
      routes: routes(),
      pro: true,
      reader: FakeQrReader(['https://esempio.it']),
      extra: [pickImageProvider.overrideWithValue(() async => '/foto/menu.jpg')],
    );
    await tap(tester, 'wifi_source_image');
    expect(find.text('In questa immagine non c’è il QR di una rete Wi-Fi.'), findsOneWidget);
    expect(shown, isEmpty);
    expect(h.repo.recorded, isEmpty);
  });

  testWidgets('rete connessa: spiegazione, nome letto, password incollata → stringa WIFI giusta', (
    tester,
  ) async {
    final reader = FakeWifiNameReader(const WifiNameLookup.found('AndroidWifi'));
    final clipboard = <String>['segreta 123\n'];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.getData') return {'text': clipboard.single};
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpQr(
      tester,
      routes: routes(),
      pro: true,
      historyOn: false,
      extra: [wifiNameReaderProvider.overrideWithValue(reader)],
    );
    await tap(tester, 'wifi_source_connected');
    // La spiegazione prima del permesso del sistema; senza «Continua» non si chiede niente.
    expect(find.text('Il nome della rete'), findsOneWidget);
    expect(reader.lookups, 0);
    await tap(tester, 'wifi_permission_ok');
    expect(reader.lookups, 1);

    // Il modulo parte con il nome letto, il bottone «Incolla» grande e dove trovare la password.
    final ssid = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('wifi_ssid')),
        matching: find.byType(TextField),
      ),
    );
    expect(ssid.controller!.text, 'AndroidWifi');
    expect(find.byKey(const ValueKey('wifi_pasteHelp')), findsOneWidget);
    await tap(tester, 'wifi_paste');

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('form_submit')),
      200,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    await tap(tester, 'form_submit');
    // ⚑ L'a capo in coda degli appunti si toglie, lo spazio dentro la password resta.
    expect(single().payload, 'WIFI:T:WPA;S:AndroidWifi;P:segreta 123;;');
  });

  testWidgets('permesso gia\' concesso: nessuna spiegazione, si legge subito', (tester) async {
    final reader = FakeWifiNameReader(const WifiNameLookup.found('Casa'), needs: false);
    await pumpQr(
      tester,
      routes: routes(),
      pro: true,
      extra: [wifiNameReaderProvider.overrideWithValue(reader)],
    );
    await tap(tester, 'wifi_source_connected');
    expect(find.text('Il nome della rete'), findsNothing);
    expect(reader.lookups, 1);
    expect(find.byKey(const ValueKey('wifi_paste')), findsOneWidget);
  });

  testWidgets('spiegazione annullata: niente richiesta di permesso', (tester) async {
    final reader = FakeWifiNameReader(const WifiNameLookup.found('Casa'));
    await pumpQr(
      tester,
      routes: routes(),
      pro: true,
      extra: [wifiNameReaderProvider.overrideWithValue(reader)],
    );
    await tap(tester, 'wifi_source_connected');
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(reader.lookups, 0);
    expect(find.byKey(const ValueKey('wifi_source_connected')), findsOneWidget);
  });

  for (final (status, text, settings) in [
    (WifiNameStatus.denied, 'Senza il permesso di posizione', false),
    (WifiNameStatus.deniedForever, 'La posizione è spenta per QR Me', true),
    (WifiNameStatus.locationOff, 'La localizzazione del telefono è spenta', false),
    (WifiNameStatus.unavailable, 'Non riesco a leggere il nome della rete', false),
  ]) {
    testWidgets('nome non letto ($status): messaggio chiaro e ripiego a mano', (tester) async {
      final reader = FakeWifiNameReader(WifiNameLookup(status), needs: false);
      await pumpQr(
        tester,
        routes: routes(),
        pro: true,
        extra: [wifiNameReaderProvider.overrideWithValue(reader)],
      );
      await tap(tester, 'wifi_source_connected');
      expect(find.byKey(const ValueKey('wifi_notice')), findsOneWidget);
      expect(find.textContaining(text), findsOneWidget);
      expect(
        find.byKey(const ValueKey('wifi_notice_settings')),
        settings ? findsOneWidget : findsNothing,
      );
      await tap(tester, 'wifi_notice_manual');
      final ssid = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('wifi_ssid')),
          matching: find.byType(TextField),
        ),
      );
      expect(ssid.controller!.text, isEmpty);
      // A mano niente bottone «Incolla» grande: e' della strada della rete connessa.
      expect(find.byKey(const ValueKey('wifi_paste')), findsNothing);
    });
  }

  testWidgets('«Altri modi» dal modulo torna alle strade', (tester) async {
    await pumpQr(tester, routes: routes(), pro: true);
    await tap(tester, 'wifi_manual');
    expect(find.byKey(const ValueKey('wifi_ssid')), findsOneWidget);
    await tap(tester, 'form_otherWays');
    expect(find.byKey(const ValueKey('wifi_source_scan')), findsOneWidget);
  });

  group('regole pure', () {
    test('cleanSsid toglie le virgolette di Android e scarta i nomi finti', () {
      expect(cleanSsid('"AndroidWifi"'), 'AndroidWifi');
      expect(cleanSsid('Casa'), 'Casa');
      expect(cleanSsid('" Casa "'), ' Casa ', reason: 'gli spazi fanno parte del nome');
      expect(cleanSsid('<unknown ssid>'), isNull);
      expect(cleanSsid('""'), isNull);
      expect(cleanSsid(null), isNull);
    });

    test('QrDecoder.firstWifi: la prima rete fra i QR, null se nessuna', () {
      expect(
        QrDecoder.firstWifi(['ciao', 'WIFI:S:Bar;T:nopass;;', 'WIFI:S:Altro;T:WPA;P:x;;']),
        const WifiContent(ssid: 'Bar', security: WifiSecurity.none),
      );
      expect(QrDecoder.firstWifi(['https://esempio.it', 'tel:123']), isNull);
      expect(QrDecoder.firstWifi(const []), isNull);
      expect(QrDecoder.firstWifi(['WIFI:T:WPA;P:senza-nome;;']), isNull, reason: 'WIFI: rotto');
    });
  });
}

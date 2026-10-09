import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_share/micro_share.dart';
import 'package:qr_me/app/routes.dart';
import 'package:qr_me/data/database.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/services/share_router.dart';

import '../widget/qr_test_harness.dart';

/// F17.1.7, `ShareRouter` e `ShareIntake`: dalla condivisione alla rotta giusta.
void main() {
  late List<Object?> shown;
  late List<Object?> results;
  late GoRouter router;

  Future<void> mount(WidgetTester tester) async {
    shown = [];
    results = [];
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('HOME')),
        ),
        captureRoute(Routes.show, shown),
        captureRoute(Routes.scanResult, results),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('testo → /show con TextContent e source shared', (tester) async {
    await mount(tester);
    final r = ShareRouter(reader: FakeQrReader());
    expect(await r.handle(const SharedText('ciao mondo'), router), ShareOutcome.shownText);
    await tester.pumpAndSettle();
    final args = shown.single! as QrDisplayArgs;
    expect(args.content, const TextContent('ciao mondo'));
    expect(args.payload, 'ciao mondo');
    expect(args.source, QrSource.shared);
  });

  testWidgets('link senza schema → UrlContent con https', (tester) async {
    await mount(tester);
    await ShareRouter(reader: FakeQrReader()).handle(const SharedText('esempio.it'), router);
    await tester.pumpAndSettle();
    final args = shown.single! as QrDisplayArgs;
    expect(args.content, isA<UrlContent>());
    expect(args.payload, 'https://esempio.it');
  });

  testWidgets('immagine con un QR → /scan/result con source image', (tester) async {
    await mount(tester);
    final reader = FakeQrReader(['WIFI:T:WPA;S:Casa;P:x;;']);
    expect(
      await ShareRouter(reader: reader).handle(const SharedImage('/tmp/a.png'), router),
      ShareOutcome.scannedImage,
    );
    await tester.pumpAndSettle();
    final args = results.single! as ScanResultArgs;
    expect(args.raw, 'WIFI:T:WPA;S:Casa;P:x;;');
    expect(args.source, QrSource.image);
    expect(reader.paths, ['/tmp/a.png']);
  });

  testWidgets('immagine senza QR → messaggio, nessuna pagina', (tester) async {
    await mount(tester);
    expect(
      await ShareRouter(reader: FakeQrReader()).handle(const SharedImage('/tmp/b.png'), router),
      ShareOutcome.noQrInImage,
    );
    await tester.pumpAndSettle();
    expect(results, isEmpty);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('scanner assente → readerUnavailable, non "nessun QR"', (tester) async {
    await mount(tester);
    final outcome = await ShareRouter(reader: FakeQrReader(const [], true))
        .handle(const SharedImage('/x.png'), router);
    expect(outcome, ShareOutcome.readerUnavailable);
  });

  testWidgets('lo stesso payload entro 2 s si ignora, dopo 2 s no', (tester) async {
    await mount(tester);
    var now = DateTime.utc(2026, 10, 9, 12);
    final r = ShareRouter(reader: FakeQrReader(), clock: () => now);
    expect(await r.handle(const SharedText('uno'), router), ShareOutcome.shownText);
    now = now.add(const Duration(milliseconds: 1500));
    expect(await r.handle(const SharedText('uno'), router), ShareOutcome.duplicate);
    // Un payload diverso passa subito.
    expect(await r.handle(const SharedText('due'), router), ShareOutcome.shownText);
    now = now.add(const Duration(seconds: 3));
    expect(await r.handle(const SharedText('due'), router), ShareOutcome.shownText);
    await tester.pumpAndSettle();
    expect(shown, hasLength(3));
  });

  testWidgets('piu\' elementi: il primo testo vince sull\'immagine', (tester) async {
    await mount(tester);
    final reader = FakeQrReader(['x']);
    await ShareRouter(reader: reader)
        .handleAll(const [SharedImage('/i.png'), SharedText('testo')], router);
    await tester.pumpAndSettle();
    expect(shown, hasLength(1));
    expect(reader.paths, isEmpty);
  });

  testWidgets('ShareIntake: legge initial, chiama reset subito, poi ascolta incoming', (
    tester,
  ) async {
    await mount(tester);
    final inbox = FakeShareInbox(initial: const [SharedText('dall\'avvio')]);
    addTearDown(inbox.close);
    final outcomes = <ShareOutcome>[];
    final intake = ShareIntake(
      inbox: inbox,
      router: ShareRouter(reader: FakeQrReader()),
      goRouter: router,
      onOutcome: outcomes.add,
    );
    addTearDown(intake.dispose);
    await intake.start();
    await tester.pumpAndSettle();
    expect(inbox.initialCount, 1);
    expect(inbox.resetCount, 1);
    expect((shown.single! as QrDisplayArgs).payload, 'dall\'avvio');

    // ☠ Trappola 5: lo stesso elemento riconsegnato da incoming subito dopo si ignora.
    inbox.push(const [SharedText('dall\'avvio')]);
    await tester.pumpAndSettle();
    expect(shown, hasLength(1));
    expect(outcomes.last, ShareOutcome.duplicate);

    inbox.push(const [SharedText('nuovo')]);
    await tester.pumpAndSettle();
    expect(shown, hasLength(2));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_me/app/routes.dart';
import 'package:qr_me/data/database.dart';
import 'package:qr_me/domain/qr_style.dart';
import 'package:qr_me/features/scan/scan_result_page.dart';

import 'qr_test_harness.dart';

/// F17.1.6, `ScanResultPage`: «Rigenera con stile» non perde lo stile scelto.
///
/// ☠ Difetto trovato rileggendo l'atlante (F17.8): lo stile restituito da `/style` era ignorato.
/// Con la cronologia spenta andava perso; con la cronologia accesa «Mostra come QR» e «Salva»
/// ripartivano dal QR semplice.
void main() {
  const scelto = QrStyle(foreground: 0xFF123456);

  /// La pagina dello stile finta: «Applica» restituisce [scelto], come fa `StylePage`.
  GoRoute fakeStyle(List<Object?> sink) => GoRoute(
    path: Routes.style,
    builder: (context, s) {
      if (!sink.any((e) => identical(e, s.extra))) sink.add(s.extra);
      return Scaffold(
        body: TextButton(
          key: const ValueKey('fake_apply'),
          onPressed: () => context.pop(scelto),
          child: const Text('Applica'),
        ),
      );
    },
  );

  List<RouteBase> routes(List<Object?> shown, List<Object?> styled) => [
    GoRoute(
      path: Routes.home,
      builder: (_, __) => const ScanResultPage(
        args: ScanResultArgs(raw: 'ciao dal QR', source: QrSource.scanned),
      ),
    ),
    fakeStyle(styled),
    captureRoute(Routes.show, shown),
  ];

  for (final historyOn in [false, true]) {
    testWidgets(
      'cronologia ${historyOn ? 'accesa' : 'spenta'}: dopo «Applica» si apre /show con lo stile',
      (tester) async {
        final shown = <Object?>[];
        final styled = <Object?>[];
        final h = await pumpQr(
          tester,
          routes: routes(shown, styled),
          pro: true,
          historyOn: historyOn,
        );

        await tester.tap(find.byKey(const ValueKey('result_style')));
        await tester.pumpAndSettle();
        expect((styled.single! as StyleArgs).display.style, QrStyle.plain);
        await tester.tap(find.byKey(const ValueKey('fake_apply')));
        await tester.pumpAndSettle();

        final args = shown.single! as QrDisplayArgs;
        expect(args.style, scelto);
        expect(args.payload, 'ciao dal QR');
        expect(args.qrId, historyOn ? isNotNull : isNull);

        // Tornati al risultato, «Mostra come QR» riparte dallo stile scelto, non dal semplice.
        h.router!.pop();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('result_show')));
        await tester.pumpAndSettle();
        expect((shown.last! as QrDisplayArgs).style, scelto);
      },
    );
  }

  testWidgets('cronologia spenta: «Salva» dopo lo stile scrive la riga con lo stile', (
    tester,
  ) async {
    final shown = <Object?>[];
    final h = await pumpQr(tester, routes: routes(shown, []), pro: true, historyOn: false);
    await tester.tap(find.byKey(const ValueKey('result_style')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fake_apply')));
    await tester.pumpAndSettle();
    h.router!.pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('result_save')));
    await tester.tap(find.byKey(const ValueKey('result_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('title_ok')));
    await tester.pumpAndSettle();

    expect(h.repo.recorded.single.style, scelto);
    expect(h.repo.favorited, hasLength(1));
  });
}

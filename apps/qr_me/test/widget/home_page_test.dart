import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';
import 'package:qr_me/app/routes.dart';
import 'package:qr_me/data/database.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/features/home/home_page.dart';

import 'qr_test_harness.dart';

/// F17.1.6, `HomePage`.
void main() {
  late List<Object?> shown;

  List<RouteBase> routes() => [
    GoRoute(path: Routes.home, builder: (_, __) => const HomePage()),
    captureRoute(Routes.show, shown),
    GoRoute(
      path: Routes.qr,
      builder: (_, s) => Scaffold(body: Text('QR ${s.pathParameters['id']}')),
    ),
    captureRoute(Routes.history, []),
  ];

  setUp(() => shown = []);

  /// Gli appunti finti: `Clipboard.getData` risponde [text].
  void clipboard(WidgetTester tester, String? text) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.getData') return text == null ? null : {'text': text};
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  testWidgets('incolla un link senza schema → Mostra QR apre /show con il link https', (
    tester,
  ) async {
    await pumpQr(tester, routes: routes());
    clipboard(tester, 'esempio.it/menu');
    await tester.tap(find.byKey(const ValueKey('home_paste')));
    await tester.pumpAndSettle();
    expect(find.text('esempio.it/menu'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home_show')));
    await tester.pumpAndSettle();
    final args = shown.single! as QrDisplayArgs;
    expect(args.content, isA<UrlContent>());
    expect(args.payload, 'https://esempio.it/menu');
    expect(args.source, QrSource.typed);
  });

  testWidgets('un testo resta testo, identico', (tester) async {
    await pumpQr(tester, routes: routes());
    await tester.enterText(find.byKey(const ValueKey('home_text')), 'ciao a tutti ');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home_show')));
    await tester.pumpAndSettle();
    final args = shown.single! as QrDisplayArgs;
    expect(args.content, const TextContent('ciao a tutti '));
  });

  testWidgets('Mostra QR e\' spento con il campo vuoto', (tester) async {
    await pumpQr(tester, routes: routes());
    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('home_show')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('recenti: al massimo 5 righe, e la riga della cronologia gratuita', (tester) async {
    await pumpQr(
      tester,
      routes: routes(),
      rows: [
        for (var i = 1; i <= 6; i++)
          qrRow(i, content: TextContent('testo $i'), payload: 'testo $i', lastUsedAt: i),
      ],
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home_freeHistory')),
      200,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    expect(find.text('testo 6'), findsOneWidget);
    expect(find.text('testo 2'), findsOneWidget);
    expect(find.text('testo 1'), findsNothing);
    expect(find.textContaining('ultimi 5 QR'), findsOneWidget);
  });

  testWidgets('col Pro la riga della cronologia gratuita sparisce', (tester) async {
    await pumpQr(
      tester,
      routes: routes(),
      pro: true,
      rows: [qrRow(1, content: const TextContent('uno'), payload: 'uno')],
    );
    expect(find.byKey(const ValueKey('home_freeHistory')), findsNothing);
  });

  testWidgets('moduli: Wi-Fi, Contatto, Email precompilata; niente SMS e Telefono (F17.10)', (
    tester,
  ) async {
    await pumpQr(tester, routes: routes());
    expect(find.byKey(const ValueKey('form_chip_wifi')), findsOneWidget);
    expect(find.byKey(const ValueKey('form_chip_contact')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('form_chip_email')),
        matching: find.text('Email precompilata'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('form_chip_sms')), findsNothing);
    expect(find.byKey(const ValueKey('form_chip_phone')), findsNothing);
  });

  testWidgets('i moduli hanno il badge PRO senza il Pro', (tester) async {
    await pumpQr(tester, routes: routes());
    for (final k in kFormKinds) {
      final chip = find.byKey(ValueKey('form_chip_${k.name}'));
      expect(chip, findsOneWidget);
      expect(
        find.descendant(of: chip, matching: find.byType(ProBadge)),
        findsOneWidget,
        reason: k.name,
      );
    }
  });

  testWidgets('col Pro i moduli non hanno badge', (tester) async {
    await pumpQr(tester, routes: routes(), pro: true);
    expect(find.byType(ProBadge), findsNothing);
  });

  testWidgets('un modulo toccato senza Pro apre il paywall', (tester) async {
    await pumpQr(tester, routes: routes());
    await tester.tap(find.byKey(const ValueKey('form_chip_wifi')));
    await tester.pumpAndSettle();
    expect(find.text('QR Me Pro'), findsWidgets);
  });

  testWidgets('senza nulla salvato la home spiega la condivisione', (tester) async {
    await pumpQr(tester, routes: routes());
    expect(find.byKey(const ValueKey('home_empty')), findsOneWidget);
    expect(find.textContaining('scegli QR Me'), findsOneWidget);
  });
}

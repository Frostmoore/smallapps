import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_me/app/routes.dart';
import 'package:qr_me/data/database.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/features/forms/form_page.dart';

import 'qr_test_harness.dart';

/// F17.1.6, `FormPage`: i moduli producono la stringa giusta.
void main() {
  late List<Object?> shown;

  List<RouteBase> routes(QrKind kind) => [
    GoRoute(
      path: '/',
      builder: (_, __) => FormPage(kind: kind),
    ),
    captureRoute(Routes.show, shown),
    GoRoute(
      path: Routes.qr,
      builder: (_, s) => Scaffold(body: Text('QR ${s.pathParameters['id']}')),
    ),
  ];

  setUp(() => shown = []);

  Future<void> submit(WidgetTester tester) async {
    // ⚑ Lo Scrollable della pagina, non quelli dei campi di testo (anche loro scorrono).
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('form_submit')),
      200,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('form_submit')));
    await tester.pumpAndSettle();
  }

  testWidgets('Wi-Fi con caratteri speciali: la stringa WIFI: ha gli escape', (tester) async {
    await pumpQr(tester, routes: routes(QrKind.wifi), pro: true, historyOn: false);
    expect(find.byKey(const ValueKey('form_preview_empty')), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('wifi_ssid')),
        matching: find.byType(TextField),
      ),
      'Casa;1',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('wifi_password')),
        matching: find.byType(TextField),
      ),
      r'pa:ss"\',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('form_preview')), findsOneWidget);

    await submit(tester);
    final args = shown.single! as QrDisplayArgs;
    expect(args.payload, r'WIFI:T:WPA;S:Casa\;1;P:pa\:ss\"\\;;');
    expect(args.source, QrSource.form);
  });

  testWidgets('rete aperta: niente password, niente P:', (tester) async {
    await pumpQr(tester, routes: routes(QrKind.wifi), pro: true, historyOn: false);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('wifi_ssid')),
        matching: find.byType(TextField),
      ),
      'Bar',
    );
    await tester.tap(find.text('Nessuna'));
    await tester.pump();
    expect(find.byKey(const ValueKey('wifi_password')), findsNothing);
    await submit(tester);
    expect((shown.single! as QrDisplayArgs).payload, 'WIFI:T:nopass;S:Bar;;');
  });

  testWidgets('senza SSID il pulsante resta spento e il campo dice "Obbligatorio"', (tester) async {
    await pumpQr(tester, routes: routes(QrKind.wifi), pro: true);
    final ssid = find.descendant(
      of: find.byKey(const ValueKey('wifi_ssid')),
      matching: find.byType(TextField),
    );
    await tester.enterText(ssid, 'x');
    await tester.enterText(ssid, '');
    await tester.pump();
    expect(find.text('Obbligatorio'), findsWidgets);
    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('form_submit')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('cronologia accesa: registra con source form e apre /qr/:id', (tester) async {
    final h = await pumpQr(tester, routes: routes(QrKind.phone), pro: true);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('phone_number')),
        matching: find.byType(TextField),
      ),
      '+39 333 123 4567',
    );
    await tester.pump();
    await submit(tester);
    expect(h.repo.recorded.single.payload, 'tel:+393331234567');
    expect(h.repo.recorded.single.source, QrSource.form);
    expect(find.text('QR 100'), findsOneWidget);
  });
}

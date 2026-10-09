import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_me/app/app.dart' show formKindOf;
import 'package:qr_me/app/routes.dart';
import 'package:qr_me/data/database.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/domain/qr_decoder.dart';
import 'package:qr_me/features/forms/email_form.dart';
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

  /// Wi-Fi nuovo: si parte dalle strade (F17.10); «Inserisci a mano» apre il modulo vuoto.
  Future<void> manual(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('wifi_manual')));
    await tester.pumpAndSettle();
  }

  testWidgets('Wi-Fi con caratteri speciali: la stringa WIFI: ha gli escape', (tester) async {
    await pumpQr(tester, routes: routes(QrKind.wifi), pro: true, historyOn: false);
    await manual(tester);
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
    await manual(tester);
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
    await manual(tester);
    final ssid = find.descendant(
      of: find.byKey(const ValueKey('wifi_ssid')),
      matching: find.byType(TextField),
    );
    await tester.enterText(ssid, 'x');
    await tester.enterText(ssid, '');
    await tester.pump();
    expect(find.text('Obbligatorio'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('form_submit')),
      200,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('form_submit')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('cronologia accesa: registra con source form e apre /qr/:id', (tester) async {
    final h = await pumpQr(tester, routes: routes(QrKind.email), pro: true);
    await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('email_to')), matching: find.byType(TextField)),
      'info@esempio.it',
    );
    await tester.pump();
    await submit(tester);
    expect(h.repo.recorded.single.payload, 'mailto:info@esempio.it');
    expect(h.repo.recorded.single.source, QrSource.form);
    expect(find.text('QR 100'), findsOneWidget);
  });

  group('Email precompilata (F17.10 punto 3)', () {
    testWidgets('titolo «Email precompilata» e testo grande: almeno 6 righe, senza tetto', (
      tester,
    ) async {
      await pumpQr(tester, routes: routes(QrKind.email), pro: true);
      expect(find.text('Email precompilata'), findsOneWidget);
      final body = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('email_body')),
          matching: find.byType(TextField),
        ),
      );
      expect(body.minLines, kEmailBodyMinLines);
      expect(kEmailBodyMinLines, greaterThanOrEqualTo(6));
      expect(body.maxLines, isNull, reason: 'il campo cresce con il testo');
    });

    testWidgets('un testo lungo e su piu\' righe entra tutto nel mailto:', (tester) async {
      await pumpQr(tester, routes: routes(QrKind.email), pro: true, historyOn: false);
      final lungo = List.generate(
        12,
        (i) => 'Riga $i: ciao, ecco i dettagli dell\'ordine.',
      ).join('\n');
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('email_to')),
          matching: find.byType(TextField),
        ),
        'ordini@esempio.it',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('email_subject')),
          matching: find.byType(TextField),
        ),
        'Ordine',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('email_body')),
          matching: find.byType(TextField),
        ),
        lungo,
      );
      await tester.pump();
      await submit(tester);
      final args = shown.single! as QrDisplayArgs;
      expect(args.content, EmailContent(to: 'ordini@esempio.it', subject: 'Ordine', body: lungo));
      expect(QrDecoder.decode(args.payload), args.content, reason: 'round-trip del mailto:');
    });
  });

  group('SMS e Telefono tolti (F17.10 punto 4)', () {
    test('niente moduli SMS e Telefono, restano Wi-Fi, Contatto ed Email', () {
      expect(kFormKinds, [QrKind.wifi, QrKind.contact, QrKind.email]);
    });

    test('/form/sms e /form/phone non hanno un modulo («Non trovato»)', () {
      expect(formKindOf('sms'), isNull);
      expect(formKindOf('phone'), isNull);
      expect(formKindOf('wifi'), QrKind.wifi);
      expect(formKindOf('email'), QrKind.email);
    });

    test('la lettura resta: SMSTO: e tel: si riconoscono ancora', () {
      expect(QrDecoder.decode('SMSTO:+393331234567:Ciao'), isA<SmsContent>());
      expect(QrDecoder.decode('tel:+393331234567'), isA<PhoneContent>());
    });
  });
}

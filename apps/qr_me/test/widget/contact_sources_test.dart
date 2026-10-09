import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_me/app/providers.dart';
import 'package:qr_me/app/routes.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/features/forms/form_page.dart';
import 'package:qr_me/features/forms/my_contact_page.dart';
import 'package:qr_me/services/contact_picker.dart';

import 'qr_test_harness.dart';

/// F17.10 punto 2: il Contatto dalla rubrica (selettore di sistema, nessun permesso) o «Io».
void main() {
  late List<Object?> shown;

  List<RouteBase> routes() => [
    GoRoute(
      path: '/',
      builder: (_, __) => const FormPage(kind: QrKind.contact),
    ),
    GoRoute(path: Routes.myContact, builder: (_, __) => const MyContactPage()),
    captureRoute(Routes.show, shown),
  ];

  setUp(() => shown = []);

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('form_submit')),
      200,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    await tap(tester, 'form_submit');
  }

  String field(WidgetTester tester, String key) => tester
      .widget<TextField>(
        find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField)),
      )
      .controller!
      .text;

  QrDisplayArgs single() => shown.single! as QrDisplayArgs;

  const mario = ContactContent(name: 'Mario Rossi', phone: '+39 333 123 4567');

  testWidgets('dalla rubrica: il modulo si apre compilato e diventa una vCard', (tester) async {
    final picker = FakeContactPicker(mario);
    await pumpQr(
      tester,
      routes: routes(),
      pro: true,
      historyOn: false,
      extra: [contactPickerProvider.overrideWithValue(picker)],
    );
    expect(
      find.byKey(const ValueKey('form_submit')),
      findsNothing,
      reason: 'si parte dalle strade',
    );
    await tap(tester, 'contact_source_pick');
    expect(picker.picks, 1);
    expect(field(tester, 'contact_name'), 'Mario Rossi');
    expect(field(tester, 'contact_phone'), '+39 333 123 4567');

    // L'email il selettore non la da': la si aggiunge qui, nel modulo gia' compilato.
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('contact_email')),
        matching: find.byType(TextField),
      ),
      'mario@esempio.it',
    );
    await tester.pump();
    await submit(tester);
    final payload = single().payload;
    expect(payload, startsWith('BEGIN:VCARD'));
    expect(payload, contains('FN:Mario Rossi'));
    expect(payload, contains('TEL:+393331234567'));
    expect(payload, contains('EMAIL:mario@esempio.it'));
  });

  testWidgets('rubrica annullata: si resta sulle strade', (tester) async {
    await pumpQr(
      tester,
      routes: routes(),
      pro: true,
      extra: [contactPickerProvider.overrideWithValue(FakeContactPicker(null))],
    );
    await tap(tester, 'contact_source_pick');
    expect(find.byKey(const ValueKey('contact_source_pick')), findsOneWidget);
    expect(find.byKey(const ValueKey('contact_name')), findsNothing);
  });

  testWidgets('rubrica che non si apre: lo dice', (tester) async {
    await pumpQr(
      tester,
      routes: routes(),
      pro: true,
      extra: [contactPickerProvider.overrideWithValue(FakeContactPicker(null, fails: true))],
    );
    await tap(tester, 'contact_source_pick');
    expect(find.text('Non riesco ad aprire la rubrica.'), findsOneWidget);
  });

  testWidgets('«Io» salvato: il QR esce subito, senza modulo', (tester) async {
    await pumpQr(
      tester,
      routes: routes(),
      pro: true,
      historyOn: false,
      settingsValues: {
        QrSettingKeys.myContact: jsonEncode(
          const ContactContent(name: 'Anna Bianchi', email: 'anna@esempio.it').toFields(),
        ),
      },
    );
    expect(find.text('Anna Bianchi: la tua scheda, pronta'), findsOneWidget);
    await tap(tester, 'contact_source_me');
    expect(single().content, const ContactContent(name: 'Anna Bianchi', email: 'anna@esempio.it'));
  });

  testWidgets('«Io» la prima volta: la si sceglie dalla rubrica, si salva e si riusa', (
    tester,
  ) async {
    final h = await pumpQr(
      tester,
      routes: routes(),
      pro: true,
      historyOn: false,
      extra: [contactPickerProvider.overrideWithValue(FakeContactPicker(mario))],
    );
    expect(
      find.text('La tua scheda: la scegli o la compili una volta, poi è sempre pronta'),
      findsOneWidget,
    );
    await tap(tester, 'contact_source_me');
    // La pagina della scheda: scelta dalla rubrica, poi «Salva».
    expect(find.text('La mia scheda'), findsOneWidget);
    await tap(tester, 'me_pick');
    expect(field(tester, 'contact_name'), 'Mario Rossi');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('me_save')),
      200,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    await tap(tester, 'me_save');

    // Tornati al modulo, il QR e' gia' uscito con la scheda appena salvata...
    expect(single().content, mario);
    // ...e la scheda e' nelle preferenze, per la prossima volta.
    final saved =
        jsonDecode(h.settings.getString(QrSettingKeys.myContact)!) as Map<String, Object?>;
    expect(QrContent.fromFields(QrKind.contact, saved), mario);
  });

  testWidgets('«Io» si elimina dalla sua pagina', (tester) async {
    final h = await pumpQr(
      tester,
      routes: [GoRoute(path: '/', builder: (_, __) => const MyContactPage())],
      pro: true,
      settingsValues: {
        QrSettingKeys.myContact: jsonEncode(const ContactContent(name: 'Anna').toFields()),
      },
    );
    expect(field(tester, 'contact_name'), 'Anna');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('me_delete')),
      200,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    await tap(tester, 'me_delete');
    await tester.tap(find.text('Elimina').last);
    await tester.pumpAndSettle();
    expect(h.settings.getString(QrSettingKeys.myContact), isNull);
  });

  group('contactFromPicked', () {
    test('nome e primo telefono non vuoto', () {
      expect(
        contactFromPicked(fullName: ' Mario Rossi ', phones: ['', '333 1']),
        const ContactContent(name: 'Mario Rossi', phone: '333 1'),
      );
    });

    test('il numero scelto vince sull\'elenco', () {
      expect(contactFromPicked(fullName: 'M', phones: ['1', '2'], selected: '2')!.phone, '2');
    });

    test('niente nome e niente numero: niente contatto', () {
      expect(contactFromPicked(fullName: '', phones: const []), isNull);
      expect(contactFromPicked(), isNull);
    });

    test('senza nome il nome resta vuoto (lo chiede il modulo)', () {
      expect(contactFromPicked(phones: ['123'])!.name, isEmpty);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_me/app/routes.dart';
import 'package:qr_me/data/database.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/domain/qr_encoder.dart';
import 'package:qr_me/features/display/qr_display_page.dart';

import 'qr_test_harness.dart';

/// F17.1.6, `QrDisplayPage`: IL motivo dell'app.
void main() {
  const wifi = WifiContent(ssid: 'Casa', password: 'segreta123');
  final wifiArgs = QrDisplayArgs(
    content: wifi,
    payload: QrEncoder.encode(wifi),
    source: QrSource.typed,
  );

  testWidgets('la password del Wi-Fi e\' nascosta finche\' non si tocca l\'occhio', (tester) async {
    await pumpQr(tester, page: QrDisplayPage.args(wifiArgs));
    expect(find.textContaining('segreta123'), findsNothing);
    expect(find.textContaining('••••••••'), findsOneWidget);
    expect(find.textContaining('Rete: Casa'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toggle_password')));
    await tester.pump();
    expect(find.textContaining('segreta123'), findsOneWidget);
  });

  testWidgets('senza Pro: Stile e Immagine col lucchetto, Salva e Copia no', (tester) async {
    await pumpQr(tester, page: QrDisplayPage.args(wifiArgs));
    Finder lockIn(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byKey(const ValueKey('lock')),
    );
    expect(lockIn('action_style'), findsOneWidget);
    expect(lockIn('action_image'), findsOneWidget);
    expect(lockIn('action_save'), findsNothing);
    expect(lockIn('action_copy'), findsNothing);
  });

  testWidgets('col Pro nessun lucchetto', (tester) async {
    await pumpQr(tester, page: QrDisplayPage.args(wifiArgs), pro: true);
    expect(find.byKey(const ValueKey('lock')), findsNothing);
  });

  testWidgets(
    'luminosita\' al massimo all\'apertura, ripristinata in pausa e riaccesa al ritorno',
    (tester) async {
      final h = await pumpQr(tester, page: QrDisplayPage.args(wifiArgs));
      expect(h.boost.enabled, 1);
      expect(h.boost.on, isTrue);

      // ☠ Il tasto Home: senza il ripristino in pausa il telefono resterebbe a luminosita' piena.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(h.boost.on, isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(h.boost.on, isTrue);

      // Uscendo dalla pagina si ripristina sempre.
      await tester.pumpWidget(const SizedBox());
      expect(h.boost.on, isFalse);
    },
  );

  testWidgets('cronologia accesa: registra il QR e pota a 5 nel piano gratuito', (tester) async {
    final h = await pumpQr(tester, page: QrDisplayPage.args(wifiArgs));
    expect(h.repo.recorded.single.payload, wifiArgs.payload);
    expect(h.repo.recorded.single.source, QrSource.typed);
    expect(h.repo.pruneCalls, [5]);
  });

  testWidgets('col Pro la cronologia non si pota', (tester) async {
    final h = await pumpQr(tester, page: QrDisplayPage.args(wifiArgs), pro: true);
    expect(h.repo.pruneCalls, [null]);
  });

  testWidgets('cronologia spenta: il QR si mostra e non si scrive niente', (tester) async {
    final h = await pumpQr(tester, page: QrDisplayPage.args(wifiArgs), historyOn: false);
    expect(find.byKey(const ValueKey('qr_panel')), findsOneWidget);
    expect(h.repo.recorded, isEmpty);
    expect(h.repo.pruneCalls, isEmpty);
  });

  testWidgets('un QR salvato si apre per id e si "tocca" invece di registrarlo di nuovo', (
    tester,
  ) async {
    final h = await pumpQr(
      tester,
      page: const QrDisplayPage.saved(7),
      rows: [
        qrRow(
          7,
          content: wifi,
          payload: QrEncoder.encode(wifi),
          favorite: true,
          title: 'Wi-Fi di casa',
        ),
      ],
    );
    expect(find.text('Wi-Fi di casa'), findsOneWidget);
    expect(h.repo.touched, [7]);
    expect(h.repo.recorded, isEmpty);
    // Preferito con modulo: c'e' anche «Modifica».
    expect(find.byKey(const ValueKey('action_edit')), findsOneWidget);
  });

  testWidgets('un id che non esiste dice "non esiste piu\'"', (tester) async {
    await pumpQr(tester, page: const QrDisplayPage.saved(99));
    expect(find.text('Questo QR non esiste più.'), findsOneWidget);
  });

  testWidgets('salvare il secondo preferito senza Pro apre il paywall, non il nome', (
    tester,
  ) async {
    final h = await pumpQr(
      tester,
      page: QrDisplayPage.args(wifiArgs),
      rows: [qrRow(1, content: const TextContent('ciao'), payload: 'ciao', favorite: true)],
    );
    await tester.tap(find.byKey(const ValueKey('action_save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('title_field')), findsNothing);
    expect(find.text('QR Me Pro'), findsWidgets);
    expect(h.repo.favorited, isEmpty);
  });

  testWidgets('il primo preferito si salva con il nome scelto', (tester) async {
    final h = await pumpQr(tester, page: QrDisplayPage.args(wifiArgs));
    await tester.tap(find.byKey(const ValueKey('action_save')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('title_field')), 'Wi-Fi ospiti');
    await tester.tap(find.byKey(const ValueKey('title_ok')));
    await tester.pumpAndSettle();
    expect(h.repo.favorited.single.$2, 'Wi-Fi ospiti');
  });

  testWidgets('un testo troppo lungo per un QR lo dice invece di lanciare', (tester) async {
    final long = 'x' * 3000;
    await pumpQr(
      tester,
      page: QrDisplayPage.args(
        QrDisplayArgs(content: TextContent(long), payload: long, source: QrSource.shared),
      ),
    );
    expect(find.text('Troppo lungo per un QR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('SMS e Telefono senza modulo (F17.10 punto 4)', () {
    for (final (content, payload) in [
      (const SmsContent(number: '+393331234567', body: 'Ciao'), 'SMSTO:+393331234567:Ciao'),
      (const PhoneContent('+393331234567'), 'tel:+393331234567'),
    ]) {
      testWidgets('un preferito ${content.kind.name} gia\' salvato si mostra, senza «Modifica»', (
        tester,
      ) async {
        await pumpQr(
          tester,
          page: const QrDisplayPage.saved(7),
          pro: true,
          rows: [qrRow(7, content: content, payload: payload, favorite: true, title: 'Vecchio')],
        );
        expect(find.byKey(const ValueKey('qr_panel')), findsOneWidget);
        expect(find.text('Vecchio'), findsOneWidget);
        expect(find.byKey(const ValueKey('action_edit')), findsNothing);
      });
    }

    testWidgets('un preferito Wi-Fi invece ha ancora «Modifica»', (tester) async {
      await pumpQr(
        tester,
        page: const QrDisplayPage.saved(8),
        pro: true,
        rows: [qrRow(8, content: wifi, payload: wifiArgs.payload, favorite: true)],
      );
      expect(find.byKey(const ValueKey('action_edit')), findsOneWidget);
    });
  });
}

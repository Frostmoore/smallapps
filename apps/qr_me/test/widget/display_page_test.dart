import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_me/app/qr_palette.dart';
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

  group('«Etichetta» nella barra e titolo al 130% (correzione di F17.10)', () {
    // ⚑ Il font vero dei titoli: con il font dei test (ogni glifo largo 1 em) qualunque titolo
    // sembrerebbe troncato, e il test non direbbe niente sulla barra vera.
    setUpAll(() async {
      final bytes = File('assets/fonts/SpaceGrotesk-Variable.ttf').readAsBytesSync();
      final loader = FontLoader(kTitleFont)
        ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
      await loader.load();
    });

    /// Un telefono medio (412 dp, il Medium Phone dell'emulatore) con il testo al 130%.
    void phoneAt130(WidgetTester tester) {
      tester.view
        ..physicalSize = const Size(412 * 3, 915 * 3)
        ..devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    for (final (content, title) in [
      (const EmailContent(to: 'mario@esempio.it', subject: 'Ciao'), 'Email precompilata'),
      (const ContactContent(name: 'Mario Rossi', phone: '+39 333 123 4567'), 'Contatto'),
      (wifi, 'Wi-Fi'),
    ]) {
      for (final pro in [false, true]) {
        testWidgets('«$title» non si tronca al 130% (${pro ? 'Pro' : 'gratis'})', (tester) async {
          phoneAt130(tester);
          await pumpQr(
            tester,
            pro: pro,
            page: QrDisplayPage.args(
              QrDisplayArgs(
                content: content,
                payload: QrEncoder.encode(content),
                source: QrSource.typed,
              ),
            ),
          );
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: find.byType(AppBar), matching: find.text(title)),
          );
          // Troncato = il testo intero vorrebbe piu' spazio di quello che la barra gli da'.
          expect(
            paragraph.getMaxIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(paragraph.size.width + 0.5),
          );
        });
      }
    }

    testWidgets('e\' un IconButton con tooltip e nome per i lettori di schermo', (tester) async {
      await pumpQr(tester, page: QrDisplayPage.args(wifiArgs));
      final button = tester.widget<IconButton>(find.byKey(const ValueKey('action_label')));
      expect(button.tooltip, 'Etichetta');
      expect(find.bySemanticsLabel(RegExp('Etichetta')), findsWidgets);
    });

    testWidgets('senza Pro il lucchetto sulla stampante, col Pro no', (tester) async {
      await pumpQr(tester, page: QrDisplayPage.args(wifiArgs));
      Finder lock() => find.descendant(
        of: find.byKey(const ValueKey('action_label')),
        matching: find.byKey(const ValueKey('lock')),
      );
      expect(lock(), findsOneWidget);
      await pumpQr(tester, page: QrDisplayPage.args(wifiArgs), pro: true);
      expect(lock(), findsNothing);
    });
  });
}

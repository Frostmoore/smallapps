import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:micro_core/micro_core.dart';
import 'package:pdf/pdf.dart';
import 'package:qr_me/app/paywall_config.dart';
import 'package:qr_me/app/providers.dart';
import 'package:qr_me/app/routes.dart';
import 'package:qr_me/data/database.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/domain/qr_encoder.dart';
import 'package:qr_me/domain/qr_style.dart';
import 'package:qr_me/features/common/pro_gate.dart';
import 'package:qr_me/features/display/qr_display_page.dart';
import 'package:qr_me/features/label/label_page.dart';
import 'package:qr_me/l10n/generated/app_localizations.dart';
import 'package:qr_me/services/label_renderer.dart';

import 'qr_test_harness.dart';

/// F17.10 punto 5: «Genera etichetta» (Pro, `imageExport`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const wifi = WifiContent(ssid: 'Casa', password: 'segreta123');
  final args = QrDisplayArgs(content: wifi, payload: QrEncoder.encode(wifi), source: QrSource.form);

  /// Quanti pixel "di inchiostro" (scuri) ci sono nella fascia [top, bottom) dell'immagine.
  int inkBetween(img.Image image, double top, double bottom) {
    var ink = 0;
    for (var y = (image.height * top).floor(); y < (image.height * bottom).floor(); y++) {
      for (var x = 0; x < image.width; x += 2) {
        if (image.getPixel(x, y).luminance < 100) ink++;
      }
    }
    return ink;
  }

  group('LabelRenderer', () {
    const renderer = LabelRenderer();

    test('PNG quadrato 1200×1200, rettangolare 1200×1800', () async {
      for (final (format, h) in [(LabelFormat.square, 1200), (LabelFormat.tall, 1800)]) {
        final png = await renderer.png(
          payload: args.payload,
          style: QrStyle.plain,
          text: 'Wi-Fi di casa',
          format: format,
        );
        final image = img.decodePng(png)!;
        expect((image.width, image.height), (1200, h), reason: '$format');
      }
    });

    test('il testo c\'e\': sotto il QR c\'e\' inchiostro, senza testo no', () async {
      Future<img.Image> render(String text) async => img.decodePng(
        await renderer.png(
          payload: args.payload,
          style: QrStyle.plain,
          text: text,
          format: LabelFormat.square,
        ),
      )!;
      final withText = await render('Wi-Fi di casa');
      final empty = await render('   ');
      // La fascia del testo nella quadrata: l'ultimo 20% meno il margine.
      expect(inkBetween(withText, 0.78, 0.94), greaterThan(500));
      // Senza testo il QR si centra e si allarga: in fondo resta solo il margine bianco.
      expect(inkBetween(empty, 0.97, 1.0), 0);
    });

    test('il testo prende il colore del QR (stile applicato)', () async {
      const red = QrStyle(foreground: 0xFFB00020, background: 0xFFFFFFFF);
      final image = img.decodePng(
        await renderer.png(
          payload: args.payload,
          style: red,
          text: 'ROSSO',
          format: LabelFormat.square,
        ),
      )!;
      var reddish = 0;
      for (var y = (image.height * 0.8).floor(); y < (image.height * 0.94).floor(); y++) {
        for (var x = 0; x < image.width; x += 3) {
          final p = image.getPixel(x, y);
          if (p.r > 140 && p.g < 80 && p.b < 80) reddish++;
        }
      }
      expect(reddish, greaterThan(200));
    });

    test('layout: il QR sta dentro la tela e sopra il testo', () {
      for (final size in [const Size(1200, 1200), const Size(1200, 1800)]) {
        final l = LabelPainter.layout(size, hasText: true);
        expect(l.qr.left, greaterThanOrEqualTo(0));
        expect(l.qr.right, lessThanOrEqualTo(size.width));
        expect(l.qr.width, l.qr.height);
        expect(l.text.top, greaterThanOrEqualTo(l.qr.bottom));
        expect(l.text.bottom, lessThanOrEqualTo(size.height));
      }
    });

    test('il PDF e\' un PDF, con l\'etichetta alla misura vera', () async {
      final png = await renderer.png(
        payload: args.payload,
        style: QrStyle.plain,
        text: 'x',
        format: LabelFormat.square,
      );
      final pdf = await renderer.pdf(png: png, format: LabelFormat.square, page: PdfPageFormat.a4);
      expect(ascii.decode(pdf.sublist(0, 5)), '%PDF-');
    });
  });

  group('LabelPage', () {
    /// ⚑ La ListView costruisce solo cio' che e' vicino allo schermo: i pulsanti in fondo vanno
    /// portati in vista prima di cercarli.
    Future<void> reveal(WidgetTester tester, String key) => tester.scrollUntilVisible(
      find.byKey(ValueKey(key)),
      200,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );

    /// ⚑ Il PNG e' lavoro vero del motore (`toImage`), ma la catena che lo chiede passa anche da
    /// Riverpod e dai microtask del tempo finto: si alternano attese vere e `pump`.
    Future<void> waitFor(WidgetTester tester, bool Function() done) async {
      for (var i = 0; i < 100 && !done(); i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
    }

    List<RouteBase> routes() => [
      GoRoute(
        path: '/',
        builder: (_, __) => LabelPage(
          args: LabelArgs(display: args, title: 'Wi-Fi di casa'),
        ),
      ),
    ];

    testWidgets('testo di partenza = titolo del QR, formati, anteprima', (tester) async {
      await pumpQr(
        tester,
        routes: routes(),
        pro: true,
        extra: [labelOutputProvider.overrideWithValue(FakeLabelOutput())],
      );
      expect(find.text('Etichetta da stampare'), findsOneWidget);
      expect(find.byKey(const ValueKey('label_preview')), findsOneWidget);
      final field = tester.widget<TextField>(find.byKey(const ValueKey('label_text')));
      expect(field.controller!.text, 'Wi-Fi di casa');
      expect(field.maxLines, 2);
      expect(find.text('Quadrata'), findsOneWidget);
      expect(find.text('Rettangolare'), findsOneWidget);
    });

    testWidgets('«Condividi immagine»: un PNG ad alta risoluzione con il testo scritto', (
      tester,
    ) async {
      final out = FakeLabelOutput();
      await pumpQr(
        tester,
        routes: routes(),
        pro: true,
        extra: [labelOutputProvider.overrideWithValue(out)],
      );
      await tester.enterText(find.byKey(const ValueKey('label_text')), 'Ospiti');
      await tester.tap(find.text('Rettangolare'));
      await tester.pump();
      await reveal(tester, 'label_share');
      await tester.tap(find.byKey(const ValueKey('label_share')));
      await waitFor(tester, () => out.shared.isNotEmpty);
      await tester.pumpAndSettle();
      final shared = out.shared.single;
      expect(shared.title, 'Wi-Fi di casa');
      final image = img.decodePng(Uint8List.fromList(shared.png))!;
      expect((image.width, image.height), (1200, 1800));
      expect(inkBetween(image, 0.65, 0.95), greaterThan(300), reason: 'il testo sotto il QR');
    });

    testWidgets('«Stampa»: il dialogo di sistema riceve un PDF', (tester) async {
      final out = FakeLabelOutput();
      await pumpQr(
        tester,
        routes: routes(),
        pro: true,
        extra: [labelOutputProvider.overrideWithValue(out)],
      );
      await reveal(tester, 'label_print');
      await tester.tap(find.byKey(const ValueKey('label_print')));
      await waitFor(tester, () => out.printed.isNotEmpty);
      final pdf = await tester.runAsync(() => out.printed.single.buildPdf(PdfPageFormat.a4));
      await tester.pumpAndSettle();
      expect(out.printed.single.name, 'Wi-Fi di casa');
      expect(ascii.decode(pdf!.sublist(0, 5)), '%PDF-');
    });
  });

  group('il Pro (imageExport)', () {
    testWidgets('senza Pro: «Etichetta» nella pagina del QR apre il paywall, non l\'etichetta', (
      tester,
    ) async {
      await pumpQr(
        tester,
        routes: [
          GoRoute(path: '/', builder: (_, __) => QrDisplayPage.args(args)),
          GoRoute(path: Routes.label, builder: (_, __) => const Text('ETICHETTA')),
        ],
      );
      await tester.tap(find.byKey(const ValueKey('action_label')));
      await tester.pumpAndSettle();
      expect(find.text('QR Me Pro'), findsWidgets);
      expect(find.text('ETICHETTA'), findsNothing);
    });

    testWidgets('col Pro: «Etichetta» apre /label con il QR e il suo titolo', (tester) async {
      final seen = <Object?>[];
      await pumpQr(
        tester,
        pro: true,
        routes: [
          GoRoute(path: '/', builder: (_, __) => QrDisplayPage.args(args)),
          captureRoute(Routes.label, seen),
        ],
      );
      await tester.tap(find.byKey(const ValueKey('action_label')));
      await tester.pumpAndSettle();
      final label = seen.single! as LabelArgs;
      expect(label.title, 'Casa');
      expect(label.display.payload, args.payload);
    });

    testWidgets('la rotta ha il suo ProGate: senza Pro c\'e\' il lucchetto', (tester) async {
      await pumpQr(
        tester,
        page: ProGate(
          feature: FeatureKey.imageExport,
          child: LabelPage(
            args: LabelArgs(display: args, title: 'x'),
          ),
        ),
      );
      expect(find.text('Questa funzione fa parte di QR Me Pro.'), findsOneWidget);
      expect(find.byKey(const ValueKey('label_print')), findsNothing);
    });

    test('il paywall lo dice: immagine o etichetta da stampare', () {
      final it = buildQrPaywall(lookupL(const Locale('it')));
      final en = buildQrPaywall(lookupL(const Locale('en')));
      String titleOf(PaywallConfig c) =>
          c.benefits.singleWhere((b) => b.key == FeatureKey.imageExport).title;
      expect(titleOf(it), 'Condividi il QR come immagine o come etichetta da stampare');
      expect(titleOf(en), 'Share the QR code as a picture or as a printable label');
    });
  });
}

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qr_me/domain/qr_capacity.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/domain/qr_style.dart';
import 'package:qr_me/services/content_actions.dart';
import 'package:qr_me/services/qr_renderer.dart';
import 'package:qr_me/services/readability_check.dart';

/// F17.1.7: `QrRenderer` e `ContentActions`.
void main() {
  group('QrRenderer', () {
    const r = QrRenderer();

    test('M senza logo, H con il logo, logo tolto se non sta in H', () {
      expect(r.levelFor('ciao', QrStyle.plain), QrErrorLevel.medium);
      const logo = QrStyle(logo: IconLogo('wifi'));
      expect(r.levelFor('ciao', logo), QrErrorLevel.high);
      final long = 'x' * 1500;
      expect(r.levelFor(long, logo), QrErrorLevel.medium);
      expect(r.choose(long, logo).logoDropped, isTrue);
    });

    test('troppo lungo: levelFor lancia, choose lo dice', () {
      final huge = 'x' * 3000;
      expect(r.choose(huge, QrStyle.plain).tooLong, isTrue);
      expect(() => r.levelFor(huge, QrStyle.plain), throwsArgumentError);
    });

    testWidgets('il widget ha la zona di rispetto del colore di sfondo, mai trasparente', (
      tester,
    ) async {
      const style = QrStyle(foreground: 0xFF1B2A4A, background: 0xFFFFF3C4);
      await tester.pumpWidget(
        Center(
          child: r.widget(payload: 'ciao', style: style, size: 200),
        ),
      );
      final box = tester.widget<ColoredBox>(find.byType(ColoredBox));
      expect(box.color, const Color(0xFFFFF3C4));
      final padding = tester.widget<Padding>(find.byType(Padding)).padding as EdgeInsets;
      // 'ciao' sta nella versione 1 (21 moduli): 4 moduli di 29 per lato.
      expect(padding.left, closeTo(200 * 4 / 29, 0.001));
    });

    testWidgets('il PNG e\' un PNG del lato chiesto', (tester) async {
      final bytes = await tester.runAsync(
        () => r.png(payload: 'ciao', style: QrStyle.plain, pixels: 256),
      );
      expect(bytes!.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      // Larghezza e altezza nell'intestazione IHDR, big endian.
      int be(int o) => (bytes[o] << 24) | (bytes[o + 1] << 16) | (bytes[o + 2] << 8) | bytes[o + 3];
      expect(be(16), 256);
      expect(be(20), 256);
    });
  });

  group('ContentActions', () {
    test('gli URI giusti per tipo', () {
      expect(
        ContentActions.uriFor(UrlContent(Uri.parse('https://esempio.it/a'))).toString(),
        'https://esempio.it/a',
      );
      expect(
        ContentActions.uriFor(const PhoneContent('+39 333-12 34')).toString(),
        'tel:+393331234',
      );
      expect(
        ContentActions.uriFor(
          const EmailContent(to: 'a@b.it', subject: 'Ciao a tutti', body: '1+1'),
        ).toString(),
        'mailto:a@b.it?subject=Ciao%20a%20tutti&body=1%2B1',
      );
      expect(
        ContentActions.uriFor(const SmsContent(number: '333 1', body: 'ci vediamo')).toString(),
        'sms:3331?body=ci%20vediamo',
      );
      expect(ContentActions.uriFor(const TextContent('x')), isNull);
      expect(ContentActions.uriFor(const WifiContent(ssid: 'x')), isNull);
    });

    test('open usa il lanciatore e restituisce false se non c\'e\' niente da aprire', () async {
      final opened = <Uri>[];
      final a = ContentActions(
        launcher: (u) async {
          opened.add(u);
          return true;
        },
      );
      expect(await a.open(const PhoneContent('123')), isTrue);
      expect(opened.single.toString(), 'tel:123');
      expect(await a.open(const TextContent('x')), isFalse);
    });

    test('un lanciatore che fallisce diventa false, non un\'eccezione', () async {
      final a = ContentActions(launcher: (_) async => throw StateError('nessuna app'));
      expect(await a.open(const PhoneContent('123')), isFalse);
    });

    // ☠ Difetto trovato rileggendo l'atlante: `uriFor` stava fuori dal try. Un `%` nudo
    // `Uri.parse` lo tollera (diventa `%25`, verificato); lancia invece un destinatario letto
    // che comincia con `//` e ha una «porta» non numerica (`MATMSG:TO://a:b;;`).
    test('destinatario che Uri.parse rifiuta: false, non FormatException, nessun lancio', () async {
      expect(
        () => ContentActions.uriFor(const EmailContent(to: '//posta:sconti')),
        throwsFormatException,
      );
      expect(
        ContentActions.uriFor(const EmailContent(to: '50%@sconti.it')).toString(),
        'mailto:50%25@sconti.it',
      );
      var calls = 0;
      final a = ContentActions(
        launcher: (_) async {
          calls++;
          return true;
        },
      );
      expect(await a.open(const EmailContent(to: '//posta:sconti')), isFalse);
      expect(calls, 0);
    });
  });

  group('ZxingImageReader', () {
    // ⚑ Sotto `flutter test` sul PC la libreria nativa di ZXing non c'e' (si compila solo dentro
    // l'app Android/iOS): il lettore deve dirlo con QrReaderUnavailable, che chi chiama traduce
    // in "non verificato"/"non riesco a leggere le immagini", e non con un'eccezione qualunque
    // che diventerebbe un crash o un "nessun QR" falso. La lettura vera la prova F17.7
    // sull'emulatore (ZXing legge da file anche li').
    test('senza libreria nativa: QrReaderUnavailable, non un errore qualunque', () async {
      // ☠ Serve un'immagine vera: un file che non c'e' o non e' un'immagine si ferma prima di
      // toccare la libreria nativa e torna come "nessun QR" (lista vuota), non come eccezione.
      final dir = await Directory.systemTemp.createTemp('qrme_zxing_');
      addTearDown(() => dir.delete(recursive: true));
      final png = File('${dir.path}/vuota.png')
        ..writeAsBytesSync(img.encodePng(img.Image(width: 8, height: 8)));
      await expectLater(
        const ZxingImageReader().read(png.path),
        throwsA(isA<QrReaderUnavailable>()),
      );
      await expectLater(
        const ZxingImageReader.strict().read(png.path),
        throwsA(isA<QrReaderUnavailable>()),
      );
    });

    test("un file che non si apre come immagine: nessun QR, non 'non disponibile'", () async {
      expect(await const ZxingImageReader().read('non_esiste.png'), isEmpty);
    });

    test('strict non prova i QR invertiti, quello normale si', () {
      expect(const ZxingImageReader().tryInverted, isTrue);
      expect(const ZxingImageReader.strict().tryInverted, isFalse);
    });
  });
}

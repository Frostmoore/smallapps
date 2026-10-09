import 'package:flutter_test/flutter_test.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/domain/qr_decoder.dart';
import 'package:qr_me/domain/qr_encoder.dart';

/// F17.1.3: ogni codifica esattamente come nella tabella. Sono le stringhe che le fotocamere di
/// sistema riconoscono: un carattere diverso e una fotocamera smette di capirle.
void main() {
  group('testo', () {
    test('identico, nemmeno il trim', () {
      expect(QrEncoder.encode(const TextContent('  ciao\nmondo  ')), '  ciao\nmondo  ');
    });
  });

  group('link', () {
    test('http e https come sono', () {
      expect(QrEncoder.encode(UrlContent(Uri.parse('https://esempio.it/a?b=1'))), 'https://esempio.it/a?b=1');
      expect(QrEncoder.encode(UrlContent(Uri.parse('http://esempio.it'))), 'http://esempio.it');
    });

    test('senza schema: https solo se c\'e\' un punto e nessuno spazio', () {
      expect(UrlContent.tryParse('esempio.it')!.uri.toString(), 'https://esempio.it');
      expect(UrlContent.tryParse('esempio.it/pagina?x=1')!.uri.toString(), 'https://esempio.it/pagina?x=1');
      expect(QrEncoder.encode(UrlContent(Uri.parse('esempio.it'))), 'https://esempio.it');
      expect(UrlContent.tryParse('ciao'), isNull, reason: 'senza punto e\' una parola');
      expect(UrlContent.tryParse('ciao mondo.it'), isNull, reason: 'con uno spazio e\' una frase');
      expect(UrlContent.tryParse('  HTTPS://Esempio.it  ')!.uri.host, 'esempio.it');
    });

    test('altri schemi rifiutati', () {
      expect(UrlContent.tryParse('ftp://esempio.it'), isNull);
      expect(UrlContent.tryParse('javascript:alert(1)'), isNull);
      expect(() => QrEncoder.encode(UrlContent(Uri.parse('ftp://esempio.it'))), throwsArgumentError);
    });
  });

  group('Wi-Fi', () {
    test('WPA con password', () {
      expect(QrEncoder.encode(const WifiContent(ssid: 'Casa', password: 'segreta')), 'WIFI:T:WPA;S:Casa;P:segreta;;');
    });

    test('WEP, rete nascosta', () {
      expect(
        QrEncoder.encode(const WifiContent(ssid: 'Casa', password: 'x', security: WifiSecurity.wep, hidden: true)),
        'WIFI:T:WEP;S:Casa;P:x;H:true;;',
      );
    });

    test('rete aperta: nopass e niente P', () {
      expect(
        QrEncoder.encode(const WifiContent(ssid: 'Bar', password: 'ignorata', security: WifiSecurity.none)),
        'WIFI:T:nopass;S:Bar;;',
      );
    });

    test(r'escape di \ ; , : " in SSID e password (F17.1.11 punto 1)', () {
      expect(
        QrEncoder.encode(const WifiContent(ssid: r'Ca;sa, "1": \x', password: r'p;a,s:s"w\d')),
        r'WIFI:T:WPA;S:Ca\;sa\, \"1\"\: \\x;P:p\;a\,s\:s\"w\\d;;',
      );
    });
  });

  group('contatto vCard 3.0', () {
    test('tutti i campi, CRLF, N ricavato da FN', () {
      final s = QrEncoder.encode(
        const ContactContent(
          name: 'Mario Bianchi Rossi',
          phone: '+39 333 123-4567',
          email: 'mario@esempio.it',
          organization: 'SMP',
          url: 'https://esempio.it',
          note: 'ciao',
        ),
      );
      expect(
        s,
        'BEGIN:VCARD\r\nVERSION:3.0\r\nN:Rossi;Mario Bianchi;;;\r\nFN:Mario Bianchi Rossi\r\n'
        'TEL:+393331234567\r\nEMAIL:mario@esempio.it\r\nORG:SMP\r\nURL:https://esempio.it\r\nNOTE:ciao\r\nEND:VCARD',
      );
    });

    test('righe vuote omesse, un nome solo', () {
      expect(
        QrEncoder.encode(const ContactContent(name: 'Mario', phone: '', email: null)),
        'BEGIN:VCARD\r\nVERSION:3.0\r\nN:Mario;;;;\r\nFN:Mario\r\nEND:VCARD',
      );
    });

    test(r'escape vCard di \ , ; e a-capo', () {
      final s = QrEncoder.encode(const ContactContent(name: 'Ditta, Srl', note: 'riga 1\nriga; 2 \\ fine'));
      expect(s, contains(r'FN:Ditta\, Srl'));
      expect(s, contains(r'NOTE:riga 1\nriga\; 2 \\ fine'));
    });
  });

  group('email, SMS, telefono', () {
    test('mailto con encodeComponent, parametri vuoti omessi', () {
      expect(
        QrEncoder.encode(const EmailContent(to: 'a@b.it', subject: 'Ciao a tutti', body: 'riga 1\n1+1=2 & più')),
        'mailto:a@b.it?subject=Ciao%20a%20tutti&body=riga%201%0A1%2B1%3D2%20%26%20pi%C3%B9',
      );
      expect(QrEncoder.encode(const EmailContent(to: 'a@b.it')), 'mailto:a@b.it');
      expect(QrEncoder.encode(const EmailContent(to: 'a@b.it', body: 'x')), 'mailto:a@b.it?body=x');
    });

    test('SMSTO con il testo dopo il secondo due punti', () {
      expect(QrEncoder.encode(const SmsContent(number: '+39 333 1234', body: 'Ciao: arrivo')), 'SMSTO:+393331234:Ciao: arrivo');
      expect(QrEncoder.encode(const SmsContent(number: '333')), 'SMSTO:333:');
    });

    test('tel normalizzato, il + resta', () {
      expect(QrEncoder.encode(const PhoneContent('+39 (02) 123-45.67')), 'tel:+39021234567');
    });
  });

  test('autoTitle sensato per ogni tipo', () {
    expect(const TextContent('\n  prima riga \nseconda').autoTitle, 'prima riga');
    expect(UrlContent(Uri.parse('https://www.Esempio.it/x')).autoTitle, 'esempio.it');
    expect(const WifiContent(ssid: 'Casa').autoTitle, 'Casa');
    expect(const ContactContent(name: 'Mario Rossi').autoTitle, 'Mario Rossi');
    expect(const EmailContent(to: 'a@b.it').autoTitle, 'a@b.it');
    expect(const SmsContent(number: '333').autoTitle, '333');
    expect(const PhoneContent('333').autoTitle, '333');
    expect(TextContent('x' * 100).autoTitle.length, 41);
    expect(const TextContent('   ').autoTitle, isNotEmpty);
  });

  group('payloadOfTyped (testo scritto o condiviso, non da modulo)', () {
    String typed(String raw) => QrEncoder.payloadOfTyped(raw, QrDecoder.decodeTyped(raw));

    test('testo: identico, spazi compresi', () {
      expect(typed('  ciao  '), '  ciao  ');
    });

    test('link senza schema: ricodificato con https (l\'unica ricodifica)', () {
      expect(typed('esempio.it'), 'https://esempio.it');
    });

    test('vCard con ADR, MECARD, sms: tal quali (i campi ignoti non si perdono)', () {
      const vcard = 'BEGIN:VCARD\nVERSION:3.0\nFN:Mario\nADR:;;Via Roma 1;Milano;;;\nEND:VCARD';
      expect(typed(vcard), vcard);
      expect(QrEncoder.encode(QrDecoder.decodeTyped(vcard)), isNot(contains('ADR')));
      expect(typed('MECARD:N:Rossi;NICKNAME:Super;;'), 'MECARD:N:Rossi;NICKNAME:Super;;');
      expect(typed('sms:+39333?body=Ciao'), 'sms:+39333?body=Ciao');
    });

    test('tipi riconosciuti: via solo gli spazi a sinistra', () {
      expect(typed('  tel:+39333'), 'tel:+39333');
    });
  });
}

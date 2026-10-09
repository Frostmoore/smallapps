import 'package:flutter_test/flutter_test.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/domain/qr_decoder.dart';
import 'package:qr_me/domain/qr_encoder.dart';

/// F17.1.3: il decoder riconosce tutti i prefissi (anche quelli che l'encoder non produce),
/// ripiega su testo e non lancia mai; per ogni contenuto valido `decode(encode(c)) == c`.
void main() {
  group('riconoscimento', () {
    test('WIFI in qualunque ordine, maiuscole indifferenti, con unescape', () {
      expect(
        QrDecoder.decode(r'wifi:S:Ca\;sa;P:a\:b\\c;T:WPA2;H:TRUE;;'),
        const WifiContent(ssid: 'Ca;sa', password: r'a:b\c', hidden: true),
      );
      expect(QrDecoder.decode('WIFI:T:nopass;S:Bar;;'), const WifiContent(ssid: 'Bar', security: WifiSecurity.none));
      expect(QrDecoder.decode('WIFI:T:WEP;S:X;P:k;;'), const WifiContent(ssid: 'X', password: 'k', security: WifiSecurity.wep));
      // Senza T ma con una password: protetta.
      expect((QrDecoder.decode('WIFI:S:X;P:k;;') as WifiContent).security, WifiSecurity.wpa);
    });

    test('vCard 3.0 e 4.0, parametri e gruppi ignorati', () {
      const v4 = 'BEGIN:VCARD\nVERSION:4.0\nFN:Anna Verdi\nitem1.TEL;TYPE=cell;VALUE=uri:tel:+39 333 1\n'
          'EMAIL;TYPE=work:anna@x.it\nORG:Ditta;Reparto\nPHOTO:ignorata\nEND:VCARD';
      expect(
        QrDecoder.decode(v4),
        const ContactContent(name: 'Anna Verdi', phone: '+393331', email: 'anna@x.it', organization: 'Ditta, Reparto'),
      );
      // Senza FN: il nome da N (cognome;nome).
      expect(
        QrDecoder.decode('BEGIN:VCARD\r\nVERSION:3.0\r\nN:Rossi;Mario;;;\r\nEND:VCARD'),
        const ContactContent(name: 'Mario Rossi'),
      );
    });

    test('MECARD diventa un contatto', () {
      expect(
        QrDecoder.decode('MECARD:N:Rossi,Mario;TEL:333;EMAIL:m@r.it;;'),
        const ContactContent(name: 'Mario Rossi', phone: '333', email: 'm@r.it'),
      );
    });

    test('mailto e MATMSG diventano email', () {
      expect(
        QrDecoder.decode('MAILTO:a@b.it?Subject=1%2B1&body=x+y'),
        const EmailContent(to: 'a@b.it', subject: '1+1', body: 'x+y'),
      );
      expect(
        QrDecoder.decode('MATMSG:TO:a@b.it;SUB:Ciao;BODY:Testo\\; lungo;;'),
        const EmailContent(to: 'a@b.it', subject: 'Ciao', body: 'Testo; lungo'),
      );
    });

    test('SMSTO, sms: e SMS:numero:testo', () {
      expect(QrDecoder.decode('smsto:333:ciao: sì'), const SmsContent(number: '333', body: 'ciao: sì'));
      expect(QrDecoder.decode('sms:+39333?body=ciao%20a%20te'), const SmsContent(number: '+39333', body: 'ciao a te'));
      expect(QrDecoder.decode('SMS:333:ciao'), const SmsContent(number: '333', body: 'ciao'));
      expect(QrDecoder.decode('sms:333'), const SmsContent(number: '333'));
    });

    test('tel', () {
      expect(QrDecoder.decode('TEL:+39 02 123'), const PhoneContent('+3902123'));
    });

    test('http/https senza spazi diventano link, con spazi restano testo', () {
      expect(QrDecoder.decode('HTTPS://esempio.it/x'), UrlContent(Uri.parse('https://esempio.it/x')));
      expect(QrDecoder.decode('https://esempio.it/x\n'), UrlContent(Uri.parse('https://esempio.it/x')));
      expect(QrDecoder.decode('https://esempio.it guarda'), const TextContent('https://esempio.it guarda'));
    });

    test('testo come ripiego, intatto', () {
      for (final raw in ['ciao', '  spazi  ', 'esempio.it', 'ftp://x.it', '']) {
        expect(QrDecoder.decode(raw), TextContent(raw), reason: raw);
      }
    });

    test('non lancia mai: formati rotti diventano testo', () {
      for (final raw in ['WIFI:', 'WIFI:P:solo;;', 'BEGIN:VCARD', 'mailto:%E0%A4%A', 'mailto:', 'tel:abc', 'SMSTO:', 'MECARD:;;', 'MATMSG:;']) {
        expect(QrDecoder.decode(raw), TextContent(raw), reason: raw);
      }
    });

    test('decodeTyped: un dominio scritto a mano diventa un link https', () {
      expect(QrDecoder.decodeTyped('esempio.it'), UrlContent(Uri.parse('https://esempio.it')));
      expect(QrDecoder.decodeTyped('ciao'), const TextContent('ciao'));
      expect(QrDecoder.decodeTyped('tel:333'), const PhoneContent('333'));
    });
  });

  group('round-trip decode(encode(c)) == c', () {
    final contenuti = <QrContent>[
      const TextContent('Una nota\ncon due righe e un’emoji 🎉'),
      const TextContent('  spazi ai bordi  '),
      UrlContent(Uri.parse('https://esempio.it/percorso?a=1&b=due#x')),
      UrlContent(Uri.parse('http://esempio.it')),
      const WifiContent(ssid: 'Casa', password: 'segreta'),
      const WifiContent(ssid: r'Ca;sa, "1": \x', password: r'p;a,s:s"w\d', hidden: true),
      const WifiContent(ssid: 'Ospiti 🍕', password: 'w', security: WifiSecurity.wep),
      const WifiContent(ssid: 'Bar', security: WifiSecurity.none),
      const ContactContent(
        name: 'Mario Bianchi Rossi',
        phone: '+39 333 123 4567',
        email: 'mario@esempio.it',
        organization: 'Ditta, Srl; reparto',
        url: 'https://esempio.it',
        note: 'riga 1\nriga 2 \\ fine',
      ),
      const ContactContent(name: 'Anna'),
      const EmailContent(to: 'a@b.it', subject: 'Ciao & arrivederci 1+1', body: 'riga 1\nriga 2 🎉'),
      const EmailContent(to: 'a@b.it'),
      const SmsContent(number: '+39 333 1234', body: 'Arrivo: 5 minuti; ok?'),
      const SmsContent(number: '333'),
      const PhoneContent('+39 (02) 123-4567'),
    ];
    for (final c in contenuti) {
      test('$c', () {
        final encoded = QrEncoder.encode(c);
        expect(QrDecoder.decode(encoded), c, reason: encoded);
      });
    }
  });

  group('toFields / fromFields', () {
    final contenuti = <QrContent>[
      const TextContent('x'),
      UrlContent(Uri.parse('https://esempio.it')),
      const WifiContent(ssid: 'Casa', password: 'p', hidden: true),
      const ContactContent(name: 'Mario', phone: '333', note: 'n'),
      const EmailContent(to: 'a@b.it', subject: 's', body: 'b'),
      const SmsContent(number: '333', body: 'b'),
      const PhoneContent('333'),
    ];
    for (final c in contenuti) {
      test('${c.kind.name} andata e ritorno', () => expect(QrContent.fromFields(c.kind, c.toFields()), c));
    }

    test('campi rotti: FormatException', () {
      expect(() => QrContent.fromFields(QrKind.wifi, {'ssid': 3}), throwsFormatException);
      expect(() => QrContent.fromFields(QrKind.wifi, {'ssid': 'x', 'security': 'boh'}), throwsFormatException);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:qr_me/domain/qr_capacity.dart';

/// F17.1.3: limiti per livello in byte UTF-8 (un'emoji conta 4), e la scelta del livello.
void main() {
  test('i limiti della versione 40 in modalita\' byte', () {
    expect(QrCapacity.maxBytes(QrErrorLevel.low), 2953);
    expect(QrCapacity.maxBytes(QrErrorLevel.medium), 2331);
    expect(QrCapacity.maxBytes(QrErrorLevel.quartile), 1663);
    expect(QrCapacity.maxBytes(QrErrorLevel.high), 1273);
  });

  test('fits al limite esatto', () {
    expect(QrCapacity.fits('a' * 1273, QrErrorLevel.high), isTrue);
    expect(QrCapacity.fits('a' * 1274, QrErrorLevel.high), isFalse);
  });

  test('UTF-8 multibyte: un\'emoji conta 4 byte, una lettera accentata 2', () {
    expect(QrCapacity.bytesOf('🎉'), 4);
    expect(QrCapacity.bytesOf('è'), 2);
    // 319 emoji = 1276 byte: oltre H anche se sono "319 caratteri".
    expect(QrCapacity.fits('🎉' * 318, QrErrorLevel.high), isTrue);
    expect(QrCapacity.fits('🎉' * 319, QrErrorLevel.high), isFalse);
  });

  group('choose', () {
    test('M senza logo, H con il logo', () {
      expect(QrCapacity.choose('ciao', wantsLogo: false).level, QrErrorLevel.medium);
      final conLogo = QrCapacity.choose('ciao', wantsLogo: true);
      expect(conLogo.level, QrErrorLevel.high);
      expect(conLogo.logoAllowed, isTrue);
      expect(conLogo.logoDropped, isFalse);
    });

    test('troppo lungo per H: il logo si toglie, si scende a M', () {
      final c = QrCapacity.choose('a' * 1500, wantsLogo: true);
      expect(c.level, QrErrorLevel.medium);
      expect(c.logoAllowed, isFalse);
      expect(c.logoDropped, isTrue);
      expect(c.dense, isTrue);
    });

    test('troppo lungo per M: L; troppo lungo per L: niente QR', () {
      expect(QrCapacity.choose('a' * 2500, wantsLogo: false).level, QrErrorLevel.low);
      final no = QrCapacity.choose('a' * 3000, wantsLogo: false);
      expect(no.tooLong, isTrue);
      expect(no.bytes, 3000);
    });

    test('fitto solo oltre 1000 byte', () {
      expect(QrCapacity.choose('a' * 1000, wantsLogo: false).dense, isFalse);
      expect(QrCapacity.choose('a' * 1001, wantsLogo: false).dense, isTrue);
    });
  });
}

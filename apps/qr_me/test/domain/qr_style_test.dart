import 'package:flutter_test/flutter_test.dart';
import 'package:qr_me/domain/qr_style.dart';

/// F17.1.3: JSON tollerante, `isPlain`, id delle icone stabili, logo di testo a grafemi.
void main() {
  test('plain e isPlain', () {
    expect(QrStyle.plain.isPlain, isTrue);
    expect(const QrStyle().isPlain, isTrue);
    expect(QrStyle.plain.copyWith(foreground: 0xFF112233).isPlain, isFalse);
    expect(QrStyle.plain.copyWith(logo: const IconLogo('wifi')).isPlain, isFalse);
    expect(QrStyle.plain.copyWith(logo: const NoLogo()).isPlain, isTrue);
  });

  group('JSON', () {
    final stili = [
      QrStyle.plain,
      const QrStyle(foreground: 0xFF1B5E20, background: 0xFFFFF8E1, moduleShape: QrModuleShape.circle, eyeShape: QrEyeShape.circle),
      const QrStyle(logo: PhotoLogo(imageName: 'images/logos/a.jpg', round: true)),
      const QrStyle(logo: IconLogo('heart')),
      const QrStyle(logo: TextLogo('👨‍👩‍👧')),
    ];
    for (final s in stili) {
      test('andata e ritorno: $s', () => expect(QrStyle.fromJson(s.toJson()), s));
    }

    test('chiavi mancanti = default, sconosciute ignorate', () {
      expect(QrStyle.fromJson(const {}), QrStyle.plain);
      expect(QrStyle.fromJson(const {'futuro': true, 'fg': 0xFF00FF00}), const QrStyle(foreground: 0xFF00FF00));
    });

    test('valori del tipo sbagliato o sconosciuti = default, mai un\'eccezione', () {
      final s = QrStyle.fromJson(const {
        'fg': 'rosso',
        'bg': 1.0,
        'module': 'stella',
        'eye': 3,
        'logo': {'type': 'ologramma'},
      });
      expect(s.foreground, QrStyle.plain.foreground);
      expect(s.background, 1);
      expect(s.moduleShape, QrModuleShape.square);
      expect(s.eyeShape, QrEyeShape.square);
      expect(s.logo, const NoLogo());
      expect(QrStyle.fromJson(const {'logo': {'type': 'text', 'text': 'troppo lungo'}}).logo, const NoLogo());
      expect(QrStyle.fromJson(const {'logo': {'type': 'photo'}}).logo, const NoLogo());
    });

    test('IconLogo salva l\'id testuale, non un codePoint', () {
      expect(const IconLogo('wifi').toJson(), {'type': 'icon', 'id': 'wifi'});
    });
  });

  test('il catalogo delle icone: 24 id stabili, senza doppioni', () {
    // ☠ Un id pubblicato non si toglie e non si rinomina: e' gia' nei database e nei backup.
    expect(kLogoIconIds, [
      'wifi', 'phone', 'email', 'sms', 'home', 'work', 'heart', 'star', 'shop', 'restaurant', //
      'coffee', 'music', 'camera', 'link', 'person', 'group', 'event', 'location', 'car', 'pets', //
      'school', 'info', 'gift', 'payment',
    ]);
    expect(kLogoIconIds.toSet(), hasLength(kLogoIconIds.length));
  });

  test('il logo di testo conta i grafemi, non i code unit', () {
    expect(TextLogo.isValidText('A'), isTrue);
    expect(TextLogo.isValidText('SMP'), isTrue);
    expect(TextLogo.isValidText('🇮🇹🎉👨‍👩‍👧'), isTrue, reason: 'tre grafemi, molti code unit');
    expect(TextLogo.isValidText('ABCD'), isFalse);
    expect(TextLogo.isValidText('  '), isFalse);
    expect(TextLogo.isValidText(''), isFalse);
  });
}

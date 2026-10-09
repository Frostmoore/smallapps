import 'package:flutter_test/flutter_test.dart';
import 'package:qr_me/domain/contrast.dart';

/// F17.1.3: rapporto WCAG e verso dei colori.
void main() {
  test('nero su bianco: 21, simmetrico', () {
    expect(Contrast.ratio(0xFF000000, 0xFFFFFFFF), closeTo(21, 0.01));
    expect(Contrast.ratio(0xFFFFFFFF, 0xFF000000), closeTo(21, 0.01));
  });

  test('colori uguali: 1', () {
    expect(Contrast.ratio(0xFF3BD13B, 0xFF3BD13B), closeTo(1, 1e-9));
  });

  test('grigi simili sotto 3: l\'avviso rosso', () {
    expect(Contrast.ratio(0xFF777777, 0xFF999999), lessThan(Contrast.minRatio));
    expect(Contrast.ratio(0xFF1B5E20, 0xFFFFFFFF), greaterThan(Contrast.minRatio));
  });

  test('l\'alfa si ignora', () {
    expect(Contrast.ratio(0x00000000, 0xFFFFFFFF), closeTo(21, 0.01));
  });

  test('inversione: primo piano piu\' chiaro dello sfondo', () {
    expect(Contrast.inverted(0xFFFFFFFF, 0xFF000000), isTrue);
    expect(Contrast.inverted(0xFF000000, 0xFFFFFFFF), isFalse);
    expect(Contrast.inverted(0xFF3BD13B, 0xFF102010), isTrue);
  });
}

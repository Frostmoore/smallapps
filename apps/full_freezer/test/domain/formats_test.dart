import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/app/formats.dart';

/// I litri come li legge una persona.
void main() {
  test('sotto il litro due decimali, fino a 10 uno, oltre nessuno', () {
    expect(formatLiters(0.25, 'it'), '0,25 L');
    expect(formatLiters(0.4, 'it'), '0,4 L');
    expect(formatLiters(1.25, 'it'), '1,3 L');
    expect(formatLiters(70, 'it'), '70 L');
    expect(formatLiters(1.5, 'en'), '1.5 L');
  });

  test('numeri scritti con la virgola o con il punto', () {
    expect(parseUserNumber('1,5'), 1.5);
    expect(parseUserNumber(' 15 '), 15);
    expect(parseUserNumber('abc'), isNull);
    expect(parseUserNumber(''), isNull);
  });
}

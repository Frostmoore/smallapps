import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_me/app/qr_palette.dart';
import 'package:qr_me/domain/contrast.dart';

/// F17.7: i testi della grafica «A · Neon» si leggono, nel tema scuro e in quello chiaro.
///
/// ☠ Nato da un difetto visto sull'emulatore: nel tema chiaro l'accento #16A34A dava 3,0:1 sul
/// fondo («Vedi tutti», i link) e 3,3:1 col testo bianco dei pulsanti. La soglia e' quella di
/// WCAG AA per il testo normale (4,5:1): i testi verdi dell'app non sono mai "grandi".
void main() {
  const aa = 4.5;

  for (final (nome, p) in [('scuro', QrPalette.dark), ('chiaro', QrPalette.light)]) {
    group('tema $nome', () {
      double r(Color a, Color b) => Contrast.ratio(a.toARGB32(), b.toARGB32());

      test('testo e testo secondario sul fondo e sulle superfici', () {
        for (final fondo in [p.ground, p.surface]) {
          expect(r(p.ink, fondo), greaterThanOrEqualTo(aa));
          expect(r(p.inkMuted, fondo), greaterThanOrEqualTo(aa));
        }
      });

      test("l'accento come testo (link, «Vedi tutti») sul fondo e sulle superfici", () {
        expect(r(p.accent, p.ground), greaterThanOrEqualTo(aa));
        expect(r(p.accent, p.surface), greaterThanOrEqualTo(aa));
      });

      test("il testo dei pulsanti sull'accento", () {
        expect(r(p.onAccent, p.accent), greaterThanOrEqualTo(aa));
      });
    });
  }
}

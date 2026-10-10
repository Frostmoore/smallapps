import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spending_review/app/sr_palette.dart';

/// I contrasti di «C · Una mano» (develop_microapps.md F12.1.12, F12.1.17
/// `palette_contrast_test.dart`): ogni coppia testo/fondo ≥ 4,5:1 (WCAG AA, testo normale), i
/// numeri grandi e i colori della barra ≥ 3:1, in ENTRAMBI i temi.
///
/// ⚑ Il tema chiaro e' derivato (la tavola e' solo scura): l'accento #4ADE80 sul bianco darebbe
/// circa 1,6:1, per questo il chiaro usa #15803D (come QR Me). Questo test e' cio' che lo tiene.
void main() {
  double luminanza(Color c) {
    double canale(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * canale(c.r) + 0.7152 * canale(c.g) + 0.0722 * canale(c.b);
  }

  double rapporto(Color a, Color b) {
    final la = luminanza(a);
    final lb = luminanza(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  test('il calcolo del rapporto e\' quello di WCAG (nero su bianco = 21)', () {
    expect(rapporto(const Color(0xFF000000), const Color(0xFFFFFFFF)), closeTo(21, 0.01));
  });

  for (final (nome, p) in [('scuro', SrPalette.scuro), ('chiaro', SrPalette.chiaro)]) {
    group('tema $nome', () {
      test('testo, testo della lista e testo secondario su fondo, superfici e tastierino ≥ 4,5', () {
        for (final fondo in [p.sfondo, p.superficie, p.fondoProfondo, p.superficieOp]) {
          expect(rapporto(p.testo, fondo), greaterThanOrEqualTo(4.5));
          expect(rapporto(p.testoLista, fondo), greaterThanOrEqualTo(4.5));
        }
        for (final fondo in [p.sfondo, p.superficie, p.fondoProfondo]) {
          expect(rapporto(p.testoSecondario, fondo), greaterThanOrEqualTo(4.5));
        }
      });

      test('il testo sui bottoni verdi (Cartellino, +, Chiudi la spesa) ≥ 4,5', () {
        expect(rapporto(p.suAccento, p.accento), greaterThanOrEqualTo(4.5));
      });

      test("l'accento come testo (residuo, link) su fondo e superficie ≥ 4,5", () {
        expect(rapporto(p.accento, p.sfondo), greaterThanOrEqualTo(4.5));
        expect(rapporto(p.accento, p.superficie), greaterThanOrEqualTo(4.5));
      });

      test("l'ambra: testo sul suo fondo ≥ 4,5, valore sul suo fondo ≥ 3 (numero grande)", () {
        expect(rapporto(p.ambraTesto, p.ambraFondo), greaterThanOrEqualTo(4.5));
        expect(rapporto(p.ambraValore, p.ambraFondo), greaterThanOrEqualTo(3));
      });

      test('rosso e ambra della barra e del residuo sul fondo ≥ 3', () {
        expect(rapporto(p.rosso, p.sfondo), greaterThanOrEqualTo(3));
        expect(rapporto(p.ambraValore, p.sfondo), greaterThanOrEqualTo(3));
      });
    });
  }
}

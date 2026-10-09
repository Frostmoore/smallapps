import 'dart:math' as math;

/// Contrasto fra i colori di un QR (develop_microapps.md F17.1.3). Colori in ARGB a 32 bit
/// (`0xFF000000`), come in `QrStyle`; l'alfa si ignora (i colori dello stile sono opachi).
///
/// ⚑ Sono euristiche per avvisare presto: rapporto **< 3** → avviso rosso, **invertito** →
/// avviso giallo. La prova vera e' `ReadabilityCheck` (F17.1.7), che rilegge il PNG.
abstract final class Contrast {
  /// Sotto questo rapporto: «Colori troppo simili, molte fotocamere non lo leggeranno».
  static const double minRatio = 3;

  /// Rapporto di contrasto WCAG 2 fra due colori: da 1 (uguali) a 21 (nero su bianco).
  static double ratio(int argbA, int argbB) {
    final a = _luminance(argbA);
    final b = _luminance(argbB);
    final hi = math.max(a, b);
    final lo = math.min(a, b);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// True se il primo piano e' piu' chiaro dello sfondo («QR chiaro su scuro»): molte
  /// fotocamere cercano moduli scuri su fondo chiaro e non lo leggono.
  static bool inverted(int foreground, int background) => _luminance(foreground) > _luminance(background);

  /// Luminanza relativa WCAG: sRGB linearizzato, pesi 0.2126 / 0.7152 / 0.0722.
  static double _luminance(int argb) {
    double channel(int shift) {
      final c = ((argb >> shift) & 0xFF) / 255.0;
      return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
  }
}

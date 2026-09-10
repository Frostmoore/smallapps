import 'package:flutter/material.dart';

/// Spaziature. Scala a passi di 4, con due gradini fini in basso per i dettagli.
///
/// ⚑ Perché una scala e non numeri liberi: con numeri liberi ogni schermata finisce con
/// margini leggermente diversi, e il risultato si legge come sciatteria anche da chi non
/// saprebbe dire perché. Sei valori coprono tutto.
abstract final class MicroSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const EdgeInsets pageH = EdgeInsets.symmetric(horizontal: l);
  static const EdgeInsets page = EdgeInsets.fromLTRB(l, l, l, xxxl);
  static const EdgeInsets card = EdgeInsets.all(l);
  static const EdgeInsets cardTight = EdgeInsets.all(m);

  static const SizedBox gapXS = SizedBox(height: xs);
  static const SizedBox gapS = SizedBox(height: s);
  static const SizedBox gapM = SizedBox(height: m);
  static const SizedBox gapL = SizedBox(height: l);
  static const SizedBox gapXL = SizedBox(height: xl);
  static const SizedBox gapXXL = SizedBox(height: xxl);

  static const SizedBox hGapS = SizedBox(width: s);
  static const SizedBox hGapM = SizedBox(width: m);
  static const SizedBox hGapL = SizedBox(width: l);
}

/// Raggi di arrotondamento.
abstract final class MicroRadius {
  static const Radius small = Radius.circular(8);
  static const Radius medium = Radius.circular(14);
  static const Radius large = Radius.circular(22);

  static const BorderRadius chip = BorderRadius.all(small);
  static const BorderRadius card = BorderRadius.all(medium);
  static const BorderRadius hero = BorderRadius.all(large);
  static const BorderRadius sheet = BorderRadius.vertical(top: large);
}

/// Durate delle animazioni.
///
/// ⚑ Una sola scala anche qui: animazioni di durata casuale fanno sembrare l'app
/// incoerente. `quick` per i feedback immediati, `normal` per le transizioni di stato,
/// `slow` solo per gli elementi grandi che cambiano forma.
abstract final class MicroDuration {
  static const Duration quick = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 420);
}

/// Colori semantici che non stanno in [ColorScheme].
///
/// ⚑ Perché come extension e non come costanti globali: `success` e `warning` devono
/// derivare dal seed dell'app e dalla brightness, altrimenti il verde di "consumato" del
/// freezer stona con il blu ghiaccio. Come extension restano accessibili ovunque con
/// `Theme.of(context).colorScheme.success` e cambiano da soli con il tema.
extension MicroColorScheme on ColorScheme {
  bool get _dark => brightness == Brightness.dark;

  Color get success => _dark ? const Color(0xFF7CC48A) : const Color(0xFF2E7D4F);
  Color get onSuccess => _dark ? const Color(0xFF08290F) : Colors.white;

  Color get warning => _dark ? const Color(0xFFE8B04B) : const Color(0xFFB26A00);
  Color get onWarning => _dark ? const Color(0xFF2A1C00) : Colors.white;

  Color get danger => error;
  Color get onDanger => onError;

  /// Sfondo delle card, distinto da [surface] così le card si staccano dalla pagina
  /// senza bisogno di ombre marcate.
  Color get cardSurface => _dark
      ? Color.alphaBlend(surfaceTint.withValues(alpha: 0.06), surfaceContainerHigh)
      : surfaceContainerLowest;

  /// Bordo appena percettibile, per separare senza disegnare linee nere.
  Color get subtleBorder => outlineVariant.withValues(alpha: _dark ? 0.5 : 0.7);

  /// Testo secondario, leggibile ma non in competizione con il titolo.
  Color get mutedText => onSurfaceVariant;
}

/// Stili tipografici ricorrenti.
extension MicroTextTheme on TextTheme {
  /// Cifre a larghezza fissa.
  ///
  /// ☠ Senza `FontFeature.tabularFigures()` le liste di numeri (giorni nel freezer,
  /// giorni di autonomia, costi) "ballano" in larghezza da una riga all'altra. È il
  /// dettaglio che distingue un'app curata da una fatta in fretta.
  TextStyle get numeric =>
      (bodyMedium ?? const TextStyle()).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  TextStyle get cardTitle =>
      (titleMedium ?? const TextStyle()).copyWith(fontWeight: FontWeight.w600, height: 1.25);

  TextStyle get cardMeta => (bodySmall ?? const TextStyle()).copyWith(height: 1.3);

  /// Il numero grande di una dashboard.
  TextStyle get statValue => (displaySmall ?? const TextStyle()).copyWith(
    fontWeight: FontWeight.w700,
    height: 1.05,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  TextStyle get statLabel => (labelLarge ?? const TextStyle()).copyWith(
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  /// Etichetta di sezione, maiuscoletto spaziato.
  TextStyle get sectionLabel => (labelMedium ?? const TextStyle()).copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
  );
}

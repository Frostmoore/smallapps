import 'package:flutter/material.dart';

import 'micro_tokens.dart';

/// Costruisce il tema di un'app MicroApps a partire dal suo seed color.
///
/// Ogni app passa il proprio seed e il proprio font (ADR-010). `micro_core` non sa quale
/// app sta vestendo: nessun elenco di appId, nessuno `switch` sul nome.
abstract final class MicroTheme {
  /// Pesi usati dal design system. Servono a generare le [FontVariation] del font
  /// variabile, vedi [_textTheme].
  static const List<int> _weights = <int>[400, 500, 600, 700];

  static ThemeData light({
    required Color seed,
    required String fontFamily,
    String? displayFontFamily,
  }) => build(
    seed: seed,
    brightness: Brightness.light,
    fontFamily: fontFamily,
    displayFontFamily: displayFontFamily,
  );

  static ThemeData dark({
    required Color seed,
    required String fontFamily,
    String? displayFontFamily,
  }) => build(
    seed: seed,
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    displayFontFamily: displayFontFamily,
  );

  static ThemeData build({
    required Color seed,
    required Brightness brightness,
    required String fontFamily,
    String? displayFontFamily,
  }) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final text = _textTheme(scheme, fontFamily, displayFontFamily);
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      fontFamily: fontFamily,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),

      cardTheme: CardThemeData(
        color: scheme.cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: MicroRadius.card,
          side: BorderSide(color: scheme.subtleBorder),
        ),
      ),

      // ⚑ Nessuna elevazione, solo bordi sottili. Le ombre di Material su fondo chiaro
      // sporcano, e in dark mode sono invisibili: un bordo funziona in entrambi i temi
      // e costa meno da disegnare.
      dividerTheme: DividerThemeData(color: scheme.subtleBorder, space: 1, thickness: 1),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: MicroRadius.card),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: MicroRadius.card),
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          // 48 dp è il minimo per un target di tocco accessibile.
          minimumSize: const Size(64, 48),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MicroSpacing.l,
          vertical: MicroSpacing.l,
        ),
        border: OutlineInputBorder(
          borderRadius: MicroRadius.card,
          borderSide: BorderSide(color: scheme.subtleBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: MicroRadius.card,
          borderSide: BorderSide(color: scheme.subtleBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: MicroRadius.card,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: MicroRadius.chip),
        side: BorderSide(color: scheme.subtleBorder),
        labelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: MicroSpacing.s, vertical: MicroSpacing.xs),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: MicroRadius.sheet),
        showDragHandle: true,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: MicroRadius.card),
        insetPadding: const EdgeInsets.all(MicroSpacing.l),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      ),

      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: MicroRadius.card),
        contentPadding: const EdgeInsets.symmetric(horizontal: MicroSpacing.l),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        extendedTextStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
      ),

      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );
  }

  /// Costruisce la tipografia applicando le [FontVariation] al font variabile.
  ///
  /// ☠ Trappola: con un font variabile, `fontWeight` da solo **non basta**. Flutter non
  /// interpola l'asse `wght` automaticamente: senza `fontVariations` tutti i pesi
  /// renderizzano l'istanza predefinita, e l'app appare tutta dello stesso spessore.
  /// Dichiarare lo stesso file quattro volte nel pubspec con `weight:` diversi non
  /// risolve: darebbe comunque l'istanza predefinita.
  static TextTheme _textTheme(ColorScheme scheme, String fontFamily, String? displayFamily) {
    final base = Typography.material2021(colorScheme: scheme).black.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      fontFamily: fontFamily,
    );

    TextStyle w(TextStyle? style, int weight, {String? family}) {
      assert(_weights.contains(weight), 'peso $weight non previsto dal design system');
      return (style ?? const TextStyle()).copyWith(
        fontFamily: family ?? fontFamily,
        fontWeight: FontWeight.values[(weight ~/ 100) - 1],
        fontVariations: <FontVariation>[FontVariation('wght', weight.toDouble())],
      );
    }

    final display = displayFamily ?? fontFamily;
    return base.copyWith(
      displayLarge: w(base.displayLarge, 700, family: display),
      displayMedium: w(base.displayMedium, 700, family: display),
      displaySmall: w(base.displaySmall, 700, family: display),
      headlineLarge: w(base.headlineLarge, 700, family: display),
      headlineMedium: w(base.headlineMedium, 600, family: display),
      headlineSmall: w(base.headlineSmall, 600, family: display),
      titleLarge: w(base.titleLarge, 600),
      titleMedium: w(base.titleMedium, 600),
      titleSmall: w(base.titleSmall, 500),
      bodyLarge: w(base.bodyLarge, 400),
      bodyMedium: w(base.bodyMedium, 400),
      bodySmall: w(base.bodySmall, 400),
      labelLarge: w(base.labelLarge, 500),
      labelMedium: w(base.labelMedium, 500),
      labelSmall: w(base.labelSmall, 500),
    );
  }
}

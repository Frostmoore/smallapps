import 'package:flutter/material.dart';

/// Il carattere dei titoli: Space Grotesk 700 (SIL OFL, `assets/fonts/OFL-SpaceGrotesk.txt`).
const String kTitleFont = 'SpaceGrotesk';

/// I colori e le forme della grafica «A · Neon» (scelta del proprietario, 2026-10-09, F17.6;
/// board https://claude.ai/artifact/PnrsKsGFRmFsppGHBxBrHk).
///
/// ⚑ Come Film Tracker (`withFilmLook`) e non come Scorte Calore: la palette cambia **anche** il
/// `ColorScheme`. Il verde neon e' l'accento di tutto (pulsanti, interruttori, chip), e i colori
/// che Material ricaverebbe dal seme (un verde spento, un terziario azzurro) stonerebbero.
///
/// ⚑ Il QR **non** prende questi colori: sta sempre sul suo pannello bianco (o sullo sfondo del
/// suo stile). Il nero della pagina e' scelto anche per questo: attorno a un pannello bianco
/// l'occhio (e la fotocamera) trovano subito il codice.
@immutable
class QrPalette extends ThemeExtension<QrPalette> {
  const QrPalette({
    required this.ground,
    required this.surface,
    required this.border,
    required this.borderFaint,
    required this.ink,
    required this.inkMuted,
    required this.accent,
    required this.onAccent,
    required this.glow,
  });

  /// Il fondo della pagina.
  final Color ground;

  /// Schede, righe, campi.
  final Color surface;

  /// Il bordo da 1 px delle superfici.
  final Color border;

  /// I separatori sottili.
  final Color borderFaint;

  final Color ink;

  /// Testo secondario ed etichette di sezione.
  final Color inkMuted;

  /// Il verde: pulsante primario, pallini delle azioni, badge PRO.
  final Color accent;
  final Color onAccent;

  /// L'alone attorno al pulsante primario e al pannello del QR.
  final Color glow;

  /// Scuro: quello disegnato. Default dell'app.
  static const QrPalette dark = QrPalette(
    ground: Color(0xFF0E1110),
    surface: Color(0xFF151A16),
    border: Color(0xFF2A332C),
    borderFaint: Color(0xFF1E2620),
    ink: Color(0xFFEAF2EA),
    inkMuted: Color(0xFF8FA394),
    accent: Color(0xFF3BD13B),
    onAccent: Color(0xFF06210B),
    glow: Color(0x733BD13B), // rgba(59,209,59,0.45)
  );

  /// Chiaro: la stessa app su carta. ⚑ L'accento si scurisce a #16A34A: il #3BD13B su bianco ha
  /// un contrasto di 2:1 e i testi verdi (link, «Vedi tutti») non si leggerebbero.
  static const QrPalette light = QrPalette(
    ground: Color(0xFFF4F6F2),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFD5DDD6),
    borderFaint: Color(0xFFE6EBE6),
    ink: Color(0xFF121614),
    inkMuted: Color(0xFF5A6B5E),
    accent: Color(0xFF16A34A),
    onAccent: Color(0xFFFFFFFF),
    glow: Color(0x4D16A34A),
  );

  static QrPalette of(BuildContext context) =>
      Theme.of(context).extension<QrPalette>() ?? QrPalette.dark;

  /// Le etichette di sezione: «SCRIVI O INCOLLA», «MODULI», «RECENTI».
  TextStyle get sectionLabel => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation('wght', 700)],
    letterSpacing: 12 * 0.08,
    color: inkMuted,
  );

  /// I titoli grandi (il nome dell'app, il titolo del QR mostrato).
  TextStyle title({double size = 24, Color? color}) => TextStyle(
    fontFamily: kTitleFont,
    fontSize: size,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation('wght', 700)],
    height: 1.15,
    color: color ?? ink,
  );

  /// Superficie con bordo da 1 px: schede, righe, azioni.
  BoxDecoration card({double radius = 20}) => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border),
  );

  @override
  QrPalette copyWith() => this;

  @override
  QrPalette lerp(ThemeExtension<QrPalette>? other, double t) =>
      t < 0.5 ? this : (other as QrPalette? ?? this);
}

/// Il tema di Material vestito da «A · Neon»: fondo, superfici, accento, forme a pillola.
ThemeData withQrLook(ThemeData base, QrPalette p) {
  final scheme = base.colorScheme.copyWith(
    primary: p.accent,
    onPrimary: p.onAccent,
    primaryContainer: p.surface,
    onPrimaryContainer: p.accent,
    secondary: p.accent,
    onSecondary: p.onAccent,
    secondaryContainer: p.accent.withValues(alpha: 0.18),
    onSecondaryContainer: p.ink,
    // ⚑ Anche il terziario: Material lo ricava di un altro colore dal seme (lezione di Film
    // Tracker, dove un chip usciva celeste in mezzo all'arancio).
    tertiary: p.accent,
    onTertiary: p.onAccent,
    surface: p.ground,
    onSurface: p.ink,
    onSurfaceVariant: p.inkMuted,
    surfaceContainerLowest: p.ground,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surface,
    surfaceContainerHighest: p.surface,
    outline: p.border,
    outlineVariant: p.borderFaint,
  );
  const pill = StadiumBorder();
  final pillBorder = BorderSide(color: p.border);
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: p.ground,
    canvasColor: p.ground,
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: p.ground,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.ink,
      titleTextStyle: p.title(size: 20),
    ),
    cardTheme: base.cardTheme.copyWith(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.border),
      ),
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
    ),
    // Pillola alta 46, testo 800: il pulsante primario del disegno. L'alone lo aggiunge
    // `NeonButton`, che i pulsanti principali usano; questo vale per gli altri FilledButton.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        minimumSize: const Size(64, 46),
        shape: pill,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontVariations: [FontVariation('wght', 800)],
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        minimumSize: const Size(64, 46),
        shape: pill,
        side: pillBorder,
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: p.accent)),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: p.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.border),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: p.accent,
        selectedForegroundColor: p.onAccent,
        side: pillBorder,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onAccent : p.inkMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accent : p.surface,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accent : p.border,
      ),
    ),
    dividerTheme: base.dividerTheme.copyWith(color: p.borderFaint),
    snackBarTheme: base.snackBarTheme.copyWith(
      backgroundColor: p.surface,
      contentTextStyle: TextStyle(color: p.ink),
      actionTextColor: p.accent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
    ),
    extensions: [...base.extensions.values, p],
  );
}

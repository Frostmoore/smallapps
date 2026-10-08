import 'package:flutter/material.dart';

/// Il carattere a bordo pellicola: Space Mono (SIL OFL, `assets/fonts/OFL-SpaceMono.txt`).
const String kEdgeFont = 'SpaceMono';

/// I colori dell'interfaccia "C · Provino" (scelta del proprietario, 2026-10-08; artifact
/// https://claude.ai/artifact/14GrAPyvYN2bdcov5PKVoP, develop_microapps.md F6.0 punto 6).
///
/// ⚑ **Qui, a differenza di Scorte Calore, la palette cambia anche il `ColorScheme`**
/// (`withFilmLook`): in "A · Brace" la testata blu notte era un'isola dentro un'app Material
/// normale; in "C · Provino" tutta l'app e' una striscia di pellicola nera con l'arancio della
/// scritta a bordo, quindi pulsanti, campi e chip devono prendere gli stessi colori, non
/// quelli che Material ricaverebbe dal seme.
@immutable
class FilmPalette extends ThemeExtension<FilmPalette> {
  const FilmPalette({
    required this.ground,
    required this.strip,
    required this.stripRaised,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.edge,
    required this.onEdge,
    required this.border,
  });

  /// Il fondo della pagina: il nero fra un fotogramma e l'altro. Anche il colore dei fori.
  final Color ground;

  /// La pellicola: le schede, le strisce, il foglio provini.
  final Color strip;
  final Color stripRaised;

  final Color ink;
  final Color inkMuted;

  /// Le etichette delle sezioni ("IN MACCHINA").
  final Color inkFaint;

  /// L'arancio della scritta a bordo pellicola: numeri, giorni, pulsante principale.
  final Color edge;
  final Color onEdge;

  final Color border;

  /// Scuro: quello disegnato e scelto. Default dell'app (F6.1).
  static const FilmPalette dark = FilmPalette(
    ground: Color(0xFF0D0C0B),
    strip: Color(0xFF1A1714),
    stripRaised: Color(0xFF24201C),
    ink: Color(0xFFEDE6DA),
    inkMuted: Color(0xFFB3AA9C),
    inkFaint: Color(0xFF8D857A),
    edge: Color(0xFFF0A33B),
    onEdge: Color(0xFF0D0C0B),
    border: Color(0xFF2E2A26),
  );

  /// Chiaro: il tavolo luminoso. Il fondo e' il bianco caldo della luce sotto i negativi, la
  /// pellicola resta scura (un negativo e' scuro anche sul tavolo luminoso) e l'arancio si
  /// scurisce per restare leggibile sul chiaro (contrasto 4,5:1).
  static const FilmPalette light = FilmPalette(
    ground: Color(0xFFF4EFE6),
    strip: Color(0xFFFFFFFF),
    stripRaised: Color(0xFFEDE6DA),
    ink: Color(0xFF1E1A16),
    inkMuted: Color(0xFF5F574D),
    inkFaint: Color(0xFF7A7064),
    edge: Color(0xFFA85A06),
    onEdge: Color(0xFFFFFFFF),
    border: Color(0xFFDCD3C5),
  );

  static FilmPalette of(BuildContext context) =>
      Theme.of(context).extension<FilmPalette>() ?? FilmPalette.dark;

  /// La scritta a bordo pellicola: monospaziata, maiuscola, spaziata.
  TextStyle edgeText({double size = 11, Color? color, FontWeight weight = FontWeight.w400}) => TextStyle(
    fontFamily: kEdgeFont,
    fontSize: size,
    // Spaziata come la stampa a bordo pellicola; meno nei numeri grandi, dove la stessa
    // spaziatura staccava "12 GG" in cinque pezzi (visto sull'emulatore il 2026-10-08).
    letterSpacing: size >= 16 ? size * 0.04 : size * 0.18,
    fontWeight: weight,
    color: color ?? edge,
    height: 1.2,
  );

  @override
  FilmPalette copyWith() => this;

  @override
  FilmPalette lerp(ThemeExtension<FilmPalette>? other, double t) =>
      t < 0.5 ? this : (other as FilmPalette? ?? this);
}

/// Il tema di Material vestito da "C · Provino": fondo, superfici, accento e forme.
ThemeData withFilmLook(ThemeData base, FilmPalette p) {
  final scheme = base.colorScheme.copyWith(
    primary: p.edge,
    onPrimary: p.onEdge,
    primaryContainer: p.stripRaised,
    onPrimaryContainer: p.edge,
    secondary: p.edge,
    onSecondary: p.onEdge,
    // ⚑ Anche il terziario: Material lo ricava azzurro dal seme, e il chip dell'ISO "tirato"
    //   usciva celeste in mezzo all'arancio (visto sull'emulatore il 2026-10-08).
    tertiary: p.edge,
    onTertiary: p.onEdge,
    tertiaryContainer: p.stripRaised,
    onTertiaryContainer: p.edge,
    surface: p.ground,
    onSurface: p.ink,
    onSurfaceVariant: p.inkMuted,
    surfaceContainerLowest: p.ground,
    surfaceContainerLow: p.strip,
    surfaceContainer: p.strip,
    surfaceContainerHigh: p.stripRaised,
    surfaceContainerHighest: p.stripRaised,
    outline: p.inkFaint,
    outlineVariant: p.border,
  );
  // ⚑ Angoli piccoli: la pellicola e' tagliata dritta. 6 px per le schede, come nel disegno.
  const taglio = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6)));
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: p.ground,
    canvasColor: p.ground,
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: p.ground,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.ink,
    ),
    cardTheme: base.cardTheme.copyWith(color: p.strip, surfaceTintColor: Colors.transparent, shape: taglio),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(backgroundColor: p.strip, surfaceTintColor: Colors.transparent),
    dialogTheme: base.dialogTheme.copyWith(backgroundColor: p.strip, surfaceTintColor: Colors.transparent),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.edge,
        foregroundColor: p.onEdge,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    ),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: p.edge,
      foregroundColor: p.onEdge,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
    ),
    dividerTheme: base.dividerTheme.copyWith(color: p.border),
    extensions: [...base.extensions.values, p],
  );
}

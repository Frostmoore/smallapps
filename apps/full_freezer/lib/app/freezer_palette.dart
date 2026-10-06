import 'package:flutter/material.dart';

/// I colori dell'interfaccia "A · Ghiaccio" (decisione del proprietario, 2026-10-07,
/// `memory/decisioni.md`; il disegno di riferimento e' nella tela
/// https://claude.ai/artifact/9UChUVhwswddbkhnSh62aX).
///
/// ⚑ Perche' una `ThemeExtension` e non costanti: la testata blu notte, il bollino ambra e
/// i colori dei giorni devono cambiare con il tema scuro, e le pagine li leggono tutte da
/// `FreezerPalette.of(context)` senza sapere quale tema e' attivo. I colori del tema Material
/// (pulsanti, campi, snackbar) restano quelli che `MicroTheme` ricava dal seme `#0461E5`.
@immutable
class FreezerPalette extends ThemeExtension<FreezerPalette> {
  const FreezerPalette({
    required this.ground,
    required this.card,
    required this.ink,
    required this.inkMuted,
    required this.night,
    required this.nightRaised,
    required this.nightBorder,
    required this.onNight,
    required this.onNightMuted,
    required this.ice,
    required this.gaugeFill,
    required this.accent,
    required this.onAccent,
    required this.badge,
    required this.onBadge,
    required this.old,
    required this.watch,
    required this.iconTile,
    required this.onIconTile,
  });

  /// Il fondo delle pagine.
  final Color ground;

  /// Il fondo delle schede e delle righe.
  final Color card;

  /// Il testo principale e quello secondario sul fondo.
  final Color ink;
  final Color inkMuted;

  /// La testata blu notte, i suoi rilievi e i suoi bordi.
  final Color night;
  final Color nightRaised;
  final Color nightBorder;

  /// Il testo sulla testata, pieno e attenuato.
  final Color onNight;
  final Color onNightMuted;

  /// L'azzurro ghiaccio delle etichette sulla testata ("FREEZER CUCINA").
  final Color ice;

  /// Il riempimento dell'asticella in testata.
  final Color gaugeFill;

  /// Il blu del pulsante principale.
  final Color accent;
  final Color onAccent;

  /// Il bollino "N da usare".
  final Color badge;
  final Color onBadge;

  /// I giorni di chi ha superato il promemoria e di chi ci si avvicina.
  final Color old;
  final Color watch;

  /// Il riquadro dell'icona di categoria nelle righe.
  final Color iconTile;
  final Color onIconTile;

  static const FreezerPalette light = FreezerPalette(
    ground: Color(0xFFF2F6FC),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF0B1A33),
    inkMuted: Color(0xFF5B6B86),
    night: Color(0xFF0B1A33),
    nightRaised: Color(0xFF13284A),
    nightBorder: Color(0xFF2A3D5E),
    onNight: Color(0xFFFFFFFF),
    onNightMuted: Color(0xFFB9CBE8),
    ice: Color(0xFF8FB8FF),
    gaugeFill: Color(0xFF4F9BFF),
    accent: Color(0xFF0461E5),
    onAccent: Color(0xFFFFFFFF),
    badge: Color(0xFFFFB547),
    onBadge: Color(0xFF3A2400),
    // Contrasto >= 4.5:1 sul bianco delle schede: un arancio piu' chiaro non si leggerebbe.
    old: Color(0xFFC2410C),
    watch: Color(0xFFA15C00),
    iconTile: Color(0xFFE3EEFF),
    onIconTile: Color(0xFF0461E5),
  );

  /// ⚑ Nel tema scuro la testata resta "notte" ma si stacca dal fondo diventando piu'
  /// chiara di lui; giorni e bollino si schiariscono per restare leggibili sul fondo scuro.
  static const FreezerPalette dark = FreezerPalette(
    ground: Color(0xFF070F1F),
    card: Color(0xFF0F1D36),
    ink: Color(0xFFEAF1FF),
    inkMuted: Color(0xFF8FA3C7),
    night: Color(0xFF13284A),
    nightRaised: Color(0xFF1C3560),
    nightBorder: Color(0xFF2E4A7A),
    onNight: Color(0xFFFFFFFF),
    onNightMuted: Color(0xFFB9CBE8),
    ice: Color(0xFF8FB8FF),
    gaugeFill: Color(0xFF4F9BFF),
    accent: Color(0xFF2F7BFF),
    onAccent: Color(0xFFFFFFFF),
    badge: Color(0xFFFFB547),
    onBadge: Color(0xFF3A2400),
    old: Color(0xFFFF8A3D),
    watch: Color(0xFFFFC24B),
    iconTile: Color(0xFF13284A),
    onIconTile: Color(0xFF8FB8FF),
  );

  static FreezerPalette of(BuildContext context) =>
      Theme.of(context).extension<FreezerPalette>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  FreezerPalette copyWith() => this;

  @override
  FreezerPalette lerp(FreezerPalette? other, double t) => t < 0.5 || other == null ? this : other;
}

/// Il tema dell'app: quello di `MicroTheme` con il fondo e la palette di "Ghiaccio".
ThemeData withFreezerLook(ThemeData base, FreezerPalette palette) => base.copyWith(
  scaffoldBackgroundColor: palette.ground,
  appBarTheme: base.appBarTheme.copyWith(backgroundColor: palette.ground, surfaceTintColor: Colors.transparent),
  extensions: [...base.extensions.values, palette],
);

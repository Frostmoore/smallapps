import 'package:flutter/material.dart';

/// I colori dell'interfaccia "A · Brace" (scelta del proprietario, 2026-10-07; artifact
/// https://claude.ai/artifact/Q1GQPG7gKkuJJz31py8pLt, develop_microapps.md F5.0 punto 6).
///
/// ⚑ Stanno in una `ThemeExtension` e non nel `ColorScheme` di Material: la testata blu notte
/// e l'arancio brace non sono ruoli Material (primary, surface...) e forzarli li dentro
/// cambierebbe colore a pulsanti e campi che devono restare quelli del seme. Stesso schema
/// della `FreezerPalette` di Full Freezer.
@immutable
class ScortePalette extends ThemeExtension<ScortePalette> {
  const ScortePalette({
    required this.ground,
    required this.card,
    required this.ink,
    required this.inkMuted,
    required this.night,
    required this.nightRaised,
    required this.nightBorder,
    required this.onNight,
    required this.onNightMuted,
    required this.ember,
    required this.emberLabel,
    required this.flame,
    required this.onFlame,
    required this.track,
    required this.badge,
    required this.iconTile,
    required this.onIconTile,
  });

  /// Il fondo caldo dietro le schede.
  final Color ground;
  final Color card;
  final Color ink;
  final Color inkMuted;

  /// La testata della fonte principale.
  final Color night;
  final Color nightRaised;
  final Color nightBorder;
  final Color onNight;
  final Color onNightMuted;

  /// I giorni di autonomia e la barra del residuo: l'arancio della brace.
  final Color ember;

  /// L'etichetta in maiuscoletto sopra la testata ("STUFA SOGGIORNO · PELLET").
  final Color emberLabel;

  /// Il pulsante "Aggiorna scorta": l'arancio della fiamma dell'icona.
  final Color flame;
  final Color onFlame;

  /// Il binario della barra del residuo, sulla testata.
  final Color track;

  /// L'icona del calendario nel riquadro del riordino.
  final Color badge;

  /// Il riquadro dell'icona nelle righe delle altre fonti.
  final Color iconTile;
  final Color onIconTile;

  static const ScortePalette light = ScortePalette(
    ground: Color(0xFFF7F2EE),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF1B1A22),
    inkMuted: Color(0xFF6B625D),
    night: Color(0xFF14213A),
    nightRaised: Color(0xFF1C2C4B),
    nightBorder: Color(0xFF2B3B5C),
    onNight: Color(0xFFFFFFFF),
    onNightMuted: Color(0xFFC9D3E6),
    ember: Color(0xFFFF7A3D),
    emberLabel: Color(0xFFFF9A62),
    flame: Color(0xFFF4511E),
    onFlame: Color(0xFFFFFFFF),
    track: Color(0xFF23345A),
    badge: Color(0xFFFFB547),
    iconTile: Color(0xFFFFE9DE),
    onIconTile: Color(0xFFD9461A),
  );

  static const ScortePalette dark = ScortePalette(
    ground: Color(0xFF0B1220),
    card: Color(0xFF152036),
    ink: Color(0xFFEDF1F8),
    inkMuted: Color(0xFF9AA7BF),
    night: Color(0xFF1A2944),
    nightRaised: Color(0xFF233658),
    nightBorder: Color(0xFF33496F),
    onNight: Color(0xFFFFFFFF),
    onNightMuted: Color(0xFFC9D3E6),
    ember: Color(0xFFFF8A52),
    emberLabel: Color(0xFFFFA676),
    flame: Color(0xFFF4511E),
    onFlame: Color(0xFFFFFFFF),
    track: Color(0xFF2C4170),
    badge: Color(0xFFFFB547),
    iconTile: Color(0xFF3A2219),
    onIconTile: Color(0xFFFF8A52),
  );

  static ScortePalette of(BuildContext context) =>
      Theme.of(context).extension<ScortePalette>() ?? ScortePalette.light;

  @override
  ScortePalette copyWith() => this;

  @override
  ScortePalette lerp(ThemeExtension<ScortePalette>? other, double t) => t < 0.5 ? this : (other as ScortePalette? ?? this);
}

/// Il tema di Material con sopra il fondo e i colori "Brace".
ThemeData withScorteLook(ThemeData base, ScortePalette p) => base.copyWith(
  scaffoldBackgroundColor: p.ground,
  extensions: [...base.extensions.values, p],
);

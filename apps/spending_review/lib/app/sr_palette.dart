import 'package:flutter/material.dart';

import '../domain/spesa.dart';

/// Il carattere dei numeri: Space Grotesk 700 (SIL OFL, `assets/fonts/OFL-SpaceGrotesk.txt`).
/// Il totale enorme, i prezzi del tastierino, i numeri delle card (F12.1.12).
const String kNumeriFont = 'SpaceGrotesk';

/// I colori e le forme della grafica «C · Una mano» (scelta del proprietario, 2026-10-10, F12.0
/// punto 6; tavola `UnaMano.dc.html`, https://claude.ai/artifact/Y9KH2qk6PeAYKzQBTyvdhY).
/// Valori **esatti** della tavola per il tema scuro (F12.1.12); il chiaro e' derivato.
///
/// ⚑ Come QR Me (`withQrLook`): la palette cambia **anche** il `ColorScheme`, perche' i colori
/// che Material ricaverebbe dal seme (un verde spento, un terziario azzurro) stonerebbero col
/// verde della tavola.
///
/// ⚑ Il totale **non** si colora (resta [testo]): il colore lo portano la barra e il residuo,
/// cosi' il numero piu' importante si legge sempre al massimo contrasto.
@immutable
class SrPalette extends ThemeExtension<SrPalette> {
  const SrPalette({
    required this.sfondo,
    required this.fondoProfondo,
    required this.superficie,
    required this.superficieOp,
    required this.bordo,
    required this.testo,
    required this.testoLista,
    required this.testoSecondario,
    required this.accento,
    required this.suAccento,
    required this.ambraFondo,
    required this.ambraBordo,
    required this.ambraTesto,
    required this.ambraValore,
    required this.rosso,
  });

  /// Fondo delle pagine.
  final Color sfondo;

  /// Pannello del tastierino.
  final Color fondoProfondo;

  /// Tasti numerici, card, bottone Scontrino.
  final Color superficie;

  /// Tasti × − ⌫, traccia della barra, separatori della lista.
  final Color superficieOp;

  /// Bordo dei bottoni secondari.
  final Color bordo;

  final Color testo;

  /// I nomi nella lista degli articoli.
  final Color testoLista;

  /// «9 articoli · budget 60 €», «€», etichette.
  final Color testoSecondario;

  /// Totale sotto budget (barra e residuo), Cartellino, «+».
  final Color accento;

  /// Testo sui bottoni verdi.
  final Color suAccento;

  /// «Differenza da guardare», budget fra l'80 e il 100%.
  final Color ambraFondo;
  final Color ambraBordo;
  final Color ambraTesto;
  final Color ambraValore;

  /// Budget sforato. ⚑ La tavola non lo prevede: serve un terzo stato distinguibile dall'ambra
  /// **anche per luminosita'** (chi non distingue i colori vede comunque la differenza).
  final Color rosso;

  /// Scuro: quello disegnato. Default dell'app.
  static const SrPalette scuro = SrPalette(
    sfondo: Color(0xFF161B22),
    fondoProfondo: Color(0xFF0F1318),
    superficie: Color(0xFF1E252E),
    superficieOp: Color(0xFF262D36),
    bordo: Color(0xFF3A434E),
    testo: Color(0xFFE8EDF2),
    testoLista: Color(0xFFC8D0D8),
    testoSecondario: Color(0xFF9AA5B1),
    accento: Color(0xFF4ADE80),
    suAccento: Color(0xFF05230F),
    ambraFondo: Color(0xFF3B2410),
    ambraBordo: Color(0xFFB45309),
    ambraTesto: Color(0xFFFCD9A8),
    ambraValore: Color(0xFFFBBF24),
    rosso: Color(0xFFF87171),
  );

  /// Chiaro: derivato (la tavola e' solo scura). ⚑ L'accento si scurisce a #15803D come in QR Me:
  /// il #4ADE80 su bianco ha un contrasto di circa 1,6:1 e i testi verdi non si leggerebbero.
  static const SrPalette chiaro = SrPalette(
    sfondo: Color(0xFFF6F8FA),
    fondoProfondo: Color(0xFFE9EDF1),
    superficie: Color(0xFFFFFFFF),
    superficieOp: Color(0xFFDDE3E9),
    bordo: Color(0xFFC3CBD4),
    testo: Color(0xFF12171D),
    testoLista: Color(0xFF2B333C),
    testoSecondario: Color(0xFF55606C),
    accento: Color(0xFF15803D),
    suAccento: Color(0xFFFFFFFF),
    ambraFondo: Color(0xFFFFF4E5),
    ambraBordo: Color(0xFFB45309),
    ambraTesto: Color(0xFF7A3E06),
    ambraValore: Color(0xFFB45309),
    rosso: Color(0xFFB91C1C),
  );

  static SrPalette of(BuildContext context) =>
      Theme.of(context).extension<SrPalette>() ?? SrPalette.scuro;

  /// Il colore della barra e del residuo per un livello di budget (F12.1.12 punto 3).
  /// `null` senza budget: la barra non si disegna.
  Color? coloreBudget(LivelloBudget livello) => switch (livello) {
    LivelloBudget.nessuno => null,
    LivelloBudget.ok => accento,
    LivelloBudget.vicino => ambraValore,
    LivelloBudget.sforato => rosso,
  };

  /// I numeri in Space Grotesk 700 (il totale enorme e' `numeri(size: 64)`).
  TextStyle numeri({double size = 20, Color? color, double? letterSpacing}) => TextStyle(
    fontFamily: kNumeriFont,
    fontSize: size,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation('wght', 700)],
    height: 1,
    letterSpacing: letterSpacing,
    color: color ?? testo,
  );

  @override
  SrPalette copyWith() => this;

  @override
  SrPalette lerp(ThemeExtension<SrPalette>? other, double t) =>
      t < 0.5 ? this : (other as SrPalette? ?? this);
}

/// Il tema di Material vestito da «C · Una mano»: fondo, superfici, accento, pillole alte 56.
ThemeData withSrLook(ThemeData base, SrPalette p) {
  final scheme = base.colorScheme.copyWith(
    primary: p.accento,
    onPrimary: p.suAccento,
    primaryContainer: p.superficie,
    onPrimaryContainer: p.accento,
    secondary: p.accento,
    onSecondary: p.suAccento,
    secondaryContainer: p.accento.withValues(alpha: 0.18),
    onSecondaryContainer: p.testo,
    // ⚑ Anche il terziario: Material lo ricava di un altro colore dal seme (lezione di Film Tracker).
    tertiary: p.accento,
    onTertiary: p.suAccento,
    error: p.rosso,
    surface: p.sfondo,
    onSurface: p.testo,
    onSurfaceVariant: p.testoSecondario,
    surfaceContainerLowest: p.fondoProfondo,
    surfaceContainerLow: p.superficie,
    surfaceContainer: p.superficie,
    surfaceContainerHigh: p.superficie,
    surfaceContainerHighest: p.superficieOp,
    outline: p.bordo,
    outlineVariant: p.superficieOp,
  );
  const pillola = StadiumBorder();
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: p.sfondo,
    canvasColor: p.sfondo,
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: p.sfondo,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.testo,
    ),
    cardTheme: base.cardTheme.copyWith(
      color: p.superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: p.superficie,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: p.superficie,
      surfaceTintColor: Colors.transparent,
    ),
    // Pillola alta 56, testo 800: i bottoni Cartellino e Chiudi la spesa della tavola.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accento,
        foregroundColor: p.suAccento,
        minimumSize: const Size(64, 56),
        shape: pillola,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontVariations: [FontVariation('wght', 800)],
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.testo,
        backgroundColor: p.superficie,
        minimumSize: const Size(64, 56),
        shape: pillola,
        side: BorderSide(color: p.bordo),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: p.accento)),
    dividerTheme: base.dividerTheme.copyWith(color: p.superficieOp),
    snackBarTheme: base.snackBarTheme.copyWith(
      backgroundColor: p.superficie,
      contentTextStyle: TextStyle(color: p.testo),
      actionTextColor: p.accento,
    ),
    extensions: [...base.extensions.values, p],
  );
}

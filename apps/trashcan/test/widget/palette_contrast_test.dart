import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:trashcan/app/waste_presets.dart';

/// Il contrasto dei colori proposti per i tipi di rifiuto.
///
/// ⚑ Perché è un test e non un controllo a occhio: il blocco "Stasera" riempie mezzo
/// schermo con il colore del tipo di rifiuto e ci scrive sopra il nome in grande. È la cosa
/// che l'app esiste per far leggere, di sera, di fretta, spesso da un metro di distanza. Un
/// colore con contrasto scarso non produce nessun errore e passa inosservato a chi lo
/// sceglie sul proprio schermo, luminoso e vicino.
///
/// Aggiungere un colore alla tavolozza senza controllarne il contrasto è facilissimo. Con
/// questo test, non si può.
void main() {
  /// Luminanza relativa secondo WCAG 2.1.
  double luminance(Color c) {
    double channel(double value) {
      final v = value;
      return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  }

  /// Il rapporto di contrasto fra due colori, da 1 (identici) a 21 (nero su bianco).
  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  test('il nero su bianco vale 21, come da definizione', () {
    // Verifica la formula stessa: se sbagliasse, tutti i test qui sotto passerebbero o
    // fallirebbero per il motivo sbagliato.
    expect(contrast(Colors.black, Colors.white), closeTo(21, 0.1));
    expect(contrast(Colors.white, Colors.white), closeTo(1, 0.01));
  });

  test('ogni colore della tavolozza regge il testo grande scelto da MicroCard', () {
    // AA per il testo grande chiede 3:1. Il nome del tipo nel blocco "Stasera" e' a 34sp
    // in grassetto, quindi rientra abbondantemente nella definizione di testo grande.
    for (final color in WastePalette.colors) {
      final foreground = MicroCard.foregroundOn(color);
      final ratio = contrast(color, foreground);
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason: 'colore 0x${color.toARGB32().toRadixString(16)}: contrasto ${ratio.toStringAsFixed(2)}',
      );
    }
  });

  test('ogni colore della tavolozza regge anche il testo piccolo', () {
    // AA per il testo normale chiede 4.5:1. Sulla stessa card compaiono anche etichette
    // piccole ("STASERA", la data): se non reggono, meta' del blocco e' illeggibile.
    final failing = <String>[];
    for (final color in WastePalette.colors) {
      final ratio = contrast(color, MicroCard.foregroundOn(color));
      if (ratio < 4.5) {
        failing.add('0x${color.toARGB32().toRadixString(16)} = ${ratio.toStringAsFixed(2)}');
      }
    }
    expect(failing, isEmpty, reason: 'colori sotto 4.5:1 -> ${failing.join(', ')}');
  });

  test('anche i colori dei preset del wizard reggono il contrasto', () {
    // ☠ La prima versione di questo test guardava solo WastePalette.colors e passava,
    // mentre i preset del wizard usavano ancora tre colori fuori norma. I preset sono i
    // colori che vede davvero un utente nuovo: sono quelli che conta di piu' verificare,
    // perche' la maggioranza non cambiera' mai il colore proposto.
    final failing = <String>[];
    for (final preset in kWastePresets) {
      final ratio = contrast(preset.color, MicroCard.foregroundOn(preset.color));
      if (ratio < 4.5) {
        failing.add('${preset.nameKey} = ${ratio.toStringAsFixed(2)}');
      }
    }
    expect(failing, isEmpty, reason: 'preset sotto 4.5:1 -> ${failing.join(', ')}');
  });

  test('ogni preset usa un colore della tavolozza', () {
    // Un preset con un colore fuori tavolozza sfuggirebbe al controllo qui sopra la prima
    // volta che qualcuno lo cambia, e non sarebbe nemmeno riselezionabile dall'editor.
    final palette = WastePalette.colors.map((c) => c.toARGB32()).toSet();
    for (final preset in kWastePresets) {
      expect(
        palette,
        contains(preset.color.toARGB32()),
        reason: '${preset.nameKey} usa un colore che non e nella tavolozza',
      );
    }
  });

  test('nessun colore duplicato: due tipi identici non si distinguono', () {
    final values = WastePalette.colors.map((c) => c.toARGB32()).toList();
    expect(values.toSet(), hasLength(values.length));
  });
}

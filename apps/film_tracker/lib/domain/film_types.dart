/// I tipi enumerati di Film Tracker (develop_microapps.md F6.2): formato della pellicola,
/// processo di sviluppo, tipo di immagine del rullino. Dart puro.
///
/// Ogni valore porta una [key] **stabile**, che e' quella salvata nel database: non si
/// rinomina mai, anche se si rinomina il valore dell'enum (stessa regola di `FuelType.key` in
/// Scorte Calore). Per questo e' scritta a mano e non e' `name`: `35mm` e `C-41` non sono
/// nemmeno identificatori Dart validi.
///
/// I nomi visibili ("35 mm", "Medio formato 120", "Bianco e nero") NON stanno qui: la UI li
/// risolve dagli ARB con la chiave, cosi' il dominio resta traducibile senza toccarlo.
library;

/// Il formato della pellicola (`cameras.format`, `film_stocks.format`, `film_rolls.format`).
enum FilmFormat {
  mm35('35mm', defaultFrames: 36),

  /// Medio formato. ⚑ 12 pose e' il 6x6, il caso piu' comune; 6x4,5 ne fa 15-16 e 6x7 ne fa
  /// 10: chi li usa corregge il numero nel form.
  medium120('120', defaultFrames: 12),
  mm110('110', defaultFrames: 24),

  /// Grande formato: una lastra e' un'esposizione.
  large('large', defaultFrames: 1),
  other('other', defaultFrames: 36);

  const FilmFormat(this.key, {required this.defaultFrames});

  /// Valore stabile salvato nel database.
  final String key;

  /// I fotogrammi con cui il form del rullino preimposta il campo `frames` (F6.6).
  final int defaultFrames;

  /// Il formato salvato con [key]; null se la chiave e' sconosciuta (dato corrotto, o scritto
  /// da una versione futura dell'app).
  static FilmFormat? byKey(String? key) {
    for (final f in values) {
      if (f.key == key) return f;
    }
    return null;
  }
}

/// Il processo chimico di sviluppo (`film_stocks.process`, `developments.process`).
enum FilmProcess {
  c41('C-41'),
  e6('E-6'),
  bw('BW'),
  ecn2('ECN-2'),
  other('other');

  const FilmProcess(this.key);

  /// Valore stabile salvato nel database.
  final String key;

  static FilmProcess? byKey(String? key) {
    for (final p in values) {
      if (p.key == key) return p;
    }
    return null;
  }
}

/// Che cosa ritrae un'immagine del rullino (`roll_images.kind`, F6.2).
enum RollImageKind {
  contactSheet('contactSheet'),
  print('print'),
  scan('scan'),
  other('other');

  const RollImageKind(this.key);

  /// Valore stabile salvato nel database.
  final String key;

  static RollImageKind? byKey(String? key) {
    for (final k in values) {
      if (k.key == key) return k;
    }
    return null;
  }
}

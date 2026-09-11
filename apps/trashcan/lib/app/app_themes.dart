import 'package:flutter/material.dart';

/// I colori generali dell'app, fra cui l'utente sceglie (funzione Pro).
///
/// ⚑ Perché una lista chiusa e non un selettore libero: il colore scelto diventa il seme
/// del tema, e `ColorScheme.fromSeed` costruisce da lì una trentina di tinte fra cui quelle
/// dei testi. Con un seme troppo chiaro o troppo desaturato l'intera app diventa illeggibile
/// e non c'è niente che l'utente possa fare per accorgersene prima. Dieci semi scelti e
/// misurati costano una lista e tolgono la possibilità di rompersi l'app da soli.
///
/// ☠ Questi sono i **semi**, non i colori dei tipi di rifiuto: quelli stanno in
/// `WastePalette` e hanno un vincolo diverso (contrasto col testo che ci va sopra, perché
/// riempiono la card "Stasera"). Non vanno confusi né unificati.
abstract final class AppSeeds {
  /// La chiave in `SettingsStore`. Sta qui e non in `SettingKeys` di micro_core perché è
  /// una preferenza di questa app, non della piattaforma.
  static const String settingKey = 'seed_color';

  /// Il verde della raccolta differenziata: il default, e il primo della lista.
  static const Color fallback = Color(0xFF2E7D5B);

  static const List<({String key, Color color})> all = <({String key, Color color})>[
    (key: 'green', color: Color(0xFF2E7D5B)),
    (key: 'forest', color: Color(0xFF3F6B3A)),
    (key: 'teal', color: Color(0xFF1F6F78)),
    (key: 'blue', color: Color(0xFF2C5F9E)),
    (key: 'indigo', color: Color(0xFF474C93)),
    (key: 'purple', color: Color(0xFF6B4E8C)),
    (key: 'plum', color: Color(0xFF8A3F6B)),
    (key: 'terracotta', color: Color(0xFFA6503A)),
    (key: 'amber', color: Color(0xFF8A6A1F)),
    (key: 'slate', color: Color(0xFF4A5560)),
  ];

  /// Il colore salvato, o il verde se non è stato scelto niente o il valore è illeggibile.
  ///
  /// Non lancia: la preferenza può venire da un backup, da una versione futura o da una
  /// modifica a mano, e un valore storto deve far ripiegare sul default, non impedire
  /// all'app di costruire il tema.
  static Color resolve(String? saved) {
    if (saved == null) return fallback;
    for (final entry in all) {
      if (entry.key == saved) return entry.color;
    }
    return fallback;
  }

  /// La chiave di un colore, per salvarlo.
  ///
  /// Si salva la **chiave** e non il valore ARGB: se un domani si ritocca una tinta, chi
  /// l'aveva scelta si ritrova quella nuova invece di un colore orfano che non compare più
  /// fra quelli selezionabili.
  static String keyOf(Color color) {
    for (final entry in all) {
      if (entry.color.toARGB32() == color.toARGB32()) return entry.key;
    }
    return all.first.key;
  }
}

import 'package:flutter/material.dart';

/// Le icone disponibili per un tipo di rifiuto, indicizzate per **chiave stringa**.
///
/// ☠ Trappola disinnescata: il database salva `iconKey`, non `IconData.codePoint`.
/// Salvare il codepoint e ricostruire l'icona con `IconData(codePoint, fontFamily:
/// 'MaterialIcons')` rompe il tree shaking delle icone: il compilatore non riesce piu'
/// a sapere quali glifi servono, e in release Flutter o le rimuove tutte, lasciando
/// quadrati vuoti, oppure obbliga a disattivare l'ottimizzazione e a imbarcare l'intero
/// font. Con una mappa costante di riferimenti letterali il tree shaking funziona e
/// l'APK resta piccolo.
abstract final class WasteIcons {
  static const Map<String, IconData> byKey = <String, IconData>{
    'compost': Icons.compost,
    'eco': Icons.eco,
    'paper': Icons.description,
    'newspaper': Icons.newspaper,
    'box': Icons.inventory_2,
    'bottle': Icons.local_drink,
    'glass': Icons.wine_bar,
    'recycle': Icons.recycling,
    'metal': Icons.hardware,
    'trash': Icons.delete,
    'bag': Icons.shopping_bag,
    'grass': Icons.grass,
    'tree': Icons.park,
    'baby': Icons.child_friendly,
    'battery': Icons.battery_full,
    'bulb': Icons.lightbulb,
    'oil': Icons.opacity,
    'electronics': Icons.devices_other,
    'furniture': Icons.chair,
    'clothes': Icons.checkroom,
    'medicine': Icons.medical_services,
    'other': Icons.category,
  };

  /// L'icona corrispondente alla chiave, oppure un ripiego neutro.
  ///
  /// Non lancia: una chiave sconosciuta puo' arrivare da un calendario importato da
  /// una versione piu' recente dell'app, e in quel caso l'utente deve vedere un'icona
  /// generica, non un crash.
  static IconData resolve(String? key) => byKey[key] ?? Icons.category;

  /// Le chiavi in ordine di presentazione nel selettore.
  static List<String> get allKeys => byKey.keys.toList(growable: false);
}

/// La tavolozza offerta per i tipi di rifiuto.
///
/// I colori sono scelti scuri a sufficienza da reggere testo bianco: la card della home
/// usa il colore del tipo come sfondo, e un giallo chiaro renderebbe illeggibile la
/// scritta piu' importante dell'app. `MicroCard` calcola comunque il colore del testo
/// con `ThemeData.estimateBrightnessForColor`, ma partire da una tavolozza sana evita
/// il problema alla radice.
abstract final class WastePalette {
  static const List<Color> colors = <Color>[
    Color(0xFF6D8B3C), // verde oliva, organico
    Color(0xFF2E6F9E), // blu, carta
    Color(0xFFC9A227), // giallo scuro, plastica
    Color(0xFF3F7A6A), // verde acqua, vetro
    Color(0xFF7A5C3E), // marrone, metalli
    Color(0xFF5A5A5A), // grigio, indifferenziato
    Color(0xFF4C8B3F), // verde, sfalci
    Color(0xFF9C6B8E), // malva, pannolini
    Color(0xFFB05B3B), // terracotta
    Color(0xFF3D5A80), // blu notte
    Color(0xFF8A6D3B), // ocra
    Color(0xFF6B4E7A), // viola
  ];
}

/// Un tipo di rifiuto proposto durante il wizard iniziale.
///
/// Il campo [nameKey] non e' il nome visibile: e' la chiave ARB da tradurre. Il nome
/// mostrato dipende dalla lingua del dispositivo (ADR-011), e l'utente puo' comunque
/// rinominarlo.
@immutable
class WastePreset {
  const WastePreset({required this.nameKey, required this.iconKey, required this.color});

  final String nameKey;
  final String iconKey;
  final Color color;
}

/// I tipi proposti nel wizard, nell'ordine in cui compaiono.
///
/// L'elenco segue le specifiche di prodotto. Sono proposte, non vincoli: l'utente puo'
/// deselezionarli tutti e crearne di propri, perche' ogni Comune ha le sue categorie e
/// i suoi nomi.
const List<WastePreset> kWastePresets = <WastePreset>[
  WastePreset(nameKey: 'waste_organic', iconKey: 'compost', color: Color(0xFF6D8B3C)),
  WastePreset(nameKey: 'waste_paper', iconKey: 'newspaper', color: Color(0xFF2E6F9E)),
  WastePreset(nameKey: 'waste_plastic', iconKey: 'bottle', color: Color(0xFFC9A227)),
  WastePreset(nameKey: 'waste_glass', iconKey: 'glass', color: Color(0xFF3F7A6A)),
  WastePreset(nameKey: 'waste_metal', iconKey: 'metal', color: Color(0xFF7A5C3E)),
  WastePreset(nameKey: 'waste_unsorted', iconKey: 'trash', color: Color(0xFF5A5A5A)),
  WastePreset(nameKey: 'waste_garden', iconKey: 'grass', color: Color(0xFF4C8B3F)),
  WastePreset(nameKey: 'waste_nappies', iconKey: 'baby', color: Color(0xFF9C6B8E)),
  WastePreset(nameKey: 'waste_other', iconKey: 'other', color: Color(0xFFB05B3B)),
];

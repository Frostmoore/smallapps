import 'package:flutter/material.dart';

/// Le icone delle categorie, per chiave.
///
/// ☠ Nel database c'e' la **chiave**, mai l'`IconData.codePoint`: salvare il codepoint rompe
/// il tree shaking delle icone e in release produce quadrati vuoti (gia' pagato in TrashCan).
/// Per lo stesso motivo la mappa e' `const` e contiene solo icone citate per nome.
abstract final class CategoryIcons {
  static const Map<String, IconData> byKey = <String, IconData>{
    'meat': Icons.kebab_dining_outlined,
    'poultry': Icons.egg_outlined,
    'fish': Icons.set_meal_outlined,
    'vegetables': Icons.eco_outlined,
    'fruit': Icons.spa_outlined,
    'bread': Icons.bakery_dining_outlined,
    'prepared': Icons.soup_kitchen_outlined,
    'ice_cream': Icons.icecream_outlined,
    'other': Icons.inventory_2_outlined,
  };

  static IconData resolve(String? key) => byKey[key] ?? Icons.inventory_2_outlined;
}

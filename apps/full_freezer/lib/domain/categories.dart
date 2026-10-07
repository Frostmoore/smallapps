import 'package:meta/meta.dart';

/// Una categoria predefinita di alimento.
///
/// Le categorie predefinite vivono **in codice, non nel database** (develop_microapps.md
/// F4.2): nel database c'e' solo la chiave (`items.category`). Il nome visibile sta negli
/// ARB, cosi' la stessa riga si legge in italiano e in inglese senza migrare dati.
@immutable
class ItemCategory {
  const ItemCategory({
    required this.key,
    required this.defaultReminderDays,
    required this.litersPerPiece,
    required this.iconKey,
  });

  /// Chiave stabile, salvata in `items.category`. **Non si rinomina mai**: un alimento
  /// salvato con la vecchia chiave perderebbe categoria e promemoria.
  final String key;

  /// Promemoria suggerito, in giorni dal congelamento.
  ///
  /// ☠ Non e' una scadenza ne' una garanzia di sicurezza alimentare: e' un promemoria
  /// organizzativo, e la UI lo dice (develop_microapps.md F4.2, "Trappola di prodotto").
  final int defaultReminderDays;

  /// Ingombro stimato di **un pezzo** di questa categoria, in litri (F4.3b). Le altre unita'
  /// (porzioni, g, kg, confezioni, L) non dipendono dalla categoria.
  final double litersPerPiece;

  /// Chiave dell'icona, risolta nella UI. Mai un codepoint: rompe il tree shaking.
  final String iconKey;
}

/// La chiave con cui un alimento cita una categoria personalizzata: `custom:<id>`.
///
/// ⚑ Il prefisso distingue a colpo d'occhio le due famiglie: le predefinite hanno chiavi
/// fisse in codice, le personalizzate vivono nel database (`custom_categories`).
String customCategoryKey(int id) => 'custom:$id';

/// L'id della categoria personalizzata citata da [key], o null se non e' personalizzata.
int? customCategoryId(String? key) =>
    key != null && key.startsWith('custom:') ? int.tryParse(key.substring(7)) : null;

/// Le categorie predefinite, nell'ordine in cui si mostrano.
abstract final class ItemCategories {
  static const ItemCategory meatRed = ItemCategory(
    key: 'meat_red',
    defaultReminderDays: 180,
    litersPerPiece: 0.5,
    iconKey: 'meat',
  );
  static const ItemCategory meatWhite = ItemCategory(
    key: 'meat_white',
    defaultReminderDays: 180,
    litersPerPiece: 0.5,
    iconKey: 'poultry',
  );
  static const ItemCategory fish = ItemCategory(
    key: 'fish',
    defaultReminderDays: 120,
    litersPerPiece: 0.4,
    iconKey: 'fish',
  );
  static const ItemCategory vegetables = ItemCategory(
    key: 'vegetables',
    defaultReminderDays: 240,
    litersPerPiece: 0.3,
    iconKey: 'vegetables',
  );
  static const ItemCategory fruit = ItemCategory(
    key: 'fruit',
    defaultReminderDays: 240,
    litersPerPiece: 0.2,
    iconKey: 'fruit',
  );
  static const ItemCategory bread = ItemCategory(
    key: 'bread',
    defaultReminderDays: 90,
    litersPerPiece: 0.5,
    iconKey: 'bread',
  );
  static const ItemCategory prepared = ItemCategory(
    key: 'prepared',
    defaultReminderDays: 90,
    litersPerPiece: 0.4,
    iconKey: 'prepared',
  );
  static const ItemCategory iceCream = ItemCategory(
    key: 'ice_cream',
    defaultReminderDays: 180,
    litersPerPiece: 1.0,
    iconKey: 'ice_cream',
  );
  static const ItemCategory other = ItemCategory(
    key: 'other',
    defaultReminderDays: 180,
    litersPerPiece: 0.4,
    iconKey: 'other',
  );

  static const List<ItemCategory> all = <ItemCategory>[
    meatRed,
    meatWhite,
    fish,
    vegetables,
    fruit,
    bread,
    prepared,
    iceCream,
    other,
  ];

  /// La categoria con questa chiave, o `null` se la chiave e' sconosciuta (per esempio una
  /// categoria personalizzata, che vive nel database e non qui).
  static ItemCategory? byKey(String? key) {
    if (key == null) return null;
    for (final c in all) {
      if (c.key == key) return c;
    }
    return null;
  }
}

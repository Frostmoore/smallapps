/// Le unita' di misura di un alimento.
///
/// Come le categorie, vivono in codice e nel database c'e' solo la chiave
/// (`items.unit`): il nome visibile sta negli ARB.
abstract final class Units {
  static const String portions = 'portions';
  static const String pieces = 'pieces';
  static const String grams = 'g';
  static const String kilograms = 'kg';
  static const String packs = 'packs';
  static const String liters = 'l';

  /// Nell'ordine in cui compaiono come chip nell'inserimento rapido: prima le piu' usate.
  static const List<String> all = <String>[portions, pieces, packs, grams, kilograms, liters];

  /// L'unita' proposta quando non se ne e' mai usata una.
  static const String fallback = portions;

  static bool isKnown(String? key) => key != null && all.contains(key);
}

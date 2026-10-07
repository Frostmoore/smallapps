import '../data/database.dart';
import 'text_norm.dart';

/// La ricerca fra gli alimenti nel freezer (develop_microapps.md F4.8).
///
/// ⚑ **In memoria, non in SQL.** Il piano prevedeva un `LIKE` su `items.name_norm` con un
/// debounce di 200 ms. Gli alimenti nel freezer di una casa sono al massimo qualche
/// centinaio e l'app li ha gia' in memoria (`storedItemsProvider`, sempre aggiornato): un
/// filtro in Dart risponde a ogni lettera senza attese, senza debounce e senza una query
/// per tasto. E puo' cercare anche nelle **note**, che nel database non hanno una colonna
/// normalizzata: in SQL "pure" non troverebbe "purè" scritto in una nota.
///
/// Ogni parola cercata deve comparire (in qualunque ordine) nel nome o nella nota:
/// "sugo nonna" trova "Sugo della nonna". Il risultato resta nell'ordine ricevuto, che e'
/// "il piu' vecchio per primo".
List<Item> searchItems(Iterable<Item> items, String query) {
  final words = normalizeName(query).split(' ').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const <Item>[];
  return [
    for (final item in items)
      if (_matches(item, words)) item,
  ];
}

bool _matches(Item item, List<String> words) {
  // nameNorm e' gia' normalizzato dal repository; la nota no.
  final haystack = '${item.nameNorm} ${normalizeName(item.note ?? '')}';
  for (final w in words) {
    if (!haystack.contains(w)) return false;
  }
  return true;
}

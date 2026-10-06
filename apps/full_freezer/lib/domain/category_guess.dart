import 'text_norm.dart';

/// Deduce la categoria dal nome dell'alimento (F4.5: "categoria dedotta dal nome se
/// corrisponde a un termine noto").
///
/// ⚑ Un dizionario di parole, non un modello: le parole dell'italiano e dell'inglese di
/// cucina sono poche, il risultato deve essere prevedibile, e un errore costa un tocco per
/// correggerlo. Si confronta per **parola intera** sul nome normalizzato, cosi' "pane" non
/// scatta dentro "panettone" e "panna" ma "pane grattugiato" si'.
///
/// Restituisce null quando nessuna parola e' nota: meglio nessuna categoria che una
/// sbagliata, perche' la categoria porta con se' il promemoria.
String? guessCategory(String name) {
  final words = normalizeName(name).split(RegExp(r'[^a-z0-9]+')).where((w) => w.isNotEmpty);
  for (final w in words) {
    final hit = _parole[w];
    if (hit != null) return hit;
  }
  return null;
}

const String _red = 'meat_red';
const String _white = 'meat_white';
const String _fish = 'fish';
const String _veg = 'vegetables';
const String _fruit = 'fruit';
const String _bread = 'bread';
const String _prep = 'prepared';
const String _ice = 'ice_cream';

/// Parola normalizzata -> chiave di categoria. Le chiavi devono esistere in
/// `ItemCategories`: lo verifica un test.
///
/// ☠ Volutamente assenti "pasta" ("pasta al forno" e' un preparato, non un lievitato: la
/// prima parola deciderebbe male) e "ice" ("ice cubes" non e' un gelato).
const Map<String, String> _parole = <String, String>{
  // Carne rossa
  'manzo': _red, 'vitello': _red, 'maiale': _red, 'agnello': _red, 'salsiccia': _red,
  'salsicce': _red, 'spezzatino': _red, 'macinato': _red, 'bistecca': _red, 'bistecche': _red,
  'arrosto': _red, 'costine': _red, 'hamburger': _red, 'polpette': _red, 'beef': _red,
  'pork': _red, 'lamb': _red, 'sausage': _red, 'sausages': _red, 'steak': _red, 'mince': _red,
  'meatballs': _red, 'burger': _red, 'burgers': _red,
  // Carne bianca
  'pollo': _white, 'tacchino': _white, 'coniglio': _white, 'petto': _white, 'cosce': _white,
  'chicken': _white, 'turkey': _white, 'rabbit': _white,
  // Pesce
  'pesce': _fish, 'merluzzo': _fish, 'salmone': _fish, 'tonno': _fish, 'gamberi': _fish,
  'gamberetti': _fish, 'calamari': _fish, 'seppie': _fish, 'cozze': _fish, 'vongole': _fish,
  'orata': _fish, 'branzino': _fish, 'polpo': _fish, 'bastoncini': _fish, 'fish': _fish,
  'cod': _fish, 'salmon': _fish, 'tuna': _fish, 'prawns': _fish, 'shrimp': _fish, 'squid': _fish,
  // Verdura
  'piselli': _veg, 'spinaci': _veg, 'fagiolini': _veg, 'zucchine': _veg, 'carote': _veg,
  'broccoli': _veg, 'minestrone': _veg, 'verdure': _veg, 'verdura': _veg, 'funghi': _veg,
  'peperoni': _veg, 'melanzane': _veg, 'carciofi': _veg, 'cavolfiore': _veg, 'mais': _veg,
  'patate': _veg, 'peas': _veg, 'spinach': _veg, 'beans': _veg, 'carrots': _veg,
  'vegetables': _veg, 'veg': _veg, 'mushrooms': _veg, 'corn': _veg, 'potatoes': _veg,
  // Frutta
  'fragole': _fruit, 'frutti': _fruit, 'mirtilli': _fruit, 'lamponi': _fruit, 'pesche': _fruit,
  'banane': _fruit, 'frutta': _fruit, 'more': _fruit, 'ciliegie': _fruit, 'strawberries': _fruit,
  'berries': _fruit, 'blueberries': _fruit, 'raspberries': _fruit, 'fruit': _fruit,
  // Pane e lievitati
  'pane': _bread, 'panini': _bread, 'pizza': _bread, 'focaccia': _bread, 'brioche': _bread,
  'cornetti': _bread, 'croissant': _bread, 'impasto': _bread, 'bread': _bread,
  'rolls': _bread, 'dough': _bread, 'bagels': _bread,
  // Preparati e avanzi
  'lasagne': _prep, 'lasagna': _prep, 'sugo': _prep, 'ragu': _prep, 'brodo': _prep,
  'zuppa': _prep, 'avanzi': _prep, 'risotto': _prep, 'gnocchi': _prep, 'ravioli': _prep,
  'tortellini': _prep, 'cannelloni': _prep, 'parmigiana': _prep, 'polenta': _prep,
  'sauce': _prep, 'soup': _prep, 'stew': _prep, 'leftovers': _prep, 'stock': _prep,
  'curry': _prep, 'chili': _prep,
  // Gelati
  'gelato': _ice, 'gelati': _ice, 'ghiaccioli': _ice, 'sorbetto': _ice, 'semifreddo': _ice,
  'icecream': _ice, 'sorbet': _ice, 'popsicles': _ice,
};

/// Solo per i test: le chiavi usate dal dizionario.
Iterable<String> get guessedCategoryKeys => _parole.values.toSet();

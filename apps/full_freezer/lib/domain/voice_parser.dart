import 'package:meta/meta.dart';

import 'category_guess.dart';
import 'units.dart';

/// Quello che si e' capito da una frase detta a voce (F4.12).
@immutable
class ParsedItem {
  const ParsedItem({required this.name, this.quantity, this.unit, this.categoryKey, required this.confidence});

  /// Il nome dell'alimento, con l'iniziale maiuscola. Mai vuoto.
  final String name;
  final double? quantity;

  /// Una chiave di `Units`, o null se la frase non ne nomina una.
  final String? unit;

  /// La categoria dedotta dal nome (`guessCategory`), o null.
  final String? categoryKey;

  /// 1 = quantita', unita' e nome riconosciuti; 0.8 = quantita' e nome; 0.5 = solo il nome;
  /// 0 = non si e' capito niente di strutturato, e [name] e' la frase cosi' com'e'.
  final double confidence;

  @override
  String toString() => 'ParsedItem($name, $quantity, $unit, $categoryKey, $confidence)';
}

/// Trasforma "due porzioni di lasagne" in quantita' 2, unita' porzioni, nome "Lasagne".
///
/// ⚑ **Nessuna chiamata a un server** (develop_microapps.md F4.12): un dizionario e qualche
/// regola bastano per le frasi che si dicono davanti a un freezer, e un servizio remoto
/// aggiungerebbe latenza, costi, una dichiarazione di privacy e una dipendenza di rete in
/// un'app che si vanta di non averne. Il riconoscimento vocale vero lo fa il telefono;
/// qui arriva solo il testo.
///
/// ⚑ **Il ripiego non e' mai un errore.** Se la frase non ha la forma "quantita' [unita']
/// [di] nome", tutto il testo diventa il nome: l'utente lo vede nel campo e lo corregge con
/// un tocco. Un "non ho capito" lo costringerebbe a ripetere.
///
/// Si riconoscono italiano e inglese insieme, a prescindere da [locale]: chi ha il telefono
/// in inglese puo' comunque dire "mezzo chilo di macinato", e le parole delle due lingue non
/// si pestano i piedi. [locale] resta per il giorno in cui servira' (una terza lingua).
class VoiceItemParser {
  const VoiceItemParser({required this.locale});

  final String locale;

  ParsedItem parse(String utterance) {
    final original = utterance.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (original.isEmpty) return const ParsedItem(name: '', confidence: 0);

    // "un'altra", "d'agnello": l'apostrofo diventa uno spazio, cosi' "d" e "un" sono parole.
    final words = original
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    var i = 0;
    double? quantity;
    String? unit;

    // ── Quantita' ──
    final first = _number(words[i]);
    if (first != null) {
      quantity = first;
      i++;
      // "half a kilo": l'articolo dopo "half" si salta.
      if (first == 0.5 && i < words.length && (words[i] == 'a' || words[i] == 'an')) i++;
      // "un chilo e mezzo", "two and a half kilos" si gestiscono come "e mezzo" dopo l'unita'.
    }

    // ── Unita' (puo' esserci anche senza numero: "un chilo" e' gia' passato da _number) ──
    if (i < words.length) {
      final u = _unit(words[i]);
      if (u != null) {
        unit = u.key;
        quantity = (quantity ?? 1) * u.factor;
        i++;
        // "un chilo e mezzo" / "a kilo and a half"
        if (i + 1 < words.length && (words[i] == 'e' || words[i] == 'and')) {
          final half = words[i + 1] == 'mezzo' || words[i + 1] == 'mezza' || words[i + 1] == 'half';
          if (half) {
            quantity = quantity + 0.5 * u.factor;
            i += 2;
          } else if (i + 2 < words.length && words[i + 1] == 'a' && words[i + 2] == 'half') {
            quantity = quantity + 0.5 * u.factor;
            i += 3;
          }
        }
      }
    }

    // ── "di" / "of" fra quantita' e nome ──
    if (quantity != null && i < words.length && _linkers.contains(words[i])) i++;

    // Il nome si prende dal testo originale, non da quello minuscolo, per non perdere le
    // maiuscole che l'utente ha (o che il riconoscimento ha messo): si saltano le prime i
    // parole contando sulla stessa divisione.
    final nameWords = _originalWords(original).skip(i).join(' ').trim();

    if (quantity == null) {
      return ParsedItem(
        name: _capitalize(original),
        categoryKey: guessCategory(original),
        confidence: 0.5,
      );
    }
    if (nameWords.isEmpty) {
      // "due porzioni" e basta: niente nome, la frase intera va nel campo.
      return ParsedItem(name: _capitalize(original), confidence: 0);
    }

    // Un numero senza unita' ("tre hamburger") conta pezzi: lasciare l'unita' di prima
    // trasformerebbe tre hamburger in tre chili.
    final resolvedUnit = unit ?? Units.pieces;
    return ParsedItem(
      name: _capitalize(nameWords),
      quantity: quantity,
      unit: resolvedUnit,
      categoryKey: guessCategory(nameWords),
      confidence: unit == null ? 0.8 : 1,
    );
  }

  /// Le parole del testo originale, divise come quelle minuscole (apostrofi compresi).
  static List<String> _originalWords(String original) =>
      original.replaceAll(RegExp(r"[’']"), ' ').split(' ').where((w) => w.isNotEmpty).toList();

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static double? _number(String w) {
    final digits = double.tryParse(w.replaceAll(',', '.'));
    if (digits != null && digits > 0) return digits;
    return _numberWords[w];
  }

  static _UnitWord? _unit(String w) => _unitWords[w];

  static const Set<String> _linkers = {'di', 'd', 'del', 'della', 'dei', 'delle', 'of'};

  /// Numeri in lettere. "un"/"a" valgono 1 solo davanti a un'unita' o a un nome: "a" come
  /// nome non esiste, quindi non ci sono ambiguita' pratiche.
  static const Map<String, double> _numberWords = {
    'un': 1, 'uno': 1, 'una': 1, 'mezzo': 0.5, 'mezza': 0.5, 'due': 2, 'tre': 3, 'quattro': 4,
    'cinque': 5, 'sei': 6, 'sette': 7, 'otto': 8, 'nove': 9, 'dieci': 10, 'undici': 11,
    'dodici': 12, 'quindici': 15, 'venti': 20, 'trenta': 30, 'cento': 100, 'duecento': 200,
    'trecento': 300, 'quattrocento': 400, 'cinquecento': 500,
    'a': 1, 'an': 1, 'one': 1, 'half': 0.5, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6,
    'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11, 'twelve': 12, 'dozen': 12,
    'fifteen': 15, 'twenty': 20, 'thirty': 30, 'hundred': 100,
  };

  static const Map<String, _UnitWord> _unitWords = {
    'porzione': _UnitWord(Units.portions), 'porzioni': _UnitWord(Units.portions),
    'portion': _UnitWord(Units.portions), 'portions': _UnitWord(Units.portions),
    'serving': _UnitWord(Units.portions), 'servings': _UnitWord(Units.portions),
    'pezzo': _UnitWord(Units.pieces), 'pezzi': _UnitWord(Units.pieces),
    'piece': _UnitWord(Units.pieces), 'pieces': _UnitWord(Units.pieces),
    'confezione': _UnitWord(Units.packs), 'confezioni': _UnitWord(Units.packs),
    'pacco': _UnitWord(Units.packs), 'pacchi': _UnitWord(Units.packs),
    'pacchetto': _UnitWord(Units.packs), 'pacchetti': _UnitWord(Units.packs),
    'busta': _UnitWord(Units.packs), 'buste': _UnitWord(Units.packs),
    'vaschetta': _UnitWord(Units.packs), 'vaschette': _UnitWord(Units.packs),
    'pack': _UnitWord(Units.packs), 'packs': _UnitWord(Units.packs),
    'packet': _UnitWord(Units.packs), 'packets': _UnitWord(Units.packs),
    'bag': _UnitWord(Units.packs), 'bags': _UnitWord(Units.packs),
    'box': _UnitWord(Units.packs), 'boxes': _UnitWord(Units.packs),
    'grammi': _UnitWord(Units.grams), 'grammo': _UnitWord(Units.grams), 'g': _UnitWord(Units.grams),
    'gr': _UnitWord(Units.grams), 'gram': _UnitWord(Units.grams), 'grams': _UnitWord(Units.grams),
    // "un etto" = 100 g: e' cosi' che si dice dal macellaio.
    'etto': _UnitWord(Units.grams, 100), 'etti': _UnitWord(Units.grams, 100),
    'chilo': _UnitWord(Units.kilograms), 'chili': _UnitWord(Units.kilograms),
    'kg': _UnitWord(Units.kilograms), 'chilogrammo': _UnitWord(Units.kilograms),
    'chilogrammi': _UnitWord(Units.kilograms), 'kilo': _UnitWord(Units.kilograms),
    'kilos': _UnitWord(Units.kilograms), 'kilogram': _UnitWord(Units.kilograms),
    'kilograms': _UnitWord(Units.kilograms),
    'litro': _UnitWord(Units.liters), 'litri': _UnitWord(Units.liters), 'l': _UnitWord(Units.liters),
    'liter': _UnitWord(Units.liters), 'liters': _UnitWord(Units.liters),
    'litre': _UnitWord(Units.liters), 'litres': _UnitWord(Units.liters),
  };
}

class _UnitWord {
  const _UnitWord(this.key, [this.factor = 1]);

  final String key;

  /// Per le unita' che sono multipli di un'altra: "etto" = 100 grammi.
  final double factor;
}

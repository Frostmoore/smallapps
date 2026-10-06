/// Normalizzazione dei nomi per la ricerca e l'autocompletamento.
///
/// ☠ **SQLite senza ICU non e' insensibile agli accenti** (develop_microapps.md F4.8):
/// `LIKE '%pure%'` non trova "Purè". Invece di estendere SQLite, si salva accanto al nome
/// una colonna `items.nameNorm` calcolata qui, in Dart, al momento della scrittura, e si
/// cerca su quella. Cercare "pure" deve trovare "Purè"; "PANE" deve trovare "pane".
///
/// ⚑ La stessa funzione si applica al testo cercato: nome salvato e ricerca passano dalla
/// stessa porta, quindi non possono divergere.
String normalizeName(String input) {
  final lower = input.toLowerCase().trim();
  final out = StringBuffer();
  var lastWasSpace = false;
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final mapped = _senzaAccenti[ch] ?? ch;
    // Gli spazi multipli diventano uno solo: "pasta  al forno" e "pasta al forno" sono lo
    // stesso alimento per chi lo cerca.
    final isSpace = mapped.trim().isEmpty;
    if (isSpace) {
      if (!lastWasSpace) out.write(' ');
      lastWasSpace = true;
    } else {
      out.write(mapped);
      lastWasSpace = false;
    }
  }
  return out.toString();
}

/// Le lettere accentate dell'italiano e delle lingue vicine. Non serve l'intero Unicode:
/// i nomi degli alimenti si scrivono in italiano o in inglese (ADR-011).
const Map<String, String> _senzaAccenti = <String, String>{
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n', 'ß': 'ss', 'œ': 'oe', 'æ': 'ae',
  '’': "'", '`': "'",
};

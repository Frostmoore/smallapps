/// Piccole funzioni di testo comuni ai tre parser (cartellino, bilancia, scontrino).
///
/// ⚑ File in piu' rispetto all'albero della specsheet (F12.1.1): le stesse due righe
/// (minuscolo senza accenti, conta delle lettere) servivano a tre parser e al confronto.
abstract final class TestoOcr {
  static const Map<String, String> _accenti = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', //
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n', '’': "'", '`': "'",
  };

  /// Minuscolo e senza accenti: le regex delle parole chiave della specsheet sono scritte cosi'.
  static String chiave(String testo) =>
      testo.toLowerCase().split('').map((c) => _accenti[c] ?? c).join();

  /// Quante lettere (anche accentate) ci sono.
  static int lettere(String testo) => RegExp(r'[A-Za-zÀ-ÿ]').allMatches(testo).length;

  /// Una data `gg/mm/aa(aa)` (o con `.` e `-`).
  static final RegExp data = RegExp(r'\b(\d{2})[-/.](\d{2})[-/.](\d{4}|\d{2})\b');
}

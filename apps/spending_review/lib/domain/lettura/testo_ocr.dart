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

  /// Le lettere cirilliche e greche che hanno la stessa forma di una latina.
  static const Map<String, String> _gemelle = {
    'А': 'A', 'В': 'B', 'Е': 'E', 'К': 'K', 'М': 'M', 'Н': 'H', 'О': 'O', 'Р': 'P', 'С': 'C', 'Т': 'T', //
    'Х': 'X', 'У': 'Y', 'І': 'I', 'Ј': 'J', 'Ѕ': 'S', 'а': 'a', 'е': 'e', 'о': 'o', 'р': 'p', 'с': 'c', //
    'х': 'x', 'у': 'y', 'і': 'i', 'ј': 'j', 'ѕ': 's', 'Α': 'A', 'Β': 'B', 'Ε': 'E', 'Ζ': 'Z', 'Η': 'H', //
    'Ι': 'I', 'Κ': 'K', 'Μ': 'M', 'Ν': 'N', 'Ο': 'O', 'Ρ': 'P', 'Τ': 'T', 'Υ': 'Y', 'Χ': 'X', 'ο': 'o',
  };

  /// ⚑ F12.7: Vision (iOS) a volte restituisce lettere CIRILLICHE identiche alle latine anche con
  /// le lingue it-IT/en-US («ІКАО ВІССН.ВІККА» per «NUTKAO BICCH.BIRRA», «ВIЕTA/CОSTA»): a occhio
  /// sono uguali, ma nessuna regex e nessun confronto di nomi le riconosce. Si riportano alle
  /// latine prima di tutto il resto (le chiama `NumeriOcr.pulisci`).
  static String latino(String testo) {
    if (!RegExp(r'[Ͱ-ϿЀ-ӿ]').hasMatch(testo)) return testo;
    return testo.split('').map((c) => _gemelle[c] ?? c).join();
  }

  /// Quante lettere (anche accentate) ci sono.
  static int lettere(String testo) => RegExp(r'[A-Za-zÀ-ÿ]').allMatches(testo).length;

  /// Una data `gg/mm/aa(aa)` (o con `.` e `-`).
  static final RegExp data = RegExp(r'\b(\d{2})[-/.](\d{2})[-/.](\d{4}|\d{2})\b');
}

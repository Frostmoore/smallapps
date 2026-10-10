import 'package:micro_core/micro_core.dart';

/// Arrotondamenti al centesimo, **in interi** (develop_microapps.md F12.1.3).
///
/// ⚑ **Perche' «mezzo in su» (half-up) e in interi**: tutte le 9 etichette della bilancia dei
/// campioni e le 4 righe pesate di s03 tornano **solo** cosi' (s03: 0,126 kg × 7,50 = 0,945 →
/// **0,95**; l'arrotondamento bancario darebbe 0,94). `Money.operator *` di micro_core usa
/// `double.round()`: va bene per moltiplicare per un intero, **non** per i pesi (0,1 + 0,2 in
/// virgola mobile non fa 0,3).
///
/// ⚑ **Sconto percentuale: si arrotonda lo SCONTO, poi si sottrae** (come le righe «SCONTO
/// -0,40» dello scontrino). Prova c29: «2,99 −50%» stampa 1,49 (sconto 1,495 → 1,50); arrotondare
/// il prezzo finale darebbe 1,50.
abstract final class Arrotonda {
  /// `a × b / divisore`, arrotondato all'intero con la regola «mezzo in su», solo con interi.
  /// Per i valori negativi arrotonda il valore assoluto e rimette il segno (simmetrico:
  /// −0,945 → −0,95, come lo storno di una riga da 0,95).
  ///
  /// ⚑ `(2·|a·b| + d) ~/ (2·d)` e non `(|a·b| + d ~/ 2) ~/ d`: la seconda sbaglia con un
  /// divisore dispari (d = 3: 1,5 deve dare 2, e 1 + 1 = 2 ~/ 3 = 0).
  static int mezzoInSu(int a, int b, int divisore) {
    assert(divisore > 0, 'divisore $divisore');
    final prodotto = a * b;
    final assoluto = prodotto.abs();
    final arrotondato = (2 * assoluto + divisore) ~/ (2 * divisore);
    return prodotto < 0 ? -arrotondato : arrotondato;
  }

  /// Il prezzo di una quantita' a misura: `centesimiAlKg × millesimi / 1000`, half-up.
  /// 0,258 kg × 29,90 €/kg = 7,7142 → 7,71.
  static Money perMisura(Money alKgOLitro, int millesimi) =>
      Money.cents(mezzoInSu(alKgOLitro.cents, millesimi, 1000), currency: alKgOLitro.currency);

  /// L'importo dello sconto percentuale: `pieno × percento / 100`, half-up.
  /// 0,99 −30% → 0,297 → 0,30.
  static Money scontoPercentuale(Money pieno, int percento) =>
      Money.cents(mezzoInSu(pieno.cents, percento, 100), currency: pieno.currency);
}

import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

/// I 16 tasti del tastierino (F12.1.12): `7 8 9 ⌫ / 4 5 6 × / 1 2 3 − / 0 00 , +`.
enum TastoTastierino { c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c00, virgola, per, meno, cancella, piu }

/// Cosa produce un tocco: niente, una riga nuova, o «+1 all'ultima riga».
sealed class EffettoTasto {
  const EffettoTasto();
}

/// Niente da fare. [rifiutato] = il tasto non era ammesso: vibrazione d'errore.
@immutable
final class NessunEffetto extends EffettoTasto {
  const NessunEffetto({this.rifiutato = false});

  final bool rifiutato;

  @override
  bool operator ==(Object other) => other is NessunEffetto && other.rifiutato == rifiutato;

  @override
  int get hashCode => rifiutato.hashCode;

  @override
  String toString() => 'NessunEffetto(rifiutato: $rifiutato)';
}

/// Una riga nuova: [prezzo] (negativo = sconto/buono, allora [pezzi] e' 1) × [pezzi].
@immutable
final class AggiungiRiga extends EffettoTasto {
  const AggiungiRiga({required this.prezzo, required this.pezzi});

  final Money prezzo;
  final int pezzi;

  @override
  bool operator ==(Object other) => other is AggiungiRiga && other.prezzo == prezzo && other.pezzi == pezzi;

  @override
  int get hashCode => Object.hash(prezzo, pezzi);

  @override
  String toString() => 'AggiungiRiga($prezzo x $pezzi)';
}

/// «+» a display vuoto: un pezzo in piu' all'ultima riga a pezzi. ⚑ Se l'ultima e' a misura o
/// uno sconto lo rifiuta chi applica l'effetto (`SpesaRepository.incrementaUltima`): il
/// tastierino non conosce le righe.
@immutable
final class IncrementaUltima extends EffettoTasto {
  const IncrementaUltima();

  @override
  bool operator ==(Object other) => other is IncrementaUltima;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'IncrementaUltima()';
}

/// La macchina a stati del tastierino «alla cassa» (develop_microapps.md F12.1.3; risposta D2 del
/// proprietario, 2026-10-10).
///
/// ⚑ **Virgola facoltativa, come alla cassa**: `2 4 9` = 2,49 (le cifre entrano da destra come
/// centesimi) e `2 , 4 9` = 2,49 come si legge sul cartellino. Il display mostra **sempre** il
/// valore formattato, quindi `3` si vede «0,03» prima del `+`: l'errore si vede prima di aggiungere.
///
/// ⚑ **Come e' fatto dentro**: lo stato e' la sola lista dei tasti accettati, e tutto (display,
/// validita', valore) si ricava rileggendola dall'inizio (`_Lettura`). Cosi' «⌫ toglie l'ultimo
/// carattere logico» e' banale (si toglie l'ultimo tasto: cifra, virgola, «×» o «−»), e le regole
/// di validita' stanno in un posto solo: un tasto e' accettato se la lista allungata si rilegge.
/// Il tasto `00` entra come due `0`, cosi' ⌫ ne toglie uno.
///
/// ⚑ **«×» decide da solo se il numero battuto e' la quantita' o il prezzo**: senza virgola e con
/// al massimo 2 cifre (1..99) e' una **quantita'** (`3 ×` → «3 ×», poi si batte il prezzo); con la
/// virgola o con 3 cifre o piu' e' un **prezzo** (`2 4 9 ×` → «2,49 ×», poi si batte la quantita').
/// Conseguenza da sapere: 0,99 × 3 si batte `0 9 9 × 3` o `, 9 9 × 3` (oppure `3 × 9 9`).
@immutable
final class TastierinoState {
  const TastierinoState.vuoto() : _tasti = const [];

  const TastierinoState._(this._tasti);

  /// Il display precompilato con un prezzo (il «Batti a mano» del foglio del cartellino porta
  /// nel tastierino il prezzo letto, F12.1.12). Le cifre entrano «alla cassa»: 2,49 → `2 4 9`.
  factory TastierinoState.daPrezzo(Money prezzo) {
    final tasti = <TastoTastierino>[];
    if (prezzo.isNegative) tasti.add(TastoTastierino.meno);
    final cifre = prezzo.cents.abs().toString();
    for (final c in cifre.split('')) {
      tasti.add(TastoTastierino.values[int.parse(c)]);
    }
    final stato = TastierinoState._(List.unmodifiable(tasti));
    return _Lettura.di(stato._tasti) == null ? const TastierinoState.vuoto() : stato;
  }

  /// Il prezzo massimo battibile: 9999,99.
  static const int centesimiMassimi = 999999;

  /// La quantita' massima battibile con «×».
  static const int quantitaMassima = 99;

  final List<TastoTastierino> _tasti;

  /// Il testo grande a destra di «Prezzo a mano»: "2,49", "3 × 2,49", "2,49 × 3", "− 1,50", "".
  /// ⚑ Costruito SENZA intl: virgola decimale fissa, l'app e' in euro anche in inglese.
  String get display => _Lettura.di(_tasti)!.display;

  bool get vuoto => _tasti.isEmpty;

  /// Il tocco di un tasto: il nuovo stato e cosa fare.
  (TastierinoState, EffettoTasto) premi(TastoTastierino tasto) {
    switch (tasto) {
      case TastoTastierino.cancella:
        if (_tasti.isEmpty) return (this, const NessunEffetto());
        return (TastierinoState._(List.unmodifiable(_tasti.sublist(0, _tasti.length - 1))), const NessunEffetto());
      case TastoTastierino.piu:
        if (_tasti.isEmpty) return (this, const IncrementaUltima());
        final valore = _Lettura.di(_tasti)!.valore();
        if (valore == null) return (this, const NessunEffetto(rifiutato: true));
        return (const TastierinoState.vuoto(), AggiungiRiga(prezzo: valore.$1, pezzi: valore.$2));
      case TastoTastierino.c00:
        final nuovi = [..._tasti, TastoTastierino.c0, TastoTastierino.c0];
        return _prova(nuovi);
      default:
        return _prova([..._tasti, tasto]);
    }
  }

  /// Pressione lunga su ⌫: tutto via.
  TastierinoState svuota() => const TastierinoState.vuoto();

  (TastierinoState, EffettoTasto) _prova(List<TastoTastierino> nuovi) {
    if (_Lettura.di(nuovi) == null) return (this, const NessunEffetto(rifiutato: true));
    return (TastierinoState._(List.unmodifiable(nuovi)), const NessunEffetto());
  }

  @override
  bool operator ==(Object other) =>
      other is TastierinoState &&
      other._tasti.length == _tasti.length &&
      Iterable<int>.generate(_tasti.length).every((i) => other._tasti[i] == _tasti[i]);

  @override
  int get hashCode => Object.hashAll(_tasti);

  @override
  String toString() => 'TastierinoState("$display")';
}

/// Un numero in costruzione nella modalita' «cassa»: cifre intere, virgola, decimali.
final class _Numero {
  String cifre = '';
  bool virgola = false;
  String decimali = '';

  bool get vuoto => cifre.isEmpty && !virgola;

  /// Il valore in centesimi: senza virgola le cifre sono centesimi; con la virgola le cifre sono
  /// euro e i decimali (0..2) i centesimi.
  int get centesimi {
    if (!virgola) return cifre.isEmpty ? 0 : int.parse(cifre);
    final euro = cifre.isEmpty ? 0 : int.parse(cifre);
    return euro * 100 + (decimali.isEmpty ? 0 : int.parse(decimali.padRight(2, '0')));
  }

  /// Da' la cifra; false se non ci sta (gia' 2 decimali, o prezzo oltre il massimo).
  bool aggiungi(String c) {
    if (virgola) {
      if (decimali.length >= 2) return false;
      decimali += c;
    } else {
      cifre += c;
    }
    // ⚑ Cifre fino a 9: un `int.parse` di 30 zeri resterebbe 0 ma il display li mostrerebbe.
    return cifre.length <= 8 && centesimi <= TastierinoState.centesimiMassimi;
  }

  String get formattato {
    if (virgola) {
      final euro = cifre.isEmpty ? 0 : int.parse(cifre);
      return '$euro,$decimali';
    }
    final c = centesimi;
    return '${c ~/ 100},${(c % 100).toString().padLeft(2, '0')}';
  }
}

/// La rilettura della lista dei tasti: null se non e' una sequenza valida.
final class _Lettura {
  _Lettura._();

  bool negativo = false;

  /// Il primo numero battuto (prezzo, o quantita' se seguito da «×» e «corto»).
  final _Numero primo = _Numero();

  /// «×» premuto.
  bool per = false;

  /// Con «×»: il primo numero era la quantita' (true) o il prezzo (false).
  bool quantitaPrima = false;

  /// Dopo «×»: il prezzo (se [quantitaPrima]) o la quantita' (solo cifre).
  final _Numero secondo = _Numero();

  static _Lettura? di(List<TastoTastierino> tasti) {
    final l = _Lettura._();
    for (final t in tasti) {
      if (!l._applica(t)) return null;
    }
    return l;
  }

  bool _applica(TastoTastierino t) {
    switch (t) {
      case TastoTastierino.meno:
        // ⚑ Lo sconto e' un pezzo solo (F12.1.3): niente segno dentro una moltiplicazione.
        if (per) return false;
        negativo = !negativo;
        return true;
      case TastoTastierino.per:
        if (per || primo.vuoto || negativo) return false;
        per = true;
        quantitaPrima = !primo.virgola && primo.cifre.length <= 2;
        return true;
      case TastoTastierino.virgola:
        final n = _corrente;
        // La quantita' battuta dopo il prezzo e' un intero: niente virgola.
        if (per && !quantitaPrima) return false;
        if (n.virgola) return false;
        n.virgola = true;
        return true;
      case TastoTastierino.cancella || TastoTastierino.piu || TastoTastierino.c00:
        return false; // non entrano mai nella lista
      default:
        final cifra = '${t.index}'; // c0..c9 hanno indice 0..9
        if (per && !quantitaPrima) {
          if (secondo.cifre.length >= 3) return false;
          secondo.cifre += cifra;
          return true;
        }
        return _corrente.aggiungi(cifra);
    }
  }

  _Numero get _corrente => per ? secondo : primo;

  String get display {
    final segno = negativo ? '− ' : '';
    if (!per) {
      if (primo.vuoto) return negativo ? '−' : '';
      return '$segno${primo.formattato}';
    }
    if (quantitaPrima) {
      final q = int.parse(primo.cifre);
      return secondo.vuoto ? '$q ×' : '$q × ${secondo.formattato}';
    }
    return secondo.cifre.isEmpty ? '${primo.formattato} ×' : '${primo.formattato} × ${int.parse(secondo.cifre)}';
  }

  /// (prezzo, pezzi), o null se il «+» va rifiutato (valore 0, quantita' 0 o > 99, niente prezzo).
  (Money, int)? valore() {
    final int centesimi;
    final int pezzi;
    if (!per) {
      if (primo.vuoto) return null;
      centesimi = primo.centesimi;
      pezzi = 1;
    } else if (quantitaPrima) {
      if (secondo.vuoto) return null;
      centesimi = secondo.centesimi;
      pezzi = int.parse(primo.cifre);
    } else {
      if (secondo.cifre.isEmpty) return null;
      centesimi = primo.centesimi;
      pezzi = int.parse(secondo.cifre);
    }
    if (centesimi == 0 || pezzi < 1 || pezzi > TastierinoState.quantitaMassima) return null;
    return (Money.cents(negativo ? -centesimi : centesimi), pezzi);
  }
}

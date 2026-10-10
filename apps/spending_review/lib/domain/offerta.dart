import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import 'arrotonda.dart';

/// Un'offerta su una riga (develop_microapps.md F12.1.3). Le regole di calcolo sono **esattamente**
/// quelle della tabella della specsheet; i testi brevi («3x2», «−30%») li produce
/// `lib/app/labels.dart`, non il dominio.
///
/// ⚑ **Il prezzo unitario di una riga con offerta NxM e' il prezzo PIENO**, anche se il cartellino
/// mostra in grande il prezzo «effettivo» (c11: grande 1,26, piccolo 1,89, «2+1»): cosi' il totale e'
/// quello della cassa (3 pezzi di un «3x1 a 3,19» = 3,19, non 3 × 1,06 = 3,18) e una quantita' non
/// multipla di N si conta giusta.
sealed class Offerta {
  const Offerta();

  /// Il totale di [pezzi] pezzi a [prezzoUnitario] con questa offerta. Per le offerte che non
  /// dipendono dalla quantita' ([OffertaPrezzoBarrato], [OffertaPrezzoConCarta]) e'
  /// `prezzoUnitario × pezzi`.
  Money totale(Money prezzoUnitario, int pezzi);

  /// `{"tipo": "...", ...}`: va in `righe.offerta_json`.
  Map<String, Object?> toJson();

  /// Tollerante: null, tipo sconosciuto o campi fuori dai limiti → `null` (la riga resta senza
  /// offerta e il suo totale scritto non cambia: e' `righe.totale_cents`). ⚑ Un dato di una
  /// versione futura non deve far cadere la lettura dello storico.
  static Offerta? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    int? intero(String chiave) => switch (json[chiave]) {
      final int v => v,
      final num v when v == v.roundToDouble() => v.toInt(),
      _ => null,
    };
    switch (json['tipo']) {
      case 'nxm':
        final prendi = intero('prendi');
        final paghi = intero('paghi');
        if (prendi == null || paghi == null || paghi < 1 || prendi <= paghi || prendi > 99) return null;
        return OffertaNxM(prendi: prendi, paghi: paghi);
      case 'percentuale':
        final p = intero('percento');
        return (p == null || p < 1 || p > 99) ? null : OffertaPercentuale(p);
      case 'barrato':
        final c = intero('pieno');
        return (c == null || c <= 0) ? null : OffertaPrezzoBarrato(Money.cents(c));
      case 'secondo':
        final p = intero('percento');
        return (p == null || p < 1 || p > 100) ? null : OffertaSecondoAPercento(p);
      case 'carta':
        final c = intero('senza');
        return (c == null || c <= 0) ? null : OffertaPrezzoConCarta(Money.cents(c));
      default:
        return null;
    }
  }
}

/// «Prendi N paghi M»: 3x2, 2x1, «2+1» (= 3x2), «1+1» (= 2x1), «3x1».
/// `totale(p, q) = p × ((q ~/ N) × M + q % N)`.
@immutable
final class OffertaNxM extends Offerta {
  const OffertaNxM({required this.prendi, required this.paghi});

  final int prendi;
  final int paghi;

  @override
  Money totale(Money prezzoUnitario, int pezzi) =>
      prezzoUnitario * ((pezzi ~/ prendi) * paghi + pezzi % prendi);

  /// Il prezzo «effettivo» di un pezzo se se ne prendono N (c11: 1,89 × 2/3 = 1,26), half-up.
  Money effettivo(Money prezzoUnitario) =>
      Money.cents(Arrotonda.mezzoInSu(prezzoUnitario.cents, paghi, prendi), currency: prezzoUnitario.currency);

  @override
  Map<String, Object?> toJson() => {'tipo': 'nxm', 'prendi': prendi, 'paghi': paghi};

  @override
  bool operator ==(Object other) => other is OffertaNxM && other.prendi == prendi && other.paghi == paghi;

  @override
  int get hashCode => Object.hash(prendi, paghi);

  @override
  String toString() => 'OffertaNxM($prendi, $paghi)';
}

/// Sconto percentuale applicato al prezzo pieno (bollino «−30%» con il solo prezzo pieno stampato:
/// lo sconto lo fa la cassa, c28 e c30). `totale(p, q) = q × (p − sconto(p))`.
@immutable
final class OffertaPercentuale extends Offerta {
  const OffertaPercentuale(this.percento);

  /// 1..99.
  final int percento;

  /// Il prezzo di un pezzo dopo lo sconto: lo sconto arrotondato, poi sottratto.
  Money scontato(Money pieno) => pieno - Arrotonda.scontoPercentuale(pieno, percento);

  @override
  Money totale(Money prezzoUnitario, int pezzi) => scontato(prezzoUnitario) * pezzi;

  @override
  Map<String, Object?> toJson() => {'tipo': 'percentuale', 'percento': percento};

  @override
  bool operator ==(Object other) => other is OffertaPercentuale && other.percento == percento;

  @override
  int get hashCode => percento.hashCode;

  @override
  String toString() => 'OffertaPercentuale($percento)';
}

/// Prezzo gia' scontato sul cartellino, con il pieno barrato o «anziche'»: **informativa** (il
/// prezzo unitario della riga e' gia' quello scontato). `totale(p, q) = p × q`.
@immutable
final class OffertaPrezzoBarrato extends Offerta {
  const OffertaPrezzoBarrato(this.prezzoPieno);

  final Money prezzoPieno;

  @override
  Money totale(Money prezzoUnitario, int pezzi) => prezzoUnitario * pezzi;

  @override
  Map<String, Object?> toJson() => {'tipo': 'barrato', 'pieno': prezzoPieno.cents};

  @override
  bool operator ==(Object other) => other is OffertaPrezzoBarrato && other.prezzoPieno == prezzoPieno;

  @override
  int get hashCode => prezzoPieno.hashCode;

  @override
  String toString() => 'OffertaPrezzoBarrato($prezzoPieno)';
}

/// «−50% sul secondo pezzo»: in ogni coppia il secondo e' scontato.
/// `totale(p, q) = p × q − (q ~/ 2) × sconto(p)`.
@immutable
final class OffertaSecondoAPercento extends Offerta {
  const OffertaSecondoAPercento(this.percento);

  /// 1..100 (100 = il secondo gratis, che pero' i cartellini scrivono «1+1»).
  final int percento;

  @override
  Money totale(Money prezzoUnitario, int pezzi) =>
      prezzoUnitario * pezzi - Arrotonda.scontoPercentuale(prezzoUnitario, percento) * (pezzi ~/ 2);

  @override
  Map<String, Object?> toJson() => {'tipo': 'secondo', 'percento': percento};

  @override
  bool operator ==(Object other) => other is OffertaSecondoAPercento && other.percento == percento;

  @override
  int get hashCode => percento.hashCode;

  @override
  String toString() => 'OffertaSecondoAPercento($percento)';
}

/// Prezzo riservato a chi ha la carta fedelta' (informativa: il prezzo unitario e' gia' quello
/// scelto dall'utente nel foglio di conferma, risposta D4). `totale(p, q) = p × q`.
@immutable
final class OffertaPrezzoConCarta extends Offerta {
  const OffertaPrezzoConCarta(this.prezzoSenzaCarta);

  final Money prezzoSenzaCarta;

  @override
  Money totale(Money prezzoUnitario, int pezzi) => prezzoUnitario * pezzi;

  @override
  Map<String, Object?> toJson() => {'tipo': 'carta', 'senza': prezzoSenzaCarta.cents};

  @override
  bool operator ==(Object other) =>
      other is OffertaPrezzoConCarta && other.prezzoSenzaCarta == prezzoSenzaCarta;

  @override
  int get hashCode => prezzoSenzaCarta.hashCode;

  @override
  String toString() => 'OffertaPrezzoConCarta($prezzoSenzaCarta)';
}

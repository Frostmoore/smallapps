import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import 'arrotonda.dart';
import 'offerta.dart';
import 'quantita.dart';

/// Da dove viene una riga: cambia solo come la si mostra, mai il conto.
enum OrigineRiga { tastierino, cartellino, bilancia, scontrino }

/// Una riga della spesa (develop_microapps.md F12.1.3).
@immutable
final class RigaSpesa {
  const RigaSpesa({
    this.id,
    required this.nome,
    required this.quantita,
    required this.prezzoUnitario,
    this.offerta,
    this.prezzoRiferimento,
    this.unitaRiferimento,
    this.totaleStampato,
    required this.origine,
  });

  /// Il limite della colonna `righe.nome`.
  static const int nomeMassimo = 80;

  final int? id;

  /// 0..80 caratteri; '' = «Articolo» nell'interfaccia (o «Sconto» se [eSconto]).
  final String nome;
  final Quantita quantita;

  /// Per [Pezzi]: il prezzo di un pezzo (PIENO se c'e' un'offerta NxM). Per [AMisura]: €/kg o €/l.
  /// Negativo solo per le righe di sconto/buono battute con «−» (quantita' `Pezzi(1)`).
  final Money prezzoUnitario;
  final Offerta? offerta;

  /// Il prezzo al kg/l stampato sul cartellino di un prodotto a pezzi (solo informativo).
  final Money? prezzoRiferimento;
  final UnitaMisura? unitaRiferimento;

  /// Bilancia: il totale stampato sull'etichetta. Se presente **vince** sul calcolo: e' cio' che
  /// si paga, anche quando peso × prezzo non torna (F12.1.5 punto 4).
  final Money? totaleStampato;
  final OrigineRiga origine;

  /// `totaleStampato ?? (offerta?.totale(...) ?? calcolo base)` (tabella di F12.1.3).
  ///
  /// ⚑ A misura le offerte NxM non esistono (F12.1.3: si ignorano). Un `OffertaPercentuale` su
  /// una riga a misura (un bollino «−30%» su un prodotto al kg) si applica all'importo pesato,
  /// con lo stesso arrotondamento dello sconto: e' quello che fa la cassa. Le altre offerte a
  /// misura sono solo informative.
  Money get totale {
    final stampato = totaleStampato;
    if (stampato != null) return stampato;
    switch (quantita) {
      case Pezzi(:final n):
        return offerta?.totale(prezzoUnitario, n) ?? prezzoUnitario * n;
      case AMisura(:final millesimi):
        final base = Arrotonda.perMisura(prezzoUnitario, millesimi);
        final o = offerta;
        return o is OffertaPercentuale ? o.scontato(base) : base;
    }
  }

  /// Una riga di sconto o buono battuta con «−».
  bool get eSconto => prezzoUnitario.isNegative;

  /// I pezzi, o null se a misura.
  int? get pezzi => switch (quantita) {
    Pezzi(:final n) => n,
    AMisura() => null,
  };

  /// ⚑ I campi annullabili si tolgono con i `togli*` espliciti: un `null` passato a copyWith
  /// vuol dire «lascia com'e'».
  RigaSpesa copyWith({
    int? id,
    String? nome,
    Quantita? quantita,
    Money? prezzoUnitario,
    Offerta? offerta,
    bool togliOfferta = false,
    Money? prezzoRiferimento,
    UnitaMisura? unitaRiferimento,
    Money? totaleStampato,
    bool togliTotaleStampato = false,
    OrigineRiga? origine,
  }) => RigaSpesa(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    quantita: quantita ?? this.quantita,
    prezzoUnitario: prezzoUnitario ?? this.prezzoUnitario,
    offerta: togliOfferta ? null : (offerta ?? this.offerta),
    prezzoRiferimento: prezzoRiferimento ?? this.prezzoRiferimento,
    unitaRiferimento: unitaRiferimento ?? this.unitaRiferimento,
    totaleStampato: togliTotaleStampato ? null : (totaleStampato ?? this.totaleStampato),
    origine: origine ?? this.origine,
  );

  @override
  bool operator ==(Object other) =>
      other is RigaSpesa &&
      other.id == id &&
      other.nome == nome &&
      other.quantita == quantita &&
      other.prezzoUnitario == prezzoUnitario &&
      other.offerta == offerta &&
      other.prezzoRiferimento == prezzoRiferimento &&
      other.unitaRiferimento == unitaRiferimento &&
      other.totaleStampato == totaleStampato &&
      other.origine == origine;

  @override
  int get hashCode => Object.hash(
    id,
    nome,
    quantita,
    prezzoUnitario,
    offerta,
    prezzoRiferimento,
    unitaRiferimento,
    totaleStampato,
    origine,
  );

  @override
  String toString() => 'RigaSpesa($id, "$nome", $quantita x $prezzoUnitario, $offerta = $totale)';
}

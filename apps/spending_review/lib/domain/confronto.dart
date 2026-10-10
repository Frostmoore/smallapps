import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import 'lettura/scontrino_parser.dart';
import 'nomi.dart';
import 'riga_spesa.dart';

/// Una riga da guardare nel confronto fra il contato e lo scontrino (F12.1.7).
sealed class RigaSospetta {
  const RigaSospetta();

  /// Quanto in PIU' paghi rispetto al contato (negativo = paghi meno).
  Money get delta;
}

/// Stesso articolo, prezzo diverso (cartellino 7,90 · scontrino 9,40).
final class PrezzoDiverso extends RigaSospetta {
  const PrezzoDiverso(this.contata, this.scontrino);

  final RigaSpesa contata;
  final RigaScontrino scontrino;

  @override
  Money get delta => scontrino.importo - contata.totale;
}

/// Sullo scontrino ma non contato (il sacchetto).
final class SoloSulloScontrino extends RigaSospetta {
  const SoloSulloScontrino(this.scontrino);

  final RigaScontrino scontrino;

  @override
  Money get delta => scontrino.importo;
}

/// Contato ma non sullo scontrino (un articolo dimenticato dal cassiere, o lasciato).
final class NonSulloScontrino extends RigaSospetta {
  const NonSulloScontrino(this.contata);

  final RigaSpesa contata;

  @override
  Money get delta => Money.zero - contata.totale;
}

/// Due righe uguali sullo scontrino e una sola contata: «battuto due volte?».
final class ForseDoppia extends RigaSospetta {
  const ForseDoppia(this.contata, this.scontrino);

  final RigaSpesa contata;
  final RigaScontrino scontrino;

  @override
  Money get delta => scontrino.importo;
}

/// Una riga contata e la sua riga dello scontrino.
@immutable
final class Abbinamento {
  const Abbinamento(this.contata, this.scontrino);

  final RigaSpesa contata;
  final RigaScontrino scontrino;
}

/// Il risultato del confronto.
@immutable
final class EsitoConfronto {
  const EsitoConfronto({
    required this.totaleScontrino,
    required this.totaleContato,
    required this.abbinate,
    required this.sospette,
  });

  /// Il TOTALE stampato, o la somma delle righe se manca.
  final Money totaleScontrino;
  final Money totaleContato;
  final List<Abbinamento> abbinate;

  /// Ordinate per |delta| decrescente.
  final List<RigaSospetta> sospette;

  /// `totaleScontrino − totaleContato` (positivo = paghi di piu').
  Money get differenza => totaleScontrino - totaleContato;

  /// Schermata verde «Tutto torna».
  bool get tuttoTorna => differenza.isZero && sospette.isEmpty;
}

/// Una riga dello scontrino con gli sconti che la seguono gia' sommati (s06: «OFFERTA -0,40»
/// sotto i cornetti e' lo sconto dei cornetti).
final class _Voce {
  _Voce(this.riga, this.importo);

  final RigaScontrino riga;
  Money importo;
}

/// Il confronto fra le righe contate e lo scontrino letto (F12.1.7).
abstract final class Confronto {
  /// ⚑ Si confrontano **totali di riga**: «3 × 0,35» contato a mano e «ACQUA 1,05» sullo scontrino
  /// si abbinano. ⚑ L'importo e' l'indizio piu' affidabile: le descrizioni dello scontrino sono
  /// troncate a ~18-20 caratteri e abbreviate («PR COTTO AQ.AR.SA FF»).
  /// Deterministico: stesse righe, stesso esito.
  static EsitoConfronto confronta(List<RigaSpesa> contate, LetturaScontrino scontrino) {
    // 1. Dallo scontrino: articoli non stornati, sconti sommati all'articolo che precede; gli
    // storni si ignorano (le stornate sono gia' fuori). Uno sconto senza articolo prima resta
    // libero e si confronta con gli sconti battuti a mano.
    final voci = <_Voce>[];
    final scontiLiberi = <_Voce>[];
    for (final r in scontrino.righe) {
      switch (r.tipo) {
        case TipoRigaScontrino.articolo:
          if (!r.stornata) voci.add(_Voce(r, r.importo));
        case TipoRigaScontrino.sconto:
          if (voci.isEmpty) {
            scontiLiberi.add(_Voce(r, r.importo));
          } else {
            voci.last.importo = voci.last.importo + r.importo;
          }
        case TipoRigaScontrino.storno:
          break;
      }
    }
    final daScontrino = [...voci, ...scontiLiberi];
    final liberiS = [...daScontrino];
    final liberiC = [...contate];
    final abbinate = <(RigaSpesa, _Voce)>[];

    String nome(RigaSpesa r) => r.nome;

    // 2. Passata 1: stesso importo e similarita' ≥ 0,5, in ordine di similarita' decrescente.
    final coppie = <(double, RigaSpesa, _Voce)>[];
    for (final c in liberiC) {
      for (final s in liberiS) {
        if (c.totale != s.importo) continue;
        final sim = Nomi.similarita(nome(c), s.riga.descrizione);
        if (sim >= 0.5) coppie.add((sim, c, s));
      }
    }
    coppie.sort((a, b) => b.$1.compareTo(a.$1));
    for (final (_, c, s) in coppie) {
      if (!liberiC.contains(c) || !liberiS.contains(s)) continue;
      abbinate.add((c, s));
      liberiC.remove(c);
      liberiS.remove(s);
    }

    // 3. Passata 2: stesso importo, nome qualsiasi, in ordine di apparizione.
    for (final c in [...liberiC]) {
      final s = liberiS.where((s) => s.importo == c.totale).firstOrNull;
      if (s == null) continue;
      abbinate.add((c, s));
      liberiC.remove(c);
      liberiS.remove(s);
    }

    // 4. Passata 3: similarita' ≥ 0,6 e importo diverso → prezzo diverso.
    final sospette = <RigaSospetta>[];
    final diverse = <(double, RigaSpesa, _Voce)>[];
    for (final c in liberiC) {
      for (final s in liberiS) {
        final sim = Nomi.similarita(nome(c), s.riga.descrizione);
        if (sim >= 0.6) diverse.add((sim, c, s));
      }
    }
    diverse.sort((a, b) => b.$1.compareTo(a.$1));
    for (final (_, c, s) in diverse) {
      if (!liberiC.contains(c) || !liberiS.contains(s)) continue;
      sospette.add(PrezzoDiverso(c, _conImporto(s)));
      liberiC.remove(c);
      liberiS.remove(s);
    }

    // 5. Scontrino rimasto: forse battuto due volte (uguale a una gia' abbinata), o solo li'.
    for (final s in liberiS) {
      final gemella = abbinate.where((a) =>
          a.$2.importo == s.importo && Nomi.normalizza(a.$2.riga.descrizione) == Nomi.normalizza(s.riga.descrizione));
      final g = gemella.firstOrNull;
      sospette.add(g != null ? ForseDoppia(g.$1, _conImporto(s)) : SoloSulloScontrino(_conImporto(s)));
    }
    for (final c in liberiC) {
      sospette.add(NonSulloScontrino(c));
    }
    sospette.sort((a, b) => b.delta.cents.abs().compareTo(a.delta.cents.abs()));

    final totaleS = scontrino.totale ?? scontrino.sommaRighe;
    return EsitoConfronto(
      totaleScontrino: totaleS,
      totaleContato: Money.sum(contate.map((r) => r.totale)),
      abbinate: List.unmodifiable([for (final (c, s) in abbinate) Abbinamento(c, _conImporto(s))]),
      sospette: List.unmodifiable(sospette),
    );
  }

  /// La riga dello scontrino con l'importo comprensivo dei suoi sconti (quello confrontato).
  static RigaScontrino _conImporto(_Voce v) => v.importo == v.riga.importo
      ? v.riga
      : RigaScontrino(
          descrizione: v.riga.descrizione,
          importo: v.importo,
          tipo: v.riga.tipo,
          quantita: v.riga.quantita,
          prezzoUnitario: v.riga.prezzoUnitario,
          stornata: v.riga.stornata,
        );
}

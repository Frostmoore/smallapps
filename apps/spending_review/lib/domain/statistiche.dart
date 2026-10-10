import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import 'spesa.dart';

/// Una riga della tabella per negozio.
@immutable
final class VoceNegozio {
  const VoceNegozio({required this.negozioId, required this.nome, required this.spese, required this.totale});

  /// null = «Senza negozio».
  final int? negozioId;
  final String nome;
  final int spese;
  final Money totale;

  /// La spesa media (divisione intera, come `Money.average`). ⚑ Mai null: una voce esiste solo
  /// se ha almeno una spesa.
  Money get media => Money.cents(spese == 0 ? 0 : totale.cents ~/ spese);

  @override
  String toString() => 'VoceNegozio($negozioId "$nome", $spese spese, $totale)';
}

/// Un mese di spesa.
@immutable
final class MeseSpesa {
  const MeseSpesa({
    required this.anno,
    required this.mese,
    required this.spese,
    required this.totale,
    required this.sforamenti,
    required this.conBudget,
  });

  final int anno;
  final int mese;
  final int spese;

  /// Quante spese del mese hanno superato il loro budget.
  final int sforamenti;

  /// Quante spese del mese avevano un budget («2 su 5 con budget»).
  final int conBudget;
  final Money totale;

  /// null se nel mese non ci sono spese: «nessun dato» non e' «zero» (commento di `money.dart`).
  Money? get media => spese == 0 ? null : Money.cents(totale.cents ~/ spese);

  @override
  String toString() => 'MeseSpesa($anno-$mese: $spese spese, $totale, sforamenti $sforamenti/$conBudget)';
}

/// Il budget del MESE (risposta D3 del proprietario, 2026-10-10, Pro): quanto si e' speso nel
/// mese contro un tetto.
@immutable
final class BudgetMese {
  const BudgetMese({required this.anno, required this.mese, required this.tetto, required this.speso});

  final int anno;
  final int mese;
  final Money tetto;
  final Money speso;

  /// `tetto − speso` (negativo = sforato).
  Money get residuo => tetto - speso;

  /// Stesse soglie della spesa singola: vicino dall'80% al 100% incluso, sforato oltre.
  LivelloBudget get livello => livelloBudgetDi(speso, tetto);

  @override
  String toString() => 'BudgetMese($anno-$mese: $speso su $tetto)';
}

/// Le statistiche della spesa (F12.1.8, Pro).
///
/// ⚑ Il totale di ogni spesa e' `Spesa.totale`: segue la fonte (contate o scontrino) e, per le
/// spese chiuse, e' quello **scritto alla chiusura** (`Spesa.totaleSalvato`).
abstract final class StatisticheSpesa {
  /// Solo spese CHIUSE con `dataSpesa` nel mese.
  static MeseSpesa mese(List<Spesa> chiuse, int anno, int mese) {
    final del = _chiuse(chiuse).where((s) => s.dataSpesa!.year == anno && s.dataSpesa!.month == mese).toList();
    final conBudget = del.where((s) => s.budget != null).toList();
    return MeseSpesa(
      anno: anno,
      mese: mese,
      spese: del.length,
      totale: Money.sum(del.map((s) => s.totale)),
      sforamenti: conBudget.where((s) => s.sforata).length,
      conBudget: conBudget.length,
    );
  }

  /// Gli ultimi [n] mesi fino a quello di [oggi] compreso, anche vuoti (spese 0, media null),
  /// dal piu' vecchio al piu' recente (l'ordine del grafico a barre).
  static List<MeseSpesa> ultimiMesi(List<Spesa> chiuse, CivilDate oggi, {int n = 6}) {
    final primo = oggi.firstDayOfMonth.addMonths(-(n - 1));
    return [
      for (var i = 0; i < n; i++)
        () {
          final m = primo.addMonths(i);
          return mese(chiuse, m.year, m.month);
        }(),
    ];
  }

  /// Per negozio nel periodo [da, a] inclusi, ordinato per totale decrescente; «Senza negozio»
  /// (e i negozi che non sono piu' in [nomi]) in fondo, con il nome [senzaNegozio].
  static List<VoceNegozio> perNegozio(
    List<Spesa> chiuse,
    Map<int, String> nomi,
    CivilDate da,
    CivilDate a, {
    String senzaNegozio = '',
  }) {
    final perId = <int?, ({int spese, int cents})>{};
    for (final s in _nelPeriodo(chiuse, da, a)) {
      final id = (s.negozioId != null && nomi.containsKey(s.negozioId)) ? s.negozioId : null;
      final v = perId[id] ?? (spese: 0, cents: 0);
      perId[id] = (spese: v.spese + 1, cents: v.cents + s.totale.cents);
    }
    final voci = [
      for (final MapEntry(key: id, value: v) in perId.entries)
        if (id != null) VoceNegozio(negozioId: id, nome: nomi[id]!, spese: v.spese, totale: Money.cents(v.cents)),
    ]..sort((x, y) {
        final t = y.totale.compareTo(x.totale);
        return t != 0 ? t : x.nome.compareTo(y.nome);
      });
    final senza = perId[null];
    if (senza != null) {
      voci.add(VoceNegozio(negozioId: null, nome: senzaNegozio, spese: senza.spese, totale: Money.cents(senza.cents)));
    }
    return voci;
  }

  /// Spesa media nel periodo (`Money.average`: null se nessuna spesa) e sforamenti (totale >
  /// budget) sulle spese con budget.
  static ({Money? media, int sforamenti, int conBudget}) riepilogo(List<Spesa> chiuse, CivilDate da, CivilDate a) {
    final nel = _nelPeriodo(chiuse, da, a).toList();
    final conBudget = nel.where((s) => s.budget != null).toList();
    return (
      media: Money.average(nel.map((s) => s.totale)),
      sforamenti: conBudget.where((s) => s.sforata).length,
      conBudget: conBudget.length,
    );
  }

  /// Il budget del mese (D3): le spese chiuse del mese piu', se c'e' ed e' iniziata in quel mese,
  /// la spesa in corso (⚑ il tetto del mese serve proprio mentre si spende).
  static BudgetMese budgetMese(List<Spesa> chiuse, Money tetto, int anno, int mese, {Spesa? inCorso}) {
    var speso = StatisticheSpesa.mese(chiuse, anno, mese).totale;
    if (inCorso != null && inCorso.stato == StatoSpesa.inCorso) {
      final inizio = inCorso.iniziataIl.toLocal();
      if (inizio.year == anno && inizio.month == mese) speso = speso + inCorso.totale;
    }
    return BudgetMese(anno: anno, mese: mese, tetto: tetto, speso: speso);
  }

  static Iterable<Spesa> _chiuse(List<Spesa> spese) =>
      spese.where((s) => s.stato == StatoSpesa.chiusa && s.dataSpesa != null);

  static Iterable<Spesa> _nelPeriodo(List<Spesa> spese, CivilDate da, CivilDate a) =>
      _chiuse(spese).where((s) => s.dataSpesa!.isSameOrAfter(da) && s.dataSpesa!.isSameOrBefore(a));
}

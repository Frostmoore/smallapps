import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import 'quantita.dart';
import 'riga_spesa.dart';

/// Una spesa e' in corso (una sola alla volta, garantito dal database) o chiusa.
enum StatoSpesa { inCorso, chiusa }

/// Quale insieme di righe fa fede per totale e statistiche: le contate o quelle dello scontrino.
enum FonteRighe { contate, scontrino }

/// A che punto e' il budget: `vicino` = da 80% a 100% **incluso**, `sforato` = oltre il 100%.
enum LivelloBudget { nessuno, ok, vicino, sforato }

/// Il livello di [speso] rispetto a [budget] (della spesa o del mese), in interi.
///
/// ⚑ In interi e non con un rapporto in virgola mobile: i bordi (80% e 100% esatti) devono
/// cadere sempre dalla stessa parte. 80,00 su 100,00 e' `vicino`; 100,00 su 100,00 e' ancora
/// `vicino` (hai speso tutto, non di piu'); 100,01 e' `sforato`.
LivelloBudget livelloBudgetDi(Money speso, Money? budget) {
  if (budget == null || budget.cents <= 0) return LivelloBudget.nessuno;
  if (speso.cents > budget.cents) return LivelloBudget.sforato;
  if (speso.cents * 100 >= budget.cents * 80) return LivelloBudget.vicino;
  return LivelloBudget.ok;
}

/// Una spesa (develop_microapps.md F12.1.3).
///
/// ⚑ **Il budget e' della spesa, non una tabella**: la spesa grande del sabato non e' quella del
/// pane. Il «budget abituale» e' un'impostazione che precompila quello della spesa nuova; il
/// budget del **mese** (risposta D3, Pro) e' un tetto a parte, in `StatisticheSpesa.budgetMese`.
@immutable
final class Spesa {
  const Spesa({
    this.id,
    required this.stato,
    this.negozioId,
    required this.iniziataIl,
    this.chiusaIl,
    this.dataSpesa,
    this.budget,
    required this.righe,
    this.righeScontrino = const [],
    this.totaleScontrino,
    this.fonte = FonteRighe.contate,
    this.totaleSalvato,
  });

  final int? id;
  final StatoSpesa stato;
  final int? negozioId;
  final DateTime iniziataIl;
  final DateTime? chiusaIl;
  final CivilDate? dataSpesa;

  /// null = nessun budget.
  final Money? budget;

  /// Le contate, in ordine di inserimento.
  final List<RigaSpesa> righe;

  /// Origine scontrino, solo Pro. ⚑ Si affiancano alle contate, non le sostituiscono.
  final List<RigaSpesa> righeScontrino;

  /// Il TOTALE stampato sullo scontrino, se letto.
  final Money? totaleScontrino;
  final FonteRighe fonte;

  /// `spese.totale_cents` di una spesa **chiusa**: scritto alla chiusura e mai ricalcolato
  /// (F12.1.10), cosi' un cambiamento delle regole di calcolo non cambia lo storico. null per la
  /// spesa in corso (il totale si calcola dalle righe).
  /// ⚑ Campo in piu' rispetto alla firma della specsheet: senza, `totale` di una spesa chiusa
  /// sarebbe ricalcolato dalle righe e la regola «totali scritti alla chiusura» varrebbe solo nel
  /// database, non nelle statistiche.
  final Money? totaleSalvato;

  /// La somma dei totali delle righe contate.
  Money get totaleContato => Money.sum(righe.map((r) => r.totale));

  /// Il totale che fa fede: quello salvato se la spesa e' chiusa; altrimenti, con fonte
  /// scontrino, il TOTALE stampato (o la somma delle sue righe), con fonte contate il contato.
  Money get totale =>
      totaleSalvato ??
      switch (fonte) {
        FonteRighe.scontrino => totaleScontrino ?? Money.sum(righeScontrino.map((r) => r.totale)),
        FonteRighe.contate => totaleContato,
      };

  /// Somma dei pezzi + 1 per ogni riga a misura, righe di sconto escluse.
  int get articoli {
    var n = 0;
    for (final r in righe) {
      if (r.eSconto) continue;
      n += switch (r.quantita) {
        Pezzi(n: final p) => p,
        AMisura() => 1,
      };
    }
    return n;
  }

  /// `budget − totale` (negativo = sforato); null senza budget.
  Money? get residuoBudget {
    final b = budget;
    return b == null ? null : b - totale;
  }

  LivelloBudget get livelloBudget => livelloBudgetDi(totale, budget);

  /// C'era un budget e il totale lo supera (conta negli «sforamenti» delle statistiche).
  bool get sforata => livelloBudget == LivelloBudget.sforato;

  @override
  String toString() => 'Spesa($id, $stato, ${righe.length} righe, totale $totale)';
}

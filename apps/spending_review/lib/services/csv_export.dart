import 'package:micro_core/micro_core.dart';

import '../app/labels.dart';
import '../domain/quantita.dart';
import '../domain/riga_spesa.dart';
import '../domain/spesa.dart';
import '../l10n/generated/app_localizations.dart';

/// L'export CSV dello storico (Pro, `FeatureKey.csvExport`; develop_microapps.md F12.1.13).
///
/// Un file, **una riga per RIGA di spesa** (dell'insieme che fa fede: contate o scontrino), colonne:
/// `Data;Negozio;Spesa n.;Articolo;Quantita';Unita';Prezzo unitario;Offerta;Totale riga;Totale
/// spesa;Budget;Origine`. Decimali con la virgola (`Money.formatPlain(locale: 'it')`), separatore
/// `;` e BOM (`CsvWriter` di micro_core): e' quello che Excel italiano apre senza chiedere niente.
///
/// ⚑ Una spesa senza righe (registrata solo col totale) esce comunque, con l'articolo vuoto: il
/// totale della spesa non deve sparire dal foglio.
/// ☠ Nessun testo OCR grezzo esiste nel database (F12.1.10), quindi non puo' finire qui: si
/// esportano solo nome, quantita' e importi confermati.
class CsvExport {
  const CsvExport();

  String costruisci(List<Spesa> chiuse, Map<int, String> negozi, {required L l}) {
    final csv = CsvWriter()
      ..addHeader([
        l.csv_data,
        l.csv_negozio,
        l.csv_spesa,
        l.csv_articolo,
        l.csv_quantita,
        l.csv_unita,
        l.csv_prezzoUnitario,
        l.csv_offerta,
        l.csv_totaleRiga,
        l.csv_totaleSpesa,
        l.csv_budget,
        l.csv_origine,
      ]);
    String soldi(Money? m) => m == null ? '' : m.formatPlain(locale: 'it');
    for (final s in chiuse) {
      final righe = s.fonte == FonteRighe.scontrino ? s.righeScontrino : s.righe;
      final testa = [
        s.dataSpesa?.toIso() ?? '',
        s.negozioId == null ? '' : (negozi[s.negozioId] ?? ''),
        s.id,
      ];
      final coda = [soldi(s.totale), soldi(s.budget)];
      if (righe.isEmpty) {
        csv.addRow([...testa, '', '', '', '', '', '', ...coda, l.origine_scontrino]);
        continue;
      }
      for (final r in righe) {
        final (quantita, unita) = switch (r.quantita) {
          Pezzi(:final n) => ('$n', l.csv_pezzi),
          AMisura(:final millesimi, :final unita) => (millesimiTesto(millesimi), unita.name),
        };
        csv.addRow([
          ...testa,
          nomeRiga(l, r),
          quantita,
          unita,
          soldi(r.prezzoUnitario),
          offertaTesto(l, r.offerta) ?? '',
          soldi(r.totale),
          ...coda,
          origineTesto(l, r.origine),
        ]);
      }
    }
    return csv.build();
  }

  /// Il nome del file: `spending-review-AAAA-MM-GG.csv`.
  static String nomeFile(CivilDate oggi) => 'spending-review-${oggi.toIso()}.csv';
}

/// Il testo dell'origine di una riga (CSV e dettaglio).
String origineTesto(L l, OrigineRiga o) => switch (o) {
  OrigineRiga.tastierino => l.origine_tastierino,
  OrigineRiga.cartellino => l.origine_cartellino,
  OrigineRiga.bilancia => l.origine_bilancia,
  OrigineRiga.scontrino => l.origine_scontrino,
};

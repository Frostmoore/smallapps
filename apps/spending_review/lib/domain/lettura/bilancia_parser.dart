import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/riga_ocr.dart';

import '../arrotonda.dart';
import '../quantita.dart';
import 'numeri_ocr.dart';
import 'righe_visive.dart';
import 'testo_ocr.dart';

/// L'etichetta della bilancia letta (F12.1.5).
@immutable
final class LetturaBilancia {
  const LetturaBilancia({this.prodotto, this.pesoNetto, this.alKg, this.totale, this.tara, required this.coerente});

  final String? prodotto;

  /// Grammi ([UnitaMisura.kg]).
  final AMisura? pesoNetto;
  final Money? alKg;

  /// Cio' che si paga: **vince** nel conto (`RigaSpesa.totaleStampato`).
  final Money? totale;

  /// Esclusa dal conto (gia' tolta dal peso netto dalla bilancia).
  final AMisura? tara;

  /// `Arrotonda.perMisura(alKg, peso) == totale` entro 1 centesimo. false se i tre valori ci sono
  /// e non tornano (il foglio lo dice in ambra) e anche se ne manca uno: «verificato» e' una
  /// promessa che senza i tre valori non si fa.
  final bool coerente;

  /// Senza totale non e' un'etichetta utilizzabile.
  bool get utile => totale != null;

  @override
  String toString() => 'LetturaBilancia("$prodotto", $pesoNetto × $alKg = $totale, tara $tara, coerente $coerente)';
}

/// Una tripla peso × €/kg ≈ totale.
typedef _Tripla = ({NumeroOcr peso, NumeroOcr alKg, NumeroOcr totale});

/// L'interprete dell'etichetta della bilancia (F12.1.5).
///
/// ⚑ La bilancia ha gia' fatto il conto: il totale stampato e' quello della cassa. Il parser lo
/// prende sempre, e usa peso e €/kg per **verificare** la lettura (una cifra letta male quasi mai
/// lascia la tripla coerente) e per trovare i numeri quando mancano le etichette.
class BilanciaParser {
  const BilanciaParser();

  static final RegExp _netto = RegExp(r'netto|peso\s*netto|p\.?\s*netto|kg\s*netto|net\s*w|poids|gewicht|weight|peso\b');
  static final RegExp _tara = RegExp(r'\btara\b|\btare\b');
  static final RegExp _alKg = RegExp(r'/\s*kg|eur/kg|prezzo\s*/?\s*kg|prezzo\s*al\s*kg|al\s*kg|prix\s*/\s*kg|preis\s*/\s*kg|eur\s*/\s*kg|e/kg');
  static final RegExp _totale = RegExp(r'importo|prezzo\s*€?$|totale|da\s*pagare|\beuro\b|\bprix\b|\bpreis\b|\bprice\b|a\s*payer|zu\s*zahlen');
  static final RegExp _nonProdotto = RegExp(
    r'peso|tara|prezzo|confezionat|consumar|lotto|scadenza|netto|importo|totale|\beuro\b|/\s*kg|data|ingredient|conservare',
  );

  /// null = non sembra un'etichetta di bilancia (nessun totale trovabile).
  LetturaBilancia? interpreta(List<RigaOcr> righe) {
    final visive = RigheVisive.raggruppa(righe);
    if (visive.isEmpty) return null;

    // 1. Candidati: pesi a 3 decimali o «258 g»; importi a 2 decimali.
    final pesi = <NumeroOcr>[];
    final importi = <NumeroOcr>[];
    final etichetta = <NumeroOcr, String>{};
    for (var i = 0; i < visive.length; i++) {
      final v = visive[i];
      for (final n in v.numeri) {
        if (n.valore.isNegative) continue;
        (n.forma == FormaNumero.peso ? pesi : importi).add(n);
        // 2. L'etichetta: la stessa riga visiva, o quella sopra.
        etichetta[n] = TestoOcr.chiave(v.testo + (i > 0 ? '\n${visive[i - 1].testo}' : ''));
      }
      for (final m in RegExp(r'(?<![\d.,])(\d{2,5})\s*g\b', caseSensitive: false).allMatches(NumeriOcr.pulisci(v.testo))) {
        final g = NumeroOcr(valore: Money.cents(int.parse(m[1]!)), riquadro: v.riquadro, forma: FormaNumero.peso, testo: m[0]!);
        pesi.add(g);
        etichetta[g] = TestoOcr.chiave(v.testo + (i > 0 ? '\n${visive[i - 1].testo}' : ''));
      }
    }
    if (importi.isEmpty) return null;

    NumeroOcr? conEtichetta(List<NumeroOcr> lista, RegExp re, {RegExp? non}) =>
        lista.where((n) => re.hasMatch(etichetta[n]!) && (non == null || !non.hasMatch(etichetta[n]!))).firstOrNull;

    final tara = conEtichetta(pesi, _tara);
    final pesiNetti = pesi.where((p) => !identical(p, tara)).toList();
    var peso = conEtichetta(pesiNetti, _netto, non: _tara);
    var alKg = conEtichetta(importi, _alKg);
    var totale = conEtichetta(importi.where((n) => !identical(n, alKg)).toList(), _totale, non: _alKg);

    // 3. Ricerca combinatoria: la tripla coerente decide (e corregge le etichette ambigue).
    final triple = _triple(pesiNetti, importi);
    _Tripla? scelta;
    if (triple.length == 1) {
      scelta = triple.single;
    } else if (triple.length > 1) {
      // Prima quelle che rispettano le etichette trovate, poi il totale nel riquadro piu' alto.
      final rispettose = triple.where((t) =>
          (totale == null || identical(t.totale, totale)) && (alKg == null || identical(t.alKg, alKg))).toList();
      final pool = rispettose.isNotEmpty ? rispettose : triple;
      pool.sort((a, b) => b.totale.riquadro.altezza.compareTo(a.totale.riquadro.altezza));
      scelta = pool.first;
    }
    if (scelta != null) {
      peso = scelta.peso;
      alKg = scelta.alKg;
      totale = scelta.totale;
    }
    totale ??= _totaleSenzaEtichetta(importi, alKg);
    if (totale == null) return null;

    final coerente = peso != null && alKg != null &&
        (Arrotonda.perMisura(alKg.valore, peso.millesimi).cents - totale.valore.cents).abs() <= 1;

    return LetturaBilancia(
      prodotto: _prodotto(righe),
      pesoNetto: peso == null ? null : AMisura(peso.millesimi, UnitaMisura.kg),
      alKg: alKg?.valore,
      totale: totale.valore,
      tara: tara == null ? null : AMisura(tara.millesimi, UnitaMisura.kg),
      coerente: coerente,
    );
  }

  /// Vero se le righe hanno la «firma» della bilancia: un peso con 3 decimali e una tripla
  /// peso × €/kg ≈ totale. Lo usa la pagina della fotocamera per passare da sola a «Bilancia».
  bool riconosce(List<RigaOcr> righe) {
    final numeri = [for (final v in RigheVisive.raggruppa(righe)) ...v.numeri];
    final pesi = numeri.where((n) => n.forma == FormaNumero.peso).toList();
    final importi = numeri.where((n) => n.forma == FormaNumero.esplicito && !n.valore.isNegative).toList();
    return pesi.isNotEmpty && _triple(pesi, importi).isNotEmpty;
  }

  /// Tutte le triple (peso, €/kg, totale) con `|perMisura(alKg, peso) − totale| ≤ 1 cent`.
  /// ⚑ €/kg ≠ totale come riquadro, e il totale > 0: un'etichetta col solo «1,00» non e' una tripla.
  static List<_Tripla> _triple(List<NumeroOcr> pesi, List<NumeroOcr> importi) {
    final out = <_Tripla>[];
    for (final p in pesi) {
      if (p.millesimi <= 0) continue;
      for (final u in importi) {
        for (final t in importi) {
          if (identical(u, t) || t.valore.cents <= 0) continue;
          final calcolato = Arrotonda.perMisura(u.valore, p.millesimi).cents;
          if ((calcolato - t.valore.cents).abs() <= 1) out.add((peso: p, alKg: u, totale: t));
        }
      }
    }
    return out;
  }

  /// Senza tripla e senza etichetta «importo»: il numero piu' alto (di riquadro) che non e' il €/kg.
  static NumeroOcr? _totaleSenzaEtichetta(List<NumeroOcr> importi, NumeroOcr? alKg) {
    final altri = importi.where((n) => !identical(n, alKg)).toList()
      ..sort((a, b) => b.riquadro.altezza.compareTo(a.riquadro.altezza));
    return altri.firstOrNull;
  }

  /// L'insegna stampata in testa all'etichetta («PANORAMA», «Pam», «ESSELUNGA®», «REWE Center»):
  /// e' il negozio, non il prodotto.
  static final RegExp _insegna = RegExp(
    r'^\W*(pam|panorama|pam panorama|esselunga|coop|ipercoop|conad|carrefour|lidl|eurospin|despar|interspar|'
    r'eurospar|iper|bennet|md|penny|aldi|tigros|famila|crai|sigma|simply|auchan|unes|rewe|waitrose|il gigante|'
    r'naturasi)(\s+center)?\W*$',
  );

  /// Diciture d'offerta e istruzioni che non sono il prodotto (oltre a [_nonProdotto]).
  static final RegExp _nonProdottoAncora = RegExp(
    r'offert|offre|speciale|sconto|scontat|ribasso|approfitta|servare|frigorifer|cottura|origine|allevato|macellato|'
    r'\buse\s*by\b|\bkeep\b|refrigerat|gewicht|preis|betrag',
  );

  /// 5. Il nome del prodotto: fra le righe OCR di lettere (almeno 4) che non sono etichette,
  /// insegne, diciture o codici, quella scritta PIU' GRANDE (a parita', entro il 10%, la piu' in
  /// alto), unita alle altre buone della stessa riga visiva alte almeno l'80% («NEKTARINEN» +
  /// «GELB», b07).
  /// ⚑ F12.7: prima era «la prima riga visiva di lettere dall'alto», che su quasi tutte le
  /// etichette e' l'insegna del negozio («PANORAMA» su b01, visto sul simulatore iOS) o il bollino
  /// dell'offerta («OFFRE SPECIALE», b09). Il nome del prodotto e' quasi sempre la scritta piu'
  /// grande dopo il prezzo. ⚑ Sulle righe OCR e non sulle righe visive: una riga visiva unisce il
  /// nome all'insegna accanto («WR MULL KINTYRE CHDR» + «Waitrose», b08) o al prezzo (b09).
  /// ⚑ Esclusi: frasi oltre 40 caratteri (ingredienti, istruzioni) e codici con piu' di un terzo
  /// di cifre («E4954 G.03», b06).
  static String? _prodotto(List<RigaOcr> righe) {
    bool buona(RigaOcr r) {
      final t = TestoOcr.latino(r.testo).trim();
      final lettere = TestoOcr.lettere(t);
      if (lettere < 4 || t.length > 40) return false;
      if (RegExp(r'\d').allMatches(t).length * 2 > lettere) return false;
      final k = TestoOcr.chiave(t);
      if (_nonProdotto.hasMatch(k) || _nonProdottoAncora.hasMatch(k) || _insegna.hasMatch(k)) return false;
      return !TestoOcr.data.hasMatch(t) && !RegExp(r'\d[.,]\d{2}').hasMatch(t);
    }

    final buone = righe.where(buona).toList()..sort((a, b) => a.riquadro.alto.compareTo(b.riquadro.alto));
    if (buone.isEmpty) return null;
    final massima = buone.map((r) => r.riquadro.altezza).reduce(math.max);
    final scelta = buone.firstWhere((r) => r.riquadro.altezza >= 0.9 * massima);
    final riga = [
      for (final r in buone)
        if (identical(r, scelta) ||
            (r.riquadro.sovrapposizioneVerticale(scelta.riquadro) >= 0.5 && r.riquadro.altezza >= 0.8 * scelta.riquadro.altezza))
          r,
    ]..sort((a, b) => a.riquadro.sinistra.compareTo(b.riquadro.sinistra));
    final nome = riga.map((r) => TestoOcr.latino(r.testo).trim()).join(' ');
    return nome.length > 60 ? nome.substring(0, 60).trimRight() : nome;
  }
}

import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/riga_ocr.dart';

import '../arrotonda.dart';
import '../nomi.dart';
import '../quantita.dart';
import 'numeri_ocr.dart';
import 'righe_visive.dart';
import 'testo_ocr.dart';

enum TipoRigaScontrino { articolo, sconto, storno }

/// Una riga dello scontrino interpretata (F12.1.6).
@immutable
final class RigaScontrino {
  const RigaScontrino({
    required this.descrizione,
    required this.importo,
    required this.tipo,
    this.quantita,
    this.prezzoUnitario,
    this.stornata = false,
  });

  final String descrizione;

  /// Con segno: sconti e storni negativi.
  final Money importo;
  final TipoRigaScontrino tipo;

  /// Da "2 x 1,29" ([Pezzi]) o "0,248 kg x 12,50" ([AMisura]).
  final Quantita? quantita;
  final Money? prezzoUnitario;

  /// Un articolo annullato da uno storno successivo.
  final bool stornata;

  RigaScontrino copyWith({String? descrizione, Quantita? quantita, Money? prezzoUnitario, bool? stornata}) => RigaScontrino(
    descrizione: descrizione ?? this.descrizione,
    importo: importo,
    tipo: tipo,
    quantita: quantita ?? this.quantita,
    prezzoUnitario: prezzoUnitario ?? this.prezzoUnitario,
    stornata: stornata ?? this.stornata,
  );

  @override
  String toString() =>
      'RigaScontrino(${tipo.name} "$descrizione" ${importo.cents}${quantita == null ? '' : ' $quantita'}'
      '${stornata ? ' STORNATA' : ''})';
}

/// Lo scontrino letto.
///
/// ☠ Della sezione pagamento (ultime cifre della carta, autorizzazioni, terminale: s13) qui non
/// arriva **niente**: il parser la scarta e non la tiene in nessun campo (F12.1.6 punto 5).
@immutable
final class LetturaScontrino {
  const LetturaScontrino({this.negozio, this.data, required this.righe, this.totale, required this.righeIgnorate});

  /// Come e' stampato in testata (ragione sociale). Per mostrarlo: [negozioMostrato].
  final String? negozio;
  final CivilDate? data;

  /// Nell'ordine dello scontrino.
  final List<RigaScontrino> righe;

  /// Il TOTALE stampato.
  final Money? totale;

  /// Righe del corpo non capite (per il messaggio «N righe non lette»).
  final int righeIgnorate;

  /// Somma degli importi (stornate comprese: lo storno le compensa).
  Money get sommaRighe => Money.sum(righe.map((r) => r.importo));

  bool get quadra => totale != null && totale == sommaRighe;

  /// Righe articolo non stornate (confrontabile con «righe» della verita' dei campioni).
  int get articoli => righe.where((r) => r.tipo == TipoRigaScontrino.articolo && !r.stornata).length;

  /// Il nome senza «S.R.L.», «S.P.A.», «S.A.S.», «SNC» in fondo (F12.1.6 punto 3) e senza la
  /// punteggiatura finale.
  /// ⚑ F12.7: «EMME Piu Supermercati.» (s06 sull'emulatore) finiva col punto nel campo del negozio
  /// della chiusura e poi nella lista dei negozi, dove non combaciava con lo stesso negozio scritto
  /// a mano. Si toglie anche il trattino o i due punti rimasti in coda.
  String? get negozioMostrato {
    final n = negozio;
    if (n == null) return null;
    // Prima la coda («S.N.C. -» → «S.N.C»), poi la forma societaria, poi di nuovo la coda.
    final coda = RegExp(r'[\s.,;:\-–]+$');
    final s = n
        .replaceAll(coda, '')
        .replaceAll(RegExp(r'[\s,.-]*\b(s\.?\s?r\.?\s?l|s\.?\s?p\.?\s?a|s\.?\s?a\.?\s?s|s\.?\s?n\.?\s?c)\.?\s*$', caseSensitive: false), '')
        .replaceAll(coda, '')
        .trim();
    return s.isEmpty ? n : s;
  }
}

/// L'interprete dello scontrino (F12.1.6). Vale per il «documento commerciale» degli RT (dal 2020)
/// e per il vecchio «scontrino fiscale».
class ScontrinoParser {
  const ScontrinoParser();

  static final RegExp _fineTestata = RegExp(r'documento\s*commerciale|descrizione|scontrino\s*fiscale');
  static final RegExp _totale = RegExp(r'^\s*totale(\s*complessivo|\s*euro|\s*eur|\s*€)?\b');
  static final RegExp _nonNegozio = RegExp(
    r'\bvia\b|viale|piazza|p\.?zza|corso|c\.so|\btel|p\.?\s*iva|c\.?f\.|\bcap\b|\d{5}|documento|commerciale|benvenut|grazie|arrivederci|^\W*$|'
    // ⚑ Oltre alla specsheet: la provincia «(IM)» delle righe dell'indirizzo (s13) e le diciture
    // legali delle cooperative (s15 «Iscrizione Albo Cooperative»).
    r'\([a-z]{2}\)|iscrizion|\balbo\b|cooperativ|mutualit|capitale\s*soc|\brea\b|registro|'
    // …e le intestazioni di colonna quando la testata finisce al primo importo (s13, s15).
    r'prezzo|^\s*euro\s*$|\biva\b',
  );
  static final RegExp _quantita = RegExp(r'^\s*(\d{1,3})\s*[x×*]\s*(\d+[.,]\d{2})\s*$');
  static final RegExp _pesata = RegExp(r'(\d+[.,]\d{3})\s*kg\s*[x×*]\s*(\d+[.,]\d{2})');
  static final RegExp _parolaSconto = RegExp(r'sconto|offerta|promo|buono|coupon|risparmio');
  static final RegExp _storno = RegExp(r'storno|annull|\breso\b|correzione');
  static final RegExp _ignorateMute = RegExp(
    r'subtot|sub\s*tot|di\s*cui\s*iva|totale\s*iva|n\.?\s*articoli|^\s*articoli|^\s*pezzi\b|^\s*descrizione|prezzo\s*\(?\s*(€|e)?\s*\)?\s*$|'
    r'^\s*iva\b|^\s*euro\s*$|^\s*€?\s*$|^\s*\(?e\)?\s*$|t.?tale\s*parziale',
  );
  static final RegExp _tokenIva = RegExp(r'(\s+(\d{1,2}\s*%|[abcd]|vi|\*))+\s*$', caseSensitive: false);
  static final RegExp _quantitaInTesta = RegExp(r'^(\d{1,2})\s+[a-z]');

  LetturaScontrino interpreta(List<RigaOcr> righe, {DateTime? oggi}) {
    final visive = RigheVisive.raggruppa(righe);
    final testi = [for (final v in visive) NumeriOcr.pulisci(v.testo)];
    final chiavi = [for (final t in testi) TestoOcr.chiave(t)];

    // 2. Zone: testata, corpo (fino al totale incluso), piede.
    // ⚑ La parola che chiude la testata vale solo se viene PRIMA del primo importo: nel vecchio
    // formato «SCONTRINO FISCALE N. 201» sta in fondo (s09), e la testata finirebbe dopo il totale.
    final primoImporto = visive.indexWhere((v) => v.importoADestra != null);
    final parola = chiavi.indexWhere(_fineTestata.hasMatch);
    var inizioCorpo = (parola >= 0 && (primoImporto < 0 || parola <= primoImporto)) ? parola : primoImporto;
    if (inizioCorpo < 0) inizioCorpo = visive.length;
    // Il TOTALE: una riga «totale…» con il suo importo (sulla riga o, se l'OCR l'ha messo a capo,
    // sulla riga sotto fatta di soli numeri). Con piu' totali vince «complessivo», poi l'ultimo.
    // ⚑ Una riga «totale» SENZA importo non e' il totale («TOTALE PEZZI: 13» di s11).
    var rigaTotale = -1;
    var complessivo = false;
    Money? totale;
    // ⚑ F12.7 (Vision su s01: «TOTALE COMPLESSIVO» letto, il suo 11,85 no): una riga totale senza
    // importo chiude comunque il corpo se non ce n'e' una con l'importo, cosi' «Pagamento
    // elettronico 11,85» sotto non diventa un articolo e il totale si ricava da «pagato − resto»
    // e dalla somma delle righe (`_verificaTotale`), che devono concordare.
    var totaleSenzaImporto = -1;
    for (var i = inizioCorpo; i < visive.length; i++) {
      final m = _totale.firstMatch(chiavi[i]);
      if (m == null) continue;
      final dopo = chiavi[i].substring(m.end);
      if (RegExp(r'^\s*(iva|parziale|pezzi|articoli|n\.)').hasMatch(dopo)) continue;
      final eComplessivo = (m[1] ?? '').contains('complessivo');
      if (complessivo && !eComplessivo) continue;
      final importo = _importoTotale(visive, testi, i);
      if (importo == null) {
        if (totaleSenzaImporto < 0) totaleSenzaImporto = i;
        continue;
      }
      rigaTotale = i;
      complessivo = eComplessivo;
      totale = importo;
    }
    final fineCorpo = rigaTotale >= 0 ? rigaTotale : (totaleSenzaImporto >= 0 ? totaleSenzaImporto : visive.length);

    // 3. Negozio: la prima riga buona della testata.
    // ⚑ La prima e non quella con «S.R.L.»: e' l'insegna (INTERSPAR, IPERSIDIS), cioe' il nome con
    // cui l'utente chiama il negozio; la ragione sociale sotto e' spesso un'altra («MAIORA S.R.L.»).
    // Provato il contrario sul banco: guadagna s11 e perde s07 e s16.
    String? negozio;
    for (var i = 0; i < inizioCorpo && i < visive.length; i++) {
      final t = testi[i].trim();
      // ⚑ Confidenza ≥ 0,7: il logo stampato in grafica (s03 «OS ENLOD») esce come testo a caso.
      if (TestoOcr.lettere(t) < 4 || _nonNegozio.hasMatch(chiavi[i]) || visive[i].confidenza < 0.7) continue;
      negozio = t;
      break;
    }

    // 4. Corpo.
    final out = <RigaScontrino>[];
    // La riga visiva da cui viene ogni riga di [out] (per il totale ricavato dalla somma, sotto).
    final origine = <int>[];
    final ignorateIn = <int>{};
    var ignorate = 0;
    // ⚑ Una CODA e non una sola descrizione: in s13 l'OCR legge prima due descrizioni e poi i
    // loro due prezzi (colonne lette a blocchi). Si abbinano nell'ordine.
    final descrizioniPendenti = <String>[];
    String? prossimaDescrizione() => descrizioniPendenti.isEmpty ? null : descrizioniPendenti.removeAt(0);
    // Una quantita' letta su una riga sua, in attesa dell'articolo successivo.
    ({Quantita q, Money unitario})? quantitaPendente;

    void metti(int i, RigaScontrino r) {
      out.add(r);
      origine.add(i);
    }

    void aggiungiArticolo(int i, RigaScontrino r) {
      var riga = r;
      final qp = quantitaPendente;
      if (qp != null) {
        riga = riga.copyWith(quantita: qp.q, prezzoUnitario: qp.unitario);
        quantitaPendente = null;
      }
      metti(i, riga);
    }

    final inizio = inizioCorpo < visive.length && _fineTestata.hasMatch(chiavi[inizioCorpo]) ? inizioCorpo + 1 : inizioCorpo;
    for (var i = inizio; i < fineCorpo; i++) {
      final v = visive[i];
      final t = testi[i];
      final k = chiavi[i];
      if (_ignorateMute.hasMatch(k) && TestoOcr.lettere(t) > 0) {
        descrizioniPendenti.clear();
        continue;
      }

      // Pesata: «0,248 kg x 12,50 €/kg», con o senza l'importo sulla stessa riga.
      final pesata = _pesata.firstMatch(t);
      if (pesata != null) {
        final grammi = _intero(pesata[1]!);
        final alKg = Money.cents(_intero(pesata[2]!));
        final q = AMisura(grammi, UnitaMisura.kg);
        final importo = _importoDopo(v, pesata.end, t);
        if (importo != null) {
          aggiungiArticolo(i, RigaScontrino(
            descrizione: _pulisciDescrizione(t.substring(0, pesata.start)).isNotEmpty
                ? _pulisciDescrizione(t.substring(0, pesata.start))
                : (prossimaDescrizione() ?? ''),
            importo: importo,
            tipo: TipoRigaScontrino.articolo,
            quantita: q,
            prezzoUnitario: alKg,
          ));
        } else if (!_attacca(out, q, alKg, (r) => Arrotonda.perMisura(alKg, grammi) == r.importo)) {
          quantitaPendente = (q: q, unitario: alKg);
        }
        continue;
      }

      // Pesata senza «kg x» (s03: «0,248  12,50  3,10»): un peso a 3 decimali e due importi con
      // peso × €/kg = importo. ⚑ Il conto la riconosce: due numeri qualunque non tornano.
      final senzaKg = _pesataSenzaEtichetta(v);
      if (senzaKg != null) {
        aggiungiArticolo(i, RigaScontrino(
          descrizione: TestoOcr.lettere(t) >= 2 ? _pulisciDescrizione(t.replaceAll(RegExp(r'\d+[.,]\d+'), '')) : (prossimaDescrizione() ?? ''),
          importo: senzaKg.importo,
          tipo: TipoRigaScontrino.articolo,
          quantita: AMisura(senzaKg.grammi, UnitaMisura.kg),
          prezzoUnitario: senzaKg.alKg,
        ));
        continue;
      }

      // Quantita' su una riga sua: «2 x 1,29».
      final qm = _quantita.firstMatch(t);
      if (qm != null) {
        final n = int.parse(qm[1]!);
        final p = Money.cents(_intero(qm[2]!));
        final q = Pezzi(n);
        if (!_attacca(out, q, p, (r) => ((p * n).cents - r.importo.cents).abs() <= 1)) {
          quantitaPendente = (q: q, unitario: p);
        }
        continue;
      }

      final importo = _importoDi(v);
      if (importo == null) {
        // Una descrizione senza prezzo: lo scontrino (o l'OCR) l'ha messa sulla riga sopra.
        if (TestoOcr.lettere(t) >= 2) {
          descrizioniPendenti.add(_pulisciDescrizione(t));
        } else if (t.trim().isNotEmpty) {
          ignorate++;
          ignorateIn.add(i);
        }
        continue;
      }
      var descrizione = _descrizioneDi(v, t);
      final soloImporto = TestoOcr.lettere(descrizione) < 2 && !RegExp(r'\d').hasMatch(descrizione);
      if (soloImporto) descrizione = prossimaDescrizione() ?? '';

      if (_storno.hasMatch(k)) {
        final negativo = Money.cents(-importo.cents.abs());
        metti(i, RigaScontrino(descrizione: descrizione, importo: negativo, tipo: TipoRigaScontrino.storno));
        _marcaStornata(out, negativo, descrizione);
        continue;
      }
      if (importo.isNegative || _parolaSconto.hasMatch(k)) {
        metti(i, RigaScontrino(
          descrizione: descrizione,
          importo: Money.cents(-importo.cents.abs()),
          tipo: TipoRigaScontrino.sconto,
        ));
        continue;
      }
      // ⚑ Oltre la specsheet («almeno 2 lettere»): una riga fatta del SOLO importo nella colonna dei
      // prezzi e' un articolo di cui l'OCR ha perso la descrizione (s09, s03: le descrizioni
      // stampate piu' chiare o storte non si leggono). Conta nel totale e si mostra come «Articolo».
      // Una riga con altre cifre e nessuna parola resta ignorata (un codice, un orario).
      if (TestoOcr.lettere(descrizione) < 2 && !soloImporto) {
        ignorate++;
        ignorateIn.add(i);
        continue;
      }
      // Quantita' in testa alla descrizione (s11 «3 COPERTO/ANTIPASTO 3,90»).
      final testa = _quantitaInTesta.firstMatch(TestoOcr.chiave(descrizione));
      if (testa != null && quantitaPendente == null) {
        final n = int.parse(testa[1]!);
        final divisibile = n > 0 && importo.cents % n == 0;
        aggiungiArticolo(i, RigaScontrino(
          descrizione: descrizione,
          importo: importo,
          tipo: TipoRigaScontrino.articolo,
          quantita: divisibile ? Pezzi(n) : null,
          prezzoUnitario: divisibile ? Money.cents(importo.cents ~/ n) : null,
        ));
        continue;
      }
      aggiungiArticolo(i, RigaScontrino(descrizione: descrizione, importo: importo, tipo: TipoRigaScontrino.articolo));
    }

    // Nessuna riga «TOTALE» (s03, scontrino della bilancia): e' totale l'ultimo importo del corpo
    // che vale esattamente la somma delle righe prima di lui. ⚑ La somma lo rende sicuro: un
    // articolo qualunque non vale la somma di tutti gli altri.
    if (totale == null && out.length >= 2) {
      final ultimoArticolo = origine.reduce((a, b) => a > b ? a : b);
      final somma = Money.sum(out.map((r) => r.importo));
      // Una riga DOPO l'ultimo articolo (anche una presa per quantita', s03 «04 × € 7,39»)…
      for (var j = ultimoArticolo + 1; j < fineCorpo && totale == null; j++) {
        final importo = _importoTotale(visive, testi, j, ovunque: true);
        if (importo != null && importo == somma) {
          totale = importo;
          if (ignorateIn.remove(j)) ignorate--;
        }
      }
      // …o l'ultimo «articolo» stesso, se vale la somma di tutti quelli prima.
      final ultimo = out.last;
      if (totale == null && ultimo.importo == Money.sum(out.take(out.length - 1).map((r) => r.importo))) {
        totale = ultimo.importo;
        out.removeLast();
        origine.removeLast();
      }
    }

    // Verifica del totale: una cifra del TOTALE letta male (s02: «13.23» per 13,73) si corregge se
    // DUE altre fonti concordano fra loro: il subtotale, «pagato − resto» (contanti), la somma delle
    // righe. ⚑ Le righe del pagamento si leggono solo qui, per l'importo: non escono dal metodo.
    totale = _verificaTotale(totale, visive, chiavi, inizioCorpo, fineCorpo, Money.sum(out.map((r) => r.importo)));

    // 5–6. Il piede si scarta tutto tranne la data (☠ dati della carta, s13).
    final data = _data([
      for (var i = fineCorpo + 1; i < visive.length; i++) testi[i],
      for (var i = 0; i < inizioCorpo && i < visive.length; i++) testi[i],
    ], oggi ?? DateTime.now());

    return LetturaScontrino(
      negozio: negozio,
      data: data,
      righe: List.unmodifiable(out),
      totale: totale,
      righeIgnorate: ignorate,
    );
  }

  /// L'importo del TOTALE alla riga [i]: sulla riga, o sulla riga sotto se e' fatta di soli numeri.
  static Money? _importoTotale(List<RigaVisiva> visive, List<String> testi, int i, {bool ovunque = false}) {
    final proprio = _importoDi(visive[i], ovunque: ovunque);
    if (proprio != null) return proprio;
    if (i + 1 < visive.length && TestoOcr.lettere(testi[i + 1]) == 0) {
      return _importoDi(visive[i + 1], ovunque: true);
    }
    return null;
  }

  // ⚑ `t.?tale`: un carattere letto male («T*talE PARZIALE» di s06 sull'emulatore, F12.4) non
  // deve far diventare il subtotale un articolo.
  static final RegExp _subtotale = RegExp(r'sub\s*tot|\bsubt\b|t.?tale\s*parziale');
  static final RegExp _pagato = RegExp(r'contant|\bcassa\b|pagat|pagamento|bancomat|carta\s*di');
  static final RegExp _resto = RegExp(r'\bresto\b');

  /// Il totale confermato (vedi la chiamata): tenuto se un'altra fonte lo conferma, sostituito se
  /// due altre fonti concordano su un altro valore; un TOTALE maggiore del SUBTOTALE non e'
  /// possibile (gli sconti dopo il subtotale lo abbassano, non lo alzano): vince il subtotale
  /// (s09, scontrino curvo: al TOTALE si attacca l'importo dei contanti). Senza TOTALE, il
  /// subtotale (s16).
  static Money? _verificaTotale(Money? letto, List<RigaVisiva> visive, List<String> chiavi, int inizio, int fine, Money somma) {
    Money? sub, pagato, resto;
    for (var i = inizio; i < visive.length; i++) {
      final k = chiavi[i];
      // Il subtotale: l'ULTIMO del corpo (s16 ne stampa uno dopo ogni riga).
      if (i <= fine && _subtotale.hasMatch(k)) sub = _importoDi(visive[i], ovunque: true) ?? sub;
      if (pagato == null && _pagato.hasMatch(k)) pagato = _importoDi(visive[i], ovunque: true);
      if (resto == null && _resto.hasMatch(k)) resto = _importoDi(visive[i], ovunque: true);
    }
    final p = pagato;
    final netto = p == null ? null : p - (resto ?? Money.zero);
    final fonti = <Money?>[sub, netto, somma.isZero ? null : somma];
    if (letto != null && fonti.contains(letto)) return letto;
    for (var a = 0; a < fonti.length; a++) {
      for (var b = a + 1; b < fonti.length; b++) {
        final x = fonti[a];
        if (x != null && x.cents > 0 && x == fonti[b]) return x;
      }
    }
    final s = sub;
    if (s != null && s.cents > 0 && (letto == null || letto.cents > s.cents)) return s;
    return letto;
  }

  /// Una riga pesata senza le parole: peso (3 decimali), €/kg e importo con perMisura = importo.
  static ({int grammi, Money alKg, Money importo})? _pesataSenzaEtichetta(RigaVisiva v) {
    final numeri = v.numeri;
    final pesi = numeri.where((n) => n.forma == FormaNumero.peso);
    final importi = numeri.where((n) => n.forma == FormaNumero.esplicito && !n.valore.isNegative).toList();
    for (final p in pesi) {
      for (final u in importi) {
        for (final t in importi) {
          if (identical(u, t) || t.riquadro.sinistra < u.riquadro.sinistra) continue;
          if ((Arrotonda.perMisura(u.valore, p.millesimi).cents - t.valore.cents).abs() <= 1) {
            return (grammi: p.millesimi, alKg: u.valore, importo: t.valore);
          }
        }
      }
    }
    return null;
  }

  /// L'importo di una riga visiva: quello nella colonna dei prezzi ([RigaVisiva.importoADestra]);
  /// con [ovunque] anche un numero solo in qualunque posizione (la riga sotto il TOTALE).
  static Money? _importoDi(RigaVisiva v, {bool ovunque = false}) {
    final n = v.importoADestra;
    if (n != null) return n.valore;
    if (!ovunque) return null;
    final numeri = v.numeri.where((n) => n.forma == FormaNumero.esplicito).toList();
    return numeri.isEmpty ? null : numeri.last.valore;
  }

  /// L'importo dopo la fine della pesata nella stessa riga (s03 «0,248 kg x 12,50 3,10»).
  static Money? _importoDopo(RigaVisiva v, int fine, String testo) {
    final resto = testo.substring(fine);
    final m = RegExp(r'(-?\d{1,4}[.,]\d{2})(?![.,]?\d)').allMatches(resto).lastOrNull;
    if (m == null) return null;
    return Money.cents(_intero(m[1]!.replaceAll('-', '')) * (m[1]!.startsWith('-') ? -1 : 1));
  }

  /// La descrizione: il testo a sinistra dell'importo, senza i token IVA in coda.
  static String _descrizioneDi(RigaVisiva v, String testo) {
    final n = v.importoADestra;
    var s = testo;
    if (n != null) {
      final i = testo.lastIndexOf(n.testo);
      if (i >= 0) s = testo.substring(0, i);
    }
    return _pulisciDescrizione(s);
  }

  static String _pulisciDescrizione(String s) {
    var d = s.replaceAll(RegExp(r'[-−]\s*$'), '').trim();
    d = d.replaceAll(_tokenIva, '').trim();
    // ⚑ F12.7: gli asterischi in coda («NUTELLA GR200 ****», s06: la cassa segna cosi' gli articoli
    // in promozione) finivano nel confronto e nella registrazione. Si tolgono solo in coda.
    d = d.replaceAll(RegExp(r'[\s*]+$'), '');
    d = d.replaceAll(RegExp(r'\s+'), ' ');
    return d;
  }

  /// Attacca una quantita' all'articolo appena precedente se l'importo torna. ⚑ «Adiacente»: si
  /// guarda solo l'ultimo articolo; se non torna, la quantita' aspetta il successivo.
  static bool _attacca(List<RigaScontrino> out, Quantita q, Money unitario, bool Function(RigaScontrino) torna) {
    if (out.isEmpty) return false;
    final ultimo = out.last;
    if (ultimo.tipo != TipoRigaScontrino.articolo || ultimo.quantita != null || !torna(ultimo)) return false;
    out[out.length - 1] = ultimo.copyWith(quantita: q, prezzoUnitario: unitario);
    return true;
  }

  /// Uno storno annulla l'ultimo articolo precedente con lo stesso importo e descrizione simile
  /// (o qualunque descrizione, se lo storno non ne ha).
  static void _marcaStornata(List<RigaScontrino> out, Money storno, String descrizione) {
    for (var i = out.length - 2; i >= 0; i--) {
      final r = out[i];
      if (r.tipo != TipoRigaScontrino.articolo || r.stornata) continue;
      if (r.importo.cents != storno.cents.abs()) continue;
      final nomeStorno = descrizione.replaceAll(RegExp(r'storno|annull\w*|reso|correzione', caseSensitive: false), '').trim();
      if (nomeStorno.isEmpty || TestoOcr.lettere(nomeStorno) < 2 || Nomi.similarita(nomeStorno, r.descrizione) >= 0.5) {
        out[i] = r.copyWith(stornata: true);
        return;
      }
    }
  }

  /// La prima data plausibile: non nel futuro di oltre 1 giorno e non piu' vecchia di 366 giorni.
  /// ⚑ F12.8: una data non plausibile si SALTA e si cerca la successiva (prima chiudeva la ricerca
  /// con null): un buono «valido fino al 31/12/2027» stampato prima della data dello scontrino non
  /// deve far perdere la data vera.
  static CivilDate? _data(List<String> testi, DateTime oggi) {
    final o = CivilDate.fromDateTime(oggi);
    for (final t in testi) {
      for (final m in TestoOcr.data.allMatches(t)) {
        final g = int.parse(m[1]!), mm = int.parse(m[2]!);
        var a = int.parse(m[3]!);
        if (a < 100) a += 2000;
        if (mm < 1 || mm > 12 || g < 1 || g > 31) continue;
        final CivilDate d;
        try {
          d = CivilDate(a, mm, g);
        } on Object {
          continue;
        }
        final giorni = o.daysUntil(d);
        if (giorni > 1 || giorni < -366) continue;
        return d;
      }
    }
    return null;
  }

  static int _intero(String numero) => int.parse(numero.replaceAll(RegExp(r'[.,]'), ''));
}

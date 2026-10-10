import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/riga_ocr.dart';

import '../nomi.dart';
import '../offerta.dart';
import '../quantita.dart';
import 'numeri_ocr.dart';
import 'testo_ocr.dart';

/// Un prezzo al kg o al litro stampato sul cartellino.
@immutable
final class PrezzoUnitario {
  const PrezzoUnitario(this.valore, this.unita);

  final Money valore;
  final UnitaMisura unita;

  @override
  bool operator ==(Object other) => other is PrezzoUnitario && other.valore == valore && other.unita == unita;

  @override
  int get hashCode => Object.hash(valore, unita);

  @override
  String toString() => 'PrezzoUnitario($valore/${unita.name})';
}

/// I due prezzi di un cartellino con la carta fedelta' (risposta D4 del proprietario, 2026-10-10:
/// **chiedi ogni volta**). Il foglio di conferma mostra due bottoni e l'utente sceglie; nessun
/// default, nessuna impostazione «Ho la carta».
@immutable
final class DoppioPrezzoCarta {
  const DoppioPrezzoCarta({required this.conCarta, required this.senzaCarta});

  final Money conCarta;
  final Money senzaCarta;

  @override
  bool operator ==(Object other) =>
      other is DoppioPrezzoCarta && other.conCarta == conCarta && other.senzaCarta == senzaCarta;

  @override
  int get hashCode => Object.hash(conCarta, senzaCarta);

  @override
  String toString() => 'DoppioPrezzoCarta(con $conCarta, senza $senzaCarta)';
}

/// Una proposta da confermare con un tocco (F12.1.4). **Non si aggiunge mai da sola** (F12.0
/// punto 4).
@immutable
final class PropostaCartellino {
  const PropostaCartellino({
    required this.nome,
    this.prezzo,
    this.prezzoPieno,
    this.unitario,
    this.offerta,
    this.formato,
    required this.affidabilita,
    this.alternative = const [],
    this.carta,
  });

  /// '' se non trovato.
  final String nome;

  /// Il prezzo UNITARIO da usare nella riga (PIENO con NxM, F12.1.3). Con [carta] e' il prezzo
  /// **con** la carta finche' l'utente non sceglie ([scegliCarta]).
  final Money? prezzo;

  /// Barrato / «anziche'».
  final Money? prezzoPieno;

  /// €/kg o €/l stampato.
  final PrezzoUnitario? unitario;
  final Offerta? offerta;

  /// Dal nome ("200 g").
  final AMisura? formato;

  /// 0..1: decide solo se il foglio mette in evidenza le [alternative] (sotto 0,6) e il testo
  /// «Controlla il prezzo», **mai** se aggiungere.
  final double affidabilita;

  /// Gli altri prezzi letti, come chip «Era invece…».
  final List<Money> alternative;

  /// Cartellino con due prezzi, con e senza carta fedelta' (D4): entrambi, marcati. Il foglio
  /// chiede quale; null se il cartellino ne ha uno solo.
  /// ⚑ Campo in piu' rispetto alla firma della specsheet (che aveva `preferisciPrezzoCarta` nel
  /// parser): la risposta D4 ha tolto il default, quindi il parser non sceglie piu'.
  final DoppioPrezzoCarta? carta;

  /// Prodotto venduto a peso/volume: c'e' solo il prezzo al kg/l (c02 zucchine, c03 borlotti).
  bool get aMisura => prezzo == null && unitario != null;

  /// La proposta dopo la scelta dell'utente fra i due prezzi della carta: con la carta, prezzo
  /// con carta e `OffertaPrezzoConCarta(senza)`; senza, il prezzo normale e nessuna offerta.
  /// Senza [carta] restituisce se stessa.
  PropostaCartellino scegliCarta({required bool conCarta}) {
    final c = carta;
    if (c == null) return this;
    return PropostaCartellino(
      nome: nome,
      prezzo: conCarta ? c.conCarta : c.senzaCarta,
      prezzoPieno: prezzoPieno,
      unitario: unitario,
      offerta: conCarta ? OffertaPrezzoConCarta(c.senzaCarta) : null,
      formato: formato,
      affidabilita: affidabilita,
      alternative: alternative,
    );
  }

  @override
  String toString() =>
      'PropostaCartellino("$nome", prezzo $prezzo, pieno $prezzoPieno, $unitario, $offerta, '
      'formato $formato, aff ${affidabilita.toStringAsFixed(2)}, alt $alternative, $carta)';
}

/// Il risultato della lettura di un cartellino.
@immutable
final class LetturaCartellino {
  const LetturaCartellino(this.proposte);

  /// Ordinate: la prima e' quella da proporre (con piu' cartellini, la piu' vicina al centro del
  /// mirino). Vuota = niente di utile.
  final List<PropostaCartellino> proposte;

  bool get vuota => proposte.isEmpty;
}

enum _Ruolo { daPagare, unitarioKg, unitarioL, pieno, carta }

final class _Candidato {
  _Candidato(this.numero, this.riga, this.ruolo);

  final NumeroOcr numero;
  final RigaOcr riga;
  _Ruolo ruolo;

  Money get valore => numero.valore;
  Riquadro get riquadro => numero.riquadro;
  double get altezza => numero.riquadro.altezza;

  bool get unitario => ruolo == _Ruolo.unitarioKg || ruolo == _Ruolo.unitarioL;

  @override
  String toString() => '${ruolo.name} ${valore.cents} h${altezza.toStringAsFixed(3)}';
}

/// L'interprete del cartellino (F12.1.4): dai riquadri OCR a una o piu' proposte.
///
/// ⚑ **Lavora sui riquadri, non sul testo**: i prezzi grandi con i centesimi in apice escono
/// dall'OCR senza virgola («229») o spezzati in due riquadri («1» | «06»), e solo la posizione e
/// l'altezza dicono che sono un prezzo (f12-ocr.md §7).
/// ⚑ Un solo parser per Vision e per PP-OCR: lavora su `RigaOcr`, qualunque sia il motore.
class CartellinoParser {
  const CartellinoParser();

  static final RegExp _kg = RegExp(
    // ⚑ Oltre alle parole della specsheet: «AKG» (c03, «al kg» scritto a mano letto attaccato),
    // un'etichetta fatta solo di «kg», e il francese «le kg:» (c11).
    r'/\s*kg|al\s*kg|euro\s*al\s*kg|prezzo\s*(al|per)\s*kg|eur/kg|\bkg\b\s*$|\be\s*/\s*kg|per\s*kg|'
    r'^\s*(al|a|per)?\s*kg\.?\s*$|\ble\s*kg\b|kg\s*:|'
    // ⚑ F12.7, sui ritagli del mirino: la «g» di «kg» letta «9»/«q» («€ 188,06 / k9», c27) e
    // «al kg» piccolo letto «ol ku» (c10). Le varianti larghe solo su una riga che e' tutta
    // etichetta, per non prendere parole qualunque.
    r'/\s*k[9q]\b|^\s*[ao][l1i]\s*k[gq9u]\.?\s*$',
  );

  /// Subito DOPO il numero: «2,10 L.» (c09), «10,60 kg» → prezzo al litro / al kg.
  static final RegExp _unitaDopo = RegExp(r'^\s*/?\s*(kg|l|lt|litro)\b');

  /// Subito PRIMA del numero: «Al kg € 9,90», e le sue letture storte delle etichette Esselunga
  /// «AI L € 43,80» (c19) e «AILC1,84» (c20, «€» letto come C). Il € e' gia' tolto da `pulisci`.
  /// ⚑ F12.7: anche con un «.» o «:» attaccato («AILC.12,80», c18 nel ritaglio del mirino).
  static final RegExp _unitaPrima = RegExp(r'\b(a[il]|per)\s*(kg|l|lt|litro)\s*[ce]?\s*[.:]?\s*$');

  /// Dove finisce il contesto di un numero in una riga con piu' numeri (F12.7): «250 g: 1,89 € -
  /// Soit le kg: 7,56 €» (c11). Il «le kg:» dopo il trattino e' l'etichetta del numero DOPO, non
  /// di quello prima: senza questo taglio 1,89 (il prezzo pieno del pezzo) diventava un prezzo al
  /// kg, il caso noto di c11.
  static final RegExp _separatore = RegExp(r'\s[-–|;]|[-–|;]\s|\bsoit\b');

  /// Una riga che e' una QUANTITA' («1/kg», «1 kg», «500 g» stampati sulla confezione, c22) non fa
  /// da etichetta «al kg» per il prezzo vicino.
  static final RegExp _quantita = RegExp(r'^\s*\d+([.,]\d+)?\s*/?\s*(kg|gr?|l|lt|ml|cl)\b');

  /// Una percentuale scritta senza «%» (l'OCR non legge il simbolo stilizzato: «SCONTO / 40», c28;
  /// «30» e «%» in due riquadri, c31): un numero di due cifre da solo sulla riga.
  static final RegExp _dueCifre = RegExp(r'^\s*[-−]?\s*([1-9]\d)\s*%?\s*$');
  static final RegExp _litro = RegExp(r'/\s*l(t|itro)?\b|al\s*l(t|itro)\b|prezzo\s*al\s*litro|per\s*l(t|itro)\b');
  static final RegExp _pieno = RegExp(r'anziche|invece\s*di|\bprima\b|prezzo\s*pieno|\bera\b');
  static final RegExp _carta = RegExp(r'con\s*(la\s*)?carta|carta\s*fedelta|\bsoci\b|prezzo\s*carta');

  /// ⚑ F12.7: anche «3*1» (Vision legge cosi' la «x» stilizzata del 3x1 Tigros).
  static final RegExp _nxm = RegExp(r'\b([2-5])\s*[x×*]\s*([1-4])\b(?![.,]?\d)(?!\s*(?:kg|gr?|ml|cl|lt?)\b)');
  static final RegExp _prendiPaghi = RegExp(r'prendi\s*([2-5])\s*paghi\s*([1-4])');
  static final RegExp _piuUno = RegExp(r'\b([1-4])\s*\+\s*1\b(?![.,]?\d)');
  static final RegExp _secondo = RegExp(r'sul\s*(2|secondo)\b|2\s*°\s*pezzo|secondo\s*pezzo');
  static final RegExp _percento = RegExp(r'-?\s*([1-9]\d?)\s*%');
  static final RegExp _percentoSconto = RegExp(r'(?:[-−]\s*|sconto\s*)([1-9]\d?)\s*%');
  /// ⚑ F12.7: anche «(23%» (Vision legge cosi' il «-23%» nel riquadro arrotondato di c33).
  static final RegExp _percentoSolo = RegExp(r'^\s*[-−(]?\s*([1-9]\d?)\s*%\s*\)?\s*$');
  static final RegExp _zeroPercento = RegExp(r'(?<!\d)0\s*%');

  /// Parole che non fanno un nome di prodotto (passo 7).
  static final RegExp _nonNome = RegExp(
    r'offert|sconto|prezz|promo|anziche|invece|al\s*kg|/\s*kg|/\s*l|al\s*l(t|itro)|al\s*pz|\bcad\b|'
    r'\beuro\b|%|carta|fedelta|soci\b|cod\.|codice|\bpz\b|risparmi|valid|fino\s*al|dal\s*\d|'
    // ⚑ F12.7, dai ritagli del mirino: «3 PEZZI €» (c01), «SE SCADE ENTRO IL» (c33), «SOLO A»
    // (c30), «Prezzochiaro» e' gia' sopra (prezz), le righe francesi di c11.
    r'\bpezz[io]\b|\bscade\b|\bsolo\s*a\b|\bsoit\b|\bprix\b|\bles\s*\d|al\s*pacco|\bwww\.|\.com\b',
  );

  LetturaCartellino interpreta(List<RigaOcr> righe) {
    // 1. Pulizia: testo corretto, via il rumore (confidenza bassa, riquadri minuscoli).
    final pulite = [
      for (final r in righe)
        if (r.confidenza >= 0.30 && r.riquadro.larghezza * r.riquadro.altezza >= 0.0004)
          RigaOcr(testo: NumeriOcr.pulisci(r.testo), riquadro: r.riquadro, confidenza: r.confidenza),
    ];
    if (pulite.isEmpty) return const LetturaCartellino([]);

    // 8. Piu' cartellini nella stessa foto: un'«ancora» per cartellino, ogni riga alla piu' vicina.
    final candidati = _candidati(pulite);
    final ancore = _ancore(candidati, _percentuali(pulite));
    if (ancore.length < 2) {
      final p = _proposta(pulite);
      return LetturaCartellino(p == null ? const [] : [p]);
    }
    final gruppi = {for (final a in ancore) a: <RigaOcr>[]};
    for (final r in pulite) {
      _Candidato? vicina;
      var migliore = double.infinity;
      for (final a in ancore) {
        final dx = r.riquadro.centroX - a.riquadro.centroX;
        final dy = 1.5 * (r.riquadro.centroY - a.riquadro.centroY);
        final d = dx * dx + dy * dy;
        if (d < migliore) {
          migliore = d;
          vicina = a;
        }
      }
      gruppi[vicina]!.add(r);
    }
    final proposte = <(double, PropostaCartellino)>[];
    for (final MapEntry(key: a, value: g) in gruppi.entries) {
      final p = _proposta(g);
      if (p == null) continue;
      final dx = a.riquadro.centroX - 0.5;
      final dy = a.riquadro.centroY - 0.5;
      proposte.add((dx * dx + dy * dy, p));
    }
    proposte.sort((a, b) => a.$1.compareTo(b.$1));
    return LetturaCartellino([for (final p in proposte) p.$2]);
  }

  /// Le ancore dei cartellini (passo 8): i prezzi da pagare alti almeno il 60% del piu' alto e
  /// lontani fra loro. ⚑ 60% e non 75% (F12.7): in una foto larga in prospettiva (c27, due
  /// cartellini Peck) il cartellino piu' lontano ha il prezzo alto due terzi dell'altro; sui
  /// ritagli del mirino non cambia niente (un cartellino solo).
  /// ⚑ «Lontani» = centri distanti piu' di `min(0,3, 2,5 × altezza del prezzo piu' alto)` in
  /// larghezza o in altezza, non 0,3 fisso come nella specsheet: in una foto larga (c08, due
  /// bottiglie col loro adesivo) i cartellini distano 0,27 ma i loro prezzi sono alti 0,09; in un
  /// primo piano (prezzo alto 0,2) la soglia resta 0,3.
  ///
  /// ⚑ I prezzi al kg/l fanno da ancora solo se non c'e' nessun prezzo da pagare: provato il
  /// contrario (c09, vino sfuso con il solo «€ 2,10 L.»), il «al kg» di un cartellino grande (c01)
  /// apriva un secondo cartellino finto e gli portava via il prezzo «anziche'».
  ///
  /// ⚑ F12.7: due ancore legate da una percentuale scritta (la seconda e' la prima meno l'X%, c33
  /// col prezzo dinamico) sono UN cartellino: si tiene la piu' bassa.
  List<_Candidato> _ancore(List<_Candidato> candidati, List<int> percentuali) {
    // ⚑ Il prezzo «con carta» non e' un'ancora: sta sempre accanto al prezzo normale dello stesso
    // cartellino, spesso grande uguale, e aprirebbe un secondo cartellino finto (D4).
    var tutti = candidati.where((c) => c.ruolo == _Ruolo.daPagare).toList();
    if (tutti.isEmpty) tutti = candidati.where((c) => c.unitario).toList();
    if (tutti.isEmpty) return const [];
    tutti.sort((a, b) => b.altezza.compareTo(a.altezza));
    final piuAlto = tutti.first.altezza;
    final soglia = math.min(0.3, 2.5 * piuAlto);
    final ancore = <_Candidato>[];
    for (final c in tutti) {
      if (c.altezza < 0.6 * piuAlto) continue;
      final lontana = ancore.every(
        (a) => (c.riquadro.centroX - a.riquadro.centroX).abs() > soglia || (c.riquadro.centroY - a.riquadro.centroY).abs() > soglia,
      );
      if (lontana) ancore.add(c);
    }
    if (percentuali.isEmpty || ancore.length < 2) return ancore;
    return [
      for (final a in ancore)
        if (!ancore.any((b) => b.valore.cents < a.valore.cents && percentuali.any((x) => _scontoTorna(a.valore, b.valore, x)))) a,
    ];
  }

  /// 2–3. I candidati prezzo con il loro ruolo dal contesto.
  List<_Candidato> _candidati(List<RigaOcr> righe) {
    final out = <_Candidato>[];
    final usate = <RigaOcr>{};
    for (final s in NumeriOcr.spezzati(righe)) {
      final a = righe.firstWhere((r) => r.riquadro.sinistra == s.riquadro.sinistra && r.riquadro.alto == s.riquadro.alto);
      usate.add(a);
      // Anche il riquadro dei centesimi e' usato: non deve diventare un esplicito o un fuso.
      for (final r in righe) {
        if (!identical(r, a) && r.riquadro.destra == s.riquadro.destra && RegExp(r'^[,.]?\d{2}$').hasMatch(r.testo)) usate.add(r);
      }
      out.add(_Candidato(s, a, _ruoloDaContesto(s, a, righe, segmento: '')));
    }
    for (final f in NumeriOcr.fusi(righe)) {
      final r = righe.firstWhere((r) => r.riquadro == f.riquadro);
      if (usate.contains(r)) continue;
      usate.add(r);
      out.add(_Candidato(f, r, _ruoloDaContesto(f, r, righe, segmento: '')));
    }
    for (final r in righe) {
      if (usate.contains(r)) continue;
      // ⚑ F12.7: un meno DOPO il numero («0.99-», c30 letto da Vision: la coda del «€» stilizzato)
      // su un cartellino non e' uno sconto, che si scrive col meno davanti («-0,40»): vale positivo.
      final numeri = [
        for (final n in NumeriOcr.espliciti(r))
          if (n.forma == FormaNumero.esplicito)
            if (!n.valore.isNegative)
              n
            else if (_menoSoloDopo(r.testo, n.testo))
              NumeroOcr(valore: Money.cents(-n.valore.cents), riquadro: n.riquadro, forma: n.forma, testo: n.testo),
      ];
      if (numeri.isEmpty) continue;
      final testo = r.testo;
      var da = 0;
      final posizioni = <(int, int)>[];
      for (final n in numeri) {
        final i = testo.indexOf(n.testo, da);
        posizioni.add(i < 0 ? (da, da) : (i, i + n.testo.length));
        if (i >= 0) da = i + n.testo.length;
      }
      for (var k = 0; k < numeri.length; k++) {
        // Il «segmento» di un numero: il testo fra il numero precedente e il successivo.
        final inizio = k == 0 ? 0 : posizioni[k - 1].$2;
        final fine = k == numeri.length - 1 ? testo.length : posizioni[k + 1].$1;
        var dopo = testo.substring(math.min(posizioni[k].$2, fine), math.max(posizioni[k].$2, fine));
        var prima = testo.substring(inizio, math.max(inizio, posizioni[k].$1));
        var segmento = testo.substring(inizio, math.max(inizio, fine));
        if (numeri.length > 1) {
          // ⚑ F12.7: il testo fra due numeri si divide al primo separatore (vedi [_separatore]).
          final chiaveDopo = TestoOcr.chiave(dopo);
          final taglioDopo = _separatore.firstMatch(chiaveDopo);
          if (k < numeri.length - 1 && taglioDopo != null) dopo = dopo.substring(0, taglioDopo.start);
          final tagliPrima = _separatore.allMatches(TestoOcr.chiave(prima)).toList();
          if (k > 0 && tagliPrima.isNotEmpty) prima = prima.substring(tagliPrima.last.end);
          segmento = '$prima ${numeri[k].testo} $dopo';
        }
        out.add(_Candidato(
          numeri[k],
          r,
          _ruoloDaContesto(numeri[k], r, righe, segmento: segmento, dopo: dopo, prima: prima),
        ));
      }
    }
    // ⚑ Ripiego (oltre la specsheet): nessun prezzo in nessuna forma, ma righe di sole 3-4 cifre
    // (c13: tre «249» sotto tre confezioni, piu' bassi della soglia dei fusi perche' i loghi del
    // prodotto alzano la mediana). Valgono come fusi, con l'affidabilita' dei fusi.
    if (out.isEmpty) {
      for (final r in righe) {
        final t = r.testo.trim();
        if (!RegExp(r'^\d{3,4}$').hasMatch(t)) continue;
        final f = NumeroOcr(valore: Money.cents(int.parse(t)), riquadro: r.riquadro, forma: FormaNumero.fuso, testo: t);
        out.add(_Candidato(f, r, _ruoloDaContesto(f, r, righe, segmento: '')));
      }
    }
    return out;
  }

  /// Il ruolo di un numero (passo 3): prima il suo pezzo di riga, poi le altre parole della stessa
  /// riga visiva, poi le righe entro 1,5 altezze sopra e sotto che si sovrappongono in orizzontale.
  /// ⚑ Solo righe **senza numeri** come contesto: la scritta «€/kg» accanto al prezzo piccolo non
  /// deve trasformare in prezzo al kg anche il prezzo grande lì vicino.
  _Ruolo _ruoloDaContesto(
    NumeroOcr n,
    RigaOcr riga,
    List<RigaOcr> righe, {
    required String segmento,
    String dopo = '',
    String prima = '',
  }) {
    final unita = _unitaDopo.firstMatch(TestoOcr.chiave(dopo)) ?? _unitaPrima.firstMatch(TestoOcr.chiave(prima));
    if (unita != null) {
      final u = unita.groupCount == 2 ? unita[2] : unita[1];
      return u == 'kg' ? _Ruolo.unitarioKg : _Ruolo.unitarioL;
    }
    final proprio = _ruoloDiTesto(TestoOcr.chiave(segmento));
    if (proprio != null) return proprio;
    final q = n.riquadro;
    final stessa = <RigaOcr>[];
    final vicine = <RigaOcr>[];
    for (final r in righe) {
      if (identical(r, riga) || _haNumeri(r) || _quantita.hasMatch(TestoOcr.chiave(r.testo))) continue;
      final rr = r.riquadro;
      if (rr.sovrapposizioneVerticale(q) >= 0.5) {
        // ⚑ F12.7 (c15 nel mirino): un'etichetta «Al kg» piccola, a SINISTRA del numero grande e
        // seguita da un frammento con cifre e' l'etichetta di un valore letto male (Esselunga: «Al
        // kg € 9,95» a sinistra, letto «Alkg» + «2»; il prezzo grande a destra), non del prezzo
        // grande. ⚑ Serve il frammento: «al kg» piccolo sotto il prezzo SENZA niente accanto e'
        // proprio l'etichetta del prezzo grande (c10, «1,79 / al kg»).
        if (rr.destra < q.sinistra && rr.altezza < 0.5 * q.altezza && _seguitaDaCifre(r, q, righe)) continue;
        stessa.add(r);
      } else if ((rr.centroY - q.centroY).abs() <= 1.5 * q.altezza && rr.sinistra < q.destra + q.altezza && rr.destra > q.sinistra - q.altezza) {
        vicine.add(r);
      }
    }
    for (final gruppo in [stessa, vicine]) {
      gruppo.sort((a, b) => _distanza(a.riquadro, q).compareTo(_distanza(b.riquadro, q)));
      for (final r in gruppo) {
        final ruolo = _ruoloDiTesto(TestoOcr.chiave(r.testo));
        if (ruolo != null) return ruolo;
      }
    }
    return _Ruolo.daPagare;
  }

  /// [etichetta] ha subito a destra (entro due altezze, sulla stessa riga visiva, prima del numero
  /// [q]) un frammento con cifre: il valore a cui l'etichetta appartiene, letto male.
  static bool _seguitaDaCifre(RigaOcr etichetta, Riquadro q, List<RigaOcr> righe) {
    final e = etichetta.riquadro;
    for (final t in righe) {
      if (identical(t, etichetta) || !RegExp(r'\d').hasMatch(t.testo)) continue;
      final r = t.riquadro;
      if (r.sovrapposizioneVerticale(e) < 0.5) continue;
      if (r.sinistra >= e.destra - e.altezza && r.sinistra <= e.destra + 2 * e.altezza && r.destra <= q.sinistra) return true;
    }
    return false;
  }

  /// Il meno di [numero] in [testo] sta solo dopo («0,99-»), non davanti («-0,99»).
  static bool _menoSoloDopo(String testo, String numero) {
    final n = RegExp.escape(numero);
    return RegExp(n + r'\s*[-−](?!\d)').hasMatch(testo) && !RegExp(r'[-−]\s?' + n).hasMatch(testo);
  }

  static double _distanza(Riquadro a, Riquadro b) {
    final dx = a.centroX - b.centroX;
    final dy = a.centroY - b.centroY;
    return dx * dx + dy * dy;
  }

  /// ⚑ F12.7: anche cifre attaccate a «/kg» o «/l» («• c 819/Kg», c33 letto da Vision: il «8,19 €/kg»
  /// piccolo senza virgola) sono un VALORE illeggibile, non un'etichetta per il prezzo grande vicino.
  static bool _haNumeri(RigaOcr r) =>
      RegExp(r'\d[.,]\d{2}|^\s*\d{1,5}\s*$|\d\s*/\s*(kg|l)\b', caseSensitive: false).hasMatch(r.testo);

  static _Ruolo? _ruoloDiTesto(String t) {
    if (_kg.hasMatch(t)) return _Ruolo.unitarioKg;
    if (_litro.hasMatch(t)) return _Ruolo.unitarioL;
    if (_pieno.hasMatch(t)) return _Ruolo.pieno;
    if (_carta.hasMatch(t)) return _Ruolo.carta;
    return null;
  }

  /// 4. Le offerte scritte nel testo del cartellino.
  ({OffertaNxM? nxm, int? percento, int? secondo, bool zero}) _offerte(List<RigaOcr> righe) {
    final testi = [for (final r in righe) TestoOcr.chiave(r.testo)];
    final tutto = testi.join('\n');
    OffertaNxM? nxm;
    for (final m in _nxm.allMatches(tutto)) {
      final n = int.parse(m[1]!), p = int.parse(m[2]!);
      if (n > p) {
        nxm = OffertaNxM(prendi: n, paghi: p);
        break;
      }
    }
    final pp = _prendiPaghi.firstMatch(tutto);
    if (nxm == null && pp != null) {
      final n = int.parse(pp[1]!), p = int.parse(pp[2]!);
      if (n > p) nxm = OffertaNxM(prendi: n, paghi: p);
    }
    final piu = _piuUno.firstMatch(tutto);
    if (nxm == null && piu != null) {
      final n = int.parse(piu[1]!);
      nxm = OffertaNxM(prendi: n + 1, paghi: n);
    }
    final zero = _zeroPercento.hasMatch(tutto);
    int? secondo;
    if (_secondo.hasMatch(tutto)) {
      final m = _percento.firstMatch(tutto);
      if (m != null) secondo = int.parse(m[1]!);
    }
    int? percento;
    if (secondo == null) {
      final m = _percentoSconto.firstMatch(tutto);
      if (m != null) {
        percento = int.parse(m[1]!);
      } else {
        for (final t in testi) {
          final s = _percentoSolo.firstMatch(t);
          if (s != null) {
            percento = int.parse(s[1]!);
            break;
          }
        }
      }
      percento ??= _percentoSenzaSimbolo(righe);
    }
    return (nxm: nxm, percento: percento, secondo: secondo, zero: zero);
  }

  /// Una percentuale senza «%» accanto alla parola «sconto» (F12.7: c28 «SCONTO» sopra «40», c31
  /// «30» con il «%» in un riquadro a parte e «SCONTO» sotto): il numero di due cifre da solo
  /// sulla riga e una riga con «sconto» entro due altezze, sovrapposte in orizzontale.
  /// ⚑ Solo vicino a «sconto»: un «40» isolato da solo puo' essere qualunque cosa (un reparto, un
  /// codice, il «52» del cartellino Despar).
  static int? _percentoSenzaSimbolo(List<RigaOcr> righe) {
    for (final r in righe) {
      final m = _dueCifre.firstMatch(r.testo);
      if (m == null) continue;
      final q = r.riquadro;
      for (final s in righe) {
        if (identical(s, r) || !TestoOcr.chiave(s.testo).contains('sconto')) continue;
        final rr = s.riquadro;
        final vicinaY = (rr.centroY - q.centroY).abs() <= 2 * math.max(q.altezza, rr.altezza);
        final vicinaX = rr.sinistra < q.destra + q.altezza && rr.destra > q.sinistra - q.altezza;
        if (vicinaY && vicinaX) return int.parse(m[1]!);
      }
    }
    return null;
  }

  /// Tutte le percentuali di sconto scritte (anche piu' d'una in una foto larga): servono a
  /// riconoscere la coppia «prezzo pieno / prezzo scontato» ([_scontoTorna]).
  static List<int> _percentuali(List<RigaOcr> righe) {
    final out = <int>[];
    for (final r in righe) {
      final t = TestoOcr.chiave(r.testo);
      for (final m in _percentoSconto.allMatches(t)) {
        out.add(int.parse(m[1]!));
      }
      final s = _percentoSolo.firstMatch(t);
      if (s != null) out.add(int.parse(s[1]!));
    }
    final senza = _percentoSenzaSimbolo(righe);
    if (senza != null) out.add(senza);
    return out;
  }

  /// `scontato` e' `pieno` meno [percento]% (±2 centesimi: i cartellini col prezzo dinamico
  /// arrotondano a modo loro, c33 «-8%» 2,54 → 2,32 invece di 2,34).
  static bool _scontoTorna(Money pieno, Money scontato, int percento) {
    final atteso = pieno.cents - (pieno.cents * percento / 100).round();
    return (atteso - scontato.cents).abs() <= 2;
  }

  /// 5–7 e 9: la proposta per le righe di UN cartellino; null se non c'e' niente di utile.
  PropostaCartellino? _proposta(List<RigaOcr> righe) {
    final candidati = _candidati(righe);
    if (candidati.isEmpty) return _soloSconto(righe);
    final offerte = _offerte(righe);
    final unitari = candidati.where((c) => c.unitario).toList();
    var pagabili = candidati.where((c) => c.ruolo == _Ruolo.daPagare || c.ruolo == _Ruolo.carta).toList();
    final pieni = candidati.where((c) => c.ruolo == _Ruolo.pieno).toList();
    if (pagabili.isEmpty && unitari.isEmpty && pieni.isNotEmpty) {
      // Un «anziche'» senza nient'altro: e' comunque l'unico prezzo che c'e'.
      pagabili = pieni;
    }

    final formato = _formato(righe);

    // 5. Prodotto a peso: c'e' solo il prezzo al kg/l.
    if (pagabili.isEmpty) {
      if (unitari.isEmpty) return null;
      unitari.sort((a, b) => b.altezza.compareTo(a.altezza));
      final u = unitari.first;
      final nome = _nome(righe, u.riquadro);
      return PropostaCartellino(
        nome: nome,
        unitario: PrezzoUnitario(u.valore, u.ruolo == _Ruolo.unitarioL ? UnitaMisura.l : UnitaMisura.kg),
        formato: formato,
        affidabilita: _taglia((0.5 + _bonusForma(u.numero.forma) + (nome.isEmpty ? 0 : 0.1) + u.riga.confidenza) / 2),
      );
    }

    // 5. Il prezzo da pagare: il piu' alto; a parita' (±10%) quello del controllo formato.
    pagabili.sort((a, b) => b.altezza.compareTo(a.altezza));
    final alto = pagabili.first;
    final pari = pagabili.where((c) => c.altezza >= 0.9 * alto.altezza).toList();
    var scelto = alto;
    final unitarioVicino = _vicino(unitari, alto.riquadro);
    var formatoRiuscito = false;
    if (formato != null && unitarioVicino != null) {
      for (final c in pari) {
        if (_formatoTorna(c.valore, formato, unitarioVicino.valore)) {
          scelto = c;
          formatoRiuscito = true;
          break;
        }
      }
    }
    // ⚑ F12.7 (c33, cartellino elettronico col prezzo dinamico «se scade entro il… 2,29 / se
    // scade oltre il… 2,99», «-23%»): due prezzi grandi uguali, ma uno e' l'altro meno la
    // percentuale scritta. Il prezzo e' lo scontato, il pieno l'altro: non c'e' ambiguita'.
    _Candidato? pienoDaSconto;
    final percentuali = _percentuali(righe);
    if (percentuali.isNotEmpty) {
      coppia:
      // ⚑ Fra tutti i prezzi alti almeno il 60% del piu' alto, non solo i «pari»: Vision legge
      // «229» piu' basso di «€ 299» (0,15 contro 0,22) sullo stesso cartellino elettronico.
      for (final a in pagabili.where((c) => c.altezza >= 0.6 * alto.altezza)) {
        for (final b in pagabili) {
          if (b.valore.cents <= a.valore.cents) continue;
          if (percentuali.any((x) => _scontoTorna(b.valore, a.valore, x))) {
            scelto = a;
            pienoDaSconto = b;
            break coppia;
          }
        }
      }
    }
    final ambiguo = pienoDaSconto == null && pari.where((c) => c.valore != scelto.valore).isNotEmpty;

    var affidabilita = 0.5 + _bonusForma(scelto.numero.forma);
    var prezzo = scelto.valore;
    Money? pieno;
    Offerta? offerta;
    DoppioPrezzoCarta? carta;

    // Carta fedelta' (D4): due prezzi, entrambi marcati; sceglie l'utente.
    final conCarta = pagabili.where((c) => c.ruolo == _Ruolo.carta).toList();
    final normali = pagabili.where((c) => c.ruolo == _Ruolo.daPagare).toList();
    if (pienoDaSconto != null) {
      pieno = pienoDaSconto.valore;
      offerta = OffertaPrezzoBarrato(pieno);
    } else if (conCarta.isNotEmpty && normali.isNotEmpty && conCarta.first.valore != normali.first.valore) {
      carta = DoppioPrezzoCarta(conCarta: conCarta.first.valore, senzaCarta: normali.first.valore);
      prezzo = carta.conCarta;
      offerta = OffertaPrezzoConCarta(carta.senzaCarta);
    } else if (offerte.nxm case final nxm?) {
      // 6. NxM: il prezzo grande e' l'effettivo se un prezzo piu' piccolo Q lo da' come Q × M / N.
      // ⚑ F12.7: l'«anziche'» per primo. Con «3 PEZZI € 3,18» e «anziche' € 3,19» danno entrambi
      // 1,06 col 3x1, ma il prezzo del pezzo e' 3,19 (Vision su c01 largo).
      final altri = [
        ...pieni.where((c) => c.valore.cents > scelto.valore.cents),
        ...candidati.where((c) => !c.unitario && c.ruolo != _Ruolo.pieno && c.valore.cents > scelto.valore.cents),
      ];
      final q = altri.where((c) => (nxm.effettivo(c.valore).cents - scelto.valore.cents).abs() <= 1).firstOrNull;
      offerta = nxm;
      // ⚑ F12.7 (c01 nel mirino: il «1,06» grande non letto, restano «3 PEZZI € 3,18» e «anziche'
      // € 3,19 al pz»): con un NxM il prezzo della riga e' il PIENO (F12.1.3), e l'«anziche'» lo
      // dice esplicitamente. Vale anche quando il prezzo grande non c'e'.
      final anziche = pieni.firstOrNull;
      if (q != null) {
        prezzo = q.valore;
      } else if (anziche != null) {
        prezzo = anziche.valore;
      } else {
        affidabilita -= 0.2;
      }
    } else {
      // 6. Pieno: un candidato «anziche'», o un secondo prezzo maggiore e piu' basso dell'80%.
      final p = pieni.where((c) => c.valore.cents > scelto.valore.cents).firstOrNull ??
          pagabili.where((c) => c.valore.cents > scelto.valore.cents && c.altezza < 0.8 * scelto.altezza).firstOrNull;
      if (p != null) {
        pieno = p.valore;
        offerta = OffertaPrezzoBarrato(p.valore);
      } else if (offerte.secondo case final s?) {
        offerta = OffertaSecondoAPercento(s);
      } else if (offerte.percento case final x? when !offerte.zero) {
        offerta = OffertaPercentuale(x);
      }
    }

    var unitario = _vicino(unitari, scelto.riquadro);
    // ⚑ F12.7 (c11: «Soit le kg 5,04» del prezzo in offerta e «Soit le kg 7,56» del prezzo pieno):
    // con un NxM e due prezzi al kg, quello che torna col prezzo EFFETTIVO e il formato.
    if (offerta case final OffertaNxM nxm when unitari.length > 1 && formato != null) {
      final eff = nxm.effettivo(prezzo);
      unitario = unitari.where((u) => _formatoTorna(eff, formato, u.valore)).firstOrNull ?? unitario;
    }
    final nome = _nome(righe, scelto.riquadro);
    final formatoFinale = Nomi.formato(nome) ?? formato;
    if (!formatoRiuscito && formatoFinale != null && unitario != null) {
      formatoRiuscito = _formatoTorna(prezzo, formatoFinale, unitario.valore);
    }
    if (formatoRiuscito) affidabilita += 0.2;
    if (nome.isNotEmpty) affidabilita += 0.1;
    if (ambiguo) affidabilita -= 0.2;
    affidabilita = _taglia((affidabilita + scelto.riga.confidenza) / 2);

    final alternative = <Money>[];
    for (final c in [...pagabili, ...pieni]) {
      if (c.valore != prezzo && c.valore != pieno && !alternative.contains(c.valore)) alternative.add(c.valore);
    }

    return PropostaCartellino(
      nome: nome,
      prezzo: prezzo,
      prezzoPieno: pieno,
      unitario: unitario == null
          ? null
          : PrezzoUnitario(unitario.valore, unitario.ruolo == _Ruolo.unitarioL ? UnitaMisura.l : UnitaMisura.kg),
      offerta: offerta,
      formato: formatoFinale,
      affidabilita: affidabilita,
      alternative: List.unmodifiable(alternative.take(3)),
      carta: carta,
    );
  }

  /// Un bollino di sconto senza prezzo («ULTIMI GIORNI -30% SCONTO ALLA CASSA», c31/c32): una
  /// proposta col solo sconto e il prezzo da battere nel foglio (che lo mostra come «—» e lo fa
  /// toccare per scriverlo). ⚑ Affidabilita' bassa: il foglio mette in evidenza «Controlla il
  /// prezzo». Null se non c'e' nemmeno lo sconto.
  PropostaCartellino? _soloSconto(List<RigaOcr> righe) {
    final o = _offerte(righe);
    final x = o.percento ?? o.secondo;
    if (x == null || o.zero) return null;
    return PropostaCartellino(
      nome: '',
      offerta: o.secondo != null ? OffertaSecondoAPercento(x) : OffertaPercentuale(x),
      affidabilita: 0.3,
    );
  }

  static double _bonusForma(FormaNumero f) => switch (f) {
    FormaNumero.esplicito => 0.2,
    FormaNumero.spezzato => 0.1,
    FormaNumero.fuso => -0.1,
    FormaNumero.peso => 0,
  };

  static double _taglia(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  static _Candidato? _vicino(List<_Candidato> lista, Riquadro q) {
    if (lista.isEmpty) return null;
    return (lista.toList()..sort((a, b) => _distanza(a.riquadro, q).compareTo(_distanza(b.riquadro, q)))).first;
  }

  /// Controllo formato (passo 5): `|P × 1000 / millesimi − U| ≤ max(2 cent, 0,5% di U)`, in interi
  /// (×1000 per non usare double: |P·1e6/m − U·1000| ≤ max(2000, 5·U)).
  static bool _formatoTorna(Money p, AMisura formato, Money u) {
    final calcolato = p.cents * 1000 * 1000 ~/ formato.millesimi;
    final atteso = u.cents * 1000;
    final tolleranza = math.max(2000, 5 * u.cents);
    return (calcolato - atteso).abs() <= tolleranza;
  }

  /// Il formato della confezione dal primo testo che ne ha uno (righe senza prezzi).
  static AMisura? _formato(List<RigaOcr> righe) {
    for (final r in righe) {
      if (TestoOcr.lettere(r.testo) < 3) continue;
      final f = Nomi.formato(r.testo);
      if (f != null) return f;
    }
    return null;
  }

  /// 7. Il nome: righe con almeno 3 lettere, non parole chiave ne' numeri ne' codici, sopra il
  /// prezzo o alla sua sinistra; le 2 piu' vicine, poi dall'alto in basso, unite; max 60 caratteri.
  /// ⚑ «Le piu' vicine» e non «le prime dall'alto»: in una foto il testo piu' in alto e' spesso
  /// l'insegna del reparto o un altro cartellino, il nome sta subito sopra il prezzo.
  static String _nome(List<RigaOcr> righe, Riquadro prezzo) {
    final buone = <RigaOcr>[];
    for (final r in righe) {
      final t = r.testo.trim();
      if (TestoOcr.lettere(t) < 3) continue;
      if (_nonNome.hasMatch(TestoOcr.chiave(t))) continue;
      if (RegExp(r'\d[.,]\d{2}').hasMatch(t)) continue;
      if (RegExp(r'^\d{8,13}$').hasMatch(t) || TestoOcr.data.hasMatch(t)) continue;
      final q = r.riquadro;
      final sopra = q.centroY < prezzo.alto + 0.2 * prezzo.altezza;
      final sinistra = q.destra <= prezzo.sinistra + 0.05 && q.centroY < prezzo.basso;
      if (sopra || sinistra) buone.add(r);
    }
    // ⚑ F12.7 (ritagli Esselunga «Il Prezzochiaro»: prezzo in alto a destra, nome stampato SOTTO,
    // a sinistra): niente sopra o a sinistra → le righe sotto il prezzo, entro 3 altezze.
    if (buone.isEmpty) {
      for (final r in righe) {
        final t = r.testo.trim();
        if (TestoOcr.lettere(t) < 3 || _nonNome.hasMatch(TestoOcr.chiave(t))) continue;
        if (RegExp(r'\d[.,]\d{2}').hasMatch(t) || RegExp(r'^\d{8,13}$').hasMatch(t) || TestoOcr.data.hasMatch(t)) continue;
        final q = r.riquadro;
        if (q.alto >= prezzo.centroY && q.alto <= prezzo.basso + 3 * prezzo.altezza) buone.add(r);
      }
    }
    if (buone.isEmpty) return '';
    buone.sort((a, b) => _distanza(a.riquadro, prezzo).compareTo(_distanza(b.riquadro, prezzo)));
    final scelte = buone.take(2).toList()..sort((a, b) => a.riquadro.alto.compareTo(b.riquadro.alto));
    // ⚑ F12.7 (Esselunga sull'emulatore): «Cod CREMA …», l'etichetta del codice attaccata al nome.
    final nome = scelte.map((r) => r.testo.trim()).join(' ').replaceFirst(RegExp(r'^cod\b\.?\s*', caseSensitive: false), '');
    return nome.length > 60 ? nome.substring(0, 60).trimRight() : nome;
  }
}

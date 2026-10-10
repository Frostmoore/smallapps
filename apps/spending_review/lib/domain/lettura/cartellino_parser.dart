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

/// I due prezzi di un cartellino con la carta fedelta' (risposta D4 del proprietario, 2026-10-11:
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
    r'^\s*(al|a|per)?\s*kg\.?\s*$|\ble\s*kg\b|kg\s*:',
  );

  /// Subito DOPO il numero: «2,10 L.» (c09), «10,60 kg» → prezzo al litro / al kg.
  static final RegExp _unitaDopo = RegExp(r'^\s*/?\s*(kg|l|lt|litro)\b');

  /// Subito PRIMA del numero: «Al kg € 9,90», e le sue letture storte delle etichette Esselunga
  /// «AI L € 43,80» (c19) e «AILC1,84» (c20, «€» letto come C). Il € e' gia' tolto da `pulisci`.
  static final RegExp _unitaPrima = RegExp(r'\b(a[il]|per)\s*(kg|l|lt|litro)\s*[ce]?\s*$');
  static final RegExp _litro = RegExp(r'/\s*l(t|itro)?\b|al\s*l(t|itro)\b|prezzo\s*al\s*litro|per\s*l(t|itro)\b');
  static final RegExp _pieno = RegExp(r'anziche|invece\s*di|\bprima\b|prezzo\s*pieno|\bera\b');
  static final RegExp _carta = RegExp(r'con\s*(la\s*)?carta|carta\s*fedelta|\bsoci\b|prezzo\s*carta');

  static final RegExp _nxm = RegExp(r'\b([2-5])\s*[x×]\s*([1-4])\b(?![.,]?\d)(?!\s*(?:kg|gr?|ml|cl|lt?)\b)');
  static final RegExp _prendiPaghi = RegExp(r'prendi\s*([2-5])\s*paghi\s*([1-4])');
  static final RegExp _piuUno = RegExp(r'\b([1-4])\s*\+\s*1\b(?![.,]?\d)');
  static final RegExp _secondo = RegExp(r'sul\s*(2|secondo)\b|2\s*°\s*pezzo|secondo\s*pezzo');
  static final RegExp _percento = RegExp(r'-?\s*([1-9]\d?)\s*%');
  static final RegExp _percentoSconto = RegExp(r'(?:[-−]\s*|sconto\s*)([1-9]\d?)\s*%');
  static final RegExp _percentoSolo = RegExp(r'^\s*[-−]?\s*([1-9]\d?)\s*%\s*$');
  static final RegExp _zeroPercento = RegExp(r'(?<!\d)0\s*%');

  /// Parole che non fanno un nome di prodotto (passo 7).
  static final RegExp _nonNome = RegExp(
    r'offert|sconto|prezz|promo|anziche|invece|al\s*kg|/\s*kg|/\s*l|al\s*l(t|itro)|al\s*pz|\bcad\b|'
    r'\beuro\b|%|carta|fedelta|soci\b|cod\.|codice|\bpz\b|risparmi|valid|fino\s*al|dal\s*\d',
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
    final ancore = _ancore(candidati);
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

  /// Le ancore dei cartellini (passo 8): i prezzi da pagare alti entro il 25% del piu' alto e
  /// lontani fra loro.
  /// ⚑ «Lontani» = centri distanti piu' di `min(0,3, 2,5 × altezza del prezzo piu' alto)` in
  /// larghezza o in altezza, non 0,3 fisso come nella specsheet: in una foto larga (c08, due
  /// bottiglie col loro adesivo) i cartellini distano 0,27 ma i loro prezzi sono alti 0,09; in un
  /// primo piano (prezzo alto 0,2) la soglia resta 0,3.
  ///
  /// ⚑ I prezzi al kg/l fanno da ancora solo se non c'e' nessun prezzo da pagare: provato il
  /// contrario (c09, vino sfuso con il solo «€ 2,10 L.»), il «al kg» di un cartellino grande (c01)
  /// apriva un secondo cartellino finto e gli portava via il prezzo «anziche'».
  List<_Candidato> _ancore(List<_Candidato> candidati) {
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
      if (c.altezza < 0.75 * piuAlto) continue;
      final lontana = ancore.every(
        (a) => (c.riquadro.centroX - a.riquadro.centroX).abs() > soglia || (c.riquadro.centroY - a.riquadro.centroY).abs() > soglia,
      );
      if (lontana) ancore.add(c);
    }
    return ancore;
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
      final numeri = NumeriOcr.espliciti(r).where((n) => n.forma == FormaNumero.esplicito && !n.valore.isNegative).toList();
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
        final segmento = testo.substring(inizio, math.max(inizio, fine));
        final dopo = testo.substring(math.min(posizioni[k].$2, fine), math.max(posizioni[k].$2, fine));
        final prima = testo.substring(inizio, math.max(inizio, posizioni[k].$1));
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
      if (identical(r, riga) || _haNumeri(r)) continue;
      final rr = r.riquadro;
      if (rr.sovrapposizioneVerticale(q) >= 0.5) {
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

  static double _distanza(Riquadro a, Riquadro b) {
    final dx = a.centroX - b.centroX;
    final dy = a.centroY - b.centroY;
    return dx * dx + dy * dy;
  }

  static bool _haNumeri(RigaOcr r) => RegExp(r'\d[.,]\d{2}|^\s*\d{1,5}\s*$').hasMatch(r.testo);

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
    }
    return (nxm: nxm, percento: percento, secondo: secondo, zero: zero);
  }

  /// 5–7 e 9: la proposta per le righe di UN cartellino; null se non c'e' niente di utile.
  PropostaCartellino? _proposta(List<RigaOcr> righe) {
    final candidati = _candidati(righe);
    if (candidati.isEmpty) return null;
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
    final ambiguo = pari.where((c) => c.valore != scelto.valore).isNotEmpty;

    var affidabilita = 0.5 + _bonusForma(scelto.numero.forma);
    var prezzo = scelto.valore;
    Money? pieno;
    Offerta? offerta;
    DoppioPrezzoCarta? carta;

    // Carta fedelta' (D4): due prezzi, entrambi marcati; sceglie l'utente.
    final conCarta = pagabili.where((c) => c.ruolo == _Ruolo.carta).toList();
    final normali = pagabili.where((c) => c.ruolo == _Ruolo.daPagare).toList();
    if (conCarta.isNotEmpty && normali.isNotEmpty && conCarta.first.valore != normali.first.valore) {
      carta = DoppioPrezzoCarta(conCarta: conCarta.first.valore, senzaCarta: normali.first.valore);
      prezzo = carta.conCarta;
      offerta = OffertaPrezzoConCarta(carta.senzaCarta);
    } else if (offerte.nxm case final nxm?) {
      // 6. NxM: il prezzo grande e' l'effettivo se un prezzo piu' piccolo Q lo da' come Q × M / N.
      final altri = candidati.where((c) => !c.unitario && c.valore.cents > scelto.valore.cents);
      final q = altri.where((c) => (nxm.effettivo(c.valore).cents - scelto.valore.cents).abs() <= 1).firstOrNull;
      offerta = nxm;
      if (q != null) {
        prezzo = q.valore;
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

    final unitario = _vicino(unitari, scelto.riquadro);
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
    if (buone.isEmpty) return '';
    buone.sort((a, b) => _distanza(a.riquadro, prezzo).compareTo(_distanza(b.riquadro, prezzo)));
    final scelte = buone.take(2).toList()..sort((a, b) => a.riquadro.alto.compareTo(b.riquadro.alto));
    final nome = scelte.map((r) => r.testo.trim()).join(' ');
    return nome.length > 60 ? nome.substring(0, 60).trimRight() : nome;
  }
}

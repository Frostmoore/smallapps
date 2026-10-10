import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/riga_ocr.dart';
import 'package:spending_review/domain/lettura/bilancia_parser.dart';
import 'package:spending_review/domain/lettura/cartellino_parser.dart';
import 'package:spending_review/domain/lettura/scontrino_parser.dart';
import 'package:spending_review/domain/nomi.dart';
import 'package:spending_review/domain/offerta.dart';
import 'package:spending_review/domain/quantita.dart';

/// Il banco di regressione del parser (develop_microapps.md F12.1.17).
///
/// ⚑ Nel repo c'e' solo il TESTO OCR (righe + riquadri + confidenza) dei 33 campioni a licenza
/// libera, mai le immagini: il parser lavora solo sulle righe, quindi il test e' deterministico e
/// gira in millisecondi senza motore OCR e senza dispositivo.
///
/// ⚑ **Un «cricchetto», non una soglia inventata**: `test/fixtures/ocr/soglie.json` tiene, per
/// motore, tipo e campo, il numero di casi giusti dell'ultima versione accettata. Il test FALLISCE
/// se un numero scende; se sale stampa «aggiorna soglie.json: …» (si aggiorna a mano, nello stesso
/// commit). Le soglie di f12-ocr.md §6.3 (prezzo ≥ 95%…) sono l'obiettivo sulle foto vere fatte col
/// mirino, non su queste foto larghe del web.
///
/// Le 27 fixture a licenza non libera stanno FUORI dal repo; con `SR_CAMPIONI` che punta alla
/// cartella che contiene `ppocrv5/` (es. `E:/coding/XAMPP/htdocs/microapps-campioni/f12/fixture`)
/// il banco le legge e stampa anche i numeri sui 60 (senza cricchetto: non tutti le hanno).
///
/// ⚑ Ogni sottocartella di `test/fixtures/ocr/` e' un «motore» col suo cricchetto (F12.7):
/// `ppocrv5` = foto intere (spesso larghe, piu' cartellini), `ppocrv5-mirino` = un ritaglio per
/// cartellino come lo fa il mirino dell'app (`ritagli_mirino.json`, il caso d'uso vero),
/// `vision-sim` e `vision-sim-mirino` = le stesse immagini lette da Vision sul simulatore iPhone.
/// Nei «-mirino» ogni fixture ha UNA verita': conta solo la prima proposta.
void main() {
  final cartella = Directory('test/fixtures/ocr');
  final soglie = (jsonDecode(File('${cartella.path}/soglie.json').readAsStringSync()) as Map<String, Object?>)
      .map((k, v) => MapEntry(k, (v! as Map<String, Object?>).map((c, n) => MapEntry(c, n! as int))));

  final motori = cartella.listSync().whereType<Directory>().toList()..sort((a, b) => a.path.compareTo(b.path));

  for (final motore in motori) {
    final nomeMotore = motore.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final fixture = _carica(motore);
    if (fixture.isEmpty) continue;

    group('motore $nomeMotore (${fixture.length} fixture nel repo)', () {
      // ⚑ Un giro a vuoto prima di misurare: il primo passaggio paga la compilazione JIT delle
      // regex e del parser (20 ms sul primo campione, 3 ms a regime).
      _Banco.misura(fixture);
      final esito = _Banco.misura(fixture);

      test('nessun dato di carta nelle fixture del repo', () {
        // ⚑ Asterischi (RapidOCR) o «x» (Vision, F12.7: «673703xxxxxxxxx7034» in s13) davanti alle
        // ultime 4 cifre: un PAN mascherato non deve mai finire nel repo.
        final carta = RegExp(r'(\*{4}|[xX]{4,})\d{4}');
        for (final f in fixture) {
          for (final r in f.righe) {
            expect(carta.hasMatch(r.testo), isFalse, reason: '${f.campione}: "${r.testo}"');
          }
        }
      });

      test('il cricchetto: nessun numero scende', () {
        esito.stampa('repo, $nomeMotore');
        final attese = soglie[nomeMotore] ?? const <String, int>{};
        final salite = <String>[];
        for (final MapEntry(key: campo, value: giusti) in esito.giusti.entries) {
          final prima = attese[campo];
          if (prima == null || giusti > prima) salite.add('$campo ${prima ?? '-'} → $giusti');
          if (prima != null) expect(giusti, greaterThanOrEqualTo(prima), reason: '$campo e\' sceso da $prima a $giusti');
        }
        for (final campo in attese.keys) {
          expect(esito.giusti.containsKey(campo), isTrue, reason: '$campo non si misura piu\'');
        }
        if (salite.isNotEmpty) {
          // ignore: avoid_print
          print('aggiorna soglie.json ($nomeMotore): ${salite.join(', ')}');
        }
      });

      // ⚑ Solo PP-OCRv5: e' RapidOCR che legge al 100% i totali (f12-ocr.md §7). Vision sul
      // simulatore ne perde alcuni gia' nell'OCR (F12.7): li tiene il suo cricchetto.
      test('sempre giusti: i totali di bilance e scontrini (il lettore li legge al 100%)', skip: !nomeMotore.startsWith('ppocrv5'), () {
        expect(esito.sbagliati['bilancia.totale'] ?? const <String>[], isEmpty);
        expect(esito.sbagliati['scontrino.totale'] ?? const <String>[], isEmpty);
      });

      test('ogni parser sta sotto i 20 ms per foto (F12.1.18)', () {
        expect(esito.msMassimi, lessThan(20), reason: 'il piu\' lento: ${esito.piuLento}');
      });
    });
  }

  // ⚑ Le private si leggono per OGNI cartella di motore del repo (`ppocrv5` = foto intere,
  // `ppocrv5-mirino` = ritagli del mirino, F12.7): `SR_CAMPIONI/<motore>/`.
  final privati = Platform.environment['SR_CAMPIONI'];
  test('fixture private (SR_CAMPIONI)', () {
    if (privati == null || !Directory('$privati/ppocrv5').existsSync()) {
      // ignore: avoid_print
      print('fixture private non trovate (SR_CAMPIONI non impostata): solo quelle del repo');
      return;
    }
    for (final motore in motori) {
      final nome = motore.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final tutte = [..._carica(motore), ..._carica(Directory('$privati/$nome'))];
      _Banco.misura(tutte).stampa('tutti i ${tutte.length} campioni, $nome');
    }
  });
}

final class _Fixture {
  _Fixture(this.campione, this.tipo, this.righe, this.verita);

  final String campione;
  final String tipo;
  final List<RigaOcr> righe;
  final List<Map<String, String>> verita;
}

List<_Fixture> _carica(Directory d) {
  if (!d.existsSync()) return const [];
  final files = d.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final f in files)
      () {
        final j = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
        return _Fixture(
          j['campione']! as String,
          j['tipo']! as String,
          [for (final r in j['righe']! as List<Object?>) RigaOcr.fromJson(r! as Map<String, Object?>)],
          [
            for (final v in j['verita']! as List<Object?>)
              (v! as Map<String, Object?>).map((k, x) => MapEntry(k, '$x')),
          ],
        );
      }(),
  ];
}

/// "1,06" → 106; "1.100,00" → 110000; "0,258" → 258 (millesimi).
int? _cents(String? v) {
  if (v == null) return null;
  final m = RegExp(r'^(\d{1,3}(?:\.\d{3})*|\d+),(\d{2,3})$').firstMatch(v.trim());
  if (m == null) return null;
  return int.parse(m[1]!.replaceAll('.', '')) * (m[2]!.length == 3 ? 1000 : 100) + int.parse(m[2]!);
}

final class _Banco {
  final Map<String, int> giusti = {};
  final Map<String, int> totali = {};
  final Map<String, List<String>> sbagliati = {};
  double msMassimi = 0;
  String piuLento = '';

  void _conta(String campo, bool ok, String chi) {
    totali[campo] = (totali[campo] ?? 0) + 1;
    giusti[campo] = (giusti[campo] ?? 0) + (ok ? 1 : 0);
    if (!ok) (sbagliati[campo] ??= []).add(chi);
  }

  static _Banco misura(List<_Fixture> fixture) {
    final b = _Banco();
    final oggi = DateTime(2026, 10, 12);
    for (final f in fixture) {
      final sw = Stopwatch()..start();
      switch (f.tipo) {
        case 'cartellino':
          final l = const CartellinoParser().interpreta(f.righe);
          sw.stop();
          b._cartellino(f, l);
        case 'bilancia':
          final l = const BilanciaParser().interpreta(f.righe);
          sw.stop();
          b._bilancia(f, l);
        case 'scontrino':
          // ⚑ `oggi` fisso, e la data non si misura: i campioni hanno date di anni diversi.
          final l = const ScontrinoParser().interpreta(f.righe, oggi: oggi);
          sw.stop();
          b._scontrino(f, l);
      }
      final ms = sw.elapsedMicroseconds / 1000;
      if (ms > b.msMassimi) {
        b.msMassimi = ms;
        b.piuLento = '${f.campione} ${ms.toStringAsFixed(1)} ms';
      }
    }
    return b;
  }

  /// ⚑ Una verita' e' «presa» se la PRIMA proposta ha quel valore (F12.1.17). Con piu' cartellini
  /// nella stessa foto (verita' con piu' voci) basta una proposta qualunque: l'interfaccia le
  /// mostra tutte («Ho visto N cartellini: quale?») e solo una puo' essere la prima.
  void _cartellino(_Fixture f, LetturaCartellino l) {
    final proposte = f.verita.length > 1 ? l.proposte : l.proposte.take(1).toList();
    for (final v in f.verita) {
      final prezzo = _cents(v['prezzo']);
      final pieno = _cents(v['prezzo_pieno']);
      final alKg = _cents(v['al_kg']);
      final unita = v['unita'];
      final chi = '${f.campione} ${v['nome'] ?? ''}';
      if (prezzo != null) {
        _conta('cartellino.prezzo', proposte.any((p) {
          if (p.prezzo?.cents == prezzo) return true;
          final o = p.offerta;
          if (o is OffertaNxM && p.prezzo != null && o.effettivo(p.prezzo!).cents == prezzo) return true;
          // c24: «10,20» con unita' kg e senza al_kg e' un prezzo al kg.
          return alKg == null && (unita == 'kg' || unita == 'l') && p.unitario?.valore.cents == prezzo;
        }), chi);
      }
      if (pieno != null) {
        _conta('cartellino.prezzo_pieno', proposte.any((p) =>
            p.prezzoPieno?.cents == pieno || (p.prezzo?.cents == pieno && (p.offerta is OffertaNxM || prezzo == pieno))), chi);
      }
      if (alKg != null) {
        final u = unita == 'l' ? UnitaMisura.l : UnitaMisura.kg;
        _conta('cartellino.al_kg', proposte.any((p) => p.unitario?.valore.cents == alKg && p.unitario?.unita == u), chi);
      }
      // ⚑ F12.7: il nome, solo dove la verita' lo ha (vedi [_nomeOk]).
      final nome = v['nome'];
      if (nome != null && f.verita.length == 1) {
        _conta('cartellino.nome', proposte.isNotEmpty && _nomeOk(proposte.first.nome, nome), '$chi letto "${proposte.firstOrNull?.nome}"');
      }
      final attesa = _offertaAttesa(v);
      if (attesa != null) {
        _conta('cartellino.offerta', proposte.any((p) => attesa(p.offerta)), chi);
      }
    }
  }

  /// L'offerta attesa dalla verita': `offerta=3x1`, `offerta=2+1`, `sconto=-40%`, `sconto=0%`.
  /// «OFFERTA» generico (un cartello giallo) non e' un'offerta calcolabile: non si misura.
  static bool Function(Offerta?)? _offertaAttesa(Map<String, String> v) {
    final o = v['offerta'] ?? '';
    final nxm = RegExp(r'^(\d)\s*x\s*(\d)$').firstMatch(o);
    if (nxm != null) return (x) => x == OffertaNxM(prendi: int.parse(nxm[1]!), paghi: int.parse(nxm[2]!));
    final piu = RegExp(r'^(\d)\s*\+\s*1$').firstMatch(o);
    if (piu != null) return (x) => x == OffertaNxM(prendi: int.parse(piu[1]!) + 1, paghi: int.parse(piu[1]!));
    final s = RegExp(r'^-?(\d+)%$').firstMatch(v['sconto'] ?? '');
    if (s == null) return null;
    final x = int.parse(s[1]!);
    if (x == 0) return (o) => o == null;
    final pieno = _cents(v['prezzo_pieno']);
    if (pieno != null && pieno != _cents(v['prezzo'])) return (o) => o == OffertaPrezzoBarrato(Money.cents(pieno));
    return (o) => o == OffertaPercentuale(x);
  }

  void _bilancia(_Fixture f, LetturaBilancia? l) {
    final v = f.verita.first;
    _conta('bilancia.totale', l?.totale?.cents == _cents(v['totale']), f.campione);
    _conta('bilancia.peso_kg', l?.pesoNetto?.millesimi == _cents(v['peso_kg']), f.campione);
    _conta('bilancia.al_kg', l?.alKg?.cents == _cents(v['al_kg']), f.campione);
    // ⚑ F12.7: il nome del prodotto (col criterio del negozio: simile ≥ 0,8 o parole iniziali).
    final prodotto = v['prodotto'];
    if (prodotto != null) _conta('bilancia.prodotto', _negozioOk(l?.prodotto, prodotto), '${f.campione} letto "${l?.prodotto}"');
  }

  void _scontrino(_Fixture f, LetturaScontrino l) {
    final v = f.verita.first;
    _conta('scontrino.totale', l.totale?.cents == _cents(v['totale']), '${f.campione} letto ${l.totale}');
    final negozio = v['negozio'];
    if (negozio != null) {
      _conta('scontrino.negozio', _negozioOk(l.negozio, negozio), '${f.campione} letto "${l.negozio}"');
    }
    final righe = int.tryParse(v['righe'] ?? '');
    if (righe != null) {
      _conta('scontrino.righe', (l.articoli - righe).abs() <= 1, '${f.campione} letti ${l.articoli} su $righe');
    }
  }

  /// Il negozio e' «preso» se, tolti S.R.L./S.P.A./S.A.S./SNC da entrambi, la similarita' e'
  /// ≥ 0,8 (F12.1.17) **oppure** tutte le parole del nome piu' corto sono l'inizio del piu' lungo
  /// («INTERSPAR» per «INTERSPAR MAIORA S.R.L.», «EMME PIUI SUPERMERCATI» per «EMME PIU'»): e'
  /// cio' che basta per suggerire il negozio giusto.
  static bool _negozioOk(String? letto, String atteso) {
    if (letto == null) return false;
    String senza(String s) =>
        Nomi.normalizza(s).replaceAll(RegExp(r'\b(S R L|S P A|S A S|S N C|SRL|SPA|SAS|SNC)$'), '').trim();
    final a = senza(letto), b = senza(atteso);
    if (a.isEmpty || b.isEmpty) return false;
    if (Nomi.similarita(a, b) >= 0.8) return true;
    final pa = a.split(' '), pb = b.split(' ');
    final (corto, lungo) = pa.length <= pb.length ? (pa, pb) : (pb, pa);
    for (var i = 0; i < corto.length; i++) {
      final x = corto[i], y = lungo[i];
      if (!(x == y || (x.length >= 3 && y.startsWith(x)) || (y.length >= 3 && x.startsWith(y)))) return false;
    }
    return true;
  }

  /// Il nome del cartellino e' «preso» se almeno meta' delle sue parole significative (4+
  /// caratteri) sta nella verita' (uguale o con lo stesso inizio di 4 lettere), e almeno una. ⚑ Largo
  /// apposta: il nome nel foglio di conferma si corregge con un tocco, serve che sia QUEL prodotto.
  static bool _nomeOk(String letto, String atteso) {
    List<String> parole(String s) => Nomi.normalizza(s).split(' ').where((p) => p.length >= 4).toList();
    final l = parole(letto), a = parole(atteso);
    if (l.isEmpty || a.isEmpty) return false;
    final buone = l.where((x) => a.any((y) => x == y || (x.substring(0, 4) == y.substring(0, 4)))).length;
    return buone >= 1 && buone * 2 >= l.length;
  }

  void stampa(String titolo) {
    final b = StringBuffer('\nBanco del parser ($titolo):\n');
    for (final campo in (totali.keys.toList()..sort())) {
      final g = giusti[campo]!, t = totali[campo]!;
      b.writeln('  ${campo.padRight(26)} ${'$g'.padLeft(3)} / ${'$t'.padRight(3)} ${(100 * g / t).round()}%');
      final s = sbagliati[campo];
      if (s != null) b.writeln('      sbagliati: ${s.join('; ')}');
    }
    b.writeln('  parser piu\' lento: $piuLento');
    // ignore: avoid_print
    print(b);
  }
}

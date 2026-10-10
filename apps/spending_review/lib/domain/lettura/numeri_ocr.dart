import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/riga_ocr.dart';

/// Come e' stato trovato un numero: scritto per intero («2,49»), spezzato in due riquadri
/// (euro grandi + centesimi in apice), fuso senza separatore («229»), o un peso a 3 decimali.
enum FormaNumero { esplicito, spezzato, fuso, peso }

/// Un numero «da prezzo» trovato nel testo OCR, con il riquadro da cui viene (F12.1.4).
///
/// ⚑ Per [FormaNumero.peso] `valore.cents` vale i **millesimi** (0,258 → 258): il campo resta un
/// `Money` per avere una sola forma di numero nel parser; si legge con [millesimi].
@immutable
final class NumeroOcr {
  const NumeroOcr({required this.valore, required this.riquadro, required this.forma, required this.testo});

  final Money valore;

  /// Il riquadro del numero. ⚑ Per un numero dentro una riga piu' lunga («anziche' EUR 3,19 al
  /// pz») e' la porzione della riga in proporzione ai caratteri: l'OCR da' un riquadro per riga, e
  /// la colonna dei prezzi di uno scontrino si riconosce dalla posizione del numero, non della riga.
  final Riquadro riquadro;
  final FormaNumero forma;

  /// Il testo da cui viene (il pezzo della riga pulita).
  final String testo;

  /// I millesimi di un peso (solo [FormaNumero.peso]).
  int get millesimi => valore.cents;

  @override
  String toString() => 'NumeroOcr(${forma.name} ${valore.cents} "$testo")';
}

/// Estrazione e normalizzazione dei numeri dal testo OCR (F12.1.4).
abstract final class NumeriOcr {
  // ⚑ Lookbehind/lookahead: un numero non deve stare dentro un numero piu' lungo («08.01.2022»
  // non contiene il prezzo 8,01; «3049000414032» nessun prezzo).
  // ⚑ Un numero seguito da «%» e' una percentuale, non un prezzo: «12,50 % vol.» del vino (c09),
  // l'aliquota «22,00%» accanto al prezzo sugli scontrini (s16).
  static final RegExp _migliaia = RegExp(r'(?<![\d.,])(\d{1,3}(?:\.\d{3})+),(\d{2})(?![.,]?\d)(?!\s*%)');
  static final RegExp _semplice = RegExp(r'(?<![\d.,])(\d{1,4})[.,](\d{2,3})(?![.,]?\d)(?!\s*%)');

  /// Correzioni di lettura DENTRO i gruppi di cifre: O/o→0, I/l/|→1, S→5 (solo fra cifre o accanto
  /// a un separatore di cifre), «16..50»→«16,50», spazio fra cifre e separatore tolto
  /// («2 ,49»→«2,49», «2, 49»→«2,49»), «€» e «EUR» tolti.
  ///
  /// ⚑ «Fra cifre» e non «accanto a una cifra»: «0,5l» (mezzo litro) non deve diventare «0,51».
  /// ⚑ «EURO» resta: e' una parola chiave dello scontrino («TOTALE EURO»).
  static String pulisci(String testo) {
    var s = testo.replaceAll('€', ' ').replaceAll(RegExp(r'\bEUR\b', caseSensitive: false), ' ');
    s = s.replaceAllMapped(RegExp(r'(\d)\s*[.,]{2,}\s*(\d)'), (m) => '${m[1]},${m[2]}');
    s = s.replaceAllMapped(RegExp(r'(\d)\s+([.,])(\d)'), (m) => '${m[1]}${m[2]}${m[3]}');
    s = s.replaceAllMapped(RegExp(r'(\d)([.,])\s+(\d{2})(?!\d)'), (m) => '${m[1]}${m[2]}${m[3]}');
    final c = s.split('');
    bool cifra(int i) => i >= 0 && i < c.length && RegExp(r'\d').hasMatch(c[i]);
    bool sep(int i) => i >= 0 && i < c.length && (c[i] == ',' || c[i] == '.');
    for (var i = 0; i < c.length; i++) {
      final sostituto = switch (c[i]) {
        'O' || 'o' => '0',
        'I' || 'l' || '|' => '1',
        'S' => '5',
        _ => null,
      };
      if (sostituto == null) continue;
      final fra = cifra(i - 1) && cifra(i + 1);
      // Accanto al separatore («O,99», «3,l9»), o — solo per la O — ultima cifra dei decimali
      // («10,5O»). ⚑ Non per la l: «0,5l» e' mezzo litro.
      final accantoSep = (sep(i - 1) && cifra(i - 2)) ||
          (sep(i + 1) && cifra(i + 2)) ||
          (sostituto == '0' && cifra(i - 1) && sep(i - 2));
      if (fra || accantoSep) c[i] = sostituto;
    }
    return c.join().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// I numeri espliciti di una riga: `\d{1,4}(\.\d{3})*[,.]\d{2}`, piu' i pesi a 3 decimali
  /// («0,258», [FormaNumero.peso]). «1.100,00» → 1100,00 (migliaia, c26). Negativi: «-0,40» e
  /// «0,40-».
  /// ⚑ Il testo si pulisce qui dentro: chi chiama passa la riga com'e'.
  static List<NumeroOcr> espliciti(RigaOcr riga) {
    final testo = pulisci(riga.testo);
    final out = <NumeroOcr>[];
    final presi = <(int, int)>[];
    for (final m in _migliaia.allMatches(testo)) {
      final cents = int.parse(m[1]!.replaceAll('.', '')) * 100 + int.parse(m[2]!);
      presi.add((m.start, m.end));
      out.add(_numero(riga, testo, m.start, m.end, _segno(testo, m.start, m.end) * cents, FormaNumero.esplicito));
    }
    for (final m in _semplice.allMatches(testo)) {
      if (presi.any((p) => m.start < p.$2 && m.end > p.$1)) continue;
      final decimali = m[2]!;
      final peso = decimali.length == 3;
      final valore = int.parse(m[1]!) * (peso ? 1000 : 100) + int.parse(decimali);
      out.add(_numero(
        riga,
        testo,
        m.start,
        m.end,
        peso ? valore : _segno(testo, m.start, m.end) * valore,
        peso ? FormaNumero.peso : FormaNumero.esplicito,
      ));
    }
    out.sort((a, b) => a.riquadro.sinistra.compareTo(b.riquadro.sinistra));
    return out;
  }

  /// -1 se il numero ha un meno davanti («-0,40», «- 0,40») o dietro («0,40-»).
  static int _segno(String t, int inizio, int fine) {
    final prima = t.substring(0, inizio);
    final dopo = t.substring(fine);
    if (RegExp(r'[-−]\s?$').hasMatch(prima)) return -1;
    if (RegExp(r'^[-−](?!\d)').hasMatch(dopo)) return -1;
    return 1;
  }

  static NumeroOcr _numero(RigaOcr riga, String testo, int inizio, int fine, int valore, FormaNumero forma) {
    final r = riga.riquadro;
    final n = testo.isEmpty ? 1 : testo.length;
    return NumeroOcr(
      valore: Money.cents(valore),
      riquadro: Riquadro(
        sinistra: r.sinistra + r.larghezza * inizio / n,
        alto: r.alto,
        larghezza: r.larghezza * (fine - inizio) / n,
        altezza: r.altezza,
      ),
      forma: forma,
      testo: testo.substring(inizio, fine),
    );
  }

  /// Euro grandi + centesimi piccoli in apice in DUE riquadri (c01: "1" | "06" → 1,06). Regola:
  /// A ha solo 1..4 cifre; B ha esattamente 2 cifre; B.altezza fra 0,25 e 0,75 × A.altezza;
  /// B.sinistra fra A.destra − 0,2·A.altezza e A.destra + 0,6·A.altezza; B.alto ≤ A.alto +
  /// 0,5·A.altezza. Il riquadro del risultato e' quello di A (le cifre grandi) allargato a B.
  /// ⚑ Le soglie orizzontali sono in altezze di A (la specsheet): le coordinate sono normalizzate
  /// separatamente su x e y, quindi su una foto molto stretta o larga la tolleranza cambia un po'.
  static List<NumeroOcr> spezzati(List<RigaOcr> righe) {
    final out = <NumeroOcr>[];
    final euro = RegExp(r'^\d{1,4}[,.]?$');
    final cent = RegExp(r'^[,.]?\d{2}$');
    for (final a in righe) {
      final ta = pulisci(a.testo);
      if (!euro.hasMatch(ta)) continue;
      final ra = a.riquadro;
      for (final b in righe) {
        if (identical(a, b)) continue;
        final tb = pulisci(b.testo);
        if (!cent.hasMatch(tb)) continue;
        final rb = b.riquadro;
        if (rb.altezza < 0.25 * ra.altezza || rb.altezza > 0.75 * ra.altezza) continue;
        if (rb.sinistra < ra.destra - 0.2 * ra.altezza || rb.sinistra > ra.destra + 0.6 * ra.altezza) continue;
        // ⚑ 0,5 e non lo 0,35 della specsheet: in c02 i centesimi («,68», «38») partono appena
        // sotto il terzo superiore delle cifre grandi e con 0,35 si perdevano per un millesimo.
        // Meta' altezza resta «in apice» (sopra il centro delle cifre grandi).
        if (rb.alto > ra.alto + 0.5 * ra.altezza) continue;
        final e = int.parse(ta.replaceAll(RegExp(r'[,.]'), ''));
        final c = int.parse(tb.replaceAll(RegExp(r'[,.]'), ''));
        out.add(NumeroOcr(
          valore: Money.cents(e * 100 + c),
          riquadro: Riquadro(
            sinistra: ra.sinistra,
            alto: ra.alto,
            larghezza: rb.destra - ra.sinistra,
            altezza: ra.altezza,
          ),
          forma: FormaNumero.spezzato,
          testo: '$ta|$tb',
        ));
        break;
      }
    }
    return out;
  }

  /// Cifre senza separatore in un riquadro alto (c33: "229" → 2,29): 3..5 cifre, nessun altro
  /// carattere, altezza ≥ 1,5 × mediana delle altezze delle altre righe con lettere. Le ultime 2
  /// cifre sono i centesimi. Senza righe con lettere non c'e' termine di paragone: nessun fuso.
  static List<NumeroOcr> fusi(List<RigaOcr> righe) {
    final altezze = [
      for (final r in righe)
        if (RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(r.testo)) r.riquadro.altezza,
    ]..sort();
    if (altezze.isEmpty) return const [];
    final mediana = altezze[altezze.length ~/ 2];
    final out = <NumeroOcr>[];
    for (final r in righe) {
      final t = pulisci(r.testo);
      if (!RegExp(r'^\d{3,5}$').hasMatch(t)) continue;
      if (r.riquadro.altezza < 1.5 * mediana) continue;
      out.add(NumeroOcr(valore: Money.cents(int.parse(t)), riquadro: r.riquadro, forma: FormaNumero.fuso, testo: t));
    }
    return out;
  }
}

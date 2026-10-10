import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/riga_ocr.dart';
import 'package:spending_review/domain/lettura/scontrino_parser.dart';
import 'package:spending_review/domain/quantita.dart';

import 'righe_finte.dart';

/// F12.1.6: lo scontrino, con righe finte nello stile dei campioni citati (i numeri della verita'
/// sono fatti e si usano; descrizioni e negozi inventati).
void main() {
  const parser = ScontrinoParser();
  final oggi = DateTime(2026, 10, 12);
  Money e(int c) => Money.cents(c);

  /// Uno scontrino da righe (descrizione, importo): testata, corpo, totale, piede.
  List<RigaOcr> scontrino(List<(String, String?)> corpo, {String totale = '', List<String> piede = const []}) {
    var n = 0;
    return [
      ...rigaScontrino(n++, 'SUPERMERCATO ESEMPIO S.R.L.'),
      ...rigaScontrino(n++, 'VIA ROMA 1 - 00100 ROMA'),
      ...rigaScontrino(n++, 'P.IVA 01234567890'),
      ...rigaScontrino(n++, 'DOCUMENTO COMMERCIALE'),
      ...rigaScontrino(n++, 'di vendita o prestazione'),
      ...rigaScontrino(n++, 'DESCRIZIONE IVA', 'Prezzo(€)'),
      for (final (d, i) in corpo) ...rigaScontrino(n++, d, i),
      if (totale.isNotEmpty) ...rigaScontrino(n++, 'TOTALE COMPLESSIVO', totale),
      for (final p in piede) ...rigaScontrino(n++, p),
    ];
  }

  test('s01: totale, articoli, colonna IVA tolta, riga pesata attaccata', () {
    final l = parser.interpreta(
      scontrino([
        ('ACQUA NATURALE 1,5L 10%', '1,32'),
        ('PORRIDGE AVENA 10%', '1,65'),
        ('PORRIDGE AVENA 10%', '1,65'),
        ('TAVOLETTA LATTE 10%', '2,85'),
        ('CRACKER INTEGRALI 10%', '2,85'),
        ('MELE VERDI 4%', '1,53'),
        ('0,612 kg x 2,50 €/kg', null),
      ], totale: '11,85'),
      oggi: oggi,
    );
    expect(l.totale, e(1185));
    expect(l.articoli, 6);
    expect(l.righe[0].descrizione, 'ACQUA NATURALE 1,5L');
    expect(l.righe[5].quantita, const AMisura(612, UnitaMisura.kg));
    expect(l.righe[5].prezzoUnitario, e(250));
    expect(l.quadra, isTrue);
    expect(l.negozio, 'SUPERMERCATO ESEMPIO S.R.L.');
    expect(l.negozioMostrato, 'SUPERMERCATO ESEMPIO');
  });

  test('F12.7 (Vision su s01): «TOTALE COMPLESSIVO» senza importo chiude il corpo; il totale da pagato = somma', () {
    final l = parser.interpreta(
      [
        ...rigaScontrino(0, 'DOCUMENTO COMMERCIALE'),
        ...rigaScontrino(2, 'ACQUA NATURALE', '1,32'),
        ...rigaScontrino(3, 'BISCOTTI', '2,85'),
        ...rigaScontrino(5, 'TOTALE COMPLESSIVO'),
        ...rigaScontrino(7, 'Pagamento elettronico', '4,17'),
        ...rigaScontrino(8, 'Importo pagato', '4,17'),
      ],
      oggi: oggi,
    );
    expect(l.articoli, 2);
    expect(l.totale, e(417));
  });

  test('F12.7: asterischi in coda alla descrizione tolti («CREMA GR200 ****», s06)', () {
    final l = parser.interpreta(
      [
        ...rigaScontrino(0, 'DOCUMENTO COMMERCIALE'),
        ...rigaScontrino(2, 'CREMA GR200 ****', '2,19'),
        ...rigaScontrino(3, 'BISCOTTI****', '1,29'),
        ...rigaScontrino(4, 'TOTALE EURO', '3,48'),
      ],
      oggi: oggi,
    );
    expect([for (final r in l.righe) r.descrizione], ['CREMA GR200', 'BISCOTTI']);
  });

  test('F12.7: negozioMostrato senza la punteggiatura finale («EMME Piu Supermercati.», s06)', () {
    String? mostrato(String n) => LetturaScontrino(negozio: n, righe: const [], righeIgnorate: 0).negozioMostrato;
    expect(mostrato('ESEMPIO Piu Supermercati.'), 'ESEMPIO Piu Supermercati');
    expect(mostrato('BOTTEGA ESEMPIO S.N.C. -'), 'BOTTEGA ESEMPIO');
    expect(mostrato("SUPER 'S'"), "SUPER 'S'");
    expect(mostrato('.'), '.'); // tutto punteggiatura: meglio il testo com'e' che niente
  });

  test('s03: 4 righe pesate, totale 7,39 che quadra', () {
    final l = parser.interpreta(
      scontrino([
        ('PIZZA ROSSA 0,248 kg x 12,50', '3,10'),
        ('PIZZA BIANCA 0,186 kg x 14,00', '2,60'),
        ('FOCACCIA 0,126 kg x 7,50', '0,95'),
        ('FOCACCIA 0,098 kg x 7,50', '0,74'),
      ], totale: '7,39'),
      oggi: oggi,
    );
    expect([for (final r in l.righe) r.importo.cents], [310, 260, 95, 74]);
    expect([for (final r in l.righe) (r.quantita! as AMisura).millesimi], [248, 186, 126, 98]);
    expect(l.quadra, isTrue);
  });

  test('s06: «OFFERTA -0,40» e\' uno sconto; totale 6,15 = somma', () {
    final l = parser.interpreta(
      scontrino([('CORNETTI GR.270', '2,19'), ('OFFERTA', '-0,40'), ('BISCOTTI', '1,29'), ('CREMA GR200', '2,19'), ('PASTA KG', '0,88')], totale: '6,15'),
      oggi: oggi,
    );
    expect(l.righe[1].tipo, TipoRigaScontrino.sconto);
    expect(l.righe[1].importo, e(-40));
    expect(l.totale, e(615));
    expect(l.quadra, isTrue);
    expect(l.articoli, 4);
  });

  test('s07: righe uguali «ACQUA …» con la quantita\' su una riga separata', () {
    final l = parser.interpreta(
      scontrino([
        ('ACQUA MINER. NATURAL', '0,35'),
        ('ACQUA MINER. NATURAL', '0,35'),
        ('ACQUA MINER. NATURAL', '0,35'),
        ('6 x 0,35', null),
        ('ACQUA MINER. NATURAL', '2,10'),
      ], totale: '3,15'),
      oggi: oggi,
    );
    expect(l.articoli, 4);
    expect(l.righe[3].quantita, const Pezzi(6));
    expect(l.righe[3].prezzoUnitario, e(35));
    expect(l.quadra, isTrue);
  });

  test('la quantita\' prima della descrizione si attacca all\'articolo dopo', () {
    final l = parser.interpreta(scontrino([('2 x 1,29', null), ('BISCOTTI FROLLINI', '2,58')], totale: '2,58'), oggi: oggi);
    expect(l.righe.single.quantita, const Pezzi(2));
  });

  test('s10: «REPARTO 1»: righe valide anche senza nome di prodotto', () {
    final l = parser.interpreta(scontrino([('REPARTO 1', '21,90'), ('REPARTO 1', '12,50')], totale: '34,40'), oggi: oggi);
    expect(l.articoli, 2);
    expect(l.quadra, isTrue);
  });

  test('s11: quantita\' in testa alla descrizione', () {
    final l = parser.interpreta(
      scontrino([('3 COPERTO/ANTIPASTO', '3,90'), ('2 CONTORNI/BEVANDE', '4,00'), ('3 PIZZERIA', '10,50'), ('1 VARIE', '2,00')], totale: '20,40'),
      oggi: oggi,
    );
    expect(l.righe[0].quantita, const Pezzi(3));
    expect(l.righe[0].prezzoUnitario, e(130));
    expect(l.righe[1].quantita, const Pezzi(2));
    expect(l.righe[2].quantita, const Pezzi(3));
    expect(l.righe[2].prezzoUnitario, e(350));
  });

  test('s16: storno: l\'articolo stornato marcato, 2 articoli veri, totale 4,78', () {
    final l = parser.interpreta(
      scontrino([
        ('LATTE FRESCO BIO 4%', '2,49'),
        ('STORNO LATTE FRESCO BIO', '-2,49'),
        ('SCATOLAME DOLCE 22%', '2,39'),
        ('SCATOLAME DOLCE 22%', '2,39'),
      ], totale: '4,78'),
      oggi: oggi,
    );
    expect(l.righe[0].stornata, isTrue);
    expect(l.righe[1].tipo, TipoRigaScontrino.storno);
    expect(l.articoli, 2);
    expect(l.totale, e(478));
    expect(l.quadra, isTrue);
  });

  test('pagamento: le righe dopo il totale non compaiono da nessuna parte (☠ s13)', () {
    final l = parser.interpreta(
      scontrino(
        [('PANE', '1,20')],
        totale: '1,20',
        piede: ['PAGAMENTO ELETTRONICO 1,20', '************1234', 'AUT. 123456', 'TERMINALE 99887766'],
      ),
      oggi: oggi,
    );
    expect(l.righe, hasLength(1));
    for (final r in l.righe) {
      expect(r.descrizione, isNot(contains('1234')));
      expect(r.descrizione, isNot(contains('AUT')));
    }
    expect(l.righeIgnorate, 0);
  });

  group('data', () {
    test('«10-10-26 18:32» → 2026-10-10', () {
      final l = parser.interpreta(scontrino([('PANE', '1,20')], totale: '1,20', piede: ['10-10-26 18:32 DOC.N. 0123-0045']), oggi: oggi);
      expect(l.data, CivilDate(2026, 10, 10));
    });
    test('una data nel 2031 → null; piu\' vecchia di un anno → null', () {
      expect(parser.interpreta(scontrino([('PANE', '1,20')], totale: '1,20', piede: ['10/10/2031']), oggi: oggi).data, isNull);
      expect(parser.interpreta(scontrino([('PANE', '1,20')], totale: '1,20', piede: ['10/10/2024']), oggi: oggi).data, isNull);
    });
  });

  test('non quadra: una riga persa → quadra false, righeIgnorate > 0', () {
    final l = parser.interpreta(scontrino([('PANE', '1,20'), ('%%%% 12', '9,99'), ('LATTE', '1,50')], totale: '12,69'), oggi: oggi);
    expect(l.quadra, isFalse);
    expect(l.righeIgnorate, greaterThan(0));
  });

  test('vecchio formato senza «documento commerciale»: la testata finisce al primo importo', () {
    var n = 0;
    final l = parser.interpreta([
      ...rigaScontrino(n++, 'BOTTEGA ESEMPIO SNC'),
      ...rigaScontrino(n++, 'TEL. 06 1234567'),
      ...rigaScontrino(n++, 'PANE', '1,20'),
      ...rigaScontrino(n++, 'LATTE', '1,50'),
      ...rigaScontrino(n++, 'TOTALE EURO', '2,70'),
      ...rigaScontrino(n++, 'SCONTRINO FISCALE N. 201'),
    ], oggi: oggi);
    expect(l.negozio, 'BOTTEGA ESEMPIO SNC');
    expect(l.totale, e(270));
    expect(l.articoli, 2);
  });

  test('un TOTALE letto male si corregge con subtotale e contanti − resto (s02)', () {
    var n = 0;
    final l = parser.interpreta([
      ...rigaScontrino(n++, 'NEGOZIO ESEMPIO'),
      ...rigaScontrino(n++, 'PANE', '1,20'),
      ...rigaScontrino(n++, 'LATTE', '1,50'),
      ...rigaScontrino(n++, 'SUBT.', '2,70'),
      ...rigaScontrino(n++, 'TOTALE', '2,20'),
      ...rigaScontrino(n++, 'CONTANTI', '5,00'),
      ...rigaScontrino(n++, 'RESTO', '2,30'),
    ], oggi: oggi);
    expect(l.totale, e(270));
  });

  test('scontrino della bilancia senza la parola TOTALE: l\'ultimo importo che vale la somma', () {
    var n = 0;
    final l = parser.interpreta([
      ...rigaScontrino(n++, 'PANIFICIO ESEMPIO'),
      ...rigaScontrino(n++, 'PANE', '1,20'),
      ...rigaScontrino(n++, 'PIZZA', '2,50'),
      ...rigaScontrino(n++, '', '3,70'),
    ], oggi: oggi);
    expect(l.totale, e(370));
    expect(l.articoli, 2);
  });
}

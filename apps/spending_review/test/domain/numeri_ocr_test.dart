import 'package:flutter_test/flutter_test.dart';
import 'package:spending_review/domain/lettura/numeri_ocr.dart';

import 'righe_finte.dart';

/// F12.1.4: pulizia del testo OCR, numeri espliciti, spezzati e fusi.
void main() {
  group('pulisci', () {
    test('O→0, I/l/|→1, S→5 solo fra cifre o accanto al separatore', () {
      expect(NumeriOcr.pulisci('2,O9'), '2,09');
      expect(NumeriOcr.pulisci('1O,5O'), '10,50');
      expect(NumeriOcr.pulisci('3,l9'), '3,19');
      expect(NumeriOcr.pulisci('2S,90'), '25,90');
      expect(NumeriOcr.pulisci('SOLE 0,5l'), 'SOLE 0,5l'); // mezzo litro non diventa 0,51
    });
    test('«16..50» → «16,50»; «2 ,49» e «2, 49» → «2,49»', () {
      expect(NumeriOcr.pulisci('16..50'), '16,50');
      expect(NumeriOcr.pulisci('2 ,49'), '2,49');
      expect(NumeriOcr.pulisci('2, 49'), '2,49');
    });
    test('€ ed EUR tolti, EURO resta (parola dello scontrino)', () {
      expect(NumeriOcr.pulisci('€13.60'), '13.60');
      expect(NumeriOcr.pulisci('EUR 3,19'), '3,19');
      expect(NumeriOcr.pulisci('TOTALE EURO 6,15'), 'TOTALE EURO 6,15');
    });
  });

  group('espliciti', () {
    List<int> valori(String t) => [for (final n in NumeriOcr.espliciti(r(t, 0, 0, 1, 0.1))) n.valore.cents];

    test('prezzi semplici con virgola e con punto', () {
      expect(valori('anziche\' € 3,19 al pz'), [319]);
      expect(valori('1.99'), [199]);
    });
    test('migliaia: «1.100,00» → 1100,00 (c26)', () => expect(valori('1.100,00 €/kg'), [110000]));
    test('negativi: «-0,40» e «0,40-»', () {
      expect(valori('SCONTO -0,40'), [-40]);
      expect(valori('OFFERTA 0,40-'), [-40]);
    });
    test('pesi a 3 decimali', () {
      final n = NumeriOcr.espliciti(r('0,258 kg', 0, 0, 1, 0.1)).single;
      expect(n.forma, FormaNumero.peso);
      expect(n.millesimi, 258);
    });
    test('non dentro numeri piu\' lunghi: date, codici, percentuali', () {
      expect(valori('08.01.2022 13:10'), isEmpty);
      expect(valori('3049000414032'), isEmpty);
      expect(valori('12,50 % vol.'), isEmpty);
      expect(valori('IVA 22,00% 2,39'), [239]);
    });
    test('il riquadro del numero e\' la sua porzione della riga', () {
      final n = NumeriOcr.espliciti(r('ACQUA 1,05', 0, 0, 1, 0.1)).single;
      expect(n.riquadro.sinistra, closeTo(0.6, 1e-9));
      expect(n.riquadro.destra, closeTo(1, 1e-9));
    });
  });

  group('spezzati: euro grandi + centesimi in apice (c01: «1» | «06»)', () {
    test('trovato', () {
      final s = NumeriOcr.spezzati([r('1', 0.30, 0.30, 0.10, 0.20), r('06', 0.41, 0.31, 0.08, 0.10)]);
      expect(s.single.valore.cents, 106);
      expect(s.single.forma, FormaNumero.spezzato);
    });
    test('centesimi troppo grandi, troppo lontani o troppo in basso: niente', () {
      expect(NumeriOcr.spezzati([r('1', 0.30, 0.30, 0.10, 0.20), r('06', 0.41, 0.31, 0.08, 0.19)]), isEmpty);
      expect(NumeriOcr.spezzati([r('1', 0.30, 0.30, 0.10, 0.20), r('06', 0.70, 0.31, 0.08, 0.10)]), isEmpty);
      expect(NumeriOcr.spezzati([r('1', 0.30, 0.30, 0.10, 0.20), r('06', 0.41, 0.45, 0.08, 0.10)]), isEmpty);
    });
  });

  group('fusi: «229» alto → 2,29 (c33)', () {
    test('trovato se alto almeno 1,5 volte la mediana delle righe con lettere', () {
      final righe = [r('MACINATO DI POLLO', 0.1, 0.1, 0.5, 0.05), r('229', 0.3, 0.3, 0.3, 0.15), r('300 G', 0.1, 0.5, 0.2, 0.05)];
      expect(NumeriOcr.fusi(righe).single.valore.cents, 229);
    });
    test('basso come il testo: no (e\' un codice o un formato)', () {
      final righe = [r('MACINATO DI POLLO', 0.1, 0.1, 0.5, 0.05), r('229', 0.3, 0.3, 0.3, 0.06)];
      expect(NumeriOcr.fusi(righe), isEmpty);
    });
  });
}

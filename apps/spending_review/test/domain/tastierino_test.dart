import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/domain/tastierino.dart';

/// F12.1.3: ogni riga della tabella del tastierino «alla cassa» (risposta D2), piu' le sequenze.
void main() {
  /// Batte i tasti uno dopo l'altro e restituisce lo stato e l'ultimo effetto.
  (TastierinoState, EffettoTasto) batti(String sequenza, {TastierinoState? da}) {
    var s = da ?? const TastierinoState.vuoto();
    EffettoTasto ultimo = const NessunEffetto();
    for (final t in sequenza.split(' ').where((t) => t.isNotEmpty)) {
      final tasto = switch (t) {
        '00' => TastoTastierino.c00,
        ',' => TastoTastierino.virgola,
        'x' => TastoTastierino.per,
        '-' => TastoTastierino.meno,
        '<' => TastoTastierino.cancella,
        '+' => TastoTastierino.piu,
        _ => TastoTastierino.values[int.parse(t)],
      };
      (s, ultimo) = s.premi(tasto);
    }
    return (s, ultimo);
  }

  String display(String sequenza) => batti(sequenza).$1.display;
  EffettoTasto effetto(String sequenza) => batti(sequenza).$2;
  AggiungiRiga riga(int cents, int pezzi) => AggiungiRiga(prezzo: Money.cents(cents), pezzi: pezzi);
  const rifiutato = NessunEffetto(rifiutato: true);

  group('la tabella', () {
    test('cifre senza virgola: entrano da destra come centesimi', () {
      expect(display('2'), '0,02');
      expect(display('2 4'), '0,24');
      expect(display('2 4 9'), '2,49');
    });

    test('«00» come due zeri (il tasto delle casse)', () => expect(display('3 00'), '3,00'));

    test('virgola: le cifre battute diventano euro, poi al massimo 2 decimali', () {
      expect(display('2 ,'), '2,');
      expect(display('2 , 5'), '2,5');
      expect(effetto('2 , 5 +'), riga(250, 1));
      expect(display(', 9 9'), '0,99');
    });

    test('dopo la virgola, gia\' 2 decimali: la cifra e\' rifiutata', () {
      expect(effetto('2 , 4 9 1'), rifiutato);
      expect(display('2 , 4 9 1'), '2,49');
    });

    test('prezzo oltre 9999,99: la cifra e\' rifiutata', () {
      expect(display('9 9 9 9 9 9'), '9999,99');
      expect(effetto('9 9 9 9 9 9 9'), rifiutato);
    });

    test('numero corto, niente ×: «×» lo fa diventare la quantita\'', () {
      expect(display('3 x'), '3 ×');
      expect(display('3 x 2 4 9'), '3 × 2,49');
    });

    test('prezzo battuto: «×» lo tiene, il numero dopo e\' la quantita\'', () {
      expect(display('2 4 9 x'), '2,49 ×');
      expect(display('2 4 9 x 3'), '2,49 × 3');
      expect(display('2 , 4 9 x 3'), '2,49 × 3');
    });

    test('quantita\' 0 o oltre 99: «+» rifiutato', () {
      expect(effetto('0 x 2 4 9 +'), rifiutato);
      expect(effetto('2 4 9 x 0 +'), rifiutato);
      expect(effetto('2 4 9 x 1 2 0 +'), rifiutato);
      expect(effetto('2 4 9 x 1 2 3 4'), rifiutato); // la quarta cifra non entra
    });

    test('display vuoto: «−» mette il segno; poi la riga e\' uno sconto da 1 pezzo', () {
      expect(display('-'), '−');
      expect(display('- 1 5 0'), '− 1,50');
      expect(effetto('- 1 5 0 +'), riga(-150, 1));
    });

    test('display non vuoto: «−» inverte il segno', () {
      expect(display('1 5 0 -'), '− 1,50');
      expect(display('1 5 0 - -'), '1,50');
    });

    test('niente segno dentro una moltiplicazione', () {
      expect(effetto('3 x -'), rifiutato);
      expect(effetto('- 3 x'), rifiutato);
    });

    test('⌫ toglie l\'ultimo carattere logico (cifra, virgola, ×, −)', () {
      expect(display('2 4 9 <'), '0,24');
      expect(display('2 , <'), '0,02');
      expect(display('3 x <'), '0,03');
      expect(display('- <'), '');
      expect(display('3 00 <'), '0,30'); // «00» entra come due zeri: ⌫ ne toglie uno
      expect(effetto('<'), const NessunEffetto());
    });

    test('pressione lunga su ⌫: svuota', () {
      final (s, _) = batti('3 x 2 4 9');
      expect(s.svuota().vuoto, isTrue);
      expect(s.svuota().display, '');
    });

    test('valore valido: «+» aggiunge e svuota', () {
      final (s, e) = batti('2 4 9 +');
      expect(e, riga(249, 1));
      expect(s.vuoto, isTrue);
    });

    test('display vuoto: «+» = un pezzo in piu\' all\'ultima riga', () {
      expect(effetto('+'), const IncrementaUltima());
    });

    test('valore 0,00: «+» rifiutato', () {
      expect(effetto('0 +'), rifiutato);
      expect(effetto('00 +'), rifiutato);
      expect(effetto(', +'), rifiutato);
      expect(effetto('- +'), rifiutato);
    });

    test('«×» due volte o a display vuoto: rifiutato', () {
      expect(effetto('x'), rifiutato);
      expect(effetto('3 x x'), rifiutato);
    });

    test('virgola nella quantita\' battuta dopo il prezzo: rifiutata', () {
      expect(effetto('2 4 9 x ,'), rifiutato);
    });
  });

  group('le sequenze complete', () {
    test('«2 4 9 +»', () => expect(effetto('2 4 9 +'), riga(249, 1)));
    test('«2 , 4 9 +»', () => expect(effetto('2 , 4 9 +'), riga(249, 1)));
    test('«3 00 +»', () => expect(effetto('3 00 +'), riga(300, 1)));
    test('«3 × 2 4 9 +»', () => expect(effetto('3 x 2 4 9 +'), riga(249, 3)));
    test('«2 4 9 × 3 +»', () => expect(effetto('2 4 9 x 3 +'), riga(249, 3)));
    test('«− 1 5 0 +»', () => expect(effetto('- 1 5 0 +'), riga(-150, 1)));
    test('«3 +» = 0,03 € (D2: si vede sul display prima del +)', () {
      expect(display('3'), '0,03');
      expect(effetto('3 +'), riga(3, 1));
    });
    test('«3 , +» = 3,00 €', () => expect(effetto('3 , +'), riga(300, 1)));
    test('«2 4 9 ×» senza quantita\': «+» rifiutato', () => expect(effetto('2 4 9 x +'), rifiutato));
    test('«3 ×» senza prezzo: «+» rifiutato', () => expect(effetto('3 x +'), rifiutato));
  });

  group('daPrezzo («Batti a mano» dal cartellino)', () {
    test('2,49 → «2 4 9»', () {
      final s = TastierinoState.daPrezzo(Money.cents(249));
      expect(s.display, '2,49');
      expect(s.premi(TastoTastierino.piu).$2, riga(249, 1));
    });
    test('0,05 → «0,05»', () => expect(TastierinoState.daPrezzo(Money.cents(5)).display, '0,05'));
    test('oltre il massimo → vuoto', () => expect(TastierinoState.daPrezzo(Money.cents(1000000)).vuoto, isTrue));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/domain/quantita.dart';
import 'package:spending_review/domain/riga_spesa.dart';
import 'package:spending_review/domain/spesa.dart';

/// F12.1.3: il totale di una spesa per fonte, gli articoli, il budget ai bordi.
void main() {
  RigaSpesa riga(int cents, {Quantita q = const Pezzi(1)}) => RigaSpesa(
    nome: '',
    quantita: q,
    prezzoUnitario: Money.cents(cents),
    origine: OrigineRiga.tastierino,
  );

  group('Spesa', () {
    Spesa spesa(List<RigaSpesa> righe, {int? budget, FonteRighe fonte = FonteRighe.contate, int? stampato, List<RigaSpesa> sc = const []}) =>
        Spesa(
          stato: StatoSpesa.inCorso,
          iniziataIl: DateTime.utc(2026, 10, 10),
          righe: righe,
          budget: budget == null ? null : Money.cents(budget),
          fonte: fonte,
          totaleScontrino: stampato == null ? null : Money.cents(stampato),
          righeScontrino: sc,
        );

    test('totale per fonte: contate, scontrino stampato, somma delle righe dello scontrino', () {
      final contate = [riga(100), riga(200)];
      expect(spesa(contate).totale, Money.cents(300));
      expect(spesa(contate, fonte: FonteRighe.scontrino, stampato: 315).totale, Money.cents(315));
      expect(spesa(contate, fonte: FonteRighe.scontrino, sc: [riga(150), riga(165)]).totale, Money.cents(315));
    });

    test('il totale salvato alla chiusura vince sul ricalcolo', () {
      final s = Spesa(
        stato: StatoSpesa.chiusa,
        iniziataIl: DateTime.utc(2026),
        righe: [riga(100)],
        totaleSalvato: Money.cents(999),
      );
      expect(s.totale, Money.cents(999));
      expect(s.totaleContato, Money.cents(100));
    });

    test('articoli: pezzi + 1 per riga a misura, sconti esclusi', () {
      final s = spesa([riga(100, q: const Pezzi(3)), riga(500, q: const AMisura(250, UnitaMisura.kg)), riga(-50)]);
      expect(s.articoli, 4);
    });

    test('residuo e livello del budget ai bordi 79,99% / 80% / 100% / 100,01%', () {
      expect(spesa([riga(7999)], budget: 10000).livelloBudget, LivelloBudget.ok);
      expect(spesa([riga(8000)], budget: 10000).livelloBudget, LivelloBudget.vicino);
      expect(spesa([riga(10000)], budget: 10000).livelloBudget, LivelloBudget.vicino);
      expect(spesa([riga(10001)], budget: 10000).livelloBudget, LivelloBudget.sforato);
      expect(spesa([riga(10001)], budget: 10000).residuoBudget, Money.cents(-1));
      expect(spesa([riga(4370)], budget: 6000).residuoBudget, Money.cents(1630));
    });

    test('senza budget: nessun livello, nessun residuo, non sforata', () {
      final s = spesa([riga(10000)]);
      expect(s.livelloBudget, LivelloBudget.nessuno);
      expect(s.residuoBudget, isNull);
      expect(s.sforata, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/domain/quantita.dart';
import 'package:spending_review/domain/riga_spesa.dart';
import 'package:spending_review/domain/spesa.dart';
import 'package:spending_review/domain/statistiche.dart';

/// F12.1.8: un dataset noto di 12 spese su 3 mesi e 3 negozi, piu' il budget del mese (D3).
void main() {
  Money e(int c) => Money.cents(c);

  Spesa chiusa(CivilDate d, int totale, {int? negozio, int? budget, FonteRighe fonte = FonteRighe.contate}) => Spesa(
    stato: StatoSpesa.chiusa,
    iniziataIl: d.toLocalMidnight(),
    chiusaIl: d.toLocalMidnight(),
    dataSpesa: d,
    negozioId: negozio,
    budget: budget == null ? null : e(budget),
    righe: [RigaSpesa(nome: '', quantita: const Pezzi(1), prezzoUnitario: e(totale), origine: OrigineRiga.tastierino)],
    fonte: fonte,
    totaleSalvato: e(totale),
  );

  // Agosto: 4 spese (2 con budget, 1 sforata). Settembre: 5. Ottobre: 3. Negozi 1, 2, 3, null.
  final spese = [
    chiusa(CivilDate(2026, 8, 2), 4000, negozio: 1, budget: 5000),
    chiusa(CivilDate(2026, 8, 9), 6000, negozio: 1, budget: 5000), // sforata
    chiusa(CivilDate(2026, 8, 16), 2000, negozio: 2),
    chiusa(CivilDate(2026, 8, 30), 1000),
    chiusa(CivilDate(2026, 9, 1), 3000, negozio: 3, budget: 3000), // al 100%: non sforata
    chiusa(CivilDate(2026, 9, 7), 3001, negozio: 3, budget: 3000), // sforata di 1 centesimo
    chiusa(CivilDate(2026, 9, 14), 1500, negozio: 2),
    chiusa(CivilDate(2026, 9, 21), 2500, negozio: 1),
    chiusa(CivilDate(2026, 9, 30), 999, negozio: 2),
    chiusa(CivilDate(2026, 10, 3), 5000, negozio: 1, budget: 6000),
    chiusa(CivilDate(2026, 10, 5), 1234, negozio: 2),
    chiusa(CivilDate(2026, 10, 10), 4321, negozio: 1, fonte: FonteRighe.scontrino),
  ];

  test('mese: totale, spese, media, sforamenti su quelle con budget', () {
    final ago = StatisticheSpesa.mese(spese, 2026, 8);
    expect(ago.spese, 4);
    expect(ago.totale, e(13000));
    expect(ago.media, e(3250));
    expect(ago.sforamenti, 1);
    expect(ago.conBudget, 2);
    final set = StatisticheSpesa.mese(spese, 2026, 9);
    expect(set.spese, 5);
    expect(set.totale, e(11000));
    expect(set.sforamenti, 1);
    expect(set.conBudget, 2);
  });

  test('il totale e\' quello salvato alla chiusura, anche con fonte scontrino', () {
    expect(StatisticheSpesa.mese(spese, 2026, 10).totale, e(5000 + 1234 + 4321));
  });

  test('mese vuoto: 0 spese e media null (nessun dato non e\' zero)', () {
    final m = StatisticheSpesa.mese(spese, 2026, 7);
    expect(m.spese, 0);
    expect(m.media, isNull);
    expect(m.totale, Money.zero);
  });

  test('ultimi 6 mesi fino a oggi, anche vuoti, dal piu\' vecchio', () {
    final mesi = StatisticheSpesa.ultimiMesi(spese, CivilDate(2026, 10, 12));
    expect([for (final m in mesi) m.mese], [5, 6, 7, 8, 9, 10]);
    expect([for (final m in mesi) m.spese], [0, 0, 0, 4, 5, 3]);
  });

  test('ultimi mesi a cavallo dell\'anno', () {
    final mesi = StatisticheSpesa.ultimiMesi(const [], CivilDate(2027, 2, 1), n: 4);
    expect([for (final m in mesi) (m.anno, m.mese)], [(2026, 11), (2026, 12), (2027, 1), (2027, 2)]);
  });

  test('per negozio: totale decrescente, «Senza negozio» in fondo, media intera', () {
    final voci = StatisticheSpesa.perNegozio(
      spese,
      {1: 'Esempio Market', 2: 'Bottega', 3: 'Discount'},
      CivilDate(2026, 8, 1),
      CivilDate(2026, 10, 31),
      senzaNegozio: 'Senza negozio',
    );
    expect([for (final v in voci) v.nome], ['Esempio Market', 'Discount', 'Bottega', 'Senza negozio']);
    expect(voci[0].spese, 5);
    expect(voci[0].totale, e(4000 + 6000 + 2500 + 5000 + 4321));
    expect(voci[2].media, e((2000 + 1500 + 999 + 1234) ~/ 4));
    expect(voci.last.negozioId, isNull);
  });

  test('un negozio eliminato (non piu\' nei nomi) finisce in «Senza negozio»', () {
    final voci = StatisticheSpesa.perNegozio(spese, {1: 'Esempio Market'}, CivilDate(2026, 8, 1), CivilDate(2026, 8, 31));
    expect(voci.last.negozioId, isNull);
    expect(voci.last.spese, 2);
  });

  test('riepilogo: media del periodo e sforamenti; senza spese media null', () {
    final r = StatisticheSpesa.riepilogo(spese, CivilDate(2026, 8, 1), CivilDate(2026, 9, 30));
    expect(r.media, e(24000 ~/ 9));
    expect(r.sforamenti, 2);
    expect(r.conBudget, 4);
    expect(StatisticheSpesa.riepilogo(spese, CivilDate(2025, 1, 1), CivilDate(2025, 12, 31)).media, isNull);
  });

  test('le spese in corso non contano', () {
    final inCorso = Spesa(stato: StatoSpesa.inCorso, iniziataIl: DateTime(2026, 10, 11), righe: const []);
    expect(StatisticheSpesa.mese([...spese, inCorso], 2026, 10).spese, 3);
  });

  group('budget del mese (risposta D3, Pro)', () {
    test('speso nel mese contro il tetto, con le stesse soglie della spesa', () {
      final b = StatisticheSpesa.budgetMese(spese, e(12000), 2026, 10);
      expect(b.speso, e(10555));
      expect(b.residuo, e(1445));
      expect(b.livello, LivelloBudget.vicino);
      expect(StatisticheSpesa.budgetMese(spese, e(10000), 2026, 10).livello, LivelloBudget.sforato);
      expect(StatisticheSpesa.budgetMese(spese, e(50000), 2026, 10).livello, LivelloBudget.ok);
    });

    test('la spesa in corso del mese si somma (il tetto serve mentre si spende)', () {
      final inCorso = Spesa(
        stato: StatoSpesa.inCorso,
        iniziataIl: DateTime(2026, 10, 12, 18),
        righe: [RigaSpesa(nome: '', quantita: const Pezzi(1), prezzoUnitario: e(445), origine: OrigineRiga.tastierino)],
      );
      expect(StatisticheSpesa.budgetMese(spese, e(12000), 2026, 10, inCorso: inCorso).speso, e(11000));
      expect(StatisticheSpesa.budgetMese(spese, e(12000), 2026, 9, inCorso: inCorso).speso, e(11000));
    });
  });
}

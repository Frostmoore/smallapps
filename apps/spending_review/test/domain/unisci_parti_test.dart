import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/riga_ocr.dart';
import 'package:spending_review/domain/lettura/scontrino_parser.dart';
import 'package:spending_review/domain/lettura/unisci_parti.dart';

import 'righe_finte.dart';

/// F12.1.6: la fusione di piu' foto dello stesso scontrino.
void main() {
  List<RigaOcr> parte(List<(String, String)> righe) => [
    for (var i = 0; i < righe.length; i++) ...rigaScontrino(i * 2, righe[i].$1, righe[i].$2),
  ];

  test('giunzione trovata: le 3 righe sovrapposte non si contano due volte', () {
    final a = parte([('PANE', '1,20'), ('LATTE', '1,50'), ('UOVA', '2,10'), ('BURRO', '2,49'), ('MIELE', '4,90')]);
    final b = parte([('UOVA', '2,10'), ('BURRO', '2,49'), ('MIELE', '4,90'), ('CAFFE', '3,99'), ('TOTALE COMPLESSIVO', '16,18')]);
    final u = UnisciParti.unisci([a, b]);
    expect(u.giunzioniTrovate, [true]);
    final l = const ScontrinoParser().interpreta(u.righe, oggi: DateTime(2026, 10, 12));
    expect(l.articoli, 6);
    expect(l.totale, Money.cents(1618));
    expect(l.quadra, isTrue);
  });

  test('le coordinate si impilano: la parte i occupa [i, i+1] in verticale', () {
    final u = UnisciParti.unisci([parte([('PANE', '1,20')]), parte([('LATTE', '1,50')])]);
    expect(u.righe.where((r) => r.testo == 'LATTE').single.riquadro.alto, greaterThan(1));
    expect(u.righe.where((r) => r.testo == 'PANE').single.riquadro.alto, lessThan(1));
  });

  test('giunzione non trovata: tutto concatenato e segnalato', () {
    final u = UnisciParti.unisci([
      parte([('PANE', '1,20'), ('LATTE', '1,50')]),
      parte([('CAFFE', '3,99'), ('MIELE', '4,90')]),
    ]);
    expect(u.giunzioniTrovate, [false]);
    expect(u.righe.where((r) => r.testo.contains(',')).length, 4);
  });

  test('una riga sola in comune non basta (k ≥ 2)', () {
    final u = UnisciParti.unisci([
      parte([('PANE', '1,20'), ('LATTE', '1,50')]),
      parte([('LATTE', '1,50'), ('MIELE', '4,90')]),
    ]);
    expect(u.giunzioniTrovate, [false]);
  });

  test('parte singola: nessuna giunzione', () {
    final u = UnisciParti.unisci([parte([('PANE', '1,20')])]);
    expect(u.giunzioniTrovate, isEmpty);
    expect(u.righe, hasLength(2));
  });
}

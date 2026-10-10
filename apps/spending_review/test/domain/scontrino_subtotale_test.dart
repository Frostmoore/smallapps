import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/domain/lettura/scontrino_parser.dart';

import 'righe_finte.dart';

/// ☠ Visto sull'emulatore in F12.4 (s06 letto dal motore vero): «T*talE PARZIALE», con un
/// asterisco al posto della «o», finiva fra gli articoli e lo scontrino non quadrava piu'.
void main() {
  test('un «totale parziale» con un carattere letto male non e\' un articolo', () {
    final righe = [
      ...rigaScontrino(0, 'DOCUMENTO COMMERCIALE'),
      ...rigaScontrino(1, 'CORNETTI GR.270', '2,19'),
      ...rigaScontrino(2, 'NUTELLA GR200', '2,19'),
      ...rigaScontrino(3, 'T*talE PARZIALE', '4,38'),
      ...rigaScontrino(4, 'TOTALE EURO', '4,38'),
    ];
    final l = const ScontrinoParser().interpreta(righe, oggi: DateTime(2026, 10, 11));
    expect(l.righe.map((r) => r.descrizione), isNot(contains(contains('PARZIALE'))));
    expect(l.totale, const Money.cents(438));
    expect(l.quadra, isTrue);
  });
}

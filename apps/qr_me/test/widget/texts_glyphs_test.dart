import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F17.7: nei testi niente segni di spunta o di avviso (✓ ✔ ✗ ✘ ⚠ ❌ ✅).
///
/// ⚑ Il segno lo mette l'interfaccia, con un'icona colorata (la riga di verifica della pagina
/// Stile, le snackbar di `MicroSnack`). Un ✓ anche nel testo raddoppia il segno («icona ✓
/// Leggibile»), e su alcuni telefoni il glifo arriva da un altro font, piu' grande o a colori.
/// I testi nascono in `tool/testi_*.py`: se questo test fallisce, si corregge li' e si
/// rigenerano ARB e `gen-l10n` (README dell'app).
void main() {
  final glifi = RegExp('[✓✔✗✘⚠❌✅]');

  for (final lingua in ['it', 'en']) {
    test('app_$lingua.arb senza segni di spunta o di avviso', () {
      final arb = jsonDecode(File('lib/l10n/app_$lingua.arb').readAsStringSync()) as Map<String, Object?>;
      final colpevoli = [
        for (final MapEntry(:key, :value) in arb.entries)
          if (!key.startsWith('@') && value is String && glifi.hasMatch(value)) '$key: $value',
      ];
      expect(colpevoli, isEmpty);
    });
  }
}

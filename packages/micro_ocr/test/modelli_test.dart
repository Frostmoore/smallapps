import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// ☠ Gli SHA-256 dei modelli devono essere quelli scritti in MODELLI.md (F12.1.9,
/// F12.1.16 trappola 4): un modello o un dizionario cambiato per sbaglio produce testo
/// plausibile ma sbagliato, e qui deve fallire un test, non una lettura in silenzio.
void main() {
  const cartella = 'android/src/main/assets/ppocrv5';

  Map<String, String> attesi() {
    final md = File('$cartella/MODELLI.md').readAsStringSync();
    final riga = RegExp(r'^\| `([^`]+)` \|.*\| `([0-9a-f]{64})` \|$', multiLine: true);
    return {for (final m in riga.allMatches(md)) m.group(1)!: m.group(2)!};
  }

  test('MODELLI.md elenca i tre file', () {
    expect(attesi().keys.toSet(), {'det.onnx', 'rec_latin.onnx', 'latin_dict.txt'});
  });

  for (final nome in ['det.onnx', 'rec_latin.onnx', 'latin_dict.txt']) {
    test('SHA-256 di $nome uguale a MODELLI.md', () {
      final file = File('$cartella/$nome');
      // Un clone senza i binari (o con file puntatore di LFS) deve fallire qui.
      expect(file.existsSync(), isTrue, reason: '$nome mancante');
      expect(sha256.convert(file.readAsBytesSync()).toString(), attesi()[nome]);
    });
  }

  test('dizionario: 502 simboli, euro compreso, nessuna riga vuota', () {
    final righe = File('$cartella/latin_dict.txt').readAsStringSync().split('\n');
    expect(righe.removeLast(), '', reason: 'il file finisce con un a capo');
    expect(righe, hasLength(502));
    expect(righe, contains('€'));
    expect(righe.where((r) => r.isEmpty), isEmpty);
  });
}

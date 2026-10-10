import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spending_review/app/routes.dart';
import 'package:spending_review/features/dev/ocr_dev_page.dart';

import 'sr_test_harness.dart';

/// ☠ La pagina di sviluppo dell'OCR esporta le righe lette: in release non deve esistere
/// (develop_microapps.md F12.1.11, F12.1.17 `dev_route_test.dart`).
void main() {
  setUp(zittisciPiattaforma);

  test('rottaDevAttiva: solo con debug o SR_DEV', () {
    expect(rottaDevAttiva(debug: false, srDev: false), isFalse);
    expect(rottaDevAttiva(debug: true, srDev: false), isTrue);
    expect(rottaDevAttiva(debug: false, srDev: true), isTrue);
  });

  testWidgets('con debug e SR_DEV falsi /dev/ocr non esiste: «Non trovato»', (tester) async {
    await pumpSr(tester, initialLocation: '/dev/ocr', devAttiva: false);
    expect(find.byType(OcrDevPage), findsNothing);
    expect(find.text('Questa spesa non esiste più.'), findsOneWidget);
  });

  testWidgets('e nessuna voce di sviluppo in Impostazioni', (tester) async {
    await pumpSr(tester, initialLocation: '/impostazioni', devAttiva: false);
    await tester.scrollUntilVisible(find.text('Licenze'), 200);
    expect(find.byKey(const ValueKey('impostazioni_dev')), findsNothing);
  });

  testWidgets('con la rotta attiva la pagina si apre', (tester) async {
    await pumpSr(tester, initialLocation: '/dev/ocr', devAttiva: true);
    expect(find.byType(OcrDevPage), findsOneWidget);
  });
}

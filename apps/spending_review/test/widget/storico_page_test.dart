import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/app/providers.dart';
import 'package:spending_review/data/database.dart';

import 'sr_test_harness.dart';

/// Lo storico (develop_microapps.md F12.1.12, F12.1.17 `storico_page_test.dart`): 7 spese chiuse,
/// gratis → 5 visibili + la card «Le altre 2…»; Pro → 7. Le nascoste non si aprono senza il Pro
/// nemmeno da un link diretto (risposta D1: sono sul telefono, non cancellate).
void main() {
  setUp(zittisciPiattaforma);

  final sette = [
    for (var i = 1; i <= 7; i++)
      spesaChiusa(i, CivilDate(2026, 10, i), Money.cents(1000 * i), negozioId: i == 7 ? 1 : null, budget: i == 7 ? const Money.cents(5000) : null),
  ];
  final negozi = [const Negozio(id: 1, nome: 'Esselunga', creatoIl: 0)];

  testWidgets('gratis: le ultime 5, la card delle altre 2, e la riga col pallino di sforamento', (tester) async {
    final h = await pumpSr(tester, initialLocation: '/storico', chiuse: sette, negozi: negozi);
    for (var i = 3; i <= 7; i++) {
      expect(find.byKey(ValueKey('storico_spesa_$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('storico_spesa_2')), findsNothing);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('storico_nascoste')), 200);
    expect(find.textContaining('Le altre 2 spese sono sul telefono'), findsOneWidget);
    expect(find.text('Esselunga'), findsOneWidget);
    expect(find.byKey(const ValueKey('storico_pallino_7')), findsOneWidget);
    // ☠ Nascoste ma non cancellate.
    expect(h.repo.chiuse, hasLength(7));
    expect(h.container.read(speseChiuseProvider).value, hasLength(5));
  });

  testWidgets('la card delle nascoste apre il paywall', (tester) async {
    await pumpSr(tester, initialLocation: '/storico', chiuse: sette);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('storico_nascoste')), 200);
    await tester.tap(find.byKey(const ValueKey('storico_nascoste')));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);
  });

  testWidgets('Pro: tutte e 7, nessuna card', (tester) async {
    await pumpSr(tester, initialLocation: '/storico', chiuse: sette, pro: true);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('storico_spesa_1')), 200);
    expect(find.byKey(const ValueKey('storico_spesa_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('storico_nascoste')), findsNothing);
  });

  testWidgets('☠ gratis, link diretto a una spesa nascosta: lucchetto, non la pagina', (tester) async {
    await pumpSr(tester, initialLocation: '/storico/1', chiuse: sette);
    expect(find.byKey(const ValueKey('dettaglio_nascosta')), findsOneWidget);
    expect(find.byKey(const ValueKey('dettaglio_totale')), findsNothing);
  });

  testWidgets('gratis, una spesa visibile si apre col suo totale', (tester) async {
    await pumpSr(tester, initialLocation: '/storico/7', chiuse: sette, negozi: negozi);
    expect(tester.widget<Text>(find.byKey(const ValueKey('dettaglio_totale'))).data, '70,00');
  });

  testWidgets('un id non numerico porta a «Non trovato»', (tester) async {
    await pumpSr(tester, initialLocation: '/storico/abc', chiuse: sette);
    expect(find.text('Questa spesa non esiste più.'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/features/scontrino/scontrino_camera_page.dart';
import 'package:spending_review/features/statistiche/statistiche_page.dart';

import 'sr_test_harness.dart';

/// Il Pro controllato **sulla pagina** (develop_microapps.md F12.0 punto 11, F12.1.11, F12.5):
/// Scontrino e Statistiche aperti con un push diretto, senza Pro, mostrano il lucchetto; col Pro
/// la pagina. Le voci Pro dello storico e delle impostazioni hanno il badge e aprono il paywall.
void main() {
  setUp(zittisciPiattaforma);

  for (final (rotta, pagina) in [('/scontrino', ScontrinoCameraPage), ('/statistiche', StatistichePage)]) {
    testWidgets('$rotta senza Pro: lucchetto, e il bottone apre il paywall', (tester) async {
      await pumpSr(tester, initialLocation: rotta);
      expect(find.byType(pagina), findsNothing);
      expect(find.text('Questa funzione fa parte di Spending Review Pro.'), findsOneWidget);
      await tester.tap(find.text('Sblocca Pro'));
      await tester.pumpAndSettle();
      expect(find.byType(PaywallPage), findsOneWidget);
    });

    testWidgets('$rotta col Pro: la pagina', (tester) async {
      await pumpSr(tester, initialLocation: rotta, pro: true);
      expect(find.byType(pagina), findsOneWidget);
    });
  }

  testWidgets('storico senza Pro: Statistiche col badge apre il paywall', (tester) async {
    await pumpSr(tester, initialLocation: '/storico');
    expect(
      find.descendant(of: find.byKey(const ValueKey('storico_statistiche')), matching: find.byType(ProBadge)),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('storico_statistiche')));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);
  });

  testWidgets("impostazioni senza Pro: backup e CSV col badge, ripristino senza (e' gratis)", (tester) async {
    await pumpSr(tester, initialLocation: '/impostazioni');
    await tester.scrollUntilVisible(find.byKey(const ValueKey('dati_csv')), 200);
    for (final (chiave, badge) in [('dati_backup', true), ('dati_ripristino', false), ('dati_csv', true)]) {
      expect(
        find.descendant(of: find.byKey(ValueKey(chiave)), matching: find.byType(ProBadge)),
        badge ? findsOneWidget : findsNothing,
        reason: chiave,
      );
    }
    await tester.ensureVisible(find.byKey(const ValueKey('dati_csv')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dati_csv')));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);
  });

  testWidgets('statistiche col Pro: il budget del mese (D3) si imposta e mostra «speso su tetto»', (tester) async {
    await pumpSr(
      tester,
      initialLocation: '/statistiche',
      pro: true,
      chiuse: [spesaChiusa(1, CivilDate(2026, 10, 2), const Money.cents(18240))],
    );
    expect(find.text('Imposta un tetto per tutto il mese.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('statistiche_tetto')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('budget_40000')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('budget_salva')));
    await tester.pumpAndSettle();
    expect(find.text('182,40 € su 400 €'), findsOneWidget);
  });
}

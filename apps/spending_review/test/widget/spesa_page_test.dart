import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/app/sr_palette.dart';
import 'package:spending_review/domain/spesa.dart';
import 'package:spending_review/features/spesa/spesa_page.dart';

import 'sr_test_harness.dart';

/// LA schermata (develop_microapps.md F12.1.12, F12.1.17 `spesa_page_test.dart`).
void main() {
  setUp(zittisciPiattaforma);

  Future<void> batti(WidgetTester tester, List<String> tasti) async {
    for (final t in tasti) {
      await tester.tap(find.byKey(ValueKey('tasto_$t')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  String totale(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('spesa_totale'))).data!;

  Spesa conBudget(int budgetCents, List<int> righe) => Spesa(
    id: 1,
    stato: StatoSpesa.inCorso,
    iniziataIl: kOra.toUtc(),
    budget: Money.cents(budgetCents),
    righe: [for (final (i, c) in righe.indexed) rigaTastierino(c, id: 10 + i)],
  );

  testWidgets('«alla cassa»: 2 4 9 + aggiunge 2,49; il display mostra il valore prima del +', (tester) async {
    final h = await pumpSr(tester, page: const SpesaPage());
    expect(find.byKey(const ValueKey('spesa_vuota')), findsOneWidget);
    await batti(tester, ['c2', 'c4', 'c9']);
    expect(tester.widget<Text>(find.byKey(const ValueKey('display_tastierino'))).data, '2,49');
    await batti(tester, ['piu']);
    expect(totale(tester), '2,49');
    expect(h.repo.inCorso!.righe.single.prezzoUnitario, Money.cents(249));
    expect(h.aptica.fatte.last, 'aggiunto');
  });

  testWidgets('quantita\' con ×: 3 × 1 5 0 + fa 4,50 e la riga dice «3 × 1,50»', (tester) async {
    await pumpSr(tester, page: const SpesaPage());
    await batti(tester, ['c3', 'per', 'c1', 'c5', 'c0', 'piu']);
    expect(totale(tester), '4,50');
    expect(find.text('3 × 1,50'), findsOneWidget);
  });

  testWidgets('− 1 5 0 + e\' uno sconto: il totale scende, la riga si chiama «Sconto»', (tester) async {
    await pumpSr(tester, page: const SpesaPage(), inCorso: conBudget(10000, [500]));
    await batti(tester, ['meno', 'c1', 'c5', 'c0', 'piu']);
    expect(totale(tester), '3,50');
    expect(find.text('Sconto'), findsOneWidget);
  });

  testWidgets('un tasto rifiutato vibra d\'errore (una terza cifra dopo la virgola)', (tester) async {
    final h = await pumpSr(tester, page: const SpesaPage());
    await batti(tester, ['c1', 'virgola', 'c2', 'c3', 'c4']);
    expect(h.aptica.fatte.last, 'rifiuto');
  });

  testWidgets('budget: residuo «−16,30» verde sotto l\'80%, la barra c\'e\'', (tester) async {
    await pumpSr(tester, page: const SpesaPage(), inCorso: conBudget(6000, [4370]));
    expect(totale(tester), '43,70');
    expect(tester.widget<Text>(find.byKey(const ValueKey('spesa_residuo'))).data, '−16,30');
    expect(find.text('1 articolo · budget 60 €'), findsOneWidget);
    final barra = tester.widget<ColoredBox>(find.byKey(const ValueKey('barra_riempimento')));
    expect(barra.color, SrPalette.scuro.accento);
  });

  for (final (nome, righe, colore) in [
    ('80% esatto: ambra', [8000], SrPalette.scuro.ambraValore),
    ('100% esatto: ancora ambra', [10000], SrPalette.scuro.ambraValore),
    ('100,01%: rosso', [10001], SrPalette.scuro.rosso),
    ('79,99%: verde', [7999], SrPalette.scuro.accento),
  ]) {
    testWidgets('colore della barra alle soglie, $nome', (tester) async {
      await pumpSr(tester, page: const SpesaPage(), inCorso: conBudget(10000, righe));
      expect(tester.widget<ColoredBox>(find.byKey(const ValueKey('barra_riempimento'))).color, colore);
    });
  }

  testWidgets('passata la soglia dell\'80% vibra una volta sola', (tester) async {
    final h = await pumpSr(tester, page: const SpesaPage(), inCorso: conBudget(1000, [700]));
    await batti(tester, ['c1', 'c0', 'c0', 'piu']); // 8,00 su 10: vicino
    await batti(tester, ['c1', 'piu']); // 8,01: ancora vicino
    expect(h.aptica.fatte.where((v) => v == 'soglia'), hasLength(1));
  });

  testWidgets('scorrere a sinistra elimina, «Annulla» rimette la riga al suo posto', (tester) async {
    final h = await pumpSr(tester, page: const SpesaPage(), inCorso: conBudget(10000, [100, 200]));
    await tester.drag(find.byKey(const ValueKey('riga_11')), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(totale(tester), '1,00');
    expect(find.text('Eliminato'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(totale(tester), '3,00');
    expect(h.repo.inCorso!.righe.map((r) => r.id), [10, 11]);
  });

  testWidgets('Scontrino senza Pro: badge PRO, e il tocco apre il paywall (non la fotocamera)', (tester) async {
    await pumpSr(tester, initialLocation: '/');
    expect(find.descendant(of: find.byKey(const ValueKey('spesa_scontrino')), matching: find.byType(ProBadge)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('spesa_scontrino')));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);
  });

  testWidgets('Scontrino col Pro: nessun badge, si apre il mirino dello scontrino', (tester) async {
    await pumpSr(tester, initialLocation: '/', pro: true);
    expect(find.descendant(of: find.byKey(const ValueKey('spesa_scontrino')), matching: find.byType(ProBadge)), findsNothing);
    await tester.tap(find.byKey(const ValueKey('spesa_scontrino')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scontrino_scatta')), findsOneWidget);
  });

  testWidgets('spesa aperta da piu\' di 12 ore: il banner «iniziata ieri» con Chiudila e Continua', (tester) async {
    final ieri = Spesa(
      id: 1,
      stato: StatoSpesa.inCorso,
      iniziataIl: DateTime(2026, 10, 10, 18, 32).toUtc(),
      righe: [rigaTastierino(100, id: 10)],
    );
    await pumpSr(tester, page: const SpesaPage(), inCorso: ieri);
    expect(find.text('Spesa iniziata ieri alle 18:32'), findsOneWidget);
    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spesa_banner')), findsNothing);
  });

  group('al 130% con i font veri, nessun tasto tagliato', () {
    setUpAll(caricaFontVeri);

    for (final (l, a) in [(412.0, 915.0), (390.0, 844.0)]) {
      testWidgets('${l.toInt()}×${a.toInt()}', (tester) async {
        telefono(tester, larghezza: l, altezza: a, scala: 1.3);
        await pumpSr(tester, page: const SpesaPage(), inCorso: conBudget(6000, [100, 200, 300, 400, 500, 600]));
        expect(tester.takeException(), isNull);
        final schermo = tester.getRect(find.byType(SpesaPage));
        for (final t in ['c7', 'cancella', 'c0', 'piu', 'meno', 'per']) {
          final r = tester.getRect(find.byKey(ValueKey('tasto_$t')));
          expect(r.height, 48, reason: 'tasto $t');
          expect(schermo.contains(r.bottomRight - const Offset(1, 1)), isTrue, reason: 'tasto $t fuori schermo');
        }
        // La lista resta visibile (almeno due righe) e i due tasti grandi ci sono.
        expect(find.byKey(const ValueKey('spesa_cartellino')), findsOneWidget);
        expect(tester.getRect(find.byKey(const ValueKey('spesa_lista'))).height, greaterThan(2 * 48));
      });
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scorte_calore/data/database.dart';
import 'package:scorte_calore/features/purchases/purchase_editor_sheet.dart';
import 'package:scorte_calore/features/purchases/purchases_page.dart';

import 'fake_repo.dart';

/// F5.11: la pagina degli acquisti (spesa della stagione, prezzo medio, inverni precedenti),
/// l'aggiunta dal foglio e l'eliminazione con "Annulla".
void main() {
  Purchase acquisto(int id, String iso, double q, [int? cents, String? supplier]) =>
      Purchase(id: id, fuelSourceId: 1, date: iso, quantity: q, totalCostCents: cents, supplier: supplier);

  // Oggi 2026-10-08: l'inverno in corso e' il 2026/27.
  final acquisti = [
    acquisto(1, '2025-11-10', 50, 25000, 'Agraria Rossi'),
    acquisto(2, '2026-10-02', 70, 36400, 'Agraria Rossi'),
    acquisto(3, '2026-10-03', 20),
  ];

  group('parseEuroCents', () {
    test('virgola o punto, arrotondato al centesimo', () {
      expect(parseEuroCents('420'), 42000);
      expect(parseEuroCents('52,5'), 5250);
      expect(parseEuroCents('5.195'), 520);
      expect(parseEuroCents('0'), 0);
    });

    test('vuoto, testo o negativo: null', () {
      expect(parseEuroCents(''), isNull);
      expect(parseEuroCents('dieci'), isNull);
      expect(parseEuroCents('-3'), isNull);
    });
  });

  test('formatEuro scrive i centesimi come la lingua', () {
    expect(formatEuro(36400, 'it', decimals: 0), contains('364'));
    expect(formatEuro(36400, 'it', decimals: 0), contains('€'));
    expect(formatEuro(5250, 'it'), contains('52,50'));
    expect(formatEuro(5250, 'en'), contains('52.50'));
  });

  testWidgets('testata: spesa dell\'inverno, prezzo medio, inverni precedenti', (tester) async {
    await pumpPage(tester, const PurchasesPage(sourceId: 1), pro: true, acquisti: acquisti);

    expect(find.text('SPESA INVERNO 2026/27'), findsOneWidget);
    expect(find.textContaining('364'), findsWidgets);
    // (25000 + 36400) / 120 sacchi con un costo = 511,67 centesimi.
    expect(find.textContaining('5,12'), findsOneWidget);
    expect(find.text('90 sacchi'), findsOneWidget);
    expect(find.text('1 acquisto senza costo non è conteggiato.'), findsOneWidget);
    expect(find.text('Inverno 2025/26'), findsOneWidget);
    expect(find.text('senza costo'), findsOneWidget);
  });

  testWidgets('aggiungere un acquisto dal foglio, con il fornitore dell\'ultima volta', (tester) async {
    final repo = await pumpPage(tester, const PurchasesPage(sourceId: 1), pro: true, acquisti: acquisti);

    await tester.tap(find.text('Aggiungi acquisto'));
    await tester.pumpAndSettle();
    expect(find.text('Agraria Rossi'), findsWidgets);
    await tester.enterText(find.byKey(const ValueKey('purchase_quantity')), '10');
    await tester.enterText(find.byKey(const ValueKey('purchase_cost')), '52,5');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    final nuovo = repo.acquisti.singleWhere((p) => p.id >= 1000);
    expect(nuovo.date, '2026-10-08');
    expect(nuovo.quantity, 10);
    expect(nuovo.totalCostCents, 5250);
    expect(nuovo.supplier, 'Agraria Rossi');
  });

  testWidgets('un costo non valido blocca il salvataggio', (tester) async {
    final repo = await pumpPage(tester, const PurchasesPage(sourceId: 1), pro: true, acquisti: acquisti);
    await tester.tap(find.text('Aggiungi acquisto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('purchase_quantity')), '10');
    await tester.enterText(find.byKey(const ValueKey('purchase_cost')), 'tanto');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(repo.acquisti, hasLength(3));
  });

  testWidgets('eliminare un acquisto dal foglio e annullare', (tester) async {
    final repo = await pumpPage(tester, const PurchasesPage(sourceId: 1), pro: true, acquisti: acquisti);

    await tester.tap(find.text('70 sacchi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(repo.acquisti.map((p) => p.id), isNot(contains(2)));
    expect(find.text('70 sacchi'), findsNothing);

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    final rimesso = repo.acquisti.singleWhere((p) => p.date == '2026-10-02');
    expect(rimesso.totalCostCents, 36400);
    expect(rimesso.supplier, 'Agraria Rossi');
    expect(find.text('70 sacchi'), findsOneWidget);
  });
}

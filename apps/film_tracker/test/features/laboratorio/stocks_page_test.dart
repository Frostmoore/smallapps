import 'package:film_tracker/features/stocks/stocks_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_film_repo.dart';

/// F6.4: il catalogo con ricerca e gruppi per marca, e le pellicole personalizzate.
void main() {
  Future<void> compila(WidgetTester tester, {required String brand, required String name, required String iso}) async {
    await tester.tap(find.byKey(const ValueKey('stock_add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('stock_brand')), brand);
    await tester.enterText(find.byKey(const ValueKey('stock_name')), name);
    await tester.enterText(find.byKey(const ValueKey('stock_iso')), iso);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salva'));
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
  }

  testWidgets('raggruppato per marca, con ISO e processo; la ricerca filtra', (tester) async {
    await pumpFilm(tester, page: const StocksPage(), pro: false, stocks: [hp5, portra400]);
    expect(find.text('ILFORD'), findsOneWidget);
    expect(find.text('KODAK'), findsOneWidget);
    expect(find.text('ISO 400 · Bianco e nero · 35 mm'), findsOneWidget);
    expect(find.text('ISO 400 · C-41 · 35 mm'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), 'portra');
    await tester.pumpAndSettle();
    expect(find.text('Portra 400'), findsOneWidget);
    expect(find.text('HP5+'), findsNothing);
  });

  testWidgets('solo le personalizzate hanno il menu di modifica', (tester) async {
    await pumpFilm(tester, page: const StocksPage(), pro: false, stocks: [portra400, miaPellicola]);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    expect(find.text('Tua'), findsOneWidget);
  });

  testWidgets('una pellicola personalizzata nuova', (tester) async {
    final repo = await pumpFilm(tester, page: const StocksPage(), pro: false, stocks: [portra400]);
    await compila(tester, brand: 'Kodak', name: 'Vision3 250D', iso: '250');
    final nuova = repo.stocks.singleWhere((s) => s.isCustom);
    expect(nuova.name, 'Vision3 250D');
    expect(nuova.iso, 250);
  });

  testWidgets('il doppione da\' un errore leggibile e non crea niente', (tester) async {
    final repo = await pumpFilm(tester, page: const StocksPage(), pro: false, stocks: [portra400]);
    // Maiuscole diverse: per il repository e' la stessa pellicola.
    await compila(tester, brand: 'kodak', name: 'portra 400', iso: '400');

    expect(find.text('“Kodak Portra 400” in 35 mm è già nell’elenco.'), findsOneWidget);
    expect(find.text('Usa quella'), findsOneWidget);
    expect(repo.stocks, hasLength(1));

    // Cambiare il nome toglie l'errore.
    await tester.enterText(find.byKey(const ValueKey('stock_name')), 'Portra 400 NC');
    await tester.pumpAndSettle();
    expect(find.textContaining('è già nell’elenco'), findsNothing);
  });
}

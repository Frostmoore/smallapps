import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:scorte_calore/app/feature_limits.dart';
import 'package:scorte_calore/domain/fuel_source.dart';
import 'package:scorte_calore/features/history/charts.dart';
import 'package:scorte_calore/features/history/history_page.dart';

import 'fake_repo.dart';

/// F5.9: lo storico, il limite dei 90 giorni del gratuito, i grafici solo col Pro,
/// l'eliminazione con "Annulla". Piu' le due funzioni pure dei grafici.
void main() {
  CivilDate d(String iso) => CivilDate.parse(iso);

  // Oggi 2026-10-08: il gratuito vede dal 2026-07-11 compreso.
  final misure = [
    misura(1, '2026-03-01', 100),
    misura(2, '2026-03-20', 60),
    misura(3, '2026-09-20', 120), // rifornimento
    misura(4, '2026-09-30', 110),
    misura(5, '2026-10-05', 104),
  ];

  group('funzioni dei grafici', () {
    test('refillDates: solo le date in cui la scorta sale', () {
      final m = [
        Measurement.absolute(date: d('2026-01-01'), quantity: 50),
        Measurement.absolute(date: d('2026-01-05'), quantity: 40),
        Measurement.absolute(date: d('2026-01-06'), quantity: 90),
        Measurement.absolute(date: d('2026-01-10'), quantity: 90),
        Measurement.absolute(date: d('2026-01-12'), quantity: 91),
      ];
      expect(refillDates(m), [d('2026-01-06'), d('2026-01-12')]);
      expect(refillDates(const []), isEmpty);
    });

    test('niceCeiling: il primo valore tondo >= v, mai zero', () {
      expect(niceCeiling(0), 1);
      expect(niceCeiling(-3), 1);
      expect(niceCeiling(0.8), 1);
      expect(niceCeiling(1.3), 2);
      expect(niceCeiling(2.2), 2.5);
      expect(niceCeiling(5), 5);
      expect(niceCeiling(120), 200);
      expect(niceCeiling(344), 500);
      expect(niceCeiling(1000), 1000);
    });

    test('historyStart: 90 giorni oggi compreso nel gratuito, niente limite col Pro', () {
      final today = d('2026-10-08');
      final free = FeatureGate(limits: scorteFeatureLimits, isPro: false);
      expect(historyStart(free, today), d('2026-07-11'));
      expect(today.daysUntil(historyStart(free, today)!), -89);
      expect(historyStart(FeatureGate(limits: scorteFeatureLimits, isPro: true), today), isNull);
    });
  });

  testWidgets('gratuito: ultimi 90 giorni, grafici bloccati, invito con le misure nascoste', (tester) async {
    await pumpPage(tester, const HistoryPage(sourceId: 1), pro: false, misure: misure);

    expect(find.text('Storico · Stufa'), findsOneWidget);
    expect(find.byType(StockChart), findsNothing);
    expect(find.text('Grafici'), findsOneWidget);
    expect(find.byType(ProBadge), findsWidgets);

    // Le tre misure recenti si', le due di marzo no.
    expect(find.text('104 sacchi'), findsOneWidget);
    expect(find.text('110 sacchi'), findsOneWidget);
    expect(find.text('120 sacchi'), findsOneWidget);
    expect(find.text('60 sacchi'), findsNothing);
    expect(find.text('MARZO 2026'), findsNothing);

    // Il delta della prima visibile si calcola con la precedente nascosta (60 -> 120).
    expect(find.text('+60 sacchi · rifornimento'), findsOneWidget);
    expect(find.text('−6 sacchi'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Il piano gratuito mostra gli ultimi 90 giorni'), 200);
    expect(find.textContaining('2 misurazioni più vecchie'), findsOneWidget);
  });

  testWidgets('Pro: grafici e tutto lo storico, raggruppato per mese', (tester) async {
    await pumpPage(tester, const HistoryPage(sourceId: 1), pro: true, misure: misure);

    expect(find.byType(StockChart), findsOneWidget);
    expect(find.byType(RateChart), findsOneWidget);
    expect(find.text('Grafici'), findsNothing);

    await tester.scrollUntilVisible(find.text('MARZO 2026'), 200);
    expect(find.text('60 sacchi'), findsOneWidget);
    expect(find.text('Il piano gratuito mostra gli ultimi 90 giorni'), findsNothing);
  });

  testWidgets('Pro con una misura sola: niente grafici, la spiegazione', (tester) async {
    await pumpPage(tester, const HistoryPage(sourceId: 1), pro: true, misure: [misura(1, '2026-10-01', 50)]);
    expect(find.byType(StockChart), findsNothing);
    expect(find.text('I grafici compaiono dopo due misurazioni.'), findsOneWidget);
  });

  testWidgets('eliminare una misura e annullare', (tester) async {
    final repo = await pumpPage(tester, const HistoryPage(sourceId: 1), pro: false, misure: misure);

    await tester.tap(find.byTooltip('Elimina').first);
    await tester.pumpAndSettle();
    expect(find.text('104 sacchi'), findsNothing);
    expect(repo.misure.map((m) => m.id), isNot(contains(5)));
    expect(find.text('Misurazione eliminata'), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(find.text('104 sacchi'), findsOneWidget);
    final rimessa = repo.misure.singleWhere((m) => m.date == '2026-10-05');
    expect(rimessa.quantity, 104);
    expect(rimessa.enteredAs, EnteredAs.absolute.key);
  });

  testWidgets('eliminare scorrendo', (tester) async {
    final repo = await pumpPage(tester, const HistoryPage(sourceId: 1), pro: false, misure: misure);
    await tester.drag(find.text('110 sacchi'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('110 sacchi'), findsNothing);
    expect(repo.misure.map((m) => m.id), isNot(contains(4)));
  });
}

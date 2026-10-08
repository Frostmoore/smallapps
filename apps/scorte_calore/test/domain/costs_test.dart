import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:scorte_calore/domain/costs.dart';

/// F5.11: costo medio per unita', stagioni (1 ottobre - 31 marzo), spesa stagionale.
void main() {
  CivilDate d(String iso) => CivilDate.parse(iso);
  PurchaseEntry p(String iso, double q, [int? cents]) =>
      PurchaseEntry(date: d(iso), quantity: q, totalCostCents: cents);

  group('HeatingSeason', () {
    test('gli estremi sono compresi: 1 ottobre e 31 marzo', () {
      const s = HeatingSeason(2025);
      expect(s.start, d('2025-10-01'));
      expect(s.end, d('2026-03-31'));
      expect(s.contains(d('2025-10-01')), isTrue);
      expect(s.contains(d('2026-03-31')), isTrue);
      expect(s.contains(d('2025-09-30')), isFalse);
      expect(s.contains(d('2026-04-01')), isFalse);
    });

    test('containing: autunno -> anno corrente, inverno -> anno prima, estate -> null', () {
      expect(HeatingSeason.containing(d('2025-11-15')), const HeatingSeason(2025));
      expect(HeatingSeason.containing(d('2026-01-10')), const HeatingSeason(2025));
      expect(HeatingSeason.containing(d('2026-03-31')), const HeatingSeason(2025));
      expect(HeatingSeason.containing(d('2026-04-01')), isNull);
      expect(HeatingSeason.containing(d('2026-09-30')), isNull);
      expect(HeatingSeason.containing(d('2026-10-01')), const HeatingSeason(2026));
    });

    test('latest: in estate e\' la stagione appena finita, non quella che deve venire', () {
      expect(HeatingSeason.latest(d('2026-07-15')), const HeatingSeason(2025));
      expect(HeatingSeason.latest(d('2026-02-01')), const HeatingSeason(2025));
      expect(HeatingSeason.latest(d('2026-10-08')), const HeatingSeason(2026));
    });

    test('shortLabel con due cifre anche a cavallo del secolo', () {
      expect(const HeatingSeason(2025).shortLabel, '2025/26');
      expect(const HeatingSeason(2099).shortLabel, '2099/00');
      expect(const HeatingSeason(2008).shortLabel, '2008/09');
    });
  });

  group('PurchaseTotals', () {
    test('vuoto: tutto zero e costo medio null (mai una divisione per zero)', () {
      final t = PurchaseTotals.of(const []);
      expect(t, PurchaseTotals.empty);
      expect(t.averageCentsPerUnit, isNull);
      expect(t.isEmpty, isTrue);
    });

    test('costo medio ponderato per la quantita\', non media dei prezzi unitari', () {
      // 100 sacchi a 5 € + 2 sacchi a 8 € = 516 € / 102 sacchi = 5,0588 €.
      final t = PurchaseTotals.of([p('2025-10-01', 100, 50000), p('2025-12-01', 2, 1600)]);
      expect(t.totalCostCents, 51600);
      expect(t.averageCentsPerUnit, closeTo(505.88, 0.01));
    });

    test('gli acquisti senza costo contano nella quantita\' ma non nel costo medio', () {
      final t = PurchaseTotals.of([p('2025-10-01', 70, 35000), p('2025-11-01', 30)]);
      expect(t.count, 2);
      expect(t.quantity, 100);
      expect(t.costedQuantity, 70);
      expect(t.uncostedCount, 1);
      expect(t.averageCentsPerUnit, 500);
    });

    test('solo acquisti senza costo: costo medio null', () {
      expect(PurchaseTotals.of([p('2025-10-01', 3)]).averageCentsPerUnit, isNull);
    });

    test('un costo di zero (regalo dichiarato) entra nella media', () {
      final t = PurchaseTotals.of([p('2025-10-01', 10, 0), p('2025-10-02', 10, 1000)]);
      expect(t.averageCentsPerUnit, 50);
    });
  });

  group('spesa stagionale', () {
    final entries = [
      p('2024-11-10', 50, 25000), // 2024/25
      p('2025-03-31', 10, 6000), // 2024/25, ultimo giorno
      p('2025-08-20', 100, 45000), // estate: nessuna stagione
      p('2025-10-01', 70, 36400), // 2025/26, primo giorno
      p('2026-01-15', 20), // 2025/26, senza costo
    ];

    test('seasonTotals conta solo le date dentro la stagione', () {
      final t = seasonTotals(entries, const HeatingSeason(2025));
      expect(t.count, 2);
      expect(t.totalCostCents, 36400);
      expect(t.quantity, 90);
      expect(t.uncostedCount, 1);
      final prima = seasonTotals(entries, const HeatingSeason(2024));
      expect(prima.totalCostCents, 31000);
      expect(seasonTotals(entries, const HeatingSeason(2026)).isEmpty, isTrue);
    });

    test('totalsBySeason: dalla piu\' recente, senza l\'estate', () {
      final by = totalsBySeason(entries);
      expect(by.map((e) => e.$1).toList(), const [HeatingSeason(2025), HeatingSeason(2024)]);
      expect(by.first.$2.totalCostCents, 36400);
      expect(by.last.$2.totalCostCents, 31000);
      final contati = by.fold<int>(0, (s, e) => s + e.$2.count);
      expect(contati, 4, reason: 'l\'acquisto di agosto non sta in nessuna stagione');
    });
  });
}

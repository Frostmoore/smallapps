import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:scorte_calore/domain/consumption.dart';
import 'package:scorte_calore/domain/fuel_source.dart';
import 'package:scorte_calore/domain/fuel_units.dart';
import 'package:scorte_calore/domain/reorder_plan.dart';

/// F5.8: quando arrivano gli avvisi di riordino e di superamento, e con quali valori.
void main() {
  const calc = ConsumptionCalculator();
  const planner = ReorderPlanner();
  final pellet = FuelSourceSpec.withDefaults(id: 4, name: 'Stufa', fuelType: FuelType.pellet);

  CivilDate ott(int giorno) => CivilDate(2026, 10, giorno);
  Measurement m(int giorno, double q) => Measurement.absolute(date: ott(giorno), quantity: q);

  // 1 al giorno, 20 sacchi l'11 ottobre: esaurimento il 31, riordino il 24.
  final stima = calc.estimate(
    measurements: [m(1, 30), m(6, 25), m(11, 20)],
    source: pellet,
    today: ott(11),
  );

  group('piano delle notifiche', () {
    test('riordino il 24 alle 10:00 e superamento il 27 alle 10:00, con i loro valori', () {
      final p = planner.plan(source: pellet, estimate: stima, now: DateTime(2026, 10, 11, 12));
      expect(p, hasLength(2));

      final riordino = p[0];
      expect(riordino.kind, ReorderNotificationKind.reorder);
      expect(riordino.id, 41);
      expect(riordino.fireAt, DateTime(2026, 10, 24, 10));
      expect(riordino.daysUntilDepletion, 7); // "potrebbe terminare tra circa 7 giorni"
      expect(riordino.projectedQuantity, closeTo(7, 1e-9)); // "ti restano circa 7 sacchi"
      expect(riordino.fuelTypeKey, 'pellet');
      expect(riordino.unitKey, 'bags');
      expect(riordino.sourceName, 'Stufa');
      expect(riordino.reorderDate, ott(24));
      expect(riordino.depletionDate, ott(31));

      final superamento = p[1];
      expect(superamento.kind, ReorderNotificationKind.overdue);
      expect(superamento.id, 42);
      expect(superamento.fireAt, DateTime(2026, 10, 27, 10));
      expect(superamento.daysUntilDepletion, 4);
    });

    test('l ora e locale, non UTC', () {
      final p = planner.plan(source: pellet, estimate: stima, now: DateTime(2026, 10, 11));
      expect(p.every((n) => !n.fireAt.isUtc), isTrue);
    });

    test('stima insufficient: nessuna notifica', () {
      final scarsa = calc.estimate(measurements: [m(1, 20)], source: pellet, today: ott(1));
      expect(planner.plan(source: pellet, estimate: scarsa, now: DateTime(2026, 10, 1)), isEmpty);
    });

    test('un avviso gia passato non si pianifica, quello futuro si', () {
      final p = planner.plan(source: pellet, estimate: stima, now: DateTime(2026, 10, 24, 11));
      expect(p.map((n) => n.kind), [ReorderNotificationKind.overdue]);
    });

    test('alle 10 in punto del giorno di riordino l avviso e gia passato', () {
      final p = planner.plan(source: pellet, estimate: stima, now: DateTime(2026, 10, 24, 10));
      expect(p.map((n) => n.kind), [ReorderNotificationKind.overdue]);
    });

    test('misurato dopo la data di riordino: niente superamento', () {
      // 1 al giorno, 6 sacchi l'11: esaurimento il 17, riordino il 10, superamento il 13.
      final tardi = calc.estimate(
        measurements: [m(1, 16), m(11, 6)],
        source: pellet,
        today: ott(11),
      );
      expect(tardi.reorderDate, ott(10));
      final p = planner.plan(source: pellet, estimate: tardi, now: DateTime(2026, 10, 11, 8));
      expect(p, isEmpty);
    });

    test('l ora e i giorni di superamento si possono cambiare', () {
      const altro = ReorderPlanner(hour: 18, minute: 30, overdueAfterDays: 5);
      final p = altro.plan(source: pellet, estimate: stima, now: DateTime(2026, 10, 11));
      expect(p.map((n) => n.fireAt), [
        DateTime(2026, 10, 24, 18, 30),
        DateTime(2026, 10, 29, 18, 30),
      ]);
    });
  });

  group('id delle notifiche', () {
    test('stabili per fonte: id x 10 + 1 per il riordino, + 2 per il superamento', () {
      expect(ReorderPlanner.notificationId(4, ReorderNotificationKind.reorder), 41);
      expect(ReorderPlanner.notificationId(4, ReorderNotificationKind.overdue), 42);
      expect(ReorderPlanner.idsFor(4), [41, 42]);
    });

    test('fonti diverse non collidono mai', () {
      final ids = <int>{for (var s = 0; s < 500; s++) ...ReorderPlanner.idsFor(s)};
      expect(ids, hasLength(1000));
    });

    test('ripianificare da gli stessi id: sostituisce, non duplica', () {
      final a = planner.plan(source: pellet, estimate: stima, now: DateTime(2026, 10, 11));
      final b = planner.plan(source: pellet, estimate: stima, now: DateTime(2026, 10, 12));
      expect(b.map((n) => n.id), a.map((n) => n.id));
    });

    test('gli id stanno in 32 bit; oltre il limite si lancia invece di traboccare', () {
      final max = ReorderPlanner.notificationId(
        ReorderPlanner.maxSourceId,
        ReorderNotificationKind.overdue,
      );
      expect(max, lessThanOrEqualTo(0x7FFFFFFF));
      expect(
        () => ReorderPlanner.notificationId(
          ReorderPlanner.maxSourceId + 1,
          ReorderNotificationKind.reorder,
        ),
        throwsArgumentError,
      );
      expect(
        () => ReorderPlanner.notificationId(-1, ReorderNotificationKind.reorder),
        throwsArgumentError,
      );
    });
  });
}

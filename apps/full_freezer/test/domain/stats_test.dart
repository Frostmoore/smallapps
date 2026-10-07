import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/data/database.dart';
import 'package:full_freezer/domain/stats.dart';

/// F4.7 / F4.10: le statistiche dello spreco.
void main() {
  final now = DateTime(2026, 10, 7, 12);

  Item uscito(int id, {required String status, required String frozenAt, required DateTime out, String? category}) => Item(
    id: id,
    freezerId: 1,
    name: 'I$id',
    nameNorm: 'i$id',
    category: category,
    quantity: 1,
    unit: 'portions',
    frozenAt: frozenAt,
    volumeLiters: 0.4,
    volumeManual: false,
    status: status,
    removedAt: out.toUtc().millisecondsSinceEpoch,
    createdAt: 0,
  );

  final dati = [
    uscito(1, status: ItemStatus.consumed, frozenAt: '2026-09-01', out: DateTime(2026, 10, 1)),
    uscito(2, status: ItemStatus.discarded, frozenAt: '2026-06-01', out: DateTime(2026, 10, 2), category: 'bread'),
    uscito(3, status: ItemStatus.discarded, frozenAt: '2026-08-01', out: DateTime(2026, 9, 20), category: 'bread'),
    uscito(4, status: ItemStatus.discarded, frozenAt: '2026-08-01', out: DateTime(2026, 9, 25), category: 'fish'),
    // Un anno e mezzo fa: fuori da "12 mesi", dentro "Sempre".
    uscito(5, status: ItemStatus.consumed, frozenAt: '2025-03-01', out: DateTime(2025, 4, 1)),
  ];

  test('contano le righe uscite nel periodo', () {
    final s = computeStats(dati, period: StatsPeriod.year, now: now);
    expect(s.consumed, 1);
    expect(s.discarded, 3);
    expect(s.wasteRate, closeTo(0.75, 1e-9));
  });

  test('"Sempre" include tutto, "30 giorni" solo l ultimo mese', () {
    expect(computeStats(dati, period: StatsPeriod.all, now: now).total, 5);
    // Dal 7 settembre in poi: 1, 2, 3, 4.
    expect(computeStats(dati, period: StatsPeriod.month, now: now).total, 4);
  });

  test('la permanenza media e in giorni da calendario', () {
    final s = computeStats([dati.first], period: StatsPeriod.all, now: now);
    expect(s.averageDays, 30); // 1 settembre -> 1 ottobre
  });

  test('la categoria piu buttata, con quante volte', () {
    final s = computeStats(dati, period: StatsPeriod.year, now: now);
    expect(s.mostWastedCategory, 'bread');
    expect(s.mostWastedCount, 2);
  });

  test('il grafico ha sempre sei mesi, dal piu vecchio, e il mese giusto', () {
    final s = computeStats(dati, period: StatsPeriod.month, now: now);
    expect(s.months, hasLength(statsMonths));
    expect((s.months.first.year, s.months.first.month), (2026, 5));
    expect((s.months.last.year, s.months.last.month), (2026, 10));
    final ottobre = s.months.last;
    expect((ottobre.consumed, ottobre.discarded), (1, 1));
    final settembre = s.months[statsMonths - 2];
    expect((settembre.consumed, settembre.discarded), (0, 2));
  });

  test('senza uscite: niente divisioni per zero', () {
    final s = computeStats(const <Item>[], period: StatsPeriod.all, now: now);
    expect(s.isEmpty, isTrue);
    expect(s.wasteRate, 0);
    expect(s.averageDays, isNull);
    expect(s.mostWastedCategory, isNull);
  });
}

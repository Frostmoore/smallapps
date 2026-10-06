import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/domain/aging.dart';
import 'package:micro_core/micro_core.dart';

/// F4.3: anzianita' e ordinamento "il piu' vecchio per primo".
void main() {
  const calc = AgingCalculator();
  final oggi = CivilDate(2026, 10, 6);

  test('i giorni si contano da calendario, e il giorno stesso vale 0', () {
    expect(calc.daysInFreezer(oggi, today: oggi), 0);
    expect(calc.daysInFreezer(CivilDate(2026, 10, 5), today: oggi), 1);
    // Attraverso il cambio dell'ora legale (25 ottobre) e un anno bisestile.
    expect(calc.daysInFreezer(CivilDate(2026, 10, 20), today: CivilDate(2026, 10, 30)), 10);
    expect(calc.daysInFreezer(CivilDate(2028, 2, 28), today: CivilDate(2028, 3, 1)), 2);
  });

  test('una data nel futuro vale 0 giorni, non un numero negativo', () {
    expect(calc.daysInFreezer(CivilDate(2026, 10, 7), today: oggi), 0);
  });

  group('livelli', () {
    AgingInfo con(int giorniFa, {int? promemoria, String? categoria}) => calc.evaluate(
      frozenAt: oggi.addDays(-giorniFa),
      reminderAfterDays: promemoria,
      categoryKey: categoria,
      today: oggi,
    );

    test('fresh sotto l 80%, watch dall 80%, old dal promemoria in poi', () {
      expect(con(79, promemoria: 100).level, AgingLevel.fresh);
      expect(con(80, promemoria: 100).level, AgingLevel.watch);
      expect(con(99, promemoria: 100).level, AgingLevel.watch);
      expect(con(100, promemoria: 100).level, AgingLevel.old);
    });

    test('overdueBy conta solo i giorni oltre il promemoria', () {
      expect(con(100, promemoria: 100).overdueBy, isNull);
      expect(con(137, promemoria: 100).overdueBy, 37);
      expect(con(50, promemoria: 100).overdueBy, isNull);
    });

    test('il promemoria dell alimento vince su quello della categoria', () {
      // Pesce: 120 giorni di categoria, 30 scelti dall'utente.
      final info = con(40, promemoria: 30, categoria: 'fish');
      expect(info.reminderDays, 30);
      expect(info.level, AgingLevel.old);
    });

    test('senza promemoria personale si usa quello della categoria', () {
      expect(con(100, categoria: 'fish').reminderDays, 120);
      expect(con(100, categoria: 'fish').level, AgingLevel.watch);
    });

    test('senza nessun promemoria e sempre fresh, ma i giorni ci sono', () {
      final info = con(900);
      expect(info.level, AgingLevel.fresh);
      expect(info.days, 900);
      expect(info.reminderDays, isNull);
    });
  });

  test('l ordinamento guarda la data, non il livello', () {
    // Un alimento di 400 giorni senza promemoria deve stare SOPRA uno di 100 giorni in "old".
    final dimenticato = oggi.addDays(-400);
    final vecchioConPromemoria = oggi.addDays(-100);
    expect(compareOldestFirst(dimenticato, vecchioConPromemoria), lessThan(0));
    // A parita' di data, l'inserito prima.
    expect(compareOldestFirst(oggi, oggi, tieA: 3, tieB: 7), lessThan(0));
  });
}

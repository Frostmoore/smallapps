import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:trashcan/domain/occurrence_engine.dart';
import 'package:trashcan/domain/recurrence.dart';

/// Date di riferimento usate in tutta la suite, verificate a mano:
///   2026-09-07 lunedi     2026-09-09 mercoledi   2026-09-11 venerdi
///   2026-03-29 domenica   inizio ora legale in Italia
///   2026-10-25 domenica   fine ora legale in Italia
///   2026-12-25 venerdi    2026-12-26 sabato      2026-12-31 giovedi
const int organico = 1;
const int carta = 2;
const int plastica = 3;

CivilDate d(String iso) => CivilDate.parse(iso);

List<String> isoOf(List<CollectionOccurrence> occurrences) =>
    occurrences.map((o) => o.date.toIso()).toList();

RuleWithExceptions weekly(
  int wasteTypeId,
  Set<int> weekdays, {
  String start = '2026-01-01',
  String? end,
  List<CollectionException> exceptions = const <CollectionException>[],
  int sortOrder = 0,
}) => RuleWithExceptions(
  wasteTypeId: wasteTypeId,
  sortOrder: sortOrder,
  exceptions: exceptions,
  recurrence: WeeklyRecurrence(
    weekdays: weekdays,
    startDate: d(start),
    endDate: end == null ? null : d(end),
  ),
);

void main() {
  const engine = OccurrenceEngine();

  group('settimanale', () {
    test('due giorni a settimana su quattro settimane', () {
      final rules = [
        weekly(organico, {DateTime.monday, DateTime.thursday}),
      ];
      final result = engine.expand(rules: rules, from: d('2026-09-07'), to: d('2026-10-04'));
      expect(result, hasLength(8));
      expect(isoOf(result).first, '2026-09-07');
      expect(isoOf(result), contains('2026-09-10'));
      expect(isoOf(result).last, '2026-10-01');
      expect(result.every((o) => o.origin == OccurrenceOrigin.regular), isTrue);
    });

    test('nessuna occorrenza prima di startDate', () {
      final rules = [
        weekly(organico, {DateTime.monday}, start: '2026-09-14'),
      ];
      final result = engine.expand(rules: rules, from: d('2026-09-01'), to: d('2026-09-20'));
      expect(isoOf(result), ['2026-09-14']);
    });

    test('nessuna occorrenza dopo endDate', () {
      final rules = [
        weekly(organico, {DateTime.monday}, start: '2026-09-01', end: '2026-09-15'),
      ];
      final result = engine.expand(rules: rules, from: d('2026-09-01'), to: d('2026-09-30'));
      expect(isoOf(result), ['2026-09-07', '2026-09-14']);
    });

    test('finestra invertita restituisce lista vuota senza errori', () {
      final rules = [
        weekly(organico, {DateTime.monday}),
      ];
      expect(engine.expand(rules: rules, from: d('2026-09-30'), to: d('2026-09-01')), isEmpty);
    });

    test('nessuna regola, nessuna occorrenza', () {
      expect(engine.expand(rules: const [], from: d('2026-09-01'), to: d('2026-12-31')), isEmpty);
    });
  });

  group('ogni N settimane', () {
    test('mercoledi alterni: l ancora decide la parita', () {
      final rules = [
        RuleWithExceptions(
          wasteTypeId: carta,
          recurrence: EveryNWeeksRecurrence(
            weekdays: {DateTime.wednesday},
            intervalWeeks: 2,
            anchorDate: d('2026-09-09'),
            startDate: d('2026-01-01'),
          ),
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-09-01'), to: d('2026-10-31'));
      expect(isoOf(result), ['2026-09-09', '2026-09-23', '2026-10-07', '2026-10-21']);
    });

    test('il ciclo vale anche prima dell ancora', () {
      // L'utente indica come ancora la prossima raccolta, ma il calendario mensile
      // mostra anche il passato: le date precedenti devono rispettare la stessa parita.
      final rules = [
        RuleWithExceptions(
          wasteTypeId: carta,
          recurrence: EveryNWeeksRecurrence(
            weekdays: {DateTime.wednesday},
            intervalWeeks: 2,
            anchorDate: d('2026-09-09'),
            startDate: d('2026-01-01'),
          ),
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-08-01'), to: d('2026-09-08'));
      expect(isoOf(result), ['2026-08-12', '2026-08-26']);
    });

    test('a cavallo del 31 dicembre non si salta ne si raddoppia', () {
      // Con il numero di settimana ISO qui comparirebbe un salto: la settimana 1 del
      // 2027 ripartirebbe da capo. Con l ancora, la cadenza resta di 14 giorni esatti.
      final rules = [
        RuleWithExceptions(
          wasteTypeId: carta,
          recurrence: EveryNWeeksRecurrence(
            weekdays: {DateTime.wednesday},
            intervalWeeks: 2,
            anchorDate: d('2026-12-16'),
            startDate: d('2026-01-01'),
          ),
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-12-01'), to: d('2027-01-31'));
      expect(isoOf(result), ['2026-12-02', '2026-12-16', '2026-12-30', '2027-01-13', '2027-01-27']);
      for (var i = 1; i < result.length; i++) {
        expect(result[i - 1].date.daysUntil(result[i].date), 14);
      }
    });

    test('ogni 3 settimane su due giorni', () {
      final rules = [
        RuleWithExceptions(
          wasteTypeId: carta,
          recurrence: EveryNWeeksRecurrence(
            weekdays: {DateTime.tuesday, DateTime.friday},
            intervalWeeks: 3,
            anchorDate: d('2026-09-08'),
            startDate: d('2026-09-01'),
          ),
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-09-01'), to: d('2026-10-31'));
      expect(isoOf(result), [
        '2026-09-08',
        '2026-09-11',
        '2026-09-29',
        '2026-10-02',
        '2026-10-20',
        '2026-10-23',
      ]);
    });
  });

  group('mensile per giorno del mese', () {
    test('il 31 di ogni mese fa il clamp nei mesi corti', () {
      final rules = [
        RuleWithExceptions(
          wasteTypeId: plastica,
          recurrence: MonthlyDayRecurrence(dayOfMonth: 31, startDate: d('2026-01-01')),
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-01-01'), to: d('2026-06-30'));
      expect(isoOf(result), [
        '2026-01-31',
        '2026-02-28',
        '2026-03-31',
        '2026-04-30',
        '2026-05-31',
        '2026-06-30',
      ]);
    });

    test('il 31 in febbraio bisestile cade il 29', () {
      final rules = [
        RuleWithExceptions(
          wasteTypeId: plastica,
          recurrence: MonthlyDayRecurrence(dayOfMonth: 31, startDate: d('2024-02-01')),
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2024-02-01'), to: d('2024-02-29'));
      expect(isoOf(result), ['2024-02-29']);
    });

    test('un giorno che esiste sempre non viene toccato dal clamp', () {
      final rules = [
        RuleWithExceptions(
          wasteTypeId: plastica,
          recurrence: MonthlyDayRecurrence(dayOfMonth: 15, startDate: d('2026-01-01')),
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-01-01'), to: d('2026-03-31'));
      expect(isoOf(result), ['2026-01-15', '2026-02-15', '2026-03-15']);
    });
  });

  group('mensile per ennesimo giorno della settimana', () {
    test('primo lunedi del mese', () {
      final rules = [
        RuleWithExceptions(
          wasteTypeId: plastica,
          recurrence: MonthlyNthWeekdayRecurrence(
            nth: 1,
            weekday: DateTime.monday,
            startDate: d('2026-09-01'),
          ),
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-09-01'), to: d('2026-11-30'));
      expect(isoOf(result), ['2026-09-07', '2026-10-05', '2026-11-02']);
    });

    test('ultimo venerdi del mese', () {
      final rules = [
        RuleWithExceptions(
          wasteTypeId: plastica,
          recurrence: MonthlyNthWeekdayRecurrence(
            nth: -1,
            weekday: DateTime.friday,
            startDate: d('2026-09-01'),
          ),
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-09-01'), to: d('2026-10-31'));
      expect(isoOf(result), ['2026-09-25', '2026-10-30']);
    });

    test('il quinto di un giorno che nel mese non c e cinque volte non produce nulla', () {
      final rules = [
        RuleWithExceptions(
          wasteTypeId: plastica,
          recurrence: MonthlyNthWeekdayRecurrence(
            nth: 5,
            weekday: DateTime.monday,
            startDate: d('2026-09-01'),
          ),
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-09-01'), to: d('2026-09-30'));
      expect(result, isEmpty, reason: 'settembre 2026 ha solo quattro lunedi');
    });
  });

  group('date manuali', () {
    test('solo le date elencate, ordinate', () {
      final rules = [
        RuleWithExceptions(
          wasteTypeId: plastica,
          recurrence: ManualDatesRecurrence(
            dates: [d('2026-11-20'), d('2026-09-15'), d('2026-10-10')],
            startDate: d('2026-01-01'),
          ),
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-09-01'), to: d('2026-12-31'));
      expect(isoOf(result), ['2026-09-15', '2026-10-10', '2026-11-20']);
    });
  });

  group('eccezioni', () {
    test('salta: la raccolta di Natale sparisce', () {
      final rules = [
        weekly(
          carta,
          {DateTime.friday},
          exceptions: [CollectionException.skip(id: 1, wasteTypeId: carta, date: d('2026-12-25'))],
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-12-18'), to: d('2026-12-31'));
      expect(isoOf(result), ['2026-12-18']);
    });

    test('sposta: una sola occorrenza, alla nuova data, marcata moved', () {
      final rules = [
        weekly(
          carta,
          {DateTime.friday},
          exceptions: [
            CollectionException.move(
              id: 1,
              wasteTypeId: carta,
              from: d('2026-12-25'),
              to: d('2026-12-26'),
            ),
          ],
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-12-20'), to: d('2026-12-31'));
      expect(isoOf(result), ['2026-12-26']);
      expect(result.single.origin, OccurrenceOrigin.moved);
      expect(result.single.originalDate, d('2026-12-25'));
    });

    test('salta e sposta la stessa data: prevale il salto', () {
      // L ordine delle fasi in expand() e vincolante proprio per questo caso: uno
      // spostamento su una data gia annullata non deve resuscitare la raccolta.
      final rules = [
        weekly(
          carta,
          {DateTime.friday},
          exceptions: [
            CollectionException.skip(id: 1, wasteTypeId: carta, date: d('2026-12-25')),
            CollectionException.move(
              id: 2,
              wasteTypeId: carta,
              from: d('2026-12-25'),
              to: d('2026-12-26'),
            ),
          ],
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-12-20'), to: d('2026-12-31'));
      expect(result, isEmpty);
    });

    test('sposta verso una data fuori finestra: l originale sparisce comunque', () {
      final rules = [
        weekly(
          carta,
          {DateTime.friday},
          exceptions: [
            CollectionException.move(
              id: 1,
              wasteTypeId: carta,
              from: d('2026-12-25'),
              to: d('2027-01-08'),
            ),
          ],
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-12-20'), to: d('2026-12-31'));
      expect(result, isEmpty, reason: 'il 25 non c e piu, e l 8 gennaio e fuori finestra');
    });

    test('sposta una data che la regola non genera: non inventa raccolte', () {
      final rules = [
        weekly(
          carta,
          {DateTime.friday},
          exceptions: [
            CollectionException.move(
              id: 1,
              wasteTypeId: carta,
              from: d('2026-12-24'),
              to: d('2026-12-26'),
            ),
          ],
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-12-20'), to: d('2026-12-31'));
      expect(isoOf(result), ['2026-12-25'], reason: 'il 24 non era una raccolta');
    });

    test('straordinaria: compare marcata extra', () {
      final rules = [
        weekly(
          plastica,
          {DateTime.tuesday},
          exceptions: [
            CollectionException.extra(
              id: 1,
              wasteTypeId: plastica,
              date: d('2026-12-31'),
              note: 'ritiro aggiuntivo di fine anno',
            ),
          ],
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-12-28'), to: d('2026-12-31'));
      expect(isoOf(result), ['2026-12-29', '2026-12-31']);
      expect(result.last.origin, OccurrenceOrigin.extra);
      expect(result.last.note, 'ritiro aggiuntivo di fine anno');
    });

    test('straordinaria che coincide con una ordinaria: una sola, marcata extra', () {
      final rules = [
        weekly(
          plastica,
          {DateTime.tuesday},
          exceptions: [
            CollectionException.extra(id: 1, wasteTypeId: plastica, date: d('2026-12-29')),
          ],
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-12-28'), to: d('2026-12-30'));
      expect(result, hasLength(1));
      expect(result.single.origin, OccurrenceOrigin.extra);
    });

    test('eccezione malformata viene ignorata invece di far saltare tutto', () {
      const malformed = CollectionException(id: 9, wasteTypeId: carta);
      final rules = [
        weekly(carta, {DateTime.friday}, exceptions: const [malformed]),
      ];
      final result = engine.expand(rules: rules, from: d('2026-12-18'), to: d('2026-12-25'));
      expect(isoOf(result), ['2026-12-18', '2026-12-25']);
    });
  });

  group('ordinamento e piu regole', () {
    test('due tipi lo stesso giorno seguono il sortOrder', () {
      final rules = [
        weekly(plastica, {DateTime.monday}, sortOrder: 5),
        weekly(organico, {DateTime.monday}, sortOrder: 1),
      ];
      final result = engine.expand(rules: rules, from: d('2026-09-07'), to: d('2026-09-07'));
      expect(result.map((o) => o.wasteTypeId).toList(), [organico, plastica]);
    });

    test('regole diverse si fondono in ordine cronologico', () {
      final rules = [
        weekly(organico, {DateTime.monday, DateTime.thursday}, sortOrder: 1),
        weekly(carta, {DateTime.wednesday}, sortOrder: 2),
      ];
      final result = engine.expand(rules: rules, from: d('2026-09-07'), to: d('2026-09-13'));
      expect(isoOf(result), ['2026-09-07', '2026-09-09', '2026-09-10']);
    });

    test('due regole sullo stesso tipo nello stesso giorno non si duplicano', () {
      final rules = [
        weekly(organico, {DateTime.monday}),
        weekly(organico, {DateTime.monday, DateTime.friday}),
      ];
      final result = engine.expand(rules: rules, from: d('2026-09-07'), to: d('2026-09-13'));
      expect(isoOf(result), ['2026-09-07', '2026-09-11']);
    });
  });

  group('ora legale (ADR-008)', () {
    test('il passaggio a ora legale non sposta le raccolte', () {
      final rules = [
        weekly(organico, {DateTime.sunday, DateTime.monday}),
      ];
      final result = engine.expand(rules: rules, from: d('2026-03-27'), to: d('2026-03-31'));
      expect(isoOf(result), ['2026-03-29', '2026-03-30']);
    });

    test('il ritorno a ora solare non sposta le raccolte', () {
      final rules = [
        weekly(organico, {DateTime.sunday, DateTime.monday}),
      ];
      final result = engine.expand(rules: rules, from: d('2026-10-23'), to: d('2026-10-27'));
      expect(isoOf(result), ['2026-10-25', '2026-10-26']);
    });

    test('una cadenza quindicinale attraverso il cambio d ora resta di 14 giorni', () {
      final rules = [
        RuleWithExceptions(
          wasteTypeId: carta,
          recurrence: EveryNWeeksRecurrence(
            weekdays: {DateTime.wednesday},
            intervalWeeks: 2,
            anchorDate: d('2026-03-18'),
            startDate: d('2026-01-01'),
          ),
        ),
      ];
      final result = engine.expand(rules: rules, from: d('2026-03-01'), to: d('2026-04-30'));
      for (var i = 1; i < result.length; i++) {
        expect(result[i - 1].date.daysUntil(result[i].date), 14);
      }
      expect(isoOf(result), contains('2026-04-01'));
    });
  });

  group('anno bisestile', () {
    test('il 29 febbraio e un giorno come gli altri', () {
      final rules = [
        weekly(organico, {DateTime.thursday}, start: '2024-01-01'),
      ];
      final result = engine.expand(rules: rules, from: d('2024-02-26'), to: d('2024-03-03'));
      expect(isoOf(result), ['2024-02-29']);
    });
  });

  group('tonight, next, nextN', () {
    test('tonight mostra la raccolta di DOMANI', () {
      // Regola di prodotto piu importante dell app: stasera si porta fuori quello che
      // raccolgono domani mattina.
      final rules = [
        weekly(organico, {DateTime.thursday}),
      ];
      final tonight = engine.tonight(rules: rules, today: d('2026-09-09'));
      expect(isoOf(tonight), ['2026-09-10']);
    });

    test('tonight vuoto quando domani non raccolgono nulla', () {
      final rules = [
        weekly(organico, {DateTime.thursday}),
      ];
      expect(engine.tonight(rules: rules, today: d('2026-09-10')), isEmpty);
    });

    test('next trova la prossima raccolta a partire da oggi incluso', () {
      final rules = [
        weekly(organico, {DateTime.thursday}),
      ];
      final next = engine.next(rules: rules, from: d('2026-09-10'));
      expect(next?.date.toIso(), '2026-09-10');
    });

    test('next restituisce null se non c e nulla entro l orizzonte', () {
      final rules = [
        weekly(organico, {DateTime.thursday}, start: '2026-01-01', end: '2026-01-31'),
      ];
      expect(engine.next(rules: rules, from: d('2026-09-01')), isNull);
    });

    test('nextN restituisce esattamente il numero richiesto', () {
      final rules = [
        weekly(organico, {DateTime.monday, DateTime.thursday}),
      ];
      final six = engine.nextN(6, rules: rules, from: d('2026-09-07'));
      expect(isoOf(six), [
        '2026-09-07',
        '2026-09-10',
        '2026-09-14',
        '2026-09-17',
        '2026-09-21',
        '2026-09-24',
      ]);
    });

    test('nextN con regola mensile guarda oltre l anno', () {
      final rules = [
        RuleWithExceptions(
          wasteTypeId: plastica,
          recurrence: MonthlyDayRecurrence(dayOfMonth: 1, startDate: d('2026-01-01')),
        ),
      ];
      final six = engine.nextN(6, rules: rules, from: d('2026-09-02'));
      expect(six, hasLength(6));
      expect(isoOf(six).last, '2027-03-01');
    });

    test('nextN con count zero o negativo', () {
      final rules = [
        weekly(organico, {DateTime.monday}),
      ];
      expect(engine.nextN(0, rules: rules, from: d('2026-09-07')), isEmpty);
      expect(engine.nextN(-3, rules: rules, from: d('2026-09-07')), isEmpty);
    });
  });

  group('bitmask dei giorni', () {
    test('round-trip su tutte le combinazioni', () {
      for (var mask = 0; mask < 128; mask++) {
        expect(WeekdayMask.fromSet(WeekdayMask.toSet(mask)), mask);
      }
    });

    test('lunedi e il bit 0, domenica il bit 6', () {
      expect(WeekdayMask.fromSet({DateTime.monday}), 1);
      expect(WeekdayMask.fromSet({DateTime.sunday}), 64);
      expect(WeekdayMask.fromSet({DateTime.monday, DateTime.sunday}), 65);
      expect(WeekdayMask.toSet(0), isEmpty);
    });
  });
}

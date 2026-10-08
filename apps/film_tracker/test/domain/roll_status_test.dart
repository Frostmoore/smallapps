import 'package:film_tracker/domain/roll_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

/// F6.3: la macchina a stati del rullino.
void main() {
  const m = RollStatusMachine();
  CivilDate d(String iso) => CivilDate.parse(iso);

  group('canTransition: la matrice 6x6', () {
    // La tabella e' riscritta a mano dal piano (F6.3), non derivata da allowedTransitions:
    // un errore nella mappa deve far fallire il test, non passare con lei.
    // Righe = da, colonne = a, nell'ordine di RollStatus.values.
    const o = RollStatus.values;
    const expected = <RollStatus, List<int>>{
      //                              lo ex se de pr ar
      RollStatus.loaded: /*         */ [0, 1, 0, 0, 0, 1],
      RollStatus.exposed: /*        */ [0, 0, 1, 1, 0, 1],
      RollStatus.sentForDevelopment: [0, 1, 0, 1, 0, 1],
      RollStatus.developed: /*      */ [0, 0, 0, 0, 1, 1],
      RollStatus.printed: /*        */ [0, 0, 0, 1, 0, 1],
      RollStatus.archived: /*       */ [0, 0, 0, 1, 1, 0],
    };

    for (final from in o) {
      for (final to in o) {
        final allowed = expected[from]![o.indexOf(to)] == 1;
        test('${from.key} -> ${to.key}: ${allowed ? 'ammessa' : 'vietata'}', () {
          expect(m.canTransition(from, to), allowed);
        });
      }
    }

    test('lo stesso stato non e\' mai una transizione', () {
      for (final s in o) {
        expect(m.canTransition(s, s), isFalse, reason: s.key);
      }
    });

    test('nessuno stato e\' un vicolo cieco: da ognuno si esce', () {
      for (final s in o) {
        expect(RollStatusMachine.allowedTransitions[s], isNotEmpty, reason: s.key);
      }
    });
  });

  group('sectionFor', () {
    test('loaded/exposed in macchina, sentForDevelopment in laboratorio, il resto archivio', () {
      expect(m.sectionFor(RollStatus.loaded), RollSection.inCamera);
      expect(m.sectionFor(RollStatus.exposed), RollSection.inCamera);
      expect(m.sectionFor(RollStatus.sentForDevelopment), RollSection.atLab);
      expect(m.sectionFor(RollStatus.developed), RollSection.archive);
      expect(m.sectionFor(RollStatus.printed), RollSection.archive);
      expect(m.sectionFor(RollStatus.archived), RollSection.archive);
    });

    test('statusesIn e\' l\'inverso di sectionFor e copre tutti gli stati una volta', () {
      final all = [for (final s in RollSection.values) ...m.statusesIn(s)];
      expect(all.toSet(), RollStatus.values.toSet());
      expect(all.length, RollStatus.values.length);
      expect(m.statusesIn(RollSection.atLab), {RollStatus.sentForDevelopment});
    });
  });

  group('chiavi', () {
    test('le chiavi salvate nel database sono quelle del piano e tornano indietro', () {
      expect(
        [for (final s in RollStatus.values) s.key],
        ['loaded', 'exposed', 'sentForDevelopment', 'developed', 'printed', 'archived'],
      );
      for (final s in RollStatus.values) {
        expect(RollStatus.byKey(s.key), s);
      }
      expect(RollStatus.byKey('lost'), isNull);
      expect(RollStatus.byKey(null), isNull);
    });
  });

  group('suggestFrom: otto combinazioni di sviluppo e stampa', () {
    // Il rullino di partenza e' `exposed`, finito il 1 settembre.
    RollStatus suggest({LabEvent? dev, List<LabEvent> prints = const []}) => m.suggestFrom(
      current: RollStatus.exposed,
      finishedAt: d('2026-09-01'),
      development: dev,
      prints: prints,
    );

    final consegnato = LabEvent(submittedAt: d('2026-09-02'));
    final tornato = LabEvent(submittedAt: d('2026-09-02'), returnedAt: d('2026-09-10'));
    const inCasa = LabEvent(selfDeveloped: true);
    final stampaInAttesa = LabEvent(submittedAt: d('2026-09-12'));
    final stampaTornata = LabEvent(submittedAt: d('2026-09-12'), returnedAt: d('2026-09-20'));

    test('1. niente sviluppo, niente stampe: resta exposed', () {
      expect(suggest(), RollStatus.exposed);
    });

    test('2. sviluppo consegnato e non tornato: sentForDevelopment', () {
      expect(suggest(dev: consegnato), RollStatus.sentForDevelopment);
    });

    test('3. sviluppo registrato senza date: e\' comunque consegnato', () {
      expect(suggest(dev: const LabEvent()), RollStatus.sentForDevelopment);
    });

    test('4. sviluppo tornato: developed', () {
      expect(suggest(dev: tornato), RollStatus.developed);
    });

    test('5. sviluppo in casa, anche senza date: developed', () {
      expect(suggest(dev: inCasa), RollStatus.developed);
    });

    test('6. sviluppo tornato e stampa in attesa: resta developed', () {
      expect(suggest(dev: tornato, prints: [stampaInAttesa]), RollStatus.developed);
    });

    test('7. sviluppo tornato e una stampa tornata fra due: printed', () {
      expect(suggest(dev: tornato, prints: [stampaInAttesa, stampaTornata]), RollStatus.printed);
    });

    test('8. stampa tornata senza sviluppo registrato (il lab ha fatto tutto): printed', () {
      expect(suggest(prints: [stampaTornata]), RollStatus.printed);
    });

    test('una stampa tornata vince anche su uno sviluppo ancora in laboratorio', () {
      expect(suggest(dev: consegnato, prints: [stampaTornata]), RollStatus.printed);
    });
  });

  group('suggestFrom: lo stato messo a mano', () {
    test('archived resta archived qualunque cosa sia registrata', () {
      expect(
        m.suggestFrom(
          current: RollStatus.archived,
          development: LabEvent(returnedAt: d('2026-09-10')),
          prints: [LabEvent(returnedAt: d('2026-09-20'))],
        ),
        RollStatus.archived,
      );
    });

    test('loaded con la data di fine diventa exposed; senza, resta loaded', () {
      expect(
        m.suggestFrom(current: RollStatus.loaded, finishedAt: d('2026-09-01')),
        RollStatus.exposed,
      );
      expect(m.suggestFrom(current: RollStatus.loaded), RollStatus.loaded);
    });

    test('senza eventi non si suggerisce mai di tornare indietro', () {
      for (final s in [RollStatus.sentForDevelopment, RollStatus.developed, RollStatus.printed]) {
        expect(m.suggestFrom(current: s), s, reason: s.key);
      }
    });
  });
}

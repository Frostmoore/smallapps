import 'package:film_tracker/data/database.dart';
import 'package:film_tracker/domain/roll_status.dart';
import 'package:film_tracker/features/rolls/roll_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_roll_repo.dart';

/// F6.6: il dettaglio del rullino mostra l'azione giusta per lo stato, la timeline con date e
/// costi, e il suggerimento quando sviluppo e stampe dicono un altro stato.
void main() {
  const finished = ValueKey('action-finished');
  const deliver = ValueKey('action-deliver');
  const develop = ValueKey('action-development');
  const print = ValueKey('action-print');
  const archive = ValueKey('action-archive');
  const all = [finished, deliver, develop, print, archive];

  /// Le azioni presenti nella pagina, fra quelle dipendenti dallo stato.
  Set<ValueKey<String>> actions() => {
    for (final k in all)
      if (find.byKey(k).evaluate().isNotEmpty) k,
  };

  final expected = <RollStatus, Set<ValueKey<String>>>{
    RollStatus.loaded: {finished},
    RollStatus.exposed: {deliver},
    RollStatus.sentForDevelopment: {develop},
    RollStatus.developed: {print, archive},
    RollStatus.printed: {print, archive},
    RollStatus.archived: {print},
  };

  for (final MapEntry(key: status, value: want) in expected.entries) {
    testWidgets('stato ${status.key}: le azioni giuste', (tester) async {
      await pumpRollPage(tester, const RollDetailPage(rollId: 1), rolls: [roll(1, status: status)]);
      expect(actions(), want);
      expect(find.byKey(const ValueKey('roll-suggestion')), findsNothing);
    });
  }

  testWidgets('"Rullino terminato" in un tocco: markFinished con oggi, poi "Consegna"', (
    tester,
  ) async {
    final repo = await pumpRollPage(tester, const RollDetailPage(rollId: 1), rolls: [roll(1)]);

    await tester.tap(find.byKey(finished));
    await tester.pumpAndSettle();

    expect(repo.finishedCalls, [(1, testToday)]);
    expect(actions(), {deliver});
    expect(find.text('Segnato come terminato.'), findsOneWidget);
  });

  testWidgets('"Archivia" passa a archived senza forzare', (tester) async {
    final repo = await pumpRollPage(
      tester,
      const RollDetailPage(rollId: 1),
      rolls: [roll(1, status: RollStatus.developed)],
      developments: [development(1, submittedAt: '2026-10-02', returnedAt: '2026-10-06')],
    );

    await tester.tap(find.byKey(archive));
    await tester.pumpAndSettle();

    expect(repo.statusCalls, [(1, RollStatus.archived, false)]);
    expect(actions(), {print});
  });

  testWidgets('il cambio di stato a mano offre solo le transizioni ammesse', (tester) async {
    await pumpRollPage(
      tester,
      const RollDetailPage(rollId: 1),
      rolls: [roll(1, status: RollStatus.sentForDevelopment)],
      developments: [development(1, submittedAt: '2026-10-02')],
    );

    await tester.tap(find.text('Cambia stato'));
    await tester.pumpAndSettle();

    final offered = {
      for (final s in RollStatus.values)
        if (find.byKey(ValueKey('status-${s.key}')).evaluate().isNotEmpty) s,
    };
    expect(offered, RollStatusMachine.allowedTransitions[RollStatus.sentForDevelopment]);
  });

  testWidgets('sviluppo tornato su un rullino "terminato": suggerisce "Sviluppato"', (
    tester,
  ) async {
    final repo = await pumpRollPage(
      tester,
      const RollDetailPage(rollId: 1),
      rolls: [roll(1, status: RollStatus.exposed, finishedAt: '2026-10-02')],
      developments: [development(1, submittedAt: '2026-10-03', returnedAt: '2026-10-07')],
    );

    expect(find.text('Sviluppo e stampe dicono “Sviluppato”.'), findsOneWidget);
    await tester.tap(find.text('Applica'));
    await tester.pumpAndSettle();

    expect(repo.statusCalls, [(1, RollStatus.developed, false)]);
    expect(find.byKey(const ValueKey('roll-suggestion')), findsNothing);
  });

  testWidgets('la timeline mostra date e costi, e la spesa totale', (tester) async {
    await pumpRollPage(
      tester,
      const RollDetailPage(rollId: 1),
      cameras: [om2],
      rolls: [
        roll(1, status: RollStatus.printed, cameraId: 1, finishedAt: '2026-10-02', costCents: 1500),
      ],
      developments: [
        development(
          1,
          submittedAt: '2026-10-03',
          returnedAt: '2026-10-07',
          laboratory: 'Fotolab',
          costCents: 800,
          scanCents: 500,
        ),
      ],
      prints: [
        const PrintOrder(
          id: 9,
          filmRollId: 1,
          submittedAt: '2026-10-07',
          returnedAt: '2026-10-08',
          format: '10×15',
          numberOfPrints: 12,
          costCents: 600,
        ),
      ],
    );

    for (final t in ['Caricato', 'Terminato', 'Consegnato al laboratorio', 'Sviluppato']) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(find.text('Stampe ritirate'), findsOneWidget);
    expect(find.text('1 ott 2026'), findsOneWidget);
    expect(find.text('7 ott 2026'), findsOneWidget);
    expect(find.textContaining('Olympus OM-2 · 15,00'), findsOneWidget);
    expect(find.textContaining('sviluppo 8,00'), findsOneWidget);
    expect(find.textContaining('scansioni 5,00'), findsOneWidget);
    expect(find.textContaining('12 stampe'), findsOneWidget);
    // 15 + 8 + 5 + 6
    expect(find.textContaining('Spesa totale: 34,00'), findsOneWidget);
  });

  testWidgets('un rullino che non esiste piu’ lo dice', (tester) async {
    await pumpRollPage(tester, const RollDetailPage(rollId: 42));
    expect(find.text('Questo rullino non esiste più.'), findsOneWidget);
  });
}

import 'package:film_tracker/domain/roll_status.dart';
import 'package:film_tracker/features/lab/development_page.dart';
import 'package:film_tracker/features/lab/lab_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_film_repo.dart';

/// F6.7: lo sviluppo salvato porta il rullino nello stato che suggerisce (F6.3).
void main() {
  group('costi', () {
    test('euro digitati in centesimi, con la virgola o il punto', () {
      expect(parseCostCents('12,50'), 1250);
      expect(parseCostCents('6.5'), 650);
      expect(parseCostCents('6,50 €'), 650);
      expect(parseCostCents('0'), 0);
    });

    test('vuoto, testo e negativi non sono importi', () {
      expect(parseCostCents(''), isNull);
      expect(parseCostCents('dieci'), isNull);
      expect(parseCostCents('-3'), isNull);
      expect(isCostTextValid(''), isTrue);
      expect(isCostTextValid('dieci'), isFalse);
    });

    test('il testo del campo rilegge gli stessi centesimi', () {
      for (final locale in const ['it', 'en']) {
        expect(parseCostCents(costCentsToText(123456, locale)), 123456, reason: locale);
      }
    });
  });

  testWidgets('consegnato senza ritorno: il rullino passa in laboratorio', (tester) async {
    final repo = await pumpFilm(
      tester,
      page: const DevelopmentPage(rollId: 1),
      pro: false,
      rolls: [rullino(1, stockId: portra400.id)],
      stocks: [portra400],
    );

    // Il processo viene dalla pellicola, la consegna e' oggi.
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'C-41')).selected, isTrue);
    await tester.enterText(find.byKey(const ValueKey('dev_laboratory')), 'Fotoservice Roma');
    await tester.enterText(find.byKey(const ValueKey('dev_cost')), '12,50');
    await tapSalva(tester);

    final dev = repo.developments[1]!;
    expect(dev.laboratory, 'Fotoservice Roma');
    expect(dev.submittedAt, '2026-10-08');
    expect(dev.returnedAt, isNull);
    expect(dev.process, 'C-41');
    expect(dev.developmentCostCents, 1250);
    expect(repo.rolls[1]!.status, RollStatus.sentForDevelopment.key);
    expect(find.text('Salvato. Il rullino ora risulta in laboratorio.'), findsOneWidget);
  });

  testWidgets('con la data di ritorno: il rullino e\' sviluppato', (tester) async {
    final repo = await pumpFilm(
      tester,
      page: const DevelopmentPage(rollId: 1),
      pro: false,
      rolls: [rullino(1, stockId: portra400.id)],
      stocks: [portra400],
    );

    await tester.tap(find.byKey(const ValueKey('dev_returned')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapSalva(tester);

    final dev = repo.developments[1]!;
    expect(dev.submittedAt, '2026-10-08');
    expect(dev.returnedAt, '2026-10-08');
    expect(repo.rolls[1]!.status, RollStatus.developed.key);
  });

  testWidgets('sviluppato in casa: niente laboratorio, il rullino e\' sviluppato', (tester) async {
    final repo = await pumpFilm(tester, page: const DevelopmentPage(rollId: 1), pro: false, rolls: [rullino(1)]);

    await tester.tap(find.byKey(const ValueKey('dev_self')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev_laboratory')), findsNothing);
    await tapSalva(tester);

    final dev = repo.developments[1]!;
    expect(dev.selfDeveloped, isTrue);
    expect(dev.laboratory, isNull);
    expect(dev.submittedAt, isNull);
    expect(repo.rolls[1]!.status, RollStatus.developed.key);
  });

  testWidgets('un rullino ancora "in macchina" esce comunque dalla macchina', (tester) async {
    // loaded -> sentForDevelopment non e' una transizione ammessa: lo sviluppo registrato
    // dice pero' che il rullino e' finito, e la pagina lo forza (applySuggestedStatus).
    final repo = await pumpFilm(
      tester,
      page: const DevelopmentPage(rollId: 1),
      pro: false,
      rolls: [rullino(1, status: RollStatus.loaded)],
    );
    await tapSalva(tester);
    expect(repo.rolls[1]!.status, RollStatus.sentForDevelopment.key);
  });

  testWidgets('un costo non valido blocca il salvataggio', (tester) async {
    final repo = await pumpFilm(tester, page: const DevelopmentPage(rollId: 1), pro: false, rolls: [rullino(1)]);
    await tester.enterText(find.byKey(const ValueKey('dev_scanCost')), 'dieci');
    await tester.pumpAndSettle();
    expect(find.text('Scrivi un importo, come 12,50'), findsOneWidget);
    await tapSalva(tester);
    expect(repo.developments, isEmpty);
  });
}

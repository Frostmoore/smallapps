import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/domain/spesa.dart';

import 'sr_test_harness.dart';

/// La chiusura (develop_microapps.md F12.1.12, `/chiudi`): totale ed esito del budget, negozio,
/// data, Salva → storico; nel gratis oltre le 5 lo snack lo dice; spesa vuota → «niente da salvare».
void main() {
  setUp(zittisciPiattaforma);

  final inCorso = Spesa(
    id: 50,
    stato: StatoSpesa.inCorso,
    iniziataIl: kOra.toUtc(),
    budget: const Money.cents(1000),
    righe: [rigaTastierino(680, id: 1)],
  );

  testWidgets('totale, «Dentro il budget di 3,20», negozio scelto, Salva → storico', (tester) async {
    final h = await pumpSr(tester, initialLocation: '/chiudi', inCorso: inCorso);
    expect(tester.widget<Text>(find.byKey(const ValueKey('chiusura_totale'))).data, '6,80');
    expect(find.text('Dentro il budget di 3,20'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('negozio_altro')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('negozio_campo')), 'Coop');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chiusura_salva')));
    await tester.pumpAndSettle();
    expect(h.repo.inCorso, isNull);
    final chiusa = h.repo.chiuse.single;
    expect(chiusa.totale, const Money.cents(680));
    expect(chiusa.dataSpesa, CivilDate(2026, 10, 11));
    expect(h.repo.negozi.single.nome, 'Coop');
    expect(chiusa.negozioId, h.repo.negozi.single.id);
    expect(find.text('Le spese'), findsOneWidget);
    expect(find.text('Salvata.'), findsOneWidget);
  });

  testWidgets('gratis con gia\' 5 spese chiuse: lo snack dice che le altre restano sul telefono', (tester) async {
    final h = await pumpSr(
      tester,
      initialLocation: '/chiudi',
      inCorso: inCorso,
      chiuse: [for (var i = 1; i <= 5; i++) spesaChiusa(i, CivilDate(2026, 10, i), const Money.cents(100))],
    );
    await tester.tap(find.byKey(const ValueKey('chiusura_salva')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nel piano gratuito vedi le ultime 5'), findsOneWidget);
    expect(h.repo.chiuse, hasLength(6));
  });

  testWidgets('spesa senza righe: «Non c\'e\' niente da salvare» e Butta via', (tester) async {
    final h = await pumpSr(
      tester,
      initialLocation: '/chiudi',
      inCorso: Spesa(id: 51, stato: StatoSpesa.inCorso, iniziataIl: kOra.toUtc(), righe: const []),
    );
    expect(find.byKey(const ValueKey('chiusura_niente')), findsOneWidget);
    await tester.tap(find.text('Butta via'));
    await tester.pumpAndSettle();
    expect(h.repo.inCorso, isNull);
  });
}

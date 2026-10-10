import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/domain/lettura/scontrino_parser.dart';
import 'package:spending_review/domain/spesa.dart';
import 'package:spending_review/services/lettura_service.dart';

import 'sr_test_harness.dart';

/// «Scontrino contro conto» (develop_microapps.md F12.1.12, F12.1.17 `confronto_page_test.dart`):
/// card ambra con il delta e le righe sospette; «Tutto torna»; Pro sulla rotta.
void main() {
  setUp(zittisciPiattaforma);

  RigaScontrino art(String d, int c) => RigaScontrino(descrizione: d, importo: Money.cents(c), tipo: TipoRigaScontrino.articolo);

  final contata = Spesa(
    id: 1,
    stato: StatoSpesa.inCorso,
    iniziataIl: kOra.toUtc(),
    righe: [rigaTastierino(790, nome: 'Mozzarella', id: 10), rigaTastierino(200, nome: 'Pane', id: 11)],
  );

  ScontrinoLetto letto(List<RigaScontrino> righe, {List<bool> giunzioni = const []}) => ScontrinoLetto(
    lettura: LetturaScontrino(righe: righe, totale: Money.sum(righe.map((r) => r.importo)), righeIgnorate: 0),
    giunzioniTrovate: giunzioni,
  );

  Future<SrHarness> apri(WidgetTester tester, ScontrinoLetto l, {bool pro = true}) async {
    final h = await pumpSr(tester, initialLocation: '/', pro: pro, inCorso: contata);
    unawaited(h.router!.push('/scontrino/confronto', extra: l));
    await tester.pumpAndSettle();
    return h;
  }

  testWidgets('differenza da guardare: +1,65 in ambra, prezzo diverso e riga solo sullo scontrino', (tester) async {
    final h = await apri(tester, letto([art('MOZZARELLA', 940), art('PANE', 200), art('SACCHETTO', 15)]));
    expect(find.byKey(const ValueKey('confronto_differenza')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('confronto_delta'))).data, '+1,65');
    expect(find.text('11,55'), findsOneWidget);
    expect(find.text('9,90'), findsOneWidget);
    expect(find.text('cartellino 7,90 · scontrino 9,40'), findsOneWidget);
    expect(find.text('solo sullo scontrino'), findsOneWidget);
    expect(find.text('Righe che tornano (1)'), findsOneWidget);
    // Lo scontrino si e' affiancato alla spesa in corso (per la chiusura e il dettaglio).
    expect(h.repo.scontriniSalvati, [1]);
    expect(h.repo.inCorso!.righeScontrino, hasLength(3));
  });

  testWidgets('tutto torna: card verde, nessuna riga sospetta', (tester) async {
    await apri(tester, letto([art('MOZZARELLA', 790), art('PANE', 200)]));
    expect(find.byKey(const ValueKey('confronto_torna')), findsOneWidget);
    expect(find.text('Tutto torna'), findsOneWidget);
    expect(find.byKey(const ValueKey('confronto_delta')), findsNothing);
  });

  testWidgets('foto unite senza giunzione: l\'avviso lo dice', (tester) async {
    await apri(tester, letto([art('MOZZARELLA', 790), art('PANE', 200)], giunzioni: [false]));
    expect(find.textContaining('Ho unito 2 foto senza trovare il punto di unione'), findsOneWidget);
  });

  testWidgets('Chiudi la spesa porta alla chiusura con la scelta della fonte (scontrino, che quadra)', (tester) async {
    await apri(tester, letto([art('MOZZARELLA', 940), art('PANE', 200)]));
    await tester.tap(find.byKey(const ValueKey('confronto_chiudi')));
    await tester.pumpAndSettle();
    expect(find.text('Quali righe salvare'), findsOneWidget);
    expect(find.byKey(const ValueKey('chiusura_totale')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('chiusura_totale'))).data, '11,40');
  });

  testWidgets('☠ senza Pro, anche con un push diretto, la pagina non si apre: lucchetto', (tester) async {
    await apri(tester, letto([art('PANE', 200)]), pro: false);
    expect(find.text('Questa funzione fa parte di Spending Review Pro.'), findsOneWidget);
    expect(find.byKey(const ValueKey('confronto_chiudi')), findsNothing);
  });
}

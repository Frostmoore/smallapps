import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/domain/lettura/cartellino_parser.dart';
import 'package:spending_review/domain/offerta.dart';
import 'package:spending_review/domain/quantita.dart';
import 'package:spending_review/domain/riga_spesa.dart';
import 'package:spending_review/domain/spesa.dart';
import 'package:spending_review/features/cartellino/conferma_cartellino_sheet.dart';
import 'package:spending_review/features/spesa/azioni_spesa.dart';
import 'package:spending_review/features/spesa/spesa_page.dart';
import 'package:spending_review/services/lettura_service.dart';

import 'sr_test_harness.dart';

/// Il foglio di conferma del cartellino (develop_microapps.md F12.1.12, F12.1.17
/// `conferma_cartellino_test.dart`): ☠ niente si aggiunge senza un tocco; chip alternativi;
/// «Aggiungi (ora 2)»; NxM con quantita' N di default; scelta fra due cartellini; e il doppio
/// prezzo della carta fedelta' con DUE bottoni e nessun default (risposta D4).
void main() {
  setUp(zittisciPiattaforma);

  /// Monta la spesa e fa arrivare [r] come se tornasse dalla fotocamera.
  Future<SrHarness> arriva(WidgetTester tester, RisultatoCartellino r, {Spesa? inCorso}) async {
    final h = await pumpSr(tester, page: const SpesaPage(), inCorso: inCorso);
    // Il giro senza fotocamera: gestisciRisultatoCartellino vuole un WidgetRef, lo prende dalla
    // pagina.
    final stato = tester.state<ConsumerState<SpesaPage>>(find.byType(SpesaPage));
    unawaited(gestisciRisultatoCartellino(stato.context, stato.ref, r));
    await tester.pumpAndSettle();
    return h;
  }

  LettoCartellino uno(PropostaCartellino p) => LettoCartellino(LetturaCartellino([p]));

  testWidgets('☠ niente si aggiunge senza il tocco su Aggiungi', (tester) async {
    final h = await arriva(tester, uno(const PropostaCartellino(nome: 'Pasta', prezzo: Money.cents(249), affidabilita: 0.9)));
    expect(find.byType(ConfermaCartellinoSheet), findsOneWidget);
    expect(h.repo.inCorso, isNull);
    await tester.tap(find.byKey(const ValueKey('conferma_aggiungi')));
    await tester.pumpAndSettle();
    final riga = h.repo.inCorso!.righe.single;
    expect(riga.prezzoUnitario, const Money.cents(249));
    expect(riga.nome, 'Pasta');
    expect(riga.origine, OrigineRiga.cartellino);
  });

  testWidgets('chiudere il foglio senza toccare niente non aggiunge niente', (tester) async {
    final h = await arriva(tester, uno(const PropostaCartellino(nome: 'Pasta', prezzo: Money.cents(249), affidabilita: 0.9)));
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(h.repo.inCorso, isNull);
  });

  testWidgets('affidabilita\' bassa: «Controlla il prezzo» e i chip; un tocco sostituisce il prezzo', (tester) async {
    final h = await arriva(
      tester,
      uno(const PropostaCartellino(nome: 'Latte', prezzo: Money.cents(249), affidabilita: 0.4, alternative: [Money.cents(199)])),
    );
    expect(find.text('Controlla il prezzo'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('conferma_alternativa_199')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('conferma_aggiungi')));
    await tester.pumpAndSettle();
    expect(h.repo.inCorso!.righe.single.prezzoUnitario, const Money.cents(199));
  });

  testWidgets('offerta 3x2: quantita\' 3 di default e la pillola «3x2 · 1,26 cad. se ne prendi 3»', (tester) async {
    final h = await arriva(
      tester,
      uno(const PropostaCartellino(
        nome: 'Biscotti',
        prezzo: Money.cents(189),
        offerta: OffertaNxM(prendi: 3, paghi: 2),
        affidabilita: 0.9,
      )),
    );
    expect(tester.widget<Text>(find.byKey(const ValueKey('conferma_pezzi'))).data, '3');
    expect(find.text('3x2 · 1,26 cad. se ne prendi 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('conferma_aggiungi')));
    await tester.pumpAndSettle();
    expect(h.repo.inCorso!.righe.single.totale, const Money.cents(378));
  });

  testWidgets('prodotto gia\' nella spesa: «Aggiungi (ora 2)» incrementa la riga esistente', (tester) async {
    final gia = Spesa(
      id: 1,
      stato: StatoSpesa.inCorso,
      iniziataIl: kOra.toUtc(),
      righe: [
        const RigaSpesa(id: 10, nome: 'PASTA', quantita: Pezzi(1), prezzoUnitario: Money.cents(249), origine: OrigineRiga.cartellino),
      ],
    );
    final h = await arriva(
      tester,
      uno(const PropostaCartellino(nome: 'Pasta', prezzo: Money.cents(249), affidabilita: 0.9)),
      inCorso: gia,
    );
    expect(find.text('Aggiungi (ora 2)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('conferma_aggiungi')));
    await tester.pumpAndSettle();
    expect(h.repo.inCorso!.righe.single.pezzi, 2);
  });

  testWidgets('due cartellini nella foto: prima «quale?», poi il foglio di quello scelto', (tester) async {
    final h = await arriva(
      tester,
      const LettoCartellino(LetturaCartellino([
        PropostaCartellino(nome: 'Burro', prezzo: Money.cents(219), affidabilita: 0.9),
        PropostaCartellino(nome: 'Panna', prezzo: Money.cents(159), affidabilita: 0.9),
      ])),
    );
    expect(find.text('Ho visto 2 cartellini: quale?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scelta_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('conferma_aggiungi')));
    await tester.pumpAndSettle();
    expect(h.repo.inCorso!.righe.single.nome, 'Panna');
  });

  group('carta fedelta\' (D4): due bottoni, nessun default', () {
    const doppio = PropostaCartellino(
      nome: 'Caffe',
      prezzo: Money.cents(399),
      affidabilita: 0.9,
      carta: DoppioPrezzoCarta(conCarta: Money.cents(399), senzaCarta: Money.cents(499)),
    );

    testWidgets('nessun «Aggiungi» unico: solo «Con la carta» e «Senza la carta»', (tester) async {
      await arriva(tester, uno(doppio));
      expect(find.byKey(const ValueKey('conferma_aggiungi')), findsNothing);
      expect(find.text('Con la carta fedeltà: 3,99'), findsOneWidget);
      expect(find.text('Senza la carta: 4,99'), findsOneWidget);
    });

    testWidgets('con la carta: prezzo con carta e l\'offerta «con carta» sulla riga', (tester) async {
      final h = await arriva(tester, uno(doppio));
      await tester.tap(find.byKey(const ValueKey('conferma_conCarta')));
      await tester.pumpAndSettle();
      final riga = h.repo.inCorso!.righe.single;
      expect(riga.prezzoUnitario, const Money.cents(399));
      expect(riga.offerta, const OffertaPrezzoConCarta(Money.cents(499)));
    });

    testWidgets('senza la carta: prezzo pieno, nessuna offerta', (tester) async {
      final h = await arriva(tester, uno(doppio));
      await tester.tap(find.byKey(const ValueKey('conferma_senzaCarta')));
      await tester.pumpAndSettle();
      final riga = h.repo.inCorso!.righe.single;
      expect(riga.prezzoUnitario, const Money.cents(499));
      expect(riga.offerta, isNull);
    });
  });

  testWidgets('solo il prezzo al kg: si apre il foglio del peso, 500 g di zucchine a 1,48 = 0,74', (tester) async {
    final h = await arriva(
      tester,
      uno(const PropostaCartellino(
        nome: 'Zucchine',
        unitario: PrezzoUnitario(Money.cents(148), UnitaMisura.kg),
        affidabilita: 0.9,
      )),
    );
    for (final c in ['5', '0', '0']) {
      await tester.tap(find.byKey(ValueKey('peso_$c')));
      await tester.pump();
    }
    expect(find.text('0,500 kg × 1,48 = 0,74 €'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('peso_aggiungi')));
    await tester.pumpAndSettle();
    final riga = h.repo.inCorso!.righe.single;
    expect(riga.quantita, const AMisura(500, UnitaMisura.kg));
    expect(riga.totale, const Money.cents(74));
  });

  testWidgets('«Batti a mano» porta il prezzo letto nel display del tastierino', (tester) async {
    await arriva(tester, uno(const PropostaCartellino(nome: 'Pasta', prezzo: Money.cents(249), affidabilita: 0.9)));
    await tester.tap(find.byKey(const ValueKey('conferma_battiAMano')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const ValueKey('display_tastierino'))).data, '2,49');
  });

  testWidgets('OCR assente: un messaggio che manda al tastierino', (tester) async {
    await arriva(tester, const OcrAssente());
    expect(find.text('Su questo telefono non riesco a leggere i cartellini: usa il tastierino'), findsOneWidget);
  });
}

import 'dart:io';

import 'package:camera/camera.dart' show CameraException;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/features/cartellino/conferma_cartellino_sheet.dart';

import '../domain/righe_finte.dart';
import 'sr_test_harness.dart';

/// Il mirino del cartellino con la fotocamera FINTA (develop_microapps.md F12.1.12): scatto →
/// lettura → foglio di conferma sulla spesa; lo scatto sparisce; il permesso negato offre «Apri
/// le impostazioni» e lascia «Da una foto».
void main() {
  setUp(zittisciPiattaforma);

  /// ☠ La lettura cancella la foto con I/O vero, che FakeAsync congela: si lascia passare un po'
  /// di tempo reale prima di aspettare che la pagina si assesti.
  Future<void> attendiLettura(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  final cartellino = [r('PASTA FUSILLI 500 g', 0.08, 0.10, 0.70, 0.08), r('2,49', 0.30, 0.40, 0.40, 0.25)];

  testWidgets('scatto: il foglio di conferma sulla spesa, e lo scatto non resta sul telefono', (tester) async {
    final h = await pumpSr(tester, initialLocation: '/', righeOcr: cartellino);
    await tester.tap(find.byKey(const ValueKey('spesa_cartellino')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('anteprima_finta')), findsOneWidget);
    expect(find.text('Inquadra un cartellino, da vicino'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cartellino_scatta')));
    await attendiLettura(tester);
    expect(find.byType(ConfermaCartellinoSheet), findsOneWidget);
    expect(h.motore.letti, hasLength(1));
    expect(File(h.motore.letti.single).existsSync(), isFalse);
    await tester.tap(find.byKey(const ValueKey('conferma_aggiungi')));
    await tester.pumpAndSettle();
    expect(h.repo.inCorso!.righe.single.prezzoUnitario, const Money.cents(249));
  });

  testWidgets('il suggerimento sullo scritto a mano si vede la prima volta', (tester) async {
    await pumpSr(tester, initialLocation: '/cartellino', righeOcr: cartellino);
    expect(find.byKey(const ValueKey('cartellino_suggerimento')), findsOneWidget);
  });

  testWidgets('dopo il primo scatto il suggerimento non torna', (tester) async {
    await pumpSr(
      tester,
      initialLocation: '/cartellino',
      righeOcr: cartellino,
      settingsValues: {'suggerimento_mirino_visto': true},
    );
    expect(find.byKey(const ValueKey('cartellino_suggerimento')), findsNothing);
  });

  testWidgets("modo Bilancia dalla rotta: si inquadra l'etichetta", (tester) async {
    await pumpSr(tester, initialLocation: '/cartellino?modo=bilancia', righeOcr: cartellino);
    expect(find.text('Inquadra l’etichetta della bilancia, da vicino'), findsOneWidget);
  });

  testWidgets('permesso negato: «Apri le impostazioni» e «Riprova», «Da una foto» resta', (tester) async {
    await pumpSr(
      tester,
      initialLocation: '/cartellino',
      erroreFotocamera: CameraException('CameraAccessDenied', 'negato'),
    );
    expect(find.text('La fotocamera è spenta'), findsOneWidget);
    expect(find.text('Apri le impostazioni'), findsOneWidget);
    expect(find.byKey(const ValueKey('cartellino_daFoto')), findsOneWidget);
  });

  testWidgets('«Da una foto»: la copia temporanea si legge e sparisce', (tester) async {
    final h = await pumpSr(tester, initialLocation: '/', righeOcr: cartellino);
    final copia = File('${h.cartella.path}/galleria.jpg')..writeAsBytesSync([1]);
    h.foto.add(copia.path);
    await tester.tap(find.byKey(const ValueKey('spesa_cartellino')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cartellino_daFoto')));
    await attendiLettura(tester);
    expect(find.byType(ConfermaCartellinoSheet), findsOneWidget);
    expect(copia.existsSync(), isFalse);
  });

  // F12.8: prima l'errore usciva da un `unawaited` (il test falliva con un'eccezione non gestita).
  testWidgets('«Da una foto» con un errore inatteso del motore: messaggio, nessun foglio, copia sparita', (tester) async {
    final h = await pumpSr(tester, initialLocation: '/', righeOcr: cartellino, erroreOcr: StateError('motore rotto'));
    final copia = File('${h.cartella.path}/galleria.jpg')..writeAsBytesSync([1]);
    h.foto.add(copia.path);
    await tester.tap(find.byKey(const ValueKey('spesa_cartellino')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cartellino_daFoto')));
    await attendiLettura(tester);
    expect(find.text('La foto non è riuscita. Riprova.'), findsOneWidget);
    expect(find.byType(ConfermaCartellinoSheet), findsNothing);
    expect(find.byKey(const ValueKey('cartellino_daFoto')), findsOneWidget);
    expect(copia.existsSync(), isFalse);
  });
}

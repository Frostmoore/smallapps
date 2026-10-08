import 'package:film_tracker/features/photos/roll_photos_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_photo_repo.dart';

/// F6.9: la sezione foto del dettaglio del rullino, vuota e piena.
void main() {
  Widget page() => Scaffold(
    body: ListView(padding: const EdgeInsets.all(16), children: const [RollPhotosSection(rollId: 1)]),
  );

  testWidgets('vuota: invito ad aggiungere, niente griglia e niente "Riordina"', (tester) async {
    await pumpWithFakeRepo(tester, page(), roll: testRoll());
    expect(find.text('Foto'), findsOneWidget);
    expect(find.text('Aggiungi'), findsOneWidget);
    expect(find.text('Ancora nessuna foto'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(find.text('Riordina'), findsNothing);
  });

  testWidgets('piena: una miniatura per foto, la copertina segnata, "Riordina"', (tester) async {
    await pumpWithFakeRepo(
      tester,
      page(),
      roll: testRoll(cover: 11),
      images: [testImage(10), testImage(11, order: 1), testImage(12, order: 2)],
    );
    expect(find.text('Ancora nessuna foto'), findsNothing);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.bySemanticsLabel('Foto 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Foto 2, Copertina'), findsOneWidget);
    expect(find.bySemanticsLabel('Foto 3'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.text('Riordina'), findsOneWidget);
  });

  testWidgets('pressione lunga, "Usa come copertina": cambia la copertina', (tester) async {
    final repo = await pumpWithFakeRepo(
      tester,
      page(),
      roll: testRoll(cover: 10),
      images: [testImage(10), testImage(11, order: 1)],
    );
    await tester.longPress(find.bySemanticsLabel('Foto 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usa come copertina'));
    await tester.pumpAndSettle();
    expect(repo.coverCalls, [11]);
    expect(find.bySemanticsLabel('Foto 2, Copertina'), findsOneWidget);
  });

  testWidgets('eliminare la copertina, con conferma, passa la copertina alla foto rimasta', (tester) async {
    final repo = await pumpWithFakeRepo(
      tester,
      page(),
      roll: testRoll(cover: 10),
      images: [testImage(10), testImage(11, order: 1)],
    );
    await tester.longPress(find.bySemanticsLabel('Foto 1, Copertina'));
    await tester.pumpAndSettle();
    // La copertina non offre "Usa come copertina".
    expect(find.text('Usa come copertina'), findsNothing);
    await tester.tap(find.text('Elimina foto'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare questa foto?'), findsOneWidget);
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(repo.images.map((i) => i.id), [11]);
    expect(repo.coverCalls, [11]);
    expect(find.bySemanticsLabel('Foto 1, Copertina'), findsOneWidget);
  });
}

import 'package:film_tracker/domain/roll_status.dart';
import 'package:film_tracker/features/home/home_page.dart';
import 'package:film_tracker/features/rolls/roll_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_roll_repo.dart';

/// F6.8: la home a tre sezioni e i suoi stati vuoti.
void main() {
  testWidgets('senza rullini: un invito solo, non tre sezioni vuote', (tester) async {
    await pumpRollPage(tester, const HomePage());

    expect(find.text('Il tuo primo rullino'), findsOneWidget);
    expect(find.text('Carica un rullino'), findsOneWidget);
    expect(find.text('IN MACCHINA'), findsNothing);
    expect(find.text('Nuovo rullino'), findsOneWidget, reason: 'il FAB c’è sempre');
  });

  testWidgets('le tre sezioni con le loro card', (tester) async {
    await pumpRollPage(
      tester,
      const HomePage(),
      cameras: [om2],
      rolls: [
        roll(1, cameraId: 1),
        roll(2, status: RollStatus.sentForDevelopment, film: 'Kodak Tri-X 400'),
        roll(3, status: RollStatus.sentForDevelopment, film: 'Ilford HP5+'),
        roll(4, status: RollStatus.developed, title: 'Praga', finishedAt: '2026-10-05'),
      ],
      developments: [
        development(2, submittedAt: '2026-10-03'),
        development(3, submittedAt: '2026-09-28', laboratory: 'Fotolab'),
      ],
    );

    expect(find.text('IN MACCHINA'), findsOneWidget);
    expect(find.text('IN LABORATORIO'), findsOneWidget);
    expect(find.text('ARCHIVIO'), findsOneWidget);

    // In macchina: pellicola, macchina, giorni dal caricamento (1 → 8 ottobre).
    expect(find.text('Kodak Portra 400'), findsOneWidget);
    expect(find.textContaining('Olympus OM-2'), findsOneWidget);
    expect(find.textContaining('Caricato 7 giorni fa'), findsOneWidget);

    // In laboratorio: "consegnato N giorni fa", chi aspetta di piu' in cima.
    final hp5 = find.text('Ilford HP5+ — consegnato 10 giorni fa');
    final trix = find.text('Kodak Tri-X 400 — consegnato 5 giorni fa');
    expect(hp5, findsOneWidget);
    expect(trix, findsOneWidget);
    expect(tester.getTopLeft(hp5).dy, lessThan(tester.getTopLeft(trix).dy));
    expect(find.text('Fotolab'), findsOneWidget);

    // Archivio: titolo, numero e periodo; senza foto, la striscia di pellicola.
    expect(find.text('Praga'), findsOneWidget);
    expect(find.textContaining('#4'), findsWidgets);
    expect(find.byType(FilmStripPlaceholder), findsOneWidget);
  });

  testWidgets('sezioni vuote accanto a quelle piene: righe d’invito e segnaposti', (tester) async {
    await pumpRollPage(
      tester,
      const HomePage(),
      rolls: [roll(1, status: RollStatus.sentForDevelopment)],
    );

    expect(find.textContaining('Nessun rullino in macchina'), findsOneWidget);
    expect(
      find.text('Kodak Portra 400 — consegnato'),
      findsOneWidget,
      reason: 'senza data di consegna non si inventano i giorni',
    );
    expect(find.textContaining('Qui finiscono i rullini sviluppati'), findsOneWidget);
    // ⚑ L'archivio vuoto non e' un buco: due strisce di pellicola disegnate.
    expect(find.byType(FilmStripPlaceholder), findsNWidgets(2));
  });

  testWidgets('un rullino terminato dice che va consegnato', (tester) async {
    await pumpRollPage(
      tester,
      const HomePage(),
      rolls: [roll(1, status: RollStatus.exposed, finishedAt: '2026-10-06')],
    );

    expect(find.textContaining('Terminato · da consegnare'), findsOneWidget);
    expect(find.text('Niente in laboratorio, per ora.'), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:trashcan/data/database.dart';
import 'package:trashcan/domain/occurrence_engine.dart';
import 'package:trashcan/domain/recurrence.dart';
import 'package:trashcan/features/exceptions/exceptions_page.dart';

import 'harness.dart';

/// La pagina delle eccezioni deve permettere di **crearne**.
///
/// ☠ Esiste per il 2026-10-06: la pagina elencava le eccezioni ma non aveva modo di
/// aggiungerne, e il proprietario ha chiesto a cosa servisse. Questi test dimostrano il
/// percorso: pulsante Aggiungi, scelta del rifiuto, elenco delle prossime raccolte di quel
/// rifiuto, e la voce per la raccolta straordinaria.
void main() {
  final organic = Harness.type(id: 1, name: 'Organic');
  final paper = Harness.type(id: 2, name: 'Paper', colorValue: 0xFF2E6DA4);

  CalendarBundle conRegole() => CalendarBundle(
    calendar: Harness.calendar(),
    wasteTypes: [organic, paper],
    rules: [
      // L'organico tutti i giorni, cosi' le prossime raccolte ci sono qualunque sia oggi.
      RuleWithExceptions(
        wasteTypeId: 1,
        recurrence: WeeklyRecurrence(
          weekdays: const {1, 2, 3, 4, 5, 6, 7},
          startDate: CivilDate.today().addDays(-7),
        ),
      ),
    ],
  );

  testWidgets('c e un pulsante per aggiungere, anche quando non ci sono eccezioni', (
    tester,
  ) async {
    await Harness.pump(
      tester,
      const ExceptionsPage(),
      bundle: conRegole(),
      body: () async {
        expect(find.text('No exceptions'), findsOneWidget);
        expect(find.widgetWithText(FloatingActionButton, 'Add'), findsOneWidget);
      },
    );
  });

  testWidgets('aggiungi: si sceglie il rifiuto, poi la raccolta o una straordinaria', (
    tester,
  ) async {
    await Harness.pump(
      tester,
      const ExceptionsPage(),
      bundle: conRegole(),
      body: () async {
        await tester.tap(find.widgetWithText(FloatingActionButton, 'Add'));
        await tester.pumpAndSettle();

        // Primo passo: i rifiuti del calendario.
        expect(find.text('Which waste type?'), findsOneWidget);
        expect(find.text('Organic'), findsWidgets);
        expect(find.text('Paper'), findsOneWidget);

        await tester.tap(find.text('Organic').last);
        await tester.pumpAndSettle();

        // Secondo passo: la straordinaria in cima, poi le prossime raccolte dell'organico.
        expect(find.text('Which Organic collection?'), findsOneWidget);
        expect(find.text('Add an extra collection'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsWidgets);
      },
    );
  });

  testWidgets('un rifiuto senza raccolte lo dice, e lascia aggiungere la straordinaria', (
    tester,
  ) async {
    await Harness.pump(
      tester,
      const ExceptionsPage(),
      bundle: conRegole(),
      body: () async {
        await tester.tap(find.widgetWithText(FloatingActionButton, 'Add'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Paper'));
        await tester.pumpAndSettle();

        expect(find.textContaining('No collections in the coming months'), findsOneWidget);
        expect(find.text('Add an extra collection'), findsOneWidget);
      },
    );
  });
}

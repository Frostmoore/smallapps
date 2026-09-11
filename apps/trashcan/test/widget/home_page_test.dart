import 'package:flutter_test/flutter_test.dart';
import 'package:trashcan/features/home/home_page.dart';

import 'harness.dart';

/// La home nei tre stati che contano.
///
/// ⚑ Perché proprio questi tre: il blocco "Stasera" è la ragione per cui l'app esiste, e
/// ha tre comportamenti diversi. Con niente da portare fuori deve dirlo a parole, perché
/// un blocco vuoto si legge come "l'app non ha caricato". Con un tipo deve urlarlo. Con
/// tre deve elencarli tutti in un blocco solo, perché tre card separate rendono meno
/// leggibile proprio il caso in cui l'utente ha più cose da ricordare.
void main() {
  final organic = Harness.type(id: 1, name: 'Organic');
  final paper = Harness.type(id: 2, name: 'Paper', colorValue: 0xFF2E6DA4);
  final glass = Harness.type(id: 3, name: 'Glass', colorValue: 0xFF3B7A6B);

  testWidgets('senza raccolte domani lo dice a parole', (tester) async {
    await Harness.pump(
      tester,
      const HomePage(),
      bundle: Harness.bundleOf([glass]),
      week: [Harness.occurrence(wasteTypeId: 3, inDays: 4)],
      body: () async {
        expect(find.text('TONIGHT'), findsOneWidget);
        expect(find.text('Nothing to take out tonight'), findsOneWidget);
      },
    );
  });

  testWidgets('con un tipo domani lo mostra nel blocco della sera', (tester) async {
    await Harness.pump(
      tester,
      const HomePage(),
      bundle: Harness.bundleOf([organic]),
      tonight: [Harness.occurrence(wasteTypeId: 1, inDays: 1)],
      body: () async {
        expect(find.text('TONIGHT'), findsOneWidget);
        expect(find.text('Organic'), findsOneWidget);
        expect(find.text('Nothing to take out tonight'), findsNothing);
      },
    );
  });

  testWidgets('con tre tipi domani li elenca tutti in un blocco solo', (tester) async {
    await Harness.pump(
      tester,
      const HomePage(),
      bundle: Harness.bundleOf([organic, paper, glass]),
      tonight: [
        Harness.occurrence(wasteTypeId: 1, inDays: 1),
        Harness.occurrence(wasteTypeId: 2, inDays: 1),
        Harness.occurrence(wasteTypeId: 3, inDays: 1),
      ],
      body: () async {
        expect(find.text('TONIGHT'), findsOneWidget, reason: 'un blocco solo, non tre');
        for (final name in ['Organic', 'Paper', 'Glass']) {
          expect(find.text(name), findsOneWidget, reason: '$name deve comparire');
        }
      },
    );
  });

  testWidgets('senza nessun tipo di rifiuto invita ad aggiungerne uno', (tester) async {
    await Harness.pump(
      tester,
      const HomePage(),
      bundle: Harness.bundleOf(const []),
      body: () async {
        // Uno stato vuoto che spiega cosa fare, non una schermata bianca: e' il primo
        // momento in cui un utente decide se l'app serve a qualcosa.
        expect(find.text('No collections scheduled'), findsOneWidget);
      },
    );
  });

  testWidgets('la prossima raccolta dice in quale sera portarla fuori', (tester) async {
    await Harness.pump(
      tester,
      const HomePage(),
      bundle: Harness.bundleOf([organic, glass]),
      tonight: [Harness.occurrence(wasteTypeId: 1, inDays: 1)],
      next: Harness.occurrence(wasteTypeId: 3, inDays: 2),
      body: () async {
        expect(find.text('NEXT COLLECTION'), findsOneWidget);
        // La raccolta e' fra due giorni, quindi si porta fuori domani sera.
        expect(find.textContaining('tomorrow evening'), findsOneWidget);
      },
    );
  });

  testWidgets('il titolo mostra il nome del calendario attivo', (tester) async {
    await Harness.pump(
      tester,
      const HomePage(),
      bundle: Harness.bundleOf([organic], name: 'Seaside'),
      body: () async {
        expect(find.text('Seaside'), findsOneWidget);
      },
    );
  });
}

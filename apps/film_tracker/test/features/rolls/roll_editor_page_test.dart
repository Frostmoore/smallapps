import 'package:film_tracker/features/rolls/roll_editor_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_roll_repo.dart';

/// F6.6: il form del rullino.
void main() {
  testWidgets('modificare un rullino che non esiste lo dice, invece di caricare per sempre', (tester) async {
    // ☠ Trovato con l'atlante (2026-10-08): `_load` non segnava mai la pagina come caricata.
    await pumpRollPage(tester, const RollEditorPage(rollId: 99));

    expect(find.text('Questo rullino non esiste più.'), findsOneWidget);
  });
}

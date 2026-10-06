import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

/// `MicroPrimaryButton` con il tema vero.
///
/// ☠ Esiste per il 2026-10-06: il tema da' ai FilledButton una larghezza minima infinita
/// (`Size.fromHeight(52)`), pensata per i pulsanti a tutta larghezza. Un pulsante non
/// espanso dentro una `Row` non si poteva disegnare ("BoxConstraints forces an infinite
/// width"), e in Full Freezer il foglio d'inserimento rapido restava invisibile sotto lo
/// sfondo scuro: l'app sembrava bloccata. Nessun test se n'era accorto perche' nessuno
/// montava il pulsante con il tema dell'app.
void main() {
  Widget conTema(Widget child) => MaterialApp(
    theme: MicroTheme.light(seed: const Color(0xFF0461E5), fontFamily: 'Roboto'),
    home: Scaffold(body: child),
  );

  testWidgets('non espanso, in una riga accanto a un altro pulsante, si disegna', (tester) async {
    await tester.pumpWidget(
      conTema(
        Row(
          children: [
            TextButton(onPressed: () {}, child: const Text('Altri dettagli')),
            const Spacer(),
            MicroPrimaryButton(label: 'Salva', expanded: false, onPressed: () {}),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Salva'), findsOneWidget);
    // E non si allarga a tutta la riga.
    expect(tester.getSize(find.byType(FilledButton)).width, lessThan(400));
  });

  testWidgets('espanso occupa tutta la larghezza', (tester) async {
    await tester.pumpWidget(conTema(MicroPrimaryButton(label: 'Salva', onPressed: () {})));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FilledButton)).width, 800);
  });
}

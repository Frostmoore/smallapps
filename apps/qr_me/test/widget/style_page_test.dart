import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_me/app/routes.dart';
import 'package:qr_me/data/database.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/domain/qr_style.dart';
import 'package:qr_me/features/style/logo_picker.dart';
import 'package:qr_me/features/style/style_page.dart';
import 'package:qr_me/services/readability_check.dart';

import 'qr_test_harness.dart';

/// F17.1.6, `StylePage`: avvisi di contrasto e verifica di leggibilita'.
void main() {
  StyleArgs args([QrStyle style = QrStyle.plain]) => StyleArgs(
    display: QrDisplayArgs(
      content: const TextContent('ciao'),
      payload: 'ciao',
      source: QrSource.typed,
      style: style,
    ),
  );

  /// ⚑ `pumpAndSettle` non aspetta un `Timer` senza fotogrammi: la pausa di 600 ms va fatta
  /// passare a mano.
  Future<void> afterPause(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
  }

  test('il catalogo delle icone ha esattamente gli id del dominio', () {
    expect(kLogoIcons.keys.toList(), kLogoIconIds);
  });

  testWidgets('nero su bianco: nessun avviso, e la verifica dice leggibile dopo 600 ms', (
    tester,
  ) async {
    final check = FakeReadabilityCheck(Readability.readable);
    await pumpQr(
      tester,
      page: StylePage(args: args()),
      pro: true,
      readability: check,
    );
    await afterPause(tester);
    expect(find.byKey(const ValueKey('warn_contrast')), findsNothing);
    expect(find.byKey(const ValueKey('warn_inverted')), findsNothing);
    expect(find.text('Leggibile'), findsOneWidget);
    expect(check.calls, 1);
  });

  testWidgets('colori troppo simili: avviso rosso di contrasto', (tester) async {
    await pumpQr(
      tester,
      page: StylePage(args: args(const QrStyle(foreground: 0xFFDDDDDD))),
      pro: true,
    );
    expect(find.byKey(const ValueKey('warn_contrast')), findsOneWidget);
    expect(find.textContaining('Colori troppo simili'), findsOneWidget);
  });

  testWidgets('scegliere il primo piano bianco su sfondo bianco fa comparire l\'avviso', (
    tester,
  ) async {
    final check = FakeReadabilityCheck(Readability.readable);
    await pumpQr(
      tester,
      page: StylePage(args: args()),
      pro: true,
      readability: check,
    );
    await afterPause(tester);
    await tester.tap(find.byKey(const ValueKey('fg_ffffffff')));
    await tester.pump();
    expect(find.byKey(const ValueKey('warn_contrast')), findsOneWidget);
    // La verifica riparte solo dopo la pausa.
    expect(find.text('Verifico…'), findsOneWidget);
    await afterPause(tester);
    expect(check.calls, 2);
  });

  testWidgets('chiaro su scuro: avviso giallo di inversione', (tester) async {
    await pumpQr(
      tester,
      page: StylePage(args: args(const QrStyle(foreground: 0xFFFFFFFF, background: 0xFF000000))),
      pro: true,
    );
    expect(find.byKey(const ValueKey('warn_inverted')), findsOneWidget);
    expect(find.byKey(const ValueKey('warn_contrast')), findsNothing);
  });

  testWidgets('scanner assente: "non verificato", non "illeggibile"', (tester) async {
    await pumpQr(
      tester,
      page: StylePage(args: args()),
      pro: true,
      readability: FakeReadabilityCheck(Readability.unknown),
    );
    await afterPause(tester);
    expect(find.text('Non verificato su questo dispositivo'), findsOneWidget);
    expect(find.textContaining('Non riesco a leggerlo'), findsNothing);
  });
}

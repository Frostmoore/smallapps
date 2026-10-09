import 'package:camera/camera.dart' show CameraException;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_me/features/scan/scan_page.dart';

import 'qr_test_harness.dart';

/// `ScanErrorView`: con il permesso negato c'e' sempre la via d'uscita «Apri le impostazioni».
///
/// ☠ Prima, su Android, solo «Riprova»: dopo un rifiuto definitivo il sistema non richiede piu'
/// il permesso e si tornava allo stesso stato vuoto.
void main() {
  Future<({List<String> taps})> mount(WidgetTester tester, Object error) async {
    final taps = <String>[];
    await pumpQr(
      tester,
      page: Scaffold(
        body: ScanErrorView(
          error: error,
          onRetry: () => taps.add('retry'),
          onOpenSettings: () async => taps.add('settings'),
        ),
      ),
    );
    return (taps: taps);
  }

  // ⚑ La vista non dipende dalla piattaforma: «Apri le impostazioni» c'e' su Android come su
  // iOS (prima solo su iOS). Che cosa apra lo decide `AppSettings` (app_settings_test.dart).
  testWidgets('permesso negato: «Apri le impostazioni» e sotto «Riprova»', (tester) async {
    final m = await mount(tester, CameraException('CameraAccessDenied', 'negato'));
    expect(find.text('La fotocamera è spenta per QR Me'), findsOneWidget);
    await tester.tap(find.text('Apri le impostazioni'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan_retry')));
    await tester.pump();
    expect(m.taps, ['settings', 'retry']);
  });

  testWidgets('variante iOS «senza richiesta»: anche quella e\' un permesso negato', (
    tester,
  ) async {
    final m = await mount(tester, CameraException('CameraAccessDeniedWithoutPrompt', 'negato'));
    await tester.tap(find.text('Apri le impostazioni'));
    await tester.pump();
    expect(m.taps, ['settings']);
  });

  testWidgets('nessuna fotocamera: solo «Riprova», niente impostazioni', (tester) async {
    final m = await mount(tester, StateError('nessuna fotocamera'));
    expect(find.text('Apri le impostazioni'), findsNothing);
    expect(find.byKey(const ValueKey('scan_retry')), findsNothing);
    await tester.tap(find.text('Riprova'));
    await tester.pump();
    expect(m.taps, ['retry']);
  });
}

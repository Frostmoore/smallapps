import 'package:film_tracker/app/routes.dart';
import 'package:film_tracker/features/cameras/camera_editor_page.dart';
import 'package:film_tracker/features/cameras/cameras_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import 'fake_film_repo.dart';

/// F6.5: le macchine, e il limite del piano gratuito (una macchina, `secondaryEntities`).
void main() {
  final rotte = <RouteBase>[
    GoRoute(path: Routes.cameras, builder: (_, __) => const CamerasPage()),
    GoRoute(path: Routes.cameraNew, builder: (_, __) => const NewCameraGate()),
    GoRoute(
      path: Routes.cameraEdit,
      builder: (_, s) => CameraEditorPage(cameraId: int.tryParse(s.pathParameters['cameraId'] ?? '')),
    ),
  ];

  testWidgets('l\'elenco mostra macchina, formato e rullini scattati', (tester) async {
    await pumpFilm(
      tester,
      routes: rotte,
      initialLocation: Routes.cameras,
      pro: false,
      cameras: [om2],
      rollCounts: {om2.id: 3},
    );
    expect(find.text('Olympus OM-2'), findsOneWidget);
    expect(find.text('35 mm'), findsOneWidget);
    expect(find.text('3 rullini'), findsOneWidget);
  });

  testWidgets('la prima macchina e\' gratis', (tester) async {
    await pumpFilm(tester, routes: rotte, initialLocation: Routes.cameras, pro: false);
    await tester.tap(find.byKey(const ValueKey('camera_add')));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsNothing);
    expect(find.byType(CameraEditorPage), findsOneWidget);
  });

  testWidgets('la seconda macchina senza Pro apre il paywall', (tester) async {
    await pumpFilm(tester, routes: rotte, initialLocation: Routes.cameras, pro: false, cameras: [om2]);
    await tester.tap(find.byKey(const ValueKey('camera_add')));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);
    expect(find.byType(CameraEditorPage), findsNothing);
  });

  testWidgets('la seconda macchina con il Pro apre il modulo', (tester) async {
    final repo = await pumpFilm(tester, routes: rotte, initialLocation: Routes.cameras, pro: true, cameras: [om2]);
    await tester.tap(find.byKey(const ValueKey('camera_add')));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsNothing);
    expect(find.byType(CameraEditorPage), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('camera_manufacturer')), 'Pentax');
    await tester.enterText(find.byKey(const ValueKey('camera_model')), 'MX');
    await tester.pumpAndSettle();
    await tapSalva(tester);
    expect(repo.cameras.map((c) => '${c.manufacturer} ${c.model}'), ['Olympus OM-2', 'Pentax MX']);
    // Tornati all'elenco, con la macchina nuova.
    expect(find.text('Pentax MX'), findsOneWidget);
  });

  testWidgets('la rotta di creazione, aperta direttamente senza Pro, mostra il lucchetto', (tester) async {
    // Un deep link o una pagina futura che fa `push` senza passare dal paywall.
    await pumpFilm(tester, routes: rotte, initialLocation: Routes.cameraNew, pro: false, cameras: [om2]);
    expect(find.byType(CameraEditorPage), findsNothing);
    expect(find.text('Questa funzione fa parte di Film Tracker Pro.'), findsOneWidget);
  });

  testWidgets('eliminare avvisa che i rullini restano senza macchina', (tester) async {
    final repo = await pumpFilm(
      tester,
      routes: rotte,
      initialLocation: Routes.cameraEditOf(om2.id),
      pro: false,
      cameras: [om2],
      rollCounts: {om2.id: 4},
    );
    await tester.tap(find.byTooltip('Elimina'));
    await tester.pumpAndSettle();
    expect(find.text('I 4 rullini scattati con questa macchina restano, senza macchina.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
    await tester.pumpAndSettle();
    expect(repo.cameras, isEmpty);
  });
}

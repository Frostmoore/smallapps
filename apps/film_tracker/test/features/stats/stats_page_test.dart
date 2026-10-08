import 'dart:io';

import 'package:film_tracker/app/entitlement.dart';
import 'package:film_tracker/app/feature_limits.dart';
import 'package:film_tracker/app/providers.dart';
import 'package:film_tracker/data/database.dart';
import 'package:film_tracker/data/film_repository.dart';
import 'package:film_tracker/domain/film_stats.dart';
import 'package:film_tracker/features/settings/data_section.dart';
import 'package:film_tracker/features/stats/stats_page.dart';
import 'package:film_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

import '../laboratorio/fake_film_repo.dart' show FakeEntitlementNotifier, om2, oggi;

/// Un repository finto che conosce solo cio' che servono le statistiche: gli ingressi del
/// calcolo e le macchine.
///
/// ☠ Finto e non Drift su `AppDatabase.memory()`: dentro `testWidgets` FakeAsync congela l'I/O
/// di SQLite e gli stream non arrivano mai (vedi `test/features/laboratorio/fake_film_repo.dart`).
class FakeStatsRepository extends FilmRepository {
  FakeStatsRepository(super.db, {required this.rolls, this.cameras = const []});

  final List<StatsRoll> rolls;
  final List<Camera> cameras;

  @override
  Stream<List<StatsRoll>> watchStatsRolls() => Stream.value(rolls);

  @override
  Future<List<StatsRoll>> statsRolls() async => rolls;

  @override
  Stream<List<Camera>> watchCameras({bool activeOnly = false}) => Stream.value(cameras);
}

/// Il dataset noto: tre rullini nel 2026 (due a gennaio, uno a marzo), uno nel 2025.
///
/// 2026: fotogrammi 36 + 36 + 12 = 84. Pellicola 15,90 + 12,00 = 27,90; sviluppo 9,00; scansioni
/// 5,00; stampe 6,00 + 4,00 = 10,00; totale 51,90. Rullini con costi: 2 (il terzo non ne ha),
/// fotogrammi con costi 72 -> media per rullino 25,95, per fotogramma 5190/72 = 72,08 cent ≈ 0,72.
final List<StatsRoll> dataset = [
  StatsRoll(
    date: CivilDate(2026, 1, 5),
    frames: 36,
    filmName: 'Kodak Portra 400',
    cameraId: 1,
    costCents: 1590,
    development: const StatsDevelopment(laboratory: 'Fotoservice', developmentCostCents: 900, scanCostCents: 500),
    prints: const [StatsPrint(laboratory: 'Fotoservice', costCents: 600), StatsPrint(laboratory: 'Lab Roma', costCents: 400)],
  ),
  StatsRoll(date: CivilDate(2026, 1, 20), frames: 36, filmName: 'Kodak Portra 400', cameraId: 1, costCents: 1200),
  StatsRoll(
    date: CivilDate(2026, 3, 2),
    frames: 12,
    filmName: 'Ilford HP5 Plus',
    development: const StatsDevelopment(selfDeveloped: true),
  ),
  StatsRoll(date: CivilDate(2025, 11, 1), frames: 24, filmName: 'Fomapan 100', costCents: 700),
];

Future<void> pumpStats(WidgetTester tester, {required bool pro, Widget page = const StatsPage()}) async {
  final db = AppDatabase.memory();
  final repo = FakeStatsRepository(db, rolls: dataset, cameras: [om2]);
  const sku = 'filmtracker_pro_lifetime';
  final service = EntitlementService(
    appId: 'filmtracker',
    proSku: sku,
    gateway: FakePurchaseGateway.withProduct(sku, formattedPrice: '4,99 €'),
    store: EntitlementStore(file: File('${Directory.systemTemp.path}/film_tracker_test_entitlement_stats.json')),
    installId: InstallId.fixed('00000000-0000-0000-0000-000000000000'),
  );
  addTearDown(() async {
    service.dispose();
    await db.close();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        todayProvider.overrideWithValue(oggi),
        featureGateProvider.overrideWithValue(FeatureGate(limits: filmFeatureLimits, isPro: pro)),
        entitlementProvider.overrideWith(() => FakeEntitlementNotifier(service)),
      ],
      child: MaterialApp(
        locale: const Locale('it'),
        supportedLocales: const [Locale('it'), Locale('en')],
        localizationsDelegates: const [
          L.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: MicroTheme.dark(seed: const Color(0xFFE0A458), fontFamily: 'Inter', variant: DynamicSchemeVariant.fidelity),
        home: Scaffold(body: page),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Un importo come lo scrive `formatCents` in italiano: lo spazio prima di € e' indivisibile.
String eur(String amount) => '$amount\u00A0€';

/// Il testo di un widget con chiave, ovunque stia sotto di esso.
bool hasText(Key key, String text) =>
    find.descendant(of: find.byKey(key), matching: find.text(text)).evaluate().isNotEmpty;

void main() {
  testWidgets('senza Pro la pagina mostra il lucchetto e nessun numero', (tester) async {
    await pumpStats(tester, pro: false);
    expect(find.text('Questa funzione fa parte di Film Tracker Pro.'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byKey(const ValueKey('stats_rolls')), findsNothing);
  });

  testWidgets('con il Pro mostra i numeri dell\'anno piu\' recente', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpStats(tester, pro: true);

    expect(find.byKey(const ValueKey('stats_year_2026')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats_year_2025')), findsOneWidget);
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('stats_year_2026'))).selected, isTrue);

    expect(hasText(const ValueKey('stats_rolls'), '3'), isTrue);
    expect(hasText(const ValueKey('stats_frames'), '84'), isTrue);
    expect(find.text(eur('27,90')), findsOneWidget, reason: 'pellicola');
    expect(find.text(eur('9,00')), findsOneWidget, reason: 'sviluppo');
    expect(find.text(eur('5,00')), findsOneWidget, reason: 'scansioni');
    expect(find.text(eur('10,00')), findsOneWidget, reason: 'stampe');
    expect(hasText(const ValueKey('stats_total'), eur('51,90')), isTrue);
    expect(hasText(const ValueKey('stats_perRoll'), eur('25,95')), isTrue);
    expect(hasText(const ValueKey('stats_perRoll'), 'sui 2 rullini con costi'), isTrue);

    // ☠ F6.10: il costo per fotogramma e' dichiarato come stima, nel titolo, nel valore e
    // nella spiegazione.
    // (MicroStatTile scrive l'etichetta in maiuscolo.)
    expect(hasText(const ValueKey('stats_perFrame'), 'COSTO PER FOTOGRAMMA (STIMA)'), isTrue);
    expect(hasText(const ValueKey('stats_perFrame'), eur('≈ 0,72')), isTrue);
    expect(find.textContaining('Una stima sui fotogrammi nominali'), findsOneWidget);

    expect(hasText(const ValueKey('stats_topEmulsion'), 'Kodak Portra 400'), isTrue);
    expect(hasText(const ValueKey('stats_topEmulsion'), 'Emulsione · 2 rullini'), isTrue);
    expect(hasText(const ValueKey('stats_topCamera'), 'Olympus OM-2'), isTrue);
    expect(hasText(const ValueKey('stats_topLab'), 'Fotoservice'), isTrue);
    expect(hasText(const ValueKey('stats_topLab'), 'Laboratorio · 2 volte'), isTrue);
    expect(find.text('1 rullino sviluppato in casa'), findsOneWidget);

    // Il grafico: dodici mesi, gennaio 2 e marzo 1 per i lettori di schermo.
    final chart = tester.widget<MonthlyRollsChart>(find.byType(MonthlyRollsChart));
    expect(chart.rollsPerMonth, [2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
    final semantics = tester.widget<Semantics>(
      find.descendant(of: find.byType(MonthlyRollsChart), matching: find.byType(Semantics)).first,
    );
    expect(semantics.properties.label, startsWith('gen 2, feb 0, mar 1'));
  });

  testWidgets('scegliendo un altro anno i numeri cambiano', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpStats(tester, pro: true);

    await tester.tap(find.byKey(const ValueKey('stats_year_2025')));
    await tester.pumpAndSettle();
    expect(hasText(const ValueKey('stats_rolls'), '1'), isTrue);
    expect(hasText(const ValueKey('stats_frames'), '24'), isTrue);
    expect(hasText(const ValueKey('stats_total'), eur('7,00')), isTrue);
    expect(hasText(const ValueKey('stats_topLab'), 'Nessuno, per ora'), isTrue);
  });

  testWidgets('"I tuoi dati" senza Pro: badge sulle quattro voci Pro, non sul ripristino; '
      'le voci Pro aprono il paywall', (tester) async {
    await pumpStats(tester, pro: false, page: const SingleChildScrollView(child: DataSection()));
    for (final k in ['data_stats', 'data_report', 'data_csv', 'data_backup']) {
      expect(find.descendant(of: find.byKey(ValueKey(k)), matching: find.byType(ProBadge)), findsOneWidget, reason: k);
    }
    expect(find.descendant(of: find.byKey(const ValueKey('data_restore')), matching: find.byType(ProBadge)), findsNothing);

    await tester.tap(find.byKey(const ValueKey('data_csv')));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);
  });
}

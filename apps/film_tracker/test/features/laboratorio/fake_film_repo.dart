import 'dart:async';
import 'dart:io';

import 'package:film_tracker/app/entitlement.dart';
import 'package:film_tracker/app/feature_limits.dart';
import 'package:film_tracker/app/providers.dart';
import 'package:film_tracker/data/database.dart';
import 'package:film_tracker/data/film_repository.dart';
import 'package:film_tracker/domain/film_types.dart';
import 'package:film_tracker/domain/roll_status.dart';
import 'package:film_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

/// Un repository in memoria per i test di widget di sviluppo, stampe, macchine e pellicole.
///
/// ☠ Finto e non Drift su `AppDatabase.memory()`: dentro `testWidgets` FakeAsync congela
/// l'I/O di SQLite e gli stream non arrivano mai (lezione di TrashCan, ripetuta in Scorte
/// Calore `test/features/history/fake_repo.dart`). Le regole vere del repository le prova
/// `test/data/film_repository_test.dart`; qui conta la pagina. Le poche regole che le pagine
/// devono vedere (doppione di pellicola, transizioni di stato, stato suggerito) sono rifatte
/// qui con la stessa `RollStatusMachine` del codice vero.
class FakeFilmRepository extends FilmRepository {
  FakeFilmRepository(
    super.db, {
    List<FilmRoll>? rolls,
    List<Camera>? cameras,
    List<FilmStock>? stocks,
    List<Development>? developments,
    List<PrintOrder>? prints,
    Map<int, int>? rollCounts,
  }) : rolls = {for (final r in rolls ?? const <FilmRoll>[]) r.id: r},
       cameras = [...?cameras],
       stocks = [...?stocks],
       developments = {for (final d in developments ?? const <Development>[]) d.filmRollId: d},
       prints = [...?prints],
       rollCounts = {...?rollCounts};

  final Map<int, FilmRoll> rolls;
  final List<Camera> cameras;
  final List<FilmStock> stocks;

  /// Per id del rullino: uno sviluppo al massimo.
  final Map<int, Development> developments;
  final List<PrintOrder> prints;
  final Map<int, int> rollCounts;

  final _changes = StreamController<void>.broadcast();
  var _nextId = 1000;
  static const _machine = RollStatusMachine();

  void _emit() => _changes.add(null);

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  Future<void> dispose() => _changes.close();

  // ── Macchine ──

  @override
  Stream<List<Camera>> watchCameras({bool activeOnly = false}) =>
      _watch(() => [for (final c in cameras) if (!activeOnly || c.active) c]);

  @override
  Future<int> cameraCount() async => cameras.length;

  @override
  Stream<int> watchCameraCount() => _watch(() => cameras.length);

  @override
  Stream<Map<int, int>> watchRollCountByCamera() => _watch(() => Map.of(rollCounts));

  @override
  Future<Map<int, int>> rollCountByCamera() async => Map.of(rollCounts);

  @override
  Future<Camera?> cameraById(int id) async => cameras.where((c) => c.id == id).firstOrNull;

  @override
  Future<int> addCamera({required String manufacturer, required String model, required FilmFormat format, String? note}) async {
    final id = _nextId++;
    cameras.add(
      Camera(
        id: id,
        manufacturer: manufacturer.trim(),
        model: model.trim(),
        format: format.key,
        note: note,
        active: true,
        sortOrder: cameras.length,
      ),
    );
    _emit();
    return id;
  }

  @override
  Future<void> updateCamera(Camera camera) async {
    cameras[cameras.indexWhere((c) => c.id == camera.id)] = camera;
    _emit();
  }

  @override
  Future<void> deleteCamera(int id) async {
    cameras.removeWhere((c) => c.id == id);
    _emit();
  }

  // ── Pellicole ──

  @override
  Stream<List<FilmStock>> watchStocks() => _watch(() => List.of(stocks));

  @override
  Future<FilmStock?> stockById(int id) async => stocks.where((s) => s.id == id).firstOrNull;

  void _requireNoDuplicate(String brand, String name, String format, {int? exceptId}) {
    for (final s in stocks) {
      if (s.id != exceptId &&
          s.format == format &&
          s.brand.toLowerCase() == brand.trim().toLowerCase() &&
          s.name.toLowerCase() == name.trim().toLowerCase()) {
        throw DuplicateFilmStockException(s.id);
      }
    }
  }

  @override
  Future<int> addCustomStock({
    required String brand,
    required String name,
    required int iso,
    required FilmProcess process,
    required FilmFormat format,
  }) async {
    _requireNoDuplicate(brand, name, format.key);
    final id = _nextId++;
    stocks.add(
      FilmStock(
        id: id,
        brand: brand.trim(),
        name: name.trim(),
        iso: iso,
        process: process.key,
        format: format.key,
        isCustom: true,
      ),
    );
    _emit();
    return id;
  }

  @override
  Future<void> updateCustomStock(FilmStock stock) async {
    _requireNoDuplicate(stock.brand, stock.name, stock.format, exceptId: stock.id);
    stocks[stocks.indexWhere((s) => s.id == stock.id)] = stock;
    _emit();
  }

  @override
  Future<void> deleteCustomStock(int id) async {
    stocks.removeWhere((s) => s.id == id);
    _emit();
  }

  // ── Rullini e stato ──

  @override
  Future<FilmRoll?> rollById(int id) async => rolls[id];

  @override
  Stream<FilmRoll?> watchRoll(int id) => _watch(() => rolls[id]);

  @override
  Future<void> setRollStatus(int id, RollStatus to, {bool force = false}) async {
    final roll = rolls[id];
    if (roll == null) throw StateError('Rullino $id inesistente');
    final from = roll.statusEnum;
    if (from == to) return;
    if (!force && !_machine.canTransition(from, to)) throw RollTransitionException(from, to);
    rolls[id] = roll.copyWith(status: to.key);
    _emit();
  }

  @override
  Future<RollStatus?> suggestedStatus(int rollId) async {
    final roll = rolls[rollId];
    if (roll == null) return null;
    return _machine.suggestFrom(
      current: roll.statusEnum,
      finishedAt: roll.finishedDate,
      development: developments[rollId]?.toLabEvent(),
      prints: [for (final p in prints) if (p.filmRollId == rollId) p.toLabEvent()],
    );
  }

  // ── Sviluppo ──

  @override
  Future<Development?> developmentFor(int rollId) async => developments[rollId];

  @override
  Stream<Development?> watchDevelopment(int rollId) => _watch(() => developments[rollId]);

  @override
  Future<int> saveDevelopment({
    required int rollId,
    String? laboratory,
    CivilDate? submittedAt,
    CivilDate? returnedAt,
    int? developmentCostCents,
    int? scanCostCents,
    FilmProcess? process,
    bool selfDeveloped = false,
    String? note,
  }) async {
    final id = developments[rollId]?.id ?? _nextId++;
    String? vuoto(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
    developments[rollId] = Development(
      id: id,
      filmRollId: rollId,
      laboratory: vuoto(laboratory),
      submittedAt: submittedAt?.toIso(),
      returnedAt: returnedAt?.toIso(),
      developmentCostCents: developmentCostCents,
      scanCostCents: scanCostCents,
      process: process?.key,
      selfDeveloped: selfDeveloped,
      note: vuoto(note),
    );
    _emit();
    return id;
  }

  @override
  Future<void> deleteDevelopment(int rollId) async {
    developments.remove(rollId);
    _emit();
  }

  // ── Stampe ──

  @override
  Future<List<PrintOrder>> printsFor(int rollId) async => [for (final p in prints) if (p.filmRollId == rollId) p];

  @override
  Stream<List<PrintOrder>> watchPrints(int rollId) => _watch(() => [for (final p in prints) if (p.filmRollId == rollId) p]);

  @override
  Future<PrintOrder?> printById(int id) async => prints.where((p) => p.id == id).firstOrNull;

  @override
  Future<int> addPrintOrder({
    required int rollId,
    String? laboratory,
    CivilDate? submittedAt,
    CivilDate? returnedAt,
    String? format,
    int? numberOfPrints,
    int? costCents,
    String? note,
  }) async {
    final id = _nextId++;
    prints.add(
      PrintOrder(
        id: id,
        filmRollId: rollId,
        laboratory: laboratory,
        submittedAt: submittedAt?.toIso(),
        returnedAt: returnedAt?.toIso(),
        format: format,
        numberOfPrints: numberOfPrints,
        costCents: costCents,
        note: note,
      ),
    );
    _emit();
    return id;
  }

  @override
  Future<void> updatePrintOrder(PrintOrder order) async {
    prints[prints.indexWhere((p) => p.id == order.id)] = order;
    _emit();
  }

  @override
  Future<void> deletePrintOrder(int id) async {
    prints.removeWhere((p) => p.id == id);
    _emit();
  }

  @override
  Stream<List<String>> watchLaboratories() => _watch(() {
    final seen = <String>{};
    return [
      for (final l in [...developments.values.map((d) => d.laboratory), ...prints.map((p) => p.laboratory)])
        if (l != null && seen.add(l.toLowerCase())) l,
    ];
  });
}

/// Un `EntitlementNotifier` che non legge configurazione, percorsi e id d'installazione: il
/// paywall vero si apre con un servizio dal gateway finto, senza store e senza disco.
class FakeEntitlementNotifier extends EntitlementNotifier {
  FakeEntitlementNotifier(this._fake);

  final EntitlementService _fake;

  @override
  EntitlementService get service => _fake;

  @override
  EntitlementView build() => EntitlementView(entitlement: _fake.current, busy: false, storeAvailable: true);
}

// ── Righe di prova ──

FilmRoll rullino(int id, {RollStatus status = RollStatus.exposed, int? stockId}) => FilmRoll(
  id: id,
  sequenceNumber: id,
  filmStockId: stockId,
  filmName: 'Kodak Portra 400',
  format: '35mm',
  nominalIso: 400,
  exposedIso: 400,
  loadedAt: '2026-09-01',
  finishedAt: status == RollStatus.loaded ? null : '2026-09-20',
  frames: 36,
  status: status.key,
  createdAt: 0,
);

const FilmStock portra400 = FilmStock(
  id: 5,
  brand: 'Kodak',
  name: 'Portra 400',
  iso: 400,
  process: 'C-41',
  format: '35mm',
  isCustom: false,
);

const FilmStock hp5 = FilmStock(id: 6, brand: 'Ilford', name: 'HP5+', iso: 400, process: 'BW', format: '35mm', isCustom: false);

/// Una pellicola personalizzata.
const FilmStock miaPellicola = FilmStock(
  id: 7,
  brand: 'Kodak',
  name: 'Vision3 250D',
  iso: 250,
  process: 'ECN-2',
  format: '35mm',
  isCustom: true,
);

const Camera om2 = Camera(id: 1, manufacturer: 'Olympus', model: 'OM-2', format: '35mm', active: true, sortOrder: 0);

/// "Oggi" nei test.
final CivilDate oggi = CivilDate(2026, 10, 8);

/// Monta l'app in italiano, scura come quella vera, con il repository finto, "oggi" fisso e il
/// Pro scelto. Con [routes] usa un `GoRouter` (le pagine che fanno `context.push`), altrimenti
/// mostra [page].
Future<FakeFilmRepository> pumpFilm(
  WidgetTester tester, {
  Widget? page,
  List<RouteBase>? routes,
  String? initialLocation,
  required bool pro,
  List<FilmRoll>? rolls,
  List<Camera>? cameras,
  List<FilmStock>? stocks,
  List<Development>? developments,
  Map<int, int>? rollCounts,
}) async {
  assert((page == null) != (routes == null), 'o una pagina o le rotte');
  final db = AppDatabase.memory();
  final repo = FakeFilmRepository(
    db,
    rolls: rolls,
    cameras: cameras,
    stocks: stocks,
    developments: developments,
    rollCounts: rollCounts,
  );
  const sku = 'filmtracker_pro_lifetime';
  final service = EntitlementService(
    appId: 'filmtracker',
    proSku: sku,
    gateway: FakePurchaseGateway.withProduct(sku, formattedPrice: '4,99 €'),
    store: EntitlementStore(file: File('${Directory.systemTemp.path}/film_tracker_test_entitlement.json')),
    installId: InstallId.fixed('00000000-0000-0000-0000-000000000000'),
  );
  addTearDown(() async {
    service.dispose();
    await repo.dispose();
    await db.close();
  });
  final theme = MicroTheme.dark(seed: const Color(0xFFE0A458), fontFamily: 'Inter', variant: DynamicSchemeVariant.fidelity);
  const delegates = [
    L.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  const locales = [Locale('it'), Locale('en')];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        todayProvider.overrideWithValue(oggi),
        featureGateProvider.overrideWithValue(FeatureGate(limits: filmFeatureLimits, isPro: pro)),
        entitlementProvider.overrideWith(() => FakeEntitlementNotifier(service)),
      ],
      child: routes != null
          ? MaterialApp.router(
              locale: const Locale('it'),
              supportedLocales: locales,
              localizationsDelegates: delegates,
              theme: theme,
              routerConfig: GoRouter(initialLocation: initialLocation, routes: routes),
            )
          : MaterialApp(
              locale: const Locale('it'),
              supportedLocales: locales,
              localizationsDelegates: delegates,
              theme: theme,
              home: page,
            ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// Scorre il modulo fino a "Salva" e lo tocca.
///
/// ⚑ `scrollUntilVisible` e non `ensureVisible`: i moduli sono `ListView`, che costruisce
/// solo le righe visibili, e il pulsante in fondo non esiste finche' non ci si arriva.
Future<void> tapSalva(WidgetTester tester) async {
  final lista = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(find.text('Salva'), 200, scrollable: lista);
  // scrollUntilVisible si ferma appena il pulsante esiste, anche se e' ancora sul bordo.
  await tester.ensureVisible(find.text('Salva'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Salva'));
  await tester.pumpAndSettle();
}

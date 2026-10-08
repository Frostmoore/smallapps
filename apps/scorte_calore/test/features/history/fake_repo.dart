import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:scorte_calore/app/entitlement.dart';
import 'package:scorte_calore/app/feature_limits.dart';
import 'package:scorte_calore/app/providers.dart';
import 'package:scorte_calore/app/scorte_palette.dart';
import 'package:scorte_calore/data/database.dart';
import 'package:scorte_calore/data/scorte_repository.dart';
import 'package:scorte_calore/domain/fuel_source.dart';
import 'package:scorte_calore/l10n/generated/app_localizations.dart';

/// Un repository in memoria per i test di widget di storico e acquisti.
///
/// ☠ Finto e non Drift su `AppDatabase.memory()`: dentro `testWidgets` FakeAsync congela
/// l'I/O di SQLite e gli stream non arrivano mai (lezione di TrashCan, ripetuta in Full
/// Freezer `test/widget/quick_add_test.dart`). Che le scritture vere funzionino lo dimostra
/// `test/data/scorte_repository_test.dart`; qui conta la pagina.
class FakeScorteRepository extends ScorteRepository {
  FakeScorteRepository(super.db, {required this.source, List<StockMeasurement>? misure, List<Purchase>? acquisti})
    : misure = [...?misure],
      acquisti = [...?acquisti];

  final FuelSource source;
  final List<StockMeasurement> misure;
  final List<Purchase> acquisti;
  final _m = StreamController<List<StockMeasurement>>.broadcast();
  final _p = StreamController<List<Purchase>>.broadcast();
  var _nextId = 1000;

  void _emitM() {
    misure.sort((a, b) => a.date.compareTo(b.date));
    _m.add(List.of(misure));
  }

  void _emitP() {
    acquisti.sort((a, b) => b.date.compareTo(a.date));
    _p.add(List.of(acquisti));
  }

  @override
  Stream<FuelSource?> watchSource(int id) => Stream.value(id == source.id ? source : null);

  @override
  Stream<List<FuelSource>> watchSources({bool activeOnly = false}) => Stream.value([source]);

  @override
  Stream<List<StockMeasurement>> watchMeasurements(int sourceId, {CivilDate? since}) async* {
    misure.sort((a, b) => a.date.compareTo(b.date));
    yield List.of(misure);
    yield* _m.stream;
  }

  @override
  Future<void> deleteMeasurement(int id) async {
    misure.removeWhere((m) => m.id == id);
    _emitM();
  }

  @override
  Future<int> upsertMeasurement(int sourceId, Measurement m, {String? note}) async {
    misure.removeWhere((r) => r.date == m.date.toIso());
    final id = _nextId++;
    misure.add(
      StockMeasurement(
        id: id,
        fuelSourceId: sourceId,
        date: m.date.toIso(),
        quantity: m.quantity,
        enteredAs: m.enteredAs.key,
        rawInput: m.rawInput,
        note: note,
      ),
    );
    _emitM();
    return id;
  }

  @override
  Stream<List<Purchase>> watchPurchases({int? sourceId}) async* {
    acquisti.sort((a, b) => b.date.compareTo(a.date));
    yield List.of(acquisti);
    yield* _p.stream;
  }

  @override
  Future<int> addPurchase({
    required int sourceId,
    required CivilDate date,
    required double quantity,
    int? totalCostCents,
    String? supplier,
    String? note,
  }) async {
    final id = _nextId++;
    String? vuoto(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
    acquisti.add(
      Purchase(
        id: id,
        fuelSourceId: sourceId,
        date: date.toIso(),
        quantity: quantity,
        totalCostCents: totalCostCents,
        supplier: vuoto(supplier),
        note: vuoto(note),
      ),
    );
    _emitP();
    return id;
  }

  @override
  Future<void> updatePurchase(Purchase purchase) async {
    acquisti
      ..removeWhere((p) => p.id == purchase.id)
      ..add(purchase);
    _emitP();
  }

  @override
  Future<void> deletePurchase(int id) async {
    acquisti.removeWhere((p) => p.id == id);
    _emitP();
  }

  Future<void> dispose() async {
    await _m.close();
    await _p.close();
  }
}

const FuelSource stufa = FuelSource(
  id: 1,
  name: 'Stufa',
  fuelType: 'pellet',
  unit: 'bags',
  usableFraction: 1,
  warningDays: 7,
  active: true,
  sortOrder: 0,
  createdAt: 0,
);

StockMeasurement misura(int id, String iso, double q) => StockMeasurement(
  id: id,
  fuelSourceId: 1,
  date: iso,
  quantity: q,
  enteredAs: 'absolute',
  rawInput: q,
);

/// Monta [page] in italiano con il repository finto, "oggi" fisso e il Pro scelto.
Future<FakeScorteRepository> pumpPage(
  WidgetTester tester,
  Widget page, {
  required bool pro,
  List<StockMeasurement>? misure,
  List<Purchase>? acquisti,
  CivilDate? today,
}) async {
  final db = AppDatabase.memory();
  final repo = FakeScorteRepository(db, source: stufa, misure: misure, acquisti: acquisti);
  addTearDown(() async {
    await repo.dispose();
    await db.close();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        todayProvider.overrideWithValue(today ?? CivilDate(2026, 10, 8)),
        featureGateProvider.overrideWithValue(FeatureGate(limits: scorteFeatureLimits, isPro: pro)),
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
        theme: withScorteLook(ThemeData(), ScortePalette.light),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

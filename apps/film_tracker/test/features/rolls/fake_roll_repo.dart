import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:film_tracker/app/providers.dart';
import 'package:film_tracker/data/database.dart';
import 'package:film_tracker/data/film_repository.dart';
import 'package:film_tracker/domain/roll_status.dart';
import 'package:film_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

/// Un repository in memoria per i test di widget della home e del dettaglio del rullino.
///
/// ☠ Finto e non Drift su `AppDatabase.memory()`: dentro `testWidgets` FakeAsync congela l'I/O
/// di SQLite e gli stream non arrivano mai (lezione di TrashCan, ripetuta in Scorte Calore
/// `test/features/history/fake_repo.dart`). Le regole vere (transizioni, `markFinished`) le
/// prova `test/data/film_repository_test.dart`; qui contano le pagine.
class FakeRollRepository extends FilmRepository {
  FakeRollRepository(
    super.db, {
    List<FilmRoll>? rolls,
    List<Camera>? cameras,
    List<Development>? developments,
    List<PrintOrder>? prints,
  }) : rolls = [...?rolls],
       cameras = [...?cameras],
       developments = [...?developments],
       prints = [...?prints];

  final List<FilmRoll> rolls;
  final List<Camera> cameras;
  final List<Development> developments;
  final List<PrintOrder> prints;
  final _changes = StreamController<void>.broadcast();

  /// Le chiamate ricevute, per le verifiche.
  final List<(int, CivilDate)> finishedCalls = [];
  final List<(int, RollStatus, bool)> statusCalls = [];

  /// Il valore subito, poi un valore nuovo a ogni modifica.
  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  void _replace(FilmRoll r) {
    rolls[rolls.indexWhere((x) => x.id == r.id)] = r;
    _changes.add(null);
  }

  @override
  Stream<List<RollListItem>> watchRollItems({RollSection? section}) => _watch(() {
    final list = [
      for (final r in rolls)
        if (section == null || r.section == section)
          RollListItem(
            roll: r,
            camera: cameras.where((c) => c.id == r.cameraId).firstOrNull,
            development: developments.where((d) => d.filmRollId == r.id).firstOrNull,
            prints: [
              for (final p in prints)
                if (p.filmRollId == r.id) p,
            ],
          ),
    ]..sort((a, b) => b.roll.sequenceNumber.compareTo(a.roll.sequenceNumber));
    return list;
  });

  @override
  Stream<FilmRoll?> watchRoll(int id) => _watch(() => rolls.where((r) => r.id == id).firstOrNull);

  @override
  Stream<Development?> watchDevelopment(int rollId) =>
      _watch(() => developments.where((d) => d.filmRollId == rollId).firstOrNull);

  @override
  Stream<List<PrintOrder>> watchPrints(int rollId) => _watch(
    () => [
      for (final p in prints)
        if (p.filmRollId == rollId) p,
    ],
  );

  @override
  Stream<List<RollImage>> watchImages(int rollId) => _watch(() => const <RollImage>[]);

  @override
  Stream<List<Camera>> watchCameras({bool activeOnly = false}) => _watch(() => List.of(cameras));

  @override
  Future<void> markFinished(int id, CivilDate date) async {
    finishedCalls.add((id, date));
    final r = rolls.firstWhere((x) => x.id == id);
    _replace(
      r.copyWith(
        finishedAt: Value(date.toIso()),
        status: r.statusEnum == RollStatus.loaded ? RollStatus.exposed.key : null,
      ),
    );
  }

  @override
  Future<void> setRollStatus(int id, RollStatus to, {bool force = false}) async {
    statusCalls.add((id, to, force));
    _replace(rolls.firstWhere((x) => x.id == id).copyWith(status: to.key));
  }

  Future<void> dispose() => _changes.close();
}

/// Un rullino di prova: Portra 400, 36 pose, caricato il 1° ottobre 2026.
FilmRoll roll(
  int id, {
  RollStatus status = RollStatus.loaded,
  String film = 'Kodak Portra 400',
  String? title,
  int? cameraId,
  String? loadedAt = '2026-10-01',
  String? finishedAt,
  int? costCents,
}) => FilmRoll(
  id: id,
  sequenceNumber: id,
  filmName: film,
  format: '35mm',
  nominalIso: 400,
  exposedIso: 400,
  cameraId: cameraId,
  loadedAt: loadedAt,
  finishedAt: finishedAt,
  frames: 36,
  title: title,
  status: status.key,
  costCents: costCents,
  createdAt: 0,
);

const Camera om2 = Camera(
  id: 1,
  manufacturer: 'Olympus',
  model: 'OM-2',
  format: '35mm',
  active: true,
  sortOrder: 0,
);

Development development(
  int rollId, {
  String? submittedAt,
  String? returnedAt,
  String? laboratory,
  int? costCents,
  int? scanCents,
}) => Development(
  id: rollId,
  filmRollId: rollId,
  laboratory: laboratory,
  submittedAt: submittedAt,
  returnedAt: returnedAt,
  developmentCostCents: costCents,
  scanCostCents: scanCents,
  selfDeveloped: false,
);

/// "Oggi" nei test: 8 ottobre 2026.
final CivilDate testToday = CivilDate(2026, 10, 8);

/// Monta [page] in italiano, scura come l'app, con il repository finto e "oggi" fisso.
///
/// ⚑ Schermo alto (800×2000): home e dettaglio sono liste pigre, e un elemento fuori schermo
/// non esiste per `find`. Qui conta che ci sia, non doverlo far scorrere.
Future<FakeRollRepository> pumpRollPage(
  WidgetTester tester,
  Widget page, {
  List<FilmRoll>? rolls,
  List<Camera>? cameras,
  List<Development>? developments,
  List<PrintOrder>? prints,
}) async {
  tester.view
    ..physicalSize = const Size(800, 2000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase.memory();
  final repo = FakeRollRepository(
    db,
    rolls: rolls,
    cameras: cameras,
    developments: developments,
    prints: prints,
  );
  addTearDown(() async {
    await repo.dispose();
    await db.close();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        todayProvider.overrideWithValue(testToday),
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
        theme: ThemeData(brightness: Brightness.dark),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:film_tracker/app/providers.dart';
import 'package:film_tracker/data/database.dart';
import 'package:film_tracker/data/film_repository.dart';
import 'package:film_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

/// Un repository in memoria per i test di widget delle foto e del QR.
///
/// ☠ Finto e non Drift su `AppDatabase.memory()`: dentro `testWidgets` FakeAsync congela l'I/O
/// di SQLite e gli stream non arrivano mai (lezione di TrashCan, ripetuta in Scorte Calore
/// `test/features/history/fake_repo.dart`). Che le scritture vere funzionino lo dimostrano
/// `test/data/film_repository_test.dart` e `photo_import_test.dart`.
class FakePhotoRepository extends FilmRepository {
  FakePhotoRepository(super.db, {required this.roll, List<RollImage>? images}) : images = [...?images];

  FilmRoll roll;
  final List<RollImage> images;
  final _imgs = StreamController<List<RollImage>>.broadcast();
  final rolls = StreamController<FilmRoll?>.broadcast();

  /// Le chiamate ricevute, per le verifiche.
  final List<int?> coverCalls = [];
  final List<List<int>> reorderCalls = [];

  @override
  Stream<List<RollImage>> watchImages(int rollId) async* {
    yield List.of(images);
    yield* _imgs.stream;
  }

  @override
  Stream<FilmRoll?> watchRoll(int id) async* {
    yield id == roll.id ? roll : null;
    yield* rolls.stream;
  }

  @override
  Future<void> setCoverImage(int rollId, int? imageId) async {
    coverCalls.add(imageId);
    roll = roll.copyWith(coverImageId: Value(imageId));
    rolls.add(roll);
  }

  @override
  Future<void> reorderImages(List<int> idsInOrder) async {
    reorderCalls.add(idsInOrder);
  }

  @override
  Future<StoredImage?> deleteImage(int id) async {
    final i = images.indexWhere((x) => x.id == id);
    if (i < 0) return null;
    final removed = images.removeAt(i);
    if (roll.coverImageId == id) roll = roll.copyWith(coverImageId: const Value(null));
    _imgs.add(List.of(images));
    rolls.add(roll);
    return removed.toStoredImage();
  }

  Future<void> dispose() async {
    await _imgs.close();
    await rolls.close();
  }
}

FilmRoll testRoll({int id = 1, int seq = 17, int? cover, String? title}) => FilmRoll(
  id: id,
  sequenceNumber: seq,
  filmName: 'Kodak Portra 400',
  format: '35mm',
  nominalIso: 400,
  exposedIso: 400,
  frames: 36,
  title: title,
  status: 'loaded',
  coverImageId: cover,
  createdAt: 0,
);

RollImage testImage(int id, {int rollId = 1, int order = 0}) => RollImage(
  id: id,
  filmRollId: rollId,
  path: 'images/rolls/$id.jpg',
  thumbPath: 'images/thumbs/rolls/$id.jpg',
  width: 1600,
  height: 1067,
  bytes: 300000,
  kind: 'contactSheet',
  sortOrder: order,
  createdAt: 0,
);

/// Monta [page] in italiano, tema scuro (il default dell'app), con il repository finto.
Future<FakePhotoRepository> pumpWithFakeRepo(
  WidgetTester tester,
  Widget page, {
  required FilmRoll roll,
  List<RollImage>? images,
}) async {
  final db = AppDatabase.memory();
  final repo = FakePhotoRepository(db, roll: roll, images: images);
  addTearDown(() async {
    await repo.dispose();
    await db.close();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        // Cartella che non esiste: le miniature mostrano il segnaposto, come dopo un
        // ripristino senza foto. Qui conta la pagina, non i pixel.
        appPathsProvider.overrideWithValue(
          AppPaths.underRoot(Directory('${Directory.systemTemp.path}/ft_widget_test_inesistente')),
        ),
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE0A458), brightness: Brightness.dark),
        ),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

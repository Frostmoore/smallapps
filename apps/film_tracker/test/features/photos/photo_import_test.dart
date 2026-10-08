import 'dart:io';

import 'package:film_tracker/data/database.dart';
import 'package:film_tracker/data/film_repository.dart';
import 'package:film_tracker/domain/film_types.dart';
import 'package:film_tracker/features/photos/photo_actions.dart';
import 'package:film_tracker/features/photos/photo_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:micro_core/micro_core.dart';

/// F6.9: l'import delle foto con ImageStore vero (ridimensionamento in un isolate) e database
/// in memoria. Test semplici e non `testWidgets`: dentro FakeAsync l'isolate e SQLite non
/// avanzano.
void main() {
  late Directory tmp;
  late AppDatabase db;
  late FilmRepository repo;
  late ImageStore store;
  late int rollId;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('ft_photos_');
    db = AppDatabase.memory();
    repo = FilmRepository(db);
    store = ImageStore(paths: AppPaths.underRoot(Directory('${tmp.path}/docs')));
    rollId = await repo.addRoll(filmName: 'Ilford HP5 Plus', format: FilmFormat.mm35, nominalIso: 400, frames: 36);
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  /// Un JPEG vero, piu' grande del lato lungo conservato, cosi' il ridimensionamento si vede.
  File jpeg(String name, {int w = 2000, int h = 1000}) {
    final f = File('${tmp.path}/src_$name.jpg')
      ..writeAsBytesSync(img.encodeJpg(img.Image(width: w, height: h)));
    return f;
  }

  File garbage(String name) => File('${tmp.path}/src_$name.jpg')..writeAsBytesSync([1, 2, 3, 4]);

  test('importa, ridimensiona a 1600 px, salva la miniatura e conta le illeggibili', () async {
    final progress = <int>[];
    final outcome = await importRollPhotos(
      repository: repo,
      store: store,
      rollId: rollId,
      files: [jpeg('a'), garbage('b'), jpeg('c', w: 800, h: 1200)],
      kind: RollImageKind.scan,
      onProgress: progress.add,
    );
    expect(outcome.imported, 2);
    expect(outcome.failed, 1);
    expect(outcome.cancelled, isFalse);
    expect(progress, [1, 2, 3]);

    final images = await repo.imagesFor(rollId);
    expect(images, hasLength(2));
    expect(images.first.width, 1600);
    expect(images.first.height, 800);
    expect(images.last.width, 800, reason: 'un\'immagine piu\' piccola non si ingrandisce');
    expect(images.every((i) => i.kindEnum == RollImageKind.scan), isTrue);
    for (final i in images) {
      expect(store.resolve(i.path).existsSync(), isTrue);
      expect(store.resolve(i.thumbPath).existsSync(), isTrue);
    }
    // La prima foto diventa copertina da sola (FilmRepository.addImage).
    expect((await repo.rollById(rollId))!.coverImageId, images.first.id);
  });

  test('annullato prima di cominciare non importa niente', () async {
    final cancel = ImportCancellation()..cancel();
    final outcome = await importRollPhotos(
      repository: repo,
      store: store,
      rollId: rollId,
      files: [jpeg('a'), jpeg('b')],
      cancellation: cancel,
    );
    expect(outcome.imported, 0);
    expect(outcome.cancelled, isTrue);
    expect(await repo.imagesFor(rollId), isEmpty);
  });

  test('annullato durante: tiene la foto in corso e si ferma', () async {
    final cancel = ImportCancellation();
    final outcome = await importRollPhotos(
      repository: repo,
      store: store,
      rollId: rollId,
      files: [jpeg('a'), jpeg('b'), jpeg('c')],
      cancellation: cancel,
      onProgress: (_) => cancel.cancel(),
    );
    expect(outcome.imported, 1);
    expect(outcome.cancelled, isTrue);
    expect(await repo.imagesFor(rollId), hasLength(1));
  });

  test('libera spazio: pruneOrphans con allImagePaths toglie solo gli orfani', () async {
    await importRollPhotos(repository: repo, store: store, rollId: rollId, files: [jpeg('a'), jpeg('b')]);
    final images = await repo.imagesFor(rollId);
    // Un orfano: la riga cancellata senza toccare i file (una cancellazione interrotta).
    await repo.deleteImage(images.first.id);

    final removed = await store.pruneOrphans(await repo.allImagePaths());
    expect(removed, 2, reason: 'immagine e miniatura dell\'orfano');
    expect(store.resolve(images.first.path).existsSync(), isFalse);
    expect(store.resolve(images.last.path).existsSync(), isTrue);
    expect(store.resolve(images.last.thumbPath).existsSync(), isTrue);
  });
}

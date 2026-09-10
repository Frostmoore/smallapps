import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../util/micro_log.dart';
import '../util/result.dart';
import 'app_paths.dart';

/// Un'immagine conservata dall'app, con la sua miniatura.
@immutable
class StoredImage {
  const StoredImage({
    required this.path,
    required this.thumbPath,
    required this.width,
    required this.height,
    required this.bytes,
    required this.createdAt,
  });

  factory StoredImage.fromJson(Map<String, Object?> json) => StoredImage(
    path: json['path']! as String,
    thumbPath: json['thumbPath']! as String,
    width: (json['width']! as num).toInt(),
    height: (json['height']! as num).toInt(),
    bytes: (json['bytes']! as num).toInt(),
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc(),
  );

  /// Percorso **relativo** alla cartella documenti dell'app.
  ///
  /// Mai assoluto: la sandbox di Android cambia percorso fra un aggiornamento e l'altro,
  /// e un percorso assoluto salvato oggi punta al nulla dopo il primo update. Il sintomo
  /// sarebbe che tutte le foto degli utenti spariscono al primo aggiornamento.
  final String path;

  final String thumbPath;
  final int width;
  final int height;
  final int bytes;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'path': path,
    'thumbPath': thumbPath,
    'width': width,
    'height': height,
    'bytes': bytes,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

@immutable
class _ResizeRequest {
  const _ResizeRequest(this.bytes, this.maxLongSide, this.thumbLongSide, this.quality);

  final Uint8List bytes;
  final int maxLongSide;
  final int thumbLongSide;
  final int quality;
}

@immutable
class _ResizeResult {
  const _ResizeResult(this.full, this.thumb, this.width, this.height);

  final Uint8List full;
  final Uint8List thumb;
  final int width;
  final int height;
}

/// Conserva le immagini dell'app, ridimensionate.
class ImageStore {
  const ImageStore({required this.paths});

  final AppPaths paths;

  /// Lato lungo massimo dell'immagine conservata.
  ///
  /// 1600 px è il compromesso indicato dalle specifiche di Film Tracker: abbastanza per
  /// riconoscere un provino, poco abbastanza da non riempire il telefono. Con qualità 82
  /// sono circa 300 KB per immagine.
  static const int defaultMaxLongSide = 1600;
  static const int defaultThumbLongSide = 400;
  static const int defaultQuality = 82;

  Future<Result<StoredImage>> importFile(
    File source, {
    required String bucket,
    int maxLongSide = defaultMaxLongSide,
    int thumbLongSide = defaultThumbLongSide,
    int quality = defaultQuality,
  }) async {
    try {
      return await importBytes(
        await source.readAsBytes(),
        bucket: bucket,
        maxLongSide: maxLongSide,
        thumbLongSide: thumbLongSide,
        quality: quality,
      );
    } on FileSystemException catch (error, stack) {
      return Err(
        MicroError(
          code: MicroErrorCodes.io,
          message: 'Immagine non leggibile',
          cause: error,
          stackTrace: stack,
        ),
      );
    }
  }

  Future<Result<StoredImage>> importBytes(
    Uint8List data, {
    required String bucket,
    int maxLongSide = defaultMaxLongSide,
    int thumbLongSide = defaultThumbLongSide,
    int quality = defaultQuality,
  }) async {
    try {
      // Il ridimensionamento gira in un isolate separato.
      //
      // ☠ Su un telefono di fascia bassa, decodificare e ridimensionare una foto da 12
      // megapixel richiede secondi: farlo sul thread della UI congela l'app proprio
      // mentre l'utente ha appena scelto dieci immagini dalla galleria.
      final resized = await compute(
        _resize,
        _ResizeRequest(data, maxLongSide, thumbLongSide, quality),
      );
      if (resized == null) {
        return const Err(
          MicroError(
            code: MicroErrorCodes.corruptedFile,
            message: 'Formato immagine non riconosciuto',
          ),
        );
      }

      final name = '${const Uuid().v4()}.jpg';
      final relative = 'images/$bucket/$name';
      final thumbRelative = 'images/thumbs/$bucket/$name';

      final fullFile = paths.resolve(relative);
      final thumbFile = paths.resolve(thumbRelative);
      for (final f in [fullFile, thumbFile]) {
        if (!f.parent.existsSync()) await f.parent.create(recursive: true);
      }
      await AtomicFile.writeBytes(fullFile, resized.full);
      await AtomicFile.writeBytes(thumbFile, resized.thumb);

      return Ok(
        StoredImage(
          path: relative,
          thumbPath: thumbRelative,
          width: resized.width,
          height: resized.height,
          bytes: resized.full.length,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    } on Exception catch (error, stack) {
      MicroLog.e('import immagine fallito', error: error, stackTrace: stack);
      return Err(MicroError.unexpected(error, stack));
    }
  }

  File resolve(String relativePath) => paths.resolve(relativePath);

  Future<void> delete(StoredImage image) async {
    for (final relative in [image.path, image.thumbPath]) {
      final file = paths.resolve(relative);
      if (file.existsSync()) await file.delete();
    }
  }

  Future<void> deleteBucket(String bucket) async {
    for (final dir in [
      Directory(p.join(paths.images.path, bucket)),
      Directory(p.join(paths.thumbs.path, bucket)),
    ]) {
      if (dir.existsSync()) await dir.delete(recursive: true);
    }
  }

  Future<int> totalBytes() => paths.sizeOf(paths.images);

  /// Cancella i file che nessun record referenzia più.
  ///
  /// ⚑ Serve perché prima o poi qualcosa resta orfano: una cancellazione interrotta, un
  /// ripristino parziale, un difetto. Senza una pulizia periodica lo spazio occupato
  /// cresce e l'utente non capisce perché l'app pesa un giga.
  Future<int> pruneOrphans(Set<String> referencedPaths) async {
    if (!paths.images.existsSync()) return 0;
    var removed = 0;
    await for (final entity in paths.images.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = paths.relativize(entity);
      if (referencedPaths.contains(relative)) continue;
      await entity.delete();
      removed++;
    }
    if (removed > 0) MicroLog.i('immagini orfane rimosse: $removed');
    return removed;
  }
}

/// Gira in un isolate: nessun accesso a stato condiviso.
_ResizeResult? _resize(_ResizeRequest request) {
  final decoded = img.decodeImage(request.bytes);
  if (decoded == null) return null;

  // ☠ `bakeOrientation` applica l'orientamento EXIF ai pixel. Senza, una foto scattata in
  // verticale resta orizzontale nei dati e viene raddrizzata solo dai visualizzatori che
  // leggono l'EXIF: nella griglia dell'app apparirebbe coricata, e la miniatura pure.
  final oriented = img.bakeOrientation(decoded);

  img.Image fit(img.Image src, int longSide) {
    final longest = src.width > src.height ? src.width : src.height;
    if (longest <= longSide) return src;
    return src.width >= src.height
        ? img.copyResize(src, width: longSide)
        : img.copyResize(src, height: longSide);
  }

  final full = fit(oriented, request.maxLongSide);
  final thumb = fit(oriented, request.thumbLongSide);

  return _ResizeResult(
    img.encodeJpg(full, quality: request.quality),
    img.encodeJpg(thumb, quality: request.quality),
    full.width,
    full.height,
  );
}

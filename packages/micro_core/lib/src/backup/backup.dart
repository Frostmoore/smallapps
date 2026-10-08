import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../storage/app_paths.dart';
import '../util/micro_log.dart';
import '../util/result.dart';

/// Come integrare i dati importati con quelli già presenti.
enum ImportMode {
  /// Cancella tutto e riparte dal file.
  replaceAll,

  /// Aggiunge quello che manca, senza toccare quello che c'è.
  mergeKeepExisting,
}

/// Ciò che un'app deve saper fare per essere salvata e ripristinata.
abstract interface class BackupSource {
  /// Identificatore dell'app, per esempio `trashcan`. Impedisce di ripristinare il
  /// backup di un'app dentro un'altra.
  String get schemaId;

  /// Versione dello schema dei dati esportati.
  int get schemaVersion;

  Future<Map<String, Object?>> exportPayload();

  Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode});

  /// I percorsi relativi delle immagini da includere nel backup completo.
  Future<List<String>> imagePaths() async => const <String>[];

  /// Quanti elementi per collezione, per il riepilogo mostrato prima di ripristinare.
  Future<Map<String, int>> counts() async => const <String, int>{};
}

/// L'intestazione di un file di backup.
@immutable
class BackupManifest {
  const BackupManifest({
    required this.schemaId,
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAt,
    required this.itemCounts,
    this.label,
  });

  factory BackupManifest.fromJson(Map<String, Object?> json) => BackupManifest(
    schemaId: json['schemaId']! as String,
    schemaVersion: (json['schemaVersion']! as num).toInt(),
    appVersion: json['appVersion'] as String? ?? '?',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toUtc() ??
        DateTime.now().toUtc(),
    itemCounts: <String, int>{
      for (final e in (json['itemCounts'] as Map? ?? const {}).entries)
        e.key.toString(): (e.value as num).toInt(),
    },
    label: json['label'] as String?,
  );

  final String schemaId;
  final int schemaVersion;
  final String appVersion;
  final DateTime createdAt;
  final Map<String, int> itemCounts;
  final String? label;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaId': schemaId,
    'schemaVersion': schemaVersion,
    'appVersion': appVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'itemCounts': itemCounts,
    'label': label,
  };

  int get totalItems => itemCounts.values.fold(0, (a, b) => a + b);
}

/// Il formato del file di backup.
///
/// ⚑ JSON leggibile e non un binario compresso: l'utente deve poter aprire il file e
/// riconoscere i propri dati, e in caso di problema può ripararlo a mano. Le dimensioni
/// sono trascurabili, qualche decina di KB, perché le immagini non ci finiscono dentro.
abstract final class JsonBackupCodec {
  static const String magic = 'MICROAPPS_BACKUP';
  static const int formatVersion = 1;

  static String encode({
    required BackupManifest manifest,
    required Map<String, Object?> payload,
  }) => const JsonEncoder.withIndent('  ').convert(<String, Object?>{
    'magic': magic,
    'formatVersion': formatVersion,
    'manifest': manifest.toJson(),
    'payload': payload,
  });

  static Result<({BackupManifest manifest, Map<String, Object?> payload})> decode(
    String contents,
  ) {
    try {
      final decoded = jsonDecode(contents);
      if (decoded is! Map<String, Object?>) {
        return const Err(
          MicroError(code: MicroErrorCodes.corruptedFile, message: 'Il file non è un backup'),
        );
      }
      if (decoded['magic'] != magic) {
        return const Err(
          MicroError(
            code: MicroErrorCodes.corruptedFile,
            message: 'Il file non è un backup delle MicroApps',
          ),
        );
      }
      final version = (decoded['formatVersion'] as num?)?.toInt() ?? 0;
      if (version > formatVersion) {
        return const Err(
          MicroError(
            code: MicroErrorCodes.unsupportedVersion,
            message: 'Backup creato da una versione più recente dell\'app',
          ),
        );
      }
      final manifest = BackupManifest.fromJson(decoded['manifest']! as Map<String, Object?>);
      final payload = decoded['payload'] as Map<String, Object?>? ?? const <String, Object?>{};
      return Ok((manifest: manifest, payload: payload));
    } on Exception catch (error, stack) {
      return Err(
        MicroError(
          code: MicroErrorCodes.corruptedFile,
          message: 'Backup illeggibile',
          cause: error,
          stackTrace: stack,
        ),
      );
    }
  }
}

/// Crea e ripristina i backup.
class BackupService {
  const BackupService({required this.paths, required this.appVersion});

  final AppPaths paths;
  final String appVersion;

  static const String jsonExtension = 'microbackup.json';
  static const String zipExtension = 'microbackup.zip';

  /// Crea il file di backup e ne restituisce il percorso.
  ///
  /// Con [includeImages] produce uno ZIP con `data.json` più la cartella `images/`.
  ///
  /// ⚑ Perché uno ZIP e non le immagini in base64 dentro il JSON: le contact sheet di
  /// Film Tracker pesano centinaia di KB l'una. In base64 il file cresce di un terzo e
  /// diventa impossibile da aprire con un editor, cioè perde l'unico vantaggio del JSON.
  Future<Result<File>> createBackup(
    BackupSource source, {
    String? label,
    bool includeImages = false,
  }) async {
    try {
      if (!paths.exports.existsSync()) await paths.exports.create(recursive: true);

      final manifest = BackupManifest(
        schemaId: source.schemaId,
        schemaVersion: source.schemaVersion,
        appVersion: appVersion,
        createdAt: DateTime.now().toUtc(),
        itemCounts: await source.counts(),
        label: label,
      );
      final json = JsonBackupCodec.encode(
        manifest: manifest,
        payload: await source.exportPayload(),
      );

      final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      if (!includeImages) {
        final target = paths.file(paths.exports, '${source.schemaId}-$stamp.$jsonExtension');
        await AtomicFile.writeString(target, json);
        return Ok(target);
      }

      final archive = Archive()
        ..addFile(ArchiveFile.string('data.json', json));
      for (final relative in await source.imagePaths()) {
        final file = paths.resolve(relative);
        if (!file.existsSync()) continue;
        archive.addFile(ArchiveFile.bytes('images/$relative', await file.readAsBytes()));
      }
      final encoded = ZipEncoder().encode(archive);
      final target = paths.file(paths.exports, '${source.schemaId}-$stamp.$zipExtension');
      await AtomicFile.writeBytes(target, encoded);
      return Ok(target);
    } on Exception catch (error, stack) {
      MicroLog.e('creazione backup fallita', error: error, stackTrace: stack);
      return Err(MicroError.unexpected(error, stack));
    }
  }

  /// Legge solo l'intestazione, per mostrare all'utente cosa sta per ripristinare.
  ///
  /// ⚑ Un ripristino è distruttivo e irreversibile: mostrare prima quante voci contiene
  /// il file e di che data è, evita la telefonata che comincia con "ho perso tutto".
  Future<Result<BackupManifest>> inspect(File file) async {
    final read = await _readJson(file);
    return read.fold(
      ok: (data) => Ok(data.manifest),
      err: Err.new,
    );
  }

  Future<Result<void>> restore(
    File file,
    BackupSource source, {
    required ImportMode mode,
  }) async {
    final read = await _readJson(file);
    final data = read.valueOrNull;
    if (data == null) return Err(read.errorOrNull!);

    // Due controlli prima di toccare qualsiasi dato dell'utente: l'app giusta, e uno
    // schema che questa versione sa leggere. Un import parziale è peggio di nessun
    // import, perché lascia un miscuglio che nessuno sa più districare.
    if (data.manifest.schemaId != source.schemaId) {
      return const Err<void>(
        MicroError(
          code: MicroErrorCodes.unsupportedVersion,
          message: 'Questo backup appartiene a un\'altra app',
        ),
      );
    }
    if (data.manifest.schemaVersion > source.schemaVersion) {
      return const Err<void>(
        MicroError(
          code: MicroErrorCodes.unsupportedVersion,
          message: 'Backup creato da una versione più recente dell\'app',
        ),
      );
    }

    try {
      await source.importPayload(data.payload, mode: mode);
      if (_isZip(file)) await _restoreImages(file);
      return const Ok<void>(null);
    } on Exception catch (error, stack) {
      MicroLog.e('ripristino fallito', error: error, stackTrace: stack);
      return Err<void>(MicroError.unexpected(error, stack));
    }
  }

  /// Chiede all'utente quale file ripristinare.
  ///
  /// Non si filtra per estensione: su Android il selettore di sistema con un filtro
  /// personalizzato nasconde spesso proprio il file cercato, perche' il MIME type di un
  /// .json arrivato via chat o via cloud non e' quello previsto. Meglio mostrarli tutti e
  /// far fallire la lettura con un messaggio chiaro.
  Future<File?> pickBackupFile() async {
    final picked = await FilePicker.pickFile();
    final path = picked?.path;
    return path == null ? null : File(path);
  }

  Future<void> shareBackup(File file, {String? subject}) =>
      SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: subject));

  /// Cancella gli export vecchi. Sono file usa e getta.
  Future<int> cleanupExports({Duration olderThan = const Duration(days: 7)}) async {
    if (!paths.exports.existsSync()) return 0;
    final cutoff = DateTime.now().subtract(olderThan);
    var removed = 0;
    await for (final entity in paths.exports.list()) {
      if (entity is! File) continue;
      if (entity.statSync().modified.isBefore(cutoff)) {
        await entity.delete();
        removed++;
      }
    }
    return removed;
  }

  static bool _isZip(File file) => file.path.toLowerCase().endsWith('.zip');

  Future<Result<({BackupManifest manifest, Map<String, Object?> payload})>> _readJson(
    File file,
  ) async {
    try {
      if (!file.existsSync()) {
        return const Err(
          MicroError(code: MicroErrorCodes.notFound, message: 'File non trovato'),
        );
      }
      if (_isZip(file)) {
        final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
        final entry = archive.files.where((f) => f.name == 'data.json').firstOrNull;
        if (entry == null) {
          return const Err(
            MicroError(
              code: MicroErrorCodes.corruptedFile,
              message: 'Archivio senza data.json',
            ),
          );
        }
        return JsonBackupCodec.decode(utf8.decode(entry.readBytes() ?? const <int>[]));
      }
      return JsonBackupCodec.decode(await file.readAsString());
    } on Exception catch (error, stack) {
      return Err(
        MicroError(
          code: MicroErrorCodes.corruptedFile,
          message: 'Backup illeggibile',
          cause: error,
          stackTrace: stack,
        ),
      );
    }
  }

  Future<void> _restoreImages(File zip) async {
    final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    for (final entry in archive.files) {
      if (!entry.isFile || !entry.name.startsWith('images/')) continue;
      final relative = entry.name.substring('images/'.length);
      final target = paths.resolve(relative);
      // ☠ Zip slip: un nome di voce come `images/../../shared_prefs/x.xml` (o assoluto)
      // scriverebbe fuori dalla cartella dell'app. Un backup arriva da fuori (email, cloud,
      // chat): si scartano le voci che, normalizzate, non restano dentro i documenti
      // (segnalato con Film Tracker, 2026-10-08).
      if (!p.isWithin(p.normalize(paths.documents.path), p.normalize(target.path))) {
        MicroLog.w('voce del backup fuori dalla cartella, ignorata: ${entry.name}');
        continue;
      }
      if (!target.parent.existsSync()) await target.parent.create(recursive: true);
      await target.writeAsBytes(entry.readBytes() ?? const <int>[], flush: true);
    }
  }
}

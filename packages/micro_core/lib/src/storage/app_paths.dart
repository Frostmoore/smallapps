import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Le cartelle di un'app, risolte una volta sola all'avvio.
///
/// ☠ **I percorsi assoluti non si salvano mai nel database.** Su Android la sandbox
/// dell'app cambia percorso tra un aggiornamento e l'altro e dopo un ripristino del
/// dispositivo: un percorso assoluto salvato oggi punta al nulla dopo il primo update, e
/// tutte le foto degli utenti risultano mancanti. Si salva il percorso **relativo** e lo
/// si risolve a runtime con [resolve].
class AppPaths {
  const AppPaths._({
    required this.documents,
    required this.support,
    required this.images,
    required this.thumbs,
    required this.exports,
    required this.logs,
  });

  static Future<AppPaths> forApp({required String appId}) async {
    final docs = await getApplicationDocumentsDirectory();
    final support = await getApplicationSupportDirectory();
    final cache = await getTemporaryDirectory();

    // Sotto-cartella per appId: in test e in eventuali build multi-flavor più app
    // condividono la stessa sandbox, e senza prefisso si sovrascriverebbero i dati.
    final root = Directory(p.join(docs.path, appId));
    final images = Directory(p.join(root.path, 'images'));

    return AppPaths._(
      documents: root,
      support: Directory(p.join(support.path, appId)),
      images: images,
      thumbs: Directory(p.join(images.path, 'thumbs')),
      // Gli export stanno in cache: sono file usa e getta, e il sistema può cancellarli
      // quando serve spazio senza che l'utente perda niente di suo.
      exports: Directory(p.join(cache.path, appId, 'exports')),
      logs: Directory(p.join(support.path, appId, 'logs')),
    );
  }

  /// Costruisce un set di cartelle sotto una radice arbitraria. Per i test.
  factory AppPaths.underRoot(Directory root) {
    final images = Directory(p.join(root.path, 'images'));
    return AppPaths._(
      documents: root,
      support: Directory(p.join(root.path, 'support')),
      images: images,
      thumbs: Directory(p.join(images.path, 'thumbs')),
      exports: Directory(p.join(root.path, 'exports')),
      logs: Directory(p.join(root.path, 'logs')),
    );
  }

  /// Dati dell'app. Inclusi nel backup di sistema di Android.
  final Directory documents;

  /// Stato interno: entitlement, marcatori. Non pensato per l'utente.
  final Directory support;

  final Directory images;
  final Directory thumbs;

  /// File temporanei destinati alla condivisione. Cancellabili in qualsiasi momento.
  final Directory exports;

  final Directory logs;

  Future<void> ensureAll() async {
    for (final dir in [documents, support, images, thumbs, exports, logs]) {
      if (!dir.existsSync()) await dir.create(recursive: true);
    }
  }

  File file(Directory dir, String name) => File(p.join(dir.path, name));

  /// Risolve un percorso **relativo a [documents]** in un file reale.
  File resolve(String relativePath) => File(p.join(documents.path, relativePath));

  /// L'inverso di [resolve]: da file assoluto a percorso relativo salvabile.
  String relativize(File file) => p.relative(file.path, from: documents.path).replaceAll(r'\', '/');

  /// Spazio occupato da una cartella, in byte.
  Future<int> sizeOf(Directory dir) async {
    if (!dir.existsSync()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}

/// Scrittura atomica: o il file finisce intero, o resta quello di prima.
///
/// ⚑ Perché serve: `entitlement.json` e i backup si scrivono mentre l'utente può chiudere
/// l'app e mentre il sistema può ucciderla. Una scrittura non atomica lascia un file
/// troncato, e al riavvio un utente che ha pagato risulta gratuito. Scrivere su un file
/// temporaneo e poi rinominarlo rende l'operazione atomica a livello di filesystem: la
/// rinomina o avviene o non avviene, non esiste una via di mezzo.
abstract final class AtomicFile {
  static Future<void> writeString(File target, String contents) =>
      writeBytes(target, contents.codeUnits);

  static int _tmpCounter = 0;

  /// Le scritture sullo stesso file vengono messe in fila, non eseguite in parallelo.
  ///
  /// ☠ Trappola trovata dai test: `EntitlementService` può scrivere lo stato da due
  /// percorsi asincroni contemporaneamente (l'evento di acquisto e la sincronizzazione
  /// col server). Due scritture concorrenti sullo stesso file si sabotavano a vicenda,
  /// con `rename` che falliva perché il temporaneo era già stato consumato dall'altra.
  /// In produzione il sintomo sarebbe stato un entitlement che ogni tanto non si salva,
  /// cioè un Pro che sparisce al riavvio: raro, non riproducibile, e devastante.
  static final Map<String, Future<void>> _queues = <String, Future<void>>{};

  static Future<void> writeBytes(File target, List<int> bytes) {
    final key = target.path;
    final previous = _queues[key] ?? Future<void>.value();
    final next = previous.then((_) => _writeNow(target, bytes));
    _queues[key] = next.catchError((Object _) {});
    return next;
  }

  static Future<void> _writeNow(File target, List<int> bytes) async {
    final dir = target.parent;
    if (!dir.existsSync()) await dir.create(recursive: true);

    // Nome temporaneo unico: due scritture in coda non devono comunque poter usare lo
    // stesso file di appoggio, nemmeno se una fallisce a metà lasciandolo lì.
    final tmp = File('${target.path}.${_tmpCounter++}.tmp');
    try {
      await tmp.writeAsBytes(bytes, flush: true);

      // Su Windows `rename` fallisce se la destinazione esiste; su POSIX la sostituisce.
      // Cancellare prima riapre una finestra di rischio minima, ma è l'unico modo per
      // avere lo stesso comportamento sulle due piattaforme.
      if (target.existsSync() && Platform.isWindows) await target.delete();
      await tmp.rename(target.path);
    } finally {
      if (tmp.existsSync()) {
        try {
          await tmp.delete();
        } on FileSystemException {
          // un temporaneo orfano non fa danni
        }
      }
    }
  }

  /// Il contenuto, oppure `null` se il file non c'è o non è leggibile.
  ///
  /// Non lancia: un file di stato illeggibile deve far ripartire l'app da zero su quel
  /// dato, non impedirle di avviarsi.
  static Future<String?> readStringOrNull(File target) async {
    try {
      if (!target.existsSync()) return null;
      return await target.readAsString();
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  static Future<Uint8List?> readBytesOrNull(File target) async {
    try {
      if (!target.existsSync()) return null;
      return await target.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }
}

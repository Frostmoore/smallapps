import 'dart:io';

import 'package:drift/drift.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../domain/film_types.dart';
import '../domain/roll_status.dart';

/// Come Film Tracker si esporta e si reimporta, **con le immagini** (F6.11). Creare il backup
/// e' Pro (`FeatureKey.backupRestore`), ripristinarlo e' gratis: vedi `restoreBackup` in
/// `features/settings/data_section.dart`.
///
/// Il file e' lo ZIP di `BackupService.createBackup(includeImages: true)`: `data.json` con il
/// payload qui sotto, piu' `images/<percorso relativo>` per ogni foto e miniatura
/// ([imagePaths]). Al ripristino `BackupService` chiama prima [importPayload] e poi scrive i
/// file delle immagini **agli stessi percorsi relativi**: per questo il payload conserva
/// `path` e `thumbPath` tali e quali (sono UUID, F6.9: non si scontrano fra telefoni).
///
/// Forma del payload:
/// ```
/// cameras: [{ref, manufacturer, model, format, note, active, sortOrder}]
/// stocks:  [{brand, name, iso, process, format}]          solo le pellicole dell'utente
/// rolls:   [{sequenceNumber, stock:{brand,name,format}?, filmName, format, nominalIso,
///            exposedIso, camera:ref?, loadedAt, finishedAt, frames, title, note, status,
///            costCents, createdAt,
///            development:{...}?, prints:[{...}], images:[{path, thumbPath, width, height,
///            bytes, kind, sortOrder, createdAt, cover}]}]
/// ```
///
/// ⚑ **Sviluppo, stampe e immagini annidati nel rullino** (come Scorte Calore, Full Freezer e
/// TrashCan): gli id di riga non significano niente su un altro telefono, e annidando non c'e'
/// niente da rimappare. Le macchine invece sono condivise da molti rullini e non si possono
/// annidare: viaggiano con un `ref` (l'id del telefono di partenza) che vale **solo dentro il
/// file** e al ripristino si traduce nell'id nuovo.
///
/// ⚑ **La pellicola si riconosce da marca, nome e formato**, non dall'id: l'id del catalogo
/// dipende dall'ordine in cui e' stato caricato, la tripla no (e' la UNIQUE di
/// `film_stocks`). Del catalogo si esportano solo le pellicole personalizzate: le altre
/// esistono gia' su ogni telefono (`AppDatabase.seedCatalog`).
///
/// ⚑ La copertina viaggia come `cover: true` sull'immagine e non come `coverImageId`: e' un
/// riferimento circolare (rullino -> immagine -> rullino), e il ripristino lo ricuce dopo aver
/// inserito le immagini.
///
/// ☠ **"Sostituisci tutto" cancella anche i file delle foto che il backup non riporta.** Il
/// cascade toglie le righe di `roll_images`, non i file: senza [paths] resterebbero sul
/// telefono per sempre (stessa trappola di `deleteRollAndCollectImagePaths`, F6.2). Si
/// cancellano **dopo** la transazione riuscita, e solo quelli che il file non riscrivera':
/// ripristinare sullo stesso telefono il backup di ieri non deve far sparire foto che
/// `BackupService` sta per riscrivere identiche.
class FilmBackupSource implements BackupSource {
  const FilmBackupSource(this.db, {this.paths, this.clock});

  final AppDatabase db;

  /// Le cartelle dell'app, per cancellare i file orfani dopo un "sostituisci tutto". Null
  /// nei test che provano solo il database.
  final AppPaths? paths;

  /// Per i test: l'ora usata quando il file non porta una data di creazione.
  final DateTime Function()? clock;

  /// L'identificativo dei backup di Film Tracker, anche per riconoscerli prima di chiedere
  /// come ripristinarli (`restoreBackup`).
  static const String id = 'film_tracker';

  @override
  String get schemaId => id;

  @override
  int get schemaVersion => 1;

  // ── Esportazione ─────────────────────────────────────────────────────────

  @override
  Future<Map<String, Object?>> exportPayload() async {
    final cameras = await (db.select(db.cameras)
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)]))
        .get();
    final stocks = await db.select(db.filmStocks).get();
    final stockById = {for (final s in stocks) s.id: s};
    final rolls = await (db.select(db.filmRolls)
          ..orderBy([(t) => OrderingTerm(expression: t.sequenceNumber)]))
        .get();
    final devs = {for (final d in await db.select(db.developments).get()) d.filmRollId: d};
    final prints = await (db.select(db.printOrders)..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
    final images = await (db.select(db.rollImages)
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)]))
        .get();

    return <String, Object?>{
      'cameras': [
        for (final c in cameras)
          <String, Object?>{
            'ref': c.id,
            'manufacturer': c.manufacturer,
            'model': c.model,
            'format': c.format,
            'note': c.note,
            // Anche le macchine dismesse: sono la storia dei rullini che hanno scattato.
            'active': c.active,
            'sortOrder': c.sortOrder,
          },
      ],
      'stocks': [
        for (final s in stocks)
          if (s.isCustom)
            <String, Object?>{'brand': s.brand, 'name': s.name, 'iso': s.iso, 'process': s.process, 'format': s.format},
      ],
      'rolls': [
        for (final r in rolls)
          <String, Object?>{
            'sequenceNumber': r.sequenceNumber,
            'stock': switch (stockById[r.filmStockId]) {
              null => null,
              final s => <String, Object?>{'brand': s.brand, 'name': s.name, 'format': s.format},
            },
            'filmName': r.filmName,
            'format': r.format,
            'nominalIso': r.nominalIso,
            'exposedIso': r.exposedIso,
            'camera': r.cameraId,
            'loadedAt': r.loadedAt,
            'finishedAt': r.finishedAt,
            'frames': r.frames,
            'title': r.title,
            'note': r.note,
            'status': r.status,
            'costCents': r.costCents,
            'createdAt': r.createdAt,
            'development': switch (devs[r.id]) {
              null => null,
              final d => <String, Object?>{
                'laboratory': d.laboratory,
                'submittedAt': d.submittedAt,
                'returnedAt': d.returnedAt,
                'developmentCostCents': d.developmentCostCents,
                'scanCostCents': d.scanCostCents,
                'process': d.process,
                'selfDeveloped': d.selfDeveloped,
                'note': d.note,
              },
            },
            'prints': [
              for (final p in prints.where((p) => p.filmRollId == r.id))
                <String, Object?>{
                  'laboratory': p.laboratory,
                  'submittedAt': p.submittedAt,
                  'returnedAt': p.returnedAt,
                  'format': p.format,
                  'numberOfPrints': p.numberOfPrints,
                  'costCents': p.costCents,
                  'note': p.note,
                },
            ],
            'images': [
              for (final i in images.where((i) => i.filmRollId == r.id))
                <String, Object?>{
                  'path': i.path,
                  'thumbPath': i.thumbPath,
                  'width': i.width,
                  'height': i.height,
                  'bytes': i.bytes,
                  'kind': i.kind,
                  'sortOrder': i.sortOrder,
                  'createdAt': i.createdAt,
                  'cover': i.id == r.coverImageId,
                },
            ],
          },
      ],
    };
  }

  /// Foto e miniature di tutti i rullini, relative alla cartella documenti: `BackupService`
  /// le mette nello ZIP sotto `images/` (e salta in silenzio quelle il cui file manca).
  @override
  Future<List<String>> imagePaths() async {
    final rows = await (db.select(db.rollImages)..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
    return [
      for (final r in rows) ...[r.path, r.thumbPath],
    ];
  }

  /// Quello che il riepilogo mostra prima del ripristino (`backup_restoreSummary`).
  @override
  Future<Map<String, int>> counts() async => <String, int>{
    'rolls': await db.filmRolls.count().getSingle(),
    'cameras': await db.cameras.count().getSingle(),
    'images': await db.rollImages.count().getSingle(),
  };

  // ── Ripristino ───────────────────────────────────────────────────────────

  /// Scrive il contenuto di [payload] nel database, tutto in una transazione.
  ///
  /// - `replaceAll`: cancella rullini (e in cascata sviluppi, stampe e righe delle immagini),
  ///   macchine e pellicole personalizzate, poi mette quelle del backup con i loro numeri. I
  ///   file delle foto che il backup non riporta si cancellano dopo (vedi la classe).
  /// - `mergeKeepExisting`: aggiunge quello che manca.
  ///   * Un rullino **gia' presente** (stesso `createdAt` e stesso `filmName`: lo stesso
  ///     rullino ripristinato due volte) si salta con tutto quello che contiene.
  ///   * Un rullino nuovo tiene il suo numero se e' libero, altrimenti prende il primo
  ///     libero dopo il massimo. ⚑ Tenerlo quando si puo' conta: il numero e' scritto
  ///     sull'etichetta QR attaccata al contenitore (F6.12).
  ///   * Una macchina con lo stesso produttore e modello (a meno di maiuscole) e' la stessa:
  ///     i rullini del backup si attaccano a quella del telefono, senza doppioni.
  ///   * Una pellicola personalizzata gia' presente (marca, nome, formato) non si duplica.
  ///
  /// ⚑ Il limite di una macchina del piano gratuito **non** si applica qui: il ripristino e'
  /// gratis e riporta i dati dell'utente come erano. Il limite ferma la creazione di una
  /// macchina nuova, non la restituzione di quelle che l'utente aveva.
  ///
  /// ☠ Lancia [FormatException] (mai un `Error`) su un file con chiavi sconosciute, campi del
  /// tipo sbagliato o percorsi d'immagine sospetti: `BackupService.restore` intercetta solo
  /// le `Exception`, e un `TypeError` arriverebbe all'utente come crash invece che come "file
  /// rovinato". La transazione intanto e' gia' annullata: niente ripristini a meta'.
  @override
  Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode}) async {
    final now = (clock ?? DateTime.now)().toUtc().millisecondsSinceEpoch;
    final orphans = <String>{};
    try {
      await db.transaction(() async {
        if (mode == ImportMode.replaceAll) {
          for (final i in await db.select(db.rollImages).get()) {
            orphans
              ..add(i.path)
              ..add(i.thumbPath);
          }
          // Cascade: con i rullini spariscono sviluppi, stampe e righe delle immagini.
          await db.delete(db.filmRolls).go();
          await db.delete(db.cameras).go();
          await (db.delete(db.filmStocks)..where((t) => t.isCustom.equals(true))).go();
          // Il catalogo non si cancella mai, ma rimetterlo costa niente e garantisce che le
          // pellicole citate dal file esistano.
          await db.seedCatalog();
        }

        final cameraIds = await _importCameras(_list(payload['cameras']), mode);
        await _importStocks(_list(payload['stocks']));
        final stocks = await db.select(db.filmStocks).get();

        final existing = await db.select(db.filmRolls).get();
        final seen = {for (final r in existing) (r.createdAt, r.filmName)};
        final incoming = [
          for (final r in _list(payload['rolls']))
            if (mode == ImportMode.replaceAll ||
                !seen.contains(((r['createdAt'] as num?)?.toInt() ?? now, r['filmName']! as String)))
              r,
        ];

        // ⚑ Due passate: prima si riservano i numeri del file che sono liberi, poi chi ha il
        // numero occupato prende il primo dopo il massimo di tutti. In una passata sola un
        // numero occupato all'inizio spingerebbe a cascata tutti i rullini dopo di lui
        // (#1 -> 2, quindi #2 -> 3, ...), e ogni etichetta QR del file diventerebbe sbagliata.
        final usedNumbers = {for (final r in existing) r.sequenceNumber};
        final numbers = List<int?>.filled(incoming.length, null);
        for (var k = 0; k < incoming.length; k++) {
          final n = (incoming[k]['sequenceNumber'] as num?)?.toInt() ?? 0;
          if (n > 0 && usedNumbers.add(n)) numbers[k] = n;
        }
        var maxNumber = usedNumbers.fold<int>(0, (m, n) => n > m ? n : m);

        for (var k = 0; k < incoming.length; k++) {
          final r = incoming[k];
          final filmName = r['filmName']! as String;
          final createdAt = (r['createdAt'] as num?)?.toInt() ?? now;
          final number = numbers[k] ?? ++maxNumber;

          final rollId = await db
              .into(db.filmRolls)
              .insert(
                FilmRollsCompanion.insert(
                  sequenceNumber: number,
                  filmStockId: Value(_findStock(stocks, r['stock'])),
                  filmName: filmName,
                  format: _formatKey(r['format'], 'rullino "$filmName"'),
                  nominalIso: (r['nominalIso']! as num).toInt(),
                  exposedIso: (r['exposedIso'] as num? ?? r['nominalIso']! as num).toInt(),
                  cameraId: Value(cameraIds[(r['camera'] as num?)?.toInt()]),
                  loadedAt: Value(_date(r['loadedAt'])),
                  finishedAt: Value(_date(r['finishedAt'])),
                  frames: (r['frames']! as num).toInt(),
                  title: Value(r['title'] as String?),
                  note: Value(r['note'] as String?),
                  status: _statusKey(r['status'], filmName),
                  costCents: Value((r['costCents'] as num?)?.toInt()),
                  createdAt: createdAt,
                ),
              );

          final dev = r['development'];
          if (dev is Map) await _importDevelopment(rollId, dev.cast<String, Object?>());
          for (final p in _list(r['prints'])) {
            await db
                .into(db.printOrders)
                .insert(
                  PrintOrdersCompanion.insert(
                    filmRollId: rollId,
                    laboratory: Value(p['laboratory'] as String?),
                    submittedAt: Value(_date(p['submittedAt'])),
                    returnedAt: Value(_date(p['returnedAt'])),
                    format: Value(p['format'] as String?),
                    numberOfPrints: Value((p['numberOfPrints'] as num?)?.toInt()),
                    costCents: Value((p['costCents'] as num?)?.toInt()),
                    note: Value(p['note'] as String?),
                  ),
                );
          }

          int? coverId;
          var order = 0;
          for (final i in _list(r['images'])) {
            final path = _imagePath(i['path']);
            final thumbPath = _imagePath(i['thumbPath']);
            orphans
              ..remove(path)
              ..remove(thumbPath);
            final kind = RollImageKind.byKey(i['kind'] as String?);
            if (kind == null) throw FormatException('Immagine "$path": tipo sconosciuto (${i['kind']})');
            final imageId = await db
                .into(db.rollImages)
                .insert(
                  RollImagesCompanion.insert(
                    filmRollId: rollId,
                    path: path,
                    thumbPath: thumbPath,
                    width: (i['width']! as num).toInt(),
                    height: (i['height']! as num).toInt(),
                    bytes: (i['bytes'] as num?)?.toInt() ?? 0,
                    kind: kind.key,
                    sortOrder: Value((i['sortOrder'] as num?)?.toInt() ?? order),
                    createdAt: (i['createdAt'] as num?)?.toInt() ?? now,
                  ),
                );
            order++;
            if (i['cover'] == true) coverId = imageId;
          }
          if (coverId != null) {
            await (db.update(db.filmRolls)..where((t) => t.id.equals(rollId)))
                .write(FilmRollsCompanion(coverImageId: Value(coverId)));
          }
        }
      });
    } on TypeError catch (error) {
      throw FormatException('Backup di Film Tracker malformato: $error');
    }

    // Solo a transazione riuscita: con un file rotto le foto del telefono restano.
    final p = paths;
    if (p != null && mode == ImportMode.replaceAll) {
      for (final relative in orphans) {
        final file = p.resolve(relative);
        try {
          if (file.existsSync()) await file.delete();
        } on FileSystemException {
          // Un file che non si cancella resta orfano: lo raccoglie `ImageStore.pruneOrphans`.
        }
      }
    }
  }

  /// Le macchine del file; restituisce `ref del file -> id sul telefono`.
  Future<Map<int, int>> _importCameras(List<Map<String, Object?>> cameras, ImportMode mode) async {
    final existing = await db.select(db.cameras).get();
    String key(String manufacturer, String model) => '${manufacturer.trim().toLowerCase()}|${model.trim().toLowerCase()}';
    final byName = {for (final c in existing) key(c.manufacturer, c.model): c.id};
    var nextOrder = existing.fold<int>(-1, (m, c) => c.sortOrder > m ? c.sortOrder : m) + 1;
    final ids = <int, int>{};
    for (final c in cameras) {
      final manufacturer = c['manufacturer']! as String;
      final model = c['model']! as String;
      final ref = (c['ref'] as num?)?.toInt();
      final same = byName[key(manufacturer, model)];
      if (same != null) {
        if (ref != null) ids[ref] = same;
        continue;
      }
      final sortOrder = mode == ImportMode.replaceAll ? (c['sortOrder'] as num?)?.toInt() ?? nextOrder : nextOrder;
      nextOrder = (sortOrder > nextOrder ? sortOrder : nextOrder) + 1;
      final id = await db
          .into(db.cameras)
          .insert(
            CamerasCompanion.insert(
              manufacturer: manufacturer,
              model: model,
              format: _formatKey(c['format'], 'macchina "$manufacturer $model"'),
              note: Value(c['note'] as String?),
              active: Value(c['active'] as bool? ?? true),
              sortOrder: Value(sortOrder),
            ),
          );
      byName[key(manufacturer, model)] = id;
      if (ref != null) ids[ref] = id;
    }
    return ids;
  }

  /// Le pellicole personalizzate del file, saltando quelle gia' presenti (a meno di
  /// maiuscole e spazi, la stessa regola di `FilmRepository.addCustomStock`).
  Future<void> _importStocks(List<Map<String, Object?>> stocks) async {
    final existing = await db.select(db.filmStocks).get();
    for (final s in stocks) {
      final brand = s['brand']! as String;
      final name = s['name']! as String;
      final format = _formatKey(s['format'], 'pellicola "$brand $name"');
      if (_matchStock(existing, brand, name, format) != null) continue;
      final process = FilmProcess.byKey(s['process'] as String?);
      if (process == null) throw FormatException('Pellicola "$brand $name": processo sconosciuto (${s['process']})');
      await db
          .into(db.filmStocks)
          .insert(
            FilmStocksCompanion.insert(
              brand: brand,
              name: name,
              iso: (s['iso']! as num).toInt(),
              process: process.key,
              format: format,
              isCustom: const Value(true),
            ),
          );
      existing.add(
        FilmStock(id: -1, brand: brand, name: name, iso: 0, process: process.key, format: format, isCustom: true),
      );
    }
  }

  Future<void> _importDevelopment(int rollId, Map<String, Object?> d) async {
    final processRaw = d['process'] as String?;
    final process = processRaw == null ? null : FilmProcess.byKey(processRaw);
    if (processRaw != null && process == null) {
      throw FormatException('Sviluppo: processo sconosciuto ($processRaw)');
    }
    await db
        .into(db.developments)
        .insert(
          DevelopmentsCompanion.insert(
            filmRollId: rollId,
            laboratory: Value(d['laboratory'] as String?),
            submittedAt: Value(_date(d['submittedAt'])),
            returnedAt: Value(_date(d['returnedAt'])),
            developmentCostCents: Value((d['developmentCostCents'] as num?)?.toInt()),
            scanCostCents: Value((d['scanCostCents'] as num?)?.toInt()),
            process: Value(process?.key),
            selfDeveloped: Value(d['selfDeveloped'] as bool? ?? false),
            note: Value(d['note'] as String?),
          ),
        );
  }

  /// L'id della pellicola citata da un rullino (`{brand, name, format}`); null se il file non
  /// la cita o il telefono non ce l'ha (il rullino conserva comunque `filmName`).
  static int? _findStock(List<FilmStock> stocks, Object? raw) {
    if (raw is! Map) return null;
    final brand = raw['brand'] as String?;
    final name = raw['name'] as String?;
    final format = raw['format'] as String?;
    if (brand == null || name == null || format == null) return null;
    return _matchStock(stocks, brand, name, format)?.id;
  }

  static FilmStock? _matchStock(List<FilmStock> stocks, String brand, String name, String format) {
    final b = brand.trim().toLowerCase();
    final n = name.trim().toLowerCase();
    for (final s in stocks) {
      if (s.format == format && s.brand.trim().toLowerCase() == b && s.name.trim().toLowerCase() == n) return s;
    }
    return null;
  }

  static String _formatKey(Object? raw, String what) {
    final f = FilmFormat.byKey(raw as String?);
    if (f == null) throw FormatException('Formato sconosciuto per $what ($raw)');
    return f.key;
  }

  static String _statusKey(Object? raw, String filmName) {
    final s = RollStatus.byKey(raw as String?);
    if (s == null) throw FormatException('Rullino "$filmName": stato sconosciuto ($raw)');
    return s.key;
  }

  /// Una data `YYYY-MM-DD` o null. ☠ Validata qui: una data scritta male passerebbe il
  /// vincolo di lunghezza e romperebbe in silenzio i confronti fra date dello schema.
  static String? _date(Object? raw) {
    if (raw == null) return null;
    final d = CivilDate.tryParse(raw as String);
    if (d == null) throw FormatException('Data non valida ($raw)');
    return d.toIso();
  }

  /// Un percorso d'immagine relativo, sotto `images/`.
  ///
  /// ☠ Un file di backup e' un dato esterno: un percorso con `..` o assoluto, scritto nel
  /// database, farebbe leggere (e cancellare, con "sostituisci tutto") un file fuori dalla
  /// cartella dell'app.
  static String _imagePath(Object? raw) {
    final path = raw! as String;
    if (!path.startsWith('images/') || path.contains('..') || path.contains(r'\') || path.contains(':')) {
      throw FormatException('Percorso d\'immagine non ammesso ($path)');
    }
    return path;
  }

  static List<Map<String, Object?>> _list(Object? raw) =>
      raw is List ? [for (final e in raw) if (e is Map) e.cast<String, Object?>()] : const [];
}

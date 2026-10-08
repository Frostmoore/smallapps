import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import '../domain/film_stats.dart';
import '../domain/film_types.dart';
import '../domain/roll_status.dart';
import 'database.dart';

/// Tutte le scritture e le letture dei dati di Film Tracker.
///
/// ⚑ **Perche' un repository e non query sparse nelle pagine**: alcune regole non si
/// possono scrivere come vincoli SQL e vanno rispettate a ogni scrittura, quindi passano da
/// una porta sola:
/// 1. `sequenceNumber` e' `max + 1`, assegnato dentro la stessa transazione dell'inserimento;
/// 2. lo stato cambia solo per transizioni ammesse da `RollStatusMachine`, salvo `force`;
/// 3. al massimo **uno** sviluppo per rullino (il secondo salvataggio sostituisce il primo);
/// 4. la copertina e' un'immagine **dello stesso** rullino;
/// 5. le pellicole del catalogo non si modificano ne' si cancellano, e non esistono due
///    pellicole uguali a meno delle maiuscole.
///
/// ⚑ **Righe in uscita, dominio dove serve**: le letture restituiscono le righe Drift
/// (`Camera`, `FilmStock`, `FilmRoll`, `Development`, `PrintOrder`, `RollImage`); le
/// conversioni al dominio stanno nelle estensioni di `database.dart` (`statusEnum`,
/// `toLabEvent()`...).
///
/// I limiti del piano gratuito (una macchina) **non** stanno qui: li applica la UI con
/// `FeatureGate`. I dati non sanno del Pro.
class FilmRepository {
  FilmRepository(this._db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  static const RollStatusMachine _machine = RollStatusMachine();

  int _nowMs() => _clock().toUtc().millisecondsSinceEpoch;

  // ── Macchine ──────────────────────────────────────────────────────────────

  /// Le macchine nell'ordine dell'utente. Con [activeOnly] solo quelle attive (il form del
  /// rullino); senza, anche le dismesse (l'inventario).
  Stream<List<Camera>> watchCameras({bool activeOnly = false}) => _camerasQuery(activeOnly).watch();

  Future<List<Camera>> allCameras({bool activeOnly = false}) => _camerasQuery(activeOnly).get();

  SimpleSelectStatement<$CamerasTable, Camera> _camerasQuery(bool activeOnly) {
    final q = _db.select(_db.cameras);
    if (activeOnly) q.where((t) => t.active.equals(true));
    return q..orderBy([
      (t) => OrderingTerm(expression: t.sortOrder),
      (t) => OrderingTerm(expression: t.id),
    ]);
  }

  Future<Camera?> cameraById(int id) =>
      (_db.select(_db.cameras)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Camera?> watchCamera(int id) =>
      (_db.select(_db.cameras)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Quante macchine esistono, attive e no: il conteggio di `FeatureKey.secondaryEntities`.
  Future<int> cameraCount() => _db.cameras.count().getSingle();

  Stream<int> watchCameraCount() => _db.cameras.count().watchSingle();

  /// Aggiunge una macchina in fondo all'elenco. Il limite del piano gratuito lo controlla
  /// la UI prima di chiamare.
  Future<int> addCamera({
    required String manufacturer,
    required String model,
    required FilmFormat format,
    String? note,
  }) async {
    final count = await cameraCount();
    return _db
        .into(_db.cameras)
        .insert(
          CamerasCompanion.insert(
            manufacturer: manufacturer.trim(),
            model: model.trim(),
            format: format.key,
            note: Value(_blankToNull(note)),
            sortOrder: Value(count),
          ),
        );
  }

  /// Salva produttore, modello, formato e nota di [camera]. `active` e `sortOrder` hanno i
  /// loro metodi e qui non si toccano.
  Future<void> updateCamera(Camera camera) =>
      (_db.update(_db.cameras)..where((t) => t.id.equals(camera.id))).write(
        CamerasCompanion(
          manufacturer: Value(camera.manufacturer.trim()),
          model: Value(camera.model.trim()),
          format: Value(camera.format),
          note: Value(_blankToNull(camera.note)),
        ),
      );

  Future<void> setCameraActive(int id, bool active) => (_db.update(
    _db.cameras,
  )..where((t) => t.id.equals(id))).write(CamerasCompanion(active: Value(active)));

  /// Cancella la macchina. I rullini restano, con `cameraId` NULL (setNull): la storia non
  /// si perde perche' si e' venduta una macchina. La UI propone prima di disattivarla.
  Future<void> deleteCamera(int id) =>
      (_db.delete(_db.cameras)..where((t) => t.id.equals(id))).go();

  Future<void> reorderCameras(List<int> idsInOrder) => _db.transaction(() async {
    for (var i = 0; i < idsInOrder.length; i++) {
      await (_db.update(
        _db.cameras,
      )..where((t) => t.id.equals(idsInOrder[i]))).write(CamerasCompanion(sortOrder: Value(i)));
    }
  });

  /// Quanti rullini ha scattato ogni macchina (F6.5): `cameraId -> conteggio`. Le macchine
  /// senza rullini non compaiono (la UI legge `?? 0`).
  Stream<Map<int, int>> watchRollCountByCamera() =>
      _rollCountByCameraQuery().watch().map(_toCountMap);

  Future<Map<int, int>> rollCountByCamera() async =>
      _toCountMap(await _rollCountByCameraQuery().get());

  JoinedSelectStatement<$FilmRollsTable, FilmRoll> _rollCountByCameraQuery() {
    final r = _db.filmRolls;
    return _db.selectOnly(r)
      ..addColumns([r.cameraId, _rollsCount])
      ..where(r.cameraId.isNotNull())
      ..groupBy([r.cameraId]);
  }

  Expression<int> get _rollsCount => _db.filmRolls.id.count();

  Map<int, int> _toCountMap(List<TypedResult> rows) => {
    for (final row in rows) row.read(_db.filmRolls.cameraId)!: row.read(_rollsCount)!,
  };

  // ── Catalogo pellicole ────────────────────────────────────────────────────

  /// Tutte le pellicole, ordinate per marca e nome senza badare alle maiuscole: la lista
  /// del catalogo (F6.4) le raggruppa per marca in quest'ordine.
  Stream<List<FilmStock>> watchStocks() => _stocksQuery().watch();

  Future<List<FilmStock>> allStocks() => _stocksQuery().get();

  SimpleSelectStatement<$FilmStocksTable, FilmStock> _stocksQuery() =>
      _db.select(_db.filmStocks)..orderBy([
        (t) => OrderingTerm(expression: t.brand.collate(Collate.noCase)),
        (t) => OrderingTerm(expression: t.name.collate(Collate.noCase)),
        (t) => OrderingTerm(expression: t.id),
      ]);

  Future<FilmStock?> stockById(int id) =>
      (_db.select(_db.filmStocks)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Le pellicole usate in almeno un rullino, dalla piu' usata, al massimo [limit]: la
  /// selezione rapida in cima al form del rullino (F6.4, le cinque in cima). A parita' di
  /// rullini vince quella usata piu' di recente (numero progressivo piu' alto).
  Stream<List<FilmStock>> watchMostUsedStocks({int limit = 5}) =>
      _mostUsedQuery(limit).watch().map(_readStocks);

  Future<List<FilmStock>> mostUsedStocks({int limit = 5}) async =>
      _readStocks(await _mostUsedQuery(limit).get());

  JoinedSelectStatement<HasResultSet, dynamic> _mostUsedQuery(int limit) {
    final s = _db.filmStocks;
    final r = _db.filmRolls;
    final uses = r.id.count();
    final lastUse = r.sequenceNumber.max();
    return _db.select(s).join([innerJoin(r, r.filmStockId.equalsExp(s.id))])
      ..addColumns([uses, lastUse])
      ..groupBy([s.id])
      ..orderBy([OrderingTerm.desc(uses), OrderingTerm.desc(lastUse)])
      ..limit(limit);
  }

  List<FilmStock> _readStocks(List<TypedResult> rows) => [
    for (final row in rows) row.readTable(_db.filmStocks),
  ];

  /// Aggiunge una pellicola dell'utente (`isCustom` true).
  ///
  /// Lancia [DuplicateFilmStockException] se esiste gia' una pellicola con la stessa marca,
  /// lo stesso nome e lo stesso formato **a meno di maiuscole e spazi** (anche del
  /// catalogo): la UI la seleziona invece di crearne un doppione.
  Future<int> addCustomStock({
    required String brand,
    required String name,
    required int iso,
    required FilmProcess process,
    required FilmFormat format,
  }) => _db.transaction(() async {
    await _requireNoDuplicateStock(brand, name, format.key);
    return _db
        .into(_db.filmStocks)
        .insert(
          FilmStocksCompanion.insert(
            brand: brand.trim(),
            name: name.trim(),
            iso: iso,
            process: process.key,
            format: format.key,
            isCustom: const Value(true),
          ),
        );
  });

  /// Salva una pellicola dell'utente. ⚑ I rullini gia' scattati **non** cambiano nome
  /// (`filmName` e' denormalizzato di proposito: e' la loro storia).
  ///
  /// Lancia [ArgumentError] su una pellicola del catalogo, [DuplicateFilmStockException] se
  /// la modifica la rende uguale a un'altra.
  Future<void> updateCustomStock(FilmStock stock) => _db.transaction(() async {
    final before = await stockById(stock.id);
    if (before == null) throw StateError('Pellicola ${stock.id} inesistente');
    if (!before.isCustom) {
      throw ArgumentError.value(stock.id, 'stock', 'Le pellicole del catalogo non si modificano');
    }
    await _requireNoDuplicateStock(stock.brand, stock.name, stock.format, exceptId: stock.id);
    await (_db.update(_db.filmStocks)..where((t) => t.id.equals(stock.id))).write(
      FilmStocksCompanion(
        brand: Value(stock.brand.trim()),
        name: Value(stock.name.trim()),
        iso: Value(stock.iso),
        process: Value(stock.process),
        format: Value(stock.format),
      ),
    );
  });

  /// Cancella una pellicola dell'utente. I rullini restano con il loro `filmName` e
  /// `filmStockId` NULL. Lancia [ArgumentError] su una pellicola del catalogo.
  Future<void> deleteCustomStock(int id) => _db.transaction(() async {
    final stock = await stockById(id);
    if (stock == null) return;
    if (!stock.isCustom) {
      throw ArgumentError.value(id, 'id', 'Le pellicole del catalogo non si cancellano');
    }
    await (_db.delete(_db.filmStocks)..where((t) => t.id.equals(id))).go();
  });

  Future<void> _requireNoDuplicateStock(
    String brand,
    String name,
    String formatKey, {
    int? exceptId,
  }) async {
    // Il confronto senza maiuscole si fa in Dart: `lower()` di SQLite conosce solo l'ASCII.
    final b = brand.trim().toLowerCase();
    final n = name.trim().toLowerCase();
    final sameFormat = await (_db.select(
      _db.filmStocks,
    )..where((t) => t.format.equals(formatKey))).get();
    for (final s in sameFormat) {
      if (s.id != exceptId && s.brand.toLowerCase() == b && s.name.toLowerCase() == n) {
        throw DuplicateFilmStockException(s.id);
      }
    }
  }

  // ── Rullini ───────────────────────────────────────────────────────────────

  /// I rullini, **dal numero piu' alto** (il piu' recente). Con [section] solo quelli di
  /// una sezione della home.
  Stream<List<FilmRoll>> watchRolls({RollSection? section}) => _rollsQuery(section).watch();

  Future<List<FilmRoll>> allRolls({RollSection? section}) => _rollsQuery(section).get();

  SimpleSelectStatement<$FilmRollsTable, FilmRoll> _rollsQuery(RollSection? section) {
    final q = _db.select(_db.filmRolls);
    if (section != null) {
      q.where((t) => t.status.isIn([for (final s in _machine.statusesIn(section)) s.key]));
    }
    return q..orderBy([(t) => OrderingTerm.desc(t.sequenceNumber)]);
  }

  Future<FilmRoll?> rollById(int id) =>
      (_db.select(_db.filmRolls)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<FilmRoll?> watchRoll(int id) =>
      (_db.select(_db.filmRolls)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Il rullino con il "#n": il bersaglio del deep link del QR (F6.12).
  Future<FilmRoll?> rollBySequence(int sequenceNumber) => (_db.select(
    _db.filmRolls,
  )..where((t) => t.sequenceNumber.equals(sequenceNumber))).getSingleOrNull();

  /// Il numero che avra' il prossimo rullino: `max + 1`, 1 sul database vuoto (F6.6).
  ///
  /// ⚑ I buchi lasciati da rullini cancellati in mezzo restano buchi; il numero dell'ultimo
  /// rullino, se cancellato, si riusa (e' `max + 1`, come dice il piano). E' accettato: il
  /// caso tipico e' il rullino creato per errore e cancellato subito, e li' riusare il numero
  /// e' cio' che l'utente si aspetta.
  Future<int> nextSequenceNumber() async {
    final max = _db.filmRolls.sequenceNumber.max();
    final row = await (_db.selectOnly(_db.filmRolls)..addColumns([max])).getSingle();
    return (row.read(max) ?? 0) + 1;
  }

  /// Crea un rullino con il prossimo numero progressivo e ne restituisce l'id.
  ///
  /// [exposedIso] ha come default [nominalIso] (F6.6). [filmName] e' il nome mostrato e
  /// conservato (di solito `FilmStock.displayName`). [status] serve all'import e ai dati di
  /// esempio: la UI crea sempre rullini `loaded`.
  Future<int> addRoll({
    int? filmStockId,
    required String filmName,
    required FilmFormat format,
    required int nominalIso,
    int? exposedIso,
    int? cameraId,
    CivilDate? loadedAt,
    CivilDate? finishedAt,
    required int frames,
    String? title,
    String? note,
    int? costCents,
    RollStatus status = RollStatus.loaded,
  }) => _db.transaction(() async {
    final seq = await nextSequenceNumber();
    return _db
        .into(_db.filmRolls)
        .insert(
          FilmRollsCompanion.insert(
            sequenceNumber: seq,
            filmStockId: Value(filmStockId),
            filmName: filmName.trim(),
            format: format.key,
            nominalIso: nominalIso,
            exposedIso: exposedIso ?? nominalIso,
            cameraId: Value(cameraId),
            loadedAt: Value(loadedAt?.toIso()),
            finishedAt: Value(finishedAt?.toIso()),
            frames: frames,
            title: Value(_blankToNull(title)),
            note: Value(_blankToNull(note)),
            status: status.key,
            costCents: Value(costCents),
            createdAt: _nowMs(),
          ),
        );
  });

  /// Salva i campi modificabili dal form di [roll]: pellicola, formato, ISO, macchina,
  /// date, fotogrammi, titolo, nota, costo.
  ///
  /// ⚑ **Non** tocca `sequenceNumber`, `createdAt`, `status` e `coverImageId`: lo stato
  /// passa da [setRollStatus] (che conosce le transizioni), la copertina da [setCoverImage]
  /// (che controlla il rullino). Lancia `SqliteException` se `finishedAt` precede `loadedAt`.
  Future<void> updateRoll(FilmRoll roll) =>
      (_db.update(_db.filmRolls)..where((t) => t.id.equals(roll.id))).write(
        FilmRollsCompanion(
          filmStockId: Value(roll.filmStockId),
          filmName: Value(roll.filmName.trim()),
          format: Value(roll.format),
          nominalIso: Value(roll.nominalIso),
          exposedIso: Value(roll.exposedIso),
          cameraId: Value(roll.cameraId),
          loadedAt: Value(roll.loadedAt),
          finishedAt: Value(roll.finishedAt),
          frames: Value(roll.frames),
          title: Value(_blankToNull(roll.title)),
          note: Value(_blankToNull(roll.note)),
          costCents: Value(roll.costCents),
        ),
      );

  /// Porta il rullino [id] nello stato [to].
  ///
  /// Lancia [RollTransitionException] se `RollStatusMachine.canTransition` non lo ammette,
  /// a meno di [force]: l'utente puo' sempre forzare lo stato a mano (F6.3). Lo stesso
  /// stato non e' un errore, non fa niente. Lancia [StateError] se il rullino non esiste.
  Future<void> setRollStatus(int id, RollStatus to, {bool force = false}) =>
      _db.transaction(() async {
        final roll = await rollById(id);
        if (roll == null) throw StateError('Rullino $id inesistente');
        final from = roll.statusEnum;
        if (from == to) return;
        if (!force && !_machine.canTransition(from, to)) throw RollTransitionException(from, to);
        await _writeStatus(id, to);
      });

  /// "Rullino terminato" (F6.6): imposta `finishedAt` e, se il rullino e' `loaded`, lo
  /// passa a `exposed`. In un altro stato corregge solo la data.
  Future<void> markFinished(int id, CivilDate date) => _db.transaction(() async {
    final roll = await rollById(id);
    if (roll == null) throw StateError('Rullino $id inesistente');
    await (_db.update(_db.filmRolls)..where((t) => t.id.equals(id))).write(
      FilmRollsCompanion(
        finishedAt: Value(date.toIso()),
        status: roll.statusEnum == RollStatus.loaded
            ? Value(RollStatus.exposed.key)
            : const Value.absent(),
      ),
    );
  });

  Future<void> _writeStatus(int id, RollStatus to) => (_db.update(
    _db.filmRolls,
  )..where((t) => t.id.equals(id))).write(FilmRollsCompanion(status: Value(to.key)));

  /// Lo stato che sviluppo e stampe suggeriscono per il rullino
  /// (`RollStatusMachine.suggestFrom`); null se il rullino non esiste. La UI lo chiama dopo
  /// aver salvato uno sviluppo o una stampa e propone il cambio se e' diverso.
  Future<RollStatus?> suggestedStatus(int rollId) async {
    final roll = await rollById(rollId);
    if (roll == null) return null;
    final dev = await developmentFor(rollId);
    final prints = await printsFor(rollId);
    return _machine.suggestFrom(
      current: roll.statusEnum,
      finishedAt: roll.finishedDate,
      development: dev?.toLabEvent(),
      prints: [for (final p in prints) p.toLabEvent()],
    );
  }

  /// Cancella il rullino **con sviluppo, stampe e immagini** (cascade) e restituisce i
  /// percorsi relativi dei file delle sue immagini (`path` e `thumbPath`, nell'ordine).
  ///
  /// ☠ Il database non cancella i file: il chiamante passa i percorsi allo storage
  /// (`ImageStore`, con `AppPaths.resolve`), altrimenti le foto restano sul telefono per
  /// sempre (F6.2). `ImageStore.pruneOrphans` e' la rete di sicurezza, non il meccanismo.
  Future<List<String>> deleteRollAndCollectImagePaths(int id) => _db.transaction(() async {
    final images = await imagesFor(id);
    await (_db.delete(_db.filmRolls)..where((t) => t.id.equals(id))).go();
    return [
      for (final i in images) ...[i.path, i.thumbPath],
    ];
  });

  /// Le righe complete della home e dell'archivio: rullino, macchina, sviluppo, stampe e
  /// copertina in un colpo solo, dal numero piu' alto. Si riemette a ogni modifica di una
  /// delle tabelle coinvolte.
  ///
  /// ⚑ Cinque query e un'unione in Dart invece di un JOIN: le stampe sono N per rullino, e un
  /// JOIN moltiplicherebbe le righe. Con qualche centinaio di rullini costa nulla.
  Stream<List<RollListItem>> watchRollItems({RollSection? section}) => _watchTables({
    _db.filmRolls,
    _db.cameras,
    _db.developments,
    _db.printOrders,
    _db.rollImages,
  }, () => rollItems(section: section));

  Future<List<RollListItem>> rollItems({RollSection? section}) async {
    final rolls = await allRolls(section: section);
    final cameras = {for (final c in await allCameras()) c.id: c};
    final devs = {for (final d in await _db.select(_db.developments).get()) d.filmRollId: d};
    final prints = <int, List<PrintOrder>>{};
    for (final p in await (_db.select(_db.printOrders)..orderBy(_printOrder)).get()) {
      (prints[p.filmRollId] ??= []).add(p);
    }
    final coverIds = {for (final r in rolls) ?r.coverImageId};
    final covers = coverIds.isEmpty
        ? const <int, RollImage>{}
        : {
            for (final i in await (_db.select(
              _db.rollImages,
            )..where((t) => t.id.isIn(coverIds))).get())
              i.id: i,
          };
    return [
      for (final r in rolls)
        RollListItem(
          roll: r,
          camera: cameras[r.cameraId],
          development: devs[r.id],
          prints: List.unmodifiable(prints[r.id] ?? const <PrintOrder>[]),
          cover: covers[r.coverImageId],
        ),
    ];
  }

  // ── Sviluppo (uno per rullino) ────────────────────────────────────────────

  Future<Development?> developmentFor(int rollId) =>
      (_db.select(_db.developments)..where((t) => t.filmRollId.equals(rollId))).getSingleOrNull();

  Stream<Development?> watchDevelopment(int rollId) =>
      (_db.select(_db.developments)..where((t) => t.filmRollId.equals(rollId))).watchSingleOrNull();

  /// Salva lo sviluppo del rullino: lo crea, o **sostituisce** quello esistente (uno per
  /// rullino, F6.7). Tutti i campi vengono riscritti: un valore null cancella il vecchio.
  /// Restituisce l'id della riga, che resta lo stesso in caso di sostituzione.
  ///
  /// Non cambia lo stato del rullino: la UI chiede [suggestedStatus] e propone il cambio.
  /// Lancia `SqliteException` se [returnedAt] precede [submittedAt] o il rullino non esiste.
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
    final companion = DevelopmentsCompanion.insert(
      filmRollId: rollId,
      laboratory: Value(_blankToNull(laboratory)),
      submittedAt: Value(submittedAt?.toIso()),
      returnedAt: Value(returnedAt?.toIso()),
      developmentCostCents: Value(developmentCostCents),
      scanCostCents: Value(scanCostCents),
      process: Value(process?.key),
      selfDeveloped: Value(selfDeveloped),
      note: Value(_blankToNull(note)),
    );
    final row = await _db
        .into(_db.developments)
        .insertReturning(
          companion,
          onConflict: DoUpdate((_) => companion, target: [_db.developments.filmRollId]),
        );
    return row.id;
  }

  Future<void> deleteDevelopment(int rollId) =>
      (_db.delete(_db.developments)..where((t) => t.filmRollId.equals(rollId))).go();

  // ── Stampe (N per rullino) ────────────────────────────────────────────────

  /// Le stampe del rullino, **dalla consegna piu' vecchia** (l'ordine della timeline); quelle
  /// senza data di consegna in fondo, nell'ordine di inserimento.
  Stream<List<PrintOrder>> watchPrints(int rollId) => _printsQuery(rollId).watch();

  Future<List<PrintOrder>> printsFor(int rollId) => _printsQuery(rollId).get();

  SimpleSelectStatement<$PrintOrdersTable, PrintOrder> _printsQuery(int rollId) =>
      _db.select(_db.printOrders)
        ..where((t) => t.filmRollId.equals(rollId))
        ..orderBy(_printOrder);

  static final List<OrderClauseGenerator<$PrintOrdersTable>> _printOrder = [
    (t) => OrderingTerm(expression: t.submittedAt, nulls: NullsOrder.last),
    (t) => OrderingTerm(expression: t.id),
  ];

  Future<PrintOrder?> printById(int id) =>
      (_db.select(_db.printOrders)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> addPrintOrder({
    required int rollId,
    String? laboratory,
    CivilDate? submittedAt,
    CivilDate? returnedAt,
    String? format,
    int? numberOfPrints,
    int? costCents,
    String? note,
  }) => _db
      .into(_db.printOrders)
      .insert(
        PrintOrdersCompanion.insert(
          filmRollId: rollId,
          laboratory: Value(_blankToNull(laboratory)),
          submittedAt: Value(submittedAt?.toIso()),
          returnedAt: Value(returnedAt?.toIso()),
          format: Value(_blankToNull(format)),
          numberOfPrints: Value(numberOfPrints),
          costCents: Value(costCents),
          note: Value(_blankToNull(note)),
        ),
      );

  /// Salva la riga intera, come `copyWith` la lascia (`filmRollId` compreso).
  Future<void> updatePrintOrder(PrintOrder order) => _db
      .update(_db.printOrders)
      .replace(
        order.copyWith(
          laboratory: Value(_blankToNull(order.laboratory)),
          format: Value(_blankToNull(order.format)),
          note: Value(_blankToNull(order.note)),
        ),
      );

  Future<void> deletePrintOrder(int id) =>
      (_db.delete(_db.printOrders)..where((t) => t.id.equals(id))).go();

  // ── Laboratori ────────────────────────────────────────────────────────────

  /// I laboratori gia' usati in sviluppi e stampe, **dal piu' usato**, per l'autocompletamento
  /// (F6.7). Maiuscole e spazi non creano doppioni ("Fotoservice" e "fotoservice " sono uno,
  /// con la grafia vista per prima); a parita' d'uso, in ordine alfabetico.
  Stream<List<String>> watchLaboratories() =>
      _watchTables({_db.developments, _db.printOrders}, usedLaboratories);

  Future<List<String>> usedLaboratories() async {
    final devs =
        await (_db.selectOnly(_db.developments)
              ..addColumns([_db.developments.laboratory])
              ..orderBy([OrderingTerm(expression: _db.developments.id)]))
            .map((r) => r.read(_db.developments.laboratory))
            .get();
    final prints =
        await (_db.selectOnly(_db.printOrders)
              ..addColumns([_db.printOrders.laboratory])
              ..orderBy([OrderingTerm(expression: _db.printOrders.id)]))
            .map((r) => r.read(_db.printOrders.laboratory))
            .get();
    final counts = <String, int>{};
    final display = <String, String>{};
    for (final raw in [...devs, ...prints]) {
      final name = raw?.trim();
      if (name == null || name.isEmpty) continue;
      final key = name.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
      display.putIfAbsent(key, () => name);
    }
    final keys = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return [for (final k in keys) display[k]!];
  }

  // ── Immagini ──────────────────────────────────────────────────────────────

  /// Le immagini del rullino nell'ordine dell'utente.
  Stream<List<RollImage>> watchImages(int rollId) => _imagesQuery(rollId).watch();

  Future<List<RollImage>> imagesFor(int rollId) => _imagesQuery(rollId).get();

  SimpleSelectStatement<$RollImagesTable, RollImage> _imagesQuery(int rollId) =>
      _db.select(_db.rollImages)
        ..where((t) => t.filmRollId.equals(rollId))
        ..orderBy([
          (t) => OrderingTerm(expression: t.sortOrder),
          (t) => OrderingTerm(expression: t.id),
        ]);

  /// Registra un'immagine gia' salvata da `ImageStore` in fondo a quelle del rullino.
  ///
  /// ⚑ Se il rullino non ha ancora una copertina, la prima immagine lo diventa: l'archivio
  /// e' l'identita' dell'app (F6.8), e un rullino con le foto ma senza anteprima perche'
  /// l'utente non ha scelto la copertina sarebbe un difetto, non una scelta.
  Future<int> addImage({
    required int rollId,
    required StoredImage image,
    RollImageKind kind = RollImageKind.contactSheet,
  }) => _db.transaction(() async {
    final max = _db.rollImages.sortOrder.max();
    final row =
        await (_db.selectOnly(_db.rollImages)
              ..addColumns([max])
              ..where(_db.rollImages.filmRollId.equals(rollId)))
            .getSingle();
    final id = await _db
        .into(_db.rollImages)
        .insert(
          RollImagesCompanion.insert(
            filmRollId: rollId,
            path: image.path,
            thumbPath: image.thumbPath,
            width: image.width,
            height: image.height,
            bytes: image.bytes,
            kind: kind.key,
            sortOrder: Value((row.read(max) ?? -1) + 1),
            createdAt: image.createdAt.toUtc().millisecondsSinceEpoch,
          ),
        );
    await (_db.update(_db.filmRolls)..where((t) => t.id.equals(rollId) & t.coverImageId.isNull()))
        .write(FilmRollsCompanion(coverImageId: Value(id)));
    return id;
  });

  /// Cancella la riga e restituisce l'immagine da passare a `ImageStore.delete`; null se non
  /// esisteva. Se era la copertina, il rullino resta senza (setNull).
  Future<StoredImage?> deleteImage(int id) => _db.transaction(() async {
    final image = await (_db.select(
      _db.rollImages,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (image == null) return null;
    await (_db.delete(_db.rollImages)..where((t) => t.id.equals(id))).go();
    return image.toStoredImage();
  });

  Future<void> reorderImages(List<int> idsInOrder) => _db.transaction(() async {
    for (var i = 0; i < idsInOrder.length; i++) {
      await (_db.update(
        _db.rollImages,
      )..where((t) => t.id.equals(idsInOrder[i]))).write(RollImagesCompanion(sortOrder: Value(i)));
    }
  });

  /// Sceglie la copertina del rullino; null la toglie. Lancia [ArgumentError] se
  /// l'immagine non appartiene a quel rullino.
  Future<void> setCoverImage(int rollId, int? imageId) => _db.transaction(() async {
    if (imageId != null) {
      final image = await (_db.select(
        _db.rollImages,
      )..where((t) => t.id.equals(imageId))).getSingleOrNull();
      if (image == null || image.filmRollId != rollId) {
        throw ArgumentError.value(imageId, 'imageId', 'Non e\' un\'immagine del rullino $rollId');
      }
    }
    await (_db.update(
      _db.filmRolls,
    )..where((t) => t.id.equals(rollId))).write(FilmRollsCompanion(coverImageId: Value(imageId)));
  });

  /// Tutti i percorsi referenziati (immagini e miniature): l'ingresso di
  /// `ImageStore.pruneOrphans`.
  Future<Set<String>> allImagePaths() async {
    final rows = await _db.select(_db.rollImages).get();
    return {
      for (final r in rows) ...[r.path, r.thumbPath],
    };
  }

  // ── Statistiche (F6.10) ───────────────────────────────────────────────────

  /// I rullini con sviluppo e stampe, nella forma di `FilmStatsCalculator`.
  ///
  /// La data del rullino e' `loadedAt`, o il giorno (locale) di creazione se manca: un
  /// rullino senza data di caricamento deve comunque cadere in un anno.
  Future<List<StatsRoll>> statsRolls() async {
    final items = await rollItems();
    return [
      for (final i in items)
        StatsRoll(
          date: i.roll.loadedDate ?? CivilDate.fromDateTime(i.roll.createdAtUtc),
          frames: i.roll.frames,
          filmName: i.roll.filmName,
          cameraId: i.roll.cameraId,
          costCents: i.roll.costCents,
          development: i.development == null
              ? null
              : StatsDevelopment(
                  laboratory: i.development!.laboratory,
                  developmentCostCents: i.development!.developmentCostCents,
                  scanCostCents: i.development!.scanCostCents,
                  selfDeveloped: i.development!.selfDeveloped,
                ),
          prints: [
            for (final p in i.prints) StatsPrint(laboratory: p.laboratory, costCents: p.costCents),
          ],
        ),
    ];
  }

  Stream<List<StatsRoll>> watchStatsRolls() =>
      _watchTables({_db.filmRolls, _db.developments, _db.printOrders}, statsRolls);

  // ── Segnale di modifica ───────────────────────────────────────────────────

  /// Un segnale a ogni modifica di qualunque tabella (backup automatico, export).
  Stream<void> watchAnyChange() => _db.tableUpdates(
    TableUpdateQuery.onAllTables([
      _db.cameras,
      _db.filmStocks,
      _db.filmRolls,
      _db.developments,
      _db.printOrders,
      _db.rollImages,
    ]),
  );

  // ── Regole interne ────────────────────────────────────────────────────────

  /// Uno stream che emette [load] subito e a ogni modifica di [tables].
  ///
  /// ⚑ `tableUpdates` da solo non emette il primo valore; un `customSelect` con `readsFrom`
  /// si'. La query e' finta (`SELECT 1`): serve solo come innesco.
  Stream<T> _watchTables<T>(
    Set<ResultSetImplementation<dynamic, dynamic>> tables,
    Future<T> Function() load,
  ) => _db.customSelect('SELECT 1', readsFrom: tables).watch().asyncMap((_) => load());

  /// Una nota o un laboratorio fatti di soli spazi sono "niente", non una stringa vuota.
  static String? _blankToNull(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}

/// Un rullino con tutto quello che la sua card mostra (home, archivio).
@immutable
class RollListItem {
  const RollListItem({
    required this.roll,
    this.camera,
    this.development,
    this.prints = const [],
    this.cover,
  });

  final FilmRoll roll;
  final Camera? camera;
  final Development? development;

  /// Dalla consegna piu' vecchia.
  final List<PrintOrder> prints;

  /// La copertina (`coverImageId`), se c'e'.
  final RollImage? cover;

  RollStatus get status => roll.statusEnum;

  RollSection get section => roll.section;
}

/// Una pellicola uguale (marca, nome, formato, a meno di maiuscole) esiste gia'.
class DuplicateFilmStockException implements Exception {
  const DuplicateFilmStockException(this.existingId);

  /// La pellicola gia' presente: la UI puo' selezionarla.
  final int existingId;

  @override
  String toString() => 'DuplicateFilmStockException(esiste gia\' la pellicola $existingId)';
}

/// Una transizione di stato non ammessa da `RollStatusMachine` (senza `force`).
class RollTransitionException implements Exception {
  const RollTransitionException(this.from, this.to);

  final RollStatus from;
  final RollStatus to;

  @override
  String toString() => 'RollTransitionException(${from.key} -> ${to.key})';
}

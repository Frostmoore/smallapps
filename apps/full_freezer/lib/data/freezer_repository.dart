import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import '../domain/text_norm.dart';
import 'database.dart';

/// Un alimento da inserire. Lo costruiscono l'inserimento rapido e quello completo (F4.5).
@immutable
class NewItem {
  const NewItem({
    required this.name,
    required this.freezerId,
    required this.quantity,
    required this.unit,
    required this.frozenAt,
    required this.volumeLiters,
    this.compartmentId,
    this.category,
    this.reminderAfterDays,
    this.volumeManual = false,
    this.photoPath,
    this.note,
  });

  final String name;
  final int freezerId;
  final int? compartmentId;
  final String? category;
  final double quantity;
  final String unit;
  final CivilDate frozenAt;
  final int? reminderAfterDays;
  final double volumeLiters;
  final bool volumeManual;
  final String? photoPath;
  final String? note;
}

/// Tutte le scritture e le letture dei dati di Full Freezer.
///
/// ⚑ **Perche' un repository e non query sparse nelle pagine**: alcune regole non si
/// possono scrivere come vincoli SQL e vanno rispettate a ogni scrittura, quindi devono
/// passare da una porta sola:
/// 1. `items.freezerId` coincide con il freezer dello scomparto, se c'e' uno scomparto;
/// 2. `items.nameNorm` e' sempre `normalizeName(name)`;
/// 3. ogni entrata, uscita, spostamento o annullamento scrive una riga in `item_movements`.
/// Dimenticarne una in una pagina non darebbe nessun errore: darebbe una ricerca che non
/// trova, un riempimento contato nel freezer sbagliato, una statistica falsa.
class FreezerRepository {
  FreezerRepository(this._db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  int _nowMs() => _clock().toUtc().millisecondsSinceEpoch;

  // ── Freezer ───────────────────────────────────────────────────────────────

  Stream<List<Freezer>> watchFreezers() => (_db.select(_db.freezers)..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.id),
      ]))
      .watch();

  Future<List<Freezer>> allFreezers() => (_db.select(_db.freezers)..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.id),
      ]))
      .get();

  Future<Freezer?> freezerById(int id) =>
      (_db.select(_db.freezers)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Crea un freezer in fondo all'elenco. Il limite del piano gratuito (un freezer) lo
  /// controlla la UI con `FeatureGate`, non il repository: i dati non sanno del Pro.
  Future<int> addFreezer({
    required String name,
    required String modelKey,
    required double capacityLiters,
  }) async {
    final count = await _db.freezers.count().getSingle();
    return _db
        .into(_db.freezers)
        .insert(
          FreezersCompanion.insert(
            name: name.trim(),
            modelKey: modelKey,
            capacityLiters: capacityLiters,
            sortOrder: Value(count),
            createdAt: _nowMs(),
          ),
        );
  }

  /// Rinomina o cambia modello. Cambiare modello cambia la capacita', non gli alimenti.
  Future<void> updateFreezer(int id, {String? name, String? modelKey, double? capacityLiters}) =>
      (_db.update(_db.freezers)..where((t) => t.id.equals(id))).write(
        FreezersCompanion(
          name: name == null ? const Value.absent() : Value(name.trim()),
          modelKey: Value.absentIfNull(modelKey),
          capacityLiters: Value.absentIfNull(capacityLiters),
        ),
      );

  Future<void> setCalibration(int freezerId, double calibration) =>
      (_db.update(_db.freezers)..where((t) => t.id.equals(freezerId))).write(
        FreezersCompanion(calibration: Value(calibration)),
      );

  Future<void> setLastAlertLevel(int freezerId, String? level) =>
      (_db.update(_db.freezers)..where((t) => t.id.equals(freezerId))).write(
        FreezersCompanion(lastAlertLevel: Value(level)),
      );

  /// Cancella un freezer **con tutto quello che contiene** (cascade). La UI chiede conferma
  /// dicendo quanti alimenti spariscono.
  Future<void> deleteFreezer(int id) =>
      (_db.delete(_db.freezers)..where((t) => t.id.equals(id))).go();

  /// Riscrive l'ordine dei freezer secondo la lista di id ricevuta (trascinamento, F4.6).
  Future<void> reorderFreezers(List<int> idsInOrder) => _db.transaction(() async {
    for (var i = 0; i < idsInOrder.length; i++) {
      await (_db.update(_db.freezers)..where((t) => t.id.equals(idsInOrder[i]))).write(
        FreezersCompanion(sortOrder: Value(i)),
      );
    }
  });

  // ── Scomparti ─────────────────────────────────────────────────────────────

  Stream<List<Compartment>> watchCompartments(int freezerId) =>
      (_db.select(_db.compartments)
            ..where((t) => t.freezerId.equals(freezerId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.sortOrder),
              (t) => OrderingTerm(expression: t.id),
            ]))
          .watch();

  /// Tutti gli scomparti di tutti i freezer, per scegliere dove mettere un alimento.
  Stream<List<Compartment>> watchAllCompartments() => (_db.select(_db.compartments)..orderBy([
        (t) => OrderingTerm(expression: t.freezerId),
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.id),
      ]))
      .watch();

  Future<int> addCompartment(int freezerId, String name) async {
    final count =
        await (_db.selectOnly(_db.compartments)
              ..addColumns([_db.compartments.id.count()])
              ..where(_db.compartments.freezerId.equals(freezerId)))
            .map((r) => r.read(_db.compartments.id.count()) ?? 0)
            .getSingle();
    return _db
        .into(_db.compartments)
        .insert(
          CompartmentsCompanion.insert(
            freezerId: freezerId,
            name: name.trim(),
            sortOrder: Value(count),
          ),
        );
  }

  Future<void> renameCompartment(int id, String name) =>
      (_db.update(_db.compartments)..where((t) => t.id.equals(id))).write(
        CompartmentsCompanion(name: Value(name.trim())),
      );

  /// Gli alimenti dello scomparto restano nel freezer, senza scomparto (setNull).
  Future<void> deleteCompartment(int id) =>
      (_db.delete(_db.compartments)..where((t) => t.id.equals(id))).go();

  Future<void> reorderCompartments(List<int> idsInOrder) => _db.transaction(() async {
    for (var i = 0; i < idsInOrder.length; i++) {
      await (_db.update(_db.compartments)..where((t) => t.id.equals(idsInOrder[i]))).write(
        CompartmentsCompanion(sortOrder: Value(i)),
      );
    }
  });

  // ── Alimenti ──────────────────────────────────────────────────────────────

  /// Gli alimenti nel freezer, **il piu' vecchio per primo** (la promessa dell'app).
  ///
  /// A parita' di data vince l'inserito prima, cosi' l'ordine non salta fra un ridisegno e
  /// l'altro. Con [freezerId] null, tutti i freezer.
  Stream<List<Item>> watchStoredItems({int? freezerId}) => _storedQuery(freezerId).watch();

  Future<List<Item>> storedItems({int? freezerId}) => _storedQuery(freezerId).get();

  SimpleSelectStatement<$ItemsTable, Item> _storedQuery(int? freezerId) =>
      _db.select(_db.items)
        ..where((t) {
          final stored = t.status.equals(ItemStatus.stored);
          return freezerId == null ? stored : stored & t.freezerId.equals(freezerId);
        })
        ..orderBy([
          (t) => OrderingTerm(expression: t.frozenAt),
          (t) => OrderingTerm(expression: t.id),
        ]);

  Future<Item?> itemById(int id) =>
      (_db.select(_db.items)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Inserisce un alimento e registra il movimento di entrata.
  Future<int> addItem(NewItem item) => _db.transaction(() async {
    final freezerId = await _freezerFor(item.freezerId, item.compartmentId);
    final now = _nowMs();
    final id = await _db
        .into(_db.items)
        .insert(
          ItemsCompanion.insert(
            freezerId: freezerId,
            compartmentId: Value(item.compartmentId),
            name: item.name.trim(),
            nameNorm: normalizeName(item.name),
            category: Value(item.category),
            quantity: item.quantity,
            unit: item.unit,
            frozenAt: item.frozenAt.toIso(),
            reminderAfterDays: Value(item.reminderAfterDays),
            volumeLiters: item.volumeLiters,
            volumeManual: Value(item.volumeManual),
            photoPath: Value(item.photoPath),
            note: Value(item.note),
            createdAt: now,
          ),
        );
    await _movement(id, MovementKind.stored, at: now, toCompartmentId: item.compartmentId);
    return id;
  });

  /// Salva le modifiche a un alimento esistente, mantenendo le regole del repository.
  Future<void> updateItem(Item item) => _db.transaction(() async {
    final freezerId = await _freezerFor(item.freezerId, item.compartmentId);
    await _db
        .update(_db.items)
        .replace(item.copyWith(freezerId: freezerId, name: item.name.trim(), nameNorm: normalizeName(item.name)));
  });

  /// Consumato (`consumed: true`) o buttato (`false`): l'alimento esce dal freezer ma resta
  /// nel database, per lo storico e le statistiche (F4.7).
  Future<void> removeItem(int id, {required bool consumed}) => _db.transaction(() async {
    final now = _nowMs();
    await (_db.update(_db.items)..where((t) => t.id.equals(id))).write(
      ItemsCompanion(
        status: Value(consumed ? ItemStatus.consumed : ItemStatus.discarded),
        removedAt: Value(now),
      ),
    );
    await _movement(id, consumed ? MovementKind.consumed : MovementKind.discarded, at: now);
  });

  /// Annulla un'uscita (lo snackbar "Annulla" dopo lo swipe, F4.4): l'alimento torna nel
  /// freezer con la sua data di congelamento originale.
  ///
  /// ⚑ Il movimento d'uscita non si cancella: si aggiunge un `restored`. Le statistiche
  /// contano le uscite nette, e uno storico che si riscrive non e' piu' uno storico.
  Future<void> undoRemoval(int id) => _db.transaction(() async {
    await (_db.update(_db.items)..where((t) => t.id.equals(id))).write(
      const ItemsCompanion(status: Value(ItemStatus.stored), removedAt: Value(null)),
    );
    await _movement(id, MovementKind.restored, at: _nowMs());
  });

  /// Sposta un alimento in un altro freezer o scomparto.
  Future<void> moveItem(int id, {required int freezerId, int? compartmentId}) =>
      _db.transaction(() async {
        final before = await itemById(id);
        if (before == null) return;
        final target = await _freezerFor(freezerId, compartmentId);
        await (_db.update(_db.items)..where((t) => t.id.equals(id))).write(
          ItemsCompanion(freezerId: Value(target), compartmentId: Value(compartmentId)),
        );
        await _movement(
          id,
          MovementKind.moved,
          at: _nowMs(),
          fromCompartmentId: before.compartmentId,
          toCompartmentId: compartmentId,
        );
      });

  /// "Ne ho congelato un altro uguale" (F4.5): stessa riga, congelata oggi.
  Future<int> duplicateAsToday(int id, {CivilDate? today}) async {
    final source = await itemById(id);
    if (source == null) throw StateError('Alimento $id inesistente');
    return addItem(
      NewItem(
        name: source.name,
        freezerId: source.freezerId,
        compartmentId: source.compartmentId,
        category: source.category,
        quantity: source.quantity,
        unit: source.unit,
        frozenAt: today ?? CivilDate.today(now: _clock()),
        reminderAfterDays: source.reminderAfterDays,
        volumeLiters: source.volumeLiters,
        volumeManual: source.volumeManual,
        note: source.note,
        // La foto no: e' la foto di quella confezione, non di questa.
      ),
    );
  }

  /// I nomi gia' usati che iniziano con [prefix], **i piu' frequenti per primi** (F4.5).
  ///
  /// ⚑ Si cerca su tutti gli alimenti, anche quelli usciti: lo spezzatino finito la settimana
  /// scorsa e' proprio quello che si sta per congelare di nuovo. A parita' di frequenza vince
  /// il piu' recente. Il prefisso passa da `normalizeName`, quindi "pu" trova "Purè".
  Future<List<String>> suggestNames(String prefix, {int limit = 8}) async {
    final norm = normalizeName(prefix);
    if (norm.isEmpty) return const <String>[];
    final rows = await _db
        .customSelect(
          'SELECT name, COUNT(*) AS n, MAX(created_at) AS last '
          'FROM items WHERE name_norm LIKE ? ESCAPE ? '
          'GROUP BY name_norm ORDER BY n DESC, last DESC LIMIT ?',
          variables: [Variable.withString('${_escapeLike(norm)}%'), Variable.withString(r'\'), Variable.withInt(limit)],
          readsFrom: {_db.items},
        )
        .get();
    return [for (final r in rows) r.read<String>('name')];
  }

  /// Un segnale a ogni modifica di freezer o alimenti: lo usano lo scheduler delle
  /// notifiche (F4.9) e il widget (F4.11), cosi' nessuno deve ricordarsi di chiamarli.
  Stream<void> watchAnyChange() => _db.tableUpdates(
    TableUpdateQuery.onAllTables([_db.freezers, _db.compartments, _db.items]),
  );

  // ── Regole interne ────────────────────────────────────────────────────────

  /// Il freezer giusto per un alimento: quello dello scomparto, se c'e'.
  Future<int> _freezerFor(int freezerId, int? compartmentId) async {
    if (compartmentId == null) return freezerId;
    final c = await (_db.select(_db.compartments)..where((t) => t.id.equals(compartmentId)))
        .getSingleOrNull();
    if (c == null) throw ArgumentError.value(compartmentId, 'compartmentId', 'scomparto inesistente');
    return c.freezerId;
  }

  Future<void> _movement(
    int itemId,
    String kind, {
    required int at,
    int? fromCompartmentId,
    int? toCompartmentId,
  }) => _db
      .into(_db.itemMovements)
      .insert(
        ItemMovementsCompanion.insert(
          itemId: itemId,
          kind: kind,
          at: at,
          fromCompartmentId: Value(fromCompartmentId),
          toCompartmentId: Value(toCompartmentId),
        ),
      );

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
}

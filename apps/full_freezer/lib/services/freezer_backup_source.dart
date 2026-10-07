import 'package:drift/drift.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../domain/text_norm.dart';
import '../features/items/item_photo.dart';

/// Come Full Freezer si esporta e si reimporta (Pro, `FeatureKey.backupRestore`).
///
/// ⚑ **Payload annidato** (freezer -> scomparti -> alimenti), come TrashCan: gli id di riga
/// non significano niente su un altro telefono, e annidando non c'e' niente da rimappare.
/// L'unica eccezione sono le categorie personalizzate, che gli alimenti citano come
/// `custom:<id>`: si esportano con il loro id di allora e all'import si traduce
/// vecchio -> nuovo. Un errore qui darebbe un alimento con la categoria di un altro.
///
/// ⚑ Si esportano **anche gli alimenti usciti**: sono lo storico e le statistiche, cioe' una
/// delle cose per cui si paga il Pro. Un backup che le perde riporta il telefono nuovo a
/// "0 uscite".
class FreezerBackupSource implements BackupSource {
  const FreezerBackupSource(this.db, {this.clock});

  final AppDatabase db;
  /// Per i test: l'ora usata quando il file non porta una data di creazione.
  final DateTime Function()? clock;

  @override
  String get schemaId => 'full_freezer';

  @override
  int get schemaVersion => 1;

  @override
  Future<Map<String, Object?>> exportPayload() async {
    final categories = await db.select(db.customCategories).get();
    final freezers = await (db.select(db.freezers)..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();
    final compartments = await db.select(db.compartments).get();
    final items = await db.select(db.items).get();

    Map<String, Object?> itemJson(Item i) => <String, Object?>{
      'name': i.name,
      'category': i.category,
      'quantity': i.quantity,
      'unit': i.unit,
      'frozenAt': i.frozenAt,
      'reminderAfterDays': i.reminderAfterDays,
      'volumeLiters': i.volumeLiters,
      'volumeManual': i.volumeManual,
      'photoPath': i.photoPath,
      'note': i.note,
      'status': i.status,
      'removedAt': i.removedAt,
      'createdAt': i.createdAt,
    };

    return <String, Object?>{
      'customCategories': [
        for (final c in categories)
          <String, Object?>{
            'id': c.id,
            'name': c.name,
            'iconKey': c.iconKey,
            'colorValue': c.colorValue,
            'defaultReminderDays': c.defaultReminderDays,
          },
      ],
      'freezers': [
        for (final f in freezers)
          <String, Object?>{
            'name': f.name,
            'modelKey': f.modelKey,
            'capacityLiters': f.capacityLiters,
            'calibration': f.calibration,
            'lastAlertLevel': f.lastAlertLevel,
            'sortOrder': f.sortOrder,
            'createdAt': f.createdAt,
            'compartments': [
              for (final c in compartments.where((c) => c.freezerId == f.id))
                <String, Object?>{
                  'name': c.name,
                  'sortOrder': c.sortOrder,
                  'items': [for (final i in items.where((i) => i.compartmentId == c.id)) itemJson(i)],
                },
            ],
            'items': [
              for (final i in items.where((i) => i.freezerId == f.id && i.compartmentId == null)) itemJson(i),
            ],
          },
      ],
    };
  }

  @override
  Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode}) async {
    final now = (clock ?? DateTime.now)().toUtc().millisecondsSinceEpoch;
    await db.transaction(() async {
      if (mode == ImportMode.replaceAll) {
        // Cascade: con i freezer spariscono scomparti, alimenti e movimenti.
        await db.delete(db.freezers).go();
        await db.delete(db.customCategories).go();
      }
      final existingNames = {for (final f in await db.select(db.freezers).get()) f.name};

      // Categorie: vecchio id -> nuovo id.
      final categoryMap = <int, int>{};
      for (final raw in _list(payload['customCategories'])) {
        final c = raw;
        final newId = await db.into(db.customCategories).insert(
          CustomCategoriesCompanion.insert(
            name: c['name']! as String,
            iconKey: c['iconKey']! as String,
            colorValue: (c['colorValue']! as num).toInt(),
            defaultReminderDays: Value((c['defaultReminderDays'] as num?)?.toInt()),
          ),
        );
        categoryMap[(c['id']! as num).toInt()] = newId;
      }

      String? category(Object? raw) {
        final key = raw as String?;
        if (key == null || !key.startsWith('custom:')) return key;
        final old = int.tryParse(key.substring(7));
        final mapped = old == null ? null : categoryMap[old];
        return mapped == null ? null : 'custom:$mapped';
      }

      Future<void> addItem(Map<String, Object?> i, int freezerId, int? compartmentId) async {
        final name = i['name']! as String;
        final id = await db.into(db.items).insert(
          ItemsCompanion.insert(
            freezerId: freezerId,
            compartmentId: Value(compartmentId),
            name: name,
            nameNorm: normalizeName(name),
            category: Value(category(i['category'])),
            quantity: (i['quantity']! as num).toDouble(),
            unit: i['unit']! as String,
            frozenAt: i['frozenAt']! as String,
            reminderAfterDays: Value((i['reminderAfterDays'] as num?)?.toInt()),
            volumeLiters: (i['volumeLiters']! as num).toDouble(),
            volumeManual: Value(i['volumeManual'] as bool? ?? false),
            photoPath: Value(i['photoPath'] as String?),
            note: Value(i['note'] as String?),
            status: Value(i['status'] as String? ?? ItemStatus.stored),
            removedAt: Value((i['removedAt'] as num?)?.toInt()),
            createdAt: (i['createdAt'] as num?)?.toInt() ?? now,
          ),
        );
        // Lo storico dei movimenti si ricostruisce dall'essenziale: entrata e, se c'e',
        // uscita. Gli spostamenti fra scomparti non servono a nessuna statistica.
        final createdAt = (i['createdAt'] as num?)?.toInt() ?? now;
        await db.into(db.itemMovements).insert(
          ItemMovementsCompanion.insert(itemId: id, kind: MovementKind.stored, at: createdAt),
        );
        final status = i['status'] as String?;
        final removedAt = (i['removedAt'] as num?)?.toInt();
        if (status != null && status != ItemStatus.stored && removedAt != null) {
          await db.into(db.itemMovements).insert(
            ItemMovementsCompanion.insert(itemId: id, kind: status, at: removedAt),
          );
        }
      }

      for (final f in _list(payload['freezers'])) {
        final name = f['name']! as String;
        // In unione, un freezer con lo stesso nome e' gia' qui: non si duplica.
        if (mode == ImportMode.mergeKeepExisting && existingNames.contains(name)) continue;
        final freezerId = await db.into(db.freezers).insert(
          FreezersCompanion.insert(
            name: name,
            modelKey: f['modelKey']! as String,
            capacityLiters: (f['capacityLiters']! as num).toDouble(),
            calibration: Value((f['calibration'] as num?)?.toDouble() ?? 1),
            lastAlertLevel: Value(f['lastAlertLevel'] as String?),
            sortOrder: Value((f['sortOrder'] as num?)?.toInt() ?? 0),
            createdAt: (f['createdAt'] as num?)?.toInt() ?? now,
          ),
        );
        for (final c in _list(f['compartments'])) {
          final compartmentId = await db.into(db.compartments).insert(
            CompartmentsCompanion.insert(
              freezerId: freezerId,
              name: c['name']! as String,
              sortOrder: Value((c['sortOrder'] as num?)?.toInt() ?? 0),
            ),
          );
          for (final i in _list(c['items'])) {
            await addItem(i, freezerId, compartmentId);
          }
        }
        for (final i in _list(f['items'])) {
          await addItem(i, freezerId, null);
        }
      }
    });
  }

  @override
  Future<List<String>> imagePaths() async {
    final items = await (db.select(db.items)..where((t) => t.photoPath.isNotNull())).get();
    return [
      for (final i in items) ...[i.photoPath!, thumbPathOf(i.photoPath!)],
    ];
  }

  @override
  Future<Map<String, int>> counts() async {
    final items = await db.select(db.items).get();
    return <String, int>{
      'freezers': (await db.select(db.freezers).get()).length,
      'items': items.where((i) => i.status == ItemStatus.stored).length,
      'history': items.where((i) => i.status != ItemStatus.stored).length,
    };
  }

  static List<Map<String, Object?>> _list(Object? raw) =>
      raw is List ? [for (final e in raw) if (e is Map) e.cast<String, Object?>()] : const [];
}

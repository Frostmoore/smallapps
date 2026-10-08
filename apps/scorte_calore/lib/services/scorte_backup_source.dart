import 'package:drift/drift.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../domain/fuel_source.dart';
import '../domain/fuel_units.dart';
import '../domain/quantity_converter.dart';

/// Come Scorte Calore si esporta e si reimporta (F5.11). Creare il backup e' Pro
/// (`FeatureKey.backupRestore`), ripristinarlo e' gratis: vedi `restoreBackup` in
/// `features/settings/data_section.dart`.
///
/// ⚑ **Payload annidato** (fonti -> misurazioni, fonti -> acquisti), come Full Freezer e
/// TrashCan: gli id di riga non significano niente su un altro telefono, e annidando non c'e'
/// niente da rimappare.
///
/// ⚑ **Le misurazioni portano `enteredAs` e `rawInput`**, non solo la quantita': sono la
/// ragione per cui le misure in percentuale si possono ricalcolare quando cambia la capacita'
/// del serbatoio (F5.2). Un backup che le appiattisse in quantita' assolute funzionerebbe il
/// giorno del ripristino e tradirebbe l'utente alla prima modifica della fonte.
///
/// ☠ **I promemoria del calendario (`calendar_reminders`) restano fuori di proposito.** La riga
/// contiene l'id di un evento e di un calendario che esistono **solo sul telefono dove sono
/// stati creati** (`device_calendar`): portata su un altro telefono punterebbe al nulla, o
/// peggio a un evento di un altro calendario con lo stesso id, e l'app lo aggiornerebbe o lo
/// cancellerebbe. Dopo il ripristino il promemoria si rimette dalla fonte.
///
/// ☠ Conseguenza da ricordare per chi scrive il calendario (F5.10): "sostituisci tutto"
/// cancella le fonti, e con loro (cascade) le righe di `calendar_reminders`, ma **non** gli
/// eventi nel calendario del telefono, che restano orfani. Chi chiama [importPayload] con
/// `ImportMode.replaceAll` su un telefono che ha promemoria dovrebbe prima toglierli con
/// `CalendarSyncService.deleteEvent` (che al 2026-10-08 non esiste ancora).
class ScorteBackupSource implements BackupSource {
  const ScorteBackupSource(this.db, {this.clock});

  final AppDatabase db;

  /// Per i test: l'ora usata quando il file non porta una data di creazione della fonte.
  final DateTime Function()? clock;

  /// L'identificativo dei backup di Scorte Calore, anche per riconoscerli prima di
  /// chiedere come ripristinarli (`restoreBackup`).
  static const String id = 'scorte_calore';

  @override
  String get schemaId => id;

  @override
  int get schemaVersion => 1;

  @override
  Future<Map<String, Object?>> exportPayload() async {
    final sources = await (db.select(db.fuelSources)
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .get();
    final measurements = await (db.select(db.stockMeasurements)
          ..orderBy([(t) => OrderingTerm(expression: t.date)]))
        .get();
    final purchases = await (db.select(db.purchases)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .get();

    return <String, Object?>{
      'sources': [
        for (final s in sources)
          <String, Object?>{
            'name': s.name,
            'fuelType': s.fuelType,
            'unit': s.unit,
            'unitWeightKg': s.unitWeightKg,
            'tankCapacity': s.tankCapacity,
            'usableFraction': s.usableFraction,
            'warningDays': s.warningDays,
            'costPerUnitCents': s.costPerUnitCents,
            // Anche le fonti disattivate: sono lo storico (la stufa dismessa e la sua spesa).
            'active': s.active,
            'sortOrder': s.sortOrder,
            'createdAt': s.createdAt,
            'measurements': [
              for (final m in measurements.where((m) => m.fuelSourceId == s.id))
                <String, Object?>{
                  'date': m.date,
                  'quantity': m.quantity,
                  'enteredAs': m.enteredAs,
                  'rawInput': m.rawInput,
                  'note': m.note,
                },
            ],
            'purchases': [
              for (final p in purchases.where((p) => p.fuelSourceId == s.id))
                <String, Object?>{
                  'date': p.date,
                  'quantity': p.quantity,
                  'totalCostCents': p.totalCostCents,
                  'supplier': p.supplier,
                  'note': p.note,
                },
            ],
          },
      ],
    };
  }

  /// Scrive il contenuto di [payload] nel database, tutto in una transazione.
  ///
  /// - `replaceAll`: cancella tutte le fonti (e in cascata misurazioni, acquisti e righe dei
  ///   promemoria) e mette quelle del backup con il loro ordine.
  /// - `mergeKeepExisting`: aggiunge in fondo le fonti del backup **saltando quelle con lo
  ///   stesso nome** di una gia' presente (con le sue misure e i suoi acquisti): due "Stufa
  ///   soggiorno" con due storie diverse darebbero due stime per la stessa stufa.
  ///
  /// ☠ Lancia [FormatException] (mai un `Error`) su un file con chiavi sconosciute o campi del
  /// tipo sbagliato: `BackupService.restore` intercetta solo le `Exception`, e un `TypeError`
  /// da un cast arriverebbe all'utente come crash invece che come "file rovinato". La
  /// transazione intanto e' gia' annullata: niente ripristini a meta'.
  @override
  Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode}) async {
    final now = (clock ?? DateTime.now)().toUtc().millisecondsSinceEpoch;
    try {
      await db.transaction(() async {
        if (mode == ImportMode.replaceAll) {
          // Cascade: con le fonti spariscono misurazioni, acquisti e calendar_reminders.
          await db.delete(db.fuelSources).go();
        }
        final existing = await db.select(db.fuelSources).get();
        final existingNames = {for (final s in existing) s.name};
        // In unione le fonti nuove vanno in fondo, dopo quelle che l'utente ha gia' ordinato.
        var nextOrder = existing.isEmpty
            ? 0
            : existing.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

        for (final s in _list(payload['sources'])) {
          final name = s['name']! as String;
          if (mode == ImportMode.mergeKeepExisting && existingNames.contains(name)) continue;

          final fuelType = FuelType.byKey(s['fuelType'] as String?);
          final unit = s['unit'] as String?;
          if (fuelType == null || unit == null || !FuelUnits.isAllowed(fuelType, unit)) {
            throw FormatException('Fonte "$name": combustibile o unita\' sconosciuti ($fuelType, $unit)');
          }
          final sortOrder = mode == ImportMode.replaceAll
              ? (s['sortOrder'] as num?)?.toInt() ?? nextOrder
              : nextOrder;
          nextOrder = (sortOrder > nextOrder ? sortOrder : nextOrder) + 1;

          final row = await db
              .into(db.fuelSources)
              .insertReturning(
                FuelSourcesCompanion.insert(
                  name: name,
                  fuelType: fuelType.key,
                  unit: unit,
                  unitWeightKg: Value((s['unitWeightKg'] as num?)?.toDouble()),
                  tankCapacity: Value((s['tankCapacity'] as num?)?.toDouble()),
                  usableFraction:
                      (s['usableFraction'] as num?)?.toDouble() ?? fuelType.defaultUsableFraction,
                  warningDays: Value(
                    (s['warningDays'] as num?)?.toInt() ?? FuelType.defaultWarningDays,
                  ),
                  costPerUnitCents: Value((s['costPerUnitCents'] as num?)?.toInt()),
                  active: Value(s['active'] as bool? ?? true),
                  sortOrder: Value(sortOrder),
                  createdAt: (s['createdAt'] as num?)?.toInt() ?? now,
                ),
              );

          // ⚑ La quantita' delle misure in percentuale si ricalcola dal valore grezzo con la
          // configurazione appena scritta, come fa `ScorteRepository.upsertMeasurement`: la
          // regola "quantita' = fromPercentage(rawInput)" vale anche per un file scritto a
          // mano o da una versione che arrotondava diversamente.
          final converter = QuantityConverter(row.toSpec());
          for (final m in _list(s['measurements'])) {
            final enteredAs = EnteredAs.byKey(m['enteredAs'] as String?);
            if (enteredAs == null) {
              throw FormatException('Fonte "$name": misura con enteredAs sconosciuto (${m['enteredAs']})');
            }
            final quantity = (m['quantity']! as num).toDouble();
            final measurement = converter.recompute(
              Measurement(
                date: CivilDate.parse(m['date']! as String),
                quantity: quantity,
                enteredAs: enteredAs,
                rawInput: (m['rawInput'] as num?)?.toDouble() ?? quantity,
              ),
            );
            await db
                .into(db.stockMeasurements)
                .insert(
                  StockMeasurementsCompanion.insert(
                    fuelSourceId: row.id,
                    date: measurement.date.toIso(),
                    quantity: measurement.quantity,
                    enteredAs: measurement.enteredAs.key,
                    rawInput: measurement.rawInput,
                    note: Value(m['note'] as String?),
                  ),
                  // Una misura al giorno (UNIQUE fonte+data): un file con due misure nella
                  // stessa data tiene l'ultima, come fa l'app.
                  mode: InsertMode.insertOrReplace,
                );
          }

          for (final p in _list(s['purchases'])) {
            await db
                .into(db.purchases)
                .insert(
                  PurchasesCompanion.insert(
                    fuelSourceId: row.id,
                    date: CivilDate.parse(p['date']! as String).toIso(),
                    quantity: (p['quantity']! as num).toDouble(),
                    totalCostCents: Value((p['totalCostCents'] as num?)?.toInt()),
                    supplier: Value(p['supplier'] as String?),
                    note: Value(p['note'] as String?),
                  ),
                );
          }
        }
      });
    } on TypeError catch (error) {
      throw FormatException('Backup di Scorte Calore malformato: $error');
    }
  }

  /// Scorte Calore non ha foto: il backup e' un JSON solo.
  @override
  Future<List<String>> imagePaths() async => const <String>[];

  /// Quello che il riepilogo mostra prima del ripristino (`backup_restoreSummary`).
  @override
  Future<Map<String, int>> counts() async => <String, int>{
    'sources': await db.fuelSources.count().getSingle(),
    'measurements': await db.stockMeasurements.count().getSingle(),
    'purchases': await db.purchases.count().getSingle(),
  };

  static List<Map<String, Object?>> _list(Object? raw) =>
      raw is List ? [for (final e in raw) if (e is Map) e.cast<String, Object?>()] : const [];
}

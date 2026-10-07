import 'dart:convert';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/data/database.dart';
import 'package:full_freezer/data/freezer_repository.dart';
import 'package:full_freezer/domain/units.dart';
import 'package:full_freezer/l10n/generated/app_localizations.dart';
import 'package:full_freezer/services/csv_export.dart';
import 'package:full_freezer/services/freezer_backup_source.dart';
import 'package:micro_core/micro_core.dart';

/// F4.10: il backup riporta tutto (anche lo storico e le categorie personalizzate) e il CSV
/// e' leggibile da Excel in italiano.
void main() {
  // Due database in memoria distinti (telefono vecchio e nuovo): l'avviso di drift sulle
  // istanze multiple riguarda chi condivide lo stesso file, non questo caso.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase origine;
  late FreezerRepository repo;
  final now = DateTime.utc(2026, 10, 7, 12);

  setUp(() {
    origine = AppDatabase.memory();
    repo = FreezerRepository(origine, clock: () => now);
  });
  tearDown(() => origine.close());

  NewItem alimento(int freezerId, String name, {int? compartmentId, String? category, String? photo}) => NewItem(
    name: name,
    freezerId: freezerId,
    compartmentId: compartmentId,
    category: category,
    quantity: 1.5,
    unit: Units.portions,
    frozenAt: CivilDate.parse('2026-09-27'),
    volumeLiters: 1.2,
    photoPath: photo,
    note: 'per il ragù; domenica',
  );

  /// Un telefono "pieno": due freezer, uno scomparto, una categoria personalizzata, un
  /// alimento con foto e uno gia' consumato.
  Future<void> riempi() async {
    final cucina = await repo.addFreezer(name: 'Cucina', modelKey: 'combi_compact', capacityLiters: 70);
    final garage = await repo.addFreezer(name: 'Garage', modelKey: 'chest_medium', capacityLiters: 200);
    final cassetto = await repo.addCompartment(cucina, 'Cassetto alto');
    final cat = await origine.into(origine.customCategories).insert(
      CustomCategoriesCompanion.insert(name: 'Selvaggina', iconKey: 'meat', colorValue: 0xFF884400, defaultReminderDays: const Value(200)),
    );
    await repo.addItem(alimento(cucina, 'Cinghiale', compartmentId: cassetto, category: 'custom:$cat', photo: 'images/a.jpg'));
    await repo.addItem(alimento(garage, 'Piselli'));
    final mangiato = await repo.addItem(alimento(garage, 'Pizza'));
    await repo.removeItem(mangiato, consumed: true);
  }

  /// Il payload passa da JSON come nel file vero: interi e double tornano `num`.
  Future<Map<String, Object?>> esporta() async =>
      (jsonDecode(jsonEncode(await FreezerBackupSource(origine).exportPayload())) as Map).cast<String, Object?>();

  group('backup', () {
    test('sostituisci tutto riporta freezer, scomparti, alimenti, storico e foto', () async {
      await riempi();
      final payload = await esporta();

      final destinazione = AppDatabase.memory();
      addTearDown(destinazione.close);
      // Una categoria gia' presente sposta gli id: la rimappatura deve accorgersene.
      await destinazione.into(destinazione.customCategories).insert(
        CustomCategoriesCompanion.insert(name: 'Vecchia', iconKey: 'box', colorValue: 0),
      );
      final source = FreezerBackupSource(destinazione, clock: () => now);
      await source.importPayload(payload, mode: ImportMode.replaceAll);

      final freezers = await destinazione.select(destinazione.freezers).get();
      expect(freezers.map((f) => f.name), unorderedEquals(['Cucina', 'Garage']));
      final categorie = await destinazione.select(destinazione.customCategories).get();
      expect(categorie.map((c) => c.name), ['Selvaggina'], reason: 'sostituisci tutto cancella le categorie di prima');

      final items = await destinazione.select(destinazione.items).get();
      final cinghiale = items.singleWhere((i) => i.name == 'Cinghiale');
      expect(cinghiale.category, 'custom:${categorie.single.id}');
      expect(cinghiale.compartmentId, isNotNull);
      expect(cinghiale.photoPath, 'images/a.jpg');
      expect(cinghiale.quantity, 1.5);
      expect(cinghiale.volumeLiters, 1.2);

      final pizza = items.singleWhere((i) => i.name == 'Pizza');
      expect(pizza.status, ItemStatus.consumed);
      expect(pizza.removedAt, isNotNull);

      final counts = await source.counts();
      expect(counts, {'freezers': 2, 'items': 2, 'history': 1});
      expect(await source.imagePaths(), contains('images/a.jpg'));

      final movimenti = await destinazione.select(destinazione.itemMovements).get();
      expect(movimenti.where((m) => m.itemId == pizza.id).map((m) => m.kind), [MovementKind.stored, MovementKind.consumed]);
    });

    test('aggiungi salta i freezer con lo stesso nome e tiene quelli che ci sono', () async {
      await riempi();
      final payload = await esporta();

      final destinazione = AppDatabase.memory();
      addTearDown(destinazione.close);
      final altro = FreezerRepository(destinazione, clock: () => now);
      final cucina = await altro.addFreezer(name: 'Cucina', modelKey: 'fridge_top', capacityLiters: 50);
      await altro.addItem(alimento(cucina, 'Gelato'));

      await FreezerBackupSource(destinazione).importPayload(payload, mode: ImportMode.mergeKeepExisting);

      final freezers = await destinazione.select(destinazione.freezers).get();
      expect(freezers.map((f) => f.name), unorderedEquals(['Cucina', 'Garage']));
      expect(freezers.singleWhere((f) => f.name == 'Cucina').capacityLiters, 50, reason: 'quello del telefono resta');
      final nomi = (await destinazione.select(destinazione.items).get()).map((i) => i.name);
      expect(nomi, unorderedEquals(['Gelato', 'Piselli', 'Pizza']));
    });
  });

  group('CSV', () {
    test('una riga per alimento, con giorni nel freezer, freezer e scomparto', () async {
      await riempi();
      final l = lookupL(const Locale('it'));
      final csv = buildStoredCsv(
        l: l,
        items: await repo.storedItems(),
        freezers: await repo.allFreezers(),
        compartments: {
          for (final f in await repo.allFreezers()) f.id: await repo.watchCompartments(f.id).first,
        },
        today: CivilDate.parse('2026-10-07'),
      ).build();

      expect(csv.startsWith('﻿'), isTrue, reason: 'senza BOM Excel rovina gli accenti');
      final righe = const LineSplitter().convert(csv.substring(1));
      expect(righe.first, startsWith('Nome;Categoria;Quantità;'));
      expect(righe, hasLength(3), reason: 'la pizza consumata non e\' nel freezer');
      final cinghiale = righe.singleWhere((r) => r.startsWith('Cinghiale'));
      expect(cinghiale, contains(';1,5;'));
      expect(cinghiale, contains(';2026-09-27;10;Cucina;Cassetto alto;'));
      // Il punto e virgola nella nota non deve spezzare la colonna.
      expect(cinghiale, endsWith('"per il ragù; domenica"'));
    });
  });
}

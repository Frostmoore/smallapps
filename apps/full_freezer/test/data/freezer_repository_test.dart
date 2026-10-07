import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/data/database.dart';
import 'package:full_freezer/data/freezer_repository.dart';
import 'package:full_freezer/domain/categories.dart';
import 'package:full_freezer/domain/units.dart';
import 'package:micro_core/micro_core.dart';
// I vincoli CHECK violati arrivano come eccezione di sqlite3, non di drift.
import 'package:sqlite3/sqlite3.dart' show SqliteException;

/// F4.2: le regole che il repository deve far rispettare a ogni scrittura.
void main() {
  late AppDatabase db;
  late FreezerRepository repo;
  var now = DateTime.utc(2026, 10, 6, 12);

  setUp(() {
    db = AppDatabase.memory();
    now = DateTime.utc(2026, 10, 6, 12);
    repo = FreezerRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  Future<int> freezer([String name = 'Cucina']) =>
      repo.addFreezer(name: name, modelKey: 'combi_compact', capacityLiters: 70);

  NewItem alimento(
    int freezerId, {
    String name = 'Spezzatino',
    String frozenAt = '2026-09-01',
    int? compartmentId,
  }) => NewItem(
    name: name,
    freezerId: freezerId,
    compartmentId: compartmentId,
    quantity: 2,
    unit: Units.portions,
    frozenAt: CivilDate.parse(frozenAt),
    volumeLiters: 0.8,
  );

  group('freezer', () {
    test('un freezer nuovo parte con taratura 1 e avviso "vuoto" gia\' dato', () async {
      final id = await freezer();
      final f = (await repo.freezerById(id))!;
      expect(f.calibration, 1.0);
      // F4.9: un freezer appena creato e' vuoto e non deve mai ricevere "quasi vuoto".
      expect(f.lastAlertLevel, 'empty');
      expect(f.capacityLiters, 70);
    });

    test('i freezer si accodano e si riordinano', () async {
      final a = await freezer('A');
      final b = await freezer('B');
      expect((await repo.allFreezers()).map((f) => f.name), ['A', 'B']);
      await repo.reorderFreezers([b, a]);
      expect((await repo.allFreezers()).map((f) => f.name), ['B', 'A']);
    });

    test('una capacita\' zero o negativa e\' rifiutata dal database', () async {
      expect(
        () => repo.addFreezer(name: 'X', modelKey: 'custom', capacityLiters: 0),
        throwsA(isA<SqliteException>()),
      );
    });

    test('le foreign key sono attive: cancellare un freezer porta via i suoi alimenti', () async {
      // Senza PRAGMA foreign_keys questo lascerebbe un alimento orfano, contato nel
      // riempimento di un freezer che non esiste piu'.
      final f = await freezer();
      await repo.addItem(alimento(f));
      await repo.deleteFreezer(f);
      expect(await db.select(db.items).get(), isEmpty);
      expect(await db.select(db.itemMovements).get(), isEmpty);
    });
  });

  group('scomparti', () {
    test('cancellare uno scomparto lascia gli alimenti nel freezer, senza scomparto', () async {
      final f = await freezer();
      final c = await repo.addCompartment(f, 'Cassetto 1');
      final id = await repo.addItem(alimento(f, compartmentId: c));
      await repo.deleteCompartment(c);
      final item = (await repo.itemById(id))!;
      expect(item.compartmentId, isNull);
      expect(item.freezerId, f);
      expect(item.status, ItemStatus.stored);
    });

    test('il freezer di un alimento e\' quello del suo scomparto, anche se si sbaglia', () async {
      final cucina = await freezer('Cucina');
      final garage = await freezer('Garage');
      final cassetto = await repo.addCompartment(garage, 'Cassetto');
      // Chi chiama passa il freezer sbagliato: il repository lo corregge.
      final id = await repo.addItem(alimento(cucina, compartmentId: cassetto));
      expect((await repo.itemById(id))!.freezerId, garage);
    });

    test('uno scomparto inesistente e\' un errore, non un alimento nel posto sbagliato', () async {
      final f = await freezer();
      expect(() => repo.addItem(alimento(f, compartmentId: 999)), throwsArgumentError);
    });
  });

  group('alimenti', () {
    test('il piu\' vecchio per primo, e a parita\' di data l\'inserito prima', () async {
      final f = await freezer();
      await repo.addItem(alimento(f, name: 'Nuovo', frozenAt: '2026-10-01'));
      await repo.addItem(alimento(f, name: 'Vecchio', frozenAt: '2026-03-15'));
      await repo.addItem(alimento(f, name: 'Pari A', frozenAt: '2026-06-01'));
      await repo.addItem(alimento(f, name: 'Pari B', frozenAt: '2026-06-01'));
      expect((await repo.storedItems()).map((i) => i.name), ['Vecchio', 'Pari A', 'Pari B', 'Nuovo']);
    });

    test('il filtro per freezer mostra solo quel freezer', () async {
      final a = await freezer('A');
      final b = await freezer('B');
      await repo.addItem(alimento(a, name: 'In A'));
      await repo.addItem(alimento(b, name: 'In B'));
      expect((await repo.storedItems(freezerId: b)).map((i) => i.name), ['In B']);
    });

    test('nameNorm e\' sempre il nome normalizzato, anche dopo una modifica', () async {
      final f = await freezer();
      final id = await repo.addItem(alimento(f, name: '  Purè di PATATE '));
      var item = (await repo.itemById(id))!;
      expect(item.name, 'Purè di PATATE');
      expect(item.nameNorm, 'pure di patate');
      await repo.updateItem(item.copyWith(name: 'Ragù'));
      item = (await repo.itemById(id))!;
      expect(item.nameNorm, 'ragu');
    });

    test('quantita\' e ingombro devono essere positivi', () async {
      final f = await freezer();
      final zero = NewItem(
        name: 'X',
        freezerId: f,
        quantity: 0,
        unit: Units.pieces,
        frozenAt: CivilDate(2026, 10, 6),
        volumeLiters: 0.5,
      );
      expect(() => repo.addItem(zero), throwsA(isA<SqliteException>()));
    });

    test('consumato: esce dal freezer, resta nel database, con il movimento', () async {
      final f = await freezer();
      final id = await repo.addItem(alimento(f));
      now = DateTime.utc(2026, 10, 7, 19);
      await repo.removeItem(id, consumed: true);
      expect(await repo.storedItems(), isEmpty);
      final item = (await repo.itemById(id))!;
      expect(item.status, ItemStatus.consumed);
      expect(item.removedAt, now.millisecondsSinceEpoch);
      final kinds = (await db.select(db.itemMovements).get()).map((m) => m.kind);
      expect(kinds, [MovementKind.stored, MovementKind.consumed]);
    });

    test('annullare l\'uscita lo rimette dentro con la data di congelamento originale', () async {
      final f = await freezer();
      final id = await repo.addItem(alimento(f, frozenAt: '2026-02-01'));
      await repo.removeItem(id, consumed: false);
      await repo.undoRemoval(id);
      final item = (await repo.itemById(id))!;
      expect(item.status, ItemStatus.stored);
      expect(item.removedAt, isNull);
      expect(item.frozenAt, '2026-02-01');
      // Lo storico non si riscrive: si aggiunge "restored".
      final kinds = (await db.select(db.itemMovements).get()).map((m) => m.kind);
      expect(kinds, [MovementKind.stored, MovementKind.discarded, MovementKind.restored]);
    });

    test('spostare registra da dove a dove', () async {
      final f = await freezer();
      final c1 = await repo.addCompartment(f, 'Uno');
      final c2 = await repo.addCompartment(f, 'Due');
      final id = await repo.addItem(alimento(f, compartmentId: c1));
      await repo.moveItem(id, freezerId: f, compartmentId: c2);
      expect((await repo.itemById(id))!.compartmentId, c2);
      final moved = (await db.select(db.itemMovements).get()).last;
      expect(moved.kind, MovementKind.moved);
      expect(moved.fromCompartmentId, c1);
      expect(moved.toCompartmentId, c2);
    });

    test('"ne ho congelato un altro uguale" copia tutto tranne data e foto', () async {
      final f = await freezer();
      final id = await repo.addItem(
        NewItem(
          name: 'Lasagne',
          freezerId: f,
          quantity: 4,
          unit: Units.portions,
          frozenAt: CivilDate(2026, 5, 1),
          volumeLiters: 2.5,
          volumeManual: true,
          photoPath: 'photos/lasagne.jpg',
          category: 'prepared',
        ),
      );
      final copia = (await repo.itemById(await repo.duplicateAsToday(id)))!;
      expect(copia.name, 'Lasagne');
      expect(copia.quantity, 4);
      expect(copia.volumeLiters, 2.5);
      expect(copia.volumeManual, isTrue);
      expect(copia.category, 'prepared');
      expect(copia.frozenAt, '2026-10-06');
      expect(copia.photoPath, isNull);
    });
  });

  group('autocompletamento', () {
    test('i nomi piu\' usati per primi, anche fra quelli gia\' usciti', () async {
      final f = await freezer();
      for (var i = 0; i < 3; i++) {
        final id = await repo.addItem(alimento(f, name: 'Spezzatino'));
        await repo.removeItem(id, consumed: true);
      }
      await repo.addItem(alimento(f, name: 'Spinaci'));
      await repo.addItem(alimento(f, name: 'Pane'));
      expect(await repo.suggestNames('sp'), ['Spezzatino', 'Spinaci']);
    });

    test('ignora maiuscole e accenti nel prefisso', () async {
      final f = await freezer();
      await repo.addItem(alimento(f, name: 'Purè'));
      expect(await repo.suggestNames('PU'), ['Purè']);
    });

    test('un prefisso vuoto non suggerisce niente, e % non e\' un jolly', () async {
      final f = await freezer();
      await repo.addItem(alimento(f, name: 'Pane'));
      expect(await repo.suggestNames('  '), isEmpty);
      expect(await repo.suggestNames('%'), isEmpty);
    });
  });

  test('watchAnyChange avvisa a ogni scrittura di freezer o alimenti', () async {
    final f = await freezer();
    final segnali = <void>[];
    final sub = repo.watchAnyChange().listen(segnali.add);
    await repo.addItem(alimento(f));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(segnali, isNotEmpty);
    await sub.cancel();
  });

  group('categorie personalizzate', () {
    test('si creano, si rinominano e si elencano in ordine alfabetico', () async {
      final b = await repo.addCustomCategory(name: ' Selvaggina ', iconKey: 'meat', defaultReminderDays: 200);
      await repo.addCustomCategory(name: 'Pappe', iconKey: 'prepared');
      expect((await repo.watchCustomCategories().first).map((c) => c.name), ['Pappe', 'Selvaggina']);
      await repo.updateCustomCategory(b, name: 'Cacciagione', iconKey: 'poultry', defaultReminderDays: null);
      final c = (await repo.watchCustomCategories().first).first;
      expect((c.name, c.iconKey, c.defaultReminderDays), ('Cacciagione', 'poultry', null));
    });

    test('cancellarla lascia gli alimenti senza categoria, non con una chiave orfana', () async {
      final f = await freezer();
      final cat = await repo.addCustomCategory(name: 'Pappe', iconKey: 'prepared');
      final id = await repo.addItem(
        NewItem(
          name: 'Pappa',
          freezerId: f,
          category: customCategoryKey(cat),
          quantity: 1,
          unit: Units.portions,
          frozenAt: CivilDate.parse('2026-10-01'),
          volumeLiters: 0.2,
        ),
      );
      await repo.deleteCustomCategory(cat);
      expect((await repo.itemById(id))!.category, isNull);
      expect(await repo.watchCustomCategories().first, isEmpty);
    });

    test('la chiave custom:<id> va e torna', () {
      expect(customCategoryKey(7), 'custom:7');
      expect(customCategoryId('custom:7'), 7);
      expect(customCategoryId('fish'), isNull);
      expect(customCategoryId(null), isNull);
    });
  });
}

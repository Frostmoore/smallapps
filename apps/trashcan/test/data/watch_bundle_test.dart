// StreamQueue serve a consumare le emissioni una alla volta: con un semplice listen non si
// distingue "lo stream non ha riemesso" da "ha riemesso ma dopo la fine del test".
import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:trashcan/data/database.dart';
import 'package:trashcan/data/repository.dart';
import 'package:trashcan/domain/recurrence.dart';

/// Lo stream del bundle deve reagire a **tutte** le tabelle che lo compongono.
///
/// ☠ Questo file esiste per un difetto vero, trovato provando l'app sull'emulatore:
/// `watchBundle` osservava soltanto `collection_calendars` e leggeva tipi, regole ed
/// eccezioni con `get()` dentro la callback. Drift invalida uno stream in base alle tabelle
/// della query osservata, non a quelle lette dentro la callback, quindi cambiare una regola
/// scriveva sul database senza cambiare niente sullo schermo fino al riavvio. Nessun errore
/// in console: solo un'app che sembra ignorare l'utente.
///
/// Ogni test qui sotto corrisponde a un'azione che nell'app non aggiornava la schermata.
void main() {
  late AppDatabase db;
  late TrashcanRepository repo;
  late int calendarId;

  setUp(() async {
    db = AppDatabase.memory();
    repo = TrashcanRepository(db);
    calendarId = await repo.createCalendar(name: 'Casa');
  });
  tearDown(() => db.close());

  /// Attende la prossima emissione dello stream dopo aver eseguito [action].
  ///
  /// La prima emissione (lo stato iniziale) viene consumata prima di agire, altrimenti il
  /// test passerebbe anche con uno stream che non reagisce a niente.
  Future<CalendarBundle?> afterAction(Future<void> Function() action) async {
    final events = StreamQueue(db.watchBundle(calendarId));
    await events.next; // stato iniziale
    final pending = events.next;
    await action();
    final result = await pending.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TestFailure(
        'watchBundle non ha riemesso: la schermata resterebbe ferma dopo la modifica',
      ),
    );
    await events.cancel();
    return result;
  }

  test('riemette quando si aggiunge un tipo di rifiuto', () async {
    final bundle = await afterAction(
      () => repo.createWasteType(
        calendarId: calendarId,
        name: 'Organico',
        iconKey: 'compost',
        colorValue: 0xFF6D8B3C,
      ),
    );
    expect(bundle!.wasteTypes, hasLength(1));
  });

  test('riemette quando cambia la regola di un tipo', () async {
    final typeId = await repo.createWasteType(
      calendarId: calendarId,
      name: 'Carta',
      iconKey: 'paper',
      colorValue: 0xFF2E6DA4,
    );
    await repo.setWeeklyRule(wasteTypeId: typeId, weekdays: {DateTime.monday});

    final bundle = await afterAction(
      () => repo.setRule(
        wasteTypeId: typeId,
        recurrence: EveryNWeeksRecurrence(
          weekdays: {DateTime.wednesday},
          intervalWeeks: 2,
          anchorDate: CivilDate.today(),
          startDate: CivilDate.today(),
        ),
      ),
    );
    expect(bundle!.rules.single.recurrence, isA<EveryNWeeksRecurrence>());
  });

  test('riemette quando si aggiunge un-eccezione', () async {
    final typeId = await repo.createWasteType(
      calendarId: calendarId,
      name: 'Vetro',
      iconKey: 'glass',
      colorValue: 0xFF3B7A6B,
    );
    await repo.setWeeklyRule(wasteTypeId: typeId, weekdays: {DateTime.saturday});

    final bundle = await afterAction(
      () => repo.skipCollection(wasteTypeId: typeId, date: CivilDate.today().addDays(7)),
    );
    expect(bundle!.rules.single.exceptions, hasLength(1));
  });

  test('riemette quando si riordina la lista dei tipi', () async {
    final first = await repo.createWasteType(
      calendarId: calendarId,
      name: 'Uno',
      iconKey: 'trash',
      colorValue: 0xFF555555,
    );
    final second = await repo.createWasteType(
      calendarId: calendarId,
      name: 'Due',
      iconKey: 'trash',
      colorValue: 0xFF555555,
    );

    final bundle = await afterAction(() => repo.reorderWasteTypes([second, first]));
    expect(bundle!.wasteTypes.map((t) => t.name), ['Due', 'Uno']);
  });

  test('riemette quando si rinomina il calendario', () async {
    final bundle = await afterAction(() => repo.renameCalendar(calendarId, 'Casa al mare'));
    expect(bundle!.calendar.name, 'Casa al mare');
  });
}

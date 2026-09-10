import 'package:drift/drift.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';

/// Come TrashCan si esporta e si reimporta.
///
/// ⚑ **Perché il payload è annidato e non una copia delle tabelle**: gli id di riga non
/// significano niente fuori da questo dispositivo. Esportando calendari, tipi, regole ed
/// eccezioni come quattro elenchi piatti legati da id, l'import dovrebbe rimappare ogni
/// riferimento, e un solo errore di rimappatura produce una regola attaccata al tipo di
/// rifiuto sbagliato: nessun errore visibile, solo un calendario che dice bugie. Annidando
/// i figli dentro i genitori il problema non esiste, perché non c'è nessun id da rimappare.
///
/// ⚑ **Perché lo stesso oggetto serve backup e condivisione**: la spec distingue il backup
/// completo (a pagamento) dalla condivisione di un singolo calendario (gratuita), ma sono
/// lo stesso formato con un filtro diverso. Due formati vorrebbero dire due parser, due
/// versioni di schema e due modi di sbagliare; e chi riceve un calendario condiviso deve
/// poterlo aprire anche se chi glielo manda ha il Pro e lui no.
class TrashcanBackupSource implements BackupSource {
  const TrashcanBackupSource(this.db, {this.onlyCalendarId});

  final AppDatabase db;

  /// Se valorizzato, si esporta **solo** questo calendario: è la condivisione.
  final int? onlyCalendarId;

  @override
  String get schemaId => 'trashcan';

  @override
  int get schemaVersion => 1;

  @override
  Future<Map<String, Object?>> exportPayload() async {
    final calendars = await db.allCalendars();
    final wanted = onlyCalendarId == null
        ? calendars
        : calendars.where((c) => c.id == onlyCalendarId).toList();

    return <String, Object?>{
      'calendars': <Map<String, Object?>>[
        for (final calendar in wanted) await _exportCalendar(calendar),
      ],
    };
  }

  Future<Map<String, Object?>> _exportCalendar(CollectionCalendar calendar) async {
    final types = await (db.select(db.wasteTypes)
          ..where((t) => t.calendarId.equals(calendar.id))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();

    return <String, Object?>{
      'name': calendar.name,
      'notificationTime': calendar.notificationTime,
      'secondNotificationTime': calendar.secondNotificationTime,
      'enabled': calendar.enabled,
      'sortOrder': calendar.sortOrder,
      'wasteTypes': <Map<String, Object?>>[
        for (final type in types) await _exportWasteType(type),
      ],
    };
  }

  Future<Map<String, Object?>> _exportWasteType(WasteType type) async {
    final rules = await (db.select(
      db.recurrenceRules,
    )..where((r) => r.wasteTypeId.equals(type.id))).get();
    final exceptions = await (db.select(
      db.collectionExceptions,
    )..where((e) => e.wasteTypeId.equals(type.id))).get();

    return <String, Object?>{
      'name': type.name,
      'iconKey': type.iconKey,
      'colorValue': type.colorValue,
      'notificationsEnabled': type.notificationsEnabled,
      'sortOrder': type.sortOrder,
      'rules': <Map<String, Object?>>[
        for (final rule in rules)
          <String, Object?>{
            'kind': rule.kind,
            'weekdaysMask': rule.weekdaysMask,
            'intervalWeeks': rule.intervalWeeks,
            'anchorDate': rule.anchorDate,
            'dayOfMonth': rule.dayOfMonth,
            'nthOfMonth': rule.nthOfMonth,
            'weekday': rule.weekday,
            'manualDatesCsv': rule.manualDatesCsv,
            'startDate': rule.startDate,
            'endDate': rule.endDate,
          },
      ],
      'exceptions': <Map<String, Object?>>[
        for (final exception in exceptions)
          <String, Object?>{
            'originalDate': exception.originalDate,
            'replacementDate': exception.replacementDate,
            'skipped': exception.skipped,
            'note': exception.note,
          },
      ],
    };
  }

  @override
  Future<void> importPayload(
    Map<String, Object?> payload, {
    required ImportMode mode,
  }) async {
    final calendars = _listOfMaps(payload['calendars']);

    // ☠ Tutto in una transazione: un import interrotto a metà lascerebbe un calendario con
    // tre tipi su cinque, indistinguibile da un calendario configurato male. E poiché
    // `replaceAll` cancella prima di scrivere, un'interruzione fuori transazione
    // cancellerebbe i dati dell'utente senza rimpiazzarli.
    await db.transaction(() async {
      if (mode == ImportMode.replaceAll) {
        await db.delete(db.collectionCalendars).go();
      }

      final existingNames = mode == ImportMode.mergeKeepExisting
          ? (await db.allCalendars()).map((c) => c.name).toSet()
          : <String>{};

      for (final calendar in calendars) {
        final name = _string(calendar['name']);
        if (name == null || name.isEmpty) continue;
        // In fusione si salta un calendario che c'è già invece di duplicarlo: due
        // "Casa" identici sono peggio di un import mancato, perché l'utente non sa
        // quale dei due sta guardando.
        if (existingNames.contains(name)) continue;

        final calendarId = await db
            .into(db.collectionCalendars)
            .insert(
              CollectionCalendarsCompanion.insert(
                name: name,
                notificationTime: Value(_string(calendar['notificationTime']) ?? '20:00'),
                secondNotificationTime: Value(_string(calendar['secondNotificationTime'])),
                enabled: Value(_bool(calendar['enabled']) ?? true),
                sortOrder: Value(_int(calendar['sortOrder']) ?? 0),
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );

        for (final type in _listOfMaps(calendar['wasteTypes'])) {
          await _importWasteType(calendarId, type);
        }
      }
    });
  }

  Future<void> _importWasteType(int calendarId, Map<String, Object?> type) async {
    final name = _string(type['name']);
    if (name == null || name.isEmpty) return;

    final typeId = await db
        .into(db.wasteTypes)
        .insert(
          WasteTypesCompanion.insert(
            calendarId: calendarId,
            name: name,
            iconKey: _string(type['iconKey']) ?? 'trash',
            colorValue: _int(type['colorValue']) ?? 0xFF6D8B3C,
            notificationsEnabled: Value(_bool(type['notificationsEnabled']) ?? true),
            sortOrder: Value(_int(type['sortOrder']) ?? 0),
          ),
        );

    for (final rule in _listOfMaps(type['rules'])) {
      final kind = _string(rule['kind']);
      final startDate = _string(rule['startDate']);
      // Una regola senza `kind` o senza data d'inizio non è leggibile dal mapper: si
      // scarta la regola, non l'intero import. Il tipo di rifiuto resta, e l'utente può
      // rimettergli i giorni.
      if (kind == null || startDate == null) continue;

      await db
          .into(db.recurrenceRules)
          .insert(
            RecurrenceRulesCompanion.insert(
              wasteTypeId: typeId,
              kind: kind,
              weekdaysMask: Value(_int(rule['weekdaysMask']) ?? 0),
              intervalWeeks: Value(_int(rule['intervalWeeks'])),
              anchorDate: Value(_string(rule['anchorDate'])),
              dayOfMonth: Value(_int(rule['dayOfMonth'])),
              nthOfMonth: Value(_int(rule['nthOfMonth'])),
              weekday: Value(_int(rule['weekday'])),
              manualDatesCsv: Value(_string(rule['manualDatesCsv'])),
              startDate: startDate,
              endDate: Value(_string(rule['endDate'])),
            ),
          );
    }

    for (final exception in _listOfMaps(type['exceptions'])) {
      await db
          .into(db.collectionExceptions)
          .insert(
            CollectionExceptionsCompanion.insert(
              wasteTypeId: typeId,
              originalDate: Value(_string(exception['originalDate'])),
              replacementDate: Value(_string(exception['replacementDate'])),
              skipped: Value(_bool(exception['skipped']) ?? false),
              note: Value(_string(exception['note'])),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    }
  }

  @override
  Future<List<String>> imagePaths() async => const <String>[];

  /// I numeri mostrati prima di ripristinare: un ripristino è distruttivo, e vedere
  /// "1 calendario, 3 tipi" prima di confermare evita di sovrascrivere il file sbagliato.
  @override
  Future<Map<String, int>> counts() async {
    final payload = await exportPayload();
    final calendars = _listOfMaps(payload['calendars']);
    var types = 0;
    var rules = 0;
    for (final calendar in calendars) {
      for (final type in _listOfMaps(calendar['wasteTypes'])) {
        types++;
        rules += _listOfMaps(type['rules']).length;
      }
    }
    return <String, int>{'calendars': calendars.length, 'wasteTypes': types, 'rules': rules};
  }
}

// ── Letture difensive ──────────────────────────────────────────────────────────────
//
// ⚑ Il payload arriva da un file che può essere stato scritto da una versione futura, da
// un'altra persona, o modificato a mano. Nessuna di queste letture lancia: un campo storto
// deve far perdere quel campo, non l'intero import. La regola sta qui e non sparsa nei
// chiamanti, così non esistono due idee diverse di cosa sia un valore accettabile.

List<Map<String, Object?>> _listOfMaps(Object? value) => value is List
    ? <Map<String, Object?>>[
        for (final item in value)
          if (item is Map) Map<String, Object?>.from(item),
      ]
    : const <Map<String, Object?>>[];

String? _string(Object? value) => value is String ? value : null;

int? _int(Object? value) => switch (value) {
  final int i => i,
  final double d => d.toInt(),
  final String s => int.tryParse(s),
  _ => null,
};

bool? _bool(Object? value) => switch (value) {
  final bool b => b,
  final int i => i != 0,
  'true' => true,
  'false' => false,
  _ => null,
};

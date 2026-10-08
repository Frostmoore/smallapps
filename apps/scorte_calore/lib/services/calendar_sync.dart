import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../data/scorte_repository.dart';

/// Un calendario del telefono in cui si puo' scrivere: quello che serve alla scelta.
@immutable
class CalendarChoice {
  const CalendarChoice({required this.id, required this.name, this.account, this.isPrimary = false});

  final String id;
  final String name;
  final String? account;
  final bool isPrimary;
}

/// Il confine con il plugin: tutto quello che `CalendarSyncService` chiede al telefono.
///
/// ⚑ Un'interfaccia e non `DeviceCalendar.instance` diretto: il plugin parla con il sistema
/// tramite canale, e nei test non c'e' nessun sistema. Cosi' le regole (evento cancellato a
/// mano, permesso negato, deriva di 3 giorni) si provano senza telefono.
abstract interface class CalendarGateway {
  /// `true` se il permesso c'e' o e' stato appena concesso.
  Future<bool> requestAccess();

  Future<List<CalendarChoice>> writableCalendars();

  /// Crea un evento di un giorno intero e restituisce il suo id.
  Future<String> createAllDay({
    required String calendarId,
    required String title,
    required String description,
    required CivilDate day,
  });

  /// ☠ Solleva [CalendarEventMissing] se l'evento non c'e' piu' (cancellato a mano).
  Future<void> updateAllDay(
      {required String eventId, required String title, required String description, required CivilDate day});

  /// ☠ Solleva [CalendarEventMissing] se l'evento non c'e' piu'.
  Future<void> delete(String eventId);
}

/// L'evento non esiste piu' nel calendario: l'utente l'ha cancellato a mano.
class CalendarEventMissing implements Exception {
  const CalendarEventMissing();
}

/// Il gateway vero, su `device_calendar_plus`.
///
/// ⚑ `device_calendar_plus` e non `device_calendar` come diceva il piano: `device_calendar` e'
/// fermo al settembre 2024, senza il permesso "accesso completo" di iOS 17 (deciso il
/// 2026-10-08, vedi l'atlante).
class DeviceCalendarGateway implements CalendarGateway {
  const DeviceCalendarGateway();

  DeviceCalendar get _plugin => DeviceCalendar.instance;

  @override
  Future<bool> requestAccess() async =>
      // ⚑ Accesso completo e non "solo scrittura": per aggiornare o togliere l'evento bisogna
      //   poterlo ritrovare, e con la sola scrittura iOS non lo lascia leggere.
      await _plugin.requestPermissions() == CalendarPermissionStatus.granted;

  @override
  Future<List<CalendarChoice>> writableCalendars() async {
    final all = await _plugin.listCalendars();
    return [
      for (final c in all)
        if (!c.readOnly && !c.hidden)
          CalendarChoice(id: c.id, name: c.name, account: c.accountName, isPrimary: c.isPrimary),
    ];
  }

  @override
  Future<String> createAllDay({
    required String calendarId,
    required String title,
    required String description,
    required CivilDate day,
  }) =>
      _plugin.createEvent(
        calendarId: calendarId,
        title: title,
        description: description,
        // Un giorno intero: dalla mezzanotte del giorno a quella del successivo (data "fluttuante",
        // resta lo stesso giorno in qualunque fuso).
        startDate: day.toLocalMidnight(),
        endDate: day.addDays(1).toLocalMidnight(),
        isAllDay: true,
        availability: EventAvailability.free,
      );

  @override
  Future<void> updateAllDay(
      {required String eventId, required String title, required String description, required CivilDate day}) async {
    try {
      await _plugin.updateEvent(
        instanceId: eventId,
        title: title,
        description: Patch.set(description),
        startDate: day.toLocalMidnight(),
        endDate: day.addDays(1).toLocalMidnight(),
        isAllDay: true,
      );
    } on DeviceCalendarException catch (e) {
      if (e.errorCode == DeviceCalendarError.notFound) throw const CalendarEventMissing();
      rethrow;
    }
  }

  @override
  Future<void> delete(String eventId) async {
    try {
      await _plugin.deleteEvent(instanceId: eventId);
    } on DeviceCalendarException catch (e) {
      if (e.errorCode == DeviceCalendarError.notFound) throw const CalendarEventMissing();
      rethrow;
    }
  }
}

/// I testi dell'evento: titolo e descrizione, gia' nella lingua dell'app.
typedef ReorderEventTexts = ({String title, String description});

/// L'evento di riordino nel calendario del telefono (F5.10, Pro). Uno per fonte.
///
/// ⚑ **L'app propone, non sposta.** Quando la stima cambia di piu' di [driftDays] giorni la
/// home lo dice e offre "Aggiorna evento"; l'evento si tocca solo dopo quel tocco. Un'app che
/// sposta da sola gli eventi nel calendario di qualcuno e' invadente, e se il calendario e'
/// condiviso manda avvisi ad altre persone.
class CalendarSyncService {
  /// [gateway] si sostituisce solo nei test.
  CalendarSyncService(this._repo, [this._gateway = const DeviceCalendarGateway()]);

  final ScorteRepository _repo;
  final CalendarGateway _gateway;

  /// Oltre questa differenza fra la data scritta nell'evento e la stima di oggi, la home
  /// propone l'aggiornamento. Sotto, il rumore di una misura non deve disturbare.
  static const int driftDays = 3;

  /// Codici d'errore di questo servizio (oltre a `MicroError.unexpected`).
  static const String errDenied = 'calendar_denied';
  static const String errNoCalendar = 'calendar_none';

  /// `true` se l'evento scritto il giorno [written] va riproposto per la data [current].
  static bool drifted(CivilDate written, CivilDate current) => written.daysUntil(current).abs() > driftDays;

  /// I calendari in cui si puo' scrivere, il principale per primo. Chiede il permesso.
  Future<Result<List<CalendarChoice>>> availableCalendars() async {
    try {
      if (!await _gateway.requestAccess()) {
        return const Err(MicroError(code: errDenied, message: 'permesso del calendario negato'));
      }
      final list = [...await _gateway.writableCalendars()]
        ..sort((a, b) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0));
      if (list.isEmpty) return const Err(MicroError(code: errNoCalendar, message: 'nessun calendario scrivibile'));
      return Ok(list);
    } on Object catch (e, st) {
      return Err(MicroError.unexpected(e, st));
    }
  }

  /// Scrive (o aggiorna) l'evento di riordino di [source] al giorno [date] e se lo ricorda.
  ///
  /// Se l'evento ricordato non c'e' piu' perche' l'utente l'ha cancellato dal calendario, ne
  /// crea uno nuovo: l'utente ha appena chiesto di averlo, quindi lo vuole.
  Future<Result<String>> upsertReorderEvent({
    required FuelSource source,
    required CivilDate date,
    required String calendarId,
    required ReorderEventTexts texts,
    String? existingEventId,
  }) async {
    try {
      if (!await _gateway.requestAccess()) {
        return const Err(MicroError(code: errDenied, message: 'permesso del calendario negato'));
      }
      String? eventId = existingEventId;
      if (eventId != null) {
        try {
          await _gateway.updateAllDay(eventId: eventId, title: texts.title, description: texts.description, day: date);
        } on CalendarEventMissing {
          eventId = null;
        }
      }
      eventId ??= await _gateway.createAllDay(
        calendarId: calendarId,
        title: texts.title,
        description: texts.description,
        day: date,
      );
      await _repo.upsertReminder(
          sourceId: source.id, calendarId: calendarId, externalEventId: eventId, calculatedDate: date);
      return Ok(eventId);
    } on Object catch (e, st) {
      return Err(MicroError.unexpected(e, st));
    }
  }

  /// Toglie l'evento dal calendario. Un evento gia' sparito conta come tolto.
  Future<Result<void>> deleteEvent(String calendarId, String eventId) async {
    try {
      await _gateway.delete(eventId);
    } on CalendarEventMissing {
      // Gia' tolto a mano: e' quello che si voleva.
    } on Object catch (e, st) {
      return Err(MicroError.unexpected(e, st));
    }
    return const Ok(null);
  }

  /// Toglie l'evento della fonte e dimentica il promemoria. Da chiamare **prima** di
  /// cancellare la fonte o di sostituire tutto con un backup: dopo, la riga che diceva quale
  /// evento togliere non c'e' piu' (cascade) e l'evento resterebbe orfano nel calendario.
  ///
  /// Se il calendario non risponde (permesso tolto nel frattempo) il promemoria si dimentica
  /// comunque: la fonte sta per sparire e non deve restare bloccata da un evento.
  Future<void> forgetSource(int sourceId) async {
    final reminder = await _repo.reminderFor(sourceId);
    if (reminder == null) return;
    final removed = await deleteEvent(reminder.calendarId, reminder.externalEventId);
    if (removed.isErr) MicroLog.d('evento del calendario non tolto: ${removed.errorOrNull}');
    await _repo.deleteReminder(sourceId);
  }

  /// [forgetSource] per tutte le fonti che hanno un evento. (Il ripristino di un backup non
  /// la usa: legge i promemoria prima e toglie gli eventi solo se il ripristino riesce.)
  Future<void> forgetAll() async {
    final all = await _repo.watchReminders().first;
    for (final r in all) {
      await forgetSource(r.fuelSourceId);
    }
  }
}

import 'package:drift/drift.dart';

/// Un calendario di raccolta: "Casa", "Casa al mare", "Da mia madre".
///
/// Nel piano gratuito ne esiste uno solo. Il secondo è quello che il Pro vende.
class CollectionCalendars extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// Orario del promemoria, come `HH:mm`.
  ///
  /// ⚑ Testo e non due interi: è un dato che si legge e si scrive sempre insieme, non si
  /// interroga mai per ora separata dai minuti, e in forma testuale è ispezionabile a
  /// occhio in un dump del database.
  TextColumn get notificationTime => text().withLength(min: 5, max: 5).withDefault(
    const Constant('20:00'),
  )();

  /// Secondo promemoria, funzione Pro. `null` = non impostato.
  TextColumn get secondNotificationTime => text().withLength(min: 5, max: 5).nullable()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Istante di creazione, millisecondi UTC (ADR-008: questo è un istante vero).
  IntColumn get createdAt => integer()();
}

/// Un tipo di rifiuto dentro un calendario: organico, carta, plastica…
class WasteTypes extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get calendarId =>
      integer().references(CollectionCalendars, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// Chiave in `WasteIcons.byKey`, **mai** un `IconData.codePoint`.
  ///
  /// ☠ Salvare il codepoint rompe il tree shaking delle icone e in release produce
  /// quadrati vuoti. Vedi `lib/app/waste_presets.dart`.
  TextColumn get iconKey => text().withLength(min: 1, max: 32)();

  /// Colore ARGB come intero.
  IntColumn get colorValue => integer()();

  BoolColumn get notificationsEnabled => boolean().withDefault(const Constant(true))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Una regola di ricorrenza per un tipo di rifiuto.
///
/// La tabella è volutamente "larga": molte colonne nullable, di cui solo alcune valide
/// per ciascun `kind`.
///
/// ⚑ Perché non una tabella per tipo di ricorrenza: sarebbero cinque tabelle, cinque
/// join e cinque DAO per un dato che si legge sempre tutto insieme e che non supera
/// qualche decina di righe per utente. La larghezza si paga con la validazione nel
/// mapper, che è un posto solo.
class RecurrenceRules extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get wasteTypeId =>
      integer().references(WasteTypes, #id, onDelete: KeyAction.cascade)();

  /// `weekly` | `everyNWeeks` | `monthlyDay` | `monthlyNthWeekday` | `manual`
  TextColumn get kind => text().withLength(min: 1, max: 24)();

  /// Bitmask dei giorni: bit 0 = lunedì, bit 6 = domenica. Vedi `WeekdayMask`.
  IntColumn get weekdaysMask => integer().withDefault(const Constant(0))();

  /// Per `everyNWeeks`: ogni quante settimane. Sempre >= 2.
  IntColumn get intervalWeeks => integer().nullable()();

  /// Per `everyNWeeks`: la data che fissa la fase del ciclo, `YYYY-MM-DD`.
  TextColumn get anchorDate => text().withLength(min: 10, max: 10).nullable()();

  /// Per `monthlyDay`: 1..31, con clamp a fine mese.
  IntColumn get dayOfMonth => integer().nullable()();

  /// Per `monthlyNthWeekday`: 1..5 oppure -1 per "l'ultimo".
  IntColumn get nthOfMonth => integer().nullable()();

  /// Per `monthlyNthWeekday`: 1..7.
  IntColumn get weekday => integer().nullable()();

  /// Per `manual`: date `YYYY-MM-DD` separate da virgola.
  TextColumn get manualDatesCsv => text().nullable()();

  TextColumn get startDate => text().withLength(min: 10, max: 10)();

  TextColumn get endDate => text().withLength(min: 10, max: 10).nullable()();
}

/// Una deroga alla regola: salta, sposta, oppure raccolta straordinaria.
///
/// Le tre forme ammesse e il loro significato stanno in `CollectionException`
/// (`lib/domain/occurrence_engine.dart`). Il mapper valida prima di consegnare.
///
/// La data class generata si chiama `ExceptionRow` e non `CollectionException`: il nome
/// naturale collide con la classe di dominio omonima, e due tipi con lo stesso nome nello
/// stesso file sono il tipo di attrito che si paga a ogni import per anni.
@DataClassName('ExceptionRow')
class CollectionExceptions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get wasteTypeId =>
      integer().references(WasteTypes, #id, onDelete: KeyAction.cascade)();

  TextColumn get originalDate => text().withLength(min: 10, max: 10).nullable()();

  TextColumn get replacementDate => text().withLength(min: 10, max: 10).nullable()();

  BoolColumn get skipped => boolean().withDefault(const Constant(false))();

  TextColumn get note => text().nullable()();

  IntColumn get createdAt => integer()();
}

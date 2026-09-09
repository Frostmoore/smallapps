import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

/// Una regola che dice in quali giorni passa la raccolta di un tipo di rifiuto.
///
/// Vive in `domain/` e non importa Flutter di proposito: un errore qui e' invisibile
/// all'utente finche' l'app non sbaglia il giorno, quindi dev'essere testabile in
/// millisecondi senza `WidgetTester`.
///
/// Tutte le date sono [CivilDate]: "la carta si raccoglie il mercoledi" non e' un
/// istante e non ha fuso orario (ADR-008).
@immutable
sealed class Recurrence {
  const Recurrence({required this.startDate, this.endDate});

  /// Prima data in cui la regola puo' produrre una raccolta.
  final CivilDate startDate;

  /// Ultima data inclusa, oppure `null` se la regola non scade.
  final CivilDate? endDate;

  /// `true` se in [date] c'e' una raccolta secondo questa regola, ignorando le
  /// eccezioni: quelle le applica [OccurrenceEngine].
  bool occursOn(CivilDate date) {
    if (date.isBefore(startDate)) return false;
    final end = endDate;
    if (end != null && date.isAfter(end)) return false;
    return matches(date);
  }

  /// Il criterio specifico della sottoclasse, gia' dentro la finestra di validita'.
  @protected
  bool matches(CivilDate date);

  /// Le date di raccolta comprese tra [from] e [to], estremi inclusi.
  ///
  /// L'implementazione predefinita scandisce i giorni uno per uno. Per le finestre in
  /// gioco qui (60 giorni per la pianificazione delle notifiche, un anno al massimo
  /// per la vista mensile) sono qualche centinaio di confronti interi per regola: non
  /// vale la pena di ottimizzare a scapito della leggibilita' di un calcolo che deve
  /// essere ovviamente corretto.
  Iterable<CivilDate> occurrencesIn(CivilDate from, CivilDate to) sync* {
    if (to.isBefore(from)) return;
    for (final date in from.rangeTo(to)) {
      if (occursOn(date)) yield date;
    }
  }
}

/// Raccolta in uno o piu' giorni fissi, tutte le settimane.
///
/// Il caso piu' comune in assoluto: "organico il lunedi e il giovedi".
@immutable
final class WeeklyRecurrence extends Recurrence {
  const WeeklyRecurrence({required this.weekdays, required super.startDate, super.endDate});

  /// Giorni della settimana, da [DateTime.monday] a [DateTime.sunday].
  final Set<int> weekdays;

  @override
  bool matches(CivilDate date) => weekdays.contains(date.weekday);

  @override
  bool operator ==(Object other) =>
      other is WeeklyRecurrence &&
      _sameWeekdays(other.weekdays, weekdays) &&
      other.startDate == startDate &&
      other.endDate == endDate;

  @override
  int get hashCode =>
      Object.hash(WeeklyRecurrence, Object.hashAllUnordered(weekdays), startDate, endDate);

  @override
  String toString() => 'WeeklyRecurrence(${weekdays.toList()..sort()})';
}

/// Raccolta a settimane alterne, o ogni N settimane.
///
/// "La carta si raccoglie i mercoledi alterni" e' ambiguo finche' non si sa **quale**
/// mercoledi: per questo serve [anchor], la data che l'utente indica come prossima
/// raccolta. Il ciclo si calcola contando le settimane rispetto a quella, in entrambe
/// le direzioni.
///
/// Non si usa il numero di settimana ISO: cambia significato a cavallo dell'anno e
/// produrrebbe un salto o un raddoppio tra dicembre e gennaio.
@immutable
final class EveryNWeeksRecurrence extends Recurrence {
  EveryNWeeksRecurrence({
    required this.weekdays,
    required this.intervalWeeks,
    required CivilDate anchorDate,
    required super.startDate,
    super.endDate,
  }) : assert(intervalWeeks >= 2, 'Con intervallo 1 si usa WeeklyRecurrence'),
       anchor = anchorDate,
       _anchorWeekStart = _mondayOf(anchorDate);

  final Set<int> weekdays;

  /// Ogni quante settimane si ripete il ciclo. Sempre >= 2.
  final int intervalWeeks;

  /// Una data in cui la raccolta avviene: fissa la fase del ciclo.
  final CivilDate anchor;

  final CivilDate _anchorWeekStart;

  @override
  bool matches(CivilDate date) {
    if (!weekdays.contains(date.weekday)) return false;
    final weeksApart = (_mondayOf(date).epochDay - _anchorWeekStart.epochDay) ~/ 7;
    // Modulo sempre non negativo: il ciclo vale anche per le date precedenti
    // all'ancora, purche' dentro la finestra di validita' della regola.
    return weeksApart % intervalWeeks == 0;
  }

  static CivilDate _mondayOf(CivilDate date) => date.addDays(-(date.weekday - DateTime.monday));

  @override
  bool operator ==(Object other) =>
      other is EveryNWeeksRecurrence &&
      _sameWeekdays(other.weekdays, weekdays) &&
      other.intervalWeeks == intervalWeeks &&
      other._anchorWeekStart == _anchorWeekStart &&
      other.startDate == startDate &&
      other.endDate == endDate;

  @override
  int get hashCode => Object.hash(
    EveryNWeeksRecurrence,
    Object.hashAllUnordered(weekdays),
    intervalWeeks,
    _anchorWeekStart,
    startDate,
    endDate,
  );

  @override
  String toString() =>
      'EveryNWeeksRecurrence(ogni $intervalWeeks sett., ${weekdays.toList()..sort()}, ancora $anchor)';
}

/// Raccolta in un giorno fisso del mese, con clamp a fine mese.
///
/// "Il 31 di ogni mese" a febbraio diventa il 28 (o il 29): non si salta il mese e non
/// si sconfina in marzo. E' la sola interpretazione che corrisponde a come la intende
/// chi la scrive.
@immutable
final class MonthlyDayRecurrence extends Recurrence {
  const MonthlyDayRecurrence({required this.dayOfMonth, required super.startDate, super.endDate})
    : assert(dayOfMonth >= 1 && dayOfMonth <= 31, 'giorno del mese fuori intervallo');

  final int dayOfMonth;

  @override
  bool matches(CivilDate date) {
    final effective = dayOfMonth <= date.daysInMonth ? dayOfMonth : date.daysInMonth;
    return date.day == effective;
  }

  @override
  bool operator ==(Object other) =>
      other is MonthlyDayRecurrence &&
      other.dayOfMonth == dayOfMonth &&
      other.startDate == startDate &&
      other.endDate == endDate;

  @override
  int get hashCode => Object.hash(MonthlyDayRecurrence, dayOfMonth, startDate, endDate);

  @override
  String toString() => 'MonthlyDayRecurrence(giorno $dayOfMonth)';
}

/// Raccolta nel primo, secondo, terzo, quarto o ultimo giorno della settimana del mese.
///
/// "L'ultimo venerdi del mese" e' una formulazione frequente sui volantini comunali.
@immutable
final class MonthlyNthWeekdayRecurrence extends Recurrence {
  const MonthlyNthWeekdayRecurrence({
    required this.nth,
    required this.weekday,
    required super.startDate,
    super.endDate,
  }) : assert(nth == -1 || (nth >= 1 && nth <= 5), 'nth deve essere 1..5 oppure -1'),
       assert(weekday >= DateTime.monday && weekday <= DateTime.sunday);

  /// Da 1 a 5, oppure -1 per "l'ultimo del mese".
  final int nth;

  final int weekday;

  @override
  bool matches(CivilDate date) {
    if (date.weekday != weekday) return false;
    if (nth == -1) {
      // E' l'ultimo del mese se sette giorni dopo si cambia mese.
      return date.addDays(7).month != date.month;
    }
    // Il primo giorno-della-settimana del mese cade tra il 1 e il 7, il secondo tra
    // l'8 e il 14, e cosi' via.
    final occurrenceIndex = ((date.day - 1) ~/ 7) + 1;
    return occurrenceIndex == nth;
  }

  @override
  bool operator ==(Object other) =>
      other is MonthlyNthWeekdayRecurrence &&
      other.nth == nth &&
      other.weekday == weekday &&
      other.startDate == startDate &&
      other.endDate == endDate;

  @override
  int get hashCode => Object.hash(MonthlyNthWeekdayRecurrence, nth, weekday, startDate, endDate);

  @override
  String toString() => 'MonthlyNthWeekdayRecurrence(nth $nth, weekday $weekday)';
}

/// Raccolta solo nelle date indicate a mano.
///
/// Serve ai calendari che non hanno una regola: alcuni Comuni pubblicano un elenco di
/// date per il verde o per gli ingombranti.
@immutable
final class ManualDatesRecurrence extends Recurrence {
  ManualDatesRecurrence({
    required Iterable<CivilDate> dates,
    required super.startDate,
    super.endDate,
  }) : dates = Set<CivilDate>.unmodifiable(dates);

  final Set<CivilDate> dates;

  @override
  bool matches(CivilDate date) => dates.contains(date);

  @override
  Iterable<CivilDate> occurrencesIn(CivilDate from, CivilDate to) {
    if (to.isBefore(from)) return const <CivilDate>[];
    final inRange =
        dates.where((d) => d.isSameOrAfter(from) && d.isSameOrBefore(to) && occursOn(d)).toList()
          ..sort();
    return inRange;
  }

  @override
  bool operator ==(Object other) =>
      other is ManualDatesRecurrence &&
      other.dates.length == dates.length &&
      other.dates.containsAll(dates) &&
      other.startDate == startDate &&
      other.endDate == endDate;

  @override
  int get hashCode =>
      Object.hash(ManualDatesRecurrence, Object.hashAllUnordered(dates), startDate, endDate);

  @override
  String toString() => 'ManualDatesRecurrence(${dates.length} date)';
}

bool _sameWeekdays(Set<int> a, Set<int> b) => a.length == b.length && a.containsAll(b);

/// Conversioni tra l'insieme dei giorni e la bitmask salvata nel database.
///
/// In tabella i giorni stanno in un intero (`weekdaysMask`) invece che in una tabella
/// figlia: sono al massimo sette valori, non si interrogano mai singolarmente, e una
/// colonna intera evita una join a ogni lettura del calendario.
abstract final class WeekdayMask {
  /// Bit 0 = lunedi, bit 6 = domenica.
  static int fromSet(Set<int> weekdays) {
    var mask = 0;
    for (final day in weekdays) {
      assert(day >= DateTime.monday && day <= DateTime.sunday, 'weekday fuori intervallo');
      mask |= 1 << (day - DateTime.monday);
    }
    return mask;
  }

  static Set<int> toSet(int mask) {
    final result = <int>{};
    for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
      if (mask & (1 << (day - DateTime.monday)) != 0) result.add(day);
    }
    return result;
  }
}

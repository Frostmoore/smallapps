import 'package:meta/meta.dart';

/// Una data del calendario, senza ora e senza fuso.
///
/// "La raccolta dell'organico e' lunedi'" e "il ragu' e' stato congelato il 4
/// settembre" non sono istanti: sono date civili. Rappresentarle con [DateTime]
/// significa portarsi dietro un'ora e un fuso che non esistono, e il risultato e' che
/// il cambio dell'ora legale o un fuso diverso spostano la data di un giorno per
/// alcuni utenti in alcune settimane dell'anno. E' il bug classico dei calendari:
/// difficilissimo da riprodurre e devastante per un'app la cui unica funzione e' dire
/// il giorno giusto.
///
/// Si serializza sempre come TEXT `YYYY-MM-DD` (ADR-008). Gli istanti veri (creazione
/// di un record, verifica di una licenza) restano [DateTime] in millisecondi UTC.
@immutable
final class CivilDate implements Comparable<CivilDate> {
  /// Costruisce una data civile. I valori fuori intervallo vengono normalizzati come
  /// fa [DateTime]: `CivilDate(2026, 13, 1)` diventa il 1 gennaio 2027.
  factory CivilDate(int year, int month, int day) {
    if (month >= 1 && month <= 12 && day >= 1 && day <= _daysInMonth(year, month)) {
      return CivilDate._(year, month, day);
    }
    final normalized = DateTime(year, month, day);
    return CivilDate._(normalized.year, normalized.month, normalized.day);
  }

  const CivilDate._(this.year, this.month, this.day);

  /// La parte di data di un [DateTime], letta nel fuso **locale**.
  factory CivilDate.fromDateTime(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    return CivilDate._(local.year, local.month, local.day);
  }

  /// La data di oggi nel fuso locale. [now] serve ai test per fissare il presente.
  factory CivilDate.today({DateTime? now}) => CivilDate.fromDateTime(now ?? DateTime.now());

  /// Interpreta una stringa `YYYY-MM-DD`. Lancia [FormatException] se non lo e'.
  factory CivilDate.parse(String iso) {
    final parsed = tryParse(iso);
    if (parsed == null) {
      throw FormatException('Data civile non valida, atteso YYYY-MM-DD', iso);
    }
    return parsed;
  }

  /// Come [CivilDate.parse] ma restituisce `null` invece di lanciare.
  static CivilDate? tryParse(String? iso) {
    if (iso == null || iso.length != 10) return null;
    if (iso.codeUnitAt(4) != 0x2D || iso.codeUnitAt(7) != 0x2D) return null;
    final year = int.tryParse(iso.substring(0, 4));
    final month = int.tryParse(iso.substring(5, 7));
    final day = int.tryParse(iso.substring(8, 10));
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > _daysInMonth(year, month)) return null;
    return CivilDate._(year, month, day);
  }

  /// La data corrispondente al numero di giorni trascorsi dal 1970-01-01.
  factory CivilDate.fromEpochDay(int epochDay) {
    final dt = DateTime.utc(1970).add(Duration(days: epochDay));
    return CivilDate._(dt.year, dt.month, dt.day);
  }

  final int year;
  final int month;
  final int day;

  /// Rappresentazione canonica `YYYY-MM-DD`, quella che va nel database.
  String toIso() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Mezzanotte locale di questa data. Utile per pianificare notifiche.
  DateTime toLocalMidnight() => DateTime(year, month, day);

  /// Questa data all'ora locale indicata.
  DateTime toLocalDateTime(int hour, [int minute = 0]) => DateTime(year, month, day, hour, minute);

  /// Giorno della settimana, da [DateTime.monday] a [DateTime.sunday].
  int get weekday => DateTime.utc(year, month, day).weekday;

  /// Giorni trascorsi dal 1970-01-01. Base per l'aritmetica e per l'ordinamento.
  ///
  /// Si calcola in UTC di proposito: in fuso locale una data a cavallo del cambio
  /// d'ora produrrebbe una differenza di 23 o 25 ore, e la divisione per 24 darebbe
  /// il giorno sbagliato.
  int get epochDay => DateTime.utc(year, month, day).difference(DateTime.utc(1970)).inDays;

  /// Somma (o sottrae) giorni.
  CivilDate addDays(int days) => CivilDate.fromEpochDay(epochDay + days);

  /// Somma (o sottrae) mesi, con **clamp a fine mese**.
  ///
  /// 31 gennaio + 1 mese = 28 febbraio (29 negli anni bisestili), non 3 marzo. Senza
  /// il clamp, la regola "raccolta il 31 di ogni mese" salterebbe i mesi corti
  /// generando date nel mese successivo, che e' sempre l'interpretazione sbagliata.
  CivilDate addMonths(int months) {
    final total = (year * 12 + (month - 1)) + months;
    final newYear = total ~/ 12;
    final newMonth = total % 12 + 1;
    final newDay = day <= _daysInMonth(newYear, newMonth) ? day : _daysInMonth(newYear, newMonth);
    return CivilDate._(newYear, newMonth, newDay);
  }

  /// Somma (o sottrae) anni, con clamp del 29 febbraio al 28.
  CivilDate addYears(int years) => addMonths(years * 12);

  /// Giorni da questa data a [other]. Positivo se [other] e' successiva.
  int daysUntil(CivilDate other) => other.epochDay - epochDay;

  bool isBefore(CivilDate other) => epochDay < other.epochDay;

  bool isAfter(CivilDate other) => epochDay > other.epochDay;

  bool isSameOrBefore(CivilDate other) => epochDay <= other.epochDay;

  bool isSameOrAfter(CivilDate other) => epochDay >= other.epochDay;

  /// `true` se e' la data odierna nel fuso locale.
  bool isToday({DateTime? now}) => this == CivilDate.today(now: now);

  /// Il primo giorno del mese di questa data.
  CivilDate get firstDayOfMonth => CivilDate._(year, month, 1);

  /// L'ultimo giorno del mese di questa data.
  CivilDate get lastDayOfMonth => CivilDate._(year, month, _daysInMonth(year, month));

  /// Numero di giorni del mese di questa data.
  int get daysInMonth => _daysInMonth(year, month);

  /// Le date da questa a [end] incluse. Vuoto se [end] precede questa data.
  Iterable<CivilDate> rangeTo(CivilDate end) sync* {
    var current = this;
    while (current.isSameOrBefore(end)) {
      yield current;
      current = current.addDays(1);
    }
  }

  @override
  int compareTo(CivilDate other) => epochDay.compareTo(other.epochDay);

  @override
  bool operator ==(Object other) =>
      other is CivilDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// Coincide con [toIso]: una data civile si stampa in un modo solo.
  @override
  String toString() => toIso();

  static const List<int> _monthLengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  static int _daysInMonth(int year, int month) {
    if (month == 2 && _isLeapYear(year)) return 29;
    return _monthLengths[month - 1];
  }

  static bool _isLeapYear(int year) => (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
}

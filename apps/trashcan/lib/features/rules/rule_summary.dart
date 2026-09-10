import 'package:flutter/widgets.dart';

import '../../domain/recurrence.dart';
import '../../l10n/generated/app_localizations.dart';
import 'weekday_labels.dart';

/// Una riga che descrive una regola in modo verificabile a colpo d'occhio.
///
/// ⚑ Perché non basta "Ogni settimana": il sottotitolo di una voce serve a confermare che
/// la configurazione è quella giusta. "Ogni settimana" è vero per qualunque regola
/// settimanale e quindi non conferma niente; "Ogni settimana: mar, ven" invece si confronta
/// col volantino del Comune senza aprire nulla. È lo stesso motivo per cui l'editor mostra
/// le prossime sei date.
String describeRecurrence(BuildContext context, Recurrence recurrence) {
  final l = L.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();

  return switch (recurrence) {
    WeeklyRecurrence(:final weekdays) => l.rules_summaryWeekly(
      weekdayListShort(locale, weekdays),
    ),
    EveryNWeeksRecurrence(:final weekdays, :final intervalWeeks) => l.rules_summaryEveryNWeeks(
      intervalWeeks,
      weekdayListShort(locale, weekdays),
    ),
    MonthlyDayRecurrence(:final dayOfMonth) => l.rules_summaryMonthlyDay(dayOfMonth),
    MonthlyNthWeekdayRecurrence(:final nth, :final weekday) => l.rules_summaryMonthlyNth(
      nthLabel(l, nth),
      weekdayFull(locale, weekday),
    ),
    ManualDatesRecurrence(:final dates) => l.rules_summaryManual(dates.length),
  };
}

/// "Primo", "Ultimo"… per le regole del tipo "il terzo giovedì del mese".
///
/// `-1` significa "l'ultimo", non "il meno-primo": è la stessa convenzione della colonna
/// `nthOfMonth` in tabella e di [MonthlyNthWeekdayRecurrence.nth].
String nthLabel(L l, int nth) => switch (nth) {
  1 => l.rules_nthFirst,
  2 => l.rules_nthSecond,
  3 => l.rules_nthThird,
  4 => l.rules_nthFourth,
  _ => l.rules_nthLast,
};

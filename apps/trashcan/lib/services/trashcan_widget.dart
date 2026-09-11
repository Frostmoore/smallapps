import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../app/locale_resolution.dart';
import '../data/database.dart';
import '../domain/occurrence_engine.dart';
import '../l10n/generated/app_localizations.dart';

/// Il widget della schermata iniziale.
///
/// ⚑ **Perché il widget è la funzione più importante dopo la notifica**: chi ha il widget
/// non apre l'app, guarda lo schermo. Un'app che risponde a una domanda sola guadagna di
/// più a rispondere senza essere aperta che ad avere una bella schermata.
///
/// ☠ **Un widget Android non può usare Flutter per disegnarsi.** Il sistema costruisce la
/// vista in un processo suo, a partire da `RemoteViews`, che accetta solo un
/// sottoinsieme ristretto di view: niente `ConstraintLayout`, niente widget personalizzati.
/// Quindi qui si calcolano solo **stringhe e colori**, si salvano dove il provider Kotlin
/// sa leggerli, e il disegno lo fa un layout XML.
abstract final class TrashcanWidget {
  /// Il nome della classe Kotlin, con il package: è così che il plugin la ritrova.
  ///
  /// ☠ Scritto per esteso e non come nome semplice: con il solo nome della classe il
  /// plugin la cerca sotto il package dell'applicazione, e con un `applicationIdSuffix`
  /// (per esempio `.debug`) non la trova più. Il sintomo è un widget che non si aggiorna
  /// mai, senza nessun errore.
  static const String qualifiedName = 'com.smp.trashcan.TrashcanWidgetProvider';

  // Le chiavi devono coincidere con quelle lette in TrashcanWidgetProvider.kt. Sono
  // costanti qui e là: due stringhe scritte a mano in due linguaggi diversi divergono al
  // primo ritocco, e il sintomo è un campo vuoto nel widget e nessun errore da nessuna
  // parte.
  static const String keyTonightLabel = 'tonight_label';
  static const String keyTonightText = 'tonight_text';
  static const String keyTonightColor = 'tonight_color';
  static const String keyNextText = 'next_text';
  static const String keyCalendarName = 'calendar_name';
  static const String keyUpcoming = 'upcoming';
  static const String keyShowUpcoming = 'show_upcoming';

  static const OccurrenceEngine _engine = OccurrenceEngine();

  /// Ricalcola il contenuto e lo consegna al sistema.
  ///
  /// [pro] decide se il widget mostra anche i prossimi giorni: è l'unica differenza fra
  /// la versione gratuita e quella a pagamento, e si decide qui invece che nel layout
  /// perché il provider Kotlin non sa niente di acquisti.
  static Future<void> publish({
    required AppDatabase db,
    required int? calendarId,
    required bool pro,
  }) async {
    final l = lookupL(
      resolveAppLocale(WidgetsBinding.instance.platformDispatcher.locales, kSupportedLocales),
    );
    final locale = l.localeName;

    final calendars = await db.allCalendars();
    if (calendars.isEmpty) {
      await _write(
        label: l.home_tonightTitle.toUpperCase(),
        text: l.home_tonightEmpty,
        color: null,
        next: '',
        calendarName: '',
        upcoming: const <String>[],
        showUpcoming: false,
      );
      return;
    }

    final calendar =
        calendars.where((c) => c.id == calendarId).firstOrNull ?? calendars.first;
    final bundle = await db.loadBundle(calendar.id);
    final today = CivilDate.today();
    final occurrences = bundle == null
        ? const <CollectionOccurrence>[]
        : _engine.expand(rules: bundle.rules, from: today, to: today.addDays(10));

    // "Stasera" è la raccolta di **domani**: il bidone si porta fuori la sera prima.
    final tomorrow = today.addDays(1);
    final tonight = occurrences.where((o) => o.date == tomorrow).toList();

    final names = <String>[
      for (final occurrence in tonight)
        if (bundle?.typeOf(occurrence.wasteTypeId)?.name case final name?) name,
    ];

    final accent = tonight.isEmpty
        ? null
        : bundle?.typeOf(tonight.first.wasteTypeId)?.colorValue;

    final next = occurrences.where((o) => o.date.isAfter(tomorrow)).firstOrNull;
    final nextText = next == null
        ? ''
        : l.home_nextIn(
            bundle?.typeOf(next.wasteTypeId)?.name ?? '',
            _eveningLabel(l, locale, next.date),
          );

    await _write(
      label: l.home_tonightTitle.toUpperCase(),
      text: names.isEmpty ? l.home_tonightEmpty : names.join(', '),
      color: accent,
      next: nextText,
      calendarName: calendars.length > 1 ? calendar.name : '',
      upcoming: <String>[
        for (final occurrence in occurrences.where((o) => o.date.isAfter(tomorrow)).take(3))
          '${DateFormat('EEE d', locale).format(occurrence.date.toLocalMidnight())}  '
              '${bundle?.typeOf(occurrence.wasteTypeId)?.name ?? ''}',
      ],
      showUpcoming: pro,
    );
  }

  static Future<void> _write({
    required String label,
    required String text,
    required int? color,
    required String next,
    required String calendarName,
    required List<String> upcoming,
    required bool showUpcoming,
  }) async {
    await HomeWidget.saveWidgetData<String>(keyTonightLabel, label);
    await HomeWidget.saveWidgetData<String>(keyTonightText, text);
    // Il colore viaggia come intero ARGB. `null` significa "usa il colore neutro del
    // tema": il provider lo interpreta, il layout non ha logica.
    await HomeWidget.saveWidgetData<int>(keyTonightColor, color ?? 0);
    await HomeWidget.saveWidgetData<String>(keyNextText, next);
    await HomeWidget.saveWidgetData<String>(keyCalendarName, calendarName);
    await HomeWidget.saveWidgetData<String>(keyUpcoming, upcoming.join('\n'));
    await HomeWidget.saveWidgetData<bool>(keyShowUpcoming, showUpcoming && upcoming.isNotEmpty);
    await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedName);
  }

  /// Programma un aggiornamento poco dopo la mezzanotte.
  ///
  /// ☠ Senza questo, alle 00:01 il widget continua a dire "stasera: organico" riferendosi
  /// alla sera precedente, finché qualcosa non apre l'app. È il momento in cui il widget
  /// è più letto e più sbagliato: la mattina, uscendo di casa.
  ///
  /// Le 00:05 e non le 00:00: il sistema raggruppa gli allarmi della mezzanotte esatta e
  /// li fa slittare, e cinque minuti di margine costano niente.
  static Future<void> scheduleDailyRefresh() async {
    final now = DateTime.now();
    final times = <DateTime>[
      for (var day = 1; day <= 7; day++)
        DateTime(now.year, now.month, now.day + day, 0, 5),
    ];
    try {
      await HomeWidget.scheduleWidgetUpdates(times, qualifiedAndroidName: qualifiedName);
    } on Exception catch (error) {
      // Il plugin lancia se non trova nessun provider: succede quando l'utente non ha
      // messo il widget sulla schermata. Non e' un difetto, ed e' il caso normale.
      MicroLog.d('aggiornamenti del widget non programmati: $error');
    }
  }

  /// "questa sera", "domani sera", "giovedì sera".
  static String _eveningLabel(L l, String locale, CivilDate collectionDate) {
    final evening = collectionDate.addDays(-1);
    final today = CivilDate.today();
    if (evening == today) return l.home_whenThisEvening;
    if (evening == today.addDays(1)) return l.home_whenTomorrowEvening;
    return l.home_whenOnWeekdayEvening(
      DateFormat('EEEE', locale).format(evening.toLocalMidnight()),
    );
  }
}

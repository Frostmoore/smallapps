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
  static const String keyCalendarName = 'calendar_name';
  static const String keyUpcoming = 'upcoming';
  static const String keyUpcomingEmpty = 'upcoming_empty';

  /// Il separatore fra le righe dei prossimi giorni.
  ///
  /// In una costante e non scritto a mano dentro `join`: l'a capo dentro un letterale Dart
  /// e' facilissimo da rompere con una sostituzione automatica, e il sintomo e' un widget
  /// che elenca i giorni tutti su una riga sola.
  static const String newline = '\n';

  static const OccurrenceEngine _engine = OccurrenceEngine();

  /// Ricalcola il contenuto e lo consegna al sistema.
  ///
  /// [pro] decide **quanti** giorni elenca la fascia inferiore, non se elencarli: tre col
  /// Pro, solo la prossima raccolta senza.
  ///
  /// ⛑ Perche' non "niente" senza Pro: il widget e' fatto di due fasce, e una meta'
  /// bianca e vuota non si legge come "funzione a pagamento", si legge come "il widget non
  /// ha caricato". Una riga sola che dice qualcosa di vero e' un widget che funziona e che
  /// lascia vedere cosa si guadagna ad averne tre.
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
        calendarName: '',
        upcoming: const <String>[],
        emptyText: l.home_noUpcoming,
      );
      return;
    }

    final calendar =
        calendars.where((c) => c.id == calendarId).firstOrNull ?? calendars.first;
    final bundle = await db.loadBundle(calendar.id);
    final today = CivilDate.today();
    final occurrences = bundle == null
        ? const <CollectionOccurrence>[]
        : _engine.expand(rules: bundle.rules, from: today, to: today.addDays(21));

    // "Stasera" e' la raccolta di **domani**: il bidone si porta fuori la sera prima.
    final tomorrow = today.addDays(1);
    final tonight = occurrences.where((o) => o.date == tomorrow).toList();

    final names = <String>[
      for (final occurrence in tonight)
        if (bundle?.typeOf(occurrence.wasteTypeId)?.name case final name?) name,
    ];

    final accent = tonight.isEmpty
        ? null
        : bundle?.typeOf(tonight.first.wasteTypeId)?.colorValue;

    final later = occurrences.where((o) => o.date.isAfter(tomorrow)).toList();

    await _write(
      label: l.home_tonightTitle.toUpperCase(),
      text: names.isEmpty ? l.home_tonightEmpty : names.join(', '),
      color: accent,
      calendarName: calendars.length > 1 ? calendar.name : '',
      upcoming: <String>[
        for (final occurrence in later.take(pro ? 3 : 1))
          '${DateFormat('EEE d', locale).format(occurrence.date.toLocalMidnight())}   '
              '${bundle?.typeOf(occurrence.wasteTypeId)?.name ?? ''}',
      ],
      emptyText: l.home_noUpcoming,
    );
  }

  static Future<void> _write({
    required String label,
    required String text,
    required int? color,
    required String calendarName,
    required List<String> upcoming,
    required String emptyText,
  }) async {
    await HomeWidget.saveWidgetData<String>(keyTonightLabel, label);
    await HomeWidget.saveWidgetData<String>(keyTonightText, text);
    // Il colore viaggia come intero ARGB. 0 significa "usa il colore neutro": il provider
    // lo interpreta, il layout non ha logica.
    await HomeWidget.saveWidgetData<int>(keyTonightColor, color ?? 0);
    await HomeWidget.saveWidgetData<String>(keyCalendarName, calendarName);
    await HomeWidget.saveWidgetData<String>(keyUpcoming, upcoming.join(newline));
    await HomeWidget.saveWidgetData<String>(keyUpcomingEmpty, emptyText);
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
}

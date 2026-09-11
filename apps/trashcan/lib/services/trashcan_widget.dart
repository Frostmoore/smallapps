import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../app/locale_resolution.dart';
import '../app/waste_presets.dart';
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
  static const String keyTonightIcon = 'tonight_icon';
  static const String keyCalendarName = 'calendar_name';
  static const String keyUpcoming = 'upcoming';
  static const String keyUpcomingEmpty = 'upcoming_empty';

  /// Il lato del PNG dell'icona, in pixel.
  ///
  /// Fisso e generoso: il widget lo rimpicciolisce a 26dp, ma la stessa immagine deve
  /// reggere anche uno schermo a densità 3x senza sgranarsi, e 96 px bastano.
  static const int iconSide = 96;

  /// Il separatore fra le righe dei prossimi giorni.
  ///
  /// In una costante e non scritto a mano dentro `join`: l'a capo dentro un letterale Dart
  /// e' facilissimo da rompere con una sostituzione automatica, e il sintomo e' un widget
  /// che elenca i giorni tutti su una riga sola.
  static const String newline = '\n';

  static const OccurrenceEngine _engine = OccurrenceEngine();

  /// Quanti giorni elenca la fascia inferiore. **Uguale per tutti.**
  ///
  /// ☠ Qui c'era `pro ? 3 : 1`. La versione gratuita mostrava una riga sola, e il
  /// proprietario, guardando il widget vero sul proprio telefono, l'ha letta come un
  /// difetto: "e' sbagliato il widget". Non stava sbagliando lui. Una riga in mezzo a meta'
  /// widget bianca non comunica "funzione a pagamento", comunica "non ha caricato", e chi
  /// lo pensa non compra, disinstalla.
  ///
  /// Il commento che stava qui diceva che una riga sola "lascia vedere cosa si guadagna ad
  /// averne tre". Era una supposizione, ed e' stata smentita dal primo essere umano che ha
  /// guardato il widget. Decisione del 2026-09-11: tre giorni per tutti, e il Pro resta
  /// venduto dai promemoria, dal secondo promemoria, dai calendari multipli, dal backup e
  /// dal colore dell'app.
  static const int giorniElencati = 3;

  /// Ricalcola il contenuto e lo consegna al sistema.
  ///
  /// [pro] non incide piu' su quanti giorni si vedono (vedi [giorniElencati]). Resta nella
  /// firma perche' il chiamante lo ha e perche' il giorno in cui il widget tornera' a
  /// distinguere qualcosa fra gratuito e Pro — per esempio la scelta del calendario —
  /// servira' di nuovo, senza cambiare tutte le chiamate.
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
        iconKey: null,
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

    // Colore e icona vengono dallo **stesso** tipo, il primo di stasera, esattamente come
    // nella card della home: con piu' tipi la stessa sera si mostra l'icona del primo e si
    // elencano tutti i nomi. Prenderli da due tipi diversi darebbe un'intestazione arancione
    // con l'icona del vetro, che e' peggio che non avere l'icona.
    final first = tonight.isEmpty ? null : bundle?.typeOf(tonight.first.wasteTypeId);
    final accent = first?.colorValue;

    final later = occurrences.where((o) => o.date.isAfter(tomorrow)).toList();

    await _write(
      label: l.home_tonightTitle.toUpperCase(),
      text: names.isEmpty ? l.home_tonightEmpty : names.join(', '),
      color: accent,
      iconKey: first?.iconKey,
      calendarName: calendars.length > 1 ? calendar.name : '',
      upcoming: <String>[
        for (final occurrence in later.take(giorniElencati))
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
    required String? iconKey,
    required String calendarName,
    required List<String> upcoming,
    required String emptyText,
  }) async {
    await HomeWidget.saveWidgetData<String>(keyTonightLabel, label);
    await HomeWidget.saveWidgetData<String>(keyTonightText, text);
    // Il colore viaggia come intero ARGB. 0 significa "usa il colore neutro": il provider
    // lo interpreta, il layout non ha logica.
    await HomeWidget.saveWidgetData<int>(keyTonightColor, color ?? 0);
    await _writeIcon(iconKey);
    await HomeWidget.saveWidgetData<String>(keyCalendarName, calendarName);
    await HomeWidget.saveWidgetData<String>(keyUpcoming, upcoming.join(newline));
    await HomeWidget.saveWidgetData<String>(keyUpcomingEmpty, emptyText);
    await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedName);
  }

  /// Disegna l'icona del tipo di rifiuto in un PNG e ne consegna il percorso al widget.
  ///
  /// ⚑ **Perché un PNG e non un vector drawable.** L'icona nella card della home è un glifo
  /// del font Material, scelto per chiave in [WasteIcons]. `RemoteViews` non sa disegnare
  /// glifi: sa mostrare un drawable o un bitmap. Ricopiare le ventidue icone Material come
  /// altrettanti vector drawable in `res/` significherebbe due cataloghi da tenere allineati
  /// a mano, e la prima icona aggiunta in Dart e dimenticata in `res/` darebbe un widget con
  /// un quadrato vuoto. Qui invece il glifo viene disegnato a runtime **dallo stesso font e
  /// dalla stessa mappa** che usa la card: per costruzione non possono divergere.
  ///
  /// ⚑ Il glifo si disegna **bianco su trasparente**, non già del colore giusto: il provider
  /// Kotlin lo tinge con `setColorFilter`, lo stesso colore che calcola per il testo
  /// dell'intestazione. Così la scelta fra testo chiaro e testo scuro resta in un posto solo.
  ///
  /// ☠ Un fallimento qui non deve far fallire l'aggiornamento: l'icona è un ornamento, il
  /// nome di cosa si butta è l'informazione. Se il disegno non riesce si svuota la chiave e
  /// il provider nasconde l'immagine.
  static Future<void> _writeIcon(String? iconKey) async {
    if (iconKey == null) {
      await HomeWidget.saveWidgetData<String>(keyTonightIcon, '');
      return;
    }
    try {
      final bytes = await renderIcon(WasteIcons.resolve(iconKey));
      // saveFile scrive il PNG e salva **il percorso** sotto la chiave: è il percorso che
      // il provider legge.
      await HomeWidget.saveFile(keyTonightIcon, bytes, extension: 'png');
    } on Object catch (error) {
      MicroLog.d('icona del widget non disegnata: $error');
      await HomeWidget.saveWidgetData<String>(keyTonightIcon, '');
    }
  }

  /// Il glifo [icon] disegnato bianco su trasparente, in un PNG di [iconSide] px di lato.
  ///
  /// ☠ Si legge `codePoint` da un `IconData` **costante**, preso da `WasteIcons.byKey`. Non
  /// si costruisca mai un `IconData` da un codepoint calcolato: il tree shaking delle icone
  /// analizza le istanze costanti, e con una dinamica Flutter o rimuove tutti i glifi,
  /// lasciando quadrati vuoti in release, o imbarca il font intero.
  @visibleForTesting
  static Future<Uint8List> renderIcon(IconData icon) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final painter = TextPainter(
      // ☠ `ui.TextDirection` e non `TextDirection`: `package:intl` esporta una classe con
      // lo stesso nome e costanti diverse (`LTR`), e senza prefisso vince quella.
      textDirection: ui.TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: iconSide.toDouble(),
          color: const Color(0xFFFFFFFF),
        ),
      ),
    )..layout();

    painter.paint(
      canvas,
      ui.Offset((iconSide - painter.width) / 2, (iconSide - painter.height) / 2),
    );

    final image = await recorder.endRecording().toImage(iconSide, iconSide);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('il glifo non si è convertito in PNG');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
      painter.dispose();
    }
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

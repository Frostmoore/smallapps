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

  /// Gli stati del widget, **uno per giorno**, una riga ciascuno. Vedi [publish].
  static const String keyDays = 'days';

  /// L'intestazione fissa, "STASERA".
  static const String keyTonightLabel = 'tonight_label';

  /// Il nome del calendario, vuoto quando ce n'è uno solo.
  static const String keyCalendarName = 'calendar_name';

  /// Cosa scrivere sotto quando nei giorni elencati non c'è nessuna raccolta.
  static const String keyUpcomingEmpty = 'upcoming_empty';

  /// Cosa scrivere quando i giorni precalcolati sono finiti. Vedi [giorniPrecalcolati].
  static const String keyStale = 'stale';

  /// Il prefisso delle chiavi che contengono il percorso di un'icona già disegnata.
  ///
  /// Una riga di [keyDays] porta la **chiave** dell'icona, non il suo percorso: il percorso
  /// è lungo settanta caratteri e si ripeterebbe in ogni riga dell'anno. Il provider lo
  /// ritrova leggendo `icon_<chiave>` dalle stesse preferenze.
  static const String iconKeyPrefix = 'icon_';

  // ── Il formato delle righe ─────────────────────────────────────────────────
  //
  // ⚑ Righe separate da `\n` e campi separati da un carattere di controllo, invece di JSON.
  // Non è micro-ottimizzazione: il provider deve trovare **una sola riga** su trecento­
  // sessantacinque, e cercare `"\n2026-09-16"` in una stringa costa quanto una
  // ricerca di sottostringa, mentre analizzare tutto il JSON costa quanto l'intero anno.
  // Così il numero di giorni precalcolati smette di incidere sul costo del ridisegno, che
  // avviene dentro un BroadcastReceiver e ha un budget di tempo stretto.
  //
  // ☠ I separatori sono caratteri di controllo ASCII (US e RS) e **non possono comparire**
  // nel nome di un tipo di rifiuto scritto dall'utente: una tastiera non li produce. Con un
  // carattere stampabile, tipo `|`, un tipo chiamato "Carta | Cartone" spaccherebbe la riga
  // e il widget mostrerebbe campi sfasati.

  /// Fra un campo e l'altro nella stessa riga. `US`, unit separator.
  ///
  /// Scritto come sequenza di escape e non come carattere letterale: un carattere di
  /// controllo dentro il sorgente e' invisibile in ogni editor, sopravvive male alle
  /// conversioni di codifica, e chi lo cancella per sbaglio non se ne accorge
  /// guardando il file.
  static const String fieldSeparator = '\u001F';

  /// Fra una riga e l'altra dell'elenco dei prossimi giorni, **dentro** un campo.
  /// `RS`, record separator. Il provider lo converte in un a capo vero.
  static const String lineSeparator = '\u001E';

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

  /// Quanti giorni di stati si precalcolano in una sola pubblicazione.
  ///
  /// ☠ **È il cuore della correzione del 2026-09-16.** Prima il widget conteneva le
  /// stringhe di **un giorno solo**, e a mezzanotte continuava a dire "stasera: organico"
  /// riferendosi alla sera passata finché qualcuno non apriva l'app.
  ///
  /// La causa non era l'allarme: era che l'allarme non poteva servire a niente. Il
  /// risveglio notturno fa ridisegnare il widget, ma il ridisegno rilegge le stesse
  /// stringhe, e a calcolarle è Dart, che gira **solo quando l'app è in primo piano**. Un
  /// widget Android non può far partire Flutter per aggiornarsi.
  ///
  /// La soluzione non è far girare Dart in background — servirebbe un isolate, una seconda
  /// connessione al database e il permesso del sistema di svegliarsi, e fallirebbe in
  /// silenzio sui telefoni che uccidono i processi. La soluzione è **precalcolare**: Dart
  /// prepara dieci anni di stati, uno per giorno, e il provider sceglie quello che
  /// porta la data di oggi. Kotlin non calcola niente e non conosce né calendari né lingue:
  /// confronta due stringhe di dieci caratteri.
  ///
  /// ⚑ **Dieci anni, non un mese e non uno.** La prima stesura si fermava a trenta giorni,
  /// la seconda a trecentosessantacinque, con la motivazione che costruire un decennio
  /// avrebbe fatto scattare l'interfaccia. Il proprietario ha chiesto un decennio -
  /// «parliamo di kbyte» - e aveva ragione su tutti e tre i costi.
  ///
  /// Lo **spazio**: una riga sta in una novantina di caratteri, quindi il decennio occupa
  /// poco più di trecento kilobyte in una preferenza. È molto per una preferenza e niente
  /// per un telefono, e si paga una volta sola.
  ///
  /// La **lettura** non la paga nessuno: il provider cerca una riga invece di analizzare
  /// tutto, quindi il numero di giorni non incide sul ridisegno. È il formato a righe ad
  /// aver reso gratuito l'allungamento dell'orizzonte.
  ///
  /// Il **calcolo** sarebbe stato il costo vero, perché `publish` gira a ogni avvio e a ogni
  /// modifica dei dati. Non lo è più: la parte cara era formattare la data di ogni raccolta
  /// elencata, e ogni raccolta compariva nell'elenco di [giorniElencati] giorni diversi.
  /// Adesso l'etichetta si formatta **una volta per raccolta**, nel passaggio di
  /// raggruppamento, e il ciclo dei giorni non fa altro che unire stringhe già pronte. Il
  /// decennio costa meno dell'anno di prima.
  ///
  /// ☠ Le regole valgono per sempre, ma i calendari comunali cambiano. Un decennio di righe
  /// non è la promessa che il 2036 sarà così: è esattamente quello che l'app stessa mostra
  /// scorrendo avanti, cioè le regole di oggi proiettate. Il widget non mente più dell'app,
  /// e chi cambia le regole ripubblica tutto.
  static const int giorniPrecalcolati = 3650;

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
    final calendar =
        calendars.where((c) => c.id == calendarId).firstOrNull ?? calendars.firstOrNull;
    final bundle = calendar == null ? null : await db.loadBundle(calendar.id);

    final oggi = CivilDate.today();

    // ☠ La finestra va oltre l'ultimo giorno precalcolato. L'ultima riga dell'anno deve
    // comunque poter elencare le sue tre raccolte successive, e con una regola mensile la
    // terza puo' cadere tre mesi dopo. Senza questo margine l'ultima riga avrebbe la fascia
    // inferiore vuota, e nessuno capirebbe perche' proprio quel giorno.
    final occorrenze = bundle == null
        ? const <CollectionOccurrence>[]
        : _engine.expand(
            rules: bundle.rules,
            from: oggi,
            to: oggi.addDays(giorniPrecalcolati + 120),
          );

    // Raccolte raggruppate per data, nell'ordine in cui l'espansione le restituisce, che
    // e' gia' cronologico.
    final perData = <String, List<CollectionOccurrence>>{};
    final dateConRaccolta = <CivilDate>[];
    for (final occorrenza in occorrenze) {
      final chiave = occorrenza.date.toIso();
      perData.putIfAbsent(chiave, () {
        dateConRaccolta.add(occorrenza.date);
        return <CollectionOccurrence>[];
      }).add(occorrenza);
    }

    // ⚑ L'etichetta della fascia inferiore, già pronta, **una per raccolta**.
    //
    // ☠ È questa riga che rende gratuito il decennio. `DateFormat.format` è l'operazione
    // più cara del giro: costruisce il nome del giorno nella lingua corrente. Ogni raccolta
    // compare nell'elenco di [giorniElencati] giorni diversi, quindi formattandola dentro il
    // ciclo la si formatterebbe tre volte, e con dieci anni di giorni sarebbero decine di
    // migliaia di chiamate a ogni salvataggio di una regola: esattamente lo scatto
    // dell'interfaccia che aveva fatto scegliere un orizzonte corto. Qui se ne fa una per
    // raccolta, e il ciclo dei giorni si riduce a unire stringhe.
    final etichette = <CollectionOccurrence, String>{
      for (final occorrenza in occorrenze)
        occorrenza:
            '${DateFormat('EEE d', locale).format(occorrenza.date.toLocalMidnight())}   '
            '${bundle?.typeOf(occorrenza.wasteTypeId)?.name ?? ''}',
    };

    final righe = <String>[];
    final chiaviIcona = <String>{};

    // ⚑ Un puntatore che avanza, non un filtro per ogni giorno. Filtrando, il costo sarebbe
    // il prodotto fra i giorni e le raccolte: con un anno di giorni e quattro tipi
    // settimanali sono milioni di confronti a ogni avvio dell'app. Poiche' il giorno cresce
    // di uno a ogni giro, la prima raccolta utile non torna mai indietro, e il puntatore la
    // segue in una sola passata.
    var primaDopo = 0;

    for (var scarto = 0; scarto < giorniPrecalcolati; scarto++) {
      final giorno = oggi.addDays(scarto);

      // "Stasera" e' la raccolta di **domani**: il bidone si porta fuori la sera prima.
      // Quindi la riga del 13 settembre parla della raccolta del 14.
      final domani = giorno.addDays(1);
      final stasera = perData[domani.toIso()] ?? const <CollectionOccurrence>[];

      final nomi = <String>[
        for (final occorrenza in stasera)
          if (bundle?.typeOf(occorrenza.wasteTypeId)?.name case final nome?) nome,
      ];

      // Colore e icona vengono dallo **stesso** tipo, il primo di stasera, esattamente come
      // nella card della home: con piu' tipi la stessa sera si mostra l'icona del primo e si
      // elencano tutti i nomi. Prenderli da due tipi diversi darebbe un'intestazione
      // arancione con l'icona del vetro, che e' peggio che non avere l'icona.
      final primo = stasera.isEmpty ? null : bundle?.typeOf(stasera.first.wasteTypeId);
      final chiaveIcona = primo?.iconKey ?? '';
      if (chiaveIcona.isNotEmpty) chiaviIcona.add(chiaveIcona);

      while (primaDopo < dateConRaccolta.length &&
          !dateConRaccolta[primaDopo].isAfter(domani)) {
        primaDopo++;
      }

      final prossimi = <String>[];
      for (var i = primaDopo;
          i < dateConRaccolta.length && prossimi.length < giorniElencati;
          i++) {
        final data = dateConRaccolta[i];
        for (final occorrenza in perData[data.toIso()]!) {
          if (prossimi.length >= giorniElencati) break;
          prossimi.add(etichette[occorrenza] ?? '');
        }
      }

      righe.add(
        <String>[
          giorno.toIso(),
          nomi.isEmpty ? l.home_tonightEmpty : nomi.join(', '),
          // Il colore viaggia come intero ARGB. 0 significa "usa il colore neutro": il
          // provider lo interpreta, il layout non ha logica.
          '${primo?.colorValue ?? 0}',
          chiaveIcona,
          prossimi.join(lineSeparator),
        ].join(fieldSeparator),
      );
    }

    await _scriviIcone(chiaviIcona);

    await _write(
      label: l.home_tonightTitle.toUpperCase(),
      calendarName: calendars.length > 1 ? (calendar?.name ?? '') : '',
      upcomingEmpty: l.home_noUpcoming,
      stale: l.widget_openApp,
      righe: righe,
    );
  }

  static Future<void> _write({
    required String label,
    required String calendarName,
    required String upcomingEmpty,
    required String stale,
    required List<String> righe,
  }) async {
    await HomeWidget.saveWidgetData<String>(keyTonightLabel, label);
    await HomeWidget.saveWidgetData<String>(keyCalendarName, calendarName);
    await HomeWidget.saveWidgetData<String>(keyUpcomingEmpty, upcomingEmpty);
    await HomeWidget.saveWidgetData<String>(keyStale, stale);

    // ☠ Un a capo anche in testa. Il provider cerca la riga di oggi con
    // `indexOf("\n" + data)`: senza il primo a capo, la riga iniziale non verrebbe mai
    // trovata, e il widget sarebbe sbagliato esattamente il giorno in cui l'app e' stata
    // aperta.
    await HomeWidget.saveWidgetData<String>(keyDays, newline + righe.join(newline));

    await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedName);
  }

  /// Disegna una volta sola ogni icona che servira' nell'anno precalcolato.
  ///
  /// ⚑ **Perche' un PNG e non un vector drawable.** L'icona nella card della home e' un
  /// glifo del font Material, scelto per chiave in [WasteIcons]. `RemoteViews` non sa
  /// disegnare glifi: sa mostrare un drawable o un bitmap. Ricopiare le ventidue icone
  /// Material come altrettanti vector drawable in `res/` significherebbe due cataloghi da
  /// tenere allineati a mano, e la prima icona aggiunta in Dart e dimenticata in `res/`
  /// darebbe un widget con un quadrato vuoto. Qui invece il glifo viene disegnato a runtime
  /// **dallo stesso font e dalla stessa mappa** che usa la card: per costruzione non possono
  /// divergere.
  ///
  /// ⚑ Il glifo si disegna **bianco su trasparente**, non gia' del colore giusto: il
  /// provider Kotlin lo tinge con `setColorFilter`, lo stesso colore che calcola per il
  /// testo dell'intestazione. Cosi' la scelta fra testo chiaro e testo scuro resta in un
  /// posto solo.
  ///
  /// ☠ Un file per **chiave d'icona**, non uno solo. Con un anno di giorni precalcolati le
  /// icone in gioco sono quante sono i tipi di rifiuto, e un unico `tonight_icon.png`
  /// riscritto a ogni pubblicazione li mostrerebbe tutti con l'icona dell'ultimo scritto.
  ///
  /// ☠ Un fallimento qui non deve far fallire l'aggiornamento: l'icona e' un ornamento, il
  /// nome di cosa si butta e' l'informazione. Se il disegno non riesce non si scrive niente,
  /// il provider non trova il percorso e nasconde l'immagine.
  static Future<void> _scriviIcone(Set<String> chiavi) async {
    for (final chiave in chiavi) {
      try {
        final bytes = await renderIcon(WasteIcons.resolve(chiave));
        // `saveFile` scrive il PNG e mette **il percorso** sotto la chiave: e' da li' che
        // il provider lo rilegge, con lo stesso prefisso.
        await HomeWidget.saveFile('$iconKeyPrefix$chiave', bytes, extension: 'png');
      } on Object catch (error) {
        MicroLog.d('icona "$chiave" non disegnata: $error');
      }
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

  /// Programma il risveglio quotidiano del widget, poco dopo la mezzanotte.
  ///
  /// ☠ Senza questo, alle 00:01 il widget continua a mostrare il giorno precedente finché
  /// qualcosa non apre l'app. È il momento in cui il widget è più letto e più sbagliato: la
  /// mattina, uscendo di casa.
  ///
  /// ☠ E senza il receiver `HomeWidgetScheduledUpdateReceiver` dichiarato nel manifest,
  /// **questo metodo non serve a niente**: l'allarme viene armato, scatta, e la trasmissione
  /// non trova nessuno. Il plugin lascia la dichiarazione all'app di proposito, così chi non
  /// pianifica aggiornamenti non eredita il permesso di avvio. È rimasto fuori per giorni e
  /// non l'ha segnalato nessun errore.
  ///
  /// Le 00:05 e non le 00:00: il sistema raggruppa gli allarmi della mezzanotte esatta e li
  /// fa slittare, e cinque minuti di margine costano niente.
  ///
  /// ⚑ **Tanti risvegli quanti sono i giorni precalcolati, e non uno di meno.** Prima erano
  /// sette, cioè meno dei giorni che il widget sapeva già raccontare: dall'ottavo giorno
  /// senza aprire l'app il risveglio smetteva di arrivare pur avendo i dati pronti sotto.
  /// Un elenco più corto dell'orizzonte rimette esattamente il difetto che l'orizzonte
  /// serve a togliere, solo più in là nel tempo.
  ///
  /// Il plugin arma **un solo** allarme per volta e riarma il successivo a ogni scatto
  /// (`HomeWidgetScheduler.pruneAndArmNext`), quindi un decennio non è un decennio di
  /// allarmi di sistema: è un elenco di numeri in una preferenza, una cinquantina di
  /// kilobyte, riscritto una volta al giorno. Il sistema ne vede sempre e solo uno.
  static Future<void> scheduleDailyRefresh() async {
    final now = DateTime.now();
    final times = <DateTime>[
      for (var day = 1; day <= giorniPrecalcolati; day++)
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

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
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
  /// `true` dove il widget esiste davvero: Android e iOS.
  ///
  /// ☠ **Serve ancora, e non è un residuo.** `publish` gira da `notificationSyncProvider`
  /// a ogni avvio. Su una piattaforma senza widget (il desktop dei test, o iOS prima che
  /// esistesse l'estensione) il canale solleva, l'eccezione risale dentro un `unawaited` e
  /// la prima schermata non si vede nemmeno.
  ///
  /// ⚑ Le due piattaforme condividono **tutto** il calcolo: le stesse 3650 righe, gli
  /// stessi separatori, le stesse icone disegnate da Dart. Cambia solo chi le consuma, un
  /// `AppWidgetProvider` in Kotlin di qua e un'estensione WidgetKit in Swift di là.
  static bool get disponibile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Il gruppo condiviso fra app ed estensione su iOS.
  ///
  /// ☠ **Senza, su iOS non si scrive niente e non lo dice nessuno.** Le preferenze del
  /// widget non sono quelle dell'app: vivono in un contenitore separato a cui accedono
  /// entrambe, e che va dichiarato nei diritti dei due bersagli **e** registrato nel
  /// portale Apple. Se il gruppo non esiste, `saveWidgetData` scrive in un `UserDefaults`
  /// nullo e l'estensione legge un contenitore vuoto: nessun errore, widget vuoto.
  ///
  /// ☠ La stringa è ripetuta in tre posti che devono restare uguali: qui,
  /// `ios/Runner/Runner.entitlements` e `ios/TrashcanWidget/TrashcanWidget.entitlements`.
  static const String gruppoIos = 'group.com.smp.trashcan';

  /// Il nome con cui WidgetKit conosce l'estensione.
  ///
  /// ☠ È il `kind` dichiarato in `TrashcanWidget.swift`. Se le due divergono, l'app
  /// chiede a WidgetKit di ricaricare un widget che non esiste: nessun errore, nessun
  /// aggiornamento, e nessun indizio su dove guardare.
  static const String nomeIos = 'TrashcanWidget';

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
  /// Lo **spazio**: una riga sta in una novantina di caratteri, e il file delle preferenze
  /// misura **420 KB** sul dispositivo - più dei ~330 KB delle righe, perché le preferenze
  /// sono XML e ogni separatore di controllo ci finisce scritto come `&#31;`, cinque
  /// caratteri invece di uno. È molto per una preferenza e niente per un telefono, e si
  /// riscrive una volta per pubblicazione.
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
    if (!disponibile) return;
    await _preparaIos();

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

    await HomeWidget.updateWidget(
      qualifiedAndroidName: qualifiedName,
      iOSName: nomeIos,
    );
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

  /// Dichiara al plugin il gruppo condiviso, una volta per avvio.
  ///
  /// ⚑ Su Android non serve e non fa niente di dannoso, ma chiamarlo comunque
  /// costerebbe un passaggio di canale inutile a ogni pubblicazione.
  static Future<void> _preparaIos() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await HomeWidget.setAppGroupId(gruppoIos);
  }

  /// Quanti secondi dopo la mezzanotte scatta il risveglio **finale** di ogni giorno.
  ///
  /// ☠ **Deve coincidere con `SECONDI_DOPO_MEZZANOTTE` in `TrashcanWidgetProvider.kt`**, che
  /// ricalcola gli stessi istanti quando l'utente cambia fuso o ora, perché in quel momento
  /// Dart non gira. Due regole diverse darebbero due risvegli in due momenti diversi, e
  /// nessuno se ne accorgerebbe.
  static const int secondiDopoMezzanotte = 5;

  /// Quanti secondi dopo la mezzanotte deve **finire la finestra** del preavviso. Vedi
  /// [istantiDiRisveglio]. Uguale a `SECONDI_FINE_FINESTRA` in `TrashcanWidgetProvider.kt`.
  static const int secondiFineFinestra = 30;

  /// La finestra massima che Android concede a un allarme inesatto. Vedi
  /// [istantiDiRisveglio]. È `INTERVAL_HOUR` in `AlarmManagerService.maxTriggerTime`.
  static const Duration finestraMassima = Duration(hours: 1);

  /// La finestra di un allarme inesatto è questa frazione del preavviso con cui lo si arma,
  /// fino a [finestraMassima]. È lo `0.75` di `AlarmManagerService.maxTriggerTime`.
  static const double quotaFinestra = 0.75;

  /// Gli istanti in cui svegliare il widget: per ognuno dei prossimi [giorni] giorni un
  /// **preavviso** calcolato perché la sua finestra finisca a mezzanotte e
  /// [secondiFineFinestra] secondi, e un risveglio **finale** a mezzanotte e
  /// [secondiDopoMezzanotte] secondi.
  ///
  /// ☠ **Il perché del preavviso è il difetto del 2026-10-10** («alle 00:00 deve cambiare da
  /// solo»). Misurato sull'emulatore, Android 15, senza il permesso degli allarmi esatti
  /// (da Android 14 non è concesso di default):
  ///
  /// - il plugin arma un allarme **inesatto** (`setAndAllowWhileIdle`);
  /// - un allarme inesatto ha una finestra pari al 75% del preavviso con cui è stato armato,
  ///   con un tetto di un'ora: armato un giorno prima, `dumpsys alarm` diceva
  ///   `window=+1h0m0s`;
  /// - e da Android 14 il sistema lo consegna **alla fine** della finestra (il «lazy
  ///   batching»), anche a schermo acceso: un allarme per le 00:00:05 con 92 secondi di
  ///   finestra è arrivato alle 00:01:37, benché lo schermo fosse stato riacceso alle
  ///   00:00:30.
  ///
  /// Quindi l'allarme di mezzanotte faceva cambiare il widget verso **l'una di notte**, ogni
  /// notte. Il preavviso usa la stessa regola a nostro favore: armato con più di due ore e venti
  /// di anticipo, ha la finestra piena di un'ora (0,75 · 1 h 20 min = 1 h), e piazzandolo alle 23:00:30 la
  /// finestra finisce alle 00:00:30. Su Android 14+ il widget cambia alle 00:00:30 senza
  /// nessun permesso. Il risveglio finale resta per i sistemi che consegnano all'inizio della
  /// finestra (Android 13 e precedenti, o con il permesso concesso): lì il preavviso scatta
  /// alle 23:00:30, ridisegna lo stesso giorno, e alle 00:00:05 arriva il finale. Dove il
  /// preavviso arriva dopo le 00:00:05, il plugin scarta il finale come già passato.
  ///
  /// ⚑ **Il primo giorno è diverso**: il preavviso viene armato adesso, e non un giorno prima.
  /// Se mancano meno di due ore e venti alla fine voluta, la finestra sarebbe più corta di
  /// un'ora e finirebbe prima di mezzanotte: si sceglie allora l'istante `T` tale che
  /// `T + 0,75·(T − adesso)` cada proprio alle 00:00:30. I giorni successivi il plugin arma
  /// ogni allarme quando scatta il precedente, cioè intorno alla mezzanotte prima: quasi un
  /// giorno di anticipo, finestra piena.
  ///
  /// ⚑ **Si costruisce con i campi del calendario, non sommando 24 ore.** `DateTime(a, m,
  /// g + n)` è "il giorno n-esimo a mezzanotte, ora locale", e Dart normalizza da solo il
  /// giorno 32 e i cambi d'ora. Sommando `Duration(days: 1)`, dal 25 ottobre 2026 (che in
  /// Italia dura 25 ore) tutti gli istanti cadrebbero un'ora prima, per tutto l'inverno.
  ///
  /// ☠ Consegnati al plugin, gli istanti diventano **assoluti**. Misurato: passando da GMT
  /// a Europe/Rome l'allarme delle 00:05 è diventato quello delle 02:05. Per questo il
  /// provider Kotlin li ricalcola, con questa stessa regola, su `TIMEZONE_CHANGED` e
  /// `TIME_SET`.
  @visibleForTesting
  static List<DateTime> istantiDiRisveglio(
    DateTime adesso, {
    int giorni = giorniPrecalcolati,
  }) {
    final istanti = <DateTime>[];
    for (var giorno = 1; giorno <= giorni; giorno++) {
      final mezzanotte = DateTime(adesso.year, adesso.month, adesso.day + giorno);
      final fineFinestra = mezzanotte.add(const Duration(seconds: secondiFineFinestra));
      final preavviso = giorno == 1
          ? preavvisoArmatoAlle(adesso, fineFinestra)
          : fineFinestra.subtract(finestraMassima);
      if (preavviso != null) istanti.add(preavviso);
      istanti.add(mezzanotte.add(const Duration(seconds: secondiDopoMezzanotte)));
    }
    return istanti;
  }

  /// L'istante da chiedere ad Android, armando **adesso**, perché un allarme inesatto
  /// arrivi alla fine della finestra in [fineFinestra]. `null` se manca troppo poco perché
  /// un preavviso serva: basta il risveglio finale.
  ///
  /// La finestra vale `quotaFinestra · (T − adesso)`, fino a [finestraMassima]. Con molto
  /// anticipo il tetto vince e `T = fine − 1 h`; con poco, si risolve
  /// `T + 0,75·(T − adesso) = fine`, cioè `T = adesso + (fine − adesso) / 1,75`.
  @visibleForTesting
  static DateTime? preavvisoArmatoAlle(DateTime adesso, DateTime fineFinestra) {
    final mancano = fineFinestra.difference(adesso);
    if (mancano < const Duration(minutes: 1)) return null;
    final conTetto = fineFinestra.subtract(finestraMassima);
    final anticipoPerTetto = finestraMassima * (1 + 1 / quotaFinestra);
    if (mancano >= anticipoPerTetto) return conTetto;
    return adesso.add(mancano * (1 / (1 + quotaFinestra)));
  }

  /// Programma il risveglio del widget a ogni mezzanotte. **Solo Android.**
  ///
  /// ☠ Senza un risveglio, dopo mezzanotte il widget continua a mostrare il giorno
  /// precedente finché qualcosa non apre l'app. È il momento in cui il widget è più letto e
  /// più sbagliato: la mattina, uscendo di casa.
  ///
  /// ☠ **Il difetto del 2026-10-10 stava qui.** Gli istanti erano alle 00:05 e, senza il
  /// permesso degli allarmi esatti, Android 14+ li consegnava alla fine di una finestra di
  /// un'ora: il widget cambiava verso l'una. Adesso ogni giorno ha un preavviso tarato perché
  /// la consegna cada alle 00:00:30. Vedi [istantiDiRisveglio]; le reti di sicurezza
  /// (`updatePeriodMillis`, i cambi di fuso e d'ora) sono in `TrashcanWidgetProvider.kt` e in
  /// `trashcan_widget_info.xml`.
  ///
  /// ☠ E senza il receiver `HomeWidgetScheduledUpdateReceiver` dichiarato nel manifest,
  /// **questo metodo non serve a niente**: l'allarme viene armato, scatta, e la trasmissione
  /// non trova nessuno. Il plugin lascia la dichiarazione all'app di proposito.
  ///
  /// ⚑ **Tanti risvegli quanti sono i giorni precalcolati, e non uno di meno.** Un elenco
  /// più corto dell'orizzonte rimette il difetto che l'orizzonte serve a togliere, solo più
  /// in là nel tempo. Il plugin arma **un solo** allarme per volta e riarma il successivo a
  /// ogni scatto (`HomeWidgetScheduler.pruneAndArmNext`): il sistema ne vede sempre uno, e
  /// l'elenco è una preferenza di una cinquantina di kilobyte.
  ///
  /// ⚑ Gli istanti si salvano **anche se il widget non c'è ancora** (verificato: l'allarme
  /// compare in `dumpsys alarm` prima di aggiungere il widget). Chi lo aggiunge dopo l'ultima
  /// apertura dell'app è coperto, e `onEnabled` del provider li ricalcola comunque.
  ///
  /// ⚑ Su iOS non servono sveglie: WidgetKit cambia schermata all'ora giusta leggendo la
  /// timeline che l'estensione costruisce dalle righe già pronte.
  static Future<void> scheduleDailyRefresh() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final times = istantiDiRisveglio(DateTime.now());
    try {
      await HomeWidget.scheduleWidgetUpdates(times, qualifiedAndroidName: qualifiedName);
    } on Exception catch (error) {
      // Il plugin lancia solo se non trova la classe del provider (nome sbagliato): con il
      // nome qualificato giusto non succede, ma un widget mancante non deve far cadere
      // l'avvio dell'app.
      MicroLog.d('aggiornamenti del widget non programmati: $error');
    }
  }
}

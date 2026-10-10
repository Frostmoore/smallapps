# codebase_reference.md — TrashCan

> Atlante dell'app **TrashCan**, il calendario personale della raccolta differenziata.
> **Obiettivo**: capire il codice, trovare ciò che serve e modificarlo **senza aprire i file**.
>
> **Aggiornato al**: 2026-09-16 · **Fase**: F3 conclusa · **versionName+Code**: `1.0.0+3`
> **Package Android**: `com.smp.trashcan` (immutabile dopo il primo upload su Play)
> **SKU Pro**: `trashcan_pro_lifetime` — 2,99 € una tantum
>
> Quello che questa app prende da `micro_core` **non è ricopiato qui**: si rimanda a
> `packages/micro_core/codebase_reference.md`. Una firma copiata in due posti diverge in due
> settimane.
>
> Stato: l'app gira su Android ed è stata percorsa a mano sull'emulatore in ogni schermata.
> 127 test propri, oltre ai 109 di `micro_core`.

---

## 1. Dove sta cosa

| Cerchi… | Vai in… |
|---|---|
| Quando cade una raccolta | `lib/domain/occurrence_engine.dart` |
| Le cinque forme di ricorrenza | `lib/domain/recurrence.dart` |
| Le tabelle del database | `lib/data/tables.dart` |
| Le query di lettura, il bundle, i mapper riga→dominio | `lib/data/database.dart` |
| Tutte le scritture sul database | `lib/data/repository.dart` |
| I provider Riverpod (radice di tutto) | `lib/app/providers.dart` |
| I percorsi di navigazione | `lib/app/routes.dart` |
| Cosa è gratis e cosa è Pro | `lib/app/feature_limits.dart` |
| I testi e i benefici del paywall | `lib/app/paywall_config.dart` |
| Colori, icone e preset dei tipi di rifiuto | `lib/app/waste_presets.dart` |
| Italiano sì / italiano no | `lib/app/locale_resolution.dart` |
| Il piano delle notifiche | `lib/services/trashcan_scheduler.dart` |
| I colori generali dell'app (funzione Pro) | `lib/app/app_themes.dart` |
| Come si riprende l'acquisto su un telefono nuovo | `lib/features/restore/restore_page.dart` |
| Il contenuto del widget di sistema | `lib/services/trashcan_widget.dart` |
| Export, import, backup | `lib/services/trashcan_backup_source.dart` |
| Il disegno del widget | `android/app/src/main/kotlin/com/smp/trashcan/TrashcanWidgetProvider.kt` |
| Quando il widget cambia giorno (allarmi, preavviso, reti) | `TrashcanWidget.istantiDiRisveglio` in `lib/services/trashcan_widget.dart`, `TrashcanWidgetProvider.onReceive`/`riarmaMezzanotti`, `res/xml/trashcan_widget_info.xml` (`updatePeriodMillis`) |
| La timeline del widget iOS | `ios/TrashcanWidget/TrashcanWidget.swift`, `Fornitore.getTimeline` |
| Permessi, receiver, widget nel manifest | `android/app/src/main/AndroidManifest.xml` |
| La firma di release | `android/app/build.gradle.kts` + `android/key.properties` (non versionato) |
| Le stringhe tradotte | `lib/l10n/app_en.arb` (template) e `app_it.arb` |
| L'icona del launcher e la schermata di avvio | §2bis + `flutter_launcher_icons.yaml`, `flutter_native_splash.yaml` |

---

## 2. Albero dei file

Solo il codice scritto da noi.

```
apps/trashcan/
├── lib/
│   ├── main.dart                     avvio: config, cartelle, log, preferenze. Niente altro.
│   ├── app/
│   │   ├── app.dart                  GoRouter, MaterialApp, ciclo di vita, tocco sulle notifiche
│   │   ├── app_config.dart           MicroAppConfig di TrashCan (id, SKU, colore, font)
│   │   ├── feature_limits.dart       cosa è gratis e cosa è Pro (ADR-017)
│   │   ├── locale_resolution.dart    italiano sui dispositivi italiani, inglese altrove
│   │   ├── paywall_config.dart       testi e benefici del paywall + showTrashcanPaywall()
│   │   ├── providers.dart            TUTTI i provider Riverpod
│   │   ├── routes.dart               i percorsi, in costanti
│   │   └── waste_presets.dart        icone, tavolozza, preset del wizard
│   ├── data/
│   │   ├── tables.dart               le 4 tabelle Drift
│   │   ├── database.dart             AppDatabase, CalendarBundle, query, mapper riga→dominio
│   │   ├── database.g.dart           generato da drift_dev (non si modifica a mano)
│   │   └── repository.dart           tutte le scritture + mapper dominio→riga
│   ├── domain/
│   │   ├── recurrence.dart           le 5 ricorrenze, pure, senza database
│   │   └── occurrence_engine.dart    espansione regole + eccezioni in raccolte concrete
│   ├── features/
│   │   ├── backup/backup_page.dart
│   │   ├── calendars/calendars_page.dart, calendar_editor_page.dart
│   │   ├── day/day_page.dart         dove porta il tocco su una notifica
│   │   ├── exceptions/exceptions_page.dart, occurrence_actions.dart
│   │   ├── home/home_page.dart       "Stasera", prossima raccolta, prossimi 7 giorni
│   │   ├── notifications/notifications_page.dart
│   │   ├── onboarding/onboarding_page.dart   il wizard in 4 passi
│   │   ├── rules/rule_editor_page.dart, rule_summary.dart, weekday_labels.dart
│   │   ├── settings/settings_page.dart
│   │   └── waste_types/waste_types_page.dart, waste_type_editor_page.dart
│   ├── services/
│   │   ├── trashcan_scheduler.dart   costruisce e consegna il piano delle notifiche
│   │   ├── trashcan_widget.dart      calcola il contenuto del widget di sistema
│   │   └── trashcan_backup_source.dart  export/import
│   └── l10n/
│       ├── app_en.arb                template
│       └── app_it.arb                italiano, zero chiavi non tradotte
├── assets/icons/                     sorgenti dei generatori, NON asset a runtime (§2bis)
│   ├── trashcan_logo.png             il logo, 1254x1254
│   └── trashcan_splash_android12.png lo stesso logo rientrato per il ritaglio di Android 12
├── flutter_launcher_icons.yaml       configurazione dell'icona del launcher (§2bis)
├── flutter_native_splash.yaml        configurazione della schermata di avvio (§2bis)
├── android/app/src/main/
│   ├── AndroidManifest.xml
│   ├── kotlin/com/smp/trashcan/MainActivity.kt
│   ├── kotlin/com/smp/trashcan/TrashcanWidgetProvider.kt
│   └── res/
│       ├── drawable/ic_notification.xml         icona monocromatica della barra di stato
│       ├── drawable/widget_header_background.xml  angoli in alto, fascia colorata
│       ├── drawable/widget_body_background.xml    angoli in basso, fondo bianco
│       ├── layout/trashcan_widget.xml           il layout del widget (solo RemoteViews)
│       ├── xml/trashcan_widget_info.xml
│       ├── values/strings.xml, values-it/strings.xml
│       │
│       │   ↓ da qui in giu': GENERATO, non si modifica a mano (§2bis)
│       ├── mipmap-*dpi/ic_launcher.png          icona legacy
│       ├── mipmap-anydpi-v26/ic_launcher.xml    icona adattiva + monochrome
│       ├── drawable-*dpi/ic_launcher_foreground.png, ic_launcher_monochrome.png
│       ├── values/colors.xml                    ic_launcher_background
│       ├── drawable*/launch_background.xml      splash fino ad Android 11
│       ├── drawable*/background.png             la tinta piatta della splash
│       └── values-v31/styles.xml, values-night-v31/styles.xml   splash di Android 12+
├── ios/                              generata il 2026-10-04 (vedi §2ter)
│   ├── Runner.xcworkspace                **questo** si apre in Xcode, non .xcodeproj
│   ├── Runner/Info.plist                 nome visualizzato, lingue, orientamenti
│   ├── Runner/Assets.xcassets/            icona generata dal logo
│   └── Runner/Base.lproj/LaunchScreen.storyboard   la schermata di avvio
├── test/                             127 test (vedi §9)
└── integration_test/first_run_test.dart
```

---

## 2ter. iOS

TrashCan gira su iOS dal **4 ottobre 2026**. Il progetto Xcode è stato generato con
`flutter create --platforms=ios --org com.smp --project-name trashcan .` dentro
`apps/trashcan/`, quindi l'identificativo del bundle è già `com.smp.trashcan`, lo stesso
`applicationId` di Android.

### Come si compila e si prova

Serve un Mac: Xcode non esiste altrove. La macchina di sviluppo iOS è il Mac mini
(`ssh mac`), con Flutter 3.47.3 in `~/microapps-toolchain/flutter`.

⚑ **Niente CocoaPods, e non è una dimenticanza.** Flutter 3.47 risolve i plugin iOS con
**Swift Package Manager**: non esiste un `Podfile`, non esiste una cartella `Pods`, e il
primo `flutter build ios` non scarica nessuno specfile. CocoaPods è installato sul Mac
perché `flutter doctor` lo cerca e perché serve ai progetti più vecchi, non a questo. Chi
cerca il `Podfile` per aggiungerci qualcosa sta per creare un file che nessuno leggerà.

```
export PATH="$HOME/microapps-toolchain/flutter/bin:/opt/homebrew/bin:$PATH"
cd ~/microapps/apps/trashcan
flutter build ios --simulator --debug
xcrun simctl install <UDID> build/ios/iphonesimulator/Runner.app
xcrun simctl launch  <UDID> com.smp.trashcan
```

⚑ La toolchain **non** sta in `.flutter/` come su Windows: quella cartella è esclusa dal
trasferimento perché pesa due giga ed è specifica del sistema operativo. Il Mac ha la sua
copia della stessa versione, 3.47.3. Due copie della stessa versione, non due versioni.

### Solo iPhone, anche sugli iPad

`TARGETED_DEVICE_FAMILY = 1`. Su iPad l'app si installa lo stesso e gira nella finestra di
compatibilità da telefono, centrata sullo sfondo del tablet.

☠ **Dichiararla universale non è gratis: è peggio.** Con `"1,2"` su un iPad il layout da
telefono si allarga invece di adattarsi: il testo attraversa tutta la pagina, il pulsante
diventa largo quanto lo schermo e in mezzo resta un vuoto enorme. Funziona, e sembra
trascurata. Verificato sul simulatore iPad mini il 2026-10-04, prima e dopo la modifica.

⚑ Conseguenza utile: la scheda App Store non ha bisogno di schermate per iPad.

### Come si carica su TestFlight

`tool/build_ios.sh`, da eseguire **sul Mac**: `ssh mac 'bash ~/microapps/tool/build_ios.sh'`.

☠ **Non apre Xcode e non chiede nessuna password**, ed è il motivo per cui esiste. Firma e
caricamento passano da una **chiave API di App Store Connect**, l'unico modo di fare tutto
questo da una sessione ssh. Con l'Apple ID dentro Xcode servirebbe qualcuno davanti allo
schermo a ogni rinnovo del certificato.

☠ **I tre identificativi non stanno nel repo.** Vivono in `~/.microapps-ios.env` sul Mac,
fuori da git, e la chiave privata sta in
`~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8`. Chi ha quel file può caricare build a
nome del titolare dell'account: non si committa e non si copia altrove.

⚑ Lo script fa `flutter build ios --no-codesign` e poi `xcodebuild archive` a mano invece
del più corto `flutter build ipa`: quest'ultimo non sa passare la chiave API a xcodebuild,
quindi la firma automatica fallirebbe chiedendo un Apple ID che in ssh non c'è.

⚑ `altool --validate-app` prima del caricamento vero: trasferire impiega minuti, e un
difetto d'icona o un permesso mancante si scoprirebbe altrimenti solo alla fine.

☠ **Il numero di build non si riusa**, esattamente come il `versionCode` di Play: Apple
rifiuta una build già vista per quella versione e quel numero non si libera. Viene dal
`pubspec.yaml`, unica fonte per tutte e due le piattaforme.

⚑ `ITSAppUsesNonExemptEncryption` sta a `false` in `Info.plist`. È la dichiarazione di
conformità all'esportazione, che Apple chiede a **ogni** build: senza la chiave, la domanda
ricompare a mano in App Store Connect ogni volta. Dichiara che l'app non usa cifratura
soggetta a restrizioni, il che vale finché si usano solo HTTPS, il portachiavi di sistema e
l'HMAC per autenticare le chiamate al License Server. **Se un giorno si aggiunge cifratura
vera dei dati, questa riga va rivista**: è una dichiarazione legale, non un'impostazione.

### Cosa su iOS non c'è, e perché

| Pezzo | Stato | Perché |
|---|---|---|
| Widget di casa | **presente** | estensione WidgetKit in `ios/TrashcanWidget/` (`TrashcanWidget.swift`, `VistaTrashcan.swift`), che legge le stesse righe precalcolate dal gruppo `group.com.smp.trashcan`. La timeline ha 7 voci a `startOfDay` e, dal 2026-10-10, il criterio `.after(prossima mezzanotte + 5 s)` invece di `.atEnd`: le voci sono istanti assoluti, e senza un ricaricamento quotidiano un cambio di fuso o d'ora spostava il cambio di giorno per fino a sette giorni |
| Acquisti | da verificare sul dispositivo | il gateway è neutro (`StorePurchaseGateway`), ma i prodotti vanno creati in App Store Connect e il simulatore non compra |
| Notifiche | codice pronto, da provare | `micro_core` inizializza ora anche il lato Darwin e chiede il permesso. Il simulatore le consegna, un dispositivo vero è un'altra cosa |

☠ **La voce "aggiungi il widget" nelle impostazioni compare solo dove il widget esiste.**
Mostrarla su iOS e poi rispondere "non supportato" al tocco è peggio che non mostrarla:
l'utente ha già deciso che la vuole, e si porta via l'idea che l'app sia difettosa invece
dell'idea, corretta, che su iPhone quella funzione non c'è ancora.

## 2bis. Icona e schermata di avvio

Il logo è **fornito dall'utente**: `assets/icons/trashcan_logo.png`, 1254x1254 ARGB, un
cestino verde con un calendario dietro e il simbolo del riciclo in basso a destra. Da quel
file si generano, con due pacchetti, tutte le risorse Android **e iOS**.

☠ **L'icona iOS non può avere un canale alfa.** App Store Connect rifiuta il caricamento di
un'app la cui icona sia trasparente, e lo fa a caricamento finito, non prima. Il logo è su
fondo trasparente, quindi `remove_alpha_ios: true` e `background_color_ios: "#2E7D5B"`
riempiono con lo stesso verde che Android usa come sfondo dell'icona adattiva: la stessa
icona sulle due piattaforme, non due parenti.

⚠️ **`assets/icons/` non è dichiarato in `pubspec.yaml` sotto `flutter: assets:`, ed è
giusto così**: quelle immagini sono ingressi dei generatori, non asset letti a runtime.
Dichiararle le impacchetterebbe nell'APK una seconda volta, a pura perdita.

⚠️ **Tutto ciò che i due comandi scrivono è rigenerabile e non si modifica a mano.** Una
correzione fatta direttamente su `mipmap-anydpi-v26/ic_launcher.xml` sopravvive fino alla
prima rigenerazione e poi sparisce, senza che nessuno se ne accorga. Si cambia lo `yaml` e
si rilancia.

### I due comandi

```
cd apps/trashcan
pwsh ../../tool/fl.ps1 pub run flutter_launcher_icons          # icona del launcher
pwsh ../../tool/fl.ps1 pub run flutter_native_splash:create    # schermata di avvio
```

### `flutter_launcher_icons.yaml`

| Chiave | Valore | Perché |
|---|---|---|
| `image_path` | `assets/icons/trashcan_logo.png` | icona legacy, pre-Android 8 |
| `adaptive_icon_background` | `#2E7D5B` | il verde del tema: il tondo attorno al logo |
| `adaptive_icon_foreground` | il logo | il livello che il launcher anima e maschera |
| `adaptive_icon_foreground_inset` | `18` | il margine dentro la maschera adattiva |
| `adaptive_icon_monochrome` | il logo | il livello per i temi colorati di Android 13 |
| `min_sdk_android` | `24` | allineato al `minSdk` del progetto |

`adaptive_icon_foreground_inset: 18` non è estetica: il launcher ritaglia il livello di
primo piano con una maschera di forma variabile (tondo, quadrotto, goccia, dipende
dall'OEM) e ne garantisce visibile solo il 66% centrale. Senza rientro il cestino perde il
manico su metà dei telefoni.

### `flutter_native_splash.yaml`

Fondo `#2E7D5B` in chiaro, `#16241E` in scuro, con il logo al centro in entrambi i casi.

☠ **La sezione `android_12:` usa un'immagine diversa**, `trashcan_splash_android12.png`.
Da Android 12 la splash non è più un tema con un drawable di sfondo ma un'API di sistema,
che disegna l'immagine in un quadrato di 240dp e la **ritaglia con un cerchio di 160dp**:
sopravvivono solo i due terzi centrali. Con il logo a pieno formato, sull'emulatore si
vedeva il manico del cestino tagliato in alto e il simbolo del riciclo mangiato in basso a
destra. Il file rimediato è lo stesso logo su una tela trasparente 1152x1152 con il disegno
confinato nei 768x768 centrali, cioè esattamente la zona che sopravvive. Si rigenera
scalando il logo al 66,7% e centrandolo.

### Cosa NON deriva dal logo

`drawable/ic_notification.xml` resta **disegnato a mano e monocromatico**, e non va
sostituito con il logo. Android ignora i colori dell'icona di notifica e ne usa solo il
canale alfa, ridisegnandola in bianco: il logo, opaco ovunque, diventerebbe una macchia.

---

## 3. Il database

Quattro tabelle, `schemaVersion = 1`. Le date civili sono TEXT `YYYY-MM-DD` (ADR-008), gli
istanti sono interi in millisecondi UTC.

### `collection_calendars`

| Colonna | Tipo | Vincoli | Significato |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `name` | TEXT | 1..60 | "Casa", "Casa al mare" |
| `notification_time` | TEXT | 5..5, default `20:00` | orario del promemoria, `HH:mm` |
| `second_notification_time` | TEXT | 5..5, nullable | secondo promemoria, funzione Pro |
| `enabled` | BOOL | default true | promemoria attivi per questo calendario |
| `sort_order` | INTEGER | default 0 | |
| `created_at` | INTEGER | obbligatorio | ms UTC |

L'orario è testo e non due interi: si legge e si scrive sempre insieme, non si interroga mai
per ora separata dai minuti, e in forma testuale è ispezionabile a occhio in un dump.

### `waste_types`

| Colonna | Tipo | Vincoli | Significato |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `calendar_id` | INTEGER | FK → `collection_calendars.id`, ON DELETE CASCADE | |
| `name` | TEXT | 1..40 | |
| `icon_key` | TEXT | 1..32 | chiave in `WasteIcons.byKey`, **mai** un codepoint |
| `color_value` | INTEGER | obbligatorio | ARGB |
| `notifications_enabled` | BOOL | default true | |
| `sort_order` | INTEGER | default 0 | |

☠ `icon_key` è una chiave e non un `IconData.codePoint`: salvare il codepoint rompe il tree
shaking delle icone e in release produce quadrati vuoti.

### `recurrence_rules`

Tabella volutamente larga: molte colonne nullable, di cui solo alcune valide per ciascun
`kind`. Cinque tabelle separate sarebbero cinque join per un dato che si legge sempre tutto
insieme e che non supera qualche decina di righe per utente. La larghezza si paga con la
validazione nel mapper, che è un posto solo.

| Colonna | Tipo | Valido per | Significato |
|---|---|---|---|
| `id` | INTEGER | | PK |
| `waste_type_id` | INTEGER | | FK → `waste_types.id`, CASCADE |
| `kind` | TEXT 1..24 | | `weekly` \| `everyNWeeks` \| `monthlyDay` \| `monthlyNthWeekday` \| `manual` |
| `weekdays_mask` | INTEGER, default 0 | weekly, everyNWeeks | bit 0 = lunedì, bit 6 = domenica |
| `interval_weeks` | INTEGER nullable | everyNWeeks | ≥ 2 |
| `anchor_date` | TEXT nullable | everyNWeeks | fissa la fase del ciclo |
| `day_of_month` | INTEGER nullable | monthlyDay | 1..31, clamp a fine mese |
| `nth_of_month` | INTEGER nullable | monthlyNthWeekday | 1..5 oppure **-1 = l'ultimo** |
| `weekday` | INTEGER nullable | monthlyNthWeekday | 1..7 |
| `manual_dates_csv` | TEXT nullable | manual | date `YYYY-MM-DD` separate da virgola |
| `start_date` | TEXT 10..10 | tutti | obbligatoria |
| `end_date` | TEXT nullable | tutti | |

### `collection_exceptions`

La data class generata si chiama **`ExceptionRow`**, non `CollectionException`: il nome
naturale collide con la classe di dominio omonima, e due tipi con lo stesso nome nello stesso
file sono attrito che si paga a ogni import per anni.

| Colonna | Tipo | Significato |
|---|---|---|
| `id` | INTEGER | PK |
| `waste_type_id` | INTEGER | FK → `waste_types.id`, CASCADE |
| `original_date` | TEXT nullable | la data prevista dalla regola |
| `replacement_date` | TEXT nullable | la data nuova |
| `skipped` | BOOL default false | |
| `note` | TEXT nullable | |
| `created_at` | INTEGER | ms UTC |

Tre combinazioni ammesse, e nessun'altra:

| Forma | `original_date` | `replacement_date` | `skipped` |
|---|---|---|---|
| salta | valorizzata | null | true |
| sposta | valorizzata | valorizzata | false |
| straordinaria | null | valorizzata | false |

---

## 4. `lib/domain/` — il cuore, senza database

### `sealed class Recurrence`

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `const Recurrence({required CivilDate startDate, CivilDate? endDate})` | |
| `startDate` | `final CivilDate` | prima data in cui la regola vale |
| `endDate` | `final CivilDate?` | ultima, inclusa |
| `occursOn` | `bool occursOn(CivilDate date)` | `matches` **e** dentro l'intervallo |
| `matches` | `bool matches(CivilDate date)` | astratto: la forma della ricorrenza |
| `occurrencesIn` | `Iterable<CivilDate> occurrencesIn(CivilDate from, CivilDate to)` | |

Le cinque sottoclassi:

| Classe | Campi propri | Note |
|---|---|---|
| `WeeklyRecurrence` | `Set<int> weekdays` | |
| `EveryNWeeksRecurrence` | `Set<int> weekdays`, `int intervalWeeks` (≥2), `CivilDate anchor` | il costruttore prende `anchorDate:`, il campo si chiama `anchor` |
| `MonthlyDayRecurrence` | `int dayOfMonth` | clamp a fine mese |
| `MonthlyNthWeekdayRecurrence` | `int nth` (1..5 o -1), `int weekday` | |
| `ManualDatesRecurrence` | `Set<CivilDate> dates` | il costruttore prende un `Iterable` |

⚑ `EveryNWeeksRecurrence` non usa il numero di settimana ISO: cambia significato a cavallo
dell'anno e produrrebbe un salto o un raddoppio fra dicembre e gennaio. Usa invece la
distanza in settimane dall'ancora, in entrambe le direzioni.

### `abstract final class WeekdayMask`

| Metodo | Firma |
|---|---|
| `fromSet` | `static int fromSet(Set<int> weekdays)` |
| `toSet` | `static Set<int> toSet(int mask)` |

### `class OccurrenceEngine`

`const OccurrenceEngine()`.

| Metodo | Firma |
|---|---|
| `expand` | `List<CollectionOccurrence> expand({required List<RuleWithExceptions> rules, required CivilDate from, required CivilDate to})` |
| `onDate` | `List<CollectionOccurrence> onDate(CivilDate date, {required List<RuleWithExceptions> rules})` |
| `tonight` | `List<CollectionOccurrence> tonight({required List<RuleWithExceptions> rules, CivilDate? today})` |
| `next` | `CollectionOccurrence? next({required List<RuleWithExceptions> rules, CivilDate? from})` |
| `nextN` | `List<CollectionOccurrence> nextN(int count, {required List<RuleWithExceptions> rules, CivilDate? from, int horizonDays = 800})` |

`CollectionOccurrence`: `wasteTypeId`, `date`, `origin` (`regular` \| `moved` \| `extra`),
`originalDate` (per le spostate), `note`.

`RuleWithExceptions`: `wasteTypeId`, `recurrence`, `exceptions`, `sortOrder`.

---

## 5. `lib/data/`

### `class AppDatabase extends _$AppDatabase`

| Membro | Firma |
|---|---|
| apertura normale | `factory AppDatabase.open()` |
| in memoria, per i test | `factory AppDatabase.memory()` |
| versione | `int get schemaVersion => 1` |

### `class CalendarBundle`

`const CalendarBundle({required CollectionCalendar calendar, required List<WasteType> wasteTypes, required List<RuleWithExceptions> rules})`
più `WasteType? typeOf(int id)`.

### `extension AppDatabaseQueries on AppDatabase`

| Metodo | Firma | Note |
|---|---|---|
| `watchCalendars` | `Stream<List<CollectionCalendar>> watchCalendars()` | |
| `allCalendars` | `Future<List<CollectionCalendar>> allCalendars()` | serve al pianificatore: copre **tutti** i calendari |
| `countCalendars` | `Future<int> countCalendars()` | |
| `watchWasteTypes` | `Stream<List<WasteType>> watchWasteTypes(int calendarId)` | |
| `watchAnyChange` | `Stream<void> watchAnyChange()` | un segnale a ogni modifica di una delle 4 tabelle |
| `watchBundle` | `Stream<CalendarBundle?> watchBundle(int calendarId)` | vedi la trappola in §10 |
| `loadBundle` | `Future<CalendarBundle?> loadBundle(int calendarId)` | |

### `extension RecurrenceRuleMapper on RecurrenceRule`

`Recurrence? toDomain()` — `null` se la riga è incoerente col proprio `kind`. **Non lancia**:
una riga storta, arrivata da un import o da una versione futura, deve far sparire quella
regola, non rendere l'app inutilizzabile.

### `extension CollectionExceptionMapper on ExceptionRow`

`CollectionException? toDomain()` — `null` se la riga non è una delle tre forme ammesse.

### `class TrashcanRepository`

`const TrashcanRepository(AppDatabase db)`. **Tutte** le scritture passano da qui.

| Metodo | Firma |
|---|---|
| `createCalendar` | `Future<int> createCalendar({required String name, String notificationTime = '20:00'})` |
| `renameCalendar` | `Future<void> renameCalendar(int id, String name)` |
| `setCalendarNotification` | `Future<void> setCalendarNotification(int id, {required String time, String? secondTime, bool? enabled})` |
| `deleteCalendar` | `Future<void> deleteCalendar(int id)` |
| `createWasteType` | `Future<int> createWasteType({required int calendarId, required String name, required String iconKey, required int colorValue, int? sortOrder})` |
| `updateWasteType` | `Future<void> updateWasteType(int id, {String? name, String? iconKey, int? colorValue, bool? notificationsEnabled})` |
| `deleteWasteType` | `Future<void> deleteWasteType(int id)` |
| `reorderWasteTypes` | `Future<void> reorderWasteTypes(List<int> orderedIds)` |
| `setWeeklyRule` | `Future<void> setWeeklyRule({required int wasteTypeId, required Set<int> weekdays, CivilDate? startDate, CivilDate? endDate})` |
| `setEveryNWeeksRule` | `Future<void> setEveryNWeeksRule({required int wasteTypeId, required Set<int> weekdays, required int intervalWeeks, required CivilDate anchorDate, CivilDate? startDate, CivilDate? endDate})` |
| `setMonthlyDayRule` | `Future<void> setMonthlyDayRule({required int wasteTypeId, required int dayOfMonth, CivilDate? startDate, CivilDate? endDate})` |
| `setMonthlyNthWeekdayRule` | `Future<void> setMonthlyNthWeekdayRule({required int wasteTypeId, required int nth, required int weekday, CivilDate? startDate, CivilDate? endDate})` |
| `setManualDatesRule` | `Future<void> setManualDatesRule({required int wasteTypeId, required List<CivilDate> dates, CivilDate? startDate, CivilDate? endDate})` |
| `setRule` | `Future<void> setRule({required int wasteTypeId, required Recurrence recurrence})` |
| `clearRules` | `Future<void> clearRules(int wasteTypeId)` |
| `ruleOf` | `Future<Recurrence?> ruleOf(int wasteTypeId)` |
| `skipCollection` | `Future<int> skipCollection({required int wasteTypeId, required CivilDate date, String? note})` |
| `moveCollection` | `Future<int> moveCollection({required int wasteTypeId, required CivilDate from, required CivilDate to, String? note})` |
| `addExtraCollection` | `Future<int> addExtraCollection({required int wasteTypeId, required CivilDate date, String? note})` |
| `removeException` | `Future<void> removeException(int id)` |
| `watchExceptions` | `Stream<List<ExceptionRow>> watchExceptions(int calendarId)` |
| `createCalendarFromWizard` | `Future<int> createCalendarFromWizard({required String name, required String notificationTime, required List<WizardWasteType> types})` |

Tutte le `set*Rule` e `setRule` **sostituiscono** le regole esistenti del tipo, in
transazione: nella UI c'è un solo insieme di giorni, non una collezione di regole
sovrapposte.

`class WizardWasteType`: `name`, `iconKey`, `colorValue`, `Set<int> weekdays`, più
`copyWith({Set<int>? weekdays, String? name})`.

### `extension RecurrenceToRow on Recurrence`

`RecurrenceRulesCompanion toCompanion(int wasteTypeId)` — l'inverso di `toDomain()`. Le due
direzioni vivono in file diversi: la lettura deve tollerare righe storte, la scrittura parte
da un oggetto valido per costruzione. **Se tocchi una, controlla l'altra.**

---

## 6. `lib/app/providers.dart`

Da sovrascrivere in `main()`, altrimenti l'app non parte: `appConfigProvider`,
`appPathsProvider`, `settingsProvider`.

| Provider | Tipo | Cosa espone |
|---|---|---|
| `databaseProvider` | `Provider<AppDatabase>` | apre e chiude il database |
| `repositoryProvider` | `Provider<TrashcanRepository>` | |
| `installIdProvider` | `FutureProvider<InstallId>` | |
| `purchaseGatewayProvider` | `Provider<PurchaseGateway>` | Play o finto, secondo `BILLING` |
| `entitlementProvider` | `NotifierProvider<EntitlementNotifier, EntitlementView>` | `.notifier.service` per le azioni |
| `isProProvider` | `Provider<bool>` | |
| `featureGateProvider` | `Provider<FeatureGate>` | |
| `backupServiceProvider` | `Provider<BackupService>` | |
| `themeModeProvider` | `NotifierProvider<ThemeModeNotifier, ThemeMode>` | `.set(mode)` |
| `onboardingDoneProvider` | `Provider<bool>` | |
| `selectedCalendarProvider` | `NotifierProvider<SelectedCalendar, int?>` | `.select(id)` |
| `calendarsProvider` | `StreamProvider<List<CollectionCalendar>>` | |
| `activeCalendarProvider` | `Provider<CollectionCalendar?>` | il selezionato, o il primo |
| `activeBundleProvider` | `StreamProvider<CalendarBundle?>` | |
| `occurrencesProvider` | `Provider<List<CollectionOccurrence>>` | 120 giorni, calcolati **una volta** |
| `tonightProvider` | `Provider<List<CollectionOccurrence>>` | le raccolte di **domani** |
| `nextOccurrenceProvider` | `Provider<CollectionOccurrence?>` | la prima dopo stasera |
| `upcomingWeekProvider` | `Provider<List<CollectionOccurrence>>` | i prossimi 7 giorni |
| `notificationServiceProvider` | `FutureProvider<NotificationService>` | creato al primo uso, non in `main()` |
| `schedulerProvider` | `Provider<TrashcanScheduler>` | |
| `notificationSyncProvider` | `Provider<void>` | tiene notifiche **e** widget allineati ai dati |
| `notificationsEnabledProvider` | `NotifierProvider<NotificationsEnabled, bool>` | `.set(value)` |
| `seedColorProvider` | `NotifierProvider<SeedColor, Color>` | il colore generale dell'app, `.set(color)` |

`EntitlementView` è un valore immutabile con `entitlement`, `busy`, `storeAvailable`,
`product`, `error`, più `isPro` e `isPending`. Esiste perché `EntitlementService` è un
`ChangeNotifier` e Riverpod 3 ha spostato `ChangeNotifierProvider` fra le API legacy:
rispecchiarlo in un valore rende esplicito **cosa** fa ridisegnare la UI.

`appVersion` è la costante `'0.1.0'` in questo file: compare nel backup, nelle chiamate al
server e nella schermata delle informazioni. Tenerla in tre posti garantirebbe che divergano.

---

## 7. Le rotte

Dichiarate in `lib/app/routes.dart`, registrate in `lib/app/app.dart`.

| Costante | Percorso | Pagina |
|---|---|---|
| `Routes.home` | `/` | `HomePage` |
| `Routes.onboarding` | `/onboarding` | `OnboardingPage` |
| `Routes.calendars` | `/calendars` | `CalendarsPage` |
| `Routes.calendarNew` | `/calendars/new` | `CalendarEditorPage` |
| `Routes.calendarEdit` | `/calendars/:calendarId/edit` | `CalendarEditorPage` |
| `Routes.wasteTypes` | `/waste-types` | `WasteTypesPage` |
| `Routes.wasteTypeNew` | `/waste-types/new` | `WasteTypeEditorPage` |
| `Routes.wasteTypeEdit` | `/waste-types/:wasteTypeId/edit` | `WasteTypeEditorPage` |
| `Routes.day` | `/day/:date` (+ `?calendar=<id>`) | `DayPage` — **bersaglio delle notifiche** |
| `Routes.exceptions` | `/exceptions` | `ExceptionsPage` |
| `Routes.settings` | `/settings` | `SettingsPage` |
| `Routes.notifications` | `/settings/notifications` | `NotificationsPage` |
| `Routes.backup` | `/settings/backup` | `BackupPage` |
| `Routes.restore` | `/settings/restore` | `RestorePage` |

Helper: `Routes.dayOf(String iso)`, `Routes.calendarEditOf(int id)`,
`Routes.wasteTypeEditOf(int id)`, `Routes.rulesOf(int wasteTypeId)`.

Un `redirect` porta all'onboarding chi non l'ha completato, da qualunque punto entri, e
riporta alla home chi lo ha già fatto.

**Non ha una rotta**: l'editor delle regole. È un sotto-passaggio che restituisce un valore
al chiamante, non una destinazione raggiungibile da un deep link. Si apre con
`Navigator.push` e restituisce un `RuleEditorResult`, il cui campo `recurrence` a `null`
significa "togli i giorni di raccolta" e va distinto dall'annullamento (pop senza valore).

---

## 8. `lib/services/`

### `class TrashcanScheduler implements NotificationScheduler`

`TrashcanScheduler({required AppDatabase db, required SettingsStore settings, required FeatureGate gate, required String appName, NotificationService? notifications})`

| Membro | Firma | Effetto |
|---|---|---|
| `horizonDays` | `static const int = 60` | |
| `maxScheduled` | `static const int = 64` | il limite di Android |
| `isReady` | `bool get isReady` | c'è un servizio a cui consegnare |
| `rescheduleAll` | `Future<void> rescheduleAll()` | ricalcola e sostituisce |
| `rescheduleIfStale` | `Future<void> rescheduleIfStale()` | solo se è passata un'ora |
| `cancelAll` | `Future<void> cancelAll()` | |
| `computeSchedule` | `Future<List<ScheduledNotification>> computeSchedule({CivilDate? today, DateTime? now})` | **puro**: non tocca il plugin |
| `timesFor` | `List<TimeOfDay> timesFor(CollectionCalendar calendar)` | uno gratis, due col Pro |

Funzioni di modulo: `TimeOfDay? parseTime(String?)` (non lancia mai),
`String formatTime(TimeOfDay)`.

Costante di modulo: `const MicroNotificationChannel trashcanChannel` — un canale solo, perché
su Android l'utente può silenziare i canali singolarmente e spezzare i promemoria in più
canali offrirebbe un modo di silenziarne metà senza accorgersene.

Regole del piano: una notifica **per giorno e per calendario**, non per tipo; la sera
**prima** della raccolta; niente notifiche nel passato; id derivati da
`NotificationIds.forOccurrence(calendarId, date, slot)` perché la ripianificazione
sovrascriva invece di accumulare; ordinato per istante e troncato a 64; titolo col nome del
calendario solo se ce n'è più d'uno; payload `/day/YYYY-MM-DD?calendar=<id>`, cioè il
percorso interno di `go_router`.

### `abstract final class TrashcanWidget`

| Membro | Firma |
|---|---|
| `qualifiedName` | `static const String = 'com.smp.trashcan.TrashcanWidgetProvider'` |
| chiavi | `keyDays`, `keyTonightLabel`, `keyCalendarName`, `keyUpcomingEmpty`, `keyStale`, `iconKeyPrefix` |
| separatori | `fieldSeparator` = `\u001F`, `lineSeparator` = `\u001E`, `newline` |
| orizzonte | `giorniPrecalcolati` = `3650`, `giorniElencati` = `3` |
| `newline` | `static const String = '\n'`, il separatore fra le righe dei prossimi giorni |
| `iconSide` | `static const int = 96`, il lato in pixel del PNG dell'icona |
| `giorniElencati` | `static const int = 3`, quanti giorni elenca la fascia inferiore. **Uguale per tutti** |
| `publish` | `static Future<void> publish({required AppDatabase db, required int? calendarId, required bool pro})` |
| `renderIcon` | `static Future<Uint8List> renderIcon(IconData icon)` — `@visibleForTesting` |
| `scheduleDailyRefresh` | `static Future<void> scheduleDailyRefresh()` — consegna al plugin `istantiDiRisveglio(DateTime.now())`. Solo Android |
| `secondiDopoMezzanotte` | `static const int = 5`, il risveglio **finale** di ogni giorno cade alle 00:00:05. Uguale a `SECONDI_DOPO_MEZZANOTTE` in Kotlin |
| `secondiFineFinestra` | `static const int = 30`, la finestra del **preavviso** finisce alle 00:00:30. Uguale a `SECONDI_FINE_FINESTRA` in Kotlin |
| `finestraMassima` | `static const Duration = Duration(hours: 1)`, il tetto della finestra di un allarme inesatto (`INTERVAL_HOUR` in `AlarmManagerService.maxTriggerTime`) |
| `quotaFinestra` | `static const double = 0.75`, la finestra inesatta è il 75% del preavviso |
| `istantiDiRisveglio` | `static List<DateTime> istantiDiRisveglio(DateTime adesso, {int giorni = giorniPrecalcolati})` — `@visibleForTesting`. Due istanti per giorno, in ordine: preavviso e finale. Il primo giorno può non avere il preavviso |
| `preavvisoArmatoAlle` | `static DateTime? preavvisoArmatoAlle(DateTime adesso, DateTime fineFinestra)` — `@visibleForTesting`. L'istante da chiedere armando adesso perché la finestra finisca in `fineFinestra`; `null` sotto un minuto |

Le chiavi **devono** coincidere con le costanti in `TrashcanWidgetProvider.kt`: sono scritte
a mano in due linguaggi diversi, e una divergenza produce un campo vuoto nel widget senza
nessun errore da nessuna parte.

☠ Il parametro `pro` di `publish` **non decide più quanti giorni si vedono**. Fino all'11
settembre 2026 era `pro ? 3 : 1`: la versione gratuita mostrava una riga sola, e il
proprietario, guardando il widget vero sul proprio telefono, l'ha letta come un difetto
("è sbagliato il widget"). Non stava sbagliando lui. Una riga in mezzo a metà widget bianca
non comunica "funzione a pagamento", comunica "non ha caricato", e chi lo pensa disinstalla.

Il commento che stava nel codice sosteneva che una riga sola "lascia vedere cosa si guadagna
ad averne tre": era una supposizione, smentita dal primo essere umano che ha guardato il
widget. Il parametro resta nella firma perché il chiamante lo ha già e perché il giorno in
cui il widget tornerà a distinguere qualcosa fra gratuito e Pro — per esempio la scelta del
calendario — servirà di nuovo.

`scheduleDailyRefresh` programma i risvegli del widget per tutto l'orizzonte (vedi la
sezione qui sotto, «Come il widget cambia giorno a mezzanotte»). Senza, dopo mezzanotte il
widget continua a dire "stasera: organico" riferendosi alla sera precedente, cioè proprio la
mattina, quando lo si guarda uscendo di casa.

#### Come il widget cambia giorno a mezzanotte (correzione del 2026-10-10)

☠ **Il difetto.** Il proprietario: «alle 00:00 deve cambiare da solo», e invece il widget
cambiava solo aprendo l'app. Misurato sull'emulatore `Medium_Phone_API_35` (Android 15,
targetSdk 36), con l'app chiusa:

| Misura | Valore | Cosa vuol dire |
|---|---|---|
| `dumpsys alarm`, allarme del plugin | `origWhen=… 00:05:00 window=+1h0m0s flags=0x20` | alle 00:05, **inesatto** (`0x20` = `ALLOW_WHILE_IDLE_COMPAT`, cioè `setAndAllowWhileIdle`) |
| `dumpsys package`, permessi | `SCHEDULE_EXACT_ALARM` richiesto, **non concesso** | da Android 14 non è concesso di default, quindi `canScheduleExactAlarms()` è falso |
| consegna in Doze forzato | finestra di 59 s → arrivato a **fine finestra** | il «lazy batching» di Android 14+: gli inesatti si consegnano alla fine |
| consegna con lo schermo riacceso a metà finestra | finestra 92 s, schermo acceso alle 00:00:30, arrivato alle **00:01:37** | riaccendere il telefono **non** anticipa niente |
| cambio di fuso GMT → Europe/Rome | l'allarme delle 00:05 GMT è diventato quello delle **02:05** | gli istanti sono assoluti, calcolati nel fuso di quando l'app era aperta |
| schermata alle 00:01, app chiusa | il widget mostrava ancora il giorno prima | difetto riprodotto |

Quindi: la finestra di un allarme inesatto è il **75% del preavviso** con cui lo si arma,
**al massimo un'ora** (`AlarmManagerService.maxTriggerTime`), e Android 14+ lo consegna alla
**fine** della finestra. Un allarme per le 00:00:05 armato il giorno prima arriva verso
**l'una**, ogni notte, con lo schermo acceso o spento.

⚑ **La correzione usa la stessa regola a favore.** `istantiDiRisveglio` mette, per ogni
giorno, un **preavviso** alle 23:00:30 (finestra piena di un'ora → consegna alle 00:00:30) e
un risveglio **finale** alle 00:00:05. Il plugin arma un allarme per volta e il successivo
quando scatta il precedente, cioè quasi un giorno prima: finestra sempre piena.

| Sistema | Cosa succede |
|---|---|
| Android 14+, senza permesso esatto | il preavviso arriva alle 00:00:30 e ridisegna il giorno nuovo; il finale delle 00:00:05 è già passato e il plugin lo scarta. **Misurato in Doze profondo con l'app uccisa: consegna alle 00:00:29**, widget giusto, prossimo preavviso armato a 23:00:30 `+1h` |
| Android 13 e precedenti (consegna a inizio finestra), o permesso esatto concesso | il preavviso scatta alle 23:00:30 e ridisegna lo stesso giorno (innocuo); il finale arriva alle 00:00:05. Con il permesso: `window=0 exactAllowReason=permission`, misurato |

Il **primo** preavviso viene armato quando si apre l'app, non un giorno prima: se mancano
meno di due ore e venti, `preavvisoArmatoAlle` risolve `T + 0,75·(T − adesso) = 00:00:30` e
la consegna resta giusta (aprire l'app alle 22:30 non deve far scattare il preavviso alle
23:23). Misurato: con l'orologio alle 23:57 l'allarme è stato armato alle 23:59:00 con
finestra di 89 s, consegnato alle 00:00:29.

Le **reti di sicurezza**, se gli allarmi non arrivano (produttori che li bloccano, permesso
revocato):

- `updatePeriodMillis="1800000"` in `trashcan_widget_info.xml`: lo pilota il servizio dei
  widget di sistema, non l'app; il ridisegno sceglie la riga dalla data del momento, quindi il
  primo giro dopo mezzanotte corregge il widget. Prima era `0`.
- `TrashcanWidgetProvider.onReceive` ascolta `TIME_SET`, `TIMEZONE_CHANGED` e
  `MY_PACKAGE_REPLACED` (trasmissioni esenti dai limiti in background, verificato con l'app
  chiusa): ridisegna e **ricalcola gli istanti** nel fuso nuovo con
  `riarmaMezzanotti`, la stessa regola di Dart ripetuta in Kotlin.
- `TrashcanWidgetProvider.onEnabled` ricalcola gli istanti quando si aggiunge il primo widget.

☠ **`DATE_CHANGED` è stata provata e scartata.** Sembrava perfetta (la mezzanotte annunciata
dal sistema, senza permessi), ma non è fra le trasmissioni esenti: `dumpsys activity
broadcasts` mostrava *"skipped by policy at enqueue: Background execution not allowed"* per
il receiver del manifest.

☠ **`USE_EXACT_ALARM` non si usa**: Play lo riserva a sveglie e calendari come funzione
principale, e il manifest spiega già perché non regge per un'app di promemoria domestici. Il
permesso esatto (`SCHEDULE_EXACT_ALARM`) resta quello che l'utente può concedere dalla pagina
dei promemoria: se lo concede, anche il widget diventa esatto. Nessuna richiesta in più solo
per il widget: il preavviso basta.

#### Perché il widget contiene dieci anni, e non il giorno di oggi

☠ **Un widget Android non può far girare Flutter per aggiornarsi.** Vive nel processo
dell'app ma viene ridisegnato dal sistema, e Dart gira solo quando l'app è aperta. Fino al
16 settembre 2026 il widget conteneva le stringhe di **un giorno solo**: a mezzanotte
continuava a dire "stasera: organico" riferendosi alla sera passata, finché qualcuno non
apriva l'app. L'ha segnalato il proprietario, non un test: «adesso devo aprire l'app per far
aggiornare il widget».

Erano **due** difetti sovrapposti, ed è il motivo per cui la prima correzione plausibile
(«manca l'allarme») non avrebbe risolto niente:

1. `HomeWidgetScheduledUpdateReceiver` non era dichiarato nel manifest. L'allarme di mezzanotte
   veniva armato, scattava, e la trasmissione cadeva nel vuoto. Il plugin lascia la
   dichiarazione all'app di proposito, così chi non pianifica aggiornamenti non eredita il
   permesso di avvio al boot. Nessun errore, da nessuna parte.
2. Anche fosse arrivata, il ridisegno rileggeva **le stesse stringhe**. Non c'era niente di
   nuovo da mostrare.

La soluzione **non** è far girare Dart in background: servirebbero un isolate, una seconda
connessione al database e la benevolenza del sistema operativo, e fallirebbe in silenzio sui
telefoni che uccidono i processi. La soluzione è precalcolare. Dart prepara **3650 stati, uno
per giorno**, e Kotlin sceglie quello che porta la data di oggi. Kotlin non calcola niente e
non conosce né calendari né lingue: confronta stringhe.

#### Il formato delle righe

Una riga per giorno, separate da `\n`; dentro la riga, cinque campi separati da
`fieldSeparator`:

| # | Campo | Esempio |
|---|---|---|
| 0 | data, in forma `AAAA-MM-GG` | `2026-09-15` |
| 1 | cosa si porta fuori stasera, o il testo di "niente" | `Organico` |
| 2 | colore ARGB come intero; `0` significa "usa il neutro" | `4284644662` |
| 3 | **chiave** dell'icona, vuota se non ce n'è | `compost` |
| 4 | i prossimi `giorniElencati`, separati da `lineSeparator` | `dom 20   Carta` |

La riga di un giorno parla della raccolta del **giorno dopo**: il bidone si porta fuori la
sera prima.

⚑ **Righe e non JSON.** Il provider deve trovare **una riga su tremilaseicentocinquanta**:
cercare `"\n2026-09-15\u001F"` costa quanto una ricerca di sottostringa, mentre analizzare
tutto il JSON costerebbe quanto il decennio intero, dentro un `BroadcastReceiver` che ha un
budget di tempo stretto. È questa scelta ad aver reso gratuito allungare l'orizzonte.

☠ **I separatori sono caratteri di controllo** (US e RS), non `|` o `;`. Un tipo di rifiuto
chiamato "Carta | Cartone" spaccherebbe la riga e il widget mostrerebbe i campi sfasati, il
colore al posto del nome, senza nessun errore. Una tastiera non produce US e RS.

☠ La riga porta la **chiave** dell'icona, non il percorso: il percorso è lungo una settantina
di caratteri e si ripeterebbe in ognuna delle 3650 righe. Il provider lo ritrova leggendo
`icon_<chiave>` dalle stesse preferenze, dove l'ha messo `HomeWidget.saveFile`.

#### Quanto costa un decennio, e perché non costa

Tre costi, guardati prima di scegliere il numero. Il proprietario aveva chiesto dieci anni
(«parliamo di kbyte») contro un orizzonte di un anno che avevo motivato male.

| Costo | Quanto | Perché non pesa |
|---|---|---|
| Spazio | **420 KB misurati** in `HomeWidgetPreferences.xml` | una preferenza, riscritta una volta per pubblicazione. Sono piu' dei ~330 KB delle righe: le preferenze sono XML, e ogni separatore di controllo ci finisce scritto come `&#31;`, cinque caratteri invece di uno |
| Lettura | una ricerca di sottostringa | il formato a righe: non dipende dal numero di giorni |
| Sveglie | 7300 istanti (preavviso e finale per giorno) in un `JSONArray` di ~100 KB | il plugin arma **un allarme per volta** e riarma il successivo a ogni scatto; il sistema ne vede sempre uno |
| Calcolo | 3650 giri di ciclo | vedi sotto: era il costo vero, ed è stato tolto |

⚑ **Il calcolo era il costo vero, e stava in `DateFormat`.** `publish` gira a ogni avvio e a
ogni modifica dei dati, e l'operazione cara del giro è formattare il nome del giorno nella
lingua corrente. Ogni raccolta compare nell'elenco di tre giorni diversi, quindi formattandola
dentro il ciclo la si formattava tre volte: con un decennio sarebbero state decine di migliaia
di chiamate a ogni salvataggio di una regola. Adesso `publish` costruisce prima la mappa
`etichette`, **una voce per raccolta**, e il ciclo dei giorni si limita a unire stringhe già
pronte. Il decennio costa meno dell'anno di prima.

⚑ La costruzione è **lineare** anche nell'altra direzione: le raccolte si raggruppano per data
una volta sola e un puntatore (`primaDopo`) avanza insieme al giorno, senza mai tornare
indietro. Filtrando la lista per ogni giorno il costo sarebbe il prodotto fra giorni e
raccolte, cioè decine di milioni di confronti.

⚑ La finestra di espansione è `giorniPrecalcolati + 120`. L'ultima riga del decennio deve
comunque poter elencare le sue tre raccolte successive, e con una regola mensile la terza cade
tre mesi dopo. Senza il margine, le ultime righe avrebbero la fascia inferiore vuota e nessuno
capirebbe perché proprio quelle.

⚑ Finite le righe, il provider scrive `keyStale` - "Apri TrashCan per aggiornare" - invece di
mostrare un giorno sbagliato. Un decennio di righe non promette che il 2036 sarà così: è
esattamente ciò che l'app stessa mostra scorrendo avanti, cioè le regole di oggi proiettate.

#### L'icona di "stasera", nel widget

L'intestazione mostra l'icona del tipo di rifiuto accanto al nome, **la stessa della card
"Stasera" della home**. Con più tipi la stessa sera, icona e colore vengono entrambi dal
primo: prenderli da due tipi diversi darebbe un'intestazione arancione con l'icona del
vetro, che è peggio che non avere l'icona.

⚑ **Perché un PNG disegnato a runtime e non un vector drawable.** L'icona è un glifo del
font Material, scelto per chiave in `WasteIcons`. `RemoteViews` non sa disegnare glifi: sa
mostrare un drawable o un bitmap. Ricopiare le ventidue icone in altrettanti vector drawable
sotto `res/` darebbe **due cataloghi da tenere allineati a mano**, e la prima icona aggiunta
in Dart e dimenticata in `res/` darebbe un widget con un quadrato vuoto. `renderIcon`
disegna invece il glifo dallo stesso font e dalla stessa mappa che usa la card: per
costruzione non possono divergere.

Il percorso del PNG viaggia sotto `keyTonightIcon` (lo scrive `HomeWidget.saveFile`, che
salva il file e mette **il percorso** nella chiave). Stringa vuota significa "niente da
buttare stasera", e il provider nasconde l'`ImageView`.

☠ Il glifo si disegna **bianco su trasparente**. È il provider Kotlin a tingerlo con
`setColorFilter`, con lo stesso colore che calcola per il testo dell'intestazione. Se lo
colorasse Dart, la scelta fra testo chiaro e testo scuro starebbe in due posti e prima o poi
divergerebbero, dando un'icona nera su fondo nero senza nessun errore.

☠ `renderIcon` legge `codePoint` da un `IconData` **costante**. Non si costruisca mai un
`IconData` da un codepoint calcolato: il tree shaking delle icone analizza le istanze
costanti, e con una dinamica Flutter o rimuove tutti i glifi, lasciando quadrati vuoti in
release, o imbarca il font intero.

☠ `ui.TextDirection.ltr` e non `TextDirection.ltr`: `package:intl`, importato nello stesso
file, esporta una classe omonima con costanti diverse, e senza prefisso vince quella.

### `class TrashcanWidgetProvider : HomeWidgetProvider()` (Kotlin)

File: `android/app/src/main/kotlin/com/smp/trashcan/TrashcanWidgetProvider.kt`.

| Metodo | Firma | Effetto |
|---|---|---|
| `onReceive` | `override fun onReceive(context: Context, intent: Intent)` | `super` per primo; per `TIME_SET`, `TIMEZONE_CHANGED`, `MY_PACKAGE_REPLACED` (`AZIONI_OROLOGIO`) ricalcola gli istanti e ridisegna. Tutto in un `try` |
| `onEnabled` | `override fun onEnabled(context: Context)` | `super` (il plugin riarma dagli istanti salvati), poi `riarmaMezzanotti` |
| `onUpdate` | `override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences)` | ridisegna ogni istanza con la riga di oggi; tutto in un `try` |
| `ridisegnaTutti` | `private fun ridisegnaTutti(context: Context)` | trova le istanze e chiama `onUpdate` con `HomeWidgetPlugin.getData` |
| `riarmaMezzanotti` | `private fun riarmaMezzanotti(context: Context)` | la regola di `istantiDiRisveglio` nel fuso di adesso, consegnata a `HomeWidgetScheduler.schedule` |
| `preavvisoArmatoAlle` | `private fun preavvisoArmatoAlle(adesso: Long, fineFinestra: Long): Long?` | come l'omonimo Dart, in millisecondi |
| `update` | `private fun update(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences)` | costruisce le `RemoteViews` |
| `statoDiOggi` | `private fun statoDiOggi(widgetData: SharedPreferences): Stato` | cerca `"\n" + LocalDate.now() + FIELD` nelle righe |

Costanti del `companion object`: `TAG`, `SECONDI_DOPO_MEZZANOTTE = 5L`,
`SECONDI_FINE_FINESTRA = 30L`, `FINESTRA_MASSIMA_MS = 3_600_000L`, `QUOTA_FINESTRA = 0.75`,
`GIORNI_DI_RISVEGLI = 3650`, `AZIONI_OROLOGIO`, le chiavi (`KEY_*`, `ICON_PREFIX`), i
separatori `FIELD`/`LINE`, `NEUTRAL`, e le funzioni `fun isDark(color: Int): Boolean` e
`fun translucent(color: Int): Int`. Le prime cinque numeriche devono restare uguali alle
costanti Dart omonime.

### `class TrashcanBackupSource implements BackupSource`

`const TrashcanBackupSource(AppDatabase db, {int? onlyCalendarId})`

| Membro | Firma |
|---|---|
| `schemaId` | `String get schemaId => 'trashcan'` |
| `schemaVersion` | `int get schemaVersion => 1` |
| `exportPayload` | `Future<Map<String, Object?>> exportPayload()` |
| `importPayload` | `Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode})` |
| `imagePaths` | `Future<List<String>> imagePaths()` → sempre vuoto |
| `counts` | `Future<Map<String, int>> counts()` → chiavi `calendars`, `wasteTypes`, `rules` |

Il payload è **annidato** (calendari → tipi → regole ed eccezioni) e non una copia delle
tabelle: gli id di riga non significano niente fuori da questo dispositivo, e un formato
piatto legato da id costringerebbe l'import a rimapparli. Un solo errore di rimappatura
attacca una regola al tipo di rifiuto sbagliato, e il sintomo non è un errore ma un
calendario che dice bugie.

L'import gira in **una sola transazione**: `replaceAll` cancella prima di scrivere, e
un'interruzione fuori transazione cancellerebbe i dati senza rimpiazzarli.

---

## 9. Catalogo dei test

127 test in `apps/trashcan/`, oltre ai 109 di `micro_core`.

| File | N. | Cosa dimostra |
|---|---|---|
| `test/domain/occurrence_engine_test.dart` | 40 | le cinque ricorrenze su casi reali (cambio mese, anno bisestile, ultimo venerdì), le tre eccezioni, la precedenza fra regola ed eccezione, la bitmask |
| `test/data/database_test.dart` | 19 | foreign key attive e cascata, mapper riga→dominio delle 5 forme, righe storte scartate senza far cadere il resto, conteggi e stream |
| `test/data/recurrence_roundtrip_test.dart` | 7 | andata e ritorno dominio↔tabella per tutte e 5 le forme; l'ancora e il `-1 = ultimo` sopravvivono; `setRule` sostituisce invece di affiancare |
| `test/data/watch_bundle_test.dart` | 5 | lo stream del calendario riemette su **tutte** le tabelle: tipo aggiunto, regola cambiata, eccezione aggiunta, lista riordinata, calendario rinominato |
| `test/data/orphan_exceptions_test.dart` | 3 | le eccezioni di un tipo **senza regola** arrivano fino al motore; la ricorrenza sintetica non genera date di suo; nessun duplicato per i tipi che una regola ce l'hanno |
| `test/services/trashcan_scheduler_test.dart` | 16 | **nel piano gratuito non si pianifica niente**; la sera prima, all'orario giusto; una notifica per giorno con tutti i tipi; tipo silenziato e calendario disattivato esclusi; raccolta saltata senza promemoria; niente nel passato; secondo orario solo col Pro; troncatura a 64 e ordine; titolo col nome del calendario solo se ce n'è più d'uno; id stabili; payload; `parseTime` che non lancia |
| `test/services/trashcan_backup_source_test.dart` | 9 | giro completo su un database vuoto; `replaceAll` cancella; `mergeKeepExisting` non duplica; export di un solo calendario; conteggi veri; quattro casi di file storto |
| `test/widget/home_page_test.dart` | 6 | la home nei tre stati (niente / uno / tre tipi), lo stato vuoto, la prossima raccolta con la sera giusta, il nome del calendario nel titolo |
| `test/widget/paywall_config_test.dart` | 6 | **ogni funzione bloccata è venduta**; i calendari stanno per primi; nessun duplicato; nessun testo vuoto; il bottone regge un prezzo assente |
| `test/services/trashcan_widget_icon_test.dart` | 5 | tutte e ventidue le icone si disegnano e non escono vuote; il glifo non riempie il riquadro (sarebbe il "tofu" del font mancante); esce bianco, perche' a tingerlo e' il provider; una chiave sconosciuta ripiega su un'icona vera; ogni preset del wizard punta a una chiave che esiste |
| `test/services/trashcan_widget_giorni_test.dart` | 13 | il contratto del formato che Kotlin rilegge: i separatori sono caratteri di controllo, sono tre e diversi fra loro; l'orizzonte e' un decennio e copre i giorni elencati; il prefisso delle icone non collide con nessuna chiave fissa. **Gruppo «istanti di risveglio»** (2026-10-10): due istanti per giorno (preavviso 23:00:30, finale 00:00:05) per tutto l'orizzonte, in ordine e senza doppioni; il finale non e' mai piu' alle 00:05; un preavviso armato un giorno prima, con la finestra calcolata come `AlarmManagerService.maxTriggerTime`, viene consegnato 30 s dopo mezzanotte; il primo preavviso, armato alle 8, alle 21:40:30, alle 22:30, alle 23:50 o alle 23:58:30, viene consegnato sempre fra 29 e 31 s dopo mezzanotte; sotto un minuto il preavviso sparisce; 800 giorni di finali consecutivi senza buchi; il 25 ottobre 2026 dura 25 ore a Roma e la mezzanotte del 26 resta a mezzanotte |
| `test/widget/palette_contrast_test.dart` | 6 | ogni colore della tavolozza **e ogni preset** regge 4.5:1 col testo che ci va sopra; i preset usano colori della tavolozza; nessun duplicato |

`test/widget/harness.dart` non contiene test: è l'impalcatura che monta una pagina
sostituendo i provider che legge.

`integration_test/acquisto_store_test.dart` apre il paywall **con lo store vero**
(`--dart-define=BILLING=store`) dal riquadro Pro delle impostazioni, e verifica che entro il
tempo massimo la rotellina sparisca: prezzo, messaggio con "Riprova", o "store assente".
☠ E' l'unico test che vede il difetto del 2026-10-06 (rotellina eterna su iPhone): il
gateway finto risponde sempre col prodotto. Esiti verificati: iOS "messaggio con Riprova",
emulatore Android "store assente".

`integration_test/screenshots_test.dart` **non verifica niente**: percorre l'app con dati
realistici e scrive `SCATTO:<nome>` a ogni schermata da fotografare per gli store. Lo scatto
lo fa il computer che guida il dispositivo (`tool/screenshots_ios.sh` sul Mac,
`tool/screenshots_android.ps1` sul PC), perche' `takeScreenshot` fotografa solo Flutter e
lascerebbe fuori la barra di stato. La lingua la sceglie il test con `localesTestValue` e ogni
testo cercato viene da `lookupL`, quindi gira in italiano e in inglese senza toccare il
dispositivo. Azzera database, preferenze **e** `entitlement.json`: senza l'ultimo, il secondo
giro trova il Pro gia' comprato e aspetta per sempre un pulsante che non c'e'. Su Android chiede
anche al launcher di aggiungere il widget (`FISSA:widget`), e lo script conferma la finestra di
sistema. E' anche un test di fatto: ha trovato il rifiuto di iOS sulle notifiche senza permesso
e l'avviso di `MicroCard`, che nessun test a tavolino poteva vedere.

`integration_test/first_run_test.dart` percorre wizard → home → dati scritti, sul
dispositivo: `flutter test integration_test/first_run_test.dart -d <device>`.

☠ **Il dispositivo deve essere in inglese.** Il test tocca i controlli cercandoli per
testo visibile (`find.text('Set up my calendar')`), e l'app segue la lingua di sistema:
su un dispositivo italiano quel testo non esiste e il test **non fallisce, si pianta**,
restando in `pumpAndSettle` finché non scade il timeout. Costa un quarto d'ora prima che
qualcuno sospetti qualcosa, perché l'output non dice niente e lo schermo mostra un'app
perfettamente funzionante. Sul simulatore iOS:

```
xcrun simctl spawn <UDID> defaults write .GlobalPreferences AppleLanguages -array en-US
xcrun simctl spawn <UDID> defaults write .GlobalPreferences AppleLocale -string en_US
xcrun simctl shutdown <UDID> && xcrun simctl boot <UDID>
```

⚑ È **debito**, non una regola: un test che dipende dalla lingua della macchina su cui
gira è un test fragile. La forma giusta è cercare per chiave di traduzione o per
`Semantics`. Finché resta così, la riga qui sopra è obbligatoria.

### Come si eseguono

```
pwsh tool/fl.ps1 test                 # dalla cartella dell'app
pwsh tool/test_all.ps1                # tutto il monorepo
```

---

## 9ter. Le schede degli store

Tutto in `apps/trashcan/store/`: `scheda-play.md` e `scheda-app-store.md` con i testi pronti da
incollare, ognuno col conteggio dei caratteri contro il limite del suo campo, e
`screenshots/{android,ios}/{it,en}/01..06-*.png`.

| Piattaforma | Misura | Perche' |
|---|---|---|
| Android | 1080×1920 | Play rifiuta immagini con il lato lungo oltre il doppio del corto: quelle di settembre erano 1080×2400 |
| iOS | 1320×2868 | la misura da 6,9" e' l'unica obbligatoria; niente iPad, l'app e' solo iPhone |

☠ **Le schede dicono solo cose vere.** Quella di settembre prometteva il promemoria come se fosse
gratis e metteva il backup fra le funzioni gratuite: per gli store e' rappresentazione
ingannevole. Prima di toccare i testi si rilegge `lib/app/feature_limits.dart`.

⚑ Il widget negli screenshot e' **composto**: su iOS con `tool/anteprima_widget_ios.swift
--vetrina`, su Android ritagliando il widget vero dalla schermata Home fotografata dallo script.
In tutti e due i casi il widget e' quello vero; e' finta solo la cornice con la didascalia.

⚑ Su iOS l'app **non raccoglie dati**: non parla con nessun server, quindi l'etichetta privacy
e' "Dati non raccolti" e i manifesti `PrivacyInfo.xcprivacy` (app ed estensione) dichiarano
solo l'uso delle preferenze. Su Android si', per la verifica dell'acquisto: le due schede
privacy sono diverse di proposito.

## 9bis. Come si costruisce il pacchetto da caricare

```
pwsh tool/build_release.ps1 -App trashcan
```

Fa quattro cose in un comando, nell'ordine giusto: alza il `versionCode`, recupera dal
server il segreto HMAC dell'app, compila il bundle di release passando l'indirizzo del
License Server e il segreto, copia il risultato in `apps/trashcan/store/` e **verifica che
sia firmato**. Il pacchetto finisce in `store/trashcan-<versione>-<codice>.aab`.

Con `-NoBump` non tocca il `versionCode`: serve solo a ricostruire lo stesso numero dopo
aver corretto qualcosa in un pacchetto **non ancora caricato**.

☠ **Il `versionCode` non si riusa mai.** Play rifiuta un numero già visto e quel numero non
si libera più, nemmeno cancellando la versione. Per questo lo script lo alza da solo: chi lo
fa a mano prima o poi ricostruisce sullo stesso numero e se ne accorge davanti al
caricamento rifiutato.

☠ **Si usa `--dart-define-from-file`, non `--dart-define`.** `tool/fl.ps1` chiama un file
batch di Windows, che spezza gli argomenti **sui due punti**: `MA_LICENSE_URL=https://...`
arriva a Flutter tagliato in due e il build muore con `Target file //lic.smpmicroapps.it not
found`. Anche il percorso del file dei define va **relativo**, perché `C:\...` contiene a
sua volta due punti.

☠ **Il file dei define contiene il segreto e viene cancellato sempre**, anche quando la
compilazione fallisce (è in un `finally`). È anche in `.gitignore`, ma la cancellazione non
dipende da quello.

⚑ Senza `MA_LICENSE_URL` e `MA_APP_SECRET` l'app si compila lo stesso e funziona, ma
`serverEnabled` è falso: niente verifica dell'acquisto lato server e niente codice di
trasferimento. È un guasto silenzioso, ed è il motivo per cui la compilazione passa da uno
script invece che da un comando ricordato a memoria.

⚑ Il bundle pesa 68 MB perché contiene tre architetture più i simboli di debug, che Play usa
per i rapporti di crash e non scarica sui telefoni. Il download reale per l'utente è intorno
ai 12 MB. **Il file non è versionato**: sessantotto megabyte per pacchetto nella storia di
git non si tolgono più.

---

## 10. Trappole già disinnescate

Ognuna è costata tempo almeno una volta. Sono elencate perché il sintomo non nomina mai la
causa.

| Sintomo | Causa | Dove |
|---|---|---|
| "Activity class does not exist" con la classe presente nel dex | l'emulatore era in `RUNNING_LOCKED`: con lo storage utente bloccato il package manager nasconde i componenti non direct-boot-aware | ambiente, non codice: serve un cold boot |
| `fl.ps1 build apk --debug` costruisce una **release** | con `-File`, PowerShell lega ogni token che inizia per trattino a un nome di parametro: `--debug` finiva in un `param()` inesistente | `tool/fl.ps1`: niente `param()`, si usa `$args` |
| Modifico una regola e lo schermo non cambia fino al riavvio | `watchBundle` osservava solo `collection_calendars`; drift invalida uno stream in base alle tabelle **della query osservata**, non a quelle lette nella callback | `database.dart`: `watchBundle` osserva tutte e quattro |
| Aggiungo una raccolta straordinaria e sparisce | `_rulesFor` costruiva la lista dalle sole righe di `recurrence_rules`: un tipo senza regola non compariva, e con lui le sue eccezioni | `database.dart`: ricorrenza sintetica vuota |
| Il bottone "Sblocca Pro" gira all'infinito | `EntitlementService.dispose()` chiudeva il gateway ricevuto per iniezione; il servizio si ricrea a ogni avvio (appena arriva l'id di installazione) e il secondo ne riceveva uno già chiuso | `micro_core`: un servizio non chiude ciò che non ha costruito |
| La notifica non arriva mai, nessun errore | mancavano `ScheduledNotificationReceiver` e `ScheduledNotificationBootReceiver` nel manifest | `AndroidManifest.xml` |
| Dopo un riavvio del telefono i promemoria smettono | gli allarmi non sopravvivono al riavvio senza `RECEIVE_BOOT_COMPLETED` e il boot receiver | `AndroidManifest.xml` |
| Configuro l'app e dopo due mesi non arriva più niente | niente ripianificava all'avvio: il piano si ricostruiva solo al cambio dei dati | `notificationSyncProvider` |
| Tocco la notifica e il back esce dall'app | `go` sostituisce lo stack: la pagina del giorno restava senza nulla sotto | `app.dart`, `_openPayload` fa `go(home)` poi `push` |
| "È sbagliato il widget": la metà inferiore mostra una riga sola e sembra non aver caricato | era il gate `advancedWidget`, `pro ? 3 : 1`. Il difetto non è tecnico ma di lettura: uno spazio bianco con una riga dentro non comunica "a pagamento". L'ha segnalato il proprietario, non un utente, il che vuol dire che un utente l'avrebbe scritto in una recensione | `advancedWidget` è passato a `open()` e `TrashcanWidget.giorniElencati` vale 3 per tutti |
| I promemoria non arrivano, e l'app non chiede mai il permesso di notificare | in `NotificationsPage` l'avviso che porta a chiedere il permesso compariva `if (_permissionGranted == false)`, ma quel campo partiva a `null` e lo scriveva **solo** la funzione che il banner avrebbe dovuto lanciare. `_refreshPermissions` aggiornava l'altro permesso e non questo. Cerchio chiuso: nessuno leggeva lo stato, quindi l'avviso non appariva, quindi il permesso non si chiedeva. Valeva su **tutte e due** le piattaforme; su Android non si vedeva perche' chi provava l'app il permesso ce l'aveva gia'. Trovato dal proprietario su un iPad, il 2026-10-04 | `NotificationService.hasPermission()` legge lo stato senza chiederlo, `_refreshPermissions` lo scrive, e il permesso si chiede quando si accendono i promemoria |
| Il widget resta fermo al giorno prima, e si aggiorna solo aprendo l'app | due difetti insieme. `HomeWidgetScheduledUpdateReceiver` non era dichiarato nel manifest, quindi l'allarme delle 00:05 scattava e non arrivava a nessuno; e anche arrivando, il ridisegno rileggeva le stesse stringhe, perche' a calcolarle e' Dart, che gira solo con l'app aperta | receiver dichiarato nel manifest, e Dart precalcola 3650 giorni fra cui il provider sceglie la riga di oggi (vedi la sezione qui sopra) |
| Il widget cambia giorno verso l'una di notte, o solo aprendo l'app (2026-10-10) | l'allarme era alle 00:05 e **inesatto**: Android 14+ non concede piu' `SCHEDULE_EXACT_ALARM` di default, la finestra di un inesatto e' il 75% del preavviso fino a un'ora, e Android 14+ consegna **alla fine** della finestra. Armato un giorno prima: consegna verso l'01:00 | `TrashcanWidget.istantiDiRisveglio`: un preavviso alle 23:00:30, la cui finestra finisce alle 00:00:30, piu' il finale alle 00:00:05; `updatePeriodMillis` a 30 min come rete. Vedi «Come il widget cambia giorno a mezzanotte» |
| Dopo un cambio di fuso il widget cambia giorno all'ora sbagliata | gli istanti consegnati al plugin sono assoluti: misurato, GMT → Europe/Rome sposta le 00:05 alle 02:05 | `TrashcanWidgetProvider.onReceive` su `TIME_SET`/`TIMEZONE_CHANGED` ricalcola con `riarmaMezzanotti` |
| Si dichiara `DATE_CHANGED` nel manifest e non arriva mai | non e' esente dai limiti delle trasmissioni implicite di Android 8: «Background execution not allowed» | non si usa; vedi il commento nel manifest |
| L'elenco delle sveglie era piu' corto dell'orizzonte | sette sveglie contro i giorni che il widget sapeva gia' raccontare: dall'ottavo giorno senza aprire l'app il risveglio smetteva di arrivare pur avendo i dati pronti sotto. E' lo stesso difetto, spostato in avanti | `scheduleDailyRefresh` copre esattamente `giorniPrecalcolati` giorni (due istanti per giorno) |
| Cinque test dello scheduler falliscono tutti insieme, senza che il codice sia cambiato | `setWeeklyRule` fa partire la regola da `CivilDate.today()`, cioe' dall'orologio vero: i test usavano una data fissa e passavano finche' la macchina stava prima di quella data. Dal giorno dopo, tutte le attese spostate avanti di una settimana esatta | il fixture passa `startDate: inizioRegole`, una data esplicita |
| Il widget e' squadrato sopra e tondo sotto | `setBackgroundColor` su una view sostituisce il drawable, e con lui gli angoli arrotondati. Il colore si applica tingendo con `setColorFilter` un `ImageView` di sfondo | `TrashcanWidgetProvider.kt` + `widget_header_background.xml` |
| Il widget resta un rettangolo colorato e vuoto | il receiver crollava leggendo il colore: vedi la riga seguente | `TrashcanWidgetProvider.kt` |
| "TrashCan continua a bloccarsi", dopo giorni di funzionamento perfetto | il canale fra Dart e Android codifica un intero come **Integer** se sta in 32 bit con segno e come **Long** altrimenti: *il tipo dipende dal valore*. Un ARGB con alpha `0xFF` supera 2³¹ e arriva Long; lo zero che si manda quando stasera non si raccoglie niente arriva Integer. `getInt` e `getLong` sbagliano **a turno**. E un receiver che lancia fa cadere l'intero processo dell'app, non solo il widget | `TrashcanWidgetProvider.kt`: si legge da `widgetData.all[...]` accettando entrambi i tipi, e tutto `onUpdate` sta dentro un `try` |
| L'icona nella barra di stato è una macchia bianca | Android usa solo il canale alfa dell'icona: `@mipmap/ic_launcher` è opaca ovunque | `drawable/ic_notification.xml` |
| La splash taglia il logo: manico del cestino e simbolo del riciclo mangiati | da Android 12 la splash è un'API di sistema che disegna l'immagine in 240dp e la ritaglia con un cerchio di 160dp: resta visibile solo il 66% centrale | `flutter_native_splash.yaml`, la sezione `android_12:` usa `trashcan_splash_android12.png`, il logo rientrato su tela 1152x1152 (§2bis) |
| `ic_launcher_background` definito due volte, la build si ferma | `flutter_launcher_icons` crea `values/colors.xml` con quel colore, che stava già a mano in `values/strings.xml` | tolto da `strings.xml`: il generatore ha la precedenza |
| Lo spinner "Sblocca Pro" continua a girare su un acquisto in attesa | il ramo `PurchasePending` spegneva `isBusy` **dopo** aver scritto l'entitlement, al contrario di ogni altro ramo: con una scrittura lenta o che lancia, il bottone non si ferma più, e un pagamento in attesa di approvazione può durare giorni | `micro_core`, `entitlement_service.dart`: `_setBusy(false)` prima di `_apply` |
| Il testo sul blocco "Stasera" si legge male | `ThemeData.estimateBrightnessForColor` confronta `(luminanza + 0.05)²` con 0.15, cioè passa al bianco sopra 0.337, non 0.5: sui colori di mezzo sceglie il bianco dove ci si aspetta il nero | tavolozza corretta + `palette_contrast_test.dart` |
| Un widget test resta appeso dieci minuti e muore | `testWidgets` gira in `FakeAsync`, che non fa avanzare l'I/O vero di SQLite; e `pumpAndSettle` non termina perché drift pianifica lavoro di continuo | `test/widget/harness.dart`: si sostituiscono i provider, niente database |
| Build che si ferma su "Could not close incremental caches" | la compilazione incrementale di Kotlin non regge il locking di Windows | `android/gradle.properties`, `kotlin.incremental=false` |
| Il PC resta senza RAM | il template Flutter chiede `-Xmx8G` e 4 GB di metaspace per i demoni di build | `android/gradle.properties`: 2 GB + 1 GB |
| `RadioListTile` deprecato | `groupValue`/`onChanged` sui singoli tile sono deprecati da Flutter 3.32 | `settings_page.dart`, si usa `RadioGroup` |
| `ReorderableListView` sposta una posizione più in là | `onReorder` consegna un `newIndex` già incrementato | `waste_types_page.dart`, si usa `onReorderItem` |

### Regole non negoziabili

1. **`icon_key` è una chiave, mai un codepoint.**
2. **Le date civili sono `CivilDate`**, mai `DateTime`: un `DateTime` porta con sé un fuso, e
   una raccolta "del 12 settembre" non ha un fuso.
3. **Tutte le scritture passano dal repository.** Quasi ognuna tocca più tabelle e deve
   restare coerente.
4. **Nessuna pagina scrive `if (isPro)`**: si passa da `FeatureGate` (ADR-017).
5. **Ogni colore nuovo nella tavolozza va verificato** dal test del contrasto.
6. **`android/key.properties` non si committa**, e il keystore non entra mai nel repository.
7. **`applicationId` e `proSku` sono immutabili** dopo il primo upload su Play.
8. **La regola dei risvegli del widget vive in due posti**, `TrashcanWidget.istantiDiRisveglio`
   (Dart, testata) e `TrashcanWidgetProvider.riarmaMezzanotti` (Kotlin, per i cambi di fuso):
   costanti e formula vanno cambiate insieme.

---

## 10bis. Cosa e' a pagamento

Deciso dal proprietario l'11 settembre 2026. La mappa vive in
`lib/app/feature_limits.dart` ed e' l'unico posto in cui cambiarlo.

| Funzione | Chiave | Piano gratuito |
|---|---|---|
| Secondo calendario e oltre | `unlimitedEntities` | uno solo |
| **I promemoria, tutti** | `notifications` | nessuno |
| Secondo orario di promemoria | `multipleNotifications` | no |
| Backup completo | `backupRestore` | no (la condivisione di un calendario resta gratuita) |
| Colore dell'app | `themeCustomization` | verde fisso |

⛑ **Il compromesso dei promemoria**, scritto qui perche' e' la scelta commerciale piu'
pesante: TrashCan gratuito diventa un calendario che bisogna ricordarsi di aprire, cioe' non
risolve piu' il problema per cui la si installa. Se le installazioni o le recensioni ne
risentono, si torna indietro cambiando una riga in `FeatureLimit.open()`. Il controllo sta
sia nella pagina sia **nel pianificatore**: una notifica gia' consegnata ad Android
sopravvive alla perdita del diritto, e senza il secondo controllo un rimborso lascerebbe
arrivare promemoria per sessanta giorni.

---

## 11. Cosa NON esiste ancora

Per non farlo cercare invano.

- **Nessuna sincronizzazione col License Server in esercizio.** Il client c'è in
  `micro_core`, ma `serverEnabled` è falso finché non c'è un dominio.
- **Nessuna esportazione in CSV.** `FeatureKey.csvExport` è dichiarata `open()` proprio per
  dire che non è una funzione di quest'app.
- **Nessun golden test.** Scelta deliberata: vedi §12.
- **Nessuna prova del ricaricamento a mezzanotte del widget iOS** (`.after`, 2026-10-10):
  scritto da Windows, da compilare e provare sul Mac.
- **Nessun prodotto in App Store Connect.** Il Pro su iOS non è comprabile finché non c'è.
- **Nessuna prova su un iPhone vero.** Finora solo simulatore: notifiche e acquisti sono
  proprio le due cose che un simulatore non dimostra.
- **Nessuna vista mensile a calendario.** Le eccezioni si creano dalla home e dalla pagina
  del giorno.
- **Nessun terzo orario di promemoria.** La tabella ne prevede due.
- **Nessun selettore di colore libero.** Dieci semi misurati, non una ruota: un seme troppo
  chiaro renderebbe illeggibile l'intera app e l'utente non avrebbe modo di accorgersene
  prima. Vedi `AppSeeds`.
- **Il codice di trasferimento non funziona finche' il server non e' in esercizio.** La
  pagina lo dice invece di offrire un bottone che fallisce.
- **Nessuna app su Play Console.** Vedi §12.
- **Nessun test di migrazione dello schema** (F3.2.6): con `schemaVersion = 1` non c'è ancora
  niente da migrare, ma il test va scritto **prima** della versione 2.

---

## 12. Debito tecnico aperto

| Voce | Perché è rimandato | Quando va affrontato |
|---|---|---|
| **F3.12, Play Console** | richiede l'account Google Play del proprietario, un AAB pubblicato su un canale e alcune ore di attesa prima che il prodotto in-app diventi acquistabile. Nessuno di questi passi è eseguibile da qui | prima di qualunque pubblicazione; è il collo di bottiglia della fase F8 |
| **Golden test della home** | un golden fallisce per il rasterizzatore, la versione del font o il sistema operativo, cioè per motivi che non sono difetti dell'app. I 6 widget test della home già verificano il contenuto nei tre stati | se e quando ci sarà una CI con una sola piattaforma fissa |
| **Test di migrazione dello schema** | `schemaVersion = 1`: non c'è nulla da migrare | insieme alla prima modifica delle tabelle, non dopo |
| **`pub cache` condivisa col sistema** | `package_config.json` risolve i pacchetti dalla cache utente invece che da `.flutter/.pub-cache`. Non è pericoloso (i pacchetti sono versionati per risoluzione, l'SDK no) ma tradisce l'isolamento dichiarato in ADR-002 | quando si tocca la toolchain |
| **Testo ingrandito al 200%** | verificato a occhio, non misurato. Il blocco "Stasera" usa `displaySmall` e può traboccare | in F7 (hardening), con un widget test a scala del testo alta |
| **`Semantics` sulle card** | le pagine sono navigabili con TalkBack perché usano widget standard, ma il blocco "Stasera" non ha un'etichetta unica che lo legga come una frase | in F7 |
| **Limite Pro aggirabile via import** | importare un backup con più calendari li crea anche senza Pro. Il backup completo è già dietro al paywall, quindi serve il file di qualcun altro | prima della pubblicazione, se si vuole chiudere il buco |
| **Permesso esatto revocato: allarme del widget perso** | revocando `SCHEDULE_EXACT_ALARM`, Android cancella gli allarmi esatti e non manda nessuna trasmissione (verificato: dopo la revoca `dumpsys alarm` non mostra piu' l'allarme). Si riarma alla prossima apertura dell'app; nel frattempo resta `updatePeriodMillis`. Riarmare in `onUpdate` rovinerebbe la finestra del preavviso, che dipende da **quando** lo si arma | se qualcuno lo segnala |
| **Puntualita' del widget su telefoni con risparmio energetico aggressivo** | verificata solo sull'emulatore (Android 15, Doze forzato). Alcuni produttori ritardano o bloccano gli allarmi delle app in background a prescindere | prova sul telefono vero del proprietario, una notte con l'app chiusa |
| **Il widget non sceglie il calendario** | mostra sempre quello attivo nell'app. Il piano prevedeva la scelta del calendario come funzione Pro | quando qualcuno avrà davvero due calendari e lo chiederà |

---

## 13. Configurazione

| Chiave | Dove | Default | Significato |
|---|---|---|---|
| `BILLING` | `--dart-define` | `play` | `fake` usa `FakePurchaseGateway`; una release compilata con `fake` fallisce all'avvio |
| `MA_LICENSE_URL` | `--dart-define` | vuoto | base URL del License Server; se vuoto, `serverEnabled` è falso |
| `applicationId` | `android/app/build.gradle.kts` | `com.smp.trashcan` | **immutabile** dopo il primo upload |
| `minSdk` | idem | 24 | |
| `proSku` | `lib/app/app_config.dart` | `trashcan_pro_lifetime` | **immutabile**: uno SKU pubblicato non si cancella né si riusa |
| `storeFile`, `storePassword`, `keyAlias`, `keyPassword` | `android/key.properties` | assenti | se il file manca, la release si firma con la chiave di debug e Play la rifiuta: è voluto, perché fallire in fase di upload è meglio che pubblicare firmato male |
| `org.gradle.jvmargs` | `android/gradle.properties` | `-Xmx2G` | tetto ai demoni di build |
| `kotlin.daemon.jvmargs` | idem | `-Xmx1G` | |
| `kotlin.incremental` | idem | `false` | vedi le trappole |

### Comandi

```
pwsh tool/fl.ps1 pub get
pwsh tool/fl.ps1 test
pwsh tool/fl.ps1 analyze lib test
pwsh tool/fl.ps1 run -d emulator-5554 --dart-define=BILLING=fake
pwsh tool/fl.ps1 build appbundle --release
```

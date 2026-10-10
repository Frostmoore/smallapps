# codebase_reference.md — Scorte Calore

> Atlante dell'app **Scorte Calore**: quanti giorni di riscaldamento restano (pellet, legna,
> GPL, gasolio, altra biomassa), entro quando riordinare, con notifiche, calendario e widget.
> **Obiettivo**: capire il codice, trovare cio' che serve e modificarlo **senza aprire i file**.
>
> **Aggiornato al**: 2026-10-08 · **Fase**: F5.0–F5.13 concluse, questo atlante e' F5.14 (resta
> F5.15, il rituale, sul ramo `v7.0.0`) · **Ramo git al momento della scrittura**: `v6.2.0`,
> allineato al commit `3a9712b` · **versionName+Code**: `1.0.0+1`
> **Package Android / bundle iOS**: `com.smp.scortecalore` (immutabile dopo il primo upload)
> **Estensione widget iOS**: `com.smp.scortecalore.ScorteCaloreWidget` · **App Group**: `group.com.smp.scortecalore`
> **SKU Pro**: `scortecalore_pro_lifetime` — **2,99 €** una tantum (Play: base 2,45 EUR senza IVA)
> **Id per il License Server**: `licenseAppId = 'scortecalore'` (senza trattino basso, ≠ `appId`)
> **Grafica**: «A · Brace», scelta dal proprietario il 2026-10-07 (seme `#F4511E`, font Plus Jakarta Sans)
>
> Quello che l'app prende da `micro_core` (configurazione, preferenze, notifiche, acquisti,
> paywall, backup, CSV, date civili) **non e' ricopiato qui**: si rimanda a
> `packages/micro_core/codebase_reference.md`. I nomi dei tipi di `micro_core`, Flutter, Drift,
> dei plugin e delle classi generate da Drift (righe e companion) compaiono qui in testo
> semplice o dentro le firme, mai da soli fra apici inversi: cosi' `tool/verify_atlas.ps1`
> segnala solo i nomi **di quest'app** che non esistono piu'.
>
> Stato: l'app gira su Android (emulatore) e su iOS (simulatore iPhone, con l'estensione
> WidgetKit). **158 test verdi** propri, oltre a quelli di `micro_core`.
>
> Convenzioni dei simboli: ⚑ = scelta non ovvia, con il suo perche'. ☠ = trappola gia' pagata.

---

## 1. Dove sta cosa

| Cerchi… | Vai in… |
|---|---|
| L'avvio dell'app (config, cartelle, log, preferenze, conteggio avvii, dati demo) | `lib/main.dart` |
| Il router, il tema, il ciclo di vita, il tocco sulle notifiche | `lib/app/app.dart` |
| I percorsi di navigazione | `lib/app/routes.dart` |
| Id app, SKU, colore seme, font, `licenseAppId` | `lib/app/app_config.dart` |
| I provider radice: config, database, repository, fonti, misure, stima, fonte in testata, tema | `lib/app/providers.dart` |
| Il Pro: gateway, entitlement, `featureGateProvider`, `appVersion` | `lib/app/entitlement.dart` |
| Cosa e' gratis e cosa e' Pro | `lib/app/feature_limits.dart` |
| I testi e i benefici del paywall, `showScortePaywall` | `lib/app/paywall_config.dart` |
| I colori «A · Brace» (testata blu notte, arancio brace) | `lib/app/scorte_palette.dart` |
| Nomi visibili di combustibili e unita', quantita' con l'unita' ("12 sacchi") | `lib/app/labels.dart` |
| Litri e quantita' formattati, numeri scritti con virgola o punto | `lib/app/formats.dart` |
| Italiano sui telefoni italiani, inglese altrove | `lib/app/locale_resolution.dart` |
| Le tabelle del database | `lib/data/tables.dart` |
| Apertura del database, `PRAGMA foreign_keys`, migrazioni, conversioni riga → dominio | `lib/data/database.dart` |
| **Tutte** le letture e scritture sul database | `lib/data/scorte_repository.dart` |
| I dati di esempio (SC_DEMO) | `lib/dev/demo_data.dart` |
| Combustibili, unita' di misura, unita' ammesse per combustibile | `lib/domain/fuel_units.dart` |
| La fonte e la misurazione come le vedono i calcoli | `lib/domain/fuel_source.dart` |
| Percentuale del manometro ↔ quantita', chili, ricalcolo dal valore digitato | `lib/domain/quantity_converter.dart` |
| **La stima**: consumo medio, autonomia, esaurimento, riordino, qualita' | `lib/domain/consumption.dart` |
| Quando e con quali valori partono le notifiche (puro) | `lib/domain/reorder_plan.dart` |
| Stagioni di riscaldamento, costo medio, spesa stagionale | `lib/domain/costs.dart` |
| La consegna delle notifiche (testi, Pro, canale) | `lib/services/scorte_scheduler.dart` |
| I provider delle notifiche (servizio, scheduler, sincronizzazione, interruttore, permesso) | `lib/services/notification_providers.dart` |
| L'evento di riordino nel calendario del telefono | `lib/services/calendar_sync.dart` (+ provider in `calendar_providers.dart`) |
| Il contenuto del widget di sistema (Dart) | `lib/services/scorte_widget.dart` (+ `widget_sync.dart`) |
| Il disegno del widget Android | `android/app/src/main/kotlin/com/smp/scortecalore/ScorteCaloreWidgetProvider.kt` + `res/layout/scorte_calore_widget.xml` |
| Il disegno del widget iOS | `ios/ScorteCaloreWidget/VistaScorte.swift` (+ timeline in `ScorteCaloreWidget.swift`) |
| Backup e ripristino (formato) | `lib/services/scorte_backup_source.dart` |
| Backup, ripristino e CSV (azioni dalle impostazioni) | `lib/features/settings/data_section.dart` |
| Il CSV | `lib/services/csv_export.dart` |
| La home «A · Brace» | `lib/features/home/home_page.dart` |
| Il foglio "Aggiorna scorta" | `lib/features/stock/update_sheet.dart` |
| Creazione/modifica/eliminazione di una fonte, primo avvio | `lib/features/sources/source_editor_page.dart` |
| La riga del calendario sotto il riquadro del riordino | `lib/features/calendar/calendar_reminder_bar.dart` |
| Storico delle misure, limite dei 90 giorni | `lib/features/history/history_page.dart` |
| I due grafici disegnati a mano | `lib/features/history/charts.dart` |
| Acquisti e costi (Pro) | `lib/features/purchases/purchases_page.dart` (+ `purchase_editor_sheet.dart`) |
| Le impostazioni | `lib/features/settings/settings_page.dart` (+ `notifications_section.dart`, `data_section.dart`) |
| Il lucchetto delle pagine Pro aperte senza Pro (`ProGate`) | `lib/features/common/pro_gate.dart` |
| Permessi, receiver, widget, deep link spento (Android) | `android/app/src/main/AndroidManifest.xml` |
| `onNewIntent` → `setIntent` | `android/app/src/main/kotlin/com/smp/scortecalore/MainActivity.kt` |
| Permessi del calendario, schema URL, deep link spento (iOS) | `ios/Runner/Info.plist` (+ `ios/Runner/{en,it}.lproj/InfoPlist.strings`) |
| Le stringhe tradotte | **`tool/testi.py` + `tool/testi_*.py`** (sorgente unica) → `lib/l10n/app_en.arb`, `app_it.arb` |
| L'icona e la splash | `tool/genera_icone.py` + `flutter_launcher_icons.yaml`, `flutter_native_splash.yaml` (§2bis) |
| L'anteprima del widget iOS sul Mac | `tool/anteprima_widget_ios.swift` (§2ter) |
| Scheda App Store, screenshot, video, prodotto Pro | `store/scheda-app-store.md` (come si rifa' tutto), `tool/scheda_app_store.py` |

---

## 2. Albero dei file

Solo il codice scritto da noi (esclusi `lib/l10n/generated/`, `lib/data/database.g.dart`,
i file generati da Flutter/Xcode/Gradle e le immagini).

```
apps/scorte_calore/
├── lib/
│   ├── main.dart                         avvio: config, cartelle, log, preferenze, avvii, demo. Niente database (tranne la demo).
│   ├── app/
│   │   ├── app.dart                      buildRouter, ScorteCaloreApp: router, tema, resume, tocchi sulle notifiche
│   │   ├── app_config.dart               licenseAppId, buildScorteConfig(): id, nome, SKU, seme #F4511E, font
│   │   ├── entitlement.dart              Pro: appVersion, gateway, EntitlementView/Notifier, isPro, featureGateProvider
│   │   ├── feature_limits.dart           scorteFeatureLimits (ADR-017)
│   │   ├── formats.dart                  formatLiters, formatQuantity, parseUserNumber
│   │   ├── labels.dart                   fuelName, unitName, formatAmount (nomi visibili dagli ARB)
│   │   ├── locale_resolution.dart        kSupportedLocales, resolveAppLocale
│   │   ├── paywall_config.dart           buildScortePaywall, showScortePaywall
│   │   ├── providers.dart                provider radice, ThemeModeNotifier, SelectedSource, stima, fonte in testata
│   │   ├── routes.dart                   Routes: percorsi in costanti
│   │   └── scorte_palette.dart           ScortePalette (ThemeExtension) + withScorteLook
│   ├── data/
│   │   ├── tables.dart                   4 tabelle Drift + fuelTypeKeys/fuelUnitKeys/enteredAsKeys
│   │   ├── database.dart                 AppDatabase (schema 1) + estensioni riga → dominio
│   │   ├── database.g.dart               GENERATO da drift_dev
│   │   └── scorte_repository.dart        ScorteRepository: la sola porta sui dati
│   ├── dev/
│   │   └── demo_data.dart                seedDemoData (solo con --dart-define=SC_DEMO=true, mai in release)
│   ├── domain/                           Dart puro: niente Flutter, niente Drift, niente stringhe dell'app
│   │   ├── consumption.dart              EstimateQuality, ConsumptionInterval, ConsumptionEstimate, ConsumptionCalculator
│   │   ├── costs.dart                    PurchaseEntry, HeatingSeason, PurchaseTotals, seasonTotals, totalsBySeason
│   │   ├── fuel_source.dart              FuelSourceSpec, EnteredAs, Measurement
│   │   ├── fuel_units.dart               FuelType, FuelUnit, FuelUnits
│   │   ├── quantity_converter.dart       QuantityConverter
│   │   └── reorder_plan.dart             ReorderNotificationKind, PlannedNotification, ReorderPlanner
│   ├── services/
│   │   ├── calendar_providers.dart       calendarSyncProvider, remindersProvider
│   │   ├── calendar_sync.dart            CalendarChoice, CalendarGateway, CalendarEventMissing, DeviceCalendarGateway, ReorderEventTexts, CalendarSyncService
│   │   ├── csv_export.dart               exportScorteCsv, buildScorteCsv, csvDecimal
│   │   ├── notification_providers.dart   notificationServiceProvider, scorteSchedulerProvider, notificationSyncProvider, NotificationsEnabled, notificationPermissionProvider
│   │   ├── scorte_backup_source.dart     ScorteBackupSource (BackupSource di micro_core)
│   │   ├── scorte_scheduler.dart         scorteChannelId, scorteChannel, ScorteScheduler
│   │   ├── scorte_widget.dart            ScorteWidget: chiavi, riga, pubblicazione, sveglia 00:05
│   │   └── widget_sync.dart              widgetSyncProvider, widgetRefreshProvider
│   ├── features/
│   │   ├── calendar/calendar_reminder_bar.dart   CalendarReminderBar (3 stati)
│   │   ├── common/pro_gate.dart                  ProGate
│   │   ├── history/charts.dart                   chartLeftGutter, refillDates, niceCeiling, StockChart, RateChart
│   │   ├── history/history_page.dart             historyStart, HistoryPage
│   │   ├── home/home_page.dart                   HomePage, openNewSource
│   │   ├── purchases/purchase_editor_sheet.dart  showPurchaseEditor, parseEuroCents
│   │   ├── purchases/purchases_page.dart         openPurchases, formatEuro, toPurchaseEntries, PurchasesPage
│   │   ├── settings/data_section.dart            backupServiceProvider, DataSection, exportCsv, createBackup, restoreBackup
│   │   ├── settings/notifications_section.dart   NotificationsSection
│   │   ├── settings/settings_page.dart           SettingsPage
│   │   ├── sources/source_editor_page.dart       SourceEditorPage (nuova, primo avvio, modifica, elimina)
│   │   └── stock/update_sheet.dart               showUpdateSheet
│   └── l10n/
│       ├── app_en.arb, app_it.arb        GENERATI da tool/testi.py (template: inglese)
│       └── generated/                    GENERATO da gen-l10n (classe L)
├── test/                                 §12 — 158 test
│   ├── data/scorte_repository_test.dart
│   ├── domain/{consumption,costs,fuel_units,quantity_converter,reorder_plan}_test.dart
│   ├── features/history/{fake_repo.dart,history_page_test.dart,purchases_page_test.dart}
│   ├── services/{backup_csv,calendar_sync,scorte_scheduler,scorte_widget}_test.dart
│   └── widget/paywall_config_test.dart
├── integration_test/                     NON test di regressione: giri per gli store (sul Mac)
│   ├── screenshots_test.dart             stampa SCATTO:<nome>, lo scatto lo fa tool/screenshots_ios.sh
│   └── anteprima_test.dart               il giro del video, fra REGISTRA e FINE (tool/anteprima_app_store.sh)
├── store/                                schede e grafiche degli store
│   ├── scheda-app-store.md               testi it/en contati, cosa va dove (API o a mano)
│   ├── screenshots/ios/<lingua>/         screenshot veri dal simulatore (anche paywall-revisione.png)
│   ├── grafiche/                         appstore (6,9"), appstore-6.5, play, apple (intestazione, ricerca), sorgenti (widget)
│   └── video/anteprima-886x1920-<lingua>.mp4   anteprima App Store (il .mov grezzo e' ignorato da git)
├── tool/
│   ├── testi.py                          sorgente dei testi (TESTI comuni) → ARB
│   ├── testi_{widget,notifiche,storico,dati,calendario}.py   testi per parte dell'app, caricati da testi.py
│   ├── genera_icone.py                   icone e splash dall'originale del proprietario
│   ├── anteprima_widget_ios.swift        renderizza il widget iOS in PNG sul Mac (--vetrina per le grafiche)
│   ├── genera_grafiche_store.py          schede screenshot, testata Play, intestazione e ricerca Apple
│   ├── anteprima_app_store.sh            registra il video sul simulatore (Mac)
│   ├── converti_anteprima.ps1            .mov → mp4 886x1920 30 fps con audio muto (PC, ffmpeg)
│   └── scheda_app_store.py               carica scheda, video e prodotto Pro su App Store Connect (Mac)
├── android/app/src/main/
│   ├── AndroidManifest.xml               permessi, receiver di widget/notifiche, deep link spento
│   ├── kotlin/com/smp/scortecalore/
│   │   ├── MainActivity.kt               onNewIntent → setIntent
│   │   └── ScorteCaloreWidgetProvider.kt il widget Android: i giorni li conta lui
│   └── res/
│       ├── layout/scorte_calore_widget.xml, scorte_calore_widget_preview.xml
│       ├── xml/scorte_calore_widget_info.xml
│       ├── values/widget.xml, values-it/widget.xml   testi di riserva e stili del widget
│       ├── drawable/widget_background.xml            blu notte, raggio 22dp
│       └── drawable/ic_notification.xml              icona monocroma della barra di stato
├── ios/
│   ├── Runner/Info.plist, Runner.entitlements, {en,it}.lproj/InfoPlist.strings, AppDelegate.swift
│   └── ScorteCaloreWidget/
│       ├── ScorteCaloreWidget.swift      @main, Fornitore (timeline di 8 voci), VistaConFamiglia
│       ├── VistaScorte.swift             Chiavi, Ripiego, RigaFonte, VoceScorte, Deposito, colori, VistaScorte
│       ├── Info.plist                    NSExtension widgetkit
│       └── ScorteCaloreWidget.entitlements   App Group
├── flutter_launcher_icons.yaml, flutter_native_splash.yaml, l10n.yaml, pubspec.yaml, analysis_options.yaml
└── README.md
```

---

## 2bis. Icona e schermata di avvio

Sorgente: `assets/icons/source/scortecalore_originale.png` (1254x1254, RGB), l'icona del
proprietario: quadrato arrotondato blu notte con fiamma, pellet, manometro e calendario, con
**angoli neri** fuori dall'arrotondamento.

`python apps/scorte_calore/tool/genera_icone.py` produce in `assets/icons/`:

| File | Uso |
|---|---|
| `scortecalore_fullbleed.png` | quadrato pieno senza angoli neri: icona iOS, icona Play 512, legacy Android |
| `scortecalore_logo.png` | il quadrato con gli angoli trasparenti: sito, schede |
| `adaptive_background.png` | Android 8+: l'icona stessa alla scala del primo piano, bordi allungati |
| `adaptive_foreground.png` | Android 8+: solo il disegno, nella zona sicura |
| `adaptive_monochrome.png` | Android 13+: sagoma piatta per le icone a tema |
| `splash_logo.png` | splash (Android fino a 11 e iOS) |
| `splash_android12.png` | splash di Android 12+, nei due terzi centrali |

Poi `pwsh ../../tool/fl.ps1 pub run flutter_launcher_icons` e
`pwsh ../../tool/fl.ps1 pub run flutter_native_splash:create`.

Funzioni dello script (Python, non toccano il codice dell'app): `carica`, `maschera_quadrato`,
`blu_notte`, `fullbleed`, `sfondo_adattivo`, `alfa_disegno`, `raggio_disegno`, `su_tela`,
`main`.

⚑ **Il disegno si separa con la luminosita' massima dei canali**, non col solo rosso come in
Full Freezer: lo sfondo e' blu notte (canale piu' alto sotto 90), fiamma e calendario sono
chiari o saturi. Il quadrante scuro del manometro diventa trasparente, ma sotto il primo piano
c'e' l'icona stessa alla stessa scala, quindi non si vede.
⚑ **Il disegno arriva quasi ai bordi**: nella zona sicura Android va rimpicciolito di piu'.
⚑ Splash e monocromatica vengono dal ritaglio automatico; se arriva
`source/scortecalore_senza_sfondo.png` lo script lo usa al posto del ritaglio.
⚑ Lo sfondo adattivo e' un'**immagine** (l'icona stessa), non un colore: dove il ritaglio
sbaglia sotto c'e' l'originale. `adaptive_icon_foreground_inset: 0`.

| Impostazione | Valore |
|---|---|
| splash `color` / `color_dark` | `#183450` / `#0F1828` (blu notte dell'icona) |
| `background_color_ios` | `#183450` |
| `remove_alpha_ios` | `true` |

☠ **Le immagini generate non si modificano a mano**: si cambia l'originale e si rilancia lo
script. ☠ iOS: niente canale alfa, o App Store Connect rifiuta la build a caricamento finito.
☠ Android 12+ ritaglia la splash a cerchio e tiene solo i due terzi centrali: per questo
`splash_android12.png` e' un'immagine a parte.

---

## 2ter. iOS

L'app e' nata con `flutter create --platforms=android,ios` (F5.0 punto 1): ogni giuntura col
sistema (widget, notifiche, acquisti, calendario) esiste su tutte e due.

| Impostazione | Valore | Dove |
|---|---|---|
| Bundle app | `com.smp.scortecalore` | `project.pbxproj` |
| Bundle estensione | `com.smp.scortecalore.ScorteCaloreWidget` | `project.pbxproj` |
| TARGETED_DEVICE_FAMILY | `1` (solo iPhone; sull'iPad in compatibilita') | tutti i target |
| IPHONEOS_DEPLOYMENT_TARGET | `15.0` (a livello di progetto, ereditato da Runner ed estensione) | `project.pbxproj` |
| DEVELOPMENT_TEAM | A29HGT2MQ4 | |
| App Group | `group.com.smp.scortecalore` | `Runner.entitlements`, `ScorteCaloreWidget.entitlements`, `ScorteWidget.iosGroup`, `Chiavi.gruppo` (Swift) |
| Schema URL | `scortecalore` | `Info.plist` CFBundleURLTypes |
| FlutterDeepLinkingEnabled | `false` | `Info.plist` |
| ITSAppUsesNonExemptEncryption | `false` | `Info.plist` |
| Lingue | `it`, `en` (CFBundleLocalizations) | `Info.plist` |
| NSCalendarsUsageDescription, NSCalendarsFullAccessUsageDescription | testo inglese in `Info.plist`, it/en in `{it,en}.lproj/InfoPlist.strings` | |

⚑ **Niente CocoaPods**: Flutter risolve i plugin con Swift Package Manager. Non c'e' Podfile.

### Come si compila sul Mac

La macchina iOS e' il Mac mini (`ssh mac`); sul Mac la repo vive in `~/microapps` come **copia
non-git** sincronizzata dal PC con `tar` via ssh, e si compila con la toolchain del Mac in
`~/microapps-toolchain/flutter` (stessa procedura di Full Freezer, vedi il suo atlante §2ter).

```
export PATH="$HOME/microapps-toolchain/flutter/bin:/opt/homebrew/bin:$PATH"
cd ~/microapps/apps/scorte_calore
flutter build ios --simulator --debug
xcrun simctl install <UDID> build/ios/iphonesimulator/Runner.app
xcrun simctl launch  <UDID> com.smp.scortecalore
```

☠ Le modifiche fatte sul Mac (per esempio il `project.pbxproj` toccato dagli script Ruby)
**non tornano da sole sul PC**: vanno riportate a mano.

### Gli script Ruby (nel monorepo, `tool/`)

Si lanciano **sul Mac**, dalla radice della copia, con la gemma `xcodeproj` di Homebrew:

```
PATH=/opt/homebrew/bin:$PATH ruby tool/aggiungi_widget_ios.rb apps/scorte_calore ScorteCaloreWidget group.com.smp.scortecalore
PATH=/opt/homebrew/bin:$PATH ruby tool/aggiungi_infoplist_strings.rb apps/scorte_calore
```

| Script | Cosa fa | ☠ |
|---|---|---|
| `tool/aggiungi_widget_ios.rb` | aggiunge al progetto Xcode il target dell'estensione WidgetKit con App Group, entitlements, soglia iOS del Runner; *Embed App Extensions* prima di *Thin Binary* | **idempotente**: un secondo target omonimo produce un pacchetto con due estensioni, che App Store Connect rifiuta a caricamento finito |
| `tool/aggiungi_infoplist_strings.rb` | aggiunge al Runner gli `{it,en}.lproj/InfoPlist.strings` come **gruppo di varianti** (qui: i testi dei permessi del calendario) | file sciolti finirebbero nel pacchetto con lo stesso nome e uno sovrascriverebbe l'altro |

Gia' eseguiti per Scorte Calore (commit `3a9712b`).

### L'anteprima del widget

`apps/scorte_calore/tool/anteprima_widget_ios.swift` compila **la stessa** `VistaScorte.swift`
del widget e la rende in PNG su macOS (comando nell'header del file):

```
swiftc -parse-as-library -O \
  apps/scorte_calore/ios/ScorteCaloreWidget/VistaScorte.swift \
  apps/scorte_calore/tool/anteprima_widget_ios.swift -o /tmp/anteprima_sc \
  && /tmp/anteprima_sc /tmp/anteprima_sc.png [contenitore.plist]
```

Col secondo argomento legge il contenitore vero del simulatore
(`<AppGroup>/Library/Preferences/group.com.smp.scortecalore.plist`) con un Deposito costruito
da un dizionario: verifica in un colpo la catena intera, da Dart che scrive alla vista che
disegna. **Provata il 2026-10-08 con i dati veri del simulatore.**

☠ Esiste perche' un widget non si mette sulla schermata da riga di comando (in TrashCan ne era
arrivato al proprietario uno mai guardato). Per questo `VistaScorte.swift` non contiene niente
che esista solo su iOS.

### Caricamento su TestFlight

`tool/build_ios.sh scorte_calore` sul Mac. **Non ancora eseguito per Scorte Calore** (§14).

---

## 3. Il database

Quattro tabelle, **`schemaVersion = 1`**, file `scorte_calore.sqlite` nella cartella documenti
dell'app. Le date civili sono TEXT `YYYY-MM-DD` (ADR-008), gli istanti sono interi in
millisecondi UTC. Le colonne in SQL sono in snake_case (Drift converte i getter camelCase).

Legenda vincoli: **CHECK** = vincolo SQL vero, scritto nello schema; **len** = `withLength`,
controllato **solo da Drift in Dart** all'inserimento con un companion, non da SQLite.

☠ `PRAGMA foreign_keys = ON` si imposta in `beforeOpen` **a ogni connessione**: SQLite lo tiene
spento di default, e senza i `references(... onDelete: cascade)` sarebbero decorativi
(misure e acquisti orfani nelle statistiche e nel CSV).

⚑ **Le chiavi ammesse nei CHECK vengono dal dominio**, non da una lista copiata: variabili di
modulo in `tables.dart` (esportate anche da `database.dart`):

| Simbolo | Firma | Contenuto |
|---|---|---|
| `fuelTypeKeys` | `final List<String> fuelTypeKeys` | `[for (t in FuelType.values) t.key]` |
| `fuelUnitKeys` | `final List<String> fuelUnitKeys` | `[for (u in FuelUnits.all) u.key]` |
| `enteredAsKeys` | `final List<String> enteredAsKeys` | `[for (e in EnteredAs.values) e.key]` |

☠ Il CHECK entra nello schema **alla creazione** della tabella: aggiungere una chiave al dominio
dopo il rilascio richiede una migrazione che ricrei la tabella (SQLite non modifica i CHECK).

### `fuel_sources` (classe `FuelSources`)

| Colonna | Tipo | Default | Vincoli | Significato |
|---|---|---|---|---|
| `id` | INTEGER | | PK autoincrement | |
| `name` | TEXT | | len 1..60 | "Stufa soggiorno": un dato dell'utente |
| `fuel_type` | TEXT | | **CHECK IN `fuelTypeKeys`** | `pellet` \| `lpg` \| `diesel` \| `wood` \| `biomass` |
| `unit` | TEXT | | **CHECK IN `fuelUnitKeys`** | chiave in `FuelUnits` |
| `unit_weight_kg` | REAL nullable | | **CHECK > 0** | peso di un sacco/cassetta, solo informativo |
| `tank_capacity` | REAL nullable | | **CHECK > 0** (NULL passa) | capacita' **nominale** in litri (GPL, gasolio) |
| `usable_fraction` | REAL | **nessuno** | **CHECK > 0 AND <= 1** | 0,80 per il GPL; il default lo mette il repository |
| `warning_days` | INTEGER | `7` (`FuelType.defaultWarningDays`) | **CHECK >= 0** | anticipo del riordino |
| `cost_per_unit_cents` | INTEGER nullable | | **CHECK >= 0** | costo per unita' in centesimi (impostato dall'editor, non usato nei calcoli) |
| `active` | BOOL | `true` | | disattivata: sparisce da home, notifiche, widget, resta lo storico |
| `sort_order` | INTEGER | `0` | | ordine dell'utente (⚑ non in F5.2, aggiunto come Full Freezer) |
| `created_at` | INTEGER | | obbligatoria | ms UTC |

⚑ **L'unita' ammessa per il combustibile** (niente "litri di pellet") non e' un CHECK: la
controlla `ScorteRepository` con `FuelUnits.isAllowed`. Un CHECK che incrocia due colonne con
una mappa del dominio sarebbe illeggibile e andrebbe migrato a ogni unita' nuova.
⚑ `usable_fraction` senza default SQL: dipende dal combustibile (`FuelType.defaultUsableFraction`).
Zero escluso: una capacita' utile nulla trasformerebbe ogni percentuale in 0.

### `stock_measurements` (classe `StockMeasurements`) — il cuore dell'app

| Colonna | Tipo | Vincoli | Significato |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `fuel_source_id` | INTEGER | FK → `fuel_sources.id` **ON DELETE CASCADE** | |
| `date` | TEXT | len 10..10 | `YYYY-MM-DD`: l'ordine del testo e' quello cronologico |
| `quantity` | REAL | **CHECK >= 0** | nell'unita' della fonte, gia' convertita. Zero ammesso (stufa a secco) |
| `entered_as` | TEXT | **CHECK IN `enteredAsKeys`** | `absolute` \| `percentage` |
| `raw_input` | REAL | **CHECK >= 0 AND (entered_as = 'absolute' OR raw_input <= 100)** | il valore digitato prima della conversione |
| `note` | TEXT nullable | | |

Vincolo: **`UNIQUE(fuel_source_id, date)`** (`uniqueKeys`). Nessun altro indice dichiarato.

☠ **Una misurazione al giorno**: due misure nella stessa data darebbero un intervallo di zero
giorni e una divisione per zero nel calcolatore; la seconda sovrascrive la prima
(`ScorteRepository.upsertMeasurement`, `ON CONFLICT DO UPDATE`).
⚑ **Perche' `entered_as` e `raw_input`** (F5.2): se l'utente cambia capacita' o frazione utile
dopo dieci letture del manometro, le quantita' si ricalcolano dal valore grezzo
(`ScorteRepository.recomputeMeasurements`). Senza, quelle misure sarebbero perse.

### `purchases` (classe `Purchases`)

| Colonna | Tipo | Vincoli | Significato |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `fuel_source_id` | INTEGER | FK → `fuel_sources.id` **ON DELETE CASCADE** | |
| `date` | TEXT | len 10..10 | `YYYY-MM-DD` |
| `quantity` | REAL | **CHECK > 0** | strettamente positiva: un acquisto di zero falserebbe il costo medio |
| `total_cost_cents` | INTEGER nullable | **CHECK >= 0** | ⚑ nullable (legna regalata, scontrino perso); il costo medio conta solo gli acquisti con un costo |
| `supplier` | TEXT nullable | | |
| `note` | TEXT nullable | | |

⚑ **Un acquisto non crea una misurazione**: "ho comprato 70 sacchi" non dice quanti ce ne sono
adesso. La scorta la dice solo una misura.

### `calendar_reminders` (classe `CalendarReminders`, Pro)

| Colonna | Tipo | Vincoli | Significato |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `fuel_source_id` | INTEGER | **UNIQUE**, FK → `fuel_sources.id` **ON DELETE CASCADE** | uno per fonte |
| `calendar_id` | TEXT | len 1..255 | ⚑ non in F5.2: serve per aggiornare o cancellare l'evento |
| `external_event_id` | TEXT | len 1..255 | l'id dell'evento nel calendario del telefono |
| `calculated_date` | TEXT | len 10..10 | la `reorderDate` con cui l'evento e' stato scritto: misura la deriva |
| `created_at` | INTEGER | obbligatoria | ms UTC della prima scrittura |
| `last_synced_at` | INTEGER | obbligatoria | ms UTC dell'ultima scrittura |

☠ **Cancellare la fonte cancella questa riga (cascade), non l'evento nel calendario**, che sta
fuori dal database: prima va chiamato `CalendarSyncService.forgetSource` (§8).

### Righe generate da Drift

Le classi **tabella** scritte a mano in `tables.dart` (estendono Table di Drift) sono
`FuelSources`, `StockMeasurements`, `Purchases`, `CalendarReminders`; il database le dichiara
in `@DriftDatabase(tables: [...])` in quest'ordine.

Classi riga (in `database.g.dart`, non si modificano): FuelSource, StockMeasurement, Purchase,
CalendarReminder, piu' i companion (FuelSourcesCompanion, StockMeasurementsCompanion,
PurchasesCompanion, CalendarRemindersCompanion). I campi sono i getter in camelCase:
`date` e `calculatedDate` sono String, `fuelType`/`unit`/`enteredAs` sono String (le chiavi),
`unitWeightKg`/`tankCapacity` `double?`, `totalCostCents` `int?`, `active` `bool`.

⚑ **La riga Drift non e' il modello del dominio**: le schermate vogliono id, nota, `active`,
`sortOrder`, che il dominio non porta; i calcoli vogliono tipi forti. Si converte nel punto in
cui si calcola, con le estensioni di §5.

### Migrazioni

`onUpgrade` **lancia** UnsupportedError: alla versione 1 non c'e' niente da migrare, e il ramo
resta scritto perche' la prima modifica di schema debba incrementare `schemaVersion` **e**
aggiungere qui il passo con il suo test. Senza, il primo aggiornamento in produzione
cancellerebbe i dati.

---

## 4. `lib/domain/` — il cuore, senza database

Dart puro: niente Flutter, niente Drift, **niente stringhe dell'app** (i nomi visibili stanno
in `lib/app/labels.dart` e negli ARB). Il "oggi" si passa sempre come parametro.

### `fuel_units.dart`

`enum FuelType` — costruttore `const FuelType(this.key, {required this.defaultUnitKey, this.defaultUsableFraction = 1.0, this.usesTank = false})`.

| Valore | `key` (nel DB, **non si rinomina**) | `defaultUnitKey` | `defaultUsableFraction` | `usesTank` |
|---|---|---|---|---|
| `pellet` | `pellet` | `bags` | 1,0 | no |
| `lpg` | `lpg` | `liters` | **0,80** | si' |
| `diesel` | `diesel` | `liters` | 1,0 | si' |
| `wood` | `wood` | `quintals` | 1,0 | no |
| `biomass` | `biomass` | `kg` | 1,0 | no |

| Membro | Firma | Significato |
|---|---|---|
| `key` | `final String key` | valore stabile nel database |
| `defaultUnitKey` | `final String defaultUnitKey` | unita' proposta dall'editor |
| `defaultUsableFraction` | `final double defaultUsableFraction` | default di `usable_fraction` |
| `usesTank` | `final bool usesTank` | solo allora l'editor chiede capacita' e quota utile, e il foglio offre il manometro |
| `defaultWarningDays` | `static const int defaultWarningDays = 7` | default di `warning_days` |
| `byKey` | `static FuelType? byKey(String? key)` | null su chiave sconosciuta |

☠ **GPL a 0,80**: un bombolone non si riempie mai oltre l'80% della capacita' geometrica.
Senza, l'app sovrastima la scorta di un quarto e manda l'utente a secco.

`@immutable class FuelUnit` — `const FuelUnit({required String key, required int decimals, required bool supportsWeight})`;
`==`/`hashCode` per valore, `toString` → `FuelUnit(<key>)`.
`decimals` e' solo presentazione (i calcoli usano il double pieno); `supportsWeight` = ha senso
chiedere "quanto pesa uno?".

`abstract final class FuelUnits`

| Membro | Firma | Significato |
|---|---|---|
| costanti | `static const String bags = 'bags'`, `kg`, `pallets`, `liters`, `percent`, `quintals`, `steres`, `crates` | chiavi stabili, salvate in `fuel_sources.unit` |
| `all` | `static const List<FuelUnit> all` | le otto unita', una volta ciascuna |
| `forType` | `static List<FuelUnit> forType(FuelType type)` | ammesse per il combustibile, la prima e' la predefinita |
| `isAllowed` | `static bool isAllowed(FuelType type, String unitKey)` | il repository lo controlla prima di salvare |
| `defaultFor` | `static FuelUnit defaultFor(FuelType type)` | |
| `byKey` | `static FuelUnit byKey(String key)` | ☠ **lancia ArgumentError** su chiave sconosciuta: "12 litri" per 12 sacchi e' peggio di un errore |
| `tryByKey` | `static FuelUnit? tryByKey(String? key)` | per i dati che arrivano da fuori |

| Unita' | `decimals` | `supportsWeight` |
|---|---|---|
| `bags` | 1 | si' |
| `kg` | 0 | no |
| `pallets` | 2 | si' |
| `liters` | 0 | no |
| `percent` | 0 | no |
| `quintals` | 1 | no |
| `steres` | 1 | **no** (⚑ un metro stero di faggio e uno di abete pesano diversamente) |
| `crates` | 0 | si' |

Unita' per combustibile (privata `_keysByType`, ordine = ordine dell'editor):
pellet `bags, kg, pallets` · lpg `liters, percent` · diesel `liters, percent` ·
wood `quintals, steres, crates, kg` · biomass `kg, quintals, bags`.

⚑ `percent` per GPL e gasolio: chi ha solo il manometro tiene la scorta in percentuale, si
consuma "2% al giorno" e la stima funziona uguale.

### `fuel_source.dart`

`@immutable class FuelSourceSpec` — la fonte come la vedono i calcoli. ⚑ **Non e' la riga
Drift**: restano fuori `active`, `sortOrder`, `createdAt`.

| Membro | Firma | Significato |
|---|---|---|
| costruttore | `const FuelSourceSpec({required int id, required String name, required FuelType fuelType, required String unitKey, double? unitWeightKg, double? tankCapacity, required double usableFraction, int warningDays = FuelType.defaultWarningDays, int? costPerUnitCents})` | |
| `withDefaults` | `factory FuelSourceSpec.withDefaults({required int id, required String name, required FuelType fuelType, double? tankCapacity})` | unita' e frazione utile del combustibile (oggi usata solo nei test) |
| campi | `final int id`, `final String name`, `final FuelType fuelType`, `final String unitKey`, `final double? unitWeightKg`, `final double? tankCapacity`, `final double usableFraction`, `final int warningDays`, `final int? costPerUnitCents` | |
| `unit` | `FuelUnit get unit` | `FuelUnits.byKey(unitKey)` (lancia su chiave ignota) |
| `usableCapacity` | `double? get usableCapacity` | `tankCapacity × usableFraction`; null senza capacita' |
| `copyWith` | `FuelSourceSpec copyWith({String? name, String? unitKey, double? unitWeightKg, double? tankCapacity, double? usableFraction, int? warningDays, int? costPerUnitCents})` | ⚠️ con `??`: **non sa togliere** un valore (null = invariato); `id` e `fuelType` fissi |
| `==`, `hashCode`, `toString` | | per valore; `FuelSourceSpec(id, key, unitKey)` |

`enum EnteredAs` — `absolute('absolute')`, `percentage('percentage')`; `final String key`
(**non si rinomina**); `static EnteredAs? byKey(String? key)`.

`@immutable class Measurement` — una misura senza id e nota.

| Membro | Firma | Significato |
|---|---|---|
| costruttore | `const Measurement({required CivilDate date, required double quantity, required EnteredAs enteredAs, required double rawInput})` | |
| `absolute` | `const Measurement.absolute({required CivilDate date, required double quantity})` | `enteredAs = absolute`, `rawInput = quantity` |
| campi | `final CivilDate date`, `final double quantity` (gia' convertita), `final EnteredAs enteredAs`, `final double rawInput` | |
| `withQuantity` | `Measurement withQuantity(double newQuantity)` | stessa data, enteredAs, rawInput |
| `==`, `hashCode`, `toString` | | per valore |

### `quantity_converter.dart`

`class QuantityConverter` — `const QuantityConverter(FuelSourceSpec source)`; campo `final FuelSourceSpec source`.

| Membro | Firma | Effetto |
|---|---|---|
| `supportsPercentage` | `bool get supportsPercentage` | vero con unita' `percent`, oppure con capacita' utile > 0 |
| `fromPercentage` | `double fromPercentage(double percent)` | `percent / 100 × capacita' utile`; con unita' `percent` e' l'identita'. **Lancia StateError** senza capacita' utile |
| `toPercentage` | `double toPercentage(double quantity)` | l'inverso (non usato fuori dai test) |
| `toKilograms` | `double? toKilograms(double quantity)` | `kg` = se stesso; `quintals` × 100; contenitore con `supportsWeight` e peso > 0 × peso; altrimenti null (non usato in UI) |
| `recompute` | `Measurement recompute(Measurement m)` | `percentage` → `withQuantity(fromPercentage(rawInput))`; `absolute` o senza capacita' → **invariata** |
| `recomputeAll` | `List<Measurement> recomputeAll(Iterable<Measurement> measurements)` | `recompute` su tutte, stesso ordine |

☠ **Capacita' utile, non nominale**: 43% di 1000 L con 0,8 = **344 L**, non 430.
☠ Se la fonte ha perso la capacita', `recompute` lascia la misura com'era: un campo lasciato
vuoto un momento non deve azzerare mesi di dati.
⚑ **Niente densita' di GPL/gasolio, niente peso degli steri**: una conversione approssimata
presentata come esatta produce numeri falsi con un'aria di precisione.
⚑ La `format` del piano non c'e': formattare richiede `intl` e gli ARB, cioe' la UI.

### `consumption.dart` — la stima

`enum EstimateQuality { insufficient, low, good }` — `insufficient`: niente stima (la UI mostra
"Serve un'altra misura", mai "∞ giorni"); `low`: un solo intervallo o meno di 10 giorni di dati.

`@immutable class ConsumptionInterval` — `const ConsumptionInterval({required CivilDate from, required CivilDate to, required double consumed, required int days})`;
`double get rate` = `consumed / days`; `==`, `hashCode`, `toString`. `consumed` mai negativo
(i tratti in salita sono rifornimenti e non diventano intervalli).

`@immutable class ConsumptionEstimate`

| Membro | Firma | Significato |
|---|---|---|
| costruttore | `const ConsumptionEstimate({required double? dailyRate, required double currentQuantity, required int? daysRemaining, required CivilDate? depletionDate, required CivilDate? reorderDate, required EstimateQuality quality, required int intervalsUsed, required int spanDays, required CivilDate? lastMeasurementDate, required double? referenceQuantity})` | |
| `dailyRate` | `final double?` | unita' al giorno; null se `insufficient` |
| `currentQuantity` | `final double` | l'**ultima misura** (0 senza misure): un dato, non una proiezione |
| `daysRemaining` | `final int?` | da oggi a `depletionDate`, **mai negativo** |
| `depletionDate` | `final CivilDate?` | |
| `reorderDate` | `final CivilDate?` | `depletionDate − warningDays`; puo' essere nel passato |
| `quality` | `final EstimateQuality` | |
| `intervalsUsed` | `final int` | ≤ `maxIntervals` |
| `spanDays` | `final int` | somma dei giorni degli intervalli usati |
| `lastMeasurementDate` | `final CivilDate?` | |
| `referenceQuantity` | `final double?` | quantita' subito dopo l'ultimo rifornimento (o la prima misura): il "pieno" della barra |
| `isActionable` | `bool get isActionable` | `quality != insufficient` |
| `fractionRemaining` | `double? get fractionRemaining` | `current / reference` tagliato a 0..1; null se riferimento ≤ 0 |
| `percentRemaining` | `int? get percentRemaining` | la frazione in percentuale intera |
| `projectedQuantityOn` | `double? projectedQuantityOn(CivilDate date)` | ultima misura − consumo dei giorni trascorsi, mai sotto zero; null senza `dailyRate` (testo della notifica) |
| `toString` | | |

`class ConsumptionCalculator` — `const ConsumptionCalculator({this.maxIntervals = 5, this.minIntervalDays = 1})`.

| Membro | Firma | Effetto |
|---|---|---|
| `maxIntervals` | `final int` | ⚑ finestra di **5 intervalli**: il consumo dipende dalla temperatura, ottobre non deve pesare su gennaio |
| `minIntervalDays` | `final int` | intervalli piu' corti scartati |
| `minSpanDays` | `static const int minSpanDays = 3` | sotto: `insufficient` |
| `goodSpanDays` | `static const int goodSpanDays = 10` | sotto (o un solo intervallo): `low` |
| `normalize` | `List<Measurement> normalize(Iterable<Measurement> measurements)` | una per data (**vince l'ultima della lista**, come nel DB), ordinate per data |
| `buildIntervals` | `List<ConsumptionInterval> buildIntervals(List<Measurement> measurements)` | normalizza, salta i tratti in **salita** (rifornimenti) e quelli < `minIntervalDays`; un tratto **piatto** resta (stufa spenta e' un dato vero) |
| `referenceQuantity` | `double? referenceQuantity(List<Measurement> sorted)` | quantita' dopo l'ultima salita, o la prima; null con lista vuota |
| `estimate` | `ConsumptionEstimate estimate({required List<Measurement> measurements, required FuelSourceSpec source, CivilDate? today})` | la stima (F5.3) |

Algoritmo di `estimate`:
1. `normalize`, `buildIntervals`, ultimi `maxIntervals` intervalli;
2. `rate = sum(consumed) / sum(days)` — ⚑ **media ponderata per la durata**, non la media delle
   velocita' (un intervallo di 2 giorni e uno di 20 non pesano uguale);
3. `insufficient` se nessun intervallo, `spanDays < 3`, `rate <= 0`, o nessuna misura;
4. `low` se un solo intervallo o `spanDays < 10`, altrimenti `good`;
5. `depletionDate = ultimaMisura + floor(current / rate)` (0 giorni se `current <= 0`);
6. `daysRemaining = max(0, oggi → depletionDate)`; `reorderDate = depletionDate − warningDays`.

☠ **L'esaurimento si conta dall'ultima misura, non da oggi.** Il piano diceva `oggi +
daysRemaining`: se l'utente non misura per dieci giorni, l'esaurimento slitterebbe in avanti di
un giorno al giorno, con riordino e notifica, e il widget (che conta i giorni dalla data,
ADR-018) non scenderebbe mai.
☠ **Velocita' <= 0** (misure tutte uguali): `dailyRate: null` e `insufficient`, mai "∞ giorni".

### `reorder_plan.dart` — quando partono le notifiche (puro)

`enum ReorderNotificationKind` — `reorder(1)` (alla `reorderDate`), `overdue(2)` (3 giorni dopo,
se nel frattempo non e' arrivata una misura); `final int slot` = ultima cifra dell'id.

`@immutable class PlannedNotification` — **valori, non testi** (⚑ una frase costruita nel
dominio non si traduce).
`const PlannedNotification({required int id, required ReorderNotificationKind kind, required DateTime fireAt, required int sourceId, required String sourceName, required String fuelTypeKey, required String unitKey, required CivilDate reorderDate, required CivilDate depletionDate, required int daysUntilDepletion, required double projectedQuantity})`;
`fireAt` e' **ora locale** (da `CivilDate.toLocalDateTime`), `daysUntilDepletion` mai negativo,
`projectedQuantity` stimata il giorno della notifica. `==`, `hashCode`, `toString` per valore.

`class ReorderPlanner` — `const ReorderPlanner({this.hour = 10, this.minute = 0, this.overdueAfterDays = 3})`.

| Membro | Firma | Effetto |
|---|---|---|
| `hour`, `minute`, `overdueAfterDays` | `final int` | 10:00, 3 giorni |
| `maxSourceId` | `static const int maxSourceId = 214748363` | il piu' grande id di fonte che lo schema regge |
| `notificationId` | `static int notificationId(int sourceId, ReorderNotificationKind kind)` | `sourceId × 10 + slot`; **ArgumentError** se `sourceId < 0` o `> maxSourceId` |
| `idsFor` | `static List<int> idsFor(int sourceId)` | tutti gli id possibili della fonte (non usato fuori dai test) |
| `plan` | `List<PlannedNotification> plan({required FuelSourceSpec source, required ConsumptionEstimate estimate, DateTime? now})` | vedi sotto |

Regole di `plan`: stima non utilizzabile → `[]`; riordino alla `reorderDate` alle 10:00;
superamento alla `reorderDate + 3` alle 10:00 **solo se** l'ultima misura non e' successiva
alla `reorderDate`; un avviso il cui momento e' gia' passato (anche alle 10:00 in punto) non si
pianifica.

⚑ **Id stabile per fonte**: ripianificare **sostituisce** invece di accumulare. Le cifre 0 e 3-9
restano libere. ☠ Gli id delle notifiche locali sono int a 32 bit con segno: oltre
`maxSourceId` l'id traboccherebbe e collidrebbe in silenzio con un'altra fonte.

### `costs.dart` — acquisti e costi (Pro)

⚑ **Tutto in centesimi interi** in entrata e in uscita: sommare euro in `double` porta a
419,99999 dopo dieci acquisti. L'unica divisione (costo medio) resta `double` e la arrotonda chi
la mostra.

`@immutable class PurchaseEntry` — `const PurchaseEntry({required CivilDate date, required double quantity, int? totalCostCents})`;
`bool get hasCost`; `==`, `hashCode`, `toString`.

`@immutable class HeatingSeason implements Comparable<HeatingSeason>` — la stagione dal 1 ottobre
al 31 marzo, identificata con l'anno in cui **comincia**.

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `const HeatingSeason(this.startYear)` | `final int startYear` |
| `start` / `end` | `CivilDate get start` / `CivilDate get end` | 1/10/startYear · 31/3/startYear+1 |
| `contains` | `bool contains(CivilDate date)` | estremi compresi |
| `containing` | `static HeatingSeason? containing(CivilDate date)` | ott-dic → anno; gen-mar → anno−1; **apr-set → null** |
| `latest` | `static HeatingSeason latest(CivilDate today)` | quella in corso o, in estate, quella **appena finita** |
| `shortLabel` | `String get shortLabel` | "2025/26" |
| `compareTo`, `==`, `hashCode`, `toString` | | per `startYear` |

⚑ In estate non si mostra la stagione che deve cominciare: avrebbe sempre zero euro.
⚑ Un acquisto estivo resta negli acquisti e nel costo medio, ma in **nessuna** spesa
stagionale (definizione del piano; **da confermare col proprietario**, §14).

`@immutable class PurchaseTotals`

| Membro | Firma | Significato |
|---|---|---|
| costruttore | `const PurchaseTotals({required int count, required double quantity, required int costedCount, required double costedQuantity, required int totalCostCents})` | |
| `of` | `factory PurchaseTotals.of(Iterable<PurchaseEntry> entries)` | totali (anche di una lista vuota) |
| `empty` | `static const PurchaseTotals empty` | tutto zero |
| `averageCentsPerUnit` | `double? get averageCentsPerUnit` | `totalCostCents / costedQuantity`; null senza acquisti con costo. ⚑ **ponderata per la quantita'** (100 sacchi a 5 € + 2 a 8 € = 5,06 €, non 6,50) |
| `uncostedCount` | `int get uncostedCount` | la pagina lo dice: la spesa e' per difetto |
| `isEmpty` | `bool get isEmpty` | |
| `==`, `hashCode`, `toString` | | |

Funzioni di modulo:

| Funzione | Firma | Effetto |
|---|---|---|
| `seasonTotals` | `PurchaseTotals seasonTotals(Iterable<PurchaseEntry> entries, HeatingSeason season)` | solo le date dentro la stagione |
| `totalsBySeason` | `List<(HeatingSeason, PurchaseTotals)> totalsBySeason(Iterable<PurchaseEntry> entries)` | dalla piu' recente, solo stagioni con acquisti, senza l'estate |

---

## 5. `lib/data/`

### `class AppDatabase extends _$AppDatabase` (`database.dart`)

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `AppDatabase(super.e)` | |
| `open` | `factory AppDatabase.open()` | file `scorte_calore.sqlite` nella cartella documenti, su isolate separato (`NativeDatabase.createInBackground`) |
| `memory` | `factory AppDatabase.memory()` | in memoria, per i test |
| `schemaVersion` | `int get schemaVersion` → `1` | |
| `migration` | `MigrationStrategy get migration` | `createAll`; `beforeOpen` → `PRAGMA foreign_keys = ON`; `onUpgrade` lancia |

Privata `_openConnection()`: imposta `sqlite3.tempDirectory` alla cartella temporanea dell'app.
☠ Su Android la cartella temporanea di sistema non e' scrivibile: senza, VACUUM e alcuni ORDER
BY grandi falliscono con "unable to open database file", **solo su dispositivo**.

Estensioni riga → dominio (stesso file):

| Estensione | Membro | Firma | Effetto |
|---|---|---|---|
| `FuelSourceToDomain on FuelSource` | `fuelTypeEnum` | `FuelType get fuelTypeEnum` | ☠ **lancia StateError** su combustibile ignoto invece di ripiegare su `pellet` |
| | `fuelUnit` | `FuelUnit get fuelUnit` | `FuelUnits.byKey(unit)` |
| | `toSpec` | `FuelSourceSpec toSpec()` | |
| `StockMeasurementToDomain on StockMeasurement` | `civilDate` | `CivilDate get civilDate` | |
| | `enteredAsEnum` | `EnteredAs get enteredAsEnum` | lancia StateError su chiave ignota |
| | `toMeasurement` | `Measurement toMeasurement()` | senza id e nota |
| `StockMeasurementListToDomain on Iterable<StockMeasurement>` | `toMeasurements` | `List<Measurement> toMeasurements()` | stesso ordine: l'ingresso di `ConsumptionCalculator.estimate` |
| `PurchaseToDomain on Purchase` | `civilDate` | `CivilDate get civilDate` | |
| `CalendarReminderToDomain on CalendarReminder` | `calculatedCivilDate` | `CivilDate get calculatedCivilDate` | (non usata: la barra del calendario fa `CivilDate.tryParse`) |

### `class ScorteRepository` (`scorte_repository.dart`)

`ScorteRepository(AppDatabase db, {DateTime Function()? clock})` — `clock` per i test (default
`DateTime.now`; gli istanti si salvano in ms UTC). **Tutte** le letture e scritture passano da qui.

⚑ **Perche' un repository**: tre regole non si scrivono come vincoli SQL e vanno rispettate a
ogni scrittura: (1) l'unita' e' ammessa per il combustibile (`FuelUnits.isAllowed`); (2) la
quantita' di una misura in percentuale e' sempre `fromPercentage(rawInput)` con la
configurazione **attuale** della fonte; (3) una misura al giorno per fonte, la seconda
sovrascrive. Dimenticarne una non darebbe errori: darebbe una stima sbagliata di un quarto.
⚑ **Righe in uscita, dominio in entrata dove basta**: le letture restituiscono le righe Drift; le
scritture prendono il dominio quando descrive tutta la scrittura (`updateSource(FuelSourceSpec)`,
`upsertMeasurement(..., Measurement)`), parametri con nome quando l'oggetto non ha ancora un id.
⚑ **I limiti del Pro non stanno qui**: li applica la UI con FeatureGate. I dati non sanno del Pro.

| Metodo | Firma | Effetto |
|---|---|---|
| `watchSources` | `Stream<List<FuelSource>> watchSources({bool activeOnly = false})` | per `sort_order`, poi id |
| `allSources` | `Future<List<FuelSource>> allSources({bool activeOnly = false})` | idem, una volta |
| `sourceById` | `Future<FuelSource?> sourceById(int id)` | |
| `watchSource` | `Stream<FuelSource?> watchSource(int id)` | anche disattivata (storico, acquisti) |
| `addSource` | `Future<int> addSource({required String name, required FuelType fuelType, String? unitKey, double? unitWeightKg, double? tankCapacity, double? usableFraction, int warningDays = FuelType.defaultWarningDays, int? costPerUnitCents})` | in fondo (`sortOrder` = numero di fonti), nome con `trim`, default del combustibile; **ArgumentError** su unita' non ammessa. **Non** controlla il limite Pro |
| `updateSource` | `Future<void> updateSource(FuelSourceSpec spec)` | transazione: riscrive **tutti** i campi (null in spec = null nel DB: cosi' si toglie una capacita'); se cambiano capacita', frazione utile o unita' → `recomputeMeasurements`. **ArgumentError** su unita', **StateError** su fonte inesistente. Non tocca `active`, `sortOrder`, `createdAt` |
| `setSourceActive` | `Future<void> setSourceActive(int id, bool active)` | (nessuna UI la chiama, §14) |
| `deleteSource` | `Future<void> deleteSource(int id)` | con misure, acquisti, promemoria (cascade). ☠ prima `CalendarSyncService.forgetSource` |
| `reorderSources` | `Future<void> reorderSources(List<int> idsInOrder)` | in transazione (nessuna UI la chiama, §14) |
| `watchMeasurements` | `Stream<List<StockMeasurement>> watchMeasurements(int sourceId, {CivilDate? since})` | **dalla piu' vecchia**; `since` compresa |
| `allMeasurements` | `Future<List<StockMeasurement>> allMeasurements(int sourceId)` | idem, una volta |
| `measurementsSince` | `Future<List<StockMeasurement>> measurementsSince(int sourceId, CivilDate since)` | per il limite dei 90 giorni (oggi la UI filtra in memoria, §9) |
| `latestMeasurement` | `Future<StockMeasurement?> latestMeasurement(int sourceId)` | precompila il foglio di aggiornamento |
| `upsertMeasurement` | `Future<int> upsertMeasurement(int sourceId, Measurement m, {String? note})` | transazione: `absolute` → `rawInput = quantity`; `percentage` → quantita' = `fromPercentage(rawInput)` con la fonte attuale; `INSERT ... ON CONFLICT(fuel_source_id, date) DO UPDATE` (nota compresa: null cancella la vecchia); restituisce l'id, **lo stesso** in caso di sostituzione. **StateError** fonte inesistente, **ArgumentError** percentuale senza capacita' |
| `deleteMeasurement` | `Future<void> deleteMeasurement(int id)` | |
| `recomputeMeasurements` | `Future<int> recomputeMeasurements(int sourceId)` | riapplica `QuantityConverter.recompute` alle misure `percentage`; restituisce quante righe sono cambiate; fonte inesistente → 0 |
| `watchPurchases` | `Stream<List<Purchase>> watchPurchases({int? sourceId})` | **i piu' recenti per primi** (data, poi id decrescente); null = tutte le fonti |
| `allPurchases` | `Future<List<Purchase>> allPurchases({int? sourceId})` | idem, una volta |
| `purchaseById` | `Future<Purchase?> purchaseById(int id)` | (non usata fuori dal repository) |
| `addPurchase` | `Future<int> addPurchase({required int sourceId, required CivilDate date, required double quantity, int? totalCostCents, String? supplier, String? note})` | fornitore e nota vuoti → null. **Non** crea una misura |
| `updatePurchase` | `Future<void> updatePurchase(Purchase purchase)` | `replace` della riga intera, fornitore e nota vuoti → null |
| `deletePurchase` | `Future<void> deletePurchase(int id)` | |
| `reminderFor` | `Future<CalendarReminder?> reminderFor(int sourceId)` | |
| `watchReminders` | `Stream<List<CalendarReminder>> watchReminders()` | |
| `upsertReminder` | `Future<void> upsertReminder({required int sourceId, required String calendarId, required String externalEventId, required CivilDate calculatedDate})` | transazione: uno per fonte; `createdAt` resta quello della prima scrittura, `lastSyncedAt` = adesso |
| `deleteReminder` | `Future<void> deleteReminder(int sourceId)` | |
| `watchAnyChange` | `Stream<void> watchAnyChange()` | un segnale a ogni modifica di `fuel_sources`, `stock_measurements`, `purchases`, `calendar_reminders` |

Privati che contano: `_requireUnitAllowed(FuelType, String)` (ArgumentError), `_blankToNull(String?)`
(una nota di soli spazi e' "niente", non una stringa vuota nel CSV), `_sourcesQuery`,
`_measurementsQuery`, `_purchasesQuery`, `_nowMs()`.

⚑ Il confronto `date >= ?` fra testi `YYYY-MM-DD` coincide con quello fra date (ADR-008).

---

## 6. `lib/app/`

### `providers.dart` — i provider radice

⚑ Niente singleton globali: un provider si sostituisce nei test con un `override` e si
inizializza pigramente. Stesso schema di Full Freezer e TrashCan.

Da sovrascrivere in `main()`, altrimenti lanciano UnimplementedError: `appConfigProvider`,
`appPathsProvider`, `settingsProvider`.

| Provider | Tipo | Cosa espone | Dipende da |
|---|---|---|---|
| `appConfigProvider` | `Provider<MicroAppConfig>` | la configurazione | override in `main` |
| `appPathsProvider` | `Provider<AppPaths>` | cartelle dell'app | override |
| `settingsProvider` | `Provider<SettingsStore>` | preferenze (namespace `scorte_calore`) | override |
| `todayProvider` | `Provider<CivilDate>` | "oggi"; **invalidato al resume** da `ScorteCaloreApp` | |
| `onboardingDoneProvider` | `Provider<bool>` | `SettingKeys.onboardingDone`, default false | `settingsProvider` |
| `themeModeProvider` | `NotifierProvider<ThemeModeNotifier, ThemeMode>` | | `settingsProvider` |
| `databaseProvider` | `Provider<AppDatabase>` | apre alla prima lettura, chiude col ProviderScope | |
| `repositoryProvider` | `Provider<ScorteRepository>` | | `databaseProvider` |
| `sourcesProvider` | `StreamProvider<List<FuelSource>>` | le fonti **attive**, nell'ordine dell'utente | repository |
| `measurementsProvider` | `StreamProvider.family<List<StockMeasurement>, int>` | tutte le misure di una fonte, per data | repository |
| `estimateProvider` | `Provider.family<ConsumptionEstimate?, int>` | la stima della fonte; null finche' mancano fonte o misure, o se la fonte non e' attiva | sources, measurements, today |
| `selectedSourceProvider` | `NotifierProvider<SelectedSource, int?>` | la fonte scelta per la testata | settings |
| `heroSourceProvider` | `Provider<FuelSource?>` | la fonte in testata: quella scelta se esiste ancora, altrimenti la prima; null senza fonti | sources, selected |

⚑ `estimateProvider` usa **tutte** le misure anche nel gratuito: il limite dei 90 giorni
riguarda cosa si vede nello storico, non la stima (che comunque usa gli ultimi 5 intervalli).
⚑ `onboardingDoneProvider` e' una **preferenza** e non "esiste almeno una fonte": il redirect
del router deve rispondere subito, mentre il database arriva dopo il primo frame. **Non e'
reattivo**: chi lo cambia lo invalida (`SourceEditorPage._save`).
⚑ La fonte in testata e' una **preferenza** e non sempre la prima: chi ha stufa e bombolone ne
guarda una, e la scelta deve sopravvivere alla chiusura dell'app.

Le classi notifier:

| Classe | `build()` | Azione |
|---|---|---|
| `ThemeModeNotifier extends Notifier<ThemeMode>` | `ThemeMode build()` — `'light'`/`'dark'`/altro = system | `Future<void> set(ThemeMode mode)` — salva `mode.name` in `SettingKeys.themeMode` |
| `SelectedSource extends Notifier<int?>` | `int? build()` — legge `selected_source` (`-1`/assente → null) | `Future<void> select(int sourceId)`; costante `static const String key = 'selected_source'` |

Altri provider fuori da questo file: `installIdProvider`, `purchaseGatewayProvider`,
`entitlementProvider`, `isProProvider`, `featureGateProvider` (`entitlement.dart`);
`notificationServiceProvider`, `scorteSchedulerProvider`, `notificationSyncProvider`,
`notificationsEnabledProvider`, `notificationPermissionProvider` (`services/notification_providers.dart`);
`calendarSyncProvider`, `remindersProvider` (`services/calendar_providers.dart`);
`widgetSyncProvider`, `widgetRefreshProvider` (`services/widget_sync.dart`);
`backupServiceProvider` (`features/settings/data_section.dart`); privati
`_historySourceProvider` (`history_page.dart`), `_purchaseSourceProvider`, `_purchasesProvider`
(`purchases_page.dart`).

### `entitlement.dart` — il Pro

| Simbolo | Firma / tipo | Significato |
|---|---|---|
| `appVersion` | `const String appVersion = '1.0.0'` | **un posto solo**: backup, server licenze, impostazioni. Va tenuta uguale al versionName di `pubspec.yaml` |
| `installIdProvider` | `FutureProvider<InstallId>` | id d'installazione (`InstallId.load(appId:)`) |
| `purchaseGatewayProvider` | `Provider<PurchaseGateway>` | `BillingMode.store` → store vero; `BillingMode.fake` → finto **senza Pro**, con prodotto a `'2,99 €'` (lo screenshot del paywall per Apple viene da qui) |
| `entitlementProvider` | `NotifierProvider<EntitlementNotifier, EntitlementView>` | `.notifier.service` per le azioni |
| `isProProvider` | `Provider<bool>` | |
| `featureGateProvider` | `Provider<FeatureGate>` | `FeatureGate(limits: scorteFeatureLimits, isPro: ...)` |

`@immutable class EntitlementView` — `const EntitlementView({required Entitlement entitlement, required bool busy, required bool storeAvailable, MicroProduct? product, MicroError? error})`;
getter `bool get isPro`, `bool get isPending`; `==` confronta entitlement, busy, store, id e
prezzo del prodotto, codice d'errore; `hashCode`.

`class EntitlementNotifier extends Notifier<EntitlementView>` — `EntitlementView build()` crea
l'EntitlementService di micro_core con `appId: licenseAppId` (file `entitlement.json` in
`support`; client del License Server solo se `serverEnabled` e l'id d'installazione c'e',
altrimenti id fisso tutto zeri), si iscrive ai cambiamenti e **avvia da solo il bootstrap**
(dimenticarlo = un'app che non si accorge di un acquisto gia' fatto); getter
`EntitlementService get service`.

☠ **Debito aperto**: il file e' identico alla parte corrispondente di TrashCan e Full Freezer
(§14).

### `feature_limits.dart`

`const FeatureLimits scorteFeatureLimits` — la mappa di §10. Nessuna pagina scrive
`if (isPro)`: si passa da `featureGateProvider`.

⚑ **F12.8 (2026-10-10)**: la mappa scrive **tutte le 16 chiavi** di `FeatureKey`. Le due nate dopo questa app sono `open()` qui, una riga ciascuna e nessun cambiamento di comportamento (il test di coerenza del paywall le vuole tutte): `imageExport` (2026-10-09, QR Me) e **`documentScan`** (2026-10-10, F12.2a: lo Scontrino di Spending Review). Tabella completa delle chiavi e di chi le limita: `packages/micro_core/codebase_reference.md`.

### `paywall_config.dart`

| Funzione | Firma |
|---|---|
| `buildScortePaywall` | `PaywallConfig buildScortePaywall(L l)` — testi, `productUnavailableLabel` e `retryLabel` (mai la rotellina eterna), 7 benefici |
| `showScortePaywall` | `Future<bool> showScortePaywall(BuildContext context, WidgetRef ref, {FeatureKey? highlight})` — `true` se si esce col Pro |

Benefici, in quest'ordine (⚑ quello che vende: prima il promemoria, che e' il motivo per cui si
apre l'app): `notifications`, `unlimitedEntities`, `fullHistory`, `statistics` (costi),
`calendarSync`, `backupRestore`, `csvExport`.

### `app_config.dart`

| Simbolo | Firma | Significato |
|---|---|---|
| `licenseAppId` | `const String licenseAppId = 'scortecalore'` | chiave della tabella `apps` e di APP_SECRETS sul License Server |
| `buildScorteConfig` | `MicroAppConfig buildScorteConfig()` | `MicroAppConfig.fromEnvironment(appId: 'scorte_calore', appName: 'Scorte Calore', proSku: 'scortecalore_pro_lifetime', seedColor: Color(0xFFF4511E), fontFamily: 'PlusJakartaSans', defaultBrightness: Brightness.light)` |

☠ **`licenseAppId` non e' `appId`**: `appId` (`scorte_calore`) nomina cartelle e preferenze; il
server usa gli id senza trattino basso. Mandare l'id locale fa rifiutare ogni verifica
d'acquisto come "app sconosciuta" (pagato con Full Freezer).
L'arancio `#F4511E` e' quello della fiamma dell'icona (misurato il 2026-10-07), al posto del
`#C4622D` del piano.

### `scorte_palette.dart` — interfaccia «A · Brace»

`@immutable class ScortePalette extends ThemeExtension<ScortePalette>` — costruttore const con
tutti i campi `required` (tipo Color):

| Campo | Chiaro | Scuro | Uso |
|---|---|---|---|
| `ground` | `#F7F2EE` | `#0B1220` | fondo caldo dietro le schede (diventa `scaffoldBackgroundColor`) |
| `card` | `#FFFFFF` | `#152036` | schede |
| `ink` / `inkMuted` | `#1B1A22` / `#6B625D` | `#EDF1F8` / `#9AA7BF` | testo |
| `night` | `#14213A` | `#1A2944` | testata della fonte principale, pannelli |
| `nightRaised` | `#1C2C4B` | `#233658` | riquadro del riordino, pulsanti sulla testata |
| `nightBorder` | `#2B3B5C` | `#33496F` | bordo dei pulsanti sulla testata |
| `onNight` / `onNightMuted` | `#FFFFFF` / `#C9D3E6` | idem | testo sulla testata |
| `ember` | `#FF7A3D` | `#FF8A52` | giorni di autonomia, barra del residuo |
| `emberLabel` | `#FF9A62` | `#FFA676` | etichetta maiuscola sopra la testata |
| `flame` / `onFlame` | `#F4511E` / `#FFFFFF` | idem | pulsante "Aggiorna scorta", FAB degli acquisti |
| `track` | `#23345A` | `#2C4170` | binario della barra del residuo |
| `badge` | `#FFB547` | idem | icona del calendario, avvisi "provvisoria"/"vecchia" |
| `iconTile` / `onIconTile` | `#FFE9DE` / `#D9461A` | `#3A2219` / `#FF8A52` | riquadro dell'icona nelle righe |

| Membro | Firma |
|---|---|
| `light`, `dark` | `static const ScortePalette light`, `static const ScortePalette dark` |
| `of` | `static ScortePalette of(BuildContext context)` — ripiega su `light` |
| `copyWith` | `ScortePalette copyWith()` — restituisce se stessa |
| `lerp` | `ScortePalette lerp(ThemeExtension<ScortePalette>? other, double t)` — scatta a meta' |

Funzione: `ThemeData withScorteLook(ThemeData base, ScortePalette p)` — `scaffoldBackgroundColor`
e l'estensione.

⚑ Una ThemeExtension e non il ColorScheme: testata blu notte e arancio brace non sono ruoli
Material, e forzarli dentro cambierebbe colore a pulsanti e campi.

### `labels.dart` — i nomi visibili

| Funzione | Firma | Effetto |
|---|---|---|
| `fuelName` | `String fuelName(L l, FuelType type)` | `l.fuel_pellet`, `fuel_lpg`, `fuel_diesel`, `fuel_wood`, `fuel_biomass` |
| `unitName` | `String unitName(L l, String unitKey, double quantity)` | `unit_<key>` accordato (singolare solo per `quantity == 1`); chiave ignota → la chiave stessa |
| `formatAmount` | `String formatAmount(L l, String unitKey, double quantity, {int minDecimals = 0})` | "12 sacchi", "344 L", "0,8 sacchi" con i decimali dell'unita' (almeno `minDecimals`) |

☠ Singolare e plurale si scelgono sul numero **arrotondato** mostrato: con il valore grezzo 0,98
diventava "1 bags" (emulatore, 2026-10-07).

### `formats.dart`

| Funzione | Firma | Effetto |
|---|---|---|
| `formatLiters` | `String formatLiters(double liters, String locale)` | 2 decimali sotto 1 L, 1 fino a 10, 0 oltre (non usata nell'app: ereditata) |
| `formatQuantity` | `String formatQuantity(double q, String locale)` | al massimo 2 decimali |
| `parseUserNumber` | `double? parseUserNumber(String input)` | virgola **o** punto, spazi tolti; null se vuoto o non numerico |

⚑ Tutte e due i separatori: alcune tastiere numeriche mostrano solo il punto.

### `locale_resolution.dart`

`const List<Locale> kSupportedLocales = [Locale('en'), Locale('it')]` — **inglese per primo**
(Flutter ripiega sul primo). `Locale resolveAppLocale(List<Locale>? deviceLocales, Iterable<Locale> supported)`
— italiano se `it` compare fra le preferenze, altrimenti inglese (ADR-011).

---

## 7. Le rotte

Dichiarate in `lib/app/routes.dart` (`abstract final class Routes`), registrate in
`buildRouter` (`lib/app/app.dart`): `GoRouter buildRouter(WidgetRef ref)`, `initialLocation: Routes.home`.

| Costante | Percorso | Pagina | Parametri | Gate |
|---|---|---|---|---|
| `Routes.home` | `/` | `HomePage` | | |
| `Routes.welcome` | `/welcome` | `SourceEditorPage(firstRun: true)` | | primo avvio |
| `Routes.settings` | `/settings` | `SettingsPage` | | |
| `Routes.sourceNew` | `/sources/new` | `ProGate(unlimitedEntities, allowed: withinLimit)` → `SourceEditorPage()` | | limite di 1 fonte: `openNewSource` all'ingresso **e** `ProGate` |
| `Routes.sourceEdit` | `/sources/:sourceId/edit` | `SourceEditorPage(sourceId:)` | `sourceId` (`int.tryParse`, null → editor di una fonte **nuova**) | |
| `Routes.history` | `/sources/:sourceId/history` | `HistoryPage(sourceId:)` | `sourceId` (non numerico → -1, pagina vuota) | nessuno sulla rotta: grafici e oltre 90 giorni bloccati **dentro** la pagina |
| `Routes.purchases` | `/sources/:sourceId/purchases` | `ProGate(statistics)` → `PurchasesPage(sourceId:)` | `sourceId` (non numerico → -1) | Pro: `openPurchases` all'ingresso **e** `ProGate` |

Helper: `static String sourceEditOf(int id)`, `static String historyOf(int id)`,
`static String purchasesOf(int id)`. Costante `static const String scheme = 'scortecalore'`
(oggi non letta da nessun codice Dart, §14).

⚑ `sourceNew` e' registrata **prima** di `:sourceId`: go_router prova le rotte in ordine.
⚑ Routes contiene **solo i percorsi che esistono**.
Per `/sources/new` il controllo e' `allowed: (gate) => gate.withinLimit(FeatureKey.unlimitedEntities, numero di fonti attive)`,
con il numero letto da `sourcesProvider` nel builder della rotta.

**Redirect**: senza `onboardingDone` ogni percorso diverso da `/welcome` porta a `/welcome`
(anche da una notifica). ⚠️ Al contrario di Full Freezer, chi **ha** fatto l'onboarding e va su
`/welcome` **non** viene rimandato alla home: ci arriva solo da `SourceEditorPage` stessa.

☠ **Pro sulla pagina, non con un `redirect`**: un `push` che redireziona a "/" mette "/" due
volte nella pila e go_router mostra la sua pagina d'errore (Full Freezer, 2026-10-07).

### Chi apre l'app su una pagina

| Sorgente | Payload / URI | Arriva a | Codice |
|---|---|---|---|
| Notifica di riordino o superamento | payload `/` (`Routes.home`) | home | `ScorteScheduler.toScheduled` |
| Widget Android | intent di avvio del pacchetto (`getLaunchIntentForPackage`) | dove l'app era, o la home | `ScorteCaloreWidgetProvider.kt` |
| Widget iOS | `scortecalore:///?homeWidget` (`widgetURL`) | dove l'app era, o la home | `ScorteCaloreWidget.swift` |

⚑ **Il payload delle notifiche e' la home**: e' li' che si vedono la stima e il pulsante
"Aggiorna scorta". Il widget non apre pagine specifiche: Dart non ascolta i tocchi del widget
(nessun `widgetClicked`, nessun `initiallyLaunchedFromHomeWidget`).

`ScorteCaloreApp` (`class ScorteCaloreApp extends ConsumerStatefulWidget`, `const ScorteCaloreApp({Key? key})`):

- **notifiche**: appena `notificationServiceProvider` ha un valore si iscrive a `taps` e consuma
  il payload di lancio (app aperta da chiusa);
- `_openPayload(String payload)`: `go(home)` e poi `push(payload)` **solo se** il payload non e'
  la home (☠ senza il controllo la home finirebbe due volte nella pila);
- al **resume** (AppLifecycleListener): `invalidate(todayProvider)` e
  `scorteSchedulerProvider.rescheduleAll()` (le date di riordino dipendono da "oggi");
- `build`: `MaterialApp.router` con MicroTheme chiaro/scuro (`DynamicSchemeVariant.fidelity`:
  l'arancio resta quello acceso della fiamma invece del bruno che Material ricaverebbe) +
  `withScorteLook(..., ScortePalette.light/dark)`, `themeModeProvider`, `kSupportedLocales`,
  `resolveAppLocale`; tiene vivi con un `watch` **`widgetSyncProvider`**,
  **`widgetRefreshProvider`** e **`notificationSyncProvider`**.

☠ **Il deep link di Flutter e' spento** su entrambe le piattaforme
(`flutter_deeplinking_enabled=false` nel manifest, `FlutterDeepLinkingEnabled=false` in
`Info.plist`): acceso, Flutter passava da solo l'URI del widget a go_router come `go`, che
sostituisce la pila (pagato con Full Freezer).
☠ `MainActivity.onNewIntent` fa `setIntent(intent)` (trappola di Full Freezer, F5.0 punto 7).
Qui il widget apre l'app con l'intent di avvio, quindi la correzione e' oggi una cintura di
sicurezza per il giorno in cui il widget aprira' una pagina.

---

## 8. `lib/services/`

### `scorte_scheduler.dart` — la consegna delle notifiche

| Simbolo | Firma | Significato |
|---|---|---|
| `scorteChannelId` | `const String scorteChannelId = 'scorte_reorder'` | ☠ **non si cambia mai**: Android lega al canale le scelte dell'utente (suono, silenzioso, spento); un id nuovo e' un canale nuovo |
| `scorteChannel` | `MicroNotificationChannel scorteChannel(L l)` | nome e descrizione nella lingua del telefono (`notif_channelName`, `notif_channelDescription`) |

⚑ Una funzione e non una costante come in Full Freezer: il nome del canale si legge nelle
impostazioni di sistema, e Android lo aggiorna a ogni `createNotificationChannel` con lo stesso id.

`class ScorteScheduler implements NotificationScheduler`

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `ScorteScheduler({required ScorteRepository repo, required SettingsStore settings, required FeatureGate gate, required L l, NotificationService? notifications, ConsumptionCalculator calculator = const ConsumptionCalculator(), ReorderPlanner planner = const ReorderPlanner(), DateTime Function()? clock})` | |
| campi | `final ScorteRepository repo`, `final SettingsStore settings`, `final FeatureGate gate`, `final L l`, `final NotificationService? notifications`, `final ConsumptionCalculator calculator`, `final ReorderPlanner planner` | `notifications` null finche' il servizio non e' pronto |
| `isReady` | `bool get isReady` | `notifications != null` |
| `allowed` | `bool get allowed` | `gate.allows(FeatureKey.notifications)` **e** `SettingKeys.notificationsEnabled` (default **false**) |
| `cancelAll` | `Future<void> cancelAll()` | |
| `rescheduleAll` | `Future<void> rescheduleAll()` | senza servizio non fa niente; non `allowed` → `cancelAll`; altrimenti `replaceSchedule(buildSchedule(...))` e salva `SettingKeys.lastRescheduleAt` |
| `buildSchedule` | `@visibleForTesting Future<List<ScheduledNotification>> buildSchedule({DateTime? now})` | per ogni fonte **attiva**: misure → `calculator.estimate` → `planner.plan` → `toScheduled`. Salta le fonti con id > `ReorderPlanner.maxSourceId`. Non controlla il Pro |
| `toScheduled` | `@visibleForTesting ScheduledNotification toScheduled(PlannedNotification p)` | testi dagli ARB, `channelId: scorteChannelId`, `payload: Routes.home`, `exact` = false (default) |

Testi: riordino → `notif_reorderTitle(sourceName)` + `notif_reorderBody(fuel, days, amount)`
("Pellet: potrebbe terminare tra circa 7 giorni. Ti restano circa 14 sacchi."); superamento →
`notif_overdueTitle(sourceName)` + `notif_overdueBody(fuel)`.

☠ **Il Pro si controlla qui**, dove il piano viene consegnato, non solo nell'interruttore: una
notifica gia' pianificata sopravvive a un rimborso.
⚑ Tutto il piano si ricalcola da zero e si consegna con `replaceSchedule`, che cancella le
pendenti non piu' volute: fonte eliminata o disattivata, stima diventata insufficiente.
⚑ `exact: false` → `inexactAllowWhileIdle`: un promemoria alle 10:12 invece che alle 10:00 non
cambia niente, e il permesso degli alarm esatti Play lo contesta a chi non e' una sveglia.
⚑ "Pellet: potrebbe terminare…" invece di "Il pellet…": l'articolo cambia col combustibile e
`fuelName` non lo porta.

### `notification_providers.dart`

| Simbolo | Tipo / firma | Significato |
|---|---|---|
| `_systemL()` (privata) | `L _systemL()` | traduzioni con la lingua del telefono risolta come l'app: le notifiche si scrivono fuori da ogni widget |
| `notificationServiceProvider` | `FutureProvider<NotificationService>` | creato al primo uso, icona `@drawable/ic_notification`, canale `scorteChannel(_systemL())` |
| `scorteSchedulerProvider` | `Provider<ScorteScheduler>` | ricostruito quando cambiano Pro o servizio (`.value`, null finche' non c'e') |
| `notificationSyncProvider` | `Provider<void>` | all'avvio `rescheduleAll` (se pronto), poi a ogni `watchAnyChange` con **500 ms di debounce** |
| `NotificationsEnabled extends Notifier<bool>` | `bool build()` (**default false**), `Future<void> set(bool value)` | salva e `rescheduleAll` |
| `notificationsEnabledProvider` | `NotifierProvider<NotificationsEnabled, bool>` | |
| `notificationPermissionProvider` | `FutureProvider.autoDispose<bool>` | `service.hasPermission()`; ⚑ `autoDispose`: si rilegge riaprendo la pagina, dopo le impostazioni di sistema |

⚑ **Su `watchAnyChange` e non su `estimateProvider`**: le stime esistono solo per le fonti che
una pagina guarda, le notifiche servono per tutte; e una misura puo' arrivare da piu' punti
(foglio, storico con "Annulla", ripristino).
☠ **L'interruttore parte spento**: le notifiche sono Pro e il permesso si chiede solo
accendendole. Col default acceso l'interruttore si mostrava acceso senza permesso e il primo
tocco lo **spegneva** (Full Freezer, emulatore, 2026-10-07).

### `calendar_sync.dart` — l'evento di riordino (F5.10, Pro)

⚑ **`device_calendar_plus` 0.10.1 e non `device_calendar`** (decisione del 2026-10-08):
`device_calendar` e' fermo al settembre 2024 e non ha il permesso "accesso completo" di iOS 17.

`@immutable class CalendarChoice` — `const CalendarChoice({required String id, required String name, String? account, bool isPrimary = false})`.

`abstract interface class CalendarGateway` — il confine con il plugin (⚑ nei test non c'e'
nessun sistema: cosi' le regole si provano senza telefono).

| Metodo | Firma | Contratto |
|---|---|---|
| `requestAccess` | `Future<bool> requestAccess()` | true se il permesso c'e' o e' stato concesso |
| `writableCalendars` | `Future<List<CalendarChoice>> writableCalendars()` | |
| `createAllDay` | `Future<String> createAllDay({required String calendarId, required String title, required String description, required CivilDate day})` | id dell'evento |
| `updateAllDay` | `Future<void> updateAllDay({required String eventId, required String title, required String description, required CivilDate day})` | ☠ solleva `CalendarEventMissing` se l'evento non c'e' piu' |
| `delete` | `Future<void> delete(String eventId)` | idem |

`class CalendarEventMissing implements Exception` — `const CalendarEventMissing()`: l'evento e'
stato cancellato a mano.

`class DeviceCalendarGateway implements CalendarGateway` — `const DeviceCalendarGateway()`, su
`DeviceCalendar.instance`:
- `requestAccess` → `requestPermissions() == CalendarPermissionStatus.granted`. ⚑ **Accesso
  completo, non "solo scrittura"**: per aggiornare o togliere l'evento bisogna ritrovarlo, e con
  la sola scrittura iOS non lo lascia leggere;
- `writableCalendars` → `listCalendars()` senza i `readOnly` e gli `hidden`;
- `createAllDay` → `createEvent(..., startDate: day.toLocalMidnight(), endDate: day+1 a mezzanotte, isAllDay: true, availability: EventAvailability.free)`;
- `updateAllDay` → `updateEvent(instanceId:, description: Patch.set(...), ...)`;
  `DeviceCalendarError.notFound` → `CalendarEventMissing`;
- `delete` → `deleteEvent(instanceId:)`; idem.

`typedef ReorderEventTexts = ({String title, String description})` — i testi gia' tradotti.

`class CalendarSyncService` — `CalendarSyncService(ScorteRepository repo, [CalendarGateway gateway = const DeviceCalendarGateway()])`.

| Membro | Firma | Effetto |
|---|---|---|
| `driftDays` | `static const int driftDays = 3` | soglia della proposta di aggiornamento |
| `errDenied` | `static const String errDenied = 'calendar_denied'` | codice d'errore |
| `errNoCalendar` | `static const String errNoCalendar = 'calendar_none'` | codice d'errore |
| `drifted` | `static bool drifted(CivilDate written, CivilDate current)` | `|written → current| > 3` giorni, in tutte e due le direzioni |
| `availableCalendars` | `Future<Result<List<CalendarChoice>>> availableCalendars()` | chiede il permesso; il principale per primo; `Err(errDenied)`, `Err(errNoCalendar)`, `MicroError.unexpected` |
| `upsertReorderEvent` | `Future<Result<String>> upsertReorderEvent({required FuelSource source, required CivilDate date, required String calendarId, required ReorderEventTexts texts, String? existingEventId})` | permesso; aggiorna l'evento esistente o, se `CalendarEventMissing`, **ne crea uno nuovo**; poi `repo.upsertReminder` |
| `deleteEvent` | `Future<Result<void>> deleteEvent(String calendarId, String eventId)` | un evento gia' sparito conta come tolto (`calendarId` non usato: il plugin lo ritrova dall'id) |
| `forgetSource` | `Future<void> forgetSource(int sourceId)` | toglie l'evento (anche se il calendario non risponde, logga e prosegue) e `repo.deleteReminder` |
| `forgetAll` | `Future<void> forgetAll()` | `forgetSource` per ogni promemoria |

⚑ **L'app propone, non sposta**: oltre `driftDays` la home mostra la frase e "Aggiorna
evento"; l'evento si tocca solo dopo quel tocco. Un'app che sposta da sola gli eventi e'
invadente, e se il calendario e' condiviso manda avvisi ad altre persone.
☠ **`forgetSource` va chiamato prima di `deleteSource`** (`SourceEditorPage._delete`) **e
prima di un ripristino "sostituisci tutto" si leggono i promemoria** (`restoreBackup`, che poi toglie gli eventi solo se il ripristino riesce): dopo, la riga che
diceva quale evento togliere non c'e' piu' (cascade) e l'evento resta orfano nel calendario.
⚑ Evento cancellato a mano dall'utente → si ricrea: ha appena chiesto di averlo.

Evento: titolo `calendar_eventTitle(fuel, source)` ("Riordino Pellet · Stufa soggiorno"),
descrizione `calendar_eventBody(date)` ("Autonomia stimata fino al 9 dicembre. Creato da
Scorte Calore."), giornata intera alla `reorderDate`, disponibilita' "libero".
**Provato il 2026-10-08** sull'emulatore: evento di un giorno intero il 2 dicembre, con titolo e
descrizione giusti.

☠ **Sull'emulatore senza account Google non c'e' nessun calendario** (`calendar_none`). Per
provare se ne crea uno locale:

```
adb shell content insert --uri 'content://com.android.calendar/calendars?caller_is_syncadapter=true&account_name=prova&account_type=LOCAL' ...
```

(con le colonne del calendario: nome, visibilita', livello di accesso proprietario).

### `calendar_providers.dart`

| Provider | Tipo | Cosa espone |
|---|---|---|
| `calendarSyncProvider` | `Provider<CalendarSyncService>` | il servizio sul repository |
| `remindersProvider` | `StreamProvider<Map<int, CalendarReminder>>` | i promemoria per id di fonte |

### `scorte_widget.dart` — il widget di sistema (lato Dart)

`abstract final class ScorteWidget` — contratto completo in §9bis.

| Membro | Firma | Effetto |
|---|---|---|
| `available` | `static bool get available` | Android o iOS, non web (sul desktop dei test il canale solleva) |
| `iosGroup` | `static const String iosGroup = 'group.com.smp.scortecalore'` | |
| `iosName` | `static const String iosName = 'ScorteCaloreWidget'` | il `kind` Swift |
| `androidName` | `static const String androidName = 'com.smp.scortecalore.ScorteCaloreWidgetProvider'` | ☠ **con il package** |
| chiavi | `keyTitle`, `keyRows`, `keyToday`, `keyDaysTemplate`, `keyReorderTemplate`, `keyReorderNow`, `keyNeedMore`, `keyEmpty` (`static const String`) | §9bis |
| `fieldSeparator` | `static const String fieldSeparator = '\u001F'` | US |
| `countPlaceholder` / `datePlaceholder` | `static const String countPlaceholder = '{n}'`, `datePlaceholder = '{d}'` | |
| `rowCount` | `static const int rowCount = 3` | fonti al massimo |
| `buildRow` | `@visibleForTesting static String buildRow({required String name, required ConsumptionEstimate? estimate, required String reorderShort})` | `nome US esaurimento US riordino US riordinoBreve`; date vuote se la stima non c'e'; a capo → spazio |
| `daysTemplate` | `@visibleForTesting static String daysTemplate(L l)` | "{n} giorni" / "{n} days", dal testo dell'app con il numero sentinella 987654 |
| `publish` | `static Future<void> publish({required List<FuelSource> sources, required ConsumptionEstimate? Function(int sourceId) estimateOf, required String Function(CivilDate date, String localeName) formatShortDate})` | su iOS `setAppGroupId`; scrive tutte le chiavi e `updateWidget`. **Ogni errore e' assorbito e loggato**: il widget non deve mai far fallire un salvataggio o l'avvio |
| `scheduleDailyRefresh` | `static Future<void> scheduleDailyRefresh()` | **solo Android**: `scheduleWidgetUpdates` con 365 orari alle **00:05** |

### `widget_sync.dart`

| Provider | Tipo | Effetto |
|---|---|---|
| `widgetSyncProvider` | `Provider<void>` | si ricostruisce quando cambiano le fonti, la fonte in testata o una stima, e ripubblica; ordine: **la fonte in testata prima** (il piccolo iOS mostra solo quella), poi le altre; data breve con `DateFormat.MMMd` ("2 dic") |
| `widgetRefreshProvider` | `Provider<void>` | una volta per avvio: `ScorteWidget.scheduleDailyRefresh()` |

⚑ Un provider e non una chiamata in ogni schermata che salva: chi scrive domani una pagina
nuova non deve ricordarsi del widget.

### `scorte_backup_source.dart`

`class ScorteBackupSource implements BackupSource` — `const ScorteBackupSource(AppDatabase db, {DateTime Function()? clock})`;
campi `final AppDatabase db`, `final DateTime Function()? clock`.

| Membro | Firma | Effetto |
|---|---|---|
| `id` | `static const String id = 'scorte_calore'` | riconosce i backup dell'app prima di chiedere come ripristinarli |
| `schemaId` | `String get schemaId` → `id` | |
| `schemaVersion` | `int get schemaVersion` → `1` | |
| `exportPayload` | `Future<Map<String, Object?>> exportPayload()` | `{'sources': [{name, fuelType, unit, unitWeightKg, tankCapacity, usableFraction, warningDays, costPerUnitCents, active, sortOrder, createdAt, measurements: [{date, quantity, enteredAs, rawInput, note}], purchases: [{date, quantity, totalCostCents, supplier, note}]}]}` — anche le fonti disattivate |
| `importPayload` | `Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode})` | in una transazione; vedi sotto |
| `imagePaths` | `Future<List<String>> imagePaths()` | `[]`: l'app non ha foto, il backup e' un JSON solo |
| `counts` | `Future<Map<String, int>> counts()` | `sources`, `measurements`, `purchases` (il riepilogo prima del ripristino) |

`importPayload`:
- `ImportMode.replaceAll`: cancella tutte le fonti (cascade su misure, acquisti, promemoria) e
  mette quelle del file col loro `sortOrder`;
- `ImportMode.mergeKeepExisting`: aggiunge in fondo **saltando le fonti con lo stesso nome**
  (due "Stufa soggiorno" con due storie darebbero due stime per la stessa stufa);
- combustibile o unita' sconosciuti/non ammessi → FormatException;
- ⚑ la quantita' delle misure in percentuale si **ricalcola dal `rawInput`** con la fonte appena
  scritta (`QuantityConverter.recompute`), anche se il file porta un'altra quantita';
- due misure nella stessa data: `InsertMode.insertOrReplace`, vince l'ultima.

⚑ **Payload annidato** (fonti → misure, fonti → acquisti): gli id di riga non significano
niente su un altro telefono, e annidando non c'e' niente da rimappare.
⚑ **Le misure portano `enteredAs` e `rawInput`**: un backup appiattito in quantita' funzionerebbe
il giorno del ripristino e tradirebbe l'utente alla prima modifica della fonte.
☠ **I promemoria del calendario restano fuori di proposito**: contengono id che esistono solo sul
telefono dove sono stati creati; su un altro punterebbero al nulla, o a un evento di un altro
calendario con lo stesso id. Dopo il ripristino si rimettono dalla home.
☠ `importPayload` lancia **FormatException, mai un Error**: un TypeError da un cast viene
convertito, perche' `BackupService.restore` intercetta solo le Exception e altrimenti
arriverebbe come crash invece che come "file rovinato". La transazione e' annullata.

### `csv_export.dart`

| Funzione | Firma | Effetto |
|---|---|---|
| `exportScorteCsv` | `Future<File> exportScorteCsv({required AppPaths paths, required L l, required List<FuelSource> sources, required List<StockMeasurement> measurements, required List<Purchase> purchases, required CivilDate today})` | scrive `exports/scorte-calore-<YYYY-MM-DD>.csv` |
| `buildScorteCsv` | `CsvWriter buildScorteCsv({required L l, required List<FuelSource> sources, required List<StockMeasurement> measurements, required List<Purchase> purchases})` | il contenuto, senza disco |
| `csvDecimal` | `String csvDecimal(double value, {bool fixed = false})` | virgola decimale, niente migliaia, max 2 decimali senza zeri inutili; `fixed` = sempre 2 (soldi) |

Colonne: Tipo, Fonte, Data, Quantita', Unita', Lettura %, Costo (euro "12,50"), Fornitore,
Nota. Righe per fonte (ordine di `sources`), poi per data; a parita' di data prima la misura.
"Lettura %" solo per le misure `percentage`. Righe di fonti assenti da `sources` saltate.

⚑ **Un file solo con una colonna "Tipo"**: il foglio di condivisione manda un file alla volta,
e in Excel un filtro separa le due cose con un clic. ⚑ Separatore `;` e BOM UTF-8 (CsvWriter):
Excel in italiano lo apre con un doppio clic. ⚑ **I numeri sono numeri**: `formatQuantity` in
inglese scriverebbe "1,200" per milleduecento, che Excel italiano legge 1,2; e
`343.99999999999994.toString()` finirebbe nel foglio cosi' com'e'.

---

## 9. `lib/features/` — le schermate

### Home — `features/home/home_page.dart`

`class HomePage extends ConsumerWidget` — `const HomePage({Key? key})`. «A · Brace»:

- in testata (privata `_Hero`, su `night`): etichetta maiuscola "NOME · COMBUSTIBILE"
  (`emberLabel`), "Ti restano …" (`home_amountLeft`), pulsanti Storico (`Routes.historyOf`),
  Modifica (`Routes.sourceEditOf`), Impostazioni; **i giorni di autonomia enormi** (92 pt,
  `ember`) con `home_daysWord` e `home_autonomy`, oppure `home_needMore` se la stima non e'
  utilizzabile; la barra del residuo (`fractionRemaining`), "% dall'ultimo rifornimento" e
  consumo al giorno; il riquadro del riordino (`home_reorderBox` / `home_reorderBoxPast` se la
  data e' passata, `home_runsOutShort`) con sotto `CalendarReminderBar`; l'avviso
  `home_provisional(intervalsUsed)` con stima `low`, o `home_stale` se l'ultima misura ha **piu'
  di 14 giorni**;
- senza fonti (dopo averle cancellate tutte): `_EmptyHero` con `source_intro`;
- sotto, le altre fonti (`_SourceRow`): **toccarne una la porta in testata**
  (`selectedSourceProvider.select`);
- "Aggiungi fonte" (`openNewSource`);
- in fondo, fisso, "Aggiorna scorta" (`flame`) → `showUpdateSheet` della fonte in testata.

Barra di stato con icone chiare (`SystemUiOverlayStyle.light`) anche nel tema chiaro: la
testata e' blu notte.

| Funzione | Firma | Effetto |
|---|---|---|
| `openNewSource` | `Future<void> openNewSource(BuildContext context, WidgetRef ref)` | se il numero di fonti attive non e' `withinLimit(unlimitedEntities)` apre il paywall; poi `push(Routes.sourceNew)` |

### Aggiorna scorta — `features/stock/update_sheet.dart`

`Future<void> showUpdateSheet(BuildContext context, FuelSource source)` — bottom sheet (privati
`_UpdateSheet`/`_UpdateSheetState`).

- data = oggi (selettore fino a oggi, dal 2020);
- quantita' **precompilata con l'ultima misura** (`latestMeasurement`); se l'ultima era in
  percentuale e la fonte la supporta, il foglio parte gia' sul manometro;
- interruttore "lettura del manometro" solo se `supportsPercentage` e l'unita' non e' gia'
  `percent`; con la percentuale (≤ 100) mostra la conversione mentre si digita
  (`update_conversion`: lettura, capacita' **nominale**, litri utili arrotondati);
- avviso `update_refill` se il valore e' piu' alto dell'ultimo (un rifornimento);
- Salva → `upsertMeasurement` (percentuale: `Measurement(..., enteredAs: percentage, rawInput: v)`;
  il repository ricalcola comunque la quantita').

⚑ Salvare costa un tocco: si corregge un numero invece di scriverlo da zero.

### Fonte — `features/sources/source_editor_page.dart`

`class SourceEditorPage extends ConsumerStatefulWidget` — `const SourceEditorPage({int? sourceId, bool firstRun = false, Key? key})`;
`sourceId` null = fonte nuova.

Campi: nome (max 60), combustibile (ChoiceChip; cambiarlo riporta l'unita' al default se non
ammessa e la quota utile al default), unita' (`FuelUnits.forType`), **solo per GPL/gasolio**
capienza in litri (obbligatoria > 0) e quota utile (slider 50–100%, passi del 5%), **solo per
unita' con peso** il peso di un'unita', **solo per una fonte nuova** la scorta iniziale, costo
per unita' in euro (facoltativo, salvato in centesimi), anticipo del riordino (1–60 giorni).

Salva: nuova → `addSource` + (se c'e' la scorta) `upsertMeasurement(absolute, oggi)` +
`SettingKeys.onboardingDone = true` + `invalidate(onboardingDoneProvider)`; esistente →
`updateSource(FuelSourceSpec(...))`. Al primo avvio `go(home)`, altrimenti `pop`.
Elimina (solo esistente) → MicroConfirmSheet distruttivo → **`forgetSource` poi
`deleteSource`** → `pop`.

⚑ **Una pagina sola e non una procedura a otto passi** come diceva il piano: i campi sono pochi
e quasi tutti hanno gia' un valore giusto; quelli che non servono non compaiono.

### Calendario — `features/calendar/calendar_reminder_bar.dart`

`class CalendarReminderBar extends ConsumerWidget` — `const CalendarReminderBar({required FuelSource source, required CivilDate reorderDate, CivilDate? depletionDate, Key? key})`.

| Stato | Mostra | Tocco |
|---|---|---|
| nessun promemoria | "Aggiungi al calendario" (+ ProBadge senza Pro) | senza Pro paywall (`calendarSync`); `availableCalendars`; se ce n'e' uno solo lo usa, altrimenti foglio di scelta; `upsertReorderEvent` |
| promemoria con deriva > 3 giorni | `calendar_drift(data scritta)` + "Aggiorna evento" | `upsertReorderEvent` con l'evento esistente |
| promemoria allineato | "Nel calendario" | foglio "Togli dal calendario" → `forgetSource` |

Errori → snack `calendar_denied` / `calendar_none` / `calendar_failed` secondo il codice.

### Storico — `features/history/history_page.dart`

| Simbolo | Firma | Effetto |
|---|---|---|
| `historyStart` | `CivilDate? historyStart(FeatureGate gate, CivilDate today)` | null col Pro; altrimenti `today − (freeMax − 1)`: **90 giorni oggi compreso**, letti dal gate |
| `HistoryPage` | `class HistoryPage extends ConsumerStatefulWidget` — `const HistoryPage({required int sourceId, Key? key})` | |

La pagina: titolo "Storico · nome"; in alto i grafici (`_Charts`, Pro `statistics`) o il
riquadro bloccato (`_LockedCharts`, apre il paywall); la porta verso acquisti e costi
(`_PurchasesTile`, `openPurchases`, badge senza Pro); le misure per mese dalla piu' recente
(`_MonthLabel` "OTTOBRE 2026", `_MonthCard`, `_MeasurementRow` con delta dalla precedente,
`history_refillDelta` per i rifornimenti, `−` tipografico per i cali, `history_gauge` per le
letture del manometro, nota); in fondo, nel gratuito, `_FreeLimitCard` con quante misure piu'
vecchie si vedono col Pro. Elimina col cestino o scorrendo, con "Annulla" che rimette la misura
con `upsertMeasurement` (non con un insert della riga: le regole passano da una porta sola;
l'id cambia ed e' indifferente). Fonte inesistente → pagina vuota, non una rotellina eterna.

⚑ **Il limite dei 90 giorni si applica in memoria** a `measurementsProvider`, non con
`watchMeasurements(since:)`: la stessa lista serve alla stima (uno stream solo), il delta della
prima misura visibile si calcola con la precedente nascosta, e si sa quante misure il gratuito
non mostra.
☠ Un Dismissible scartato deve sparire dall'albero **nello stesso frame** ("A dismissed
Dismissible widget is still part of the tree"): lo stream di Drift arriva dopo, quindi le righe
eliminate finiscono subito in `_gone`.
Provider privato: `_historySourceProvider` (`StreamProvider.autoDispose.family<FuelSource?, int>`,
`watchSource`): la fonte anche se disattivata.

### Grafici — `features/history/charts.dart`

| Simbolo | Firma | Effetto |
|---|---|---|
| `chartLeftGutter` | `const double chartLeftGutter = 40` | margine sinistro **uguale** per i due grafici |
| `refillDates` | `List<CivilDate> refillDates(List<Measurement> sorted)` | le date in cui la scorta **sale** |
| `niceCeiling` | `double niceCeiling(double v)` | primo valore tondo (1, 2, 2,5, 5 × 10^k) ≥ v; ≤ 0, NaN, infinito → 1 |
| `StockChart` | `class StockChart extends StatelessWidget` — `const StockChart({required List<Measurement> measurements, double height = 180, Key? key})` | linea arancio con area tenue; rifornimenti come cerchi blu notte e tratto in salita tratteggiato |
| `RateChart` | `class RateChart extends StatelessWidget` — `const RateChart({required List<ConsumptionInterval> intervals, required CivilDate firstDay, required CivilDate lastDay, double? estimateRate, double height = 140, Key? key})` | una barra per intervallo **larga quanto l'intervallo**, alta quanto il consumo al giorno; stima attuale tratteggiata |

Privati: `_Frame` (data → x, valore → y, assi), `_StockPainter`, `_RatePainter`, `_text`,
`_dashed`, `_edgeDates`, `_Anchor`.

⚑ **Disegnati a mano con CustomPainter, niente `fl_chart`** (decisione del 2026-10-08): due
grafici semplici non valgono un pacchetto in piu' su due piattaforme.
⚑ **Lo stesso asse del tempo** (dalla prima all'ultima misura, stesso margine): la barra di
gennaio sta sotto il tratto di gennaio della scorta.
⚑ Barre larghe quanto l'intervallo: nella stima un intervallo di venti giorni pesa venti volte
uno di un giorno (media ponderata), e il grafico deve far vedere la stessa cosa.
⚑ I rifornimenti si ricavano **dalle misure, non dagli acquisti**: sono visibili anche a chi gli
acquisti non li registra.
Accessibilita': ogni grafico ha una Semantics (`chart_stockSemantics`, `chart_rateSemantics`).

### Acquisti e costi (Pro) — `features/purchases/`

`purchases_page.dart`:

| Simbolo | Firma | Effetto |
|---|---|---|
| `openPurchases` | `Future<void> openPurchases(BuildContext context, WidgetRef ref, int sourceId)` | senza Pro (`statistics`) paywall, poi `push(Routes.purchasesOf(sourceId))` |
| `formatEuro` | `String formatEuro(num cents, String locale, {int decimals = 2})` | "364,00 €" / "€364.00" |
| `toPurchaseEntries` | `List<PurchaseEntry> toPurchaseEntries(Iterable<Purchase> rows)` | righe → dominio |
| `PurchasesPage` | `class PurchasesPage extends ConsumerStatefulWidget` — `const PurchasesPage({required int sourceId, Key? key})` | |

La pagina: pannello blu notte con la spesa dell'inverno (`HeatingSeason.latest`, euro interi
quando la cifra e' tonda) e quanti acquisti senza costo non sono contati; prezzo medio per
unita' (3 decimali sotto 1 € — GPL e gasolio si contano al millesimo) e quantita'
dell'inverno; gli inverni precedenti; gli acquisti dal piu' recente (tocco = modifica,
scorrere = elimina con "Annulla" che ricrea con `addPurchase`); FAB "Aggiungi acquisto";
in fondo la regola della stagione (`costs_seasonRule`).
Provider privati: `_purchaseSourceProvider`, `_purchasesProvider` (autoDispose family).

`purchase_editor_sheet.dart`:

| Simbolo | Firma | Effetto |
|---|---|---|
| `showPurchaseEditor` | `Future<void> showPurchaseEditor(BuildContext context, FuelSource source, {Purchase? purchase, String? lastSupplier, VoidCallback? onDelete})` | foglio nuovo/modifica; `lastSupplier` precompila il fornitore (di solito e' lo stesso ogni anno); `onDelete` aggiunge "Elimina" (il foglio si chiude e la **pagina** cancella, perche' lo snack con "Annulla" deve vivere sulla pagina) |
| `parseEuroCents` | `int? parseEuroCents(String input)` | euro digitati → centesimi arrotondati ("5,195" → 520); null se vuoto, non numerico, negativo |

Campi: data (dal 2000 a oggi), quantita' (**> 0**, chiave `purchase_quantity`), costo
(facoltativo, chiave `purchase_cost`, valido se vuoto o ≥ 0), fornitore (`purchase_supplier`),
nota.

### Impostazioni — `features/settings/`

`class SettingsPage extends ConsumerWidget` (`settings_page.dart`): riga del Pro (tocco su tutta
la riga → paywall), `NotificationsSection`, "Metti il widget sulla schermata iniziale" (solo
dove `ScorteWidget.available`), `DataSection`, "Ripristina acquisti" (testo Apple/Google),
tema (foglio con sistema/chiaro/scuro), versione (`appVersion`). Privata
`_pinWidget(BuildContext, L)`: su iOS spiega come aggiungerlo a mano (`widget_addIos`); su
Android `requestPinWidget` se il launcher lo supporta, altrimenti `widget_addUnsupported`.

⚑ Le righe rispondono al tocco su tutta la superficie: in TrashCan il riquadro non rispondeva e
il proprietario l'ha trovato rotto.

`class NotificationsSection extends ConsumerWidget` (`notifications_section.dart`): senza Pro
ProBadge e paywall (`notifications`); col Pro un interruttore; acceso ma bloccato dal sistema →
sottotitolo `settings_notifDenied` in rosso. Privata
`_setNotifications(BuildContext, WidgetRef, bool)`: accendendo chiede il permesso
(`ensurePermission`) — ☠ col permesso negato l'interruttore **resta spento**.

`data_section.dart`:

| Simbolo | Firma | Effetto |
|---|---|---|
| `backupServiceProvider` | `Provider<BackupService>` | `BackupService(paths:, appVersion: appVersion)` |
| `DataSection` | `class DataSection extends ConsumerWidget` — `const DataSection({Key? key})` | "I tuoi dati": CSV (Pro), backup (Pro), ripristino (gratis); le voci Pro **si vedono** col badge |
| `exportCsv` | `Future<void> exportCsv(BuildContext context, WidgetRef ref)` | senza Pro paywall; **tutte** le fonti (anche disattivate) e tutto lo storico; condivide il file |
| `createBackup` | `Future<void> createBackup(BuildContext context, WidgetRef ref)` | senza Pro paywall; `createBackup(ScorteBackupSource)` e condivisione |
| `restoreBackup` | `Future<void> restoreBackup(BuildContext context, WidgetRef ref)` | sceglie il file, `inspect` (schemaId diverso → errore subito), riepilogo con i conteggi, scelta sostituisci/aggiungi; con "sostituisci" **legge i promemoria prima** e, solo se il ripristino riesce, toglie gli eventi con `deleteEvent`; dopo, con almeno una fonte, `onboardingDone = true` |

⚑ **Ripristino gratis**, creazione Pro: chi cambia telefono deve riavere i dati anche prima di
aver ripristinato l'acquisto (stessa scelta di Full Freezer).
☠ "Sostituisci tutto" e' irreversibile: il riepilogo prima della conferma e' il solo modo per
accorgersi del file sbagliato (lezione di TrashCan).
⚑ Il CSV non e' tagliato ai 90 giorni: e' Pro, e un CSV tagliato sarebbe un dato che sparisce
senza avviso.

### Il lucchetto Pro — `features/common/pro_gate.dart`

`class ProGate extends ConsumerWidget` — `const ProGate({required FeatureKey feature, required Widget child, bool Function(FeatureGate gate)? allowed, Key? key})`.
Con il permesso mostra `child`; senza, una pagina con lucchetto, `pro_locked` e il pulsante del
paywall con `feature` evidenziata; si ridisegna da sola quando arriva il Pro. Copiato da Full
Freezer.

### Avvio — `lib/main.dart` e `lib/dev/demo_data.dart`

`Future<void> main()`: `buildScorteConfig()` + `assertUsableInRelease()` (☠ una release col
billing finto regalerebbe il Pro), `AppPaths.forApp`, `ensureAll`, log su
`logs/scorte_calore.log`, `FlutterError.onError` → log, `SettingsStore.create(namespace: 'scorte_calore')`,
`_recordLaunch` (conta gli avvii e registra il primo, per decidere quando chiedere una
recensione), dati demo se richiesti, `runApp` con gli override dei tre provider radice.

⚑ Database, notifiche e store li inizializzano i provider, pigramente: farlo prima del primo
frame produce una schermata bianca all'avvio.

| Simbolo | Firma | Effetto |
|---|---|---|
| `demoRequested` | `const bool demoRequested = bool.fromEnvironment('SC_DEMO')` | |
| `demoEnabled` | `bool get demoEnabled` | `demoRequested && !kReleaseMode`: ☠ **mai in release** |
| `seedDemoData` | `Future<bool> seedDemoData(AppDatabase db, SettingsStore settings, {bool english = false})` | solo su database vuoto: "Stufa soggiorno" (pellet, 15 kg, 6,90 €, 10 misure in 60 giorni con un rifornimento) e "Bombolone GPL" (1000 L, 0,85 €, 5 letture del manometro in 40 giorni); `onboardingDone = true`; true se ha scritto |

⚑ Esistono perche' la stima si accende solo dopo qualche giorno di misure, e da fuori (adb) non
si possono inserire date nel passato.

---

## 9bis. Il widget di sistema: il contratto fra Dart, Kotlin e Swift

**Cosa mostra**: titolo ("SCORTE" / "HEATING STOCK"), fino a **tre fonti attive** (la fonte in
testata nell'app per prima) con nome, giorni di autonomia a destra e sotto "Riordina entro il
2 dic" o "Riordina ora". Senza stima: "–" e "Serve un'altra misura". Senza fonti: "Apri Scorte
Calore per aggiungere una fonte". Su blu notte come la testata della home. Android 4x2; iOS
**piccolo** (una fonte sola, numero grande) e **medio** (tre righe). **Gratuito** (ADR-019).
Tocco → apre l'app (nessuna pagina specifica).

### Le chiavi condivise (preferenze del plugin / UserDefaults del gruppo)

| Dart (`ScorteWidget`) | Valore | Kotlin | Swift (Chiavi) | Contenuto |
|---|---|---|---|---|
| `keyTitle` | `title` | KEY_TITLE | `titolo` | `widget_title` |
| `keyRows` | `rows` | KEY_ROWS | `righe` | le righe, separate da `\n` |
| `keyToday` | `days_today` | KEY_TODAY | `oggi` | `widget_runsOutToday` ("Finisce oggi") per 0 giorni |
| `keyDaysTemplate` | `days_template` | KEY_DAYS_TEMPLATE | `modelloGiorni` | "{n} giorni" / "{n} days" |
| `keyReorderTemplate` | `reorder_template` | KEY_REORDER_TEMPLATE | `modelloRiordino` | `widget_reorderBy('{d}')` |
| `keyReorderNow` | `reorder_now` | KEY_REORDER_NOW | `riordinaOra` | `widget_reorderNow` |
| `keyNeedMore` | `need_more` | KEY_NEED_MORE | `servonoMisure` | `widget_needMore` |
| `keyEmpty` | `empty` | KEY_EMPTY | `vuoto` | `widget_empty` |
| `fieldSeparator` | `\u001F` | FIELD | `separatoreCampo` | US |
| `iosGroup` | `group.com.smp.scortecalore` | — | `gruppo` | |

**Riga**: `nome US esaurimento US riordino US riordinoBreve` — date `YYYY-MM-DD` (vuote se la
stima non e' utilizzabile); nome con gli a capo sostituiti da spazi; `riordinoBreve` = la data
di riordino gia' scritta nella lingua dell'app ("2 dic"). Una riga con meno di 4 campi si
salta (Kotlin la nasconde, Swift la scarta).

☠ **Le chiavi sono scritte a mano in tre linguaggi**: una divergenza da' un campo vuoto nel
widget senza nessun errore, e su una piattaforma sola. Se ne cambi una, cambiale tutte e tre.

### Perche' cosi'

⚑ **ADR-018: il payload porta date, non giorni.** I giorni cambiano a mezzanotte anche se
nessuno apre l'app, e Dart gira solo con l'app aperta. Il payload porta la **data di
esaurimento** e la data di riordino: **Kotlin calcola i giorni con `LocalDate.now()`**, **Swift
con la data della voce della timeline** (8 voci). Il numero non invecchia mai.
⚑ L'esaurimento parte dall'**ultima misura** (§4): senza misure nuove la data non slitta, e il
widget scende di un giorno al giorno da solo.
⚑ `riordinoBreve` arriva gia' formattata da Dart: formattare le date in Kotlin e Swift vorrebbe
dire rifare la localizzazione in tre linguaggi.
⚑ "Riordina ora" e il colore ambra li decide il widget (oggi ≥ data di riordino), con la stessa
logica dei giorni: anche quello cambia a mezzanotte.
⚑ Il modello dei giorni si ricava dal testo dell'app con un numero sentinella (987654): il widget
dice i giorni esattamente come la home.
⚑ **Il widget non e' una leva del Pro** (ADR-019): `FeatureKey.advancedWidget` e' `open()`.

### Android — `ScorteCaloreWidgetProvider.kt` + layout

`class ScorteCaloreWidgetProvider : HomeWidgetProvider()` — `onUpdate(context, appWidgetManager,
appWidgetIds, widgetData)` chiama la privata `update` dentro un `try`. Per ogni widget: titolo
(se pubblicato); per ognuna delle 3 righe (ROW_IDS, data class `Riga(row, name, detail, days)`):
nome; senza esaurimento "–" in MUTED e `need_more`; altrimenti giorni =
`ChronoUnit.DAYS.between(oggi, esaurimento)` (mai negativi; 0 → `days_today`, altrimenti
`days_template` con `{n}`), colore **ALARM `#FFB547`** se oggi ≥ riordino (dettaglio
`reorder_now`) altrimenti **EMBER `#FF7A3D`** (dettaglio `reorder_template` con `{d}` =
`riordinoBreve`). `widget_empty` visibile se l'app non ha mai pubblicato o le righe sono vuote
(testo da `empty` se pubblicato). Tocco: `PendingIntent.getActivity` sull'intent di avvio del
pacchetto (FLAG_IMMUTABLE, obbligatorio da Android 12). Privati: `data(String)` (parse
sicuro), `testoGiorni(Long, SharedPreferences)`. Costanti nel companion: le chiavi, FIELD,
EMBER, ALARM, MUTED `#C9D3E6`.

| File | Ruolo |
|---|---|
| `res/layout/scorte_calore_widget.xml` | `widget_root`, `widget_title`, `widget_empty`, `widget_row{1,2,3}` con `widget_name/detail/days{1,2,3}` |
| `res/layout/scorte_calore_widget_preview.xml` | anteprima nel selettore con due fonti d'esempio |
| `res/xml/scorte_calore_widget_info.xml` | 250x110 dp, `targetCell` 4x2, ridimensionabile (min 180x80), `updatePeriodMillis="0"`, `home_screen` |
| `res/values/widget.xml` (+ `values-it/`) | `widget_label`, `widget_description`, `widget_title`, `widget_open_app`, `widget_sample{1,2}`, `widget_sample_detail{1,2}`, `widget_sample_days{1,2}`; stili WidgetRow, WidgetTexts, WidgetName, WidgetDetail, WidgetDays |
| `res/drawable/widget_background.xml` | blu notte `#14213A`, raggio 22dp |

☠ **Solo LinearLayout e TextView**: RemoteViews non disegna un ConstraintLayout, senza errori.
⚑ Tre righe fisse con visibilita' e non una lista: una ListView in RemoteViews vuole un
RemoteViewsService.
☠ Righe con **altezza 0 e peso 1**: con `wrap_content` stavano in alto e lasciavano mezzo widget
vuoto, che si legge come "non ha caricato" (Full Freezer).
☠ Tutto `onUpdate` in un `try`: un'eccezione in un BroadcastReceiver fa cadere **l'intero
processo dell'app**.
⚑ I testi di riserva stanno in `res/values`: il selettore e il primo disegno avvengono prima che
l'app sia mai partita. Mai un widget vuoto.
⚑ `updatePeriodMillis = 0`: gli aggiornamenti li pilotano l'app (a ogni modifica) e l'**allarme
delle 00:05**; con un periodo il sistema sveglierebbe il telefono per niente.
☠ **HomeWidgetScheduledUpdateReceiver deve stare nel manifest**: senza, la sveglia delle 00:05
scatta e non arriva a nessuno, e il widget resta ai giorni di ieri. BOOT_COMPLETED e
MY_PACKAGE_REPLACED la riarmano. `scheduleDailyRefresh` passa 365 orari: il plugin ne arma uno
per volta. **Solo Android**: su iOS non serve.
☠ `androidName` **con il package**: col solo nome il plugin cerca la classe sotto
l'applicationId, e con un suffisso `.debug` non la trova.

**Provato il 2026-10-08 sull'emulatore Android.**

### iOS — `ios/ScorteCaloreWidget/`

| Simbolo Swift | File | Ruolo |
|---|---|---|
| `struct ScorteCaloreWidget: Widget` (`@main`) | `ScorteCaloreWidget.swift` | `kind = "ScorteCaloreWidget"` (= `ScorteWidget.iosName`), famiglie small e medium, descrizione it/en, `contentMarginsDisabled()` |
| `struct Fornitore: TimelineProvider` | idem | `placeholder`, `getSnapshot`; `getTimeline`: **8 voci** (adesso + le 7 mezzanotti seguenti), policy `.atEnd` |
| `struct VistaConFamiglia: View` | idem | passa la famiglia, `widgetURL(scortecalore:///?homeWidget)`, `sfondoWidget()` (privata: `containerBackground` da iOS 17) |
| `enum Chiavi`, `separatoreCampo` | `VistaScorte.swift` | le chiavi della tabella sopra |
| `enum Ripiego` | idem | `italiano`, `titolo`, `apri`: testi **detti dall'estensione da sola** (lingua da `Locale.preferredLanguages`) |
| `struct RigaFonte: Hashable` | idem | `nome`, `esaurimento: Date?`, `riordino: Date?`, `riordinoBreve` |
| `struct VoceScorte: TimelineEntry` | idem | `giorni(_:)` rispetto alla data **della voce**, `testoGiorni(_:)`, `daRiordinare(_:)`, `dettaglio(_:)`, `coloreGiorni(_:)`; `senzaDati` |
| `struct Deposito` | idem | lettura astratta (`leggi`), `static var condiviso` = UserDefaults del gruppo, `static let formatoData` (`yyyy-MM-dd`, `en_US_POSIX`, fuso locale), `voce(al:)` |
| `extension Color` | idem | `init(argb:)`, `notte #14213A`, `brace #FF7A3D`, `braceChiara #FF9A62`, `ambra #FFB547`, `suNotteSpento #C9D3E6` |
| `struct VistaScorte: View` | idem | il disegno: vuoto → testo; small → `piccolo` (la prima riga, numero a 30 pt); medium → `rigaLarga` × 3 con `maxHeight: .infinity` |

⚑ **Una voce per ciascuno dei prossimi 7 giorni a mezzanotte**: su iOS non c'e' sveglia; e'
WidgetKit a passare da una voce all'altra, e ogni voce calcola i giorni rispetto alla propria
data. L'app fa ricaricare la timeline a ogni modifica (`updateWidget`).
☠ Il parametro `?homeWidget` nell'URL e' quello con cui il plugin riconosce un tocco sul widget
(`HomeWidgetPlugin.isWidgetUrl`) e non lo passa al router.
☠ `contentMarginsDisabled` e `containerBackground` (iOS 17+): senza, il fondo blu resta staccato
dai bordi dentro un riquadro bianco.
☠ Il gruppo `group.com.smp.scortecalore` e' ripetuto in quattro posti (Dart, Swift, due
`.entitlements`) e va **registrato sul portale Apple e agganciato a ciascun App ID**: senza,
`saveWidgetData` scrive in un contenitore nullo, nessun errore, widget vuoto. Per questo
Ripiego esiste.

**Provato il 2026-10-08 sul Mac**, con l'anteprima e i dati veri del simulatore (§2ter).

---

## 10. Cosa e' Pro e cosa e' gratis

La mappa vive in `lib/app/feature_limits.dart` (`scorteFeatureLimits`) ed e' l'**unico** posto
in cui cambiarla. Decisioni del proprietario del 2026-10-07 (F5.0).

| Funzione | Chiave | Piano gratuito | Dove si controlla |
|---|---|---|---|
| Seconda fonte e oltre | `unlimitedEntities` | **una** (`count(freeMax: 1)`) | `openNewSource` + `ProGate` su `/sources/new` |
| Notifiche di riordino e superamento | `notifications` | no | impostazioni **e** `ScorteScheduler.allowed` |
| Storico oltre 90 giorni | `fullHistory` | **90 giorni** (`count(freeMax: 90)`), i dati restano nel DB | `historyStart` in `HistoryPage` |
| Grafici, acquisti e costi | `statistics` | no | `HistoryPage` (grafici), `openPurchases` + `ProGate` su `/sources/:id/purchases` |
| Evento nel calendario | `calendarSync` | no | `CalendarReminderBar._add` |
| Export CSV | `csvExport` | no | `exportCsv` |
| Creazione del backup | `backupRestore` | no — **il ripristino e' gratis** | `createBackup` |
| Widget | `advancedWidget` | **si'** (ADR-019) | |
| `secondaryEntities`, `multipleNotifications`, `photos`, `customCategories`, `pdfReport`, `themeCustomization` | | aperte: l'app non le ha | |

**Il gratuito risponde alla domanda dell'app**: una fonte, misure illimitate, stima, autonomia
e data di riordino, in app e nel widget. **Il Pro vende** la notifica prima di restare senza
(decisione del proprietario: «le notifiche sono pro»), le altre fonti, lo storico per
confrontare gli inverni, il calendario, i costi, CSV e backup.

⚑ Lo storico gratuito e' di 90 giorni ma le misure piu' vecchie **restano nel database** e la
stima le usa: chi compra il Pro le ritrova, e la pagina dice quante sono.
☠ **Ogni chiave limitata compare fra i benefici del paywall e viceversa** (7 e 7): lo verifica
`test/widget/paywall_config_test.dart` (aggiunto il 2026-10-08, copiato da Full Freezer).
Le funzioni aperte sono dichiarate comunque nella mappa: si legge cosa NON e' a pagamento, e
l'assert di FeatureGate non scatta.

---

## 11. Configurazione e chiavi

| Chiave | Dove | Default | Significato |
|---|---|---|---|
| SC_DEMO | `--dart-define` | `false` | dati di esempio su database vuoto; **ignorato in release** |
| BILLING | `--dart-define` (letto da `MicroAppConfig.fromEnvironment`) | `fake` in debug, `store` in release | `fake` = gateway finto **senza Pro** a 2,99 €; `play` accettato come grafia storica; una release con `fake` fallisce all'avvio |
| MA_LICENSE_URL, MA_APP_SECRET | `--dart-define-from-file` | vuoti | server licenze; senza, `serverEnabled` falso e l'entitlement lavora in locale |
| `appId` | `app_config.dart` | `scorte_calore` | namespace delle preferenze, cartelle, log; anche `ScorteBackupSource.id` |
| `licenseAppId` | `app_config.dart` | `scortecalore` | id sul License Server (≠ `appId`) |
| `proSku` | `app_config.dart` | `scortecalore_pro_lifetime` | **immutabile**: uno SKU pubblicato non si cancella ne' si riusa |
| `seedColor` / `fontFamily` | `app_config.dart` | `#F4511E` / PlusJakartaSans | font variabile in `assets/fonts/PlusJakartaSans-Variable.ttf` (licenza OFL in `assets/fonts/OFL.txt`) |
| `applicationId` / `namespace` | `android/app/build.gradle.kts` | `com.smp.scortecalore` | **immutabile** dopo il primo upload |
| `minSdk` / `targetSdk` | idem | 24 / quello di Flutter | desugaring attivo (flutter_local_notifications); release con minify e shrink |
| `storeFile`, `storePassword`, `keyAlias`, `keyPassword` | `android/key.properties` (non versionato) | assenti | senza, la release si firma in debug e Play la rifiuta; keystore **PKCS12** |
| bundle iOS | `project.pbxproj` | `com.smp.scortecalore` (+ `.ScorteCaloreWidget`) | |
| App Group | entitlements + `ScorteWidget.iosGroup` + `Chiavi.gruppo` | `group.com.smp.scortecalore` | |
| Schema URL iOS | `Info.plist` | `scortecalore` | `Routes.scheme` |
| Canale notifiche | `scorteChannelId` | `scorte_reorder` | ☠ **mai cambiarlo** |
| `version` | `pubspec.yaml` | `1.0.0+1` | `appVersion` va tenuta uguale |
| `schemaVersion` DB / backup | `database.dart` / `ScorteBackupSource` | `1` / `1` | |

### Preferenze (SettingsStore, namespace `scorte_calore`: chiave salvata `scorte_calore.<chiave>`)

| Classe.costante | Chiave | Tipo | Chi la scrive / legge |
|---|---|---|---|
| `SelectedSource.key` | `selected_source` | int (assente/-1 = la prima) | `SelectedSource` / `heroSourceProvider` |
| SettingKeys.onboardingDone (micro_core) | `onboarding_done` | bool, default false | editor della prima fonte, ripristino, demo / redirect del router |
| SettingKeys.notificationsEnabled | `notifications_enabled` | bool, **default false** | `NotificationsEnabled` / `ScorteScheduler.allowed` |
| SettingKeys.themeMode | `theme_mode` | String `light`\|`dark`\|`system` | `ThemeModeNotifier` |
| SettingKeys.launchCount, SettingKeys.firstLaunchAt | `launch_count`, `first_launch_at` | int, istante | `main` (`_recordLaunch`) |
| SettingKeys.lastRescheduleAt | `last_reschedule_at` | istante | `ScorteScheduler.rescheduleAll` |

### Permessi

| Piattaforma | Permesso | Perche' |
|---|---|---|
| Android | `com.android.vending.BILLING` | acquisti; dichiarato a mano perche' Play guarda il pacchetto caricato |
| Android | RECEIVE_BOOT_COMPLETED | riarmare notifiche e sveglia del widget dopo un riavvio |
| Android | READ_CALENDAR, WRITE_CALENDAR | ☠ **solo in Scorte Calore** (Play li fa giustificare nella scheda); lettura compresa per ritrovare l'evento |
| Android | receiver ScheduledNotificationReceiver, ScheduledNotificationBootReceiver | senza, il plugin pianifica senza errori e la notifica non arriva mai |
| Android | receiver HomeWidgetScheduledUpdateReceiver | la sveglia delle 00:05 del widget |
| Android | (nessun INTERNET nel manifest principale; solo in debug/profile) | vedi §14 |
| iOS | NSCalendarsUsageDescription, NSCalendarsFullAccessUsageDescription | calendario (iOS 17+ vuole il secondo per l'accesso completo) |

I testi iOS stanno in inglese in `Info.plist` e in **`Runner/{en,it}.lproj/InfoPlist.strings`**
(aggiunti al progetto con `tool/aggiungi_infoplist_strings.rb`).

### Testi (l10n)

**217 chiavi**, template **inglese** (`l10n.yaml`: `template-arb-file: app_en.arb`,
`output-class: L`, `nullable-getter: false`, `output-dir: lib/l10n/generated`): una chiave
dimenticata deve produrre inglese in un'app italiana, non il contrario.

Classi **generate** in `lib/l10n/generated/` (non si modificano): `abstract class L` (con
`L.of(context)`, `L.delegate`), `class LEn extends L`, `class LIt extends L`, e la funzione
`L lookupL(Locale locale)`, usata fuori dai widget (notifiche, widget, test).

☠ **Gli ARB non si modificano mai a mano.** Si scrive in `tool/testi.py` (TESTI comuni:
appTitle, common, fuel, unit, source, home, update, paywall, pro, settings, theme) e nei
`tool/testi_*.py` caricati da `tutti_i_testi()` (in ordine alfabetico; una chiave ripetuta in
due file e' un errore):

| File | Parte |
|---|---|
| `tool/testi_widget.py` | `widget_*` |
| `tool/testi_notifiche.py` | `notif_*`, `settings_notif*` |
| `tool/testi_storico.py` | `history_*`, `chart_*`, `purchase_*`, `costs_*` |
| `tool/testi_dati.py` | `data_title`, `csv_*`, `backup_*` |
| `tool/testi_calendario.py` | `calendar_*` |

Ogni chiave ha le due lingue sulla stessa riga `'chiave': ('inglese', 'italiano')`; segnaposti
`{nome}` (tipo in TIPI: `n`, `count`, `days`, `percent` sono int, il resto String); plurali
ICU. ☠ Virgolette **tipografiche** anche in inglese: con quelle dritte gli script adb non
trovano piu' i riquadri.

Prefissi: appTitle 1, common 9, fuel 5, unit 8, source 21, home 23, update 7, paywall 24, pro 1,
settings 12, theme 3, calendar 14, data 1, csv 14, backup 14, notif 6, history 11, chart 10,
purchase 15, costs 8, widget 10.

Flusso: `python tool/testi.py` (scrive i due ARB) → `pwsh ../../tool/fl.ps1 gen-l10n`.

### Comandi

Dalla cartella `apps/scorte_calore`, sempre con la toolchain del progetto:

```
pwsh ../../tool/fl.ps1 test                                   # i 158 test
pwsh ../../tool/fl.ps1 analyze                                # analisi statica
python tool/testi.py; pwsh ../../tool/fl.ps1 gen-l10n         # dopo aver cambiato un testo
pwsh ../../tool/fl.ps1 build apk                              # APK
pwsh ../../tool/fl.ps1 build apk --debug --dart-define=SC_DEMO=true   # con due fonti di esempio
pwsh ../../tool/fl.ps1 pub run build_runner build             # dopo una modifica a tables.dart (rigenera database.g.dart)
pwsh ../../tool/verify_atlas.ps1 -Project apps/scorte_calore  # dalla radice: atlante contro codice
```

☠ In `pubspec.yaml` l'analyzer di build_runner ha un tetto `<14.4.0`: con la 14.5 la
generazione di Drift muore con "The setter 'contextFeatures' isn't defined".
⚑ Ogni dipendenza entra con la sottofase che la usa: una dipendenza aggiunta prima del suo
codice e' un plugin nativo in piu' da compilare su due piattaforme senza che nessuno lo provi.

---

## 12. Catalogo dei test

**158 test** in `apps/scorte_calore/test/`.

| File | N. | Cosa dimostra |
|---|---|---|
| `test/data/scorte_repository_test.dart` | 38 | vedi sotto |
| `test/domain/consumption_test.dart` | 24 | vedi sotto |
| `test/domain/costs_test.dart` | 11 | vedi sotto |
| `test/domain/fuel_units_test.dart` | 13 | vedi sotto |
| `test/domain/quantity_converter_test.dart` | 14 | vedi sotto |
| `test/domain/reorder_plan_test.dart` | 11 | vedi sotto |
| `test/features/history/history_page_test.dart` | 8 | vedi sotto |
| `test/features/history/purchases_page_test.dart` | 7 | vedi sotto |
| `test/services/backup_csv_test.dart` | 7 | vedi sotto |
| `test/services/calendar_sync_test.dart` | 8 | vedi sotto |
| `test/services/scorte_scheduler_test.dart` | 8 | vedi sotto |
| `test/services/scorte_widget_test.dart` | 4 | vedi sotto |
| `test/widget/paywall_config_test.dart` | 5 | ogni chiave limitata e' un beneficio del paywall e viceversa, in it e in en; ogni FeatureKey e' dichiarata; una fonte gratis, la seconda Pro; widget gratis (ADR-019); notifiche, statistiche, calendario, CSV e backup Pro |

### `scorte_repository_test.dart` (38, su `AppDatabase.memory()`, orologio fisso)

- **fonti** (6): una fonte nuova prende i default del combustibile (GPL 0,80, litri, 7 giorni);
  la riga diventa il FuelSourceSpec giusto; un'unita' non ammessa (litri di pellet) e' rifiutata
  dal repository; le fonti si accodano, si riordinano, si filtrano per attive; `updateSource`
  riscrive tutti i campi **anche togliendo un valore**; aggiornare una fonte inesistente e' un errore.
- **vincoli dello schema** (9): capacita' zero/negativa rifiutata dal CHECK, NULL ammessa;
  frazione utile in (0, 1]; peso unitario positivo; combustibile e unita' devono essere chiavi
  note; **le liste dei CHECK vengono dal dominio**; misura con quantita' negativa, `enteredAs`
  ignoto o percentuale > 100 rifiutata; acquisto con quantita' zero o costo negativo rifiutato;
  **le foreign key sono attive** (cancellare una fonte porta via misure, acquisti, promemoria);
  una misura per una fonte inesistente e' rifiutata.
- **misurazioni** (10): **una al giorno, la seconda sovrascrive con lo stesso id**; stesso giorno
  su due fonti non e' un conflitto; **il vincolo UNIQUE regge anche senza il repository**; ordine
  di data qualunque sia l'ordine d'inserimento; `measurementsSince` include la data limite e solo
  quella fonte; **la percentuale la converte il repository: 43% di 1000 L utili 0,8 = 344 L**; un
  assoluto salva `rawInput = quantity`; percentuale senza capacita' = errore; `deleteMeasurement`
  toglie solo quella riga; le righe arrivano al calcolatore come Measurement.
- **ricalcolo dopo un cambio di configurazione** (6): cambiare la capacita' ricalcola le
  percentuali e non gli assoluti; cambiare la frazione utile ricalcola; rinominare non riscrive le
  misure; **togliere la capacita' lascia le misure com'erano**; passare all'unita' `percent` riporta
  le percentuali al valore grezzo; `recomputeMeasurements` su fonte inesistente non fa niente.
- **acquisti** (2): crea, modifica, cancella, piu' recenti per primi; **un acquisto non crea una
  misura**.
- **promemoria nel calendario** (2): uno per fonte, il secondo aggiorna e `createdAt` resta;
  UNIQUE(fuelSourceId) regge anche senza il repository.
- **watch** (3): `watchMeasurements` riemette dopo un upsert; `watchSources(activeOnly)` segue
  attivazione e ordine; `watchAnyChange` avvisa per fonti, misure, acquisti e promemoria.

### `consumption_test.dart` (24)

- **test obbligatori di F5.3** (8): tre misure decrescenti regolari (calcolo base); rifornimento a
  meta' serie: l'intervallo in salita e' scartato; due misure identiche → `insufficient`, nessuna
  divisione per zero; una sola misura → `insufficient`; **intervalli di durata diversa: media
  ponderata** (30/22, non 3); otto intervalli → solo gli ultimi 5; due misure lo stesso giorno →
  vince l'ultima, niente intervallo a zero giorni; percentuale con 0,8: 43% di 1000 L = 344 L.
- **qualita' della stima** (6): meno di 3 giorni di dati → `insufficient` anche con velocita';
  un solo intervallo anche lungo → `low`; due intervalli ma meno di 10 giorni → `low`; solo
  rifornimenti → `insufficient`; nessuna misura → `insufficient`, quantita' 0, niente barra;
  `minIntervalDays` scarta gli intervalli corti.
- **date** (5): **l'esaurimento si conta dall'ultima misura, senza misure nuove non slitta**;
  esaurimento gia' passato → 0 giorni, mai negativi; scorta a zero → esaurita il giorno
  dell'ultima misura; l'anticipo del riordino segue `warningDays`; la quantita' stimata a una
  data scende col consumo e non va sotto zero.
- **residuo rispetto all'ultimo rifornimento** (5): senza rifornimenti il riferimento e' la prima
  misura; dopo un rifornimento e' la quantita' subito dopo; vale anche con stima `insufficient`;
  riferimento zero → niente percentuale; `ConsumptionInterval.rate`.

### `costs_test.dart` (11)

`HeatingSeason` (4): estremi compresi (1/10 e 31/3); `containing` autunno → anno, inverno →
anno prima, estate → null; `latest` in estate e' la stagione appena finita; `shortLabel` a due
cifre anche a cavallo del secolo. `PurchaseTotals` (5): vuoto → zero e media null; **media
ponderata per la quantita'**; senza costo conta nella quantita' ma non nella media; solo senza
costo → media null; un costo zero (regalo dichiarato) entra nella media. Spesa stagionale (2):
`seasonTotals` conta solo dentro la stagione; `totalsBySeason` dalla piu' recente, senza l'estate.

### `fuel_units_test.dart` (13)

Le otto chiavi del piano una volta ciascuna; `byKey` lancia su chiave sconosciuta invece di
ripiegare; peso unitario solo per i contenitori, **mai per gli steri**; unita' ammesse per pellet,
GPL/gasolio, legna, biomassa; l'unita' predefinita e' ammessa ed e' la prima proposta; chiavi
del database stabili e rileggibili; frazione utile 0,80 solo per il GPL; solo GPL e gasolio hanno
un serbatoio; `FuelSourceSpec.withDefaults` prende unita', frazione e 7 giorni; chiavi di
`EnteredAs` stabili.

### `quantity_converter_test.dart` (14)

Percentuale (5): **43% di 1000 L con 0,8 = 344 L, non 430**; `toPercentage` e' l'inverso; il
gasolio con 1,0 usa la capacita' intera; con l'unita' `percent` e' l'identita'; senza capacita'
lancia invece di inventare. Chili (4): kg e quintali senza peso; 12 sacchi da 15 kg = 180 kg;
contenitore senza peso, litri e percentuale non si convertono; gli steri non si convertono
nemmeno con un peso. Ricalcolo (5): cambiando capacita' o frazione la misura in percentuale si
ricalcola dal 43%; una misura assoluta resta com'e'; **se la fonte perde la capacita' la misura
resta invariata**; `recomputeAll` mantiene l'ordine.

### `reorder_plan_test.dart` (11)

Piano (7): riordino il 24 alle 10:00 e superamento il 27 alle 10:00 con i loro valori; **ora
locale, non UTC**; stima `insufficient` → nessuna notifica; un avviso gia' passato non si
pianifica, quello futuro si'; alle 10:00 in punto del giorno di riordino l'avviso e' gia'
passato; misurato dopo la data di riordino → niente superamento; ora e giorni di superamento
configurabili. Id (4): `id × 10 + 1/2`; fonti diverse non collidono; ripianificare da' gli stessi
id; **oltre 32 bit si lancia** invece di traboccare.

### `history_page_test.dart` (8, repository finto)

Funzioni (3): `refillDates` solo le date in salita; `niceCeiling` primo valore tondo, mai zero;
`historyStart` 90 giorni oggi compreso nel gratuito, null col Pro. Pagina (5): **gratuito**:
ultimi 90 giorni, grafici bloccati col badge, le misure di marzo nascoste, **il delta della prima
visibile si calcola con la precedente nascosta** ("+60 sacchi · rifornimento"), invito con "2
misurazioni piu' vecchie"; **Pro**: StockChart e RateChart, tutto lo storico raggruppato per mese;
Pro con una misura sola → spiegazione invece dei grafici; eliminare col cestino e annullare (la
misura torna con `upsertMeasurement`, `absolute`); eliminare scorrendo.

### `purchases_page_test.dart` (7, repository finto; sta in `test/features/history/`)

`parseEuroCents` virgola o punto e arrotondamento; vuoto/testo/negativo → null; `formatEuro`
secondo la lingua. Pagina: testata con "SPESA INVERNO 2026/27", prezzo medio 5,12 (ponderato su
120 sacchi con costo), quantita' dell'inverno, "1 acquisto senza costo non e' conteggiato",
inverno precedente; aggiungere un acquisto **con il fornitore dell'ultima volta** (data di oggi,
costo 5250 centesimi); un costo non valido blocca il salvataggio; eliminare dal foglio e
annullare (l'acquisto torna con costo e fornitore).

### `backup_csv_test.dart` (7)

Backup (5): "sostituisci tutto" riporta fonti, misure in percentuale col `rawInput` e acquisti
(payload passato da JSON come nel file vero); **la percentuale si ricalcola dal `rawInput` anche
se il file porta un'altra quantita'**; "aggiungi" salta le fonti omonime e mette le nuove in
fondo; un combustibile sconosciuto fallisce come Exception **e non scrive niente**; un campo del
tipo sbagliato diventa FormatException, non TypeError. CSV (2): BOM, `;`, colonna Tipo, lettura %
solo per le misure in percentuale; `csvDecimal` con virgola, senza migliaia e zeri inutili.

### `calendar_sync_test.dart` (8, `_FakeGateway` con gli eventi in una mappa)

Calendari col principale per primo; permesso negato o nessun calendario → errori col loro
codice e nessun evento; crea l'evento di un giorno e ricorda la data scritta; **aggiornare sposta
lo stesso evento senza duplicarlo**; **un evento cancellato a mano si ricrea**; `forgetSource`
toglie evento e promemoria **anche se l'evento era gia' sparito**; `forgetAll` toglie gli eventi
di tutte le fonti; la proposta di aggiornamento parte **oltre i 3 giorni, in entrambe le
direzioni**.

### `scorte_scheduler_test.dart` (8, `_FakeNotifications`, mercoledi' 7/10/2026 a mezzogiorno)

Senza Pro nessuna notifica e quelle pianificate si cancellano; **con Pro ma interruttore mai
toccato (il default) nessuna notifica**; con Pro e interruttore acceso riordino il 13/10 e
superamento il 16/10 alle 10:00, id `id×10+1/2`, testi italiani esatti ("Ti restano circa 14
sacchi"), canale `scorte_reorder`, payload home, `exact` falso, `lastRescheduleAt` salvato; i
testi seguono la lingua dello scheduler (inglese); stima insufficiente → piano vuoto consegnato
(non `cancelAll`); un rifornimento ripianifica con **date nuove e stessi id**; misurata dopo la
data di riordino → niente superamento; una fonte disattivata o eliminata non lascia notifiche
orfane.

### `scorte_widget_test.dart` (4)

Una stima pronta porta esaurimento, riordino e data breve **(date, non giorni)**; senza stima
le date restano vuote ma i campi sono quattro; un a capo nel nome non spezza le righe; il
modello dei giorni ha il segnaposto e la parola dell'app, diversa fra it e en.

### Impianto

`test/features/history/fake_repo.dart`: `class FakeScorteRepository extends ScorteRepository`
(liste in memoria, stream broadcast; costruito su un `AppDatabase.memory()` mai usato),
costante `stufa`, `misura(int id, String iso, double q)`, e
`Future<FakeScorteRepository> pumpPage(WidgetTester tester, Widget page, {required bool pro, List<StockMeasurement>? misure, List<Purchase>? acquisti, CivilDate? today})`
— monta la pagina in italiano con oggi = 8/10/2026 e il gate scelto.

⚑ **Niente database vero nei widget test**: `testWidgets` gira in FakeAsync, che congela l'I/O
di SQLite, e gli stream non arrivano mai (lezione di TrashCan). Che le scritture vere
funzionino lo dimostra il test del repository.
⚑ **Niente golden**: i caratteri cambiano fra Windows e Mac. L'aspetto lo verificano gli scatti
sull'emulatore e l'anteprima del widget iOS.

---

## 13. Trappole gia' disinnescate e regole

Ognuna e' costata tempo almeno una volta (qui o in un'app precedente). Sono qui perche' il
sintomo non nomina mai la causa.

| Sintomo | Causa | Dove |
|---|---|---|
| La scorta di GPL e' sovrastimata di un quarto | il manometro moltiplicato per la capacita' nominale | `usable_fraction` 0,80, `QuantityConverter.fromPercentage` sulla capacita' **utile** |
| Divisione per zero nella stima | due misure nella stessa data | `UNIQUE(fuel_source_id, date)` + `normalize` (vince l'ultima) |
| "∞ giorni" | misure tutte uguali, velocita' 0 | `insufficient` con `dailyRate` null |
| Il widget non scende mai e il riordino slitta ogni giorno | esaurimento contato da oggi | contato dall'**ultima misura** |
| Dopo aver cambiato la capienza le vecchie letture sono sbagliate | quantita' calcolata una volta sola | `entered_as` + `raw_input`, `recomputeMeasurements` in `updateSource` |
| Un campo capienza svuotato un momento azzera mesi di dati | ricalcolo senza capacita' | `recompute` lascia la misura invariata |
| Cancello una fonte e restano misure orfane nel CSV | SQLite tiene `foreign_keys` spento | `PRAGMA foreign_keys = ON` in `beforeOpen` |
| "unable to open database file" solo su telefono | cartella temporanea non scrivibile | `sqlite3.tempDirectory` |
| Una chiave nuova del dominio rifiutata solo in produzione | CHECK con una lista copiata | CHECK costruiti da `fuelTypeKeys`/`fuelUnitKeys`/`enteredAsKeys` |
| "12 litri" per 12 sacchi | ripiego silenzioso su un'altra unita' | `FuelUnits.byKey` e `fuelTypeEnum` lanciano |
| "1 bags" | singolare scelto sul valore grezzo 0,98 | `formatAmount` sceglie sul numero arrotondato |
| Evento orfano nel calendario dopo aver eliminato una fonte | la cascade toglie la riga, non l'evento | `forgetSource` prima di `deleteSource` |
| Evento orfano dopo un ripristino "sostituisci tutto" | idem | promemoria letti prima di `restore`, eventi tolti dopo, solo se riesce |
| Il backup sposta o cancella l'evento di un altro calendario | id di eventi validi solo sul telefono d'origine | promemoria esclusi dal backup |
| "Aggiorna evento" fallisce dopo che l'utente l'ha cancellato | evento sparito | `CalendarEventMissing` → si ricrea |
| Nessun calendario sull'emulatore | emulatore senza account Google | calendario locale via `adb shell content insert` (§8) |
| L'evento non si ritrova su iOS 17 | permesso di sola scrittura | accesso completo + NSCalendarsFullAccessUsageDescription |
| Un file di backup rovinato fa crashare l'app | TypeError da un cast, `restore` intercetta solo Exception | `importPayload` converte in FormatException |
| "1,200" litri letti 1,2 da Excel | numeri formattati con le migliaia inglesi | `csvDecimal` |
| Dopo un rimborso le notifiche continuano | il Pro si controllava solo nella UI | `ScorteScheduler.allowed` |
| L'interruttore e' acceso senza permesso; il primo tocco lo spegne | default acceso copiato da TrashCan | `NotificationsEnabled` default **false** |
| L'interruttore resta acceso con il permesso negato | stato salvato prima del permesso | `_setNotifications` esce senza salvare |
| La notifica non arriva mai, nessun errore | mancano i receiver di flutter_local_notifications | manifest |
| Chi aveva silenziato le notifiche le risente col suono | id del canale cambiato | `scorte_reorder`, mai cambiarlo |
| Notifiche duplicate a ogni ripianificazione | id non stabili | `sourceId × 10 + slot` |
| Due fonti con la stessa notifica | id oltre 32 bit | `maxSourceId`, la fonte si salta |
| Icona della barra di stato = macchia bianca | Android usa solo l'alfa | `drawable/ic_notification.xml` |
| Tocco la notifica: la home due volte nella pila | `push` del payload "/" dopo `go("/")` | `_openPayload` controlla il payload |
| Ogni verifica d'acquisto rifiutata come "app sconosciuta" | `appId` col trattino basso mandato al server | `licenseAppId` |
| Una release regala il Pro | billing finto in release | `assertUsableInRelease` |
| L'app non si accorge di un acquisto gia' fatto | bootstrap dimenticato | `EntitlementNotifier.build` lo avvia |
| Una pagina Pro aperta da un link si vede gratis | Pro controllato solo all'ingresso | `ProGate` sulla rotta |
| Pagina d'errore di go_router aprendo una pagina Pro | `redirect` su un `push` | niente redirect: `ProGate` |
| "A dismissed Dismissible widget is still part of the tree" | lo stream di Drift arriva dopo la cancellazione | righe tolte subito in `_gone` |
| Il widget resta ai giorni di ieri | manca HomeWidgetScheduledUpdateReceiver; Dart gira solo ad app aperta | receiver nel manifest; i giorni li calcola il widget (ADR-018) |
| Widget che non si disegna, senza errori | view non ammesse da RemoteViews | solo LinearLayout/TextView |
| "Scorte Calore continua a bloccarsi" | eccezione nel receiver del widget | `onUpdate` dentro `try` |
| Widget mezzo vuoto, "non ha caricato" | righe in `wrap_content` | peso 1 (Android), `maxHeight: .infinity` (iOS) |
| Campi del widget sfasati | un separatore che una tastiera produce, o un a capo nel nome | US `\u001F`; a capo → spazio |
| Il plugin non trova il provider del widget in debug | `androidName` senza package | `com.smp.scortecalore.ScorteCaloreWidgetProvider` |
| Widget iOS vuoto, nessun errore | App Group non registrato | registrare e agganciare il gruppo; testi in Ripiego |
| Fondo del widget iOS staccato dai bordi | margini di sistema da iOS 17 | `contentMarginsDisabled`, `containerBackground` |
| Tocco sul widget iOS ignorato o passato al router | il plugin riconosce i tocchi dal parametro `homeWidget` | `widgetURL(...?homeWidget)` |
| La pila perde la freccia indietro aprendo dal widget | deep link di Flutter acceso | spento in manifest e Info.plist |
| Un widget test resta appeso | FakeAsync congela l'I/O di SQLite | FakeScorteRepository |
| Generazione Drift: "contextFeatures isn't defined" | analyzer 14.5 | tetto `<14.4.0` |
| Build: "requires core library desugaring" | flutter_local_notifications su minSdk 24 | `isCoreLibraryDesugaringEnabled = true` |
| "Activity class does not exist" | plugin Kotlin mancante nel template | `id("org.jetbrains.kotlin.android")` |
| Icona iOS rifiutata a caricamento finito | canale alfa | fullbleed opaca + `remove_alpha_ios` |
| Due estensioni nel pacchetto, rifiutato da App Store Connect | script di Xcode rilanciato | `aggiungi_widget_ios.rb` idempotente |
| Testi dei permessi iOS che si sovrascrivono | `InfoPlist.strings` sciolti | gruppo di varianti (`aggiungi_infoplist_strings.rb`) |

### Regole non negoziabili

1. **Tutte le letture e scritture passano da `ScorteRepository`.** Le tre regole (unita' ammessa,
   percentuale ricalcolata, una misura al giorno) non hanno un vincolo SQL che le difenda.
2. **Le date delle misure e degli acquisti sono CivilDate/TEXT `YYYY-MM-DD`**, mai DateTime. Gli
   istanti sono ms UTC. Le notifiche si costruiscono in **ora locale** da CivilDate.
3. **Il dominio non contiene stringhe dell'app**: nomi e frasi dagli ARB (`labels.dart`,
   `ScorteScheduler.toScheduled`).
4. **Nessuna pagina scrive `if (isPro)`**: si passa da `featureGateProvider` e da
   `scorteFeatureLimits`. Il controllo delle notifiche sta anche nello scheduler.
5. **Ogni `locked()` ha il suo beneficio nel paywall e viceversa.**
6. **Le chiavi stabili non si rinominano**: `FuelType.key`, chiavi di `FuelUnits`,
   `EnteredAs.key`, chiavi del widget, preferenze, `scorteChannelId`, `ScorteBackupSource.id`.
7. **Le chiavi del widget cambiano in tre file insieme**: `scorte_widget.dart`,
   `ScorteCaloreWidgetProvider.kt`, `VistaScorte.swift`. Il gruppo iOS in quattro.
8. **Il payload del widget non contiene giorni**, solo date (ADR-018).
9. **I testi si cambiano in `tool/testi.py` / `tool/testi_*.py`**, mai negli ARB.
10. **Le icone si cambiano dall'originale con `tool/genera_icone.py`**.
11. **L'app propone, non sposta**: l'evento del calendario si modifica solo dopo un tocco.
12. **`forgetSource` prima di `deleteSource`; promemoria letti prima di "sostituisci tutto" ed eventi tolti dopo, solo a ripristino riuscito.**
13. **`applicationId`, bundle id, App Group, `proSku`, `licenseAppId` sono immutabili** dopo il
    primo upload; `android/key.properties` e il keystore non entrano mai nel repository.
14. **Mai `Platform.isX`**: `defaultTargetPlatform`.
15. **Una modifica allo schema** incrementa `schemaVersion`, aggiunge il passo in `onUpgrade`
    **e** il suo test (e i CHECK nuovi richiedono di ricreare la tabella).
16. **Dati di esempio solo con `--dart-define=SC_DEMO=true`, mai in release.**

---

## 14. Cosa NON esiste ancora, e debito aperto

### Non esiste (per non cercarlo invano)

- **Nessuna interfaccia per disattivare o riordinare le fonti**: `setSourceActive` e
  `reorderSources` esistono nel repository (e sono testati), ma nessuna schermata li chiama. Oggi
  una fonte si puo' solo eliminare; `active` e `sort_order` arrivano diversi dal default solo da
  un backup.
- **Nessun uso di `measurementsSince`, `purchaseById`, `QuantityConverter.toKilograms`,
  `toPercentage`, `recomputeAll`, `ReorderPlanner.idsFor`, `FuelSourceSpec.withDefaults`,
  `calculatedCivilDate`, `formatLiters`** fuori dai test: API pronte, non collegate.
- **Il peso dei sacchi non si mostra da nessuna parte**: si chiede nell'editor ma nessuna
  schermata usa `toKilograms`.
- **`cost_per_unit_cents` non entra in nessun calcolo**: costo medio e spesa vengono dagli
  acquisti.
- **Nessuna pagina per fonte** a cui portino notifiche o widget: aprono la home.
- **Nessun test della home, dell'editor della fonte, del foglio di aggiornamento,
  della barra del calendario, delle impostazioni**, **nessun app smoke test**, **nessun test
  d'integrazione** (`integration_test/` contiene solo i giri per screenshot e video), **nessun golden** (scelta), **nessun test di
  migrazione** (schema 1).
- **Nessuna prova su telefono vero**: acquisti, notifiche su iPhone, calendario su iPhone,
  tocco sul widget iOS.
- **Nessun App ID, App Group o prodotto Pro registrato sugli store**: vanno creati dal
  proprietario (portale Apple — col gruppo agganciato a ciascun App ID —, App Store Connect,
  Play Console con base 2,45 EUR). Finche' non ci sono il Pro non e' comprabile e il widget iOS
  firmato scrive in un contenitore nullo.
- **Nessuna build TestFlight / Play**, nessuna scheda store, nessuno screenshot.
- **Nessuna grafica definitiva** oltre l'interfaccia essenziale «A · Brace» (F5.0 punto 6, da
  fare con il proprietario).
- **Nessun redirect Pro in go_router**, di proposito.

### Debito tecnico

| Voce | Perche' e' rimandato | Quando va affrontato |
|---|---|---|
| **`EntitlementView`/`EntitlementNotifier` copiati per la terza volta** (TrashCan, Full Freezer, Scorte Calore) | il commento di `entitlement.dart` diceva di spostarli in `micro_core` **alla terza app**, cioe' questa, e non e' stato fatto | prima di F6: altrimenti la prossima correzione al flusso d'acquisto va fatta tre volte |
| **`ProGate` copiato da Full Freezer** | due copie | insieme all'entitlement, in `micro_core` |
| **Permesso INTERNET assente dal manifest principale** | finora il License Server non e' configurato nelle build (MA_LICENSE_URL vuoto) | prima di una release con il server licenze: verificare il manifest unito della release e, se manca, dichiararlo |
| **Acquisti estivi fuori da ogni spesa stagionale** | e' la definizione del piano, ma va confermata | DA CONFERMARE col proprietario |
| **Disattivazione e riordino delle fonti senza UI** | non richiesti dall'interfaccia essenziale | con le grafiche definitive |
| **App ID, App Group, prodotto Pro da registrare** | richiedono gli account del proprietario | prima della prima build firmata |
| **Prove su iPhone** (calendario, notifiche, tocco del widget) | serve un dispositivo (il proprietario prova su iPad) | prima di TestFlight |
| **Copia del codice sul Mac non-git** | sincronizzazione a mano con tar | se il lavoro iOS diventa frequente |

### Differenze consapevoli dal piano (`develop_microapps.md` F5)

Il codice ha la precedenza; il piano e' la storia delle intenzioni.

| Il piano diceva | Il codice fa | Perche' |
|---|---|---|
| `device_calendar` | `device_calendar_plus` 0.10.1 | `device_calendar` fermo al 2024, senza l'accesso completo di iOS 17 (2026-10-08) |
| `upsertReorderEvent` senza testi | con `ReorderEventTexts` gia' tradotti, e c'e' `forgetSource`/`forgetAll` | i testi si traducono nella UI; niente eventi orfani |
| "propone l'aggiornamento con una notifica in-app" | la frase e il pulsante "Aggiorna evento" nella testata | la proposta sta dove si guarda la data |
| `availableCalendars` → `Result<List<Calendar>>` | `Result<List<CalendarChoice>>` | il tipo del plugin non entra nell'app |
| `depletionDate = oggi + daysRemaining` | `ultimaMisura + floor(current / rate)` | altrimenti senza misure nuove la data slitta e il widget non scende |
| wizard a otto passi (F5.5) | una pagina sola | i campi sono pochi e quasi tutti gia' giusti |
| `FuelUnit.label`, `shortLabel`, `QuantityConverter.format` | non ci sono | niente stringhe nel dominio |
| `fl_chart` | grafici con CustomPainter | un pacchetto in meno |
| anello MicroProgressRing in dashboard | barra lineare nella testata «A · Brace» | grafica scelta dal proprietario |
| colore `#C4622D`, font Sora | `#F4511E`, Plus Jakarta Sans | colori dall'icona; font confermato con «A · Brace» |
| `calendar_reminders` senza `calendar_id` | con `calendar_id` | senza, l'evento non si aggiorna ne' si cancella |
| `purchases.total_cost_cents` obbligatorio | nullable | legna regalata, scontrino perso |
| `fuel_sources` senza `sort_order` | con `sort_order` | coerenza con Full Freezer |
| notifiche non citate fra i limiti | `notifications` **locked** | decisione del proprietario (F5.0 punto 2) |

### Incoerenze notate nel codice (non corrette: da sistemare alla prossima occasione)

Il 2026-10-08, dopo la stesura, sono state **corrette**: test del paywall mancante, commenti
superati (`device_calendar`, font, chiavi ARB, anello, "nessuna pagina per fonte",
`deleteEvent` "che non esiste"), la riga del widget Kotlin con la data breve vuota (ora come
Swift), e il ripristino che toglieva gli eventi prima di sapere se riusciva. Restano:

- `entitlement.dart`: il commento del debito ("alla terza app (Scorte Calore) vanno spostati in
  micro_core") e' scaduto: questa **e'** la terza app.
- `MainActivity.kt`: il commento parla dell'app che "si apriva sulla home invece che sulla pagina
  giusta", ma qui il widget apre l'app con l'intent di avvio e Dart non ascolta i tocchi del widget.
- `Routes.scheme` ("deep link che arrivano dalle notifiche e dal widget") non e' letto da nessun
  codice: le notifiche usano un payload, il widget l'intent di avvio o un URL che il plugin assorbe.
- `PurchasesPage._SeasonPanel`: il commento dice "gli euro interi in grande", ma i centesimi si
  mostrano quando la cifra non e' tonda.
- `ScorteRepository.addSource`: `sortOrder` = numero di fonti esistenti; dopo un'eliminazione due
  fonti possono avere lo stesso `sort_order` (l'ordine ripiega sull'id, quindi non si vede).
- 10 chiavi l10n non usate dal codice: `common_ok`, `common_next`, `common_back`,
  `home_remaining`, `home_rate`, `home_reorderPast`, `home_lastUpdate`, `home_lastUpdateShort`,
  `settings_purchase`, `settings_appearance`.

# codebase_reference.md — Film Tracker

> Atlante dell'app **Film Tracker**: il diario dei rullini analogici. Ogni rullino ("#17") e'
> una scheda cronologica (caricato → terminato → consegnato → sviluppato → stampato) con le
> sue foto; la home e' divisa in **In macchina**, **In laboratorio** e **Archivio** (un foglio
> provini). **Obiettivo**: capire il codice, trovare cio' che serve e modificarlo **senza
> aprire i file**.
>
> **Aggiornato al**: 2026-10-08 · **Fase**: F6.0–F6.14 concluse, questo atlante e' F6.15 (resta
> F6.16, il rituale) · **Ramo git al momento della scrittura**: `v7.6.1`, allineato al commit
> `5dce3bc` · **versionName+Code**: `1.0.0+1`
> **Package Android / bundle iOS**: `com.smp.filmtracker` (immutabile dopo il primo upload)
> **SKU Pro**: `filmtracker_pro_lifetime` — **4,99 €** una tantum (Play: base **4,09 EUR senza IVA**)
> **Id per il License Server**: `licenseAppId = 'filmtracker'` (senza trattino basso, ≠ `appId`)
> **Grafica**: «C · Provino», scelta dal proprietario il 2026-10-08
> (https://claude.ai/artifact/14GrAPyvYN2bdcov5PKVoP): fondo quasi nero, tutto impaginato come
> pellicola, scritte a bordo in arancio `#F0A33B` monospaziato **Space Mono**, corpo in Plus
> Jakarta Sans. **Tema scuro di default.**
>
> Quello che l'app prende da `micro_core` (configurazione, preferenze, acquisti, paywall,
> backup, CSV, immagini, date civili, Money, componenti di interfaccia) **non e' ricopiato
> qui**: si rimanda a `packages/micro_core/codebase_reference.md`. I nomi dei tipi di
> `micro_core`, Flutter, Drift, dei plugin e delle classi generate da Drift (righe e companion)
> compaiono qui in testo semplice o dentro le firme, mai da soli fra apici inversi: cosi'
> `tool/verify_atlas.ps1` segnala solo i nomi **di quest'app** che non esistono piu'.
>
> Stato: l'app gira su Android (emulatore; QR provato con adb) e su iOS (simulatore iPhone,
> 2026-10-08). **185 test verdi** propri, oltre a quelli di `micro_core`.
>
> Convenzioni dei simboli: ⚑ = scelta non ovvia, con il suo perche'. ☠ = trappola gia' pagata.

---

## 0. Le decisioni che reggono tutto (F6.0, 2026-10-08)

Prese con il proprietario prima di scrivere codice (`develop_microapps.md` §8 F6.0, registro
`memory/decisioni.md`, voci "Film Tracker: decisioni di partenza" e "Film Tracker: interfaccia
C · Provino"). **Dove contraddicono il resto del piano F6, vincono queste.**

| # | Decisione | Dove si vede nel codice | Perche' |
|---|---|---|---|
| 1 | Android e iPhone dal primo commit, bundle `com.smp.filmtracker`, **solo iPhone** (`TARGETED_DEVICE_FAMILY = 1`) | `build.gradle.kts`, `project.pbxproj` | come Full Freezer e Scorte Calore |
| 2 | **Pro a 4,99 €** (non 6,99 € del piano). Play: base 4,09 EUR **senza IVA** per avere 4,99 € in Italia | `purchaseGatewayProvider` (prezzo del gateway finto), `buildFilmPaywall` | decisione del proprietario |
| 3 | **Foto tutte gratis** (copertina, provini, stampe, galleria, zoom): `FeatureKey.photos` → `open()` | `filmFeatureLimits` | ⚑ l'archivio con le anteprime e' l'identita' dell'app: chiuderlo dietro il Pro renderebbe brutta proprio la versione che deve far conoscere l'app |
| 3b | Il Pro si regge su: **macchine multiple** (una gratis), statistiche e costi, PDF annuale, CSV, backup completo | `filmFeatureLimits`, paywall | |
| 4 | **Nessun widget**: niente home_widget, nessuna estensione iOS, nessun App Group | (assenza) | confermato dal proprietario |
| 5 | Icona del proprietario, ripulita da `tool/genera_icone.py` | §2bis | |
| 6 | **Tema scuro di default**; prima un'interfaccia essenziale, poi la grafica scelta fra tre (**C · Provino**) | `ThemeModeNotifier`, `FilmPalette`, `film_strip.dart` | le foto su fondo chiaro perdono contrasto (F6.1) |
| 7 | Trappole gia' pagate: `licenseAppId` senza trattino basso, deep link di Flutter **spento** (il QR passa da `app_links`), `ProGate` sulle pagine Pro, virgolette tipografiche | §6, §7, §13 | |

---

## 1. Dove sta cosa

| Cerchi… | Vai in… |
|---|---|
| L'avvio dell'app (config, cartelle, log, preferenze, conteggio avvii, dati demo) | `lib/main.dart` |
| Il router, il tema, il ciclo di vita, i link del QR in ingresso | `lib/app/app.dart` |
| I percorsi di navigazione (e lo schema `filmtracker`) | `lib/app/routes.dart` |
| Id app, SKU, colore seme, font, `licenseAppId` | `lib/app/app_config.dart` |
| I provider radice: config, database, repository, stream per la UI, statistiche, tema | `lib/app/providers.dart` |
| Il Pro: gateway, entitlement, `featureGateProvider`, `appVersion` | `lib/app/entitlement.dart` |
| Cosa e' gratis e cosa e' Pro | `lib/app/feature_limits.dart` |
| I testi e i benefici del paywall, `showFilmPaywall` | `lib/app/paywall_config.dart` |
| I colori «C · Provino» e il tema Material vestito da pellicola | `lib/app/film_palette.dart` |
| Nomi visibili di stati, formati, processi; date e importi formattati | `lib/app/labels.dart` |
| Italiano sui telefoni italiani, inglese altrove | `lib/app/locale_resolution.dart` |
| Le tabelle del database | `lib/data/tables.dart` |
| Apertura del database, `PRAGMA foreign_keys`, seed del catalogo, conversioni riga → dominio | `lib/data/database.dart` |
| **Tutte** le letture e scritture sul database | `lib/data/film_repository.dart` |
| I dati di esempio (FT_DEMO) | `lib/dev/demo_data.dart` |
| Le foto disegnate dei dati di esempio | `lib/dev/demo_photos.dart` |
| Formati, processi, tipi d'immagine (chiavi stabili) | `lib/domain/film_types.dart` |
| **La macchina a stati del rullino**, le tre sezioni della home | `lib/domain/roll_status.dart` |
| Le 25 pellicole precaricate | `lib/domain/film_catalog.dart` |
| Le statistiche per anno (puro) | `lib/domain/film_stats.dart` |
| Il CSV dei rullini | `lib/services/csv_export.dart` |
| Backup e ripristino **con le foto** (formato) | `lib/services/film_backup_source.dart` |
| Il PDF di riepilogo annuale | `lib/services/year_report.dart` |
| La home «C · Provino» a tre sezioni | `lib/features/home/home_page.dart` |
| Perforazioni, striscia di pellicola, scritta a bordo, etichetta di sezione | `lib/features/common/film_strip.dart` |
| Il lucchetto delle pagine Pro aperte senza Pro (`ProGate`) | `lib/features/common/pro_gate.dart` |
| Creazione e modifica di un rullino, scelta pellicola e macchina | `lib/features/rolls/roll_editor_page.dart` |
| Il dettaglio del rullino: timeline, azioni, suggerimento di stato, eliminazione | `lib/features/rolls/roll_detail_page.dart` |
| La copertina e la striscia segnaposto disegnata | `lib/features/rolls/roll_cover.dart` |
| Lo sviluppo (uno per rullino) | `lib/features/lab/development_page.dart` |
| Gli ordini di stampa (N per rullino) | `lib/features/lab/print_page.dart` |
| Campi comuni di laboratorio (costi, date, suggerimenti), stato suggerito applicato | `lib/features/lab/lab_fields.dart` |
| Le macchine fotografiche e il limite di una gratis | `lib/features/cameras/cameras_page.dart`, `camera_editor_page.dart` |
| Il catalogo delle pellicole e quelle personalizzate | `lib/features/stocks/stocks_page.dart`, `custom_stock_sheet.dart` |
| Le foto di un rullino (griglia, aggiungi, riordina, copertina) | `lib/features/photos/roll_photos_section.dart` |
| Import delle foto in isolate con annulla, eliminazione, copertina | `lib/features/photos/photo_actions.dart` |
| Logica pura delle foto (riordino, copertina dopo un'eliminazione, byte leggibili) | `lib/features/photos/photo_logic.dart` |
| Il visualizzatore a schermo intero con zoom | `lib/features/photos/photo_viewer_page.dart` |
| ImageStore dell'app, cartella `rolls`, miniatura che non si rompe mai | `lib/features/photos/image_store_provider.dart` |
| Spazio delle foto e "Libera spazio" | `lib/features/photos/photo_storage_tile.dart` |
| L'etichetta QR del rullino | `lib/features/qr/qr_page.dart` |
| Il link `filmtracker://roll/<n>`: scrittura, lettura, ascolto | `lib/features/qr/qr_links.dart` |
| Le statistiche (Pro) e il grafico mensile | `lib/features/stats/stats_page.dart` |
| Le impostazioni | `lib/features/settings/settings_page.dart` |
| Statistiche, PDF, CSV, backup, ripristino (azioni dalle impostazioni) | `lib/features/settings/data_section.dart` |
| Deep link spento, schema `filmtracker` (Android) | `android/app/src/main/AndroidManifest.xml` |
| `onNewIntent` → `setIntent` | `android/app/src/main/kotlin/com/smp/filmtracker/MainActivity.kt` |
| Schema URL, deep link spento, permessi fotocamera e foto (iOS) | `ios/Runner/Info.plist` (+ `ios/Runner/{en,it}.lproj/InfoPlist.strings`) |
| Le stringhe tradotte | **`tool/testi.py` + `tool/testi_*.py`** (sorgente unica) → `lib/l10n/app_en.arb`, `app_it.arb` |
| L'icona e la splash | `tool/genera_icone.py` + `flutter_launcher_icons.yaml`, `flutter_native_splash.yaml` (§2bis) |
| I caratteri e le loro licenze | `assets/fonts/` (Plus Jakarta Sans variabile, Space Mono, `OFL-*.txt`) |

---

## 2. Albero dei file

Solo il codice scritto da noi (esclusi `lib/l10n/generated/`, `lib/data/database.g.dart`,
i file generati da Flutter/Xcode/Gradle e le immagini).

```
apps/film_tracker/
├── lib/
│   ├── main.dart                         avvio: config, cartelle, log, preferenze, avvii, demo. Niente database (tranne la demo).
│   ├── app/
│   │   ├── app.dart                      buildRouter, FilmTrackerApp: router, tema «C · Provino», resume, link del QR (app_links)
│   │   ├── app_config.dart               licenseAppId, buildFilmConfig(): id, nome, SKU, seme #E0A458, font, scuro
│   │   ├── entitlement.dart              Pro: appVersion, gateway, EntitlementView/Notifier, isPro, featureGateProvider
│   │   ├── feature_limits.dart           filmFeatureLimits (ADR-017; F6.0 punto 3)
│   │   ├── film_palette.dart             kEdgeFont, FilmPalette (ThemeExtension), withFilmLook (cambia anche il ColorScheme)
│   │   ├── labels.dart                   statusName, formatName, processName, formatDay, formatMonth, formatPeriod, formatCents
│   │   ├── locale_resolution.dart        kSupportedLocales, resolveAppLocale
│   │   ├── paywall_config.dart           buildFilmPaywall, showFilmPaywall
│   │   ├── providers.dart                provider radice, ThemeModeNotifier, stream per la UI, statistiche
│   │   └── routes.dart                   Routes: percorsi in costanti, helper, scheme
│   ├── data/
│   │   ├── tables.dart                   6 tabelle Drift + filmFormatKeys/filmProcessKeys/rollStatusKeys/rollImageKindKeys
│   │   ├── database.dart                 AppDatabase (schema 1, seed del catalogo) + 6 estensioni riga → dominio
│   │   ├── database.g.dart               GENERATO da drift_dev
│   │   └── film_repository.dart          FilmRepository (la sola porta), RollListItem, DuplicateFilmStockException, RollTransitionException
│   ├── dev/                              solo con --dart-define=FT_DEMO=true, mai in release
│   │   ├── demo_data.dart                demoRequested, demoEnabled, seedDemoData (3 macchine, 12 rullini)
│   │   └── demo_photos.dart              seedDemoPhotos, demoLandscape (paesaggi disegnati, B/N per le pellicole BW)
│   ├── domain/                           Dart puro: niente Flutter, niente Drift, niente stringhe dell'app
│   │   ├── film_types.dart               FilmFormat, FilmProcess, RollImageKind
│   │   ├── roll_status.dart              RollStatus, RollSection, LabEvent, RollStatusMachine
│   │   ├── film_catalog.dart             CatalogStock, kFilmCatalog (25 emulsioni)
│   │   └── film_stats.dart               StatsDevelopment, StatsPrint, StatsRoll, RankedName, YearStats, FilmStatsCalculator
│   ├── services/
│   │   ├── csv_export.dart               exportRollsCsv, buildRollsCsv (una riga per rullino)
│   │   ├── film_backup_source.dart       FilmBackupSource (BackupSource di micro_core, con le foto)
│   │   └── year_report.dart              YearReportRoll, reportDateOf, rollsOfYear, loadReportFont, buildYearReportDocument, buildYearReport
│   ├── features/
│   │   ├── cameras/cameras_page.dart             CamerasPage, openNewCamera
│   │   ├── cameras/camera_editor_page.dart       NewCameraGate, CameraEditorPage
│   │   ├── common/film_strip.dart                SprocketRow, FilmStrip, EdgeText, SectionLabel
│   │   ├── common/pro_gate.dart                  ProGate
│   │   ├── home/home_page.dart                   HomePage, waitingDays, edgeLabelOf
│   │   ├── lab/lab_fields.dart                   parseCostCents, isCostTextValid, costCentsToText, formatCostCents, CostField, LabDateTile, SuggestionTextField, applySuggestedStatus, labSavedMessage
│   │   ├── lab/development_page.dart             DevelopmentPage
│   │   ├── lab/print_page.dart                   PrintPage
│   │   ├── photos/image_store_provider.dart      imageStoreProvider, rollImageBucket, rollImageFile, RollImageThumb
│   │   ├── photos/photo_actions.dart             imagePickerProvider, importRollPhotos, PhotoPick, showPhotoSourceSheet, rollImageKindLabel, addRollPhotos, confirmAndDeleteRollPhoto, setRollCover
│   │   ├── photos/photo_logic.dart               reorderIds, coverAfterDelete, formatBytes, ImportProgress, ImportOutcome, ImportCancellation
│   │   ├── photos/photo_storage_tile.dart        photoStorageBytesProvider, PhotoStorageTile
│   │   ├── photos/photo_viewer_page.dart         PhotoViewerPage
│   │   ├── photos/roll_photos_section.dart       RollPhotosSection, rollImageHeroTag
│   │   ├── qr/qr_links.dart                      rollQrData, sequenceFromUri, locationForRollLink, listenRollLinks
│   │   ├── qr/qr_page.dart                       QrPage, RollQrLabel
│   │   ├── rolls/roll_cover.dart                 RollCover, FilmStripPlaceholder
│   │   ├── rolls/roll_detail_page.dart           RollDetailPage
│   │   ├── rolls/roll_editor_page.dart           RollEditorPage
│   │   ├── settings/data_section.dart            backupServiceProvider, DataSection, openStats, createYearReport, exportCsv, createBackup, restoreBackup
│   │   ├── settings/settings_page.dart           SettingsPage
│   │   ├── stats/stats_page.dart                 StatsPage, MonthlyRollsChart, MonthlyBarsPainter
│   │   ├── stocks/custom_stock_sheet.dart        showCustomStockSheet, showEditCustomStockSheet
│   │   └── stocks/stocks_page.dart               StocksPage
│   └── l10n/
│       ├── app_en.arb, app_it.arb        GENERATI da tool/testi.py (template: inglese) — 361 chiavi
│       └── generated/                    GENERATO da gen-l10n (classe L)
├── test/                                 §12 — 185 test
│   ├── data/film_repository_test.dart
│   ├── domain/{film_catalog,film_stats,roll_status}_test.dart
│   ├── features/laboratorio/{fake_film_repo.dart,cameras_page_test,development_page_test,stocks_page_test}.dart
│   ├── features/photos/{fake_photo_repo.dart,photo_import_test,photo_logic_test,roll_photos_section_test}.dart
│   ├── features/qr/{qr_links_test,qr_page_test}.dart
│   ├── features/rolls/{fake_roll_repo.dart,home_page_test,roll_detail_page_test}.dart
│   ├── features/stats/stats_page_test.dart
│   ├── services/{csv_export,film_backup_source,year_report}_test.dart
│   └── widget/paywall_config_test.dart
├── integration_test/                     NON test di regressione: giri per lo store (sul Mac, con FT_DEMO)
│   ├── screenshots_test.dart             stampa SCATTO:<nome>, lo scatto lo fa tool/screenshots_ios.sh
│   └── anteprima_test.dart               il giro del video, fra REGISTRA e FINE (tool/anteprima_app_store.sh)
├── store/                                scheda e grafiche dello store
│   ├── scheda-app-store.md               testi it/en contati, cosa va dove (API o a mano), come si rifa' tutto
│   ├── screenshots/ios/<lingua>/         screenshot veri dal simulatore (anche paywall-revisione.png)
│   ├── grafiche/                         appstore (6,9"), appstore-6.5, play, apple (intestazione, ricerca), testata Play
│   └── video/anteprima-886x1920-<lingua>.mp4   anteprima App Store (il .mov grezzo e' ignorato da git)
├── tool/
│   ├── testi.py                          sorgente dei testi (TESTI comuni: appTitle, common, paywall, pro, settings, theme) → ARB
│   ├── testi_{dati,foto,laboratorio,rullini}.py   testi per parte dell'app, caricati da testi.py
│   ├── genera_icone.py                   icone e splash dall'originale del proprietario
│   ├── genera_grafiche_store.py          schede screenshot, testata Play, intestazione e ricerca Apple (stile C · Provino)
│   ├── anteprima_app_store.sh            registra il video sul simulatore (Mac)
│   ├── converti_anteprima.ps1            .mov → mp4 886x1920 30 fps con audio muto (PC, ffmpeg)
│   └── scheda_app_store.py               carica scheda, video e prodotto Pro su App Store Connect (Mac)
├── assets/
│   ├── fonts/                            PlusJakartaSans-Variable.ttf, SpaceMono-{Regular,Bold}.ttf, OFL-PlusJakartaSans.txt, OFL-SpaceMono.txt
│   └── icons/                            generate da genera_icone.py; source/filmtracker_originale.png, source/anteprime/
├── android/app/
│   ├── build.gradle.kts                  applicationId, minSdk 24, firma da key.properties (PKCS12), desugaring, minify
│   └── src/main/
│       ├── AndroidManifest.xml           BILLING, deep link spento, intent-filter filmtracker://roll
│       └── kotlin/com/smp/filmtracker/MainActivity.kt   onNewIntent → setIntent
├── ios/Runner/
│   ├── Info.plist                        schema filmtracker, deep link spento, permessi fotocamera/foto (inglese)
│   ├── {en,it}.lproj/InfoPlist.strings   testi dei permessi it/en (gruppo di varianti nel progetto)
│   ├── AppDelegate.swift, SceneDelegate.swift   quelli di flutter create (nessuna modifica)
├── flutter_launcher_icons.yaml, flutter_native_splash.yaml, l10n.yaml, pubspec.yaml, analysis_options.yaml
└── README.md                             cos'e' l'app, gratis e Pro, comandi, identita'
```

**Non esistono** (per non cercarle): test d'integrazione di regressione (`integration_test/` ha
solo i giri per lo store), estensioni iOS, codice Kotlin oltre `MainActivity.kt`, Podfile (Flutter
usa Swift Package Manager).

### Lo store (2026-10-08)

App Store: app `6820633385`, inviata alla revisione il 2026-10-08 con
`filmtracker_pro_lifetime` (4,99 €). Tutto quello che serve per rifare scheda, screenshot, video
e grafiche sta in `store/scheda-app-store.md`. Tre cose da ricordare:

- ☠ **Nome inglese «Film Tracker – Roll Diary»**: «Film Tracker» in inglese e' di un altro
  sviluppatore (409 DUPLICATE.DIFFERENT_ACCOUNT, come per Full Freezer). Sotto l'icona resta
  «Film Tracker».
- ☠ **Space Mono non ha il glifo «▸»**: nell'app Flutter ripiega su un altro carattere, Pillow no
  (quadratino). `genera_grafiche_store.py` lo disegna come triangolino (`riga_a_bordo`).
- ☠ **Niente `Runner.entitlements`** (nessun App Group): `tool/build_ios.sh` firma l'archivio
  senza diritti se il file manca (prima si fermava con "cannot read entitlement data").

---

## 2bis. Icona e schermata di avvio

Sorgente: `assets/icons/source/filmtracker_originale.png` (1254x1254, RGB), l'icona del
proprietario: un **quadrato arrotondato** (raggio ~24%) con un **gradiente grigio-azzurro
chiaro**, il rullino, la striscia di pellicola e il bollino della lista, posato su un fondo
**blu notte `#192634`**, con un bordo lucido sottile (10-15 px).

`python apps/film_tracker/tool/genera_icone.py` (numpy, Pillow, scipy) produce in `assets/icons/`:

| File | Uso |
|---|---|
| `filmtracker_fullbleed.png` | 1024: il quadrato **rifilato di 34 px per lato**, angoli riempiti: icona iOS, icona Play 512, legacy Android |
| `filmtracker_logo.png` | il quadrato arrotondato con gli angoli trasparenti (sito, schede, splash) |
| `adaptive_background.png` | Android 8+: **l'icona intera** nei 700 px centrali della tela da 1080, bordi prolungati e sfumati |
| `adaptive_foreground.png` | Android 8+: **trasparente** (tutto sta nello sfondo) |
| `splash_logo.png` | splash (Android fino a 11 e iOS), 1024 |
| `splash_android12.png` | splash di Android 12+, il quadrato in 560 px su 1152 (dentro il cerchio superstite) |
| `source/anteprime/{android_cerchio,android_squircle,ios}.png` | controlli a occhio, non usati dall'app |

Poi `pwsh ../../tool/fl.ps1 pub run flutter_launcher_icons` e
`pwsh ../../tool/fl.ps1 pub run flutter_native_splash:create`.

Funzioni e costanti dello script (Python, non toccano il codice dell'app): FONDO (25, 38, 52:
il blu notte misurato negli angoli), `RIFILO = 34`, `TELA = 1080`, `LATO_ANDROID = 700`,
`carica()`, `maschera_quadrato(rgb)` (dentro = distanza dal blu > 40, buchi riempiti, erosione
di 3), `riempi_angoli(rgb, dentro)` (fuori dal quadrato il colore del pixel interno piu'
vicino, sfocato a 12), `main()`.

⚑ **Il disegno non si separa dal gradiente chiaro del riquadro**: lo sfondo del quadrato va dal
145 al 190 sul blu, il disegno ha parti scure (il coperchio del rullino) e parti chiare
(l'etichetta, il bollino). Nessuna soglia (ne' il rosso di Full Freezer ne' la luminosita' di
Scorte Calore) li separa. Per questo **non** si usa il metodo delle altre app (disegno ritagliato
in primo piano, sfondo separato).
⚑ **iOS usa il riquadro rifilato**: il bordo lucido e' sottile e il raggio degli angoli (24%) e'
quasi quello della maschera di Apple (22,4%), quindi il quadrato rifilato appena dentro il bordo
e' gia' un'icona iOS. Gli angoli si riempiono col colore del quadrato e non col blu notte: sotto
la maschera resterebbe un filo scuro che si legge come cornice.
⚑ **Android usa l'icona intera nella zona sicura**: 700 px dentro i 720 visibili; il disegno
arriva a ~0,46 del lato dal centro e resta dentro il cerchio sicuro da 660. Primo piano
trasparente: niente parallasse, che con un disegno non separabile non avrebbe niente da muovere.
`adaptive_icon_foreground_inset: 0`.
☠ **Manca la monocromatica** di Android 13 (icone a tema): senza un ritaglio del disegno non c'e'
una sagoma. Il launcher mostra l'icona a colori, che e' il comportamento previsto quando manca.
Se il proprietario fornisce `source/filmtracker_senza_sfondo.png`, si aggiunge.

| Impostazione | Valore |
|---|---|
| splash `color` / `color_dark` | `#192634` / `#192634` (uguali: l'app e' scura di default) |
| `background_color_ios` | `#192634` |
| `remove_alpha_ios` | `true` |
| `min_sdk_android` | 24 |

☠ **Le immagini generate non si modificano a mano**: si cambia l'originale e si rilancia lo
script. ☠ iOS: niente canale alfa, o App Store Connect rifiuta la build a caricamento finito.
☠ Android 12+ ritaglia la splash a cerchio e tiene solo i due terzi centrali: per questo
`splash_android12.png` e' un'immagine a parte.

---

## 2ter. iOS

L'app e' nata con `flutter create --platforms=android,ios` (F6.1). Nessuna estensione, nessun
App Group (non c'e' widget, F6.0 punto 4).

| Impostazione | Valore | Dove |
|---|---|---|
| Bundle app | `com.smp.filmtracker` (test: `com.smp.filmtracker.RunnerTests`) | `project.pbxproj` |
| TARGETED_DEVICE_FAMILY | `1` (solo iPhone; sull'iPad in compatibilita') | `project.pbxproj` |
| IPHONEOS_DEPLOYMENT_TARGET | `15.0` | `project.pbxproj` |
| DEVELOPMENT_TEAM | A29HGT2MQ4 | `project.pbxproj` |
| Schema URL | `filmtracker` (CFBundleURLName `com.smp.filmtracker`) | `Info.plist` CFBundleURLTypes |
| FlutterDeepLinkingEnabled | `false` | `Info.plist` |
| ITSAppUsesNonExemptEncryption | `false` | `Info.plist` |
| Lingue | `it`, `en` (CFBundleLocalizations) | `Info.plist` |
| NSCameraUsageDescription, NSPhotoLibraryUsageDescription | inglese in `Info.plist`; it/en in `{it,en}.lproj/InfoPlist.strings` (anche CFBundleDisplayName) | |
| Orientamenti | iPhone: verticale e i due orizzontali | `Info.plist` |

⚑ **Niente CocoaPods**: Flutter risolve i plugin con Swift Package Manager. Non c'e' Podfile.
⚑ `AppDelegate.swift` (FlutterImplicitEngineDelegate) e `SceneDelegate.swift` sono quelli
del template: nessun codice nativo nostro su iOS.

### I testi dei permessi nel progetto Xcode

I due `InfoPlist.strings` sono stati aggiunti al target Runner come **gruppo di varianti** con
lo script del monorepo, **sul Mac**, dalla radice della copia, con il Ruby di Homebrew (la gemma
`xcodeproj`):

```
export PATH=/opt/homebrew/bin:$PATH
ruby tool/aggiungi_infoplist_strings.rb apps/film_tracker
```

☠ File sciolti finirebbero nel pacchetto con lo stesso nome e uno sovrascriverebbe l'altro; un
file presente solo su disco non viene letto da iOS, che mostra l'inglese. Lo script e'
idempotente. **Gia' eseguito** (commit `5dce3bc`: le voci `InfoPlist.strings` sono nel
`project.pbxproj`). Le modifiche fatte sul Mac (il `project.pbxproj` toccato dallo script)
**non tornano da sole sul PC**: vanno riportate a mano.

### Come si compila sul Mac

La macchina iOS e' il Mac mini (`ssh mac`); la repo vive in `~/microapps` come copia non-git
sincronizzata dal PC con `tar` via ssh, toolchain in `~/microapps-toolchain/flutter` (stessa
procedura di Full Freezer e Scorte Calore, vedi i loro atlanti §2ter).

```
export PATH="$HOME/microapps-toolchain/flutter/bin:/opt/homebrew/bin:$PATH"
cd ~/microapps/apps/film_tracker
flutter build ios --simulator --debug
xcrun simctl install <UDID> build/ios/iphonesimulator/Runner.app
xcrun simctl launch  <UDID> com.smp.filmtracker
```

**Provato sul simulatore il 2026-10-08** (testi dei permessi it/en compresi).
Caricamento su TestFlight: `tool/build_ios.sh film_tracker` sul Mac — **non ancora eseguito**
(§14). Le prove si fanno su **iPad**, in compatibilita' iPhone (niente iPhone a disposizione).

---

## 3. Il database

Sei tabelle, **`schemaVersion = 1`**, file `film_tracker.sqlite` nella cartella documenti
dell'app. Le date civili sono TEXT `YYYY-MM-DD` (ADR-008: "caricato il 3 marzo" non ha fuso
orario), gli istanti sono interi in millisecondi UTC, **i soldi sono centesimi interi, mai
double**. Le colonne in SQL sono in snake_case (Drift converte i getter camelCase).

Legenda vincoli: **CHECK** = vincolo SQL vero, scritto nello schema; **len** = `withLength`,
controllato **solo da Drift in Dart** all'inserimento con un companion, non da SQLite.

☠ `PRAGMA foreign_keys = ON` si imposta in `beforeOpen` **a ogni connessione**: SQLite lo tiene
spento di default, e senza i cascade sarebbero decorativi (cancellare un rullino lascerebbe
sviluppi, stampe e immagini orfani).

⚑ **Le chiavi ammesse nei CHECK vengono dal dominio**, non da una lista copiata: variabili di
modulo in `tables.dart` (riesportate da `database.dart`):

| Simbolo | Firma | Contenuto |
|---|---|---|
| `filmFormatKeys` | `final List<String> filmFormatKeys` | `[for (f in FilmFormat.values) f.key]` → `35mm, 120, 110, large, other` |
| `filmProcessKeys` | `final List<String> filmProcessKeys` | `[for (p in FilmProcess.values) p.key]` → `C-41, E-6, BW, ECN-2, other` |
| `rollStatusKeys` | `final List<String> rollStatusKeys` | `[for (s in RollStatus.values) s.key]` |
| `rollImageKindKeys` | `final List<String> rollImageKindKeys` | `[for (k in RollImageKind.values) k.key]` |

☠ Il CHECK entra nello schema **alla creazione** della tabella: aggiungere una chiave al dominio
dopo il rilascio richiede una migrazione che ricrei la tabella (SQLite non modifica i CHECK).
Il file `tables.dart` ha `// ignore_for_file: recursive_getters`: i `check(...)` citano la
colonna dentro il suo getter, forma documentata da Drift, che il lint scambia per ricorsione.

### `cameras` (classe `Cameras`, F6.5)

| Colonna | Tipo | Default | Vincoli | Significato |
|---|---|---|---|---|
| `id` | INTEGER | | PK autoincrement | |
| `manufacturer` | TEXT | | len 1..60 | "Olympus": dato dell'utente |
| `model` | TEXT | | len 1..60 | "OM-2" |
| `format` | TEXT | | **CHECK IN `filmFormatKeys`** | preimposta il formato dei rullini caricati in questa macchina |
| `note` | TEXT nullable | | | |
| `active` | BOOL | `true` | | dismessa: sparisce dalla scelta nel form ma resta sui rullini (**nessuna UI la cambia**, §14) |
| `sort_order` | INTEGER | `0` | | ordine nell'elenco (**nessuna UI di riordino**, §14) |

⚑ Niente numero di serie, anno, valore, obiettivi, foto della macchina: la spec avverte che
**non deve diventare un'app per collezionisti** (F6.5).

### `film_stocks` (classe `FilmStocks`, F6.4) — il catalogo

| Colonna | Tipo | Default | Vincoli | Significato |
|---|---|---|---|---|
| `id` | INTEGER | | PK autoincrement | |
| `brand` | TEXT | | len 1..60 | "Kodak" |
| `name` | TEXT | | len 1..80 | "Portra 400" |
| `iso` | INTEGER | | **CHECK BETWEEN 1 AND 100000** | il tetto e' largo (le Delta 3200 si tirano a 25600) ma toglie gli errori a sei cifre |
| `process` | TEXT | | **CHECK IN `filmProcessKeys`** | |
| `format` | TEXT | | **CHECK IN `filmFormatKeys`** | |
| `is_custom` | BOOL | `false` | | true per le pellicole dell'utente: solo queste si modificano e si cancellano |

Vincolo: **`UNIQUE(brand, name, format)`** (`uniqueKeys`).
☠ Due "Kodak Portra 400 35mm" renderebbero ambigua la selezione rapida e spezzerebbero il
conteggio delle piu' usate. Il controllo **senza maiuscole e spazi** lo fa
`FilmRepository.addCustomStock` (in Dart: `lower()` di SQLite conosce solo l'ASCII); la UNIQUE e'
l'ultimo argine (distingue le maiuscole).

### `film_rolls` (classe `FilmRolls`) — l'entita' principale

| Colonna | Tipo | Vincoli | Significato |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `sequence_number` | INTEGER | **UNIQUE**, **CHECK > 0** | il "#17": `max + 1` (`FilmRepository.addRoll`). E' anche l'indirizzo del QR |
| `film_stock_id` | INTEGER nullable | FK → `film_stocks.id` **ON DELETE SET NULL** | |
| `film_name` | TEXT | len 1..120 | ⚑ **denormalizzato** ("Kodak Portra 400") |
| `format` | TEXT | **CHECK IN `filmFormatKeys`** | il formato **del rullino**, non della pellicola |
| `nominal_iso` | INTEGER | **CHECK BETWEEN 1 AND 100000** | |
| `exposed_iso` | INTEGER | **CHECK BETWEEN 1 AND 100000** | push/pull: diverso dal nominale → la UI lo evidenzia |
| `camera_id` | INTEGER nullable | FK → `cameras.id` **ON DELETE SET NULL** | |
| `loaded_at` | TEXT nullable | len 10..10 | `YYYY-MM-DD` |
| `finished_at` | TEXT nullable | len 10..10, **CHECK (finished_at IS NULL OR loaded_at IS NULL OR finished_at >= loaded_at)** | il confronto fra testi ISO e' cronologico |
| `frames` | INTEGER | **CHECK BETWEEN 1 AND 1000** | fotogrammi **nominali** |
| `title` | TEXT nullable | len max 120 | "Praga - settembre 2026" |
| `note` | TEXT nullable | | |
| `status` | TEXT | **CHECK IN `rollStatusKeys`** | §4 |
| `cost_cents` | INTEGER nullable | **CHECK >= 0** | costo della pellicola |
| `cover_image_id` | INTEGER nullable | FK → `roll_images.id` **ON DELETE SET NULL** | la copertina dell'archivio |
| `created_at` | INTEGER | obbligatoria | ms UTC |

Indici: `idx_film_rolls_status (status)`, `idx_film_rolls_camera (camera_id)`,
`idx_film_rolls_stock (film_stock_id)`.

⚑ **Perche' `film_name` e' denormalizzato**: se l'utente cancella una pellicola personalizzata,
i rullini scattati con quella devono continuare a dire cosa erano. Un archivio che perde
l'informazione quando si riordina il catalogo e' inutilizzabile.
⚑ **Che la copertina sia un'immagine di questo rullino** lo controlla
`FilmRepository.setCoverImage`: un CHECK non puo' leggere un'altra tabella.
⚑ **Riferimento circolare** `film_rolls.cover_image_id` ↔ `roll_images.film_roll_id`: SQLite
accetta la FK in avanti; il backup lo spezza con `cover: true` sull'immagine (§8).

### `developments` (classe `Developments`, F6.7) — al massimo uno per rullino

| Colonna | Tipo | Vincoli | Significato |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `film_roll_id` | INTEGER | **UNIQUE**, FK → `film_rolls.id` **ON DELETE CASCADE** | ⚑ uno sviluppo per rullino |
| `laboratory` | TEXT nullable | len max 80 | ⚑ nullable anche se F6.2 lo dava obbligatorio |
| `submitted_at` | TEXT nullable | len 10..10 | consegna |
| `returned_at` | TEXT nullable | len 10..10, **CHECK (returned_at IS NULL OR submitted_at IS NULL OR returned_at >= submitted_at)** | ritorno (per lo sviluppo in casa: "sviluppato il") |
| `development_cost_cents` | INTEGER nullable | **CHECK >= 0** | |
| `scan_cost_cents` | INTEGER nullable | **CHECK >= 0** | |
| `process` | TEXT nullable | **CHECK IN `filmProcessKeys`** (NULL passa) | |
| `self_developed` | BOOL | default `false` | sviluppo in casa |
| `note` | TEXT nullable | | |

⚑ **`laboratory` nullable**: lo sviluppo in casa non ha un laboratorio, e chi ha dimenticato il
nome deve poter registrare lo stesso le date.
⚑ **Sviluppo e stampa sono tabelle separate e non colonne del rullino** (spec e F6.2): un rullino
puo' avere uno sviluppo e **tre** ordini di stampa a mesi di distanza, da laboratori diversi.

### `print_orders` (classe `PrintOrders`, F6.7) — N per rullino

| Colonna | Tipo | Vincoli | Significato |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `film_roll_id` | INTEGER | FK → `film_rolls.id` **ON DELETE CASCADE** | |
| `laboratory` | TEXT nullable | len max 80 | stessa ragione di `developments.laboratory` |
| `submitted_at` / `returned_at` | TEXT nullable | len 10..10, stesso CHECK di `developments` | |
| `format` | TEXT nullable | len max 40 | testo libero: "10x15", "13x18 opaco" |
| `number_of_prints` | INTEGER nullable | **CHECK > 0** | |
| `cost_cents` | INTEGER nullable | **CHECK >= 0** | |
| `note` | TEXT nullable | | |

Indice: `idx_print_orders_roll (film_roll_id)`.

### `roll_images` (classe `RollImages`, F6.9)

| Colonna | Tipo | Default | Vincoli | Significato |
|---|---|---|---|---|
| `id` | INTEGER | | PK autoincrement | |
| `film_roll_id` | INTEGER | | FK → `film_rolls.id` **ON DELETE CASCADE** | |
| `path` | TEXT | | len 1..255 | **relativo** alla cartella documenti: `images/rolls/<uuid>.jpg` |
| `thumb_path` | TEXT | | len 1..255 | `images/thumbs/rolls/<uuid>.jpg` |
| `width` / `height` | INTEGER | | **CHECK > 0** | dell'immagine grande (max 1600 sul lato lungo) |
| `bytes` | INTEGER | | **CHECK >= 0** | dimensione dell'immagine grande |
| `kind` | TEXT | | **CHECK IN `rollImageKindKeys`** | provini, stampa, scansione, altro |
| `sort_order` | INTEGER | `0` | | ordine dell'utente |
| `created_at` | INTEGER | | obbligatoria | ms UTC |

Indice: `idx_roll_images_roll (film_roll_id, sort_order)`.

☠ **Percorsi relativi** (F1.11, StoredImage.path): un percorso assoluto si rompe al primo
aggiornamento dell'app su Android (cambia la cartella del contenitore).
☠ **Cancellare la riga non cancella il file**: `FilmRepository.deleteImage` e
`deleteRollAndCollectImagePaths` restituiscono i percorsi, e il chiamante li passa allo storage.

### Righe generate da Drift

Le classi **tabella** scritte a mano in `tables.dart` (estendono Table di Drift) sono `Cameras`,
`FilmStocks`, `RollImages`, `FilmRolls`, `Developments`, `PrintOrders`; il database le dichiara
in `@DriftDatabase(tables: [Cameras, FilmStocks, FilmRolls, Developments, PrintOrders, RollImages])`.

Classi riga (in `database.g.dart`, non si modificano): Camera, FilmStock, FilmRoll, Development,
PrintOrder, RollImage, piu' i companion (CamerasCompanion, FilmStocksCompanion,
FilmRollsCompanion, DevelopmentsCompanion, PrintOrdersCompanion, RollImagesCompanion). I campi
sono i getter in camelCase: le date (`loadedAt`, `finishedAt`, `submittedAt`, `returnedAt`)
sono String?, le chiavi (`format`, `process`, `status`, `kind`) sono String, i costi `int?`,
`createdAt` int. Le righe hanno `copyWith` (con Value per i nullable).

⚑ **La riga Drift non e' il modello del dominio**: le schermate vogliono id, note, `sortOrder`;
i calcoli vogliono tipi forti. Si converte nel punto in cui serve, con le estensioni di §5.

### Seed del catalogo e migrazioni

`onCreate`: `createAll()` e poi `seedCatalog()` (le 25 di `kFilmCatalog`, `isCustom` false).
⚑ **Il catalogo si carica alla creazione, una volta sola**: a ogni avvio resusciterebbe le
pellicole cancellate o ritoccate. ☠ Una voce aggiunta a `kFilmCatalog` dopo il rilascio **non
arriva agli utenti esistenti**: serve un passo di migrazione che la inserisca se manca
(`seedCatalog` usa `insertOrIgnore`, quindi rilanciarlo e' sicuro).

`onUpgrade` **lancia** UnsupportedError: alla versione 1 non c'e' niente da migrare, e il ramo
resta scritto perche' la prima modifica di schema debba incrementare `schemaVersion` **e**
aggiungere qui il passo con il suo test. Senza, il primo aggiornamento in produzione
cancellerebbe i dati.

---

## 4. `lib/domain/` — il cuore, senza database

Dart puro: niente Flutter, niente Drift, **niente stringhe dell'app** (i nomi visibili stanno
in `lib/app/labels.dart` e negli ARB). Dipende da `micro_core` solo per CivilDate e da `meta`.

### `film_types.dart`

Ogni valore porta una `key` **stabile**, quella salvata nel database: non si rinomina mai, anche
se si rinomina il valore dell'enum. ⚑ Scritta a mano e non `name`: `35mm` e `C-41` non sono
nemmeno identificatori Dart validi.

`enum FilmFormat` — costruttore `const FilmFormat(this.key, {required this.defaultFrames})`.

| Valore | `key` (nel DB) | `defaultFrames` | Nota |
|---|---|---|---|
| `mm35` | `35mm` | 36 | |
| `medium120` | `120` | 12 | ⚑ il 6x6, il caso piu' comune (6x4,5 ne fa 15-16, 6x7 ne fa 10: si corregge nel form) |
| `mm110` | `110` | 24 | |
| `large` | `large` | 1 | una lastra e' un'esposizione |
| `other` | `other` | 36 | |

| Membro | Firma | Significato |
|---|---|---|
| `key` | `final String key` | valore stabile nel database |
| `defaultFrames` | `final int defaultFrames` | i fotogrammi con cui il form preimposta `frames` (F6.6) |
| `byKey` | `static FilmFormat? byKey(String? key)` | null su chiave sconosciuta (dato corrotto o versione futura) |

`enum FilmProcess` — `c41('C-41')`, `e6('E-6')`, `bw('BW')`, `ecn2('ECN-2')`, `other('other')`;
`const FilmProcess(this.key)`, `final String key`, `static FilmProcess? byKey(String? key)`.

`enum RollImageKind` — `contactSheet('contactSheet')`, `print('print')`, `scan('scan')`,
`other('other')`; `const RollImageKind(this.key)`, `final String key`,
`static RollImageKind? byKey(String? key)`.

### `roll_status.dart` — la macchina a stati (F6.3)

⚑ **Serve a guidare la UI, non a punire l'utente**: `FilmRepository.setRollStatus` rifiuta le
transizioni non ammesse ma accetta `force: true`, perche' la realta' e' piu' disordinata del
modello (un rullino ritrovato in un cassetto, un laboratorio che sviluppa e stampa in un colpo).

`enum RollStatus` — `const RollStatus(this.key)`; `final String key` (**non si rinomina mai**);
`static RollStatus? byKey(String? key)`.

| Valore | `key` | Significato | Sezione |
|---|---|---|---|
| `loaded` | `loaded` | in macchina, si sta scattando | `inCamera` |
| `exposed` | `exposed` | finito, da consegnare | `inCamera` |
| `sentForDevelopment` | `sentForDevelopment` | consegnato al laboratorio | `atLab` |
| `developed` | `developed` | negativi (o diapositive) tornati | `archive` |
| `printed` | `printed` | stampe tornate | `archive` |
| `archived` | `archived` | chiuso dall'utente | `archive` |

`enum RollSection { inCamera, atLab, archive }` — le tre sezioni della home (F6.8).

`@immutable class LabEvent` — un evento di laboratorio ridotto a cio' che serve a `suggestFrom`.
⚑ Non e' la riga Drift (Development, PrintOrder): il dominio non dipende dal database; la
conversione e' `toLabEvent()` in `database.dart`.

| Membro | Firma | Significato |
|---|---|---|
| costruttore | `const LabEvent({CivilDate? submittedAt, CivilDate? returnedAt, bool selfDeveloped = false})` | |
| campi | `final CivilDate? submittedAt`, `final CivilDate? returnedAt`, `final bool selfDeveloped` | `selfDeveloped` sempre false per le stampe |
| `isReturned` | `bool get isReturned` | `returnedAt != null \|\| selfDeveloped`. ⚑ Uno sviluppo **in casa** e' concluso per definizione: si registra dopo averlo fatto, e non e' mai "in laboratorio" |
| `==`, `hashCode`, `toString` | | per valore; `LabEvent(a -> b, in casa)` |

`class RollStatusMachine` — `const RollStatusMachine()`.

| Membro | Firma | Effetto |
|---|---|---|
| `allowedTransitions` | `static const Map<RollStatus, Set<RollStatus>> allowedTransitions` | la matrice sotto. Lo stesso stato non e' una transizione |
| `canTransition` | `bool canTransition(RollStatus from, RollStatus to)` | `allowedTransitions[from]?.contains(to) ?? false` |
| `suggestFrom` | `RollStatus suggestFrom({required RollStatus current, CivilDate? finishedAt, LabEvent? development, List<LabEvent> prints = const []})` | lo stato che gli eventi **suggeriscono** (regole sotto) |
| `sectionFor` | `RollSection sectionFor(RollStatus status)` | `loaded`/`exposed` → `inCamera`; `sentForDevelopment` → `atLab`; il resto → `archive` |
| `statusesIn` | `Set<RollStatus> statusesIn(RollSection section)` | l'inverso di `sectionFor`, per le query |

Matrice delle transizioni (riga = da, ✓ = ammessa):

| da \ a | loaded | exposed | sentForDev | developed | printed | archived |
|---|---|---|---|---|---|---|
| `loaded` | | ✓ | | | | ✓ |
| `exposed` | | | ✓ | ✓ | | ✓ |
| `sentForDevelopment` | | ✓ | | ✓ | | ✓ |
| `developed` | | | | | ✓ | ✓ |
| `printed` | | | | ✓ | | ✓ |
| `archived` | | | | ✓ | ✓ | |

⚑ `printed → developed` e `archived → developed/printed` sono ammesse: la stampa e' un evento
separato e ripetibile, e un rullino ristampato mesi dopo non deve restare bloccato in uno stato
terminale (F6.3). `sentForDevelopment → exposed` annulla una consegna segnata per sbaglio.
Nessuno stato e' un vicolo cieco (lo prova un test).

Regole di `suggestFrom`, nell'ordine (vince la prima):
1. `current == archived` → `archived` (l'archiviazione e' una scelta esplicita: uno sviluppo
   registrato dopo non deve riproporre di toglierla);
2. una stampa con `returnedAt` → `printed`;
3. uno sviluppo tornato (`isReturned`) → `developed`;
4. uno sviluppo registrato e non tornato → `sentForDevelopment` (con o senza `submittedAt`:
   averlo registrato vuol dire averlo consegnato);
5. nessun evento: `loaded` con `finishedAt` → `exposed`; altrimenti `current`. ⚑ Senza eventi
   non si suggerisce mai di tornare indietro: uno stato messo a mano resta.

Una stampa consegnata e non tornata non sposta nulla.

⚑ **Rispetto alla firma del piano mancano due cose, di proposito**: `labelFor` (niente stringhe
nel dominio: l'etichetta la risolve `statusName` in `labels.dart`) e le righe Drift come
parametri di `suggestFrom` (riceve LabEvent e i due campi del rullino che servono, cosi' si
prova con valori scritti a mano).

### `film_catalog.dart` — le 25 emulsioni

`@immutable class CatalogStock` — `const CatalogStock(this.brand, this.name, this.iso, {required this.process, this.format = FilmFormat.mm35})`.

| Membro | Firma | Significato |
|---|---|---|
| campi | `final String brand` (nome proprio, non si traduce), `final String name`, `final int iso`, `final FilmProcess process`, `final FilmFormat format` | |
| `displayName` | `String get displayName` | `'$brand $name'`: quello che `film_rolls.film_name` copia |
| `==`, `hashCode`, `toString` | | per valore |

`const List<CatalogStock> kFilmCatalog` — nell'ordine del piano (F6.2): Kodak Gold 200 (C-41),
Portra 160, Portra 400, Portra 800, Ultramax 400, ColorPlus 200 (C-41), Tri-X 400, T-Max 100,
T-Max 400 (BW), Ektar 100 (C-41); Ilford HP5+ 400, FP4+ **125**, Delta 100, Delta 400 (BW),
**XP2 Super 400 (C-41: bianco e nero cromogenico)**; Fomapan 100, 200, 400 (BW); Fujifilm C200,
Superia X-TRA 400 (C-41), **Velvia 50, Provia 100F (E-6)**; Cinestill 800T, 400D (**C-41**:
pellicole cinema vendute senza remjet); Lomography Color 400 (C-41). **Tutte in 35mm.**

⚑ **Sta nel dominio e non nel database**: il seed di AppDatabase e i test leggono dallo stesso
posto; due liste divergerebbero alla prima emulsione aggiunta e il test passerebbe lo stesso.
⚑ **Catalogo locale e non remoto**: 25 emulsioni coprono quasi tutto l'uso reale, e chi usa la
ventiseiesima la aggiunge a mano; un catalogo remoto costerebbe un backend per poco.
⚑ **Formato `35mm` per tutte**: molte esistono anche in 120, ma una riga per formato
raddoppierebbe la lista. Il formato vero e' quello **del rullino**, che il form preimposta dalla
macchina.
⚑ **"Pellicola personalizzata" non e' una riga**: e' la voce sempre presente nella UI che apre
la creazione (F6.4). Come riga sarebbe un dato finto in ogni statistica, e il nome va tradotto.

### `film_stats.dart` — le statistiche per anno (F6.10, Pro)

⚑ **Tutto in centesimi interi**, come nel database: sommare euro in double porta a 419,99999
dopo dieci rullini. Le sole divisioni sono le medie: per rullino si arrotonda al centesimo, per
fotogramma resta double (un fotogramma da 0,347 € e' un dato vero) e la arrotonda chi la mostra.
⚑ **Un rullino appartiene all'anno della sua data** (`StatsRoll.date`: caricamento, o creazione
se manca) **con tutti i suoi costi**, anche lo sviluppo pagato a gennaio di un rullino caricato
a dicembre: dividere i costi per data dell'evento renderebbe la media per rullino senza senso.

`@immutable class StatsDevelopment` — `const StatsDevelopment({String? laboratory, int? developmentCostCents, int? scanCostCents, bool selfDeveloped = false})`;
campi omonimi `final`. In casa: il "laboratorio" non conta fra i piu' usati.

`@immutable class StatsPrint` — `const StatsPrint({String? laboratory, int? costCents})`.

`@immutable class StatsRoll`

| Membro | Firma | Significato |
|---|---|---|
| costruttore | `const StatsRoll({required CivilDate date, required int frames, required String filmName, int? cameraId, int? costCents, StatsDevelopment? development, List<StatsPrint> prints = const []})` | |
| campi | `final CivilDate date`, `final int frames` (nominali), `final String filmName`, `final int? cameraId`, `final int? costCents`, `final StatsDevelopment? development`, `final List<StatsPrint> prints` | |
| `hasAnyCost` | `bool get hasAnyCost` | almeno un costo scritto (pellicola, sviluppo, scansione, una stampa): solo questi entrano nelle medie |

`@immutable class RankedName` — `const RankedName(this.name, this.count)`; `final String name`,
`final int count`; `==`, `hashCode`, `toString`.

`@immutable class YearStats`

| Membro | Firma | Significato |
|---|---|---|
| costruttore | `const YearStats({required int year, required int rollCount, required int potentialFrames, required int filmCents, required int developmentCents, required int scanCents, required int printCents, required int costedRollCount, required int costedFrames, required List<int> rollsPerMonth, RankedName? topLaboratory, RankedName? topEmulsion, int? topCameraId, int topCameraRolls = 0, int selfDevelopedCount = 0})` | |
| `potentialFrames` | `final int` | somma dei fotogrammi nominali: quanti se ne **potevano** scattare |
| `filmCents`, `developmentCents`, `scanCents`, `printCents` | `final int` | spesa per voce |
| `costedRollCount`, `costedFrames` | `final int` | ⚑ la base delle medie: un rullino senza nessun costo (regalato, scontrino perso) abbasserebbe la media a torto |
| `rollsPerMonth` | `final List<int>` | dodici interi, gennaio in posizione 0 (non modificabile) |
| `topLaboratory`, `topEmulsion` | `final RankedName?` | piu' sviluppi + ordini di stampa (in casa escluso); piu' rullini |
| `topCameraId`, `topCameraRolls` | `final int?`, `final int` | il nome lo risolve la UI dall'id |
| `selfDevelopedCount` | `final int` | rullini sviluppati in casa |
| `totalCents` | `int get totalCents` | somma delle quattro voci |
| `averageCentsPerRoll` | `int? get averageCentsPerRoll` | `totalCents / costedRollCount` arrotondato; null se nessun rullino ha costi |
| `estimatedCentsPerFrame` | `double? get estimatedCentsPerFrame` | `totalCents / costedFrames`; ☠ **e' una stima e la UI deve dirlo** (F6.10) |
| `isEmpty` | `bool get isEmpty` | `rollCount == 0` |

`class FilmStatsCalculator` — `const FilmStatsCalculator()`.

| Metodo | Firma | Effetto |
|---|---|---|
| `years` | `List<int> years(Iterable<StatsRoll> rolls)` | gli anni con almeno un rullino, dal piu' recente |
| `forYear` | `YearStats forYear(int year, Iterable<StatsRoll> rolls)` | mai null: un anno vuoto e' tutto a zero (`isEmpty` vero) |

A parita' di rullini vince la macchina con l'**id piu' basso** (registrata prima: deterministico).
Privata `_Counter` (`add(String?)`, `RankedName? top()`): conta nomi digitati a mano ignorando
maiuscole e spazi ("Fotoservice " = "fotoservice"), mostra la grafia vista per prima, a parita'
il primo in ordine alfabetico.

☠ **Costo per fotogramma sui fotogrammi nominali**: non tutti i fotogrammi vengono scattati o
riescono; presentarlo come dato esatto sarebbe falso. Pagina e PDF lo scrivono nel titolo
("stima"), nel valore ("≈") e in una riga di spiegazione.

---

## 5. `lib/data/`

### `class AppDatabase extends _$AppDatabase` (`database.dart`)

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `AppDatabase(super.e)` | |
| `open` | `factory AppDatabase.open()` | file `film_tracker.sqlite` nella cartella documenti, su isolate separato (`NativeDatabase.createInBackground`) |
| `memory` | `factory AppDatabase.memory()` | in memoria, per i test (catalogo gia' caricato da `onCreate`) |
| `schemaVersion` | `int get schemaVersion` → `1` | |
| `migration` | `MigrationStrategy get migration` | `onCreate`: `createAll` + `seedCatalog`; `beforeOpen` → `PRAGMA foreign_keys = ON`; `onUpgrade` lancia |
| `seedCatalog` | `Future<void> seedCatalog()` | `kFilmCatalog` in `film_stocks` con `InsertMode.insertOrIgnore` (salta i presenti per la UNIQUE). Pubblica per il ripristino del backup e per una migrazione futura |

Privata `_openConnection()` (LazyDatabase): imposta `sqlite3.tempDirectory` alla cartella
temporanea dell'app. ☠ Su Android la cartella temporanea di sistema non e' scrivibile: senza,
VACUUM e alcuni ORDER BY grandi falliscono con "unable to open database file", **solo su
dispositivo**.

Estensioni riga → dominio (stesso file). ☠ Una chiave sconosciuta **lancia StateError** invece
di ripiegare su un default: con i CHECK succede solo con un backup di una versione futura, e un
dato sbagliato in silenzio e' peggio di un errore visibile.

| Estensione | Membro | Firma | Effetto |
|---|---|---|---|
| `CameraToDomain on Camera` | `formatEnum` | `FilmFormat get formatEnum` | StateError su chiave ignota |
| | `displayName` | `String get displayName` | "Olympus OM-2" |
| `FilmStockToDomain on FilmStock` | `formatEnum` | `FilmFormat get formatEnum` | |
| | `processEnum` | `FilmProcess get processEnum` | |
| | `displayName` | `String get displayName` | "Kodak Portra 400": quello che `filmName` copia |
| `FilmRollToDomain on FilmRoll` | `statusEnum` | `RollStatus get statusEnum` | |
| | `formatEnum` | `FilmFormat get formatEnum` | |
| | `section` | `RollSection get section` | `RollStatusMachine().sectionFor(statusEnum)` |
| | `loadedDate` / `finishedDate` | `CivilDate? get loadedDate`, `CivilDate? get finishedDate` | `CivilDate.tryParse` |
| | `isPushPull` | `bool get isPushPull` | `exposedIso != nominalIso` |
| | `createdAtUtc` | `DateTime get createdAtUtc` | da ms UTC |
| `DevelopmentToDomain on Development` | `submittedDate` / `returnedDate` | `CivilDate? get ...` | |
| | `processEnum` | `FilmProcess? get processEnum` | null se non indicato; StateError su chiave ignota |
| | `toLabEvent` | `LabEvent toLabEvent()` | con `selfDeveloped` |
| `PrintOrderToDomain on PrintOrder` | `submittedDate` / `returnedDate` | `CivilDate? get ...` | |
| | `toLabEvent` | `LabEvent toLabEvent()` | |
| `RollImageToDomain on RollImage` | `kindEnum` | `RollImageKind get kindEnum` | |
| | `toStoredImage` | `StoredImage toStoredImage()` | per `ImageStore.delete`, che vuole uno StoredImage |

### `class FilmRepository` (`film_repository.dart`)

`FilmRepository(AppDatabase db, {DateTime Function()? clock})` (il primo e' il campo privato
`_db`) — `clock` per i test (default `DateTime.now`; gli istanti si salvano in ms UTC).
**Tutte** le letture e scritture passano da qui.

⚑ **Perche' un repository**: cinque regole non si scrivono come vincoli SQL e vanno rispettate a
ogni scrittura: (1) `sequenceNumber` e' `max + 1` nella stessa transazione dell'inserimento;
(2) lo stato cambia solo per transizioni ammesse, salvo `force`; (3) al massimo **uno**
sviluppo per rullino (il secondo salvataggio sostituisce); (4) la copertina e' un'immagine
**dello stesso** rullino; (5) le pellicole del catalogo non si modificano ne' si cancellano, e
non esistono due pellicole uguali a meno delle maiuscole.
⚑ **Righe in uscita, dominio dove serve**: le letture restituiscono righe Drift; le conversioni
stanno nelle estensioni di `database.dart`.
⚑ **I limiti del Pro non stanno qui** (una macchina gratis): li applica la UI con FeatureGate.

**Macchine**

| Metodo | Firma | Effetto |
|---|---|---|
| `watchCameras` | `Stream<List<Camera>> watchCameras({bool activeOnly = false})` | per `sort_order`, poi id |
| `allCameras` | `Future<List<Camera>> allCameras({bool activeOnly = false})` | idem, una volta |
| `cameraById` | `Future<Camera?> cameraById(int id)` | |
| `watchCamera` | `Stream<Camera?> watchCamera(int id)` | (non usato, §14) |
| `cameraCount` | `Future<int> cameraCount()` | attive **e** dismesse: il conteggio di `secondaryEntities` |
| `watchCameraCount` | `Stream<int> watchCameraCount()` | |
| `addCamera` | `Future<int> addCamera({required String manufacturer, required String model, required FilmFormat format, String? note})` | in fondo (`sortOrder` = numero di macchine), `trim`, nota vuota → null. **Non** controlla il limite Pro |
| `updateCamera` | `Future<void> updateCamera(Camera camera)` | salva produttore, modello, formato, nota; **non** tocca `active` e `sortOrder` |
| `setCameraActive` | `Future<void> setCameraActive(int id, bool active)` | (nessuna UI, §14) |
| `deleteCamera` | `Future<void> deleteCamera(int id)` | i rullini restano con `cameraId` NULL (setNull) |
| `reorderCameras` | `Future<void> reorderCameras(List<int> idsInOrder)` | in transazione (nessuna UI, §14) |
| `watchRollCountByCamera` | `Stream<Map<int, int>> watchRollCountByCamera()` | `cameraId → rullini`; le macchine senza rullini non compaiono (`?? 0`) |
| `rollCountByCamera` | `Future<Map<int, int>> rollCountByCamera()` | idem, una volta |

**Catalogo pellicole**

| Metodo | Firma | Effetto |
|---|---|---|
| `watchStocks` | `Stream<List<FilmStock>> watchStocks()` | per marca e nome **senza maiuscole** (`Collate.noCase`), poi id |
| `allStocks` | `Future<List<FilmStock>> allStocks()` | idem |
| `stockById` | `Future<FilmStock?> stockById(int id)` | |
| `watchMostUsedStocks` | `Stream<List<FilmStock>> watchMostUsedStocks({int limit = 5})` | usate in almeno un rullino, per numero di rullini, a parita' la piu' recente (`MAX(sequence_number)`) |
| `mostUsedStocks` | `Future<List<FilmStock>> mostUsedStocks({int limit = 5})` | idem |
| `addCustomStock` | `Future<int> addCustomStock({required String brand, required String name, required int iso, required FilmProcess process, required FilmFormat format})` | transazione; `isCustom` true; **DuplicateFilmStockException** se esiste gia' (anche del catalogo) a meno di maiuscole e spazi |
| `updateCustomStock` | `Future<void> updateCustomStock(FilmStock stock)` | **StateError** inesistente, **ArgumentError** sul catalogo, DuplicateFilmStockException se diventa uguale a un'altra. ⚑ I rullini **non** cambiano nome (`filmName` e' la loro storia) |
| `deleteCustomStock` | `Future<void> deleteCustomStock(int id)` | inesistente → niente; **ArgumentError** sul catalogo; i rullini restano col loro `filmName` e `filmStockId` NULL |

**Rullini**

| Metodo | Firma | Effetto |
|---|---|---|
| `watchRolls` | `Stream<List<FilmRoll>> watchRolls({RollSection? section})` | **dal numero piu' alto**; con `section` filtra con `statusesIn` (non usato fuori dal repository, §14) |
| `allRolls` | `Future<List<FilmRoll>> allRolls({RollSection? section})` | idem, una volta |
| `rollById` | `Future<FilmRoll?> rollById(int id)` | |
| `watchRoll` | `Stream<FilmRoll?> watchRoll(int id)` | |
| `rollBySequence` | `Future<FilmRoll?> rollBySequence(int sequenceNumber)` | il bersaglio del QR |
| `nextSequenceNumber` | `Future<int> nextSequenceNumber()` | `max + 1`, 1 sul database vuoto |
| `addRoll` | `Future<int> addRoll({int? filmStockId, required String filmName, required FilmFormat format, required int nominalIso, int? exposedIso, int? cameraId, CivilDate? loadedAt, CivilDate? finishedAt, required int frames, String? title, String? note, int? costCents, RollStatus status = RollStatus.loaded})` | transazione con `nextSequenceNumber`; `exposedIso` default `nominalIso`; `filmName` con `trim`; titolo e nota vuoti → null; `createdAt` dall'orologio. `status` serve a import e demo: la UI crea sempre `loaded` |
| `updateRoll` | `Future<void> updateRoll(FilmRoll roll)` | pellicola, formato, ISO, macchina, date, fotogrammi, titolo, nota, costo. ⚑ **Non** tocca `sequenceNumber`, `createdAt`, `status`, `coverImageId`. SqliteException se `finishedAt < loadedAt` |
| `setRollStatus` | `Future<void> setRollStatus(int id, RollStatus to, {bool force = false})` | transazione; stesso stato → niente; **RollTransitionException** se non ammessa e senza `force`; **StateError** se il rullino non esiste |
| `markFinished` | `Future<void> markFinished(int id, CivilDate date)` | "Rullino terminato": `finishedAt = date` e, se `loaded`, → `exposed`; in un altro stato corregge solo la data. StateError se non esiste |
| `suggestedStatus` | `Future<RollStatus?> suggestedStatus(int rollId)` | `RollStatusMachine.suggestFrom` con sviluppo e stampe del rullino; null se non esiste |
| `deleteRollAndCollectImagePaths` | `Future<List<String>> deleteRollAndCollectImagePaths(int id)` | transazione: cancella (cascade su sviluppo, stampe, immagini) e restituisce i percorsi `path, thumbPath` di ogni immagine. ☠ **il chiamante cancella i file** |
| `watchRollItems` | `Stream<List<RollListItem>> watchRollItems({RollSection? section})` | si riemette a ogni modifica di `film_rolls`, `cameras`, `developments`, `print_orders`, `roll_images` |
| `rollItems` | `Future<List<RollListItem>> rollItems({RollSection? section})` | cinque query e un'unione in Dart, dal numero piu' alto |

⚑ **Cinque query e un'unione in Dart invece di un JOIN**: le stampe sono N per rullino, e un
JOIN moltiplicherebbe le righe. Con qualche centinaio di rullini costa nulla.
⚑ **Numerazione**: i buchi lasciati da rullini cancellati in mezzo restano buchi; il numero
dell'**ultimo** rullino, se cancellato, si riusa (`max + 1`, come dice il piano). Accettato: il
caso tipico e' il rullino creato per errore e cancellato subito.

**Sviluppo (uno per rullino)**

| Metodo | Firma | Effetto |
|---|---|---|
| `developmentFor` | `Future<Development?> developmentFor(int rollId)` | |
| `watchDevelopment` | `Stream<Development?> watchDevelopment(int rollId)` | |
| `saveDevelopment` | `Future<int> saveDevelopment({required int rollId, String? laboratory, CivilDate? submittedAt, CivilDate? returnedAt, int? developmentCostCents, int? scanCostCents, FilmProcess? process, bool selfDeveloped = false, String? note})` | `INSERT ... ON CONFLICT(film_roll_id) DO UPDATE` (`insertReturning`): crea o **sostituisce**; tutti i campi riscritti (null cancella il vecchio); restituisce l'id, **lo stesso** in caso di sostituzione. **Non** cambia lo stato del rullino. SqliteException se ritorno < consegna o rullino inesistente |
| `deleteDevelopment` | `Future<void> deleteDevelopment(int rollId)` | per id **del rullino** |

**Stampe (N per rullino)**

| Metodo | Firma | Effetto |
|---|---|---|
| `watchPrints` | `Stream<List<PrintOrder>> watchPrints(int rollId)` | **dalla consegna piu' vecchia** (l'ordine della timeline); senza data in fondo (`NullsOrder.last`), poi per id |
| `printsFor` | `Future<List<PrintOrder>> printsFor(int rollId)` | idem |
| `printById` | `Future<PrintOrder?> printById(int id)` | |
| `addPrintOrder` | `Future<int> addPrintOrder({required int rollId, String? laboratory, CivilDate? submittedAt, CivilDate? returnedAt, String? format, int? numberOfPrints, int? costCents, String? note})` | laboratorio, formato, nota vuoti → null |
| `updatePrintOrder` | `Future<void> updatePrintOrder(PrintOrder order)` | `replace` della riga intera (`filmRollId` compreso), vuoti → null |
| `deletePrintOrder` | `Future<void> deletePrintOrder(int id)` | |

**Laboratori**

| Metodo | Firma | Effetto |
|---|---|---|
| `watchLaboratories` | `Stream<List<String>> watchLaboratories()` | si riemette con `developments` e `print_orders` |
| `usedLaboratories` | `Future<List<String>> usedLaboratories()` | i nomi di sviluppi e stampe **dal piu' usato**; maiuscole e spazi non creano doppioni (grafia vista per prima); a parita' in ordine alfabetico. L'autocompletamento di F6.7 |

**Immagini**

| Metodo | Firma | Effetto |
|---|---|---|
| `watchImages` | `Stream<List<RollImage>> watchImages(int rollId)` | per `sort_order`, poi id |
| `imagesFor` | `Future<List<RollImage>> imagesFor(int rollId)` | idem |
| `addImage` | `Future<int> addImage({required int rollId, required StoredImage image, RollImageKind kind = RollImageKind.contactSheet})` | transazione: in fondo (`MAX(sort_order) + 1`); ⚑ **se il rullino non ha copertina, questa lo diventa** |
| `deleteImage` | `Future<StoredImage?> deleteImage(int id)` | cancella la riga e restituisce l'immagine da passare a `ImageStore.delete`; null se non c'era. Se era la copertina il rullino resta senza (setNull) |
| `reorderImages` | `Future<void> reorderImages(List<int> idsInOrder)` | transazione: `sort_order = indice` |
| `setCoverImage` | `Future<void> setCoverImage(int rollId, int? imageId)` | null la toglie; **ArgumentError** se l'immagine non e' di quel rullino |
| `allImagePaths` | `Future<Set<String>> allImagePaths()` | tutti i `path` e `thumbPath`: l'ingresso di `ImageStore.pruneOrphans` |

⚑ La prima immagine diventa copertina da sola: l'archivio e' l'identita' dell'app (F6.8), e un
rullino con le foto ma senza anteprima perche' l'utente non ha scelto sarebbe un difetto.

**Statistiche e segnali**

| Metodo | Firma | Effetto |
|---|---|---|
| `statsRolls` | `Future<List<StatsRoll>> statsRolls()` | da `rollItems()`; la data e' `loadedAt`, o il giorno (locale) di `createdAtUtc` se manca: un rullino senza data deve comunque cadere in un anno |
| `watchStatsRolls` | `Stream<List<StatsRoll>> watchStatsRolls()` | si riemette con `film_rolls`, `developments`, `print_orders` |
| `watchAnyChange` | `Stream<void> watchAnyChange()` | un segnale a ogni modifica di una delle sei tabelle (non usato, §14) |

Privati che contano: `_watchTables<T>(tables, load)` — ⚑ `tableUpdates` da solo **non emette il
primo valore**; un `customSelect('SELECT 1', readsFrom: tables)` si', quindi fa da innesco e poi
`asyncMap(load)`. `_blankToNull(String?)` (una nota di soli spazi e' "niente"),
`_requireNoDuplicateStock(brand, name, formatKey, {exceptId})` (confronto in Dart: `lower()` di
SQLite conosce solo l'ASCII), `_camerasQuery`, `_rollsQuery`, `_printsQuery`, `_printOrder`,
`_imagesQuery`, `_stocksQuery`, `_mostUsedQuery`, `_readStocks`, `_rollCountByCameraQuery`,
`_rollsCount`, `_toCountMap`, `_writeStatus`, `_nowMs()`, `static const _machine`.

### Classi di supporto (stesso file)

`@immutable class RollListItem` — un rullino con tutto quello che la sua card mostra.

| Membro | Firma | Significato |
|---|---|---|
| costruttore | `const RollListItem({required FilmRoll roll, Camera? camera, Development? development, List<PrintOrder> prints = const [], RollImage? cover})` | |
| campi | `final FilmRoll roll`, `final Camera? camera`, `final Development? development`, `final List<PrintOrder> prints` (dalla consegna piu' vecchia), `final RollImage? cover` | |
| `status` | `RollStatus get status` | `roll.statusEnum` |
| `section` | `RollSection get section` | `roll.section` |

`class DuplicateFilmStockException implements Exception` — `const DuplicateFilmStockException(this.existingId)`;
`final int existingId` (la pellicola gia' presente: la UI puo' selezionarla); `toString`.

`class RollTransitionException implements Exception` — `const RollTransitionException(this.from, this.to)`;
`final RollStatus from`, `final RollStatus to`; `toString` → `RollTransitionException(a -> b)`.

---

## 6. `lib/app/`

### `providers.dart` — i provider radice

⚑ Niente singleton globali: un provider si sostituisce nei test con un `override` e si
inizializza pigramente. Stesso schema di Scorte Calore, Full Freezer e TrashCan.

Da sovrascrivere in `main()`, altrimenti lanciano UnimplementedError: `appConfigProvider`,
`appPathsProvider`, `settingsProvider`.

| Provider | Tipo | Cosa espone | Dipende da |
|---|---|---|---|
| `appConfigProvider` | `Provider<MicroAppConfig>` | la configurazione | override in `main` |
| `appPathsProvider` | `Provider<AppPaths>` | cartelle dell'app | override |
| `settingsProvider` | `Provider<SettingsStore>` | preferenze (namespace `film_tracker`) | override |
| `todayProvider` | `Provider<CivilDate>` | "oggi"; **invalidato al resume** da `FilmTrackerApp` (i giorni in macchina e in laboratorio si contano in giorni) | |
| `themeModeProvider` | `NotifierProvider<ThemeModeNotifier, ThemeMode>` | il tema | `settingsProvider` |
| `databaseProvider` | `Provider<AppDatabase>` | apre alla prima lettura, chiude col ProviderScope | |
| `repositoryProvider` | `Provider<FilmRepository>` | | `databaseProvider` |
| `camerasProvider` | `StreamProvider<List<Camera>>` | **tutte** le macchine (attive e dismesse): l'inventario | repository |
| `activeCamerasProvider` | `StreamProvider<List<Camera>>` | solo le attive: la scelta nel form del rullino | repository |
| `cameraCountProvider` | `StreamProvider<int>` | il conteggio per `secondaryEntities` | repository |
| `rollCountByCameraProvider` | `StreamProvider<Map<int, int>>` | `cameraId → rullini` | repository |
| `filmStocksProvider` | `StreamProvider<List<FilmStock>>` | il catalogo per marca e nome | repository |
| `mostUsedStocksProvider` | `StreamProvider<List<FilmStock>>` | le cinque piu' usate (selezione rapida F6.4) | repository |
| `rollItemsProvider` | `StreamProvider.family<List<RollListItem>, RollSection>` | le card di una sezione della home, dal numero piu' alto | repository |
| `allRollItemsProvider` | `StreamProvider<List<RollListItem>>` | tutti i rullini (**non usato**, §14) | repository |
| `rollProvider` | `StreamProvider.family<FilmRoll?, int>` | un rullino per id; null se cancellato | repository |
| `developmentProvider` | `StreamProvider.family<Development?, int>` | lo sviluppo, per id del rullino | repository |
| `printsProvider` | `StreamProvider.family<List<PrintOrder>, int>` | le stampe, per id del rullino | repository |
| `rollImagesProvider` | `StreamProvider.family<List<RollImage>, int>` | le immagini, per id del rullino | repository |
| `laboratoriesProvider` | `StreamProvider<List<String>>` | laboratori gia' usati, dal piu' frequente | repository |
| `statsRollsProvider` | `StreamProvider<List<StatsRoll>>` | gli ingressi delle statistiche | repository |
| `statsYearsProvider` | `Provider<List<int>>` | anni con rullini, dal piu' recente (`[]` finche' non arriva lo stream) | `statsRollsProvider` |
| `yearStatsProvider` | `Provider.family<YearStats?, int>` | le statistiche di un anno; null finche' i dati non sono arrivati | `statsRollsProvider` |

`class ThemeModeNotifier extends Notifier<ThemeMode>` — `ThemeMode build()`: `'light'` → light,
`'dark'` → dark, `'system'` → system, **qualunque altra cosa (anche assente) → dark**;
`Future<void> set(ThemeMode mode)` salva `mode.name` in `SettingKeys.themeMode`.
⚑ **Scuro di default** (F6.1): le foto su fondo chiaro perdono contrasto e l'occhio le confronta
col bianco della pagina invece che fra loro. Il chiaro resta disponibile e curato.

Altri provider fuori da questo file: `installIdProvider`, `purchaseGatewayProvider`,
`entitlementProvider`, `isProProvider`, `featureGateProvider` (`entitlement.dart`);
`imageStoreProvider` (`features/photos/image_store_provider.dart`); `imagePickerProvider`
(`photo_actions.dart`); `photoStorageBytesProvider` (`photo_storage_tile.dart`);
`backupServiceProvider` (`features/settings/data_section.dart`).

☠ **Riverpod 3 mette in pausa i provider che nessuno ascolta**: `ref.read(xProvider.future)` di
uno stream non ascoltato resta in caricamento per sempre, e `ref.read(x).value` e' null. Per
questo chi deve leggere un dato "adesso" da una pagina che non lo ascolta chiede **al
repository** (`openNewCamera` → `cameraCount()`, `createYearReport` → `statsRolls()`).

### `entitlement.dart` — il Pro

| Simbolo | Firma / tipo | Significato |
|---|---|---|
| `appVersion` | `const String appVersion = '1.0.0'` | **un posto solo**: backup, server licenze, impostazioni. Va tenuta uguale al versionName di `pubspec.yaml` |
| `installIdProvider` | `FutureProvider<InstallId>` | `InstallId.load(appId:)` |
| `purchaseGatewayProvider` | `Provider<PurchaseGateway>` | `BillingMode.store` → StorePurchaseGateway; `BillingMode.fake` → FakePurchaseGateway **senza Pro**, prodotto a `'4,99 €'` (lo screenshot del paywall per Apple viene da qui) |
| `entitlementProvider` | `NotifierProvider<EntitlementNotifier, EntitlementView>` | `.notifier.service` per le azioni |
| `isProProvider` | `Provider<bool>` | |
| `featureGateProvider` | `Provider<FeatureGate>` | `FeatureGate(limits: filmFeatureLimits, isPro: ...)` |

`@immutable class EntitlementView` — `const EntitlementView({required Entitlement entitlement, required bool busy, required bool storeAvailable, MicroProduct? product, MicroError? error})`;
getter `bool get isPro`, `bool get isPending`; `==` confronta entitlement, busy, store, id e
prezzo del prodotto, codice d'errore; `hashCode`. ⚑ Un valore immutabile dietro un Notifier e
non il ChangeNotifier del servizio: Riverpod 3 ha spostato ChangeNotifierProvider fra le API
legacy.

`class EntitlementNotifier extends Notifier<EntitlementView>` — `EntitlementView build()` crea
l'EntitlementService di micro_core con `appId: licenseAppId` (file `entitlement.json` in
`support`; LicenseApiClient solo se `serverEnabled` e l'id d'installazione c'e', altrimenti id
fisso tutto zeri), si iscrive ai cambiamenti e **avvia da solo il bootstrap** (dimenticarlo =
un'app che non si accorge di un acquisto gia' fatto); getter `EntitlementService get service`.
Privati `_sync()`, `static _snapshot(EntitlementService)`.

☠ **Debito aperto, ormai a quattro copie** (TrashCan, Full Freezer, Scorte Calore, Film
Tracker): `EntitlementView` e `EntitlementNotifier` vanno spostati in `micro_core` **in F7**
(§14).

### `feature_limits.dart`

`const FeatureLimits filmFeatureLimits` — la mappa di §10. Nessuna pagina scrive `if (isPro)`:
si passa da `featureGateProvider`.

### `paywall_config.dart`

| Funzione | Firma |
|---|---|
| `buildFilmPaywall` | `PaywallConfig buildFilmPaywall(L l)` — testi, `productUnavailableLabel` e `retryLabel` (mai la rotellina eterna), `oneTimeNotice` = `paywall_subhead`, 5 benefici |
| `showFilmPaywall` | `Future<bool> showFilmPaywall(BuildContext context, WidgetRef ref, {FeatureKey? highlight})` — PaywallPage.show; `true` se si esce col Pro |

Benefici, in quest'ordine (⚑ quello che vende: quanto spendi in pellicola e laboratorio e' la
domanda che chi scatta in analogico si fa): `statistics`, `pdfReport`, `secondaryEntities`,
`backupRestore`, `csvExport`.

### `app_config.dart`

| Simbolo | Firma | Significato |
|---|---|---|
| `licenseAppId` | `const String licenseAppId = 'filmtracker'` | chiave della tabella `apps` e di APP_SECRETS sul License Server |
| `buildFilmConfig` | `MicroAppConfig buildFilmConfig()` | `MicroAppConfig.fromEnvironment(appId: 'film_tracker', appName: 'Film Tracker', proSku: 'filmtracker_pro_lifetime', seedColor: Color(0xFFE0A458), fontFamily: 'PlusJakartaSans', defaultBrightness: Brightness.dark)` |

☠ **`licenseAppId` non e' `appId`**: `appId` (`film_tracker`) nomina cartelle e preferenze; il
server usa gli id senza trattino basso. Mandare l'id locale fa rifiutare ogni verifica d'acquisto
come "app sconosciuta" (pagato con Full Freezer).
⚑ Il seme `#E0A458` e' quello del piano (§2). Conta poco: `withFilmLook` sovrascrive primario,
secondario, terziario e superfici con la palette (vedi sotto); dal seme restano solo i ruoli che
la palette non tocca (errore, `secondaryContainer`, `inverse*`...).
⚑ `fontFamily: 'PlusJakartaSans'` (il piano diceva Inter + Fraunces: superato con «C ·
Provino»). Space Mono non e' il font del tema: lo usa solo `FilmPalette.edgeText`.

### `film_palette.dart` — interfaccia «C · Provino»

| Simbolo | Firma | Significato |
|---|---|---|
| `kEdgeFont` | `const String kEdgeFont = 'SpaceMono'` | il carattere a bordo pellicola (SIL OFL, `assets/fonts/OFL-SpaceMono.txt`) |

`@immutable class FilmPalette extends ThemeExtension<FilmPalette>` — costruttore const con
tutti i campi `required` (tipo Color):

| Campo | Scuro (default) | Chiaro "tavolo luminoso" | Uso |
|---|---|---|---|
| `ground` | `#0D0C0B` | `#F4EFE6` | fondo della pagina: il nero fra un fotogramma e l'altro; anche il colore dei fori |
| `strip` | `#1A1714` | `#FFFFFF` | la pellicola: schede, strisce, foglio provini |
| `stripRaised` | `#24201C` | `#EDE6DA` | superfici rialzate, contenitori primari |
| `ink` / `inkMuted` | `#EDE6DA` / `#B3AA9C` | `#1E1A16` / `#5F574D` | testo |
| `inkFaint` | `#8D857A` | `#7A7064` | etichette di sezione ("IN MACCHINA"), `outline` |
| `edge` / `onEdge` | `#F0A33B` / `#0D0C0B` | `#A85A06` / `#FFFFFF` | l'arancio della scritta a bordo: numeri, giorni, pulsante principale |
| `border` | `#2E2A26` | `#DCD3C5` | bordi, divisori, `outlineVariant` |

⚑ **Tema chiaro "tavolo luminoso"**: il fondo e' il bianco caldo della luce sotto i negativi;
l'arancio si scurisce (`#A85A06`) per restare leggibile sul chiaro (contrasto 4,5:1). Il
segnaposto dei rullini (FilmStripPlaceholder) resta scuro anche qui: un negativo e' scuro anche
sul tavolo luminoso.

| Membro | Firma | Effetto |
|---|---|---|
| `dark`, `light` | `static const FilmPalette dark`, `static const FilmPalette light` | |
| `of` | `static FilmPalette of(BuildContext context)` | ripiega su `dark` (il default dell'app) |
| `edgeText` | `TextStyle edgeText({double size = 11, Color? color, FontWeight weight = FontWeight.w400})` | Space Mono, colore `edge` di default, altezza 1.2; spaziatura `size × 0,18`, ma **`size × 0,04` da 16 pt in su** |
| `copyWith` | `FilmPalette copyWith()` | restituisce se stessa |
| `lerp` | `FilmPalette lerp(ThemeExtension<FilmPalette>? other, double t)` | scatta a meta' |

☠ Spaziatura ridotta nei numeri grandi: la stessa spaziatura staccava "12 GG" in cinque pezzi
(visto sull'emulatore il 2026-10-08).

Funzione `ThemeData withFilmLook(ThemeData base, FilmPalette p)` — il tema Material vestito da
pellicola:
- **ColorScheme**: `primary`/`secondary`/**`tertiary`** = `edge` (con `on*` = `onEdge`),
  `primaryContainer`/`tertiaryContainer` = `stripRaised` (con `on*Container` = `edge`),
  `surface` = `ground`, `onSurface` = `ink`, `onSurfaceVariant` = `inkMuted`,
  `surfaceContainerLowest` = `ground`, `surfaceContainerLow`/`surfaceContainer` = `strip`,
  `surfaceContainerHigh`/`surfaceContainerHighest` = `stripRaised`, `outline` = `inkFaint`,
  `outlineVariant` = `border`;
- `scaffoldBackgroundColor`, `canvasColor` = `ground`; AppBar su `ground` senza tinta;
  schede (`cardTheme`) su `strip` con **angoli di 6 px**; bottom sheet e dialoghi su `strip`;
  FilledButton e FAB arancio con angoli di 10; divisori `border`; l'estensione aggiunta.

⚑ **Qui, a differenza di Scorte Calore, la palette cambia anche il ColorScheme**: in «A ·
Brace» la testata blu notte era un'isola in un'app Material normale; in «C · Provino» tutta
l'app e' una striscia di pellicola nera con l'arancio della scritta a bordo, quindi pulsanti,
campi e chip devono prendere gli stessi colori e non quelli che Material ricaverebbe dal seme.
⚑ **Anche il terziario**: Material lo ricava **azzurro** dal seme, e il chip dell'ISO "tirato"
(push/pull, `tertiaryContainer`) usciva celeste in mezzo all'arancio (emulatore, 2026-10-08).
⚑ Angoli piccoli: la pellicola e' tagliata dritta.

### `labels.dart` — i nomi visibili

⚑ Il dominio conosce solo le chiavi stabili; i nomi stanno qui perche' cambiano con la lingua.
Gli switch sono **esaustivi di proposito**: un valore nuovo in un enum non compila finche' non ha
la sua etichetta.

| Funzione | Firma | Effetto |
|---|---|---|
| `statusName` | `String statusName(L l, RollStatus s)` | `l.status_<key>` ("In macchina", "In laboratorio"...) |
| `formatName` | `String formatName(L l, FilmFormat f)` | `l.roll_format_<valore>` ("35 mm", "Medio formato 120") |
| `processName` | `String processName(L l, FilmProcess p)` | `l.roll_process_<valore>` ("C-41", "Bianco e nero") |
| `formatDay` | `String formatDay(L l, CivilDate d)` | `DateFormat.yMMMd`: "8 ott 2026" / "Oct 8, 2026" |
| `formatMonth` | `String formatMonth(L l, CivilDate d)` | `DateFormat.yMMM`: "ott 2026" |
| `formatPeriod` | `String? formatPeriod(L l, CivilDate? from, CivilDate? to)` | "set 2026" o "set 2026 – ott 2026"; null senza date |
| `formatCents` | `String formatCents(L l, int cents)` | `Money.cents(cents).format(locale:)`: "8,50 €" (con spazio indivisibile prima di €) |

### `locale_resolution.dart`

`const List<Locale> kSupportedLocales = [Locale('en'), Locale('it')]` — **inglese per primo**
(Flutter ripiega sul primo). `Locale resolveAppLocale(List<Locale>? deviceLocales, Iterable<Locale> supported)`
— italiano se `it` compare fra le preferenze, altrimenti inglese (ADR-011).

---

## 7. Le rotte

Dichiarate in `lib/app/routes.dart` (`abstract final class Routes`), registrate in
`buildRouter` (`lib/app/app.dart`): `GoRouter buildRouter(WidgetRef ref)`, `initialLocation: Routes.home`.
⚑ `go_router` e non Navigator imperativo (ADR-005): il QR apre una pagina con un percorso.
⚑ I percorsi sono stati fissati tutti insieme prima delle schermate (2026-10-08) perche' tre
parti dell'app le scrivevano in parallelo.

| Costante | Percorso | Pagina | Parametri | Gate Pro |
|---|---|---|---|---|
| `Routes.home` | `/` | `HomePage` | | |
| `Routes.settings` | `/settings` | `SettingsPage` | | (le voci Pro dentro: §9) |
| `Routes.rollNew` | `/rolls/new` | `RollEditorPage()` | | gratis (rullini illimitati) |
| `Routes.roll` | `/rolls/:rollId` | `RollDetailPage(rollId:)` | `rollId` | |
| `Routes.rollEdit` | `/rolls/:rollId/edit` | `RollEditorPage(rollId:)` | `rollId` | |
| `Routes.development` | `/rolls/:rollId/development` | `DevelopmentPage(rollId:)` | `rollId` | |
| `Routes.printNew` | `/rolls/:rollId/prints/new` | `PrintPage(rollId:)` | `rollId` | |
| `Routes.printEdit` | `/rolls/:rollId/prints/:printId` | `PrintPage(rollId:, printId:)` | `rollId`, `printId` | |
| `Routes.photo` | `/rolls/:rollId/photos/:imageId` | `PhotoViewerPage(rollId:, imageId:)` | `rollId`, `imageId` | gratis (F6.0 punto 3) |
| `Routes.qr` | `/rolls/:rollId/qr` | `QrPage(rollId:)` | `rollId` | gratis (F6.12) |
| `Routes.cameras` | `/cameras` | `CamerasPage` | | |
| `Routes.cameraNew` | `/cameras/new` | `NewCameraGate` → `ProGate(secondaryEntities, allowed: withinLimit(conteggio all'apertura))` → `CameraEditorPage()` | | **una macchina gratis**: `openNewCamera` all'ingresso **e** `NewCameraGate` sulla pagina |
| `Routes.cameraEdit` | `/cameras/:cameraId` | `CameraEditorPage(cameraId:)` | `cameraId` | |
| `Routes.stocks` | `/stocks` | `StocksPage` | | |
| `Routes.stats` | `/stats` | `StatsPage` → `ProGate(statistics)` | | **Pro**: `openStats` (paywall all'ingresso, dalle impostazioni) **e** `ProGate` |

Helper: `static String rollOf(int id)`, `rollEditOf(int id)`, `developmentOf(int rollId)`,
`printNewOf(int rollId)`, `printEditOf(int rollId, int printId)`, `photoOf(int rollId, int imageId)`,
`qrOf(int rollId)`, `cameraEditOf(int id)`. Costante `static const String scheme = 'filmtracker'`
(letta da `rollQrData` e `sequenceFromUri`).

Privata `int _id(GoRouterState s, String name)` — `int.tryParse(...) ?? -1`.
☠ `tryParse` e non `parse`: un link scritto a mano con un id non numerico darebbe un'eccezione
nel builder. ☠ Per stampe e macchine **-1 e non null**: null vuol dire "nuova", e per le
macchine aggirerebbe il paywall.
⚑ `rolls/new` prima di `rolls/:rollId`, `prints/new` prima di `prints/:printId`, `cameras/new`
prima di `cameras/:cameraId`: go_router prova le rotte in ordine.
⚑ **Nessun redirect**: niente onboarding (la home vuota e' gia' l'invito), e il Pro si controlla
sulla pagina. ☠ Un `push` che redireziona a "/" mette "/" due volte nella pila e go_router
mostra la sua pagina d'errore (Full Freezer, 2026-10-07).

### Chi apre l'app su una pagina

| Sorgente | URI | Arriva a | Codice |
|---|---|---|---|
| Lettore di QR di sistema (o un link) | `filmtracker://roll/<sequenceNumber>` | `push(Routes.rollOf(id))` sopra la home: la freccia indietro torna alla home | `FilmTrackerApp.initState` → `listenRollLinks` |

`FilmTrackerApp` (`class FilmTrackerApp extends ConsumerStatefulWidget`, `const FilmTrackerApp({Key? key})`):

- `late final GoRouter _router = buildRouter(ref)`;
- al **resume** (AppLifecycleListener): `invalidate(todayProvider)`;
- **link del QR**: `_links = listenRollLinks(links: AppLinks().uriLinkStream, repository: () => ref.read(repositoryProvider), open: (location) => _router.push(location))`;
  cancellato in `dispose` insieme al lifecycle e al router;
- `build`: `MaterialApp.router` con `withFilmLook(MicroTheme.light(...), FilmPalette.light)` e
  `withFilmLook(MicroTheme.dark(...), FilmPalette.dark)` (variante `DynamicSchemeVariant.fidelity`),
  `themeModeProvider`, `kSupportedLocales`, i quattro delegati (L, Material, Widgets, Cupertino),
  `localeListResolutionCallback: resolveAppLocale`.

☠ **Il deep link di Flutter e' spento** su entrambe le piattaforme
(`flutter_deeplinking_enabled=false` nel manifest, `FlutterDeepLinkingEnabled=false` in
`Info.plist`): acceso, Flutter passa l'URI a go_router come `go`, che **sostituisce la pila**
e la freccia indietro sparisce (pagato con Full Freezer). ⚑ Il plugin **`app_links`** riceve
l'URI e l'app sceglie `push`. **Provato con adb** sull'emulatore
(`adb shell am start -a android.intent.action.VIEW -d filmtracker://roll/<n>`).
⚑ `uriLinkStream` (da app_links 6) consegna **anche** il link che ha aperto l'app da chiusa:
non si chiama `getInitialLink`, che lo consegnerebbe due volte.
☠ `MainActivity.onNewIntent` fa `setIntent(intent)`: un link aperto con l'app chiusa ma nei
recenti farebbe ricreare l'attivita' con l'intent **vecchio** del launcher (Full Freezer).

---

## 8. `lib/services/`

### `csv_export.dart` — il CSV dei rullini (F6.11, Pro, `FeatureKey.csvExport`)

| Funzione | Firma | Effetto |
|---|---|---|
| `exportRollsCsv` | `Future<File> exportRollsCsv({required AppPaths paths, required L l, required List<RollListItem> items, required CivilDate today})` | scrive `exports/film-tracker-<YYYY-MM-DD>.csv` |
| `buildRollsCsv` | `CsvWriter buildRollsCsv({required L l, required List<RollListItem> items})` | il contenuto, senza disco; righe **dal numero piu' basso** |

25 colonne (`csv_*`): Numero, Titolo, Pellicola, Formato, ISO nominale, ISO di esposizione,
Macchina, Stato, Caricato, Terminato, Fotogrammi, Costo pellicola (€), Laboratorio sviluppo,
Consegnato al laboratorio, Ritirato dal laboratorio, Processo, Sviluppato in casa ("Sì"/"No"),
Costo sviluppo (€), Costo scansioni (€), Ordini di stampa, Copie stampate, Laboratori stampa,
Costo stampe (€), Costo totale (€), Nota.

Privati: `_euros(int?)` (centesimi in "6,50" **dagli interi**, mai da un double: 650/100 puo'
dare 6.499999), `_formatName`, `_processName`, `_statusName` (una chiave sconosciuta finisce nel
foglio cosi' com'e').

⚑ **Una riga per rullino**, non una per evento come in Scorte Calore: l'unita' che l'utente
ragiona e' il "#17"; sviluppo (uno) e stampe (N) ne sono attributi. Le stampe si riassumono in
quattro colonne (ordini, copie solo se almeno un ordine le dice, laboratori senza doppioni di
maiuscole, costo solo se almeno un ordine ce l'ha): una colonna per ordine renderebbe il numero
di colonne variabile, ed Excel non sa sommare una colonna che cambia posto.
⚑ Separatore `;` e BOM UTF-8 (CsvWriter): Excel in italiano lo apre con un doppio clic.
⚑ **I numeri sono numeri** ("6,50" senza simbolo, ISO e fotogrammi interi); le date restano ISO
(`2026-09-01`): Excel le riconosce in qualunque lingua, "1 set 2026" no.
⚑ **Costo totale vuoto (non 0)** per un rullino senza nessun costo: non e' "gratis", e' "non
saputo" (stessa regola di `StatsRoll.hasAnyCost`).
☠ Le chiavi sconosciute non fanno fallire l'export: il CSV e' un'uscita, non deve essere il
punto in cui l'app si rompe.

### `film_backup_source.dart` — backup e ripristino **con le foto** (F6.11)

`class FilmBackupSource implements BackupSource` — `const FilmBackupSource(AppDatabase db, {AppPaths? paths, DateTime Function()? clock})`;
campi `final AppDatabase db`, `final AppPaths? paths` (per cancellare i file orfani dopo un
"sostituisci tutto"; null nei test che provano solo il database), `final DateTime Function()? clock`
(l'ora usata quando il file non porta una data).

| Membro | Firma | Effetto |
|---|---|---|
| `id` | `static const String id = 'film_tracker'` | riconosce i backup dell'app prima di chiedere come ripristinarli |
| `schemaId` | `String get schemaId` → `id` | |
| `schemaVersion` | `int get schemaVersion` → `1` | |
| `exportPayload` | `Future<Map<String, Object?>> exportPayload()` | vedi la forma sotto |
| `imagePaths` | `Future<List<String>> imagePaths()` | `path` e `thumbPath` di ogni immagine (per id): BackupService li mette nello ZIP sotto `images/` e salta quelli il cui file manca |
| `counts` | `Future<Map<String, int>> counts()` | `rolls`, `cameras`, `images` (il riepilogo `backup_restoreSummary`) |
| `importPayload` | `Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode})` | in una transazione; vedi sotto |

Il file e' lo ZIP di `BackupService.createBackup(includeImages: true)`: `data.json` col payload,
piu' `images/<percorso relativo>` per ogni foto e miniatura. Al ripristino BackupService chiama
prima `importPayload` e poi scrive i file **agli stessi percorsi relativi**: per questo il
payload conserva `path` e `thumbPath` tali e quali (sono UUID: non si scontrano fra telefoni).

Forma del payload:

```
cameras: [{ref, manufacturer, model, format, note, active, sortOrder}]   anche le dismesse
stocks:  [{brand, name, iso, process, format}]                          solo le personalizzate
rolls:   [{sequenceNumber, stock:{brand,name,format}?, filmName, format, nominalIso,
           exposedIso, camera:ref?, loadedAt, finishedAt, frames, title, note, status,
           costCents, createdAt,
           development:{laboratory, submittedAt, returnedAt, developmentCostCents,
                        scanCostCents, process, selfDeveloped, note}?,
           prints:[{laboratory, submittedAt, returnedAt, format, numberOfPrints, costCents, note}],
           images:[{path, thumbPath, width, height, bytes, kind, sortOrder, createdAt, cover}]}]
```

`importPayload`:
- `ImportMode.replaceAll`: raccoglie i percorsi di tutte le immagini attuali, cancella rullini
  (cascade su sviluppi, stampe, righe delle immagini), macchine e pellicole personalizzate,
  rilancia `seedCatalog`, poi mette quelle del file **con i loro numeri**;
- `ImportMode.mergeKeepExisting`: aggiunge cio' che manca —
  * un rullino **gia' presente** (stesso `createdAt` e stesso `filmName`) si salta con tutto
    quello che contiene (lo stesso backup due volte non duplica niente);
  * un rullino nuovo tiene il suo numero se e' libero, altrimenti prende il primo libero dopo il
    massimo. ⚑ **Due passate**: prima si riservano i numeri liberi, poi chi ha il numero occupato
    va dopo il massimo; in una passata sola un numero occupato all'inizio spingerebbe a cascata
    tutti gli altri (#1 → 2, #2 → 3...) e ogni etichetta QR diventerebbe sbagliata;
  * una macchina con lo stesso produttore e modello (a meno di maiuscole e spazi) e' la stessa: i
    rullini del file si attaccano a quella del telefono, le nuove vanno in fondo;
  * una pellicola personalizzata gia' presente (marca, nome, formato) non si duplica;
- la copertina si **ricuce** dopo aver inserito le immagini (`cover: true` → `coverImageId`);
- solo a transazione riuscita e con `replaceAll`: si cancellano i file delle foto che il backup
  **non** riporta (se un file non si cancella resta orfano per `pruneOrphans`).

Privati: `_importCameras(...)` (`ref del file → id sul telefono`), `_importStocks`,
`_importDevelopment`, `static _findStock`, `static _matchStock`, `static _formatKey`,
`static _statusKey`, `static _date` (valida `YYYY-MM-DD`), `static _imagePath`, `static _list`.

⚑ **Sviluppo, stampe e immagini annidati nel rullino** (come le altre app): gli id di riga non
significano niente su un altro telefono. Le macchine invece sono condivise da molti rullini:
viaggiano con un `ref` (l'id di partenza) che vale **solo dentro il file**.
⚑ **La pellicola si riconosce da marca, nome e formato**, non dall'id: l'id del catalogo dipende
dall'ordine di caricamento, la tripla no (e' la UNIQUE). Del catalogo si esportano solo le
personalizzate.
⚑ **Il limite di una macchina non si applica al ripristino**: e' gratis e riporta i dati come
erano; il limite ferma la creazione di una macchina nuova, non la restituzione.
☠ **"Sostituisci tutto" cancella anche i file delle foto che il backup non riporta**: il cascade
toglie le righe, non i file. Si cancellano **dopo** la transazione e solo quelli che il file non
riscrivera': ripristinare sullo stesso telefono il backup di ieri non deve far sparire foto che
BackupService sta per riscrivere identiche.
☠ **Percorsi d'immagine validati** (`_imagePath`): devono cominciare con `images/` e non contenere
`..`, `\` o `:`. Un backup e' un dato esterno: un percorso fuori dalla cartella, scritto nel
database, farebbe leggere (e cancellare, con "sostituisci tutto") un file fuori dall'app.
☠ **Zip slip corretto in `micro_core`** (2026-10-08, `BackupService._restoreImages`): le voci
dello ZIP il cui nome normalizzato esce dalla cartella documenti (`images/../../shared_prefs/x.xml`
o assolute) si scartano con un avviso nel log. Era un difetto del ripristino di tutte le app,
emerso con le foto di Film Tracker; il test sta in `micro_core`.
☠ **Date validate** (`_date`): una data scritta male passerebbe il vincolo di lunghezza e
romperebbe in silenzio i confronti dello schema.
☠ `importPayload` lancia **FormatException, mai un Error**: un TypeError da un cast viene
convertito, perche' `BackupService.restore` intercetta solo le Exception e altrimenti
arriverebbe come crash invece che come "file rovinato". La transazione e' gia' annullata.

### `year_report.dart` — il PDF di riepilogo annuale (F6.11, Pro, `FeatureKey.pdfReport`)

Una **copertina** (l'anno, rullini e fotogrammi potenziali, la spesa per voce, le medie col costo
per fotogramma dichiarato stima, i piu' usati, l'indice dei rullini) e poi **una pagina per
rullino** (numero, titolo, pellicola · formato · ISO · fotogrammi · macchina, nota, la timeline
con le date, i costi con il totale, la griglia delle foto a tre colonne). Piede: "Film Tracker ·
anno · pagina/pagine". A4, fondo bianco.

`@immutable class YearReportRoll` — `const YearReportRoll({required RollListItem item, List<RollImage> images = const []})`;
`final RollListItem item`, `final List<RollImage> images` (nell'ordine dell'utente).

| Funzione | Firma | Effetto |
|---|---|---|
| `reportDateOf` | `CivilDate reportDateOf(FilmRoll roll)` | `loadedAt`, o il giorno locale di creazione. ⚑ **la stessa regola di `FilmRepository.statsRolls`**: copertina e statistiche devono contare gli stessi rullini |
| `rollsOfYear` | `List<RollListItem> rollsOfYear(Iterable<RollListItem> items, int year)` | i rullini dell'anno, **dal numero piu' basso** (si sfoglia come un quaderno) |
| `loadReportFont` | `Future<pw.Font> loadReportFont()` | `assets/fonts/PlusJakartaSans-Variable.ttf` via rootBundle |
| `buildYearReportDocument` | `Future<pw.Document> buildYearReportDocument({required L l, required YearStats stats, required List<YearReportRoll> rolls, required pw.Font font, required Future<Uint8List?> Function(String relativePath) readImage, required CivilDate today, String? topCameraName})` | il documento; separato perche' i test contino le pagine (`doc.document.pdfPageList.pages`) |
| `buildYearReport` | `Future<Uint8List> buildYearReport({...stessi parametri...})` | `buildYearReportDocument(...).save()`: i byte da stampare o condividere |

`readImage` riceve un percorso relativo (`RollImage.thumbPath`) e restituisce i byte o null: una
foto sparita diventa un riquadro vuoto, **mai un PDF che fallisce**.

Privati: `_margin` (40/44/40/36), colori `_ink #1E1B18`, `_muted #6B6259`, `_accent #B5782A`,
`_rule #E4DDD3`, `_cell #F3EFE9`; `_theme(font)`, `_t(String)`, `_text`, `_footer`,
`_sectionTitle`, `_row(label, value, {strong})`, `_cover`, `_ranked`, `_rollPage`,
`_formatLabel`, `_grid(images)`.

⚑ **Il PDF vive nell'app e non in `micro_core`** — debito **DT-10 chiuso cosi'**: il debito
diceva di costruire PdfReportBuilder "quando si sa che forma deve avere il riepilogo". Scritto,
la forma e' tutta di Film Tracker (rullini, timeline, foto); le altre tre app non hanno un PDF e
non ne avranno (F6.11). Un builder generico oggi sarebbe un'astrazione con un utente solo; il
giorno che servisse a una seconda app, si estraggono pagina, tema e piede (`_theme`, `_footer`).
⚑ **Il carattere e' Plus Jakarta Sans Regular, senza grassetto**: il pacchetto `pdf` non sa
istanziare un font variabile, ma il file ha i contorni `glyf` dell'istanza di default, che e' il
peso 400 (verificato con fontTools: asse `wght` 200-800, default 400). Letto cosi' e' un Regular
con accenti, `€`, virgolette tipografiche e `≈`. Il grassetto non esiste (servirebbe
un'istanza statica): la gerarchia si fa con **corpo e colore**, e il tema usa lo stesso file per
`bold`, `italic` e `boldItalic` perche' uno stile non ricada sull'Helvetica senza accenti.
☠ **Helvetica (il font di base del PDF) non va**: e' in codifica WinAnsi, e senza un TTF
incorporato `pdf` disegna i caratteri fuori codifica come quadrati o lancia ("quest’anno" ha gia'
l'apostrofo tipografico).
☠ **U+202F (spazio stretto indivisibile) non e' nel font** e `intl` lo usa in alcune lingue fra
numero e simbolo: **ogni testo passa da `_t`, che lo sostituisce con U+00A0**.
⚑ **Le foto sono le miniature** (400 px): in una griglia a tre colonne su A4 una cella e' ~5,5 cm,
cioe' ~180 dpi, abbastanza per la stampa; con le grandi un anno da 100 rullini peserebbe quasi
100 MB. Il test controlla che si leggano solo percorsi `images/thumbs/`.
⚑ **Un MultiPage per rullino** e non un Page: ogni rullino comincia su una pagina sua, ma uno con
venti foto continua sulla successiva invece di far fallire il documento. La griglia e' **una
riga di tre alla volta** (ogni riga un figlio del MultiPage): il salto pagina cade fra due righe e
non taglia una foto.
⚑ Fondo bianco anche se l'app e' scura: e' carta, e un fondo scuro stampato consuma una cartuccia.

---

## 9. `lib/features/` — le schermate

### Home — `features/home/home_page.dart`

`class HomePage extends ConsumerWidget` — `const HomePage({Key? key})`. «C · Provino», tre
sezioni in **una sola pagina che scorre** (i rullini in macchina e in laboratorio sono pochi,
l'archivio sotto e' quello che si vuole vedere):

- testata (privata `_Header`): scritta a bordo `home_overline(totale)` ("▸ FILM TRACKER · 12
  RULLINI"), titolo `home_title` a 28 pt, due quadrati 44x44: menu (`home_menuMore`: Macchine →
  `Routes.cameras`, Pellicole → `Routes.stocks`, Statistiche → `Routes.stats`, che senza Pro
  mostra il lucchetto) e Impostazioni;
- **In macchina** (`_InCameraStrip`): ogni rullino e' una `FilmStrip` con la scritta a bordo
  `edgeLabelOf`, titolo (o pellicola), "macchina · Caricato N giorni fa" (`home_loadedDaysAgo`) e
  i giorni in arancio monospaziato (`home_daysShort`, "12 GG"); un rullino `exposed` dice
  `home_finishedToDeliver` e mostra il furgone invece del numero;
- **In laboratorio** (`_AtLabRow`): righe compatte "pellicola · titolo · laboratorio" con i
  giorni d'attesa, **chi aspetta da piu' tempo in cima**, senza data di consegna in fondo ("—");
  Semantics con la frase intera (`home_deliveredDaysAgo`, "Ilford HP5+ — consegnato 10 giorni fa");
- **Archivio · provino** (`_ContactSheet`): foglio provini a **tre colonne**, ogni fotogramma
  (`_Frame`) con la copertina 4:3 (`RollCover`) e "▸ 4 PRAGA"; vuoto → due `_PlaceholderFrame`
  (striscia disegnata, opacita' 0,7);
- sezione vuota accanto a piene: una riga d'invito (`home_inCameraEmpty`, `home_atLabEmpty`,
  `home_archiveEmpty`); **tutto vuoto**: un MicroEmptyState solo (`home_emptyTitle`,
  `home_emptyAction` → `Routes.rollNew`), non tre sezioni vuote che sembrano un'app rotta;
  errore → MicroEmptyState con "Riprova" (invalida `rollItemsProvider`);
- in fondo, fisso, il pulsante largo **"NUOVO RULLINO"** (56 pt, `home_newRoll`) → `Routes.rollNew`.

| Funzione | Firma | Effetto |
|---|---|---|
| `waitingDays` | `@visibleForTesting int? waitingDays(RollListItem item, CivilDate today)` | giorni dalla consegna dello sviluppo (`submittedAt`), mai negativi; null senza data |
| `edgeLabelOf` | `@visibleForTesting String edgeLabelOf(FilmRoll roll)` | "ILFORD HP5+ 400 ▸ 12": l'ISO di esposizione si aggiunge **solo se non e' gia' nel nome** o se il rullino e' tirato/trattenuto |

⚑ Ogni sezione ha il suo stream (`rollItemsProvider(section)`): un rullino che cambia stato passa
da una sezione all'altra da solo.
☠ "Kodak Portra 400" diventava "PORTRA 400 400" (emulatore, 2026-10-08): da qui la regola
dell'ISO nel nome (regex sul numero intero).

### La pellicola disegnata — `features/common/film_strip.dart`

⚑ **Disegnati con widget e non con un'immagine**: si adattano alla larghezza, ai due temi e al
carattere ingrandito dell'utente senza sgranarsi (testo al 130% provato).

| Classe | Costruttore | Cosa disegna |
|---|---|---|
| `SprocketRow` | `const SprocketRow({Key? key})` | una fila di perforazioni (14x8, passo 24, raggio 2) del colore `ground` lungo tutta la larghezza (1..60 fori), esclusa dalla semantica |
| `FilmStrip` | `const FilmStrip({required Widget child, String? edgeText, VoidCallback? onTap, String? semanticLabel, Key? key})` | la striscia su `strip` (angoli 6): perforazioni sopra e sotto, `child`, la scritta a bordo (`EdgeText` a 10 pt) sopra la fila in basso; InkWell e Semantics bottone |
| `EdgeText` | `const EdgeText(String text, {double size = 11, Color? color, bool bold = false, int maxLines = 1, Key? key})` | la scritta a bordo: **maiuscola**, Space Mono (`FilmPalette.edgeText`), ellissi |
| `SectionLabel` | `const SectionLabel(String text, {int? count, Key? key})` | etichetta di sezione in `inkFaint` con il conteggio a destra (solo se > 0); `Semantics(header: true)` |

### Copertina — `features/rolls/roll_cover.dart`

| Classe | Costruttore | Effetto |
|---|---|---|
| `RollCover` | `const RollCover({required RollImage? cover, String? edgeLabel, Key? key})` | `RollImageThumb(image: cover, placeholder: FilmStripPlaceholder(edgeLabel:))` |
| `FilmStripPlaceholder` | `const FilmStripPlaceholder({String? edgeLabel, Key? key})` | CustomPainter (privato `_FilmStripPainter`): negativo scuro (`#17130E` velato di primario), bande con le perforazioni (un ottavo dell'altezza, 8..22), fotogrammi 3:2 bordati, scritta sul bordo se la banda e' alta almeno 10 |

⚑ **Disegnato e non un rettangolo grigio** (F6.8): l'archivio e' la sezione che da' identita'
all'app, e un rullino senza foto deve sembrare comunque un rullino. In codice e non negli asset:
qualunque proporzione, colori del tema, nessun peso.
⚑ `appPathsProvider` si legge solo se c'e' una copertina (dentro RollImageThumb): la home senza
foto si prova nei test senza cartelle vere.

### Rullino: modifica — `features/rolls/roll_editor_page.dart`

`class RollEditorPage extends ConsumerStatefulWidget` — `const RollEditorPage({int? rollId, Key? key})`;
`rollId` null = rullino nuovo.

Ordine dei campi (quello del piano): **1. pellicola** (`_FieldTile` → `_StockPickerSheet`),
**2. macchina** facoltativa (→ `_CameraPickerSheet`), formato (ChoiceChip), **3. ISO esposto**
(preimpostato al nominale, helper `roll_exposedIsoHelp`), **4. fotogrammi** (preimpostati dal
formato), **5. data di caricamento** (default oggi, calendario 1950 → oggi + 1 anno); in modifica,
se c'e', la data di fine. Sotto, "Dettagli facoltativi": titolo (max 120), costo in euro
(`Money.tryParse`: "6,50", "6.50 €", "1.234,56"), nota. Salva in fondo (`roll-save`).

Validita': pellicola scelta, ISO 1..100000, fotogrammi 1..1000, costo vuoto o >= 0.
Salva: nuovo → `addRoll` (sempre `loaded`) e **`pushReplacement(Routes.rollOf(id))`** (⚑ il passo
successivo, foto e QR, si fa nel dettaglio); esistente → `updateRoll(_original.copyWith(...))` e
`pop`. Errore (il caso atteso e' il CHECK `finishedAt >= loadedAt`) → snack `roll_saveError`.

⚑ **I preimpostati seguono le scelte finche' l'utente non li tocca**: cambiare pellicola riporta
l'ISO al nominale nuovo, cambiare macchina riporta formato e fotogrammi a quelli della macchina; un
campo modificato a mano resta (`_isoTouched`, `_framesTouched`; in modifica si considerano toccati
se diversi dal default). Il formato lo decide la macchina se c'e', altrimenti la pellicola.
⚑ **Una pagina sola e non una procedura a passi**: l'unico campo obbligatorio e' la pellicola.

Fogli privati:
- `_StockPickerSheet` (DraggableScrollableSheet 0,9): ricerca, **"Pellicola personalizzata"**
  (apre `showCustomStockSheet` e restituisce la pellicola creata **o quella esistente** se era un
  doppione), **le cinque piu' usate** (`mostUsedStocksProvider`, solo senza ricerca), poi il
  catalogo per marca con "ISO · processo";
- `_CameraPickerSheet`: "Nessuna macchina", le macchine **attive**; senza macchine
  `roll_cameraEmpty` e "Aggiungi una macchina" (`push(Routes.cameraNew)`; il foglio resta aperto e
  la macchina compare tornando);
- `_CameraPick` — ⚑ un oggetto e non Camera?: "nessuna macchina" (una scelta) e "foglio chiuso"
  (nessuna scelta) devono restare distinguibili.

### Rullino: dettaglio — `features/rolls/roll_detail_page.dart`

`class RollDetailPage extends ConsumerWidget` — `const RollDetailPage({required int rollId, Key? key})`.

Dall'alto: titolo `roll_detailTitle(#n)`; `_Header` (titolo o pellicola, pellicola sotto se c'e'
un titolo, chip di stato, formato, **ISO** — su `tertiaryContainer` se push/pull, con
`roll_exposedAt` —, fotogrammi, macchina); `_SuggestionCard`; `_StatusActions`; la **timeline**;
la nota; **`RollPhotosSection`**; poi le righe "Etichetta QR" (`Routes.qrOf`), "Cambia stato",
"Modifica" (`Routes.rollEditOf`), "Elimina" (rosso). Rullino inesistente → `roll_notFound`.

**Azioni del momento** (`_StatusActions`, chiavi per i test):

| Stato | Azioni |
|---|---|
| `loaded` | `action-finished` "Rullino terminato": **un tocco**, `markFinished(id, oggi)` |
| `exposed` | `action-deliver` "Consegna al laboratorio" → `Routes.developmentOf` |
| `sentForDevelopment` | `action-development` "Registra sviluppo" → lo stesso modulo |
| `developed`, `printed` | `action-print` "Aggiungi stampa" + `action-archive` "Archivia" (transizione normale, senza forzare) |
| `archived` | `action-print` (una ristampa mesi dopo, F6.3) |

**Suggerimento** (`_SuggestionCard`, chiave `roll-suggestion`): `suggestFrom` calcolato **qui,
dagli stream** (sviluppo e stampe), mostrato solo quando entrambi sono arrivati (altrimenti
lampeggerebbe) e solo se diverso dallo stato. "Applica" → `setRollStatus(..., force: !canTransition)`.
⚑ `force` perche' il suggerimento nasce da un dato registrato e dice la verita' anche quando il
rullino ha saltato un passo. ⚑ Calcolato dagli stream e non chiesto al repository: compare appena
si torna dal modulo, senza che quelle pagine debbano avvisare il dettaglio.

**Cambio di stato a mano** (`_changeStatus`): un foglio con **solo** le transizioni ammesse
(`status-<key>`). ⚑ Niente "forza" da qui: le transizioni ammesse coprono gia' le correzioni
sensate; lo stato fuori sequenza arriva solo dal suggerimento.

**Timeline** (`_Timeline`, `_Event`, `_EventRow`): caricato (macchina · costo) → terminato →
consegnato al laboratorio (laboratorio; **assente se sviluppato in casa**) → sviluppato / "Sviluppato
in casa" (processo · sviluppo X · scansioni Y) → stampe (una riga per ordine: "Stampe ordinate" o
"Stampe ritirate", laboratorio · formato · N stampe · costo; senza ordini una riga "Stampato"
che apre `printNewOf`). Pallino pieno se fatto; un evento e' fatto se c'e' il dato **oppure** lo
stato dice che e' passato (`archived` non segna niente: si archivia anche un rullino mai
sviluppato). Data o `roll_noDate`/`roll_eventNotYet`. In fondo `roll_totalCost` (chiave
`roll-total`) se > 0. Le righe di sviluppo e stampa sono toccabili (aprono i moduli).
⚑ **Timeline e non una scheda a campi** (spec: "ogni rullino diventa una scheda cronologica").

**Eliminazione** (`_delete`): MicroConfirmSheet distruttivo → `deleteRollAndCollectImagePaths` →
cancella ogni file con `store.resolve(...).delete()` (un errore si logga e non ferma: lo toglie
`pruneOrphans`) → snack `roll_deleted` → `pop`.
☠ **Il database non cancella i file** (F6.2): senza questo passo le foto restano sul telefono per
sempre.

Privato `static _setStatus(context, ref, id, to, {force})`: `setRollStatus` e snack
`roll_statusChanged`; una RollTransitionException si logga.

### Sviluppo e stampe — `features/lab/`

`lab_fields.dart` — i pezzi comuni (⚑ sviluppo e stampa sono due form separate con gli stessi
campi di laboratorio: due copie divergerebbero alla prima correzione).

| Simbolo | Firma | Effetto |
|---|---|---|
| `parseCostCents` | `int? parseCostCents(String input)` | `Money.tryParse` (virgola o punto, simbolo scartato) → centesimi; null se vuoto, non numerico o negativo |
| `isCostTextValid` | `bool isCostTextValid(String input)` | vuoto (i costi sono facoltativi) o importo >= 0 |
| `costCentsToText` | `String costCentsToText(int? cents, String locale)` | "12,50" / "12.50" (rilegge uguale) |
| `formatCostCents` | `String formatCostCents(int cents, String locale)` | "12,50 €" (**non usata**, §14) |
| `CostField` | `const CostField({required TextEditingController controller, required String label, required VoidCallback onChanged, Key? fieldKey, Key? key})` | campo in euro, `common_optional`, errore `dev_costInvalid` |
| `LabDateTile` | `const LabDateTile({required String label, required CivilDate? value, required ValueChanged<CivilDate?> onChanged, required CivilDate firstDate, required CivilDate lastDate, IconData icon = Icons.event_outlined, Key? key})` | riga che apre il calendario (data proposta dentro i limiti, o showDatePicker fallisce un assert), crocetta che toglie la data |
| `SuggestionTextField` | `const SuggestionTextField({required TextEditingController controller, required List<String> suggestions, required String label, String? helperText, int? maxLength, Key? fieldKey, VoidCallback? onChanged, Key? key})` | RawAutocomplete: al massimo 6 nomi che **contengono** il testo senza maiuscole ("foto" trova "Fotoservice Roma"), non quello gia' scritto per intero |
| `applySuggestedStatus` | `Future<RollStatus?> applySuggestedStatus(FilmRepository repo, int rollId)` | porta il rullino allo stato suggerito; restituisce il nuovo stato o null |
| `labSavedMessage` | `String labSavedMessage(L l, RollStatus? newStatus)` | `dev_savedNowExposed/AtLab/Developed/Printed`, altrimenti `dev_saved` |

⚑ `LabDateTile` limita il calendario con l'altra data: il ritorno non puo' precedere la consegna.
Lo vieta anche un CHECK, ma un errore SQL al salvataggio sarebbe incomprensibile.
⚑ RawAutocomplete con il controller **del modulo** e non Autocomplete: il modulo deve
precompilare il campo e leggerlo al salvataggio, e Autocomplete tiene il controller per se'.
⚑ **`applySuggestedStatus` lo fa da solo, senza chiedere**, e lo dice con uno snack: chi registra
"consegnato il 5 ottobre" ha appena detto che il rullino e' in laboratorio. ⚑ **Solo in avanti**:
una transizione ammessa, mai una forzata, **tranne da `loaded`** (un evento di laboratorio vuol
dire che e' uscito dalla macchina anche se nessuno ha toccato "Rullino terminato"). Non torna mai
indietro da solo: togliere la data di ritorno non riporta un rullino `developed` in laboratorio.

`class DevelopmentPage extends ConsumerStatefulWidget` — `const DevelopmentPage({required int rollId, Key? key})`.
Legge **una volta** rullino, sviluppo e pellicola (⚑ e' un modulo, non una vista che segue il
database: un aggiornamento a meta' compilazione cancellerebbe cio' che si scrive). Nuovo:
consegna = oggi, processo = quello della pellicola (C-41 per una Portra; si cambia per il
cross-processing). Campi: interruttore **"Sviluppato in casa"** (`dev_self`), laboratorio con
suggerimenti (`dev_laboratory`, max 80), consegna (`dev_submitted`), ritorno / "Sviluppato il"
(`dev_returned`), processo (ChoiceChip, un secondo tocco lo toglie), costo sviluppo (`dev_cost`),
costo scansioni (`dev_scanCost`), nota. Salva → `saveDevelopment` + `applySuggestedStatus` + snack
+ `maybePop` (se non si chiude torna modificabile). "Elimina" (se esiste) → `deleteDevelopment`;
⚑ lo stato del rullino non cambia (lo stato giusto lo sa solo l'utente). Rullino inesistente →
`dev_rollMissingTitle`.
⚑ **"Sviluppato in casa" nasconde laboratorio e consegna**: non c'e' un laboratorio, e uno
sviluppo in casa si registra a cose fatte. Resta la data, che e' `returnedAt` (la timeline la
mostra).

`class PrintPage extends ConsumerStatefulWidget` — `const PrintPage({required int rollId, int? printId, Key? key})`;
`printId` null = ordine nuovo. Nuovo: consegna = oggi, laboratorio = il piu' usato (di solito si
stampa dove si sviluppa). Campi: laboratorio (`print_laboratory`), consegna, ritorno, formato
libero (`print_format`, max 40) con le scorciatoie `10x15`, `13x18`, `15x20`, `20x30`
(costante privata `_commonPrintFormats`), numero di stampe (`print_count`, vuoto o > 0), costo
(`print_cost`), nota. Salva → `addPrintOrder`/`updatePrintOrder(copyWith)` + `applySuggestedStatus`
(una stampa tornata → `printed`) + snack. ⚑ Un ordine di **un altro rullino** (link costruito male)
si tratta come inesistente: la pagina salverebbe col `filmRollId` dell'ordine.

### Macchine — `features/cameras/`

`class CamerasPage extends ConsumerWidget` (`cameras_page.dart`) — `const CamerasPage({Key? key})`:
l'elenco (produttore modello · formato · "dismessa" · nota, a destra `camera_rollCount`), tocco →
`cameraEditOf`; FAB "Aggiungi" (`camera_add`) con il ProBadge quando la prossima e' Pro.
⚑ **Un inventario, non una collezione** (F6.5).

| Funzione | Firma | Effetto |
|---|---|---|
| `openNewCamera` | `Future<int?> openNewCamera(BuildContext context, WidgetRef ref)` | conta **dal repository** (`cameraCount()`); fuori limite paywall (`secondaryEntities`); poi `push<int>(Routes.cameraNew)` e restituisce l'id creato |

⚑ Il conteggio si chiede al repository e non al provider: chiamata da una pagina che non ascolta
il conteggio, `.value` sarebbe null, cioe' zero, cioe' la seconda macchina gratis. ☠
`ref.read(cameraCountProvider.future)` non arriva mai (Riverpod 3 mette in pausa i provider non
ascoltati; visto in un test il 2026-10-08).

`camera_editor_page.dart`:

| Classe | Costruttore | Effetto |
|---|---|---|
| `NewCameraGate` | `const NewCameraGate({Key? key})` | la rotta `cameraNew`: **aspetta** `cameraCountProvider` e **congela** il conteggio all'apertura, poi `ProGate(secondaryEntities, allowed: withinLimit(conteggio))` → `CameraEditorPage()` |
| `CameraEditorPage` | `const CameraEditorPage({int? cameraId, Key? key})` | produttore (`camera_manufacturer`, max 60), modello (`camera_model`), formato, nota. **Nient'altro**. Salva → `addCamera`/`updateCamera` e `maybePop(id)`; Elimina → avviso con quanti rullini restano **senza macchina** (`camera_deleteBody(n)`) → `deleteCamera` |

⚑ **Perche' `NewCameraGate` e non il solo ProGate nel router** (come la fonte nuova di Scorte
Calore): li' `allowed` leggeva il conteggio con `.value`, null finche' lo stream non arriva,
cioe' via libera. Qui si aspetta; e lo si congela perche' dopo il salvataggio le macchine
diventano due e un conteggio vivo farebbe lampeggiare il lucchetto sulla pagina che si chiude.
⚑ Chi vende una macchina non deve temere di perdere la storia: i rullini restano (setNull).

### Pellicole — `features/stocks/`

`class StocksPage extends ConsumerStatefulWidget` (`stocks_page.dart`) — `const StocksPage({Key? key})`:
SearchBar (marca, nome, "marca nome" o ISO esatto), gruppi per marca (`SectionLabel`), righe con
l'ISO nel cerchio e "ISO · processo · formato"; **le personalizzate** hanno il chip `stock_customBadge`
("Tua") e il menu Modifica/Elimina (tocco = modifica); FAB `stock_add`. Nessun risultato →
MicroEmptyState con "Aggiungi". Privati `_matches`, `_delete`, `_grouped`, `_StockTile`.
⚑ Catalogo e personalizzate nella stessa lista: chi cerca "Portra" non deve sapere in quale
delle due sta.

`custom_stock_sheet.dart`:

| Funzione | Firma | Effetto |
|---|---|---|
| `showCustomStockSheet` | `Future<int?> showCustomStockSheet(BuildContext context, WidgetRef ref)` | crea una pellicola (marca con suggerimenti dalle marche esistenti, nome, ISO 1..100000, processo, formato) e restituisce l'id; null se chiuso |
| `showEditCustomStockSheet` | `Future<bool> showEditCustomStockSheet(BuildContext context, WidgetRef ref, FilmStock stock)` | lo stesso foglio in modifica (assert `isCustom`); avvisa `stock_editKeepsRolls`; true se salvato |

⚑ **Doppione** (DuplicateFilmStockException): il foglio lo dice sotto il nome
(`stock_duplicate`) e offre **"Usa quella"** (`stock_useExisting`), che restituisce l'id della
pellicola **esistente**: dal form del rullino serve una pellicola da scegliere, non un doppione.
L'errore sparisce appena si cambia un campo. Un solo posto crea le pellicole (lo usa anche il
form del rullino).

### Foto — `features/photos/` (F6.9, **gratis**)

`image_store_provider.dart`:

| Simbolo | Firma | Effetto |
|---|---|---|
| `imageStoreProvider` | `Provider<ImageStore>` | `ImageStore(paths: appPathsProvider)`; ⚑ i test cambiano `appPathsProvider` e tutto segue |
| `rollImageBucket` | `const String rollImageBucket = 'rolls'` | `images/rolls/` e `images/thumbs/rolls/`; ⚑ una cartella sola per tutti i rullini (nomi UUID) |
| `rollImageFile` | `File rollImageFile(AppPaths paths, String relativePath)` | `paths.resolve(relativePath)` |
| `RollImageThumb` | `const RollImageThumb({required RollImage? image, bool full = false, BoxFit fit = BoxFit.cover, Widget? placeholder, int? cacheWidth, Key? key})` | miniatura (o la grande con `full`); senza immagine o con il file sparito mostra `placeholder` o un riquadro neutro con icona (privato `_ThumbPlaceholder`) — **mai un errore rosso** |

⚑ `RollImageThumb` decodifica **alla dimensione mostrata** (`cacheWidth` = larghezza ×
devicePixelRatio): una griglia di miniature da 400 px e' poco, la stessa con le 1600 no.

`photo_logic.dart` (puro, senza Flutter):

| Simbolo | Firma | Effetto |
|---|---|---|
| `reorderIds` | `List<int> reorderIds(List<int> ids, int oldIndex, int newIndex)` | il nuovo ordine con `newIndex` **finale** (semantica di `ReorderableListView.onReorderItem`); indici fuori misura non rompono; non modifica la lista ricevuta |
| `coverAfterDelete` | `int? coverAfterDelete({required List<int> idsInOrder, required int? currentCover, required int deletedId})` | ⚑ cancellata la copertina, diventa copertina **la prima foto rimasta**, non "nessuna"; null solo senza foto |
| `formatBytes` | `String formatBytes(int bytes, String locale)` | "850 KB", "12,3 MB": ⚑ **unita' decimali** come le impostazioni di iOS e Android |
| `ImportProgress` | `const ImportProgress({required int done, required int total, bool cancelling = false})` | `double get fraction`, `ImportProgress copyWith({int? done, bool? cancelling})` |
| `ImportOutcome` | `const ImportOutcome({required int imported, required int failed, required bool cancelled})` | |
| `ImportCancellation` | `ImportCancellation()` | `bool get isCancelled`, `void cancel()` |

☠ Il vecchio `onReorder` (deprecato da Flutter 3.41) passava un indice che contava ancora
l'elemento trascinato (andando avanti, quello vero era `newIndex - 1`): qui si riceve l'indice finale.

`photo_actions.dart`:

| Simbolo | Firma | Effetto |
|---|---|---|
| `imagePickerProvider` | `Provider<ImagePicker>` | sostituibile nei test |
| `importRollPhotos` | `Future<ImportOutcome> importRollPhotos({required FilmRepository repository, required ImageStore store, required int rollId, required List<File> files, RollImageKind kind = RollImageKind.contactSheet, ImportCancellation? cancellation, void Function(int done)? onProgress})` | **una foto alla volta**: `store.importFile(bucket: 'rolls')` (1600 px, miniatura 400, JPEG 82, **in un isolate**), poi `addImage`; l'annullamento si controlla **fra** una foto e l'altra |
| `PhotoPick` | `typedef PhotoPick = ({ImageSource source, RollImageKind kind})` | la scelta del foglio |
| `showPhotoSourceSheet` | `Future<PhotoPick?> showPhotoSourceSheet(BuildContext context)` | tipo (provini di default) e sorgente: fotocamera, o galleria con selezione multipla |
| `rollImageKindLabel` | `String rollImageKindLabel(L l, RollImageKind kind)` | `photo_kind_<valore>` |
| `addRollPhotos` | `Future<void> addRollPhotos(BuildContext context, WidgetRef ref, int rollId)` | foglio → `pickImage`/`pickMultiImage` → finestra d'import con barra e "Annulla" → snack (`photo_importFailed(n)` o `photo_imported(n)`) |
| `confirmAndDeleteRollPhoto` | `Future<bool> confirmAndDeleteRollPhoto(BuildContext context, WidgetRef ref, {required int rollId, required RollImage image, required List<RollImage> images, required int? coverId})` | conferma → `deleteImage` → `ImageStore.delete` → se era la copertina `setCoverImage(coverAfterDelete(...))` |
| `setRollCover` | `Future<void> setRollCover(BuildContext context, WidgetRef ref, {required int rollId, required int imageId})` | `setCoverImage` + snack `photo_coverSet` |

Privati: `_discardPickerCopy(File)` (cancella la copia di image_picker **solo** se il percorso
contiene `/cache/` o `/tmp/`: dalla galleria, su alcuni Android, e' l'originale dell'utente),
`_PhotoSourceSheet`, `_ImportDialog`.

☠ **Import in isolate** (F6.9): dieci foto da 12 megapixel sul thread della UI la congelano per
secondi. ⚑ **Una alla volta e non dieci isolate insieme**: dieci decodifiche in parallelo (~48 MB
di pixel l'una) finiscono la memoria di un telefono economico; in fila la memoria resta quella di
una foto e la barra avanza in modo leggibile. ⚑ **Annulla**: la foto gia' in conversione si finisce
e si tiene ("mi fermo dopo questa foto"), quelle salvate restano.
☠ **Un file illeggibile non ferma l'import**: il decoder del pacchetto `image` lancia un **Error**
(RangeError, visto il 2026-10-08 con quattro byte a caso). In `micro_core` `ImageStore.importBytes`
**ora cattura `on Object`** (2026-10-08) e restituisce un Err; il `catch` senza `on` attorno a
`importFile` in `importRollPhotos` resta come seconda rete (conta la foto come fallita e passa
alla successiva).
⚑ Niente `maxWidth`/`imageQuality` nel picker: il ridimensionamento lo fa ImageStore con
l'orientamento EXIF applicato; farlo fare anche al picker ricomprimerebbe due volte.
⚑ **La finestra d'import non si chiude** (tocco fuori, "indietro"): l'import continuerebbe senza
che l'utente lo veda, e un secondo "Aggiungi" lo raddoppierebbe.
⚑ **Prima la riga e poi i file** nell'eliminazione: al contrario, un'interruzione lascerebbe una
riga che punta al nulla; cosi' resta al massimo un file orfano, che "Libera spazio" toglie.
⚑ **Si copia sempre l'immagine nell'app** invece di tenere un riferimento alla galleria: un URI di
MediaStore puo' diventare invalido (foto cancellata, scheda SD, permesso revocato).
**Da provare su telefono**: HEIC dalla galleria Android (§14).

`class RollPhotosSection extends ConsumerWidget` (`roll_photos_section.dart`) —
`const RollPhotosSection({required int rollId, Key? key})`. ⚑ **Contratto col dettaglio**: nome e
firma non cambiano; la sezione non scorre da sola (griglia `shrinkWrap`). Titolo `photo_sectionTitle`,
"Riordina" (da 2 foto, foglio `_ReorderSheet` con ReorderableListView e "Fatto"; ⚑ una lista e non
la griglia: Flutter riordina col trascinamento solo le liste), "Aggiungi"; vuota → `_EmptyPhotos`;
piena → griglia (`static int columnsFor(double width)`: `width / 130` fra 3 e 6) di `_PhotoTile`
con la stella sulla copertina e Semantics "Foto N, Copertina"; tocco → `Routes.photoOf`;
pressione lunga → foglio Apri / Usa come copertina / Elimina foto (`_PhotoAction`).
Funzione `String rollImageHeroTag(int imageId)` → `'roll-image-$id'`: lo stesso tag nel
visualizzatore, la miniatura "si apre" invece di sparire.

`class PhotoViewerPage extends ConsumerStatefulWidget` (`photo_viewer_page.dart`) —
`const PhotoViewerPage({required int rollId, required int imageId, Key? key})`: **fondo nero anche
nel tema chiaro**, PageView fra le foto (parte da quella toccata), barra con "N di M", tipo ·
Copertina, stella (se non e' copertina) e cestino; tocco = nasconde/mostra la barra; `_ZoomablePhoto`
con InteractiveViewer (fino a 6x) e **doppio tocco 2,5x nel punto toccato**; mentre la grande si
carica resta la miniatura. Dopo una cancellazione resta sull'ultima foto esistente; cancellata
l'ultima, si chiude.
⚑ Con la foto ingrandita il PageView non scorre (NeverScrollableScrollPhysics): il trascinamento
lo vincerebbe la pagina e la foto ingrandita non si potrebbe esplorare.
⚑ InteractiveViewer di Flutter e non un pacchetto di galleria.

`photo_storage_tile.dart`:

| Simbolo | Firma | Effetto |
|---|---|---|
| `photoStorageBytesProvider` | `FutureProvider.autoDispose<int>` | `imageStore.totalBytes()` (cartella `images/`); ⚑ si invalida dopo "Libera spazio" |
| `PhotoStorageTile` | `const PhotoStorageTile({Key? key})` | voce delle impostazioni "Spazio delle foto: 12,3 MB"; tocco → conferma → `pruneOrphans(allImagePaths())` → `photo_freed(n)` / `photo_freedNothing` |

⚑ "Libera spazio" non tocca mai una foto in uso: l'elenco di cio' che si tiene viene dal database
(immagini **e** miniature). ☠ Non va lanciato durante un import (il file esiste un istante prima
della riga): in pratica la finestra d'import blocca lo schermo.

### QR del rullino — `features/qr/` (F6.12, gratis)

`qr_links.dart`:

| Funzione | Firma | Effetto |
|---|---|---|
| `rollQrData` | `String rollQrData(int sequenceNumber)` | `filmtracker://roll/<n>` |
| `sequenceFromUri` | `int? sequenceFromUri(Uri uri)` | accetta `filmtracker://roll/17`, con o senza barra finale, e `filmtracker:///roll/17` (host vuoto: certi lettori riscrivono cosi'), schema e host senza maiuscole; **solo cifre, al massimo nove**, > 0; null altrimenti |
| `locationForRollLink` | `Future<String?> locationForRollLink(Uri uri, FilmRepository repository)` | `Routes.rollOf(id)` del rullino con quel numero; null se il link non e' nostro o il rullino non c'e' |
| `listenRollLinks` | `StreamSubscription<Uri> listenRollLinks({required Stream<Uri> links, required FilmRepository Function() repository, required void Function(String location) open})` | ascolta e apre; i link non nostri o di rullini assenti si **ignorano** (la home resta dov'e') |

⚑ **Il QR porta il numero del rullino ("#17") e non l'id**: il numero e' scritto in chiaro sotto il
codice e sul contenitore, e' UNIQUE e resta lo stesso dopo un ripristino; l'id puo' cambiare.
⚑ `sequenceFromUri` e' l'unico punto in cui un testo arrivato da fuori (un QR stampato da chiunque)
entra nell'app: e' pura e si prova da sola. Niente "+17", "1e3", "0x11".

`qr_page.dart`:

| Classe | Costruttore | Effetto |
|---|---|---|
| `QrPage` | `const QrPage({required int rollId, Key? key})` | `qr_title`, l'etichetta e `qr_hint` ("stampala o fotografala e attaccala al contenitore"); rullino assente → `qr_rollMissing` |
| `RollQrLabel` | `const RollQrLabel({required FilmRoll roll, double maxWidth = 360, Key? key})` | QrImageView (correzione **M**, moduli quadrati neri), "#17" a 44 pt, la pellicola, il titolo; pubblica per un futuro foglio di etichette |

⚑ **Etichetta bianca con inchiostro nero anche nel tema scuro**: si stampa e si fotografa, e i
lettori leggono male i codici chiari su fondo scuro. Testi con stile esplicito (nel tema scuro
sarebbero chiari su bianco).
⚑ Correzione M: regge un'etichetta graffiata o piegata, e il link corto tiene i moduli grandi.
⚑ **Gratis**: e' la funzione piu' raccontabile dell'app e serve a farla conoscere. Nessun
laboratorio deve supportare nulla.

### Statistiche (Pro) — `features/stats/stats_page.dart`

| Classe | Costruttore | Effetto |
|---|---|---|
| `StatsPage` | `const StatsPage({Key? key})` | `ProGate(statistics, child: _StatsView())` |
| `MonthlyRollsChart` | `const MonthlyRollsChart({required List<int> rollsPerMonth, double height = 160, Key? key})` | assert 12 valori; Semantics "gen 2, feb 0, ..." |
| `MonthlyBarsPainter` | `MonthlyBarsPainter({required List<int> values, required List<String> labels, required Color bar, required Color empty, required Color text, required Color valueText})` | 12 barre (larghe al massimo 28), numero sopra le non vuote, iniziale del mese sotto, linea di base; `shouldRepaint` confronta liste e colori |

`_StatsView`: anni come ChoiceChip (`stats_year_<anno>`, dal piu' recente; ⚑ un anno scelto che
non ha piu' rullini torna al piu' recente), tessere rullini (`stats_rolls`) e fotogrammi potenziali
(`stats_frames`), grafico mensile, spesa per voce e totale (`stats_total`; `stats_noCosts` se zero),
medie (`stats_perRoll` con "sui N rullini con costi"; `stats_perFrame` **"Costo per fotogramma
(stima)"**, valore "≈ 0,72 €" e la riga `stats_perFrameHint`), piu' usati (emulsione, macchina,
laboratorio, `stats_noneYet`), "N rullini sviluppati in casa". Pulsante PDF in barra
(`stats_pdf` → `createYearReport(year:)`).
⚑ **Grafico con CustomPainter, niente `fl_chart`** (come Scorte Calore): dodici rettangoli non
valgono un pacchetto. Niente asse verticale: con il numero sopra ogni barra direbbe la stessa cosa.
☠ **Il costo per fotogramma e' una stima** (F6.10): scritto nel titolo, nel valore e nella spiegazione.

### Impostazioni — `features/settings/`

`class SettingsPage extends ConsumerWidget` (`settings_page.dart`) — `const SettingsPage({Key? key})`:
riga del Pro (tocco su tutta la riga → paywall; col Pro `settings_proActive`), "Ripristina
acquisto" (sottotitolo Apple/Google secondo `defaultTargetPlatform`), Tema (foglio Scuro / Chiaro /
Come il telefono), `DataSection`, `PhotoStorageTile`, versione (`appVersion`).
⚑ Le righe rispondono al tocco su tutta la superficie (in TrashCan non succedeva).

`data_section.dart`:

| Simbolo | Firma | Effetto |
|---|---|---|
| `backupServiceProvider` | `Provider<BackupService>` | `BackupService(paths:, appVersion: appVersion)` |
| `DataSection` | `const DataSection({Key? key})` | "I tuoi dati": statistiche (`data_stats`), PDF (`data_report`), CSV (`data_csv`), backup (`data_backup`) col ProBadge senza Pro; ripristino (`data_restore`) **senza badge** |
| `openStats` | `Future<void> openStats(BuildContext context, WidgetRef ref)` | senza Pro il paywall **invece** della pagina (arrivare a un lucchetto sarebbe un passaggio in piu'); col Pro `push(Routes.stats)` |
| `createYearReport` | `Future<void> createYearReport(BuildContext context, WidgetRef ref, {int? year})` | senza Pro paywall; senza `year` lo chiede se gli anni sono piu' di uno (`report_noRolls` se nessuno); costruisce il PDF in una finestra d'attesa; poi "Stampa" (`Printing.layoutPdf`, anteprima di sistema) o "Condividi" (file `exports/film-tracker-<anno>.pdf` e `shareBackup`) |
| `exportCsv` | `Future<void> exportCsv(BuildContext context, WidgetRef ref)` | senza Pro paywall; **tutti** i rullini; condivide |
| `createBackup` | `Future<void> createBackup(BuildContext context, WidgetRef ref)` | senza Pro paywall; `createBackup(FilmBackupSource, includeImages: true)` in una finestra d'attesa, poi condivisione |
| `restoreBackup` | `Future<void> restoreBackup(BuildContext context, WidgetRef ref)` | **gratis**: sceglie il file, `inspect` (schemaId diverso → errore subito), riepilogo con i conteggi, sostituisci/aggiungi, `restore` con finestra d'attesa |

Privati: `_pickYear`, `_withProgress<T>(context, message, work)` (dialogo che non si chiude,
chiuso nel `finally`).

⚑ **Ripristino gratis**, creazione Pro: chi cambia telefono deve riavere i dati anche prima di aver
ripristinato l'acquisto (stessa scelta di Full Freezer e Scorte Calore).
☠ "Sostituisci tutto" e' irreversibile, **foto comprese**: il riepilogo prima della conferma e' il
solo modo per accorgersi del file sbagliato.
⚑ Gli ingressi del PDF si leggono **adesso dal repository** e non dai provider delle statistiche:
dalle impostazioni quegli stream non sono mai stati ascoltati.
⚑ Il PDF si condivide con lo stesso canale di CSV e backup (`shareBackup`, share_plus in
micro_core) e non con `Printing.sharePdf`: un modo solo di condividere file.
⚑ **Finestre d'attesa** su PDF, backup e ripristino: con qualche centinaio di foto lo ZIP richiede
secondi, e senza un segno di vita l'utente tocca di nuovo e ne parte un secondo.
⚑ Il PDF prende gli errori **`on Object`**: un'immagine rovinata puo' far lanciare un Error al
pacchetto `pdf`, e l'utente deve vedere `report_failed`, non un crash.

### Il lucchetto Pro — `features/common/pro_gate.dart`

`class ProGate extends ConsumerWidget` — `const ProGate({required FeatureKey feature, required Widget child, bool Function(FeatureGate gate)? allowed, Key? key})`.
Con il permesso mostra `child`; senza, una pagina con lucchetto, `pro_locked` e il pulsante del
paywall con `feature` evidenziata; si ridisegna da sola quando arriva il Pro. Copiato da Scorte
Calore (nato in Full Freezer). ⚑ Il Pro controllato **sulla pagina**, non solo sulla porta: un
`push` diretto (deep link, pagina futura) aprirebbe la pagina gratis.

### Avvio — `lib/main.dart` e `lib/dev/`

`Future<void> main()`: `buildFilmConfig()` + `assertUsableInRelease()` (☠ una release col billing
finto regalerebbe il Pro), `AppPaths.forApp`, `ensureAll`, log su `logs/film_tracker.log`,
`FlutterError.onError` → log, `SettingsStore.create(namespace: 'film_tracker')`, `_recordLaunch`
(conta gli avvii e registra il primo, per decidere quando chiedere una recensione), dati demo se
richiesti, `runApp` con gli override dei tre provider radice.

⚑ Database e store li inizializzano i provider, pigramente: farlo prima del primo frame produce una
schermata bianca all'avvio.

| Simbolo | Firma | Effetto |
|---|---|---|
| `demoRequested` | `const bool demoRequested = bool.fromEnvironment('FT_DEMO')` | |
| `demoEnabled` | `bool get demoEnabled` | `demoRequested && !kReleaseMode`: ☠ **mai in release** |
| `seedDemoData` | `Future<bool> seedDemoData(AppDatabase db, {bool english = false})` | solo su database **senza rullini**: 3 macchine (Olympus OM-2, Nikon FM2, Yashica Mat-124G 6x6) e **12 rullini** negli ultimi otto mesi in tutte e tre le sezioni (2 in macchina, 1 finito, 2 in laboratorio, 7 in archivio: uno con due ordini di stampa da laboratori diversi, uno sviluppato in casa, un Tri-X tirato a 1600); titoli in italiano o inglese secondo la lingua; true se ha scritto |
| `seedDemoPhotos` | `Future<void> seedDemoPhotos(AppDatabase db, ImageStore store)` | **tre foto** per ogni rullino dell'archivio senza foto, passate dallo **stesso ImageStore** delle foto vere (`importBytes`, bucket `rolls`) e registrate con `addImage` |
| `demoLandscape` | `Uint8List demoLandscape({required int seed, bool blackAndWhite = false})` | paesaggio da cartolina 1200x800 JPEG 88 disegnato col pacchetto `image`: cielo sfumato, sole, due catene di montagne, prato, cinque tavolozze; **in bianco e nero per le pellicole BW**; puro (stesso seme, stessa immagine) |

In `main` la lingua dei dati demo viene da `resolveAppLocale` sulle lingue del telefono; il database
aperto per la demo si chiude prima di `runApp`.
⚑ **Perche' esistono**: le tre sezioni, la timeline e le statistiche si vedono solo con mesi di
rullini, e da fuori (adb, test d'integrazione) non si inseriscono date nel passato. ⚑ **Foto
disegnate e non vere** nel repository: niente diritti da chiarire, niente megabyte negli asset; il
foglio provini e il PDF senza foto mostrerebbero solo le strisce, e gli screenshot degli store
devono far vedere l'app com'e' usata.
⚑ **`image` e' diventata dipendenza diretta** (era gia' nell'app tramite micro_core): la usano
`demo_photos.dart` e i JPEG veri dei test dell'import.

---

## 10. Cosa e' Pro e cosa e' gratis

La mappa vive in `lib/app/feature_limits.dart` (`filmFeatureLimits`) ed e' l'**unico** posto in cui
cambiarla. Decisioni del proprietario del 2026-10-08 (F6.0 punti 2 e 3). Prezzo: **4,99 €** una
tantum (Play: 4,09 EUR senza IVA).

| Funzione | Chiave | Piano gratuito | Dove si controlla |
|---|---|---|---|
| Seconda macchina e oltre | `secondaryEntities` | **una** (`count(freeMax: 1)`) | `openNewCamera` + `NewCameraGate`/`ProGate` su `/cameras/new` |
| Statistiche e costi per anno | `statistics` | no | `openStats` + `ProGate` su `/stats` (la voce del menu della home porta al lucchetto) |
| PDF di riepilogo annuale | `pdfReport` | no | `createYearReport` |
| Export CSV | `csvExport` | no | `exportCsv` |
| Creazione del backup | `backupRestore` | no — **il ripristino e' gratis** | `createBackup` |
| **Foto** (copertina, provini, stampe, galleria, zoom) | `photos` | **si'** (F6.0 punto 3) | |
| Rullini | `unlimitedEntities` | **illimitati** | |
| QR del rullino | (nessuna chiave) | **si'** (F6.12) | |
| `fullHistory`, `notifications`, `multipleNotifications`, `calendarSync`, `advancedWidget`, `customCategories`, `themeCustomization` | | aperte: l'app non le ha o non le vende | |

**Il gratuito risponde alla domanda dell'app**: rullini illimitati, una macchina, il catalogo,
sviluppo e stampe, l'archivio con **tutte le foto** e il QR. **Il Pro vende** le altre macchine, le
statistiche e i costi per anno, il PDF dell'anno, CSV e backup completo.

⚑ Il piano (spec) diceva "fino a 10 rullini" gratis e foto Pro: superato da F6.0. I rullini sono il
cuore dell'app; le foto sono la sua identita'.
☠ **Ogni chiave limitata compare fra i benefici del paywall e viceversa** (5 e 5): lo verifica
`test/widget/paywall_config_test.dart`, in it e in en. Le funzioni aperte sono dichiarate comunque
nella mappa: si legge cosa NON e' a pagamento, e l'assert di FeatureGate non scatta.

---

## 11. Configurazione e chiavi

| Chiave | Dove | Default | Significato |
|---|---|---|---|
| FT_DEMO | `--dart-define` | `false` | dati di esempio (12 rullini, foto disegnate) su database senza rullini; **ignorato in release** |
| BILLING | `--dart-define` (letto da `MicroAppConfig.fromEnvironment`) | `fake` in debug, `store` in release | `fake` = gateway finto **senza Pro** a 4,99 €; una release con `fake` fallisce all'avvio (`assertUsableInRelease`) |
| MA_LICENSE_URL, MA_APP_SECRET | `--dart-define-from-file` | vuoti | server licenze; senza, `serverEnabled` falso e l'entitlement lavora in locale |
| `appId` | `app_config.dart` | `film_tracker` | namespace delle preferenze, cartelle, log; anche `FilmBackupSource.id` |
| `licenseAppId` | `app_config.dart` | `filmtracker` | id sul License Server (≠ `appId`) |
| `proSku` | `app_config.dart` | `filmtracker_pro_lifetime` | **immutabile**: uno SKU pubblicato non si cancella ne' si riusa |
| `seedColor` / `fontFamily` | `app_config.dart` | `#E0A458` / PlusJakartaSans | font variabile `assets/fonts/PlusJakartaSans-Variable.ttf` (OFL in `OFL-PlusJakartaSans.txt`) |
| `defaultBrightness` | `app_config.dart` | `Brightness.dark` | scuro di default (F6.1) |
| `kEdgeFont` | `film_palette.dart` | `'SpaceMono'` | `SpaceMono-Regular.ttf` e `SpaceMono-Bold.ttf` (peso 700), OFL in `OFL-SpaceMono.txt` |
| `applicationId` / `namespace` | `android/app/build.gradle.kts` | `com.smp.filmtracker` | **immutabile** dopo il primo upload |
| `minSdk` / `targetSdk` | idem | 24 / quello di Flutter | desugaring attivo (flutter_local_notifications di micro_core); release con minify e shrink |
| `storeFile`, `storePassword`, `keyAlias`, `keyPassword` | `android/key.properties` (non versionato) | assenti | senza, la release si firma in debug e Play la rifiuta; keystore **PKCS12** in `%USERPROFILE%/.android-keys` |
| bundle iOS, team | `project.pbxproj` | `com.smp.filmtracker`, A29HGT2MQ4 | solo iPhone |
| Schema URL | manifest (`scheme="filmtracker" host="roll"`) e `Info.plist` | `filmtracker` | `Routes.scheme` |
| `version` | `pubspec.yaml` | `1.0.0+1` | `appVersion` va tenuta uguale |
| `schemaVersion` DB / backup | `database.dart` / `FilmBackupSource` | `1` / `1` | |
| file del database | `_openConnection` | `film_tracker.sqlite` (documenti) | |
| foto | `rollImageBucket` + ImageStore | `images/rolls/<uuid>.jpg`, `images/thumbs/rolls/<uuid>.jpg` | 1600 px / 400 px, JPEG 82 (default di ImageStore) |
| esportazioni | `exportRollsCsv`, `createYearReport` | `exports/film-tracker-<YYYY-MM-DD>.csv`, `exports/film-tracker-<anno>.pdf` | |
| log, entitlement | `main`, `EntitlementNotifier` | `logs/film_tracker.log`, `support/entitlement.json` | |

### Preferenze (SettingsStore, namespace `film_tracker`: chiave salvata `film_tracker.<chiave>`)

| Chiave (micro_core) | Valore salvato | Tipo | Chi la scrive / legge |
|---|---|---|---|
| SettingKeys.themeMode | `theme_mode` | String `light`\|`dark`\|`system`; **assente → scuro** | `ThemeModeNotifier` |
| SettingKeys.launchCount, SettingKeys.firstLaunchAt | `launch_count`, `first_launch_at` | int, istante | `main` (`_recordLaunch`) |

**Nessuna preferenza propria** dell'app (niente onboarding, nessuna sezione o macchina
"preferita"): tutto il resto sta nel database.

### Permessi

| Piattaforma | Permesso | Perche' |
|---|---|---|
| Android | `com.android.vending.BILLING` | acquisti; dichiarato a mano perche' Play guarda il pacchetto caricato |
| Android | intent-filter VIEW/BROWSABLE `filmtracker://roll` (senza `autoVerify`: e' uno schema nostro) | il QR apre l'app |
| Android | (nessun CAMERA: image_picker apre l'app fotocamera di sistema con un intent) | |
| Android | (FileProvider portato da `printing` nel manifest fuso) | anteprima e stampa del PDF |
| Android | (nessun INTERNET nel manifest principale; solo in debug/profile) | vedi §14 |
| iOS | NSCameraUsageDescription, NSPhotoLibraryUsageDescription | foto dei provini (testi it/en in `InfoPlist.strings`) |

### Testi (l10n)

**361 chiavi**, template **inglese** (`l10n.yaml`: `template-arb-file: app_en.arb`,
`output-class: L`, `nullable-getter: false`, `output-dir: lib/l10n/generated`,
`untranslated-messages-file: lib/l10n/untranslated.json`): una chiave dimenticata deve produrre
inglese in un'app italiana, non il contrario.

Classi **generate** in `lib/l10n/generated/` (non si modificano): `abstract class L` (con
`L.of(context)`, `L.delegate`), `class LEn extends L`, `class LIt extends L`, e la funzione
`L lookupL(Locale locale)`, usata fuori dai widget (test).

☠ **Gli ARB non si modificano mai a mano.** Si scrive in `tool/testi.py` (TESTI comuni: appTitle,
common, paywall, pro, settings, theme — 38 chiavi) e nei `tool/testi_*.py` caricati da
`tutti_i_testi()` (in ordine alfabetico; una chiave ripetuta in due file e' un errore):

| File | Prefissi | Chiavi | TIPI propri |
|---|---|---|---|
| `tool/testi_dati.py` | `stats_`, `data_`, `csv_`, `backup_`, `report_` | 95 | `rolls`, `cameras`, `images` int |
| `tool/testi_foto.py` | `photo_`, `qr_` | 45 | `done`, `total`, `index` int |
| `tool/testi_laboratorio.py` | `dev_`, `print_`, `camera_`, `stock_` | 82 | `n` int |
| `tool/testi_rullini.py` | `home_`, `roll_`, `status_` | 101 | `iso` int |

Ogni chiave ha le due lingue sulla stessa riga `'chiave': ('inglese', 'italiano')`; segnaposti
`{nome}` (tipo in TIPI: `n`, `count`, `days` int in `testi.py`, il resto String); plurali ICU.
⚑ L'anno passa come testo (`{year}` senza tipo): un int formattato da gen_l10n potrebbe diventare
"2.026". ⚑ Le chiavi `status_<key>`, `roll_format_<nome>`, `roll_process_<nome>`, `photo_kind_<nome>`
si risolvono negli switch esaustivi di `labels.dart` e `photo_actions.dart`. ☠ Virgolette
**tipografiche** anche in inglese: con quelle dritte gli script adb non trovano piu' i riquadri.

Prefissi: appTitle 1, common 6, paywall 20, pro 1, settings 7, theme 3, home 24, roll 71,
status 6, dev 25, print 17, camera 20, stock 20, photo 39, qr 6, stats 28, data 2, csv 30,
backup 16, report 19.

Flusso: `python tool/testi.py` (scrive i due ARB) → `pwsh ../../tool/fl.ps1 gen-l10n`.

### Dipendenze proprie (oltre a micro_core)

`app_links ^7.2.2` (il QR, F6.12), `image_picker ^1.2.4` (F6.9), `image ^4.10.1` (demo e test),
`pdf ^3.13.1` e `printing ^5.15.1` (F6.11), `qr_flutter ^4.1.0` (F6.12), `drift`, `sqlite3`,
`sqlite3_flutter_libs`, `flutter_riverpod ^3.4.3`, `go_router ^18.0.1`, `intl`, `meta`, `path`,
`path_provider`, `cupertino_icons`. Dev: `drift_dev`, `build_runner`, `flutter_launcher_icons`,
`flutter_native_splash`, `shared_preferences`, `integration_test`, `flutter_lints`, e il tetto
`analyzer: ">=14.0.0 <14.4.0"`.
⚑ **Ogni dipendenza entra con la sottofase che la usa**: una dipendenza aggiunta prima del suo
codice e' un plugin nativo in piu' da compilare su due piattaforme senza che nessuno lo provi.
⚑ **Niente `fl_chart`** (il piano lo elencava in F6.1): il grafico mensile e' un CustomPainter.

### Comandi

Dalla cartella `apps/film_tracker`, sempre con la toolchain del progetto:

```
pwsh ../../tool/fl.ps1 test                                   # i 185 test
pwsh ../../tool/fl.ps1 analyze                                # analisi statica
python tool/testi.py; pwsh ../../tool/fl.ps1 gen-l10n         # dopo aver cambiato un testo
pwsh ../../tool/fl.ps1 build apk                              # APK
pwsh ../../tool/fl.ps1 build apk --debug --dart-define=FT_DEMO=true   # con i dati e le foto di esempio
pwsh ../../tool/fl.ps1 pub run build_runner build             # dopo una modifica a tables.dart (rigenera database.g.dart)
python tool/genera_icone.py                                   # dopo aver cambiato l'originale dell'icona
pwsh ../../tool/fl.ps1 pub run flutter_launcher_icons         # poi le icone
pwsh ../../tool/fl.ps1 pub run flutter_native_splash:create   # e la splash
adb shell am start -a android.intent.action.VIEW -d filmtracker://roll/3   # prova del QR sull'emulatore
pwsh ../../tool/verify_atlas.ps1 -Project apps/film_tracker   # dalla radice: atlante contro codice
```

☠ In `pubspec.yaml` l'analyzer di build_runner ha un tetto `<14.4.0`: con la 14.5 la generazione
di Drift muore con "The setter 'contextFeatures' isn't defined".

---

## 12. Catalogo dei test

**185 test** in `apps/film_tracker/test/`.

| File | N. | Cosa dimostra |
|---|---|---|
| `test/data/film_repository_test.dart` | 33 | vedi sotto |
| `test/domain/film_catalog_test.dart` | 4 | vedi sotto |
| `test/domain/film_stats_test.dart` | 11 | vedi sotto |
| `test/domain/roll_status_test.dart` | 53 | vedi sotto (36 sono la matrice) |
| `test/features/laboratorio/cameras_page_test.dart` | 6 | vedi sotto |
| `test/features/laboratorio/development_page_test.dart` | 8 | vedi sotto |
| `test/features/laboratorio/stocks_page_test.dart` | 4 | vedi sotto |
| `test/features/photos/photo_import_test.dart` | 4 | vedi sotto |
| `test/features/photos/photo_logic_test.dart` | 11 | vedi sotto |
| `test/features/photos/roll_photos_section_test.dart` | 4 | vedi sotto |
| `test/features/qr/qr_links_test.dart` | 7 | vedi sotto |
| `test/features/qr/qr_page_test.dart` | 2 | vedi sotto |
| `test/features/rolls/home_page_test.dart` | 5 | vedi sotto |
| `test/features/rolls/roll_detail_page_test.dart` | 12 | vedi sotto (6 sono le azioni per stato) |
| `test/features/rolls/roll_editor_page_test.dart` | 1 | modificare un rullino che non esiste mostra "Questo rullino non esiste piu'" invece della rotellina eterna |
| `test/features/stats/stats_page_test.dart` | 4 | vedi sotto |
| `test/services/csv_export_test.dart` | 2 | vedi sotto |
| `test/services/film_backup_source_test.dart` | 5 | vedi sotto |
| `test/services/year_report_test.dart` | 4 | vedi sotto |
| `test/widget/paywall_config_test.dart` | 5 | vedi sotto |

### `film_repository_test.dart` (33, su `AppDatabase.memory()`, orologio fisso 2026-10-08 12:00 UTC)

- **catalogo** (8): al primo avvio ci sono le 25 pellicole di `kFilmCatalog`, nessuna
  personalizzata; ordinate per marca e nome; **`seedCatalog` rilanciato non crea doppioni**; una
  personalizzata si aggiunge, si modifica e si cancella; **un doppione a meno di maiuscole e'
  rifiutato e indica l'esistente**; le pellicole del catalogo non si modificano ne' si cancellano;
  **cancellare una pellicola lascia il rullino col suo `filmName`** (e `filmStockId` NULL); le piu'
  usate: per numero di rullini, poi per uso piu' recente, al massimo 5.
- **macchine** (4): si aggiungono in fondo e contano i loro rullini; disattivata sparisce dalla
  scelta ma resta nell'inventario; **cancellarla stacca i rullini, non li cancella**; un formato
  fuori dalle chiavi e' rifiutato dal CHECK.
- **rullini** (8): **`sequenceNumber` e' max + 1, anche dopo una cancellazione in mezzo**;
  `sequenceNumber` UNIQUE nello schema (anche senza repository); default: ISO esposto = nominale,
  `createdAt` dall'orologio; i CHECK rifiutano stato sconosciuto, **fine prima del caricamento**,
  costo negativo; **`updateRoll` non tocca stato, numero e copertina**; `setRollStatus`: le
  ammesse passano, le vietate lanciano RollTransitionException, `force` passa sempre, lo stesso
  stato non e' un errore, rullino inesistente = StateError; `markFinished`: data e `loaded →
  exposed`, in un altro stato solo la data; le sezioni della home filtrano per stato, dal numero
  piu' alto.
- **sviluppo e stampe** (6): **al massimo uno sviluppo: il secondo salvataggio sostituisce il
  primo** (stesso id); lo schema rifiuta un secondo sviluppo scritto a mano (UNIQUE); il ritorno non
  puo' precedere la consegna; stampe multiple dalla consegna piu' vecchia, senza data in fondo;
  `suggestedStatus` legge sviluppo e stampe del rullino; i laboratori usati dal piu' frequente,
  senza doppioni di maiuscole.
- **immagini e cancellazioni** (4): **la prima immagine diventa la copertina**, l'ordine e' quello
  d'inserimento; la copertina deve essere un'immagine dello stesso rullino; cancellare la copertina
  lascia il rullino senza (setNull) e `deleteImage` restituisce lo StoredImage (null la seconda
  volta); **cancellare un rullino porta via sviluppo, stampe e immagini e restituisce i file**
  (path e thumbPath nell'ordine), senza toccare l'altro rullino.
- **stream e righe composte** (3): `watchRollItems` unisce macchina, sviluppo, stampe e copertina
  (e la sezione archivio esclude quello in macchina); **lo stream si riemette quando cambia una
  tabella collegata**; `statsRolls`: la data e' il caricamento, o il giorno di creazione.

### `film_catalog_test.dart` (4)

Le 25 emulsioni del piano, senza doppioni; processi e ISO facili da sbagliare (**XP2 Super C-41**,
Velvia e Provia E-6, FP4+ 125, Tri-X BW; tutte in 35mm); le chiavi salvate nel database sono quelle
del piano (`35mm, 120, 110, large, other`; `C-41, E-6, BW, ECN-2, other`; tipi d'immagine) e
tornano indietro con `byKey`, chiave ignota → null; fotogrammi preimpostati per formato (36, 12,
24, 1, 36).

### `film_stats_test.dart` (11, dataset noto calcolato a mano: cinque rullini nel 2026, uno nel 2025, uno nel 2024)

`forYear(2026)` (10): rullini e fotogrammi potenziali; la spesa per voce e il totale in centesimi;
**le medie contano solo i rullini con almeno un costo**; il laboratorio piu' usato **ignora
maiuscole e spazi e lo sviluppo in casa**; l'emulsione piu' usata con la grafia vista per prima;
la macchina piu' usata: **a parita' vince l'id piu' basso**; rullini per mese, gennaio in posizione
0; **il 31 dicembre appartiene al suo anno**; un anno senza costi ha le medie null, non zero; un
anno vuoto e' tutto a zero, mai null. `years` (1): gli anni con rullini, dal piu' recente.

### `roll_status_test.dart` (53)

- **matrice 6x6** (36 + 2): ogni coppia da → a, con la tabella **riscritta a mano dal piano** e
  non derivata da `allowedTransitions` (un errore nella mappa deve far fallire il test); lo stesso
  stato non e' mai una transizione; **nessuno stato e' un vicolo cieco**.
- **sectionFor** (2): `loaded`/`exposed` in macchina, `sentForDevelopment` in laboratorio, il resto
  archivio; `statusesIn` e' l'inverso e copre ogni stato una volta.
- **chiavi** (1): quelle del piano, e tornano indietro.
- **suggestFrom, otto combinazioni** (9): niente → resta `exposed`; consegnato e non tornato →
  `sentForDevelopment`; registrato senza date → consegnato; tornato → `developed`; **in casa anche
  senza date → `developed`**; tornato con stampa in attesa → resta `developed`; una stampa tornata
  fra due → `printed`; **stampa tornata senza sviluppo registrato → `printed`**; una stampa tornata
  vince anche su uno sviluppo ancora in laboratorio.
- **lo stato messo a mano** (3): `archived` resta `archived` qualunque cosa sia registrata;
  `loaded` con la data di fine → `exposed`, senza resta; **senza eventi non si suggerisce mai di
  tornare indietro**.

### `cameras_page_test.dart` (6, `pumpFilm` con le rotte)

L'elenco mostra macchina, formato e "3 rullini"; **la prima macchina e' gratis** (si apre il
modulo, niente paywall); **la seconda senza Pro apre il paywall**; la seconda col Pro apre il
modulo, si salva ("Pentax MX") e torna all'elenco; **la rotta di creazione aperta direttamente senza
Pro mostra il lucchetto** (un deep link non aggira il limite); eliminare avvisa "I 4 rullini
scattati con questa macchina restano, senza macchina." e cancella.

### `development_page_test.dart` (8)

Costi (3): euro in centesimi con virgola o punto; vuoto, testo e negativi non sono importi; il testo
del campo rilegge gli stessi centesimi. Pagina (5): **consegnato senza ritorno → il rullino passa in
laboratorio** (processo C-41 dalla pellicola, consegna oggi, 12,50 → 1250, snack "Il rullino ora
risulta in laboratorio"); con la data di ritorno → sviluppato; **sviluppato in casa: niente
laboratorio (il campo sparisce), il rullino e' sviluppato**; **un rullino ancora "in macchina" esce
comunque dalla macchina** (`loaded → sentForDevelopment` forzato da `applySuggestedStatus`); un
costo non valido mostra l'errore e blocca il salvataggio.

### `stocks_page_test.dart` (4)

Raggruppato per marca con ISO, processo e formato, la ricerca filtra; **solo le personalizzate hanno
il menu** (e il chip "Tua"); una personalizzata nuova si salva; **il doppione a meno di maiuscole da'
un errore leggibile ("“Kodak Portra 400” in 35 mm è già nell’elenco.") con "Usa quella" e non crea
niente**; cambiare il nome toglie l'errore.

### `photo_import_test.dart` (4, ImageStore **vero** su cartella temporanea, AppDatabase.memory, JPEG veri fatti col pacchetto `image`)

**Importa, ridimensiona a 1600 px, salva la miniatura e conta le illeggibili** (tre file, uno di
quattro byte a caso: 2 importate, 1 fallita, avanzamento `[1, 2, 3]`, un'immagine piu' piccola non
si ingrandisce, il tipo scelto, file e miniature esistono, la prima diventa copertina); annullato
prima di cominciare non importa niente; **annullato durante: tiene la foto in corso e si ferma**;
**"libera spazio": `pruneOrphans` con `allImagePaths` toglie solo gli orfani** (immagine e
miniatura dell'orfano, le altre restano).

### `photo_logic_test.dart` (11)

`reorderIds` (5): in avanti, all'indietro, sul posto, indici fuori misura non rompono e non perdono
foto, non modifica la lista ricevuta. `coverAfterDelete` (4): cancellare un'altra foto lascia la
copertina; **cancellare la copertina passa alla prima rimasta**; senza copertina la prende la prima
rimasta; cancellata l'ultima, nessuna. `formatBytes` (1): unita' decimali e separatore della lingua.
`ImportProgress` (1): frazione e copia.

### `roll_photos_section_test.dart` (4, `pumpWithFakeRepo`)

Vuota: invito ad aggiungere, niente griglia e niente "Riordina"; piena: una miniatura per foto, la
copertina segnata (Semantics "Foto 2, Copertina", una stella), "Riordina"; pressione lunga "Usa come
copertina" cambia la copertina; **eliminare la copertina, con conferma, passa la copertina alla foto
rimasta** (e la copertina non offre "Usa come copertina").

### `qr_links_test.dart` (7)

`sequenceFromUri` (4): legge la forma che scriviamo; tollera barra finale, host vuoto e maiuscole
in schema e host; rifiuta altri schemi e percorsi; **rifiuta numeri non positivi, segni, esponenti,
esadecimali e numeri enormi**. `locationForRollLink` (3, AppDatabase.memory): porta al dettaglio
del rullino **con quel numero, per id**; null per un rullino che non c'e' o un link non nostro;
**`listenRollLinks` apre solo i link validi di rullini esistenti**.

### `qr_page_test.dart` (2)

Mostra il QR **su fondo bianco**, "#17", la pellicola, il titolo, e la Semantics "Codice QR del
rullino 17"; rullino cancellato: lo dice invece di un QR vuoto.

### `home_page_test.dart` (5, `pumpRollPage`, schermo 800x2000)

Senza rullini: **un invito solo, non tre sezioni vuote** (il pulsante "NUOVO RULLINO" c'e' sempre);
le tre sezioni con le loro card (in macchina "Caricato 7 giorni fa", **in laboratorio chi aspetta di
piu' in cima** con "10 GG" e la frase intera per il lettore di schermo, archivio "▸ 4 PRAGA" con la
striscia segnaposto); sezioni vuote accanto a quelle piene: righe d'invito, **senza data di consegna
non si inventano i giorni**, archivio vuoto = due strisce disegnate; un rullino terminato dice
"Terminato · da consegnare" col furgone; `edgeLabelOf` **non ripete l'ISO che e' gia' nel nome**.

### `roll_detail_page_test.dart` (12, `pumpRollPage`)

Per ognuno dei 6 stati **le azioni giuste** (tabella di §9) e nessun suggerimento;
"Rullino terminato" in un tocco chiama `markFinished` con oggi e poi mostra "Consegna"; **"Archivia"
passa ad `archived` senza forzare**; **il cambio di stato a mano offre solo le transizioni
ammesse**; sviluppo tornato su un rullino "terminato": **suggerisce "Sviluppato"** e "Applica" chiama
`setRollStatus(developed, force: false)`; la timeline mostra date e costi (15 + 8 + 5 + 6 = **"Spesa
totale: 34,00"**); un rullino che non esiste piu' lo dice.

### `stats_page_test.dart` (4)

Senza Pro la pagina mostra il lucchetto e nessun numero; **col Pro i numeri dell'anno piu'
recente** (3 rullini, 84 fotogrammi, spesa per voce, totale 51,90 €, media 25,95 € "sui 2 rullini
con costi", **"COSTO PER FOTOGRAMMA (STIMA)" con "≈ 0,72 €" e la spiegazione**, i piu' usati, "1
rullino sviluppato in casa", grafico `[2, 0, 1, 0...]` con Semantics "gen 2, feb 0, mar 1");
scegliendo un altro anno i numeri cambiano; **"I tuoi dati" senza Pro: ProBadge sulle quattro voci
Pro e non sul ripristino**, e il CSV apre il paywall.

### `csv_export_test.dart` (2)

Intestazione (le 25 colonne in italiano), **BOM**, CRLF, una riga per rullino **dal numero piu'
basso** anche se arrivano al contrario; il rullino senza niente ha celle vuote e **totale vuoto (non
0)**; titolo con `;` e nota con le virgolette quotati; costi "15,90"; laboratori delle stampe senza
doppioni di maiuscole; totale 38,45. Sviluppo in casa senza costi: "Bianco e nero", **"Sì"** e
totale vuoto.

### `film_backup_source_test.dart` (5, due telefoni: due AppDatabase e due cartelle temporanee, BackupService vero)

- **sostituisci tutto** (2): riporta macchine (anche la dismessa con la nota), pellicola
  personalizzata **ricollegata**, pellicola del catalogo ritrovata da marca/nome/formato, rullini
  **coi loro numeri**, sviluppo, stampe, foto nell'ordine col loro tipo, **copertina ricucita** e
  file identici; **la foto del rullino sostituito non resta orfana sul telefono**; ripristinare
  sullo stesso telefono non perde le foto che il file riscrive.
- **aggiungi** (1): tiene i rullini del telefono, **rinumera solo i numeri occupati** (il #1
  occupato: il Portra va dopo il massimo, gli altri tengono il loro), "olympus / om-2 " e' la stessa
  macchina, le nuove in fondo; **lo stesso backup una seconda volta non duplica niente**.
- **file rovinati** (2): **un percorso d'immagine fuori dalla cartella (`images/../../segreti.txt`)
  e' FormatException e non scrive niente** (transazione annullata); uno stato sconosciuto o un campo
  del tipo sbagliato sono FormatException, non TypeError.

### `year_report_test.dart` (4, il vero font degli asset)

`rollsOfYear` tiene solo l'anno chiesto, dal numero piu' basso (con `loadedAt` del 2025); copertina
piu' una pagina per rullino (3 pagine, inizia con `%PDF-`), **una foto mancante non lo fa fallire**,
e **si leggono solo le miniature** (`images/thumbs/`); un rullino con 30 foto continua sulle pagine
dopo (almeno 3) senza far fallire il documento; `buildYearReport` restituisce i byte di un anno
senza costi.

### `paywall_config_test.dart` (5)

Ogni funzione bloccata e' nel paywall e il paywall non promette altro, in it e in en; ogni
FeatureKey e' dichiarata; una macchina si', la seconda solo col Pro; **foto e rullini sono gratis**
(F6.0 punto 3); statistiche, PDF, CSV e backup sono Pro.

### Impianto

| File | Cosa offre |
|---|---|
| `test/features/laboratorio/fake_film_repo.dart` | `class FakeFilmRepository extends FilmRepository` (liste in memoria, stream broadcast; doppione di pellicola, transizioni e stato suggerito rifatti con la stessa RollStatusMachine), `class FakeEntitlementNotifier extends EntitlementNotifier`, `rullino(int id, {RollStatus status, int? stockId})`, costanti `portra400`, `hp5`, `miaPellicola`, `om2`, `oggi` (8/10/2026), `Future<FakeFilmRepository> pumpFilm(WidgetTester tester, {Widget? page, List<RouteBase>? routes, String? initialLocation, required bool pro, List<FilmRoll>? rolls, List<Camera>? cameras, List<FilmStock>? stocks, List<Development>? developments, Map<int, int>? rollCounts})`, `Future<void> tapSalva(WidgetTester tester)` |
| `test/features/photos/fake_photo_repo.dart` | `class FakePhotoRepository extends FilmRepository` (registra le chiamate, es. `coverCalls`), `testRoll({int id, int seq, int? cover, String? title})`, `testImage(int id, {int rollId, int order})`, `Future<FakePhotoRepository> pumpWithFakeRepo(WidgetTester tester, Widget page, {required FilmRoll roll, List<RollImage>? images})` (cartella inesistente: le miniature mostrano il segnaposto) |
| `test/features/rolls/fake_roll_repo.dart` | `class FakeRollRepository extends FilmRepository` (registra `statusCalls`), `roll(...)`, `om2`, `development(...)`, `testToday` (8/10/2026), `Future<FakeRollRepository> pumpRollPage(WidgetTester tester, Widget page, {List<FilmRoll>? rolls, List<Camera>? cameras, List<Development>? developments, List<PrintOrder>? prints})` (schermo 800x2000: home e dettaglio sono liste pigre) |

⚑ **Niente database vero nei widget test**: `testWidgets` gira in FakeAsync, che congela l'I/O di
SQLite, e gli stream non arrivano mai (lezione di TrashCan). Che le scritture vere funzionino lo
dimostrano `film_repository_test`, `photo_import_test`, `qr_links_test` e `film_backup_source_test`
(test normali, non widget).
⚑ `tapSalva` usa `scrollUntilVisible` e poi `ensureVisible`: i moduli sono ListView che costruiscono
solo le righe visibili, e il pulsante in fondo non esiste finche' non ci si arriva.
⚑ **Niente golden**: i caratteri cambiano fra Windows e Mac. L'aspetto lo verificano i giri
sull'emulatore e sul simulatore. **Niente test d'integrazione di regressione**: `integration_test/`
ha solo i giri che producono screenshot e video dello store.

---

## 13. Trappole gia' disinnescate e regole

Ognuna e' costata tempo almeno una volta (qui o in un'app precedente). Sono qui perche' il sintomo
non nomina mai la causa.

| Sintomo | Causa | Dove |
|---|---|---|
| Cancello un rullino e restano sviluppi, stampe e immagini orfani | SQLite tiene `foreign_keys` spento | `PRAGMA foreign_keys = ON` in `beforeOpen` |
| "unable to open database file" solo su telefono | cartella temporanea non scrivibile | `sqlite3.tempDirectory` |
| Una chiave nuova del dominio rifiutata solo in produzione | CHECK con una lista copiata | CHECK costruiti da `filmFormatKeys` & co. |
| Un'emulsione aggiunta al catalogo non arriva agli utenti | il seed gira solo a `onCreate` | serve un passo di migrazione (`seedCatalog` e' idempotente) |
| Pellicole cancellate dall'utente che ricompaiono | seed a ogni avvio | seed solo alla creazione |
| Due "Kodak Portra 400" nel catalogo | doppione a meno di maiuscole | `_requireNoDuplicateStock` in Dart + UNIQUE |
| Il rullino perde il nome quando si cancella la sua pellicola | nome letto dalla pellicola | `film_name` denormalizzato |
| Le etichette QR non corrispondono piu' dopo un ripristino | id del database nel QR / rinumerazione a cascata | il QR porta `sequenceNumber`; ripristino "aggiungi" in due passate |
| Le foto restano sul telefono dopo aver cancellato un rullino | il cascade toglie le righe, non i file | `deleteRollAndCollectImagePaths` + cancellazione in `_delete` |
| Le foto restano dopo un "sostituisci tutto" | idem | `FilmBackupSource` cancella gli orfani dopo la transazione |
| Il backup di ieri sullo stesso telefono fa sparire foto | si cancellavano anche quelle che il file riscrive | si tolgono dagli orfani i percorsi del file |
| Un backup malevolo scrive o cancella fuori dalla cartella | percorsi `..` o assoluti | `_imagePath` nell'app, zip slip scartato in `BackupService._restoreImages` (micro_core) |
| Un file di backup rovinato fa crashare l'app | TypeError da un cast; `restore` intercetta solo Exception | `importPayload` converte in FormatException |
| Una data storta rompe in silenzio i confronti | `withLength(10)` non valida il contenuto | `_date` con CivilDate.tryParse |
| L'interfaccia si blocca importando dieci foto | ridimensionamento sul thread della UI | `ImageStore.importFile` in isolate (`compute`) |
| Il telefono esaurisce la memoria importando | dieci isolate in parallelo | una foto alla volta |
| L'import si ferma a meta' con la finestra aperta | il decoder di `image` lancia un **Error** su un file rotto | `importBytes` `on Object` in micro_core + `catch` in `importRollPhotos` |
| Una foto "illeggibile" sparisce dalla galleria dell'utente | si cancellava la copia di image_picker anche fuori dalla cache | `_discardPickerCopy` solo per `/cache/` e `/tmp/` |
| Le foto spariscono dopo un aggiornamento dell'app | percorsi assoluti | percorsi **relativi** risolti con AppPaths |
| Miniatura rotta (errore rosso) nella griglia | file sparito | `RollImageThumb.errorBuilder` → segnaposto |
| Il riordino delle foto sposta di una posizione in piu' | `onReorder` (deprecato) contava l'elemento trascinato | `onReorderItem` + `reorderIds` con indice finale |
| La foto ingrandita non si puo' esplorare | il PageView vince il trascinamento | NeverScrollableScrollPhysics con lo zoom |
| Un rullino con le foto ma senza anteprima | copertina mai scelta o cancellata | prima foto = copertina (`addImage`), `coverAfterDelete` |
| La seconda macchina e' gratis | conteggio da `.value` null (stream non ascoltato) | `openNewCamera` conta dal repository; `NewCameraGate` aspetta |
| Il conteggio non arriva mai | `ref.read(provider.future)` di uno stream in pausa (Riverpod 3) | leggere dal repository |
| Il lucchetto lampeggia sulla pagina della macchina appena salvata | conteggio vivo | conteggio congelato all'apertura |
| Una pagina Pro aperta da un link si vede gratis | Pro controllato solo all'ingresso | `ProGate` / `NewCameraGate` sulla rotta |
| Pagina d'errore di go_router aprendo una pagina Pro | `redirect` su un `push` | niente redirect |
| Aprendo dal QR la freccia indietro sparisce | deep link di Flutter acceso (`go`) | spento in manifest e Info.plist; `app_links` + `push` |
| Il link del QR arriva due volte all'avvio | `getInitialLink` + `uriLinkStream` | solo `uriLinkStream` (app_links 6) |
| L'app riaperta dai recenti legge il link vecchio | Android ricrea l'attivita' con l'intent del launcher | `MainActivity.onNewIntent` → `setIntent` |
| Un link scritto a mano manda in eccezione il router | `int.parse` | `_id` con `tryParse ?? -1` |
| `/cameras/abc` apre il modulo di una macchina **nuova** gratis | id illeggibile trattato come null | -1, non null |
| QR illeggibile dal telefono | codice chiaro su fondo scuro | etichetta bianca con inchiostro nero sempre |
| Un QR stampato da chiunque fa danni | testo esterno non validato | `sequenceFromUri`: solo cifre, max 9, > 0 |
| Chip dell'ISO tirato celeste in mezzo all'arancio | terziario ricavato dal seme | `withFilmLook` imposta anche `tertiary*` |
| "12 GG" spezzato in cinque pezzi | spaziatura da bordo pellicola sui numeri grandi | `edgeText`: 0,04 da 16 pt in su |
| "PORTRA 400 400" | ISO aggiunto anche quando e' nel nome | `edgeLabelOf` |
| Il PDF mostra quadrati al posto di "’" o "€" | Helvetica WinAnsi | Plus Jakarta incorporato |
| Il PDF lancia su "8,50 €" in certe lingue | U+202F non e' nel font | `_t` → U+00A0 |
| Un "bold" nel PDF ricade sull'Helvetica | il font variabile non ha un'istanza bold | tema con lo stesso file anche per bold/italic |
| Un rullino con venti foto fa fallire il PDF | una Page sola | un MultiPage per rullino, una riga di foto per figlio |
| Il PDF di un anno pesa 100 MB | immagini grandi | miniature da 400 px |
| Il PDF dice "12 rullini" e ne mostra 11 | regole diverse per l'anno | `reportDateOf` = regola di `statsRolls` |
| "1,200" letto 1,2 da Excel / costi a 6,4999 | numeri formattati in inglese, double | `_euros` dagli interi |
| Un rullino regalato abbassa la media | costo assente contato come zero | `hasAnyCost`, totale vuoto nel CSV |
| Costo per fotogramma preso per esatto | fotogrammi nominali | "stima", "≈" e spiegazione (pagina e PDF) |
| Il dettaglio dice "sviluppato" accanto a stampe ritirate | stato non aggiornato dopo il salvataggio | `applySuggestedStatus` |
| Un rullino resta "in macchina" coi negativi tornati | `loaded → sentForDevelopment` non e' ammessa | `applySuggestedStatus` forza solo da `loaded` |
| Il suggerimento di stato lampeggia aprendo il dettaglio | calcolato prima che arrivino sviluppo e stampe | solo con entrambi `hasValue` |
| Il testo scritto in un modulo sparisce a meta' compilazione | modulo che segue lo stream del database | i moduli (sviluppo, stampa, rullino, macchina) leggono una volta sola |
| Una release regala il Pro | billing finto in release | `assertUsableInRelease` |
| Ogni verifica d'acquisto rifiutata come "app sconosciuta" | `appId` col trattino basso mandato al server | `licenseAppId` |
| L'app non si accorge di un acquisto gia' fatto | bootstrap dimenticato | `EntitlementNotifier.build` lo avvia |
| Un widget test resta appeso | FakeAsync congela l'I/O di SQLite | repository finti |
| Generazione Drift: "contextFeatures isn't defined" | analyzer 14.5 | tetto `<14.4.0` |
| "Activity class does not exist" | plugin Kotlin mancante nel template | `id("org.jetbrains.kotlin.android")` |
| Build: "requires core library desugaring" | flutter_local_notifications (micro_core) su minSdk 24 | `isCoreLibraryDesugaringEnabled = true` |
| Icona iOS rifiutata a caricamento finito | canale alfa | fullbleed opaca + `remove_alpha_ios` |
| Filo scuro agli angoli dell'icona iOS | angoli riempiti col blu notte | riempiti col colore del quadrato |
| Testi dei permessi iOS in inglese su un iPhone italiano | `InfoPlist.strings` solo su disco | gruppo di varianti con `aggiungi_infoplist_strings.rb` |

### Regole non negoziabili

1. **Tutte le letture e scritture passano da `FilmRepository`.** Numero progressivo, transizioni,
   uno sviluppo per rullino, copertina dello stesso rullino e catalogo intoccabile non hanno un
   vincolo SQL completo che li difenda.
2. **Le date civili sono CivilDate/TEXT `YYYY-MM-DD`**, mai DateTime; gli istanti ms UTC; **i soldi
   centesimi interi**.
3. **Il dominio non contiene stringhe dell'app**: nomi e frasi dagli ARB (`labels.dart`).
4. **Nessuna pagina scrive `if (isPro)`**: si passa da `featureGateProvider` e `filmFeatureLimits`.
5. **Ogni chiave limitata ha il suo beneficio nel paywall e viceversa.**
6. **Le chiavi stabili non si rinominano**: `FilmFormat.key`, `FilmProcess.key`, `RollStatus.key`,
   `RollImageKind.key`, `FilmBackupSource.id`, lo schema `filmtracker`, il formato del link del QR
   (le etichette stampate esistono per sempre).
7. **Il QR porta `sequenceNumber`, mai l'id**; il ripristino tiene i numeri quando puo'.
8. **Chi cancella righe con immagini cancella anche i file** (o li lascia a `pruneOrphans`).
9. **Il deep link di Flutter resta spento**: i link passano da `app_links` e si aprono con `push`.
10. **I testi si cambiano in `tool/testi.py` / `tool/testi_*.py`**, mai negli ARB.
11. **Le icone si cambiano dall'originale con `tool/genera_icone.py`**.
12. **`applicationId`, bundle id, `proSku`, `licenseAppId` sono immutabili** dopo il primo upload;
    `android/key.properties` e il keystore non entrano mai nel repository.
13. **Mai `Platform.isX`**: `defaultTargetPlatform`.
14. **Una modifica allo schema** incrementa `schemaVersion`, aggiunge il passo in `onUpgrade` **e**
    il suo test (i CHECK nuovi richiedono di ricreare la tabella; le emulsioni nuove un passo che
    le inserisca).
15. **Dati di esempio solo con `--dart-define=FT_DEMO=true`, mai in release.**
16. **Il tema scuro e' il default**; la palette passa sempre da `withFilmLook` (ColorScheme compreso).

---

## 14. Cosa NON esiste ancora, debito, differenze dal piano, incoerenze

### Non esiste (per non cercarlo invano)

- **Nessuna interfaccia per dismettere o riordinare le macchine**: `setCameraActive` e
  `reorderCameras` esistono nel repository (e sono testati), ma nessuna schermata li chiama;
  `active` e `sort_order` diversi dal default arrivano solo da un backup. Una macchina si puo' solo
  eliminare (i rullini restano senza).
- **API pronte e non usate** da nessuna schermata: `allRollItemsProvider`, `watchRolls` (si usa
  solo `allRolls`), `watchCamera`, `watchAnyChange`,
  `formatCostCents`, il parametro `RollCover.edgeLabel` (nessuno lo passa), le chiavi l10n
  `qr_action` e `home_archive`.
- **Nessun onboarding**: la home vuota e' l'invito; nessuna preferenza propria.
- **Nessuna notifica, nessun widget, nessun calendario** (F6.0 punto 4).
- **Nessuna stampa o condivisione dell'etichetta QR dall'app**: la pagina la mostra e dice di
  stamparla o fotografarla; `RollQrLabel` e' pubblica per un futuro foglio di etichette o per il PDF.
- **Nessuna transizione Hero fra provino e dettaglio** e nessun caricamento progressivo delle
  miniature (F6.14, di proposito: il dettaglio non mostra la copertina in alto, le miniature sono
  gia' decodificate alla dimensione mostrata). Lo Hero c'e' fra griglia delle foto e visualizzatore.
- **Nessun "forza stato" manuale**: il cambio di stato offre solo le transizioni ammesse; lo stato
  fuori sequenza arriva solo dal suggerimento.
- **Nessuna icona monocromatica** Android 13 (§2bis).
- **Nessun test** dell'editor del rullino, della pagina delle stampe, del visualizzatore, delle
  impostazioni (oltre a DataSection), del PDF dal punto di vista grafico; **nessun golden**
  (scelta), **nessun test d'integrazione di regressione** (`integration_test/` ha solo i giri
  per lo store), **nessun test di migrazione** (schema 1).
- **Provata su iPad dal proprietario** (TestFlight, 2026-10-08: «mi pare che funzioni tutto»).
  Ancora da provare su Android vero: **HEIC dalla galleria** (il pacchetto `image` potrebbe non
  decodificarlo e la foto conterebbe come illeggibile) e il QR letto dalla fotocamera di sistema
  (provato solo con adb).
- **Google Play**: niente ancora (app, prodotto a 4,09 EUR senza IVA, scheda). Dopo il D-U-N-S,
  come le altre app.

### Debito tecnico

| Voce | Perche' e' rimandato | Quando va affrontato |
|---|---|---|
| **`EntitlementView`/`EntitlementNotifier` in quattro copie** (TrashCan, Full Freezer, Scorte Calore, Film Tracker) | `micro_core` non dipende da Riverpod e lo spostamento tocca tre app gia' in revisione o pubblicate | **F7** (hardening), una volta, con le prove su tutte e quattro |
| **`ProGate` in tre copie** (Full Freezer, Scorte Calore, Film Tracker) | insieme all'entitlement | F7, in `micro_core` |
| **Permesso INTERNET assente dal manifest principale** | il License Server non e' configurato nelle build (MA_LICENSE_URL vuoto) | prima di una release con il server licenze: verificare il manifest unito della release |
| **HEIC dalla galleria Android** | serve un telefono vero | prima della release; se fallisce, convertire nel picker o con un plugin nativo |
| **Monocromatica Android 13** | il disegno non si separa dal fondo | quando il proprietario fornisce `source/filmtracker_senza_sfondo.png` |
| **Dismissione e riordino delle macchine senza UI** | non richiesti dall'interfaccia essenziale | con le rifiniture o su richiesta |
| **Emulsioni nuove dopo il rilascio** | il seed gira solo alla creazione | alla prima aggiunta: passo di migrazione + test |
| **App ID, prodotto Pro da registrare; prove su iPad/telefono** | account del proprietario, dispositivi | prima della prima build firmata (F7) |
| **README del template** di flutter create | non toccato | al rituale o in F7 |
| ~~DT-10 PdfReportBuilder in `micro_core`~~ | **chiuso il 2026-10-08**: il PDF vive nell'app (`year_report.dart`), un builder generico avrebbe un utente solo | se mai servisse a una seconda app, si estraggono `_theme` e `_footer` |

### Differenze consapevoli dal piano (`develop_microapps.md` F6)

Il codice ha la precedenza; il piano e' la storia delle intenzioni.

| Il piano diceva | Il codice fa | Perche' |
|---|---|---|
| Pro 6,99 € / 9,99 € (spec, §1.3) | **4,99 €** (Play 4,09 EUR senza IVA) | decisione del proprietario (F6.0) |
| Foto Pro (F6.9), "fino a 10 rullini" gratis (spec) | foto **gratis**, rullini illimitati, una macchina gratis | F6.0 punto 3 |
| `seedColor #E0A458`, Inter + Fraunces, tipografia Fraunces sui titoli (F6.1, F6.14) | seme `#E0A458` ma la palette «C · Provino» copre il ColorScheme; Plus Jakarta Sans + Space Mono | grafica scelta dal proprietario |
| `fl_chart` fra le dipendenze (F6.1) | CustomPainter | un pacchetto in meno |
| `labelFor` e righe Drift in `RollStatusMachine` (F6.3) | niente stringhe nel dominio; `suggestFrom` con LabEvent | dominio puro e testabile |
| `suggestFrom` senza `current` | con `current` e `finishedAt`; `archived` resta | l'archiviazione e' una scelta; senza eventi non si torna indietro |
| `developments.laboratory` obbligatorio | nullable | sviluppo in casa, nome dimenticato |
| PdfReportBuilder in micro_core (F1.11, F6.11, DT-10) | PDF nell'app | un solo utente |
| creazione del rullino a passi (pellicola → macchina → ISO...) | una pagina sola nello stesso ordine | i campi arrivano gia' giusti |
| deep link del QR con go_router (F6.12) | `app_links` + `push`, deep link di Flutter spento | il deep link di Flutter fa `go` |
| `ImageStore.pruneOrphans` una volta al mese (F6.2) | a mano, "Libera spazio" nelle impostazioni | il meccanismo e' la cancellazione esplicita, `pruneOrphans` la rete |
| griglia riordinabile (F6.9) | foglio "Riordina" con una lista | Flutter riordina col trascinamento solo le liste |
| transizioni Hero griglia → dettaglio, caricamento progressivo (F6.14) | Hero solo foto → visualizzatore | vedi "Non esiste" |
| `filmName` dal catalogo con formato per riga | catalogo tutto 35mm, formato del rullino dalla macchina | non raddoppiare la lista |

Nota sul piano: l'intestazione di F6 dice "→ `v8.0.0`", mentre F6.16 dice "Branch previsto:
`v7.0.0`" (scritto prima che Scorte Calore usasse la v7): fa fede la prima.

### Incoerenze notate nel codice (non corrette: da sistemare alla prossima occasione)

Il 2026-10-08, dopo la stesura, sono state **corrette**: il form di modifica che restava sulla
rotellina con un rullino inesistente (ora dice "non esiste piu'", con un test), la macchina creata
dal form del rullino che ora si sceglie da sola, `_setStatus` che ora gestisce anche lo
StateError del rullino sparito, i commenti superati (`photo_actions`, `settings_page`,
`app_config`, `year_report`, `image_store_provider`, MainActivity.kt, `pubspec`) e il README del
template. Restano:

- `lib/features/stats/stats_page.dart`: `MonthlyBarsPainter` e' "pubblico perche' un test ne
  controlli `shouldRepaint`", ma **nessun test lo fa**.
- `lib/features/rolls/roll_cover.dart`: il parametro `edgeLabel` di `RollCover` non lo passa
  nessuno (la home usa `RollCover(cover:)`), quindi la scritta sul bordo del segnaposto non compare
  mai nell'archivio.
- `lib/data/film_repository.dart`: `watchAnyChange` e' documentato "backup automatico, export", ma
  non lo usa nessuno.
- 2 chiavi l10n non usate dal codice: `qr_action`, `home_archive`.

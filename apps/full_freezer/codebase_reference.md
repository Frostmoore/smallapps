# codebase_reference.md — Full Freezer

> Atlante dell'app **Full Freezer**: cosa c'e' nel freezer e da quanto tempo, il piu' vecchio
> per primo, e quanto e' pieno.
> **Obiettivo**: capire il codice, trovare cio' che serve e modificarlo **senza aprire i file**.
>
> **Aggiornato al**: 2026-10-07 · **Fase**: F4.0–F4.16 concluse (resta F4.17, gli store, che
> dipende dal proprietario) · **Ramo git**: `v6.0.0` · **versionName+Code**: `1.0.0+1`
> **Package Android / bundle iOS**: `com.smp.fullfreezer` (immutabile dopo il primo upload)
> **Estensione widget iOS**: `com.smp.fullfreezer.FullFreezerWidget` · **App Group**: `group.com.smp.fullfreezer`
> **SKU Pro**: `fullfreezer_pro_lifetime` — 3,99 € una tantum (stesso gradino su Play e App Store)
>
> Quello che l'app prende da `micro_core` (configurazione, preferenze, notifiche, acquisti,
> paywall, backup, CSV, immagini, date civili) **non e' ricopiato qui**: si rimanda a
> `packages/micro_core/codebase_reference.md`. Una firma copiata in due posti diverge in due
> settimane. I nomi dei tipi di `micro_core`, Flutter, Drift e dei plugin compaiono qui in
> testo semplice o dentro le firme, mai da soli fra apici inversi: cosi' `tool/verify_atlas.ps1`
> segnala solo i nomi **di quest'app** che non esistono piu'.
>
> Stato: l'app gira su Android (emulatore Android 15) e su iOS (simulatore iPhone, con
> l'estensione WidgetKit). **140 test verdi** propri, oltre a quelli di `micro_core`.
>
> Allineato al commit `b018f90` (correzioni emerse scrivendo l'atlante: movimento `moved`
> dalla pagina dell'alimento, freezer riordinabili, `ProGate`, F4.9 completa).
>
> Convenzioni dei simboli: ⚑ = scelta non ovvia, con il suo perche'. ☠ = trappola gia' pagata.

---

## 1. Dove sta cosa

| Cerchi… | Vai in… |
|---|---|
| L'avvio dell'app (config, cartelle, log, preferenze, dati demo) | `lib/main.dart` |
| Il router, il tema, il tocco su notifiche e widget | `lib/app/app.dart` |
| I percorsi di navigazione | `lib/app/routes.dart` |
| Id app, SKU, colore seme, font | `lib/app/app_config.dart` |
| I provider Riverpod dei dati, del tema, delle notifiche | `lib/app/providers.dart` |
| Il Pro: gateway, entitlement, `featureGateProvider`, `appVersion` | `lib/app/entitlement.dart` |
| Cosa e' gratis e cosa e' Pro | `lib/app/feature_limits.dart` |
| I testi e i benefici del paywall, `showFreezerPaywall` | `lib/app/paywall_config.dart` |
| I colori "A · Ghiaccio" (testata blu notte, bollino, giorni) | `lib/app/freezer_palette.dart` |
| Le icone disegnate delle categorie (bistecca, coscia, pesce…) | `lib/app/category_glyphs.dart` |
| Litri e quantita' formattati, numeri scritti con virgola o punto | `lib/app/formats.dart` |
| Italiano sui telefoni italiani, inglese altrove | `lib/app/locale_resolution.dart` |
| Le tabelle del database | `lib/data/tables.dart` |
| L'apertura del database, `PRAGMA foreign_keys`, migrazioni | `lib/data/database.dart` |
| **Tutte** le letture e scritture sul database | `lib/data/freezer_repository.dart` |
| I dati di esempio (FF_DEMO) | `lib/dev/demo_data.dart` |
| Quanti giorni ha un alimento, `fresh`/`watch`/`old` | `lib/domain/aging.dart` |
| Modelli di freezer, litri stimati, riempimento, taratura, isteresi degli avvisi | `lib/domain/capacity.dart` |
| Le 9 categorie predefinite e la chiave `custom:<id>` | `lib/domain/categories.dart` |
| La categoria dedotta dal nome ("spezzatino" → carne rossa) | `lib/domain/category_guess.dart` |
| Le sezioni della home ("Da usare prima", "Tutto il resto", "Dove sono") | `lib/domain/home_view.dart` |
| La ricerca senza accenti, su nome e note | `lib/domain/search.dart` |
| Le statistiche dello spreco | `lib/domain/stats.dart` |
| La normalizzazione dei nomi (`nameNorm`) | `lib/domain/text_norm.dart` |
| Le unita' di misura | `lib/domain/units.dart` |
| "Due porzioni di lasagne" → 2, porzioni, Lasagne | `lib/domain/voice_parser.dart` |
| Il piano delle notifiche (date del riepilogo, testo, orari degli avvisi) | `lib/services/notification_plan.dart` |
| La consegna delle notifiche e la valutazione della capienza | `lib/services/freezer_scheduler.dart` |
| Il contenuto del widget di sistema (Dart) | `lib/services/freezer_widget.dart` |
| Il disegno del widget Android | `android/app/src/main/kotlin/com/smp/fullfreezer/FullFreezerWidgetProvider.kt` + `res/layout/full_freezer_widget.xml` |
| Il disegno del widget iOS | `ios/FullFreezerWidget/VistaFreezer.swift` (+ timeline in `FullFreezerWidget.swift`) |
| Backup e ripristino (formato) | `lib/services/freezer_backup_source.dart` |
| Backup, ripristino e CSV (azioni dalle impostazioni) | `lib/features/settings/data_actions.dart` |
| Il CSV | `lib/services/csv_export.dart` |
| Il microfono | `lib/services/voice_input.dart` |
| La home | `lib/features/home/home_page.dart` (+ schede e righe in `item_row_tile.dart`) |
| L'inserimento rapido | `lib/features/items/quick_add_sheet.dart` |
| L'inserimento completo e la modifica | `lib/features/items/item_edit_page.dart` |
| La bozza condivisa fra rapido e completo | `lib/features/items/item_draft.dart` |
| I fogli di scelta (categoria, ingombro, posizione), nomi visibili di unita' e categorie | `lib/features/items/item_pickers.dart` |
| Le foto dei prodotti | `lib/features/items/item_photo.dart` |
| La pagina del freezer, scomparti, taratura | `lib/features/freezers/freezer_page.dart` |
| Creazione/modifica freezer e primo avvio | `lib/features/freezers/freezer_editor_page.dart` |
| Silhouette dei modelli, barra e asticella di riempimento | `lib/features/freezers/freezer_widgets.dart` |
| Il limite di un freezer e l'apertura delle pagine Pro | `lib/features/freezers/freezer_actions.dart` |
| Storico e statistiche (Pro) | `lib/features/history/` |
| Le categorie personalizzate (Pro) | `lib/features/categories/` |
| Le impostazioni | `lib/features/settings/settings_page.dart` |
| Le righe e le etichette "Ghiaccio" comuni | `lib/features/common/ghiaccio.dart` |
| Il lucchetto delle pagine Pro aperte senza Pro (`ProGate`) | `lib/features/common/pro_gate.dart` |
| Permessi, receiver, widget, deep link spento (Android) | `android/app/src/main/AndroidManifest.xml` |
| L'intent del widget ad app chiusa | `android/app/src/main/kotlin/com/smp/fullfreezer/MainActivity.kt` |
| Permessi, schema URL, deep link spento (iOS) | `ios/Runner/Info.plist` (+ `{it,en}.lproj/InfoPlist.strings`) |
| Le stringhe tradotte | **`tool/testi.py`** (sorgente unica) → `lib/l10n/app_en.arb`, `app_it.arb` |
| L'icona e la splash | `tool/genera_icone.py` + `flutter_launcher_icons.yaml`, `flutter_native_splash.yaml` (§2bis) |

---

## 2. Albero dei file

Solo il codice scritto da noi (esclusi `lib/l10n/generated/` e `lib/data/database.g.dart`,
generati).

```
apps/full_freezer/
├── lib/
│   ├── main.dart                         avvio: config, cartelle, log, preferenze, demo. Niente database.
│   ├── app/
│   │   ├── app.dart                      buildRouter, FullFreezerApp: router, tema, ciclo di vita, tocchi
│   │   ├── app_config.dart               buildFreezerConfig(): id, nome, SKU, seme #0461E5, font
│   │   ├── category_glyphs.dart          CategoryGlyph + CategoryGlyphPainter (icone disegnate 24x24)
│   │   ├── entitlement.dart              Pro: gateway, EntitlementView/Notifier, featureGateProvider, appVersion
│   │   ├── feature_limits.dart           freezerFeatureLimits (ADR-017)
│   │   ├── formats.dart                  formatLiters, formatQuantity, parseUserNumber
│   │   ├── freezer_palette.dart          FreezerPalette (ThemeExtension) + withFreezerLook
│   │   ├── locale_resolution.dart        kSupportedLocales, resolveAppLocale
│   │   ├── paywall_config.dart           buildFreezerPaywall, showFreezerPaywall
│   │   ├── providers.dart                provider radice, FreezerSettingKeys, notifier di tema/notifiche
│   │   └── routes.dart                   Routes: percorsi in costanti
│   ├── data/
│   │   ├── tables.dart                   5 tabelle Drift + ItemStatus + MovementKind
│   │   ├── database.dart                 AppDatabase (schema 1), apertura su file/in memoria
│   │   ├── database.g.dart               GENERATO da drift_dev
│   │   └── freezer_repository.dart       NewItem + FreezerRepository: la sola porta sui dati
│   ├── dev/
│   │   └── demo_data.dart                seedDemoData (solo con --dart-define=FF_DEMO=true, mai in release)
│   ├── domain/                           Dart puro: niente Flutter, niente database (tranne i tipi riga)
│   │   ├── aging.dart                    AgingLevel, AgingInfo, AgingCalculator, compareOldestFirst
│   │   ├── capacity.dart                 FreezerModel(s), FillLevel, FillInfo, CapacityEstimator, AlertLevel, AlertDecision, CapacityAlertPolicy
│   │   ├── categories.dart               ItemCategory, ItemCategories, customCategoryKey/Id
│   │   ├── category_guess.dart           guessCategory (dizionario it/en)
│   │   ├── home_view.dart                ItemRow, FreezerSummary, HomeView, buildHomeView
│   │   ├── search.dart                   searchItems
│   │   ├── stats.dart                    StatsPeriod, MonthBar, WasteStats, computeStats
│   │   ├── text_norm.dart                normalizeName
│   │   ├── units.dart                    Units
│   │   └── voice_parser.dart             ParsedItem, VoiceItemParser
│   ├── features/
│   │   ├── categories/custom_categories_page.dart, custom_category_editor.dart   (Pro)
│   │   ├── common/ghiaccio.dart          GhiaccioSectionLabel, GhiaccioTile
│   │   ├── common/pro_gate.dart          ProGate: il Pro controllato sulla pagina
│   │   ├── freezers/freezer_actions.dart, freezer_editor_page.dart, freezer_page.dart, freezer_widgets.dart
│   │   ├── history/history_page.dart, stats_page.dart                             (Pro)
│   │   ├── home/home_page.dart, item_row_tile.dart
│   │   ├── items/item_draft.dart, item_edit_page.dart, item_photo.dart, item_pickers.dart, quick_add_sheet.dart
│   │   ├── search/search_page.dart
│   │   └── settings/data_actions.dart, settings_page.dart
│   ├── services/
│   │   ├── csv_export.dart               exportStoredCsv, buildStoredCsv
│   │   ├── freezer_backup_source.dart    FreezerBackupSource (BackupSource di micro_core)
│   │   ├── freezer_scheduler.dart        freezerChannel, NotificationSettingKeys, FreezerScheduler
│   │   ├── freezer_widget.dart           FreezerWidget: righe, icone PNG, pubblicazione, sveglie
│   │   ├── notification_plan.dart        DigestFrequency, digestDates, digestFor, alertTime, PendingAlert, digestId
│   │   └── voice_input.dart              VoiceInput (speech_to_text)
│   └── l10n/
│       ├── app_en.arb                    template (249 chiavi) — GENERATO da tool/testi.py
│       ├── app_it.arb                    italiano, stesse chiavi — GENERATO da tool/testi.py
│       └── untranslated.json             vuoto: nessuna chiave senza traduzione
├── test/                                 140 test (§12)
│   ├── data/freezer_repository_test.dart
│   ├── domain/{aging,capacity,formats,home_view,item_photo,search,stats,text_norm,voice_parser}_test.dart
│   ├── services/{backup_csv,freezer_widget,notification_plan}_test.dart
│   └── widget/{app_smoke,paywall_config,quick_add}_test.dart
├── integration_test/flusso_test.dart     flusso vero sul dispositivo (non affidabile sull'emulatore, §14)
├── tool/
│   ├── testi.py                          SORGENTE dei testi: genera i due ARB da una tabella sola
│   ├── genera_icone.py                   genera tutte le immagini di icona e splash dall'originale
│   └── anteprima_widget_ios.swift        rende il widget iOS in PNG sul Mac (stessa vista del widget)
├── assets/
│   ├── fonts/PlusJakartaSans-Variable.ttf + OFL.txt   font variabile (dichiarato in pubspec), con licenza
│   └── icons/                            ingressi dei generatori, NON asset a runtime (§2bis)
│       ├── source/fullfreezer_originale.png        l'originale del proprietario, 1254x1254
│       ├── source/fullfreezer_senza_sfondo.png     il disegno ritagliato a mano dal proprietario
│       ├── source/anteprime/*.png                  anteprime (cerchio, squircle, monocromatica, ios)
│       └── fullfreezer_fullbleed.png, fullfreezer_logo.png, adaptive_{background,foreground,monochrome}.png,
│           splash_logo.png, splash_android12.png   prodotti da tool/genera_icone.py
├── flutter_launcher_icons.yaml           icona (§2bis)
├── flutter_native_splash.yaml            splash (§2bis)
├── l10n.yaml                             gen_l10n: template inglese, classe L, output lib/l10n/generated
├── android/app/
│   ├── build.gradle.kts                  applicationId, minSdk 24, desugaring, firma da key.properties
│   └── src/main/
│       ├── AndroidManifest.xml           permessi BILLING/BOOT/RECORD_AUDIO, receiver, widget, deep link spento
│       ├── kotlin/com/smp/fullfreezer/MainActivity.kt              onNewIntent → setIntent
│       ├── kotlin/com/smp/fullfreezer/FullFreezerWidgetProvider.kt il widget: giorni calcolati qui
│       └── res/
│           ├── drawable/ic_notification.xml        fiocco di neve monocromatico (barra di stato)
│           ├── drawable/widget_background.xml      rettangolo blu notte #0B1A33, raggio 22dp
│           ├── layout/full_freezer_widget.xml      il widget: testata + 3 righe fisse (solo RemoteViews)
│           ├── layout/full_freezer_widget_preview.xml  anteprima nel selettore, righe d'esempio
│           ├── xml/full_freezer_widget_info.xml    4x2, updatePeriodMillis 0
│           ├── values/widget.xml, values-it/widget.xml   testi e stili del widget
│           │
│           │   ↓ GENERATO, non si modifica a mano (§2bis)
│           ├── values*/styles.xml, drawable*/launch_background.xml   splash
│           └── mipmap-*, drawable-*dpi/*.png                         icone
└── ios/
    ├── Runner.xcworkspace                    si apre questo, non .xcodeproj (niente Podfile: SPM)
    ├── Runner/AppDelegate.swift, SceneDelegate.swift    template Flutter, non toccati
    ├── Runner/Info.plist                     permessi (testi inglesi), schema fullfreezer, deep link spento
    ├── Runner/{en,it}.lproj/InfoPlist.strings  testi dei permessi nelle due lingue (F4.14)
    ├── Runner/Runner.entitlements            App Group group.com.smp.fullfreezer
    ├── Runner/PrivacyInfo.xcprivacy          UserDefaults CA92.1 + 1C8F.1, nessun dato raccolto
    └── FullFreezerWidget/
        ├── FullFreezerWidget.swift           @main Widget, TimelineProvider (8 voci), widgetURL
        ├── VistaFreezer.swift                lettura del contenitore + disegno SwiftUI (anche su macOS)
        ├── FullFreezerWidget.entitlements    App Group
        ├── Info.plist                        NSExtension widgetkit
        └── PrivacyInfo.xcprivacy             UserDefaults 1C8F.1
```

---

## 2bis. Icona e schermata di avvio

L'icona e' **fornita dal proprietario**: `assets/icons/source/fullfreezer_originale.png`,
1254x1254 RGB, un quadrato arrotondato blu con un fiocco/freezer al centro e **angoli neri**
fuori dall'arrotondamento. Tutto il resto si genera in due passi.

```
python apps/full_freezer/tool/genera_icone.py             # 1. dall'originale alle immagini di ingresso
cd apps/full_freezer
pwsh ../../tool/fl.ps1 pub run flutter_launcher_icons       # 2a. icone Android e iOS
pwsh ../../tool/fl.ps1 pub run flutter_native_splash:create # 2b. splash Android e iOS
```

`tool/genera_icone.py` produce in `assets/icons/`:

| File | A cosa serve |
|---|---|
| `fullfreezer_fullbleed.png` | quadrato pieno senza angoli neri: icona iOS, icona Play 512, icona legacy Android |
| `fullfreezer_logo.png` | il quadrato arrotondato con gli angoli trasparenti: sito, splash iOS |
| `adaptive_background.png` | Android 8+: livello di sfondo 1080x1080 (108 dp) |
| `adaptive_foreground.png` | Android 8+: solo il disegno, su trasparente, nella zona sicura |
| `adaptive_monochrome.png` | Android 13+: sagoma piatta per le icone a tema |
| `splash_logo.png` | splash fino ad Android 11 e iOS: il disegno senza sfondo del proprietario |
| `splash_android12.png` | splash Android 12+: lo stesso disegno nei due terzi centrali |

⚑ **Lo sfondo adattivo e' un'immagine, non un colore**: e' l'icona stessa alla stessa scala
del primo piano. Dove il ritaglio automatico del disegno sbaglia (le sfaccettature blu scure
del fiocco hanno lo stesso colore dello sfondo) sotto si vede esattamente l'originale.
`adaptive_icon_foreground_inset: 0` perche' lo script dimensiona gia' il primo piano nella
zona sicura (cerchio di 66 dp su 108).

☠ **iOS non accetta il canale alfa nell'icona**: App Store Connect rifiuta la build a
caricamento finito. `fullfreezer_fullbleed.png` e' gia' opaco (gli angoli neri riempiti
allungando il blu del bordo e sfumando); `remove_alpha_ios: true` e
`background_color_ios: "#0461E5"` restano come cintura di sicurezza.

☠ **Le splash NON usano il ritaglio automatico** (`alfa_disegno` nello script): rende
trasparenti le sfaccettature blu scure e il fiocco appare "svuotato" (osservazione del
proprietario, 2026-10-06). Si usa il ritaglio a mano `source/fullfreezer_senza_sfondo.png`.

☠ **Android 12+ ritaglia la splash a cerchio** e tiene solo i due terzi centrali: la sezione
`android_12:` usa `splash_android12.png`, il disegno gia' confinato nel cerchio.

Splash: fondo `#0461E5` (il blu dell'icona, scelto dal proprietario dopo aver scartato il fondo
chiaro), `#0B1A33` nel tema scuro.

⚠️ `assets/icons/` **non** e' dichiarata in `pubspec.yaml` sotto `assets:`: sono ingressi dei
generatori, non file letti a runtime. In `pubspec.yaml` c'e' solo il font.

⚠️ Le risorse prodotte dai due comandi (mipmap, drawable-*dpi, `values*/styles.xml`,
`launch_background.xml`, `Assets.xcassets`) **non si modificano a mano**: si cambia lo yaml o
l'originale e si rilancia.

`drawable/ic_notification.xml` e' disegnato a mano (fiocco a sei bracci, solo tratti bianchi):
Android usa solo il canale alfa dell'icona di notifica, e il logo diventerebbe una macchia.

---

## 2ter. iOS

L'app e' nata con `flutter create --platforms=android,ios` (ADR-021, F4.0 punto 1): ogni
giuntura col sistema (widget, notifiche, acquisti, microfono, foto) esiste su tutte e due.

| Impostazione | Valore | Dove |
|---|---|---|
| Bundle app | `com.smp.fullfreezer` | `project.pbxproj` |
| Bundle estensione | `com.smp.fullfreezer.FullFreezerWidget` | `project.pbxproj` |
| TARGETED_DEVICE_FAMILY | `1` (solo iPhone, anche sugli iPad in modalita' iPhone) | tutti i target |
| IPHONEOS_DEPLOYMENT_TARGET | `15.0` | Runner ed estensione (stessa soglia: un'estensione piu' esigente non si installa) |
| DEVELOPMENT_TEAM | A29HGT2MQ4, nessun CODE_SIGN_IDENTITY fissato | |
| App Group | `group.com.smp.fullfreezer` | `Runner.entitlements`, `FullFreezerWidget.entitlements`, `FreezerWidget.iosGroup` |
| Schema URL | `fullfreezer` | `Info.plist` CFBundleURLTypes |
| FlutterDeepLinkingEnabled | `false` | `Info.plist` (§7) |
| ITSAppUsesNonExemptEncryption | `false` | `Info.plist` |
| Lingue | `it`, `en` (CFBundleLocalizations) | `Info.plist` |

⚑ **Niente CocoaPods**: Flutter 3.47 risolve i plugin con Swift Package Manager. Non c'e'
Podfile e non va creato.

### Come si compila sul Mac

La macchina iOS e' il Mac mini (`ssh mac`). Sul Mac la repo vive in `~/microapps` ed e' una
**copia non-git**: si sincronizza dal PC con `tar` via ssh (le cartelle `.flutter/`, `build/`
e simili restano fuori), e si compila con la toolchain del Mac in
`~/microapps-toolchain/flutter` (la stessa versione di Windows, 3.47.3, ma una copia propria:
`.flutter/` e' specifica del sistema operativo e pesa due giga).

```
export PATH="$HOME/microapps-toolchain/flutter/bin:/opt/homebrew/bin:$PATH"
cd ~/microapps/apps/full_freezer
flutter build ios --simulator --debug
xcrun simctl install <UDID> build/ios/iphonesimulator/Runner.app
xcrun simctl launch  <UDID> com.smp.fullfreezer
```

☠ Le modifiche fatte sul Mac **non tornano da sole sul PC**: la copia non e' un clone. Si
lavora sul PC e si risincronizza; quello che si cambia sul Mac (per esempio il
`project.pbxproj` toccato dagli script Ruby) va riportato indietro a mano.

### Gli script Ruby (nel monorepo, `tool/`)

Si lanciano **sul Mac**, dalla radice della copia, con `PATH=/opt/homebrew/bin:$PATH` (la
gemma `xcodeproj` e' quella di Homebrew, non quella del Ruby di sistema):

```
PATH=/opt/homebrew/bin:$PATH ruby tool/aggiungi_widget_ios.rb apps/full_freezer FullFreezerWidget group.com.smp.fullfreezer
PATH=/opt/homebrew/bin:$PATH ruby tool/aggiungi_infoplist_strings.rb apps/full_freezer
```

| Script | Cosa fa | ☠ |
|---|---|---|
| `tool/aggiungi_widget_ios.rb` | aggiunge il target dell'estensione WidgetKit al progetto Xcode, con App Group, entitlements, soglia iOS del Runner; mette *Embed App Extensions* prima di *Thin Binary* | **idempotente**: un secondo target omonimo costruisce lo stesso e produce un pacchetto con due estensioni che App Store Connect rifiuta a caricamento finito |
| `tool/aggiungi_infoplist_strings.rb` | aggiunge al Runner i `<lingua>.lproj/InfoPlist.strings` come **gruppo di varianti** | file sciolti finirebbero nel pacchetto con lo stesso nome e uno sovrascriverebbe l'altro |

Si fanno con uno script e non in Xcode perche' il Mac si guida da ssh, e perche' le altre app
devono poter rifare lo stesso passo con un comando.

### L'anteprima del widget

`apps/full_freezer/tool/anteprima_widget_ios.swift` compila **la stessa** `VistaFreezer.swift`
del widget e la rende in PNG su macOS:

```
swiftc -parse-as-library -O \
  apps/full_freezer/ios/FullFreezerWidget/VistaFreezer.swift \
  apps/full_freezer/tool/anteprima_widget_ios.swift -o /tmp/anteprima_ff \
  && /tmp/anteprima_ff /tmp/anteprima_ff.png [contenitore.plist]
```

Col secondo argomento legge il contenitore vero del simulatore
(`<AppGroup>/Library/Preferences/group.com.smp.fullfreezer.plist`): verifica in un colpo la
catena intera, da Dart che scrive alla vista che disegna, icone comprese.

☠ Esiste perche' un widget non si mette sulla schermata da riga di comando, e in TrashCan ne
era arrivato al proprietario uno mai guardato. Per questo `VistaFreezer.swift` non contiene
niente che esista solo su iOS (`#if canImport(UIKit)` / AppKit per caricare le immagini).

### Caricamento su TestFlight

`tool/build_ios.sh full_freezer` sul Mac (prende l'app come argomento; vedi l'atlante di
TrashCan per la chiave API di App Store Connect). **Non ancora eseguito per Full Freezer**
(§13).

---

## 3. Il database

Cinque tabelle, **`schemaVersion = 1`**, file `full_freezer.sqlite` nella cartella documenti
dell'app. Le date civili sono TEXT `YYYY-MM-DD` (ADR-008), gli istanti sono interi in
millisecondi UTC. Le colonne in SQL sono in snake_case (Drift converte i getter camelCase).

Legenda vincoli: **CHECK** = vincolo SQL vero, scritto nello schema; **len** = `withLength`,
controllato **solo da Drift in Dart** all'inserimento con un companion, non da SQLite.

☠ `PRAGMA foreign_keys = ON` si imposta in `beforeOpen` **a ogni connessione**: SQLite lo
tiene spento di default e senza i `references(... onDelete: ...)` sarebbero decorativi.

### `freezers`

| Colonna | Tipo | Default | Vincoli | Significato |
|---|---|---|---|---|
| `id` | INTEGER | | PK autoincrement | |
| `name` | TEXT | | len 1..40 | "Freezer cucina" |
| `model_key` | TEXT | | len 1..32 | chiave in `FreezerModels`, o `custom` |
| `capacity_liters` | REAL | | **CHECK > 0** | litri **nominali** del vano congelatore |
| `calibration` | REAL | `1.0` | | fattore di taratura (§4 `CapacityEstimator.calibrate`) |
| `last_alert_level` | TEXT nullable | **`'empty'`** | | ultimo avviso di capienza: `full` \| `empty` \| null |
| `sort_order` | INTEGER | `0` | | |
| `created_at` | INTEGER | | obbligatoria | ms UTC |

⚑ **La capacita' si salva in litri, non solo come modello**: se un giorno si corregge il
valore tipico di un modello in `FreezerModels`, i freezer gia' creati non devono cambiare
riempimento sotto gli occhi dell'utente. `model_key` resta per il disegno e per riproporre il
modello.

⚑ `last_alert_level` parte da `empty` e non da null: un freezer appena creato e' vuoto e non
deve mai ricevere "quasi vuoto" (F4.9).

### `compartments`

| Colonna | Tipo | Default | Vincoli | Significato |
|---|---|---|---|---|
| `id` | INTEGER | | PK autoincrement | |
| `freezer_id` | INTEGER | | FK → `freezers.id` **ON DELETE CASCADE** | |
| `name` | TEXT | | len 1..40 | "Cassetto 2" |
| `sort_order` | INTEGER | `0` | | |

### `items` — il cuore dell'app

| Colonna | Tipo | Default | Vincoli | Significato |
|---|---|---|---|---|
| `id` | INTEGER | | PK autoincrement | |
| `freezer_id` | INTEGER | | FK → `freezers.id` **ON DELETE CASCADE** | ridondante con lo scomparto, voluto |
| `compartment_id` | INTEGER nullable | | FK → `compartments.id` **ON DELETE SET NULL** | cancellare uno scomparto lascia l'alimento nel freezer |
| `name` | TEXT | | len 1..60 | |
| `name_norm` | TEXT | | | `normalizeName(name)`: ricerca e autocompletamento |
| `category` | TEXT nullable | | **nessuna FK** | chiave di `ItemCategories` **oppure** `custom:<id>` |
| `quantity` | REAL | | **CHECK > 0** | |
| `unit` | TEXT | | len 1..16 | chiave di `Units` |
| `frozen_at` | TEXT | | len 10..10 | `YYYY-MM-DD` (ADR-008) |
| `reminder_after_days` | INTEGER nullable | | | promemoria proprio; null = quello della categoria |
| `volume_liters` | REAL | | **CHECK > 0** | ingombro **dell'intera riga** (quantita' compresa) |
| `volume_manual` | BOOL | `false` | CHECK IN (0,1) | true = corretto a mano, la stima non lo tocca piu' |
| `photo_path` | TEXT nullable | | | percorso **relativo** (F1.11) |
| `note` | TEXT nullable | | | |
| `status` | TEXT | `'stored'` | **CHECK IN ('stored','consumed','discarded')** | gli usciti **non si cancellano** |
| `removed_at` | INTEGER nullable | | | ms UTC dell'uscita |
| `created_at` | INTEGER | | obbligatoria | ms UTC |

Indici:

| Nome | Colonne | Perche' |
|---|---|---|
| `idx_items_status_frozen` | `(status, frozen_at)` | regge la home: alimenti `stored` per data |
| `idx_items_freezer` | `(freezer_id)` | filtro per freezer, conteggi |
| `idx_items_name_norm` | `(name_norm)` | autocompletamento `LIKE 'pre%'` |

⚑ **`freezer_id` e' ridondante rispetto a `compartment_id`, ed e' voluto**: un alimento puo'
stare in un freezer senza scomparti. Ricavarlo con una join costringerebbe a uno scomparto
fittizio "Nessuno". La coerenza la garantisce `FreezerRepository._freezerFor`, che quando c'e'
uno scomparto ne copia il freezer.

☠ **`category` e' testo, non una FK**: vale sia per le chiavi in codice sia per
`custom:<id>`. Per questo `FreezerRepository.deleteCustomCategory` azzera a mano la
categoria degli alimenti che la usavano: altrimenti puntano a un id che SQLite puo' riusare,
e finiscono nella categoria di un altro.

Costanti `abstract final class ItemStatus`: `stored`, `consumed`, `discarded` (esportate
anche da `database.dart`).

### `item_movements`

| Colonna | Tipo | Vincoli | Significato |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `item_id` | INTEGER | FK → `items.id` **ON DELETE CASCADE** | |
| `kind` | TEXT | len 1..16 | `stored` \| `consumed` \| `discarded` \| `moved` \| `restored` |
| `at` | INTEGER | obbligatoria | ms UTC |
| `from_compartment_id` | INTEGER nullable | nessuna FK | per `moved` |
| `to_compartment_id` | INTEGER nullable | nessuna FK | per `stored` e `moved` |

Costanti `abstract final class MovementKind`: `stored`, `consumed`, `discarded`, `moved`,
`restored` (esportate da `database.dart`).

⚑ Un'uscita annullata **non cancella** il movimento d'uscita: aggiunge `restored`. Uno storico
che si riscrive non e' piu' uno storico.

`moved` lo scrive `FreezerRepository.moveItem`, chiamato da `ItemEditPage` quando si salva un
alimento con freezer o scomparto cambiati.

⚠️ Oggi **nessuna schermata legge `item_movements`**: le statistiche lavorano su
`items.status`/`removed_at`. La tabella e' scritta fedelmente (repository e import) per lo
storico dettagliato futuro.

### `custom_categories` (Pro)

| Colonna | Tipo | Vincoli | Significato |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | citato dagli alimenti come `custom:<id>` |
| `name` | TEXT | len 1..40 | |
| `icon_key` | TEXT | len 1..32 | una delle 9 chiavi di `customCategoryIcons` |
| `color_value` | INTEGER | obbligatoria | **sempre 0**: l'interfaccia non la usa (§5) |
| `default_reminder_days` | INTEGER nullable | | promemoria da copiare negli alimenti |

### Righe generate da Drift

Le classi **tabella** scritte a mano in `tables.dart` (estendono Table di Drift) sono
`Freezers`, `Compartments`, `Items` (con le tre `@TableIndex`), `ItemMovements`,
`CustomCategories`; il database le dichiara in `@DriftDatabase(tables: [...])` in quest'ordine.

Classi riga (in `database.g.dart`, non si modificano): Freezer, Compartment, Item,
ItemMovement, CustomCategory, piu' i rispettivi companion (FreezersCompanion,
CompartmentsCompanion, ItemsCompanion, ItemMovementsCompanion, CustomCategoriesCompanion).
I campi sono i getter delle tabelle in camelCase (`frozenAt` e' una String,
`lastAlertLevel` una `String?`, `removedAt` un `int?`).

### Migrazioni

`onUpgrade` **lancia** UnsupportedError: alla versione 1 non c'e' niente da migrare, e il
ramo resta scritto perche' la prima modifica di schema debba incrementare `schemaVersion`
**e** aggiungere qui il passo con il suo test. Senza, il primo aggiornamento in produzione
cancellerebbe i dati.

---

## 4. `lib/domain/` — il cuore, senza database

Dart puro: niente Flutter, niente I/O. Il "oggi" si passa sempre come parametro.

### `aging.dart`

`enum AgingLevel { fresh, watch, old }` — `fresh` lontano dal promemoria o senza promemoria;
`watch` dall'80% del promemoria; `old` promemoria superato.

`@immutable class AgingInfo`

| Membro | Firma | Significato |
|---|---|---|
| costruttore | `const AgingInfo({required int days, required AgingLevel level, required int? reminderDays, required int? overdueBy})` | |
| `days` | `final int` | giorni nel freezer, 0 il giorno stesso |
| `level` | `final AgingLevel` | |
| `reminderDays` | `final int?` | il promemoria usato (alimento, categoria, o null) |
| `overdueBy` | `final int?` | giorni **oltre** il promemoria; null se non superato |
| `==`, `hashCode`, `toString` | | per valore |

`class AgingCalculator`

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `const AgingCalculator({this.watchFraction = 0.8})` | |
| `watchFraction` | `final double` | |
| `daysInFreezer` | `int daysInFreezer(CivilDate frozenAt, {CivilDate? today})` | giorni di calendario; **mai negativo** (data futura = 0) |
| `defaultReminderFor` | `int? defaultReminderFor(String? categoryKey)` | promemoria della categoria predefinita; null per `custom:` e chiavi ignote |
| `evaluate` | `AgingInfo evaluate({required CivilDate frozenAt, int? reminderAfterDays, String? categoryKey, CivilDate? today})` | promemoria = quello dell'alimento, altrimenti della categoria; senza nessuno (o ≤ 0) sempre `fresh` |

Regole: `old` se `days >= reminder`; `watch` se `days >= reminder * watchFraction`.

Funzione di modulo: `int compareOldestFirst(CivilDate a, CivilDate b, {int tieA = 0, int tieB = 0})`
— data crescente, a parita' vince `tieA < tieB` (l'id: l'inserito prima).

⚑ **L'ordinamento non dipende dal livello**: ordinare per livello e poi per data farebbe
scendere un alimento vecchissimo senza promemoria sotto uno appena entrato in `watch`, e
quello senza promemoria e' proprio quello che l'utente ha dimenticato.

⚠️ Per le categorie **personalizzate** `evaluate` non conosce il promemoria della categoria
(vive nel database): funziona solo perche' quel promemoria viene **copiato** in
`reminderAfterDays` dell'alimento quando lo si assegna (`chooseCategory`, §9).

### `capacity.dart`

`@immutable class FreezerModel` — `const FreezerModel({required String key, required double liters, required String iconKey})`.
`key` stabile salvata in `freezers.model_key` (il nome sta negli ARB, `freezerModel_<key>`;
**non si rinomina mai**), `liters` nominali tipici, `iconKey` della silhouette.

`abstract final class FreezerModels`

| Membro | Firma |
|---|---|
| `customKey` | `static const String customKey = 'custom'` |
| `all` | `static const List<FreezerModel> all` — dal piu' piccolo al piu' grande |
| `byKey` | `static FreezerModel? byKey(String? key)` |

| `key` | Litri | `iconKey` (silhouette) |
|---|---|---|
| `ice_box` | 15 | `ice_box` |
| `fridge_top` | 50 | `fridge_top` |
| `combi_compact` | 70 | `combi` |
| `undercounter` | 85 | `undercounter` |
| `combi_large` | 100 | `combi` |
| `chest_small` | 100 | `chest` |
| `side_by_side` | 200 | `side_by_side` |
| `chest_medium` | 200 | `chest` |
| `upright_tall` | 270 | `upright` |
| `chest_large` | 350 | `chest` |

Valori e fonti (schede tecniche del 2026-10-06) in `develop_microapps.md` F4.3b.

`enum FillLevel { empty, normal, full }`

`@immutable class FillInfo` — `const FillInfo({required double usedLiters, required double usableLiters, required double fraction, required FillLevel level})`;
`usedLiters` gia' moltiplicati per la taratura, `usableLiters` = nominali x 0,8, `fraction`
puo' superare 1. Getter `int get percent` — arrotondata e **tagliata a 0..100**.

`class CapacityEstimator`

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `const CapacityEstimator({this.usableFraction = 0.8, this.fullAt = 0.85, this.emptyAt = 0.20})` | |
| `minCalibration` / `maxCalibration` | `static const double` = `0.25` / `4` | |
| `litersPerUnit` | `static const Map<String, double>` | `portions` 0,4 · `packs` 0,8 · `l` 1,1 · `kg` 1,3 · `g` 0,0013 |
| `quickSizes` | `static const Map<String, double>` | litri **per unita'**: `small` 0,25 · `medium` 0,5 · `large` 1 · `xlarge` 2 |
| `estimateLiters` | `double estimateLiters({required double quantity, required String unit, String? categoryKey})` | quantita' x litri per unita'; `pieces` usa `ItemCategory.litersPerPiece` (ignota → `other`); unita' ignota → come `portions`; **mai sotto 0,01** |
| `fill` | `FillInfo fill({required double capacityLiters, required double calibration, required Iterable<double> itemLiters})` | somma x taratura su capienza utile; capienza 0 → frazione 0; `full` ≥ 0,85, `empty` < 0,20 |
| `rawFraction` | `double rawFraction({required double capacityLiters, required Iterable<double> itemLiters})` | la frazione **senza** taratura |
| `calibrate` | `double calibrate({required double estimatedFraction, required double declaredFraction})` | dichiarata / stimata, limitata a 0,25..4; stima ≤ 0 → 1 |

⚑ `kg` vale 1,3 litri e non 1: il congelato pesa poco meno dell'acqua ma sacchetti, vaschette
e aria occupano spazio. Per lo stesso motivo la capienza utile e' l'80% della nominale.

⚑ **Due correzioni separate**, perche' la stima sbaglia in due modi: il singolo alimento (la
lasagna in teglia non e' "una porzione") si corregge sull'alimento (`volumeManual`); il
freezer intero (ognuno riempie a modo suo) si corregge con la taratura.

☠ `calibrate` vuole la stima **grezza** (`rawFraction`), non quella gia' tarata: due tarature
di seguito si moltiplicherebbero e la barra impazzirebbe.

`abstract final class AlertLevel` — `full = 'full'`, `empty = 'empty'` (i valori di
`freezers.last_alert_level`).

`@immutable class AlertDecision` — `const AlertDecision({required String? send, required String? newLastLevel})`:
`send` = l'avviso da mandare (`AlertLevel.*` o null), `newLastLevel` = il valore da scrivere.

`class CapacityAlertPolicy`

| Membro | Firma |
|---|---|
| costruttore | `const CapacityAlertPolicy({this.estimator = const CapacityEstimator(), this.rearmFullBelow = 0.70, this.rearmEmptyAbove = 0.40})` |
| `decide` | `AlertDecision decide({required double fraction, required String? lastLevel})` |

Regole: sopra `fullAt` avvisa `full` solo se l'ultimo non era `full`; sotto `emptyAt` avvisa
`empty` solo se l'ultimo non era `empty`; in mezzo nessun avviso, e si **riarma** (ultimo → null)
solo scendendo sotto 0,70 dopo un pieno o salendo sopra 0,40 dopo un vuoto.

☠ **L'avviso ripetuto**: senza isteresi un freezer all'86% che riceve e perde un alimento al
giorno attraverserebbe la soglia ogni giorno, e l'utente silenzierebbe le notifiche.

### `categories.dart`

`@immutable class ItemCategory` — `const ItemCategory({required String key, required int defaultReminderDays, required double litersPerPiece, required String iconKey})`.

☠ `defaultReminderDays` **non e' una scadenza** ne' una garanzia di sicurezza alimentare: e'
un promemoria organizzativo, e la UI lo dice (`item_reminderDisclaimer`). Vendere un'app che
implica sicurezza alimentare senza esserne titolati e' un rischio reale.

`abstract final class ItemCategories` — le predefinite **vivono in codice**, nel database c'e'
solo la chiave:

| Costante | `key` | Promemoria (gg) | Litri/pezzo | `iconKey` |
|---|---|---|---|---|
| `meatRed` | `meat_red` | 180 | 0,5 | `meat` |
| `meatWhite` | `meat_white` | 180 | 0,5 | `poultry` |
| `fish` | `fish` | 120 | 0,4 | `fish` |
| `vegetables` | `vegetables` | 240 | 0,3 | `vegetables` |
| `fruit` | `fruit` | 240 | 0,2 | `fruit` |
| `bread` | `bread` | 90 | 0,5 | `bread` |
| `prepared` | `prepared` | 90 | 0,4 | `prepared` |
| `iceCream` | `ice_cream` | 180 | 1,0 | `ice_cream` |
| `other` | `other` | 180 | 0,4 | `other` |

Piu' `static const List<ItemCategory> all` (in quest'ordine) e
`static ItemCategory? byKey(String? key)`.

Funzioni: `String customCategoryKey(int id)` → `'custom:<id>'`;
`int? customCategoryId(String? key)` → l'id, o null se la chiave non e' personalizzata.

☠ Le chiavi **non si rinominano mai**: un alimento salvato con la vecchia chiave perderebbe
categoria e promemoria.

### `category_guess.dart`

`String? guessCategory(String name)` — normalizza, divide in **parole intere**, restituisce la
categoria della prima parola nota nel dizionario `_parole` (it + en), o null.
`Iterable<String> get guessedCategoryKeys` — solo per i test (ogni chiave deve esistere).

⚑ Un dizionario e non un modello: prevedibile, e un errore costa un tocco. Parola intera,
cosi' "pane" non scatta in "panettone". Null e' meglio di una categoria sbagliata, perche' la
categoria porta con se' il promemoria.

☠ Volutamente assenti "pasta" ("pasta al forno" e' un preparato) e "ice" ("ice cubes" non e'
un gelato).

### `home_view.dart`

`@immutable class ItemRow` — `const ItemRow({required Item item, required AgingInfo aging, required String freezerName})`.

`@immutable class FreezerSummary` — `const FreezerSummary({required Freezer freezer, required int count, required FillInfo fill})`.

`@immutable class HomeView`

| Membro | Firma | Significato |
|---|---|---|
| costruttore | `const HomeView({required Freezer? selectedFreezer, required List<ItemRow> useSoonAll, required List<ItemRow> rest, required List<FreezerSummary> freezers})` | |
| `selectedFreezer` | `final Freezer?` | null = "Tutti" |
| `useSoonAll` | `final List<ItemRow>` | tutti i `watch`/`old`, il piu' vecchio per primo |
| `useSoon` | `List<ItemRow> get useSoon` | i primi `useSoonPreview`: le schede della home |
| `useSoonTotal` | `int get useSoonTotal` | il numero del bollino |
| `rest` | `final List<ItemRow>` | solo i `fresh`, dal piu' vecchio |
| `freezers` | `final List<FreezerSummary>` | **tutti** i freezer, anche con un filtro attivo |
| `totalCount` | `int get totalCount` | |
| `selectedFill` | `FillInfo? get selectedFill` | null con "Tutti" |
| `isEmpty` | `bool get isEmpty` | |

Costante `const int useSoonPreview = 4` — la usano `HomeView.useSoon` e `HomePage` ("Vedi
tutti" compare oltre questo numero).

⚑ Quattro e non cinque: le schede stanno in una griglia di due colonne, e con cinque l'ultima
resterebbe sola in una riga (deciso guardando la home "A · Ghiaccio", 2026-10-07; il piano
diceva 5).

Funzione di modulo:
`HomeView buildHomeView({required List<Freezer> freezers, required List<Item> storedItems, required int? selectedFreezerId, required CivilDate today, AgingCalculator aging = const AgingCalculator(), CapacityEstimator capacity = const CapacityEstimator()})`.
Funzione pura; riordina comunque con `compareOldestFirst` ("il repository li da' gia' in
ordine, ma la funzione non si fida: e' la promessa dell'app").

⚑ "Da usare prima" e "Tutto il resto" si dividono gli alimenti **senza ripetizioni**:
mostrarne uno in due sezioni farebbe sembrare il freezer piu' pieno.

### `search.dart`

`List<Item> searchItems(Iterable<Item> items, String query)` — ogni parola della query
normalizzata deve comparire (in qualunque ordine) in `nameNorm` **o** nella nota normalizzata;
query vuota → lista vuota; l'ordine ricevuto resta.

⚑ **In memoria, non in SQL** (il piano diceva LIKE con debounce di 200 ms): gli alimenti di
una casa sono qualche centinaio e sono gia' in `storedItemsProvider`. Risponde a ogni lettera
senza query, e cerca anche nelle **note**, che non hanno una colonna normalizzata.

### `stats.dart`

`enum StatsPeriod { month, year, all }` — 30 giorni, 365 giorni, sempre.

`@immutable class MonthBar` — `const MonthBar({required int year, required int month, required int consumed, required int discarded})` + `int get total`.

`@immutable class WasteStats`

| Membro | Firma |
|---|---|
| costruttore | `const WasteStats({required int consumed, required int discarded, required double? averageDays, required String? mostWastedCategory, required int mostWastedCount, required List<MonthBar> months})` |
| `total` | `int get total` |
| `wasteRate` | `double get wasteRate` — 0..1, 0 senza uscite |
| `isEmpty` | `bool get isEmpty` |

Costante `const int statsMonths = 6`.

`WasteStats computeStats(Iterable<Item> removed, {required StatsPeriod period, required DateTime now})`
— conta le **righe** uscite nel periodo, la permanenza media in giorni di calendario, la
categoria piu' buttata (null → `other`), e i sei mesi del grafico **sempre** (qualunque
periodo: e' l'andamento).

⚑ Si contano le righe e non le quantita': "1 confezione e 500 g" non si somma in modo onesto.

### `text_norm.dart`

`String normalizeName(String input)` — minuscolo, senza accenti (tabella `_senzaAccenti`:
vocali accentate, ç, ñ, ß→ss, œ, æ, apostrofo tipografico → `'`), spazi multipli ridotti a
uno, `trim`.

☠ **SQLite senza ICU non e' insensibile agli accenti**: `LIKE '%pure%'` non trova "Purè".
Invece di estendere SQLite si salva `name_norm` accanto al nome. La stessa funzione si applica
al testo cercato: nome salvato e ricerca passano dalla stessa porta.

### `units.dart`

`abstract final class Units` — `portions = 'portions'`, `pieces = 'pieces'`, `grams = 'g'`,
`kilograms = 'kg'`, `packs = 'packs'`, `liters = 'l'`;
`static const List<String> all` = `[portions, pieces, packs, grams, kilograms, liters]` (ordine
dei chip); `static const String fallback = portions`; `static bool isKnown(String? key)`.

### `voice_parser.dart`

`@immutable class ParsedItem` — `const ParsedItem({required String name, double? quantity, String? unit, String? categoryKey, required double confidence})`.
`confidence`: 1 = quantita', unita' e nome; 0,8 = quantita' e nome (unita' → `pieces`);
0,5 = solo nome; 0 = niente di strutturato (la frase intera e' il nome).

`class VoiceItemParser` — `const VoiceItemParser({required String locale})`,
`ParsedItem parse(String utterance)`.

Riconosce numeri in cifre (anche `1,5`) e in lettere (it/en, `mezzo`, `half`, `dozen`),
unita' da dizionario (`etto`/`etti` = 100 g), "e mezzo" / "and a half" dopo l'unita',
"half a", e i legami `di/d/del/della/dei/delle/of`. Il nome si prende dal testo **originale**
(maiuscole conservate), con l'iniziale maiuscola; la categoria con `guessCategory`.

⚑ **Nessun server**: un dizionario basta per le frasi davanti a un freezer; un servizio
remoto aggiungerebbe latenza, costi, privacy da dichiarare e una dipendenza di rete.
⚑ **Il ripiego non e' mai un errore**: senza forma riconosciuta, tutto il testo diventa il
nome. ⚑ Italiano e inglese **insieme**, a prescindere da `locale` (che resta per una terza
lingua): chi ha il telefono in inglese puo' dire "mezzo chilo di macinato".

---

## 5. `lib/data/`

### `class AppDatabase extends _$AppDatabase`

| Membro | Firma |
|---|---|
| costruttore | `AppDatabase(super.e)` |
| su file | `factory AppDatabase.open()` — `full_freezer.sqlite` nei documenti, `NativeDatabase.createInBackground` (isolate separato) |
| in memoria, per i test | `factory AppDatabase.memory()` |
| versione | `int get schemaVersion => 1` |
| migrazioni | `MigrationStrategy get migration` — `onCreate: createAll`, `beforeOpen: PRAGMA foreign_keys = ON`, `onUpgrade` lancia |

`database.dart` riesporta `ItemStatus` e `MovementKind` da `tables.dart`.

☠ `sqlite3.tempDirectory` = cartella temporanea dell'app, prima di aprire: su Android quella di
sistema non e' scrivibile e VACUUM o ORDER BY grandi falliscono con "unable to open database
file", solo su dispositivo.

### `@immutable class NewItem`

`const NewItem({required String name, required int freezerId, required double quantity, required String unit, required CivilDate frozenAt, required double volumeLiters, int? compartmentId, String? category, int? reminderAfterDays, bool volumeManual = false, String? photoPath, String? note})`
— un alimento da inserire; lo costruiscono `ItemDraft.toNewItem`, la demo e i test.

### `class FreezerRepository`

`FreezerRepository(AppDatabase db, {DateTime Function()? clock})` — `clock` per i test (default
`DateTime.now`). **Tutte** le letture e scritture passano da qui.

⚑ Perche' un repository e non query nelle pagine: tre regole non si scrivono come vincoli SQL
e vanno rispettate a ogni scrittura: (1) `items.freezerId` = freezer dello scomparto, se c'e';
(2) `nameNorm` = `normalizeName(name)`; (3) ogni entrata, uscita, spostamento o annullamento
scrive una riga in `item_movements`. Dimenticarne una non darebbe errori: darebbe una ricerca
che non trova, un riempimento nel freezer sbagliato, una statistica falsa.

| Metodo | Firma | Effetto |
|---|---|---|
| `watchFreezers` | `Stream<List<Freezer>> watchFreezers()` | per `sort_order`, poi id |
| `allFreezers` | `Future<List<Freezer>> allFreezers()` | idem, una volta |
| `freezerById` | `Future<Freezer?> freezerById(int id)` | |
| `addFreezer` | `Future<int> addFreezer({required String name, required String modelKey, required double capacityLiters})` | in fondo all'elenco; nome con `trim`. **Non** controlla il limite Pro (lo fa la UI) |
| `updateFreezer` | `Future<void> updateFreezer(int id, {String? name, String? modelKey, double? capacityLiters})` | null = invariato; cambia la capacita', non gli alimenti |
| `setCalibration` | `Future<void> setCalibration(int freezerId, double calibration)` | |
| `setLastAlertLevel` | `Future<void> setLastAlertLevel(int freezerId, String? level)` | lo stato dell'isteresi |
| `deleteFreezer` | `Future<void> deleteFreezer(int id)` | **con tutto il contenuto** (cascade) |
| `reorderFreezers` | `Future<void> reorderFreezers(List<int> idsInOrder)` | in transazione; lo chiama il trascinamento dei freezer in `SettingsPage` |
| `watchCompartments` | `Stream<List<Compartment>> watchCompartments(int freezerId)` | |
| `watchAllCompartments` | `Stream<List<Compartment>> watchAllCompartments()` | per freezer, ordine, id |
| `addCompartment` | `Future<int> addCompartment(int freezerId, String name)` | in fondo |
| `renameCompartment` | `Future<void> renameCompartment(int id, String name)` | |
| `deleteCompartment` | `Future<void> deleteCompartment(int id)` | gli alimenti restano nel freezer (SET NULL) |
| `reorderCompartments` | `Future<void> reorderCompartments(List<int> idsInOrder)` | in transazione |
| `watchCustomCategories` | `Stream<List<CustomCategory>> watchCustomCategories()` | alfabetico |
| `addCustomCategory` | `Future<int> addCustomCategory({required String name, required String iconKey, int? defaultReminderDays})` | `colorValue` = 0 sempre |
| `updateCustomCategory` | `Future<void> updateCustomCategory(int id, {required String name, required String iconKey, int? defaultReminderDays})` | **non** tocca gli alimenti gia' salvati |
| `deleteCustomCategory` | `Future<void> deleteCustomCategory(int id)` | in transazione: prima `category = null` sugli alimenti con `custom:<id>`, poi cancella |
| `watchStoredItems` | `Stream<List<Item>> watchStoredItems({int? freezerId})` | `stored`, per `frozen_at` poi id |
| `storedItems` | `Future<List<Item>> storedItems({int? freezerId})` | idem, una volta |
| `watchRemovedItems` | `Stream<List<Item>> watchRemovedItems()` | non `stored`, `removed_at` **decrescente** |
| `itemById` | `Future<Item?> itemById(int id)` | |
| `addItem` | `Future<int> addItem(NewItem item)` | transazione: freezer coerente, `nameNorm`, movimento `stored` |
| `updateItem` | `Future<void> updateItem(Item item)` | transazione: freezer coerente, `trim`, `nameNorm`. **Non** scrive movimenti: lo spostamento passa prima da `moveItem` |
| `removeItem` | `Future<void> removeItem(int id, {required bool consumed})` | `status`, `removedAt`, movimento `consumed`/`discarded` |
| `undoRemoval` | `Future<void> undoRemoval(int id)` | torna `stored`, `removedAt` null, movimento `restored`; la data di congelamento resta quella vera |
| `moveItem` | `Future<void> moveItem(int id, {required int freezerId, int? compartmentId})` | movimento `moved` con da/a; lo chiama `ItemEditPage._save` se freezer o scomparto cambiano, **prima** di `updateItem` |
| `duplicateAsToday` | `Future<int> duplicateAsToday(int id, {CivilDate? today})` | copia tutto **tranne data e foto**; lancia StateError se l'id non esiste |
| `suggestNames` | `Future<List<String>> suggestNames(String prefix, {int limit = 8})` | nomi usati che iniziano col prefisso normalizzato, **anche fra gli usciti**, i piu' frequenti poi i piu' recenti; `%` e `_` scappati |
| `watchAnyChange` | `Stream<void> watchAnyChange()` | un segnale a ogni modifica di `freezers`, `compartments`, `items`, `custom_categories` |

Privati che contano: `_freezerFor(int freezerId, int? compartmentId)` — il freezer dello
scomparto; **lancia ArgumentError** se lo scomparto non esiste ("meglio un errore che un
alimento nel posto sbagliato"). `_movement(...)` scrive la riga di storico. `_escapeLike`.

⚑ L'autocompletamento cerca **anche gli usciti**: lo spezzatino finito la settimana scorsa e'
proprio quello che si sta per congelare di nuovo.

---

## 6. `lib/app/`

### `providers.dart` — i provider radice

⚑ Niente singleton globali: un provider si sostituisce nei test con un `override` e si
inizializza pigramente. Stesso schema di TrashCan.

Da sovrascrivere in `main()`, altrimenti lanciano UnimplementedError: `appConfigProvider`,
`appPathsProvider`, `settingsProvider`.

| Provider | Tipo | Cosa espone | Dipende da |
|---|---|---|---|
| `appConfigProvider` | `Provider<MicroAppConfig>` | la configurazione | override in `main` |
| `appPathsProvider` | `Provider<AppPaths>` | cartelle dell'app | override |
| `settingsProvider` | `Provider<SettingsStore>` | preferenze (namespace `full_freezer`) | override |
| `databaseProvider` | `Provider<AppDatabase>` | apre alla prima lettura, chiude col ProviderScope | |
| `repositoryProvider` | `Provider<FreezerRepository>` | | `databaseProvider` |
| `todayProvider` | `Provider<CivilDate>` | "oggi"; **invalidato al resume** | |
| `freezersProvider` | `StreamProvider<List<Freezer>>` | | `repositoryProvider` |
| `storedItemsProvider` | `StreamProvider<List<Item>>` | gli alimenti dentro, dal piu' vecchio | `repositoryProvider` |
| `removedItemsProvider` | `StreamProvider<List<Item>>` | gli usciti, dal piu' recente | `repositoryProvider` |
| `customCategoriesProvider` | `StreamProvider<List<CustomCategory>>` | anche senza Pro (chi lo perde continua a vederle) | `repositoryProvider` |
| `compartmentsByFreezerProvider` | `StreamProvider<Map<int, List<Compartment>>>` | scomparti raggruppati per freezer | `repositoryProvider` |
| `onboardingDoneProvider` | `Provider<bool>` | `SettingKeys.onboardingDone` | `settingsProvider` |
| `selectedFreezerProvider` | `NotifierProvider<SelectedFreezer, int?>` | freezer guardato in home, null = Tutti | `settingsProvider` |
| `homeViewProvider` | `Provider<HomeView?>` | la home pronta; null finche' mancano i dati | freezers, stored, selected, today |
| `themeModeProvider` | `NotifierProvider<ThemeModeNotifier, ThemeMode>` | | `settingsProvider` |
| `notificationServiceProvider` | `FutureProvider<NotificationService>` | creato al primo uso, icona `@drawable/ic_notification`, canale `freezerChannel` | |
| `schedulerProvider` | `Provider<FreezerScheduler>` | | repository, settings, `featureGateProvider`, servizio notifiche (`.value`, null finche' non c'e') |
| `notificationSyncProvider` | `Provider<void>` | tiene notifiche **e widget** allineati ai dati | scheduler, repository |
| `notificationsEnabledProvider` | `NotifierProvider<NotificationsEnabled, bool>` | interruttore avvisi, **default spento** | settings, scheduler |
| `digestFrequencyProvider` | `NotifierProvider<DigestFrequencyNotifier, String>` | `weekly` (default) \| `biweekly` \| `monthly` | settings, scheduler |

Altri provider fuori da questo file: `installIdProvider`, `purchaseGatewayProvider`,
`entitlementProvider`, `isProProvider`, `featureGateProvider` (in `entitlement.dart`);
`compartmentsProvider` (in `freezer_page.dart`); `backupServiceProvider` (in
`data_actions.dart`).

Comportamenti che contano:

- `homeViewProvider`: un freezer selezionato e poi cancellato torna a "Tutti"; **con un freezer
  solo**, "Tutti" diventa quel freezer, cosi' la testata ha la sua barra.
- `notificationSyncProvider`: all'avvio `rescheduleAll` (se il servizio c'e'), pubblica il
  widget e programma le sveglie del widget; poi a ogni `watchAnyChange`, con **500 ms di
  debounce** (un'azione fa piu' scritture): `evaluateCapacity` → `rescheduleAll` →
  `FreezerWidget.publish`. Lo tiene vivo `FullFreezerApp.build` con un `watch`.
- `_systemL()` (privata): le traduzioni per i testi delle notifiche, scritti fuori da ogni
  widget, con la lingua risolta da `resolveAppLocale`.

⚑ `onboardingDoneProvider` e' una **preferenza** e non "esiste almeno un freezer": il redirect
del router deve rispondere subito, mentre lo stream del database arriva dopo il primo frame.
Non e' reattivo: chi lo cambia lo invalida (`FreezerEditorPage`).

Le classi notifier:

| Classe | `build()` | Azione |
|---|---|---|
| `SelectedFreezer extends Notifier<int?>` | `int? build()` — legge `FreezerSettingKeys.selectedFreezer` (-1/assente → null) | `Future<void> select(int? freezerId)` — null cancella la preferenza |
| `ThemeModeNotifier extends Notifier<ThemeMode>` | `ThemeMode build()` — `'light'`/`'dark'`/altro = system | `Future<void> set(ThemeMode mode)` — salva `mode.name` |
| `NotificationsEnabled extends Notifier<bool>` | `bool build()` — `SettingKeys.notificationsEnabled`, **`orElse: false`** | `Future<void> set(bool value)` — salva e `rescheduleAll` |
| `DigestFrequencyNotifier extends Notifier<String>` | `String build()` — `NotificationSettingKeys.digestFrequency` ?? `'weekly'` | `Future<void> set(String value)` — salva e `rescheduleAll` |

☠ **`NotificationsEnabled` parte spento**, al contrario di TrashCan: qui gli avvisi sono Pro e
il permesso si chiede solo quando li si accende. Col default acceso l'interruttore si mostrava
acceso senza permesso mai chiesto, e **il primo tocco lo spegneva** (emulatore, 2026-10-07).

`abstract final class FreezerSettingKeys` — vedi §11.

### `entitlement.dart` — il Pro

| Simbolo | Firma / tipo | Significato |
|---|---|---|
| `appVersion` | `const String appVersion = '1.0.0'` | **un posto solo**: backup, server licenze, impostazioni. Va tenuta uguale al versionName di `pubspec.yaml` |
| `installIdProvider` | `FutureProvider<InstallId>` | id d'installazione |
| `purchaseGatewayProvider` | `Provider<PurchaseGateway>` | store vero (`BillingMode.store`) o finto **senza Pro** (`BillingMode.fake`, con il prodotto) |
| `entitlementProvider` | `NotifierProvider<EntitlementNotifier, EntitlementView>` | `.notifier.service` per le azioni |
| `isProProvider` | `Provider<bool>` | |
| `featureGateProvider` | `Provider<FeatureGate>` | `FeatureGate(limits: freezerFeatureLimits, isPro: ...)` |

`@immutable class EntitlementView` — `const EntitlementView({required Entitlement entitlement, required bool busy, required bool storeAvailable, MicroProduct? product, MicroError? error})`,
getter `bool get isPro`, `bool get isPending`; `==` confronta entitlement, busy, store, id e
prezzo del prodotto, codice d'errore.

`class EntitlementNotifier extends Notifier<EntitlementView>` — `EntitlementView build()`
crea il servizio d'entitlement di micro_core (file `entitlement.json` in `support`, client
del License Server solo se `serverEnabled` e l'id d'installazione c'e'), si iscrive ai suoi
cambiamenti, **avvia da solo il bootstrap**; getter `EntitlementService get service`.

⚑ Un valore immutabile dietro un Notifier invece del ChangeNotifier del servizio: Riverpod 3
ha messo ChangeNotifierProvider fra le API legacy, e cosi' e' esplicito cosa ridisegna la UI.

☠ **Debito**: il file e' identico alla parte corrispondente di
`apps/trashcan/lib/app/providers.dart` (§14).

### `feature_limits.dart`

`const FeatureLimits freezerFeatureLimits` — la mappa di §10. Nessuna pagina scrive
`if (isPro)`: si passa da `featureGateProvider`.

### `paywall_config.dart`

| Funzione | Firma |
|---|---|
| `buildFreezerPaywall` | `PaywallConfig buildFreezerPaywall(L l)` — testi, `productUnavailableLabel` e `retryLabel` (mai la rotellina eterna), 7 benefici |
| `showFreezerPaywall` | `Future<bool> showFreezerPaywall(BuildContext context, WidgetRef ref, {FeatureKey? highlight})` — `true` se si esce col Pro |

⚑ L'ordine dei benefici e' quello che vende: secondo freezer, avvisi, statistiche, storico,
backup, CSV, categorie.

### `app_config.dart`

`MicroAppConfig buildFreezerConfig()` — `MicroAppConfig.fromEnvironment(appId: 'full_freezer', appName: 'Full Freezer', proSku: 'fullfreezer_pro_lifetime', seedColor: Color(0xFF0461E5), fontFamily: 'PlusJakartaSans', defaultBrightness: Brightness.light)`.
Il blu e' quello dell'icona (misurato da `tool/genera_icone.py`), al posto dell'azzurro
`#3A7CA5` del piano originale.

### `freezer_palette.dart` — interfaccia "A · Ghiaccio"

`@immutable class FreezerPalette extends ThemeExtension<FreezerPalette>` — 19 colori:

| Campo | Chiaro | Scuro | Uso |
|---|---|---|---|
| `ground` | `#F2F6FC` | `#070F1F` | fondo pagine |
| `card` | `#FFFFFF` | `#0F1D36` | schede e righe |
| `ink` / `inkMuted` | `#0B1A33` / `#5B6B86` | `#EAF1FF` / `#8FA3C7` | testo |
| `night` / `nightRaised` / `nightBorder` | `#0B1A33` / `#13284A` / `#2A3D5E` | `#13284A` / `#1C3560` / `#2E4A7A` | testata blu notte |
| `onNight` / `onNightMuted` | `#FFFFFF` / `#B9CBE8` | uguali | testo sulla testata |
| `ice` | `#8FB8FF` | uguale | etichette in testata |
| `gaugeFill` | `#4F9BFF` | uguale | asticella |
| `accent` / `onAccent` | `#0461E5` / `#FFFFFF` | `#2F7BFF` / `#FFFFFF` | pulsante principale |
| `badge` / `onBadge` | `#FFB547` / `#3A2400` | uguali | bollino "N da usare" |
| `old` / `watch` | `#C2410C` / `#A15C00` | `#FF8A3D` / `#FFC24B` | giorni oltre / vicino al promemoria (≥ 4,5:1 sul bianco) |
| `iconTile` / `onIconTile` | `#E3EEFF` / `#0461E5` | `#13284A` / `#8FB8FF` | riquadro icona categoria |

Membri: `static const FreezerPalette light`, `static const FreezerPalette dark`,
`static FreezerPalette of(BuildContext context)` (ripiega su light/dark se l'estensione manca),
`FreezerPalette copyWith()` (restituisce se stessa), `FreezerPalette lerp(FreezerPalette? other, double t)`
(scatto a meta', niente interpolazione).

`ThemeData withFreezerLook(ThemeData base, FreezerPalette palette)` — fondo scaffold e app bar
= `ground`, niente tinta di superficie, aggiunge l'estensione.

⚑ Una ThemeExtension e non costanti: testata, bollino e giorni cambiano col tema scuro, e le
pagine li leggono senza sapere quale tema e' attivo. I colori Material (pulsanti, campi) restano
quelli che MicroTheme ricava dal seme, con `DynamicSchemeVariant.fidelity` (§7).

### `category_glyphs.dart` — le icone disegnate

| Classe | Firma | |
|---|---|---|
| `CategoryGlyph extends StatelessWidget` | `const CategoryGlyph({required String? iconKey, double size = 22, Color? color, Key? key})` | colore: `color` ?? IconTheme ?? `onSurface`; chiave null/ignota → `other` |
| `CategoryGlyphPainter extends CustomPainter` | `CategoryGlyphPainter(String key, Color color)`; `void paint(Canvas canvas, Size size)`; `bool shouldRepaint(CategoryGlyphPainter old)` | griglia 24x24, tratto 2 arrotondato; chiavi `meat`, `poultry`, `fish`, `vegetables`, `fruit`, `bread`, `prepared`, `ice_cream`, default = scatola |

☠ Erano icone Material, e la carne era uno spiedino (Material non ha una bistecca): il
proprietario l'ha notato al primo giro. Disegnate qui sono coerenti fra loro e indipendenti da
una libreria. `CategoryGlyphPainter` e' pubblico perche' `FreezerWidget.renderIcon` lo usa per
i PNG del widget: **stesso disegno nell'app e sul widget, per costruzione**.

### `formats.dart`

| Funzione | Firma | |
|---|---|---|
| `formatLiters` | `String formatLiters(double liters, String locale)` | "0,25 L" (2 decimali sotto 1), "1,2 L" (1 fino a 10), "70 L" (0 oltre) |
| `formatQuantity` | `String formatQuantity(double q, String locale)` | massimo 2 decimali, niente zeri inutili |
| `parseUserNumber` | `double? parseUserNumber(String input)` | accetta **virgola e punto**, toglie spazi; vuoto → null |

⚑ Virgola e punto entrambi: alcune tastiere numeriche mostrano solo il punto anche in italiano.

### `locale_resolution.dart`

`const List<Locale> kSupportedLocales` = `[en, it]` (**inglese per primo**: Flutter ripiega
sul primo). `Locale resolveAppLocale(List<Locale>? deviceLocales, Iterable<Locale> supported)`
— italiano se **qualunque** lingua del dispositivo ha `languageCode == 'it'`, altrimenti
inglese (ADR-011).

---

## 7. Le rotte e i deep link

Dichiarate in `lib/app/routes.dart` (`abstract final class Routes`), registrate in
`buildRouter` (`lib/app/app.dart`): `GoRouter buildRouter(WidgetRef ref)`, `initialLocation: Routes.home`.

| Costante | Percorso | Pagina | Parametri / extra | Gate |
|---|---|---|---|---|
| `Routes.home` | `/` | `HomePage` | | |
| `Routes.welcome` | `/welcome` | `FreezerEditorPage(firstRun: true)` | | primo avvio |
| `Routes.useSoon` | `/use-soon` | `UseSoonPage` | | **bersaglio di riepilogo e widget** |
| `Routes.search` | `/search` | `SearchPage` | | |
| `Routes.settings` | `/settings` | `SettingsPage` | | |
| `Routes.stats` | `/stats` | `ProGate(statistics)` → `StatsPage` | | Pro: `openProFeature` all'ingresso **e** `ProGate` sulla pagina |
| `Routes.history` | `/history` | `ProGate(fullHistory)` → `HistoryPage` | | Pro, idem |
| `Routes.categories` | `/categories` | `ProGate(customCategories)` → `CustomCategoriesPage` | | Pro, idem |
| `Routes.freezerNew` | `/freezers/new` | `ProGate(unlimitedEntities, allowed: withinLimit)` → `FreezerEditorPage()` | | limite di 1 freezer: `openNewFreezer` all'ingresso **e** `ProGate` |
| `Routes.freezer` | `/freezers/:freezerId` | `FreezerPage` | `freezerId` (non numerico → -1, pagina vuota) | **bersaglio degli avvisi di capienza** |
| `Routes.freezerEdit` | `/freezers/:freezerId/edit` | `FreezerEditorPage(freezerId:)` | `freezerId` | |
| `Routes.itemNew` | `/items/new` | `ItemEditPage(draft:)` | `extra`: un `ItemDraft` (dall'inserimento rapido) o niente | |
| `Routes.itemEdit` | `/items/:itemId` | `ItemEditPage(itemId:)` | `itemId` | |

Helper: `static String freezerOf(int id)`, `static String freezerEditOf(int id)`,
`static String itemEditOf(int id)`. Costante `static const String scheme = 'fullfreezer'`.

⚑ `freezerNew` e' registrata **prima** di `:freezerId`: go_router prova le rotte in ordine e
"new" e' un valore valido per il parametro. La bozza va in `extra` e non nel percorso: e' uno
stato in memoria, non un link.

⚑ Routes contiene **solo i percorsi che esistono**: una costante che punta a una pagina
inesistente e' un deep link rotto in attesa di essere usato.

**Redirect**: chi non ha l'onboarding fatto va su `/welcome` da qualunque punto entri (anche da
deep link); chi l'ha fatto e va su `/welcome` torna alla home.

**Il Pro sulla pagina**: `/stats`, `/history`, `/categories` e `/freezers/new` sono avvolte in
`ProGate` (§9, `features/common/pro_gate.dart`). Le porte normali (`openProFeature`,
`openNewFreezer`) mostrano il paywall **prima** di aprire; `ProGate` copre le porte che non lo
fanno (un deep link, una notifica, una pagina scritta domani che fa `push` diretto): senza il
Pro la pagina mostra un lucchetto (`pro_locked`) col pulsante del paywall, e appena il Pro
arriva mostra se stessa. Per `/freezers/new` il controllo e' `allowed: (gate) =>
gate.withinLimit(FeatureKey.unlimitedEntities, numero di freezer)`, con il numero letto da
`freezersProvider` nel builder della rotta.

☠ **Non un `redirect` di go_router**: un `push` che redireziona a "/" mette "/" due volte nella
pila, e go_router mostra la sua pagina d'errore (provato in un test il 2026-10-07).

### Chi apre l'app su una pagina

| Sorgente | Payload / URI | Arriva a | Codice |
|---|---|---|---|
| Notifica di riepilogo | payload `/use-soon` | `UseSoonPage` | `FreezerScheduler.rescheduleAll` |
| Avviso "quasi pieno/vuoto" | payload `/freezers/<id>` | `FreezerPage` | idem |
| Widget Android | `fullfreezer:///use-soon` (HomeWidgetLaunchIntent) | `UseSoonPage` | `FullFreezerWidgetProvider.kt` |
| Widget iOS | `fullfreezer:///use-soon?homeWidget` (`widgetURL`) | `UseSoonPage` | `FullFreezerWidget.swift` |

`FullFreezerApp` (`class FullFreezerApp extends ConsumerStatefulWidget`, `const FullFreezerApp({Key? key})`):

- **notifiche**: appena `notificationServiceProvider` ha un valore si iscrive a `taps`, e
  consuma il payload di lancio (app aperta da chiusa: quel tocco non passa dallo stream);
- **widget** (solo se `FreezerWidget.available`): `initiallyLaunchedFromHomeWidget` **dopo il
  primo frame** (prima il router non ha la posizione iniziale e un `go` verrebbe sovrascritto)
  e lo stream `widgetClicked`; `_openWidgetUri` accetta **solo** schema `fullfreezer` e
  percorso `/use-soon` (un link costruito altrove non apre pagine a caso);
- `_openPayload(String)` fa `go(home)` e poi `push(payload)`: col solo `go` il tasto indietro
  uscirebbe dall'app (trappola di TrashCan);
- al **resume**: `invalidate(todayProvider)` e `rescheduleAll` (i testi dei riepiloghi
  dipendono dai giorni);
- `build`: `MaterialApp.router` con MicroTheme chiaro/scuro (`fidelity`: il blu resta quello
  acceso dell'icona invece del blu ardesia che Material ricaverebbe) + `withFreezerLook`,
  `themeModeProvider`, `kSupportedLocales`, `resolveAppLocale`; tiene vivo
  `notificationSyncProvider`.

☠ **Il deep link di Flutter e' spento** su entrambe le piattaforme
(`flutter_deeplinking_enabled=false` nel manifest, `FlutterDeepLinkingEnabled=false` in
`Info.plist`): acceso, Flutter passava da solo l'URI del widget a go_router come `go`, che
sostituisce la pila. Visto sull'emulatore il 2026-10-07: "Da usare prima" senza freccia
indietro, e da app chiusa la home invece della pagina. Gli URI li gestisce solo `_openWidgetUri`.

☠ **`MainActivity.onNewIntent` fa `setIntent(intent)`**: tocco sul widget con l'app chiusa ma
nei recenti → Android ricrea l'attivita' con l'intent **vecchio** del launcher e consegna
quello del widget con `onNewIntent`, prima che Dart abbia aperto lo stream del plugin.
`initiallyLaunchedFromHomeWidget` leggeva l'intent vecchio e l'app si apriva sulla home.

---

## 8. `lib/services/`

### `notification_plan.dart` — il piano, senza toccare il sistema

| Simbolo | Firma | Significato |
|---|---|---|
| `DigestFrequency` | `enum DigestFrequency { weekly, biweekly, monthly }` | |
| `digestHour` / `digestWeekday` | `const int` = `18` / `DateTime.sunday` | riepilogo la domenica alle 18 |
| `emptyAlertHour` / `emptyAlertWeekday` | `const int` = `10` / `DateTime.saturday` | "quasi vuoto" il sabato alle 10 |
| `digestDates` | `List<CivilDate> digestDates(CivilDate today, DigestFrequency frequency)` | dalla prossima domenica (**oggi compreso** se e' domenica): 8 settimanali, 4 ogni 14 giorni, 3 ogni 28 (~2 mesi) |
| `DigestContent` | `const DigestContent({required int oldCount, required String oldest, required int oldestDays})` | quanti `old` quel giorno, il piu' vecchio e i suoi giorni |
| `digestFor` | `DigestContent? digestFor(Iterable<Item> stored, CivilDate on, {AgingCalculator aging = const AgingCalculator()})` | null se quel giorno nessuno e' `old` → niente notifica |
| `alertTime` | `DateTime alertTime({required bool full, required DateTime now})` | pieno: `now + 10 s`; vuoto: il prossimo sabato alle 10 strettamente dopo `now` |
| `PendingAlert` | `const PendingAlert({required int freezerId, required bool full, required DateTime when})` | avviso in coda nelle preferenze |
| `PendingAlert.encode` | `String encode()` | `"<freezerId>\|full\|<ms>"` o `\|empty\|` |
| `PendingAlert.decode` | `static PendingAlert? decode(String raw)` | null se rotto |
| `PendingAlert.notificationId` | `int get notificationId` | `NotificationIds.forOccurrence(freezerId, giorno, full ? 1 : 2)` — stabile |
| `digestId` | `int digestId(CivilDate on)` | `NotificationIds.forOccurrence(0, on, 9)` — stabile |

☠ **Il testo del riepilogo si calcola per il giorno della consegna, non per oggi**: il plugin
non calcola niente alla consegna, il testo e' fissato quando si pianifica. Il riepilogo fra tre
settimane deve contare chi **fra tre settimane** sara' vecchio, con i giorni di allora (con il
conteggio di oggi direbbe "137 giorni" invece di 158). Resta impreciso solo per cio' che si
aggiunge o consuma nel frattempo, ed e' per questo che si ripianifica a ogni modifica e resume.

⚑ "Quasi pieno" **subito** (serve mentre si sta per congelare altro); "quasi vuoto" **il sabato
mattina** (arrivare mentre si toglie l'ultima cosa non serve; arrivare quando si pianifica la
spesa si').

⚑ **Perche' conservare gli avvisi in coda**: `replaceSchedule` di micro_core cancella tutto
cio' che non e' nel piano. Un "quasi vuoto" per sabato sparirebbe alla prima ripianificazione
dei riepiloghi; tenuto nelle preferenze, ogni ripianificazione lo rimette finche' la sua ora
non e' passata.

⚑ **Un riepilogo e non una notifica per alimento**: in un freezer pieno sarebbero tre a
settimana, e l'utente le silenzierebbe entro un mese.

### `freezer_scheduler.dart`

Costante `const MicroNotificationChannel freezerChannel` — id `freezer_alerts`, nome
"Freezer alerts". Un canale solo.

`abstract final class NotificationSettingKeys` — `digestFrequency = 'digest_frequency'`,
`pendingAlerts = 'pending_capacity_alerts'` (§11).

`class FreezerScheduler implements NotificationScheduler`

`FreezerScheduler({required FreezerRepository repo, required SettingsStore settings, required FeatureGate gate, required L l, NotificationService? notifications, DateTime Function()? clock})`

| Membro | Firma | Effetto |
|---|---|---|
| `isReady` | `bool get isReady` | c'e' un servizio a cui consegnare |
| `allowed` | `bool get allowed` | Pro (`FeatureKey.notifications`) **e** interruttore acceso |
| `frequency` | `DigestFrequency get frequency` | dalla preferenza, default settimanale |
| `cancelAll` | `Future<void> cancelAll()` | cancella le notifiche **e** la coda degli avvisi |
| `evaluateCapacity` | `Future<void> evaluateCapacity()` | per ogni freezer: `CapacityAlertPolicy.decide`, scrive `lastAlertLevel` **sempre**; se c'e' un avviso e `allowed`, sostituisce quello in coda per lo stesso freezer |
| `capacityAlertBody` | `@visibleForTesting String capacityAlertBody({required bool full, required int percent, required List<Item> items})` | vuoto: `notif_emptyBody`; pieno: `notif_fullBodyOldest(percent, nome del piu' vecchio per frozenAt)`, o `notif_fullBody` se il freezer non ha niente |
| `digestCapacityLines` | `@visibleForTesting List<String> digestCapacityLines(Iterable<Freezer> freezers, List<Item> stored)` | una riga per ogni freezer **con qualcosa dentro** e pieno (≥ `fullAt`: `notif_digestFull`) o quasi vuoto (< `emptyAt`: `notif_digestEmpty`) |
| `rescheduleAll` | `Future<void> rescheduleAll()` | senza servizio: niente; senza `allowed`: `cancelAll`; altrimenti riepiloghi (`digestDates` x `digestFor`) + avvisi in coda ancora futuri (1 minuto di tolleranza), `replaceSchedule`, scrive `SettingKeys.lastRescheduleAt` |

☠ **Il controllo del Pro sta qui**, dove il piano si consegna, e non solo nelle impostazioni:
una notifica gia' pianificata sopravvive alla fine del diritto (rimborso), e col solo controllo
nella UI continuerebbe ad arrivare per settimane.

⚑ `lastAlertLevel` si aggiorna **anche senza Pro e con le notifiche spente**: e' lo stato
dell'isteresi. Altrimenti chi accende gli avvisi con il freezer gia' pieno riceverebbe un
"quasi pieno" vecchio di settimane.

Testi (chiavi `notif_*`): riepilogo `notif_digestTitle` + `notif_digestOne(name, days)` o
`notif_digestMany(count, name, days)`, **seguito** dalle righe di `digestCapacityLines`
(`notif_digestFull(name, percent)`, `notif_digestEmpty(name, percent)`), uniti da uno spazio;
avvisi `notif_fullTitle(name)` / `notif_fullBodyOldest(percent, name)` (o `notif_fullBody(percent)`
se il freezer e' vuoto), `notif_emptyTitle(name)` / `notif_emptyBody(percent)`.

⚑ "Quasi pieno" **cita il piu' vecchio del freezer**: "consuma qualcosa" non dice cosa,
"comincia dallo spezzatino" si'.

⚑ Le righe di capienza del riepilogo usano il riempimento **di adesso**, non quello del giorno
del riepilogo: lo spazio cambia solo quando cambiano i dati, e ogni modifica ripianifica tutto.

⚑ Un freezer **senza niente dentro** non entra: "quasi vuoto" ogni settimana su un freezer
appena creato sarebbe un rimprovero (stessa ragione per cui `lastAlertLevel` parte da `empty`).

⚠️ Le righe si **aggiungono** a un riepilogo che c'e' gia': se quel giorno nessun alimento e'
`old`, `digestFor` restituisce null e non parte niente, nemmeno le righe di capienza (gli
avvisi "quasi pieno/vuoto" restano a parte).

### `freezer_widget.dart` — il widget di sistema (lato Dart)

`abstract final class FreezerWidget`

| Membro | Firma / valore | |
|---|---|---|
| `available` | `static bool get available` | Android e iOS, non web/desktop (sul desktop dei test il canale solleva) |
| `iosGroup` | `static const String iosGroup = 'group.com.smp.fullfreezer'` | |
| `iosName` | `static const String iosName = 'FullFreezerWidget'` | il `kind` dello Swift |
| `androidName` | `static const String androidName = 'com.smp.fullfreezer.FullFreezerWidgetProvider'` | **con il package** |
| chiavi | `keyTitle = 'title'`, `keyCount = 'count'`, `keyEmpty = 'empty'`, `keyRows = 'rows'`, `keyToday = 'days_today'`, `keyDaysTemplate = 'days_template'`, `iconKeyPrefix = 'icon_'` | §11 |
| `fieldSeparator` | `static const String fieldSeparator = '\u001F'` | US |
| `countPlaceholder` | `static const String countPlaceholder = '{n}'` | |
| `rowCount` | `static const int rowCount = 3` | |
| `iconSide` | `static const int iconSide = 72` | px del PNG |
| `tapUri` | `static final Uri tapUri` = `fullfreezer:///use-soon` | documentale: Kotlin e Swift scrivono l'URI a mano |
| `buildRows` | `@visibleForTesting static List<String> buildRows(List<Item> stored, List<CustomCategory> custom)` | i 3 piu' vecchi (data, poi id): `frozenAt US nome US iconKey US promemoria` |
| `publish` | `static Future<void> publish({required List<Item> stored, required List<CustomCategory> custom})` | scrive testi, righe, PNG delle icone, poi `updateWidget`. **Non lancia mai** |
| `daysTemplate` | `@visibleForTesting static String daysTemplate(L l)` | `item_daysShort(987654)` con `{n}` al posto del numero: "{n} gg" / "{n} d" |
| `renderIcon` | `@visibleForTesting static Future<Uint8List> renderIcon(String iconKey)` | `CategoryGlyphPainter` bianco su trasparente, 72x72 PNG |
| `scheduleDailyRefresh` | `static Future<void> scheduleDailyRefresh()` | **solo Android**: 365 sveglie alle 00:05 dei giorni seguenti |

Il contratto completo e il perche' sono in §9bis.

### `freezer_backup_source.dart`

`class FreezerBackupSource implements BackupSource` — `const FreezerBackupSource(AppDatabase db, {DateTime Function()? clock})`

| Membro | Firma |
|---|---|
| `schemaId` | `String get schemaId => 'full_freezer'` |
| `schemaVersion` | `int get schemaVersion => 1` |
| `exportPayload` | `Future<Map<String, Object?>> exportPayload()` |
| `importPayload` | `Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode})` |
| `imagePaths` | `Future<List<String>> imagePaths()` — ogni `photoPath` **e** la sua miniatura |
| `counts` | `Future<Map<String, int>> counts()` — `freezers`, `items` (dentro), `history` (usciti) |

Forma del payload:

```
{ customCategories: [ {id, name, iconKey, colorValue, defaultReminderDays} ],
  freezers: [ { name, modelKey, capacityLiters, calibration, lastAlertLevel, sortOrder, createdAt,
                compartments: [ { name, sortOrder, items: [item…] } ],
                items: [item…]  /* senza scomparto */ } ] }
item = {name, category, quantity, unit, frozenAt, reminderAfterDays, volumeLiters, volumeManual,
        photoPath, note, status, removedAt, createdAt}
```

⚑ **Annidato** (freezer → scomparti → alimenti), come TrashCan: gli id di riga non
significano niente su un altro telefono, e annidando non c'e' niente da rimappare. **Unica
eccezione: le categorie personalizzate**, che gli alimenti citano come `custom:<id>`. Si
esportano con il loro id di allora e l'import traduce vecchio → nuovo (`categoryMap`); un id
non trovato diventa "senza categoria". Un errore qui darebbe a un alimento la categoria di un
altro.

⚑ Si esportano **anche gli usciti**: sono storico e statistiche, cioe' cio' per cui si paga il
Pro. I movimenti non si esportano: all'import si ricostruiscono `stored` (a `createdAt`) e,
per gli usciti, l'uscita (a `removedAt`).

Import: **una sola transazione**. `replaceAll` cancella prima freezer (a cascata scomparti,
alimenti, movimenti) e categorie; `mergeKeepExisting` **salta i freezer con lo stesso nome** di
uno gia' presente (le categorie personalizzate invece si aggiungono sempre). `nameNorm` si
ricalcola. Un'interruzione fuori transazione cancellerebbe i dati senza rimpiazzarli.

### `csv_export.dart`

| Funzione | Firma |
|---|---|
| `exportStoredCsv` | `Future<File> exportStoredCsv({required AppPaths paths, required L l, required List<Item> items, required List<Freezer> freezers, required Map<int, List<Compartment>> compartments, required CivilDate today, List<CustomCategory> customCategories = const []})` → `exports/full-freezer-<YYYY-MM-DD>.csv` |
| `buildStoredCsv` | `CsvWriter buildStoredCsv({required L l, required List<Item> items, required List<Freezer> freezers, required Map<int, List<Compartment>> compartments, required CivilDate today, List<CustomCategory> customCategories = const []})` — separato dalla scrittura per i test (AppPaths vuole path_provider) |

Colonne: nome, categoria, quantita', unita', congelato il, giorni nel freezer, freezer,
scomparto, nota. ⚑ `;` e BOM UTF-8 (impostazioni del CsvWriter di micro_core): e' il formato
che Excel in italiano apre con un doppio clic, accenti compresi. Niente id, niente litri.

### `voice_input.dart`

`class VoiceInput` — `VoiceInput({SpeechToText? engine})`

| Membro | Firma | |
|---|---|---|
| `isListening` | `bool get isListening` | |
| `prepare` | `Future<bool> prepare({void Function(String status)? onStatus})` | chiede il permesso la prima volta; `false` se negato o senza riconoscitore (non lancia) |
| `listen` | `Future<void> listen({required String languageTag, required void Function(String words, {required bool isFinal}) onWords})` | dettatura, risultati parziali, pausa 3 s, limite 15 s |
| `stop` | `Future<void> stop()` | |
| `cancel` | `Future<void> cancel()` | |
| `localeIdFor` | `@visibleForTesting static String localeIdFor(String languageTag)` | `it*` → `it_IT`, altro → `en_US` |

⚑ Il riconoscimento lo fa **il telefono** (Google / Apple), non l'app: l'app non parla con
nessun server, ma il motore di sistema puo' usare i server del produttore, e l'informativa
privacy del sito deve dirlo. ⚑ Un oggetto per foglio, non un singleton: lo stato "sta
ascoltando" deve morire con il foglio. ⚑ Pausa di 3 s: chi si ferma a pensare "due porzioni
di… lasagne" non deve vedersi chiudere il microfono.

---

## 9. `lib/features/` — le schermate

### Home — `features/home/`

`class HomePage extends ConsumerWidget` (`const HomePage({Key? key})`) — interfaccia
"A · Ghiaccio":

1. **Testata blu notte** (privata `_NightHeader`): nome del freezer (con piu' freezer e' un menu
   `_FreezerPicker` che chiama `selectedFreezerProvider.select`), numero di prodotti, lente
   (→ `/search`) e ingranaggio (→ `/settings`); con un freezer guardato, asticella `FillGauge` e
   percentuale grande (tocco → `/freezers/<id>`); con "Tutti", `home_allFreezersHint`; bollino
   ambra con `useSoonTotal`. Barra di stato chiara (AnnotatedRegion) e striscia blu notte fissa
   sotto la barra di stato.
2. **"Da usare prima"**: schede `UseSoonCard` su due colonne, `view.useSoon` (**al massimo
   `useSoonPreview` = 4**), "Vedi tutti" → `/use-soon` se `useSoonTotal > useSoonPreview`.
3. **"Tutto il resto · N"**: righe `ItemRowTile`.
4. **"Dove sono"**: solo con piu' di un freezer (con uno, la testata e' il freezer): silhouette,
   conteggio, `FillBar`, tocco → pagina del freezer.
5. Stato vuoto `_EmptyHint` (fiocco, `home_emptyTitle`, `home_emptyBody`).
6. Pulsante largo fisso "Metti nel freezer" → `showQuickAdd`.

`class UseSoonPage extends ConsumerWidget` — tutti i `useSoonAll` come schede.

`features/home/item_row_tile.dart`:

| Simbolo | Firma | |
|---|---|---|
| `UseSoonCard` | `const UseSoonCard({required ItemRow row, required String subtitle, Key? key})` | giorni in grande nel colore dell'anzianita', nome, sottotitolo |
| `ItemRowTile` | `const ItemRowTile({required ItemRow row, required String subtitle, Key? key})` | foto (se c'e') o icona categoria, nome, sottotitolo, giorni brevi |
| `daysColor` | `Color daysColor(AgingLevel level, FreezerPalette p)` | `old` → `p.old`, `watch` → `p.watch`, `fresh` → `inkMuted` |
| `itemSubtitle` | `String itemSubtitle(BuildContext context, ItemRow row, {required bool showFreezer, String? compartment})` | "2 porzioni · Cassetto 1 · Freezer cucina" |

Gesti comuni (privata `_ItemGestures`): swipe a destra **consumato**, a sinistra **buttato**,
entrambi con "Annulla" nello snackbar (`undoRemoval`); tocco → `/items/<id>`; **pressione
lunga → "Ne ho congelato un altro uguale"** (`duplicateAsToday` con `todayProvider`).

⚑ Niente conferma sullo swipe: l'uscita e' il gesto piu' frequente dopo l'entrata, e
l'annullamento rimette tutto com'era.

☠ Dismissible mette il contenuto in uno Stack, che **allenta i vincoli**: senza il
`SizedBox(width: double.infinity)` le schede si stringono sul testo e due schede affiancate
escono di larghezze diverse (emulatore, 2026-10-07).

### Inserimento — `features/items/`

`quick_add_sheet.dart`

| Simbolo | Firma | |
|---|---|---|
| `showQuickAdd` | `Future<void> showQuickAdd(BuildContext context, WidgetRef ref)` | prepara la bozza e apre il foglio; senza freezer non fa niente |
| `QuickAddSheet` | `const QuickAddSheet({required ItemDraft draft, Key? key})` | il foglio |

Bozza iniziale: freezer = quello guardato in home, altrimenti `lastFreezer`, altrimenti il
primo; scomparto = `lastCompartment` se appartiene a quel freezer; unita' = `lastUnit` se nota,
altrimenti porzioni; quantita' = `defaultQuantity(unita')`; data = oggi.

Il foglio: campo nome con **tastiera gia' aperta** (`autofocus`), icona della categoria dedotta
a sinistra, microfono e fotocamera (o miniatura) a destra; chip dell'autocompletamento
(`suggestNames`, limite 6, con un "biglietto" `_query` perche' una risposta vecchia non
sovrascriva una nuova); stepper `quantityStep`; chip delle unita' (cambiando unita' la quantita'
torna a `defaultQuantity`); riga posizione (toccabile solo se c'e' una scelta); riga ingombro
"≈ 1,2 L · il freezer sara' pieno al 67%" (rossa da 0,85, tocco → `pickSize`); "Altri
dettagli" → `push(Routes.itemNew, extra: draft)`; "Salva". Salvando scrive `lastFreezer`,
`lastCompartment` (o lo cancella), `lastUnit`.

⚑ **Il vincolo dell'app**: dall'apertura al salvato meno di 5 secondi e meno di 4 tocchi.
Percorso minimo: "+", nome, Salva = **3 interazioni**; con un suggerimento, 4. Lo misura
`test/widget/quick_add_test.dart`. Ogni campo in piu' visibile qui e' un motivo per non usare
l'app; microfono, foto e ingombro sono facoltativi e non aggiungono tocchi.

Voce: `_toggleVoice` crea `VoiceInput` al **primo tocco** (chi non lo usa non vede la richiesta
di permesso), mostra il testo provvisorio nel campo, e al risultato finale `_applyVoice`:
`VoiceItemParser(locale: lingua).parse`, nome nel campo, quantita' e unita' cambiate **solo se
la frase le dice entrambe**.

Foto nel foglio: se il foglio si chiude senza salvare ne' passare ad "Altri dettagli", la foto
scattata si cancella (`_handedOff`).

`item_draft.dart` — `class ItemDraft` (mutabile)

| Membro | Firma | |
|---|---|---|
| costruttore | `ItemDraft({required int freezerId, required CivilDate frozenAt, int? compartmentId, String name = '', double quantity = 1, String unit = Units.fallback, String? category, bool categoryManual = false, int? reminderAfterDays, double? volumeLiters, bool volumeManual = false, String? photoPath, String? note})` | |
| da riga | `factory ItemDraft.fromItem(Item item)` | `categoryManual: true` |
| campi | `freezerId`, `compartmentId`, `frozenAt`, `name`, `quantity`, `unit`, `category`, `categoryManual`, `reminderAfterDays`, `volumeManual`, `photoPath`, `note` | |
| `setName` | `void setName(String value)` | ri-deduce la categoria se non scelta a mano |
| `setCategory` | `void setCategory(String? key)` | `categoryManual = true` |
| `volumeLiters` | `double get volumeLiters` | quello a mano, o la stima aggiornata |
| `setManualVolume` | `void setManualVolume(double liters)` | |
| `resetVolume` | `void resetVolume()` | torna alla stima |
| `isValid` | `bool get isValid` | nome non vuoto e quantita' > 0 |
| `toNewItem` | `NewItem toNewItem()` | |
| `applyTo` | `Item applyTo(Item item)` | per `updateItem` |

Funzioni: `double quantityStep(String unit)` — g 100, kg/L 0,5, altro 1;
`double defaultQuantity(String unit)` — g 500, altro 1.

⚑ Una bozza comune: "Altri dettagli" apre la pagina completa **con quello che si era gia'
scritto**, e le due schermate non possono stimare l'ingombro in due modi diversi.

`item_edit_page.dart` — `class ItemEditPage extends ConsumerStatefulWidget`,
`const ItemEditPage({int? itemId, ItemDraft? draft, Key? key})`: con `itemId` modifica (id
inesistente → `pop`), altrimenti crea da `draft` o da una bozza vuota nel primo freezer.
Salvando una modifica: **se freezer o scomparto sono cambiati chiama prima `moveItem`**
(movimento `moved`, regola 3 del repository), poi `updateItem`; con il solo `updateItem` lo
spostamento non lasciava traccia (trovato rileggendo il codice per l'atlante, 2026-10-07).
Campi: foto (`ItemPhotoEditor`, in cima), nome, categoria (`chooseCategory`), quantita' +
unita', data di congelamento (fino a 5 anni indietro, non nel futuro), posizione
(`pickLocation`), ingombro (`pickSize`), promemoria personale con l'aiuto del promemoria di
categoria, disclaimer "non e' una scadenza", nota. Menu: duplica, consumato, buttato (questi
due solo se `stored`). Un alimento **uscito** mostra una scheda con "Rimetti nel freezer"
(`undoRemoval`).

Pulizia foto: le foto scattate nella pagina (e quella arrivata dal foglio) si cancellano se si
esce senza salvare; salvando si cancellano quelle non usate e la vecchia se cambiata.

`item_photo.dart`

| Simbolo | Firma | |
|---|---|---|
| `itemPhotoMaxSide` | `const int itemPhotoMaxSide = 1280` | lato lungo, ~150 KB a foto |
| `itemPhotoBucket` | `const String itemPhotoBucket = 'items'` | sottocartella di `images/` |
| `thumbPathOf` | `String thumbPathOf(String photoPath)` | solo il **primo** `images/` → `images/thumbs/` |
| `pickItemPhoto` | `Future<String?> pickItemPhoto(BuildContext context, WidgetRef ref)` | foglio fotocamera/galleria, ImagePicker, importazione con ImageStore di micro_core; restituisce il percorso **relativo**; errore → snackbar e null |
| `deleteItemPhoto` | `Future<void> deleteItemPhoto(AppPaths paths, String photoPath)` | foto e miniatura; prende AppPaths e non `ref` perche' si chiama da `dispose` |
| `ItemPhotoThumb` | `const ItemPhotoThumb({required String photoPath, required double size, required Widget fallback, double radius = 10, Key? key})` | miniatura quadrata, file mancante → `fallback` |
| `ItemPhotoEditor` | `const ItemPhotoEditor({required String? photoPath, required ValueChanged<String?> onChanged, Key? key})` | foto 4:3 con "Togli" / "Cambia", o "Aggiungi foto" |

⚑ Il ridimensionamento lo fa ImageStore **in un isolate** (una foto da 12 MP congelerebbe la
UI per secondi). ⚑ La copia che image_picker lascia nella cache si cancella dopo l'importazione,
**solo se il percorso contiene `/cache/`**: dalla galleria, su alcune versioni, il percorso e'
l'originale dell'utente.

`item_pickers.dart`

| Simbolo | Firma | |
|---|---|---|
| `unitName` | `String unitName(L l, String key, double quantity)` | plurale per porzioni/pezzi/confezioni; `g`, `kg`, `L` fissi |
| `categoryName` | `String categoryName(L l, String? key, [List<CustomCategory> custom = const []])` | predefinita dagli ARB o personalizzata; `custom:` sconosciuta → "Nessuna categoria" |
| `categoryGlyph` | `Widget categoryGlyph(String? key, {double size = 22, Color? color})` | l'icona, che **legge da sola** le categorie personalizzate |
| `newCategoryChoice` | `const String newCategoryChoice = '+new'` | |
| `chooseCategory` | `Future<(String, int?)?> chooseCategory(BuildContext context, WidgetRef ref, String? current)` | `(chiave, promemoria)`; `''` = nessuna; "+ nuova" senza Pro → paywall e null; con Pro crea la categoria e la restituisce |
| `pickCategory` | `Future<String?> pickCategory(BuildContext context, String? current, {List<CustomCategory> custom = const []})` | il foglio: predefinite, personalizzate, "+ nuova", "nessuna" |
| `SizeChoice` | `sealed class SizeChoice` (`const SizeChoice()`) | esito di `pickSize` |
| `SizeLiters` | `final class SizeLiters extends SizeChoice` — `const SizeLiters(double liters)` | litri della **riga intera** |
| `SizeAuto` | `final class SizeAuto extends SizeChoice` — `const SizeAuto()` | torna alla stima |
| `pickSize` | `Future<SizeChoice?> pickSize(BuildContext context, {required double quantity, required double estimate, required bool manual})` | stima, 4 misure rapide (per unita' x quantita'), valore libero |
| `pickLocation` | `Future<({int freezerId, int? compartmentId})?> pickLocation(BuildContext context, {required List<Freezer> freezers, required Map<int, List<Compartment>> compartments, required int freezerId, required int? compartmentId})` | freezer e scomparti |

⚑ **Il promemoria della categoria personalizzata si copia nell'alimento** invece di leggerlo
ogni volta: cambiare la categoria domani non sposta i promemoria di cio' che e' gia' dentro, e
cancellarla non li fa sparire.

### Freezer — `features/freezers/`

| Simbolo | Firma | |
|---|---|---|
| `openProFeature` | `Future<void> openProFeature(BuildContext context, WidgetRef ref, FeatureKey key, String route)` | paywall con la funzione evidenziata se serve, poi `push` |
| `openNewFreezer` | `Future<void> openNewFreezer(BuildContext context, WidgetRef ref)` | `withinLimit(unlimitedEntities, count)` o paywall, poi `/freezers/new` |
| `FreezerEditorPage` | `const FreezerEditorPage({int? freezerId, bool firstRun = false, Key? key})` | nome + griglia di modelli (+ "Altro: litri", 1..2000); `firstRun`: "Inizia", segna `onboardingDone`, invalida il provider, `go(home)` |
| `FreezerPage` | `const FreezerPage({required int freezerId, Key? key})` | pannello blu notte (asticella, %, litri, conteggio, silhouette), modello, taratura ("Ripristina" se ≠ 1), scomparti riordinabili con la maniglia, rinomina/elimina, elimina freezer (conferma con il numero di alimenti) |
| `compartmentsProvider` | `StreamProvider.family<List<Compartment>, int>` | in `freezer_page.dart` |
| `FreezerSilhouette` | `const FreezerSilhouette({required String iconKey, double size = 56, Key? key})` | disegno del modello (`ice_box`, `fridge_top`, `combi`, `undercounter`, `chest`, `side_by_side`, `upright`, default `custom` con una "L") |
| `FillBar` | `const FillBar({required FillInfo fill, double height = 10, bool showLabel = true, Key? key})` + `static Color colorFor(double fraction, ColorScheme scheme)` | verde < 0,70, ambra < 0,85, rosso oltre |
| `FillGauge` | `const FillGauge({required FillInfo fill, required Color track, required Color color, double height = 92, double width = 14, Key? key})` | asticella verticale, rossa da 0,85 |
| `freezerModelName` | `String freezerModelName(L l, String key)` | nome visibile del modello |
| `silhouetteKeyFor` | `String silhouetteKeyFor(String modelKey)` | `iconKey` del modello o `custom` |

⚑ `openNewFreezer` e' **una funzione sola** perche' "aggiungi un freezer" si tocca da piu'
punti: chi scrivesse il controllo in ogni pagina prima o poi ne dimenticherebbe uno, e il
secondo freezer diventerebbe gratis da quella porta.

⚑ Il nome proposto per un freezer nuovo e' "Freezer cucina" per il primo e "Freezer N" dal
secondo (un secondo "Freezer cucina" era un doppione, emulatore 2026-10-07). Si scrive in
`didChangeDependencies` perche' serve la lingua.

⚑ Silhouette disegnate e non icone: Material ha un frigorifero solo, e il modello si sceglie
proprio guardando la forma.

⚑ Scomparti riordinati con `onReorderItem` (l'indice d'arrivo e' gia' corretto per l'elemento
tolto; `onReorder` lo darebbe incrementato).

### Storico e statistiche (Pro) — `features/history/`

`HistoryPage` (`const HistoryPage({Key? key})`): usciti a gruppi per mese (piu' recenti
prima), "Consumato/Buttato · data · rimasto N giorni", tocco → pagina dell'alimento (da cui lo
si rimette dentro).

`StatsPage` (`const StatsPage({Key? key})`): "adesso" e' `ref.watch(todayProvider).toLocalMidnight()`
(la pagina non legge l'orologio da sola); periodo 30 giorni / 12 mesi / sempre (default
anno), pannello blu notte con la quota buttata, permanenza media, categoria piu' buttata,
grafico degli ultimi sei mesi disegnato a mano (privati `_MonthChart`, `_Bar`, `_Legend`,
`_NumberTile`), riga verso lo storico.

⚑ Grafico disegnato a mano: per sei coppie di barre una libreria (fl_chart, previsto dal piano)
e' un plugin in piu' da tenere aggiornato senza dare niente in cambio.

### Categorie personalizzate (Pro) — `features/categories/`

`CustomCategoriesPage` (`const CustomCategoriesPage({Key? key})`): elenco, modifica, elimina
(conferma col numero di alimenti che la usano), "Nuova categoria".

`custom_category_editor.dart`: `@immutable class CustomCategoryDraft` —
`const CustomCategoryDraft({required String name, required String iconKey, int? reminderDays})`;
`const List<String> customCategoryIcons` (le stesse 9 icone disegnate delle predefinite);
`Future<CustomCategoryDraft?> showCustomCategoryEditor(BuildContext context, {CustomCategory? existing})`
(dialogo: nome ≤ 40, icona, promemoria facoltativo; null se annullato).

⚑ Niente icone Material ne' colori per le categorie dell'utente: stanno nelle stesse righe delle
predefinite, e un'icona di un'altra famiglia o una categoria arancione stonerebbero. Per questo
`color_value` si salva a 0.

### Ricerca — `features/search/search_page.dart`

`SearchPage` (`const SearchPage({Key? key})`): campo nell'app bar con tastiera aperta,
risultati a ogni lettera (`searchItems` su `storedItemsProvider`) come `ItemRowTile`, con
scomparto sempre e freezer se ce n'e' piu' d'uno; testi per query vuota e senza risultati.

### Impostazioni — `features/settings/`

`SettingsPage` (`const SettingsPage({Key? key})`), dall'alto:

1. **Scheda Pro** blu notte, **tutta toccabile** (in TrashCan il riquadro non rispondeva).
2. **Freezer**: elenco in un ReorderableListView (tocco → pagina del freezer); **con piu'
   di un freezer** la coda della riga e' una maniglia (ReorderableDragStartListener) e il
   trascinamento chiama `reorderFreezers` (`onReorderItem`); con uno solo, una freccia.
   L'ordine e' quello di "Dove sono" e del menu della testata. "Aggiungi un freezer"
   (`openNewFreezer`), con ProBadge e "serve il Pro" gia' prima del tocco.
3. **Avvisi**: interruttore (senza Pro: ProBadge e tocco → paywall); con Pro e acceso,
   frequenza del riepilogo.
4. **I numeri**: statistiche (senza Pro dice quante uscite ci sono gia') e storico, via
   `openProFeature`.
5. **I tuoi dati**: categorie (`openProFeature`), CSV, backup (Pro), **ripristino (gratis)**.
6. **Acquisto**: "Ripristina acquisti" (testo Apple o Google), "Aggiungi il widget" **solo se
   `FreezerWidget.available`**.
7. **Aspetto**: tema sistema/chiaro/scuro. Versione in fondo (`appVersion`).

Privati: `_setAlerts(context, ref, on)` — accendendo **chiede il permesso** (negato → snackbar
e resta spento), poi `set`, `evaluateCapacity` e `rescheduleAll` subito (chi accende con il
freezer quasi pieno deve saperlo adesso); `_pinWidget` — su iOS spiega i gesti (non c'e'
un'API), su Android `requestPinWidget` se supportato.

`data_actions.dart`:

| Simbolo | Firma | |
|---|---|---|
| `backupServiceProvider` | `Provider<BackupService>` | `BackupService(paths:, appVersion:)` |
| `exportCsv` | `Future<void> exportCsv(BuildContext context, WidgetRef ref)` | Pro; scrive e condivide |
| `createBackup` | `Future<void> createBackup(BuildContext context, WidgetRef ref)` | Pro; **foto comprese** (`includeImages: true`); condivide |
| `restoreBackup` | `Future<void> restoreBackup(BuildContext context, WidgetRef ref)` | **gratis**; sceglie il file, lo ispeziona, mostra il riepilogo (freezer, dentro, storico), chiede sostituisci/aggiungi, ripristina; poi "Tutti" e `onboardingDone` |

⚑ **Ripristino gratis, creazione Pro**: chi passa a un telefono nuovo deve poter riavere i
suoi dati anche prima di aver ripristinato l'acquisto. Il Pro si vende sulla creazione del
backup, non sul diritto di riavere i propri dati.

⚑ Foto nel backup: sono gratis e fanno parte dei dati; senza, il telefono nuovo sarebbe pieno
di miniature rotte.

☠ Un ripristino "sostituisci tutto" e' irreversibile: il riepilogo prima della conferma e' il
solo modo di accorgersi del file sbagliato.

### Il lucchetto Pro — `features/common/pro_gate.dart`

`class ProGate extends ConsumerWidget` —
`const ProGate({required FeatureKey feature, required Widget child, bool Function(FeatureGate gate)? allowed, Key? key})`.
`build` guarda `featureGateProvider`: se `allowed?.call(gate) ?? gate.allows(feature)` e' vero
restituisce `child`; altrimenti uno Scaffold con lucchetto, `pro_locked` ("Questa funzione fa
parte di Full Freezer Pro.") e il pulsante `paywall_buy` → `showFreezerPaywall(highlight: feature)`.
Si ridisegna da solo quando il Pro arriva. `allowed` serve ai limiti numerici (il secondo
freezer). Usato in `buildRouter` (§7), dove c'e' anche il perche' non e' un redirect.

### Componenti comuni — `features/common/ghiaccio.dart`

| Classe | Firma |
|---|---|
| `GhiaccioSectionLabel` | `const GhiaccioSectionLabel({required String text, Widget? trailing, EdgeInsets padding = const EdgeInsets.fromLTRB(22, 22, 22, 10), Key? key})` — maiuscolo spaziato, azione opzionale a destra |
| `GhiaccioTile` | `const GhiaccioTile({required String title, String? subtitle, Widget? leading, Widget? trailing, VoidCallback? onTap, Key? key})` — riga bianca arrotondata, icona nel riquadro azzurro |

Stanno in un file comune perche' home, freezer, impostazioni, storico e categorie devono avere
le stesse righe: copiate in ogni pagina divergerebbero al primo ritocco.

### Avvio — `lib/main.dart` e `lib/dev/demo_data.dart`

`Future<void> main()`: `buildFreezerConfig()` → `assertUsableInRelease()` (una release col
billing finto fallisce subito) → AppPaths (`ensureAll`) → log su file `full_freezer.log` →
`FlutterError.onError` nel log → SettingsStore (namespace `full_freezer`) → conta gli avvii
(`launchCount`, `firstLaunchAt`) → **demo** se richiesta → `runApp` con i tre override.

⚑ Database, notifiche e store li inizializzano i provider, pigramente: farlo prima del primo
frame da' una schermata bianca all'avvio.

`demo_data.dart`: `const bool demoRequested = bool.fromEnvironment('FF_DEMO')`;
`bool get demoEnabled` (= richiesto **e** non release);
`Future<bool> seedDemoData(AppDatabase db, SettingsStore settings, {required String freezerName})`
— solo su database **vuoto**: un freezer `combi_compact` con due cassetti, 23 alimenti con date
nel passato, 18 uscite degli ultimi sei mesi (ognuna scritta da un repository con l'orologio
fermo al giorno dell'uscita, cosi' `removedAt` e' vero), `onboardingDone`. Usa una connessione
sua, chiusa prima che l'app apra la propria; va fatto **prima** di `runApp` perche' il router
decide subito se mostrare il primo avvio.

☠ Mai in release: anche compilato con il define, in release non fa niente.

---

## 9bis. Il widget di sistema: il contratto fra Dart, Kotlin e Swift

**Cosa mostra**: titolo "DA USARE PRIMA" / "USE FIRST", conteggio ("23 prodotti"), i **tre
alimenti che stanno nel freezer da piu' tempo** con icona, nome e giorni; i giorni diventano
color ambra quando superano il promemoria della riga. Tocco → "Da usare prima". Android 4x2;
iOS piccolo (2 righe, giorni sotto il nome) e medio (3 righe).

### Le chiavi condivise (preferenze del plugin / UserDefaults del gruppo)

| Dart (`FreezerWidget`) | Valore | Kotlin | Swift (Chiavi) | Contenuto |
|---|---|---|---|---|
| `keyTitle` | `title` | KEY_TITLE | `titolo` | `home_useSoon` in maiuscolo |
| `keyCount` | `count` | KEY_COUNT | `conteggio` | `home_itemCount(n)` |
| `keyEmpty` | `empty` | KEY_EMPTY | `vuoto` | `home_emptyTitle` |
| `keyRows` | `rows` | KEY_ROWS | `righe` | le righe, separate da `\n` |
| `keyToday` | `days_today` | KEY_TODAY | `oggi` | `item_daysShort(0)` ("oggi") |
| `keyDaysTemplate` | `days_template` | KEY_DAYS_TEMPLATE | `modelloGiorni` | "{n} gg" / "{n} d" |
| `iconKeyPrefix` | `icon_` | ICON_PREFIX | `prefissoIcona` | `icon_<iconKey>` → **percorso** del PNG (lo scrive `HomeWidget.saveFile`) |
| `fieldSeparator` | `\u001F` | FIELD | `separatoreCampo` | |
| `iosGroup` | `group.com.smp.fullfreezer` | — | `gruppo` | |

☠ **Le chiavi sono scritte a mano in tre linguaggi**: una divergenza da' un campo vuoto nel
widget senza nessun errore da nessuna parte, e su una piattaforma sola (lo si cerca nel posto
sbagliato). Se ne cambi una, cambiale tutte e tre.

Riga: `frozenAt US nome US iconKey US promemoria` — data `YYYY-MM-DD`; nome con gli a capo
sostituiti da spazi (spezzerebbero la riga); chiave dell'icona disegnata (personalizzata →
la sua, ignota → `other`); promemoria dell'alimento o della categoria, **vuoto** se nessuno
(allora la riga non si colora mai). Una riga con meno di 4 campi si salta.

### Perche' cosi'

⚑ **ADR-018 applicato all'anzianita': i giorni li calcola il widget.** I giorni cambiano a
mezzanotte anche se nessuno apre l'app, e Dart gira solo con l'app aperta. Il payload **non
contiene "N giorni"** ma la data di congelamento: Kotlin con `LocalDate.now()` (la data locale,
la stessa nozione di CivilDate), Swift con la data della voce della timeline. Il numero non
invecchia mai.

⚑ **"I piu' vecchi" e non "da usare presto" della home**: "da usare presto" dipende dalla data
di oggi (un alimento ci entra il giorno in cui supera il promemoria), quindi andrebbe
ricalcolato ogni notte, e a farlo dovrebbe essere il widget. L'ordine per data di
congelamento **non cambia col passare dei giorni**: i tre piu' vecchi di oggi sono quelli di
domani finche' qualcuno non tocca i dati, e toccare i dati vuol dire aprire l'app, che
ripubblica. Il colore "vecchio" lo decide il widget confrontando i giorni col promemoria della
riga.

⚑ **Il widget non e' una leva del Pro** (ADR-019): `FeatureKey.advancedWidget` e' `open()`.

⚑ Il modello dei giorni si ricava dal testo dell'app con un numero sentinella (987654): il
widget dice i giorni esattamente come le righe della home, e una traduzione corretta in
`testi.py` corregge entrambi.

⚑ Icone: PNG **bianchi su trasparente** disegnati da `CategoryGlyphPainter`, tinti dal widget
(Kotlin `setColorFilter` ghiaccio `#8FB8FF`, Swift `.renderingMode(.template)`): stesso
disegno dell'app, e il colore sta in un posto solo per piattaforma.

### Android — `FullFreezerWidgetProvider.kt` + layout

`class FullFreezerWidgetProvider : HomeWidgetProvider()` — `onUpdate(context, appWidgetManager,
appWidgetIds, widgetData)` chiama `update` dentro un `try`. Per ogni widget: titolo (se
pubblicato), conteggio, fino a 3 righe (ROW_IDS), giorni con `ChronoUnit.DAYS.between`
(mai negativi), colore DAYS `#B9CBE8` o OLD `#FFB547`, icona da `decodeFile` (null →
INVISIBLE); `widget_empty` se le righe ci sono ma vuote; `widget_stale` ("Apri Full Freezer
per vedere cosa c'e' dentro") se l'app non ha mai pubblicato; tocco
`HomeWidgetLaunchIntent.getActivity(..., Uri.parse("fullfreezer:///use-soon"))`.

| File | Ruolo |
|---|---|
| `res/layout/full_freezer_widget.xml` | `widget_root`, `widget_title`, `widget_count`, `widget_stale`, `widget_empty`, `widget_row{1,2,3}` con `widget_icon/name/days{1,2,3}` |
| `res/layout/full_freezer_widget_preview.xml` | anteprima nel selettore con le righe d'esempio |
| `res/xml/full_freezer_widget_info.xml` | 250x110 dp, `targetCell` 4x2, ridimensionabile (min 180x110), `updatePeriodMillis="0"` |
| `res/values/widget.xml` (+ `values-it/`) | `widget_label`, `widget_description`, `widget_title`, `widget_sample1..3`, `widget_open_app`; stili WidgetRow, WidgetIcon, WidgetName, WidgetDays |
| `res/drawable/widget_background.xml` | blu notte, raggio 22dp |

☠ **Solo LinearLayout, TextView e ImageView**: RemoteViews accetta un sottoinsieme ristretto, e
un ConstraintLayout produce un widget che non si disegna, senza errori.
⚑ Tre righe fisse con visibilita' e non una lista: una ListView in RemoteViews vuole un
RemoteViewsService, un servizio in piu' per tre righe.
☠ Righe con **altezza 0 e peso 1**: con `wrap_content` stavano in alto e lasciavano mezzo widget
vuoto, che si legge come "non ha caricato" (emulatore, 2026-10-07).
☠ Tutto `onUpdate` in un `try`: un'eccezione in un BroadcastReceiver fa cadere **l'intero
processo dell'app** ("Full Freezer continua a bloccarsi").
☠ `decodeFile` restituisce null se il PNG e' stato pulito dalla cache: si nasconde l'icona
invece di lasciare quella della riga precedente.
⚑ I testi del widget stanno in `res/values` e non arrivano da Dart: il selettore e il primo
disegno avvengono prima che l'app sia mai partita. Mai un widget vuoto.
⚑ `updatePeriodMillis = 0`: gli aggiornamenti li pilotano l'app (a ogni modifica) e la sveglia
delle 00:05; con un periodo il sistema sveglierebbe il telefono per niente.
☠ **HomeWidgetScheduledUpdateReceiver deve stare nel manifest**: senza, la sveglia delle 00:05
scatta e non arriva a nessuno, e il widget resta ai giorni di ieri. BOOT_COMPLETED e
MY_PACKAGE_REPLACED la riarmano. `scheduleDailyRefresh` passa 365 orari: il plugin ne arma
**uno per volta** e riarma il successivo.
☠ `androidName` **con il package**: col solo nome il plugin cerca la classe sotto
l'applicationId, e con un suffisso `.debug` non la trova piu'.

### iOS — `ios/FullFreezerWidget/`

| Simbolo Swift | File | Ruolo |
|---|---|---|
| `struct FullFreezerWidget: Widget` (`@main`) | `FullFreezerWidget.swift` | `kind = "FullFreezerWidget"` (= `FreezerWidget.iosName`), famiglie small e medium, `contentMarginsDisabled()` |
| `struct Fornitore: TimelineProvider` | idem | **8 voci**: adesso + le 7 mezzanotti seguenti, policy `.atEnd` |
| `struct VistaConFamiglia: View` | idem | passa la famiglia, `widgetURL(fullfreezer:///use-soon?homeWidget)`, sfondo |
| `enum Chiavi`, `separatoreCampo` | `VistaFreezer.swift` | le chiavi della tabella sopra |
| `enum Ripiego` | idem | titolo e "apri l'app" **detti dall'estensione da sola** (it/en da `Locale.preferredLanguages`) |
| `struct RigaAlimento`, `struct VoceFreezer: TimelineEntry` | idem | `giorni(_:)` rispetto alla data **della voce**, `testoGiorni(_:)`, `vecchio(_:)` |
| `struct Deposito` | idem | lettura astratta (`condiviso` = UserDefaults del gruppo; l'anteprima usa un dizionario), `voce(al:)` |
| `struct VistaFreezer: View` | idem | il disegno SwiftUI; `static func carica(_:)` UIImage/NSImage |

⚑ **Una voce per ciascuno dei prossimi 7 giorni, a mezzanotte**: su iOS non c'e' sveglia; e'
WidgetKit a passare da una voce all'altra, e ogni voce calcola i giorni rispetto alla propria
data. L'app fa ricaricare la timeline a ogni modifica (`updateWidget`).
☠ Il parametro `?homeWidget` nell'URL e' quello con cui il plugin riconosce un tocco sul widget
(`HomeWidgetPlugin.isWidgetUrl`): senza, l'URL arriva all'app e nessuno lo inoltra a Dart.
☠ `contentMarginsDisabled` e `containerBackground` (iOS 17+): senza, il fondo blu resta staccato
dai bordi dentro un riquadro bianco.
☠ Il gruppo `group.com.smp.fullfreezer` e' ripetuto in tre posti (Dart, due `.entitlements`) e
va **registrato sul portale Apple**: senza, `saveWidgetData` scrive in un contenitore nullo,
nessun errore, widget vuoto. Per questo Ripiego esiste: se il contenitore e' vuoto, e' vuoto
anche qualunque testo messo li' dentro.

---

## 10. Cosa e' Pro e cosa e' gratis

La mappa vive in `lib/app/feature_limits.dart` (`freezerFeatureLimits`) ed e' l'**unico**
posto in cui cambiarla. Decisioni del proprietario del 2026-10-06 (F4.0 punti 8, 10, 11).

| Funzione | Chiave | Piano gratuito | Dove si controlla |
|---|---|---|---|
| Secondo freezer e oltre | `unlimitedEntities` | **uno** (`count(freeMax: 1)`) | `openNewFreezer` + `ProGate` su `/freezers/new` |
| Riepilogo e avvisi quasi pieno/vuoto | `notifications` | no | impostazioni **e** `FreezerScheduler.allowed` |
| Storico degli usciti | `fullHistory` | no (i dati restano nel DB) | `openProFeature` + `ProGate` |
| Statistiche dello spreco | `statistics` | no | `openProFeature` + `ProGate` |
| Export CSV | `csvExport` | no | `exportCsv` |
| Creazione del backup | `backupRestore` | no — **il ripristino e' gratis** | `createBackup` |
| Categorie personalizzate | `customCategories` | no (quelle esistenti restano visibili) | `openProFeature` + `ProGate`, `chooseCategory` |
| Foto dei prodotti | `photos` | **si'** | |
| Scomparti | `secondaryEntities` | **illimitati** | |
| Widget | `advancedWidget` | **si'** (ADR-019) | |
| `multipleNotifications`, `pdfReport`, `calendarSync`, `themeCustomization` | | aperte: l'app non le ha | |

**Il gratuito e' un'app completa**: freezer con modello e riempimento, scomparti, prodotti
illimitati, inserimento rapido e vocale, foto, ricerca, widget, barra di riempimento. **Il Pro
vende** il secondo freezer (chi ha il pozzetto in garage ha gia' il problema), il richiamo
delle notifiche, e i numeri dello spreco.

⚑ **Foto gratis, notifiche Pro** (ribalta il piano originale): la foto fa parte del gesto di
inserimento e toglierla al gratuito peggiora l'app che deve farsi installare; la notifica e' il
richiamo che riporta nell'app, ed e' quella che si vende, come in TrashCan. La barra di
riempimento e' gratis perche' e' cio' che distingue l'app; il Pro vende l'**avviso**.

⚑ Lo storico e' Pro ma gli usciti si salvano sempre: chi compra il Pro trova gia' i dati di
prima, e le impostazioni senza Pro dicono "hai N uscite registrate".

☠ **Ogni chiave `locked()` compare fra i benefici del paywall e viceversa**: lo verifica
`test/widget/paywall_config_test.dart`. Un blocco senza beneficio e' una funzione a pagamento
che nessuno ha detto; un beneficio senza blocco promette una cosa che l'utente ha gia'
(trappola pagata in TrashCan con il widget).

Le funzioni aperte sono dichiarate comunque nella mappa: si legge a colpo d'occhio cosa NON e'
a pagamento, e l'assert di FeatureGate non scatta.

---

## 11. Configurazione e chiavi

| Chiave | Dove | Default | Significato |
|---|---|---|---|
| FF_DEMO | `--dart-define` | `false` | dati di esempio su database vuoto; **ignorato in release** |
| BILLING | `--dart-define` (letto da `MicroAppConfig.fromEnvironment`) | `fake` in debug, `store` in release | `fake` = gateway finto **senza Pro** (si vede il paywall); `play` accettato come grafia storica; una release con `fake` fallisce all'avvio (`assertUsableInRelease`) |
| MA_LICENSE_URL, MA_APP_SECRET | `--dart-define-from-file` | vuoti | server licenze; senza, `serverEnabled` falso (vedi atlante di TrashCan §9bis) |
| `appId` | `app_config.dart` | `full_freezer` | namespace delle preferenze, cartelle, log |
| `proSku` | `app_config.dart` | `fullfreezer_pro_lifetime` | **immutabile**: uno SKU pubblicato non si cancella ne' si riusa |
| `seedColor` / `fontFamily` | `app_config.dart` | `#0461E5` / PlusJakartaSans | |
| `applicationId` / `namespace` | `android/app/build.gradle.kts` | `com.smp.fullfreezer` | **immutabile** dopo il primo upload |
| `minSdk` / `targetSdk` | idem | 24 / quello di Flutter | desugaring attivo (richiesto da flutter_local_notifications) |
| `storeFile`, `storePassword`, `keyAlias`, `keyPassword` | `android/key.properties` (non versionato) | assenti | senza, la release si firma in debug e Play la rifiuta; keystore **PKCS12** |
| bundle iOS | `project.pbxproj` | `com.smp.fullfreezer` (+ `.FullFreezerWidget`) | |
| App Group | entitlements + `FreezerWidget.iosGroup` + `Chiavi.gruppo` | `group.com.smp.fullfreezer` | |
| `version` | `pubspec.yaml` | `1.0.0+1` | `appVersion` va tenuta uguale |

### Preferenze (SettingsStore, namespace `full_freezer`: chiave salvata `full_freezer.<chiave>`)

| Classe.costante | Chiave | Tipo | Chi la scrive / legge |
|---|---|---|---|
| `FreezerSettingKeys.selectedFreezer` | `selected_freezer` | int (assente = Tutti) | `SelectedFreezer` |
| `FreezerSettingKeys.lastFreezer` | `last_freezer` | int | foglio rapido, editor del freezer / `showQuickAdd` |
| `FreezerSettingKeys.lastCompartment` | `last_compartment` | int (assente = nessuno) | foglio rapido / `showQuickAdd` |
| `FreezerSettingKeys.lastUnit` | `last_unit` | String | foglio rapido / `showQuickAdd` |
| `NotificationSettingKeys.digestFrequency` | `digest_frequency` | String `weekly`\|`biweekly`\|`monthly` | `DigestFrequencyNotifier` / `FreezerScheduler.frequency` |
| `NotificationSettingKeys.pendingAlerts` | `pending_capacity_alerts` | List<String> (`PendingAlert.encode`) | `FreezerScheduler` |
| SettingKeys.onboardingDone (micro_core) | | bool | editor al primo avvio, ripristino, demo / router |
| SettingKeys.notificationsEnabled | | bool, **default false** | `NotificationsEnabled` / `FreezerScheduler.allowed` |
| SettingKeys.themeMode | | String | `ThemeModeNotifier` |
| SettingKeys.launchCount, SettingKeys.firstLaunchAt | | int, istante | `main` (per decidere quando chiedere una recensione) |
| SettingKeys.lastRescheduleAt | | istante | `FreezerScheduler.rescheduleAll` |

### Permessi

| Piattaforma | Permesso | Perche' |
|---|---|---|
| Android | `com.android.vending.BILLING` | acquisti; dichiarato a mano perche' Play guarda il bundle, non le dipendenze |
| Android | RECEIVE_BOOT_COMPLETED | riarmare notifiche e sveglia del widget dopo un riavvio |
| Android | RECORD_AUDIO + `<queries>` `android.speech.RecognitionService` | voce; senza la query, da Android 11 il riconoscitore di sistema "non esiste" |
| Android | (niente SCHEDULE_EXACT_ALARM, niente INTERNET, niente Bluetooth) | riepiloghi inesatti per scelta (ADR-009); la rete la usa il servizio di Google, non l'app |
| iOS | NSCameraUsageDescription, NSPhotoLibraryUsageDescription | foto |
| iOS | NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription | voce (senza, iOS chiude l'app al primo tocco sul microfono) |

I testi iOS stanno in inglese in `Info.plist` e in **`Runner/{en,it}.lproj/InfoPlist.strings`**
(aggiunti con `tool/aggiungi_infoplist_strings.rb`): senza, un iPhone italiano mostrava la
richiesta in inglese.

Receiver nel manifest: `.FullFreezerWidgetProvider` (exported, APPWIDGET_UPDATE),
HomeWidgetScheduledUpdateReceiver, ScheduledNotificationReceiver e
ScheduledNotificationBootReceiver di flutter_local_notifications (senza, la notifica si
pianifica senza errori e non arriva mai).

### Testi (l10n)

☠ **La sorgente dei testi e' `tool/testi.py`, non gli ARB.** Ogni chiave ha inglese e italiano
sulla stessa riga; lo script scrive `app_en.arb` (con i segnaposto tipizzati da TIPI) e
`app_it.arb`. Un ARB modificato a mano viene **sovrascritto** al giro dopo.

```
python tool/testi.py                    # dalla cartella dell'app: "249 chiavi scritte"
pwsh ../../tool/fl.ps1 gen-l10n         # rigenera lib/l10n/generated/
```

Il codice generato sta in `lib/l10n/generated/` (non si tocca): la classe astratta `L`
(`L.of(context)`, `L.delegate`) con le sottoclassi `LEn` e `LIt`, e la funzione
`lookupL(Locale)` per i testi scritti fuori da un widget (notifiche, widget di sistema, test).
`l10n.yaml`: `output-class: L`, `nullable-getter: false`, template `app_en.arb`,
`untranslated-messages-file: lib/l10n/untranslated.json`.

⚑ Una tabella sola: con due ARB scritti a mano, una chiave aggiunta a una lingua sola compila
lo stesso (gen_l10n ripiega sull'inglese) e l'app italiana mostra una frase inglese senza che
nessuno se ne accorga. Il template e' l'inglese per lo stesso motivo (ADR-011).

Virgolette: l'italiano usa le caporali «», l'inglese le tipografiche “ ”, **ovunque** (anche
`freezer_deleteTitle`, `categories_deleteTitle`, `search_noResults`). ☠ Il perche' pratico,
oltre alla correttezza tipografica: con una `"` dritta nel testo, il dump di uiautomator scrive
l'attributo `content-desc` fra apici singoli, e lo script di prova adb (una regex su
`content-desc="..."`) non trovava piu' il riquadro. Nessuna `"` dritta nei testi visibili.

Chiave aggiunta col `ProGate`: `pro_locked`. Chiavi aggiunte con F4.9 completa:
`notif_fullBodyOldest`, `notif_digestFull`, `notif_digestEmpty`.

### Comandi

Dalla cartella `apps/full_freezer`:

```
pwsh ../../tool/fl.ps1 test                                        # 140 test
pwsh ../../tool/fl.ps1 analyze
pwsh ../../tool/fl.ps1 gen-l10n
pwsh ../../tool/fl.ps1 run -d emulator-5554 --dart-define=FF_DEMO=true
pwsh ../../tool/fl.ps1 build apk --debug --dart-define=FF_DEMO=true
pwsh ../../tool/fl.ps1 pub run build_runner build                  # dopo una modifica a tables.dart (rigenera database.g.dart)
python tool/testi.py                                               # dopo una modifica ai testi
python tool/genera_icone.py                                        # dopo un cambio dell'icona originale
pwsh ../../tool/verify_atlas.ps1 -Project apps/full_freezer        # dalla radice del monorepo
```

☠ In `pubspec.yaml` l'analyzer di build_runner ha un tetto `<14.4.0`: con la 14.5 la
generazione di Drift muore con "The setter 'contextFeatures' isn't defined". Si toglie quando
la catena supporta la 14.5.

---

## 12. Catalogo dei test

**140 test** in `apps/full_freezer/` (il file del parser vocale ne genera 20 da una tabella).

| File | N. | Cosa dimostra |
|---|---|---|
| `test/data/freezer_repository_test.dart` | 22 | freezer nuovo con taratura 1 e `last_alert_level = empty`; accodamento e riordino; **capacita' ≤ 0 rifiutata dal CHECK**; **foreign key attive** (cancellare un freezer porta via gli alimenti); cancellare uno scomparto lascia gli alimenti nel freezer; il freezer dell'alimento e' **quello dello scomparto** anche se il chiamante sbaglia; scomparto inesistente = errore; il piu' vecchio per primo (a parita' l'inserito prima); filtro per freezer; `nameNorm` sempre aggiornato anche dopo `updateItem`; quantita' e ingombro positivi; consumato esce e resta con il movimento; annullare rimette dentro con la data originale e aggiunge `restored`; spostare registra da/a; duplicare copia tutto tranne data e foto; autocompletamento per frequenza anche fra gli usciti, senza accenti/maiuscole, prefisso vuoto e `%` non jolly; `watchAnyChange` a ogni scrittura; categorie personalizzate in ordine alfabetico; cancellarla lascia gli alimenti **senza categoria**, non con una chiave orfana; `custom:<id>` va e torna |
| `test/domain/aging_test.dart` | 8 | giorni di calendario (ora legale, anno bisestile), il giorno stesso vale 0, data futura 0; soglie fresh/watch/old; `overdueBy`; promemoria dell'alimento sopra quello della categoria; senza promemoria sempre fresh; **l'ordinamento guarda la data, non il livello** |
| `test/domain/capacity_test.dart` | 19 | modelli ordinati e chiavi uniche, litri delle schede; stima per ogni unita', pezzi per categoria, mai zero; 80% utile; freezer vuoto senza divisioni per zero; oltre il 100% → 100 e `full`; soglie esatte 85%/20%; la taratura moltiplica; 60/40 → 1,5; limiti 0,25–4; stima zero → 1; **due tarature non si moltiplicano**; isteresi: freezer nuovo non avvisa vuoto, pieno una volta sola, riarmo sotto 70%, vuoto dopo riempimento, riarmo sopra 40% |
| `test/domain/formats_test.dart` | 2 | decimali dei litri per fascia; numeri con virgola o punto |
| `test/domain/home_view_test.dart` | 10 | un alimento sta in una sezione sola; "Da usare prima" ha i `useSoonPreview` (4) piu' vecchi (`useSoon`) e il resto dietro "vedi tutti"; il piu' vecchio senza promemoria resta in "Tutto il resto" ma in cima; il filtro per freezer non toglie freezer da "Dove sono"; "Tutti" senza riempimento unico; riempimento con litri, capacita' e taratura; deduzione della categoria it/en, solo parole intere, null meglio che sbagliata, **ogni chiave del dizionario esiste** |
| `test/domain/item_photo_test.dart` | 2 | la miniatura sta in `images/thumbs/<bucket>/`; solo il primo `images/` cambia |
| `test/domain/search_test.dart` | 6 | "pure" trova "Purè"; maiuscole indifferenti; cerca nelle note senza accenti; tutte le parole in qualunque ordine; query vuota = niente; l'ordine ricevuto resta |
| `test/domain/stats_test.dart` | 6 | conteggio nel periodo; "sempre" vs 30 giorni; permanenza media in giorni di calendario; categoria piu' buttata con conteggio; **sempre sei mesi**, dal piu' vecchio; nessuna uscita senza divisioni per zero |
| `test/domain/text_norm_test.dart` | 6 | `normalizeName` (accenti, spazi, apostrofo tipografico); chiavi di categoria uniche e ritrovabili; promemoria del piano F4.2; unita' note e ripiego |
| `test/domain/voice_parser_test.dart` | 22 | **20 frasi reali** it/en (numeri in lettere e cifre, "mezzo chilo", "un chilo e mezzo", "due etti" = 200 g, "d'agnello", "half a kilo", "a kilo and a half", "ice cream" senza categoria); quantita' senza nome → frase intera nel nome con confidenza 0; confidenza 1 / 0,8 / 0,5 |
| `test/services/backup_csv_test.dart` | 3 | "sostituisci tutto" riporta freezer, scomparti, alimenti, **storico**, foto, e **rimappa `custom:<id>`** quando gli id si spostano (payload passato da JSON come nel file vero); "aggiungi" salta i freezer omonimi; CSV con una riga per alimento, giorni, freezer, scomparto, `;` nella nota senza spezzare la colonna |
| `test/services/freezer_widget_test.dart` | 5 | i tre piu' vecchi con **data e non giorni**; promemoria dell'alimento sopra la categoria, vuoto senza nessuno, icona `other` di ripiego; icona della categoria personalizzata e a capo nel nome; modello dei giorni "{n} gg" / "{n} d"; le icone escono PNG |
| `test/services/notification_plan_test.dart` | 14 | date del riepilogo (oggi compreso se domenica; 14 e 28 giorni); **il riepilogo conta chi sara' vecchio quel giorno, con i giorni di quel giorno**; chi invecchia entra nei successivi; il piu' vecchio e' quello con piu' giorni; niente di vecchio → niente riepilogo; quasi pieno subito; quasi vuoto il sabato alle 10 (anche sabato alle 9 e alle 11); `PendingAlert` codifica/decodifica con id stabile; `evaluateCapacity` con Pro mette in coda "quasi pieno", **senza Pro nessun avviso ma isteresi aggiornata**, freezer nuovo non manda "quasi vuoto"; **"quasi pieno" cita il piu' vecchio del freezer** (`capacityAlertBody`); **il riepilogo aggiunge una riga per i freezer pieni o quasi vuoti, non per quelli vuoti** (`digestCapacityLines`) |
| `test/widget/app_smoke_test.dart` | 6 | primo avvio in italiano con il nome proposto; **in tedesco ripiega sull'inglese**; home con il piu' vecchio in "Da usare prima", etichette maiuscole, bollino, percentuale e litri in testata, ordine giusto; home vuota; tema dal blu dell'icona e dal font; l'inglese e' il primo delle lingue |
| `test/widget/paywall_config_test.dart` | 6 | **ogni blocco e' nel paywall e il paywall non promette altro**; ogni chiave dichiarata; un freezer si', il secondo no (con Pro si'); foto, scomparti e widget gratis; notifiche, storico, statistiche, CSV, backup e categorie Pro |
| `test/widget/quick_add_test.dart` | 3 | **il vincolo dell'app misurato**: "+", nome, Salva = 3 interazioni; con un suggerimento = 4; **senza Pro le pagine Pro aperte con un `push` diretto** (`/stats`, `/history`, `/categories`, `/freezers/new`) **mostrano il lucchetto** di `ProGate`. Repository finto (`_RepoFinto`); piano gratuito con override di `isProProvider` e `featureGateProvider` (`freezerFeatureLimits`, `isPro: false`) |

`integration_test/flusso_test.dart` (1 test, sul dispositivo:
`flutter test integration_test/flusso_test.dart -d <device>`): primo avvio con il modello,
inserimento rapido **contando i tocchi** (fallisce se ≥ 4), un secondo alimento, home, pagina
del freezer; stampa `SCATTO:<nome>` dove fotografare. Usa `lookupL` e `localesTestValue`,
quindi gira in qualunque lingua. ☠ `pumpAndSettle` **non aspetta il database**: si aspetta la
schermata attesa fotogramma per fotogramma (`aspetta`). ☠ `ensureVisible` e non
`scrollUntilVisible`: il pulsante e' gia' costruito appena sotto il bordo, il finder lo trova, e
il tocco cade fuori dallo schermo. **Non affidabile sull'emulatore** (§14).

⚑ **Niente database vero nei widget test**: `testWidgets` gira in FakeAsync, che congela l'I/O
di SQLite, e il test resta appeso (trappola di TrashCan). Si sostituiscono i provider con
`Stream.value(...)` e `notificationSyncProvider` con un provider vuoto; che i dati siano
calcolati bene lo dimostrano i test del repository e di `buildHomeView`.

⚑ **Niente golden**: i caratteri cambiano fra Windows e Mac, e un golden instabile si impara a
ignorarlo. L'aspetto lo verificano gli scatti sull'emulatore e l'anteprima del widget iOS.

---

## 13. Trappole gia' disinnescate e regole

Ognuna e' costata tempo almeno una volta. Sono qui perche' il sintomo non nomina mai la causa.

| Sintomo | Causa | Dove |
|---|---|---|
| Cancello un freezer e il riempimento conta ancora i suoi alimenti | SQLite tiene `foreign_keys` spento: i cascade sono decorativi | `database.dart`, `PRAGMA foreign_keys = ON` in `beforeOpen` |
| "unable to open database file" su VACUUM, solo su telefono | la cartella temporanea di sistema non e' scrivibile | `database.dart`, `sqlite3.tempDirectory` |
| Cerco "pure" e non trovo "Purè" | SQLite senza ICU non ignora gli accenti | colonna `name_norm` + `normalizeName` |
| Un alimento finisce nella categoria di un'altra | `category` e' testo, non FK; SQLite puo' riusare l'id | `deleteCustomCategory` azzera la categoria degli alimenti |
| Dopo un ripristino un alimento ha la categoria sbagliata | gli id di `custom_categories` cambiano fra telefoni | `importPayload`, `categoryMap` vecchio → nuovo |
| La barra impazzisce dopo due tarature | la seconda taratura partiva dalla stima gia' tarata | `calibrate` riceve `rawFraction` |
| "Quasi pieno" ogni giorno | soglia attraversata avanti e indietro | `CapacityAlertPolicy` con isteresi 70% / 40% |
| Accendo gli avvisi e arriva subito un "quasi pieno" vecchio | l'isteresi si aggiornava solo con le notifiche attive | `evaluateCapacity` scrive `lastAlertLevel` sempre |
| Freezer nuovo e vuoto riceve "quasi vuoto" | `last_alert_level` partiva da null | default `'empty'` nella tabella |
| Una pagina Pro aperta da un `push` diretto si vede gratis | il Pro si controllava solo nelle porte d'ingresso | `ProGate` sulla pagina |
| Pagina d'errore di go_router aprendo una pagina Pro | un `redirect` a "/" su un `push` mette "/" due volte nella pila | niente redirect: `ProGate` |
| Lo script adb non trova un riquadro con un titolo fra virgolette | con `"` nel testo uiautomator scrive `content-desc` fra apici singoli | virgolette tipografiche in tutti i testi |
| Spostare un alimento dalla sua pagina non lascia traccia | `updateItem` non scrive movimenti | `ItemEditPage._save` chiama prima `moveItem` |
| Il "quasi vuoto" di sabato sparisce | `replaceSchedule` cancella cio' che non e' nel piano | coda `pending_capacity_alerts` rimessa a ogni ripianificazione |
| Il riepilogo fra tre settimane dice i giorni di oggi | il testo si fissa quando si pianifica | `digestFor(stored, giornoDiConsegna)` |
| Dopo un rimborso le notifiche continuano | il Pro si controllava solo nella UI | `FreezerScheduler.allowed` |
| L'interruttore degli avvisi e' acceso ma nessun permesso; il primo tocco lo spegne | default acceso copiato da TrashCan | `NotificationsEnabled` default **false**, permesso chiesto accendendo |
| La notifica non arriva mai, nessun errore | mancano i receiver di flutter_local_notifications | manifest |
| Icona della barra di stato = macchia bianca | Android usa solo l'alfa; il logo e' opaco | `drawable/ic_notification.xml` disegnato a mano |
| Tocco la notifica e il back esce dall'app | `go` sostituisce la pila | `_openPayload`: `go(home)` poi `push` |
| Tocco il widget: "Da usare prima" senza freccia, o da chiusa la home | il deep link di Flutter passava l'URI a go_router con `go` | deep link spento in manifest e Info.plist |
| Tocco il widget con l'app nei recenti: si apre la home | Android consegna l'intent nuovo con `onNewIntent`, prima dello stream; il plugin rilegge il vecchio | `MainActivity.onNewIntent` → `setIntent` |
| Aperta dal widget a freddo, la navigazione si perde | `go` in `initState` sovrascritto dalla posizione iniziale | `initiallyLaunchedFromHomeWidget` dopo il primo frame |
| Tocco sul widget iOS ignorato | il plugin riconosce i tocchi dal parametro `homeWidget` | `widgetURL(...?homeWidget)` |
| Widget fermo ai giorni di ieri | manca HomeWidgetScheduledUpdateReceiver; e Dart gira solo con l'app aperta | receiver nel manifest; **i giorni li calcola il widget** (ADR-018) |
| Widget mezzo vuoto, "non ha caricato" | righe in `wrap_content` ammassate in alto | righe a peso 1 (Android), `maxHeight: .infinity` (iOS) |
| "Full Freezer continua a bloccarsi" | un'eccezione nel receiver del widget fa cadere il processo | `onUpdate` dentro `try` |
| Widget che non si disegna, senza errori | view non ammesse da RemoteViews | solo LinearLayout/TextView/ImageView |
| Widget iOS vuoto, nessun errore | App Group non registrato: contenitore nullo | registrare il gruppo; testi di riserva in Ripiego |
| Fondo del widget iOS staccato dai bordi | margini di sistema da iOS 17 | `contentMarginsDisabled`, `containerBackground` |
| Campi del widget sfasati | un separatore che una tastiera puo' produrre | US `\u001F`; a capo nel nome → spazio |
| Due schede affiancate di larghezze diverse | Dismissible allenta i vincoli nel suo Stack | `SizedBox(width: double.infinity)` |
| Carne disegnata come uno spiedino | Material non ha una bistecca | icone disegnate in `category_glyphs.dart` |
| Il blu dell'app e' un blu ardesia, non quello dell'icona | lo schema Material "tonalSpot" desatura il seme | `DynamicSchemeVariant.fidelity` |
| "0,3 L" per la misura "piccolo" (0,25) | un solo decimale sotto il litro | `formatLiters`: 2 decimali sotto 1 L |
| Secondo freezer proposto come "Freezer cucina" | nome fisso | `freezer_defaultNameN` dal secondo |
| Foto orfane che fanno crescere lo spazio | foto scattate e mai salvate, e copie nella cache di image_picker | pulizia in `QuickAddSheet`/`ItemEditPage`, cancellazione della copia in `/cache/` |
| Un widget test resta appeso | FakeAsync congela l'I/O di SQLite | provider sostituiti con stream finti |
| Il test d'integrazione fallisce subito dopo "Salva" | `pumpAndSettle` non aspetta il database | `aspetta(finder)` fotogramma per fotogramma |
| Il tocco del test cade fuori schermo | `scrollUntilVisible` non scorre su un widget gia' costruito | `ensureVisible` |
| Generazione Drift: "contextFeatures isn't defined" | analyzer 14.5 | tetto `<14.4.0` in `pubspec.yaml` |
| Build: "requires core library desugaring" | flutter_local_notifications su minSdk 24 | `isCoreLibraryDesugaringEnabled = true` |
| "Activity class does not exist" | plugin Kotlin mancante nel template | `id("org.jetbrains.kotlin.android")` in `build.gradle.kts` |
| Icona iOS rifiutata a caricamento finito | canale alfa | icona fullbleed opaca + `remove_alpha_ios` |
| Splash Android 12 con il disegno tagliato | ritaglio a cerchio dei due terzi centrali | `splash_android12.png` |
| Fiocco "svuotato" nella splash | ritaglio automatico del disegno | ritaglio a mano del proprietario |

### Regole non negoziabili

1. **Tutte le letture e scritture passano da `FreezerRepository`.** Le tre regole (freezer
   coerente, `nameNorm`, movimenti) non hanno un vincolo SQL che le difenda.
2. **Le date di congelamento sono CivilDate/TEXT `YYYY-MM-DD`**, mai DateTime: un alimento
   "congelato il 3 marzo" non ha fuso orario. Gli istanti sono ms UTC.
3. **Nessuna pagina scrive `if (isPro)`**: si passa da `featureGateProvider` e da
   `freezerFeatureLimits` (ADR-017). Il controllo delle notifiche sta anche nel pianificatore.
4. **Ogni `locked()` ha il suo beneficio nel paywall e viceversa** (test).
5. **Le chiavi stabili non si rinominano**: categorie, modelli di freezer, unita', `status`,
   `kind`, chiavi del widget, preferenze. Sono nel database, nei backup e nelle preferenze degli
   utenti.
6. **Le chiavi del widget cambiano in tre file insieme**: `freezer_widget.dart`,
   `FullFreezerWidgetProvider.kt`, `VistaFreezer.swift`. Il gruppo iOS in quattro (piu' i due
   `.entitlements`).
7. **Il payload del widget non contiene giorni**, solo date (ADR-018).
8. **I testi si cambiano in `tool/testi.py`**, mai negli ARB.
9. **Le icone si cambiano dall'originale con `tool/genera_icone.py`**, mai nelle risorse
   generate.
10. **Il promemoria e' un promemoria, non una scadenza**: nessun testo puo' implicare sicurezza
    alimentare.
11. **`applicationId`, bundle id, App Group e `proSku` sono immutabili** dopo il primo upload;
    `android/key.properties` e il keystore non entrano mai nel repository.
12. **Mai `Platform.isX`**: `defaultTargetPlatform` (si puo' simulare nei test).
13. **Una modifica allo schema** incrementa `schemaVersion`, aggiunge il passo in
    `onUpgrade` **e** il suo test, prima di uscire.

---

## 14. Cosa NON esiste ancora, e debito aperto

### Non esiste (per non cercarlo invano)

- **Nessuna prova su telefono vero**: tocco sul widget iOS (il simulatore headless chiede
  conferma a `simctl openurl`), voce vera (all'emulatore non si puo' parlare), acquisti,
  notifiche su iPhone.
- **Nessun App ID, App Group o prodotto Pro registrato sugli store**: `group.com.smp.fullfreezer`,
  l'App ID dell'estensione e `fullfreezer_pro_lifetime` vanno creati dal proprietario sul
  portale Apple, in App Store Connect e in Play Console (F4.17). Finche' non ci sono, il Pro
  non e' comprabile e il widget iOS firmato scrive in un contenitore nullo.
- **Nessuna build TestFlight / Play** di Full Freezer, nessuna scheda store, nessuno
  screenshot da test (F4.17).
- **Nessuna azione "sposta" separata**: si sposta cambiando la posizione nella pagina
  dell'alimento (che chiama `moveItem`).
- **Nessuna schermata legge `item_movements`**.
- **Nessun redirect Pro in go_router**, di proposito: il controllo sta sulla pagina
  (`ProGate`, §7).
- **Nessun valore economico dello spreco** nelle statistiche (il piano lo prevedeva come
  opzionale): il modello non ha prezzi.
- **Nessun file `lib/services/capacity_alerts.dart`**: la logica sta in `CapacityAlertPolicy`
  e in `FreezerScheduler` (§14, differenze).
- **Nessun barcode, nessun inserimento a lotti** (post-MVP).
- **Nessun golden test** (scelta, §12) e **nessun test di migrazione** (schema 1).
- **Nessuna verifica del Pro sul server dalla build iOS**: il ripristino su iOS passa
  dall'ID Apple, senza codice di trasferimento.

### Debito tecnico

| Voce | Perche' e' rimandato | Quando va affrontato |
|---|---|---|
| **`EntitlementView`/`EntitlementNotifier` copiati da TrashCan** in `lib/app/entitlement.dart` | due copie sono sopportabili | **alla terza app (Scorte Calore, F5)**: spostarli in `micro_core` insieme, o la prossima correzione al flusso d'acquisto (come la rotellina eterna del 2026-10-06) andra' fatta tre volte |
| **Test d'integrazione non affidabile sull'emulatore** | `flusso_test.dart` resta sulla splash: la connessione PC-emulatore con la VM si appende (problema dell'ambiente, non dell'app; il giro manuale via adb funziona). Il vincolo dei tocchi e' coperto da `quick_add_test.dart` | quando cambia la toolchain o con un dispositivo fisico |
| **Tocco del widget iOS e voce vera da provare su telefono** | serve un iPhone in mano, e per la voce un telefono qualunque | prima di F4.17 / TestFlight |
| **App ID, App Group, prodotto Pro da registrare sugli store** | richiedono gli account del proprietario | F4.17, prima della prima build firmata |
| **Flaky test di entitlement in `micro_core`** | un test di `micro_core/test/entitlement` fallisce ogni tanto e passa al giro dopo; non e' di quest'app | alla prossima sessione su `micro_core` |
| **Copia del codice sul Mac non-git** | sincronizzazione a mano con tar | se il lavoro iOS diventa frequente: un clone vero sul Mac |
| **Informativa privacy del sito** | deve dire che il riconoscimento vocale lo fa il servizio del telefono (Google/Apple), che puo' usare i loro server | prima della pubblicazione |

### Differenze consapevoli dal piano (`develop_microapps.md` F4)

Il codice ha la precedenza; il piano e' la storia delle intenzioni.

| Il piano diceva | Il codice fa | Perche' |
|---|---|---|
| "Da usare prima": massimo 5 | `useSoonPreview = 4` | schede a due colonne: con cinque l'ultima resta sola (interfaccia Ghiaccio) |
| `lib/features/locations/`, `lib/features/stats/` | `features/freezers/`, `features/history/` | |
| `lib/services/capacity_alerts.dart` | `CapacityAlertPolicy` in `domain/capacity.dart` + `FreezerScheduler.evaluateCapacity` / `capacityAlertBody` / `digestCapacityLines` | scelta consapevole: la regola e' pura, la consegna e i testi stanno col pianificatore |
| ricerca LIKE con debounce 200 ms | filtro in memoria | §4 `search.dart` |
| `fl_chart` per le statistiche | grafico disegnato a mano | §9 |
| valore indicativo dello spreco | non calcolato | il modello non ha prezzi |
| indice `idx_items_name` | `idx_items_name_norm` | si cerca sulla colonna normalizzata |
| `kind` senza `restored` | anche `restored` | annullare un'uscita senza riscrivere lo storico |
| il test d'integrazione misura i tocchi (F4.13) | lo misura un widget test (`quick_add_test.dart`) | l'integrazione resta, ma non e' affidabile sull'emulatore |
| "Ne ho congelato un altro uguale" dal menu di una riga | pressione lunga sulla riga, e voce di menu nella pagina dell'alimento | |

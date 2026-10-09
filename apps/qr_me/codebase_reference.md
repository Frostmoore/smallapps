# codebase_reference.md — QR Me

> Atlante dell'app **QR Me**: condividi qualunque cosa da un'altra app e diventa un QR a tutto
> schermo, luminoso; e l'app sa anche **leggere** i QR (fotocamera o immagine) e rigenerarli con
> il suo stile (colori, forme, logo). Gesto principale: **Condividi → QR Me → il QR e' gia' li'**.
> **Obiettivo**: capire il codice, trovare cio' che serve e modificarlo **senza aprire i file**.
>
> **Aggiornato al**: 2026-10-09 · **Fase**: F17.0–F17.7 (parte Android) concluse, questo atlante e'
> F17.8 · **Ramo git al momento della scrittura**: `v8.6.0`, commit `7a48532` (F17.7) ·
> **versionName+Code**: `1.0.0+1` · **Test**: **155 verdi** (152 + 3 di ZXing), `analyze` senza issue (2026-10-09)
> **Package Android / bundle iOS**: `com.smp.qrme` (immutabile dopo il primo upload) ·
> estensione iOS `com.smp.qrme.ShareExtension` · App Group `group.com.smp.qrme`
> **SKU Pro**: `qrme_pro_lifetime` — **1,99 €** una tantum (Play: base **1,63 EUR senza IVA**)
> **Id per il License Server**: `licenseAppId = 'qrme'` (senza trattino basso, ≠ `appId = 'qr_me'`)
> **Grafica**: «A · Neon», scelta dal proprietario il 2026-10-09
> (https://claude.ai/artifact/PnrsKsGFRmFsppGHBxBrHk): fondo quasi nero `#0E1110`, verde neon
> `#3BD13B` con alone, titoli **Space Grotesk**, corpo **Plus Jakarta Sans**, QR sempre su pannello
> **bianco**. **Tema scuro di default.**
>
> ⚠ **Lettore dei QR: ZXing al posto di ML Kit (2026-10-09).** Il proprietario ha fissato la
> regola **«dati solo sul telefono»** (`memory/decisioni.md`, voce «Dati solo sul telefono: nessun
> SDK che manda dati a terzi», **non negoziabile**): `mobile_scanner` (ML Kit di Google su Android,
> metriche d'uso e id d'installazione non disattivabili) **e' stato sostituito da `flutter_zxing`**
> (ZXing C++ via FFI dentro l'app, fotocamera dal plugin `camera`) su entrambe le piattaforme.
> La sostituzione e' **chiusa** il 2026-10-09 (F17.7.7 del piano): lettore da file
> (`ZxingImageReader`), provider, pagina di scansione su `ReaderWidget`, manifest, dipendenze e tre
> test; `analyze` pulito, 155 test verdi, APK di debug compilato e provato sull'emulatore (pagina di
> lettura, permesso negato, «Da immagine», condivisione da Google Foto, «Leggibile» nello Stile).
> Verificato: nessuna dipendenza ML Kit risolta e nessun servizio ML Kit nel manifest. ⚠ Restano i
> servizi `datatransport` di **Play Billing** (§14, debito). **Non e' una scelta aperta**: tornare a
> ML Kit richiede una nuova decisione scritta del proprietario.
>
> Quello che l'app prende da `micro_core` (configurazione, preferenze, acquisti, paywall, backup,
> immagini, componenti UI) **non e' ricopiato qui**: `packages/micro_core/codebase_reference.md`.
> La ricezione da Share Sheet (`SharedPayload`, `ShareInbox`, `RsiShareInbox`, lo script Ruby
> dell'estensione iOS, il modello `ios_template/`) sta in `packages/micro_share/codebase_reference.md`.
> I nomi dei tipi di `micro_core`, `micro_share`, Flutter, Drift, dei plugin e delle classi generate
> da Drift (la riga QrCode, il companion QrCodesCompanion) compaiono qui in testo semplice o dentro
> le firme, mai da soli fra apici inversi: cosi' `tool/verify_atlas.ps1` segnala solo i nomi **di
> quest'app** che non esistono piu'.
>
> Convenzioni: ⚑ = scelta non ovvia, con il suo perche'. ☠ = trappola gia' pagata.
> **[SCANNER]** = parte cambiata con il passaggio a ZXing (chiuso il 2026-10-09).

---

## 0. Le decisioni che reggono tutto (F17.0, 2026-10-09)

Prese con il proprietario prima di scrivere codice (`develop_microapps.md` §8 «F17 — QR Me», F17.0;
registro `memory/decisioni.md`, voci «F17 "Fammi un QR" diventa "QR Me"», «QR Me: grafica A ·
Neon», «QR Me: ML Kit» (chiusa: tolto) e «Dati solo sul telefono»). **Dove contraddicono il resto
del piano, vincono queste.**

| # | Decisione | Dove si vede nel codice | Perche' |
|---|---|---|---|
| 1 | Nome «QR Me» in it ed en; `com.smp.qrme`, `appId 'qr_me'`, `licenseAppId 'qrme'`, SKU `qrme_pro_lifetime`. Se il nome della scheda e' preso: «QR Me – Share & Scan» / «QR Me – Condividi e leggi» (sotto l'icona resta «QR Me») | `app_config.dart`, `build.gradle.kts`, `project.pbxproj`, `Info.plist` | sostituisce «Fammi un QR» |
| 2 | Android e iPhone dal primo commit, **solo iPhone** (`TARGETED_DEVICE_FAMILY = 1`), **App Group** `group.com.smp.qrme` | `project.pbxproj`, `*.entitlements` | l'estensione di condivisione iOS scrive nell'App Group |
| 3 | Contenuti: testo e link + moduli **Wi-Fi, contatto (vCard), email, SMS, telefono** | `QrKind`, `lib/features/forms/` | |
| 4 | **Legge i QR** (fotocamera e immagine) e li rigenera con lo stile; **lettura gratis** | `ScanPage`, `ScanResultPage`, `qrFeatureLimits` | |
| 5 | Stile: colori, forma moduli/occhi, **logo da foto, icona pronta o emoji/testo (1–3 grafemi)** | `QrStyle`, `QrLogo`, `LogoPicker` | |
| 6 | «Base generosa», Pro **1,99 €**: cronologia 5 gratis, **1 preferito** gratis; Pro moduli, stile, preferiti e cronologia illimitati, PNG, backup | `qrFeatureLimits`, `buildQrPaywall` | ⚑ 1 preferito e non 0: fa capire a cosa servono (il Wi-Fi di casa) |
| 7 | Cronologia **accesa di default e spegnibile**, con «Cancella» | `HistoryEnabledNotifier`, `SettingsPage` | dentro ci finiscono password Wi-Fi e testi privati |
| 8 | **Nessun widget** (niente `home_widget`) | (assenza) | |
| 9 | Icona dal proprietario, ripulita da `tool/genera_icone.py`; seme `#3BD13B` | §2bis | |
| 10 | Prima interfaccia essenziale, poi la grafica fra tre (**A · Neon**, scelta) | `qr_palette.dart`, `neon.dart` | applicata gia' in F17.4, F17.6 chiusa con F17.4 |
| 11 | Trappole gia' pagate: `licenseAppId` senza `_`, deep link di Flutter **spento**, `ProGate` sulle rotte Pro, virgolette tipografiche, `Runner.entitlements` presente (qui serve) | §7, §13 | |
| 12 | **Dati solo sul telefono** (2026-10-09, regola di tutte le microapp): nessun SDK che manda dati a terzi, nemmeno metriche anonime → **ML Kit sostituito da ZXing** | `pubspec.yaml` (`flutter_zxing`, `camera`), `ZxingImageReader`, `scan_page.dart`, manifest | requisito delle MicroApps; cambiarlo serve un motivo «importantissimo» scritto dal proprietario |

Le decisioni tecniche della specsheet (F17.1) sono nelle sezioni che seguono, ognuna con il suo ⚑.

---

## 1. Dove sta cosa

| Cerchi… | Vai in… |
|---|---|
| L'avvio (config, cartelle, log, preferenze, conteggio avvii) | `lib/main.dart` |
| Router, tema, ascolto delle condivisioni, pulizia dei loghi orfani, messaggi della condivisione | `lib/app/app.dart` |
| I percorsi, gli argomenti delle pagine (`QrDisplayArgs`, `ScanResultArgs`, `StyleArgs`), i tipi con modulo | `lib/app/routes.dart` |
| Id app, SKU, seme, font, `licenseAppId` | `lib/app/app_config.dart` |
| Tutti i provider (config, database, repository, stream, servizi, logo, galleria, backup, cronologia accesa, tema) | `lib/app/providers.dart` |
| Il Pro: gateway, entitlement, `featureGateProvider`, `appVersion` | `lib/app/entitlement.dart` |
| Cosa e' gratis e cosa e' Pro | `lib/app/feature_limits.dart` |
| Testi e benefici del paywall, `showQrPaywall` | `lib/app/paywall_config.dart` |
| I colori «A · Neon» e il tema Material vestito | `lib/app/qr_palette.dart` |
| Nome e icona dei tipi, contenuto in chiaro, password mascherata, riga meta | `lib/app/labels.dart` |
| Italiano sui telefoni italiani, inglese altrove | `lib/app/locale_resolution.dart` |
| **Cosa c'e' in un QR** (tipi, uguaglianza, campi, titolo automatico) | `lib/domain/qr_content.dart` |
| **Contenuto → stringa del QR** (Wi-Fi, vCard 3.0, mailto, SMSTO, tel) | `lib/domain/qr_encoder.dart` |
| **Stringa letta → contenuto** (anche MECARD, MATMSG, sms:, vCard 4.0) | `lib/domain/qr_decoder.dart` |
| Quanti byte stanno in un QR, scelta del livello M/H/L | `lib/domain/qr_capacity.dart` |
| Stile e logo, JSON tollerante, id stabili delle icone | `lib/domain/qr_style.dart` |
| Contrasto WCAG e verso dei colori | `lib/domain/contrast.dart` |
| La tabella `qr_codes`, `QrSource`, `qrKindKeys` | `lib/data/tables.dart` |
| Apertura del database, conversioni riga → dominio | `lib/data/database.dart` |
| **Tutte** le letture e scritture (cronologia, preferiti, potatura, loghi orfani) | `lib/data/qr_repository.dart` |
| Backup e ripristino con i loghi foto | `lib/data/qr_backup_source.dart` |
| Il QR disegnato (widget e PNG con gli stessi parametri) | `lib/services/qr_renderer.dart` |
| Il logo come immagine (piatto, icona, testo, foto), import della foto | `lib/services/logo_renderer.dart` |
| Lettura di QR da file, verifica di leggibilita' **[SCANNER]** | `lib/services/readability_check.dart` |
| Luminosita' al massimo e schermo acceso | `lib/services/screen_boost.dart` |
| Condivisione → rotta giusta, doppioni entro 2 s, avvio dell'ascolto | `lib/services/share_router.dart` |
| Apri link / chiama / email / SMS (url_launcher) | `lib/services/content_actions.dart` |
| La home: scrivi/incolla, leggi, moduli, preferiti, recenti | `lib/features/home/home_page.dart` |
| **IL QR a tutto schermo** e le sue azioni | `lib/features/display/qr_display_page.dart` |
| Azioni condivise con il loro controllo Pro (salva, stile, PNG, moduli, copia, apri, cronologia) | `lib/features/common/qr_actions.dart` |
| Mattoni grafici Neon (pulsante, etichetta, pannello, miniatura, riga, tessera azione) | `lib/features/common/neon.dart` |
| Il lucchetto delle pagine Pro aperte senza Pro | `lib/features/common/pro_gate.dart` |
| La fotocamera, la torcia, «Da immagine» **[SCANNER]** | `lib/features/scan/scan_page.dart` |
| Cosa c'era nel QR letto, con le azioni del tipo | `lib/features/scan/scan_result_page.dart` |
| I moduli speciali (una pagina, cinque moduli) | `lib/features/forms/form_page.dart` + `wifi_form.dart`, `contact_form.dart`, `email_form.dart`, `sms_form.dart`, `phone_form.dart` |
| Validatori e campo di testo dei moduli | `lib/features/forms/form_fields.dart` |
| Lo stile (colori, forme, logo, avvisi, verifica) | `lib/features/style/style_page.dart` |
| Il selettore del logo e il catalogo delle icone `kLogoIcons` | `lib/features/style/logo_picker.dart` |
| Preferiti | `lib/features/saved/saved_page.dart` |
| Cronologia | `lib/features/history/history_page.dart` |
| Impostazioni (cronologia, Pro, dati, tema, privacy, info) | `lib/features/settings/settings_page.dart` |
| Backup e ripristino (azioni) | `lib/features/settings/data_section.dart` |
| Manifest: intent SEND, `allowBackup=false`, deep link spento, `<queries>` | `android/app/src/main/AndroidManifest.xml` |
| `onNewIntent` → `setIntent` | `android/app/src/main/kotlin/com/smp/qrme/MainActivity.kt` |
| **`finalizeDsl { compileSdk = 36 }`** per `receive_sharing_intent` | `android/build.gradle.kts` |
| Firma, minify, desugaring | `android/app/build.gradle.kts` |
| Esclusione dal backup iCloud di `Documents/` | `ios/Runner/AppDelegate.swift` |
| Schema `ShareMedia-…`, `AppGroupId`, deep link spento, permessi | `ios/Runner/Info.plist` (+ `ios/Runner/{it,en}.lproj/InfoPlist.strings`) |
| L'estensione di condivisione iOS | `ios/ShareExtension/` (copiata da `packages/micro_share/ios_template/` dallo script) |
| Le stringhe tradotte | **`tool/testi.py` + `tool/testi_*.py`** (sorgente unica) → `lib/l10n/app_en.arb`, `app_it.arb` |
| Icona e splash | `tool/genera_icone.py` + `flutter_launcher_icons.yaml`, `flutter_native_splash.yaml` |
| Caratteri e licenze | `assets/fonts/` (Plus Jakarta Sans e Space Grotesk variabili, `OFL-*.txt`) |
| I doppi finti dei test di widget | `test/widget/qr_test_harness.dart` |

---

## 2. Albero dei file

Solo codice e configurazione scritti o toccati da noi (esclusi `lib/l10n/generated/`,
`lib/data/database.g.dart`, `GeneratedPluginRegistrant.*`, i file generati da Flutter/Xcode/Gradle,
`android/key.properties` — non versionato — e le immagini).

```
apps/qr_me/
├── lib/
│   ├── main.dart                         avvio: config, assertUsableInRelease, AppPaths, MicroLog, SettingsStore, avvii. Niente database.
│   ├── app/
│   │   ├── app.dart                      buildRouter(), formKindOf, QrMeApp (router, tema Neon, ShareIntake, pruneOrphanLogos dopo 3 s)
│   │   ├── app_config.dart               licenseAppId, buildQrConfig(): qr_me, «QR Me», qrme_pro_lifetime, #3BD13B, PlusJakartaSans, scuro
│   │   ├── entitlement.dart              appVersion, installIdProvider, purchaseGatewayProvider (finto a 1,99 €), EntitlementView/Notifier, isProProvider, featureGateProvider
│   │   ├── feature_limits.dart           qrFeatureLimits (tutte le 15 FeatureKey)
│   │   ├── labels.dart                   kindName, kindIcon, plainText, kMaskedPassword, rowMeta
│   │   ├── locale_resolution.dart        kSupportedLocales, resolveAppLocale
│   │   ├── paywall_config.dart           buildQrPaywall (6 benefici), showQrPaywall
│   │   ├── providers.dart                provider radice, QrSettingKeys, ThemeModeNotifier, HistoryEnabledNotifier, stream, servizi, PickImage, LogoKey, kLogoPixels, logoImageProvider, logoKeyOf
│   │   ├── qr_palette.dart               kTitleFont, QrPalette (ThemeExtension, dark/light), withQrLook (cambia anche il ColorScheme)
│   │   └── routes.dart                   Routes, kFormKinds, QrDisplayArgs, ScanResultArgs, StyleArgs
│   ├── data/
│   │   ├── tables.dart                   qrKindKeys, QrSource, QrCodes (la sola tabella)
│   │   ├── database.dart                 QrDatabase (schema 1) + estensione QrCodeToDomain; riesporta QrSource, qrKindKeys
│   │   ├── database.g.dart               GENERATO da drift_dev
│   │   ├── qr_repository.dart            QrLogoFiles, QrRepository (la sola porta sul database)
│   │   └── qr_backup_source.dart         QrBackupSource (BackupSource di micro_core, con i loghi)
│   ├── domain/                           Dart puro: niente Flutter, niente Drift, niente stringhe dell'app
│   │   ├── qr_content.dart               QrKind, WifiSecurity, normalizePhone, QrContent + 7 sottoclassi
│   │   ├── qr_encoder.dart               QrEncoder (encode, wifiEscape, vcardEscape)
│   │   ├── qr_decoder.dart               QrDecoder (decode, decodeTyped)
│   │   ├── qr_capacity.dart              QrErrorLevel, QrCapacity, QrLevelChoice
│   │   ├── qr_style.dart                 QrModuleShape, QrEyeShape, kLogoIconIds, QrLogo + 4 sottoclassi, QrStyle
│   │   └── contrast.dart                 Contrast (ratio WCAG, inverted)
│   ├── services/
│   │   ├── qr_renderer.dart              QrRenderer (widget, png, painter: UN solo traduttore stile → qr_flutter)
│   │   ├── logo_renderer.dart            LogoRenderer (render con piatto, importPhoto quadrata 512 px)
│   │   ├── readability_check.dart        QrReaderUnavailable, QrImageReader, ZxingImageReader (normale / strict), Readability, ReadabilityCheck
│   │   ├── screen_boost.dart             ScreenBoost (luminosita' dell'app + wakelock, errori ingoiati)
│   │   ├── share_router.dart             ShareOutcome, ShareRouter (doppioni 2 s), ShareIntake (initial → reset → incoming)
│   │   └── content_actions.dart          ContentActions (uriFor, open)
│   ├── features/
│   │   ├── common/
│   │   │   ├── neon.dart                 NeonButton, SectionLabel, QrPanel, QrThumb, QrRow, ActionTile
│   │   │   ├── pro_gate.dart             ProGate (copia di Film Tracker)
│   │   │   └── qr_actions.dart           historyKeep, recordIfEnabled, saveAsFavorite, askTitle, openStyle, openEditForm, openNewForm, shareQrImage, copyContent, copyText, openContent, openPro
│   │   ├── display/qr_display_page.dart  QrDisplayPage (.args / .saved), argsOfRow
│   │   ├── forms/                        FormPage + 5 moduli (QrFormWidget) + form_fields (validatori, QrTextField)
│   │   ├── history/history_page.dart     HistoryPage
│   │   ├── home/home_page.dart           HomePage, kHomeFavorites, kHomeRecents
│   │   ├── saved/saved_page.dart         SavedPage (menu rinomina/togli/elimina)
│   │   ├── scan/scan_page.dart           [SCANNER] ScanPage (ReaderWidget di flutter_zxing, torcia, Da immagine, mirino), _ScanError, _Viewfinder
│   │   ├── scan/scan_result_page.dart    ScanResultPage (tipo, contenuto, azioni)
│   │   ├── settings/settings_page.dart   SettingsPage
│   │   ├── settings/data_section.dart    DataSection, createBackup, restoreBackup
│   │   └── style/
│   │       ├── style_page.dart           StylePage, kSwatches, kReadabilityDelay
│   │       └── logo_picker.dart          kLogoIcons, LogoPicker
│   └── l10n/
│       ├── app_en.arb, app_it.arb        GENERATI da tool/testi.py (205 chiavi)
│       ├── untranslated.json             vuoto ({}): nessuna chiave senza traduzione
│       └── generated/                    GENERATO da gen-l10n (classe L)
├── test/                                 152 test (§12)
│   ├── data/      qr_repository_test.dart, qr_backup_test.dart
│   ├── domain/    qr_encoder_test, qr_decoder_test, qr_capacity_test, qr_style_test, contrast_test
│   ├── services/  services_test.dart, share_router_test.dart
│   └── widget/    qr_test_harness.dart (impianto), display_page_test, form_page_test, home_page_test,
│                  style_page_test, paywall_config_test, palette_contrast_test, texts_glyphs_test
├── tool/
│   ├── testi.py                          sorgente dei testi comuni + generatore degli ARB (57 chiavi)
│   ├── testi_forms.py                    contact_, email_, form_, phone_, sms_, wifi_ (25)
│   ├── testi_home.py                     common_, display_, home_, save_, share_, wifi_ (37)
│   ├── testi_lists.py                    backup_, data_, history_, saved_, settings_ (40; TIPI favorites/history int)
│   ├── testi_scan.py                     result_, scan_ (19)
│   ├── testi_style.py                    logo_, style_ (27)
│   └── genera_icone.py                   icone e splash dall'originale (numpy, PIL, scipy)
├── assets/
│   ├── fonts/                            PlusJakartaSans-Variable.ttf, SpaceGrotesk-Variable.ttf, OFL-PlusJakartaSans.txt, OFL-SpaceGrotesk.txt
│   └── icon/                             originale.png (del proprietario) + i PNG prodotti da genera_icone.py; anteprime/ (prove, non usate)
├── android/
│   ├── build.gradle.kts                  + blocco finalizeDsl per receive_sharing_intent
│   ├── gradle.properties                 tetti di memoria, kotlin.incremental=false, builtInKotlin=false
│   ├── settings.gradle.kts               AGP 9.1.0, Kotlin 2.4.0
│   └── app/
│       ├── build.gradle.kts              com.smp.qrme, minSdk 24, desugaring, firma da key.properties (PKCS12), minify+shrink
│       ├── proguard-rules.pro            keep com.dexterous.**, com.tekartik.**
│       └── src/main/
│           ├── AndroidManifest.xml       BILLING, CAMERA (+ remove di RECORD_AUDIO e storage), camera non obbligatoria, allowBackup=false, singleTask, SEND text/plain e image/*, deep link spento, <queries>
│           └── kotlin/com/smp/qrme/MainActivity.kt   onNewIntent → setIntent
├── ios/
│   ├── ExportOptions.plist               app-store-connect, automatic, export
│   ├── Runner/
│   │   ├── AppDelegate.swift             excludeUserDataFromBackup() su Documents/ a ogni avvio
│   │   ├── SceneDelegate.swift           vuoto (FlutterSceneDelegate)
│   │   ├── Info.plist                    QR Me, deep link spento, permessi, AppGroupId, CFBundleURLTypes ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)
│   │   ├── Runner.entitlements           application-groups: group.com.smp.qrme
│   │   └── {it,en}.lproj/InfoPlist.strings   testi dei permessi
│   ├── ShareExtension/                   creata da tool/aggiungi_share_extension_ios.rb (modello in packages/micro_share/ios_template/)
│   │   ├── ShareViewController.swift     RSIShareViewController con shouldAutoRedirect() -> true
│   │   ├── Info.plist                    attivazione: testo, 1 link, 1 immagine; AppGroupId = $(CUSTOM_GROUP_ID)
│   │   └── ShareExtension.entitlements   application-groups: group.com.smp.qrme
│   └── Runner.xcodeproj/project.pbxproj  target ShareExtension, Embed Foundation Extensions PRIMA di Thin Binary, pacchetto Swift receive_sharing_intent-1.9.0
├── pubspec.yaml                          dipendenze commentate una per una
├── l10n.yaml                             template inglese, classe L
├── analysis_options.yaml                 include ../../analysis_options.yaml, esclude generated/build/android/ios
├── flutter_launcher_icons.yaml           adattiva + monocromatica, remove_alpha_ios, fondo iOS #F3F7F3
├── flutter_native_splash.yaml            #F3F7F3 nei due temi, immagine per Android 12
└── README.md
```

**Non esistono**: `integration_test/` (la dipendenza di sviluppo c'e', la cartella no: niente giri
per screenshot o video dello store), `lib/dev/` (nessun dato di esempio), `test/` per pagine di
scansione, risultato, preferiti, cronologia, impostazioni.

---

## 2bis. Icona e schermata di avvio

`tool/genera_icone.py` (Python con numpy, PIL, scipy) legge `assets/icon/originale.png` (1254×1254
RGBA, **sfondo trasparente**, arrivato il 2026-10-09 in Download come file «QR Me» senza
estensione) e produce in `assets/icon/`:

| File | A cosa serve |
|---|---|
| `icona_ios.png` | 1024 pieno, senza alfa: icona iOS, icona Play 512, legacy Android |
| `adaptive_background.png` | Android 8+: fondo pieno `#F3F7F3` |
| `adaptive_foreground.png` | Android 8+: il disegno trasparente nella zona sicura |
| `adaptive_monochrome.png` | Android 13+ (icone a tema): la sagoma |
| `splash_logo.png` | splash Android ≤ 11 e iOS |
| `splash_android12.png` | splash Android 12+, dentro il cerchio che sopravvive |
| `anteprime/*.png` | prove a occhio (maschere iOS, cerchio e squircle Android), non usate dall'app |

Costanti dello script: `FONDO = (243, 247, 243)` (`#F3F7F3`), `TELA = 1080`, `LATO_ANDROID = 460`,
`LATO_IOS = 780`, `ALFA_SAGOMA = 140`, `GAP_SIMBOLO = 40`. Funzioni: `carica()`, `scala(disegno,
lato_lungo)`, `al_centro(disegno, tela, lato_lungo, fondo=(0,0,0,0))`, `sagoma(primo)`, `main()`.

⚑ **Metodo di Scorte Calore/Full Freezer, non di Film Tracker**: il disegno arriva gia' scontornato,
quindi si ha gratis il primo piano separato (parallasse) e la **monocromatica** di Android 13.
⚑ **Fondo chiarissimo e non scuro**: i moduli del disegno sono quasi neri e su fondo scuro
sparirebbero; grigio-verde e non bianco puro perche' sulla griglia bianca di iOS un'icona bianca
perde il bordo. Per lo stesso motivo la splash e' `#F3F7F3` **anche nel tema scuro**.
☠ iOS rifiuta il canale alfa a caricamento finito: icona composta su fondo pieno + `remove_alpha_ios: true`.
☠ Zona sicura Android: il disegno (quasi quadrato, occhi negli angoli) deve avere la diagonale nel
cerchio sicuro di 660 px su 1080 → lato lungo ≤ ~466 px (460).

Poi: `pwsh ../../tool/fl.ps1 pub run flutter_launcher_icons` e
`pwsh ../../tool/fl.ps1 pub run flutter_native_splash:create`.

---

## 2ter. iOS

- Bundle `com.smp.qrme`, team `A29HGT2MQ4`, `IPHONEOS_DEPLOYMENT_TARGET = 15.0`,
  `TARGETED_DEVICE_FAMILY = 1` (solo iPhone; sull'iPad gira in compatibilita').
- **Target `ShareExtension`** (`com.smp.qrme.ShareExtension`, `productType` app-extension): creato dallo
  script `tool/aggiungi_share_extension_ios.rb apps/qr_me ShareExtension group.com.smp.qrme`
  (**gia' eseguito sul Mac**, commit `30f351a`). Fasi: Sources, Frameworks (solo il prodotto Swift
  `receive-sharing-intent`), Resources. Build settings: `CUSTOM_GROUP_ID = group.com.smp.qrme` (anche
  sul Runner), `CODE_SIGN_ENTITLEMENTS = ShareExtension/ShareExtension.entitlements`,
  `INFOPLIST_FILE = ShareExtension/Info.plist`, `GENERATE_INFOPLIST_FILE = NO`, `SKIP_INSTALL = YES`,
  `SWIFT_VERSION = 5.0`, `LD_RUNPATH_SEARCH_PATHS = $(inherited) @executable_path/Frameworks
  @executable_path/../../Frameworks`.
- Runner: fasi «… Embed Frameworks, **Embed Foundation Extensions**, Thin Binary» (la copia
  dell'appex **prima** di Thin Binary). Pacchetti Swift locali: `FlutterGeneratedPluginSwiftPackage`
  e `Flutter/ephemeral/Packages/.packages/receive_sharing_intent-1.9.0`.
- `Info.plist` del Runner: `CFBundleDisplayName`/`CFBundleName` «QR Me», `CFBundleLocalizations`
  it/en, `ITSAppUsesNonExemptEncryption` false, **`FlutterDeepLinkingEnabled` false**,
  `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `AppGroupId = $(CUSTOM_GROUP_ID)`,
  `CFBundleURLTypes` con schema **`ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)`** (cioe'
  `ShareMedia-com.smp.qrme`), orientamenti verticale e orizzontali.
- `ios/Runner/AppDelegate.swift` — `@main class AppDelegate: FlutterAppDelegate,
  FlutterImplicitEngineDelegate`:

| Metodo | Firma | Effetto |
|---|---|---|
| `application(_:didFinishLaunchingWithOptions:)` | `override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool` | chiama `excludeUserDataFromBackup()` **prima** di `super` (prima che Dart apra il database) |
| `didInitializeImplicitFlutterEngine` | `func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge)` | `GeneratedPluginRegistrant.register(with:)` |
| `excludeUserDataFromBackup` | `private func excludeUserDataFromBackup()` | `isExcludedFromBackup = true` su `Documents/`, `Documents/qr_me/`, `Documents/qr_me.sqlite` e `-wal`/`-shm`/`-journal` (solo quelli che esistono); errori → `NSLog`, l'avvio prosegue |

  ⚑ **La cartella intera**, non solo i file: SQLite (journal, WAL) e le scritture atomiche creano file
  nuovi che non erediterebbero l'attributo; una cartella esclusa esclude anche cio' che vi nasce
  dopo. Si rifa' **a ogni avvio** (ripara un attributo perso dopo un ripristino del dispositivo).
  `Library/Application Support/qr_me/` (entitlement, log) **resta** nel backup: niente contenuti
  dell'utente, e l'entitlement aiuta dopo un cambio di telefono.
  ☐ **Mai compilato**: Windows non compila Swift; va provato sul Mac (F17.7.6).
- `SceneDelegate.swift`: `class SceneDelegate: FlutterSceneDelegate {}` (template).
- Testi dei permessi: `en.lproj` e `it.lproj/InfoPlist.strings` (camera: «Per leggere i QR con la
  fotocamera.»; foto: «Per scegliere una foto da mettere come logo nel QR, o un'immagine con un QR da
  leggere.»), gia' nel gruppo di varianti del progetto (☠ solo su disco iOS non li legge).
- **Estensione**: `ShareViewController: RSIShareViewController` con `override func
  shouldAutoRedirect() -> Bool { true }` (nessuna schermata intermedia: salva nell'App Group e
  riapre l'app con `ShareMedia-com.smp.qrme`). `Info.plist` dell'estensione:
  `NSExtensionActivationSupportsText` true, `…WebURLWithMaxCount` 1, `…ImageWithMaxCount` 1,
  `PHSupportedMediaTypes` Image, `NSExtensionPrincipalClass = $(PRODUCT_MODULE_NAME).ShareViewController`,
  niente storyboard. **Si modificano nel modello** `packages/micro_share/ios_template/`, non qui (lo
  script li ricopia).
- Stato: **build iOS, estensione e riapertura dell'app mai provate** (F17.7.6, serve il Mac e un
  iPad via TestFlight). Ripiego gia' deciso se iOS rompe la riapertura per schema URL: un'estensione
  che mostra il QR da sola (SwiftUI + `CIQRCodeGenerator`).

---

## 3. Il database

**Una tabella sola**, `qr_codes`, **`schemaVersion = 1`**, file **`qr_me.sqlite`** nella cartella
documenti dell'app (`getApplicationDocumentsDirectory()`, **non** dentro `Documents/qr_me/`).
Istanti in **millisecondi UTC** (ADR-008). Colonne SQL in snake_case.

Legenda: **CHECK** = vincolo SQL vero; **len** = `withLength`, controllato **solo da Drift in Dart**
all'inserimento con un companion (lancia `InvalidDataException`), non da SQLite.

⚑ **Una tabella e non due**: cronologia e preferiti sono lo stesso oggetto con un flag. Salvare un
QR della cronologia nei preferiti non lo copia: cambia `is_favorite` e smette di essere potabile.

### `qr_codes` (classe `QrCodes`, `lib/data/tables.dart`)

| Colonna | Tipo | Default | Vincoli | Significato |
|---|---|---|---|---|
| `id` | INTEGER | | PK autoincrement | |
| `kind` | TEXT | | **CHECK IN `qrKindKeys`** (`text, url, wifi, contact, email, sms, phone`) | `QrKind.name` |
| `payload` | TEXT | | len 1..4000 | la stringa **esatta** nel QR (`QrEncoder.encode` o quella letta) |
| `fields_json` | TEXT nullable | | | `jsonEncode(QrContent.toFields())`; **null per testo e link** (si riaprono dal payload) |
| `title` | TEXT | | len 1..80 | `autoTitle` o il nome dato dall'utente (il repository rifila e taglia: `_title`) |
| `source` | TEXT | | **CHECK IN `QrSource.all`** | `shared` \| `typed` \| `form` \| `scanned` \| `image` |
| `style_json` | TEXT nullable | | | `jsonEncode(QrStyle.toJson())`; **null = `QrStyle.plain`** |
| `is_favorite` | BOOL | `false` | | preferito = salvato con nome, escluso dalla potatura |
| `created_at` | INTEGER | | obbligatoria | ms UTC |
| `last_used_at` | INTEGER | | obbligatoria | ms UTC, aggiornato a ogni visualizzazione: ordina la cronologia |

Indice: **`idx_qr_codes_favorite_used ON qr_codes (is_favorite, last_used_at DESC)`**
(`@TableIndex.sql`). **Nessuna UNIQUE su `payload`**: due preferiti con lo stesso contenuto e stili
diversi sono legittimi (il Wi-Fi di casa in verde per la cucina e in nero per l'ingresso); i
doppioni **in cronologia** li evita `QrRepository.recordShown`.
⚑ `payload` 4000 e non 2953: il limite del QR e' in **byte UTF-8**, questo in **caratteri**, ed e'
solo un argine; il controllo vero e' `QrCapacity` prima di disegnare.
☠ Il CHECK entra nello schema alla creazione: un `QrKind` o una `QrSource` nuovi dopo il rilascio
richiedono una migrazione che **ricrei** la tabella (SQLite non modifica i CHECK).
`tables.dart` ha `// ignore_for_file: recursive_getters` (i `check(...)` citano la colonna dentro il
suo getter: forma documentata da Drift che il lint scambia per ricorsione).

Simboli di modulo in `tables.dart` (riesportati da `database.dart` con `export 'tables.dart' show
QrSource, qrKindKeys`):

| Simbolo | Firma | Contenuto |
|---|---|---|
| `qrKindKeys` | `final List<String> qrKindKeys` | `[for (k in QrKind.values) k.name]` — dal dominio, non copiata |
| `QrSource` | `abstract final class QrSource` | costanti `static const String shared = 'shared'`, `typed = 'typed'`, `form = 'form'`, `scanned = 'scanned'`, `image = 'image'`; `static const List<String> all = [shared, typed, form, scanned, image]` |

Righe generate (in `database.g.dart`, non si modificano): la riga QrCode (`id`, `kind`, `payload`,
`fieldsJson` String?, `title`, `source`, `styleJson` String?, `isFavorite` bool, `createdAt` int,
`lastUsedAt` int, con `copyWith`), il companion QrCodesCompanion (`QrCodesCompanion.insert(...)`),
la tabella `$QrCodesTable`. ☠ Il nome QrCode **si scontra** con `QrCode` del pacchetto `qr` (esportato
da qr_flutter): per questo `qr_renderer.dart` importa qr_flutter **con prefisso** `qf`.

### Sicurezza dei dati

| Rischio | Stato | Dove |
|---|---|---|
| Password Wi-Fi e testi privati **in chiaro** nel database (`payload`, `fields_json`) | **accettato**: il file sta nel sandbox dell'app, nessuna cifratura | `qr_me.sqlite` |
| Backup automatico Android (Drive) | **escluso**: `android:allowBackup="false"` | `AndroidManifest.xml` |
| Backup iCloud / computer | **escluso**: `isExcludedFromBackup` su `Documents/` a ogni avvio (☐ da provare sul Mac) | `AppDelegate.swift` |
| La cronologia trattiene dati che l'utente crede cancellati | **no**: la potatura del piano gratuito cancella **davvero** (§5) | `QrRepository.pruneHistory` |
| Chi non vuole una traccia | cronologia **spegnibile** (nessuna scrittura) e «Cancella la cronologia» | `HistoryEnabledNotifier`, `SettingsPage` |
| La password Wi-Fi letta da chi passa | mascherata `••••••••` sotto il QR finche' non si tocca l'occhio; `WifiContent.toString` non la stampa (finirebbe nei log) | `QrDisplayPage`, `qr_content.dart` |
| Un backup malevolo scrive/cancella fuori dalla cartella | percorsi di logo con `..`, `\`, `:` o fuori da `images/` → FormatException | `QrBackupSource._logoPath` |
| Dati verso terzi | **nessuno** (regola «dati solo sul telefono»); eccezione: server licenze per il Pro su Android. ML Kit (`mobile_scanner`) mandava metriche a Google: **sostituito da ZXing**. ☠ Di flutter_zxing non si chiamano mai `zx.readBarcodeImageUrl`/`readBarcodesImageUrl` (l'unico punto del pacchetto che va in rete) | §0 punto 12, `pubspec.yaml` |

Il backup **esplicito** lo crea solo l'utente col Pro, in un file ZIP che vede (§8 e §9 Impostazioni).

### Migrazioni

`onCreate: m.createAll()`. `onUpgrade` **lancia** UnsupportedError («Migrazione da schema $from a
$to non implementata…»): la prima modifica di schema deve incrementare `schemaVersion` **e** aggiungere
qui il passo con il suo test; senza, il primo aggiornamento in produzione cancella i dati.
**Nessun** `PRAGMA foreign_keys` (una tabella sola, nessuna FK) e **nessun seed**.

---

## 4. `lib/domain/` — il cuore, senza Flutter

Dart puro (dipende solo da `characters`): niente Flutter, niente Drift, **niente stringhe
dell'app**. ⚑ Codifica e decodifica sono il punto in cui un errore e' **invisibile** (un QR Wi-Fi che
«si legge» ma connette con la password sbagliata): senza Flutter si testano in millisecondi, round-trip
compreso.

### `qr_content.dart` — cosa c'e' in un QR

`enum QrKind { text, url, wifi, contact, email, sms, phone }` — `name` e' la chiave di
`qr_codes.kind`: **non si rinomina**.
`enum WifiSecurity { wpa, wep, none }` — `wpa` copre WPA/WPA2/WPA3 (nella stringa sono tutte `T:WPA`).

| Funzione | Firma | Effetto |
|---|---|---|
| `normalizePhone` | `String normalizePhone(String number)` | `trim` e via spazi, trattini, **punti** e parentesi; il `+` iniziale resta. ⚑ anche i punti (la spec non li citava): «333.123.4567» e' comune e un punto in `tel:` fa fallire la chiamata su alcuni Android |

Private: `const int _kTitleMax = 40`; `String _clip(String s)` (trim; vuoto → `…`; oltre 40 code unit
taglia **senza spezzare una coppia surrogata** e aggiunge `…`, quindi max 41); `bool _same(String?,
String?)` (null == ''); `String? _orNull(String?)`.

`sealed class QrContent` — `const QrContent()`:

| Membro | Firma | Significato |
|---|---|---|
| `kind` | `QrKind get kind` | |
| `autoTitle` | `String get autoTitle` | titolo per la cronologia: mai vuoto, max 41 caratteri |
| `toFields` | `Map<String, Object?> toFields()` | per `fields_json`; solo tipi JSON |
| `fromFields` | `static QrContent fromFields(QrKind kind, Map<String, Object?> fields)` | l'inverso. ☠ **FormatException** su campo obbligatorio mancante/non testo, facoltativo non testo, URL illeggibile, sicurezza sconosciuta: succede solo con database o backup rovinati |

⚑ **Uguaglianza per valore** su tutte le sottoclassi (serve al round-trip e al repository).
**Facoltativi vuoti e null sono uguali**; i **numeri di telefono si confrontano normalizzati**: un QR
letto non distingue «nessuna email» da «email vuota», e la differenza farebbe fallire il round-trip
senza significato per l'utente.

| Sottoclasse | Costruttore | Campi | `autoTitle` | `toFields()` | Note |
|---|---|---|---|---|---|
| `TextContent` | `const TextContent(this.text)` | `String text` | prima riga non vuota, `_clip` | `{'text'}` | codificato **identico**, nemmeno il trim |
| `UrlContent` | `const UrlContent(this.uri)` | `Uri uri` | host minuscolo senza `www.` | `{'url': uri.toString()}` | ⚑ il costruttore non valida; per il testo scritto `tryParse` |
| `WifiContent` | `const WifiContent({required this.ssid, this.password = '', this.security = WifiSecurity.wpa, this.hidden = false})` | `ssid`, `password`, `security`, `hidden` | `ssid` | `{'ssid','password','security': name,'hidden'}` | ☠ `toString` **senza password** (finisce nei log) |
| `ContactContent` | `const ContactContent({required this.name, this.phone, this.email, this.organization, this.url, this.note})` | `name` (FN) + 5 `String?` | `name` | `{'name', 'phone'…'note'}` con vuoti → null | `N` ricavato da `name`: ultima parola = cognome |
| `EmailContent` | `const EmailContent({required this.to, this.subject = '', this.body = ''})` | `to`, `subject`, `body` | `to` | `{'to','subject','body'}` | |
| `SmsContent` | `const SmsContent({required this.number, this.body = ''})` | `number`, `body` | `number` | `{'number','body'}` | uguaglianza sul numero normalizzato |
| `PhoneContent` | `const PhoneContent(this.number)` | `number` | `number` | `{'number'}` | uguaglianza sul numero normalizzato |

Ogni sottoclasse ridefinisce `operator ==`, `hashCode` (con il `QrKind` nel hash) e `toString`.

`UrlContent.tryParse` — `static UrlContent? tryParse(String input)`:
- trim; vuoto o con spazi interni → null;
- `http://`/`https://` (maiuscole indifferenti) → `UrlContent(Uri.tryParse(s))` se ha un host;
- un altro schema (`mailto:`, `ftp://`, `javascript:`) → null (ma `host:8080` senza schema non e' uno schema);
- senza schema: diventa `https://<s>` **solo se contiene un punto** e l'host ha un punto.
⚑ Il punto distingue un dominio da una parola: senza la regola «ciao» diventerebbe `https://ciao`.

### `qr_encoder.dart` — contenuto → stringa

`abstract final class QrEncoder`:

| Metodo | Firma | Effetto |
|---|---|---|
| `encode` | `static String encode(QrContent content)` | la stringa da codificare (tabella sotto). ☠ **ArgumentError** per un `UrlContent` con schema diverso da http/https (o senza schema e senza aspetto di dominio) |
| `wifiEscape` | `static String wifiEscape(String s)` | backslash davanti a `\ ; , : "` (stessa grammatica di MECARD/MATMSG) |
| `vcardEscape` | `static String vcardEscape(String s)` | `\`→`\\`, `,`→`\,`, `;`→`\;`, CRLF/CR/LF → `\n` letterale |

Private: `_url(Uri)`, `_wifi(WifiContent)`, `_vcard(ContactContent)`, `_mailto(EmailContent)`.

Le codifiche, **esattamente** queste (sono quelle che le fotocamere di sistema di Android e iOS
riconoscono; il decoder accetta le varianti, l'encoder **non le produce mai**):

| Tipo | Stringa | Regole |
|---|---|---|
| testo | il testo com'e' | nessuna trasformazione, nemmeno il trim |
| link | `uri.toString()` | solo http/https; senza schema → normalizzato con `tryParse` |
| Wi-Fi | `WIFI:T:WPA;S:<ssid>;P:<password>;H:true;;` | `T:WEP` / `T:nopass` (e allora **niente `P:`**: alcune fotocamere chiederebbero una password vuota); `H:true` solo se nascosta; **escape `\ ; , : "`** in SSID e password |
| contatto | vCard **3.0** con **CRLF**: `BEGIN:VCARD`, `VERSION:3.0`, `N:<cognome>;<nome>;;;`, `FN:<nome>`, `TEL:` (normalizzato), `EMAIL:`, `ORG:`, `URL:`, `NOTE:`, `END:VCARD` | righe vuote **omesse** (un `TEL:` vuoto crea un numero vuoto in rubrica); escape vCard |
| email | `mailto:<to>?subject=<s>&body=<b>` | `Uri.encodeComponent` (spazi `%20`); parametri vuoti omessi; `to` rifilato |
| SMS | `SMSTO:<numero normalizzato>:<testo>` | il testo **non** si escapa: tutto dopo il secondo `:` e' il messaggio |
| telefono | `tel:<numero normalizzato>` | il `+` iniziale resta |

⚑ **vCard 3.0 e non 4.0**: iOS e Android la importano entrambe; MECARD e' piu' corta ma iOS la tratta come testo.
⚑ **`SMSTO:` e non `sms:`**: e' quella che entrambe le fotocamere aprono col testo precompilato.
⚑ **`encodeComponent` e non `Uri(queryParameters:)`**: quest'ultimo scrive gli spazi come `+`, e in un
mailto il `+` resta un `+` («Ciao+a+tutti»).
☠ **Senza l'escape del Wi-Fi** una password con `;` produce un QR che **si legge** ma connette con la
password sbagliata, e l'errore sembra della rete (F17.1.11 punto 1).

### `qr_decoder.dart` — stringa letta → contenuto

`abstract final class QrDecoder`:

| Metodo | Firma | Effetto |
|---|---|---|
| `decode` | `static QrContent decode(String raw)` | riconosce il tipo; **non lancia mai** (try/`on Object` → `TextContent(raw)`); cio' che non riconosce **o riconosce ma e' rotto** (un `WIFI:` senza SSID) diventa `TextContent(raw)` intatto. Proprieta': `decode(QrEncoder.encode(c)) == c` |
| `decodeTyped` | `static QrContent decodeTyped(String raw)` | per cio' che l'utente **scrive, incolla o condivide**: come `decode`, ma un `TextContent` che `UrlContent.tryParse` riconosce diventa link (`esempio.it` → `https://esempio.it`) |

⚑ **Due metodi di proposito**: un QR **letto** che contiene «esempio.it» e' un testo (chi l'ha
generato non l'ha fatto link) e cambiarlo romperebbe il round-trip; cio' che scrive l'utente e'
un'intenzione. Chi usa quale: `HomePage._show` e `ShareRouter` → `decodeTyped`; `ScanResultPage`,
`QrCodeToDomain.content` → `decode`.

Riconoscimento (prefisso senza badare alle maiuscole, **trim solo a sinistra**: a destra c'e' il testo
di un SMS o di una nota e tagliarlo romperebbe il round-trip):

| Prefisso | Diventa | Dettagli |
|---|---|---|
| `WIFI:` | `WifiContent` | campi in qualunque ordine, unescape; `T` `WEP` → wep, `NOPASS`/`NONE` → none, **assente → none se senza password, altrimenti wpa**, qualunque altro (`WPA2`, `SAE`…) → wpa; `H:true` (minuscole indifferenti); senza `S` → testo |
| `BEGIN:VCARD` | `ContactContent` | 3.0 e 4.0; righe ripiegate unite (RFC 6350 §3.2); gruppi (`item1.`) e parametri (`;TYPE=…`) ignorati; legge `FN`, `N`, `TEL` (toglie `tel:` della 4.0), `EMAIL`, `ORG` (componenti `;` uniti con `, `), `URL`, `NOTE`; senza `FN` il nome da `N` (`nome cognome`); senza nome → testo |
| `MECARD:` | `ContactContent` | `N:Cognome,Nome` → «Nome Cognome»; `TEL`, `EMAIL`, `ORG`, `URL`, `NOTE` |
| `mailto:` | `EmailContent` | destinatario decodificato; `subject`/`body` con `decodeComponent` (**il `+` resta `+`**); senza destinatario → testo |
| `MATMSG:` | `EmailContent` | `TO`, `SUB`, `BODY` |
| `SMSTO:` | `SmsContent` | numero fino al primo `:`, il resto e' il testo |
| `sms:` | `SmsContent` | RFC 5724 `sms:+39333?body=…`, oppure `SMS:333:testo` (→ come SMSTO) |
| `tel:` | `PhoneContent` | normalizzato; deve essere `^\+?[0-9*#,;pPwW]+$`, altrimenti testo |
| `http://`, `https://` senza spazi | `UrlContent` | con host; spazi finali tollerati |

Private: `_decode`, `_fields` (grammatica `chiave:valore;` con escape a backslash), `_first`,
`_wifi`, `_mecard`, `_matmsg`, `_vcard`, `_unescapedIndex`, `_splitUnescaped`, `_vcardUnescape`,
`_mailto`, `_query` (⚑ non `Uri.splitQueryString`, che trasforma `+` in spazio: «1+1» diventerebbe
«1 1»), `_smsto`, `_sms`, `_tel`, `_nonEmpty`.

### `qr_capacity.dart` — quanto ci sta

`enum QrErrorLevel { low, medium, quartile, high }` (L ~7%, M ~15%, Q ~25%, H ~30% di moduli recuperabili).

`abstract final class QrCapacity`:

| Membro | Firma | Effetto |
|---|---|---|
| `maxBytes` | `static int maxBytes(QrErrorLevel level)` | versione 40, modalita' byte: **L 2953, M 2331, Q 1663, H 1273** |
| `bytesOf` | `static int bytesOf(String payload)` | `utf8.encode(payload).length` (emoji 4, accentata 2) |
| `fits` | `static bool fits(String payload, QrErrorLevel level)` | `bytesOf <= maxBytes` (usata solo dai test) |
| `denseBytes` | `static const int denseBytes = 1000` | oltre: avviso «QR molto fitto» |
| `choose` | `static QrLevelChoice choose(String payload, {required bool wantsLogo})` | **H** se c'e' il logo e sta in H; altrimenti **M** (logo tolto se era chiesto); altrimenti **L**; altrimenti livello null (`tooLong`) |

`final class QrLevelChoice` — costruttore privato `QrLevelChoice._(this.level, {required this.bytes,
required this.logoAllowed, required this.logoDropped})`; campi `QrErrorLevel? level`, `int bytes`,
`bool logoAllowed`, `bool logoDropped`; getter `bool get tooLong` (`level == null`), `bool get dense`
(`bytes > denseBytes`).

⚑ **M senza logo, H con logo**: il logo copre fino al ~22% del lato (~5% dell'area) e H ne recupera
il 30%. ⚑ **Sempre modalita' byte**, anche per sole cifre: e' il limite prudente, e un QR numerico da
7.000 cifre non e' comunque leggibile da un telefono. ⚑ La regola sta qui (Dart puro, testabile) e
`QrRenderer.choose` la chiama. ☠ **Si controlla PRIMA di disegnare** (F17.1.11 punto 7): un articolo
intero condiviso farebbe lanciare a qr_flutter un'eccezione dentro il build di un widget.

### `qr_style.dart` — stile e logo

`enum QrModuleShape { square, circle }` · `enum QrEyeShape { square, circle }` (gli occhi sono i tre
quadrati di posizionamento).

`const List<String> kLogoIconIds` = `wifi, phone, email, sms, home, work, heart, star, shop,
restaurant, coffee, music, camera, link, person, group, event, location, car, pets, school, info,
gift, payment` (**24**). ⚑ Id **testuali** e non il `codePoint` Material: i codePoint cambiano fra
versioni dei font di Flutter e un preferito mostrerebbe un'altra icona. ☠ Un id pubblicato non si
toglie e non si rinomina (e' nei database e nei backup); `kLogoIcons` (logo_picker) deve avere
**esattamente** queste chiavi, nello stesso ordine (test).

`sealed class QrLogo` — `const QrLogo()`; `Map<String, Object?>? toJson()`; `static QrLogo
fromJson(Object? json)` **tollerante**: non mappa, tipo sconosciuto, foto senza `image`, icona senza
`id`, testo non valido → `NoLogo` (meglio un QR senza logo che una pagina che non si apre). Note: per
le icone **non** controlla che l'id sia nel catalogo (lo fa `LogoRenderer`, che restituisce null).

| Sottoclasse | Costruttore | `toJson()` | Note |
|---|---|---|---|
| `NoLogo` | `const NoLogo()` | `null` | |
| `PhotoLogo` | `const PhotoLogo({required this.imageName, this.round = false})` | `{'type':'photo','image':…,'round':…}` | `imageName` = percorso **relativo** in ImageStore (`images/logos/<uuid>.jpg`), uguale a `StoredImage.path`; la miniatura si ricava (`QrLogoFiles.thumbOf`) |
| `IconLogo` | `const IconLogo(this.iconId)` | `{'type':'icon','id':…}` | |
| `TextLogo` | `const TextLogo(this.text)` | `{'type':'text','text':…}` | `static const int maxGraphemes = 3`; `static bool isValidText(String text)` → 1..3 **grafemi** dopo il trim (`characters`). ⚑ `String.length` conterebbe i code unit e una bandiera sarebbe gia' «troppo lunga» |

Tutte con `==`/`hashCode` per valore.

`final class QrStyle`:

| Membro | Firma | Significato |
|---|---|---|
| costruttore | `const QrStyle({this.foreground = 0xFF000000, this.background = 0xFFFFFFFF, this.moduleShape = QrModuleShape.square, this.eyeShape = QrEyeShape.square, this.logo = const NoLogo()})` | colori **ARGB int**, non `Color` (Dart puro) |
| `plain` | `static const QrStyle plain = QrStyle()` | nero su bianco, quadrati, senza logo: lo stile **gratis** |
| `isPlain` | `bool get isPlain` | `== plain` → `style_json` null |
| `hasLogo` | `bool get hasLogo` | `logo is! NoLogo` |
| `copyWith` | `QrStyle copyWith({int? foreground, int? background, QrModuleShape? moduleShape, QrEyeShape? eyeShape, QrLogo? logo})` | |
| `toJson` | `Map<String, Object?> toJson()` | chiavi **corte e stabili**: `fg`, `bg`, `module`, `eye`, `logo` (assente senza logo). ☠ non si rinominano |
| `fromJson` | `static QrStyle fromJson(Map<String, Object?> json)` | **tollerante**: chiavi sconosciute ignorate, mancanti o del tipo sbagliato = default; i colori numerici con `& 0xFFFFFFFF`. ⚑ uno stile di una versione futura si apre con la forma di default invece di non aprirsi |
| `==`, `hashCode`, `toString` | | per valore |

`background` e' anche il colore della **zona di rispetto**: mai trasparente.

### `contrast.dart`

`abstract final class Contrast` — colori ARGB, **l'alfa si ignora**:

| Membro | Firma | Effetto |
|---|---|---|
| `minRatio` | `static const double minRatio = 3` | sotto: avviso rosso «Colori troppo simili» |
| `ratio` | `static double ratio(int argbA, int argbB)` | rapporto WCAG 2, da 1 a 21, simmetrico |
| `inverted` | `static bool inverted(int foreground, int background)` | primo piano piu' chiaro dello sfondo: avviso giallo |

Privata `_luminance(int argb)` (sRGB linearizzato, 0.2126/0.7152/0.0722). ⚑ Euristiche per avvisare
presto; la prova vera e' `ReadabilityCheck`. La stessa funzione verifica i colori della palette (test).

---

## 5. `lib/data/`

### `class QrDatabase extends _$QrDatabase` (`database.dart`)

`@DriftDatabase(tables: [QrCodes])`.

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `QrDatabase(super.e)` | |
| `open` | `factory QrDatabase.open()` | file `qr_me.sqlite` nella cartella documenti, su isolate separato (`NativeDatabase.createInBackground`) |
| `memory` | `factory QrDatabase.memory()` | in memoria, per i test |
| `schemaVersion` | `int get schemaVersion` → `1` | |
| `migration` | `MigrationStrategy get migration` | `onCreate` createAll; `onUpgrade` lancia |

Privata `LazyDatabase _openConnection()`: imposta `sqlite3.tempDirectory` alla cartella temporanea
dell'app. ☠ Su Android la cartella temporanea di sistema non e' scrivibile: senza, VACUUM e certi
ORDER BY falliscono con «unable to open database file», **solo su dispositivo**. ⚑ Se il file cambia
nome o cartella va aggiornato anche `AppDelegate.excludeUserDataFromBackup`.

`extension QrCodeToDomain on QrCode` (stesso file):

| Membro | Firma | Effetto |
|---|---|---|
| `kindEnum` | `QrKind get kindEnum` | ☠ **StateError** su chiave sconosciuta (solo con un dato di una versione futura; meglio un errore visibile) |
| `content` | `QrContent get content` | da `fields_json` se c'e' e si legge (riapre il modulo esattamente); altrimenti `QrDecoder.decode(payload)`. ⚑ Un `kind == text` che il decoder legge come altro **resta `TextContent(payload)`**. `fields_json` rotto (FormatException) → ripiego sul payload, «la verita' del QR». ⚠ un `fields_json` JSON valido ma con campi sbagliati fa lanciare `fromFields` (FormatException non intercettata qui: vedi §14) |
| `style` | `QrStyle get style` | null o illeggibile → `QrStyle.plain` |
| `createdAtUtc` / `lastUsedAtUtc` | `DateTime get createdAtUtc`, `DateTime get lastUsedAtUtc` | da ms UTC |

### `abstract final class QrLogoFiles` (`qr_repository.dart`)

| Membro | Firma | Effetto |
|---|---|---|
| `bucket` | `static const String bucket = 'logos'` | il bucket di `ImageStore.importBytes` |
| `thumbOf` | `static String thumbOf(String imageName)` | `images/logos/x.jpg` → `images/thumbs/logos/x.jpg` (la regola di ImageStore); un nome fuori da `images/` torna com'e' |
| `filesOf` | `static List<String> filesOf(String imageName)` | `[imageName, thumbOf(imageName)]` |

⚑ Lo stile salva **una stringa sola** (il percorso dell'immagine) invece di uno StoredImage intero;
la miniatura si ricava.

### `class QrRepository` (`qr_repository.dart`) — la sola porta sul database

`QrRepository(this._db, {this.images, DateTime Function()? clock})` — `final ImageStore? images`
(null nei test che provano solo il database: allora i file non si toccano); `clock` default
`DateTime.now`, istanti salvati in ms UTC (`_now()`).

Regole che vivono qui e non nello schema:
1. **niente doppioni in cronologia**: un non preferito con stesso `payload` **e** stesso `style_json`
   si «tocca» invece di aggiungersi (`recordShown`, `unfavorite`, `updateStyle`);
2. **la potatura non tocca i preferiti**;
3. **un logo foto che nessuno usa piu' si cancella dal disco** (`delete`, `clearHistory`,
   `pruneHistory`, `updateStyle`), controllando **tutti** gli stili rimasti (due QR possono
   condividere lo stesso logo).
⚑ **Nessuna scrittura implicita**: «cronologia spenta = nessuna scrittura» e' una regola **del
chiamante** (`recordIfEnabled`). ⚑ **I limiti del piano gratuito non stanno qui**: il repository
offre `pruneHistory` e `countFavorites` e non sa chi e' Pro.

**Letture**

| Metodo | Firma | Effetto |
|---|---|---|
| `watchHistory` | `Stream<List<QrCode>> watchHistory()` | non preferiti, `last_used_at DESC`, poi `id DESC` |
| `watchFavorites` | `Stream<List<QrCode>> watchFavorites()` | preferiti per titolo **senza maiuscole** (`Collate.noCase`), poi id |
| `byId` | `Future<QrCode?> byId(int id)` | |
| `watchById` | `Stream<QrCode?> watchById(int id)` | segue le modifiche; null se cancellata |
| `countFavorites` | `Future<int> countFavorites()` | per `FeatureKey.unlimitedEntities` |
| `watchFavoriteCount` | `Stream<int> watchFavoriteCount()` | idem, che segue (usato solo da `favoriteCountProvider`, che nessuno usa: §14) |
| `usedLogoImages` | `Future<Set<String>> usedLogoImages()` | i `PhotoLogo.imageName` di tutte le righe con `style_json` non null: per potatura e backup |

**Scritture**

| Metodo | Firma | Effetto |
|---|---|---|
| `recordShown` | `Future<int> recordShown({required QrContent content, required String payload, required String source, QrStyle style = QrStyle.plain})` | transazione: se esiste un **non preferito** gemello (payload + style_json) aggiorna `last_used_at` e ne restituisce l'id; altrimenti inserisce (`fields_json` null per testo/link, `title = _title(autoTitle)`). **ArgumentError** su `source` fuori da `QrSource.all`. ⚑ Un **preferito** identico non si tocca: la visualizzazione entra in cronologia come cosa a se'. ⚠ Un payload > 4000 caratteri lancia InvalidDataException di Drift (i chiamanti la intercettano) |
| `touch` | `Future<void> touch(int id)` | `last_used_at = now` (torna in cima) |
| `saveAsFavorite` | `Future<void> saveAsFavorite(int id, {required String title})` | `is_favorite = true`, titolo rifilato. Il limite lo controlla il chiamante |
| `unfavorite` | `Future<void> unfavorite(int id)` | torna in cronologia in cima; se c'era gia' un gemello in cronologia, **il gemello** si cancella |
| `updateStyle` | `Future<void> updateStyle(int id, QrStyle style)` | id inesistente → niente; scrive lo stile, toglie i gemelli che si creano, poi cancella i loghi rimasti orfani (il vecchio e quelli dei gemelli) |
| `updateContent` | `Future<void> updateContent(int id, {required QrContent content, required String payload})` | la «Modifica» di un preferito: `kind`, `payload`, `fields_json`, `last_used_at`; **titolo e stile restano**. ⚑ Il payload lo passa il chiamante: il repository non codifica |
| `rename` | `Future<void> rename(int id, String title)` | |
| `delete` | `Future<void> delete(int id)` | riga + logo foto se orfano; id inesistente → niente |
| `clearHistory` | `Future<void> clearHistory()` | solo i non preferiti, + loghi orfani |
| `pruneHistory` | `Future<int> pruneHistory({required int? keep})` | tiene gli ultimi `keep` non preferiti e restituisce quanti ne ha **cancellati davvero**; `null` = nessun limite (Pro) → 0; `keep < 0` → ArgumentError |
| `orphanLogoGrace` | `static const Duration orphanLogoGrace = Duration(minutes: 15)` | |
| `pruneOrphanLogos` | `Future<int> pruneOrphanLogos({Duration grace = orphanLogoGrace})` | cancella i file sotto `images/` che nessun QR usa (immagine **e** miniatura in uso tenute), **tranne quelli modificati negli ultimi `grace`** (rispetto a `clock`); restituisce i file tolti (0 senza `images`). Chiamata da `QrMeApp` 3 s dopo il primo frame |

Private: `static String? _fieldsJson(QrContent)`, `static String? _styleJson(QrStyle)` (plain → null),
`static String _title(String raw)` (trim; vuoto → `…`; max 80), `_historyTwins(String payload,
String? styleJson)` (select dei non preferiti gemelli), `Future<List<QrCode>> _dropHistoryTwinsOf(int
id)`, `Future<void> _deleteOrphanLogos(Iterable<QrCode> rows)`.

⚑ **Cronologia gratis = 5 righe VERE** (F17.1.4): le righe in eccesso si **cancellano**. Nasconderle e
rivelarle al Pro vorrebbe dire trattenere password Wi-Fi che l'utente crede sparite; il Pro tiene
tutto **da quando e' comprato in poi** (lo dice il paywall).
⚑ **Perche' `pruneOrphanLogos` esiste**: una foto scelta nella pagina Stile e abbandonata senza
«Applica» resta su disco, e `_deleteOrphanLogos` parte solo da righe che la usavano. ⚑ **15 minuti di
grazia**: tra l'import della foto (`LogoRenderer.importPhoto` scrive subito) e «Applica» la foto e' un
orfano **legittimo**; se la pulizia girasse in quel momento cancellerebbe l'anteprima sotto gli occhi.
☠ L'elenco da tenere contiene anche le **miniature** (`QrLogoFiles.filesOf`): `ImageStore.pruneOrphans`
scorre tutta `images/`, `thumbs/` compresa, e con le sole immagini cancellerebbe le miniature in uso.
☠ Un errore del disco non fa fallire l'operazione (il dato e' gia' cancellato): `MicroLog.e`.

### `class QrBackupSource implements BackupSource` (`qr_backup_source.dart`)

`const QrBackupSource(this.db, {this.paths, this.clock})` — `final QrDatabase db`; `final AppPaths?
paths` (per cancellare i loghi orfani dopo un «sostituisci tutto»; null nei test del solo database);
`final DateTime Function()? clock` (ora usata quando il file non porta le date).

| Membro | Firma | Effetto |
|---|---|---|
| `id` | `static const String id = 'qr_me'` | **immutabile**: lo schema dei backup |
| `schemaId` | `String get schemaId` → `id` | |
| `schemaVersion` | `int get schemaVersion` → `1` | |
| `exportPayload` | `Future<Map<String, Object?>> exportPayload()` | `{codes: [{kind, payload, fields?, title, source, style?, favorite, createdAt, lastUsedAt}]}` per id; `fields` e `style` come **oggetti JSON** (file leggibile) |
| `imagePaths` | `Future<List<String>> imagePaths()` | immagine e miniatura di ogni logo usato, ordinati |
| `counts` | `Future<Map<String, int>> counts()` | `{'favorites': n, 'history': n}` (li legge il riepilogo del ripristino) |
| `importPayload` | `Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode})` | in **una transazione**: `replaceAll` cancella tutto; `mergeKeepExisting` salta i gia' presenti (stessi payload, style_json, preferito **e** `createdAt`). Valida `kind`, `source`, `fields` (rilette con `fromFields`), `style` (riscritto dalla forma letta: chiavi di versioni future cadono), percorso del logo. ☠ Tutto diventa **FormatException** (TypeError e InvalidDataException compresi): `BackupService.restore` intercetta solo le Exception. Dopo la transazione riuscita, con `replaceAll`, cancella i loghi del telefono che il file **non** riporta |

Private: `static String _logoPath(String path)` (☠ deve iniziare con `images/`, niente `..`, `\`, `:`),
`static List<Map<String, Object?>> _list(Object? raw)` (gli elementi non mappa si scartano).

⚑ **Niente id nel file**: non significano niente su un altro telefono e nessuno li referenzia.
⚑ **Il limite di 5 non si applica al ripristino**: riporta i dati come erano; lo riapplica la prossima
`pruneHistory` dopo un QR mostrato.
☠ «Sostituisci tutto» cancella anche i loghi che il backup non riporta, **dopo** la transazione e solo
quelli che il file non riscrive (regola di `FilmBackupSource`).

---

## 6. `lib/app/`

### `providers.dart` — i provider radice

⚑ Tutto passa da provider e niente e' globale: un singleton non si sostituisce nei test; con i
provider l'inizializzazione e' pigra (⚑ database e store **non** in `main`: produrrebbero una
schermata bianca all'avvio, e chi arriva da una condivisione vuole il QR subito).

| Provider / simbolo | Tipo | Valore / effetto |
|---|---|---|
| `appConfigProvider` | `Provider<MicroAppConfig>` | **lancia** UnimplementedError se non sovrascritto in `main` |
| `appPathsProvider` | `Provider<AppPaths>` | idem |
| `settingsProvider` | `Provider<SettingsStore>` | idem |
| `QrSettingKeys` | `abstract final class QrSettingKeys` | `static const String historyEnabled = 'history_enabled'` |
| `ThemeModeNotifier` | `class ThemeModeNotifier extends Notifier<ThemeMode>` | `ThemeMode build()`: `light`/`system` salvati, **altrimenti scuro**; `Future<void> set(ThemeMode mode)` salva `mode.name` |
| `themeModeProvider` | `NotifierProvider<ThemeModeNotifier, ThemeMode>` | |
| `HistoryEnabledNotifier` | `class HistoryEnabledNotifier extends Notifier<bool>` | `bool build()` → `getBool(historyEnabled, orElse: true)`; `Future<void> set(bool enabled)` |
| `historyEnabledProvider` | `NotifierProvider<HistoryEnabledNotifier, bool>` | |
| `databaseProvider` | `Provider<QrDatabase>` | `QrDatabase.open()`, chiuso con `onDispose` |
| `imageStoreProvider` | `Provider<ImageStore>` | `ImageStore(paths: appPaths)` (i loghi foto) |
| `repositoryProvider` | `Provider<QrRepository>` | `QrRepository(db, images: imageStore)` |
| `historyProvider` | `StreamProvider<List<QrCode>>` | `watchHistory()` |
| `favoritesProvider` | `StreamProvider<List<QrCode>>` | `watchFavorites()` |
| `favoriteCountProvider` | `StreamProvider<int>` | `watchFavoriteCount()` — **nessuno lo usa** (§14) |
| `qrCodeProvider` | `StreamProvider.family<QrCode?, int>` | `watchById(id)` (pagina del QR salvato) |
| `qrRendererProvider` | `Provider<QrRenderer>` | `const QrRenderer()` |
| `logoRendererProvider` | `Provider<LogoRenderer>` | `const LogoRenderer()` |
| `qrImageReaderProvider` | `Provider<QrImageReader>` | `const ZxingImageReader()` («Da immagine», immagine condivisa: prova anche i QR invertiti) |
| `readabilityCheckProvider` | `Provider<ReadabilityCheck>` | `ReadabilityCheck(const ZxingImageReader.strict(), renderer: renderer)`. ⚑ **Non** usa `qrImageReaderProvider`: la verifica usa il lettore severo (niente invertiti); i test sostituiscono direttamente questo provider |
| `screenBoostProvider` | `Provider<ScreenBoost>` | `const ScreenBoost()` |
| `contentActionsProvider` | `Provider<ContentActions>` | `const ContentActions()` |
| `shareInboxProvider` | `Provider<ShareInbox>` | `RsiShareInbox()` (micro_share); nei test FakeShareInbox |
| `shareRouterProvider` | `Provider<ShareRouter>` | ⚑ **uno solo per l'app**: il filtro dei doppioni ricorda l'ultima condivisione |
| `PickImage` | `typedef PickImage = Future<String?> Function()` | |
| `pickImageProvider` | `Provider<PickImage>` | `ImagePicker().pickImage(source: gallery)?.path`; ⚑ selettore di sistema, nessun permesso su Android 13+ e iOS |
| `backupServiceProvider` | `Provider<BackupService>` | `BackupService(paths:, appVersion: appVersion)` |
| `LogoKey` | `typedef LogoKey = ({QrLogo logo, int background, int foreground})` | chiave dell'immagine del logo |
| `kLogoPixels` | `const int kLogoPixels = 256` | lato del logo disegnato (basta al PNG da 1024: 22% = 225 px) |
| `logoImageProvider` | `FutureProvider.autoDispose.family<ui.Image?, LogoKey>` | null per NoLogo; altrimenti `LogoRenderer.render(..., sizePx: kLogoPixels)`. ⚑ un provider e non un calcolo nel build: il disegno e' asincrono e la stessa immagine serve ad anteprima, pagina e PNG |
| `logoKeyOf` | `LogoKey logoKeyOf(QrStyle style)` | `(logo:, background:, foreground:)` |

⚑ Tutti i servizi stanno dietro un provider: sotto `flutter test` non c'e' nessun plugin e i test li
sostituiscono con doppi.

### `entitlement.dart` — il Pro

Copia di `apps/film_tracker/lib/app/entitlement.dart` con i valori di QR Me.

| Simbolo | Firma | Significato |
|---|---|---|
| `appVersion` | `const String appVersion = '1.0.0'` | nel backup, al server, in «Informazioni». **Va tenuta uguale al pubspec** |
| `installIdProvider` | `FutureProvider<InstallId>` | `InstallId.load(appId:)` |
| `purchaseGatewayProvider` | `Provider<PurchaseGateway>` | `store` → StorePurchaseGateway; `fake` → `FakePurchaseGateway.withProduct(proSku, formattedPrice: '1,99 €')` (parte **senza** Pro: in sviluppo si vede il paywall; il prezzo e' quello vero per lo screenshot di Apple) |
| `EntitlementView` | `@immutable class EntitlementView` — `const EntitlementView({required Entitlement entitlement, required bool busy, required bool storeAvailable, MicroProduct? product, MicroError? error})` | `bool get isPro`, `bool get isPending`, `==`/`hashCode` su entitlement, busy, storeAvailable, id e prezzo del prodotto, codice d'errore |
| `EntitlementNotifier` | `class EntitlementNotifier extends Notifier<EntitlementView>` | `EntitlementService get service`; `EntitlementView build()` crea il LicenseApiClient **solo** se `config.serverEnabled` e c'e' l'install id, crea EntitlementService (`appId: licenseAppId`, store `support/entitlement.json`), ascolta, **avvia `bootstrap()`**; privati `_sync()`, `static _snapshot(EntitlementService)` |
| `entitlementProvider` | `NotifierProvider<EntitlementNotifier, EntitlementView>` | |
| `isProProvider` | `Provider<bool>` | |
| `featureGateProvider` | `Provider<FeatureGate>` | `FeatureGate(limits: qrFeatureLimits, isPro:)` |

☠ Il bootstrap parte da solo: dimenticarlo vuol dire un'app che non si accorge di un acquisto gia' fatto.
☠ **Debito a cinque copie** (TrashCan, Full Freezer, Scorte Calore, Film Tracker, QR Me): va in `micro_core` in F7.

### `feature_limits.dart`

`const FeatureLimits qrFeatureLimits` — **tutte le 15 chiavi** di `FeatureKey.values` (il test di
coerenza le vuole tutte):

| Chiave | Limite | Cosa copre |
|---|---|---|
| `FeatureKey.fullHistory` | `count(freeMax: 5)` | cronologia: 5 righe **vere** |
| `FeatureKey.unlimitedEntities` | `count(freeMax: 1)` | preferiti: **uno** gratis |
| `FeatureKey.customCategories` | `locked()` | i cinque moduli speciali (compilare o modificare) |
| `FeatureKey.themeCustomization` | `locked()` | colori, forme, logo |
| `FeatureKey.imageExport` | `locked()` | condividere il QR come PNG (chiave nata con QR Me, F17.2a) |
| `FeatureKey.backupRestore` | `locked()` | **creare** il backup (il ripristino e' gratis) |
| `secondaryEntities`, `photos`, `statistics`, `csvExport`, `pdfReport`, `advancedWidget`, `notifications`, `multipleNotifications`, `calendarSync` | `open()` | QR Me non le vende |

⚑ Un QR **letto** con un modulo speciale (un Wi-Fi inquadrato) si mostra e si ri-mostra **gratis**:
e' un contenuto, non un modulo. ⚑ Se il proprietario volesse 0 preferiti gratis: una riga qui e il test.

### `paywall_config.dart`

| Funzione | Firma | Effetto |
|---|---|---|
| `buildQrPaywall` | `PaywallConfig buildQrPaywall(L l)` | titolo «QR Me Pro», sottotitolo «Un pagamento unico…», **6 benefici** in quest'ordine: stile (`themeCustomization`, palette), moduli (`customCategories`, wifi), preferiti (`unlimitedEntities`, star), cronologia (`fullHistory`, history), immagine (`imageExport`, ios_share), backup (`backupRestore`, cloud_download) |
| `showQrPaywall` | `Future<bool> showQrPaywall(BuildContext context, WidgetRef ref, {FeatureKey? highlight})` | `PaywallPage.show` con la funzione evidenziata; `true` se si esce col Pro |

⚑ **Sei righe e non le «quattro piu' backup» della spec**: preferiti e cronologia sono due chiavi e il
test vuole una riga per chiave limitata; due righe dicono anche meglio che la cronologia illimitata
vale «da adesso in poi». ⚑ Ordine: prima cio' che si vede (lo stile), poi il Wi-Fi per gli ospiti.

### `app_config.dart`

`const String licenseAppId = 'qrme'` (☠ non e' `appId`: il server usa id senza trattino basso).
`MicroAppConfig buildQrConfig()` → `MicroAppConfig.fromEnvironment(appId: 'qr_me', appName: 'QR Me',
proSku: 'qrme_pro_lifetime', seedColor: Color(0xFF3BD13B), fontFamily: 'PlusJakartaSans',
defaultBrightness: Brightness.dark)`.

### `qr_palette.dart` — interfaccia «A · Neon»

`const String kTitleFont = 'SpaceGrotesk'` (700).

`@immutable class QrPalette extends ThemeExtension<QrPalette>` — `const QrPalette({required Color
ground, required Color surface, required Color border, required Color borderFaint, required Color
ink, required Color inkMuted, required Color accent, required Color onAccent, required Color glow})`.

| Campo | `QrPalette.dark` (default) | `QrPalette.light` |
|---|---|---|
| `ground` (fondo pagina) | `#0E1110` | `#F4F6F2` |
| `surface` (schede, righe, campi) | `#151A16` | `#FFFFFF` |
| `border` (1 px) | `#2A332C` | `#D5DDD6` |
| `borderFaint` (separatori) | `#1E2620` | `#E6EBE6` |
| `ink` | `#EAF2EA` | `#121614` |
| `inkMuted` | `#8FA394` | `#5A6B5E` |
| `accent` | `#3BD13B` | **`#15803D`** |
| `onAccent` | `#06210B` | `#FFFFFF` |
| `glow` | `#733BD13B` (45%) | `#4D15803D` |

Membri: `static const QrPalette dark`, `static const QrPalette light`, `static QrPalette
of(BuildContext context)` (ripiego `dark`), `TextStyle get sectionLabel` (12/700, spaziatura 0,08,
`inkMuted`), `TextStyle title({double size = 24, Color? color})` (Space Grotesk 700, altezza 1,15),
`BoxDecoration card({double radius = 20})`, `QrPalette copyWith()` (restituisce se stessa), `QrPalette
lerp(ThemeExtension<QrPalette>? other, double t)` (scatto a meta').

`ThemeData withQrLook(ThemeData base, QrPalette p)` — cambia **anche il ColorScheme** (primary,
secondary, **tertiary** = accento; surface* = ground/surface; outline), scaffold/canvas/appBar/card/
bottomSheet/dialog, FilledButton pillola 46 testo 800, OutlinedButton pillola, TextButton verde, campi
con bordo 16 e fuoco verde 1,5, SegmentedButton, Switch, divider, snackbar; aggiunge `p` alle estensioni.

⚑ Come Film Tracker e non come Scorte Calore: i colori che Material ricaverebbe dal seme (un verde
spento, un terziario azzurro) stonerebbero. ⚑ **Il QR non prende questi colori**: sta sempre sul suo
pannello bianco (o sullo sfondo del suo stile); il nero attorno lo fa trovare a occhio e fotocamera.
☠ **Accento chiaro `#15803D`**: era `#16A34A` fino a F17.7 → 3,0:1 sul fondo e 3,3:1 col bianco sopra,
sotto il 4,5:1 di WCAG AA per il testo normale (visto sull'emulatore). `#15803D` da' 4,6:1 sul fondo e
5,0:1 col bianco. Il `#3BD13B` su bianco darebbe 2:1. Verificato da `palette_contrast_test.dart`.

### `labels.dart`

| Funzione | Firma | Effetto |
|---|---|---|
| `kindName` | `String kindName(L l, QrKind k)` | `kind_*` dagli ARB; switch esaustivo (un tipo nuovo non compila senza etichetta) |
| `kindIcon` | `IconData kindIcon(QrKind k)` | notes, link, wifi, person_outline, mail_outline, sms_outlined, call_outlined |
| `plainText` | `String plainText(L l, QrContent c, {bool withPassword = true})` | il contenuto **in chiaro**, una riga per campo (⚑ non il payload: una vCard e' illeggibile); Wi-Fi: «Rete: …» + «Password: …» (assente per le reti aperte), mascherata senza `withPassword` |
| `kMaskedPassword` | `const String kMaskedPassword = '••••••••'` | ⚑ sempre otto pallini: anche la lunghezza e' un indizio |
| `rowMeta` | `String rowMeta(L l, QrCode code)` | «tipo · 9 ott» (`DateFormat.MMMd`, ora locale) |

### `locale_resolution.dart`

`const List<Locale> kSupportedLocales = [Locale('en'), Locale('it')]` (inglese **primo**: e' il
ripiego di Flutter). `Locale resolveAppLocale(List<Locale>? deviceLocales, Iterable<Locale>
supported)` → `it` se **una qualunque** delle lingue del dispositivo e' italiano, altrimenti `en`
(ADR-011). ⚠ Il commento del file dice il contrario per `[de, it, en]` (§14).

---

## 7. Le rotte

Dichiarate in `lib/app/routes.dart` (`abstract final class Routes`), registrate in `GoRouter
buildRouter()` (`lib/app/app.dart`, **senza parametri**), `initialLocation: Routes.home`,
`errorBuilder` → pagina «Non trovato» (`_NotFoundPage`, testo `common_notFound`).

| Costante | Percorso | Pagina | Argomenti | Gate Pro | «Non trovato» se |
|---|---|---|---|---|---|
| `Routes.home` | `/` | `HomePage` | | | |
| `Routes.show` | `/show` | `QrDisplayPage.args(args)` | `extra: QrDisplayArgs` | | `extra` assente o di altro tipo |
| `Routes.qr` | `/qr/:id` | `QrDisplayPage.saved(id)` | `id` | | id non numerico (`_id` → -1); id inesistente → pagina «Questo QR non esiste piu'» |
| `Routes.scan` | `/scan` | `ScanPage` | | gratis | |
| `Routes.scanResult` | `/scan/result` | `ScanResultPage(args:)` | `extra: ScanResultArgs` | gratis | `extra` assente |
| `Routes.form` | `/form/:kind` (+ `?id=`) | `ProGate(customCategories, FormPage(kind:, id:))` | `kind` ∈ `kFormKinds`, `id` facoltativo | **Pro** | tipo sconosciuto o senza modulo (`text`, `url`); `?id=` non numerico (⚑ non un modulo nuovo che sembri una modifica) |
| `Routes.style` | `/style` | `ProGate(themeCustomization, StylePage(args:))` | `extra: StyleArgs` | **Pro** | `extra` assente |
| `Routes.saved` | `/saved` | `SavedPage` | | | |
| `Routes.history` | `/history` | `HistoryPage` | | | |
| `Routes.settings` | `/settings` | `SettingsPage` | | | |
| `Routes.pro` | `/pro` | `_PaywallRoutePage` (PaywallPage come pagina) | | | — (nessun codice la apre: si usa `showQrPaywall`, che evidenzia la funzione) |

Helper: `static String qrOf(int id)` → `/qr/<id>`; `static String formOf(QrKind kind, {int? id})` →
`/form/<kind>[?id=<id>]`. Funzioni di modulo in `app.dart`: `QrKind? formKindOf(String? name)`;
privata `int _id(GoRouterState s)` (`int.tryParse(...) ?? -1`, ☠ `tryParse` e non `parse`: un percorso
scritto a mano darebbe un'eccezione nel builder).

`const List<QrKind> kFormKinds = [wifi, contact, email, sms, phone]` (testo e link si scrivono nella home).

Argomenti (`routes.dart`):

| Classe | Costruttore | Campi |
|---|---|---|
| `QrDisplayArgs` | `const QrDisplayArgs({required this.content, required this.payload, required this.source, this.style = QrStyle.plain, this.qrId})` | `QrContent content`, `String payload` (la stringa esatta), `String source` (chiave di `QrSource`), `QrStyle style`, `int? qrId` (se gia' registrato) |
| `ScanResultArgs` | `const ScanResultArgs({required this.raw, required this.source})` | `String raw`, `String source` (`scanned` o `image`) |
| `StyleArgs` | `const StyleArgs({required this.display})` | `QrDisplayArgs display`; `int? get qrId` → `display.qrId` (se c'e', «Applica» scrive sulla riga) |

⚑ `ProGate` **sulla rotta** (F17.0 punto 11): un `push` diretto non deve aprire una pagina Pro gratis; i
pulsanti controllano comunque prima (`qr_actions.dart`) per mostrare subito il paywall.
⚑ **Nessun redirect**: ☠ un `push` che redireziona a «/» mette «/» due volte nella pila e go_router
mostra la sua pagina d'errore (Full Freezer).
⚑ `/scan/result` non e' figlio di `/scan`: e' un percorso a se'.
⚑ Percorsi fissati tutti insieme nel bootstrap (F17.2c), prima delle schermate scritte in parallelo.

### `QrMeApp` (`app.dart`)

`class QrMeApp extends ConsumerStatefulWidget` — `const QrMeApp({super.key})`. Stato privato:

- `late final GoRouter _router = buildRouter()`; `GlobalKey<ScaffoldMessengerState> _messenger` (i
  messaggi della condivisione arrivano fuori da ogni pagina); `ShareIntake? _intake`.
- `initState` → **dopo il primo frame** (il router deve essere montato prima di un `push`): crea
  `ShareIntake(inbox: shareInboxProvider, router: shareRouterProvider, goRouter: _router, onOutcome:
  _onShareOutcome)` e lo avvia; poi `_pruneOrphanLogos()`.
- `Future<void> _pruneOrphanLogos()`: aspetta **3 s** (⚑ chi arriva da una condivisione vuole il QR, non
  la pulizia del disco), poi `repository.pruneOrphanLogos()`; ☠ ogni errore → `MicroLog.e`, mai un crash.
- `void _onShareOutcome(ShareOutcome)`: snackbar per `noQrInImage` (`share_noQrInImage`) e
  `readerUnavailable` (`scan_readerUnavailable`); gli altri esiti non dicono niente.
- `dispose`: `_intake.dispose()`, `_router.dispose()`.
- `build`: `MaterialApp.router` con `withQrLook(MicroTheme.light(seed, fontFamily, displayFontFamily:
  kTitleFont, variant: fidelity), QrPalette.light)` e l'analogo scuro, `themeModeProvider`,
  `kSupportedLocales`, i quattro delegati, `localeListResolutionCallback: resolveAppLocale`.

### Chi apre l'app su una pagina

| Sorgente | Come arriva | Dove porta | Codice |
|---|---|---|---|
| Condividi testo/link (Android) | intent `SEND text/plain` | `push(/show)` con `source: shared` | `RsiShareInbox` → `ShareIntake` → `ShareRouter` |
| Condividi immagine (Android) | intent `SEND image/*` (`content://` con permesso temporaneo) | lettura del file → `push(/scan/result)` con `source: image`, o snackbar | idem |
| Condividi (iOS) | estensione → App Group → schema `ShareMedia-com.smp.qrme` | idem | idem (☐ mai provato su dispositivo) |

☠ **Il deep link di Flutter e' spento** (`flutter_deeplinking_enabled=false` nel manifest,
`FlutterDeepLinkingEnabled=false` in Info.plist): acceso, Flutter passerebbe a go_router l'URL
`ShareMedia-…` (o l'intent), che cercherebbe una rotta e mostrerebbe «Non trovato». Le condivisioni
le gestisce il plugin. **Nessuno schema URL proprio** dell'app (a differenza di Film Tracker).

---

## 8. `lib/services/`

### `qr_renderer.dart` — il QR disegnato

`class QrRenderer` — `const QrRenderer()`. Import di qr_flutter **con prefisso `qf`** (☠ qr_flutter
esporta `QrEyeShape` come il nostro dominio e, tramite `qr`, `QrCode` come la riga di Drift).

| Membro | Firma | Effetto |
|---|---|---|
| `quietModules` | `static const int quietModules = 4` | zona di rispetto per lato, in **moduli** (ISO/IEC 18004) |
| `logoFraction` | `static const double logoFraction = 0.22` | lato del logo rispetto al lato del codice |
| `choose` | `QrLevelChoice choose(String payload, QrStyle style)` | `QrCapacity.choose(payload, wantsLogo: style.hasLogo)`; le pagine la leggono **prima** di disegnare |
| `levelFor` | `QrErrorLevel levelFor(String payload, QrStyle style)` | ☠ **ArgumentError** se non sta in nessun QR (chi chiama deve aver guardato `choose`) |
| `widget` | `Widget widget({required String payload, required QrStyle style, required double size, ui.Image? logo, String? semanticsLabel})` | quadrato di lato `size`, zona di rispetto calcolata in moduli veri e **piena del colore di sfondo** (ColoredBox + Padding + CustomPaint); `Semantics(image: true)` |
| `png` | `Future<Uint8List> png({required String payload, required QrStyle style, int pixels = 1024, ui.Image? logo})` | PNG quadrato con zona di rispetto: per «Condividi immagine» e per la verifica |
| `painter` | `qf.QrPainter painter({required qf.QrCode qr, required QrStyle style, required double codeSide, ui.Image? logo})` | **IL** punto che traduce lo stile: `gapless: true`, occhi e moduli del colore di primo piano con la forma scelta, logo `embeddedImage` di lato `codeSide * 0,22`. Pubblico per i test |
| `errorCorrectLevelOf` | `static int errorCorrectLevelOf(QrErrorLevel level)` | → costanti `QrErrorCorrectLevel` L/M/Q/H |

Privata `({qf.QrCode qr, ui.Image? logo}) _layout(String payload, QrStyle style, ui.Image? logo)`:
il codice al livello scelto e il logo **solo se** `logoAllowed`.

⚑ **Un solo traduttore** stile → qr_flutter: se widget e PNG traducessero separatamente, l'immagine
condivisa prima o poi differirebbe da quella vista. ⚑ **`QrPainter` anche per il widget, non
`QrImageView`** (la spec diceva QrImageView): QrImageView vuole il logo come ImageProvider e lo ricarica
a ogni build con un FutureBuilder (un fotogramma vuoto a ogni cambio di stile), e il suo `padding` non
sa quanto e' grande un modulo. ⚑ **`gapless`**: con le fessure il colore di sfondo passa in righe
sottili che ad alcune fotocamere sembrano moduli chiari. ⚑ **Zona di rispetto mai trasparente**: sopra
una pagina scura la fotocamera non troverebbe il bordo chiaro.

### `logo_renderer.dart`

`class LogoRenderer` — `const LogoRenderer({this._icons})` (`Map<String, IconData>? _icons`,
default `kLogoIcons`: iniettabile).

| Membro | Firma | Effetto |
|---|---|---|
| `plateMargin` | `static const double plateMargin = 0.12` | margine del contenuto dentro il piatto, per lato |
| `photoSide` | `static const int photoSide = 512` | lato della foto salvata |
| `render` | `Future<ui.Image?> render(QrLogo logo, {required int backgroundArgb, required int sizePx, required ImageStore images, int foregroundArgb = 0xFF000000})` | null per NoLogo, icona sconosciuta, foto illeggibile (file sparito, backup senza immagini: `MicroLog.e`); testo e icona con TextPainter nel colore dei moduli, rimpiccioliti (×0,85, max 12 tentativi) finche' stanno nel riquadro interno; foto ritagliata al centro, rotonda (ovale) o quadrata con angoli 12% |
| `importPhoto` | `Future<Result<String>> importPhoto(Uint8List bytes, ImageStore images)` | in un **isolate** (`compute(_cropSquare)`): orientamento EXIF, ritaglio **quadrato al centro**, ridotta a 512, PNG; poi `images.importBytes(bucket: 'logos', maxLongSide: 512, thumbLongSide: 128, quality: 90)` (salvata **JPEG** da ImageStore). Restituisce `Ok(path relativo)` o `Err` |

Private: `_glyph`, `_photo`, `_plate` (quadrato arrotondato 18% o ovale, del colore di sfondo),
`static Uint8List _cropSquare(Uint8List bytes)`.

⚑ **Il piatto**: sotto il logo un quadrato (o cerchio) del colore di sfondo; senza, i moduli sotto il
logo si vedono a pezzi e la fotocamera prova a leggerli come dati. Con il piatto l'area e' «persa» e H la
recupera. ⚑ Icone ed emoji passano dalla stessa strada (un'icona Material e' un carattere del font
MaterialIcons). ⚑ **Il ritaglio rotondo non si cuoce nel file**: ImageStore salva JPEG senza
trasparenza (un cerchio diventerebbe un cerchio su nero); il file e' quadrato e `PhotoLogo.round` ritaglia
al disegno, cosi' si passa da quadrato a rotondo senza reimportare. ⚑ Decodifica **una volta sola**
all'import: una foto da 12 MP a ogni disegno costerebbe secondi. ⚑ Niente `image_cropper`: una
dipendenza nativa in meno (il pacchetto `image` c'era gia').

### `readability_check.dart` — lettura da file e verifica

| Simbolo | Firma | Effetto |
|---|---|---|
| `QrReaderUnavailable` | `class QrReaderUnavailable implements Exception` — `const QrReaderUnavailable(this.cause)`; `final Object cause`; `toString()` | il lettore **non c'e'** (libreria nativa di ZXing non caricabile: sotto `flutter test` sul PC, o piattaforma senza plugin). ⚑ diverso da «nessun QR trovato» |
| `QrImageReader` | `abstract interface class QrImageReader` — `Future<List<String>> read(String path)` | i testi non vuoti dei QR nel file, nell'ordine del lettore; vuota se nessuno; lancia `QrReaderUnavailable` se non disponibile. Interfaccia perche' i test non hanno il lettore nativo |
| `ZxingImageReader` | `class ZxingImageReader implements QrImageReader` — `const ZxingImageReader({this.tryInverted = true})`, `const ZxingImageReader.strict()` (`tryInverted = false`); `final bool tryInverted` | ZXing C++ via FFI (`flutter_zxing`), uguale su Android e iOS, tutto dentro l'app |
| `ZxingImageReader.maxSize` | `static const int maxSize = 1600` | lato massimo a cui ZXing riduce l'immagine. ⚑ piu' del default 768: uno screenshot 1080×2400 ridotto a 768 lascia un QR con moduli di 1-2 pixel; 1600 resta sotto il decimo di secondo |
| `read` | `Future<List<String>> read(String path)` | in un **`Isolate.run`** (decodifica e ricerca sono decine di ms di CPU, e la verifica gira a ogni pausa): `zx.readBarcodesImagePathString(path, DecodeParams(format: Format.qrCode, tryHarder: true, tryInverted:, tryDownscale: true, maxSize: 1600, isMultiScan: true))`, restituisce i testi dei codici validi. ☠ Un file che non e' un'immagine torna come `error` (log, lista vuota = «nessun QR»), non come eccezione; ArgumentError (`DynamicLibrary.open` fallito), UnsupportedError, MissingPluginException → `QrReaderUnavailable` |
| `Readability` | `enum Readability { readable, unreadable, unknown }` | `unknown` = «non verificato» (grigio), **non** illeggibile |
| `ReadabilityCheck` | `class ReadabilityCheck` — `ReadabilityCheck(this._reader, {this._renderer = const QrRenderer(), Future<Directory> Function()? tempDir})` | |
| `ReadabilityCheck.pixels` | `static const int pixels = 720` | ⚑ piu' piccolo del PNG condiviso: basta al lettore e gira a ogni pausa dell'utente |
| `check` | `Future<Readability> check({required String payload, required QrStyle style, ui.Image? logo})` | troppo lungo → `unreadable`; genera il PNG, lo scrive in `qrme_check_<µs>.png` nella cartella temporanea, lo rilegge e confronta **esattamente** con il payload; `QrReaderUnavailable` o qualunque altro guasto → `unknown`; il file temporaneo si cancella sempre |

⚑ **ZXing e non ML Kit/Vision**: la decodifica resta nell'app (regola «dati solo sul telefono»), e a
differenza di ML Kit **legge anche sull'emulatore e sul simulatore**: `QrReaderUnavailable` resta per
i guasti veri.
⚑ **Due lettori**: quello normale (`tryInverted: true`) per cio' che l'utente **vuole leggere**
(«Da immagine», condivisione); quello **severo** (`strict`) per la verifica di leggibilita'.
☠ Molti lettori (la fotocamera di diversi Android, varie app) non leggono un QR invertito: dire
«Leggibile» perche' ZXing ci riesce provando anche l'inverso sarebbe una promessa falsa; lo stile
invertito ha gia' il suo avviso da `Contrast.inverted`.
⚑ E' la difesa vera contro i QR «carini ma illeggibili»: il contrasto e' euristica, questo e' il test.
⚑ **Confronto esatto**: un QR che si legge come un'altra stringa e' peggio di uno che non si legge.
⚑ **Solo QR** (`Format.qrCode`) come la fotocamera.

### `screen_boost.dart`

`class ScreenBoost` — `const ScreenBoost()`; `Future<void> enable()` (luminosita' **dell'app** a 1 +
WakelockPlus.enable); `Future<void> disable()` (reset della luminosita' dell'app + WakelockPlus.disable);
privata `static Future<void> _quiet(String what, Future<void> Function() action)`.
⚑ Luminosita' **dell'app** e non di sistema: nessun permesso, e se l'app muore il sistema torna da solo
a quella dell'utente. ⚑ **Errori ingoiati e loggati**: un telefono che non permette di cambiare la
luminosita' deve mostrare il QR lo stesso; `enable`/`disable` non lanciano mai. Classe concreta (i test
la sostituiscono con `implements`).

### `share_router.dart`

`enum ShareOutcome { shownText, scannedImage, noQrInImage, readerUnavailable, duplicate, nothing }`.

`class ShareRouter` — `ShareRouter({required this._reader, DateTime Function()? clock})`:

| Membro | Firma | Effetto |
|---|---|---|
| `duplicateWindow` | `static const Duration duplicateWindow = Duration(seconds: 2)` | |
| `handleAll` | `Future<ShareOutcome> handleAll(List<SharedPayload> payloads, GoRouter router)` | **il primo testo**, altrimenti la prima immagine; lista senza nessuno dei due → `nothing` |
| `handle` | `Future<ShareOutcome> handle(SharedPayload payload, GoRouter router)` | payload **uguale** al precedente entro 2 s → `duplicate`; SharedText → `QrDecoder.decodeTyped` → `push(/show, QrDisplayArgs(payload: QrEncoder.encode(c), source: shared))`; SharedImage → `reader.read(path)` → vuota `noQrInImage`, non disponibile `readerUnavailable`, altrimenti `push(/scan/result, ScanResultArgs(raw: primo, source: image))` |

`class ShareIntake` — `ShareIntake({required this.inbox, required this.router, required this.goRouter,
this.onOutcome})`; campi `final ShareInbox inbox`, `final ShareRouter router`, `final GoRouter
goRouter`, `final void Function(ShareOutcome outcome)? onOutcome`:

| Metodo | Firma | Effetto |
|---|---|---|
| `start` | `Future<void> start()` | ascolta `inbox.incoming`; poi `initial()` **una volta**, **subito `reset()`**, e instrada; errori del plugin → `MicroLog.e` (l'app si apre lo stesso) |
| `dispose` | `Future<void> dispose()` | cancella l'ascolto |

Privata `_route(List<SharedPayload>)` → `router.handleAll` → `onOutcome`.

☠ **Doppioni** (F17.1.11 punto 5): con l'app aperta `initial` e `incoming` possono consegnare lo stesso
elemento → `reset()` subito dopo `initial()` **e** il filtro dei 2 s; senza, due pagine del QR una
sopra l'altra. ⚑ `decodeTyped` e non `decode`: chi condivide «esempio.it» intende il sito.
⚑ Separato dal widget dell'app per testarlo con FakeShareInbox e un router vero.

### `content_actions.dart`

`class ContentActions` — `const ContentActions({this._launcher})` (`Future<bool> Function(Uri uri)?`,
iniettabile: i test verificano **quale** URI si apre).

| Membro | Firma | Effetto |
|---|---|---|
| `uriFor` | `static Uri? uriFor(QrContent content)` | link → l'URI; telefono → `tel:<normalizzato>`; email → `mailto:` con `encodeComponent`; SMS → **`sms:<numero>?body=`**; testo, Wi-Fi, contatto → null (si copiano) |
| `open` | `Future<bool> open(QrContent content)` | `false` se non c'e' niente da aprire o nessuna app sa farlo (anche se il lanciatore lancia); senza lanciatore `launchUrl(mode: externalApplication)` |

⚑ **`sms:` per aprire, `SMSTO:` nel QR**: SMSTO e' la forma che le fotocamere capiscono, `sms:?body=`
quella che le app dei messaggi accettano da un link. ⚑ **Sempre app esterna**: QR Me non e' un browser,
l'utente deve vedere la barra degli indirizzi del suo. ☠ Su Android 11+ senza le `<queries>` del
manifest il sistema risponde sempre «nessuna app».

---

## 9. `lib/features/` — le schermate

### Azioni condivise — `features/common/qr_actions.dart`

⚑ **Il controllo Pro sta nella funzione**, non solo nel pulsante: la stessa azione si raggiunge da piu'
pagine, e un controllo dimenticato in una regalerebbe la funzione. ⚑ Comprato il Pro dal paywall
aperto da un'azione, **si prosegue** (chi ha toccato il pulsante vuole la funzione).

| Funzione | Firma | Effetto |
|---|---|---|
| `historyKeep` | `int? historyKeep(FeatureGate gate)` | Pro → null; gratis → `freeLimitOf(fullHistory)` = 5 |
| `recordIfEnabled` | `Future<int?> recordIfEnabled(WidgetRef ref, {required QrContent content, required String payload, required String source, QrStyle style = QrStyle.plain})` | **solo con la cronologia accesa**: `recordShown` + `pruneHistory(keep: historyKeep)`; restituisce l'id o null; ogni errore → log e null (un QR che non si registra si mostra lo stesso) |
| `saveAsFavorite` | `Future<int?> saveAsFavorite(BuildContext context, WidgetRef ref, {required QrDisplayArgs args, int? existingId})` | conta i preferiti; oltre il limite → paywall (`unlimitedEntities`) e null; chiede il nome (`askTitle`, iniziale `autoTitle`); se non c'e' una riga (cronologia spenta) la **crea** con `recordShown`; poi `saveAsFavorite`; snack «Salvato» |
| `askTitle` | `Future<String?> askTitle(BuildContext context, {required String title, required String initial})` | dialogo con campo `title_field` (max 80) e `title_ok`; null se annullato o vuoto |
| `openStyle` | `Future<QrStyle?> openStyle(BuildContext context, WidgetRef ref, QrDisplayArgs args)` | senza Pro → paywall (`themeCustomization`), poi prosegue solo se comprato; `push<QrStyle>(/style, StyleArgs(display: args))`, restituisce lo stile applicato |
| `openEditForm` | `Future<void> openEditForm(BuildContext context, WidgetRef ref, {required QrKind kind, required int id})` | Pro `customCategories`; `push(/form/<kind>?id=<id>)` |
| `openNewForm` | `Future<void> openNewForm(BuildContext context, WidgetRef ref, QrKind kind)` | Pro `customCategories`; ⚑ senza Pro paywall subito e non la pagina col lucchetto |
| `shareQrImage` | `Future<void> shareQrImage(BuildContext context, WidgetRef ref, {required QrDisplayArgs args, required String title})` | Pro `imageExport`; logo dal provider, `QrRenderer.png` 1024, scritto con AtomicFile in `exports/qr-me-<ms>.png`, `SharePlus.instance.share(ShareParams(files: [XFile(.., mimeType: 'image/png')], subject: title))`; errore → snack `display_shareFailed` |
| `copyContent` | `Future<void> copyContent(BuildContext context, QrContent content)` | `plainText` **con** password (chi tocca Copia la vuole) negli appunti; snack «Copiato» |
| `copyText` | `Future<void> copyText(BuildContext context, String text)` | idem per un testo qualsiasi |
| `openContent` | `Future<void> openContent(BuildContext context, WidgetRef ref, QrContent content)` | `ContentActions.open`; false → snack `result_noApp` |
| `openPro` | `void openPro(BuildContext context, WidgetRef ref, FeatureKey key)` | paywall generico con evidenza |

Private: `_TitleDialog`/`_TitleDialogState`. ☠ **Un widget con stato e non un controller creato e
chiuso in `askTitle`**: il dialogo si ridisegna ancora durante l'animazione di chiusura e un controller
gia' chiuso fa esplodere il campo («A TextEditingController was used after being disposed»).

### Mattoni Neon — `features/common/neon.dart`

| Widget | Costruttore | Cosa disegna |
|---|---|---|
| `NeonButton` | `const NeonButton({required String label, required VoidCallback? onPressed, IconData? icon, bool expanded = true, Key? key})` | FilledButton pillola 46 con alone `glow` **solo se attivo** (⚑ un pulsante spento che brilla sembra premibile); ☠ `minimumSize: Size(64, 46)` finita (il tema di micro_core la dava infinita e un pulsante non espanso in una Row non si disegnava) |
| `SectionLabel` | `const SectionLabel(String text, {Widget? trailing, Key? key})` | etichetta MAIUSCOLA con azione a destra («Vedi tutti») |
| `QrPanel` | `const QrPanel({required Color background, required Widget child, double padding = 22, bool glow = true, Key? key})` | il pannello del QR: colore di sfondo dello stile, raggio 26, alone verde. ⚑ anche nel tema scuro |
| `QrThumb` | `const QrThumb({required QrCode code, double size = 34, Key? key})` | miniatura 34×34 raggio 8: il codice **vero, senza logo**; troppo lungo → quadrato pieno |
| `QrRow` | `const QrRow({required QrCode code, required String meta, VoidCallback? onTap, Widget? trailing, Key? key})` | riga di elenco: miniatura, titolo 15/700, meta 12 grigia |
| `ActionTile` | `const ActionTile({required IconData icon, required String label, required VoidCallback? onTap, bool locked = false, Key? key})` | tessera alta 72 con pallino verde o **lucchetto** (`ValueKey('lock')`) se Pro mancante; ⚑ pallino e lucchetto nello stesso spazio alto 9 |

### Il lucchetto — `features/common/pro_gate.dart`

`class ProGate extends ConsumerWidget` — `const ProGate({required FeatureKey feature, required Widget
child, bool Function(FeatureGate gate)? allowed, Key? key})`. Con il Pro mostra `child`; senza,
Scaffold con lucchetto, `pro_locked` e pulsante che apre il paywall; si ridisegna da solo appena
arriva il Pro. Copia di Film Tracker (nata in Full Freezer). `allowed` (limiti numerici) non e' usato
in QR Me. ☠ Non un redirect (§7).

### Home — `features/home/home_page.dart`

`class HomePage extends ConsumerStatefulWidget` — `const HomePage({super.key})`.
Costanti: `const int kHomeFavorites = 3`, `const int kHomeRecents = 5`.

Dall'alto: titolo «QR **Me**» (Me in verde), ingranaggio → `/settings` (`home_settings`); **Scrivi o
incolla** (`home_text`, 2–5 righe); **Incolla** (`home_paste`: legge gli appunti, vuoti → snack; su iOS
il sistema mostra il suo avviso, e' normale) e **Mostra QR** (`home_show`, spento con testo vuoto o
solo spazi) → `QrDecoder.decodeTyped` → `push(/show, source: typed)`; **Leggi un QR** (`home_scan`, riga
alta 64) → `/scan`; **Moduli**: cinque chip (`form_chip_<kind>`) con `ProBadge` senza Pro →
`openNewForm`; **Preferiti** (primi 3, «Vedi tutti» → `/saved`); **Recenti** (primi 5, «Vedi tutti»
`home_seeHistory` → `/history`) e, **senza Pro e con la cronologia accesa**, la riga
`home_freeHistory` («La cronologia gratuita tiene gli ultimi 5 QR.» + link al Pro); **stato vuoto**
`home_empty` se non ci sono ne' preferiti ne' cronologia.
⚑ Lo stato vuoto e' **la spiegazione dell'app** («Condividi un link o un testo da qualunque app e
scegli QR Me…»): chi la apre dall'icona deve capire che il modo giusto e' la condivisione.
Private: `_HomePageState` (`_paste`, `_show`), `_ScanRow`, `_FormChip`, `_EmptyHint`.

### IL QR — `features/display/qr_display_page.dart`

`class QrDisplayPage extends ConsumerWidget` — due costruttori: `const QrDisplayPage.args(QrDisplayArgs
this.args, {super.key})` (`/show`, contenuto in memoria) e `const QrDisplayPage.saved(int this.id,
{super.key})` (`/qr/:id`, segue la riga con `qrCodeProvider`: dato → corpo; null o errore →
`_Missing` «Questo QR non esiste piu'»; caricamento → rotellina). Campi `final QrDisplayArgs? args`,
`final int? id`.
Funzione: `QrDisplayArgs argsOfRow(QrCode row)` (contenuto, payload, source, stile, `qrId`).

Corpo (`_DisplayBody` / `_DisplayBodyState`):
- **Luminosita'**: `ScreenBoost.enable()` in `initState`; `AppLifecycleListener(onHide: disable,
  onShow: enable)`; `disable()` in `dispose`. ☠ Solo in dispose, uscendo col tasto Home il telefono
  resterebbe a luminosita' piena finche' non si riapre l'app.
- **Cronologia** (`_record`, dopo il primo frame): con un id (riga salvata o `args.qrId`) → `touch`;
  altrimenti, se il contenuto sta in un QR, `recordIfEnabled` e l'id ricevuto diventa `_id`.
- **Troppo lungo** → MicroEmptyState «Troppo lungo per un QR» con «N caratteri: … circa 2.900»
  (invece dell'eccezione di qr_flutter).
- **Pannello** `qr_panel`: lato = `max(120, min(larghezza, altezza disponibili) - 32)`, codice di lato
  pannello − 44 (padding 22), logo da `logoImageProvider`, etichetta semantica `display_semantics`.
- Titolo (riga salvata o `autoTitle`, 2 righe), contenuto in chiaro `_ContentLine` (`content_text`):
  **Wi-Fi protetto → password mascherata** con l'occhio `toggle_password`; altri → 3 righe, tocca per
  espandere. Note gialle `_Note`: logo tolto (`display_logoDropped`), QR fitto (`display_dense`).
- **Azioni** `_Actions` (una Row di `ActionTile`): `action_save` (gia' preferito → snack «gia' nei
  preferiti»; altrimenti `saveAsFavorite(existingId: args.qrId)`), `action_style` (lucchetto senza
  `themeCustomization`; `openStyle` → lo stile restituito vale per la pagina), `action_image`
  (lucchetto senza `imageExport`; `shareQrImage`), `action_copy`, e **solo per un preferito con
  modulo** `action_edit` (lucchetto senza `customCategories`; `openEditForm`).
⚑ Stato locale: `_id`, `_savedHere` (preferito salvato da qui, per `/show` che non segue il database),
`_style` (stile applicato da qui), `_showPassword`, `_expanded`.
⚑ **Pagina scura, pannello chiaro**: abbaglia meno di una pagina tutta bianca e la fotocamera trova il
bordo chiaro. ⚑ **Password nascosta**: il QR si mostra a un ospite, la password scritta sotto non deve
leggerla chi passa.

### Lettura — `features/scan/scan_page.dart` **[SCANNER]**

`class ScanPage extends ConsumerStatefulWidget` — `const ScanPage({super.key})`;
`static const double cropPercent = 0.8` (la parte del fotogramma in cui ZXing cerca, frazione del lato
corto; ⚑ piu' larga del mirino disegnato: con l'anteprima a riempimento il fotogramma deborda dallo
schermo, quindi la zona letta e' gia' piu' grande del mirino, e il margine perdona un QR storto).

Fotocamera e decodifica sono il **`ReaderWidget` di `flutter_zxing`** (plugin `camera`: CameraX su
Android, AVFoundation su iOS; il widget crea il `CameraController` con `enableAudio: false`), con:
`codeFormat: Format.qrCode`, `tryInverted: true` (⚑ QR chiari su scuro esistono: adesivi, schermi in
tema scuro), `cropPercent: ScanPage.cropPercent`, `resolution: ResolutionPreset.high`,
`lensDirection: CameraLensDirection.back`, `scanDelaySuccess: Duration.zero` (la pagina smonta la
fotocamera da se'), `scanDelay: 150 ms` (fra un fotogramma senza QR e il successivo). ⚑ Del widget si
usano **solo anteprima e decodifica**: `showScannerOverlay`, `showFlashlight`, `showGallery`,
`showToggleCamera` tutti `false` (doppioni dei nostri: mirino, torcia nella barra, «Da immagine»).

Stato di `_ScanPageState`:

| Campo | Tipo | Significato |
|---|---|---|
| `_cameraOn` | `bool` | `ReaderWidget` montato. ⚑ `false` mentre e' aperta la pagina del risultato: smontarlo **spegne davvero** la fotocamera (coperta, continuerebbe a leggere fotogrammi e a scaldare il telefono); al ritorno si rimonta e riparte |
| `_attempt` | `int` | chiave (`ValueKey`) del `ReaderWidget`: cambia a ogni «Riprova», che cosi' richiede il permesso e riapre la fotocamera da capo |
| `_camera` | `CameraController?` | il controller consegnato da `onControllerCreated`, per la torcia |
| `_error` | `Object?` | perche' la fotocamera non e' partita; `null` se va o sta partendo |
| `_torchUsable`, `_torchOn` | `bool` | ⚑ la torcia si scopre solo provandola (emulatore e frontali non l'hanno): al primo errore di `setFlashMode` il pulsante sparisce |
| `_handling` | `bool` | ☠ il lettore consegna la stessa lettura piu' volte (e una in volo puo' arrivare dopo lo smontaggio): senza, piu' pagine del risultato una sopra l'altra |

| Metodo | Firma | Effetto |
|---|---|---|
| `initState` | `void initState()` | lancia `_checkCameras` |
| `_checkCameras` | `Future<void> _checkCameras()` | ☠ `availableCameras()` vuota → `_error = StateError('nessuna fotocamera')`: senza fotocamere il `ReaderWidget` non segnala nulla e resterebbe nero per sempre. Se `availableCameras` lancia, solo log (l'errore vero arriva da `onControllerCreated`) |
| `_onController` | `void _onController(CameraController? controller, Exception? error)` | callback `onControllerCreated`: salva il controller, spegne lo stato torcia; con `error` lo logga e lo mette in `_error` |
| `_toggleTorch` | `Future<void> _toggleTorch()` | `setFlashMode(FlashMode.torch / FlashMode.off)`; errore → `_torchUsable = false` |
| `_showResult` | `Future<void> _showResult(String raw, String source)` | `source` e' una chiave di `QrSource`. Smonta la fotocamera (`_cameraOn = false`), `push(Routes.scanResult, ScanResultArgs(raw:, source:))`, al ritorno la rimonta e azzera `_handling` |
| `_onScan` | `void _onScan(Code code)` | callback `onScan`: ignorata se `_handling`, fotocamera smontata o testo vuoto; poi `_handling = true`, `HapticFeedback.lightImpact()`, `_showResult(raw, QrSource.scanned)` |
| `_fromImage` | `Future<void> _fromImage()` | **Da immagine** (`scan_fromImage`): `pickImageProvider` → `qrImageReaderProvider.read` → `QrReaderUnavailable`: snack d'errore `scan_readerUnavailable`; vuota: snack «Nessun QR in questa immagine»; altrimenti `_showResult(values.first, QrSource.image)`. Resta usabile anche senza fotocamera |
| `_retry` | `void _retry()` | azzera errore, controller e torcia, `_attempt++`, ricontrolla le fotocamere |
| `build` | | AppBar nera (☠ titolo bianco esplicito `p.title(color: Colors.white)`: il colore del tema vince su `foregroundColor` e nel tema chiaro era nero su nero, F17.7) con la torcia solo se nessun errore, controller pronto, `_torchUsable` e fotocamera posteriore; corpo: `_ScanError` se c'e' un errore, altrimenti il `ReaderWidget` (se `_cameraOn`); sopra, mirino e «Inquadra il QR» **solo senza errore** (⚑ sopra lo stato d'errore gli angoli incorniciavano il messaggio); in basso «Da immagine» sempre |

- `_ScanError` (`const _ScanError({required Object error, required VoidCallback onRetry})`,
  `static bool isDenied(Object error)` = `error is CameraException && error.code.startsWith('CameraAccessDenied')`:
  copre `CameraAccessDenied` di Android CameraX e iOS e `CameraAccessDeniedWithoutPrompt` di iOS;
  ⚑ per prefisso perche' i codici sono stringhe dei plugin, non un enum): permesso negato → «La
  fotocamera e' spenta per QR Me» con «Apri le impostazioni» (`app-settings:`) **solo su iOS**, su
  Android «Riprova» (⚑ aprire i permessi dell'app su Android richiederebbe `permission_handler` per un
  pulsante; e se Android ha fissato il rifiuto, «Riprova» ritorna allo stesso stato: provato); altri
  errori, nessuna fotocamera → «La fotocamera non e' partita» con «Riprova».
- `_Viewfinder` (`const _Viewfinder({required Color color})`, `static const double sideFraction = 0.66`):
  quattro angoli dell'accento attorno a un quadrato centrale alzato di 40 px. ⚑ `sideFraction` minore di
  `ScanPage.cropPercent`: la zona in cui ZXing cerca deve contenere il mirino.
⚑ **Solo QR**: i codici a barre dei prodotti farebbero scattare letture accidentali. ⚑ Gratis.
⚑ Provato sull'emulatore il 2026-10-09: anteprima della scena virtuale, mirino, torcia accesa e spenta,
ritorno dal risultato con la fotocamera che riparte, permesso negato. ☐ La lettura **dal vivo** di un
QR non e' provata (la scena virtuale non ne mostra): su telefono vero.

### Risultato della lettura — `features/scan/scan_result_page.dart`

`class ScanResultPage extends ConsumerStatefulWidget` — `const ScanResultPage({required ScanResultArgs
args, super.key})`. Stato: `late final QrContent _content = QrDecoder.decode(args.raw)` (⚑ `decode`, non
`decodeTyped`), `_id`, `_saved`; `_display` getter → QrDisplayArgs con `payload: raw` (⚑ la stringa
**letta**, senza ricodificarla: nessuna perdita).
- Dopo il primo frame: `recordIfEnabled(source: scanned | image)`.
- Intestazione: icona e nome del tipo (`result_kind`). Corpo `_Body`: per un link il **dominio grande
  in verde** (`result_domain`) e l'indirizzo intero sotto; per gli altri `plainText` selezionabile
  (`result_text`).
- Azioni del tipo: link → **Apri** (`result_open`) + Copia link; telefono → Chiama + Copia; email →
  Scrivi + Copia; SMS → Manda + Copia; Wi-Fi protetto → **Copia password**; contatto e testo → Copia.
- Sempre: **Mostra come QR** (`result_show`, gratis) → `/show`; **Rigenera con stile** (`result_style`,
  `ProBadge` senza Pro) → `openStyle`; **Salva** (`result_save`) → `saveAsFavorite(existingId: _id)`.
⚑ **Un link letto non si apre mai da solo**: si mostra con il dominio in evidenza (un adesivo sopra il
QR vero al parcheggio). ⚑ **Connettersi al Wi-Fi da qui non si fa**: su Android 10+ serve un'API di
suggerimento con conferma, su iOS un'entitlement Hotspot; la fotocamera di sistema lo fa meglio.
⚠ **Difetto aperto** (§14): lo stile restituito da «Rigenera con stile» viene **ignorato**.

### Moduli — `features/forms/`

`class FormPage extends ConsumerStatefulWidget` — `const FormPage({required QrKind kind, int? id,
super.key})` (dietro `ProGate(customCategories)` sulla rotta).
- Con `id`: legge la riga **una volta** (`byId`); inesistente → «non trovato»; riga di un altro tipo →
  modulo vuoto (⚑ non si apre col modulo sbagliato).
- Anteprima dal vivo `_Preview` in alto: vuota (`form_preview_empty`, «Compila il modulo…») finche' il
  contenuto non e' valido, poi `form_preview` 168 px **con i colori del preferito ma senza logo**
  (l'anteprima e' per il contenuto); troppo lungo → testo d'errore e pulsante spento.
- Pulsante `form_submit`: nuovo → «Mostra QR»: `recordIfEnabled(source: form)` → `pushReplacement(/qr/<id>)`,
  **con la cronologia spenta** `pushReplacement(/show)` dalla memoria; modifica → «Salva»:
  `updateContent` (titolo e stile restano) e `pop`.

`abstract class QrFormWidget<T extends QrContent> extends StatefulWidget` — `const
QrFormWidget({required this.onChanged, this.initial, super.key})`; `final T? initial`; `final
ValueChanged<QrContent?> onChanged` (contenuto **valido** o null). Ogni modulo emette dopo il primo
frame e a ogni modifica.

| Modulo | Costruttore | Campi (chiavi) | Valido se | Note |
|---|---|---|---|---|
| `WifiForm` | `const WifiForm({required super.onChanged, super.initial, super.key})` | `wifi_ssid`, `wifi_security` (WPA/WEP/Nessuna), `wifi_password` (solo se protetta, nascosta con l'occhio), `wifi_hidden` | SSID non vuoto e, se protetta, password non vuota | ⚑ SSID e password **non si rifilano** (uno spazio in coda puo' far parte del nome) |
| `ContactForm` | `const ContactForm({…})` | `contact_name`, `contact_phone`, `contact_email`, azienda, sito, nota | nome; telefono ed email facoltativi ma validi se scritti | tutto rifilato; vuoti → null |
| `EmailForm` | `const EmailForm({…})` | `email_to`, oggetto, testo | destinatario email valido | oggetto e testo non rifilati |
| `SmsForm` | `const SmsForm({…})` | `sms_number`, testo | numero valido | |
| `PhoneForm` | `const PhoneForm({…})` | `phone_number` | numero valido | |

`form_fields.dart`:

| Simbolo | Firma | Effetto |
|---|---|---|
| `kEmailPattern` | `final RegExp kEmailPattern` | `^[^@\s]+@[^@\s]+\.[^@\s]+$` |
| `requiredText` | `String? requiredText(L l, String v)` | vuoto dopo trim → «Obbligatorio» |
| `emailText` | `String? emailText(L l, String v, {bool required = true})` | |
| `phoneText` | `String? phoneText(L l, String v, {bool required = true})` | normalizzato, `^\+?[0-9]{3,}$` |
| `QrTextField` | `const QrTextField({required TextEditingController controller, required String label, String? Function(String value)? validator, TextInputType? keyboardType, int maxLines = 1, bool obscure = false, Widget? suffix, TextCapitalization capitalization = TextCapitalization.none, Key? key})` | TextFormField con errore dopo il primo tocco; nascosto → niente autocorrect e suggerimenti |

⚑ **Un validatore, due usi**: il campo (errore in linea) e il modulo (contenuto valido o null) usano la
stessa funzione: l'anteprima non puo' mostrare un QR che il campo dice sbagliato.

### Stile — `features/style/style_page.dart`

`class StylePage extends ConsumerStatefulWidget` — `const StylePage({required StyleArgs args,
super.key})` (dietro `ProGate(themeCustomization)`).
Costanti: `const List<int> kSwatches` (12: nero, bianco, `#1B2A4A`, `#1565C0`, `#00796B`, `#2E7D32`,
`#3BD13B`, `#C62828`, `#6A1B9A`, `#E65100`, `#5D4037`, `#FFF3C4`; ⚑ scuri e chiari insieme: la scelta
sbagliata la segnalano gli avvisi invece di impedirla), `const Duration kReadabilityDelay =
Duration(milliseconds: 600)`.
- **Anteprima fissa in alto** (pannello 150 px) e riga di verifica `readability`; si scorre solo il
  resto (⚑ sull'emulatore, scegliendo il logo in fondo, l'anteprima era fuori schermo).
- Avvisi: `warn_contrast` (rapporto < 3, rosso), `warn_inverted` (giallo), logo tolto (giallo).
- Primo piano e sfondo: tondini `fg_<argb hex>` / `bg_<argb hex>` (es. `fg_ffffffff`) e campo
  esadecimale (`fg_hex`, `bg_hex`: `#RRGGBB` o `RRGGBB`, **sempre opaco**); forma moduli e occhi
  (quadrati/rotondi); **Logo** (`LogoPicker`); «Ripristina» (spento se gia' semplice); **Applica**
  (`style_apply`): se `qrId` → `updateStyle`, poi `pop(stile)`.
- **Verifica**: a ogni modifica riparte dopo **600 ms** dall'ultima; ☠ numero di sequenza: una verifica
  lenta partita prima non sovrascrive l'esito di quella dopo. Stati: «Verifico…» (null), Leggibile,
  Non riesco a leggerlo, «Non verificato su questo dispositivo» (grigio). ⚑ Il segno sta **solo
  nell'icona**: niente ✓/⚠ nei testi.
Private: `_StylePageState` (`_update`, `_scheduleCheck`, `_check`, `_apply`), `_ReadabilityRow`,
`_Warning`, `_ColorRow`, `_HexField` (`static int? parse(String s)`, non sovrascrive il campo mentre
l'utente scrive un colore valido diverso).

### Logo — `features/style/logo_picker.dart`

`const Map<String, IconData> kLogoIcons` — i 24 id di `kLogoIconIds` → wifi, phone, email, sms, home,
work, favorite (heart), star, shopping_bag (shop), restaurant, local_cafe (coffee), music_note,
photo_camera, link, person, group, event, place (location), directions_car, pets, school, info,
card_giftcard (gift), payment. ⚑ L'icona dietro un id si puo' cambiare; l'id no.

`class LogoPicker extends ConsumerStatefulWidget` — `const LogoPicker({required QrLogo logo, required
ValueChanged<QrLogo> onChanged, super.key})`. Segmenti `logo_source` (Nessuno, Foto, Icona, Testo, enum
privato `_Source`): Nessuno → subito NoLogo; **Foto** → galleria → `LogoRenderer.importPhoto` (rotellina)
→ PhotoLogo, poi interruttore «rotondo»; errore → snack; **Icona** → griglia `logo_icon_<id>`; **Testo**
→ campo `logo_text` con contatore in **grafemi** `n/3` (⚑ `maxLength` conterebbe i code unit e
taglierebbe un'emoji a meta'), emette solo se valido.
☠ `_SegmentLabel` (FittedBox, una riga): al 130% di testo «Nessuno» andava a capo a meta' parola
(«Nessun / o», F17.7). Private: `_LogoPickerState`, `_IconChoice`, `_SegmentLabel`.

### Preferiti — `features/saved/saved_page.dart`

`class SavedPage extends ConsumerWidget` — `const SavedPage({super.key})`. Elenco dei preferiti
(`QrRow` → `/qr/<id>`), menu `_Menu` (enum privato `_RowAction { rename, unfavorite, delete }`):
**Rinomina** (`askTitle`), **Togli dai preferiti** (`unfavorite` + `pruneHistory(keep:)`; ⚑ non e'
una cancellazione, niente conferma; nel gratis sopravvive solo se e' fra gli ultimi 5), **Elimina**
(con MicroConfirmSheet). Senza Pro, in fondo, «Il piano gratuito tiene 1 preferito…» → paywall.
Stato vuoto, errore («common_loadFailed»), caricamento.

### Cronologia — `features/history/history_page.dart`

`class HistoryPage extends ConsumerWidget` — `const HistoryPage({super.key})`. Riquadro «cronologia
spenta» con link alle impostazioni se spenta; righe con «×» (elimina senza conferma); cestino
nell'AppBar → conferma → `clearHistory`; senza Pro la nota «La cronologia gratuita tiene gli ultimi 5.
Con Pro tutti, da adesso in poi.» → paywall. ⚑ Nel gratis non c'e' niente di nascosto da rivelare: le
righe oltre 5 sono gia' cancellate.

### Impostazioni — `features/settings/`

`class SettingsPage extends ConsumerWidget` — `const SettingsPage({super.key})`. Dall'alto:
**Cronologia** (⚑ per prima: chi condivide cose riservate deve trovare subito come spegnerla):
interruttore `settings_history`, «Cancella la cronologia» `settings_clearHistory` con conferma; **Pro**
(riga intera toccabile → paywall; col Pro «attivo»), **Ripristina acquisti** (testo Apple/Google
secondo `defaultTargetPlatform`); `DataSection`; **App**: tema (foglio Scuro/Chiaro/Sistema),
**Informativa** (dialogo con `settings_privacyBody`), **Informazioni** (versione `appVersion`).
Privata `static Future<void> _info(BuildContext, String title, String body)`.

`data_section.dart`:

| Simbolo | Firma | Effetto |
|---|---|---|
| `DataSection` | `class DataSection extends ConsumerWidget` — `const DataSection({super.key})` | «I tuoi dati»: `data_backup` (ProBadge senza Pro; ⚑ **visibile anche senza Pro**, nasconderla non farebbe sapere che esiste) e `data_restore` |
| `createBackup` | `Future<void> createBackup(BuildContext context, WidgetRef ref)` | Pro `backupRestore` (senza → paywall); `BackupService.createBackup(QrBackupSource, label: «QR Me», includeImages: true)` con dialogo d'attesa; `shareBackup` |
| `restoreBackup` | `Future<void> restoreBackup(BuildContext context, WidgetRef ref)` | **gratis**: sceglie il file, `inspect` (schema diverso da `qr_me` → errore), foglio con riepilogo «N preferiti, M in cronologia» e **Sostituisci tutto / Aggiungi**, poi `restore` |

Privata `Future<T> _withProgress<T>(BuildContext, String message, Future<T> Function() work)` (dialogo
non chiudibile sul navigatore radice). ⚑ Ripristino gratis: chi cambia telefono deve riavere i dati
anche prima di ripristinare l'acquisto. ☠ «Sostituisci tutto» e' irreversibile, loghi compresi: il
riepilogo prima della conferma e' l'unico modo di accorgersi del file sbagliato.

### Avvio — `lib/main.dart`

`Future<void> main()`: `buildQrConfig()` → **`assertUsableInRelease()`** (☠ una release con BILLING=fake
sbloccherebbe il Pro a chiunque) → `AppPaths.forApp` + `ensureAll` → `MicroLog.init(logs/qr_me.log)` →
`FlutterError.onError` nel log → `SettingsStore.create(namespace: 'qr_me')` → `_recordLaunch` (conta
avvii e primo avvio: servono alla richiesta di recensione) → `runApp(ProviderScope(overrides: config,
paths, settings, child: QrMeApp()))`. **Niente database qui** (pigro, §6).

---

## 10. Cosa e' Pro e cosa e' gratis

| Funzione | Gratis | Pro | Chiave | Dove si controlla |
|---|---|---|---|---|
| Condivisione → QR a tutto schermo, luminosita' | ✔ | ✔ | — | |
| Testo e link scritti o incollati | ✔ | ✔ | — | |
| Lettura dalla fotocamera e da immagine (anche condivisa) | ✔ | ✔ | — | |
| Ri-mostrare un QR letto, anche Wi-Fi/contatto | ✔ | ✔ | — | |
| Cronologia | ultimi **5** (cancellati davvero) | illimitata da adesso | `fullHistory` | `historyKeep` in `recordIfEnabled` e `SavedPage` |
| Preferiti | **1** | illimitati | `unlimitedEntities` | `saveAsFavorite` |
| Moduli speciali (compilare, modificare) | — | ✔ | `customCategories` | `openNewForm`, `openEditForm`, `ProGate` su `/form` |
| Stile (colori, forme, logo) | — | ✔ | `themeCustomization` | `openStyle`, `ProGate` su `/style` |
| Condividere il QR come PNG | — | ✔ | `imageExport` | `shareQrImage` |
| Creare il backup | — | ✔ | `backupRestore` | `createBackup` |
| Ripristinare un backup | ✔ | ✔ | — | |
| Copia testo / password, apri link, chiama… | ✔ | ✔ | — | |

Prezzo: **1,99 €** (App Store base Italia), **Play 1,63 EUR senza IVA** (1,99 / 1,22). Paywall: 6
benefici (§6). ⚠ Nessuno ha ancora creato il prodotto negli store.

---

## 11. Configurazione e chiavi

| Chiave | Dove | Default | Significato |
|---|---|---|---|
| `BILLING` | `--dart-define` (letto da `MicroAppConfig.fromEnvironment`) | `fake` in debug, `store` in release | `fake` = gateway finto **senza Pro** a 1,99 €; una release con `fake` fallisce all'avvio (`assertUsableInRelease`) |
| `MA_LICENSE_URL`, `MA_APP_SECRET` | `--dart-define-from-file` | vuoti | server licenze; senza, `serverEnabled` falso e l'entitlement lavora in locale con lo store |
| `appId` | `app_config.dart` | `qr_me` | namespace di preferenze, cartelle, log; uguale a `QrBackupSource.id` |
| `licenseAppId` | `app_config.dart` | `qrme` | id sul License Server (≠ `appId`) |
| `proSku` | `app_config.dart` | `qrme_pro_lifetime` | **immutabile** dopo la pubblicazione |
| `seedColor` / `fontFamily` / titoli | `app_config.dart`, `qr_palette.dart` | `#3BD13B` / PlusJakartaSans / SpaceGrotesk | font variabili in `assets/fonts/` (OFL) |
| `defaultBrightness` | `app_config.dart` | `Brightness.dark` | scuro di default |
| `applicationId` / `namespace` | `android/app/build.gradle.kts` | `com.smp.qrme` | **immutabile** |
| `minSdk` / `targetSdk` / `compileSdk` | idem | 24 / Flutter / Flutter | desugaring attivo; release con minify e shrink |
| `compileSdk` di `receive_sharing_intent` | `android/build.gradle.kts` (`finalizeDsl`) | **36** | il plugin dichiara 37 (§13) |
| `storeFile`, `storePassword`, `keyAlias`, `keyPassword` | `android/key.properties` (**non versionato**, in `.gitignore`) | assenti → firma debug | keystore **PKCS12** in `%USERPROFILE%/.android-keys` |
| bundle iOS, estensione, team | `project.pbxproj` | `com.smp.qrme`, `com.smp.qrme.ShareExtension`, `A29HGT2MQ4` | solo iPhone, iOS 15 |
| App Group | `CUSTOM_GROUP_ID` (build setting su Runner ed estensione), `*.entitlements` | `group.com.smp.qrme` | `AppGroupId` negli Info.plist |
| Schema URL | `Info.plist` del Runner | `ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)` | lo usa l'estensione per riaprire l'app; lo gestisce il plugin |
| `version` | `pubspec.yaml` | `1.0.0+1` | `appVersion` va tenuta uguale |
| `schemaVersion` DB / backup | `database.dart` / `QrBackupSource` | `1` / `1` | |
| file del database | `_openConnection` | `<Documenti>/qr_me.sqlite` | escluso da iCloud |
| loghi foto | `QrLogoFiles` + ImageStore | `<Documenti>/qr_me/images/logos/<uuid>.jpg` e `images/thumbs/logos/<uuid>.jpg` | 512 px / 128 px, JPEG 90 |
| PNG condivisi | `shareQrImage` | `<cache>/qr_me/exports/qr-me-<ms>.png` | mai cancellati dall'app (§14) |
| file della verifica | `ReadabilityCheck` | `<tmp>/qrme_check_<µs>.png` | cancellato subito |
| log, entitlement | `main`, `EntitlementNotifier` | `<support>/qr_me/logs/qr_me.log`, `<support>/qr_me/entitlement.json` | restano nel backup iCloud |

### Preferenze (SettingsStore, namespace `qr_me`: chiave salvata `qr_me.<chiave>`)

| Chiave | Valore salvato | Tipo | Chi |
|---|---|---|---|
| SettingKeys.themeMode | `theme_mode` | `light`\|`dark`\|`system`; **assente → scuro** | `ThemeModeNotifier` |
| `QrSettingKeys.historyEnabled` | `history_enabled` | bool; **assente → true** | `HistoryEnabledNotifier` |
| SettingKeys.launchCount, SettingKeys.firstLaunchAt | `launch_count`, `first_launch_at` | int, istante | `main` |

### Permessi

| Piattaforma | Permesso | Perche' |
|---|---|---|
| Android | `com.android.vending.BILLING` | dichiarato a mano: Play guarda il pacchetto per sbloccare il prodotto |
| Android | `CAMERA` (dichiarato **da noi**, oltre che da `camera_android_camerax`: il permesso e' del prodotto) | alla prima apertura di `/scan` |
| Android | ☠ `RECORD_AUDIO`, `WRITE_EXTERNAL_STORAGE` e `READ_EXTERNAL_STORAGE` **rimossi** con `tools:node="remove"` | li porta `camera_android_camerax` (servono a chi registra video); `READ_…` il fusore la deduce da `WRITE_…` anche dopo averla tolta (IMPLIED nel report di fusione), quindi va rimossa esplicitamente |
| Android | `uses-feature android.hardware.camera.any` **`required="false"`** (`tools:replace`) | senza fotocamera l'app crea QR e li legge da un'immagine; richiesta, Play la nasconderebbe a quei dispositivi |
| Android | ☠ nessun servizio `com.google.mlkit` nel manifest fuso (verificato con `aapt dump xmltree` il 2026-10-09) | regola «dati solo sul telefono». ⚠ I servizi `com.google.android.datatransport.*` **ci sono**, ma li porta Play Billing (`com.android.billingclient:billing:8.0.0` via `in_app_purchase_android`), non lo scanner: §14 debito |
| Android | ☠ **niente `READ_EXTERNAL_STORAGE`** | le immagini condivise arrivano `content://` con permesso temporaneo; su Play chiederebbe una giustificazione (provato: PNG da Google Foto ad app aperta e chiusa) |
| Android | intent-filter `SEND` `text/plain` e `image/*` su MainActivity (`singleTask`) | Condividi → QR Me |
| Android | `<queries>` VIEW per `http`, `https`, `tel`, `mailto`, `smsto`, `sms` (+ PROCESS_TEXT del template) | url_launcher su Android 11+ |
| Android | INTERNET solo nei manifest debug/profile | (vedi §14) |
| iOS | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` | lettura; logo e «Da immagine» (☠ image_picker la vuole anche col selettore di sistema, o App Store Connect rifiuta) |
| iOS | **niente** `NSMicrophoneUsageDescription` | il `ReaderWidget` apre la fotocamera con `enableAudio: false` e `camera_avfoundation` chiede il microfono solo con `enableAudio` (verificato nel sorgente). ⚠ Al primo caricamento su App Store Connect controllare che non arrivi l'avviso ITMS-90683 per il microfono (il binario contiene le API audio del plugin): se arriva, si aggiunge la stringa |

### Testi (l10n)

**205 chiavi**, template **inglese** (`l10n.yaml`: `template-arb-file: app_en.arb`, `output-class: L`,
`nullable-getter: false`, `output-dir: lib/l10n/generated`, `untranslated-messages-file:
lib/l10n/untranslated.json` — oggi `{}`). Classi generate: `abstract class L` (`L.of`, `L.delegate`),
`LEn`, `LIt`, `L lookupL(Locale locale)` (usata dai test).

☠ **Gli ARB non si modificano mai a mano**: si scrive in `tool/testi.py` (TESTI comuni + `main()`,
`segnaposti()`, `tutti_i_testi()`) e nei `tool/testi_*.py` caricati in ordine alfabetico (una chiave
ripetuta e' un errore). Una riga: `'chiave': ('inglese', 'italiano')`; segnaposti `{nome}` (tipi in
`TIPI`: `n`, `count`, `days` int in `testi.py`; `favorites`, `history` int in `testi_lists.py`; il resto
String); plurali ICU. ☠ Virgolette **tipografiche** anche in inglese. ☠ **Niente ✓ ✔ ✗ ✘ ⚠ ❌ ✅ nei
testi** (`texts_glyphs_test`): il segno lo mette l'icona.

| File | Prefissi (chiavi) |
|---|---|
| `tool/testi.py` (57) | appTitle 1, common 9, form 1, history 1, kind 7, paywall 22, pro 1, saved 1, scan 1, scanResult 1, settings 7, show 1, style 1, theme 3 |
| `tool/testi_forms.py` (25) | contact 6, email 3, form 6, phone 1, sms 2, wifi 7 |
| `tool/testi_home.py` (37) | common 3, display 13, home 15, save 3, share 1, wifi 2 |
| `tool/testi_lists.py` (40) | backup 16, data 1, history 8, saved 7, settings 8 |
| `tool/testi_scan.py` (19) | result 10, scan 9 |
| `tool/testi_style.py` (27) | logo 10, style 17 |

Flusso: `python tool/testi.py` → `pwsh ../../tool/fl.ps1 gen-l10n`.

### Dipendenze proprie (oltre a micro_core)

`micro_share` (path), `qr_flutter ^4.1.0`, **`flutter_zxing ^3.1.0`** (ha sostituito `mobile_scanner`
il 2026-10-09: non rimetterlo), **`camera ^0.12.1`** (diretta perche' la pagina di scansione usa
`FlashMode` e `CameraException`; stesso vincolo che risolve flutter_zxing, non allargarlo),
`screen_brightness ^2.1.11`, `wakelock_plus ^1.8.0`, `image_picker
^1.2.4`, `url_launcher ^6.3.3`, `share_plus ^13.3.0` (⚑ stesso vincolo di micro_core), `image ^4.10.1`,
`characters ^1.4.1`, `drift ^2.35.2`, `sqlite3 ^3.7.0`, `sqlite3_flutter_libs ^0.6.0+eol`,
`flutter_riverpod ^3.4.3`, `go_router ^18.0.2`, `intl ^0.20.3`, `meta`, `path`, `path_provider`,
`cupertino_icons`. Dev: `drift_dev`, `build_runner`, `analyzer: ">=14.0.0 <14.4.0"` (☠ 14.5 rompe
Drift), `flutter_launcher_icons`, `flutter_native_splash`, `shared_preferences` (mock di SettingsStore),
`integration_test` (dichiarata, non usata), `flutter_lints`.
⚑ **Qui le dipendenze native entrano tutte con il bootstrap** (diversamente da Film Tracker): la
specsheet le aveva fissate e F17.4 lavorava a piu' passi in parallelo; l'APK di debug del bootstrap era
la prova che compilavano insieme. ⚑ L'app **non** usa `receive_sharing_intent` direttamente.
⚑ Regola «dati solo sul telefono»: prima di aggiungere una dipendenza nativa si controllano le sue
dipendenze Android/iOS (Firebase, `datatransport`, play-services di analisi, crash reporting, ML Kit,
pubblicita'): se ne porta una, non si usa.

### Comandi

Dalla cartella `apps/qr_me`:

```
pwsh ../../tool/fl.ps1 test                                   # i test (155)
pwsh ../../tool/fl.ps1 analyze
python tool/testi.py; pwsh ../../tool/fl.ps1 gen-l10n         # dopo aver cambiato un testo
pwsh ../../tool/fl.ps1 pub run build_runner build             # dopo una modifica a lib/data/tables.dart
pwsh ../../tool/fl.ps1 build apk                              # APK
python tool/genera_icone.py                                   # poi flutter_launcher_icons e flutter_native_splash:create
adb shell am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "https://esempio.it" com.smp.qrme   # condivisione finta
pwsh ../../tool/verify_atlas.ps1 -Project apps/qr_me          # dalla radice: atlante contro codice
ruby tool/aggiungi_share_extension_ios.rb apps/qr_me ShareExtension group.com.smp.qrme   # dalla radice, sul Mac, dopo pub get
```

---

## 12. Catalogo dei test

**155 test** in `apps/qr_me/test/` (127 dichiarazioni, alcune in cicli), tutti verdi il 2026-10-09:
152 al commit `7a48532` piu' i 3 di `ZxingImageReader` in `services_test.dart` aggiunti con la
sostituzione di ML Kit.

| File | N. | Cosa dimostra |
|---|---|---|
| `test/domain/qr_encoder_test.dart` | 15 | ogni codifica **esattamente** come in tabella |
| `test/domain/qr_decoder_test.dart` | 33 | riconoscimento, ripiego, mai un'eccezione, **round-trip su 15 contenuti**, `toFields`/`fromFields` su 7 tipi |
| `test/domain/qr_capacity_test.dart` | 7 | limiti per livello, UTF-8, scelta del livello |
| `test/domain/qr_style_test.dart` | 11 | `isPlain`, JSON (5 andata e ritorno), tolleranza, id icone, grafemi |
| `test/domain/contrast_test.dart` | 5 | WCAG e inversione |
| `test/data/qr_repository_test.dart` | 17 | le regole del repository su `QrDatabase.memory()` + ImageStore vero in cartella temporanea |
| `test/data/qr_backup_test.dart` | 4 | backup vero (ZIP di BackupService) fra due «telefoni» |
| `test/services/services_test.dart` | 10 | QrRenderer e ContentActions; **3 di `ZxingImageReader`** (aggiunti con la sostituzione di ML Kit) |
| `test/services/share_router_test.dart` | 8 | ShareRouter e ShareIntake con router vero e FakeShareInbox |
| `test/widget/display_page_test.dart` | 12 | la pagina del QR |
| `test/widget/form_page_test.dart` | 4 | i moduli |
| `test/widget/home_page_test.dart` | 9 | la home |
| `test/widget/style_page_test.dart` | 6 | stile, avvisi, verifica |
| `test/widget/paywall_config_test.dart` | 6 | coerenza del Pro |
| `test/widget/palette_contrast_test.dart` | 6 | contrasto AA della palette nei due temi |
| `test/widget/texts_glyphs_test.dart` | 2 | niente glifi di spunta/avviso negli ARB |

### `qr_encoder_test.dart` (15)
testo identico (spazi e a-capo compresi); http/https com'e'; senza schema solo con punto e senza
spazi (`ciao` → null, `ciao mondo.it` → null, `HTTPS://Esempio.it` → host minuscolo); `ftp:`/`javascript:`
rifiutati e `encode` di un ftp → ArgumentError; Wi-Fi WPA, WEP nascosta, aperta (`nopass`, niente `P:`
anche con password), **escape di `\ ; , : "`**; vCard 3.0 completa con CRLF e `N` ricavato
(«Rossi;Mario Bianchi»), righe vuote omesse, escape vCard; mailto con `%20`/`%2B`/`%0A`/UTF-8 e
parametri vuoti omessi; `SMSTO:+393331234:Ciao: arrivo` e `SMSTO:333:`; `tel:+39021234567`; `autoTitle`
per ogni tipo (dominio senza www, max 41, mai vuoto).

### `qr_decoder_test.dart` (33)
WIFI in qualunque ordine e minuscolo con unescape, `nopass`, WEP, senza T ma con password → wpa; vCard
4.0 con gruppi/parametri/`tel:`/ORG a componenti e vCard 3.0 senza FN (nome da N); MECARD; mailto con
`+` che resta `+` e MATMSG con escape; SMSTO, `sms:?body=`, `SMS:333:ciao`, `sms:333`; `TEL:` normalizzato;
link con e senza spazi; testo come ripiego intatto (`esempio.it`, `ftp://`, vuoto); **9 formati rotti
→ testo** (`WIFI:`, `mailto:%E0%A4%A`, `tel:abc`, …); `decodeTyped`; **round-trip** (15: testi con
emoji e spazi, link con frammento, Wi-Fi con caratteri speciali ed emoji, contatto completo con `,` `;`
`\` e a-capo, email con `&` e `+`, SMS, telefono); `fromFields(toFields(c)) == c` per i 7 tipi; campi
rotti → FormatException.

### `qr_capacity_test.dart` (7)
limiti 2953/2331/1663/1273; `fits` al byte esatto; emoji 4 byte, accentata 2 (318 emoji stanno in H,
319 no); M senza logo e H con logo; 1500 byte con logo → M, logo tolto, fitto; 2500 → L, 3000 →
`tooLong`; fitto solo oltre 1000.

### `qr_style_test.dart` (11)
`plain`/`isPlain` (anche `copyWith(logo: NoLogo())` resta plain); andata e ritorno JSON di 5 stili (foto
rotonda, icona, emoji famiglia); chiavi mancanti/sconosciute; valori del tipo sbagliato → default, logo
sconosciuto/testo troppo lungo/foto senza immagine → NoLogo; IconLogo salva l'id; **catalogo di 24 id
senza doppioni** (lista esatta); grafemi (`🇮🇹🎉👨‍👩‍👧` valido, `ABCD` no, spazi no).

### `contrast_test.dart` (5)
nero/bianco 21 simmetrico; uguali 1; grigi simili < 3 e verde scuro su bianco > 3; alfa ignorata; inversione.

### `qr_repository_test.dart` (17, `QrDatabase.memory()`, orologio 2026-10-09 12:00 UTC + 1 min per QR, ImageStore su cartella temporanea)
`recordShown` salva tipo, payload con escape, titolo, provenienza, `style_json` null, `fields_json`, e
niente campi per testo e link; **un testo che sembra un `tel:` resta testo**; provenienza sconosciuta →
ArgumentError; **niente doppioni** (il ri-mostrato torna in cima; stesso payload con altro stile = altro
QR); un preferito identico non si tocca; **potatura a 5** (preferito salvo, righe **cancellate**,
`keep: null` → 0); preferiti: salva, rinomina, ordine per titolo senza maiuscole, conteggi, togli;
togliere un preferito non crea un doppione; `touch`; `clearHistory` solo non preferiti; **logo orfano
cancellato solo quando nessuno lo usa** (immagine e miniatura); **`pruneOrphanLogos`**: via
l'abbandonato, salvo quello in uso **con la miniatura**, salvo quello di 1 minuto fa, che sparisce dopo
15 minuti; senza ImageStore → 0; `updateStyle`/`pruneHistory`/`clearHistory` cancellano i loghi; il
repository **non scrive da solo**; titolo rifilato, max 80, mai vuoto; `updateContent` tiene il nome.

### `qr_backup_test.dart` (4, due QrDatabase.memory e due cartelle)
andata e ritorno con **logo foto** e Wi-Fi con `; , : " \` (preferito con titolo, stile, contenuto,
payload; cronologia; file del logo arrivato allo stesso percorso relativo); ripristino doppio in unione
senza doppioni; «sostituisci tutto» cancella il logo che il backup non riporta; **5 file malformati**
(tipo, provenienza, payload non testo, titolo vuoto, percorso `../../segreto`) → FormatException e
database intatto.

### `services_test.dart` (10)
`levelFor` M/H/logo tolto; troppo lungo: `choose` lo dice e `levelFor` lancia; il widget ha la **zona di
rispetto del colore di sfondo** (ColoredBox) e larga 4 moduli su 29 (versione 1); il PNG ha la firma PNG
e IHDR 256×256; `uriFor` per tipo (`tel:+393331234`, mailto `%20`/`%2B`, `sms:3331?body=…`, null per
testo e Wi-Fi); `open` usa il lanciatore e restituisce false senza niente da aprire; un lanciatore che
lancia → false. **ZXing**: senza la libreria nativa (sotto `flutter test` sul PC) un
PNG vero da' `QrReaderUnavailable` con entrambi i lettori, non un errore qualunque; un file che non si
apre come immagine da' lista vuota («nessun QR»); `strict` non prova gli invertiti.

### `share_router_test.dart` (8)
testo → `/show` TextContent con `source: shared`; `esempio.it` → UrlContent `https://esempio.it`;
immagine con QR → `/scan/result` con `source: image` e il percorso letto; immagine senza QR →
`noQrInImage` e nessuna pagina; scanner assente → `readerUnavailable`; **doppione entro 2 s ignorato**,
diverso passa, dopo 3 s passa; piu' elementi: il testo vince e l'immagine non si legge; **ShareIntake**:
`initial` letto una volta, `reset` subito, poi lo stesso elemento su `incoming` → `duplicate`, uno nuovo passa.

### `display_page_test.dart` (12)
password Wi-Fi nascosta finche' non si tocca l'occhio («Rete: Casa», `••••••••`); senza Pro lucchetto su
Stile e Immagine e non su Salva e Copia; col Pro nessun lucchetto; **luminosita' accesa all'apertura,
ripristinata in pausa, riaccesa al ritorno, ripristinata uscendo**; cronologia accesa: registrato e
`pruneCalls == [5]`; col Pro `[null]`; **cronologia spenta: niente scritture**; un QR salvato si apre per
id e si **tocca** (preferito con modulo: c'e' Modifica); id inesistente → «Questo QR non esiste più.»;
secondo preferito senza Pro → paywall e nessun nome chiesto; primo preferito salvato col nome scelto;
testo da 3000 → «Troppo lungo per un QR» senza eccezioni.

### `form_page_test.dart` (4)
Wi-Fi con `;` `:` `"` `\` → `WIFI:T:WPA;S:Casa\;1;P:pa\:ss\"\\;;` e `source: form` (cronologia spenta →
`/show`); rete aperta → niente campo password e `WIFI:T:nopass;S:Bar;;`; SSID vuoto → «Obbligatorio» e
pulsante spento; cronologia accesa → registrato `tel:+393331234567` e aperto `/qr/100`.

### `home_page_test.dart` (9)
incolla `esempio.it/menu` → `/show` con `https://esempio.it/menu`, `source: typed`; un testo resta
identico (spazio finale compreso); Mostra QR spento a campo vuoto; **al massimo 5 recenti** e la riga
della cronologia gratuita; col Pro la riga sparisce; i 5 chip con ProBadge senza Pro; nessun badge col
Pro; chip senza Pro → paywall; stato vuoto che spiega la condivisione.

### `style_page_test.dart` (6)
`kLogoIcons.keys == kLogoIconIds` (stesso ordine); nero su bianco: nessun avviso e «Leggibile» dopo 600 ms
(1 verifica); colori simili → avviso rosso; primo piano bianco → avviso subito, «Verifico…» e seconda
verifica solo dopo la pausa; chiaro su scuro → avviso giallo e non rosso; scanner assente → «Non
verificato su questo dispositivo», mai «Non riesco a leggerlo».

### `paywall_config_test.dart` (6)
ogni chiave limitata e' fra i benefici e viceversa, in it ed en, una riga per chiave; **tutte le
FeatureKey dichiarate**; cronologia 5 gratis; 1 preferito gratis; moduli, stile, immagine, backup Pro;
foto, statistiche, notifiche, CSV gratis.

### `palette_contrast_test.dart` (6 = 3 × 2 temi)
`ink` e `inkMuted` ≥ 4,5:1 su fondo e superfici; l'accento come testo ≥ 4,5:1; `onAccent` sull'accento ≥ 4,5:1.

### `texts_glyphs_test.dart` (2)
`app_it.arb` e `app_en.arb` senza `✓✔✗✘⚠❌✅` (legge i file dalla cartella dell'app: va lanciato da li').

### Impianto — `test/widget/qr_test_harness.dart`

| Simbolo | Firma | Cosa offre |
|---|---|---|
| `FakeQrRepository` | `class FakeQrRepository extends QrRepository` — `FakeQrRepository(super.db, {List<QrCode>? rows})` | righe in memoria, stream broadcast; registra `recorded`, `pruneCalls`, `touched`, `favorited`; id da 100; `dispose()` |
| `qrRow` | `QrCode qrRow(int id, {required QrContent content, String? payload, String source = QrSource.typed, bool favorite = false, String? title, int lastUsedAt = 0})` | una riga di prova |
| `FakeScreenBoost` | `class FakeScreenBoost implements ScreenBoost` | contatori `enabled`, `disabled`, `bool get on` |
| `FakeQrReader` | `class FakeQrReader implements QrImageReader` — `FakeQrReader([List<String> values = const [], bool unavailable = false])` | registra `paths`; lancia QrReaderUnavailable se `unavailable` |
| `FakeReadabilityCheck` | `class FakeReadabilityCheck extends ReadabilityCheck` — `FakeReadabilityCheck(this.result)` | risponde sempre `result`, conta `calls` |
| `FakeEntitlementNotifier` | `class FakeEntitlementNotifier extends EntitlementNotifier` | sul servizio dato, senza bootstrap |
| `FixedHistoryNotifier` | `class FixedHistoryNotifier extends HistoryEnabledNotifier` | cronologia fissa |
| `QrHarness` | `class QrHarness` — `repo`, `boost`, `reader`, `router` | |
| `pumpQr` | `Future<QrHarness> pumpQr(WidgetTester tester, {Widget? page, List<RouteBase>? routes, String initialLocation = '/', bool pro = false, bool historyOn = true, List<QrCode>? rows, FakeQrReader? reader, ReadabilityCheck? readability, List<Override> extra = const []})` | monta una pagina **o** le rotte in **italiano**, tema scuro Neon, con tutti i doppi (gate, entitlement finto a 1,99 €, cartella temporanea) |
| `captureRoute` | `GoRoute captureRoute(String path, List<Object?> sink, {String label = 'DESTINAZIONE'})` | rotta che registra l'`extra` (una volta) e mostra «DESTINAZIONE <path>» |

⚑ **Niente Drift nei widget test**: dentro `testWidgets` FakeAsync congela l'I/O di SQLite e gli stream
non arrivano mai (TrashCan, Film Tracker). Che le scritture vere funzionino lo dimostrano
`qr_repository_test` e `qr_backup_test`. ⚑ **Niente golden** (i font cambiano fra Windows e Mac).
⚑ `pumpAndSettle` non aspetta un Timer senza fotogrammi: la pausa di 600 ms va fatta passare a mano.

**Senza test**: `ScanPage`, `ScanResultPage`, `SavedPage`, `HistoryPage`, `SettingsPage`, `DataSection`,
`LogoPicker` (oltre al catalogo), `LogoRenderer`, `ReadabilityCheck` vera, la lettura vera di `ZxingImageReader` (serve la libreria nativa: emulatore),
`ScreenBoost` vero, `QrMeApp`/`buildRouter` (rotte «Non trovato»), `QrCodeToDomain` con `fields_json`
rotto, migrazioni (schema 1), `integration_test`.

---

## 13. Trappole gia' disinnescate e regole

| Sintomo | Causa | Dove |
|---|---|---|
| Il QR del Wi-Fi si legge ma non connette | `;` `,` `:` `"` `\` non escapati | `QrEncoder.wifiEscape` |
| La fotocamera chiede una password per una rete aperta | `P:` vuoto | niente `P:` con `nopass` |
| Il contatto non si importa su iOS | MECARD (iOS la tratta come testo) | vCard **3.0** con CRLF |
| Un numero vuoto in rubrica | `TEL:` vuoto | righe vuote omesse |
| Il messaggio non si precompila | `sms:` nel QR | `SMSTO:` nel QR, `sms:?body=` per aprire |
| Oggetto «Ciao+a+tutti» | `Uri(queryParameters:)` / `splitQueryString` | `encodeComponent` / `_query` |
| `tel:` che non chiama su alcuni Android | punti nel numero | `normalizePhone` toglie anche i punti |
| Un QR strano fa crashare la pagina | decoder che lancia | `decode` non lancia mai: testo |
| «ciao» diventa `https://ciao` | link senza schema troppo generoso | serve un punto; `decode` vs `decodeTyped` |
| Un articolo condiviso fa lanciare qr_flutter nel build | nessun controllo di capacita' | `QrCapacity.choose` prima di disegnare |
| Il QR col logo non si legge | logo troppo grande o livello basso | 22% del lato, **H**, logo tolto se non ci sta, piatto, `ReadabilityCheck` |
| Moduli a pezzi attorno al logo | logo senza piatto | `LogoRenderer._plate` |
| Righe chiare fra i moduli | fessure | `gapless: true` |
| La fotocamera non trova il QR su fondo scuro | zona di rispetto trasparente | ColoredBox dello sfondo, 4 moduli |
| L'immagine condivisa diversa da quella vista | due traduzioni dello stile | un solo `QrRenderer.painter` |
| Un preferito mostra un'altra icona dopo un aggiornamento | codePoint salvato | id testuali `kLogoIconIds` |
| Un'emoji «troppo lunga» / tagliata a meta' | `String.length` e `maxLength` contano code unit | `characters`, contatore proprio |
| Telefono a luminosita' piena dopo il tasto Home | ripristino solo in dispose | `AppLifecycleListener` onHide/onShow |
| Il QR non si mostra su un telefono strano | plugin della luminosita' che lancia | `ScreenBoost._quiet` |
| Due pagine del QR una sopra l'altra dopo una condivisione | `initial` e `incoming` consegnano lo stesso elemento | `reset()` subito + finestra di 2 s |
| Tre pagine del risultato da una sola inquadratura | lo scanner consegna piu' letture al secondo | `_handling` |
| Fotocamera accesa (e telefono caldo) sotto la pagina del risultato | il `ReaderWidget` coperto continua a leggere | `_cameraOn = false` smonta il widget durante il push |
| Pagina di lettura nera per sempre su un dispositivo senza fotocamera | il `ReaderWidget` non segnala nulla se `availableCameras()` e' vuota | `_checkCameras` → stato d'errore |
| `READ_EXTERNAL_STORAGE` ricomparso nell'APK | il fusore la **deduce** (IMPLIED) dal `WRITE_EXTERNAL_STORAGE` di `camera_android_camerax` | `tools:node="remove"` anche su READ, oltre che su WRITE e `RECORD_AUDIO` |
| L'app nascosta su Play ai dispositivi senza fotocamera | `uses-feature camera.any` richiesta dal plugin | `required="false"` con `tools:replace` |
| «Non trovato» aprendo dall'estensione | deep link di Flutter acceso | spento in manifest e Info.plist |
| La condivisione con l'app aperta legge l'intent vecchio | `singleTask`, `getIntent()` vecchio | `MainActivity.onNewIntent` → `setIntent` |
| «Failed to find target with hash string 'android-37'» | `receive_sharing_intent` 1.9.0 dichiara compileSdk 37, AGP 9 non lo trova | `finalizeDsl { compileSdk = 36 }` in `android/build.gradle.kts` (gira **dopo** il build.gradle del plugin) |
| Lo script Ruby muore con «invalid byte sequence in US-ASCII» | da ssh il Mac non imposta LANG e Ruby legge gli Info.plist accentati come ASCII | `# encoding: utf-8` + `Encoding.default_external/internal = UTF_8` in `tool/aggiungi_share_extension_ios.rb` |
| L'estensione non trova Flutter.framework / «contains disallowed file 'Frameworks'» | framework incorporati dentro l'appex | l'estensione **non** incorpora framework: `LD_RUNPATH_SEARCH_PATHS` cerca in `@executable_path/../../Frameworks` dell'app (☐ da confermare all'archivio, DT-S2 di micro_share) |
| Errore di ciclo fra dipendenze in Xcode | copia dell'appex dopo «Thin Binary» | «Embed Foundation Extensions» **prima** di Thin Binary (script) |
| QR Me non compare nello Share Sheet di iOS | estensione non copiata nell'app | fase di copia aggiunta dallo script |
| «Missing package product» in Xcode | il percorso del pacchetto Swift contiene la versione del plugin | rilanciare lo script a ogni aggiornamento di `receive_sharing_intent` |
| Permesso di storage chiesto da Play | `READ_EXTERNAL_STORAGE` del README del plugin | non dichiarato: `content://` con permesso temporaneo |
| Le password Wi-Fi su Drive/iCloud | backup automatici | `allowBackup="false"`, `isExcludedFromBackup` su `Documents/` |
| La cronologia «nascosta» trattiene password | righe oltre 5 solo nascoste | cancellate davvero |
| Una password Wi-Fi nei log | `toString` | `WifiContent.toString` senza password |
| Miniature dei loghi in uso cancellate | `pruneOrphans` con le sole immagini | `QrLogoFiles.filesOf` (immagine **e** miniatura) |
| L'anteprima del logo appena scelto sparisce | pulizia durante la scelta | 15 minuti di grazia, pulizia 3 s dopo l'avvio |
| Il logo condiviso da due QR sparisce | cancellato al primo dei due | controllo su tutti gli stili rimasti |
| Un logo rotondo diventa un cerchio su nero | JPEG senza trasparenza | file quadrato, ritaglio al disegno |
| Foto verticale ritagliata di lato | EXIF ignorato | `bakeOrientation` |
| L'app si congela importando una foto | decodifica sul thread UI | `compute(_cropSquare)` |
| Un backup rovinato fa crashare l'app | TypeError non intercettato da `restore` | tutto in FormatException |
| Un backup scrive fuori dalla cartella | percorsi `..` | `_logoPath` |
| «A TextEditingController was used after being disposed» | controller chiuso durante la chiusura del dialogo | `_TitleDialog` con stato |
| «Nessun / o» al 130% di testo | segmenti stretti | `_SegmentLabel` con FittedBox |
| Link e «Vedi tutti» illeggibili nel tema chiaro | accento #16A34A (3,0:1) | **#15803D** (4,6:1), test |
| Titolo della lettura nero su nero (tema chiaro) | colore del titolo del tema vince | bianco esplicito |
| Mirino sopra il messaggio di permesso negato | sovrapposizione sempre visibile | solo senza errore |
| Il segno doppio «✓ Leggibile» | glifo nel testo e icona | testi senza glifi (test) |
| Una pagina Pro aperta gratis da un push | Pro controllato solo sul pulsante | `ProGate` sulla rotta |
| Pagina d'errore di go_router | redirect su un push | nessun redirect |
| Eccezione nel builder con `/qr/abc` | `int.parse` | `tryParse ?? -1` |
| Una release regala il Pro | BILLING fake in release | `assertUsableInRelease` |
| «app sconosciuta» dal License Server | `appId` col trattino basso | `licenseAppId 'qrme'` |
| Nomi QrCode e QrEyeShape in conflitto | qr_flutter li esporta | import con prefisso `qf` |
| «unable to open database file» solo su telefono | tmp di sistema non scrivibile | `sqlite3.tempDirectory` |
| Un widget test resta appeso | FakeAsync congela SQLite | repository finto |
| Generazione Drift: «contextFeatures isn't defined» | analyzer 14.5 | tetto `<14.4.0` |
| «Activity class does not exist» | Kotlin Gradle Plugin mancante | `id("org.jetbrains.kotlin.android")` |
| «requires core library desugaring» | flutter_local_notifications in micro_core | `isCoreLibraryDesugaringEnabled` |
| Build Kotlin bloccate su Windows | cache incrementale bloccata | `kotlin.incremental=false` |
| Icona iOS rifiutata a caricamento finito | canale alfa | icona su fondo pieno + `remove_alpha_ios` |

### Regole non negoziabili

1. **Dati solo sul telefono**: nessun SDK che manda qualcosa a terzi (nemmeno metriche anonime). Unica
   eccezione il server licenze per il Pro. **[SCANNER]** per questo ML Kit e' stato tolto (ZXing dal
   2026-10-09). ☠ Non rimettere `mobile_scanner` ne' scanner basati su ML Kit; non chiamare le letture
   «da URL» di `flutter_zxing`.
2. **Tutte le letture e scritture passano da `QrRepository`** (doppioni, potatura, loghi orfani).
3. **Cronologia spenta = nessuna scrittura** (`recordIfEnabled`); si scrive solo con «Salva».
4. **La potatura cancella davvero**: mai nascondere righe per rivelarle al Pro.
5. **Le codifiche dell'encoder non cambiano** (sono quelle delle fotocamere di sistema); il decoder puo'
   solo allargarsi. Ogni modifica passa dai test di round-trip.
6. **Lo stile si traduce in qr_flutter in un punto solo** (`QrRenderer.painter`); zona di rispetto mai trasparente.
7. **Il QR sta sempre sul suo pannello del colore di sfondo**, anche nel tema scuro.
8. **Si controlla la capacita' prima di disegnare** (`choose`), mai dopo.
9. **Il dominio non contiene stringhe dell'app** ne' Flutter.
10. **Nessuna pagina scrive `if (isPro)` a mano**: `featureGateProvider` e `qrFeatureLimits`; ogni
    chiave limitata ha il suo beneficio nel paywall e viceversa; tutte le FeatureKey dichiarate.
11. **Le chiavi stabili non si rinominano**: `QrKind.name`, `QrSource`, chiavi JSON di `QrStyle`/`QrLogo`
    (`fg`, `bg`, `module`, `eye`, `logo`, `type`, `image`, `round`, `id`, `text`), campi di `toFields`,
    `kLogoIconIds`, `QrBackupSource.id`, `QrSettingKeys.historyEnabled`.
12. **Il deep link di Flutter resta spento.**
13. **I testi si cambiano in `tool/testi*.py`**, mai negli ARB; niente glifi di spunta nei testi.
14. **L'estensione iOS si cambia nel modello** `packages/micro_share/ios_template/` e si rilancia lo script.
15. **`applicationId`, bundle, `proSku`, `licenseAppId`, App Group sono immutabili**; `key.properties` e
    il keystore non entrano mai nel repository.
16. **Mai `Platform.isX`**: `defaultTargetPlatform`.
17. **Una modifica allo schema** incrementa `schemaVersion`, aggiunge il passo in `onUpgrade` e il suo test.
18. **Il tema scuro e' il default**; la palette passa sempre da `withQrLook`.

---

## 14. Cosa NON esiste, debito, differenze dal piano, incoerenze

### Non esiste (per non cercarlo invano)

- **Nessun widget, nessuna notifica, nessun calendario** (F17.0 punto 8): le chiavi relative sono `open()`.
- **Nessun server proprio** oltre al License Server; nessun account, nessuna sincronizzazione.
- **Nessuno schema URL dell'app** e nessun deep link: si entra dall'icona o dalla condivisione.
- **Nessuna connessione al Wi-Fi** dall'app (si copia la password), nessun salvataggio diretto in rubrica.
- **Nessun codice a barre**: solo QR.
- **Nessun `integration_test/`** (dipendenza dichiarata, cartella assente): niente giri per screenshot
  e video dello store, niente test di regressione su dispositivo.
- **Nessun dato di esempio** (`lib/dev/` non c'e').
- **API pronte e non usate**: `favoriteCountProvider` (e quindi `watchFavoriteCount` fuori dai test),
  `Routes.pro` (la rotta esiste, nessun codice la apre), `QrCapacity.fits` (solo test), il parametro
  `ProGate.allowed`, le chiavi l10n **`common_optional`, `show_title`, `form_title`**.
- **Nessuna pulizia dei PNG condivisi** in `exports/` (cartella cache: la svuota il sistema).
- **Google Play e App Store**: niente ancora (app, prodotto, scheda); License Server senza la riga `qrme`.

### Debito tecnico

| Voce | Perche' e' rimandato | Quando va affrontato |
|---|---|---|
| **`datatransport` di Play Billing** | la sostituzione di ML Kit e' chiusa (2026-10-09), ma nel manifest e nelle dipendenze restano `com.google.android.datatransport:*`, `firebase-encoders*`, `play-services-base/basement/tasks/location`: li porta `com.android.billingclient:billing:8.0.0` (via `in_app_purchase_android`, cioe' il Pro di `micro_core`). E' il canale d'acquisto di Play, comune a **tutte** le app con il Pro su Android | decisione del proprietario per tutte le microapp (non solo QR Me), prima di Play: se la regola «dati solo sul telefono» copre anche Play Billing |
| **Testo dell'informativa** (`settings_privacyBody`: «non manda niente fuori dal telefono») | vero per l'app da quando lo scanner e' ZXing (2026-10-09); resta da decidere come trattare Play Billing (riga sopra) | prima di Play; poi Data safety senza dati raccolti (salvo il server licenze) |
| **`finalizeDsl { compileSdk = 36 }` per `receive_sharing_intent`** | il plugin dichiara 37 | toglierlo quando plugin o SDK si allineano; **da ripetere in F16/F18/F19** (o spostarlo in un punto comune) finche' serve |
| **iOS mai compilato**: build, esclusione dal backup (Swift scritto da Windows), estensione, riapertura dell'app dall'estensione, lettore su iOS | serve il Mac e un iPad via TestFlight (niente iPhone: si prova su iPad in compatibilita') | F17.7.6, prima di considerare chiusa F17.2b |
| **Riapertura dell'app dall'estensione via schema URL** | Apple la tollera senza documentarla | provarla su iPad; ripiego deciso: estensione che mostra il QR da sola (SwiftUI + CIQRCodeGenerator) |
| **«Frameworks» dentro l'appex** (DT-S2 di micro_share) | si vede solo all'archivio/caricamento | primo TestFlight di QR Me |
| **Fotocamera reale** | con ZXing provati sull'emulatore anteprima, torcia, permesso negato, «Da immagine», condivisione e verifica; la lettura **dal vivo** di un QR no (la scena virtuale non ne mostra) | su telefono vero (Android) e su iPad (F17.7.6) |
| **Evidenza del beneficio nel paywall** (`highlight`) | non verificata a occhio su ogni porta | rifinitura o primo giro dello store |
| **`EntitlementView`/`EntitlementNotifier` e `ProGate` in piu' copie** | `micro_core` non dipende da Riverpod | F7 (hardening), una volta per tutte le app |
| **Permesso INTERNET** solo nei manifest debug/profile | server licenze non configurato nelle build | prima di una release con il server: controllare il manifest unito |
| **Prodotto Pro, App ID, App Group nel portale, scheda, License Server** | account del proprietario | prima della prima build firmata |
| **Password Wi-Fi in chiaro nel database** | il sandbox dell'app basta per la soglia scelta; cifrare richiederebbe gestione delle chiavi | solo se il proprietario lo chiede |
| **PNG condivisi mai cancellati** da `exports/` | stanno in cache | se si vedono accumuli |
| **Test mancanti** (elenco in §12) | interfaccia essenziale gia' provata sull'emulatore | con le prossime modifiche a quelle pagine |

### Differenze consapevoli dal piano (`develop_microapps.md` F17)

| Il piano diceva | Il codice fa | Perche' |
|---|---|---|
| `mobile_scanner` con ML Kit, poi «tenerlo dichiarandolo» (raccomandazione F17.7) | **`flutter_zxing`** (+ `camera`), lettore normale e severo | regola del proprietario «dati solo sul telefono» |
| `QrImageView` per il widget (F17.1.7) | `QrPainter` per widget **e** PNG | logo senza fotogrammi vuoti, zona di rispetto in moduli |
| `QrRenderer.widget(... ImageProvider? logo)` | `ui.Image? logo` + `semanticsLabel` | lo stesso `ui.Image` serve a PNG e verifica |
| `ReadabilityCheck.isReadable → bool` | `check → Readability` (con `unknown`) | «non verificato» ≠ «illeggibile» |
| `ShareRouter.handle` unico | `handle` + `handleAll` + `ShareIntake` | piu' elementi in una consegna; testabile senza l'app |
| `LogoRenderer.render(logo, {backgroundArgb, sizePx, images})` | + `foregroundArgb`, + `importPhoto` | il logo prende il colore dei moduli |
| `QrDecoder.decode` solo | + `decodeTyped` | un dominio scritto e' un link, uno letto no |
| `normalizePhone`: spazi, trattini, parentesi | anche i punti | grafia comune che rompe `tel:` |
| Paywall «quattro righe piu' backup» | sei righe | una riga per chiave limitata |
| `QrRepository(this._db)` | `+ images`, `+ clock`; `+ watchById`, `watchFavoriteCount`, `updateContent`, `usedLogoImages`, `pruneOrphanLogos` | loghi, test, modifica di un preferito |
| Logo in `ImageStore` da `LogoRenderer.render` | import a parte (`importPhoto`) | decodifica una volta sola |
| Dipendenze entrano con la sottofase che le usa (regola generale) | tutte al bootstrap | specsheet gia' fissata, lavoro in parallelo |
| «Apri le impostazioni» con permesso negato | solo su iOS; Android «Riprova» | evitare `permission_handler` |

### Difetti e incoerenze notate nel codice (non corretti: da sistemare alla prossima occasione)

- **☠ Difetto: «Rigenera con stile» dal risultato della lettura perde lo stile.**
  `lib/features/scan/scan_result_page.dart`: `onPressed: () => unawaited(openStyle(context, ref,
  _display))` ignora lo stile restituito, e `_display` non ha campo stile. Con la **cronologia spenta**
  (riga assente, `qrId` null) lo stile applicato va **perso**; con la cronologia accesa e' scritto sulla
  riga, ma «Mostra come QR» e «Salva» ripartono dal QR semplice e l'utente non vede il QR rigenerato.
  Correzione proposta: un campo `QrStyle _style = QrStyle.plain` nello stato, `style: _style` in
  `_display`, e un metodo `_restyle()` che fa `final style = await openStyle(...); if (style != null &&
  mounted) { setState(() => _style = style); await context.push(Routes.show, extra: _display); }`, con un
  test di widget. Non applicata durante F17.8 perche' la parte di lettura e i test erano in modifica in
  parallelo (passaggio a ZXing).
- `QrCodeToDomain.content`: un `fields_json` **JSON valido ma con campi sbagliati** fa lanciare
  FormatException da `fromFields` (intercetta solo l'errore di `jsonDecode`), invece di ripiegare sul
  payload come dice il commento. Succede solo con dati scritti a mano: il ripristino valida i campi.
- `ContentActions.open`: `uriFor` e' **fuori** dal try; un indirizzo email decodificato con un `%` nudo
  puo' far lanciare `Uri.parse` invece di restituire false.
- **Testo condiviso o scritto che il decoder riconosce** (una vCard con indirizzo, una MECARD, un
  `sms:`) viene **ricodificato** nella forma canonica (`QrEncoder.encode(decodeTyped(raw))`): i campi che
  il dominio non conosce (ADR, PHOTO…) **si perdono** nel QR. Per i QR letti no (si usa il raw). Va
  deciso se mostrare il testo condiviso tal quale.
- `lib/app/locale_resolution.dart`: il commento dice che `[de, it, en]` non deve dare l'italiano, ma il
  codice lo da' (basta che l'italiano compaia fra le preferenze); stesso testo copiato dalle altre app.
- `flutter_native_splash.yaml`: «L'app e' chiara di default (F17.2c)» — superato, oggi e' scura.
- `pubspec.yaml`: il commento di `qr_flutter` cita `QrImageView` (non usato).
- `packages/micro_share/codebase_reference.md` dice ancora che lo script Ruby non e' mai stato eseguito
  su un progetto reale (DT-S1): il target `ShareExtension` e' invece nel `project.pbxproj` di QR Me
  (commit `30f351a`). Va aggiornato quell'atlante.
- `develop_microapps.md` F17.2b (§7) dice «lo script Ruby va ancora eseguito sul Mac»: eseguito.

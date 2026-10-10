# codebase_reference.md — Spending Review

> Atlante dell'app **Spending Review** (`apps/spending_review`): il conto della spesa **con una mano
> sola, col carrello nell'altra**. Gesto principale: **batti il prezzo (o inquadra il cartellino) → il
> totale enorme in alto sale subito, e la barra dice quanto manca al budget**. Il tastierino e'
> **sempre** sullo schermo. Intorno: cartellino **interpretato** (nome, prezzo, offerte, €/kg),
> etichetta della **bilancia**, **scontrino** (confronto alla cassa e registrazione della spesa, Pro),
> storico, statistiche con il budget del mese (Pro). OCR **solo sul telefono** (`packages/micro_ocr`).
> **Obiettivo**: capire il codice, trovare cio' che serve e modificarlo **senza aprire i file**.
>
> **Aggiornato al**: 2026-10-10 (+ **lo store**, §2bis: scheda App Store, dati d'esempio `SR_DEMO`,
> screenshot, grafiche, video, TestFlight) · **Fase**: F12.0–F12.7 fatte (F12.7 parziale: restano iPad/TestFlight,
> foto vere del proprietario, Android vero), **F12.8** (questo atlante) · **Ultimo commit al momento
> della scrittura**: `b6a5c1c` (F12.7) + le correzioni di F12.8 non ancora committate ·
> **versionName+Code**: `1.0.0+1` · **Test**: **341 esiti, 339 verdi + 2 saltati** (i 336 di F12.7 + 3
> test nuovi di F12.8, §15.4; i 2 saltati sono «sempre giusti» sui motori `vision-sim*`, per scelta),
> `flutter analyze` senza issue.
>
> **Package Android / bundle iOS**: `com.smp.spendingreview` (immutabile dopo il primo upload) ·
> `appId 'spending_review'` (cartelle e preferenze) · `licenseAppId 'spendingreview'` (License Server,
> senza trattino basso) · **SKU Pro**: `spendingreview_pro_lifetime` — **2,99 €** una tantum (Play: base
> **2,45 EUR** senza IVA). **Solo iPhone** su iOS, nessuna estensione, nessun App Group.
> **Grafica**: «C · Una mano» (scelta del proprietario il 2026-10-10,
> https://claude.ai/artifact/Y9KH2qk6PeAYKzQBTyvdhY): fondo `#161B22`, verde `#4ADE80`, totale enorme in
> **Space Grotesk**, corpo **Plus Jakarta Sans**. **Tema scuro di default**, chiaro derivato.
>
> Quello che l'app prende da `micro_core` (configurazione, preferenze, acquisti, paywall, backup,
> componenti UI, `Money`, `CivilDate`) **non e' ricopiato qui**: `packages/micro_core/codebase_reference.md`.
> Il motore OCR (`OcrEngine`, `CanaleOcrEngine`, `FakeOcrEngine`, `RigaOcr`, `Riquadro`, `OcrModo`, la
> catena Kotlin PP-OCRv5, Vision, la guardia `privacy_ocr.gradle`, lo script sul binario) sta in
> `packages/micro_ocr/codebase_reference.md`. I nomi dei tipi di `micro_core`, `micro_ocr`, Flutter,
> Drift, dei plugin e delle classi generate da Drift (le righe `Negozio`, `SpesaRow`, `RigaRow` e i
> companion) compaiono anche fra apici inversi: l'elenco «citati ma assenti» di `tool/verify_atlas.ps1`
> (96 nomi al 2026-10-10) e' stato **controllato a mano** in F12.8 — solo tipi di Flutter, Drift, dei
> plugin, di `micro_core`/`micro_ocr`, costanti di piattaforma (permessi, chiavi di Info.plist),
> dart-define, i doppi dei test (`test/widget/sr_test_harness.dart`) e le costanti dello script
> `tool/esporta_fixture_ocr.py`; **nessun nome dell'app superato**. Con lo store (§2bis) sono **125**: i 29
> in piu' sono costanti di `tool/scheda_app_store.py` e `tool/genera_grafiche_store.py` (`APP`, `NOMI`,
> `RIPIEGHI`, `SCHEDE`…), stati e categorie di Apple (`VALID`, `READY_TO_SUBMIT`, `FINANCE`, `UTILITIES`),
> i dart-define `SR_DEMO`/`LINGUA`, le righe `REGISTRA`/`FINE` dei giri e `WidgetRef`/`ConsumerStatefulElement` di
> Riverpod: controllati a mano il 2026-10-10.
>
> **Come sono fatte le tabelle delle classi**: la colonna **Firma** e' estratta **a macchina** dal
> sorgente (AST dell'analyzer di Dart, F12.8) e non riscritta a mano; i campi d'istanza sono raccolti
> in una riga «campi». `costruttore: i parametri sono i campi omonimi` vuol dire esattamente quello.
>
> **Verifica a macchina (F12.8, 2026-10-10)**: `tool/verify_atlas.ps1 -Project apps/spending_review` →
> 143 simboli, **0 non documentati**; le **945** firme e testate delle tabelle cercate alla lettera nel
> sorgente normalizzato: **926 identiche + 19 inizializzatori lunghi troncati di proposito** (identici
> fino ai puntini), **0 diverse**. Alla prossima modifica: rigenerare le tabelle o ricontrollarle allo
> stesso modo.
>
> Convenzioni: ⚑ = scelta non ovvia, con il suo perche'. ☠ = trappola gia' pagata (o rischio vivo).
> **F12.x** = sottofase del piano (`develop_microapps.md`, §7 tracking e §8 «F12 — Spending Review»).
> **Dn** = risposte del proprietario alle domande aperte (§0).

---

## 0. Le decisioni che reggono tutto (F12.0 e D1–D4, 2026-10-10/11)

Prese con il proprietario (`develop_microapps.md` §8 F12.0 e F12.10; `memory/decisioni.md`, voci dal
2026-10-09 «Dati solo sul telefono» al 2026-10-10 «banco sui ritagli del mirino»). **Dove
contraddicono il resto del piano, vincono queste.**

| # | Decisione | Dove si vede nel codice | Perche' |
|---|---|---|---|
| 1 | Nome «Spending Review» uguale in it ed en; `com.smp.spendingreview`, `appId 'spending_review'`, `licenseAppId 'spendingreview'`, SKU `spendingreview_pro_lifetime`; ripiego del nome negli store gia' deciso («Spending Review – Conto spesa» / «– Cart Total») | `app_config.dart`, `build.gradle.kts`, `Info.plist`, manifest | immutabili dopo la pubblicazione |
| 2 | Android e iPhone dal primo commit, **solo iPhone**, **nessuna estensione, nessun App Group** | progetto iOS, `TARGETED_DEVICE_FAMILY = 1` | niente widget ne' condivisione |
| 3 | **Nessun widget, nessuna notifica, niente voce** in v1 | (assenze, §15.1); `POST_NOTIFICATIONS` tolto dal manifest | scelta del proprietario; la voce solo se la chiede, e solo on-device |
| 4 | **Tastierino sempre visibile** (× quantita', − sconto, ⌫, +); **budget** con barra; **due tasti**: Cartellino (verde) e Scontrino (scuro), nessun tasto «intelligente» | `SpesaPage`, `TastierinoState`, `tastiDellaSpesa` | il gesto alla cassa non deve dipendere dall'OCR |
| 5 | Il **cartellino va INTERPRETATO** (nome, prezzo da pagare, barrato/«anziche'», €/kg, offerte, centesimi piccoli); ambiguita' → **proposta da confermare con un tocco**; ☠ **mai aggiunto da solo** | `CartellinoParser`, `ConfermaCartellinoSheet` | un prezzo sbagliato nel totale costa piu' di un tocco |
| 6 | **Prodotti a peso, entrambe le strade**: peso a mano dopo un €/kg **e** etichetta della bilancia (totale stampato) | `PesoSheet`, `BilanciaParser`, `ConfermaBilanciaSheet`, `RigaSheet` «È un prezzo al kg» | |
| 7 | **Scontrino**: confronto alla cassa **e** registrazione della spesa dallo scontrino | `ConfrontoPage`, `RegistraScontrinoPage` | |
| 8 | **Lo scritto a mano non e' supportato** (zero cifre lette sui campioni c03-c05, c25): l'app lo dice | `NienteLetto(forseAMano)`, suggerimento del mirino | |
| 9 | **«Spesa gratis, revisione Pro» a 2,99 €**: gratis tastierino, budget, cartellini illimitati, bilancia, ultime 5 spese; Pro Scontrino (`documentScan`, chiave nuova), tutte le spese, statistiche (+ budget del mese), CSV, backup (ripristino gratis) | `srFeatureLimits`, `buildSrPaywall`, `ProGate` | §11 |
| 10 | **D1**: spese oltre le 5 del gratis **nascoste, mai cancellate** | `speseChiuseProvider` (limite in lettura), `osservaChiuse(limite:)`, card delle nascoste, lucchetto del dettaglio | chi compra dopo tre mesi ritrova tutto |
| 11 | **D2**: tastierino **«alla cassa»** (`249` = 2,49; virgola facoltativa) | `TastierinoState` | come le casse; il display mostra subito «0,03» per `3` |
| 12 | **D3**: **budget mensile** nel Pro oltre a quello per spesa | `SrSettingKeys.budgetMensile`, `StatisticheSpesa.budgetMese`, card nelle Statistiche | |
| 13 | **D4**: cartellino con prezzo carta fedelta' / normale → **chiedi ogni volta**, due bottoni, nessun default | `DoppioPrezzoCarta`, `PropostaCartellino.scegliCarta`, i due bottoni del foglio | niente impostazione «Ho la carta» |
| 14 | **OCR solo sul telefono**: Vision su iOS; PP-OCRv5 mobile su **ONNX Runtime 1.28.0 bloccata** su Android (dalla 1.29 telemetria Microsoft accesa); ML Kit e LiteRT 2.x esclusi | `ocrEngineProvider`, `micro_ocr`, guardia `privacy_ocr.gradle` | regola «dati solo sul telefono» |
| 15 | **Dati solo sul telefono**: nessun SDK che manda dati a terzi; unica eccezione Play Billing + server licenze | manifest, `allowBackup=false`, esclusione iCloud, guardia di build | non negoziabile (§14) |
| 16 | **Privacy delle foto**: cancellate dopo la lettura, testo OCR grezzo **mai salvato**, nessuna colonna per le foto | `LetturaService`, `Fotocamera`, `tables.dart` | i dati della carta degli scontrini (s13) |
| 17 | Riferimento del parser del cartellino = **i RITAGLI del mirino** (F12.7), non le foto larghe del web | `ritagli_mirino.json`, motori `*-mirino` del banco | nell'app si inquadra UN cartellino |
| 18 | Vision misurato sotto PP-OCRv5 (F12.7): **nessun cambio di motore** finche' non si misura sull'iPad; se il distacco resta, ORT 1.28 anche su iOS (+22 MB) — decide il proprietario | §13 (banco), §15.2 | |

## 1. Dove sta cosa

| Cerchi | File (sotto `apps/spending_review/`) | Sezione |
|---|---|---|
| L'avvio, cosa NON si fa all'avvio | `lib/main.dart` | §8.3 |
| Il router, le rotte, l'app | `lib/app/app.dart` (`buildRouter`, `SpendingReviewApp`), `lib/app/routes.dart` (`Routes`, `ChiusuraArgs`, `rottaDevAttiva`, `kSrDev`) | §8 |
| Tutti i provider (preferenze, servizi, dati, tastierino) | `lib/app/providers.dart` | §7.1 |
| Le chiavi delle preferenze | `lib/app/providers.dart` → `SrSettingKeys` | §7.1, §12.2 |
| Gratis e Pro, il paywall | `lib/app/feature_limits.dart` (`srFeatureLimits`), `lib/app/paywall_config.dart`, `lib/app/entitlement.dart`, `lib/features/common/pro_gate.dart` | §7.2, §11 |
| Colori, font, tema | `lib/app/sr_palette.dart` (`SrPalette`, `withSrLook`, `kNumeriFont`) | §7.6 |
| Come si scrivono importi, offerte, righe | `lib/app/labels.dart` | §7.4 |
| Licenze del motore OCR e dei font | `lib/app/licenze.dart` + `assets/licenses/`, `assets/fonts/OFL-*.txt` | §7.5 |
| Arrotondamenti al centesimo (half-up, interi) | `lib/domain/arrotonda.dart` | §4.1 |
| Pezzi e pesi | `lib/domain/quantita.dart` | §4.2 |
| Offerte 3x2, −30%, barrato, carta, secondo a −50% | `lib/domain/offerta.dart` | §4.3 |
| Il totale di una riga | `lib/domain/riga_spesa.dart` → `RigaSpesa.totale` | §4.4 |
| Il totale di una spesa, il budget | `lib/domain/spesa.dart` (`Spesa`, `livelloBudgetDi`) | §4.5 |
| Il tastierino «alla cassa» (logica) | `lib/domain/tastierino.dart` | §4.6 |
| Il tastierino (widget, griglia 4×4) | `lib/features/spesa/tastierino_widget.dart` | §10.2 |
| Normalizzare e confrontare nomi, formato della confezione | `lib/domain/nomi.dart` | §4.7 |
| Statistiche, budget del mese | `lib/domain/statistiche.dart` | §4.8 |
| Il confronto contato/scontrino | `lib/domain/confronto.dart` | §4.9 |
| Numeri nel testo OCR (spezzati, fusi, pesi) | `lib/domain/lettura/numeri_ocr.dart` | §5.2 |
| Righe visive, unione delle foto dello scontrino | `lib/domain/lettura/righe_visive.dart`, `unisci_parti.dart` | §5.3, §5.4 |
| Il parser del cartellino | `lib/domain/lettura/cartellino_parser.dart` | §5.5 |
| Il parser della bilancia | `lib/domain/lettura/bilancia_parser.dart` | §5.6 |
| Il parser dello scontrino | `lib/domain/lettura/scontrino_parser.dart` | §5.7 |
| Il database (tabelle, vincoli) | `lib/data/tables.dart`, `lib/data/database.dart`, `drift_schemas/drift_schema_v1.json` | §3, §6.1 |
| Le regole dei dati (spesa in corso, chiusura, nascoste) | `lib/data/spesa_repository.dart` | §6.2 |
| Il backup | `lib/data/spending_backup_source.dart` | §6.3 |
| Foto → OCR → parser, cancellazione delle foto | `lib/services/lettura_service.dart` | §9.4 |
| Ritaglio al mirino, fotocamera sostituibile, selettore | `lib/services/fotocamera.dart` | §9.3 |
| Vibrazioni | `lib/services/aptica.dart` | §9.1 |
| CSV | `lib/services/csv_export.dart` | §9.2 |
| «Apri le impostazioni» (canale nostro) | `lib/services/impostazioni_sistema.dart`, `android/.../MainActivity.kt`, `ios/Runner/AppDelegate.swift` | §9.5, §2.2 |
| LA schermata della spesa | `lib/features/spesa/spesa_page.dart` | §10.1 |
| Il giro del cartellino (risultato → foglio → riga) | `lib/features/spesa/azioni_spesa.dart` | §10.3 |
| Mirino del cartellino / bilancia | `lib/features/cartellino/cartellino_camera_page.dart` | §10.5 |
| Foglio di conferma del cartellino, «quale?» | `lib/features/cartellino/conferma_cartellino_sheet.dart` | §10.6 |
| Foglio del peso, foglio della bilancia | `lib/features/cartellino/peso_sheet.dart`, `conferma_bilancia_sheet.dart` | §10.7, §10.8 |
| Scontrino: mirino, confronto, registrazione | `lib/features/scontrino/` | §10.9–§10.11 |
| Chiusura della spesa | `lib/features/chiusura/chiusura_page.dart` | §10.12 |
| Storico e dettaglio | `lib/features/storico/` | §10.13, §10.14 |
| Statistiche e grafico | `lib/features/statistiche/` | §10.15 |
| Impostazioni, negozi, «I tuoi dati» | `lib/features/impostazioni/` | §10.16 |
| Pagina di sviluppo dell'OCR (`/dev/ocr`) | `lib/features/dev/ocr_dev_page.dart` | §10.17 |
| Mattoni grafici comuni (pagina, card, barra, avviso, foglio) | `lib/features/common/una_mano.dart` | §10.4 |
| Mirino, errore della fotocamera, bottoni sul nero | `lib/features/common/mirino.dart` | §10.4 |
| Scelta del negozio e della data | `lib/features/common/scelte.dart` | §10.4 |
| Testi (it/en) | `tool/testi.py` + `tool/testi_schermate.py` → `lib/l10n/app_{en,it}.arb` → `lib/l10n/generated/` | §12.4 |
| Banco del parser, fixture, cricchetto | `test/domain/banco_parser_test.dart`, `test/fixtures/ocr/` | §13.2 |
| Doppi finti per i test di widget | `test/widget/sr_test_harness.dart` | §13.4 |
| Flussi sul dispositivo con OCR vero | `integration_test/flussi_test.dart` | §13.5 |
| Manifest, permessi, guardia di privacy | `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts` | §2.2 |
| Esclusione da iCloud, canale iOS | `ios/Runner/AppDelegate.swift` | §2.2 |
| Icona e splash | `tool/genera_icone.py`, `flutter_launcher_icons.yaml`, `flutter_native_splash.yaml`, `assets/icon/` | §2.1 |
| I dati di esempio per screenshot e video (`SR_DEMO`) | `lib/dev/demo_data.dart` (seminati da `lib/main.dart`) | §2bis |
| Le letture finte di cartellino, bilancia e scontrino degli scatti | `integration_test/letture_finte.dart` | §2bis |
| Screenshot e video per gli store (giri sul simulatore) | `integration_test/screenshots_test.dart`, `integration_test/anteprima_test.dart`, `tool/anteprima_app_store.sh`, `tool/converti_anteprima.ps1` | §2bis |
| Grafiche delle schede (App Store, Play, intestazione e ricerca Apple) | `tool/genera_grafiche_store.py` → `store/grafiche/` | §2bis |
| Testi della scheda App Store, conteggi, note di revisione | `store/scheda-app-store.md` | §2bis |
| Caricamento su App Store Connect (scheda, IAP, build) | `tool/scheda_app_store.py` (gira sul Mac) | §2bis |

## 2. Albero dei file (solo il codice scritto da noi)

```
apps/spending_review/
├─ pubspec.yaml                 versione 1.0.0+1; dipendenze commentate (§12.5); assets licenze e font; font PlusJakartaSans/SpaceGrotesk
├─ analysis_options.yaml        le lint del monorepo
├─ l10n.yaml                    template app_en.arb (inglese = ripiego), classe L, output lib/l10n/generated
├─ flutter_launcher_icons.yaml, flutter_native_splash.yaml   icona e splash (fondo #161B22, uguale nei due temi)
├─ codebase_reference.md        questo file
├─ README.md
├─ drift_schemas/drift_schema_v1.json   lo schema 1 (base dei test di migrazione futuri)
├─ assets/
│  ├─ fonts/  PlusJakartaSans-Variable.ttf, SpaceGrotesk-Variable.ttf, OFL-PlusJakartaSans.txt, OFL-SpaceGrotesk.txt
│  ├─ icon/   originale.png, icona_ios.png, adaptive_{background,foreground,monochrome}.png, splash_logo.png, splash_android12.png, anteprime/
│  └─ licenses/  paddleocr-rapidocr.txt (copia di micro_ocr/.../LICENSE-PaddleOCR.txt), onnxruntime.txt
├─ tool/
│  ├─ testi.py                  tabella it/en delle chiavi di base → ARB (insieme a testi_schermate.py)
│  ├─ testi_schermate.py        le chiavi delle schermate (283 chiavi in tutto negli ARB)
│  ├─ genera_icone.py           icona e splash da docs/specs/icona-spending-review.png
│  ├─ esporta_fixture_ocr.py    fixture del banco: RapidOCR 3.10 (foto intere), --ritagli (mirino), --log (Vision)
│  ├─ genera_grafiche_store.py  schede App Store 6,9"/6,5", Play, testate, intestazione e ricerca Apple (§2bis)
│  ├─ scheda_app_store.py       caricamento su App Store Connect, sul Mac (§2bis)
│  ├─ anteprima_app_store.sh    registra il video grezzo sul simulatore (Mac)
│  └─ converti_anteprima.ps1    video → 886x1920 30 fps H.264 + audio muto (PC, ffmpeg)
├─ store/
│  ├─ scheda-app-store.md       testi it/en-GB contati, file, IAP, TestFlight
│  ├─ screenshots/ios/{it,en}/  gli scatti veri 1320x2868 (+ paywall-revisione.png)
│  ├─ grafiche/                 appstore/, appstore-6.5/, play/, apple/, testata-1024x500-{it,en}.png
│  └─ video/                    anteprima_sr_{it,en}.mov (grezzi) e anteprima-886x1920-{it,en}.mp4
├─ lib/
│  ├─ main.dart                 avvio minimo (§8.3); con SR_DEMO semina i dati d'esempio
│  ├─ dev/demo_data.dart        dati d'esempio per screenshot e video (SR_DEMO, mai in release, §2bis)
│  ├─ app/
│  │  ├─ app.dart               buildRouter, SpendingReviewApp (OCR preparato 3 s dopo il primo frame), _NotFoundPage
│  │  ├─ app_config.dart        licenseAppId, buildSrConfig
│  │  ├─ entitlement.dart       appVersion, gateway, EntitlementView/Notifier, isProProvider, featureGateProvider
│  │  ├─ feature_limits.dart    srFeatureLimits (16 chiavi)
│  │  ├─ labels.dart            importo, offerte, righe come testo (senza intl)
│  │  ├─ licenze.dart           registraLicenze
│  │  ├─ locale_resolution.dart kSupportedLocales, resolveAppLocale
│  │  ├─ paywall_config.dart    buildSrPaywall, showSrPaywall
│  │  ├─ providers.dart         TUTTI i provider, SrSettingKeys, ThemeModeNotifier, TastierinoNotifier
│  │  ├─ routes.dart            Routes, ChiusuraArgs, rottaDevAttiva, kSrDev
│  │  └─ sr_palette.dart        SrPalette, withSrLook, kNumeriFont
│  ├─ domain/                   Dart puro (niente Flutter): importa solo micro_core e package:micro_ocr/riga_ocr.dart
│  │  ├─ arrotonda.dart, quantita.dart, offerta.dart, riga_spesa.dart, spesa.dart
│  │  ├─ tastierino.dart, nomi.dart, statistiche.dart, confronto.dart
│  │  └─ lettura/  testo_ocr.dart, numeri_ocr.dart, righe_visive.dart, unisci_parti.dart,
│  │               cartellino_parser.dart, bilancia_parser.dart, scontrino_parser.dart
│  ├─ data/  tables.dart (Negozi, Spese, Righe), database.dart (+ database.g.dart generato), spesa_repository.dart, spending_backup_source.dart
│  ├─ services/  aptica.dart, csv_export.dart, fotocamera.dart, impostazioni_sistema.dart, lettura_service.dart
│  ├─ features/
│  │  ├─ common/  una_mano.dart, mirino.dart, scelte.dart, pro_gate.dart
│  │  ├─ spesa/   spesa_page.dart, azioni_spesa.dart, tastierino_widget.dart, riga_sheet.dart, budget_sheet.dart
│  │  ├─ cartellino/  cartellino_camera_page.dart, conferma_cartellino_sheet.dart, peso_sheet.dart, conferma_bilancia_sheet.dart
│  │  ├─ scontrino/   scontrino_camera_page.dart, confronto_page.dart, registra_scontrino_page.dart
│  │  ├─ chiusura/chiusura_page.dart
│  │  ├─ storico/     storico_page.dart, dettaglio_spesa_page.dart
│  │  ├─ statistiche/ statistiche_page.dart, grafico_mesi.dart
│  │  ├─ impostazioni/ impostazioni_page.dart, data_section.dart, negozi_page.dart
│  │  └─ dev/ocr_dev_page.dart  solo debug o SR_DEV
│  └─ l10n/  app_en.arb, app_it.arb (generati da tool/testi*.py), untranslated.json ({}), generated/
├─ test/
│  ├─ domain/  arrotonda, offerta, riga_spesa, spesa, tastierino, nomi, numeri_ocr, unisci_parti,
│  │           cartellino_parser, bilancia_parser, scontrino_parser, scontrino_subtotale, confronto,
│  │           statistiche, banco_parser (+ righe_finte.dart: le funzioni r() e rigaScontrino())
│  ├─ data/    spesa_repository_test.dart, backup_test.dart
│  ├─ services/ csv_export, fotocamera, lettura_service
│  ├─ widget/  sr_test_harness.dart + spesa_page, cartellino_camera, conferma_cartellino, confronto_page,
│  │           chiusura_page, storico_page, pro_gate, dev_route, palette_contrast, paywall_config, texts_glyphs
│  └─ fixtures/ocr/  soglie.json, ritagli_mirino.json, LICENZE.md, ppocrv5/ (33), ppocrv5-mirino/ (20),
│                    vision-sim/ (33), vision-sim-mirino/ (20)
├─ integration_test/
│  ├─ flussi_test.dart          OCR vero + database vero + foto dei campioni (SR_FOTO)
│  ├─ screenshots_test.dart     gli scatti per gli store (SCATTO:<nome>, §2bis)
│  ├─ anteprima_test.dart       il giro del video (REGISTRA … FINE, §2bis)
│  └─ letture_finte.dart        righe OCR finte ai parser veri: cartellino, bilancia, scontrino
├─ android/app/
│  ├─ build.gradle.kts          com.smp.spendingreview, minSdk 24, noCompress onnx, R8, desugaring, apply(from = privacy_ocr.gradle)
│  ├─ src/main/AndroidManifest.xml   BILLING, CAMERA; via RECORD_AUDIO, WRITE/READ_EXTERNAL_STORAGE, POST_NOTIFICATIONS; allowBackup=false; deep link spento
│  ├─ src/debug/AndroidManifest.xml  INTERNET solo per il tool di Flutter (debug)
│  └─ src/main/kotlin/com/smp/spendingreview/MainActivity.kt   canale «Apri le impostazioni»
└─ ios/Runner/
   ├─ AppDelegate.swift         esclusione di Documents/ dal backup iCloud + canale «Apri le impostazioni»
   ├─ SceneDelegate.swift       (generato)
   └─ Info.plist                CFBundleDisplayName, FlutterDeepLinkingEnabled=false, ITSAppUsesNonExemptEncryption=false, NSCamera/NSPhotoLibraryUsageDescription (it/en)
```

### 2.1 Icona e schermata di avvio

- Sorgente: `docs/specs/icona-spending-review.png` (PNG 1254×1254, del proprietario), ripulita da
  `tool/genera_icone.py` (fondo scuro `#161B22`, sagoma monocromatica con righe ed euro «bucati» per
  l'icona tematica di Android 13). Si rigenerano con `pwsh ../../tool/fl.ps1 pub run
  flutter_launcher_icons` e `… flutter_native_splash:create`.
- Splash: `#161B22` con `splash_logo.png`, **uguale nei due temi** (l'app e' scura di default; lo
  scontrino bianco si legge solo sullo scuro); Android 12+: `splash_android12.png` col disegno gia' nel
  cerchio sopravvissuto.
- ☠ Lo splash nativo resta finche' Flutter non disegna il primo frame: se il codice Dart **non chiama
  mai `runApp`** (build di un test d'integrazione) o la VM e' **in pausa** (avvio con `start-paused`),
  si vede solo lo splash. Non e' un difetto dell'app: §14.2, trappola «APK di debug fermo sullo splash».

### 2.2 Nativo: Android e iOS

| File | Cosa contiene | Perche' |
|---|---|---|
| `android/app/build.gradle.kts` | `namespace`/`applicationId` `com.smp.spendingreview` (⚑ senza trattino basso: `flutter create` aveva messo `spending_review`), `minSdk 24` (ORT 1.28), `androidResources { noCompress += "onnx" }`, Java 17 + `isCoreLibraryDesugaringEnabled` (per `flutter_local_notifications` di micro_core), firma da `key.properties` (PKCS12) o debug, release con `isMinifyEnabled`/`isShrinkResources`, `apply(from = "../../../../packages/micro_ocr/android/privacy_ocr.gradle")` | i modelli non si comprimono (decide il modulo app, non il plugin); la guardia fa FALLIRE la release se arriva telemetria (§14) |
| `AndroidManifest.xml` (main) | `com.android.vending.BILLING`, `CAMERA`; `tools:node="remove"` su `RECORD_AUDIO`, `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE` (implicito), `POST_NOTIFICATIONS`; `uses-feature camera.any required=false`; `allowBackup="false"`; `flutter_deeplinking_enabled=false`; `launchMode singleTop` | camerax dichiara microfono e storage; micro_core porta le notifiche; niente backup automatico su Drive; un link estraneo non deve finire in go_router |
| `AndroidManifest.xml` (debug) | `INTERNET` | solo per il tool di Flutter (hot reload, VM service); la guardia guarda il manifest di RELEASE |
| `MainActivity.kt` | `MethodChannel("com.smp.spendingreview/impostazioni")`, metodo `apri` → `Settings.ACTION_APPLICATION_DETAILS_SETTINGS` con `package:<id>`; risponde sempre `true`/`false` | un Intent non vale una dipendenza (`permission_handler`, `app_settings`) |
| `ios/Runner/AppDelegate.swift` | `excludeUserDataFromBackup()` PRIMA di avviare Flutter: `isExcludedFromBackup` su `Documents/`, `Documents/spending_review/`, `spending_review.sqlite{,-wal,-shm,-journal}` (errore → `NSLog`, mai un blocco); canale `com.smp.spendingreview/impostazioni` → `UIApplication.openSettingsURLString` (registrato in `didInitializeImplicitFlutterEngine`) | la cronologia della spesa non va su iCloud senza che l'utente lo scelga; la cartella intera perche' SQLite crea file nuovi |
| `ios/Runner/Info.plist` | `CFBundleDisplayName` «Spending Review», `FlutterDeepLinkingEnabled` false, `ITSAppUsesNonExemptEncryption` false, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` (varianti `InfoPlist.strings` it/en); ⚑ niente `NSMicrophoneUsageDescription` (fotocamera con `enableAudio: false`) | |

## 2bis. Lo store (2026-10-10)

App Store: app **`6821392694`** («Spending Review», bundle `com.smp.spendingreview`, creata dal
proprietario), versione **1.0.0**, build **1.0.0 (1)** (`470a0092-7449-4e6d-a212-3c121b0b85fe`), prodotto
**`spendingreview_pro_lifetime`** (id `6821405107`, `READY_TO_SUBMIT`) non consumabile a **2,99 €** (base Italia, tutti i paesi). Nome
«Spending Review» **in tutte e due le lingue** (in en-GB Apple l'ha accettato: il ripiego «– Cart Total» non
e' servito). Categorie **Finanza + Utilita'** (perche': `store/scheda-app-store.md` §2). Testi, conteggi,
file e note di revisione: `store/scheda-app-store.md`. TestFlight: gruppo interno **«Sviluppatore»**
(`253f7667-2b46-4b77-8cb9-f86b16000ae5`, tutte le build) con il proprietario, invito mandato.
**Non inviata in revisione**: la invia il proprietario dopo la prova su iPad.

### `lib/dev/demo_data.dart`

| Simbolo | Firma | Effetto |
|---|---|---|
| `demoRequested` | `const bool demoRequested = bool.fromEnvironment('SR_DEMO')` | chiesto con `--dart-define=SR_DEMO=true` |
| `demoEnabled` | `bool get demoEnabled` | `demoRequested && !kReleaseMode`: ☠ mai in release |
| `kDemoBudgetCents` | `const int kDemoBudgetCents = 4000` | budget della spesa in corso e budget abituale: 40 € |
| `kDemoBudgetMeseCents` | `const int kDemoBudgetMeseCents = 40000` | tetto del mese (Pro, D3): 400 € |
| `DemoRiga` | `typedef DemoRiga = ({String it, String en, Quantita q, int cents, Offerta? offerta, int? stampato, OrigineRiga o})` | una riga d'esempio in due lingue |
| `_pz` | `DemoRiga _pz(String it, String en, int cents, {int n = 1, Offerta? offerta, OrigineRiga o = OrigineRiga.tastierino})` | una riga a pezzi |
| `kDemoInCorso` | `final List<DemoRiga> kDemoInCorso` | la spesa in corso: 9 righe (13 articoli) da tastierino, cartellino (3x2 sulla pasta, caffe' 3,49 barrato 4,29) e bilancia (pomodori 0,486 kg → 1,90; banane 1,120 kg → 2,00); totale **26,61** |
| `_catalogo` | `const List<(String, String, int)> _catalogo` | 20 prodotti (nome it, nome en, centesimi) da cui si compone lo storico |
| `_negozi` | `const List<(String, String)> _negozi` | tre negozi **inventati** (Supermercato Sole / Sunny Market, Discount Rondine / Swallow Discount, Mercato di quartiere / Corner Market): niente insegne vere nelle schede |
| `seedDemoData` | `Future<void> seedDemoData(SpendingDatabase db, SettingsStore settings, {bool english = false}) async` | solo con `demoEnabled` e tabella `spese` vuota: ~45 spese chiuse negli ultimi ~158 giorni (una ogni 3-4, a rotazione nei tre negozi, piccole 6-9 righe e grandi 15-20, meta' con budget e qualche sforamento; un `SpesaRepository(db, ora: …)` con la data della spesa), poi la spesa in corso iniziata 25 minuti fa con `kDemoInCorso`; scrive `SrSettingKeys.budgetPredefinito` e `SrSettingKeys.budgetMensile` |

⚑ **Numeri fissi**: lo storico usa un generatore lineare con seme costante (`20261010`), cosi' gli scatti
rifatti mostrano gli stessi totali. ⚑ **Il Pro non si attiva nella demo**: lo comprano i due giri con il
gateway finto (in debug c'e' gia'), cosi' lo stesso giro fotografa il paywall per la revisione di Apple
(come QR Me). ⚑ `main.dart` apre e chiude un `SpendingDatabase` suo prima di `runApp` (quello dei provider,
pigro, lo riapre dopo); la lingua viene da `resolveAppLocale` sulle lingue del telefono.

### Le letture finte (`integration_test/letture_finte.dart`)

| Nome | Firma | Effetto |
|---|---|---|
| `_r` | `RigaOcr _r(String testo, double x, double y, double w, double h)` | una riga OCR con riquadro normalizzato, confidenza 0,95 |
| `cartellinoFinto` | `RisultatoCartellino cartellinoFinto({required bool english})` | `LettoCartellino` dal `CartellinoParser` vero: «FROLLINI AL CACAO 350 G» / «COCOA SHORTBREAD 350 G», 2,29 con 2,99 barrato, bollino −23%, 6,54 €/kg (disposizione del campione c33) |
| `bilanciaFinta` | `RisultatoCartellino bilanciaFinta({required bool english})` | `LettaBilancia` dal `BilanciaParser` vero: provola / smoked cheese 0,612 kg × 12,90 = 7,89; ☠ `StateError` se il parser non la legge |
| `scontrinoFinto` | `ScontrinoLetto scontrinoFinto({required bool english})` | lo scontrino di `kDemoInCorso` dallo `ScontrinoParser` vero: stesse righe ma caffe' a 4,29 e il sacchetto 0,15; totale 27,56 → confronto **+0,95** con due righe sospette (`PrezzoDiverso`, `SoloSulloScontrino`) e 8 che tornano |

⚑ **Perche' finte**: il simulatore non ha una fotocamera e le foto vere dei campioni non stanno nel repo.
**Perche' passate ai parser veri** e non scritte gia' interpretate: il foglio fotografato e' esattamente
quello che l'app mostra leggendo un cartellino fatto cosi'.

### I giri sul simulatore (`integration_test/`)

| File | Cosa fa |
|---|---|
| `screenshots_test.dart` | cancella preferenze, `spending_review.sqlite` (+ `-wal`, `-shm`) ed `entitlement.json`; `app.main()` (semina `SR_DEMO`); tocca `spesa_scontrino` → paywall → `SCATTO:paywall-revisione` → compra (finto) → `go('/')`; batte `2 × 1 4 9` → `spesa`; `gestisciRisultatoCartellino` con `cartellinoFinto` → `cartellino` (foglio chiuso con `pop`); con `bilanciaFinta` → `bilancia`; `push(Routes.confronto, extra: scontrinoFinto)` → `scontrino`; `/statistiche` → `statistiche`; `/storico` → `storico`. Costante `lingua` (`LINGUA`) |
| `anteprima_test.dart` | stesso azzeramento, compra il Pro **prima** di `REGISTRA`; giro: spesa → confronto dello scontrino → cartellino **aggiunto** → bilancia **aggiunta** → `2 × 1,49 +` → statistiche → storico → spesa; `FINE`. ~27 s (Apple: 15–30). ⚑ Lo scontrino PRIMA delle aggiunte: dopo, il confronto mostrerebbe le righe nuove come «non sullo scontrino» |

☠ **Niente `pumpAndSettle` dopo l'acquisto**: il Pro apre il mirino dello scontrino (`/scontrino`), e senza
fotocamera la sua rotellina non si ferma mai; i due giri aspettano a tempo (`pausa`, frame da 16-50 ms).
⚑ Il `WidgetRef` per `gestisciRisultatoCartellino` e' l'elemento di `SpesaPage`
(`tester.element(find.byType(SpesaPage)) as WidgetRef`: `ConsumerStatefulElement` implementa `WidgetRef`).

### Comandi per rifare tutto

```
# 1. screenshot (Mac, simulatore iPhone 18 Pro Max 6,9"); lo script aggiunge SR_DEMO=true
ssh mac 'bash ~/microapps/tool/screenshots_ios.sh 2E0C5359-ACED-45E8-8DD3-0ECB0C0BAF85 it ~/sr_shots/it spending_review'
#    (idem en) poi copia dei PNG in store/screenshots/ios/<lingua>/ (tar con COPYFILE_DISABLE=1)
# 2. grafiche (PC, da apps/spending_review)
python tool/genera_grafiche_store.py
# 3. video (Mac, poi PC)
ssh mac 'bash ~/microapps/apps/spending_review/tool/anteprima_app_store.sh 2E0C5359-ACED-45E8-8DD3-0ECB0C0BAF85 it'
#    copia di ~/anteprima_sr_<lingua>.mov in store/video/, poi:
pwsh tool/converti_anteprima.ps1
# 4. caricamento (Mac): testi, categorie, eta', prezzo, disponibilita', screenshot 6,5" e 6,9", video,
#    revisione, prodotto Pro, build; alla fine stampa la verifica campo per campo (rete Mac-Apple lenta)
ssh mac 'cd ~/microapps && python3 -u apps/spending_review/tool/scheda_app_store.py'
```

`tool/scheda_app_store.py` (copia di QR Me del 2026-10-09): costanti `APP` (`6821392694`), `VERSIONE`
(`1.0.0`), `BUILD` (`'1'`), `LINGUE`, `NOMI`, **`RIPIEGHI`** (nuovo: «Spending Review – Conto spesa» /
«– Cart Total», scritto solo se il nome risponde DUPLICATE), `CATEGORIE` (`FINANCE`, `UTILITIES`), `IAP_ID`,
**`IAP_NOME`**, `IAP_PREZZO` (`'2.99'`), `IAP_TESTI`, `IAP_NOTA`, `VERSIONE_TRASHCAN` (da li' copia nome e
telefono del contatto di revisione); funzioni `md5(file)`, `gia_uguale(remoti, locali)` (nome **e**
`sourceFileChecksum`, nell'ordine), `svuota(tipo_risorsa, remoti)`, `api(metodo, percorso, corpo=None,
tentativi=4)`, `controlla(r, cosa)`, `testi()`, `carica_file(...)`, `tutti_i_territori()`, `prodotto_pro()`
(in piu' rispetto a QR Me: **sfoglia le pagine** dei punti di prezzo finche' trova `IAP_PREZZO`), `main()`,
`eta(info_id)` (in piu' rispetto a QR Me: si corregge da sola sui campi che Apple rifiuta per tipo), `collega_build(versione_id)` (PATCH della versione, solo se la build e' `VALID`),
`verifica(versione_id)` (stati, poi campo per campo con gli elenchi `VUOTI`, `DOPPIONI`, «DA FARE A MANO»).

`tool/genera_grafiche_store.py` (copia di QR Me): colori di `SrPalette.scuro` (`FONDO #161B22`, `NEON` =
l'accento `#4ADE80`), `SCHEDE` (6 per lingua: `spesa`, `cartellino`, `bilancia`, `scontrino`, `statistiche`,
`storico`), `TESTATA`, `FRASI_APPLE`; testata Play con titolo a 56 px e icona 240 (a 72 «Spending Review»
finiva sotto l'icona); prima di scrivere **cancella i PNG** di ogni cartella di uscita.

### Trappole dello store (gia' pagate qui o nelle altre app)

- ☠ **Python su Windows scrive CRLF** con `write_text`/`open('w')` in modo testo: `screenshots_ios.sh`
  riscritto cosi' sul Mac fallisce con `set: pipefail: invalid option name`. Scrivere con `newline=''` o in
  binario, e controllare con `file`.
- ☠ **`tar` dal Mac porta i file `._*`** (attributi estesi di macOS) e copiarli nelle cartelle degli scatti
  li manderebbe ad Apple: `COPYFILE_DISABLE=1` sul Mac e `find … -name '._*' -delete` sul PC.
- ☠ **Nome inglese preso → ripiego** (Full Freezer, Film Tracker, QR Me): qui non e' successo, ma lo
  script lo gestisce da solo (`RIPIEGHI`).
- ☠ **Con il Pro `READY_TO_SUBMIT` descrizione e screenshot di revisione dell'IAP non si cambiano via API**
  (409 UNMODIFIABLE / MEDIA_ASSET_DELETE_NOT_ALLOWED, QR Me 2026-10-09): si cambiano a mano; lo script li
  elenca in «DA FARE A MANO».
- ☠ `GET /v1/profiles?filter[name]=` confronta per **prefisso**: filtrare a mano sul nome esatto prima di
  un DELETE (QR Me, F17.10).
- ☠ **TestFlight**: aggiungere al gruppo un tester esistente da' 409; si crea il tester con email e nome
  presi da un `betaTester` esistente del proprietario e la relazione al gruppo (`POST /v1/betaTesters`, un
  500 e' temporaneo), poi `POST /v1/betaTesterInvitations`.
- ☠ La **classificazione per eta'** via API (`eta()`): `gracRatingClassificationNumber` (Corea) fuori,
  altrimenti 409 KOREA_AGE_RATING_OVERRIDE_INVALID. ☠ **Campi nuovi null** (2026-10-10: `socialMedia`,
  `socialMediaAgeRestricted`): dal nome non si sa il tipo; scritti come `'NONE'` davano 409
  ENTITY_ERROR.ATTRIBUTE.TYPE «Expected a BOOLEAN». Ora `eta()` legge gli errori di tipo e riscrive quei campi
  col tipo giusto (fino a 3 tentativi). Esito verificato: **4+** (`appStoreAgeRating FOUR_PLUS`).
- ☠ Il primo acquisto in-app si invia **con la versione** (FIRST_NON_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION):
  la spunta nella pagina della versione e' a mano.

## 3. Il database (Drift, schema 1)

File `Documents/spending_review.sqlite` (`getApplicationDocumentsDirectory()`), aperto **pigramente**
da `databaseProvider` alla prima lettura, su un isolate di background
(`NativeDatabase.createInBackground`). Tre tabelle: `negozi`, `spese`, `righe`. Lo schema esportato e'
`drift_schemas/drift_schema_v1.json`.

⚑ **Tutti i vincoli che SQL sa esprimere stanno nel database** (CHECK, UNIQUE, chiavi esterne, indice
unico parziale): un errore di programmazione nel repository diventa un'eccezione, non un dato sbagliato
salvato in silenzio. Le regole che SQL non esprime stanno in `SpesaRepository` (§6.2).
☠ **Nessuna tabella per le foto e nessuna colonna per il testo OCR grezzo**: e' la garanzia che i dati
della carta di uno scontrino (s13: ultime cifre, autorizzazione, terminale) non finiscano mai nel
database, nel backup o nel CSV.

### 3.1 `negozi` (classe `Negozi`, riga generata `Negozio`)

| Colonna | Tipo | Vincoli | Note |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `nome` | TEXT | `NOT NULL UNIQUE COLLATE NOCASE CHECK (length(nome) BETWEEN 1 AND 60)` | ⚑ NOCASE: «Esselunga» = «ESSELUNGA» (lo scontrino e' maiuscolo). Un doppione in `rinominaNegozio` → eccezione → snack |
| `creato_il` | INTEGER | NOT NULL | epoch ms UTC |

### 3.2 `spese` (classe `Spese`, riga generata `SpesaRow`)

| Colonna | Tipo | Vincoli | Note |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `stato` | TEXT | `CHECK IN ('in_corso','chiusa')` | |
| `negozio_id` | INTEGER NULL | FK → `negozi(id)` **ON DELETE SET NULL** | eliminare un negozio lascia le spese «senza negozio» |
| `iniziata_il` | INTEGER | NOT NULL | epoch ms UTC |
| `chiusa_il` | INTEGER NULL | `CHECK ((stato = 'chiusa') = (chiusa_il IS NOT NULL))` | presente se e solo se chiusa |
| `data_spesa` | TEXT NULL | `CHECK (stato <> 'chiusa' OR data_spesa IS NOT NULL)` | `YYYY-MM-DD` (`CivilDate`, ADR-008): il giorno, dallo scontrino se letto |
| `budget_cents` | INTEGER NULL | `CHECK (budget_cents > 0)` | null = nessun budget (della SPESA; quello del mese e' una preferenza) |
| `totale_cents` | INTEGER | default 0 | ⚑ scritto alla CHIUSURA e mai ricalcolato; 0 per la spesa in corso |
| `totale_scontrino_cents` | INTEGER NULL | | il TOTALE stampato, se letto |
| `fonte` | TEXT | default `'contate'`, `CHECK IN ('contate','scontrino')` | quale insieme di righe fa fede |

Indici:
- `spese_una_in_corso`: `CREATE UNIQUE INDEX … ON spese (stato) WHERE stato = 'in_corso'` — ⚑ **una
  sola spesa in corso garantita dal database**: due tocchi veloci su «+» non possono crearne due.
- `idx_spese_storico`: `(stato, data_spesa DESC, id DESC)` — l'ordine dello storico.
- `idx_spese_negozio`: `(negozio_id)`.

### 3.3 `righe` (classe `Righe`, riga generata `RigaRow`)

| Colonna | Tipo | Vincoli | Note |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `spesa_id` | INTEGER | FK → `spese(id)` **ON DELETE CASCADE** | |
| `insieme` | TEXT | `CHECK IN ('contate','scontrino')` | ⚑ le righe dello scontrino si AFFIANCANO alle contate |
| `posizione` | INTEGER | NOT NULL | ordine dentro l'insieme; i buchi dopo un'eliminazione non contano |
| `nome` | TEXT | default `''`, `CHECK (length(nome) <= 80)` | '' = «Articolo» |
| `pezzi` | INTEGER NULL | `CHECK BETWEEN 1 AND 999` | |
| `millesimi` | INTEGER NULL | `CHECK BETWEEN 1 AND 99999` | grammi o millilitri |
| `unita` | TEXT NULL | `CHECK IN ('kg','l')` | |
| `prezzo_unitario_cents` | INTEGER | `CHECK (prezzo_unitario_cents <> 0)` | negativo solo per gli sconti |
| `totale_cents` | INTEGER | NOT NULL | `RigaSpesa.totale` al momento della scrittura (ricalcolato da `aggiornaRiga`) |
| `offerta_json` | TEXT NULL | | `Offerta.toJson()` |
| `prezzo_rif_cents` | INTEGER NULL | | €/kg o €/l stampato su un prodotto a pezzi |
| `unita_rif` | TEXT NULL | `CHECK IN ('kg','l')` | |
| `totale_stampato_cents` | INTEGER NULL | | bilancia e righe dello scontrino: vince sul calcolo |
| `origine` | TEXT | `CHECK IN ('tastierino','cartellino','bilancia','scontrino')` | |
| `stornata` | BOOLEAN | default false | solo insieme 'scontrino' |
| `creata_il` | INTEGER | NOT NULL | epoch ms UTC |

Vincolo di tabella: `CHECK ((pezzi IS NOT NULL AND millesimi IS NULL AND unita IS NULL) OR (pezzi IS
NULL AND millesimi IS NOT NULL AND unita IS NOT NULL))` — o pezzi, o peso con unita'.
Indice: `idx_righe_spesa (spesa_id, insieme, posizione)`.

### 3.4 Le classi delle tabelle

`class Negozi extends Table` — file `lib/data/tables.dart`

`@DataClassName('Negozio')`

| Membro | Firma | Effetto |
|---|---|---|
| `id` | `IntColumn get id` | colonna `id` (§3.1) |
| `nome` | `TextColumn get nome` | colonna `nome` (§3.1) |
| `creatoIl` | `IntColumn get creatoIl` | colonna `creato_il` (§3.1) |

`class Spese extends Table` — file `lib/data/tables.dart`

`@DataClassName('SpesaRow')` + i tre `@TableIndex.sql` di §3.2

| Membro | Firma | Effetto |
|---|---|---|
| `id` | `IntColumn get id` | colonna `id` (§3.2) |
| `stato` | `TextColumn get stato` | colonna `stato` (§3.2) |
| `negozioId` | `IntColumn get negozioId` | colonna `negozio_id` (§3.2) |
| `iniziataIl` | `IntColumn get iniziataIl` | colonna `iniziata_il` (§3.2) |
| `chiusaIl` | `IntColumn get chiusaIl` | colonna `chiusa_il` (§3.2) |
| `dataSpesa` | `TextColumn get dataSpesa` | colonna `data_spesa` (§3.2) |
| `budgetCents` | `IntColumn get budgetCents` | colonna `budget_cents` (§3.2) |
| `totaleCents` | `IntColumn get totaleCents` | colonna `totale_cents` (§3.2) |
| `totaleScontrinoCents` | `IntColumn get totaleScontrinoCents` | colonna `totale_scontrino_cents` (§3.2) |
| `fonte` | `TextColumn get fonte` | colonna `fonte` (§3.2) |
| `customConstraints` | `List<String> get customConstraints` | i due CHECK di tabella (§3.2) |

`class Righe extends Table` — file `lib/data/tables.dart`

`@DataClassName('RigaRow')` + `@TableIndex.sql` `idx_righe_spesa`

| Membro | Firma | Effetto |
|---|---|---|
| `id` | `IntColumn get id` | colonna `id` (§3.3) |
| `spesaId` | `IntColumn get spesaId` | colonna `spesa_id` (§3.3) |
| `insieme` | `TextColumn get insieme` | colonna `insieme` (§3.3) |
| `posizione` | `IntColumn get posizione` | colonna `posizione` (§3.3) |
| `nome` | `TextColumn get nome` | colonna `nome` (§3.3) |
| `pezzi` | `IntColumn get pezzi` | colonna `pezzi` (§3.3) |
| `millesimi` | `IntColumn get millesimi` | colonna `millesimi` (§3.3) |
| `unita` | `TextColumn get unita` | colonna `unita` (§3.3) |
| `prezzoUnitarioCents` | `IntColumn get prezzoUnitarioCents` | colonna `prezzo_unitario_cents` (§3.3) |
| `totaleCents` | `IntColumn get totaleCents` | colonna `totale_cents` (§3.3) |
| `offertaJson` | `TextColumn get offertaJson` | colonna `offerta_json` (§3.3) |
| `prezzoRifCents` | `IntColumn get prezzoRifCents` | colonna `prezzo_rif_cents` (§3.3) |
| `unitaRif` | `TextColumn get unitaRif` | colonna `unita_rif` (§3.3) |
| `totaleStampatoCents` | `IntColumn get totaleStampatoCents` | colonna `totale_stampato_cents` (§3.3) |
| `origine` | `TextColumn get origine` | colonna `origine` (§3.3) |
| `stornata` | `BoolColumn get stornata` | colonna `stornata` (§3.3) |
| `creataIl` | `IntColumn get creataIl` | colonna `creata_il` (§3.3) |
| `customConstraints` | `List<String> get customConstraints` | il CHECK pezzi XOR millesimi+unita' (§3.3) |

### 3.5 Sicurezza dei dati

| Rischio | Difesa | Dove |
|---|---|---|
| Dati della carta degli scontrini | nessuna colonna per foto o testo OCR; il parser scarta il piede; le fixture del repo ripulite e il banco controlla `(\*{4}\|[xX]{4,})\d{4}` | `tables.dart`, `ScontrinoParser`, `banco_parser_test.dart` |
| Backup automatico verso Google Drive | `android:allowBackup="false"` | manifest |
| Backup automatico verso iCloud | `isExcludedFromBackup` su `Documents/` (cartella intera) a ogni avvio | `AppDelegate.swift` (verificato sul simulatore, F12.7: `com_apple_backup_excludeItem` su `Documents/`, `Documents/spending_review/` e `spending_review.sqlite`) |
| ⚠ Fuori dall'esclusione iCloud | `Library/Application Support/spending_review/logs` (log) e le preferenze (budget, tema, vibrazione) | debito §15.2 |
| Chiavi esterne spente di default in SQLite | `PRAGMA foreign_keys = ON` in `beforeOpen` | `SpendingDatabase.migration` |
| Totali dello storico che cambiano con le regole | `totale_cents` scritto e mai ricalcolato | §6.2 |

### 3.6 Migrazioni

Alla versione 1 **non esistono**: `onUpgrade` lancia `UnsupportedError` di proposito. La prima modifica
di schema dovra' (1) alzare `schemaVersion`, (2) scrivere il passo in `SpendingDatabase.migration`, (3)
generare `drift_schemas/drift_schema_v2.json` e (4) scrivere il test di migrazione a partire da
`drift_schema_v1.json`. ☠ Senza, il primo aggiornamento in produzione perde i dati degli utenti.

## 4. `lib/domain/` — il cuore, Dart puro

⚑ **Niente Flutter nel dominio**: importa solo `micro_core` (`Money`, `CivilDate`) e
`package:micro_ocr/riga_ocr.dart` (la libreria pura con `RigaOcr`, `Riquadro`). Cosi' parser e conti si
provano in millisecondi senza motore OCR e senza piattaforma, e il banco gira sul PC.
⚑ **Soldi sempre in centesimi interi, pesi in millesimi interi**: nessun `double` nei conti (0,1 + 0,2
in virgola mobile non fa 0,3).

### 4.1 `arrotonda.dart` — al centesimo, «mezzo in su», in interi

⚑ **Perche' half-up**: le 9 etichette della bilancia dei campioni e le 4 righe pesate di s03 tornano
**solo** cosi' (0,126 kg × 7,50 = 0,945 → **0,95**; il bancario darebbe 0,94). `Money.operator *` di
micro_core usa `double.round()`: va bene per un intero, **non** per i pesi.
⚑ **Sconto percentuale: si arrotonda lo SCONTO, poi si sottrae** (c29: 2,99 −50% → sconto 1,495 → 1,50 →
1,49, come la cassa).
⚑ **La formula** `(2·|a·b| + d) ~/ (2·d)` e non `(|a·b| + d ~/ 2) ~/ d`: la seconda sbaglia con un
divisore dispari (d = 3: 1,5 deve dare 2).

`abstract final class Arrotonda` — file `lib/domain/arrotonda.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `mezzoInSu` | `static int mezzoInSu(int a, int b, int divisore)` | `a × b / divisore` arrotondato «mezzo in su» con soli interi: `(2·\|a·b\| + d) ~/ (2·d)`, segno rimesso (simmetrico). `assert(divisore > 0)` |
| `perMisura` | `static Money perMisura(Money alKgOLitro, int millesimi)` | `mezzoInSu(alKg.cents, millesimi, 1000)`: 0,258 kg × 29,90 = 7,71 |
| `scontoPercentuale` | `static Money scontoPercentuale(Money pieno, int percento)` | `mezzoInSu(pieno.cents, percento, 100)`: lo SCONTO arrotondato (0,99 −30% → 0,30) |

### 4.2 `quantita.dart`

`enum UnitaMisura { kg, l }` — file `lib/domain/quantita.dart`

`sealed class Quantita` — file `lib/domain/quantita.dart`

`sealed`: `Pezzi` o `AMisura`. Pesi e volumi in millesimi interi

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const Quantita()` | costruttore: i parametri sono i campi omonimi |

`final class Pezzi extends Quantita` — file `lib/domain/quantita.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final int n` |  |
| `()` | `const Pezzi(this.n)` | costruttore: i parametri sono i campi omonimi |
| `massimo` | `static const int massimo = 999` | 999 (CHECK della colonna `righe.pezzi`) |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class AMisura extends Quantita` — file `lib/domain/quantita.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final int millesimi` · `final UnitaMisura unita` |  |
| `()` | `const AMisura(this.millesimi, this.unita)` | costruttore: i parametri sono i campi omonimi |
| `massimo` | `static const int massimo = 99999` | 99999 (CHECK di `righe.millesimi`) |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

### 4.3 `offerta.dart` — le offerte

| Offerta | Esempio | `totale(p, q)` | Nota |
|---|---|---|---|
| `OffertaNxM(prendi: N, paghi: M)` | 3x2, 2x1, «2+1» (= 3x2), «1+1» (= 2x1), 3x1 | `p × ((q ~/ N) × M + q % N)` | ⚑ `p` e' il prezzo **PIENO** anche se il cartellino mostra in grande l'effettivo (c11: 1,26 grande, 1,89 piccolo): cosi' 3 pezzi di un 3x1 a 3,19 fanno 3,19 (non 3 × 1,06 = 3,18) e una quantita' non multipla di N torna |
| `OffertaPercentuale(x)` | bollino «−30%» col solo prezzo pieno (sconto alla cassa, c28/c30) | `q × (p − sconto(p))` | sconto arrotondato prima |
| `OffertaPrezzoBarrato(pieno)` | «anziche' 2,99» | `p × q` | **informativa**: `p` e' gia' lo scontato |
| `OffertaSecondoAPercento(x)` | «−50% sul secondo» | `p × q − (q ~/ 2) × sconto(p)` | 1..100 |
| `OffertaPrezzoConCarta(senza)` | prezzo con la carta fedelta' (D4) | `p × q` | **informativa**: `p` e' quello scelto nel foglio |

JSON in `righe.offerta_json`: `{"tipo":"nxm","prendi":3,"paghi":2}`, `{"tipo":"percentuale","percento":30}`,
`{"tipo":"barrato","pieno":299}`, `{"tipo":"secondo","percento":50}`, `{"tipo":"carta","senza":249}`.
⚑ `fromJson` e' **tollerante** (null/tipo sconosciuto/campi fuori limite → null): un dato di una
versione futura non deve far cadere lo storico; il totale scritto della riga non cambia comunque.

`sealed class Offerta` — file `lib/domain/offerta.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const Offerta()` | costruttore: i parametri sono i campi omonimi |
| `totale` | `Money totale(Money prezzoUnitario, int pezzi)` | Il totale di `pezzi` pezzi a `prezzoUnitario` con l'offerta |
| `toJson` | `Map<String, Object?> toJson()` | `{"tipo": …}` per `righe.offerta_json` |
| `fromJson` | `static Offerta? fromJson(Map<String, Object?>? json)` | Tollerante: null, tipo sconosciuto, campi fuori dai limiti → null. Tipi `nxm` (prendi 2..99 > paghi ≥ 1), `percentuale` (1..99), `barrato` (pieno > 0), `secondo` (1..100), `carta` (senza > 0); numeri double con valore intero accettati |

`final class OffertaNxM extends Offerta` — file `lib/domain/offerta.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final int prendi` · `final int paghi` |  |
| `()` | `const OffertaNxM({required this.prendi, required this.paghi})` | costruttore: i parametri sono i campi omonimi |
| `totale` | `Money totale(Money prezzoUnitario, int pezzi)` | `p × ((q ~/ N) × M + q % N)` |
| `effettivo` | `Money effettivo(Money prezzoUnitario)` | Il prezzo «effettivo» di un pezzo se se ne prendono N: `mezzoInSu(p, M, N)` (1,89 × 2/3 = 1,26) |
| `toJson` | `Map<String, Object?> toJson()` | `{tipo: nxm, prendi, paghi}` |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class OffertaPercentuale extends Offerta` — file `lib/domain/offerta.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final int percento` |  |
| `()` | `const OffertaPercentuale(this.percento)` | costruttore: i parametri sono i campi omonimi |
| `scontato` | `Money scontato(Money pieno)` | `pieno − scontoPercentuale(pieno, percento)` |
| `totale` | `Money totale(Money prezzoUnitario, int pezzi)` | `scontato(p) × q` |
| `toJson` | `Map<String, Object?> toJson()` | `{tipo: percentuale, percento}` |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class OffertaPrezzoBarrato extends Offerta` — file `lib/domain/offerta.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Money prezzoPieno` |  |
| `()` | `const OffertaPrezzoBarrato(this.prezzoPieno)` | costruttore: i parametri sono i campi omonimi |
| `totale` | `Money totale(Money prezzoUnitario, int pezzi)` | `p × q` (informativa: il prezzo e' gia' quello scontato) |
| `toJson` | `Map<String, Object?> toJson()` | `{tipo: barrato, pieno: cents}` |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class OffertaSecondoAPercento extends Offerta` — file `lib/domain/offerta.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final int percento` |  |
| `()` | `const OffertaSecondoAPercento(this.percento)` | costruttore: i parametri sono i campi omonimi |
| `totale` | `Money totale(Money prezzoUnitario, int pezzi)` | `p × q − (q ~/ 2) × scontoPercentuale(p, percento)` |
| `toJson` | `Map<String, Object?> toJson()` | `{tipo: secondo, percento}` |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class OffertaPrezzoConCarta extends Offerta` — file `lib/domain/offerta.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Money prezzoSenzaCarta` |  |
| `()` | `const OffertaPrezzoConCarta(this.prezzoSenzaCarta)` | costruttore: i parametri sono i campi omonimi |
| `totale` | `Money totale(Money prezzoUnitario, int pezzi)` | `p × q` (informativa: il prezzo e' quello scelto nel foglio) |
| `toJson` | `Map<String, Object?> toJson()` | `{tipo: carta, senza: cents}` |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

### 4.4 `riga_spesa.dart`

`enum OrigineRiga { tastierino, cartellino, bilancia, scontrino }` — file `lib/domain/riga_spesa.dart`

`OrigineRiga` cambia solo come la riga si mostra (e il CSV), mai il conto.

`final class RigaSpesa` — file `lib/domain/riga_spesa.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final int? id` · `final String nome` · `final Quantita quantita` · `final Money prezzoUnitario` · `final Offerta? offerta` · `final Money? prezzoRiferimento` · `final UnitaMisura? unitaRiferimento` · `final Money? totaleStampato` · `final OrigineRiga origine` | `nome` '' = «Articolo»; `prezzoUnitario` PIENO con NxM, €/kg o €/l a misura, negativo solo per gli sconti; `prezzoRiferimento`/`unitaRiferimento` = €/kg stampato di un prodotto a pezzi (informativo); `totaleStampato` = bilancia e scontrino (VINCE sul calcolo) |
| `()` | `const RigaSpesa({this.id, required this.nome, required this.quantita, required this.prezzoUnitario, this.offerta, this.prezzoRiferimento, this.unitaRiferimento, this.totaleStampato, required this.origine})` | costruttore: i parametri sono i campi omonimi |
| `nomeMassimo` | `static const int nomeMassimo = 80` | 80 (colonna `righe.nome`) |
| `totale` | `Money get totale` | `totaleStampato` se c'e'; a pezzi `offerta.totale(p, n)` o `p × n`; a misura `perMisura(p, millesimi)`, con `OffertaPercentuale` applicata all'importo pesato (le altre offerte a misura si ignorano) |
| `eSconto` | `bool get eSconto` | `prezzoUnitario.isNegative` |
| `pezzi` | `int? get pezzi` | n per `Pezzi`, null a misura |
| `copyWith` | `RigaSpesa copyWith({int? id, String? nome, Quantita? quantita, Money? prezzoUnitario, Offerta? offerta, bool togliOfferta = false, Money? prezzoRiferimento, UnitaMisura? unitaRiferimento, Money? totaleStampato, bool togliTotaleStampato = false, OrigineRiga? origine})` | ⚑ null = «lascia»; per togliere offerta o totale stampato servono `togliOfferta`/`togliTotaleStampato` |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

### 4.5 `spesa.dart`

`enum StatoSpesa { inCorso, chiusa }` — file `lib/domain/spesa.dart`

`enum FonteRighe { contate, scontrino }` — file `lib/domain/spesa.dart`

`enum LivelloBudget { nessuno, ok, vicino, sforato }` — file `lib/domain/spesa.dart`

| Nome | Firma | Effetto |
|---|---|---|
| `livelloBudgetDi` | `LivelloBudget livelloBudgetDi(Money speso, Money? budget)` | In interi: nessun budget (o ≤ 0) → `nessuno`; `speso > budget` → `sforato`; `speso × 100 ≥ budget × 80` → `vicino` (80% e 100% ESATTI sono vicino); altrimenti `ok` |

⚑ **Il budget e' della spesa, non una tabella** (la spesa grande del sabato non e' quella del pane): il
«budget abituale» e' una preferenza che precompila quello della spesa nuova; il budget del **mese** (D3)
e' un tetto a parte (`StatisticheSpesa.budgetMese`). ⚑ Soglie **in interi** perche' i bordi (80% e 100%
esatti) cadano sempre dalla stessa parte.

`final class Spesa` — file `lib/domain/spesa.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final int? id` · `final StatoSpesa stato` · `final int? negozioId` · `final DateTime iniziataIl` · `final DateTime? chiusaIl` · `final CivilDate? dataSpesa` · `final Money? budget` · `final List<RigaSpesa> righe` · `final List<RigaSpesa> righeScontrino` · `final Money? totaleScontrino` · `final FonteRighe fonte` · `final Money? totaleSalvato` | `righe` = le contate in ordine; `righeScontrino` affiancate (Pro); `totaleSalvato` = `spese.totale_cents` di una CHIUSA (null in corso). ⚑ Campo in piu' della specsheet: senza, lo storico si ricalcolerebbe |
| `()` | `const Spesa({this.id, required this.stato, this.negozioId, required this.iniziataIl, this.chiusaIl, this.dataSpesa, this.budget, required this.righe, this.righeScontrino = const [], this.totaleScontrino, this.fonte = FonteRighe.contate, this.totaleSalvato})` | costruttore: i parametri sono i campi omonimi |
| `totaleContato` | `Money get totaleContato` | Somma dei totali delle righe contate |
| `totale` | `Money get totale` | `totaleSalvato` se chiusa; altrimenti fonte scontrino → `totaleScontrino ?? somma righeScontrino`, fonte contate → `totaleContato` |
| `articoli` | `int get articoli` | Pezzi + 1 per ogni riga a misura, sconti esclusi («9 articoli») |
| `residuoBudget` | `Money? get residuoBudget` | `budget − totale` (negativo = sforato); null senza budget |
| `livelloBudget` | `LivelloBudget get livelloBudget` | `livelloBudgetDi(totale, budget)` |
| `sforata` | `bool get sforata` | `livelloBudget == sforato` (statistiche) |
| `toString` | `String toString()` | testo per log e messaggi dei test |

### 4.6 `tastierino.dart` — la macchina a stati «alla cassa» (D2)

I 16 tasti: `7 8 9 ⌫ / 4 5 6 × / 1 2 3 − / 0 00 , +`.

| Sequenza | Display | «+» aggiunge |
|---|---|---|
| `2 4 9` | «2,49» | 2,49 × 1 |
| `2 , 4 9` | «2,49» | 2,49 × 1 |
| `3` | «0,03» | 0,03 (⚑ l'errore si vede PRIMA del +) |
| `3 ,` | «3,» | 3,00 |
| `3 00` | «3,00» | 3,00 |
| `3 ×` poi `2 4 9` | «3 ×» → «3 × 2,49» | 2,49 × 3 (numero ≤ 2 cifre senza virgola = QUANTITA') |
| `2 4 9 ×` poi `3` | «2,49 ×» → «2,49 × 3» | 2,49 × 3 (3+ cifre o virgola = PREZZO) |
| `− 1 5 0` | «− 1,50» | −1,50 × 1 (sconto; il segno non entra in una moltiplicazione) |
| «+» a display vuoto | — | `IncrementaUltima` (+1 all'ultima riga a pezzi) |
| «+» con 0,00, «××», «×» a vuoto, 3° decimale, oltre 9999,99, quantita' > 99 | invariato | rifiutato (vibrazione d'errore) |

⚑ **Come e' fatto dentro**: lo stato e' **la sola lista dei tasti accettati**; display, validita' e
valore si ricavano rileggendola da capo (`_Lettura.di`). «⌫ toglie l'ultimo carattere logico» diventa
«togli l'ultimo tasto», e le regole stanno in un posto solo: un tasto e' accettato se la lista allungata
si rilegge. `00` entra come due `0` (⌫ ne toglie uno). Il display e' costruito **senza intl** (virgola
fissa: l'app e' in euro anche in inglese).
Conseguenza da sapere: 0,99 × 3 si batte `0 9 9 × 3`, `, 9 9 × 3` o `3 × 9 9`.

`enum TastoTastierino { c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c00, virgola, per, meno, cancella, piu }` — file `lib/domain/tastierino.dart`

`sealed class EffettoTasto` — file `lib/domain/tastierino.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const EffettoTasto()` | costruttore: i parametri sono i campi omonimi |

`final class NessunEffetto extends EffettoTasto` — file `lib/domain/tastierino.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final bool rifiutato` | `rifiutato` → vibrazione d'errore |
| `()` | `const NessunEffetto({this.rifiutato = false})` | costruttore: i parametri sono i campi omonimi |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class AggiungiRiga extends EffettoTasto` — file `lib/domain/tastierino.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Money prezzo` · `final int pezzi` | `prezzo` (negativo = sconto, allora `pezzi` = 1) × `pezzi` |
| `()` | `const AggiungiRiga({required this.prezzo, required this.pezzi})` | costruttore: i parametri sono i campi omonimi |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class IncrementaUltima extends EffettoTasto` — file `lib/domain/tastierino.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const IncrementaUltima()` | costruttore: i parametri sono i campi omonimi |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`IncrementaUltima`: ⚑ se l'ultima riga e' a misura, uno sconto o ha il totale stampato lo rifiuta chi
applica l'effetto (`SpesaRepository.incrementaUltima` ritorna false): il tastierino non conosce le righe.

`final class TastierinoState` — file `lib/domain/tastierino.dart`

La macchina a stati «alla cassa» (D2). Lo stato e' SOLO la lista dei tasti accettati; display, validita' e valore si ricavano rileggendola (`_Lettura`)

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final List<TastoTastierino> _tasti` |  |
| `vuoto()` | `const TastierinoState.vuoto()` | Display vuoto |
| `_()` | `const TastierinoState._(this._tasti)` | Dalla lista dei tasti (privato) |
| `daPrezzo()` | `factory TastierinoState.daPrezzo(Money prezzo)` | Le cifre del prezzo «alla cassa» (2,49 → `2 4 9`, con `meno` se negativo); vuoto se la lista non si rilegge (oltre il massimo) |
| `centesimiMassimi` | `static const int centesimiMassimi = 999999` | 999999 (9999,99 €) |
| `quantitaMassima` | `static const int quantitaMassima = 99` | 99 |
| `display` | `String get display` | «2,49», «3 × 2,49», «2,49 × 3», «− 1,50», «» — senza intl, virgola fissa |
| `vuoto` | `bool get vuoto` | Nessun tasto |
| `premi` | `(TastierinoState, EffettoTasto) premi(TastoTastierino tasto)` | ⌫ → toglie l'ultimo tasto; `+` a vuoto → `IncrementaUltima`; `+` con valore → `AggiungiRiga` e svuota (valore nullo → rifiutato); `00` → due `0`; altro → `_prova` |
| `svuota` | `TastierinoState svuota()` | `TastierinoState.vuoto()` |
| `_prova` | `(TastierinoState, EffettoTasto) _prova(List<TastoTastierino> nuovi)` | Accetta il tasto se la lista allungata si rilegge, altrimenti `NessunEffetto(rifiutato: true)` |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class _Numero` — file `lib/domain/tastierino.dart`

Un numero in costruzione: `cifre`, `virgola`, `decimali`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `String cifre` · `bool virgola` · `String decimali` |  |
| `vuoto` | `bool get vuoto` | niente cifre e niente virgola |
| `centesimi` | `int get centesimi` | senza virgola: le cifre SONO centesimi; con la virgola: euro × 100 + decimali (0..2) |
| `aggiungi` | `bool aggiungi(String c)` | Aggiunge una cifra; false se 3° decimale, oltre 8 cifre o oltre 9999,99 |
| `formattato` | `String get formattato` | «2,49» (senza virgola: centesimi formattati; con: «euro,decimali» come battuto) |

`final class _Lettura` — file `lib/domain/tastierino.dart`

La rilettura della lista di tasti: `negativo`, `primo`, `per`, `quantitaPrima`, `secondo`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `bool negativo` · `final _Numero primo` · `bool per` · `bool quantitaPrima` · `final _Numero secondo` |  |
| `_()` | `_Lettura._()` | privato |
| `di` | `static _Lettura? di(List<TastoTastierino> tasti)` | Rilegge la lista; null se un tasto non e' valido in quel punto |
| `_applica` | `bool _applica(TastoTastierino t)` | `meno` inverte il segno (vietato dopo `×`); `×` una volta sola, non a vuoto, non con il segno, decide `quantitaPrima` (senza virgola e ≤ 2 cifre); virgola vietata nella quantita' dopo il prezzo; cifre nel numero corrente (quantita' dopo il prezzo: max 3 cifre) |
| `_corrente` | `_Numero get _corrente` | `secondo` dopo `×`, altrimenti `primo` |
| `display` | `String get display` | Il testo del display |
| `valore` | `(Money, int)? valore()` | (prezzo, pezzi) o null (valore 0, pezzi 0 o > 99, numero mancante) |

### 4.7 `nomi.dart` — nomi dei prodotti

⚑ La similarita' divide per il nome piu' **LUNGO**: «ACQUA» non deve valere 1 contro «ACQUA MINERALE
NATURALE 6X1,5 L». «PR COTTO» ~ «PROSCIUTTO COTTO» = 0,5 (COTTO si', PR no: 2 lettere sono troppo poche).
⚑ In `normalizza` i formati si tolgono **prima** della punteggiatura: «GR.600» e' un formato solo finche'
il punto c'e'.

`abstract final class Nomi` — file `lib/domain/nomi.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `_accenti` | `static const Map<String, String> _accenti = {'À': 'A', 'Á': 'A', 'Â': 'A', 'Ä': 'A', 'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', 'Ì': 'I',…` |  |
| `_unita` | `static const String _unita = r'(?:KG\|GR\|G\|ML\|CL\|LT\|L)'` |  |
| `_formati` | `static final List<RegExp> _formati = [RegExp('\\b\\d+\\s*[X×]\\s*\\d+(?:[.]\\d+)?\\s*$_unita\\b'), RegExp('\\b\\d+(?:[.]\\d+)?\…` |  |
| `normalizza` | `static String normalizza(String nome)` | Maiuscolo, senza accenti, formati tolti PRIMA della punteggiatura («GR.600», «200 G», «6X180 ML», «LT 1», «X2»), non alfanumerici → spazio, spazi singoli |
| `similarita` | `static double similarita(String a, String b)` | 0..1: max fra Jaccard sulle parole e «prefissi» (coppie uguali o con prefisso ≥ 3 lettere, divise per le parole del nome piu' LUNGO) |
| `_parole` | `static List<String> _parole(String s)` | Le parole di `normalizza` |
| `_simili` | `static bool _simili(String p, String q)` | Uguali, o la piu' corta (≥ 3 lettere, solo lettere) e' l'inizio dell'altra |
| `formato` | `static AMisura? formato(String nome)` | Il formato della confezione dal nome: «6x180 ml» → 1080 ml; «200 g» → 200 g; «GR.600» → 600 g; «LT 1» → 1000 ml; null se assente o fuori 1..99999 |
| `_limite` | `static AMisura? _limite(AMisura? m)` | null fuori da 1..`AMisura.massimo` |
| `_millesimi` | `static AMisura? _millesimi(String numero, String unita)` | Numero + unita' → millesimi interi (G/GR, KG, ML, CL, L/LT) |

### 4.8 `statistiche.dart` (Pro)

⚑ Il totale di ogni spesa e' `Spesa.totale`: segue la fonte e, per le chiuse, e' quello **scritto alla
chiusura**. Contano solo le spese CHIUSE con `dataSpesa` (tranne `budgetMese`, che somma anche la spesa
in corso: il tetto del mese serve proprio mentre si spende).

`final class VoceNegozio` — file `lib/domain/statistiche.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final int? negozioId` · `final String nome` · `final int spese` · `final Money totale` |  |
| `()` | `const VoceNegozio({required this.negozioId, required this.nome, required this.spese, required this.totale})` | costruttore: i parametri sono i campi omonimi |
| `media` | `Money get media` | `totale ~/ spese` (mai null: una voce ha almeno una spesa) |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class MeseSpesa` — file `lib/domain/statistiche.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final int anno` · `final int mese` · `final int spese` · `final int sforamenti` · `final int conBudget` · `final Money totale` | `sforamenti` = spese oltre il loro budget; `conBudget` = spese con un budget |
| `()` | `const MeseSpesa({required this.anno, required this.mese, required this.spese, required this.totale, required this.sforamenti, required this.conBudget})` | costruttore: i parametri sono i campi omonimi |
| `media` | `Money? get media` | null se nessuna spesa («nessun dato» non e' zero) |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class BudgetMese` — file `lib/domain/statistiche.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final int anno` · `final int mese` · `final Money tetto` · `final Money speso` |  |
| `()` | `const BudgetMese({required this.anno, required this.mese, required this.tetto, required this.speso})` | costruttore: i parametri sono i campi omonimi |
| `residuo` | `Money get residuo` | `tetto − speso` |
| `livello` | `LivelloBudget get livello` | `livelloBudgetDi(speso, tetto)` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`abstract final class StatisticheSpesa` — file `lib/domain/statistiche.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `mese` | `static MeseSpesa mese(List<Spesa> chiuse, int anno, int mese)` | Solo CHIUSE con `dataSpesa` nel mese: spese, totale (`Spesa.totale`), sforamenti, con budget |
| `ultimiMesi` | `static List<MeseSpesa> ultimiMesi(List<Spesa> chiuse, CivilDate oggi, {int n = 6})` | Gli ultimi `n` mesi fino a quello di `oggi`, anche vuoti, dal piu' vecchio |
| `perNegozio` | `static List<VoceNegozio> perNegozio(List<Spesa> chiuse, Map<int, String> nomi, CivilDate da, CivilDate a, {String senzaNegozio = ''})` | Per negozio nel periodo [da, a]: totale decrescente (a parita' per nome); «Senza negozio» (e negozi spariti da `nomi`) in fondo con `senzaNegozio` |
| `riepilogo` | `static ({Money? media, int sforamenti, int conBudget}) riepilogo(List<Spesa> chiuse, CivilDate da, CivilDate a)` | Media del periodo (`Money.average`, null se vuoto) e sforamenti/con budget |
| `budgetMese` | `static BudgetMese budgetMese(List<Spesa> chiuse, Money tetto, int anno, int mese, {Spesa? inCorso})` | Chiuse del mese + la spesa IN CORSO se iniziata (ora locale) in quel mese |
| `_chiuse` | `static Iterable<Spesa> _chiuse(List<Spesa> spese)` | Chiuse con `dataSpesa` |
| `_nelPeriodo` | `static Iterable<Spesa> _nelPeriodo(List<Spesa> spese, CivilDate da, CivilDate a)` | Chiuse con `da ≤ dataSpesa ≤ a` |

### 4.9 `confronto.dart` — contato contro scontrino

⚑ Si confrontano **totali di riga** («3 × 0,35» contato e «ACQUA 1,05» sullo scontrino si abbinano);
l'importo e' l'indizio piu' affidabile (le descrizioni dello scontrino sono troncate a ~18-20 caratteri e
abbreviate). Deterministico.

Algoritmo di `Confronto.confronta(contate, scontrino)`:
1. Dallo scontrino: articoli **non stornati**; ogni sconto si **somma all'articolo che lo precede** (s06:
   «OFFERTA -0,40» sotto i cornetti); uno sconto senza articolo prima resta libero; gli storni si ignorano.
2. Passata 1: stesso importo e `Nomi.similarita ≥ 0,5`, per similarita' decrescente → abbinate.
3. Passata 2: stesso importo, nome qualsiasi, in ordine → abbinate.
4. Passata 3: `similarita ≥ 0,6` e importo diverso → `PrezzoDiverso`.
5. Righe dello scontrino rimaste: uguali (importo e nome normalizzato) a una gia' abbinata →
   `ForseDoppia` («battuto due volte?»), altrimenti `SoloSulloScontrino` (il sacchetto).
6. Righe contate rimaste → `NonSulloScontrino`. Sospette ordinate per |delta| decrescente.
7. `totaleScontrino` = TOTALE stampato o somma delle righe.

`sealed class RigaSospetta` — file `lib/domain/confronto.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const RigaSospetta()` | costruttore: i parametri sono i campi omonimi |
| `delta` | `Money get delta` | Quanto in PIU' paghi rispetto al contato (negativo = meno) |

`final class PrezzoDiverso extends RigaSospetta` — file `lib/domain/confronto.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final RigaSpesa contata` · `final RigaScontrino scontrino` |  |
| `()` | `const PrezzoDiverso(this.contata, this.scontrino)` | costruttore: i parametri sono i campi omonimi |
| `delta` | `Money get delta` | `scontrino.importo − contata.totale` |

`final class SoloSulloScontrino extends RigaSospetta` — file `lib/domain/confronto.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final RigaScontrino scontrino` |  |
| `()` | `const SoloSulloScontrino(this.scontrino)` | costruttore: i parametri sono i campi omonimi |
| `delta` | `Money get delta` | `scontrino.importo` |

`final class NonSulloScontrino extends RigaSospetta` — file `lib/domain/confronto.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final RigaSpesa contata` |  |
| `()` | `const NonSulloScontrino(this.contata)` | costruttore: i parametri sono i campi omonimi |
| `delta` | `Money get delta` | `−contata.totale` |

`final class ForseDoppia extends RigaSospetta` — file `lib/domain/confronto.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final RigaSpesa contata` · `final RigaScontrino scontrino` |  |
| `()` | `const ForseDoppia(this.contata, this.scontrino)` | costruttore: i parametri sono i campi omonimi |
| `delta` | `Money get delta` | `scontrino.importo` |

`final class Abbinamento` — file `lib/domain/confronto.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final RigaSpesa contata` · `final RigaScontrino scontrino` |  |
| `()` | `const Abbinamento(this.contata, this.scontrino)` | costruttore: i parametri sono i campi omonimi |

`final class EsitoConfronto` — file `lib/domain/confronto.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Money totaleScontrino` · `final Money totaleContato` · `final List<Abbinamento> abbinate` · `final List<RigaSospetta> sospette` | `totaleScontrino` = TOTALE stampato o somma; `sospette` per \|delta\| decrescente |
| `()` | `const EsitoConfronto({required this.totaleScontrino, required this.totaleContato, required this.abbinate, required this.sospette})` | costruttore: i parametri sono i campi omonimi |
| `differenza` | `Money get differenza` | `totaleScontrino − totaleContato` (positivo = paghi di piu') |
| `tuttoTorna` | `bool get tuttoTorna` | differenza zero e nessuna sospetta |

`final class _Voce` — file `lib/domain/confronto.dart`

Riga dello scontrino con l'importo mutabile (gli sconti che la seguono gia' sommati)

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final RigaScontrino riga` · `Money importo` |  |
| `()` | `_Voce(this.riga, this.importo)` | costruttore: i parametri sono i campi omonimi |

`abstract final class Confronto` — file `lib/domain/confronto.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `confronta` | `static EsitoConfronto confronta(List<RigaSpesa> contate, LetturaScontrino scontrino)` | Deterministico (§4.9): sconti sommati all'articolo prima, storni ignorati; passata 1 stesso importo + similarita' ≥ 0,5; passata 2 stesso importo; passata 3 similarita' ≥ 0,6 → `PrezzoDiverso`; resto scontrino → `ForseDoppia` o `SoloSulloScontrino`; resto contato → `NonSulloScontrino`; sospette per \|delta\| decrescente |
| `_conImporto` | `static RigaScontrino _conImporto(_Voce v)` | La riga dello scontrino con l'importo comprensivo dei suoi sconti |

## 5. `lib/domain/lettura/` — dai riquadri OCR ai dati

### 5.1 Il principio

⚑ **I parser lavorano sui RIQUADRI, non sul testo**: i prezzi grandi con i centesimi in apice escono
dall'OCR senza virgola («229») o spezzati in due riquadri («1» | «06»), e solo posizione e altezza dicono
che sono un prezzo (f12-ocr.md §7). ⚑ **Un solo parser per Vision e PP-OCR**: tutti lavorano su
`RigaOcr` (testo + `Riquadro` normalizzato 0..1 con l'origine in alto a sinistra + confidenza), qualunque
sia il motore. PP-OCR spezza una riga in piu' riquadri, Vision spesso la da' intera: `RigheVisive` le
riporta alla stessa forma. ☠ Il testo OCR grezzo vive **solo in memoria** il tempo del parser.

### 5.2 `testo_ocr.dart` e `numeri_ocr.dart`

`abstract final class TestoOcr` — file `lib/domain/lettura/testo_ocr.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `_accenti` | `static const Map<String, String> _accenti = {'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i',…` |  |
| `chiave` | `static String chiave(String testo)` | Minuscolo senza accenti (e ’ ` → '): le regex delle parole chiave sono scritte cosi' |
| `_gemelle` | `static const Map<String, String> _gemelle = {'А': 'A', 'В': 'B', 'Е': 'E', 'К': 'K', 'М': 'M', 'Н': 'H', 'О': 'O', 'Р': 'P', 'С': 'C',…` |  |
| `latino` | `static String latino(String testo)` | Lettere cirilliche/greche gemelle → latine (Vision, F12.7) |
| `lettere` | `static int lettere(String testo)` | Quante lettere (anche accentate) |
| `data` | `static final RegExp data = RegExp(r'\b(\d{2})[-/.](\d{2})[-/.](\d{4}\|\d{2})\b')` | `gg/mm/aa(aa)` con `/`, `.` o `-` |

⚑ `TestoOcr.latino` (F12.7): Vision a volte restituisce lettere **cirilliche** identiche alle latine
(«ІКАО ВІССН.ВІККА» per «NUTKAO BICCH.BIRRA»): a occhio uguali, ma nessuna regex le riconosce. Le chiama
`NumeriOcr.pulisci` per prima cosa.

`enum FormaNumero { esplicito, spezzato, fuso, peso }` — file `lib/domain/lettura/numeri_ocr.dart`

`final class NumeroOcr` — file `lib/domain/lettura/numeri_ocr.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Money valore` · `final Riquadro riquadro` · `final FormaNumero forma` · `final String testo` | `valore` (per `peso` i MILLESIMI nei `cents`), `riquadro` (porzione della riga in proporzione ai caratteri), `forma`, `testo` |
| `()` | `const NumeroOcr({required this.valore, required this.riquadro, required this.forma, required this.testo})` | costruttore: i parametri sono i campi omonimi |
| `millesimi` | `int get millesimi` | `valore.cents` (solo per `FormaNumero.peso`) |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`abstract final class NumeriOcr` — file `lib/domain/lettura/numeri_ocr.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `_migliaia` | `static final RegExp _migliaia = RegExp(r'(?<![\d.])(\d{1,3}(?:\.\d{3})+),(\d{2})(?![.]?\d)(?!\s*%)')` |  |
| `_semplice` | `static final RegExp _semplice = RegExp(r'(?<![\d.])(\d{1,4})[.](\d{2,3})(?![.]?\d)(?!\s*%)')` |  |
| `pulisci` | `static String pulisci(String testo)` | `latino`; € ed EUR tolti (EURO resta); «16..50» → «16,50»; «AILC.12,80» → «AILC 12,80»; spazi fra cifre e separatore tolti; O/o→0, I/l/\|→1, S→5 solo fra cifre o accanto al separatore (la l mai: «0,5l») |
| `espliciti` | `static List<NumeroOcr> espliciti(RigaOcr riga)` | I numeri di una riga (la pulisce lei): migliaia «1.100,00», semplici `\d{1,4}[.,]\d{2}` (esplicito) o `\d{1,4}[.,]\d{3}` (peso); mai dentro numeri piu' lunghi, mai seguiti da «%»; segno da meno davanti o dietro; ordinati per x |
| `_segno` | `static int _segno(String t, int inizio, int fine)` | -1 con «-0,40», «- 0,40» o «0,40-» |
| `_numero` | `static NumeroOcr _numero(RigaOcr riga, String testo, int inizio, int fine, int valore, FormaNumero forma)` | Costruisce il `NumeroOcr` con il riquadro proporzionale ai caratteri |
| `spezzati` | `static List<NumeroOcr> spezzati(List<RigaOcr> righe)` | Euro grandi + centesimi in apice in due riquadri: A 1..4 cifre, B 2 cifre alta 0,25..0,75 × A, sinistra fra A.destra − 0,2·hA e A.destra + 0,6·hA, alto ≤ A.alto + 0,5·hA |
| `fusi` | `static List<NumeroOcr> fusi(List<RigaOcr> righe)` | 3..5 cifre sole in un riquadro alto ≥ 1,5 × mediana delle righe con lettere → ultime 2 cifre = centesimi; nessuna riga con lettere → nessun fuso |

⚑ In `pulisci` le sostituzioni O→0, I/l/|→1, S→5 valgono **fra cifre** o accanto al separatore, non
«accanto a una cifra»: «0,5l» (mezzo litro) non deve diventare «0,51». «EURO» resta (parola chiave dello
scontrino «TOTALE EURO»). Un numero seguito da «%» non e' un prezzo («12,50 % vol.» del vino, l'aliquota
«22,00%»). Lookbehind/lookahead: «08.01.2022» non contiene il prezzo 8,01.
⚑ In `spezzati` il limite verticale e' 0,5 altezze e non lo 0,35 della specsheet: in c02 i centesimi
partono appena sotto il terzo superiore delle cifre grandi.

### 5.3 `righe_visive.dart`

⚑ **Fascia media e non unione**: su uno scontrino storto (s03, s09) l'unione dei riquadri cresce a ogni
pezzo e inghiotte la riga sotto; la media resta alta quanto una riga e segue l'inclinazione.
⚑ **La soglia della colonna dei prezzi e' sul TESTO** (60% fra il bordo sinistro e destro di tutte le
righe lette), non sull'immagine: uno scontrino fotografato con margini ha i prezzi al 55% dell'immagine
ma al 95% del testo.

`final class RigaVisiva` — file `lib/domain/lettura/righe_visive.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final List<RigaOcr> pezzi` · `final double sogliaDestra` | `pezzi` da sinistra a destra; `sogliaDestra` = 60% della larghezza del TESTO (non dell'immagine) |
| `()` | `const RigaVisiva(this.pezzi, {this.sogliaDestra = 0.6})` | costruttore: i parametri sono i campi omonimi |
| `testo` | `String get testo` | I pezzi uniti da spazi |
| `riquadro` | `Riquadro get riquadro` | L'unione dei riquadri |
| `confidenza` | `double get confidenza` | Media pesata sulla lunghezza del testo (non la minima) |
| `numeri` | `List<NumeroOcr> get numeri` | `NumeriOcr.espliciti` di ogni pezzo |
| `importoADestra` | `NumeroOcr? get importoADestra` | L'ultimo esplicito a 2 decimali che finisce oltre `sogliaDestra`: la colonna dei prezzi |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`abstract final class RigheVisive` — file `lib/domain/lettura/righe_visive.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `raggruppa` | `static List<RigaVisiva> raggruppa(List<RigaOcr> righe)` | Ordina per centro y; un riquadro entra nella riga se la sovrapposizione verticale con la FASCIA MEDIA della riga (media di alti e bassi) e' ≥ 0,5; soglia destra = minX + 0,6·(maxX − minX) |

### 5.4 `unisci_parti.dart` — lo scontrino in piu' foto

Uno scontrino di 40 righe in una foto sola ha i caratteri troppo piccoli: si fotografa in 2–4 pezzi
dall'alto in basso. ⚑ Le coordinate si **impilano** (la parte i occupa [i, i+1] in verticale), cosi'
`RigheVisive` lavora sul tutto senza sapere delle foto. ☠ Una giunzione non trovata vuol dire «forse righe
doppie o mancanti»: confronto e registrazione lo dicono («Ho unito N foto senza trovare il punto di unione»).

`abstract final class UnisciParti` — file `lib/domain/lettura/unisci_parti.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `unisci` | `static ({List<RigaOcr> righe, List<bool> giunzioniTrovate}) unisci(List<List<RigaOcr>> parti)` | Righe visive di ogni parte concatenate; se le ultime k (≥ 2) della parte i coincidono con le prime k della i+1 si saltano; y della parte i spostata di +i; ritorna anche `giunzioniTrovate` |
| `_sovrapposte` | `static int _sovrapposte(List<RigaVisiva> a, List<RigaVisiva> b)` | Il k piu' grande di righe coincidenti in coda/testa (0 se nessuno) |
| `_uguali` | `static bool _uguali(RigaVisiva x, RigaVisiva y)` | Stesso `importoADestra` e testo uguale o similarita' ≥ 0,8 |

### 5.5 `cartellino_parser.dart` — il cartellino interpretato

**Algoritmo di `CartellinoParser.interpreta`** (i passi numerati sono quelli di F12.1.4):
1. **Pulizia**: righe con confidenza ≥ 0,30 e area del riquadro ≥ 0,0004; testo `NumeriOcr.pulisci`.
2. **Candidati** (`_candidati`): prima gli **spezzati** (anche il riquadro dei centesimi si marca usato),
   poi i **fusi**, poi gli **espliciti** riga per riga. Un meno SOLO DOPO il numero («0.99-», la coda del
   € stilizzato letta da Vision su c30) vale positivo; un meno davanti resta uno sconto. Ripiego: nessun
   candidato ma righe di sole 3-4 cifre (c13) → valgono come fusi.
3. **Ruolo dal contesto** (`_ruoloDaContesto`): unita' subito dopo («2,10 L.», «10,60 kg») o subito
   prima («Al kg € 9,90», «AI L», «AILC1,84», «AILC.12,80»); poi il **segmento** del numero (il testo fra
   il numero precedente e il successivo, ⚑ tagliato al primo `_separatore` « - », «|», «;», «soit» quando
   la riga ha piu' numeri: «250 g: 1,89 € - Soit le kg: 7,56 €», c11); poi le righe **senza numeri**
   della stessa riga visiva e quelle entro 1,5 altezze (⚑ «€/kg» accanto al prezzo piccolo non deve
   trasformare in €/kg il prezzo grande; un «Al kg» piccolo a SINISTRA seguito da un frammento con cifre
   e' l'etichetta di un valore letto male, c15). Ruoli: `daPagare` (default), `unitarioKg`, `unitarioL`,
   `pieno` («anziche'», «invece di», «prima», «era»), `carta` («con carta», «soci»…). Una riga che e' una
   QUANTITA' («1/kg», «500 g», c22) non fa da etichetta.
4. **Offerte** (`_offerte`): NxM («3x2», «3*1» di Vision, «prendi 3 paghi 2», «2+1»), «0%» (nessuna
   offerta), secondo a percento («sul secondo», «2° pezzo»), percentuale (con meno o «sconto», sola sulla
   riga, «(23%» di Vision, o **senza simbolo** vicino a «sconto»: «SCONTO / 40», c28).
5. **Prezzo da pagare**: il candidato pagabile piu' **alto**; a parita' (±10%) quello del **controllo
   formato** (`|P × 1000 / millesimi − U| ≤ max(2 cent, 0,5% di U)`, con il formato dal nome e il €/kg
   vicino). Senza pagabili: solo il €/kg → proposta **a misura** (`aMisura`).
6. **Pieno e offerte**: (a) coppia legata da una percentuale scritta (prezzo dinamico c33: «2,29 / 2,99,
   −23%») → prezzo lo scontato, `OffertaPrezzoBarrato(pieno)`; (b) prezzo con carta e normale diversi →
   `DoppioPrezzoCarta` (D4), prezzo provvisorio con carta; (c) NxM → il prezzo della riga e' il **PIENO**:
   quello Q per cui `effettivo(Q) ≈ prezzo grande`, o l'«anziche'» (⚑ c01 nel mirino: grande non letto,
   «3 PEZZI € 3,18» e «anziche' € 3,19 al pz»), altrimenti affidabilita' −0,2; (d) altrimenti un
   «anziche'» maggiore o un secondo prezzo maggiore e piu' basso dell'80% → barrato; poi secondo a
   percento; poi percentuale (non con «0%»).
7. **Unitario e nome**: il €/kg piu' vicino al prezzo (con NxM e due €/kg, quello che torna col prezzo
   EFFETTIVO, c11); il nome = le 2 righe buone piu' vicine **sopra o a sinistra** del prezzo (senza: sotto,
   entro 3 altezze — Esselunga «Il Prezzochiaro»), unite dall'alto, «Cod» iniziale tolto, max 60.
8. **Piu' cartellini** (`_ancore`): ancore = prezzi da pagare alti ≥ 60% del piu' alto e distanti >
   `min(0,3, 2,5 × altezza del piu' alto)`; ogni riga va all'ancora piu' vicina (dy pesato 1,5); proposte
   ordinate per distanza dal centro. Il prezzo con carta non e' mai un'ancora; i €/kg solo se non ci sono
   prezzi da pagare; due ancore legate da una percentuale sono UN cartellino.
9. **Affidabilita'** = (0,5 + bonus forma [esplicito +0,2, spezzato +0,1, fuso −0,1] + 0,2 formato
   riuscito + 0,1 nome trovato − 0,2 ambiguo + confidenza della riga) / 2, tagliata a 0..1.
   ⚑ Decide **solo** se il foglio mostra «Controlla il prezzo» e i chip (sotto 0,6 o con alternative),
   **mai** se aggiungere. Alternative: fino a 3 altri prezzi letti.
10. **Solo sconto** (`_soloSconto`): un bollino senza prezzo («ULTIMI GIORNI −30% SCONTO ALLA CASSA»,
    c31) → proposta col solo sconto e prezzo «—» da battere, affidabilita' 0,3.

`final class PrezzoUnitario` — file `lib/domain/lettura/cartellino_parser.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Money valore` · `final UnitaMisura unita` | €/kg o €/l stampato |
| `()` | `const PrezzoUnitario(this.valore, this.unita)` | costruttore: i parametri sono i campi omonimi |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class DoppioPrezzoCarta` — file `lib/domain/lettura/cartellino_parser.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Money conCarta` · `final Money senzaCarta` | I due prezzi del cartellino con la carta fedelta' (D4): nessun default |
| `()` | `const DoppioPrezzoCarta({required this.conCarta, required this.senzaCarta})` | costruttore: i parametri sono i campi omonimi |
| `operator==` | `bool operator ==(Object other)` | uguaglianza per valore sui campi |
| `hashCode` | `int get hashCode` | coerente con `==` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class PropostaCartellino` — file `lib/domain/lettura/cartellino_parser.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String nome` · `final Money? prezzo` · `final Money? prezzoPieno` · `final PrezzoUnitario? unitario` · `final Offerta? offerta` · `final AMisura? formato` · `final double affidabilita` · `final List<Money> alternative` · `final DoppioPrezzoCarta? carta` | `nome` ('' se non trovato); `prezzo` UNITARIO (PIENO con NxM; con `carta` e' quello CON la carta finche' non si sceglie); `prezzoPieno` barrato/«anziche'»; `unitario` €/kg o €/l stampato; `formato` dal nome; `affidabilita` 0..1 (sotto 0,6 il foglio dice «Controlla il prezzo», MAI decide se aggiungere); `alternative` ≤ 3 prezzi letti; `carta` se due prezzi |
| `()` | `const PropostaCartellino({required this.nome, this.prezzo, this.prezzoPieno, this.unitario, this.offerta, this.formato, required this.affidabilita, this.alternative = const [], this.carta})` | costruttore: i parametri sono i campi omonimi |
| `aMisura` | `bool get aMisura` | Solo il prezzo al kg/l (niente prezzo): si apre il foglio del peso |
| `scegliCarta` | `PropostaCartellino scegliCarta({required bool conCarta})` | Con la carta: prezzo con carta + `OffertaPrezzoConCarta(senza)`; senza: prezzo normale, nessuna offerta; `carta` sparisce. Senza `carta` ritorna se stessa |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class LetturaCartellino` — file `lib/domain/lettura/cartellino_parser.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final List<PropostaCartellino> proposte` | `proposte` ordinate: la prima e' quella da proporre (la piu' vicina al centro) |
| `()` | `const LetturaCartellino(this.proposte)` | costruttore: i parametri sono i campi omonimi |
| `vuota` | `bool get vuota` | nessuna proposta |

`enum _Ruolo { daPagare, unitarioKg, unitarioL, pieno, carta }` — file `lib/domain/lettura/cartellino_parser.dart`

`final class _Candidato` — file `lib/domain/lettura/cartellino_parser.dart`

Un numero col suo ruolo (mutabile) e la riga OCR

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final NumeroOcr numero` · `final RigaOcr riga` · `_Ruolo ruolo` |  |
| `()` | `_Candidato(this.numero, this.riga, this.ruolo)` | costruttore: i parametri sono i campi omonimi |
| `valore` | `Money get valore` | `numero.valore` |
| `riquadro` | `Riquadro get riquadro` | `numero.riquadro` |
| `altezza` | `double get altezza` | altezza del riquadro (il prezzo da pagare e' il piu' alto) |
| `unitario` | `bool get unitario` | ruolo al kg o al litro |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`class CartellinoParser` — file `lib/domain/lettura/cartellino_parser.dart`

Dai riquadri OCR a una o piu' proposte (algoritmo al §5.5). Un solo parser per Vision e PP-OCR

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const CartellinoParser()` | costruttore: i parametri sono i campi omonimi |
| `_kg` | `static final RegExp _kg = RegExp(r'/\s*kg\|al\s*kg\|euro\s*al\s*kg\|prezzo\s*(al\|per)\s*kg\|eur/kg\|\bkg\b\s*$\|\be\s*/\s*…` |  |
| `_unitaDopo` | `static final RegExp _unitaDopo = RegExp(r'^\s*/?\s*(kg\|l\|lt\|litro)\b')` |  |
| `_unitaPrima` | `static final RegExp _unitaPrima = RegExp(r'\b(a[il]\|per)\s*(kg\|l\|lt\|litro)\s*[ce]?\s*[.:]?\s*$')` |  |
| `_separatore` | `static final RegExp _separatore = RegExp(r'\s[-–\|;]\|[-–\|;]\s\|\bsoit\b')` |  |
| `_quantita` | `static final RegExp _quantita = RegExp(r'^\s*\d+([.]\d+)?\s*/?\s*(kg\|gr?\|l\|lt\|ml\|cl)\b')` |  |
| `_dueCifre` | `static final RegExp _dueCifre = RegExp(r'^\s*[-−]?\s*([1-9]\d)\s*%?\s*$')` |  |
| `_litro` | `static final RegExp _litro = RegExp(r'/\s*l(t\|itro)?\b\|al\s*l(t\|itro)\b\|prezzo\s*al\s*litro\|per\s*l(t\|itro)\b')` |  |
| `_pieno` | `static final RegExp _pieno = RegExp(r'anziche\|invece\s*di\|\bprima\b\|prezzo\s*pieno\|\bera\b')` |  |
| `_carta` | `static final RegExp _carta = RegExp(r'con\s*(la\s*)?carta\|carta\s*fedelta\|\bsoci\b\|prezzo\s*carta')` |  |
| `_nxm` | `static final RegExp _nxm = RegExp(r'\b([2-5])\s*[x×*]\s*([1-4])\b(?![.]?\d)(?!\s*(?:kg\|gr?\|ml\|cl\|lt?)\b)')` |  |
| `_prendiPaghi` | `static final RegExp _prendiPaghi = RegExp(r'prendi\s*([2-5])\s*paghi\s*([1-4])')` |  |
| `_piuUno` | `static final RegExp _piuUno = RegExp(r'\b([1-4])\s*\+\s*1\b(?![.]?\d)')` |  |
| `_secondo` | `static final RegExp _secondo = RegExp(r'sul\s*(2\|secondo)\b\|2\s*°\s*pezzo\|secondo\s*pezzo')` |  |
| `_percento` | `static final RegExp _percento = RegExp(r'-?\s*([1-9]\d?)\s*%')` |  |
| `_percentoSconto` | `static final RegExp _percentoSconto = RegExp(r'(?:[-−]\s*\|sconto\s*)([1-9]\d?)\s*%')` |  |
| `_percentoSolo` | `static final RegExp _percentoSolo = RegExp(r'^\s*[-−(]?\s*([1-9]\d?)\s*%\s*\)?\s*$')` |  |
| `_zeroPercento` | `static final RegExp _zeroPercento = RegExp(r'(?<!\d)0\s*%')` |  |
| `_nonNome` | `static final RegExp _nonNome = RegExp(r'offert\|sconto\|prezz\|promo\|anziche\|invece\|al\s*kg\|/\s*kg\|/\s*l\|al\s*l(t\|itro)\|al\s…` |  |
| `interpreta` | `LetturaCartellino interpreta(List<RigaOcr> righe)` | Pulizia (confidenza ≥ 0,30, area ≥ 0,0004, `pulisci`); ancore; < 2 ancore → una proposta; altrimenti ogni riga alla ancora piu' vicina (dy pesato 1,5) e proposte ordinate per distanza dal centro |
| `_ancore` | `List<_Candidato> _ancore(List<_Candidato> candidati, List<int> percentuali)` | Prezzi da pagare (o unitari se non ce ne sono) alti ≥ 60% del piu' alto e distanti > min(0,3, 2,5 × altezza); due ancore legate da una percentuale scritta → si tiene la piu' bassa |
| `_candidati` | `List<_Candidato> _candidati(List<RigaOcr> righe)` | Spezzati, poi fusi, poi espliciti (meno solo DOPO → positivo), ciascuno col ruolo dal contesto; con piu' numeri nella riga il contesto si taglia al separatore (`_separatore`); ripiego: righe di sole 3-4 cifre come fusi |
| `_ruoloDaContesto` | `_Ruolo _ruoloDaContesto(NumeroOcr n, RigaOcr riga, List<RigaOcr> righe, {required String segmento, String dopo = '', String prima = ''})` | Unita' subito dopo/prima del numero; poi il suo segmento; poi le righe SENZA numeri della stessa riga visiva (salta un «Al kg» piccolo a sinistra seguito da cifre) e quelle entro 1,5 altezze; default `daPagare` |
| `_seguitaDaCifre` | `static bool _seguitaDaCifre(RigaOcr etichetta, Riquadro q, List<RigaOcr> righe)` | Un'etichetta piccola seguita a destra (entro 2 altezze, prima del numero) da un frammento con cifre |
| `_menoSoloDopo` | `static bool _menoSoloDopo(String testo, String numero)` | «0,99-» si', «-0,99» no |
| `_distanza` | `static double _distanza(Riquadro a, Riquadro b)` | Quadrato della distanza fra i centri |
| `_haNumeri` | `static bool _haNumeri(RigaOcr r)` | Riga con un prezzo, sole cifre, o cifre attaccate a «/kg» «/l» |
| `_ruoloDiTesto` | `static _Ruolo? _ruoloDiTesto(String t)` | kg → unitarioKg, litro → unitarioL, «anziche'/invece di/prima/era» → pieno, «con carta/soci» → carta |
| `_offerte` | `({OffertaNxM? nxm, int? percento, int? secondo, bool zero}) _offerte(List<RigaOcr> righe)` | NxM («3x2», «3*1», «prendi 3 paghi 2», «2+1»); «0%»; secondo a percento; percentuale (con meno/sconto, sola sulla riga, o senza simbolo vicino a «sconto») |
| `_percentoSenzaSimbolo` | `static int? _percentoSenzaSimbolo(List<RigaOcr> righe)` | Due cifre sole su una riga, con «sconto» entro 2 altezze e sovrapposto in x |
| `_percentuali` | `static List<int> _percentuali(List<RigaOcr> righe)` | Tutte le percentuali di sconto scritte |
| `_scontoTorna` | `static bool _scontoTorna(Money pieno, Money scontato, int percento)` | `scontato ≈ pieno − round(pieno × x / 100)` entro ±2 cent |
| `_proposta` | `PropostaCartellino? _proposta(List<RigaOcr> righe)` | La proposta di UN cartellino (passi 5–7, 9: prezzo, pieno, carta, NxM, percentuali, unitario, nome, affidabilita', alternative); `_soloSconto` senza candidati |
| `_soloSconto` | `PropostaCartellino? _soloSconto(List<RigaOcr> righe)` | Bollino senza prezzo: proposta col solo sconto, affidabilita' 0,3; null senza sconto o con 0% |
| `_bonusForma` | `static double _bonusForma(FormaNumero f)` | esplicito +0,2, spezzato +0,1, fuso −0,1, peso 0 |
| `_taglia` | `static double _taglia(double v)` | 0..1 |
| `_vicino` | `static _Candidato? _vicino(List<_Candidato> lista, Riquadro q)` | Il candidato piu' vicino a un riquadro |
| `_formatoTorna` | `static bool _formatoTorna(Money p, AMisura formato, Money u)` | `\|P × 10⁶ / millesimi − U × 1000\| ≤ max(2000, 5·U)` (in interi) |
| `_formato` | `static AMisura? _formato(List<RigaOcr> righe)` | Il formato dalla prima riga con ≥ 3 lettere che ne ha uno |
| `_nome` | `static String _nome(List<RigaOcr> righe, Riquadro prezzo)` | Righe con ≥ 3 lettere, non parole chiave/prezzi/codici/date, sopra o a sinistra del prezzo (senza: sotto, entro 3 altezze); le 2 piu' vicine dall'alto, unite, «Cod» iniziale tolto, max 60 |

### 5.6 `bilancia_parser.dart` — l'etichetta della bilancia

⚑ La bilancia ha gia' fatto il conto: il **totale stampato e' quello della cassa** e VINCE
(`RigaSpesa.totaleStampato`). Peso e €/kg servono a **verificare** (una cifra letta male quasi mai lascia
la tripla coerente) e a trovare i numeri quando mancano le etichette. ⚑ `riconosce` e' la «firma» che fa
passare da solo il mirino del Cartellino alla bilancia: **niente terzo tasto** sulla spesa.
⚑ Il nome del prodotto (F12.7) e' la scritta **piu' grande** fra le buone, non la prima dall'alto (che
quasi sempre e' l'insegna «PANORAMA» o il bollino «OFFRE SPECIALE»); sulle righe OCR e non visive (una
riga visiva unisce il nome all'insegna accanto, b08).

`final class LetturaBilancia` — file `lib/domain/lettura/bilancia_parser.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String? prodotto` · `final AMisura? pesoNetto` · `final Money? alKg` · `final Money? totale` · `final AMisura? tara` · `final bool coerente` | `pesoNetto` in grammi (kg); `totale` VINCE nel conto; `tara` esclusa; `coerente` = perMisura(alKg, peso) = totale ±1 cent (false anche se manca un valore) |
| `()` | `const LetturaBilancia({this.prodotto, this.pesoNetto, this.alKg, this.totale, this.tara, required this.coerente})` | costruttore: i parametri sono i campi omonimi |
| `utile` | `bool get utile` | `totale != null` |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`class BilanciaParser` — file `lib/domain/lettura/bilancia_parser.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const BilanciaParser()` | costruttore: i parametri sono i campi omonimi |
| `_netto` | `static final RegExp _netto = RegExp(r'netto\|peso\s*netto\|p\.?\s*netto\|kg\s*netto\|net\s*w\|poids\|gewicht\|weight\|peso\b')` |  |
| `_tara` | `static final RegExp _tara = RegExp(r'\btara\b\|\btare\b')` |  |
| `_alKg` | `static final RegExp _alKg = RegExp(r'/\s*kg\|eur/kg\|prezzo\s*/?\s*kg\|prezzo\s*al\s*kg\|al\s*kg\|prix\s*/\s*kg\|preis\s*/\s…` |  |
| `_totale` | `static final RegExp _totale = RegExp(r'importo\|prezzo\s*€?$\|totale\|da\s*pagare\|\beuro\b\|\bprix\b\|\bpreis\b\|\bprice\b\|a\s…` |  |
| `_nonProdotto` | `static final RegExp _nonProdotto = RegExp(r'peso\|tara\|prezzo\|confezionat\|consumar\|lotto\|scadenza\|netto\|importo\|totale\|\beuro\…` |  |
| `interpreta` | `LetturaBilancia? interpreta(List<RigaOcr> righe)` | Candidati (pesi a 3 decimali o «258 g», importi positivi) con l'etichetta della riga e di quella sopra; tara, netto, €/kg, totale per parole; triple coerenti (una → quella; piu' → rispettose delle etichette, poi totale piu' alto); senza totale → l'importo piu' alto che non e' il €/kg; null se nessun importo o totale |
| `riconosce` | `bool riconosce(List<RigaOcr> righe)` | La «firma» della bilancia: un peso a 3 decimali e almeno una tripla coerente (la usa `LetturaService`) |
| `_triple` | `static List<_Tripla> _triple(List<NumeroOcr> pesi, List<NumeroOcr> importi)` | Tutte le triple con \|perMisura − totale\| ≤ 1 cent (€/kg ≠ totale, totale > 0) |
| `_totaleSenzaEtichetta` | `static NumeroOcr? _totaleSenzaEtichetta(List<NumeroOcr> importi, NumeroOcr? alKg)` | L'importo piu' alto di riquadro che non e' il €/kg |
| `_insegna` | `static final RegExp _insegna = RegExp(r'^\W*(pam\|panorama\|pam panorama\|esselunga\|coop\|ipercoop\|conad\|carrefour\|lidl\|euros…` |  |
| `_nonProdottoAncora` | `static final RegExp _nonProdottoAncora = RegExp(r'offert\|offre\|speciale\|sconto\|scontat\|ribasso\|approfitta\|servare\|frigorifer\|cottur…` |  |
| `_prodotto` | `static String? _prodotto(List<RigaOcr> righe)` | Fra le righe OCR con ≥ 4 lettere, ≤ 40 caratteri, cifre ≤ meta' delle lettere, non etichette/insegne/diciture/date/prezzi: la piu' GRANDE (a parita' entro 10% la piu' in alto), unita alle buone della stessa riga alte ≥ 80%; max 60 caratteri |

| Nome | Firma | Effetto |
|---|---|---|
| `_Tripla` | `typedef _Tripla = ({NumeroOcr peso, NumeroOcr alKg, NumeroOcr totale});` | Una tripla peso × €/kg ≈ totale (privata) |

### 5.7 `scontrino_parser.dart` — lo scontrino

Vale per il «documento commerciale» degli RT (dal 2020) e per il vecchio «scontrino fiscale».

**Algoritmo di `ScontrinoParser.interpreta`**:
1. Righe visive; testi puliti e chiavi (minuscolo senza accenti).
2. **Zone**: la testata finisce a «documento commerciale / descrizione / scontrino fiscale» **solo se**
   viene prima del primo importo (⚑ nel vecchio formato «SCONTRINO FISCALE N. 201» sta in fondo, s09),
   altrimenti al primo importo. Il corpo finisce alla riga **TOTALE con importo** (sulla riga o su quella
   sotto di soli numeri; «complessivo» vince; «totale iva/parziale/pezzi/articoli» non sono il totale); ⚑
   una riga TOTALE **senza** importo chiude comunque il corpo se non ce n'e' una con l'importo (Vision su
   s01), e il totale si ricava dopo.
3. **Negozio**: la PRIMA riga buona della testata (≥ 4 lettere, non indirizzo/telefono/P.IVA/diciture
   legali/intestazioni, confidenza ≥ 0,7). ⚑ L'insegna (INTERSPAR) e non la ragione sociale sotto
   («MAIORA S.R.L.»): provato il contrario sul banco, perde s07 e s16.
4. **Corpo**, riga per riga: righe «mute» (subtotale, IVA, n. articoli, intestazioni, «T*talE PARZIALE»)
   saltate; **pesata** «0,248 kg x 12,50» (con o senza importo; attaccata all'articolo prima se torna) o
   senza parole (peso + €/kg + importo coerenti, s03); **quantita'** «2 x 1,29» su una riga sua (attaccata
   all'articolo prima se torna, altrimenti in attesa del successivo); descrizione senza prezzo → **coda**
   di descrizioni (⚑ in s13 l'OCR legge due descrizioni e poi i due prezzi); **storno** («storno, annull,
   reso, correzione») → riga negativa + marca stornato l'articolo; **sconto** (importo negativo o «sconto,
   offerta, promo, buono, coupon, risparmio») → riga negativa; riga col **solo importo** nella colonna dei
   prezzi → articolo senza nome (s09, s03); quantita' in testa («3 COPERTO 3,90», s11).
5. Senza TOTALE: e' totale l'ultimo importo del corpo che vale **esattamente la somma** delle righe prima
   (scontrino della bilancia, s03).
6. **Verifica del totale** (`_verificaTotale`): fonti = ultimo subtotale del corpo, pagato − resto
   (contanti), somma delle righe. Confermato da una fonte → resta; due fonti concordi → lo sostituiscono
   (s02: «13.23» letto per 13,73); un TOTALE maggiore del subtotale → subtotale (s09); senza TOTALE →
   subtotale (s16). ☠ Le righe del pagamento si leggono **solo** qui, per l'importo: non escono.
7. **Data**: la prima data plausibile del piede e della testata (§`_data`). ☠ Del piede (carta,
   autorizzazione, terminale) **non si tiene altro**.

`enum TipoRigaScontrino { articolo, sconto, storno }` — file `lib/domain/lettura/scontrino_parser.dart`

`final class RigaScontrino` — file `lib/domain/lettura/scontrino_parser.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String descrizione` · `final Money importo` · `final TipoRigaScontrino tipo` · `final Quantita? quantita` · `final Money? prezzoUnitario` · `final bool stornata` | `importo` con segno (sconti e storni negativi); `quantita`/`prezzoUnitario` da «2 x 1,29» o «0,248 kg x 12,50»; `stornata` |
| `()` | `const RigaScontrino({required this.descrizione, required this.importo, required this.tipo, this.quantita, this.prezzoUnitario, this.stornata = false})` | costruttore: i parametri sono i campi omonimi |
| `copyWith` | `RigaScontrino copyWith({String? descrizione, Quantita? quantita, Money? prezzoUnitario, bool? stornata})` | Cambia descrizione, quantita', unitario, stornata (importo e tipo restano) |
| `toString` | `String toString()` | testo per log e messaggi dei test |

`final class LetturaScontrino` — file `lib/domain/lettura/scontrino_parser.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String? negozio` · `final CivilDate? data` · `final List<RigaScontrino> righe` · `final Money? totale` · `final int righeIgnorate` | `negozio` com'e' stampato; `data`; `righe` nell'ordine; `totale` STAMPATO; `righeIgnorate`. ☠ Nessun campo per il pagamento |
| `()` | `const LetturaScontrino({this.negozio, this.data, required this.righe, this.totale, required this.righeIgnorate})` | costruttore: i parametri sono i campi omonimi |
| `sommaRighe` | `Money get sommaRighe` | Somma degli importi (stornate comprese: lo storno le compensa) |
| `quadra` | `bool get quadra` | `totale != null && totale == sommaRighe` |
| `articoli` | `int get articoli` | Articoli non stornati |
| `negozioMostrato` | `String? get negozioMostrato` | Senza punteggiatura in coda e senza S.R.L./S.P.A./S.A.S./S.N.C. finali; il nome originale se resterebbe vuoto |

`class ScontrinoParser` — file `lib/domain/lettura/scontrino_parser.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const ScontrinoParser()` | costruttore: i parametri sono i campi omonimi |
| `_fineTestata` | `static final RegExp _fineTestata = RegExp(r'documento\s*commerciale\|descrizione\|scontrino\s*fiscale')` |  |
| `_totale` | `static final RegExp _totale = RegExp(r'^\s*totale(\s*complessivo\|\s*euro\|\s*eur\|\s*€)?\b')` |  |
| `_nonNegozio` | `static final RegExp _nonNegozio = RegExp(r'\bvia\b\|viale\|piazza\|p\.?zza\|corso\|c\.so\|\btel\|p\.?\s*iva\|c\.?f\.\|\bcap\b\|\d{5}\|d…` |  |
| `_quantita` | `static final RegExp _quantita = RegExp(r'^\s*(\d{1,3})\s*[x×*]\s*(\d+[.]\d{2})\s*$')` |  |
| `_pesata` | `static final RegExp _pesata = RegExp(r'(\d+[.]\d{3})\s*kg\s*[x×*]\s*(\d+[.]\d{2})')` |  |
| `_parolaSconto` | `static final RegExp _parolaSconto = RegExp(r'sconto\|offerta\|promo\|buono\|coupon\|risparmio')` |  |
| `_storno` | `static final RegExp _storno = RegExp(r'storno\|annull\|\breso\b\|correzione')` |  |
| `_ignorateMute` | `static final RegExp _ignorateMute = RegExp(r'subtot\|sub\s*tot\|di\s*cui\s*iva\|totale\s*iva\|n\.?\s*articoli\|^\s*articoli\|^\s*pez…` |  |
| `_tokenIva` | `static final RegExp _tokenIva = RegExp(r'(\s+(\d{1,2}\s*%\|[abcd]\|vi\|\*))+\s*$', caseSensitive: false)` |  |
| `_quantitaInTesta` | `static final RegExp _quantitaInTesta = RegExp(r'^(\d{1,2})\s+[a-z]')` |  |
| `interpreta` | `LetturaScontrino interpreta(List<RigaOcr> righe, {DateTime? oggi})` | Righe visive → zone (testata fino a «documento commerciale/descrizione/scontrino fiscale» se prima del primo importo, altrimenti primo importo; corpo fino al TOTALE, «complessivo» vince) → negozio → corpo (pesate, quantita', sconti, storni, descrizioni in coda) → totale ricavato senza TOTALE → `_verificaTotale` → data dal piede e dalla testata. `oggi` iniettabile |
| `_importoTotale` | `static Money? _importoTotale(List<RigaVisiva> visive, List<String> testi, int i, {bool ovunque = false})` | L'importo sulla riga o, se la riga sotto e' di soli numeri, su quella |
| `_subtotale` | `static final RegExp _subtotale = RegExp(r'sub\s*tot\|\bsubt\b\|t.?tale\s*parziale')` |  |
| `_pagato` | `static final RegExp _pagato = RegExp(r'contant\|\bcassa\b\|pagat\|pagamento\|bancomat\|carta\s*di')` |  |
| `_resto` | `static final RegExp _resto = RegExp(r'\bresto\b')` |  |
| `_verificaTotale` | `static Money? _verificaTotale(Money? letto, List<RigaVisiva> visive, List<String> chiavi, int inizio, int fine, Money somma)` | Fonti: ultimo subtotale del corpo, pagato − resto, somma righe. Il letto confermato da una fonte resta; due fonti concordi lo sostituiscono; un TOTALE > subtotale → subtotale; senza TOTALE → subtotale |
| `_pesataSenzaEtichetta` | `static ({int grammi, Money alKg, Money importo})? _pesataSenzaEtichetta(RigaVisiva v)` | Peso a 3 decimali + due importi con perMisura = importo (±1) |
| `_importoDi` | `static Money? _importoDi(RigaVisiva v, {bool ovunque = false})` | `importoADestra`; con `ovunque` anche l'ultimo esplicito della riga |
| `_importoDopo` | `static Money? _importoDopo(RigaVisiva v, int fine, String testo)` | L'ultimo importo dopo la fine della pesata nella stessa riga |
| `_descrizioneDi` | `static String _descrizioneDi(RigaVisiva v, String testo)` | Il testo a sinistra dell'importo, ripulito |
| `_pulisciDescrizione` | `static String _pulisciDescrizione(String s)` | Meno finale, token IVA in coda («22%», «A», «VI», «*»), asterischi in coda, spazi |
| `_attacca` | `static bool _attacca(List<RigaScontrino> out, Quantita q, Money unitario, bool Function(RigaScontrino) torna)` | Attacca una quantita' all'ULTIMO articolo se l'importo torna |
| `_marcaStornata` | `static void _marcaStornata(List<RigaScontrino> out, Money storno, String descrizione)` | Marca stornato l'ultimo articolo con lo stesso importo e descrizione simile (≥ 0,5) o qualunque se lo storno non ha nome |
| `_data` | `static CivilDate? _data(List<String> testi, DateTime oggi)` | La prima data PLAUSIBILE (≤ 1 giorno nel futuro, ≥ −366 giorni); ⚑ F12.8: le altre si saltano (prima la prima non plausibile chiudeva con null) |
| `_intero` | `static int _intero(String numero)` | «12,50» → 1250 (separatori tolti) |

## 6. `lib/data/`

### 6.1 `database.dart`

`class SpendingDatabase extends _$SpendingDatabase` — file `lib/data/database.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `SpendingDatabase(super.e)` | Su un `QueryExecutor` qualunque |
| `open()` | `factory SpendingDatabase.open()` | Su file `Documents/spending_review.sqlite` (`_openConnection`, isolate di background) |
| `memory()` | `factory SpendingDatabase.memory()` | In memoria (`NativeDatabase.memory()`), per i test |
| `schemaVersion` | `int get schemaVersion` | 1 |
| `migration` | `MigrationStrategy get migration` | `onCreate: createAll`; `onUpgrade` → ☠ `UnsupportedError` (nessuna migrazione: va scritta col suo test prima di alzare la versione); `beforeOpen` → `PRAGMA foreign_keys = ON` |

| Nome | Firma | Effetto |
|---|---|---|
| `_openConnection` | `LazyDatabase _openConnection()` | `LazyDatabase`: file in `getApplicationDocumentsDirectory()`, ☠ `sqlite3.tempDirectory = getTemporaryDirectory()` (Android), `NativeDatabase.createInBackground(file)` |

☠ `sqlite3.tempDirectory`: su Android la cartella temporanea di sistema non e' scrivibile dal processo
dell'app; senza, VACUUM e alcuni ORDER BY grandi falliscono con «unable to open database file», **solo
sul dispositivo** (lezione di TrashCan). ⚑ Se il file cambia nome o cartella va aggiornato anche
`AppDelegate.swift` (esclusione iCloud).

### 6.2 `spesa_repository.dart` — la sola porta sul database

Le regole che SQL non esprime:
- ⚑ **Spesa creata pigramente** al primo articolo (o al primo budget/scontrino), col budget abituale.
- ⚑ **Una sola spesa in corso**: la garantisce l'indice unico parziale, non questo codice; ☠ l'insert che
  lo viola (`SqliteException`) si recupera rileggendo la spesa creata dall'altra chiamata.
- ⚑ **Totali scritti e mai ricalcolati**: `righe.totale_cents` alla scrittura della riga,
  `spese.totale_cents` alla chiusura. Un cambiamento delle regole di calcolo non cambia lo storico.
- ⚑ **Le spese oltre le 5 nel gratis restano nel database** (D1): il limite lo applica la lettura
  (`osservaChiuse(limite:)`), mai una cancellazione. **Qui non c'e' nessuna «potatura», e non deve esserci.**
- Gli stream (`osservaInCorso`, `osservaChiuse`) riemettono a ogni scrittura su `spese` **o** `righe`
  (`customSelect('SELECT 1', readsFrom: {...}).watch()`), poi ricaricano: semplice e sempre coerente.
- Metodi in piu' rispetto alla specsheet, con il perche': `posizioneDi` («Annulla» rimette la riga al suo
  posto; l'indice nella lista non basta, le posizioni hanno buchi), `osservaNumeroChiuse` (la card delle
  nascoste senza caricare le righe di tutte le spese), `incrementaUltima` ritorna `bool` (senza,
  l'interfaccia non saprebbe quando vibrare d'errore).

`class SpesaRepository` — file `lib/data/spesa_repository.dart`

LE regole dei dati che SQL non esprime (§6.2). Unica porta sul database per le schermate

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final SpendingDatabase _db` · `final DateTime Function() _ora` |  |
| `()` | `SpesaRepository(this._db, {DateTime Function() ora = DateTime.now})` | `ora` iniettabile (date nei test); ⚑ `ignore: prefer_initializing_formals` per tenere `_ora` privata |
| `_inCorso` | `static const String _inCorso = 'in_corso'` |  |
| `_chiusa` | `static const String _chiusa = 'chiusa'` |  |
| `_contate` | `static const String _contate = 'contate'` |  |
| `_scontrino` | `static const String _scontrino = 'scontrino'` |  |
| `_adesso` | `int get _adesso` | `_ora().toUtc().millisecondsSinceEpoch` |
| `osservaInCorso` | `Stream<Spesa?> osservaInCorso()` | Stream che riemette a ogni scrittura su `spese` o `righe` (`customSelect('SELECT 1', readsFrom: {spese, righe}).watch()`) e ricarica la spesa in corso |
| `_caricaInCorso` | `Future<Spesa?> _caricaInCorso() async` | La riga `stato = 'in_corso'` (o null) → `_spesa` |
| `assicuraInCorso` | `Future<int> assicuraInCorso({Money? budgetPredefinito})` | In transazione: l'id della spesa in corso, o la crea (`iniziata_il` = adesso, budget = `budgetPredefinito` se > 0). ☠ `SqliteException` (indice unico violato da un'altra connessione) → rilegge e ritorna quella |
| `aggiungiRiga` | `Future<int> aggiungiRiga(RigaSpesa riga)` | In transazione: `assicuraInCorso()`, posizione = max+1 nell'insieme 'contate', insert; ritorna l'id della riga. `totale_cents` = `riga.totale` adesso |
| `aggiornaRiga` | `Future<void> aggiornaRiga(RigaSpesa riga) async` | Riscrive la riga (stessa spesa, insieme, posizione e `creata_il`), ricalcolando `totale_cents`. ☠ `ArgumentError` se `riga.id == null` |
| `eliminaRiga` | `Future<void> eliminaRiga(int rigaId)` | DELETE per id |
| `posizioneDi` | `Future<int?> posizioneDi(int rigaId) async` | La posizione della riga (da leggere PRIMA di eliminarla, per «Annulla»); null se non c'e' |
| `ripristinaRiga` | `Future<void> ripristinaRiga(RigaSpesa riga, {required int posizione})` | «Annulla»: reinserisce la riga con il suo id e la sua posizione nella spesa in corso (creata se serve) |
| `incrementaUltima` | `Future<bool> incrementaUltima()` | +1 pezzo all'ultima riga contata (posizione e id piu' alti); `false` senza spesa, senza righe, se a misura, sconto, con totale stampato o gia' a 999 (la pagina vibra d'errore) |
| `impostaBudget` | `Future<void> impostaBudget(Money? budget)` | Budget della spesa in corso (creata se serve); null o ≤ 0 → nessuno |
| `salvaScontrino` | `Future<void> salvaScontrino(int spesaId, LetturaScontrino lettura)` | In transazione: cancella le righe 'scontrino' della spesa, inserisce quelle della lettura (`rigaDaScontrino`, `stornata`), scrive `totale_scontrino_cents` |
| `chiudi` | `Future<int> chiudi({required CivilDate data, int? negozioId, required FonteRighe fonte})` | In transazione: ☠ `StateError` senza spesa in corso; calcola `Spesa(...fonte).totale` e scrive stato 'chiusa', `chiusa_il`, `data_spesa`, `negozio_id`, `fonte`, `totale_cents` (che non cambiera' piu'). Ritorna l'id |
| `registraDaScontrino` | `Future<int> registraDaScontrino(LetturaScontrino lettura, {required CivilDate data, int? negozioId})` | In transazione: una spesa gia' CHIUSA con fonte scontrino, `totale_cents` = TOTALE stampato o somma delle righe, e le righe dello scontrino. Ritorna l'id |
| `scartaInCorso` | `Future<void> scartaInCorso()` | DELETE della spesa in corso (righe in cascata) |
| `osservaChiuse` | `Stream<List<Spesa>> osservaChiuse({int? limite})` | Le chiuse per `data_spesa DESC, id DESC`, con `limite` (null = tutte); riemette a ogni scrittura su spese o righe |
| `osservaNumeroChiuse` | `Stream<int> osservaNumeroChiuse()` | `SELECT COUNT(*) … WHERE stato = 'chiusa'`, osservato |
| `modificaChiusa` | `Future<void> modificaChiusa(int id, {required CivilDate data, int? negozioId})` | Cambia `data_spesa` e `negozio_id` di una spesa CHIUSA (il WHERE esclude quella in corso); ⚑ il totale non si tocca |
| `contaChiuse` | `Future<int> contaChiuse() async` | Il numero delle chiuse (snack del gratis dopo la chiusura) |
| `perId` | `Future<Spesa?> perId(int id) async` | La spesa con le righe, o null |
| `eliminaSpesa` | `Future<void> eliminaSpesa(int id)` | DELETE (righe in cascata) |
| `osservaNegozi` | `Stream<List<Negozio>> osservaNegozi()` | Per nome `COLLATE NOCASE` |
| `negozioPerNome` | `Future<int> negozioPerNome(String nome)` | In transazione: trova per nome (NOCASE) o crea; il nome ripulito (`_nomeNegozio`). ☠ `ArgumentError` se vuoto |
| `rinominaNegozio` | `Future<void> rinominaNegozio(int id, String nome)` | UPDATE del nome ripulito. ☠ Un doppione viola `UNIQUE COLLATE NOCASE` → eccezione (la pagina la mostra) |
| `eliminaNegozio` | `Future<void> eliminaNegozio(int id)` | DELETE; le spese restano «senza negozio» (`ON DELETE SET NULL`) |
| `_nomeNegozio` | `static String _nomeNegozio(String nome)` | Spazi compattati, tronco a 60; `ArgumentError` se vuoto |
| `_prossimaPosizione` | `Future<int> _prossimaPosizione(int spesaId, String insieme) async` | `max(posizione) + 1` nell'insieme (0 se vuoto) |
| `_inserisciScontrino` | `Future<void> _inserisciScontrino(int spesaId, LetturaScontrino lettura) async` | Inserisce le righe della lettura (saltando gli importi zero) con posizione 0.. e `stornata` |
| `rigaDaScontrino` | `static RigaSpesa? rigaDaScontrino(RigaScontrino r)` | `RigaScontrino` → `RigaSpesa` (origine scontrino): `totaleStampato` = importo; quantita'/unitario letti solo se l'unitario c'e', non e' zero e l'importo e' positivo, altrimenti `Pezzi(1)` × importo; nome troncato a 80. null per importo zero |
| `_companion` | `RigheCompanion _companion(RigaSpesa r, {required int spesaId, required String insieme, required int posizione})` | `RigaSpesa` → `RigheCompanion.insert` (pezzi o millesimi+unita', `totale_cents` = `r.totale`, offerta in JSON, `creata_il` = adesso) |
| `_spesa` | `Future<Spesa> _spesa(SpesaRow row) async` | Carica le righe (posizione, id) e chiama `spesaDaRiga` |
| `spesaDaRiga` | `static Spesa spesaDaRiga(SpesaRow row, List<RigaRow> righe)` | `SpesaRow` + righe → `Spesa` (anche dal backup e dai test): righe separate per insieme (stornate comprese), `totaleSalvato` solo se chiusa |
| `_riga` | `static RigaSpesa _riga(RigaRow r)` | `RigaRow` → `RigaSpesa`; offerta illeggibile → null (il totale salvato non cambia); origine sconosciuta → tastierino |

### 6.3 `spending_backup_source.dart` — backup (Pro) e ripristino (gratis)

Formato del payload, schema 1 (dentro il file di `BackupService.createBackup`, JSON, **nessuna immagine**):
```
negozi: [{id, nome, creatoIl}]
spese:  [{id, stato, negozioId?, iniziataIl, chiusaIl?, dataSpesa?, budget?, totale, totaleScontrino?, fonte}]
righe:  [{spesaId, insieme, posizione, nome, pezzi?, millesimi?, unita?, prezzoUnitario, totale,
          offerta?, prezzoRif?, unitaRif?, totaleStampato?, origine, stornata, creataIl}]
```
Importi in centesimi interi; date come nel database (epoch ms UTC, `YYYY-MM-DD`). ⚑ Gli `id` del file
servono SOLO a collegare righe → spese → negozi dentro il file: al ripristino si riassegnano.
Ripristino: `replaceAll` svuota e riscrive tutto in una transazione (anche la spesa in corso del file);
`mergeKeepExisting` unisce i negozi per nome (NOCASE) e aggiunge le spese con id nuovi; ⚑ una spesa IN
CORSO del file diventa **chiusa** (data = giorno di `iniziataIl`, totale = somma delle righe contate) se
ha righe, altrimenti si scarta: l'indice unico ne vuole una sola, e quella del telefono vince. ☠ Le
**preferenze** (budget abituale, tetto del mese, tema, vibrazione) **non** sono nel backup (debito §15.2).

`class SpendingBackupSource implements BackupSource` — file `lib/data/spending_backup_source.dart`

La `BackupSource` di micro_core (formato al §6.3). Backup Pro, ripristino gratis

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final SpendingDatabase _db` |  |
| `()` | `SpendingBackupSource(this._db)` | costruttore: i parametri sono i campi omonimi |
| `id` | `static const String id = 'spending_review'` | `'spending_review'` (schemaId del manifest: il ripristino rifiuta file di altre app) |
| `schemaId` | `String get schemaId` | `id` |
| `schemaVersion` | `int get schemaVersion` | 1 |
| `exportPayload` | `Future<Map<String, Object?>> exportPayload() async` | `{negozi, spese, righe}` con tutte le colonne (centesimi, epoch ms, ISO), righe per id |
| `counts` | `Future<Map<String, int>> counts() async` | `{spese, righe, negozi}` (il riepilogo prima di ripristinare) |
| `imagePaths` | `Future<List<String>> imagePaths() async` | `[]`: nessuna immagine conservata |
| `importPayload` | `Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode}) async` | In UNA transazione: `replaceAll` svuota righe, spese, negozi; negozi uniti per nome NOCASE; spesa in corso del file → chiusa (data = giorno di `iniziataIl`, totale = somma delle contate) se in merge o se il telefono ne ha gia' una, scartata se senza righe; righe reinserite con id nuovi. ☠ `FormatException` (anche per un campo del tipo sbagliato, F12.8) dentro la transazione → nulla cambia |
| `_lista` | `static List<Map<String, Object?>> _lista(Map<String, Object?> payload, String chiave)` | La lista sotto `chiave`; `FormatException` se manca o un elemento non e' una mappa |
| `_intero` | `static int _intero(Map<String, Object?> m, String k)` | Intero obbligatorio (`FormatException` se manca) |
| `_interoONull` | `static int? _interoONull(Map<String, Object?> m, String k)` | null, int, o double con valore intero; altro → `FormatException` |
| `_testo` | `static String _testo(Map<String, Object?> m, String k)` | Stringa obbligatoria (`FormatException` se manca) |
| `_testoONull` | `static String? _testoONull(Map<String, Object?> m, String k)` | null o stringa; altro tipo → `FormatException` (⚑ F12.8: prima `as String?`, cioe' `TypeError`, che `BackupService.restore` non intercetta) |

## 7. `lib/app/`

### 7.1 `providers.dart` — i provider radice

⚑ **Tutto passa dai provider, niente singleton globali**: un singleton non si sostituisce nei test e
obbliga a inizializzare in `main` cose che servono a una schermata sola. Ogni servizio con un lato nativo
(OCR, fotocamera, ritaglio, selettore, impostazioni di sistema, vibrazione) ha il suo provider, che i
test di widget sostituiscono con un doppio (`sr_test_harness.dart`).

| Nome | Firma | Effetto |
|---|---|---|
| `appConfigProvider` | `final appConfigProvider = Provider<MicroAppConfig>((ref) => throw UnimplementedError('appConfigProvider va sovrascritto in main()'))` | ☠ Lancia `UnimplementedError` se non sovrascritto in `main()` (o nei test) |
| `appPathsProvider` | `final appPathsProvider = Provider<AppPaths>((ref) => throw UnimplementedError('appPathsProvider va sovrascritto in main()'))` | Come sopra: le cartelle di `AppPaths` (logs, support, exports, backups…) |
| `settingsProvider` | `final settingsProvider = Provider<SettingsStore>((ref) => throw UnimplementedError('settingsProvider va sovrascritto in main()'))` | Come sopra: `SettingsStore` con namespace `spending_review` |
| `themeModeProvider` | `final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new)` | Il tema scelto |
| `budgetPredefinitoProvider` | `final budgetPredefinitoProvider = NotifierProvider<_MoneySetting, Money?>(() => _MoneySetting(SrSettingKeys.budgetPredefinito))` | Il budget abituale (precompila quello della spesa nuova) |
| `budgetMensileProvider` | `final budgetMensileProvider = NotifierProvider<_MoneySetting, Money?>(() => _MoneySetting(SrSettingKeys.budgetMensile))` | Il tetto del mese (Statistiche, Pro, D3) |
| `vibrazioneProvider` | `final vibrazioneProvider = NotifierProvider<_BoolSetting, bool>(() => _BoolSetting(SrSettingKeys.vibrazione, predefinito: true))` | Vibrazioni (default accese) |
| `suggerimentoMirinoVistoProvider` | `final suggerimentoMirinoVistoProvider = NotifierProvider<_BoolSetting, bool>(() => _BoolSetting(SrSettingKeys.suggerimentoMirinoVisto, predefinito: false))` | Il suggerimento del mirino gia' visto (default no) |
| `oraProvider` | `final oraProvider = Provider<DateTime Function()>((ref) => DateTime.now)` | L'orologio (`DateTime.now`), sovrascritto nei test con `kOra` |
| `ocrEngineProvider` | `final ocrEngineProvider = Provider<OcrEngine>((ref) => CanaleOcrEngine())` | `CanaleOcrEngine()` di micro_ocr (Vision su iOS, PP-OCRv5/ORT su Android); nei test `FakeOcrEngine` |
| `letturaServiceProvider` | `final letturaServiceProvider = Provider<LetturaService>((ref) => LetturaService(motore: ref.watch(ocrEngineProvider), ora: ref.watch(oraProvider)))` | `LetturaService(motore: ocrEngineProvider, ora: oraProvider)` |
| `obiettivoProvider` | `final obiettivoProvider = Provider<Obiettivo Function()>((ref) => ObiettivoCamera.new)` | Una FABBRICA di `Obiettivo` (`ObiettivoCamera.new`): ogni pagina col mirino ne apre e chiude uno suo; nei test `ObiettivoFinto` |
| `Ritaglio` | `typedef Ritaglio = Future<String> Function(String percorsoFoto, Rect mirino, {required Size anteprima});` | La firma di `Fotocamera.ritagliaAlMirino` senza la cartella (sostituibile nei test) |
| `ritaglioProvider` | `final ritaglioProvider = Provider<Ritaglio>((ref) => (foto, mirino, {required anteprima}) => Fotocamera.ritagliaAlMirino(foto, mirino, anteprima:…` | `Fotocamera.ritagliaAlMirino` (isolate); nei test di widget un finto (la fotocamera finta non fa JPEG veri) |
| `scegliFotoProvider` | `final scegliFotoProvider = Provider<ScegliFoto>((ref) => scegliFotoDiSistema)` | `scegliFotoDiSistema` (image_picker); nei test una funzione che restituisce copie |
| `impostazioniSistemaProvider` | `final impostazioniSistemaProvider = Provider<ImpostazioniSistema>((ref) => const ImpostazioniSistema())` | `const ImpostazioniSistema()`; nei test `ImpostazioniFinte` |
| `apticaProvider` | `final apticaProvider = Provider<Aptica>((ref) => Aptica(attiva: ref.watch(vibrazioneProvider)))` | `Aptica(attiva: vibrazioneProvider)`; nei test `ApticaRegistrata` |
| `csvExportProvider` | `final csvExportProvider = Provider<CsvExport>((ref) => const CsvExport())` | `const CsvExport()` |
| `tastierinoProvider` | `final tastierinoProvider = NotifierProvider<TastierinoNotifier, TastierinoState>(TastierinoNotifier.new)` | Il tastierino |
| `databaseProvider` | `final databaseProvider = Provider<SpendingDatabase>((ref) {final db = SpendingDatabase.open(); ref.onDispose(db.close); return db;})` | `SpendingDatabase.open()` alla prima lettura (pigro), `close` alla chiusura del `ProviderScope` |
| `spesaRepositoryProvider` | `final spesaRepositoryProvider = Provider<SpesaRepository>((ref) => SpesaRepository(ref.watch(databaseProvider)))` | `SpesaRepository(databaseProvider)` |
| `spesaInCorsoProvider` | `final spesaInCorsoProvider = StreamProvider<Spesa?>((ref) => ref.watch(spesaRepositoryProvider).osservaInCorso())` | `osservaInCorso()`: la spesa in corso con le righe, null finche' non nasce |
| `speseChiuseProvider` | `final speseChiuseProvider = StreamProvider<List<Spesa>>((ref) {final gate = ref.watch(featureGateProvider); final limite = gate.isPro ? null : gate.…` | `osservaChiuse(limite: isPro ? null : freeLimitOf(fullHistory))`: le VISIBILI (5 nel gratis). ⚑ Il 5 viene da `FeatureGate`, non e' scritto qui |
| `tutteLeChiuseProvider` | `final tutteLeChiuseProvider = StreamProvider<List<Spesa>>((ref) => ref.watch(spesaRepositoryProvider).osservaChiuse())` | `osservaChiuse()` senza limite: statistiche (Pro). Separato per non caricare le righe di tutte le spese nello storico gratis |
| `numeroChiuseProvider` | `final numeroChiuseProvider = StreamProvider<int>((ref) => ref.watch(spesaRepositoryProvider).osservaNumeroChiuse())` | `osservaNumeroChiuse()`: anche le nascoste (card «Le altre N spese») |
| `negoziProvider` | `final negoziProvider = StreamProvider<List<Negozio>>((ref) => ref.watch(spesaRepositoryProvider).osservaNegozi())` | `osservaNegozi()`: per nome, senza maiuscole |
| `backupServiceProvider` | `final backupServiceProvider = Provider<BackupService>((ref) => BackupService(paths: ref.watch(appPathsProvider), appVersion: appVersion))` | `BackupService(paths, appVersion)` di micro_core |
| `backupSourceProvider` | `final backupSourceProvider = Provider<SpendingBackupSource>((ref) => SpendingBackupSource(ref.watch(databaseProvider)))` | `SpendingBackupSource(databaseProvider)` |

`abstract final class SrSettingKeys` — file `lib/app/providers.dart`

Le chiavi delle preferenze proprie (quelle comuni sono `SettingKeys` di micro_core). Salvate come `spending_review.<chiave>` da `SettingsStore`

| Membro | Firma | Effetto |
|---|---|---|
| `budgetPredefinito` | `static const String budgetPredefinito = 'budget_predefinito'` | int centesimi; assente = nessun budget abituale |
| `budgetMensile` | `static const String budgetMensile = 'budget_mensile'` | int centesimi; il tetto del MESE (D3, Pro); assente = nessuno |
| `vibrazione` | `static const String vibrazione = 'vibrazione'` | bool, default `true` |
| `suggerimentoMirinoVisto` | `static const String suggerimentoMirinoVisto = 'suggerimento_mirino_visto'` | bool, default `false`: il suggerimento «Lo scritto a mano non lo leggo» gia' mostrato |

`class ThemeModeNotifier extends Notifier<ThemeMode>` — file `lib/app/providers.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `build` | `ThemeMode build()` | Legge `SettingKeys.themeMode`: `'light'` → chiaro, `'system'` → sistema, altro/assente → ⚑ SCURO |
| `set` | `Future<void> set(ThemeMode mode) async` | Aggiorna lo stato e scrive `mode.name` |

`class _MoneySetting extends Notifier<Money?>` — file `lib/app/providers.dart`

Un importo in centesimi nelle preferenze (chiave nel costruttore)

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String _chiave` |  |
| `()` | `_MoneySetting(this._chiave)` | costruttore: i parametri sono i campi omonimi |
| `build` | `Money? build()` | `getInt(chiave, orElse: 0)`: > 0 → `Money.cents`, altrimenti null |
| `set` | `Future<void> set(Money? valore) async` | null o ≤ 0 → `remove(chiave)`; altrimenti `setInt(cents)` |

`class _BoolSetting extends Notifier<bool>` — file `lib/app/providers.dart`

Un interruttore nelle preferenze con il suo default

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String _chiave` · `final bool predefinito` |  |
| `()` | `_BoolSetting(this._chiave, {required this.predefinito})` | costruttore: i parametri sono i campi omonimi |
| `build` | `bool build()` | `getBool(chiave, orElse: predefinito)` |
| `set` | `Future<void> set(bool valore) async` | Aggiorna lo stato e `setBool` |

`class TastierinoNotifier extends Notifier<TastierinoState>` — file `lib/app/providers.dart`

Lo stato del tastierino della spesa in corso. ⚑ Un provider e non lo stato della pagina: «Batti a mano» del foglio del cartellino ci scrive, e il valore a meta' sopravvive a un giro nello storico

| Membro | Firma | Effetto |
|---|---|---|
| `build` | `TastierinoState build()` | `TastierinoState.vuoto()` |
| `premi` | `EffettoTasto premi(TastoTastierino tasto)` | `state.premi(tasto)`: aggiorna lo stato e ritorna l'`EffettoTasto` (lo applica la pagina) |
| `svuota` | `void svuota()` | Display vuoto (pressione lunga su ⌫, chiusura della spesa) |
| `precompila` | `void precompila(Money prezzo)` | `TastierinoState.daPrezzo(prezzo)`: «Batti a mano» |

### 7.2 `entitlement.dart`, `feature_limits.dart`, `paywall_config.dart` — il Pro

| Nome | Firma | Effetto |
|---|---|---|
| `appVersion` | `const String appVersion = '1.0.0'` | La versione in un posto solo: backup, chiamate al server, Impostazioni > Informazioni. ⚑ Va tenuta allineata a `version:` del pubspec a mano |
| `installIdProvider` | `final installIdProvider = FutureProvider<InstallId>((ref) => InstallId.load(appId: ref.watch(appConfigProvider).appId))` | `InstallId.load(appId)`: l'id d'installazione per il License Server |
| `purchaseGatewayProvider` | `final purchaseGatewayProvider = Provider<PurchaseGateway>((ref) {final config = ref.watch(appConfigProvider); final gateway = switch (config.billingMode…` | `BillingMode.store` → `StorePurchaseGateway()`; `BillingMode.fake` → `FakePurchaseGateway.withProduct(proSku, formattedPrice: '2,99 €')` (parte senza Pro). `dispose` alla chiusura |
| `entitlementProvider` | `final entitlementProvider = NotifierProvider<EntitlementNotifier, EntitlementView>(EntitlementNotifier.new)` | `NotifierProvider<EntitlementNotifier, EntitlementView>` |
| `isProProvider` | `final isProProvider = Provider<bool>((ref) => ref.watch(entitlementProvider).isPro)` | `entitlementProvider.isPro` (i test lo sovrascrivono per il Pro finto) |
| `featureGateProvider` | `final featureGateProvider = Provider<FeatureGate>((ref) => FeatureGate(limits: srFeatureLimits, isPro: ref.watch(isProProvider)))` | `FeatureGate(limits: srFeatureLimits, isPro: isProProvider)`: LA porta di ogni decisione gratis/Pro |

`class EntitlementView` — file `lib/app/entitlement.dart`

Stato immutabile del Pro per la UI (al posto del `ChangeNotifier` del servizio). Copia di QR Me: ☠ debito «sei copie» (§15)

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Entitlement entitlement` · `final bool busy` · `final bool storeAvailable` · `final MicroProduct? product` · `final MicroError? error` |  |
| `()` | `const EntitlementView({required this.entitlement, required this.busy, required this.storeAvailable, this.product, this.error})` | costruttore: i parametri sono i campi omonimi |
| `isPro` | `bool get isPro` | `entitlement.isPro` |
| `isPending` | `bool get isPending` | acquisto in sospeso |
| `operator==` | `bool operator ==(Object other)` | uguali se entitlement, busy, store, id e prezzo del prodotto, codice d'errore coincidono |
| `hashCode` | `int get hashCode` | coerente con `==` |

`class EntitlementNotifier extends Notifier<EntitlementView>` — file `lib/app/entitlement.dart`

Crea `EntitlementService` (store + server licenze se `serverEnabled` e `installId` pronto, `EntitlementStore` su `support/entitlement.json`), ascolta i cambi e fa partire `bootstrap()` da solo

| Membro | Firma | Effetto |
|---|---|---|
| campi | `EntitlementService? _service` |  |
| `service` | `EntitlementService get service` | Il servizio per le azioni (acquisto, ripristino); ☠ `!`: valido solo dopo `build` |
| `build` | `EntitlementView build()` | Costruisce servizio e client licenze, registra `_sync`, `ref.onDispose` (toglie il listener, `dispose`, `api?.close()`), `unawaited(service.bootstrap())`, ritorna `_snapshot` |
| `_sync` | `void _sync()` | Ricopia lo stato del servizio in `state` (ridisegna la UI) |
| `_snapshot` | `static EntitlementView _snapshot(EntitlementService service)` | `EntitlementView` dal servizio (current, isBusy, storeAvailable, proProduct, lastError) |

| Nome | Firma | Effetto |
|---|---|---|
| `srFeatureLimits` | `const FeatureLimits srFeatureLimits = <FeatureKey, FeatureLimit>{FeatureKey.fullHistory: FeatureLimit.count(freeMax: 5), FeatureKey.documentScan: FeatureLimit…` | Le 16 chiavi di `FeatureKey` (§11): `fullHistory` → `count(freeMax: 5)`; `documentScan`, `statistics`, `csvExport`, `backupRestore` → `locked()`; le altre 11 → `open()` |

| Nome | Firma | Effetto |
|---|---|---|
| `buildSrPaywall` | `PaywallConfig buildSrPaywall(L l)` | `PaywallConfig` con i testi ARB e 5 benefici nell'ordine: Scontrino (`documentScan`, `Icons.receipt_long_outlined`), tutte le spese (`fullHistory`), statistiche (`statistics`), CSV (`csvExport`), backup (`backupRestore`) |
| `showSrPaywall` | `Future<bool> showSrPaywall(BuildContext context, WidgetRef ref, {FeatureKey? highlight})` | `PaywallPage.show(config: buildSrPaywall(L), service: entitlementProvider.notifier.service, highlight)`: `true` se si esce col Pro |

☠ Ogni chiave limitata ha il suo beneficio nel paywall e viceversa, e `srFeatureLimits` scrive **tutte**
le 16 chiavi di `FeatureKey`: lo verifica `test/widget/paywall_config_test.dart` (trappola pagata in
TrashCan). ⚑ Ordine dei benefici: prima lo Scontrino (si vede alla cassa ed e' l'unica cosa che il gratis
non ha in nessuna forma).

### 7.3 `app_config.dart`

| Nome | Firma | Effetto |
|---|---|---|
| `licenseAppId` | `const String licenseAppId = 'spendingreview'` | L'id di Spending Review per il License Server (tabella `apps`, `APP_SECRETS`). ☠ Senza trattino basso, diverso da `appId` |
| `buildSrConfig` | `MicroAppConfig buildSrConfig()` | `MicroAppConfig.fromEnvironment(appId: 'spending_review', appName: 'Spending Review', proSku: 'spendingreview_pro_lifetime', seedColor: #4ADE80, fontFamily: 'PlusJakartaSans', defaultBrightness: dark)`; legge i dart-define `BILLING`, `MA_LICENSE_URL`, `MA_APP_SECRET` (§12) |

### 7.4 `labels.dart` — il dominio scritto in parole

⚑ Il dominio non ha testi: i nomi cambiano con la lingua e stanno qui. Gli switch sono esaustivi di
proposito: un'offerta nuova non compila finche' non ha la sua etichetta. ⚑ **Gli importi si scrivono
sempre con la virgola** («2,49»), anche in inglese: il tastierino «alla cassa» mostra la virgola, e un
«2.49» nella lista sotto un «2,49» nel display sarebbe una seconda lingua dei numeri.

| Nome | Firma | Effetto |
|---|---|---|
| `nomeRiga` | `String nomeRiga(L l, RigaSpesa r)` | Il nome mostrato: `r.nome` se non vuoto; altrimenti `riga_sconto` («Sconto») per gli sconti, `riga_senzaNome` («Articolo») |
| `importo` | `String importo(Money m)` | «43,70», «−1,50»: virgola SEMPRE (anche in inglese), meno tipografico U+2212; senza simbolo € |
| `importoTondo` | `String importoTondo(Money m)` | «60» se intero, altrimenti come `importo` («60,50»): i budget |
| `importoConSegno` | `String importoConSegno(Money m)` | «+1,65» per i positivi, `importo` per zero e negativi: residuo e differenze |
| `millesimiTesto` | `String millesimiTesto(int millesimi)` | 258 → «0,258» (grammi/millilitri come kg/l, tre decimali) |
| `unitaTesto` | `String unitaTesto(UnitaMisura u)` | `kg` → «kg», `l` → «l» |
| `offertaBreve` | `String? offertaBreve(Offerta? o)` | «3x2», «−30%», «−50% 2°»; null per barrato e carta (informative) e per null. Switch esaustivo: un'offerta nuova non compila senza etichetta |
| `offertaTesto` | `String? offertaTesto(L l, Offerta? o)` | Come `offertaBreve` ma anche le informative: «anziché 2,99» (`offerta_anziche`), «con carta (senza 2,49)» (`offerta_conCarta`). Per CSV e chip della riga |
| `offertaLunga` | `String offertaLunga(L l, Offerta o, Money prezzo)` | La pillola del foglio di conferma: NxM → `offerta_nxmLunga('3x2', effettivo, prendi)`; percentuale → `offerta_percentoLunga(p, scontato)`; secondo → `offerta_secondoLunga`; barrato → `offerta_barratoLunga(pieno, risparmio)`; carta → `offerta_cartaLunga(senza)` |
| `dettaglioRiga` | `String? dettaglioRiga(RigaSpesa r)` | La riga piccola nella lista: «3 × 2,49» (pezzi > 1), «0,258 kg × 29,90 €/kg» (a misura), poi l'offerta breve, uniti da « · »; null se non serve |

### 7.5 `licenze.dart`, `locale_resolution.dart`

| Nome | Firma | Effetto |
|---|---|---|
| `registraLicenze` | `void registraLicenze({TargetPlatform? piattaforma})` | `LicenseRegistry.addLicense` pigro: su Android PaddleOCR/RapidOCR (`assets/licenses/paddleocr-rapidocr.txt`) e ONNX Runtime (`assets/licenses/onnxruntime.txt`); ovunque i due font OFL. `piattaforma` iniettabile per i test |

⚑ `showLicensePage` mostra solo le licenze dei pacchetti pub: modelli PP-OCRv5/RapidOCR (Apache-2.0, che
chiede di distribuire il testo), ONNX Runtime (MIT) e i font (OFL) vanno registrati a mano. Solo su
Android le prime due (su iPhone legge Vision, del sistema).

| Nome | Firma | Effetto |
|---|---|---|
| `kSupportedLocales` | `const List<Locale> kSupportedLocales = <Locale>[Locale('en'), Locale('it')]` | `[en, it]`: ⚑ inglese PRIMO (ripiego di Flutter per le lingue non supportate) |
| `resolveAppLocale` | `Locale resolveAppLocale(List<Locale>? deviceLocales, Iterable<Locale> supported)` | Italiano se `it` compare in QUALUNQUE posizione delle lingue del dispositivo, altrimenti inglese (ADR-011) |

### 7.6 `sr_palette.dart` — «C · Una mano»

| Colore | Scuro (tavola, esatto) | Chiaro (derivato) | Dove |
|---|---|---|---|
| `sfondo` | `#161B22` | `#F6F8FA` | fondo delle pagine, splash |
| `fondoProfondo` | `#0F1318` | `#E9EDF1` | pannello del tastierino |
| `superficie` | `#1E252E` | `#FFFFFF` | tasti numerici, card, bottone Scontrino |
| `superficieOp` | `#262D36` | `#DDE3E9` | tasti × − ⌫, traccia della barra, separatori |
| `bordo` | `#3A434E` | `#C3CBD4` | bottoni secondari |
| `testo` | `#E8EDF2` | `#12171D` | testo; ⚑ anche il TOTALE (non si colora mai) |
| `testoLista` | `#C8D0D8` | `#2B333C` | nomi nella lista |
| `testoSecondario` | `#9AA5B1` | `#55606C` | «9 articoli · budget 60 €», «€», etichette |
| `accento` | `#4ADE80` | `#15803D` | barra sotto budget, Cartellino, «+» |
| `suAccento` | `#05230F` | `#FFFFFF` | testo sui bottoni verdi |
| `ambraFondo` / `ambraBordo` / `ambraTesto` / `ambraValore` | `#3B2410` / `#B45309` / `#FCD9A8` / `#FBBF24` | `#FFF4E5` / `#B45309` / `#7A3E06` / `#B45309` | «Differenza da guardare», budget 80–100% |
| `rosso` | `#F87171` | `#B91C1C` | budget sforato (⚑ assente dalla tavola: terzo stato distinguibile anche per luminosita') |

Contrasti AA verificati da `palette_contrast_test.dart` in entrambi i temi. ⚑ Come QR Me, la palette
cambia **anche** il `ColorScheme` (il verde spento e il terziario azzurro che Material ricava dal seme
stonerebbero; anche il terziario, lezione di Film Tracker).

| Nome | Firma | Effetto |
|---|---|---|
| `kNumeriFont` | `const String kNumeriFont = 'SpaceGrotesk'` | Space Grotesk 700: totale, tastierino, numeri delle card |
| `withSrLook` | `ThemeData withSrLook(ThemeData base, SrPalette p)` | Il `ThemeData` di Material vestito: `ColorScheme` riscritto (primary/secondary/tertiary = accento, surface = sfondo, error = rosso…), scaffold/appBar/card (raggio 18)/bottomSheet/dialog, `FilledButton` pillola alta 56 testo 800, `OutlinedButton` pillola 56 con bordo, divider, snackBar, estensione `SrPalette` |

`class SrPalette extends ThemeExtension<SrPalette>` — file `lib/app/sr_palette.dart`

I colori di «C · Una mano» come `ThemeExtension` (valori esatti nella tabella di §7.6)

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Color sfondo` · `final Color fondoProfondo` · `final Color superficie` · `final Color superficieOp` · `final Color bordo` · `final Color testo` · `final Color testoLista` · `final Color testoSecondario` · `final Color accento` · `final Color suAccento` · `final Color ambraFondo` · `final Color ambraBordo` · `final Color ambraTesto` · `final Color ambraValore` · `final Color rosso` |  |
| `()` | `const SrPalette({required this.sfondo, required this.fondoProfondo, required this.superficie, required this.superficieOp, required this.bordo, required this.testo, required this.testoLista, required this.testoSecondario, required this.accento, required this.suAccento, required this.ambraFondo, required this.ambraBordo, required this.ambraTesto, required this.ambraValore, required this.rosso})` | costruttore: i parametri sono i campi omonimi |
| `scuro` | `static const SrPalette scuro = SrPalette(sfondo: Color(0xFF161B22), fondoProfondo: Color(0xFF0F1318), superficie: Color(0…` | Il tema disegnato (default) |
| `chiaro` | `static const SrPalette chiaro = SrPalette(sfondo: Color(0xFFF6F8FA), fondoProfondo: Color(0xFFE9EDF1), superficie: Color(0…` | Derivato: accento scurito a #15803D (il #4ADE80 su bianco fa ~1,6:1) |
| `of` | `static SrPalette of(BuildContext context)` | `Theme.of(context).extension<SrPalette>() ?? SrPalette.scuro` |
| `coloreBudget` | `Color? coloreBudget(LivelloBudget livello)` | `nessuno` → null (niente barra), `ok` → accento, `vicino` → ambraValore, `sforato` → rosso |
| `numeri` | `TextStyle numeri({double size = 20, Color? color, double? letterSpacing})` | `TextStyle` Space Grotesk w700 (`FontVariation('wght', 700)`), `height: 1`, colore default `testo` |
| `copyWith` | `SrPalette copyWith()` | ritorna se stessa (la palette non si ritocca a pezzi) |
| `lerp` | `SrPalette lerp(ThemeExtension<SrPalette>? other, double t)` | nessuna interpolazione: sotto meta' questa, sopra l'altra |

### 7.7 `routes.dart`

`abstract final class Routes` — file `lib/app/routes.dart`

I percorsi in un posto solo (§8). ⚑ Nessuna rotta `/pro`: il paywall si apre con `showSrPaywall`

| Membro | Firma | Effetto |
|---|---|---|
| `spesa` | `static const String spesa = '/'` |  |
| `cartellino` | `static const String cartellino = '/cartellino'` |  |
| `cartellinoBilancia` | `static const String cartellinoBilancia = '/cartellino?modo=bilancia'` |  |
| `scontrino` | `static const String scontrino = '/scontrino'` |  |
| `confronto` | `static const String confronto = '/scontrino/confronto'` |  |
| `registra` | `static const String registra = '/scontrino/registra'` |  |
| `chiudi` | `static const String chiudi = '/chiudi'` |  |
| `storico` | `static const String storico = '/storico'` |  |
| `dettaglio` | `static const String dettaglio = '/storico/:id'` |  |
| `dettaglioDi` | `static String dettaglioDi(int id)` | `'/storico/$id'` |
| `statistiche` | `static const String statistiche = '/statistiche'` |  |
| `impostazioni` | `static const String impostazioni = '/impostazioni'` |  |
| `negozi` | `static const String negozi = '/impostazioni/negozi'` |  |
| `devOcr` | `static const String devOcr = '/dev/ocr'` |  |

`final class ChiusuraArgs` — file `lib/app/routes.dart`

L'`extra` di `/chiudi`: quale insieme fa fede (`fonte`, default contate) e lo scontrino letto (`lettura`, null senza scontrino)

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final FonteRighe fonte` · `final LetturaScontrino? lettura` |  |
| `()` | `const ChiusuraArgs({this.fonte = FonteRighe.contate, this.lettura})` | costruttore: i parametri sono i campi omonimi |

| Nome | Firma | Effetto |
|---|---|---|
| `rottaDevAttiva` | `bool rottaDevAttiva({required bool debug, required bool srDev})` | `debug \|\| srDev`. ⚑ Una funzione con i due interruttori iniettati (non una costante): `dev_route_test.dart` la prova con entrambi falsi |
| `kSrDev` | `const bool kSrDev = bool.fromEnvironment('SR_DEV')` | `--dart-define=SR_DEV=true`: la rotta `/dev/ocr` anche in profile. ☠ In release `main` si ferma |

## 8. Le rotte e l'avvio

### 8.1 Le rotte (`buildRouter`, `lib/app/app.dart`)

⚑ **Tutte le rotte sono figlie di `/`**: un `go('/storico/5')` costruisce la pila `/` → `/storico` →
`/storico/5`, e «indietro» riporta sempre alla spesa invece di chiudere l'app.
⚑ **`ProGate` sulla rotta** per le pagine Pro: un `push` diretto (o una porta scritta domani) non apre una
pagina Pro gratis. ☠ Non un `redirect` di go_router (Full Freezer: pila con `/` due volte e pagina d'errore).
☠ Deep link di Flutter **spento** (manifest e Info.plist): l'app non riceve link.

| Percorso | Costante | Pagina | Guardia | Argomenti | Errori |
|---|---|---|---|---|---|
| `/` | `Routes.spesa` | `SpesaPage` | — | — | — |
| `/cartellino` | `Routes.cartellino` | `CartellinoCameraPage(modoIniziale)` | — (gratis) | query `modo=bilancia` → `ModoLettura.bilancia`, altro → cartellino; torna con `pop(RisultatoCartellino)` | — |
| `/cartellino?modo=bilancia` | `Routes.cartellinoBilancia` | idem in modo bilancia | — | | |
| `/scontrino` | `Routes.scontrino` | `ScontrinoCameraPage` | `ProGate(documentScan)` | — | — |
| `/scontrino/confronto` | `Routes.confronto` | `ConfrontoPage(letto)` | `ProGate(documentScan)` | `extra: ScontrinoLetto` | extra mancante o di altro tipo → «Non trovato» |
| `/scontrino/registra` | `Routes.registra` | `RegistraScontrinoPage(letto)` | `ProGate(documentScan)` | `extra: ScontrinoLetto` | idem |
| `/chiudi` | `Routes.chiudi` | `ChiusuraPage(args)` | — | `extra: ChiusuraArgs` (default `ChiusuraArgs()`) | — |
| `/storico` | `Routes.storico` | `StoricoPage` | — (gratis: 5 visibili) | — | — |
| `/storico/:id` | `Routes.dettaglio`, `Routes.dettaglioDi(id)` | `DettaglioSpesaPage(id)` | **nella pagina**: gratis + spesa nascosta → lucchetto + paywall (`fullHistory`) | `:id` intero | `:id` non numerico → «Non trovato»; spesa assente o in corso → «Non trovato» |
| `/statistiche` | `Routes.statistiche` | `StatistichePage` | `ProGate(statistics)` | — | — |
| `/impostazioni` | `Routes.impostazioni` | `ImpostazioniPage(devAttiva)` | — | — | — |
| `/impostazioni/negozi` | `Routes.negozi` | `NegoziPage` | — | — | — |
| `/dev/ocr` | `Routes.devOcr` | `OcrDevPage` | **esiste solo** con `rottaDevAttiva(kDebugMode, kSrDev)` | — | in release → «Non trovato» |
| qualunque altro | — | `_NotFoundPage` | — | — | `errorBuilder` |

⚑ Nessuna rotta `/pro`: il paywall si apre con `showSrPaywall` (§8.T del piano).

### 8.2 `app.dart`

| Nome | Firma | Effetto |
|---|---|---|
| `buildRouter` | `GoRouter buildRouter({required bool devAttiva})` | Il `GoRouter` dell'app (§8): `initialLocation: '/'`, tutte le rotte figlie di `/`, `/dev/ocr` solo con `devAttiva`, `errorBuilder` → `_NotFoundPage` |
| `_figlia` | `String _figlia(String assoluto)` | `'/cartellino'` → `'cartellino'` (il percorso di una rotta figlia senza la barra iniziale) |
| `_id` | `int? _id(GoRouterState s)` | `int.tryParse(pathParameters['id'])`: null se non numerico → «Non trovato» |

`class SpendingReviewApp extends ConsumerStatefulWidget` — file `lib/app/app.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const SpendingReviewApp({super.key})` | costruttore: i parametri sono i campi omonimi |
| `createState` | `ConsumerState<SpendingReviewApp> createState()` | crea lo stato |

`class _SpendingReviewAppState extends ConsumerState<SpendingReviewApp>` — file `lib/app/app.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `late final GoRouter _router` · `Timer? _preparazione` | `_router` costruito una volta con `rottaDevAttiva(debug: kDebugMode, srDev: kSrDev)`; `_preparazione` = il timer dei 3 s |
| `initState` | `void initState()` | Dopo il primo frame avvia un `Timer` di 3 s che chiama `ocrEngineProvider.prepara()` (errore → `MicroLog.w('OCR non pronto')`, mai un crash) |
| `dispose` | `void dispose()` | Cancella il timer e chiude il router |
| `build` | `Widget build(BuildContext context)` | `MaterialApp.router`: titolo, `theme`/`darkTheme` = `withSrLook(MicroTheme.light/dark(seed, PlusJakartaSans, displayFontFamily: SpaceGrotesk, variant: fidelity), SrPalette.chiaro/scuro)`, `themeMode` da `themeModeProvider`, lingue `kSupportedLocales`, `localeListResolutionCallback: resolveAppLocale`, nessun banner di debug |

⚑ **Il motore OCR si prepara 3 secondi dopo il primo frame** (come `pruneOrphanLogos` di QR Me): la prima
lettura non paga il caricamento dei modelli (0,5–1 s su Android; `prepara()` 216 ms misurato sulla
release in emulatore) e l'avvio nemmeno (tastierino entro 1,5 s). Un motore assente non e' un errore: lo
dira' la prima lettura.

`class _NotFoundPage extends StatelessWidget` — file `lib/app/app.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const _NotFoundPage()` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | `Scaffold` con `AppBar` e il testo `common_notFound` centrato |

### 8.3 `main.dart`

| Nome | Firma | Effetto |
|---|---|---|
| `main` | `Future<void> main() async` | Avvio: `WidgetsFlutterBinding.ensureInitialized`; `buildSrConfig()` + `assertUsableInRelease()` (billing finto vietato in release); ☠ `StateError` se `kReleaseMode && kSrDev`; `AppPaths.forApp(appId)` + `ensureAll()`; `MicroLog.init` su `logs/spending_review.log`; `FlutterError.onError` → `MicroLog.e` + `presentError`; `registraLicenze()`; `SettingsStore.create(namespace: 'spending_review')`; `_recordLaunch`; con `demoEnabled` (`SR_DEMO`, mai in release) apre un `SpendingDatabase`, chiama `seedDemoData` nella lingua di `resolveAppLocale` e lo chiude (§2bis); `runApp(ProviderScope(overrides: [appConfigProvider, appPathsProvider, settingsProvider], child: SpendingReviewApp()))`. ⚑ Database e motore OCR NON qui (pigri, nei provider): niente schermata bianca all'avvio |
| `_recordLaunch` | `Future<void> _recordLaunch(SettingsStore settings) async` | `SettingKeys.launchCount` +1; scrive `SettingKeys.firstLaunchAt` (UTC) al primo avvio. Servono a decidere quando chiedere una recensione |

⚑ **Database e motore OCR NON si inizializzano in `main`**: farlo prima del primo frame produce una
schermata bianca (§8.T). Qui conta doppio: chi apre l'app e' alla cassa.
☠ `config.assertUsableInRelease()`: una release compilata con `BILLING=fake` regalerebbe il Pro; ☠ una
release con `SR_DEV=true` si ferma con `StateError` (la pagina di sviluppo esporta le righe lette).

## 9. `lib/services/`

### 9.1 `aptica.dart` — le vibrazioni

⚑ Perche' esistono: l'app si usa con una mano, spesso senza guardare lo schermo fino in fondo; una
vibrazione diversa per «tasto preso», «rifiutato», «riga aggiunta», «soglia del budget» dice cosa e'
successo senza leggere. ⚑ Una classe con `attiva` e non funzioni globali: i test la sostituiscono con
`ApticaRegistrata` e contano le chiamate.

`class Aptica` — file `lib/services/aptica.dart`

Le vibrazioni brevi (§9.1)

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final bool attiva` |  |
| `()` | `Aptica({required this.attiva})` | costruttore: i parametri sono i campi omonimi |
| `tasto` | `void tasto()` | `HapticFeedback.selectionClick` |
| `rifiuto` | `void rifiuto()` | `HapticFeedback.heavyImpact` |
| `soglia` | `void soglia()` | `HapticFeedback.mediumImpact` (80% e 100% del budget, una volta per soglia e spesa) |
| `aggiunto` | `void aggiunto()` | `HapticFeedback.lightImpact` (riga entrata) |
| `_fai` | `void _fai(Future<void> Function() effetto)` | Niente se `!attiva`; altrimenti `unawaited(effetto().catchError(...))`: mai attesa, mai un errore |

### 9.2 `csv_export.dart` — il CSV (Pro)

Un file, **una riga per RIGA di spesa** dell'insieme che fa fede; colonne (testi l10n `csv_*`): `Data;
Negozio; Spesa n.; Articolo; Quantita'; Unita'; Prezzo unitario; Offerta; Totale riga; Totale spesa;
Budget; Origine`. Decimali con la virgola (`Money.formatPlain(locale: 'it')`), separatore `;` e BOM
(`CsvWriter` di micro_core): Excel italiano lo apre senza chiedere. Pezzi → «n» + `csv_pezzi`; a misura →
«0,258» + `kg`/`l`. ⚑ Una spesa senza righe esce lo stesso (articolo vuoto, origine «scontrino»): il
totale non deve sparire. ☠ Nessun testo OCR grezzo puo' finirci (non esiste nel database).

`class CsvExport` — file `lib/services/csv_export.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const CsvExport()` | costruttore: i parametri sono i campi omonimi |
| `costruisci` | `String costruisci(List<Spesa> chiuse, Map<int, String> negozi, {required L l})` | Il CSV (§9.2): una riga per riga dell'insieme che fa fede; spesa senza righe → una riga con l'articolo vuoto |
| `nomeFile` | `static String nomeFile(CivilDate oggi)` | `spending-review-AAAA-MM-GG.csv` |

| Nome | Firma | Effetto |
|---|---|---|
| `origineTesto` | `String origineTesto(L l, OrigineRiga o)` | Il testo dell'origine (CSV e dettaglio) |

### 9.3 `fotocamera.dart` — scatto, ritaglio, selettore

⚑ **Si ritaglia al mirino prima dell'OCR**: il caso in cui il motore rende e' UN cartellino inquadrato
da vicino; la foto intera farebbe leggere anche gli scaffali e i prezzi accanto. ⚑ `Isolate.run`:
decodificare 12 MP sul thread dell'interfaccia lo blocca per 300–800 ms. ☠ **EXIF prima del conto**
(`bakeOrientation`): una foto verticale salvata coricata ritaglierebbe la zona sbagliata. ☠ **L'originale
si cancella nel `finally`**, ritaglio riuscito o no; il ritaglio lo cancella `LetturaService`.
⚑ `Obiettivo` e' un'interfaccia sopra il plugin `camera`: i test di widget non hanno una fotocamera, e con
`ObiettivoFinto` la pagina si prova intera.

`abstract final class Fotocamera` — file `lib/services/fotocamera.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `margine` | `static const double margine = 0.04` | 0,04: margine aggiunto al mirino per lato |
| `ritagliaAlMirino` | `static Future<String> ritagliaAlMirino(String percorsoFoto, Rect mirino, {required Size anteprima, String? cartella}) async` | Ritaglia in `Isolate.run`, scrive `sr_ritaglio_<µs>.jpg` (JPEG 92) in `cartella` o nella temporanea; ☠ cancella SEMPRE l'originale nel `finally` |
| `_ritaglia` | `static void _ritaglia(String ingresso, String uscita, ({double l, double t, double r, double b}) f, ({double w, double h}) a)` | Decodifica (☠ `FormatException('foto illeggibile')`), `bakeOrientation` (EXIF PRIMA del conto), `rettangoloNellaFoto`, `copyCrop`, `encodeJpg(92)` |
| `rettangoloNellaFoto` | `static Rect rettangoloNellaFoto(Size foto, Size anteprima, Rect mirino, {double margineFrazione = margine})` | Il mirino (frazioni dell'anteprima a riempimento, `BoxFit.cover` centrata) in pixel della foto, piu' il margine, dentro la foto. Funzione pura testata |
| `cancellaSeEsiste` | `static Future<void> cancellaSeEsiste(String percorso) async` | Cancella; non lancia mai. ⚠ Nessun controllo sulla cartella (vedi debito §15) |

`abstract interface class Obiettivo` — file `lib/services/fotocamera.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `apri` | `Future<void> apri()` | Permesso e fotocamera posteriore; lancia (`CameraException` `CameraAccessDenied…`, `StateError`) |
| `anteprima` | `Widget anteprima()` | L'anteprima a riempimento (cover centrata) |
| `scatta` | `Future<String> scatta()` | Il percorso del JPEG |
| `torcia` | `Future<bool> torcia(bool accesa)` | false se non c'e' |
| `chiudi` | `Future<void> chiudi()` | Idempotente |

`class ObiettivoCamera implements Obiettivo` — file `lib/services/fotocamera.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `CameraController? _controller` | `_controller` (`CameraController?`) |
| `apri` | `Future<void> apri() async` | `availableCameras()`, posteriore, `ResolutionPreset.veryHigh`, `enableAudio: false`, flash spento |
| `anteprima` | `Widget anteprima()` | `ClipRect` + `FittedBox(cover)` con i lati di `previewSize` SCAMBIATI (☠ e' orizzontale anche col telefono in verticale); nero se spenta |
| `scatta` | `Future<String> scatta() async` | `takePicture().path`; `StateError` se spenta |
| `torcia` | `Future<bool> torcia(bool accesa) async` | `FlashMode.torch`/`off`; false su errore |
| `chiudi` | `Future<void> chiudi() async` | `dispose` e null |

| Nome | Firma | Effetto |
|---|---|---|
| `ScegliFoto` | `typedef ScegliFoto = Future<List<String>> Function({required bool multiple});` | La firma del selettore di sistema |
| `scegliFotoDiSistema` | `Future<List<String>> scegliFotoDiSistema({required bool multiple}) async` | `pickMultiImage(limit: 4)` (max 4) o `pickImage(gallery)`; i percorsi delle COPIE temporanee; vuoto se annullato |

### 9.4 `lettura_service.dart` — foto → motore → parser

☠ **Le foto si cancellano sempre**, lette o no, anche con un errore (nel `finally`): e' la regola di
privacy dello scontrino. Si cancellano anche le **copie** che `image_picker` crea, ma ⚑ **solo se stanno
nelle cartelle temporanee dell'app** (`getTemporaryDirectory`, `getApplicationCacheDirectory`): un
originale dell'utente non si tocca mai (decisione 2026-10-10). Il testo OCR grezzo non esce da qui.

`sealed class RisultatoCartellino` — file `lib/services/lettura_service.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const RisultatoCartellino()` | costruttore: i parametri sono i campi omonimi |

`final class LettoCartellino extends RisultatoCartellino` — file `lib/services/lettura_service.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final LetturaCartellino lettura` | la `LetturaCartellino` |
| `()` | `const LettoCartellino(this.lettura)` | costruttore: i parametri sono i campi omonimi |

`final class LettaBilancia extends RisultatoCartellino` — file `lib/services/lettura_service.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final LetturaBilancia lettura` | la `LetturaBilancia` |
| `()` | `const LettaBilancia(this.lettura)` | costruttore: i parametri sono i campi omonimi |

`final class NienteLetto extends RisultatoCartellino` — file `lib/services/lettura_service.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final bool forseAMano` | `forseAMano`: testo letto ma nessun prezzo |
| `()` | `const NienteLetto({required this.forseAMano})` | costruttore: i parametri sono i campi omonimi |

`final class OcrAssente extends RisultatoCartellino` — file `lib/services/lettura_service.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const OcrAssente()` | costruttore: i parametri sono i campi omonimi |

`final class ScontrinoLetto` — file `lib/services/lettura_service.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final LetturaScontrino lettura` · `final List<bool> giunzioniTrovate` | `lettura` + `giunzioniTrovate` (una per coppia di foto consecutive) |
| `()` | `const ScontrinoLetto({required this.lettura, this.giunzioniTrovate = const []})` | costruttore: i parametri sono i campi omonimi |
| `parti` | `int get parti` | `giunzioniTrovate.length + 1` |
| `giunzioniMancanti` | `int get giunzioniMancanti` | Giunzioni non trovate |

⚑ `ScontrinoLetto` e' un tipo in piu' della specsheet (che faceva tornare la sola `LetturaScontrino`): il
confronto deve poter dire «Ho unito 2 foto senza trovare il punto di unione», e quell'informazione nasce
in `UnisciParti`, non nel parser. Viaggia come `extra` di `/scontrino/confronto` e `/scontrino/registra`.

`class LetturaService` — file `lib/services/lettura_service.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final OcrEngine motore` · `final CartellinoParser cartellinoParser` · `final BilanciaParser bilanciaParser` · `final ScontrinoParser scontrinoParser` · `final DateTime Function() _ora` · `final Future<bool> Function(String percorso) _cancellabile` |  |
| `()` | `LetturaService({required this.motore, this.cartellinoParser = const CartellinoParser(), this.bilanciaParser = const BilanciaParser(), this.scontrinoParser = const ScontrinoParser(), DateTime Function() ora = DateTime.now, Future<bool> Function(String percorso)? cancellabile})` | Parser iniettabili; `ora`; `cancellabile` (default `_nelleCartelleTemporanee`) |
| `cartellino` | `Future<RisultatoCartellino> cartellino(String percorso, {required bool forzaBilancia}) async` | `motore.leggi(modo: cartellino)` (`OcrNonDisponibile` → `OcrAssente`); `forzaBilancia` o `riconosce` → `LettaBilancia` se utile; poi cartellino → `LettoCartellino` o `NienteLetto`. ☠ Foto cancellata nel `finally`. Altri errori del motore PASSANO (la pagina li gestisce) |
| `scontrino` | `Future<ScontrinoLetto> scontrino(List<String> percorsi) async` | OCR di ogni parte in modo scontrino, `UnisciParti`, `ScontrinoParser(oggi: ora())`. ☠ `OcrNonDisponibile` passa; foto cancellate tutte nel `finally` |
| `_cancella` | `Future<void> _cancella(String percorso) async` | Cancella solo se `cancellabile`; non lancia mai |
| `_nelleCartelleTemporanee` | `static Future<bool> _nelleCartelleTemporanee(String percorso) async` | Il percorso sta in `getTemporaryDirectory()` o `getApplicationCacheDirectory()` |

### 9.5 `impostazioni_sistema.dart` — «Apri le impostazioni»

⚑ Un `MethodChannel` **nostro** su entrambe le piattaforme (`MainActivity.kt`, `AppDelegate.swift`) e non
`url_launcher` (assente) ne' `permission_handler` (vietato da F12.1.2): un pulsante non vale una
dipendenza. ☠ Senza, un permesso negato **per sempre** lascerebbe solo «Riprova», che il sistema ignora.

`class ImpostazioniSistema` — file `lib/services/impostazioni_sistema.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const ImpostazioniSistema()` | costruttore: i parametri sono i campi omonimi |
| `canale` | `static const MethodChannel canale = MethodChannel('com.smp.spendingreview/impostazioni')` | `MethodChannel('com.smp.spendingreview/impostazioni')` |
| `apri` | `Future<bool> apri() async` | `invokeMethod<bool>('apri')`; false (e `MicroLog.e`) su qualunque errore: non lancia mai |

## 10. `lib/features/` — le schermate

Chiavi dei widget (`ValueKey`) citate qui sono quelle usate dai test: cambiarle rompe i test.

### 10.1 La spesa — `spesa/spesa_page.dart` (`/`)

Tutto in una colonna **senza scorrimento della pagina** (scorre solo la lista). Dall'alto: barra discreta
(Storico `spesa_storico`, Chiudi la spesa `spesa_chiudi`, Impostazioni `spesa_impostazioni`), banner della
spesa vecchia (`spesa_banner`), riga di stato (`spesa_stato` → budget; residuo `spesa_residuo`), **totale
enorme** (`spesa_totale`), barra del budget, lista (`spesa_lista`, piu' recente in alto; vuota →
`spesa_vuota`), **Cartellino** (`spesa_cartellino`) e **Scontrino** (`spesa_scontrino`, badge PRO senza
Pro), **tastierino** (`display_tastierino`, tasti `tasto_<nome>`).
- ⚑ Il totale **non si colora** (massimo contrasto); il colore lo portano barra e residuo («−16,30» =
  quanto manca, «+3,20» = di quanto si e' sforato).
- ⚑ **Al 130% di testo** la pagina sta in 390×844 senza tagliare il tastierino: si riduce prima la lista
  (unica parte elastica), poi il totale (64 → 48 sotto i 700 dp), **mai** i tasti (alti 48 fissi). Il
  totale **non segue la scala del testo** (`MediaQuery.withNoTextScaling`): a 64 e' gia' enorme, a 83
  spingerebbe fuori il tastierino.
- Scorrere una riga a sinistra la elimina con «Annulla» per 5 s; tocco → `RigaSheet`.
- ☠ Un `Dismissible` scorso deve uscire dall'albero **subito** (`_scorse`), prima che il database
  risponda, o Flutter si ferma con «A dismissed Dismissible widget is still part of the tree».
- Vibrazioni: tasto, rifiuto, riga aggiunta, soglie 80% e 100% **una volta per soglia e per spesa**.
- Banner «Spesa iniziata ieri alle 18:32» (Chiudila / Continua) se la spesa ha righe ed e' aperta da
  piu' di 12 ore.
- ⚑ Scontrino senza Pro: paywall; **comprato il Pro, lo Scontrino si apre subito** (chi l'ha toccato alla
  cassa voleva quello).

`class SpesaPage extends ConsumerStatefulWidget` — file `lib/features/spesa/spesa_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const SpesaPage({super.key})` | costruttore: i parametri sono i campi omonimi |
| `altezzaCompatta` | `static const double altezzaCompatta = 700` | 700 dp: sotto, il totale passa da 64 a 48 |
| `spesaVecchia` | `static const Duration spesaVecchia = Duration(hours: 12)` | 12 ore: banner «Spesa iniziata ieri alle …» |
| `createState` | `ConsumerState<SpesaPage> createState()` | crea lo stato |

`class _SpesaPageState extends ConsumerState<SpesaPage>` — file `lib/features/spesa/spesa_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Set<int> _scorse` · `final Map<int, Set<LivelloBudget>> _soglie` · `int? _bannerChiusoPer` | `_scorse` (id gia' scorsi via, tolti dall'albero subito), `_soglie` (soglie del budget gia' vibrate per spesa), `_bannerChiusoPer` («Continua» sul banner) |
| `_azioni` | `AzioniSpesa get _azioni` | `AzioniSpesa(ref)` |
| `_tasto` | `Future<void> _tasto(TastoTastierino t) async` | Applica l'effetto: rifiuto → `aptica.rifiuto`; nessuno → `tasto`; `AggiungiRiga` → `AzioniSpesa.aggiungi(RigaSpesa(origine: tastierino))`; `IncrementaUltima` → repository (true → aggiunto, false → rifiuto) |
| `_controllaSoglie` | `void _controllaSoglie(Spesa? prima, Spesa? dopo)` | Vibrazione `soglia` quando il livello SALE a vicino o sforato, una volta per livello e spesa |
| `_apriBudget` | `Future<void> _apriBudget(Spesa? spesa) async` | `BudgetSheet` (con «usalo anche per le prossime») → `impostaBudget` (+ `budgetPredefinito` se scelto) |
| `_apriRiga` | `Future<void> _apriRiga(RigaSpesa riga) async` | `RigaSheet` → `aggiornaRiga` o `_elimina` |
| `_elimina` | `Future<void> _elimina(RigaSpesa riga) async` | Toglie subito dall'albero, legge la posizione, elimina, snack 5 s con «Annulla» → `ripristinaRiga` |
| `_scontrino` | `Future<void> _scontrino() async` | Col Pro → `/scontrino`; senza → paywall e, se si compra, `/scontrino` subito |
| `build` | `Widget build(BuildContext context)` | Colonna senza scorrimento: `_BarraAlta`, banner, `_RigaStato`, `_Totale` (64/48), `BarraBudget`, lista (piu' recente in alto, `Dismissible`), Cartellino/Scontrino (badge PRO), `PannelloTastierino` |

`class _BarraAlta extends StatelessWidget` — file `lib/features/spesa/spesa_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final bool chiudiAttivo` · `final VoidCallback onChiudi` |  |
| `()` | `const _BarraAlta({required this.chiudiAttivo, required this.onChiudi})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Titolo solo semantico; Storico, Chiudi la spesa (attiva con ≥ 1 riga), Impostazioni |

`class _RigaStato extends StatelessWidget` — file `lib/features/spesa/spesa_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Spesa? spesa` · `final VoidCallback onBudget` |  |
| `()` | `const _RigaStato({required this.spesa, required this.onBudget})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | «9 articoli · budget 60 €» (tocco → budget) e il residuo con segno colorato per livello |

`class _Totale extends StatelessWidget` — file `lib/features/spesa/spesa_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Spesa? spesa` · `final double dimensione` |  |
| `()` | `const _Totale({required this.spesa, required this.dimensione})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Totale + «€» in Space Grotesk, `MediaQuery.withNoTextScaling`, `FittedBox`; `Semantics(liveRegion)` con totale e residuo |

`class _RigaLista extends StatelessWidget` — file `lib/features/spesa/spesa_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final RigaSpesa riga` · `final VoidCallback onTap` |  |
| `()` | `const _RigaLista({required this.riga, required this.onTap})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Nome, `dettaglioRiga`, totale (accento per gli sconti); alta almeno 48 |

`class _BannerSpesaVecchia extends StatelessWidget` — file `lib/features/spesa/spesa_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final DateTime iniziata` · `final DateTime adesso` · `final VoidCallback onChiudi` · `final VoidCallback onContinua` |  |
| `()` | `const _BannerSpesaVecchia({required this.iniziata, required this.adesso, required this.onChiudi, required this.onContinua})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Riquadro ambra «Spesa iniziata ieri alle 18:32» / «il 3 ott alle …» con Chiudila e Continua |

### 10.1b Il foglio della riga e quello del budget — `spesa/riga_sheet.dart`, `spesa/budget_sheet.dart`

`RigaSheet` (tocco su una riga): nome (`riga_nome`), prezzo (`riga_prezzo`; per una riga della bilancia
e' il **totale stampato** a essere modificabile, perche' e' lui che conta), quantita' (`riga_meno`,
`riga_pezzi`, `riga_piu`), peso (riga a misura → foglio del peso), **«È un prezzo al kg»** (`riga_aPeso`:
una riga battuta a un pezzo senza offerta diventa €/kg × peso — ⚑ la strada del tastierino per i
prodotti a peso senza cartellino, F12.0 punto 4), offerte pronte (`riga_offertaNessuna`, 3x2, 2x1, −50%
2°), totale, **Salva** (`riga_salva`), **Elimina** (`riga_elimina`). ⚑ Uno sconto resta uno sconto: il
segno lo decide la riga, non il campo.

`BudgetSheet`: scorciatoie (`budget_<cents>`, default 30/50/80/100 €; 200/300/400/600 per il tetto del
mese), campo (`budget_campo`), «Usalo anche per le prossime spese» (`budget_abituale`, solo dalla spesa),
Salva (`budget_salva`), «Nessun budget» (`budget_nessuno`, se c'era). ⚑ Lo stesso foglio per il budget
della spesa, il budget abituale (Impostazioni) e il tetto del mese (Statistiche).

`sealed class EsitoRiga` — file `lib/features/spesa/riga_sheet.dart`

`RigaSalvata(riga)` o `RigaEliminata()`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const EsitoRiga()` | costruttore: i parametri sono i campi omonimi |

`final class RigaSalvata extends EsitoRiga` — file `lib/features/spesa/riga_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final RigaSpesa riga` |  |
| `()` | `const RigaSalvata(this.riga)` | costruttore: i parametri sono i campi omonimi |

`final class RigaEliminata extends EsitoRiga` — file `lib/features/spesa/riga_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const RigaEliminata()` | costruttore: i parametri sono i campi omonimi |

`class RigaSheet extends StatefulWidget` — file `lib/features/spesa/riga_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final RigaSpesa riga` |  |
| `()` | `const RigaSheet({required this.riga, super.key})` | costruttore: i parametri sono i campi omonimi |
| `show` | `static Future<EsitoRiga?> show(BuildContext context, RigaSpesa riga)` | Apre il foglio |
| `createState` | `State<RigaSheet> createState()` | crea lo stato |

`class _RigaSheetState extends State<RigaSheet>` — file `lib/features/spesa/riga_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `late RigaSpesa _riga` · `late final TextEditingController _nome` · `late final TextEditingController _prezzo` |  |
| `dispose` | `void dispose()` | libera le risorse |
| `_stampato` | `bool get _stampato` | La riga ha un totale stampato (bilancia) |
| `_risultato` | `RigaSpesa? get _risultato` | La riga coi campi applicati (prezzo valido e ≠ 0; uno sconto resta negativo); con totale stampato si modifica QUEL totale |
| `_aPeso` | `Future<void> _aPeso() async` | `PesoSheet` (senza bilancia) → quantita' `AMisura`, offerta tolta |
| `_offerta` | `void _offerta(Offerta? o)` | Imposta o toglie l'offerta |
| `build` | `Widget build(BuildContext context)` | Nome, prezzo (o totale stampato, o €/kg), quantita' ±, peso, «È un prezzo al kg», offerte pronte (3x2, 2x1, −50% 2°), totale, Salva, Elimina |

| Nome | Firma | Effetto |
|---|---|---|
| `SceltaBudget` | `typedef SceltaBudget = ({Money? budget, bool abituale});` | `({Money? budget, bool abituale})` |

`class BudgetSheet extends StatefulWidget` — file `lib/features/spesa/budget_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String titolo` · `final Money? attuale` · `final bool chiediAbituale` · `final List<int> scorciatoie` | `titolo`, `attuale`, `chiediAbituale`, `scorciatoie` in centesimi (default 30/50/80/100 €) |
| `()` | `const BudgetSheet({required this.titolo, this.attuale, this.chiediAbituale = false, this.scorciatoie = const [3000, 5000, 8000, 10000], super.key})` | costruttore: i parametri sono i campi omonimi |
| `show` | `static Future<SceltaBudget?> show(BuildContext context, {required String titolo, Money? attuale, bool chiediAbituale = false, List<int> scorciatoie = const [3000, 5000, 8000, 10000]})` | Apre il foglio (`mostraFoglio`) |
| `createState` | `State<BudgetSheet> createState()` | crea lo stato |

`class _BudgetSheetState extends State<BudgetSheet>` — file `lib/features/spesa/budget_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `late final TextEditingController _campo` · `bool _abituale` |  |
| `dispose` | `void dispose()` | libera le risorse |
| `_valore` | `Money? get _valore` | `Money.tryParse` del campo, null se ≤ 0 |
| `build` | `Widget build(BuildContext context)` | Chip delle scorciatoie (`budget_<cents>`), campo, «Usalo anche per le prossime», Salva, «Nessun budget» (se c'era) |

### 10.2 Il tastierino — `spesa/tastierino_widget.dart`

Griglia 4×4, spaziatura 6, tasti alti 48, raggio 14, Space Grotesk 20; cifre su `superficie`, × − ⌫ su
`superficieOp`, «+» su `accento`. ⚑ La stessa griglia nel foglio del peso: il pollice impara un posto solo
per ogni tasto. ⚑ **I tasti non si rimpiccioliscono mai**: altezza fissa e testo in un `FittedBox`.

`enum TipoTasto { cifra, operazione, conferma }` — file `lib/features/spesa/tastierino_widget.dart`

`class TastoGriglia` — file `lib/features/spesa/tastierino_widget.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String etichetta` · `final String semantica` · `final TipoTasto tipo` · `final VoidCallback? onTap` · `final VoidCallback? onLongPress` · `final Key? chiave` · `final IconData? icona` | `etichetta`, `semantica`, `tipo`, `onTap`, `onLongPress`, `chiave`, `icona` |
| `()` | `const TastoGriglia({required this.etichetta, required this.semantica, required this.tipo, required this.onTap, this.onLongPress, this.chiave, this.icona})` | costruttore: i parametri sono i campi omonimi |

`class GrigliaTasti extends StatelessWidget` — file `lib/features/spesa/tastierino_widget.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final List<TastoGriglia> tasti` |  |
| `()` | `const GrigliaTasti({required this.tasti, super.key})` | `assert(tasti.length == 16)` |
| `altezzaTasto` | `static const double altezzaTasto = 48` | 48 |
| `spazio` | `static const double spazio = 6` | 6 |
| `altezza` | `static const double altezza = altezzaTasto * 4 + spazio * 3` | 4 × 48 + 3 × 6 = 210 |
| `build` | `Widget build(BuildContext context)` | 4 righe × 4 tasti `Expanded` |

`class _Tasto extends StatelessWidget` — file `lib/features/spesa/tastierino_widget.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final TastoGriglia t` |  |
| `()` | `const _Tasto(this.t)` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | `Material` raggio 14 del colore del tipo, `InkWell`, alto 48, etichetta in `FittedBox` o icona |

`class PannelloTastierino extends StatelessWidget` — file `lib/features/spesa/tastierino_widget.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String etichetta` · `final String display` · `final List<TastoGriglia> tasti` |  |
| `()` | `const PannelloTastierino({required this.etichetta, required this.display, required this.tasti, super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Fondo `fondoProfondo` raggio 22: etichetta + display (Space Grotesk 24, `liveRegion`, `ValueKey('display_tastierino')`) e la griglia |

| Nome | Firma | Effetto |
|---|---|---|
| `tastiDellaSpesa` | `List<TastoGriglia> tastiDellaSpesa(L l, {required ValueChanged<TastoTastierino> onTasto, required VoidCallback onSvuota})` | I 16 tasti `7 8 9 ⌫ / 4 5 6 × / 1 2 3 − / 0 00 , +` con chiavi `tasto_<nome>`; pressione lunga su ⌫ → `onSvuota` |

### 10.3 Le azioni sulla spesa e il giro del cartellino — `spesa/azioni_spesa.dart`

⚑ Tutte le scritture dell'interfaccia sulla spesa in corso passano da `AzioniSpesa`: la spesa nasce
pigramente **col budget abituale**, e ogni riga aggiunta da' la stessa vibrazione. Tre strade che lo
fanno ognuna a modo suo finiscono per dimenticarlo in una.

Il giro (`flussoCartellino` → `gestisciRisultatoCartellino`):

| Risultato | Cosa succede |
|---|---|
| `OcrAssente` | snack `cartellino_ocrAssente` (icona tastierino) |
| `NienteLetto(forseAMano: true/false)` | snack `cartellino_forseAMano` / `cartellino_nienteLetto` |
| `LettaBilancia` | `ConfermaBilanciaSheet` → riga (Aggiungi) o mirino in modo bilancia (Riprova) |
| `LettoCartellino` con piu' proposte | prima `SceltaCartellinoSheet` («quale?») |
| proposta solo al kg (`aMisura`) | `PesoSheet` → riga `AMisura` (origine cartellino) o mirino bilancia |
| altrimenti | `ConfermaCartellinoSheet` → Aggiungi / Incrementa («Aggiungi (ora N)») / Riprova / Batti a mano (prezzo nel display) |

☠ **Mai una riga senza un tocco su Aggiungi.**

`class AzioniSpesa` — file `lib/features/spesa/azioni_spesa.dart`

Le scritture sulla spesa in corso dall'interfaccia, in un posto solo (spesa pigra col budget abituale, vibrazione)

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final WidgetRef _ref` |  |
| `()` | `AzioniSpesa(this._ref)` | costruttore: i parametri sono i campi omonimi |
| `assicura` | `Future<int> assicura()` | `assicuraInCorso(budgetPredefinito: budgetPredefinitoProvider)` |
| `aggiungi` | `Future<void> aggiungi(RigaSpesa riga) async` | `assicura()`, `aggiungiRiga`, `aptica.aggiunto()` |
| `incrementa` | `Future<void> incrementa(RigaSpesa riga, int pezzi) async` | +pezzi (1..999) a una riga a pezzi gia' presente, vibrazione |

| Nome | Firma | Effetto |
|---|---|---|
| `flussoCartellino` | `Future<void> flussoCartellino(BuildContext context, WidgetRef ref, {bool bilancia = false}) async` | `push<RisultatoCartellino>('/cartellino'` o `'?modo=bilancia')` → `gestisciRisultatoCartellino` |
| `gestisciRisultatoCartellino` | `Future<void> gestisciRisultatoCartellino(BuildContext context, WidgetRef ref, RisultatoCartellino r) async` | `OcrAssente`/`NienteLetto` → snack verso il tastierino; `LettaBilancia` → `ConfermaBilanciaSheet`; `LettoCartellino` → «quale?» se piu' proposte, foglio del peso se a misura, altrimenti `ConfermaCartellinoSheet` (aggiungi, incrementa, riprova, batti a mano). ☠ Mai una riga senza un tocco |
| `_flussoPeso` | `Future<void> _flussoPeso(BuildContext context, WidgetRef ref, {required String nome, required Money alKg, required UnitaMisura unita}) async` | `PesoSheet` → riga `AMisura` (origine cartellino) o il mirino in modo bilancia |

### 10.4 I mattoni comuni — `common/`

`una_mano.dart` (in un file solo perche' la tavola li ripete identici: una misura cambiata cambia
dappertutto), `mirino.dart`, `scelte.dart`, `pro_gate.dart`.

`class PaginaUnaMano extends StatelessWidget` — file `lib/features/common/una_mano.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String titolo` · `final Widget corpo` · `final List<Widget> azioni` · `final Widget? fondo` · `final bool indietro` |  |
| `()` | `const PaginaUnaMano({required this.titolo, required this.corpo, this.azioni = const [], this.fondo, this.indietro = true, super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | `SafeArea`: testata (indietro bordato se si puo' tornare, titolo 18/800, azioni), corpo espanso, `fondo` fuori dallo scorrimento |

`class BottoneIndietro extends StatelessWidget` — file `lib/features/common/una_mano.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final VoidCallback onTap` |  |
| `()` | `const BottoneIndietro({required this.onTap, super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | 44×44, bordo `bordo`, raggio 14, semantica «Indietro» di Material |

`class CardNumero extends StatelessWidget` — file `lib/features/common/una_mano.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String etichetta` · `final String valore` · `final Color? colore` · `final double dimensione` |  |
| `()` | `const CardNumero({required this.etichetta, required this.valore, this.colore, this.dimensione = 28, super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Card `superficie` raggio 18: etichetta e numero Space Grotesk (`FittedBox`) |

`class BarraBudget extends StatelessWidget` — file `lib/features/common/una_mano.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final double frazione` · `final Color colore` |  |
| `()` | `const BarraBudget({required this.frazione, required this.colore, super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Alta 6, raggio 3, traccia `superficieOp`, riempimento `colore` (frazione 0..1; NaN → 0; `ValueKey('barra_riempimento')`) |

`class AvvisoAmbra extends StatelessWidget` — file `lib/features/common/una_mano.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String testo` · `final IconData icona` |  |
| `()` | `const AvvisoAmbra({required this.testo, this.icona = Icons.info_outline, super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Riquadro ambra con icona e testo 700 |

`class BottoneSecondario extends StatelessWidget` — file `lib/features/common/una_mano.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String etichetta` · `final VoidCallback? onPressed` · `final IconData? icona` |  |
| `()` | `const BottoneSecondario({required this.etichetta, required this.onPressed, this.icona, super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | `OutlinedButton` alto 48, trasparente, bordo |

`class TitoloFoglio extends StatelessWidget` — file `lib/features/common/una_mano.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String testo` |  |
| `()` | `const TitoloFoglio(this.testo, {super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Titolo 18/800 del foglio (`Semantics(header)`) |

| Nome | Firma | Effetto |
|---|---|---|
| `stileTitolo` | `TextStyle stileTitolo(SrPalette p)` | 18, w800, `testo` |
| `stileEtichetta` | `TextStyle stileEtichetta(SrPalette p, {Color? colore})` | 13, w700, `testoSecondario` o `colore` |
| `mostraFoglio` | `Future<T?> mostraFoglio<T>(BuildContext context, WidgetBuilder builder)` | `showModalBottomSheet` scorrevole, con maniglia, `useSafeArea`, padding per la tastiera |

| Nome | Firma | Effetto |
|---|---|---|
| `rettangoloMirino` | `Rect rettangoloMirino(Size area, {required double larghezza, required double rapporto, double alzato = 40})` | Il mirino dentro `area`: `larghezza` × larghezza, rapporto w/h, centrato e alzato di `alzato`; altezza max 62% (si riduce tenendo il rapporto) |
| `inFrazioni` | `Rect inFrazioni(Rect r, Size area)` | Rettangolo in frazioni 0..1 dell'area |

`class PittoreMirino extends CustomPainter` — file `lib/features/common/mirino.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Rect mirino` · `final Color colore` |  |
| `()` | `const PittoreMirino({required this.mirino, required this.colore})` | costruttore: i parametri sono i campi omonimi |
| `paint` | `void paint(Canvas canvas, Size size)` | Velo nero 55% fuori dal mirino (raggio 16) e quattro angoli (tratto 5, lato 16% del lato corto, 18..40) |
| `shouldRepaint` | `bool shouldRepaint(PittoreMirino old)` | ridisegna solo se cambiano i dati |

`class ErroreFotocamera extends StatelessWidget` — file `lib/features/common/mirino.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Object errore` · `final VoidCallback onRiprova` · `final Future<void> Function() onImpostazioni` |  |
| `()` | `const ErroreFotocamera({required this.errore, required this.onRiprova, required this.onImpostazioni, super.key})` | costruttore: i parametri sono i campi omonimi |
| `negato` | `static bool negato(Object e)` | `CameraException` con codice che inizia per `CameraAccessDenied` |
| `build` | `Widget build(BuildContext context)` | `MicroEmptyState` «La fotocamera è spenta» + «Apri le impostazioni» e sotto «Riprova» (negato), o errore generico + «Riprova» |

⚑ Permesso negato: «Apri le impostazioni» (unica via d'uscita dopo un rifiuto definitivo) **e** «Riprova»
(basta dopo un rifiuto singolo su Android): non si sa quale dei due sia senza `permission_handler`, quindi
si offrono entrambe. «Da una foto» resta usabile.

`class BottoneScatto extends StatelessWidget` — file `lib/features/common/mirino.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final VoidCallback? onTap` · `final String semantica` · `final Color? colore` |  |
| `()` | `const BottoneScatto({required this.onTap, required this.semantica, this.colore, super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | 72 dp, anello bianco, centro `colore`; `Semantics(button)`; 40% di opacita' se disattivo |

`class BottoneTondo extends StatelessWidget` — file `lib/features/common/mirino.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final IconData icona` · `final String etichetta` · `final VoidCallback? onTap` |  |
| `()` | `const BottoneTondo({required this.icona, required this.etichetta, required this.onTap, super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Cerchio 48 bianco al 16% con icona e etichetta sotto (larghezza 84) |

`class SceltaNegozio extends ConsumerWidget` — file `lib/features/common/scelte.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String? valore` · `final ValueChanged<String?> onCambia` |  |
| `()` | `const SceltaNegozio({required this.valore, required this.onCambia, super.key})` | costruttore: i parametri sono i campi omonimi |
| `recenti` | `static const int recenti = 5` | 5 chip |
| `ordinati` | `static List<String> ordinati(List<Negozio> negozi, List<int?> idRecenti)` | Nomi in ordine d'uso recente (dagli id delle spese visibili), poi gli altri, senza doppioni |
| `_altro` | `Future<void> _altro(BuildContext context, List<String> tutti) async` | Dialogo «Altro…» (`_DialogoNegozio`): il nome scelto (vuoto → nessuno e snack `negozio_nessuno`) |
| `build` | `Widget build(BuildContext context, WidgetRef ref)` | Chip del valore se non fra i recenti, i 5 recenti, «Altro…» (`ValueKey('negozio_altro')`) |

⚑ Si sceglie un **nome**, non un id: il negozio dello scontrino non esiste ancora nella tabella, e crearlo
prima del salvataggio lascerebbe negozi orfani a ogni «indietro». Chi salva lo trasforma in id con
`SpesaRepository.negozioPerNome`.

`class _DialogoNegozio extends StatefulWidget` — file `lib/features/common/scelte.dart`

Campo (max 60, `ValueKey('negozio_campo')`) con fino a 8 suggerimenti filtrati

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final List<String> tutti` · `final String iniziale` |  |
| `()` | `const _DialogoNegozio({required this.tutti, required this.iniziale})` | costruttore: i parametri sono i campi omonimi |
| `createState` | `State<_DialogoNegozio> createState()` | crea lo stato |

`class _DialogoNegozioState extends State<_DialogoNegozio>` — file `lib/features/common/scelte.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `late final TextEditingController _c` |  |
| `dispose` | `void dispose()` | libera le risorse |
| `build` | `Widget build(BuildContext context)` | costruisce l'interfaccia (vedi la descrizione sopra la tabella) |

`class SceltaData extends StatelessWidget` — file `lib/features/common/scelte.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final CivilDate data` · `final ValueChanged<CivilDate> onCambia` |  |
| `()` | `const SceltaData({required this.data, required this.onCambia, super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | `OutlinedButton` con la data lunga (`yMMMMEEEEd`) → `showDatePicker` (dal 2020 a fine anno prossimo) → `CivilDate` |

`class Sezione extends StatelessWidget` — file `lib/features/common/scelte.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final String testo` |  |
| `()` | `const Sezione(this.testo, {super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Etichetta di sezione (13/700, `Semantics(header)`) |

`class ProGate extends ConsumerWidget` — file `lib/features/common/pro_gate.dart`

Il Pro controllato SULLA PAGINA: senza Pro un lucchetto con «Sblocca» (paywall con `feature` evidenziata), col Pro il `child`. ☠ Non un redirect di go_router

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final FeatureKey feature` · `final Widget child` · `final bool Function(FeatureGate gate)? allowed` |  |
| `()` | `const ProGate({required this.feature, required this.child, this.allowed, super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context, WidgetRef ref)` | `allowed?.call(gate) ?? gate.allows(feature)` |

### 10.5 Il mirino del cartellino — `cartellino/cartellino_camera_page.dart` (`/cartellino`)

Anteprima a tutto schermo, **mirino orizzontale** 86% 4:3, angoli verdi, velo nero 55%; «Inquadra un
cartellino, da vicino»; suggerimento «Lo scritto a mano non lo leggo» **una volta**
(`cartellino_suggerimento`); interruttore **Cartellino | Bilancia** (`cartellino_modo`; ⚑ serve solo a
forzare: la bilancia si riconosce da sola); torcia (`cartellino_torcia`, sparisce al primo errore), scatto
72 dp (`cartellino_scatta`), «Da una foto» (`cartellino_daFoto`); «Leggo…» (`cartellino_leggo`) sul mirino
con la fotocamera **montata**; il risultato torna con `pop(RisultatoCartellino)`.
☠ Al ritorno dalle impostazioni si riapre la fotocamera **solo** se si e' partiti da «Apri le
impostazioni» (`_attesaImpostazioni`): il dialogo del permesso stesso mette l'attivita' in pausa, e un
«riprova a ogni ripresa» lo richiederebbe in un giro senza fine (lezione di QR Me).

`enum ModoLettura { cartellino, bilancia }` — file `lib/features/cartellino/cartellino_camera_page.dart`

`class CartellinoCameraPage extends ConsumerStatefulWidget` — file `lib/features/cartellino/cartellino_camera_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final ModoLettura modoIniziale` |  |
| `()` | `const CartellinoCameraPage({this.modoIniziale = ModoLettura.cartellino, super.key})` | costruttore: i parametri sono i campi omonimi |
| `mirino` | `static Rect mirino(Size area)` | 86% della larghezza, 4:3 |
| `createState` | `ConsumerState<CartellinoCameraPage> createState()` | crea lo stato |

`class _CartellinoCameraPageState extends ConsumerState<CartellinoCameraPage>` — file `lib/features/cartellino/cartellino_camera_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `late ModoLettura _modo` · `Obiettivo? _obiettivo` · `bool _pronta` · `Object? _errore` · `bool _leggo` · `bool _torciaUsabile` · `bool _torcia` · `bool _attesaImpostazioni` · `Size? _area` · `late final AppLifecycleListener _ciclo` | modo, obiettivo, pronta, errore, «Leggo…», torcia, attesa delle impostazioni, area, ascoltatore del ciclo di vita |
| `initState` | `void initState()` | `AppLifecycleListener(onResume)`: riapre SOLO al ritorno dalle impostazioni con un errore; poi `_apri` |
| `dispose` | `void dispose()` | Chiude ascoltatore e fotocamera |
| `_apri` | `Future<void> _apri() async` | Chiude la vecchia, ne crea una dal provider, `apri()`; errore → `_errore` |
| `_torciaCambia` | `Future<void> _torciaCambia() async` | Accende/spegne; false → la torcia sparisce |
| `_suggerimentoVisto` | `void _suggerimentoVisto()` | Segna visto il suggerimento dello scritto a mano |
| `_scatta` | `Future<void> _scatta() async` | Scatto → ritaglio al mirino → `_leggi`; errore → snack `cartellino_scattoFallito` |
| `_daUnaFoto` | `Future<void> _daUnaFoto() async` | Selettore (una foto) → `_leggi`; ⚑ F12.8: errore → snack `cartellino_scattoFallito` (prima si perdeva) |
| `_leggi` | `Future<void> _leggi(String percorso) async` | `LetturaService.cartellino(forzaBilancia: modo == bilancia)` → `pop(risultato)` |
| `build` | `Widget build(BuildContext context)` | Nero: anteprima, mirino, `SegmentedButton` Cartellino/Bilancia, testo e suggerimento, «Leggo…», torcia/scatto/«Da una foto»; con errore `ErroreFotocamera` lasciando libera la fascia in basso |

### 10.6 La conferma del cartellino — `cartellino/conferma_cartellino_sheet.dart`

Nome modificabile (`conferma_nome`); **prezzo grande** (Space Grotesk 40, `conferma_prezzo`, un tocco →
campo `conferma_prezzoCampo`); barrato (`conferma_barrato`); €/kg (`conferma_alKg`); pillola dell'offerta
(`conferma_offerta`, `offertaLunga`); «Controlla il prezzo» in ambra e i chip alternativi
(`conferma_alternativa_<cents>`) se affidabilita' < 0,6 o ci sono alternative; quantita' (`conferma_meno`,
`conferma_pezzi`, `conferma_piu`; ⚑ default N con un NxM: chi guarda un 3x2 ne prende 3); **Aggiungi**
(`conferma_aggiungi`) o, con due prezzi carta, **due bottoni** `conferma_conCarta` / `conferma_senzaCarta`
(D4: ognuno e' gia' l'«Aggiungi» di quel prezzo); Riprova (`conferma_riprova`), Batti a mano
(`conferma_battiAMano`). ⚑ Prodotto gia' nella spesa (stesso nome normalizzato e prezzo) → «Aggiungi (ora
N)» incrementa la riga esistente (un 3x2 scattato tre volte fa scattare l'offerta).

`sealed class EsitoCartellino` — file `lib/features/cartellino/conferma_cartellino_sheet.dart`

`CartellinoAggiungi(riga)`, `CartellinoIncrementa(esistente, pezzi)`, `CartellinoRiprova()`, `CartellinoBattiAMano(prezzo)`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const EsitoCartellino()` | costruttore: i parametri sono i campi omonimi |

`final class CartellinoAggiungi extends EsitoCartellino` — file `lib/features/cartellino/conferma_cartellino_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final RigaSpesa riga` |  |
| `()` | `const CartellinoAggiungi(this.riga)` | costruttore: i parametri sono i campi omonimi |

`final class CartellinoIncrementa extends EsitoCartellino` — file `lib/features/cartellino/conferma_cartellino_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final RigaSpesa esistente` · `final int pezzi` |  |
| `()` | `const CartellinoIncrementa(this.esistente, this.pezzi)` | costruttore: i parametri sono i campi omonimi |

`final class CartellinoRiprova extends EsitoCartellino` — file `lib/features/cartellino/conferma_cartellino_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const CartellinoRiprova()` | costruttore: i parametri sono i campi omonimi |

`final class CartellinoBattiAMano extends EsitoCartellino` — file `lib/features/cartellino/conferma_cartellino_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Money? prezzo` |  |
| `()` | `const CartellinoBattiAMano(this.prezzo)` | costruttore: i parametri sono i campi omonimi |

`class ConfermaCartellinoSheet extends StatefulWidget` — file `lib/features/cartellino/conferma_cartellino_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final PropostaCartellino proposta` · `final List<RigaSpesa> esistenti` |  |
| `()` | `const ConfermaCartellinoSheet({required this.proposta, this.esistenti = const [], super.key})` | costruttore: i parametri sono i campi omonimi |
| `show` | `static Future<EsitoCartellino?> show(BuildContext context, {required PropostaCartellino proposta, List<RigaSpesa> esistenti = const []})` | Apre il foglio con le righe esistenti |
| `createState` | `State<ConfermaCartellinoSheet> createState()` | crea lo stato |

`class _ConfermaCartellinoSheetState extends State<ConfermaCartellinoSheet>` — file `lib/features/cartellino/conferma_cartellino_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `late final TextEditingController _nome` · `late final TextEditingController _prezzoTesto` · `Money? _prezzo` · `bool _modificaPrezzo` · `late int _pezzi` | nome, campo del prezzo, prezzo corretto, modifica in corso, pezzi (default N con NxM) |
| `dispose` | `void dispose()` | libera le risorse |
| `_prezzoEffettivo` | `Money? get _prezzoEffettivo` | Il corretto o quello della proposta |
| `_riga` | `RigaSpesa? _riga(PropostaCartellino prop, {Money? prezzo})` | La riga che si aggiungerebbe (prezzo > 0), con offerta e €/kg di riferimento |
| `_gemella` | `RigaSpesa? _gemella(RigaSpesa nuova)` | Riga gia' presente a pezzi con stesso nome normalizzato e stesso prezzo |
| `_conferma` | `void _conferma(RigaSpesa? riga)` | `pop(CartellinoAggiungi)` o `CartellinoIncrementa` se c'e' la gemella |
| `_salvaPrezzo` | `void _salvaPrezzo()` | Applica il prezzo battuto (se > 0) |
| `build` | `Widget build(BuildContext context)` | Nome; prezzo grande toccabile (o la domanda della carta); barrato; pillola dell'offerta; €/kg; «Controlla il prezzo» + chip; quantita'; due bottoni carta o Aggiungi («Aggiungi (ora N)»); Riprova, Batti a mano |

`class SceltaCartellinoSheet extends StatelessWidget` — file `lib/features/cartellino/conferma_cartellino_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final List<PropostaCartellino> proposte` |  |
| `()` | `const SceltaCartellinoSheet({required this.proposte, super.key})` | costruttore: i parametri sono i campi omonimi |
| `show` | `static Future<PropostaCartellino?> show(BuildContext context, List<PropostaCartellino> proposte)` | «Ho visto N cartellini: quale?» |
| `build` | `Widget build(BuildContext context)` | Una riga per proposta (nome, prezzo o €/kg) |

### 10.7 Il peso — `cartellino/peso_sheet.dart`

«1,48 €/kg» in alto, tastierino dei grammi (unita' g/kg commutabile `peso_unita`, «C», «00», virgola →
passa ai chili), anteprima `peso_anteprima` «0,500 kg × 1,48 = 0,74 €» (`Arrotonda.perMisura`), Aggiungi
(`peso_aggiungi`, «Aggiungi 0,74 €»), «Leggi l'etichetta della bilancia» (⚑ alla bilancia self-service il
peso esatto lo stampa l'etichetta: piu' veloce e preciso di 0,258 a mano).

`sealed class EsitoPeso` — file `lib/features/cartellino/peso_sheet.dart`

`PesoScelto(quantita)` o `PesoLeggiBilancia()`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const EsitoPeso()` | costruttore: i parametri sono i campi omonimi |

`final class PesoScelto extends EsitoPeso` — file `lib/features/cartellino/peso_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final AMisura quantita` |  |
| `()` | `const PesoScelto(this.quantita)` | costruttore: i parametri sono i campi omonimi |

`final class PesoLeggiBilancia extends EsitoPeso` — file `lib/features/cartellino/peso_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const PesoLeggiBilancia()` | costruttore: i parametri sono i campi omonimi |

`class PesoSheet extends StatefulWidget` — file `lib/features/cartellino/peso_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Money alKg` · `final UnitaMisura unita` · `final String nome` · `final int? millesimiIniziali` · `final bool mostraBilancia` |  |
| `()` | `const PesoSheet({required this.alKg, required this.unita, this.nome = '', this.millesimiIniziali, this.mostraBilancia = true, super.key})` | costruttore: i parametri sono i campi omonimi |
| `show` | `static Future<EsitoPeso?> show(BuildContext context, {required Money alKg, required UnitaMisura unita, String nome = '', int? millesimiIniziali, bool mostraBilancia = true})` | Apre il foglio |
| `createState` | `State<PesoSheet> createState()` | crea lo stato |

`class _PesoSheetState extends State<PesoSheet>` — file `lib/features/cartellino/peso_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `bool _grammi` · `String _testo` | `_grammi` (unita' piccola o grande), `_testo` battuto |
| `initState` | `void initState()` | — |
| `_millesimi` | `int? get _millesimi` | Il peso battuto in millesimi (1..99999) o null |
| `_aggiungi` | `bool _aggiungi(String c)` | Un tasto; false se rifiutato (grammi: 5 cifre, niente virgola; chili: 2 interi, 3 decimali) |
| `_cambiaUnita` | `void _cambiaUnita()` | g ↔ kg conservando il valore |
| `_conferma` | `void _conferma()` | `pop(PesoScelto(AMisura(m, unita)))` |
| `build` | `Widget build(BuildContext context)` | €/kg, anteprima «0,500 kg × 1,48 = 0,74 €», tastierino dei grammi (unita', C, 00, virgola → chili), Aggiungi, «Leggi l'etichetta della bilancia» |

### 10.8 La bilancia — `cartellino/conferma_bilancia_sheet.dart`

Totale grande (`bilancia_totale`), avviso ambra «Il conto peso × prezzo non torna: controlla» se
`!coerente`, nome, peso (`bilancia_peso`), €/kg, totale (`bilancia_totaleCampo`), Aggiungi
(`bilancia_aggiungi`), Riprova. ⚑ Il campo modificabile importante e' il **totale**: vince nel conto.
⚑ Senza peso o €/kg leggibili la riga resta `Pezzi(1)` al totale stampato: il conto e' comunque giusto.

`sealed class EsitoBilancia` — file `lib/features/cartellino/conferma_bilancia_sheet.dart`

`BilanciaAggiungi(riga)` o `BilanciaRiprova()`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const EsitoBilancia()` | costruttore: i parametri sono i campi omonimi |

`final class BilanciaAggiungi extends EsitoBilancia` — file `lib/features/cartellino/conferma_bilancia_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final RigaSpesa riga` |  |
| `()` | `const BilanciaAggiungi(this.riga)` | costruttore: i parametri sono i campi omonimi |

`final class BilanciaRiprova extends EsitoBilancia` — file `lib/features/cartellino/conferma_bilancia_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const BilanciaRiprova()` | costruttore: i parametri sono i campi omonimi |

`class ConfermaBilanciaSheet extends StatefulWidget` — file `lib/features/cartellino/conferma_bilancia_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final LetturaBilancia lettura` |  |
| `()` | `const ConfermaBilanciaSheet({required this.lettura, super.key})` | costruttore: i parametri sono i campi omonimi |
| `show` | `static Future<EsitoBilancia?> show(BuildContext context, LetturaBilancia lettura)` | Apre il foglio |
| `createState` | `State<ConfermaBilanciaSheet> createState()` | crea lo stato |

`class _ConfermaBilanciaSheetState extends State<ConfermaBilanciaSheet>` — file `lib/features/cartellino/conferma_bilancia_sheet.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `late final TextEditingController _nome` · `late final TextEditingController _peso` · `late final TextEditingController _alKg` · `late final TextEditingController _totale` |  |
| `dispose` | `void dispose()` | libera le risorse |
| `_grammi` | `static int? _grammi(String testo)` | «0,258» → 258 (max 2 interi e 3 decimali, 1..99999) |
| `_riga` | `RigaSpesa? get _riga` | Totale > 0 obbligatorio; peso e €/kg validi → `AMisura`, altrimenti `Pezzi(1)` al totale; sempre `totaleStampato` = totale, origine bilancia |
| `build` | `Widget build(BuildContext context)` | Totale grande, avviso «non torna» se `!coerente`, nome, peso, €/kg, totale, Aggiungi, Riprova |

### 10.9 Il mirino dello scontrino — `scontrino/scontrino_camera_page.dart` (`/scontrino`, Pro)

Mirino **verticale** 88% 3:5; dopo lo scatto le miniature (`scontrino_pezzo_<i>`, X per togliere) e due
bottoni **Leggi** (`scontrino_leggi`) e **Aggiungi un pezzo** (`scontrino_aggiungiPezzo`, fino a 4);
«Da una foto» (`scontrino_daFoto`) anche multipla; «Leggo…» (`scontrino_lavoro`). **Leggi** → con righe
contate il **confronto**, altrimenti la **registrazione** (`pushReplacement`, extra `ScontrinoLetto`).
☠ I pezzi non letti si cancellano all'uscita; quelli letti li cancella la lettura.
⚑ F12.7: la X delle miniature sta **dentro** la foto (`Center` + `Stack` della misura della foto): fuori
dallo `Stack` il tocco non arriva.

`class ScontrinoCameraPage extends ConsumerStatefulWidget` — file `lib/features/scontrino/scontrino_camera_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const ScontrinoCameraPage({super.key})` | costruttore: i parametri sono i campi omonimi |
| `massimoParti` | `static const int massimoParti = 4` | 4 |
| `mirino` | `static Rect mirino(Size area)` | 88% della larghezza, 3:5, alzato 60 |
| `createState` | `ConsumerState<ScontrinoCameraPage> createState()` | crea lo stato |

`class _ScontrinoCameraPageState extends ConsumerState<ScontrinoCameraPage>` — file `lib/features/scontrino/scontrino_camera_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `Obiettivo? _obiettivo` · `bool _pronta` · `Object? _errore` · `bool _lavoro` · `bool _attesaImpostazioni` · `bool _torciaUsabile` · `bool _torcia` · `Size? _area` · `final List<String> _parti` · `bool _inScatto` · `late final AppLifecycleListener _ciclo` | obiettivo, pronta, errore, lavoro, impostazioni, torcia, area, `_parti` (ritagli in ordine), `_inScatto` |
| `initState` | `void initState()` | Ascoltatore del ciclo di vita come il cartellino, poi `_apri` |
| `dispose` | `void dispose()` | Chiude e ☠ cancella i pezzi NON letti |
| `_apri` | `Future<void> _apri() async` | Come il cartellino |
| `_scatta` | `Future<void> _scatta() async` | Scatto → ritaglio → pezzo aggiunto (se la pagina e' smontata il ritaglio si cancella) |
| `_daFoto` | `Future<void> _daFoto() async` | Selettore multiplo; oltre i 4 pezzi le copie in piu' si cancellano |
| `_togli` | `void _togli(int i)` | Toglie e cancella un pezzo |
| `_leggi` | `Future<void> _leggi() async` | `LetturaService.scontrino` → niente letto: snack e torna allo scatto; con righe contate `pushReplacement('/scontrino/confronto')`, altrimenti `'/scontrino/registra'` (extra `ScontrinoLetto`); `OcrNonDisponibile` → snack `scontrino_ocrAssente`; altro → `scontrino_nienteLetto` |
| `build` | `Widget build(BuildContext context)` | Mirino verticale o miniature dei pezzi; Leggi, «Aggiungi un pezzo» (max 4) |

`class _Pezzi extends StatelessWidget` — file `lib/features/scontrino/scontrino_camera_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final List<String> parti` · `final ValueChanged<int> onTogli` |  |
| `()` | `const _Pezzi({required this.parti, required this.onTogli})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Miniature (`Image.file`, `cacheWidth: 400`) con la X dentro la foto |

### 10.10 Il confronto — `scontrino/confronto_page.dart` (`/scontrino/confronto`, Pro)

Due card «Scontrino 45,35» e «Contato 43,70»; la differenza: verde «Tutto torna» (`confronto_torna`, ✔
come **icona**, mai nel testo) o ambra «Differenza da guardare» (`confronto_differenza`) con il delta
(`confronto_delta`); avvisi (non quadra con le righe non lette; foto unite senza giunzione); le righe
sospette (`confronto_sospetta_<i>`, tocco → dettaglio) e, ripiegate, «Righe che tornano (N)»
(`confronto_tornano`); **Chiudi la spesa** (`confronto_chiudi`, fonte scontrino se quadra, altrimenti
contate) e «Rifotografa lo scontrino». ⚑ All'apertura le righe dello scontrino si **salvano** nella spesa
in corso (insieme 'scontrino', affiancate): alla chiusura si sceglie quale insieme fa fede.

`class ConfrontoPage extends ConsumerStatefulWidget` — file `lib/features/scontrino/confronto_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final ScontrinoLetto letto` |  |
| `()` | `const ConfrontoPage({required this.letto, super.key})` | costruttore: i parametri sono i campi omonimi |
| `createState` | `ConsumerState<ConfrontoPage> createState()` | crea lo stato |

`class _ConfrontoPageState extends ConsumerState<ConfrontoPage>` — file `lib/features/scontrino/confronto_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `initState` | `void initState()` | `_salva()` |
| `_salva` | `Future<void> _salva() async` | Salva le righe dello scontrino nella spesa in corso (creata se serve, col budget abituale) |
| `_dettaglio` | `void _dettaglio(RigaSospetta s)` | Dialogo con la riga contata e quella dello scontrino |
| `_nome` | `static String _nome(L l, RigaSospetta s)` | Il nome da mostrare per la riga sospetta |
| `_nota` | `static String _nota(L l, RigaSospetta s)` | La nota: prezzo diverso «cartellino X · scontrino Y», solo sullo scontrino, non sullo scontrino, forse doppia |
| `build` | `Widget build(BuildContext context)` | Due card, differenza (verde «Tutto torna» / ambra con delta), avvisi (non quadra, giunzione), sospette, «Righe che tornano (N)»; Chiudi la spesa (fonte scontrino se quadra) e Rifotografa |

### 10.11 La registrazione dallo scontrino — `scontrino/registra_scontrino_page.dart` (Pro)

Niente spesa contata: lo scontrino **e'** la spesa. Totale stampato (o somma), avvisi, negozio
(`negozioMostrato`, modificabile), data (dello scontrino o oggi), righe modificabili/eliminabili
(`registra_riga_<i>`; stornate barrate), **Salva la spesa** (`registra_salva`) → `registraDaScontrino` →
`go('/storico/<id>')`. ⚑ Il totale salvato e' quello **STAMPATO** (o la somma se manca): e' cio' che si e'
pagato, anche se si tolgono righe.

`class RegistraScontrinoPage extends ConsumerStatefulWidget` — file `lib/features/scontrino/registra_scontrino_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final ScontrinoLetto letto` |  |
| `()` | `const RegistraScontrinoPage({required this.letto, super.key})` | costruttore: i parametri sono i campi omonimi |
| `createState` | `ConsumerState<RegistraScontrinoPage> createState()` | crea lo stato |

`class _RegistraScontrinoPageState extends ConsumerState<RegistraScontrinoPage>` — file `lib/features/scontrino/registra_scontrino_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `late final LetturaScontrino _l` · `late String? _negozio` · `late CivilDate _data` · `late final List<RigaScontrino> _righe` · `bool _salvo` | lettura, negozio (`negozioMostrato`), data (dello scontrino o oggi), righe modificabili, salvataggio |
| `_somma` | `Money get _somma` | Somma delle righe correnti |
| `_modifica` | `Future<void> _modifica(int i) async` | Dialogo nome/importo (importo cambiato → quantita' e unitario tolti) |
| `_salva` | `Future<void> _salva() async` | Negozio per nome, `registraDaScontrino` (TOTALE stampato della lettura), `go('/storico/:id')` |
| `build` | `Widget build(BuildContext context)` | Totale stampato (o somma), avvisi, negozio, data, righe (scorri = elimina, stornate barrate) |

### 10.12 La chiusura — `chiusura/chiusura_page.dart` (`/chiudi`)

Totale grande (`chiusura_totale`) calcolato con la stessa regola di `SpesaRepository.chiudi`; esito del
budget (`chiusura_budget`: «Dentro il budget di 3,20» / «Sforato di 4,10»); con uno scontrino la scelta
**Salva le righe dello scontrino** (`chiusura_fonteScontrino`, default se quadra) / **contate**
(`chiusura_fonteContate`); negozio (chip + «Altro…»), data; **Salva** (`chiusura_salva`) → storico;
**Butta via** (`chiusura_buttaVia`, con conferma). Spesa vuota → «Non c'è niente da salvare»
(`chiusura_niente`). ⚑ Gratis con piu' di 5 spese chiuse: lo snack lo dice subito («le altre restano sul
telefono»).

`class ChiusuraPage extends ConsumerStatefulWidget` — file `lib/features/chiusura/chiusura_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final ChiusuraArgs args` |  |
| `()` | `const ChiusuraPage({this.args = const ChiusuraArgs(), super.key})` | costruttore: i parametri sono i campi omonimi |
| `createState` | `ConsumerState<ChiusuraPage> createState()` | crea lo stato |

`class _ChiusuraPageState extends ConsumerState<ChiusuraPage>` — file `lib/features/chiusura/chiusura_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `late FonteRighe _fonte` · `late String? _negozio` · `late CivilDate _data` · `bool _salvo` | fonte, negozio (dallo scontrino), data (dallo scontrino o oggi), salvataggio in corso |
| `_salva` | `Future<void> _salva() async` | Negozio per nome, `chiudi`, svuota il tastierino, `go('/storico')`, snack (gratis con > 5 chiuse: «le altre restano sul telefono») |
| `_buttaVia` | `Future<void> _buttaVia() async` | `scartaInCorso`, svuota il tastierino, `go('/')` |
| `build` | `Widget build(BuildContext context)` | Vuota → «Non c'è niente da salvare» (+ Butta via); altrimenti totale con la fonte scelta, esito del budget, scelta della fonte (con scontrino), negozio, data, Salva, Butta via con conferma |

### 10.13 Lo storico — `storico/storico_page.dart` (`/storico`)

Per mese («Ottobre 2026 · 4 spese · 182,40 €»); per riga giorno, negozio (o «Senza negozio»), pallino
ambra/rosso (`storico_pallino_<id>`) se il budget e' stato quasi o del tutto sforato, totale; tocco →
dettaglio (`storico_spesa_<id>`). **Gratis: le ultime 5** e in fondo la card «Le altre N spese sono sul
telefono» (`storico_nascoste`) → paywall `fullHistory`. In alto Statistiche (`storico_statistiche`, badge
PRO senza Pro → paywall). Vuoto → `storico_vuoto`.

`class StoricoPage extends ConsumerWidget` — file `lib/features/storico/storico_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const StoricoPage({super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context, WidgetRef ref)` | Spese visibili per mese («Ottobre 2026 · 4 spese · 182,40 €»), pallino ambra/rosso, card delle nascoste (gratis) → paywall, icona Statistiche (badge PRO) |

`class _RigaStorico extends StatelessWidget` — file `lib/features/storico/storico_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final Spesa spesa` · `final String? negozio` · `final String locale` |  |
| `()` | `const _RigaStorico({required this.spesa, required this.negozio, required this.locale})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Giorno, negozio (o «Senza negozio»), pallino, totale; tocco → `/storico/:id` |

### 10.14 Il dettaglio — `storico/dettaglio_spesa_page.dart` (`/storico/:id`)

Totale (`dettaglio_totale`), budget, negozio e data **modificabili**, righe dell'insieme che fa fede e
«Mostra anche le righe contate/dello scontrino» (`dettaglio_altre`), Elimina (`dettaglio_elimina`).
☠ **Una spesa nascosta non si apre senza il Pro** (`dettaglio_nascosta` + paywall): la regola la applica
la PAGINA, non la porta. ⚑ Finche' la lista delle visibili non e' arrivata non si decide (niente lucchetto
lampeggiante).

| Nome | Firma | Effetto |
|---|---|---|
| `spesaPerIdProvider` | `final spesaPerIdProvider = FutureProvider.autoDispose.family<Spesa?, int>((ref, id) => ref.watch(spesaRepositoryProvider).perId(id))` | `FutureProvider.autoDispose.family<Spesa?, int>`: `perId(id)` |

`class DettaglioSpesaPage extends ConsumerStatefulWidget` — file `lib/features/storico/dettaglio_spesa_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final int id` |  |
| `()` | `const DettaglioSpesaPage({required this.id, super.key})` | costruttore: i parametri sono i campi omonimi |
| `createState` | `ConsumerState<DettaglioSpesaPage> createState()` | crea lo stato |

`class _DettaglioSpesaPageState extends ConsumerState<DettaglioSpesaPage>` — file `lib/features/storico/dettaglio_spesa_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `bool _altre` |  |
| `_modifica` | `Future<void> _modifica(Spesa s, {String? negozio, CivilDate? data, bool togliNegozio = false}) async` | Negozio (per nome, o tolto) e data → `modificaChiusa`, poi invalida il provider |
| `_elimina` | `Future<void> _elimina() async` | Conferma distruttiva → `eliminaSpesa` → `pop` |
| `build` | `Widget build(BuildContext context)` | Gratis e spesa non fra le visibili → lucchetto + paywall (`fullHistory`); in caricamento → vuoto; assente o non chiusa → «Non trovato»; altrimenti totale, budget, negozio, data, righe dell'insieme che fa fede e «Mostra anche…» |

`class _Riga extends StatelessWidget` — file `lib/features/storico/dettaglio_spesa_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final RigaSpesa riga` |  |
| `()` | `const _Riga({required this.riga})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Nome, dettaglio, totale |

### 10.15 Le statistiche — `statistiche/` (`/statistiche`, Pro)

Mese con frecce (`statistiche_prima`, `statistiche_mese`, `statistiche_dopo`; non oltre il corrente);
**budget del mese** (`statistiche_budgetMese`, `statistiche_tetto`, `statistiche_speso`; D3, con la spesa
in corso dentro); 4 tessere (`MicroStatTile`: totale del mese, spese, media, sforamenti «su N con
budget»); grafico degli ultimi 6 mesi; tabella per negozio, mese o ultimi 12 mesi
(`statistiche_periodo`). ⚑ Legge **tutte** le chiuse (`tutteLeChiuseProvider`): chi compra il Pro dopo tre
mesi trova le statistiche gia' piene (D1). ⚑ Grafico con `CustomPainter` e non `fl_chart` (niente
dipendenze per sei barre); il disegno e' muto per i lettori di schermo, la `Semantics` legge i valori.

`class StatistichePage extends ConsumerStatefulWidget` — file `lib/features/statistiche/statistiche_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const StatistichePage({super.key})` | costruttore: i parametri sono i campi omonimi |
| `createState` | `ConsumerState<StatistichePage> createState()` | crea lo stato |

`class _StatistichePageState extends ConsumerState<StatistichePage>` — file `lib/features/statistiche/statistiche_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `late CivilDate _mese` · `bool _dodiciMesi` |  |
| `_tetto` | `Future<void> _tetto(Money? attuale) async` | `BudgetSheet` con scorciatoie 200/300/400/600 € → `budgetMensileProvider` |
| `build` | `Widget build(BuildContext context)` | Mese con frecce (non oltre il corrente), budget del mese, 4 tessere, grafico 6 mesi, tabella per negozio (mese o 12 mesi) |

`class _BudgetMese extends StatelessWidget` — file `lib/features/statistiche/statistiche_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final BudgetMese? budget` · `final VoidCallback onTetto` |  |
| `()` | `const _BudgetMese({required this.budget, required this.onTetto})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | Senza tetto «Imposta»; con: «Speso X su Y», barra, residuo/sforato |

`class GraficoMesi extends StatelessWidget` — file `lib/features/statistiche/grafico_mesi.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final List<MeseSpesa> mesi` · `final (int, int)? evidenziato` |  |
| `()` | `const GraficoMesi({required this.mesi, this.evidenziato, super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context)` | `CustomPaint` alto 160 con `Semantics` che legge i mesi («ottobre 182,40 euro») |

`class _Barre extends CustomPainter` — file `lib/features/statistiche/grafico_mesi.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final List<int> valori` · `final List<String> etichette` · `final List<bool> evidenziata` · `final Color colore` · `final Color coloreSpento` · `final Color testo` |  |
| `()` | `_Barre({required this.valori, required this.etichette, required this.evidenziata, required this.colore, required this.coloreSpento, required this.testo})` | costruttore: i parametri sono i campi omonimi |
| `paint` | `void paint(Canvas canvas, Size size)` | Barre (raggio 6, 56% del passo; evidenziata piena, le altre al 45%), etichette dei mesi, linea di base |
| `shouldRepaint` | `bool shouldRepaint(_Barre old)` | ridisegna solo se cambiano i dati |

### 10.16 Impostazioni — `impostazioni/`

`ImpostazioniPage` (`/impostazioni`): Budget abituale (`impostazioni_budget`), Vibrazione
(`impostazioni_vibrazione`), Negozi (`impostazioni_negozi`), Tema (`impostazioni_tema`: scuro/chiaro/
sistema), Pro (`impostazioni_pro`: tutta la riga risponde al tocco, lezione di TrashCan), Ripristina
acquisti, «I tuoi dati» (`dati_backup`, `dati_ripristino`, `dati_csv`), informativa, licenze, versione,
voce di sviluppo (`impostazioni_dev`, solo con la rotta). ⚑ Niente «Ho la carta fedelta'» (D4); il tetto
del mese si imposta dalle Statistiche, dove si vede. ⚑ Le voci Pro **si vedono anche senza il Pro**, col
badge: nasconderle vorrebbe dire non far sapere che esistono. ⚑ Il ripristino e' gratis. ☠ «Sostituisci
tutto» e' irreversibile: il riepilogo (spese, negozi) prima della conferma e' l'unico modo di accorgersi
del file sbagliato.

`class ImpostazioniPage extends ConsumerWidget` — file `lib/features/impostazioni/impostazioni_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final bool devAttiva` |  |
| `()` | `const ImpostazioniPage({this.devAttiva = false, super.key})` | costruttore: i parametri sono i campi omonimi |
| `_info` | `static Future<void> _info(BuildContext context, String titolo, String testo)` | Dialogo con un testo lungo (informativa) |
| `build` | `Widget build(BuildContext context, WidgetRef ref)` | Budget abituale, Vibrazione, Negozi, Tema (scuro/chiaro/sistema), Pro (stato, acquisto, ripristino), «I tuoi dati», informativa, licenze, versione, voce di sviluppo (se `devAttiva`) |

`class DataSection extends ConsumerWidget` — file `lib/features/impostazioni/data_section.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const DataSection({super.key})` | costruttore: i parametri sono i campi omonimi |
| `build` | `Widget build(BuildContext context, WidgetRef ref)` | Backup (badge PRO senza Pro), Ripristina (gratis), CSV (badge PRO) |

| Nome | Firma | Effetto |
|---|---|---|
| `creaBackup` | `Future<void> creaBackup(BuildContext context, WidgetRef ref) async` | Senza Pro → paywall `backupRestore`; con → `createBackup` (dialogo d'attesa) e `shareBackup`; errore → snack |
| `ripristinaBackup` | `Future<void> ripristinaBackup(BuildContext context, WidgetRef ref) async` | File → `inspect` (schemaId diverso → errore) → riepilogo e modo (Sostituisci tutto / Unisci) → `restore` → snack |
| `esportaCsv` | `Future<void> esportaCsv(BuildContext context, WidgetRef ref) async` | Senza Pro → paywall `csvExport`; nessuna chiusa → snack; altrimenti CSV in `exports/` e condivisione `text/csv`; errore → snack |
| `_conAttesa` | `Future<T> _conAttesa<T>(BuildContext context, String messaggio, Future<T> Function() lavoro) async` | Dialogo d'attesa non chiudibile sul navigatore radice, chiuso nel `finally` |

`class NegoziPage extends ConsumerWidget` — file `lib/features/impostazioni/negozi_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const NegoziPage({super.key})` | costruttore: i parametri sono i campi omonimi |
| `_rinomina` | `Future<void> _rinomina(BuildContext context, WidgetRef ref, Negozio n) async` | Dialogo (max 60) → `rinominaNegozio`; doppione → snack `negozi_doppione` |
| `_elimina` | `Future<void> _elimina(BuildContext context, WidgetRef ref, Negozio n) async` | Conferma → `eliminaNegozio` (le spese restano senza negozio) |
| `build` | `Widget build(BuildContext context, WidgetRef ref)` | Lista per nome (tocco = rinomina, cestino = elimina) o stato vuoto |

### 10.17 Sviluppo — `dev/ocr_dev_page.dart` (`/dev/ocr`, solo debug o `SR_DEV`)

Scatta o sceglie una foto, mostra le righe lette con i riquadri, i risultati dei tre parser, e **«Esporta
fixture»** (JSON nel formato del banco: righe e riquadri, **senza immagine**, verita' vuota da scrivere a
mano). ⚑ E' lo strumento per raccogliere le fixture di Vision dall'iPad e quelle delle foto vere del
proprietario (F12.7). ☠ La foto resta finche' si e' nella pagina e si cancella all'uscita.

`class OcrDevPage extends ConsumerStatefulWidget` — file `lib/features/dev/ocr_dev_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| `()` | `const OcrDevPage({super.key})` | costruttore: i parametri sono i campi omonimi |
| `createState` | `ConsumerState<OcrDevPage> createState()` | crea lo stato |

`enum _Tipo { cartellino, bilancia, scontrino }` — file `lib/features/dev/ocr_dev_page.dart`

`class _OcrDevPageState extends ConsumerState<OcrDevPage>` — file `lib/features/dev/ocr_dev_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `String? _foto` · `ui.Size? _dimensione` · `List<RigaOcr> _righe` · `_Tipo _tipo` · `bool _lavoro` · `String? _errore` · `Duration? _tempo` | foto, dimensioni, righe, tipo, lavoro, errore, tempo |
| `dispose` | `void dispose()` | Cancella la foto mostrata |
| `_prendi` | `Future<void> _prendi({required bool fotocamera}) async` | Fotocamera di sistema (`ImagePicker.camera`) o selettore → dimensioni → `_leggi` (la foto precedente si cancella) |
| `_leggi` | `Future<void> _leggi() async` | OCR nel modo del tipo, cronometrato |
| `_esporta` | `Future<void> _esporta() async` | JSON della fixture (campione, tipo, licenza vuota, motore, data, righe, verita' vuota) condiviso |
| `_risultati` | `String _risultati()` | Testo con le uscite dei tre parser |
| `build` | `Widget build(BuildContext context)` | Tipo, Scatta/Da una foto, foto con i riquadri, conteggio e ms, Esporta fixture, risultati, righe con confidenza |

`class _Riquadri extends CustomPainter` — file `lib/features/dev/ocr_dev_page.dart`

| Membro | Firma | Effetto |
|---|---|---|
| campi | `final List<RigaOcr> righe` · `final Color colore` |  |
| `()` | `_Riquadri(this.righe, this.colore)` | costruttore: i parametri sono i campi omonimi |
| `paint` | `void paint(Canvas canvas, Size size)` | I riquadri delle righe sulla foto |
| `shouldRepaint` | `bool shouldRepaint(_Riquadri old)` | ridisegna solo se cambiano i dati |

## 11. Cosa e' Pro e cosa e' gratis

| Funzione | Gratis | Pro | `FeatureKey` → limite | Dove si applica |
|---|---|---|---|---|
| Tastierino, totale, quantita', sconti a mano, budget della spesa | ✔ | ✔ | — | |
| Lettura dei cartellini (illimitata), peso a mano, etichetta della bilancia | ✔ | ✔ | — | |
| Spese salvate | ultime **5** visibili (le altre nascoste, D1) | tutte | `fullHistory` → `count(freeMax: 5)` | `speseChiuseProvider`, card in `StoricoPage`, lucchetto in `DettaglioSpesaPage`, snack in `ChiusuraPage` |
| **Scontrino** (confronto e registrazione) | — | ✔ | `documentScan` → `locked()` | `ProGate` su `/scontrino*`, badge e paywall su `SpesaPage` |
| **Statistiche** (+ budget del mese, D3) | — | ✔ | `statistics` → `locked()` | `ProGate` su `/statistiche`, badge in `StoricoPage` |
| **CSV** | — | ✔ | `csvExport` → `locked()` | `esportaCsv` |
| **Backup** (ripristino gratis) | — | ✔ | `backupRestore` → `locked()` | `creaBackup` (il ripristino non controlla) |
| Le altre 11 chiavi | aperte | | `open()` | (Spending Review non le vende) |

Prezzo: **2,99 €** (App Store, base Italia); Play **2,45 EUR** senza IVA. In sviluppo `BILLING=fake`:
`FakePurchaseGateway` col prezzo «2,99 €», senza Pro all'avvio. ⚑ `photos` resta `open()`: vuol dire
«allegare foto ai record», e qui nessuna foto si conserva.

## 12. Configurazione e chiavi

### 12.1 Identificativi e dart-define

| Cosa | Valore | Dove |
|---|---|---|
| `appId` | `spending_review` | `buildSrConfig` (cartelle, namespace delle preferenze, nome del log) |
| `licenseAppId` | `spendingreview` | `app_config.dart` |
| bundle / applicationId / namespace | `com.smp.spendingreview` | gradle, Xcode |
| SKU | `spendingreview_pro_lifetime` | `buildSrConfig` |
| `appVersion` | `'1.0.0'` | `entitlement.dart` (allineare a mano a `pubspec.yaml`) |
| seme del tema | `#4ADE80` | `buildSrConfig` |
| canale «impostazioni» | `com.smp.spendingreview/impostazioni`, metodo `apri` → bool | `ImpostazioniSistema`, `MainActivity.kt`, `AppDelegate.swift` |
| canale OCR | `micro_ocr` (del plugin) | `packages/micro_ocr` |
| file del database | `Documents/spending_review.sqlite` | `database.dart` |
| log | `<logs>/spending_review.log` (`AppPaths`, `Library/Application Support/spending_review/logs` su iOS) | `main.dart` |
| entitlement | `<support>/entitlement.json` | `EntitlementNotifier` |
| export CSV | `<exports>/spending-review-AAAA-MM-GG.csv` | `esportaCsv` |

| dart-define / variabile | Default | Significato |
|---|---|---|
| `BILLING` | (store) | `fake` → `FakePurchaseGateway` a 2,99 €; ☠ vietato in release (`assertUsableInRelease`) |
| `MA_LICENSE_URL`, `MA_APP_SECRET` | assenti | server licenze acceso solo se entrambi (come le altre app su Android) |
| `SR_DEV` | `false` | `true` → `/dev/ocr` e la voce in Impostazioni anche fuori da debug; ☠ in release `main` lancia `StateError` |
| `SR_DEMO` | `false` | `true` → `seedDemoData` in `main` (database vuoto: storico, spesa in corso, budget); ☠ ignorato in release (`demoEnabled`) |
| `LINGUA` (dart-define dei giri dello store) | `it` | lingua di `screenshots_test.dart` e `anteprima_test.dart` |
| `SR_FOTO` (dart-define del test d'integrazione) | assente | cartella delle foto dei campioni fuori dal repo; senza, `flussi_test.dart` salta |
| `SR_CAMPIONI` (variabile d'ambiente del banco) | assente | cartella con `ppocrv5/`, `ppocrv5-mirino/` … delle 27 fixture private (es. `E:/coding/XAMPP/htdocs/microapps-campioni/f12/fixture`) |

### 12.2 Preferenze (`SettingsStore`, namespace `spending_review`)

| Chiave | Tipo | Default | Chi |
|---|---|---|---|
| `SrSettingKeys.budgetPredefinito` = `budget_predefinito` | int centesimi | assente | `budgetPredefinitoProvider` (Impostazioni, «usalo anche per le prossime») |
| `SrSettingKeys.budgetMensile` = `budget_mensile` | int centesimi | assente | `budgetMensileProvider` (Statistiche, D3) |
| `SrSettingKeys.vibrazione` = `vibrazione` | bool | `true` | `vibrazioneProvider` |
| `SrSettingKeys.suggerimentoMirinoVisto` = `suggerimento_mirino_visto` | bool | `false` | `suggerimentoMirinoVistoProvider` |
| `SettingKeys.themeMode` (micro_core) | string `dark`/`light`/`system` | scuro | `ThemeModeNotifier` |
| `SettingKeys.launchCount`, `SettingKeys.firstLaunchAt` (micro_core) | int, instant | 0, assente | `_recordLaunch` |

⚑ **Niente `preferisciPrezzoCarta`** (D4) e niente «Ho la carta». ☠ Le preferenze non entrano nel backup e
non sono escluse da iCloud (§15.2).

### 12.3 Permessi

| Piattaforma | Permesso | Quando | Note |
|---|---|---|---|
| Android | `CAMERA` | primo tocco su Cartellino o Scontrino (lo chiede `camera`) | |
| Android | `com.android.vending.BILLING` | — | Play Console lo vuole nel pacchetto per creare il prodotto |
| Android | `INTERNET`, `ACCESS_NETWORK_STATE` | — | **solo** da Play Billing (`com.google.android.datatransport`), `ACCESS_NETWORK_STATE` anche da `androidx.media3` (camerax); controllati da `verificaPrivacyOcr` |
| Android | tolti: `RECORD_AUDIO`, `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, `POST_NOTIFICATIONS` | | `tools:node="remove"` |
| iOS | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` | fotocamera; «Da una foto» | niente microfono |

### 12.4 Testi

283 chiavi in `lib/l10n/app_{en,it}.arb`, generate da `tool/testi.py` + `tool/testi_schermate.py`
(`python apps/spending_review/tool/testi.py`, poi `pwsh ../../tool/fl.ps1 gen-l10n` o una build).
Template inglese (ripiego), `untranslated.json` vuoto. Classi generate da `gen_l10n` in
`lib/l10n/generated/` (non si modificano a mano): `L` (astratta, `L.of(context)`, `L.delegate`), `LEn` e
`LIt` (le due lingue). Virgolette tipografiche anche in inglese; ☠ nessun
glifo ✓ ⚠ ✗ (guardia `texts_glyphs_test.dart`). Famiglie di chiavi: `appTitle`, `common_*`, `paywall_*`,
`settings_*`, `theme_*`, `spesa_*`, `tasto_*`, `semantica_*`, `riga_*`, `offerta_*`, `budget_*`,
`cartellino_*`, `bilancia_*`, `peso_*`, `fotocamera_*`, `scontrino_*`, `confronto_*`, `registra_*`,
`chiusura_*`, `negozio_*`, `negozi_*`, `storico_*`, `dettaglio_*`, `statistiche_*`, `grafico_*`,
`impostazioni_*`, `dati_*`, `backup_*`, `csv_*`, `origine_*`, `pro_*`, `dev_*`.

### 12.5 Dipendenze proprie (oltre a `micro_core` e `micro_ocr`)

| Pacchetto | Perche' | Note |
|---|---|---|
| `camera ^0.12.1` | anteprima col NOSTRO mirino e `takePicture()` | ☠ camerax dichiara microfono e storage: tolti dal manifest; ⚑ non `image_picker` per lo scatto (serve il mirino) |
| `image_picker ^1.2.4` | «Da una foto» (selettore di sistema, nessun permesso su Android 13+/iOS) | copie temporanee, cancellate dopo la lettura |
| `image ^4.10.1` | ritaglio al mirino in un isolate (Dart puro) | |
| `drift ^2.35.2`, `sqlite3 ^3.7.0`, `sqlite3_flutter_libs` | database | dev: `drift_dev`, `build_runner`, ☠ `analyzer >=14.0.0 <14.4.0` (la 14.5 rompe la generazione) |
| `flutter_riverpod ^3.4.3`, `go_router ^18.0.2` | stato e rotte | |
| `share_plus ^13.3.0` | CSV e backup, esporta fixture | stesso vincolo di micro_core |
| `intl`, `meta`, `path`, `path_provider`, `cupertino_icons`, `flutter_localizations` | | |
| dev: `integration_test`, `flutter_launcher_icons`, `flutter_native_splash`, `shared_preferences` (mock nei test) | | |

⚑ **Non si usano** (F12.1.2): `flutter_onnxruntime` (porterebbe ORT anche su iPhone), `google_mlkit_*`,
`tflite_flutter`/LiteRT 2.x, `flutter_tesseract_ocr`, `mobile_scanner`, `home_widget`,
`permission_handler`, `url_launcher`, `speech_to_text`, `fl_chart`. ☠ Prima di aggiungere una dipendenza
nativa: controllarne le dipendenze Android/iOS (Firebase, `datatransport` fuori da Billing,
`play-services-*`, ML Kit, SDK di crash o analisi). Una dipendenza nuova si aggiunge con `pwsh
../../tool/fl.ps1 pub add <pacchetto>`, mai a memoria.

### 12.6 Comandi (da `apps/spending_review`)

```
pwsh ../../tool/fl.ps1 analyze
pwsh ../../tool/fl.ps1 test                                   # 341 esiti (339 verdi + 2 saltati)
$env:SR_CAMPIONI='E:/coding/XAMPP/htdocs/microapps-campioni/f12/fixture'; pwsh ../../tool/fl.ps1 test test/domain/banco_parser_test.dart   # anche le 27 private
pwsh ../../tool/fl.ps1 test integration_test/flussi_test.dart -d <dispositivo> --dart-define=SR_FOTO=<cartella>
pwsh ../../tool/fl.ps1 run -d <dispositivo> --dart-define=BILLING=fake
pwsh ../../tool/fl.ps1 build apk --release                     # verificaPrivacyOcr gira da sola
pwsh ../../packages/micro_ocr/tool/verifica_privacy_android.ps1 -Apk build/app/outputs/flutter-apk/app-release.apk
pwsh ../../tool/fl.ps1 pub run build_runner build              # dopo una modifica a tables.dart/database.dart
python tool/testi.py                                           # dopo una modifica ai testi
pwsh ../../tool/verify_atlas.ps1 -Project apps/spending_review # questo atlante
pwsh ../../tool/fl.ps1 run -d <dispositivo> --dart-define=SR_DEMO=true   # con i dati d'esempio (solo debug)
python tool/genera_grafiche_store.py                          # grafiche degli store (§2bis, con gli altri comandi dello store)
```

## 13. Catalogo dei test

**341 esiti al 2026-10-10 (F12.8): 339 verdi + 2 saltati** (il test «sempre giusti» salta di proposito sui
motori `vision-sim` e `vision-sim-mirino`). Il numero fra parentesi e' quello degli esiti (i test dentro
cicli contano una volta per giro).

### 13.1 Dominio (`test/domain/`)

| File | Cosa dimostra |
|---|---|
| `arrotonda_test.dart` (20) | half-up e non bancario; negativi simmetrici; divisore dispari (1,5 → 2); le 9 etichette della bilancia dei campioni (peso × €/kg = totale stampato) e le 4 righe pesate di s03 (0,945 → 0,95); lo SCONTO arrotondato (c29, c30, c28) |
| `offerta_test.dart` (9) | NxM 3x2, 3x1 a 3,19 (3 pezzi = 3,19, non 3,18), 2x1; percentuale −40% su 1,98 → 1,19; barrato e carta informative; secondo −50% su 3,00 × 3 = 7,50; JSON andata e ritorno, tollerante, numeri double interi accettati |
| `riga_spesa_test.dart` (7) | totale a pezzi, a misura half-up, con NxM, a misura (NxM ignorata, percentuale applicata all'importo pesato), totale stampato che vince, sconto negativo, `copyWith` (null lascia, `togli*` toglie) |
| `spesa_test.dart` (5) | totale per fonte (contate, scontrino stampato, somma scontrino); totale salvato che vince; articoli (pezzi + 1 per misura, sconti esclusi); bordi 79,99% / 80% / 100% / 100,01%; senza budget |
| `tastierino_test.dart` (31) | la tabella di §4.6 tasto per tasto (cifre da destra, `00`, virgola e 2 decimali, massimo, × quantita'/prezzo, segno, ⌫, svuota, + rifiutato…) e le sequenze complete; `daPrezzo` |
| `nomi_test.dart` (15) | normalizza (accenti, punteggiatura, formati); formato (200 g, GR.600, LT 1, 6x180 ml, 50 cl, 0,5 L, 1,5 kg); similarita' (abbreviazioni, troncature, una parola non vale il nome intero) |
| `numeri_ocr_test.dart` (14) | `pulisci` (O/I/S solo fra cifre, «16..50», spazi, € ed EUR, «AILC.12,80» → spazio ma «GR.600» resta); espliciti (virgola e punto, migliaia, negativi davanti e dietro, pesi, non dentro numeri piu' lunghi, riquadro proporzionale); spezzati (trovato; troppo grandi/lontani/bassi → no); fusi (alto ≥ 1,5 mediana si', basso no) |
| `unisci_parti_test.dart` (5) | giunzione trovata (3 righe non contate due volte); coordinate impilate; giunzione non trovata segnalata; k = 1 non basta; parte singola |
| `cartellino_parser_test.dart` (35) | i casi dei campioni (c01 3x1 anziche', c11 2+1, c14/c16/c19/c20 formato e €/kg o €/l, c22 due cartellini, c26 migliaia, c28/c29/c30/c33 percentuali e barrati, c02/c03 a misura, c23 «0%», c04 scritto a mano → vuota), carta fedelta' (entrambi marcati; scelta con e senza), rumore scartato, e i casi F12.7 dei ritagli del mirino e di Vision (separatore di c11, «/ k9» e «ol ku», «AILC.12,80», «Alkg» + «2», «1/kg», c33 dinamico, «SCONTO 40», «40» isolato no, bollino senza prezzo, «0.99-», «(23%», «3*1», meno davanti resta sconto, nome sotto il prezzo, cirillico, «819/Кg») |
| `bilancia_parser_test.dart` (17) | le 9 verita' delle etichette dei campioni; tara ignorata; ricerca combinatoria senza parole chiave; due etichette sovrapposte (b06); «258 g»; totale incoerente (`coerente` false, totale tenuto); `riconosce`; niente importi → null; nome = scritta piu' grande (F12.7) |
| `scontrino_parser_test.dart` (19) | s01 (IVA tolta, pesata attaccata), Vision su s01 (totale senza importo), asterischi in coda, `negozioMostrato` senza punto, s03 pesate senza «kg x», s06 sconto, s07 quantita' su riga sua, quantita' in attesa, s10 reparti, s11 quantita' in testa, s16 storno, ☠ piede del pagamento mai nelle righe (s13), data (formato breve; 2031 e 2024 → null; ⚑ **F12.8**: una data non plausibile si salta e vale la successiva), non quadra, vecchio formato, totale corretto da subtotale e contanti − resto (s02), totale ricavato senza TOTALE |
| `scontrino_subtotale_test.dart` (1) | «T*talE PARZIALE» (OCR, F12.4) non diventa un articolo |
| `confronto_test.dart` (8) | abbinamento per importo e nome; quantita' contata vs riga dello scontrino; sconto sommato all'articolo; `ForseDoppia`; registrazione pura (tutte `SoloSulloScontrino`); `NonSulloScontrino` con delta negativo; stornata non conta; senza TOTALE la somma |
| `statistiche_test.dart` (11) | mese (totale, spese, media, sforamenti); totale salvato; mese vuoto (media null); 6 mesi anche vuoti e a cavallo d'anno; per negozio (ordine, «Senza negozio» in fondo, media intera, negozio eliminato); riepilogo; spese in corso escluse; budget del mese con la spesa in corso |
| `banco_parser_test.dart` (17) | il banco (§13.2): per ognuno dei 4 motori «nessun dato di carta», «il cricchetto», «sempre giusti» (solo `ppocrv5*`), «≤ 20 ms»; piu' «fixture private» |
| `righe_finte.dart` | non un test: `r(testo, x, y, w, h, {c})` e `rigaScontrino(n, sinistra, [destra])` per costruire `RigaOcr` a mano |

### 13.2 Il banco del parser (`banco_parser_test.dart` + `test/fixtures/ocr/`)

- **Fixture** = solo il TESTO OCR (righe, riquadri, confidenza) e la **verita'** trascritta, **mai le
  immagini**: deterministico, in millisecondi, senza motore ne' dispositivo. Le immagini e le 27 fixture
  a licenza non libera stanno **fuori dal repo** (`microapps-campioni/f12/`); `LICENZE.md` elenca autore,
  licenza e fonte delle 33 libere (Wikimedia Commons, Flickr).
- **Motori** = sottocartelle, ognuna col suo cricchetto:

| Motore | Cosa | Nel repo | Generate da |
|---|---|---|---|
| `ppocrv5` | foto INTERE (spesso larghe, piu' cartellini) lette da RapidOCR 3.10 (PP-OCRv5 mobile latin, cls acceso) | 33 (cartellini, bilance, scontrini) | `tool/esporta_fixture_ocr.py <cartella> --licenze-libere … --altre …` |
| `ppocrv5-mirino` | un RITAGLIO per cartellino come lo fa il mirino (4:3, coordinate a mano in `ritagli_mirino.json`; esclusi i 7 scritti a mano) — ⚑ **il riferimento** del parser del cartellino | 20 (`<nome>_r<k>.json`) | `… --ritagli ritagli_mirino.json` (ritaglio in memoria) |
| `vision-sim` | le stesse foto intere lette da **Vision** sul simulatore iPhone 18 Pro Max | 33 | `… --log <log con MICRO_OCR\|<json>> --motore vision-sim` (dall'esempio di micro_ocr) |
| `vision-sim-mirino` | i ritagli letti da Vision sul simulatore | 20 | `… --log … --motore vision-sim-mirino` |

- **Cricchetto** (`soglie.json`): per motore e campo, il numero di casi giusti dell'ultima versione
  accettata. Il test **fallisce se un numero scende** e stampa «aggiorna soglie.json: …» se sale (si
  aggiorna a mano, nello stesso commit). ⚑ Un cricchetto e non una soglia inventata: le soglie di
  f12-ocr.md §6.3 valgono sulle foto vere col mirino, non su queste.

| Campo | `ppocrv5` | `ppocrv5-mirino` | `vision-sim` | `vision-sim-mirino` |
|---|---|---|---|---|
| `cartellino.prezzo` | 13 | 11 | 10 | 9 |
| `cartellino.prezzo_pieno` | 3 | 3 | 2 | 2 |
| `cartellino.al_kg` | 4 | 5 | 3 | 5 |
| `cartellino.offerta` | 2 | 3 | 3 | 3 |
| `cartellino.nome` | 4 | 8 | 5 | 10 |
| `bilancia.totale` / `peso_kg` / `al_kg` / `prodotto` | 2 / 2 / 2 / 1 | — | 1 / 1 / 1 / 1 | — |
| `scontrino.totale` / `negozio` / `righe` | 15 / 6 / 12 | — | 13 / 4 / 12 | — |

- **Metriche**: prezzo «preso» se la PRIMA proposta lo ha (con piu' cartellini nella verita', una
  qualunque; con NxM vale anche l'effettivo); `nome` largo (meta' delle parole di 4+ lettere); negozio
  con similarita' ≥ 0,8 o parole iniziali; righe dello scontrino ±1; `oggi` fisso (2026-10-12), la data
  dello scontrino non si misura.
- **Sempre giusti** (solo `ppocrv5*`): totali di bilance e scontrini al 100% (RapidOCR li legge tutti).
- **Tempi**: ogni parser < 20 ms per foto (dopo un giro a vuoto per la JIT; misurato max 4,8 ms).
- **Nessun dato di carta**: nessuna riga con `(\*{4}\|[xX]{4,})\d{4}` (asterischi di RapidOCR, «x» di
  Vision, s13).
- **Sui 60 con le private** (`SR_CAMPIONI`): numeri stampati, senza cricchetto. Al 2026-10-10 (F12.7):
  ritagli 47 prezzo 36/40, al kg 19/22, offerte 9/10, pieno 6/6, nome 25/39; foto larghe prezzo 33/45,
  al kg 17/27, offerte 8/10; totale scontrino 16/16, bilancia 9/9 (PP-OCRv5). Vision: ritagli prezzo
  33/40, foto intere 31/45, totale scontrino 14/16, bilancia 7/9.

### 13.3 Dati e servizi

| File | Cosa dimostra |
|---|---|
| `data/spesa_repository_test.dart` (19, `SpendingDatabase.memory()`) | una sola spesa in corso (anche con due chiamate concorrenti; l'indice unico la impone anche a mano); righe (spesa pigra, totale scritto, `aggiornaRiga` ricalcola, elimina + ripristina con id e posizione, `incrementaUltima` e i suoi rifiuti, i CHECK lanciano); budget; chiusura (totale non piu' ricalcolato; senza spesa `StateError`; righe dello scontrino affiancate e fonte scontrino; `registraDaScontrino`; `scartaInCorso`; **spese oltre le 5 CONSERVATE**, D1; cascata); negozi (NOCASE, SET NULL, rinomina e ordine) |
| `data/backup_test.dart` (6) | counts e nessuna immagine; `replaceAll` identico (anche la spesa in corso e i totali); merge (negozi per nome, spesa in corso del file → chiusa; senza righe → scartata); ☠ file rotto: database intatto anche con `replaceAll`; ⚑ **F12.8**: un campo di testo di tipo sbagliato (`dataSpesa`, `unita`) e' una `FormatException`, non un `TypeError` |
| `services/csv_export_test.dart` (5) | BOM e 12 colonne; una riga per riga, virgola, peso a 3 decimali, offerta breve; fonte scontrino → righe dello scontrino; spesa senza righe esce; nome del file |
| `services/fotocamera_test.dart` (6) | `rettangoloNellaFoto` (stesso rapporto, foto 3:4 su schermo piu' alto, margine dentro la foto, mirino del cartellino); `ritagliaAlMirino` scrive il JPEG e cancella l'originale; ☠ foto illeggibile: errore ma originale cancellato |
| `services/lettura_service_test.dart` (12) | cartellino → `LettoCartellino` e foto sparita; bilancia forzata senza importi → cartellino; `NienteLetto` con e senza «forse a mano»; motore assente → `OcrAssente` e foto sparita; errore inatteso passa ma la foto sparisce; ☠ originale fuori dalle temporanee mai toccato; scontrino in modo scontrino, in ordine, foto sparite; motore assente → `OcrNonDisponibile` e foto sparite; giunzioni mancanti |

### 13.4 Widget (`test/widget/`, con `sr_test_harness.dart`)

| File | Cosa dimostra |
|---|---|
| `spesa_page_test.dart` (16) | «2 4 9 +» = 2,49 col display prima del +; quantita'; sconto; rifiuto vibra; residuo verde e barra; colore della barra alle soglie; vibrazione alla soglia una volta; scorri = elimina, «Annulla» rimette; Scontrino senza Pro → paywall, col Pro → mirino; banner della spesa vecchia; **al 130% coi font veri nessun tasto tagliato** (piu' misure di telefono) |
| `cartellino_camera_test.dart` (7) | scatto → foglio di conferma e scatto cancellato; suggerimento la prima volta e non dopo; permesso negato («Apri le impostazioni», «Riprova», «Da una foto»); «Da una foto» legge e cancella la copia; ⚑ **F12.8**: errore inatteso del motore da «Da una foto» → snack, nessun foglio, copia cancellata |
| `conferma_cartellino_test.dart` (12) | ☠ niente si aggiunge senza Aggiungi (nemmeno chiudendo il foglio); «Controlla il prezzo» e chip; NxM → quantita' N; prodotto gia' presente → «Aggiungi (ora N)»; «quale?»; carta (due bottoni, con e senza); solo al kg → foglio del peso (500 g × 1,48 = 0,74); «Batti a mano» nel display; OCR assente → messaggio |
| `confronto_page_test.dart` (5) | differenza +1,65 in ambra con prezzo diverso e riga solo sullo scontrino; «Tutto torna»; giunzione mancante; Chiudi → chiusura con la fonte; ☠ senza Pro anche con push diretto: lucchetto |
| `chiusura_page_test.dart` (3) | totale, «Dentro il budget di 3,20», negozio, Salva → storico; snack del gratis oltre le 5; spesa vuota → «Non c'è niente da salvare» |
| `storico_page_test.dart` (6) | gratis: 5 + card delle altre 2 + pallino; card → paywall; Pro: tutte e 7; ☠ link diretto a una nascosta → lucchetto; visibile si apre; id non numerico → «Non trovato» |
| `pro_gate_test.dart` (7) | per `/scontrino` e `/statistiche`: senza Pro lucchetto e paywall, col Pro la pagina; Statistiche dallo storico col badge → paywall; budget del mese impostato e mostrato |
| `dev_route_test.dart` (4) | `rottaDevAttiva`; con debug e SR_DEV falsi `/dev/ocr` → «Non trovato» e nessuna voce in Impostazioni; con la rotta la pagina si apre |
| `palette_contrast_test.dart` (11) | formula del contrasto; per tema: testi ≥ 4,5 su fondi e superfici; testo sui verdi ≥ 4,5; rosso e ambra ≥ 3 |
| `paywall_config_test.dart` (6) | ogni chiave bloccata ha il suo beneficio e viceversa; 5 righe in ordine; tutte le chiavi presenti; 5 spese visibili; Scontrino/statistiche/CSV/backup Pro; nient'altro bloccato |
| `texts_glyphs_test.dart` (2) | nessun ✓ ⚠ ✗ negli ARB, it ed en |

**Impianto** (`sr_test_harness.dart`): ☠ repository **finto in memoria** (`FakeSpesaRepository`, stesse
regole) e non Drift: dentro `testWidgets` FakeAsync congela l'I/O di SQLite e gli stream non arrivano mai
(lezione di TrashCan); che le scritture vere funzionino lo dimostra `spesa_repository_test.dart`.
`pumpSr(tester, {page, initialLocation, devAttiva, pro, chiaro, inCorso, chiuse, negozi, righeOcr,
erroreOcr, erroreFotocamera, foto, settingsValues, extra})` monta l'app vera (router, temi, l10n) con:
`FakeOcrEngine(righe, errore)`, `ObiettivoFinto` (anteprima `anteprima_finta`, scatti in una cartella
temporanea), ritaglio finto, selettore che restituisce `foto`, `ImpostazioniFinte` (conta le aperture),
`ApticaRegistrata` (registra «tasto/rifiuto/soglia/aggiunto»), `FakeEntitlementNotifier` (Pro finto),
`oraProvider` = `kOra` (2026-10-10 10:30), preferenze su `SharedPreferences.setMockInitialValues`
(namespace `sr_test`). Altre funzioni: `caricaFontVeri()` (Space Grotesk e Plus Jakarta Sans veri per le
misure al 130%), `telefono(tester, {larghezza, altezza, scala})`, `zittisciPiattaforma()`,
`spesaChiusa(...)`, `rigaTastierino(cents, {pezzi, nome, id})`.

### 13.5 Sul dispositivo (`integration_test/`: `flussi_test.dart`, piu' i due giri dello store)

OCR **vero** (Vision su iOS, PP-OCRv5 su Android), database vero, foto dei campioni da `SR_FOTO` (fuori
dal repo; senza, il test **salta**): cartellino dalla galleria 3,59 → bilancia 7,71 (totale 11,30) →
scontrino Emme Piu' 6,15 col Pro finto → confronto → chiusura → storico; le copie temporanee spariscono.
Sostituito solo il selettore di sistema. Fra un passo e l'altro stampa `SR_PASSO|<nome>` e aspetta 3 s
(screenshot). ⚑ `screenshots_test.dart` e `anteprima_test.dart` non sono prove: producono scatti e video
per gli store (§2bis) e dimostrano solo che il giro arriva in fondo; servono il simulatore e `SR_DEMO`.
Tempi misurati (F12.7): simulatore iOS 0,54 / 0,96 / 0,45 s; emulatore Android 0,95 /
0,99 / 1,14 s. ☠ Lanciarlo **installa al posto dell'app una build col test come `main`** (trappola §14.2).

## 14. Regole non negoziabili e trappole gia' disinnescate

### 14.1 Regole non negoziabili

1. ☠ **Dati solo sul telefono** (regola di tutte le microapp, 2026-10-09): nessun SDK che manda dati a
   terzi, nemmeno metriche. Unica eccezione: Play Billing + server licenze per il Pro. Cambiarla richiede
   un motivo «importantissimo» scritto dal proprietario.
2. ☠ **ONNX Runtime solo 1.28.0** (dalla 1.29: `TelemetryInitializer`, `INTERNET`, invio a
   `mobile.events.data.microsoft.com`). `privacy_ocr.gradle` fa fallire la release se cambia; un'altra
   versione richiede una voce nuova in `memory/decisioni.md`.
3. ☠ **Un cartellino letto non si aggiunge mai da solo**: serve il tocco su Aggiungi (o su uno dei due
   bottoni della carta). L'affidabilita' decide solo cosa evidenziare.
4. ☠ **Foto cancellate dopo la lettura**, sempre (`finally`); **testo OCR grezzo mai salvato**; nessuna
   colonna per foto o testo; il piede dello scontrino (carta) non esce dal parser.
5. **Totali scritti e mai ricalcolati** (riga alla scrittura, spesa alla chiusura).
6. **Spese oltre le 5 nascoste, MAI cancellate** (D1): il limite lo applica la lettura.
7. **Pro controllato sulla pagina** (`ProGate`, lucchetto del dettaglio), mai solo sulla porta; mai un
   `redirect` di go_router.
8. **Arrotondamenti half-up in interi**; sconto percentuale arrotondato prima di sottrarlo; offerte NxM al
   prezzo **PIENO** nella riga.
9. **Il totale stampato vince** (bilancia, righe dello scontrino).
10. **Ogni chiave di `FeatureKey` in `srFeatureLimits`**, ogni chiave limitata nel paywall
    (`paywall_config_test.dart`).
11. **Nessun glifo ✓ ⚠ ✗ nei testi**, virgolette tipografiche, testi solo da `tool/testi*.py`.
12. **Il tastierino non si rimpicciolisce mai**; il totale non segue la scala del testo.
13. **Il cricchetto del banco non scende** (`soglie.json`): un peggioramento del parser fa fallire i test.
14. **`/dev/ocr` non esiste in release**; una release con `SR_DEV=true` o `BILLING=fake` non parte.

### 14.2 Trappole, con la causa tecnica

| Trappola | Causa | Difesa |
|---|---|---|
| **APK di debug avviato da solo fermo sullo splash** (osservato in F12.7, chiarito in F12.8) | **Non e' un difetto dell'app.** Due cause, entrambe riprodotte sull'emulatore il 2026-10-10: (a) l'app installata e' la build di un **test d'integrazione** (`flutter test integration_test/flussi_test.dart -d …` installa `com.smp.spendingreview` con il TEST come entrypoint e **sovrascrive anche** `build/app/outputs/flutter-apk/app-debug.apk`): senza `SR_FOTO` il test esce prima di montare l'app, `runApp` non viene mai chiamato e lo splash nativo resta per sempre, anche avviandola dal launcher con un intent pulito; (b) l'attivita' e' stata avviata con l'extra `--ez start-paused true` (come fanno `flutter drive`, `flutter run --start-paused`, i debugger): la VM resta in pausa in attesa del debugger, e **il task conserva l'intent radice con l'extra**, quindi anche l'icona del launcher dopo che il processo e' morto (`am kill`) riapre l'app in pausa. Verificato che l'APK di debug vero, installato da `flutter build apk --debug`, si avvia da solo (a freddo, 5 volte, anche con dati) come QR Me debug | (a) dopo un test d'integrazione rifare `pwsh ../../tool/fl.ps1 build apk --debug` (o `flutter run`) prima di provare a mano; (b) `adb shell am force-stop com.smp.spendingreview` (o togliere l'app dalle recenti) e riaprirla dal launcher. Per le prove a mano basta il debug vero; la release resta il riferimento per i tempi |
| ONNX Runtime con telemetria | dalla 1.29 | `strictly("1.28.0")` in micro_ocr + `verificaPrivacyOcr` |
| «1DS» nel `.so` ARMv7 di ORT | byte del codice macchina Thumb, non una stringa: falso positivo della guardia sul binario | stringhe corte contate solo dentro stringhe stampabili di 8+ caratteri (micro_ocr §8) |
| `INTERNET` nel manifest unito | lo porta Play Billing (`datatransport`); `ACCESS_NETWORK_STATE` anche `androidx.media3` via camerax | la guardia guarda CHI lo porta (report di fusione), non se c'e' |
| Lo script condiviso ammetteva solo `transport-backend-cct` | Billing porta anche `transport-runtime` | allineato in F12.4 a tutto il gruppo `com.google.android.datatransport` |
| `.gradle.kts` applicato con `apply(from)` | crash di `lintVitalAnalyzeRelease` (AGP 9.1) | guardia in Groovy |
| camerax dichiara `RECORD_AUDIO`, `WRITE_EXTERNAL_STORAGE` (e implicito `READ_…`) | servono a chi registra video | `tools:node="remove"`; fotocamera con `enableAudio: false` |
| `POST_NOTIFICATIONS` senza notifiche | lo porta `flutter_local_notifications` di micro_core | `tools:node="remove"` |
| Chiavi esterne di SQLite spente | default di SQLite, per connessione | `PRAGMA foreign_keys = ON` in `beforeOpen` |
| «unable to open database file» solo sul telefono | temporanea di sistema non scrivibile su Android | `sqlite3.tempDirectory` |
| Stream di Drift che non arrivano nei test di widget | FakeAsync congela l'I/O di SQLite | `FakeSpesaRepository` in memoria |
| `analyzer` 14.5 | rompe la generazione di Drift | `analyzer: ">=14.0.0 <14.4.0"` |
| Arrotondamento bancario | `0,945` → 0,94 invece della cassa 0,95 | `Arrotonda.mezzoInSu` in interi |
| `Money * double` sui pesi | virgola mobile | millesimi interi + `perMisura` |
| Offerte calcolate sul prezzo effettivo | 3 × 1,06 = 3,18 ≠ 3,19 della cassa | prezzo PIENO nella riga NxM |
| «T*talE PARZIALE» (F12.4, s06 sull'emulatore) | un carattere letto male: il subtotale diventava un articolo | `t.?tale\s*parziale` fra le righe mute e nel subtotale |
| Vision legge lettere cirilliche gemelle | riconoscimento multilingue | `TestoOcr.latino` |
| Vision legge il PAN mascherato con le «x» (s13) | Vision non usa gli asterischi | pulizia delle fixture (`RIPULISCI`, `INIZIO_POS` nello script) e controllo del banco `x{4,}\d{4}` |
| `debugPrint` throttled perdeva le ultime righe del banco sul dispositivo | coda scritta poco alla volta | `print` nell'esempio di micro_ocr |
| Foto verticale ritagliata nel punto sbagliato | EXIF non applicato | `bakeOrientation` prima del conto |
| `previewSize` orizzontale col telefono verticale | convenzione di camerax | lati scambiati in `ObiettivoCamera.anteprima` |
| `Dismissible` scorso ancora nell'albero | lo stream risponde dopo | `_scorse` in `SpesaPage` |
| Permesso della fotocamera chiesto in un giro senza fine | il dialogo del permesso mette in pausa l'attivita' | si riprova solo al ritorno da «Apri le impostazioni» |
| Permesso negato per sempre | il sistema ignora «Riprova» | canale «Apri le impostazioni» nostro |
| Pagina Pro aperta da un push diretto | il controllo era sulla porta (Full Freezer) | `ProGate` sulla rotta, lucchetto nel dettaglio |
| Deep link estraneo in go_router | Flutter passa gli intent con dati | deep link spento |
| `licenseAppId` col trattino basso | il server usa gli id senza (Full Freezer) | `'spendingreview'` |
| Glifi ✓ ⚠ ✗ nei testi | QR Me | `texts_glyphs_test.dart` |
| La X delle miniature fuori dalla foto (F12.7) | `Expanded` imponeva la larghezza della cella | `Center` + `Stack` della misura della foto |
| Errore del motore da «Da una foto» perso (F12.8) | `_daUnaFoto` senza `catch` dentro un `unawaited` | snack `cartellino_scattoFallito` + test |
| Data dello scontrino persa per una data non plausibile prima (F12.8) | `_data` chiudeva con null alla prima data fuori intervallo | si salta e si cerca la successiva + test |
| Ripristino di un backup con un campo di testo di tipo sbagliato senza messaggio (F12.8) | `as String?` lancia `TypeError`, che e' un `Error`: `BackupService.restore` intercetta solo `on Exception`, quindi l'errore usciva dal `unawaited` | `_testoONull` lancia `FormatException` + test |

## 15. Cosa NON esiste, debito tecnico, differenze dal piano, difetti trovati

### 15.1 Cosa NON esiste (per non cercarlo invano)

- **Widget** della schermata Home (niente `home_widget`, decisione F12.0 punto 3).
- **Notifiche** di qualunque tipo (niente `NotificationService`, `POST_NOTIFICATIONS` tolto).
- **Rete**: nessuna chiamata dell'app, tranne acquisto/ripristino del Pro (Billing, server licenze).
- **Voce / dettatura** (non in v1).
- **Estensione di condivisione**, App Group, ricezione di link (deep link spento).
- **Foto conservate**: nessuna tabella, nessun file dopo la lettura; nessuna colonna per il testo OCR.
- **Budget del mese diverso per ogni mese**: un tetto solo (preferenza), uguale per tutti i mesi.
- **Impostazione «Ho la carta fedelta'»** (D4: si chiede ogni volta).
- **Tasto «bilancia»** sulla spesa: la bilancia si riconosce dentro il mirino del Cartellino.
- **Rotta `/pro`**: il paywall si apre con `showSrPaywall`.
- **Lettura dello scritto a mano**: non supportata, l'app manda al tastierino.
- **Classificatore 0°/180°** dell'OCR (vedi micro_ocr).
- **Migrazioni del database** (schema 1).
- **Le preferenze nel backup**; **l'aggiunta manuale di un negozio** (nasce scegliendolo alla chiusura).
- **Taratura sulle foto vere del proprietario** e **fixture di Vision lette sull'iPad**: non ancora (F12.7).
- **Card «In arrivo» nella vetrina, StatusMicroApps, schede degli store**: F12.9 in poi.

### 15.2 Debito tecnico aperto

| Debito | Perche' rimandato | Quando |
|---|---|---|
| **Vision sull'iPad da misurare** (TestFlight, le stesse 107 immagini) | serve l'App ID registrato dal proprietario | F12.7 (aperto); poi decidere se ORT 1.28 anche su iOS (+22 MB) — decide il proprietario |
| **Foto vere del proprietario** (fixture fuori dal repo, col cricchetto) | non ancora consegnate | F12.7 (aperto) |
| **Android vero di fascia media**: avvio a freddo, memoria di picco, tempi dell'OCR, `--split-per-abi --analyze-size` (F12.1.18) | nessun telefono disponibile; l'emulatore x86_64 non e' rappresentativo | F12.7 (aperto) |
| **Log e preferenze fuori dall'esclusione iCloud** (`Library/Application Support/spending_review/logs`, `NSUserDefaults`) | i log di `MicroLog` non contengono dati della spesa per scelta (solo avvisi tecnici), le preferenze solo budget/tema/vibrazione; escluderli tocca `micro_core` (`AppPaths`) e tutte le app | F7 (hardening trasversale) |
| **Le preferenze non sono nel backup** (budget abituale, tetto del mese, tema, vibrazione) | il formato del backup e' per i dati del database | quando lo chiede il proprietario (aggiungere un campo facoltativo come la scheda «Io» di QR Me) |
| **`ScontrinoCameraPage` cancella le copie del selettore senza il controllo della cartella** (`Fotocamera.cancellaSeEsiste` in `_togli`, `_daFoto` oltre i 4 e `dispose`) mentre `LetturaService` lo fa (decisione 2026-10-10: «una foto si cancella solo se sta nelle cartelle temporanee») | `image_picker` restituisce sempre copie temporanee su Android e iOS, quindi oggi non tocca originali; correggerlo vuol dire esportare il controllo di `LetturaService` | alla prossima modifica della pagina dello scontrino |
| **`RegistraScontrinoPage._salva` e `ConfrontoPage._salva` senza `catch`** | un errore del database li fa uscire da un `unawaited` (il bottone si riattiva, niente messaggio); con i vincoli attuali i dati dello scontrino non li violano | con il prossimo giro sulle pagine dello scontrino |
| `EntitlementView`/`EntitlementNotifier` copiati in sei app | `micro_core` non dipende da Riverpod; lo spostamento tocca app gia' pubblicate | F7 |
| `appVersion` duplicata a mano rispetto a `pubspec.yaml` | come le altre app | F7 |
| Il banco di PARITA' con RapidOCR (script) vive fuori dal repo | le fixture del parser invece sono nel repo | se si cambiano modelli o parametri |
| `_Barre.shouldRepaint` confronta liste per identita' (ridisegna sempre) | sei barre: costo nullo | mai, salvo profilo |

### 15.3 Differenze consapevoli dalla specsheet (`develop_microapps.md` F12.1)

| Specsheet | Codice | Perche' |
|---|---|---|
| `LetturaService.scontrino` → `LetturaScontrino` | → `ScontrinoLetto` (lettura + giunzioni) | l'avviso della giunzione nasce in `UnisciParti` |
| `preferisciPrezzoCarta` nel parser e in Impostazioni | `DoppioPrezzoCarta` + `scegliCarta`, due bottoni | D4 |
| `Spesa` senza `totaleSalvato` | campo in piu' | il totale delle chiuse non si ricalcola nemmeno nelle statistiche |
| `incrementaUltima` → `void` | → `bool` | la pagina deve sapere quando vibrare d'errore |
| — | `posizioneDi`, `osservaNumeroChiuse`, `testo_ocr.dart` | «Annulla»; card delle nascoste; testo comune ai tre parser |
| soglia della colonna dei prezzi al 60% dell'immagine | al 60% del testo | scontrini con margini e foto larghe |
| spezzati: centesimi entro 0,35 altezze | 0,5 | c02 |
| ancore distanti 0,3; ancore al 75% | `min(0,3, 2,5 × altezza)`; 60% | foto larghe (c08, c27) |
| lo script condiviso con il solo `transport-backend-cct` e una copia Kotlin nell'app | script allineato, `apply(from = …)` | una regola in un posto |
| nome del prodotto della bilancia = prima riga di lettere | la scritta piu' grande | insegne e bollini sopra il nome (F12.7) |

### 15.4 Difetti trovati rileggendo il codice per questo atlante (F12.8, 2026-10-10)

1. **`CartellinoCameraPage._daUnaFoto` perdeva gli errori del motore** — un errore inatteso (non
   `OcrNonDisponibile`) usciva da un `unawaited` senza messaggio. **Corretto**: snack
   `cartellino_scattoFallito` come lo scatto. Test nuovo in `cartellino_camera_test.dart` (rosso prima
   della correzione, verde dopo).
2. **`ScontrinoParser._data` restituiva null alla prima data non plausibile** anche con la data vera piu'
   avanti (un buono «valido fino al 31/12/2027» stampato prima). **Corretto**: le date non plausibili si
   saltano. Test nuovo in `scontrino_parser_test.dart` (rosso prima, verde dopo); banco invariato.
3. **Il ripristino di un backup con un campo di testo di tipo sbagliato non diceva niente**: `as String?`
   (`dataSpesa`, `unita`, `offerta`, `unitaRif`) lanciava `TypeError`, che `BackupService.restore` (solo
   `on Exception`) non intercetta: niente «ripristino fallito», errore perso in un `unawaited` (il
   database restava intatto grazie alla transazione). **Corretto**: `SpendingBackupSource._testoONull`
   lancia `FormatException`. Test nuovo in `backup_test.dart` (rosso prima, verde dopo).
4. **Commenti superati in `routes.dart`**: `confronto` e `registra` dicevano `extra: LetturaScontrino`
   (il codice vuole `ScontrinoLetto`); `dettaglio` diceva «paywall, non la pagina» (e' la pagina che mostra
   il lucchetto). **Corretti**.
5. **Nota del piano «APK di debug fermo sullo splash (VM in attesa del debugger)»**: non era un difetto
   dell'app (§14.2, prima riga); nota corretta nel piano.
6. Documentati come debito (§15.2), non corretti perche' a rischio nullo oggi: la cancellazione senza
   controllo della cartella in `ScontrinoCameraPage` e i `_salva` senza `catch` delle pagine dello
   scontrino.

## 16. Il perche' delle scelte non ovvie (riepilogo)

- **Tastierino sempre visibile e totale non colorato**: il gesto principale e' alla cassa, con una mano;
  il colore lo porta la barra, il numero resta al massimo contrasto.
- **Due tasti distinti, nessun tasto «intelligente»**: un'interpretazione sbagliata del tipo di foto
  costa piu' di un tocco; la bilancia invece si riconosce da sola perche' la sua «firma» (peso a 3
  decimali e tripla coerente) e' quasi impossibile per caso.
- **Ritaglio al mirino e banco sui ritagli**: il motore rende su UN cartellino da vicino; tarare il
  parser sulle foto larghe del web lo ottimizzava per un caso che nell'app non c'e'.
- **Riquadri e non testo**: centesimi in apice e cifre fuse si riconoscono solo per posizione e altezza.
- **Un parser per due motori**: `RigheVisive` normalizza le differenze; il banco misura entrambi.
- **Cricchetto e non soglie**: nessuno inventa un obiettivo; nessuno puo' peggiorare senza accorgersene.
- **Provider per ogni servizio nativo**: le pagine si provano intere con doppi finti (fotocamera,
  ritaglio, selettore, OCR, vibrazione, impostazioni).
- **Totali scritti alla chiusura**: lo storico non cambia se domani cambia una regola di calcolo.
- **Nascoste e non cancellate**: il Pro promette «tutte le spese»; cancellarle lo renderebbe falso.
- **Canale nostro per le impostazioni**: un pulsante non vale una dipendenza (e un SDK in piu' da
  dichiarare).
- **OCR preparato 3 s dopo il primo frame**: ne' l'avvio ne' la prima lettura pagano i modelli.

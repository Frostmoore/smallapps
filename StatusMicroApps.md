# StatusMicroApps — build e pubblicazioni

> Dove sta ogni app sugli store, quale build c'è dove, e cosa manca per accendere i pulsanti del
> sito. **Si aggiorna a ogni invio, approvazione, rifiuto o rilascio**, con la data.
>
> ⚑ **Ogni app ha sempre tutte e due le sezioni, Google Play e App Store**, anche quando uno
> store e' fermo: si scrive perche' e' fermo, da quando, e cosa lo sblocca. Un'informazione
> "in attesa" e' comunque un'informazione (indicazione del proprietario, 2026-10-08).
>
> Il sito segue questo file: un pulsante store si accende (`suPlay` / `suAppStore` in
> `site/src/apps.php`) **solo** quando qui la riga dice «pubblicata» per quello store **e per
> l'Italia**.

Ultimo aggiornamento: **2026-10-09** (D-U-N-S ricevuto; stati App Store verificati via API la sera del 2026-10-08)

---

## Riepilogo

| App | Versione | Google Play | App Store | Sito: pulsanti |
|---|---|---|---|---|
| **TrashCan** | 1.0.1 (12) | 🟢 **pubblicata**; **1.0.1 (12) in produzione** il 2026-10-10 (widget corretto) | 🟢 1.0.0 in vendita ovunque; 🟡 **1.0.1 (12) in revisione** (inviata il 2026-10-10) | 🟢 **accesi tutti e due** (2026-10-09) |
| **Full Freezer** | 1.0.0 (2) | 🔵 **test interno**, Pro attivo; produzione bloccata dall'account personale (attesa D-U-N-S) | 🔴 **respinta 2.1** il 2026-10-10 (domanda sull'AI): risposta pronta, in arrivo la 1.0.0 (3) con la dettatura solo sul telefono | card grigia «In arrivo» |
| **Scorte Calore** | 1.0.0 (1) | ⚪ **non ancora creata** su Play Console; codice Android completo, grafiche Play pronte; bloccata dall'account personale (attesa D-U-N-S) | 🟢 **in vendita** (1.0.0 + Pro approvati, 2026-10-10) | card grigia «In arrivo»: pulsanti solo quando e' pubblicata su **entrambi** gli store |
| **Film Tracker** | 1.0.0 (1) | ⚪ **non ancora creata** su Play Console; codice Android completo, grafiche Play pronte; bloccata dall'account personale (attesa D-U-N-S) | 🟡 **in revisione** (1.0.0 (1) + Pro, inviata il 2026-10-08) | card grigia «In arrivo» |

**App in programma** (decise il 2026-10-08, fasi F10–F19 di `develop_microapps.md` §1.6): non
ancora iniziate, quindi ⚪ su **Google Play** e ⚪ su **App Store** per tutte e dieci; card in
vetrina da aggiungere.

| App | Fase | Google Play | App Store |
|---|---|---|---|
| Te l'ho prestato | F10 | ⚪ non iniziata | ⚪ non iniziata |
| Dove l'ho lasciato? | F11 | ⚪ non iniziata | ⚪ non iniziata |
| Quanto sto spendendo? | F12 | ⚪ non iniziata — **la prossima**, si parte il 2026-10-11 | ⚪ non iniziata |
| Quanto dividiamo? | F13 | ⚪ non iniziata | ⚪ non iniziata |
| Ricordamelo qui | F14 | ⚪ non iniziata | ⚪ non iniziata |
| Quanti sono? | F15 | ⚪ non iniziata | ⚪ non iniziata |
| Riassumilo | F16 | ⚪ non iniziata | ⚪ non iniziata |
| **QR Me** (ex Fammi un QR) | F17 | ⚪ codice Android completo (2026-10-09); app non creata su Play Console, bloccata dall'account (D-U-N-S) | 🟡 **in revisione** (1.0.0 (2) + Pro, inviata il 2026-10-10) |
| Leggimelo | F18 | ⚪ non iniziata | ⚪ non iniziata |
| Dove porta? | F19 | ⚪ non iniziata | ⚪ non iniziata |

Legenda: ⚪ non iniziata sullo store · 🔵 in test / in sviluppo · 🟡 in revisione ·
🟠 pubblicata in parte · 🟢 pubblicata · 🔴 respinta

---

## Account Google Play (comune a tutte le app)

| Dato | Valore |
|---|---|
| Account | SMPStudio, oggi **personale** |
| Conseguenza | ogni app **nuova** deve fare un **test chiuso con 12 tester per 14 giorni** prima di poter andare in produzione (TrashCan l'ha gia' fatto a settembre) |
| Soluzione scelta | passare ad account **da organizzazione**, che non ha questo obbligo |

| Data | Evento |
|---|---|
| 2026-10-07 | Sito `https://smp-digital.it` verificato per il cambio (record TXT su Aruba + Search Console) |
| 2026-10-07 | **D-U-N-S richiesto** tramite il modulo di Apple; in attesa dell'email di Dun & Bradstreet |
| 2026-10-08 | Ancora in attesa del D-U-N-S |
| 2026-10-09 | **D-U-N-S ricevuto: 302873881** (D&B, caso 11083280, creato il 2026-10-09 alle 10:14 UTC, intestato a «SEE MY PAGE DI RONCONI RICCARDO», Nepi VT) |
| 2026-10-09 | Primo inserimento nel modulo di Google: «numero non trovato». Causa probabile: numero creato **la mattina stessa**, non ancora arrivato ai sistemi di Google. ☠ I tentativi sono limitati: non riprovare finche' il numero non risulta nelle ricerche pubbliche (vedi sotto) |

**Cosa sblocca, in ordine:**

1. ✅ Numero D-U-N-S arrivato il 2026-10-09 (302873881). **Prima di ritentare su Google**
   (tentativi limitati) controllare che sia visibile pubblicamente, cosa che non consuma
   tentativi: lo strumento di ricerca D-U-N-S di Apple (developer.apple.com/enroll/duns-lookup)
   o la ricerca di D&B. Di solito qualche giorno lavorativo, a volte di piu'. Quando si inserisce,
   nome e indirizzo dell'organizzazione nel profilo pagamenti devono essere **identici** al
   record D&B («SEE MY PAGE DI RONCONI RICCARDO», Via degli Orti 426, 01036 Nepi VT).
2. Play Console → Account sviluppatore → **Cambia tipo di account** → organizzazione, con
   profilo pagamenti da organizzazione e recapiti pubblici di lavoro.
3. Dopo il cambio **aspettare 72 ore** prima di pubblicare.
4. Poi, app per app: Full Freezer in produzione; Scorte Calore e Film Tracker create, caricate e
   pubblicate (sezioni qui sotto).

☠ Su Play il prezzo di un prodotto si scrive **senza IVA**: Play aggiunge il 22% per l'Italia
(pagato con Full Freezer). Prezzi base: Full Freezer 3,27 EUR → 3,99 €, Scorte Calore
2,45 EUR → 2,99 €, Film Tracker 4,09 EUR → 4,99 €.

---

## TrashCan

| Dato | Valore |
|---|---|
| Pacchetto / bundle | `com.smp.trashcan` |
| Prodotto Pro | `trashcan_pro_lifetime`, non consumabile |
| Prezzo Pro | Play **2,39 €** · App Store **2,99 €** (il sito mostra il più alto, vedi `memory/decisioni.md`) |
| Apple app id | `6818986320` · IAP id `6819339143` |
| Link App Store | https://apps.apple.com/app/id6818986320 |
| Link Play | https://play.google.com/store/apps/details?id=com.smp.trashcan |

> **Widget che non cambiava giorno a mezzanotte (segnalato il 2026-10-10): corretto nella 1.0.1 (12).**
> Causa: su Android 14+ senza permesso di allarmi esatti l'allarme delle 00:05 era inesatto e arrivava
> verso l'01:05. Ora: preavviso alle 23:00:30 che arriva alle 00:00:30, ridisegno ogni 30 minuti come
> rete, cambi d'ora e di fuso gestiti; iOS ricarica la timeline a ogni mezzanotte. Provato
> sull'emulatore in Doze profondo con l'app chiusa (cambio alle 00:00:29).
>
> - [x] **App Store:** versione **1.0.1** creata via API con la build **12** collegata e le «Novita'»
>   it/en-GB (2026-10-10); profili «MicroApps AppStore» di TrashCan creati (prima firmava col portachiavi
>   di sistema, che da ssh e' chiuso: `errSecInternalComponent`). ☠ La 1.0.0 pubblicata non accetta
>   build nuove (90186): ogni correzione dopo l'uscita richiede una versione nuova.
> - [x] **Proprietario:** 1.0.1 inviata in revisione su App Store (2026-10-10): WAITING_FOR_REVIEW, verificato via API.
>   Possibile chiedere la revisione accelerata (correzione di un difetto di una funzione centrale).
> - [x] **Proprietario:** `trashcan-1.0.1-12.aab` caricato e **pubblicato** su Play (2026-10-10).
> - [ ] Prova di una notte su un telefono Android vero e su iPad.

### Google Play — 🟢 pubblicata

| Data | Evento |
|---|---|
| 2026-09 | Test chiuso: 14 giorni con 12 tester completati |
| entro 2026-10-06 | Inviata in **produzione** con la **build 11** (confermato dal proprietario) |
| 2026-10-06 | Stato: **in revisione** |
| 2026-10-08 | **Pubblicata, disponibile su Google Play** (comunicato dal proprietario; scheda raggiungibile dall'Italia, HTTP 200) |
| 2026-10-10 | **1.0.1 (12)** con il widget corretto: caricata dal proprietario, **aggiornata e pubblicata** |

**Sito:** pulsante Play acceso il 2026-10-09, **insieme** a quello App Store come deciso il
2026-10-08 (vedi `memory/decisioni.md`).

### App Store — 🟢 pubblicata ovunque

| Data | Evento |
|---|---|
| entro 2026-10-06 | Build 10 inviata · respinta 2.1 (richiesta informazioni) |
| 2026-10-06 | Accordo app a pagamento attivo; il prezzo del Pro arriva in sandbox dalle 12:13 |
| 2026-10-06 | Build 11 + TrashCan Pro inviati insieme (12:41) |
| 2026-10-06 | **Approvata**, rilascio automatico: «Pronta per la distribuzione» |
| 2026-10-06 | In vendita in **148 paesi**; nei **27 paesi UE (Italia compresa)** bloccata con `TRADER_STATUS_NOT_PROVIDED` |
| 2026-10-07 | Ricontrollato via API: Italia ancora `TRADER_STATUS_NOT_PROVIDED` (verifica DSA di Apple in corso, niente da fare da parte nostra) |
| 2026-10-08 | Ricontrollato via API (due volte): Italia ancora `TRADER_STATUS_NOT_PROVIDED`; versione READY_FOR_SALE, Pro APPROVED |
| 2026-10-09 | Verifica DSA approvata da Apple (comunicato dal proprietario): **disponibile in tutti i 175 paesi, Italia compresa** (ITA = AVAILABLE, nessun paese bloccato; verificato via API) |

✅ **Verifica DSA chiusa il 2026-10-09** (dati inviati il 2026-10-05): l'app e' comparsa in UE da
sola, senza un nuovo invio. Vale per l'account: le altre app nasceranno gia' disponibili in UE.

Verifica via API (sul Mac):
```bash
cd ~/microapps && python3 tool/asc_api.py GET '/v2/appAvailabilities/6818986320/territoryAvailabilities?limit=200&include=territory'
# ITA deve passare da TRADER_STATUS_NOT_PROVIDED ad AVAILABLE
```

**Sito:** ✅ il 2026-10-09 `suPlay => true` e `suAppStore => true` per TrashCan, pubblicato su
clawserver (siti critici a 200 prima e dopo, verifica §11 dell'atlante del sito superata).

---

## Full Freezer

| Dato | Valore |
|---|---|
| Pacchetto / bundle | `com.smp.fullfreezer` · estensione widget iOS `com.smp.fullfreezer.FullFreezerWidget` |
| App Group iOS | `group.com.smp.fullfreezer` (app ed estensione) |
| Prodotto Pro | `fullfreezer_pro_lifetime`, non consumabile, **3,99 €** (Play: base 3,27 EUR senza IVA) |
| Apple app id | `6820155659` · IAP id `6820155793` |
| Piattaforme | Android e solo iPhone |

Codice completo (F4 di `develop_microapps.md`, 2026-10-07), provato sull'emulatore Android, sul
simulatore iPhone e dal proprietario su iPad (TestFlight).

### Google Play — 🔵 test interno, produzione bloccata dall'account

> AAB **1.0.0 (3)** con la dettatura solo sul dispositivo pronto in `apps/full_freezer/store/full_freezer-1.0.0-3.aab` (2026-10-10), da caricare nel test interno.

| Data | Evento |
|---|---|
| 2026-10-07 | App creata su Play Console (account **personale** SMPStudio); AAB **1.0.0 (2)** in **test interno**; prodotto `fullfreezer_pro_lifetime` **attivo**, base 3,27 EUR → 3,99 € in Italia; scheda dello Store compilata it/en (testi importati da `store/traduzioni-play.txt`), grafiche caricate |
| 2026-10-07 | Il test interno non si scaricava per le modifiche in attesa nella Panoramica della pubblicazione e per l'account personale |
| 2026-10-07 | ☠ Account personale → serve il test chiuso con 12 tester per 14 giorni: avviato il cambio ad account da organizzazione (vedi **Account Google Play**) |
| 2026-10-08 | Fermo in attesa del D-U-N-S |

**Prossimi passi Play:**
- [ ] Compilare i moduli «Contenuti dell'app» (risposte in `apps/full_freezer/store/scheda-play.md` §6-8)
- [ ] D-U-N-S → cambio tipo di account → 72 ore (sezione **Account Google Play**)
- [ ] Produzione con l'AAB 1.0.0 (2), o una build nuova se nel frattempo cambia qualcosa
- [ ] Provare sul telefono vero la voce (sull'emulatore non si poteva)

### App Store — 🔴 respinta (2.1, informazioni richieste)

| Data | Evento |
|---|---|
| 2026-10-07 | App creata su App Store Connect (id `6820155659`, SKU `com.smp.fullfreezer`); App ID e App Group registrati dal proprietario |
| 2026-10-07 | Prodotto `fullfreezer_pro_lifetime` (id `6820155793`): testi it/en-GB, 3,99 € (base Italia, ricavo 2,77 €), 175 paesi, screenshot di revisione → **READY_TO_SUBMIT** |
| 2026-10-07 | Build **1.0.0 (1)** su **TestFlight**, gruppo interno «Sviluppatore» (accesso a tutte le build) |
| 2026-10-07 | Provata dal proprietario su **iPad** (compatibilita' iPhone): acquisto Pro e voce funzionano |
| 2026-10-07 | Scheda caricata via API (`apps/full_freezer/tool/scheda_app_store.py`); nome inglese **«Full Freezer – Freezer Tracker»** perche' «Full Freezer» in inglese e' gia' di un altro sviluppatore; intestazione e risultato di ricerca caricati a mano |
| 2026-10-07 | **Inviata per la verifica**: versione 1.0.0 e Pro in **WAITING_FOR_REVIEW** |
| 2026-10-08 | Ricontrollato via API: ancora WAITING_FOR_REVIEW |
| 2026-10-10 | In revisione (IN_REVIEW), poi **REJECTED, Guideline 2.1 — Information Needed** (iPad Air 11" M3): «Does the app send data to a third-party AI system? Does the AI feature send user data outside the device?». Risposta preparata: nessuna AI, categoria da un elenco di parole nell'app, voce con lo Speech framework di Apple e interpretazione con regole locali |
| 2026-10-10 | Verificando la risposta: la dettatura **non** era limitata al telefono (`onDevice` assente, iOS/Android potevano usare i server di Apple/Google). Decisione del proprietario: **dettatura solo sul dispositivo** → build **1.0.0 (3)** in preparazione |

| 2026-10-10 | **Il proprietario ha risposto ad Apple e reinviato** la 1.0.0 con la **build 1**: di nuovo WAITING_FOR_REVIEW. La build **3** (dettatura solo sul dispositivo) e' caricata e VALID ma non si puo' collegare a una versione in coda (409); scelta del proprietario: **lasciarla in coda**, niente ritiro |

**Prossimi passi App Store:**
- [x] Risposta ad Apple e reinvio (proprietario, 2026-10-10)
- [ ] Dopo l'approvazione: **1.0.1** con la dettatura solo sul dispositivo (il codice e' quello della build 3; serve `1.0.1+4` perche' la 1.0.0 pubblicata non accetta build nuove)
- [x] Informativa del sito: paragrafo sulla dettatura **pubblicato** il 2026-10-10 (dalla 1.0.1 solo sul telefono; nella 1.0.0 il servizio del sistema puo' usare i server di Apple/Google)

Grafiche in `apps/full_freezer/store/grafiche/` (testata 1024x500, 6 schede 1320x2868 per App
Store e 1080x2160 per Play, it/en). ☠ Firma: Xcode 27 non crea piu' profili nuovi con la chiave
API; i profili «MicroApps AppStore …» si creano via API (vedi `tool/build_ios.sh`).

---

## Scorte Calore

| Dato | Valore |
|---|---|
| Pacchetto / bundle | `com.smp.scortecalore` · estensione widget iOS `com.smp.scortecalore.ScorteCaloreWidget` |
| App Group iOS | `group.com.smp.scortecalore` (app ed estensione) |
| Prodotto Pro | `scortecalore_pro_lifetime`, non consumabile, **2,99 €** (Play: base 2,45 EUR senza IVA) |
| Apple app id | `6820405604` |
| Piattaforme | Android e solo iPhone |

Codice completo (F5, 2026-10-08), provato sull'emulatore Android e sul simulatore iPhone, widget
compreso.

### Google Play — ⚪ non ancora creata, bloccata dall'account

| Data | Evento |
|---|---|
| 2026-10-08 | Codice Android completo e provato sull'emulatore (home, widget, notifiche, calendario con un calendario locale, storico, costi, backup); **app non ancora creata su Play Console** |
| 2026-10-08 | Grafiche Play pronte: `apps/scorte_calore/store/grafiche/play/` (schede 1080x2160 it/en) e `testata-1024x500-<lingua>.png` |
| 2026-10-08 | Fermo: con l'account personale servirebbero 12 tester per 14 giorni; si aspetta il D-U-N-S (sezione **Account Google Play**) |

**Prossimi passi Play** (dopo il cambio di account):
- [ ] Creare l'app su Play Console (`com.smp.scortecalore`)
- [ ] AAB di release firmato (`tool/build_release.ps1`), caricato in test interno
- [ ] Prodotto `scortecalore_pro_lifetime` a **2,45 EUR senza IVA** (→ 2,99 €)
- [ ] Scheda it/en (testi da adattare da `store/scheda-app-store.md`), grafiche dalla cartella `play/`
- [ ] ☠ Dichiarazione dei permessi: **giustificare `READ_CALENDAR` e `WRITE_CALENDAR`** (funzione Pro facoltativa: la data di riordino nel calendario); notifiche e allarmi del widget
- [ ] Moduli «Contenuti dell'app» (sulla falsariga di Full Freezer) e produzione

### App Store — 🟢 in vendita

| Data | Evento |
|---|---|
| 2026-10-08 | App `6820405604`, App ID e App Group creati dal proprietario; profili «MicroApps AppStore com.smp.scortecalore» e «…ScorteCaloreWidget» creati via API (gruppo dentro) |
| 2026-10-08 | **Via API** (`apps/scorte_calore/tool/scheda_app_store.py`): nomi, sottotitoli, categorie Utility + Stile di vita, privacy, diritti sui contenuti, disponibilita' in 175 paesi, gratuita, testi it/en-GB, 5 screenshot 6,5" per lingua, **anteprima video** 6,5" per lingua (COMPLETE), note e contatti per la revisione |
| 2026-10-08 | Prodotto `scortecalore_pro_lifetime` creato via API: non consumabile, 2,99 € (base Italia), tutti i paesi, testi it/en-GB, screenshot per la revisione |
| 2026-10-08 | Build **1.0.0 (1)** su TestFlight; gruppo interno «Sviluppatore» col proprietario, invito mandato a parte (aggiungere al gruppo non basta) |
| 2026-10-08 | Fatti a mano dal proprietario: Intestazione e Risultati della ricerca, etichetta privacy, classificazione per eta', acquisto in-app spuntato; build collegata alla versione via API |
| 2026-10-08 | **Inviata alla revisione**: versione 1.0.0 e Pro in WAITING_FOR_REVIEW (verificato via API, anche la sera) |
| 2026-10-10 | **Approvata e in vendita**: versione 1.0.0 READY_FOR_SALE, Pro APPROVED (verificato via API) |

**Sito:** pulsante App Store **non** acceso: decisione del proprietario (2026-10-10) i pulsanti di
un'app si accendono solo quando e' pubblicata su **entrambi** gli store. Scorte Calore aspetta Play.

---

## Film Tracker

| Dato | Valore |
|---|---|
| Pacchetto / bundle | `com.smp.filmtracker` (nessun widget, nessun App Group) |
| Prodotto Pro | `filmtracker_pro_lifetime`, non consumabile, **4,99 €** (decisione del proprietario; Play: base 4,09 EUR senza IVA) |
| Apple app id | `6820633385` · IAP id `6820641001` |
| Nome nello store inglese | «Film Tracker – Roll Diary» (in inglese «Film Tracker» e' di un altro sviluppatore) |
| Piattaforme | Android e solo iPhone |

Codice completo (F6, 2026-10-08), provato sull'emulatore Android, sul simulatore iPhone e dal
proprietario su iPad (TestFlight: «mi pare che funzioni tutto»).

### Google Play — ⚪ non ancora creata, bloccata dall'account

| Data | Evento |
|---|---|
| 2026-10-08 | Codice Android completo e provato sull'emulatore (home C · Provino, rullini, laboratorio, foto, QR via adb, statistiche, PDF, backup); **app non ancora creata su Play Console**, nessun AAB caricato |
| 2026-10-08 | Grafiche Play pronte: `apps/film_tracker/store/grafiche/play/` (schede 1080x2160 it/en) e `testata-1024x500-<lingua>.png` |
| 2026-10-08 | Fermo: con l'account personale servirebbero 12 tester per 14 giorni; si aspetta il D-U-N-S (sezione **Account Google Play**) |

**Prossimi passi Play** (dopo il cambio di account):
- [ ] Creare l'app su Play Console (`com.smp.filmtracker`)
- [ ] AAB di release firmato (`tool/build_release.ps1`), caricato in test interno
- [ ] Prodotto `filmtracker_pro_lifetime` a **4,09 EUR senza IVA** (→ 4,99 €)
- [ ] Scheda it/en (testi da adattare da `store/scheda-app-store.md`), grafiche dalla cartella `play/`
- [ ] Dichiarazione dei permessi: fotocamera e foto (solo quando si aggiunge una foto a un rullino)
- [ ] Moduli «Contenuti dell'app» e produzione
- [ ] Provare su un Android vero: foto HEIC dalla galleria, QR letto dalla fotocamera di sistema

### App Store — 🟡 in revisione

| Data | Evento |
|---|---|
| 2026-10-08 | App `6820633385` e App ID `com.smp.filmtracker` creati dal proprietario; profilo «MicroApps AppStore com.smp.filmtracker» creato via API |
| 2026-10-08 | **Via API** (`apps/film_tracker/tool/scheda_app_store.py`): nomi (it «Film Tracker», en-GB «Film Tracker – Roll Diary»), sottotitoli, categorie Foto e video + Stile di vita, privacy, diritti, disponibilita', gratuita, testi it/en-GB, 5 screenshot 6,5" e video per lingua (COMPLETE), revisione |
| 2026-10-08 | Prodotto `filmtracker_pro_lifetime`: 4,99 € base Italia (verificato via API), tutti i paesi, testi it/en-GB, screenshot di revisione → READY_TO_SUBMIT |
| 2026-10-08 | Build **1.0.0 (1)** su TestFlight e collegata alla versione; gruppo «Sviluppatore» col proprietario, invito mandato |
| 2026-10-08 | Fatti a mano dal proprietario: Intestazione e Risultati della ricerca, etichetta privacy, classificazione per eta', acquisto in-app spuntato; provata su iPad |
| 2026-10-08 | **Inviata alla revisione**: versione 1.0.0 e Pro in WAITING_FOR_REVIEW (verificato via API) |

## QR Me

| Dato | Valore |
|---|---|
| Pacchetto / bundle | `com.smp.qrme` · estensione di condivisione iOS `com.smp.qrme.ShareExtension` |
| App Group iOS | `group.com.smp.qrme` (app ed estensione: serve alla condivisione verso l'app) |
| Prodotto Pro | `qrme_pro_lifetime`, non consumabile, **1,99 €** (Play: base **1,63 EUR** senza IVA) |
| Nome | «QR Me» in italiano e in inglese (ripiego se gia' preso: «QR Me – Share & Scan» / «QR Me – Condividi e leggi») |
| Piattaforme | Android e solo iPhone |
| Grafica | «A · Neon» (tema scuro, verde `#3BD13B`) |

Codice completo il 2026-10-09 (F17.0–F17.9): 182 test, lettura con ZXing, provato sull'emulatore Android
(condivisione di testo e di immagini con un QR vero, moduli, stile con verifica di leggibilita',
backup) e sul simulatore iPhone. Card «In arrivo» pubblicata nel sito il 2026-10-09.

### Google Play — ⚪ non ancora creata, bloccata dall'account

| Data | Evento |
|---|---|
| 2026-10-09 | Codice Android completo; **app non ancora creata su Play Console**, nessun AAB caricato |
| 2026-10-09 | Fermo come le altre app nuove: account personale (12 tester per 14 giorni), si aspetta il D-U-N-S |
| 2026-10-09 | **ML Kit tolto** (decisione del proprietario: dati solo sul telefono): la lettura passa a ZXing dentro l'app, su Android e iOS |

**Prossimi passi Play** (dopo il cambio di account):
- [ ] License Server: riga `qrme` nella tabella `apps` e il suo segreto in `APP_SECRETS`
- [ ] Creare l'app su Play Console (`com.smp.qrme`), AAB di release firmato in test interno
- [ ] Prodotto `qrme_pro_lifetime` a **1,63 EUR senza IVA** (→ 1,99 €)
- [ ] Scheda it/en, screenshot e grafiche (da fare: `store/` non esiste ancora)
- [ ] Data safety (nessun dato raccolto, salvo il server licenze per il Pro) e dichiarazione della fotocamera
- [ ] Provare su un Android vero: fotocamera reale, condivisione da Chrome e da Galleria

### App Store — 🟡 in revisione

| Data | Evento |
|---|---|
| 2026-10-09 | Estensione di condivisione aggiunta al progetto con `tool/aggiungi_share_extension_ios.rb` (eseguito sul Mac, idempotente); build per il simulatore riuscita; l'estensione non incorpora framework |
| 2026-10-09 | App provata sul simulatore iPhone (grafica Neon); esclusione di database e dati dal backup iCloud verificata |
| 2026-10-09 | App ID `com.smp.qrme` e `com.smp.qrme.ShareExtension` con App Groups → `group.com.smp.qrme` creati dal proprietario; app App Store Connect **`6821086416`** «QR Me» (il nome era libero) |
| 2026-10-09 | Profili «MicroApps AppStore com.smp.qrme» e «… .ShareExtension» creati via API (certificato DU9DGW7NAH), entrambi col gruppo |
| 2026-10-09 | Build **1.0.0 (1)** caricata (VALID alle 20:45), gruppo TestFlight «Sviluppatore» creato via API col proprietario, **invito mandato** |
| 2026-10-09 | **Scheda completa via API** (`apps/qr_me/tool/scheda_app_store.py`), verificata campo per campo: nomi it «QR Me», **en-GB «QR Me – Share & Scan»** («QR Me» in inglese e' di un altro account, 409), sottotitoli, categorie Utilita' + Produttivita', gratuita in 175 paesi, testi it/en-GB, 5 screenshot 6,9" e 6,5" per lingua, video per lingua, contatti e note di revisione, build 1.0.0 (1) collegata; versione PREPARE_FOR_SUBMISSION |
| 2026-10-09 | Prodotto **`qrme_pro_lifetime`** (id 6821117058) 1,99 € base Italia, testi, screenshot di revisione → READY_TO_SUBMIT |
| 2026-10-09 | Fatti a mano dal proprietario: classificazione per eta', etichetta privacy. Intestazione e risultati della ricerca messi sulla Scrivania del Mac |
| 2026-10-09 | Provata su iPad (TestFlight, build 1): **la condivisione verso QR Me funziona** («quasi istantaneamente»). Il proprietario chiede di rifare i moduli (F17.10): Wi-Fi da QR letto o dalla rete connessa, Contatto dalla rubrica o «Io», email precompilata, via SMS e Telefono, Pro «Genera etichetta». Capability «Access Wi-Fi Information» abilitata via API, profili rigenerati |

**Prossimi passi App Store:**
- [x] **Proprietario:** App ID `com.smp.qrme` e gruppo `group.com.smp.qrme` creati (2026-10-09)
- [ ] **Proprietario:** App ID `com.smp.qrme.ShareExtension` con App Groups → `group.com.smp.qrme`
- [x] Profili via API per app ed estensione, build 1.0.0 (1) su TestFlight, invito al proprietario
- [x] Scheda completa via API e build collegata alla versione
- [x] F17.10 (moduli nuovi, etichetta) → build **1.0.0 (2)** caricata (VALID) e **collegata** alla versione; 6 screenshot per lingua (6,9" e 6,5"), video, grafiche, testi e note di revisione rifatti e ricaricati via API, verificati (nessun campo vuoto, nessun doppione) — 2026-10-09
- [ ] **A mano (Apple non lo permette via API col Pro in READY_TO_SUBMIT, 409):** nel Pro `qrme_pro_lifetime` sostituire lo **screenshot di revisione** con `QRMe-paywall-revisione-it.png` (Scrivania del Mac, cartella QR Me) e la **descrizione** con «Moduli, stile e logo, immagine ed etichetta, backup» / «Forms, style and logo, image and label, backup»
- [ ] **Provare su iPad**: condividere da Safari verso QR Me (l'estensione deve riaprire l'app); se iOS lo impedisce, ripiego deciso in F17.1.8 (QR mostrato dall'estensione stessa)
- [x] Prodotto `qrme_pro_lifetime` a 1,99 €; eta' ed etichetta privacy (proprietario)
- [x] **Inviata in revisione dal proprietario** (2026-10-10): versione 1.0.0 con build 2 e `qrme_pro_lifetime` in WAITING_FOR_REVIEW (verificato via API). I campi «Intestazione» e «Risultati della ricerca» in App Store Connect non c'erano piu' (sezione tolta o spostata da Apple, non dallo script)

---

## Quando una app finisce di uscire: aggiornare il sito

1. Qui la riga dice pubblicata, **in Italia**, sullo store in questione.
2. `site/src/apps.php`: `suPlay => true` e/o `suAppStore => true` (per un'app nuova anche
   `appStoreId`, preso da App Store Connect).
3. `php site/deploy/verifica_lingue.php`, prova in locale, poi pubblicazione su clawserver
   (procedura in `site/codebase_reference.md` §9 — **chiedere prima conferma**, controllare i
   siti critici a 200 prima e dopo).
4. Aggiornare questo file con la data.

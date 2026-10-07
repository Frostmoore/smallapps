# StatusMicroApps — build e pubblicazioni

> Dove sta ogni app sugli store, quale build c'è dove, e cosa manca per accendere i pulsanti del
> sito. **Si aggiorna a ogni invio, approvazione, rifiuto o rilascio**, con la data.
>
> Il sito segue questo file: un pulsante store si accende (`suPlay` / `suAppStore` in
> `site/src/apps.php`) **solo** quando qui la riga dice «pubblicata» per quello store **e per
> l'Italia**.

Ultimo aggiornamento: **2026-10-07**

---

## Riepilogo

| App | Versione | Google Play | App Store | Sito: pulsanti |
|---|---|---|---|---|
| **TrashCan** | 1.0.0 (11) | 🟡 in revisione (produzione) | 🟠 pubblicata, **tranne UE** | spenti («Presto su Google Play e App Store») |
| **Full Freezer** | 1.0.0 (2) | 🔵 test interno, Pro attivo; in attesa del D-U-N-S per l'account da organizzazione | 🔵 **TestFlight** (build 1), Pro pronto per l'invio, scheda da compilare | card grigia «In arrivo» |
| **Scorte Calore** | — | ⚪ non iniziata | ⚪ non iniziata | card grigia «In arrivo» |
| **Film Tracker** | — | ⚪ non iniziata | ⚪ non iniziata | card grigia «In arrivo» |

Legenda: ⚪ non iniziata · 🔵 in sviluppo · 🟡 in revisione · 🟠 pubblicata in parte ·
🟢 pubblicata · 🔴 respinta

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

### Google Play

| Data | Evento |
|---|---|
| 2026-09 | Test chiuso: 14 giorni con 12 tester completati |
| entro 2026-10-06 | Inviata in **produzione** con la **build 11** (confermato dal proprietario) |
| 2026-10-06 | Stato: **in revisione** |

**Per accendere il pulsante sul sito:** app visibile su Play dall'Italia → `suPlay => true`.

### App Store

| Data | Evento |
|---|---|
| entro 2026-10-06 | Build 10 inviata · respinta 2.1 (richiesta informazioni) |
| 2026-10-06 | Accordo app a pagamento attivo; il prezzo del Pro arriva in sandbox dalle 12:13 |
| 2026-10-06 | Build 11 + TrashCan Pro inviati insieme (12:41) |
| 2026-10-06 | **Approvata**, rilascio automatico: «Pronta per la distribuzione» |
| 2026-10-06 | In vendita in **148 paesi**; nei **27 paesi UE (Italia compresa)** bloccata con `TRADER_STATUS_NOT_PROVIDED` |
| 2026-10-07 | Ricontrollato via API: Italia ancora `TRADER_STATUS_NOT_PROVIDED` (verifica DSA di Apple in corso, niente da fare da parte nostra) |

⏳ **In attesa di Apple:** Business → Conformità → *Normativa sui servizi digitali* =
«Verifica in corso» (dati inviati il 2026-10-05, niente da cliccare). Quando diventa «Attivo»
l'app compare in UE da sola, senza un nuovo invio. Se dopo 3–4 giorni lavorativi è ancora così e
non è arrivata nessuna mail: developer.apple.com/contact → App Store Connect → Business.

Verifica via API (sul Mac):
```bash
cd ~/microapps && python3 tool/asc_api.py GET '/v2/appAvailabilities/6818986320/territoryAvailabilities?limit=200&include=territory'
# ITA deve passare da TRADER_STATUS_NOT_PROVIDED ad AVAILABLE
```

**Per accendere il pulsante sul sito:** ITA = `AVAILABLE` → `suAppStore => true`.

---

## Full Freezer

| Dato | Valore |
|---|---|
| Pacchetto / bundle | `com.smp.fullfreezer` · estensione widget iOS `com.smp.fullfreezer.FullFreezerWidget` |
| App Group iOS | `group.com.smp.fullfreezer` (app ed estensione) |
| Prodotto Pro | `fullfreezer_pro_lifetime`, non consumabile, **3,99 €** |
| Piattaforme | Android e solo iPhone |

Codice completo (F4 di `develop_microapps.md`, 2026-10-07), provato sull'emulatore Android e
sul simulatore iPhone.

| Data | App Store |
|---|---|
| 2026-10-07 | App creata su App Store Connect (id `6820155659`, SKU `com.smp.fullfreezer`); App ID e App Group registrati dal proprietario |
| 2026-10-07 | Prodotto `fullfreezer_pro_lifetime` (id `6820155793`): testi it/en-GB, 3,99 € (base Italia, ricavo 2,77 €), 175 paesi, screenshot di revisione → **READY_TO_SUBMIT** |
| 2026-10-07 | Build **1.0.0 (1)** su **TestFlight**, gruppo interno «Sviluppatore» (accesso a tutte le build) |

Grafiche pronte in `apps/full_freezer/store/grafiche/` (testata 1024x500, 6 schede 1320x2868 per
App Store e 1080x2160 per Play, it/en). ☠ Firma: Xcode 27 non crea piu' profili nuovi con la chiave
API; per Full Freezer i profili «MicroApps AppStore …» sono stati creati via API (vedi
`tool/build_ios.sh`).

| Data | Google Play |
|---|---|
| 2026-10-07 | App creata su Play Console (account **personale** SMPStudio); AAB **1.0.0 (2)** in **test interno**; prodotto `fullfreezer_pro_lifetime` **attivo**, base 3,27 EUR → 3,99 € in Italia; scheda dello Store compilata it/en (testi importati da `store/traduzioni-play.txt`) |
| 2026-10-07 | ☠ **Account personale → per ogni app nuova serve un test chiuso con 12 tester per 14 giorni** prima della produzione. Avviato il **cambio ad account da organizzazione**: sito `https://smp-digital.it` verificato (record TXT su Aruba + Search Console), **D-U-N-S richiesto** tramite il modulo Apple, in attesa dell'email di Dun & Bradstreet |

**Prossimi passi Play**: compilare i moduli «Contenuti dell'app» (risposte in `apps/full_freezer/store/scheda-play.md` §6-8); appena arriva il D-U-N-S (aspettare 1-2 giorni lavorativi prima di inserirlo) → Account sviluppatore → Cambia tipo di account, con profilo pagamenti da organizzazione e recapiti pubblici di lavoro; dopo il cambio aspettare 72 ore prima di pubblicare.

Cosa resta (prima versione era: prima del primo invio, il proprietario deve):

- **Apple**: registrare gli App ID `com.smp.fullfreezer` e `com.smp.fullfreezer.FullFreezerWidget`
  con la capability App Groups, creare il gruppo `group.com.smp.fullfreezer`, creare l'app su
  App Store Connect e il prodotto non consumabile `fullfreezer_pro_lifetime` a 3,99 €
  (il primo prodotto si allega alla versione, come per TrashCan).
- **Google**: creare l'app su Play Console, caricare un primo AAB (serve perche' compaia la
  sezione prodotti), creare `fullfreezer_pro_lifetime` a 3,99 €.
- Provare sul proprio telefono: voce vera e tocco del widget su iPhone (sul simulatore non si
  potevano provare).

## Scorte Calore

Non iniziata. Pacchetto previsto `com.smp.scortecalore`, Pro `scortecalore_pro_lifetime`.

## Film Tracker

Non iniziata. Pacchetto previsto `com.smp.filmtracker`, Pro `filmtracker_pro_lifetime`.

---

## Quando una app finisce di uscire: aggiornare il sito

1. Qui la riga dice pubblicata, **in Italia**, sullo store in questione.
2. `site/src/apps.php`: `suPlay => true` e/o `suAppStore => true` (per un'app nuova anche
   `appStoreId`, preso da App Store Connect).
3. `php site/deploy/verifica_lingue.php`, prova in locale, poi pubblicazione su clawserver
   (procedura in `site/codebase_reference.md` §9 — **chiedere prima conferma**, controllare i
   siti critici a 200 prima e dopo).
4. Aggiornare questo file con la data.

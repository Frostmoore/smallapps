# StatusMicroApps — build e pubblicazioni

> Dove sta ogni app sugli store, quale build c'è dove, e cosa manca per accendere i pulsanti del
> sito. **Si aggiorna a ogni invio, approvazione, rifiuto o rilascio**, con la data.
>
> Il sito segue questo file: un pulsante store si accende (`suPlay` / `suAppStore` in
> `site/src/apps.php`) **solo** quando qui la riga dice «pubblicata» per quello store **e per
> l'Italia**.

Ultimo aggiornamento: **2026-10-06**

---

## Riepilogo

| App | Versione | Google Play | App Store | Sito: pulsanti |
|---|---|---|---|---|
| **TrashCan** | 1.0.0 (11) | 🟡 in revisione (produzione) | 🟠 pubblicata, **tranne UE** | spenti («Presto su Google Play e App Store») |
| **Full Freezer** | — | ⚪ non iniziata | ⚪ non iniziata | card grigia «In arrivo» |
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
| entro 2026-10-06 | Inviata in **produzione** — ⚠️ con la **build 10** |
| 2026-10-06 | Stato: **in revisione** |

⚠️ **Da verificare:** la build 10 ha il difetto della rotellina infinita sul paywall, corretto
nella **11** (`apps/trashcan/store/trashcan-1.0.0-11.aab`). Se in produzione c'è ancora la 10,
va sostituita con la 11 (nuova release di produzione con l'AAB 11) prima o subito dopo
l'approvazione.

**Per accendere il pulsante sul sito:** app visibile su Play dall'Italia → `suPlay => true`.

### App Store

| Data | Evento |
|---|---|
| entro 2026-10-06 | Build 10 inviata · respinta 2.1 (richiesta informazioni) |
| 2026-10-06 | Accordo app a pagamento attivo; il prezzo del Pro arriva in sandbox dalle 12:13 |
| 2026-10-06 | Build 11 + TrashCan Pro inviati insieme (12:41) |
| 2026-10-06 | **Approvata**, rilascio automatico: «Pronta per la distribuzione» |
| 2026-10-06 | In vendita in **148 paesi**; nei **27 paesi UE (Italia compresa)** bloccata con `TRADER_STATUS_NOT_PROVIDED` |

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

Non iniziata. Pacchetto previsto `com.smp.fullfreezer`, Pro `fullfreezer_pro_lifetime`.
Fase F4 di `develop_microapps.md`.

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

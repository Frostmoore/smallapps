# Scheda App Store — Full Freezer

> Tutto quello che serve per compilare App Store Connect. **Le parti segnate «API» le carica
> `tool/scheda_app_store_ff.py` sul Mac**; le altre si fanno a mano.
> **Aggiornato al**: 2026-10-07 · **Versione**: `1.0.0 (1)` · **Bundle ID**: `com.smp.fullfreezer`
> · **ID Apple**: `6820155659` · **IAP**: `6820155793`
>
> ⚑ Ogni testo e' controllato contro il limite del campo: il conteggio e' scritto sotto.

---

## 1. File

| File | Dove va |
|---|---|
| `grafiche/appstore-6.5/it/*.png` | Versione, Italiano → screenshot **iPhone 6,5"** (1284×2778), in quest'ordine — API |
| `grafiche/appstore-6.5/en/*.png` | Versione, Inglese (Regno Unito) → iPhone 6,5" — API |
| `grafiche/appstore/it|en/*.png` | Facoltative, iPhone 6,9" (1320×2868) |
| `screenshots/ios/it/paywall-revisione.png` | Acquisto in-app → screenshot per la revisione — **gia' caricato** (API, 2026-10-07) |

| `grafiche/apple/intestazione-3840x1646-it|en.png` | Versione → **Intestazione e risultati di ricerca → Intestazione** (21:9), per lingua — a mano |
| `grafiche/apple/ricerca-3840x2560-it|en.png` | Versione → **Intestazione e risultati di ricerca → Risultati della ricerca** (3:2), per lingua — a mano |

⚑ Le risorse «Intestazione» e «Risultati della ricerca» sono nuove (Apple, 5 ottobre 2026): niente
trasparenza, frasi brevi e tradotte, niente prezzi, URL o ©; contenuti 4+; l'elemento chiave al
centro perche' i bordi si tagliano sui vari dispositivi. Si rigenerano con le altre grafiche.

☠ Spazio obbligatorio = **6,5"**: Apple rifiuta le 6,9" trascinate li' (lezione di TrashCan).
**Niente iPad**: l'app e' solo iPhone (`TARGETED_DEVICE_FAMILY = 1`); su iPad gira in compatibilita'.

---

## 2. Informazioni sull'app — API

| Campo | Valore |
|---|---|
| Nome (it) | `Full Freezer` |
| Nome (en-GB) | `Full Freezer – Freezer Tracker` (30 su 30): «Full Freezer» in inglese e' gia' di un altro sviluppatore |
| Sottotitolo (it) | `Il più vecchio sempre in cima` (29 su 30) |
| Sottotitolo (en-GB) | `The oldest always on top` (24 su 30) |
| Categoria principale | **Cibo e bevande** (FOOD_AND_DRINK) |
| Categoria secondaria | **Stile di vita** (LIFESTYLE) |
| URL della privacy | `https://smpmicroapps.it/legale/privacy` |
| Diritti sui contenuti | **No**, nessun contenuto di terzi — a mano |
| Classificazione per eta' | "No"/"Nessuno" a tutto, esito **4+** — a mano |
| Prezzo | **Gratuita**, tutti i paesi |

---

## 3. Pagina della versione 1.0.0 — API

### Italiano

**Testo promozionale** (129 su 170)

```
Il più vecchio sempre in cima, i giorni da quando l'hai congelato e quanto è pieno il freezer. Niente account, niente pubblicità.
```

**Descrizione** (2204 su 4000)

```
Cosa c'è nel freezer, e da quanto tempo?

Full Freezer risponde in un colpo d'occhio. Gli alimenti stanno in ordine di anzianità, il più vecchio in cima, con i giorni passati dal congelamento. Niente più sacchetti dimenticati in fondo al cassetto.

DENTRO IN TRE TOCCHI

Metti nel freezer, scrivi il nome, salva. La categoria si capisce dal nome, la data è oggi, il resto è già come l'ultima volta. Puoi anche dirlo a voce («due porzioni di lasagne») o scattare una foto per riconoscerlo dopo.

QUANTO È PIENO

Scegli il tuo freezer da una serie di modelli veri, dal cassetto del frigo al pozzetto da 350 litri. L'app stima lo spazio che occupa ogni cosa e ti dice quanto è pieno, e lo puoi correggere quando apri lo sportello.

IL WIDGET SULLA SCHERMATA INIZIALE

Le tre cose più vecchie, con i giorni. Li conta da solo ogni notte, anche se l'app non la apri mai.

TROVI TUTTO

Cerca per nome o per nota, senza badare ad accenti e maiuscole. Dividi il freezer in cassetti e ripiani e sai sempre dove guardare.

SENZA ACCOUNT, SENZA INTERNET

Niente da registrare, niente da accettare. Quello che inserisci resta sul telefono: non lo vediamo e non lo raccogliamo.

NIENTE PUBBLICITÀ

Nemmeno nella versione gratuita.

GRATIS, E POI PRO SE TI SERVE

La versione gratuita include un freezer con i suoi cassetti, l'inserimento rapido, a voce e con le foto, il riempimento, la ricerca, il widget e il ripristino da un backup.

Full Freezer Pro si sblocca con un acquisto singolo, senza abbonamento, e aggiunge:
• tutti i freezer che hai: il pozzetto in garage, quello dai tuoi
• gli avvisi: cosa sta lì da troppo, freezer quasi pieno o quasi vuoto
• lo storico di cosa hai consumato e buttato, con le statistiche dello spreco
• le tue categorie, ognuna con il suo promemoria
• l'esportazione in un foglio di calcolo e il backup completo

Se cambi iPhone, il Pro lo ripristini con il tuo ID Apple.

UNA COSA DA DIRE CHIARAMENTE

I promemoria sono un aiuto per organizzarti, non una scadenza né una garanzia di sicurezza alimentare: in caso di dubbio valgono le indicazioni sulla confezione.

Full Freezer fa parte di SMP MicroApps: app piccole, che fanno una cosa sola e la fanno bene.
https://smpmicroapps.it
```

**Parole chiave** (92 su 100)

```
freezer,congelatore,surgelati,inventario,cibo,spreco,dispensa,cucina,avanzi,frigo,promemoria
```

**URL di assistenza**: `https://smpmicroapps.it/contatti` · **URL di marketing**: `https://smpmicroapps.it`
· **Copyright**: `2026 SeeMyPage di Ronconi Riccardo`

### Inglese (Regno Unito)

**Testo promozionale** (111 su 170)

```
The oldest always on top, the days since you froze it and how full your freezer is. No account, no advertising.
```

**Descrizione** (2071 su 4000)

```
What's in your freezer, and since when?

Full Freezer answers at a glance. Items are sorted by age, the oldest on top, with the days since they were frozen. No more forgotten bags at the bottom of the drawer.

IN THE FREEZER IN THREE TAPS

Put in freezer, type the name, save. The category comes from the name, the date is today, everything else is as last time. You can also say it ("two portions of lasagne") or take a photo to recognise it later.

HOW FULL IT IS

Pick your freezer from a range of real models, from the fridge drawer to a 350-litre chest freezer. The app estimates the space each item takes and tells you how full it is, and you can correct it when you open the door.

THE HOME SCREEN WIDGET

The three oldest items, with their days. It counts them by itself every night, even if you never open the app.

FIND ANYTHING

Search by name or note, accents and capitals don't matter. Split the freezer into drawers and shelves and always know where to look.

NO ACCOUNT, NO INTERNET

Nothing to register, nothing to accept. What you enter stays on your phone: we never see it and never collect it.

NO ADVERTISING

Not even in the free version.

FREE, THEN PRO IF YOU NEED IT

The free version includes one freezer with its drawers, quick add by text, voice and photo, the fill level, search, the widget and restoring from a backup.

Full Freezer Pro unlocks with a single purchase, no subscription, and adds:
• every freezer you have: the chest in the garage, the one at your parents'
• alerts: what has been in too long, freezer nearly full or nearly empty
• the history of what you ate and threw away, with waste statistics
• your own categories, each with its own reminder
• export to a spreadsheet and full backup

Change iPhone and you restore Pro with your Apple ID.

ONE THING TO SAY PLAINLY

Reminders help you get organised; they are not an expiry date or a food safety guarantee. When in doubt, follow the instructions on the packaging.

Full Freezer is part of SMP MicroApps: small apps that do one thing and do it well.
https://smpmicroapps.it
```

**Parole chiave** (92 su 100)

```
freezer,inventory,frozen,food,waste,pantry,kitchen,leftovers,fridge,tracker,reminder,drawers
```

### Piu' in basso nella stessa pagina — a mano

| Campo | Valore |
|---|---|
| Build | `1.0.0 (1)` |
| Acquisti in-app | Seleziona **Full Freezer Pro** |
| Rilascio | Manuale |

☠ **Il primo acquisto in-app si allega dalla pagina della versione**, non via API
(`FIRST_NON_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION`, visto con TrashCan).

---

## 4. Privacy dell'app — a mano

Risposta: **«Dati non raccolti»**. La build iOS non parla con nessun server (`tool/build_ios.sh`
passa solo `BILLING=store`, non `MA_LICENSE_URL`): alimenti e foto restano sul telefono, l'acquisto
lo gestisce Apple, la voce la riconosce il telefono stesso (solo riconoscimento sul dispositivo,
mai i server di Apple: dove non c'e', il microfono dice di scrivere — decisione del 2026-10-10).

☠ Se un giorno la build iOS si collega al License Server, questa etichetta diventa falsa.

---

## 5. Informazioni per la revisione — API

Accesso richiesto: **No**. Contatto: Riccardo Ronconi, `info@smp-digital.it`.

### Note (1414 su 4000)

```
Full Freezer is a freezer inventory. No account and no login are needed: the app works fully offline and does not talk to any server.

HOW TO TRY IT
1. On first launch, pick a freezer model (for example "Fridge-freezer, 180 cm") and tap Continue.
2. Tap "Put in freezer", type a name (for example "Lasagne") and tap Save. The oldest items are always on top, with the days since they were frozen, and the header shows how full the freezer is.
3. The microphone in the name field lets you dictate "two portions of lasagne": speech is recognised on the device only (on-device recognition, never Apple's servers), the app only receives the text. If on-device recognition is not available for the language, the microphone says so and the user types the name.
4. To add the widget: touch and hold the Home Screen, tap +, search for Full Freezer.

IN-APP PURCHASE
Full Freezer Pro (fullfreezer_pro_lifetime) is a single non-consumable purchase. It unlocks more than one freezer, alerts (old items, freezer nearly full or nearly empty), full history and statistics, custom categories, CSV export and full backup. To see it: Settings > "Full Freezer Pro", or tap any item marked PRO. "Restore purchase" is in Settings.

PERMISSIONS
Camera and photos only when the user adds a photo to an item; microphone and speech recognition only when the user taps the microphone; notifications only when the user turns alerts on (Pro).
```

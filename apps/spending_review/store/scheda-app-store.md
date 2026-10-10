# Scheda App Store — Spending Review

> Tutto quello che serve per compilare App Store Connect. **Le parti segnate «API» le carica
> `tool/scheda_app_store.py` sul Mac**; le altre si fanno a mano.
> **Aggiornato al**: 2026-10-10 · **Versione**: `1.0.0` (build `1`) · **Bundle ID**:
> `com.smp.spendingreview` · **ID Apple**: `6821392694` · **IAP**: `spendingreview_pro_lifetime`
>
> ⚑ Ogni testo e' controllato contro il limite del campo: il conteggio e' scritto sotto.
> ⚑ L'ordine dei blocchi di codice e' quello che legge lo script (`testi()`): promo, descrizione,
> parole chiave in italiano, poi in inglese, poi le note per la revisione. Non aggiungerne altri
> in mezzo.

---

## 1. File

| File | Dove va |
|---|---|
| `grafiche/appstore-6.5/it/*.png` | Versione, Italiano → screenshot **iPhone 6,5"** (1284×2778), in quest'ordine — API |
| (ordine delle 6 schede) | `01-spesa` (totale e budget, tastierino), `02-cartellino` (foglio di conferma con barrato ed €/kg), `03-bilancia`, `04-scontrino` (confronto alla cassa, Pro), `05-statistiche` (budget del mese, Pro), `06-storico`. Lo script **sostituisce** l'insieme se i file locali sono cambiati |
| `grafiche/appstore-6.5/en/*.png` | Versione, Inglese (Regno Unito) → iPhone 6,5" — API |
| `grafiche/appstore/it|en/*.png` | Versione → screenshot **iPhone 6,9"** (1320×2868, `APP_IPHONE_67`) — API |
| `grafiche/play/it|en/*.png` | Google Play, 1080×2160 (non caricate: Play e' un'altra pratica) |
| `grafiche/testata-1024x500-it|en.png` | Google Play, grafica in primo piano |
| `video/anteprima-886x1920-it|en.mp4` | Versione → **Anteprime app** iPhone 6,5", per lingua (H.264, 30 fps, audio muto, ~27 s) — API |
| `screenshots/ios/it/paywall-revisione.png` | Acquisto in-app → screenshot per la revisione — API |
| `grafiche/apple/intestazione-3840x1646-it|en.png` | Versione → **Intestazione e risultati di ricerca → Intestazione** (21:9), per lingua — a mano |
| `grafiche/apple/ricerca-3840x2560-it|en.png` | Versione → **Intestazione e risultati di ricerca → Risultati della ricerca** (3:2), per lingua — a mano |

Come si rifanno (da `apps/spending_review`):

1. Screenshot veri: `ssh mac 'bash ~/microapps/tool/screenshots_ios.sh 2E0C5359-ACED-45E8-8DD3-0ECB0C0BAF85 it|en ~/sr_shots/<lingua> spending_review'`
   (lo script aggiunge da solo `SR_DEMO=true`), poi copiarli in `screenshots/ios/<lingua>/`
   (con `COPYFILE_DISABLE=1 tar`, altrimenti arrivano i file `._*` di macOS).
2. `python tool/genera_grafiche_store.py`.
3. Video: `ssh mac 'bash ~/microapps/apps/spending_review/tool/anteprima_app_store.sh <UDID> it|en'`, copia
   di `~/anteprima_sr_<lingua>.mov` in `video/`, `pwsh tool/converti_anteprima.ps1`.
4. Caricamento: `ssh mac 'cd ~/microapps && python3 -u apps/spending_review/tool/scheda_app_store.py'`.

☠ Spazio obbligatorio = **6,5"**: Apple rifiuta le 6,9" trascinate li' (lezione di TrashCan).
**Niente iPad**: l'app e' solo iPhone (`TARGETED_DEVICE_FAMILY = 1`); su iPad gira in compatibilita'.
⚑ **Il paywall non sta nelle schede**: il prezzo cambia da paese a paese. Serve solo come
screenshot di revisione dell'acquisto in-app.
⚑ **Cartellino, bilancia e scontrino delle schede sono letture finte** (`integration_test/letture_finte.dart`)
passate ai parser veri: il simulatore non ha la fotocamera. I fogli fotografati sono quelli veri.

---

## 2. Informazioni sull'app — API

| Campo | Valore |
|---|---|
| Nome (it) | `Spending Review` (15 su 30), accettato da Apple alla creazione dell'app |
| Nome (en-GB) | `Spending Review` (15 su 30); se Apple risponde 409 DUPLICATE.DIFFERENT_ACCOUNT lo script ripiega da solo su `Spending Review – Cart Total` (28 su 30, ripiego deciso in F12.0 punto 1; in italiano il ripiego sarebbe `Spending Review – Conto spesa`) |
| Sottotitolo (it) | `Conto della spesa e budget` (26 su 30) |
| Sottotitolo (en-GB) | `Grocery total and budget` (24 su 30) |
| Categoria principale | **Finanza** (FINANCE) |
| Categoria secondaria | **Utilita'** (UTILITIES) |
| URL del supporto | `https://smpmicroapps.it/contatti` |
| URL di marketing | `https://smpmicroapps.it` |
| URL della privacy | `https://smpmicroapps.it/legale/privacy` |
| Diritti sui contenuti | **No**, nessun contenuto di terzi — API |
| Classificazione per eta' | "No"/"Nessuno" a tutto (24 campi) — API (`eta()`); esito verificato **4+** il 2026-10-10 |
| Prezzo | **Gratuita**, tutti i paesi — API |
| Privacy (etichetta) | **Dati non raccolti** — a mano |

⚑ **Perche' Finanza + Utilita'** (e non Shopping): su App Store «Shopping» e' la categoria dei negozi
e dei marketplace (si compra dentro l'app); chi cerca un'app che tiene il conto di quanto spende e del
budget la trova in **Finanza**, dove stanno i «budget» e gli «spending tracker». **Utilita'** come
seconda perche' alla cassa l'app e' uno strumento (tastierino, lettore di cartellini), non una
vetrina. Le alternative scartate: Shopping (fuori luogo, nessun acquisto di merce), Produttivita'
(troppo generica), Cibo e bevande (ricette e consegne).
⚑ Il sottotitolo **non** contiene «Project Microapps»: si aggiungera' a tutte le app insieme.

---

## 3. Pagina della versione 1.0.0 — API

### Italiano

**Testo promozionale** (159 su 170)

```
Batti il prezzo o inquadra il cartellino: il totale della spesa sale subito e il budget è sempre in vista. Con una mano sola, senza account e senza pubblicità.
```

**Descrizione** (2186 su 4000)

```
Spending Review è il conto della spesa che usi con una mano sola, col carrello nell'altra. Batti il prezzo sul tastierino, sempre sullo schermo, o inquadra il cartellino: il totale enorme in alto sale subito e la barra ti dice quanto manca al budget. Alla cassa sai già quanto pagherai.

IL TASTIERINO DELLA CASSA
• 2 4 9 fa 2,49, come alla cassa: la virgola non serve
• × per la quantità, − per uno sconto o un buono, + per aggiungere
• Tocca una riga per correggerla, scorrila per toglierla

IL CARTELLINO, INTERPRETATO
• Nome, prezzo da pagare, prezzo barrato o «anziché», prezzo al kg o al litro
• Le offerte: 3x2, 2x1, −30%, il secondo a metà prezzo
• Se il cartellino ha il prezzo con la carta fedeltà e quello senza, scegli tu con un tocco
• Niente entra nel conto da solo: controlli e tocchi Aggiungi
• Anche da una foto che hai già scattato

PRODOTTI A PESO
• Scrivi il peso dopo un prezzo al kg, oppure inquadra l'etichetta della bilancia: peso, prezzo al kg e totale, senza fare conti

LO STORICO
• Chiudi la spesa con il negozio e la data
• Le ultime 5 spese sempre a portata

SPENDING REVIEW PRO
Un acquisto unico, niente abbonamento:
• Lo scontrino alla cassa: fotografalo e l'app lo confronta con il tuo conto, riga per riga. Ti mostra la differenza e le righe da guardare: un prezzo diverso dal cartellino, un articolo battuto due volte, il sacchetto
• Registra una spesa direttamente dallo scontrino, anche se non hai contato niente
• Tutte le spese, non solo le ultime 5: le altre sono già sul telefono
• Statistiche per mese e per negozio, spesa media, sforamenti del budget e un budget del mese
• Esporta in CSV ogni articolo di ogni spesa
• Backup dello storico, da tenere o portare su un telefono nuovo

La versione gratuita comprende il tastierino, il budget, la lettura dei cartellini senza limiti, il peso e l'etichetta della bilancia, le ultime 5 spese e il ripristino da un backup.

I cartellini, le etichette e gli scontrini si leggono sul telefono: le foto si cancellano appena lette e il testo non si salva. Gli scritti a mano non si leggono: per quelli c'è il tastierino.

Niente account, niente pubblicità, nessun dato raccolto: tutto resta sul telefono.
```

**Parole chiave** (97 su 100)

```
spesa,supermercato,scontrino,cartellino,prezzi,calcolatrice,carrello,offerte,bilancia,conto,spese
```

### Inglese (Regno Unito)

**Testo promozionale** (151 su 170)

```
Tap in the price or point at the price tag: your grocery total goes up at once and the budget is always in sight. One hand only, no account and no ads.
```

**Descrizione** (2062 su 4000)

```
Spending Review is the grocery total you keep with one hand, with the trolley in the other. Tap the price on the keypad, always on screen, or point at the price tag: the big total at the top goes up at once and the bar tells you how much budget is left. At the till you already know what you will pay.

A TILL-STYLE KEYPAD
• 2 4 9 makes 2.49, just like at the till: no decimal point needed
• × for quantity, − for a discount or a voucher, + to add
• Tap a line to fix it, swipe it to remove it

THE PRICE TAG, UNDERSTOOD
• Name, price to pay, crossed-out price, price per kg or per litre
• Offers: 3 for 2, 2 for 1, −30%, second one half price
• If the tag shows a loyalty card price and a normal one, you choose with one tap
• Nothing goes in by itself: you check and tap Add
• From a photo you already took, too

SOLD BY WEIGHT
• Type the weight after a per-kg price, or point at the scale label: weight, price per kg and total, no maths

YOUR HISTORY
• Close each shopping trip with the shop and the date
• Your last 5 trips always at hand

SPENDING REVIEW PRO
One purchase, no subscription:
• The receipt at the till: take a photo and the app compares it with your count, line by line. It shows the difference and the lines to check: a price that differs from the tag, an item scanned twice, the bag
• Record a shopping trip straight from the receipt, even if you counted nothing
• All your trips, not just the last 5: the others are already on your phone
• Statistics by month and by shop, average spend, budget overruns and a monthly budget
• Export every item of every trip to CSV
• Back up your history, to keep or to move to a new phone

The free version includes the keypad, the budget, unlimited price tag reading, weights and scale labels, your last 5 trips and restoring from a backup.

Price tags, scale labels and receipts are read on your phone: photos are deleted as soon as they are read and the text is never saved. Handwriting can't be read: for that there's the keypad.

No account, no ads, no data collected: everything stays on your phone.
```

**Parole chiave** (99 su 100)

```
grocery,shopping,budget,receipt,price,tag,calculator,trolley,cart,supermarket,expense,tracker,scale
```

### Note per la revisione (inglese, 2108 su 4000)

```
No account is needed: everything is stored on the device. Price tags, scale labels and receipts are read on the device with Apple's Vision framework (no network); photos are deleted right after reading and the recognised text is never stored.

Main flow (free): the keypad is always on the main screen. It works like a till: "2 4 9" is 2.49, "×" sets a quantity (e.g. "3 × 1 2 9"), "−" enters a discount, "+" adds the line. The big total at the top goes up and the bar shows the budget (tap the line above the total to set one).

Price tag (free, unlimited): tap "Price tag". The camera opens (permission requested only then); frame one shelf price tag up close and take the photo, or tap "From a photo" to pick an image with the system photo picker. A sheet shows the name, the price, any offer (crossed-out price, 3 for 2, -30%) and the price per kg; nothing is added until you tap "Add". Handwritten tags cannot be read: the app says so and the keypad is used instead.

Scale label (free): the same "Price tag" button recognises a printed scale label (weight, price per kg, total) by itself; the viewfinder also has a "Scale" switch. After a per-kg price tag, a weight sheet appears, with "Read the scale label".

In-app purchase spendingreview_pro_lifetime (non-consumable) unlocks: the Receipt (comparing the receipt with the counted lines, and recording a shopping trip straight from the receipt), all past shopping trips instead of the last 5, statistics with a monthly budget, CSV export and backup (restoring stays free). To test it: tap "Receipt" on the main screen, or Settings > Pro. The purchase works with a Sandbox account; "Restore purchase" is on the same screen.

After the purchase: tap "Receipt", photograph the receipt straight (one or more photos for a long one) and tap "Read": "Receipt vs your count" shows the difference and the lines to check; "Close the shopping trip" saves it. With nothing counted, the receipt is recorded as a new shopping trip. Statistics: the history icon at the top, then the chart icon.

The app is iPhone only; on iPad it runs in iPhone compatibility mode.
```

---

## 4. Acquisto in-app — API

| Campo | Valore |
|---|---|
| Tipo | Non consumabile |
| Nome di riferimento | `Spending Review Pro` |
| ID prodotto | `spendingreview_pro_lifetime` (id Apple `6821405107`, `READY_TO_SUBMIT` dal 2026-10-10) |
| Prezzo | **2,99 €** (territorio base Italia), tutti i paesi |
| In famiglia | No |
| Nome visualizzato (it / en-GB) | `Spending Review Pro` (19 su 30) |
| Descrizione (it) | `Scontrino, tutte le spese, statistiche, CSV, backup` (51 su 55) |
| Descrizione (en-GB) | `Receipt check, full history, stats, CSV, backup` (47 su 55) |
| Screenshot per la revisione | `screenshots/ios/it/paywall-revisione.png` |

☠ **Testi e screenshot di revisione dell'IAP si cambiano via API solo finche' il prodotto non e'
`READY_TO_SUBMIT`**: dopo, Apple risponde 409 UNMODIFIABLE / MEDIA_ASSET_DELETE_NOT_ALLOWED (lezione di
QR Me, 2026-10-09) e vanno cambiati a mano. Lo script lo segnala in «DA FARE A MANO».

☠ Il primo acquisto in-app di un'app si invia **insieme alla versione**, dalla sua pagina
(FIRST_NON_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION): va spuntato a mano prima di inviare.

---

## 5. TestFlight

| Cosa | Valore |
|---|---|
| Gruppo interno | `Sviluppatore` (`253f7667-2b46-4b77-8cb9-f86b16000ae5`), accesso a tutte le build |
| Tester | il proprietario (`d38588af-93f1-4fcf-b4fb-0845580d09a2`), invito `a9861252-c8bc-45f0-8632-03eb8f30825e` mandato il 2026-10-10 |
| Build | `1.0.0 (1)`, `470a0092-7449-4e6d-a212-3c121b0b85fe`, VALID |

☠ Metodo che funziona: email e nome da un `betaTester` gia' esistente del proprietario, poi
`POST /v1/betaTesters` con la relazione al gruppo (un 500 e' temporaneo: si riprova), poi `POST
/v1/betaTesterInvitations`. Aggiungere al gruppo un tester esistente da' 409.

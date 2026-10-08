# Scheda App Store — Film Tracker

> Tutto quello che serve per compilare App Store Connect. **Le parti segnate «API» le carica
> `tool/scheda_app_store.py` sul Mac**; le altre si fanno a mano.
> **Aggiornato al**: 2026-10-08 · **Versione**: `1.0.0` · **Bundle ID**: `com.smp.filmtracker`
> · **ID Apple**: `6820633385` · **IAP**: `filmtracker_pro_lifetime`
>
> ⚑ Ogni testo e' controllato contro il limite del campo: il conteggio e' scritto sotto.

---

## 1. File

| File | Dove va |
|---|---|
| `grafiche/appstore-6.5/it/*.png` | Versione, Italiano → screenshot **iPhone 6,5"** (1284×2778), in quest'ordine — API |
| `grafiche/appstore-6.5/en/*.png` | Versione, Inglese (Regno Unito) → iPhone 6,5" — API |
| `grafiche/appstore/it|en/*.png` | Facoltative, iPhone 6,9" (1320×2868) |
| `video/anteprima-886x1920-it|en.mp4` | Versione → **Anteprime app** iPhone 6,5", per lingua (~21 s, H.264, 30 fps, audio muto) — API |
| `screenshots/ios/it/paywall-revisione.png` | Acquisto in-app → screenshot per la revisione — API |
| `grafiche/apple/intestazione-3840x1646-it|en.png` | Versione → **Intestazione e risultati di ricerca → Intestazione** (21:9), per lingua — a mano |
| `grafiche/apple/ricerca-3840x2560-it|en.png` | Versione → **Intestazione e risultati di ricerca → Risultati della ricerca** (3:2), per lingua — a mano |

Come si rifanno:

1. Screenshot veri: `ssh mac 'bash ~/microapps/tool/screenshots_ios.sh <UDID 18 Pro Max> it|en ~/microapps/apps/film_tracker/store/screenshots/ios/<lingua> film_tracker'`, poi copiarli qui. I dati di esempio hanno le foto disegnate (`lib/dev/demo_photos.dart`).
2. `python tool/genera_grafiche_store.py`. ☠ Space Mono non ha il glifo "▸": lo script lo disegna come triangolino.
3. Video: `tool/anteprima_app_store.sh` sul Mac, copia dei `.mov` in `video/`, `pwsh tool/converti_anteprima.ps1`.

☠ Spazio obbligatorio = **6,5"**: Apple rifiuta le 6,9" trascinate li' (lezione di TrashCan).
**Niente iPad**: l'app e' solo iPhone (`TARGETED_DEVICE_FAMILY = 1`); su iPad gira in compatibilita'.

☠ **TestFlight: aggiungere il tester al gruppo interno NON manda l'invito.** Va mandato a parte
con `POST /v1/betaTesterInvitations` (lezione di Scorte Calore).

---

## 2. Informazioni sull'app — API

| Campo | Valore |
|---|---|
| Nome (it) | `Film Tracker` |
| Nome (en-GB) | `Film Tracker` |
| Sottotitolo (it) | `Diario dei rullini analogici` (28 su 30) |
| Sottotitolo (en-GB) | `Your analogue film roll diary` (29 su 30) |
| Categoria principale | **Foto e video** (PHOTO_AND_VIDEO) |
| Categoria secondaria | **Stile di vita** (LIFESTYLE) |
| URL della privacy | `https://smpmicroapps.it/legale/privacy` |
| Diritti sui contenuti | **No**, nessun contenuto di terzi — API |
| Classificazione per eta' | "No"/"Nessuno" a tutto, esito **4+** — a mano |
| Prezzo | **Gratuita**, tutti i paesi — API |
| Privacy (etichetta) | **Dati non raccolti** — a mano |

---

## 3. Pagina della versione 1.0.0 — API

### Italiano

**Testo promozionale** (150 su 170)

```
Ogni rullino, dal carico in macchina al foglio provini: pellicola, sviluppo, stampe, costi e foto. E un'etichetta QR per il barattolo. Niente account.
```

**Descrizione** (1699 su 4000)

```
Film Tracker è il diario dei tuoi rullini analogici: sai sempre cosa c'è in macchina, cosa aspetta in laboratorio e cosa è già nell'archivio.

Quando carichi un rullino scegli la pellicola dal catalogo (Kodak, Ilford, Fujifilm, Fomapan, Cinestill e altre, più le tue), la macchina e l'ISO a cui lo esponi. Da lì Film Tracker lo segue passo per passo: terminato, consegnato al laboratorio, sviluppato, stampato.

IN TRE SEZIONI
• In macchina: i rullini caricati e da quanti giorni
• In laboratorio: cosa aspetta lo sviluppo, chi aspetta da più tempo in cima
• Archivio: un foglio provini con le foto di ogni rullino

OGNI RULLINO HA LA SUA STORIA
• Una cronologia con date e costi: pellicola, sviluppo, scansioni, stampe
• Lo sviluppo in laboratorio o in casa, e quante stampe vuoi
• Le foto dei provini, delle stampe o delle scansioni, con lo zoom
• Il rullino tirato o trattenuto: l'ISO di esposizione accanto a quello nominale

L'ETICHETTA QR
Ogni rullino ha un'etichetta da stampare o fotografare e attaccare al barattolo. Inquadrandola con la fotocamera, l'app si apre su quel rullino: niente più rullini scambiati.

FILM TRACKER PRO
Un acquisto unico, niente abbonamento:
• Tutte le tue macchine fotografiche
• Statistiche dell'anno: rullini, spesa per pellicola, sviluppo e stampe, costo medio per rullino
• Il riepilogo dell'anno in PDF, da stampare, con le foto
• Esportazione in un foglio di calcolo e backup completo, foto comprese

La versione gratuita comprende rullini illimitati, una macchina, il catalogo delle pellicole, sviluppo e stampe, tutte le foto, l'etichetta QR e il ripristino da un backup.

Niente account, niente pubblicità, nessun dato raccolto: tutto resta sul telefono.
```

**Parole chiave** (100 su 100)

```
pellicola,analogico,rullino,35mm,120,sviluppo,provino,kodak,ilford,portra,fotografia,stampe,negativi
```

### Inglese (Regno Unito)

**Testo promozionale** (146 su 170)

```
Every roll, from loading the camera to the contact sheet: film, developing, prints, costs and photos. And a QR label for the canister. No account.
```

**Descrizione** (1543 su 4000)

```
Film Tracker is the diary of your film rolls: you always know what's in the camera, what's waiting at the lab and what's already in the archive.

When you load a roll, pick the film from the catalogue (Kodak, Ilford, Fujifilm, Fomapan, Cinestill and more, plus your own), the camera and the ISO you shoot it at. From there Film Tracker follows it step by step: finished, at the lab, developed, printed.

IN THREE SECTIONS
• In camera: the rolls you've loaded and for how many days
• At the lab: what's waiting to be developed, longest wait on top
• Archive: a contact sheet with the photos of every roll

EVERY ROLL HAS ITS STORY
• A timeline with dates and costs: film, developing, scans, prints
• Lab or home developing, and as many print orders as you like
• Photos of the contact sheet, prints or scans, with zoom
• Pushed or pulled rolls: the ISO you shot at next to the box speed

THE QR LABEL
Every roll gets a label to print or photograph and stick on the canister. Scan it with the camera and the app opens on that roll: no more mixed-up rolls.

FILM TRACKER PRO
One purchase, no subscription:
• All your cameras
• Yearly statistics: rolls, spending on film, developing and prints, average cost per roll
• Your year as a printable PDF, with the photos
• Spreadsheet export and full backup, photos included

The free version includes unlimited rolls, one camera, the film catalogue, developing and prints, all the photos, the QR label and restoring from a backup.

No account, no ads, no data collected: everything stays on your phone.
```

**Parole chiave** (98 su 100)

```
film,analogue,analog,35mm,120,roll,developing,contact sheet,kodak,ilford,portra,darkroom,negatives
```

### Note per la revisione (inglese)

```
No account is needed: everything is stored on the device.

To see the app with data: tap "New roll", pick a film and save; open the roll and use "Roll finished", then "Deliver to the lab" to record developing. Photos can be added from the camera or the photo library in the roll's Photos section. The QR label is under the roll's details.

In-app purchase filmtracker_pro_lifetime (non-consumable) unlocks: more than one camera, yearly statistics and costs, the yearly PDF summary, CSV export and full backup. To test it: Settings > Film Tracker Pro, or tap any item marked PRO.

Camera and photo library access are requested only when the user adds a photo to a roll.
```

---

## 4. Acquisto in-app — API

| Campo | Valore |
|---|---|
| Tipo | Non consumabile |
| Nome di riferimento | `Film Tracker Pro` |
| ID prodotto | `filmtracker_pro_lifetime` |
| Prezzo | **4,99 €** (territorio base Italia), tutti i paesi |
| In famiglia | No |
| Nome visualizzato (it / en-GB) | `Film Tracker Pro` |
| Descrizione (it) | `Macchine, statistiche, PDF dell'anno, CSV e backup` (50 su 55) |
| Descrizione (en-GB) | `Cameras, statistics, yearly PDF, CSV and backup` (47 su 55) |
| Screenshot per la revisione | `screenshots/ios/it/paywall-revisione.png` |

☠ Il primo acquisto in-app di un'app si invia **insieme alla versione**, dalla sua pagina
(FIRST_NON_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION): va spuntato a mano prima di inviare.

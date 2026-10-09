# Scheda App Store — QR Me

> Tutto quello che serve per compilare App Store Connect. **Le parti segnate «API» le carica
> `tool/scheda_app_store.py` sul Mac**; le altre si fanno a mano.
> **Aggiornato al**: 2026-10-09 · **Versione**: `1.0.0` · **Bundle ID**: `com.smp.qrme`
> · **ID Apple**: `6821086416` · **IAP**: `qrme_pro_lifetime`
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
| (ordine delle 6 schede) | `01-qr`, `02-home`, `03-lettura`, `04-modulo` (le tre strade del Wi-Fi), `05-stile`, `06-etichetta`. Niente SMS né Telefono (tolti in F17.10). Lo script **sostituisce** l'insieme se i file locali sono cambiati |
| `grafiche/appstore-6.5/en/*.png` | Versione, Inglese (Regno Unito) → iPhone 6,5" — API |
| `grafiche/appstore/it|en/*.png` | Versione → screenshot **iPhone 6,9"** (1320×2868, `APP_IPHONE_67`) — API |
| `grafiche/play/it|en/*.png` | Google Play, 1080×2160 (non caricate: Play e' un'altra pratica) |
| `grafiche/testata-1024x500-it|en.png` | Google Play, grafica in primo piano |
| `video/anteprima-886x1920-it|en.mp4` | Versione → **Anteprime app** iPhone 6,5", per lingua (H.264, 30 fps, audio muto) — API |
| `screenshots/ios/it/paywall-revisione.png` | Acquisto in-app → screenshot per la revisione — API |
| `grafiche/apple/intestazione-3840x1646-it|en.png` | Versione → **Intestazione e risultati di ricerca → Intestazione** (21:9), per lingua — a mano |
| `grafiche/apple/ricerca-3840x2560-it|en.png` | Versione → **Intestazione e risultati di ricerca → Risultati della ricerca** (3:2), per lingua — a mano |

Come si rifanno:

1. Screenshot veri: `ssh mac 'bash ~/microapps/tool/screenshots_ios.sh 2E0C5359-ACED-45E8-8DD3-0ECB0C0BAF85 it|en ~/qrme_scatti_<lingua> qr_me'`
   (lo script aggiunge da solo `QM_DEMO=true`), poi copiarli in `screenshots/ios/<lingua>/`.
2. `python tool/genera_grafiche_store.py` (dalla cartella `apps/qr_me`).
3. Video: `ssh mac 'bash ~/microapps/apps/qr_me/tool/anteprima_app_store.sh <UDID> it|en'`, copia di
   `~/anteprima_qm_<lingua>.mov` in `video/`, `pwsh tool/converti_anteprima.ps1`.
4. Caricamento: `ssh mac 'cd ~/microapps && python3 -u apps/qr_me/tool/scheda_app_store.py'`.

☠ Spazio obbligatorio = **6,5"**: Apple rifiuta le 6,9" trascinate li' (lezione di TrashCan).
**Niente iPad**: l'app e' solo iPhone (`TARGETED_DEVICE_FAMILY = 1`); su iPad gira in compatibilita'.
⚑ **Il paywall non sta nelle schede**: il prezzo cambia da paese a paese. Serve solo come
screenshot di revisione dell'acquisto in-app.

---

## 2. Informazioni sull'app — API

| Campo | Valore |
|---|---|
| Nome (it) | `QR Me` (5 su 30) |
| Nome (en-GB) | `QR Me – Share & Scan` (20 su 30): «QR Me» in inglese e' gia' di un altro account (409 DUPLICATE.DIFFERENT_ACCOUNT, 2026-10-09); ripiego deciso in F17.0 punto 1. Sotto l'icona resta «QR Me» |
| Sottotitolo (it) | `Condividi, mostra e leggi QR` (28 su 30) |
| Sottotitolo (en-GB) | `Share, show and scan QR codes` (29 su 30) |
| Categoria principale | **Utilita'** (UTILITIES) |
| Categoria secondaria | **Produttivita'** (PRODUCTIVITY) |
| URL del supporto | `https://smpmicroapps.it/contatti` |
| URL della privacy | `https://smpmicroapps.it/legale/privacy` |
| Diritti sui contenuti | **No**, nessun contenuto di terzi — API |
| Classificazione per eta' | "No"/"Nessuno" a tutto (24 campi, NONE/false), esito atteso **4+** — API (`eta()`); da ricontrollare a occhio |
| Prezzo | **Gratuita**, tutti i paesi — API |
| Privacy (etichetta) | **Dati non raccolti** — a mano |

⚑ Il sottotitolo **non** contiene «Project Microapps»: si aggiungera' a tutte le app insieme.

---

## 3. Pagina della versione 1.0.0 — API

### Italiano

**Testo promozionale** (134 su 170)

```
Condividi un link o un testo da qualunque app e scegli QR Me: il QR è già lì, grande e luminoso. E legge i QR, gratis. Niente account.
```

**Descrizione** (1738 su 4000)

```
QR Me trasforma in un QR qualunque cosa gli condividi. Da Safari, dalle Note o da una chat tocchi Condividi, scegli QR Me e il QR è già lì: a tutto schermo, con la luminosità al massimo, pronto da far inquadrare.

Puoi anche scrivere o incollare un testo o un link, e mostrarlo subito come QR.

LEGGE ANCHE I QR, GRATIS
• Con la fotocamera, o da un'immagine: una foto o uno screenshot con un QR dentro
• Un link letto non si apre mai da solo: vedi prima il sito, in grande
• Copi, apri, chiami o scrivi con un tocco
• Ogni QR letto puoi rimostrarlo e salvarlo

PREFERITI E CRONOLOGIA
• Il Wi-Fi di casa o il tuo contatto sempre a portata, con il loro nome
• La cronologia degli ultimi QR, che puoi spegnere o cancellare quando vuoi
• Sotto il QR del Wi-Fi la password resta nascosta

QR ME PRO
Un acquisto unico, niente abbonamento:
• Il Wi-Fi senza scrivere niente: dal QR della rete, da uno screenshot o dalla rete a cui sei connesso. Gli ospiti entrano solo inquadrando
• Il tuo contatto dalla rubrica, salvato una volta e sempre pronto, e un'email precompilata
• Lo stile: i tuoi colori, puntini e angoli rotondi, e al centro una foto, un'icona o un'emoji. L'app rilegge il QR e ti dice se si legge ancora
• Rigenera con il tuo stile un QR che hai letto
• Condividi il QR come immagine, o come etichetta da stampare con il tuo testo sotto
• Preferiti e cronologia senza limite
• Backup completo, loghi compresi

La versione gratuita comprende la condivisione, il QR a tutto schermo, testi e link, la lettura dalla fotocamera e dalle immagini, gli ultimi 5 QR in cronologia, un preferito e il ripristino da un backup.

Niente account, niente pubblicità, nessun dato raccolto: la lettura avviene dentro l'app e tutto resta sul telefono.
```

**Parole chiave** (97 su 100)

```
codice,scanner,generatore,wifi,password,condividi,vcard,contatto,link,leggi,ospiti,logo,etichetta
```

### Inglese (Regno Unito)

**Testo promozionale** (140 su 170)

```
Share a link or some text from any app and pick QR Me: the QR is already there, big and bright. It reads QR codes too, for free. No account.
```

**Descrizione** (1660 su 4000)

```
QR Me turns anything you share with it into a QR code. From Safari, Notes or a chat, tap Share, pick QR Me and the QR is already there: full screen, at full brightness, ready to be scanned.

You can also type or paste some text or a link and show it as a QR straight away.

IT READS QR CODES TOO, FOR FREE
• With the camera, or from a picture: a photo or a screenshot with a QR in it
• A scanned link never opens by itself: you see the website first, in large type
• Copy, open, call or write with one tap
• Every QR you read can be shown again and saved

FAVOURITES AND HISTORY
• Your home Wi-Fi or your contact always at hand, each with its name
• A history of your latest QR codes, which you can switch off or clear at any time
• Under a Wi-Fi QR the password stays hidden

QR ME PRO
One purchase, no subscription:
• Wi-Fi without typing a thing: from the network's QR code, a screenshot or the network you are on. Guests join just by scanning
• Your contact from the address book, saved once and always ready, and a pre-filled email
• Style: your colours, round dots and corners, and a photo, an icon or an emoji in the middle. The app reads the QR back and tells you if it still scans
• Restyle a QR you have scanned
• Share the QR as a picture, or as a label to print with your own text below
• Unlimited favourites and history
• Full backup, logos included

The free version includes sharing, the full-screen QR, text and links, reading from the camera and from pictures, the last 5 QR codes in history, one favourite and restoring from a backup.

No account, no ads, no data collected: reading happens inside the app and everything stays on your phone.
```

**Parole chiave** (98 su 100)

```
code,reader,scanner,generator,wifi,password,share,vcard,contact,link,label,scan,guest,logo,barcode
```

### Note per la revisione (inglese, 2026 su 4000)

```
No account is needed: everything is stored on the device, and QR codes are decoded inside the app (no network).

Main flow: in Safari (or Notes) tap Share and choose QR Me: the shared link or text is shown as a full-screen QR. In the app, you can also type or paste text in the field on the home screen and tap "Show QR code".

Reading: "Read a QR code" on the home screen opens the camera (permission requested only then); "From a picture" reads a QR from an image picked with the system photo picker. Reading is free.

In-app purchase qrme_pro_lifetime (non-consumable) unlocks: the Wi-Fi, contact and pre-filled email forms, QR style (colours, shapes, logo), sharing the QR as an image or as a printable label, unlimited favourites and history, full backup. To test it: tap any of the Forms chips on the home screen (e.g. Wi-Fi), or Settings > Discover QR Me Pro. The purchase works with a Sandbox account; "Restore purchase" is on the same screen.

After the purchase:
- Wi-Fi (Forms > Wi-Fi): "Scan the network's QR code" (camera) or "From a picture" (e.g. a screenshot of a Wi-Fi QR code) read an existing network QR code and save it as a new one. "The network you're on" reads the network name (SSID) of the current Wi-Fi: iOS asks for location permission "While Using the App" first, because Apple requires it to give an app the network name (the location itself is not used or stored); the device must be connected to a Wi-Fi network. No app can read the Wi-Fi password, so the user pastes it with the "Paste the password" button. "Enter it by hand" is the last option.
- Contact (Forms > Contact): "Pick from contacts" opens the system contact picker, which needs no contacts permission (the app only receives the contact that is tapped). "Me" is the user's own card, picked or filled in once and stored in the app.
- Label: on any QR code screen, the printer icon at the top right opens "Label to print": the QR with a line of text under it, square or rectangular, then "Print" (system print dialog) or "Share image".
```

---

## 4. Acquisto in-app — API

| Campo | Valore |
|---|---|
| Tipo | Non consumabile |
| Nome di riferimento | `QR Me Pro` |
| ID prodotto | `qrme_pro_lifetime` |
| Prezzo | **1,99 €** (territorio base Italia), tutti i paesi |
| In famiglia | No |
| Nome visualizzato (it / en-GB) | `QR Me Pro` |
| Descrizione (it) | `Moduli, stile e logo, immagine ed etichetta, backup` (51 su 55) |
| Descrizione (en-GB) | `Forms, style and logo, image and label, backup` (46 su 55) |
| Screenshot per la revisione | `screenshots/ios/it/paywall-revisione.png` |

☠ **Testi e screenshot di revisione dell'IAP: a mano.** Con il prodotto in `READY_TO_SUBMIT` Apple
rifiuta via API sia la nuova descrizione (409 UNMODIFIABLE) sia la sostituzione dello screenshot (409
MEDIA_ASSET_DELETE_NOT_ALLOWED). Al 2026-10-09 in App Store Connect ci sono ancora la descrizione vecchia
(`Moduli, stile e logo, immagine, cronologia, backup` / `Forms, style and logo, image, full history, backup`)
e il paywall di prima di F17.10: vanno sostituiti a mano con i valori qui sopra e con
`screenshots/ios/it/paywall-revisione.png`. La nota di revisione dell'IAP (`IAP_NOTA`) e' gia' aggiornata.

☠ Il primo acquisto in-app di un'app si invia **insieme alla versione**, dalla sua pagina
(FIRST_NON_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION): va spuntato a mano prima di inviare.

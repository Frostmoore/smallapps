# Scheda Play Store — Full Freezer

> Tutto quello che serve per compilare Play Console, pronto da incollare.
> **Aggiornato al**: 2026-10-07 · **Versione**: `1.0.0+2` · **Pacchetto**: `com.smp.fullfreezer`
>
> ⚑ Ogni testo qui sotto e' stato controllato contro il limite del campo in cui va: il numero
> di caratteri e' scritto sotto ciascuno. Nessun segreto in questo file.

---

## 0. Prima di tutto: creare l'app

Play Console → **Crea app**:

| Campo | Valore |
|---|---|
| Nome dell'app | `Full Freezer` |
| Lingua predefinita | Italiano – it-IT |
| App o gioco | App |
| Senza costi o a pagamento | **Senza costi** (il Pro e' un acquisto in-app) |
| Dichiarazioni | spuntare le linee guida per gli sviluppatori e le leggi sull'esportazione USA |

☠ **Il prodotto Pro non si puo' creare finche' non c'e' un pacchetto caricato** che dichiara il
permesso `BILLING`: la sezione dei prodotti in-app resta bloccata. Quindi l'ordine e':
creare l'app → caricare l'AAB in **Test interno** → creare il prodotto (§9) → compilare la scheda.

---

## 1. File in questa cartella

| File | Dove va in Play Console |
|---|---|
| `full_freezer-1.0.0-2.aab` | Test → Test interno → Crea nuova versione → Carica (poi Produzione) |
| `icona-512.png` | Scheda principale dello Store → Icona dell'app |
| `grafiche/testata-1024x500-it.png` | Scheda principale (italiano) → Grafica in primo piano |
| `grafiche/testata-1024x500-en.png` | Scheda principale (inglese) → Grafica in primo piano |
| `grafiche/play/it/*.png` | Scheda italiana → Screenshot dello smartphone, **in quest'ordine** |
| `grafiche/play/en/*.png` | Scheda inglese → Screenshot dello smartphone, in quest'ordine |

⚑ Gli screenshot sono **1080×2160 (2:1)**: Play non accetta immagini in cui il lato lungo superi
il doppio del corto. Le stesse schede a 1320×2868 sono in `grafiche/appstore/`, per Apple.

⚑ Si rigenerano tutte con `python tool/genera_grafiche_store.py`, a partire dagli screenshot
veri dell'iPhone simulato (`integration_test/screenshots_test.dart` +
`tool/screenshots_ios.sh ... full_freezer`). L'interfaccia e' Flutter, identica sulle due
piattaforme; la sagoma del telefono e' neutra.

---

## 2. Dati dell'app

| Campo | Valore |
|---|---|
| Nome dell'app | `Full Freezer` |
| Nome del pacchetto | `com.smp.fullfreezer` |
| Categoria | Casa e giardino *(in alternativa: Cibo e bevande)* |
| Tag | Casa, Cucina, Organizzazione |
| Tipo | App (non gioco) |
| Gratuita o a pagamento | **Gratuita**, con acquisti in-app |
| Email di contatto | `info@smp-digital.it` |
| Sito web | `https://smpmicroapps.it` *(la pagina dell'app non esiste ancora: la card in vetrina e' grigia)* |
| Informativa privacy | `https://smpmicroapps.it/legale/privacy` |
| Lingua predefinita | Italiano (Italia) |
| Seconda lingua | Inglese (Regno Unito) |

---

## 3. Testi in italiano

### Nome

```
Full Freezer
```

*12 caratteri su 30.*

### Descrizione breve

```
Cosa c'è nel freezer e da quanto tempo: il più vecchio sempre in cima.
```

*70 caratteri su 80.*

### Descrizione completa

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

Se cambi telefono, il Pro lo ripristini dal tuo account Google.

UNA COSA DA DIRE CHIARAMENTE

I promemoria sono un aiuto per organizzarti, non una scadenza né una garanzia di sicurezza alimentare: in caso di dubbio valgono le indicazioni sulla confezione.

Full Freezer fa parte di SMP MicroApps: app piccole, che fanno una cosa sola e la fanno bene.
https://smpmicroapps.it
```

*2209 caratteri su 4000.*

---

## 4. Testi in inglese

### Descrizione breve

```
What's in your freezer and since when: the oldest always on top.
```

*64 caratteri su 80.*

### Descrizione completa

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

Change phone and you restore Pro from your Google account.

ONE THING TO SAY PLAINLY

Reminders help you get organised; they are not an expiry date or a food safety guarantee. When in doubt, follow the instructions on the packaging.

Full Freezer is part of SMP MicroApps: small apps that do one thing and do it well.
https://smpmicroapps.it
```

*2076 caratteri su 4000.*

---

## 5. Note di rilascio della versione

Italiano: `Prima versione.` · Inglese: `First release.`

---

## 6. Sicurezza dei dati (Data safety)

☠ Si dichiara sotto la propria responsabilita' e Google verifica a campione. Le risposte
descrivono la build Android **reale**: alimenti, foto e impostazioni stanno nel database e nelle
cartelle dell'app sul telefono; l'unica cosa che lascia il dispositivo e' la verifica
dell'acquisto verso il License Server (`packages/micro_core/lib/src/entitlement/`).

| Domanda | Risposta |
|---|---|
| L'app raccoglie o condivide dati utente richiesti? | **Sì** (identificativo di installazione e token d'acquisto) |
| I dati sono cifrati in transito? | **Sì**, HTTPS |
| L'utente puo' chiedere la cancellazione dei dati? | **Sì**, scrivendo a `info@smp-digital.it` |
| Dati raccolti | **ID dispositivo o altri ID**: identificativo di installazione generato dall'app, non l'ID pubblicitario. Finalita': **gestione dell'account** (verifica dell'acquisto) e **prevenzione delle frodi**. Obbligatorio. Non condiviso con terzi. |
| Foto | **Non raccolte**: restano nella cartella dell'app sul telefono (e nel backup, se l'utente lo crea e lo condivide lui) |
| Audio (voce) | **Non raccolto dall'app**: il riconoscimento lo fa il servizio vocale di sistema del telefono; l'app riceve solo il testo e non lo invia a nessuno |
| Acquisti in-app | Gestiti da Google Play. Non riceviamo dati di pagamento. |
| Posizione, contatti, file, messaggi, salute, calendario | **Nessuno** |
| Analisi d'uso, crash reporting, pubblicita' | **Nessuno**: niente Firebase, Crashlytics o SDK pubblicitari |

**Permessi che Play mostrera'**: fotocamera (solo quando si scatta una foto), microfono (solo
mentre si detta), notifiche (avvisi Pro), avvio al riavvio del telefono (per ripianificare gli
avvisi e il widget). Notifiche pianificate in locale: nessuna push remota.

---

## 7. Classificazione dei contenuti (IARC)

"No" a tutto: nessuna violenza, linguaggio, sostanze, sesso, gioco d'azzardo, condivisione di
posizione, interazione fra utenti, contenuti generati dagli utenti condivisi con altri.
Esito atteso: **PEGI 3 / Tutti**. **Unica risposta affermativa**: acquisti di beni digitali.

---

## 8. Pubblico di destinazione

- Fascia d'eta': **18 e oltre**, come TrashCan: evita i requisiti delle Families Policy.
- Nessun elemento che attragga i bambini.

---

## 9. Prodotto in-app

| Campo | Valore |
|---|---|
| ID prodotto | `fullfreezer_pro_lifetime` |
| Tipo | Prodotto a pagamento singolo (una tantum), **non** consumabile |
| Nome (it) | `Full Freezer Pro` |
| Descrizione (it) | `Più freezer, avvisi di freezer pieno o vuoto e cose vecchie, storico e statistiche, categorie tue, CSV e backup. Un pagamento unico.` |
| Nome (en) | `Full Freezer Pro` |
| Descrizione (en) | `More freezers, nearly full/empty and old-item alerts, history and statistics, your own categories, CSV and backup. One payment.` |
| Opzione d'acquisto | ID `lifetime`, tipo **Acquista** |
| Prezzo | Base **3,27 EUR** senza IVA → **3,99 € in Italia** (con il 22%), come l'App Store; Play calcola gli altri paesi |
| Stato | **Attivo** (creato il 2026-10-07) |

☠ **Il prezzo che si scrive in Play e' senza IVA**: scrivendo 3,99 l'Italia diventava 4,89 €
(3,99 + 22% e arrotondamento). Per ottenere 3,99 € al pubblico in Italia si scrive 3,27.

☠ **L'ID del prodotto non si cambia e non si riusa.** E' scritto in
`apps/full_freezer/lib/app/app_config.dart`.

---

## 10. Il pacchetto e' collegato al server

Compilato da `pwsh tool/build_release.ps1 -App full_freezer`, con `MA_LICENSE_URL` e il segreto
HMAC dell'app letti dal server e passati in un file di define temporaneo, cancellato a fine build.

☠ **Sul server l'app si chiama `fullfreezer`, non `full_freezer`.** La cartella e le preferenze
locali usano `full_freezer`; il License Server e `APP_SECRETS` usano gli id senza trattino basso.
L'app manda `licenseAppId` (`app_config.dart`) e lo script cerca il segreto con l'id senza
trattino. Trovato preparando questo pacchetto: prima ogni verifica d'acquisto sarebbe stata
rifiutata come "app sconosciuta".

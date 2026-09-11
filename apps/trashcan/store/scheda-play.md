# Scheda Play Store — TrashCan

> Tutto quello che serve per compilare Play Console, pronto da incollare.
> **Aggiornato al**: 2026-09-11 · **Versione**: `1.0.0+1` · **Pacchetto**: `com.smp.trashcan`
>
> ⚑ Questo file contiene **solo testo**. Il pacchetto firmato e le immagini stanno nella
> stessa cartella. Nessun segreto: il segreto HMAC dell'app vive solo in
> `/opt/microapps/server/.env` e viene passato al momento della compilazione.

---

## 1. File in questa cartella

| File | Dove va in Play Console |
|---|---|
| `trashcan-1.0.0-1.aab` | Versione → Test interno → Carica |
| `icona-512.png` | Scheda del negozio → Icona dell'app |
| `testata-1024x500-it.png` | Scheda del negozio (italiano) → Immagine in evidenza |
| `testata-1024x500-en.png` | Scheda del negozio (inglese) → Immagine in evidenza |
| `screenshots/it/*.png` | Scheda italiana → Screenshot per telefono |
| `screenshots/en/*.png` | Scheda inglese → Screenshot per telefono |

☠ L'icona da 512 è **opaca**: Play rifiuta la trasparenza nell'icona della scheda. È lo
stesso verde e lo stesso rientro dell'icona sul telefono, così chi vede la scheda e chi vede
il launcher vedono la stessa cosa.

---

## 2. Dati dell'app

| Campo | Valore |
|---|---|
| Nome dell'app | `TrashCan` |
| Nome del pacchetto | `com.smp.trashcan` |
| Categoria | Stile di vita |
| Tag | Casa, Promemoria, Produttività |
| Tipo | App (non gioco) |
| Gratuita o a pagamento | **Gratuita**, con acquisti in-app |
| Email di contatto | `info@smp-digital.it` |
| Sito web | `https://smpmicroapps.it/trashcan` |
| Informativa privacy | `https://smpmicroapps.it/legale/privacy` |
| Lingua predefinita | Italiano (Italia) |
| Seconda lingua | Inglese (Regno Unito) |

---

## 3. Testi in italiano

### Nome (30 caratteri max)

```
TrashCan
```

### Descrizione breve (80 caratteri max)

```
Il calendario della raccolta differenziata, con il promemoria la sera prima.
```

*75 caratteri.*

### Descrizione completa (4.000 caratteri max)

```
Stasera cosa si butta?

TrashCan risponde a questa domanda e basta. Imposti una volta i giorni di raccolta del tuo Comune e l'app ti avvisa ogni sera cosa portare fuori, mentre sei ancora in casa e non domattina, quando il camion è già passato.

COME FUNZIONA

Una procedura guidata in quattro passi: scegli i tipi di rifiuto che raccoglie il tuo Comune, tocca i giorni in cui passano e decidi l'ora del promemoria. Cinque minuti e non ci pensi più.

REGGE I CALENDARI VERI

Non tutti i Comuni hanno un giro settimanale semplice. TrashCan gestisce:
• ogni settimana, nei giorni che scegli
• a settimane alterne
• ogni due settimane a partire da una data
• una volta al mese, per posizione (il primo martedì, l'ultimo venerdì)
• date scelte a mano, una per una

LE ECCEZIONI NON TI FREGANO

Feste, sospensioni e raccolte straordinarie: segni la variazione sul singolo giorno e il promemoria si aggiusta da solo, senza toccare la regola di tutto l'anno.

IL WIDGET SULLA SCHERMATA INIZIALE

Stretto e verticale. L'intestazione colorata dice cosa si butta stasera, con la sua icona; sotto, i tre giorni successivi. Non serve nemmeno aprire l'app.

I TIPI DI RIFIUTO SONO I TUOI

Ogni Comune ha le sue categorie e i suoi nomi. Parti da quelli già pronti — organico, carta, plastica, vetro, metalli, indifferenziato, verde, pannolini — rinominali, cambia icona e colore, o creane di nuovi.

BACKUP E CONDIVISIONE

Un file che contiene tutto il calendario: lo salvi dove vuoi, lo rimetti su un altro telefono, o lo passi a un vicino di casa che ha gli stessi giorni di raccolta.

SENZA ACCOUNT, SENZA INTERNET

Non c'è niente da registrare e niente da accettare. Tutto quello che inserisci resta nella memoria del telefono: non lo vediamo e non lo raccogliamo. L'app funziona in aereo, in cantina e in un paese senza campo.

NIENTE PUBBLICITÀ

Nemmeno nella versione gratuita. Non c'è spazio per un banner in un'app che deve rispondere a una domanda in due secondi.

GRATIS, E POI PRO SE TI SERVE

La versione gratuita include un calendario, tipi di rifiuto e regole senza limiti, le eccezioni, il widget completo con la raccolta di stasera e i tre giorni successivi, l'esportazione e il backup.

TrashCan Pro si sblocca con un acquisto singolo — nessun abbonamento, nessun rinnovo — e aggiunge:
• il promemoria della sera prima
• un secondo promemoria, per le sere in cui al primo non sei in casa
• calendari multipli: casa, casa al mare, i genitori
• il colore dell'app scelto da te, fra dieci

Se cambi telefono lo ripristini dal tuo account Google. Se hai cambiato anche account, dentro l'app c'è un codice di trasferimento.

UNA COSA DA DIRE CHIARAMENTE

I giorni di raccolta li decide il tuo Comune, non l'app. TrashCan ti ricorda quello che hai inserito tu: in caso di dubbio fa fede sempre il calendario ufficiale del Comune o del gestore.

TrashCan fa parte di SMP MicroApps: app piccole, che fanno una cosa sola e la fanno bene.
https://smpmicroapps.it
```

---

## 4. Testi in inglese

### Descrizione breve (80 caratteri max)

```
Your waste collection calendar, with a reminder the evening before.
```

*66 caratteri.*

### Descrizione completa

```
What goes out tonight?

TrashCan answers that one question and nothing else. Set your council's collection days once, and the app reminds you every evening what to put out — while you are still indoors, not the next morning once the truck has gone.

HOW IT WORKS

A four-step wizard: pick the waste types your council collects, tap the days they come, and choose the time of the reminder. Five minutes and you never think about it again.

IT HANDLES REAL CALENDARS

Not every council runs a simple weekly round. TrashCan supports:
• every week, on the days you choose
• alternating weeks
• every two weeks from a start date
• monthly by position (the first Tuesday, the last Friday)
• dates picked by hand, one at a time

EXCEPTIONS DON'T CATCH YOU OUT

Public holidays, suspensions and extra collections: mark the change on that single day and the reminder adjusts itself, without touching the rule for the rest of the year.

THE HOME SCREEN WIDGET

Narrow and vertical. The coloured header says what goes out tonight, with its icon; below it, the next three days. You don't even need to open the app.

THE WASTE TYPES ARE YOURS

Every council has its own categories and its own names. Start from the ready-made ones — food, paper, plastic, glass, metal, general waste, garden, nappies — rename them, change icon and colour, or create your own.

BACKUP AND SHARING

One file holding the whole calendar: save it where you like, restore it on another phone, or pass it to a neighbour who has the same collection days.

NO ACCOUNT, NO INTERNET

There is nothing to register and nothing to accept. Everything you enter stays in your phone's storage: we never see it and never collect it. The app works on a plane, in a basement, and in a village with no signal.

NO ADVERTISING

Not even in the free version. There is no room for a banner in an app that has to answer a question in two seconds.

FREE, THEN PRO IF YOU NEED IT

The free version includes one calendar, unlimited waste types and rules, exceptions, the full widget showing tonight's collection and the next three days, export and backup.

TrashCan Pro unlocks with a single purchase — no subscription, no renewal — and adds:
• the reminder the evening before
• a second reminder, for the evenings you are not home for the first
• multiple calendars: home, the holiday house, your parents'
• the app colour, chosen by you out of ten

Change phone and you restore it from your Google account. If you changed account too, there is a transfer code inside the app.

ONE THING TO SAY PLAINLY

Collection days are decided by your council, not by the app. TrashCan reminds you of what you entered: in case of doubt, the council's official calendar always governs.

TrashCan is part of SMP MicroApps: small apps that do one thing and do it well.
https://smpmicroapps.it
```

---

## 5. Sicurezza dei dati (Data safety)

☠ È un modulo che si dichiara sotto la propria responsabilità e Google lo verifica a
campione. Le risposte qui sotto descrivono il comportamento **reale** del codice: i dati
delle app stanno nel database locale, l'unica cosa che lascia il dispositivo è la verifica
dell'acquisto (`packages/micro_core/lib/src/entitlement/`), e il server conserva le colonne
elencate in `server/src/db/schema.sql`.

| Domanda | Risposta |
|---|---|
| L'app raccoglie o condivide dati utente richiesti? | **Sì** (per l'identificativo di installazione e il token d'acquisto) |
| I dati sono cifrati in transito? | **Sì**, HTTPS |
| L'utente può chiedere la cancellazione dei dati? | **Sì**, scrivendo a `info@smp-digital.it` |
| L'app segue le Families Policy? | No, non è rivolta ai bambini |
| Dati raccolti automaticamente | **ID dispositivo o altri ID**: identificativo di installazione generato dall'app, non l'ID pubblicitario. Finalità: **gestione dell'account** (verifica dell'acquisto) e **prevenzione delle frodi**. Obbligatorio. Non condiviso con terzi. |
| Acquisti in-app | Gestiti da Google Play. Non riceviamo dati di pagamento. |
| Posizione, contatti, foto, file, messaggi, salute, calendario del dispositivo | **Nessuno** |
| Analisi d'uso, crash reporting, pubblicità | **Nessuno**. L'app non contiene Firebase Analytics, Crashlytics né SDK pubblicitari. |

**Nota sulle notifiche**: sono pianificate in locale dal sistema operativo. Non usiamo
notifiche push remote, quindi non c'è nessun token di notifica da dichiarare.

---

## 6. Classificazione dei contenuti (IARC)

Il questionario va compilato con "No" a tutto: nessuna violenza, nessun linguaggio volgare,
nessun riferimento a sostanze, nessun contenuto sessuale, nessun gioco d'azzardo, nessuna
condivisione di posizione, nessuna interazione fra utenti, nessun contenuto generato dagli
utenti. Esito atteso: **PEGI 3 / Tutti**.

**Un'unica risposta affermativa**: alla domanda se l'app consente acquisti di beni digitali.
Sì, un acquisto singolo di 2,99 €.

---

## 7. Pubblico di destinazione

- Fascia d'età: **18 e oltre** (l'app non è pensata per i minori e questo evita del tutto
  i requisiti aggiuntivi delle Families Policy).
- L'app non attrae i bambini: nessun elemento ludico, nessun personaggio, nessuna grafica
  infantile.

---

## 8. Prodotto in-app

⚠️ **Si può creare solo con il profilo pagamenti verificato.** Finché la verifica è in corso
questa sezione resta vuota e l'app funziona lo stesso: la versione gratuita è completa, e
chi tocca "Sblocca Pro" riceve un messaggio invece di uno spinner infinito (vedi §10).

| Campo | Valore |
|---|---|
| ID prodotto | `trashcan_pro_lifetime` |
| Tipo | Prodotto gestito (una tantum), **non** consumabile |
| Nome (it) | `TrashCan Pro` |
| Descrizione (it) | `Sblocca i promemoria della sera, il secondo promemoria, i calendari multipli, il backup completo e il colore dell'app. Un pagamento unico, nessun abbonamento.` |
| Nome (en) | `TrashCan Pro` |
| Descrizione (en) | `Unlocks evening reminders, the second reminder, multiple calendars, full backup and the app colour. One payment, no subscription.` |
| Prezzo | **2,99 €** (Italia), prezzi locali automatici altrove |
| Stato | Attivo |

☠ **L'ID del prodotto non si cambia e non si riusa.** È scritto in
`apps/trashcan/lib/app/app_config.dart` e registrato nel database del License Server. Se qui
si scrive un ID diverso, l'app non troverà niente da vendere e il bottone dirà "prodotto non
disponibile".

☠ Il prodotto **non diventa acquistabile** finché un pacchetto non è stato pubblicato su un
canale, anche solo interno, e possono passare alcune ore. Un `productDetails` vuoto subito
dopo la creazione non è un difetto.

---

## 9. Ordine consigliato delle operazioni

1. **Carica il pacchetto** sul canale di test interno. Non serve il profilo pagamenti.
2. **Compila la scheda del negozio** in italiano, poi aggiungi l'inglese.
3. **Sicurezza dei dati**, **classificazione dei contenuti**, **pubblico di destinazione**.
4. **Aggiungi i tester** al canale interno e provali dal link che Play genera.
5. Quando il **profilo pagamenti** è verificato: crea il prodotto in-app, aspetta qualche
   ora, aggiungi il tuo account alle **licenze di test** e prova un acquisto vero senza
   addebito.
6. Solo dopo: service account Google Cloud e Pub/Sub, per far verificare gli acquisti al
   server e far arrivare le notifiche di rimborso.

---

## 10. Cosa succede senza prodotto in-app

Verificato con due test in `packages/micro_core/test/entitlement/entitlement_service_test.dart`:

- Il catalogo torna vuoto, quindi non c'è nessun prodotto da comprare. Toccare "Sblocca Pro"
  produce **un messaggio d'errore, non uno spinner infinito**, e il bottone resta usabile.
- Se il foglio di pagamento non si apre (Play Services assenti o non aggiornati, nessun
  account Google), vale lo stesso.

⚑ È il motivo per cui si può caricare l'app **prima** che il profilo pagamenti sia pronto:
un tester che tocca il bottone vede un messaggio e va avanti, invece di trovarsi l'app
bloccata.

---

## 11. Il pacchetto è collegato al server

Il pacchetto in questa cartella è stato compilato con:

```
--dart-define-from-file=release_defines.json
```

dove il file contiene `MA_LICENSE_URL=https://lic.smpmicroapps.it` e il segreto HMAC
dell'app. **Il file viene creato e cancellato dallo script di compilazione**: non è
versionato e non deve esserlo.

☠ Il wrapper `tool/fl.ps1` chiama un file batch di Windows, che **spezza gli argomenti sui
due punti**: `--dart-define=MA_LICENSE_URL=https://...` arriva a Flutter tagliato in due e
il build fallisce con "Target file //lic.smpmicroapps.it not found". Per questo si usa il
file dei define, e il percorso del file deve essere **relativo**, senza la lettera di unità.

Senza quei due valori l'app funziona lo stesso, ma `serverEnabled` è falso: niente verifica
lato server e niente codice di trasferimento.

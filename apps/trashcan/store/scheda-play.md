# Scheda Play Store — TrashCan

> Tutto quello che serve per compilare Play Console, pronto da incollare.
> **Aggiornato al**: 2026-10-05 · **Versione**: `1.0.0+10` · **Pacchetto**: `com.smp.trashcan`
>
> ⚑ Ogni testo qui sotto e' stato controllato contro il limite del campo in cui va: il numero
> di caratteri e' scritto sotto ciascuno. Nessun segreto in questo file.

---

## 1. File in questa cartella

| File | Dove va in Play Console |
|---|---|
| `trashcan-1.0.0-10.aab` | Versioni → Produzione (o Test chiuso) → Crea nuova versione → Carica |
| `icona-512.png` | Scheda principale dello Store → Icona dell'app |
| `testata-1024x500-it.png` | Scheda principale (italiano) → Grafica in primo piano |
| `testata-1024x500-en.png` | Scheda principale (inglese) → Grafica in primo piano |
| `screenshots/android/it/*.png` | Scheda italiana → Screenshot dello smartphone, **in quest'ordine** |
| `screenshots/android/en/*.png` | Scheda inglese → Screenshot dello smartphone, in quest'ordine |

☠ **Gli screenshot di settembre vanno cancellati da Play Console**, non solo affiancati ai nuovi.
Mostravano l'onboarding che chiedeva a tutti l'orario del promemoria, il widget con una riga sola
e un formato 1080×2400: 2,22:1, mentre Play non accetta immagini in cui il lato lungo superi il
doppio del corto. I nuovi sono 1080×1920, cioe' 9:16, il formato che Play chiede anche per
mettere un'app in evidenza.

☠ **La grafica in primo piano e' stata corretta.** Diceva "Il promemoria la sera prima", ma il
promemoria e' Pro: ora dice "Il widget te lo dice ogni sera", che vale anche per chi non compra.

Gli screenshot si rigenerano con `pwsh tool/screenshots_android.ps1 <it|en> <cartella>`: il
test `integration_test/screenshots_test.dart` guida l'app da solo e lo script fotografa.

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

### Nome

```
TrashCan
```

*8 caratteri su 30.*

### Descrizione breve

```
Il calendario della raccolta differenziata: cosa portare fuori, ogni sera.
```

*74 caratteri su 80.*

### Descrizione completa

```
Stasera cosa si butta?

TrashCan risponde a questa domanda e basta. Imposti una volta i giorni di raccolta del tuo Comune e la risposta è sempre lì, sulla schermata iniziale, senza aprire niente.

COME FUNZIONA

Una procedura guidata: scegli i tipi di rifiuto che raccoglie il tuo Comune e tocca i giorni in cui passano. Copi il volantino del Comune in due minuti e non ci pensi più.

REGGE I CALENDARI VERI

Non tutti i Comuni hanno un giro settimanale semplice. TrashCan gestisce:
• ogni settimana, nei giorni che scegli
• a settimane alterne
• ogni due settimane a partire da una data
• una volta al mese, per posizione (il primo martedì, l'ultimo venerdì)
• date scelte a mano, una per una

LE ECCEZIONI NON TI FREGANO

Feste, sospensioni e raccolte straordinarie: segni la variazione sul singolo giorno, senza toccare la regola di tutto l'anno.

IL WIDGET SULLA SCHERMATA INIZIALE

Stretto e verticale. L'intestazione colorata dice cosa si porta fuori stasera, con la sua icona; sotto, le tre raccolte successive. Si aggiorna da solo ogni sera, anche se l'app non la apri mai.

I TIPI DI RIFIUTO SONO I TUOI

Ogni Comune ha le sue categorie e i suoi nomi. Parti da quelli già pronti (organico, carta, plastica, vetro, metalli, indifferenziato, verde, pannolini), rinominali, cambia icona e colore, o creane di nuovi.

CONDIVIDI IL CALENDARIO CON UN VICINO

Un file con il tuo calendario: chi abita nella tua via lo apre e ha già tutti i giorni, senza ricopiarli.

SENZA ACCOUNT, SENZA INTERNET

Non c'è niente da registrare e niente da accettare. Quello che inserisci resta sul telefono: non lo vediamo e non lo raccogliamo. L'app funziona in aereo, in cantina e in un paese senza campo.

NIENTE PUBBLICITÀ

Nemmeno nella versione gratuita. Non c'è spazio per un banner in un'app che deve rispondere a una domanda in due secondi.

GRATIS, E POI PRO SE TI SERVE

La versione gratuita include un calendario, tipi di rifiuto e regole senza limiti, le eccezioni, il widget completo e la condivisione del calendario.

TrashCan Pro si sblocca con un acquisto singolo, senza abbonamento e senza rinnovi, e aggiunge:
• il promemoria la sera prima, all'ora che scegli tu
• un secondo promemoria, per le sere in cui al primo non sei in casa
• calendari multipli: casa, casa al mare, i genitori
• il backup completo, da rimettere su un altro telefono
• il colore dell'app, scelto da te fra dieci

Se cambi telefono, il Pro lo ripristini dal tuo account Google. Se hai cambiato anche account, dentro l'app c'è un codice di trasferimento.

UNA COSA DA DIRE CHIARAMENTE

I giorni di raccolta li decide il tuo Comune, non l'app. TrashCan ti ricorda quello che hai inserito tu: in caso di dubbio fa fede sempre il calendario ufficiale del Comune o del gestore.

TrashCan fa parte di SMP MicroApps: app piccole, che fanno una cosa sola e la fanno bene.
https://smpmicroapps.it
```

*2864 caratteri su 4000.*

---

## 4. Testi in inglese

### Descrizione breve

```
Your bin collection calendar: what to put out, every evening.
```

*61 caratteri su 80.*

### Descrizione completa

```
What goes out tonight?

TrashCan answers that one question and nothing else. Set your council's collection days once and the answer is always there, on your home screen, without opening anything.

HOW IT WORKS

A guided setup: pick the waste types your council collects and tap the days they come. Copy your council's leaflet in two minutes and forget about it.

IT HANDLES REAL CALENDARS

Not every council runs a simple weekly round. TrashCan supports:
• every week, on the days you choose
• alternating weeks
• every two weeks from a start date
• monthly by position (the first Tuesday, the last Friday)
• dates picked by hand, one at a time

EXCEPTIONS DON'T CATCH YOU OUT

Bank holidays, suspensions and extra collections: mark the change on that single day, without touching the rule for the rest of the year.

THE HOME SCREEN WIDGET

Narrow and vertical. The coloured header says what goes out tonight, with its icon; below it, the next three collections. It updates itself every evening, even if you never open the app.

THE WASTE TYPES ARE YOURS

Every council has its own categories and its own names. Start from the ready-made ones (organic, paper, plastic, glass, metal, unsorted, garden, nappies), rename them, change icon and colour, or create your own.

SHARE THE CALENDAR WITH A NEIGHBOUR

One file holding your calendar: someone on your street opens it and has every day already, without copying them out.

NO ACCOUNT, NO INTERNET

There is nothing to register and nothing to accept. What you enter stays on your phone: we never see it and never collect it. The app works on a plane, in a basement and in a village with no signal.

NO ADVERTISING

Not even in the free version. There is no room for a banner in an app that has to answer a question in two seconds.

FREE, THEN PRO IF YOU NEED IT

The free version includes one calendar, unlimited waste types and rules, exceptions, the full widget and calendar sharing.

TrashCan Pro unlocks with a single purchase, no subscription and no renewals, and adds:
• the reminder the evening before, at the time you choose
• a second reminder, for the evenings you are out at the first
• multiple calendars: home, the holiday house, your parents'
• full backup, to restore on another phone
• the app colour, chosen by you out of ten

Change phone and you restore Pro from your Google account. If you changed account too, there is a transfer code inside the app.

ONE THING TO SAY PLAINLY

Collection days are decided by your council, not by the app. TrashCan reminds you of what you entered: in case of doubt, the council's official calendar always governs.

TrashCan is part of SMP MicroApps: small apps that do one thing and do it well.
https://smpmicroapps.it
```

*2722 caratteri su 4000.*

---

## 5. Note di rilascio della versione

Italiano:

```
Prima versione.
```

*15 caratteri su 500.*

Inglese:

```
First release.
```

*14 caratteri su 500.*

---

## 6. Sicurezza dei dati (Data safety)

☠ E' un modulo che si dichiara sotto la propria responsabilita' e Google lo verifica a
campione. Le risposte descrivono il comportamento **reale** della build Android: i dati stanno nel
database locale, e l'unica cosa che lascia il dispositivo e' la verifica dell'acquisto verso il
License Server (`packages/micro_core/lib/src/entitlement/`).

| Domanda | Risposta |
|---|---|
| L'app raccoglie o condivide dati utente richiesti? | **Sì** (identificativo di installazione e token d'acquisto) |
| I dati sono cifrati in transito? | **Sì**, HTTPS |
| L'utente puo' chiedere la cancellazione dei dati? | **Sì**, scrivendo a `info@smp-digital.it` |
| Dati raccolti | **ID dispositivo o altri ID**: identificativo di installazione generato dall'app, non l'ID pubblicitario. Finalita': **gestione dell'account** (verifica dell'acquisto) e **prevenzione delle frodi**. Obbligatorio. Non condiviso con terzi. |
| Acquisti in-app | Gestiti da Google Play. Non riceviamo dati di pagamento. |
| Posizione, contatti, foto, file, messaggi, salute, calendario | **Nessuno** |
| Analisi d'uso, crash reporting, pubblicita' | **Nessuno**: niente Firebase, Crashlytics o SDK pubblicitari |

**Notifiche**: pianificate in locale dal sistema. Nessuna notifica push remota, nessun token.

---

## 7. Classificazione dei contenuti (IARC)

"No" a tutto: nessuna violenza, linguaggio, sostanze, sesso, gioco d'azzardo, condivisione di
posizione, interazione fra utenti, contenuti generati dagli utenti. Esito atteso: **PEGI 3 / Tutti**.
**Unica risposta affermativa**: l'app consente acquisti di beni digitali (un acquisto singolo).

---

## 8. Pubblico di destinazione

- Fascia d'eta': **18 e oltre**. L'app non e' pensata per i minori, e cosi' si evitano del tutto i
  requisiti aggiuntivi delle Families Policy.
- Nessun elemento che attragga i bambini: niente giochi, personaggi o grafica infantile.

---

## 9. Prodotto in-app

| Campo | Valore |
|---|---|
| ID prodotto | `trashcan_pro_lifetime` |
| Tipo | Prodotto gestito (una tantum), **non** consumabile |
| Nome (it) | `TrashCan Pro` |
| Descrizione (it) | `Sblocca i promemoria della sera, il secondo promemoria, i calendari multipli, il backup completo e il colore dell'app. Un pagamento unico, nessun abbonamento.` |
| Nome (en) | `TrashCan Pro` |
| Descrizione (en) | `Unlocks evening reminders, the second reminder, multiple calendars, full backup and the app colour. One payment, no subscription.` |
| Prezzo | Base 1,99 €: Play lo porta a **2,39 € IVA inclusa** in Italia, e calcola il finale paese per paese |
| Stato | Attivo |

☠ **L'ID del prodotto non si cambia e non si riusa.** E' scritto in
`apps/trashcan/lib/app/app_config.dart`: con un ID diverso l'app non trova niente da vendere.

---

## 10. Cosa e' cambiato rispetto alla scheda di settembre, e perche'

La scheda precedente conteneva **affermazioni diventate false**. Su uno store non e' un problema
di stile: Google le tratta come rappresentazione ingannevole.

| Prima | Adesso | Perche' |
|---|---|---|
| "l'app ti avvisa ogni sera cosa portare fuori" | "la risposta e' sempre li', sulla schermata iniziale" | il promemoria e' Pro; il widget no |
| "decidi l'ora del promemoria" nella procedura guidata | tolto | dal 2026-10-04 l'onboarding dice che il promemoria e' Pro invece di chiedere l'orario |
| gratis: "l'esportazione e il backup" | gratis: "la condivisione del calendario"; Pro: "il backup completo" | `FeatureKey.backupRestore` e' `locked`; condividere un calendario con un vicino e' libero |
| descrizione breve "con il promemoria la sera prima" | "cosa portare fuori, ogni sera" | come sopra |

---

## 11. Il pacchetto e' collegato al server

Il pacchetto e' compilato con `--dart-define-from-file=release_defines.json`, che contiene
`MA_LICENSE_URL=https://lic.smpmicroapps.it` e il segreto HMAC dell'app. **Il file viene creato e
cancellato da `tool/build_release.ps1`**: non e' versionato e non deve esserlo.

☠ `--dart-define=MA_LICENSE_URL=https://...` non si puo' usare: il wrapper `tool/fl.ps1`
passa da un file batch di Windows che spezza gli argomenti sui due punti, e il build fallisce con
"Target file //lic.smpmicroapps.it not found". Per questo il file dei define, con percorso relativo.

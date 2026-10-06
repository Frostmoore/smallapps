# Scheda App Store — TrashCan

> Tutto quello che serve per compilare App Store Connect, pronto da incollare.
> **Aggiornato al**: 2026-10-05 · **Versione**: `1.0.0 (11)` · **Bundle ID**: `com.smp.trashcan`
> · **ID Apple**: `6818986320`
>
> ⚑ Ogni testo qui sotto e' stato controllato contro il limite del campo in cui va: il numero
> di caratteri e' scritto sotto ciascuno.

---

## 1. File in questa cartella

| File | Dove va in App Store Connect |
|---|---|
| `screenshots/ios-6.5/it/*.png` | Pagina della versione, Italiano → Anteprime e screenshot → **iPhone, display da 6,5"**, in quest'ordine |
| `screenshots/ios-6.5/en/*.png` | Pagina della versione, Inglese (Regno Unito) → iPhone 6,5", in quest'ordine |
| `screenshots/ios/revisione/paywall-it.png` | Acquisti in-app → TrashCan Pro → **Screenshot per la revisione** |

☠ **App Store Connect chiede la misura da 6,5 pollici, 1284×2778**, e rifiuta le 1320×2868 da
6,9 trascinate in quello spazio. Le `ios-6.5/` sono ricavate dalle `ios/` (ridotte e rifilate di
6 pixel sopra e sotto: le proporzioni differiscono di 12 pixel su 2800). Le 6,9 restano in `ios/`
per lo spazio facoltativo in "Visualizza tutte le dimensioni". **Niente screenshot per iPad**: l'app e' dichiarata solo iPhone
(`TARGETED_DEVICE_FAMILY = 1`), e sugli iPad gira nella finestra di compatibilita'.

⚑ Il secondo screenshot, quello del widget, e' **composto** e non fotografato: un widget non si
mette sulla schermata Home da riga di comando. I widget dentro sono pero' la vista vera,
`VistaTrashcan.swift`, renderizzata da `tool/anteprima_widget_ios.swift --vetrina`.

☠ Il paywall non e' fra gli screenshot della scheda di proposito: mostrerebbe un prezzo, e il
prezzo cambia da paese a paese. Lo screenshot del paywall serve solo alla revisione
dell'acquisto in-app, dove Apple lo pretende.

Gli screenshot si rigenerano con `bash tool/screenshots_ios.sh <UDID> <it|en> <cartella>` sul Mac.

---

## 2. Informazioni sull'app

| Campo | Valore |
|---|---|
| Nome | `TrashCan` |
| Sottotitolo (it) | `Raccolta differenziata` |
| Sottotitolo (en) | `Bin collection calendar` |
| Lingua principale | Italiano |
| Categoria principale | Stile di vita |
| Categoria secondaria | Utility |
| Diritti sui contenuti | **No**, l'app non contiene contenuti di terzi |
| URL della privacy | `https://smpmicroapps.it/legale/privacy` |

**Classificazione per eta'**: "Nessuno" o "No" a ogni domanda del questionario. Esito atteso
**4+**. Nessun contenuto generato dagli utenti, nessuna navigazione web libera, nessun gioco
d'azzardo, nessun controllo parentale da dichiarare.

**Prezzo e disponibilita'**: app **gratuita**, disponibile in tutti i paesi.

---

## 3. Pagina della versione 1.0.0

I campi sono nell'ordine in cui li trovi nella pagina. Le parole chiave non ripetono il nome e il
sottotitolo, che Apple indicizza gia', e sono separate da virgole senza spazi.

### Italiano

**Testo promozionale** (126 su 170)

```
Imposti una volta i giorni del tuo Comune e il widget ti dice ogni sera cosa portare fuori. Niente account, niente pubblicità.
```

**Descrizione** (2808 su 4000)

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

Piccolo o medio, come preferisci. La testata colorata dice cosa si porta fuori stasera, con la sua icona; accanto o sotto, le tre raccolte successive. Si aggiorna da solo ogni sera, anche se l'app non la apri mai.

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

Se cambi iPhone, il Pro lo ripristini con "Ripristina acquisti", con lo stesso ID Apple.

UNA COSA DA DIRE CHIARAMENTE

I giorni di raccolta li decide il tuo Comune, non l'app. TrashCan ti ricorda quello che hai inserito tu: in caso di dubbio fa fede sempre il calendario ufficiale del Comune o del gestore.

TrashCan fa parte di SMP MicroApps: app piccole, che fanno una cosa sola e la fanno bene.
```

**Parole chiave** (98 su 100)

```
calendario,rifiuti,spazzatura,bidone,comune,promemoria,riciclo,umido,organico,carta,plastica,vetro
```

**URL di assistenza**

```
https://smpmicroapps.it/contatti
```

**URL di marketing**

```
https://smpmicroapps.it/trashcan
```

**Versione**

```
1.0.0
```

**Copyright** (34 su 200)

```
2026 SeeMyPage di Ronconi Riccardo
```

**File di copertura geografica**: lascia vuoto. Serve solo alle app di navigazione stradale.

### Inglese (Regno Unito)

**Testo promozionale** (115 su 170)

```
Set your council's collection days once and the widget tells you every evening what to put out. No account, no ads.
```

**Descrizione** (2675 su 4000)

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

Small or medium, as you like. The coloured header says what goes out tonight, with its icon; next to it or below, the next three collections. It updates itself every evening, even if you never open the app.

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

Change iPhone and you restore Pro with "Restore purchases", using the same Apple ID.

ONE THING TO SAY PLAINLY

Collection days are decided by your council, not by the app. TrashCan reminds you of what you entered: in case of doubt, the council's official calendar always governs.

TrashCan is part of SMP MicroApps: small apps that do one thing and do it well.
```

**Parole chiave** (93 su 100)

```
trash,garbage,recycling,waste,rubbish,refuse,council,reminder,schedule,widget,dustbin,recycle
```

**URL di assistenza**

```
https://smpmicroapps.it/en/contatti
```

**URL di marketing**

```
https://smpmicroapps.it/en/trashcan
```

**Versione**

```
1.0.0
```

**Copyright** (34 su 200)

```
2026 SeeMyPage di Ronconi Riccardo
```

**File di copertura geografica**: lascia vuoto. Serve solo alle app di navigazione stradale.

### Piu' in basso nella stessa pagina

| Campo | Valore |
|---|---|
| Build | `1.0.0 (11)`, quella con widget e manifesti di privacy |
| Acquisti in-app | Seleziona **TrashCan Pro** |
| Rilascio | Manuale, cosi' scegli tu il momento dopo l'approvazione |

☠ **Il primo acquisto in-app si invia insieme alla prima versione.** Se resta fuori, Apple approva
l'app e non l'acquisto, e il Pro non si puo' comprare.

---

## 4. Privacy dell'app (l'etichetta nella scheda)

Risposta: **"Dati non raccolti"**.

⚑ E' diversa da Android, ed e' giusta cosi'. La build iOS **non parla con nessun server**:
`tool/build_ios.sh` passa solo `BILLING=store` e non `MA_LICENSE_URL`, quindi la verifica
dell'acquisto lato server e il codice di trasferimento non esistono su iPhone. L'acquisto lo
gestisce Apple, il calendario resta sul telefono.

☠ **Se un giorno la build iOS si collega al License Server, questa etichetta diventa falsa** e va
rifatta come quella di Play: identificativo di installazione, finalita' "funzionalita' dell'app".

I manifesti di privacy (`ios/Runner/PrivacyInfo.xcprivacy`, `ios/TrashcanWidget/PrivacyInfo.xcprivacy`)
dichiarano lo stesso: nessun tracciamento, nessun dato raccolto, e le preferenze (UserDefaults)
usate per motivi propri dell'app e del gruppo condiviso col widget.

---

## 5. Acquisto in-app

| Campo | Valore |
|---|---|
| Tipo | **Non consumabile** |
| Nome di riferimento | `TrashCan Pro` |
| ID prodotto | `trashcan_pro_lifetime` |
| Nome visualizzato (it) | `TrashCan Pro` |
| Descrizione (it) | `Promemoria, più calendari, backup e colori` (42 su 45) |
| Nome visualizzato (en) | `TrashCan Pro` |
| Descrizione (en) | `Reminders, more calendars, backup, colours` (42 su 45) |
| Prezzo | Paese di riferimento **Italia**, **2,39 €**, lo stesso che il compratore italiano paga su Play |
| Screenshot per la revisione | `screenshots/ios/revisione/paywall-it.png` |
| Note per la revisione | "Unlocked from Settings > Reminders > See what Pro includes." |

☠ **L'ID prodotto deve essere identico a Play**: `trashcan_pro_lifetime`. L'app lo cerca con
quel nome su tutti e due i negozi.

⚑ Apple i prezzi li mostra gia' **IVA inclusa**, e dal paese di riferimento ricava gli altri.
Controlla nella tabella dei paesi che l'Italia dica 2,39 €.

---

## 6. Informazioni per la revisione

| Campo | Valore |
|---|---|
| Accesso richiesto | **No**, l'app non ha account |
| Contatto | Riccardo Ronconi, `info@smp-digital.it` e il tuo telefono |

### Note (in inglese, le leggono i revisori)

```
TrashCan is a waste-collection calendar. No account and no login are needed: the app works fully offline and does not talk to any server.

HOW TO TRY IT
1. On first launch, tap "Set up my calendar", keep the suggested name, pick a few waste types and tap the days they are collected.
2. The home screen and the widget then show what goes out tonight and the next collections.
3. To add the widget: touch and hold the Home Screen, tap +, search for TrashCan.

IN-APP PURCHASE
TrashCan Pro (trashcan_pro_lifetime) is a single non-consumable purchase. It unlocks the evening reminder notifications, a second reminder, multiple calendars, full backup and restore, and the app colour. To see it: Settings > Reminders > "See what Pro includes". "Restore purchases" is on the same screen.

NOTIFICATIONS
Reminders are part of Pro. The app asks for notification permission only when the user turns reminders on, never at first launch.
```

*926 caratteri su 4000.*

---

## 7. TestFlight, cosa provare

```
Cosa provare:
- Il widget: tieni premuto sulla schermata Home, tocca +, cerca TrashCan. Deve mostrare cosa si butta stasera e le tre raccolte successive, e cambiare da solo dopo mezzanotte.
- I promemoria (con il Pro): accendendoli l'app deve chiedere il permesso delle notifiche una volta sola.
```

*295 caratteri su 4000.*

---

## 8. Ordine consigliato delle operazioni

1. **Acquisto in-app**: crealo (§5) e caricagli lo screenshot del paywall. Resta "Pronto per
   l'invio" finche' non lo alleghi alla versione.
2. **Informazioni sull'app** (§2), comprese classificazione per eta' e privacy (§4).
3. **Pagina della versione** in italiano, poi aggiungi l'inglese (§3) con i suoi screenshot.
4. Scegli la build `1.0.0 (11)` e seleziona TrashCan Pro fra gli acquisti in-app.
5. **Informazioni per la revisione** (§6), poi **Aggiungi per la revisione** e invia.

La prima revisione di solito richiede da uno a tre giorni.

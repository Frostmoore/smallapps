# Scheda App Store — Scorte Calore

> Tutto quello che serve per compilare App Store Connect. **Le parti segnate «API» le carica
> `tool/scheda_app_store.py` sul Mac**; le altre si fanno a mano.
> **Aggiornato al**: 2026-10-08 · **Versione**: `1.0.0` · **Bundle ID**: `com.smp.scortecalore`
> · **ID Apple**: `6820405604` · **IAP**: `scortecalore_pro_lifetime`
>
> ⚑ Ogni testo e' controllato contro il limite del campo: il conteggio e' scritto sotto.

---

## 1. File

| File | Dove va |
|---|---|
| `grafiche/appstore-6.5/it/*.png` | Versione, Italiano → screenshot **iPhone 6,5"** (1284×2778), in quest'ordine — API |
| `grafiche/appstore-6.5/en/*.png` | Versione, Inglese (Regno Unito) → iPhone 6,5" — API |
| `grafiche/appstore/it|en/*.png` | Facoltative, iPhone 6,9" (1320×2868) |
| `video/anteprima-886x1920-it|en.mp4` | Versione → **Anteprime app** iPhone 6,5", per lingua (24,5 s, H.264, 30 fps, audio muto) — API |
| `screenshots/ios/it/paywall-revisione.png` | Acquisto in-app → screenshot per la revisione — API |
| `grafiche/apple/intestazione-3840x1646-it|en.png` | Versione → **Intestazione e risultati di ricerca → Intestazione** (21:9), per lingua — a mano |
| `grafiche/apple/ricerca-3840x2560-it|en.png` | Versione → **Intestazione e risultati di ricerca → Risultati della ricerca** (3:2), per lingua — a mano |

⚑ «Intestazione» e «Risultati della ricerca» (Apple, 5 ottobre 2026): niente trasparenza, frasi
brevi e tradotte, niente prezzi, URL o ©; l'elemento chiave al centro perche' i bordi si tagliano.

Come si rifanno:

1. Screenshot veri: `ssh mac 'bash ~/microapps/tool/screenshots_ios.sh <UDID 18 Pro Max> it|en ~/microapps/apps/scorte_calore/store/screenshots/ios/<lingua> scorte_calore'`, poi copiarli qui.
2. Widget per la terza scheda: `tool/anteprima_widget_ios.swift --vetrina it|en <file>` sul Mac → `grafiche/sorgenti/widget_<lingua>.png`.
3. `python tool/genera_grafiche_store.py`.
4. Video: `tool/anteprima_app_store.sh` sul Mac, copia del `.mov` in `video/`, `pwsh tool/converti_anteprima.ps1`.

☠ Spazio obbligatorio = **6,5"**: Apple rifiuta le 6,9" trascinate li' (lezione di TrashCan).
**Niente iPad**: l'app e' solo iPhone (`TARGETED_DEVICE_FAMILY = 1`); su iPad gira in compatibilita'.

---

## 2. Informazioni sull'app — API

| Campo | Valore |
|---|---|
| Nome (it) | `Scorte Calore` |
| Nome (en-GB) | `Scorte Calore – Fuel Tracker` (28 su 30): il nome italiano da solo non dice niente a chi cerca in inglese |
| Sottotitolo (it) | `Quando riordinare pellet e GPL` (30 su 30) |
| Sottotitolo (en-GB) | `When to reorder pellets & LPG` (29 su 30) |
| Categoria principale | **Utility** (UTILITIES) |
| Categoria secondaria | **Stile di vita** (LIFESTYLE) |
| URL della privacy | `https://smpmicroapps.it/legale/privacy` |
| Diritti sui contenuti | **No**, nessun contenuto di terzi — API |
| Classificazione per eta' | "No"/"Nessuno" a tutto, esito **4+** — a mano |
| Prezzo | **Gratuita**, tutti i paesi — API |
| Privacy (etichetta) | **Dati non raccolti** — a mano |

---

## 3. Pagina della versione 1.0.0 — API

### Italiano

**Testo promozionale** (140 su 170)

```
Quanti giorni di riscaldamento ti restano e il giorno giusto per riordinare pellet, GPL, gasolio o legna. Niente account, niente pubblicità.
```

**Descrizione** (1798 su 4000)

```
Scorte Calore ti dice quanti giorni di riscaldamento ti restano e entro quando riordinare, prima di restare al freddo.

Aggiorna la scorta ogni tanto, con il numero che hai sotto gli occhi: i sacchi di pellet rimasti, i litri della cisterna, la percentuale del manometro del bombolone del GPL, gli steri di legna. L'app impara il tuo consumo dalle misure, riconosce da sola i rifornimenti e calcola la data in cui la scorta finisce.

COSA VEDI A COLPO D'OCCHIO
• I giorni di autonomia, in grande
• Il consumo medio al giorno
• La data entro cui riordinare, con i giorni di anticipo che scegli tu
• Quanto resta rispetto all'ultimo carico

PENSATA PER COME SI MISURA DAVVERO
• Pellet a sacchi o a chili, legna a steri o a quintali, gasolio a litri
• Il bombolone del GPL con la lettura del manometro: l'app la trasforma in litri utili, tenendo conto che non si riempie mai oltre l'80%
• Una misura al giorno, anche saltando settimane: la stima regge lo stesso

IL WIDGET
I giorni di autonomia e la data di riordino sulla schermata iniziale, senza aprire l'app. Il conto scende da solo ogni giorno.

SCORTE CALORE PRO
Un acquisto unico, niente abbonamento:
• Tutte le fonti di calore: la stufa e il bombolone, la casa e la seconda casa
• Le notifiche: il giorno in cui riordinare, e un promemoria se la data passa
• Lo storico completo e i grafici del consumo, per confrontare gli inverni
• Acquisti e costi: quanto spendi ogni inverno e il prezzo medio
• La data di riordino come evento nel calendario del telefono
• Esportazione in un foglio di calcolo e backup completo

La versione gratuita comprende una fonte di calore, la stima completa, gli ultimi 90 giorni di misure, il widget e il ripristino da un backup.

Niente account, niente pubblicità, nessun dato raccolto: tutto resta sul telefono.
```

**Parole chiave** (95 su 100)

```
pellet,stufa,gpl,bombolone,gasolio,legna,riscaldamento,scorta,consumo,riordino,caldaia,cisterna
```

### Inglese (Regno Unito)

**Testo promozionale** (140 su 170)

```
How many days of heating you have left, and the right day to reorder pellets, LPG, heating oil or firewood. No account, no ads, no tracking.
```

**Descrizione** (1624 su 4000)

```
Scorte Calore tells you how many days of heating you have left and when to reorder, before you run out in the cold.

Update your stock now and then with the number in front of you: bags of pellets left, litres in the oil tank, the percentage on your LPG tank gauge, cubic metres of firewood. The app learns your consumption from your readings, spots refills by itself and works out the day your stock runs out.

AT A GLANCE
• Days left, in big numbers
• Average use per day
• The date to reorder by, as many days ahead as you choose
• How much is left since the last refill

BUILT FOR HOW PEOPLE REALLY MEASURE
• Pellets in bags or kilos, firewood in cubic metres, heating oil in litres
• Your LPG tank's gauge reading: the app turns it into usable litres, knowing the tank is never filled beyond 80%
• One reading a day, even with weeks in between: the estimate holds up

THE WIDGET
Days left and the reorder date on your Home Screen, without opening the app. The count goes down by itself every day.

SCORTE CALORE PRO
One purchase, no subscription:
• Every heat source: the stove and the LPG tank, home and holiday home
• Notifications: on the day to reorder, and a reminder if the date passes
• Full history and consumption charts, to compare winters
• Purchases and costs: what you spend each winter and the average price
• The reorder date as an event in your phone's calendar
• Spreadsheet export and full backup

The free version includes one heat source, the full estimate, the last 90 days of readings, the widget and restoring from a backup.

No account, no ads, no data collected: everything stays on your phone.
```

**Parole chiave** (100 su 100)

```
pellets,stove,lpg,propane,heating oil,firewood,fuel,tank,gauge,reorder,consumption,boiler,winter,log
```

### Note per la revisione (inglese)

```
No account is needed: everything is stored on the device.

The estimate needs at least two stock readings on different days. To see the app with data right away: add a heat source (for example Pellets, in bags), then tap "Update stock" twice with a lower number, changing the date in the sheet to an earlier day for the first reading.

In-app purchase scortecalore_pro_lifetime (non-consumable) unlocks: more than one heat source, reorder notifications, full history and charts, purchases and costs, the calendar event, CSV export and full backup. To test it: Settings > Scorte Calore Pro, or tap any item marked PRO.

Calendar access is requested only when the user taps "Add to calendar" (Pro), to create and later move or remove the reorder event. Notifications are off until the user turns them on in Settings.
```

---

## 4. Acquisto in-app — API

| Campo | Valore |
|---|---|
| Tipo | Non consumabile |
| Nome di riferimento | `Scorte Calore Pro` |
| ID prodotto | `scortecalore_pro_lifetime` |
| Prezzo | **2,99 €** (territorio base Italia), tutti i paesi |
| In famiglia | No |
| Nome visualizzato (it / en-GB) | `Scorte Calore Pro` |
| Descrizione (it) | `Tutte le fonti, notifiche, storico, costi e calendario` (54 su 55) |
| Descrizione (en-GB) | `All heat sources, alerts, history, costs and calendar` (53 su 55) |
| Screenshot per la revisione | `screenshots/ios/it/paywall-revisione.png` |

☠ Il primo acquisto in-app di un'app si invia **insieme alla versione**, dalla sua pagina
(FIRST_NON_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION): va spuntato a mano prima di inviare.

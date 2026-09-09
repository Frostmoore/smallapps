# Scorte Calore — Spec-sheet operativa

## Concept

App per sapere quanto combustibile domestico rimane e tra quanti giorni finirà.

Combustibili inizialmente supportati:

- pellet
- GPL
- gasolio
- legna
- biomassa generica

L'utente aggiorna periodicamente la propria scorta. L'app calcola automaticamente il consumo medio e stima la data di esaurimento.

Obiettivo principale:

> Quando devo ricomprare il combustibile?

---

## Target

Proprietari di:

- stufe a pellet
- caldaie a pellet
- bomboloni GPL
- serbatoi gasolio
- camini e stufe a legna
- seconde case

Target principale: utenti privati, non installatori.

---

## USP

La schermata principale deve mostrare subito:

- Pellet rimasto: 18 sacchi
- Consumo medio: 0,82 sacchi/giorno
- Autonomia stimata: 22 giorni
- Riordina entro: 3 ottobre

L'app deve essere comprensibile in pochi secondi.

---

## MVP

### Configurazione fonte

Campi:

- nome
- tipo combustibile
- unità di misura
- peso/capacità per unità
- quantità iniziale
- costo opzionale
- giorni di anticipo per il riordino

Esempio:

- Nome: Stufa soggiorno
- Tipo: Pellet
- Unità: Sacchi
- Peso unitario: 15 kg
- Scorta iniziale: 60 sacchi
- Costo: 6,50 € / sacco

### Aggiornamenti scorta

L'utente inserisce periodicamente la quantità residua.

Esempio:

- 12 settembre → 58 sacchi
- 19 settembre → 51 sacchi
- 26 settembre → 44 sacchi

### Calcolo consumo

Formula base:

`consumo_medio = quantità_consumata / giorni_trascorsi`

`giorni_residui = quantità_attuale / consumo_medio`

Preferibile una media mobile degli ultimi 3–5 intervalli per evitare che dati molto vecchi alterino la previsione.

Mostrare sempre che il risultato è una stima.

### Riordino

Configurazione:

`Avvisami X giorni prima`

Default consigliato:

`7 giorni`

L'app calcola:

`data_prevista_esaurimento - anticipo`

---

## Notifiche

Notifiche locali.

Esempio:

> Il pellet potrebbe terminare tra circa 7 giorni. Ti restano circa 12 sacchi.

Seconda notifica possibile:

> Hai superato la data prevista di riordino del GPL.

---

## Google Calendar

Funzione opzionale.

Pulsante:

**Aggiungi riordino al calendario**

Evento:

- Titolo: Riordinare pellet
- Data: data consigliata
- Descrizione: Autonomia stimata fino al 10 ottobre

Se la previsione cambia sensibilmente, l'app può proporre l'aggiornamento dell'evento.

Nessun backend necessario: si usa il calendario disponibile sul dispositivo e la sincronizzazione viene lasciata a Google Calendar.

---

## Tipologie di combustibile

### Pellet

Unità:

- sacchi
- kg
- pallet

### GPL

Input:

- litri
- percentuale serbatoio

Configurazione capacità serbatoio.

Esempio:

- capacità: 1.000 L
- residuo: 43%

L'app converte la percentuale in quantità stimata.

### Gasolio

Stessa logica del GPL.

### Legna

Unità configurabili:

- kg
- quintali
- metri steri
- cassette/ceste

Nell'MVP evitare conversioni troppo sofisticate.

---

## Dashboard

Esempio:

### Stufa soggiorno

18 sacchi

**22 giorni di autonomia**

Riordino consigliato: **3 ottobre**

Ultimo aggiornamento: 26 settembre

CTA principale:

**Aggiorna scorta**

---

## Storico e statistiche

Grafici:

- data → quantità residua
- data → consumo medio giornaliero

Dati opzionali:

- quantità acquistata
- prezzo
- costo medio
- spesa stagionale

---

## Data model

### FuelSource

- id
- name
- type
- measurement_unit
- unit_weight
- tank_capacity
- warning_days
- created_at

### StockMeasurement

- id
- fuel_source_id
- date
- quantity
- note

### Purchase

- id
- fuel_source_id
- date
- quantity
- total_cost
- supplier
- note

### CalendarReminder

- id
- fuel_source_id
- external_event_id
- calculated_date

---

## Monetizzazione

### Free

- 1 fonte di combustibile
- storico 90 giorni
- notifiche
- stima autonomia

### Pro — 5,99 € / 7,99 € lifetime

- fonti illimitate
- storico illimitato
- Google Calendar
- grafici
- statistiche di spesa
- export CSV
- backup locale

Niente abbonamento nell'MVP.

---

## Architettura tecnica

- Flutter
- SQLite / Drift
- notifiche locali
- integrazione calendario Android
- export/import JSON
- nessun login
- nessun backend obbligatorio

---

## Complessità

- Backend: 0/5
- Frontend: 2/5
- Logica: 2/5
- Manutenzione futura: bassa

# My Digital Film Tracker — Spec-sheet operativa

## Concept

Diario dei rullini fotografici analogici.

Serve a ricordare:

- quale rullino è stato usato
- su quale macchina
- quando è stato consegnato
- quanto è costato lo sviluppo
- quanto è costata la stampa
- quando sono tornate le foto
- quali fotografie appartengono a quel rullino

Ogni rullino diventa una scheda cronologica e visiva.

---

## Target

Fotografi analogici amatoriali, soprattutto chi:

- usa più macchine
- prova emulsioni diverse
- usa laboratori differenti
- separa sviluppo, scansione e stampa
- vuole una memoria visiva dei rullini

---

## Oggetto principale

### Film Roll

Esempio:

**Kodak Gold 200 — #17**

Campi:

- macchina
- formato
- ISO nominale
- ISO esposto
- data caricamento
- data completamento
- numero fotogrammi
- titolo opzionale
- note

Esempio:

- Macchina: Olympus OM-2
- Formato: 35mm
- ISO nominale: 200
- ISO esposto: 200
- Data caricamento: 4 settembre
- Data completamento: 18 settembre
- Fotogrammi: 36

---

## Stati del rullino

Workflow:

1. Loaded
2. Exposed
3. Sent for development
4. Developed
5. Printed opzionale

La stampa deve essere separata dallo sviluppo by design.

Questo permette casi come:

- sviluppo laboratorio A
- scansione laboratorio A
- stampa mesi dopo da laboratorio B
- sviluppo in casa + scansione esterna

---

## Development

Campi:

- laboratorio
- data consegna
- data restituzione
- costo sviluppo
- costo scansione
- processo
- note

Esempio:

- Laboratorio: Ars Imago
- Consegnato: 20 settembre
- Ricevuto: 27 settembre
- Costo sviluppo: 7 €
- Costo scansione: 8 €
- Processo: C-41

---

## Printing

Evento separato.

Campi:

- laboratorio
- data consegna
- data restituzione
- formato
- numero stampe
- costo
- note

---

## Photo overview

Feature caratterizzante.

Quando le fotografie tornano dal laboratorio:

**Aggiungi anteprima del rullino**

L'utente può:

- fotografare il foglio di provini
- fotografare le stampe
- importare una contact sheet ricevuta dal laboratorio
- selezionare alcune immagini dalla galleria

La scheda del rullino mostra una preview immediata.

Obiettivo:

riconoscere il rullino visivamente senza dover ricordare il numero o il tipo di pellicola.

---

## Gestione immagini

Strategia consigliata:

- generare miniature locali ottimizzate
- evitare di duplicare inutilmente le scansioni originali

Possibili opzioni:

- Salva copia nell'app
- Conserva riferimento alla foto

Dimensione thumbnail consigliata:

max 1600 px lato lungo.

---

## Home

Tre sezioni principali.

### In camera

- Kodak Portra 400
- Olympus OM-2
- 18 / 36

### Waiting for lab

- Ilford HP5 — consegnato 5 giorni fa
- Kodak Gold — consegnato 2 giorni fa

### Archive

Card con thumbnail/contact sheet:

- Kodak Gold 200 #17
- Praga — settembre 2026

---

## Camera collection

Piccolo inventario opzionale.

Campi:

- produttore
- modello
- formato
- note

Non deve diventare un'app per collezionisti.

Serve solo ad associare rapidamente una macchina al rullino.

---

## Film stock

Database locale iniziale piccolo.

Esempi:

- Kodak Gold 200
- Kodak Portra 160
- Kodak Portra 400
- Kodak Ultramax 400
- Ilford HP5+
- Ilford FP4+
- Fomapan 100

Deve sempre esistere:

**Custom film**

Nessun bisogno di un database remoto enorme.

---

## Statistiche

Esempio annuale:

### 2026

- 23 rullini
- 828 fotogrammi potenziali

Spese:

- Rullini: 231 €
- Sviluppo: 176 €
- Scansioni: 143 €
- Stampe: 94 €

Totale:

**644 €**

Indicatori:

- costo medio per rullino
- costo medio per fotogramma
- laboratorio più usato
- emulsione più usata
- macchina più usata

---

## Data model

### Camera

- id
- manufacturer
- model
- format
- note

### FilmRoll

- id
- sequence_number
- film_name
- format
- nominal_iso
- exposed_iso
- camera_id
- loaded_at
- finished_at
- frames
- title
- note
- status

### Development

- id
- film_roll_id
- laboratory
- submitted_at
- returned_at
- development_cost
- scan_cost
- process
- note

### PrintOrder

- id
- film_roll_id
- laboratory
- submitted_at
- returned_at
- format
- number_of_prints
- cost
- note

### RollImage

- id
- film_roll_id
- image_path
- type
- sort_order

---

## Monetizzazione

### Free

- fino a 10 rullini
- tutte le funzioni base
- una macchina

### Pro — 6,99 € / 9,99 € lifetime

- rullini illimitati
- macchine illimitate
- statistiche
- immagini/contact sheet
- export CSV
- backup
- PDF riepilogo

Nessun account obbligatorio.

---

## Possibile evoluzione

### QR rullino

Quando il rullino viene tolto dalla macchina, l'app genera un piccolo QR identificativo.

Il QR serve all'utente per non mischiare i rullini prima o dopo lo sviluppo.

Il laboratorio non deve supportare nulla.

---

## Architettura tecnica

- Flutter
- SQLite / Drift
- file system locale
- image picker / camera
- notifiche opzionali
- export/import JSON
- nessun backend

---

## Complessità

- Backend: 0/5
- Frontend: 3/5
- Logica: 2/5
- Storage foto: 3/5

È quella con maggiore identità di prodotto tra le quattro.

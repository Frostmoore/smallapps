# Full Freezer — Spec-sheet operativa

## Concept

Inventario semplice del freezer, centrato sull'anzianità degli alimenti.

Problema principale:

> Quale roba è lì dentro da mesi e me ne sono completamente dimenticato?

L'app deve privilegiare l'ordine "più vecchio prima", non una gestione da magazzino.

---

## Target

Famiglie e persone che:

- congelano avanzi
- acquistano carne o pesce in quantità
- fanno meal prep
- hanno congelatori a pozzetto
- usano più cassetti o più freezer

---

## USP

Home ordinata automaticamente per anzianità.

Esempio:

### Da usare prima

- Spezzatino — congelato 4 mesi fa
- Salmone — congelato 3 mesi fa
- Lasagne — congelate 2 mesi fa

Feature chiave:

**oldest first**

---

## Inserimento alimento

CTA:

**Metti nel freezer**

Campi:

- nome
- categoria
- quantità
- unità
- data
- posizione
- nota opzionale
- foto opzionale

Esempio:

- Nome: Ragù
- Categoria: Preparato
- Quantità: 2 porzioni
- Data: oggi
- Posizione: Cassetto 2

---

## Inserimento rapido

Deve richiedere pochi secondi.

Modalità base:

**Nome + quantità + salva**

Tutto il resto deve essere opzionale.

Possibile voice input Android:

> Due porzioni di lasagne

senza AI server-side.

---

## Posizione

L'utente può creare:

- freezer cucina
- freezer garage
- congelatore a pozzetto
- cassetto 1
- cassetto 2
- cassetto 3

Esempio visualizzazione:

### Freezer cucina

- Cassetto 1 — 8 prodotti
- Cassetto 2 — 14 prodotti
- Cassetto 3 — 5 prodotti

---

## Uscita alimento

Azioni rapide:

- Consumata
- Buttata

Registrare la data di uscita.

Questo permette statistiche future sullo spreco.

---

## Aging system

Non usare automaticamente una "scadenza sanitaria" rigida.

Meglio mostrare:

`128 giorni nel freezer`

e opzionalmente:

`Avvisami dopo 120 giorni`

Preset suggeriti possono esistere per categoria, ma devono essere indicati come promemoria organizzativi e non come garanzia di sicurezza alimentare.

---

## Notifiche

Preferibile una notifica aggregata settimanale.

Esempio:

> Hai 4 prodotti nel freezer da più di 90 giorni. Il più vecchio è "Spezzatino", congelato 137 giorni fa.

Frequenze:

- settimanale
- ogni 15 giorni
- mensile

---

## Home

### Full Freezer

32 prodotti

**4 da usare presto**

Lista:

- Spezzatino — 137 giorni
- Salmone — 104 giorni
- Piselli — 91 giorni

CTA:

**+ Aggiungi**

Sezione secondaria:

### Dove sono

- Freezer cucina
- Freezer garage

---

## Ricerca

Ricerca immediata.

Esempio:

`pollo`

Risultato:

- Petto di pollo — Cassetto 1 — 46 giorni
- Pollo arrosto — Freezer garage — 22 giorni

---

## Data model

### Freezer

- id
- name

### Compartment

- id
- freezer_id
- name
- sort_order

### Item

- id
- freezer_id
- compartment_id
- name
- category
- quantity
- unit
- frozen_at
- reminder_after_days
- photo_path
- note
- status
- removed_at

---

## Funzioni post-MVP

### Barcode

Scansione barcode per prodotti confezionati.

### Duplicate

Funzione:

**Ne ho congelato un altro uguale**

### Batch

Gestione di più confezioni dello stesso prodotto.

### Statistiche

Esempio mensile:

- consumati 21 prodotti
- buttati 2
- permanenza media 47 giorni

### Widget Android

Esempio:

> 3 prodotti da consumare presto

---

## Monetizzazione

### Free

- inventario completo
- 1 freezer
- reminder base

### Pro — 3,99 € / 5,99 € lifetime

- freezer multipli
- fotografie
- storico
- statistiche
- CSV
- widget
- categorie personalizzate

---

## Architettura tecnica

- Flutter
- SQLite / Drift
- notifiche locali
- file system locale per foto
- export/import JSON
- nessun login
- nessun backend

---

## Complessità

- Backend: 0/5
- Frontend: 2/5
- Logica: 1/5
- UX: 3/5

La parte critica è ridurre l'inserimento di un prodotto a pochi secondi.

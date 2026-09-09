# TrashCan — Spec-sheet operativa

## Concept

Calendario personale della raccolta differenziata.

Non dipende dal Comune.

L'utente inserisce una volta il proprio calendario e l'app ricorda ogni sera cosa deve essere portato fuori.

Esempio:

> Domani raccolgono l'organico. Ricordati di portarlo fuori questa sera.

---

## Target

Chiunque viva in una zona con raccolta porta a porta.

Particolarmente utile per:

- piccoli Comuni
- seconde case
- condomini
- famiglie
- persone che gestiscono più abitazioni

---

## USP

Funziona ovunque, anche senza:

- API comunali
- account
- database centralizzati
- integrazioni con il Comune

L'utente configura il calendario una volta e poi l'app lo segue.

---

## Setup iniziale

Wizard.

### Calendario

Nome:

`Casa`

### Tipi di rifiuto

Preset:

- organico
- carta
- plastica
- vetro
- metalli
- indifferenziato
- verde
- pannolini
- altro

Icone e colori configurabili.

---

## Regole ricorrenti

Esempio:

### Organico

- lunedì
- giovedì

### Plastica

- martedì

### Carta

- mercoledì alterni

### Indifferenziato

- venerdì

Tipi di ricorrenza richiesti:

- ogni settimana
- ogni N settimane
- giorno specifico del mese
- date manuali

---

## Notifiche

Default:

**20:00 del giorno precedente**

Esempio:

> Domani raccolgono l'organico. Ricordati di portarlo fuori questa sera.

Configurazioni:

- ora
- anticipo
- notifiche multiple
- attiva/disattiva per singolo tipo di rifiuto

Esempio:

- prima notifica: 18:00
- seconda notifica: 20:00

---

## Home

La home deve essere brutalmente semplice.

### Stasera

**Organico**

oppure:

### Stasera non devi buttare nulla

Prossima raccolta:

**Plastica — domani sera**

---

## Eccezioni

Feature fondamentale.

Caso:

la carta viene raccolta ogni mercoledì, ma una festività cambia il calendario.

Azioni:

- Salta raccolta
- Sposta raccolta
- Aggiungi raccolta straordinaria

Esempio:

- data originale: 25 dicembre
- nuova data: 26 dicembre

---

## Calendari multipli

Possibili calendari:

- Casa
- Casa al mare
- Nonna
- Ufficio

Ogni calendario ha regole e notifiche indipendenti.

---

## Widget Android

Feature importante.

Esempio:

### Stasera

**PLASTICA**

oppure:

### Niente

Prossimo: Organico domani

Il widget può diventare uno dei principali elementi premium.

---

## Google Calendar

Non necessario nell'MVP.

TrashCan è già un calendario verticale.

L'integrazione con Google Calendar può essere introdotta successivamente come funzione opzionale.

---

## Data model

### CollectionCalendar

- id
- name
- notification_time
- enabled

### WasteType

- id
- calendar_id
- name
- icon
- color

### RecurrenceRule

- id
- waste_type_id
- recurrence_type
- weekday
- interval
- start_date
- day_of_month

### Exception

- id
- recurrence_rule_id
- original_date
- replacement_date
- skipped

---

## Funzioni post-MVP

### Foto calendario cartaceo

L'utente fotografa il calendario distribuito dal Comune.

Una funzione OCR/AI può provare a ricavare automaticamente:

- date
- tipi di rifiuto
- ricorrenze

Non consigliata nel primo MVP.

Può essere una buona funzione premium futura.

### Condivisione

Esporta il calendario come file.

Un altro utente può importarlo.

Nessun server necessario.

### Template Comune

Possibile evoluzione futura:

- Nepi — zona centro — 2027
- Roma — zona X — 2027

Questa funzione richiederebbe un piccolo backend o repository condiviso.

---

## Monetizzazione

### Free

- 1 calendario
- notifiche
- raccolte standard

### Pro — 2,99 € / 4,99 € lifetime

- calendari multipli
- widget avanzato
- backup
- import/export
- notifiche multiple
- personalizzazione completa

Alternativa:

app completamente premium a 2,99 € una tantum.

---

## Architettura tecnica

- Flutter
- SQLite / Drift
- local notifications
- Android widgets
- export/import JSON
- nessun login
- nessun backend

---

## Complessità

- Backend: 0/5
- Frontend: 2/5
- Logica ricorrenze: 3/5
- Notifiche Android: 2/5

È quella con il target potenziale più ampio delle quattro.

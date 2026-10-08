"""Testi dello storico, dei grafici, degli acquisti e dei costi (F5.9, F5.11).

Li raccoglie tool/testi.py (tutti_i_testi): stesso formato, chiave: (inglese, italiano).
Virgolette tipografiche anche in inglese (“…”, ’): con quelle dritte gli script adb non
trovano piu' i riquadri.
"""

TESTI = {
    # ── Storico (F5.9) ──
    'history_title': ('History', 'Storico'),
    'history_open': ('History and charts', 'Storico e grafici'),
    'history_empty': ('No readings yet.', 'Ancora nessuna misurazione.'),
    'history_refillDelta': ('+{amount} · refill', '+{amount} · rifornimento'),
    'history_gauge': ('gauge {reading}%', 'manometro {reading}%'),
    'history_deleted': ('Reading deleted', 'Misurazione eliminata'),
    'history_undo': ('Undo', 'Annulla'),
    'history_freeLimitTitle': ('The free plan shows the last {days} days', 'Il piano gratuito mostra gli ultimi {days} giorni'),
    'history_freeLimitBody': ('{count, plural, =1{1 older reading is kept: you’ll see it with Pro.} other{{count} older readings are kept: you’ll see them with Pro.}}',
                              '{count, plural, =1{1 misurazione più vecchia è conservata: la vedi con il Pro.} other{{count} misurazioni più vecchie sono conservate: le vedi con il Pro.}}'),
    'history_purchases': ('Purchases and costs', 'Acquisti e costi'),
    'history_purchasesHint': ('Average price, spending per winter', 'Prezzo medio, spesa per inverno'),

    # ── Grafici (F5.9) ──
    'chart_stockTitle': ('Stock over time', 'Scorta nel tempo'),
    'chart_rateTitle': ('Daily use between readings', 'Consumo al giorno fra le misure'),
    'chart_refill': ('Refill', 'Rifornimento'),
    'chart_reading': ('Reading', 'Misurazione'),
    'chart_estimate': ('Current estimate', 'Stima attuale'),
    'chart_notEnough': ('The charts appear after two readings.', 'I grafici compaiono dopo due misurazioni.'),
    'chart_lockedTitle': ('Charts', 'Grafici'),
    'chart_lockedBody': ('See how your stock goes down and compare one winter with the next.',
                         'Guarda come scende la scorta e confronta un inverno con l’altro.'),
    'chart_stockSemantics': ('Stock chart, {count} readings from {from} to {to}',
                             'Grafico della scorta, {count} misurazioni dal {from} al {to}'),
    'chart_rateSemantics': ('Daily use chart, {count} intervals', 'Grafico del consumo giornaliero, {count} intervalli'),

    # ── Acquisti (F5.11) ──
    'purchase_title': ('Purchases', 'Acquisti'),
    'purchase_add': ('Add purchase', 'Aggiungi acquisto'),
    'purchase_newTitle': ('New purchase', 'Nuovo acquisto'),
    'purchase_editTitle': ('Purchase', 'Acquisto'),
    'purchase_date': ('Date', 'Data'),
    'purchase_quantity': ('Quantity', 'Quantità'),
    'purchase_cost': ('Total cost', 'Costo totale'),
    'purchase_costHelp': ('Optional. Leave it empty if you don’t know it.', 'Facoltativo. Lascialo vuoto se non lo sai.'),
    'purchase_supplier': ('Supplier', 'Fornitore'),
    'purchase_note': ('Note', 'Nota'),
    'purchase_saved': ('Purchase saved', 'Acquisto salvato'),
    'purchase_deleted': ('Purchase deleted', 'Acquisto eliminato'),
    'purchase_undo': ('Undo', 'Annulla'),
    'purchase_empty': ('No purchases yet. Add the next delivery to see what keeping warm costs you.',
                       'Ancora nessun acquisto. Aggiungi la prossima consegna per vedere quanto ti costa scaldarti.'),
    'purchase_noCost': ('no cost', 'senza costo'),

    # ── Costi (F5.11) ──
    'costs_seasonSpent': ('SPENT IN WINTER {season}', 'SPESA INVERNO {season}'),
    'costs_perUnit': ('{price}/{unit}', '{price}/{unit}'),
    'costs_averagePrice': ('Average price', 'Prezzo medio'),
    'costs_seasonQuantity': ('Bought in the winter', 'Comprati nell’inverno'),
    'costs_uncosted': ('{count, plural, =1{1 purchase without a cost is not counted.} other{{count} purchases without a cost are not counted.}}',
                       '{count, plural, =1{1 acquisto senza costo non è conteggiato.} other{{count} acquisti senza costo non sono conteggiati.}}'),
    'costs_seasonRule': ('A winter runs from 1 October to 31 March.', 'Un inverno va dal 1° ottobre al 31 marzo.'),
    'costs_seasonsTitle': ('WINTER BY WINTER', 'INVERNO PER INVERNO'),
    'costs_seasonName': ('Winter {season}', 'Inverno {season}'),
}

TIPI = {}

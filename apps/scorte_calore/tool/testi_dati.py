"""Testi della sezione "I tuoi dati": CSV e backup (F5.11). Vedi tool/testi.py."""

TESTI = {
    # ── Sezione delle impostazioni ──
    'data_title': ('Your data', 'I tuoi dati'),

    # ── CSV ──
    'csv_export': ('Export to a spreadsheet', 'Esporta in un foglio di calcolo'),
    'csv_exportBody': ('Readings and purchases of every heat source, as a CSV file that opens in Excel.',
                       'Misurazioni e acquisti di tutte le fonti, in un file CSV che si apre con Excel.'),
    'csv_subject': ('Scorte Calore - readings and purchases', 'Scorte Calore - misurazioni e acquisti'),
    'csv_kind': ('Type', 'Tipo'),
    'csv_kindMeasurement': ('Reading', 'Misurazione'),
    'csv_kindPurchase': ('Purchase', 'Acquisto'),
    'csv_source': ('Heat source', 'Fonte'),
    'csv_date': ('Date', 'Data'),
    'csv_quantity': ('Quantity', 'Quantità'),
    'csv_unit': ('Unit', 'Unità'),
    'csv_reading': ('Gauge reading %', 'Lettura %'),
    'csv_cost': ('Cost (€)', 'Costo (€)'),
    'csv_supplier': ('Supplier', 'Fornitore'),
    'csv_note': ('Note', 'Nota'),

    # ── Backup ──
    'backup_create': ('Back up everything', 'Fai un backup di tutto'),
    'backup_createBody': ('Heat sources, readings and purchases in one file, to keep or move to a new phone. Calendar reminders stay out: set them again after restoring.',
                          'Fonti, misurazioni e acquisti in un solo file, da conservare o portare su un telefono nuovo. I promemoria del calendario restano fuori: rimettili dopo il ripristino.'),
    'backup_createFailed': ('The backup could not be created. Try again.', 'Non sono riuscito a creare il backup. Riprova.'),
    'backup_subject': ('Scorte Calore backup', 'Backup di Scorte Calore'),
    'backup_restore': ('Restore from a backup', 'Ripristina da un backup'),
    'backup_restoreBody': ('Bring back the data from a file made with “Back up everything”.',
                           'Riporta i dati da un file fatto con «Fai un backup di tutto».'),
    'backup_restoreTitle': ('What to do with this backup?', 'Cosa faccio con questo backup?'),
    'backup_restoreSummary': ('Heat sources: {sources} · readings: {measurements} · purchases: {purchases}.',
                              'Fonti: {sources} · misurazioni: {measurements} · acquisti: {purchases}.'),
    'backup_modeReplace': ('Replace everything', 'Sostituisci tutto'),
    'backup_modeReplaceBody': ('What’s on this phone now is deleted and replaced by the backup.',
                               'Quello che c’è ora su questo telefono si cancella e al suo posto va il backup.'),
    'backup_modeMerge': ('Add to what I have', 'Aggiungi a quello che ho'),
    'backup_modeMergeBody': ('Heat sources with the same name as one already here are skipped.',
                             'Le fonti con lo stesso nome di una già presente vengono saltate.'),
    'backup_restored': ('Backup restored', 'Backup ripristinato'),
    'backup_failed': ('That file isn’t a Scorte Calore backup, or it’s damaged.',
                      'Quel file non è un backup di Scorte Calore, o è rovinato.'),
}

TIPI = {
    'sources': 'int', 'measurements': 'int', 'purchases': 'int',
}

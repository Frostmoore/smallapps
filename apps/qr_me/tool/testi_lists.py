"""Testi di preferiti, cronologia, impostazioni e dati (F17.4).

Caricato da tool/testi.py. Chiave: (inglese, italiano). Virgolette tipografiche.
"""

TESTI = {
    # ── Preferiti ──
    'saved_emptyTitle': ('No favourites yet', 'Ancora nessun preferito'),
    'saved_emptyBody': ('Open a QR code and tap “Save”: your home Wi-Fi, always at hand.',
                        'Apri un QR e tocca «Salva»: il Wi-Fi di casa, sempre a portata di mano.'),
    'saved_freeLimit': ('The free plan keeps 1 favourite. Unlimited with Pro.', 'Il piano gratuito tiene 1 preferito. Senza limite con Pro.'),
    'saved_rename': ('Rename', 'Rinomina'),
    'saved_unfavorite': ('Remove from favourites', 'Togli dai preferiti'),
    'saved_deleteTitle': ('Delete this QR code?', 'Eliminare questo QR?'),
    'saved_deleteBody': ('“{title}” will be deleted for good.', '«{title}» sarà eliminato per sempre.'),

    # ── Cronologia ──
    'history_emptyTitle': ('No history', 'Cronologia vuota'),
    'history_emptyBody': ('The QR codes you show or read appear here.', 'Qui compaiono i QR che mostri o leggi.'),
    'history_off': ('History is off: new QR codes aren’t saved.', 'La cronologia è spenta: i nuovi QR non si salvano.'),
    'history_freeNote': ('The free history keeps the last 5. With Pro, all of them from now on.',
                         'La cronologia gratuita tiene gli ultimi 5. Con Pro tutti, da adesso in poi.'),
    'history_clear': ('Clear history', 'Cancella la cronologia'),
    'history_clearTitle': ('Clear history?', 'Cancellare la cronologia?'),
    'history_clearBody': ('Every QR code in the history will be deleted. Favourites stay.',
                          'Tutti i QR della cronologia saranno eliminati. I preferiti restano.'),
    'history_cleared': ('History cleared', 'Cronologia cancellata'),

    # ── Impostazioni ──
    'settings_historyOn': ('Keep a history', 'Tieni la cronologia'),
    'settings_historyBody': ('Off, nothing you show or read is saved: useful for passwords and private text.',
                             'Spenta, niente di ciò che mostri o leggi viene salvato: utile per password e testi privati.'),
    'settings_proLabel': ('Pro', 'Pro'),
    'settings_appLabel': ('App', 'App'),
    'settings_privacy': ('Privacy', 'Privacy'),
    'settings_privacyBody': ('QR Me has no account and sends nothing from your phone: QR codes, history, favourites and logos stay on this device. '
                             'On Android, buying Pro asks Google Play and our licence server to confirm the purchase. '
                             'Phone backups don’t include QR Me’s data: a backup is only the file you create yourself.',
                             'QR Me non ha account e non manda niente fuori dal telefono: QR, cronologia, preferiti e loghi restano su questo dispositivo. '
                             'Su Android l’acquisto del Pro chiede conferma a Google Play e al nostro server delle licenze. '
                             'I backup automatici del telefono non contengono i dati di QR Me: un backup è solo il file che crei tu.'),
    'settings_about': ('About', 'Informazioni'),
    'settings_aboutBody': ('Share anything and it becomes a full-screen QR code; it reads them too.',
                           'Condividi qualunque cosa e diventa un QR a tutto schermo; e sa anche leggerli.'),

    # ── Dati: backup e ripristino ──
    'data_title': ('Your data', 'I tuoi dati'),
    'backup_create': ('Create backup', 'Crea un backup'),
    'backup_createBody': ('Favourites, history and logos in one file', 'Preferiti, cronologia e loghi in un file'),
    'backup_creating': ('Creating the backup…', 'Creo il backup…'),
    'backup_createFailed': ('Couldn’t create the backup. Try again.', 'Non sono riuscito a creare il backup. Riprova.'),
    'backup_subject': ('QR Me backup', 'Backup di QR Me'),
    'backup_restore': ('Restore a backup', 'Ripristina un backup'),
    'backup_restoreBody': ('From a file created by QR Me, free', 'Da un file creato da QR Me, gratis'),
    'backup_restoreTitle': ('Restore this backup?', 'Ripristinare questo backup?'),
    'backup_restoreSummary': ('{favorites, plural, =1{1 favourite} other{{favorites} favourites}} and {history, plural, =1{1 QR code} other{{history} QR codes}} in the history.',
                              '{favorites, plural, =1{1 preferito} other{{favorites} preferiti}} e {history, plural, =1{1 QR} other{{history} QR}} in cronologia.'),
    'backup_modeReplace': ('Replace everything', 'Sostituisci tutto'),
    'backup_modeReplaceBody': ('What’s on this phone now is deleted', 'Ciò che c’è ora su questo telefono si cancella'),
    'backup_modeMerge': ('Add what’s missing', 'Aggiungi ciò che manca'),
    'backup_modeMergeBody': ('Keeps what’s already here', 'Tiene quello che c’è già'),
    'backup_restoring': ('Restoring…', 'Ripristino…'),
    'backup_restored': ('Backup restored', 'Backup ripristinato'),
    'backup_failed': ('This file isn’t a QR Me backup, or it’s damaged.', 'Questo file non è un backup di QR Me, o è rovinato.'),
}

TIPI = {'favorites': 'int', 'history': 'int'}

"""Testi delle foto dei rullini (F6.9, gratis per F6.0 punto 3) e del QR del rullino (F6.12).
Vedi tool/testi.py: questo file lo legge da solo, per il nome testi_*.py."""

TESTI = {
    # ── Foto del rullino (F6.9) ──
    'photo_sectionTitle': ('Photos', 'Foto'),
    'photo_add': ('Add', 'Aggiungi'),
    'photo_emptyTitle': ('No photos yet', 'Ancora nessuna foto'),
    'photo_emptyBody': ('Add the contact sheet, the prints or the scans: the roll will show its cover in the archive.',
                        'Aggiungi i provini, le stampe o le scansioni: il rullino mostrerà la sua copertina nell’archivio.'),
    'photo_camera': ('Take a photo', 'Scatta una foto'),
    'photo_gallery': ('Choose from photos', 'Scegli dalle foto'),
    'photo_galleryHint': ('You can pick more than one.', 'Puoi sceglierne più di una.'),
    'photo_kindLabel': ('What is it?', 'Che cos’è?'),
    'photo_kind_contactSheet': ('Contact sheet', 'Provini'),
    'photo_kind_print': ('Print', 'Stampa'),
    'photo_kind_scan': ('Scan', 'Scansione'),
    'photo_kind_other': ('Other', 'Altro'),
    'photo_importing': ('Importing {done} of {total}…', 'Importo {done} di {total}…'),
    'photo_importCancelling': ('Stopping after this photo…', 'Mi fermo dopo questa foto…'),
    'photo_imported': ('{count, plural, =1{1 photo added} other{{count} photos added}}',
                       '{count, plural, =1{1 foto aggiunta} other{{count} foto aggiunte}}'),
    'photo_importFailed': ('{count, plural, =1{1 photo couldn’t be read} other{{count} photos couldn’t be read}}',
                           '{count, plural, =1{1 foto non si è potuta leggere} other{{count} foto non si sono potute leggere}}'),
    'photo_pickFailed': ('Couldn’t open the camera or your photos. Check the permissions in Settings.',
                         'Non riesco ad aprire la fotocamera o le foto. Controlla i permessi nelle Impostazioni.'),
    'photo_cover': ('Cover', 'Copertina'),
    'photo_setCover': ('Use as cover', 'Usa come copertina'),
    'photo_coverSet': ('Cover changed', 'Copertina cambiata'),
    'photo_open': ('Open', 'Apri'),
    'photo_reorder': ('Reorder', 'Riordina'),
    'photo_reorderHint': ('Drag the photos into the order you want.', 'Trascina le foto nell’ordine che preferisci.'),
    'photo_done': ('Done', 'Fatto'),
    'photo_delete': ('Delete photo', 'Elimina foto'),
    'photo_deleteTitle': ('Delete this photo?', 'Eliminare questa foto?'),
    'photo_deleteBody': ('It is removed from the roll and from the phone. The original in your photos stays where it is.',
                         'Sparisce dal rullino e dal telefono. L’originale nelle tue foto resta dov’è.'),
    'photo_deleted': ('Photo deleted', 'Foto eliminata'),
    'photo_missing': ('This photo is no longer on the phone.', 'Questa foto non è più sul telefono.'),
    'photo_position': ('{index} of {total}', '{index} di {total}'),
    'photo_thumbLabel': ('Photo {index}', 'Foto {index}'),

    # ── Spazio occupato, nelle impostazioni (F6.9) ──
    'photo_storageTitle': ('Photo storage', 'Spazio delle foto'),
    'photo_storageUsed': ('{size} used. Tap to free up space.', '{size} occupati. Tocca per liberare spazio.'),
    'photo_storageLoading': ('Calculating…', 'Calcolo in corso…'),
    'photo_freeTitle': ('Free up space?', 'Liberare spazio?'),
    'photo_freeBody': ('Removes the files no roll uses any more, left behind by interrupted deletions. Your rolls’ photos stay.',
                       'Toglie i file che nessun rullino usa più, rimasti da cancellazioni interrotte. Le foto dei rullini restano.'),
    'photo_freeConfirm': ('Free up space', 'Libera spazio'),
    'photo_freed': ('{count, plural, =1{1 file removed} other{{count} files removed}}',
                    '{count, plural, =1{1 file rimosso} other{{count} file rimossi}}'),
    'photo_freedNothing': ('Nothing to remove: every file belongs to a roll.', 'Niente da togliere: ogni file appartiene a un rullino.'),

    # ── QR del rullino (F6.12) ──
    'qr_title': ('Roll label', 'Etichetta del rullino'),
    'qr_action': ('QR label', 'Etichetta QR'),
    'qr_hint': ('Print it or take a photo of it and stick it on the roll’s canister. Scanning it with the camera opens this roll.',
                'Stampala o fotografala e attaccala al contenitore del rullino. Inquadrandola con la fotocamera si apre questo rullino.'),
    'qr_number': ('#{n}', '#{n}'),
    'qr_semantics': ('QR code of roll {n}', 'Codice QR del rullino {n}'),
    'qr_rollMissing': ('This roll doesn’t exist any more.', 'Questo rullino non esiste più.'),
}

TIPI = {
    'done': 'int', 'total': 'int', 'index': 'int',
}

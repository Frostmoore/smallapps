"""Testi della home, della pagina del QR, del salvataggio e della condivisione (F17.4).

Caricato da tool/testi.py. Chiave: (inglese, italiano). Virgolette tipografiche.
"""

TESTI = {
    # ── Comuni aggiunti con F17.4 ──
    'common_close': ('Close', 'Chiudi'),
    'common_more': ('More', 'Altro'),
    'common_loadFailed': ('Couldn’t load this list. Try reopening the app.', 'Non riesco a caricare l’elenco. Prova a riaprire l’app.'),

    # ── Home (F17.1.6) ──
    'home_writeLabel': ('Write or paste', 'Scrivi o incolla'),
    'home_writeHint': ('A link, a message, anything…', 'Un link, un messaggio, quello che vuoi…'),
    'home_paste': ('Paste', 'Incolla'),
    'home_show': ('Show QR code', 'Mostra QR'),
    'home_clipboardEmpty': ('There’s no text to paste.', 'Non c’è testo da incollare.'),
    'home_scan': ('Read a QR code', 'Leggi un QR'),
    'home_scanBody': ('With the camera or from a picture', 'Con la fotocamera o da un’immagine'),
    'home_formsLabel': ('Forms', 'Moduli'),
    'home_favoritesLabel': ('Favourites', 'Preferiti'),
    'home_recentLabel': ('Recent', 'Recenti'),
    'home_seeAll': ('See all', 'Vedi tutti'),
    'home_freeHistory': ('The free history keeps the last 5 QR codes.', 'La cronologia gratuita tiene gli ultimi 5 QR.'),
    'home_freeHistoryCta': ('Keep them all with Pro', 'Tienili tutti con Pro'),
    'home_emptyTitle': ('Share anything to QR Me', 'Condividi qualunque cosa con QR Me'),
    'home_emptyBody': ('Share a link or some text from any app and pick QR Me: the QR code is already there, big and bright.',
                       'Condividi un link o un testo da qualunque app e scegli QR Me: il QR è già lì, grande e luminoso.'),

    # ── Pagina del QR (F17.1.6) ──
    'display_semantics': ('QR code: {title}', 'Codice QR: {title}'),
    'display_missingBody': ('It may have been deleted from favourites or history.', 'Forse è stato cancellato dai preferiti o dalla cronologia.'),
    'display_tooLongTitle': ('Too long for a QR code', 'Troppo lungo per un QR'),
    'display_tooLongBody': ('{n} characters: a QR code holds about 2,900 at most. Try sharing a link instead.',
                            '{n} caratteri: in un QR ne stanno al massimo circa 2.900. Prova a condividere un link.'),
    'display_logoDropped': ('Text too long for the logo: the QR code is shown without it.', 'Testo troppo lungo per il logo: il QR si mostra senza.'),
    'display_dense': ('Very dense QR code: hold the phone close.', 'QR molto fitto: avvicina il telefono.'),
    'display_showPassword': ('Show password', 'Mostra la password'),
    'display_hidePassword': ('Hide password', 'Nascondi la password'),
    'display_style': ('Style', 'Stile'),
    'display_image': ('Image', 'Immagine'),
    'display_saved': ('Saved', 'Salvato'),
    'display_alreadySaved': ('Already in your favourites.', 'È già nei preferiti.'),
    'display_shareFailed': ('Couldn’t create the image. Try again.', 'Non sono riuscito a creare l’immagine. Riprova.'),

    # ── Salvataggio nei preferiti ──
    'save_title': ('Save to favourites', 'Salva nei preferiti'),
    'save_name': ('Name', 'Nome'),
    'save_done': ('Saved to favourites', 'Salvato nei preferiti'),

    # ── Wi-Fi in chiaro (sotto il QR e nel risultato) ──
    'wifi_network': ('Network: {ssid}', 'Rete: {ssid}'),
    'wifi_password': ('Password: {password}', 'Password: {password}'),

    # ── Condivisione verso l'app (F17.1.7) ──
    'share_noQrInImage': ('No QR code in this picture.', 'Nessun QR in questa immagine.'),
}

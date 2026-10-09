"""Testi della lettura e del risultato (F17.4).

Caricato da tool/testi.py. Chiave: (inglese, italiano). Virgolette tipografiche.
"""

TESTI = {
    # ── Lettura (F17.1.6) ──
    'scan_hint': ('Frame the QR code inside the corners', 'Inquadra il QR dentro gli angoli'),
    'scan_fromImage': ('From a picture', 'Da immagine'),
    'scan_torch': ('Torch', 'Torcia'),
    'scan_deniedTitle': ('The camera is off for QR Me', 'La fotocamera è spenta per QR Me'),
    'scan_deniedBody': ('Allow the camera for QR Me in the phone’s settings. Meanwhile you can read a QR code from a picture.',
                        'Consenti la fotocamera a QR Me nelle impostazioni del telefono. Intanto puoi leggere un QR da un’immagine.'),
    'scan_errorTitle': ('The camera didn’t start', 'La fotocamera non è partita'),
    'scan_errorBody': ('Try again, or read the QR code from a picture.', 'Riprova, oppure leggi il QR da un’immagine.'),
    'scan_openSettings': ('Open settings', 'Apri le impostazioni'),
    'scan_readerUnavailable': ('Pictures can’t be read on this device.', 'Su questo dispositivo non riesco a leggere le immagini.'),

    # ── Risultato (F17.1.6) ──
    'result_goesTo': ('Goes to', 'Porta a'),
    'result_open': ('Open', 'Apri'),
    'result_copyLink': ('Copy link', 'Copia il link'),
    'result_call': ('Call', 'Chiama'),
    'result_email': ('Write email', 'Scrivi email'),
    'result_sms': ('Send SMS', 'Manda SMS'),
    'result_copyPassword': ('Copy password', 'Copia la password'),
    'result_showAsQr': ('Show as QR code', 'Mostra come QR'),
    'result_restyle': ('Restyle', 'Rigenera con stile'),
    'result_noApp': ('No app on this phone can open it.', 'Nessuna app sul telefono sa aprirlo.'),
}

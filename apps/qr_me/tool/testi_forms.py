"""Testi dei moduli speciali (F17.4, Pro).

Caricato da tool/testi.py. Chiave: (inglese, italiano). Virgolette tipografiche.
"""

TESTI = {
    'form_editTitle': ('Edit {kind}', 'Modifica {kind}'),
    'form_fillIn': ('Fill in the form: the QR code appears here.', 'Compila il modulo: il QR compare qui.'),
    'form_required': ('Required', 'Obbligatorio'),
    'form_invalidEmail': ('This doesn’t look like an email address', 'Non sembra un indirizzo email'),
    'form_invalidPhone': ('Digits only, with + in front if needed', 'Solo cifre, con il + davanti se serve'),
    'form_tooLong': ('Too long for a QR code: shorten the note or the text.', 'Troppo lungo per un QR: accorcia la nota o il testo.'),

    # ── Wi-Fi ──
    'wifi_ssid': ('Network name (SSID)', 'Nome della rete (SSID)'),
    'wifi_passwordLabel': ('Password', 'Password'),
    'wifi_wpa': ('WPA', 'WPA'),
    'wifi_wep': ('WEP', 'WEP'),
    'wifi_open': ('None', 'Nessuna'),
    'wifi_hidden': ('Hidden network', 'Rete nascosta'),
    'wifi_hiddenBody': ('Only if the network doesn’t show up in the list', 'Solo se la rete non compare nell’elenco'),

    # ── Contatto ──
    'contact_name': ('Name and surname', 'Nome e cognome'),
    'contact_phone': ('Phone', 'Telefono'),
    'contact_email': ('Email', 'Email'),
    'contact_organization': ('Company', 'Azienda'),
    'contact_url': ('Website', 'Sito'),
    'contact_note': ('Note', 'Nota'),

    # ── Email ──
    'email_to': ('To', 'A'),
    'email_subject': ('Subject', 'Oggetto'),
    'email_body': ('Message', 'Testo'),

    # ── SMS e telefono ──
    'sms_number': ('Number', 'Numero'),
    'sms_body': ('Message', 'Testo'),
    'phone_number': ('Number', 'Numero'),
}

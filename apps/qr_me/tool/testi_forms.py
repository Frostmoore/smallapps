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

    # ⚑ SMS e Telefono: moduli tolti in F17.10 punto 4 (la lettura resta, con i testi di
    # testi_scan.py). Le loro chiavi sono state cancellate, non lasciate orfane.

    # ── Le strade dei moduli (F17.10) ──
    'form_otherWays': ('Other ways', 'Altri modi'),

    # Wi-Fi (F17.10 punto 1)
    'wifiSource_intro': ('Where’s the network? From its QR code or from the phone: nothing to type.',
                         'Da dove prendo la rete? Dal suo QR o dal telefono: niente da scrivere.'),
    'wifiSource_scan': ('Scan the network’s QR code', 'Inquadra il QR della rete'),
    'wifiSource_scanBody': ('The one on the router, or on another phone (Settings › Wi-Fi › Share)',
                            'Quello del router, o di un altro telefono (Impostazioni › Wi-Fi › Condividi)'),
    'wifiSource_image': ('From a picture', 'Da un’immagine'),
    'wifiSource_imageBody': ('A screenshot of the network’s QR code, or a photo of the router label',
                             'Uno screenshot del QR della rete, o la foto dell’etichetta del router'),
    'wifiSource_connected': ('The network you’re on', 'La rete a cui sei connesso'),
    'wifiSource_connectedBody': ('The phone reads the name, you paste the password',
                                 'Il nome lo legge il telefono, la password la incolli'),
    'wifiSource_manual': ('Enter it by hand', 'Inserisci a mano'),
    'wifiSource_notWifi': ('This QR code isn’t a Wi-Fi network. Frame the network’s one.',
                           'Questo QR non è di una rete Wi-Fi. Inquadra quello della rete.'),
    'wifiSource_notWifiImage': ('There’s no Wi-Fi network QR code in this picture.',
                                'In questa immagine non c’è il QR di una rete Wi-Fi.'),
    'wifiSource_permissionTitle': ('The network name', 'Il nome della rete'),
    'wifiSource_permissionAndroid': ('Android tells an app the name of your Wi-Fi network only if it has the precise location permission. QR Me doesn’t use or save your location: it only reads the network name. In the next window choose “Precise”.',
                                     'Android dice a un’app il nome della rete Wi-Fi solo se ha il permesso di posizione precisa. QR Me non usa e non salva la posizione: legge solo il nome della rete. Nella prossima finestra scegli “Precisa”.'),
    'wifiSource_permissionIos': ('iOS tells an app the name of your Wi-Fi network only if it may use your location while you use it. QR Me doesn’t use or save your location: it only reads the network name.',
                                 'iOS dice a un’app il nome della rete Wi-Fi solo se può usare la posizione mentre la usi. QR Me non usa e non salva la posizione: legge solo il nome della rete.'),
    'wifiSource_permissionContinue': ('Continue', 'Continua'),
    'wifiSource_denied': ('Without the location permission the phone won’t tell the network name. Try again, or enter the network by hand.',
                          'Senza il permesso di posizione il telefono non dice il nome della rete. Riprova, oppure inserisci la rete a mano.'),
    'wifiSource_deniedForever': ('Location is off for QR Me. Turn it on in the settings (it’s only used to read the network name), or enter the network by hand.',
                                 'La posizione è spenta per QR Me. Accendila nelle impostazioni (serve solo a leggere il nome della rete), oppure inserisci la rete a mano.'),
    'wifiSource_locationOff': ('The phone’s location is off: turn it on for a moment and try again.',
                               'La localizzazione del telefono è spenta: accendila un momento e riprova.'),
    'wifiSource_unavailable': ('I can’t read the network name: maybe the phone isn’t on Wi-Fi, or location is only approximate. You can enter the network by hand.',
                               'Non riesco a leggere il nome della rete: forse il telefono non è connesso a un Wi-Fi, o la posizione è solo approssimativa. Puoi inserire la rete a mano.'),
    'wifiSource_pastePassword': ('Paste the password', 'Incolla la password'),
    'wifiSource_whereIos': ('To copy it: Settings › Wi-Fi › (i) next to the network › Password: tap it and choose Copy.',
                            'Per copiarla: Impostazioni › Wi-Fi › (i) accanto alla rete › Password: toccala e scegli Copia.'),
    'wifiSource_whereAndroid': ('To find it: Settings › Wi-Fi › the network › Share: the password is under the QR code. Or take a screenshot of that QR code and use “From a picture”.',
                                'Per trovarla: Impostazioni › Wi-Fi › la rete › Condividi: la password è sotto il QR. Oppure fai uno screenshot di quel QR e usa “Da un’immagine”.'),

    # Contatto (F17.10 punto 2)
    'contactSource_intro': ('Pick a contact or use your own card: nothing to type.',
                            'Scegli un contatto o usa la tua scheda: niente da scrivere.'),
    'contactSource_pick': ('Pick from contacts', 'Scegli dalla rubrica'),
    'contactSource_pickBody': ('QR Me only gets the contact you tap, not your address book',
                               'QR Me riceve solo il contatto che tocchi, non la rubrica'),
    'contactSource_me': ('Me', 'Io'),
    'contactSource_meEmpty': ('Your card: pick it or fill it in once, then it’s always ready',
                              'La tua scheda: la scegli o la compili una volta, poi è sempre pronta'),
    'contactSource_meSaved': ('{name}: your card, ready', '{name}: la tua scheda, pronta'),
    'contactSource_pickFailed': ('Couldn’t open the contacts.', 'Non riesco ad aprire la rubrica.'),

    # La scheda «Io» (/me)
    'myContact_title': ('My card', 'La mia scheda'),
    'myContact_intro': ('Your contact card for the “Me” QR code. It stays on this phone, inside QR Me.',
                        'La tua scheda per il QR “Io”. Resta su questo telefono, dentro QR Me.'),
    'myContact_pickBody': ('Pick yourself: name and phone fill in by themselves',
                           'Scegli te stesso: nome e telefono si compilano da soli'),
    'myContact_edit': ('Edit my card', 'Modifica la mia scheda'),
    'myContact_saved': ('Card saved', 'Scheda salvata'),
    'myContact_delete': ('Delete my card', 'Elimina la mia scheda'),
    'myContact_deleteTitle': ('Delete your card?', 'Eliminare la tua scheda?'),
    'myContact_deleteBody': ('QR codes already made stay. Next time “Me” will ask for it again.',
                             'I QR già creati restano. La prossima volta “Io” te la richiede.'),
    'myContact_none': ('Not saved yet', 'Non ancora salvata'),

    # ── Etichetta da stampare (F17.10 punto 5, Pro) ──
    'display_label': ('Label', 'Etichetta'),
    'label_title': ('Label to print', 'Etichetta da stampare'),
    'label_textLabel': ('Text under the QR code', 'Testo sotto il QR'),
    'label_textHelp': ('One or two lines. Empty: just the QR code.', 'Una o due righe. Vuoto: solo il QR.'),
    'label_square': ('Square', 'Quadrata'),
    'label_tall': ('Rectangular', 'Rettangolare'),
    'label_print': ('Print', 'Stampa'),
    'label_share': ('Share image', 'Condividi immagine'),
    'label_failed': ('Couldn’t create the label. Try again.', 'Non sono riuscito a creare l’etichetta. Riprova.'),
}

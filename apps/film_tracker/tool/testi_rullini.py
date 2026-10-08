"""Testi della home, dei rullini e degli stati (F6.6, F6.8). Vedi tool/testi.py.

Prefissi: home_ (la home a tre sezioni), roll_ (form e dettaglio del rullino, nomi dei formati
e dei processi), status_ (gli stati del rullino, uno per valore di RollStatus).

⚑ Le chiavi status_<chiave>, roll_format_<nome> e roll_process_<nome> si risolvono in
lib/app/labels.dart: chi aggiunge un valore a un enum aggiunge qui la riga, altrimenti lo
switch di labels.dart non compila (e' voluto: niente etichette dimenticate).
"""

TESTI = {
    # ── Home (F6.8) ──
    'home_inCamera': ('In camera', 'In macchina'),
    'home_atLab': ('At the lab', 'In laboratorio'),
    'home_archive': ('Archive', 'Archivio'),
    'home_newRoll': ('New roll', 'Nuovo rullino'),
    'home_menuCameras': ('Cameras', 'Macchine'),
    'home_menuStocks': ('Film stocks', 'Pellicole'),
    'home_menuMore': ('More', 'Altro'),
    'home_emptyTitle': ('Your first roll', 'Il tuo primo rullino'),
    'home_emptyBody': ('Note the film you load in the camera: it will follow you to the lab and into the archive, with its photos.',
                       'Segna la pellicola che carichi in macchina: ti segue fino al laboratorio e nell’archivio, con le sue foto.'),
    'home_emptyAction': ('Load a roll', 'Carica un rullino'),
    'home_inCameraEmpty': ('No roll in a camera. Tap “New roll” when you load one.',
                           'Nessun rullino in macchina. Tocca “Nuovo rullino” quando ne carichi uno.'),
    'home_atLabEmpty': ('Nothing at the lab right now.', 'Niente in laboratorio, per ora.'),
    'home_archiveEmpty': ('Developed rolls end up here, with their photos.',
                          'Qui finiscono i rullini sviluppati, con le loro foto.'),
    'home_loadedDaysAgo': ('{days, plural, =0{Loaded today} =1{Loaded yesterday} other{Loaded {days} days ago}}',
                           '{days, plural, =0{Caricato oggi} =1{Caricato ieri} other{Caricato {days} giorni fa}}'),
    'home_notLoadedYet': ('No loading date', 'Senza data di caricamento'),
    'home_finishedToDeliver': ('Finished · to deliver', 'Terminato · da consegnare'),
    'home_deliveredDaysAgo': ('{days, plural, =0{delivered today} =1{delivered yesterday} other{delivered {days} days ago}}',
                              '{days, plural, =0{consegnato oggi} =1{consegnato ieri} other{consegnato {days} giorni fa}}'),
    'home_delivered': ('delivered', 'consegnato'),
    'home_loadError': ('Couldn’t read your rolls', 'Non riesco a leggere i rullini'),
    'home_loadErrorBody': ('Your data is still there. Try again in a moment.',
                           'I dati sono ancora lì. Riprova tra un momento.'),

    # ── Form del rullino (F6.6) ──
    'roll_newTitle': ('New roll', 'Nuovo rullino'),
    'roll_editTitle': ('Edit roll', 'Modifica rullino'),
    'roll_film': ('Film', 'Pellicola'),
    'roll_filmChoose': ('Choose the film', 'Scegli la pellicola'),
    'roll_camera': ('Camera', 'Macchina'),
    'roll_cameraNone': ('No camera', 'Nessuna macchina'),
    'roll_cameraEmpty': ('You haven’t added a camera yet. It’s optional.',
                         'Non hai ancora aggiunto una macchina. È facoltativa.'),
    'roll_cameraAdd': ('Add a camera', 'Aggiungi una macchina'),
    'roll_format': ('Format', 'Formato'),
    'roll_exposedIso': ('Exposed at ISO', 'ISO di esposizione'),
    'roll_exposedIsoHelp': ('Nominal {iso}. Change it if you push or pull the film.',
                            'Nominale {iso}. Cambialo se fai push o pull.'),
    'roll_frames': ('Frames', 'Fotogrammi'),
    'roll_loadedAt': ('Loaded on', 'Caricato il'),
    'roll_finishedAt': ('Finished on', 'Finito il'),
    'roll_details': ('Optional details', 'Dettagli facoltativi'),
    'roll_title': ('Title', 'Titolo'),
    'roll_titleHint': ('“Prague — September”', '“Praga — settembre”'),
    'roll_note': ('Note', 'Nota'),
    'roll_cost': ('Cost of the roll', 'Costo del rullino'),
    'roll_costInvalid': ('Write an amount, like 6.50', 'Scrivi un importo, come 6,50'),
    'roll_saveError': ('Couldn’t save. Check the dates: a roll can’t finish before it’s loaded.',
                       'Non riesco a salvare. Controlla le date: un rullino non può finire prima di essere caricato.'),

    # ── Scelta della pellicola (F6.4, dal form) ──
    'roll_stockSearch': ('Search film', 'Cerca una pellicola'),
    'roll_stockMostUsed': ('Most used', 'Le più usate'),
    'roll_stockCustom': ('Custom film', 'Pellicola personalizzata'),
    'roll_stockCustomHelp': ('Not in the list? Add it.', 'Non è nell’elenco? Aggiungila.'),
    'roll_stockNoResults': ('No film matches “{query}”.', 'Nessuna pellicola corrisponde a “{query}”.'),

    # ── Dettaglio del rullino (F6.6) ──
    'roll_detailTitle': ('Roll #{n}', 'Rullino #{n}'),
    'roll_notFound': ('This roll no longer exists.', 'Questo rullino non esiste più.'),
    'roll_framesCount': ('{n, plural, =1{1 frame} other{{n} frames}}', '{n, plural, =1{1 fotogramma} other{{n} fotogrammi}}'),
    'roll_exposedAt': ('exposed at {iso}', 'esposta a {iso}'),
    'roll_timeline': ('Timeline', 'Cronologia'),
    'roll_eventLoaded': ('Loaded', 'Caricato'),
    'roll_eventFinished': ('Finished', 'Terminato'),
    'roll_eventDelivered': ('Delivered to the lab', 'Consegnato al laboratorio'),
    'roll_eventSelfDeveloped': ('Developed at home', 'Sviluppato in casa'),
    'roll_eventDeveloped': ('Developed', 'Sviluppato'),
    'roll_eventPrinted': ('Printed', 'Stampato'),
    'roll_eventPrintOrdered': ('Prints ordered', 'Stampe ordinate'),
    'roll_eventPrintBack': ('Prints back', 'Stampe ritirate'),
    'roll_eventNotYet': ('Not yet', 'Non ancora'),
    'roll_noDate': ('No date', 'Senza data'),
    'roll_costDevelopment': ('developing {amount}', 'sviluppo {amount}'),
    'roll_costScan': ('scans {amount}', 'scansioni {amount}'),
    'roll_printsCount': ('{n, plural, =1{1 print} other{{n} prints}}', '{n, plural, =1{1 stampa} other{{n} stampe}}'),
    'roll_totalCost': ('Total spent: {amount}', 'Spesa totale: {amount}'),
    'roll_actionFinished': ('Roll finished', 'Rullino terminato'),
    'roll_actionDeliver': ('Deliver to the lab', 'Consegna al laboratorio'),
    'roll_actionDevelopment': ('Record development', 'Registra sviluppo'),
    'roll_actionAddPrint': ('Add prints', 'Aggiungi stampa'),
    'roll_actionArchive': ('Archive', 'Archivia'),
    'roll_finishedDone': ('Marked as finished.', 'Segnato come terminato.'),
    'roll_changeStatus': ('Change status', 'Cambia stato'),
    'roll_changeStatusHelp': ('From “{status}” you can go to:', 'Da “{status}” puoi passare a:'),
    'roll_statusChanged': ('Status: {status}.', 'Stato: {status}.'),
    'roll_suggestion': ('Development and prints say “{status}”.', 'Sviluppo e stampe dicono “{status}”.'),
    'roll_suggestionApply': ('Apply', 'Applica'),
    'roll_qr': ('QR label', 'Etichetta QR'),
    'roll_delete': ('Delete roll', 'Elimina rullino'),
    'roll_deleteTitle': ('Delete roll #{n}?', 'Eliminare il rullino #{n}?'),
    'roll_deleteBody': ('Development, prints and photos go with it, including the photo files on this phone. This can’t be undone.',
                        'Se ne vanno anche sviluppo, stampe e foto, compresi i file sul telefono. Non si può annullare.'),
    'roll_deleted': ('Roll deleted.', 'Rullino eliminato.'),

    # ── Formati e processi (risolti in lib/app/labels.dart) ──
    'roll_format_mm35': ('35 mm', '35 mm'),
    'roll_format_medium120': ('120', '120'),
    'roll_format_mm110': ('110', '110'),
    'roll_format_large': ('Large format', 'Grande formato'),
    'roll_format_other': ('Other', 'Altro'),
    'roll_process_c41': ('C-41', 'C-41'),
    'roll_process_e6': ('E-6', 'E-6'),
    'roll_process_bw': ('Black & white', 'Bianco e nero'),
    'roll_process_ecn2': ('ECN-2', 'ECN-2'),
    'roll_process_other': ('Other', 'Altro'),

    # ── Stati del rullino (F6.3), con la chiave di RollStatus ──
    'status_loaded': ('In camera', 'In macchina'),
    'status_exposed': ('Finished', 'Terminato'),
    'status_sentForDevelopment': ('At the lab', 'In laboratorio'),
    'status_developed': ('Developed', 'Sviluppato'),
    'status_printed': ('Printed', 'Stampato'),
    'status_archived': ('Archived', 'Archiviato'),
}

TIPI = {
    'iso': 'int',
}

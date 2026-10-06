<?php

/**
 * I testi italiani del sito.
 *
 * ⚑ Le chiavi sono piatte e puntate (`home.hero.titolo`), non annidate: una ricerca
 * testuale trova al primo colpo dove una frase e' scritta e dove viene usata, che e'
 * esattamente quello che serve quando bisogna correggere una virgola in due lingue.
 *
 * ☠ Questo file e' `en.php` devono avere **le stesse chiavi**. Lo verifica
 * `deploy/verifica_lingue.php`, che va lanciato dopo ogni modifica: una chiave che manca
 * in inglese non produce nessun errore, produce una frase italiana in mezzo a una pagina
 * inglese, e nessuno la segnala.
 *
 * ☠ I valori possono contenere HTML e vengono stampati senza ripulitura. Qui dentro non
 * deve finire MAI niente che provenga da un utente.
 */

declare(strict_types=1);

return [

    // ── Comuni ──────────────────────────────────────────────────────────────
    'comune.altra_lingua'      => 'English',
    'comune.scegli_lingua'     => 'Scegli la lingua',
    'comune.in_italiano'       => 'Leggi in italiano',
    'comune.in_inglese'        => 'Read in English',
    'comune.salta'             => 'Salta al contenuto',
    'comune.aggiornato'        => 'Ultimo aggiornamento: {data}',
    'comune.data_legale'       => '6 ottobre 2026',
    'comune.scopri'            => 'Scopri di più &rarr;',
    'comune.in_lavorazione'    => 'In lavorazione',
    'comune.in_arrivo'         => 'In arrivo',
    'comune.disponibile'       => 'Disponibile',
    'comune.presto_play'       => 'Presto su Google Play',
    'comune.scarica_play'      => 'Scarica su Google Play',
    'comune.scarica_app_store' => 'Scarica su App Store',
    'comune.presto_store'      => 'Presto su Google Play e App Store',

    // ── Navigazione ─────────────────────────────────────────────────────────
    'nav.app'         => 'Le app',
    'nav.contatti'    => 'Contatti',
    'nav.su_misura'   => 'Sviluppo su misura',
    'nav.principale'  => 'Principale',
    'nav.apri'        => 'Apri il menu',
    'nav.chiudi'      => 'Chiudi il menu',
    'nav.mostra_app'  => 'Mostra le app',

    // ── Pie' di pagina ──────────────────────────────────────────────────────
    'footer.blurb'       => 'App piccole per Android e iPhone, che fanno una cosa sola e la fanno '
                          . 'bene. Gratis nella versione base, sbloccabili con un acquisto '
                          . 'una tantum. Nessun abbonamento.',
    'footer.app'         => 'Le app',
    'footer.legale'      => 'Informazioni legali',
    'footer.contatti'    => 'Contatti',
    'footer.note'        => 'Note legali',
    'footer.privacy'     => 'Informativa privacy',
    'footer.cookie'      => 'Cookie policy',
    'footer.termini'     => 'Condizioni di servizio',
    'footer.responsabilita' => 'Limitazione di responsabilità',
    'footer.segnala'     => 'Segnala un problema',
    'footer.diritti'     => 'Tutti i diritti riservati. Android e Google Play sono marchi '
                          . 'di Google LLC. iPhone e App Store sono marchi di Apple Inc.',

    // ── Le app del catalogo ─────────────────────────────────────────────────
    'app.trashcan.prezzo'   => '2,99 €',
    'app.trashcan.claim'    => 'Stasera cosa si butta?',
    'app.trashcan.sommario' => 'Il calendario della raccolta differenziata del tuo Comune, '
                             . 'con il promemoria la sera prima. Niente più bidone '
                             . 'dimenticato sul pianerottolo.',

    'app.full-freezer.claim'    => 'Cosa c\'è nel congelatore, e da quanto.',
    'app.full-freezer.sommario' => 'L\'inventario del freezer ordinato per anzianità, così '
                                 . 'si consuma prima quello che aspetta da più tempo.',

    'app.scorte-calore.claim'    => 'Quanto pellet ti resta davvero.',
    'app.scorte-calore.sommario' => 'Consumo medio, autonomia residua e data in cui conviene '
                                  . 'riordinare. Per pellet, gasolio, GPL e legna.',

    'app.film-tracker.claim'    => 'Il diario dei tuoi rullini.',
    'app.film-tracker.sommario' => 'Pellicole, scatti, tempi e diaframmi. Per chi fotografa '
                                 . 'in analogico e non vuole perdere le note dello sviluppo.',

    // ── Home ────────────────────────────────────────────────────────────────
    'home.titolo'      => 'App piccole per Android e iPhone, che fanno una cosa sola',
    'home.descrizione' => 'SMP MicroApps: applicazioni Android e iPhone leggere, senza account e '
                        . 'senza abbonamenti. Versione base gratuita, Pro con un acquisto '
                        . 'una tantum.',

    'home.eyebrow'      => 'App per Android e iPhone',
    'home.hero.titolo'  => 'Una cosa sola.<br>Fatta bene.',
    'home.hero.lede'    => 'Micro applicazioni che rispondono a una domanda precisa e si '
                         . 'tolgono di mezzo. Nessun account, nessuna pubblicità, nessun '
                         . 'abbonamento: la versione base è gratis, il Pro si sblocca una '
                         . 'volta e resta tuo.',
    'home.hero.cta1'    => 'Guarda le app',
    'home.hero.cta2'    => 'Ti serve un\'app su misura?',

    'home.catalogo.titolo'    => 'Il catalogo',
    'home.catalogo.una'       => 'Una è già scaricabile, le altre sono in lavorazione.',
    'home.catalogo.molte'     => '{n} sono già scaricabili, le altre sono in lavorazione.',
    'home.catalogo.coda'      => 'Le trovi qui perché arrivano, non perché sono pronte.',

    'home.principi.titolo' => 'Come la pensiamo',
    'home.principi.lede'   => 'Tre scelte che valgono per tutte le app del catalogo, senza '
                            . 'eccezioni.',
    'home.principi.1.titolo' => 'Si paga una volta',
    'home.principi.1.testo'  => 'Niente abbonamenti. La versione Pro si sblocca con un '
                              . 'acquisto singolo e resta sbloccata, anche cambiando '
                              . 'telefono. Non c\'è niente che scade.',
    'home.principi.2.titolo' => 'I dati restano sul telefono',
    'home.principi.2.testo'  => 'Nessun account da creare, nessun profilo, nessuna raccolta '
                              . 'di statistiche d\'uso. Quello che scrivi nell\'app resta '
                              . 'nell\'app, e puoi esportarlo quando vuoi.',
    'home.principi.3.titolo' => 'Niente pubblicità',
    'home.principi.3.testo'  => 'Non c\'è spazio per un banner in un\'app che deve '
                              . 'rispondere a una domanda in due secondi. Nemmeno nella '
                              . 'versione gratuita.',

    'home.cta.titolo' => 'Hai in mente un\'app che non esiste?',
    'home.cta.testo'  => 'Sviluppo software su misura: gestionali, automazioni, '
                       . 'applicazioni mobili e strumenti interni. Raccontami il problema e '
                       . 'ti dico se e come si risolve.',
    'home.cta.bottone' => 'Parliamone',

    // ── Pagina TrashCan ─────────────────────────────────────────────────────
    'trashcan.titolo'      => 'TrashCan, il calendario della raccolta differenziata',
    'trashcan.descrizione' => 'TrashCan ti ricorda la sera prima cosa portare fuori. '
                            . 'Calendario della raccolta differenziata con promemoria e '
                            . 'widget, per Android e iPhone. Gratis, Pro a 2,99 € una tantum.',

    'trashcan.eyebrow'     => 'TrashCan · Android e iPhone',
    'trashcan.hero.titolo' => 'Stasera cosa<br>si butta?',
    'trashcan.hero.lede'   => 'Il calendario della raccolta differenziata del tuo Comune, '
                            . 'con il promemoria la sera prima e il widget sulla schermata '
                            . 'iniziale. Il bidone giusto, la sera giusta.',
    'trashcan.hero.cta'    => 'Cosa sa fare',

    'trashcan.problema.titolo' => 'Il problema è sempre lo stesso',
    'trashcan.problema.lede'   => 'Il calendario della raccolta è un foglio attaccato al '
                                . 'frigo, o un PDF del Comune che nessuno riapre. Te ne '
                                . 'ricordi la mattina dopo, quando il camion è già passato. '
                                . 'TrashCan te lo ricorda mentre sei ancora in casa.',
    'trashcan.problema.1.titolo' => 'Lo imposti una volta',
    'trashcan.problema.1.testo'  => 'Una procedura guidata in quattro passi: scegli i tipi '
                                  . 'di rifiuto, i giorni in cui passano e l\'ora del '
                                  . 'promemoria. Cinque minuti e non ci pensi più.',
    'trashcan.problema.2.titolo' => 'Regge i calendari veri',
    'trashcan.problema.2.testo'  => 'Settimanale, a settimane alterne, ogni due settimane '
                                  . 'con data di partenza, mensile per posizione, o date '
                                  . 'scelte a mano. Anche i giri strani del tuo Comune ci '
                                  . 'stanno.',
    'trashcan.problema.3.titolo' => 'Le eccezioni non ti fregano',
    'trashcan.problema.3.testo'  => 'Festività, salti e raccolte straordinarie: scegli la '
                                  . 'raccolta da cambiare, anche fra mesi, e il calendario si '
                                  . 'aggiusta da solo, senza toccare la regola.',

    'trashcan.funzioni.titolo' => 'Cosa trovi dentro',
    'trashcan.funzioni.lede'   => 'Tutto quello che serve per non sbagliare bidone, e '
                                . 'niente altro.',
    'trashcan.funzioni.1.titolo' => 'La schermata "Stasera"',
    'trashcan.funzioni.1.testo'  => 'Apri l\'app e la prima cosa che vedi è cosa portare '
                                  . 'fuori stasera, grande e a colori. Sotto, la prossima '
                                  . 'raccolta e i sette giorni successivi.',
    'trashcan.funzioni.2.titolo' => 'Il widget sulla home',
    'trashcan.funzioni.2.testo'  => 'Su Android e su iPhone: l\'intestazione colorata dice '
                                  . 'cosa si butta stasera, con la sua icona; sotto, i giorni '
                                  . 'successivi. Si aggiorna da solo ogni sera, ed è gratis.',
    'trashcan.funzioni.3.titolo' => 'Promemoria puntuale',
    'trashcan.funzioni.3.testo'  => 'Con il Pro, una notifica all\'ora che scegli, la sera '
                                  . 'prima della raccolta. Se al primo non sei in casa, ne '
                                  . 'aggiungi un secondo.',
    'trashcan.funzioni.4.titolo' => 'Tipi di rifiuto tuoi',
    'trashcan.funzioni.4.testo'  => 'Ogni Comune ha le sue categorie e i suoi nomi. Parti '
                                  . 'dai tipi già pronti e rinominali, cambia icona e '
                                  . 'colore, o creane di nuovi.',
    'trashcan.funzioni.5.titolo' => 'Condivisione e backup',
    'trashcan.funzioni.5.testo'  => 'Mandi il calendario a un vicino e lui ha gli stessi '
                                  . 'giorni senza riscriverli, gratis. Con il Pro salvi tutto '
                                  . 'in un file e lo porti su un telefono nuovo.',
    'trashcan.funzioni.6.titolo' => 'Italiano e inglese',
    'trashcan.funzioni.6.testo'  => 'L\'app segue la lingua del telefono. Le date e i giorni '
                                  . 'della settimana anche.',

    'trashcan.prezzi.titolo' => 'Gratis, e poi Pro se ti serve',
    'trashcan.prezzi.lede'   => 'Un acquisto solo, nessun abbonamento, nessun rinnovo. Se '
                              . 'cambi telefono lo ripristini dal tuo account Google o dal '
                              . 'tuo ID Apple. Su Android, se hai cambiato anche account, '
                              . 'c\'è un codice di trasferimento dentro l\'app.',
    'trashcan.prezzi.base'      => 'Base',
    'trashcan.prezzi.gratis'    => 'Gratis',
    'trashcan.prezzi.pro'       => 'Pro',
    'trashcan.prezzi.unatantum' => 'una tantum, IVA inclusa',
    'trashcan.prezzi.base.lista' => '<li>Un calendario della raccolta</li>'
        . '<li>Tipi di rifiuto e regole illimitati</li>'
        . '<li>Eccezioni, salti e raccolte straordinarie</li>'
        . '<li>Widget con la raccolta di stasera e i giorni successivi</li>'
        . '<li>Condivisione del calendario con un vicino</li>'
        . '<li>Nessuna pubblicità, nessun account</li>',
    'trashcan.prezzi.pro.lista' => '<li>Tutto quello che c\'è nella versione base</li>'
        . '<li><strong>I promemoria</strong>: la notifica la sera prima</li>'
        . '<li>Doppio promemoria, per chi al primo non si muove</li>'
        . '<li>Calendari multipli: casa, casa al mare, i genitori</li>'
        . '<li>Backup completo in un file, per il telefono nuovo</li>'
        . '<li>Il colore dell\'app scelto da te, fra dieci</li>',

    'trashcan.privacy.titolo' => 'I tuoi dati restano tuoi',
    'trashcan.privacy.testo'  => 'TrashCan non ha account, non chiede registrazione e non '
                               . 'raccoglie statistiche d\'uso. Il calendario, i tipi di '
                               . 'rifiuto e i promemoria vivono nella memoria del telefono '
                               . 'e non vengono inviati da nessuna parte. L\'unica cosa che '
                               . 'esce dal dispositivo è la verifica dell\'acquisto, perché '
                               . 'la fa Google o Apple.',
    'trashcan.privacy.link'   => 'Leggi l\'informativa privacy completa &rarr;',

    'trashcan.bug.titolo'  => 'Qualcosa non va, o manca qualcosa?',
    'trashcan.bug.testo'   => 'Le segnalazioni le legge una persona sola, che è la stessa '
                            . 'che scrive il codice. Scrivi cosa è successo e su che '
                            . 'telefono: è il modo più veloce perché venga sistemato.',
    'trashcan.bug.bottone' => 'Segnala un problema',

    // ── Contatti ────────────────────────────────────────────────────────────
    'contatti.titolo'      => 'Contatti e sviluppo su misura',
    'contatti.descrizione' => 'Scrivi per una segnalazione, una domanda sulle app o per far '
                            . 'sviluppare un\'applicazione su misura.',
    'contatti.eyebrow'     => 'Parliamo',
    'contatti.h1'          => 'Scrivimi',
    'contatti.lede'        => 'Segnalazioni, domande sulle app e richieste di sviluppo su '
                            . 'misura arrivano tutte allo stesso posto, e le legge una '
                            . 'persona sola.',

    'contatti.misura.titolo' => 'Sviluppo su misura',
    'contatti.misura.testo'  => 'Applicazioni Android e iPhone, gestionali, automazioni e strumenti '
                              . 'interni. Descrivi il problema e il contesto in cui nasce: '
                              . 'la prima risposta dice se è fattibile, con che tempi e con '
                              . 'quale ordine di grandezza di costo.',
    'contatti.bug.titolo'    => 'Segnalare un problema',
    'contatti.bug.testo'     => 'Indica il modello di telefono, la versione di Android o iOS e '
                              . 'cosa stavi facendo quando è successo. Con queste tre '
                              . 'informazioni un problema si riproduce in pochi minuti; '
                              . 'senza, spesso non si riproduce affatto.',
    'contatti.recapiti.titolo' => 'Recapiti diretti',
    'contatti.recapiti.pec'    => '(PEC)',

    // ── Il modulo ───────────────────────────────────────────────────────────
    'form.titolo'      => 'Il modulo',
    'form.nome'        => 'Nome',
    'form.email'       => 'Email',
    'form.email.aiuto' => 'Serve solo per risponderti.',
    'form.argomento'   => 'Argomento',
    'form.scegli'      => 'Scegli…',
    'form.app'         => 'App interessata',
    'form.app.ph'      => 'TrashCan, oppure lascia vuoto',
    'form.app.aiuto'   => 'Per una segnalazione, aggiungi modello del telefono e versione '
                        . 'di Android o iOS nel messaggio.',
    'form.messaggio'   => 'Messaggio',
    'form.consenso'    => 'Ho letto l\'<a href="{privacy}">informativa privacy</a> e '
                        . 'acconsento al trattamento dei miei dati per ricevere una '
                        . 'risposta a questo messaggio.',
    'form.invia'       => 'Invia il messaggio',
    'form.obbligatori' => 'I campi contrassegnati con * sono obbligatori. Titolare del '
                        . 'trattamento: {denominazione}.',
    'form.trappola'    => 'Non compilare questo campo',

    'form.ok.titolo'   => 'Messaggio ricevuto.',
    'form.ok.testo'    => 'Ti rispondo all\'indirizzo che hai indicato, di solito entro due '
                        . 'giorni lavorativi.',
    'form.ok.salvato'  => 'Il messaggio è stato registrato correttamente.',
    'form.ko.titolo'   => 'Il messaggio non è stato inviato.',

    'form.arg.bug'            => 'Segnalazione di un problema',
    'form.arg.personalizzato' => 'Richiesta di sviluppo personalizzato',
    'form.arg.app'            => 'Domanda su una delle app',
    'form.arg.privacy'        => 'Privacy e dati personali',
    'form.arg.altro'          => 'Altro',

    'form.err.sessione'  => 'La pagina è rimasta aperta troppo a lungo. Ricaricala e '
                          . 'reinvia il messaggio.',
    'form.err.nome'      => 'Indica un nome fra 2 e 80 caratteri.',
    'form.err.email'     => 'Indica un indirizzo email valido: serve per poterti rispondere.',
    'form.err.argomento' => 'Scegli un argomento fra quelli proposti.',
    'form.err.corto'     => 'Scrivi qualche riga in più: sotto i 20 caratteri non si '
                          . 'capisce cosa serve.',
    'form.err.lungo'     => 'Il messaggio supera i 5.000 caratteri. Riassumilo, o allega il '
                          . 'resto via email.',
    'form.err.consenso'  => 'Per poterti rispondere devi confermare di aver letto '
                          . 'l\'informativa privacy.',
    'form.err.limite'    => 'Hai inviato diversi messaggi nell\'ultima ora. Riprova più '
                          . 'tardi, oppure scrivi direttamente a {email}.',
    'form.err.archivio'  => 'Non è stato possibile registrare il messaggio. Scrivi '
                          . 'direttamente a {email}, così non si perde nulla.',

    // ── Pagine legali: intestazioni ─────────────────────────────────────────
    'legale.occhiello' => 'Informazioni legali',

    'legale.note-legali.titolo'      => 'Note legali',
    'legale.note-legali.descrizione' => 'Dati identificativi del titolare del sito smpmicroapps.it '
                               . 'e delle app SMP MicroApps.',
    'legale.note-legali.sommario'    => 'Chi gestisce questo sito e le applicazioni che vi sono '
                               . 'presentate.',

    'legale.privacy.titolo'      => 'Informativa privacy',
    'legale.privacy.descrizione' => 'Come vengono trattati i dati personali su '
                                  . 'smpmicroapps.it e nelle app SMP MicroApps.',
    'legale.privacy.sommario'    => 'Quali dati raccogliamo, perché, per quanto tempo e '
                                  . 'quali diritti hai. Resa ai sensi degli articoli 13 e '
                                  . '14 del Regolamento (UE) 2016/679.',

    'legale.cookie.titolo'      => 'Cookie policy',
    'legale.cookie.descrizione' => 'Quali cookie usa smpmicroapps.it: solo cookie tecnici, '
                                 . 'nessun cookie di profilazione e nessuna risorsa di '
                                 . 'terze parti.',
    'legale.cookie.sommario'    => 'Questo sito non usa cookie di profilazione e non carica '
                                 . 'nulla da server di terze parti.',

    'legale.termini.titolo'      => 'Condizioni di servizio',
    'legale.termini.descrizione' => 'Condizioni d\'uso del sito smpmicroapps.it e licenza '
                                  . 'd\'uso delle applicazioni SMP MicroApps.',
    'legale.termini.sommario'    => 'Le regole d\'uso del sito e la licenza con cui ti '
                                  . 'vengono concesse le applicazioni.',

    'legale.responsabilita.titolo'      => 'Limitazione di responsabilità',
    'legale.responsabilita.descrizione' => 'Limiti di responsabilità relativi all\'uso del '
                                         . 'sito e delle applicazioni SMP MicroApps.',
    'legale.responsabilita.sommario'    => 'Che cosa possiamo garantire, che cosa no, e '
                                         . 'perché.',
];

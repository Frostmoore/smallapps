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
    'comune.data_legale'       => '10 ottobre 2026',
    'comune.scopri'            => 'Scopri di più &rarr;',
    'comune.in_lavorazione'    => 'In lavorazione',
    'comune.su_app_store'   => 'Disponibile su App Store',
    'comune.su_google_play' => 'Disponibile su Google Play',
    'comune.in_arrivo'         => 'In arrivo',
    'comune.disponibile'       => 'Disponibile',
    'comune.presto_play'       => 'Presto su Google Play',
    'comune.scarica_play'      => 'Scarica su Google Play',
    'comune.scarica_app_store' => 'Scarica su App Store',
    'comune.presto_store'      => 'Presto su Google Play e App Store',
    'comune.disponibile_ios_android' => 'Disponibile su iOS e Android',
    'comune.disponibile_ios'     => 'Disponibile su iOS',
    'comune.disponibile_android' => 'Disponibile su Android',
    'comune.android_in_arrivo'   => 'Su Android in arrivo.',
    'comune.ios_in_arrivo'       => 'Su iPhone in arrivo.',
    'comune.cosa_sa_fare'        => 'Cosa sa fare',
    'comune.schermate.titolo'    => 'Com\'è fatta',
    'comune.schermate.lede'      => 'Schermate vere dell\'app, non disegni: quello che vedi qui è quello che trovi sul telefono.',
    'comune.promo.titolo'        => 'In due parole',
    'comune.promo.lede'          => 'Le cose che contano, una per immagine.',
    'comune.piano.base'          => 'Base',
    'comune.piano.gratis'        => 'Gratis',
    'comune.piano.pro'           => 'Pro',
    'comune.piano.unatantum'     => 'una tantum, IVA inclusa',
    'comune.privacy.link'        => 'Leggi l\'informativa privacy completa &rarr;',
    'comune.bug.titolo'          => 'Qualcosa non va, o manca qualcosa?',
    'comune.bug.testo'           => 'Le segnalazioni le legge una persona sola, che è la stessa che scrive il codice. Scrivi cosa è successo e su che telefono: è il modo più veloce perché venga sistemato.',
    'comune.bug.bottone'         => 'Segnala un problema',

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

    'app.scorte-calore.prezzo'     => '2,99 €',
    'app.scorte-calore.claim'    => 'Quanto pellet ti resta davvero.',
    'app.scorte-calore.sommario' => 'Consumo medio, autonomia residua e data in cui conviene '
                                  . 'riordinare. Per pellet, gasolio, GPL e legna.',

    'app.film-tracker.claim'    => 'Il diario dei tuoi rullini.',
    'app.film-tracker.sommario' => 'Ogni rullino dalla macchina al provino: pellicola, sviluppo, '
                                 . 'stampe, costi e foto. E un\'etichetta QR per il barattolo.',
    'app.film-tracker.prezzo'      => '4,99 €',

    'app.qr-me.claim'    => 'Condividi, ed è già un QR.',
    'app.qr-me.sommario' => 'Un link, un testo o il Wi-Fi di casa diventano un QR grande e '
                          . 'luminoso, da far inquadrare. E i QR li legge anche.',

    'app.spending-review.claim'    => 'Quanto stai spendendo, mentre fai la spesa.',
    'app.spending-review.sommario' => 'Inquadri il cartellino e il prezzo si aggiunge al totale, '
                                    . 'col budget sempre davanti. Alla cassa controlla lo scontrino.',

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

    'trashcan.img.testata'     => 'TrashCan: stasera cosa si butta? Il widget te lo dice ogni sera.',
    'trashcan.schermate.titolo' => 'Com\'è fatta',
    'trashcan.schermate.lede'   => 'Schermate vere dell\'app, non disegni: quello che vedi qui è '
                                 . 'quello che trovi sul telefono.',
    'trashcan.schermate.1'      => 'Stasera e i prossimi sette giorni',
    'trashcan.schermate.2'      => 'Il widget sulla home',
    'trashcan.schermate.3'      => 'I giorni di raccolta',
    'trashcan.schermate.4'      => 'La regola di un tipo di rifiuto',
    'trashcan.schermate.5'      => 'I tipi di rifiuto, con colori e icone',
    'trashcan.schermate.6'      => 'Il Pro, un acquisto solo',
    'trashcan.promo.titolo'     => 'In due parole',
    'trashcan.promo.lede'       => 'Le cose che contano, una per immagine.',
    'trashcan.promo.02-widget'         => 'Widget sempre visibile: sai cosa esporre senza aprire l\'app.',
    'trashcan.promo.03-promemoria'     => 'Non dimenticare il bidone: un promemoria la sera prima.',
    'trashcan.promo.04-calendari'      => 'Anche calendari complicati: settimanali, alternati, mensili o personalizzati.',
    'trashcan.promo.05-festivi'        => 'Festivi? Nessun problema: eccezioni e variazioni in un attimo.',
    'trashcan.promo.06-personalizza'   => 'Personalizza tutto: categorie, colori e icone.',
    'trashcan.promo.07-nessun-account' => 'Nessun account: funziona offline e senza pubblicità.',
    'trashcan.promo.08-condividi'      => 'Condividi il calendario con chi vive con te o con i vicini.',
    'trashcan.promo.09-piu-calendari'  => 'Più calendari in una sola app: casa, vacanze, genitori.',
    'trashcan.promo.10-mai-piu'        => 'Mai più raccolta dimenticata.',

    // ── Pagina Scorte Calore ─────────────────────────────────────────────────
    'scorte-calore.promo.02-riordina' => 'Riordina prima di restare al freddo: la data giusta, con l\'anticipo che scegli tu.',
    'scorte-calore.promo.03-widget' => 'Il widget che conta i giorni, sulla schermata iniziale.',
    'scorte-calore.promo.04-gpl' => 'Anche il bombolone del GPL: leggi il manometro e l\'app lo trasforma in litri.',
    'scorte-calore.promo.05-misure' => 'Sacchi, chili, litri: misuri come vuoi, quando capita.',
    'scorte-calore.promo.06-consumo' => 'Impara il tuo consumo e riconosce da sola i rifornimenti.',
    'scorte-calore.promo.07-nessun-account' => 'Nessun account, zero pubblicità: i tuoi dati restano sul telefono.',
    'scorte-calore.promo.08-costi' => 'Quanto spendi ogni inverno: acquisti, costi e prezzo medio (Pro).',
    'scorte-calore.promo.09-fonti' => 'La stufa e il bombolone insieme: tutte le fonti di calore (Pro).',
    'scorte-calore.promo.10-mai-piu' => 'Mai più al freddo: la scorta sempre sotto controllo.',
    'scorte-calore.titolo'             => 'Scorte Calore, quanti giorni di riscaldamento ti restano',
    'scorte-calore.descrizione'        => 'Scorte Calore calcola quanti giorni di pellet, GPL, gasolio o legna ti restano ed entro quando riordinare. Gratis, Pro a 2,99 € una tantum.',
    'scorte-calore.hero.titolo'        => 'Quanti giorni<br>ti restano?',
    'scorte-calore.hero.lede'          => 'Pellet, GPL, gasolio o legna: aggiorni la scorta ogni tanto, con il numero che hai sotto gli occhi, e Scorte Calore ti dice quanti giorni di riscaldamento ti restano ed entro quando riordinare.',
    'scorte-calore.img.testata'        => 'Scorte Calore: pellet, GPL, gasolio, legna. Quanti giorni ti restano, e il giorno giusto per riordinare.',
    'scorte-calore.schermate.1'        => 'I giorni di autonomia e la data di riordino',
    'scorte-calore.schermate.2'        => 'Aggiorni la scorta, anche dal manometro del GPL',
    'scorte-calore.schermate.3'        => 'Lo storico e il consumo fra una misura e l\'altra',
    'scorte-calore.schermate.4'        => 'Acquisti e spesa dell\'inverno',
    'scorte-calore.schermate.5'        => 'Il Pro, un acquisto solo',
    'scorte-calore.problema.titolo'    => 'Te ne accorgi quando è tardi',
    'scorte-calore.problema.lede'      => 'La scorta si guarda a occhio: «ce n\'è ancora per un po\'». Poi la stufa si ferma un sabato sera di gennaio e il fornitore consegna la settimana dopo. Scorte Calore fa il conto al posto tuo, prima che serva.',
    'scorte-calore.problema.1.titolo'  => 'Misuri come misuri già',
    'scorte-calore.problema.1.testo'   => 'I sacchi di pellet rimasti, i litri della cisterna, la percentuale sul manometro del bombolone, gli steri o i quintali di legna: scrivi il numero che hai davanti, nell\'unità che usi.',
    'scorte-calore.problema.2.titolo'  => 'Il consumo lo impara da sé',
    'scorte-calore.problema.2.testo'   => 'Dalle misure ricava il consumo medio al giorno e riconosce da sola i rifornimenti. Anche se passano settimane fra una misura e l\'altra, la stima regge.',
    'scorte-calore.problema.3.titolo'  => 'Ti dice entro quando ordinare',
    'scorte-calore.problema.3.testo'   => 'Il giorno in cui la scorta finisce e quello entro cui riordinare, con i giorni di anticipo che scegli tu: quelli che servono al tuo fornitore.',
    'scorte-calore.funzioni.titolo'    => 'Cosa trovi dentro',
    'scorte-calore.funzioni.lede'      => 'Tutto quello che serve per non restare al freddo, e niente altro.',
    'scorte-calore.funzioni.1.titolo'  => 'I giorni, in grande',
    'scorte-calore.funzioni.1.testo'   => 'Apri l\'app e vedi i giorni di autonomia, il consumo medio al giorno, la data di riordino e quanto resta rispetto all\'ultimo carico.',
    'scorte-calore.funzioni.2.titolo'  => 'Il bombolone del GPL',
    'scorte-calore.funzioni.2.testo'   => 'Leggi la percentuale sul manometro e l\'app la trasforma in litri utili, tenendo conto che il serbatoio non si riempie mai oltre l\'80 per cento.',
    'scorte-calore.funzioni.3.titolo'  => 'Il widget sulla home',
    'scorte-calore.funzioni.3.testo'   => 'I giorni di autonomia e la data di riordino sulla schermata iniziale, senza aprire l\'app. Il conto scende da solo ogni giorno, ed è gratis.',
    'scorte-calore.funzioni.4.titolo'  => 'La notifica al momento giusto',
    'scorte-calore.funzioni.4.testo'   => 'Con il Pro, una notifica il giorno in cui riordinare, e un\'altra se la data passa e non hai ancora aggiornato la scorta.',
    'scorte-calore.funzioni.5.titolo'  => 'Un inverno contro l\'altro',
    'scorte-calore.funzioni.5.testo'   => 'Con il Pro, lo storico completo con i grafici del consumo, e gli acquisti: quanto spendi ogni inverno e il prezzo medio per unità.',
    'scorte-calore.funzioni.6.titolo'  => 'Nel calendario del telefono',
    'scorte-calore.funzioni.6.testo'   => 'Con il Pro, la data di riordino diventa un evento nel calendario che scegli tu. Se la stima cambia te lo fa notare, e lo sposti con un tocco.',
    'scorte-calore.prezzi.titolo'      => 'Gratis, e poi Pro se ti serve',
    'scorte-calore.prezzi.lede'        => 'La versione gratuita risponde già alla domanda: quanti giorni ti restano. Il Pro è un acquisto solo, nessun abbonamento, nessun rinnovo; se cambi telefono lo ripristini dallo store, con lo stesso account.',
    'scorte-calore.prezzi.base.lista'  => '<li>Una fonte di calore</li><li>Misure illimitate, stima completa del consumo e dell\'autonomia</li><li>La data di riordino, con l\'anticipo che scegli tu</li><li>Gli ultimi 90 giorni di misure nello storico</li><li>Il widget sulla schermata iniziale</li><li>Il ripristino da un backup</li><li>Nessuna pubblicità, nessun account</li>',
    'scorte-calore.prezzi.pro.lista'   => '<li>Tutto quello che c\'è nella versione base</li><li><strong>Le notifiche</strong>: il giorno in cui riordinare, e se la data passa</li><li>Tutte le fonti: la stufa e il bombolone, la casa e la seconda casa</li><li>Lo storico completo e i grafici del consumo</li><li>Acquisti e costi: la spesa di ogni inverno e il prezzo medio</li><li>La data di riordino nel calendario del telefono</li><li>Esportazione in un foglio di calcolo e backup completo</li>',
    'scorte-calore.privacy.titolo'     => 'I tuoi dati restano tuoi',
    'scorte-calore.privacy.testo'      => 'Scorte Calore non ha account, non chiede registrazione e non raccoglie statistiche d\'uso. Fonti, misure e acquisti vivono nella memoria del telefono e non vengono inviati da nessuna parte. Se aggiungi la data di riordino al calendario, l\'evento finisce nel calendario del telefono che scegli tu, e da lì segue quel calendario. L\'unica cosa che esce dal dispositivo è la verifica dell\'acquisto, perché la fa lo store.',

    // ── Pagina Film Tracker ──────────────────────────────────────────────────
    'film-tracker.promo.02-in-macchina' => 'Cosa c\'è in macchina? In macchina, in laboratorio, in archivio.',
    'film-tracker.promo.03-provini' => 'Il foglio provini di ogni rullino, con lo zoom.',
    'film-tracker.promo.04-qr' => 'Un QR sul barattolo: inquadri e si apre il rullino giusto.',
    'film-tracker.promo.05-pellicole' => 'Tutte le pellicole, più le tue: dal catalogo o aggiunte da te.',
    'film-tracker.promo.06-tirato' => 'Tirato o trattenuto: l\'ISO a cui hai esposto, accanto a quello nominale.',
    'film-tracker.promo.07-nessun-account' => 'Nessun account, zero pubblicità: i tuoi rullini restano sul telefono.',
    'film-tracker.promo.08-costi' => 'Quanto ti costa ogni rullino: pellicola, sviluppo, scansioni e stampe (Pro).',
    'film-tracker.promo.09-pdf' => 'Il tuo anno in un PDF da stampare, con le foto (Pro).',
    'film-tracker.promo.10-stampa' => 'Dallo scatto alla stampa: sviluppo in laboratorio o in casa.',
    'film-tracker.titolo'              => 'Film Tracker, il diario dei tuoi rullini analogici',
    'film-tracker.descrizione'         => 'Film Tracker segue ogni rullino dalla macchina al provino: pellicola, sviluppo, stampe, costi e foto, con un\'etichetta QR per il barattolo. Gratis, Pro a 4,99 € una tantum.',
    'film-tracker.hero.titolo'         => 'Cosa c\'è<br>in macchina?',
    'film-tracker.hero.lede'           => 'Il diario dei tuoi rullini analogici: sai sempre cosa c\'è in macchina, cosa aspetta in laboratorio e cosa è già nell\'archivio, con le foto di ogni rullino.',
    'film-tracker.img.testata'         => 'Film Tracker: il diario dei tuoi rullini analogici, dalla macchina al provino.',
    'film-tracker.schermate.1'         => 'In macchina, in laboratorio, in archivio',
    'film-tracker.schermate.2'         => 'La storia di un rullino, con date e costi',
    'film-tracker.schermate.3'         => 'L\'archivio come un foglio provini',
    'film-tracker.schermate.4'         => 'L\'etichetta QR per il barattolo',
    'film-tracker.schermate.5'         => 'Le statistiche dell\'anno',
    'film-tracker.schermate.6'         => 'Il Pro, un acquisto solo',
    'film-tracker.problema.titolo'     => 'Quale rullino era quello?',
    'film-tracker.problema.lede'       => 'Tre rullini finiti nello stesso cassetto, uno in laboratorio da settimane, e nessuno ricorda a che ISO si sta esponendo quello in macchina. Film Tracker tiene il diario al posto tuo, dal carico al provino.',
    'film-tracker.problema.1.titolo'   => 'Lo carichi, lui lo segue',
    'film-tracker.problema.1.testo'    => 'Scegli la pellicola dal catalogo (Kodak, Ilford, Fujifilm, Fomapan, Cinestill e altre, più le tue), la macchina e l\'ISO. Da lì il rullino passa da terminato a consegnato, sviluppato, stampato.',
    'film-tracker.problema.2.titolo'   => 'Sai sempre dov\'è',
    'film-tracker.problema.2.testo'    => 'Tre sezioni: in macchina, con i giorni da quando l\'hai caricato; in laboratorio, con chi aspetta da più tempo in cima; e l\'archivio, con le foto.',
    'film-tracker.problema.3.titolo'   => 'Niente più rullini scambiati',
    'film-tracker.problema.3.testo'    => 'Ogni rullino ha un\'etichetta QR da stampare o fotografare e attaccare al barattolo. La inquadri con la fotocamera e l\'app si apre su quel rullino.',
    'film-tracker.funzioni.titolo'     => 'Cosa trovi dentro',
    'film-tracker.funzioni.lede'       => 'Tutto quello che serve per non perdere il filo dei tuoi rullini, e niente altro.',
    'film-tracker.funzioni.1.titolo'   => 'La cronologia del rullino',
    'film-tracker.funzioni.1.testo'    => 'Date e costi di ogni passaggio: pellicola, sviluppo, scansioni, stampe. E la spesa totale del rullino, sempre sotto gli occhi.',
    'film-tracker.funzioni.2.titolo'   => 'Sviluppo e stampe',
    'film-tracker.funzioni.2.testo'    => 'In laboratorio o in casa, e tutti gli ordini di stampa che vuoi, ciascuno con la sua data e il suo costo.',
    'film-tracker.funzioni.3.titolo'   => 'Le foto, gratis',
    'film-tracker.funzioni.3.testo'    => 'Le foto dei provini, delle stampe o delle scansioni, con lo zoom. L\'archivio diventa un foglio provini con le immagini di ogni rullino.',
    'film-tracker.funzioni.4.titolo'   => 'Tirato o trattenuto',
    'film-tracker.funzioni.4.testo'    => 'L\'ISO a cui hai esposto accanto a quello nominale: quando porti il rullino a sviluppare, il dato è lì.',
    'film-tracker.funzioni.5.titolo'   => 'Il tuo anno in numeri',
    'film-tracker.funzioni.5.testo'    => 'Con il Pro, le statistiche dell\'anno: rullini, spesa per pellicola, sviluppo e stampe, costo medio per rullino. E il riepilogo in PDF, da stampare, con le foto.',
    'film-tracker.funzioni.6.titolo'   => 'Scura, per le foto',
    'film-tracker.funzioni.6.testo'    => 'Su fondo scuro le foto non perdono contrasto. Se preferisci la luce, c\'è il tema chiaro «tavolo luminoso».',
    'film-tracker.prezzi.titolo'       => 'Gratis, e poi Pro se ti serve',
    'film-tracker.prezzi.lede'         => 'Nella versione gratuita rullini e foto sono illimitati. Il Pro è un acquisto solo, nessun abbonamento, nessun rinnovo; se cambi telefono lo ripristini dallo store, con lo stesso account.',
    'film-tracker.prezzi.base.lista'   => '<li>Rullini illimitati</li><li>Una macchina fotografica</li><li>Il catalogo delle pellicole, più le tue</li><li>Sviluppo, stampe e costi di ogni rullino</li><li>Tutte le foto, con lo zoom</li><li>L\'etichetta QR di ogni rullino</li><li>Il ripristino da un backup</li><li>Nessuna pubblicità, nessun account</li>',
    'film-tracker.prezzi.pro.lista'    => '<li>Tutto quello che c\'è nella versione base</li><li><strong>Tutte le tue macchine</strong>, ciascuna con i suoi rullini</li><li>Le statistiche dell\'anno: rullini e spesa</li><li>Il riepilogo dell\'anno in PDF, con le foto</li><li>Esportazione in un foglio di calcolo</li><li>Backup completo, foto comprese</li>',
    'film-tracker.privacy.titolo'      => 'I tuoi dati restano tuoi',
    'film-tracker.privacy.testo'       => 'Film Tracker non ha account, non chiede registrazione e non raccoglie statistiche d\'uso. Rullini, costi e foto vivono nella memoria del telefono e non vengono inviati da nessuna parte. La fotocamera e la libreria foto si aprono solo quando aggiungi una foto a un rullino. L\'unica cosa che esce dal dispositivo è la verifica dell\'acquisto, perché la fa lo store.',

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

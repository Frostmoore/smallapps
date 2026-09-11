<?php

/**
 * Condizioni di servizio: uso del sito e licenza d'uso delle applicazioni.
 *
 * ☠ Il punto delicato e' il rapporto con Google Play. Il contratto di acquisto NON si
 * conclude qui: si conclude fra l'utente e Google. Scrivere condizioni che si arrogano la
 * gestione dei pagamenti o dei rimborsi sarebbe falso e, verso un consumatore, anche
 * vessatorio. Qui si regola cio' che davvero dipende da noi: la licenza d'uso del software
 * e l'assistenza.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../src/layout.php';

pagina_inizio(
    'Condizioni di servizio',
    'Condizioni d\'uso del sito smpmicroapps.it e licenza d\'uso delle applicazioni '
        . 'SMP MicroApps.',
    '/legale/termini'
);

intestazione_legale(
    'Condizioni di servizio',
    '11 settembre 2026',
    'Le regole d\'uso del sito e la licenza con cui ti vengono concesse le applicazioni.'
);
?>

<div class="wrap prose">

  <h2>1. Chi siamo e a cosa si applicano queste condizioni</h2>

  <p>
    Le presenti condizioni regolano l'uso del sito <?= e(SITO_URL) ?> e delle applicazioni
    per Android distribuite con il marchio SMP MicroApps da
    <strong><?= e(AZIENDA['denominazione']) ?></strong>, <?= e(AZIENDA['indirizzo']) ?>,
    <?= e(AZIENDA['cap']) ?> <?= e(AZIENDA['citta']) ?> (<?= e(AZIENDA['provincia']) ?>),
    P. IVA e C.F. <?= e(AZIENDA['piva']) ?> (di seguito «il fornitore»).
  </p>

  <p>
    Usando il sito o le applicazioni accetti queste condizioni. Se non le accetti, non usare
    il servizio e disinstalla l'applicazione.
  </p>

  <h2>2. Il sito non vende nulla</h2>

  <p>
    Questo sito ha funzione esclusivamente informativa. Le applicazioni si scaricano e si
    acquistano su <strong>Google Play</strong>, e il contratto di acquisto si conclude fra te
    e <strong>Google Ireland Limited</strong>, che agisce come rivenditore. Il fornitore non
    incassa direttamente il prezzo, non emette la ricevuta d'acquisto e non ha accesso ai
    tuoi dati di pagamento.
  </p>

  <div class="box">
    <p>
      Di conseguenza <strong>rimborsi, storni e diritto di recesso sull'acquisto si
      richiedono a Google Play</strong>, secondo le procedure e i termini indicati da Google.
      Se hai un problema che Google non risolve, scrivici lo stesso: possiamo intervenire sul
      piano tecnico e, dove ci è consentito, sollecitare la pratica.
    </p>
  </div>

  <h2>3. Licenza d'uso del software</h2>

  <p>
    Le applicazioni non ti vengono vendute: ti viene concessa una licenza d'uso
    <strong>personale, non esclusiva, non trasferibile e non sublicenziabile</strong>, valida
    per un tempo indeterminato, per installarle e usarle sui dispositivi che ti appartengono
    o che sono sotto il tuo controllo.
  </p>

  <p>L'acquisto della versione Pro sblocca funzioni aggiuntive dell'applicazione. È:</p>

  <ul>
    <li><strong>un acquisto singolo</strong>, non un abbonamento: non si rinnova e non scade;</li>
    <li><strong>legato al tuo account Google Play</strong>, non al singolo telefono: cambiando
      dispositivo puoi ripristinarlo dal medesimo account;</li>
    <li><strong>riferito alla singola applicazione</strong>: l'acquisto di un'app non sblocca
      le altre del catalogo.</li>
  </ul>

  <p>Non è consentito:</p>

  <ul>
    <li>decompilare, disassemblare o tentare di ricavare il codice sorgente, salvo nei limiti
      inderogabili dell'art. 64-quater della legge 633/1941;</li>
    <li>modificare l'applicazione, o distribuirne versioni derivate o modificate;</li>
    <li>rivendere, noleggiare, prestare o cedere la licenza a terzi;</li>
    <li>aggirare le limitazioni della versione gratuita o i controlli sulla licenza, né
      diffondere strumenti o istruzioni che consentano ad altri di farlo;</li>
    <li>usare le applicazioni per scopi illeciti o in violazione di diritti altrui.</li>
  </ul>

  <h2>4. Il codice di trasferimento</h2>

  <p>
    Per i casi in cui non sia possibile il ripristino tramite Google Play — tipicamente il
    cambio di account Google — le applicazioni offrono un codice temporaneo per spostare la
    licenza su un altro dispositivo. È uno strumento di assistenza, soggetto a limiti di
    validità, di numero e di frequenza. L'uso del codice per condividere la licenza con terzi
    costituisce violazione del punto 3 e consente al fornitore di revocare la licenza.
  </p>

  <h2>5. Aggiornamenti e continuità del servizio</h2>

  <p>
    Il fornitore può aggiornare le applicazioni per correggere difetti, adeguarsi a nuove
    versioni di Android o migliorarne il funzionamento. Può altresì modificare, sospendere o
    cessare la distribuzione di un'applicazione, dandone preavviso quando ragionevolmente
    possibile.
  </p>

  <p>
    Le applicazioni funzionano <strong>senza connessione a internet</strong> per tutte le loro
    funzioni principali: l'eventuale cessazione dei servizi online del fornitore non impedisce
    di continuare a usare l'app già installata e già sbloccata. La verifica della licenza
    serve ad attivare la versione Pro, non a farla funzionare ogni giorno.
  </p>

  <h2>6. Garanzia legale di conformità</h2>

  <p>
    Nei confronti dei consumatori resta ferma la garanzia legale di conformità del contenuto
    digitale prevista dagli articoli 135-octies e seguenti del Codice del consumo (d.lgs.
    206/2005). Se l'applicazione non è conforme a quanto descritto, hai diritto al ripristino
    della conformità e, nei casi previsti, alla riduzione del prezzo o alla risoluzione del
    contratto, secondo le procedure di Google Play. Nessuna clausola di queste condizioni
    limita tali diritti.
  </p>

  <h2>7. Responsabilità</h2>

  <p>
    Il fornitore risponde secondo la legge dei danni cagionati da dolo o colpa grave e in
    tutti i casi in cui la legge non ammette limitazioni. Per il resto vale quanto indicato
    nella <a href="/legale/responsabilita">limitazione di responsabilità</a>, che costituisce
    parte integrante di queste condizioni.
  </p>

  <h2>8. Dati personali</h2>

  <p>
    Il trattamento dei dati personali è descritto nell'<a href="/legale/privacy">informativa
    privacy</a>. Le applicazioni conservano i dati che inserisci nella memoria del tuo
    dispositivo: <strong>il backup è una tua responsabilità</strong>, e le app mettono a
    disposizione una funzione di esportazione proprio per questo.
  </p>

  <h2>9. Assistenza</h2>

  <p>
    L'assistenza si richiede dal <a href="/contatti">modulo di contatto</a> o scrivendo a
    <a href="mailto:<?= e(AZIENDA['email']) ?>"><?= e(AZIENDA['email']) ?></a>. Non sono
    previsti tempi di risposta contrattualmente garantiti; l'obiettivo dichiarato è rispondere
    entro due giorni lavorativi.
  </p>

  <h2>10. Modifiche alle condizioni</h2>

  <p>
    Queste condizioni possono essere modificate. La versione vigente è quella pubblicata a
    questo indirizzo, con la data di ultimo aggiornamento in testa alla pagina. Le modifiche
    non si applicano retroattivamente agli acquisti già effettuati, quando ne alterino in
    senso sfavorevole il contenuto essenziale.
  </p>

  <h2>11. Legge applicabile, foro e risoluzione delle controversie</h2>

  <p>
    Si applica la legge italiana. Per i consumatori è competente il foro del luogo di
    residenza o domicilio; negli altri casi è competente in via esclusiva il Foro di Viterbo.
  </p>

  <p>
    Il consumatore può inoltre ricorrere alla piattaforma europea di risoluzione delle
    controversie online, disponibile all'indirizzo
    <a href="https://ec.europa.eu/consumers/odr" rel="noopener">ec.europa.eu/consumers/odr</a>,
    o agli organismi di mediazione competenti.
  </p>

</div>

<?php pagina_fine(); ?>

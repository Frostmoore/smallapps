<?php

/**
 * Informativa privacy, artt. 13 e 14 del Regolamento (UE) 2016/679.
 *
 * ☠ Questa pagina deve descrivere quello che il software fa **davvero**. Le affermazioni
 * qui dentro sono verificabili nel codice: i dati delle app restano nel database locale
 * (apps/trashcan/lib/data/), l'unico dato che lascia il dispositivo e' quello della
 * verifica dell'acquisto (packages/micro_core/lib/src/entitlement/), e il server delle
 * licenze conserva le colonne elencate in server/src/db/schema.sql. Se il codice cambia,
 * questa pagina cambia lo stesso giorno: un'informativa che descrive un trattamento
 * diverso da quello reale e' una violazione in se', a prescindere dai dati raccolti.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../src/layout.php';

pagina_inizio(
    'Informativa privacy',
    'Come vengono trattati i dati personali su smpmicroapps.it e nelle app SMP MicroApps.',
    '/legale/privacy'
);

intestazione_legale(
    'Informativa privacy',
    '11 settembre 2026',
    'Quali dati raccogliamo, perché, per quanto tempo e quali diritti hai. '
        . 'Resa ai sensi degli articoli 13 e 14 del Regolamento (UE) 2016/679.'
);
?>

<div class="wrap prose">

  <div class="toc">
    <strong>In breve</strong>
    <ol>
      <li>Le app funzionano senza account e senza registrazione.</li>
      <li>I dati che inserisci nelle app restano nella memoria del telefono.</li>
      <li>Non usiamo strumenti di analisi, profilazione o pubblicità, né nel sito né nelle app.</li>
      <li>L'unico dato che esce dal telefono riguarda la verifica dell'acquisto della versione Pro.</li>
      <li>Il modulo di contatto raccoglie solo quello che scrivi tu.</li>
    </ol>
  </div>

  <h2>1. Titolare del trattamento</h2>

  <p>
    <strong><?= e(AZIENDA['denominazione']) ?></strong>,
    <?= e(AZIENDA['indirizzo']) ?>, <?= e(AZIENDA['cap']) ?> <?= e(AZIENDA['citta']) ?>
    (<?= e(AZIENDA['provincia']) ?>), <?= e(AZIENDA['paese']) ?> —
    P. IVA e C.F. <?= e(AZIENDA['piva']) ?>.
  </p>
  <p>
    Per esercitare i tuoi diritti o per qualunque domanda su questa informativa scrivi a
    <a href="mailto:<?= e(AZIENDA['email']) ?>"><?= e(AZIENDA['email']) ?></a> oppure, via
    posta certificata, a <a href="mailto:<?= e(AZIENDA['pec']) ?>"><?= e(AZIENDA['pec']) ?></a>.
  </p>
  <p>
    Non è stato nominato un responsabile della protezione dei dati (DPO): non ricorre
    nessuno dei casi in cui l'articolo 37 del Regolamento lo rende obbligatorio.
  </p>

  <h2>2. Navigazione sul sito</h2>

  <h3>Dati di connessione</h3>

  <p>
    Il server che ospita questo sito registra, come fa qualunque server web, le richieste
    che riceve: indirizzo IP, data e ora, indirizzo della pagina richiesta, esito della
    richiesta, tipo di browser e sistema operativo dichiarati. Questi dati non sono
    associati a un utente identificato e non vengono usati per costruire profili.
  </p>

  <div class="scroll-x">
    <table>
      <tr><th>Finalità</th><td>Funzionamento tecnico del sito, diagnosi dei guasti, sicurezza e difesa da abusi.</td></tr>
      <tr><th>Base giuridica</th><td>Legittimo interesse del titolare a erogare e proteggere il servizio (art. 6.1.f).</td></tr>
      <tr><th>Conservazione</th><td>Massimo 30 giorni, poi cancellazione automatica dei file di log.</td></tr>
    </table>
  </div>

  <h3>Cookie e tecnologie simili</h3>

  <p>
    Il sito non utilizza cookie di profilazione, non include strumenti di analisi statistica
    e non carica alcuna risorsa da server di terze parti: font, fogli di stile e immagini
    sono serviti dallo stesso dominio. L'unico cookie che può essere impostato è quello
    tecnico di sessione della pagina dei contatti. Per il dettaglio vedi la
    <a href="/legale/cookie">cookie policy</a>.
  </p>

  <h2>3. Modulo di contatto</h2>

  <p>
    Quando invii il modulo raccogliamo <strong>nome, indirizzo email, argomento, app
    eventualmente indicata e testo del messaggio</strong>. Non c'è nessun altro campo, e
    nulla viene dedotto o arricchito da fonti esterne.
  </p>

  <div class="scroll-x">
    <table>
      <tr><th>Finalità</th><td>Rispondere alla tua richiesta e, se necessario, gestire la segnalazione fino alla sua risoluzione.</td></tr>
      <tr><th>Base giuridica</th><td>Consenso, che presti spuntando la casella prima dell'invio (art. 6.1.a). Per le richieste relative a un servizio in corso, esecuzione di misure precontrattuali o contrattuali (art. 6.1.b).</td></tr>
      <tr><th>Conferimento</th><td>Facoltativo, ma senza nome, email e testo non è possibile rispondere.</td></tr>
      <tr><th>Conservazione</th><td>24 mesi dall'ultimo scambio di messaggi, salvo che la conservazione sia necessaria per adempimenti di legge o per la difesa di un diritto in giudizio.</td></tr>
    </table>
  </div>

  <p>
    Ogni messaggio ricevuto viene registrato sul nostro server e, se la casella di posta è
    configurata, inoltrato all'indirizzo aziendale. Registriamo inoltre, per un'ora, un
    valore derivato dal tuo indirizzo IP attraverso una funzione di hash: serve unicamente a
    limitare gli invii ripetuti provenienti dalla stessa connessione. L'indirizzo IP in
    chiaro non viene conservato.
  </p>

  <h2>4. Le applicazioni</h2>

  <h3>Quello che resta sul tuo telefono</h3>

  <p>
    Le app SMP MicroApps <strong>non richiedono registrazione e non hanno account</strong>.
    Tutto quello che inserisci — nel caso di TrashCan: calendari, tipi di rifiuto, regole di
    raccolta, eccezioni, orari dei promemoria e preferenze — è salvato in un database locale
    nella memoria del dispositivo, protetto dall'isolamento fra applicazioni previsto da
    Android. Questi dati non ci vengono trasmessi, non li vediamo e non possiamo recuperarli
    per te: se disinstalli l'app senza aver fatto un'esportazione, si perdono.
  </p>

  <p>
    Le notifiche sono pianificate dal sistema operativo del telefono e il loro contenuto non
    transita da nessun server. Non utilizziamo notifiche push remote. Il widget legge gli
    stessi dati locali.
  </p>

  <p>
    La funzione di esportazione produce un file che <strong>scegli tu</strong> dove salvare o
    a chi inviare. In quel momento i dati escono dall'app perché lo hai chiesto tu, e da quel
    momento il trattamento dipende dal servizio che hai scelto per conservarli o
    condividerli.
  </p>

  <h3>Acquisto e verifica della versione Pro</h3>

  <p>
    L'acquisto della versione Pro avviene interamente su Google Play. Non riceviamo e non
    trattiamo i tuoi dati di pagamento: la carta, i dati di fatturazione e l'identità
    dell'acquirente restano a Google, che opera come titolare autonomo del trattamento.
    Vedi la <a href="https://policies.google.com/privacy" rel="noopener">informativa privacy
    di Google</a>.
  </p>

  <p>
    Per riconoscere un acquisto valido e per impedire che una licenza venga riutilizzata su
    un numero indefinito di dispositivi, l'app comunica con un nostro server. I dati trattati
    in questa fase sono:
  </p>

  <div class="scroll-x">
    <table>
      <tr>
        <th>Identificativo di installazione</th>
        <td>Un codice casuale generato dall'app al primo avvio. Non deriva da alcun
          identificativo del dispositivo, non è l'ID pubblicitario di Android, non permette
          di risalire a te e cambia se disinstalli e reinstalli l'app.</td>
      </tr>
      <tr>
        <th>Token di acquisto e numero d'ordine</th>
        <td>Rilasciati da Google Play al momento dell'acquisto. Servono a verificare presso
          Google che l'acquisto sia reale e non sia stato rimborsato.</td>
      </tr>
      <tr>
        <th>Identificativo dell'app, prodotto acquistato, stato e date</th>
        <td>Per sapere a che cosa hai diritto e da quando.</td>
      </tr>
      <tr>
        <th>Versione dell'app e piattaforma</th>
        <td>Per diagnosticare i problemi legati a una versione specifica.</td>
      </tr>
    </table>
  </div>

  <div class="box">
    <p>
      <strong>Non trattiamo il tuo indirizzo email, il tuo nome o il tuo account Google.</strong>
      Il nostro archivio degli acquisti non contiene dati che permettano di identificarti:
      contiene un codice casuale e la prova che a quel codice corrisponde un acquisto valido.
    </p>
  </div>

  <div class="scroll-x">
    <table>
      <tr><th>Finalità</th><td>Verificare l'acquisto, erogare le funzioni acquistate, gestire rimborsi e revoche, prevenire gli abusi delle licenze.</td></tr>
      <tr><th>Base giuridica</th><td>Esecuzione del contratto relativo alla fornitura del contenuto digitale acquistato (art. 6.1.b) e legittimo interesse alla prevenzione delle frodi (art. 6.1.f).</td></tr>
      <tr><th>Conservazione</th><td>Per tutta la durata della licenza, che è permanente, e per i successivi 10 anni ai fini degli obblighi contabili e di difesa in giudizio.</td></tr>
    </table>
  </div>

  <h3>Codice di trasferimento</h3>

  <p>
    Se cambi telefono e anche account Google, l'app permette di generare un codice
    temporaneo per spostare la licenza sul nuovo dispositivo. Il codice è casuale, scade
    dopo sette giorni, si può usare una sola volta ed è collegato unicamente
    all'identificativo di installazione. Non contiene e non rivela alcun dato personale.
  </p>

  <h3>Nessuna analisi d'uso</h3>

  <p>
    Le app non contengono strumenti di analisi (Firebase Analytics, Crashlytics o
    equivalenti), non raccolgono statistiche su come le usi, non registrano le schermate che
    apri e non contengono pubblicità né identificatori pubblicitari.
  </p>

  <h2>5. A chi comunichiamo i dati</h2>

  <p>
    I dati non vengono venduti, ceduti né comunicati a terzi per finalità commerciali.
    Possono accedervi, nei limiti di quanto necessario allo svolgimento del servizio:
  </p>

  <ul>
    <li>
      <strong>Il fornitore di hosting</strong> del sito e del server delle licenze, che
      agisce come responsabile del trattamento ai sensi dell'art. 28 del Regolamento. I
      server sono situati nell'Unione Europea.
    </li>
    <li>
      <strong>Google Ireland Limited</strong>, in qualità di titolare autonomo, per tutto
      ciò che riguarda la distribuzione dell'app e l'acquisto sul Play Store.
    </li>
    <li>
      <strong>Il fornitore del servizio di posta elettronica</strong> attraverso cui
      transitano i messaggi inviati dal modulo di contatto.
    </li>
    <li>
      Autorità pubbliche, quando la comunicazione sia imposta da una norma di legge o da un
      provvedimento dell'autorità.
    </li>
  </ul>

  <h2>6. Trasferimenti fuori dallo Spazio economico europeo</h2>

  <p>
    Il trattamento avviene di regola all'interno dell'Unione Europea. La verifica degli
    acquisti comporta un'interrogazione ai sistemi di Google, che può trattare dati anche
    negli Stati Uniti: tale trasferimento avviene sulla base della decisione di adeguatezza
    della Commissione europea relativa al quadro UE-USA per la protezione dei dati, e in via
    residuale sulla base delle clausole contrattuali tipo adottate dalla Commissione.
  </p>

  <h2>7. Processi decisionali automatizzati</h2>

  <p>
    Non effettuiamo profilazione né processi decisionali automatizzati che producano effetti
    giuridici su di te o incidano in modo analogamente significativo sulla tua persona, ai
    sensi dell'art. 22 del Regolamento.
  </p>

  <h2>8. I tuoi diritti</h2>

  <p>Nei limiti previsti dagli articoli da 15 a 22 del Regolamento hai diritto di:</p>

  <ul>
    <li>sapere se trattiamo dati che ti riguardano e ottenerne copia (accesso);</li>
    <li>far correggere dati inesatti o completare dati incompleti (rettifica);</li>
    <li>ottenere la cancellazione dei dati, quando non sussista un obbligo di conservarli;</li>
    <li>chiedere che il trattamento sia limitato, in attesa di una verifica;</li>
    <li>opporti al trattamento fondato sul legittimo interesse;</li>
    <li>ricevere i dati in formato strutturato e leggibile da dispositivo automatico (portabilità);</li>
    <li>revocare in ogni momento il consenso prestato, senza che ciò pregiudichi la liceità del trattamento svolto fino a quel momento.</li>
  </ul>

  <div class="box">
    <p>
      <strong>Un limite pratico, detto chiaramente.</strong> Sull'archivio degli acquisti non
      conserviamo dati che permettano di identificarti: se ci scrivi chiedendo l'accesso o la
      cancellazione, non siamo in grado di collegare la tua richiesta a una riga di quel
      registro senza che tu ci fornisca l'identificativo di installazione o il numero
      d'ordine di Google Play. È l'ipotesi prevista dall'art. 11 del Regolamento. Se ci
      fornisci tali riferimenti, procediamo.
    </p>
  </div>

  <p>
    Le richieste vanno inviate a
    <a href="mailto:<?= e(AZIENDA['email']) ?>"><?= e(AZIENDA['email']) ?></a>. Rispondiamo
    senza ingiustificato ritardo e comunque entro un mese, prorogabile di due mesi nei casi
    complessi, dandotene notizia.
  </p>

  <h2>9. Reclamo all'autorità di controllo</h2>

  <p>
    Se ritieni che il trattamento dei tuoi dati violi il Regolamento puoi proporre reclamo al
    <strong>Garante per la protezione dei dati personali</strong>, Piazza Venezia 11, 00187
    Roma — <a href="https://www.garanteprivacy.it" rel="noopener">garanteprivacy.it</a> —
    oppure ricorrere all'autorità giudiziaria.
  </p>

  <h2>10. Minori</h2>

  <p>
    Le app e il sito non sono rivolti specificamente ai minori e non raccolgono
    consapevolmente dati di minori di quattordici anni. Se ritieni che un minore ci abbia
    inviato dati personali attraverso il modulo di contatto, scrivici: li cancelleremo.
  </p>

  <h2>11. Modifiche</h2>

  <p>
    Questa informativa può essere aggiornata per adeguarla a modifiche del servizio o della
    normativa. La versione vigente è sempre quella pubblicata a questo indirizzo, con la data
    di ultimo aggiornamento indicata in testa alla pagina. Le modifiche sostanziali che
    riguardino trattamenti basati sul consenso ti verranno comunicate prima di essere
    applicate.
  </p>

</div>

<?php pagina_fine(); ?>

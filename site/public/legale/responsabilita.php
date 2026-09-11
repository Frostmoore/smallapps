<?php

/**
 * Limitazione di responsabilita' (disclaimer).
 *
 * ⚑ Il punto vero, per TrashCan, e' che i calendari della raccolta li decide il Comune e
 * possono cambiare senza preavviso. Una app che dice "stasera l'organico" non puo'
 * garantire che il camion passi: dirlo qui, in chiaro, e' piu' utile di qualunque formula
 * di stile, e protegge sul serio.
 *
 * ☠ Nessuna clausola di questa pagina puo' escludere la responsabilita' per dolo o colpa
 * grave (art. 1229 c.c.) ne' comprimere la garanzia legale spettante al consumatore. Una
 * clausola che ci provasse sarebbe nulla, e trascinerebbe con se' la credibilita' di tutto
 * il resto.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../src/layout.php';

pagina_inizio(
    'Limitazione di responsabilità',
    'Limiti di responsabilità relativi all\'uso del sito e delle applicazioni '
        . 'SMP MicroApps.',
    '/legale/responsabilita'
);

intestazione_legale(
    'Limitazione di responsabilità',
    '11 settembre 2026',
    'Che cosa possiamo garantire, che cosa no, e perché.'
);
?>

<div class="wrap prose">

  <h2>1. Le informazioni delle app dipendono da te e dal tuo Comune</h2>

  <p>
    Le applicazioni elaborano i dati che <strong>inserisci tu</strong>. Nel caso di TrashCan,
    il calendario della raccolta differenziata non viene scaricato da nessun archivio
    ufficiale: lo configuri tu sulla base di quanto comunicato dal tuo Comune o dal gestore
    del servizio di igiene urbana.
  </p>

  <div class="box">
    <p>
      <strong>Ne consegue che l'applicazione non può garantire che la raccolta avvenga nei
      giorni indicati.</strong> Calendari, festività, sospensioni e variazioni straordinarie
      sono decisi dall'ente competente e possono cambiare senza preavviso. In caso di dubbio
      fa fede sempre e solo la comunicazione ufficiale del Comune o del gestore. Il fornitore
      non risponde di sanzioni, disguidi o mancati ritiri derivanti da un calendario
      configurato in modo non aggiornato o non corretto.
    </p>
  </div>

  <h2>2. Le notifiche dipendono dal sistema operativo</h2>

  <p>
    I promemoria sono pianificati attraverso i servizi di allarme di Android. La loro
    consegna puntuale non è garantita dall'applicazione e può essere impedita o ritardata da
    fattori che l'app non controlla: risparmio energetico, ottimizzazione della batteria,
    modalità «non disturbare», sospensione dell'app da parte del sistema, riavvii del
    dispositivo, personalizzazioni del produttore o revoca dei permessi.
  </p>

  <p>
    <strong>Il promemoria è un aiuto, non un sistema di allerta affidabile.</strong> Non va
    utilizzato per scopi in cui un avviso mancato produca conseguenze rilevanti.
  </p>

  <h2>3. I dati stanno sul tuo dispositivo</h2>

  <p>
    Tutto ciò che inserisci è salvato nella memoria del telefono. Non ne conserviamo copia e
    non possiamo recuperarlo per te. Perdita o rottura del dispositivo, disinstallazione
    dell'app, cancellazione dei dati dell'applicazione o ripristino di fabbrica comportano la
    <strong>perdita definitiva</strong> di quanto inserito.
  </p>

  <p>
    Le applicazioni offrono una funzione di esportazione proprio per questo. Effettuare copie
    di sicurezza e conservarle è responsabilità dell'utente.
  </p>

  <h2>4. Assenza di difetti</h2>

  <p>
    Il software viene sviluppato e collaudato con la diligenza professionale esigibile, ma
    nessun programma è esente da difetti. Le applicazioni sono fornite «così come sono» per
    quanto riguarda l'idoneità a scopi particolari non espressamente dichiarati, ferma
    restando la garanzia legale di conformità spettante ai consumatori, richiamata al punto 6
    delle <a href="/legale/termini">condizioni di servizio</a>.
  </p>

  <h2>5. Contenuti del sito e collegamenti esterni</h2>

  <p>
    I contenuti di questo sito hanno finalità informativa e possono essere aggiornati o
    modificati in qualunque momento. Le descrizioni delle funzioni si riferiscono alla
    versione più recente delle applicazioni: una versione precedente installata sul tuo
    dispositivo può comportarsi diversamente.
  </p>

  <p>
    I collegamenti verso siti di terzi sono forniti per comodità. Il fornitore non controlla
    tali siti e non risponde dei loro contenuti, della loro disponibilità né delle politiche
    che vi si applicano.
  </p>

  <h2>6. Limiti della limitazione</h2>

  <p>Nulla di quanto scritto sopra esclude o limita la responsabilità del fornitore:</p>

  <ul>
    <li>per dolo o colpa grave, ai sensi dell'art. 1229 del codice civile;</li>
    <li>per morte o lesioni personali cagionate da un suo comportamento;</li>
    <li>nei casi in cui la legge, in particolare la normativa a tutela dei consumatori, non
      ammette esclusioni o limitazioni;</li>
    <li>per la garanzia legale di conformità dovuta al consumatore.</li>
  </ul>

  <p>
    Ove una clausola di questa pagina risultasse nulla o inefficace, le restanti conservano
    piena validità.
  </p>

  <h2>7. Contatti</h2>

  <p>
    Per qualunque chiarimento:
    <a href="mailto:<?= e(AZIENDA['email']) ?>"><?= e(AZIENDA['email']) ?></a> —
    <?= e(AZIENDA['denominazione']) ?>, <?= e(AZIENDA['indirizzo']) ?>,
    <?= e(AZIENDA['cap']) ?> <?= e(AZIENDA['citta']) ?> (<?= e(AZIENDA['provincia']) ?>).
  </p>

</div>

<?php pagina_fine(); ?>

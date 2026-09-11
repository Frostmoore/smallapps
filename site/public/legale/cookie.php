<?php

/**
 * Cookie policy.
 *
 * ⚑ E' corta perche' il sito e' stato costruito perche' fosse corta. Niente font esterni,
 * niente CDN, niente analytics, niente widget social: senza terze parti non c'e' niente da
 * far consentire, e quindi niente banner. Il banner non e' un adempimento: e' il prezzo che
 * si paga per aver messo in pagina roba di altri.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../src/layout.php';

pagina_inizio(
    'Cookie policy',
    'Quali cookie usa smpmicroapps.it: solo un cookie tecnico di sessione, nessun cookie '
        . 'di profilazione e nessuna risorsa di terze parti.',
    '/legale/cookie'
);

intestazione_legale(
    'Cookie policy',
    '11 settembre 2026',
    'Questo sito non usa cookie di profilazione e non carica nulla da server di terze parti.'
);
?>

<div class="wrap prose">

  <h2>1. Che cosa sono i cookie</h2>

  <p>
    I cookie sono piccoli file di testo che un sito salva nel browser di chi lo visita, per
    essere riletti nelle visite successive. Servono a ricordare informazioni fra una pagina e
    l'altra. La stessa disciplina si applica a tecnologie equivalenti, come il local storage
    del browser o i pixel di tracciamento.
  </p>

  <h2>2. I cookie di questo sito</h2>

  <p>
    Questo sito utilizza <strong>un solo cookie</strong>, e solo in una pagina.
  </p>

  <div class="scroll-x">
    <table>
      <tr>
        <th>Nome</th>
        <th>Tipo</th>
        <th>Quando viene impostato</th>
        <th>A cosa serve</th>
        <th>Durata</th>
      </tr>
      <tr>
        <td><code>smpmicroapps</code></td>
        <td>Tecnico di sessione, di prima parte</td>
        <td>Solo aprendo la pagina <a href="/contatti">Contatti</a></td>
        <td>
          Collega il modulo alla sessione del browser per verificare che l'invio provenga
          davvero dal modulo di questo sito, e non da una pagina di terzi che lo invia a tua
          insaputa. Senza, il modulo sarebbe esposto agli attacchi di tipo CSRF.
        </td>
        <td>Fino alla chiusura del browser</td>
      </tr>
    </table>
  </div>

  <p>
    Si tratta di un cookie tecnico strettamente necessario a erogare un servizio richiesto
    dall'utente. Ai sensi dell'art. 122 del Codice privacy e delle Linee guida del Garante
    del 10 giugno 2021 <strong>non richiede consenso preventivo</strong>, e per questo il
    sito non mostra alcun banner.
  </p>

  <h2>3. Quello che questo sito non fa</h2>

  <ul>
    <li>Non usa cookie di profilazione né cookie pubblicitari.</li>
    <li>Non usa strumenti di analisi statistica, di prima o di terza parte.</li>
    <li>Non carica font, fogli di stile, script o immagini da server esterni: ogni risorsa
      è servita dallo stesso dominio, quindi nessun terzo riceve il tuo indirizzo IP
      visitando queste pagine.</li>
    <li>Non incorpora video, mappe, pulsanti social o widget di altri servizi.</li>
    <li>Non traccia la navigazione fra siti diversi e non partecipa a circuiti pubblicitari.</li>
  </ul>

  <div class="box">
    <p>
      I link che portano fuori da questo sito, per esempio quello alla scheda dell'app su
      Google Play, conducono a pagine gestite da altri soggetti, che applicano le proprie
      politiche sui cookie. Una volta uscito da qui, valgono le loro regole.
    </p>
  </div>

  <h2>4. Le applicazioni</h2>

  <p>
    Le app SMP MicroApps non sono pagine web e non usano cookie. Le preferenze dell'app sono
    salvate nella memoria locale del dispositivo e non sono leggibili da nessun altro
    programma né da noi.
  </p>

  <h2>5. Come gestire i cookie dal browser</h2>

  <p>
    Ogni browser permette di visualizzare, bloccare o cancellare i cookie dalle proprie
    impostazioni di privacy. Bloccando i cookie tecnici di questo sito le pagine restano
    leggibili, ma <strong>il modulo di contatto smette di funzionare</strong>: senza il
    cookie di sessione il controllo anti-CSRF non può riuscire, e l'invio verrà rifiutato.
    In quel caso puoi scrivere direttamente a
    <a href="mailto:<?= e(AZIENDA['email']) ?>"><?= e(AZIENDA['email']) ?></a>.
  </p>

  <h2>6. Titolare</h2>

  <p>
    <?= e(AZIENDA['denominazione']) ?>, <?= e(AZIENDA['indirizzo']) ?>,
    <?= e(AZIENDA['cap']) ?> <?= e(AZIENDA['citta']) ?> (<?= e(AZIENDA['provincia']) ?>) —
    P. IVA e C.F. <?= e(AZIENDA['piva']) ?>.
    Per informazioni: <a href="mailto:<?= e(AZIENDA['email']) ?>"><?= e(AZIENDA['email']) ?></a>.
    Vedi anche l'<a href="/legale/privacy">informativa privacy</a>.
  </p>

</div>

<?php pagina_fine(); ?>

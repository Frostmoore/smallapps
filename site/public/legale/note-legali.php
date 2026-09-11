<?php

/**
 * Note legali (impressum).
 *
 * ⚑ In Italia non si chiama "impressum", ma l'obbligo esiste lo stesso e nasce da due
 * norme diverse: l'art. 7 del d.lgs. 70/2003, che impone al prestatore di servizi della
 * societa' dell'informazione di rendere accessibili in modo diretto e permanente i propri
 * dati identificativi, e l'art. 2250 del codice civile per chi e' iscritto al Registro
 * delle Imprese. Per questo la pagina e' linkata dal pie' di **ogni** pagina.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../src/layout.php';

pagina_inizio(
    'Note legali',
    'Dati identificativi del titolare del sito smpmicroapps.it e delle app SMP MicroApps.',
    '/legale/note-legali'
);

intestazione_legale(
    'Note legali',
    '11 settembre 2026',
    'Chi gestisce questo sito e le applicazioni che vi sono presentate.'
);
?>

<div class="wrap prose">

  <h2>Titolare del sito</h2>

  <div class="scroll-x">
    <table>
      <tr><th>Denominazione</th><td><?= e(AZIENDA['denominazione']) ?></td></tr>
      <tr><th>Titolare</th><td><?= e(AZIENDA['titolare']) ?></td></tr>
      <tr><th>Sede</th><td><?= e(AZIENDA['indirizzo']) ?>, <?= e(AZIENDA['cap']) ?> <?= e(AZIENDA['citta']) ?> (<?= e(AZIENDA['provincia']) ?>), <?= e(AZIENDA['paese']) ?></td></tr>
      <tr><th>Partita IVA e Codice Fiscale</th><td><?= e(AZIENDA['piva']) ?></td></tr>
      <?php if (AZIENDA['rea'] !== ''): ?>
        <tr><th>Numero REA</th><td><?= e(AZIENDA['rea']) ?></td></tr>
      <?php endif; ?>
      <tr><th>Email</th><td><a href="mailto:<?= e(AZIENDA['email']) ?>"><?= e(AZIENDA['email']) ?></a></td></tr>
      <tr><th>PEC</th><td><a href="mailto:<?= e(AZIENDA['pec']) ?>"><?= e(AZIENDA['pec']) ?></a></td></tr>
      <tr><th>Sito</th><td><?= e(SITO_URL) ?></td></tr>
    </table>
  </div>

  <h2>Oggetto del sito</h2>

  <p>
    Questo sito presenta le applicazioni per dispositivi Android sviluppate e distribuite
    dal titolare sopra indicato, e mette a disposizione un modulo per richiedere assistenza,
    segnalare malfunzionamenti e chiedere informazioni su servizi di sviluppo software su
    misura.
  </p>

  <p>
    Il sito <strong>non è un negozio</strong>: non vi si conclude alcun contratto di
    acquisto e non vi si effettuano pagamenti. La distribuzione delle applicazioni e la
    vendita delle relative funzioni aggiuntive avvengono esclusivamente attraverso Google
    Play, gestito da Google Ireland Limited. Le condizioni economiche, il diritto di recesso
    e la procedura di rimborso relativi a tali acquisti sono regolati dai termini di Google
    Play, come indicato nelle <a href="/legale/termini">condizioni di servizio</a>.
  </p>

  <h2>Proprietà intellettuale</h2>

  <p>
    I testi, la grafica, i loghi, le icone, il codice sorgente delle applicazioni e ogni
    altro contenuto di questo sito sono di proprietà del titolare, salvo dove diversamente
    indicato, e sono protetti dalla normativa sul diritto d'autore. Ne è vietata la
    riproduzione, anche parziale, senza autorizzazione scritta.
  </p>

  <p>
    Android, Google Play e il logo Google Play sono marchi di Google LLC. La loro citazione
    ha finalità esclusivamente descrittiva e non implica alcun rapporto di affiliazione,
    sponsorizzazione o approvazione da parte di Google.
  </p>

  <h2>Segnalazione di contenuti</h2>

  <p>
    Per segnalare un contenuto che si ritenga lesivo di un proprio diritto è possibile
    scrivere a <a href="mailto:<?= e(AZIENDA['email']) ?>"><?= e(AZIENDA['email']) ?></a>
    oppure, per comunicazioni con valore legale, alla casella PEC
    <a href="mailto:<?= e(AZIENDA['pec']) ?>"><?= e(AZIENDA['pec']) ?></a>. Le segnalazioni
    ricevute vengono esaminate e, se fondate, il contenuto viene rimosso senza indugio.
  </p>

  <h2>Legge applicabile e foro competente</h2>

  <p>
    Il rapporto con gli utenti di questo sito è regolato dalla legge italiana. Per le
    controversie con soggetti che agiscono al di fuori della propria attività commerciale
    (consumatori) è competente il giudice del luogo di residenza o domicilio del consumatore,
    se situato in Italia. In tutti gli altri casi è competente in via esclusiva il Foro di
    Viterbo.
  </p>

  <div class="box">
    <p>
      Le informazioni sul trattamento dei dati personali sono contenute nell'<a href="/legale/privacy">informativa
      privacy</a>. Le informazioni sui cookie sono nella <a href="/legale/cookie">cookie policy</a>.
    </p>
  </div>

</div>

<?php pagina_fine(); ?>

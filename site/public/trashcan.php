<?php

/**
 * La vetrina di TrashCan.
 *
 * ⚑ Il testo e' commerciale ma non promette cose che l'app non fa. Una pagina che vende
 * funzioni inesistenti non produce vendite, produce rimborsi e recensioni da una stella,
 * e su Play la valutazione non si recupera piu'.
 */

declare(strict_types=1);

require_once __DIR__ . '/../src/layout.php';

$app = app_per_slug('trashcan');
$play = link_play($app);

pagina_inizio(
    'TrashCan, il calendario della raccolta differenziata',
    'TrashCan ti ricorda la sera prima cosa portare fuori. Calendario della raccolta '
        . 'differenziata con promemoria e widget. Gratis, Pro a 2,99 € una tantum.',
    '/trashcan'
);
?>

<section class="hero">
  <div class="wrap">
    <p class="eyebrow">TrashCan · Android</p>
    <h1 class="display">Stasera cosa<br>si butta?</h1>
    <p class="lede">
      Il calendario della raccolta differenziata del tuo Comune, con il promemoria la sera
      prima e il widget sulla schermata iniziale. Il bidone giusto, la sera giusta.
    </p>
    <div class="hero__actions">
      <?php if ($play !== null): ?>
        <a class="btn btn--primary" href="<?= e($play) ?>" rel="noopener">Scarica su Google Play</a>
      <?php else: ?>
        <span class="btn" aria-disabled="true">Presto su Google Play</span>
      <?php endif; ?>
      <a class="btn btn--ghost" href="#funzioni">Cosa sa fare</a>
    </div>
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title">Il problema è sempre lo stesso</h2>
      <p>
        Il calendario della raccolta è un foglio attaccato al frigo, o un PDF del Comune che
        nessuno riapre. Te ne ricordi la mattina dopo, quando il camion è già passato.
        TrashCan te lo ricorda mentre sei ancora in casa.
      </p>
    </div>

    <div class="features">
      <div class="feature">
        <span class="feature__num" aria-hidden="true">1</span>
        <h3>Lo imposti una volta</h3>
        <p>
          Una procedura guidata in quattro passi: scegli i tipi di rifiuto, i giorni in cui
          passano e l'ora del promemoria. Cinque minuti e non ci pensi più.
        </p>
      </div>
      <div class="feature">
        <span class="feature__num" aria-hidden="true">2</span>
        <h3>Regge i calendari veri</h3>
        <p>
          Settimanale, a settimane alterne, ogni due settimane con data di partenza, mensile
          per posizione, o date scelte a mano. Anche i giri strani del tuo Comune ci stanno.
        </p>
      </div>
      <div class="feature">
        <span class="feature__num" aria-hidden="true">3</span>
        <h3>Le eccezioni non ti fregano</h3>
        <p>
          Festività, salti e raccolte straordinarie: segni la variazione sul singolo giorno
          e il promemoria si aggiusta da solo, senza toccare la regola.
        </p>
      </div>
    </div>
  </div>
</section>

<section class="section section--tint" id="funzioni">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title">Cosa trovi dentro</h2>
      <p>Tutto quello che serve per non sbagliare bidone, e niente altro.</p>
    </div>

    <div class="features">
      <div class="feature">
        <h3>La schermata "Stasera"</h3>
        <p>
          Apri l'app e la prima cosa che vedi è cosa portare fuori stasera, grande e a
          colori. Sotto, la prossima raccolta e i sette giorni successivi.
        </p>
      </div>
      <div class="feature">
        <h3>Il widget sulla home</h3>
        <p>
          Stretto e verticale: l'intestazione colorata dice cosa si butta stasera, con la
          sua icona; sotto, i giorni che vengono. Non serve nemmeno aprire l'app.
        </p>
      </div>
      <div class="feature">
        <h3>Promemoria puntuale</h3>
        <p>
          Una notifica all'ora che scegli, la sera prima della raccolta. Toccandola si apre
          direttamente il giorno interessato.
        </p>
      </div>
      <div class="feature">
        <h3>Tipi di rifiuto tuoi</h3>
        <p>
          Ogni Comune ha le sue categorie e i suoi nomi. Parti dai tipi già pronti e
          rinominali, cambia icona e colore, o creane di nuovi.
        </p>
      </div>
      <div class="feature">
        <h3>Backup ed esportazione</h3>
        <p>
          Un file che contiene tutto il calendario: lo salvi dove vuoi, lo rimetti su un
          altro telefono, o lo passi a un familiare che abita nella stessa via.
        </p>
      </div>
      <div class="feature">
        <h3>Italiano e inglese</h3>
        <p>
          L'app segue la lingua del telefono. Le date e i giorni della settimana anche.
        </p>
      </div>
    </div>
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title">Gratis, e poi Pro se ti serve</h2>
      <p>
        Un acquisto solo, nessun abbonamento, nessun rinnovo. Se cambi telefono lo
        ripristini dal tuo account Google, e se hai cambiato anche account c'è un codice di
        trasferimento dentro l'app.
      </p>
    </div>

    <div class="price">
      <div class="plan">
        <h3>Base</h3>
        <p class="plan__price">Gratis</p>
        <ul class="ticks">
          <li>Un calendario della raccolta</li>
          <li>Tipi di rifiuto e regole illimitati</li>
          <li>Eccezioni, salti e raccolte straordinarie</li>
          <li>Widget con la raccolta di stasera</li>
          <li>Esportazione e backup del calendario</li>
          <li>Nessuna pubblicità</li>
        </ul>
      </div>

      <div class="plan plan--pro">
        <h3>Pro</h3>
        <p class="plan__price">
          <?= e($app['prezzoPro']) ?> <small>una tantum</small>
        </p>
        <ul class="ticks">
          <li>Tutto quello che c'è nella versione base</li>
          <li><strong>I promemoria</strong>: la notifica la sera prima</li>
          <li>Doppio promemoria, per chi al primo non si muove</li>
          <li>Calendari multipli: casa, casa al mare, i genitori</li>
          <li>Widget con i prossimi tre giorni invece di uno</li>
          <li>Il colore dell'app scelto da te, fra dieci</li>
        </ul>
        <p style="margin-top:1.25rem">
          <?php if ($play !== null): ?>
            <a class="btn btn--dark" href="<?= e($play) ?>" rel="noopener">Scarica su Google Play</a>
          <?php else: ?>
            <span class="btn" aria-disabled="true" style="background:#e4e8e5;color:#6f7c75">Presto su Google Play</span>
          <?php endif; ?>
        </p>
      </div>
    </div>
  </div>
</section>

<section class="section section--tint">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title">I tuoi dati restano tuoi</h2>
      <p>
        TrashCan non ha account, non chiede registrazione e non raccoglie statistiche d'uso.
        Il calendario, i tipi di rifiuto e i promemoria vivono nella memoria del telefono e
        non vengono inviati da nessuna parte. L'unica cosa che esce dal dispositivo è la
        verifica dell'acquisto, perché la fa Google.
      </p>
      <p style="margin-top:1rem">
        <a href="/legale/privacy">Leggi l'informativa privacy completa &rarr;</a>
      </p>
    </div>
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="cta">
      <h2>Qualcosa non va, o manca qualcosa?</h2>
      <p>
        Le segnalazioni le legge una persona sola, che è la stessa che scrive il codice.
        Scrivi cosa è successo e su che telefono: è il modo più veloce perché venga
        sistemato.
      </p>
      <div>
        <a class="btn btn--primary" href="/contatti#bug">Segnala un problema</a>
      </div>
    </div>
  </div>
</section>

<?php pagina_fine(); ?>

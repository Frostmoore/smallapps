<?php

/** La home: titolo grande, che cosa sono queste app, e la griglia del catalogo. */

declare(strict_types=1);

require_once __DIR__ . '/../src/layout.php';

$apps = catalogo();
$pubblicate = array_filter($apps, static fn (array $a): bool => $a['pubblicata']);

pagina_inizio(
    'App piccole per Android, che fanno una cosa sola',
    'SMP MicroApps: applicazioni Android leggere, senza account e senza abbonamenti. '
        . 'Versione base gratuita, Pro con un acquisto una tantum.',
    '/'
);
?>

<section class="hero">
  <div class="wrap">
    <p class="eyebrow">App per Android</p>
    <h1 class="display">Una cosa sola.<br>Fatta bene.</h1>
    <p class="lede">
      Micro applicazioni che rispondono a una domanda precisa e si tolgono di mezzo.
      Nessun account, nessuna pubblicità, nessun abbonamento: la versione base è gratis,
      il Pro si sblocca una volta e resta tuo.
    </p>
    <div class="hero__actions">
      <a class="btn btn--primary" href="#app">Guarda le app</a>
      <a class="btn btn--ghost" href="/contatti#personalizzato">Ti serve un'app su misura?</a>
    </div>
  </div>
</section>

<section class="section" id="app">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title">Il catalogo</h2>
      <p>
        <?php
        // Il conteggio si scrive per esteso invece di infilare due numeri in una frase:
        // "1 su 4 sono disponibili" non concorda, e la stessa frase con due app
        // pubblicate non concorderebbe al contrario. Due rami e il problema sparisce.
        ?>
        <?php if (count($pubblicate) === 1): ?>
          Una è già scaricabile, le altre sono in lavorazione.
        <?php else: ?>
          <?= count($pubblicate) ?> sono già scaricabili, le altre sono in lavorazione.
        <?php endif; ?>
        Le trovi qui perché arrivano, non perché sono pronte.
      </p>
    </div>

    <div class="grid">
      <?php foreach ($apps as $slug => $app): ?>
        <?php
        // La card è un link solo se c'è qualcosa da aprire. Un <a> che non porta da
        // nessuna parte è peggio di un riquadro spento: sembra un sito rotto.
        $tag = $app['pubblicata'] ? 'a' : 'div';
        $classi = 'card' . ($app['pubblicata'] ? '' : ' card--soon');
        ?>
        <<?= $tag ?>
          class="<?= $classi ?>"
          style="--card-accent: <?= e($app['accento']) ?>"
          <?= $app['pubblicata'] ? 'href="/' . e($slug) . '"' : '' ?>>

          <?php if ($app['logo'] !== null): ?>
            <img class="card__logo" src="<?= e($app['logo']) ?>" alt="" width="58" height="58">
          <?php else: ?>
            <span class="card__logo card__logo--letter" aria-hidden="true">
              <?= e(mb_substr($app['nome'], 0, 1)) ?>
            </span>
          <?php endif; ?>

          <span class="tag <?= $app['pubblicata'] ? 'tag--live' : '' ?>">
            <?= $app['pubblicata'] ? 'Disponibile' : 'In arrivo' ?>
          </span>

          <h3 class="card__name"><?= e($app['nome']) ?></h3>
          <p class="card__claim"><?= e($app['claim']) ?></p>
          <p class="card__text"><?= e($app['sommario']) ?></p>

          <p class="card__foot">
            <?= $app['pubblicata'] ? 'Scopri di più &rarr;' : 'In lavorazione' ?>
          </p>
        </<?= $tag ?>>
      <?php endforeach; ?>
    </div>
  </div>
</section>

<section class="section section--tint">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title">Come la pensiamo</h2>
      <p>Tre scelte che valgono per tutte le app del catalogo, senza eccezioni.</p>
    </div>

    <div class="features">
      <div class="feature">
        <span class="feature__num" aria-hidden="true">1</span>
        <h3>Si paga una volta</h3>
        <p>
          Niente abbonamenti. La versione Pro si sblocca con un acquisto singolo e resta
          sbloccata, anche cambiando telefono. Non c'è niente che scade.
        </p>
      </div>
      <div class="feature">
        <span class="feature__num" aria-hidden="true">2</span>
        <h3>I dati restano sul telefono</h3>
        <p>
          Nessun account da creare, nessun profilo, nessuna raccolta di statistiche d'uso.
          Quello che scrivi nell'app resta nell'app, e puoi esportarlo quando vuoi.
        </p>
      </div>
      <div class="feature">
        <span class="feature__num" aria-hidden="true">3</span>
        <h3>Niente pubblicità</h3>
        <p>
          Non c'è spazio per un banner in un'app che deve rispondere a una domanda in due
          secondi. Nemmeno nella versione gratuita.
        </p>
      </div>
    </div>
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="cta">
      <h2>Hai in mente un'app che non esiste?</h2>
      <p>
        Sviluppo software su misura: gestionali, automazioni, applicazioni mobili e
        strumenti interni. Raccontami il problema e ti dico se e come si risolve.
      </p>
      <div>
        <a class="btn btn--primary" href="/contatti#personalizzato">Parliamone</a>
      </div>
    </div>
  </div>
</section>

<?php pagina_fine(); ?>

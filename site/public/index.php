<?php

/** La home: titolo grande, che cosa sono queste app, e la griglia del catalogo. */

declare(strict_types=1);

require_once __DIR__ . '/../src/layout.php';

$lingua = lingua_corrente();
$apps = catalogo();
$pubblicate = array_filter($apps, static fn (array $a): bool => $a['pubblicata']);

pagina_inizio('home.titolo', 'home.descrizione', '/');
?>

<section class="hero">
  <div class="wrap">
    <p class="eyebrow"><?= t('home.eyebrow') ?></p>
    <h1 class="display"><?= t('home.hero.titolo') ?></h1>
    <p class="lede"><?= t('home.hero.lede') ?></p>
    <div class="hero__actions">
      <a class="btn btn--primary" href="#app"><?= t('home.hero.cta1') ?></a>
      <a class="btn btn--ghost" href="<?= e(url_per($lingua, '/contatti')) ?>#personalizzato">
        <?= t('home.hero.cta2') ?>
      </a>
    </div>
  </div>
</section>

<section class="section" id="app">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title"><?= t('home.catalogo.titolo') ?></h2>
      <p>
        <?php
        // Il conteggio ha due forme invece di infilare un numero in una frase sola:
        // "1 su 4 sono disponibili" non concorda, e nessuna formulazione unica regge sia
        // il singolare sia il plurale in entrambe le lingue.
        echo count($pubblicate) === 1
            ? t('home.catalogo.una')
            : t('home.catalogo.molte', ['n' => (string) count($pubblicate)]);
        ?>
        <?= t('home.catalogo.coda') ?>
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
          <?= $app['pubblicata'] ? 'href="' . e(url_per($lingua, '/' . $slug)) . '"' : '' ?>>

          <?php if (($app['testata'] ?? null) !== null): ?>
            <?php /* La testata ha gia' icona e nome dell'app: il logo sotto sarebbe un doppione. */ ?>
            <img class="card__testata" src="<?= e(str_replace('{lingua}', $lingua, $app['testata'])) ?>"
                 alt="" width="1024" height="500">
          <?php elseif ($app['logo'] !== null): ?>
            <img class="card__logo" src="<?= e($app['logo']) ?>" alt="" width="58" height="58">
          <?php else: ?>
            <span class="card__logo card__logo--letter" aria-hidden="true">
              <?= e(mb_substr($app['nome'], 0, 1)) ?>
            </span>
          <?php endif; ?>

          <span class="tag <?= $app['pubblicata'] ? 'tag--live' : '' ?>">
            <?= $app['pubblicata'] ? t('comune.disponibile') : t('comune.in_arrivo') ?>
          </span>

          <h3 class="card__name"><?= e($app['nome']) ?></h3>
          <p class="card__claim"><?= t("app.{$slug}.claim") ?></p>
          <p class="card__text"><?= t("app.{$slug}.sommario") ?></p>

          <p class="card__foot">
            <?= $app['pubblicata'] ? t('comune.scopri') : t('comune.in_lavorazione') ?>
          </p>
        </<?= $tag ?>>
      <?php endforeach; ?>
    </div>
  </div>
</section>

<section class="section section--tint">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title"><?= t('home.principi.titolo') ?></h2>
      <p><?= t('home.principi.lede') ?></p>
    </div>

    <div class="features">
      <?php foreach ([1, 2, 3] as $n): ?>
        <div class="feature">
          <span class="feature__num" aria-hidden="true"><?= $n ?></span>
          <h3><?= t("home.principi.{$n}.titolo") ?></h3>
          <p><?= t("home.principi.{$n}.testo") ?></p>
        </div>
      <?php endforeach; ?>
    </div>
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="cta">
      <h2><?= t('home.cta.titolo') ?></h2>
      <p><?= t('home.cta.testo') ?></p>
      <div>
        <a class="btn btn--primary" href="<?= e(url_per($lingua, '/contatti')) ?>#personalizzato">
          <?= t('home.cta.bottone') ?>
        </a>
      </div>
    </div>
  </div>
</section>

<?php pagina_fine(); ?>

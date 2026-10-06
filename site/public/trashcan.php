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

$lingua = lingua_corrente();
$app = app_per_slug('trashcan');
$play = link_play($app);
$appStore = link_app_store($app);

pagina_inizio('trashcan.titolo', 'trashcan.descrizione', '/trashcan');
?>

<section class="hero">
  <div class="wrap">
    <p class="eyebrow"><?= t('trashcan.eyebrow') ?></p>
    <h1 class="display"><?= t('trashcan.hero.titolo') ?></h1>
    <p class="lede"><?= t('trashcan.hero.lede') ?></p>
    <div class="hero__actions">
      <?php if ($play !== null): ?>
        <a class="btn btn--primary" href="<?= e($play) ?>" rel="noopener"><?= t('comune.scarica_play') ?></a>
      <?php endif; ?>
      <?php if ($appStore !== null): ?>
        <a class="btn btn--primary" href="<?= e($appStore) ?>" rel="noopener"><?= t('comune.scarica_app_store') ?></a>
      <?php endif; ?>
      <?php if ($play === null && $appStore === null): ?>
        <span class="btn" aria-disabled="true"><?= t('comune.presto_store') ?></span>
      <?php endif; ?>
      <a class="btn btn--ghost" href="#funzioni"><?= t('trashcan.hero.cta') ?></a>
    </div>
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title"><?= t('trashcan.problema.titolo') ?></h2>
      <p><?= t('trashcan.problema.lede') ?></p>
    </div>

    <div class="features">
      <?php foreach ([1, 2, 3] as $n): ?>
        <div class="feature">
          <span class="feature__num" aria-hidden="true"><?= $n ?></span>
          <h3><?= t("trashcan.problema.{$n}.titolo") ?></h3>
          <p><?= t("trashcan.problema.{$n}.testo") ?></p>
        </div>
      <?php endforeach; ?>
    </div>
  </div>
</section>

<section class="section section--tint" id="funzioni">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title"><?= t('trashcan.funzioni.titolo') ?></h2>
      <p><?= t('trashcan.funzioni.lede') ?></p>
    </div>

    <div class="features">
      <?php foreach ([1, 2, 3, 4, 5, 6] as $n): ?>
        <div class="feature">
          <h3><?= t("trashcan.funzioni.{$n}.titolo") ?></h3>
          <p><?= t("trashcan.funzioni.{$n}.testo") ?></p>
        </div>
      <?php endforeach; ?>
    </div>
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title"><?= t('trashcan.prezzi.titolo') ?></h2>
      <p><?= t('trashcan.prezzi.lede') ?></p>
    </div>

    <div class="price">
      <div class="plan">
        <h3><?= t('trashcan.prezzi.base') ?></h3>
        <p class="plan__price"><?= t('trashcan.prezzi.gratis') ?></p>
        <ul class="ticks"><?= t('trashcan.prezzi.base.lista') ?></ul>
      </div>

      <div class="plan plan--pro">
        <h3><?= t('trashcan.prezzi.pro') ?></h3>
        <p class="plan__price">
          <?= t('app.trashcan.prezzo') ?> <small><?= t('trashcan.prezzi.unatantum') ?></small>
        </p>
        <ul class="ticks"><?= t('trashcan.prezzi.pro.lista') ?></ul>
        <p style="margin-top:1.25rem">
          <?php if ($play !== null): ?>
            <a class="btn btn--dark" href="<?= e($play) ?>" rel="noopener"><?= t('comune.scarica_play') ?></a>
          <?php endif; ?>
          <?php if ($appStore !== null): ?>
            <a class="btn btn--dark" href="<?= e($appStore) ?>" rel="noopener"><?= t('comune.scarica_app_store') ?></a>
          <?php endif; ?>
          <?php if ($play === null && $appStore === null): ?>
            <span class="btn btn--spento" aria-disabled="true"><?= t('comune.presto_store') ?></span>
          <?php endif; ?>
        </p>
      </div>
    </div>
  </div>
</section>

<section class="section section--tint">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title"><?= t('trashcan.privacy.titolo') ?></h2>
      <p><?= t('trashcan.privacy.testo') ?></p>
      <p style="margin-top:1rem">
        <a href="<?= e(url_per($lingua, '/legale/privacy')) ?>"><?= t('trashcan.privacy.link') ?></a>
      </p>
    </div>
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="cta">
      <h2><?= t('trashcan.bug.titolo') ?></h2>
      <p><?= t('trashcan.bug.testo') ?></p>
      <div>
        <a class="btn btn--primary" href="<?= e(url_per($lingua, '/contatti')) ?>#bug">
          <?= t('trashcan.bug.bottone') ?>
        </a>
      </div>
    </div>
  </div>
</section>

<?php pagina_fine(); ?>

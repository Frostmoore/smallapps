<?php

/**
 * La pagina vetrina di un'app, sul modello di `public/trashcan.php`.
 *
 * Usata da `public/scorte-calore.php` e `public/film-tracker.php` (2026-10-10). TrashCan resta
 * col suo file, che ha le promozionali in tre righe per forma e chiavi proprie: e' il modello
 * da cui questa funzione e' nata, e riscriverlo non portava niente al visitatore.
 *
 * Sezioni, nell'ordine: hero con testata a destra, «Com'e' fatta» (screenshot), problema
 * (3 schede), funzioni (6 schede), «In due parole» (solo se ci sono le immagini), prezzi,
 * privacy, segnalazione dei bug.
 *
 * Chiavi lette dai dizionari, con `<slug>` = lo slug del catalogo:
 *   <slug>.titolo, <slug>.descrizione, <slug>.hero.{titolo,lede}, <slug>.img.testata,
 *   <slug>.schermate.<n> (1..N, una per screenshot), <slug>.problema.{titolo,lede},
 *   <slug>.problema.<1..3>.{titolo,testo}, <slug>.funzioni.{titolo,lede},
 *   <slug>.funzioni.<1..6>.{titolo,testo}, <slug>.prezzi.{titolo,lede,base.lista,pro.lista},
 *   <slug>.privacy.{titolo,testo}, app.<slug>.prezzo, e le comuni comune.* (schermate,
 *   piano, privacy.link, bug, cosa_sa_fare, android_in_arrivo, ios_in_arrivo, promo).
 *
 * ⚑ Il testo e' commerciale ma non promette cose che l'app non fa: ogni funzione nominata
 * nei dizionari e' presa dalla scheda dello store e da `feature_limits.dart` dell'app.
 */

declare(strict_types=1);

require_once __DIR__ . '/layout.php';

/**
 * Stampa la pagina intera di un'app.
 *
 * @param string                     $slug      lo slug del catalogo, che e' anche la cartella
 *                                              delle immagini `public/assets/img/<slug>/`
 * @param list<string>               $schermate i nomi degli screenshot senza lingua ne'
 *                                              estensione (`01-home`): il file e'
 *                                              `screen-<lingua>-<nome>.webp`, 480x1043
 * @param array<string,list<string>> $promo     le promozionali per forma (`quadre`, `larghe`,
 *                                              `verticali`) => nomi `NN-nome`; il file e'
 *                                              `promo-<lingua>-<nome>.webp`, l'alt e' la chiave
 *                                              `<slug>.promo.<nome>`. Vuoto = sezione assente.
 */
function pagina_app(string $slug, array $schermate, array $promo = []): void
{
    $lingua = lingua_corrente();
    $app = app_per_slug($slug);
    if ($app === null || !$app['pubblicata']) {
        http_response_code(404);
        echo '404';
        return;
    }
    $play = link_play($app);
    $appStore = link_app_store($app);
    $img = '/assets/img/' . $slug;

    // ⚑ La sezione «In due parole» compare solo con le immagini **della lingua della pagina**
    // davvero presenti sul disco: le promozionali hanno il testo dentro, e una pagina inglese
    // con immagini italiane sarebbe una pagina italiana travestita. Finche' non ci sono, la
    // sezione non esiste: niente titolo sopra il vuoto.
    $promoPresenti = [];
    foreach ($promo as $forma => $nomi) {
        $nomi = array_values(array_filter(
            $nomi,
            static fn (string $n): bool => is_file(__DIR__ . "/../public{$img}/promo-{$lingua}-{$n}.webp")
        ));
        if ($nomi !== []) {
            $promoPresenti[$forma] = $nomi;
        }
    }

    pagina_inizio("{$slug}.titolo", "{$slug}.descrizione", '/' . $slug);
    ?>

<section class="hero">
  <div class="wrap hero__grid">
    <div>
    <p class="eyebrow"><?= e($app['nome']) ?> · <?= etichetta_disponibilita($app) ?></p>
    <h1 class="display"><?= t("{$slug}.hero.titolo") ?></h1>
    <p class="lede"><?= t("{$slug}.hero.lede") ?></p>
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
      <a class="btn btn--ghost" href="#funzioni"><?= t('comune.cosa_sa_fare') ?></a>
    </div>
    <?php
    // ☠ Una riga discreta, non un bottone spento: un pulsante «presto su Play» sembra una
    // promessa con una data, e la data non c'e'. Decisione del proprietario, 2026-10-10.
    ?>
    <?php if ($play === null && $appStore !== null): ?>
      <p class="meta hero__nota"><?= t('comune.android_in_arrivo') ?></p>
    <?php elseif ($appStore === null && $play !== null): ?>
      <p class="meta hero__nota"><?= t('comune.ios_in_arrivo') ?></p>
    <?php endif; ?>
    </div>
    <img class="hero__img" src="<?= e($img) ?>/testata-<?= e($lingua) ?>.webp"
         width="1024" height="500" alt="<?= t("{$slug}.img.testata") ?>">
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title"><?= t('comune.schermate.titolo') ?></h2>
      <p><?= t('comune.schermate.lede') ?></p>
    </div>

    <?php /* Scorre in orizzontale: cinque o sei telefoni affiancati non stanno in nessuno schermo. */ ?>
    <div class="shots" tabindex="0" aria-label="<?= t('comune.schermate.titolo') ?>">
      <?php foreach ($schermate as $n => $nome): ?>
        <figure class="shot">
          <img src="<?= e($img) ?>/screen-<?= e($lingua) ?>-<?= e($nome) ?>.webp"
               width="480" height="1043" loading="lazy" alt="<?= t("{$slug}.schermate." . ($n + 1)) ?>">
          <figcaption><?= t("{$slug}.schermate." . ($n + 1)) ?></figcaption>
        </figure>
      <?php endforeach; ?>
    </div>
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title"><?= t("{$slug}.problema.titolo") ?></h2>
      <p><?= t("{$slug}.problema.lede") ?></p>
    </div>

    <div class="features">
      <?php foreach ([1, 2, 3] as $n): ?>
        <div class="feature">
          <span class="feature__num" aria-hidden="true"><?= $n ?></span>
          <h3><?= t("{$slug}.problema.{$n}.titolo") ?></h3>
          <p><?= t("{$slug}.problema.{$n}.testo") ?></p>
        </div>
      <?php endforeach; ?>
    </div>
  </div>
</section>

<section class="section section--tint" id="funzioni">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title"><?= t("{$slug}.funzioni.titolo") ?></h2>
      <p><?= t("{$slug}.funzioni.lede") ?></p>
    </div>

    <div class="features">
      <?php foreach ([1, 2, 3, 4, 5, 6] as $n): ?>
        <div class="feature">
          <h3><?= t("{$slug}.funzioni.{$n}.titolo") ?></h3>
          <p><?= t("{$slug}.funzioni.{$n}.testo") ?></p>
        </div>
      <?php endforeach; ?>
    </div>
  </div>
</section>

<?php if ($promoPresenti !== []): ?>
<section class="section">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title"><?= t('comune.promo.titolo') ?></h2>
      <p><?= t('comune.promo.lede') ?></p>
    </div>

    <?php foreach ($promoPresenti as $forma => $nomi): ?>
      <div class="promo promo--<?= e((string) $forma) ?>" tabindex="0">
        <?php foreach ($nomi as $nome): ?>
          <img src="<?= e($img) ?>/promo-<?= e($lingua) ?>-<?= e($nome) ?>.webp" loading="lazy"
               alt="<?= t("{$slug}.promo.{$nome}") ?>">
        <?php endforeach; ?>
      </div>
    <?php endforeach; ?>
  </div>
</section>
<?php endif; ?>

<section class="section">
  <div class="wrap">
    <div class="section__head">
      <h2 class="title"><?= t("{$slug}.prezzi.titolo") ?></h2>
      <p><?= t("{$slug}.prezzi.lede") ?></p>
    </div>

    <div class="price">
      <div class="plan">
        <h3><?= t('comune.piano.base') ?></h3>
        <p class="plan__price"><?= t('comune.piano.gratis') ?></p>
        <ul class="ticks"><?= t("{$slug}.prezzi.base.lista") ?></ul>
      </div>

      <div class="plan plan--pro">
        <h3><?= t('comune.piano.pro') ?></h3>
        <p class="plan__price">
          <?= t("app.{$slug}.prezzo") ?> <small><?= t('comune.piano.unatantum') ?></small>
        </p>
        <ul class="ticks"><?= t("{$slug}.prezzi.pro.lista") ?></ul>
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
      <h2 class="title"><?= t("{$slug}.privacy.titolo") ?></h2>
      <p><?= t("{$slug}.privacy.testo") ?></p>
      <p style="margin-top:1rem">
        <a href="<?= e(url_per($lingua, '/legale/privacy')) ?>"><?= t('comune.privacy.link') ?></a>
      </p>
    </div>
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="cta">
      <h2><?= t('comune.bug.titolo') ?></h2>
      <p><?= t('comune.bug.testo') ?></p>
      <div>
        <a class="btn btn--primary" href="<?= e(url_per($lingua, '/contatti')) ?>#bug">
          <?= t('comune.bug.bottone') ?>
        </a>
      </div>
    </div>
  </div>
</section>

    <?php
    pagina_fine();
}

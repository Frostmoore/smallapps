<?php

/**
 * Intestazione e pie' di pagina condivisi da tutte le pagine.
 *
 * ⚑ Perche' PHP e non HTML statico: le pagine sono undici e il pie' contiene i link
 * legali obbligatori. In HTML statico il primo ritocco al menu si dimenticherebbe su tre
 * pagine, e le tre dimenticate sarebbero proprio quelle legali, che nessuno riapre mai.
 *
 * ☠ Nessuna risorsa esterna: niente Google Fonts, niente CDN, niente analytics. Non e'
 * minimalismo: caricare un font da Google significa mandare a Google l'indirizzo IP di
 * ogni visitatore, che e' un trasferimento di dati personali a un terzo senza base
 * giuridica ne consenso. Con zero terze parti il sito non ha bisogno di banner dei
 * cookie, e la cookie policy puo' dire il vero in cinque righe.
 */

declare(strict_types=1);

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/apps.php';

/**
 * Apre la pagina.
 *
 * @param string $titolo     il titolo del browser, senza il nome del sito
 * @param string $descrizione la meta description, per i motori di ricerca
 * @param string $canonical   il percorso assoluto della pagina, per il link canonico
 */
function pagina_inizio(string $titolo, string $descrizione, string $canonical = '/'): void
{
    $anno = date('Y');
    ?><!doctype html>
<html lang="it">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= e($titolo) ?> · <?= e(SITO_NOME) ?></title>
<meta name="description" content="<?= e($descrizione) ?>">
<link rel="canonical" href="<?= e(SITO_URL . $canonical) ?>">
<meta name="robots" content="index, follow">
<meta property="og:type" content="website">
<meta property="og:site_name" content="<?= e(SITO_NOME) ?>">
<meta property="og:title" content="<?= e($titolo) ?>">
<meta property="og:description" content="<?= e($descrizione) ?>">
<meta property="og:url" content="<?= e(SITO_URL . $canonical) ?>">
<meta property="og:locale" content="it_IT">
<link rel="icon" href="/assets/img/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/assets/img/trashcan.png">
<link rel="stylesheet" href="/assets/style.css?v=2">
</head>
<body>

<a class="skip" href="#contenuto">Salta al contenuto</a>

<header class="topbar">
  <div class="wrap topbar__inner">
    <a class="brand" href="/">
      <span class="brand__mark" aria-hidden="true"></span>
      <span class="brand__name">SMP<span>MicroApps</span></span>
    </a>
    <nav class="nav" aria-label="Principale">
      <a href="/#app">Le app</a>
      <a href="/contatti">Contatti</a>
      <a href="/contatti#personalizzato">Sviluppo su misura</a>
    </nav>
  </div>
</header>

<main id="contenuto">
<?php
}

/** Chiude la pagina. */
function pagina_fine(): void
{
    $anno = date('Y');
    $apps = catalogo();
    ?>
</main>

<footer class="footer">
  <div class="wrap footer__grid">

    <div class="footer__col footer__col--wide">
      <p class="footer__brand">SMP<span>MicroApps</span></p>
      <p class="footer__blurb">
        App piccole per Android, che fanno una cosa sola e la fanno bene.
        Gratis nella versione base, sbloccabili con un acquisto una tantum.
        Nessun abbonamento.
      </p>
    </div>

    <div class="footer__col">
      <h2 class="footer__title">Le app</h2>
      <ul class="footer__list">
        <?php foreach ($apps as $slug => $app): ?>
          <li>
            <?php if ($app['pubblicata']): ?>
              <a href="/<?= e($slug) ?>"><?= e($app['nome']) ?></a>
            <?php else: ?>
              <span class="footer__soon"><?= e($app['nome']) ?> <em>in arrivo</em></span>
            <?php endif; ?>
          </li>
        <?php endforeach; ?>
      </ul>
    </div>

    <div class="footer__col">
      <h2 class="footer__title">Informazioni legali</h2>
      <ul class="footer__list">
        <li><a href="/legale/note-legali">Note legali</a></li>
        <li><a href="/legale/privacy">Informativa privacy</a></li>
        <li><a href="/legale/cookie">Cookie policy</a></li>
        <li><a href="/legale/termini">Condizioni di servizio</a></li>
        <li><a href="/legale/responsabilita">Limitazione di responsabilità</a></li>
      </ul>
    </div>

    <div class="footer__col">
      <h2 class="footer__title">Contatti</h2>
      <ul class="footer__list">
        <li><a href="mailto:<?= e(AZIENDA['email']) ?>"><?= e(AZIENDA['email']) ?></a></li>
        <li><a href="mailto:<?= e(AZIENDA['pec']) ?>"><?= e(AZIENDA['pec']) ?></a> <em>(PEC)</em></li>
        <li><a href="/contatti#bug">Segnala un problema</a></li>
      </ul>
    </div>

  </div>

  <div class="wrap footer__legal">
    <p>
      <strong><?= e(AZIENDA['denominazione']) ?></strong> ·
      <?= e(AZIENDA['indirizzo']) ?>, <?= e(AZIENDA['cap']) ?> <?= e(AZIENDA['citta']) ?>
      (<?= e(AZIENDA['provincia']) ?>) ·
      P. IVA e C.F. <?= e(AZIENDA['piva']) ?>
      <?php if (AZIENDA['rea'] !== ''): ?> · REA <?= e(AZIENDA['rea']) ?><?php endif; ?>
    </p>
    <p>© <?= e((string) $anno) ?> <?= e(AZIENDA['denominazione']) ?>. Tutti i diritti riservati.
      Android e Google Play sono marchi di Google LLC.</p>
  </div>
</footer>

</body>
</html>
<?php
}

/**
 * Il riquadro che apre ogni pagina legale: titolo, data e avvertenza sulla versione.
 *
 * La data di ultimo aggiornamento non e' un vezzo: un'informativa privacy senza data non
 * permette all'interessato di sapere quale versione ha accettato, ed e' la prima cosa che
 * si guarda in caso di contestazione.
 */
function intestazione_legale(string $titolo, string $aggiornata, string $sommario): void
{
    ?>
    <section class="hero hero--slim">
      <div class="wrap">
        <p class="eyebrow">Informazioni legali</p>
        <h1 class="display display--s"><?= e($titolo) ?></h1>
        <p class="lede"><?= e($sommario) ?></p>
        <p class="meta">Ultimo aggiornamento: <?= e($aggiornata) ?></p>
      </div>
    </section>
    <?php
}

<?php

/**
 * Intestazione e pie' di pagina condivisi da tutte le pagine.
 *
 * ⚑ Perche' PHP e non HTML statico: le pagine sono undici, in due lingue, e il pie'
 * contiene i link legali obbligatori. In HTML statico il primo ritocco al menu si
 * dimenticherebbe su tre pagine, e le tre dimenticate sarebbero proprio quelle legali, che
 * nessuno riapre mai.
 *
 * ☠ Nessuna risorsa esterna: niente Google Fonts, niente CDN, niente analytics. Non e'
 * minimalismo: caricare un font da Google significa mandare a Google l'indirizzo IP di ogni
 * visitatore, che e' un trasferimento di dati personali a un terzo senza base giuridica ne
 * consenso. Con zero terze parti il sito non ha bisogno di banner dei cookie, e la cookie
 * policy puo' dire il vero in poche righe.
 */

declare(strict_types=1);

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/i18n.php';
require_once __DIR__ . '/apps.php';

// ☠ Va eseguito **prima di qualunque output**, perche' manda intestazioni e puo' redirigere.
// Sta qui, a livello di file, e non dentro pagina_inizio(): `contatti.php` elabora la POST
// prima di stampare, e con la chiamata dentro pagina_inizio() il redirect di lingua
// arriverebbe dopo che il modulo ha gia' scritto sull'archivio.
applica_lingua();

/**
 * I segnaposto disponibili nei testi tradotti: i dati dell'azienda piu' gli indirizzi
 * interni, gia' nella lingua corrente.
 *
 * ⚑ Gli URL sono parametri e non stringhe scritte nei dizionari: un link scritto a mano
 * dentro il testo inglese punterebbe alla pagina italiana, e il lettore si troverebbe
 * catapultato in un'altra lingua a meta' di un'informativa.
 *
 * @return array<string, string>
 */
function parametri_pagina(): array
{
    return parametri_azienda() + [
        'url_privacy'        => url_per(lingua_corrente(), '/legale/privacy'),
        'url_cookie'         => url_per(lingua_corrente(), '/legale/cookie'),
        'url_termini'        => url_per(lingua_corrente(), '/legale/termini'),
        'url_responsabilita' => url_per(lingua_corrente(), '/legale/responsabilita'),
        'url_note'           => url_per(lingua_corrente(), '/legale/note-legali'),
        'url_contatti'       => url_per(lingua_corrente(), '/contatti'),
        // Nelle pagine legali inglesi si rimanda al testo che fa fede, cioe' l'italiano.
        'url_it'             => url_per('it'),
    ];
}

/**
 * Apre la pagina.
 *
 * @param string $chiaveTitolo      chiave del titolo del browser, senza il nome del sito
 * @param string $chiaveDescrizione chiave della meta description
 * @param string $canonical         il percorso **neutro**, senza prefisso di lingua
 */
function pagina_inizio(string $chiaveTitolo, string $chiaveDescrizione, string $canonical = '/'): void
{
    $lingua = lingua_corrente();
    $titolo = t($chiaveTitolo);
    $descrizione = t($chiaveDescrizione);
    ?><!doctype html>
<html lang="<?= e($lingua) ?>">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= e($titolo) ?> · <?= e(SITO_NOME) ?></title>
<meta name="description" content="<?= e($descrizione) ?>">

<?php
// Il canonico punta alla versione **di questa lingua**, e gli alternate dichiarano l'altra.
// ⚑ `x-default` indica ai motori quale servire a chi non corrisponde a nessuna lingua
// dichiarata: e' l'italiano, che e' anche la radice del sito.
?>
<link rel="canonical" href="<?= e(SITO_URL . url_per($lingua, $canonical)) ?>">
<link rel="alternate" hreflang="it" href="<?= e(SITO_URL . url_per('it', $canonical)) ?>">
<link rel="alternate" hreflang="en" href="<?= e(SITO_URL . url_per('en', $canonical)) ?>">
<link rel="alternate" hreflang="x-default" href="<?= e(SITO_URL . url_per('it', $canonical)) ?>">

<meta name="robots" content="index, follow">
<meta property="og:type" content="website">
<meta property="og:site_name" content="<?= e(SITO_NOME) ?>">
<meta property="og:title" content="<?= e($titolo) ?>">
<meta property="og:description" content="<?= e($descrizione) ?>">
<meta property="og:url" content="<?= e(SITO_URL . url_per($lingua, $canonical)) ?>">
<meta property="og:locale" content="<?= $lingua === 'it' ? 'it_IT' : 'en_GB' ?>">
<link rel="icon" href="/assets/img/favicon-32.png" sizes="32x32" type="image/png">
<link rel="icon" href="/assets/img/favicon-192.png" sizes="192x192" type="image/png">
<link rel="apple-touch-icon" href="/assets/img/apple-touch-icon.png">
<link rel="stylesheet" href="/assets/style.css?v=4">

<?php
// ⚑ Uno script di due righe, inline e nel `<head>`, che marca il documento come "con
// JavaScript". Serve a una cosa sola: il menu a panino esiste **solo** se il browser puo'
// aprirlo. Senza questa riga bisognerebbe nasconderlo con JavaScript dopo il primo
// disegno, e su una connessione lenta si vedrebbe la navigazione comparire e sparire.
//
// ☠ Va nel `<head>` e non in fondo: piu' avanti e il browser avrebbe gia' disegnato la
// pagina in versione senza JavaScript, con lo stesso sfarfallio che si voleva evitare.
?>
<script>document.documentElement.className += ' js';</script>
<script src="/assets/menu.js?v=1" defer></script>
</head>
<body>

<a class="skip" href="#contenuto"><?= t('comune.salta') ?></a>

<header class="topbar">
  <div class="wrap topbar__inner">
    <a class="brand" href="<?= e(url_per($lingua, '/')) ?>">
      <img class="brand__mark" src="/assets/img/logo.png" alt="" width="30" height="30">
      <span class="brand__name">SMP<span>MicroApps</span></span>
    </a>

    <?php
    // Il bottone del menu a panino. Sta **prima** della navigazione nel documento perche'
    // e' quello che la apre: chi naviga da tastiera o con uno screen reader lo incontra
    // prima di cio' che controlla, non dopo.
    //
    // `hidden` di partenza: senza JavaScript resta nascosto e la navigazione si vede per
    // intero, mandando a capo le voci come faceva prima. Una comodita' non deve diventare
    // un requisito.
    ?>
    <button class="panino" type="button" id="panino"
            aria-expanded="false" aria-controls="menu-principale"
            aria-label="<?= e(t('nav.apri')) ?>"
            data-apri="<?= e(t('nav.apri')) ?>"
            data-chiudi="<?= e(t('nav.chiudi')) ?>" hidden>
      <span class="panino__righe" aria-hidden="true"></span>
    </button>

    <nav class="nav" id="menu-principale" aria-label="<?= e(t('nav.principale')) ?>">
      <ul class="nav__lista">
        <?php
        // "Le app" con il suo sottomenu. Sul desktop si apre passandoci sopra o entrandoci
        // da tastiera; dentro il panino resta aperto, perche' con una voce sola costringere
        // a un tocco in piu' sarebbe solo fastidioso.
        $pubblicate = array_filter(catalogo(), static fn (array $a): bool => $a['pubblicata']);
        ?>
        <li class="nav__voce nav__voce--conSottomenu">
          <a href="<?= e(url_per($lingua, '/')) ?>#app"><?= t('nav.app') ?></a>
          <?php if ($pubblicate !== []): ?>
            <ul class="sottomenu">
              <?php foreach ($pubblicate as $slug => $app): ?>
                <li>
                  <a href="<?= e(url_per($lingua, '/' . $slug)) ?>">
                    <?php if ($app['logo'] !== null): ?>
                      <img src="<?= e($app['logo']) ?>" alt="" width="22" height="22">
                    <?php endif; ?>
                    <span><?= e($app['nome']) ?></span>
                  </a>
                </li>
              <?php endforeach; ?>
            </ul>
          <?php endif; ?>
        </li>

        <li class="nav__voce">
          <a href="<?= e(url_per($lingua, '/contatti')) ?>"><?= t('nav.contatti') ?></a>
        </li>
        <li class="nav__voce">
          <a href="<?= e(url_per($lingua, '/contatti')) ?>#personalizzato"><?= t('nav.su_misura') ?></a>
        </li>
        <li class="nav__voce nav__voce--lingue"><?php selettore_lingua(); ?></li>
      </ul>
    </nav>
  </div>
</header>

<main id="contenuto">
<?php
}

/**
 * Le due bandierine.
 *
 * ⚑ Si mostrano **entrambe**, con quella corrente marcata, invece della sola bandiera
 * dell'altra lingua. Mostrarne una sola e' ambiguo: nessuno sa se quella bandiera dice "stai
 * leggendo in italiano" o "clicca per l'italiano", e chi sbaglia a interpretarla si convince
 * che il sito sia gia' nella lingua che voleva.
 *
 * ☠ Il link porta alla **stessa pagina** nell'altra lingua, non alla home: sbattere alla
 * home chi cambia lingua a meta' di un'informativa lo costringe a ritrovarsi il punto.
 *
 * ☠ `?l=` serve solo a chi ha i cookie bloccati: sopprime il rilevamento automatico per
 * quella richiesta. Senza, un browser in inglese e senza cookie tornerebbe all'inglese a
 * ogni clic sulla bandiera italiana, e la bandiera sembrerebbe rotta.
 */
function selettore_lingua(): void
{
    $corrente = lingua_corrente();
    $bandiere = [
        'it' => ['file' => 'flag-it.svg', 'etichetta' => t('comune.in_italiano'), 'sigla' => 'IT'],
        'en' => ['file' => 'flag-gb.svg', 'etichetta' => t('comune.in_inglese'), 'sigla' => 'EN'],
    ];
    ?>
    <span class="lingue" role="group" aria-label="<?= e(t('comune.scegli_lingua')) ?>">
      <?php foreach ($bandiere as $codice => $b): ?>
        <?php if ($codice === $corrente): ?>
          <span class="lingue__voce lingue__voce--attiva" aria-current="true">
            <img src="/assets/img/<?= e($b['file']) ?>" alt="" width="21" height="14">
            <span class="lingue__sigla"><?= e($b['sigla']) ?></span>
          </span>
        <?php else: ?>
          <a class="lingue__voce"
             href="<?= e(url_per($codice) . '?l=' . $codice) ?>"
             lang="<?= e($codice) ?>"
             title="<?= e($b['etichetta']) ?>">
            <img src="/assets/img/<?= e($b['file']) ?>" alt="<?= e($b['etichetta']) ?>" width="21" height="14">
            <span class="lingue__sigla"><?= e($b['sigla']) ?></span>
          </a>
        <?php endif; ?>
      <?php endforeach; ?>
    </span>
    <?php
}

/** Chiude la pagina. */
function pagina_fine(): void
{
    $anno = date('Y');
    $lingua = lingua_corrente();
    $apps = catalogo();
    ?>
</main>

<footer class="footer">
  <div class="wrap footer__grid">

    <div class="footer__col footer__col--wide">
      <p class="footer__brand">SMP<span>MicroApps</span></p>
      <p class="footer__blurb"><?= t('footer.blurb') ?></p>
    </div>

    <div class="footer__col">
      <h2 class="footer__title"><?= t('footer.app') ?></h2>
      <ul class="footer__list">
        <?php foreach ($apps as $slug => $app): ?>
          <li>
            <?php if ($app['pubblicata']): ?>
              <a href="<?= e(url_per($lingua, '/' . $slug)) ?>"><?= e($app['nome']) ?></a>
            <?php else: ?>
              <span class="footer__soon"><?= e($app['nome']) ?> <em><?= t('comune.in_arrivo') ?></em></span>
            <?php endif; ?>
          </li>
        <?php endforeach; ?>
      </ul>
    </div>

    <div class="footer__col">
      <h2 class="footer__title"><?= t('footer.legale') ?></h2>
      <ul class="footer__list">
        <li><a href="<?= e(url_per($lingua, '/legale/note-legali')) ?>"><?= t('footer.note') ?></a></li>
        <li><a href="<?= e(url_per($lingua, '/legale/privacy')) ?>"><?= t('footer.privacy') ?></a></li>
        <li><a href="<?= e(url_per($lingua, '/legale/cookie')) ?>"><?= t('footer.cookie') ?></a></li>
        <li><a href="<?= e(url_per($lingua, '/legale/termini')) ?>"><?= t('footer.termini') ?></a></li>
        <li><a href="<?= e(url_per($lingua, '/legale/responsabilita')) ?>"><?= t('footer.responsabilita') ?></a></li>
      </ul>
    </div>

    <div class="footer__col">
      <h2 class="footer__title"><?= t('footer.contatti') ?></h2>
      <ul class="footer__list">
        <li><a href="mailto:<?= e(AZIENDA['email']) ?>"><?= e(AZIENDA['email']) ?></a></li>
        <li><a href="mailto:<?= e(AZIENDA['pec']) ?>"><?= e(AZIENDA['pec']) ?></a>
          <em><?= t('contatti.recapiti.pec') ?></em></li>
        <li><a href="<?= e(url_per($lingua, '/contatti')) ?>#bug"><?= t('footer.segnala') ?></a></li>
      </ul>
    </div>

  </div>

  <div class="wrap footer__legal">
    <p>
      <strong><?= e(AZIENDA['denominazione']) ?></strong> ·
      <?= e(AZIENDA['indirizzo']) ?>, <?= e(AZIENDA['cap']) ?> <?= e(AZIENDA['citta']) ?>
      (<?= e(AZIENDA['provincia']) ?>) ·
      P. IVA / VAT <?= e(AZIENDA['piva']) ?>
      <?php if (AZIENDA['rea'] !== ''): ?> · REA <?= e(AZIENDA['rea']) ?><?php endif; ?>
    </p>
    <p>© <?= e((string) $anno) ?> <?= e(AZIENDA['denominazione']) ?>. <?= t('footer.diritti') ?></p>
  </div>
</footer>

</body>
</html>
<?php
}

/**
 * Il riquadro che apre ogni pagina legale: titolo, data e sommario.
 *
 * La data di ultimo aggiornamento non e' un vezzo: un'informativa privacy senza data non
 * permette all'interessato di sapere quale versione ha accettato, ed e' la prima cosa che si
 * guarda in caso di contestazione.
 */
function intestazione_legale(string $chiaveTitolo, string $chiaveSommario): void
{
    ?>
    <section class="hero hero--slim">
      <div class="wrap">
        <p class="eyebrow"><?= t('legale.occhiello') ?></p>
        <h1 class="display display--s"><?= t($chiaveTitolo) ?></h1>
        <p class="lede"><?= t($chiaveSommario) ?></p>
        <p class="meta"><?= t('comune.aggiornato', ['data' => t('comune.data_legale')]) ?></p>
      </div>
    </section>
    <?php
}

/**
 * Stampa una pagina legale intera: intestazione + corpo tradotto.
 *
 * ⚑ Cinque pagine con la stessa struttura, quindi una funzione sola. Ogni file sotto
 * `public/legale/` si riduce a due righe, e una modifica alla struttura si fa una volta.
 */
function pagina_legale(string $nome): void
{
    pagina_inizio(
        "legale.{$nome}.titolo",
        "legale.{$nome}.descrizione",
        "/legale/{$nome}"
    );
    intestazione_legale("legale.{$nome}.titolo", "legale.{$nome}.sommario");
    echo '<div class="wrap prose">', t("legale.{$nome}.corpo", parametri_pagina()), '</div>';
    pagina_fine();
}

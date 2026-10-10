<?php

/**
 * La vetrina di Scorte Calore. La struttura sta in `src/pagina_app.php`, i testi nei
 * dizionari sotto `scorte-calore.*`, le immagini in `assets/img/scorte-calore/`.
 *
 * Gli screenshot sono gli iOS della lingua (store/screenshots/ios/<l>/ dell'app): home-pro,
 * aggiornamento, storico, costi, paywall-revisione. La home senza Pro non c'e': e' identica
 * alla home-pro tranne l'etichetta PRO, e sarebbe un doppione.
 */

declare(strict_types=1);

require_once __DIR__ . '/../src/pagina_app.php';

pagina_app(
    'scorte-calore',
    ['01-home', '02-aggiorna', '03-storico', '04-costi', '05-pro'],
    // Le promozionali, quando il proprietario le avra' fatte: per forma, nomi `NN-nome`, file
    // `promo-<lingua>-NN-nome.webp` e chiave `scorte-calore.promo.NN-nome` per l'alt.
    // Es.: 'quadre' => ['01-widget', '02-gpl', '03-calendario'].
    []
);

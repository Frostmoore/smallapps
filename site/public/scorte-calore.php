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
    // Le promozionali fatte dal proprietario con ChatGPT (2026-10-10): testo italiano dentro
    // l'immagine, quindi si vedono solo sulla pagina italiana. La n. 1 ripete il titolo: fuori.
    [
        'quadre' => ['02-riordina', '03-widget', '04-gpl'],
        'larghe' => ['05-misure', '06-consumo', '07-nessun-account'],
        'verticali' => ['08-costi', '09-fonti', '10-mai-piu'],
    ]
);

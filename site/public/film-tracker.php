<?php

/**
 * La vetrina di Film Tracker. La struttura sta in `src/pagina_app.php`, i testi nei
 * dizionari sotto `film-tracker.*`, le immagini in `assets/img/film-tracker/`.
 *
 * ⚑ La pagina usa lo stile del sito: la grafica scura «C · Provino» dell'app si vede nella
 * testata e negli screenshot, non ricolorando la pagina.
 *
 * Gli screenshot sono gli iOS della lingua: home, dettaglio, provino, qr, statistiche,
 * paywall-revisione. Manca `foto.png` (una foto a tutto schermo: non racconta l'app).
 */

declare(strict_types=1);

require_once __DIR__ . '/../src/pagina_app.php';

pagina_app(
    'film-tracker',
    ['01-rullini', '02-rullino', '03-archivio', '04-etichetta', '05-statistiche', '06-pro'],
    // Le promozionali, quando ci saranno: vedi scorte-calore.php.
    []
);

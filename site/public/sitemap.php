<?php

/**
 * La sitemap, generata dal catalogo, con le due lingue e gli hreflang.
 *
 * ⚑ Generata e non scritta a mano: una app aggiunta in `src/apps.php` compare in home e
 * nella sitemap nello stesso istante. Con un XML statico, la prima app nuova comparirebbe
 * in home e non qui, e nessuno se ne accorgerebbe finche' qualcuno non va a cercare perche'
 * quella pagina non e' su Google.
 *
 * ⚑ Ogni indirizzo compare una volta per lingua, e **ciascuna voce dichiara entrambe le
 * versioni** con `xhtml:link`. E' quello che i motori si aspettano per capire che le due
 * pagine sono la stessa cosa in lingue diverse invece che contenuto duplicato.
 */

declare(strict_types=1);

require_once __DIR__ . '/../src/config.php';
require_once __DIR__ . '/../src/i18n.php';
require_once __DIR__ . '/../src/apps.php';

header('Content-Type: application/xml; charset=utf-8');

$oggi = date('Y-m-d');

/** @var list<array{loc: string, priority: string}> $pagine */
$pagine = [
    ['loc' => '/', 'priority' => '1.0'],
    ['loc' => '/contatti', 'priority' => '0.8'],
];

foreach (catalogo() as $slug => $app) {
    // Le app non pubblicate non hanno una pagina: metterle in sitemap darebbe un 404.
    if ($app['pubblicata']) {
        $pagine[] = ['loc' => '/' . $slug, 'priority' => '0.9'];
    }
}

foreach (['note-legali', 'privacy', 'cookie', 'termini', 'responsabilita'] as $legale) {
    $pagine[] = ['loc' => '/legale/' . $legale, 'priority' => '0.3'];
}

echo '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
<?php foreach ($pagine as $pagina): ?>
<?php foreach (LINGUE as $lingua): ?>
  <url>
    <loc><?= e(SITO_URL . url_per($lingua, $pagina['loc'])) ?></loc>
    <xhtml:link rel="alternate" hreflang="it" href="<?= e(SITO_URL . url_per('it', $pagina['loc'])) ?>"/>
    <xhtml:link rel="alternate" hreflang="en" href="<?= e(SITO_URL . url_per('en', $pagina['loc'])) ?>"/>
    <xhtml:link rel="alternate" hreflang="x-default" href="<?= e(SITO_URL . url_per('it', $pagina['loc'])) ?>"/>
    <lastmod><?= e($oggi) ?></lastmod>
    <priority><?= e($pagina['priority']) ?></priority>
  </url>
<?php endforeach; ?>
<?php endforeach; ?>
</urlset>

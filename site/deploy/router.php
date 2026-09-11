<?php

/**
 * Il router del server di sviluppo di PHP. NON viene usato in produzione.
 *
 * ⚑ Serve a riprodurre in locale la regola `try_files $uri $uri.php $uri/` di nginx: senza,
 * in locale funzionerebbe `/trashcan.php` e sul server `/trashcan`, e ci si accorgerebbe
 * della differenza solo dopo il caricamento, con tutti i link interni rotti.
 *
 * Si lancia dalla cartella `site/`:
 *
 *     php -S 127.0.0.1:8099 -t public deploy/router.php
 */

declare(strict_types=1);

$percorso = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?: '/';
$radice = __DIR__ . '/../public';

// /sitemap.xml e' generato da sitemap.php, come nel vhost.
if ($percorso === '/sitemap.xml') {
    require $radice . '/sitemap.php';
    return true;
}

$file = $radice . $percorso;

// Un file che esiste davvero (css, immagini) lo serve il server integrato.
if ($percorso !== '/' && is_file($file)) {
    return false;
}

foreach ([$file . '.php', rtrim($file, '/') . '/index.php'] as $candidato) {
    if (is_file($candidato)) {
        require $candidato;
        return true;
    }
}

http_response_code(404);
echo '404';
return true;

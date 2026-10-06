<?php

/**
 * Il catalogo delle microapp: l'unica fonte di verita' della vetrina.
 *
 * ⚑ **Ogni microapp del monorepo ha una card in home.** Anche quelle non ancora
 * pubblicate: restano in griglia, in grigio, con l'etichetta "In arrivo" e senza link.
 * E' voluto. Una griglia che mostra solo l'app pronta dice "ne ho fatta una"; una che
 * mostra le quattro dice "questo e' un catalogo che cresce", e prepara il lancio
 * successivo senza promettere date.
 *
 * ⚑ Perche' un array e non una pagina scritta a mano: la card in home, la pagina di
 * dettaglio, la sitemap e i dati strutturati leggono tutti da qui. Scrivendo la griglia a
 * mano, la prima app aggiunta comparirebbe in home e non nella sitemap, o viceversa, e
 * nessuno se ne accorgerebbe per mesi.
 *
 * Quando si aggiunge una app al monorepo si aggiunge una voce qui, nello stesso giro.
 *
 * ☠ Qui dentro non c'e' **nessun testo visibile**: nome a parte, claim, sommario e prezzo
 * stanno nei dizionari sotto le chiavi `app.<slug>.*`, perche' vanno tradotti. Rimetterli
 * qui significherebbe un catalogo che resta italiano anche sulle pagine inglesi, senza che
 * niente lo segnali.
 */

declare(strict_types=1);

/**
 * @return array<string, array<string, mixed>> indicizzato per slug, nell'ordine di
 *                                             presentazione in home.
 */
function catalogo(): array
{
    return [
        'trashcan' => [
            'nome'      => 'TrashCan',
            'accento'   => '#2E7D5B',
            'logo'      => '/assets/img/trashcan.png',
            // Pubblicata: la card e' cliccabile e porta alla sua pagina.
            'pubblicata' => true,
            // L'indirizzo su Play e' deterministico: e' costruito sul nome del pacchetto,
            // che non cambia piu' dopo il primo caricamento. Diventa un bottone vero
            // quando `suPlay` passa a true.
            'packageId' => 'com.smp.trashcan',
            'suPlay'    => false,
            // L'id Apple e' quello di App Store Connect, assegnato alla creazione della
            // scheda e mai piu' cambiato. Diventa un bottone quando `suAppStore` passa a true.
            'appStoreId' => '6818986320',
            'suAppStore' => false,
        ],
        'full-freezer' => [
            'nome'      => 'Full Freezer',
            'accento'   => '#2C5F9E',
            'logo'      => null,
            'pubblicata' => false,
            'packageId' => 'com.smp.fullfreezer',
            'suPlay'    => false,
        ],
        'scorte-calore' => [
            'nome'      => 'Scorte Calore',
            'accento'   => '#A6503A',
            'logo'      => null,
            'pubblicata' => false,
            'packageId' => 'com.smp.scortecalore',
            'suPlay'    => false,
        ],
        'film-tracker' => [
            'nome'      => 'Film Tracker',
            'accento'   => '#4A5560',
            'logo'      => null,
            'pubblicata' => false,
            'packageId' => 'com.smp.filmtracker',
            'suPlay'    => false,
        ],
    ];
}

/** Una sola app, o null se lo slug non esiste. */
function app_per_slug(string $slug): ?array
{
    return catalogo()[$slug] ?? null;
}

/** L'indirizzo della scheda su App Store, o null finche' Apple non l'ha pubblicata. */
function link_app_store(array $app): ?string
{
    return ($app['suAppStore'] ?? false) && isset($app['appStoreId'])
        ? 'https://apps.apple.com/app/id' . $app['appStoreId']
        : null;
}

/** L'indirizzo della scheda su Google Play, o null finche' l'app non e' pubblicata. */
function link_play(array $app): ?string
{
    return ($app['suPlay'] ?? false)
        ? 'https://play.google.com/store/apps/details?id=' . $app['packageId']
        : null;
}

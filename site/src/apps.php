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
            'claim'     => 'Stasera cosa si butta?',
            'sommario'  => 'Il calendario della raccolta differenziata del tuo Comune, '
                         . 'con il promemoria la sera prima. Niente più bidone dimenticato '
                         . 'sul pianerottolo.',
            'accento'   => '#2E7D5B',
            'logo'      => '/assets/img/trashcan.png',
            // Pubblicata: la card e' cliccabile e porta alla sua pagina.
            'pubblicata' => true,
            // L'indirizzo su Play e' deterministico: e' costruito sul nome del pacchetto,
            // che non cambia piu' dopo il primo caricamento. Diventa un bottone vero
            // quando `suPlay` passa a true.
            'packageId' => 'com.smp.trashcan',
            'suPlay'    => false,
            'prezzoPro' => '2,99 €',
        ],
        'full-freezer' => [
            'nome'      => 'Full Freezer',
            'claim'     => 'Cosa c\'è nel congelatore, e da quanto.',
            'sommario'  => 'L\'inventario del freezer ordinato per anzianità, così si '
                         . 'consuma prima quello che aspetta da più tempo.',
            'accento'   => '#2C5F9E',
            'logo'      => null,
            'pubblicata' => false,
            'packageId' => 'com.smp.fullfreezer',
            'suPlay'    => false,
            'prezzoPro' => null,
        ],
        'scorte-calore' => [
            'nome'      => 'Scorte Calore',
            'claim'     => 'Quanto pellet ti resta davvero.',
            'sommario'  => 'Consumo medio, autonomia residua e data in cui conviene '
                         . 'riordinare. Per pellet, gasolio, GPL e legna.',
            'accento'   => '#A6503A',
            'logo'      => null,
            'pubblicata' => false,
            'packageId' => 'com.smp.scortecalore',
            'suPlay'    => false,
            'prezzoPro' => null,
        ],
        'film-tracker' => [
            'nome'      => 'Film Tracker',
            'claim'     => 'Il diario dei tuoi rullini.',
            'sommario'  => 'Pellicole, scatti, tempi e diaframmi. Per chi fotografa in '
                         . 'analogico e non vuole perdere le note dello sviluppo.',
            'accento'   => '#4A5560',
            'logo'      => null,
            'pubblicata' => false,
            'packageId' => 'com.smp.filmtracker',
            'suPlay'    => false,
            'prezzoPro' => null,
        ],
    ];
}

/** Una sola app, o null se lo slug non esiste. */
function app_per_slug(string $slug): ?array
{
    return catalogo()[$slug] ?? null;
}

/** L'indirizzo della scheda su Google Play, o null finche' l'app non e' pubblicata. */
function link_play(array $app): ?string
{
    return ($app['suPlay'] ?? false)
        ? 'https://play.google.com/store/apps/details?id=' . $app['packageId']
        : null;
}

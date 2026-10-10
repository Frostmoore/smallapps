<?php

/**
 * Il link «scarica» di un'app: manda il visitatore allo store del suo sistema.
 *
 *     https://smpmicroapps.it/scarica/<slug>
 *
 * ⚑ Richiesta del proprietario (2026-10-10): un link unico per app da usare nelle sponsorizzate
 *   di Facebook, che porti chi ci tocca direttamente sul suo store. iPhone, iPad e Mac vanno
 *   all'App Store; tutti gli altri a Google Play.
 *
 * ☠ **iPadOS si presenta come un Mac.** Safari su iPad, per avere i siti «da computer», manda lo
 *   stesso user agent di macOS (`Macintosh; Intel Mac OS X`). Per questo `Macintosh` vale come
 *   Apple: e' il proprietario stesso a volere anche macOS sull'App Store, quindi i due casi
 *   coincidono e non serve distinguerli.
 *
 * ☠ **Lo store giusto puo' non avere l'app.** Scorte Calore e Film Tracker sono solo su App Store:
 *   un visitatore Android mandato a Google Play troverebbe «articolo non trovato». In quel caso,
 *   e se l'app non e' su nessuno store, si va alla pagina dell'app sul sito (che dice «Su Android
 *   in arrivo»), mai allo store dell'altro sistema, dove non potrebbe installarla.
 *
 * ⚑ Niente contatori, niente cookie, niente parametri passati avanti: il sito non traccia nessuno
 *   (regola «zero terze parti»). Le statistiche della campagna le da' Facebook dal suo lato.
 */

declare(strict_types=1);

require_once __DIR__ . '/layout.php';

/** `true` se lo user agent e' di un dispositivo Apple: iPhone, iPad, iPod o Mac. */
function e_apple(string $userAgent): bool
{
    // ☠ Android non dice mai «Macintosh» ne' «iPhone», ma alcuni browser Android in modalita'
    //   desktop si spacciano per Linux: il controllo su Apple e' quindi quello affidabile.
    return (bool) preg_match('/iPhone|iPad|iPod|Macintosh|Mac OS X/i', $userAgent);
}

/** Dove mandare il visitatore: l'indirizzo dello store o della pagina dell'app sul sito. */
function destinazione_scarica(string $slug, string $userAgent, string $lingua): string
{
    $app = app_per_slug($slug);
    if ($app === null) {
        return url_per($lingua, '/');
    }

    $store = e_apple($userAgent) ? link_app_store($app) : link_play($app);
    if ($store !== null) {
        return $store;
    }

    // Lo store del suo sistema non ha l'app: la pagina dell'app se esiste, altrimenti il
    // catalogo in home (le app «In arrivo» non hanno una pagina propria).
    return $app['pubblicata'] ? url_per($lingua, '/' . $slug) : url_per($lingua, '/') . '#app';
}

/** Manda il redirect e termina. Chiamata dai file `public/scarica/<slug>.php`. */
function scarica(string $slug): never
{
    $destinazione = destinazione_scarica(
        $slug,
        (string) ($_SERVER['HTTP_USER_AGENT'] ?? ''),
        lingua_corrente(),
    );

    // ⚑ 302 e non 301: la destinazione cambia con il dispositivo e con il tempo (quando un'app
    //   arriva su Play). Un 301 lo memorizzerebbero browser e anteprime dei link di Facebook.
    header('Location: ' . $destinazione, true, 302);
    header('Cache-Control: no-store, private');
    header('Vary: User-Agent');
    exit;
}

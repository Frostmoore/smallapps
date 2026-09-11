<?php

/**
 * Le due lingue del sito: italiano alla radice, inglese sotto `/en`.
 *
 * ⚑ **Perche' l'italiano resta alla radice e non sotto `/it`.** Il sito era gia' online e
 * indicizzato con gli indirizzi senza prefisso. Spostarli tutti sotto `/it` avrebbe
 * richiesto una catena di redirect permanenti per non perdere quel poco di posizionamento
 * e per non rompere i link gia' condivisi, in cambio di nient'altro che simmetria.
 *
 * ⚑ **Perche' la lingua si legge da `REQUEST_URI` e non da una variabile di nginx.**
 * nginx riscrive `/en/trashcan` in `/trashcan` con una `rewrite ... last`, ma
 * `REQUEST_URI` conserva sempre **l'indirizzo originale** della richiesta. Leggerlo da li'
 * significa che il meccanismo funziona identico sotto nginx e sotto `php -S`, senza
 * parametri FastCGI da tenere allineati fra due file di configurazione diversi.
 */

declare(strict_types=1);

require_once __DIR__ . '/config.php';

/** Le lingue disponibili. La prima e' quella predefinita, servita alla radice. */
const LINGUE = ['it', 'en'];

const LINGUA_DEFAULT = 'it';

/**
 * Il cookie che ricorda la lingua scelta.
 *
 * ⚑ E' un cookie **tecnico di preferenza**: memorizza una scelta dell'utente e non traccia
 * niente. Le Linee guida del Garante del 10 giugno 2021 lo escludono espressamente
 * dall'obbligo di consenso preventivo, quindi il sito continua a non avere bisogno di
 * nessun banner. Sta comunque scritto nella cookie policy, perche' un cookie non
 * dichiarato e' una violazione anche quando e' esente dal consenso.
 */
const COOKIE_LINGUA = 'ma_lang';

/** Un anno: la scelta della lingua non e' una cosa che si rifa' a ogni visita. */
const COOKIE_LINGUA_DURATA = 31536000;

/** Il percorso richiesto, senza query. Sempre con la barra iniziale. */
function percorso_richiesto(): string
{
    $uri = $_SERVER['REQUEST_URI'] ?? '/';
    $percorso = parse_url($uri, PHP_URL_PATH);
    return is_string($percorso) && $percorso !== '' ? $percorso : '/';
}

/**
 * La lingua della pagina che si sta servendo, dedotta dall'indirizzo.
 *
 * ☠ Il confronto e' su `/en` esatto o `/en/`, non su un semplice `str_starts_with('/en')`:
 * quest'ultimo prenderebbe anche un ipotetico `/energia` e servirebbe il dizionario
 * inglese a una pagina italiana.
 */
function lingua_corrente(): string
{
    $percorso = percorso_richiesto();
    return ($percorso === '/en' || str_starts_with($percorso, '/en/')) ? 'en' : LINGUA_DEFAULT;
}

/**
 * Il percorso senza il prefisso di lingua: `/en/trashcan` e `/trashcan` danno entrambi
 * `/trashcan`. E' la chiave con cui si costruiscono il link canonico, gli `hreflang` e i
 * due link della bandierina.
 */
function percorso_neutro(): string
{
    $percorso = percorso_richiesto();
    if ($percorso === '/en') {
        return '/';
    }
    if (str_starts_with($percorso, '/en/')) {
        $resto = substr($percorso, 3);
        return $resto === '' ? '/' : $resto;
    }
    return $percorso;
}

/** L'indirizzo di [$percorso] in [$lingua]. Senza argomento usa la pagina corrente. */
function url_per(string $lingua, ?string $percorso = null): string
{
    $percorso = $percorso ?? percorso_neutro();
    if ($lingua === LINGUA_DEFAULT) {
        return $percorso;
    }
    return $percorso === '/' ? '/en/' : '/en' . $percorso;
}

/**
 * La lingua che il browser preferisce fra quelle disponibili.
 *
 * Tre casi, e sono diversi apposta:
 *
 * 1. **Nessuna intestazione, o solo `*`.** Si resta sull'italiano. Non e' indifferenza: i
 *    crawler dei motori di ricerca spesso non mandano `Accept-Language` affatto, e
 *    rimbalzarli sulla versione inglese farebbe apparire la home italiana come una pagina
 *    che redirige sempre. `*` vuol dire letteralmente "una vale l'altra", quindi vale lo
 *    stesso ragionamento.
 * 2. **L'intestazione nomina l'italiano o l'inglese.** Vince quello con il peso maggiore.
 * 3. ☠ **L'intestazione c'e' ma non nomina nessuna delle due**, per esempio `fr-FR`. Si
 *    va all'**inglese**, non all'italiano: chi ha il browser in francese non legge
 *    l'italiano piu' di quanto legga l'inglese, ma di inglese ne mastica di piu'. Mandarlo
 *    sulla versione italiana perche' e' quella predefinita significa dargli una pagina che
 *    non capisce.
 *
 * @param ?string $header il valore grezzo di `Accept-Language`
 */
function lingua_preferita(?string $header): string
{
    if ($header === null || trim($header) === '') {
        return LINGUA_DEFAULT;
    }

    $qualita = ['it' => null, 'en' => null];
    $soloJolly = true;

    foreach (explode(',', $header) as $pezzo) {
        $parti = explode(';', trim($pezzo));
        $tag = strtolower(trim($parti[0]));
        if ($tag === '') {
            continue;
        }
        if ($tag !== '*') {
            $soloJolly = false;
        }

        // "it-IT" e "it" contano entrambi per l'italiano; "q=0.8" e' il peso, e in
        // assenza vale 1 come prescrive la RFC 9110.
        $q = 1.0;
        foreach (array_slice($parti, 1) as $parametro) {
            if (preg_match('/^\s*q\s*=\s*([0-9.]+)\s*$/', $parametro, $m) === 1) {
                $q = (float) $m[1];
            }
        }

        foreach (['it', 'en'] as $lingua) {
            if ($tag === $lingua || str_starts_with($tag, $lingua . '-')) {
                $qualita[$lingua] = max($qualita[$lingua] ?? 0.0, $q);
            }
        }
    }

    if ($qualita['it'] === null && $qualita['en'] === null) {
        // Caso 1 contro caso 3: il browser non ha detto niente, oppure ha chiesto una lingua
        // che non abbiamo.
        return $soloJolly ? LINGUA_DEFAULT : 'en';
    }
    if ($qualita['it'] === null) {
        return 'en';
    }
    if ($qualita['en'] === null) {
        return 'it';
    }

    return $qualita['en'] > $qualita['it'] ? 'en' : 'it';
}

/**
 * Sceglie la lingua, eventualmente redirige, e ricorda la scelta. Va chiamata **prima di
 * qualunque output**, perche' manda intestazioni.
 *
 * ⚑ **Non esiste nessun endpoint per cambiare lingua, ed e' voluto.** La bandierina e' un
 * link normale verso l'altra versione della stessa pagina, e visitarla *e'* la scelta: il
 * cookie viene scritto con la lingua della pagina che si sta guardando. Il rilevamento
 * automatico scatta solo quando il cookie **non c'e'**, quindi non puo' mai rimbalzare
 * indietro chi ha appena cliccato la bandiera.
 *
 * ☠ Il parametro `?l=` sui soli link della bandierina copre il caso limite di chi ha i
 * cookie bloccati: senza, un browser in inglese e senza cookie riporterebbe all'inglese a
 * ogni clic sulla bandiera italiana, e quella bandiera sembrerebbe rotta.
 */
function applica_lingua(): void
{
    $lingua = lingua_corrente();

    // Vary va messo sempre, anche quando non si redirige: dice ai proxy e alla cache del
    // browser che questa pagina cambia in base a quelle due cose. Senza, una cache
    // intermedia servirebbe la copia italiana a un visitatore inglese.
    header('Vary: Accept-Language, Cookie');

    $sceltaEsplicita = isset($_GET['l']) && in_array($_GET['l'], LINGUE, true);

    if ($lingua === LINGUA_DEFAULT && !$sceltaEsplicita && !isset($_COOKIE[COOKIE_LINGUA])) {
        $preferita = lingua_preferita($_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? null);
        if ($preferita !== LINGUA_DEFAULT) {
            // 302 e non 301: la destinazione dipende da chi chiede, e un permanente
            // verrebbe memorizzato dal browser per tutti.
            header('Location: ' . url_per($preferita), true, 302);
            exit;
        }
    }

    setcookie(COOKIE_LINGUA, $lingua, [
        'expires'  => time() + COOKIE_LINGUA_DURATA,
        'path'     => '/',
        'httponly' => true,
        'samesite' => 'Lax',
        'secure'   => ($_SERVER['HTTPS'] ?? '') !== '',
    ]);
}

/**
 * Il dizionario di una lingua, caricato una volta sola.
 *
 * ⚑ Sono due file per lingua: `it.php` con le stringhe brevi dell'interfaccia e
 * `it.legale.php` con i corpi delle pagine legali. Non e' una gerarchia, e' solo
 * leggibilita': i testi legali sono blocchi di HTML da qualche migliaio di parole
 * ciascuno, e mescolarli alle etichette dei bottoni renderebbe impraticabile trovare
 * qualunque cosa in entrambi i file.
 */
function dizionario(string $lingua): array
{
    static $cache = [];
    if (isset($cache[$lingua])) {
        return $cache[$lingua];
    }

    $unito = [];
    foreach ([$lingua . '.php', $lingua . '.legale.php'] as $nome) {
        $file = __DIR__ . '/lang/' . $nome;
        if (is_readable($file)) {
            $unito += require $file;
        }
    }

    return $cache[$lingua] = $unito;
}

/**
 * La stringa [$chiave] nella lingua corrente.
 *
 * ☠ **Il valore restituito NON viene ripulito e puo' contenere HTML**, perche' i testi del
 * sito hanno grassetti e collegamenti. Va quindi stampato con `echo`, mai passato per `e()`,
 * e nel dizionario non deve MAI finire niente che provenga dall'utente: sarebbe un XSS
 * immediato. I parametri, quelli si', vengono ripuliti.
 *
 * Se una chiave manca nella lingua richiesta si ripiega sull'italiano: a un lettore
 * inglese una frase italiana e' fastidiosa, una chiave grezza in pagina e' un sito rotto.
 * Il buco finisce nel log, e `deploy/verifica_lingue.php` lo trova prima che lo veda un
 * visitatore.
 *
 * @param array<string, string> $parametri sostituiscono i segnaposto `{nome}`
 */
function t(string $chiave, array $parametri = []): string
{
    $lingua = lingua_corrente();
    $testo = dizionario($lingua)[$chiave] ?? null;

    if ($testo === null) {
        if ($lingua !== LINGUA_DEFAULT) {
            error_log("[smpmicroapps] chiave mancante in {$lingua}: {$chiave}");
        }
        $testo = dizionario(LINGUA_DEFAULT)[$chiave] ?? $chiave;
    }

    foreach ($parametri as $nome => $valore) {
        $testo = str_replace('{' . $nome . '}', e((string) $valore), $testo);
    }

    return $testo;
}

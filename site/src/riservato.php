<?php

/**
 * L'area riservata al proprietario: `/riservato` (decisione del 2026-10-11, `memory/decisioni.md`).
 *
 * Una pagina sola, in italiano, senza link dal sito e fuori dall'indice dei motori, che dopo il
 * login mostra lo stato di tutte le app (`var/riservato/dati.json`, generato da
 * `tool/genera_riservato.py`).
 *
 * ⚑ **Cosa protegge e da cosa.** Il contenuto non e' un segreto industriale, ma non e' pubblico:
 * date di revisione, problemi aperti, decisioni. La pagina e' su Internet, quindi le difese sono
 * quelle di un login vero e non di una "pagina nascosta":
 *
 * - la password non esiste da nessuna parte, ne' nel repo (pubblico su GitHub) ne' sul server:
 *   sul server c'e' solo l'impronta **Argon2id** in `config.local.php` (`RISERVATO_HASH`);
 * - senza impronta l'area **non esiste** (404): un errore di configurazione la chiude, non la apre;
 * - se la build di PHP non ha Argon2id la pagina **lo dice** (503) invece di ripiegare su bcrypt;
 * - sessione dedicata (cookie proprio, `Secure`, `HttpOnly`, `SameSite=Strict`, percorso
 *   `/riservato`), id rigenerato al login, 8 ore al massimo e 30 minuti di inattivita';
 * - CSRF su login e logout; limite ai tentativi **per IP su file** con blocco crescente;
 * - stesso tempo di risposta su ogni errore e un solo messaggio, che non dice se e' sbagliato
 *   l'utente o la password;
 * - `Cache-Control: no-store` e `X-Robots-Tag: noindex` su ogni risposta;
 * - i dati stanno in `var/`, fuori dalla document root e fuori da git, e si leggono solo dopo il login.
 *
 * ☠ Questa pagina NON include `src/layout.php`: quello chiama `applica_lingua()` a livello di file,
 * che rimbalzerebbe un browser inglese su `/en/riservato`. L'area e' solo italiana e ha una sua
 * testata minima, con le classi CSS del sito.
 */

declare(strict_types=1);

require_once __DIR__ . '/config.php';

/** Lo username atteso se `config.local.php` non ne indica un altro. Non e' un segreto. */
const RISERVATO_UTENTE_DEFAULT = 'smp-webmaster';

/**
 * I parametri con cui si genera l'impronta (vedi `codebase_reference.md`, «Come si imposta la
 * password»). 64 MiB e 4 passaggi: circa 0,2 s per verifica su un core moderno, che rende
 * impraticabile provare password a forza bruta anche con l'impronta in mano. `threads = 1` perche'
 * le build di PHP che usano l'Argon2 di libsodium non accettano altri valori.
 */
const RISERVATO_ARGON2 = ['memory_cost' => 65536, 'time_cost' => 4, 'threads' => 1];

/**
 * Un'impronta Argon2id di una stringa casuale buttata via, con gli stessi parametri di quella vera.
 *
 * ⚑ Si verifica la password **contro questa** quando lo username e' sbagliato: cosi' il lavoro (e
 * il tempo) e' lo stesso nei due casi, e dal tempo di risposta non si capisce quale dei due campi
 * era giusto. Non corrisponde a nessuna password nota.
 */
const RISERVATO_HASH_FINTO = '$argon2id$v=19$m=65536,t=4,p=1$Ly9Sbzl2WDlIVlBFNjBKdg$czkyQfIP+5ukPd8rddwgiLrQ57h/Ujzf7kNWg3wehlA';

/** Durata massima di una sessione dal login, in secondi (8 ore). */
const RISERVATO_DURATA_MAX = 8 * 3600;

/** Dopo quanti secondi senza richieste la sessione scade (30 minuti). */
const RISERVATO_INATTIVITA = 30 * 60;

/** Errori ammessi nella finestra prima del blocco, e la finestra in secondi (5 in 15 minuti). */
const RISERVATO_MAX_ERRORI = 5;
const RISERVATO_FINESTRA = 15 * 60;

/** Il primo blocco dura 15 minuti, poi raddoppia a ogni blocco successivo fino a 24 ore. */
const RISERVATO_BLOCCO_BASE = 15 * 60;
const RISERVATO_BLOCCO_MAX = 24 * 3600;

/**
 * Ogni risposta a un login fallito (o bloccato) arriva dopo almeno questo tempo dall'inizio della
 * richiesta, in secondi. Deve stare sopra il costo di Argon2id con margine: cosi' tutti gli
 * errori durano uguale, qualunque sia il ramo preso.
 */
const RISERVATO_TEMPO_RISPOSTA = 1.5;

/** Il nome del cookie di sessione: diverso da quello del modulo contatti (`smpmicroapps`). */
const RISERVATO_COOKIE = 'smpriservato';

/** Il percorso pubblico della pagina e del cookie. */
const RISERVATO_PERCORSO = '/riservato';

// ─── Configurazione ──────────────────────────────────────────────────────────

/**
 * Username e impronta da `config.local.php`.
 *
 * @return array{utente: string, hash: ?string}
 */
function riservato_configurazione(): array
{
    $cfg = config();
    $hash = $cfg['RISERVATO_HASH'] ?? null;
    $utente = $cfg['RISERVATO_UTENTE'] ?? RISERVATO_UTENTE_DEFAULT;
    return [
        'utente' => is_string($utente) && $utente !== '' ? $utente : RISERVATO_UTENTE_DEFAULT,
        'hash'   => is_string($hash) && trim($hash) !== '' ? trim($hash) : null,
    ];
}

/**
 * Se l'area puo' funzionare.
 *
 * - `'ok'`: impronta presente, Argon2id disponibile, impronta Argon2id;
 * - `'disattivata'`: nessuna impronta → la pagina risponde 404, come se non esistesse;
 * - `'argon2_assente'`: questa build di PHP non ha Argon2id → 503 con il motivo scritto;
 * - `'hash_non_argon2id'`: l'impronta c'e' ma e' di un altro algoritmo (bcrypt, testo) → 503.
 *
 * ☠ Gli ultimi due **non ripiegano**: un'impronta bcrypt verrebbe accettata da `password_verify()`
 * senza dire niente, e la protezione sarebbe piu' debole di quella dichiarata.
 */
function riservato_stato_configurazione(): string
{
    $hash = riservato_configurazione()['hash'];
    if ($hash === null) {
        return 'disattivata';
    }
    if (!defined('PASSWORD_ARGON2ID')) {
        return 'argon2_assente';
    }
    if ((password_get_info($hash)['algoName'] ?? '') !== 'argon2id') {
        return 'hash_non_argon2id';
    }
    return 'ok';
}

// ─── Intestazioni e trasporto ────────────────────────────────────────────────

/**
 * Le intestazioni di ogni risposta dell'area, prima di qualunque output.
 *
 * ⚑ `no-store` e non solo `no-cache`: `no-cache` permette di salvare la pagina su disco e
 * ricontrollarla; `no-store` vieta di salvarla, quindi il contenuto riservato non resta nella
 * cache del browser ne' di un proxy dopo il logout. `Vary: Cookie` per le cache che ignorassero
 * `no-store`.
 */
function riservato_intestazioni(): void
{
    header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0, private');
    header('Pragma: no-cache');
    header('Expires: 0');
    header('Vary: Cookie');
    header('X-Robots-Tag: noindex, nofollow, noarchive');
    header('Referrer-Policy: no-referrer');
    header('X-Frame-Options: DENY');
    header('X-Content-Type-Options: nosniff');
}

/** Se la richiesta e' arrivata in HTTPS (nginx passa `HTTPS=on` con `fastcgi_params`). */
function riservato_https(): bool
{
    $https = $_SERVER['HTTPS'] ?? '';
    return $https !== '' && strtolower((string) $https) !== 'off';
}

/**
 * Se si sta girando sul server di sviluppo di PHP (`php -S`), che parla solo HTTP.
 *
 * ⚑ E' l'**unica** eccezione al cookie `Secure` e al passaggio forzato in HTTPS, e non puo' scattare
 * in produzione: sotto php-fpm `PHP_SAPI` vale `fpm-fcgi`, mai `cli-server`.
 */
function riservato_sviluppo(): bool
{
    return PHP_SAPI === 'cli-server';
}

/** In produzione, una richiesta in chiaro viene rimandata in HTTPS prima di aprire la sessione. */
function riservato_forza_https(): void
{
    if (riservato_https() || riservato_sviluppo()) {
        return;
    }
    header('Location: ' . SITO_URL . RISERVATO_PERCORSO, true, 301);
    exit;
}

/** L'indirizzo del client. nginx parla direttamente con php-fpm: nessun proxy davanti. */
function riservato_ip(): string
{
    return (string) ($_SERVER['REMOTE_ADDR'] ?? '0.0.0.0');
}

// ─── Sessione ────────────────────────────────────────────────────────────────

/** Le cartelle di lavoro dentro `var/`: sessioni, tentativi, dati. */
function riservato_cartella(string $nome = ''): string
{
    $base = rtrim((string) config()['storageDir'], '/\\');
    return $nome === '' ? $base : $base . '/' . $nome;
}

/**
 * Avvia la sessione **dedicata** dell'area. Idempotente.
 *
 * ⚑ File di sessione in `var/sessioni-riservato/` e non nella cartella di sistema: su Ubuntu quella
 * viene ripulita da un cron con il `gc_maxlifetime` globale (24 minuti), che chiuderebbe la sessione
 * prima dei nostri 30 minuti di inattivita', e la condividono tutti i siti del server. Le sessioni
 * scadute le cancella `riservato_pulisci_sessioni()` a ogni login.
 *
 * ☠ `use_strict_mode`: un id di sessione inventato dal client (fissazione della sessione) viene
 * rifiutato e sostituito. Il login rigenera comunque l'id.
 */
function riservato_sessione(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) {
        return;
    }
    $dir = riservato_cartella('sessioni-riservato');
    if (!is_dir($dir)) {
        @mkdir($dir, 0700, true);
    }
    session_set_cookie_params([
        'lifetime' => 0,
        'path'     => RISERVATO_PERCORSO,
        'httponly' => true,
        'samesite' => 'Strict',
        'secure'   => !riservato_sviluppo() || riservato_https(),
    ]);
    session_name(RISERVATO_COOKIE);
    session_save_path($dir);
    session_start([
        'use_strict_mode'  => 1,
        'use_only_cookies' => 1,
        'use_trans_sid'    => 0,
        'gc_maxlifetime'   => RISERVATO_DURATA_MAX,
        'gc_probability'   => 0,
        // Le intestazioni di cache le decide riservato_intestazioni(): il limitatore di PHP
        // («nocache») le sovrascriverebbe con le sue.
        'cache_limiter'    => '',
    ]);
}

/** Cancella i file di sessione piu' vecchi della durata massima. */
function riservato_pulisci_sessioni(): void
{
    $limite = time() - RISERVATO_DURATA_MAX;
    foreach (glob(riservato_cartella('sessioni-riservato') . '/sess_*') ?: [] as $file) {
        if (@filemtime($file) < $limite) {
            @unlink($file);
        }
    }
}

/** Il token CSRF della sessione dell'area (32 byte casuali, esadecimali). */
function riservato_csrf(): string
{
    riservato_sessione();
    if (empty($_SESSION['csrf']) || !is_string($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

/** Confronto a tempo costante del token inviato con quello di sessione. */
function riservato_csrf_valido(mixed $token): bool
{
    riservato_sessione();
    $atteso = $_SESSION['csrf'] ?? '';
    return is_string($token) && $token !== '' && is_string($atteso) && $atteso !== ''
        && hash_equals($atteso, $token);
}

/**
 * Se la sessione e' autenticata e non scaduta. Aggiorna l'ultimo accesso.
 *
 * Una sessione scaduta (8 ore dal login o 30 minuti senza richieste) viene distrutta qui.
 */
function riservato_autenticato(): bool
{
    riservato_sessione();
    $s = $_SESSION['riservato'] ?? null;
    if (!is_array($s) || ($s['dentro'] ?? false) !== true) {
        return false;
    }
    $ora = time();
    if ($ora - (int) ($s['login'] ?? 0) > RISERVATO_DURATA_MAX
        || $ora - (int) ($s['ultimo'] ?? 0) > RISERVATO_INATTIVITA) {
        riservato_esci();
        riservato_sessione();
        return false;
    }
    $_SESSION['riservato']['ultimo'] = $ora;
    return true;
}

/**
 * Verifica username e password.
 *
 * ☠ `password_verify()` gira **sempre**, anche con lo username sbagliato (contro
 * `RISERVATO_HASH_FINTO`), e i due esiti si combinano solo alla fine: niente scorciatoie che
 * rendano piu' veloce uno dei due errori. Lo username si confronta con `hash_equals`.
 */
function riservato_verifica_credenziali(string $utente, string $password): bool
{
    $cfg = riservato_configurazione();
    $utenteOk = hash_equals($cfg['utente'], $utente);
    $hash = ($utenteOk && $cfg['hash'] !== null) ? $cfg['hash'] : RISERVATO_HASH_FINTO;
    // Argon2 su una password di un megabyte costerebbe solo a noi: si tronca prima.
    $passwordOk = password_verify(substr($password, 0, 4096), $hash);
    return $utenteOk && $passwordOk && $cfg['hash'] !== null;
}

/** Login riuscito: id nuovo (il vecchio viene cancellato), token nuovo, orari. */
function riservato_entra(): void
{
    riservato_sessione();
    session_regenerate_id(true);
    $ora = time();
    $_SESSION = [
        'riservato' => ['dentro' => true, 'login' => $ora, 'ultimo' => $ora],
        'csrf'      => bin2hex(random_bytes(32)),
    ];
    riservato_pulisci_sessioni();
}

/** Logout: svuota e distrugge la sessione e cancella il cookie. */
function riservato_esci(): void
{
    riservato_sessione();
    $_SESSION = [];
    $p = session_get_cookie_params();
    setcookie(session_name(), '', [
        'expires'  => time() - 3600,
        'path'     => $p['path'],
        'secure'   => $p['secure'],
        'httponly' => true,
        'samesite' => 'Strict',
    ]);
    session_destroy();
}

/**
 * Aspetta fino a `RISERVATO_TEMPO_RISPOSTA` secondi dall'inizio della richiesta.
 *
 * ⚑ Pareggia i tempi di tutti gli errori: credenziali sbagliate, token scaduto, IP bloccato. Senza,
 * un blocco (che non verifica niente) risponderebbe in un millisecondo e un errore in 0,2 secondi.
 */
function riservato_attendi(float $inizio): void
{
    $resto = RISERVATO_TEMPO_RISPOSTA - (microtime(true) - $inizio);
    if ($resto > 0) {
        usleep((int) round($resto * 1_000_000));
    }
}

// ─── Limite ai tentativi ─────────────────────────────────────────────────────

/**
 * Apre `var/riservato-tentativi.json` in esclusiva, passa i dati a `$fn` e riscrive quello che
 * restituisce. Torna il secondo valore di `$fn`, o `null` se il file non si puo' usare.
 *
 * ⚑ Su file e non in sessione: la sessione la controlla il client, che basta butti il cookie per
 * ripartire da zero. Gli IP non si salvano in chiaro: solo i primi 16 caratteri dello SHA-256 di
 * IP + sale, che bastano a distinguere un client dall'altro.
 *
 * @param callable(array, string): array{0: array, 1: mixed} $fn
 */
function riservato_con_tentativi(string $ip, callable $fn): mixed
{
    $dir = riservato_cartella();
    if (!is_dir($dir)) {
        @mkdir($dir, 0770, true);
    }
    $h = @fopen($dir . '/riservato-tentativi.json', 'c+');
    if ($h === false) {
        return null;
    }
    try {
        if (!flock($h, LOCK_EX)) {
            return null;
        }
        $dati = json_decode(stream_get_contents($h) ?: '', true);
        $dati = is_array($dati) ? $dati : [];
        $chiave = substr(hash('sha256', $ip . '|smpmicroapps-riservato'), 0, 16);
        $ora = time();
        // Si buttano le voci ferme da piu' di un giorno, cosi' il file non cresce.
        $dati = array_filter($dati, static function ($v) use ($ora): bool {
            if (!is_array($v)) {
                return false;
            }
            $ultimo = max([(int) ($v['fino'] ?? 0), ...array_map('intval', (array) ($v['errori'] ?? []))]);
            return $ultimo > $ora - RISERVATO_BLOCCO_MAX;
        });
        [$dati, $risultato] = $fn($dati, $chiave);
        ftruncate($h, 0);
        rewind($h);
        fwrite($h, json_encode($dati));
        fflush($h);
        return $risultato;
    } finally {
        flock($h, LOCK_UN);
        fclose($h);
    }
}

/**
 * Quanti secondi di blocco restano per questo IP: 0 se puo' provare, `null` se il file dei
 * tentativi non e' utilizzabile.
 *
 * ☠ Con `null` il chiamante **nega** il login. Al contrario del modulo contatti (dove un contatore
 * guasto non deve far perdere i messaggi dei clienti), qui il limite e' la difesa principale contro
 * chi prova password: se manca, l'area resta chiusa e lo scrive nel log.
 */
function riservato_blocco_residuo(string $ip): ?int
{
    $r = riservato_con_tentativi($ip, static function (array $dati, string $k): array {
        $fino = (int) ($dati[$k]['fino'] ?? 0);
        return [$dati, max(0, $fino - time())];
    });
    return $r === null ? null : (int) $r;
}

/**
 * Registra un errore. Al quinto nella finestra di 15 minuti scatta un blocco di 15 minuti, poi 30,
 * 60, ... fino a 24 ore; il contatore dei blocchi si azzera dopo un giorno senza blocchi.
 * Torna i secondi di blocco appena iniziato (0 se non e' scattato).
 */
function riservato_registra_errore(string $ip): int
{
    $r = riservato_con_tentativi($ip, static function (array $dati, string $k): array {
        $ora = time();
        $v = $dati[$k] ?? ['errori' => [], 'blocchi' => 0, 'fino' => 0];
        if ((int) ($v['fino'] ?? 0) < $ora - RISERVATO_BLOCCO_MAX) {
            $v['blocchi'] = 0;
        }
        $errori = array_values(array_filter(
            array_map('intval', (array) ($v['errori'] ?? [])),
            static fn (int $t): bool => $t > $ora - RISERVATO_FINESTRA
        ));
        $errori[] = $ora;
        $durata = 0;
        if (count($errori) >= RISERVATO_MAX_ERRORI) {
            $v['blocchi'] = (int) ($v['blocchi'] ?? 0) + 1;
            $durata = min(RISERVATO_BLOCCO_MAX, RISERVATO_BLOCCO_BASE * (2 ** ($v['blocchi'] - 1)));
            $v['fino'] = $ora + $durata;
            $errori = [];
        }
        $v['errori'] = $errori;
        $dati[$k] = $v;
        return [$dati, $durata];
    });
    return (int) ($r ?? 0);
}

/** Dopo un login riuscito gli errori di quell'IP si dimenticano. */
function riservato_azzera_errori(string $ip): void
{
    riservato_con_tentativi($ip, static function (array $dati, string $k): array {
        unset($dati[$k]);
        return [$dati, null];
    });
}

// ─── Dati e disegno ──────────────────────────────────────────────────────────

/**
 * I dati della pagina, da `var/riservato/dati.json`. `null` se il file non c'e' o non e' valido.
 *
 * Va chiamata **solo dopo** `riservato_autenticato()`.
 */
function riservato_dati(): ?array
{
    $file = riservato_cartella('riservato') . '/dati.json';
    if (!is_readable($file)) {
        return null;
    }
    $dati = json_decode((string) file_get_contents($file), true);
    return is_array($dati) && ($dati['formato'] ?? null) === 1 ? $dati : null;
}

/**
 * Markdown in linea → HTML: `**grassetto**`, `` `codice` ``, `~~barrato~~`, `[testo](https://...)`.
 *
 * ☠ Si ripulisce **prima** con `e()` e si trasforma dopo: il testo viene dai file del repo, ma un
 * `<` in un documento non deve mai diventare un tag. I link accettano solo `http(s)://`.
 */
function riservato_md(?string $testo): string
{
    $h = e($testo ?? '');
    $codici = [];
    $h = preg_replace_callback('/`([^`]+)`/', static function (array $m) use (&$codici): string {
        $codici[] = '<code>' . $m[1] . '</code>';
        return "\x00" . (count($codici) - 1) . "\x00";
    }, $h);
    $h = preg_replace('/\*\*(.+?)\*\*/s', '<strong>$1</strong>', $h);
    $h = preg_replace('/~~(.+?)~~/s', '<del>$1</del>', $h);
    $h = preg_replace(
        '/\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/',
        '<a href="$2" rel="noopener noreferrer">$1</a>',
        $h
    );
    return preg_replace_callback('/\x00(\d+)\x00/', static fn (array $m): string => $codici[(int) $m[1]], $h);
}

/** Il testo senza markdown, per gli attributi `title`. */
function riservato_testo(?string $testo): string
{
    return trim(str_replace(['**', '~~', '`'], '', $testo ?? ''));
}

/**
 * Disegna i blocchi prodotti da `genera_riservato.py` (titolo, paragrafo, tabella, lista, nota,
 * codice). Le tabelle stanno in un contenitore che scorre in orizzontale.
 *
 * @param list<array<string, mixed>> $blocchi
 */
function riservato_blocchi(array $blocchi): string
{
    $out = '';
    foreach ($blocchi as $b) {
        switch ($b['tipo'] ?? '') {
            case 'titolo':
                $out .= '<h4 class="ris-sottotitolo">' . riservato_md($b['testo'] ?? '') . '</h4>';
                break;
            case 'paragrafo':
                $out .= '<p>' . riservato_md($b['testo'] ?? '') . '</p>';
                break;
            case 'codice':
                $out .= '<pre class="ris-codice"><code>' . e($b['testo'] ?? '') . '</code></pre>';
                break;
            case 'nota':
                $out .= '<div class="ris-nota">' . riservato_blocchi($b['blocchi'] ?? []) . '</div>';
                break;
            case 'tabella':
                $out .= '<div class="scroll-x"><table class="ris-tab ris-tab--dettaglio"><thead><tr>';
                foreach ($b['intestazione'] ?? [] as $c) {
                    $out .= '<th scope="col">' . riservato_md((string) $c) . '</th>';
                }
                $out .= '</tr></thead><tbody>';
                foreach ($b['righe'] ?? [] as $riga) {
                    $out .= '<tr>';
                    foreach ($riga as $c) {
                        $out .= '<td>' . riservato_md((string) $c) . '</td>';
                    }
                    $out .= '</tr>';
                }
                $out .= '</tbody></table></div>';
                break;
            case 'lista':
                $tag = !empty($b['ordinata']) ? 'ol' : 'ul';
                $spunte = array_filter($b['voci'] ?? [], static fn ($v): bool => ($v['spunta'] ?? null) !== null);
                $out .= '<' . $tag . ($spunte ? ' class="ris-spunte"' : '') . '>';
                foreach ($b['voci'] ?? [] as $v) {
                    $s = $v['spunta'] ?? null;
                    $segno = $s === null ? '' : ($s
                        ? '<span class="ris-spunta ris-spunta--fatta" aria-label="fatto">✓</span>'
                        : '<span class="ris-spunta" aria-label="da fare"></span>');
                    $out .= '<li' . ($s === true ? ' class="ris-fatto"' : '') . '>' . $segno
                        . riservato_md((string) ($v['testo'] ?? '')) . '</li>';
                }
                $out .= '</' . $tag . '>';
                break;
        }
    }
    return $out;
}

/** L'etichetta dello stato di un'app nella lista. */
function riservato_etichetta_stato(string $stato): string
{
    return match ($stato) {
        'pubblicata'     => 'Pubblicata',
        'in-lavorazione' => 'In lavorazione',
        'non-iniziata'   => 'Non iniziata',
        'annullata'      => 'Annullata',
        default          => $stato,
    };
}

/** L'ancora di un'app nella pagina. */
function riservato_ancora(array $app): string
{
    $base = strtolower((string) preg_replace('/[^A-Za-z0-9]+/', '-', (string) ($app['nome'] ?? '')));
    return 'app-' . trim($base, '-');
}

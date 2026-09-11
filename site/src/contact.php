<?php

/**
 * Il modulo di contatto: validazione, difese dallo spam, archiviazione, notifica.
 *
 * ⚑ **L'ordine conta: prima si salva, poi si notifica.** Se si invertisse, un guasto SMTP
 * (credenziali scadute, provider irraggiungibile, quota esaurita) farebbe perdere il
 * messaggio, e nessuno se ne accorgerebbe: chi ha scritto vede "grazie" e aspetta una
 * risposta che non arrivera' mai. Salvando per primo, il peggio che puo' succedere e' una
 * notifica mancata su un messaggio che resta leggibile nell'archivio.
 */

declare(strict_types=1);

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/mailer.php';

/** Gli argomenti selezionabili. La chiave finisce nell'oggetto della mail. */
function argomenti_contatto(): array
{
    return [
        'bug'            => 'Segnalazione di un problema',
        'personalizzato' => 'Richiesta di sviluppo personalizzato',
        'app'            => 'Domanda su una delle app',
        'privacy'        => 'Privacy e dati personali',
        'altro'          => 'Altro',
    ];
}

/** Avvia la sessione, che serve al token anti-CSRF. Idempotente. */
function sessione(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) {
        return;
    }
    session_set_cookie_params([
        'lifetime' => 0,
        'path'     => '/',
        'httponly' => true,
        'samesite' => 'Lax',
        'secure'   => ($_SERVER['HTTPS'] ?? '') !== '',
    ]);
    session_name('smpmicroapps');
    session_start();
}

/**
 * Il token anti-CSRF della sessione corrente.
 *
 * ⚑ Serve anche a un modulo che non fa login: senza, un sito qualunque puo' far inviare
 * al visitatore un messaggio a nostro nome, e l'unico effetto pratico e' una casella piena
 * di spazzatura firmata da persone vere.
 */
function csrf_token(): string
{
    sessione();
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

/**
 * Valida l'invio e restituisce gli errori. Vuoto significa "va bene".
 *
 * @param array<string, string> $post
 * @return list<string>
 */
function valida_contatto(array $post): array
{
    $errori = [];

    sessione();
    $token = $post['csrf'] ?? '';
    if (!is_string($token) || $token === '' || !hash_equals($_SESSION['csrf'] ?? '', $token)) {
        // Succede anche in buona fede: una scheda lasciata aperta per ore ha una sessione
        // scaduta. Il messaggio lo dice, invece di accusare l'utente di qualcosa.
        $errori[] = 'La pagina è rimasta aperta troppo a lungo. Ricaricala e reinvia il messaggio.';
        return $errori;
    }

    // ☠ La trappola: un campo invisibile a una persona e irresistibile per un robot che
    // compila tutto quello che trova. Se e' pieno, si risponde "grazie" senza salvare
    // niente: dire "sei un robot" insegna al robot come passare la prossima volta.
    if (trim($post['website'] ?? '') !== '') {
        return ['__bot__'];
    }

    $nome = trim($post['nome'] ?? '');
    if (mb_strlen($nome) < 2 || mb_strlen($nome) > 80) {
        $errori[] = 'Indica un nome fra 2 e 80 caratteri.';
    }

    $email = trim($post['email'] ?? '');
    if (filter_var($email, FILTER_VALIDATE_EMAIL) === false || mb_strlen($email) > 190) {
        $errori[] = 'Indica un indirizzo email valido: serve per poterti rispondere.';
    }

    if (!array_key_exists($post['argomento'] ?? '', argomenti_contatto())) {
        $errori[] = 'Scegli un argomento fra quelli proposti.';
    }

    $messaggio = trim($post['messaggio'] ?? '');
    if (mb_strlen($messaggio) < 20) {
        $errori[] = 'Scrivi qualche riga in più: sotto i 20 caratteri non si capisce cosa serve.';
    }
    if (mb_strlen($messaggio) > 5000) {
        $errori[] = 'Il messaggio supera i 5.000 caratteri. Riassumilo, o allega il resto via email.';
    }

    if (($post['consenso'] ?? '') !== 'si') {
        $errori[] = 'Per poterti rispondere devi confermare di aver letto l\'informativa privacy.';
    }

    return $errori;
}

/**
 * Il limite di invii per indirizzo IP.
 *
 * ⚑ Un contatore in un file e non in sessione: la sessione la controlla il client, che
 * basta scarti il cookie per ripartire da zero. Il file no.
 *
 * L'indirizzo IP viene **troncato e poi cifrato**: serve solo a distinguere un mittente
 * dall'altro per un'ora, non a sapere chi e'. Conservare gli IP in chiaro sarebbe un
 * trattamento di dati personali senza nessuna necessita'.
 */
function limite_superato(string $ip): bool
{
    $cfg = config();
    $dir = $cfg['storageDir'];
    if (!is_dir($dir)) {
        @mkdir($dir, 0770, true);
    }

    $file = $dir . '/ratelimit.json';
    $ora = time();
    $chiave = substr(hash('sha256', $ip . '|smpmicroapps'), 0, 16);

    $handle = @fopen($file, 'c+');
    if ($handle === false) {
        // Se il contatore non si puo' scrivere non si blocca il messaggio: il limite e' una
        // difesa dallo spam, non una condizione per ricevere posta da un cliente.
        return false;
    }

    try {
        flock($handle, LOCK_EX);
        $contenuto = stream_get_contents($handle) ?: '';
        $dati = json_decode($contenuto, true);
        $dati = is_array($dati) ? $dati : [];

        // Si buttano le voci piu' vecchie di un'ora: il file non cresce all'infinito.
        $dati = array_filter(
            $dati,
            static fn (array $v): bool => ($v['ultimo'] ?? 0) > $ora - 3600
        );

        $voce = $dati[$chiave] ?? ['conteggio' => 0, 'ultimo' => $ora];
        $superato = $voce['conteggio'] >= (int) $cfg['rateLimit']['maxPerHour'];

        if (!$superato) {
            $dati[$chiave] = ['conteggio' => $voce['conteggio'] + 1, 'ultimo' => $ora];
        }

        ftruncate($handle, 0);
        rewind($handle);
        fwrite($handle, json_encode($dati, JSON_UNESCAPED_UNICODE));
        fflush($handle);

        return $superato;
    } finally {
        flock($handle, LOCK_UN);
        fclose($handle);
    }
}

/**
 * Salva il messaggio in append su un file JSON Lines, fuori dalla webroot.
 *
 * @param array<string, string> $post
 * @throws RuntimeException se non si riesce a scrivere: a quel punto e' giusto che
 *                          l'utente veda un errore, invece di un "grazie" bugiardo.
 */
function archivia_contatto(array $post): void
{
    $cfg = config();
    $dir = $cfg['storageDir'];
    if (!is_dir($dir) && !@mkdir($dir, 0770, true) && !is_dir($dir)) {
        throw new RuntimeException('cartella di archiviazione non creabile');
    }

    $riga = json_encode([
        'ricevuto'  => date('c'),
        'nome'      => $post['nome'],
        'email'     => $post['email'],
        'argomento' => $post['argomento'],
        'app'       => $post['app'] ?? '',
        'messaggio' => $post['messaggio'],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

    $scritto = @file_put_contents($dir . '/contatti.jsonl', $riga . "\n", FILE_APPEND | LOCK_EX);
    if ($scritto === false) {
        throw new RuntimeException('archivio non scrivibile');
    }
}

/**
 * Manda la notifica. Non lancia: un guasto SMTP non deve diventare un errore per chi
 * scrive, perche' il messaggio e' gia' al sicuro nell'archivio.
 *
 * @param array<string, string> $post
 * @return bool se la notifica e' partita davvero
 */
function notifica_contatto(array $post): bool
{
    $mailer = new Mailer(config()['smtp']);
    if (!$mailer->attivo()) {
        return false;
    }

    $argomenti = argomenti_contatto();
    $oggetto = '[smpmicroapps] ' . $argomenti[$post['argomento']] . ' - ' . $post['nome'];

    $corpo = implode("\n", [
        'Nuovo messaggio dal modulo di contatto di smpmicroapps.it',
        '',
        'Nome:      ' . $post['nome'],
        'Email:     ' . $post['email'],
        'Argomento: ' . $argomenti[$post['argomento']],
        'App:       ' . ($post['app'] !== '' ? $post['app'] : '(non indicata)'),
        'Ricevuto:  ' . date('d/m/Y H:i'),
        '',
        str_repeat('-', 60),
        '',
        $post['messaggio'],
    ]);

    try {
        $mailer->invia($oggetto, $corpo, $post['email']);
        return true;
    } catch (SmtpError $e) {
        error_log('[smpmicroapps] notifica non inviata: ' . $e->getMessage());
        return false;
    }
}

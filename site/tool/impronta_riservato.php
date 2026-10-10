<?php

/**
 * Genera l'impronta Argon2id della password dell'area riservata, da incollare in
 * `config.local.php` come `'RISERVATO_HASH' => '...'`.
 *
 * ⚑ La password si legge da **stdin**, mai dagli argomenti: un argomento resta nella history della
 * shell e si vede nell'elenco dei processi. Sul terminale di Linux/macOS l'eco viene spento
 * (`stty -echo`); da una pipe si legge la prima riga.
 *
 *     php site/tool/impronta_riservato.php
 *     # oppure, senza eco anche dove stty non c'e':
 *     read -rs P && printf '%s\n' "$P" | php site/tool/impronta_riservato.php; unset P
 *
 * Esce con 1 se questa build di PHP non ha Argon2id: in quel caso l'impronta va generata su una
 * macchina che lo ha (l'impronta e' portabile, la verifica no).
 */

declare(strict_types=1);

require_once __DIR__ . '/../src/riservato.php';

if (!defined('PASSWORD_ARGON2ID')) {
    fwrite(STDERR, "Questa build di PHP non ha Argon2id (PASSWORD_ARGON2ID non definita).\n");
    exit(1);
}

$terminale = function_exists('posix_isatty') ? posix_isatty(STDIN) : stream_isatty(STDIN);
$eco = $terminale && DIRECTORY_SEPARATOR === '/';

$leggi = static function (string $domanda) use ($terminale, $eco): string {
    if ($terminale) {
        fwrite(STDERR, $domanda);
    }
    if ($eco) {
        shell_exec('stty -echo');
    }
    $riga = fgets(STDIN);
    if ($eco) {
        shell_exec('stty echo');
        fwrite(STDERR, "\n");
    }
    return rtrim($riga === false ? '' : $riga, "\r\n");
};

$password = $leggi('Password: ');
if ($terminale && $leggi('Ripeti: ') !== $password) {
    fwrite(STDERR, "Le due password non coincidono.\n");
    exit(1);
}
if (strlen($password) < 12) {
    fwrite(STDERR, "Password troppo corta: almeno 12 caratteri.\n");
    exit(1);
}

echo password_hash($password, PASSWORD_ARGON2ID, RISERVATO_ARGON2), PHP_EOL;

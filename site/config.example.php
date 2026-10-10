<?php

/**
 * Configurazione della vetrina. COPIARE IN config.local.php E COMPILARE.
 *
 * ☠ `config.local.php` non e' versionato e non deve esserlo: contiene la password SMTP.
 * Questo file, invece, e' versionato e non deve MAI contenere credenziali vere.
 *
 * ⚑ Perche' un file e non variabili d'ambiente: il sito gira sotto php-fpm dietro nginx,
 * e passare l'ambiente a fpm significa toccare il pool condiviso con gli altri siti del
 * server. Un file leggibile dal solo utente di fpm e' piu' semplice e non tocca niente
 * che appartenga ad altri.
 */

declare(strict_types=1);

return [
    // ─────────────────────────────────────────────────────────────────────────
    // Posta
    // ─────────────────────────────────────────────────────────────────────────
    //
    // ☠ Sul server NON c'e' nessun MTA: `mail()` di PHP non spedisce niente e non
    // segnala errori. Senza queste credenziali il modulo di contatto continua a
    // funzionare e a **salvare** ogni messaggio, ma non arriva nessuna notifica.
    // Il messaggio non si perde mai: si perde solo l'avviso.
    'smtp' => [
        'enabled'  => false,
        'host'     => 'smtp.esempio.it',
        // 465 = TLS implicito, 587 = STARTTLS. Sono gli unici due supportati.
        'port'     => 465,
        'username' => 'info@smp-digital.it',
        'password' => '',
        // Il mittente deve essere una casella di cui il dominio autorizza l'invio,
        // altrimenti SPF e DMARC fanno finire tutto nello spam.
        'from'     => 'info@smp-digital.it',
        'fromName' => 'Vetrina smpmicroapps.it',
        // Dove arrivano i messaggi del modulo.
        'to'       => 'info@smp-digital.it',
    ],

    // ─────────────────────────────────────────────────────────────────────────
    // Dove finiscono i messaggi ricevuti
    // ─────────────────────────────────────────────────────────────────────────
    //
    // Un file JSON Lines in append, FUORI dalla webroot. E' la copia che resta anche
    // se la posta non parte, ed e' il motivo per cui il modulo non perde niente.
    'storageDir' => __DIR__ . '/var',

    // ─────────────────────────────────────────────────────────────────────────
    // Limite di invii
    // ─────────────────────────────────────────────────────────────────────────
    'rateLimit' => [
        'maxPerHour' => 5,
    ],

    // ─────────────────────────────────────────────────────────────────────────
    // Area riservata /riservato (src/riservato.php)
    // ─────────────────────────────────────────────────────────────────────────
    //
    // ☠ Qui NON si scrive mai la password, nemmeno in config.local.php: solo la sua impronta
    // Argon2id, generata con il comando in codebase_reference.md («Come si imposta la password»).
    // Con null (o chiave assente) l'area e' DISATTIVATA e /riservato risponde 404.
    'RISERVATO_UTENTE' => 'smp-webmaster',
    'RISERVATO_HASH'   => null,
];

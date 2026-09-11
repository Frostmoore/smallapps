<?php

/**
 * I dati fissi della vetrina e il caricamento della configurazione locale.
 *
 * ⚑ I dati dell'azienda stanno **qui e solo qui**. Compaiono in sei pagine diverse
 * (note legali, privacy, cookie, termini, responsabilita', pie' di pagina) e ricopiarli
 * significherebbe, alla prima variazione, un sito che dichiara due indirizzi diversi.
 * Per le note legali non e' un dettaglio estetico: e' il contenuto stesso dell'obbligo.
 */

declare(strict_types=1);

/** Il titolare del sito e delle app, come va indicato nelle note legali. */
const AZIENDA = [
    'denominazione' => 'SeeMyPage di Ronconi Riccardo',
    'titolare'      => 'Riccardo Ronconi',
    'piva'          => '02288080563',
    'indirizzo'     => 'Via degli Orti, 426',
    'cap'           => '01036',
    'citta'         => 'Nepi',
    'provincia'     => 'VT',
    'paese'         => 'Italia',
    'pec'           => 'legale@pec.seemypage.it',
    'email'         => 'info@smp-digital.it',
    // Se e quando ci sara' l'iscrizione al Registro delle Imprese, il numero REA va qui:
    // l'art. 2250 del codice civile lo vuole indicato negli spazi informatici. Vuoto
    // significa "non iscritto", e la riga non viene stampata.
    'rea'           => '',
];

/** Il dominio pubblico, senza barra finale. Serve ai link assoluti e alla sitemap. */
const SITO_URL = 'https://smpmicroapps.it';

const SITO_NOME = 'SMP MicroApps';

/**
 * La configurazione locale, con i valori di ripiego se il file non c'e'.
 *
 * Non lancia se `config.local.php` manca: il sito deve restare in piedi e mostrare le
 * pagine legali anche prima che qualcuno abbia messo le credenziali SMTP. Solo il modulo
 * di contatto si accorge della differenza, e lo dice.
 */
function config(): array
{
    static $cache = null;
    if ($cache !== null) {
        return $cache;
    }

    $defaults = require __DIR__ . '/../config.example.php';
    $localFile = __DIR__ . '/../config.local.php';
    $local = is_readable($localFile) ? require $localFile : [];

    // Fusione a due livelli: basta, perche' la configurazione e' profonda due.
    $merged = $defaults;
    foreach ($local as $key => $value) {
        $merged[$key] = is_array($value) && isset($defaults[$key]) && is_array($defaults[$key])
            ? array_merge($defaults[$key], $value)
            : $value;
    }

    return $cache = $merged;
}

/** Scorciatoia per l'escaping. Il nome corto e' voluto: compare centinaia di volte. */
function e(?string $value): string
{
    return htmlspecialchars($value ?? '', ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

<?php

/**
 * Verifica che i dizionari siano allineati. Si lancia dalla cartella `site/`:
 *
 *     php deploy/verifica_lingue.php
 *
 * ⚑ **Perche' esiste.** Una chiave presente in italiano e assente in inglese non produce
 * nessun errore: `t()` ripiega sull'italiano, e il risultato e' una frase italiana in mezzo
 * a una pagina inglese. Nessun visitatore la segnala, e chi ha scritto il codice non la
 * vede perche' legge il sito in italiano. E' il tipo di difetto che resta in produzione per
 * mesi.
 *
 * Controlla anche i segnaposto `{nome}`: una traduzione che perde un `{email}` stampa una
 * frase monca, e una che ne inventa uno lascia le graffe in pagina.
 *
 * Esce con codice 1 se qualcosa non va, cosi' si puo' incatenare a uno script di deploy.
 */

declare(strict_types=1);

require_once __DIR__ . '/../src/config.php';
require_once __DIR__ . '/../src/i18n.php';

/** @return list<string> i segnaposto `{nome}` presenti in una stringa, ordinati */
function segnaposto(string $testo): array
{
    preg_match_all('/\{([a-z_]+)\}/', $testo, $trovati);
    $unici = array_values(array_unique($trovati[1]));
    sort($unici);
    return $unici;
}

/**
 * I segnaposto che il codice sa risolvere.
 *
 * ☠ Va tenuta allineata a `parametri_pagina()` in `src/layout.php` e alle chiamate a `t()`
 * che passano parametri propri. Non si legge da li' a runtime perche' `layout.php` esegue
 * `applica_lingua()` al caricamento, e un verificatore non deve avere effetti collaterali.
 * Un segnaposto non elencato qui verrebbe stampato in pagina con le graffe.
 */
const SEGNAPOSTO_NOTI = [
    // Dati dell'azienda
    'denominazione', 'titolare', 'piva', 'indirizzo', 'cap', 'citta', 'provincia',
    'paese', 'pec', 'email', 'sito',
    // Indirizzi interni
    'url_privacy', 'url_cookie', 'url_termini', 'url_responsabilita', 'url_note',
    'url_contatti', 'url_it', 'privacy',
    // Passati caso per caso
    'data', 'n',
];

$problemi = [];
$riferimento = dizionario(LINGUA_DEFAULT);

printf("Dizionario di riferimento (%s): %d chiavi\n", LINGUA_DEFAULT, count($riferimento));

foreach (LINGUE as $lingua) {
    if ($lingua === LINGUA_DEFAULT) {
        continue;
    }

    $altro = dizionario($lingua);
    printf("Dizionario %s: %d chiavi\n", $lingua, count($altro));

    foreach (array_diff(array_keys($riferimento), array_keys($altro)) as $mancante) {
        $problemi[] = "[{$lingua}] manca la chiave: {$mancante}";
    }

    // Una chiave in piu' e' meno grave ma va detta lo stesso: o e' un residuo di un testo
    // cancellato, o e' un refuso nel nome, e in quest'ultimo caso da qualche parte c'e'
    // anche una chiave che manca.
    foreach (array_diff(array_keys($altro), array_keys($riferimento)) as $sovrappiu) {
        $problemi[] = "[{$lingua}] chiave in piu', non esiste in "
            . LINGUA_DEFAULT . ': ' . $sovrappiu;
    }

    // Anche la lingua di riferimento va controllata: un segnaposto sbagliato li' stampa le
    // graffe sulla versione che vede la maggior parte dei visitatori.
    foreach ($riferimento as $chiave => $testo) {
        foreach (array_diff(segnaposto($testo), SEGNAPOSTO_NOTI) as $ignoto) {
            $problemi[] = '[' . LINGUA_DEFAULT . "] segnaposto sconosciuto in {$chiave}: "
                . "{{$ignoto}}";
        }
        if (!isset($altro[$chiave])) {
            continue;
        }
        $attesi = segnaposto($testo);
        $trovati = segnaposto($altro[$chiave]);

        // ☠ La regola non e' "gli stessi segnaposto", e' asimmetrica, per una ragione.
        // Perderne uno spezza la frase: `{email}` sparito lascia "scrivi direttamente a ."
        // Averne uno in piu' e' invece legittimo: le pagine legali inglesi usano `{url_it}`
        // per rimandare al testo italiano che fa fede, e quel rimando in italiano non ha
        // senso. Quello che conta e' che ogni segnaposto usato sia risolvibile.
        foreach (array_diff($attesi, $trovati) as $perso) {
            $problemi[] = "[{$lingua}] segnaposto perso in {$chiave}: {{$perso}}";
        }
        foreach (array_diff($trovati, SEGNAPOSTO_NOTI) as $ignoto) {
            $problemi[] = "[{$lingua}] segnaposto sconosciuto in {$chiave}: {{$ignoto}} "
                . '(finirebbe in pagina con le graffe)';
        }
        if (trim($altro[$chiave]) === '') {
            $problemi[] = "[{$lingua}] stringa vuota: {$chiave}";
        }
    }
}

if ($problemi === []) {
    echo "\nDizionari allineati.\n";
    exit(0);
}

echo "\n" . count($problemi) . " problemi:\n";
foreach ($problemi as $problema) {
    echo '  - ' . $problema . "\n";
}
exit(1);

<?php

/**
 * Pagina legale: note-legali.
 *
 * Il contenuto sta nei dizionari, sotto le chiavi `legale.note-legali.*`, perche' va tradotto.
 * Qui resta solo l'aggancio: struttura e intestazione le mette `pagina_legale()`.
 */

declare(strict_types=1);

require_once __DIR__ . '/../../src/layout.php';

pagina_legale('note-legali');

<?php

/**
 * `/riservato`: l'area del proprietario (login, stato di tutte le app, logout).
 *
 * Tutta la logica sta in `src/riservato.php`; qui c'e' il flusso della richiesta e l'HTML.
 * Nessun link dal sito, `noindex` (meta e intestazione), `Disallow` in `robots.txt`.
 *
 * Flusso:
 *   GET  senza sessione      → modulo di login
 *   POST azione=entra        → limite per IP → verifica (sempre completa) → 303 su /riservato,
 *                              oppure il modulo con un messaggio unico, dopo un tempo fisso
 *   GET  con sessione valida → i dati di var/riservato/dati.json
 *   POST azione=esci         → CSRF → sessione distrutta → 303 su /riservato
 */

declare(strict_types=1);

$inizio = microtime(true);

require_once __DIR__ . '/../src/riservato.php';

riservato_intestazioni();

$statoConfig = riservato_stato_configurazione();

if ($statoConfig === 'disattivata') {
    // Senza impronta l'area non esiste: stessa risposta di un indirizzo qualunque.
    http_response_code(404);
    echo '404';
    exit;
}

if ($statoConfig !== 'ok') {
    $motivo = $statoConfig === 'argon2_assente'
        ? 'Questa build di PHP non ha Argon2id (PASSWORD_ARGON2ID non definita): l\'area riservata resta chiusa. Serve PHP compilato con libargon2 o con libsodium.'
        : 'RISERVATO_HASH in config.local.php non e\' un\'impronta Argon2id: l\'area riservata resta chiusa. Rigenerarla come descritto in codebase_reference.md.';
    error_log('[smpmicroapps] area riservata: ' . $motivo);
    http_response_code(503);
    header('Content-Type: text/plain; charset=utf-8');
    echo $motivo;
    exit;
}

riservato_forza_https();
riservato_sessione();

$messaggio = null;
$codice = 200;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $azione = $_POST['azione'] ?? '';

    if ($azione === 'esci') {
        // Con un token sbagliato non si esce: un sito qualunque non deve poter chiudere la sessione.
        if (riservato_csrf_valido($_POST['csrf'] ?? null)) {
            riservato_esci();
        }
        header('Location: ' . RISERVATO_PERCORSO, true, 303);
        exit;
    }

    if ($azione === 'entra') {
        $ip = riservato_ip();
        $residuo = riservato_blocco_residuo($ip);

        if ($residuo === null) {
            error_log('[smpmicroapps] area riservata: var/riservato-tentativi.json non scrivibile, login negato');
            $messaggio = 'Accesso momentaneamente non disponibile. Riprova più tardi.';
            $codice = 503;
        } elseif ($residuo > 0) {
            $messaggio = 'Troppi tentativi non riusciti. Riprova fra ' . max(1, (int) ceil($residuo / 60)) . ' minuti.';
            $codice = 429;
        } else {
            $utente = $_POST['utente'] ?? '';
            $password = $_POST['password'] ?? '';
            // Entrambi i controlli vengono sempre eseguiti: nessuna scorciatoia sul primo che fallisce.
            $credenziali = riservato_verifica_credenziali(
                is_string($utente) ? $utente : '',
                is_string($password) ? $password : ''
            );
            $token = riservato_csrf_valido($_POST['csrf'] ?? null);

            if ($credenziali && $token) {
                riservato_azzera_errori($ip);
                riservato_entra();
                header('Location: ' . RISERVATO_PERCORSO, true, 303);
                exit;
            }

            $blocco = riservato_registra_errore($ip);
            if ($blocco > 0) {
                $messaggio = 'Troppi tentativi non riusciti. Riprova fra ' . (int) ceil($blocco / 60) . ' minuti.';
                $codice = 429;
            } else {
                // ☠ Un messaggio solo per ogni errore: non dice se era sbagliato l'utente o la password.
                $messaggio = 'Accesso non riuscito. Controlla i dati e riprova.';
            }
        }
        riservato_attendi($inizio);
    }
}

$dentro = riservato_autenticato();
$csrf = riservato_csrf();
$dati = $dentro ? riservato_dati() : null;

http_response_code($codice);
header('Content-Type: text/html; charset=utf-8');
?>
<!doctype html>
<html lang="it">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow, noarchive">
<meta name="referrer" content="no-referrer">
<title><?= $dentro ? 'Stato delle app' : 'Area riservata' ?> · <?= e(SITO_NOME) ?></title>
<link rel="icon" href="/assets/img/favicon-32.png" sizes="32x32" type="image/png">
<link rel="stylesheet" href="/assets/style.css?v=9">
</head>
<body class="ris">

<header class="topbar">
  <div class="wrap topbar__inner">
    <span class="brand">
      <img class="brand__mark" src="/assets/img/logo.png" alt="" width="30" height="30">
      <span class="brand__name">SMP<span>MicroApps</span></span>
    </span>
    <?php if ($dentro): ?>
      <form method="post" action="<?= e(RISERVATO_PERCORSO) ?>" class="ris-esci">
        <input type="hidden" name="csrf" value="<?= e($csrf) ?>">
        <input type="hidden" name="azione" value="esci">
        <button type="submit" class="btn btn--ghost btn--piccolo">Esci</button>
      </form>
    <?php endif; ?>
  </div>
</header>

<main id="contenuto">
<?php if (!$dentro): ?>

  <section class="hero hero--slim">
    <div class="wrap">
      <p class="eyebrow">Area riservata</p>
      <h1 class="display display--s">Accesso</h1>
    </div>
  </section>

  <section class="section">
    <div class="wrap">
      <form method="post" action="<?= e(RISERVATO_PERCORSO) ?>" class="form ris-login" autocomplete="on">
        <?php if ($messaggio !== null): ?>
          <div class="alert alert--err" role="alert"><?= e($messaggio) ?></div>
        <?php endif; ?>
        <input type="hidden" name="csrf" value="<?= e($csrf) ?>">
        <input type="hidden" name="azione" value="entra">
        <div class="field">
          <label for="utente">Utente</label>
          <input type="text" id="utente" name="utente" required autocomplete="username"
                 autocapitalize="none" spellcheck="false" maxlength="100">
        </div>
        <div class="field">
          <label for="password">Password</label>
          <input type="password" id="password" name="password" required autocomplete="current-password" maxlength="4096">
        </div>
        <div>
          <button type="submit" class="btn btn--primary">Entra</button>
        </div>
      </form>
    </div>
  </section>

<?php elseif ($dati === null): ?>

  <section class="hero hero--slim">
    <div class="wrap">
      <p class="eyebrow">Area riservata</p>
      <h1 class="display display--s">Stato delle app</h1>
    </div>
  </section>
  <section class="section">
    <div class="wrap">
      <div class="alert alert--err">
        I dati non sono ancora stati caricati (<code>var/riservato/dati.json</code> manca o non è valido).
        Si generano con <code>site/tool/genera_riservato.py</code> e si caricano con
        <code>site/tool/pubblica_riservato.ps1</code>.
      </div>
    </div>
  </section>

<?php else: ?>
<?php
    $app = $dati['app'] ?? [];
    $perNome = [];
    foreach ($app as $a) {
        $perNome[$a['nome']] = $a;
    }
    $generato = strtotime((string) ($dati['generato'] ?? '')) ?: null;
?>
  <section class="hero hero--slim">
    <div class="wrap">
      <p class="eyebrow">Area riservata</p>
      <h1 class="display display--s">Stato delle app</h1>
      <p class="meta">
        Status aggiornato al <?= riservato_md($dati['aggiornamento_status'] ?? '?') ?>
        <?php if ($generato): ?> · dati generati il <?= e(date('d/m/Y \a\l\l\e H:i', $generato)) ?><?php endif; ?>
      </p>
    </div>
  </section>

  <section class="section ris-sezione">
    <div class="wrap">
      <h2 class="ris-titolo">Tabella dello stato</h2>
      <div class="scroll-x ris-scorri">
        <table class="ris-tab ris-tab--stato">
          <thead>
            <tr><th scope="col">App</th><th scope="col">App Store</th><th scope="col">Google Play</th><th scope="col">Sito</th></tr>
          </thead>
          <tbody>
            <?php foreach ($dati['tabella'] ?? [] as $nome): $a = $perNome[$nome] ?? null; if ($a === null) { continue; } ?>
              <tr>
                <th scope="row">
                  <a href="#<?= e(riservato_ancora($a)) ?>"><?= e($a['nome']) ?></a>
                  <?php if (!empty($a['versione'])): ?><span class="ris-versione"><?= e($a['versione']) ?></span><?php endif; ?>
                </th>
                <?php foreach (['app_store', 'play', 'sito'] as $col): $c = $a[$col] ?? []; ?>
                  <td title="<?= e(riservato_testo($c['completo'] ?? '')) ?>">
                    <span class="ris-pallino" aria-hidden="true"><?= e($c['pallino'] ?? '·') ?></span>
                    <?= e($c['breve'] ?? '') ?>
                  </td>
                <?php endforeach; ?>
              </tr>
            <?php endforeach; ?>
          </tbody>
        </table>
      </div>
      <?php if (!empty($dati['legenda'])): ?>
        <p class="ris-legenda"><?= riservato_md($dati['legenda']) ?> · ❌ annullata</p>
      <?php endif; ?>

      <h2 class="ris-titolo">In sospeso</h2>
      <div class="ris-sospeso">
        <?php foreach ($dati['in_sospeso'] ?? [] as $gruppo): ?>
          <div class="ris-sospeso__gruppo">
            <h3><?= e($gruppo['app']) ?></h3>
            <ul>
              <?php foreach ($gruppo['voci'] ?? [] as $voce): ?>
                <li><?= riservato_md($voce) ?></li>
              <?php endforeach; ?>
            </ul>
          </div>
        <?php endforeach; ?>
      </div>
    </div>
  </section>

  <section class="section section--tint ris-sezione">
    <div class="wrap">
      <h2 class="ris-titolo">Tutte le app</h2>
      <nav class="ris-indice" aria-label="Le app">
        <?php foreach ($app as $a): ?>
          <a href="#<?= e(riservato_ancora($a)) ?>" class="ris-chip ris-chip--<?= e($a['stato']) ?>"><?= e($a['nome']) ?></a>
        <?php endforeach; ?>
      </nav>

      <?php foreach ($app as $a): ?>
        <article class="ris-app ris-app--<?= e($a['stato']) ?>" id="<?= e(riservato_ancora($a)) ?>">
          <header class="ris-app__testa">
            <img class="ris-app__icona" src="<?= e($a['icona']) ?>" alt="" width="64" height="64">
            <div class="ris-app__nomi">
              <h3 class="ris-app__nome"><?= e($a['nome']) ?></h3>
              <p class="ris-app__sotto">
                <span class="tag ris-stato ris-stato--<?= e($a['stato']) ?>"><?= e(riservato_etichetta_stato($a['stato'])) ?></span>
                <?php if (!empty($a['fase'])): ?><span><?= e($a['fase']) ?></span><?php endif; ?>
                <?php if (!empty($a['ex'])): ?><span>ex «<?= e($a['ex']) ?>»</span><?php endif; ?>
                <?php if (!empty($a['versione'])): ?><span><?= e($a['versione']) ?></span><?php endif; ?>
              </p>
            </div>
          </header>

          <?php if (!empty($a['claim'])): ?><p class="ris-app__claim"><?= riservato_md($a['claim']) ?></p><?php endif; ?>
          <?php if (!empty($a['sommario'])): ?><p><?= riservato_md($a['sommario']) ?></p><?php endif; ?>
          <?php if (!empty($a['descrizione'])): ?><p class="ris-app__desc"><strong>Problema:</strong> <?= riservato_md($a['descrizione']) ?></p><?php endif; ?>
          <?php if (!empty($a['peso']) && $a['stato'] !== 'pubblicata'): ?><p class="ris-app__desc"><strong>Cosa pesa:</strong> <?= riservato_md($a['peso']) ?></p><?php endif; ?>

          <ul class="ris-app__stati">
            <?php foreach (['App Store' => 'app_store', 'Google Play' => 'play', 'Sito' => 'sito'] as $etichetta => $col): $c = $a[$col] ?? []; ?>
              <li title="<?= e(riservato_testo($c['completo'] ?? '')) ?>"><strong><?= e($etichetta) ?></strong> <?= e($c['pallino'] ?? '') ?> <?= e($c['breve'] ?? '') ?></li>
            <?php endforeach; ?>
          </ul>

          <?php if (!empty($a['decisioni'])): ?>
            <details class="ris-dett">
              <summary>Decisioni (<?= count($a['decisioni']) ?>)</summary>
              <?php foreach ($a['decisioni'] as $d): ?>
                <details class="ris-decisione">
                  <summary><span class="ris-data"><?= e($d['quando']) ?></span> <?= riservato_md($d['titolo']) ?></summary>
                  <?= riservato_blocchi($d['corpo'] ?? []) ?>
                  <?php if (!empty($d['vale_per'])): ?><p class="ris-vale"><strong>Vale per:</strong> <?= riservato_md($d['vale_per']) ?></p><?php endif; ?>
                </details>
              <?php endforeach; ?>
            </details>
          <?php endif; ?>

          <?php if (!empty($a['dettaglio'])): ?>
            <details class="ris-dett">
              <summary>Stato dettagliato</summary>
              <div class="ris-blocchi"><?= riservato_blocchi($a['dettaglio']) ?></div>
            </details>
          <?php endif; ?>
        </article>
      <?php endforeach; ?>
    </div>
  </section>

  <section class="section ris-sezione">
    <div class="wrap">
      <?php foreach ($dati['comuni'] ?? [] as $comune): ?>
        <h2 class="ris-titolo"><?= e($comune['titolo']) ?></h2>
        <details class="ris-dett">
          <summary>Dettaglio</summary>
          <div class="ris-blocchi"><?= riservato_blocchi($comune['blocchi'] ?? []) ?></div>
        </details>
      <?php endforeach; ?>

      <?php if (!empty($dati['decisioni_generali'])): ?>
        <h2 class="ris-titolo">Decisioni che valgono per tutte le app</h2>
        <?php foreach ($dati['decisioni_generali'] as $d): ?>
          <details class="ris-decisione">
            <summary><span class="ris-data"><?= e($d['quando']) ?></span> <?= riservato_md($d['titolo']) ?></summary>
            <?= riservato_blocchi($d['corpo'] ?? []) ?>
            <?php if (!empty($d['vale_per'])): ?><p class="ris-vale"><strong>Vale per:</strong> <?= riservato_md($d['vale_per']) ?></p><?php endif; ?>
          </details>
        <?php endforeach; ?>
      <?php endif; ?>
    </div>
  </section>

<?php endif; ?>
</main>

</body>
</html>

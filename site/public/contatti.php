<?php

/**
 * Contatti: sviluppo su misura, segnalazione problemi, recapiti.
 *
 * ⚑ Un modulo solo con un selettore di argomento, invece di tre moduli separati. Chi
 * arriva con un problema non vuole scegliere fra tre pagine: vuole scrivere. Le ancore
 * `#personalizzato` e `#bug` preselezionano l'argomento, cosi i link dalle altre pagine
 * portano comunque nel posto giusto.
 */

declare(strict_types=1);

require_once __DIR__ . '/../src/layout.php';
require_once __DIR__ . '/../src/contact.php';

$lingua = lingua_corrente();

// ☠ Il token si prende **prima di stampare qualunque cosa**, e il valore si tiene in una
// variabile per usarlo nel modulo piu' sotto.
//
// `csrf_token()` avvia la sessione, e avviare una sessione manda un `Set-Cookie`. Chiamarla
// dentro il modulo, cioe' a meta' documento, significa chiederla quando l'HTML e' gia'
// partito: PHP non puo' piu' mandare intestazioni, il cookie di sessione non arriva al
// browser, e alla POST successiva la sessione e' nuova e vuota. Il risultato e' un modulo
// che rifiuta **ogni** invio dicendo "la pagina e' rimasta aperta troppo a lungo", su una
// pagina appena aperta.
//
// Il difetto restava nascosto finche' il buffer di output di PHP era abbastanza capiente da
// trattenere il documento fino alla fine: cresciuto il testo della pagina, il buffer si
// svuota prima di arrivare al modulo e il modulo smette di funzionare. Una pagina piu' lunga
// non deve poter rompere l'invio.
$csrf = csrf_token();

$errori = [];
$inviato = false;
$notificato = false;
$vecchio = ['nome' => '', 'email' => '', 'argomento' => '', 'app' => '', 'messaggio' => ''];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $post = array_map(
        static fn ($v): string => is_string($v) ? $v : '',
        $_POST
    );
    $vecchio = array_merge($vecchio, array_intersect_key($post, $vecchio));

    $errori = valida_contatto($post);

    if ($errori === ['__bot__']) {
        // Al robot si risponde "grazie" e non si salva niente.
        $errori = [];
        $inviato = true;
    } elseif ($errori === []) {
        $ip = (string) ($_SERVER['REMOTE_ADDR'] ?? '0.0.0.0');
        if (limite_superato($ip)) {
            $errori[] = t('form.err.limite', ['email' => AZIENDA['email']]);
        } else {
            try {
                $pulito = [
                    'nome'      => trim($post['nome']),
                    'email'     => trim($post['email']),
                    'argomento' => $post['argomento'],
                    'app'       => trim($post['app'] ?? ''),
                    // La lingua in cui il modulo e' stato compilato: serve al titolare per
                    // sapere in che lingua rispondere.
                    'lingua'    => $lingua,
                    'messaggio' => trim($post['messaggio']),
                ];
                archivia_contatto($pulito);
                $notificato = notifica_contatto($pulito);
                $inviato = true;
                $vecchio = ['nome' => '', 'email' => '', 'argomento' => '', 'app' => '', 'messaggio' => ''];
            } catch (RuntimeException $e) {
                error_log('[smpmicroapps] archiviazione fallita: ' . $e->getMessage());
                $errori[] = t('form.err.archivio', ['email' => AZIENDA['email']]);
            }
        }
    }
}

$argomenti = argomenti_contatto();

pagina_inizio('contatti.titolo', 'contatti.descrizione', '/contatti');
?>

<section class="hero hero--slim">
  <div class="wrap">
    <p class="eyebrow"><?= t('contatti.eyebrow') ?></p>
    <h1 class="display display--s"><?= t('contatti.h1') ?></h1>
    <p class="lede"><?= t('contatti.lede') ?></p>
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="features" style="margin-bottom:3rem">
      <div class="feature" id="personalizzato">
        <span class="feature__num" aria-hidden="true">&#9670;</span>
        <h3><?= t('contatti.misura.titolo') ?></h3>
        <p><?= t('contatti.misura.testo') ?></p>
      </div>
      <div class="feature" id="bug">
        <span class="feature__num" aria-hidden="true">&#9888;</span>
        <h3><?= t('contatti.bug.titolo') ?></h3>
        <p><?= t('contatti.bug.testo') ?></p>
      </div>
      <div class="feature">
        <span class="feature__num" aria-hidden="true">&#9993;</span>
        <h3><?= t('contatti.recapiti.titolo') ?></h3>
        <p>
          <a href="mailto:<?= e(AZIENDA['email']) ?>"><?= e(AZIENDA['email']) ?></a><br>
          <a href="mailto:<?= e(AZIENDA['pec']) ?>"><?= e(AZIENDA['pec']) ?></a>
          <?= t('contatti.recapiti.pec') ?><br>
          <?= e(AZIENDA['denominazione']) ?><br>
          <?= e(AZIENDA['indirizzo']) ?>, <?= e(AZIENDA['cap']) ?> <?= e(AZIENDA['citta']) ?> (<?= e(AZIENDA['provincia']) ?>)
        </p>
      </div>
    </div>

    <h2 class="title" id="modulo"><?= t('form.titolo') ?></h2>

    <?php if ($inviato): ?>
      <div class="alert alert--ok" role="status">
        <p><strong><?= t('form.ok.titolo') ?></strong> <?= t('form.ok.testo') ?></p>
        <?php if (!$notificato): ?>
          <p style="margin-bottom:0"><?= t('form.ok.salvato') ?></p>
        <?php endif; ?>
      </div>
    <?php endif; ?>

    <?php if ($errori !== []): ?>
      <div class="alert alert--err" role="alert">
        <strong><?= t('form.ko.titolo') ?></strong>
        <ul>
          <?php foreach ($errori as $errore): ?>
            <li><?= e($errore) ?></li>
          <?php endforeach; ?>
        </ul>
      </div>
    <?php endif; ?>

    <form class="form" method="post" action="<?= e(url_per($lingua, '/contatti')) ?>#modulo" novalidate>
      <input type="hidden" name="csrf" value="<?= e($csrf) ?>">

      <!-- Il campo trappola: invisibile a una persona, irresistibile per un robot. -->
      <div class="trap" aria-hidden="true">
        <label for="website"><?= t('form.trappola') ?></label>
        <input type="text" id="website" name="website" tabindex="-1" autocomplete="off">
      </div>

      <div class="field">
        <label for="nome"><?= t('form.nome') ?> <span aria-hidden="true">*</span></label>
        <input type="text" id="nome" name="nome" required maxlength="80"
               autocomplete="name" value="<?= e($vecchio['nome']) ?>">
      </div>

      <div class="field">
        <label for="email"><?= t('form.email') ?> <span aria-hidden="true">*</span></label>
        <input type="email" id="email" name="email" required maxlength="190"
               autocomplete="email" value="<?= e($vecchio['email']) ?>">
        <small><?= t('form.email.aiuto') ?></small>
      </div>

      <div class="field">
        <label for="argomento"><?= t('form.argomento') ?> <span aria-hidden="true">*</span></label>
        <select id="argomento" name="argomento" required>
          <option value=""><?= t('form.scegli') ?></option>
          <?php foreach ($argomenti as $chiave => $etichetta): ?>
            <option value="<?= e($chiave) ?>" <?= $vecchio['argomento'] === $chiave ? 'selected' : '' ?>>
              <?= e($etichetta) ?>
            </option>
          <?php endforeach; ?>
        </select>
      </div>

      <div class="field">
        <label for="app"><?= t('form.app') ?></label>
        <input type="text" id="app" name="app" maxlength="60"
               placeholder="<?= e(t('form.app.ph')) ?>"
               value="<?= e($vecchio['app']) ?>">
        <small><?= t('form.app.aiuto') ?></small>
      </div>

      <div class="field">
        <label for="messaggio"><?= t('form.messaggio') ?> <span aria-hidden="true">*</span></label>
        <textarea id="messaggio" name="messaggio" required minlength="20" maxlength="5000"><?= e($vecchio['messaggio']) ?></textarea>
      </div>

      <label class="check">
        <input type="checkbox" name="consenso" value="si" required>
        <span><?= t('form.consenso', ['privacy' => url_per($lingua, '/legale/privacy')]) ?></span>
      </label>

      <div>
        <button class="btn btn--primary" type="submit"><?= t('form.invia') ?></button>
      </div>

      <p class="meta meta--scuro">
        <?= t('form.obbligatori', ['denominazione' => AZIENDA['denominazione']]) ?>
      </p>
    </form>
  </div>
</section>

<script>
/*
  Preseleziona l'argomento in base all'ancora con cui si arriva.

  ⚑ È l'unico script del sito e non è necessario al funzionamento: senza JavaScript il
  modulo si compila e si invia lo stesso, solo che l'argomento va scelto a mano. Una
  comodità non deve mai diventare un requisito.
*/
(function () {
  var mappa = { '#bug': 'bug', '#personalizzato': 'personalizzato' };
  var scelta = mappa[window.location.hash];
  var campo = document.getElementById('argomento');
  if (scelta && campo && !campo.value) { campo.value = scelta; }
})();
</script>

<?php pagina_fine(); ?>

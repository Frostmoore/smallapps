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
            $errori[] = 'Hai inviato diversi messaggi nell\'ultima ora. '
                . 'Riprova più tardi, oppure scrivi direttamente a ' . AZIENDA['email'] . '.';
        } else {
            try {
                $pulito = [
                    'nome'      => trim($post['nome']),
                    'email'     => trim($post['email']),
                    'argomento' => $post['argomento'],
                    'app'       => trim($post['app'] ?? ''),
                    'messaggio' => trim($post['messaggio']),
                ];
                archivia_contatto($pulito);
                $notificato = notifica_contatto($pulito);
                $inviato = true;
                $vecchio = ['nome' => '', 'email' => '', 'argomento' => '', 'app' => '', 'messaggio' => ''];
            } catch (RuntimeException $e) {
                error_log('[smpmicroapps] archiviazione fallita: ' . $e->getMessage());
                $errori[] = 'Non è stato possibile registrare il messaggio. '
                    . 'Scrivi direttamente a ' . AZIENDA['email'] . ', così non si perde nulla.';
            }
        }
    }
}

$argomenti = argomenti_contatto();

pagina_inizio(
    'Contatti e sviluppo su misura',
    'Scrivi per una segnalazione, una domanda sulle app o per far sviluppare '
        . 'un\'applicazione su misura.',
    '/contatti'
);
?>

<section class="hero hero--slim">
  <div class="wrap">
    <p class="eyebrow">Parliamo</p>
    <h1 class="display display--s">Scrivimi</h1>
    <p class="lede">
      Segnalazioni, domande sulle app e richieste di sviluppo su misura arrivano tutte
      allo stesso posto, e le legge una persona sola.
    </p>
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="features" style="margin-bottom:3rem">
      <div class="feature" id="personalizzato">
        <span class="feature__num" aria-hidden="true">&#9670;</span>
        <h3>Sviluppo su misura</h3>
        <p>
          Applicazioni Android, gestionali, automazioni e strumenti interni. Descrivi il
          problema e il contesto in cui nasce: la prima risposta dice se è fattibile, con
          che tempi e con quale ordine di grandezza di costo.
        </p>
      </div>
      <div class="feature" id="bug">
        <span class="feature__num" aria-hidden="true">&#9888;</span>
        <h3>Segnalare un problema</h3>
        <p>
          Indica il modello di telefono, la versione di Android e cosa stavi facendo quando
          è successo. Con queste tre informazioni un problema si riproduce in pochi minuti;
          senza, spesso non si riproduce affatto.
        </p>
      </div>
      <div class="feature">
        <span class="feature__num" aria-hidden="true">&#9993;</span>
        <h3>Recapiti diretti</h3>
        <p>
          Email: <a href="mailto:<?= e(AZIENDA['email']) ?>"><?= e(AZIENDA['email']) ?></a><br>
          PEC: <a href="mailto:<?= e(AZIENDA['pec']) ?>"><?= e(AZIENDA['pec']) ?></a><br>
          <?= e(AZIENDA['denominazione']) ?><br>
          <?= e(AZIENDA['indirizzo']) ?>, <?= e(AZIENDA['cap']) ?> <?= e(AZIENDA['citta']) ?> (<?= e(AZIENDA['provincia']) ?>)
        </p>
      </div>
    </div>

    <h2 class="title" id="modulo">Il modulo</h2>

    <?php if ($inviato): ?>
      <div class="alert alert--ok" role="status">
        <p><strong>Messaggio ricevuto.</strong> Ti rispondo all'indirizzo che hai indicato,
          di solito entro due giorni lavorativi.</p>
        <?php if (!$notificato): ?>
          <p style="margin-bottom:0">Il messaggio è stato registrato correttamente.</p>
        <?php endif; ?>
      </div>
    <?php endif; ?>

    <?php if ($errori !== []): ?>
      <div class="alert alert--err" role="alert">
        <strong>Il messaggio non è stato inviato.</strong>
        <ul>
          <?php foreach ($errori as $errore): ?>
            <li><?= e($errore) ?></li>
          <?php endforeach; ?>
        </ul>
      </div>
    <?php endif; ?>

    <form class="form" method="post" action="/contatti#modulo" novalidate>
      <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">

      <!-- Il campo trappola: invisibile a una persona, irresistibile per un robot. -->
      <div class="trap" aria-hidden="true">
        <label for="website">Non compilare questo campo</label>
        <input type="text" id="website" name="website" tabindex="-1" autocomplete="off">
      </div>

      <div class="field">
        <label for="nome">Nome <span aria-hidden="true">*</span></label>
        <input type="text" id="nome" name="nome" required maxlength="80"
               autocomplete="name" value="<?= e($vecchio['nome']) ?>">
      </div>

      <div class="field">
        <label for="email">Email <span aria-hidden="true">*</span></label>
        <input type="email" id="email" name="email" required maxlength="190"
               autocomplete="email" value="<?= e($vecchio['email']) ?>">
        <small>Serve solo per risponderti.</small>
      </div>

      <div class="field">
        <label for="argomento">Argomento <span aria-hidden="true">*</span></label>
        <select id="argomento" name="argomento" required>
          <option value="">Scegli…</option>
          <?php foreach ($argomenti as $chiave => $etichetta): ?>
            <option value="<?= e($chiave) ?>" <?= $vecchio['argomento'] === $chiave ? 'selected' : '' ?>>
              <?= e($etichetta) ?>
            </option>
          <?php endforeach; ?>
        </select>
      </div>

      <div class="field">
        <label for="app">App interessata</label>
        <input type="text" id="app" name="app" maxlength="60"
               placeholder="TrashCan, oppure lascia vuoto"
               value="<?= e($vecchio['app']) ?>">
        <small>Per una segnalazione, aggiungi modello del telefono e versione di Android nel messaggio.</small>
      </div>

      <div class="field">
        <label for="messaggio">Messaggio <span aria-hidden="true">*</span></label>
        <textarea id="messaggio" name="messaggio" required minlength="20" maxlength="5000"><?= e($vecchio['messaggio']) ?></textarea>
      </div>

      <label class="check">
        <input type="checkbox" name="consenso" value="si" required>
        <span>
          Ho letto l'<a href="/legale/privacy">informativa privacy</a> e acconsento al
          trattamento dei miei dati per ricevere una risposta a questo messaggio.
        </span>
      </label>

      <div>
        <button class="btn btn--primary" type="submit">Invia il messaggio</button>
      </div>

      <p class="meta" style="color:var(--ink-faint) !important">
        I campi contrassegnati con <span aria-hidden="true">*</span> sono obbligatori.
        Titolare del trattamento: <?= e(AZIENDA['denominazione']) ?>.
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

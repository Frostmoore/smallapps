<?php

/**
 * Un client SMTP minimo, quanto basta a recapitare i messaggi del modulo di contatto.
 *
 * ⚑ **Perche' non `mail()`.** Sul server non c'e' nessun MTA installato: `mail()`
 * restituisce `false` senza spiegazioni, oppure `true` consegnando a un binario che non
 * esiste. In entrambi i casi il messaggio sparisce in silenzio, che e' il modo peggiore in
 * cui puo' fallire un modulo di contatto.
 *
 * ⚑ **Perche' non una libreria.** PHPMailer richiederebbe Composer e un `vendor/` da
 * mantenere aggiornato su un server che ospita anche altro. Per mandare un messaggio di
 * testo a un indirizzo solo bastano centocinquanta righe, che si leggono tutte.
 *
 * ☠ Questo client fa il minimo indispensabile e non e' adatto a inviare campagne: niente
 * coda, niente ritentativi, niente allegati. Serve a recapitare una notifica per volta.
 */

declare(strict_types=1);

final class SmtpError extends RuntimeException
{
}

final class Mailer
{
    /** @param array<string, mixed> $smtp la sezione `smtp` della configurazione */
    public function __construct(private readonly array $smtp)
    {
    }

    public function attivo(): bool
    {
        return ($this->smtp['enabled'] ?? false) === true
            && ($this->smtp['host'] ?? '') !== ''
            && ($this->smtp['to'] ?? '') !== '';
    }

    /**
     * Spedisce un messaggio di solo testo.
     *
     * @param string $replyTo indirizzo a cui risponde il tasto "Rispondi": e' quello di chi
     *                        ha compilato il modulo, non il mittente della busta. Mettere
     *                        il suo indirizzo come mittente farebbe fallire SPF e DMARC,
     *                        perche' il nostro server non e' autorizzato per il suo dominio.
     * @throws SmtpError
     */
    public function invia(string $oggetto, string $corpo, string $replyTo = ''): void
    {
        if (!$this->attivo()) {
            throw new SmtpError('SMTP non configurato');
        }

        $host = (string) $this->smtp['host'];
        $port = (int) $this->smtp['port'];
        $implicito = $port === 465;

        $endpoint = ($implicito ? 'ssl://' : 'tcp://') . $host . ':' . $port;
        $context = stream_context_create([
            'ssl' => ['verify_peer' => true, 'verify_peer_name' => true, 'SNI_enabled' => true],
        ]);

        $socket = @stream_socket_client($endpoint, $errno, $errstr, 15, STREAM_CLIENT_CONNECT, $context);
        if ($socket === false) {
            throw new SmtpError("connessione a {$host}:{$port} fallita: {$errstr}");
        }
        stream_set_timeout($socket, 15);

        try {
            $this->attendi($socket, 220);

            $ehloName = $this->nomeEhlo();
            $this->comando($socket, "EHLO {$ehloName}", 250);

            if (!$implicito) {
                $this->comando($socket, 'STARTTLS', 220);
                // ☠ Senza questa negoziazione la connessione resta in chiaro e la password
                // viaggia in base64, cioe' leggibile da chiunque stia sul percorso. Se il
                // passaggio a TLS fallisce si interrompe tutto: meglio nessuna notifica di
                // una credenziale regalata.
                $ok = stream_socket_enable_crypto(
                    $socket,
                    true,
                    STREAM_CRYPTO_METHOD_TLS_CLIENT
                );
                if ($ok !== true) {
                    throw new SmtpError('STARTTLS fallito');
                }
                // Dopo STARTTLS il dialogo ricomincia: il server puo' annunciare capacita'
                // diverse su canale cifrato, fra cui proprio AUTH.
                $this->comando($socket, "EHLO {$ehloName}", 250);
            }

            $this->autentica($socket);

            $this->comando($socket, 'MAIL FROM:<' . $this->smtp['from'] . '>', 250);
            $this->comando($socket, 'RCPT TO:<' . $this->smtp['to'] . '>', 250);
            $this->comando($socket, 'DATA', 354);

            $this->scrivi($socket, $this->componi($oggetto, $corpo, $replyTo) . "\r\n.\r\n");
            $this->attendi($socket, 250);

            $this->comando($socket, 'QUIT', 221);
        } finally {
            fclose($socket);
        }
    }

    /**
     * Il nome annunciato nell'EHLO.
     *
     * Molti server rifiutano un EHLO con un nome che non somiglia a un dominio. Si usa
     * quello del mittente, che esiste per definizione.
     */
    private function nomeEhlo(): string
    {
        $from = (string) $this->smtp['from'];
        $at = strrpos($from, '@');
        return $at === false ? 'localhost' : substr($from, $at + 1);
    }

    /** @param resource $socket */
    private function autentica($socket): void
    {
        $user = (string) $this->smtp['username'];
        $pass = (string) $this->smtp['password'];
        if ($user === '') {
            return;
        }

        $this->comando($socket, 'AUTH LOGIN', 334);
        $this->comando($socket, base64_encode($user), 334);
        $this->comando($socket, base64_encode($pass), 235);
    }

    /** @param resource $socket */
    private function comando($socket, string $riga, int $atteso): void
    {
        $this->scrivi($socket, $riga . "\r\n");
        $this->attendi($socket, $atteso);
    }

    /** @param resource $socket */
    private function scrivi($socket, string $dati): void
    {
        if (fwrite($socket, $dati) === false) {
            throw new SmtpError('scrittura sul socket fallita');
        }
    }

    /**
     * Legge la risposta e verifica il codice.
     *
     * ☠ Una risposta SMTP puo' occupare piu' righe: quelle intermedie hanno un trattino
     * dopo il codice (`250-`), l'ultima uno spazio (`250 `). Fermarsi alla prima riga
     * lascia il resto nel buffer e manda fuori sincrono tutto il dialogo successivo, con
     * errori che sembrano casuali.
     *
     * @param resource $socket
     */
    private function attendi($socket, int $atteso): string
    {
        $tutto = '';
        do {
            $riga = fgets($socket, 1024);
            if ($riga === false) {
                throw new SmtpError('nessuna risposta dal server (timeout?)');
            }
            $tutto .= $riga;
            $continua = strlen($riga) >= 4 && $riga[3] === '-';
        } while ($continua);

        $codice = (int) substr($tutto, 0, 3);
        if ($codice !== $atteso) {
            throw new SmtpError("atteso {$atteso}, ricevuto: " . trim($tutto));
        }
        return $tutto;
    }

    /**
     * Compone il messaggio grezzo.
     *
     * ☠ Ogni valore che finisce in un'intestazione viene ripulito da CR e LF. Senza,
     * un indirizzo contenente un a capo permetterebbe a chi compila il modulo di
     * aggiungere intestazioni a piacere, per esempio un `Bcc:` verso mille destinatari:
     * il modulo di contatto diventerebbe un rilancio per lo spam.
     */
    private function componi(string $oggetto, string $corpo, string $replyTo): string
    {
        $pulisci = static fn (string $v): string => str_replace(["\r", "\n"], ' ', $v);

        $intestazioni = [
            'From: ' . $this->codificaNome((string) $this->smtp['fromName'])
                . ' <' . $pulisci((string) $this->smtp['from']) . '>',
            'To: <' . $pulisci((string) $this->smtp['to']) . '>',
            'Subject: ' . $this->codificaNome($oggetto),
            'Date: ' . date('r'),
            'MIME-Version: 1.0',
            'Content-Type: text/plain; charset=UTF-8',
            'Content-Transfer-Encoding: 8bit',
        ];

        if ($replyTo !== '' && filter_var($replyTo, FILTER_VALIDATE_EMAIL) !== false) {
            $intestazioni[] = 'Reply-To: <' . $pulisci($replyTo) . '>';
        }

        // ☠ Dot stuffing: una riga del corpo che comincia con un punto chiuderebbe la fase
        // DATA in anticipo, troncando il messaggio. Il protocollo vuole il punto raddoppiato.
        $corpoNormalizzato = preg_replace('/\r\n|\r|\n/', "\r\n", $corpo) ?? $corpo;
        $corpoNormalizzato = preg_replace('/^\./m', '..', $corpoNormalizzato) ?? $corpoNormalizzato;

        return implode("\r\n", $intestazioni) . "\r\n\r\n" . $corpoNormalizzato;
    }

    /** Un'intestazione con accenti va codificata, altrimenti arriva illeggibile. */
    private function codificaNome(string $valore): string
    {
        $pulito = str_replace(["\r", "\n"], ' ', $valore);
        return preg_match('/^[\x20-\x7E]*$/', $pulito) === 1
            ? $pulito
            : '=?UTF-8?B?' . base64_encode($pulito) . '?=';
    }
}

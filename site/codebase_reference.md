# codebase_reference.md — Vetrina smpmicroapps.it

> Atlante del **sito vetrina** delle MicroApps.
> **Obiettivo**: capire il sito, trovare ciò che serve e modificarlo **senza aprire i file**.
>
> **Aggiornato al**: 2026-09-11 · **Stato**: online su <https://smpmicroapps.it>
> **Stack**: PHP 8.3 su php-fpm, nginx, zero dipendenze, zero build step
> **Repo**: dentro il monorepo `microapps`, cartella `site/` (Gitea + mirror GitHub)

---

## 1. Dove sta cosa

| Cerchi… | Vai in… |
|---|---|
| L'elenco delle app e i loro testi | `src/apps.php` |
| I dati dell'azienda (P. IVA, sede, PEC) | `src/config.php`, costante `AZIENDA` |
| Intestazione, menu, pie' di pagina | `src/layout.php` |
| Tutto il CSS | `public/assets/style.css` |
| La home con la griglia delle card | `public/index.php` |
| La pagina di TrashCan | `public/trashcan.php` |
| Il modulo di contatto (pagina) | `public/contatti.php` |
| Validazione, antispam, archiviazione | `src/contact.php` |
| L'invio della mail | `src/mailer.php` |
| Le pagine legali | `public/legale/*.php` |
| Credenziali SMTP | `config.local.php` sul server, **non versionato** |
| La configurazione nginx | `deploy/smpmicroapps.it.nginx` |
| Far girare il sito in locale | `deploy/router.php` |

---

## 2. Albero dei file

```
site/
├── config.example.php          modello della configurazione, VERSIONATO, senza segreti
├── config.local.php            solo sul server: credenziali SMTP. NON versionato.
├── src/
│   ├── config.php              costante AZIENDA, SITO_URL, config(), e()
│   ├── apps.php                il catalogo: catalogo(), app_per_slug(), link_play()
│   ├── layout.php              pagina_inizio(), pagina_fine(), intestazione_legale()
│   ├── contact.php             validazione, CSRF, trappola, limite, archivio, notifica
│   └── mailer.php              client SMTP minimo (classi Mailer, SmtpError)
├── public/                     ← LA DOCUMENT ROOT. Tutto il resto sta fuori.
│   ├── index.php               home: titolo grande, griglia delle app, tre principi
│   ├── trashcan.php            vetrina di TrashCan: problema, funzioni, prezzi, privacy
│   ├── contatti.php            i tre canali + il modulo
│   ├── sitemap.php             servita come /sitemap.xml
│   ├── robots.txt
│   ├── legale/
│   │   ├── note-legali.php     l'impressum italiano (d.lgs. 70/2003, art. 2250 c.c.)
│   │   ├── privacy.php         informativa artt. 13-14 GDPR
│   │   ├── cookie.php          un solo cookie tecnico, niente banner
│   │   ├── termini.php         condizioni di servizio e licenza d'uso
│   │   └── responsabilita.php  limitazione di responsabilita'
│   └── assets/
│       ├── style.css           tutto il CSS, un file solo
│       └── img/
│           ├── favicon.svg     quattro caselle su fondo verde
│           └── trashcan.png    256x256, derivata dal logo dell'app
├── deploy/
│   ├── smpmicroapps.it.nginx   il vhost, PRIMA che certbot ci aggiunga il blocco TLS
│   └── router.php              solo per `php -S`: riproduce le URL pulite di nginx
└── var/                        solo sul server: messaggi ricevuti e contatore. NON versionato.
```

---

## 3. Le regole non negoziabili

### ⚑ Zero terze parti

Il sito **non carica niente da fuori**: nessun font di Google, nessuna CDN, nessun
analytics, nessun pulsante social, nessuna mappa. Non è minimalismo estetico: caricare un
font da Google significa trasmettere a Google l'indirizzo IP di ogni visitatore, cioè un
trasferimento di dati personali a un terzo senza base giuridica né consenso. Con zero terze
parti:

- la cookie policy dice il vero in cinque righe;
- non serve nessun banner dei cookie;
- la `Content-Security-Policy` può essere `default-src 'self'`.

**Aggiungere una sola risorsa esterna rende false tre pagine legali.** Se serve davvero, si
self-hosta.

### ⚑ Il catalogo è una sola lista

`src/apps.php` è l'unica fonte di verità. Home, sitemap e pagine di dettaglio leggono da lì.
**Ogni microapp del monorepo ha una card in home**, anche quelle non ancora pubblicate: in
grigio, con l'etichetta "In arrivo" e senza link. Quando si aggiunge una app al monorepo si
aggiunge una voce qui nello stesso giro, altrimenti comparirà in home e non nella sitemap,
o viceversa, e non se ne accorgerà nessuno.

### ⚑ I dati dell'azienda stanno in un posto solo

La costante `AZIENDA` in `src/config.php`. Compaiono in sei pagine: ricopiarli
significherebbe, alla prima variazione, un sito che dichiara due sedi diverse. Per le note
legali non è un dettaglio estetico, è il contenuto stesso dell'obbligo.

### ⚑ Le pagine legali descrivono il software vero

Le affermazioni dell'informativa privacy sono verificabili nel codice: i dati restano nel
database locale dell'app, l'unico dato che lascia il dispositivo è quello della verifica
dell'acquisto, e il server delle licenze conserva le colonne elencate in
`server/src/db/schema.sql`. **Se il codice cambia, l'informativa cambia lo stesso giorno**:
un'informativa che descrive un trattamento diverso da quello reale è una violazione in sé.

---

## 4. Le funzioni

### `src/config.php`

| Funzione | Firma | Cosa fa |
|---|---|---|
| `config` | `config(): array` | La configurazione, con i valori di `config.example.php` come ripiego. Non lancia se `config.local.php` manca. |
| `e` | `e(?string $value): string` | `htmlspecialchars` con `ENT_QUOTES \| ENT_SUBSTITUTE`, UTF-8. Nome corto perché compare centinaia di volte. |

Costanti: `AZIENDA` (array), `SITO_URL` (`https://smpmicroapps.it`), `SITO_NOME`.

### `src/apps.php`

| Funzione | Firma | Cosa fa |
|---|---|---|
| `catalogo` | `catalogo(): array` | Le app indicizzate per slug, nell'ordine di presentazione. |
| `app_per_slug` | `app_per_slug(string $slug): ?array` | Una app, o `null`. |
| `link_play` | `link_play(array $app): ?string` | L'indirizzo su Play, o `null` finché `suPlay` è `false`. |

Campi di una voce del catalogo:

| Campo | Tipo | Significato |
|---|---|---|
| `nome` | string | "TrashCan" |
| `claim` | string | La frase in grassetto sulla card |
| `sommario` | string | Tre righe di descrizione |
| `accento` | string | Colore esadecimale, diventa `--card-accent` nella card |
| `logo` | ?string | Percorso dell'immagine, o `null` per il segnaposto con l'iniziale |
| `pubblicata` | bool | Decide se la card è un link o un riquadro grigio |
| `packageId` | string | Il nome del pacchetto Android, da cui si costruisce l'indirizzo Play |
| `suPlay` | bool | `false` finché l'app non è davvero pubblicata: il bottone resta spento |
| `prezzoPro` | ?string | "2,99 €" |

### `src/layout.php`

| Funzione | Firma |
|---|---|
| `pagina_inizio` | `pagina_inizio(string $titolo, string $descrizione, string $canonical = '/'): void` |
| `pagina_fine` | `pagina_fine(): void` |
| `intestazione_legale` | `intestazione_legale(string $titolo, string $aggiornata, string $sommario): void` |

### `src/contact.php`

| Funzione | Firma | Cosa fa |
|---|---|---|
| `argomenti_contatto` | `argomenti_contatto(): array` | Le cinque voci del selettore. |
| `sessione` | `sessione(): void` | Avvia la sessione con cookie `HttpOnly`, `SameSite=Lax`, `Secure` su HTTPS. Idempotente. |
| `csrf_token` | `csrf_token(): string` | 32 byte casuali in esadecimale, per sessione. |
| `valida_contatto` | `valida_contatto(array $post): list<string>` | Gli errori. Vuoto = va bene. `['__bot__']` = trappola scattata. |
| `limite_superato` | `limite_superato(string $ip): bool` | Contatore per IP su file, con `flock`. |
| `archivia_contatto` | `archivia_contatto(array $post): void` | Append su `var/contatti.jsonl`. **Lancia** se non riesce. |
| `notifica_contatto` | `notifica_contatto(array $post): bool` | Manda la mail. **Non lancia**: torna `false`. |

### `src/mailer.php`

`final class Mailer` — `__construct(array $smtp)`.

| Metodo | Firma | Cosa fa |
|---|---|---|
| `attivo` | `attivo(): bool` | Vero solo se `enabled`, `host` e `to` ci sono. |
| `invia` | `invia(string $oggetto, string $corpo, string $replyTo = ''): void` | Lancia `SmtpError` in caso di guasto. |

Supporta porta 465 (TLS implicito) e 587 (STARTTLS), autenticazione `AUTH LOGIN`.

---

## 5. Le rotte

| URL | File servito | Note |
|---|---|---|
| `/` | `public/index.php` | Via `index index.php` |
| `/trashcan` | `public/trashcan.php` | Via `@php` |
| `/contatti` | `public/contatti.php` | Accetta GET e POST |
| `/legale/note-legali` | `public/legale/note-legali.php` | |
| `/legale/privacy` | `public/legale/privacy.php` | |
| `/legale/cookie` | `public/legale/cookie.php` | |
| `/legale/termini` | `public/legale/termini.php` | |
| `/legale/responsabilita` | `public/legale/responsabilita.php` | |
| `/sitemap.xml` | `public/sitemap.php` | `rewrite ^ /sitemap.php last` |
| `/robots.txt` | statico | |
| qualunque altro | 404 | |

---

## 6. La configurazione

| Chiave | Default | Significato |
|---|---|---|
| `smtp.enabled` | `false` | Con `false` il modulo salva e non notifica. |
| `smtp.host` | — | Server di posta in uscita. |
| `smtp.port` | `465` | 465 TLS implicito, 587 STARTTLS. Nessun altro valore è supportato. |
| `smtp.username` / `smtp.password` | — | Vuoto disattiva `AUTH`. |
| `smtp.from` / `smtp.fromName` | — | Il mittente della busta. Deve essere un dominio autorizzato, o SPF e DMARC mandano tutto nello spam. |
| `smtp.to` | — | Dove arrivano i messaggi. |
| `storageDir` | `site/var` | Fuori dalla webroot. |
| `rateLimit.maxPerHour` | `5` | Per indirizzo IP. |

---

## 7. Difese del modulo di contatto

| Difesa | Come | Perché |
|---|---|---|
| Token CSRF | `hash_equals` su un valore di sessione | Senza, un sito qualunque può far inviare messaggi al visitatore a nostro nome |
| Trappola (honeypot) | Campo `website` fuori schermo, `tabindex="-1"` | Un robot compila tutto quello che trova. Se è pieno si risponde "grazie" **senza salvare**: dire "sei un robot" insegna al robot come passare la prossima volta |
| Limite per IP | 5 all'ora, contatore su file con `flock` | Una sessione la controlla il client; un file no |
| Consenso esplicito | Casella obbligatoria | Base giuridica del trattamento |
| Lunghezze | nome 2-80, email ≤190, messaggio 20-5000 | |
| Anti header injection | CR e LF rimossi da ogni intestazione | Senza, un a capo nell'indirizzo permette di aggiungere un `Bcc:` verso mille destinatari |

L'indirizzo IP **non viene conservato**: del valore `IP + sale` si tiene solo un troncamento
dell'hash SHA-256, per un'ora.

---

## 8. Trappole già disinnescate

| Sintomo | Causa | Dove |
|---|---|---|
| `smpmicroapps.it` mostrava **flamingnews** | nessun `server` block dichiarava quel nome, e nginx serve il primo blocco in ordine di caricamento, che alfabeticamente era flamingnews. Non c'era nessun `default_server` | è bastato aggiungere il vhost |
| `/trashcan` restituiva il **codice sorgente PHP**, e la POST del modulo dava 405 | `try_files $uri $uri.php $uri/ =404`: quando try_files trova un argomento **intermedio** lo serve dal blocco corrente, che non ha handler FastCGI. Solo l'ultimo argomento rientra nel confronto delle location. Con una GET si vedeva una pagina di testo simile a quella giusta, quindi il difetto passava inosservato | `location / { try_files $uri $uri/ @php; }` + `location @php { rewrite ^(.*)$ $1.php last; }` |
| Le immagini non caricavano provando in locale | il server integrato di PHP (`php -S`) serve **una richiesta per volta**: il browser che chiede CSS e immagini insieme si vede rifiutare le richieste in coda | è un limite del solo ambiente di sviluppo, nginx non ne soffre |
| Frasi come "1 su 4 sono disponibili" | un conteggio infilato in una frase non concorda né al singolare né al plurale | due rami nel template |
| Uno script che parte da PowerShell verso `bash -s` dà `syntax error: unexpected end of file` | le fini riga di Windows: `\r` finisce dentro i comandi | si scrive lo script in un file con fini riga Unix e si passa da `ssh ... "cat > file && bash file"` |

---

## 9. Come si mette online

```bash
# 1. Pacchetto (da Git Bash, nella radice del monorepo)
tar -czf /tmp/site.tar.gz --exclude=var --exclude=config.local.php \
    -C site public src config.example.php deploy

# 2. Caricamento (da PowerShell: ssh di Git Bash non vede l'agente di Windows)
scp /tmp/site.tar.gz clawserver:/tmp/site.tar.gz

# 3. Scompattamento e permessi
ssh clawserver "sudo tar -xzf /tmp/site.tar.gz -C /var/www/smpmicroapps"
ssh clawserver "sudo chown -R www-data:www-data /var/www/smpmicroapps/var"
ssh clawserver "sudo chown -R root:www-data /var/www/smpmicroapps/public /var/www/smpmicroapps/src"
```

⚑ `public/` e `src/` appartengono a **root** e php-fpm li legge soltanto: un sito che non può
riscrivere il proprio codice è un sito che una falla non riesce a modificare. Solo `var/` è
scrivibile da `www-data`.

☠ Se si sostituisce `/etc/nginx/sites-available/smpmicroapps.it` con la versione del repo si
perdono i blocchi TLS che certbot ci aveva aggiunto. Basta rilanciare certbot subito dopo:
riusa il certificato esistente e li rimette.

```bash
sudo certbot --nginx -d smpmicroapps.it -d www.smpmicroapps.it --redirect
```

☠ Su questo server vivono anche `hesclaw.ovh` e `wa-webhook.hesclaw.ovh`, che appartengono a
OpenClaw, e `lic.smpmicroapps.it`, che è il License Server. **Si aggiungono file nuovi, non
si modifica niente di esistente.**

### In locale

```bash
cd site
php -S 127.0.0.1:8099 -t public deploy/router.php
```

---

## 10. Cosa NON esiste

- **Nessun pannello di amministrazione**: i messaggi ricevuti si leggono con
  `sudo cat /var/www/smpmicroapps/var/contatti.jsonl`.
- **Nessuna pagina di dettaglio** per Full Freezer, Scorte Calore e Film Tracker: le card
  ci sono ma non sono link. La pagina si crea alla chiusura della fase che costruisce l'app.
- **Nessuna versione inglese**: il sito è solo in italiano, mentre le app sono bilingui.
- **Nessun blog, nessuna newsletter, nessun analytics.**
- **Nessun test automatico**: il sito è statico nella sostanza, e la verifica è la lista di
  controllo del §11.

---

## 11. Verifica dopo ogni modifica

```powershell
# Tutte le pagine rispondono ed eseguono PHP invece di mostrarne il sorgente
foreach ($u in @('/','/trashcan','/contatti','/legale/privacy','/legale/note-legali',
                 '/legale/cookie','/legale/termini','/legale/responsabilita','/sitemap.xml')) {
  $r = Invoke-WebRequest "https://smpmicroapps.it$u" -UseBasicParsing
  "{0,-28} {1} {2}" -f $u, $r.StatusCode, $(if ($r.Content -match '<\?php') {'SORGENTE ESPOSTO'} else {'ok'})
}

# I file riservati non sono raggiungibili: devono dare tutti 404 o 403
foreach ($u in @('/config.local.php','/src/config.php','/var/contatti.jsonl')) { ... }
```

Il controllo `<?php` nel corpo della risposta non è pignoleria: è esattamente il difetto del
§8 che una semplice verifica del codice 200 non avrebbe mai trovato.

---

## 12. Debito tecnico aperto

| Cosa | Perché è rimandato | Quando |
|---|---|---|
| **SMTP non configurato** | serve una casella vera con le sue credenziali, che deve fornire il proprietario. Fino ad allora i messaggi si salvano e non arrivano notifiche | appena ci sono le credenziali di `info@smp-digital.it` |
| **Nessuna pagina per le altre tre app** | non esistono ancora | alla chiusura di F4, F5, F6 |
| **Numero REA assente** | non fornito. Se c'è iscrizione al Registro delle Imprese va indicato (art. 2250 c.c.) | va riempita `AZIENDA['rea']` in `src/config.php` |
| **Nessuna schermata delle app** | la pagina di TrashCan descrive a parole; qualche immagine venderebbe meglio | quando ci saranno gli screenshot per Play, che servono comunque |
| **Il bottone Play è spento** | l'app non è ancora pubblicata | si mette `suPlay => true` in `src/apps.php`, e basta |
| **Nessun backup dell'archivio messaggi** | `var/contatti.jsonl` vive solo sul server | quando arriveranno messaggi che valga la pena non perdere |

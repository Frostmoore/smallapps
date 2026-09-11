# codebase_reference.md — Vetrina smpmicroapps.it

> Atlante del **sito vetrina** delle MicroApps.
> **Obiettivo**: capire il sito, trovare ciò che serve e modificarlo **senza aprire i file**.
>
> **Aggiornato al**: 2026-09-11 · **Stato**: online su <https://smpmicroapps.it>
> **Stack**: PHP 8.3 su php-fpm, nginx, zero dipendenze, zero build step
> **Lingue**: italiano alla radice, inglese sotto `/en` (vedi §3bis)
> **Repo**: dentro il monorepo `microapps`, cartella `site/` (Gitea + mirror GitHub)

---

## 1. Dove sta cosa

| Cerchi… | Vai in… |
|---|---|
| L'elenco delle app (dati, non testi) | `src/apps.php` |
| **Tutti i testi visibili, in italiano** | `src/lang/it.php` e `src/lang/it.legale.php` |
| **Tutti i testi visibili, in inglese** | `src/lang/en.php` e `src/lang/en.legale.php` |
| Rilevamento della lingua, `t()`, `url_per()` | `src/i18n.php` |
| Controllare che le due lingue siano allineate | `deploy/verifica_lingue.php` |
| I dati dell'azienda (P. IVA, sede, PEC) | `src/config.php`, costante `AZIENDA` |
| Intestazione, menu, pie' di pagina | `src/layout.php` |
| Il menu a panino e il sottomenù | `src/layout.php` + `public/assets/menu.js` (§3ter) |
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
│   ├── config.php              costante AZIENDA, SITO_URL, config(), e(), parametri_azienda()
│   ├── i18n.php                lingua corrente, rilevamento, t(), url_per(), applica_lingua()
│   ├── lang/
│   │   ├── it.php              interfaccia e testi commerciali, italiano
│   │   ├── it.legale.php       i corpi delle cinque pagine legali, italiano
│   │   ├── en.php              interfaccia e testi commerciali, inglese
│   │   └── en.legale.php       i corpi delle cinque pagine legali, inglese
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
│   ├── legale/                 cinque file da due righe: il contenuto sta nei dizionari
│   │   ├── note-legali.php     l'impressum italiano (d.lgs. 70/2003, art. 2250 c.c.)
│   │   ├── privacy.php         informativa artt. 13-14 GDPR
│   │   ├── cookie.php          due cookie tecnici, niente banner
│   │   ├── termini.php         condizioni di servizio e licenza d'uso
│   │   └── responsabilita.php  limitazione di responsabilita'
│   └── assets/
│       ├── style.css           tutto il CSS, un file solo
│       ├── menu.js             il menu a panino, quaranta righe (§3ter)
│       └── img/
│           ├── logo.png        128x128, il cubo SMP per la barra
│           ├── favicon-32.png  la scheda del browser
│           ├── favicon-192.png la schermata iniziale su Android
│           ├── apple-touch-icon.png  180x180 su fondo pieno, per iOS
│           ├── flag-it.svg     il tricolore
│           ├── flag-gb.svg     la Union Jack
│           └── trashcan.png    256x256, derivata dal logo dell'app
├── deploy/
│   ├── smpmicroapps.it.nginx   il vhost, PRIMA che certbot ci aggiunga il blocco TLS
│   ├── verifica_lingue.php     controlla che i dizionari abbiano le stesse chiavi
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

Gli unici script sono nostri e serviti da qui: la riga che marca il documento come "con
JavaScript" e `assets/menu.js`. Nessuna libreria, nessun bundler, nessun passo di build.

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

## 3bis. Le due lingue

### Lo schema degli indirizzi

Italiano **alla radice**, inglese **sotto `/en`**: `/trashcan` e `/en/trashcan` sono la
stessa pagina. Non ci sono file duplicati: nginx toglie il prefisso con una
`rewrite ... last` e la richiesta prosegue sullo stesso file.

⚑ **Perché l'italiano non sta sotto `/it`.** Il sito era già online e indicizzato con gli
indirizzi senza prefisso. Spostarli tutti avrebbe richiesto una catena di redirect
permanenti per non perdere posizionamento e per non rompere i link già condivisi, in cambio
di nient'altro che simmetria.

☠ **La lingua si legge da `REQUEST_URI`, non da una variabile di nginx.** Dopo una
`rewrite ... last` l'URI riscritto cambia, ma `REQUEST_URI` conserva **l'indirizzo
originale**. Leggerlo da lì fa funzionare il meccanismo identico sotto nginx e sotto
`php -S`, senza parametri FastCGI da tenere allineati in due file di configurazione.

### Come si sceglie la lingua

| Situazione | Cosa succede |
|---|---|
| Cookie `ma_lang` presente | Vale la pagina che si sta visitando. Nessun redirect. |
| Nessun cookie, `Accept-Language` assente o `*` | Resta l'italiano. |
| Nessun cookie, l'intestazione preferisce l'italiano | Resta l'italiano. |
| Nessun cookie, l'intestazione preferisce l'inglese | 302 verso la stessa pagina sotto `/en`. |
| Nessun cookie, l'intestazione nomina **altre** lingue (`fr`, `de`) | 302 verso l'inglese. |

☠ **Assente e "nessuna delle due" sono casi diversi, apposta.** I crawler dei motori di
ricerca spesso non mandano `Accept-Language`: rimbalzarli sull'inglese farebbe apparire la
home italiana come una pagina che redirige sempre. Ma chi ha il browser in francese non
legge l'italiano più di quanto legga l'inglese, e mandarlo sulla versione italiana perché è
quella predefinita significa dargli una pagina che non capisce.

### Come si ricorda la scelta

⚑ **Non esiste nessun endpoint per cambiare lingua, ed è voluto.** La bandierina è un link
normale verso l'altra versione della **stessa pagina**, e visitarla *è* la scelta: il cookie
viene scritto con la lingua della pagina che si sta guardando, e il rilevamento automatico
scatta **solo quando il cookie non c'è**. Così non può mai rimbalzare indietro chi ha appena
cliccato la bandiera, che è la trappola classica di questo meccanismo.

☠ Il `?l=` sui soli link della bandierina copre chi ha i cookie bloccati: sopprime il
rilevamento per quella richiesta. Senza, un browser in inglese e senza cookie tornerebbe
all'inglese a ogni clic sulla bandiera italiana, e la bandiera sembrerebbe rotta.

`Vary: Accept-Language, Cookie` viene mandato **sempre**, anche quando non si redirige:
senza, una cache intermedia servirebbe la copia italiana a un visitatore inglese.

### I dizionari

Due file per lingua, uniti da `dizionario()`:

| File | Contiene |
|---|---|
| `src/lang/it.php`, `en.php` | interfaccia, navigazione, piè, home, pagina TrashCan, contatti, modulo |
| `src/lang/it.legale.php`, `en.legale.php` | i corpi HTML delle cinque pagine legali |

Le chiavi sono **piatte e puntate** (`home.hero.titolo`): una ricerca testuale trova al primo
colpo dove una frase è scritta e dove viene usata.

☠ **I valori possono contenere HTML e `t()` non li ripulisce**, perché i testi hanno
grassetti e collegamenti. Non deve quindi finirci MAI niente che provenga da un utente: i
*parametri* passati a `t()`, quelli sì, vengono ripuliti.

☠ I testi legali usano **NOWDOC** e non heredoc: nel nowdoc PHP non interpreta niente,
quindi un simbolo di dollaro resta tale e i segnaposto `{denominazione}` restano intatti. Con
l'heredoc un dollaro seguito da una lettera diventerebbe una variabile inesistente e la frase
perderebbe una parola, senza nessun errore.

### Cosa NON si traduce

- **Le chiavi degli argomenti del modulo** (`bug`, `personalizzato`, ...): sono il valore
  inviato e finiscono nell'archivio. Tradurle spezzerebbe ogni riga già salvata.
- **La mail di notifica**: la legge chi gestisce la casella, non chi ha scritto. Resta in
  italiano, con la lingua del visitatore su una riga a parte per sapere come rispondere.
- **I nomi delle app**: TrashCan si chiama TrashCan in tutte le lingue.

### Il testo che fa fede

Le pagine legali inglesi si aprono con un riquadro che dichiara la **versione italiana come
testo che governa**, e rimandano a essa con il segnaposto `{url_it}`. L'azienda è italiana,
il contratto è regolato dalla legge italiana e i richiami sono ad articoli italiani: una
traduzione che venisse letta come restrittiva di un diritto sarebbe un problema, e dirlo
apertamente lo risolve.

### La verifica

```bash
cd site
php deploy/verifica_lingue.php
```

Controlla che i due dizionari abbiano le stesse chiavi, che nessuna stringa sia vuota, che
nessuna traduzione **perda** un segnaposto e che nessun segnaposto usato sia sconosciuto al
codice. Esce con codice 1 se qualcosa non va. **Va lanciato dopo ogni modifica ai testi**:
una chiave mancante non produce nessun errore, produce una frase italiana in mezzo a una
pagina inglese, e non la segnala nessuno.

---

## 3ter. Il menu

### Cosa c'è nella barra

Logo, nome, tre voci e il selettore di lingua. La prima voce, **Le app**, ha un sottomenù con
le app **pubblicate**: oggi solo TrashCan. Quelle non ancora fatte non ci sono, perché nel
sottomenù non avrebbe senso una voce grigia che non porta da nessuna parte: in home la card
comunica qualcosa, qui sarebbe solo una riga morta.

Il sottomenù si costruisce dal catalogo, filtrando su `pubblicata`. **Una app nuova compare
da sola** appena la sua voce entra in `src/apps.php` con `pubblicata => true`.

### Sopra gli 860 pixel

Barra orizzontale. Il sottomenù è un pannello a discesa che si apre con `:hover` **e** con
`:focus-within`.

☠ Servono tutti e due. Il solo `hover` renderebbe il sottomenù irraggiungibile da tastiera, e
le voci dentro resterebbero focalizzabili ma invisibili: il fuoco sparirebbe dentro un
pannello che non si vede, che è peggio che non avere il menù.

☠ Il pannello parte a `top: 100%`, cioè esattamente al bordo inferiore della voce, **senza
stacco**. Un solo pixel di distanza basta a farlo richiudere mentre ci si sposta sopra col
puntatore, e il menù diventa inutilizzabile senza che si capisca perché.

⚑ Su un dispositivo a tocco più largo di 860px (un tablet in orizzontale) il tocco su "Le
app" **naviga** invece di aprire il pannello, perché il tocco non produce hover. È il
comportamento voluto: la destinazione è la griglia del catalogo in home, che elenca tutte le
app, cioè esattamente quello che il sottomenù avrebbe mostrato.

### Sotto gli 860 pixel

Compare il bottone a panino e la navigazione diventa un pannello sotto la barra, con il
sottomenù già aperto e rientrato: con una voce sola, costringere a un tocco in più sarebbe
solo fastidio.

⚑ **La soglia è 860 e non 560.** Il punto in cui serve il panino è quello in cui il contenuto
non entra, non quello in cui comincia un telefono: sotto quella larghezza le tre voci, le due
bandierine e il nome del sito non stavano su una riga e la barra andava a capo, diventando
alta il doppio.

### Senza JavaScript

☠ **Il bottone arriva dal server con l'attributo `hidden`, e solo `menu.js` lo toglie.** Tutte
le regole che nascondono la navigazione sono agganciate alla classe `.js`, messa sul
documento da uno script di una riga nel `<head>`. Se lo script non arriva — rete lenta,
blocco, errore — la navigazione resta quella di prima: tutte le voci visibili, che vanno a
capo. Un sito la cui navigazione dipende da JavaScript è un sito che a volte non si può
navigare.

☠ Quella riga sta nel `<head>` e non in fondo: più avanti, il browser avrebbe già disegnato la
pagina in versione senza JavaScript, con lo stesso sfarfallio che si voleva evitare.

### `public/assets/menu.js`

Quaranta righe, nessuna libreria. Fa cinque cose:

| Cosa | Perché |
|---|---|
| Toglie `hidden` dal bottone | È lui a dichiarare che il menù si può aprire |
| Apre e chiude, aggiornando `aria-expanded` e `aria-label` | Le due etichette arrivano tradotte in attributi `data-`: il JavaScript non conosce nessuna lingua |
| Chiude dopo il clic su una voce | ☠ Quasi tutti i link sono ancore verso la **stessa** pagina (`/#app`, `#personalizzato`). Senza, il pannello resta aperto sopra il contenuto a cui si è appena saltati, e sembra che il link non abbia funzionato |
| `Esc` chiude e riporta il fuoco sul bottone | Altrimenti il fuoco resta dentro un pannello chiuso |
| Al ridimensionamento richiude se il bottone non è più visibile | Ruotando il telefono il pannello sparisce per via del CSS, ma `aria-expanded` resterebbe `true` e uno screen reader annuncerebbe un menù aperto che non c'è |

### Il logo e le icone

Il logo è **fornito dal proprietario**: un cubo isometrico con le lettere SMP, sfondo
trasparente. Da quello si generano quattro file.

| File | Misura | Dove va |
|---|---|---|
| `logo.png` | 128 | Il segno accanto al nome, nella barra |
| `favicon-32.png` | 32 | La scheda del browser |
| `favicon-192.png` | 192 | La schermata iniziale su Android |
| `apple-touch-icon.png` | 180 | iOS |

☠ L'icona per iOS è l'unica **su fondo pieno**, il verde scuro della barra, con il logo
rientrato del 10%. iOS non gestisce la trasparenza in quell'icona: la compone su nero, e un
logo verde scuro su nero sparisce.

⚑ Il logo ha lo sfondo trasparente, quindi si vede bene sulla barra scura e si vedrebbe male
su fondo chiaro. Se un giorno servisse un'intestazione chiara, serve una seconda versione, non
un filtro CSS.

---

## 4. Le funzioni

### `src/config.php`

| Funzione | Firma | Cosa fa |
|---|---|---|
| `config` | `config(): array` | La configurazione, con i valori di `config.example.php` come ripiego. Non lancia se `config.local.php` manca. |
| `e` | `e(?string $value): string` | `htmlspecialchars` con `ENT_QUOTES \| ENT_SUBSTITUTE`, UTF-8. Nome corto perché compare centinaia di volte. |
| `parametri_azienda` | `parametri_azienda(): array` | I dati dell'azienda pronti per i segnaposto `{nome}` dei testi tradotti. |

### `src/i18n.php`

| Funzione | Firma | Cosa fa |
|---|---|---|
| `percorso_richiesto` | `percorso_richiesto(): string` | Il percorso della richiesta, senza query. |
| `lingua_corrente` | `lingua_corrente(): string` | `'it'` o `'en'`, dedotta dall'indirizzo. |
| `percorso_neutro` | `percorso_neutro(): string` | Il percorso senza prefisso di lingua. |
| `url_per` | `url_per(string $lingua, ?string $percorso = null): string` | L'indirizzo di una pagina in una lingua. |
| `lingua_preferita` | `lingua_preferita(?string $header): string` | Analizza `Accept-Language` con i pesi `q`. |
| `applica_lingua` | `applica_lingua(): void` | Sceglie, eventualmente redirige, ricorda. **Prima di ogni output.** |
| `dizionario` | `dizionario(string $lingua): array` | I due file della lingua, uniti e messi in cache. |
| `t` | `t(string $chiave, array $parametri = []): string` | La stringa tradotta. **Non ripulita**: può contenere HTML. |

Costanti: `LINGUE`, `LINGUA_DEFAULT`, `COOKIE_LINGUA`, `COOKIE_LINGUA_DURATA`.

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
| `nome` | string | "TrashCan". Non si traduce. |
| `accento` | string | Colore esadecimale, diventa `--card-accent` nella card |
| `logo` | ?string | Percorso dell'immagine, o `null` per il segnaposto con l'iniziale |
| `pubblicata` | bool | Decide se la card è un link o un riquadro grigio |
| `packageId` | string | Il nome del pacchetto Android, da cui si costruisce l'indirizzo Play |
| `suPlay` | bool | `false` finché l'app non è davvero pubblicata: il bottone resta spento |

☠ Nel catalogo non c'è **nessun testo visibile** oltre al nome: claim, sommario e prezzo
stanno nei dizionari sotto `app.<slug>.*`, perché vanno tradotti. Rimetterli qui darebbe un
catalogo che resta italiano anche sulle pagine inglesi, senza che niente lo segnali.

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
| `/sitemap.xml` | `public/sitemap.php` | `rewrite ^ /sitemap.php last`. Contiene **entrambe** le lingue con gli `hreflang` |
| `/robots.txt` | statico | |
| qualunque altro | 404 | |

**Ogni rotta qui sopra esiste anche con il prefisso `/en`**, e serve lo stesso file: nginx
toglie il prefisso e PHP sceglie il dizionario leggendo `REQUEST_URI` (§3bis). `/en` e `/en/`
danno la home inglese.

☠ L'espressione del vhost ancora `/en` per intero, `^/en(/.*)?$`, non come prefisso:
altrimenti un ipotetico `/energia` verrebbe servito come pagina inglese.

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
| Il modulo rifiuta **ogni** invio dicendo "la pagina è rimasta aperta troppo a lungo", su una pagina appena aperta | `csrf_token()` avvia la sessione, e avviare una sessione manda un `Set-Cookie`. Veniva chiamata **dentro il modulo**, cioè a metà documento: a quel punto l'HTML è già partito, PHP non può più mandare intestazioni, il cookie di sessione non arriva e alla POST successiva la sessione è nuova e vuota. Restava nascosto finché il buffer di output tratteneva l'intero documento: cresciuto il testo della pagina, il buffer si svuota prima di arrivare al modulo e l'invio smette di funzionare | `public/contatti.php`: `$csrf = csrf_token()` **prima** di ogni output, e nel modulo si stampa la variabile |
| La bandierina italiana non funziona: si torna sempre all'inglese | il rilevamento automatico rimbalzava anche chi aveva appena scelto. Scatta **solo in assenza del cookie**, e per chi ha i cookie bloccati c'è il `?l=` sui link della bandierina | `src/i18n.php`, `applica_lingua()` |
| Un visitatore francese vedeva l'italiano | ricadeva nel ramo "nessuna lingua riconosciuta", che tornava sul predefinito. Ora quel ramo va all'inglese, e solo l'intestazione **assente** (o `*`) resta sull'italiano, per non rimbalzare i crawler | `src/i18n.php`, `lingua_preferita()` |
| Una frase italiana in mezzo a una pagina inglese | chiave mancante nel dizionario inglese: `t()` ripiega sull'italiano e non segnala niente in pagina | `deploy/verifica_lingue.php`, da lanciare dopo ogni modifica ai testi |
| Una parola sparita da un testo legale | l'heredoc interpreta il simbolo di dollaro come inizio di variabile | i testi legali usano NOWDOC |
| Il sottomenù si richiude mentre ci si sposta col puntatore | uno stacco fra la voce e il pannello: il puntatore esce dall'area in `:hover` e il pannello sparisce prima di essere raggiunto | `.sottomenu { top: 100%; }`, senza margine |
| Il fuoco da tastiera sparisce dentro un pannello invisibile | il sottomenù si apriva col solo `:hover`: le voci restavano focalizzabili ma non visibili | aggiunto `:focus-within` |
| Il pannello del panino resta aperto sopra il contenuto | quasi tutte le voci sono ancore verso la stessa pagina: il salto avviene, ma il pannello lo copre e sembra che il link non funzioni | `menu.js` chiude dopo il clic su una voce |
| L'icona su iOS è un quadrato nero | iOS non gestisce la trasparenza nell'apple-touch-icon e la compone su nero | `apple-touch-icon.png` ha il fondo pieno verde scuro |
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
- **Nessuna terza lingua**: solo italiano e inglese. Aggiungerne una vuol dire un nuovo codice in `LINGUE`, due file di dizionario e una bandiera.
- **Nessun blog, nessuna newsletter, nessun analytics.**
- **Nessun test automatico sulle pagine**: l'unico controllo automatico è
  `deploy/verifica_lingue.php` sui dizionari. Per il resto vale la lista del §11.

---

## 11. Verifica dopo ogni modifica

**1. I dizionari sono allineati** (locale, prima di caricare):

```bash
cd site && php deploy/verifica_lingue.php
```

**2. Tutte le pagine rispondono, in tutte e due le lingue, ed eseguono PHP invece di
mostrarne il sorgente:**

```powershell
$percorsi = @('/','/trashcan','/contatti','/legale/privacy','/legale/note-legali',
              '/legale/cookie','/legale/termini','/legale/responsabilita','/sitemap.xml')
foreach ($p in $percorsi) {
  foreach ($u in @($p, "/en$p")) {
    $r = Invoke-WebRequest "https://smpmicroapps.it$u" -UseBasicParsing
    $lang = [regex]::Match($r.Content,'<html lang="([a-z]+)"').Groups[1].Value
    "{0,-32} {1} lang={2} {3}" -f $u, $r.StatusCode, $lang,
      $(if ($r.Content -match '<\?php') {'SORGENTE ESPOSTO'} else {'ok'})
  }
}
```

**3. Il rilevamento della lingua**: con `Accept-Language: en-GB` la radice deve dare 302
verso la versione inglese; con `it-IT` e senza intestazione deve restare dov'è.

**4. Il modulo funziona in entrambe le lingue**: GET della pagina contatti, estrazione del
token, POST. Deve rispondere "Messaggio ricevuto" e "Message received".

**5. I file riservati non sono raggiungibili**: `/config.local.php`, `/src/config.php` e
`/var/contatti.jsonl` devono dare tutti 404 o 403.

Il controllo `<?php` nel corpo della risposta non è pignoleria: è esattamente il difetto del
§8 che una semplice verifica del codice 200 non avrebbe mai trovato.

---

## 12. Debito tecnico aperto

| Cosa | Perché è rimandato | Quando |
|---|---|---|
| **SMTP non configurato** | serve una casella vera con le sue credenziali, che deve fornire il proprietario. Fino ad allora i messaggi si salvano e non arrivano notifiche | appena ci sono le credenziali di `info@smp-digital.it` |
| **Nessuna pagina per le altre tre app** | non esistono ancora | alla chiusura di F4, F5, F6. **Servono anche le chiavi `app.<slug>.*` in entrambi i dizionari** |
| **Le pagine legali inglesi sono una traduzione** | l'originale italiano fa fede e le pagine lo dichiarano. Una revisione da parte di un legale madrelingua non è stata fatta | se e quando ci saranno clienti fuori dall'Italia |
| **Numero REA assente** | non fornito. Se c'è iscrizione al Registro delle Imprese va indicato (art. 2250 c.c.) | va riempita `AZIENDA['rea']` in `src/config.php` |
| **Nessuna schermata delle app** | la pagina di TrashCan descrive a parole; qualche immagine venderebbe meglio | quando ci saranno gli screenshot per Play, che servono comunque |
| **Il bottone Play è spento** | l'app non è ancora pubblicata | si mette `suPlay => true` in `src/apps.php`, e basta |
| **Nessun backup dell'archivio messaggi** | `var/contatti.jsonl` vive solo sul server | quando arriveranno messaggi che valga la pena non perdere |

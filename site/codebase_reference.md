# codebase_reference.md — Vetrina smpmicroapps.it

> Atlante del **sito vetrina** delle MicroApps.
> **Obiettivo**: capire il sito, trovare ciò che serve e modificarlo **senza aprire i file**.
>
> **Aggiornato al**: 2026-10-10 · **Stato**: online su <https://smpmicroapps.it> (le modifiche del 2026-10-10 su
> Scorte Calore e Film Tracker sono **in locale**, da pubblicare)
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
| Le pagine di Scorte Calore e Film Tracker | `public/scorte-calore.php`, `public/film-tracker.php` (una chiamata ciascuna) |
| Il modello condiviso delle pagine app (hero, schermate, problema, funzioni, promo, prezzi, privacy, bug) | `src/pagina_app.php`, `pagina_app()` |
| La pill «Disponibile su iOS / Android / iOS e Android» | `etichetta_disponibilita()` in `src/layout.php` |
| Testate e screenshot di Scorte Calore e Film Tracker | `public/assets/img/scorte-calore/`, `public/assets/img/film-tracker/` |
| Testata, screenshot e promozionali di TrashCan | `public/assets/img/trashcan/` (WebP, §Aggiornamento 2026-10-09) |
| Il CSS delle immagini di una pagina app (`.hero__grid`, `.shots`, `.promo`) | in fondo a `public/assets/style.css` |
| La testata in cima alla card di un'app in home | chiave `testata` in `src/apps.php`, `.card__testata` in `style.css` |
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
│   ├── apps.php                il catalogo: catalogo(), app_per_slug(), link_play(), link_app_store()
│   ├── layout.php              pagina_inizio(), pagina_fine(), intestazione_legale(), etichetta_disponibilita()
│   ├── pagina_app.php          pagina_app(): il modello delle pagine di Scorte Calore e Film Tracker
│   ├── contact.php             validazione, CSRF, trappola, limite, archivio, notifica
│   └── mailer.php              client SMTP minimo (classi Mailer, SmtpError)
├── public/                     ← LA DOCUMENT ROOT. Tutto il resto sta fuori.
│   ├── index.php               home: titolo grande, griglia delle app, tre principi
│   ├── trashcan.php            vetrina di TrashCan: hero con testata, schermate, problema, funzioni,
│   │                           promozionali (solo it), prezzi, privacy
│   ├── scorte-calore.php       vetrina di Scorte Calore: chiama pagina_app() con i 5 screenshot
│   ├── film-tracker.php        vetrina di Film Tracker: chiama pagina_app() con i 6 screenshot
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
│           ├── trashcan.png    256x256, derivata dal logo dell'app
│           ├── scorte-calore.png  256x256, dal logo dell'app (assets/icons/scortecalore_logo.png), 256 colori
│           ├── film-tracker.png   256x256, dal logo dell'app (assets/icons/filmtracker_logo.png), 256 colori
│           ├── scorte-calore/  12 WebP: testata-{it,en}.webp (1024x500) + screen-{it,en}-0N-<nome>.webp
│           │                   (480x1043: 01-home, 02-aggiorna, 03-storico, 04-costi, 05-pro)
│           ├── film-tracker/   14 WebP: testata-{it,en}.webp + screen-{it,en}-0N-<nome>.webp
│           │                   (01-rullini, 02-rullino, 03-archivio, 04-etichetta, 05-statistiche, 06-pro)
│           └── trashcan/       23 WebP generati da apps/trashcan/store e dal Desktop (vedi sotto)
│               ├── testata-{it,en}.webp          1024x500, la testata Play per lingua
│               ├── screen-{it,en}-0N-<nome>.webp 480x1043, gli screenshot iOS (01-home … 06-pro)
│               └── promo-NN-<nome>.webp          9 promozionali in italiano (02…10), 640 o 900 px
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
le app **pubblicate**: dal 2026-10-10 TrashCan, Scorte Calore e Film Tracker. Quelle non ancora fatte non ci sono, perché nel
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

Compare il bottone a panino e la navigazione diventa un pannello sotto la barra. Il
sottomenù è **a tendina, chiuso di partenza**, e si apre con un bottoncino a freccia sulla
destra della riga "Le app".

☠ **Il bottoncino è separato dal link, non è il link che fa da interruttore.** "Le app" deve
continuare a portare al catalogo: trasformarlo in un interruttore gli toglierebbe la
destinazione, e chi tocca il nome di una sezione si aspetta di andarci. Il bottone fa una
cosa sola e la dichiara con `aria-expanded`.

⚑ Il bersaglio del bottoncino è 44 pixel, non la freccina disegnata. È la misura minima
consigliata per un elemento da toccare: sotto, chi ha le dita grosse o la mano ferma poco
centra il link accanto e finisce su un'altra pagina.

☠ Dentro il pannello l'apertura la comanda **solo** il bottone: le regole `:hover` e
`:focus-within` del desktop vengono disattivate. Su Android il tocco produce hover, quindi
senza disattivarle il sottomenù si aprirebbe da solo sfiorando la voce e il bottone
sembrerebbe non fare niente.

⚑ Chiuso di partenza e non aperto: con una app sola sembrava ragionevole lasciarlo aperto,
ma con quattro il pannello diventa una lista lunga in cui le voci principali si perdono fra
quelle secondarie, e non c'è modo di richiuderla.

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
| Apre e chiude il sottomenù delle app col bottoncino a freccia | ☠ Il gestore che chiude il pannello al clic controlla che sia un **link**: il bottoncino vive nello stesso pannello, e chiuderlo al suo clic farebbe sparire il sottomenù nello stesso istante in cui si apre |
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
| `link_app_store` | `link_app_store(array $app): ?string` | `https://apps.apple.com/app/id{appStoreId}`, o `null` finché `suAppStore` è `false` o manca `appStoreId`. |

Campi di una voce del catalogo:

| Campo | Tipo | Significato |
|---|---|---|
| `nome` | string | "TrashCan". Non si traduce. |
| `accento` | string | Colore esadecimale, diventa `--card-accent` nella card |
| `logo` | ?string | Percorso dell'immagine, o `null` per il segnaposto con l'iniziale |
| `pubblicata` | bool | Decide se la card è un link o un riquadro grigio |
| `packageId` | string | Il nome del pacchetto Android, da cui si costruisce l'indirizzo Play |
| `suPlay` | bool | `false` finché l'app non è davvero pubblicata: il bottone resta spento |
| `appStoreId` | string, facoltativa | L'id numerico di App Store Connect (TrashCan: `6818986320`), da cui si costruisce l'indirizzo App Store |
| `suAppStore` | bool, facoltativa | Come `suPlay`, per App Store. Finché **tutti e due** sono `false` la pagina mostra un solo bottone spento, `comune.presto_store` |
| `testata` | ?string | Percorso della testata con `{lingua}`, o `null` (vedi «La testata sulla card in home») |

Stato al 2026-10-10:

| slug | `pubblicata` | `suPlay` | `suAppStore` | `appStoreId` | pill |
|---|---|---|---|---|---|
| `trashcan` | true | true | true | `6818986320` | Disponibile su iOS e Android |
| `full-freezer` | false | false | — | — | In arrivo |
| `scorte-calore` | true | **false** | true | `6820405604` | Disponibile su iOS |
| `film-tracker` | true | **false** | true | `6820633385` | Disponibile su iOS |
| `qr-me` | false | false | — | — | In arrivo |
| `spending-review` | false | false | — | — | In arrivo |

☠ Nel catalogo non c'è **nessun testo visibile** oltre al nome: claim, sommario e prezzo
stanno nei dizionari sotto `app.<slug>.*`, perché vanno tradotti. Rimetterli qui darebbe un
catalogo che resta italiano anche sulle pagine inglesi, senza che niente lo segnali.

### `src/layout.php`

| Funzione | Firma | Cosa fa |
|---|---|---|
| `parametri_pagina` | `parametri_pagina(): array` | I segnaposto dei testi: dati azienda + `url_*` nella lingua corrente |
| `etichetta_disponibilita` | `etichetta_disponibilita(array $app): string` | La pill di un'app pubblicata, dai flag `suAppStore`/`suPlay`: `comune.disponibile_ios_android`, `comune.disponibile_ios`, `comune.disponibile_android`, o `comune.disponibile` se nessuno dei due. Usata dalla card in home e dall'eyebrow delle pagine app (`Nome · pill`). Sta qui e non in `apps.php` perché usa `t()` |
| `pagina_inizio` | `pagina_inizio(string $chiaveTitolo, string $chiaveDescrizione, string $canonical = '/'): void` | `<head>`, barra, menu. Prende **chiavi**, non testi |
| `selettore_lingua` | `selettore_lingua(): void` | Le due bandierine |
| `pagina_fine` | `pagina_fine(): void` | Piè di pagina |
| `intestazione_legale` | `intestazione_legale(string $chiaveTitolo, string $chiaveSommario): void` | Il riquadro in cima alle pagine legali |
| `pagina_legale` | `pagina_legale(string $nome): void` | Una pagina legale intera |

### `src/pagina_app.php`

| Funzione | Firma | Cosa fa |
|---|---|---|
| `pagina_app` | `pagina_app(string $slug, array $schermate, array $promo = []): void` | La pagina vetrina intera di un'app. `$schermate` = `list<string>` di nomi `0N-nome` (file `assets/img/<slug>/screen-<lingua>-<nome>.webp`, didascalia `<slug>.schermate.<n>`); `$promo` = `array<forma, list<nome>>` (file `promo-<lingua>-<nome>.webp`, alt `<slug>.promo.<nome>`). Se lo slug non c'è o non è pubblicato risponde 404 |

Sezioni nell'ordine: hero (eyebrow `Nome · pill`, titolo, lede, bottoni degli store **solo per gli store veri**, «Cosa sa fare», riga discreta `comune.android_in_arrivo` / `comune.ios_in_arrivo` quando l'app è su uno store solo, testata a destra) → «Com'è fatta» → problema (3) → funzioni (6, `id="funzioni"`) → «In due parole» (**solo se** esiste almeno un file promo della lingua della pagina) → prezzi (`app.<slug>.prezzo`) → privacy → bug.

⚑ TrashCan **non** usa `pagina_app()`: ha il suo file con chiavi `trashcan.*` e le nove promozionali senza lingua nel nome. È il modello da cui la funzione è nata; riscriverlo non portava niente al visitatore.

### `src/contact.php`

| Funzione | Firma | Cosa fa |
|---|---|---|
| `argomenti_contatto` | `argomenti_contatto(): array` | Le cinque voci del selettore. |
| `argomenti_notifica` | `argomenti_notifica(): array` | Le stesse voci sempre in italiano, per la mail di notifica al titolare. |
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
| `/scorte-calore` | `public/scorte-calore.php` | Via `@php`, come `/trashcan`: nessuna modifica a nginx o al router |
| `/film-tracker` | `public/film-tracker.php` | Idem |
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
| Nel pannello il sottomenù si apriva da solo sfiorando la voce, e il bottoncino sembrava inerte | su Android il tocco produce `:hover`, e le regole del desktop restavano attive anche dentro il pannello | dentro la media query `:hover` e `:focus-within` sono disattivate: apre solo il bottone |
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
- **Nessuna pagina di dettaglio** per Full Freezer, QR Me e Spending Review: le card ci sono ma non
  sono link. Scorte Calore e Film Tracker ce l'hanno dal 2026-10-10.
- **Nessuna promozionale** di Scorte Calore e Film Tracker: la sezione «In due parole» non compare
  finché non ci sono i file (§Aggiornamento 2026-10-10 sera).
- **Nessun pulsante Play** per Scorte Calore e Film Tracker: non sono ancora su Play (`suPlay => false`).
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
| **Nessuna pagina per Full Freezer, QR Me, Spending Review** | non sono ancora su nessuno store | quando arrivano su almeno uno store: `pubblicata => true`, il flag dello store, un file `public/<slug>.php` che chiama `pagina_app()`, le chiavi `<slug>.*` e `app.<slug>.prezzo` in entrambi i dizionari, le immagini in `public/assets/img/<slug>/` |
| **Scorte Calore e Film Tracker non sono su Play** | pubblicazione Android non ancora fatta | quando ci sono: `suPlay => true` in `src/apps.php` e basta (pill, bottone e riga «in arrivo» si aggiornano da soli) |
| **Promozionali di Scorte Calore e Film Tracker** | le fa il proprietario con ChatGPT | WebP in `public/assets/img/<slug>/promo-<lingua>-NN-nome.webp`, i nomi nell'array `$promo` del file della pagina, le chiavi `<slug>.promo.NN-nome` (alt) in entrambi i dizionari |
| **Le pagine legali inglesi sono una traduzione** | l'originale italiano fa fede e le pagine lo dichiarano. Una revisione da parte di un legale madrelingua non è stata fatta | se e quando ci saranno clienti fuori dall'Italia |
| **Numero REA assente** | non fornito. Se c'è iscrizione al Registro delle Imprese va indicato (art. 2250 c.c.) | va riempita `AZIENDA['rea']` in `src/config.php` |
| ~~**Nessuna schermata delle app**~~ | **chiuso il 2026-10-09**: TrashCan ha testata, schermate e promozionali | per le app successive: stessa struttura, `public/assets/img/<slug>/` |
| **Promozionali solo in italiano** | le immagini di TrashCan hanno il testo italiano dentro, e sulla pagina inglese non si mostrano | se arrivano le versioni inglesi: nome file con la lingua, e via la condizione `$lingua === 'it'` in `trashcan.php` |
| ~~**Il bottone Play è spento**~~ | **chiuso il 2026-10-09**: TrashCan ha `suPlay => true` | per le app successive: `suPlay => true` in `src/apps.php`, e basta |
| ~~**Il bottone App Store è spento**~~ | **chiuso il 2026-10-09**: TrashCan ha `suAppStore => true` (disponibile anche in UE) | per le app successive: `suAppStore => true` e il loro `appStoreId` |
| **Nessun backup dell'archivio messaggi** | `var/contatti.jsonl` vive solo sul server | quando arriveranno messaggi che valga la pena non perdere |

---

## Aggiornamento 2026-10-06 — TrashCan anche su iPhone

- Testi di home, piè di pagina, contatti e pagina TrashCan: «Android e iPhone». Piano gratuito e
  Pro allineati a `apps/trashcan/lib/app/feature_limits.dart`: la condivisione del calendario è
  gratuita, il **backup completo è Pro**, il promemoria è Pro.
- Nuove chiavi: `comune.scarica_app_store`, `comune.presto_store` (`comune.presto_play` resta nel
  dizionario ma `trashcan.php` non la usa più).
- Pagine legali (privacy, termini, note legali, cookie, responsabilità): aggiunti App Store e Apple
  Distribution International. ⚑ L'informativa dice che **su iPhone l'app non contatta il nostro
  server licenze**: è vero perché `tool/build_ios.sh` compila senza `MA_LICENSE_URL`, quindi
  `MicroAppConfig.serverEnabled` è `false`. Se un giorno la build iOS lo passasse, l'informativa
  va cambiata **prima** di pubblicare quella build. `comune.data_legale` → 6 ottobre 2026.
- `app.trashcan.prezzo` → **2,99 € / €2.99**: è il prezzo App Store in Italia (verificato via API il
  2026-10-06), più alto dei 2,39 € di Play. ⚑ Il sito mostra **il più alto dei due**, così nessuno
  trova in negozio un prezzo superiore a quello promesso qui.

## Aggiornamento 2026-10-09 — immagini sulla pagina di TrashCan

- **Hero a due colonne** (`.hero__grid`): testo a sinistra, `testata-<lingua>.webp` a destra; sotto
  gli 860px la testata va sotto il testo.
- **«Com'è fatta»** (`.shots`, subito dopo l'hero): i sei screenshot iOS della lingua della pagina in
  una striscia che scorre in orizzontale con `scroll-snap`, con didascalia (`trashcan.schermate.1..6`).
  Sono gli screenshot iOS e non quelli Android perché sono quelli piu' nitidi (1320 px di partenza).
- **«In due parole»** (`.promo`, dopo «Cosa trovi dentro»): nove promozionali in tre righe per forma
  (quadre 02-04, larghe 05-07, verticali 08-10), cosi' ogni riga ha la stessa altezza. Sotto i 780px
  ogni riga diventa una striscia che scorre: a due colonne la terza restava orfana. La n. 1
  («Stasera cosa si butta?») non c'e' perche' ripete il titolo dell'hero.
  ⚑ **Solo sulla pagina italiana**: il testo e' dentro l'immagine.
  ⚑ Prima di metterle si e' controllato che ogni funzione promessa esista (condivisione gratuita,
  piu' calendari e promemoria col Pro, eccezioni, regole mensili, temi e icone). Le immagini hanno
  il pulsante «Installa» col logo Play anche per chi arriva da iPhone: accettato, l'app e' su
  entrambi gli store.
- **Nuove chiavi** (in entrambi i dizionari, 190 in tutto): `trashcan.img.testata`,
  `trashcan.schermate.{titolo,lede,1..6}`, `trashcan.promo.{titolo,lede}`,
  `trashcan.promo.<NN-nome>` (gli `alt` delle promozionali).
- **Come si rifanno le immagini**: lo script che le ha generate (PIL, WebP qualita' 80-85, metodo 6)
  ridimensiona `apps/trashcan/store/testata-1024x500-<l>.png`, `store/screenshots/ios/<l>/0*.png` a
  480 px di larghezza e le promozionali del Desktop (`C:/Users/Pixel/Desktop/trashcan/`, originali
  ChatGPT da 1,6 MB, **non nel repo**) a 640 px (quadre e verticali) o 900 px (larghe). In tutto circa
  700 KB invece di 16 MB. Tutte con `width`/`height` o `loading="lazy"` tranne la testata, che e'
  sopra la piega.
- Provata in locale a 1400 px e in un iframe da 390 px (⚠ Edge headless non scende sotto ~500 px di
  finestra: una cattura con `--window-size=400` sembra tagliata a destra anche sulle pagine sane).

### La testata sulla card in home (2026-10-09, richiesta del proprietario)

- `catalogo()` in `src/apps.php` ha una chiave in piu' per app: **`testata`** (`string|null`), un
  percorso con il segnaposto `{lingua}` che `public/index.php` sostituisce con `$lingua` (la testata
  ha il testo dentro, quindi una per lingua). TrashCan: `/assets/img/trashcan/testata-{lingua}.webp`;
  le altre tre: `null`.
- Con la testata la card **non mostra il logo**: la testata ha gia' icona e nome, il logo sotto
  sarebbe un doppione. Senza testata resta tutto come prima (logo o iniziale).
- `.card__testata`: margini negativi pari al padding della card (1,6rem) per andare a filo dei
  bordi, `aspect-ratio: 1024 / 500`, `z-index: 1` per coprire la fascia colorata di `.card::before`.
  `index.php` legge `$app['testata'] ?? null`, quindi una voce nuova del catalogo senza la chiave
  non rompe la home.
- Per le prossime app: quando hanno la testata dello store, WebP in `public/assets/img/<slug>/` e la
  chiave `testata` nel catalogo.

## Aggiornamento 2026-10-09 — card «In arrivo» di QR Me

- `catalogo()` in `src/apps.php`: voce **`qr-me`** (`nome` «QR Me», `accento` `#15803D`, cioe' il
  verde dell'app scurito per stare sul bianco della card, `pubblicata` false, `packageId`
  `com.smp.qrme`, `suPlay` false, `testata` null). E' la quinta card, dopo Film Tracker.
- Dizionari: `app.qr-me.claim` («Condividi, ed è già un QR.» / «Share it, and it's a QR.») e
  `app.qr-me.sommario`, in entrambi (`verifica_lingue.php`: allineati).
- **Pubblicata il 2026-10-09** su clawserver con il via del proprietario (siti critici a 200 prima e
  dopo, pagine a 200 in entrambe le lingue, file riservati 404). Il sito vivo ha cinque card.

## Aggiornamento 2026-10-10 — card «In arrivo» di Spending Review

- `catalogo()`: voce **`spending-review`** (`nome` «Spending Review», `accento` `#16A34A`, `pubblicata`
  false, `packageId` `com.smp.spendingreview`, `suPlay` false, `testata` null); sesta card, dopo QR Me.
- Dizionari: `app.spending-review.claim` («Quanto stai spendendo, mentre fai la spesa.» / «What you're
  spending, while you shop.») e `app.spending-review.sommario`, in entrambi (allineati).
- **Pubblicata il 2026-10-10** col via del proprietario (siti critici a 200 prima e dopo, pagine a 200,
  file riservati 404).


## Aggiornamento 2026-10-10 (sera) — Scorte Calore e Film Tracker disponibili, pill per piattaforma

**Decisione del proprietario (2026-10-10):** un'app è «Disponibile» sul sito appena è su **almeno
uno** store, e la pill dice dove.

- **Pill per piattaforma** (`etichetta_disponibilita()` in `src/layout.php`): «Disponibile su iOS e
  Android» / «Disponibile su iOS» / «Disponibile su Android» (en «Available on …»), calcolata da
  `suAppStore`/`suPlay`. La usano la card in home (`public/index.php`) e l'eyebrow delle pagine app
  (`Nome · pill`). ⚑ L'eyebrow di TrashCan ora è calcolato anche lui: la chiave `trashcan.eyebrow`
  («TrashCan · Android e iPhone») **non esiste più** in nessuno dei due dizionari.
  ⚑ Nella card di TrashCan, su desktop a quattro colonne, la pill lunga va a capo su due righe:
  accettato, il riquadro arrotondato resta leggibile.
- **Catalogo**: `scorte-calore` e `film-tracker` con `pubblicata => true`, `suAppStore => true`,
  `appStoreId` (`6820405604`, `6820633385`), `suPlay => false`, `logo` e `testata`. Compaiono da sole
  nel sottomenù «Le app», nel piè di pagina e nella sitemap (`/scorte-calore`, `/film-tracker`, anche
  `/en/…`). Il conteggio in home dice «3 sono già scaricabili».
- ☠ **Nessun pulsante Play e nessun «Presto su Google Play»** per le due app: un bottone spento
  sembra una promessa con una data. Al suo posto, sotto i bottoni dell'hero, una riga `.meta
  .hero__nota` «Su Android in arrivo.» (`comune.android_in_arrivo`). Simmetrica: se un giorno un'app
  fosse solo su Play, compare «Su iPhone in arrivo.» (`comune.ios_in_arrivo`).
- **Pagine nuove** `public/scorte-calore.php` e `public/film-tracker.php`, una chiamata ciascuna a
  `pagina_app()` (`src/pagina_app.php`, §4). Le rotte non hanno richiesto modifiche: nginx e
  `deploy/router.php` servono già `/<nome>` → `<nome>.php`.
- **Testi** (fonte: `apps/<app>/store/scheda-app-store.md`, `lib/app/feature_limits.dart`, i
  benefici del paywall in `lib/l10n/app_it.arb`, gli atlanti delle app):
  - chiavi `scorte-calore.*` e `film-tracker.*` (titolo, descrizione, hero, img.testata, schermate.N,
    problema, funzioni 1-6, prezzi.{titolo,lede,base.lista,pro.lista}, privacy);
  - `app.scorte-calore.prezzo` **2,99 € / €2.99**, `app.film-tracker.prezzo` **4,99 € / €4.99**;
  - comuni nuove, riusabili dalle prossime pagine: `comune.disponibile_{ios_android,ios,android}`,
    `comune.{android,ios}_in_arrivo`, `comune.cosa_sa_fare`, `comune.schermate.{titolo,lede}`,
    `comune.promo.{titolo,lede}`, `comune.piano.{base,gratis,pro,unatantum}`, `comune.privacy.link`,
    `comune.bug.{titolo,testo,bottone}`;
  - ☠ `app.film-tracker.sommario` corretto: diceva «Pellicole, scatti, **tempi e diaframmi**», ma
    l'app non registra tempi né diaframmi. Ora: «Ogni rullino dalla macchina al provino: pellicola,
    sviluppo, stampe, costi e foto. E un'etichetta QR per il barattolo.»
  - Gratis/Pro come in `feature_limits.dart`. Scorte Calore: gratis una fonte, misure illimitate,
    stima, data di riordino, 90 giorni di storico, widget, ripristino; Pro notifiche, tutte le fonti,
    storico completo e grafici, acquisti e costi, evento nel calendario, CSV e backup. Film Tracker:
    gratis rullini illimitati, una macchina, catalogo, sviluppo e stampe, **tutte le foto**, QR,
    ripristino; Pro tutte le macchine, statistiche dell'anno, PDF dell'anno, CSV, backup con le foto.
  - ⚑ Il lede dei prezzi dice «lo ripristini dallo store, con lo stesso account» e non «dal tuo ID
    Apple»: resta vero il giorno in cui arriva Play, senza riscriverlo.
- **Immagini** (PIL, WebP qualità 85 la testata e 82 gli screenshot, metodo 6; circa 370 KB per app):
  testate da `apps/<app>/store/grafiche/testata-1024x500-<l>.png`, screenshot da
  `store/screenshots/ios/<l>/*.png` (1320x2868) ridotti a 480x1043. Scelti: Scorte Calore `home-pro`,
  `aggiornamento`, `storico`, `costi`, `paywall-revisione` (la `home` senza Pro è identica a parte
  l'etichetta; il widget di `grafiche/sorgenti/` è orizzontale e non sta nella striscia dei telefoni);
  Film Tracker `home`, `dettaglio`, `provino`, `qr`, `statistiche`, `paywall-revisione` (fuori `foto`,
  una foto a tutto schermo che non racconta l'app). Loghi 256x256 per il sottomenù da
  `assets/icons/<app>_logo.png`, ritagliati, quantizzati a 256 colori (~25 KB).
- ⚑ **Film Tracker** ha la grafica scura «C · Provino»: la pagina resta nello stile del sito, la
  grafica dell'app si vede nella testata e negli screenshot.
- **«In due parole» pronta ma assente**: `pagina_app()` mostra la sezione solo se esiste almeno un
  `promo-<lingua>-<nome>.webp` elencato nell'array `$promo` del file della pagina (oggi `[]`). La
  lingua è nel nome del file: una pagina inglese non mostra mai le promozionali italiane. Provato in
  locale con un file finto (poi tolto): la sezione compare in italiano e non in inglese.
- **Informativa privacy** (`it.legale.php`/`en.legale.php`, §4 «Le applicazioni»): aggiunto il
  paragrafo sull'**evento di Scorte Calore nel calendario del telefono** (solo Pro, solo su richiesta,
  permesso chiesto in quel momento; contenuto: combustibile, nome della fonte, data stimata; va nel
  calendario scelto dall'utente e, se quel calendario è sincronizzato con iCloud o Google, segue quel
  servizio). Le foto di Film Tracker erano già coperte dal paragrafo sulla fotocamera. Nient'altro
  cambiato. `comune.data_legale` → **10 ottobre 2026**.
- `style.css`: `.hero__nota { margin-top: 1rem; }`; `layout.php` carica `style.css?v=6`.
- **Verificato in locale**: `php -l` su tutti i file toccati, `verifica_lingue.php` allineato (290
  chiavi), `/`, `/trashcan`, `/scorte-calore`, `/film-tracker`, `/legale/privacy`, `/contatti` e le
  versioni `/en/…` a 200 senza sorgente esposto, nessuna immagine a 404, link App Store
  `https://apps.apple.com/app/id6820405604` e `…/id6820633385`, nessun link Play sulle due pagine,
  sitemap con le due pagine nuove in entrambe le lingue; screenshot Edge a 1400 px e in iframe da
  390 px. ☠ Edge headless lanciato in serie dalla stessa sessione non scriveva i file: va lanciato
  con `Start-Process -Wait` e un `--user-data-dir` diverso per ogni cattura.
- **Non ancora pubblicato** su clawserver.

# develop_microapps.md — Specsheet operativa di sviluppo

> **Progetto**: MicroApps — quattro app Flutter monetizzate una tantum su Google Play
> più un server di licenze/entitlement self-hosted.
> **Repository app** (remote `origin`): `https://git.home.varitest.ovh/smp-webmaster/microapps.git`
> **Mirror pubblico app** (remote `github`): `https://github.com/Frostmoore/smallapps.git`
> **Repository server** (**solo Gitea**, remote `origin`): `https://git.home.varitest.ovh/smp-webmaster/microapps-server.git`
> **Documento creato**: 2026-09-09
> **Stato**: **F0 e F1 chiuse.** F3 (TrashCan) in corso. 159 test verdi. Vedi §7.

---

## §0 — Come si usa questo documento

Questo file è la **specsheet operativa** dello sviluppo. Non è un riassunto e non è una
roadmap commerciale: è la guida passo-per-passo che permette a un agente di coding o a un
essere umano di **riprendere lo sviluppo da zero su un'altra macchina senza perdere nulla**.

Regole d'uso:

1. **Si legge in ordine**: §1 → §7 una volta sola, poi si vive dentro §8 (la guida) e §7
   (il tracking).
2. **Ogni fase ha un identificatore stabile** (`F3.4`, `F6.2`, …). Gli identificatori **non
   si riciclano mai**: se una sottofase viene cancellata, resta nel documento barrata con la
   motivazione. Servono per il grep.
3. **Ogni percorso file è scritto per esteso** dalla radice del repo. Ogni firma di metodo è
   scritta per esteso, con tipi. Se una firma qui non corrisponde al codice, **il documento
   è rotto e va corretto subito** (vedi §6, punto 2).
4. **La sezione §7 (tracking) è l'unica fonte di verità sullo stato**. Si aggiorna alla fine
   di ogni fase, mai "quando capita".
5. **Il rituale di fine fase (§6) è obbligatorio e non negoziabile.** Va eseguito senza che
   nessuno lo chieda.

Convenzione tipografica:

- `▶ Azione` = passo eseguibile, in ordine.
- `⚑ Perché` = motivazione della decisione. Non è opzionale da leggere: è il motivo per cui
  il codice è così e non altrimenti.
- `✔ DoD` = Definition of Done. La sottofase è chiusa **solo** se tutti i punti sono veri.
- `☠ Trappola` = errore già previsto. Se lo si ripete, si è perso tempo per niente.

---

## §1 — Contesto e obiettivi

### §1.1 Le quattro app

| # | App | Package (applicationId) | Cartella | Problema risolto | Complessità reale |
|---|---|---|---|---|---|
| 1 | **TrashCan** | `com.smp.trashcan` | `apps/trashcan/` | Calendario personale della raccolta differenziata, indipendente dal Comune | Logica ricorrenze 3/5 |
| 2 | **Full Freezer** | `com.smp.fullfreezer` | `apps/full_freezer/` | Inventario freezer ordinato per anzianità (oldest first) | UX 3/5, logica 1/5 |
| 3 | **Scorte Calore** | `com.smp.scortecalore` | `apps/scorte_calore/` | Quanto combustibile resta e quando riordinarlo | Logica stima 2/5 |
| 4 | **Film Tracker** | `com.smp.filmtracker` | `apps/film_tracker/` | Diario dei rullini analogici con anteprime visive | Frontend 3/5, storage foto 3/5 |

Le spec di prodotto originali vivono in `docs/specs/` (copia versionata di `memory/*.md`).
**Le spec sono il contratto di prodotto; questo documento è il contratto di implementazione.**
Dove le due divergono, si aggiorna questo documento spiegando perché.

✅ **Prefisso deciso il 2026-09-10: `com.smp.`** (SMP, il marchio del committente).

La prima stesura di questo piano usava `ovh.varitest.`, dedotto dal dominio del Gitea interno.
Era una scelta sbagliata: un `applicationId` è il nome pubblico dell'app nel sistema Android e
compare nell'URL della scheda su Play. Farlo derivare dall'hostname di un server di sviluppo
avrebbe legato per sempre quattro prodotti commerciali a un dettaglio di infrastruttura.

☠ **L'`applicationId` è immutabile dopo il primo upload su Play.** Non si rinomina, non si
migra: si può solo pubblicare un'app nuova e perdere installazioni e recensioni. Il momento
per cambiarlo è **prima** di F3.12, cioè prima che il primo AAB arrivi su Play Console. Al
2026-09-10 non è stato caricato nulla, quindi il cambio è a costo zero.

### §1.2 Il server

**MicroApps License Server** (`server/`): servizio Node/Fastify self-hosted su `clawserver`
che verifica gli acquisti Google Play lato server, tiene il registro di **chi ha comprato
cosa**, e permette il ripristino dell'acquisto su un altro dispositivo tramite codice.

⚑ **Perché esiste, visto che le spec dicono "nessun backend"**: le spec dicono giustamente
che *le funzionalità delle app* non devono dipendere da un server. Questo resta vero: le
quattro app funzionano al 100% offline, per sempre, anche se il server è spento. Il server
serve a tre cose che le app da sole non possono fare:

1. **Verificare gli acquisti server-side.** Il client Play Billing può essere falsificato su
   device rootati. La verifica reale si fa chiamando l'API Google Play Developer con un
   service account, e un service account **non può stare dentro l'APK**.
2. **Sapere chi ha pagato cosa.** Google Play Console dà i numeri aggregati; qui serve un
   registro interrogabile, con un pannello admin.
3. **Ripristino cross-account.** Play ripristina l'acquisto solo sullo stesso account Google.
   Il codice di ripristino copre il caso "ho cambiato account / telefono aziendale".

☠ **Trappola**: il server **non deve mai** diventare un single point of failure. Se il
server è irraggiungibile, l'app deve considerare valido l'ultimo entitlement noto in locale
e continuare a funzionare Pro. Vedi ADR-007.

⚑ **Convivenza con OpenClaw**: `clawserver` ospita l'agente OpenClaw dell'utente. Il License
Server gira in un **container Docker isolato**, con un proprio volume, una porta interna
dedicata e nessuna modifica alla configurazione esistente del server oltre a una `location`
in più nel reverse proxy. Nessun `apt upgrade`, nessun riavvio di servizi non nostri.

### §1.3 Obiettivo commerciale

Ogni app: **versione base gratuita completa e usabile**, **versione Pro sbloccata da un
acquisto una tantum** (prodotto in-app non consumabile, nessun abbonamento).

| App | SKU Play | Prezzo di lancio | Prezzo obiettivo post-recensioni |
|---|---|---|---|
| TrashCan | `trashcan_pro_lifetime` | 2,99 € | 4,99 € |
| Full Freezer | `fullfreezer_pro_lifetime` | 3,99 € | 5,99 € |
| Scorte Calore | `scortecalore_pro_lifetime` | 5,99 € | 7,99 € |
| Film Tracker | `filmtracker_pro_lifetime` | 6,99 € | 9,99 € |

⚑ **Perché il prezzo basso al lancio**: le spec indicano per ogni app due cifre (es. "2,99 €
/ 4,99 € lifetime"). Si interpreta la cifra bassa come prezzo di ingresso e l'alta come
obiettivo. Senza recensioni un'app sconosciuta a 9,99 € non vende: si parte basso, si alza
quando ci sono ≥ 20 recensioni. Il prezzo di un prodotto in-app **si può alzare** senza
penalizzare chi ha già comprato: l'acquisto resta valido per sempre.

☠ **Trappola**: mai cambiare lo SKU dopo la pubblicazione. Uno SKU pubblicato **non si può
cancellare né riusare**. Gli SKU sopra sono definitivi.

### §1.4 Cosa NON si costruisce

Elenco esplicito, per evitare che qualcuno lo cerchi invano o lo aggiunga per iniziativa:

- Nessun abbonamento ricorrente.
- Nessun account utente finale (ADR-013).
- Nessuna sincronizzazione cloud dei dati delle app. Il backup è un file JSON che l'utente
  salva dove vuole.
- Nessun servizio iOS/App Store nell'MVP. Il codice resta portabile ma non si testa su iOS.
- Nessuna integrazione con API comunali (TrashCan), nessun database remoto di pellicole
  (Film Tracker), nessun database prodotti da barcode online (Full Freezer).
- Nessun analytics, nessun crash reporter di terze parti (ADR-016).
- Nessuna funzione OCR/AI nell'MVP (foto del calendario cartaceo TrashCan: post-MVP).

---
### §1.5 Questa è una piattaforma, non un progetto da quattro app

**MicroApps è la base permanente su cui verranno costruite tutte le microapp future.** Le
quattro descritte in §1.1 sono le prime, non l'insieme completo: il committente potrà
chiederne di nuove in qualunque momento, e la risposta corretta non è mai "apro un progetto
separato".

**Cosa fare quando arriva la richiesta di una microapp nuova**, in ordine:

1. Aggiungere una **fase propria** con le sue sottofasi nel tracking §7, numerata dopo
   l'ultima esistente. Gli identificatori non si riciclano mai.
2. Creare `apps/<nome>/` applicando **§8.T** per intero: struttura, `AppConfig`, provider,
   l10n, manifest.
3. Dichiarare i limiti del piano gratuito in `lib/app/feature_limits.dart`, **riusando i
   `FeatureKey` esistenti**. Se serve una chiave nuova, è una modifica che tocca tutte le
   app e va fatta in `micro_core` con la sua motivazione.
4. Scegliere seed color e font, e aggiungerli alla tabella di **ADR-010**.
5. Assegnare `applicationId` `com.smp.<nome>` e SKU `<nome>_pro_lifetime`. Entrambi
   immutabili dopo il primo upload su Play.
6. Registrare l'app nel License Server (tabelle `apps` e `products`, F2.2).
7. Creare il suo **`codebase_reference.md`** alla fine della prima fase che la riguarda.

⚑ **Un atlante per app, mai uno condiviso.** Ogni app ha il proprio
`codebase_reference.md`, e così `micro_core` e il server. Un atlante unico costringerebbe a
scorrere migliaia di righe che non riguardano l'app su cui si lavora, ed è esattamente la
condizione in cui si smette di aggiornarlo.

⚑ **Perché aggiungere un'app non deve costare nulla a `micro_core`**: la regola "il package
condiviso non conosce nessuna app" (§F1, regola non negoziabile) esiste per questo. Non è
purismo: è la condizione perché la decima app costi come la quinta. Se aggiungerne una
richiedesse di toccare `micro_core`, il sintomo va letto al contrario, come un confine messo
nel posto sbagliato da correggere lì, non da aggirare nell'app nuova.

☠ **Trappola**: la tentazione, alla quinta app, è copiare la cartella della quarta e
modificarla. Produce quattro copie divergenti della stessa infrastruttura, che è il motivo
per cui esiste il monorepo. Si applica §8.T, che è la stessa cosa fatta senza portarsi
dietro il dominio dell'app precedente.



## §2 — Decisioni architetturali (ADR)

Ogni ADR è numerata e stabile. Se una decisione cambia, si aggiunge una nuova ADR che
**supersede** la vecchia; la vecchia resta scritta.

### ADR-001 — Monorepo per le app, repo separata per il server

**Decisione**: una repo Gitea `microapps` contenente `apps/` (4 progetti Flutter),
`packages/micro_core/` (package Dart condiviso), `docs/`, `tool/`. Il **server vive in una
repo separata** `microapps-server`, ospitata **solo** su Gitea.

⚑ **Perché il server è fuori dal monorepo** (decisione del 2026-09-09, supersede la versione
originale di questa ADR): il monorepo delle app viene pubblicato anche su GitHub
(`Frostmoore/smallapps`), mentre il server deve restare privato su Gitea. Git pusha commit
interi: **non esiste modo di escludere una cartella da un push**. Le alternative erano
mantenere due storie git divergenti con uno script di filtro, oppure separare le repo. Si è
scelta la separazione perché è l'unica in cui l'errore è **impossibile** invece che
sorvegliato: il server non sta nella repo che finisce su GitHub, quindi nessun push distratto
può esporlo.

**Il percorso su disco resta `server/`**, dentro la cartella di lavoro ma **ignorato** dal
monorepo (`/server/` in `.gitignore`) e con un proprio `.git`. Così tutti i percorsi
documentati in §8/F2 restano validi alla lettera e chi lavora ha comunque tutto sotto la
stessa cartella.

☠ **Trappola**: `server/` è una repo git annidata dentro l'albero di un'altra. Un
`git add -A` dal monorepo **non** la include perché è in `.gitignore`, ma un
`git add -f server` la includerebbe. Non farlo mai.

**Versione originale della decisione** (superata): una sola repo contenente anche `server/`.

⚑ **Perché**: le quattro app condividono circa il 40% del codice non-UI (billing,
entitlement, notifiche, backup, export, design system). Con quattro repo separate ogni fix
di billing va fatto quattro volte, e dopo tre mesi le quattro copie divergono. Con il
monorepo il fix è uno. Il costo è che una modifica a `micro_core` può rompere quattro app:
si paga con i test di `micro_core` (F1.12) e con la regola "prima si aggiorna `micro_core`,
poi si ricompilano tutte e quattro".

**Non si usa** `melos`: aggiunge un livello di indirezione per cinque pacchetti. Si usano
dipendenze `path:` nei `pubspec.yaml` e gli script in `tool/`.

### ADR-002 — Flutter aggiornato a stable ≥ 3.35, Dart ≥ 3.9

**Decisione**: prima riga di codice solo dopo `flutter upgrade`. Versione minima 3.35.

⚑ **Perché**: la macchina ha Flutter 3.27.1 (dicembre 2024). Google Play, dal 31 agosto
2025, rifiuta nuove app con `targetSdk` < 35, e dal 1° novembre 2025 richiede il supporto
alle pagine di memoria da **16 KB** per le app che targettano Android 15+. L'engine di
Flutter 3.27 non è allineato a 16 KB: lo si scoprirebbe al momento dell'upload, cioè nel
momento peggiore. Si aggiorna prima.

**Vincolo**: la versione esatta usata va scritta in `.flutter-version` alla radice e
riportata in ogni `codebase_reference.md`.

### ADR-003 — Riverpod per lo stato, senza code generation

**Decisione**: `flutter_riverpod` con `Notifier`/`AsyncNotifier` scritti a mano. Niente
`riverpod_generator`, niente `build_runner` per i provider.

⚑ **Perché**: `build_runner` serve già per Drift; aggiungere anche i provider generati
raddoppia i tempi di build e rende il codice illeggibile a chi apre il file senza aver
lanciato la generazione. I provider scritti a mano sono tre righe in più e restano leggibili
in un diff.

### ADR-004 — Drift su SQLite per la persistenza, in tutte e quattro le app

**Decisione**: `drift` + `sqlite3_flutter_libs`, schema dichiarato in Dart, migrazioni
esplicite con `MigrationStrategy` versionata.

⚑ **Perché**: le spec lo chiedono esplicitamente. In più Drift dà query tipizzate e
`Stream` reattivi che si sposano con Riverpod senza colla. L'alternativa (`sqflite` + SQL a
stringhe) costa un bug di battitura per query.

☠ **Trappola già nota**: `schemaVersion` **deve** essere incrementato a ogni modifica di
tabella, e serve un test di migrazione (`drift_dev schema dump` + `drift_dev schema steps`).
Senza, il primo aggiornamento in produzione cancella i dati degli utenti. Ogni app ha la
sottofase `X.2.6 — Test di migrazione` esattamente per questo.

### ADR-005 — go_router per la navigazione

**Decisione**: `go_router`, rotte dichiarate in un unico file per app
(`lib/app/router.dart`), con nomi costanti in `lib/app/routes.dart`.

⚑ **Perché**: serve il deep-link dalle notifiche ("apri il dettaglio della raccolta di
domani") e dai widget Android. Con `Navigator` imperativo il deep link diventa una catena di
`push` fragile che si rompe quando l'app viene aperta da fredda.

### ADR-006 — Un solo gateway di acquisto, due implementazioni

**Decisione**: interfaccia `PurchaseGateway` in `micro_core`, con `PlayPurchaseGateway`
(usa `in_app_purchase`) e `FakePurchaseGateway` (in-memory, deterministico).

⚑ **Perché**: senza il fake non si può sviluppare né testare il paywall finché l'app non è
caricata su un canale interno di Play Console. Con il fake, tutto il flusso paywall →
acquisto → sblocco funzionalità è sviluppabile e testabile il primo giorno. La scelta
avviene a compile time con `--dart-define=BILLING=fake|play`; il default in `debug` è `fake`,
in `release` è `play`, e un `assert` impedisce di produrre una release con il fake attivo.

### ADR-007 — Entitlement local-first, server come conferma opzionale

**Decisione**: la verità sull'entitlement è il file locale `entitlement.json`, scritto da
`EntitlementStore`. Le fonti che possono aggiornarlo sono, in ordine di fiducia crescente:
`local` < `play` < `server`. Il server può **promuovere** a Pro; può **revocare** solo con
una risposta esplicita `status: "revoked"` (rimborso/chargeback), mai per timeout o errore
di rete.

⚑ **Perché**: un utente che ha pagato deve restare Pro in aereo, in cantina, e nel 2031
quando il server sarà spento. Qualunque design in cui "niente rete = niente Pro" produce
recensioni a una stella meritate.

☠ **Trappola**: mai scrivere `if (serverResponse == null) setFree()`. Mai. Il test
`packages/micro_core/test/entitlement/offline_never_downgrades_test.dart` esiste per
impedirlo per sempre.

### ADR-008 — Le date "civili" non sono istanti

**Decisione**: le date senza ora (data di congelamento, data di raccolta, data di consegna
al laboratorio, data di misurazione della scorta) si memorizzano come **TEXT `YYYY-MM-DD`**
e si manipolano con `CivilDate` di `micro_core`. Solo i timestamp veri (creazione record,
verifica licenza, orario di uscita di un alimento) sono istanti, memorizzati come **INTEGER
millisecondi UTC**.

⚑ **Perché**: "la raccolta dell'organico è lunedì" non è un istante UTC. Salvando
`DateTime.now()` e riconvertendo, l'ora legale e i fusi spostano la data di un giorno per
alcuni utenti in alcune settimane dell'anno. È il bug classico dei calendari, difficilissimo
da riprodurre e devastante per un'app la cui unica funzione è dire il giorno giusto.

### ADR-009 — Notifiche locali con finestra scorrevole

**Decisione**: `flutter_local_notifications` + `timezone`. Si pianificano al massimo **64**
notifiche future per app, coprendo una finestra di 60 giorni, e si ripianifica a ogni
`AppLifecycleState.resumed`, dopo ogni modifica ai dati, e al boot del dispositivo
(`BOOT_COMPLETED` receiver fornito dal plugin).

⚑ **Perché**: Android ha un limite pratico sugli alarm pendenti per app (≈500) e non
garantisce la sopravvivenza degli alarm al riavvio senza receiver. 64 notifiche su 60 giorni
coprono il caso d'uso reale (una raccolta ogni due giorni) senza avvicinarsi al limite. La
ripianificazione al resume è la rete di sicurezza contro il killing aggressivo dei processi
di Xiaomi/Huawei/Oppo.

☠ **Trappola**: `AndroidScheduleMode.exactAllowWhileIdle` richiede `SCHEDULE_EXACT_ALARM`,
che su Android 14+ Google Play **contesta** se non hai una ragione da sveglia/promemoria
utente. Si usa `inexactAllowWhileIdle` per il digest settimanale del freezer e per il
riordino combustibile (tolleranza: ore), ed `exact` **solo** per TrashCan, dove l'orario
preciso della sera prima è la funzione stessa dell'app — con schermata di spiegazione e
fallback funzionante se il permesso viene negato.

### ADR-010 — Design system condiviso, identità visiva separata

**Decisione**: `micro_core` fornisce i componenti (`MicroCard`, `MicroStatTile`,
`MicroEmptyState`, …) e la funzione `MicroTheme.build(...)`. Ogni app passa il proprio seed
e il proprio font. Nessuna app scrive `Container` con `BoxDecoration` a mano dentro le
pagine.

| App | Seed color | Brightness di default | Font | Motivo |
|---|---|---|---|---|
| TrashCan | `#2E7D5B` | light | Outfit | Verde raccolta, leggibile a colpo d'occhio la sera |
| Full Freezer | `#3A7CA5` | light | Plus Jakarta Sans | Blu ghiaccio, freddo e pulito |
| Scorte Calore | `#C4622D` | light | Sora | Ambra/fiamma, richiama il calore |
| Film Tracker | `#E0A458` | **dark** | Fraunces (titoli) + Inter (corpo) | La camera oscura è scura; le foto risaltano su fondo scuro |

Tutte e quattro supportano light e dark; cambia solo il default e la cura riposta nell'uno o
nell'altro.

⚑ **Perché font bundlati e non `google_fonts` a runtime**: `google_fonts` di default scarica
i font da Internet al primo avvio. Un'app che dichiara "funziona offline" e mostra il font di
fallback in aereo è sciatta. I `.ttf` stanno in `assets/fonts/` di ogni app, dichiarati nel
`pubspec.yaml`. Costo: circa 400 KB per app. Accettabile.

### ADR-011 — Due lingue: italiano sui dispositivi italiani, inglese su tutti gli altri

**Decisione**: `flutter_localizations` + file ARB in `lib/l10n/`. Due lingue e due sole:
`it` e `en`. Un dispositivo con lingua italiana vede l'app in italiano; **qualunque altra
lingua vede l'inglese**, senza eccezioni e senza schermate a metà tradotte.

Implementazione, identica in tutte e quattro le app:

| Elemento | Valore | Perché così |
|---|---|---|
| `template-arb-file` | **`app_en.arb`** | Il template è l'unico file di cui `gen_l10n` garantisce la completezza: se manca una chiave in un'altra lingua, si ripiega sul template. Poiché l'inglese è la lingua di ripiego per il mondo, dev'essere lui il template. Una chiave dimenticata produce una parola inglese in un'app italiana, non una parola italiana in un'app coreana. |
| `supportedLocales` | `[Locale('en'), Locale('it')]`, **`en` per primo** | Quando il dispositivo non corrisponde a nessuna lingua supportata, Flutter ripiega sul **primo** elemento della lista. Mettere `it` per primo darebbe l'italiano a un utente tedesco. |
| `localeResolutionCallback` | esplicito | Non ci si affida al comportamento implicito: la regola è scritta in una funzione con un nome, così è leggibile e testabile. |
| `untranslated-messages-file` | `l10n/untranslated.json` | Elenca a ogni build le chiavi non tradotte in italiano. Serve a non accorgersi dei buchi in produzione. |

```dart
Locale resolveLocale(List<Locale>? deviceLocales, Iterable<Locale> supported) {
  // Italiano se il dispositivo lo chiede, in qualunque variante regionale
  // (it, it_IT, it_CH). Inglese in tutti gli altri casi.
  for (final locale in deviceLocales ?? const <Locale>[]) {
    if (locale.languageCode == 'it') return const Locale('it');
  }
  return const Locale('en');
}
```

⚑ **Perché non si segue la lista completa delle preferenze del dispositivo**: un utente con
preferenze `[de, it, en]` riceverebbe l'italiano perché viene prima dell'inglese. È un
comportamento difendibile in astratto, ma qui produce sorpresa: chi ha il telefono in tedesco
si aspetta l'inglese come ripiego, non l'italiano. La regola scelta è quella che l'utente
riesce a prevedere.

⚑ **Perché solo due lingue**: TrashCan (raccolta porta a porta) e Scorte Calore (pellet,
bomboloni GPL) hanno un mercato prevalentemente italiano; Film Tracker e Full Freezer sono
universali. Aggiungere spagnolo o tedesco senza un traduttore vero significa pubblicare
traduzioni automatiche, che nelle recensioni si notano e fanno più danno che bene.

☠ **Trappola**: nessuna stringa visibile all'utente va scritta nel codice, **nemmeno le
stringhe apparentemente neutre** come i formati di data, le unità di misura e i separatori
decimali. `intl` va usato con il locale corrente, altrimenti un'app inglese mostra "9,5 kg"
con la virgola e un'app italiana mostra "9/9/2026" nell'ordine americano.

☠ **Trappola numero due**: le stringhe dello **store** (titolo, descrizione, screenshot) sono
una localizzazione separata, gestita in Play Console (F7.6). Un'app tradotta con una scheda
solo in italiano non viene trovata da chi cerca in inglese.

### ADR-012 — Server: Node 22 + Fastify 5 + TypeScript + SQLite

**Decisione**: `server/` in TypeScript strict, Fastify 5, `better-sqlite3` (sincrono, WAL),
Zod per la validazione, Pino per i log, `argon2` per le password admin, `googleapis` per
Android Publisher v3. Nessun ORM: SQL a mano in `server/src/db/`.

⚑ **Perché SQLite e non Postgres**: il carico atteso è di poche migliaia di righe e qualche
decina di richieste al giorno. Postgres su `clawserver` significa un container in più, un
backup in più e un servizio in più da tenere aggiornato accanto a OpenClaw. SQLite in WAL
regge tre ordini di grandezza più di quel che serve, e il backup è la copia di un file.

⚑ **Perché niente ORM**: lo schema ha dieci tabelle e non cambierà spesso. Un ORM
aggiungerebbe un layer di traduzione e un generatore per risparmiare duecento righe di SQL
leggibile.

### ADR-013 — Il server non ospita account utente finali

**Decisione**: nessuna registrazione, nessuna password lato utente. L'identità del
dispositivo è un `install_id` UUIDv4 generato al primo avvio e conservato in
`flutter_secure_storage`. Gli unici account con password sono gli **admin**.

⚑ **Perché**: le spec ripetono "nessun login". Un'app che chiede la mail per usare il
calendario dell'immondizia perde metà degli utenti all'onboarding. L'`install_id` dà tutto
quello che serve (associare un acquisto a un dispositivo) senza dato personale, quindi senza
obblighi GDPR pesanti e senza informativa complicata.

### ADR-014 — Autenticazione delle chiamate device→server via HMAC

**Decisione**: ogni richiesta dei device porta gli header `X-MA-App`, `X-MA-Install`,
`X-MA-Timestamp`, `X-MA-Signature`, dove la firma è
`HMAC-SHA256(appSecret, method + "\n" + path + "\n" + timestamp + "\n" + sha256hex(body))`.
Il `appSecret` è compilato nell'APK via `--dart-define=MA_APP_SECRET=…`.

⚑ **Perché, sapendo che un segreto dentro un APK non è un segreto**: non serve a proteggere
l'entitlement (quello lo protegge la verifica Google server-side), serve a impedire che
l'endpoint pubblico venga sommerso da traffico casuale e a rendere non banale il replay
(finestra timestamp ±300 s + cache dei nonce). Chi decompila l'APK ottiene la possibilità di
*chiedere* la verifica di un token: senza un token Play valido, il server risponde comunque
`not_entitled`.

☠ **Trappola**: non spacciare mai questo per sicurezza forte, né in codice né nei commenti.
Il commento in testa a `server/src/plugins/auth.ts` deve dire esattamente cosa protegge e
cosa no.

### ADR-015 — Widget Android nativi solo dove sono una feature di prodotto

**Decisione**: widget home-screen in **TrashCan** (feature premium centrale, F4.10) e in
**Full Freezer** (F5.10). Nessun widget in Scorte Calore e Film Tracker.

⚑ **Perché**: un widget Android in Flutter richiede codice Kotlin nativo, il plugin
`home_widget`, e `RemoteViews`/Glance scritti a mano. È il pezzo più costoso in rapporto
alle righe di Dart. Lo si paga dove l'utente lo guarda ogni giorno senza aprire l'app
("cosa butto stasera", "cosa devo consumare") e non dove aprirebbe l'app comunque.

### ADR-016 — Niente analytics né crash reporting di terze parti nell'MVP

**Decisione**: nessun Firebase, nessun Sentry al lancio. I crash si leggono in Play Console
(Android Vitals). Un log locale a rotazione (`micro_core/lib/src/util/micro_log.dart`)
esportabile dall'utente su richiesta.

⚑ **Perché**: ogni SDK di analytics obbliga a una sezione "Sicurezza dei dati" più complessa
in Play Console, a un consenso, e a un'informativa privacy più lunga. Per quattro app
offline il rapporto costo/beneficio al lancio è negativo. Si potrà aggiungere dopo, dietro
consenso esplicito.

### ADR-017 — Il gating Pro è dichiarativo, mai sparso

**Decisione**: ogni limite del piano gratuito è dichiarato in un'unica mappa per app
(`lib/app/feature_limits.dart`) e valutato da `FeatureGate` di `micro_core`. Nessun
`if (isPro)` scritto a mano dentro una pagina.

⚑ **Perché**: i limiti cambiano (è normale spostare il limite gratuito dopo il lancio). Se
sono sparsi in venti file, cambiarli è un refactor; se sono in una mappa, è una riga. In più
il paywall può spiegare **cosa** si sblocca leggendo la stessa mappa, senza testi duplicati
che divergono.

---

## §3 — Ambiente di sviluppo (stato verificato il 2026-09-09)

| Elemento | Stato rilevato | Azione richiesta |
|---|---|---|
| Flutter di sistema | 3.27.1 stable, Dart 3.6.0 | **Non toccare**: altri progetti della macchina dipendono da questa versione |
| Flutter del progetto | 3.47.3 stable, Dart 3.13.3, in `.flutter/` | Scaricata in F0.2, si usa via `tool/fl.ps1` — vedi §5.8 |
| Android SDK | 36.0.0 installato | Licenze **non accettate**: `pwsh tool/fl.ps1 doctor --android-licenses` (F0.2) |
| Android Studio | 2024.2 | OK |
| JDK | OpenJDK 17.0.13 | OK (Gradle 8.x + AGP 8.x richiedono 17) |
| Node.js | v22.13.0 | OK per il server |
| Git | 2.47.1.windows.1 | OK |
| Gitea | `git.home.varitest.ovh`, utente `smp-webmaster`, credenziali in Git Credential Manager | OK, push-to-create verificato su repo esistenti |
| clawserver | `51.68.129.241`, `vps-3e7d932a`, Ubuntu 24.04, 4 core, 7,6 GB RAM, 45 GB liberi | **Raggiungibile.** La chiave ha una passphrase ed è nell'ssh-agent di **Windows**: va usato l'`ssh` di Windows (PowerShell), non quello di Git Bash |
| clawserver — servizi | OpenClaw gateway (porte locali 18789/18791/18792), nginx con 3 vhost e Certbot, wa-webhook su 3100, MariaDB, Redis | Docker 29.3 e Compose v5.1 attivi, **nessun container in esecuzione**, porta 8087 libera |
| clawserver — bonifica | Desktop XFCE, GNOME parziale, Xorg, CUPS, VNC e noVNC **rimossi** il 2026-09-09; porta 6080 chiusa | Le dipendenze di Chromium/Playwright sono state marcate `manual` prima delle purghe e verificate dopo |
| Play Console | non verificato | Serve un account sviluppatore attivo **prima** di F4.12 |

☠ **Trappola già disinnescata**: `ssh clawserver` da Git Bash risponde
`Permission denied (publickey)`. Non è un problema del server: la chiave
`~/.ssh/clawserver_ed25519` ha una **passphrase** ed è caricata nell'**ssh-agent di
Windows**, che l'ssh di Git Bash non vede. Tutti i comandi verso `clawserver` vanno dati
con l'`ssh` di Windows, quindi dallo strumento PowerShell.

---

## §4 — Struttura del monorepo

```
microapps/
├─ develop_microapps.md          ← questo documento
├─ README.md                     ← indice dei quattro prodotti + come si builda
├─ .flutter-version              ← versione Flutter pinnata (ADR-002)
├─ .gitignore
├─ .gitattributes
├─ analysis_options.yaml         ← lint condivise, ereditate dai sotto-progetti
│
├─ docs/
│  ├─ specs/                     ← copia versionata delle spec di prodotto
│  │  ├─ trashcan.md
│  │  ├─ full-freezer.md
│  │  ├─ scorte-calore.md
│  │  └─ film-tracker.md
│  ├─ store/                     ← testi e asset per Google Play (F7.6)
│  │  ├─ trashcan/  full_freezer/  scorte_calore/  film_tracker/
│  ├─ privacy/                   ← informative privacy pubblicabili (F7.7)
│  └─ adr/                       ← ADR estese, se una decisione supera le 30 righe
│
├─ packages/
│  └─ micro_core/                ← package Dart condiviso (F1)
│     ├─ pubspec.yaml
│     ├─ codebase_reference.md   ← atlante di micro_core
│     ├─ lib/
│     │  ├─ micro_core.dart      ← barrel: unica cosa che le app importano
│     │  └─ src/…                ← albero completo in §8/F1
│     └─ test/
│
├─ apps/
│  ├─ trashcan/
│  │  ├─ pubspec.yaml
│  │  ├─ codebase_reference.md   ← atlante dell'app
│  │  ├─ lib/  test/  android/  assets/
│  ├─ full_freezer/              ← stessa struttura
│  ├─ scorte_calore/             ← stessa struttura
│  └─ film_tracker/              ← stessa struttura
│
├─ server/                       ← REPO SEPARATA (ADR-001): propria .git, solo Gitea,
│  ├─ package.json  tsconfig.json  Dockerfile  docker-compose.yml  .env.example
│  ├─ codebase_reference.md      ← atlante del server
│  ├─ src/  test/                  ignorata dal monorepo tramite /server/ in .gitignore
│
└─ tool/
   ├─ pub_get_all.ps1            ← flutter pub get su micro_core + 4 app
   ├─ analyze_all.ps1
   ├─ test_all.ps1
   ├─ build_release.ps1          ← incrementa versionCode, firma, produce gli AAB
   └─ bump_version.ps1           ← calcola il prossimo branch di versione (§5.3)
```

⚑ **Perché `codebase_reference.md` è uno per progetto e non uno solo**: l'atlante deve poter
essere letto senza scorrere quattromila righe che non riguardano l'app su cui si lavora.
Sei atlanti (4 app + `micro_core` + server), ognuno autosufficiente, più un indice in
`README.md`. Nessun atlante duplica il contenuto di un altro: quando un'app usa qualcosa di
`micro_core`, l'atlante dell'app **linka** la sezione dell'atlante di `micro_core` invece di
ricopiarla, perché una firma copiata in due posti diverge in due settimane.

---

## §5 — Convenzioni

### §5.1 Naming

| Cosa | Regola | Esempio |
|---|---|---|
| Cartelle e file Dart | `snake_case` | `occurrence_engine.dart` |
| Classi | `UpperCamelCase` | `OccurrenceEngine` |
| Tabelle Drift (classe) | plurale `UpperCamelCase` | `WasteTypes` |
| Tabelle SQLite (fisiche) | plurale `snake_case` | `waste_types` |
| Provider Riverpod | suffisso `Provider` | `occurrenceEngineProvider` |
| Rotte go_router | costante in `routes.dart`, path kebab-case | `Routes.wasteTypeEdit = '/waste-type/:id/edit'` |
| Chiavi ARB | `contesto_cosa` | `home_tonightEmpty` |
| SKU Play | `<app>_pro_lifetime` | `trashcan_pro_lifetime` |
| Tabelle server | plurale `snake_case` | `restore_codes` |
| Endpoint server | `/v1/<risorsa>` kebab-case | `/v1/purchases/verify` |

### §5.2 Commit

Formato **Conventional Commits** con scope obbligatorio:

```
<tipo>(<scope>): <descrizione in italiano, imperativo, minuscolo>

<corpo opzionale: il perché, non il cosa>
```

- **tipi**: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `build`, `perf`.
- **scope**: `core`, `trashcan`, `freezer`, `scorte`, `film`, `server`, `repo`, `docs`.

Esempio: `feat(trashcan): motore ricorrenze con eccezioni salta/sposta`

Ogni commit termina con la riga:
`Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`

### §5.3 Branch e versioni

I branch **si chiamano come le versioni**, si parte da `v1.0.0`. La numerazione avanza a
ogni commit in base all'entità della modifica:

| Entità | Incremento | Cosa significa concretamente qui |
|---|---|---|
| **Piccola** | `+0.0.1` | fix, refactor locale, test, documentazione, sottofase minore |
| **Media** | `+0.1.0` | sottofase rilevante completata, feature utente nuova |
| **Grande** | `+1.0.0` | **fase** completata, o cambiamento che tocca tutte e quattro le app |

Il branch è **uno per versione**: si crea `vX.Y.Z` a partire dal branch precedente, ci si
committa sopra, si pusha. `tool/bump_version.ps1` legge l'ultimo branch `v*` ordinato per
semver e propone il successivo dato il tipo di incremento (`-Small`, `-Medium`, `-Large`).

**Versioni pianificate a fine fase** (obiettivo, non vincolo — l'incremento reale dipende dai
commit intermedi):

| Fase | Branch di chiusura previsto |
|---|---|
| F0 Fondamenta | `v1.0.0` |
| F1 micro_core | `v2.0.0` |
| F2 License Server | `v3.0.0` |
| F3 TrashCan | `v4.0.0` |
| F4 Full Freezer | `v5.0.0` |
| F5 Scorte Calore | `v6.0.0` |
| F6 Film Tracker | `v7.0.0` |
| F7 Hardening trasversale | `v8.0.0` |
| F8 Deploy e pubblicazione | `v9.0.0` |

### §5.4 versionName / versionCode delle app

Indipendenti dal versionamento del repo. Ogni app ha in `pubspec.yaml`
`version: <name>+<code>`:

- `versionName` semantico del **prodotto** (`1.0.0` al primo rilascio pubblico).
- `versionCode` intero **monotòno crescente**, mai riusato, incrementato a ogni AAB caricato
  su Play, anche per un upload di solo test.

☠ **Trappola**: Play rifiuta un AAB con un `versionCode` già visto, e quel numero non si
"libera". `tool/build_release.ps1` incrementa e committa il `versionCode` **prima** del
build, così un AAB buttato via consuma un numero ma non blocca il successivo.

### §5.5 Qualità del codice

- `analysis_options.yaml` alla radice estende `package:flutter_lints/flutter.yaml` e
  aggiunge: `prefer_final_locals`, `avoid_print`, `require_trailing_commas`,
  `use_super_parameters`, `unawaited_futures`, `always_declare_return_types`,
  `prefer_single_quotes`.
- `dart analyze` deve uscire con **zero** issue prima di ogni commit di fine fase.
- `dart format --line-length 100` su tutto il Dart; `prettier` sul TypeScript del server.
- Nessun `// ignore:` senza un commento sulla riga successiva che spiega perché.

### §5.6 Test: cosa si testa e cosa no

| Livello | Strumento | Cosa copre | Soglia |
|---|---|---|---|
| Unit puro | `flutter_test` / `node:test` | motori di calcolo (ricorrenze, consumo, aging, stato rullino), codec backup, `FeatureGate` | 100% dei rami dei motori |
| DB | `drift` + `NativeDatabase.memory()` | DAO e migrazioni | ogni DAO, ogni step di migrazione |
| Widget | `flutter_test` | pagine chiave, paywall, empty state | home + paywall + form principale per app |
| Golden | `matchesGoldenFile` | la home di ogni app in light e dark | 2 golden per app |
| Integrazione | `integration_test` | flusso "primo avvio → setup → dato inserito → notifica pianificata" | 1 per app |
| Server | `node:test` + `fastify.inject` | ogni endpoint, ogni codice d'errore | ogni rotta |

⚑ **Perché non si insegue la copertura percentuale**: il 100% sui motori serve perché un
errore lì è invisibile all'utente finché non sbaglia il giorno della raccolta. Il 100% sulla
UI costa più di quanto rende e ostacola il refactoring visivo, che in queste app sarà
frequente.

### §5.7 Remote git

| Repo | Remote | URL | Contenuto |
|---|---|---|---|
| Monorepo app | `origin` | `https://git.home.varitest.ovh/smp-webmaster/microapps.git` | app, `micro_core`, docs, tool |
| Monorepo app | `github` | `https://github.com/Frostmoore/smallapps.git` | **identico** a `origin` |
| Server | `origin` | `https://git.home.varitest.ovh/smp-webmaster/microapps-server.git` | solo il License Server |

**Regola**: ogni branch di versione del monorepo si pusha su **entrambi** i remote, nello
stesso momento e con lo stesso nome. Il server si pusha **solo** su `origin`, e non ha né
deve mai avere un remote GitHub.

```powershell
git push -u origin  vX.Y.Z
git push -u github  vX.Y.Z
```

☠ **Trappola**: il server non ha un remote `github` **per costruzione**. Se un giorno
qualcuno lo aggiunge "per comodità", i segreti di produzione, la logica di verifica delle
licenze e lo schema del registro acquisti diventano pubblici. Non aggiungerlo.

### §5.8 Toolchain Flutter locale al progetto

Flutter **non** si aggiorna a livello di sistema: sulla macchina di sviluppo ci sono altri
progetti che dipendono dalla versione vecchia. La versione usata qui è scaricata dentro il
progetto in `.flutter/` (ignorata da git) e si invoca tramite il wrapper `tool/fl.ps1`.

```powershell
pwsh tool/fl.ps1 --version        # equivale a .flutter\bin\flutter --version
pwsh tool/fl.ps1 pub get
pwsh tool/fl.ps1 run -d <device>
```

⚑ **Perché un wrapper e non il `PATH`**: modificare il `PATH` di sistema cambierebbe la
versione di Flutter per **tutti** i progetti della macchina, che è esattamente ciò che si
vuole evitare. Il wrapper rende impossibile usare per sbaglio la versione sbagliata, e rende
esplicito nel comando quale toolchain si sta usando.

---

## §6 — RITUALE DI FINE FASE (obbligatorio)

**Alla fine di ciascuna fase**, senza che nessuno lo chieda, nell'ordine esatto:

### 1. Aggiornare `develop_microapps.md`

- Spuntare in §7 le caselle della fase e di tutte le sue sottofasi.
- Se qualcosa è stato fatto diversamente da come scritto in §8, **riscrivere §8**, non
  lasciare la discrepanza.
- Se una sottofase è stata rinviata, spostarla in §9 (Debito tecnico) con motivo e scadenza.
- Aggiornare la riga "Stato" in testa al documento.

### 2. Aggiornare i `codebase_reference.md` toccati

L'atlante è il documento che permette di capire il codice **senza aprire i file**. Alla fine
di ogni fase, per ogni progetto toccato:

- Aggiungere/aggiornare: indice "dove sta cosa", albero file annotato, ogni classe con ogni
  metodo e **firma completa**, ogni tabella con ogni colonna, ogni endpoint, ogni chiave di
  configurazione, catalogo dei test, regole non negoziabili, trappole disinnescate, debito
  tecnico, e il *perché* delle scelte non ovvie.
- Segnare esplicitamente **cosa non esiste ancora**.
- **Verifica meccanica obbligatoria**: eseguire
  `pwsh tool/verify_atlas.ps1 -Project <path>`, che estrae con regex le firme pubbliche dal
  codice e le confronta con quelle citate nell'atlante, elencando le differenze. Zero
  differenze, o il rituale non è concluso.

⚑ **Perché la verifica è meccanica**: un atlante sbagliato è peggio di nessun atlante,
perché fa prendere decisioni su informazioni false. Rileggerlo a occhio non funziona alla
quinta fase.

### 3. Mandare un messaggio ESTREMAMENTE DETTAGLIATO

Contenente, in questo ordine:

1. **Stato dell'implementazione** complessivo (quante fasi chiuse, cosa gira davvero).
2. **Checkbox della fase e di tutte le sue sottofasi**, copiati da §7.
3. **Commento sullo stato generale** e **commento specifico sulla fase appena chiusa**:
   cosa è venuto bene, cosa è fragile, cosa è stato rinviato e perché.
4. Comandi esatti per verificare da soli quello che è stato fatto (build, test, run).
5. Branch e versione appena pushati.

### 4. Committare e pushare su un branch con una versione nuova

```powershell
pwsh tool/bump_version.ps1 -Large        # stampa es. v4.0.0
git checkout -b v4.0.0
git add -A
git commit -m "feat(trashcan): fase F3 completata — app TrashCan pronta per il canale interno"
git push -u origin v4.0.0
```

☠ **Trappola**: non si pusha mai su un branch di versione già pushato. Una versione è
immutabile: se serve una correzione, è una versione nuova.

---

## §7 — TRACKING DELLE FASI

Legenda: `[ ]` da fare · `[~]` in corso · `[x]` fatto · `[!]` bloccato · `[-]` annullato

### F0 — Fondamenta del repository e del toolchain → `v1.0.0`

- [x] **F0.1** Creazione repo Gitea, struttura cartelle, `develop_microapps.md`, spec versionate
- [x] **F0.2** Toolchain Flutter 3.47.3 / Dart 3.13.3 in `.flutter/`, usata via `tool/fl.ps1`
- [x] **F0.3** `analysis_options.yaml`, `.gitignore`, `.gitattributes`, `.flutter-version`
- [x] **F0.4** Script in `tool/` (`fl`, `get_flutter`, `pub_get_all`, `analyze_all`, `test_all`, `bump_version`, `verify_atlas`, `push_all`)
- [x] **F0.5** `README.md` con indice dei sei progetti e istruzioni di build
- [x] **F0.6** Keystore PKCS12 generato e copiato sul Desktop. **Resta un'azione per il committente**: una copia su un supporto diverso da questa macchina, vedi §10 rischi
- [x] **F0.7** Rituale di fine fase F0

### F1 — `micro_core`: il package condiviso → `v2.0.0`

- [x] **F1.1** Bootstrap del package, `pubspec.yaml`, barrel `micro_core.dart`
- [x] **F1.2** Utility di base: `Result`, `CivilDate`, `Money`, `MicroLog`, `AppPaths`, `AtomicFile`
- [x] **F1.3** `SettingsStore` (preferenze tipizzate su `shared_preferences`)
- [x] **F1.4** `InstallId` (UUID persistente in `flutter_secure_storage`)
- [x] **F1.5** Design system — token: `MicroTheme`, `MicroSpacing`, `MicroRadius`, `MicroDuration`, colori e testi semantici
- [x] **F1.6** Design system — dieci componenti: page scaffold, card, section header, list tile, stat tile, progress ring, empty state, bottone primario, chip, sheet di conferma, snackbar. La galleria `example/` è rinviata, vedi §9 DT-09
- [x] **F1.7** Billing: `PurchaseGateway`, `MicroProduct`, `PurchaseEvent`, `PlayPurchaseGateway`, `FakePurchaseGateway`
- [x] **F1.8** Entitlement: `Entitlement`, `EntitlementStore`, `EntitlementService`, `LicenseApi` + `LicenseApiClient`
- [x] **F1.9** Gating: `FeatureKey`, `FeatureLimit`, `FeatureGate`, `ProLock`, `ProBadge`, `PaywallPage`, `PaywallConfig`
- [x] **F1.10** Notifiche: `NotificationService`, canali, permessi, `replaceSchedule`, `NotificationIds`
- [x] **F1.11** Dati fuori dall'app: `BackupSource`, `BackupService`, `JsonBackupCodec`, `CsvWriter`, `ImageStore`. `PdfReportBuilder` rinviato a F6, vedi §9 DT-10
- [x] **F1.12** Test di `micro_core`: 100 test, inclusi quelli anti-regressione su ADR-007
- [x] **F1.13** `packages/micro_core/codebase_reference.md`
- [x] **F1.14** Rituale di fine fase F1

### F2 — MicroApps License Server → `v3.0.0`

- [ ] **F2.1** Bootstrap Node/TypeScript/Fastify, config e logging
- [ ] **F2.2** Schema SQLite, migrazioni, seed delle app e dei prodotti
- [ ] **F2.3** Plugin `auth` (HMAC device) e `rateLimit`
- [ ] **F2.4** `PlayVerifier`: verifica acquisti con Android Publisher v3
- [ ] **F2.5** `EntitlementService` lato server e rotte `/v1/purchases/verify`, `/v1/entitlements/:installId`
- [ ] **F2.6** Codici di ripristino: `/v1/restore/code`, `/v1/restore/claim`
- [ ] **F2.7** Real-time Developer Notifications: `/v1/rtdn` (rimborsi e revoche)
- [ ] **F2.8** Pannello admin: login, dashboard, elenco entitlement, ricerca, revoca manuale, audit log
- [ ] **F2.9** Backup automatico del database e rotazione
- [ ] **F2.10** Test del server (ogni rotta, ogni codice d'errore)
- [ ] **F2.11** Dockerfile, docker-compose, `.env.example`, healthcheck
- [ ] **F2.12** `server/codebase_reference.md`
- [ ] **F2.13** Rituale di fine fase F2

### F3 — TrashCan (app pilota, integrazione billing end-to-end) → `v4.0.0`

- [~] **F3.1** Progetto, dipendenze, l10n (it/en, 154 chiavi, zero non tradotte), font Outfit, rotte, limiti Pro; mancano tema e router
- [~] **F3.2** Data layer Drift: tabelle, mapper riga→dominio, `watchBundle` e 19 test. Mancano i DAO di scrittura e il test di migrazione (F3.2.6)
- [x] **F3.3** Motore delle ricorrenze `OccurrenceEngine` + 40 test
- [ ] **F3.4** Wizard di setup iniziale
- [ ] **F3.5** Home "Stasera / Prossima raccolta"
- [ ] **F3.6** Gestione tipi di rifiuto e regole (CRUD)
- [ ] **F3.7** Eccezioni: salta, sposta, raccolta straordinaria
- [ ] **F3.8** Notifiche: pianificazione, orari multipli, permesso exact alarm
- [ ] **F3.9** Calendari multipli + gating Pro + paywall
- [ ] **F3.10** Export/import calendario, backup, condivisione file
- [ ] **F3.11** Widget Android home-screen
- [ ] **F3.12** Play Console: creazione app, prodotto in-app, canale interno, verifica end-to-end del billing reale contro il server
- [ ] **F3.13** Test (unit, DB, widget, golden, integrazione)
- [ ] **F3.14** Rifinitura visiva, onboarding, empty state, accessibilità
- [x] **F3.15** `apps/trashcan/codebase_reference.md` (prima stesura, da riverificare a fine F3)
- [ ] **F3.16** Rituale di fine fase F3

### F4 — Full Freezer → `v5.0.0`

- [ ] **F4.1** Bootstrap progetto, tema, l10n, router
- [ ] **F4.2** Data layer Drift: freezer, scomparti, alimenti, movimenti
- [ ] **F4.3** `AgingCalculator` e ordinamento "oldest first" + test
- [ ] **F4.4** Home ordinata per anzianità, con sezione "Da usare prima"
- [ ] **F4.5** Inserimento rapido (obiettivo: sotto i 5 secondi) e inserimento completo
- [ ] **F4.6** Posizioni: freezer e scomparti, con conteggi
- [ ] **F4.7** Uscita alimento: consumato / buttato, con storico
- [ ] **F4.8** Ricerca istantanea
- [ ] **F4.9** Notifiche: digest aggregato settimanale/quindicinale/mensile
- [ ] **F4.10** Feature Pro: freezer multipli, foto, storico, statistiche, CSV, categorie personalizzate
- [ ] **F4.11** Widget Android "da consumare presto"
- [ ] **F4.12** Voice input Android per l'inserimento rapido
- [ ] **F4.13** Test (unit, DB, widget, golden, integrazione)
- [ ] **F4.14** Rifinitura visiva, onboarding, empty state, accessibilità
- [ ] **F4.15** `apps/full_freezer/codebase_reference.md`
- [ ] **F4.16** Rituale di fine fase F4

### F5 — Scorte Calore → `v6.0.0`

- [ ] **F5.1** Bootstrap progetto, tema, l10n, router
- [ ] **F5.2** Data layer Drift: fonti, misurazioni, acquisti, promemoria calendario
- [ ] **F5.3** `ConsumptionCalculator`: media mobile, rilevamento rifornimenti, qualità della stima + test
- [ ] **F5.4** Conversioni unità e capacità serbatoio (litri, percentuale, sacchi, kg, steri)
- [ ] **F5.5** Configurazione fonte combustibile (wizard)
- [ ] **F5.6** Dashboard: residuo, consumo medio, autonomia, data di riordino
- [ ] **F5.7** Aggiornamento scorta (il gesto più frequente dell'app)
- [ ] **F5.8** Notifiche di riordino e di superamento data
- [ ] **F5.9** Storico e grafici (Pro)
- [ ] **F5.10** Integrazione Google Calendar del dispositivo (Pro)
- [ ] **F5.11** Acquisti, costi, statistiche di spesa (Pro), CSV, backup
- [ ] **F5.12** Test (unit, DB, widget, golden, integrazione)
- [ ] **F5.13** Rifinitura visiva, onboarding, empty state, accessibilità
- [ ] **F5.14** `apps/scorte_calore/codebase_reference.md`
- [ ] **F5.15** Rituale di fine fase F5

### F6 — Film Tracker → `v7.0.0`

- [ ] **F6.1** Bootstrap progetto, tema scuro, l10n, router
- [ ] **F6.2** Data layer Drift: macchine, rullini, sviluppi, stampe, immagini, catalogo pellicole
- [ ] **F6.3** Macchina a stati del rullino + test
- [ ] **F6.4** Catalogo pellicole locale + pellicola personalizzata
- [ ] **F6.5** Inventario macchine fotografiche
- [ ] **F6.6** Creazione e modifica rullino; avanzamento di stato
- [ ] **F6.7** Sviluppo e stampa come eventi separati
- [ ] **F6.8** Home a tre sezioni: In macchina / In laboratorio / Archivio
- [ ] **F6.9** Photo overview: import, provini, contact sheet, miniature (Pro)
- [ ] **F6.10** Statistiche e costi (Pro)
- [ ] **F6.11** Export CSV, PDF di riepilogo, backup (Pro)
- [ ] **F6.12** QR identificativo del rullino
- [ ] **F6.13** Test (unit, DB, widget, golden, integrazione)
- [ ] **F6.14** Rifinitura visiva, onboarding, empty state, accessibilità
- [ ] **F6.15** `apps/film_tracker/codebase_reference.md`
- [ ] **F6.16** Rituale di fine fase F6

### F7 — Hardening trasversale e preparazione allo store → `v8.0.0`

- [ ] **F7.1** Revisione l10n completa (it/en) su tutte e quattro le app
- [ ] **F7.2** Accessibilità: contrasto, dimensioni dinamiche del testo, TalkBack, target di tocco
- [ ] **F7.3** Performance: tempo di avvio a freddo, jank, dimensione dell'AAB, R8/ProGuard
- [ ] **F7.4** Matrice di QA manuale su dispositivi e versioni Android
- [ ] **F7.5** Compliance Play: sezione Sicurezza dei dati, permessi dichiarati, `SCHEDULE_EXACT_ALARM`
- [ ] **F7.6** Asset dello store: icone, feature graphic, screenshot, descrizioni it/en
- [ ] **F7.7** Informative privacy pubblicate e raggiungibili da URL
- [ ] **F7.8** Verifica finale dei sei `codebase_reference.md` con `verify_atlas`
- [ ] **F7.9** Rituale di fine fase F7

### F8 — Deploy e pubblicazione → `v9.0.0`

- [x] **F8.1** Accesso SSH a `clawserver` verificato (anticipata il 2026-09-09)
- [ ] **F8.2** Ricognizione di `clawserver`: reverse proxy, porte, Docker, spazio, convivenza con OpenClaw
- [ ] **F8.3** Deploy del License Server in Docker, con volume persistente e healthcheck
- [ ] **F8.4** TLS, dominio, reverse proxy, hardening di rete
- [ ] **F8.5** Backup del database del server e verifica del ripristino
- [ ] **F8.6** Service account Google Play e collegamento Android Publisher API
- [ ] **F8.7** Pub/Sub per le Real-time Developer Notifications
- [ ] **F8.8** Release chiuse (closed testing) delle quattro app, 14 giorni di test
- [ ] **F8.9** Pubblicazione in produzione, monitoraggio della prima settimana
- [ ] **F8.10** Rituale di fine fase F8

---

## §8 — Guida allo sviluppo, fase per fase

Questa è la parte operativa. Si esegue in ordine. Ogni sottofase ha: obiettivo, azioni
concrete, file esatti da creare, firme reali, motivazioni e criteri di chiusura.

---

## F0 — Fondamenta del repository e del toolchain

**Obiettivo della fase**: avere un repository Gitea funzionante, un toolchain capace di
produrre AAB accettabili da Google Play, e gli script che rendono ripetibili le operazioni
che verranno fatte cento volte.

### F0.1 — Repo Gitea, struttura, spec versionate ✅

▶ Azioni:

1. `git init` nella cartella di lavoro, branch iniziale `v1.0.0`.
2. Creare l'albero di §4 (cartelle vuote con `.gitkeep` dove serve).
3. Copiare le quattro spec da `memory/*.md` a `docs/specs/*.md`.
4. Scrivere `develop_microapps.md` (questo file).
5. `git remote add origin https://git.home.varitest.ovh/smp-webmaster/microapps.git`
6. `git push -u origin v1.0.0` (push-to-create: Gitea crea la repo al primo push).

⚑ **Perché le spec vengono copiate in `docs/specs/` e non lasciate in `memory/`**:
`memory/` è memoria dell'agente, non è codice, e su un'altra macchina non esiste. Il
contratto di prodotto deve stare nella repo, versionato, con la stessa storia del codice che
lo implementa.

✔ DoD: la repo è visibile su Gitea, contiene `develop_microapps.md` e `docs/specs/` con
quattro file, il branch è `v1.0.0`.

### F0.2 — Toolchain Flutter e licenze Android

▶ Azioni:

1. `flutter upgrade` → verificare `flutter --version` ≥ 3.35 stable (ADR-002).
2. `flutter doctor --android-licenses` → accettare tutte.
3. `flutter doctor -v` → nessuna `X` residua tranne, eventualmente, quella su VS Code.
4. Scrivere la versione esatta in `.flutter-version` (una riga, es. `3.35.4`).
5. Verificare che `flutter create --platforms=android /tmp/probe && cd /tmp/probe && flutter build appbundle --release` produca un AAB. Cancellare `probe`.

☠ **Trappola**: se `flutter build appbundle` fallisce con errori di Gradle/JDK, la causa
quasi sempre è il JDK usato da Gradle diverso da quello di sistema. Si forza con
`flutter config --jdk-dir "<path JDK 17>"`. Non si aggira installando un JDK diverso.

✔ DoD: `.flutter-version` committato; un AAB di prova è stato prodotto e cancellato;
`flutter doctor` pulito.

### F0.3 — Configurazione di qualità del repo

▶ File da creare:

**`analysis_options.yaml`** (radice)

```yaml
include: package:flutter_lints/flutter.yaml
analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/generated_plugin_registrant.dart"
linter:
  rules:
    always_declare_return_types: true
    avoid_print: true
    prefer_final_locals: true
    prefer_single_quotes: true
    require_trailing_commas: true
    unawaited_futures: true
    use_super_parameters: true
    sort_child_properties_last: true
```

⚑ **Perché `strict-casts`**: senza, `dynamic` proveniente dal JSON dei backup si propaga
silenziosamente nel codice e i cast falliscono a runtime sul telefono dell'utente invece che
in compilazione sulla macchina di sviluppo.

**`.gitignore`** (radice) — deve coprire: `build/`, `.dart_tool/`, `.flutter-plugins*`,
`*.iml`, `.idea/`, `android/local.properties`, `android/key.properties`, `*.jks`, `*.keystore`,
`server/node_modules/`, `server/dist/`, `server/data/`, `server/.env`, `*.log`,
`**/failures/` (golden test falliti).

☠ **Trappola**: `key.properties` e `*.jks` fuori dal repo **sempre**. Un keystore committato
non si può "de-committare": va rigenerato, e se l'app è già pubblicata con quella firma non
si può più aggiornare. È l'errore più costoso possibile in questo progetto.

**`.gitattributes`** — `* text=auto eol=lf`, con `*.ps1 text eol=crlf` e `*.jks binary`.

⚑ **Perché**: si sviluppa su Windows e si esegue il server su Linux. Senza normalizzazione,
gli script shell del container arrivano con CRLF e il container non parte con un errore
incomprensibile (`exec /entrypoint.sh: no such file or directory`).

✔ DoD: i tre file esistono, `dart analyze` gira alla radice senza crash.

### F0.4 — Script operativi in `tool/`

Tutti in PowerShell, perché la macchina di sviluppo è Windows.

| Script | Firma | Cosa fa |
|---|---|---|
| `tool/get_flutter.ps1` | `-Version <x.y.z>`, `-Force` | Scarica la toolchain Flutter in `.flutter/`, verifica lo SHA256 dell'archivio e aggiorna `.flutter-version`. Non tocca il Flutter di sistema. |
| `tool/fl.ps1` | argomenti passati a `flutter` | Wrapper obbligatorio sulla toolchain del progetto (§5.8). |
| `tool/push_all.ps1` | `-Branch <nome>` | Pusha il branch su `origin` e `github`. Si rifiuta di procedere se il monorepo traccia file del server (ADR-001). |
| `tool/pub_get_all.ps1` | `-Clean` (switch) | `flutter pub get` su `packages/micro_core` e sulle quattro app, in quest'ordine. Con `-Clean` fa prima `flutter clean`. |
| `tool/analyze_all.ps1` | — | `dart analyze` su tutti e cinque i progetti Dart; esce con codice ≠ 0 alla prima issue. |
| `tool/test_all.ps1` | `-Coverage` (switch), `-Project <nome>` | `flutter test` su tutti o su uno; con `-Coverage` produce `coverage/lcov.info`. |
| `tool/bump_version.ps1` | `-Small` / `-Medium` / `-Large`, `-Create` (switch) | Legge i branch `v*`, ordina per semver, stampa la versione successiva. Con `-Create` crea e fa il checkout del branch. |
| `tool/verify_atlas.ps1` | `-Project <path>` | Estrae le firme pubbliche (`class`, `abstract interface class`, metodi pubblici, `enum`) dal codice del progetto e le confronta con quelle citate in `<path>/codebase_reference.md`. Stampa `MISSING_IN_DOC` e `MISSING_IN_CODE`. Esce ≠ 0 se una delle due liste non è vuota. |
| `tool/build_release.ps1` | `-App <nome>`, `-All` (switch) | Incrementa il `versionCode` nel `pubspec.yaml`, committa il bump, esegue `flutter build appbundle --release` con i `--dart-define` di produzione, copia l'AAB in `dist/`. |

⚑ **Perché `verify_atlas.ps1` esiste**: il rituale di fine fase impone di verificare
meccanicamente che l'atlante corrisponda al codice. Un controllo a occhio funziona la prima
volta e fallisce dalla terza. Lo script non deve essere perfetto: deve essere
**abbastanza rumoroso** da far notare le divergenze.

✔ DoD: i sei script esistono, sono documentati in `README.md`, e `analyze_all.ps1` e
`bump_version.ps1` sono stati eseguiti almeno una volta con successo.

### F0.5 — `README.md`

Contenuto minimo: cos'è il progetto, tabella dei sei sotto-progetti con link al rispettivo
`codebase_reference.md`, prerequisiti (Flutter pinnato, JDK 17, Node 22), comandi per
buildare ed eseguire ciascuna app, comando per far girare il server in locale, e il rimando
a `develop_microapps.md` per lo stato dello sviluppo.

✔ DoD: da `README.md` una persona che non ha mai visto il progetto sa lanciare un'app in
debug in meno di cinque minuti.

### F0.6 — Keystore di firma Android

**Stato**: keystore generato il 2026-09-09.

| Voce | Valore |
|---|---|
| File | `%USERPROFILE%\.android-keys\microapps-upload.p12` |
| Formato | PKCS12 (non JKS: `keytool` segnala JKS come formato proprietario e deprecato) |
| Alias | `microapps` |
| Chiave | RSA 4096, SHA384withRSA |
| Validità | dal 2026-09-09 al 2054-01-25 |
| Impronta SHA256 | `51:05:48:49:B5:B5:BD:A9:21:38:60:6B:F0:9E:FB:FE:6D:48:80:89:2F:FD:92:A3:97:1A:28:87:71:D3:0E:9F` |
| Password | 32 caratteri casuali, in `%USERPROFILE%\.android-keys\microapps-upload.password.txt` |

⚑ **Perché la validità fino al 2054**: Google Play richiede che la chiave di upload sia
valida almeno fino al 2033. Dieci anni oltre il minimo evitano di doverci ripensare.

▶ Azioni residue:

1. Creare `apps/<app>/android/key.properties` (ignorato da git) con `storeFile`,
   `storePassword`, `keyAlias`, `keyPassword`. Si fa quando l'app esiste, in `X.1`.
2. Configurare `signingConfigs.release` in `apps/<app>/android/app/build.gradle.kts` leggendo
   `key.properties`, con fallback esplicito che **fa fallire il build** se il file manca,
   invece di firmare con la chiave di debug.
3. **[AZIONE PER IL COMMITTENTE]** Fare due backup del `.p12` e della password in luoghi
   diversi, e annotare dove, in un documento che **non** è in questa repo. Non è un passo
   delegabile: chi ha i backup deve essere chi ha accesso ai luoghi dove metterli.

⚑ **Perché un keystore solo per quattro app**: sono quattro app dello stesso publisher,
gestite dalla stessa persona. Quattro keystore significano quattro cose da non perdere invece
di una. Google Play App Signing manterrà comunque una chiave di firma distinta per app; questa
è solo la chiave di *upload*.

☠ **Trappola**: se il build di release firma con la chiave di debug perché `key.properties`
manca, l'AAB viene rifiutato da Play con un messaggio poco chiaro. Il fallback deve essere
`throw GradleException("key.properties mancante")`.

✔ DoD: `flutter build appbundle --release` di un'app di prova produce un AAB firmato con la
chiave di upload; il keystore non compare in `git status` né in `git log`.

### F0.7 — Rituale di fine fase F0

Eseguire §6 per intero. Branch previsto: `v1.0.0` (già creato in F0.1; se sono stati fatti
commit intermedi, chiudere sulla versione raggiunta).

---

## F1 — `micro_core`: il package condiviso

**Obiettivo della fase**: avere un package Dart che le quattro app importano con una sola
riga (`import 'package:micro_core/micro_core.dart';`) e che fornisce tutto ciò che non è
dominio specifico: tema, componenti, acquisti, licenze, gating, notifiche, backup, export,
immagini.

**Regola non negoziabile**: `micro_core` **non conosce nessuna delle quattro app**. Non c'è
un `if (appId == 'trashcan')` da nessuna parte. Tutto ciò che varia si passa come parametro.

⚑ **Perché**: il giorno in cui si aggiunge una quinta app, `micro_core` non deve cambiare di
una riga. Se cambia, il confine è stato messo nel posto sbagliato.

### F1.1 — Bootstrap del package

▶ Azioni:

1. `flutter create --template=package packages/micro_core`
2. Scrivere `packages/micro_core/pubspec.yaml`:

```yaml
name: micro_core
description: Nucleo condiviso delle MicroApps: tema, billing, entitlement, notifiche, backup.
version: 1.0.0
publish_to: none

environment:
  sdk: ">=3.9.0 <4.0.0"
  flutter: ">=3.35.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  shared_preferences: ^2.3.0
  flutter_secure_storage: ^9.2.0
  path_provider: ^2.1.4
  path: ^1.9.0
  uuid: ^4.5.0
  crypto: ^3.0.5
  http: ^1.2.2
  in_app_purchase: ^3.2.0
  flutter_local_notifications: ^18.0.0
  timezone: ^0.10.0
  flutter_timezone: ^3.0.0
  image: ^4.3.0
  share_plus: ^10.0.0
  file_picker: ^8.1.0
  pdf: ^3.11.0
  printing: ^5.13.0
  intl: ^0.19.0
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

3. Creare il barrel `packages/micro_core/lib/micro_core.dart` che esporta **solo** i file
   pubblici di `lib/src/`. Nessuna app importa mai `package:micro_core/src/...`.

⚑ **Perché il barrel**: rende esplicita la superficie pubblica. Quando si aggiunge un file
in `src/` e non lo si esporta, non è API: è dettaglio interno, e lo si può cambiare senza
rompere le app.

✔ DoD: `flutter pub get` in `packages/micro_core` va a buon fine; il barrel compila; una app
di prova che importa il barrel compila.

### F1.2 — Utility di base

**`lib/src/util/result.dart`**

```dart
sealed class Result<T> {
  const Result();
  bool get isOk;
  T? get valueOrNull;
  MicroError? get errorOrNull;
  R fold<R>({required R Function(T value) ok, required R Function(MicroError error) err});
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);
  final MicroError error;
}

class MicroError {
  const MicroError({required this.code, required this.message, this.cause, this.stackTrace});
  final String code;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  @override String toString();
}
```

⚑ **Perché `Result` e non eccezioni ovunque**: le operazioni che possono fallire per cause
*attese* (rete assente, file corrotto, acquisto annullato) non sono eccezioni: sono esiti. Le
eccezioni restano per i bug. Questo evita il `try/catch` decorativo intorno a ogni chiamata.

**`lib/src/util/civil_date.dart`** — il tipo che implementa ADR-008.

```dart
@immutable
final class CivilDate implements Comparable<CivilDate> {
  const CivilDate(this.year, this.month, this.day);
  factory CivilDate.fromDateTime(DateTime dt);
  factory CivilDate.today({DateTime? now});
  factory CivilDate.parse(String iso);          // 'YYYY-MM-DD', lancia FormatException
  static CivilDate? tryParse(String? iso);

  final int year;
  final int month;
  final int day;

  String toIso();                                // 'YYYY-MM-DD'
  DateTime toLocalMidnight();
  DateTime toLocalDateTime(int hour, int minute);
  int get weekday;                               // DateTime.monday..DateTime.sunday
  int get epochDay;                              // giorni dal 1970-01-01, per aritmetica e ordinamento
  CivilDate addDays(int days);
  CivilDate addMonths(int months);               // clamp a fine mese: 31 gennaio + 1 mese = 28/29 febbraio
  int daysUntil(CivilDate other);
  bool isBefore(CivilDate other);
  bool isAfter(CivilDate other);
  bool get isToday;
  @override int compareTo(CivilDate other);
  @override bool operator ==(Object other);
  @override int get hashCode;
  @override String toString();                   // == toIso()
}

extension CivilDateRange on CivilDate {
  Iterable<CivilDate> rangeTo(CivilDate end);    // inclusivo
}
```

☠ **Trappola disinnescata**: `addMonths` deve fare il clamp (31 gennaio + 1 mese = 28
febbraio, non 3 marzo). Senza il clamp, la regola "raccolta il 31 di ogni mese" salta i mesi
corti e genera date nel mese successivo. Test obbligatorio in
`test/util/civil_date_test.dart`.

**`lib/src/util/money.dart`**

```dart
@immutable
final class Money implements Comparable<Money> {
  const Money.cents(this.cents, {this.currency = 'EUR'});
  factory Money.fromDouble(double amount, {String currency = 'EUR'});
  final int cents;
  final String currency;
  double get asDouble;
  Money operator +(Money other);
  Money operator -(Money other);
  Money operator *(num factor);
  String format({String? locale});               // usa intl NumberFormat.currency
  static Money zero({String currency = 'EUR'});
  static Money sum(Iterable<Money> values, {String currency = 'EUR'});
}
```

⚑ **Perché i centesimi interi**: Film Tracker e Scorte Calore sommano decine di importi. Con
i `double`, "231,00 €" diventa "230,99999999999997 €" nella schermata delle statistiche, e
l'utente perde fiducia in tutto il resto dei numeri.

**`lib/src/util/micro_log.dart`**

```dart
enum LogLevel { debug, info, warn, error }

class MicroLog {
  static void init({required File file, LogLevel minLevel = LogLevel.info, int maxBytes = 512 * 1024});
  static void d(String message, {Object? data});
  static void i(String message, {Object? data});
  static void w(String message, {Object? error});
  static void e(String message, {Object? error, StackTrace? stackTrace});
  static Future<File?> exportLog();
  static Future<void> clear();
}
```

⚑ **Perché un log su file e non `print`**: `avoid_print` è attivo (ADR/§5.5) e in release
`print` non arriva da nessuna parte. Con un file a rotazione, quando un utente scrive "le
notifiche non arrivano" gli si può chiedere di esportare il log dalle impostazioni.

**`lib/src/storage/app_paths.dart`**

```dart
class AppPaths {
  static Future<AppPaths> resolve({required String appId});
  final Directory documents;      // dati dell'app, inclusi nel backup di sistema
  final Directory support;        // entitlement.json, log
  final Directory images;         // documents/images
  final Directory thumbs;         // documents/images/thumbs
  final Directory exports;        // cache/exports, cancellabile
  Future<void> ensureAll();
  File file(Directory dir, String name);
}
```

**`lib/src/storage/atomic_file.dart`**

```dart
class AtomicFile {
  static Future<void> writeString(File target, String contents);   // scrive .tmp, fsync, rename
  static Future<void> writeBytes(File target, List<int> bytes);
  static Future<String?> readStringOrNull(File target);
}
```

⚑ **Perché la scrittura atomica**: `entitlement.json` e i backup si scrivono mentre l'utente
può chiudere l'app o il sistema può ucciderla. Una scrittura non atomica lascia un file
troncato: al riavvio l'utente che ha pagato risulta gratuito. Scrivere su `.tmp` e fare
`rename` rende l'operazione atomica sul filesystem.

✔ DoD F1.2: ogni classe ha il suo test in `test/util/`; `CivilDate` ha almeno i casi
ora legale, fine mese, anno bisestile.

### F1.3 — `SettingsStore`

**`lib/src/prefs/settings_store.dart`**

```dart
class SettingsStore {
  static Future<SettingsStore> create({required String namespace});
  String get namespace;

  bool getBool(String key, {required bool orElse});
  Future<void> setBool(String key, bool value);
  int getInt(String key, {required int orElse});
  Future<void> setInt(String key, int value);
  double getDouble(String key, {required double orElse});
  Future<void> setDouble(String key, double value);
  String? getString(String key);
  Future<void> setString(String key, String value);
  List<String> getStringList(String key);
  Future<void> setStringList(String key, List<String> value);
  CivilDate? getDate(String key);
  Future<void> setDate(String key, CivilDate value);
  DateTime? getInstant(String key);
  Future<void> setInstant(String key, DateTime value);
  Future<void> remove(String key);
  Future<void> clearNamespace();
  Stream<String> get changes;                    // emette la chiave modificata
}

class SettingKeys {
  static const String onboardingDone = 'onboarding_done';
  static const String themeMode = 'theme_mode';           // system|light|dark
  static const String notificationsEnabled = 'notifications_enabled';
  static const String lastRescheduleAt = 'last_reschedule_at';
  static const String lastServerSyncAt = 'last_server_sync_at';
  static const String paywallShownCount = 'paywall_shown_count';
  static const String reviewPromptShownAt = 'review_prompt_shown_at';
}
```

⚑ **Perché il `namespace`**: le quattro app hanno preferenze omonime (`onboarding_done`). In
test e in eventuali build multi-flavor il namespace evita collisioni; in produzione, dove i
processi sono separati, è un costo nullo.

### F1.4 — `InstallId`

**`lib/src/install/install_id.dart`**

```dart
class InstallId {
  static Future<InstallId> load({required String appId});
  String get value;                 // UUIDv4, minuscolo, con trattini
  String get obfuscatedAccountId;   // sha256(value) troncato a 64 char, per Play Billing
  Future<void> regenerate();        // solo per debug e test; logga a livello warn
}
```

⚑ **Perché `obfuscatedAccountId` derivato e non l'UUID diretto**: Google Play accetta un
identificatore offuscato dell'account da associare all'acquisto, e chiede esplicitamente che
non sia un identificatore personale né ricostruibile. L'hash tronca il legame e resta stabile,
il che permette in seguito di correlare un acquisto Play a un `install_id` senza esporlo.

☠ **Trappola**: `flutter_secure_storage` su Android usa il Keystore, che in rari casi (backup
e restore del dispositivo, cambio di blocco schermo su vecchie ROM) restituisce dati
illeggibili. `load()` deve gestire l'eccezione, rigenerare l'ID, loggare a `warn` e
**continuare**, mai crashare. L'utente perde l'associazione al server, non l'entitlement
locale (ADR-007).

### F1.5 — Design system: token

**`lib/src/theme/micro_spacing.dart`**

```dart
abstract final class MicroSpacing {
  static const double xxs = 2, xs = 4, s = 8, m = 12, l = 16, xl = 24, xxl = 32, xxxl = 48;
  static const EdgeInsets pageH = EdgeInsets.symmetric(horizontal: l);
  static const EdgeInsets card = EdgeInsets.all(l);
  static const SizedBox gapS = SizedBox(height: s);
  static const SizedBox gapM = SizedBox(height: m);
  static const SizedBox gapL = SizedBox(height: l);
  static const SizedBox gapXL = SizedBox(height: xl);
}

abstract final class MicroRadius {
  static const Radius small = Radius.circular(8);
  static const Radius medium = Radius.circular(14);
  static const Radius large = Radius.circular(22);
  static const BorderRadius card = BorderRadius.all(medium);
  static const BorderRadius sheet = BorderRadius.vertical(top: large);
}
```

**`lib/src/theme/micro_theme.dart`**

```dart
class MicroTheme {
  static ThemeData build({
    required Color seed,
    required Brightness brightness,
    required String fontFamily,
    String? displayFontFamily,
    double textScaleBase = 1.0,
  });

  static ThemeData light({required Color seed, required String fontFamily, String? displayFontFamily});
  static ThemeData dark({required Color seed, required String fontFamily, String? displayFontFamily});
}

extension MicroColorScheme on ColorScheme {
  Color get success;
  Color get onSuccess;
  Color get warning;
  Color get onWarning;
  Color get neutralSurface;      // sfondo delle card, distinto da surface
  Color get subtleBorder;
}
```

⚑ **Perché colori semantici come extension e non costanti globali**: `success` e `warning`
devono derivare dal seed dell'app e dalla brightness, altrimenti il verde di "consumato" del
freezer stona con il blu ghiaccio. Come extension su `ColorScheme` restano accessibili
ovunque con `Theme.of(context).colorScheme.success` e cambiano da sole con il tema.

**`lib/src/theme/micro_text_styles.dart`**

```dart
extension MicroTextTheme on TextTheme {
  TextStyle get numeric;      // tabular figures, per i numeri in colonna
  TextStyle get cardTitle;
  TextStyle get cardMeta;
  TextStyle get statValue;    // grande, per i numeri della dashboard
  TextStyle get statLabel;
}
```

☠ **Trappola**: senza `fontFeatures: [FontFeature.tabularFigures()]` le liste di numeri
(giorni nel freezer, giorni di autonomia, costi) "ballano" in larghezza tra una riga e
l'altra. È il dettaglio che distingue un'app curata da una fatta in fretta.

### F1.6 — Design system: componenti

Tutti in `lib/src/ui/`. Nessuno di questi widget ha stato interno oltre alle animazioni.

| Widget | Firma del costruttore | Uso |
|---|---|---|
| `MicroPageScaffold` | `MicroPageScaffold({required String title, Widget? subtitle, required Widget body, List<Widget> actions = const [], Widget? floatingAction, bool scrollable = true, VoidCallback? onBack})` | Impalcatura standard di ogni pagina |
| `MicroCard` | `MicroCard({required Widget child, VoidCallback? onTap, Color? accent, EdgeInsets padding = MicroSpacing.card, bool emphasized = false})` | Contenitore base |
| `MicroSectionHeader` | `MicroSectionHeader({required String title, String? count, Widget? trailing})` | Titolo di sezione della home |
| `MicroStatTile` | `MicroStatTile({required String label, required String value, String? hint, IconData? icon, Color? accent})` | Numero grande + etichetta |
| `MicroListTile` | `MicroListTile({required String title, String? subtitle, String? trailingText, Widget? leading, Color? accent, VoidCallback? onTap, List<MicroSwipeAction> swipeActions = const []})` | Riga di lista con azioni di swipe |
| `MicroEmptyState` | `MicroEmptyState({required IconData icon, required String title, required String message, String? actionLabel, VoidCallback? onAction})` | Stato vuoto |
| `MicroPrimaryButton` | `MicroPrimaryButton({required String label, required VoidCallback? onPressed, IconData? icon, bool loading = false, bool expanded = true})` | CTA |
| `MicroChip` | `MicroChip({required String label, bool selected = false, Color? color, IconData? icon, VoidCallback? onTap})` | Filtri e categorie |
| `MicroProgressRing` | `MicroProgressRing({required double value, required String centerLabel, String? centerSubLabel, Color? color, double size = 140})` | Anello di autonomia/riempimento |
| `MicroConfirmSheet` | `static Future<bool> show(BuildContext context, {required String title, required String message, required String confirmLabel, String? cancelLabel, bool destructive = false})` | Conferma delle azioni distruttive |
| `MicroSnack` | `static void success(BuildContext, String message, {String? undoLabel, VoidCallback? onUndo})` · `static void error(BuildContext, String message)` | Feedback |

```dart
class MicroSwipeAction {
  const MicroSwipeAction({required this.label, required this.icon, required this.color, required this.onInvoke});
  final String label;
  final IconData icon;
  final Color color;
  final Future<bool> Function() onInvoke;   // true = la riga sparisce
}
```

⚑ **Perché lo swipe con undo e non la conferma modale**: in Full Freezer l'azione
"consumato" si fa dieci volte a settimana. Una conferma modale per un'azione frequente e
reversibile è una tassa. Lo swipe con snackbar di annullamento è più veloce e più sicuro,
perché l'annullamento è a portata di pollice.

✔ DoD F1.5–F1.6: esiste `packages/micro_core/example/` (una app di galleria) che mostra ogni
componente in light e dark, e ci sono due golden test della galleria.

⚑ **Perché una app di galleria**: senza, ogni componente si vede solo dentro un'app reale, e
un difetto grafico in dark mode si scopre a fase finita. La galleria costa mezza giornata e
si ripaga alla prima app.

### F1.7 — Billing

**`lib/src/billing/micro_product.dart`**

```dart
@immutable
class MicroProduct {
  const MicroProduct({required this.id, required this.title, required this.description,
    required this.formattedPrice, required this.rawPriceMicros, required this.currencyCode});
  final String id;
  final String title;
  final String description;
  final String formattedPrice;     // già localizzato da Play, es. "2,99 €"
  final int rawPriceMicros;
  final String currencyCode;
  Money get price;
}
```

**`lib/src/billing/purchase_event.dart`**

```dart
sealed class PurchaseEvent {
  const PurchaseEvent(this.productId);
  final String productId;
}
final class PurchasePending extends PurchaseEvent { const PurchasePending(super.productId); }
final class PurchaseSucceeded extends PurchaseEvent {
  const PurchaseSucceeded(super.productId, {required this.purchaseToken, required this.orderId, required this.purchasedAt, required this.restored});
  final String purchaseToken;
  final String? orderId;
  final DateTime purchasedAt;
  final bool restored;             // true se proviene da restorePurchases()
}
final class PurchaseCanceled extends PurchaseEvent { const PurchaseCanceled(super.productId); }
final class PurchaseFailed extends PurchaseEvent {
  const PurchaseFailed(super.productId, {required this.code, required this.message});
  final String code;
  final String message;
}
```

**`lib/src/billing/purchase_gateway.dart`**

```dart
abstract interface class PurchaseGateway {
  Future<bool> isAvailable();
  Future<void> init();
  Stream<PurchaseEvent> get events;
  Future<Result<List<MicroProduct>>> loadProducts(Set<String> productIds);
  Future<Result<void>> buy(MicroProduct product, {required String obfuscatedAccountId});
  Future<Result<void>> restorePurchases();
  Future<void> completePurchase(PurchaseSucceeded event);   // acknowledge lato Play
  Future<void> dispose();
}
```

**`lib/src/billing/play_purchase_gateway.dart`** — implementazione su `in_app_purchase`.

☠ **Trappola numero uno del billing Android**: un acquisto **non riconosciuto** entro 3
giorni viene **rimborsato automaticamente** da Google. Il riconoscimento
(`completePurchase`) va fatto **dopo** aver scritto l'entitlement in locale, e va rifatto al
riavvio per gli acquisti pendenti trovati in `purchaseStream`. `PlayPurchaseGateway` deve
esporre `Future<void> acknowledgePending()` chiamato in `EntitlementService.bootstrap()`.

☠ **Trappola numero due**: `in_app_purchase` consegna gli acquisti passati sullo stream
**all'avvio**, non solo dopo `restorePurchases()`. Il codice che ascolta lo stream deve
essere idempotente: ricevere due volte lo stesso `purchaseToken` non deve produrre due
chiamate di verifica al server né due snackbar "Grazie per l'acquisto".

**`lib/src/billing/fake_purchase_gateway.dart`**

```dart
class FakePurchaseGateway implements PurchaseGateway {
  FakePurchaseGateway({
    List<MicroProduct> catalog = const [],
    Duration latency = const Duration(milliseconds: 600),
    FakeOutcome outcome = FakeOutcome.success,
    bool startsOwned = false,
  });
  FakeOutcome outcome;                 // modificabile a runtime dal pannello di debug
  bool get owned;
  void reset();
}

enum FakeOutcome { success, canceled, failed, pendingForever, unavailable }
```

⚑ **Perché `FakeOutcome` include `pendingForever`**: il caso reale più insidioso è
l'acquisto in attesa (pagamento con carta che richiede conferma, o metodo "paga in
contanti" in alcuni paesi). La UI deve mostrare uno stato "in elaborazione" e non lasciare
l'utente su uno spinner infinito. Senza il fake, questo caso non si testa mai.

### F1.8 — Entitlement

**`lib/src/entitlement/entitlement.dart`**

```dart
enum ProStatus { free, pro, pending, revoked }
enum EntitlementSource { none, local, play, server }

@immutable
class Entitlement {
  const Entitlement({required this.appId, required this.status, required this.source,
    this.productId, this.purchaseToken, this.purchasedAt, this.verifiedAt, this.revokedAt});
  factory Entitlement.free(String appId);
  factory Entitlement.fromJson(Map<String, Object?> json);

  final String appId;
  final ProStatus status;
  final EntitlementSource source;
  final String? productId;
  final String? purchaseToken;
  final DateTime? purchasedAt;
  final DateTime? verifiedAt;
  final DateTime? revokedAt;

  bool get isPro;                                  // status == pro
  bool get isPending;                              // status == pending
  Map<String, Object?> toJson();
  Entitlement copyWith({...});
  bool supersedes(Entitlement other);              // regola di fiducia ADR-007
}
```

⚑ **`supersedes` è il cuore di ADR-007**. Regole, in ordine:

1. Un entitlement con `status == revoked` e `source == server` vince sempre.
2. A parità di stato, vince la `source` più alta (`server` > `play` > `local` > `none`).
3. Uno stato `pro` non viene **mai** sostituito da uno `free` proveniente da `source` uguale
   o inferiore.
4. A parità di stato e sorgente, vince il `verifiedAt` più recente.

**`lib/src/entitlement/entitlement_store.dart`**

```dart
class EntitlementStore {
  EntitlementStore({required File file});
  static Future<EntitlementStore> open({required AppPaths paths});
  Future<Entitlement> read(String appId);
  Future<void> write(Entitlement entitlement);     // via AtomicFile
  Future<void> clear();
}
```

**`lib/src/entitlement/license_api_client.dart`**

```dart
class LicenseApiClient {
  LicenseApiClient({required this.baseUri, required this.appId, required this.appSecret,
    required this.installId, http.Client? httpClient, Duration timeout = const Duration(seconds: 8)});

  final Uri baseUri;
  final String appId;
  final String appSecret;
  final String installId;

  Future<Result<ServerEntitlement>> verifyPurchase({
    required String productId, required String purchaseToken, String? orderId, required String appVersion});
  Future<Result<ServerEntitlement>> fetchEntitlement();
  Future<Result<RestoreCode>> createRestoreCode();
  Future<Result<ServerEntitlement>> claimRestoreCode(String code);
}

@immutable
class ServerEntitlement {
  final String appId; final ProStatus status; final String? productId;
  final DateTime? purchasedAt; final DateTime? revokedAt; final DateTime serverTime;
  factory ServerEntitlement.fromJson(Map<String, Object?> json);
}

@immutable
class RestoreCode {
  final String code;          // 8 caratteri, alfabeto senza ambiguità
  final DateTime expiresAt;
}
```

☠ **Trappola**: `timeout` breve (8 s) e **nessun retry automatico** nel client. Il retry è
responsabilità di `EntitlementService`, che sa se l'operazione è critica (verifica dopo un
acquisto: sì, con backoff) o opportunistica (sync periodica: no, si riproverà domani).

**`lib/src/entitlement/entitlement_service.dart`**

```dart
class EntitlementService extends ChangeNotifier {
  EntitlementService({
    required String appId,
    required Set<String> proProductIds,
    required PurchaseGateway gateway,
    required EntitlementStore store,
    required InstallId installId,
    LicenseApiClient? api,
    required String appVersion,
  });

  Entitlement get current;
  bool get isPro;
  bool get isBusy;
  List<MicroProduct> get products;
  MicroError? get lastError;

  Future<void> bootstrap();            // legge locale, apre gateway, riconcilia pendenti, sync opportunistica
  Future<Result<void>> buyPro();
  Future<Result<void>> restorePurchases();
  Future<Result<void>> refreshFromServer();
  Future<Result<RestoreCode>> createRestoreCode();
  Future<Result<void>> claimRestoreCode(String code);
  Future<void> debugGrantPro();        // solo in debug; assert(kDebugMode)
  @override void dispose();
}
```

Sequenza di `bootstrap()`, da rispettare alla lettera:

1. `store.read(appId)` → stato locale, notificato **subito** (la UI non aspetta la rete).
2. `gateway.init()`; se non disponibile (device senza Play Services), si esce restando con lo
   stato locale.
3. Ascolto di `gateway.events` con deduplica per `purchaseToken`.
4. `gateway.restorePurchases()` silenzioso: gli acquisti già posseduti riemergono.
5. Per ogni `PurchaseSucceeded`: scrivi entitlement `source: play` → `completePurchase()` →
   se `api != null`, `verifyPurchase()` con 3 tentativi a backoff esponenziale (2 s, 8 s, 30 s)
   e in caso di successo riscrivi con `source: server`.
6. Se sono passate più di 24 ore da `lastServerSyncAt` e `api != null`: `fetchEntitlement()`
   opportunistico. Errore o timeout: **non cambia nulla**.

☠ **Trappola**: il punto 5 deve scrivere l'entitlement **prima** di chiamare il server.
Se l'ordine si inverte e la rete è assente, l'utente paga e non vede lo sblocco.

### F1.9 — Gating e paywall

**`lib/src/gate/feature_key.dart`**

```dart
enum FeatureKey {
  unlimitedEntities,        // calendari / freezer / fonti / rullini
  secondaryEntities,        // macchine fotografiche, scomparti extra
  photos,
  statistics,
  fullHistory,
  csvExport,
  pdfReport,
  backupRestore,
  advancedWidget,
  multipleNotifications,
  calendarSync,
  customCategories,
  themeCustomization,
}
```

⚑ **Perché una enum condivisa e non stringhe per app**: le quattro app vendono
sostanzialmente le stesse categorie di valore. Una enum comune permette di scrivere una sola
`PaywallPage` che elenca i benefici leggendo la mappa dei limiti, senza duplicare testi per
quattro volte.

**`lib/src/gate/feature_limits.dart`**

```dart
@immutable
class FeatureLimit {
  const FeatureLimit.locked();                       // solo Pro
  const FeatureLimit.count({required this.freeMax}); // n nel free, illimitato nel Pro
  const FeatureLimit.open();                         // sempre disponibile
  final int? freeMax;
  bool get isLockedForFree;
}

typedef FeatureLimits = Map<FeatureKey, FeatureLimit>;
```

**`lib/src/gate/feature_gate.dart`**

```dart
class FeatureGate {
  const FeatureGate({required this.limits, required this.isPro});
  final FeatureLimits limits;
  final bool isPro;

  bool allows(FeatureKey key);
  int? freeLimitOf(FeatureKey key);
  bool withinLimit(FeatureKey key, int currentCount);      // isPro || currentCount < freeMax
  int? remaining(FeatureKey key, int currentCount);
  GateVerdict check(FeatureKey key, {int currentCount = 0});
}

sealed class GateVerdict { const GateVerdict(); }
final class GateAllowed extends GateVerdict { const GateAllowed(); }
final class GateBlocked extends GateVerdict {
  const GateBlocked({required this.key, required this.reason, this.freeMax});
  final FeatureKey key;
  final BlockReason reason;   // proOnly | limitReached
  final int? freeMax;
}
enum BlockReason { proOnly, limitReached }
```

**`lib/src/gate/pro_lock.dart`**

```dart
class ProLock extends StatelessWidget {
  const ProLock({required this.feature, required this.child, this.currentCount = 0,
    this.mode = ProLockMode.overlay, this.onBlocked, super.key});
  final FeatureKey feature;
  final Widget child;
  final int currentCount;
  final ProLockMode mode;
  final void Function(GateBlocked)? onBlocked;
}
enum ProLockMode { overlay, hide, badgeOnly }

class ProBadge extends StatelessWidget {
  const ProBadge({this.compact = false, super.key});
}
```

**`lib/src/gate/paywall_page.dart`**

```dart
class PaywallPage extends StatefulWidget {
  const PaywallPage({required this.config, this.highlight, super.key});
  final PaywallConfig config;
  final FeatureKey? highlight;      // la funzione che ha innescato il paywall, evidenziata
  static Future<bool> show(BuildContext context, {required PaywallConfig config, FeatureKey? highlight});
}

@immutable
class PaywallConfig {
  const PaywallConfig({required this.appName, required this.productId, required this.headline,
    required this.subhead, required this.benefits, required this.heroBuilder, this.footnote});
  final String appName;
  final String productId;
  final String headline;
  final String subhead;
  final List<PaywallBenefit> benefits;
  final WidgetBuilder heroBuilder;
  final String? footnote;
}

@immutable
class PaywallBenefit {
  const PaywallBenefit({required this.key, required this.icon, required this.title, required this.description});
  final FeatureKey key;
  final IconData icon;
  final String title;
  final String description;
}
```

Comportamento obbligatorio della `PaywallPage`:

- Mostra il prezzo **reale** letto da Play (`MicroProduct.formattedPrice`), mai un prezzo
  hard-coded. Se il prezzo non è ancora arrivato, mostra uno skeleton, non "9,99 €".
- Dice esplicitamente **"pagamento unico, nessun abbonamento"**.
- Ha un pulsante **"Ripristina acquisto"** sempre visibile.
- Se `entitlement.isPending`, mostra "Pagamento in elaborazione" e disabilita l'acquisto.
- Si chiude da sola quando `isPro` diventa vero, restituendo `true`.
- Non si ripresenta automaticamente più di una volta per sessione (contatore in
  `SettingKeys.paywallShownCount`).

⚑ **Perché "pagamento unico" scritto a caratteri grandi**: è il principale motivo per cui una
persona compra questo tipo di app invece di un concorrente in abbonamento. Nasconderlo è
lasciare soldi sul tavolo.

### F1.10 — Notifiche

**`lib/src/notifications/notification_channel.dart`**

```dart
@immutable
class MicroNotificationChannel {
  const MicroNotificationChannel({required this.id, required this.name, required this.description,
    required this.importance, this.enableVibration = true, this.playSound = true});
  final String id, name, description;
  final MicroImportance importance;   // low | normal | high
}
```

**`lib/src/notifications/notification_ids.dart`**

```dart
abstract final class NotificationIds {
  static const int reservedMax = 999;
  static int forOccurrence(int entityId, CivilDate date, int slot);   // hash stabile, 1000..2^31-1
  static const int weeklyDigest = 10;
  static const int reorderWarning = 20;
  static const int reorderOverdue = 21;
}
```

⚑ **Perché gli ID derivati da un hash stabile e non da un contatore**: la ripianificazione
(ADR-009) cancella e ricrea le notifiche a ogni resume. Con un contatore, la stessa raccolta
riceve ogni volta un ID diverso e i duplicati si accumulano. Con un hash di
(entità, data, slot), la stessa raccolta ha sempre lo stesso ID e `zonedSchedule` la
sovrascrive.

**`lib/src/notifications/notification_service.dart`**

```dart
class NotificationService {
  static Future<NotificationService> create({
    required String appId,
    required String androidIconResource,        // es. '@drawable/ic_notification'
    required List<MicroNotificationChannel> channels,
  });

  Future<PermissionOutcome> ensurePermission();
  Future<bool> canScheduleExactAlarms();
  Future<void> openExactAlarmSettings();

  Future<void> scheduleAt({
    required int id, required DateTime localWhen, required String title, required String body,
    required String channelId, String? payload, bool exact = false});
  Future<void> cancel(int id);
  Future<void> cancelAll();
  Future<void> cancelInRange({required int minId, required int maxId});
  Future<List<PendingNotificationRequest>> pending();

  Stream<String> get taps;                      // payload dei tap
  Future<String?> consumeLaunchPayload();       // app aperta da notifica a freddo

  Future<void> replaceSchedule({required Iterable<ScheduledNotification> notifications, required int minId, required int maxId});
}

enum PermissionOutcome { granted, denied, permanentlyDenied, notRequired }

@immutable
class ScheduledNotification {
  const ScheduledNotification({required this.id, required this.localWhen, required this.title,
    required this.body, required this.channelId, this.payload, this.exact = false});
}
```

⚑ **Perché `replaceSchedule` come operazione unica**: la ripianificazione deve essere
atomica dal punto di vista logico ("questo è l'insieme completo delle notifiche di questa
app"). Cancellare tutto e ripianificare in due chiamate separate lascia una finestra in cui
l'app non ha notifiche, e se il processo muore in mezzo l'utente non riceve più nulla.
`replaceSchedule` fa il diff tra le pendenti e le richieste, cancellando solo le eccedenti.

☠ **Trappola timezone**: `flutter_local_notifications` richiede `tz.initializeTimeZones()` e
`tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()))`. Senza, tutte
le notifiche vengono pianificate in UTC e arrivano con due ore di anticipo in estate. Questo
va fatto una volta in `NotificationService.create()`, e va **testato** con un fuso diverso
da UTC nel test.

### F1.11 — Dati fuori dall'app: backup, export, immagini

**`lib/src/backup/backup_source.dart`**

```dart
abstract interface class BackupSource {
  String get schemaId;                  // 'trashcan', 'full_freezer', ...
  int get schemaVersion;
  Future<Map<String, Object?>> exportPayload();
  Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode});
  Future<bool> canImport(int payloadSchemaVersion);
}

enum ImportMode { replaceAll, mergeKeepExisting }
```

**`lib/src/backup/json_backup_codec.dart`**

```dart
@immutable
class BackupManifest {
  const BackupManifest({required this.schemaId, required this.schemaVersion, required this.appVersion,
    required this.createdAt, required this.itemCounts, this.label});
  final String schemaId; final int schemaVersion; final String appVersion;
  final DateTime createdAt; final Map<String, int> itemCounts; final String? label;
}

class JsonBackupCodec {
  static const String magic = 'MICROAPPS_BACKUP';
  static const int formatVersion = 1;
  static String encode({required BackupManifest manifest, required Map<String, Object?> payload});
  static Result<({BackupManifest manifest, Map<String, Object?> payload})> decode(String contents);
  static Result<BackupManifest> peekManifest(String contents);
}
```

Formato del file (`.microbackup.json`, testo UTF-8, indentato):

```json
{
  "magic": "MICROAPPS_BACKUP",
  "formatVersion": 1,
  "manifest": { "schemaId": "trashcan", "schemaVersion": 3, "appVersion": "1.2.0",
                "createdAt": "2026-09-09T18:22:31.000Z", "label": "prima di reinstallare",
                "itemCounts": { "calendars": 2, "wasteTypes": 7, "rules": 9, "exceptions": 3 } },
  "payload": { }
}
```

⚑ **Perché JSON leggibile e non un formato binario compresso**: l'utente deve poter aprire
il file e vedere che sono i suoi dati, e in caso di problema si può ripararlo a mano. Le
dimensioni sono trascurabili (qualche decina di KB) tranne per le foto, che **non** finiscono
nel JSON: vedi sotto.

**`lib/src/backup/backup_service.dart`**

```dart
class BackupService {
  BackupService({required this.paths, required this.appVersion});
  Future<Result<File>> createBackup(BackupSource source, {String? label, bool includeImages = false});
  Future<Result<BackupManifest>> inspect(File file);
  Future<Result<void>> restore(File file, BackupSource source, {required ImportMode mode});
  Future<Result<File>> pickBackupFile();
  Future<void> shareBackup(File file);
  Future<void> cleanupExports({Duration olderThan = const Duration(days: 7)});
}
```

⚑ **Perché `includeImages` produce uno ZIP e non un JSON con base64**: le contact sheet di
Film Tracker sono immagini da centinaia di KB. Codificarle in base64 dentro il JSON gonfia il
file del 33% e rende impossibile aprirlo con un editor. Con `includeImages: true` il servizio
produce `backup.zip` contenente `data.json` + `images/`. Il decoder accetta entrambi i
formati.

**`lib/src/export/csv_writer.dart`**

```dart
class CsvWriter {
  CsvWriter({String separator = ';', String lineEnding = '\r\n', bool withBom = true});
  void addHeader(List<String> columns);
  void addRow(List<Object?> values);
  String build();
  Future<File> writeTo(File target);
}
```

☠ **Trappola disinnescata**: separatore `;` e BOM UTF-8. Excel in locale italiano apre i CSV
con separatore `,` come una sola colonna, e senza BOM mangia gli accenti. Il pubblico di
queste app apre i CSV con Excel, non con `pandas`.

**`lib/src/export/pdf_report_builder.dart`**

```dart
class PdfReportBuilder {
  PdfReportBuilder({required this.title, required this.appName, this.accentColor});
  void addCoverPage({required String subtitle, Map<String, String> summary = const {}});
  void addSection(String title);
  void addKeyValues(Map<String, String> values);
  void addTable({required List<String> headers, required List<List<String>> rows});
  void addImageGrid(List<File> images, {int columns = 4});
  void addNote(String text);
  Future<File> build(File target);
  Future<void> printOrShare();
}
```

**`lib/src/storage/image_store.dart`**

```dart
class ImageStore {
  ImageStore({required this.paths});
  Future<Result<StoredImage>> importFile(File source, {required String bucket,
    int maxLongSide = 1600, int thumbLongSide = 400, int quality = 82});
  Future<Result<StoredImage>> importBytes(Uint8List bytes, {required String bucket, ...});
  Future<void> delete(StoredImage image);
  Future<void> deleteBucket(String bucket);
  File resolve(String relativePath);
  Future<int> totalBytes();
  Future<int> pruneOrphans(Set<String> referencedPaths);
}

@immutable
class StoredImage {
  const StoredImage({required this.path, required this.thumbPath, required this.width,
    required this.height, required this.bytes, required this.createdAt});
  final String path;        // relativo a AppPaths.images, es. 'rolls/17/ab12.jpg'
  final String thumbPath;
  final int width, height, bytes;
  final DateTime createdAt;
  Map<String, Object?> toJson();
  factory StoredImage.fromJson(Map<String, Object?> json);
}
```

⚑ **Perché si salva sempre un percorso relativo**: su Android il percorso assoluto della
sandbox dell'app **cambia** tra un aggiornamento e l'altro e dopo un ripristino del
dispositivo. Salvare il percorso assoluto nel database significa che dopo il primo
aggiornamento tutte le foto degli utenti risultano mancanti. Il percorso relativo si risolve
sempre a runtime con `ImageStore.resolve`.

⚑ **Perché il ridimensionamento a 1600 px**: la spec di Film Tracker lo indica; è il
compromesso tra qualità sufficiente per riconoscere un provino e occupazione di spazio. Il
`pruneOrphans` esiste perché cancellare un rullino deve cancellare anche i suoi file, e
l'esperienza dice che prima o poi qualcosa resta orfano.

### F1.12 — Test di `micro_core`

Test obbligatori, con quello che ciascuno dimostra:

| File | Dimostra |
|---|---|
| `test/util/civil_date_test.dart` | Ora legale, fine mese, anno bisestile, ordinamento, `epochDay` |
| `test/util/money_test.dart` | Somme senza errore di virgola mobile, formattazione italiana |
| `test/util/result_test.dart` | `fold` esaustivo |
| `test/storage/atomic_file_test.dart` | Una scrittura interrotta non lascia un file troncato |
| `test/entitlement/supersedes_test.dart` | Tutte le combinazioni di `supersedes` (matrice 4×4 stati × sorgenti) |
| `test/entitlement/offline_never_downgrades_test.dart` | **ADR-007**: con `api` che va in timeout o errore, un Pro resta Pro |
| `test/entitlement/bootstrap_order_test.dart` | Con rete assente, l'acquisto sblocca comunque il Pro in locale |
| `test/entitlement/duplicate_purchase_test.dart` | Lo stesso `purchaseToken` due volte produce una sola verifica |
| `test/billing/fake_gateway_test.dart` | I cinque `FakeOutcome` producono gli eventi attesi |
| `test/gate/feature_gate_test.dart` | `withinLimit` ai bordi (0, freeMax−1, freeMax, freeMax+1), Pro sempre permesso |
| `test/backup/json_backup_codec_test.dart` | Round-trip, rifiuto di magic errato, rifiuto di schemaVersion futura |
| `test/backup/backup_service_test.dart` | `replaceAll` vs `mergeKeepExisting` |
| `test/export/csv_writer_test.dart` | Escaping di `;`, virgolette, a capo; presenza del BOM |
| `test/notifications/reschedule_test.dart` | `replaceSchedule` non cancella ciò che deve restare, cancella l'eccedenza |
| `test/notifications/timezone_test.dart` | Pianificazione corretta con `Europe/Rome` in ora legale |
| `test/ui/gallery_golden_test.dart` | La galleria dei componenti in light e dark |

✔ DoD F1.12: `flutter test packages/micro_core` verde; nessun test `skip`.

### F1.13 — `packages/micro_core/codebase_reference.md`

Scritto secondo i criteri di §6.2. Deve contenere l'indice "dove sta cosa", l'albero
annotato, ogni classe con ogni metodo e firma completa, il catalogo dei test con cosa
dimostrano, le regole non negoziabili (ADR-007, percorsi relativi, acknowledge entro 3
giorni, BOM nei CSV), e la lista di cosa **non** esiste (nessun supporto iOS testato, nessun
abbonamento, nessuna sincronizzazione dati).

### F1.14 — Rituale di fine fase F1

Eseguire §6. Branch previsto: `v2.0.0`.

---

## F2 — MicroApps License Server

**Obiettivo della fase**: un servizio HTTP piccolo, leggibile e autosufficiente che verifica
gli acquisti presso Google, tiene il registro di chi ha comprato cosa, e offre un pannello
admin per guardarlo. Gira in un container Docker su `clawserver` senza toccare OpenClaw.

**Regola non negoziabile**: il server **non** può concedere il Pro a nessuno senza un token
Play verificato presso Google, tranne per una concessione manuale di un admin, che finisce
nell'audit log con il nome dell'admin e la motivazione.

**Regola non negoziabile numero due**: questa fase si sviluppa in una **repo separata**
(ADR-001), su disco in `server/`, con un proprio `.git` e **un solo remote**, `origin`, su
Gitea. Il primo passo di F2.1 è `git init` in `server/` e il push-to-create verso
`https://git.home.varitest.ovh/smp-webmaster/microapps-server.git`. Nessun remote GitHub,
mai.

### F2.1 — Bootstrap Node/TypeScript/Fastify

▶ File:

**`server/package.json`** — script: `dev` (`tsx watch src/index.ts`), `build` (`tsc`),
`start` (`node dist/index.js`), `test` (`node --test`), `migrate`, `seed`, `create-admin`.

Dipendenze: `fastify@^5`, `@fastify/cookie`, `@fastify/rate-limit`, `@fastify/static`,
`@fastify/formbody`, `better-sqlite3`, `zod`, `pino`, `pino-pretty` (solo dev), `argon2`,
`googleapis`, `nanoid`. Dev: `typescript`, `tsx`, `@types/node`, `@types/better-sqlite3`,
`prettier`.

**`server/tsconfig.json`** — `strict: true`, `noUncheckedIndexedAccess: true`,
`target: ES2023`, `module: NodeNext`, `outDir: dist`.

**`server/src/config.ts`**

```ts
export interface Config {
  readonly nodeEnv: 'development' | 'production' | 'test';
  readonly port: number;
  readonly host: string;
  readonly dbPath: string;
  readonly logLevel: string;
  readonly publicBaseUrl: string;
  readonly appSecrets: Readonly<Record<string, string>>;   // appId -> HMAC secret
  readonly hmacToleranceSeconds: number;
  readonly googleServiceAccountJson: string | null;        // percorso del file
  readonly rtdnSharedSecret: string | null;
  readonly adminSessionTtlHours: number;
  readonly backupDir: string;
  readonly backupKeepDays: number;
}
export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config;
export class ConfigError extends Error {}
```

Chiavi di configurazione (tutte da variabile d'ambiente, documentate in `.env.example`):

| Variabile | Default | Significato |
|---|---|---|
| `NODE_ENV` | `development` | Modalità |
| `PORT` | `8087` | Porta HTTP interna al container |
| `HOST` | `0.0.0.0` | Bind |
| `DB_PATH` | `./data/licenses.db` | File SQLite |
| `LOG_LEVEL` | `info` | Livello Pino |
| `PUBLIC_BASE_URL` | `http://localhost:8087` | Usato nei link del pannello admin |
| `APP_SECRETS` | — (obbligatoria) | `trashcan:xxx,fullfreezer:yyy,scortecalore:zzz,filmtracker:www` |
| `HMAC_TOLERANCE_SECONDS` | `300` | Finestra di validità del timestamp |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | `null` | Percorso al JSON del service account; se assente la verifica Play è disabilitata e il server risponde `verification_unavailable` |
| `RTDN_SHARED_SECRET` | `null` | Segreto nel query string dell'endpoint Pub/Sub |
| `ADMIN_SESSION_TTL_HOURS` | `12` | Durata della sessione admin |
| `BACKUP_DIR` | `./data/backups` | Backup del DB |
| `BACKUP_KEEP_DAYS` | `30` | Rotazione |

⚑ **Perché la porta 8087**: `clawserver` ospita OpenClaw, di cui non conosciamo ancora le
porte occupate (F8.2). 8087 è un valore di partenza da confermare in ricognizione; il
container espone comunque solo su `127.0.0.1`, e il traffico pubblico passa dal reverse
proxy.

☠ **Trappola**: `loadConfig` deve **fallire all'avvio** se `APP_SECRETS` manca o se un
segreto è più corto di 32 caratteri. Un server che parte con una configurazione incompleta e
fallisce alla prima richiesta è peggio di un server che non parte.

**`server/src/app.ts`**

```ts
export interface BuildAppOptions { config: Config; db: Database; logger?: pino.Logger; }
export function buildApp(opts: BuildAppOptions): FastifyInstance;
```

⚑ **Perché `buildApp` separato da `index.ts`**: i test usano `fastify.inject()` su una
istanza costruita con un DB in memoria. Se l'app si costruisce solo dentro `index.ts`, ogni
test deve avviare un vero server su una porta.

### F2.2 — Schema del database

**`server/src/db/schema.sql`** — eseguito da `server/src/db/migrate.ts`, con tabella
`schema_migrations(version INTEGER PRIMARY KEY, applied_at INTEGER NOT NULL)`.

**`apps`** — le quattro app conosciute.

| Colonna | Tipo | Vincoli | Note |
|---|---|---|---|
| `id` | TEXT | PK | `trashcan`, `fullfreezer`, `scortecalore`, `filmtracker` |
| `package_name` | TEXT | NOT NULL UNIQUE | `com.smp.trashcan` |
| `display_name` | TEXT | NOT NULL | "TrashCan" |
| `created_at` | INTEGER | NOT NULL | ms UTC |

**`products`** — gli SKU vendibili.

| Colonna | Tipo | Vincoli |
|---|---|---|
| `sku` | TEXT | PK |
| `app_id` | TEXT | NOT NULL REFERENCES apps(id) |
| `kind` | TEXT | NOT NULL CHECK(kind IN ('inapp')) |
| `price_cents` | INTEGER | NOT NULL |
| `currency` | TEXT | NOT NULL DEFAULT 'EUR' |
| `active` | INTEGER | NOT NULL DEFAULT 1 |

**`installs`** — un dispositivo, senza dato personale (ADR-013).

| Colonna | Tipo | Vincoli | Note |
|---|---|---|---|
| `install_id` | TEXT | PK | UUIDv4 generato dall'app |
| `app_id` | TEXT | NOT NULL REFERENCES apps(id) | |
| `platform` | TEXT | NOT NULL DEFAULT 'android' | |
| `app_version` | TEXT | NULL | ultimo visto |
| `first_seen_at` | INTEGER | NOT NULL | |
| `last_seen_at` | INTEGER | NOT NULL | |

Indice: `idx_installs_app ON installs(app_id, last_seen_at DESC)`.

☠ **Trappola**: `install_id` è generato dal client e non è fidato. La PK è
`(install_id)` ma la logica non deve mai assumere unicità globale reale: due dispositivi
malevoli possono dichiarare lo stesso ID. L'entitlement è legato al **purchase_token**, che
è unico e verificato da Google; l'install è solo un'etichetta di comodo.

**`purchases`** — un acquisto Play verificato.

| Colonna | Tipo | Vincoli | Note |
|---|---|---|---|
| `id` | TEXT | PK | nanoid |
| `app_id` | TEXT | NOT NULL REFERENCES apps(id) | |
| `sku` | TEXT | NOT NULL REFERENCES products(sku) | |
| `purchase_token` | TEXT | NOT NULL UNIQUE | chiave reale dell'acquisto |
| `order_id` | TEXT | NULL | `GPA.xxxx-xxxx-xxxx-xxxxx` |
| `install_id` | TEXT | NULL REFERENCES installs(install_id) | primo dispositivo che l'ha presentato |
| `state` | TEXT | NOT NULL CHECK(state IN ('pending','purchased','canceled','refunded')) | |
| `acknowledged` | INTEGER | NOT NULL DEFAULT 0 | come riportato da Google |
| `purchase_time` | INTEGER | NULL | ms UTC, da Google |
| `verified_at` | INTEGER | NOT NULL | ultima verifica presso Google |
| `raw_json` | TEXT | NULL | risposta grezza di Android Publisher, per il debug |
| `created_at` | INTEGER | NOT NULL | |
| `updated_at` | INTEGER | NOT NULL | |

Indici: `idx_purchases_app_state`, `idx_purchases_install`.

⚑ **Perché si conserva `raw_json`**: quando fra sei mesi un acquisto risulterà in uno stato
inatteso, l'unica cosa che permette di capire cosa ha detto Google in quel momento è averlo
scritto. Occupa poche centinaia di byte per riga.

**`entitlements`** — chi ha diritto a cosa. È la tabella che risponde alla domanda del
committente ("chi ha pagato cosa").

| Colonna | Tipo | Vincoli |
|---|---|---|
| `id` | TEXT | PK (nanoid) |
| `app_id` | TEXT | NOT NULL REFERENCES apps(id) |
| `install_id` | TEXT | NOT NULL |
| `sku` | TEXT | NOT NULL |
| `status` | TEXT | NOT NULL CHECK(status IN ('pro','pending','revoked')) |
| `purchase_id` | TEXT | NULL REFERENCES purchases(id) |
| `source` | TEXT | NOT NULL CHECK(source IN ('play','manual','restore')) |
| `granted_at` | INTEGER | NOT NULL |
| `revoked_at` | INTEGER | NULL |
| `note` | TEXT | NULL (motivazione, per le concessioni manuali) |

Vincolo: `UNIQUE(app_id, install_id, sku)`.
Indici: `idx_ent_purchase ON entitlements(purchase_id)`, `idx_ent_app_status`.

**`restore_codes`**

| Colonna | Tipo | Vincoli |
|---|---|---|
| `code` | TEXT | PK (8 caratteri, alfabeto `ABCDEFGHJKMNPQRSTUVWXYZ23456789`) |
| `app_id` | TEXT | NOT NULL |
| `entitlement_id` | TEXT | NOT NULL REFERENCES entitlements(id) |
| `created_at` | INTEGER | NOT NULL |
| `expires_at` | INTEGER | NOT NULL |
| `claimed_at` | INTEGER | NULL |
| `claimed_by_install` | TEXT | NULL |
| `attempts` | INTEGER | NOT NULL DEFAULT 0 |

⚑ **Perché l'alfabeto senza `I`, `L`, `O`, `0`, `1`**: il codice viene letto ad alta voce o
copiato a mano da uno schermo a un altro. Le ambiguità tra `0`/`O` e `1`/`I`/`l` generano
tentativi falliti e ticket di supporto.

☠ **Trappola**: un codice di ripristino è un bypass della verifica Play. Va limitato: scade
dopo **7 giorni**, è **usa e getta**, e ogni entitlement può generarne al massimo **3**
nell'arco di 30 giorni. Senza questi limiti, il codice diventa il modo per condividere il Pro
su un forum.

**`rtdn_events`** — notifiche Google in tempo reale, conservate grezze.

| Colonna | Tipo | Vincoli |
|---|---|---|
| `id` | TEXT | PK |
| `received_at` | INTEGER | NOT NULL |
| `message_id` | TEXT | UNIQUE (deduplica Pub/Sub) |
| `package_name` | TEXT | NULL |
| `notification_type` | TEXT | NULL |
| `purchase_token` | TEXT | NULL |
| `raw_json` | TEXT | NOT NULL |
| `processed_at` | INTEGER | NULL |
| `error` | TEXT | NULL |

⚑ **Perché `message_id UNIQUE`**: Pub/Sub garantisce la consegna **almeno una volta**, non
esattamente una volta. Senza deduplica, un rimborso notificato tre volte produce tre righe di
audit e potenzialmente tre revoche.

**`admin_users`**

| Colonna | Tipo | Vincoli |
|---|---|---|
| `id` | TEXT | PK |
| `email` | TEXT | NOT NULL UNIQUE |
| `password_hash` | TEXT | NOT NULL (argon2id) |
| `created_at` | INTEGER | NOT NULL |
| `last_login_at` | INTEGER | NULL |
| `disabled` | INTEGER | NOT NULL DEFAULT 0 |

**`admin_sessions`**

| Colonna | Tipo | Vincoli |
|---|---|---|
| `id` | TEXT | PK (token opaco a 32 byte, base64url) |
| `admin_user_id` | TEXT | NOT NULL REFERENCES admin_users(id) |
| `created_at` | INTEGER | NOT NULL |
| `expires_at` | INTEGER | NOT NULL |
| `ip` | TEXT | NULL |
| `user_agent` | TEXT | NULL |

**`audit_log`**

| Colonna | Tipo | Vincoli |
|---|---|---|
| `id` | INTEGER | PK AUTOINCREMENT |
| `at` | INTEGER | NOT NULL |
| `actor` | TEXT | NOT NULL (`admin:<email>`, `system`, `device:<install_id>`) |
| `action` | TEXT | NOT NULL (`entitlement.grant`, `entitlement.revoke`, `restore.claim`, `admin.login`, …) |
| `subject` | TEXT | NULL |
| `detail_json` | TEXT | NULL |

**`hmac_nonces`** — anti-replay.

| Colonna | Tipo | Vincoli |
|---|---|---|
| `signature` | TEXT | PK |
| `seen_at` | INTEGER | NOT NULL |

Pulita periodicamente per `seen_at < now - HMAC_TOLERANCE_SECONDS*2`.

**`server/src/db/db.ts`**

```ts
export type Database = import('better-sqlite3').Database;
export function openDatabase(path: string): Database;      // WAL, foreign_keys ON, busy_timeout 5000
export function closeDatabase(db: Database): void;
export function withTransaction<T>(db: Database, fn: () => T): T;
```

☠ **Trappola**: `PRAGMA foreign_keys = ON` non è il default in SQLite e va impostato **su
ogni connessione**. Senza, i `REFERENCES` sopra sono decorativi.

✔ DoD F2.2: `npm run migrate` crea il DB da zero; rieseguirlo è idempotente; `npm run seed`
inserisce le quattro app e i quattro prodotti.

### F2.3 — Plugin `auth` e `rateLimit`

**`server/src/plugins/auth.ts`**

```ts
export interface DeviceIdentity { appId: string; installId: string; appVersion: string | null; }

declare module 'fastify' {
  interface FastifyRequest { device?: DeviceIdentity; admin?: AdminIdentity; }
}

export const deviceAuthPlugin: FastifyPluginAsync<{ config: Config; db: Database }>;
export function verifyHmac(args: {
  secret: string; method: string; path: string; timestamp: string;
  bodyRaw: string; signature: string; toleranceSeconds: number;
}): { ok: true } | { ok: false; reason: 'stale' | 'bad_signature' | 'malformed' };

export const adminAuthPlugin: FastifyPluginAsync<{ config: Config; db: Database }>;
export interface AdminIdentity { id: string; email: string; }
```

In testa al file, commento obbligatorio (ADR-014): questo HMAC **non** protegge
l'entitlement, protegge l'endpoint da traffico casuale e replay. Il segreto è compilato
nell'APK e chi decompila lo trova. La sicurezza reale è la verifica presso Google.

**`server/src/plugins/rate_limit.ts`** — limiti per rotta:

| Rotta | Limite | Chiave |
|---|---|---|
| `POST /v1/purchases/verify` | 20 / ora | `install_id` |
| `GET /v1/entitlements/:installId` | 60 / ora | `install_id` |
| `POST /v1/restore/code` | 3 / giorno | `install_id` |
| `POST /v1/restore/claim` | 10 / ora, poi blocco 24 h | IP + `install_id` |
| `POST /admin/login` | 10 / 15 min | IP |

### F2.4 — `PlayVerifier`

**`server/src/services/play_verifier.ts`**

```ts
export type PlayPurchaseState = 'purchased' | 'canceled' | 'pending';

export interface PlayProductPurchase {
  purchaseState: PlayPurchaseState;
  acknowledgementState: 'acknowledged' | 'pending';
  purchaseTimeMillis: number | null;
  orderId: string | null;
  productId: string;
  obfuscatedExternalAccountId: string | null;
  raw: unknown;
}

export interface PlayVerifier {
  isConfigured(): boolean;
  getProductPurchase(args: { packageName: string; productId: string; token: string }):
    Promise<Result<PlayProductPurchase, PlayVerifierError>>;
  acknowledge(args: { packageName: string; productId: string; token: string }):
    Promise<Result<void, PlayVerifierError>>;
}

export type PlayVerifierError =
  | { kind: 'not_configured' }
  | { kind: 'not_found' }              // HTTP 404: token inesistente o non appartenente all'app
  | { kind: 'invalid_token' }          // HTTP 400
  | { kind: 'permission_denied' }      // HTTP 401/403: service account non collegato
  | { kind: 'rate_limited' }           // HTTP 429
  | { kind: 'upstream' ; status: number; message: string };

export function createPlayVerifier(config: Config): PlayVerifier;
export function createNullPlayVerifier(): PlayVerifier;    // usato nei test e quando non configurato
```

⚑ **Perché la distinzione tra `not_found` e `upstream`**: `not_found` significa "questo
token non è un acquisto valido" ed è una risposta **definitiva**: il server deve rispondere
`not_entitled` e non riprovare. `upstream` e `rate_limited` sono transitori: il server
risponde `503` e il client riproverà. Confondere i due casi produce o utenti bloccati o
tempeste di retry.

☠ **Trappola**: il service account deve essere invitato in Play Console **e** avere il
permesso "Visualizza dati finanziari" sull'app. Senza, l'API risponde 401 con un messaggio
generico, e si perde mezza giornata a cercare l'errore nel codice. F8.6 copre la procedura.

### F2.5 — Entitlement e rotte principali

**`server/src/services/entitlement_service.ts`**

```ts
export interface EntitlementRecord {
  id: string; appId: string; installId: string; sku: string;
  status: 'pro' | 'pending' | 'revoked';
  source: 'play' | 'manual' | 'restore';
  purchaseId: string | null; grantedAt: number; revokedAt: number | null; note: string | null;
}

export interface EntitlementService {
  verifyAndGrant(args: {
    appId: string; installId: string; sku: string; purchaseToken: string;
    orderId: string | null; appVersion: string | null;
  }): Promise<Result<EntitlementRecord, VerifyError>>;

  getForInstall(args: { appId: string; installId: string }): EntitlementRecord | null;
  revokeByPurchaseToken(args: { purchaseToken: string; reason: string; actor: string }): number;
  grantManually(args: { appId: string; installId: string; sku: string; note: string; actor: string }): EntitlementRecord;
  listForAdmin(args: { appId?: string; status?: string; query?: string; limit: number; offset: number }):
    { rows: AdminEntitlementRow[]; total: number };
  statsForAdmin(): AdminStats;
}

export type VerifyError =
  | { kind: 'unknown_app' } | { kind: 'unknown_sku' }
  | { kind: 'not_entitled'; detail: string }
  | { kind: 'verification_unavailable' }
  | { kind: 'upstream'; status: number };
```

Sequenza di `verifyAndGrant`, da rispettare:

1. Risolvi `app` da `appId`; verifica che `sku` appartenga a quell'app. Altrimenti
   `unknown_app` / `unknown_sku`.
2. Upsert dell'`install` (aggiorna `last_seen_at`, `app_version`).
3. `playVerifier.getProductPurchase(...)`.
   - `not_configured` → `verification_unavailable` (HTTP 503). **Nessuna concessione.**
   - `not_found` / `invalid_token` → `not_entitled` (HTTP 200 con `status: "free"`).
   - `upstream` / `rate_limited` → `upstream` (HTTP 503).
4. Upsert in `purchases` su `purchase_token`, salvando `state`, `order_id`, `purchase_time`,
   `raw_json`, `verified_at`.
5. Se `purchaseState == 'purchased'`: upsert dell'entitlement a `pro`, `source: 'play'`.
   Se `pending`: entitlement a `pending`. Se `canceled`: `revoked` con `revoked_at`.
6. Se `acknowledgementState == 'pending'`, chiama `playVerifier.acknowledge` come rete di
   sicurezza (il client dovrebbe averlo già fatto).
7. Scrivi in `audit_log`.

⚑ **Perché il server riconosce l'acquisto come rete di sicurezza**: la trappola dei 3 giorni
(F1.7) è la causa numero uno di rimborsi automatici inspiegabili. Se il client crasha tra il
pagamento e l'acknowledge, il server lo salva.

☠ **Trappola**: il punto 3 non deve **mai** cadere in un ramo che concede il Pro senza
risposta positiva di Google. La sola eccezione è `grantManually`, che passa da un admin
autenticato e finisce nell'audit log.

**Rotte** (`server/src/routes/purchases.ts`, `server/src/routes/entitlements.ts`):

| Metodo e path | Auth | Body / Param | Risposta 200 | Errori |
|---|---|---|---|---|
| `POST /v1/purchases/verify` | HMAC device | `{ sku, purchaseToken, orderId?, appVersion? }` | `{ status: 'pro'\|'pending'\|'free', sku?, purchasedAt?, serverTime }` | `400 bad_request`, `401 bad_signature`, `404 unknown_app`, `429 rate_limited`, `503 verification_unavailable` |
| `GET /v1/entitlements/:installId` | HMAC device | — | `{ status, sku?, purchasedAt?, revokedAt?, serverTime }` | `401`, `403 install_mismatch`, `429` |
| `GET /healthz` | nessuna | — | `{ ok: true, version, dbOk, playConfigured, uptimeSeconds }` | — |

Formato d'errore uniforme:

```json
{ "error": { "code": "bad_signature", "message": "Firma non valida o timestamp fuori finestra." } }
```

⚑ **Perché `not_entitled` è un 200 e non un 404**: "questo utente non ha comprato" non è un
errore della richiesta, è la risposta. Un 404 spingerebbe il client a fare retry e a
mostrare un errore all'utente, quando invece la risposta corretta è "sei nella versione
gratuita".

### F2.6 — Codici di ripristino

**`server/src/services/restore_code_service.ts`**

```ts
export interface RestoreCodeService {
  create(args: { appId: string; installId: string }): Result<{ code: string; expiresAt: number }, RestoreError>;
  claim(args: { appId: string; installId: string; code: string }): Result<EntitlementRecord, RestoreError>;
}
export type RestoreError =
  | { kind: 'no_entitlement' } | { kind: 'too_many_codes' }
  | { kind: 'not_found' } | { kind: 'expired' } | { kind: 'already_claimed' };
export function generateRestoreCode(): string;   // 8 char, alfabeto non ambiguo
```

| Metodo e path | Auth | Body | 200 | Errori |
|---|---|---|---|---|
| `POST /v1/restore/code` | HMAC device | — | `{ code, expiresAt }` | `403 no_entitlement`, `429 too_many_codes` |
| `POST /v1/restore/claim` | HMAC device | `{ code }` | `{ status, sku, purchasedAt, serverTime }` | `404 not_found`, `410 expired`, `409 already_claimed`, `429` |

Regole: scadenza 7 giorni, uso singolo, massimo 3 codici attivi per entitlement in 30 giorni.
Il claim **sposta** l'entitlement sul nuovo `install_id` e lascia quello vecchio attivo
(l'utente può avere due dispositivi in famiglia); l'audit log registra entrambi.

⚑ **Perché non revocare il dispositivo di origine**: il caso reale è "l'ho installato anche
sul tablet", non "ho venduto il telefono". Revocare produrrebbe supporto e frustrazione, e il
guadagno anti-abuso è nullo visto il tetto di 3 codici.

### F2.7 — Real-time Developer Notifications

**`server/src/routes/rtdn.ts`**

`POST /v1/rtdn?secret=<RTDN_SHARED_SECRET>` — endpoint push di Google Cloud Pub/Sub.

Corpo: `{ message: { data: <base64>, messageId, publishTime }, subscription }`.
`data` decodificato è un `DeveloperNotification` con `oneTimeProductNotification`
(`{ version, notificationType, purchaseToken, sku }`) o `voidedPurchaseNotification`.

Comportamento:

1. Verifica `secret` (confronto a tempo costante). Se errato: `401`, e **niente log del
   corpo**.
2. Inserisci in `rtdn_events`; se `message_id` esiste già, rispondi `200` e termina.
3. Se `voidedPurchaseNotification` o `notificationType == 2` (canceled): chiama
   `entitlementService.revokeByPurchaseToken(...)`.
4. Se `notificationType == 1` (purchased): rilancia `verifyAndGrant` se conosci
   l'`install_id` collegato al token; altrimenti aggiorna solo `purchases`.
5. Rispondi **sempre `200`** se il messaggio è stato registrato, anche se l'elaborazione è
   fallita: l'errore si scrive in `rtdn_events.error` e si rielabora dal pannello admin.

⚑ **Perché rispondere 200 anche in caso di errore applicativo**: Pub/Sub ritenta con backoff
esponenziale per giorni. Un errore applicativo persistente (per esempio uno SKU non ancora in
tabella) genererebbe un ciclo infinito di consegne. Registrare e rispondere 200 lascia il
controllo a noi.

### F2.8 — Pannello admin

Rendering server-side, HTML semplice, nessun framework JS. `@fastify/static` per un unico
`admin.css`.

| Metodo e path | Auth | Descrizione |
|---|---|---|
| `GET /admin/login` | — | Form email + password |
| `POST /admin/login` | rate-limited | Crea sessione, cookie `ma_admin` `HttpOnly` `Secure` `SameSite=Lax` |
| `POST /admin/logout` | sessione | Invalida la sessione |
| `GET /admin` | sessione | Dashboard: per ogni app, installazioni totali, Pro attivi, pending, revocati, ricavo lordo stimato, ultimi 10 acquisti |
| `GET /admin/entitlements` | sessione | Tabella filtrabile per app, stato, ricerca su `install_id` / `order_id` / `purchase_token`; paginazione |
| `GET /admin/entitlements/:id` | sessione | Dettaglio, con il `raw_json` dell'acquisto |
| `POST /admin/entitlements/:id/revoke` | sessione | Revoca manuale, motivazione obbligatoria |
| `POST /admin/entitlements/grant` | sessione | Concessione manuale (`app_id`, `install_id`, `sku`, motivazione) |
| `GET /admin/purchases` | sessione | Elenco acquisti con stato Play |
| `GET /admin/rtdn` | sessione | Eventi Pub/Sub, con pulsante "rielabora" |
| `GET /admin/audit` | sessione | Audit log, filtrabile |
| `GET /admin/export.csv` | sessione | Esporta gli entitlement filtrati |

⚑ **Perché HTML server-side e non una SPA**: il pannello lo usa una persona, qualche volta
alla settimana. Una SPA aggiungerebbe un build step, un bundle e una superficie di
manutenzione per un guadagno di comodità nullo. Cinque template e un foglio di stile bastano.

☠ **Trappola**: la dashboard mostra un "ricavo lordo stimato" calcolato da `price_cents` per
il numero di acquisti. **Non è** il ricavo reale: Google trattiene la commissione, e ci sono
rimborsi e tasse. L'etichetta nella pagina deve dirlo esplicitamente, altrimenti quel numero
verrà usato per decisioni sbagliate.

**`server/src/scripts/create_admin.ts`** — `npm run create-admin -- --email x@y.z` chiede la
password da stdin, la valida (≥ 12 caratteri), la hasha con argon2id e crea l'utente.

### F2.9 — Backup del database

**`server/src/services/backup_service.ts`**

```ts
export interface DbBackupService {
  runBackup(): Promise<{ file: string; bytes: number }>;
  pruneOld(): Promise<number>;
  schedule(): void;      // ogni giorno alle 03:30 ora del server
}
```

Usa l'API `Database.backup()` di better-sqlite3 (sicura con WAL attivo), scrive
`licenses-YYYYMMDD-HHmm.db` in `BACKUP_DIR`, cancella i file più vecchi di
`BACKUP_KEEP_DAYS`.

☠ **Trappola**: **non** copiare il file `.db` con `cp` mentre il server gira. Con WAL attivo
la copia può essere incoerente perché il contenuto vive anche nel `-wal`. L'API `backup()`
gestisce il caso correttamente.

### F2.10 — Test del server

| File | Dimostra |
|---|---|
| `test/hmac.test.ts` | Firma valida accettata; timestamp vecchio rifiutato; firma riusata rifiutata; corpo alterato rifiutato |
| `test/verify.test.ts` | Con verifier che risponde `purchased` si concede il Pro; con `not_found` si risponde free; con `upstream` si risponde 503 e **non** si concede |
| `test/verify_idempotent.test.ts` | Due verifiche dello stesso token producono una sola riga in `purchases` e un solo entitlement |
| `test/entitlements.test.ts` | `GET` restituisce lo stato corretto; `install_mismatch` è 403 |
| `test/restore.test.ts` | Scadenza, uso singolo, tetto di 3 codici, claim che sposta l'entitlement |
| `test/rtdn.test.ts` | Deduplica per `message_id`; revoca su acquisto annullato; 200 anche su errore applicativo |
| `test/admin.test.ts` | Login, sessione, revoca manuale con audit, accesso senza sessione respinto |
| `test/migrate.test.ts` | Migrazione da zero e rilancio idempotente |
| `test/backup.test.ts` | Backup prodotto e ripristinabile; rotazione |

✔ DoD F2.10: `npm test` verde; ogni rotta ha almeno un test del percorso felice e uno del
percorso d'errore.

### F2.11 — Docker

**`server/Dockerfile`** — multi-stage: `node:22-bookworm-slim` per il build (serve
`python3`, `make`, `g++` per compilare `better-sqlite3` e `argon2`), immagine finale
`node:22-bookworm-slim` con solo `dist/` e `node_modules` di produzione, utente non root,
`HEALTHCHECK` su `/healthz`.

**`server/docker-compose.yml`**

```yaml
services:
  license-server:
    build: .
    restart: unless-stopped
    env_file: .env
    ports:
      - "127.0.0.1:8087:8087"
    volumes:
      - ./data:/app/data
    healthcheck:
      test: ["CMD", "node", "-e", "fetch('http://127.0.0.1:8087/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]
      interval: 30s
      timeout: 5s
      retries: 3
```

☠ **Trappola**: il bind è su `127.0.0.1`, non su `0.0.0.0`. Il servizio deve essere
raggiungibile **solo** attraverso il reverse proxy di `clawserver`. Esporre 8087 su
internet significa esporre il pannello admin.

☠ **Trappola**: `better-sqlite3` è un modulo nativo. Se si copia `node_modules` dalla
macchina Windows nell'immagine Linux, il container non parte. Il Dockerfile deve installare
le dipendenze **dentro** l'immagine, e `.dockerignore` deve contenere `node_modules`.

### F2.12 — `server/codebase_reference.md`

Deve contenere tutte le tabelle con ogni colonna, tipo, indice e vincolo; tutti gli endpoint
con auth, input, output e codici d'errore; tutte le chiavi di configurazione con variabile
d'ambiente, default e significato; il catalogo dei test; le regole non negoziabili (mai
concedere senza Google, mai esporre 8087, `PRAGMA foreign_keys`, `message_id` unico) e le
trappole disinnescate.

### F2.13 — Rituale di fine fase F2

Eseguire §6. Branch previsto: `v3.0.0`.

---

## §8.T — Scheletro comune di un'app (vale per F3, F4, F5, F6)

Tutte e quattro le app hanno la stessa struttura di cartelle e gli stessi file di
infrastruttura. Questa sezione si scrive una volta e si cita da ogni fase applicativa: quando
in F4 si legge "applica §8.T", significa creare esattamente questi file adattando i nomi.

```
apps/<app>/
├─ pubspec.yaml
├─ codebase_reference.md
├─ assets/
│  ├─ fonts/
│  └─ images/
├─ android/app/src/main/AndroidManifest.xml
├─ lib/
│  ├─ main.dart                  ← solo bootstrap, zero logica
│  ├─ app/
│  │  ├─ app.dart                ← MaterialApp.router, tema, locale
│  │  ├─ router.dart             ← GoRouter e redirect di onboarding
│  │  ├─ routes.dart             ← costanti dei path
│  │  ├─ app_config.dart         ← appId, SKU, seed color, font, baseUrl, segreti da dart-define
│  │  ├─ feature_limits.dart     ← la mappa FeatureLimits dell'app (ADR-017)
│  │  ├─ paywall_config.dart     ← i testi del paywall dell'app
│  │  └─ providers.dart          ← provider radice (db, servizi, entitlement, notifiche)
│  ├─ data/
│  │  ├─ database.dart           ← @DriftDatabase, schemaVersion, MigrationStrategy
│  │  ├─ tables/                 ← una tabella per file
│  │  ├─ daos/                   ← un DAO per aggregato
│  │  └─ backup_source.dart      ← implementazione di BackupSource
│  ├─ domain/                    ← modelli puri e motori di calcolo, zero Flutter
│  ├─ features/                  ← una cartella per schermata o gruppo di schermate
│  │  └─ <feature>/
│  │     ├─ <feature>_page.dart
│  │     ├─ <feature>_controller.dart   ← Notifier Riverpod
│  │     └─ widgets/
│  ├─ services/                  ← servizi applicativi (scheduler notifiche, export…)
│  └─ l10n/
│     ├─ app_it.arb
│     └─ app_en.arb
└─ test/
```

⚑ **Perché `domain/` non importa Flutter**: i motori di calcolo (ricorrenze, consumo, aging,
stato del rullino) sono la parte in cui un errore è invisibile e costoso. Tenendoli liberi da
Flutter si testano in millisecondi, senza `WidgetTester`, e si può girare l'intera suite dei
motori a ogni salvataggio.

**`lib/app/app_config.dart`** — **solo i valori**. La classe `MicroAppConfig` vive in
`micro_core` (`lib/src/config/micro_app_config.dart`), perché la forma è identica in tutte
e quattro le app e duplicarla quattro volte sarebbe esattamente ciò che `micro_core` esiste
per evitare. Ogni app espone una funzione `build<Nome>Config()` che chiama
`MicroAppConfig.fromEnvironment(...)` con i propri valori.

⚑ **Correzione rispetto alla prima stesura di questo piano**: qui era scritto di definire
la classe in ogni app. Sbagliato: quattro definizioni identiche divergono al primo ritocco.
La firma reale è quella qui sotto, con la classe in `micro_core`.

`MicroAppConfig` in `micro_core`:

```dart
enum BillingMode { fake, play }

@immutable
class MicroAppConfig {
  const MicroAppConfig({required this.appId, required this.appName, required this.proSku,
    required this.seedColor, required this.fontFamily, required this.defaultBrightness,
    required this.billingMode, this.displayFontFamily, this.licenseBaseUrl,
    this.appSecret = ''});

  factory MicroAppConfig.fromEnvironment({
    required String appId, required String appName, required String proSku,
    required Color seedColor, required String fontFamily,
    required Brightness defaultBrightness, String? displayFontFamily});

  final String appId;
  final String appName;
  final String proSku;
  final Color seedColor;
  final String fontFamily;
  final String? displayFontFamily;
  final Brightness defaultBrightness;
  final BillingMode billingMode;
  final Uri? licenseBaseUrl;       // null = nessuna verifica server
  final String appSecret;

  bool get serverEnabled;
  bool get usesRealBilling;
  void assertUsableInRelease();    // lancia se release + BILLING=fake
}
```

`fromEnvironment` legge tre `--dart-define`:

| define | valori | significato |
|---|---|---|
| `BILLING` | `fake` oppure `play` | quale gateway usare; senza define, `fake` in debug e `play` in release |
| `MA_LICENSE_URL` | URL | base del License Server; assente = nessuna verifica lato server |
| `MA_APP_SECRET` | stringa | segreto HMAC per firmare le chiamate (ADR-014) |

Ogni app espone poi la sua sola riga di valori, per esempio in
`apps/trashcan/lib/app/app_config.dart`:

```dart
MicroAppConfig buildTrashcanConfig();
```

☠ **Trappola**: una build di release con `BILLING=fake` regalerebbe il Pro a chiunque
tocchi il pulsante. `assertUsableInRelease()`, chiamata in `main()` prima di `runApp`, la fa
fallire all'avvio. Un crash in fase di verifica e' incomparabilmente meno grave.

**`lib/main.dart`** — identico in tutte le app, salvo il config:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final paths = await AppPaths.resolve(appId: config.appId);
  await paths.ensureAll();
  MicroLog.init(file: paths.file(paths.support, 'app.log'));
  FlutterError.onError = (details) => MicroLog.e('flutter', error: details.exception, stackTrace: details.stack);
  runApp(ProviderScope(
    overrides: [appConfigProvider.overrideWithValue(config), appPathsProvider.overrideWithValue(paths)],
    child: const MicroApp(),
  ));
}
```

⚑ **Perché `main.dart` non fa altro**: tutto il resto è inizializzato in modo pigro dai
provider. Un `main` che apre il database, inizializza le notifiche e chiama il server prima
del primo frame produce una schermata bianca di due secondi all'avvio, che è il difetto più
notato dagli utenti e il più penalizzato dalle Android Vitals.

**Provider radice** (`lib/app/providers.dart`), stessa forma ovunque:

| Provider | Tipo | Note |
|---|---|---|
| `appConfigProvider` | `Provider<AppConfig>` | sovrascritto in `main` |
| `appPathsProvider` | `Provider<AppPaths>` | sovrascritto in `main` |
| `databaseProvider` | `Provider<AppDatabase>` | `onDispose` chiude il DB |
| `settingsProvider` | `FutureProvider<SettingsStore>` | |
| `installIdProvider` | `FutureProvider<InstallId>` | |
| `purchaseGatewayProvider` | `Provider<PurchaseGateway>` | sceglie fake o play da `AppConfig` |
| `entitlementServiceProvider` | `ChangeNotifierProvider<EntitlementService>` | |
| `isProProvider` | `Provider<bool>` | comodità: `watch(entitlementServiceProvider).isPro` |
| `featureGateProvider` | `Provider<FeatureGate>` | costruito da `appFeatureLimits` + `isProProvider` |
| `notificationServiceProvider` | `FutureProvider<NotificationService>` | |
| `backupServiceProvider` | `Provider<BackupService>` | |
| `themeModeProvider` | `NotifierProvider<ThemeModeNotifier, ThemeMode>` | |

**Ripianificazione delle notifiche** — servizio applicativo presente in tutte le app che ne
hanno bisogno, con questa forma:

```dart
abstract interface class NotificationScheduler {
  Future<void> rescheduleAll();
  Future<void> cancelAll();
}
```

Va richiamato da: `AppLifecycleState.resumed`, ogni scrittura sul DB che tocchi le date, il
cambio delle impostazioni di notifica, e il primo avvio dopo un ripristino di backup.

**`AndroidManifest.xml`** comune — permessi minimi:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="com.android.vending.BILLING"/>
```

Solo TrashCan aggiunge `SCHEDULE_EXACT_ALARM` e `USE_EXACT_ALARM` (ADR-009). Nessuna app
chiede `INTERNET` esplicitamente perché è già implicito, ma le app **senza** server
configurato devono comunque funzionare in modalità aereo: è verificato dal test di
integrazione.

☠ **Trappola**: `flutter_local_notifications` richiede il receiver `ScheduledNotification
BootReceiver` dichiarato nel manifest, altrimenti dopo un riavvio del telefono tutte le
notifiche pianificate spariscono senza segnali. La sezione va copiata dalla documentazione
del plugin, non inventata.

**Onboarding e paywall, comportamento comune:**

- Il paywall non si mostra **mai** al primo avvio. Si mostra quando l'utente incontra un
  limite, oppure dalla voce "Passa a Pro" nelle impostazioni.
- Ogni `GateBlocked` mostra un bottom sheet breve che spiega il limite e offre due bottoni:
  "Vedi cosa include Pro" e "Non ora".
- La richiesta di recensione (`in_app_review`) si mostra **una sola volta**, dopo almeno 5
  aperture dell'app e almeno 7 giorni dall'installazione, e mai subito dopo un errore.

⚑ **Perché mai al primo avvio**: un paywall prima che l'utente abbia capito a cosa serve
l'app produce disinstallazione immediata e una recensione negativa. Il momento giusto è
quello in cui il limite tocca un bisogno reale ("vuoi aggiungere il secondo freezer").

---

## F3 — TrashCan (app pilota)

**Obiettivo della fase**: la prima app completa e pubblicabile, e la validazione end-to-end
di tutta la catena `micro_core` → billing Play → License Server. È l'app pilota perché ha il
target più ampio, la logica più interessante (ricorrenze) e la superficie UI più piccola.

### F3.1 — Bootstrap del progetto

▶ Azioni:

1. `flutter create --org com.smp --project-name trashcan --platforms=android apps/trashcan`
   poi rinominare la cartella se necessario.
2. Applicare **§8.T** per intero.
3. `pubspec.yaml`: dipendenze `micro_core` (path), `flutter_riverpod`, `go_router`, `drift`,
   `sqlite3_flutter_libs`, `path_provider`, `intl`, `home_widget`, `in_app_review`;
   dev: `drift_dev`, `build_runner`, `flutter_test`, `integration_test`.
4. `AppConfig`: `appId: 'trashcan'`, `proSku: 'trashcan_pro_lifetime'`,
   `seedColor: Color(0xFF2E7D5B)`, `fontFamily: 'Outfit'`, `defaultBrightness: light`.
5. `minSdk: 24`, `targetSdk: 35`, `compileSdk: 35`.

⚑ **Perché `minSdk 24` (Android 7)**: sotto il 24 mancano API di notifica e di formattazione
che costringerebbero a scrivere rami alternativi per una quota di mercato ormai sotto l'1%.

✔ DoD: `flutter run` mostra una schermata vuota con il tema corretto in light e dark.

### F3.2 — Data layer

**`lib/data/tables/collection_calendars.dart`**

| Colonna | Tipo Drift | Vincoli | Note |
|---|---|---|---|
| `id` | `IntColumn` | autoIncrement | |
| `name` | `TextColumn` | 1–60 caratteri | "Casa", "Casa al mare" |
| `notificationTime` | `TextColumn` | `HH:mm` | orario di default del calendario |
| `enabled` | `BoolColumn` | default true | |
| `sortOrder` | `IntColumn` | default 0 | |
| `createdAt` | `IntColumn` | ms UTC | |

**`lib/data/tables/waste_types.dart`**

| Colonna | Tipo | Vincoli |
|---|---|---|
| `id` | `IntColumn` | autoIncrement |
| `calendarId` | `IntColumn` | references CollectionCalendars, onDelete cascade |
| `name` | `TextColumn` | 1–40 |
| `iconKey` | `TextColumn` | chiave in `WasteIcons`, non un codepoint |
| `colorValue` | `IntColumn` | ARGB |
| `notificationsEnabled` | `BoolColumn` | default true |
| `sortOrder` | `IntColumn` | |

☠ **Trappola**: salvare `IconData.codePoint` nel database **rompe il tree shaking delle
icone** e in release le icone diventano quadrati vuoti. Si salva una **chiave stringa**
risolta da una mappa costante `WasteIcons.byKey`.

**`lib/data/tables/recurrence_rules.dart`**

| Colonna | Tipo | Vincoli | Note |
|---|---|---|---|
| `id` | `IntColumn` | autoIncrement | |
| `wasteTypeId` | `IntColumn` | references, cascade | |
| `kind` | `TextColumn` | `weekly` \| `everyNWeeks` \| `monthlyDay` \| `monthlyNthWeekday` \| `manual` | |
| `weekdaysMask` | `IntColumn` | bitmask 1..127 | bit 0 = lunedì |
| `intervalWeeks` | `IntColumn` | nullable, ≥ 2 | per `everyNWeeks` |
| `anchorDate` | `TextColumn` | `YYYY-MM-DD`, nullable | inizio del ciclo per `everyNWeeks` |
| `dayOfMonth` | `IntColumn` | nullable, 1..31 | |
| `nthOfMonth` | `IntColumn` | nullable, 1..5 e −1 (ultimo) | |
| `weekday` | `IntColumn` | nullable, 1..7 | |
| `manualDatesCsv` | `TextColumn` | nullable | date `YYYY-MM-DD` separate da virgola |
| `startDate` | `TextColumn` | `YYYY-MM-DD` | |
| `endDate` | `TextColumn` | nullable | |

**`lib/data/tables/collection_exceptions.dart`**

| Colonna | Tipo | Note |
|---|---|---|
| `id` | `IntColumn` | |
| `wasteTypeId` | `IntColumn` | references, cascade |
| `originalDate` | `TextColumn` nullable | null quando è una raccolta straordinaria |
| `replacementDate` | `TextColumn` nullable | null quando è uno "salta" |
| `skipped` | `BoolColumn` | true = raccolta annullata |
| `note` | `TextColumn` nullable | |

Le tre combinazioni ammesse, con `CHECK` a livello di DAO:

| Caso | `originalDate` | `replacementDate` | `skipped` |
|---|---|---|---|
| Salta | data | null | true |
| Sposta | data | data | false |
| Straordinaria | null | data | false |

**DAO**: `CalendarsDao`, `WasteTypesDao`, `RulesDao`, `ExceptionsDao`, ognuno con
`watchAll()`, `getById()`, `insert()`, `update()`, `delete()` e le query aggregate usate
dalla home.

**`lib/data/database.dart`**

```dart
@DriftDatabase(tables: [CollectionCalendars, WasteTypes, RecurrenceRules, CollectionExceptions],
               daos: [CalendarsDao, WasteTypesDao, RulesDao, ExceptionsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  factory AppDatabase.open(File file);
  factory AppDatabase.memory();
  @override int get schemaVersion => 1;
  @override MigrationStrategy get migration;
}
```

**F3.2.6 — Test di migrazione**: generare gli schema dump con
`dart run drift_dev schema dump lib/data/database.dart drift_schemas/` e i passi con
`dart run drift_dev schema steps`. Il test `test/data/migration_test.dart` verifica ogni
transizione. Alla versione 1 il test è banale ma **il meccanismo va messo in piedi adesso**,
non alla versione 2, quando ci sono già utenti.

### F3.3 — Motore delle ricorrenze

**`lib/domain/recurrence.dart`** (nessun import di Flutter)

```dart
sealed class Recurrence {
  const Recurrence({required this.startDate, this.endDate});
  final CivilDate startDate;
  final CivilDate? endDate;
  bool occursOn(CivilDate date);
  Iterable<CivilDate> occurrencesIn(CivilDate from, CivilDate to);
}

final class WeeklyRecurrence extends Recurrence {
  const WeeklyRecurrence({required this.weekdays, required super.startDate, super.endDate});
  final Set<int> weekdays;                 // DateTime.monday..sunday
}

final class EveryNWeeksRecurrence extends Recurrence {
  const EveryNWeeksRecurrence({required this.weekdays, required this.intervalWeeks,
    required this.anchor, required super.startDate, super.endDate});
  final Set<int> weekdays;
  final int intervalWeeks;                 // >= 2
  final CivilDate anchor;                  // primo giorno della prima settimana "attiva"
}

final class MonthlyDayRecurrence extends Recurrence {
  const MonthlyDayRecurrence({required this.dayOfMonth, required super.startDate, super.endDate});
  final int dayOfMonth;                    // 1..31, con clamp a fine mese
}

final class MonthlyNthWeekdayRecurrence extends Recurrence {
  const MonthlyNthWeekdayRecurrence({required this.nth, required this.weekday, required super.startDate, super.endDate});
  final int nth;                           // 1..5, oppure -1 per "l'ultimo"
  final int weekday;
}

final class ManualDatesRecurrence extends Recurrence {
  const ManualDatesRecurrence({required this.dates, required super.startDate, super.endDate});
  final List<CivilDate> dates;
}
```

⚑ **Perché `anchor` in `EveryNWeeksRecurrence`**: "carta ogni due mercoledì" è ambiguo senza
sapere **quale** mercoledì. L'ancora è la data che l'utente indica come "la prossima
raccolta"; il motore calcola le altre come `anchor + k * intervalWeeks`. Senza ancora, il
calcolo dipenderebbe dalla settimana ISO, che cambia significato a cavallo dell'anno.

**`lib/domain/occurrence_engine.dart`**

```dart
@immutable
class CollectionOccurrence {
  const CollectionOccurrence({required this.wasteTypeId, required this.date,
    required this.origin, this.note});
  final int wasteTypeId;
  final CivilDate date;
  final OccurrenceOrigin origin;     // regular | moved | extra
  final String? note;
}

enum OccurrenceOrigin { regular, moved, extra }

@immutable
class RuleWithExceptions {
  const RuleWithExceptions({required this.wasteTypeId, required this.recurrence, required this.exceptions});
  final int wasteTypeId;
  final Recurrence recurrence;
  final List<CollectionException> exceptions;
}

class OccurrenceEngine {
  const OccurrenceEngine();

  List<CollectionOccurrence> expand({
    required List<RuleWithExceptions> rules,
    required CivilDate from,
    required CivilDate to,
  });

  List<CollectionOccurrence> onDate(CivilDate date, {required List<RuleWithExceptions> rules});
  List<CollectionOccurrence> tonight({required List<RuleWithExceptions> rules, CivilDate? today});
  CollectionOccurrence? next({required List<RuleWithExceptions> rules, CivilDate? from});
  List<CollectionOccurrence> nextN(int count, {required List<RuleWithExceptions> rules, CivilDate? from});
}
```

Algoritmo di `expand`, nell'ordine esatto:

1. Per ogni regola, genera le occorrenze base con `recurrence.occurrencesIn(from, to)`.
2. Applica le eccezioni **salta**: rimuovi le occorrenze la cui data è in `originalDate` con
   `skipped == true`.
3. Applica le eccezioni **sposta**: rimuovi `originalDate`, aggiungi `replacementDate` con
   `origin: moved`. Se `replacementDate` è fuori dalla finestra, l'occorrenza sparisce dalla
   finestra: è corretto.
4. Aggiungi le **straordinarie** (`originalDate == null`) con `origin: extra`.
5. Deduplica per `(wasteTypeId, date)` tenendo la priorità `extra` > `moved` > `regular`.
6. Ordina per data, poi per `sortOrder` del tipo di rifiuto.

⚑ **Perché l'ordine 2→3→4 è vincolante**: uno spostamento su una data già saltata non deve
resuscitare la raccolta. Invertendo i passi si otterrebbe quel comportamento, che è sbagliato
e difficilissimo da diagnosticare a posteriori.

⚑ **`tonight()` è la funzione più importante dell'app**: la home dice cosa portare fuori
**stasera**, che corrisponde alla raccolta di **domani**. Quindi
`tonight() == onDate(today.addDays(1))`. Questa asimmetria va scritta nel codice con un
commento, perché è controintuitiva e qualcuno prima o poi la "correggerà".

**Test obbligatori** in `test/domain/occurrence_engine_test.dart`, con quello che dimostrano:

| Caso | Dimostra |
|---|---|
| Settimanale su due giorni, finestra di 4 settimane | Espansione base |
| Ogni 2 settimane con ancora al mercoledì | L'ancora determina la parità, non la settimana ISO |
| Ogni 2 settimane a cavallo del 31 dicembre | Nessun salto alla settimana ISO 1 |
| Mensile giorno 31 | Clamp a 28/29/30 nei mesi corti |
| Mensile "ultimo venerdì" | `nth == -1` |
| Salta il 25 dicembre | L'occorrenza sparisce |
| Sposta 25 → 26 dicembre | Una sola occorrenza, con `origin: moved` |
| Salta **e** sposta la stessa data | Prevale il salto |
| Straordinaria il 31 dicembre | `origin: extra` |
| Due regole sullo stesso giorno | Ordine per `sortOrder` |
| `endDate` passata | Nessuna occorrenza dopo `endDate` |
| Passaggio all'ora legale (ultima domenica di marzo) | Nessuno slittamento di giorno |
| Anno bisestile, 29 febbraio | Nessuna eccezione |
| Finestra vuota (`from > to`) | Lista vuota, nessun crash |

### F3.4 — Wizard di setup iniziale

`lib/features/onboarding/` — quattro passi:

1. Benvenuto, con una frase che spiega il valore ("Non serve il calendario del tuo Comune").
2. Nome del calendario (default "Casa").
3. Scelta dei tipi di rifiuto dai preset (organico, carta, plastica, vetro, metalli,
   indifferenziato, verde, pannolini, altro), con icona e colore già assegnati e modificabili.
4. Per ogni tipo scelto, i giorni della settimana. Un solo schermo con una griglia
   tipo × giorno, non quattro schermi in sequenza.
5. Orario della notifica (default 20:00) e richiesta del permesso.

⚑ **Perché la griglia e non un wizard per tipo**: l'utente ha in mano il volantino del
Comune con una tabella. Riprodurre la tabella è la traduzione più diretta possibile del suo
modello mentale, e riduce il setup da due minuti a trenta secondi. Il setup è il momento in
cui si perdono più utenti.

`OnboardingController` è un `Notifier<OnboardingState>` che accumula lo stato e scrive tutto
in una sola transazione alla fine.

### F3.5 — Home

`lib/features/home/home_page.dart`. Struttura verticale:

1. **Blocco "Stasera"**: enorme. O il nome del tipo di rifiuto con la sua icona e il suo
   colore a tutta larghezza, o "Stasera non devi buttare nulla". Se ci sono più tipi, li
   elenca tutti.
2. **"Prossima raccolta"**: tipo + "domani sera" / "giovedì sera" / data.
3. **Prossimi 7 giorni**: lista compatta.
4. Se ci sono più calendari (Pro), selettore in alto.

⚑ **Perché il blocco "Stasera" occupa mezzo schermo**: l'app viene aperta di sera, spesso di
fretta, spesso con le mani occupate. La risposta deve essere leggibile a un metro di
distanza senza mettere a fuoco. È l'intera proposta di valore in un colpo d'occhio.

☠ **Trappola**: il colore del tipo di rifiuto scelto dall'utente può avere contrasto
insufficiente con il testo. `MicroCard(accent:)` calcola il colore del testo con
`ThemeData.estimateBrightnessForColor` e non usa mai il colore grezzo come sfondo del testo.

☠ **Trappola di prestazioni, da disinnescare quando si scrive la home**:
`OccurrenceEngine.expand` è O(giorni × regole) e alloca un oggetto per ogni raccolta.
`next()` con orizzonte 400 giorni ne costruisce qualche centinaio. È irrilevante una volta,
**disastroso se chiamato a ogni frame**. La home deve leggere le occorrenze da un provider
che le calcola una sola volta e le ricalcola solo quando cambiano i dati o la data:

```dart
final occurrencesProvider = StreamProvider.autoDispose<List<CollectionOccurrence>>(...);
```

Non si chiama mai `expand`, `next` o `tonight` dentro un `build`.

### F3.6 — Gestione tipi e regole

`lib/features/waste_types/` — lista, creazione, modifica, riordino con drag, cancellazione
con conferma (cancella anche regole ed eccezioni: la conferma lo dice esplicitamente).

`lib/features/rules/rule_editor_page.dart` — un editor che cambia forma in base al `kind`
scelto, con anteprima **live** delle prossime 6 date generate dalla regola.

⚑ **Perché l'anteprima live**: "ogni 2 settimane a partire da mercoledì 8" è difficile da
verificare mentalmente. Mostrare le sei date successive mentre l'utente modifica la regola
elimina la classe di errore più comune (calendario configurato male, notifiche sbagliate per
mesi, recensione negativa).

### F3.7 — Eccezioni

`lib/features/exceptions/` — dalla vista mensile o dalla lista dei prossimi giorni, un tap
lungo su un'occorrenza apre un menu: **Salta questa raccolta**, **Sposta a…**,
**Aggiungi raccolta straordinaria**. Una sezione nelle impostazioni elenca tutte le eccezioni
attive e permette di rimuoverle.

### F3.8 — Notifiche

`lib/services/trashcan_scheduler.dart`

```dart
class TrashcanScheduler implements NotificationScheduler {
  TrashcanScheduler({required AppDatabase db, required NotificationService notifications,
    required SettingsStore settings, required FeatureGate gate});

  static const int horizonDays = 60;
  static const int maxScheduled = 64;

  @override Future<void> rescheduleAll();
  @override Future<void> cancelAll();
  Future<List<ScheduledNotification>> computeSchedule({CivilDate? today});
}
```

Regole di calcolo:

- Per ogni occorrenza nei prossimi 60 giorni, con `notificationsEnabled` sul tipo e
  `enabled` sul calendario, genera una notifica il **giorno prima** all'orario del calendario
  (default 20:00).
- Nel piano gratuito, **un solo** orario per calendario. Con Pro (`FeatureKey.multipleNotifications`),
  fino a **tre** orari per calendario (per esempio 18:00 e 20:00).
- Testo: `"Domani raccolgono {tipi}. Ricordati di portarli fuori questa sera."` Con più tipi,
  la lista separata da virgole. Titolo: il nome del calendario, se ce n'è più di uno.
- Ordina per data e tronca a 64.
- `payload` = `trashcan://occurrence?date=YYYY-MM-DD&calendar=<id>` per il deep link.

Permesso exact alarm: alla prima attivazione delle notifiche, se
`canScheduleExactAlarms() == false`, mostra una schermata che spiega perché serve
("le notifiche devono arrivare all'ora esatta della sera, non quando decide il sistema") con
un bottone che apre le impostazioni. Se l'utente rifiuta, si pianifica comunque in modalità
inesatta e si mostra un avviso discreto nelle impostazioni. **L'app funziona lo stesso.**

☠ **Trappola**: la ripianificazione a ogni resume è potenzialmente costosa (64
cancellazioni + 64 pianificazioni). Si esegue solo se è passata più di un'ora dall'ultima
(`SettingKeys.lastRescheduleAt`) **oppure** se i dati sono cambiati. Senza questo controllo
l'app impiega mezzo secondo a tornare in primo piano.

### F3.9 — Calendari multipli e paywall

Mappa dei limiti, `lib/app/feature_limits.dart`:

```dart
const FeatureLimits trashcanLimits = {
  FeatureKey.unlimitedEntities:     FeatureLimit.count(freeMax: 1),   // calendari
  FeatureKey.multipleNotifications: FeatureLimit.locked(),
  FeatureKey.advancedWidget:        FeatureLimit.locked(),
  FeatureKey.backupRestore:         FeatureLimit.locked(),
  FeatureKey.themeCustomization:    FeatureLimit.locked(),
  FeatureKey.csvExport:             FeatureLimit.locked(),
};
```

Tutto il resto è aperto: tipi di rifiuto illimitati, regole illimitate, eccezioni illimitate,
notifica serale, widget base.

⚑ **Perché il piano gratuito è così generoso**: TrashCan gratuito deve essere l'app migliore
della categoria, altrimenti non viene installata e non c'è nessuno a cui vendere il Pro. Il
Pro vende il **secondo** calendario (seconda casa, casa dei genitori), che è esattamente il
profilo di chi paga volentieri tre euro.

Paywall (`lib/app/paywall_config.dart`): titolo "TrashCan Pro", sottotitolo "Un pagamento
unico. Per sempre.", benefici: calendari illimitati, widget avanzato, notifiche multiple,
backup e trasferimento, personalizzazione completa.

### F3.10 — Export, import, backup

- `TrashcanBackupSource implements BackupSource` con `schemaId: 'trashcan'`.
- Export di **un singolo calendario** come `.trashcan.json` condivisibile: è la funzione
  "condivisione" della spec, che permette a un vicino di importare lo stesso calendario.
- Import con anteprima: mostra nome, numero di tipi e di regole prima di confermare.

⚑ **Perché la condivisione del calendario è nel piano gratuito e il backup no**: la
condivisione è un canale di acquisizione (un utente porta un vicino), il backup è una comodità
personale. Regalare l'acquisizione e vendere la comodità è il verso giusto.

### F3.11 — Widget Android

`android/app/src/main/kotlin/.../TrashcanWidgetProvider.kt` + `home_widget`.

- Widget 4×1: "STASERA" + tipo (o "Niente") + riga piccola "Prossimo: X domani".
- Il colore di sfondo segue il tipo di rifiuto della sera.
- Aggiornato dall'app a ogni ripianificazione e da un `AlarmManager` alle 00:05.
- Versione gratuita: testo semplice. Versione Pro (`FeatureKey.advancedWidget`): colori del
  tipo, scelta del calendario, prossimi tre giorni, dimensione 4×2.

☠ **Trappola**: i widget Android non possono usare Flutter per il rendering. Si passano i
dati con `HomeWidget.saveWidgetData` e si disegna in `RemoteViews`. Il layout XML va tenuto
semplice: `RemoteViews` supporta un sottoinsieme ristretto di view, e un `ConstraintLayout`
non funziona.

### F3.12 — Play Console e verifica end-to-end del billing

Questa sottofase è il vero motivo per cui TrashCan è l'app pilota.

▶ Azioni:

1. Creare l'app in Play Console con `com.smp.trashcan`.
2. Compilare la scheda minima richiesta per un test interno.
3. Creare il prodotto in-app `trashcan_pro_lifetime`, prezzo 2,99 €, stato attivo.
4. Caricare un AAB firmato sul canale **interno**.
5. Aggiungere l'account di test alle licenze di test (acquisti senza addebito reale).
6. Con il server in esecuzione **in locale** ed esposto temporaneamente (tunnel SSH o
   `--dart-define=MA_LICENSE_URL=http://10.0.2.2:8087` su emulatore), verificare la catena:
   acquisto → entitlement locale immediato → `POST /v1/purchases/verify` → riga in
   `entitlements` visibile nel pannello admin.
7. Verificare i casi: acquisto annullato, acquisto in attesa, riavvio dell'app dopo
   l'acquisto, reinstallazione con ripristino, modalità aereo dopo l'acquisto.
8. Verificare il **rimborso**: rimborsare l'acquisto di test da Play Console e controllare
   che l'RTDN (se già configurato) o la sync a 24 ore porti lo stato a `revoked`.

☠ **Trappola**: il prodotto in-app non è acquistabile finché l'AAB **non è stato pubblicato
su un canale**, anche solo interno, e possono passare alcune ore prima che diventi
disponibile. Chi non lo sa passa mezza giornata a debuggare `productDetails` vuoto. Va messo
in conto nella pianificazione.

☠ **Trappola**: le licenze di test funzionano solo per gli account elencati **e** solo se
l'app installata proviene dal canale di Play, non da `flutter run`. Per testare il billing
reale si installa l'AAB dal link del canale interno.

✔ DoD F3.12: uno screenshot del pannello admin che mostra l'entitlement creato da un
acquisto reale di test, e la stessa riga sparita dopo il rimborso.

### F3.13 — Test

Oltre ai test del motore (F3.3): DAO, `TrashcanScheduler.computeSchedule` (senza toccare il
sistema di notifiche), widget test della home nei tre stati (niente stasera / un tipo / tre
tipi), widget test del paywall, due golden della home, e un test di integrazione
"primo avvio → wizard → home mostra la raccolta di domani → notifica pianificata".

### F3.14 — Rifinitura

Empty state per ogni lista, animazione del blocco "Stasera", supporto al testo ingrandito
fino al 200%, `Semantics` sulle card, verifica del contrasto AA su tutti i colori preset,
icona dell'app e icona di notifica monocromatica.

### F3.15 — `apps/trashcan/codebase_reference.md`

### F3.16 — Rituale di fine fase F3

Eseguire §6. Branch previsto: `v4.0.0`.

---

## F4 — Full Freezer

**Obiettivo della fase**: l'app in cui tutto è subordinato a una domanda ("cosa c'è lì
dentro da troppo tempo?") e a un gesto ("metti nel freezer" in meno di cinque secondi).

**Vincolo di prodotto misurabile**: dall'apertura dell'app al prodotto salvato con nome e
quantità devono passare **meno di 5 secondi** e **meno di 4 tocchi**. Questo numero è un
criterio di accettazione, non un auspicio: si misura con il test di integrazione F4.13.

### F4.1 — Bootstrap

Applicare **§8.T**. `appId: 'full_freezer'`, `proSku: 'fullfreezer_pro_lifetime'`,
`seedColor: Color(0xFF3A7CA5)`, `fontFamily: 'PlusJakartaSans'`, brightness light.
Dipendenze aggiuntive: `speech_to_text` (F4.12), `home_widget` (F4.11), `image_picker`,
`fl_chart` (statistiche Pro).

### F4.2 — Data layer

**`freezers`**

| Colonna | Tipo | Note |
|---|---|---|
| `id` | int | |
| `name` | text | "Freezer cucina" |
| `sortOrder` | int | |
| `createdAt` | int | ms UTC |

**`compartments`**

| Colonna | Tipo | Note |
|---|---|---|
| `id` | int | |
| `freezerId` | int | references, cascade |
| `name` | text | "Cassetto 2" |
| `sortOrder` | int | |

**`items`** — il cuore dell'app.

| Colonna | Tipo | Vincoli | Note |
|---|---|---|---|
| `id` | int | | |
| `freezerId` | int | references | ridondante rispetto a `compartmentId`, ma serve per gli item senza scomparto |
| `compartmentId` | int nullable | references, setNull | |
| `name` | text | 1–60 | |
| `category` | text nullable | chiave in `ItemCategories` | |
| `quantity` | real | > 0 | |
| `unit` | text | chiave in `Units` (`porzioni`, `pezzi`, `g`, `kg`, `confezioni`, `L`) | |
| `frozenAt` | text | `YYYY-MM-DD` | ADR-008 |
| `reminderAfterDays` | int nullable | | override del preset di categoria |
| `photoPath` | text nullable | relativo (F1.11) | |
| `note` | text nullable | | |
| `status` | text | `stored` \| `consumed` \| `discarded` | |
| `removedAt` | int nullable | ms UTC | |
| `createdAt` | int | | |

Indici: `idx_items_status_frozen ON items(status, frozenAt)` — è l'indice che regge la home;
`idx_items_freezer`, `idx_items_name` per la ricerca.

⚑ **Perché `freezerId` è ridondante**: un alimento può stare in un freezer senza che l'utente
abbia definito gli scomparti. Ricavarlo con una join sullo scomparto costringerebbe a creare
uno scomparto fittizio "Nessuno", che sporca la UI. La ridondanza è tenuta coerente dal DAO.

**`item_movements`** (Pro, storico)

| Colonna | Tipo | Note |
|---|---|---|
| `id` | int | |
| `itemId` | int | references, cascade |
| `kind` | text | `stored` \| `consumed` \| `discarded` \| `moved` |
| `at` | int | ms UTC |
| `fromCompartmentId` / `toCompartmentId` | int nullable | per `moved` |

**`custom_categories`** (Pro): `id`, `name`, `iconKey`, `colorValue`, `defaultReminderDays`.

Categorie predefinite (in codice, non in DB) con promemoria suggerito in giorni:
carne rossa 180, carne bianca 180, pesce 120, verdura 240, frutta 240, pane e lievitati 90,
preparati e avanzi 90, gelati 180, altro 180.

☠ **Trappola di prodotto**: questi numeri **non sono garanzie di sicurezza alimentare**. La
spec lo dice esplicitamente e la UI deve dirlo: la stringa accanto al promemoria è
"promemoria organizzativo, non una scadenza". Vendere un'app che implica sicurezza
alimentare senza esserne titolati è un rischio reale, oltre che scorretto.

### F4.3 — `AgingCalculator`

**`lib/domain/aging.dart`**

```dart
enum AgingLevel { fresh, watch, old }

@immutable
class AgingInfo {
  const AgingInfo({required this.days, required this.level, required this.reminderDays, required this.overdueBy});
  final int days;
  final AgingLevel level;
  final int? reminderDays;
  final int? overdueBy;      // giorni oltre il promemoria, null se non superato
}

class AgingCalculator {
  const AgingCalculator({this.watchFraction = 0.8});
  final double watchFraction;

  int daysInFreezer(CivilDate frozenAt, {CivilDate? today});
  AgingInfo evaluate({required CivilDate frozenAt, int? reminderAfterDays, CivilDate? today});
  int? defaultReminderFor(String? categoryKey);
}
```

Regole: `old` se `days >= reminderDays`; `watch` se `days >= reminderDays * watchFraction`;
altrimenti `fresh`. Senza `reminderDays`, il livello è sempre `fresh` e la home ordina
comunque per anzianità.

⚑ **Perché l'ordinamento non dipende dal livello**: la USP è "il più vecchio per primo".
Ordinare per livello e poi per data farebbe scendere sotto un prodotto vecchissimo senza
promemoria configurato, che è esattamente quello che l'utente ha dimenticato.

### F4.4 — Home

1. Testata: nome del freezer selezionato (o "Tutti"), numero di prodotti, e il contatore
   "**N da usare presto**" in evidenza.
2. Sezione **"Da usare prima"**: i prodotti con `level != fresh`, ordinati per giorni
   decrescenti, massimo 5, con "vedi tutti".
3. Sezione **"Tutto il resto"**: ordinata per `frozenAt` crescente (più vecchio in cima).
4. Sezione **"Dove sono"**: elenco dei freezer con il conteggio per ciascuno.
5. FAB grande: **"+ Metti nel freezer"**.

Ogni riga è un `MicroListTile` con swipe a destra "Consumato" (verde) e a sinistra "Buttato"
(arancio), entrambi con snackbar di annullamento.

### F4.5 — Inserimento

**Rapido** (`QuickAddSheet`): bottom sheet che si apre con la tastiera **già attiva** sul
campo nome. Campi visibili: nome (autocompletamento dai nomi già usati), quantità con
stepper, unità (chip preselezionato con l'ultimo usato). Data = oggi, posizione = ultima
usata, categoria dedotta dal nome se corrisponde a un termine noto. Bottone "Salva".
Un link "Altri dettagli" apre la form completa mantenendo quanto già scritto.

⚑ **Perché l'autocompletamento sui nomi già usati**: il freezer di una famiglia contiene
sempre le stesse venti cose. Dopo due settimane, "spe" completa "Spezzatino" e l'inserimento
scende a due tocchi. È la singola ottimizzazione che fa la differenza tra un'app usata e una
abbandonata.

**Completo** (`ItemEditPage`): tutti i campi, foto (Pro), nota, promemoria personalizzato.

Funzione **"Ne ho congelato un altro uguale"**: duplica l'item con `frozenAt = oggi`,
disponibile dal menu di una riga. Nel piano gratuito è disponibile: costa nulla e crea
abitudine.

### F4.6 — Posizioni

`lib/features/locations/` — CRUD di freezer e scomparti, con drag per riordinare e conteggio
per ciascuno. Nel piano gratuito **un solo freezer**, scomparti illimitati.

⚑ **Perché gli scomparti sono gratuiti e i freezer no**: chi ha un freezer solo è il caso
comune; chi ha il freezer in garage **oltre** a quello in cucina ha già dimostrato di avere
il problema che l'app risolve, ed è disposto a pagare quattro euro.

### F4.7 — Uscita

Azioni "Consumato" e "Buttato" scrivono `status`, `removedAt` e una riga in `item_movements`.
Lo storico degli usciti è visibile solo con Pro (`FeatureKey.fullHistory`); nel piano
gratuito gli item usciti restano nel DB ma non sono elencati.

⚑ **Perché non si cancellano**: servono per le statistiche Pro (permanenza media, sprecato
vs consumato) e permettono di "vendere" il Pro mostrando un dato che l'utente ha già prodotto
senza saperlo ("hai 143 uscite registrate: sblocca le statistiche per vederle").

### F4.8 — Ricerca

Campo in testata, ricerca `LIKE` case-insensitive e accent-insensitive su `name` e `note`,
con debounce di 200 ms, risultati che mostrano posizione e giorni.

☠ **Trappola**: SQLite senza `ICU` non è accent-insensitive. Si memorizza una colonna
generata `name_norm` (minuscolo, senza accenti, calcolata in Dart al salvataggio) e si cerca
su quella. Cercare "pure" deve trovare "Purè".

### F4.9 — Notifiche

`lib/services/freezer_scheduler.dart` — **una sola** notifica ricorrente, il digest:

> "Hai 4 prodotti nel freezer da più di 90 giorni. Il più vecchio è Spezzatino, congelato 137 giorni fa."

Frequenza configurabile: settimanale (default, domenica alle 18:00), ogni 15 giorni, mensile.
Modalità `inexactAllowWhileIdle` (ADR-009). Se non ci sono prodotti in stato `old`, la
notifica **non viene mostrata**: si ripianifica e basta.

⚑ **Perché un digest e non una notifica per prodotto**: una notifica per ogni cosa che compie
90 giorni produce, in un freezer pieno, tre notifiche a settimana. L'utente le silenzia entro
un mese e l'app perde la sua unica leva di richiamo.

☠ **Trappola**: il testo del digest dipende dai dati **al momento della consegna**, non al
momento della pianificazione. Poiché `flutter_local_notifications` non può calcolare nulla a
consegna, si ripianifica il testo a ogni resume dell'app e a ogni modifica dei dati. Se
l'utente non apre l'app per un mese, il testo può essere leggermente datato: è accettabile e
va tenuto conservativo ("almeno 4 prodotti").

### F4.10 — Pro

```dart
const FeatureLimits freezerLimits = {
  FeatureKey.unlimitedEntities:  FeatureLimit.count(freeMax: 1),   // freezer
  FeatureKey.photos:             FeatureLimit.locked(),
  FeatureKey.fullHistory:        FeatureLimit.locked(),
  FeatureKey.statistics:         FeatureLimit.locked(),
  FeatureKey.csvExport:          FeatureLimit.locked(),
  FeatureKey.backupRestore:      FeatureLimit.locked(),
  FeatureKey.advancedWidget:     FeatureLimit.locked(),
  FeatureKey.customCategories:   FeatureLimit.locked(),
};
```

**Statistiche** (`lib/features/stats/`): consumati vs buttati nel periodo, permanenza media,
categoria più sprecata, andamento mensile con `fl_chart`, valore indicativo dello spreco se
l'utente ha inserito i costi (opzionale).

### F4.11 — Widget Android

4×2: titolo "Da usare presto", fino a tre righe "nome — N giorni", e il conteggio totale.
Tocco: apre l'app sulla sezione. Aggiornamento a ogni modifica e una volta al giorno.

### F4.12 — Voice input

`speech_to_text` sul campo nome del `QuickAddSheet`, con parsing locale della frase:

```dart
class VoiceItemParser {
  const VoiceItemParser({required this.locale});
  ParsedItem parse(String utterance);
}

@immutable
class ParsedItem {
  final String name;
  final double? quantity;
  final String? unit;
  final String? categoryKey;
  final double confidence;
}
```

Regole di parsing (solo italiano e inglese, **nessuna chiamata a server**): numeri in lettere
("due", "tre") e cifre, unità riconosciute da un dizionario, "di" come separatore
(`due porzioni di lasagne` → quantity 2, unit `porzioni`, name `lasagne`). Se la confidenza è
bassa, il testo va nel campo nome così com'è: **il fallback non deve mai essere un errore**.

⚑ **Perché nessuna AI server-side**: la spec lo chiede, e per queste tre regole un dizionario
e una regex bastano. Un servizio remoto aggiungerebbe latenza, costi, privacy da dichiarare e
una dipendenza di rete in un'app che si vanta di non averne.

### F4.13 — Test

Oltre allo standard: test di integrazione che **misura** il flusso di inserimento rapido e
fallisce se supera 4 interazioni; test del parser vocale su venti frasi reali; test della
ricerca accent-insensitive; test del digest con 0, 1 e N prodotti vecchi.

### F4.14 — Rifinitura · F4.15 — Atlante · F4.16 — Rituale (branch `v5.0.0`)

---

## F5 — Scorte Calore

**Obiettivo della fase**: rispondere in mezzo secondo a "quando devo ricomprare?", con una
stima che sia onesta sulla propria incertezza.

### F5.1 — Bootstrap

Applicare **§8.T**. `appId: 'scorte_calore'`, `proSku: 'scortecalore_pro_lifetime'`,
`seedColor: Color(0xFFC4622D)`, `fontFamily: 'Sora'`, brightness light.
Dipendenze aggiuntive: `fl_chart`, `device_calendar`.

### F5.2 — Data layer

**`fuel_sources`**

| Colonna | Tipo | Note |
|---|---|---|
| `id` | int | |
| `name` | text | "Stufa soggiorno" |
| `fuelType` | text | `pellet` \| `lpg` \| `diesel` \| `wood` \| `biomass` |
| `unit` | text | chiave in `FuelUnits` |
| `unitWeightKg` | real nullable | peso di un sacco/cesta |
| `tankCapacity` | real nullable | litri, per `lpg`/`diesel` |
| `usableFraction` | real | default 0.80 per `lpg`, 1.0 per gli altri |
| `warningDays` | int | default 7 |
| `costPerUnitCents` | int nullable | |
| `active` | bool | |
| `createdAt` | int | |

☠ **Trappola tecnica reale, già disinnescata**: un bombolone GPL **non si riempie mai oltre
l'80%** della capacità geometrica, per lasciare spazio all'espansione della fase gassosa. Il
manometro indica la percentuale di **riempimento del serbatoio**, che va moltiplicata per la
capacità **utile**, non per quella nominale. Senza `usableFraction`, l'app sovrastima la
scorta di un quarto e manda l'utente a secco. Il campo è configurabile perché non tutti gli
installatori usano la stessa convenzione, e la UI mostra sempre la conversione
("43% di 1.000 L → circa 344 L utili").

**`stock_measurements`**

| Colonna | Tipo | Note |
|---|---|---|
| `id` | int | |
| `fuelSourceId` | int | references, cascade |
| `date` | text | `YYYY-MM-DD` |
| `quantity` | real | nell'unità della fonte |
| `enteredAs` | text | `absolute` \| `percentage` — cosa ha digitato l'utente |
| `rawInput` | real | il valore digitato, prima della conversione |
| `note` | text nullable | |

⚑ **Perché si conserva `enteredAs` e `rawInput`**: se l'utente cambia la capacità del
serbatoio dopo aver inserito dieci misurazioni in percentuale, le quantità vanno ricalcolate.
Senza il valore grezzo, quelle misurazioni sarebbero perse. È il tipo di problema che si
scopre sei mesi dopo, quando i dati sono già sbagliati.

Vincolo: `UNIQUE(fuelSourceId, date)` — una misurazione al giorno; la seconda sovrascrive.

**`purchases`**: `id`, `fuelSourceId`, `date`, `quantity`, `totalCostCents`, `supplier`,
`note`.

**`calendar_reminders`**: `id`, `fuelSourceId`, `externalEventId`, `calculatedDate`,
`createdAt`, `lastSyncedAt`.

### F5.3 — `ConsumptionCalculator`

**`lib/domain/consumption.dart`**

```dart
enum EstimateQuality { insufficient, low, good }

@immutable
class ConsumptionEstimate {
  const ConsumptionEstimate({required this.dailyRate, required this.currentQuantity,
    required this.daysRemaining, required this.depletionDate, required this.reorderDate,
    required this.quality, required this.intervalsUsed, required this.spanDays});
  final double? dailyRate;              // unità/giorno; null se non calcolabile
  final double currentQuantity;
  final int? daysRemaining;
  final CivilDate? depletionDate;
  final CivilDate? reorderDate;
  final EstimateQuality quality;
  final int intervalsUsed;
  final int spanDays;
  bool get isActionable => quality != EstimateQuality.insufficient;
}

@immutable
class ConsumptionInterval {
  const ConsumptionInterval({required this.from, required this.to, required this.consumed, required this.days});
  final CivilDate from, to;
  final double consumed;
  final int days;
  double get rate;                      // consumed / days
}

class ConsumptionCalculator {
  const ConsumptionCalculator({this.maxIntervals = 5, this.minIntervalDays = 1});
  final int maxIntervals;
  final int minIntervalDays;

  List<ConsumptionInterval> buildIntervals(List<StockMeasurement> measurements);
  ConsumptionEstimate estimate({required List<StockMeasurement> measurements,
    required FuelSource source, CivilDate? today});
}
```

Algoritmo di `estimate`, nell'ordine:

1. Ordina le misurazioni per data crescente.
2. Costruisci gli intervalli consecutivi. **Scarta** gli intervalli in cui la quantità è
   **aumentata**: significa che c'è stato un rifornimento, e quel salto non è consumo.
3. Scarta gli intervalli più corti di `minIntervalDays`.
4. Prendi gli ultimi `maxIntervals` (5).
5. `dailyRate` = media **ponderata per la durata**:
   `sum(consumed_i) / sum(days_i)`, non la media delle `rate_i`.
6. `daysRemaining = floor(currentQuantity / dailyRate)`.
7. `depletionDate = oggi + daysRemaining`; `reorderDate = depletionDate - warningDays`.
8. Qualità: `insufficient` se meno di 1 intervallo valido o `spanDays < 3`;
   `low` se 1 intervallo o `spanDays < 10`; `good` altrimenti.

⚑ **Perché la media ponderata e non la media delle velocità**: un intervallo di due giorni e
uno di venti non pesano uguale. La media semplice delle velocità lascia che una misurazione
ravvicinata e rumorosa (l'utente ha contato male i sacchi) domini la stima. La ponderazione
per durata è anche più semplice da spiegare all'utente: "quanto hai consumato in tutto,
diviso i giorni".

⚑ **Perché una finestra di 5 intervalli**: la spec chiede 3–5. Il consumo di combustibile
dipende dalla temperatura esterna, che cambia nell'arco di settimane. Una finestra troppo
lunga porta con sé il consumo di ottobre dentro la previsione di gennaio.

☠ **Trappola**: se `dailyRate` è 0 o negativa (l'utente ha inserito due misurazioni uguali),
`daysRemaining` sarebbe infinito. Il calcolatore restituisce `dailyRate: null`,
`quality: insufficient` e la UI mostra "Servono altre misurazioni", mai "∞ giorni".

**Test obbligatori** (`test/domain/consumption_test.dart`):

| Caso | Dimostra |
|---|---|
| Tre misurazioni decrescenti a distanza regolare | Calcolo base |
| Rifornimento a metà serie | L'intervallo di salita è scartato |
| Due misurazioni identiche | `insufficient`, nessuna divisione per zero |
| Una sola misurazione | `insufficient` |
| Intervalli di durata molto diversa | La ponderazione è corretta |
| Otto intervalli | Solo gli ultimi 5 sono usati |
| Misurazioni nello stesso giorno | Il vincolo di unicità impedisce l'intervallo a zero giorni |
| Percentuale con `usableFraction` 0.8 | 43% di 1000 L → 344 L |

### F5.4 — Unità e conversioni

**`lib/domain/fuel_units.dart`**

```dart
enum FuelType { pellet, lpg, diesel, wood, biomass }

@immutable
class FuelUnit {
  const FuelUnit({required this.key, required this.label, required this.shortLabel,
    required this.decimals, required this.supportsWeight});
  final String key;            // 'bags', 'kg', 'pallets', 'liters', 'percent', 'quintals', 'steres', 'crates'
  final String label, shortLabel;
  final int decimals;
  final bool supportsWeight;
}

abstract final class FuelUnits {
  static const List<FuelUnit> all;
  static List<FuelUnit> forType(FuelType type);
  static FuelUnit byKey(String key);
}

class QuantityConverter {
  const QuantityConverter(this.source);
  final FuelSource source;
  double fromPercentage(double percent);      // percent/100 * capacity * usableFraction
  double toPercentage(double quantity);
  double? toKilograms(double quantity);       // null se non convertibile
  String format(double quantity, {bool withUnit = true});
}
```

Nell'MVP **non** si convertono steri in kg né cassette in quintali: la spec lo dice
esplicitamente. Il campo `unitWeightKg` è opzionale e serve solo a mostrare un dato in più.

⚑ **Perché non convertire la legna**: un metro stero di faggio e uno di abete pesano
diversamente, e l'umidità cambia tutto. Una conversione approssimativa presentata come esatta
produrrebbe stime false con un'aria di precisione.

### F5.5 — Configurazione della fonte

Wizard: nome → tipo di combustibile → unità (le opzioni cambiano in base al tipo) → capacità
serbatoio e frazione utile (solo `lpg`/`diesel`) → peso unitario (opzionale) → scorta
iniziale → costo (opzionale) → giorni di anticipo per il riordino (default 7).

### F5.6 — Dashboard

Per ogni fonte attiva, una card grande:

- `MicroProgressRing` con la percentuale residua rispetto all'ultimo rifornimento.
- Quantità residua, grande, nell'unità dell'utente.
- "Consumo medio: 0,82 sacchi/giorno".
- "**22 giorni di autonomia**".
- "Riordino consigliato: 3 ottobre".
- "Ultimo aggiornamento: 26 settembre" con un badge se sono passati più di 14 giorni.
- CTA a tutta larghezza: **"Aggiorna scorta"**.

Se `quality != good`, sotto la stima compare una riga esplicita: "Stima provvisoria, basata
su 1 intervallo". Se `insufficient`, la card mostra "Inserisci un'altra misurazione per
avere una stima" al posto dei giorni.

⚑ **Perché l'onestà sulla qualità della stima è in primo piano**: un'app che dice "22 giorni"
con la stessa sicurezza sia con due misurazioni sia con venti perde credibilità la prima volta
che sbaglia. Dichiarare l'incertezza la fa perdonare.

### F5.7 — Aggiornamento della scorta

È il gesto più frequente: bottom sheet con la data (default oggi), il campo quantità
preimpostato all'ultimo valore, e, per `lpg`/`diesel`, uno switch quantità/percentuale che
mostra in tempo reale la conversione. Salvataggio in un tocco.

### F5.8 — Notifiche

`lib/services/scorte_scheduler.dart` — due notifiche per fonte:

1. **Riordino**: alla `reorderDate`, alle 10:00, `inexactAllowWhileIdle`.
   "Il pellet potrebbe terminare tra circa 7 giorni. Ti restano circa 12 sacchi."
2. **Superamento**: 3 giorni dopo la `reorderDate`, se non ci sono nuove misurazioni.
   "Hai superato la data prevista di riordino del GPL."

Si ripianificano a ogni nuova misurazione. Se `quality == insufficient`, **nessuna notifica**:
avvisare sulla base di una stima non calcolabile è peggio che tacere.

### F5.9 — Storico e grafici (Pro)

Due grafici `fl_chart`: quantità residua nel tempo (con i rifornimenti marcati) e consumo
medio giornaliero per intervallo. Nel piano gratuito lo storico è limitato a **90 giorni**
(`FeatureKey.fullHistory`), il che è sufficiente per la stima ma non per confrontare le
stagioni.

### F5.10 — Google Calendar (Pro)

`lib/services/calendar_sync.dart` con `device_calendar`:

```dart
class CalendarSyncService {
  Future<Result<List<Calendar>>> availableCalendars();
  Future<Result<String>> upsertReorderEvent({required FuelSource source,
    required CivilDate date, required String calendarId, String? existingEventId});
  Future<Result<void>> deleteEvent(String calendarId, String eventId);
}
```

Evento: titolo "Riordinare pellet — Stufa soggiorno", giornata intera alla `reorderDate`,
descrizione "Autonomia stimata fino al 10 ottobre. Creato da Scorte Calore."
Se la stima cambia di più di 3 giorni, l'app **propone** l'aggiornamento dell'evento con una
notifica in-app, senza modificarlo di iniziativa.

⚑ **Perché proporre e non aggiornare in automatico**: un'app che sposta da sola gli eventi
nel calendario personale di qualcuno è invadente, e se l'utente ha condiviso il calendario
manda notifiche ad altre persone. Il consenso esplicito costa un tocco.

☠ **Trappola**: `device_calendar` richiede `READ_CALENDAR` e `WRITE_CALENDAR`, che Play
considera permessi sensibili e chiede di giustificare nella scheda. Vanno dichiarati solo in
Scorte Calore, mai nelle altre tre app, e la funzione deve essere completamente opzionale.

### F5.11 — Acquisti, costi, export

Registrazione degli acquisti con quantità, costo totale e fornitore; costo medio per unità;
spesa stagionale (1 ottobre – 31 marzo). CSV con misurazioni e acquisti. Backup completo.
Tutto sotto `FeatureKey.statistics` / `csvExport` / `backupRestore`.

```dart
const FeatureLimits scorteLimits = {
  FeatureKey.unlimitedEntities: FeatureLimit.count(freeMax: 1),   // fonti
  FeatureKey.fullHistory:       FeatureLimit.count(freeMax: 90),  // giorni
  FeatureKey.statistics:        FeatureLimit.locked(),
  FeatureKey.calendarSync:      FeatureLimit.locked(),
  FeatureKey.csvExport:         FeatureLimit.locked(),
  FeatureKey.backupRestore:     FeatureLimit.locked(),
};
```

### F5.12 — Test · F5.13 — Rifinitura · F5.14 — Atlante · F5.15 — Rituale (branch `v6.0.0`)

---

## F6 — Film Tracker

**Obiettivo della fase**: l'app con la maggiore identità di prodotto delle quattro. Un
diario visivo dei rullini, in cui la scheda di ogni rullino si riconosce a colpo d'occhio
dalla sua anteprima e non dal numero.

Va per ultima perché è la più costosa (gestione immagini, quattro entità collegate, tema
scuro curato) e perché a quel punto `micro_core` e la catena di billing sono già collaudate
da tre app.

### F6.1 — Bootstrap

Applicare **§8.T**. `appId: 'film_tracker'`, `proSku: 'filmtracker_pro_lifetime'`,
`seedColor: Color(0xFFE0A458)`, `fontFamily: 'Inter'`, `displayFontFamily: 'Fraunces'`,
**`defaultBrightness: Brightness.dark`**.
Dipendenze aggiuntive: `image_picker`, `image`, `qr_flutter`, `pdf`, `printing`, `fl_chart`.

⚑ **Perché il tema scuro di default**: le fotografie su fondo chiaro perdono contrasto e
l'occhio le confronta con il bianco della pagina invece che tra loro. Tutte le app di
fotografia serie partono scure. Il tema chiaro resta disponibile e curato, ma non è il
default.

### F6.2 — Data layer

**`cameras`**

| Colonna | Tipo | Note |
|---|---|---|
| `id` | int | |
| `manufacturer` | text | "Olympus" |
| `model` | text | "OM-2" |
| `format` | text | `35mm` \| `120` \| `110` \| `large` \| `other` |
| `note` | text nullable | |
| `active` | bool | |
| `sortOrder` | int | |

**`film_stocks`** — catalogo locale, precaricato al primo avvio.

| Colonna | Tipo | Note |
|---|---|---|
| `id` | int | |
| `brand` | text | "Kodak" |
| `name` | text | "Gold 200" |
| `iso` | int | 200 |
| `process` | text | `C-41` \| `E-6` \| `BW` \| `ECN-2` \| `other` |
| `format` | text | |
| `isCustom` | bool | true per le pellicole aggiunte dall'utente |

Precaricate: Kodak Gold 200, Portra 160, Portra 400, Portra 800, Ultramax 400, ColorPlus 200,
Tri-X 400, T-Max 100, T-Max 400, Ektar 100; Ilford HP5+, FP4+, Delta 100, Delta 400, XP2
Super; Fomapan 100, 200, 400; Fujifilm C200, Superia X-TRA 400, Velvia 50, Provia 100F;
Cinestill 800T, 400D; Lomography Color 400. Più la voce sempre presente **"Pellicola
personalizzata"**.

⚑ **Perché un catalogo locale e non remoto**: la spec lo chiede. Venticinque emulsioni
coprono il 95% dell'uso reale, e chi usa la ventiseiesima è esattamente il tipo di utente che
apprezza poterla aggiungere a mano. Un database remoto costerebbe un backend, una
sincronizzazione e una dipendenza di rete per un guadagno marginale.

**`film_rolls`** — l'entità principale.

| Colonna | Tipo | Vincoli | Note |
|---|---|---|---|
| `id` | int | | |
| `sequenceNumber` | int | UNIQUE | il "#17" della spec, assegnato automaticamente |
| `filmStockId` | int nullable | references, setNull | |
| `filmName` | text | | denormalizzato: sopravvive alla cancellazione dello stock |
| `format` | text | | |
| `nominalIso` | int | | |
| `exposedIso` | int | | push/pull: se diverso da `nominalIso` la UI lo evidenzia |
| `cameraId` | int nullable | references, setNull | |
| `loadedAt` | text nullable | `YYYY-MM-DD` | |
| `finishedAt` | text nullable | `YYYY-MM-DD` | |
| `frames` | int | | 36, 24, 12, 16… |
| `title` | text nullable | | "Praga — settembre 2026" |
| `note` | text nullable | | |
| `status` | text | | vedi F6.3 |
| `costCents` | int nullable | | costo del rullino |
| `coverImageId` | int nullable | references roll_images, setNull | |
| `createdAt` | int | | |

⚑ **Perché `filmName` è denormalizzato**: se l'utente cancella una pellicola personalizzata
dal catalogo, i rullini scattati con quella pellicola devono continuare a dire cosa erano. Un
archivio storico che perde l'informazione quando si riordina il catalogo è inutilizzabile.

**`developments`**

| Colonna | Tipo | Note |
|---|---|---|
| `id` | int | |
| `filmRollId` | int | references, cascade |
| `laboratory` | text | |
| `submittedAt` | text nullable | `YYYY-MM-DD` |
| `returnedAt` | text nullable | |
| `developmentCostCents` | int nullable | |
| `scanCostCents` | int nullable | |
| `process` | text nullable | C-41, E-6, BW… |
| `selfDeveloped` | bool | sviluppo in casa |
| `note` | text nullable | |

**`print_orders`**

| Colonna | Tipo | Note |
|---|---|---|
| `id` | int | |
| `filmRollId` | int | references, cascade |
| `laboratory` | text | |
| `submittedAt` / `returnedAt` | text nullable | |
| `format` | text nullable | "10×15" |
| `numberOfPrints` | int nullable | |
| `costCents` | int nullable | |
| `note` | text nullable | |

**`roll_images`**

| Colonna | Tipo | Note |
|---|---|---|
| `id` | int | |
| `filmRollId` | int | references, cascade |
| `path` / `thumbPath` | text | relativi (F1.11) |
| `width` / `height` / `bytes` | int | |
| `kind` | text | `contactSheet` \| `print` \| `scan` \| `other` |
| `sortOrder` | int | |
| `createdAt` | int | |

⚑ **Perché sviluppo e stampa sono tabelle separate e non colonne del rullino**: la spec lo
impone come scelta di design, ed è giusta. Un rullino può avere uno sviluppo e **tre** ordini
di stampa a mesi di distanza, da laboratori diversi. Mettere i campi sul rullino renderebbe
impossibile il caso più caratterizzante dell'app.

☠ **Trappola**: la cancellazione di un rullino deve cancellare le sue immagini **dal
filesystem**, non solo dal database. Il DAO espone
`Future<List<String>> deleteRollAndCollectImagePaths(int id)` e il chiamante passa i percorsi
a `ImageStore.delete`. In più, `ImageStore.pruneOrphans` gira una volta al mese.

### F6.3 — Macchina a stati del rullino

**`lib/domain/roll_status.dart`**

```dart
enum RollStatus { loaded, exposed, sentForDevelopment, developed, printed, archived }

class RollStatusMachine {
  const RollStatusMachine();

  static const Map<RollStatus, Set<RollStatus>> allowedTransitions = {
    RollStatus.loaded:             {RollStatus.exposed, RollStatus.archived},
    RollStatus.exposed:            {RollStatus.sentForDevelopment, RollStatus.developed, RollStatus.archived},
    RollStatus.sentForDevelopment: {RollStatus.developed, RollStatus.exposed, RollStatus.archived},
    RollStatus.developed:          {RollStatus.printed, RollStatus.archived},
    RollStatus.printed:            {RollStatus.archived, RollStatus.developed},
    RollStatus.archived:           {RollStatus.developed, RollStatus.printed},
  };

  bool canTransition(RollStatus from, RollStatus to);
  RollStatus suggestFrom({required FilmRoll roll, Development? development, required List<PrintOrder> prints});
  String labelFor(RollStatus status);
  RollSection sectionFor(RollStatus status);
}

enum RollSection { inCamera, atLab, archive }
```

`suggestFrom` **suggerisce**, non impone: se esiste uno sviluppo con `returnedAt`, lo stato
suggerito è `developed`; se esiste una stampa con `returnedAt`, `printed`; se lo sviluppo ha
`submittedAt` ma non `returnedAt`, `sentForDevelopment`. L'utente può sempre forzare lo stato
manualmente, perché la realtà è più disordinata del modello.

⚑ **Perché `printed → developed` è una transizione ammessa**: la stampa è un evento separato
e ripetibile. Un rullino stampato che viene ristampato mesi dopo non deve essere bloccato in
uno stato terminale. La macchina a stati serve a guidare la UI, non a punire l'utente.

Mappatura alle tre sezioni della home: `loaded`/`exposed` → **In camera**;
`sentForDevelopment` → **In laboratorio**; `developed`/`printed`/`archived` → **Archivio**.

### F6.4 — Catalogo pellicole

Lista con ricerca, raggruppata per marca. Creazione di una pellicola personalizzata (marca,
nome, ISO, processo, formato). Selezione rapida dal form del rullino con i cinque stock più
usati in cima.

### F6.5 — Macchine fotografiche

CRUD semplice, con conteggio dei rullini per macchina. La spec avverte esplicitamente: **non
deve diventare un'app per collezionisti**. Quindi nessun campo per numero di serie, anno,
valore, obiettivi. Solo produttore, modello, formato, nota.

Piano gratuito: **una** macchina (`FeatureKey.secondaryEntities`).

### F6.6 — Rullini

- Lista e dettaglio. La scheda di dettaglio è una **timeline verticale**: caricato →
  terminato → consegnato → sviluppato → stampato, con le date e i costi accanto a ciascun
  evento.
- Creazione: pellicola → macchina → ISO esposto (preimpostato al nominale) → fotogrammi →
  data di caricamento. `sequenceNumber` assegnato automaticamente come `max + 1`.
- "Rullino terminato": un tocco che imposta `finishedAt` e passa a `exposed`.

⚑ **Perché la timeline verticale e non una scheda a campi**: la spec dice "ogni rullino
diventa una scheda cronologica e visiva". La cronologia è la struttura del dato; una griglia
di campi la nasconderebbe.

### F6.7 — Sviluppo e stampa

Due form separate, raggiungibili dal dettaglio del rullino. Ogni rullino ha **al massimo uno**
sviluppo e **N** ordini di stampa. Autocompletamento del laboratorio dai nomi già usati.
Costi in `Money`.

### F6.8 — Home a tre sezioni

1. **In camera** — card per rullino: nome pellicola, macchina, "18 / 36" scattati (se
   l'utente tiene il conto), giorni dal caricamento.
2. **Waiting for lab** — "Ilford HP5 — consegnato 5 giorni fa", ordinati per attesa
   decrescente.
3. **Archive** — griglia di card con la **thumbnail** (contact sheet o copertina), titolo e
   periodo. È la sezione che dà identità all'app.

Se l'archivio è vuoto, la griglia mostra placeholder eleganti con la striscia di pellicola,
non un rettangolo grigio.

### F6.9 — Photo overview (Pro)

`lib/features/roll_images/`:

- Aggiunta da fotocamera (fotografa il foglio di provini o le stampe) o da galleria, con
  selezione multipla.
- Ridimensionamento a 1600 px lato lungo e miniatura a 400 px, via `ImageStore` (F1.11).
- Griglia riordinabile, scelta della copertina, visualizzatore a schermo intero con zoom.
- Indicatore dello spazio occupato nelle impostazioni, con "libera spazio" che rigenera le
  miniature ed elimina gli orfani.

⚑ **Perché si copia sempre l'immagine nell'app invece di tenere un riferimento alla
galleria**: su Android un URI di `MediaStore` può diventare invalido (l'utente cancella la
foto, sposta la scheda SD, revoca il permesso). Un archivio storico che perde le anteprime
è rotto. Il costo è lo spazio, mitigato dal ridimensionamento: 1600 px in JPEG qualità 82
sono circa 300 KB, quindi 100 rullini con 3 immagini ciascuno stanno sotto i 100 MB.

☠ **Trappola**: l'import di dieci immagini da 12 megapixel su un telefono di fascia bassa
blocca l'interfaccia per diversi secondi. Il ridimensionamento va fatto in un `Isolate`
(`compute`), con una barra di avanzamento e la possibilità di annullare.

### F6.10 — Statistiche (Pro)

Per anno solare: numero di rullini, fotogrammi potenziali, spesa divisa in rullini,
sviluppo, scansioni, stampe, totale. Indicatori: costo medio per rullino, costo medio per
fotogramma, laboratorio più usato, emulsione più usata, macchina più usata. Grafico a barre
dei rullini per mese.

☠ **Trappola**: "costo medio per fotogramma" va calcolato sui fotogrammi **nominali** del
rullino, e la UI deve dire che è una stima: non tutti i fotogrammi vengono scattati o
riescono. Presentarlo come dato esatto è falso.

### F6.11 — Export e PDF (Pro)

- CSV dei rullini con tutti i campi e i costi.
- **PDF di riepilogo** con `PdfReportBuilder` (F1.11): copertina con l'anno e i totali, una
  pagina per rullino con la timeline, i costi e la griglia delle immagini.
- Backup completo con immagini (formato ZIP, F1.11).

⚑ **Perché il PDF è una funzione Pro sensata qui e non nelle altre app**: il pubblico di
Film Tracker è lo stesso che stampa, archivia e tiene quaderni. Un riepilogo annuale
stampabile è un oggetto che quel pubblico desidera davvero.

### F6.12 — QR del rullino

Dal dettaglio, "Genera QR": un `qr_flutter` che codifica
`filmtracker://roll/<sequenceNumber>` più il nome della pellicola in chiaro sotto. L'utente
lo stampa o lo fotografa e lo attacca al contenitore del rullino. La scansione dal lettore
di sistema apre l'app sul rullino (deep link go_router).

Nessun laboratorio deve supportare nulla: è un'etichetta per non confondere i rullini.
Disponibile anche nel piano gratuito, perché è la funzione più raccontabile dell'app e serve
a farla conoscere.

### F6.13 — Test

Oltre allo standard: tutte le transizioni della macchina a stati (matrice 6×6), `suggestFrom`
su otto combinazioni di sviluppo/stampa, aggregazioni delle statistiche su un dataset noto,
`ImageStore` (ridimensionamento, miniature, `pruneOrphans`), round-trip del backup con
immagini.

### F6.14 — Rifinitura

Cura particolare: transizioni tra griglia e dettaglio con `Hero`, caricamento progressivo
delle miniature, palette scura calibrata sul contrasto delle foto, tipografia `Fraunces` sui
titoli dei rullini.

### F6.15 — `apps/film_tracker/codebase_reference.md`

### F6.16 — Rituale di fine fase F6

Eseguire §6. Branch previsto: `v7.0.0`.

---

## F7 — Hardening trasversale e preparazione allo store

**Obiettivo della fase**: le quattro app esistono e funzionano; questa fase le rende
pubblicabili. È la fase che si tende a saltare e che determina se le app vengono approvate,
trovate e installate.

### F7.1 — Localizzazione

Revisione di tutti gli ARB: nessuna chiave inutilizzata, nessuna stringa mancante in `en`,
plurali corretti (`{count, plural, ...}`), date e numeri sempre via `intl` con il locale
corrente. Test: avviare ogni app con `--locale=en` e scorrere ogni schermata.

☠ **Trappola**: le stringhe inglesi sono in media più lunghe del 15% delle italiane. I
pulsanti e le card che stanno larghe in italiano vanno in overflow in inglese. Va verificato
a mano, schermata per schermata.

### F7.2 — Accessibilità

- Contrasto AA (4.5:1) su tutto il testo, in light e dark, verificato sui colori generati dal
  seed e su quelli scelti dall'utente per i tipi di rifiuto.
- Testo scalabile fino al 200% senza overflow.
- `Semantics` su ogni elemento interattivo; etichette sensate per TalkBack (non "Icona").
- Area di tocco minima 48×48 dp.
- Nessuna informazione veicolata dal solo colore: il livello di anzianità del freezer ha
  anche un'icona, non solo un pallino colorato.

### F7.3 — Performance

- Avvio a freddo sotto **1,5 s** su un dispositivo di fascia media.
- Nessun frame oltre i 16 ms nello scorrimento delle liste principali (verifica con
  `flutter run --profile` e DevTools).
- `flutter build appbundle --analyze-size` per ogni app; obiettivo sotto i **20 MB** di
  download.
- R8 attivo, `minifyEnabled` e `shrinkResources` in release, con le regole ProGuard richieste
  da Drift e `flutter_local_notifications`.

☠ **Trappola**: R8 rimuove classi usate solo per riflessione. `sqlite3_flutter_libs` e
`flutter_local_notifications` richiedono regole `-keep` esplicite. Il sintomo è un crash
**solo in release**, tipicamente al primo avvio, che non si riproduce in debug. Le regole
vanno in `android/app/proguard-rules.pro` e il build di release va provato **su un
dispositivo reale** prima del caricamento.

### F7.4 — Matrice di QA manuale

Da eseguire su almeno: un dispositivo Android 10, uno Android 13, uno Android 15; uno schermo
piccolo (≤ 5,5") e uno grande; una ROM cinese (Xiaomi/Oppo) per le notifiche.

| Scenario | Tutte le app |
|---|---|
| Primo avvio e onboarding completo | ✓ |
| Rotazione dello schermo in ogni schermata | ✓ |
| Modalità aereo: nessun blocco, nessun errore visibile | ✓ |
| Permesso notifiche negato: l'app funziona, avviso discreto | ✓ |
| Riavvio del telefono: le notifiche restano pianificate | ✓ |
| Cambio di fuso orario e passaggio ora legale | ✓ |
| Testo di sistema al 200% | ✓ |
| Dark mode e light mode | ✓ |
| Disinstalla e reinstalla: ripristino dell'acquisto | ✓ |
| Backup, disinstalla, reinstalla, ripristina | ✓ |
| Riempimento con 500 record: la lista resta fluida | ✓ |

### F7.5 — Compliance Play

- **Sezione Sicurezza dei dati**: per tutte e quattro, "nessun dato raccolto" tranne
  l'`install_id` inviato al License Server, che va dichiarato come identificatore del
  dispositivo, con finalità "gestione degli acquisti", non condiviso, non usato per il
  tracciamento.
- **Permessi**: solo quelli usati. `SCHEDULE_EXACT_ALARM` solo in TrashCan, con la
  giustificazione pronta. `READ_CALENDAR`/`WRITE_CALENDAR` solo in Scorte Calore.
  `RECORD_AUDIO` solo in Full Freezer (voice input), dichiarato come opzionale.
- **Contenuti**: classificazione per tutti, nessuna pubblicità, nessun contenuto generato
  dagli utenti.
- **Pagina "Elimina i miei dati"**: obbligatoria se si raccoglie un identificatore. Serve un
  endpoint o una pagina che spieghi come chiedere la cancellazione. Si implementa come
  `GET /privacy/delete` sul License Server, con un form che accetta l'`install_id`
  (visibile nelle impostazioni di ogni app) e cancella install ed entitlement.

☠ **Trappola**: le app che dichiarano "nessun dato raccolto" e poi inviano un identificatore
a un server vengono sospese. La dichiarazione deve corrispondere al comportamento reale. Se
si preferisce evitare del tutto la dichiarazione, si può rendere la verifica server
completamente opzionale e disattivata di default: **è una decisione da prendere in F7.5**,
non da rimandare.

### F7.6 — Asset dello store

Per ciascuna app: icona 512×512, feature graphic 1024×500, almeno 4 screenshot per telefono
(1080×1920 o superiore), titolo (≤ 30 caratteri), descrizione breve (≤ 80), descrizione
completa (≤ 4000), in italiano e inglese.

Titoli proposti:

| App | Titolo Play (it) | Descrizione breve |
|---|---|---|
| TrashCan | TrashCan — Raccolta differenziata | Il tuo calendario della raccolta. Funziona ovunque, senza account. |
| Full Freezer | Full Freezer — Inventario freezer | Cosa c'è nel freezer e da quanto tempo. Il più vecchio per primo. |
| Scorte Calore | Scorte Calore — Pellet e GPL | Quanto combustibile resta e quando riordinarlo. |
| Film Tracker | Film Tracker — Diario rullini | Il diario dei tuoi rullini analogici, con le anteprime. |

⚑ **Perché il nome del problema nel titolo**: la ricerca in Play è quasi solo per parola
chiave. "TrashCan" da solo non viene trovato da chi cerca "calendario raccolta
differenziata".

### F7.7 — Informative privacy

Quattro pagine HTML statiche in `docs/privacy/`, pubblicate a un URL raggiungibile (sul
License Server o su un hosting statico). Devono dire con precisione: quali dati restano sul
dispositivo (tutti quelli dell'app), quale identificatore viene inviato e perché, che non ci
sono analytics, come chiedere la cancellazione.

### F7.8 — Verifica finale degli atlanti

`tool/verify_atlas.ps1` su tutti e sei i progetti. Zero differenze.

### F7.9 — Rituale di fine fase F7 (branch `v8.0.0`)

---

## F8 — Deploy e pubblicazione

**Questa fase si affronta per ultima**, come richiesto. È scritta adesso perché le decisioni
prese prima (porta interna, bind su localhost, volume dei dati, backup) dipendono da come
finirà.

### F8.1 — Accesso SSH a `clawserver` ✅ (chiusa il 2026-09-09)

L'accesso funziona. Il `Permission denied (publickey)` iniziale era dovuto alla passphrase
sulla chiave `~/.ssh/clawserver_ed25519`, caricata nell'ssh-agent di **Windows**: l'ssh di
Git Bash non vede quell'agent.

**Regola operativa**: tutti i comandi verso `clawserver` si danno con l'`ssh` di Windows,
cioè dallo strumento PowerShell. `ssh clawserver 'hostname'` risponde `vps-3e7d932a`.

### F8.2 — Ricognizione del server (svolta il 2026-09-09, da riverificare prima del deploy)

Fotografia attuale, da riconfermare in F8.3 perché il server è vivo e può cambiare:

| Voce | Valore |
|---|---|
| Sistema | Ubuntu 24.04.4 LTS, kernel 6.8, 4 core, 7,6 GB RAM, nessuna swap |
| Disco | 72 GB totali, 45 GB liberi |
| Docker | 29.3.0 + Compose v5.1.0, attivo e abilitato, **nessun container in esecuzione** |
| Reverse proxy | nginx, 3 vhost in `/etc/nginx/sites-enabled/`: `hesclaw.ovh`, `wa-webhook.hesclaw.ovh`, `flamingnews.it` |
| TLS | Certbot, certificati in `/etc/letsencrypt/live/` per i tre domini |
| Altri servizi | OpenClaw gateway (18789/18791/18792 su localhost), wa-webhook Node su 3100, MariaDB 10.11, Redis, tutti su localhost |
| Firewall | ufw attivo: 22, 80, 443 aperte; **6080 chiusa il 2026-09-09** |
| Porta 8087 | **libera**, confermata per il License Server |
| sudo | senza password per l'utente `ubuntu` |

**Bonifica già eseguita** (2026-09-09): rimossi VNC, noVNC, websockify, il desktop XFCE, i
residui GNOME, Xorg e CUPS. 421 pacchetti in meno, circa 300 MB di RAM liberati, porta 6080
chiusa. Le 73 librerie di sistema richieste da Chromium/Playwright sono state marcate
`apt-mark manual` **prima** delle purghe, e il funzionamento di Chromium è stato verificato
dopo.

☠ **Trappola disinnescata**: OpenClaw usa Playwright con Chromium, che dipende da librerie
GTK/X11 installate come dipendenze del desktop. Un `apt purge --autoremove` dei pacchetti
desktop le avrebbe portate via, rompendo l'automazione browser di OpenClaw senza alcun
messaggio d'errore evidente. Il metodo da riusare: risolvere le librerie del binario con
`ldd`, mapparle sui pacchetti con `dpkg -S`, marcarle `manual`, simulare con `apt-get -s` e
verificare che l'intersezione con la lista di rimozione sia vuota.

Da raccogliere e scrivere in `server/codebase_reference.md`:

- Distribuzione e versione, RAM, disco libero.
- Docker presente e versione; container già in esecuzione (OpenClaw e dipendenze).
- Reverse proxy in uso (Nginx, Caddy, Traefik) e dove sta la configurazione.
- Porte già occupate: conferma o cambio della 8087.
- Firewall attivo e regole.
- Presenza di certbot o gestione automatica dei certificati.
- Dominio o sottodominio disponibile per il License Server.

☠ **Regola non negoziabile**: non si tocca nulla di OpenClaw. Nessun aggiornamento di
sistema, nessun riavvio di container altrui, nessuna modifica alla configurazione esistente
del proxy oltre all'aggiunta di un blocco nuovo. Prima di ogni modifica al proxy, copia di
backup del file con data nel nome.

### F8.3 — Deploy del License Server

1. `git clone` della repo sul server in `/opt/microapps` (o `rsync` della sola cartella
   `server/`).
2. `.env` di produzione, con segreti generati sul server e **mai** committati.
3. `docker compose up -d --build`.
4. Verifica `curl http://127.0.0.1:8087/healthz`.
5. `npm run create-admin` dentro il container per il primo utente.

### F8.4 — TLS e reverse proxy

Sottodominio dedicato (per esempio `licenses.varitest.ovh`), certificato Let's Encrypt,
blocco di proxy verso `127.0.0.1:8087`, HSTS, e **restrizione del pannello admin**: `/admin`
accessibile solo da IP noti o dietro autenticazione aggiuntiva del proxy.

⚑ **Perché una restrizione in più sul pannello**: il pannello mostra tutti gli acquisti e
permette di concedere licenze. È l'unica superficie ad alto valore del server. La password
argon2 è buona, ma un secondo livello costa cinque righe di configurazione.

### F8.5 — Backup e ripristino

Cron giornaliero che esegue `runBackup()`, copia fuori dal server (per esempio verso una
seconda macchina o uno storage a oggetti), e **una prova di ripristino effettiva**: si
ripristina il backup in un container di prova e si verifica che il pannello mostri i dati.

☠ **Trappola**: un backup mai ripristinato non è un backup. La prova va fatta adesso e
ripetuta ogni sei mesi.

### F8.6 — Service account Google Play

1. In Google Cloud, creare un progetto e un service account, generare la chiave JSON.
2. In Play Console → Utenti e autorizzazioni, invitare il service account e concedere,
   **per ciascuna delle quattro app**, i permessi di visualizzazione dei dati finanziari e di
   gestione degli ordini.
3. Copiare il JSON sul server in `/opt/microapps/secrets/play-sa.json`, permessi `600`,
   e valorizzare `GOOGLE_SERVICE_ACCOUNT_JSON`.
4. Verificare con una vera chiamata: `/healthz` deve riportare `playConfigured: true`, e una
   verifica di un token di test deve rispondere correttamente.

☠ **Trappola**: la propagazione dei permessi del service account può richiedere fino a 24
ore. Un 401 subito dopo l'invito non significa che la configurazione sia sbagliata.

### F8.7 — Pub/Sub per le RTDN

1. Creare un topic Pub/Sub e una sottoscrizione **push** verso
   `https://licenses.varitest.ovh/v1/rtdn?secret=<RTDN_SHARED_SECRET>`.
2. Dare al service account di Google Play il permesso di pubblicare sul topic.
3. In Play Console, per ogni app, impostare l'argomento nelle notifiche in tempo reale.
4. Verificare con un acquisto e un rimborso di test che gli eventi arrivino e che
   l'entitlement passi a `revoked`.

### F8.8 — Closed testing

Caricare le quattro app su un canale **chiuso**, con almeno 12 tester reali, e lasciarle in
test per **14 giorni**: è il requisito che Google applica agli account sviluppatore
personali creati dal novembre 2023 prima di poter pubblicare in produzione.

☠ **Trappola che sposta il calendario di due settimane**: questo requisito è la ragione per
cui la data di pubblicazione non dipende dalla fine dello sviluppo. Va avviato **appena la
prima app è stabile**, in parallelo allo sviluppo delle altre, non alla fine. Se l'account
sviluppatore è di tipo organizzazione, il requisito non si applica: **va verificato in F3.12**.

### F8.9 — Produzione

Rilascio graduale (20% → 50% → 100%), monitoraggio di Android Vitals e delle recensioni per
la prima settimana, e una versione correttiva pronta.

### F8.10 — Rituale di fine fase F8 (branch `v9.0.0`)

---

## §9 — Debito tecnico e rinvii consapevoli

Elenco vivo. Ogni voce ha il motivo del rinvio e quando va affrontata.

| ID | Voce | Perché è rinviata | Quando affrontarla |
|---|---|---|---|
| DT-01 | Nessun supporto iOS | Nessun account Apple, mercato secondario per queste app | Se una delle app supera 5.000 installazioni |
| DT-02 | Barcode in Full Freezer | Richiede un database prodotti; l'MVP funziona senza | Dopo il lancio, se richiesto dagli utenti |
| DT-03 | OCR del calendario cartaceo in TrashCan | Costo alto, accuratezza incerta, sarebbe una delusione se sbaglia | Come funzione Pro futura, con un modello on-device |
| DT-04 | Template calendari per Comune (TrashCan) | Richiede un repository condiviso e curatela | Solo se il volume lo giustifica |
| DT-05 | Conversioni sofisticate per la legna | Dipende da essenza e umidità: una stima sarebbe falsa | Probabilmente mai |
| DT-06 | Crash reporting | Vedi ADR-016 | Dopo il lancio, con consenso esplicito |
| DT-07 | Test golden completi | Costosi e fragili durante il refactoring visivo | Due per app in F3–F6, estendere in F7 |
| DT-08 | Sincronizzazione dati tra dispositivi | Contraddice "nessun account" | Non prevista |
| DT-09 | Galleria dei componenti (`packages/micro_core/example/`) | I componenti sono in uso reale dalla prima app, che è una verifica migliore di una galleria isolata | Prima dei golden test di F7 |
| DT-10 | `PdfReportBuilder` | Lo usa solo Film Tracker. Costruirlo ora significherebbe scriverlo senza sapere che forma deve avere il riepilogo | F6.11, insieme al riepilogo annuale |

---

## §10 — Rischi noti e cosa fare

| Rischio | Probabilità | Impatto | Mitigazione |
|---|---|---|---|
| Accesso a `clawserver` non recuperabile | media | alto sul server, **nullo sulle app** | Le app funzionano senza server (ADR-007). In alternativa, un altro VPS |
| I 14 giorni di closed testing bloccano la pubblicazione | alta | alto sul calendario | Avviare il test chiuso subito dopo F3, in parallelo |
| Play rifiuta `SCHEDULE_EXACT_ALARM` | media | medio su TrashCan | Fallback inesatto già previsto; l'app funziona senza |
| Dichiarazione dati incoerente con l'invio dell'`install_id` | media | alto (sospensione) | F7.5: dichiarare correttamente o rendere il server opt-in |
| Crash solo in release per R8 | alta se non si verifica | alto | F7.3: build di release provato su dispositivo reale prima di ogni upload |
| Perdita del keystore | bassa | catastrofico | F0.6: due backup in luoghi diversi |
| Migrazione Drift che cancella i dati | media | alto | F3.2.6 e omologhe: test di migrazione dal primo giorno |
| Prezzi troppo bassi per il valore | media | medio | Prezzi rialzabili senza penalizzare chi ha comprato |

---

## §11 — Decisioni ancora aperte (da confermare)

Elencate qui perché un piano onesto distingue ciò che è deciso da ciò che è stato assunto.

1. ~~**`applicationId`**~~ — **deciso il 2026-09-10**: `com.smp.<app>`. Vedi §1.1. Nessun
   AAB era ancora stato caricato su Play, quindi il cambio dal precedente `ovh.varitest.` non
   è costato nulla.
2. **Prezzi di lancio**: assunta la cifra bassa delle due indicate in ogni spec. Da
   confermare prima di creare i prodotti in Play Console.
3. **Dominio del License Server**: **dominio nuovo, ancora da registrare**. L'ipotesi
   iniziale di un sottodominio esistente è caduta: il committente fornirà il dominio quando
   sarà disponibile. Fino ad allora, in F8.4 si usa un sottodominio provvisorio e la
   configurazione nginx resta parametrica sul `server_name`.
4. **Tipo di account Play** (personale o organizzazione): determina se si applicano i 14
   giorni di closed testing. Da verificare in F3.12.
5. **Verifica server obbligatoria o opt-in**: incide sulla dichiarazione "Sicurezza dei
   dati". Da decidere in F7.5.
6. **Nome pubblico delle app**: i titoli proposti in F7.6 sono una proposta, non una
   decisione.

---

## §12 — Glossario

| Termine | Significato in questo progetto |
|---|---|
| **Entitlement** | Il diritto di un'installazione a usare le funzioni Pro di una specifica app |
| **`install_id`** | UUID generato dall'app al primo avvio; identifica l'installazione, non la persona |
| **`purchase_token`** | Stringa opaca generata da Google Play che identifica univocamente un acquisto; è l'unica chiave verificabile |
| **SKU** | Identificatore del prodotto in-app in Play Console |
| **RTDN** | Real-time Developer Notifications: messaggi Pub/Sub inviati da Google agli sviluppatori su rimborsi e cambi di stato |
| **Occorrenza** | Una singola raccolta in una data specifica, generata da una regola ricorrente (TrashCan) |
| **Data civile** | Data senza ora né fuso, come "14 marzo" (ADR-008) |
| **Atlante** | Il `codebase_reference.md` di un progetto |
| **Rituale di fine fase** | La procedura obbligatoria di §6 |

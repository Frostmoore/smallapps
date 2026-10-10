# develop_microapps.md — Specsheet operativa di sviluppo

> **Progetto**: MicroApps — quattro app Flutter monetizzate una tantum, su **Google Play
> e App Store**, più un server di licenze/entitlement self-hosted.
> **Repository app** (remote `origin`): `https://git.home.varitest.ovh/smp-webmaster/microapps.git`
> **Mirror pubblico app** (remote `github`): `https://github.com/Frostmoore/smallapps.git`
> **Repository server** (**solo Gitea**, remote `origin`): `https://git.home.varitest.ovh/smp-webmaster/microapps-server.git`
> **Documento creato**: 2026-09-09
> **Stato**: **F0, F1, F2 e F3 chiuse** (tranne F3.12, bloccata su Play Console). **F9
> (porting iOS) aperta il 2026-10-04**: TrashCan compila, parte e passa il test di
> integrazione sul simulatore. 236 test verdi: 127 in TrashCan, 109 in micro_core. Vedi §7.

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



### §1.6 Le app successive: dieci idee del proprietario (aggiunte il 2026-10-08)

Il 2026-10-08 il proprietario ha consegnato un elenco di idee selezionate
(`docs/specs/idee-2026-10.md`, copia versionata di `smp_microapps_idee.md` dal suo Desktop) e ha
deciso: **andranno sviluppate anche queste.** Ognuna prende una fase propria (F10–F19 in §7),
secondo §1.5. Le spec di prodotto sono, per ora, le poche righe di quel file: **la prima
sottofase di ogni app (Fx.0) e' scrivere con il proprietario le decisioni di partenza e la
specsheet completa in §8**, come per F3–F6.

| Fase | App | Problema risolto | applicationId (provvisorio) | Cosa pesa davvero |
|---|---|---|---|---|
| F10 | **Boomerang** (ex «Te l'ho prestato», nome del 2026-10-11) | Chi ha cosa e da quanto: oggetti prestati e presi in prestito | `com.smp.prestato` | Nulla di critico: dati locali, notifiche di promemoria (gia' in `micro_core`) |
| F11 | **Pin Drop** (ex «Dove l'ho lasciato?», nome del 2026-10-11) | Dove ho lasciato auto, bici, ombrellone, armadietto: posizione + foto + nota | `com.smp.dovelholasciato` | Posizione **in primo piano** (permesso), mappa o bussola senza servizi a pagamento, foto (come Film Tracker) |
| F12 | **Spending Review** (ex «Quanto sto spendendo?», nome del 2026-10-10) | Il totale del carrello mentre si fa la spesa, contro un budget | `com.smp.quantospendo` | Inserimento rapidissimo (tastierino, voce come Full Freezer); nessun permesso |
| F13 | **Fair Share** (ex «Quanto dividiamo?», nome del 2026-10-11) | Dividere un conto: in parti uguali, a quote, per voce, con sconti e mancia | `com.smp.quantodividiamo` | Aritmetica in centesimi con arrotondamenti onesti (`Money`); lettura dello scontrino = OCR (§1.4: fuori dall'MVP salvo decisione) |
| F14 | **Geo Note** (ex «Ricordamelo qui», nome del 2026-10-11) | Promemoria quando si arriva o si esce da un luogo | `com.smp.ricordamelo` | **Geofencing**: posizione **in background**, permesso sensibile su Play (dichiarazione e video) e su iOS; limiti dei sistemi sul numero di aree |
| F15 | ~~**Quanti sono?**~~ **ANNULLATA il 2026-10-11** | Contare oggetti ripetuti con la fotocamera | `com.smp.quantisono` | **Visione on-device** (sperimentale per il proprietario stesso); §1.4 esclude l'AI dall'MVP: serve una decisione |
| F16 | **TLDR** (ex «Riassumilo», nome del 2026-10-11) | Riassunto breve di un link o testo condiviso (Share Sheet) | `com.smp.riassumilo` | **Modello di linguaggio** on-device o remoto: costi, privacy, qualita'; §1.4 esclude l'AI dall'MVP: serve una decisione. Estensione di condivisione iOS |
| F17 | **QR Me** (ex «Fammi un QR», rinominata il 2026-10-09) | QR a tutto schermo da qualunque cosa condivisa, e lettura dei QR | `com.smp.qrme` (definitivo, F17.0) | Ricezione da Share Sheet (intent `SEND` su Android, **Share Extension** su iOS) in `packages/micro_share/`; scanner `flutter_zxing` (ZXing via FFI, dal 2026-10-09 al posto di `mobile_scanner`/ML Kit); stile con colori e logo |
| F18 | **Read Aloud** (ex «Leggimelo», nome del 2026-10-11) | Un articolo condiviso letto ad alta voce | `com.smp.leggimelo` | Estrazione del testo principale da una pagina (rete) + sintesi vocale del sistema; Share Extension |
| F19 | **Link Peek** (ex «Dove porta?», nome del 2026-10-11) | Dove porta davvero un link abbreviato o sospetto, prima di aprirlo | `com.smp.doveporta` | Segue i redirect via rete **senza aprire la pagina**; segnali sospetti (punycode, domini strani); cambia l'informativa privacy ("l'app non parla con nessun server" non vale piu') |

⚑ **Nomi definitivi (proprietario, 2026-10-11)**: nome sotto l'icona = la prima parte; nome nella scheda
dello store come scritto qui (il trattino e' un trattino semplice, «TLDR» senza punto e virgola):

| Fase | Sotto l'icona | Scheda store (it) | Scheda store (en) |
|---|---|---|---|
| F10 | Boomerang | Boomerang | Boomerang |
| F11 | Pin Drop | Pin Drop - Dov'è? | Pin Drop - Where is it? |
| F13 | Fair Share | Fair Share - Split Payments | Fair Share - Split Payments |
| F14 | Geo Note | Geo Note - Note Geografiche | Geo Note |
| F16 | TLDR | TLDR - Riassumilo | TLDR |
| F18 | Read Aloud | Read Aloud - Leggimelo | Read Aloud |
| F19 | Link Peek | Link Peek | Link Peek |

⚑ **In inglese niente traduzione italiana nel titolo** (proprietario, 2026-10-11): il nome da solo; se e'
gia' preso si aggiunge **una parola descrittiva in inglese** (es. «TLDR Summarizer»). La disponibilita' si
verifica solo creando l'app negli store (409 se preso). **F15 «Quanti sono?» e' annullata.** **La prossima e' F13 Fair Share**
(scelta del 2026-10-11, si comincia il 2026-10-12 da F13.0).

⚑ **Il numero di fase non e' l'ordine di sviluppo.** Le fasi seguono l'ordine del file del
proprietario; quale si fa per prima lo decide lui. Proposta, dal meno al piu' rischioso:
F17 Fammi un QR, F13 Quanto dividiamo?, F12 Quanto sto spendendo?, F10 Te l'ho prestato,
F11 Dove l'ho lasciato?, F19 Dove porta?, F18 Leggimelo, F14 Ricordamelo qui; per ultime
F15 Quanti sono? e F16 Riassumilo, che richiedono prima di decidere se e come usare l'AI.

☠ **Cose nuove per la piattaforma**, da affrontare **una volta** in `micro_core` alla prima app
che le chiede, non copiate app per app:
- **ricezione da Share Sheet** (F16, F17, F18, F19): intent `ACTION_SEND` su Android e un target
  **Share Extension** su iOS, sul modello di `tool/aggiungi_widget_ios.rb`;
- **posizione** (F11, F14): permessi in primo piano e in background, con le dichiarazioni che
  Play e Apple chiedono;
- **rete dall'app** (F18, F19, forse F16): oggi le app non parlano con nessun server se non per
  le licenze; l'informativa privacy del sito va aggiornata per quelle app.

---

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
| Full Freezer | `#0461E5` | light | Plus Jakarta Sans | Il blu dell'icona del proprietario (era `#3A7CA5`, cambiato il 2026-10-06) |
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

### ADR-015 — Widget nativi solo dove sono una feature di prodotto

**Decisione**: widget home-screen in **TrashCan** (F4.10) e in **Full Freezer** (F5.10).
Nessun widget in Scorte Calore e Film Tracker.

⚑ Dal 2026-10-04 la decisione vale **per due sistemi** (ADR-021), e il conto cambia: dove
si diceva "un widget", adesso si legga "un `AppWidgetProvider` in Kotlin **e** un'estensione
WidgetKit in Swift". Le due app che il widget non ce l'hanno risparmiano il doppio di
quanto risparmiavano prima.

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

### ADR-018 — Un widget contiene tutti i giorni che dovrà mostrare, non il giorno di oggi

**Decisione**: il codice Dart che alimenta un widget scrive **uno stato per giorno** per un
orizzonte lungo (in TrashCan 3650 giorni), in righe separate da `\n` con i campi separati da
caratteri di controllo. Il provider Kotlin cerca la riga che porta la data di oggi. Le sveglie
pianificate sono tante quante i giorni precalcolati.

**Vale per ogni widget del monorepo**, TrashCan e Full Freezer (F5.10).

☠ **Perché**: un widget Android non può far girare Flutter. Vive nel processo dell'app ma lo
ridisegna il sistema, e Dart gira solo con l'app aperta. Un widget che contiene le stringhe
di oggi è **corretto solo finché è oggi**: a mezzanotte mostra il giorno prima, e torna giusto
appena si apre l'app, cioè smette di sbagliare esattamente quando lo si va a guardare. In
TrashCan il difetto è arrivato fino al proprietario, che l'ha segnalato dal proprio telefono.

Le due correzioni che vengono in mente per prime non bastano, e vanno sapute prima:

1. **Far scattare un allarme non aggiorna niente** se il ridisegno rilegge le stesse stringhe.
2. **Far girare Dart in background** costerebbe un isolate, una seconda connessione al
   database e la benevolenza del sistema, e fallirebbe in silenzio sui telefoni che uccidono
   i processi. Non è una strada.

☠ Va dichiarato nel manifest dell'app il receiver `HomeWidgetScheduledUpdateReceiver`: il
plugin lo lascia all'app di proposito, così chi non pianifica aggiornamenti non eredita il
permesso di avvio al boot. Senza, l'allarme viene armato, scatta, e la trasmissione cade nel
vuoto **senza nessun errore, da nessuna parte**.

⚑ L'orizzonte lungo si paga solo se lo si costruisce male. In TrashCan costava formattare la
data di ogni raccolta elencata, ripetuta per ogni giorno che la elenca: l'etichetta si
prepara una volta per raccolta, e il ciclo dei giorni unisce stringhe già pronte. Le righe
invece della serializzazione strutturata servono al lato Kotlin, che così cerca una
sottostringa invece di analizzare l'intero orizzonte dentro un `BroadcastReceiver`.

⚑ **L'elenco delle sveglie non può essere più corto dell'orizzonte.** In TrashCan erano sette
contro i giorni già scritti: dall'ottavo giorno senza aprire l'app il risveglio smetteva di
arrivare pur avendo i dati pronti sotto. È lo stesso difetto, solo spostato in avanti.

### ADR-019 — Il widget non è una leva del Pro

**Decisione**: il widget di TrashCan è identico per tutti, tre giorni compresi. Il Pro si
vende con i promemoria, il secondo promemoria, i calendari multipli, il backup e il colore
dell'app.

☠ **Perché**: la versione gratuita mostrava **una** riga sola sotto la testata, con l'idea che
"si vede cosa si guadagna ad averne tre". Era una supposizione, e il primo essere umano che
ha guardato il widget vero l'ha letta come un guasto: «è sbagliato il widget». Una riga in
mezzo a mezzo widget bianco non comunica "funzione a pagamento", comunica "non ha caricato",
e chi lo pensa non compra: disinstalla. Una funzione mutilata non è una vetrina del Pro, è
una recensione da due stelle.

⚑ Regola generale per le altre app: si mette dietro il paywall una funzione **intera** che si
capisce da fuori, mai la metà di una funzione che l'utente sta già guardando.

### ADR-020 — Il prezzo scritto nei testi è quello finale del paese, non quello impostato

**Decisione**: in Play Console si imposta il **prezzo base** (TrashCan: 1,99 €), e Play ne
ricava il finale ivato paese per paese. Nei testi italiani si scrive **quel finale**
(2,39 €), mai il base, mai "+ IVA". Nei testi inglesi, che parlano a decine di paesi, la
cifra va accompagnata dalla nota che il prezzo locale varia. Nell'app non si scrive mai un
prezzo: si mostra `formattedPrice` che arriva dallo store.

☠ **Play tratta il numero che digiti come imponibile, e il compratore ne paga un altro.**
Verificato nella tabella dei prezzi di `trashcan_pro_lifetime` il 16 settembre 2026: base
1,99 €, e la colonna dei paesi riporta 2,39 € in Italia (22%), 2,49 € in Irlanda (23%),
2,47 € in Islanda (24%), 2,29 € in Lussemburgo (17%), 2,29 USD dove non c'è IVA.

☠ **Non è una moltiplicazione, è una tabella.** Italia al 22% e Lettonia al 21% finiscono
tutte e due a 2,39 €, e 1,99 × 1,22 farebbe 2,43: Play arrotonda ai propri livelli di
prezzo per valuta. Quindi **il finale non si calcola, si legge** dalla tabella del prodotto.
Chi prova a dedurlo sbaglia, e sbaglia in modo credibile, che è il modo peggiore.

☠ **Perché si scrive il finale**: verso un consumatore il prezzo dev'essere comprensivo di
imposte, lo dicono il Codice del consumo e la direttiva sull'indicazione dei prezzi. Scrivere
il base significa che l'utente legge un numero sul sito e ne trova un altro, più alto, nel
foglio di pagamento: è il momento peggiore in cui si possa perdere un acquisto.

⚑ **Un prezzo unico scritto a mano non esiste per il mondo.** Solo nell'eurozona il finale
va da 2,29 € a 2,49 €, e fuori cambia anche la valuta. Per questo la pagina inglese porta la
cifra più la nota sul prezzo locale, e la pagina italiana può permettersi il numero secco: si
rivolge a un paese solo.

⚑ **Se si vuole un finale tondo, si edita il paese, non il base.** Per far pagare 1,99 €
all'italiano non si imposta 1,99: si sovrascrive il prezzo dell'Italia nella tabella. 2,39 €
sta sopra la soglia psicologica dei 2 € ed è un numero che non si ricorda; è una decisione
commerciale aperta, non un vincolo tecnico.

⚑ **Nell'app non si scrive mai un prezzo a mano.** `formattedPrice` arriva già localizzato,
nella valuta del paese e col finale giusto; una costante nel codice sarebbe sbagliata in tutti
i paesi tranne uno, e resterebbe sbagliata il giorno che il prezzo cambia. È anche l'unico
punto del sistema che non ha avuto bisogno di questa correzione.

### ADR-021 — Ogni app esce su Android **e** su iOS

**Decisione**: le quattro app hanno due piattaforme di destinazione, non una. Ogni app ha
`apps/<nome>/android` e `apps/<nome>/ios`, e una funzione non è finita finché non si comporta
bene su entrambe.

☠ **Questo documento ha detto il contrario per quasi un mese.** L'intestazione diceva
«quattro app Flutter monetizzate una tantum su Google Play», e nessuna fase prevedeva iOS.
Il proprietario l'aveva detto dall'inizio; la decisione è scritta, con le sue parole, in
`memory/decisioni.md` alla data del 2026-10-04. Un documento che afferma una piattaforma
sola fa scrivere codice che dà per scontata quella piattaforma, ed è esattamente quello che
è successo: al momento della correzione, in tutto il monorepo esisteva **un solo** controllo
di piattaforma.

⚑ **Cosa cambia in pratica.** Flutter rende gratuita la parte grande - schermate, motore
delle ricorrenze, database, traduzioni - e lascia intero il costo delle **giunture col
sistema**, che sono poi le cose per cui si scarica l'app:

| Giuntura | Android | iOS |
|---|---|---|
| Widget di casa | `AppWidgetProvider` in Kotlin + `RemoteViews` | estensione **WidgetKit** in Swift, bersaglio Xcode separato |
| Acquisti | Google Play Billing | StoreKit, con prodotti da creare in App Store Connect |
| Notifiche | canali, importanza, `SCHEDULE_EXACT_ALARM` | permesso Darwin, niente canali, `threadIdentifier` |
| Icona | adattiva: primo piano, sfondo, monocromatica | una immagine sola, **senza canale alfa** |
| Avvio | tema, più l'API di sistema di Android 12 | storyboard |

☠ **La parte condivisa non è gratis: è gratis solo se nessuno ci mette dentro un
presupposto.** Il difetto tipico non è il codice nativo, che si vede; è la riga Dart che
chiama un'API esistente su una piattaforma sola, compila senza un avviso, e fallisce a
runtime sull'altra. `micro_core` è il posto dove questo costa di più, perché il difetto si
moltiplica per quattro app.

⚑ Dove serve sapere su cosa si sta girando, si guarda `defaultTargetPlatform` e non
`Platform.isAndroid`: il secondo legge `dart:io`, che un test non può far mentire, e la
differenza fra le piattaforme resterebbe la sola parte non coperta dai test.

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
| F9 Porting iOS (fatto prima di F4) | `v5.0.0` |
| F4 Full Freezer | `v6.0.0` |
| F5 Scorte Calore | `v7.0.0` |
| F6 Film Tracker | `v8.0.0` |
| F7 Hardening trasversale | `v9.0.0` |
| F8 Deploy e pubblicazione | `v10.0.0` |
| F10–F19 App nuove (§1.6), nell'ordine in cui si chiudono | da `v11.0.0` in su, una versione maggiore per fase |

⚑ Aggiornata il 2026-10-07: il porting iOS (F9) e' stato fatto dopo TrashCan e ha preso
`v5.0.0`, quindi tutte le fasi successive scalano di uno.

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

> ⚑ **Dal 2026-10-11**: dopo l'aggiornamento di `StatusMicroApps.md` e delle decisioni, lanciare
> `pwsh site/tool/pubblica_riservato.ps1` per aggiornare l'area riservata del proprietario
> (`https://smpmicroapps.it/riservato`). Mai scrivere la password da nessuna parte.

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

- [x] **F2.1** Bootstrap Node/TypeScript/Fastify, config e logging
- [x] **F2.2** Schema SQLite (10 tabelle), migrazioni idempotenti, seed delle quattro app
- [~] **F2.3** Plugin `auth` (HMAC + anti-replay) fatto; i limiti per rotta sono registrati ma non ancora cablati, vedi debito
- [x] **F2.4** `PlayVerifier`, con la distinzione fra errori definitivi e transitori
- [x] **F2.5** `EntitlementService` e le rotte `/v1/purchases/verify`, `/v1/entitlements/:installId`
- [x] **F2.6** Codici di ripristino, con scadenza, uso singolo e tetto di 3 in 30 giorni
- [x] **F2.7** `/v1/rtdn` con deduplica per `messageId` e risposta sempre 200
- [x] **F2.8** Pannello admin: login argon2id, riepilogo, entitlement filtrabili, acquisti, RTDN, audit, export CSV
- [x] **F2.9** Backup con `db.backup()` e rotazione. **Il ripristino va provato in F8.5**
- [x] **F2.10** 43 test: ogni rotta, ogni codice d'errore, più l'avvio reale del bundle compilato
- [x] **F2.11** Dockerfile multi-stage, compose con bind su `127.0.0.1`, `.env.example`, healthcheck
- [x] **F2.12** `server/codebase_reference.md`
- [x] **F2.13** Rituale di fine fase F2

### F3 — TrashCan (app pilota, integrazione billing end-to-end) → `v4.0.0`

- [x] **F3.1** Progetto, dipendenze, l10n (it/en, 166 chiavi, zero non tradotte), font Outfit, tema, router, rotte, limiti Pro, piattaforma Android (`com.smp.trashcan`, minSdk 24)
- [~] **F3.2** Data layer Drift: tabelle, mapper riga↔dominio nelle due direzioni, repository di scrittura, `watchBundle` corretto (osserva tutte e quattro le tabelle) e 31 test. Manca il test di migrazione (F3.2.6)
- [x] **F3.3** Motore delle ricorrenze `OccurrenceEngine` + 40 test
- [x] **F3.4** Wizard di setup iniziale: 4 passi, preset, giorni, orario, `PopScope` sul back di sistema. Verificato sull'emulatore
- [x] **F3.5** Home "Stasera / Prossima raccolta / Prossimi 7 giorni". Verificata sull'emulatore
- [x] **F3.6** Gestione tipi e regole: lista con riordino a trascinamento, editor del tipo, editor delle regole con tutte e cinque le forme e anteprima live delle prossime 6 date
- [x] **F3.7** Eccezioni: menu contestuale sulla raccolta (salta, sposta, straordinaria, ripristina), pagina di riepilogo raggiungibile dalle impostazioni. Verificato sull'emulatore
- [x] **F3.8** Notifiche: `TrashcanScheduler` + 15 test, receiver e permessi nel manifest, pagina promemoria, deep link `/day/:date`. Verificata sull'emulatore: notifica consegnata alle 13:09:03 per un allarme delle 13:09:00
- [x] **F3.9** Calendari multipli + gating Pro + paywall. Verificato sull'emulatore: il paywall si apre sul secondo calendario, l'acquisto finto sblocca il Pro, il secondo calendario si crea e si commuta dal titolo della home
- [x] **F3.10** Export/import calendario, backup, condivisione file: `TrashcanBackupSource` con 9 test. Verificato sull'emulatore: la condivisione produce un file col solo calendario attivo, manifest e conteggi corretti, e lo passa al foglio di sistema
- [x] **F3.11** Widget Android: `TrashcanWidgetProvider.kt` + layout `RemoteViews`, aggiornato a ogni modifica dei dati e alle 00:05, prossimi tre giorni come funzione Pro, voce nelle impostazioni che lo propone al launcher. Verificato sull'emulatore
- [~] **F3.12** Play Console. **Bloccata su azione del proprietario**: richiede l'account Google Play, un AAB pubblicato su un canale e alcune ore prima che il prodotto in-app diventi acquistabile. Fatto da qui: firma di release collegata al keystore (`android/key.properties`, non versionato), regole ProGuard, AAB firmato e verificato (`CN=MicroApps`). Restano i passi 1-8 del piano
- [x] **F3.13** Test: 116 in `apps/trashcan` (40 motore, 34 data layer, 24 servizi, 18 widget) + test di integrazione del primo avvio, **verde sul dispositivo**. Ha subito trovato un difetto che fa cadere il processo dell'app la prima sera senza raccolte. **Senza golden**: vedi il debito tecnico nell'atlante, un golden fallisce per il rasterizzatore e non per l'app
- [x] **F3.14** Rifinitura: icona adattiva con `monochrome`, icona di notifica monocromatica, stati vuoti in ogni lista, tavolozza corretta dopo la misurazione del contrasto (tre colori erano sotto 4.5:1). Restano il testo al 200% e le `Semantics`, elencati nel debito tecnico
- [x] **F3.15** `apps/trashcan/codebase_reference.md` riscritto a fine fase, con firme estratte dal codice
- [x] **F3.16** Rituale di fine fase F3: piano e atlanti aggiornati, documenti iniettati nel Projects Tracker (progetto 17), branch `v4.0.0`

**Revisione del proprietario, 11 settembre 2026** (branch `v4.1.0`). Quattro richieste,
tutte fatte e provate sull'emulatore:

- [x] **Recupero dell'acquisto su un telefono nuovo**: `lib/features/restore/restore_page.dart`,
  raggiungibile dalle impostazioni. Due strade in ordine di probabilita': il ripristino da
  Play, che copre il caso normale e funziona senza server, e il codice di trasferimento per
  chi cambia account Google, che compare solo quando il License Server e' configurato.
- [x] **Icona rifatta**: cestino davanti a un calendario. Il calendario e' un telaio e non un
  rettangolo pieno, altrimenti a 48dp resta una macchia chiara.
- [x] **Widget rifatto**: 2x2 invece di 4x2, stretto e verticale. Intestazione colorata col
  tipo di stasera, corpo bianco coi giorni successivi. Col Pro ne elenca tre, senza uno solo:
  una meta' bianca e vuota non si legge come "funzione a pagamento" ma come "non ha caricato".
- [x] **Colore dell'app scelto dall'utente** fra dieci semi misurati, dietro al paywall
  (`themeCustomization`). Vedi `lib/app/app_themes.dart`.
- [x] **Tutte le notifiche dietro al paywall**, non solo le doppie. Nuova chiave
  `FeatureKey.notifications` in `micro_core`. Il compromesso che comporta e' scritto in
  `feature_limits.dart` e nell'atlante.

**Logo del proprietario, 11 settembre 2026** (branch `v4.1.1`):

- [x] **Icona e splash generate dal logo fornito**, `assets/icons/trashcan_logo.png`
  (1254x1254). Icona adattiva con fondo `#2E7D5B` e rientro del 18%, livello `monochrome`
  per i temi di Android 13, icone legacy per tutte le densita'. Splash verde col logo al
  centro, chiara e scura. Configurazione in `flutter_launcher_icons.yaml` e
  `flutter_native_splash.yaml`, documentata in `apps/trashcan/codebase_reference.md` §2bis.
  Verificate sull'emulatore: icona nel drawer e splash catturate a schermo.
- [x] Su Android 12+ la splash mangiava manico del cestino e simbolo del riciclo: il sistema
  ritaglia l'immagine con un cerchio che ne lascia il 66% centrale. Risolto con
  `trashcan_splash_android12.png`, il logo rientrato su tela 1152x1152.
- [x] `drawable/ic_notification.xml` **non** e' stato sostituito col logo: resta
  monocromatico, perche' dell'icona di notifica Android usa solo il canale alfa.
- [x] Difetto trovato dalla suite durante il giro: `EntitlementService` lasciava girare lo
  spinner "Sblocca Pro" su un acquisto in attesa, perche' il ramo `PurchasePending` spegneva
  `isBusy` dopo la scrittura invece che prima. Corretto in `micro_core`.

### F4 — Full Freezer → `v6.0.0` (era `v5.0.0`, gia' usato dal porting iOS F9)

- [x] **F4.0** Decisioni di partenza (vedi §8 F4.0): due piattaforme, solo iPhone, prezzo 3,99 €, foto gratis e notifiche Pro, capienza (2026-10-06)
- [x] **F4.1** Bootstrap progetto, tema, l10n, router — **`android/` e `ios/` insieme** (2026-10-06: `com.smp.fullfreezer`, seme `#0461E5`, Plus Jakarta Sans, icone da `tool/genera_icone.py`; 4 test; provata su emulatore Android 15 e simulatore iPhone 18 Pro)
- [x] **F4.2** Data layer Drift: freezer, scomparti, alimenti, movimenti (2026-10-06: `lib/data/{tables,database,freezer_repository}.dart`, `lib/domain/{categories,units,text_norm}.dart`; 19 test del repository + 6 di dominio)
- [x] **F4.3** `AgingCalculator` e ordinamento "oldest first" + test (2026-10-06: `lib/domain/aging.dart`, `compareOldestFirst`; 9 test)
- [x] **F4.3b** `CapacityEstimator`: modelli di freezer, ingombro stimato degli alimenti, taratura, soglie + test (2026-10-06: `lib/domain/capacity.dart`, con anche `CapacityAlertPolicy` dell'isteresi di F4.9, che e' logica pura; 18 test)
- [x] **F4.4** Home ordinata per anzianità, con sezione "Da usare prima" (2026-10-07: interfaccia "A · Ghiaccio" scelta dal proprietario, vedi `memory/decisioni.md`; `lib/features/home/`, `lib/app/freezer_palette.dart`, icone disegnate in `lib/app/category_glyphs.dart`)
- [x] **F4.5** Inserimento rapido (obiettivo: sotto i 5 secondi) e inserimento completo (foglio rapido in 2 tocchi, pagina completa, ingombro; F4.5b foto con `image_picker` e `ImageStore`, provata sull'emulatore il 2026-10-07. Il debito dei testi d'uso iOS solo in inglese e' chiuso in F4.14: `ios/Runner/{it,en}.lproj/InfoPlist.strings`, aggiunti con `tool/aggiungi_infoplist_strings.rb`)
- [x] **F4.6** Posizioni: freezer (scelto da una serie di modelli, dal più piccolo al più grande) e scomparti, con conteggi e barra di riempimento (2026-10-06; il limite di un freezer nel piano gratuito e' arrivato con F4.10; il riordino dei freezer per trascinamento nelle impostazioni il 2026-10-07)
- [x] **F4.7** Uscita alimento: consumato / buttato, con storico (2026-10-07: swipe con annulla in home; storico Pro per mese in lib/features/history/history_page.dart; statistiche Pro in stats_page.dart su lib/domain/stats.dart: quota buttata, permanenza media, categoria piu buttata, ultimi sei mesi; un alimento uscito si rimette dentro dalla sua pagina)
- [x] **F4.8** Ricerca istantanea (2026-10-07: `lib/domain/search.dart` filtra in memoria nome e note normalizzati, tutte le parole in qualunque ordine; `lib/features/search/search_page.dart`; lente nella testata)
- [x] **F4.9** Notifiche (**Pro**): digest aggregato settimanale/quindicinale/mensile + avvisi «quasi pieno» / «quasi vuoto» (2026-10-07: `lib/services/{notification_plan,freezer_scheduler}.dart`; testo del riepilogo calcolato per il giorno di consegna; avvisi in coda nelle preferenze perche' `replaceSchedule` non li cancelli; interruttore spento di default, permesso chiesto all'accensione; provato sull'emulatore: avviso «quasi pieno» consegnato all'89%, riepiloghi pianificati la domenica alle 18. Completato il 2026-10-07 dopo la rilettura per l'atlante: «quasi pieno» cita il piu' vecchio del freezer (`FreezerScheduler.capacityAlertBody`) e il riepilogo aggiunge una riga per ogni freezer pieno o quasi vuoto, esclusi quelli senza niente dentro (`digestCapacityLines`). ⚑ `lib/services/capacity_alerts.dart` non esiste: la logica sta in `CapacityAlertPolicy` (dominio) e `FreezerScheduler.evaluateCapacity`, scelta consapevole)
- [x] **F4.10** Feature Pro: freezer multipli, notifiche, storico, statistiche, CSV, backup, categorie personalizzate (le foto sono **gratis**) — FATTO il 2026-10-07: `lib/app/{feature_limits,entitlement,paywall_config}.dart`, impostazioni con scheda Pro e ripristino, limite di un freezer (`openNewFreezer`), provato con lo store finto sull'emulatore. Storico, statistiche (F4.7) e notifiche (F4.9) fatti; CSV e backup/ripristino fatti il 2026-10-07 (`lib/services/{csv_export,freezer_backup_source}.dart`, `lib/features/settings/data_actions.dart`, sezione "I tuoi dati"; ripristino **gratis**, creazione Pro; provati con `test/services/backup_csv_test.dart` e sull'emulatore). Categorie personalizzate fatte il 2026-10-07 (`lib/features/categories/`, `chooseCategory` in `item_pickers.dart`, chiave `custom:<id>`, promemoria copiato nell'alimento, cancellazione che azzera la categoria degli alimenti; provate sull'emulatore). Ogni beneficio del paywall ora esiste.
- [x] **F4.11** Widget "da consumare presto": Android (Kotlin) **e** iOS (WidgetKit), stesso payload — FATTO il 2026-10-07: `lib/services/freezer_widget.dart` (i tre piu' vecchi, payload con `frozenAt` e promemoria, giorni calcolati dal widget per ADR-018), `FullFreezerWidgetProvider.kt` + `res/layout/full_freezer_widget*.xml`, `ios/FullFreezerWidget/` (timeline di 8 voci), anteprima Mac `apps/full_freezer/tool/anteprima_widget_ios.swift`. Provato: Android sull'emulatore (disegno, colori, tocco da app aperta e da app chiusa); iOS sul simulatore (build con estensione, contenitore App Group scritto, disegno con icone vere). MANCA: tocco sul widget iOS provato a mano (il simulatore headless chiede conferma a `simctl openurl`); registrare `group.com.smp.fullfreezer` e l'App ID dell'estensione sul portale (proprietario). ☠ Trappole pagate: deep link di Flutter da spegnere (`flutter_deeplinking_enabled` / `FlutterDeepLinkingEnabled`), `onNewIntent` con `setIntent` in `MainActivity`, righe a peso 1 (widget mezzo vuoto).
- [x] **F4.12** Voice input per l'inserimento rapido, Android e iOS (permessi microfono e riconoscimento vocale) — FATTO il 2026-10-07: `lib/domain/voice_parser.dart` (`VoiceItemParser`, italiano e inglese insieme, numeri in lettere, "etto" = 100 g, "e mezzo", ripiego sul nome), `lib/services/voice_input.dart` (`VoiceInput` su speech_to_text 7.5, dettatura, pausa 3 s, limite 15 s), microfono nel campo nome del `QuickAddSheet`; `RECORD_AUDIO` + `<queries>` RecognitionService su Android, `NSMicrophoneUsageDescription`/`NSSpeechRecognitionUsageDescription` su iOS. Provato: 20 frasi in `test/domain/voice_parser_test.dart`; sull'emulatore permesso, avvio e chiusura per silenzio (non si puo' parlare all'emulatore). MANCA: prova con la voce vera su telefono. I testi dei permessi iOS in italiano ci sono (F4.14). ⚑ L'informativa privacy del sito deve dire che il riconoscimento lo fa il servizio del telefono (Google/Apple), che puo' usare i loro server.
- [x] **F4.13** Test (unit, DB, widget, golden, integrazione) — FATTO il 2026-10-07, 137 test verdi. Il vincolo dei 4 tocchi e' **misurato** in `test/widget/quick_add_test.dart` (3 interazioni il percorso minimo, 4 con un suggerimento), con repository finto. Parser vocale su 20 frasi (`test/domain/voice_parser_test.dart`), ricerca senza accenti (`test/domain/search_test.dart`), riepilogo con 0, 1 e N vecchi (`test/services/notification_plan_test.dart`), backup/CSV (`test/services/backup_csv_test.dart`), widget (`test/services/freezer_widget_test.dart`). ⚑ Scelte: niente golden (i caratteri cambiano fra Windows e Mac e un golden instabile si impara a ignorarlo; l'aspetto lo verificano gli scatti sull'emulatore e l'anteprima del widget iOS); il test di integrazione `integration_test/flusso_test.dart` resta ma non e' affidabile sull'emulatore (connessione alla VM appesa): il flusso lo coprono il test dei tocchi e i giri adb.
- [x] **F4.14** Rifinitura visiva, onboarding, empty state, accessibilità — FATTO il 2026-10-07: tema scuro provato su home, inserimento, prodotto, impostazioni, statistiche, freezer; carattere al 130% su home, inserimento, statistiche (regge, i testi lunghi si troncano con i puntini); stati vuoti presenti (home, storico, categorie, ricerca, widget); etichette di accessibilita' leggibili (verificate nei dump di uiautomator); virgolette tipografiche nei testi inglesi; testi dei permessi iOS in italiano.
- [x] **F4.15** `apps/full_freezer/codebase_reference.md` — FATTO il 2026-10-07: ~2000 righe, `tool/verify_atlas.ps1 -Project apps/full_freezer` pulito, firme controllate a campione contro il sorgente. La rilettura per scriverlo ha trovato e fatto correggere: spostamento senza movimento `moved`, freezer non riordinabili, pagine Pro protette solo all'ingresso (ora `ProGate` anche sulla pagina), F4.9 incompleto, 5 schede previste contro 4 mostrate (deciso 4), virgolette dritte residue, `StatsPage` su `DateTime.now()`. Differenze consapevoli dal piano, scritte nell'atlante: niente valore economico dello spreco (il modello non ha prezzi), grafico disegnato a mano invece di fl_chart, cartelle `features/freezers` e `features/history`.
- [x] **F4.16** Rituale di fine fase F4 — 2026-10-07: piano e atlante aggiornati, documenti nel Projects Tracker (progetto 17), messaggio di fine fase, branch `v6.0.0` (il `v5.0.0` previsto qui era gia' andato al porting iOS F9, quindi le fasi successive scalano di uno)

**Ripresa (stato al 2026-10-07, sera).** Il codice di F4 e' completo: 140 test verdi, analisi pulita, provato sull'emulatore Android e sul simulatore iPhone. Resta solo **F4.17**, che dipende dal proprietario: registrare su Apple gli App ID `com.smp.fullfreezer` e `com.smp.fullfreezer.FullFreezerWidget` con l'App Group `group.com.smp.fullfreezer`, creare le app e il prodotto `fullfreezer_pro_lifetime` (3,99 €) su App Store Connect e Play Console. Da provare sul telefono vero perche' l'emulatore non lo permette: la voce, e il tocco sul widget iPhone. Aperti fuori da F4: un test di `micro_core/test/entitlement` fallisce ogni tanto e al giro dopo passa; `EntitlementView`/`EntitlementNotifier` sono copiati da TrashCan e vanno spostati in `micro_core` alla terza app. Per provare l'app piena: `flutter run --dart-define=FF_DEMO=true` (dati di esempio, mai in release).
- [ ] **F4.17** Store: prodotto Pro su Play Console e App Store Connect, schede, screenshot da test, TestFlight, invii (aggiornare `StatusMicroApps.md`)
- [x] **F4.18** Dettatura solo sul dispositivo (regola dati solo sul telefono), 1.0.0+3 — 2026-10-10: `SpeechListenOptions(onDevice: true)` in `lib/services/voice_input.dart` **e** controllo nativo prima di ascoltare (canale `full_freezer/voice`: `MainActivity.onDeviceRecognitionAvailable` = API ≥ 31 e `SpeechRecognizer.isOnDeviceRecognitionAvailable`; `AppDelegate.onDeviceRecognitionAvailable(localeId:)` = `SFSpeechRecognizer.supportsOnDeviceRecognition` per lingua), perche' speech_to_text 7.5.0 su Android senza riconoscitore on-device ripiega **in silenzio** su quello di rete e su iOS risponde due volte al canale. Dove non c'e': microfono barrato e messaggio «La dettatura sul telefono non è disponibile qui: scrivi il nome (puoi usare il microfono della tastiera)», mai un ripiego online. Testi dei permessi iOS (`NSSpeechRecognitionUsageDescription`, it/en) e schede store aggiornati; `pubspec.yaml` a `1.0.0+3` (Play ha visto il 2, App Store la build 1). 150 test verdi (+8 `test/services/voice_input_test.dart`, +2 in `quick_add_test.dart`). DA PROVARE su iPad: dettatura in italiano sul dispositivo. ⚑ Supera la nota di F4.12 sull'informativa privacy: ora deve dire «sul telefono, senza server».

### F5 — Scorte Calore → `v7.0.0`

- [x] **F5.0** Decisioni di partenza (vedi §8 F5.0): Android e iPhone, notifiche **Pro**, widget su entrambe le piattaforme, prezzo 2,99 €, colori dall'icona, interfaccia essenziale prima e proposte grafiche dopo (2026-10-07)
- [x] **F5.1** Bootstrap progetto, tema, l10n, router (2026-10-07: `com.smp.scortecalore` su Android e iOS, solo iPhone, team, firma e ProGuard come Full Freezer, `licenseAppId`, limiti Pro e paywall, testi da `tool/testi.py`, icone e splash da `tool/genera_icone.py` sull'icona del proprietario con sfondo ripulito, avvio provato sull'emulatore)
- [x] **F5.2** Data layer Drift: fonti, misurazioni, acquisti, promemoria calendario (2026-10-07: `lib/data/{tables,database,scorte_repository}.dart`, una misura al giorno con sovrascrittura, ricalcolo delle letture in percentuale quando cambiano capienza o quota utile, 38 test)
- [x] **F5.3** `ConsumptionCalculator`: media mobile, rilevamento rifornimenti, qualità della stima + test (2026-10-07: `lib/domain/consumption.dart`, `reorder_plan.dart`; ⚑ esaurimento contato dall'**ultima misura** e non da oggi, altrimenti senza misure nuove la data slitterebbe ogni giorno e il widget non scenderebbe mai; 62 test di dominio)
- [x] **F5.4** Conversioni unità e capacità serbatoio (litri, percentuale, sacchi, kg, steri) (2026-10-07: `lib/domain/{fuel_units,fuel_source,quantity_converter}.dart`; nessuna stringa nel dominio, i nomi dagli ARB)
- [x] **F5.5** Configurazione fonte combustibile (2026-10-07, interfaccia essenziale: `features/sources/source_editor_page.dart`, ⚑ una pagina sola con i campi che compaiono solo quando servono, invece della procedura a otto passi)
- [x] **F5.6** Dashboard: residuo, consumo medio, autonomia, data di riordino (2026-10-07, essenziale: `features/home/home_page.dart`; grafica da scegliere con le proposte, F5.0 punto 6)
- [x] **F5.7** Aggiornamento scorta (2026-10-07: `features/stock/update_sheet.dart`, valore dell'ultima volta precompilato, manometro con conversione in tempo reale, avviso di rifornimento)
- [x] **F5.8** Notifiche di riordino e di superamento data — FATTO il 2026-10-08: `lib/services/{scorte_scheduler,notification_providers}.dart`, `features/settings/notifications_section.dart`, canale `scorte_reorder` (☠ mai cambiarlo), **Pro e spente di default**, ripianificazione a ogni modifica (`watchAnyChange`, debounce 500 ms) e al ritorno in primo piano, nessuna notifica con stima `insufficient`; id `sourceId*10+slot`. 8 test in `test/services/scorte_scheduler_test.dart`. ⚑ Testo "Pellet: potrebbe terminare…" invece di "Il pellet…": l'articolo cambia col combustibile e `fuelName` non lo porta.
- [x] **F5.9** Storico e grafici (Pro) — FATTO il 2026-10-08: `features/history/{history_page,charts}.dart`, rotta `/sources/:sourceId/history` (pulsante in testata). Grafici disegnati con `CustomPainter` e non con fl_chart (stessa scelta di Full Freezer): scorta nel tempo con i rifornimenti e consumo per intervallo con la stima attuale, stesso asse del tempo. Gratis: ultimi 90 giorni (filtro in memoria, la differenza della prima misura visibile usa la precedente nascosta), grafici Pro. Eliminazione con "Annulla". Provato sull'emulatore.
- [x] **F5.10** Integrazione Google Calendar del dispositivo (Pro) — FATTO il 2026-10-08: `lib/services/{calendar_sync,calendar_providers}.dart`, `features/calendar/calendar_reminder_bar.dart` sotto il riquadro del riordino in testata. ⚑ **`device_calendar_plus` 0.10.1 e non `device_calendar`** (fermo al 2024, senza l'accesso completo di iOS 17). Accesso completo (serve a ritrovare l'evento), evento di un giorno intero, `CalendarGateway` astratto per i test. Oltre 3 giorni di deriva la home **propone** "Aggiorna evento". Evento cancellato a mano → si ricrea. `forgetSource` prima di eliminare una fonte e prima di un ripristino "sostituisci tutto". Permessi: `READ/WRITE_CALENDAR`, `NSCalendarsUsageDescription` + `NSCalendarsFullAccessUsageDescription` (it/en in `InfoPlist.strings`). 8 test in `test/services/calendar_sync_test.dart`; provato sull'emulatore con un calendario locale creato via adb (l'emulatore senza account non ne ha).
- [x] **F5.11** Acquisti, costi, statistiche di spesa (Pro), CSV, backup — FATTO il 2026-10-08: `lib/domain/costs.dart` (stagione 1/10–31/3, media ponderata in centesimi), `features/purchases/{purchases_page,purchase_editor_sheet}.dart` (rotta `/sources/:sourceId/purchases` con `ProGate`, si entra dallo storico), `lib/services/{scorte_backup_source,csv_export}.dart`, `features/settings/data_section.dart`. CSV unico con colonna "Tipo", decimali con la virgola. Ripristino gratis, backup e CSV Pro; il backup non porta i promemoria del calendario. DA CONFERMARE col proprietario: gli acquisti estivi (aprile–settembre) non contano in nessuna spesa stagionale.
- [x] **F5.12** Test (unit, DB, widget, golden, integrazione) — FATTO il 2026-10-08: 153 test verdi (dominio, repository, scheduler, calendario, backup/CSV, payload del widget, pagine storico e acquisti con repository finto). Niente golden, come in Full Freezer: l'aspetto lo verificano gli scatti sull'emulatore e l'anteprima del widget iOS (`tool/anteprima_widget_ios.swift`, provata con il contenitore vero del simulatore).
- [x] **F5.13** Rifinitura visiva, onboarding, empty state, accessibilità — FATTO il 2026-10-08 per l'interfaccia essenziale «A · Brace»: tema scuro e carattere al 130% provati sull'emulatore su home, foglio di aggiornamento, storico; italiano provato sul simulatore iPhone; primo avvio = editor della prima fonte (`Routes.welcome`); stati vuoti di home, storico, widget (anche «mai aperta»). Anteprima del widget nel selettore tradotta (prima mostrava date italiane col telefono in inglese). ⚑ Le **grafiche definitive** (F5.0 punto 6, proposte da generare dopo l'interfaccia minimale) restano da fare con il proprietario.
- [x] **F5.14** `apps/scorte_calore/codebase_reference.md` — FATTO il 2026-10-08: ~2050 righe, `tool/verify_atlas.ps1 -Project apps/scorte_calore` pulito (59 simboli, 0 mancanti), 24 firme controllate a campione. La rilettura ha trovato e fatto correggere: test del paywall assente (ora `test/widget/paywall_config_test.dart`), commenti superati, widget Kotlin con data breve vuota diverso da Swift, ripristino "sostituisci tutto" che toglieva gli eventi del calendario prima di sapere se riusciva (ora li toglie dopo, solo se riesce). Le incoerenze minori rimaste e il debito sono in §14 dell'atlante.
- [x] **F5.15** Rituale di fine fase F5 — 2026-10-08: piano, atlante, StatusMicroApps e decisioni aggiornati, documenti nel Projects Tracker (progetto 17), messaggio di fine fase, branch `v7.0.0`.

**Ripresa (stato al 2026-10-08).** Il codice di F5 e' completo: 158 test verdi, analisi pulita, provato sull'emulatore Android (home, paywall, calendario con un calendario locale, impostazioni, widget, storico, tema scuro, testo al 130%) e sul simulatore iPhone (home in italiano, widget con i dati veri via `tool/anteprima_widget_ios.swift`). **Aggiornamento 2026-10-08, sera:** grafica «A · Brace» confermata come definitiva; App Store fatto (scheda, video, prodotto a 2,99 €, build su TestFlight, **inviata alla revisione**; vedi `StatusMicroApps.md`). Restano: (1) Play dopo il D-U-N-S; (2) le grafiche delle schede Play sono gia' generate; (3) —; (4) confermare la stagione rigida 1/10–31/3 per la spesa (gli acquisti estivi non contano); (5) prove su dispositivo vero: acquisto, notifiche, calendario su iPad. Debito: `EntitlementView`/`EntitlementNotifier` sono ormai in tre copie e vanno spostati in `micro_core`. Dati di esempio: `--dart-define=SC_DEMO=true`.

### F6 — Film Tracker → `v8.0.0`

- [x] **F6.0** Decisioni di partenza (vedi §8 F6.0): Android e iPhone, Pro 4,99 €, foto **gratis**, nessun widget, icona del proprietario, tema scuro, interfaccia essenziale prima e proposte grafiche dopo (2026-10-08)
- [x] **F6.1** Bootstrap progetto, tema scuro, l10n, router — FATTO il 2026-10-08: `com.smp.filmtracker` Android e iOS (solo iPhone, team, firma e ProGuard da Scorte Calore, senza widget, calendario e notifiche), `licenseAppId 'filmtracker'`, Pro 4,99 €, paywall con test di coerenza, tema scuro di default (PlusJakartaSans finche' non si scelgono i caratteri), icone e splash da `tool/genera_icone.py` (riquadro rifilato per iOS, icona intera nella zona sicura per Android; niente monocromatica: il disegno non si separa dal gradiente chiaro).
- [x] **F6.2** Data layer Drift: macchine, rullini, sviluppi, stampe, immagini, catalogo pellicole — FATTO il 2026-10-08: `lib/data/{tables,database,film_repository}.dart`, seed di 25 pellicole, UNIQUE (brand, name, format), uno sviluppo per rullino (UNIQUE), stampe multiple, cascate, `sequenceNumber = max + 1`, dati di esempio `FT_DEMO`. ⚑ `laboratory` facoltativo (sviluppo in casa).
- [x] **F6.3** Macchina a stati del rullino + test — FATTO il 2026-10-08: `lib/domain/roll_status.dart`, matrice 6×6 e `suggestFrom` su 8+ combinazioni testate; niente `labelFor` nel dominio (etichette da `lib/app/labels.dart`).
- [x] **F6.4** Catalogo pellicole locale + pellicola personalizzata — FATTO il 2026-10-08: `lib/domain/film_catalog.dart`, `features/stocks/` (ricerca, gruppi per marca, personalizzate con doppione riconosciuto e "Usa quella").
- [x] **F6.5** Inventario macchine fotografiche — FATTO il 2026-10-08: `features/cameras/`, una gratis, la seconda dal paywall (`NewCameraGate` aspetta il conteggio prima di decidere).
- [x] **F6.6** Creazione e modifica rullino; avanzamento di stato — FATTO il 2026-10-08: `features/rolls/` (editor con le 5 pellicole piu' usate in cima, dettaglio con timeline verticale, azioni per stato, suggerimento di stato, cambio manuale solo con transizioni ammesse).
- [x] **F6.7** Sviluppo e stampa come eventi separati — FATTO il 2026-10-08: `features/lab/`, lo stato avanza da solo in avanti con uno snack (consegnato → in laboratorio, ritirato → sviluppato/stampato).
- [x] **F6.8** Home a tre sezioni: In macchina / In laboratorio / Archivio — FATTO il 2026-10-08 (essenziale): archivio a griglia con copertina o striscia di pellicola disegnata; grafica da scegliere con le proposte (F6.0 punto 6).
- [x] **F6.9** Photo overview: import, provini, contact sheet, miniature (**gratis**, F6.0) — FATTO il 2026-10-08: `features/photos/`, import una foto alla volta in isolate con avanzamento e annulla, galleria, riordino, copertina, visualizzatore con zoom, spazio occupato e "libera spazio". Corretto in `micro_core` `ImageStore.importBytes` (`on Object`: il decoder lancia Error). DA PROVARE su telefono: HEIC dalla galleria Android.
- [x] **F6.10** Statistiche e costi (Pro) — FATTO il 2026-10-08: `features/stats/stats_page.dart` con `ProGate`, anni dal piu' recente, spesa per voce, media sui rullini con costi, costo per fotogramma dichiarato **stima** (titolo, "≈" e riga di spiegazione), piu' usati, grafico mensile con `CustomPainter` e `Semantics`.
- [x] **F6.11** Export CSV, PDF di riepilogo, backup (Pro) — FATTO il 2026-10-08: `lib/services/{csv_export,film_backup_source,year_report}.dart`, `features/settings/data_section.dart` (ripristino gratis). PDF con `pdf` e `printing`, miniature da 400 px, Plus Jakarta Regular (niente grassetto). ⚑ DT-10 chiuso cosi': il riepilogo vive nell'app, un `PdfReportBuilder` generico in `micro_core` avrebbe un solo utente. Corretto in `micro_core` lo **zip slip** di `BackupService._restoreImages` (voci `images/../..` scartate, test aggiunto).
- [x] **F6.12** QR identificativo del rullino — FATTO il 2026-10-08: `features/qr/`, etichetta bianca stampabile, link `filmtracker://roll/<n>` con `app_links` (push, non il deep link di Flutter), provato con adb.
- [x] **F6.13** Test (unit, DB, widget, golden, integrazione) — FATTO il 2026-10-08: 184 test (matrice 6×6 e `suggestFrom`, statistiche su dataset noto, repository con vincoli e cascate, import delle foto con `ImageStore` vero, round-trip del backup con le foto, CSV, PDF, pagine con repository finto). Niente golden (stessa scelta delle altre app); integrazione: i giri su emulatore e simulatore.
- [x] **F6.14** Rifinitura visiva, onboarding, empty state, accessibilità — FATTO il 2026-10-08: grafica **C · Provino** (`lib/app/film_palette.dart`, `features/common/film_strip.dart`, Space Mono), tema chiaro "tavolo luminoso", testo al 130% provato, stati vuoti curati, `Semantics` sulle righe del laboratorio e del provino, foto disegnate nei dati di esempio (`lib/dev/demo_photos.dart`); iOS provato sul simulatore (testi dei permessi it/en). ⚑ Non fatte, di proposito: transizione `Hero` fra provino e dettaglio (il dettaglio non mostra la copertina in alto) e caricamento progressivo delle miniature (gia' decodificate alla dimensione mostrata).
- [x] **F6.15** `apps/film_tracker/codebase_reference.md` — FATTO il 2026-10-08: ~2400 righe, `tool/verify_atlas.ps1 -Project apps/film_tracker` pulito (76 simboli, 0 mancanti), 55 firme controllate. La rilettura ha trovato e fatto correggere: form di modifica sulla rotellina eterna con un rullino inesistente (test aggiunto), macchina creata dal form del rullino non selezionata, StateError non gestito nel cambio di stato, commenti superati. Le incoerenze minori rimaste sono in §14.
- [x] **F6.16** Rituale di fine fase F6 — 2026-10-08: piano, atlante, StatusMicroApps, decisioni e README aggiornati, documenti nel Projects Tracker (progetto 17), messaggio di fine fase, branch `v8.0.0`.

**Ripresa (stato al 2026-10-08).** Il codice di F6 e' completo: 185 test verdi, analisi pulita, grafica «C · Provino», provato sull'emulatore Android (dati di esempio con foto disegnate, tema scuro e chiaro, testo al 130%, QR via adb) e sul simulatore iPhone. **Aggiornamento 2026-10-08, sera:** App Store fatto (`apps/film_tracker/tool/scheda_app_store.py`, nome inglese «Film Tracker – Roll Diary», prodotto a 4,99 €, provata su iPad via TestFlight, **inviata alla revisione**; vedi `StatusMicroApps.md`). Restano: (1) —; (2) Play dopo il D-U-N-S; (3) prove su dispositivo vero: HEIC dalla galleria Android, QR letto dalla fotocamera di sistema, acquisto, stampa del PDF; (4) icona monocromatica di Android 13 (serve il disegno senza sfondo). Debito: `EntitlementView`/`EntitlementNotifier` in quattro copie, da spostare in `micro_core` in F7. Dati di esempio: `--dart-define=FT_DEMO=true`.

### F7 — Hardening trasversale e preparazione allo store → `v9.0.0`

- [ ] **F7.1** Revisione l10n completa (it/en) su tutte e quattro le app
- [ ] **F7.2** Accessibilità: contrasto, dimensioni dinamiche del testo, TalkBack, target di tocco
- [ ] **F7.3** Performance: tempo di avvio a freddo, jank, dimensione dell'AAB, R8/ProGuard
- [ ] **F7.4** Matrice di QA manuale su dispositivi e versioni Android
- [ ] **F7.5** Compliance Play: sezione Sicurezza dei dati, permessi dichiarati, `SCHEDULE_EXACT_ALARM`
- [ ] **F7.6** Asset dello store: icone, feature graphic, screenshot, descrizioni it/en
- [ ] **F7.7** Informative privacy pubblicate e raggiungibili da URL
- [ ] **F7.8** Verifica finale dei sei `codebase_reference.md` con `verify_atlas`
- [ ] **F7.9** Rituale di fine fase F7

### F10–F19 — App nuove (idee del proprietario del 2026-10-08, §1.6)

Ogni app nuova segue le **stesse sottofasi standard**, numerate `Fx.0`–`Fx.9`. Si scrivono qui una
volta sola; nella fase di ciascuna app si spuntano.

| Sottofase | Cosa | Quando e' chiusa |
|---|---|---|
| **Fx.0** | Decisioni di partenza **con il proprietario**: piattaforme, cosa e' gratis e cosa Pro, prezzo, icona (in Download), colori, widget si'/no | scritte in §8 (Fx.0) e in `memory/decisioni.md` |
| **Fx.1** | Specsheet completa in §8: dati, schermate, limiti, permessi, trappole, come per F3–F6 | un coding agent puo' svilupparla senza fare domande |
| **Fx.2** | Bootstrap §8.T, icona e splash, `licenseAppId` senza trattino basso | l'app parte sull'emulatore in Android e iOS |
| **Fx.3** | Dominio e dati, con test | test verdi, dominio senza Flutter |
| **Fx.4** | Interfaccia essenziale | tutte le funzioni raggiungibili e provate sull'emulatore |
| **Fx.5** | Pro: limiti, paywall, test di coerenza | `paywall_config_test.dart` verde |
| **Fx.6** | Proposte grafiche (artifact con 2-3 direzioni), scelta del proprietario applicata | decisione in `memory/decisioni.md` |
| **Fx.7** | Test, rifinitura, iOS sul simulatore | analisi pulita, testo al 130%, tema scuro |
| **Fx.8** | Atlante `apps/<nome>/codebase_reference.md` con `verify_atlas` | 0 simboli mancanti |
| **Fx.9** | Rituale di fine fase **e card «In arrivo» nella vetrina** (poi pagina dedicata all'uscita) | branch di versione nuova |

- [ ] **F10** Boomerang (ex «Te l'ho prestato») — `apps/prestato/` (nome della cartella da confermare in F10.0)
- [ ] **F11** Pin Drop (ex «Dove l'ho lasciato?») — posizione in primo piano + foto
- [x] **F12** Spending Review (ex «Quanto sto spendendo?») — CHIUSA il 2026-10-10 → `v10.0.0` (codice completo Android e iPhone, 339 test; store da fare: serve l'App ID del proprietario). Specsheet in §8 «F12 — Spending Review»
  - [x] **F12.0** Decisioni di partenza con il proprietario — FATTO il 2026-10-10/11 (§8 F12.0): nome «Spending Review» in it ed en, `com.smp.spendingreview`, Android e iPhone, nessun widget, interfaccia «C · Una mano», due tasti Cartellino e Scontrino, cartellino interpretato, peso a mano e bilancia, «spesa gratis, revisione Pro» a **2,99 €**, OCR Vision su iOS e PP-OCRv5 su ONNX Runtime **1.28.0 bloccata** su Android
  - [x] **F12.1** Specsheet — SCRITTA il 2026-10-10 (§8 F12.1.1–F12.1.18): file, dipendenze e guardie di privacy in build, dominio (centesimi, arrotondamenti half-up, offerte, tastierino), parser di cartellino/bilancia/scontrino sui riquadri, confronto, statistiche, `packages/micro_ocr`, dati, rotte, schermate, servizi, Pro (`FeatureKey.documentScan` nuova), permessi e privacy, trappole, test con il banco di regressione, prestazioni. domande D1–D4 **risposte dal proprietario il 2026-10-10** (§8 F12.10: nascoste, tastierino alla cassa, budget mensile Pro, carta fedelta' chiesta ogni volta)
  - [x] **F12.2a** `FeatureKey.documentScan` in `micro_core` + una riga `open()` nelle cinque app; test di tutte verdi — FATTO il 2026-10-10 (121/20/185/150/241/158/138)
  - [x] **F12.2b** `packages/micro_ocr/`: Vision (iOS), PP-OCRv5 su ORT 1.28.0 in Kotlin (Android), modelli nel repo con SHA-256, test JVM, test sul dispositivo, **parita' con RapidOCR ≥ 95%**, verifica 16 KB, atlante — FATTO il 2026-10-10 (atlante `packages/micro_ocr/codebase_reference.md`, `verify_atlas` 0 mancanti; commit e rituale ancora da fare)
    - [x] API Dart come F12.1.4/F12.1.9 (`Riquadro`, `RigaOcr`, `OcrModo`, `OcrEngine`, `OcrNonDisponibile`, `CanaleOcrEngine`, `FakeOcrEngine`); `flutter analyze` pulito, 29 test Dart verdi
    - [x] Modelli dal venv del banco (RapidOCR 3.10, SHA-256 uguali a quelli di RapidOCR), dizionario dai metadati del modello (502 simboli), Apache-2.0, `modelli_test.dart`, `.gitattributes`
    - [x] Android Kotlin su `ImmagineRgb` (girabile sulla JVM), ORT `strictly("1.28.0")`, 42 test JVM verdi. ⚑ Scostamenti dalla specsheet, imposti dal banco: parametri di RapidOCR 3.10 (`config.yaml`: det lato corto ≥ 736, mean/std 0,5, box_thresh 0,5, BGR), **rettangoli ruotati** (`minAreaRect` riscritto) invece che allineati (righe inclinate perse), riconoscitore a lotti di 6, rilettura capovolta delle righe verticali (al posto del classificatore 0/180)
    - [x] **Parita' con RapidOCR**: numeri `x,yy` ritrovati **242/243 = 99,6%** sui 33 campioni liberi, sia sulla JVM sia sull'emulatore API 35 (98,8% su tutti i 60 sulla JVM)
    - [x] **16 KB**: tutti i segmenti LOAD delle `.so` di ORT 1.28.0 (4 ABI) allineati a 16384; `zipalign -c -P 16 -v 4` verde sugli APK di release. Nessun passaggio a NCNN
    - [x] Guardie: `android/privacy_ocr.gradle` (task `verificaPrivacyOcr`, Groovy: il `.kts` fa crashare lint) provato verde e rosso (INTERNET aggiunto) sull'esempio; `tool/verifica_privacy_android.ps1` verde sull'APK vero e rosso su un APK finto; nessuna stringa di telemetria nel `.so`, manifest dell'AAR senza permessi
    - [x] Release con R8 provata sull'emulatore (`prepara()` 216 ms); `integration_test/ocr_motore_test.dart` verde su emulatore Android e simulatore iPhone (Vision); campioni cancellati da emulatore e Mac
    - [x] `tool/_common.ps1` con `micro_ocr`
    - [ ] Rituale di fine fase (§6): branch di versione, Projects Tracker, voce in `memory/decisioni.md` per gli scostamenti tecnici sopra
  - [x] **F12.2c** Bootstrap `apps/spending_review` (§8.T), icona e splash, manifest, task Gradle `verificaPrivacyOcr` provato in negativo — FATTO il 2026-10-10 (commit e rituale ancora da fare)
    - [x] `flutter create` + bundle `com.smp.spendingreview` ovunque (namespace, applicationId, cartella Kotlin; iOS dal `project.pbxproj` di Film Tracker: solo iPhone, team, varianti `InfoPlist.strings` it/en); nome «Spending Review»; nessun widget, nessuna estensione
    - [x] pubspec commentato (versioni di QR Me, `micro_ocr` per percorso), font OFL, `l10n.yaml`, `tool/testi.py` → ARB (45 chiavi), `app_config` (`spending_review`/`spendingreview`/`spendingreview_pro_lifetime`, seme `#4ADE80`, scuro), `entitlement` (finto a 2,99 €), `feature_limits`, `paywall_config` (5 righe), `providers` (`SrSettingKeys` con `budgetMensile` per D3, senza `preferisciPrezzoCarta` per D4), `routes`, `app`, `labels`, `sr_palette` (valori esatti di F12.1.12), `ProGate`, `main`; `/` per ora mostra solo il totale (pagine in F12.4)
    - [x] Manifest: CAMERA; RECORD_AUDIO, WRITE/READ_EXTERNAL_STORAGE e **POST_NOTIFICATIONS** tolti (`tools:node="remove"`); fotocamera non obbligatoria; `allowBackup=false`; deep link spento (anche iOS). iOS: `NSCameraUsageDescription` e `NSPhotoLibraryUsageDescription` it/en, esclusione di `Documents/` dal backup iCloud in `AppDelegate.swift`
    - [x] Icona e splash da `docs/specs/icona-spending-review.png` con `tool/genera_icone.py` (fondo scuro `#161B22`, sagoma monocromatica con righe ed euro «bucati»), anteprime guardate
    - [x] `verificaPrivacyOcr` dentro `android/app/build.gradle.kts`: verde; **rosso** con un `INTERNET` aggiunto in `src/main` (provato e tolto). ⚑ Ammessa anche `androidx.media3` per il solo ACCESS_NETWORK_STATE (lo porta `camera_android_camerax` via `camera-video`), e tutto il gruppo `datatransport` (anche `transport-runtime`, Play Billing). ☠ Lo script condiviso `packages/micro_ocr/android/privacy_ocr.gradle` (F12.2b) ammette solo `transport-backend-cct`: applicato cosi' a Spending Review farebbe fallire la release; da allineare prima di sostituire il task interno con `apply(from = …)` — **FATTO in F12.4** (2026-10-10): script allineato e task interno sostituito con `apply(from = …)`, verde e rosso riprovati
    - [x] `analyze` pulito, APK di debug compilato (con `micro_ocr`); anche `build apk --release` passa (lint, R8, guardia verde; APK universale 151 MB con ORT e modelli per 4 ABI: per Play si carica l'AAB, che divide per ABI)
    - [x] App avviata sull'emulatore e sul simulatore iPhone — fatto con F12.4 (2026-10-10)
  - [x] **F12.3** Dominio e dati con i test: arrotondamenti, offerte, tastierino, parser con le fixture (33 libere nel repo, 27 fuori), banco con il cricchetto, confronto, statistiche, repository, schema dump — FATTO il 2026-10-10 (210 test verdi; commit e rituale ancora da fare)
    - [x] `lib/domain/`: `Arrotonda` (half-up intero), `Quantita`, `Offerta` (5 sottoclassi, JSON tollerante), `RigaSpesa`, `Spesa` (+ `totaleSalvato`, `livelloBudgetDi`), `TastierinoState` «alla cassa» (D2), `Nomi`
    - [x] `lib/domain/lettura/`: `NumeriOcr` (espliciti, spezzati, fusi; percentuali escluse), `RigheVisive` (fascia media), `CartellinoParser` (doppio prezzo carta come `DoppioPrezzoCarta` + `scegliCarta`, D4), `BilanciaParser`, `ScontrinoParser` (verifica del totale con subtotale e contanti − resto), `UnisciParti`, `TestoOcr`; `Confronto`; `StatisticheSpesa` (+ `BudgetMese`, D3)
    - [x] `lib/data/`: Drift `negozi`/`spese`/`righe` con tutti i CHECK, indice unico parziale `spese_una_in_corso`, chiavi esterne accese; `SpesaRepository` (spese oltre le 5 **nascoste**, mai cancellate: D1); `SpendingBackupSource`; `drift_schemas/drift_schema_v1.json`
    - [x] Fixture: `tool/esporta_fixture_ocr.py` (RapidOCR 3.10, PP-OCRv5 mobile latin, cls acceso), 33 nel repo + `LICENZE.md`, 27 in `microapps-campioni/f12/fixture/ppocrv5/`; pagamento POS di s13 tagliato
    - [x] Banco con cricchetto (`soglie.json`): sui 33 totale scontrino 15/15, bilancia 2/2, prezzo cartellino 12/20; sui 60 totale scontrino 16/16, bilancia 9/9, prezzo cartellino 29/45; parser ≤ 5 ms
    - [x] Test: arrotonda, offerta, riga_spesa, spesa, tastierino, nomi, numeri_ocr, cartellino/bilancia/scontrino parser, unisci_parti, confronto, statistiche, banco, spesa_repository, backup, paywall_config, texts_glyphs
    - [x] Voce in `memory/decisioni.md` per gli scostamenti tecnici (2026-10-10 «scelte del bootstrap e del parser», + «scelte dell'interfaccia» di F12.4) e sezioni F12.1.4/F12.1.8/F12.1.10/F12.1.12/F12.1.14 aggiornate con D3 e D4 (in F12.4)
  - [x] **F12.4** Interfaccia «C · Una mano» completa con i servizi, provata sull'emulatore con foto vere e sul simulatore — FATTO il 2026-10-10 (304 test verdi, `analyze` pulito; commit e rituale ancora da fare)
    - [x] Servizi `lib/services/`: `LetturaService` (+ `RisultatoCartellino`, `ScontrinoLetto` con le giunzioni), `Fotocamera.ritagliaAlMirino` (isolate, EXIF, originale sempre cancellato) + `Obiettivo`/`ObiettivoCamera` (fotocamera sostituibile nei test), `scegliFotoDiSistema`, `CsvExport`, `Aptica`, `ImpostazioniSistema` (canale nostro su Android e iOS, niente plugin); provider per ognuno in `providers.dart`
    - [x] Spesa (`/`): totale enorme (non scala col testo, 64 → 48 sotto i 700 dp), barra del budget verde/ambra/rossa, residuo, lista (piu' recente in alto, scorri = elimina con «Annulla» 5 s, tocco = `RigaSheet`), Cartellino e Scontrino (badge PRO, acquisto → si apre lo scontrino), tastierino sempre visibile (`GrigliaTasti` 4×4, tasti fissi a 48), vibrazioni (tasto, rifiuto, aggiunto, soglie 80/100% una volta per spesa), banner «Spesa iniziata ieri», `BudgetSheet` (+ «usalo anche per le prossime»)
    - [x] Cartellino (`/cartellino`, `?modo=bilancia`): mirino 86% 4:3, velo 55%, interruttore Cartellino|Bilancia, bilancia riconosciuta da sola, torcia, «Da una foto», «Leggo…», suggerimento sullo scritto a mano una volta, permesso negato con «Apri le impostazioni»; fogli `ConfermaCartellinoSheet` (nome, prezzo grande modificabile con un tocco, barrato, €/kg, pillola dell'offerta, quantita' N con NxM, chip alternativi, «Aggiungi (ora 2)», **due bottoni con/senza carta, nessun default** — D4), `SceltaCartellinoSheet`, `PesoSheet` (grammi/kg, anteprima del conto, «Leggi l'etichetta della bilancia»), `ConfermaBilanciaSheet`
    - [x] Scontrino (Pro): mirino verticale 88% 3:5, fino a 4 pezzi con miniature, «Da una foto» multipla, `ConfrontoPage` (card, differenza ambra o «Tutto torna», righe sospette con nota e dettaglio, «Righe che tornano», avvisi quadra/giunzione, scontrino salvato accanto alle contate), `RegistraScontrinoPage` (negozio, data, righe modificabili/eliminabili, stornate barrate)
    - [x] `ChiusuraPage` (totale, esito del budget, fonte scontrino/contate, negozio con chip dei recenti + «Altro…», data, snack del gratis oltre le 5, «Butta via»), `StoricoPage` (per mese, pallino ambra/rosso, card delle nascoste), `DettaglioSpesaPage` (lucchetto per le nascoste, negozio/data modificabili, elimina), `StatistichePage` (mese, **budget del mese** con tetto — D3, 4 tessere, grafico 6 mesi `CustomPainter` con `Semantics`, tabella per negozio mese/12 mesi), `ImpostazioniPage` (budget abituale, vibrazione, negozi, tema, Pro, dati, informativa, licenze PaddleOCR/RapidOCR/ORT solo Android + font), `NegoziPage`, `OcrDevPage` (solo debug/SR_DEV)
    - [x] Router completo (`buildRouter(devAttiva:)`, tutte le rotte figlie di `/`), `OcrEngine.prepara()` 3 s dopo il primo frame, licenze registrate in `main`; 283 chiavi di testo (`tool/testi_schermate.py`)
    - [x] Guardia condivisa `privacy_ocr.gradle` allineata (gruppo datatransport, media3 solo per ACCESS_NETWORK_STATE, INTERNET stretto) e applicata con `apply(from = …)`: release verde, rossa con INTERNET di prova (tolto); `noCompress onnx` nel modulo app
    - [x] Emulatore (Medium Phone API 35): tastierino (2,49; 3 × 1,50), mirino sulla scena virtuale (nessun prezzo, nessuna foto rimasta in cache), cartellino c11 dalla galleria («quale?» fra due proposte, al kg → peso 500 g = 0,95), bilancia b07 riconosciuta da sola (1,082 × 1,59 = 1,72), paywall 2,99 € e Pro finto, scontrino s06 dalla galleria → confronto → chiusura → storico → statistiche, tema chiaro al 130%; campioni cancellati dall'emulatore. Simulatore iPhone 18 Pro Max: build e avvio, schermata principale in italiano
    - [x] Trovato e corretto sull'emulatore: «T*talE PARZIALE» (OCR) letto come articolo → `t.?tale\s*parziale` nel parser (test `scontrino_subtotale_test.dart`, banco invariato)
  - [x] **F12.5** Pro: limiti, paywall, `ProGate` sulle pagine, test di coerenza — FATTO il 2026-10-10: `ProGate` sulle rotte `/scontrino` (+ confronto e registrazione) e `/statistiche`; spese nascoste col lucchetto anche da link diretto; badge PRO su Scontrino, Statistiche, backup, CSV (ripristino gratis); test `pro_gate_test.dart`, `storico_page_test.dart`, `paywall_config_test.dart` (esistente)
  - [x] **F12.6** Grafica (gia' scelta, «C · Una mano», applicata in F12.4): tema chiaro derivato e `palette_contrast_test.dart` (AA in entrambi i temi) — FATTO il 2026-10-10; [ ] conferma del proprietario sugli scatti scuro/chiaro
  - [~] **F12.7** Test, rifinitura, iOS su iPad via TestFlight, fixture di Vision, **taratura con le foto vere del proprietario**, misure di prestazione su un Android vero, controllo privacy sull'APK di release — parte da qui FATTA il 2026-10-10 (336 test verdi, `analyze` pulito); restano iPad/TestFlight (serve l'App ID del proprietario), le foto vere del proprietario e un Android vero
    - [x] **Banco sui ritagli del mirino** (il caso d'uso vero: un cartellino inquadrato, 4:3): `test/fixtures/ocr/ritagli_mirino.json` (47 ritagli fatti a mano, coordinate sole, immagini fuori dal repo; esclusi i 7 scritti a mano), `tool/esporta_fixture_ocr.py --ritagli` (ritaglio in memoria) → motore `ppocrv5-mirino` (20 nel repo, 27 fuori) col suo cricchetto. Il banco ora carica le private per ogni cartella di motore
    - [x] Parser del cartellino migliorato (prima → dopo, PP-OCRv5): **ritagli 47** prezzo 32 → **36/40**, al kg 16 → **19/22**, offerte 4 → **9/10**, pieno 2 → **6/6**, nome 14 → **25/39** (metrica nuova); **foto larghe 60** prezzo 29 → **33/45**, al kg 15 → **17/27**, offerte 3 → **8/10**, pieno 3 → **6/6**. Regole: contesto spezzato al separatore nelle righe con piu' numeri («250 g: 1,89 € - Soit le kg: 7,56», c11), «/ k9» e «ol ku», «AILC.12,80», etichetta «Al kg» del valore illeggibile, quantita' «1/kg», NxM col prezzo «anziche'» (anche senza il prezzo grande, «3*1»), al kg coerente col prezzo effettivo, coppia pieno/scontato legata dalla percentuale (prezzo dinamico c33, anche come ancora unica), «SCONTO 40» senza «%», bollino senza prezzo (proposta col solo sconto), «0.99-», «(23%», nome sotto il prezzo (Esselunga), lettere cirilliche gemelle (Vision), ancore al 60%. Restano errori solo dove l'OCR non legge il numero (c02 stilizzati, c12 LCD, «L.» di c09, al kg di c13, «-30» di c32)
    - [x] Bilancia: nome del prodotto = scritta piu' grande, niente insegne/offerte/codici: PP-OCRv5 2 → **5/9** con la metrica nuova `bilancia.prodotto` (a occhio 7/9). Scontrino: totale senza importo chiude il corpo (Vision s01), asterischi in coda tolti, `negozioMostrato` senza punteggiatura finale. X delle miniature dello scontrino sulla foto (Center + Stack della misura della foto)
    - [x] **Vision misurato sul parser** (simulatore iPhone 18 Pro Max, 107 immagini = 60 intere + 47 ritagli, banco `micro_ocr` d'esempio, log → `esporta_fixture_ocr.py --log` → motori `vision-sim` e `vision-sim-mirino`, 33+20 nel repo): ritagli prezzo **33/40** (PP 36), al kg 16/22 (PP 19), offerte 9/10, pieno 4/6 (PP 6), nome 24/39; foto intere prezzo 31/45 (PP 33), al kg 11/27 (PP 17), **totale scontrino 14/16 (PP 16)**, **totale bilancia 7/9 (PP 9)**, peso 5/9 (PP 8). Tempi Vision sul simulatore: mediana 371 ms, max 661 ms. ⚑ Raccomandazione: non cambiare ancora motore; misurare sull'iPad (TestFlight) con le stesse 107 immagini; se il distacco sui totali di bilancia e scontrino resta, ORT 1.28 anche su iOS (decisione 2026-10-10, +22 MB) — decide il proprietario
    - [x] ☠ Trovato: Vision legge il PAN mascherato con le «x» (s13): pulizia delle fixture rinforzata (`RIPULISCI`, `INIZIO_POS`) e controllo del banco esteso a `x{4,}\d{4}`. ☠ `debugPrint` throttled perdeva le ultime righe del banco sul dispositivo: l'esempio usa `print`
    - [x] Flussi provati con OCR vero, database vero e foto dei campioni (`integration_test/flussi_test.dart`, `SR_FOTO` fuori dal repo, selettore di sistema sostituito): cartellino 3,59 → bilancia 7,71 (totale 11,30) → scontrino Emme Piu' 6,15 → confronto → chiusura → storico, copie temporanee sparite. iOS simulatore: 0,54 / 0,96 / 0,45 s; emulatore Android (PP-OCRv5): 0,95 / 0,99 / 1,14 s. Parser: max 4,8 ms (banco sul PC)
    - [x] Emulatore a mano: testo al 130%, tema chiaro, spesa vuota e storico vuoto, permesso fotocamera negato («La fotocamera e' spenta» + «Apri le impostazioni» che apre davvero le impostazioni + «Da una foto»), spesa col tastierino 2,49 + 2,22 = 4,71 → chiusura → storico; emulatore riportato al 100%. ~~⚑ L'APK debug avviato da solo resta sullo splash (VM in attesa del debugger)~~ — **chiarito in F12.8: non e' un difetto dell'app** (vedi F12.8 e `apps/spending_review/codebase_reference.md` §14.2): l'APK di debug vero parte da solo; restano sullo splash la build di un test d'integrazione (installata da `flutter test integration_test/…`, che sovrascrive anche `app-debug.apk`) e un'attivita' avviata con `start-paused`
    - [x] Esclusione dal backup iCloud verificata sul simulatore: `com_apple_backup_excludeItem` su `Documents/`, `Documents/spending_review/` e (dal secondo avvio) `spending_review.sqlite`. Fuori dall'esclusione: `Library/Application Support/spending_review/logs` e le preferenze (budget, tema)
    - [x] Release: `build apk --release` (167 MB, APK con tre ABI) con `verificaPrivacyOcr` verde; `verifica_privacy_android.ps1` verde dopo aver corretto un **falso positivo**: «1DS» compariva nel codice macchina ARMv7 di ORT (istruzioni Thumb), non come stringa; ora le stringhe corte contano solo dentro stringhe stampabili di 8+ caratteri (provato rosso su un APK finto con «Microsoft 1DS SDK»). Esempio di `micro_ocr` ricompilato (Android debug, iOS simulatore)
    - [ ] TestFlight su iPad e banco Vision sull'iPad; [ ] foto vere del proprietario (fixture fuori dal repo, cricchetto); [ ] misure F12.1.18 su un Android vero di fascia media (avvio a freddo, memoria, `--split-per-abi --analyze-size`)
  - [x] **F12.8** Atlanti `apps/spending_review` e `packages/micro_ocr` (+ `micro_core` e cinque app per `documentScan`), `verify_atlas` 0 mancanti — FATTO il 2026-10-10 (341 esiti: 339 verdi + 2 saltati di proposito, `analyze` pulito; commit e rituale ancora da fare, F12.9)
    - [x] **Difetto «APK di debug fermo sullo splash» (F12.7) indagato sull'emulatore** (Medium_Phone_API_35): **non e' dell'app**. L'APK di debug vero, avviato da solo (`am start` e launcher, 5 avvii a freddo, anche con una spesa aperta), arriva al tastierino come QR Me debug. Riprodotte le due cause vere: (a) **build di un test d'integrazione** — `flutter test integration_test/flussi_test.dart -d …` installa `com.smp.spendingreview` col TEST come entrypoint e sovrascrive `build/app/outputs/flutter-apk/app-debug.apk`; senza `SR_FOTO` il test esce senza `runApp` e lo splash resta, anche con un intent pulito dal launcher; (b) **`--ez start-paused true`** (`flutter drive`, `run --start-paused`): la VM attende il debugger, e il task conserva l'intent radice con l'extra, quindi anche l'icona dopo un `am kill` riapre in pausa. Rimedi (documentati come trappola nell'atlante §14.2): rifare `build apk --debug` dopo un test d'integrazione; `am force-stop` o togliere l'app dalle recenti. Nessun codice cambiato per questo; emulatore lasciato con l'APK di debug vero
    - [x] `apps/spending_review/codebase_reference.md` nuovo (~3200 righe): decisioni, «dove sta cosa», albero, nativo, tabelle Drift con vincoli/indici/sicurezza, ogni classe con ogni membro (**firme estratte a macchina dall'AST** con un estrattore basato su `package:analyzer`, effetti scritti a mano, copertura controllata: 0 classi/dichiarazioni/effetti mancanti), rotte con guardie/argomenti/errori, configurazione (dart-define, preferenze, identificativi, SKU, permessi, testi, dipendenze, comandi), catalogo dei test (ogni file, banco con motori `ppocrv5`/`ppocrv5-mirino`/`vision-sim`/`vision-sim-mirino`, cricchetto, `SR_CAMPIONI`, `SR_FOTO`, impianto), regole e trappole, cosa NON esiste, debito, differenze dalla specsheet, perche'
    - [x] `verify_atlas`: **0 non documentati** per `apps/spending_review` (143 simboli; i 96 «citati ma assenti» controllati a mano: solo terze parti, costanti di piattaforma, dart-define, doppi dei test, costanti dello script Python), `packages/micro_ocr` (7), `packages/micro_core` (84), Full Freezer, Scorte Calore, Film Tracker, QR Me. ☠ **TrashCan ha 11 non documentati gia' prima di F12.8** (`CollectionCalendars`, `CollectionExceptions`, `RecurrenceRules`, `OccurrenceOrigin`, `RuleEditorPage`, `TrashcanApp`, `WastePalette`, `WastePreset`, `WeekdayPicker`, `LEn`, `LIt`): debito del suo atlante, fuori da F12
    - [x] **Firme confrontate a macchina**: Spending Review **945** firme e testate delle tabelle, **926 identiche** al sorgente normalizzato + **19 inizializzatori lunghi troncati di proposito** identici fino ai puntini, **0 diverse** (piu' 1115 frammenti fra apici in tutto l'atlante: 1000 identici, 115 sono espressioni citate nel testo, controllate a mano). `micro_ocr`: 112 frammenti, 32 Dart identici; resi letterali i 5 costruttori Dart scritti in forma tipizzata; il resto e' Kotlin/Swift/Gradle. `micro_core`: 177 frammenti, 90 identici, il resto forme abbreviate dell'atlante di F1 (campione controllato: coerenti)
    - [x] `packages/micro_ocr/codebase_reference.md`: la usa Spending Review; regola «1DS» dello script sul binario (stringhe corte solo dentro stringhe stampabili di 8+ caratteri); `print` e non `debugPrint` nell'esempio; fixture di Vision del simulatore esistenti (iPad ancora no); debito aggiornato. `packages/micro_core/codebase_reference.md`: `FeatureKey` a **16** valori, riga `documentScan`, colonne riverificate sui `feature_limits.dart` delle **sei** app. Una riga `documentScan` negli atlanti di TrashCan, Full Freezer, Scorte Calore, Film Tracker, QR Me («15» → «16» in QR Me)
    - [x] **Difetti trovati rileggendo il codice e corretti con un test** (rosso prima, verde dopo): (1) `CartellinoCameraPage._daUnaFoto` perdeva gli errori inattesi del motore (nessun messaggio) → snack `cartellino_scattoFallito` (`cartellino_camera_test.dart` +1); (2) `ScontrinoParser._data` restituiva null alla prima data non plausibile anche con la data vera dopo → si salta (`scontrino_parser_test.dart` +1, banco invariato); (3) `SpendingBackupSource.importPayload` con un campo di testo di tipo sbagliato lanciava `TypeError`, che `BackupService.restore` (solo `on Exception`) non intercetta → `_testoONull` con `FormatException` (`backup_test.dart` +1); (4) commenti superati in `routes.dart` (`LetturaScontrino` → `ScontrinoLetto`; il lucchetto del dettaglio). Messi nel debito dell'atlante (§15.2): cancellazione delle copie del selettore senza il controllo della cartella in `ScontrinoCameraPage`; `_salva` senza `catch` nelle pagine dello scontrino
  - [x] **F12.9** Rituale di fine fase, card «In arrivo» in vetrina, StatusMicroApps con entrambi gli store, branch di versione nuovo — FATTO il 2026-10-10: piano, atlanti (Spending Review, micro_ocr, micro_core, cinque app), StatusMicroApps, README, decisioni, Projects Tracker, branch `v10.0.0`. Card «In arrivo» **pronta in locale, pubblicazione da confermare** dal proprietario

**Ripresa F12 (stato al 2026-10-10, sera).** Spending Review e' completa come codice: 339 test, analisi pulita, release Android con guardie di privacy verdi (ORT 1.28.0, niente telemetria, 16 KB ok), flussi provati sull'emulatore e sul simulatore iPhone. Restano:
  1. **Proprietario:** App ID `com.smp.spendingreview` (niente App Group) e app su App Store Connect; poi profilo via API, TestFlight, scheda completa via API.
  2. **Sull'iPad:** misurare Vision sulle 107 immagini del banco; se resta sotto PP-OCRv5 su bilancia e scontrino, valutare ORT 1.28 anche su iOS (+22 MB, decisione del proprietario).
  3. **Foto vere** del proprietario (bilance italiane, catene mancanti: `microapps-campioni/f12/LEGGIMI.md`) per tarare il parser; misure su un Android vero di fascia media.
  4. Play: dopo il D-U-N-S, come le altre app; riga `spendingreview` nel License Server.
  5. Debito minore (atlante §debito): copie del selettore nello scontrino, `catch` nei `_salva`, log e preferenze fuori dall'esclusione iCloud, gli 11 simboli non documentati nell'atlante di TrashCan.
- [ ] **F13** Fair Share (ex «Quanto dividiamo?») — divisione del conto
- [ ] **F14** Geo Note (ex «Ricordamelo qui») — promemoria per luogo (geofencing, permesso in background)
- [-] **F15** ~~Quanti sono?~~ — **ANNULLATA il 2026-10-11** dal proprietario: «non la facciamo proprio, sarebbe troppo inaffidabile senza ai seria»
- [ ] **F16** TLDR (ex «Riassumilo») — riassunto da Share Sheet (**decisione sull'AI prima di F16.0**)
- [x] **F17** QR Me (ex «Fammi un QR») — CHIUSA il 2026-10-09 → `v9.0.0` (codice completo Android e iPhone, 182 test; store da fare, vedi la ripresa sotto)
  - [x] **F17.0** Decisioni di partenza con il proprietario — FATTO il 2026-10-09 (§8 F17.0): nome «QR Me» in it ed en, `com.smp.qrme`, Android e iPhone, moduli Wi-Fi/contatto/email/SMS/telefono, **lettura dei QR gratis**, stile con colori e logo (foto, icone, emoji/testo), base generosa con Pro **1,99 €**, cronologia 5 gratis e spegnibile, 1 preferito gratis, nessun widget, icona dal proprietario
  - [x] **F17.1** Specsheet — FATTO il 2026-10-09 (§8 F17.1): file, dipendenze, dominio con codifiche esatte, tabella, rotte, schermate, servizi, `micro_share`, Pro, permessi, trappole, test
  - [x] **F17.2a** `FeatureKey.imageExport` in `micro_core` + una riga nelle quattro app — FATTO il 2026-10-09: test di micro_core e delle quattro app verdi (121/185/140/158/130)
  - [x] **F17.2b** `packages/micro_share/` + `tool/aggiungi_share_extension_ios.rb` — FATTO il 2026-10-09: package (20 test, atlante proprio, aggiunto a `tool/_common.ps1`); **script Ruby eseguito sul Mac su `apps/qr_me` il 2026-10-09, due volte** (idempotente: la seconda non cambia niente). ☠ Da ssh Ruby leggeva i file in US-ASCII e moriva sugli Info.plist accentati: serviva `Encoding.default_external = UTF_8`, gia' corretto nello script. Build per il simulatore riuscita, l'appex **non incorpora** la cartella Frameworks. ☐ **Nota aperta** (non blocca la chiusura): la riapertura dell'app dall'estensione va provata su iPad via TestFlight (serve l'App Group dal proprietario). ☠ Il pacchetto Swift del plugin sta in `.packages/receive_sharing_intent-<versione>`: lo script legge la versione dal `pubspec.lock` e va rilanciato a ogni aggiornamento del plugin
  - [x] **F17.2c** Bootstrap `apps/qr_me`, icona e splash — FATTO il 2026-10-09: `com.smp.qrme` Android e iOS (solo iPhone), manifest con ACTION_SEND testo e immagini, `allowBackup=false`, niente READ_EXTERNAL_STORAGE, icone dall'originale del proprietario (iOS su #F3F7F3, adattiva e monocromatica Android), APK debug compilato
  - [x] **F17.3** Dominio e dati, con test — FATTO il 2026-10-09: `lib/domain/*`, `lib/data/*`, 95 test. Decisioni minori: `QrDecoder.decodeTyped` per il testo scritto (`esempio.it` → link), `decode` per il letto (resta testo); paywall con 6 righe (una per chiave). Debito: esclusione del database dal backup iCloud (serve codice nativo, F17.7)
  - [x] **F17.4** Interfaccia essenziale, provata con condivisioni vere — FATTO il 2026-10-09: servizi (`QrRenderer` unico traduttore stile→qr_flutter, `LogoRenderer`, `ReadabilityCheck` con ML Kit che funziona anche sull'emulatore (dal 2026-10-09 ZXing, F17.7.7), `ScreenBoost`, `ShareRouter`/`ShareIntake`, `ContentActions`), tutte le pagine, grafica Neon (`lib/app/qr_palette.dart`, `features/common/neon.dart`, Space Grotesk), 142 test; provate sull'emulatore la condivisione di testo (app aperta e chiusa), moduli, stile, PNG, paywall. ☠ `receive_sharing_intent` 1.9.0 dichiara `compileSdk 37` che AGP 9 non trova: `finalizeDsl { compileSdk = 36 }` in `android/build.gradle.kts` dell'app (da ripetere in ogni app con `micro_share`). Non provati: immagine condivisa con un QR vero, fotocamera reale, backup
  - [x] **F17.5** Pro: limiti, paywall, test di coerenza — FATTO il 2026-10-09: chiavi verificate punto per punto, il gesto che apre il paywall prosegue dopo l'acquisto
  - [x] **F17.6** Proposte grafiche, scelta del proprietario — scelta «A · Neon» il 2026-10-09 (F17.0 punto 10), applicata insieme a F17.4
  - [x] **F17.7** Test, rifinitura, iOS sul simulatore, decisione su ML Kit — FATTO il 2026-10-09 (155 test a fine F17.7; 182 dopo le correzioni di F17.8). ☐ **Note aperte, prove su dispositivo vero** (non bloccano la chiusura): lettura dal vivo con la fotocamera su un telefono Android; su iPad via TestFlight riapertura dall'estensione, esclusione dal backup a runtime, lettura ZXing, avviso del microfono all'upload. **ML Kit sostituito da ZXing il 2026-10-09, decisione del proprietario** («niente dati a Google, assolutamente»; F17.7.7):
    - [x] **F17.7.1** Doppio segno nella riga di verifica: nei testi (ARB e `tool/testi_*.py`) non c'era nessun ✓/⚠/✗, il segno e' gia' solo l'icona (verificato sull'emulatore); aggiunta la guardia `test/widget/texts_glyphs_test.dart`
    - [x] **F17.7.2** Loghi foto orfani: `QrRepository.pruneOrphanLogos({Duration grace})` (salta i file degli ultimi 15 minuti, tiene immagini **e** miniature in uso), chiamata 3 s dopo il primo frame in `QrMeApp`; provata sul dispositivo (2 file vecchi tolti, quello nuovo lasciato) e con 2 test
    - [x] **F17.7.3** Backup iCloud: `isExcludedFromBackup` su `Documents/` (database `qr_me.sqlite` e `qr_me/images`) a ogni avvio in `ios/Runner/AppDelegate.swift`. **Compilato e verificato sul simulatore il 2026-10-09**: `Documents/` e `qr_me.sqlite` hanno l'attributo `com_apple_backup_excludeItem`
    - [x] **F17.7.4** ML Kit: verificato (bundled `barcode-scanning:17.3.0`, invia metriche d'uso non spegnibili; iOS usa Vision, nulla esce). Decisione del proprietario il 2026-10-09: **via ML Kit, si passa a ZXing** (F17.7.7) — `memory/decisioni.md` «QR Me: ML Kit», F17.1.10
    - [x] **F17.7.5** Rifinitura sull'emulatore: testo al 130% (corretto «Nessun/o» spezzato nei segmenti del logo), tema chiaro (accento #16A34A → #15803D per il contrasto AA, titolo della pagina di lettura invisibile corretto; test `palette_contrast_test.dart`), condivisione di un PNG con un QR vero da Google Foto ad app chiusa e aperta, «Da immagine» col selettore di sistema, backup → cancella cronologia → ripristino
    - [x] **F17.7.6** iOS sul simulatore/iPad (sul Mac): build, esclusione dal backup, estensione di condivisione, lettura con ZXing (fotocamera vera e «Da immagine»), e controllo che App Store Connect non chieda `NSMicrophoneUsageDescription` (vedi F17.1.10) — parte simulatore FATTA il 2026-10-09: script dell'estensione eseguito, **build per il simulatore riuscita** (Swift di `AppDelegate` compilato, appex senza Frameworks). ☐ **Note aperte su iPad via TestFlight**: esclusione dal backup a runtime, riapertura dall'estensione, lettura con ZXing (fotocamera vera e «Da immagine»), `NSMicrophoneUsageDescription` al primo caricamento
    - [x] **F17.7.7** ML Kit sostituito da ZXing il 2026-10-09, decisione del proprietario — FATTO il 2026-10-09: `mobile_scanner` tolto, `flutter_zxing` 3.1.0 (+ `camera` 0.12.1 diretta) su Android **e** iOS; `ScanPage` su `ReaderWidget` (F17.1.6), `ZxingImageReader` e `ZxingImageReader.strict` (F17.1.7), manifest ripulito (F17.1.10). Verificato: nessuna dipendenza `com.google.mlkit` risolta, nessun servizio ML Kit nel manifest fuso. ⚠ `datatransport`/`firebase-encoders`/`play-services-*` restano, ma li porta **Play Billing** (`com.android.billingclient:billing:8.0.0` via `in_app_purchase_android`), non lo scanner: riguarda tutte le app con il Pro su Android (F17.1.10). Provati sull'emulatore: pagina di lettura (anteprima, mirino, torcia, ritorno dal risultato che riaccende la fotocamera), permesso negato → stato vuoto, «Da immagine» con un PNG vero → «Link smpmicroapps.it», condivisione da Google Foto → risultato, Stile col Pro finto → «Leggibile» (bianco su bianco → «Non riesco a leggerlo»; chiaro su scuro → non leggibile per scelta, `strict`). ☐ Lettura dal vivo con la fotocamera **non** provata (la scena virtuale dell'emulatore non mostra un QR): da fare su un telefono vero
  - [x] **F17.8** Atlanti di `apps/qr_me` e `packages/micro_share` — FATTO il 2026-10-09: `apps/qr_me/codebase_reference.md` (~1800 righe alla rilettura, ~1970 con le correzioni sotto); `verify_atlas` **0 mancanti** per `apps/qr_me` e `packages/micro_core`; firme confrontate a macchina (380 frammenti estratti dall'atlante, 277 identici al codice, il resto chiamate o frammenti descrittivi verificati a mano). **Difetti trovati rileggendo e corretti** (27 test nuovi, 182 verdi, `analyze` pulito, `build apk --debug` ok): (1) «Rigenera con stile» dal risultato della lettura ignorava lo stile — ora `ScanResultPage._style` e `/show` con lo stile applicato; (2) `QrCodeToDomain.content` con campi sbagliati — **falso allarme** (gia' ripiegava), commento esplicito e 9 test di guardia; (3) `ContentActions.open` con `uriFor` fuori dal try — spostato dentro, non lancia mai; (4) testo condiviso/scritto ricodificato perdeva i campi (vCard con ADR, MECARD) — `QrEncoder.payloadOfTyped`, il testo tal quale; (5) commenti superati in `locale_resolution.dart` (codice giusto, commento rovesciato; le altre app hanno ancora il commento vecchio), `flutter_native_splash.yaml`, `pubspec.yaml`; (6) tolti i non usati: rotta `/pro`, `favoriteCountProvider` (+ `watchFavoriteCount`), chiavi `common_optional`, `show_title`, `form_title`; (7) Android: «Apri le impostazioni» con il permesso fotocamera negato via `MethodChannel` nostro in `MainActivity.kt` (nessuna dipendenza nuova), piu' «Riprova». Aggiornati anche l'atlante di `micro_share` (DT-S1 chiuso, trappole `compileSdk 37` e US-ASCII) e F17.2b qui
  - [x] **F17.9** Rituale di fine fase, card «In arrivo», branch `v9.0.0` — FATTO il 2026-10-09: card «In arrivo» pubblicata su smpmicroapps.it col via del proprietario (siti critici a 200 prima e dopo), piano, atlanti (QR Me, micro_share, micro_core, sito), StatusMicroApps, README e decisioni aggiornati, documenti nel Projects Tracker (progetto 17), branch `v9.0.0`

  - [x] **F17.10** Revisione del proprietario dopo la prova su iPad (§8 F17.10): Wi-Fi da QR letto o dalla rete connessa, Contatto dalla rubrica o «Io», «Email precompilata» con testo grande, via SMS e Telefono, Pro «Genera etichetta»; correzioni: «Etichetta» solo icona, scheda «Io» nel backup; poi store rifatto con la build 1.0.0 (2)
    - [x] **F17.10.1** Wi-Fi senza compilare a mano — FATTO il 2026-10-09: `/form/wifi` nuovo parte da `WifiSources` (`lib/features/forms/wifi_sources.dart`) con tre strade e «Inserisci a mano» in fondo, piccolo. (1) «Inquadra il QR della rete» → `/scan/wifi` = `ScanPage(wifiOnly: true)`, che torna (`pop`) con il `WifiContent` letto e a un QR non di rete dice «Questo QR non è di una rete Wi-Fi» e continua a inquadrare; (2) «Da un'immagine» → `pickImageProvider` + `QrImageReader`, la rete fra piu' QR con `QrDecoder.firstWifi`; senza rete: messaggio, nessun salvataggio; (3) «La rete a cui sei connesso» → `WifiNameReader` (`lib/services/wifi_name_reader.dart`: `network_info_plus` + `permission_handler`), spiegazione **prima** del dialogo del sistema, permesso solo al tocco; nome letto → `WifiForm(pasteHelp: true)` con «Incolla la password» grande e le istruzioni iPhone/Android; nome non letto (negato, negato per sempre con «Apri le impostazioni», localizzazione spenta, non disponibile/simulatore) → riquadro con il perche' e «Inserisci a mano». QR letto → salvato e mostrato subito (`/qr/:id`), poi Stile come sempre. Android: `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` + `uses-feature gps required=false`; iOS: `NSLocationWhenInUseUsageDescription` in Info.plist e InfoPlist.strings it/en. ☐ **iOS**: entitlement `com.apple.developer.networking.wifi-info` (capability «Access Wi-Fi Information» sull'App ID, profilo rigenerato) — lo aggiunge il proprietario/orchestratore; senza, su iPhone il nome non si legge e compare il riquadro «non riesco a leggere»
    - [x] **F17.10.2** Contatto dalla rubrica o «Io» — FATTO il 2026-10-09: `ContactSources` (`lib/features/forms/contact_sources.dart`): «Scegli dalla rubrica» con `ContactPicker` (`flutter_native_contact_picker` 0.0.12, selettore di sistema, **nessun permesso contatti**; da' nome e telefono, l'email si aggiunge nel modulo che si apre gia' compilato); «Io» → scheda salvata una volta nelle preferenze (`myContactProvider`, chiave `QrSettingKeys.myContact`) e riusata: QR subito; la prima volta apre `/me` (`MyContactPage`, Pro `customCategories`: scelta dalla rubrica o compilata, «Salva», «Elimina»), modificabile dalla matita nel modulo e dalle Impostazioni (riga «La mia scheda» nella sezione Moduli). Provato sull'emulatore con un contatto vero nella rubrica (il selettore e' FLAG_SECURE: screenshot neri, navigato con `uiautomator dump`)
    - [x] **F17.10.3** «Email precompilata» — FATTO: `kind_email` = «Email precompilata» / «Pre-filled email» (chip, titolo, righe), testo con `minLines: kEmailBodyMinLines` (6), `maxLines: null`, etichetta in alto (`alignLabelWithHint`)
    - [x] **F17.10.4** Via i moduli SMS e Telefono — FATTO: `kFormKinds = [wifi, contact, email]`, `sms_form.dart`/`phone_form.dart` cancellati, chiavi `sms_number`/`sms_body`/`phone_number` tolte; `formKindOf('sms'|'phone')` → null («Non trovato»); lettura invariata (decoder, «Manda SMS»/«Chiama»), i preferiti SMS/Telefono gia' salvati si mostrano senza «Modifica»
    - [x] **F17.10.5** Pro «Genera etichetta» — FATTO: azione «Etichetta» (`action_label`, icona stampante, lucchetto senza Pro) nella barra della pagina del QR (non nella griglia: una sesta azione stringeva le etichette sotto i 60 dp e una seconda riga rubava altezza al QR); `/label` = `LabelPage` dietro `ProGate(imageExport)`, `openLabel` controlla il Pro prima; `LabelPainter`/`LabelRenderer` (`lib/services/label_renderer.dart`): un solo disegno per anteprima, PNG (1200 px di larghezza) e PDF (etichetta alla misura vera, 70×70 mm quadrata o 60×90 mm rettangolare, in alto al centro del foglio scelto, filo grigio per ritagliare); testo di partenza = titolo del QR, 1-2 righe che si rimpiccioliscono, colore del QR; «Stampa» con `printing` (dialogo di sistema), «Condividi immagine» con `share_plus` (`LabelOutput`). `QrRenderer.paintSquare` nuovo (anche `png` passa da li'). Paywall: «Condividi il QR come immagine o come etichetta da stampare» / «Share the QR code as a picture or as a printable label»; riga dei moduli aggiornata («Wi-Fi, contatti ed email precompilate»)
    - [x] **F17.10.6** Testi e verifiche — FATTO: testi in `tool/testi.py` e `tool/testi_forms.py` → ARB (246 chiavi) → `gen-l10n`; nessun glifo ✓⚠✗. **228 test verdi** (+45: `wifi_sources_test.dart` 14, `contact_sources_test.dart` 10, `label_test.dart` 12, `form_page_test.dart` +5, `home_page_test.dart` +1, `display_page_test.dart` +3), `analyze` pulito, `build apk --debug` ok. Pacchetti controllati nel sorgente in pub cache (nessun SDK di analytics/telemetria/Firebase/ML Kit, nessuna rete): `network_info_plus` 8.2.1, `permission_handler` 12.0.1 (☠ **non** la 13: porta `permission_handler_android` 14 che vuole compileSdk 37 e il build falliva in `checkDebugAarMetadata`), `flutter_native_contact_picker` 0.0.12, `printing` 5.15.1, `pdf` 3.13.1. Manifest fuso: nuovi solo i permessi di posizione, `ACCESS_WIFI_STATE` e il `PrintFileProvider`; `datatransport` c'era gia' (Play Billing, F17.7.7). Provato sull'emulatore (Medium_Phone_API_35): spiegazione → permesso «mentre usi l'app» → **SSID «AndroidWifi» letto**, password incollata, QR; «Da un'immagine» con uno screenshot di un QR Wi-Fi (→ QR) e con un QR non di rete (→ messaggio); `/scan/wifi` con «Da immagine» (→ torna e mostra); contatto dalla rubrica (→ modulo compilato); «Io» compilata e salvata (→ QR, scheda nelle preferenze, riga nelle Impostazioni); Email precompilata con testo lungo; etichetta quadrata e rettangolare con testo su due righe, con stile e logo; «Stampa» (anteprima di stampa A4 con l'etichetta in alto) e «Condividi immagine» (foglio di sistema); testo al 130% e tema chiaro e scuro. ☐ Fotocamera dal vivo su un QR vero e tutto il giro su iPhone/iPad (permesso posizione, entitlement, selettore `CNContactPickerViewController`, `UIPrintInteractionController`)
    - [x] **F17.10.6b** Due correzioni dopo la rilettura del codice — FATTO il 2026-10-09: (1) **«Etichetta» solo icona**: nella barra della pagina del QR il `TextButton.icon` con la scritta «Etichetta» al 130% di testo mangiava il titolo («Email precomp…»); ora e' un `IconButton` (`action_label`, chiave invariata) con `Icons.print_outlined`, `tooltip` e `semanticLabel` «Etichetta»/«Label», e senza Pro un `Badge` con un piccolo lucchetto (`ValueKey('lock')`) su fondo accento Neon. +8 test in `display_page_test.dart` con il **font vero** dei titoli (`SpaceGrotesk` caricato con `FontLoader`) su un telefono di 412 dp al 130%: «Email precompilata», «Contatto», «Wi-Fi», gratis e Pro, il titolo non si tronca (i 2 casi «Email precompilata» falliscono col vecchio pulsante: verificato); tooltip/semantica; lucchetto solo senza Pro. (2) **La scheda «Io» nel backup**: `QrBackupSource(db, {paths, settings, clock})` esporta il campo **facoltativo** `myContact` (`ContactContent.toFields()`; `schemaVersion` resta 1, i backup vecchi senza il campo restano validi); al ripristino, validata prima della transazione (rotta → FormatException, niente cambia) e scritta dopo: telefono senza scheda → la si imposta; entrambe → vince il telefono in «Aggiungi», il file in «Sostituisci tutto»; backup senza campo → la scheda del telefono resta anche con «Sostituisci tutto». `data_section.dart` passa `settingsProvider` e dopo il ripristino fa `ref.invalidate(myContactProvider)`. +5 test in `qr_backup_test.dart` (round-trip ZIP in entrambe le modalita', precedenze, backup vecchio, scheda illeggibile, scheda rotta). **241 test verdi**, `analyze` pulito, `build apk --debug` ok. Atlante `apps/qr_me/codebase_reference.md` aggiornato per tutto F17.10 (servizi, pagine, rotte, provider, pacchetti, permessi, trappole, test), `verify_atlas` 0 non documentati, 32 firme nuove confrontate a macchina col codice
    - [x] **F17.10.7** Store rifatto con la build 1.0.0 (2) — FATTO il 2026-10-09: build 2 collegata, 6 scatti per lingua (anche l'etichetta e le tre strade del Wi-Fi), video, grafiche, testi e note di revisione ricaricati e verificati via API. ☠ Col Pro in READY_TO_SUBMIT Apple rifiuta via API la descrizione (409 UNMODIFIABLE) e lo screenshot di revisione (409 MEDIA_ASSET_DELETE_NOT_ALLOWED): a mano dal proprietario

✅ **BUG CHIUSO il 2026-10-11 (TrashCan 1.0.1 su entrambi gli store, provato dal proprietario su Android: a mezzanotte il widget ha cambiato rifiuto da solo; resta la prova su iPad).** Era: ☠ BUG APERTO — PRIORITA' 1 (segnalato dal proprietario il 2026-10-10, ore 3): il **widget di
TrashCan non si aggiorna da solo a mezzanotte**: cambia giorno solo dopo aver aperto l'app.
«Perde completamente di senso se non si aggiorna da solo.» Da fare per primo il 2026-10-10, prima di
Spending Review: capire su quale piattaforma lo vede (iPad/iOS e/o Android), verificare che il widget
**calcoli i giorni dalle date** al momento del disegno (ADR-018) e che la piattaforma lo ridisegni a
mezzanotte senza l'app (iOS: timeline WidgetKit con una voce alle 00:00 di ogni giorno e
`policy .atEnd`/`.after(mezzanotte)`; Android: aggiornamento programmato a mezzanotte con
`AlarmManager`/`HomeWidgetScheduledUpdateReceiver`, non solo `updatePeriodMillis`). Provare
spostando l'orologio del dispositivo oltre la mezzanotte con l'app chiusa. Poi build nuova su entrambi
gli store.

  **Indagine e correzione del 2026-10-10 (Android corretto e misurato sull'emulatore; iOS
  rivisto ma da compilare sul Mac; versione dell'app NON alzata):**
  - [x] **Misurato** su `Medium_Phone_API_35` (Android 15, targetSdk 36), con TrashCan debug,
    onboarding fatto, widget aggiunto dalle impostazioni e l'app chiusa. L'allarme c'era, ma
    era alle **00:05**, **inesatto** (`dumpsys alarm`: `window=+1h0m0s flags=0x20`, cioe'
    `setAndAllowWhileIdle`) perche' `SCHEDULE_EXACT_ALARM` da Android 14 **non e' concesso di
    default**, e gli istanti erano **assoluti** (cambiando fuso GMT → Europe/Rome l'allarme
    delle 00:05 e' passato alle 02:05). Orologio portato a 23:58 con `cmd alarm set-time`:
    alle 00:01 il widget mostrava ancora il giorno prima (difetto riprodotto).
  - [x] **Causa trovata**: Android 14+ consegna gli allarmi inesatti **alla fine** della
    finestra («lazy batching»), e la finestra e' il 75% del preavviso fino a un'ora. Misurato:
    in Doze, finestra di 59 s → consegna a fine finestra; con lo schermo riacceso alle
    00:00:30, finestra di 92 s → consegna alle 00:01:37. Un allarme armato il giorno prima
    per le 00:05 arriva quindi verso **l'01:05**, ogni notte, che lo schermo sia acceso o no.
    Ipotesi 2 vera; ipotesi 1 vera ma secondaria; ipotesi 3 falsa (l'allarme viene armato
    anche prima che il widget esista, verificato); ipotesi 4 in parte (aggiornando l'app gli
    istanti vecchi restano, e un cambio di fuso li sfasa).
  - [x] **Correzione, senza nessun permesso nuovo**: `TrashcanWidget.istantiDiRisveglio` mette per
    ogni giorno un **preavviso** alle 23:00:30 (finestra piena di un'ora → consegna alle
    00:00:30) e un **finale** alle 00:00:05 (per Android ≤ 13 e per chi ha concesso il
    permesso esatto). Il primo preavviso e' tarato su quando si apre l'app
    (`preavvisoArmatoAlle`). **Misurato dopo la correzione, in Doze profondo con l'app
    uccisa: consegna alle 00:00:29, widget sul giorno nuovo**, prossimo preavviso armato a
    23:00:30 `+1h`; aprendo l'app di giorno si arma 23:00:30 `+1h`; con il permesso esatto
    concesso diventa `window=0`.
  - [x] **Reti di sicurezza**: `updatePeriodMillis` da 0 a **1800000** (ridisegno ogni mezz'ora
    pilotato dal sistema); `TrashcanWidgetProvider.onReceive` su `TIME_SET`,
    `TIMEZONE_CHANGED`, `MY_PACKAGE_REPLACED` ridisegna e ricalcola gli istanti
    (`riarmaMezzanotti`, verificato con l'app chiusa); `onEnabled` li ricalcola quando si
    aggiunge il widget. ☠ `DATE_CHANGED` **provata e scartata**: il sistema non la consegna ai
    receiver del manifest («Background execution not allowed»). `USE_EXACT_ALARM` non usato
    (Play lo limita); nessuna riga nuova nelle impostazioni per il permesso esatto, il
    preavviso basta.
  - [x] **iOS** (`TrashcanWidget.swift`): nessun difetto nel calcolo (`startOfDay` e
    `date(byAdding: .day)` reggono il 25 ottobre, la chiave della data usa il fuso corrente,
    la voce di oggi con data passata si mostra subito); ma con `.atEnd` un cambio di fuso o
    d'ora spostava il cambio di giorno per fino a sette giorni. Ora `policy:
    .after(prossima mezzanotte + 5 s)`, le sette voci restano come rete.
  - [x] Test: +8 nel gruppo «istanti di risveglio» di `trashcan_widget_giorni_test.dart` (anche
    il 25 ottobre 2026, 25 ore a Roma). **138 test verdi**, `analyze` pulito, `build apk
    --debug` ok. Atlante `apps/trashcan/codebase_reference.md` aggiornato («Come il widget
    cambia giorno a mezzanotte», trappole, regola 8, debito, provider Kotlin).
  - [ ] **Da provare su un telefono vero**: una notte con l'app chiusa e il telefono fermo,
    guardare il widget poco dopo mezzanotte (atteso: giorno nuovo dalle 00:00:30). Su telefoni
    con risparmio energetico aggressivo (Xiaomi, Huawei, Samsung «app in sospensione») il
    produttore puo' ritardare gli allarmi a prescindere: in quel caso resta la rete di mezz'ora.
  - [ ] **iOS**: compilare sul Mac l'estensione (`TrashcanWidget.swift` toccato da Windows) e
    provare il passaggio di mezzanotte sul simulatore/iPad.
  - [ ] Build nuova su entrambi gli store (versione da alzare a cura del proprietario).

**Ripresa F17 (stato al 2026-10-09, sera).** Il codice di QR Me e' completo: 182 test, analisi pulita, provato sull'emulatore Android (condivisione di testo e di immagini con QR veri, «Da immagine», moduli, stile con verifica di leggibilita', PNG, backup e ripristino, testo al 130%, tema chiaro) e sul simulatore iPhone (build con l'estensione di condivisione e ZXing, esclusione dal backup iCloud verificata). Lettura dei QR con **ZXing** su entrambe le piattaforme: ML Kit tolto per la regola «dati solo sul telefono». Restano:
  1. **Proprietario:** App ID `com.smp.qrme.ShareExtension` con App Groups → `group.com.smp.qrme` (fatti gia' `com.smp.qrme` e il gruppo). Poi profili via API e build su TestFlight.
  2. **Su iPad via TestFlight:** la condivisione da Safari deve riaprire l'app (se iOS lo impedisce: ripiego di F17.1.8, QR mostrato dall'estensione); lettura dal vivo con la fotocamera; eventuale avviso ITMS-90683 sul microfono al primo caricamento.
  3. **Su un Android vero:** fotocamera reale, «Apri le impostazioni» dopo un rifiuto definitivo (lato Kotlin provato solo dalla build).
  4. **Decisione del proprietario aperta:** la libreria di Google Play per gli acquisti (`billing` 8.0.0, Pro su Android, **tutte** le app) porta i servizi `com.google.android.datatransport` e `firebase-encoders`. E' il canale d'acquisto di Play, obbligatorio per vendere il Pro su Play; va deciso se la regola «dati solo sul telefono» lo ammette (come il server licenze) e scritto in `memory/decisioni.md`, poi rivisto il testo dell'informativa prima di pubblicare su Play.
  5. **Store:** scheda, screenshot e grafiche (`store/` non esiste ancora), App Store Connect, Play dopo il D-U-N-S, riga `qrme` nel License Server.
  6. Debito minore (atlante §14): commento di `locale_resolution.dart` sbagliato anche nelle altre quattro app; `finalizeDsl { compileSdk = 36 }` da ripetere in ogni app con `micro_share`.
- [ ] **F18** Read Aloud (ex «Leggimelo») — lettura ad alta voce di un articolo condiviso
- [ ] **F19** Link Peek (ex «Dove porta?») — destinazione reale di un link, prima di aprirlo
- [ ] **Card «In arrivo»** delle dieci app nella vetrina `smpmicroapps.it` (regola: ogni microapp
  ha la sua card, anche prima di esistere; la pubblicazione del sito la decide il proprietario)

### F9 — Porting iOS → `v5.0.0`

Nata il 2026-10-04 dalla decisione in `memory/decisioni.md` e da ADR-021. Non è una fase
"dopo le altre": ogni app la attraversa quando è pronta, e TrashCan è la prima.

**F9.1 — Preparare `micro_core` alle due piattaforme**

- [x] **F9.1.1** `NotificationService` inizializza anche il lato Darwin e chiede il permesso su iOS
- [x] **F9.1.2** `PlayPurchaseGateway` → `StorePurchaseGateway`, con `GooglePlayPurchaseParam` solo su Android
- [x] **F9.1.3** `BillingMode.play` → `BillingMode.store`; il define `BILLING=play` resta accettato
- [ ] **F9.1.4** Test che coprano entrambi i rami di `defaultTargetPlatform`

**F9.2 — TrashCan su iOS**

- [x] **F9.2.1** Toolchain sul Mac mini: Flutter 3.47.3, Xcode 27, simulatori iOS 27
- [x] **F9.2.2** `apps/trashcan/ios` generata, bundle `com.smp.trashcan`, nome "TrashCan", lingue dichiarate
- [x] **F9.2.3** Icona e schermata di avvio generate dal logo, senza canale alfa
- [x] **F9.2.4** Il percorso del widget si spegne fuori da Android (`TrashcanWidget.disponibile`)
- [x] **F9.2.5** Compila e parte sul simulatore; `first_run_test.dart` passa su iOS
- [ ] **F9.2.6** Prova su un iPhone vero: notifiche consegnate, permesso chiesto una volta sola
- [x] **F9.2.7** Estensione **WidgetKit** in Swift, con le stesse righe che Dart già calcola (`ios/TrashcanWidget/`, approvata dal proprietario sull'iPad)
- [x] **F9.2.8** Prodotto `trashcan_pro_lifetime` in App Store Connect e acquisto verificato (prezzo in sandbox dal 2026-10-06 12:13, approvato insieme alla 1.0.0)
- [x] **F9.2.9** Scheda App Store: testi, schermate, informativa privacy, nutrition label (`store/scheda-app-store.md`, 2026-10-05)
- [x] **F9.2.10** TestFlight interno: build fino alla `1.0.0 (10)`, widget verificato sull'iPad del proprietario
- [x] **F9.2.11** Screenshot generati da un test (`integration_test/screenshots_test.dart`), per i due store e le due lingue
- [ ] **F9.2.12** Invio in revisione su App Store e pubblicazione su Play — App Store **approvata e in vendita** il 2026-10-06 in 148 paesi, **UE bloccata** dalla verifica DSA; Play in revisione. Stato vivo in `StatusMicroApps.md`

**F9.3 — Le altre tre app**

- [ ] **F9.3.1** Full Freezer su iOS, widget WidgetKit compreso — **assorbita da F4** (F4.0, F4.11, F4.17): Full Freezer nasce su due piattaforme
- [ ] **F9.3.2** Scorte Calore su iOS — **assorbita da F5** (F5.0): Scorte Calore nasce su due piattaforme
- [ ] **F9.3.3** Film Tracker su iOS
- [ ] **F9.3.4** Rituale di fine fase F9

☠ **Debito aperto, F9.1.4 e il test di integrazione.** `first_run_test.dart` cerca i
controlli per testo inglese e si **pianta** su un dispositivo in italiano invece di fallire:
il 4 ottobre è costato un quarto d'ora prima che qualcuno guardasse lo schermo del
simulatore. Finché resta così, il dispositivo di prova va messo in inglese a mano (vedi
l'atlante di TrashCan, §9).

### F8 — Deploy e pubblicazione → `v10.0.0`

- [x] **F8.1** Accesso SSH a `clawserver` verificato (anticipata il 2026-09-09)
- [x] **F8.2** Ricognizione di `clawserver` (anticipata l'11 settembre 2026): nginx con quattro vhost, php-fpm 8.3 e 8.4, Docker, nessun MTA installato. OpenClaw vive su `hesclaw.ovh` e `wa-webhook.hesclaw.ovh` e non si tocca
- [x] **F8.3** Deploy del License Server in Docker (anticipata l'11 settembre 2026): container `microapps-license-server` su `127.0.0.1:8087`, volume persistente, `/healthz` verde
- [x] **F8.4** TLS e reverse proxy (anticipata l'11 settembre 2026): `lic.smpmicroapps.it` e `smpmicroapps.it` + `www` con certificato Let's Encrypt e redirect da HTTP, rinnovo automatico attivo
- [ ] **F8.5** Backup del database del server e verifica del ripristino
- [ ] **F8.6** Service account Google Play e collegamento Android Publisher API
- [ ] **F8.7** Pub/Sub per le Real-time Developer Notifications
- [ ] **F8.8** Release chiuse (closed testing) delle quattro app, 14 giorni di test
- [ ] **F8.9** Pubblicazione in produzione, monitoraggio della prima settimana
- [ ] **F8.10** Rituale di fine fase F8

**Vetrina pubblica, 11 settembre 2026** (branch `v4.2.0`). Richiesta del proprietario, fatta
e verificata online su <https://smpmicroapps.it>:

- [x] **Home** con titolo grande e stilizzato, descrizione breve e griglia di card, una per
  ogni microapp del monorepo. Le app non ancora fatte restano in griglia, in grigio, con
  l'etichetta "In arrivo" e senza link: la card non e' un `<a>`, perche' un link che non
  porta da nessuna parte si legge come un sito rotto. **Regola permanente: ogni microapp
  nuova aggiunge la sua voce in `site/src/apps.php` nello stesso giro in cui nasce.**
- [x] **Pagina di TrashCan** con descrizione commerciale, confronto Base/Pro, sezione sulla
  privacy e richiamo alla segnalazione dei problemi. Il bottone di Google Play e' spento
  finche' `suPlay` non passa a `true` in `site/src/apps.php`.
- [x] **Modulo di contatto** unico con selettore di argomento, che copre sviluppo su misura,
  segnalazione bug e domande. Token CSRF, trappola per i robot, limite di cinque invii
  all'ora per IP, consenso privacy obbligatorio. **Salva prima e notifica dopo**: un guasto
  SMTP non fa perdere il messaggio.
- [x] **Cinque pagine legali**: note legali (impressum), informativa privacy artt. 13-14
  GDPR, cookie policy, condizioni di servizio, limitazione di responsabilita'. Linkate dal
  pie' di **ogni** pagina.
- [x] **Zero terze parti**: niente font di Google, niente CDN, niente analytics. Per questo
  il sito non ha bisogno del banner dei cookie e la CSP puo' essere `default-src 'self'`.
- [x] Vhost nginx nuovo, senza toccare quelli esistenti. Risolve anche il sintomo per cui
  `smpmicroapps.it` mostrava flamingnews: mancando un `server` block con quel nome, nginx
  serviva il primo blocco caricato.
- [ ] **SMTP da configurare**: sul server non c'e' nessun MTA. Finche' non si compilano le
  credenziali in `/var/www/smpmicroapps/config.local.php`, i messaggi si salvano in
  `/var/www/smpmicroapps/var/contatti.jsonl` e non arriva nessuna notifica.

**Vetrina bilingue, 11 settembre 2026** (branch `v4.3.0`). Richiesta del proprietario, fatta
e verificata online:

- [x] **Sito in italiano e inglese.** Italiano alla radice, inglese sotto `/en`: `/trashcan`
  e `/en/trashcan` sono la stessa pagina, senza file duplicati. L'italiano resta alla radice
  perche' quegli indirizzi erano gia' online e indicizzati.
- [x] **Bandierine nella barra di navigazione**, tutte e due, con quella attiva evidenziata.
  Mostrarne una sola e' ambiguo: nessuno sa se dice "stai leggendo in italiano" o "clicca per
  l'italiano". Il link porta alla **stessa pagina** nell'altra lingua, non alla home.
- [x] **Selezione automatica** in base alla lingua di sistema, letta da `Accept-Language`.
  Con l'inglese preferito si viene portati alla versione inglese; con l'italiano si resta.
  Chi ha il browser in una terza lingua va all'inglese. **Senza intestazione si resta
  sull'italiano**, per non far apparire la home come una pagina che redirige sempre ai
  crawler dei motori di ricerca.
- [x] La scelta si ricorda in un cookie tecnico `ma_lang`, e il rilevamento automatico scatta
  **solo in sua assenza**: cosi' non puo' rimbalzare indietro chi ha appena cliccato la
  bandiera. Non esiste nessun endpoint per cambiare lingua: visitare una versione *e'* la
  scelta.
- [x] **Tutti i testi in dizionari**, due file per lingua: interfaccia e corpi delle pagine
  legali. Il catalogo delle app non contiene piu' nessun testo visibile oltre al nome.
- [x] **Le cinque pagine legali tradotte**, con un riquadro che dichiara la versione italiana
  come testo che fa fede: l'azienda e' italiana e i richiami sono ad articoli italiani.
- [x] `hreflang` e link canonico per lingua su ogni pagina, sitemap con entrambe le versioni,
  `Vary: Accept-Language, Cookie` sempre.
- [x] **`site/deploy/verifica_lingue.php`**: controlla che i dizionari abbiano le stesse
  chiavi, nessuna stringa vuota e nessun segnaposto perso o sconosciuto. Va lanciato dopo
  ogni modifica ai testi, perche' una chiave mancante non da' nessun errore: da' una frase
  italiana in mezzo a una pagina inglese.
- [x] Cookie policy e informativa privacy aggiornate: ora i cookie tecnici sono due, e la
  lettura di `Accept-Language` e' dichiarata.
- [x] **Difetto trovato durante il giro**: il modulo di contatto rifiutava **ogni** invio.
  `csrf_token()` veniva chiamata dentro il modulo, cioe' a meta' documento, quando l'HTML era
  gia' partito e PHP non poteva piu' mandare il cookie di sessione. Restava nascosto finche'
  il buffer di output tratteneva l'intera pagina; allungato il testo, l'invio ha smesso di
  funzionare. Ora il token si prende prima di qualunque output.

**Logo, menu a panino e sottomenu, 11 settembre 2026** (branch `v4.4.0`). Richiesta del
proprietario, fatta e verificata online:

- [x] **Logo del proprietario** (`smpmicroappslogo.png`, cubo isometrico con le lettere SMP)
  nella barra accanto al nome, e come favicon del sito. Da un'unica immagine si generano
  `logo.png` 128, `favicon-32.png`, `favicon-192.png` e `apple-touch-icon.png` 180.
- [x] L'icona per iOS e' l'unica **su fondo pieno**: iOS non gestisce la trasparenza in
  quell'icona, la compone su nero, e un logo verde scuro su nero sparisce.
- [x] **Menu a panino sotto gli 860 pixel.** La soglia non e' quella di un telefono ma quella
  in cui le tre voci, le due bandierine e il nome non stanno su una riga e la barra andava a
  capo diventando alta il doppio.
- [x] **Sottomenu sotto "Le app"** con le app **pubblicate**, costruito dal catalogo: oggi
  solo TrashCan, e una app nuova compare da sola appena la sua voce ha `pubblicata => true`.
  Le app non ancora fatte non ci sono, perche' nel sottomenu una voce grigia che non porta da
  nessuna parte sarebbe solo una riga morta.
- [x] Sopra gli 860 pixel e' un pannello a discesa che si apre con `:hover` **e** con
  `:focus-within`: col solo hover il sottomenu sarebbe irraggiungibile da tastiera e il fuoco
  finirebbe dentro un pannello invisibile.
- [x] **Senza JavaScript la navigazione resta quella di prima.** Il bottone arriva dal server
  con `hidden` e lo toglie `menu.js`; tutte le regole che nascondono le voci sono agganciate
  a una classe messa da una riga nel `<head>`. Un sito la cui navigazione dipende da
  JavaScript e' un sito che a volte non si puo' navigare.
- [x] `menu.js` (quaranta righe, nessuna libreria) chiude anche dopo il clic su una voce,
  perche' quasi tutte sono ancore verso la stessa pagina e il pannello resterebbe aperto
  sopra il punto a cui si e' appena saltati.

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
  **due** orari per calendario (per esempio 18:00 e 20:00).
  *Correzione al piano, 2026-09-10*: qui c'era scritto "fino a tre", ma la tabella
  `collection_calendars` prevede due colonne (`notificationTime`, `secondNotificationTime`)
  e due coprono il caso reale. Il terzo orario costerebbe una migrazione e si aggiunge solo
  se qualcuno lo chiede.
- Testo: `"Domani raccolgono {tipi}. Ricordati di portarli fuori questa sera."` Con più tipi,
  la lista separata da virgole. Titolo: il nome del calendario, se ce n'è più di uno.
- Ordina per data e tronca a 64.
- `payload` = `/day/YYYY-MM-DD?calendar=<id>`, cioe' il percorso interno di `go_router`.
  *Correzione al piano, 2026-09-10*: qui c'era `trashcan://occurrence?...`, che non
  corrisponde a nessuna rotta dichiarata in `Routes`. Un secondo formato da tradurre e' un
  secondo posto in cui sbagliare, e il sintomo sarebbe una notifica che si tocca e non porta
  da nessuna parte.

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

`android/app/src/main/kotlin/.../TrashcanWidgetProvider.kt` + `home_widget`, alimentato da
`lib/services/trashcan_widget.dart`. Dettaglio completo del formato nell'atlante di TrashCan.

- Widget verticale: testata colorata con "STASERA", il tipo di rifiuto (o "Niente") e la sua
  icona, e sotto le **tre** raccolte successive.
- Il colore della testata segue il tipo di rifiuto della sera.
- Aggiornato dall'app a ogni ripianificazione e da un `AlarmManager` alle 00:05.
- Uguale per tutti. Il widget **non** è una leva del Pro: vedi ADR-019.

☠ **Trappola**: i widget Android non possono usare Flutter per il rendering. Si passano i
dati con `HomeWidget.saveWidgetData` e si disegna in `RemoteViews`. Il layout XML va tenuto
semplice: `RemoteViews` supporta un sottoinsieme ristretto di view, e un `ConstraintLayout`
non funziona.

☠ **Trappola, quella vera**: i widget Android non possono nemmeno far *girare* Flutter per
aggiornarsi da soli. Vedi ADR-018: chi scriverà il widget di Full Freezer deve leggerlo
prima di cominciare, non dopo.

### F3.12 — Play Console e verifica end-to-end del billing

Questa sottofase è il vero motivo per cui TrashCan è l'app pilota.

▶ Azioni:

1. Creare l'app in Play Console con `com.smp.trashcan`.
2. Compilare la scheda minima richiesta per un test interno.
3. Creare il prodotto in-app `trashcan_pro_lifetime`, prezzo base **1,99 €**, che Play
   porta a **2,39 € finali in Italia**. Stato attivo. Vedi ADR-020: il numero da
   scrivere nei testi è il finale, e va letto dalla tabella dei paesi.
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

### F4.0 — Decisioni di partenza (2026-10-06)

Questa fase è stata scritta quando le app erano solo Android. Prima di F4.1 valgono queste
correzioni, tutte già pagate con TrashCan:

1. **Due piattaforme dal primo commit** (ADR-021). `flutter create --platforms=android,ios`.
   Ogni giuntura col sistema (widget, notifiche, acquisti, microfono) si chiude su entrambe
   prima di spuntare la sottofase. Mai `Platform.isX`: `defaultTargetPlatform`.
2. **iOS solo iPhone** (`memory/decisioni.md`, 2026-10-04): `TARGETED_DEVICE_FAMILY = 1`;
   sull'iPad gira in modalità iPhone. `DEVELOPMENT_TEAM = A29HGT2MQ4`, nessun
   `CODE_SIGN_IDENTITY` fissato; bundle `com.smp.fullfreezer`, widget
   `com.smp.fullfreezer.FullFreezerWidget`, App Group `group.com.smp.fullfreezer`.
   ☠ App ID, App Group ed estensione vanno **registrati a mano** nel portale Apple prima della
   prima build firmata: con TrashCan è costato un giro di build.
3. **Build iOS**: `tool/build_ios.sh full_freezer` (lo script prende l'app come argomento; va solo verificato che nomi del widget e del gruppo non siano cablati su TrashCan. Archivio senza firma,
   entitlement timbrati, verifica del gruppo, export con `-allowProvisioningUpdates`).
   ☠ Script `.sh` con fini riga LF (`.gitattributes`).
4. **Prezzo Pro 3,99 €** (§1.3). È un gradino che esiste sia su Play sia su App Store: niente
   doppio prezzo come TrashCan (2,39 / 2,99). Se Play lo trasforma, vale ADR-020 e il sito
   mostra il più alto.
5. **Paywall**: `PaywallConfig` richiede `productUnavailableLabel` e `retryLabel` (mai la
   rotellina eterna). Pulsante Pro delle impostazioni con `onTap` vero.
6. **Notifiche iOS**: permesso chiesto quando serve, non all'avvio (`NotificationService`).
7. **Ripristino su iOS**: testi «ID Apple», niente codice di trasferimento (il server licenze non
   è contattato dalla build iOS, e l'informativa del sito lo dice).
8. **ADR-019 vale anche qui**: il widget non è una leva del Pro. `FeatureKey.advancedWidget`
   resta `open()`, a correzione della mappa in F4.10.
9. **Test d'integrazione** con `lookupL` e `localesTestValue`, mai testi letterali in una
   lingua: un test che cerca l'inglese su un dispositivo italiano si pianta invece di fallire.
10. **Foto gratis, notifiche Pro** (proprietario, 2026-10-06). Ribalta F4.10 originale: la foto
    è parte del gesto di inserimento e toglierla al gratuito peggiora l'app che deve farsi
    installare; la notifica è il richiamo che fa tornare nell'app, ed è quella che si vende,
    come in TrashCan. `FeatureKey.photos` → `open()`, `FeatureKey.notifications` → `locked()`.
11. **Capienza del freezer** (proprietario, 2026-10-06). Il freezer si sceglie da una serie di
    modelli, dal più piccolo al più grande; ogni alimento ha un ingombro stimato, correggibile;
    la home mostra quanto è pieno ogni freezer; con il Pro arrivano gli avvisi «quasi pieno» e
    «quasi vuoto». Specifica in **F4.3b**. La barra di riempimento è **gratis**: è la cosa che
    distingue l'app dalle altre e va vista da tutti; il Pro vende l'avviso.

### F4.1 — Bootstrap

Applicare **§8.T**. `appId: 'full_freezer'`, `proSku: 'fullfreezer_pro_lifetime'`,
`seedColor: Color(0xFF0461E5)` (il blu dell'icona, proprietario 2026-10-06: sostituisce `#3A7CA5`), `fontFamily: 'PlusJakartaSans'`, brightness light.
Dipendenze aggiuntive: `speech_to_text` (F4.12), `home_widget` (F4.11), `image_picker`,
`fl_chart` (statistiche Pro).

### F4.2 — Data layer

**`freezers`**

| Colonna | Tipo | Note |
|---|---|---|
| `id` | int | |
| `name` | text | "Freezer cucina" |
| `modelKey` | text | chiave in `FreezerModels` (F4.3b), es. `combi_drawers`; `custom` se i litri li ha scritti l'utente |
| `capacityLiters` | real | litri **nominali**: dal modello, o scritti a mano con `custom` |
| `calibration` | real | default `1.0`; fattore di taratura scritto da «quanto è pieno davvero?» (F4.3b) |
| `lastAlertLevel` | text nullable | `full` \| `empty` \| null: l'ultimo avviso mandato, per non ripeterlo (F4.9) |
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
| `unit` | text | chiave in `Units`: `portions`, `pieces`, `packs`, `g`, `kg`, `l` (chiavi inglesi stabili; i nomi visibili stanno negli ARB) | |
| `frozenAt` | text | `YYYY-MM-DD` | ADR-008 |
| `reminderAfterDays` | int nullable | | override del preset di categoria |
| `volumeLiters` | real | > 0 | ingombro **dell'intera riga** (quantità compresa), in litri |
| `volumeManual` | bool | default false | true se l'utente l'ha corretto: da lì in poi la stima non lo tocca più |
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

### F4.3b — `CapacityEstimator`: quanto è pieno il freezer

**`lib/domain/capacity.dart`** — Dart puro, zero Flutter, come `aging.dart`.

```dart
/// Un modello di freezer fra cui l'utente sceglie quando ne aggiunge uno.
@immutable
class FreezerModel {
  const FreezerModel({required this.key, required this.liters, required this.iconKey});
  final String key;      // chiave stabile, salvata in freezers.modelKey; il nome sta nell'ARB
  final double liters;   // litri nominali
  final String iconKey;
}

abstract final class FreezerModels {
  static const List<FreezerModel> all = [ /* tabella qui sotto, dal più piccolo */ ];
  static FreezerModel? byKey(String key);
  static const String customKey = 'custom';
}

enum FillLevel { empty, normal, full }

@immutable
class FillInfo {
  const FillInfo({required this.usedLiters, required this.usableLiters, required this.fraction, required this.level});
  final double usedLiters;    // somma degli ingombri × taratura
  final double usableLiters;  // capacità nominale × usableFraction
  final double fraction;      // 0..1+ : può superare 1, e la UI lo mostra come "pieno"
  final FillLevel level;
}

class CapacityEstimator {
  const CapacityEstimator({this.usableFraction = 0.8, this.fullAt = 0.85, this.emptyAt = 0.20});
  final double usableFraction;
  final double fullAt;
  final double emptyAt;

  /// Ingombro stimato di una riga: quantità × litri per unità (tabella sotto).
  double estimateLiters({required double quantity, required String unit, String? categoryKey});

  FillInfo fill({required double capacityLiters, required double calibration, required Iterable<double> itemLiters});

  /// Taratura da «quanto è pieno davvero?»: l'utente dice 60%, la stima diceva 40% → 1.5.
  /// Limitata a 0.25–4: oltre, è più probabile un errore di tocco che un freezer così strano.
  double calibrate({required double estimatedFraction, required double declaredFraction});
}
```

**Modelli** (litri **netti** del solo vano congelatore; valore tipico e intervallo trovato
nelle schede tecniche di mercato il 2026-10-06, vedi le fonti sotto):

| `key` | Nome (it) | Litri | Intervallo nelle schede |
|---|---|---|---|
| `ice_box` | Celletta del frigo monoporta | 15 | 4–17 |
| `fridge_top` | Freezer sopra il frigo (doppia porta) | 50 | 37–100, quasi tutti 44–52 |
| `combi_compact` | Frigo combinato da 180 cm (cassetti in basso) | 70 | 67–76 |
| `undercounter` | Congelatore sottopiano a cassetti (85 cm) | 85 | 70–100 |
| `combi_large` | Frigo combinato da 200 cm | 100 | 87–119 |
| `chest_small` | Congelatore a pozzetto piccolo | 100 | 60–150 |
| `side_by_side` | Frigo americano o multiporta (lato freezer) | 200 | ~200 |
| `chest_medium` | Congelatore a pozzetto medio | 200 | 150–250 |
| `upright_tall` | Congelatore verticale alto (185 cm) | 270 | 242–324 |
| `chest_large` | Congelatore a pozzetto grande | 350 | 250–400 e oltre |
| `custom` | Altro: scrivo io i litri | — | — |

Fonti: schede Bosch KIV86VS30 / KIN86VF30 e Neff KI7862S30S, KG7393B40 (combinati); schede
Mediaworld e Yeppon di doppia porta (Domo, Severin, Indesit, Candy, San Giorgio, Sharp) e
monoporta (Electrolux, Candy, Bosch KIL42NSE0); guide all'acquisto di Mediaworld, Yeppon e
Qualescegliere per pozzetti e sottopiano; Samsung RF56N9740SR (side by side, freezer 199 L);
verticali No Frost da 185 cm (Liebherr SGNEF3036 253 L, Bosch 3GFF563WE 242 L, LG GFT41PZGSZ
324 L). ⚑ Il valore tipico serve solo come punto di partenza: chi conosce i litri del proprio
apparecchio (sono sull'etichetta energetica, alla voce del vano congelatore) sceglie `custom`.

L'elenco si mostra **ordinato per litri**, con un disegno stilizzato per ciascuno, e i litri
scritti sotto: chi conosce i litri del proprio congelatore (sono sull'etichetta) sceglie
`custom` e li scrive.

**Litri per unità** (`estimateLiters`; chiavi di `Units` in `lib/domain/units.dart`):
`portions` 0,4 · `packs` 0,8 · `l` 1,1 · `kg` 1,3 · `g` 0,0013 · `pieces` per categoria: carne 0,5, pesce 0,4, verdura 0,3, frutta 0,2,
pane 0,5, gelati 1,0, preparati 0,4, altro 0,4.

⚑ **Perché `kg` vale 1,3 litri e non 1**: il cibo congelato pesa poco meno dell'acqua, ma
sacchetti, vaschette e aria fra un pezzo e l'altro occupano spazio. Per lo stesso motivo la
capienza utile è l'80% di quella nominale (`usableFraction`): nessun freezer si riempie fino
all'ultimo litro.

⚑ **Perché due correzioni e non una.** La stima sbaglia in due modi diversi, e ognuno ha la sua
correzione:
1. **Il singolo alimento** è stimato male (la lasagna in teglia non è «una porzione»). Si
   corregge sull'alimento: nel `QuickAddSheet` l'ingombro compare come «≈ 1,2 L», toccandolo si
   aggiusta con quattro misure rapide (piccolo 0,25 · medio 0,5 · grande 1 · molto grande 2 litri
   per unità) o un valore libero. `volumeManual = true`.
2. **Il freezer intero** sembra più pieno o più vuoto di quello che è, perché l'utente riempie
   in modo diverso dalla media. Si corregge sul freezer: nella pagina del freezer, «Quanto è
   pieno davvero?» con uno slider; `calibrate()` scrive `freezers.calibration`. Da lì la barra
   coincide con quello che l'utente vede aprendo lo sportello, e gli inserimenti successivi la
   fanno salire in proporzione.

Correggere solo gli alimenti costringerebbe a ricorreggerli uno per uno; correggere solo il
freezer non aggiusta il caso della lasagna. Servono entrambe.

☠ **Trappola**: la taratura si calcola sulla stima **senza** taratura precedente, altrimenti
due tarature di seguito si moltiplicano e la barra impazzisce. `calibrate()` riceve la frazione
stimata grezza.

**Soglie**: `full` da 85% in su, `empty` sotto il 20%. In UI: barra verde fino al 70%, ambra
70–85%, rossa oltre l'85%.

**Test (F4.13)**: stima per ogni unità; somma e frazione; taratura (60 dichiarato su 40 stimato
→ 1,5; limiti 0,25 e 4); una seconda taratura non si moltiplica con la prima; livelli alle
soglie esatte; freezer vuoto → frazione 0 senza divisioni per zero; `custom` con litri a mano.

### F4.4 — Home

1. Testata: nome del freezer selezionato (o "Tutti"), numero di prodotti, e il contatore
   "**N da usare presto**" in evidenza.
2. Sezione **"Da usare prima"**: i prodotti con `level != fresh`, ordinati per giorni
   decrescenti, massimo 5, con "vedi tutti".
3. Sezione **"Tutto il resto"**: ordinata per `frozenAt` crescente (più vecchio in cima).
4. Sezione **"Dove sono"**: elenco dei freezer con il conteggio e la **barra di riempimento**
   per ciascuno («Freezer cucina · 23 prodotti · pieno al 64%»). Il freezer selezionato mostra
   la barra anche in testata.
5. FAB grande: **"+ Metti nel freezer"**.

Ogni riga è un `MicroListTile` con swipe a destra "Consumato" (verde) e a sinistra "Buttato"
(arancio), entrambi con snackbar di annullamento.

### F4.5 — Inserimento

**Rapido** (`QuickAddSheet`): bottom sheet che si apre con la tastiera **già attiva** sul
campo nome. Campi visibili: nome (autocompletamento dai nomi già usati), quantità con
stepper, unità (chip preselezionato con l'ultimo usato). Data = oggi, posizione = ultima
usata, categoria dedotta dal nome se corrisponde a un termine noto. Sotto la quantità, la
riga «≈ 1,2 L · il freezer sarà pieno al 67%», toccabile per correggere l'ingombro (F4.3b).
Bottone "Salva".

⚑ La riga dell'ingombro **non aggiunge tocchi**: è precompilata e si tocca solo per
correggerla, così il vincolo dei 4 tocchi resta.
Un link "Altri dettagli" apre la form completa mantenendo quanto già scritto.

⚑ **Perché l'autocompletamento sui nomi già usati**: il freezer di una famiglia contiene
sempre le stesse venti cose. Dopo due settimane, "spe" completa "Spezzatino" e l'inserimento
scende a due tocchi. È la singola ottimizzazione che fa la differenza tra un'app usata e una
abbandonata.

**Completo** (`ItemEditPage`): tutti i campi, foto (**gratis**), nota, promemoria
personalizzato, ingombro.

**Foto**: `image_picker` da fotocamera o galleria, ridotta a 1280 px sul lato lungo, JPEG
qualità 80, salvata nella cartella dell'app con percorso relativo (F1.11). Su iOS servono
`NSCameraUsageDescription` e `NSPhotoLibraryUsageDescription` (it/en).

Funzione **"Ne ho congelato un altro uguale"**: duplica l'item con `frozenAt = oggi`,
disponibile dal menu di una riga. Nel piano gratuito è disponibile: costa nulla e crea
abitudine.

### F4.6 — Posizioni

`lib/features/locations/` — CRUD di freezer e scomparti, con drag per riordinare e conteggio
per ciascuno. Nel piano gratuito **un solo freezer**, scomparti illimitati.

**Aggiungere un freezer** (anche nell'onboarding, che crea il primo): nome, poi la **scelta
del modello** da `FreezerModels.all`, una griglia di carte ordinate dal più piccolo al più
grande, ciascuna con disegno, nome e litri; l'ultima è «Altro: scrivo io i litri». Il modello
si può cambiare dopo: cambia la capacità, non gli alimenti.

**Pagina del freezer**: barra di riempimento grande, litri occupati su litri utili, e
«Quanto è pieno davvero?» (taratura, F4.3b), con «Ripristina la stima» che riporta
`calibration` a 1.

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

**Tutte le notifiche sono Pro** (`FeatureKey.notifications`, F4.0 punto 10). Senza Pro la
home mostra comunque «Da usare prima» e la barra di riempimento: l'informazione c'è, manca
solo il richiamo.

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

**Avvisi di capienza** (Pro), in `lib/services/capacity_alerts.dart`:

- Si valutano **dopo ogni modifica** degli alimenti di un freezer (inserimento, uscita,
  correzione) e dopo una taratura.
- **Quasi pieno**: il freezer passa sopra `fullAt` → notifica immediata «Il Freezer cucina è
  pieno all'88%: prima di comprare altro da congelare, consuma qualcosa di quello che c'è»,
  con il più vecchio citato.
- **Quasi vuoto**: il freezer scende sotto `emptyAt` → notifica pianificata per **il sabato
  successivo alle 10:00** («è un buon momento per cucinare e congelare»), perché arrivare mentre
  si sta togliendo l'ultima cosa non serve a niente; arrivare quando si pianifica la spesa sì.
- Anche il digest periodico aggiunge una riga per ogni freezer pieno o quasi vuoto.

☠ **Trappola, l'avviso ripetuto**: un freezer all'86% che riceve e perde un alimento al giorno
attraverserebbe la soglia ogni giorno. Si usa `freezers.lastAlertLevel` con **isteresi**:
dopo un «pieno» non si riavvisa finché non è sceso sotto il 70%; dopo un «vuoto» non si
riavvisa finché non è risalito sopra il 40%. Un freezer appena creato e vuoto non manda mai
«quasi vuoto»: `lastAlertLevel` parte da `empty`.

### F4.10 — Pro

```dart
const FeatureLimits freezerLimits = {
  FeatureKey.unlimitedEntities:  FeatureLimit.count(freeMax: 1),   // freezer
  FeatureKey.photos:             FeatureLimit.open(),       // F4.0 punto 10: gratis
  FeatureKey.notifications:      FeatureLimit.locked(),     // F4.0 punto 10: digest e avvisi di capienza
  FeatureKey.fullHistory:        FeatureLimit.locked(),
  FeatureKey.statistics:         FeatureLimit.locked(),
  FeatureKey.csvExport:          FeatureLimit.locked(),
  FeatureKey.backupRestore:      FeatureLimit.locked(),
  FeatureKey.advancedWidget:     FeatureLimit.open(),     // ADR-019, vedi F4.0 punto 8
  FeatureKey.customCategories:   FeatureLimit.locked(),
};
```

**Statistiche** (`lib/features/stats/`): consumati vs buttati nel periodo, permanenza media,
categoria più sprecata, andamento mensile con `fl_chart`, valore indicativo dello spreco se
l'utente ha inserito i costi (opzionale).

### F4.11 — Widget (Android e iOS)

4×2: titolo "Da usare presto", fino a tre righe "nome — N giorni", e il conteggio totale.
Tocco: apre l'app sulla sezione. Aggiornamento a ogni modifica e una volta al giorno.

⚑ **ADR-018 applicato all'anzianità**: i giorni cambiano a mezzanotte anche se nessuno apre
l'app. Il payload non contiene "N giorni" ma `frozenAt` di ogni riga; il widget calcola i
giorni da sé, su Android nel provider e su iOS nella `TimelineProvider` (una voce per i
prossimi giorni). Così il numero non invecchia.

**iOS**: estensione WidgetKit `ios/FullFreezerWidget/`, creata con lo script Ruby di TrashCan
(`tool/aggiungi_widget_ios.rb`, adattato) e anteprima con `tool/anteprima_widget_ios.swift`. Trappole già
pagate: la fase *Embed App Extensions* va **prima** di *Thin Binary* (ciclo di build);
l'estensione eredita l'xcconfig di Flutter; testi di riserva nell'estensione, mai widget vuoto;
`contentMarginsDisabled`.

### F4.12 — Voice input

`speech_to_text` sul campo nome del `QuickAddSheet`, con parsing locale della frase.
Su iOS servono `NSMicrophoneUsageDescription` e `NSSpeechRecognitionUsageDescription` in
`Info.plist` (it/en), altrimenti l'app viene chiusa dal sistema al primo tocco sul microfono:

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

### F4.14 — Rifinitura · F4.15 — Atlante · F4.16 — Rituale (branch `v6.0.0`)

---

## F5 — Scorte Calore

**Obiettivo della fase**: rispondere in mezzo secondo a "quando devo ricomprare?", con una
stima che sia onesta sulla propria incertezza.

### F5.0 — Decisioni di partenza (2026-10-07)

Prese con il proprietario prima di F5.1. Dove contraddicono il resto della fase, vincono queste.

1. **Android e iPhone dal primo commit**, come Full Freezer (ADR-021, F4.0 punti 1-3):
   `flutter create --platforms=android,ios`, `TARGETED_DEVICE_FAMILY = 1`, bundle
   `com.smp.scortecalore`, widget `com.smp.scortecalore.ScorteCaloreWidget`, App Group
   `group.com.smp.scortecalore`. ☠ App ID e App Group li registra il proprietario nel portale;
   **il gruppo va agganciato a ciascun App ID** (Identifiers → App Groups → Configure),
   altrimenti i profili escono con l'elenco dei gruppi vuoto (pagato con Full Freezer).
2. **Notifiche Pro** (proprietario: «le notifiche sono pro»). Ribalta la mappa di F5.11, dove
   non erano citate: `FeatureKey.notifications` → `locked()`. Il gratuito resta utile perche'
   stima e autonomia si vedono aprendo l'app **e nel widget**.
3. **Widget su Android e iOS** (proprietario, 2026-10-07): "Pellet: 22 giorni" con la data di
   riordino. ⚑ **ADR-018**: il payload porta la **data di esaurimento stimata**, non "N giorni";
   i giorni li conta il widget (provider Kotlin con `LocalDate.now()`, timeline WidgetKit), come
   in Full Freezer (`lib/services/freezer_widget.dart`). Il widget non e' una leva del Pro
   (ADR-019): `FeatureKey.advancedWidget` → `open()`.
4. **Prezzo Pro 2,99 €** (proprietario). App Store: 2,99 € con base Italia. Play: il prezzo si
   scrive **senza IVA** → base **2,45 EUR** per avere 2,99 € in Italia (☠ pagato con Full
   Freezer: scrivendo il prezzo finale Play aggiunge il 22%). SKU `scortecalore_pro_lifetime`.
5. **Colori dall'icona** (proprietario): arancio della fiamma come seme del tema, blu notte
   dello sfondo dell'icona per le testate (come "A · Ghiaccio" di Full Freezer). Sostituisce
   `#C4622D`; i valori esatti li misura `tool/genera_icone.py`.
6. **Prima un'interfaccia essenziale, poi le proposte grafiche** (proprietario): appena
   l'app funziona si disegnano 2-3 direzioni (artifact, come per Full Freezer) e il
   proprietario sceglie. **Scelta: «A · Brace»** (2026-10-07, https://claude.ai/artifact/Q1GQPG7gKkuJJz31py8pLt):
   testata blu notte con la fonte principale e i giorni in arancio brace, altre fonti in righe
   compatte, pulsante «Aggiorna scorta» in fondo; resta Plus Jakarta Sans (non Sora).
7. **Trappole gia' pagate da non ripetere** (Full Freezer, 2026-10-07):
   - ☠ **Id per il License Server senza trattino basso**: `appId` locale `scorte_calore`, ma
     il server conosce `scortecalore` → costante `licenseAppId` in `app_config.dart` usata dal
     client licenze e dall'`EntitlementService`.
   - ☠ **Deep link di Flutter spento** su Android (`flutter_deeplinking_enabled`) e iOS
     (`FlutterDeepLinkingEnabled`), e `onNewIntent` → `setIntent` in `MainActivity`, se il
     widget apre una pagina.
   - ☠ **Xcode 27 non crea profili nuovi con la chiave API**: i profili App Store si creano via
     API ("MicroApps AppStore <bundle>") e `tool/build_ios.sh` li usa da solo.
   - ☠ **Pagine Pro protette sulla pagina** (`ProGate`), non solo all'ingresso.
   - ☠ **Testi inglesi con virgolette tipografiche** (gli script adb cercano `content-desc="…"`).
   - ☠ **Account Google Play**: se e' ancora personale, ogni app nuova chiede un test chiuso di
     12 tester per 14 giorni. Il passaggio ad account da organizzazione e' in corso (D-U-N-S
     richiesto il 2026-10-07, `StatusMicroApps.md`).
8. **Calendario (Pro) su entrambe le piattaforme**: `device_calendar` chiede `READ_CALENDAR`/
   `WRITE_CALENDAR` su Android (da giustificare nella scheda Play) e
   `NSCalendarsFullAccessUsageDescription` su iOS 17+, con testi it/en in `InfoPlist.strings`.

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

> **Fatto il 2026-10-08 con `device_calendar_plus` invece di `device_calendar`** (fermo al
> settembre 2024, senza l'accesso completo di iOS 17). Le firme vere sono nell'atlante
> `apps/scorte_calore/codebase_reference.md`: `upsertReorderEvent` prende anche i testi gia'
> tradotti, e c'e' `forgetSource` per non lasciare eventi orfani.

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

### F5.12 — Test · F5.13 — Rifinitura · F5.14 — Atlante · F5.15 — Rituale (branch `v7.0.0`)

---

## F6 — Film Tracker

**Obiettivo della fase**: l'app con la maggiore identità di prodotto delle quattro. Un
diario visivo dei rullini, in cui la scheda di ogni rullino si riconosce a colpo d'occhio
dalla sua anteprima e non dal numero.

Va per ultima perché è la più costosa (gestione immagini, quattro entità collegate, tema
scuro curato) e perché a quel punto `micro_core` e la catena di billing sono già collaudate
da tre app.

### F6.0 — Decisioni di partenza (2026-10-08)

Prese con il proprietario prima di F6.1. Dove contraddicono il resto della fase, vincono queste.

1. **Android e iPhone dal primo commit**, come Full Freezer e Scorte Calore:
   `flutter create --platforms=android,ios`, `TARGETED_DEVICE_FAMILY = 1`, bundle
   `com.smp.filmtracker`. Nessun App Group (non c'e' widget). ☠ L'App ID lo registra il
   proprietario nel portale.
2. **Prezzo Pro 4,99 €** (proprietario), non i 6,99 € di §1.3. App Store: 4,99 € con base
   Italia. Play: il prezzo si scrive **senza IVA** → base **4,09 EUR** per avere 4,99 € in
   Italia. SKU `filmtracker_pro_lifetime` (definitivo, §1.3).
3. **Foto tutte gratis** (proprietario): copertina, provini, stampe, galleria, zoom. Ribalta
   F6.9, dove la photo overview era Pro: `FeatureKey.photos` → `open()`. ⚑ L'archivio con le
   anteprime e' l'identita' dell'app (obiettivo della fase): chiuderlo dietro il Pro
   renderebbe brutta proprio la versione che deve far conoscere l'app. Il Pro si regge su:
   macchine multiple (`secondaryEntities`, una gratis), statistiche e costi (`statistics`),
   PDF annuale (`pdfReport`), CSV (`csvExport`), backup completo (`backupRestore`).
4. **Nessun widget** (§ "Nessun widget in Scorte Calore e Film Tracker", confermato dal
   proprietario): niente home_widget, niente estensione iOS, niente App Group.
5. **Icona dal proprietario** (in Download, come per Scorte Calore): la si ripulisce con
   `tool/genera_icone.py` e da li' si prendono i colori del tema. Il seme `#E0A458` del piano
   resta valido finche' l'icona non dice altro.
6. **Tema scuro di default** (F6.1, invariato) e, come per Scorte Calore, **prima
   un'interfaccia essenziale, poi 2-3 proposte grafiche** fra cui il proprietario sceglie. **Scelta: «C · Provino»** (2026-10-08,
   https://claude.ai/artifact/14GrAPyvYN2bdcov5PKVoP): fondo quasi nero `#0D0C0B`, superfici
   `#1A1714`, tutto impaginato come pellicola (perforazioni, scritte a bordo pellicola in
   arancio `#F0A33B` monospaziato **Space Mono**), archivio come foglio provini a tre
   colonne con il numero del fotogramma; corpo in Plus Jakarta Sans. Scartate «A · Camera
   oscura» (Fraunces su nero caldo) e «B · Barattolo» (blu notte dell'icona, etichette color
   carta).
7. **Trappole gia' pagate** (F5.0 punto 7, valgono tutte): `licenseAppId` senza trattino
   basso (`filmtracker`), deep link di Flutter spento (qui serve il **nostro** deep link
   `filmtracker://roll/<n>` del QR, F6.12: va gestito da go_router con
   `FlutterDeepLinkingEnabled` acceso **oppure** dal plugin `app_links`; decidere in F6.12),
   `ProGate` sulle pagine Pro, virgolette tipografiche, profili iOS via API, invito TestFlight
   mandato a parte (`POST /v1/betaTesterInvitations`).

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

Eseguire §6. Branch: `v8.0.0` (la mappa delle versioni in testa al tracking; il `v7.0.0` qui era un refuso).

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

### F7.9 — Rituale di fine fase F7 (branch `v9.0.0`)

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

### F8.10 — Rituale di fine fase F8 (branch `v10.0.0`)

---

## F10–F19 — App nuove: le idee e le prime valutazioni

Testo del proprietario (`docs/specs/idee-2026-10.md`) e, sotto, quello che gia' si sa dal lato
tecnico. **Non sono ancora specsheet**: lo diventano in `Fx.1`, dopo le decisioni `Fx.0`.

### F10 — Boomerang (ex «Te l'ho prestato»)

> Una micro-app per tenere traccia degli oggetti prestati o presi in prestito. L'utente registra
> rapidamente oggetto, persona e data, così da sapere sempre chi ha cosa e da quanto tempo.

- Due liste speculari: prestati e presi in prestito; "da quanto" si conta come in Full Freezer
  (date civili, ADR-008). Promemoria di restituzione: `NotificationService` di `micro_core`.
- Persona: testo libero, oppure scelta dalla rubrica (permesso contatti: da decidere, si puo'
  evitare). Foto dell'oggetto: come Film Tracker.
- Pro possibile: promemoria, foto, storico, backup (da decidere in F10.0).

### F11 — Pin Drop (ex «Dove l'ho lasciato?»)

> Una memoria temporanea basata su posizione, foto e nota. Serve per ricordare dove si è lasciata
> l'auto, la bici, un ombrellone, una tenda, un armadietto o qualsiasi altra cosa legata a un
> luogo preciso.

- Posizione **solo in primo piano**, al momento del salvataggio. Ritorno: bussola e distanza
  calcolate sul telefono, oppure apertura della mappa di sistema (Google Maps / Apple Maps) con
  le coordinate: niente SDK di mappe a pagamento.
- Foto e nota come Film Tracker; "temporanea": scadenza automatica dei ricordi.
- ☠ Al chiuso o sottoterra (parcheggi) il GPS sbaglia di decine di metri: la foto e la nota
  ("piano -2, colonna B7") contano piu' delle coordinate.

### F12 — Quanto sto spendendo?

> Un contatore rapido per la spesa. Durante gli acquisti si aggiungono i prezzi degli articoli e
> l'app mostra in tempo reale il totale del carrello, eventualmente confrontandolo con un budget
> impostato.

- Tastierino numerico grande, una mano sola; quantita' ("x3"); togliere l'ultimo; budget con
  barra. Importi in centesimi (`Money`). Voce: il parser di Full Freezer e' un buon punto di
  partenza.
- Nessun permesso. Widget possibile (totale corrente).

#### F12.0 — Prime decisioni del proprietario (2026-10-10), il resto il 2026-10-10

- **Nome: «Spending Review»** (proprietario). Da chiarire domani se vale per entrambe le lingue
  come «QR Me» (la cartella sara' presumibilmente `apps/spending_review/`, bundle
  `com.smp.spendingreview`, `licenseAppId 'spendingreview'`: da confermare).
- **Nessun widget** (proprietario): supera «Widget possibile» qui sopra.
- **Icona dal proprietario**: `C:/Users/Pixel/Downloads/spendendo.png` (PNG 1254x1254 RGBA
  trasparente), copiata in `docs/specs/icona-spending-review.png`. ⚑ Lo scontrino con l'euro dentro
  gli **angoli verdi da inquadratura** suggerisce la **lettura dello scontrino con la fotocamera**:
  domandarlo esplicitamente in F12.0 (OCR sul telefono, con la regola «dati solo sul telefono»:
  niente ML Kit; su iOS Vision e' locale, su Android serve un OCR che non mandi dati).
- **Gratis/Pro e prezzo** (proprietario, 2026-10-10): **«spesa gratis, revisione Pro»**, Pro **2,99 €**.
  - **Gratis:** tastierino, budget, **lettura dei cartellini illimitata**, etichette della bilancia,
    ultime **5 spese** salvate.
  - **Pro:** **Scontrino** (controllo alla cassa **e** registrazione della spesa dallo scontrino),
    **storico illimitato con statistiche** (per mese e per negozio, spesa media, sforamenti del
    budget), **export CSV**, **backup**.
- **Scontrino** (proprietario, 2026-10-10): serve **sia** a confrontare alla cassa il contato con lo
  scontrino (differenza e righe sospette) **sia a registrare la spesa** dallo scontrino letto, anche
  se durante la spesa non si e' contato niente (la spesa salvata nello storico prende righe e totale
  dallo scontrino).
- **Cosa fa esattamente**: aperto, da decidere insieme partendo dall'idea sopra.
- **2026-10-10, risposte del proprietario:** (1) «Spending Review» **in italiano e in inglese**;
  (2) l'app **legge con la fotocamera i cartellini del prezzo e gli scontrini, con due tasti
  diversi** (due flussi distinti, non uno «intelligente»).
- **2026-10-10, interfaccia scelta: «C · Una mano»** (https://claude.ai/artifact/Y9KH2qk6PeAYKzQBTyvdhY):
  tema scuro (`#161B22`, superfici `#1E252E`, bordi `#262D36`, testo `#E8EDF2`/`#9AA5B1`), verde
  `#4ADE80`, totale enorme in Space Grotesk in alto con barra del budget, lista corta degli ultimi
  articoli, i due tasti **Cartellino** (verde) e **Scontrino** (scuro) a meta', **tastierino numerico
  sempre visibile** in basso per il prezzo a mano (con ×, −, ⌫, +). Seconda schermata: scontrino
  contro conto, differenza evidenziata in ambra, righe sospette. Scartate «A · Scontrino» e «B · Cassa».
- **Il cartellino va INTERPRETATO** (proprietario), non solo letto: dal testo del cartellino ricavare
  **nome del prodotto** e **prezzo da pagare**, riconoscendo almeno: prezzo in offerta vs prezzo
  barrato/«anziche'», prezzo **al kg/al litro** (prezzo unitario) vs prezzo della confezione, offerte
  tipo **3x2 / 2x1 / -30%**, centesimi scritti piccoli. Se c'e' ambiguita' l'app propone e l'utente
  conferma con un tocco. Da definire il 2026-10-10 nella specsheet: quali formati (cartellini dei
  supermercati italiani), cosa fare con i prodotti a peso.
- **Prodotti a peso** (proprietario, 2026-10-10: «entrambe le cose»): **sia** peso scritto a mano
  dopo il cartellino al kg, **sia** lettura dell'etichetta della bilancia (che porta gia' il totale).
- **Campioni per tarare l'OCR**: raccolti dal web (preferenza a licenze libere, es. Wikimedia
  Commons), tenuti **fuori dal repo** in `E:/coding/XAMPP/htdocs/microapps-campioni/f12/` (il repo e'
  pubblico su GitHub e le foto non sono nostre), con un `campioni.csv`: file, fonte, licenza, tipo
  (cartellino/scontrino/bilancia) e la **verita'** trascritta a mano (nome, prezzo, offerta, prezzo al
  kg, totale). Servono a misurare la precisione dell'OCR prima di promettere l'interpretazione.
- ☠ **OCR solo sul telefono** (regola «dati solo sul telefono»): su iOS **Vision** (locale); su
  Android **niente ML Kit** → valutare un OCR che giri tutto nell'app (es. Tesseract via FFI) e la
  sua precisione sui cartellini; e' il punto tecnico piu' rischioso di F12.
- **Specsheet scritta il 2026-10-10**: vedi la sezione **«F12 — Spending Review»** qui sotto (F12.0
  riepilogo delle decisioni, F12.1 specsheet, F12.2 ordine di lavoro, F12.10 domande aperte). Le righe
  qui sopra restano come traccia: dove differiscono (es. «Tesseract via FFI», «Widget possibile»), vince
  la sezione F12.

### F13 — Fair Share (ex «Quanto dividiamo?»)

> Una utility per dividere velocemente un conto tra più persone. Può gestire divisione uguale,
> quote diverse, singole voci dello scontrino, sconti e mancia, mostrando subito quanto deve
> pagare ciascuno.

- Il cuore e' **l'arrotondamento**: 100 € in 3 fa 33,33 + 33,33 + 33,34, e chi paga il centesimo
  va detto. Dominio puro, testato come le statistiche di Film Tracker.
- Leggere lo scontrino con la fotocamera e' OCR: §1.4 lo esclude dall'MVP. Si parte a mano.


#### F13.0 — Prime decisioni del proprietario (2026-10-11), il resto il 2026-10-12

- **Come si divide: lo sceglie l'utente** (parti uguali, quote, per voce, mancia… da definire in F13.0).
- **Lo scontrino si legge come in Spending Review**: `packages/micro_ocr` + il parser dello scontrino
  (da estrarre in un punto comune riusabile invece di copiarlo).
- **Niente widget. Niente notifiche.**
- **Gruppi di spese nel tempo** (es. un viaggio, una casa condivisa): piu' spese tenute insieme anche
  per molto tempo, con il saldo di chi deve cosa. ☐ **Nome da trovare** («Viaggio» non piace al
  proprietario).
- **Immagine di riepilogo da mandare agli amici (Pro)**: quanto si e' speso e quanto deve mettere
  ciascuno, per la singola spesa e per l'intero gruppo («un'immagine figa»).
- **Membri dai contatti** del telefono, per mandare a ciascuno **un SMS o, se c'e', un WhatsApp** gia'
  scritto con quanto deve. ☠ Selettore dei contatti di sistema senza permesso (come QR Me); l'invio
  apre l'app dei messaggi o WhatsApp con il testo pronto: l'app non manda nulla da sola e non usa
  servizi di terzi (regola «dati solo sul telefono»).
- **Gratis/Pro e prezzo**: si decidono dopo aver fissato tutte le funzioni.

### F14 — Geo Note (ex «Ricordamelo qui»)

> Un sistema di promemoria basati sulla posizione invece che sull'orario. L'utente può chiedere
> di ricevere un avviso quando arriva o esce da un determinato luogo, ad esempio casa, ufficio,
> farmacia o supermercato.

- ☠ **Geofencing = posizione in background**: su Play e' un permesso a dichiarazione obbligatoria
  (modulo, video, motivazione) e puo' essere respinto; su iOS richiede "Sempre" con i suoi
  passaggi. Limiti dei sistemi: circa 100 aree su Android, 20 su iOS.
- "Supermercato" generico (qualunque supermercato) richiederebbe un servizio di luoghi: fuori,
  salvo decisione; si parte da luoghi scelti dall'utente.

### F15 — Quanti sono? — ANNULLATA il 2026-10-11

> Una utility che usa la fotocamera per contare automaticamente oggetti visibili in una scena.
> Potrebbe essere utile per scatole, bottiglie, componenti, monete o altri elementi ripetuti. Da
> considerare sperimentale: il riconoscimento potrebbe funzionare male con oggetti sovrapposti,
> piccoli, riflettenti o disposti in modo irregolare.

- Serve visione artificiale **on-device** (ML Kit / Core ML, o un modello di conteggio): §1.4
  esclude l'AI dall'MVP, quindi **prima di F15.0 si decide se e come**.
- Mitigazione da progettare: conteggio assistito (l'utente tocca per aggiungere o togliere i
  punti trovati), mai un numero dato per certo.

### F16 — TLDR (ex «Riassumilo»)

> Una utility da Share Sheet: si condivide un link, un articolo o del testo e l'app restituisce un
> riassunto breve e leggibile. È un'idea forte, ma richiede un sistema di summarization
> affidabile, idealmente tramite modello on-device o con un fallback remoto.

- **Decisione sull'AI prima di F16.0**: modello di sistema on-device (dove esiste), oppure un
  servizio remoto (costi per richiesta, privacy, chiavi lato server: il License Server
  potrebbe fare da proxy).
- Prima Share Extension della piattaforma insieme a F17/F18/F19 (§1.6).

### F17 — Fammi un QR → diventata **QR Me**

> Si condivide un link, un testo, un indirizzo o un altro contenuto e l'app genera immediatamente
> un QR code a tutto schermo. Utile per trasferire velocemente informazioni tra dispositivi o
> mostrarle a un'altra persona senza copiare e incollare.

- **Decisa e specificata il 2026-10-09**: vedi la sezione **«F17 — QR Me»** qui sotto (F17.0
  decisioni, F17.1 specsheet). Questa scheda resta come traccia dell'idea originale.

### F18 — Read Aloud (ex «Leggimelo»)

> Una utility che riceve un articolo o una pagina tramite Share Sheet, ne estrae il contenuto
> principale e lo legge con il text-to-speech del dispositivo. L'obiettivo è trasformare qualsiasi
> articolo in una sorta di audiolettura istantanea.

- Estrazione del testo principale (stile "modalita' lettura") scaricando la pagina: rete
  dall'app; pagine con paywall o caricate da JavaScript non si leggono.
- Sintesi vocale del sistema, con lettura in background e controlli dalla schermata di blocco.

### F19 — Link Peek (ex «Dove porta?»)

> Si condivide un link abbreviato o sospetto e l'app mostra la destinazione finale prima di
> aprirlo. Può seguire la catena dei redirect, mostrare il dominio effettivo ed evidenziare
> eventuali segnali sospetti come domini strani o punycode.

- Seguire i redirect **senza aprire la pagina** (richieste HEAD/GET senza eseguire nulla,
  limite al numero di salti), mostrare la catena; segnali: punycode, domini simili a marchi noti,
  IP al posto del dominio, tanti salti.
- ☠ La richiesta parte dal telefono: chi ha creato il link vede l'IP. Va detto nell'app e
  nell'informativa.

---

## F17 — QR Me (ex «Fammi un QR»)

**Obiettivo della fase**: l'app che trasforma in un QR a tutto schermo qualunque cosa le si
condivida, e che sa anche leggerli. Il gesto principale e' **Condividi → QR Me → il QR e' gia'
li', grande e luminoso**: zero tocchi in piu'. Tutto il resto (moduli, stile, preferiti) gira
intorno a quel gesto senza rallentarlo.

E' anche la fase che costruisce **una volta** la ricezione da Share Sheet per tutta la
piattaforma (`packages/micro_share/`, F17.2b): F16, F18 e F19 la useranno senza rifarla.

### F17.0 — Decisioni di partenza (2026-10-09)

Prese con il proprietario prima di F17.1. Dove contraddicono le idee di §8 «F10–F19», vincono queste.

1. **Nome: «QR Me», uguale in italiano e in inglese** (proprietario: «Va bene QR Me anche in
   italiano»). Sostituisce «Fammi un QR». Ne discendono:
   - cartella `apps/qr_me/`, `appId: 'qr_me'`, **`licenseAppId: 'qrme'`** (senza trattino basso,
     F5.0 punto 7);
   - bundle / applicationId **`com.smp.qrme`** (non piu' `com.smp.fammiunqr`), estensione iOS
     `com.smp.qrme.ShareExtension`, App Group `group.com.smp.qrme`;
   - SKU **`qrme_pro_lifetime`** (immutabile dopo la pubblicazione).
   - ☠ «QR Me» sugli store e' quasi certamente gia' usato da altri: il nome della **scheda** si
     prova alla creazione (App Store risponde 409 `DUPLICATE.DIFFERENT_ACCOUNT`, come per Full
     Freezer e Film Tracker). Ripiego gia' deciso: **«QR Me – Share & Scan»** (inglese) e
     **«QR Me – Condividi e leggi»** (italiano). Sotto l'icona resta sempre «QR Me»
     (`CFBundleDisplayName`, `android:label`).
2. **Android e iPhone dal primo commit**, come Film Tracker: `flutter create
   --platforms=android,ios`, `TARGETED_DEVICE_FAMILY = 1`. **Serve un App Group** (per
   l'estensione di condivisione, F17.2b): il proprietario registra nel portale Apple gli App ID
   `com.smp.qrme` e `com.smp.qrme.ShareExtension`, entrambi con la capability App Groups, e il
   gruppo `group.com.smp.qrme` (come fece per Scorte Calore). I profili si creano poi via API.
3. **Contenuti**: testo e link (dalla condivisione, scritti o incollati) **piu' i moduli
   speciali** scelti dal proprietario: **Wi-Fi**, **contatto (vCard)**, **email**, **SMS**,
   **telefono**. ⚠ **Superato da F17.10** (2026-10-09): moduli SMS e Telefono tolti (la lettura
   resta), «Email» diventa «Email precompilata», Wi-Fi e Contatto non si compilano a mano come
   strada principale (Wi-Fi da QR o dalla rete connessa, Contatto dalla rubrica o «Io»).
4. **Legge anche i QR** con la fotocamera (proprietario: «Deve anche leggere, e rigenerarlo con
   le variazioni che possono essere fatte dalla nostra app»): dalla fotocamera **e da
   un'immagine** (galleria o immagine condivisa, es. uno screenshot con un QR). Un QR letto si
   puo' mostrare di nuovo, salvare e **rigenerare con lo stile** (colori, logo).
5. **Stile del QR: colori e logo centrale** (proprietario). Logo da **tre fonti**, tutte scelte
   dal proprietario: **foto dalla galleria**, **icone pronte**, **emoji o testo corto** (1–3
   caratteri).
6. **Gratis e Pro: «base generosa»** (proprietario), Pro **1,99 €** una tantum:

   | Funzione | Gratis | Pro | `FeatureKey` |
   |---|---|---|---|
   | Condivisione → QR a tutto schermo, luminosita' al massimo | ✔ | ✔ | — |
   | Testo e link scritti o incollati | ✔ | ✔ | — |
   | **Lettura** dalla fotocamera e da immagine | ✔ | ✔ | — (decisione del proprietario: gratis) |
   | Cronologia automatica | ultimi **5** | illimitata | `fullHistory` → `count(freeMax: 5)` |
   | QR salvati con nome (preferiti) | **1** | illimitati | `unlimitedEntities` → `count(freeMax: 1)` |
   | Moduli speciali (Wi-Fi, contatto, email, SMS, telefono) | — | ✔ | `customCategories` → `locked()` |
   | Colori, forma dei moduli e degli occhi, logo | — | ✔ | `themeCustomization` → `locked()` |
   | Esportare/condividere il QR come immagine | — | ✔ | **`imageExport`** (nuova, F17.2a) → `locked()` |
   | Backup completo | — | ✔ | `backupRestore` → `locked()` (il **ripristino** resta gratis, come nelle altre app) |

   ⚑ **Perche' 1 preferito gratis e non zero**: «QR salvati senza limite» era la promessa Pro
   approvata; uno gratis fa capire a cosa servono (il Wi-Fi di casa sempre a portata) e rende il
   limite comprensibile invece che misterioso. Se il proprietario preferisce zero, si cambia una
   riga in `feature_limits.dart` e il test di coerenza del paywall.
   ⚑ **Un QR letto con un modulo speciale** (es. un Wi-Fi inquadrato) si **mostra** e si
   **ri-mostra** gratis, anche dalla cronologia: e' un contenuto, non un modulo. Il Pro serve per
   **compilarne o modificarne uno** dal modulo, e per restilizzarlo.
7. **Cronologia accesa di default, spegnibile** (proprietario): interruttore nelle impostazioni
   piu' «Cancella la cronologia». ⚑ Dentro ci finiscono password del Wi-Fi e testi privati: chi
   condivide cose riservate deve poterla evitare.
8. **Nessun widget** (proprietario). Niente `home_widget`.
9. **Icona dal proprietario** (in Download, come Film Tracker): si ripulisce con
   `tool/genera_icone.py` e da li' si prendono i colori. Seme provvisorio `#3BD13B` (il verde dell'icona, arrivata il 2026-10-09 in Download come file «QR Me» senza estensione, PNG 1254x1254 trasparente) finche'
   l'icona non dice altro.
10. **Prima un'interfaccia essenziale, poi 2–3 proposte grafiche** (F17.6), come per F5 e F6.
    **Scelta: «A · Neon»** (proprietario, 2026-10-09, https://claude.ai/artifact/PnrsKsGFRmFsppGHBxBrHk):
    **tema scuro di default**, fondo `#0E1110`, superfici `#151A16` con bordo `#2A332C`, testo
    `#EAF2EA`/`#8FA394`, accento verde neon `#3BD13B` (testo su accento `#06210B`) con alone, titoli
    in Space Grotesk e corpo in Plus Jakarta Sans, QR sempre su pannello **bianco** con alone verde.
    Scartate «B · Carta» (chiara, card arrotondate) e «C · Mirino» (angoli del mirino, monospaziato).
    Applicata gia' durante F17.4 (`lib/app/qr_palette.dart`), quindi F17.6 si chiude con F17.4.
11. **Trappole gia' pagate che valgono anche qui** (F5.0 punto 7 e F6.0 punto 7): `licenseAppId`
    senza trattino basso, deep link di Flutter spento, `ProGate` sulle pagine Pro, virgolette
    tipografiche nei testi, profili iOS via API, invito TestFlight mandato a parte
    (`POST /v1/betaTesterInvitations`), `Runner.entitlements` presente (qui **serve**, c'e' l'App
    Group).

### F17.1 — Specsheet

#### F17.1.1 — Albero dei file da creare

```
packages/micro_core/lib/src/gate/feature_key.dart      + FeatureKey.imageExport (F17.2a)
packages/micro_share/                                  NUOVO package (F17.2b)
├─ pubspec.yaml                                        dipende da receive_sharing_intent ^1.9.0
├─ lib/micro_share.dart                                barrel
├─ lib/src/shared_payload.dart                         sealed SharedPayload (Dart puro)
├─ lib/src/share_inbox.dart                            interfaccia ShareInbox + FakeShareInbox
├─ lib/src/rsi_share_inbox.dart                        implementazione su receive_sharing_intent
├─ ios_template/ShareViewController.swift              il controller dell'estensione (copiato dallo script)
├─ ios_template/Info.plist                             con le regole di attivazione
├─ test/shared_payload_test.dart
└─ codebase_reference.md
tool/aggiungi_share_extension_ios.rb                   come aggiungi_widget_ios.rb, idempotente
apps/qr_me/
├─ lib/main.dart
├─ lib/app/{app,app_config,entitlement,feature_limits,paywall_config,providers,routes,labels,locale_resolution}.dart
├─ lib/domain/
│  ├─ qr_content.dart          sealed QrContent + le 7 sottoclassi
│  ├─ qr_encoder.dart          QrContent → stringa da codificare
│  ├─ qr_decoder.dart          stringa letta → QrContent
│  ├─ qr_capacity.dart         quanto ci sta in un QR per livello di correzione
│  ├─ qr_style.dart            QrStyle, QrLogo, forme, JSON
│  └─ contrast.dart            contrasto e verso dei colori
├─ lib/data/
│  ├─ tables.dart              QrCodes
│  ├─ database.dart            QrDatabase, schemaVersion 1
│  ├─ qr_repository.dart       QrRepository (cronologia, preferiti, potatura)
│  └─ qr_backup_source.dart    BackupSource con i loghi in ImageStore
├─ lib/services/
│  ├─ qr_renderer.dart         QrRenderer: widget e PNG con lo stesso stile
│  ├─ logo_renderer.dart       icona / emoji / foto → immagine del logo
│  ├─ readability_check.dart   rilegge il PNG generato con lo scanner
│  ├─ screen_boost.dart        luminosita' al massimo + schermo acceso, con ripristino
│  ├─ share_router.dart        SharedPayload → rotta giusta
│  └─ content_actions.dart     apri link, chiama, scrivi, copia (url_launcher)
├─ lib/features/
│  ├─ home/home_page.dart              campo di testo, Leggi, Moduli, Preferiti, Cronologia
│  ├─ display/qr_display_page.dart     IL QR a tutto schermo
│  ├─ scan/scan_page.dart              fotocamera + «da immagine»
│  ├─ scan/scan_result_page.dart       cosa c'era nel QR letto, con le azioni
│  ├─ forms/form_page.dart             un'unica pagina, un modulo per QrKind
│  ├─ forms/{wifi,contact,email,sms,phone}_form.dart
│  ├─ style/style_page.dart            colori, forme, logo, anteprima, verifica di leggibilita'
│  ├─ style/logo_picker.dart           galleria / icone / emoji-testo
│  ├─ saved/saved_page.dart            preferiti
│  ├─ history/history_page.dart        cronologia completa (Pro oltre i 5)
│  └─ settings/{settings_page,data_section}.dart
├─ ios/ShareExtension/                 creata da tool/aggiungi_share_extension_ios.rb
├─ tool/{testi.py,testi_*.py,genera_icone.py}
└─ test/ …                             (F17.1.12)
```

#### F17.1.2 — Dipendenze

| Pacchetto | Versione | Perche' |
|---|---|---|
| `qr_flutter` | `^4.1.0` | gia' in Film Tracker; `QrImageView` e `QrPainter` (per il PNG) |
| `flutter_zxing` | `^3.1.0` (risolta 3.1.0) | lettura da fotocamera (`ReaderWidget`) e da file (`zx.readBarcodesImagePathString`). ZXing C++ via FFI, compilato nell'app su Android (CMake/NDK) e iOS: **nessuna rete, nessun servizio Google o Apple**. Ha sostituito `mobile_scanner` (ML Kit su Android) il 2026-10-09 per decisione del proprietario. ☠ Non chiamare mai `readBarcodeImageUrl`/`readBarcodesImageUrl`: l'unico punto del pacchetto che va in rete. ☠ vedi F17.1.11 punto 3 |
| `camera` | `^0.12.1` (risolta 0.12.1; `camera_android_camerax` 0.7.5+1, `camera_avfoundation` 0.10.3+1) | gia' portata da `flutter_zxing`; diretta perche' `scan_page.dart` usa `FlashMode`, `CameraException`, `availableCameras`, che `flutter_zxing` non riesporta. CameraX 1.6.2 + Guava, nessuna libreria di analytics |
| `micro_share` | `path: ../../packages/micro_share` | ricezione da Share Sheet (F17.2b) |
| `screen_brightness` | `^2.1.11` | luminosita' **dell'app** al massimo mentre il QR e' mostrato; nessun permesso |
| `wakelock_plus` | ultima stabile | lo schermo non si spegne mentre qualcuno inquadra |
| `image_picker` | `^1.2.4` | foto per il logo e immagine da cui leggere un QR (photo picker di sistema: niente permesso su Android 13+ e su iOS) |
| `url_launcher` | ultima stabile | «Apri link», «Chiama», «Scrivi email», «Manda SMS» dal QR letto |
| `share_plus` | come `micro_core` (`^13.3.0`) | condividere il PNG (`SharePlus.instance.share(ShareParams(files: [...]))`, la stessa forma usata in `micro_core/lib/src/backup/backup.dart`) |
| `drift`, `flutter_riverpod`, `go_router`, `intl`, `path`, `path_provider` | come Film Tracker | §8.T |

**Non** si usano: `receive_sharing_intent` direttamente dall'app (passa da `micro_share`),
`home_widget`, `image_cropper` (il ritaglio del logo e' quadrato centrato o rotondo, fatto con il
pacchetto `image` gia' noto da Film Tracker: una dipendenza nativa in meno).

#### F17.1.3 — Dominio (Dart puro, `lib/domain/`, zero Flutter)

```dart
// lib/domain/qr_content.dart
enum QrKind { text, url, wifi, contact, email, sms, phone }

enum WifiSecurity { wpa, wep, none }   // WPA copre WPA/WPA2/WPA3 nella stringa WIFI:

sealed class QrContent {
  const QrContent();
  QrKind get kind;
  /// Titolo automatico per la cronologia: il dominio di un link, il nome della rete, il nome del contatto…
  String get autoTitle;
  Map<String, Object?> toFields();                 // per la colonna fields_json
  static QrContent fromFields(QrKind kind, Map<String, Object?> fields);
}
final class TextContent    extends QrContent { const TextContent(this.text); final String text; }
final class UrlContent     extends QrContent { const UrlContent(this.uri); final Uri uri; }
final class WifiContent    extends QrContent { const WifiContent({required this.ssid, this.password = '', this.security = WifiSecurity.wpa, this.hidden = false}); … }
final class ContactContent extends QrContent { const ContactContent({required this.name, this.phone, this.email, this.organization, this.url, this.note}); … }
final class EmailContent   extends QrContent { const EmailContent({required this.to, this.subject = '', this.body = ''}); … }
final class SmsContent     extends QrContent { const SmsContent({required this.number, this.body = ''}); … }
final class PhoneContent   extends QrContent { const PhoneContent(this.number); final String number; }
```

```dart
// lib/domain/qr_encoder.dart
abstract final class QrEncoder {
  static String encode(QrContent content);
}
```

Le codifiche, **esattamente** queste (sono quelle che le fotocamere di sistema di Android e iOS
riconoscono; altre varianti esistono ma alcune fotocamere non le capiscono):

| Tipo | Stringa | Regole |
|---|---|---|
| testo | il testo com'e' | nessuna trasformazione, nemmeno il trim (un testo condiviso si mostra identico) |
| link | `uri.toString()` | si accetta solo `http`/`https`; un link senza schema scritto a mano (`esempio.it`) diventa `https://esempio.it` **solo** se contiene un punto e nessuno spazio |
| Wi-Fi | `WIFI:T:WPA;S:<ssid>;P:<password>;H:true;;` | `T:WEP` / `T:nopass` (e allora niente `P:`); `H:true` solo se nascosta. **Escape con backslash di `\ ; , : "`** in SSID e password. ☠ Senza escape una password con `;` produce un QR che si legge ma connette con la password sbagliata, e l'errore sembra della rete |
| contatto | vCard **3.0**: `BEGIN:VCARD\r\nVERSION:3.0\r\nN:<cognome>;<nome>;;;\r\nFN:<nome completo>\r\nTEL:<tel>\r\nEMAIL:<email>\r\nORG:<org>\r\nURL:<url>\r\nNOTE:<nota>\r\nEND:VCARD` | righe vuote omesse; escape vCard di `\ , ;` e a-capo → `\n`; `N` si ricava da `FN` (ultima parola = cognome). ⚑ 3.0 e non 4.0: la fotocamera di iOS e Android la importano entrambe; MECARD e' piu' corta ma iOS la tratta come testo |
| email | `mailto:<to>?subject=<s>&body=<b>` | `Uri.encodeComponent` su oggetto e corpo; parametri vuoti omessi |
| SMS | `SMSTO:<numero>:<testo>` | ⚑ `SMSTO:` e non `sms:`: e' quella che entrambe le fotocamere di sistema aprono con il testo precompilato |
| telefono | `tel:<numero>` | il numero si normalizza togliendo spazi, trattini e parentesi; il `+` iniziale resta |

```dart
// lib/domain/qr_decoder.dart
abstract final class QrDecoder {
  /// Riconosce il tipo da una stringa letta. Non lancia mai: cio' che non riconosce e' TextContent.
  static QrContent decode(String raw);
}
```

Riconosce (maiuscole/minuscole indifferenti nel prefisso): `WIFI:` (con unescape), `BEGIN:VCARD`
(3.0 e 4.0; si leggono `FN`, `N`, `TEL`, `EMAIL`, `ORG`, `URL`, `NOTE`, il resto si ignora),
`MECARD:` (→ ContactContent), `mailto:` e `MATMSG:` (→ EmailContent), `SMSTO:` e `sms:`
(→ SmsContent), `tel:` (→ PhoneContent), `http://` / `https://` senza spazi (→ UrlContent).
**Proprieta' da testare**: per ogni `QrContent` valido, `decode(encode(c)) == c` (round-trip).

```dart
// lib/domain/qr_capacity.dart
enum QrErrorLevel { low, medium, quartile, high }
abstract final class QrCapacity {
  /// Byte massimi in modalita' byte (UTF-8) alla versione 40: L 2953, M 2331, Q 1663, H 1273.
  static int maxBytes(QrErrorLevel level);
  static bool fits(String payload, QrErrorLevel level);   // utf8.encode(payload).length <= maxBytes
}
```

⚑ **Livello di correzione**: **M** senza logo, **H** con logo (il logo copre fino al ~22% dei
moduli e H ne recupera il 30%). Se il contenuto non sta in H, il logo **si disattiva** con un
avviso («Testo troppo lungo per il logo»); se non sta nemmeno in M, si prova L; se non sta in L, il
QR non si genera e si dice perche' («Troppo lungo per un QR: N caratteri, massimo circa 2.900»). Un
QR enorme si genera ma si legge male: oltre **1.000 byte** si mostra un avviso morbido «QR molto
fitto: avvicina il telefono».

```dart
// lib/domain/qr_style.dart
enum QrModuleShape { square, circle }
enum QrEyeShape { square, circle }

sealed class QrLogo { const QrLogo(); }
final class NoLogo    extends QrLogo { const NoLogo(); }
final class PhotoLogo extends QrLogo { const PhotoLogo({required this.imageName, this.round = false}); final String imageName; final bool round; } // nome in ImageStore
final class IconLogo  extends QrLogo { const IconLogo(this.iconId); final String iconId; }   // id stabile del catalogo icone, NON il codePoint
final class TextLogo  extends QrLogo { const TextLogo(this.text); final String text; }      // 1..3 grafemi (characters), emoji comprese

final class QrStyle {
  const QrStyle({this.foreground = 0xFF000000, this.background = 0xFFFFFFFF,
      this.moduleShape = QrModuleShape.square, this.eyeShape = QrEyeShape.square,
      this.logo = const NoLogo()});
  static const QrStyle plain = QrStyle();
  bool get isPlain;                       // == plain: nessun Pro coinvolto
  QrStyle copyWith({...});
  Map<String, Object?> toJson();
  static QrStyle fromJson(Map<String, Object?> json);   // tollerante: chiavi sconosciute ignorate, mancanti = default
}
```

⚑ `IconLogo` salva un **id testuale** (`'wifi'`, `'phone'`, `'heart'`…) e non il `codePoint`
dell'icona Material: i codePoint cambiano fra versioni dei font di Flutter e un preferito salvato
mostrerebbe un'altra icona dopo un aggiornamento. Catalogo in `lib/features/style/logo_picker.dart`:
`const Map<String, IconData> kLogoIcons` con circa 24 voci (wifi, phone, email, sms, home, work,
heart, star, shop, restaurant, coffee, music, camera, link, person, group, event, location, car,
pets, school, info, gift, payment).

```dart
// lib/domain/contrast.dart
abstract final class Contrast {
  static double ratio(int argbA, int argbB);           // formula WCAG sulla luminanza relativa
  static bool inverted(int foreground, int background); // primo piano piu' chiaro dello sfondo
}
```

Regole nello stile: rapporto **< 3** → avviso rosso «Colori troppo simili, molte fotocamere non lo
leggeranno»; **invertito** → avviso giallo «QR chiaro su scuro: alcune fotocamere non lo leggono»
(si puo' salvare lo stesso). La verifica vera e' comunque `ReadabilityCheck` (F17.1.7).

#### F17.1.4 — Dati (Drift, `lib/data/`)

**`qr_codes`** — una tabella sola: cronologia e preferiti sono lo stesso oggetto con un flag.

| Colonna | Tipo | Vincoli | Note |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `kind` | TEXT | NOT NULL, uno dei `QrKind.name` | |
| `payload` | TEXT | NOT NULL, 1..4000 | la stringa **esatta** codificata nel QR |
| `fields_json` | TEXT | nullable | `QrContent.toFields()` per riaprire il modulo; null per testo e link |
| `title` | TEXT | NOT NULL, 1..80 | `autoTitle` o il nome dato dall'utente |
| `source` | TEXT | NOT NULL: `shared` \| `typed` \| `form` \| `scanned` \| `image` | da dove e' arrivato |
| `style_json` | TEXT | nullable | null = `QrStyle.plain` |
| `is_favorite` | BOOLEAN | NOT NULL default false | preferito = salvato con nome, escluso dalla potatura |
| `created_at` | INTEGER | NOT NULL | epoch ms UTC |
| `last_used_at` | INTEGER | NOT NULL | aggiornato a ogni visualizzazione |

Indici: `(is_favorite, last_used_at DESC)`. Niente UNIQUE su `payload`: due preferiti con lo
stesso contenuto e stili diversi sono legittimi.

```dart
// lib/data/qr_repository.dart
class QrRepository {
  QrRepository(this._db);
  Stream<List<QrCode>> watchHistory();                       // non preferiti, last_used_at DESC
  Stream<List<QrCode>> watchFavorites();                     // preferiti, title ASC
  Future<QrCode?> byId(int id);
  /// Registra un QR mostrato. Se esiste gia' un NON preferito con lo stesso payload e lo stesso
  /// style_json, aggiorna solo last_used_at (niente doppioni in cronologia).
  Future<int> recordShown({required QrContent content, required String payload,
      required String source, QrStyle style = QrStyle.plain});
  Future<void> touch(int id);                                // last_used_at = now
  Future<void> saveAsFavorite(int id, {required String title});
  Future<void> unfavorite(int id);
  Future<void> updateStyle(int id, QrStyle style);
  Future<void> rename(int id, String title);
  Future<void> delete(int id);                               // cancella anche il logo in ImageStore se nessun altro lo usa
  Future<void> clearHistory();                               // solo i non preferiti
  /// Tiene solo gli ultimi [keep] non preferiti. null = nessun limite (Pro).
  Future<int> pruneHistory({required int? keep});
  Future<int> countFavorites();
}
```

⚑ **Cronologia gratis = 5 righe vere, non 5 righe mostrate.** `pruneHistory(keep: 5)` si chiama
dopo ogni `recordShown` nel piano gratuito: le righe in eccesso **si cancellano**. Nasconderle e
rivelarle al Pro sarebbe trattenere dati privati (password Wi-Fi) che l'utente crede spariti. Il
Pro tiene tutto da quando e' comprato in poi; la cronologia vecchia gia' potata non torna (lo dice
il paywall: «Cronologia senza limite da adesso in poi»).
⚑ **Con la cronologia spenta** `recordShown` **non scrive**: il QR si mostra da un oggetto in
memoria (`QrDisplayArgs`, F17.1.6). Si salva solo se l'utente tocca «Salva nei preferiti».
⚑ **Nessun QR in chiaro fuori dall'app**: `android:allowBackup="false"` nel manifest e i file nella
cartella documenti dell'app (su iOS esclusi dal backup iCloud con `NSURLIsExcludedFromBackupKey`
sulla cartella `Documents/` intera, che contiene database e loghi: `ios/Runner/AppDelegate.swift`, F17.7). Le password Wi-Fi non devono finire in un backup automatico che
l'utente non ha scelto. Il backup lo fa solo l'utente, col Pro, in un file che vede.

#### F17.1.5 — Rotte (`lib/app/routes.dart`)

| Rotta | Pagina | Note |
|---|---|---|
| `/` | `HomePage` | |
| `/show` | `QrDisplayPage` | argomenti in `extra: QrDisplayArgs` (contenuto non salvato) |
| `/qr/:id` | `QrDisplayPage` | da cronologia o preferiti |
| `/scan` | `ScanPage` | |
| `/scan/result` | `ScanResultPage` | `extra: ScanResultArgs(raw, source)` |
| `/form/:kind` | `FormPage` | `ProGate(FeatureKey.customCategories)`; `?id=` per modificare |
| `/style` | `StylePage` | `ProGate(FeatureKey.themeCustomization)`; `extra: StyleArgs` |
| `/scan/wifi` | `ScanPage(wifiOnly: true)` | F17.10: torna (`pop`) con il `WifiContent` letto |
| `/label` | `LabelPage` | F17.10: `ProGate(FeatureKey.imageExport)`; `extra: LabelArgs` |
| `/me` | `MyContactPage` | F17.10: `ProGate(FeatureKey.customCategories)`; la scheda «Io» |
| `/saved` | `SavedPage` | |
| `/history` | `HistoryPage` | |
| `/settings` | `SettingsPage` | |
| `/pro` | paywall | §8.T |

`_id()` come in Film Tracker: un `:id` non numerico porta a una pagina «Non trovato», non a
un'eccezione.

#### F17.1.6 — Le schermate

**`HomePage`** — dall'alto:
1. Campo multilinea «Scrivi o incolla» + bottone **Incolla** (legge gli appunti; su iOS il sistema
   mostra il suo avviso di incolla: e' normale) + bottone primario **Mostra QR** (attivo con testo
   non vuoto). Testo → `QrDecoder.decode` (un link scritto diventa UrlContent) → `/show`.
2. **Leggi un QR** (grande, icona fotocamera) → `/scan`.
3. **Moduli**: cinque chip Wi-Fi, Contatto, Email, SMS, Telefono, con `ProBadge` se non Pro;
   toccati senza Pro aprono il paywall (`ProGate`).
4. **Preferiti** (righe con miniatura del QR, titolo), «Vedi tutti» → `/saved`.
5. **Recenti**: gli ultimi 5; sotto, nel piano gratuito, la riga «La cronologia gratuita tiene
   gli ultimi 5 QR» con link al Pro. «Vedi tutta» → `/history`.
Stato vuoto: illustrazione e una riga «Condividi un link o un testo da qualunque app e scegli QR Me».
⚑ Questa riga e' **la spiegazione dell'app**: chi la apre dall'icona deve capire che il modo
giusto di usarla e' dalla condivisione.

**`QrDisplayPage`** — IL motivo dell'app:
- QR il piu' grande possibile: lato = `min(larghezza, altezza disponibile) - 2*16`, centrato, con la
  **zona di rispetto bianca** (4 moduli) sempre presente anche con sfondo colorato (si disegna un
  bordo del colore di sfondo dello stile, mai trasparente).
- All'apertura `ScreenBoost.enable()`: luminosita' dell'app a 1.0 e wakelock; `disable()` in
  `dispose` **e** quando l'app va in pausa (`AppLifecycleListener.onHide`) e si riattiva al ritorno.
  ☠ Se si ripristinasse solo in `dispose`, uscendo con il tasto Home il telefono resterebbe a
  luminosita' piena finche' non si riapre l'app.
- Sotto il QR: titolo e contenuto in chiaro (max 3 righe, tocca per espandere). Per il Wi-Fi la
  password e' **nascosta** (••••) con l'occhio per mostrarla: il QR si mostra a un ospite, la
  password scritta sotto non deve leggerla chi passa.
- Barra azioni: **Salva** (preferito; oltre il limite → paywall), **Stile** (`/style`, Pro),
  **Condividi immagine** (Pro, `imageExport`), **Copia testo**, e se e' un preferito **Modifica**
  (moduli speciali, Pro).
- Tema: in tema scuro la pagina resta scura, ma il **riquadro del QR ha sempre il suo sfondo**
  (bianco, o il colore di sfondo dello stile) con la zona di rispetto: abbaglia meno di una pagina
  tutta bianca e la fotocamera trova comunque il bordo chiaro di cui ha bisogno.

**`ScanPage`** (`lib/features/scan/scan_page.dart`, riscritta il 2026-10-09 su ZXing): il
`ReaderWidget` di `flutter_zxing` a tutto schermo con `codeFormat: Format.qrCode` (⚑ solo QR: i codici
a barre dei prodotti non sono il mestiere dell'app e farebbero scattare letture accidentali),
`tryInverted: true`, `cropPercent: ScanPage.cropPercent` (0.8, piu' largo del mirino disegnato
`_Viewfinder.sideFraction` 0.66), `scanDelay` 150 ms, `scanDelaySuccess: Duration.zero`. Del widget
si usano solo anteprima e decodifica: `showScannerOverlay`, `showFlashlight`, `showGallery`,
`showToggleCamera` tutti `false` (doppioni dei nostri). Il mirino Neon resta il nostro `_Viewfinder`.
- **Torcia**: nella barra, con il `CameraController` che il widget consegna in `onControllerCreated`
  (`setFlashMode(FlashMode.torch/off)`); solo con la fotocamera posteriore; al primo errore sparisce.
- **Prima lettura valida** (`onScan`): vibrazione leggera, poi `_showResult` **smonta** il
  `ReaderWidget` (spegne davvero la fotocamera) e apre `/scan/result`; al ritorno lo rimonta.
  `_handling` blocca le letture doppie.
- **Da immagine**: `pickImageProvider` → `qrImageReaderProvider.read(path)` (ZXing su file).
- **Errori**: `onControllerCreated(null, error)` → `_ScanError`. Permesso negato = `CameraException`
  con codice che inizia per `CameraAccessDenied` (Android CameraX e iOS; iOS anche
  `CameraAccessDeniedWithoutPrompt`) → `MicroEmptyState` «La fotocamera e' spenta» con «Apri le
  impostazioni» su iOS e «Riprova» su Android (chiave nuova al `ReaderWidget` = nuova richiesta);
  qualunque altro errore, o **nessuna fotocamera** (`availableCameras()` vuota: il widget altrimenti
  resterebbe nero per sempre) → «La fotocamera non e' partita». Il bottone Da immagine resta sempre
  usabile.

**`ScanResultPage`**: tipo riconosciuto (icona + etichetta), contenuto leggibile, azioni secondo il
tipo: link → **Apri** (url_launcher, `LaunchMode.externalApplication`) e Copia; telefono → Chiama;
email → Scrivi; SMS → Manda; Wi-Fi → rete e password con **Copia password** (⚑ connettersi
programmaticamente non si fa: su Android 10+ serve un'API di suggerimento con conferma di sistema e
su iOS un'entitlement Hotspot; la fotocamera di sistema lo fa gia' meglio); contatto → campi con
Copia. Sempre: **Mostra come QR** (`/show`, gratis), **Rigenera con stile** (`/style`, Pro),
**Salva**. La lettura entra in cronologia con `source: scanned`/`image` (se la cronologia e' accesa).
⚑ Un link letto **non si apre mai da solo**: si mostra prima, con il dominio in evidenza. Un QR
puo' portare ovunque.

**`FormPage`** (Pro): un modulo per tipo, validazione in linea, anteprima del QR dal vivo in alto.
Wi-Fi: SSID (obbligatorio), password (obbligatoria se non «nessuna»), sicurezza (WPA / WEP /
nessuna), nascosta. Contatto: nome (obbligatorio), telefono, email, azienda, sito, nota. Email: a
(obbligatorio, formato email), oggetto, testo. SMS: numero (obbligatorio), testo. Telefono: numero.
«Mostra QR» salva in cronologia con `source: form` e apre `/qr/:id`.
⚠ **Superato da F17.10** (2026-10-09): niente piu' moduli SMS e Telefono (`kFormKinds` = Wi-Fi,
Contatto, Email; `/form/sms` e `/form/phone` → «Non trovato»); Wi-Fi e Contatto **nuovi** partono
dalle strade (`WifiSources`, `ContactSources`) e il modulo compare solo dopo, gia' compilato, o con
«Inserisci a mano»; il testo dell'Email precompilata e' un campo di almeno 6 righe che cresce. La
modifica di un preferito (`?id=`) apre il modulo come prima.

**`StylePage`** (Pro): anteprima grande in alto (`QrRenderer.widget`), sotto: colore primo piano e
sfondo (12 colori preimpostati + campo esadecimale), forma moduli, forma occhi, **Logo**
(`LogoPicker`: Nessuno / Foto / Icona / Testo), avvisi di contrasto (`Contrast`), e la riga di
**verifica** («✓ Leggibile» / «⚠ Non riesco a leggerlo»), ricalcolata 600 ms dopo l'ultima modifica.
«Applica» salva lo stile sul QR (se e' in cronologia o preferito) o torna a `/show` con lo stile.

**`SettingsPage`**: Cronologia (interruttore, «Cancella la cronologia» con conferma), Pro, Dati
(backup Pro, ripristino gratis; `data_section.dart` come Film Tracker), tema, informazioni,
informativa privacy.

#### F17.1.7 — Servizi (`lib/services/`)

```dart
class QrRenderer {
  const QrRenderer();
  Widget widget({required String payload, required QrStyle style, required double size, ImageProvider? logo});
  /// PNG quadrato di [pixels] lato, zona di rispetto inclusa, per condivisione e verifica.
  Future<Uint8List> png({required String payload, required QrStyle style, int pixels = 1024, ui.Image? logo});
  QrErrorLevel levelFor(String payload, QrStyle style);   // F17.1.3: M o H, ripiego L
}
```
Usa `QrImageView` per il widget e `QrPainter(...).toImageData(pixels, format: ui.ImageByteFormat.png)`
per il PNG, **con gli stessi parametri** (eyeStyle, dataModuleStyle, embeddedImage,
embeddedImageStyle con lato = 22% del QR). ⚑ Un solo punto che traduce `QrStyle` nei parametri di
qr_flutter: se widget e PNG li traducessero separatamente, l'immagine condivisa prima o poi
differirebbe da quella vista.

```dart
class LogoRenderer {
  /// Il logo come immagine quadrata con un "piatto" del colore di sfondo e margine del 12%:
  /// senza piatto i moduli sotto il logo si vedono a pezzi e la fotocamera si confonde.
  Future<ui.Image> render(QrLogo logo, {required int backgroundArgb, required int sizePx, required ImageStore images});
}
```
`TextLogo` e `IconLogo` si disegnano con `PictureRecorder` + `TextPainter` (le icone sono testo nel
font MaterialIcons); `PhotoLogo` si legge da `ImageStore`, ritagliata quadrata al centro (o
rotonda) quando la si importa, una volta sola, a 512 px.

```dart
abstract interface class QrImageReader { Future<List<String>> read(String path); }
class QrReaderUnavailable implements Exception { const QrReaderUnavailable(this.cause); final Object cause; }
class ZxingImageReader implements QrImageReader {
  const ZxingImageReader({this.tryInverted = true});   // «Da immagine», condivisione
  const ZxingImageReader.strict() : tryInverted = false; // verifica di leggibilita'
  static const int maxSize = 1600;
}
class ReadabilityCheck {
  ReadabilityCheck(QrImageReader reader, {QrRenderer renderer, Future<Directory> Function()? tempDir});
  /// Genera il PNG (720 px), lo scrive in un file temporaneo, lo rilegge con il lettore e confronta
  /// il testo con il payload. readable solo se coincide esattamente.
  Future<Readability> check({required String payload, required QrStyle style, ui.Image? logo});
}
```
Tutto in `lib/services/readability_check.dart`. `ZxingImageReader.read` gira in `Isolate.run`
(decodifica PNG + ricerca: decine di ms di CPU, la verifica scatta a ogni pausa mentre si cambia
stile) e chiama `zx.readBarcodesImagePathString(path, DecodeParams(format: Format.qrCode,
tryHarder: true, tryInverted: …, tryDownscale: true, maxSize: 1600, isMultiScan: true))`.
`maxSize` 1600 e non 768 (default): uno screenshot intero ridotto a 768 lascia moduli di 1–2 px.
Un file che non si decodifica come immagine torna come lista vuota («nessun QR»); la libreria nativa
non caricabile (`ArgumentError` da `DynamicLibrary.open`, come sotto `flutter test` sul PC) diventa
`QrReaderUnavailable`.
⚑ La verifica usa **`ZxingImageReader.strict`** (niente QR invertiti): molti lettori non leggono
un QR chiaro su scuro, e dire «Leggibile» perche' ZXing ci riesce provando l'inverso sarebbe una
promessa falsa (lo stile invertito ha gia' l'avviso di `Contrast.inverted`). Per questo
`readabilityCheckProvider` non passa da `qrImageReaderProvider`.
⚑ E' la difesa vera contro i QR «carini ma illeggibili»: le regole di contrasto sono euristiche,
questo e' il test. ☠ Se il lettore non c'e' il risultato e' «non verificato» (grigio), **non**
«illeggibile». Con ZXing succede solo per guasti veri: legge anche su emulatore e simulatore.

```dart
class ScreenBoost {
  Future<void> enable();   // ScreenBrightness.instance.setApplicationScreenBrightness(1.0) + WakelockPlus.enable()
  Future<void> disable();  // ScreenBrightness.instance.resetApplicationScreenBrightness() + WakelockPlus.disable()
}
```
Errori dei plugin **ingoiati e loggati** (`MicroLog`): un telefono che non permette di cambiare la
luminosita' deve comunque mostrare il QR.

```dart
class ShareRouter {
  /// SharedText → QrDecoder.decode → /show (source: shared). SharedImage → QrImageReader (ZXing) → /scan/result
  /// (o messaggio «Nessun QR in questa immagine»). Piu' elementi: si prende il primo testo, poi la prima immagine.
  Future<void> handle(SharedPayload payload, GoRouter router);
}
class ContentActions {
  Future<bool> open(QrContent content);   // url_launcher; false se nessuna app sa aprirlo → snack
}
```

#### F17.1.8 — Condivisione verso l'app (F17.2b, `packages/micro_share/`)

```dart
// packages/micro_share/lib/src/shared_payload.dart
sealed class SharedPayload { const SharedPayload(); }
final class SharedText  extends SharedPayload { const SharedText(this.text); final String text; }   // testo E link (un URL arriva come testo)
final class SharedImage extends SharedPayload { const SharedImage(this.path); final String path; } // file locale gia' copiato

// packages/micro_share/lib/src/share_inbox.dart
abstract interface class ShareInbox {
  /// Cio' che ha aperto l'app (app chiusa). Va letto una volta all'avvio; poi reset().
  Future<List<SharedPayload>> initial();
  /// Cio' che arriva mentre l'app e' aperta.
  Stream<List<SharedPayload>> get incoming;
  Future<void> reset();
}
class FakeShareInbox implements ShareInbox { … }          // per i test delle app

// packages/micro_share/lib/src/rsi_share_inbox.dart
class RsiShareInbox implements ShareInbox { … }          // ReceiveSharingIntent.instance.getInitialMedia()/getMediaStream()/reset()
```

⚑ **Perche' un package separato e non `micro_core`**: `receive_sharing_intent` e' un plugin
nativo con configurazione iOS (estensione, App Group). Messo in `micro_core` finirebbe in **tutte**
le app, comprese TrashCan & co. gia' pubblicate, che non lo configurano. Le app che ricevono
condivisioni (F16, F17, F18, F19) dipendono da `micro_share`, le altre no.
⚑ **Perche' un'interfaccia**: le pagine si testano con `FakeShareInbox`, senza piattaforma.

**Android** (`apps/qr_me/android/app/src/main/AndroidManifest.xml`, sulla `MainActivity`):
`android:launchMode="singleTask"` e due intent-filter `ACTION_SEND` per `text/plain` e `image/*`.
☠ **Niente `READ_EXTERNAL_STORAGE`** anche se il README del plugin lo elenca: le immagini condivise
arrivano come `content://` con permesso temporaneo concesso dal mittente; il permesso di storage su
Play richiede una giustificazione e non serve. Da **verificare** in F17.2b con una condivisione
vera da Galleria e da Chrome; solo se fallisce si rivede.

**iOS**: target **ShareExtension** creato da `tool/aggiungi_share_extension_ios.rb apps/qr_me
ShareExtension group.com.smp.qrme` (idempotente, sul modello di `aggiungi_widget_ios.rb`: stesso
`IPHONEOS_DEPLOYMENT_TARGET` del Runner, «Embed Foundation Extensions» **prima** di «Thin Binary»,
entitlements con l'App Group, `CUSTOM_GROUP_ID` nei build settings di entrambi i target).
`ShareViewController: RSIShareViewController` con `shouldAutoRedirect() -> true` (apre subito
l'app, nessuna schermata intermedia). Info.plist dell'estensione: `NSExtensionActivationRule` con
`NSExtensionActivationSupportsText`, `NSExtensionActivationSupportsWebURLWithMaxCount = 1`,
`NSExtensionActivationSupportsImageWithMaxCount = 1`; `AppGroupId = $(CUSTOM_GROUP_ID)`. Runner:
`AppGroupId` e lo schema `ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)` in `CFBundleURLTypes`.
☠ L'estensione apre l'app host con uno schema URL: e' lo stesso meccanismo di tutte le app
«condividi verso», ma Apple lo tollera senza documentarlo. **Va provato su iPad vero via TestFlight**
(aggiornato il 2026-10-09: e' una nota aperta che non blocca la chiusura di F17.2b; script e build
per il simulatore sono gia' provati); se una versione di iOS lo rompe, il ripiego (deciso ora) e'
un'estensione che **mostra il QR da sola** in SwiftUI con `CIQRCodeGenerator`, senza aprire l'app.

#### F17.1.9 — Pro (`lib/app/feature_limits.dart`, `paywall_config.dart`)

```dart
const Map<FeatureKey, FeatureLimit> qrFeatureLimits = {
  FeatureKey.fullHistory: FeatureLimit.count(freeMax: 5),
  FeatureKey.unlimitedEntities: FeatureLimit.count(freeMax: 1),
  FeatureKey.customCategories: FeatureLimit.locked(),
  FeatureKey.themeCustomization: FeatureLimit.locked(),
  FeatureKey.imageExport: FeatureLimit.locked(),
  FeatureKey.backupRestore: FeatureLimit.locked(),
  // tutte le altre chiavi: FeatureLimit.open() — esplicite, il test di coerenza le vuole tutte
};
```
Prezzi: App Store **1,99 €** (base Italia); Play **1,63 EUR** di base senza IVA (1,99 / 1,22).
Paywall: quattro righe — «Stile: colori e logo nel QR», «Wi-Fi, contatti, email, SMS e telefono»,
«Preferiti e cronologia senza limite», «Condividi il QR come immagine» — piu' «Backup».
**F17.2a** aggiunge `FeatureKey.imageExport` a `micro_core` («Esportare un contenuto generato
come immagine») e una riga `FeatureKey.imageExport: FeatureLimit.open()` nelle mappe di TrashCan,
Full Freezer, Scorte Calore e Film Tracker: i loro `paywall_config_test` vogliono **tutte** le
chiavi mappate (`expect(<mappa>.keys.toSet(), FeatureKey.values.toSet())`) e senza quella riga
diventano rossi. Nessun cambiamento di comportamento per loro.

#### F17.1.10 — Permessi e privacy

| Piattaforma | Permesso | Quando |
|---|---|---|
| Android | `CAMERA` (dichiarato **da noi** nel manifest, oltre che da `camera_android_camerax`) | alla prima apertura di `/scan` |
| Android | **tolti** con `tools:node="remove"`: `RECORD_AUDIO` e `WRITE_EXTERNAL_STORAGE` (li dichiara `camera_android_camerax` per chi registra video; noi apriamo la fotocamera con `enableAudio: false`) e `READ_EXTERNAL_STORAGE` (il fusore la «deduce» da WRITE, IMPLIED nel report di fusione); `uses-feature android.hardware.camera.any` portata a `required="false"` (`tools:replace`): l'app crea QR e legge da immagine anche senza fotocamera | — |
| iOS | `NSCameraUsageDescription` («Per leggere i QR con la fotocamera.» / «To read QR codes with the camera.») | idem |
| iOS | **niente** `NSMicrophoneUsageDescription`: il `ReaderWidget` crea il `CameraController` con `enableAudio: false` e `camera_avfoundation` chiede il microfono solo se `enableAudio` (verificato nel sorgente, `CameraPlugin.swift`). ⚠ Da controllare al primo caricamento su App Store Connect: il binario contiene comunque le API audio del plugin, e se Apple manda l'avviso ITMS-90683 si aggiunge la stringa (F17.7.6) | — |
| iOS | `NSPhotoLibraryUsageDescription` (richiesto da image_picker anche col picker di sistema) | idem per il logo e «Da immagine» |
| Android | `<queries>` per `https`, `tel`, `mailto`, `smsto` (url_launcher su Android 11+) | — |

Informativa: **nessun dato esce dal telefono, su Android come su iOS** (come le altre app; salvo
il server licenze per il Pro). Vale anche per la lettura dei QR da quando lo scanner e' ZXing
(2026-10-09): la decodifica gira tutta dentro l'app, via FFI, senza rete.

**Decisione del proprietario (2026-10-09, non negoziabile)**: «niente dati a Google, assolutamente.
Uno dei requisiti delle microapps e' i dati solo sul telefono». ML Kit e' stato **tolto del tutto**:
`mobile_scanner` → `flutter_zxing` su entrambe le piattaforme (F17.7.7). Registro:
`memory/decisioni.md`, voce «QR Me: ML Kit».

**Verifica «niente Google» dopo il cambio (2026-10-09)**:
- `gradlew :app:dependencies --configuration releaseRuntimeClasspath`: **nessun** `com.google.mlkit`,
  `barcode-scanning`, `play-services-mlkit`, `vision`. `flutter_zxing` non ha dipendenze Maven;
  `camera_android_camerax` porta solo `androidx.camera:*` 1.6.2 e Guava.
- Manifest dell'APK (`aapt dump xmltree`): nessun componente `com.google.mlkit`.
- ⚠ **Restano** `com.google.android.datatransport:*` (servizi `TransportBackendDiscovery`,
  `JobInfoSchedulerService`, `AlarmManagerSchedulerBroadcastReceiver`), `com.google.firebase:firebase-encoders*`
  e `play-services-base/basement/tasks/location`: li porta **`com.android.billingclient:billing:8.0.0`**
  (tramite `in_app_purchase_android`, cioe' il Pro di `micro_core`), non lo scanner. Sono gli stessi in
  tutte le app con il Pro su Android. Se anche il canale di Play Billing va considerato, e' una
  decisione da prendere per **tutte** le microapp, non per QR Me.

**Storico — verifica di F17.7 (2026-10-09), prima della decisione** (superata: ML Kit non c'e' piu').
- **Cosa usa l'app**: `mobile_scanner` 7.4.2 su Android dipende da `com.google.mlkit:barcode-scanning:17.3.0`
  (**bundled**, modello nell'APK; `useUnbundled` non impostato). `autoZoom` spento. Su **iOS** usa
  **Vision di Apple** (solo `Vision`/`AVFoundation` nel codice `darwin/`, nessuna dipendenza esterna):
  nulla esce dal telefono.
- **Cosa invia ML Kit**: **non** le immagini ne' il contenuto letto; **si'** metriche d'uso e
  diagnostica (modello e versione del telefono, pacchetto e versione dell'app, latenza, configurazione,
  eventi, codici d'errore, un **id per installazione**), cifrate in transito, non cedute a terzi.
  Fonti: https://developers.google.com/ml-kit/terms e
  https://developers.google.com/ml-kit/android-data-disclosure
- **Spegnerlo**: **nessun modo supportato** (l'unico controllo documentato e' l'auto-zoom). I trucchi
  sul manifest (togliere i servizi `datatransport`) sono scartati: non documentati e fragili. Nel
  codice non e' cambiato niente.
- **Raccomandazione**: tenere ML Kit e dichiararlo (Data safety: diagnostica, interazioni, id
  d'installazione; informativa del sito corretta su Android). Alternativa: `flutter_zxing` se si vuole
  «nessun dato esce dal telefono» senza eccezioni. Dettagli, testo proposto per l'informativa e
  motivazioni: `memory/decisioni.md`, voce «QR Me: ML Kit».

#### F17.1.11 — Trappole note in anticipo

1. **Escape del Wi-Fi** (F17.1.3): test con SSID e password contenenti `; , : " \`.
2. **Luminosita'** ripristinata anche in pausa (F17.1.6).
3. **ML Kit** e privacy (F17.1.10): risolta togliendo ML Kit (ZXing dal 2026-10-09). ☠ Non
   rimettere `mobile_scanner` ne' altri scanner basati su ML Kit/Google; non chiamare le letture
   «da URL» di `flutter_zxing`.
4. **Logo che copre troppo**: lato fisso al 22% e livello H; la `ReadabilityCheck` e' la prova.
5. **Doppia apertura da condivisione**: con l'app aperta, `incoming` e `initial` possono consegnare
   lo stesso elemento: `reset()` subito dopo aver letto `initial()`, e `ShareRouter` ignora un
   payload identico arrivato entro 2 secondi.
6. **Deep link di Flutter spento** (`FlutterDeepLinkingEnabled = false` su iOS,
   `flutter_deeplinking_enabled = false` su Android): lo schema `ShareMedia-…` lo gestisce il plugin,
   non go_router. Se go_router lo ricevesse cercherebbe una rotta e mostrerebbe «Non trovato».
7. **Testi lunghi condivisi** (un articolo intero): si controlla `QrCapacity` **prima** di
   disegnare; messaggio chiaro invece di un'eccezione di qr_flutter (`InputTooLongException`).

#### F17.1.12 — Test da scrivere

| File | Cosa dimostra |
|---|---|
| `test/domain/qr_encoder_test.dart` | ogni codifica esattamente come in tabella, escape Wi-Fi e vCard, link senza schema |
| `test/domain/qr_decoder_test.dart` | riconoscimento di tutti i prefissi, MECARD/MATMSG/sms:, testo come ripiego, **round-trip** su ogni tipo |
| `test/domain/qr_capacity_test.dart` | limiti per livello, UTF-8 multibyte (emoji contano 4 byte) |
| `test/domain/qr_style_test.dart` | JSON tollerante, `isPlain`, id delle icone stabili |
| `test/domain/contrast_test.dart` | nero/bianco 21, grigi simili < 3, inversione |
| `test/data/qr_repository_test.dart` | niente doppioni in cronologia, potatura a 5 che non tocca i preferiti, cronologia spenta = nessuna scrittura, cancellazione logo orfano |
| `test/data/qr_backup_test.dart` | round-trip del backup con un logo foto |
| `test/services/services_test.dart` (gruppo `ZxingImageReader`) | senza libreria nativa (sotto `flutter test`) il lettore lancia `QrReaderUnavailable` e non un errore qualunque; un file che non si apre come immagine e' «nessun QR»; `strict` non prova gli invertiti |
| `test/services/share_router_test.dart` | testo → `/show`, link → UrlContent, immagine senza QR → messaggio, doppione entro 2 s ignorato (con `FakeShareInbox`) |
| `test/widget/paywall_config_test.dart` | tutte le chiavi mappate, limiti come in F17.0 punto 6 |
| `test/widget/display_page_test.dart` | password Wi-Fi nascosta, azioni Pro con lucchetto, `ScreenBoost` chiamato e ripristinato in pausa (finto) |
| `test/widget/home_page_test.dart` | incolla → mostra, riga dei 5 recenti, chip dei moduli con badge Pro |
| `packages/micro_share/test/shared_payload_test.dart` | conversione da `SharedMediaFile` (testo, url, immagine, misti) |

### F17.2 — Ordine di lavoro (le sottofasi standard Fx.2–Fx.9 applicate)

- **F17.2a** `FeatureKey.imageExport` in `micro_core` + una riga nelle quattro app; test di tutte verdi.
- **F17.2b** `packages/micro_share/` + `tool/aggiungi_share_extension_ios.rb`.
- **F17.2c** Bootstrap `apps/qr_me` (§8.T), icona e splash dall'originale del proprietario.
- **F17.3** Dominio e dati con i test (F17.1.3, F17.1.4).
- **F17.4** Interfaccia essenziale: home, display, scanner, risultato, moduli, stile, impostazioni;
  provata sull'emulatore con condivisione vera (Chrome → QR Me, Galleria → QR Me).
- **F17.5** Pro: limiti, paywall, test di coerenza.
- **F17.6** Proposte grafiche (artifact con 2–3 direzioni), scelta del proprietario.
- **F17.7** Test, rifinitura, iOS sul simulatore, verifica ML Kit (F17.1.10).
- **F17.8** `apps/qr_me/codebase_reference.md` + `packages/micro_share/codebase_reference.md`, `verify_atlas`.
- **F17.9** Rituale di fine fase, card «In arrivo» in vetrina (la pubblicazione la decide il
  proprietario), branch **`v9.0.0`**.

**Azioni del proprietario** (non si possono fare da qui):
- [ ] icona in Download;
- [ ] portale Apple: App ID `com.smp.qrme` e `com.smp.qrme.ShareExtension` con App Groups, gruppo
  `group.com.smp.qrme` (serve da F17.2b per provare su iPad);
- [ ] App Store Connect: l'app «QR Me» (o il ripiego di F17.0 punto 1) quando si arriva allo store;
- [ ] License Server: riga `qrme` nella tabella `apps` e il suo segreto in `APP_SECRETS` (prima di Play).

### F17.10 — Revisione del proprietario dopo la prova su iPad (2026-10-09)

Il proprietario ha provato la build 1.0.0 (1) via TestFlight. **La condivisione verso QR Me funziona**
(«mi genera il qr quasi istantaneamente»): il dubbio di F17.1.8 sull'estensione e' chiuso, il ripiego
non serve. I **moduli** invece non vanno: «Non mi deve far inserire dati a mano, così è ridicolo».
Decisioni (vincono su F17.0 punto 3 e su F17.1.6 `FormPage`):

1. **Wi-Fi: niente compilazione a mano come strada principale.** Due strade, entrambe richieste:
   - **«Inquadra il QR della rete»** (fotocamera) e **«Da un'immagine»** (es. lo screenshot del QR
     che Android mostra in Impostazioni › Wi-Fi › Condividi, o l'etichetta del router): si legge il
     QR, si riconosce `WifiContent`, e si **salva un QR con gli stessi dati** su cui si possono
     mettere logo e colori (Stile). Se il QR letto non e' un Wi-Fi: messaggio chiaro, nessun salvataggio.
   - **«La rete a cui sei connesso»**: il nome della rete (SSID) si legge dal telefono. ☠ **La
     password nessuna app la puo' leggere**, ne' su Android ne' su iOS: e' un limite dei sistemi, non
     una scelta. Quindi: SSID e sicurezza compilati da soli, la password si **incolla** (bottone
     «Incolla» grande: su iPhone Impostazioni › Wi-Fi › (i) › Password la copia; su Android
     Impostazioni › Wi-Fi › Condividi la mostra). La compilazione completamente a mano resta solo
     come ultima riga piccola («Inserisci a mano»).
   - Leggere l'SSID richiede: **Android** il permesso di **posizione precisa** (`ACCESS_FINE_LOCATION`,
     chiesto solo quando si tocca il bottone, con spiegazione: «Android chiede la posizione per dire
     a un'app il nome della rete Wi-Fi; QR Me non usa e non salva la posizione») e la localizzazione
     accesa; **iOS** l'entitlement `com.apple.developer.networking.wifi-info` (capability «Access
     Wi-Fi Information» sull'App ID `com.smp.qrme`, abilitabile via API, poi profilo rigenerato) e
     l'autorizzazione alla posizione «mentre usi l'app» (`NSLocationWhenInUseUsageDescription`).
     Pacchetti: `network_info_plus` (SSID) e `permission_handler` (richiesta del permesso), dopo il
     controllo «nessun SDK che manda dati» (regola dati solo sul telefono).
2. **Contatto: dalla rubrica o «Io».**
   - **«Scegli dalla rubrica»**: il **selettore di sistema** (iOS `CNContactPickerViewController`,
     Android `ACTION_PICK` su `ContactsContract`), che **non richiede il permesso dei contatti**: l'app
     riceve solo il contatto scelto. Pacchetto con selettore nativo senza permesso (es.
     `flutter_native_contact_picker`), da verificare (nessuna telemetria, campi restituiti: nome,
     telefono, email).
   - **«Io»**: la propria scheda, salvata **una volta** nell'app (la si sceglie dalla rubrica la
     prima volta, o la si compila) e poi riusata. ☠ Ne' iOS ne' Android danno a un'app la «mia
     scheda» senza permessi speciali (iOS non la espone affatto; Android chiede `READ_PROFILE`).
   - Poi, come sempre, logo e colori (Stile).
3. **Email → «Email precompilata».** Il modulo serve a creare un QR che apre un'email gia' scritta
   (destinatario, oggetto, testo), non a condividere il proprio indirizzo: titolo e chip si chiamano
   **«Email precompilata» / «Pre-filled email»**, il **testo e' un campo grande multilinea** (almeno 6
   righe visibili, che cresce).
4. **SMS: tolto.** **Telefono: tolto** (ridondante con Contatto). ⚑ Si tolgono i **moduli**, non la
   lettura: un QR `SMSTO:`/`tel:` letto con la fotocamera si riconosce ancora e la pagina del
   risultato offre ancora «Manda SMS» / «Chiama» (dominio e decoder invariati, `QrKind.sms` e
   `QrKind.phone` restano per i QR letti e per la cronologia esistente).
5. **Nuova funzione Pro: «Genera etichetta».** Dalla pagina del QR: un'etichetta con il QR e del
   **testo sotto** (di default il titolo del QR, modificabile, una o due righe), anteprima, formati
   (es. quadrata e rettangolare), **stampa** (pacchetto `printing`, gia' usato da Film Tracker, con
   il dialogo di sistema) e **condividi come immagine** (PNG). Lo stile del QR (colori, logo) viene
   usato anche nell'etichetta. Chiave Pro: `imageExport` (stessa famiglia di «Condividi immagine»);
   la riga del paywall diventa «Condividi il QR come immagine o come etichetta da stampare».
6. **Gia' fatti dal proprietario in App Store Connect:** classificazione per eta' ed etichetta privacy.

**Gia' fatto lato iOS (2026-10-09):** capability `ACCESS_WIFI_INFORMATION` abilitata via API
sull'App ID `com.smp.qrme` (bundleId `Z538F48ZUS`), `com.apple.developer.networking.wifi-info` in
`ios/Runner/Runner.entitlements`, profilo dell'app rigenerato (uuid `7310650a-…`, gruppo + wifi-info).
☠ **`GET /v1/profiles?filter[name]=…` confronta per PREFISSO**: cercando «MicroApps AppStore
com.smp.qrme» per cancellarlo e' stato cancellato anche «… com.smp.qrme.ShareExtension» (ricreato
subito, uuid `d8bc04db-…`). Prima di un DELETE filtrare a mano sul nome **esatto**.

Effetti collaterali: screenshot, grafiche e video dello store vanno rifatti (mostrano SMS e Telefono)
e ricaricati con una build nuova 1.0.0 (2).

**Correzioni dopo la rilettura (2026-10-09, F17.10.6b):** il pulsante «Etichetta» della pagina del QR e'
solo icona (con la scritta, al 130% troncava il titolo «Email precompilata»); la scheda «Io» entra nel
backup come campo facoltativo `myContact` (al ripristino vince il telefono, salvo «Sostituisci tutto»).

---

## F12 — Spending Review (ex «Quanto sto spendendo?»)

**Obiettivo della fase**: il contatore della spesa che si usa **con una mano sola, col carrello
nell'altra**. Il gesto principale e' **batti il prezzo (o inquadra il cartellino) → il totale
enorme in alto sale subito, e la barra dice quanto manca al budget**. Tutto il resto (cartellino
interpretato, bilancia, scontrino, storico) gira intorno a quel gesto senza rallentarlo: il
tastierino e' **sempre** sullo schermo, mai dietro un tocco.

E' anche la fase che costruisce **una volta** l'OCR sul telefono per tutta la piattaforma
(`packages/micro_ocr/`, F12.2b): F13 «Quanto dividiamo?» (scontrino) e qualunque app futura che
legga testo dalla fotocamera la useranno senza rifarla.

**Come si legge questa sezione** (per un coding agent): F12.0 sono le decisioni gia' prese (non si
ridiscutono); F12.1.x e' la specsheet, con file, firme, tabelle e regole esatte; F12.2 e' l'ordine di
lavoro, sottofase per sottofase, con le azioni del proprietario; in fondo, «Domande aperte». Alla
fine di **ogni** sottofase con codice si esegue il **rituale di fine fase di §6** (piano, atlanti,
Projects Tracker, messaggio dettagliato, branch di versione nuovo): non si salta, nemmeno «per
fare prima». Simboli: ☠ = punto rischioso (gia' costato o probabile che costi), ⚑ = scelta non
ovvia, con il perche'.

### F12.0 — Decisioni di partenza (riepilogo, 2026-10-10/11)

Prese con il proprietario (scheda «F12 — Quanto sto spendendo?» in §8 F10–F19, paragrafo F12.0, e
`memory/decisioni.md`, voci del 2026-10-10 e 2026-10-10). Dove contraddicono la scheda delle idee,
vincono queste. Le decisioni **tecniche** prese scrivendo questa specsheet sono marcate ⚑ nei
punti F12.1.x e vanno registrate in `memory/decisioni.md` al rituale di F12.1.

1. **Nome: «Spending Review», uguale in italiano e in inglese** (proprietario, 2026-10-10). Ne
   discendono, **immutabili dopo la pubblicazione**:

   | Cosa | Valore | Note |
   |---|---|---|
   | cartella | `apps/spending_review/` | |
   | `appId` (`MicroAppConfig`) | `'spending_review'` | nome di cartelle e preferenze sul telefono |
   | `licenseAppId` | `'spendingreview'` | **senza trattino basso** (F5.0 punto 7): chiave della tabella `apps` e di `APP_SECRETS` sul License Server |
   | bundle iOS / `applicationId` Android | `com.smp.spendingreview` | §1.1 |
   | SKU del Pro | `spendingreview_pro_lifetime` | uno SKU pubblicato non si cancella ne' si riusa |
   | nome sotto l'icona | «Spending Review» | `CFBundleDisplayName`, `android:label` |
   | nome della scheda negli store | «Spending Review» | ☠ quasi certamente gia' usato da altri: si prova alla creazione (App Store risponde 409 `DUPLICATE.DIFFERENT_ACCOUNT`, come per Full Freezer e Film Tracker). **Ripiego gia' deciso**: «Spending Review – Conto spesa» (italiano, 29 caratteri) e «Spending Review – Cart Total» (inglese, 28 caratteri); entrambi sotto i 30 caratteri di titolo. «Project Microapps» va nel **sottotitolo** (decisione del 2026-10-08) |
   | `package_name` Dart | `spending_review` | `name:` del `pubspec.yaml` |

2. **Android e iPhone dal primo commit**, come Film Tracker e QR Me: `flutter create
   --platforms=android,ios`, iOS solo iPhone (`TARGETED_DEVICE_FAMILY = 1`, decisione del
   2026-10-04), prove su iPad in compatibilita' iPhone (memoria del proprietario). **Nessun App
   Group e nessuna estensione** (niente widget, niente condivisione): il proprietario registra solo
   l'App ID `com.smp.spendingreview`, senza capability.
3. **Nessun widget** (proprietario, 2026-10-10): niente `home_widget`. **Nessuna notifica** (non
   richieste: niente `NotificationService`, niente `POST_NOTIFICATIONS`). ⚑ **Niente voce in v1**:
   la scheda delle idee citava il parser vocale di Full Freezer, ma il proprietario ha scelto
   tastierino + fotocamera; la voce si aggiunge solo se lui la chiede (e allora solo on-device,
   decisione del 2026-10-10 su Full Freezer).
4. **Cosa fa** (proprietario, 2026-10-10/11):
   - **tastierino numerico sempre visibile** per il prezzo a mano, con i tasti **×** (quantita'),
     **−** (sconto/buono), **⌫** (cancella), **+** (aggiungi);
   - **budget** con barra;
   - **due tasti diversi, due flussi distinti**: **Cartellino** (verde) e **Scontrino** (scuro). Non
     un tasto «intelligente» che indovina;
   - il **cartellino va INTERPRETATO**, non solo letto: nome, prezzo da pagare, prezzo
     barrato/«anziche'», prezzo al kg/al litro, offerte 3x2 / 2x1 / -30%, centesimi scritti piccoli;
     se c'e' ambiguita' l'app **propone** e l'utente **conferma con un tocco**; un cartellino letto
     **non si aggiunge mai da solo** (`docs/specs/f12-ocr.md` §7);
   - **prodotti a peso: entrambe le strade**: peso scritto a mano dopo un cartellino al kg, **e**
     lettura dell'etichetta della bilancia (che porta gia' il totale);
   - **Scontrino** serve **sia** a confrontare alla cassa il contato con lo scontrino (differenza e
     righe sospette) **sia** a registrare la spesa dallo scontrino letto, anche se non si e' contato
     niente;
   - **lo scritto a mano non e' supportato** (zero cifre lette sui campioni c04, c05, c25): si usa
     il tastierino, e l'app lo dice.
5. **Gratis e Pro: «spesa gratis, revisione Pro»**, Pro **2,99 €** una tantum (proprietario,
   2026-10-10):

   | Funzione | Gratis | Pro | `FeatureKey` → limite |
   |---|---|---|---|
   | Tastierino, totale, quantita', sconti a mano | ✔ | ✔ | — |
   | Budget con barra | ✔ | ✔ | — |
   | **Lettura dei cartellini, illimitata** (con interpretazione e offerte) | ✔ | ✔ | — |
   | Peso a mano e **etichetta della bilancia** | ✔ | ✔ | — |
   | Spese salvate | ultime **5** visibili | tutte | `fullHistory` → `count(freeMax: 5)` |
   | **Scontrino**: controllo alla cassa **e** registrazione dallo scontrino | — | ✔ | **`documentScan`** (nuova, F12.2a) → `locked()` |
   | **Statistiche**: per mese e per negozio, spesa media, sforamenti del budget | — | ✔ | `statistics` → `locked()` |
   | Export **CSV** | — | ✔ | `csvExport` → `locked()` |
   | **Backup** | — | ✔ | `backupRestore` → `locked()` (il **ripristino** resta gratis, come in tutte le app) |

   ⚑ **Perche' una chiave nuova `documentScan` per lo Scontrino.** Le chiavi esistenti sono state
   provate una per una: `photos` vuol dire «allegare fotografie ai record» (in Full Freezer e Film
   Tracker e' **gratis**, e qui lo scontrino **non** si conserva come foto, F12.1.15); `pdfReport`,
   `imageExport`, `csvExport` sono esportazioni; `customCategories`, `themeCustomization`,
   `secondaryEntities`, `unlimitedEntities` sono altro. Usarne una «perche' tanto e' solo un nome»
   renderebbe falsi gli atlanti di due app e il test di coerenza del paywall. La chiave nuova e'
   **generica** («leggere con la fotocamera un documento intero e ricavarne i dati») perche' la
   riusera' F13 per lo scontrino da dividere. **Costo**: una riga `FeatureKey.documentScan:
   FeatureLimit.open()` nelle mappe delle **cinque** app esistenti (TrashCan, Full Freezer, Scorte
   Calore, Film Tracker, QR Me), perche' i loro `paywall_config_test` vogliono **tutte** le chiavi
   (`expect(<mappa>.keys.toSet(), FeatureKey.values.toSet())`): F12.2a.
   ⚑ **Spese oltre le 5 nel gratis: conservate e nascoste, non cancellate** (proposta, vedi
   «Domande aperte» D1). Diversamente da QR Me (dove le righe in eccesso **si cancellano** perche'
   contengono password Wi-Fi), qui i dati sono la cronologia della spesa dell'utente, sul suo
   telefono: cancellarli toglierebbe proprio cio' che il Pro promette («storico illimitato con
   statistiche») a chi lo compra dopo tre mesi. Il piano gratuito **mostra** le ultime 5 chiuse e una
   riga «Le altre N spese sono sul telefono: con il Pro le rivedi tutte, con le statistiche».
   Prezzi: App Store **2,99 €** (base Italia); Play **2,45 EUR** di base senza IVA (2,99 / 1,22,
   stessa regola di F17.1.9), che il cliente vede a 2,99 €.
6. **Interfaccia «C · Una mano»** (proprietario, 2026-10-10,
   https://claude.ai/artifact/Y9KH2qk6PeAYKzQBTyvdhY, tavola `UnaMano.dc.html`): tema **scuro di
   default**; valori esatti in F12.1.12. Scartate «A · Scontrino» e «B · Cassa». ⚑ Come in QR Me, la
   grafica e' gia' scelta: si applica **da F12.4**, e F12.6 si chiude con F12.4.
7. **Icona del proprietario**: `docs/specs/icona-spending-review.png` (PNG 1254x1254 RGBA
   trasparente). Si ripulisce e si generano icone e splash con `tool/genera_icone.py` (copiato da
   `apps/qr_me/tool/genera_icone.py`). Seme del tema `#4ADE80` (il verde della grafica scelta).
8. **OCR solo sul telefono** (`docs/specs/f12-ocr.md`, `memory/decisioni.md` 2026-10-10): **iOS
   Vision** (locale, 0 MB); **Android PaddleOCR PP-OCRv5 mobile** (rilevatore `PP-OCRv5_mobile_det`
   + riconoscitore `latin_PP-OCRv5_mobile_rec`) su **ONNX Runtime 1.28.0 esatta**; ripiego gli stessi
   modelli su **NCNN**; Tesseract ultima spiaggia; **ML Kit escluso**, **LiteRT 2.x escluso**. ☠ ONNX
   Runtime **dalla 1.29** contiene telemetria Microsoft accesa di default (ContentProvider
   `ai.onnxruntime.TelemetryInitializer`, permesso `INTERNET`, invio a
   `mobile.events.data.microsoft.com`): **mai** una versione diversa da 1.28.0 senza una nuova voce
   in `memory/decisioni.md`. Misure sui 60 campioni (f12-ocr.md §7): bilancia e scontrino **100%**
   sul totale; prezzo del cartellino **78%** come cifre, ma i **centesimi in apice** escono senza
   virgola («229») o spezzati («1 | 06») → **parser con le posizioni dei riquadri** (F12.1.4).
9. **Dati solo sul telefono** (regola del 2026-10-09, tutte le app): nessun SDK che manda dati a
   terzi, nemmeno metriche. **Unica eccezione**: Play Billing e il nostro server licenze per il Pro
   su Android (decisione del 2026-10-09). ☠ Conseguenza pratica gia' verificata scrivendo questa
   specsheet: Play Billing porta `com.google.android.datatransport:transport-backend-cct`, che
   dichiara **`INTERNET`** e `ACCESS_NETWORK_STATE` nel manifest unito (report di fusione di QR Me,
   `apps/qr_me/build/app/outputs/logs/manifest-merger-debug-report.txt`). Quindi il controllo «niente
   `INTERNET` nel manifest unito» di f12-ocr.md §5.3 **non si puo' fare alla lettera**: diventa
   «`INTERNET` ammesso **solo** se arriva da `transport-backend-cct` o da `src/debug`» (F12.1.2).
10. **Sito**: card «In arrivo» in `site/src/apps.php` nello stesso giro in cui l'app nasce (F12.9);
    pulsanti degli store **solo quando l'app e' su entrambi** (decisione del 2026-10-10).
11. **Trappole gia' pagate che valgono anche qui**: `licenseAppId` senza trattino basso; deep link
    di Flutter spento (`FlutterDeepLinkingEnabled = false`, `flutter_deeplinking_enabled = false`:
    l'app non ne riceve, ma un link estraneo non deve finire in go_router); `ProGate` **sulla
    pagina** Pro, non solo sul bottone (Full Freezer 2026-10-07); virgolette tipografiche nei testi
    (`tool/testi*.py`); nessun glifo ✓⚠✗ nei testi (guardia `texts_glyphs_test.dart` di QR Me);
    profili iOS via API e invito TestFlight a parte (`POST /v1/betaTesterInvitations`);
    `GET /v1/profiles?filter[name]=` confronta per **prefisso** (F17.10): filtrare a mano sul nome
    esatto prima di un DELETE; `camera_android_camerax` dichiara `RECORD_AUDIO` e
    `WRITE_EXTERNAL_STORAGE`: si tolgono con `tools:node="remove"` (F17.1.10); `analyzer` con tetto
    `<14.4.0` per Drift (pubspec di QR Me); `permission_handler` non serve (il permesso della
    fotocamera lo chiede il plugin `camera`).

### F12.1 — Specsheet

#### F12.1.1 — Albero dei file da creare

```
packages/micro_core/lib/src/gate/feature_key.dart       + FeatureKey.documentScan (F12.2a)
apps/{trashcan,full_freezer,scorte_calore,film_tracker,qr_me}/lib/app/feature_limits.dart
                                                        + FeatureKey.documentScan: FeatureLimit.open() (F12.2a)
packages/micro_ocr/                                     NUOVO plugin Flutter (F12.2b), Android + iOS
├─ pubspec.yaml                                         plugin: android (package com.smp.micro_ocr, pluginClass MicroOcrPlugin), ios (pluginClass MicroOcrPlugin)
├─ lib/micro_ocr.dart                                   barrel: esporta tutto (usa flutter/services)
├─ lib/riga_ocr.dart                                    libreria PURA (niente Flutter): Riquadro, RigaOcr, OcrModo — la importa il dominio dell'app
├─ lib/src/riga_ocr.dart                                Riquadro, RigaOcr, OcrModo
├─ lib/src/ocr_engine.dart                              interfaccia OcrEngine + OcrNonDisponibile
├─ lib/src/canale_ocr_engine.dart                       CanaleOcrEngine (MethodChannel 'micro_ocr')
├─ lib/src/fake_ocr_engine.dart                         FakeOcrEngine per i test delle app
├─ android/build.gradle.kts                             onnxruntime-android strictly 1.28.0, exifinterface
├─ android/consumer-rules.pro                           keep di ai.onnxruntime.** (R8)
├─ android/src/main/AndroidManifest.xml                 VUOTO di permessi
├─ android/src/main/assets/ppocrv5/det.onnx             PP-OCRv5_mobile_det (≈ 4,8 MB) — F12.1.9
├─ android/src/main/assets/ppocrv5/rec_latin.onnx       latin_PP-OCRv5_mobile_rec (≈ 7,9 MB)
├─ android/src/main/assets/ppocrv5/latin_dict.txt       dizionario del riconoscitore (502 simboli, € compreso)
├─ android/src/main/assets/ppocrv5/MODELLI.md           provenienza, SHA-256, licenza Apache-2.0
├─ android/src/main/assets/ppocrv5/LICENSE-PaddleOCR.txt  testo Apache-2.0
├─ android/src/main/kotlin/com/smp/micro_ocr/MicroOcrPlugin.kt     canale, thread di lavoro
├─ android/src/main/kotlin/com/smp/micro_ocr/PpOcrEngine.kt        sessioni ORT, det → crop → rec
├─ android/src/main/kotlin/com/smp/micro_ocr/ImmagineIngresso.kt   decodifica + rotazione EXIF + riduzione
├─ android/src/main/kotlin/com/smp/micro_ocr/Preprocess.kt         tensori di det e rec
├─ android/src/main/kotlin/com/smp/micro_ocr/DbPostprocess.kt      mappa di probabilita' → riquadri
├─ android/src/main/kotlin/com/smp/micro_ocr/CtcDecoder.kt         uscita del rec → testo + confidenza
├─ android/src/main/kotlin/com/smp/micro_ocr/Strisce.kt            scontrini lunghi: strisce sovrapposte e fusione riquadri
├─ android/src/test/kotlin/com/smp/micro_ocr/{DbPostprocessTest,CtcDecoderTest,PreprocessTest,StrisceTest}.kt  JUnit sulla JVM
├─ ios/micro_ocr/Sources/micro_ocr/MicroOcrPlugin.swift            canale
├─ ios/micro_ocr/Sources/micro_ocr/VisionOcr.swift                 VNRecognizeTextRequest
├─ ios/micro_ocr/Package.swift  +  ios/micro_ocr.podspec           generati da flutter create, nessuna dipendenza esterna
├─ test/riga_ocr_test.dart, test/canale_ocr_engine_test.dart, test/fake_ocr_engine_test.dart
├─ tool/verifica_privacy_android.ps1                    controllo sull'APK di release (F12.1.2)
└─ codebase_reference.md
tool/_common.ps1                                        + micro_ocr nell'elenco dei progetti (come micro_share)
apps/spending_review/
├─ pubspec.yaml, l10n.yaml, analysis_options.yaml, flutter_launcher_icons.yaml, flutter_native_splash.yaml
├─ assets/fonts/{PlusJakartaSans-Variable.ttf,SpaceGrotesk-Variable.ttf,OFL-*.txt}   copiati da apps/qr_me/assets/fonts
├─ assets/icons/spending_review_logo.png                 dall'originale del proprietario
├─ lib/main.dart
├─ lib/app/{app,app_config,entitlement,feature_limits,paywall_config,providers,routes,labels,locale_resolution}.dart
├─ lib/app/sr_palette.dart          i colori di «C · Una mano» (F12.1.12)
├─ lib/domain/
│  ├─ arrotonda.dart                arrotondamenti al centesimo, interi (F12.1.3)
│  ├─ quantita.dart                 sealed Quantita: Pezzi, AMisura; UnitaMisura
│  ├─ offerta.dart                  sealed Offerta: NxM, Percentuale, PrezzoBarrato, SecondoAPercento, PrezzoConCarta
│  ├─ riga_spesa.dart               RigaSpesa, OrigineRiga, calcolo del totale di riga
│  ├─ spesa.dart                    Spesa, StatoSpesa, FonteRighe, StatoBudget
│  ├─ tastierino.dart               TastierinoState (macchina a stati del tastierino) + TastoTastierino
│  ├─ nomi.dart                     normalizzazione dei nomi, similarita' (cartellino ↔ scontrino)
│  ├─ lettura/numeri_ocr.dart       estrazione e normalizzazione dei numeri dal testo OCR
│  ├─ lettura/righe_visive.dart     raggruppamento dei riquadri in righe visive
│  ├─ lettura/cartellino_parser.dart   CartellinoParser → LetturaCartellino
│  ├─ lettura/bilancia_parser.dart     BilanciaParser → LetturaBilancia
│  ├─ lettura/scontrino_parser.dart    ScontrinoParser → LetturaScontrino
│  ├─ lettura/unisci_parti.dart        fusione di piu' foto dello stesso scontrino
│  ├─ confronto.dart                Confronto: contato vs scontrino → EsitoConfronto
│  └─ statistiche.dart              StatisticheSpesa: per mese, per negozio, media, sforamenti
├─ lib/data/
│  ├─ tables.dart                   Negozi, Spese, Righe
│  ├─ database.dart                 SpendingDatabase, schemaVersion 1
│  ├─ spesa_repository.dart         SpesaRepository
│  └─ spending_backup_source.dart   BackupSource
├─ drift_schemas/drift_schema_v1.json   dump dello schema per i test di migrazione futuri
├─ lib/services/
│  ├─ lettura_service.dart          foto → OcrEngine → parser, in background
│  ├─ fotocamera.dart               scatto + ritaglio al mirino
│  ├─ csv_export.dart               CsvWriter di micro_core
│  └─ aptica.dart                   vibrazioni brevi, spegnibili
├─ lib/features/
│  ├─ common/{pro_gate,una_mano}.dart   ProGate (copia di QR Me) e componenti grafici comuni
│  ├─ spesa/spesa_page.dart             LA schermata: totale, budget, lista, due tasti, tastierino
│  ├─ spesa/tastierino_widget.dart      i 16 tasti
│  ├─ spesa/budget_sheet.dart           imposta il budget di questa spesa
│  ├─ spesa/riga_sheet.dart             modifica/elimina una riga
│  ├─ cartellino/cartellino_camera_page.dart   mirino, scatto, «Cartellino | Bilancia»
│  ├─ cartellino/conferma_cartellino_sheet.dart   la proposta da confermare con un tocco
│  ├─ cartellino/peso_sheet.dart               peso a mano dopo un cartellino al kg
│  ├─ cartellino/conferma_bilancia_sheet.dart  etichetta della bilancia letta
│  ├─ scontrino/scontrino_camera_page.dart     foto (anche in piu' parti), Pro
│  ├─ scontrino/confronto_page.dart            scontrino contro conto
│  ├─ scontrino/registra_scontrino_page.dart   registrazione della spesa dallo scontrino
│  ├─ chiusura/chiusura_page.dart              chiudere e salvare la spesa
│  ├─ storico/storico_page.dart                le spese chiuse (5 visibili nel gratis)
│  ├─ storico/dettaglio_spesa_page.dart
│  ├─ statistiche/{statistiche_page,grafico_mesi}.dart   Pro
│  ├─ impostazioni/{impostazioni_page,data_section,negozi_page}.dart
│  └─ dev/ocr_dev_page.dart                    SOLO debug: esporta le righe OCR come fixture (F12.1.17)
├─ android/app/build.gradle.kts         + task verificaPrivacyOcr (F12.1.2)
├─ ios/Runner/{Info.plist,AppDelegate.swift,it.lproj,en.lproj}
├─ tool/{testi.py,testi_*.py,genera_icone.py}          testi → ARB come QR Me
├─ tool/esporta_fixture_ocr.py          crea le fixture del banco del parser (F12.1.17)
├─ test/fixtures/ocr/ppocrv5/*.json     righe OCR + verita' dei 33 campioni a licenza libera
├─ test/fixtures/ocr/LICENZE.md         fonte, autore, licenza di ogni fixture
├─ test/fixtures/ocr/soglie.json        il «cricchetto» del banco (F12.1.17)
└─ test/ …                              (F12.1.17)
```

#### F12.1.2 — Dipendenze e guardie di privacy in build

**`packages/micro_ocr/pubspec.yaml`**: `flutter`, `meta`, `plugin_platform_interface` **non**
serve (plugin interno, non federato). Nessuna dipendenza pub oltre a Flutter.

**`packages/micro_ocr/android/build.gradle.kts`** (le righe che contano):

```kotlin
android {
    namespace = "com.smp.micro_ocr"
    compileSdk = 36
    defaultConfig { minSdk = 24; consumerProguardFiles("consumer-rules.pro") }
    androidResources { noCompress += "onnx" }   // ⚑ vedi sotto
}
dependencies {
    implementation("com.microsoft.onnxruntime:onnxruntime-android") {
        version { strictly("1.28.0") }          // ☠ MAI 1.29+: telemetria (F12.0 punto 8)
    }
    implementation("androidx.exifinterface:exifinterface:1.4.1")   // rotazione delle foto
    testImplementation("junit:junit:4.13.2")
}
```

⚑ **ONNX Runtime direttamente da Maven, NON tramite `flutter_onnxruntime`** (che f12-ocr.md §5.1
suggeriva). Motivi, in ordine di peso:
1. `flutter_onnxruntime` 1.9.0 ha anche il lato iOS e porta **`onnxruntime-objc` 1.28.0** nell'app
   iPhone: ≈ 10 MB di motore **inutile** (su iOS legge Vision) e una seconda copia di ORT da tenere
   bloccata. Un plugin Flutter non si puo' escludere da una piattaforma.
2. Con `strictly("1.28.0")` nel **nostro** `build.gradle.kts` la versione la blocca Gradle (risoluzione
   che **fallisce** se qualcuno chiede altro), non la buona volonta' di un pacchetto di terzi che al
   prossimo aggiornamento portera' la 1.29.
3. Pre e post-elaborazione girano in Kotlin sui `Bitmap` nativi: nessun tensore da milioni di float
   che attraversa il canale verso Dart.
Costo: circa 600 righe di Kotlin scritte da noi (F12.1.9), testate sulla JVM.

⚑ **`noCompress += "onnx"`**: i pesi in virgola mobile si comprimono poco (f12-ocr.md §3.1) e
decomprimere 12,7 MB a ogni avvio a freddo costa tempo; l'AAB viene comunque compresso da Play per il
download.

**`apps/spending_review/pubspec.yaml`** — le versioni si risolvono con
`pwsh ../../tool/fl.ps1 pub add <pacchetto>`, **non** a memoria (regola del pubspec di QR Me):

| Pacchetto | Versione | Perche' |
|---|---|---|
| `micro_core` | `path: ../../packages/micro_core` | Money, CivilDate, gate, paywall, backup, CSV, tema |
| `micro_ocr` | `path: ../../packages/micro_ocr` | l'OCR (F12.1.9) |
| `camera` | `^0.12.1` (come QR Me) | anteprima con il **nostro** mirino e `takePicture()`. ⚑ Non la fotocamera di sistema via `image_picker`: serve il mirino per far inquadrare **un** cartellino da vicino, che e' il caso in cui l'OCR rende (f12-ocr.md §7: le foto larghe del web sono il caso sfavorevole) |
| `image_picker` | `^1.2.4` (come QR Me) | «Da una foto»: un cartellino o uno scontrino gia' fotografati (photo picker di sistema, nessun permesso su Android 13+ e iOS). ⚑ Si', serve: lo scontrino lungo spesso lo si fotografa con calma a casa |
| `image` | `^4.10.1` (come QR Me) | ritaglio della foto al mirino prima dell'OCR, in un isolate |
| `drift`, `sqlite3`, `sqlite3_flutter_libs`, `flutter_riverpod`, `go_router`, `intl`, `meta`, `path`, `path_provider`, `share_plus` | come QR Me | §8.T; `share_plus` per CSV e backup (stesso vincolo di `micro_core`) |
| dev: `drift_dev`, `build_runner`, `analyzer: ">=14.0.0 <14.4.0"`, `flutter_launcher_icons`, `flutter_native_splash`, `shared_preferences`, `integration_test` | come QR Me | |

**Non** si usano: `flutter_onnxruntime` (sopra), `google_mlkit_text_recognition` e qualunque
pacchetto ML Kit (regola del 2026-10-09), `tflite_flutter`/LiteRT 2.x (porta `play-services-*`),
`flutter_tesseract_ocr` (ultima spiaggia, non ora), `pdf_ocr_ondevice` (scarica il modello da
internet), `mobile_scanner`, `home_widget`, `permission_handler` (il permesso della fotocamera lo
chiede `camera`), `speech_to_text`, `fl_chart` (grafici con `CustomPainter`, come le altre app).
☠ Prima di aggiungere **qualunque** altra dipendenza nativa: controllarne nel `pubspec.lock` e in
`gradlew :app:dependencies` le dipendenze Android/iOS (Firebase, `datatransport` fuori da Billing,
`play-services-*`, ML Kit, SDK di crash o analisi). Se ne porta una, non si usa.

**Le guardie di privacy (obbligatorie, nate dalla telemetria di ORT 1.29):**

1. **In Gradle, a ogni build di release** — task `verificaPrivacyOcr` in
   `apps/spending_review/android/app/build.gradle.kts`, agganciato con
   `tasks.named("processReleaseMainManifest") { finalizedBy("verificaPrivacyOcr") }`. Legge il
   manifest unito di release e il report
   `build/app/outputs/logs/manifest-merger-release-report.txt` e **fa fallire la build** se:
   - compare la stringa `ai.onnxruntime.TelemetryInitializer` o qualunque `provider` con
     `ai.onnxruntime` nel nome;
   - il blocco `uses-permission#android.permission.INTERNET` del report contiene una riga
     `ADDED from`/`MERGED from` che **non** sia `com.google.android.datatransport:transport-backend-cct`
     (Play Billing, eccezione del 2026-10-09);
   - compare `uses-permission#android.permission.ACCESS_NETWORK_STATE` da una fonte diversa da
     `transport-backend-cct` (in QR Me lo portava anche `network_info_plus`, che qui non c'e').
   ⚑ Nel manifest unito i permessi sono deduplicati: guardare solo il manifest non dice **chi** ha
   portato `INTERNET`. Per questo si legge il **report di fusione**, che elenca le fonti.
2. **Sulle dipendenze risolte** — nello stesso task: `configurations.getByName("releaseRuntimeClasspath")`
   e le sue `resolvedConfiguration.resolvedArtifacts`; fallisce se `com.microsoft.onnxruntime` ha
   versione ≠ `1.28.0`, o se compare un gruppo `com.google.mlkit`, `com.google.firebase:firebase-analytics`,
   `com.google.android.gms:play-services-tflite*`, `com.google.ai.edge.litert`.
3. **Sul binario** — `packages/micro_ocr/tool/verifica_privacy_android.ps1 -Apk <percorso>`, da
   lanciare dopo `flutter build apk --release` (e in F12.7 prima di ogni caricamento su Play): estrae
   `lib/arm64-v8a/libonnxruntime.so` e cerca le stringhe `events.data.microsoft.com`, `OneCollector`,
   `1DS`; ne basta una per uscire con codice 1. Stampa anche la riga di `aapt2 dump permissions`.
4. ☠ **16 KB page size** (obbligo Play per le app con target Android 15+): in F12.2b verificare
   l'allineamento delle `.so` di ORT 1.28.0 con `zipalign -c -P 16 -v 4 app-release.apk`. Se ORT
   1.28.0 non e' allineata a 16 KB: **non** si sale di versione; si passa al ripiego NCNN o alla
   build ORT nostra con `--no_telemetry` (f12-ocr.md §5.1, §5.2), con una voce nuova in
   `memory/decisioni.md`.

#### F12.1.3 — Dominio: denaro, quantita', offerte, righe, spesa, tastierino (Dart puro, `lib/domain/`)

Regola di tutto il dominio: **importi in centesimi interi** (`Money` di `micro_core`), **pesi e volumi
in millesimi interi** (grammi, millilitri). Nessun `double` nei conti.

```dart
// lib/domain/arrotonda.dart
abstract final class Arrotonda {
  /// a × b / divisore, arrotondato al centesimo con la regola «mezzo in su» (half-up), in interi.
  /// Per i valori negativi arrotonda il valore assoluto e rimette il segno (simmetrico).
  static int mezzoInSu(int a, int b, int divisore);
  /// Prezzo di una quantita' a misura: centesimiAlKg × millesimi / 1000, half-up.
  static Money perMisura(Money alKgOLitro, int millesimi);
  /// Importo dello sconto percentuale: pieno × percento / 100, half-up.
  static Money scontoPercentuale(Money pieno, int percento);
}
```

⚑ **Perche' half-up e in interi**: tutte le 9 etichette della bilancia e le 4 righe pesate di s03
tornano **solo** con «mezzo in su» (s03: 0,126 kg × 7,50 = 0,945 → **0,95**; 0,098 × 7,50 = 0,735 →
**0,74**: l'arrotondamento bancario darebbe 0,94 e 0,74, sbagliando la prima). `Money.operator *`
di `micro_core` usa `double.round()`: va bene per moltiplicare per un intero, **non** per pesi
(0,1 + 0,2 in virgola mobile). Formula intera per valori ≥ 0: `(a * b + divisore ~/ 2) ~/ divisore`.
⚑ **Sconto percentuale: si arrotonda lo SCONTO, poi si sottrae** (come le righe «SCONTO -0,40» dello
scontrino). Prova: c29 «2,99 −50%» stampa **1,49**: lo sconto 1,495 → 1,50, e 2,99 − 1,50 = 1,49;
arrotondare il prezzo finale (1,495 → 1,50) darebbe il numero sbagliato.

```dart
// lib/domain/quantita.dart
enum UnitaMisura { kg, l }

sealed class Quantita { const Quantita(); }
/// Pezzi interi, 1..999.
final class Pezzi extends Quantita { const Pezzi(this.n); final int n; }
/// Peso (grammi) o volume (millilitri), 1..99999 millesimi di [unita].
final class AMisura extends Quantita { const AMisura(this.millesimi, this.unita); final int millesimi; final UnitaMisura unita; }
```

```dart
// lib/domain/offerta.dart
sealed class Offerta {
  const Offerta();
  /// Il totale di [pezzi] pezzi a [prezzoUnitario] con questa offerta. Per le offerte che non
  /// dipendono dalla quantita' (PrezzoBarrato, PrezzoConCarta) e' prezzoUnitario × pezzi.
  Money totale(Money prezzoUnitario, int pezzi);
  /// Testo breve per la riga ("3x2", "−30%"): lo produce lib/app/labels.dart, NON il dominio.
  Map<String, Object?> toJson();                  // {"tipo": "...", ...}
  static Offerta? fromJson(Map<String, Object?>? json);   // tollerante: tipo sconosciuto → null
}
/// «Prendi N paghi M»: 3x2, 2x1, «2+1» (= 3x2), «1+1» (= 2x1), «3x1».
final class OffertaNxM extends Offerta { const OffertaNxM({required this.prendi, required this.paghi}); final int prendi; final int paghi; }
/// Sconto percentuale applicato al prezzo pieno (bollino «−30%» con il prezzo pieno stampato).
final class OffertaPercentuale extends Offerta { const OffertaPercentuale(this.percento); final int percento; }   // 1..99
/// Prezzo gia' scontato sul cartellino, con il pieno barrato o «anziche'»: informativa.
final class OffertaPrezzoBarrato extends Offerta { const OffertaPrezzoBarrato(this.prezzoPieno); final Money prezzoPieno; }
/// «−50% sul secondo pezzo»: ogni coppia, il secondo scontato.
final class OffertaSecondoAPercento extends Offerta { const OffertaSecondoAPercento(this.percento); final int percento; }
/// Prezzo riservato a chi ha la carta fedelta' (informativa: il prezzo unitario e' gia' quello scelto).
final class OffertaPrezzoConCarta extends Offerta { const OffertaPrezzoConCarta(this.prezzoSenzaCarta); final Money prezzoSenzaCarta; }
```

Regole di calcolo, **esattamente** queste:

| Offerta | `totale(p, q)` | Esempio |
|---|---|---|
| `OffertaNxM(prendi: N, paghi: M)` | `p × ((q ~/ N) × M + q % N)` | 3x2, p = 1,89, q = 4 → 1,89 × (1×2 + 1) = 5,67 |
| `OffertaPercentuale(x)` | `q × (p − Arrotonda.scontoPercentuale(p, x))` | p = 1,98, −40% → sconto 0,79 → 1,19 a pezzo |
| `OffertaPrezzoBarrato(pieno)` | `p × q` (p e' gia' il prezzo scontato) | 1,49 anziche' 2,99 |
| `OffertaSecondoAPercento(x)` | `p × q − (q ~/ 2) × Arrotonda.scontoPercentuale(p, x)` | p = 3,00, −50%, q = 3 → 9,00 − 1,50 = 7,50 |
| `OffertaPrezzoConCarta(senza)` | `p × q` | |
| nessuna | `p × q` (Pezzi) / `Arrotonda.perMisura(p, millesimi)` (AMisura) | |

⚑ **Il prezzo unitario di una riga con offerta NxM e' il prezzo PIENO**, anche se il cartellino
mostra in grande il prezzo «effettivo». Caso c11 (Carrefour «2+1»): grande 1,26, piccolo 1,89; 1,89 ×
2/3 = 1,26 → l'app salva p = 1,89 con `OffertaNxM(3, 2)` e mostra «1,26 cad. se ne prendi 3». Caso c01
(Tigros «3x1 anziche' 3,19»): 3,19 × 1/3 = 1,063 → 1,06 → p = 3,19, `OffertaNxM(3, 1)`. Cosi' il
totale e' quello della cassa (3 pezzi = 3,19, non 3 × 1,06 = 3,18) e una quantita' non multipla di N
si conta giusta. Le offerte NxM su `AMisura` **non** esistono (si ignorano: offerta null).
⚑ **Un bollino «−X%» con il solo prezzo pieno stampato** (c28, c30: lo sconto si applica alla cassa)
diventa `OffertaPercentuale(X)`; con **entrambi** i prezzi stampati (c29, c33) vince il prezzo
stampato (`OffertaPrezzoBarrato`) e la percentuale e' solo descrittiva: le percentuali dei cartellini
sono arrotondate (c33: 2,99 «−23%» stampa 2,29, mentre 2,99 × 0,77 = 2,30). `−0%` (c23) = nessuna
offerta.

```dart
// lib/domain/riga_spesa.dart
enum OrigineRiga { tastierino, cartellino, bilancia, scontrino }

@immutable
final class RigaSpesa {
  const RigaSpesa({this.id, required this.nome, required this.quantita, required this.prezzoUnitario,
      this.offerta, this.prezzoRiferimento, this.unitaRiferimento, this.totaleStampato,
      required this.origine});
  final int? id;
  final String nome;                 // 0..80 caratteri; '' = «Articolo» nell'interfaccia
  final Quantita quantita;
  /// Per Pezzi: il prezzo di un pezzo (PIENO se c'e' un'offerta NxM). Per AMisura: €/kg o €/l.
  /// Negativo solo per le righe di sconto/buono battute con «−» (quantita' Pezzi(1)).
  final Money prezzoUnitario;
  final Offerta? offerta;
  /// Il prezzo al kg/l stampato sul cartellino di un prodotto a pezzi (solo informativo).
  final Money? prezzoRiferimento;
  final UnitaMisura? unitaRiferimento;
  /// Bilancia: il totale stampato sull'etichetta. Se presente VINCE sul calcolo (e' cio' che si paga).
  final Money? totaleStampato;
  final OrigineRiga origine;

  /// totaleStampato ?? (offerta?.totale(...) ?? calcolo base di F12.1.3).
  Money get totale;
  bool get eSconto => prezzoUnitario.isNegative;
  RigaSpesa copyWith({...});
}
```

```dart
// lib/domain/spesa.dart
enum StatoSpesa { inCorso, chiusa }
enum FonteRighe { contate, scontrino }   // quale insieme di righe fa fede per totale e statistiche
enum LivelloBudget { nessuno, ok, vicino, sforato }   // vicino = da 80% a 100% incluso

@immutable
final class Spesa {
  const Spesa({this.id, required this.stato, this.negozioId, required this.iniziataIl, this.chiusaIl,
      this.dataSpesa, this.budget, required this.righe, this.righeScontrino = const [],
      this.totaleScontrino, this.fonte = FonteRighe.contate});
  final int? id; final StatoSpesa stato; final int? negozioId;
  final DateTime iniziataIl; final DateTime? chiusaIl; final CivilDate? dataSpesa;
  final Money? budget;                       // null = nessun budget
  final List<RigaSpesa> righe;               // le contate, in ordine di inserimento
  final List<RigaSpesa> righeScontrino;      // origine scontrino, solo Pro
  final Money? totaleScontrino;              // il TOTALE stampato, se letto
  final FonteRighe fonte;
  Money get totaleContato;                   // Money.sum(righe.map((r) => r.totale))
  Money get totale;                          // fonte == scontrino ? (totaleScontrino ?? somma righeScontrino) : totaleContato
  int get articoli;                          // somma dei Pezzi.n + 1 per ogni AMisura, righe di sconto escluse
  Money? get residuoBudget;                  // budget − totale (negativo = sforato)
  LivelloBudget get livelloBudget;
}
```

⚑ **Il budget e' una colonna della spesa, non una tabella**: ogni spesa ha il suo (la spesa
grande del sabato non e' quella del pane), e il «budget abituale» e' un'impostazione
(`SrSettingKeys.budgetPredefinito`) che precompila quello della spesa nuova. Un budget mensile non
e' stato chiesto: non esiste (se servira', D3).

```dart
// lib/domain/tastierino.dart
enum TastoTastierino { c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c00, virgola, per, meno, cancella, piu }

/// Cosa produce un tocco: niente, una riga nuova, o «+1 all'ultima riga».
sealed class EffettoTasto { const EffettoTasto(); }
final class NessunEffetto extends EffettoTasto { const NessunEffetto({this.rifiutato = false}); final bool rifiutato; } // rifiutato = vibrazione d'errore
final class AggiungiRiga extends EffettoTasto { const AggiungiRiga({required this.prezzo, required this.pezzi}); final Money prezzo; final int pezzi; }
final class IncrementaUltima extends EffettoTasto { const IncrementaUltima(); }

@immutable
final class TastierinoState {
  const TastierinoState.vuoto();
  /// Il testo grande da mostrare a destra di «Prezzo a mano»: "2,49", "3 × 2,49", "− 1,50", "".
  String get display;          // costruito SENZA intl: virgola decimale fissa (l'app e' in euro)
  bool get vuoto;
  (TastierinoState, EffettoTasto) premi(TastoTastierino tasto);
  TastierinoState svuota();    // pressione lunga su ⌫
}
```

Regole del tastierino (⚑ **modalita' «cassa» con virgola facoltativa**: chi batte `2 4 9` ottiene
2,49 come alla cassa; chi batte `2 , 4 9` come legge sul cartellino ottiene lo stesso 2,49; il
display grande mostra **sempre** il valore formattato, quindi un errore si vede prima del `+`):

| Situazione | Tasto | Risultato |
|---|---|---|
| cifre senza virgola | `c0`..`c9` | le cifre entrano da destra come centesimi: `2` → 0,02; `2 4` → 0,24; `2 4 9` → 2,49 |
| cifre senza virgola | `c00` | come due `c0`: `3 00` → 3,00 (il tasto «00» delle casse) |
| cifre senza virgola | `virgola` | le cifre gia' battute diventano **euro**: `2 ,` → «2,» ; poi al massimo **2** cifre di decimali (`2 , 5` → 2,50 al `+`) |
| dopo la virgola, gia' 2 decimali | cifra | rifiutata (`NessunEffetto(rifiutato: true)`) |
| prezzo > 9999,99 | cifra | rifiutata |
| numero battuto, niente × | `per` | il numero (come **intero**, 1..99) diventa la quantita': display «3 ×»; poi si batte il prezzo |
| prezzo battuto | `per` | il prezzo resta, display «2,49 ×»; il numero battuto dopo e' la quantita' (`2 4 9 × 3 +` = 3 × 2,49) |
| quantita' 0 o > 99 | `piu` | rifiutato |
| display vuoto | `meno` | segno negativo: «−»; la riga sara' uno **sconto/buono** (prezzo negativo, `Pezzi(1)`, nome «Sconto») |
| display non vuoto | `meno` | inverte il segno |
| qualunque | `cancella` | toglie l'ultimo carattere logico (cifra, virgola, «×», «−»); pressione lunga = `svuota()` |
| valore valido ≠ 0 | `piu` | `AggiungiRiga(prezzo, pezzi)` e stato vuoto |
| display vuoto | `piu` | `IncrementaUltima` (+1 pezzo all'ultima riga a pezzi; se l'ultima e' a misura o sconto → rifiutato) |
| valore 0,00 | `piu` | rifiutato |

⚑ «Togliere l'ultimo» (dalla scheda delle idee) **non** e' un tasto: l'ultima riga della lista ha lo
scorrimento per eliminarla, con «Annulla» nello snack (F12.1.12). Un tasto del tastierino che
cancella righe sarebbe a un pollice da ⌫, e un errore costerebbe un articolo.

```dart
// lib/domain/nomi.dart
abstract final class Nomi {
  /// Maiuscolo, senza accenti, punteggiatura → spazio, spazi singoli, formati («200 G», «GR.600»,
  /// «LT 1», «X2») tolti. "Crema NUTKAO bicch.birra gr.600" → "CREMA NUTKAO BICCH BIRRA".
  static String normalizza(String nome);
  /// Similarita' 0..1 fra un nome di cartellino e una descrizione di scontrino (troncata, abbreviata):
  /// massimo fra Jaccard sulle parole e "prefissi": una parola dello scontrino di ≥ 3 lettere vale
  /// come uguale se e' prefisso di una parola del cartellino ("PR COTTO" ~ "PROSCIUTTO COTTO").
  static double similarita(String a, String b);
  /// Il formato della confezione, se c'e' nel nome: "200 g" → AMisura(200, kg); "LT 1" → AMisura(1000, l);
  /// "6x180 ml" → AMisura(1080, l); "50 cl" → AMisura(500, l). Serve al controllo prezzo/formato ≈ €/kg.
  static AMisura? formato(String nome);
}
```

#### F12.1.4 — OCR nel dominio e parser del cartellino (`lib/domain/lettura/`)

Il dominio lavora **solo** su `RigaOcr` (da `package:micro_ocr/riga_ocr.dart`, libreria pura),
qualunque sia il motore: **un solo parser per Vision e per PP-OCR** (f12-ocr.md §4).

```dart
// packages/micro_ocr/lib/src/riga_ocr.dart
/// Un rettangolo in coordinate NORMALIZZATE 0..1 rispetto all'immagine passata al motore,
/// origine in ALTO a sinistra, asse y verso il basso.
@immutable
final class Riquadro {
  const Riquadro({required this.sinistra, required this.alto, required this.larghezza, required this.altezza});
  /// Da Vision: boundingBox normalizzato con origine in BASSO a sinistra. alto = 1 − (y + h).
  factory Riquadro.daVision(double x, double y, double w, double h);
  final double sinistra, alto, larghezza, altezza;
  double get destra; double get basso; double get centroX; double get centroY;
  /// Sovrapposizione verticale 0..1, misurata sul piu' basso dei due: serve a dire «stessa riga».
  double sovrapposizioneVerticale(Riquadro altro);
  Map<String, double> toJson();                       // {"x":..,"y":..,"w":..,"h":..}
  factory Riquadro.fromJson(Map<String, Object?> json);
}

@immutable
final class RigaOcr {
  const RigaOcr({required this.testo, required this.riquadro, required this.confidenza});
  final String testo; final Riquadro riquadro; final double confidenza;   // 0..1
  Map<String, Object?> toJson();                      // {"t":..,"x":..,"y":..,"w":..,"h":..,"c":..}
  factory RigaOcr.fromJson(Map<String, Object?> json);
}

enum OcrModo { cartellino, scontrino }
```

⚑ **La conversione di Vision si fa in Dart** (`Riquadro.daVision`), non in Swift: cosi' e' testata
(`riga_ocr_test.dart`) e la trappola dell'asse y capovolto non vive in un file che nessun test tocca.

```dart
// lib/domain/lettura/numeri_ocr.dart
/// Un numero «da prezzo» trovato nel testo OCR, con il riquadro da cui viene.
@immutable final class NumeroOcr {
  const NumeroOcr({required this.valore, required this.riquadro, required this.forma, required this.testo});
  final Money valore; final Riquadro riquadro; final FormaNumero forma; final String testo;
}
enum FormaNumero { esplicito, spezzato, fuso, peso }   // peso = 3 decimali (0,258)

abstract final class NumeriOcr {
  /// Correzioni di lettura DENTRO i gruppi di cifre: O/o→0, I/l/|→1, S→5 (solo se adiacente a cifre),
  /// "16..50"→"16,50", spazio fra cifre e separatore tolto ("2 ,49"→"2,49"), "€" e "EUR" tolti.
  static String pulisci(String testo);
  /// I numeri espliciti di una riga: \d{1,4}(\.\d{3})*[,.]\d{2}, piu' "0,258"-like (peso, 3 decimali).
  /// "1.100,00" → 1100,00 (separatore delle migliaia, c26). Prezzo negativo: "-0,40" e "0,40-".
  static List<NumeroOcr> espliciti(RigaOcr riga);
  /// Euro grandi + centesimi piccoli in apice in DUE riquadri (c01: "1" | "06" → 1,06). Regola:
  /// A ha solo 1..4 cifre; B ha esattamente 2 cifre; B.altezza fra 0,25 e 0,75 × A.altezza;
  /// B.sinistra fra A.destra − 0,2·A.altezza e A.destra + 0,6·A.altezza; B.alto ≤ A.alto + 0,35·A.altezza.
  static List<NumeroOcr> spezzati(List<RigaOcr> righe);
  /// Cifre senza separatore in un riquadro alto (c33: "229" → 2,29): 3..5 cifre, nessun altro carattere,
  /// altezza ≥ 1,5 × mediana delle altezze delle altre righe con lettere. Le ultime 2 cifre sono i centesimi.
  static List<NumeroOcr> fusi(List<RigaOcr> righe);
}
```

```dart
// lib/domain/lettura/cartellino_parser.dart
@immutable final class PrezzoUnitario { const PrezzoUnitario(this.valore, this.unita); final Money valore; final UnitaMisura unita; }

@immutable final class PropostaCartellino {
  const PropostaCartellino({required this.nome, this.prezzo, this.prezzoPieno, this.unitario,
      this.offerta, this.formato, required this.affidabilita, this.alternative = const []});
  final String nome;                 // '' se non trovato
  final Money? prezzo;               // il prezzo UNITARIO da usare nella riga (PIENO con NxM, F12.1.3)
  final Money? prezzoPieno;          // barrato / «anziche'»
  final PrezzoUnitario? unitario;    // €/kg o €/l stampato
  final Offerta? offerta;
  final AMisura? formato;            // dal nome ("200 g")
  final double affidabilita;         // 0..1, vedi «Punteggio»
  final List<Money> alternative;     // gli altri prezzi letti, come chip «Era invece…»
  /// Prodotto venduto a peso/volume: c'e' solo il prezzo al kg/l (c02 zucchine, c03 borlotti, c24).
  bool get aMisura => prezzo == null && unitario != null;
}

@immutable final class LetturaCartellino {
  const LetturaCartellino(this.proposte);
  final List<PropostaCartellino> proposte;    // ordinate per affidabilita'; vuota = niente di utile
  bool get vuota => proposte.isEmpty;
}

class CartellinoParser {
  const CartellinoParser();
  LetturaCartellino interpreta(List<RigaOcr> righe);
}
// ⚑ SUPERATO da D4 (2026-10-10, «chiedi ogni volta»): niente `preferisciPrezzoCarta`. Con due prezzi
// la proposta porta `DoppioPrezzoCarta? carta` (conCarta, senzaCarta) e il foglio di conferma chiede
// con DUE bottoni; `PropostaCartellino.scegliCarta({required bool conCarta})` applica la scelta.
```

**Algoritmo di `CartellinoParser.interpreta`, nell'ordine:**

1. **Pulizia**: `NumeriOcr.pulisci` su ogni riga; scartate le righe con confidenza < 0,30 e quelle
   con riquadro di area < 0,0004 (rumore).
2. **Candidati prezzo**: `espliciti` ∪ `spezzati` ∪ `fusi` (un riquadro gia' usato da uno spezzato
   non genera anche un fuso). Ogni candidato ha la sua **altezza** (quella del riquadro delle cifre
   grandi).
3. **Contesto di ogni candidato**: le parole nella stessa riga visiva (`RigheVisive`, F12.1.6) e
   nelle righe entro 1,5 altezze sopra/sotto, cercate in minuscolo e senza accenti (nelle tabelle di
   questa sezione `\|` e' il `|` della regex, scappato per Markdown):

   | Parole (regex, minuscolo, senza accenti) | Il candidato e'… |
   |---|---|
   | `€\s*/\s*kg`, `/\s*kg`, `al\s*kg`, `euro\s*al\s*kg`, `prezzo\s*(al\|per)\s*kg`, `eur/kg` | prezzo unitario, `UnitaMisura.kg` |
   | `€\s*/\s*l(t\|itro)?\b`, `al\s*l(t\|itro)\b`, `/\s*lt?\b`, `prezzo\s*al\s*litro` | prezzo unitario, `UnitaMisura.l` |
   | `anziche`, `invece\s*di`, `prima\b`, `prezzo\s*pieno`, `era\b` | prezzo pieno |
   | `con\s*(la\s*)?carta`, `carta\s*fedelta`, `soci\b`, `prezzo\s*carta` | prezzo con carta |

4. **Offerte nel testo** (tutta l'immagine):

   | Regex | Offerta |
   |---|---|
   | `\b([2-5])\s*[x×]\s*([1-4])\b` con N > M | `OffertaNxM(N, M)` |
   | `prendi\s*([2-5])\s*paghi\s*([1-4])` | `OffertaNxM(N, M)` |
   | `\b([1-4])\s*\+\s*1\b` («2+1», «1+1») | `OffertaNxM(N + 1, N)` |
   | `-?\s*([1-9]\d?)\s*%` vicino a `sul\s*(2\|secondo)`, `2°\s*pezzo` | `OffertaSecondoAPercento(x)` |
   | `-\s*([1-9]\d?)\s*%` oppure `sconto\s*([1-9]\d?)\s*%` | percentuale x (vedi passo 6) |
   | `\b0\s*%` | nessuna (c23) |

5. **Scelta del prezzo da pagare** fra i candidati che **non** sono unitari ne' pieni:
   - si prende il candidato **piu' alto** (altezza del riquadro); a parita' (±10%), quello col
     **controllo formato** riuscito: se c'e' un `formato` nel nome e un prezzo unitario U, il
     candidato P per cui `|P × 1000 / formato.millesimi − U| ≤ max(2 cent, 0,5% di U)` vince (c14:
     1,99 / 0,200 kg = 9,95 = U; c16: 3,59 / 0,600 = 5,98 vs 5,99 stampato, dentro la tolleranza);
   - prezzo **con carta** e prezzo normale presenti → **entrambi** nella proposta, marcati
     (`DoppioPrezzoCarta`, D4): il parser non sceglie; sceglie l'utente nel foglio (con carta →
     prezzo con carta e `OffertaPrezzoConCarta(senza)`; senza carta → prezzo normale, nessuna offerta);
   - se **non** resta nessun candidato ma c'e' un unitario → proposta `aMisura` (si apre il foglio
     del peso, F12.1.12).
6. **Offerta e prezzo pieno**:
   - NxM trovata e due prezzi P (grande) e Q (piccolo, > P) con `|P − round(Q × M / N)| ≤ 1 cent`
     → `prezzo = Q` (pieno), `offerta = OffertaNxM(N, M)` (c01, c11). Senza Q, `prezzo = P`
     con l'offerta NxM e affidabilita' ridotta di 0,2 (il «grande» potrebbe essere l'effettivo);
   - pieno trovato (parole del passo 3, oppure un secondo prezzo **maggiore** di P e alto meno di
     0,8 × P) → `OffertaPrezzoBarrato(pieno)`; con percentuale anche presente, la percentuale si
     ignora (F12.1.3);
   - solo percentuale e un solo prezzo → `OffertaPercentuale(x)` sul prezzo letto (c28, c30).
7. **Nome**: le righe con almeno 3 lettere, che non sono parole chiave ne' numeri ne' codici
   (`^\d{8,13}$` EAN, `cod\.`, date `\d{2}[/.-]\d{2}`), **sopra** il prezzo scelto o alla sua sinistra,
   dall'alto in basso; si uniscono **al massimo 2**, con uno spazio; si tronca a 60 caratteri.
   Maiuscole conservate come sul cartellino (l'interfaccia lo mostra cosi', lo scontrino e' in
   maiuscolo e il confronto normalizza).
8. **Piu' cartellini nella stessa foto** (c18, c22, c26, c27, c33): se ci sono ≥ 2 candidati «prezzo
   da pagare» con altezza entro il 25% l'uno dell'altro e centri distanti > 0,3 della larghezza o
   > 0,3 dell'altezza, ogni riga si assegna al prezzo **piu' vicino** (distanza fra centri, con il
   verticale pesato 1,5) e si ripetono i passi 3–7 per gruppo. Risultato: piu' proposte, ordinate per
   **vicinanza al centro del mirino** (l'utente ha puntato quello). L'interfaccia chiede «Ho visto 2
   cartellini: quale?».
9. **Punteggio** `affidabilita'` (0..1): parte da 0,5; +0,2 forma `esplicito`, +0,1 `spezzato`,
   −0,1 `fuso`; +0,2 controllo formato riuscito; +0,1 nome trovato; −0,2 ambiguita' (altri candidati
   entro il 10% di altezza); media con la confidenza OCR delle righe usate; tagliato a [0, 1].
   ⚑ **Il punteggio non decide se aggiungere** (non si aggiunge mai da solo, F12.0 punto 4): decide
   solo se il foglio di conferma mette in evidenza le `alternative` (sotto 0,6) e il testo «Controlla
   il prezzo».
10. **Lettura vuota**: nessun candidato → `LetturaCartellino(const [])`; l'interfaccia dice «Non
    riesco a leggere il prezzo» con «Batti a mano» (e, se le righe lette hanno poche lettere e
    nessuna cifra, «Lo scritto a mano non lo leggo ancora»).

**Casi di test che DEVONO passare** (in `test/domain/cartellino_parser_test.dart`, con `RigaOcr`
**scritte a mano** che riproducono la disposizione del campione citato; prodotti e nomi **inventati**,
non copiati dai campioni):

| Caso (ispirato a) | Righe OCR finte | Atteso |
|---|---|---|
| `c01_tigros_3x1_anziche` | «PROSCIUTTO…», «1» grande + «06» piccolo in apice, «3x1», «anziche' 3,19», «10,60 €/kg» | prezzo 3,19, `OffertaNxM(3,1)`, unitario 10,60/kg, alternative [1,06] |
| `c11_carrefour_fr_2piu1` | «1,26» grande, «1,89» piccolo, «2+1», «5,04 €/kg» | prezzo 1,89, `OffertaNxM(3,2)` |
| `c14_esselunga_borotalco` | «SAPONE … 200 g», «1,99», «9,95 €/kg» piccolo | prezzo 1,99, formato 200 g, controllo riuscito |
| `c16_esselunga_nutkao` | «… GR.600», «3,59», «5,99 €/kg» | prezzo 3,59 (tolleranza del controllo) |
| `c19_esselunga_distillato_litro` | «… 50 cl», «21,90», «43,80 €/l» | prezzo 21,90, unitario litro |
| `c20_esselunga_tonica_litro` | «… 6x180 ml», «1,98», «1,84 €/lt» | formato 1080 ml, 1,98 / 1,08 = 1,833 vs 1,84: dentro la tolleranza |
| `c22_esselunga_farine_due_cartellini` | due prezzi grandi lontani | 2 proposte, la piu' vicina al centro prima |
| `c26_peck_carciofini_kg` | «132,00», «1.100,00 €/kg» | unitario 1100,00 (migliaia) |
| `c28_esselunga_misticanza_sconto40` | «1,98», bollino «-40%» | `OffertaPercentuale(40)`, totale di 1 pezzo 1,19 |
| `c29_last_minute_barrato_50` | «1,49» grande, «2,99» piccolo, «-50%» | prezzo 1,49, `OffertaPrezzoBarrato(2,99)` |
| `c30_pam_rucola_sconto30` | «0,99», «-30%» | totale 1 pezzo 0,69 (sconto 0,297 → 0,30) |
| `c33_iper_esl_prezzo_dinamico` | «229» fuso grande, «2,99» piccolo, «-23%» | prezzo 2,29 (fuso), barrato 2,99 |
| `c02_palermo_offerta_ortofrutta` / `c03_borlotti_manoscritto_kg` | «ZUCCHINE», «1,48 €/kg» | `aMisura`, unitario 1,48/kg |
| `c23_cartello_barrato_sconto_0` | «2,50», «0%» | prezzo 2,50, nessuna offerta |
| `c04_friggitelli_manoscritto_kg` | sole lettere, nessuna cifra | lettura vuota |
| (prezzo con carta) | «2,49», «con carta 1,99» | `carta: DoppioPrezzoCarta(conCarta: 1,99, senzaCarta: 2,49)`; `scegliCarta(conCarta: true)` → 1,99 + `OffertaPrezzoConCarta(2,49)`, `false` → 2,49 (D4) |

#### F12.1.5 — Parser dell'etichetta della bilancia (`lib/domain/lettura/bilancia_parser.dart`)

```dart
@immutable final class LetturaBilancia {
  const LetturaBilancia({this.prodotto, this.pesoNetto, this.alKg, this.totale, this.tara, required this.coerente});
  final String? prodotto;
  final AMisura? pesoNetto;          // grammi (UnitaMisura.kg)
  final Money? alKg;
  final Money? totale;               // cio' che si paga: VINCE nel conto
  final AMisura? tara;
  /// Arrotonda.perMisura(alKg, peso) == totale entro 1 centesimo.
  final bool coerente;
  bool get utile => totale != null;  // senza totale non e' un'etichetta utilizzabile
}

class BilanciaParser {
  const BilanciaParser();
  LetturaBilancia? interpreta(List<RigaOcr> righe);   // null = non sembra un'etichetta di bilancia
  /// Vero se le righe hanno la «firma» della bilancia: un peso con 3 decimali e una tripla
  /// peso × €/kg ≈ totale. Lo usa la pagina della fotocamera per passare da sola a «Bilancia».
  bool riconosce(List<RigaOcr> righe);
}
```

**Algoritmo:**
1. Candidati: pesi = numeri con **3 decimali** (`0,258`) oppure `\d+\s*g\b` (→ grammi); importi =
   numeri espliciti con 2 decimali (`NumeriOcr.espliciti`).
2. Etichette vicine (stessa riga visiva o riga sopra): `netto|peso\s*netto|p\.?\s*netto|kg\s*netto`
   → peso netto; `tara` → tara (esclusa dal conto); `€\s*/\s*kg|eur/kg|prezzo\s*/?\s*kg|prezzo\s*al\s*kg`
   → al kg; `importo|prezzo\s*€?$|totale|da\s*pagare|euro\b` → totale.
3. Se manca qualche etichetta: **ricerca combinatoria** su (peso, alKg, totale) fra i candidati
   rimasti, con `|Arrotonda.perMisura(alKg, peso) − totale| ≤ 1 cent`; se c'e' **una sola** tripla
   coerente, si prende; se piu' d'una, vince quella con il totale nel riquadro piu' alto.
4. `coerente = false` se i tre valori ci sono ma la verifica fallisce (> 1 cent): si usa comunque il
   **totale stampato** (e' quello della cassa) e il foglio mostra «Il conto peso × prezzo non torna:
   controlla» in ambra.
5. Prodotto: la riga di lettere piu' in alto che non e' un'etichetta (`peso`, `tara`, `prezzo`,
   `confezionato`, `da consumarsi`, `lotto`, date).
6. ⚑ Il codice a barre «a peso variabile» (EAN che inizia per 2, con il prezzo dentro) potrebbe dare un
   quarto controllo: **non in v1** (vedi §9, voce nuova DT-SR1).

**Casi di test** (`test/domain/bilancia_parser_test.dart`; numeri dai campioni, sono fatti, non
immagini): tutte e 9 le verita' di `campioni.csv` devono essere **coerenti** con `Arrotonda`
(b01 0,258 × 29,90 = 7,71; b02 0,326 × 5,90 = 1,92; b03 0,160 × 7,39 = 1,18; b04 0,099 × 280,00 =
27,72; b05 0,494 × 44,99 = 22,23; b06 0,500 × 5,86 = 2,93; b07 1,082 × 1,59 = 1,72; b08 0,225 × 12,00
= 2,70; b09 0,314 × 8,90 = 2,79), piu': tara presente e ignorata (come b01, b02, b04); etichette senza
parole chiave risolte dalla ricerca combinatoria; due etichette sovrapposte (come b06) → si propone
quella con la tripla coerente; peso in grammi «258 g»; totale incoerente → `coerente: false` e
totale stampato.

#### F12.1.6 — Parser dello scontrino (`lib/domain/lettura/scontrino_parser.dart`)

**Com'e' fatto uno scontrino italiano.** Dal 2020 il registratore telematico (RT) stampa il
**«DOCUMENTO COMMERCIALE di vendita o prestazione»** (campioni s01, s13, s14, s16); restano in giro
formati vecchi («SCONTRINO FISCALE», «TOTALE EURO»). Struttura tipica, dall'alto (esempio
**inventato**):

```
SUPERMERCATO ESEMPIO S.R.L.            ← testata: ragione sociale (= negozio)
VIA ROMA 1 - 00100 ROMA                ← indirizzo (scartare)
P.IVA 01234567890                      ← scartare
DOCUMENTO COMMERCIALE                  ← fine testata
di vendita o prestazione
DESCRIZIONE              IVA  Prezzo(€)
PASTA SEMOLA 500G        10%      0,89 ← riga articolo: descrizione + (IVA) + importo a destra
2 x 1,29                               ← quantita' (prima O dopo la descrizione, dipende dalla cassa)
BISCOTTI FROLLINI        10%      2,58
0,248 kg x 12,50 €/kg                  ← riga pesata
PROSCIUTTO COTTO         10%      3,10
SCONTO                           -0,40 ← sconto (anche "0,40-" o "OFFERTA -0,40")
STORNO PASTA SEMOLA 500G         -0,89 ← storno di una riga gia' battuta
SUBTOTALE                         5,28
TOTALE COMPLESSIVO                5,28 ← il TOTALE
di cui IVA                        0,48 ← scartare
Pagamento elettronico             5,28 ← sezione pagamento: scartare TUTTA (dati della carta)
Importo pagato                    5,28
10-10-2026 18:32  DOC.N. 0123-0045     ← data e ora
RT 99MEY012345                         ← matricola (scartare)
```

```dart
enum TipoRigaScontrino { articolo, sconto, storno }

@immutable final class RigaScontrino {
  const RigaScontrino({required this.descrizione, required this.importo, required this.tipo,
      this.quantita, this.prezzoUnitario, this.stornata = false});
  final String descrizione;
  final Money importo;               // con segno: sconti e storni negativi
  final TipoRigaScontrino tipo;
  final Quantita? quantita;          // da "2 x 1,29" (Pezzi) o "0,248 kg x 12,50" (AMisura)
  final Money? prezzoUnitario;
  final bool stornata;               // un articolo annullato da uno storno successivo
}

@immutable final class LetturaScontrino {
  const LetturaScontrino({this.negozio, this.data, required this.righe, this.totale, required this.righeIgnorate});
  final String? negozio;
  final CivilDate? data;
  final List<RigaScontrino> righe;   // nell'ordine dello scontrino
  final Money? totale;               // il TOTALE stampato
  final int righeIgnorate;           // righe del corpo non capite (per il messaggio «N righe non lette»)
  Money get sommaRighe;              // somma degli importi (stornate comprese: lo storno le compensa)
  bool get quadra;                   // totale != null && totale == sommaRighe
  int get articoli;                  // righe articolo non stornate (confrontabile con "righe" della verita')
}

class ScontrinoParser {
  const ScontrinoParser();
  LetturaScontrino interpreta(List<RigaOcr> righe, {DateTime? oggi});
}
```

```dart
// lib/domain/lettura/righe_visive.dart
@immutable final class RigaVisiva {
  const RigaVisiva(this.pezzi);
  final List<RigaOcr> pezzi;                 // da sinistra a destra
  String get testo;                          // pezzi uniti con uno spazio
  Riquadro get riquadro;                     // l'unione
  /// L'ultimo numero esplicito il cui riquadro finisce oltre il 60% della larghezza: la colonna prezzi.
  NumeroOcr? get importoADestra;
}
abstract final class RigheVisive {
  /// Ordina per centro verticale; due riquadri stanno nella stessa riga se la loro
  /// sovrapposizioneVerticale ≥ 0,5. ⚑ Serve perche' PP-OCR spezza una riga in piu' riquadri
  /// (descrizione | IVA | prezzo) mentre Vision spesso la da' intera: dopo questo passo i due
  /// motori producono le stesse righe.
  static List<RigaVisiva> raggruppa(List<RigaOcr> righe);
}
```

**Algoritmo di `ScontrinoParser.interpreta`:**
1. `RigheVisive.raggruppa`, poi `NumeriOcr.pulisci` sul testo di ogni riga.
2. **Zone**: *testata* fino alla prima riga che contiene `documento\s*commerciale|descrizione|scontrino\s*fiscale`
   (esclusa) oppure, se non c'e', fino alla prima riga con `importoADestra`; *corpo* fino alla riga
   del totale (inclusa); *piede* il resto.
3. **Negozio**: nella testata, la prima riga con ≥ 4 lettere che **non** contiene `via|viale|piazza|p\.?zza|corso|c\.so|tel|p\.?\s*iva|c\.?f\.|cap\b|\d{5}`
   ne' `documento|commerciale|benvenut|grazie`; si tolgono `s\.?r\.?l\.?|s\.?p\.?a\.?|s\.?a\.?s\.?|snc`
   in fondo solo per il nome **mostrato** (il nome intero resta nel suggerimento del negozio).
4. **Corpo**, riga per riga (le regex sul testo pulito, minuscolo):

   | Riga | Riconoscimento | Effetto |
   |---|---|---|
   | quantita' | `^\s*(\d{1,3})\s*[x×*]\s*(\d+[.,]\d{2})\s*$` | `Pezzi(n)`, prezzo unitario: si attacca all'articolo **adiacente** (precedente o successivo) il cui importo e' `n × prezzo` ±1 cent; se nessuno quadra, alla riga **successiva** |
   | pesata | `(\d+[.,]\d{3})\s*kg\s*[x×*]\s*(\d+[.,]\d{2})` | `AMisura(grammi, kg)` + €/kg, attaccata come sopra con `Arrotonda.perMisura` (s03) |
   | sconto | importo negativo (`-0,40` o `0,40-`) **oppure** `sconto|offerta|promo|buono|coupon|risparmio` con importo | `TipoRigaScontrino.sconto`, importo **negativo** (s06 «OFFERTA -0,40») |
   | storno | `storno|annull|reso|correzione` con importo | `storno`, importo negativo; marca `stornata` l'ultimo articolo **precedente** con lo stesso importo in valore assoluto e descrizione simile (`Nomi.similarita` ≥ 0,5, o uguale se la riga di storno non ha descrizione) (s16) |
   | articolo | `importoADestra` e almeno 2 lettere a sinistra | `articolo`: descrizione = testo a sinistra dell'importo, tolti i token IVA in coda (`\b\d{1,2}\s*%`, `\b(a\|b\|c\|d\|vi)\b`, `\*`) |
   | quantita' in testa alla descrizione | `^(\d{1,2})\s+[a-z]` (s11 «3 COPERTO/ANTIPASTO 3,90») | `Pezzi(n)` e prezzo unitario = importo / n solo se divisibile, altrimenti nessuna quantita' |
   | totale | `^totale(\s*complessivo\|\s*euro\|\s*eur\|\s*€)?\b` **non** preceduta da `sub` e **non** seguita da `iva` | `totale` = suo importo; se ce ne sono piu', vince `complessivo`, poi l'ultimo |
   | subtotale, «di cui IVA», «totale IVA», «n. articoli», intestazioni di colonna | | ignorate (non contano in `righeIgnorate`) |
   | altro | | `righeIgnorate++` |

5. **Piede**: tutto cio' che segue il totale e' **scartato** tranne la data: ☠ la sezione pagamento
   contiene ultime cifre della carta, codici di autorizzazione, terminale (s13). **Non** entra in
   nessuna struttura, ne' in memoria oltre la durata del parse, ne' nel database.
6. **Data**: la prima `\b(\d{2})[-/.](\d{2})[-/.](\d{2}|\d{4})\b` del piede (poi della testata),
   anno a 2 cifre = 20xx; valida solo se non e' nel futuro di oltre 1 giorno rispetto a `oggi` e non
   e' piu' vecchia di 366 giorni; altrimenti `null`.
7. Vecchio formato senza «documento commerciale»: stesse regole (la testata finisce al primo importo).

**Fusione di piu' foto dello stesso scontrino** (`lib/domain/lettura/unisci_parti.dart`):

```dart
abstract final class UnisciParti {
  /// Ogni parte e' l'OCR di una foto, dall'alto in basso. Si concatenano le righe visive; se le ultime
  /// k righe della parte i coincidono con le prime k della parte i+1 (k ≥ 2, stesso importo e testo con
  /// similarita' ≥ 0,8), si tolgono i doppioni. Ritorna anche se la giunzione e' stata trovata.
  static ({List<RigaOcr> righe, List<bool> giunzioniTrovate}) unisci(List<List<RigaOcr>> parti);
}
```
⚑ Le coordinate di ogni parte si **impilano**: alla parte i+1 si somma `i + 1` all'asse y (ogni parte
occupa l'intervallo [i, i+1]), cosi' `RigheVisive` funziona sul tutto senza sapere delle foto.
☠ Una giunzione non trovata vuol dire «forse ci sono righe doppie o mancanti»: il confronto lo dice
(«Ho unito 2 foto senza trovare il punto di unione: controlla le righe vicino alla piega»).

**Casi di test** (`test/domain/scontrino_parser_test.dart`, righe finte nello stile del campione
citato; i numeri della verita' sono fatti e si possono usare):

| Caso (ispirato a) | Atteso |
|---|---|
| `s01_documento_commerciale_iva_kg` | totale 11,85, 7 articoli, colonna IVA tolta dalle descrizioni, riga pesata attaccata |
| `s03_pizzamania_pesate` | 4 righe pesate: 0,248 × 12,50 = 3,10; 0,186 × 14,00 = 2,60; 0,126 × 7,50 = 0,95; 0,098 × 7,50 = 0,74; totale 7,39 quadra |
| `s06_emmepiu_offerta` | riga «OFFERTA -0,40» = sconto; totale 6,15 = somma |
| `s07_interspar_catanzaro` | quattro righe uguali «ACQUA …» con la quantita' su riga separata |
| `s10_dm_reparti` | descrizioni «REPARTO 1»: righe valide anche senza nome di prodotto |
| `s11_trattoria_righe_qta` | quantita' in testa alla descrizione |
| `s16_deco_storno_2025` | storno: l'articolo stornato marcato, 2 articoli veri, totale 4,78 |
| (pagamento) | righe «PAGAMENTO ELETTRONICO», «************1234», «AUT. 123456» dopo il totale → assenti dal risultato |
| (data) | «10-10-26 18:32» → 2026-10-10; una data nel 2031 → null |
| (non quadra) | una riga persa → `quadra == false`, `righeIgnorate` > 0 |
| (due parti) | parti con 3 righe sovrapposte → nessun doppione, giunzione trovata |

#### F12.1.7 — Confronto contato vs scontrino (`lib/domain/confronto.dart`)

```dart
sealed class RigaSospetta { const RigaSospetta(); Money get delta; }   // delta = quanto in PIU' paghi rispetto al contato
/// Stesso articolo, prezzo diverso (cartellino 7,90 · scontrino 9,40).
final class PrezzoDiverso extends RigaSospetta { const PrezzoDiverso(this.contata, this.scontrino); final RigaSpesa contata; final RigaScontrino scontrino; }
/// Sullo scontrino ma non contato (il sacchetto).
final class SoloSulloScontrino extends RigaSospetta { const SoloSulloScontrino(this.scontrino); final RigaScontrino scontrino; }
/// Contato ma non sullo scontrino (un articolo dimenticato dal cassiere, o lasciato).
final class NonSulloScontrino extends RigaSospetta { const NonSulloScontrino(this.contata); final RigaSpesa contata; }
/// Due righe uguali sullo scontrino e una sola contata: «battuto due volte?».
final class ForseDoppia extends RigaSospetta { const ForseDoppia(this.contata, this.scontrino); final RigaSpesa contata; final RigaScontrino scontrino; }

@immutable final class Abbinamento { const Abbinamento(this.contata, this.scontrino); final RigaSpesa contata; final RigaScontrino scontrino; }

@immutable final class EsitoConfronto {
  const EsitoConfronto({required this.totaleScontrino, required this.totaleContato,
      required this.abbinate, required this.sospette});
  final Money totaleScontrino;       // il TOTALE stampato, o la somma delle righe se manca
  final Money totaleContato;
  Money get differenza;              // totaleScontrino − totaleContato (positivo = paghi di piu')
  bool get tuttoTorna;               // differenza == 0 && sospette.isEmpty
  final List<Abbinamento> abbinate;
  final List<RigaSospetta> sospette; // ordinate per |delta| decrescente
}

abstract final class Confronto {
  static EsitoConfronto confronta(List<RigaSpesa> contate, LetturaScontrino scontrino);
}
```

**Algoritmo** (deterministico; si confrontano **totali di riga**, cosi' «3 × 0,35» contato a mano
e «ACQUA 1,05» sullo scontrino si abbinano):
1. Dallo scontrino: righe articolo **non stornate**; ogni riga di sconto si **somma** all'articolo
   che la precede (e' lo sconto di quell'articolo, s06); gli storni si ignorano (gia' compensati).
   Dal contato: le righe con il loro `totale`; le righe di sconto battute a mano con «−» si confrontano
   con gli sconti dello scontrino non attribuiti.
2. **Passata 1** — stesso importo **e** `Nomi.similarita` ≥ 0,5: abbinate, in ordine di similarita'
   decrescente.
3. **Passata 2** — stesso importo, nome qualsiasi: abbinate in ordine di apparizione (la cassa batte
   piu' o meno nell'ordine del nastro). ⚑ Le descrizioni dello scontrino sono troncate a ~18-20
   caratteri e abbreviate («PR COTTO AQ.AR.SA FF»): l'importo e' l'indizio piu' affidabile.
4. **Passata 3** — similarita' ≥ 0,6 e importo diverso: `PrezzoDiverso`.
5. Scontrino rimasto con stessa descrizione e importo di una riga gia' abbinata: `ForseDoppia`;
   altrimenti `SoloSulloScontrino`. Contato rimasto: `NonSulloScontrino`.
6. `tuttoTorna` → schermata verde «Tutto torna»; altrimenti la card ambra «Differenza da guardare».

**Casi di test** (`test/domain/confronto_test.dart`): l'esempio della tavola «C · Una mano»
(contato 43,70, scontrino 45,35; Parmigiano 7,90 vs 9,40 → `PrezzoDiverso` +1,50; «Sacchetto» 0,15 →
`SoloSulloScontrino`; differenza +1,65); quantita' contata vs riga unica; sconto dello scontrino
attribuito all'articolo; articolo battuto due volte; contato vuoto (registrazione pura) → tutte
`SoloSulloScontrino` e differenza = totale; stornata non conta.

#### F12.1.8 — Statistiche (`lib/domain/statistiche.dart`, Pro)

```dart
@immutable final class VoceNegozio { const VoceNegozio({required this.negozioId, required this.nome, required this.spese, required this.totale}); final int? negozioId; final String nome; final int spese; final Money totale; Money get media; }
@immutable final class MeseSpesa { const MeseSpesa({required this.anno, required this.mese, required this.spese, required this.totale, required this.sforamenti, required this.conBudget}); final int anno, mese, spese, sforamenti, conBudget; final Money totale; Money? get media; }

abstract final class StatisticheSpesa {
  /// Solo spese CHIUSE con dataSpesa nel mese; il totale di ogni spesa e' Spesa.totale (segue la fonte).
  static MeseSpesa mese(List<Spesa> chiuse, int anno, int mese);
  /// Gli ultimi [n] mesi fino a quello di [oggi] compreso, anche vuoti (spese 0, media null).
  static List<MeseSpesa> ultimiMesi(List<Spesa> chiuse, CivilDate oggi, {int n = 6});
  /// Per negozio nel periodo [da, a] inclusi, ordinato per totale decrescente; «Senza negozio» in fondo.
  static List<VoceNegozio> perNegozio(List<Spesa> chiuse, Map<int, String> nomi, CivilDate da, CivilDate a);
  /// Spesa media nel periodo (Money.average: null se nessuna spesa) e sforamenti (totale > budget).
  static ({Money? media, int sforamenti, int conBudget}) riepilogo(List<Spesa> chiuse, CivilDate da, CivilDate a);
  /// Il budget del MESE (D3, Pro): spese chiuse del mese + la spesa in corso se iniziata nel mese.
  static BudgetMese budgetMese(List<Spesa> chiuse, Money tetto, int anno, int mese, {Spesa? inCorso});
}
@immutable final class BudgetMese { const BudgetMese({required this.anno, required this.mese, required this.tetto, required this.speso}); final int anno, mese; final Money tetto, speso; Money get residuo; LivelloBudget get livello; }
```
⚑ La media e' quella di `Money.average` (divisione intera, null su lista vuota: «nessun dato» non e'
«zero», commento in `money.dart`). Test: dataset noto di 12 spese su 3 mesi e 3 negozi, mesi vuoti,
spese senza budget fuori dal conteggio degli sforamenti, fonte scontrino che usa il totale stampato.

#### F12.1.9 — Il motore OCR: `packages/micro_ocr/` (F12.2b)

**Dart** (`lib/src/ocr_engine.dart`, `canale_ocr_engine.dart`, `fake_ocr_engine.dart`):

```dart
abstract interface class OcrEngine {
  /// 'vision' su iOS, 'ppocrv5-ort-1.28.0' su Android, 'fake' nei test. Finisce nelle fixture.
  Future<String> nome();
  /// Carica i modelli (Android: ≈ 0,5–1 s la prima volta). Idempotente. Si chiama dopo il primo frame.
  Future<void> prepara();
  /// Legge un'immagine JPEG/PNG gia' su disco. L'ordine delle righe non e' garantito.
  Future<List<RigaOcr>> leggi(String percorsoImmagine, {required OcrModo modo});
  /// Libera le sessioni (Android). Il prossimo leggi() le ricarica.
  Future<void> rilascia();
}
class OcrNonDisponibile implements Exception { const OcrNonDisponibile(this.causa); final Object causa; }

class CanaleOcrEngine implements OcrEngine {
  CanaleOcrEngine({MethodChannel canale = const MethodChannel('micro_ocr')});
  // leggi → invokeListMethod<Map>('leggi', {'percorso': p, 'modo': modo.name}) → RigaOcr.fromJson
  //   (iOS manda il riquadro come lo da' Vision, chiave 'origine': 'basso': si converte con Riquadro.daVision)
  // PlatformException(code: 'non_disponibile') e MissingPluginException → OcrNonDisponibile
}

class FakeOcrEngine implements OcrEngine {
  FakeOcrEngine({List<RigaOcr> righe = const [], this.ritardo = Duration.zero, this.errore});
  List<RigaOcr> righe;               // modificabile fra un leggi e l'altro
  final Duration ritardo; final Object? errore;
  final List<String> letti = [];     // i percorsi richiesti, per le asserzioni
}
```
⚑ **Un solo canale e una sola classe Dart** per due motori nativi: la piattaforma sceglie il motore,
l'app non ha `if (Platform.isIOS)`.

**iOS** (`VisionOcr.swift`), `leggi(percorso, modo)`:
- `CGImageSourceCreateWithURL` + orientamento da `kCGImagePropertyOrientation` →
  `VNImageRequestHandler(cgImage:orientation:options:)`. ☠ Senza l'orientamento EXIF le foto in
  verticale arrivano ruotate di 90° e Vision legge pochissimo.
- `VNRecognizeTextRequest`: `recognitionLevel = .accurate`; `revision` = la piu' alta in
  `VNRecognizeTextRequest.supportedRevisions`; `recognitionLanguages` = `["it-IT", "en-US"]`
  filtrate per `supportedRecognitionLanguages()` (f12-ocr.md §2: l'italiano c'e' dalla rev. 2);
  `usesLanguageCorrection = false` (la correzione «aggiusta» i numeri); `customWords = ["TOTALE",
  "SUBTOTALE", "COMPLESSIVO", "SCONTO", "ANZICHÉ", "€/KG", "€/LT", "IMPORTO", "TARA", "NETTO", "STORNO"]`
  (efficaci solo con la correzione accesa: si mettono comunque, costano zero);
  `minimumTextHeight` = 0 per `cartellino`, `0.008` per `scontrino`.
- Per ogni `VNRecognizedTextObservation`: `topCandidates(1).first` → `{"t": testo, "c": confidence,
  "x","y","w","h": boundingBox, "origine": "basso"}`.
- Gira su una `DispatchQueue(label: "micro_ocr", qos: .userInitiated)`; risposta sul main thread.
- Nessuna dipendenza in `Package.swift`/podspec oltre a Vision/ImageIO (framework di sistema).

**Android** (Kotlin, `com.smp.micro_ocr`):

```kotlin
class MicroOcrPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    // canale "micro_ocr"; metodi "nome", "prepara", "leggi" {percorso, modo}, "rilascia"
    // un solo Executors.newSingleThreadExecutor(): le chiamate si mettono in fila, mai due OCR insieme
}
class PpOcrEngine(private val assets: AssetManager) : AutoCloseable {
    fun prepara()                                            // crea le due OrtSession, legge latin_dict.txt
    fun leggi(bitmap: Bitmap, modo: String): List<RigaRiconosciuta>
    override fun close()
}
data class RigaRiconosciuta(val testo: String, val sinistra: Float, val alto: Float,
                            val larghezza: Float, val altezza: Float, val confidenza: Float)
object ImmagineIngresso { fun carica(percorso: String, latoMax: Int = 2400): Bitmap }   // inSampleSize + rotazione EXIF
object Preprocess {
    fun dimensioniDet(w: Int, h: Int, latoMax: Int): Pair<Int, Int>   // stesso rapporto, multipli di 32, ≥ 32
    fun tensoreDet(b: Bitmap, w: Int, h: Int): FloatArray             // CHW, (px/255 − mean)/std
    fun tensoreRec(crop: Bitmap, altezza: Int = 48, larghezzaMax: Int = 1600): Pair<FloatArray, Int>  // CHW, (px/255 − 0,5)/0,5
}
data class Rettangolo(val sinistra: Int, val alto: Int, val destra: Int, val basso: Int)
object DbPostprocess {
    fun riquadri(mappa: FloatArray, w: Int, h: Int, soglia: Float = 0.3f, sogliaRiquadro: Float = 0.6f,
                 unclip: Float = 1.6f, latoMin: Int = 3): List<Rettangolo>
}
class CtcDecoder(private val dizionario: List<String>) {
    fun decodifica(uscita: FloatArray, passi: Int, classi: Int): Pair<String, Float>   // testo, confidenza media
}
object Strisce {
    fun tagli(larghezza: Int, altezza: Int, sovrapposizione: Float = 0.15f): List<IntRange>   // fasce orizzontali alte ≈ larghezza
    fun unisci(riquadri: List<Rettangolo>, iou: Float = 0.5f): List<Rettangolo>               // doppioni delle sovrapposizioni
}
```

Catena di `PpOcrEngine.leggi`, **con i parametri di partenza di RapidOCR 3.10** (gli stessi del banco
che ha dato le misure di f12-ocr.md §7; ☠ da ricontrollare nel suo `config.yaml` in F12.2b e da
confermare col test di parita' sotto):
1. `ImmagineIngresso.carica`: decodifica con `inSampleSize` finche' il lato lungo ≤ 2400, ruota secondo
   `ExifInterface.TAG_ORIENTATION`.
2. **Rilevatore**: `cartellino` → l'immagine intera ridotta a lato lungo **960** (multipli di 32);
   `scontrino` → `Strisce.tagli` (fasce alte quanto la larghezza, sovrapposte del 15%), ognuna ridotta a
   lato lungo 960. ⚑ Uno scontrino lungo ridotto tutto a 960 px lascerebbe righe alte 3-4 px: il
   rilevatore non le vede. Tensore `[1, 3, H, W]`, mean `[0.485, 0.456, 0.406]`, std `[0.229, 0.224,
   0.225]`, ordine dei canali **come RapidOCR** (☠ RGB o BGR: si verifica col test di parita').
3. `DbPostprocess.riquadri`: soglia 0,3 sulla mappa; componenti connesse (4-vicinato, BFS iterativa con
   `IntArray` come coda: niente ricorsione, niente OpenCV); per ogni componente il rettangolo
   **allineato agli assi**; punteggio = media della mappa dentro → scartata sotto 0,6; espansione
   «unclip» di `area × 1,6 / perimetro` per lato; scartati i lati < 3 px. ⚑ Rettangoli allineati e
   non ruotati (RapidOCR usa `minAreaRect` di OpenCV): l'utente inquadra dritto nel mirino e PP-OCR
   regge piccole inclinazioni; risparmia OpenCV (≈ 20 MB).
4. Per gli scontrini: coordinate riportate nell'immagine intera, `Strisce.unisci` toglie i doppioni.
5. **Riconoscitore**: ogni rettangolo ritagliato dall'immagine **originale** (non da quella ridotta),
   portato ad altezza 48 mantenendo il rapporto (larghezza ≤ 1600, multiplo di 8, riempimento a destra
   con zeri), un'inferenza per riga (⚑ niente batch in v1: semplice, e le righe di un cartellino sono
   10-30). `CtcDecoder`: argmax per passo, ripetizioni fuse, indice **0 = blank**, poi `dizionario[i − 1]`,
   l'ultima classe e' lo **spazio**. ☠ In `prepara()`: `assert(classi == dizionario.size + 2)` sull'ultima
   dimensione dell'uscita del modello: un dizionario sbagliato produce testo plausibile ma sbagliato.
6. Coordinate normalizzate 0..1 sull'immagine dopo la rotazione EXIF; origine in alto a sinistra.
- `OrtSession.SessionOptions`: `setIntraOpNumThreads(4)`, `setOptimizationLevel(ALL_OPT)`; **nessun**
  execution provider extra (NNAPI e' deprecato; XNNPACK si misura in F12.7 solo se i tempi di
  F12.1.18 non tornano).
- `consumer-rules.pro`: `-keep class ai.onnxruntime.** { *; }` (☠ JNI + R8: un crash solo in release
  e' il rischio di §10).

**I modelli** (`packages/micro_ocr/android/src/main/assets/ppocrv5/`):

| File | Origine | Dimensione | Licenza |
|---|---|---|---|
| `det.onnx` | `PP-OCRv5_mobile_det` convertito in ONNX da RapidOCR (lo stesso file che RapidOCR 3.10 ha scaricato nel venv del banco: `venv/Lib/site-packages/rapidocr/models/`) | ≈ 4,8 MB | Apache-2.0 (PaddleOCR, RapidOCR) |
| `rec_latin.onnx` | `latin_PP-OCRv5_mobile_rec`, stessa provenienza | ≈ 7,9 MB | Apache-2.0 |
| `latin_dict.txt` | `ppocrv5_latin_dict.txt` di PaddleOCR (o i metadati `character` del modello, se RapidOCR lo incorpora: si usa la stessa fonte del banco) | 502 righe | Apache-2.0 |

⚑ **Proprio i file del banco** (non scaricati di nuovo da un'altra pagina): cosi' le misure di
f12-ocr.md §7 valgono per l'app. `MODELLI.md` registra per ognuno URL d'origine, data e **SHA-256**;
`packages/micro_ocr/test/modelli_test.dart` ricalcola gli SHA-256 dei file e li confronta (un modello
cambiato per sbaglio fa fallire i test, non le letture in silenzio).

⚑ **I modelli si versionano nel repo, direttamente, senza Git LFS ne' scarico in build.** Valutate le
tre strade:
- **Git LFS**: il repo ha **due remote** (Gitea `origin` e il mirror pubblico `github`, `tool/push_all`):
  LFS va abilitato su entrambi, GitHub gratuito ha 1 GB/mese di banda, e il Mac (che compila iOS) deve
  avere `git-lfs`. ☠ Un clone senza LFS ottiene **file puntatore** da 130 byte: la build passa e l'OCR
  muore a runtime con un errore di formato del modello. Per 12,7 MB il rischio non vale.
- **Scarico in build** (script che scarica e verifica lo SHA-256): la build dipende dalla rete e da una
  pagina di terzi (HuggingFace/ModelScope) che puo' sparire o cambiare file; viola lo spirito di f12-ocr.md
  §5.3 («nessun download al primo avvio», qui spostato in build).
- **Nel repo** (scelta): 12,7 MB **una volta** nella storia (oggi il repo e' 174 MB di oggetti); si
  ricambiano solo se si cambia modello (es. PP-OCRv6, che oggi e' scartato). Apache-2.0 permette la
  redistribuzione con licenza e NOTICE: `LICENSE-PaddleOCR.txt` accanto ai modelli e voce nelle licenze
  dell'app (F12.1.12, Impostazioni › Informazioni). `.gitattributes`: aggiungere `*.onnx binary`.
- ⚑ I modelli stanno negli **asset Android del plugin**, non negli asset Flutter: cosi' finiscono
  **solo** nell'APK (sull'iPhone non servono: Vision). Peso su Android: ORT ≈ 10 MB per ABI + 12,7 MB.

**Test di parita' (F12.2b, obbligatorio prima di F12.3)**: un'app di prova minima o
`apps/spending_review/integration_test/ocr_parita_test.dart` sull'emulatore Android legge **le 33
immagini a licenza libera** copiate con `adb push` da `E:/coding/XAMPP/htdocs/microapps-campioni/f12/`
in `/sdcard/Download/f12/` (mai nel repo) e confronta il testo con quello di RapidOCR delle fixture
(F12.1.17): **≥ 95% dei numeri `x,yy` della fixture devono comparire anche nella lettura Kotlin**.
Sotto: la differenza e' nella pre/post-elaborazione (canali, normalizzazione, unclip) e si corregge
**prima** di scrivere i parser.

#### F12.1.10 — Dati (Drift, `lib/data/`)

**`negozi`**

| Colonna | Tipo | Vincoli | Note |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `nome` | TEXT | NOT NULL, 1..60, **UNIQUE COLLATE NOCASE** | come lo scrive l'utente o lo da' lo scontrino ripulito |
| `creato_il` | INTEGER | NOT NULL | epoch ms UTC |

**`spese`**

| Colonna | Tipo | Vincoli | Note |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `stato` | TEXT | NOT NULL, CHECK `IN ('in_corso','chiusa')` | |
| `negozio_id` | INTEGER | nullable, FK `negozi(id)` **ON DELETE SET NULL** | |
| `iniziata_il` | INTEGER | NOT NULL | epoch ms UTC |
| `chiusa_il` | INTEGER | nullable; CHECK `(stato = 'chiusa') = (chiusa_il IS NOT NULL)` | |
| `data_spesa` | TEXT | nullable, `YYYY-MM-DD` (`CivilDate`, ADR-008); NOT NULL quando chiusa (CHECK) | il giorno della spesa (dallo scontrino se letto) |
| `budget_cents` | INTEGER | nullable, CHECK `> 0` | |
| `totale_cents` | INTEGER | NOT NULL default 0 | ⚑ **scritto alla chiusura** (`Spesa.totale`) e non ricalcolato: un aggiornamento delle regole di calcolo non deve cambiare lo storico; per la spesa in corso si calcola dalle righe |
| `totale_scontrino_cents` | INTEGER | nullable | il TOTALE stampato |
| `fonte` | TEXT | NOT NULL default `'contate'`, CHECK `IN ('contate','scontrino')` | |

Indici: **`CREATE UNIQUE INDEX spese_una_in_corso ON spese(stato) WHERE stato = 'in_corso'`** (⚑ al
massimo **una** spesa in corso, garantito dal database e non solo dal codice: due tocchi veloci su
«+» all'avvio non devono creare due spese); `(stato, data_spesa DESC, id DESC)` per lo storico;
`(negozio_id)`.

**`righe`**

| Colonna | Tipo | Vincoli | Note |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `spesa_id` | INTEGER | NOT NULL, FK `spese(id)` **ON DELETE CASCADE** | |
| `insieme` | TEXT | NOT NULL, CHECK `IN ('contate','scontrino')` | ⚑ le righe dello scontrino si **affiancano** a quelle contate, non le sostituiscono: nel dettaglio si vedono entrambe |
| `posizione` | INTEGER | NOT NULL | ordine di inserimento dentro l'insieme |
| `nome` | TEXT | NOT NULL default '', 0..80 | |
| `pezzi` | INTEGER | nullable, CHECK 1..999 | |
| `millesimi` | INTEGER | nullable, CHECK 1..99999 | grammi o millilitri |
| `unita` | TEXT | nullable, CHECK `IN ('kg','l')` | |
| — | | CHECK `(pezzi IS NOT NULL AND millesimi IS NULL AND unita IS NULL) OR (pezzi IS NULL AND millesimi IS NOT NULL AND unita IS NOT NULL)` | |
| `prezzo_unitario_cents` | INTEGER | NOT NULL, CHECK `<> 0` | negativo solo per gli sconti |
| `totale_cents` | INTEGER | NOT NULL | `RigaSpesa.totale` **al momento dell'inserimento**, per lo stesso motivo di `spese.totale_cents` |
| `offerta_json` | TEXT | nullable | `Offerta.toJson()` |
| `prezzo_rif_cents` | INTEGER | nullable | €/kg o €/l stampato |
| `unita_rif` | TEXT | nullable, CHECK `IN ('kg','l')` | |
| `totale_stampato_cents` | INTEGER | nullable | bilancia |
| `origine` | TEXT | NOT NULL, CHECK `IN ('tastierino','cartellino','bilancia','scontrino')` | |
| `stornata` | BOOLEAN | NOT NULL default false | solo `insieme = 'scontrino'` |
| `creata_il` | INTEGER | NOT NULL | epoch ms UTC |

Indice `(spesa_id, insieme, posizione)`.

⚑ **Nessuna tabella per le foto e nessuna colonna per il testo OCR grezzo**: la foto si cancella
appena letta (F12.1.13), il testo OCR vive solo in memoria. Si salvano **solo** le righe interpretate e
confermate. ☠ E' la garanzia che i dati della carta degli scontrini (s13) non finiscano mai nel
database, nel backup o nel CSV.

```dart
// lib/data/spesa_repository.dart
class SpesaRepository {
  SpesaRepository(this._db, {DateTime Function() ora = DateTime.now});
  Stream<Spesa?> osservaInCorso();                              // con le righe, aggiornato a ogni scrittura
  /// La spesa in corso, creata se non c'e' (budget = budgetPredefinito). Transazione + indice unico.
  Future<int> assicuraInCorso({Money? budgetPredefinito});
  Future<int> aggiungiRiga(RigaSpesa riga);                     // nella spesa in corso, insieme 'contate'
  Future<void> aggiornaRiga(RigaSpesa riga);                    // ricalcola totale_cents
  Future<void> eliminaRiga(int rigaId);
  Future<void> ripristinaRiga(RigaSpesa riga, {required int posizione});  // «Annulla» dopo l'eliminazione
  Future<void> incrementaUltima();                              // +1 pezzo all'ultima riga a pezzi
  Future<void> impostaBudget(Money? budget);
  Future<void> salvaScontrino(int spesaId, LetturaScontrino lettura);     // insieme 'scontrino' (sostituisce il precedente)
  /// Chiude la spesa in corso: scrive totale_cents, data, negozio, fonte. Ritorna l'id.
  Future<int> chiudi({required CivilDate data, int? negozioId, required FonteRighe fonte});
  /// Registrazione pura dallo scontrino (nessuna spesa contata): crea una spesa gia' CHIUSA.
  Future<int> registraDaScontrino(LetturaScontrino lettura, {required CivilDate data, int? negozioId});
  Future<void> scartaInCorso();                                 // chiusura di una spesa vuota o «Butta via»
  Stream<List<Spesa>> osservaChiuse({int? limite});             // data_spesa DESC; limite null = tutte (Pro)
  Future<int> contaChiuse();
  Future<Spesa?> perId(int id);
  Future<void> eliminaSpesa(int id);
  Stream<List<Negozio>> osservaNegozi();                        // per nome
  Future<int> negozioPerNome(String nome);                      // trova (NOCASE) o crea
  Future<void> rinominaNegozio(int id, String nome);
  Future<void> eliminaNegozio(int id);                          // le spese restano «senza negozio»
}
```
⚑ **Le spese chiuse oltre le 5 nel gratis restano nel database** (F12.0 punto 5, D1): il limite lo
applica la **lettura** (`osservaChiuse(limite: 5)` se non Pro), mai una cancellazione.

`drift_schemas/drift_schema_v1.json` con `dart run drift_dev schema dump lib/data/database.dart
drift_schemas/` subito in F12.3: e' la base dei test di migrazione della v2 (§10, «migrazione che
cancella i dati»).

Impostazioni (`SettingsStore` di `micro_core`, classe `SrSettingKeys` in `lib/app/providers.dart`):
`budgetPredefinito` (int centesimi, assente = nessuno), **`budgetMensile`** (int centesimi, il tetto
del MESE, D3, Pro: una preferenza e non una tabella, un tetto uguale per tutti i mesi), `vibrazione`
(bool, default true), `temaScuro` (gestito da `themeModeProvider`, default scuro),
`suggerimentoMirinoVisto` (bool). ⚑ **Niente `preferisciPrezzoCarta`** (superato da D4: si chiede ogni
volta).

Metodi aggiunti a `SpesaRepository` in F12.4 (non nella firma sopra): `Future<int?> posizioneDi(int
rigaId)` (per «Annulla» dopo l'eliminazione), `Stream<int> osservaNumeroChiuse()` (la card delle
nascoste senza caricare tutte le righe), `Future<void> modificaChiusa(int id, {required CivilDate data,
int? negozioId})` (dettaglio dello storico); `incrementaUltima()` ritorna `Future<bool>`.

#### F12.1.11 — Rotte (`lib/app/routes.dart`)

| Rotta | Pagina | Note |
|---|---|---|
| `/` | `SpesaPage` | la spesa in corso (creata pigramente al primo «+» o cartellino) |
| `/cartellino` | `CartellinoCameraPage` | torna (`pop`) con un `RisultatoCartellino`; `SpesaPage` apre il foglio di conferma |
| `/cartellino?modo=bilancia` | `CartellinoCameraPage(modoIniziale: bilancia)` | dal foglio del peso, «Leggi l'etichetta della bilancia» |
| `/scontrino` | `ScontrinoCameraPage` | **`ProGate(FeatureKey.documentScan)`** |
| `/scontrino/confronto` | `ConfrontoPage` | `ProGate(documentScan)`; `extra: LetturaScontrino` |
| `/scontrino/registra` | `RegistraScontrinoPage` | `ProGate(documentScan)`; `extra: LetturaScontrino` |
| `/chiudi` | `ChiusuraPage` | `extra: ChiusuraArgs(fonte, lettura?)` |
| `/storico` | `StoricoPage` | gratis: ultime 5 |
| `/storico/:id` | `DettaglioSpesaPage` | una spesa nascosta (oltre le 5) dal gratis → paywall, non la pagina |
| `/statistiche` | `StatistichePage` | **`ProGate(FeatureKey.statistics)`** |
| `/impostazioni` | `ImpostazioniPage` | |
| `/impostazioni/negozi` | `NegoziPage` | |
| `/dev/ocr` | `OcrDevPage` | **solo** se `kDebugMode` o `--dart-define=SR_DEV=true`; in release la rotta non esiste (assert in `main`) |

`_id()` come in Film Tracker: un `:id` non numerico porta a «Non trovato». Il paywall si apre con
`PaywallPage.show` (§8.T), non con una rotta.

#### F12.1.12 — Le schermate («C · Una mano»)

**Colori e caratteri** (`lib/app/sr_palette.dart`, valori **esatti** della tavola `UnaMano.dc.html`):

| Token | Scuro (default) | Chiaro (⚑ derivato, la tavola e' solo scura) | Uso |
|---|---|---|---|
| `sfondo` | `#161B22` | `#F6F8FA` | fondo delle pagine |
| `fondoProfondo` | `#0F1318` | `#E9EDF1` | pannello del tastierino |
| `superficie` | `#1E252E` | `#FFFFFF` | tasti numerici, card, bottone Scontrino |
| `superficieOp` | `#262D36` | `#DDE3E9` | tasti ×, −, ⌫; traccia della barra; separatori della lista |
| `bordo` | `#3A434E` | `#C3CBD4` | bordo dei bottoni secondari |
| `testo` | `#E8EDF2` | `#12171D` | |
| `testoLista` | `#C8D0D8` | `#2B333C` | nomi nella lista degli articoli |
| `testoSecondario` | `#9AA5B1` | `#55606C` | «9 articoli · budget 60 €», «€», etichette |
| `accento` | `#4ADE80` | `#15803D` | totale sotto budget, barra, Cartellino, «+» (come QR Me, l'accento chiaro e' scurito per il contrasto AA) |
| `suAccento` | `#05230F` | `#FFFFFF` | testo sui bottoni verdi |
| `ambraFondo` / `ambraBordo` / `ambraTesto` / `ambraValore` | `#3B2410` / `#B45309` / `#FCD9A8` / `#FBBF24` | `#FFF4E5` / `#B45309` / `#7A3E06` / `#B45309` | «Differenza da guardare», budget al 80–100% |
| `rosso` | `#F87171` | `#B91C1C` | budget sforato (⚑ la tavola non lo prevede: serve un terzo stato distinguibile dall'ambra **anche per luminosita'**) |

Caratteri: **Space Grotesk** 700 per il totale, i prezzi del tastierino e i numeri delle card
(`letterSpacing` −0,03 em sul totale); **Plus Jakarta Sans** 500–800 per tutto il resto. Entrambi
variabili, dai file di `apps/qr_me/assets/fonts/` con le loro licenze OFL. Raggi: bottoni 28 (pillola
alta 56), tasti 14 (alti 48), pannello del tastierino 22, card 18. Test `palette_contrast_test.dart`
(come QR Me): ogni coppia testo/fondo ≥ 4,5:1, i numeri grandi ≥ 3:1, in entrambi i temi.

**`SpesaPage`** (`/`) — LA schermata, dall'alto, tutto in una colonna senza scorrimento della pagina
(solo la lista scorre):
1. **Riga di stato** (13, 700, `testoSecondario`): «9 articoli · budget 60 €» a sinistra (tocco →
   `BudgetSheet`); a destra il **residuo** in `accento` («−16,30», quanto manca), oppure «+3,20» in
   `rosso` se sforato, oppure niente se non c'e' budget. Senza budget la riga di sinistra dice «9
   articoli · imposta un budget».
2. **Totale enorme** (Space Grotesk 64, 700, interlinea 1): «43,70» e «€» a 30 in `testoSecondario`.
   ⚑ Il totale **non** si colora: resta `testo`. Il colore lo porta la barra e il residuo, cosi' il
   numero piu' importante si legge sempre al massimo contrasto. `Semantics(label: «Totale 43 euro e
   70, mancano 16 euro e 30 al budget»)`, `liveRegion: true`.
3. **Barra del budget**: alta 6, raggio 3, traccia `superficieOp`, riempimento `accento` (< 80%),
   ambra (80–100%), `rosso` (> 100%, piena). Assente senza budget. Al passaggio della soglia 80% e
   100% **una** vibrazione media (`Aptica.soglia`), una volta per soglia e per spesa.
4. **Lista degli articoli**, piu' recente **in alto** (⚑ la tavola mostra gli ultimi aggiunti: e'
   quello che si controlla subito dopo aver battuto), righe alte ≥ 44: nome in `testoLista` (15) a
   sinistra — «Articolo» se vuoto, «Sconto» se negativo, con sotto in piccolo «3 × 2,49», «0,258 kg ×
   29,90 €/kg», «3x2», «−30%» quando servono — e totale di riga (700) a destra. Separatore `superficieOp`.
   **Scorrimento a sinistra** = elimina, con snack «Eliminato · Annulla» (5 s,
   `SpesaRepository.ripristinaRiga`); **tocco** = `RigaSheet` (nome, quantita' ±, prezzo, offerta,
   elimina). Stato vuoto: «Batti un prezzo o inquadra un cartellino».
5. **Due tasti** affiancati, alti 56, pillola: **Cartellino** (`accento`, testo `suAccento`, 800) →
   `/cartellino`; **Scontrino** (`superficie`, bordo `bordo`, 800) → `/scontrino`, con `ProBadge` se non
   Pro (il tocco apre il paywall con `highlight: FeatureKey.documentScan`).
6. **Pannello del tastierino** (`fondoProfondo`, raggio 22, padding 10): riga «Prezzo a mano» (13,
   `testoSecondario`) con il **display** a destra (Space Grotesk 24, `TastierinoState.display`); sotto la
   griglia 4×4, spaziatura 6, tasti alti 48, Space Grotesk 20:
   ```
   7  8  9  ⌫
   4  5  6  ×
   1  2  3  −
   0  00 ,  +
   ```
   cifre su `superficie`, `⌫ × −` su `superficieOp`, **`+` su `accento`**. Ogni tasto ≥ 48×48 dp,
   `Semantics` con «cancella», «per», «meno», «aggiungi», «virgola», «doppio zero». Vibrazione leggera
   a ogni tasto (spegnibile); vibrazione d'errore su un tasto rifiutato.
7. **Barra in alto** (sopra la riga di stato, discreta): a sinistra il nome dell'app solo come titolo
   accessibile; a destra tre icone: **Storico**, **Chiudi la spesa** (attiva con almeno una riga) e
   **Impostazioni**. ⚑ La tavola non le disegna: vanno messe in alto, lontane dal pollice, perche'
   sono azioni rare e una «chiusura» per sbaglio costa una spesa.
- **Spesa rimasta aperta**: se la spesa in corso e' iniziata da piu' di 12 ore, un banner in cima
  «Spesa iniziata ieri alle 18:32» con **Chiudila** e **Continua**.
- Il paywall **mai** al primo avvio (§8.T); al primo avvio nessun onboarding: la pagina vuota e' gia'
  la spiegazione.
- ⚑ Al 130% di testo la pagina deve stare in 390×844 senza tagliare il tastierino: si riduce prima la
  lista (fino a 2 righe visibili), poi il totale (fino a 48), **mai** i tasti. Test con il font vero
  (come `display_page_test.dart` di QR Me).

**`CartellinoCameraPage`** (`/cartellino`):
- Anteprima `camera` a tutto schermo (`ResolutionPreset.veryHigh`, `enableAudio: false`), **mirino**
  orizzontale al centro: 86% della larghezza, rapporto 4:3 (i cartellini sono larghi), angoli verdi
  `accento` come nell'icona; fuori dal mirino un velo nero al 55%. Scritta sopra: «Inquadra **un**
  cartellino, da vicino». Primo uso: suggerimento «Lo scritto a mano non lo leggo: per quello c'e' il
  tastierino» (una volta, `suggerimentoMirinoVisto`).
- Interruttore segmentato in alto **Cartellino | Bilancia** (default Cartellino). ⚑ Se il risultato
  in modo Cartellino ha la firma della bilancia (`BilanciaParser.riconosce`), il foglio si apre come
  «Etichetta della bilancia» da solo: l'interruttore serve solo a forzare.
- Bottone di scatto grande in basso al centro (72 dp), **torcia** a sinistra (come QR Me, sparisce al
  primo errore), **«Da una foto»** a destra (`image_picker`, galleria).
- Allo scatto: `takePicture()` → `Fotocamera.ritagliaAlMirino` (isolate) → `LetturaService.cartellino`
  con un indicatore sul mirino «Leggo…»; la fotocamera resta **montata** (si puo' scattare di nuovo
  subito). Risultato → `pop(RisultatoCartellino)`.
- Permesso negato / nessuna fotocamera / errore: stato vuoto come `ScanPage` di QR Me («La fotocamera
  e' spenta» + «Apri le impostazioni» su iOS, «Riprova» su Android; «Da una foto» resta usabile).
- OCR non disponibile (`OcrNonDisponibile`): «Su questo telefono non riesco a leggere i cartellini:
  usa il tastierino», mai un crash.

**`ConfermaCartellinoSheet`** — la proposta da **confermare con un tocco** (bottom sheet, mai aggiunta
da sola):
- In alto il **nome** (modificabile, campo a una riga) e sotto il **prezzo da pagare grande** (Space
  Grotesk 40); se c'e' un'offerta, una pillola: «3x2 · 1,26 cad. se ne prendi 3», «−30% alla cassa ·
  0,69», «Anziche' 2,99 · risparmi 1,50». ⚑ **Due prezzi con e senza carta (D4)**: al posto del
  prezzo grande «Questo cartellino ha due prezzi: quale paghi?» e **due bottoni**, «Con la carta
  fedelta': 1,99» e «Senza la carta: 2,49», ciascuno gia' l'«Aggiungi» di quel prezzo; nessun default.
- Riga piccola: «9,95 €/kg» (prezzo unitario stampato) se c'e'.
- **Quantita'** con − e + (default 1; con NxM il default e' N, ⚑ chi guarda un 3x2 di solito ne prende 3).
- Se `affidabilita' < 0,6` o ci sono `alternative`: «Controlla il prezzo» in ambra e i **chip** dei
  prezzi alternativi («2,49», «1,99»): un tocco li sostituisce.
- Piu' cartellini letti: prima un elenco «Ho visto 2 cartellini: quale?» (nome e prezzo di ciascuno).
- Prodotto gia' nella spesa (stesso nome normalizzato e stesso prezzo): il bottone principale diventa
  «**Aggiungi (ora 2)**» e incrementa la riga esistente (⚑ cosi' un 3x2 scattato tre volte fa scattare
  l'offerta).
- Bottoni: **Aggiungi** (pillola `accento`, a tutta larghezza, il tocco unico), «Riprova» (torna alla
  fotocamera), «Batti a mano» (chiude e porta il prezzo letto nel display del tastierino).
- `aMisura` (solo €/kg): il foglio diventa **`PesoSheet`**.

**`PesoSheet`** — prodotto a peso dopo un cartellino al kg (o dal `RigaSheet`): «1,48 €/kg» in alto, un
**tastierino uguale** a quello della pagina ma per grammi (interi, con «kg» / «g» commutabile; `0,500 kg`
= 500 g), anteprima «0,500 kg × 1,48 = 0,74 €» (`Arrotonda.perMisura`) in tempo reale; **Aggiungi**; e
il bottone **«Leggi l'etichetta della bilancia»** (→ `/cartellino?modo=bilancia`), ⚑ perche' alla
bilancia self-service il peso esatto lo stampa l'etichetta.

**`ConfermaBilanciaSheet`**: prodotto, «0,258 kg × 29,90 €/kg», **totale grande** (7,71), riga ambra
«Il conto peso × prezzo non torna: controlla» se `coerente == false`; campi modificabili; **Aggiungi**
→ riga `AMisura` con `totaleStampato`.

**`ScontrinoCameraPage`** (`/scontrino`, Pro): mirino **verticale** (88% della larghezza, 3:5), «Inquadra
lo scontrino dritto, tutto in larghezza». Dopo lo scatto: miniatura e due bottoni **«Leggi»** e
**«Aggiungi un pezzo»** (⚑ fino a **4** foto dello stesso scontrino, dall'alto in basso: uno scontrino
di 40 righe in una foto sola ha caratteri troppo piccoli). «Da una foto» (anche piu' foto). «Leggi» →
`LetturaService.scontrino(parti)` → se c'e' una spesa con righe contate: `/scontrino/confronto`;
altrimenti `/scontrino/registra`.

**`ConfrontoPage`** — «Scontrino contro conto» (seconda schermata della tavola):
1. Testata con indietro (44×44, bordo) e titolo «Scontrino contro conto» (18, 800).
2. Due card affiancate (`superficie`, raggio 18): «Scontrino» **45,35** e «Contato» **43,70** (Space
   Grotesk 28).
3. Card della differenza: `tuttoTorna` → verde «Tutto torna» con ✔ come **icona** (non nel testo);
   altrimenti ambra (`ambraFondo`, bordo `ambraBordo`): «Differenza da guardare» (`ambraTesto`, 700)
   e «+1,65» (`ambraValore`, Space Grotesk 26).
4. Le **righe sospette**: nome (700) con sotto la nota (12, `testoSecondario`): «cartellino 7,90 ·
   scontrino 9,40», «solo sullo scontrino», «contato ma non sullo scontrino», «sullo scontrino due
   volte?»; a destra il delta in ambra. Tocco → dettaglio con entrambe le righe. Sotto, ripiegate,
   «Righe che tornano (N)».
5. Avvisi: «Il totale letto non corrisponde alla somma delle righe: N righe non lette» se
   `!quadra`; «Ho unito N foto senza trovare il punto di unione…» se una giunzione manca.
6. In fondo: **Chiudi la spesa** (pillola `accento`) → `/chiudi` con la scelta della fonte;
   **Rifotografa lo scontrino** (secondario, alto 48, trasparente con bordo).

**`RegistraScontrinoPage`** — registrazione pura: negozio (dallo scontrino, modificabile), data (dallo
scontrino o oggi), righe lette (modificabili, eliminabili, con lo stato «stornata»), totale stampato e
avviso se non quadra; **Salva la spesa** → `SpesaRepository.registraDaScontrino` → `/storico/:id`.

**`ChiusuraPage`** (`/chiudi`): totale grande; budget con esito («Dentro il budget di 3,20» /
«Sforato di 4,10»); **Negozio**: chip dei 5 piu' recenti + «Altro…» (campo con suggerimenti da
`osservaNegozi`, crea con `negozioPerNome`); **Data** (oggi, o quella dello scontrino; selettore);
se c'e' uno scontrino letto: scelta **«Salva le righe dello scontrino»** (default se `quadra`) /
**«Salva le righe contate»**; **Salva** → storico. Spesa senza righe: «Non c'e' niente da salvare» e
**Butta via** (`scartaInCorso`). Dopo il salvataggio, nel gratis, se le spese chiuse superano 5: snack
«Salvata. Nel piano gratuito vedi le ultime 5: le altre restano sul telefono».

**`StoricoPage`** (`/storico`): spese chiuse raggruppate per mese («Ottobre 2026 · 4 spese · 182,40
€»), riga: giorno, negozio (o «Senza negozio»), totale, pallino ambra/rosso se il budget e' stato
sforato. Gratis: le ultime 5 e una card in fondo «Le altre N spese sono sul telefono: con il Pro le
rivedi tutte, con le statistiche» → paywall (`highlight: fullHistory`). In alto l'icona **Statistiche**
(`ProBadge` senza Pro). **`DettaglioSpesaPage`**: righe dell'insieme che fa fede, «Mostra anche le
righe contate/dello scontrino» se ci sono entrambe, totale, budget, negozio e data modificabili,
**Elimina** con conferma.

**`StatistichePage`** (Pro): selettore del mese (frecce), la card del **budget del mese** (D3: «182,40
€ su 400 €», barra coi colori del budget, residuo o sforamento, «Imposta»/«Cambia» il tetto con lo
stesso foglio del budget), quattro `MicroStatTile`: **Totale del mese**,
**Spese**, **Spesa media**, **Sforamenti** («2 su 5 con budget»); grafico a barre degli **ultimi 6
mesi** (`CustomPainter`, come Film Tracker e Scorte Calore, con `Semantics` che legge i valori); tabella
**per negozio** (nome, spese, totale, media) per il mese o per «Ultimi 12 mesi» (interruttore).

**`ImpostazioniPage`**: **Budget abituale** (campo prezzo, «nessuno»); ~~Ho la carta fedelta'~~
(tolto da D4: si chiede ogni volta); **Vibrazione**; **Negozi** (→ `/impostazioni/negozi`: rinomina, elimina);
**Tema** (scuro / chiaro / come il telefono); **Pro** (stato, acquisto, ripristino acquisti);
**I tuoi dati** (`data_section.dart` come Film Tracker: backup **Pro**, ripristino **gratis**, CSV
**Pro**); **Informazioni** (versione, informativa privacy, **licenze**: `LicenseRegistry.addLicense`
per PaddleOCR/RapidOCR Apache-2.0 con NOTICE e ONNX Runtime MIT, solo su Android).

**`OcrDevPage`** (`/dev/ocr`, solo sviluppo): scatta o sceglie una foto, mostra le righe lette con i
riquadri disegnati sopra, il risultato dei tre parser, e **«Esporta fixture»**: un JSON nel formato di
F12.1.17 (senza immagine) condiviso con `share_plus`. ⚑ E' lo strumento per raccogliere le fixture di
**Vision** dall'iPad e quelle delle **foto vere** del proprietario (F12.7). ☠ In release non deve
esistere: rotta registrata solo se `kDebugMode || SR_DEV`, e test che lo verifica.

#### F12.1.13 — Servizi (`lib/services/`)

```dart
class Fotocamera {
  /// Ritaglia la foto al rettangolo del mirino (frazioni 0..1 dell'anteprima, convertite tenendo conto
  /// del rapporto foto/anteprima e della rotazione EXIF) e la salva JPEG 92 in getTemporaryDirectory().
  /// In Isolate.run: decodificare una foto da 12 MP sul thread dell'interfaccia blocca 300-800 ms.
  static Future<String> ritagliaAlMirino(String percorsoFoto, Rect mirino, {required Size anteprima});
}

class LetturaService {
  LetturaService({required OcrEngine motore, CartellinoParser cartellino = const CartellinoParser(),
      BilanciaParser bilancia = const BilanciaParser(), ScontrinoParser scontrino = const ScontrinoParser(),
      DateTime Function() ora = DateTime.now});
  /// Foto → OCR (modo cartellino) → bilancia se riconosciuta, altrimenti cartellino.
  /// La foto (e il ritaglio) si CANCELLANO nel finally, letta o no.
  Future<RisultatoCartellino> cartellino(String percorso, {required bool forzaBilancia});
  /// Le parti in ordine; OCR modo scontrino per ognuna; UnisciParti; ScontrinoParser. Foto cancellate.
  /// ⚑ F12.4: ritorna `ScontrinoLetto(lettura, giunzioniTrovate)` (serve all'avviso delle giunzioni);
  /// `ScontrinoLetto` e' anche l'`extra` di `/scontrino/confronto` e `/scontrino/registra`.
  Future<ScontrinoLetto> scontrino(List<String> percorsi);
}
sealed class RisultatoCartellino { const RisultatoCartellino(); }
final class LettoCartellino extends RisultatoCartellino { const LettoCartellino(this.lettura); final LetturaCartellino lettura; }
final class LettaBilancia extends RisultatoCartellino { const LettaBilancia(this.lettura); final LetturaBilancia lettura; }
final class NienteLetto extends RisultatoCartellino { const NienteLetto({required this.forseAMano}); final bool forseAMano; }
final class OcrAssente extends RisultatoCartellino { const OcrAssente(); }
```
⚑ **Le foto si cancellano sempre** (anche quelle scelte dalla galleria: si cancella la **copia**
temporanea che `image_picker` crea, mai l'originale dell'utente). Nessuna foto nel database, nel
backup o nel CSV: e' la regola di privacy dello scontrino (s13).
Il motore si prepara (`OcrEngine.prepara`) **3 secondi dopo il primo frame** in `SpendingReviewApp`
(come `pruneOrphanLogos` di QR Me): la prima lettura non paga il caricamento dei modelli, e l'avvio
non lo paga nemmeno.

```dart
class CsvExport {
  const CsvExport();
  /// Un file, una riga per RIGA di spesa (insieme che fa fede), colonne:
  /// Data;Negozio;Spesa n.;Articolo;Quantita';Unita';Prezzo unitario;Offerta;Totale riga;Totale spesa;Budget;Origine
  /// Decimali con la virgola (Money.formatPlain(locale: 'it')), CsvWriter di micro_core (';' e BOM).
  String costruisci(List<Spesa> chiuse, Map<int, String> negozi, {required AppLocalizations l});
}
class SpendingBackupSource implements BackupSource {
  SpendingBackupSource(SpendingDatabase db);
  // schemaId 'spending_review', schemaVersion 1; payload {negozi, spese, righe}; counts {spese, righe, negozi}.
  // imagePaths: nessuna. Import replaceAll: svuota e riscrive in una transazione.
  // Import mergeKeepExisting: negozi uniti per nome (NOCASE); spese aggiunte con id nuovi; una spesa
  // IN CORSO del file diventa CHIUSA (data = giorno di iniziata_il) se ha righe, altrimenti si scarta
  // (l'indice unico ne vuole una sola, e quella del telefono vince).
}
class Aptica {
  Aptica({required bool attiva});
  void tasto(); void rifiuto(); void soglia(); void aggiunto();   // HapticFeedback.selectionClick/heavy/medium/light
}
```

#### F12.1.14 — Pro (`lib/app/feature_limits.dart`, `paywall_config.dart`)

```dart
const FeatureLimits srFeatureLimits = <FeatureKey, FeatureLimit>{
  FeatureKey.fullHistory: FeatureLimit.count(freeMax: 5),   // 5 spese chiuse VISIBILI (le altre restano)
  FeatureKey.documentScan: FeatureLimit.locked(),          // Scontrino: confronto e registrazione
  FeatureKey.statistics: FeatureLimit.locked(),
  FeatureKey.csvExport: FeatureLimit.locked(),
  FeatureKey.backupRestore: FeatureLimit.locked(),          // il ripristino resta gratis
  // tutte le altre: FeatureLimit.open(), esplicite (il test di coerenza le vuole tutte)
  FeatureKey.unlimitedEntities: FeatureLimit.open(), FeatureKey.secondaryEntities: FeatureLimit.open(),
  FeatureKey.photos: FeatureLimit.open(), FeatureKey.pdfReport: FeatureLimit.open(),
  FeatureKey.advancedWidget: FeatureLimit.open(), FeatureKey.notifications: FeatureLimit.open(),
  FeatureKey.multipleNotifications: FeatureLimit.open(), FeatureKey.calendarSync: FeatureLimit.open(),
  FeatureKey.customCategories: FeatureLimit.open(), FeatureKey.themeCustomization: FeatureLimit.open(),
  FeatureKey.imageExport: FeatureLimit.open(),
};
```
Paywall (`buildSrPaywall(AppLocalizations l)`), **cinque righe, una per chiave limitata**, in
quest'ordine: «**Scontrino**: controlla la cassa e registra la spesa dallo scontrino»
(`documentScan`); «**Tutte le spese**, non solo le ultime 5» (`fullHistory`); «**Statistiche** per mese
e per negozio, spesa media, sforamenti del budget» (`statistics`); «**Export CSV**» (`csvExport`);
«**Backup**» (`backupRestore`). Titolo «Spending Review Pro», prezzo dallo store, «Una volta sola, per
sempre». Gateway finto: `FakePurchaseGateway.withProduct(config.proSku, formattedPrice: '2,99 €')`.
**F12.2a** aggiunge `FeatureKey.documentScan` a `micro_core` (doc: «Leggere con la fotocamera un
documento intero, es. lo scontrino di Spending Review, e ricavarne i dati. ⛑ Distinta da [photos]:
il documento si legge e si butta, non si allega») e la riga `FeatureKey.documentScan:
FeatureLimit.open()` nelle mappe di TrashCan, Full Freezer, Scorte Calore, Film Tracker e QR Me.
Nessun cambiamento di comportamento per loro.

#### F12.1.15 — Permessi e privacy

| Piattaforma | Permesso | Quando |
|---|---|---|
| Android | `CAMERA` (dichiarato **da noi**) | al primo tocco su Cartellino o Scontrino |
| Android | **tolti** con `tools:node="remove"`: `RECORD_AUDIO`, `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE` (portati da `camera_android_camerax`, come in QR Me); `uses-feature android.hardware.camera.any` `required="false"` (`tools:replace`): ⚑ il tastierino funziona senza fotocamera, l'app non deve sparire da Play per i dispositivi senza | — |
| Android | `com.android.vending.BILLING` | il Pro |
| Android | `INTERNET` / `ACCESS_NETWORK_STATE`: **non dichiarati da noi**; li porta Play Billing (`transport-backend-cct`), e la guardia di F12.1.2 controlla che arrivino solo da li'. Servono al Pro e al server licenze | — |
| iOS | `NSCameraUsageDescription` («Per leggere cartellini e scontrini con la fotocamera.» / «To read price tags and receipts with the camera.») | |
| iOS | `NSPhotoLibraryUsageDescription` (richiesta da `image_picker` anche col picker di sistema) | «Da una foto» |
| iOS | **niente** `NSMicrophoneUsageDescription` (fotocamera con `enableAudio: false`); ⚠ se App Store Connect manda ITMS-90683 al primo caricamento, si aggiunge (come previsto in F17.1.10) | |

Niente notifiche, niente posizione, niente contatti, niente rete dall'app (a parte il Pro).

**Privacy** (testo per l'informativa del sito, pagina di Spending Review): «Le foto di cartellini e
scontrini vengono lette **sul telefono** (su iPhone dal sistema di Apple, su Android da un motore
incluso nell'app) e **cancellate subito dopo la lettura**. Nessuna foto e nessun dato della spesa esce
dal telefono. L'unica comunicazione esterna e' l'acquisto della versione Pro (Google Play / App
Store) e, su Android, la sua verifica sul nostro server». Data safety di Play: come le altre app con il
Pro (eccezione del 2026-10-09). `android:allowBackup="false"` e, su iOS, `isExcludedFromBackup` sulla
cartella `Documents/` in `AppDelegate.swift` (come QR Me, F17.7.3): ⚑ i dati della spesa (dove e quando
si compra, quanto si spende) non devono finire in un backup automatico verso Google Drive o iCloud che
l'utente non ha scelto: la regola «dati solo sul telefono». Il backup lo fa l'utente, col Pro, in un
file che vede.

#### F12.1.16 — Trappole note in anticipo

1. ☠ **ONNX Runtime ≥ 1.29 = telemetria.** `strictly("1.28.0")` + task Gradle + script sul `.so`
   (F12.1.2). Un Dependabot, un `flutter pub upgrade` o un plugin nuovo che porta ORT non deve passare.
2. ☠ **`INTERNET` nel manifest c'e' comunque** (Play Billing): il controllo guarda **chi** lo porta,
   non **se** c'e' (F12.0 punto 9).
3. ☠ **Asse y di Vision capovolto** e **orientamento EXIF** su entrambe le piattaforme: test di
   `Riquadro.daVision`, foto verticali nel test di parita'.
4. ☠ **Dizionario del riconoscitore** disallineato di una posizione = testo plausibile ma sbagliato:
   assert sulle classi in `prepara()` e SHA-256 dei file (F12.1.9).
5. **Centesimi in apice** letti come «229» o «1 | 06»: per questo il parser lavora sui riquadri
   (F12.1.4), e c'e' un test per ciascuna forma.
6. **Arrotondamenti**: half-up intero; sconto arrotondato **prima** della sottrazione; mai
   `Money.operator *` per i pesi (F12.1.3).
7. **NxM con il prezzo effettivo in grande** (c01, c11): il prezzo della riga e' il pieno.
8. ☠ **Dati della carta sugli scontrini** (s13): il piede si scarta nel parser, il testo grezzo non si
   salva, le foto si cancellano, le fixture si ripuliscono (F12.1.17), gli screenshot dello store
   usano scontrini **inventati**.
9. **Due spese in corso** da tocchi ravvicinati: indice unico parziale nel database (F12.1.10).
10. **Plugin con iOS che porta ORT**: per questo niente `flutter_onnxruntime` (F12.1.2).
11. **Primo OCR lento** (caricamento dei modelli): `prepara()` dopo il primo frame (F12.1.13).
12. **R8 e JNI di ORT**: `consumer-rules.pro`; build di release provata su dispositivo prima di ogni
    upload (§10).
13. **16 KB page size** di Play: verifica in F12.2b (F12.1.2 punto 4).
14. **Deep link di Flutter spento** (F12.0 punto 11).

#### F12.1.17 — Test da scrivere

| File | Cosa dimostra |
|---|---|
| `packages/micro_core/test/…` (esistenti) + i cinque `paywall_config_test.dart` | `documentScan` mappata ovunque, nessun comportamento cambiato (F12.2a) |
| `packages/micro_ocr/test/riga_ocr_test.dart` | JSON di andata e ritorno; `Riquadro.daVision` (y capovolto) su 4 casi; `sovrapposizioneVerticale` |
| `packages/micro_ocr/test/canale_ocr_engine_test.dart` | con un `MethodChannel` finto: conversione delle mappe, `origine: basso`, `PlatformException('non_disponibile')` e `MissingPluginException` → `OcrNonDisponibile` |
| `packages/micro_ocr/test/modelli_test.dart` | SHA-256 dei tre file in `android/src/main/assets/ppocrv5/` uguali a `MODELLI.md` |
| `packages/micro_ocr/android/src/test/kotlin/…/DbPostprocessTest.kt` | mappa sintetica con due blocchi → due rettangoli; sotto soglia → niente; unclip; lati minimi |
| `…/CtcDecoderTest.kt` | blank, ripetizioni fuse, spazio finale, confidenza media |
| `…/PreprocessTest.kt` | dimensioni multiple di 32 e rapporto conservato; valori normalizzati di un pixel noto |
| `…/StrisceTest.kt` | tagli sovrapposti che coprono tutta l'altezza; fusione dei doppioni (IoU) |
| `apps/spending_review/test/domain/arrotonda_test.dart` | half-up intero, negativi simmetrici, i 9 casi della bilancia e i 4 di s03, sconto c29/c30 |
| `test/domain/offerta_test.dart` | tabella di F12.1.3 per q = 1..7, JSON tollerante |
| `test/domain/riga_spesa_test.dart` | totale per Pezzi/AMisura/offerta/totale stampato/sconto negativo |
| `test/domain/spesa_test.dart` | totale per fonte, articoli, residuo e `LivelloBudget` ai bordi 79,99% / 80% / 100% / 100,01% |
| `test/domain/tastierino_test.dart` | **ogni riga** della tabella del tastierino, piu' sequenze complete («2 4 9 +», «2 , 4 9 +», «3 00 +», «3 × 2 4 9 +», «2 4 9 × 3 +», «− 1 5 0 +», «+» a vuoto, rifiuti) |
| `test/domain/nomi_test.dart` | normalizzazione, formati (200 g, GR.600, LT 1, 6x180 ml, 50 cl), similarita' con abbreviazioni |
| `test/domain/numeri_ocr_test.dart` | pulizia (O→0, «16..50», «2 ,49»), migliaia, negativi «-0,40» e «0,40-», spezzati e fusi |
| `test/domain/cartellino_parser_test.dart` | i casi della tabella di F12.1.4 |
| `test/domain/bilancia_parser_test.dart` | i casi di F12.1.5 |
| `test/domain/scontrino_parser_test.dart` | i casi di F12.1.6, compresa l'assenza delle righe di pagamento |
| `test/domain/unisci_parti_test.dart` | giunzione trovata, non trovata, parte singola |
| `test/domain/confronto_test.dart` | i casi di F12.1.7 |
| `test/domain/statistiche_test.dart` | dataset noto (F12.1.8) |
| `test/domain/banco_parser_test.dart` | **il banco di regressione** (sotto) |
| `test/data/spesa_repository_test.dart` | una sola spesa in corso (anche con due `assicuraInCorso` concorrenti), chiusura con totale scritto, righe scontrino affiancate, spese oltre le 5 **conservate**, cascata, negozio eliminato → spese senza negozio, `ripristinaRiga` |
| `test/data/backup_test.dart` | round-trip ZIP nelle due modalita', spesa in corso del file in `mergeKeepExisting` |
| `test/services/lettura_service_test.dart` | con `FakeOcrEngine`: cartellino, bilancia riconosciuta da sola, niente letto, OCR assente; **le foto temporanee non esistono piu'** dopo ogni chiamata, anche con errore |
| `test/services/csv_export_test.dart` | colonne, virgola decimale, BOM, nessun testo OCR grezzo |
| `test/widget/paywall_config_test.dart` | tutte le chiavi mappate, una riga per chiave limitata, limiti come F12.0 punto 5 |
| `test/widget/spesa_page_test.dart` | battere e aggiungere, totale e residuo, colori della barra alle soglie, scorrimento + «Annulla», Scontrino con badge senza Pro, layout a 412 dp al 130% con Space Grotesk vero (nessun tasto tagliato) |
| `test/widget/conferma_cartellino_test.dart` | niente si aggiunge senza tocco; chip alternativi; «Aggiungi (ora 2)»; NxM con quantita' N di default; scelta fra due cartellini |
| `test/widget/confronto_page_test.dart` | card ambra con +1,65 e le due righe della tavola; «Tutto torna» |
| `test/widget/storico_page_test.dart` | 7 spese chiuse, gratis → 5 visibili + card «Le altre 2…»; Pro → 7 |
| `test/widget/palette_contrast_test.dart` | contrasti di F12.1.12 in entrambi i temi |
| `test/widget/texts_glyphs_test.dart` | nessun ✓⚠✗ negli ARB (come QR Me) |
| `test/widget/dev_route_test.dart` | `/dev/ocr` assente quando `kDebugMode` e `SR_DEV` sono falsi (iniettati) |
| `integration_test/ocr_motore_test.dart` | sul dispositivo: un PNG **generato dal test** (testo «PASTA 500 g» e «2,49» disegnati con `dart:ui`) letto dal motore vero → contiene «2,49» (Android ORT e iOS Vision) |
| `integration_test/ocr_parita_test.dart` | solo Android, F12.2b: parita' con RapidOCR (F12.1.9), salta se `/sdcard/Download/f12/` non c'e' |

**Il banco di regressione del parser** (`test/domain/banco_parser_test.dart`):
- ⚑ **Nel repo va solo il TESTO OCR estratto (righe + riquadri + confidenza) e la verita', mai le
  immagini.** Le immagini restano in `E:/coding/XAMPP/htdocs/microapps-campioni/f12/` (licenze,
  dati personali, peso: `LEGGIMI.md` dei campioni). Il parser lavora solo sulle righe: con le righe
  salvate il test e' **deterministico**, gira in millisecondi sotto `flutter test` su Windows e sul
  Mac, senza motore OCR e senza dispositivo.
- **Formato** di `test/fixtures/ocr/ppocrv5/<nome-campione>.json`:
  ```json
  {"campione": "c14_esselunga_borotalco.jpg", "tipo": "cartellino", "licenza": "CC BY-SA 3.0",
   "motore": "ppocrv5-mobile-latin/rapidocr-3.10", "creato": "2026-10-12",
   "righe": [{"t": "1,99", "x": 0.41, "y": 0.38, "w": 0.22, "h": 0.12, "c": 0.97}],
   "verita": [{"nome": "...", "prezzo": "1,99", "al_kg": "9,95", "unita": "kg"}]}
  ```
  `verita` e' una lista (piu' cartellini per foto), con le chiavi di `campioni.csv`.
- **Quali campioni nel repo**: solo i **33 a licenza libera** (pubblico dominio, CC BY, CC BY-SA):
  c01–c13, c23, c24, c25, s01–s15, b07, b09. `test/fixtures/ocr/LICENZE.md` elenca per ognuno fonte,
  autore e licenza (CC BY e BY-SA chiedono l'attribuzione; le trascrizioni si distribuiscono con la
  stessa licenza). Gli altri **27** (CC BY-NC e licenza sconosciuta: c14–c22, c26–c35, s16, b01–b06,
  b08) hanno le fixture **fuori dal repo**, in `E:/coding/XAMPP/htdocs/microapps-campioni/f12/fixture/ppocrv5/`,
  e il banco le carica **se** la variabile d'ambiente `SR_CAMPIONI` punta a quella cartella
  (`Platform.environment`), altrimenti le salta stampando «27 fixture private non trovate».
- **Ripulitura dei dati personali**: lo script toglie dalle righe degli scontrini quelle che
  combaciano con `\*{3,}\d{3,4}|aut(orizzazione)?\.?\s*\d|terminale|term\.|id\s*trans|n\.?\s*operazione|stan\b|a\.?i\.?d\.?`
  e il banco **fallisce** se in una fixture del repo trova `\*{4}\d{4}`.
- **Script**: `apps/spending_review/tool/esporta_fixture_ocr.py`, lanciato con
  `venv\Scripts\python -I esporta_fixture_ocr.py <cartella_campioni> --licenze-libere <dest_repo>
  --altre <dest_fuori>` nel venv di f12-ocr.md §6.3, con **RapidOCR 3.10 e gli stessi modelli** di
  `micro_ocr` (det/rec di PP-OCRv5 mobile latin; il riquadro a 4 punti diventa il rettangolo che lo
  contiene, normalizzato). ⚑ Le fixture vengono dal **PC**, non dal telefono: il test di parita'
  (F12.1.9) garantisce che il motore Kotlin legga lo stesso testo. Le fixture di **Vision** (cartella
  `test/fixtures/ocr/vision/`) arrivano in F12.7 dall'iPad con `OcrDevPage` → «Esporta fixture», per gli
  stessi 33 campioni mostrati a schermo dal PC e fotografati; il banco gira su entrambe le cartelle.
- **Metriche**, per motore e per tipo: cartellino `prezzo`, `prezzo_pieno`, `al_kg`, `offerta`;
  bilancia `totale`, `peso_kg`, `al_kg`; scontrino `totale`, `negozio` (similarita' ≥ 0,8), `righe`
  (numero di articoli ±1). Una verita' vale «presa» se la **prima** proposta del parser ha quel valore.
- ⚑ **Un «cricchetto», non una soglia inventata**: `test/fixtures/ocr/soglie.json` tiene, per motore,
  tipo e campo, il numero di casi giusti dell'ultima versione accettata. Il test **fallisce se un
  numero scende**; se sale, stampa «aggiorna soglie.json: cartellino.prezzo 24 → 26» (si aggiorna a
  mano, nello stesso commit). Le soglie di f12-ocr.md §6.3 (prezzo ≥ 95%…) sono l'**obiettivo** sulle
  foto vere fatte col mirino, non sulle foto larghe del web, dove l'OCR stesso legge le cifre del
  prezzo nel 78% dei casi: imporle oggi farebbe un test sempre rosso, che si impara a ignorare.
- **Casi che devono passare sempre** (oltre al cricchetto): tutte le bilance (b07, b09 nel repo) e
  tutti i totali degli scontrini nel repo (s01–s15): il lettore li ha letti al 100% (f12-ocr.md §7),
  quindi un errore qui e' del parser.

#### F12.1.18 — Prestazioni attese

| Misura | Obiettivo | Dove si misura |
|---|---|---|
| Avvio a freddo fino al tastierino usabile | ≤ 1,5 s (Android medio), ≤ 1 s (iPad) | F12.7, `flutter run --profile` |
| Tocco di un tasto → totale aggiornato | un frame (≤ 16 ms) | DevTools; la riga si scrive in background, il totale si aggiorna dallo stream |
| `prepara()` dei modelli (Android) | ≤ 1 s, fuori dal thread dell'interfaccia | log `MicroLog` con i tempi |
| Cartellino: scatto → foglio di conferma | ≤ 1,5 s Android medio (OCR ≤ 1 s), ≤ 0,8 s iPad | idem, 10 letture |
| Scontrino: 1 foto | ≤ 3 s Android, ≤ 1,5 s iPad; ogni parte in piu' + lo stesso | idem |
| Parser (qualunque) | ≤ 20 ms | `banco_parser_test.dart` stampa i tempi |
| Memoria di picco durante l'OCR (Android) | ≤ 300 MB | Android Studio profiler |
| Peso dell'APK per ABI (arm64) | ≈ +23 MB rispetto a QR Me (ORT + modelli) | `flutter build apk --split-per-abi --analyze-size` |

Se i tempi Android non tornano su un telefono medio: prima si abbassa il lato del rilevatore (960 →
736), poi si prova l'execution provider XNNPACK di ORT 1.28, poi il batch del riconoscitore; **mai** un
motore che chiama la rete.

### F12.2 — Ordine di lavoro (le sottofasi standard Fx.2–Fx.9 applicate)

Ogni sottofase si chiude con il **rituale di §6** (piano, atlanti toccati con `verify_atlas`, Projects
Tracker progetto 17, messaggio dettagliato, branch di versione nuovo con `tool/bump_version.ps1`). Prima
di cominciare: il **bug del widget di TrashCan** in §7 resta la priorita' 1 se non e' chiuso.

- **F12.2a** `FeatureKey.documentScan` in `packages/micro_core/lib/src/gate/feature_key.dart` + una riga
  `open()` nei cinque `feature_limits.dart`; aggiornare l'atlante di `micro_core` e i cinque atlanti
  (sezione Pro); `pwsh tool/test_all.ps1` verde.
- **F12.2b** `packages/micro_ocr/`: `flutter create --template=plugin --platforms=android,ios --org
  com.smp packages/micro_ocr`; lato Dart (F12.1.9); iOS Vision; Android ORT `strictly 1.28.0` e la catena
  Kotlin con i test JVM (`gradlew :micro_ocr:testDebugUnitTest` dall'app di esempio del plugin);
  modelli dal venv del banco con `MODELLI.md` e SHA-256; `.gitattributes` con `*.onnx binary`; aggiunto a
  `tool/_common.ps1`; `integration_test/ocr_motore_test.dart` verde su emulatore Android **e** simulatore
  iPhone (sul Mac); **test di parita'** con RapidOCR ≥ 95%; verifica 16 KB; atlante
  `packages/micro_ocr/codebase_reference.md`. ☠ Se ORT 1.28.0 fallisce la verifica 16 KB o il test di
  parita' non si raggiunge in tempi ragionevoli: **fermarsi e dirlo al proprietario** prima di passare a
  NCNN (cambia una decisione scritta).
- **F12.2c** Bootstrap `apps/spending_review` (§8.T, come QR Me): `com.smp.spendingreview` Android e
  iOS (solo iPhone), `licenseAppId 'spendingreview'`, SKU, tema scuro e `sr_palette.dart`, font, testi
  da `tool/testi.py`, icone e splash da `docs/specs/icona-spending-review.png` con `tool/genera_icone.py`,
  manifest (F12.1.15), `allowBackup=false`, esclusione dal backup iCloud, deep link spento, task Gradle
  `verificaPrivacyOcr` (F12.1.2) **provato in negativo** (aggiungendo per prova una dipendenza con
  `INTERNET`, la build deve fallire; poi si toglie). APK debug compilato, app che parte sull'emulatore e
  sul simulatore.
- **F12.3** Dominio e dati con i test (F12.1.3–F12.1.8, F12.1.10): prima `arrotonda`, `offerta`,
  `tastierino`, poi i parser **con le fixture** (`tool/esporta_fixture_ocr.py` lanciato una volta,
  fixture libere nel repo, private fuori), il banco con il cricchetto, il confronto, il repository, lo
  schema dump.
- **F12.4** Interfaccia «C · Una mano» completa (F12.1.12) con i servizi (F12.1.13): spesa,
  cartellino, peso, bilancia, scontrino, confronto, registrazione, chiusura, storico, impostazioni,
  `OcrDevPage`; provata sull'emulatore Android con foto vere (dalla galleria: le 33 libere copiate con
  `adb push` nella galleria dell'emulatore) e sul simulatore iPhone.
- **F12.5** Pro: limiti, paywall, `ProGate` sulle pagine, test di coerenza.
- **F12.6** Grafica: scelta gia' fatta («C · Una mano», F12.0 punto 6), applicata in F12.4; qui si
  aggiungono il **tema chiaro** derivato e il test dei contrasti, e si mostrano al proprietario due
  scatti (scuro e chiaro) per conferma. Decisione in `memory/decisioni.md` gia' presente.
- **F12.7** Test, rifinitura, iOS: testo al 130%, tema chiaro e scuro, stati vuoti, `Semantics`;
  build sul Mac, **TestFlight su iPad**; **fixture di Vision** con `OcrDevPage`; **taratura con le foto
  vere del proprietario** (sotto): per ogni foto, fixture in `microapps-campioni/f12/fixture/` (le foto
  del proprietario sono sue ma contengono scontrini: restano **fuori dal repo** come le altre private),
  banco rilanciato, regole dei parser corrette, cricchetto aggiornato; misure di F12.1.18 su un Android
  vero di fascia media; `verifica_privacy_android.ps1` sull'APK di release.
- **F12.8** Atlanti: `apps/spending_review/codebase_reference.md` e `packages/micro_ocr/codebase_reference.md`
  (piu' gli aggiornamenti di `micro_core` e delle cinque app per `documentScan`), `verify_atlas` **0
  mancanti** per ciascuno, firme confrontate a macchina.
- **F12.9** Rituale di fine fase, card «In arrivo» in `site/src/apps.php` (voce `'spending-review'`,
  accento `#15803D` come QR Me o il verde dell'icona scurito per il bianco della card, `packageId
  'com.smp.spendingreview'`, `pubblicata => false`, `suPlay => false`; la pubblicazione del sito la decide
  il proprietario; siti critici di `clawserver` a 200 prima e dopo), `StatusMicroApps.md` con **tutti e
  due gli store** (fermi: perche', da quando, cosa sblocca), README, decisioni; branch con
  `pwsh tool/bump_version.ps1 -Large` (oggi l'ultimo branch e' `v9.3.4`, quindi `v10.0.0`; ☠ §7 F8 indica
  `v10.0.0` per il deploy: vince lo script, e la riga di F8 si corregge nello stesso rituale).

**Azioni del proprietario** (non si possono fare da qui):
- [x] icona (`docs/specs/icona-spending-review.png`, gia' consegnata);
- [ ] portale Apple: App ID **`com.smp.spendingreview`**, nessuna capability (niente App Group, niente
  estensioni) — serve da F12.7 per TestFlight; i profili poi via API;
- [ ] App Store Connect: l'app «Spending Review» (o il ripiego di F12.0 punto 1) e il prodotto
  `spendingreview_pro_lifetime` a 2,99 € quando si arriva allo store; classificazione per eta' ed
  etichetta privacy (come ha fatto per QR Me);
- [ ] License Server: riga `spendingreview` nella tabella `apps` e il segreto in `APP_SECRETS` (prima di
  Play);
- [ ] **Foto vere per tarare** (le lacune di `microapps-campioni/f12/LEGGIMI.md`), da mettere in
  `E:/coding/XAMPP/htdocs/microapps-campioni/f12/` con una riga in `campioni.csv` (verita' trascritta),
  fatte **col mirino dell'app** quando c'e' (F12.4), altrimenti col telefono da vicino:
  - **etichette della bilancia italiane**: banco salumi e formaggi (Esselunga, Coop, Conad, Carrefour),
    bilancia self-service dell'ortofrutta, gastronomia — almeno 10, con la **tara** in alcune;
  - **cartellini delle catene mancanti**: Conad, Coop, Lidl, Eurospin, MD, Penny, Aldi, Carrefour
    Italia, Bennet — almeno 3 per catena, compresi i **prezzi con la carta fedelta'** (prezzo con carta
    contro prezzo normale: oggi nessun campione, la regola di F12.1.4 e' scritta alla cieca);
  - **cartellini elettronici italiani** in primo piano (e-ink Esselunga, Coop, Carrefour);
  - **offerte attuali**: «prendi 2 paghi 1», «−X% sul secondo», «sottocosto», 3x2;
  - **scontrini moderni**, lunghi (anche in 2–3 foto), piegati, in controluce, con tessera fedelta',
    buoni sconto e resi, di catene diverse — ☠ coprire con un dito o un foglio le cifre della carta e i
    codici POS prima di scattare, o comunque non condividerli fuori dalla cartella dei campioni;
  - **condizioni difficili**: riflessi sul plexiglass, luce dei frigo, foto mosse, cartellini inclinati
    sul bordo dello scaffale.
- [ ] Rispondere alle **domande aperte** qui sotto (D1 prima di F12.3, le altre prima di F12.4).

### F12.10 — Domande aperte per il proprietario

Decisioni di prodotto che questa specsheet **non** prende da sola. Per ciascuna e' scritta la proposta
con cui si sviluppa se la risposta non arriva prima della sottofase indicata; cambiarla dopo costa poco
(il punto da toccare e' indicato).

- **D1 — Spese oltre le 5 nel gratis: nascoste o cancellate?** (prima di F12.3) Proposta: **nascoste**
  (restano sul telefono, il Pro le mostra tutte, con le statistiche gia' piene: F12.0 punto 5).
  Alternativa «come QR Me»: cancellate davvero dopo la quinta (`SpesaRepository.chiudi` chiama una
  potatura). Punto da toccare: `osservaChiuse` e un metodo `potaChiuse({required int keep})`.
- **D2 — Il tastierino «alla cassa» va bene?** (prima di F12.4) Proposta: `2 4 9` = 2,49 (cifre come
  centesimi, come alla cassa) **e** `2 , 4 9` = 2,49 (virgola facoltativa); conseguenza: `3 +` = **0,03 €**
  (visibile sul display prima del «+»), per 3 € si batte `3 00 +` o `3 , +`. Alternativa «calcolatrice»:
  `3 +` = 3,00 €, `2 4 9` = 249,00 €, la virgola e' obbligatoria per i centesimi. Punto da toccare:
  `TastierinoState.premi` e la sua tabella di test.
- **D3 — Budget mensile?** Non richiesto: in v1 c'e' solo il budget **per spesa** (con un «budget
  abituale» che si precompila). Se servisse anche un tetto del mese, va nelle statistiche Pro.
- **D4 — Prezzo con la carta fedelta' di default?** Proposta: **si'** (interruttore «Ho la carta
  fedelta'» acceso). Nessun campione lo copre ancora: la regola si tara con le foto vere.

**RISPOSTE DEL PROPRIETARIO (2026-10-10) — vincono sulle proposte sopra:**
- **D1 → nascoste**: oltre le 5 le spese restano sul telefono e non si vedono; il Pro le ritrova
  tutte con le statistiche gia' piene. Nessuna potatura.
- **D2 → tastierino «alla cassa»**: `2 4 9` = 2,49, virgola facoltativa, quantita' con `×`
  (`3 × 2 4 9`); `3 +` = 0,03 € (visibile sul display prima del «+»).
- **D3 → budget mensile si', nel Pro**: oltre al budget della singola spesa (gratis), un **budget del
  mese** (speso nel mese / tetto) nelle statistiche Pro. Da aggiungere in F12.1.8 statistiche, F12.1.10
  dati (preferenza o tabella del budget mensile), F12.1.12 schermate (riga nello storico/statistiche e
  impostazione del tetto) e F12.1.14 Pro (`FeatureKey.statistics`).
- **D4 → chiedi ogni volta**: quando il cartellino ha due prezzi (con e senza carta fedelta'), il foglio
  di conferma **mostra entrambi e l'utente sceglie** con un tocco; nessun interruttore «Ho la carta»,
  nessun default. Da riflettere in F12.1.4 (il parser restituisce entrambi i prezzi, marcati) e
  F12.1.12 (foglio di conferma con due bottoni).

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
| DT-SR1 | Spending Review: controllo del totale della bilancia con il codice a barre «a peso variabile» (EAN che inizia per 2, con il prezzo dentro) | Il parser della bilancia ha gia' la verifica peso × €/kg ≈ totale; leggere il codice a barre vorrebbe un secondo decodificatore e i formati cambiano per catena | Se le foto vere (F12.7) mostrano etichette con peso o €/kg illeggibili ma codice nitido |

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

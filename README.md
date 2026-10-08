# MicroApps

Monorepo delle MicroApp Flutter per Android e iPhone, gratuite nella versione base e
sbloccabili con un **acquisto una tantum**, più il server di licenze che verifica gli
acquisti Play e tiene il registro di chi ha comprato cosa. Le app previste sono quattro, ma
il monorepo e' la base per tutte le microapp che verranno.

| Progetto | Cartella | Cos'è | Atlante |
|---|---|---|---|
| **TrashCan** | `apps/trashcan/` | Calendario personale della raccolta differenziata | `apps/trashcan/codebase_reference.md` |
| **Full Freezer** | `apps/full_freezer/` | Inventario del freezer ordinato per anzianità | `apps/full_freezer/codebase_reference.md` |
| **Scorte Calore** | `apps/scorte_calore/` | Autonomia residua di pellet, GPL, gasolio, legna | `apps/scorte_calore/codebase_reference.md` |
| **Film Tracker** | `apps/film_tracker/` | Diario dei rullini fotografici analogici | `apps/film_tracker/codebase_reference.md` |
| **micro_core** | `packages/micro_core/` | Nucleo condiviso: tema, billing, licenze, notifiche, backup | `packages/micro_core/codebase_reference.md` |
| **Vetrina** | `site/` | Il sito pubblico su smpmicroapps.it, in italiano e inglese: catalogo, pagina di TrashCan, contatti, pagine legali | `site/codebase_reference.md` |
| **License Server** | `server/` — **repo separata** | Verifica acquisti Play, registro entitlement, pannello admin | `server/codebase_reference.md` |

> **Stato al 2026-10-08**: esistono e sono aggiornati gli atlanti di `micro_core`, del
> License Server, di TrashCan, della Vetrina, di Full Freezer, di Scorte Calore e di Film Tracker. Gli altri vengono creati alla
> fine della fase che costruisce il rispettivo progetto. Vedi `develop_microapps.md`.

## A che punto siamo

| Fase | Cosa | Stato |
|---|---|---|
| F0 | Fondamenta del monorepo, toolchain Flutter locale al progetto | chiusa |
| F1 | `micro_core`: tema, billing, entitlement, gating, notifiche, backup | chiusa, 107 test |
| F2 | License Server (Node + Fastify + SQLite), repo separata su Gitea | chiusa, 43 test |
| **F3** | **TrashCan**, l'app pilota | **chiusa**, 122 test |
| — | **Vetrina** `smpmicroapps.it` | online, bilingue, con le pagine legali |
| **F4** | **Full Freezer**, Android e iPhone | **completa**, 140 test; App Store in revisione, Play in attesa del D-U-N-S |
| **F5** | **Scorte Calore**, Android e iPhone | **completa**, 158 test; App Store in revisione (2026-10-08), Play dopo il D-U-N-S |
| **F6** | **Film Tracker**, Android e iPhone | **completa**, 185 test; App Store in revisione (2026-10-08), Play dopo il D-U-N-S |
| F7 | Hardening | da fare |
| F8 | Deploy e pubblicazione | da fare |
| F10–F19 | **Dieci app nuove** (Te l'ho prestato, Dove l'ho lasciato?, Quanto sto spendendo?, Quanto dividiamo?, Ricordamelo qui, Quanti sono?, Riassumilo, Fammi un QR, Leggimelo, Dove porta?) | da fare, decise il 2026-10-08 (`develop_microapps.md` §1.6) |

TrashCan e' pubblicata: su App Store in vendita in 148 paesi (l'Unione Europea attende la
verifica DSA di Apple), su Google Play in revisione. Lo stato aggiornato delle build e delle
pubblicazioni sta in [`StatusMicroApps.md`](StatusMicroApps.md).

Full Freezer e' completa nel codice e provata sull'emulatore Android e sul simulatore iPhone:
inserimento rapido, a voce e con foto, riempimento stimato, avvisi, storico e statistiche,
categorie personalizzate, CSV e backup, widget su entrambe le piattaforme. Per pubblicarla
serve che il proprietario crei il prodotto `fullfreezer_pro_lifetime` su Play Console e App
Store Connect e registri App ID e App Group su Apple.

Scorte Calore e' completa nel codice e provata sull'emulatore Android e sul simulatore
iPhone: fonti di calore con conversione delle unita' (anche la percentuale del manometro),
stima del consumo con rilevamento dei rifornimenti, data di riordino, notifiche, storico e
grafici, acquisti e costi per inverno, evento nel calendario del telefono, CSV e backup,
widget su entrambe le piattaforme. Interfaccia «A · Brace»; le grafiche definitive si
scelgono con il proprietario.

Film Tracker e' completa nel codice e provata sull'emulatore Android e sul simulatore iPhone:
rullini con cronologia dal caricamento allo sviluppo e alle stampe, catalogo di pellicole,
macchine, foto dei provini (gratis), foglio provini in archivio, etichetta QR del rullino,
statistiche e costi per anno, PDF di riepilogo, CSV e backup con le foto. Grafica «C · Provino».

## Repository

| Repo | Remote | URL |
|---|---|---|
| Monorepo app | `origin` | `https://git.home.varitest.ovh/smp-webmaster/microapps.git` |
| Monorepo app | `github` | `https://github.com/Frostmoore/smallapps.git` |
| License Server | `origin` | `https://git.home.varitest.ovh/smp-webmaster/microapps-server.git` |

Il **License Server sta in una repo separata, ospitata solo su Gitea**. Su disco vive in
`server/`, dentro questa cartella ma con un proprio `.git`, ed è ignorato dal monorepo. Il
motivo è in `develop_microapps.md`, ADR-001: git pusha commit interi, quindi l'unico modo per
garantire che il server non finisca su GitHub è che non stia nella repo che ci va.

Il branch corrente si pusha su entrambi i remote con `pwsh tool/push_all.ps1`, che si rifiuta
di procedere se trova file del server tracciati nel monorepo.

## Da dove si comincia

Il documento operativo è **[`develop_microapps.md`](develop_microapps.md)**: contiene le
decisioni architetturali, il tracking delle fasi e la guida di sviluppo passo per passo.
Chiunque riprenda il progetto parte da lì, non da questo file.

## Prerequisiti

| Strumento | Versione |
|---|---|
| Flutter | **locale al progetto**, in `.flutter/`, versione in `.flutter-version` |
| JDK | 17 |
| Android SDK | compileSdk 35 |
| Node.js | 22 |

## Toolchain Flutter

Questo progetto **non usa il Flutter di sistema** e non lo aggiorna: altri progetti della
macchina dipendono dalla versione vecchia. La toolchain sta in `.flutter/` (ignorata da git)
e si invoca sempre attraverso il wrapper.

```powershell
# Prima volta, o per cambiare versione
pwsh tool/get_flutter.ps1

# Qualunque comando flutter
pwsh tool/fl.ps1 --version
pwsh tool/fl.ps1 doctor
```

## Comandi

```powershell
# Dipendenze di tutti i progetti Dart
pwsh tool/pub_get_all.ps1

# Analisi statica su tutto
pwsh tool/analyze_all.ps1

# Test
pwsh tool/test_all.ps1
pwsh tool/test_all.ps1 -Project trashcan

# Eseguire un'app in debug (billing finto, nessun server)
pwsh tool/fl.ps1 run -d <device> --dart-define=BILLING=fake

# Eseguire un'app contro il server locale
pwsh tool/fl.ps1 run -d <device> --dart-define=BILLING=fake `
  --dart-define=MA_LICENSE_URL=http://10.0.2.2:8087 `
  --dart-define=MA_APP_SECRET=<segreto di sviluppo>

# Build di release firmato
pwsh tool/build_release.ps1 -App trashcan
```

Il License Server ha una sua repo e i suoi comandi:

```bash
# Prima volta: la cartella server/ e' una repo git a se stante
cd server
npm install
npm run migrate && npm run seed
npm run dev
```

## Versionamento

I branch si chiamano come le versioni, da `v1.0.0` in avanti. Le regole di incremento sono in
`develop_microapps.md`, §5.3.

```powershell
pwsh tool/bump_version.ps1 -Medium -Create   # crea il branch della versione successiva
pwsh tool/push_all.ps1                       # lo pusha su origin e github
```

## Stato

Vedi la sezione §7 di `develop_microapps.md`, che è l'unica fonte di verità sullo stato.

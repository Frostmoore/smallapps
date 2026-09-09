# MicroApps

Monorepo di quattro app Flutter per Android, gratuite nella versione base e sbloccabili con
un **acquisto una tantum**, più il server di licenze che verifica gli acquisti e tiene il
registro di chi ha comprato cosa.

| Progetto | Cartella | Cos'è | Atlante |
|---|---|---|---|
| **TrashCan** | `apps/trashcan/` | Calendario personale della raccolta differenziata | `apps/trashcan/codebase_reference.md` |
| **Full Freezer** | `apps/full_freezer/` | Inventario del freezer ordinato per anzianità | `apps/full_freezer/codebase_reference.md` |
| **Scorte Calore** | `apps/scorte_calore/` | Autonomia residua di pellet, GPL, gasolio, legna | `apps/scorte_calore/codebase_reference.md` |
| **Film Tracker** | `apps/film_tracker/` | Diario dei rullini fotografici analogici | `apps/film_tracker/codebase_reference.md` |
| **micro_core** | `packages/micro_core/` | Nucleo condiviso: tema, billing, licenze, notifiche, backup | `packages/micro_core/codebase_reference.md` |
| **License Server** | `server/` | Verifica acquisti Play, registro entitlement, pannello admin | `server/codebase_reference.md` |

> Gli atlanti elencati sopra **non esistono ancora**: vengono creati alla fine della fase che
> costruisce il rispettivo progetto. Vedi `develop_microapps.md`.

## Da dove si comincia

Il documento operativo è **[`develop_microapps.md`](develop_microapps.md)**: contiene le
decisioni architetturali, il tracking delle fasi e la guida di sviluppo passo per passo.
Chiunque riprenda il progetto parte da lì, non da questo file.

## Prerequisiti

| Strumento | Versione |
|---|---|
| Flutter | vedi `.flutter-version` (stable ≥ 3.35) |
| JDK | 17 |
| Android SDK | compileSdk 35 |
| Node.js | 22 |

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
flutter run -d <device> --dart-define=BILLING=fake

# Eseguire un'app contro il server locale
flutter run -d <device> --dart-define=BILLING=fake `
  --dart-define=MA_LICENSE_URL=http://10.0.2.2:8087 `
  --dart-define=MA_APP_SECRET=<segreto di sviluppo>

# Build di release firmato
pwsh tool/build_release.ps1 -App trashcan
```

```bash
# Server di licenze in locale
cd server
npm install
npm run migrate && npm run seed
npm run dev
```

## Versionamento

I branch si chiamano come le versioni, da `v1.0.0` in avanti. Le regole di incremento sono in
`develop_microapps.md`, §5.3. `tool/bump_version.ps1` calcola la versione successiva.

## Stato

Vedi la sezione §7 di `develop_microapps.md`. Al momento è completata solo la fase F0.1
(struttura del repository e piano di sviluppo).

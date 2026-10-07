# Full Freezer

**Cosa c'è nel freezer, e da quanto tempo.** La seconda MicroApp, per Android e iPhone.

Si apre e si vede subito cosa va usato prima: gli alimenti stanno in ordine di anzianità, il
più vecchio in alto, con i giorni passati dal congelamento. Il freezer si sceglie da una serie
di modelli reali (dal cassetto del frigo al pozzetto da 350 L) e l'app stima quanto spazio
occupa ogni cosa, così mostra quanto è pieno.

| Gratis | Pro (acquisto una tantum, 3,99 €) |
|---|---|
| Un freezer con scomparti; inserimento rapido in 3 tocchi, a voce o con la foto | Freezer multipli |
| Riempimento stimato e regolabile | Avvisi: cose vecchie, freezer quasi pieno o quasi vuoto |
| Ricerca senza accenti, promemoria per categoria | Storico completo e statistiche dello spreco |
| Widget della schermata iniziale | Categorie personalizzate, export CSV, backup completo |
| Ripristino da un backup | |

## Dove guardare

| Cerchi | Dove |
|---|---|
| **Come è fatto il codice**: ogni classe, firma, tabella, rotta, test, trappola | [`codebase_reference.md`](codebase_reference.md) |
| **Perché è fatto così e cosa manca**: specifica, decisioni, tracking | [`../../develop_microapps.md`](../../develop_microapps.md), fase **F4** |
| A che punto sono build e pubblicazioni sugli store | [`../../StatusMicroApps.md`](../../StatusMicroApps.md) |

## Comandi

Dalla cartella `apps/full_freezer`, sempre con la toolchain del progetto:

```powershell
pwsh ../../tool/fl.ps1 test                     # tutti i test
pwsh ../../tool/fl.ps1 analyze                  # analisi statica
python tool/testi.py; pwsh ../../tool/fl.ps1 gen-l10n   # dopo aver cambiato un testo

# APK di debug con 23 alimenti e 6 mesi di storico finti, per provare a mano
pwsh ../../tool/fl.ps1 build apk --debug --dart-define=FF_DEMO=true
```

I testi (italiano e inglese) si scrivono **solo** in `tool/testi.py`: gli `.arb` sono generati.
iOS si compila sul Mac: vedi la sezione iOS dell'atlante.

## Identità

| | |
|---|---|
| Android | `com.smp.fullfreezer` |
| iOS | `com.smp.fullfreezer` (+ `.FullFreezerWidget`), App Group `group.com.smp.fullfreezer` |
| Prodotto Pro | `fullfreezer_pro_lifetime` (non consumabile) |
| Colore | `#0461E5` |

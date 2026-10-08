# Scorte Calore

**Quando devi ricomprare pellet, GPL, gasolio o legna.** La terza MicroApp, per Android e iPhone.

Si apre e si vede subito quanti giorni di riscaldamento restano e entro quando riordinare.
Basta aggiornare ogni tanto la scorta (sacchi, litri, la percentuale del manometro del
bombolone): l'app impara il consumo dalle misure, riconosce da sola i rifornimenti e stima
la data in cui finisce.

| Gratis | Pro (acquisto una tantum, 2,99 €) |
|---|---|
| Una fonte di calore | Tutte le fonti (stufa e bombolone, casa e casa al mare) |
| Giorni di autonomia, consumo medio, data di riordino | Notifiche: il giorno del riordino e se la data passa |
| Ultimi 90 giorni di misure | Storico completo e grafici |
| Widget della schermata iniziale | Acquisti e costi: spesa per inverno, prezzo medio |
| Ripristino da un backup | Data di riordino nel calendario del telefono |
| | Export CSV e backup completo |

## Dove guardare

| Cerchi | Dove |
|---|---|
| **Come è fatto il codice**: ogni classe, firma, tabella, rotta, test, trappola | [`codebase_reference.md`](codebase_reference.md) |
| **Perché è fatto così e cosa manca**: specifica, decisioni, tracking | [`../../develop_microapps.md`](../../develop_microapps.md), fase **F5** |
| A che punto sono build e pubblicazioni sugli store | [`../../StatusMicroApps.md`](../../StatusMicroApps.md) |

## Comandi

Dalla cartella `apps/scorte_calore`, sempre con la toolchain del progetto:

```powershell
pwsh ../../tool/fl.ps1 test                     # tutti i test
pwsh ../../tool/fl.ps1 analyze                  # analisi statica
python tool/testi.py; pwsh ../../tool/fl.ps1 gen-l10n   # dopo aver cambiato un testo

# APK di debug con due fonti e due mesi di misure finte, per provare a mano
pwsh ../../tool/fl.ps1 build apk --debug --dart-define=SC_DEMO=true
```

I testi (italiano e inglese) si scrivono **solo** in `tool/testi.py` e nei `tool/testi_*.py`:
gli `.arb` sono generati. iOS si compila sul Mac: vedi la sezione iOS dell'atlante.

## Identità

| | |
|---|---|
| Android | `com.smp.scortecalore` |
| iOS | `com.smp.scortecalore` (+ `.ScorteCaloreWidget`), App Group `group.com.smp.scortecalore` |
| Prodotto Pro | `scortecalore_pro_lifetime` (non consumabile) |
| Colore | `#F4511E`, grafica «A · Brace» (testata blu notte, giorni in arancio) |

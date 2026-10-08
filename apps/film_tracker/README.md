# Film Tracker

**Il diario dei tuoi rullini analogici.** La quarta MicroApp, per Android e iPhone.

Ogni rullino caricato in macchina diventa una scheda che lo segue fino al laboratorio e
nell'archivio: pellicola, macchina, ISO, date, sviluppo, stampe e costi, in una cronologia.
L'archivio e' un foglio provini con le foto dei provini, delle stampe o delle scansioni, e
ogni rullino ha un'etichetta QR da attaccare al contenitore.

| Gratis | Pro (acquisto una tantum, 4,99 €) |
|---|---|
| Rullini illimitati, una macchina fotografica | Tutte le tue macchine |
| Catalogo di 25 pellicole e pellicole personalizzate | Statistiche e costi per anno |
| Sviluppo e stampe, con i costi | Il riepilogo dell'anno in PDF, da stampare |
| Tutte le foto: provini, stampe, scansioni, copertina | Export in un foglio di calcolo (CSV) |
| L'etichetta QR del rullino | Backup completo, foto comprese |
| Ripristino da un backup | |

## Dove guardare

| Cerchi | Dove |
|---|---|
| **Come è fatto il codice**: ogni classe, firma, tabella, rotta, test, trappola | [`codebase_reference.md`](codebase_reference.md) |
| **Perché è fatto così e cosa manca**: specifica, decisioni, tracking | [`../../develop_microapps.md`](../../develop_microapps.md), fase **F6** |
| A che punto sono build e pubblicazioni sugli store | [`../../StatusMicroApps.md`](../../StatusMicroApps.md) |

## Comandi

Dalla cartella `apps/film_tracker`, sempre con la toolchain del progetto:

```powershell
pwsh ../../tool/fl.ps1 test                     # tutti i test
pwsh ../../tool/fl.ps1 analyze                  # analisi statica
python tool/testi.py; pwsh ../../tool/fl.ps1 gen-l10n   # dopo aver cambiato un testo
pwsh ../../tool/fl.ps1 pub run build_runner build       # dopo aver cambiato le tabelle

# APK di debug con 3 macchine, 12 rullini e le foto dell'archivio finti, per provare a mano
pwsh ../../tool/fl.ps1 build apk --debug --dart-define=FT_DEMO=true
```

I testi (italiano e inglese) si scrivono **solo** in `tool/testi.py` e nei `tool/testi_*.py`:
gli `.arb` sono generati. iOS si compila sul Mac: vedi la sezione iOS dell'atlante.

## Identità

| | |
|---|---|
| Android | `com.smp.filmtracker` |
| iOS | `com.smp.filmtracker` (niente widget, niente App Group) |
| Prodotto Pro | `filmtracker_pro_lifetime` (non consumabile) |
| Grafica | «C · Provino»: nero pellicola `#0D0C0B`, scritte a bordo in arancio `#F0A33B` con Space Mono |
| Link del QR | `filmtracker://roll/<numero del rullino>` |

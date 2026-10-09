# QR Me

Condividi qualunque cosa e diventa un QR a tutto schermo, luminoso; e sa anche leggerli.
Android e iPhone. Specsheet: `develop_microapps.md`, sezione «F17 — QR Me».

Stato: bootstrap (F17.2c) e dominio/dati con i test (F17.3). Le schermate (F17.4) sono ancora
segnaposto; la ricezione da Share Sheet arriva con `packages/micro_share` (F17.2b).

Comandi (dalla cartella dell'app, sempre con la toolchain del progetto):

```
pwsh ../../tool/fl.ps1 analyze
pwsh ../../tool/fl.ps1 test
pwsh ../../tool/fl.ps1 pub run build_runner build      # dopo ogni modifica a lib/data/
python tool/testi.py && pwsh ../../tool/fl.ps1 gen-l10n # dopo ogni modifica ai testi
python tool/genera_icone.py                             # poi flutter_launcher_icons e flutter_native_splash
```

# QR Me

Condividi qualunque cosa e diventa un QR a tutto schermo, luminoso; e sa anche leggerli.
Android e iPhone. Specsheet: `develop_microapps.md`, sezione «F17 — QR Me».

Stato: bootstrap (F17.2c), dominio/dati (F17.3), interfaccia essenziale con la grafica «A · Neon»
(F17.4 + F17.6, colori in `lib/app/qr_palette.dart`) e limiti Pro (F17.5). La condivisione verso
l'app passa da `packages/micro_share` (`ShareIntake` in `lib/services/share_router.dart`).

Comandi (dalla cartella dell'app, sempre con la toolchain del progetto):

```
pwsh ../../tool/fl.ps1 analyze
pwsh ../../tool/fl.ps1 test
pwsh ../../tool/fl.ps1 pub run build_runner build      # dopo ogni modifica a lib/data/
python tool/testi.py && pwsh ../../tool/fl.ps1 gen-l10n # dopo ogni modifica ai testi
python tool/genera_icone.py                             # poi flutter_launcher_icons e flutter_native_splash
```

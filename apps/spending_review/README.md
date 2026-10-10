# Spending Review

Il conto della spesa con una mano sola: batti il prezzo (o inquadra il cartellino) e il totale enorme
in alto sale subito, con la barra del budget. Cartellini, etichette della bilancia e scontrini letti
**sul telefono** (`packages/micro_ocr`). Android e iPhone. Specsheet: `develop_microapps.md`, sezione
«F12 — Spending Review».

Stato: bootstrap (F12.2c) e dominio/dati con il banco di regressione del parser (F12.3). L'interfaccia
«C · Una mano» arriva con F12.4: oggi `/` mostra solo il totale della spesa in corso.

Comandi (dalla cartella dell'app, sempre con la toolchain del progetto):

```
pwsh ../../tool/fl.ps1 analyze
pwsh ../../tool/fl.ps1 test
pwsh ../../tool/fl.ps1 pub run build_runner build                                  # dopo ogni modifica a lib/data/
pwsh ../../tool/fl.ps1 pub run drift_dev schema dump lib/data/database.dart drift_schemas/   # a ogni nuova versione dello schema
python tool/testi.py && pwsh ../../tool/fl.ps1 gen-l10n                            # dopo ogni modifica ai testi
python tool/genera_icone.py                                                        # poi flutter_launcher_icons e flutter_native_splash
```

Banco del parser (`test/domain/banco_parser_test.dart`): gira sulle fixture di testo OCR dei 33
campioni a licenza libera (`test/fixtures/ocr/`, attribuzioni in `LICENZE.md`). Con
`SR_CAMPIONI=E:/coding/XAMPP/htdocs/microapps-campioni/f12/fixture` legge anche le 27 private (fuori
dal repo). Le fixture si rigenerano con `tool/esporta_fixture_ocr.py` (vedi la sua intestazione); se
un numero del banco sale, si aggiorna a mano `test/fixtures/ocr/soglie.json` nello stesso commit.

☠ La release Android passa dal task Gradle `verificaPrivacyOcr` (`android/app/build.gradle.kts`): fallisce
se ONNX Runtime non e' 1.28.0, se compare la telemetria di ORT o se INTERNET arriva da una fonte che
non sia Play Billing.

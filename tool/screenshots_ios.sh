#!/bin/bash
#
# Screenshot di un'app per l'App Store, su un simulatore iOS.
#
#   ssh mac 'bash ~/microapps/tool/screenshots_ios.sh <UDID> <it|en> <cartella> [app]'
#
# [app] e' la cartella in apps/ (predefinita: trashcan). Per full_freezer, scorte_calore e
# film_tracker si aggiungono da soli FF_DEMO / SC_DEMO / FT_DEMO=true, cioe' i dati di esempio.
#
# Gira `integration_test/screenshots_test.dart` e fotografa lo schermo ogni volta che il
# test scrive `SCATTO:<nome>`. Vedi l'intestazione del test per il perche' lo scatto lo
# fa questo script e non il test.
#
# ⚑ Il simulatore va scelto per la misura che App Store Connect pretende: le schermate
#   da 6,9 pollici (1320x2868) sono obbligatorie, e da quelle Apple ricava da sola le
#   misure piu' piccole. L'iPhone 18 Pro Max le produce gia' giuste.

set -euo pipefail

UDID="${1:?manca l UDID del simulatore}"
LINGUA="${2:?manca la lingua, it o en}"
USCITA="${3:?manca la cartella di uscita}"
APP="${4:-trashcan}"
EXTRA=()
[ "$APP" = "full_freezer" ] && EXTRA=(--dart-define=FF_DEMO=true)
[ "$APP" = "scorte_calore" ] && EXTRA=(--dart-define=SC_DEMO=true)
[ "$APP" = "film_tracker" ] && EXTRA=(--dart-define=FT_DEMO=true)

export PATH="$HOME/microapps-toolchain/flutter/bin:/opt/homebrew/bin:$PATH"
export LANG=en_US.UTF-8
mkdir -p "$USCITA"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null

# ⚑ La barra di stato in posa: 9:41, batteria piena, segnale pieno. Non e' vanita': una
#   scheda con il telefono al 12% e le 23:47 distrae da quello che deve mostrare, e
#   l'ora reale cambia da uno scatto all'altro.
xcrun simctl status_bar "$UDID" override \
  --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100

cd "$HOME/microapps/apps/$APP"
REGISTRO=$(mktemp -t scatti)
flutter test integration_test/screenshots_test.dart -d "$UDID" \
  --dart-define=LINGUA="$LINGUA" "${EXTRA[@]}" > "$REGISTRO" 2>&1 &
TEST=$!

FATTI=" "
while kill -0 "$TEST" 2>/dev/null; do
  for nome in $(grep -o 'SCATTO:[a-z-]*' "$REGISTRO" | cut -d: -f2); do
    case "$FATTI" in *" $nome "*) continue ;; esac
    sleep 1
    xcrun simctl io "$UDID" screenshot "$USCITA/$nome.png" >/dev/null 2>&1
    FATTI="$FATTI$nome "
    echo "scattata $nome"
  done
  sleep 0.5
done

if ! wait "$TEST"; then
  echo "il test e' fallito:" >&2
  tail -40 "$REGISTRO" >&2
  exit 1
fi
xcrun simctl status_bar "$UDID" clear
echo "fatto: $(echo $FATTI | wc -w | tr -d ' ') schermate in $USCITA"

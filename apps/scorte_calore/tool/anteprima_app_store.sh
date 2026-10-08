#!/bin/bash
#
# Registra il video grezzo per l'anteprima dell'App Store, su un simulatore iOS.
#
#   ssh mac 'bash ~/microapps/apps/scorte_calore/tool/anteprima_app_store.sh <UDID> <it|en>'
#
# Scrive ~/anteprima_sc_<lingua>.mov. La conversione nel formato di Apple (886x1920, 30 fps,
# H.264, traccia audio stereo muta) la fa tool/converti_anteprima.ps1 sul PC, dove c'e' ffmpeg.
#
# Gira integration_test/anteprima_test.dart con i dati di esempio e registra lo schermo
# fra le righe REGISTRA e FINE che il test stampa: prima di REGISTRA il test sblocca il Pro,
# fuori dall'inquadratura.

set -euo pipefail

UDID="${1:?manca l UDID del simulatore}"
LINGUA="${2:?manca la lingua, it o en}"
USCITA="$HOME/anteprima_sc_$LINGUA.mov"

export PATH="$HOME/microapps-toolchain/flutter/bin:/opt/homebrew/bin:$PATH"
export LANG=en_US.UTF-8

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl status_bar "$UDID" override \
  --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100

cd "$HOME/microapps/apps/scorte_calore"
REGISTRO=$(mktemp -t anteprima)
flutter test integration_test/anteprima_test.dart -d "$UDID" \
  --dart-define=LINGUA="$LINGUA" --dart-define=SC_DEMO=true > "$REGISTRO" 2>&1 &
TEST=$!

until grep -q REGISTRA "$REGISTRO"; do
  kill -0 "$TEST" 2>/dev/null || { tail -40 "$REGISTRO" >&2; exit 1; }
  sleep 0.2
done
rm -f "$USCITA"
xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$USCITA" >/dev/null 2>&1 &
VIDEO=$!
until grep -q FINE "$REGISTRO"; do
  kill -0 "$TEST" 2>/dev/null || break
  sleep 0.2
done
kill -INT "$VIDEO"
wait "$VIDEO" || true
wait "$TEST" || { tail -40 "$REGISTRO" >&2; exit 1; }
xcrun simctl status_bar "$UDID" clear
echo "fatto: $USCITA"

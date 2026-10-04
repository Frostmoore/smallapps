#!/bin/bash
#
# Costruisce TrashCan per iOS e la carica su TestFlight.
#
# Gira **sul Mac**, non su Windows: Xcode non esiste altrove.
#   ssh mac 'bash ~/microapps/tool/build_ios.sh'
#
# ☠ Non chiede mai una password e non apre mai Xcode. Firma e caricamento passano da una
#   chiave API di App Store Connect, che e' l'unico modo di fare tutto questo da una
#   sessione ssh. Con l'Apple ID dentro Xcode servirebbe qualcuno davanti allo schermo a
#   ogni rinnovo del certificato.
#
# ☠ I tre identificativi NON stanno nel repo. Vivono in ~/.microapps-ios.env sul Mac, che
#   e' fuori da git. Il file .p8 e' una chiave privata: chi ce l'ha puo' caricare build a
#   nome del titolare dell'account. Non si committa, non si copia altrove, non si incolla
#   in chat.
#
# Il file ~/.microapps-ios.env deve contenere:
#   ASC_KEY_ID=XXXXXXXXXX          # l'id della chiave API
#   ASC_ISSUER_ID=xxxxxxxx-....    # l'issuer, uguale per tutte le chiavi dell'account
#   ASC_TEAM_ID=XXXXXXXXXX         # il Team ID, da Membership nel portale sviluppatori
#
# e la chiave deve stare in:
#   ~/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8

set -euo pipefail

APP="${1:-trashcan}"
RADICE="$HOME/microapps"
CARTELLA="$RADICE/apps/$APP"

export PATH="$HOME/microapps-toolchain/flutter/bin:/opt/homebrew/bin:$PATH"
export LANG=en_US.UTF-8

# ── Le credenziali, da fuori dal repo ───────────────────────────────────────
if [ ! -f "$HOME/.microapps-ios.env" ]; then
  echo "Manca ~/.microapps-ios.env. Vedi l'intestazione di questo script." >&2
  exit 1
fi
# shellcheck disable=SC1091
source "$HOME/.microapps-ios.env"

CHIAVE="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
if [ ! -f "$CHIAVE" ]; then
  echo "Manca la chiave API in $CHIAVE" >&2
  exit 1
fi

FIRMA=(-allowProvisioningUpdates
       -authenticationKeyPath "$CHIAVE"
       -authenticationKeyID "$ASC_KEY_ID"
       -authenticationKeyIssuerID "$ASC_ISSUER_ID")

cd "$CARTELLA"

# ── Il numero di build ──────────────────────────────────────────────────────
#
# ☠ Apple rifiuta una build con un numero gia' visto per quella versione, e quel numero
#   non si libera piu': vale la stessa regola del versionCode di Play. Lo si legge dal
#   pubspec, che e' l'unica fonte, cosi' Android e iOS non divergono.
VERSIONE=$(grep -m1 '^version:' pubspec.yaml | sed 's/version: *//')
echo "==> $APP $VERSIONE"

# ── L'archivio ──────────────────────────────────────────────────────────────
#
# ⚑ Prima `flutter build ios --no-codesign` e poi `xcodebuild archive` a mano, invece del
#   piu' corto `flutter build ipa`: quest'ultimo non sa passare la chiave API a xcodebuild,
#   quindi la firma automatica fallirebbe chiedendo un Apple ID che in ssh non c'e'.
echo "==> compilo"
flutter build ios --release --no-codesign --dart-define=BILLING=store

echo "==> archivio e firmo"
rm -rf build/ios/archive
xcodebuild archive \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/archive/Runner.xcarchive \
  -destination 'generic/platform=iOS' \
  DEVELOPMENT_TEAM="$ASC_TEAM_ID" \
  "${FIRMA[@]}" \
  | tail -5

echo "==> esporto l'ipa"
rm -rf build/ios/ipa
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath build/ios/ipa \
  "${FIRMA[@]}" \
  | tail -5

IPA=$(ls build/ios/ipa/*.ipa | head -1)
echo "==> $IPA"

# ── Il caricamento ──────────────────────────────────────────────────────────
#
# ⚑ `altool --validate-app` prima di caricare: il caricamento vero impiega minuti, e un
#   errore di icona o di permessi mancanti lo si scopre altrimenti solo alla fine.
echo "==> verifico"
xcrun altool --validate-app -f "$IPA" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" 2>&1 | tail -5

echo "==> carico su App Store Connect"
xcrun altool --upload-app -f "$IPA" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" 2>&1 | tail -5

echo
echo "Caricata. Su TestFlight compare fra dieci e trenta minuti, dopo l'elaborazione."
echo "I tester interni la vedono senza nessuna revisione di Apple."

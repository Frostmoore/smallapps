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

# ☠ **L'archivio si fa SENZA firma, e non e' una scorciatoia.**
#
# `xcodebuild archive` con la firma automatica pretende un profilo di **sviluppo**, anche
# quando la configurazione e' Release e la destinazione e' un dispositivo generico: firma
# con l'identita' di sviluppo e conta di rifirmare in esportazione. Apple pero' non rilascia
# un profilo di sviluppo a un team che non ha **nessun dispositivo registrato**, e questo non
# ne ha: l'errore parla di profili mancanti e manda a cercare il guasto nel progetto, mentre
# la causa e' un elenco vuoto dall'altra parte dell'oceano.
#
# Archiviando senza firma quel requisito sparisce. A firmare e' il passo di esportazione qui
# sotto, che chiede un profilo di **distribuzione**: quello Apple lo rilascia senza pretendere
# dispositivi, perche' una build per lo store non deve girare su un telefono scelto prima.
#
# ⚑ Conseguenza utile: per arrivare su TestFlight non serve registrare nessun dispositivo
#   ne' collegare niente via cavo. Servono solo per installare direttamente dal Mac.
echo "==> archivio, senza firmare"
rm -rf build/ios/archive
xcodebuild archive \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/archive/Runner.xcarchive \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="$ASC_TEAM_ID" \
  | tail -5

# ☠ Il Team ID va messo nelle opzioni di esportazione, e si aggiunge **qui**, non nel file
#   versionato: archiviando senza firma il team non finisce nei metadati dell'archivio, e
#   `exportArchive` si ferma con "No Team Found in Archive". Sembra un difetto del progetto
#   ed e' solo un dato che nessuno gli ha passato. Nel repo il Team ID non ci va, quindi si
#   lavora su una copia temporanea che sparisce a fine script.
echo "==> esporto e firmo per lo store"
rm -rf build/ios/ipa
OPZIONI=$(mktemp -t ExportOptions)
trap 'rm -f "$OPZIONI"' EXIT
cp ios/ExportOptions.plist "$OPZIONI"
/usr/libexec/PlistBuddy -c "Add :teamID string $ASC_TEAM_ID" "$OPZIONI"

xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist "$OPZIONI" \
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

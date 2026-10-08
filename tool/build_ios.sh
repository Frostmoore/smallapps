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

# ☠ **I diritti vanno incisi a mano nell'archivio, prima dell'esportazione.**
#
#   L'archivio senza firma non porta nessun diritto. In esportazione Xcode decide quale
#   profilo chiedere ad Apple guardando i diritti dei binari, e non trovandone nessuno
#   chiede un profilo base: niente gruppo condiviso. La build passa, si carica, e sul
#   telefono app e widget non vedono lo stesso contenitore, quindi il widget resta senza
#   dati. Abilitare App Groups sull'App ID non basta, perche' Xcode non sa di doverlo
#   chiedere. Verificato il 2026-10-05: il gruppo mancava sia nei binari sia nei profili.
#
#   La firma provvisoria (`-s -`) non ha bisogno di profili e non vale per installare
#   niente: serve solo a scrivere i diritti dove l'esportazione li va a leggere. Poi
#   l'esportazione rifirma tutto per lo store, stavolta col profilo giusto.
#
# ⚑ Prima i framework, poi le estensioni, poi l'app: codesign rifiuta di firmare un
#   pacchetto che contiene codice non firmato.
echo "==> incido i diritti nell'archivio"
APP_ARCHIVIATA=build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app
for f in "$APP_ARCHIVIATA"/Frameworks/*; do
  codesign -f -s - "$f" 2>/dev/null
done
for est in "$APP_ARCHIVIATA"/PlugIns/*.appex; do
  [ -e "$est" ] || continue
  nome_est=$(basename "$est" .appex)
  codesign -f -s - --entitlements "ios/$nome_est/$nome_est.entitlements" "$est"
done
codesign -f -s - --entitlements ios/Runner/Runner.entitlements "$APP_ARCHIVIATA"

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

# ── Firma con i nostri profili, quando ci sono ──────────────────────────────
#
# ☠ **Xcode 27 non crea piu' i profili nuovi con la chiave API** (visto il 2026-10-07 con
#   Full Freezer): "Authentication failed" e "No profiles were found", mentre la stessa
#   chiave crea profili via API senza problemi e TrashCan, che i profili li aveva gia', si
#   esporta ancora. Per un'app nuova quindi i profili si fanno a parte, via API, con un
#   certificato "Apple Distribution" nostro:
#     - chiave privata e certificato in ~/.microapps-firma/ (solo su questo Mac);
#     - un portachiavi dedicato, ~/Library/Keychains/microapps-firma.keychain-db, con la
#       password casuale in ~/.microapps-firma/portachiavi.pwd: da ssh il portachiavi di
#       login e' chiuso, questo lo si apre da qui senza la password dell'utente;
#     - profili App Store chiamati "MicroApps AppStore <bundle>", uno per l'app e uno per
#       ogni estensione. Procedura in apps/full_freezer/codebase_reference.md, sezione iOS.
#
# ☠ I profili prendono l'App Group **dall'App ID**: se il gruppo non e' agganciato all'App
#   ID nel portale (Identifiers > App Groups > Configure), il profilo ha l'elenco vuoto e la
#   firma fallisce. L'API non sa agganciarlo: si fa a mano, una volta per App ID.
PROFILI="$HOME/Library/MobileDevice/Provisioning Profiles"
PORTACHIAVI="$HOME/Library/Keychains/microapps-firma.keychain-db"
ARCH_APP=build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app
ID_APP=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$ARCH_APP/Info.plist")
profilo_per() { grep -l -a "<string>MicroApps AppStore $1</string>" "$PROFILI"/*.mobileprovision 2>/dev/null | head -1; }
if [ -f "$PORTACHIAVI" ] && [ -n "$(profilo_per "$ID_APP")" ]; then
  echo "==> firma con i profili MicroApps (certificato nostro)"
  security unlock-keychain -p "$(cat "$HOME/.microapps-firma/portachiavi.pwd")" "$PORTACHIAVI"
  /usr/libexec/PlistBuddy -c "Set :signingStyle manual" "$OPZIONI"
  /usr/libexec/PlistBuddy -c "Add :signingCertificate string Apple Distribution" "$OPZIONI"
  /usr/libexec/PlistBuddy -c "Add :provisioningProfiles dict" "$OPZIONI"
  for bundle in "$ARCH_APP" "$ARCH_APP"/PlugIns/*.appex; do
    [ -e "$bundle" ] || continue
    ident=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$bundle/Info.plist")
    if [ -z "$(profilo_per "$ident")" ]; then
      echo "!! manca il profilo 'MicroApps AppStore $ident'" >&2
      exit 1
    fi
    /usr/libexec/PlistBuddy -c "Add :provisioningProfiles:$ident string MicroApps AppStore $ident" "$OPZIONI"
  done
fi

xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist "$OPZIONI" \
  -exportPath build/ios/ipa \
  "${FIRMA[@]}" \
  | tail -5

IPA=$(ls build/ios/ipa/*.ipa | head -1)
echo "==> $IPA"

# ── Il controllo che il gruppo ci sia davvero ───────────────────────────────
#
# ☠ Senza questo controllo la build 1.0.0+6 e' arrivata su TestFlight con un widget che
#   non poteva leggere niente, e nessun passo dello script se n'era accorto: firma,
#   validazione e caricamento erano tutti verdi. Il gruppo mancante non e' un errore per
#   Apple, e' una configurazione legittima. Quindi lo si controlla qui, e se manca ci si
#   ferma prima di caricare.
if [ -f ios/Runner/Runner.entitlements ]; then
  GRUPPO=$(/usr/libexec/PlistBuddy -c "Print :com.apple.security.application-groups:0" \
    ios/Runner/Runner.entitlements 2>/dev/null || true)
  if [ -n "$GRUPPO" ]; then
    CONTROLLO=$(mktemp -d)
    unzip -q "$IPA" -d "$CONTROLLO"
    for bin in "$CONTROLLO"/Payload/*.app "$CONTROLLO"/Payload/*.app/PlugIns/*.appex; do
      [ -e "$bin" ] || continue
      if ! codesign -d --entitlements :- "$bin" 2>/dev/null | grep -q "$GRUPPO"; then
        echo "!! $GRUPPO manca nella firma di $(basename "$bin"): non carico." >&2
        rm -rf "$CONTROLLO"
        exit 1
      fi
    done
    rm -rf "$CONTROLLO"
    echo "==> $GRUPPO firmato in app ed estensioni"
  fi
fi

if [ -n "${SOLO_ESPORTA:-}" ]; then
  echo "SOLO_ESPORTA: mi fermo prima del caricamento."
  exit 0
fi

# ── Il caricamento ──────────────────────────────────────────────────────────
#
# ⚑ `altool --validate-app` prima di caricare: il caricamento vero impiega minuti, e un
#   errore di icona o di permessi mancanti lo si scopre altrimenti solo alla fine.
echo "==> verifico"
xcrun altool --validate-app -f "$IPA" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" 2>&1 | tail -5

echo "==> carico su App Store Connect"
# ☠ altool ogni tanto si ferma con "The file Defaults.properties couldn't be opened" (visto
#   con Scorte Calore il 2026-10-08) e al giro dopo carica senza problemi: si riprova.
for prova in 1 2 3; do
  ESITO=$(xcrun altool --upload-app -f "$IPA" -t ios \
    --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" 2>&1 | tail -5)
  echo "$ESITO"
  echo "$ESITO" | grep -q "UPLOAD SUCCEEDED" && break
  [ "$prova" = 3 ] && { echo "!! caricamento fallito tre volte" >&2; exit 1; }
  echo "==> riprovo il caricamento ($prova)"
  sleep 10
done

echo
echo "Caricata. Su TestFlight compare fra dieci e trenta minuti, dopo l'elaborazione."
echo "I tester interni la vedono senza nessuna revisione di Apple."

# codebase_reference.md — `micro_share`

> Atlante del package che riceve le condivisioni dallo Share Sheet (Android `ACTION_SEND`,
> iOS Share Extension) per le MicroApps che le accettano: F16, **F17 QR Me**, F18, F19.
> **Obiettivo**: capire il codice, trovare ciò che serve e modificarlo **senza aprire i
> file**. Se per sapere che firma ha un metodo bisogna leggere il sorgente, ha fallito.
>
> **Aggiornato al**: 2026-10-09 · **Sottofase F17.2b** · **Toolchain**: Flutter del progetto
> (`.flutter/`, via `pwsh tool/fl.ps1`), Dart ^3.13
> **Test**: 20 verdi · **Analisi statica**: nessuna issue
> **Plugin sotto**: `receive_sharing_intent` **1.9.0** (vincolo `^1.9.0`)

---

## 1. Dove sta cosa

| Cerchi… | Vai in |
|---|---|
| La superficie pubblica | `lib/micro_share.dart` (barrel) |
| Cosa può arrivare da una condivisione | `lib/src/shared_payload.dart` → `SharedPayload`, `SharedText`, `SharedImage` |
| L'interfaccia che le app usano | `lib/src/share_inbox.dart` → `ShareInbox` |
| La finta per i test delle app | `lib/src/share_inbox.dart` → `FakeShareInbox` |
| L'implementazione vera sul plugin | `lib/src/rsi_share_inbox.dart` → `RsiShareInbox` |
| Come un `SharedMediaFile` diventa un `SharedPayload` | `lib/src/rsi_share_inbox.dart` → `payloadsFromMedia` |
| Il controller Swift dell'estensione iOS | `ios_template/ShareViewController.swift` |
| Le regole di attivazione dell'estensione iOS | `ios_template/Info.plist` |
| Come si aggiunge l'estensione a un'app iOS | `tool/aggiungi_share_extension_ios.rb` (radice del monorepo), §6 |
| Cosa va messo nell'app Android | §7 |
| Cosa dimostrano i test | §9 |
| Cosa **non** esiste ancora | §10 |

---

## 2. Albero dei file

```
packages/micro_share/
├─ pubspec.yaml                    receive_sharing_intent ^1.9.0; dev: flutter_lints ^5.0.0, flutter_test
├─ pubspec.lock                    tracciato, come quello di micro_core
├─ analysis_options.yaml           include: ../../analysis_options.yaml (copia di micro_core)
├─ codebase_reference.md           questo file
├─ lib/
│  ├─ micro_share.dart             BARREL: l'unica cosa che le app importano
│  └─ src/
│     ├─ shared_payload.dart       SharedPayload (sealed), SharedText, SharedImage — Dart puro
│     ├─ share_inbox.dart          ShareInbox (interfaccia), FakeShareInbox
│     └─ rsi_share_inbox.dart      RsiShareInbox, payloadsFromMedia (+ _text privata)
├─ ios_template/                   NON e' codice del package: modelli che lo script copia nelle app
│  ├─ ShareViewController.swift    class ShareViewController: RSIShareViewController
│  └─ Info.plist                   Info.plist dell'estensione
└─ test/
   └─ shared_payload_test.dart     20 test
```

Fuori dal package ma parte dello stesso lavoro:

```
tool/aggiungi_share_extension_ios.rb   crea/riallinea il target ShareExtension in apps/<app>/ios
```

**Regola del barrel**: le app importano solo `package:micro_share/micro_share.dart`. Mai
`package:micro_share/src/...`. Il barrel esporta: `RsiShareInbox`, `payloadsFromMedia`,
`FakeShareInbox`, `ShareInbox`, `SharedImage`, `SharedPayload`, `SharedText`. **Non**
riesporta niente di `receive_sharing_intent`: le app non devono vederlo.

---

## 3. Dipendenze

| Pacchetto | Vincolo | Risolto | A cosa serve |
|---|---|---|---|
| `flutter` | sdk | — | richiesto dal plugin |
| `receive_sharing_intent` | `^1.9.0` | 1.9.0 | il plugin nativo: Android legge l'intent, iOS legge l'App Group riempito dall'estensione |
| `flutter_lints` (dev) | `^5.0.0` | 5.0.0 | come `micro_core` |
| `flutter_test` (dev) | sdk | — | test |

⚑ **Niente `micro_core`**: il package non ne ha bisogno, e restare indipendente evita cicli
e lo tiene testabile da solo.

### Cosa è stato verificato nel sorgente del plugin (pub cache, 1.9.0)

| Fatto | Dove nel plugin |
|---|---|
| `class SharedMediaFile { String path; String? thumbnail; int? duration; SharedMediaType type; String? mimeType; String? message; }`, costruttore con `required path`, `required type` | `lib/src/data/shared_media_file.dart` |
| `enum SharedMediaType { image, video, text, file, url }` con `value` = `'image'`, `'video'`, `'text'`, `'file'`, `'url'` | idem |
| Per `text` e `url`, `path` contiene **il testo o l'URL**, non un percorso. iOS: `url.absoluteString`; Android: `EXTRA_TEXT` | `RSIShareViewController.swift` (`handleMedia(forLiteral:)`), `ReceiveSharingIntentPlugin.kt` (`toJsonObject`) |
| Android non produce **mai** `url` da `ACTION_SEND`: un link condiviso da Chrome arriva come `text` (`text/plain`). `url` lo produce solo `ACTION_VIEW` | `ReceiveSharingIntentPlugin.kt` (`MediaType.fromMimeType`) |
| `ReceiveSharingIntent.instance.getInitialMedia()` → `Future<List<SharedMediaFile>>`, `getMediaStream()` → `Stream<List<SharedMediaFile>>` broadcast, `reset()` → `Future<dynamic>` | `lib/receive_sharing_intent.dart`, `lib/src/receive_sharing_intent_mobile.dart` |
| `ReceiveSharingIntent.setMockValues(initialMedia:, mediaStream:)` sostituisce l'istanza statica; il suo `reset()` svuota `initialMedia` | `lib/receive_sharing_intent.dart` |
| iOS: modulo Swift **`receive_sharing_intent`**, prodotto SPM **`receive-sharing-intent`**, classe **`open class RSIShareViewController: UIViewController`**, metodo `open func shouldAutoRedirect() -> Bool` (default `true`) | `ios/receive_sharing_intent/Package.swift`, `Sources/receive_sharing_intent/RSIShareViewController.swift` |
| iOS: distribuito **solo** come pacchetto Swift (nessun podspec); iOS minimo 13.0 | `Package.swift`, README |
| iOS: chiave Info.plist `AppGroupId` (`kAppGroupIdKey`); se manca usa `group.<bundle app>`; schema `ShareMedia-<bundle app>:share` (`kSchemePrefix = "ShareMedia"`) | `ReceiveSharingIntentPlugin.swift`, `RSIShareViewController.swift` (`loadIds`, `redirectToHostApp`) |
| iOS: il bundle dell'app si ricava da quello dell'estensione togliendo l'ultimo pezzo dopo il punto | `RSIShareViewController.swift` (`loadIds`) |
| iOS: `RSIShareViewController` non usa storyboard (crea la sua vista); con `shouldAutoRedirect() == true` non mostra niente | idem, README «Auto-redirect vs. the built-in compose UI» |

---

## 4. `shared_payload.dart` — Dart puro

### `sealed class SharedPayload`

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `const SharedPayload()` | solo per le sottoclassi |

Sigillata: uno `switch (p) { SharedText(:final text) => …, SharedImage(:final path) => … }` è
esaustivo, e il giorno in cui si aggiunge un terzo caso il compilatore lo segnala in ogni app.

### `final class SharedText extends SharedPayload`

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `const SharedText(String text)` | |
| campo | `final String text` | testo **o link** (un URL condiviso arriva come testo). Da `payloadsFromMedia`: già `trim()`, mai vuoto |
| `==` | `bool operator ==(Object other)` | uguale se `other is SharedText` e stesso `text` |
| `hashCode` | `int get hashCode` | `Object.hash(SharedText, text)` — il tipo entra nell'hash, così `SharedText('/a')` e `SharedImage('/a')` non collidono |
| `toString` | `String toString()` | `'SharedText(<text>)'` |

### `final class SharedImage extends SharedPayload`

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `const SharedImage(String path)` | |
| campo | `final String path` | percorso assoluto di un file **già copiato** dal plugin nella cache dell'app. Da `payloadsFromMedia`: mai vuoto |
| `==` | `bool operator ==(Object other)` | uguale se `other is SharedImage` e stesso `path` |
| `hashCode` | `int get hashCode` | `Object.hash(SharedImage, path)` |
| `toString` | `String toString()` | `'SharedImage(<path>)'` |

⚑ **Perché un URL non ha una classe sua**: Android non lo distingue (vedi §3), e capire se un
testo è un link è dominio dell'app (QR Me ha `UrlContent` nel suo `qr_decoder`). Una
`SharedUrl` qui sarebbe vera su iOS e quasi mai su Android.

---

## 5. `share_inbox.dart` e `rsi_share_inbox.dart`

### `abstract interface class ShareInbox`

| Metodo | Firma | Contratto |
|---|---|---|
| `initial` | `Future<List<SharedPayload>> initial()` | ciò che ha **aperto** l'app da chiusa. Letto **una volta** all'avvio, poi `reset()`. Lista vuota se aperta normalmente |
| `incoming` | `Stream<List<SharedPayload>> get incoming` | ciò che arriva con l'app aperta o in background. Broadcast. Mai liste vuote |
| `reset` | `Future<void> reset()` | dice al plugin che l'ultima condivisione è consumata |

### `class FakeShareInbox implements ShareInbox`

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `FakeShareInbox({List<SharedPayload> initial = const []})` | copia difensiva di `initial` |
| `initial` | `Future<List<SharedPayload>> initial()` | restituisce (non modificabile) la lista corrente; incrementa `initialCount` |
| `incoming` | `Stream<List<SharedPayload>> get incoming` | stream di uno `StreamController.broadcast()` interno |
| `reset` | `Future<void> reset()` | incrementa `resetCount` e svuota `initial`, come il plugin vero |
| `resetCount` | `int get resetCount` | quante volte è stato chiamato `reset` (i test delle app verificano che lo chiamino) |
| `initialCount` | `int get initialCount` | quante volte è stato chiamato `initial` |
| `setInitial` | `void setInitial(List<SharedPayload> payloads)` | sostituisce ciò che `initial` restituirà |
| `push` | `void push(List<SharedPayload> payloads)` | emette su `incoming`; **ignora le liste vuote** come l'implementazione vera |
| `pushError` | `void pushError(Object error)` | emette un errore su `incoming` |
| `close` | `Future<void> close()` | chiude il controller: va nel `tearDown` dei test |

### `class RsiShareInbox implements ShareInbox`

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `RsiShareInbox({ReceiveSharingIntent? plugin})` | scritto `RsiShareInbox({this._plugin})` (parametro formale privato, Dart ≥ 3.12: chi chiama scrive `plugin:`). `null` = `ReceiveSharingIntent.instance` |
| `initial` | `Future<List<SharedPayload>> initial()` | `payloadsFromMedia(await getInitialMedia())` |
| `incoming` | `Stream<List<SharedPayload>> get incoming` | `getMediaStream().map(payloadsFromMedia).where(isNotEmpty)` |
| `reset` | `Future<void> reset()` | `await plugin.reset()` |
| (privato) `_rsi` | `ReceiveSharingIntent get _rsi` | `_plugin ?? ReceiveSharingIntent.instance`, **letto a ogni uso** (vedi §8) |

### `List<SharedPayload> payloadsFromMedia(List<SharedMediaFile> files)` (funzione di libreria)

| `SharedMediaType` | Esito |
|---|---|
| `text`, `url` | `SharedText(path.trim())`; scartato se vuoto dopo il `trim` |
| `image` | `SharedImage(path)`; scartato se `path` è vuoto o di soli spazi |
| `video`, `file` | ignorati |

Inoltre: l'ordine di arrivo si conserva; un elemento **uguale** (per `==`) già presente nella
stessa consegna non si ripete; la lista restituita è **non modificabile**. Lo `switch` è
esaustivo sull'enum del plugin: un tipo nuovo in una versione futura rompe la compilazione
qui, non a runtime nelle app.

---

## 6. iOS: l'estensione e lo script

### `ios_template/ShareViewController.swift`

```swift
import receive_sharing_intent
class ShareViewController: RSIShareViewController {
    override func shouldAutoRedirect() -> Bool { return true }
}
```

`true` = nessuna schermata intermedia: salva nell'App Group e riapre subito l'app.

### `ios_template/Info.plist`

| Chiave | Valore | Perché |
|---|---|---|
| `AppGroupId` | `$(CUSTOM_GROUP_ID)` | il plugin ci legge l'App Group; il build setting lo mette lo script |
| `CFBundleDisplayName`, `CFBundleName` | `$(PRODUCT_NAME)` | |
| `CFBundleExecutable`, `CFBundleIdentifier`, `CFBundlePackageType`, `CFBundleDevelopmentRegion`, `CFBundleInfoDictionaryVersion` | variabili standard di Xcode | il target è creato con `GENERATE_INFOPLIST_FILE = NO` |
| `CFBundleShortVersionString` / `CFBundleVersion` | `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)` | dal pubspec dell'app, via `Generated.xcconfig` collegata dallo script |
| `NSExtension.NSExtensionPointIdentifier` | `com.apple.share-services` | è un'estensione di condivisione |
| `NSExtension.NSExtensionPrincipalClass` | `$(PRODUCT_MODULE_NAME).ShareViewController` | niente storyboard (`NSExtensionMainStoryboard` assente) |
| `NSExtensionActivationRule` | dict: `NSExtensionActivationSupportsText` true, `…WebURLWithMaxCount` 1, `…ImageWithMaxCount` 1 | testo, un link, un'immagine. Niente video e file |
| `NSExtensionAttributes.PHSupportedMediaTypes` | `[Image]` | come nel README del plugin, per le Foto |

### `tool/aggiungi_share_extension_ios.rb`

```
ruby tool/aggiungi_share_extension_ios.rb apps/qr_me ShareExtension group.com.smp.qrme
```

Dalla radice del monorepo, **sul Mac**, dopo `flutter pub get` dell'app. Idempotente. Passi:

| # | Cosa | Dettaglio |
|---|---|---|
| 1 | target `:app_extension` | `IPHONEOS_DEPLOYMENT_TARGET`, `TARGETED_DEVICE_FAMILY`, `DEVELOPMENT_TEAM` = valori **effettivi** del Runner (target, altrimenti progetto); bundle `<bundle Runner>.<nome>`; `CODE_SIGN_STYLE = Automatic`; `SKIP_INSTALL = YES`; runpath con `@executable_path/../../Frameworks`; Runner dipende dall'estensione |
| 2 | file | copia (sovrascrive se diversi) `ShareViewController.swift` e `Info.plist` da `packages/micro_share/ios_template/` in `apps/<app>/ios/<nome>/`; crea `<nome>.entitlements` con l'App Group; tutti i `*.swift` della cartella nei sorgenti del target |
| 3 | versioni | `base_configuration_reference` dell'estensione = quella del Runner per ogni configurazione |
| 4 | `CUSTOM_GROUP_ID` | sul Runner e sull'estensione, in tutte le configurazioni |
| 5 | `Runner.entitlements` | percorso da `CODE_SIGN_ENTITLEMENTS` del Runner (default `Runner/Runner.entitlements`), creato se manca, App Group aggiunto, riferimento nel gruppo `Runner` |
| 6 | `Runner/Info.plist` | `AppGroupId = $(CUSTOM_GROUP_ID)` e lo schema `ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)` in `CFBundleURLTypes` (aggiunto in testa se l'array esiste già); avviso se `FlutterDeepLinkingEnabled` non è `false` |
| 7 | pacchetto Swift | `XCLocalSwiftPackageReference` a `Flutter/ephemeral/Packages/.packages/receive_sharing_intent-<versione dal pubspec.lock>` + `XCSwiftPackageProductDependency` `receive-sharing-intent` sull'estensione + `PBXBuildFile` nella fase Frameworks |
| 8 | copia nell'app | fase `:plug_ins` del Runner (riusata se c'è, altrimenti «Embed Foundation Extensions»), appex aggiunto se manca, fase spostata **prima** di «Thin Binary» |

I plist si modificano **come testo** (inserimento prima dell'ultimo `</dict>`) e poi si
validano con `plutil -lint`: riscriverli con `Xcodeproj::Plist` cancellerebbe i commenti XML
che negli Info.plist delle MicroApps documentano le scelte.

---

## 7. Android: cosa mette l'app (non il package)

Nel `AndroidManifest.xml` dell'app, sulla `MainActivity`:

- `android:launchMode="singleTask"` (una sola istanza: la condivisione arriva su `incoming`
  invece di aprire una seconda app);
- due `intent-filter` `android.intent.action.SEND` + `category.DEFAULT`, uno con
  `<data android:mimeType="text/plain"/>` e uno con `<data android:mimeType="image/*"/>`;
- **niente** `READ_EXTERNAL_STORAGE` (§8).

---

## 8. Regole non negoziabili e trappole disinnescate

### Regole

1. **Package separato da `micro_core`.** `receive_sharing_intent` è un plugin nativo con
   configurazione iOS (estensione, App Group, schema URL). In `micro_core` finirebbe in tutte le
   app, comprese quelle già pubblicate che non lo configurano. Solo F16–F19 dipendono da qui.
2. **Le app non importano `receive_sharing_intent`.** Passano da `ShareInbox`; il barrel non
   riesporta i tipi del plugin.
3. **`reset()` subito dopo `initial()`.** Altrimenti la condivisione che ha aperto l'app torna a
   ogni ripresa e può ripresentarsi su `incoming`.
4. **I modelli iOS si modificano in `ios_template/`, mai nella cartella dell'app**: lo script li
   ricopia sopra a ogni giro.
5. **Dopo ogni aggiornamento di `receive_sharing_intent` si rilancia lo script** su ogni app
   che ha l'estensione (il percorso del pacchetto Swift contiene la versione, §8 trappola 4).

### Trappole, con la causa tecnica

| # | Trappola | Causa | Difesa |
|---|---|---|---|
| 1 | Condivisione consegnata **due volte** (all'avvio e su `incoming`) | il plugin conserva l'ultima condivisione finché non si chiama `reset` | regola 3; in più l'app (QR Me: `ShareRouter`) ignora un payload identico entro 2 s. Dentro la stessa consegna i doppioni li toglie già `payloadsFromMedia` (Safari può allegare la stessa pagina due volte) |
| 2 | Niente `READ_EXTERNAL_STORAGE` anche se il README del plugin lo elenca | l'immagine arriva come `content://` con permesso temporaneo del mittente e il plugin la copia nella cache; il permesso su Play richiede una giustificazione | da **verificare** con una condivisione vera da Galleria e da Chrome (F17.4); solo se fallisce si rivede |
| 3 | `shouldAutoRedirect()` | `false` mostra un foglio di composizione del plugin (campo messaggio, «Send»): un tocco in più contro il gesto «Condividi → QR già lì» | `true` nel modello. ☠ La riapertura dell'app da un'estensione via schema URL Apple la tollera senza documentarla: **va provata su iPad via TestFlight**; ripiego deciso: estensione che mostra il QR da sola (F17.1.8) |
| 4 | «Missing package product 'receive-sharing-intent'» dopo un aggiornamento del plugin | Flutter crea in `Flutter/ephemeral/Packages/.packages/` un collegamento chiamato come la cartella del plugin nella pub cache, **con la versione** (`receive_sharing_intent-1.9.0`) — `flutter_tools/lib/src/macos/swift_package_manager.dart`. Il progetto d'esempio del plugin usa `.packages/receive_sharing_intent`, che con questo Flutter non esiste | lo script legge la versione dal `pubspec.lock` dell'app e riallinea il percorso a ogni giro |
| 5 | «No such module 'receive_sharing_intent'» compilando l'estensione | il plugin è solo SPM: Flutter lo collega al Runner, non all'estensione | passo 7 dello script |
| 6 | L'app non si riapre dopo la condivisione | bundle dell'estensione con un punto in più (il plugin ricava il bundle dell'app togliendo l'ultimo pezzo), oppure schema `ShareMedia-…` assente dall'Info.plist del Runner | lo script fissa `<bundle>.<nome>` e aggiunge lo schema |
| 7 | La condivisione arriva all'app vuota | `CUSTOM_GROUP_ID` assente sul Runner → `AppGroupId` vuoto → il plugin legge da un gruppo diverso da quello in cui l'estensione ha scritto | passo 4 dello script; App Group in entrambi gli entitlements |
| 8 | Ciclo di dipendenze in build | fase di copia delle estensioni dopo «Thin Binary» | passo 8 dello script (già pagata col widget di TrashCan) |
| 9 | «Invalid placeholder attributes» all'installazione | Info.plist dell'estensione con versioni vuote: non eredita `Generated.xcconfig` | passo 3 dello script (già pagata col widget) |
| 10 | `go_router` mostra «Non trovato» all'arrivo di una condivisione su iOS | il deep link di Flutter acceso passa anche `ShareMedia-…:share` al router | `FlutterDeepLinkingEnabled = false` nell'app; lo script avvisa se manca |
| 11 | `RsiShareInbox` creata prima di `ReceiveSharingIntent.setMockValues` userebbe il plugin vero | `setMockValues` sostituisce l'istanza statica | `_rsi` è un getter letto a ogni uso, non un campo fissato nel costruttore |
| 12 | Proprietà del team vuota sull'estensione | `DEVELOPMENT_TEAM` e `IPHONEOS_DEPLOYMENT_TARGET` delle app Flutter stanno a livello di **progetto**, non del target Runner; leggerli dal solo target dà `nil`/vuoto | lo script legge il valore effettivo (target, poi progetto) e non scrive un team vuoto |

---

## 9. Catalogo dei test

`pwsh tool/fl.ps1 test` dentro `packages/micro_share` → **20 test verdi** (2026-10-09).

| Gruppo (`test/shared_payload_test.dart`) | Test | Cosa dimostra |
|---|---|---|
| `payloadsFromMedia` | 10 | testo → `SharedText`; url → `SharedText` col link; immagine → `SharedImage` col percorso; video e file ignorati; consegna mista nell'ordine giusto; testi vuoti/di soli spazi scartati e gli altri ripuliti; immagine senza percorso scartata; doppioni nella stessa consegna tolti; risultato non modificabile; l'enum del plugin ha esattamente i 5 valori noti (sentinella sugli aggiornamenti) |
| `SharedPayload` | 3 | uguaglianza e `hashCode` per valore e per **tipo** (stessa stringa, classi diverse → diversi); `toString`; `switch` esaustivo sulla classe sigillata |
| `FakeShareInbox` | 5 | `initial` stabile fino al `reset`, poi vuoto, con i contatori; `setInitial`; `push` consegna e ignora le liste vuote; broadcast a due ascoltatori; `pushError` arriva come errore |
| `RsiShareInbox sul plugin finto` | 2 | con `ReceiveSharingIntent.setMockValues`: `initial` converte e scarta il video, `reset` svuota, `incoming` non emette consegne rimaste vuote dopo la conversione; il plugin passato con `plugin:` vince sull'istanza statica |

Non coperto da test automatici (si prova a mano, F17.4 e iPad): l'intent Android vero,
l'estensione iOS, lo script Ruby.

---

## 10. Cosa NON esiste ancora

| Non esiste | Dove/quando |
|---|---|
| Un'app che usi il package | `apps/qr_me` da F17.2c; `ShareRouter` (doppioni entro 2 s, instradamento) vive nell'app, F17.4 |
| Provider Riverpod per `ShareInbox` | deliberatamente assente, come in `micro_core`: ogni app cabla il suo |
| Ricezione di più immagini (`SEND_MULTIPLE`), video, file generici | non servono a F16–F19 come decise finora; `payloadsFromMedia` scarta video e file |
| Il campo `message` di iOS (testo scritto nel foglio di composizione) | con `shouldAutoRedirect() == true` il foglio non c'è, quindi è sempre `null` |
| Cancellazione dei file temporanei delle immagini condivise | il plugin dice di cancellarli dopo l'uso (iOS); lo fa l'app quando ha finito, F17.4 |
| Prova dello script Ruby su un progetto vero | da fare sul Mac in F17.2c (bootstrap di `apps/qr_me`); vedi §11 |
| Ripiego iOS «estensione che mostra il QR da sola» (SwiftUI + `CIQRCodeGenerator`) | solo se la riapertura via schema fallisce su iPad |

---

## 11. Debito tecnico aperto

| # | Debito | Perché rimandato | Quando |
|---|---|---|---|
| DT-S1 | Lo script Ruby non è ancora stato eseguito su un progetto reale: solo `ruby -c` (Syntax OK, Ruby 2.6 del Mac) e verifica degli attributi di `xcodeproj` 1.28.1 sul Mac (`XCLocalSwiftPackageReference#relative_path`, `PBXBuildFile#product_ref`, `XCSwiftPackageProductDependency#product_name`) | serve `apps/qr_me`, che nasce in F17.2c | F17.2c, poi `flutter build ios` e archivio |
| DT-S2 | Il pacchetto Swift del plugin dipende da `FlutterFramework`: l'estensione si porta dietro il collegamento a `Flutter.framework`. Possibile errore di caricamento «contains disallowed file 'Frameworks'» (citato nel README del plugin) se Xcode incorpora il framework anche dentro l'appex | si vede solo all'archivio/caricamento su App Store Connect | primo TestFlight di QR Me |
| DT-S3 | Su Android, un **file** `.txt` condiviso da un gestore file arriva come `text` con `path` = percorso del file, e diventerebbe un `SharedText` col percorso | caso raro; l'app ha solo il filtro `text/plain` e i file manager lo usano poco | se si presenta: distinguere con `mimeType` + `path` assoluto esistente |

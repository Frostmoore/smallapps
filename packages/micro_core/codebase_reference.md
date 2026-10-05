# codebase_reference.md — `micro_core`

> Atlante del package condiviso delle MicroApps.
> **Obiettivo**: capire il codice, trovare ciò che serve e modificarlo **senza aprire i
> file**. Se per sapere che firma ha un metodo bisogna leggere il sorgente, ha fallito.
>
> **Aggiornato al**: 2026-09-10 · **Fase F1 chiusa** · **Toolchain**: Flutter 3.47.3, Dart 3.13.3
> **Test**: 100 verdi · **Analisi statica**: nessuna issue

---

## 1. Dove sta cosa

| Cerchi… | Vai in |
|---|---|
| La superficie pubblica | `lib/micro_core.dart` (barrel) |
| Esito di un'operazione fallibile | `src/util/result.dart` → `Result`, `Ok`, `Err`, `MicroError` |
| Date senza fuso orario | `src/util/civil_date.dart` → `CivilDate` |
| Importi di denaro | `src/util/money.dart` → `Money` |
| Log su file | `src/util/micro_log.dart` → `MicroLog` |
| Cartelle dell'app, scrittura atomica | `src/storage/app_paths.dart` → `AppPaths`, `AtomicFile` |
| Immagini e miniature | `src/storage/image_store.dart` → `ImageStore`, `StoredImage` |
| Preferenze tipizzate | `src/prefs/settings_store.dart` → `SettingsStore`, `SettingKeys` |
| Identità dell'installazione | `src/install/install_id.dart` → `InstallId` |
| Configurazione dell'app | `src/config/micro_app_config.dart` → `MicroAppConfig`, `BillingMode` |
| Tema e token grafici | `src/theme/` → `MicroTheme`, `MicroSpacing`, `MicroRadius`, `MicroDuration` |
| Componenti UI | `src/ui/micro_widgets.dart` → undici widget `Micro*` |
| Acquisti | `src/billing/` → `PurchaseGateway`, `StorePurchaseGateway`, `FakePurchaseGateway` |
| Dove le piattaforme divergono | § «Due sistemi, un package» qui sotto |
| Diritto al Pro | `src/entitlement/` → `Entitlement`, `EntitlementService`, `LicenseApi` |
| Cosa è a pagamento | `src/gate/` → `FeatureKey`, `FeatureLimit`, `FeatureGate` |
| Paywall e lucchetti | `src/gate/paywall.dart` → `PaywallPage`, `ProLock`, `ProBadge` |
| Notifiche locali | `src/notifications/` → `NotificationService`, `NotificationIds` |
| Backup e CSV | `src/backup/backup.dart`, `src/export/csv_writer.dart` |
| Cosa dimostrano i test | §9 |
| Cosa **non** esiste ancora | §10 |

---

## Due sistemi, un package

Dal 2026-10-04 le app escono su Android **e** su iOS (ADR-021, e `memory/decisioni.md`).
`micro_core` è il posto dove questo costa di più: un presupposto sbagliato qui si moltiplica
per quattro app.

☠ **Il difetto tipico non è il codice nativo, è la riga Dart.** Il codice nativo si vede e
si sa di doverlo scrivere due volte. Quello che non si vede è la chiamata a un'API che
esiste su una piattaforma sola: compila senza un avviso, passa i test a tavolino, e fallisce
a runtime sull'altro sistema. I due casi già pagati stanno qui sotto.

| Punto | Com'era | Perché era un difetto |
|---|---|---|
| `NotificationService.create` | passava i soli `AndroidInitializationSettings` | su iOS non arrivava **nessuna** notifica, e niente lo diceva: l'oggetto accetta i soli parametri Android senza lamentarsi |
| `NotificationService.ensurePermission` | risolveva la sola implementazione Android, e con `null` rispondeva `notRequired` | su iOS il permesso serve eccome. L'interfaccia mostrava i promemoria come attivi e funzionanti |
| `NotificationService.scheduleOne` | lasciava risalire ogni `PlatformException` | su iOS, senza permesso, pianificare **lancia** (`UNErrorDomain`, "Source is not authorized"), mentre Android accetta in silenzio. Chi comprava il Pro su iPhone prima di concedere le notifiche vedeva la pianificazione fermarsi al primo promemoria. Ora il rifiuto di permesso si salta con un avviso nel registro (`rifiutoDiPermesso`), ogni altro errore risale. Trovato dal test degli screenshot il 2026-10-05 |
| `MicroCard` | un `DecoratedBox` colorato senza superficie Material | le voci d'elenco dentro la card disegnavano l'effetto del tocco sotto il fondo: toccare "Chiaro" o "Scuro" non dava segno di risposta. Ora c'e' un `Material` trasparente fra fondo e contenuto |
| `NotificationService` | non esisteva un modo di **leggere** il permesso senza chiederlo | chi chiama non poteva sapere come stava, e non chiedeva mai. Vedi la trappola nell'atlante di TrashCan: niente notifiche su **nessuna** delle due piattaforme |
| `StorePurchaseGateway.buy` | `GooglePlayPurchaseParam` sempre | `in_app_purchase` lo rifiuta a runtime su iOS: il difetto si vedeva solo toccando il pulsante d'acquisto |

⚑ **Dove serve distinguere, si guarda `defaultTargetPlatform`**, non `Platform.isAndroid`:
il secondo legge `dart:io`, che un test non può far mentire, e la differenza fra le
piattaforme resterebbe la sola parte scoperta dai test.

⚑ Quello che **non** diverge, e che conviene lasciare dov'è: il motore delle ricorrenze, il
database, le traduzioni, il tema, i limiti del Pro e il paywall. Il paywall mostra
`formattedPrice` che arriva dal negozio, quindi è già corretto su tutti e due senza una
riga di condizione.

## 2. Albero dei file

```
packages/micro_core/
├─ pubspec.yaml
├─ analysis_options.yaml          include: ../../analysis_options.yaml
├─ codebase_reference.md          questo file
├─ lib/
│  ├─ micro_core.dart             BARREL: l'unica cosa che le app importano
│  └─ src/
│     ├─ backup/backup.dart       ImportMode, BackupSource, BackupManifest,
│     │                           JsonBackupCodec, BackupService
│     ├─ billing/
│     │  ├─ purchase_gateway.dart      MicroProduct, PurchaseEvent + 4 sottotipi,
│     │  │                             PurchaseGateway, BillingErrorCodes
│     │  ├─ fake_purchase_gateway.dart FakeOutcome, FakePurchaseGateway
│     │  └─ store_purchase_gateway.dart StorePurchaseGateway
│     ├─ config/micro_app_config.dart  BillingMode, MicroAppConfig
│     ├─ entitlement/
│     │  ├─ entitlement.dart           ProStatus, EntitlementSource, Entitlement
│     │  ├─ entitlement_store.dart     EntitlementStore
│     │  ├─ entitlement_service.dart   EntitlementService
│     │  └─ license_api_client.dart    ServerEntitlement, RestoreCode,
│     │                                LicenseApi, LicenseApiClient
│     ├─ export/csv_writer.dart        CsvWriter
│     ├─ gate/
│     │  ├─ feature_key.dart           FeatureKey (13 valori)
│     │  ├─ feature_limits.dart        FeatureLimit, FeatureLimits
│     │  ├─ feature_gate.dart          GateVerdict, GateAllowed, GateBlocked,
│     │  │                             BlockReason, FeatureGate
│     │  └─ paywall.dart               PaywallBenefit, PaywallConfig, PaywallPage,
│     │                                ProBadge, ProLockMode, ProLock
│     ├─ install/install_id.dart       InstallId
│     ├─ notifications/
│     │  └─ notification_service.dart  MicroImportance, MicroNotificationChannel,
│     │                                ScheduledNotification, PermissionOutcome,
│     │                                NotificationService, NotificationIds
│     ├─ prefs/settings_store.dart     SettingsStore, SettingKeys
│     ├─ storage/
│     │  ├─ app_paths.dart             AppPaths, AtomicFile
│     │  └─ image_store.dart           StoredImage, ImageStore
│     ├─ theme/
│     │  ├─ micro_tokens.dart          MicroSpacing, MicroRadius, MicroDuration,
│     │  │                             MicroColorScheme, MicroTextTheme (extension)
│     │  └─ micro_theme.dart           MicroTheme
│     ├─ ui/micro_widgets.dart         MicroPageScaffold, MicroCard,
│     │                                MicroSectionHeader, MicroListTile,
│     │                                MicroEmptyState, MicroPrimaryButton,
│     │                                MicroChip, MicroConfirmSheet, MicroSnack,
│     │                                MicroStatTile, MicroProgressRing
│     └─ util/
│        ├─ result.dart                Result, Ok, Err, MicroError, MicroErrorCodes
│        ├─ civil_date.dart            CivilDate
│        ├─ money.dart                 Money
│        └─ micro_log.dart             LogLevel, MicroLog
└─ test/
   ├─ core_modules_test.dart                      30 test
   ├─ entitlement/entitlement_service_test.dart   22 test
   ├─ gate/feature_gate_test.dart                 20 test
   └─ util/civil_date_test.dart                   28 test
```

**Regola del barrel**: le app importano solo `package:micro_core/micro_core.dart`. Mai
`package:micro_core/src/...`. Quello che non è esportato è dettaglio interno.

---

## 3. Dipendenze

| Pacchetto | A cosa serve |
|---|---|
| `meta` | `@immutable`, `@protected` |
| `intl` | formattazione di `Money` |
| `path`, `path_provider` | `AppPaths` |
| `shared_preferences` | `SettingsStore` |
| `flutter_secure_storage`, `uuid`, `crypto` | `InstallId`, firma HMAC |
| `http` | `LicenseApiClient` |
| `in_app_purchase`, `in_app_purchase_android` | `StorePurchaseGateway` (il pacchetto Android serve al solo `GooglePlayPurchaseParam`) |
| `flutter_local_notifications`, `timezone`, `flutter_timezone` | `NotificationService` |
| `archive`, `file_picker`, `share_plus` | `BackupService` |
| `image` | `ImageStore` |
| `pdf` | dichiarato ma **non ancora usato**: servirà a `PdfReportBuilder` (DT-10) |

**Le versioni non si scrivono a mano**: `pwsh tool/fl.ps1 pub add <pacchetto>`.

---

## 4. `util/` — le fondamenta

### `sealed class Result<T>`, `final class Ok<T>`, `final class Err<T>`

| Firma | Effetto |
|---|---|
| `bool get isOk` · `bool get isErr` | |
| `T? get valueOrNull` · `MicroError? get errorOrNull` | |
| `T orElse(T fallback)` | |
| `R fold<R>({required R Function(T) ok, required R Function(MicroError) err})` | Entrambi i rami obbligatori |
| `Result<R> map<R>(R Function(T))` | Propaga l'errore |
| `Result<R> flatMap<R>(Result<R> Function(T))` | Concatena |

⚑ Rete assente, file corrotto e acquisto annullato non sono bug: sono esiti. Le eccezioni
restano per i bug, e così sparisce il `try/catch` decorativo intorno a ogni chiamata.

### `class MicroError`

`const MicroError({required String code, required String message, Object? cause, StackTrace? stackTrace})`
· `factory MicroError.unexpected(Object cause, [StackTrace?])`

⚑ `code` è un identificatore stabile su cui ramificare; `message` è per i log, **non per la
UI**: i testi mostrati all'utente vivono negli ARB delle app.

`MicroErrorCodes`: `network`, `timeout`, `unauthorized`, `notFound`, `rateLimited`,
`badResponse`, `io`, `corruptedFile`, `unsupportedVersion`, `billingUnavailable`,
`purchaseCanceled`, `purchaseFailed`, `permissionDenied`, `unexpected`.

### `final class CivilDate implements Comparable<CivilDate>`

Implementa ADR-008. Serializzata sempre come TEXT `YYYY-MM-DD`.

**Costruttori**: `CivilDate(int y, int m, int d)` (normalizza i fuori intervallo) ·
`.fromDateTime(DateTime)` · `.today({DateTime? now})` · `.parse(String)` ·
`static CivilDate? tryParse(String?)` · `.fromEpochDay(int)`

**Membri**: `year` · `month` · `day` · `weekday` · `epochDay` · `daysInMonth` ·
`firstDayOfMonth` · `lastDayOfMonth`

**Metodi**: `toIso()` · `toLocalMidnight()` · `toLocalDateTime(int hour, [int minute = 0])` ·
`addDays(int)` · `addMonths(int)` · `addYears(int)` · `daysUntil(CivilDate)` ·
`isBefore` · `isAfter` · `isSameOrBefore` · `isSameOrAfter` · `isToday({DateTime? now})` ·
`rangeTo(CivilDate)` · `compareTo(CivilDate)`

### `final class Money implements Comparable<Money>`

| Firma | Note |
|---|---|
| `const Money.cents(int cents, {String currency = 'EUR'})` | |
| `factory Money.fromDouble(double, {String currency})` | arrotonda al centesimo |
| `static Money? tryParse(String, {String currency})` | interpreta ciò che l'utente digita |
| `static const Money zero` | |
| `double get asDouble` · `bool get isZero` · `bool get isNegative` | |
| `operator +` `-` `*` `/` | `/` **non conserva il totale**, vedi §8 |
| `String format({String? locale})` · `String formatPlain({String? locale})` | |
| `static Money sum(Iterable<Money>, {String currency})` | |
| `static Money? average(Iterable<Money>, {String currency})` | `null` su collezione vuota |

### `abstract final class MicroLog` · `enum LogLevel { debug, info, warn, error }`

`init({required File file, LogLevel minLevel, int maxBytes})` · `d()` · `i()` · `w()` ·
`e()` · `export({required Directory into})` · `clear()` · `dispose()` · `isActive` · `file`

---

## 5. `storage/`

### `class AppPaths`

`static Future<AppPaths> forApp({required String appId})` ·
`factory AppPaths.underRoot(Directory root)` (per i test)

Cartelle: `documents` · `support` · `images` · `thumbs` · `exports` · `logs`

Metodi: `ensureAll()` · `file(Directory, String)` · **`resolve(String relativePath)`** ·
`relativize(File)` · `sizeOf(Directory)`

☠ **I percorsi assoluti non si salvano mai nel database.** Su Android la sandbox cambia
percorso fra un aggiornamento e l'altro: un assoluto salvato oggi punta al nulla dopo il
primo update, e tutte le foto degli utenti risultano mancanti.

### `abstract final class AtomicFile`

`writeString(File, String)` · `writeBytes(File, List<int>)` · `readStringOrNull(File)` ·
`readBytesOrNull(File)`

### `class ImageStore` · `class StoredImage`

`importFile(File, {required String bucket, int maxLongSide = 1600, int thumbLongSide = 400, int quality = 82})` ·
`importBytes(Uint8List, …)` · `resolve(String)` · `delete(StoredImage)` ·
`deleteBucket(String)` · `totalBytes()` · `pruneOrphans(Set<String> referenced)`

`StoredImage`: `path` (**relativo**) · `thumbPath` · `width` · `height` · `bytes` ·
`createdAt` · `toJson()` · `fromJson()`

---

## 6. `prefs/`, `install/`, `config/`

### `class SettingsStore`

`static Future<SettingsStore> create({required String namespace})` ·
`factory SettingsStore.withPreferences(SharedPreferences, {required String namespace})`

`getBool/setBool` · `getInt/setInt` · `getDouble/setDouble` · `getString/setString` ·
`getStringList/setStringList` · `getDate/setDate` (come `YYYY-MM-DD`) ·
`getInstant/setInstant` (ms UTC) · `remove` · `clearNamespace` · `Stream<String> changes`

`SettingKeys`: `onboardingDone`, `themeMode`, `notificationsEnabled`, `lastRescheduleAt`,
`lastServerSyncAt`, `paywallShownCount`, `reviewPromptShownAt`, `launchCount`,
`firstLaunchAt`

⚑ Ogni getter richiede un `orElse`: "preferenza mancante" ha sempre un significato preciso,
e obbligare a dichiararlo evita i `?? false` sparsi che confondono "spento" con "mai deciso".

### `class InstallId`

`static Future<InstallId> load({required String appId, FlutterSecureStorage storage})` ·
`factory InstallId.fixed(String)` · `value` · `obfuscatedAccountId` (SHA-256, 64 caratteri) ·
`short`

### `class MicroAppConfig` · `enum BillingMode { fake, play }`

`const MicroAppConfig({required String appId, required String appName, required String proSku, required Color seedColor, required String fontFamily, required Brightness defaultBrightness, required BillingMode billingMode, String? displayFontFamily, Uri? licenseBaseUrl, String appSecret = ''})`

`factory MicroAppConfig.fromEnvironment({required String appId, required String appName, required String proSku, required Color seedColor, required String fontFamily, required Brightness defaultBrightness, String? displayFontFamily})`

`bool get serverEnabled` · `bool get usesRealBilling` · `void assertUsableInRelease()`

| `--dart-define` | Valori | Default |
|---|---|---|
| `BILLING` | `fake` \| `play` | `fake` in debug, `play` in release |
| `MA_LICENSE_URL` | URL | assente = nessuna verifica server |
| `MA_APP_SECRET` | stringa | vuota |

---

## 7. Acquisti, entitlement, gating, tema, notifiche

### `abstract interface class PurchaseGateway`

`isAvailable()` · `init()` · `Stream<PurchaseEvent> get events` ·
`loadProducts(Set<String>)` · `buy(MicroProduct, {required String obfuscatedAccountId})` ·
`restorePurchases()` · `completePurchase(PurchaseSucceeded)` · `dispose()`

Implementazioni: `StorePurchaseGateway({InAppPurchase? iap})` e
`FakePurchaseGateway({List<MicroProduct> catalog, Duration latency, FakeOutcome outcome, bool startsOwned})`,
con `FakePurchaseGateway.withProduct(...)`, `owns()`, `wasAcknowledged()`, `grant()`, `reset()`.

`enum FakeOutcome { success, canceled, failed, pendingForever, unavailable }`

`sealed class PurchaseEvent` → `PurchasePending` · `PurchaseSucceeded` (con
`purchaseToken`, `orderId`, `purchasedAt`, `restored`) · `PurchaseCanceled` ·
`PurchaseFailed` (con `code`, `message`)

`class MicroProduct`: `id` · `title` · `description` · `formattedPrice` ·
`rawPriceMicros` · `currencyCode` · `Money get price`

### `class Entitlement`

`enum ProStatus { free, pro, pending, revoked }` ·
`enum EntitlementSource { none(0), local(1), play(2), server(3) }`

`Entitlement.free(String appId)` · `fromJson` · `toJson` · `copyWith` · `isPro` ·
`isPending` · `isRevoked` · **`bool supersedes(Entitlement other)`**

Le sei regole di `supersedes`, in ordine di applicazione:

1. Il nulla (`source == none`) non sostituisce un'informazione.
2. Un `free` non toglie mai il Pro, **da nessuna fonte**.
3. Una revoca dal server resta finché non arriva un acquisto **successivo** alla revoca.
4. A stati diversi vince la fonte più affidabile.
5. Stessa fonte, stato diverso: si applica (è il passaggio a `pending` e ritorno).
6. Stesso stato e stessa fonte: vince la verifica più recente.

### `class EntitlementService extends ChangeNotifier`

`EntitlementService({required String appId, required String proSku, required PurchaseGateway gateway, required EntitlementStore store, required InstallId installId, LicenseApi? api, Duration serverSyncInterval = const Duration(hours: 24)})`

`bootstrap()` · `buyPro()` · `restorePurchases()` · `refreshFromServer()` ·
`createRestoreCode()` · `claimRestoreCode(String)` · `debugGrantPro()` ·
`current` · `isPro` · `isPending` · `isBusy` · `storeAvailable` · `products` ·
`proProduct` · `lastError` · `static const List<Duration> verifyBackoff` (2 s, 8 s, 30 s)

**Ordine di `bootstrap()`**: legge il locale e notifica subito → apre il gateway → ascolta
con deduplica per token → ripristino silenzioso → sync col server se scaduto l'intervallo.

**Ordine dopo un acquisto riuscito**: scrive l'entitlement → riconosce l'acquisto allo store
→ verifica col server. Invertire i primi due significa che chi è senza rete paga e non vede
lo sblocco; saltare il secondo significa che Google rimborsa da solo dopo tre giorni.

**`dispose()` chiude solo la sottoscrizione agli eventi.** Non il gateway, non il client del
server: quelli arrivano per iniezione e appartengono a chi li costruisce.

☠ Qui c'era `gateway.dispose()`. Il servizio viene ricreato ogni volta che una sua
dipendenza cambia, e la prima ricreazione avviene **sempre**: all'avvio l'id di installazione
e' ancora in caricamento e arriva un istante dopo. Il primo servizio chiudeva il gateway, il
secondo ne riceveva uno gia' chiuso, e da quel momento ogni acquisto falliva con "Bad state:
Cannot add new events after calling close". Sintomo per l'utente: il bottone "Sblocca Pro"
gira all'infinito. Cioe' **nessuno puo' comprare**, in app il cui unico ricavo e' quello.
Nessun crash, nessun avviso, e niente che si noti senza provare a pagare davvero.

**Regola, da qui in avanti: un servizio non chiude niente che non abbia costruito.**

### `class EntitlementStore`

`const EntitlementStore({required File file})` ·
`static Future<EntitlementStore> open({required AppPaths paths})` ·
`read(String appId)` · `write(Entitlement)` · `clear()`

### `abstract interface class LicenseApi` · `class LicenseApiClient implements LicenseApi`

`verifyPurchase({required String sku, required String purchaseToken, String? orderId})` ·
`fetchEntitlement()` · `createRestoreCode()` · `claimRestoreCode(String)` · `close()`

`LicenseApiClient({required Uri baseUri, required String appId, required String appSecret, required String installId, required String appVersion, http.Client? httpClient, Duration timeout = const Duration(seconds: 8)})`

Classi di risposta: `ServerEntitlement` (`status`, `productId`, `purchasedAt`, `revokedAt`,
`serverTime`) · `RestoreCode` (`code`, `expiresAt`)

### Gating (ADR-017)

`enum FeatureKey` (13 valori): `unlimitedEntities`, `secondaryEntities`, `photos`,
`statistics`, `fullHistory`, `csvExport`, `pdfReport`, `backupRestore`, `advancedWidget`,
`multipleNotifications`, `calendarSync`, `customCategories`, `themeCustomization`

`class FeatureLimit`: `.open()` · `.count({required int freeMax})` · `.locked()` ·
`freeMax` · `isLockedForFree` · `isCounted` · `isOpen`

`typedef FeatureLimits = Map<FeatureKey, FeatureLimit>`

`class FeatureGate`: `const FeatureGate({required FeatureLimits limits, required bool isPro})` ·
`.unlimited()` · `limitOf` · `allows` · `freeLimitOf` · `withinLimit` · `remaining` ·
`check({int currentCount = 0})` · `proOnlyFeatures` · `limitedFeatures` · `copyWith`

`sealed class GateVerdict` → `GateAllowed` · `GateBlocked({required FeatureKey key, required BlockReason reason, int? freeMax})` ·
`enum BlockReason { proOnly, limitReached }`

### Paywall

`PaywallPage.show(BuildContext, {required PaywallConfig config, required EntitlementService service, FeatureKey? highlight})` → `Future<bool>`

`PaywallConfig({required String appName, required String headline, required String subhead, required List<PaywallBenefit> benefits, required String Function(String? price) buyLabel, required String restoreLabel, required String pendingLabel, required String thanksLabel, required String nothingToRestoreLabel, required String unavailableLabel, required String oneTimeNotice, WidgetBuilder? heroBuilder, String? footnote})`

`PaywallBenefit({required FeatureKey key, required IconData icon, required String title, required String description})`

`ProLock({required FeatureKey feature, required FeatureGate gate, required Widget child, int currentCount = 0, ProLockMode mode = ProLockMode.overlay, void Function(GateBlocked)? onBlocked})` ·
`enum ProLockMode { overlay, hide, badgeOnly }` · `ProBadge({bool compact = false})`

### Tema

`MicroTheme.build({required Color seed, required Brightness brightness, required String fontFamily, String? displayFontFamily})`, con `.light()` e `.dark()`.

Token: `MicroSpacing` (`xxs` 2 … `xxxl` 48, più `pageH`, `page`, `card`, `cardTight`, i gap
verticali `gapXS`…`gapXXL` e orizzontali `hGapS`…`hGapL`) · `MicroRadius` (`small` 8,
`medium` 14, `large` 22, più `chip`, `card`, `hero`, `sheet`) · `MicroDuration` (`quick`
120 ms, `normal` 240 ms, `slow` 420 ms)

Extension `MicroColorScheme` su `ColorScheme`: `success` · `onSuccess` · `warning` ·
`onWarning` · `danger` · `onDanger` · `cardSurface` · `subtleBorder` · `mutedText`

Extension `MicroTextTheme` su `TextTheme`: `numeric` · `cardTitle` · `cardMeta` ·
`statValue` · `statLabel` · `sectionLabel`

### Componenti (11)

`MicroPageScaffold` · `MicroCard` (con `static Color foregroundOn(Color)`) ·
`MicroSectionHeader` · `MicroListTile` · `MicroEmptyState` · `MicroPrimaryButton` ·
`MicroChip` · `MicroConfirmSheet.show(...)` · `MicroSnack.success/error/show` ·
`MicroStatTile` · `MicroProgressRing`

### Notifiche (ADR-009)

`NotificationService.create({required String androidIconResource, required List<MicroNotificationChannel> channels, FlutterLocalNotificationsPlugin? plugin})`

`hasPermission()` · `ensurePermission()` · `canScheduleExactAlarms()` ·
`requestExactAlarmPermission()` ·
`scheduleOne(ScheduledNotification)` · **`replaceSchedule(Iterable<ScheduledNotification>)`** ·
`cancel(int)` · `cancelAll()` · `pending()` · `Stream<String> taps` ·
`consumeLaunchPayload()` · `static const int maxPending = 64`

`MicroNotificationChannel({required String id, required String name, required String description, MicroImportance importance, bool enableVibration, bool playSound})` ·
`enum MicroImportance { low, normal, high }` ·
`ScheduledNotification({required int id, required DateTime localWhen, required String title, required String body, required String channelId, String? payload, bool exact = false})` ·
`enum PermissionOutcome { granted, denied, permanentlyDenied, notRequired }`

`NotificationIds`: `reservedMax` (999) · `weeklyDigest` (10) · `reorderWarning` (20) ·
`reorderOverdue` (21) · `forOccurrence(int entityId, CivilDate date, int slot)`

### `abstract interface class NotificationScheduler` e `class RescheduleGuard`

`src/notifications/notification_scheduler.dart`

`NotificationScheduler`: `Future<void> rescheduleAll()` · `Future<void> cancelAll()`.

⛑ Perche' un'interfaccia qui e non una classe per app: tutte e quattro le app
ripianificano allo stesso modo (ADR-009) e dagli stessi punti, cioe' al ritorno in primo
piano e dopo ogni modifica ai dati. Una forma comune permette di scrivere quel richiamo una
volta sola invece di quattro, e soprattutto di non dimenticarne uno: una notifica che non
viene ripianificata non produce nessun errore, semplicemente non arriva.

`RescheduleGuard(SettingsStore settings, {Duration minInterval = const Duration(hours: 1)})`
· `bool shouldReschedule({DateTime? now})` · `Future<void> markRescheduled({DateTime? now})`

☠ Ripianificare costa fino a 64 cancellazioni e 64 pianificazioni, ognuna attraverso il
canale con Android: farlo a ogni ritorno in primo piano rende l'apertura visibilmente lenta
su un telefono di fascia bassa. Il momento dell'ultima ripianificazione si legge dalle
preferenze e non da un campo in memoria, perche' l'app viene uccisa e riaperta di continuo e
un contatore in memoria si azzererebbe proprio nel caso che il controllo dovrebbe coprire.
Un orologio spostato all'indietro non blocca le ripianificazioni.

### Backup ed export

`abstract interface class BackupSource`: `schemaId` · `schemaVersion` · `exportPayload()` ·
`importPayload(Map, {required ImportMode mode})` · `imagePaths()` · `counts()`

`enum ImportMode { replaceAll, mergeKeepExisting }`

`class BackupService({required AppPaths paths, required String appVersion})`:
`createBackup(BackupSource, {String? label, bool includeImages = false})` ·
`inspect(File)` · `restore(File, BackupSource, {required ImportMode mode})` ·
`pickBackupFile()` · `shareBackup(File, {String? subject})` · `cleanupExports({Duration olderThan})`

`JsonBackupCodec`: `magic` = `MICROAPPS_BACKUP` · `formatVersion` = 1 · `encode(...)` ·
`decode(String)`

`class BackupManifest`: `schemaId` · `schemaVersion` · `appVersion` · `createdAt` ·
`itemCounts` · `label` · `totalItems`

`class CsvWriter({String separator = ';', String lineEnding = '\r\n', bool withBom = true})`:
`addHeader(List<String>)` · `addRow(List<Object?>)` · `addBlankLine()` · `build()` ·
`writeTo(File)`

---

## 8. Regole non negoziabili e trappole disinnescate

### Regole

1. **`micro_core` non conosce nessuna app.** Nessun `if (appId == ...)`, mai. È la
   condizione perché la decima app costi quanto la quinta.
2. **Le app importano solo il barrel.**
3. **Date civili come TEXT `YYYY-MM-DD`**, istanti come millisecondi UTC.
4. **Nessuna stringa destinata all'utente in questo package.**
5. **Versioni delle dipendenze con `pub add`**, mai a memoria.

### Trappole, con la causa tecnica

☠ **1. Scritture concorrenti sullo stesso file.** `AtomicFile` usava un unico `.tmp`: due
percorsi asincroni che salvavano lo stesso file si sabotavano, e `rename` falliva perché
l'altro aveva già consumato il temporaneo. In produzione il sintomo sarebbe stato un
entitlement che ogni tanto non si salva, cioè **un Pro che sparisce al riavvio**: raro, non
riproducibile, devastante. Ora le scritture sono in fila per percorso e il temporaneo ha un
nome unico. Trovata dai test.

☠ **2. La revoca eterna.** La prima versione di `supersedes` faceva vincere per sempre una
revoca dal server: un utente rimborsato **non avrebbe mai più potuto ricomprare l'app**. Ora
la revoca cede a un acquisto successivo alla revoca stessa. Trovata dai test.

☠ **3. Il `free` che declassa.** Un `free` non toglie il Pro da nessuna fonte, nemmeno dal
server: per togliere il Pro il server deve dire `revoked`, che è un fatto (rimborso,
chargeback), non l'assenza di un fatto.

☠ **4. `notifyListeners` dopo `dispose`.** Il servizio ha verifiche e sincronizzazioni in
volo che si concludono dopo la distruzione. Guardia `_disposed`. Trovata dai test.

☠ **4bis. Lo spinner che non si ferma su un acquisto in attesa.** Il ramo
`PurchasePending` di `_onPurchaseEvent` spegneva `isBusy` **dopo** aver scritto
l'entitlement, al contrario di ogni altro ramo, che lo spegne per primo. Con una scrittura
lenta — o che lancia — il bottone "Sblocca Pro" continua a girare su un acquisto che il
negozio ha gia' preso in carico, e un pagamento in attesa di approvazione puo' durare
giorni. Ora `_setBusy(false)` viene prima di `_apply`. Trovata dai test.

☠ **5. Acknowledge entro tre giorni.** Un acquisto non riconosciuto viene **rimborsato
automaticamente** da Google. `completePurchase` va chiamata dopo aver scritto l'entitlement,
e va ritentata all'avvio.

☠ **6. Deduplica degli acquisti.** `in_app_purchase` consegna gli acquisti passati **a ogni
avvio**, non solo dopo un ripristino. Senza deduplica per token, ogni avvio produce una
verifica al server e una snackbar "grazie per l'acquisto".

☠ **7. Il fuso orario delle notifiche.** Senza `initializeTimeZones()` e
`setLocalLocation(...)`, `zonedSchedule` interpreta tutto come UTC: in Italia d'estate un
promemoria delle 20:00 arriva alle 18:00.

☠ **8. Id di notifica derivati e non progressivi.** Con un contatore, la ripianificazione a
ogni resume darebbe alla stessa raccolta un id diverso ogni volta, accumulando duplicati
fino a far arrivare la stessa notifica cinque volte.

☠ **9. Il font variabile.** `fontWeight` da solo non basta: senza `fontVariations` sull'asse
`wght` tutti i pesi renderizzano l'istanza predefinita e l'app appare tutta dello stesso
spessore. Dichiarare lo stesso file quattro volte nel pubspec non risolve.

☠ **10. CSV per Excel italiano.** Separatore `;` e BOM UTF-8. Con `,` l'intero file finisce
in una colonna sola; senza BOM gli accenti si rompono.

☠ **11. Ridimensionamento immagini fuori dal thread UI.** Una foto da 12 megapixel richiede
secondi su un telefono di fascia bassa. `ImageStore` usa `compute` e applica
`bakeOrientation`, senza il quale le foto verticali appaiono coricate.

☠ **12. `Money.tryParse` e il punto ambiguo.** `1.000` sono mille, `6.50` sono sei e
cinquanta: si distinguono dal numero di cifre dopo il punto. La prima versione trattava il
punto sempre come separatore di migliaia e trasformava 6,50 € in 650 €. Trovata dai test.

☠ **13. `Money./` non conserva il totale.** Dividere 10 € in tre dà tre volte 3,33 €, cioè
9,99 €. Per ripartire un importo senza perdere centesimi serve un'allocazione, che qui non
c'è perché nessuna app la richiede.

☠ **14. `FeatureGate.limitOf` su chiave non dichiarata restituisce `open`, non `locked`.**
Dimenticare una dichiarazione regala una funzione a tutti, il che costa ricavi ma non rompe
niente; il contrario toglierebbe agli utenti gratuiti una funzione che doveva essere loro.

---

## 9. Catalogo dei test

`pwsh tool/test_all.ps1 -Project micro_core` → **107 test verdi**.

| File | Test | Cosa dimostra |
|---|---|---|
| `util/civil_date_test.dart` | 28 | I due cambi d'ora italiani del 2026 non spostano le date; clamp di fine mese e sua non permanenza; regola dei 400 anni; `epochDay` e il suo inverso; intervalli inclusivi; normalizzazione dei fuori intervallo |
| `gate/feature_gate_test.dart` | 20 | I quattro bordi di ogni tetto (0, max−1, max, max+1); le tre forme di limite; la distinzione fra `allows` e `withinLimit`; gli elenchi per il paywall |
| `entitlement/entitlement_service_test.dart` | 23 | **ADR-007**: un Pro non si perde offline; solo una revoca dal server lo toglie; la revoca cede a un acquisto successivo; l'acquisto sblocca senza rete; l'acknowledge viene fatto; lo stato finisce su disco; deduplica dei token; i cinque esiti del gateway finto; file corrotto, di un'altra app, o con stati sconosciuti; **chiudere il servizio non chiude il gateway ricevuto per iniezione** (verificato contro il codice vecchio, dove fallisce) |
| `notifications/reschedule_guard_test.dart` | 6 | La prima volta si ripianifica sempre; dentro l'ora no; passata l'ora si'; un orologio spostato indietro non blocca; l'intervallo e' configurabile; lo stato sopravvive alla ricostruzione dello store |
| `core_modules_test.dart` | 30 | `Money` (somme senza errore di virgola mobile, parsing di ciò che l'utente digita davvero); `CsvWriter` (BOM, separatore, escaping); backup (round-trip, rifiuto di app e schema sbagliati, file inesistente); `AtomicFile` (venti scritture concorrenti); `AppPaths` (i relativi sopravvivono a un cambio di radice); `NotificationIds` (stabilità e unicità); `InstallId` |

---

## 10. Cosa NON esiste ancora

| Non esiste | Dove/quando |
|---|---|
| `PdfReportBuilder` | Rinviato a F6.11: lo usa solo Film Tracker, e costruirlo ora vorrebbe dire indovinare che forma deve avere il riepilogo. Il pacchetto `pdf` è già in dipendenza |
| Galleria dei componenti (`example/`) | Rinviata, DT-09: i componenti sono in uso reale dalla prima app, che è una verifica migliore di una galleria isolata |
| Golden test dei componenti | F7 |
| Provider Riverpod condivisi | Deliberatamente assenti: `micro_core` resta libero da Riverpod, e ogni app cabla i propri provider |
| Test di `NotificationService` che tocchino il plugin | F3.8, insieme allo scheduler di TrashCan |
| Test di `StorePurchaseGateway` | F3.12: servono Play Services e un prodotto pubblicato |
| Estensione WidgetKit per il widget iOS | Vive nelle app, non qui. Non esiste ancora in nessuna |
| Widget nativi | Vivono nelle app, non qui (ADR-015) |

---

## 11. Debito tecnico aperto

| Voce | Perché è rimandata | Quando |
|---|---|---|
| Nessun test di `MicroAppConfig.fromEnvironment` | Legge `String.fromEnvironment`, costante di compilazione: servirebbero build separate con define diversi | F3.12 |
| `pubspec.lock` committato per un package libreria | La convenzione Dart dice di no, ma questo è un monorepo chiuso e la riproducibilità della build vale di più | Solo se `micro_core` venisse pubblicato |
| `Money` non ha un'allocazione che conservi il totale | Nessuna app deve ripartire importi | Quando servirà, va scritta e non improvvisata |

# codebase_reference.md — `micro_core`

> Atlante del package condiviso delle MicroApps.
> **Obiettivo di questo documento**: capire il codice, trovare ciò che serve e modificarlo
> **senza aprire i file**. Se per sapere che firma ha un metodo bisogna leggere il sorgente,
> questo documento ha fallito.
>
> **Aggiornato al**: 2026-09-10 · **Versione repo**: `v1.2.0`
> **Toolchain**: Flutter 3.47.3 · Dart 3.13.3 (in `.flutter/`, vedi `develop_microapps.md` §5.8)

---

## 1. Dove sta cosa

| Cerchi… | Vai in |
|---|---|
| La superficie pubblica del package | `lib/micro_core.dart` (barrel) |
| Il tipo di esito per gli errori attesi | `lib/src/util/result.dart` → `Result`, `Ok`, `Err`, `MicroError` |
| I codici d'errore condivisi | `lib/src/util/result.dart` → `MicroErrorCodes` |
| Le date senza fuso orario | `lib/src/util/civil_date.dart` → `CivilDate` |
| La configurazione di un'app (appId, SKU, colori, billing) | `lib/src/config/micro_app_config.dart` → `MicroAppConfig` |
| Quali funzioni sono a pagamento | `lib/src/gate/feature_key.dart` → `FeatureKey` |
| Quanto ne concede il piano gratuito | `lib/src/gate/feature_limits.dart` → `FeatureLimit`, `FeatureLimits` |
| Se l'utente può fare una cosa | `lib/src/gate/feature_gate.dart` → `FeatureGate`, `GateVerdict` |
| Perché una funzione è bloccata | `lib/src/gate/feature_gate.dart` → `BlockReason` |
| Cosa dimostrano i test | §7 di questo documento |
| Cosa **non** esiste ancora | §9 di questo documento |

---

## 2. Albero dei file

Solo il codice scritto da noi. `.dart_tool/`, `build/` e le dipendenze sono esclusi.

```
packages/micro_core/
├─ pubspec.yaml                       name: micro_core, publish_to: none
├─ analysis_options.yaml              include: ../../analysis_options.yaml
├─ codebase_reference.md              questo file
├─ lib/
│  ├─ micro_core.dart                 BARREL: unica cosa che le app importano
│  └─ src/
│     ├─ config/
│     │  └─ micro_app_config.dart     BillingMode, MicroAppConfig
│     ├─ gate/
│     │  ├─ feature_key.dart          FeatureKey (13 valori)
│     │  ├─ feature_limits.dart       FeatureLimit, FeatureLimits, _LimitKind
│     │  └─ feature_gate.dart         GateVerdict, GateAllowed, GateBlocked,
│     │                               BlockReason, FeatureGate
│     └─ util/
│        ├─ result.dart               Result, Ok, Err, MicroError, MicroErrorCodes
│        └─ civil_date.dart           CivilDate
└─ test/
   ├─ gate/feature_gate_test.dart     20 test
   └─ util/civil_date_test.dart       28 test
```

**Regola del barrel**: le app importano solo `package:micro_core/micro_core.dart`. Mai
`package:micro_core/src/...`. Quello che non è esportato dal barrel è dettaglio interno e può
cambiare senza preavviso.

Esportazioni correnti del barrel, in ordine alfabetico:

```dart
export 'src/config/micro_app_config.dart';
export 'src/gate/feature_gate.dart';
export 'src/gate/feature_key.dart';
export 'src/gate/feature_limits.dart';
export 'src/util/civil_date.dart';
export 'src/util/result.dart';
```

---

## 3. Dipendenze

| Pacchetto | Vincolo | Perché |
|---|---|---|
| `flutter` | sdk | `Color`, `Brightness`, `kReleaseMode` |
| `meta` | `^1.19.0` | `@immutable`, `@protected` |
| `flutter_test` | sdk (dev) | test |
| `flutter_lints` | `^5.0.0` (dev) | lint |

**Le versioni non si scrivono a mano**: si usa `pwsh tool/fl.ps1 pub add <pacchetto>`. Un
vincolo inventato a memoria fa fallire la risoluzione o blocca l'aggiornamento di altro.

---

## 4. `lib/src/util/result.dart`

### `sealed class Result<T>`

Esito di un'operazione che può fallire per cause **attese**. Le eccezioni restano per i bug:
rete assente, file corrotto o acquisto annullato non sono bug, sono esiti. Questo evita il
`try/catch` decorativo attorno a ogni chiamata e rende impossibile dimenticare il ramo
d'errore, perché `fold` lo richiede.

| Membro | Firma | Effetto |
|---|---|---|
| `isOk` | `bool get isOk` | `true` se è un `Ok` |
| `isErr` | `bool get isErr` | `true` se è un `Err` |
| `valueOrNull` | `T? get valueOrNull` | Il valore, `null` se errore |
| `errorOrNull` | `MicroError? get errorOrNull` | L'errore, `null` se successo |
| `orElse` | `T orElse(T fallback)` | Il valore, oppure `fallback` |
| `fold` | `R fold<R>({required R Function(T value) ok, required R Function(MicroError error) err})` | Riduce i due rami a un valore. **Entrambi obbligatori.** |
| `map` | `Result<R> map<R>(R Function(T value) transform)` | Trasforma il valore, propaga l'errore |
| `flatMap` | `Result<R> flatMap<R>(Result<R> Function(T value) transform)` | Concatena un'altra operazione fallibile |

### `final class Ok<T> extends Result<T>`

| Membro | Firma |
|---|---|
| costruttore | `const Ok(this.value)` |
| campo | `final T value` |
| uguaglianza | per valore, su `value` |

### `final class Err<T> extends Result<T>`

| Membro | Firma |
|---|---|
| costruttore | `const Err(this.error)` |
| campo | `final MicroError error` |
| uguaglianza | per valore, su `error` |

### `class MicroError`

| Membro | Firma | Note |
|---|---|---|
| costruttore | `const MicroError({required String code, required String message, Object? cause, StackTrace? stackTrace})` | |
| da eccezione | `factory MicroError.unexpected(Object cause, [StackTrace? stackTrace])` | `code` = `'unexpected'` |
| campi | `final String code`, `final String message`, `final Object? cause`, `final StackTrace? stackTrace` | |
| uguaglianza | su `code` e `message` | |

⚑ **`code` non è un messaggio**: è un identificatore stabile su cui il chiamante ramifica, e
non cambia quando si riscrive o si traduce il testo. `message` è per i log, **non per la UI**:
le stringhe mostrate all'utente vivono negli ARB dell'app.

### `abstract final class MicroErrorCodes`

Costanti `static const String`: `network`, `timeout`, `unauthorized`, `notFound`,
`rateLimited`, `badResponse`, `io`, `corruptedFile`, `unsupportedVersion`,
`billingUnavailable`, `purchaseCanceled`, `purchaseFailed`, `permissionDenied`, `unexpected`.

I moduli possono definirne altri, purché documentati nel proprio atlante.

---

## 5. `lib/src/util/civil_date.dart`

### `final class CivilDate implements Comparable<CivilDate>`

Una data del calendario, **senza ora e senza fuso**. Implementa ADR-008.

⚑ **Perché esiste**: "la raccolta dell'organico è lunedì" e "il ragù è stato congelato il 4
settembre" non sono istanti. Rappresentandoli con `DateTime` ci si porta dietro un'ora e un
fuso che non esistono, e il risultato è che il cambio dell'ora legale sposta la data di un
giorno per alcuni utenti in alcune settimane dell'anno. È il bug classico dei calendari:
difficilissimo da riprodurre e devastante per un'app la cui unica funzione è dire il giorno
giusto.

**Serializzazione**: sempre TEXT `YYYY-MM-DD`. Gli istanti veri (creazione record, verifica
licenza) restano `DateTime` in millisecondi UTC.

#### Costruttori

| Firma | Effetto |
|---|---|
| `factory CivilDate(int year, int month, int day)` | Normalizza i valori fuori intervallo come fa `DateTime`: `CivilDate(2026, 13, 1)` → 2027-01-01 |
| `factory CivilDate.fromDateTime(DateTime dt)` | Legge la parte data nel fuso **locale** |
| `factory CivilDate.today({DateTime? now})` | Oggi. `now` serve ai test per fissare il presente |
| `factory CivilDate.parse(String iso)` | `YYYY-MM-DD`. Lancia `FormatException` se non lo è |
| `static CivilDate? tryParse(String? iso)` | Come sopra, ma restituisce `null` |
| `factory CivilDate.fromEpochDay(int epochDay)` | Dalla distanza in giorni dal 1970-01-01 |

#### Campi e proprietà

| Membro | Firma | Note |
|---|---|---|
| `year` / `month` / `day` | `final int` | |
| `weekday` | `int get weekday` | `DateTime.monday`…`DateTime.sunday` |
| `epochDay` | `int get epochDay` | Giorni dal 1970-01-01. **Calcolato in UTC**, vedi trappola §8 |
| `daysInMonth` | `int get daysInMonth` | |
| `firstDayOfMonth` | `CivilDate get firstDayOfMonth` | |
| `lastDayOfMonth` | `CivilDate get lastDayOfMonth` | |

#### Metodi

| Firma | Effetto |
|---|---|
| `String toIso()` | `YYYY-MM-DD`, la forma canonica che va nel database |
| `DateTime toLocalMidnight()` | Mezzanotte locale di questa data |
| `DateTime toLocalDateTime(int hour, [int minute = 0])` | Questa data all'ora locale indicata |
| `CivilDate addDays(int days)` | |
| `CivilDate addMonths(int months)` | **Con clamp a fine mese**, vedi §8 |
| `CivilDate addYears(int years)` | Delega a `addMonths(years * 12)` |
| `int daysUntil(CivilDate other)` | Positivo se `other` è successiva |
| `bool isBefore(CivilDate other)` | |
| `bool isAfter(CivilDate other)` | |
| `bool isSameOrBefore(CivilDate other)` | |
| `bool isSameOrAfter(CivilDate other)` | |
| `bool isToday({DateTime? now})` | |
| `Iterable<CivilDate> rangeTo(CivilDate end)` | Inclusivo agli estremi. Vuoto se `end` precede |
| `int compareTo(CivilDate other)` | Cronologico |
| `String toString()` | Coincide con `toIso()` |

---

## 6. `lib/src/config/micro_app_config.dart`

### `enum BillingMode { fake, play }`

Quale implementazione di acquisto usare (ADR-006). `fake` è in-memory e deterministica, serve
a sviluppare e testare tutto il flusso del paywall senza aver caricato l'app su Play Console.

### `class MicroAppConfig`

Vive qui e non nelle app perché la **forma** è identica in tutte e quattro: cambiano solo i
valori. Ogni app espone una funzione `build<Nome>Config()`.

⚑ `micro_core` non conosce nessuna app: qui non c'è nessun elenco di `appId`, nessuno `switch`
sul nome. Aggiungere una quinta app non richiede di toccare questo file.

| Membro | Firma |
|---|---|
| costruttore | `const MicroAppConfig({required String appId, required String appName, required String proSku, required Color seedColor, required String fontFamily, required Brightness defaultBrightness, required BillingMode billingMode, String? displayFontFamily, Uri? licenseBaseUrl, String appSecret = ''})` |
| da ambiente | `factory MicroAppConfig.fromEnvironment({required String appId, required String appName, required String proSku, required Color seedColor, required String fontFamily, required Brightness defaultBrightness, String? displayFontFamily})` |
| | `bool get serverEnabled` — `licenseBaseUrl != null && appSecret.isNotEmpty` |
| | `bool get usesRealBilling` — `billingMode == BillingMode.play` |
| | `void assertUsableInRelease()` — lancia `StateError` se release + `BILLING=fake` |

#### Chiavi di configurazione (`--dart-define`)

| Define | Valori | Default | Significato |
|---|---|---|---|
| `BILLING` | `fake` \| `play` | `fake` in debug, `play` in release | Quale gateway di acquisto usare |
| `MA_LICENSE_URL` | URL | assente | Base del License Server. Assente = nessuna verifica lato server, l'app funziona lo stesso (ADR-007) |
| `MA_APP_SECRET` | stringa | vuota | Segreto HMAC per firmare le chiamate al server (ADR-014) |

☠ **`appSecret` non è un segreto vero**: sta dentro l'APK e chi decompila lo trova. Serve a
tenere fuori il traffico casuale, non a proteggere l'entitlement, che è protetto dalla verifica
dell'acquisto presso Google.

---

## 7. `lib/src/gate/` — il gating Pro

Implementa ADR-017: ogni limite del piano gratuito è dichiarato in **un'unica mappa per app**
e valutato da `FeatureGate`. Nessuna pagina scrive `if (isPro)` a mano.

⚑ **Perché**: i limiti cambiano, spostare il tetto gratuito dopo il lancio è normale. Se il
valore è sparso in venti file diventa un refactoring invece che una riga. In più il paywall
costruisce l'elenco dei benefici leggendo la stessa mappa, così non esistono due testi che
dicono cose diverse sullo stesso limite.

### `enum FeatureKey`

13 valori, condivisi da tutte e quattro le app: `unlimitedEntities`, `secondaryEntities`,
`photos`, `statistics`, `fullHistory`, `csvExport`, `pdfReport`, `backupRestore`,
`advancedWidget`, `multipleNotifications`, `calendarSync`, `customCategories`,
`themeCustomization`.

⚑ **Perché una enum condivisa e non una lista per app**: le quattro app vendono le stesse cose
sotto nomi diversi. Il secondo calendario di TrashCan, il secondo freezer di Full Freezer e la
seconda fonte di Scorte Calore sono lo stesso concetto (`unlimitedEntities`). Una enum comune
permette una sola pagina di paywall invece di quattro liste che divergono.

Aggiungere una voce qui **tocca tutte e quattro le app**: si fa solo quando la funzione esiste
davvero in almeno una.

### `class FeatureLimit`

Tre forme, e nessun'altra.

| Firma | Significato | `freeMax` |
|---|---|---|
| `const FeatureLimit.open()` | Sempre disponibile | `null` |
| `const FeatureLimit.count({required int freeMax})` | Gratuita fino a `freeMax` elementi | il valore |
| `const FeatureLimit.locked()` | Solo con Pro | `0` |

| Proprietà | Firma |
|---|---|
| | `final int? freeMax` |
| | `bool get isLockedForFree` |
| | `bool get isCounted` |
| | `bool get isOpen` |

Uguaglianza per valore. `typedef FeatureLimits = Map<FeatureKey, FeatureLimit>`.

### `class FeatureGate`

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `const FeatureGate({required FeatureLimits limits, required bool isPro})` | |
| | `const FeatureGate.unlimited()` | Lascia passare tutto. Per test e anteprime |
| | `FeatureLimit limitOf(FeatureKey key)` | Chiave non dichiarata → `FeatureLimit.open()`, con `assert` in debug |
| | `bool allows(FeatureKey key)` | "Puoi usare questa funzione" |
| | `int? freeLimitOf(FeatureKey key)` | Il tetto, `null` se non si conta |
| | `bool withinLimit(FeatureKey key, int currentCount)` | "Puoi aggiungerne un'altra" |
| | `int? remaining(FeatureKey key, int currentCount)` | Quante altre, mai negativo |
| | `GateVerdict check(FeatureKey key, {int currentCount = 0})` | La verifica completa, con il motivo |
| | `List<FeatureKey> get proOnlyFeatures` | Per l'elenco "cosa sblocchi" del paywall |
| | `List<FeatureKey> get limitedFeatures` | Quelle con un tetto |
| | `FeatureGate copyWith({bool? isPro})` | |

☠ **Distinzione da non confondere**: `allows()` risponde "puoi usare questa funzione",
`withinLimit()` risponde "puoi aggiungerne un'altra". Un utente gratuito che ha già il suo
unico calendario continua a usarlo: il primo è vero, il secondo è falso. Confonderli produce o
un'app che blocca l'accesso a dati esistenti, o un tetto che non tiene.

### `sealed class GateVerdict`

| Sottotipo | Firma | Quando |
|---|---|---|
| `GateAllowed` | `const GateAllowed()` | Si può fare |
| `GateBlocked` | `const GateBlocked({required FeatureKey key, required BlockReason reason, int? freeMax})` | Non si può, e `reason` dice perché |

`enum BlockReason { proOnly, limitReached }`.

`GateVerdict` espone `bool get isAllowed`.

---

## 8. Regole non negoziabili e trappole già disinnescate

### Regole

1. **`micro_core` non conosce nessuna app.** Nessun `if (appId == 'trashcan')`, mai. Tutto ciò
   che varia si passa come parametro. Se aggiungere una quinta app richiedesse di toccare
   questo package, il confine è stato messo nel posto sbagliato.
2. **Le app importano solo il barrel.** `package:micro_core/src/...` è vietato.
3. **Le date civili si serializzano come TEXT `YYYY-MM-DD`**, mai come timestamp.
4. **Nessuna stringa destinata all'utente in questo package.** I testi vivono negli ARB delle
   app: `micro_core` non sa in che lingua parla.
5. **Le versioni delle dipendenze si aggiungono con `pub add`**, non si scrivono a memoria.

### Trappole

☠ **`CivilDate.epochDay` si calcola in UTC, non in locale.** In fuso locale una data a cavallo
del cambio d'ora produce una differenza di 23 o 25 ore, e la divisione per 24 dà il giorno
sbagliato. Il test `attraversare entrambi i cambi conta i giorni giusti` esiste per impedire
che qualcuno "semplifichi" togliendo `utc`.

☠ **`addMonths` fa il clamp a fine mese.** 31 gennaio + 1 mese = 28 febbraio (29 negli anni
bisestili), non 3 marzo. Senza il clamp, la regola "raccolta il 31 di ogni mese" salterebbe i
mesi corti generando date nel mese successivo.

☠ **Il clamp non è permanente.** Chi somma un mese alla volta partendo dal risultato già
clampato resta inchiodato al 28 per sempre. `addMonths` va chiamato sempre sulla data
originale: `gennaio.addMonths(2)` dà il 31 marzo, `gennaio.addMonths(1).addMonths(1)` dà il 28
marzo. Il test `il clamp non e permanente` documenta la differenza.

☠ **Una build di release con `BILLING=fake` regalerebbe il Pro a chiunque.**
`assertUsableInRelease()` va chiamata in `main()` prima di `runApp`. Un crash in fase di
verifica costa incomparabilmente meno di quella release pubblicata.

☠ **`FeatureGate.limitOf` su chiave non dichiarata restituisce `open`, non `locked`.** La
scelta è deliberata: dimenticare una dichiarazione regala una funzione a tutti, il che costa
ricavi ma non rompe niente; il contrario toglierebbe agli utenti gratuiti una funzione che
doveva essere loro, cioè un difetto visibile. Un `assert` in debug segnala comunque la
dimenticanza.

---

## 9. Catalogo dei test

`pwsh tool/test_all.ps1 -Project micro_core` → **48 test, tutti verdi**.

### `test/util/civil_date_test.dart` — 28 test

| Gruppo | Cosa dimostra |
|---|---|
| parse e serializzazione | Round-trip ISO; `tryParse` rifiuta `2026-9-9` senza padding, `09/09/2026`, mese 13, 30 febbraio, e il 29 febbraio di un anno non bisestile; `parse` lancia; `toString` == `toIso` |
| ora legale (ADR-008) | Il 29 marzo e il 25 ottobre 2026, cioè i due cambi d'ora italiani, non slittano di un giorno; contare i giorni attraverso entrambi dà 245 |
| aritmetica sui mesi | 31 gennaio → 28 febbraio, e → 29 in anno bisestile; 31 marzo → 30 aprile; il clamp non è permanente; mesi negativi; `addYears` clampa il 29 febbraio |
| anni bisestili | Regola dei 400 anni: 2000 sì, 1900 no |
| epochDay e ordinamento | Epoca a 0, giorni negativi prima del 1970, `fromEpochDay` inverte `epochDay`, ordinamento cronologico, confronti ai bordi |
| giorno della settimana | 9 settembre 2026 è mercoledì; il weekday è stabile attraverso i cambi d'ora |
| intervalli | `rangeTo` inclusivo, vuoto se invertito, un solo giorno; primo e ultimo del mese |
| costruzione da DateTime | Un istante UTC viene letto nel fuso locale; `today` accetta un presente fissato |
| normalizzazione | Mese 13, giorno 32, mese 0 |
| uguaglianza | Per valore, con `hashCode` coerente |

### `test/gate/feature_gate_test.dart` — 20 test

| Gruppo | Cosa dimostra |
|---|---|
| funzioni sempre aperte | Disponibili con e senza Pro, nessun tetto |
| funzioni solo Pro | Bloccate senza Pro con `BlockReason.proOnly`; aperte con Pro; il conteggio non le sblocca |
| bordi del tetto | Con tetto 1 e con tetto 3, i quattro bordi: 0, `freeMax−1`, `freeMax`, `freeMax+1`; `remaining` non va sotto zero; la funzione resta **accessibile** anche a tetto raggiunto; con Pro il tetto non esiste |
| elenchi per il paywall | `proOnlyFeatures` e `limitedFeatures` classificano correttamente e non dipendono dallo stato Pro |
| cancello senza limiti | `FeatureGate.unlimited()` lascia passare tutti i 13 `FeatureKey` |
| copyWith | Cambia solo `isPro`, condivide la mappa, non muta l'originale |
| forme di FeatureLimit | Le tre forme e l'uguaglianza per valore |

---

## 10. Cosa NON esiste ancora

Elenco esplicito, per non farlo cercare invano. La numerazione rimanda alle sottofasi di
`develop_microapps.md` §7.

| Non esiste | Sottofase che lo creerà |
|---|---|
| `Money` (importi in centesimi interi) | F1.2 |
| `MicroLog` (log su file a rotazione) | F1.2 |
| `AppPaths` (cartelle dell'app) | F1.2 |
| `AtomicFile` (scrittura atomica) | F1.2 |
| `SettingsStore` (preferenze tipizzate) | F1.3 |
| `InstallId` (UUID persistente) | F1.4 |
| `MicroTheme`, `MicroSpacing`, `MicroRadius`, i token del design system | F1.5 |
| Tutti i widget `Micro*` (card, stat tile, empty state, bottone, chip, sheet, snack) | F1.6 |
| `PurchaseGateway`, `PlayPurchaseGateway`, `FakePurchaseGateway`, `MicroProduct`, `PurchaseEvent` | F1.7 |
| `Entitlement`, `EntitlementStore`, `EntitlementService`, `LicenseApiClient` | F1.8 |
| `ProLock`, `ProBadge`, `PaywallPage`, `PaywallConfig` | F1.9 |
| `NotificationService` e i canali di notifica | F1.10 |
| `BackupSource`, `BackupService`, `JsonBackupCodec`, `CsvWriter`, `PdfReportBuilder`, `ImageStore` | F1.11 |
| La app di galleria dei componenti (`example/`) | F1.6 |
| Qualsiasi supporto iOS testato | non previsto (DT-01) |

**Nota su `MicroAppConfig`**: la prima stesura del piano diceva di definirla in ogni app. Era
sbagliato, quattro definizioni identiche divergono al primo ritocco. Ora vive qui e le app
passano solo i valori.

---

## 11. Debito tecnico aperto

| Voce | Perché è rimandata | Quando affrontarla |
|---|---|---|
| `WeeklyRecurrence` e simili nelle app accettano `Set` mutabili in costruttori `const` | Renderli non modificabili impedirebbe il `const`, che serve nei test | Se emerge un bug da mutazione condivisa |
| Nessun test di `MicroAppConfig.fromEnvironment` | Legge `String.fromEnvironment`, che è costante di compilazione: testarlo richiede build separate con `--dart-define` diversi | F3.12, insieme alla verifica end-to-end del billing |
| `pubspec.lock` committato anche per il package libreria | Convenzione Dart dice di non farlo per le librerie. Qui è un monorepo chiuso e la riproducibilità della build vale più della convenzione | Da rivedere solo se `micro_core` venisse pubblicato |

# codebase_reference.md — TrashCan

> Atlante dell'app **TrashCan**, il calendario personale della raccolta differenziata.
> **Obiettivo**: capire il codice, trovare ciò che serve e modificarlo **senza aprire i file**.
>
> **Aggiornato al**: 2026-09-10 · **Versione repo**: `v1.2.0` · **versionName+Code**: `0.1.0+1`
> **Package Android**: `com.smp.trashcan` (immutabile dopo il primo upload su Play)
> **SKU Pro**: `trashcan_pro_lifetime` — 2,99 € una tantum
>
> Quello che questa app prende da `micro_core` **non è ricopiato qui**: si rimanda a
> `packages/micro_core/codebase_reference.md`. Una firma copiata in due posti diverge in due
> settimane.

---

## 1. Dove sta cosa

| Cerchi… | Vai in |
|---|---|
| Quali giorni passa la raccolta | `lib/domain/recurrence.dart` → `Recurrence` e le 5 sottoclassi |
| Come si espandono le regole in date concrete | `lib/domain/occurrence_engine.dart` → `OccurrenceEngine` |
| Cosa butto stasera | `OccurrenceEngine.tonight()` — **restituisce la raccolta di domani**, vedi §6 |
| Salta / sposta / raccolta straordinaria | `lib/domain/occurrence_engine.dart` → `CollectionException` |
| Come i giorni finiscono nel database | `lib/domain/recurrence.dart` → `WeekdayMask` |
| Cosa è a pagamento | `lib/app/feature_limits.dart` → `trashcanFeatureLimits` |
| appId, SKU, colore, font | `lib/app/app_config.dart` → `buildTrashcanConfig()` |
| Quale lingua vede l'utente | `lib/app/locale_resolution.dart` → `resolveAppLocale` |
| I percorsi di navigazione e i deep link | `lib/app/routes.dart` → `Routes` |
| Icone e colori dei tipi di rifiuto | `lib/app/waste_presets.dart` → `WasteIcons`, `WastePalette`, `kWastePresets` |
| I testi in italiano e inglese | `lib/l10n/app_it.arb`, `lib/l10n/app_en.arb` |
| Cosa dimostrano i test | §8 |
| Cosa **non** esiste ancora | §10 |

---

## 2. Albero dei file

```
apps/trashcan/
├─ pubspec.yaml                       version: 0.1.0+1
├─ l10n.yaml                          config di gen_l10n
├─ analysis_options.yaml              include: ../../analysis_options.yaml
├─ codebase_reference.md              questo file
├─ assets/
│  ├─ fonts/
│  │  ├─ Outfit-Variable.ttf          111 KB, tutti i pesi
│  │  └─ OFL.txt                      SIL Open Font License 1.1
│  └─ images/                         vuota
├─ lib/
│  ├─ app/
│  │  ├─ app_config.dart              buildTrashcanConfig()
│  │  ├─ feature_limits.dart          trashcanFeatureLimits
│  │  ├─ locale_resolution.dart       kSupportedLocales, resolveAppLocale()
│  │  ├─ routes.dart                  Routes
│  │  └─ waste_presets.dart           WasteIcons, WastePalette, WastePreset, kWastePresets
│  ├─ domain/
│  │  ├─ recurrence.dart              Recurrence + 5 sottoclassi, WeekdayMask
│  │  └─ occurrence_engine.dart       OccurrenceOrigin, CollectionOccurrence,
│  │                                  CollectionException, RuleWithExceptions,
│  │                                  OccurrenceEngine
│  └─ l10n/
│     ├─ app_en.arb                   TEMPLATE, 154 chiavi
│     ├─ app_it.arb                   154 chiavi, zero non tradotte
│     └─ generated/                   generato, ignorato da git
└─ test/
   └─ domain/occurrence_engine_test.dart   40 test
```

**Non esistono ancora** `lib/data/`, `lib/features/`, `lib/services/`, `lib/main.dart`,
`android/`. Vedi §10.

⚑ **Perché `domain/` non importa Flutter**: i motori di calcolo sono la parte in cui un errore
è invisibile e costoso. Tenendoli liberi da Flutter si testano in millisecondi, senza
`WidgetTester`, e si può girare l'intera suite a ogni salvataggio. I 40 test del motore girano
in meno di un secondo.

---

## 3. Dipendenze

| Pacchetto | Vincolo | Perché |
|---|---|---|
| `flutter` | sdk | |
| `flutter_localizations` | sdk | ADR-011 |
| `meta` | `^1.19.0` | `@immutable` |
| `micro_core` | `path: ../../packages/micro_core` | nucleo condiviso |
| `flutter_test`, `integration_test` | sdk (dev) | |
| `flutter_lints` | `^5.0.0` (dev) | |

**Ancora da aggiungere** (F3.2 in poi): `flutter_riverpod`, `go_router`, `drift`,
`sqlite3_flutter_libs`, `drift_dev`, `build_runner`, `home_widget`, `in_app_review`.

---

## 4. Localizzazione

Implementa ADR-011: **italiano sui dispositivi italiani, inglese su tutti gli altri.**

### `lib/app/locale_resolution.dart`

| Membro | Firma |
|---|---|
| | `const List<Locale> kSupportedLocales` = `[Locale('en'), Locale('it')]` |
| | `Locale resolveAppLocale(List<Locale>? deviceLocales, Iterable<Locale> supported)` |

Comportamento: se una qualunque delle lingue preferite del dispositivo ha `languageCode == 'it'`
restituisce `Locale('it')`; in ogni altro caso `Locale('en')`. Si guarda solo il codice lingua,
così `it`, `it_IT` e `it_CH` ricevono tutti l'italiano.

☠ **L'ordine di `kSupportedLocales` non è estetico.** Quando il dispositivo non corrisponde a
nessuna lingua supportata, Flutter ripiega sul **primo** elemento della lista. Con `it` per
primo, un utente tedesco riceverebbe l'italiano.

⚑ **Perché non si segue tutta la lista di preferenze del dispositivo**: un utente con
preferenze `[de, it, en]` riceverebbe l'italiano perché precede l'inglese. È difendibile in
astratto, ma sorprende: chi ha il telefono in tedesco si aspetta l'inglese come ripiego.

### `l10n.yaml`

| Chiave | Valore | Perché |
|---|---|---|
| `arb-dir` | `lib/l10n` | |
| `template-arb-file` | **`app_en.arb`** | `gen_l10n` garantisce la completezza del solo template e ci ripiega per le chiavi mancanti altrove. Essendo l'inglese la lingua di ripiego, una chiave dimenticata deve produrre una parola inglese in un'app italiana, non il contrario |
| `output-class` | `L` | |
| `output-dir` | `lib/l10n/generated` | ignorata da git, si rigenera |
| `untranslated-messages-file` | `lib/l10n/untranslated.json` | elenca a ogni build le chiavi senza traduzione italiana |
| `nullable-getter` | `false` | |

**Stato**: 154 chiavi per lingua, `untranslated.json` vuoto.

Prefissi delle chiavi: `common_`, `home_`, `onboarding_`, `waste_`, `wasteTypes_`, `rules_`,
`exceptions_`, `notifications_`, `calendars_`, `settings_`, `paywall_`, `gate_`, `error_`.

---

## 5. `lib/domain/recurrence.dart`

### `sealed class Recurrence`

| Membro | Firma | Note |
|---|---|---|
| costruttore | `const Recurrence({required CivilDate startDate, CivilDate? endDate})` | |
| | `final CivilDate startDate` | prima data possibile |
| | `final CivilDate? endDate` | `null` = non scade |
| | `bool occursOn(CivilDate date)` | controlla la finestra, poi delega a `matches` |
| | `@protected bool matches(CivilDate date)` | il criterio della sottoclasse |
| | `Iterable<CivilDate> occurrencesIn(CivilDate from, CivilDate to)` | inclusivo, scandisce giorno per giorno |

⚑ **Perché `occurrencesIn` scandisce i giorni invece di calcolare**: per le finestre in gioco
(60 giorni per le notifiche, un anno per la vista mensile) sono qualche centinaio di confronti
interi per regola. Non vale la pena di ottimizzare a scapito della leggibilità di un calcolo
che deve essere **ovviamente** corretto.

### Le cinque sottoclassi

| Classe | Costruttore | Quando |
|---|---|---|
| `WeeklyRecurrence` | `const WeeklyRecurrence({required Set<int> weekdays, required CivilDate startDate, CivilDate? endDate})` | "organico lunedì e giovedì" — il caso più comune |
| `EveryNWeeksRecurrence` | `EveryNWeeksRecurrence({required Set<int> weekdays, required int intervalWeeks, required CivilDate anchorDate, required CivilDate startDate, CivilDate? endDate})` | "carta a mercoledì alterni" |
| `MonthlyDayRecurrence` | `const MonthlyDayRecurrence({required int dayOfMonth, required CivilDate startDate, CivilDate? endDate})` | "il 15 di ogni mese" |
| `MonthlyNthWeekdayRecurrence` | `const MonthlyNthWeekdayRecurrence({required int nth, required int weekday, required CivilDate startDate, CivilDate? endDate})` | "l'ultimo venerdì del mese" (`nth == -1`) |
| `ManualDatesRecurrence` | `ManualDatesRecurrence({required Iterable<CivilDate> dates, required CivilDate startDate, CivilDate? endDate})` | elenco di date pubblicato dal Comune |

`weekdays` usa `DateTime.monday`…`DateTime.sunday`. `nth` vale 1..5 oppure −1.
`EveryNWeeksRecurrence` ha `assert(intervalWeeks >= 2)`: con intervallo 1 si usa
`WeeklyRecurrence`.

⚑ **Perché `anchorDate` esiste**: "la carta si raccoglie i mercoledì alterni" è ambiguo finché
non si sa **quale** mercoledì. L'ancora è la data che l'utente indica come prossima raccolta.
Il ciclo si calcola contando le settimane rispetto a quella, **in entrambe le direzioni**, così
il calendario mostra correttamente anche il passato.

☠ **Non si usa il numero di settimana ISO.** Cambia significato a cavallo dell'anno: la
settimana 1 del 2027 ripartirebbe da capo e produrrebbe un salto o un raddoppio tra dicembre e
gennaio. Il test `a cavallo del 31 dicembre non si salta ne si raddoppia` verifica che
l'intervallo resti di 14 giorni esatti attraverso il capodanno.

⚑ **Perché il modulo funziona anche all'indietro**: in Dart `%` con divisore positivo
restituisce sempre un risultato non negativo, quindi `weeksApart % intervalWeeks == 0` vale
anche per le settimane precedenti all'ancora. Chi portasse questo codice in un linguaggio dove
`%` conserva il segno del dividendo (C, Java, JavaScript) romperebbe le date passate senza
accorgersene.

### `abstract final class WeekdayMask`

| Firma | Effetto |
|---|---|
| `static int fromSet(Set<int> weekdays)` | Bit 0 = lunedì, bit 6 = domenica |
| `static Set<int> toSet(int mask)` | Inverso |

⚑ **Perché una bitmask in colonna invece di una tabella figlia**: sono al massimo sette valori,
non si interrogano mai singolarmente, e una colonna intera evita una join a ogni lettura del
calendario.

---

## 6. `lib/domain/occurrence_engine.dart`

### `enum OccurrenceOrigin { regular, moved, extra }`

Da dove viene una raccolta comparsa nel calendario.

### `class CollectionOccurrence`

| Membro | Firma |
|---|---|
| costruttore | `const CollectionOccurrence({required int wasteTypeId, required CivilDate date, required OccurrenceOrigin origin, CivilDate? originalDate, String? note})` |
| | `bool get isRegular` |

`originalDate` è valorizzato solo per le raccolte spostate: è la data in cui sarebbe caduta
senza eccezione.

### `class CollectionException`

Le tre forme ammesse, e nessun'altra:

| Caso | `originalDate` | `replacementDate` | `skipped` |
|---|---|---|---|
| Salta | data | `null` | `true` |
| Sposta | data | data | `false` |
| Straordinaria | `null` | data | `false` |

| Firma | Effetto |
|---|---|
| `const CollectionException({required int id, required int wasteTypeId, CivilDate? originalDate, CivilDate? replacementDate, bool skipped = false, String? note})` | |
| `factory CollectionException.skip({required int id, required int wasteTypeId, required CivilDate date, String? note})` | |
| `factory CollectionException.move({required int id, required int wasteTypeId, required CivilDate from, required CivilDate to, String? note})` | |
| `factory CollectionException.extra({required int id, required int wasteTypeId, required CivilDate date, String? note})` | |
| `bool get isSkip` / `isMove` / `isExtra` / `isWellFormed` | |

☠ Un'eccezione malformata (combinazione di campi non prevista) viene **ignorata**, non fa
lanciare. Un record storto nel database non deve rendere inutilizzabile il calendario.

### `class RuleWithExceptions`

`const RuleWithExceptions({required int wasteTypeId, required Recurrence recurrence, List<CollectionException> exceptions = const [], int sortOrder = 0})`

### `class OccurrenceEngine`

| Firma | Effetto |
|---|---|
| `const OccurrenceEngine()` | senza stato |
| `List<CollectionOccurrence> expand({required List<RuleWithExceptions> rules, required CivilDate from, required CivilDate to})` | tutte le raccolte nella finestra, ordinate |
| `List<CollectionOccurrence> onDate(CivilDate date, {required List<RuleWithExceptions> rules})` | |
| `List<CollectionOccurrence> tonight({required List<RuleWithExceptions> rules, CivilDate? today})` | **la raccolta di domani**, vedi sotto |
| `CollectionOccurrence? next({required List<RuleWithExceptions> rules, CivilDate? from, int horizonDays = 400})` | |
| `List<CollectionOccurrence> nextN(int count, {required List<RuleWithExceptions> rules, CivilDate? from, int horizonDays = 800})` | |

#### L'ordine delle fasi di `expand` è vincolante

1. genera le occorrenze base dalle regole;
2. applica i **salti**, togliendo le date annullate;
3. applica gli **spostamenti**, togliendo l'originale e aggiungendo la nuova data;
4. aggiunge le **straordinarie**;
5. deduplica per `(tipo, data)` con priorità `extra` > `moved` > `regular`;
6. ordina per data, poi per `sortOrder` del tipo, poi per `wasteTypeId`.

☠ **Il passo 2 deve precedere il 3.** Uno spostamento su una data già saltata non deve far
riapparire la raccolta. Invertendo i due passi si otterrebbe quel comportamento, che è
sbagliato e quasi impossibile da diagnosticare a posteriori. Il test
`salta e sposta la stessa data: prevale il salto` lo blocca.

☠ **Uno spostamento verso una data fuori finestra fa sparire comunque l'originale.** È
corretto: quel giorno la raccolta non c'è più, indipendentemente da dove sia finita.

☠ **Uno spostamento da una data che la regola non genera non inventa raccolte.** L'aggiunta
avviene solo se `recurrence.occursOn(originalDate)`.

#### `tonight()` restituisce la raccolta di DOMANI

`tonight() == onDate(today.addDays(1))`. Non è un errore: **stasera si porta fuori quello che
raccolgono domani mattina.** È la regola di prodotto più importante dell'app, sembra sbagliata
a chi legge il codice di sfuggita, e prima o poi qualcuno vorrà "correggerla". Il commento nel
sorgente e il test `tonight mostra la raccolta di DOMANI` esistono per impedirlo.

☠ **Trappola di prestazioni, ancora da disinnescare.** `expand` è O(giorni × regole) e alloca
un oggetto per ogni raccolta: `next()` con orizzonte 400 giorni ne costruisce qualche centinaio.
È irrilevante una volta, **disastroso se chiamato a ogni frame**. Quando si scriverà la home
(F3.5), le occorrenze devono venire da un provider che le calcola una volta sola e le ricalcola
solo quando cambiano i dati o la data. **Nessun `build` deve chiamare `expand`, `next` o
`tonight` direttamente.**

---

## 7. `lib/app/`

### `app_config.dart`

`MicroAppConfig buildTrashcanConfig()` → `MicroAppConfig.fromEnvironment(...)` con:

| Campo | Valore |
|---|---|
| `appId` | `trashcan` |
| `appName` | `TrashCan` |
| `proSku` | `trashcan_pro_lifetime` — **immutabile dopo la pubblicazione** |
| `seedColor` | `#2E7D5B` |
| `fontFamily` | `Outfit` |
| `defaultBrightness` | `Brightness.light` |

La classe `MicroAppConfig` sta in `micro_core`: qui ci sono solo i valori.

### `feature_limits.dart`

`const FeatureLimits trashcanFeatureLimits`.

| FeatureKey | Limite | Cosa significa per l'utente |
|---|---|---|
| `unlimitedEntities` | `count(freeMax: 1)` | Un calendario gratis, illimitati con Pro |
| `multipleNotifications` | `locked()` | Un solo orario di promemoria nel piano gratuito |
| `advancedWidget` | `locked()` | Widget a colori, scelta del calendario, prossimi tre giorni |
| `backupRestore` | `locked()` | Backup completo e ripristino |
| `themeCustomization` | `locked()` | Colori e icone liberi |
| `csvExport` | `locked()` | |
| `secondaryEntities`, `photos`, `statistics`, `fullHistory`, `pdfReport`, `calendarSync`, `customCategories` | `open()` | TrashCan non le vende e non le limita |

⚑ **Perché il piano gratuito è così generoso**: TrashCan gratuito deve essere l'app migliore
della categoria, altrimenti non viene installata e non c'è nessuno a cui vendere il Pro.
Restano gratuiti tipi di rifiuto, regole ed eccezioni illimitati, il promemoria serale, il
widget di base e la condivisione del calendario.

⚑ **Perché la condivisione di un calendario è gratuita e il backup no**: la condivisione è un
canale di acquisizione, un utente ne porta un altro. Il backup è una comodità personale.
Regalare l'acquisizione e vendere la comodità è il verso giusto.

⚑ **Perché le sette funzioni aperte sono dichiarate esplicitamente**: non è ridondanza. Evita
l'`assert` di `FeatureGate` sulle chiavi non dichiarate e rende leggibile in un colpo d'occhio
cosa **non** è a pagamento.

### `routes.dart`

`abstract final class Routes` — costanti `static const String`: `home`, `onboarding`,
`calendars`, `calendarNew`, `calendarEdit`, `wasteTypes`, `wasteTypeNew`, `wasteTypeEdit`,
`rules`, `ruleNew`, `ruleEdit`, `exceptions`, `day`, `settings`, `notifications`, `about`,
`paywall`, `scheme` (= `'trashcan'`).

Helper: `static String dayOf(String isoDate)`, `static String wasteTypeEditOf(int id)`,
`static String rulesOf(int wasteTypeId)`.

⚑ **Perché costanti e non stringhe sparse**: notifiche e widget Android aprono l'app con un
deep link (`trashcan://day/2026-09-10`). Un percorso scritto a mano in due posti diverge, e il
sintomo è un tap sulla notifica che non porta da nessuna parte.

### `waste_presets.dart`

| Membro | Firma |
|---|---|
| | `abstract final class WasteIcons` — `static const Map<String, IconData> byKey` (22 icone), `static IconData resolve(String? key)`, `static List<String> get allKeys` |
| | `abstract final class WastePalette` — `static const List<Color> colors` (12 colori) |
| | `class WastePreset` — `const WastePreset({required String nameKey, required String iconKey, required Color color})` |
| | `const List<WastePreset> kWastePresets` (9 preset) |

☠ **Il database salva `iconKey`, mai `IconData.codePoint`.** Salvare il codepoint e
ricostruire l'icona con `IconData(codePoint, fontFamily: 'MaterialIcons')` rompe il tree
shaking delle icone: il compilatore non riesce più a sapere quali glifi servono, e in release
Flutter o le rimuove tutte, lasciando quadrati vuoti, oppure obbliga a disattivare
l'ottimizzazione e a imbarcare l'intero font. Con una mappa costante di riferimenti letterali
il tree shaking funziona e l'APK resta piccolo.

☠ `WasteIcons.resolve` **non lancia** su chiave sconosciuta: restituisce `Icons.category`. Una
chiave sconosciuta può arrivare da un calendario importato da una versione più recente
dell'app, e in quel caso l'utente deve vedere un'icona generica, non un crash.

⚑ **Perché i colori della tavolozza sono tutti scuri**: la card "Stasera" usa il colore del
tipo come sfondo del testo più importante dell'app, che deve leggersi a un metro di distanza.
Un giallo chiaro lo renderebbe illeggibile.

---

## 8. Font

`assets/fonts/Outfit-Variable.ttf`, 111 KB, dichiarato una volta sola nel `pubspec.yaml`.

⚑ **Perché un font variabile**: un solo file copre tutti i pesi da 100 a 900, contro i circa
190 KB di quattro istanze statiche.

☠ **Google Fonts non serve più TTF statici via API.** Con uno user agent Internet Explorer
restituisce **EOT**, con uno Android vecchio restituisce **WOFF**: Flutter non legge nessuno dei
due. Il file qui viene dal repository ufficiale `google/fonts`, insieme alla sua licenza
(`OFL.txt`, SIL Open Font License 1.1, che ne consente l'uso commerciale purché il testo della
licenza sia incluso nell'app).

☠ **I pesi si ottengono con `FontVariation`, non dichiarando lo stesso file quattro volte.**
Flutter non interpola da solo: quattro dichiarazioni dello stesso file darebbero sempre
l'istanza predefinita. La configurazione andrà in `MicroTheme` quando verrà scritto (F1.5).

---

## 9. Catalogo dei test

`pwsh tool/test_all.ps1 -Project trashcan` → **40 test, tutti verdi**.

### `test/domain/occurrence_engine_test.dart`

| Gruppo | Test | Cosa dimostra |
|---|---|---|
| settimanale | 5 | Espansione base su 4 settimane; `startDate` e `endDate` delimitano; finestra invertita restituisce lista vuota senza errori; nessuna regola, nessuna occorrenza |
| ogni N settimane | 4 | L'ancora determina la parità; il ciclo vale anche **prima** dell'ancora; a cavallo del 31 dicembre l'intervallo resta di 14 giorni esatti; cadenza di 3 settimane su due giorni |
| mensile per giorno | 3 | Il 31 fa il clamp a 28/29/30 nei mesi corti; in febbraio bisestile cade il 29; un giorno che esiste sempre non viene toccato |
| mensile per ennesimo | 3 | Primo lunedì; ultimo venerdì (`nth == -1`); il quinto lunedì di un mese che ne ha quattro non produce nulla |
| date manuali | 1 | Solo le date elencate, ordinate |
| eccezioni | 8 | Salta; sposta con `origin: moved` e `originalDate`; **salta e sposta insieme: prevale il salto**; spostamento fuori finestra fa sparire comunque l'originale; spostamento da una data non prevista non inventa raccolte; straordinaria con nota; straordinaria che coincide con un'ordinaria resta una sola; eccezione malformata ignorata |
| ordinamento e più regole | 3 | `sortOrder` decide a parità di data; regole diverse si fondono cronologicamente; due regole sullo stesso tipo lo stesso giorno non si duplicano |
| ora legale (ADR-008) | 3 | I due cambi d'ora italiani del 2026 non spostano le raccolte; una cadenza quindicinale attraverso il cambio resta di 14 giorni |
| anno bisestile | 1 | Il 29 febbraio è un giorno come gli altri |
| tonight, next, nextN | 7 | `tonight` mostra **domani**; vuoto quando domani non raccolgono; `next` include oggi; `next` restituisce `null` oltre l'orizzonte; `nextN` restituisce esattamente il numero richiesto; con regola mensile guarda oltre l'anno; `count` zero o negativo dà lista vuota |
| bitmask | 2 | Round-trip su tutte le 128 combinazioni; lunedì è il bit 0, domenica il bit 6 |

### Come sono state validate le date dei test

Le 16 assunzioni sui giorni della settimana e le 8 sequenze attese sono state verificate con
uno script Dart indipendente, prima di far girare i test. Serve a separare due fallimenti che
altrimenti si confondono: un rosso significa che il motore è sbagliato, non che le date attese
lo erano.

Fatti verificati: 2026-09-07 lunedì, 2026-09-09 mercoledì, 2026-03-29 e 2026-10-25 domeniche
(i due cambi d'ora italiani), 2026-12-25 venerdì, 2024-02-29 giovedì; settembre 2026 ha quattro
lunedì e non cinque.

---

## 10. Cosa NON esiste ancora

| Non esiste | Sottofase |
|---|---|
| `lib/main.dart` e l'avvio dell'app | F3.1 |
| Il tema (dipende da `MicroTheme`, F1.5) | F3.1 |
| Il router `go_router` | F3.1 |
| La cartella `android/` e il manifest | F3.1 |
| Lo strato dati Drift: tabelle, DAO, migrazioni | F3.2 |
| Il wizard di setup iniziale | F3.4 |
| La home | F3.5 |
| CRUD di tipi di rifiuto e regole, con anteprima live delle prossime sei date | F3.6 |
| L'interfaccia per le eccezioni | F3.7 |
| `TrashcanScheduler` e le notifiche | F3.8 |
| Calendari multipli e paywall | F3.9 |
| Export, import, backup | F3.10 |
| Il widget Android | F3.11 |
| Test di widget, golden, integrazione | F3.13 |
| Icona dell'app e icona di notifica | F3.14 |

**Il cervello esiste, il corpo no.** Oggi ci sono il motore delle ricorrenze, le traduzioni, le
rotte, i limiti Pro e la configurazione. Non c'è ancora niente che si possa eseguire.

---

## 11. Debito tecnico aperto

| Voce | Perché | Quando |
|---|---|---|
| `expand` chiamabile da `build` senza protezioni | Il provider che lo incapsula non esiste ancora | F3.5, obbligatorio prima della home |
| `WeeklyRecurrence.weekdays` è un `Set` mutabile in un costruttore `const` | Renderlo non modificabile impedirebbe il `const`, comodo nei test | Se emerge un bug da mutazione condivisa |
| `sortOrder` duplicato se due regole dello stesso tipo lo dichiarano diverso | Vince l'ultima. Caso raro e senza conseguenze visibili | Quando esisterà l'editor delle regole |
| `assets/images/` è vuota ma dichiarata nel pubspec | Serve un `.gitkeep` perché la cartella esista | Sparisce quando arrivano le prime immagini |

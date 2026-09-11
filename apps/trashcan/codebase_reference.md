# codebase_reference.md — TrashCan

> Atlante dell'app **TrashCan**, il calendario personale della raccolta differenziata.
> **Obiettivo**: capire il codice, trovare ciò che serve e modificarlo **senza aprire i file**.
>
> **Aggiornato al**: 2026-09-11 · **Fase**: F3 conclusa · **versionName+Code**: `0.1.0+1`
> **Package Android**: `com.smp.trashcan` (immutabile dopo il primo upload su Play)
> **SKU Pro**: `trashcan_pro_lifetime` — 2,99 € una tantum
>
> Quello che questa app prende da `micro_core` **non è ricopiato qui**: si rimanda a
> `packages/micro_core/codebase_reference.md`. Una firma copiata in due posti diverge in due
> settimane.
>
> Stato: l'app gira su Android ed è stata percorsa a mano sull'emulatore in ogni schermata.
> 117 test propri, oltre ai 107 di `micro_core`.

---

## 1. Dove sta cosa

| Cerchi… | Vai in… |
|---|---|
| Quando cade una raccolta | `lib/domain/occurrence_engine.dart` |
| Le cinque forme di ricorrenza | `lib/domain/recurrence.dart` |
| Le tabelle del database | `lib/data/tables.dart` |
| Le query di lettura, il bundle, i mapper riga→dominio | `lib/data/database.dart` |
| Tutte le scritture sul database | `lib/data/repository.dart` |
| I provider Riverpod (radice di tutto) | `lib/app/providers.dart` |
| I percorsi di navigazione | `lib/app/routes.dart` |
| Cosa è gratis e cosa è Pro | `lib/app/feature_limits.dart` |
| I testi e i benefici del paywall | `lib/app/paywall_config.dart` |
| Colori, icone e preset dei tipi di rifiuto | `lib/app/waste_presets.dart` |
| Italiano sì / italiano no | `lib/app/locale_resolution.dart` |
| Il piano delle notifiche | `lib/services/trashcan_scheduler.dart` |
| I colori generali dell'app (funzione Pro) | `lib/app/app_themes.dart` |
| Come si riprende l'acquisto su un telefono nuovo | `lib/features/restore/restore_page.dart` |
| Il contenuto del widget di sistema | `lib/services/trashcan_widget.dart` |
| Export, import, backup | `lib/services/trashcan_backup_source.dart` |
| Il disegno del widget | `android/app/src/main/kotlin/com/smp/trashcan/TrashcanWidgetProvider.kt` |
| Permessi, receiver, widget nel manifest | `android/app/src/main/AndroidManifest.xml` |
| La firma di release | `android/app/build.gradle.kts` + `android/key.properties` (non versionato) |
| Le stringhe tradotte | `lib/l10n/app_en.arb` (template) e `app_it.arb` |

---

## 2. Albero dei file

Solo il codice scritto da noi.

```
apps/trashcan/
├── lib/
│   ├── main.dart                     avvio: config, cartelle, log, preferenze. Niente altro.
│   ├── app/
│   │   ├── app.dart                  GoRouter, MaterialApp, ciclo di vita, tocco sulle notifiche
│   │   ├── app_config.dart           MicroAppConfig di TrashCan (id, SKU, colore, font)
│   │   ├── feature_limits.dart       cosa è gratis e cosa è Pro (ADR-017)
│   │   ├── locale_resolution.dart    italiano sui dispositivi italiani, inglese altrove
│   │   ├── paywall_config.dart       testi e benefici del paywall + showTrashcanPaywall()
│   │   ├── providers.dart            TUTTI i provider Riverpod
│   │   ├── routes.dart               i percorsi, in costanti
│   │   └── waste_presets.dart        icone, tavolozza, preset del wizard
│   ├── data/
│   │   ├── tables.dart               le 4 tabelle Drift
│   │   ├── database.dart             AppDatabase, CalendarBundle, query, mapper riga→dominio
│   │   ├── database.g.dart           generato da drift_dev (non si modifica a mano)
│   │   └── repository.dart           tutte le scritture + mapper dominio→riga
│   ├── domain/
│   │   ├── recurrence.dart           le 5 ricorrenze, pure, senza database
│   │   └── occurrence_engine.dart    espansione regole + eccezioni in raccolte concrete
│   ├── features/
│   │   ├── backup/backup_page.dart
│   │   ├── calendars/calendars_page.dart, calendar_editor_page.dart
│   │   ├── day/day_page.dart         dove porta il tocco su una notifica
│   │   ├── exceptions/exceptions_page.dart, occurrence_actions.dart
│   │   ├── home/home_page.dart       "Stasera", prossima raccolta, prossimi 7 giorni
│   │   ├── notifications/notifications_page.dart
│   │   ├── onboarding/onboarding_page.dart   il wizard in 4 passi
│   │   ├── rules/rule_editor_page.dart, rule_summary.dart, weekday_labels.dart
│   │   ├── settings/settings_page.dart
│   │   └── waste_types/waste_types_page.dart, waste_type_editor_page.dart
│   ├── services/
│   │   ├── trashcan_scheduler.dart   costruisce e consegna il piano delle notifiche
│   │   ├── trashcan_widget.dart      calcola il contenuto del widget di sistema
│   │   └── trashcan_backup_source.dart  export/import
│   └── l10n/
│       ├── app_en.arb                template
│       └── app_it.arb                italiano, zero chiavi non tradotte
├── android/app/src/main/
│   ├── AndroidManifest.xml
│   ├── kotlin/com/smp/trashcan/MainActivity.kt
│   ├── kotlin/com/smp/trashcan/TrashcanWidgetProvider.kt
│   └── res/
│       ├── drawable/ic_notification.xml         icona monocromatica della barra di stato
│       ├── drawable/ic_launcher_foreground.xml  primo piano dell'icona adattiva
│       ├── drawable/widget_background.xml       angoli arrotondati del widget
│       ├── layout/trashcan_widget.xml           il layout del widget (solo RemoteViews)
│       ├── mipmap-anydpi-v26/ic_launcher.xml    icona adattiva + monochrome
│       ├── values/strings.xml, values-it/strings.xml
│       └── xml/trashcan_widget_info.xml
├── test/                             117 test (vedi §9)
└── integration_test/first_run_test.dart
```

---

## 3. Il database

Quattro tabelle, `schemaVersion = 1`. Le date civili sono TEXT `YYYY-MM-DD` (ADR-008), gli
istanti sono interi in millisecondi UTC.

### `collection_calendars`

| Colonna | Tipo | Vincoli | Significato |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `name` | TEXT | 1..60 | "Casa", "Casa al mare" |
| `notification_time` | TEXT | 5..5, default `20:00` | orario del promemoria, `HH:mm` |
| `second_notification_time` | TEXT | 5..5, nullable | secondo promemoria, funzione Pro |
| `enabled` | BOOL | default true | promemoria attivi per questo calendario |
| `sort_order` | INTEGER | default 0 | |
| `created_at` | INTEGER | obbligatorio | ms UTC |

L'orario è testo e non due interi: si legge e si scrive sempre insieme, non si interroga mai
per ora separata dai minuti, e in forma testuale è ispezionabile a occhio in un dump.

### `waste_types`

| Colonna | Tipo | Vincoli | Significato |
|---|---|---|---|
| `id` | INTEGER | PK autoincrement | |
| `calendar_id` | INTEGER | FK → `collection_calendars.id`, ON DELETE CASCADE | |
| `name` | TEXT | 1..40 | |
| `icon_key` | TEXT | 1..32 | chiave in `WasteIcons.byKey`, **mai** un codepoint |
| `color_value` | INTEGER | obbligatorio | ARGB |
| `notifications_enabled` | BOOL | default true | |
| `sort_order` | INTEGER | default 0 | |

☠ `icon_key` è una chiave e non un `IconData.codePoint`: salvare il codepoint rompe il tree
shaking delle icone e in release produce quadrati vuoti.

### `recurrence_rules`

Tabella volutamente larga: molte colonne nullable, di cui solo alcune valide per ciascun
`kind`. Cinque tabelle separate sarebbero cinque join per un dato che si legge sempre tutto
insieme e che non supera qualche decina di righe per utente. La larghezza si paga con la
validazione nel mapper, che è un posto solo.

| Colonna | Tipo | Valido per | Significato |
|---|---|---|---|
| `id` | INTEGER | | PK |
| `waste_type_id` | INTEGER | | FK → `waste_types.id`, CASCADE |
| `kind` | TEXT 1..24 | | `weekly` \| `everyNWeeks` \| `monthlyDay` \| `monthlyNthWeekday` \| `manual` |
| `weekdays_mask` | INTEGER, default 0 | weekly, everyNWeeks | bit 0 = lunedì, bit 6 = domenica |
| `interval_weeks` | INTEGER nullable | everyNWeeks | ≥ 2 |
| `anchor_date` | TEXT nullable | everyNWeeks | fissa la fase del ciclo |
| `day_of_month` | INTEGER nullable | monthlyDay | 1..31, clamp a fine mese |
| `nth_of_month` | INTEGER nullable | monthlyNthWeekday | 1..5 oppure **-1 = l'ultimo** |
| `weekday` | INTEGER nullable | monthlyNthWeekday | 1..7 |
| `manual_dates_csv` | TEXT nullable | manual | date `YYYY-MM-DD` separate da virgola |
| `start_date` | TEXT 10..10 | tutti | obbligatoria |
| `end_date` | TEXT nullable | tutti | |

### `collection_exceptions`

La data class generata si chiama **`ExceptionRow`**, non `CollectionException`: il nome
naturale collide con la classe di dominio omonima, e due tipi con lo stesso nome nello stesso
file sono attrito che si paga a ogni import per anni.

| Colonna | Tipo | Significato |
|---|---|---|
| `id` | INTEGER | PK |
| `waste_type_id` | INTEGER | FK → `waste_types.id`, CASCADE |
| `original_date` | TEXT nullable | la data prevista dalla regola |
| `replacement_date` | TEXT nullable | la data nuova |
| `skipped` | BOOL default false | |
| `note` | TEXT nullable | |
| `created_at` | INTEGER | ms UTC |

Tre combinazioni ammesse, e nessun'altra:

| Forma | `original_date` | `replacement_date` | `skipped` |
|---|---|---|---|
| salta | valorizzata | null | true |
| sposta | valorizzata | valorizzata | false |
| straordinaria | null | valorizzata | false |

---

## 4. `lib/domain/` — il cuore, senza database

### `sealed class Recurrence`

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `const Recurrence({required CivilDate startDate, CivilDate? endDate})` | |
| `startDate` | `final CivilDate` | prima data in cui la regola vale |
| `endDate` | `final CivilDate?` | ultima, inclusa |
| `occursOn` | `bool occursOn(CivilDate date)` | `matches` **e** dentro l'intervallo |
| `matches` | `bool matches(CivilDate date)` | astratto: la forma della ricorrenza |
| `occurrencesIn` | `Iterable<CivilDate> occurrencesIn(CivilDate from, CivilDate to)` | |

Le cinque sottoclassi:

| Classe | Campi propri | Note |
|---|---|---|
| `WeeklyRecurrence` | `Set<int> weekdays` | |
| `EveryNWeeksRecurrence` | `Set<int> weekdays`, `int intervalWeeks` (≥2), `CivilDate anchor` | il costruttore prende `anchorDate:`, il campo si chiama `anchor` |
| `MonthlyDayRecurrence` | `int dayOfMonth` | clamp a fine mese |
| `MonthlyNthWeekdayRecurrence` | `int nth` (1..5 o -1), `int weekday` | |
| `ManualDatesRecurrence` | `Set<CivilDate> dates` | il costruttore prende un `Iterable` |

⚑ `EveryNWeeksRecurrence` non usa il numero di settimana ISO: cambia significato a cavallo
dell'anno e produrrebbe un salto o un raddoppio fra dicembre e gennaio. Usa invece la
distanza in settimane dall'ancora, in entrambe le direzioni.

### `abstract final class WeekdayMask`

| Metodo | Firma |
|---|---|
| `fromSet` | `static int fromSet(Set<int> weekdays)` |
| `toSet` | `static Set<int> toSet(int mask)` |

### `class OccurrenceEngine`

`const OccurrenceEngine()`.

| Metodo | Firma |
|---|---|
| `expand` | `List<CollectionOccurrence> expand({required List<RuleWithExceptions> rules, required CivilDate from, required CivilDate to})` |
| `onDate` | `List<CollectionOccurrence> onDate(CivilDate date, {required List<RuleWithExceptions> rules})` |
| `tonight` | `List<CollectionOccurrence> tonight({required List<RuleWithExceptions> rules, CivilDate? today})` |
| `next` | `CollectionOccurrence? next({required List<RuleWithExceptions> rules, CivilDate? from})` |
| `nextN` | `List<CollectionOccurrence> nextN(int count, {required List<RuleWithExceptions> rules, CivilDate? from, int horizonDays = 800})` |

`CollectionOccurrence`: `wasteTypeId`, `date`, `origin` (`regular` \| `moved` \| `extra`),
`originalDate` (per le spostate), `note`.

`RuleWithExceptions`: `wasteTypeId`, `recurrence`, `exceptions`, `sortOrder`.

---

## 5. `lib/data/`

### `class AppDatabase extends _$AppDatabase`

| Membro | Firma |
|---|---|
| apertura normale | `factory AppDatabase.open()` |
| in memoria, per i test | `factory AppDatabase.memory()` |
| versione | `int get schemaVersion => 1` |

### `class CalendarBundle`

`const CalendarBundle({required CollectionCalendar calendar, required List<WasteType> wasteTypes, required List<RuleWithExceptions> rules})`
più `WasteType? typeOf(int id)`.

### `extension AppDatabaseQueries on AppDatabase`

| Metodo | Firma | Note |
|---|---|---|
| `watchCalendars` | `Stream<List<CollectionCalendar>> watchCalendars()` | |
| `allCalendars` | `Future<List<CollectionCalendar>> allCalendars()` | serve al pianificatore: copre **tutti** i calendari |
| `countCalendars` | `Future<int> countCalendars()` | |
| `watchWasteTypes` | `Stream<List<WasteType>> watchWasteTypes(int calendarId)` | |
| `watchAnyChange` | `Stream<void> watchAnyChange()` | un segnale a ogni modifica di una delle 4 tabelle |
| `watchBundle` | `Stream<CalendarBundle?> watchBundle(int calendarId)` | vedi la trappola in §10 |
| `loadBundle` | `Future<CalendarBundle?> loadBundle(int calendarId)` | |

### `extension RecurrenceRuleMapper on RecurrenceRule`

`Recurrence? toDomain()` — `null` se la riga è incoerente col proprio `kind`. **Non lancia**:
una riga storta, arrivata da un import o da una versione futura, deve far sparire quella
regola, non rendere l'app inutilizzabile.

### `extension CollectionExceptionMapper on ExceptionRow`

`CollectionException? toDomain()` — `null` se la riga non è una delle tre forme ammesse.

### `class TrashcanRepository`

`const TrashcanRepository(AppDatabase db)`. **Tutte** le scritture passano da qui.

| Metodo | Firma |
|---|---|
| `createCalendar` | `Future<int> createCalendar({required String name, String notificationTime = '20:00'})` |
| `renameCalendar` | `Future<void> renameCalendar(int id, String name)` |
| `setCalendarNotification` | `Future<void> setCalendarNotification(int id, {required String time, String? secondTime, bool? enabled})` |
| `deleteCalendar` | `Future<void> deleteCalendar(int id)` |
| `createWasteType` | `Future<int> createWasteType({required int calendarId, required String name, required String iconKey, required int colorValue, int? sortOrder})` |
| `updateWasteType` | `Future<void> updateWasteType(int id, {String? name, String? iconKey, int? colorValue, bool? notificationsEnabled})` |
| `deleteWasteType` | `Future<void> deleteWasteType(int id)` |
| `reorderWasteTypes` | `Future<void> reorderWasteTypes(List<int> orderedIds)` |
| `setWeeklyRule` | `Future<void> setWeeklyRule({required int wasteTypeId, required Set<int> weekdays, CivilDate? startDate, CivilDate? endDate})` |
| `setEveryNWeeksRule` | `Future<void> setEveryNWeeksRule({required int wasteTypeId, required Set<int> weekdays, required int intervalWeeks, required CivilDate anchorDate, CivilDate? startDate, CivilDate? endDate})` |
| `setMonthlyDayRule` | `Future<void> setMonthlyDayRule({required int wasteTypeId, required int dayOfMonth, CivilDate? startDate, CivilDate? endDate})` |
| `setMonthlyNthWeekdayRule` | `Future<void> setMonthlyNthWeekdayRule({required int wasteTypeId, required int nth, required int weekday, CivilDate? startDate, CivilDate? endDate})` |
| `setManualDatesRule` | `Future<void> setManualDatesRule({required int wasteTypeId, required List<CivilDate> dates, CivilDate? startDate, CivilDate? endDate})` |
| `setRule` | `Future<void> setRule({required int wasteTypeId, required Recurrence recurrence})` |
| `clearRules` | `Future<void> clearRules(int wasteTypeId)` |
| `ruleOf` | `Future<Recurrence?> ruleOf(int wasteTypeId)` |
| `skipCollection` | `Future<int> skipCollection({required int wasteTypeId, required CivilDate date, String? note})` |
| `moveCollection` | `Future<int> moveCollection({required int wasteTypeId, required CivilDate from, required CivilDate to, String? note})` |
| `addExtraCollection` | `Future<int> addExtraCollection({required int wasteTypeId, required CivilDate date, String? note})` |
| `removeException` | `Future<void> removeException(int id)` |
| `watchExceptions` | `Stream<List<ExceptionRow>> watchExceptions(int calendarId)` |
| `createCalendarFromWizard` | `Future<int> createCalendarFromWizard({required String name, required String notificationTime, required List<WizardWasteType> types})` |

Tutte le `set*Rule` e `setRule` **sostituiscono** le regole esistenti del tipo, in
transazione: nella UI c'è un solo insieme di giorni, non una collezione di regole
sovrapposte.

`class WizardWasteType`: `name`, `iconKey`, `colorValue`, `Set<int> weekdays`, più
`copyWith({Set<int>? weekdays, String? name})`.

### `extension RecurrenceToRow on Recurrence`

`RecurrenceRulesCompanion toCompanion(int wasteTypeId)` — l'inverso di `toDomain()`. Le due
direzioni vivono in file diversi: la lettura deve tollerare righe storte, la scrittura parte
da un oggetto valido per costruzione. **Se tocchi una, controlla l'altra.**

---

## 6. `lib/app/providers.dart`

Da sovrascrivere in `main()`, altrimenti l'app non parte: `appConfigProvider`,
`appPathsProvider`, `settingsProvider`.

| Provider | Tipo | Cosa espone |
|---|---|---|
| `databaseProvider` | `Provider<AppDatabase>` | apre e chiude il database |
| `repositoryProvider` | `Provider<TrashcanRepository>` | |
| `installIdProvider` | `FutureProvider<InstallId>` | |
| `purchaseGatewayProvider` | `Provider<PurchaseGateway>` | Play o finto, secondo `BILLING` |
| `entitlementProvider` | `NotifierProvider<EntitlementNotifier, EntitlementView>` | `.notifier.service` per le azioni |
| `isProProvider` | `Provider<bool>` | |
| `featureGateProvider` | `Provider<FeatureGate>` | |
| `backupServiceProvider` | `Provider<BackupService>` | |
| `themeModeProvider` | `NotifierProvider<ThemeModeNotifier, ThemeMode>` | `.set(mode)` |
| `onboardingDoneProvider` | `Provider<bool>` | |
| `selectedCalendarProvider` | `NotifierProvider<SelectedCalendar, int?>` | `.select(id)` |
| `calendarsProvider` | `StreamProvider<List<CollectionCalendar>>` | |
| `activeCalendarProvider` | `Provider<CollectionCalendar?>` | il selezionato, o il primo |
| `activeBundleProvider` | `StreamProvider<CalendarBundle?>` | |
| `occurrencesProvider` | `Provider<List<CollectionOccurrence>>` | 120 giorni, calcolati **una volta** |
| `tonightProvider` | `Provider<List<CollectionOccurrence>>` | le raccolte di **domani** |
| `nextOccurrenceProvider` | `Provider<CollectionOccurrence?>` | la prima dopo stasera |
| `upcomingWeekProvider` | `Provider<List<CollectionOccurrence>>` | i prossimi 7 giorni |
| `notificationServiceProvider` | `FutureProvider<NotificationService>` | creato al primo uso, non in `main()` |
| `schedulerProvider` | `Provider<TrashcanScheduler>` | |
| `notificationSyncProvider` | `Provider<void>` | tiene notifiche **e** widget allineati ai dati |
| `notificationsEnabledProvider` | `NotifierProvider<NotificationsEnabled, bool>` | `.set(value)` |
| `seedColorProvider` | `NotifierProvider<SeedColor, Color>` | il colore generale dell'app, `.set(color)` |

`EntitlementView` è un valore immutabile con `entitlement`, `busy`, `storeAvailable`,
`product`, `error`, più `isPro` e `isPending`. Esiste perché `EntitlementService` è un
`ChangeNotifier` e Riverpod 3 ha spostato `ChangeNotifierProvider` fra le API legacy:
rispecchiarlo in un valore rende esplicito **cosa** fa ridisegnare la UI.

`appVersion` è la costante `'0.1.0'` in questo file: compare nel backup, nelle chiamate al
server e nella schermata delle informazioni. Tenerla in tre posti garantirebbe che divergano.

---

## 7. Le rotte

Dichiarate in `lib/app/routes.dart`, registrate in `lib/app/app.dart`.

| Costante | Percorso | Pagina |
|---|---|---|
| `Routes.home` | `/` | `HomePage` |
| `Routes.onboarding` | `/onboarding` | `OnboardingPage` |
| `Routes.calendars` | `/calendars` | `CalendarsPage` |
| `Routes.calendarNew` | `/calendars/new` | `CalendarEditorPage` |
| `Routes.calendarEdit` | `/calendars/:calendarId/edit` | `CalendarEditorPage` |
| `Routes.wasteTypes` | `/waste-types` | `WasteTypesPage` |
| `Routes.wasteTypeNew` | `/waste-types/new` | `WasteTypeEditorPage` |
| `Routes.wasteTypeEdit` | `/waste-types/:wasteTypeId/edit` | `WasteTypeEditorPage` |
| `Routes.day` | `/day/:date` (+ `?calendar=<id>`) | `DayPage` — **bersaglio delle notifiche** |
| `Routes.exceptions` | `/exceptions` | `ExceptionsPage` |
| `Routes.settings` | `/settings` | `SettingsPage` |
| `Routes.notifications` | `/settings/notifications` | `NotificationsPage` |
| `Routes.backup` | `/settings/backup` | `BackupPage` |
| `Routes.restore` | `/settings/restore` | `RestorePage` |

Helper: `Routes.dayOf(String iso)`, `Routes.calendarEditOf(int id)`,
`Routes.wasteTypeEditOf(int id)`, `Routes.rulesOf(int wasteTypeId)`.

Un `redirect` porta all'onboarding chi non l'ha completato, da qualunque punto entri, e
riporta alla home chi lo ha già fatto.

**Non ha una rotta**: l'editor delle regole. È un sotto-passaggio che restituisce un valore
al chiamante, non una destinazione raggiungibile da un deep link. Si apre con
`Navigator.push` e restituisce un `RuleEditorResult`, il cui campo `recurrence` a `null`
significa "togli i giorni di raccolta" e va distinto dall'annullamento (pop senza valore).

---

## 8. `lib/services/`

### `class TrashcanScheduler implements NotificationScheduler`

`TrashcanScheduler({required AppDatabase db, required SettingsStore settings, required FeatureGate gate, required String appName, NotificationService? notifications})`

| Membro | Firma | Effetto |
|---|---|---|
| `horizonDays` | `static const int = 60` | |
| `maxScheduled` | `static const int = 64` | il limite di Android |
| `isReady` | `bool get isReady` | c'è un servizio a cui consegnare |
| `rescheduleAll` | `Future<void> rescheduleAll()` | ricalcola e sostituisce |
| `rescheduleIfStale` | `Future<void> rescheduleIfStale()` | solo se è passata un'ora |
| `cancelAll` | `Future<void> cancelAll()` | |
| `computeSchedule` | `Future<List<ScheduledNotification>> computeSchedule({CivilDate? today, DateTime? now})` | **puro**: non tocca il plugin |
| `timesFor` | `List<TimeOfDay> timesFor(CollectionCalendar calendar)` | uno gratis, due col Pro |

Funzioni di modulo: `TimeOfDay? parseTime(String?)` (non lancia mai),
`String formatTime(TimeOfDay)`.

Costante di modulo: `const MicroNotificationChannel trashcanChannel` — un canale solo, perché
su Android l'utente può silenziare i canali singolarmente e spezzare i promemoria in più
canali offrirebbe un modo di silenziarne metà senza accorgersene.

Regole del piano: una notifica **per giorno e per calendario**, non per tipo; la sera
**prima** della raccolta; niente notifiche nel passato; id derivati da
`NotificationIds.forOccurrence(calendarId, date, slot)` perché la ripianificazione
sovrascriva invece di accumulare; ordinato per istante e troncato a 64; titolo col nome del
calendario solo se ce n'è più d'uno; payload `/day/YYYY-MM-DD?calendar=<id>`, cioè il
percorso interno di `go_router`.

### `abstract final class TrashcanWidget`

| Membro | Firma |
|---|---|
| `qualifiedName` | `static const String = 'com.smp.trashcan.TrashcanWidgetProvider'` |
| chiavi | `keyTonightLabel`, `keyTonightText`, `keyTonightColor`, `keyNextText`, `keyCalendarName`, `keyUpcoming`, `keyShowUpcoming` |
| `publish` | `static Future<void> publish({required AppDatabase db, required int? calendarId, required bool pro})` |
| `scheduleDailyRefresh` | `static Future<void> scheduleDailyRefresh()` |

Le chiavi **devono** coincidere con le costanti in `TrashcanWidgetProvider.kt`: sono scritte
a mano in due linguaggi diversi, e una divergenza produce un campo vuoto nel widget senza
nessun errore da nessuna parte.

`scheduleDailyRefresh` programma un aggiornamento alle 00:05 per i sette giorni successivi.
Senza, alle 00:01 il widget continua a dire "stasera: organico" riferendosi alla sera
precedente, cioè proprio la mattina, quando lo si guarda uscendo di casa.

### `class TrashcanBackupSource implements BackupSource`

`const TrashcanBackupSource(AppDatabase db, {int? onlyCalendarId})`

| Membro | Firma |
|---|---|
| `schemaId` | `String get schemaId => 'trashcan'` |
| `schemaVersion` | `int get schemaVersion => 1` |
| `exportPayload` | `Future<Map<String, Object?>> exportPayload()` |
| `importPayload` | `Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode})` |
| `imagePaths` | `Future<List<String>> imagePaths()` → sempre vuoto |
| `counts` | `Future<Map<String, int>> counts()` → chiavi `calendars`, `wasteTypes`, `rules` |

Il payload è **annidato** (calendari → tipi → regole ed eccezioni) e non una copia delle
tabelle: gli id di riga non significano niente fuori da questo dispositivo, e un formato
piatto legato da id costringerebbe l'import a rimapparli. Un solo errore di rimappatura
attacca una regola al tipo di rifiuto sbagliato, e il sintomo non è un errore ma un
calendario che dice bugie.

L'import gira in **una sola transazione**: `replaceAll` cancella prima di scrivere, e
un'interruzione fuori transazione cancellerebbe i dati senza rimpiazzarli.

---

## 9. Catalogo dei test

117 test in `apps/trashcan/`, oltre ai 107 di `micro_core`.

| File | N. | Cosa dimostra |
|---|---|---|
| `test/domain/occurrence_engine_test.dart` | 40 | le cinque ricorrenze su casi reali (cambio mese, anno bisestile, ultimo venerdì), le tre eccezioni, la precedenza fra regola ed eccezione, la bitmask |
| `test/data/database_test.dart` | 19 | foreign key attive e cascata, mapper riga→dominio delle 5 forme, righe storte scartate senza far cadere il resto, conteggi e stream |
| `test/data/recurrence_roundtrip_test.dart` | 7 | andata e ritorno dominio↔tabella per tutte e 5 le forme; l'ancora e il `-1 = ultimo` sopravvivono; `setRule` sostituisce invece di affiancare |
| `test/data/watch_bundle_test.dart` | 5 | lo stream del calendario riemette su **tutte** le tabelle: tipo aggiunto, regola cambiata, eccezione aggiunta, lista riordinata, calendario rinominato |
| `test/data/orphan_exceptions_test.dart` | 3 | le eccezioni di un tipo **senza regola** arrivano fino al motore; la ricorrenza sintetica non genera date di suo; nessun duplicato per i tipi che una regola ce l'hanno |
| `test/services/trashcan_scheduler_test.dart` | 16 | **nel piano gratuito non si pianifica niente**; la sera prima, all'orario giusto; una notifica per giorno con tutti i tipi; tipo silenziato e calendario disattivato esclusi; raccolta saltata senza promemoria; niente nel passato; secondo orario solo col Pro; troncatura a 64 e ordine; titolo col nome del calendario solo se ce n'è più d'uno; id stabili; payload; `parseTime` che non lancia |
| `test/services/trashcan_backup_source_test.dart` | 9 | giro completo su un database vuoto; `replaceAll` cancella; `mergeKeepExisting` non duplica; export di un solo calendario; conteggi veri; quattro casi di file storto |
| `test/widget/home_page_test.dart` | 6 | la home nei tre stati (niente / uno / tre tipi), lo stato vuoto, la prossima raccolta con la sera giusta, il nome del calendario nel titolo |
| `test/widget/paywall_config_test.dart` | 6 | **ogni funzione bloccata è venduta**; i calendari stanno per primi; nessun duplicato; nessun testo vuoto; il bottone regge un prezzo assente |
| `test/widget/palette_contrast_test.dart` | 6 | ogni colore della tavolozza **e ogni preset** regge 4.5:1 col testo che ci va sopra; i preset usano colori della tavolozza; nessun duplicato |

`test/widget/harness.dart` non contiene test: è l'impalcatura che monta una pagina
sostituendo i provider che legge.

`integration_test/first_run_test.dart` percorre wizard → home → dati scritti, sul
dispositivo: `flutter test integration_test/first_run_test.dart -d <device>`.

### Come si eseguono

```
pwsh tool/fl.ps1 test                 # dalla cartella dell'app
pwsh tool/test_all.ps1                # tutto il monorepo
```

---

## 10. Trappole già disinnescate

Ognuna è costata tempo almeno una volta. Sono elencate perché il sintomo non nomina mai la
causa.

| Sintomo | Causa | Dove |
|---|---|---|
| "Activity class does not exist" con la classe presente nel dex | l'emulatore era in `RUNNING_LOCKED`: con lo storage utente bloccato il package manager nasconde i componenti non direct-boot-aware | ambiente, non codice: serve un cold boot |
| `fl.ps1 build apk --debug` costruisce una **release** | con `-File`, PowerShell lega ogni token che inizia per trattino a un nome di parametro: `--debug` finiva in un `param()` inesistente | `tool/fl.ps1`: niente `param()`, si usa `$args` |
| Modifico una regola e lo schermo non cambia fino al riavvio | `watchBundle` osservava solo `collection_calendars`; drift invalida uno stream in base alle tabelle **della query osservata**, non a quelle lette nella callback | `database.dart`: `watchBundle` osserva tutte e quattro |
| Aggiungo una raccolta straordinaria e sparisce | `_rulesFor` costruiva la lista dalle sole righe di `recurrence_rules`: un tipo senza regola non compariva, e con lui le sue eccezioni | `database.dart`: ricorrenza sintetica vuota |
| Il bottone "Sblocca Pro" gira all'infinito | `EntitlementService.dispose()` chiudeva il gateway ricevuto per iniezione; il servizio si ricrea a ogni avvio (appena arriva l'id di installazione) e il secondo ne riceveva uno già chiuso | `micro_core`: un servizio non chiude ciò che non ha costruito |
| La notifica non arriva mai, nessun errore | mancavano `ScheduledNotificationReceiver` e `ScheduledNotificationBootReceiver` nel manifest | `AndroidManifest.xml` |
| Dopo un riavvio del telefono i promemoria smettono | gli allarmi non sopravvivono al riavvio senza `RECEIVE_BOOT_COMPLETED` e il boot receiver | `AndroidManifest.xml` |
| Configuro l'app e dopo due mesi non arriva più niente | niente ripianificava all'avvio: il piano si ricostruiva solo al cambio dei dati | `notificationSyncProvider` |
| Tocco la notifica e il back esce dall'app | `go` sostituisce lo stack: la pagina del giorno restava senza nulla sotto | `app.dart`, `_openPayload` fa `go(home)` poi `push` |
| Il widget e' squadrato sopra e tondo sotto | `setBackgroundColor` su una view sostituisce il drawable, e con lui gli angoli arrotondati. Il colore si applica tingendo con `setColorFilter` un `ImageView` di sfondo | `TrashcanWidgetProvider.kt` + `widget_header_background.xml` |
| Il widget resta un rettangolo colorato e vuoto | il receiver crollava leggendo il colore: vedi la riga seguente | `TrashcanWidgetProvider.kt` |
| "TrashCan continua a bloccarsi", dopo giorni di funzionamento perfetto | il canale fra Dart e Android codifica un intero come **Integer** se sta in 32 bit con segno e come **Long** altrimenti: *il tipo dipende dal valore*. Un ARGB con alpha `0xFF` supera 2³¹ e arriva Long; lo zero che si manda quando stasera non si raccoglie niente arriva Integer. `getInt` e `getLong` sbagliano **a turno**. E un receiver che lancia fa cadere l'intero processo dell'app, non solo il widget | `TrashcanWidgetProvider.kt`: si legge da `widgetData.all[...]` accettando entrambi i tipi, e tutto `onUpdate` sta dentro un `try` |
| L'icona nella barra di stato è una macchia bianca | Android usa solo il canale alfa dell'icona: `@mipmap/ic_launcher` è opaca ovunque | `drawable/ic_notification.xml` |
| Il testo sul blocco "Stasera" si legge male | `ThemeData.estimateBrightnessForColor` confronta `(luminanza + 0.05)²` con 0.15, cioè passa al bianco sopra 0.337, non 0.5: sui colori di mezzo sceglie il bianco dove ci si aspetta il nero | tavolozza corretta + `palette_contrast_test.dart` |
| Un widget test resta appeso dieci minuti e muore | `testWidgets` gira in `FakeAsync`, che non fa avanzare l'I/O vero di SQLite; e `pumpAndSettle` non termina perché drift pianifica lavoro di continuo | `test/widget/harness.dart`: si sostituiscono i provider, niente database |
| Build che si ferma su "Could not close incremental caches" | la compilazione incrementale di Kotlin non regge il locking di Windows | `android/gradle.properties`, `kotlin.incremental=false` |
| Il PC resta senza RAM | il template Flutter chiede `-Xmx8G` e 4 GB di metaspace per i demoni di build | `android/gradle.properties`: 2 GB + 1 GB |
| `RadioListTile` deprecato | `groupValue`/`onChanged` sui singoli tile sono deprecati da Flutter 3.32 | `settings_page.dart`, si usa `RadioGroup` |
| `ReorderableListView` sposta una posizione più in là | `onReorder` consegna un `newIndex` già incrementato | `waste_types_page.dart`, si usa `onReorderItem` |

### Regole non negoziabili

1. **`icon_key` è una chiave, mai un codepoint.**
2. **Le date civili sono `CivilDate`**, mai `DateTime`: un `DateTime` porta con sé un fuso, e
   una raccolta "del 12 settembre" non ha un fuso.
3. **Tutte le scritture passano dal repository.** Quasi ognuna tocca più tabelle e deve
   restare coerente.
4. **Nessuna pagina scrive `if (isPro)`**: si passa da `FeatureGate` (ADR-017).
5. **Ogni colore nuovo nella tavolozza va verificato** dal test del contrasto.
6. **`android/key.properties` non si committa**, e il keystore non entra mai nel repository.
7. **`applicationId` e `proSku` sono immutabili** dopo il primo upload su Play.

---

## 10bis. Cosa e' a pagamento

Deciso dal proprietario l'11 settembre 2026. La mappa vive in
`lib/app/feature_limits.dart` ed e' l'unico posto in cui cambiarlo.

| Funzione | Chiave | Piano gratuito |
|---|---|---|
| Secondo calendario e oltre | `unlimitedEntities` | uno solo |
| **I promemoria, tutti** | `notifications` | nessuno |
| Secondo orario di promemoria | `multipleNotifications` | no |
| Prossimi tre giorni nel widget | `advancedWidget` | uno solo |
| Backup completo | `backupRestore` | no (la condivisione di un calendario resta gratuita) |
| Colore dell'app | `themeCustomization` | verde fisso |

⛑ **Il compromesso dei promemoria**, scritto qui perche' e' la scelta commerciale piu'
pesante: TrashCan gratuito diventa un calendario che bisogna ricordarsi di aprire, cioe' non
risolve piu' il problema per cui la si installa. Se le installazioni o le recensioni ne
risentono, si torna indietro cambiando una riga in `FeatureLimit.open()`. Il controllo sta
sia nella pagina sia **nel pianificatore**: una notifica gia' consegnata ad Android
sopravvive alla perdita del diritto, e senza il secondo controllo un rimborso lascerebbe
arrivare promemoria per sessanta giorni.

---

## 11. Cosa NON esiste ancora

Per non farlo cercare invano.

- **Nessuna sincronizzazione col License Server in esercizio.** Il client c'è in
  `micro_core`, ma `serverEnabled` è falso finché non c'è un dominio.
- **Nessuna esportazione in CSV.** `FeatureKey.csvExport` è dichiarata `open()` proprio per
  dire che non è una funzione di quest'app.
- **Nessun golden test.** Scelta deliberata: vedi §12.
- **Nessuna vista mensile a calendario.** Le eccezioni si creano dalla home e dalla pagina
  del giorno.
- **Nessun terzo orario di promemoria.** La tabella ne prevede due.
- **Nessun selettore di colore libero.** Dieci semi misurati, non una ruota: un seme troppo
  chiaro renderebbe illeggibile l'intera app e l'utente non avrebbe modo di accorgersene
  prima. Vedi `AppSeeds`.
- **Il codice di trasferimento non funziona finche' il server non e' in esercizio.** La
  pagina lo dice invece di offrire un bottone che fallisce.
- **Nessuna app su Play Console.** Vedi §12.
- **Nessun test di migrazione dello schema** (F3.2.6): con `schemaVersion = 1` non c'è ancora
  niente da migrare, ma il test va scritto **prima** della versione 2.

---

## 12. Debito tecnico aperto

| Voce | Perché è rimandato | Quando va affrontato |
|---|---|---|
| **F3.12, Play Console** | richiede l'account Google Play del proprietario, un AAB pubblicato su un canale e alcune ore di attesa prima che il prodotto in-app diventi acquistabile. Nessuno di questi passi è eseguibile da qui | prima di qualunque pubblicazione; è il collo di bottiglia della fase F8 |
| **Golden test della home** | un golden fallisce per il rasterizzatore, la versione del font o il sistema operativo, cioè per motivi che non sono difetti dell'app. I 6 widget test della home già verificano il contenuto nei tre stati | se e quando ci sarà una CI con una sola piattaforma fissa |
| **Test di migrazione dello schema** | `schemaVersion = 1`: non c'è nulla da migrare | insieme alla prima modifica delle tabelle, non dopo |
| **`pub cache` condivisa col sistema** | `package_config.json` risolve i pacchetti dalla cache utente invece che da `.flutter/.pub-cache`. Non è pericoloso (i pacchetti sono versionati per risoluzione, l'SDK no) ma tradisce l'isolamento dichiarato in ADR-002 | quando si tocca la toolchain |
| **Testo ingrandito al 200%** | verificato a occhio, non misurato. Il blocco "Stasera" usa `displaySmall` e può traboccare | in F7 (hardening), con un widget test a scala del testo alta |
| **`Semantics` sulle card** | le pagine sono navigabili con TalkBack perché usano widget standard, ma il blocco "Stasera" non ha un'etichetta unica che lo legga come una frase | in F7 |
| **Limite Pro aggirabile via import** | importare un backup con più calendari li crea anche senza Pro. Il backup completo è già dietro al paywall, quindi serve il file di qualcun altro | prima della pubblicazione, se si vuole chiudere il buco |
| **Il widget non sceglie il calendario** | mostra sempre quello attivo nell'app. Il piano prevedeva la scelta del calendario come funzione Pro | quando qualcuno avrà davvero due calendari e lo chiederà |

---

## 13. Configurazione

| Chiave | Dove | Default | Significato |
|---|---|---|---|
| `BILLING` | `--dart-define` | `play` | `fake` usa `FakePurchaseGateway`; una release compilata con `fake` fallisce all'avvio |
| `MA_LICENSE_URL` | `--dart-define` | vuoto | base URL del License Server; se vuoto, `serverEnabled` è falso |
| `applicationId` | `android/app/build.gradle.kts` | `com.smp.trashcan` | **immutabile** dopo il primo upload |
| `minSdk` | idem | 24 | |
| `proSku` | `lib/app/app_config.dart` | `trashcan_pro_lifetime` | **immutabile**: uno SKU pubblicato non si cancella né si riusa |
| `storeFile`, `storePassword`, `keyAlias`, `keyPassword` | `android/key.properties` | assenti | se il file manca, la release si firma con la chiave di debug e Play la rifiuta: è voluto, perché fallire in fase di upload è meglio che pubblicare firmato male |
| `org.gradle.jvmargs` | `android/gradle.properties` | `-Xmx2G` | tetto ai demoni di build |
| `kotlin.daemon.jvmargs` | idem | `-Xmx1G` | |
| `kotlin.incremental` | idem | `false` | vedi le trappole |

### Comandi

```
pwsh tool/fl.ps1 pub get
pwsh tool/fl.ps1 test
pwsh tool/fl.ps1 analyze lib test
pwsh tool/fl.ps1 run -d emulator-5554 --dart-define=BILLING=fake
pwsh tool/fl.ps1 build appbundle --release
```

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:trashcan/app/app_config.dart';
import 'package:trashcan/app/locale_resolution.dart';
import 'package:trashcan/app/providers.dart';
import 'package:trashcan/data/database.dart';
import 'package:trashcan/domain/occurrence_engine.dart';
import 'package:trashcan/l10n/generated/app_localizations.dart';

/// L'impalcatura dei widget test.
///
/// ⚑ **Perché qui il database non c'è.** Il primo tentativo montava le pagine su un
/// database Drift in memoria, per passare dalle stesse query della produzione. Non
/// funziona: `testWidgets` esegue il corpo dentro `FakeAsync`, che congela il tempo e non
/// fa avanzare l'I/O vero di SQLite. Gli stream non emettono mai, il test resta appeso per
/// cinque minuti e muore per timeout, e in coda compare "A Timer is still pending even
/// after the widget tree was disposed", perché drift pianifica un timer di pulizia alla
/// chiusura degli stream. Il messaggio non nomina drift e manda a cercare un difetto che
/// nella pagina non c'è.
///
/// Qui si sostituiscono direttamente i provider che la pagina legge. È anche la cosa
/// giusta: un widget test deve dimostrare che **la pagina disegna bene lo stato che
/// riceve**. Che quello stato sia calcolato bene lo dimostrano i test del motore delle
/// ricorrenze e quelli del data layer, che girano senza albero dei widget e senza tempo
/// finto.
abstract final class Harness {
  /// Monta [page] con lo stato dato ed esegue [body].
  static Future<void> pump(
    WidgetTester tester,
    Widget page, {
    required Future<void> Function() body,
    CalendarBundle? bundle,
    List<CollectionOccurrence> tonight = const <CollectionOccurrence>[],
    CollectionOccurrence? next,
    List<CollectionOccurrence> week = const <CollectionOccurrence>[],
    bool pro = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(buildTrashcanConfig()),
          activeCalendarProvider.overrideWithValue(bundle?.calendar),
          activeBundleProvider.overrideWith((ref) => Stream<CalendarBundle?>.value(bundle)),
          tonightProvider.overrideWithValue(tonight),
          nextOccurrenceProvider.overrideWithValue(next),
          upcomingWeekProvider.overrideWithValue(week),
          isProProvider.overrideWithValue(pro),
        ],
        // La lingua è fissata all'inglese e non lasciata al sistema: l'esito di un test
        // non deve dipendere dalla lingua della macchina che lo esegue.
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: kSupportedLocales,
          localizationsDelegates: const [
            L.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: page,
        ),
      ),
    );
    // Due frame: il primo costruisce, il secondo lascia emettere lo stream del bundle.
    await tester.pump();
    await tester.pump();
    await body();
  }

  // ── Costruttori di stato ──────────────────────────────────────────────────────────

  static CollectionCalendar calendar({int id = 1, String name = 'Home'}) => CollectionCalendar(
    id: id,
    name: name,
    notificationTime: '20:00',
    enabled: true,
    sortOrder: 0,
    createdAt: 0,
  );

  static WasteType type({
    required int id,
    required String name,
    int colorValue = 0xFF6D8B3C,
    String iconKey = 'trash',
  }) => WasteType(
    id: id,
    calendarId: 1,
    name: name,
    iconKey: iconKey,
    colorValue: colorValue,
    notificationsEnabled: true,
    sortOrder: id,
  );

  static CollectionOccurrence occurrence({
    required int wasteTypeId,
    required int inDays,
    OccurrenceOrigin origin = OccurrenceOrigin.regular,
  }) => CollectionOccurrence(
    wasteTypeId: wasteTypeId,
    date: CivilDate.today().addDays(inDays),
    origin: origin,
  );

  /// Un pacchetto con i tipi indicati e nessuna regola: alle raccolte pensano i parametri
  /// `tonight`, `next` e `week`, che è ciò che la home legge davvero.
  static CalendarBundle bundleOf(List<WasteType> types, {String name = 'Home'}) =>
      CalendarBundle(
        calendar: calendar(name: name),
        wasteTypes: types,
        rules: const <RuleWithExceptions>[],
      );
}

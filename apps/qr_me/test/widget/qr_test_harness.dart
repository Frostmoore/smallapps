import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';
import 'package:pdf/pdf.dart';
import 'package:qr_me/app/entitlement.dart';
import 'package:qr_me/app/feature_limits.dart';
import 'package:qr_me/app/providers.dart';
import 'package:qr_me/app/qr_palette.dart';
import 'package:qr_me/data/database.dart';
import 'package:qr_me/data/qr_repository.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/domain/qr_style.dart';
import 'package:qr_me/l10n/generated/app_localizations.dart';
import 'package:qr_me/services/contact_picker.dart';
import 'package:qr_me/services/label_output.dart';
import 'package:qr_me/services/readability_check.dart';
import 'package:qr_me/services/screen_boost.dart';
import 'package:qr_me/services/wifi_name_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// I doppi finti e il montaggio delle pagine di QR Me per i test di widget.
///
/// ☠ Repository finto e non Drift su `QrDatabase.memory()`: dentro `testWidgets` FakeAsync
/// congela l'I/O di SQLite e gli stream non arrivano mai (lezione di TrashCan, ripetuta in Film
/// Tracker). Che le scritture vere funzionino lo dimostra test/data/qr_repository_test.dart.

/// Un repository in memoria che registra le chiamate.
class FakeQrRepository extends QrRepository {
  FakeQrRepository(super.db, {List<QrCode>? rows}) : rows = [...?rows];

  final List<QrCode> rows;
  final _changes = StreamController<void>.broadcast();
  var _nextId = 100;

  final List<({QrContent content, String payload, String source, QrStyle style})> recorded = [];
  final List<int?> pruneCalls = [];
  final List<int> touched = [];
  final List<(int, String)> favorited = [];

  void _changed() => _changes.add(null);

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  List<QrCode> get _history =>
      rows.where((r) => !r.isFavorite).toList()
        ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));

  @override
  Stream<List<QrCode>> watchHistory() => _watch(() => _history);

  @override
  Stream<List<QrCode>> watchFavorites() => _watch(() => rows.where((r) => r.isFavorite).toList());

  @override
  Stream<QrCode?> watchById(int id) => _watch(() => rows.where((r) => r.id == id).firstOrNull);

  @override
  Future<QrCode?> byId(int id) async => rows.where((r) => r.id == id).firstOrNull;

  @override
  Future<int> countFavorites() async => rows.where((r) => r.isFavorite).length;

  @override
  Future<int> recordShown({
    required QrContent content,
    required String payload,
    required String source,
    QrStyle style = QrStyle.plain,
  }) async {
    recorded.add((content: content, payload: payload, source: source, style: style));
    final id = _nextId++;
    rows.add(qrRow(id, content: content, payload: payload, source: source));
    _changed();
    return id;
  }

  @override
  Future<void> touch(int id) async => touched.add(id);

  @override
  Future<int> pruneHistory({required int? keep}) async {
    pruneCalls.add(keep);
    return 0;
  }

  @override
  Future<void> saveAsFavorite(int id, {required String title}) async {
    favorited.add((id, title));
    final i = rows.indexWhere((r) => r.id == id);
    if (i >= 0) rows[i] = rows[i].copyWith(isFavorite: true, title: title);
    _changed();
  }

  Future<void> dispose() => _changes.close();
}

/// Una riga di prova.
QrCode qrRow(
  int id, {
  required QrContent content,
  String? payload,
  String source = QrSource.typed,
  bool favorite = false,
  String? title,
  int lastUsedAt = 0,
}) => QrCode(
  id: id,
  kind: content.kind.name,
  payload: payload ?? content.toFields().values.first.toString(),
  fieldsJson: content is TextContent || content is UrlContent
      ? null
      : jsonEncode(content.toFields()),
  title: title ?? content.autoTitle,
  source: source,
  isFavorite: favorite,
  createdAt: lastUsedAt,
  lastUsedAt: lastUsedAt,
);

/// La luminosita' finta: conta le accensioni e i ripristini.
class FakeScreenBoost implements ScreenBoost {
  int enabled = 0;
  int disabled = 0;

  /// True se l'ultima chiamata e' stata un'accensione.
  bool get on => enabled > disabled;

  @override
  Future<void> enable() async => enabled++;

  @override
  Future<void> disable() async => disabled++;
}

/// Lo scanner su file finto: restituisce [values], o lancia "non disponibile".
class FakeQrReader implements QrImageReader {
  FakeQrReader([this.values = const [], this.unavailable = false]);

  List<String> values;
  bool unavailable;
  final List<String> paths = [];

  @override
  Future<List<String>> read(String path) async {
    paths.add(path);
    if (unavailable) throw QrReaderUnavailable(StateError('finto'));
    return values;
  }
}

/// La verifica di leggibilita' finta: risponde sempre [result] e conta le chiamate.
class FakeReadabilityCheck extends ReadabilityCheck {
  FakeReadabilityCheck(this.result) : super(FakeQrReader());

  final Readability result;
  int calls = 0;

  @override
  Future<Readability> check({required String payload, required QrStyle style, Object? logo}) async {
    calls++;
    return result;
  }
}

/// Il nome della rete finto (F17.10): risponde [result] e conta le richieste di permesso.
class FakeWifiNameReader implements WifiNameReader {
  FakeWifiNameReader(this.result, {this.needs = true});

  WifiNameLookup result;

  /// Se serve ancora il permesso (e quindi la spiegazione prima).
  bool needs;
  int lookups = 0;

  @override
  Future<bool> needsPermission() async => needs;

  @override
  Future<WifiNameLookup> lookup() async {
    lookups++;
    return result;
  }
}

/// Il selettore dei contatti finto: restituisce [contact] (null = annullato) o lancia.
class FakeContactPicker implements ContactPicker {
  FakeContactPicker(this.contact, {this.fails = false});

  ContactContent? contact;
  bool fails;
  int picks = 0;

  @override
  Future<ContactContent?> pick() async {
    picks++;
    if (fails) throw StateError('finto');
    return contact;
  }
}

/// Stampa e condivisione finte dell'etichetta: registrano cosa e' uscito.
class FakeLabelOutput implements LabelOutput {
  final List<({Uint8List png, String title})> shared = [];
  final List<({String name, Future<Uint8List> Function(PdfPageFormat) buildPdf})> printed = [];

  @override
  Future<bool> printPdf({
    required Future<Uint8List> Function(PdfPageFormat page) buildPdf,
    required String name,
  }) async {
    printed.add((name: name, buildPdf: buildPdf));
    return true;
  }

  @override
  Future<void> sharePng({required Uint8List png, required String title}) async =>
      shared.add((png: png, title: title));
}

class FakeEntitlementNotifier extends EntitlementNotifier {
  FakeEntitlementNotifier(this._fake);

  final EntitlementService _fake;

  @override
  EntitlementService get service => _fake;

  @override
  EntitlementView build() =>
      EntitlementView(entitlement: _fake.current, busy: false, storeAvailable: true);
}

class FixedHistoryNotifier extends HistoryEnabledNotifier {
  FixedHistoryNotifier(this.value);

  final bool value;

  @override
  bool build() => value;

  @override
  Future<void> set(bool enabled) async => state = enabled;
}

/// Cio' che i test leggono dopo il montaggio.
class QrHarness {
  QrHarness({
    required this.repo,
    required this.boost,
    required this.reader,
    required this.router,
    required this.settings,
  });

  final FakeQrRepository repo;
  final FakeScreenBoost boost;
  final FakeQrReader reader;
  final GoRouter? router;

  /// Le preferenze vere di micro_core sopra `SharedPreferences` finte (la scheda «Io», F17.10).
  final SettingsStore settings;
}

/// Il namespace delle preferenze nei test (in produzione e' `appId`).
const String kTestSettingsNamespace = 'qrme_test';

/// Monta [page] (o le [routes]) in italiano, tema scuro «A · Neon», con i doppi finti.
Future<QrHarness> pumpQr(
  WidgetTester tester, {
  Widget? page,
  List<RouteBase>? routes,
  String initialLocation = '/',
  bool pro = false,
  bool historyOn = true,
  List<QrCode>? rows,
  FakeQrReader? reader,
  ReadabilityCheck? readability,
  Map<String, String> settingsValues = const {},
  List<Override> extra = const [],
}) async {
  assert((page == null) != (routes == null), 'o una pagina o le rotte');
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = QrDatabase.memory();
  final repo = FakeQrRepository(db, rows: rows);
  final boost = FakeScreenBoost();
  final fakeReader = reader ?? FakeQrReader();
  // ⚑ Preferenze vere (SettingsStore) su SharedPreferences finte: [settingsValues] con le chiavi
  // senza namespace, come le scrive l'app (`QrSettingKeys`).
  SharedPreferences.setMockInitialValues({
    for (final e in settingsValues.entries) '$kTestSettingsNamespace.${e.key}': e.value,
  });
  final settings = SettingsStore.withPreferences(
    await SharedPreferences.getInstance(),
    namespace: kTestSettingsNamespace,
  );
  const sku = 'qrme_pro_lifetime';
  final service = EntitlementService(
    appId: 'qrme',
    proSku: sku,
    gateway: FakePurchaseGateway.withProduct(sku, formattedPrice: '1,99 €'),
    store: EntitlementStore(file: File('${Directory.systemTemp.path}/qr_me_test_entitlement.json')),
    installId: InstallId.fixed('00000000-0000-0000-0000-000000000000'),
  );
  final tmp = Directory.systemTemp.createTempSync('qrme_widget_');
  addTearDown(() async {
    service.dispose();
    await repo.dispose();
    await db.close();
    try {
      tmp.deleteSync(recursive: true);
    } on Object {
      // Su Windows un file ancora aperto puo' impedirlo: e' una cartella temporanea.
    }
  });
  final router = routes == null ? null : GoRouter(initialLocation: initialLocation, routes: routes);
  final theme = withQrLook(
    MicroTheme.dark(seed: const Color(0xFF3BD13B), fontFamily: 'PlusJakartaSans'),
    QrPalette.dark,
  );
  const delegates = [
    L.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  const locales = [Locale('it'), Locale('en')];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        settingsProvider.overrideWithValue(settings),
        appPathsProvider.overrideWithValue(AppPaths.underRoot(tmp)),
        featureGateProvider.overrideWithValue(FeatureGate(limits: qrFeatureLimits, isPro: pro)),
        isProProvider.overrideWithValue(pro),
        entitlementProvider.overrideWith(() => FakeEntitlementNotifier(service)),
        historyEnabledProvider.overrideWith(() => FixedHistoryNotifier(historyOn)),
        screenBoostProvider.overrideWithValue(boost),
        qrImageReaderProvider.overrideWithValue(fakeReader),
        readabilityCheckProvider.overrideWithValue(
          readability ?? FakeReadabilityCheck(Readability.readable),
        ),
        ...extra,
      ],
      child: router != null
          ? MaterialApp.router(
              locale: const Locale('it'),
              supportedLocales: locales,
              localizationsDelegates: delegates,
              theme: theme,
              routerConfig: router,
            )
          : MaterialApp(
              locale: const Locale('it'),
              supportedLocales: locales,
              localizationsDelegates: delegates,
              theme: theme,
              home: page,
            ),
    ),
  );
  await tester.pumpAndSettle();
  return QrHarness(
    repo: repo,
    boost: boost,
    reader: fakeReader,
    router: router,
    settings: settings,
  );
}

/// Una rotta che registra l'`extra` ricevuto e mostra un testo riconoscibile.
GoRoute captureRoute(String path, List<Object?> sink, {String label = 'DESTINAZIONE'}) => GoRoute(
  path: path,
  builder: (_, s) {
    // Una pagina si ricostruisce piu' volte: si registra ogni `extra` una volta sola.
    if (!sink.any((e) => identical(e, s.extra))) sink.add(s.extra);
    return Scaffold(body: Text('$label $path'));
  },
);

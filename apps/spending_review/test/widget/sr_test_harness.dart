import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/micro_ocr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spending_review/app/app.dart';
import 'package:spending_review/app/entitlement.dart';
import 'package:spending_review/app/feature_limits.dart';
import 'package:spending_review/app/providers.dart';
import 'package:spending_review/app/sr_palette.dart';
import 'package:spending_review/data/database.dart';
import 'package:spending_review/data/spesa_repository.dart';
import 'package:spending_review/domain/lettura/scontrino_parser.dart';
import 'package:spending_review/domain/quantita.dart';
import 'package:spending_review/domain/riga_spesa.dart';
import 'package:spending_review/domain/spesa.dart';
import 'package:spending_review/l10n/generated/app_localizations.dart';
import 'package:spending_review/services/aptica.dart';
import 'package:spending_review/services/fotocamera.dart';
import 'package:spending_review/services/impostazioni_sistema.dart';
import 'package:spending_review/services/lettura_service.dart';

/// I doppi finti e il montaggio delle pagine di Spending Review per i test di widget.
///
/// ☠ Repository finto in memoria e non Drift su `SpendingDatabase.memory()`: dentro `testWidgets`
/// FakeAsync congela l'I/O di SQLite e gli stream non arrivano mai (lezione di TrashCan, ripetuta
/// in Film Tracker e QR Me). Che le scritture vere funzionino lo dimostra
/// test/data/spesa_repository_test.dart.

/// Il «telefono» dei test: un giorno fisso.
final DateTime kOra = DateTime(2026, 10, 11, 10, 30);

/// Un repository in memoria con le stesse regole di quello vero (una spesa in corso, totale
/// scritto alla chiusura, spese chiuse mai cancellate), che registra le chiamate.
class FakeSpesaRepository extends SpesaRepository {
  FakeSpesaRepository(super.db, {this.inCorso, List<Spesa>? chiuse, List<Negozio>? negozi})
    : chiuse = [...?chiuse],
      negozi = [...?negozi];

  Spesa? inCorso;
  final List<Spesa> chiuse;
  final List<Negozio> negozi;
  final _cambi = StreamController<void>.broadcast();
  var _id = 1000;

  /// Le chiamate a `salvaScontrino` (spesaId).
  final List<int> scontriniSalvati = [];

  void _cambiato() => _cambi.add(null);

  Stream<T> _osserva<T>(T Function() leggi) async* {
    yield leggi();
    yield* _cambi.stream.map((_) => leggi());
  }

  static Spesa copia(
    Spesa s, {
    List<RigaSpesa>? righe,
    List<RigaSpesa>? righeScontrino,
    Money? budget,
    bool togliBudget = false,
    Money? totaleScontrino,
  }) => Spesa(
    id: s.id,
    stato: s.stato,
    negozioId: s.negozioId,
    iniziataIl: s.iniziataIl,
    chiusaIl: s.chiusaIl,
    dataSpesa: s.dataSpesa,
    budget: togliBudget ? null : (budget ?? s.budget),
    righe: righe ?? s.righe,
    righeScontrino: righeScontrino ?? s.righeScontrino,
    totaleScontrino: totaleScontrino ?? s.totaleScontrino,
    fonte: s.fonte,
    totaleSalvato: s.totaleSalvato,
  );

  @override
  Stream<Spesa?> osservaInCorso() => _osserva(() => inCorso);

  @override
  Future<int> assicuraInCorso({Money? budgetPredefinito}) async {
    final s = inCorso;
    if (s != null) return s.id!;
    final nuova = Spesa(
      id: _id++,
      stato: StatoSpesa.inCorso,
      iniziataIl: kOra.toUtc(),
      budget: budgetPredefinito,
      righe: const [],
    );
    inCorso = nuova;
    _cambiato();
    return nuova.id!;
  }

  @override
  Future<int> aggiungiRiga(RigaSpesa riga) async {
    await assicuraInCorso();
    final id = _id++;
    inCorso = copia(inCorso!, righe: [...inCorso!.righe, riga.copyWith(id: id)]);
    _cambiato();
    return id;
  }

  @override
  Future<void> aggiornaRiga(RigaSpesa riga) async {
    inCorso = copia(inCorso!, righe: [for (final r in inCorso!.righe) r.id == riga.id ? riga : r]);
    _cambiato();
  }

  @override
  Future<void> eliminaRiga(int rigaId) async {
    inCorso = copia(inCorso!, righe: [for (final r in inCorso!.righe) if (r.id != rigaId) r]);
    _cambiato();
  }

  @override
  Future<int?> posizioneDi(int rigaId) async {
    final i = inCorso?.righe.indexWhere((r) => r.id == rigaId) ?? -1;
    return i < 0 ? null : i;
  }

  @override
  Future<void> ripristinaRiga(RigaSpesa riga, {required int posizione}) async {
    await assicuraInCorso();
    final righe = [...inCorso!.righe]..insert(posizione.clamp(0, inCorso!.righe.length), riga);
    inCorso = copia(inCorso!, righe: righe);
    _cambiato();
  }

  @override
  Future<bool> incrementaUltima() async {
    final s = inCorso;
    if (s == null || s.righe.isEmpty) return false;
    final u = s.righe.last;
    final n = u.pezzi;
    if (n == null || u.eSconto || n >= Pezzi.massimo) return false;
    inCorso = copia(s, righe: [...s.righe.sublist(0, s.righe.length - 1), u.copyWith(quantita: Pezzi(n + 1))]);
    _cambiato();
    return true;
  }

  @override
  Future<void> impostaBudget(Money? budget) async {
    await assicuraInCorso();
    inCorso = copia(inCorso!, budget: budget, togliBudget: budget == null);
    _cambiato();
  }

  @override
  Future<void> salvaScontrino(int spesaId, LetturaScontrino lettura) async {
    scontriniSalvati.add(spesaId);
    inCorso = copia(
      inCorso!,
      righeScontrino: [for (final r in lettura.righe) ?SpesaRepository.rigaDaScontrino(r)],
      totaleScontrino: lettura.totale,
    );
    _cambiato();
  }

  @override
  Future<int> chiudi({required CivilDate data, int? negozioId, required FonteRighe fonte}) async {
    final s = inCorso;
    if (s == null) throw StateError('nessuna spesa in corso');
    final totale = Spesa(
      stato: StatoSpesa.inCorso,
      iniziataIl: s.iniziataIl,
      righe: s.righe,
      righeScontrino: s.righeScontrino,
      totaleScontrino: s.totaleScontrino,
      fonte: fonte,
    ).totale;
    chiuse.add(spesaChiusa(s.id!, data, totale, negozioId: negozioId, budget: s.budget, righe: s.righe, fonte: fonte));
    inCorso = null;
    _cambiato();
    return s.id!;
  }

  @override
  Future<int> registraDaScontrino(LetturaScontrino lettura, {required CivilDate data, int? negozioId}) async {
    final id = _id++;
    chiuse.add(
      spesaChiusa(
        id,
        data,
        lettura.totale ?? lettura.sommaRighe,
        negozioId: negozioId,
        fonte: FonteRighe.scontrino,
        righeScontrino: [for (final r in lettura.righe) ?SpesaRepository.rigaDaScontrino(r)],
      ),
    );
    _cambiato();
    return id;
  }

  @override
  Future<void> scartaInCorso() async {
    inCorso = null;
    _cambiato();
  }

  List<Spesa> get _ordinate => [...chiuse]
    ..sort((a, b) {
      final d = b.dataSpesa!.compareTo(a.dataSpesa!);
      return d != 0 ? d : b.id!.compareTo(a.id!);
    });

  @override
  Stream<List<Spesa>> osservaChiuse({int? limite}) =>
      _osserva(() => limite == null ? _ordinate : _ordinate.take(limite).toList());

  @override
  Stream<int> osservaNumeroChiuse() => _osserva(() => chiuse.length);

  @override
  Future<int> contaChiuse() async => chiuse.length;

  @override
  Future<Spesa?> perId(int id) async => chiuse.where((s) => s.id == id).firstOrNull;

  @override
  Future<void> eliminaSpesa(int id) async {
    chiuse.removeWhere((s) => s.id == id);
    _cambiato();
  }

  @override
  Stream<List<Negozio>> osservaNegozi() => _osserva(() => [...negozi]..sort((a, b) => a.nome.compareTo(b.nome)));

  @override
  Future<int> negozioPerNome(String nome) async {
    final e = negozi.where((n) => n.nome.toLowerCase() == nome.trim().toLowerCase()).firstOrNull;
    if (e != null) return e.id;
    final n = Negozio(id: _id++, nome: nome.trim(), creatoIl: 0);
    negozi.add(n);
    _cambiato();
    return n.id;
  }

  Future<void> dispose() => _cambi.close();
}

/// Una spesa chiusa di prova.
Spesa spesaChiusa(
  int id,
  CivilDate data,
  Money totale, {
  int? negozioId,
  Money? budget,
  List<RigaSpesa> righe = const [],
  List<RigaSpesa> righeScontrino = const [],
  FonteRighe fonte = FonteRighe.contate,
}) => Spesa(
  id: id,
  stato: StatoSpesa.chiusa,
  negozioId: negozioId,
  iniziataIl: data.toLocalMidnight().toUtc(),
  chiusaIl: data.toLocalMidnight().toUtc(),
  dataSpesa: data,
  budget: budget,
  righe: righe,
  righeScontrino: righeScontrino,
  fonte: fonte,
  totaleSalvato: totale,
);

/// Una riga battuta col tastierino.
RigaSpesa rigaTastierino(int cents, {int pezzi = 1, String nome = '', int? id}) => RigaSpesa(
  id: id,
  nome: nome,
  quantita: Pezzi(pezzi),
  prezzoUnitario: Money.cents(cents),
  origine: OrigineRiga.tastierino,
);

/// Le vibrazioni registrate invece che fatte.
class ApticaRegistrata extends Aptica {
  ApticaRegistrata() : super(attiva: false);

  final List<String> fatte = [];

  @override
  void tasto() => fatte.add('tasto');
  @override
  void rifiuto() => fatte.add('rifiuto');
  @override
  void soglia() => fatte.add('soglia');
  @override
  void aggiunto() => fatte.add('aggiunto');
}

/// La fotocamera finta: un riquadro grigio come anteprima, uno «scatto» che crea un file
/// temporaneo vero (per controllare che sparisca), o [errore] all'apertura.
class ObiettivoFinto implements Obiettivo {
  ObiettivoFinto({this.errore, required this.cartella});

  final Object? errore;
  final Directory cartella;
  int scatti = 0;
  bool chiuso = false;

  @override
  Future<void> apri() async {
    final e = errore;
    if (e != null) throw e;
  }

  @override
  Widget anteprima() => const ColoredBox(key: ValueKey('anteprima_finta'), color: Colors.grey);

  @override
  Future<String> scatta() async {
    scatti++;
    final f = File('${cartella.path}/scatto_$scatti.jpg')..writeAsBytesSync(Uint8List.fromList([1, 2, 3]));
    return f.path;
  }

  @override
  Future<bool> torcia(bool accesa) async => false;

  @override
  Future<void> chiudi() async => chiuso = true;
}

class ImpostazioniFinte extends ImpostazioniSistema {
  int aperture = 0;

  @override
  Future<bool> apri() async {
    aperture++;
    return true;
  }
}

class FakeEntitlementNotifier extends EntitlementNotifier {
  FakeEntitlementNotifier(this._fake);

  final EntitlementService _fake;

  @override
  EntitlementService get service => _fake;

  @override
  EntitlementView build() => EntitlementView(entitlement: _fake.current, busy: false, storeAvailable: true);
}

/// Cio' che i test leggono dopo il montaggio.
class SrHarness {
  SrHarness({
    required this.repo,
    required this.motore,
    required this.aptica,
    required this.router,
    required this.cartella,
    required this.foto,
    required this.container,
  });

  final FakeSpesaRepository repo;
  final FakeOcrEngine motore;
  final ApticaRegistrata aptica;
  final GoRouter? router;

  /// La cartella temporanea del test (scatti finti, foto «dalla galleria»).
  final Directory cartella;

  /// I percorsi che «Da una foto» restituira'.
  final List<String> foto;
  final ProviderContainer container;
}

/// Il namespace delle preferenze nei test.
const String kTestSettingsNamespace = 'sr_test';

/// Monta [page], oppure l'app intera col router vero (`buildRouter`) a [initialLocation], in
/// italiano, tema scuro «C · Una mano», con i doppi finti.
Future<SrHarness> pumpSr(
  WidgetTester tester, {
  Widget? page,
  String initialLocation = '/',
  bool devAttiva = false,
  bool pro = false,
  bool chiaro = false,
  Spesa? inCorso,
  List<Spesa>? chiuse,
  List<Negozio>? negozi,
  List<RigaOcr> righeOcr = const [],
  Object? erroreOcr,
  Object? erroreFotocamera,
  List<String> foto = const [],
  Map<String, Object> settingsValues = const {},
  List<Override> extra = const [],
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = SpendingDatabase.memory();
  final repo = FakeSpesaRepository(db, inCorso: inCorso, chiuse: chiuse, negozi: negozi);
  final motore = FakeOcrEngine(righe: righeOcr, errore: erroreOcr);
  final aptica = ApticaRegistrata();
  final cartella = Directory.systemTemp.createTempSync('sr_widget_');
  final percorsiFoto = [...foto];
  SharedPreferences.setMockInitialValues({
    for (final e in settingsValues.entries) '$kTestSettingsNamespace.${e.key}': e.value,
  });
  final settings = SettingsStore.withPreferences(await SharedPreferences.getInstance(), namespace: kTestSettingsNamespace);
  const sku = 'spendingreview_pro_lifetime';
  final service = EntitlementService(
    appId: 'spendingreview',
    proSku: sku,
    gateway: FakePurchaseGateway.withProduct(sku, formattedPrice: '2,99 €'),
    store: EntitlementStore(file: File('${cartella.path}/entitlement.json')),
    installId: InstallId.fixed('00000000-0000-0000-0000-000000000000'),
  );
  addTearDown(() async {
    service.dispose();
    await repo.dispose();
    await db.close();
    try {
      cartella.deleteSync(recursive: true);
    } on Object {
      // Su Windows un file ancora aperto puo' impedirlo: e' una cartella temporanea.
    }
  });
  final router = page == null ? buildRouter(devAttiva: devAttiva) : null;
  if (router != null) {
    router.go(initialLocation);
    addTearDown(router.dispose);
  }
  final p = chiaro ? SrPalette.chiaro : SrPalette.scuro;
  final base = chiaro
      ? MicroTheme.light(seed: const Color(0xFF4ADE80), fontFamily: 'PlusJakartaSans', displayFontFamily: kNumeriFont)
      : MicroTheme.dark(seed: const Color(0xFF4ADE80), fontFamily: 'PlusJakartaSans', displayFontFamily: kNumeriFont);
  final theme = withSrLook(base, p);
  const delegates = [
    L.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  const locales = [Locale('it'), Locale('en')];
  final container = ProviderContainer(
    overrides: [
      spesaRepositoryProvider.overrideWithValue(repo),
      settingsProvider.overrideWithValue(settings),
      appPathsProvider.overrideWithValue(AppPaths.underRoot(cartella)),
      featureGateProvider.overrideWithValue(FeatureGate(limits: srFeatureLimits, isPro: pro)),
      isProProvider.overrideWithValue(pro),
      entitlementProvider.overrideWith(() => FakeEntitlementNotifier(service)),
      ocrEngineProvider.overrideWithValue(motore),
      letturaServiceProvider.overrideWithValue(
        LetturaService(motore: motore, ora: () => kOra, cancellabile: (_) async => true),
      ),
      obiettivoProvider.overrideWithValue(() => ObiettivoFinto(errore: erroreFotocamera, cartella: cartella)),
      ritaglioProvider.overrideWithValue((foto, mirino, {required anteprima}) async => foto),
      scegliFotoProvider.overrideWithValue(({required multiple}) async => List.of(percorsiFoto)),
      impostazioniSistemaProvider.overrideWithValue(ImpostazioniFinte()),
      apticaProvider.overrideWithValue(aptica),
      oraProvider.overrideWithValue(() => kOra),
      ...extra,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
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
  return SrHarness(
    repo: repo,
    motore: motore,
    aptica: aptica,
    router: router,
    cartella: cartella,
    foto: percorsiFoto,
    container: container,
  );
}

/// Carica i due font veri (Space Grotesk e Plus Jakarta Sans): servono ai test di misura, dove il
/// font di prova di Flutter (tutti i glifi quadrati) darebbe larghezze false.
Future<void> caricaFontVeri() async {
  for (final (famiglia, file) in [
    (kNumeriFont, 'assets/fonts/SpaceGrotesk-Variable.ttf'),
    ('PlusJakartaSans', 'assets/fonts/PlusJakartaSans-Variable.ttf'),
  ]) {
    final bytes = File(file).readAsBytesSync();
    await (FontLoader(famiglia)..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))))).load();
  }
}

/// Un telefono di [larghezza]×[altezza] dp col testo al [scala].
void telefono(WidgetTester tester, {double larghezza = 412, double altezza = 915, double scala = 1}) {
  tester.view
    ..physicalSize = Size(larghezza * 3, altezza * 3)
    ..devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scala;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Il canale delle vibrazioni non serve: [ApticaRegistrata] le intercetta. Questo zittisce le
/// chiamate di sistema che Material fa da se' (feedback dei bottoni).
void zittisciPiattaforma() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (_) async => null,
  );
}

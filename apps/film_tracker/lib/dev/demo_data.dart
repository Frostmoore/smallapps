import 'package:flutter/foundation.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../data/film_repository.dart';
import '../domain/film_types.dart';
import '../domain/roll_status.dart';

/// Dati di esempio per provare l'app e per gli screenshot degli store.
///
/// `flutter run --dart-define=FT_DEMO=true`
///
/// ⚑ Perche' esistono: le tre sezioni della home, la timeline e le statistiche si vedono
/// solo con mesi di rullini, e da fuori (adb, test d'integrazione) non si possono inserire
/// date nel passato. Stesso principio dei dati di esempio di Scorte Calore.
///
/// ☠ Mai in release: anche compilato con il define, in release non fa niente.
const bool demoRequested = bool.fromEnvironment('FT_DEMO');

bool get demoEnabled => demoRequested && !kReleaseMode;

/// Sviluppo e stampa di esempio; le date sono in giorni fa.
typedef _Dev = ({String? lab, int? sent, int? back, int? dev, int? scan, bool self});
typedef _Print = ({String lab, int sent, int? back, String format, int count, int cents});

/// Riempie il database se non ha rullini. Restituisce true se ha scritto qualcosa.
///
/// Tre macchine, dodici rullini negli ultimi otto mesi, in tutte e tre le sezioni: due in
/// macchina, uno finito e non consegnato, due in laboratorio, sette in archivio con
/// sviluppi e stampe (uno con due ordini da laboratori diversi, uno sviluppato in casa, uno
/// tirato a 1600).
Future<bool> seedDemoData(AppDatabase db, {bool english = false}) async {
  if (!demoEnabled) return false;
  final repo = FilmRepository(db);
  if ((await repo.allRolls()).isNotEmpty) return false;
  final oggi = CivilDate.today();
  CivilDate fa(int giorni) => oggi.addDays(-giorni);

  final om2 = await repo.addCamera(manufacturer: 'Olympus', model: 'OM-2', format: FilmFormat.mm35);
  final fm2 = await repo.addCamera(manufacturer: 'Nikon', model: 'FM2', format: FilmFormat.mm35);
  final yashica = await repo.addCamera(
    manufacturer: 'Yashica',
    model: 'Mat-124G',
    format: FilmFormat.medium120,
    note: english ? 'Twin-lens, 6x6' : 'Biottica, 6x6',
  );

  final stocks = {for (final s in await repo.allStocks()) s.displayName: s};
  const milano = 'Fotoservice Milano';
  const colore = 'Labo Colore';

  final rulli =
      <
        ({
          String film,
          int camera,
          int loaded,
          int? finished,
          RollStatus status,
          String? it,
          String? en,
          int cost,
          int? iso,
          _Dev? dev,
          List<_Print> prints,
        })
      >[
        (
          film: 'Kodak Portra 400',
          camera: om2,
          loaded: 230,
          finished: 200,
          status: RollStatus.archived,
          it: 'Lisbona - maggio',
          en: 'Lisbon - May',
          cost: 1890,
          iso: null,
          dev: (lab: milano, sent: 198, back: 185, dev: 1200, scan: 800, self: false),
          prints: [(lab: milano, sent: 180, back: 172, format: '10x15', count: 24, cents: 1450)],
        ),
        (
          film: 'Ilford HP5+',
          camera: fm2,
          loaded: 210,
          finished: 190,
          status: RollStatus.printed,
          it: 'Ritratti in studio',
          en: 'Studio portraits',
          cost: 1050,
          iso: null,
          dev: (lab: null, sent: null, back: 188, dev: 300, scan: null, self: true),
          prints: [(lab: milano, sent: 185, back: 178, format: '13x18', count: 6, cents: 900)],
        ),
        (
          film: 'Fujifilm Velvia 50',
          camera: om2,
          loaded: 180,
          finished: 160,
          status: RollStatus.developed,
          it: 'Dolomiti',
          en: 'Dolomites',
          cost: 2400,
          iso: null,
          dev: (lab: colore, sent: 158, back: 145, dev: 1800, scan: 1000, self: false),
          prints: [],
        ),
        (
          film: 'Kodak Portra 160',
          camera: yashica,
          loaded: 150,
          finished: 130,
          status: RollStatus.developed,
          it: 'Matrimonio di Giulia',
          en: "Giulia's wedding",
          cost: 1400,
          iso: null,
          dev: (lab: milano, sent: 128, back: 118, dev: 1500, scan: 1200, self: false),
          prints: [],
        ),
        (
          film: 'Kodak Tri-X 400',
          camera: fm2,
          loaded: 120,
          finished: 100,
          status: RollStatus.printed,
          it: 'Citta\' di notte',
          en: 'City at night',
          cost: 1290,
          iso: 1600,
          dev: (lab: colore, sent: 98, back: 90, dev: 1000, scan: null, self: false),
          prints: [
            (lab: colore, sent: 90, back: 84, format: '10x15', count: 36, cents: 1800),
            (lab: milano, sent: 40, back: 30, format: '20x30', count: 2, cents: 1200),
          ],
        ),
        (
          film: 'Kodak Gold 200',
          camera: om2,
          loaded: 95,
          finished: 70,
          status: RollStatus.developed,
          it: 'Mare d\'agosto',
          en: 'August by the sea',
          cost: 850,
          iso: null,
          dev: (lab: milano, sent: 68, back: 60, dev: 1000, scan: 600, self: false),
          prints: [],
        ),
        (
          film: 'Cinestill 800T',
          camera: fm2,
          loaded: 80,
          finished: 60,
          status: RollStatus.developed,
          it: null,
          en: null,
          cost: 2200,
          iso: null,
          dev: (lab: colore, sent: 58, back: 50, dev: 1300, scan: 900, self: false),
          prints: [],
        ),
        (
          film: 'Kodak Ektar 100',
          camera: yashica,
          loaded: 60,
          finished: 40,
          status: RollStatus.sentForDevelopment,
          it: 'Autunno in collina',
          en: 'Autumn hills',
          cost: 1450,
          iso: null,
          dev: (lab: milano, sent: 38, back: null, dev: null, scan: null, self: false),
          prints: [],
        ),
        (
          film: 'Ilford Delta 400',
          camera: fm2,
          loaded: 45,
          finished: 25,
          status: RollStatus.sentForDevelopment,
          it: null,
          en: null,
          cost: 1150,
          iso: null,
          dev: (lab: colore, sent: 20, back: null, dev: null, scan: null, self: false),
          prints: [],
        ),
        (
          film: 'Kodak Ultramax 400',
          camera: om2,
          loaded: 30,
          finished: 10,
          status: RollStatus.exposed,
          it: 'Vendemmia',
          en: 'Grape harvest',
          cost: 1100,
          iso: null,
          dev: null,
          prints: [],
        ),
        (
          film: 'Kodak Portra 400',
          camera: yashica,
          loaded: 12,
          finished: null,
          status: RollStatus.loaded,
          it: null,
          en: null,
          cost: 1650,
          iso: null,
          dev: null,
          prints: [],
        ),
        (
          film: 'Ilford HP5+',
          camera: fm2,
          loaded: 5,
          finished: null,
          status: RollStatus.loaded,
          it: 'Mercato coperto',
          en: 'Covered market',
          cost: 1050,
          iso: 800,
          dev: null,
          prints: [],
        ),
      ];

  for (final r in rulli) {
    final stock = stocks[r.film]!;
    final format = r.camera == yashica ? FilmFormat.medium120 : FilmFormat.mm35;
    final rollId = await repo.addRoll(
      filmStockId: stock.id,
      filmName: stock.displayName,
      format: format,
      nominalIso: stock.iso,
      exposedIso: r.iso,
      cameraId: r.camera,
      loadedAt: fa(r.loaded),
      finishedAt: r.finished == null ? null : fa(r.finished!),
      frames: format.defaultFrames,
      title: english ? r.en : r.it,
      costCents: r.cost,
      status: r.status,
    );
    final d = r.dev;
    if (d != null) {
      await repo.saveDevelopment(
        rollId: rollId,
        laboratory: d.lab,
        submittedAt: d.sent == null ? null : fa(d.sent!),
        returnedAt: d.back == null ? null : fa(d.back!),
        developmentCostCents: d.dev,
        scanCostCents: d.scan,
        process: stock.processEnum,
        selfDeveloped: d.self,
      );
    }
    for (final p in r.prints) {
      await repo.addPrintOrder(
        rollId: rollId,
        laboratory: p.lab,
        submittedAt: fa(p.sent),
        returnedAt: p.back == null ? null : fa(p.back!),
        format: p.format,
        numberOfPrints: p.count,
        costCents: p.cents,
      );
    }
  }
  return true;
}

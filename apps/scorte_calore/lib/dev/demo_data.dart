import 'package:flutter/foundation.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../data/scorte_repository.dart';
import '../domain/fuel_source.dart';
import '../domain/fuel_units.dart';

/// Dati di esempio per provare l'app e per gli screenshot degli store.
///
/// `flutter run --dart-define=SC_DEMO=true`
///
/// ⚑ Perche' esistono: la stima si accende solo dopo qualche giorno di misurazioni, e da
/// fuori (adb, test d'integrazione) non si possono inserire date nel passato. Stesso
/// principio dei dati di esempio di Full Freezer.
///
/// ☠ Mai in release: anche compilato con il define, in release non fa niente.
const bool demoRequested = bool.fromEnvironment('SC_DEMO');

bool get demoEnabled => demoRequested && !kReleaseMode;

/// Riempie il database se e' vuoto. Restituisce true se ha scritto qualcosa.
Future<bool> seedDemoData(AppDatabase db, SettingsStore settings, {bool english = false}) async {
  if (!demoEnabled) return false;
  final repo = ScorteRepository(db);
  if ((await repo.allSources()).isNotEmpty) return false;
  final oggi = CivilDate.today();

  // La stufa a pellet: due mesi di sacchi, con un rifornimento a meta' (la quantita' sale e
  // il calcolatore non la conta come consumo).
  final stufa = await repo.addSource(
    name: english ? 'Living room stove' : 'Stufa soggiorno',
    fuelType: FuelType.pellet,
    unitKey: FuelUnits.bags,
    unitWeightKg: 15,
    costPerUnitCents: 690,
  );
  for (final (giorniFa, sacchi) in const [(60, 70.0), (52, 64.0), (45, 58.0), (38, 52.0), (31, 46.0), (29, 90.0), (22, 83.0), (15, 76.0), (8, 69.0), (1, 62.0)]) {
    await repo.upsertMeasurement(stufa, Measurement.absolute(date: oggi.addDays(-giorniFa), quantity: sacchi));
  }

  // Gli acquisti di pellet: il pieno di settembre, un'aggiunta in ottobre e lo scorso inverno,
  // cosi' la pagina dei costi ha una spesa stagionale e il confronto fra inverni.
  for (final (giorniFa, sacchi, centesimi, fornitore) in const [
    (330, 70.0, 45500, 'Agrinova'),
    (210, 40.0, 26800, 'Agrinova'),
    (29, 50.0, 34500, 'Agrinova'),
    (4, 15.0, 10650, 'Brico'),
  ]) {
    await repo.addPurchase(
      sourceId: stufa,
      date: oggi.addDays(-giorniFa),
      quantity: sacchi,
      totalCostCents: centesimi,
      supplier: fornitore,
    );
  }

  // Il bombolone: letture del manometro, che diventano litri utili all'80%.
  final bombolone = await repo.addSource(
    name: english ? 'LPG tank' : 'Bombolone GPL',
    fuelType: FuelType.lpg,
    tankCapacity: 1000,
    costPerUnitCents: 85,
  );
  final spec = (await repo.sourceById(bombolone))!.toSpec();
  for (final (giorniFa, percento) in const [(40, 78.0), (30, 70.0), (20, 61.0), (10, 52.0), (2, 45.0)]) {
    final litri = 1000 * spec.usableFraction * percento / 100;
    await repo.upsertMeasurement(
      bombolone,
      Measurement(date: oggi.addDays(-giorniFa), quantity: litri, enteredAs: EnteredAs.percentage, rawInput: percento),
    );
  }

  await settings.setBool(SettingKeys.onboardingDone, true);
  return true;
}

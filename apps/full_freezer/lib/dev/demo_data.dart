import 'package:flutter/foundation.dart';
import 'package:micro_core/micro_core.dart';

import '../data/freezer_repository.dart';
import '../domain/capacity.dart';
import '../domain/units.dart';

/// Dati di esempio per provare l'app e per gli screenshot degli store.
///
/// `flutter run --dart-define=FF_DEMO=true`
///
/// ⚑ Perche' esistono: con un freezer vuoto non si vedono ne' le schede di "Da usare prima"
/// ne' il riempimento, e da fuori (adb, test d'integrazione) non si possono inserire date
/// nel passato. Il primo giro della nuova interfaccia, il 2026-10-07, mostrava solo
/// alimenti "di oggi".
///
/// ☠ Mai in release: anche compilato con il define, in release non fa niente. Un'app
/// pubblicata che si riempie da sola di spezzatino sarebbe un difetto, non una demo.
const bool demoRequested = bool.fromEnvironment('FF_DEMO');

bool get demoEnabled => demoRequested && !kReleaseMode;

/// Riempie il database se e' vuoto. Restituisce true se ha scritto qualcosa.
Future<bool> seedDemoData(FreezerRepository repo, SettingsStore settings, {required String freezerName}) async {
  if (!demoEnabled) return false;
  if ((await repo.allFreezers()).isNotEmpty) return false;

  final oggi = CivilDate.today();
  final freezer = await repo.addFreezer(
    name: freezerName,
    modelKey: 'combi_compact',
    capacityLiters: FreezerModels.byKey('combi_compact')!.liters,
  );
  final cassetto1 = await repo.addCompartment(freezer, 'Cassetto 1');
  final cassetto2 = await repo.addCompartment(freezer, 'Cassetto 2');

  // (nome, giorni fa, quantita', unita', categoria, litri, scomparto)
  final dati = <(String, int, double, String, String, double, int?)>[
    ('Spezzatino', 137, 2, Units.portions, 'meat_red', 1.2, cassetto1),
    ('Merluzzo', 124, 4, Units.pieces, 'fish', 1.6, cassetto2),
    ('Pane', 96, 1, Units.packs, 'bread', 2.5, null),
    ('Lasagne', 82, 3, Units.portions, 'prepared', 3.0, cassetto1),
    ('Fragole', 30, 500, Units.grams, 'fruit', 0.8, cassetto2),
    ('Piselli', 12, 2, Units.packs, 'vegetables', 1.8, cassetto2),
    ('Petto di pollo', 20, 4, Units.pieces, 'meat_white', 2.0, cassetto1),
    ('Gelato al pistacchio', 45, 1, Units.liters, 'ice_cream', 1.5, null),
    ('Ragù', 5, 4, Units.portions, 'prepared', 1.6, cassetto1),
    ('Minestrone', 18, 3, Units.portions, 'vegetables', 1.4, null),
    ('Macinato', 40, 1, Units.kilograms, 'meat_red', 1.3, cassetto1),
    ('Pizza', 33, 2, Units.pieces, 'bread', 3.0, null),
    ('Spinaci', 60, 2, Units.packs, 'vegetables', 1.6, cassetto2),
    ('Salmone', 25, 2, Units.pieces, 'fish', 0.9, cassetto2),
    ('Brodo', 70, 2, Units.liters, 'prepared', 2.2, null),
    ('Ghiaccioli', 8, 6, Units.pieces, 'ice_cream', 1.2, null),
    ('Mirtilli', 50, 250, Units.grams, 'fruit', 0.5, cassetto2),
    ('Salsicce', 15, 6, Units.pieces, 'meat_red', 1.5, cassetto1),
    ('Polpette', 28, 3, Units.portions, 'meat_red', 1.2, cassetto1),
    ('Fagiolini', 35, 1, Units.packs, 'vegetables', 0.8, cassetto2),
    ('Focaccia', 22, 1, Units.pieces, 'bread', 1.2, null),
    ('Gamberi', 55, 1, Units.packs, 'fish', 0.8, cassetto2),
    ('Sugo di pomodoro', 3, 3, Units.portions, 'prepared', 1.0, null),
  ];
  for (final (nome, giorni, q, unita, categoria, litri, scomparto) in dati) {
    await repo.addItem(
      NewItem(
        name: nome,
        freezerId: freezer,
        compartmentId: scomparto,
        quantity: q,
        unit: unita,
        category: categoria,
        frozenAt: oggi.addDays(-giorni),
        volumeLiters: litri,
        volumeManual: true,
      ),
    );
  }
  await settings.setBool(SettingKeys.onboardingDone, true);
  return true;
}

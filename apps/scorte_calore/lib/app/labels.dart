import 'package:intl/intl.dart';

import '../domain/fuel_units.dart';
import '../l10n/generated/app_localizations.dart';

/// I nomi visibili di combustibili e unita', dagli ARB.
///
/// ⚑ Il dominio (`lib/domain/fuel_units.dart`) conosce solo le chiavi: i nomi stanno qui,
/// perche' cambiano con la lingua e il dominio deve restare testabile senza Flutter.

/// Il nome del combustibile ("Pellet", "GPL").
String fuelName(L l, FuelType type) => switch (type) {
  FuelType.pellet => l.fuel_pellet,
  FuelType.lpg => l.fuel_lpg,
  FuelType.diesel => l.fuel_diesel,
  FuelType.wood => l.fuel_wood,
  FuelType.biomass => l.fuel_biomass,
};

/// Il nome dell'unita' accordato alla quantita' ("1 sacco", "12 sacchi"). Con quantita'
/// decimali si usa il plurale, come si dice "1,5 sacchi".
String unitName(L l, String unitKey, double quantity) {
  final n = quantity == 1 ? 1 : 2;
  return switch (unitKey) {
    FuelUnits.bags => l.unit_bags(n),
    FuelUnits.kg => l.unit_kg,
    FuelUnits.pallets => l.unit_pallets(n),
    FuelUnits.liters => l.unit_liters,
    FuelUnits.percent => l.unit_percent,
    FuelUnits.quintals => l.unit_quintals(n),
    FuelUnits.steres => l.unit_steres(n),
    FuelUnits.crates => l.unit_crates(n),
    _ => unitKey,
  };
}

/// Una quantita' con la sua unita', con i decimali giusti per l'unita' ("12 sacchi",
/// "344 L", "43 %"). [minDecimals] per i consumi giornalieri, che stanno spesso sotto l'unita'
/// ("0,8 sacchi al giorno").
///
/// ☠ Singolare e plurale si scelgono sul numero **arrotondato** che si mostra: con il valore
/// grezzo 0,98 diventava "1 bags" (visto sull'emulatore il 2026-10-07).
String formatAmount(L l, String unitKey, double quantity, {int minDecimals = 0}) {
  final unit = FuelUnits.tryByKey(unitKey);
  final decimali = (unit?.decimals ?? 1) < minDecimals ? minDecimals : (unit?.decimals ?? 1);
  final f = NumberFormat.decimalPattern(l.localeName)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = decimali;
  final testo = f.format(quantity);
  final mostrato = f.parse(testo).toDouble();
  return '$testo ${unitName(l, unitKey, mostrato)}';
}

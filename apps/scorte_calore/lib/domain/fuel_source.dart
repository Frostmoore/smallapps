import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import 'fuel_units.dart';

/// Una fonte di calore come la vedono i calcoli (develop_microapps.md F5.2, `fuel_sources`).
///
/// ⚑ **Non e' la riga di Drift**: il dominio non dipende dal database. Il data layer mappa
/// la riga su questo modello (e viceversa); restano fuori le colonne che ai calcoli non
/// servono (`active`, `createdAt`). Cosi' calcolatore e convertitore si provano con valori
/// scritti a mano, senza aprire un database.
@immutable
class FuelSourceSpec {
  const FuelSourceSpec({
    required this.id,
    required this.name,
    required this.fuelType,
    required this.unitKey,
    this.unitWeightKg,
    this.tankCapacity,
    required this.usableFraction,
    this.warningDays = FuelType.defaultWarningDays,
    this.costPerUnitCents,
  });

  /// Una fonte nuova con i default del suo combustibile (unita', frazione utile, anticipo).
  factory FuelSourceSpec.withDefaults({
    required int id,
    required String name,
    required FuelType fuelType,
    double? tankCapacity,
  }) => FuelSourceSpec(
    id: id,
    name: name,
    fuelType: fuelType,
    unitKey: fuelType.defaultUnitKey,
    tankCapacity: tankCapacity,
    usableFraction: fuelType.defaultUsableFraction,
  );

  final int id;

  /// Il nome scelto dall'utente ("Stufa soggiorno"). E' un dato, non un testo dell'app.
  final String name;

  final FuelType fuelType;

  /// Chiave in [FuelUnits] (`fuel_sources.unit`).
  final String unitKey;

  /// Peso in kg di una unita' (un sacco, una cassetta); solo per unita' con
  /// [FuelUnit.supportsWeight]. Opzionale: serve solo a mostrare un dato in piu' (F5.4).
  final double? unitWeightKg;

  /// Capacita' nominale del serbatoio, in litri, per `lpg`/`diesel`.
  final double? tankCapacity;

  /// Frazione della capacita' nominale che si puo' davvero usare (0,80 per il GPL).
  final double usableFraction;

  /// Giorni di anticipo fra il riordino consigliato e l'esaurimento stimato.
  final int warningDays;

  final int? costPerUnitCents;

  FuelUnit get unit => FuelUnits.byKey(unitKey);

  /// Capacita' **utile**: nominale x frazione utile. Null senza capacita'.
  double? get usableCapacity => tankCapacity == null ? null : tankCapacity! * usableFraction;

  FuelSourceSpec copyWith({
    String? name,
    String? unitKey,
    double? unitWeightKg,
    double? tankCapacity,
    double? usableFraction,
    int? warningDays,
    int? costPerUnitCents,
  }) => FuelSourceSpec(
    id: id,
    name: name ?? this.name,
    fuelType: fuelType,
    unitKey: unitKey ?? this.unitKey,
    unitWeightKg: unitWeightKg ?? this.unitWeightKg,
    tankCapacity: tankCapacity ?? this.tankCapacity,
    usableFraction: usableFraction ?? this.usableFraction,
    warningDays: warningDays ?? this.warningDays,
    costPerUnitCents: costPerUnitCents ?? this.costPerUnitCents,
  );

  @override
  bool operator ==(Object other) =>
      other is FuelSourceSpec &&
      other.id == id &&
      other.name == name &&
      other.fuelType == fuelType &&
      other.unitKey == unitKey &&
      other.unitWeightKg == unitWeightKg &&
      other.tankCapacity == tankCapacity &&
      other.usableFraction == usableFraction &&
      other.warningDays == warningDays &&
      other.costPerUnitCents == costPerUnitCents;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    fuelType,
    unitKey,
    unitWeightKg,
    tankCapacity,
    usableFraction,
    warningDays,
    costPerUnitCents,
  );

  @override
  String toString() => 'FuelSourceSpec($id, ${fuelType.key}, $unitKey)';
}

/// Cosa ha digitato l'utente in `stock_measurements.enteredAs` (F5.2).
enum EnteredAs {
  /// Una quantita' nell'unita' della fonte (12 sacchi, 430 litri).
  absolute('absolute'),

  /// Una lettura del manometro, in percentuale.
  percentage('percentage');

  const EnteredAs(this.key);

  /// Valore salvato nel database. **Non si rinomina mai.**
  final String key;

  static EnteredAs? byKey(String? key) {
    for (final e in values) {
      if (e.key == key) return e;
    }
    return null;
  }
}

/// Una misurazione della scorta (F5.2, `stock_measurements`), senza id e nota: ai calcoli
/// servono solo data, quantita' e cosa ha digitato l'utente.
///
/// ⚑ **Perche' [enteredAs] e [rawInput]**: se l'utente cambia la capacita' del serbatoio
/// dopo dieci misurazioni in percentuale, le quantita' vanno ricalcolate dal valore grezzo
/// (`QuantityConverter.recompute`). Senza, quelle misurazioni sarebbero perse.
@immutable
class Measurement {
  const Measurement({
    required this.date,
    required this.quantity,
    required this.enteredAs,
    required this.rawInput,
  });

  /// Una misurazione digitata come quantita': il valore grezzo e' la quantita' stessa.
  const Measurement.absolute({required this.date, required this.quantity})
    : enteredAs = EnteredAs.absolute,
      rawInput = quantity;

  final CivilDate date;

  /// Nell'unita' della fonte, gia' convertita.
  final double quantity;

  final EnteredAs enteredAs;

  /// Il valore digitato, prima della conversione (la percentuale, se [enteredAs] e'
  /// `percentage`).
  final double rawInput;

  Measurement withQuantity(double newQuantity) =>
      Measurement(date: date, quantity: newQuantity, enteredAs: enteredAs, rawInput: rawInput);

  @override
  bool operator ==(Object other) =>
      other is Measurement &&
      other.date == date &&
      other.quantity == quantity &&
      other.enteredAs == enteredAs &&
      other.rawInput == rawInput;

  @override
  int get hashCode => Object.hash(date, quantity, enteredAs, rawInput);

  @override
  String toString() => 'Measurement($date, $quantity, ${enteredAs.key} $rawInput)';
}

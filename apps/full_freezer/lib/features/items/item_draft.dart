import 'package:drift/drift.dart' show Value;
import 'package:micro_core/micro_core.dart';

import '../../data/database.dart';
import '../../data/freezer_repository.dart';
import '../../domain/capacity.dart';
import '../../domain/category_guess.dart';
import '../../domain/units.dart';

/// Un alimento mentre lo si scrive: lo condividono l'inserimento rapido e quello completo.
///
/// ⚑ Perche' una bozza comune: "Altri dettagli" deve aprire la pagina completa **con
/// quello che si era gia' scritto** (F4.5). Passando la stessa bozza non si perde niente,
/// e le due schermate non possono calcolare l'ingombro in due modi diversi.
class ItemDraft {
  ItemDraft({
    required this.freezerId,
    required this.frozenAt,
    this.compartmentId,
    this.name = '',
    this.quantity = 1,
    this.unit = Units.fallback,
    this.category,
    this.categoryManual = false,
    this.reminderAfterDays,
    double? volumeLiters,
    this.volumeManual = false,
    this.photoPath,
    this.note,
  }) : _manualVolume = volumeLiters;

  /// La bozza di un alimento gia' salvato, per modificarlo.
  factory ItemDraft.fromItem(Item item) => ItemDraft(
    freezerId: item.freezerId,
    compartmentId: item.compartmentId,
    frozenAt: CivilDate.parse(item.frozenAt),
    name: item.name,
    quantity: item.quantity,
    unit: item.unit,
    category: item.category,
    categoryManual: true,
    reminderAfterDays: item.reminderAfterDays,
    volumeLiters: item.volumeLiters,
    volumeManual: item.volumeManual,
    photoPath: item.photoPath,
    note: item.note,
  );

  int freezerId;
  int? compartmentId;
  CivilDate frozenAt;
  String name;
  double quantity;
  String unit;

  /// La categoria; se [categoryManual] e' falso la si deduce dal nome a ogni modifica.
  String? category;
  bool categoryManual;

  int? reminderAfterDays;
  bool volumeManual;
  String? photoPath;
  String? note;

  double? _manualVolume;

  static const CapacityEstimator _estimator = CapacityEstimator();

  /// Aggiorna il nome e, se l'utente non l'ha scelta a mano, la categoria.
  void setName(String value) {
    name = value;
    if (!categoryManual) category = guessCategory(value);
  }

  void setCategory(String? key) {
    category = key;
    categoryManual = true;
  }

  /// L'ingombro: quello corretto a mano, oppure la stima aggiornata.
  double get volumeLiters => volumeManual && _manualVolume != null
      ? _manualVolume!
      : _estimator.estimateLiters(quantity: quantity, unit: unit, categoryKey: category);

  /// Correzione a mano dell'ingombro (F4.3b, prima delle due correzioni).
  void setManualVolume(double liters) {
    _manualVolume = liters;
    volumeManual = true;
  }

  /// Torna alla stima automatica.
  void resetVolume() {
    _manualVolume = null;
    volumeManual = false;
  }

  bool get isValid => name.trim().isNotEmpty && quantity > 0;

  NewItem toNewItem() => NewItem(
    name: name,
    freezerId: freezerId,
    compartmentId: compartmentId,
    category: category,
    quantity: quantity,
    unit: unit,
    frozenAt: frozenAt,
    reminderAfterDays: reminderAfterDays,
    volumeLiters: volumeLiters,
    volumeManual: volumeManual,
    photoPath: photoPath,
    note: note,
  );

  /// Applica la bozza a una riga esistente, per `FreezerRepository.updateItem`.
  Item applyTo(Item item) => item.copyWith(
    name: name,
    freezerId: freezerId,
    compartmentId: Value(compartmentId),
    category: Value(category),
    quantity: quantity,
    unit: unit,
    frozenAt: frozenAt.toIso(),
    reminderAfterDays: Value(reminderAfterDays),
    volumeLiters: volumeLiters,
    volumeManual: volumeManual,
    photoPath: Value(photoPath),
    note: Value(note),
  );
}

/// Il passo dello stepper della quantita', per unita'.
double quantityStep(String unit) => switch (unit) {
  Units.grams => 100,
  Units.kilograms || Units.liters => 0.5,
  _ => 1,
};

/// La quantita' proposta quando si sceglie un'unita'.
double defaultQuantity(String unit) => switch (unit) {
  Units.grams => 500,
  Units.kilograms || Units.liters => 1,
  _ => 1,
};

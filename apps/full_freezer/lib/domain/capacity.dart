import 'package:meta/meta.dart';

import 'categories.dart';
import 'units.dart';

/// Un modello di freezer fra cui l'utente sceglie quando ne aggiunge uno (F4.3b).
@immutable
class FreezerModel {
  const FreezerModel({required this.key, required this.liters, required this.iconKey});

  /// Chiave stabile, salvata in `freezers.modelKey`. Il nome sta negli ARB
  /// (`freezerModel_<key>`). **Non si rinomina mai.**
  final String key;

  /// Litri netti tipici del vano congelatore.
  final double liters;

  final String iconKey;
}

/// I modelli, **dal piu' piccolo al piu' grande**.
///
/// I litri sono il valore tipico trovato nelle schede tecniche di mercato il 2026-10-06;
/// intervalli e fonti in develop_microapps.md F4.3b. Cambiare un numero qui NON cambia i
/// freezer gia' creati: `freezers.capacityLiters` salva i litri, non solo il modello.
abstract final class FreezerModels {
  static const String customKey = 'custom';

  static const List<FreezerModel> all = <FreezerModel>[
    FreezerModel(key: 'ice_box', liters: 15, iconKey: 'ice_box'),
    FreezerModel(key: 'fridge_top', liters: 50, iconKey: 'fridge_top'),
    FreezerModel(key: 'combi_compact', liters: 70, iconKey: 'combi'),
    FreezerModel(key: 'undercounter', liters: 85, iconKey: 'undercounter'),
    FreezerModel(key: 'combi_large', liters: 100, iconKey: 'combi'),
    FreezerModel(key: 'chest_small', liters: 100, iconKey: 'chest'),
    FreezerModel(key: 'side_by_side', liters: 200, iconKey: 'side_by_side'),
    FreezerModel(key: 'chest_medium', liters: 200, iconKey: 'chest'),
    FreezerModel(key: 'upright_tall', liters: 270, iconKey: 'upright'),
    FreezerModel(key: 'chest_large', liters: 350, iconKey: 'chest'),
  ];

  static FreezerModel? byKey(String? key) {
    for (final m in all) {
      if (m.key == key) return m;
    }
    return null;
  }
}

enum FillLevel { empty, normal, full }

@immutable
class FillInfo {
  const FillInfo({
    required this.usedLiters,
    required this.usableLiters,
    required this.fraction,
    required this.level,
  });

  /// Somma degli ingombri, gia' moltiplicata per la taratura.
  final double usedLiters;

  /// Capacita' nominale x `usableFraction`.
  final double usableLiters;

  /// 0..1 e oltre: puo' superare 1, e la UI lo mostra come "pieno".
  final double fraction;

  final FillLevel level;

  /// La percentuale da mostrare, arrotondata e tagliata a 100.
  int get percent => (fraction * 100).round().clamp(0, 100);
}

/// Quanto e' pieno un freezer (develop_microapps.md F4.3b).
///
/// Due correzioni separate, perche' la stima sbaglia in due modi diversi:
/// 1. il singolo alimento (la lasagna in teglia non e' "una porzione"): lo corregge
///    l'utente sull'alimento, e da li' `items.volumeManual` blocca la stima;
/// 2. il freezer intero (ognuno riempie a modo suo): lo corregge [calibrate], che scrive
///    `freezers.calibration`.
class CapacityEstimator {
  const CapacityEstimator({this.usableFraction = 0.8, this.fullAt = 0.85, this.emptyAt = 0.20});

  /// Nessun freezer si riempie fino all'ultimo litro: si conta l'80% di quello nominale.
  final double usableFraction;

  /// Da qui in su il freezer e' `full` (avviso "quasi pieno", F4.9).
  final double fullAt;

  /// Sotto questo il freezer e' `empty` (avviso "quasi vuoto", F4.9).
  final double emptyAt;

  /// Limiti della taratura: oltre, e' piu' probabile un tocco sbagliato che un freezer cosi'.
  static const double minCalibration = 0.25;
  static const double maxCalibration = 4;

  /// Litri per unita' (F4.3b). `pieces` dipende dalla categoria.
  ///
  /// ⚑ `kg` vale 1,3 litri e non 1: il congelato pesa poco meno dell'acqua, ma sacchetti,
  /// vaschette e aria fra i pezzi occupano spazio.
  static const Map<String, double> litersPerUnit = <String, double>{
    Units.portions: 0.4,
    Units.packs: 0.8,
    Units.liters: 1.1,
    Units.kilograms: 1.3,
    Units.grams: 0.0013,
  };

  /// Le quattro misure rapide per correggere un alimento, in litri **per unita'**.
  static const Map<String, double> quickSizes = <String, double>{
    'small': 0.25,
    'medium': 0.5,
    'large': 1,
    'xlarge': 2,
  };

  /// Ingombro stimato di una riga intera: quantita' x litri per unita'.
  ///
  /// Mai zero: il database rifiuta un ingombro nullo, e un alimento che "non occupa
  /// spazio" e' sempre un errore di stima, non un dato.
  double estimateLiters({required double quantity, required String unit, String? categoryKey}) {
    final perUnit = unit == Units.pieces
        ? (ItemCategories.byKey(categoryKey) ?? ItemCategories.other).litersPerPiece
        : (litersPerUnit[unit] ?? litersPerUnit[Units.portions]!);
    final liters = quantity * perUnit;
    return liters > 0.01 ? liters : 0.01;
  }

  FillInfo fill({
    required double capacityLiters,
    required double calibration,
    required Iterable<double> itemLiters,
  }) {
    final usable = capacityLiters * usableFraction;
    final raw = itemLiters.fold<double>(0, (sum, l) => sum + l);
    final used = raw * calibration;
    final fraction = usable <= 0 ? 0.0 : used / usable;
    final level = fraction >= fullAt
        ? FillLevel.full
        : fraction < emptyAt
        ? FillLevel.empty
        : FillLevel.normal;
    return FillInfo(usedLiters: used, usableLiters: usable, fraction: fraction, level: level);
  }

  /// La frazione stimata **senza** taratura: e' quella che [calibrate] vuole.
  double rawFraction({required double capacityLiters, required Iterable<double> itemLiters}) =>
      fill(capacityLiters: capacityLiters, calibration: 1, itemLiters: itemLiters).fraction;

  /// Taratura da "quanto e' pieno davvero?": l'utente dice 60%, la stima diceva 40% -> 1,5.
  ///
  /// ☠ [estimatedFraction] deve essere la stima **grezza** ([rawFraction]), non quella gia'
  /// tarata: due tarature di seguito si moltiplicherebbero e la barra impazzirebbe.
  ///
  /// Con il freezer vuoto secondo la stima (0%) non c'e' niente da tarare: si torna a 1.
  double calibrate({required double estimatedFraction, required double declaredFraction}) {
    if (estimatedFraction <= 0) return 1;
    final factor = declaredFraction / estimatedFraction;
    return factor.clamp(minCalibration, maxCalibration).toDouble();
  }
}

/// I valori di `freezers.lastAlertLevel`.
abstract final class AlertLevel {
  static const String full = 'full';
  static const String empty = 'empty';
}

/// Cosa fare dopo una modifica: quale avviso mandare (o nessuno) e cosa salvare in
/// `freezers.lastAlertLevel`.
@immutable
class AlertDecision {
  const AlertDecision({required this.send, required this.newLastLevel});

  /// `AlertLevel.full`, `AlertLevel.empty` o null (nessun avviso).
  final String? send;

  /// Il valore da scrivere in `freezers.lastAlertLevel`.
  final String? newLastLevel;

  @override
  bool operator ==(Object other) =>
      other is AlertDecision && other.send == send && other.newLastLevel == newLastLevel;

  @override
  int get hashCode => Object.hash(send, newLastLevel);

  @override
  String toString() => 'AlertDecision(send: $send, last: $newLastLevel)';
}

/// La regola degli avvisi di capienza, con isteresi (develop_microapps.md F4.9).
///
/// ☠ **L'avviso ripetuto**: un freezer all'86% che riceve e perde un alimento al giorno
/// attraverserebbe la soglia ogni giorno, e l'utente silenzierebbe le notifiche. Quindi:
/// - dopo un "pieno" non si riavvisa finche' il freezer non e' sceso sotto [rearmFullBelow];
/// - dopo un "vuoto" non si riavvisa finche' non e' risalito sopra [rearmEmptyAbove].
/// Un freezer appena creato ha `lastAlertLevel = empty`: non manda mai "quasi vuoto" finche'
/// non e' stato riempito almeno fino al 40%.
class CapacityAlertPolicy {
  const CapacityAlertPolicy({
    this.estimator = const CapacityEstimator(),
    this.rearmFullBelow = 0.70,
    this.rearmEmptyAbove = 0.40,
  });

  final CapacityEstimator estimator;
  final double rearmFullBelow;
  final double rearmEmptyAbove;

  AlertDecision decide({required double fraction, required String? lastLevel}) {
    if (fraction >= estimator.fullAt) {
      return lastLevel == AlertLevel.full
          ? const AlertDecision(send: null, newLastLevel: AlertLevel.full)
          : const AlertDecision(send: AlertLevel.full, newLastLevel: AlertLevel.full);
    }
    if (fraction < estimator.emptyAt) {
      return lastLevel == AlertLevel.empty
          ? const AlertDecision(send: null, newLastLevel: AlertLevel.empty)
          : const AlertDecision(send: AlertLevel.empty, newLastLevel: AlertLevel.empty);
    }
    // Fascia intermedia: nessun avviso; si riarma solo uscendo abbastanza dalla soglia.
    if (lastLevel == AlertLevel.full && fraction < rearmFullBelow) {
      return const AlertDecision(send: null, newLastLevel: null);
    }
    if (lastLevel == AlertLevel.empty && fraction > rearmEmptyAbove) {
      return const AlertDecision(send: null, newLastLevel: null);
    }
    return AlertDecision(send: null, newLastLevel: lastLevel);
  }
}

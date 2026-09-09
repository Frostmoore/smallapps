import 'package:meta/meta.dart';

import 'feature_key.dart';

/// Quanto di una funzione e' concesso al piano gratuito.
///
/// Tre forme, e nessun'altra:
///
/// - [FeatureLimit.open]: sempre disponibile, anche senza Pro.
/// - [FeatureLimit.count]: disponibile fino a `freeMax` elementi, poi serve Pro.
/// - [FeatureLimit.locked]: solo con Pro.
@immutable
class FeatureLimit {
  const FeatureLimit._(this._kind, this.freeMax);

  /// Solo con Pro.
  const FeatureLimit.locked() : this._(_LimitKind.locked, 0);

  /// Gratuita fino a [freeMax] elementi inclusi, poi serve Pro.
  const FeatureLimit.count({required int freeMax}) : this._(_LimitKind.counted, freeMax);

  /// Sempre disponibile.
  const FeatureLimit.open() : this._(_LimitKind.open, null);

  final _LimitKind _kind;

  /// Quanti elementi concede il piano gratuito. `null` se la funzione non si conta:
  /// zero per [FeatureLimit.locked], `null` per [FeatureLimit.open].
  final int? freeMax;

  /// `true` se senza Pro la funzione non e' proprio accessibile.
  bool get isLockedForFree => _kind == _LimitKind.locked;

  /// `true` se il piano gratuito ne concede una quantita' limitata.
  bool get isCounted => _kind == _LimitKind.counted;

  /// `true` se e' disponibile a tutti senza limiti.
  bool get isOpen => _kind == _LimitKind.open;

  @override
  bool operator ==(Object other) =>
      other is FeatureLimit && other._kind == _kind && other.freeMax == freeMax;

  @override
  int get hashCode => Object.hash(_kind, freeMax);

  @override
  String toString() => switch (_kind) {
    _LimitKind.locked => 'FeatureLimit.locked()',
    _LimitKind.counted => 'FeatureLimit.count(freeMax: $freeMax)',
    _LimitKind.open => 'FeatureLimit.open()',
  };
}

enum _LimitKind { locked, counted, open }

/// La tabella dei limiti di un'app.
///
/// Ogni app ne dichiara **una sola**, in `lib/app/feature_limits.dart` (ADR-017).
/// Le chiavi assenti valgono [FeatureLimit.open].
typedef FeatureLimits = Map<FeatureKey, FeatureLimit>;

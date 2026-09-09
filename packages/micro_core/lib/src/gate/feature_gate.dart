import 'package:meta/meta.dart';

import 'feature_key.dart';
import 'feature_limits.dart';

/// Esito di una verifica sul piano dell'utente.
@immutable
sealed class GateVerdict {
  const GateVerdict();

  bool get isAllowed => this is GateAllowed;
}

/// La funzione e' disponibile.
@immutable
final class GateAllowed extends GateVerdict {
  const GateAllowed();

  @override
  String toString() => 'GateAllowed()';
}

/// La funzione non e' disponibile, e il paywall deve spiegare perche'.
@immutable
final class GateBlocked extends GateVerdict {
  const GateBlocked({required this.key, required this.reason, this.freeMax});

  final FeatureKey key;
  final BlockReason reason;

  /// Quanti elementi concedeva il piano gratuito, quando il blocco e' per quantita'.
  final int? freeMax;

  @override
  bool operator ==(Object other) =>
      other is GateBlocked &&
      other.key == key &&
      other.reason == reason &&
      other.freeMax == freeMax;

  @override
  int get hashCode => Object.hash(key, reason, freeMax);

  @override
  String toString() => 'GateBlocked(${key.name}, ${reason.name}, freeMax: $freeMax)';
}

/// Perche' una funzione e' bloccata.
enum BlockReason {
  /// Richiede Pro e basta.
  proOnly,

  /// Il piano gratuito la concede, ma il tetto e' stato raggiunto.
  limitReached,
}

/// Decide cosa l'utente puo' fare, dato il suo piano e i limiti dichiarati dall'app.
///
/// Nessuna pagina scrive `if (isPro)` a mano (ADR-017). I limiti cambiano: spostare il
/// tetto gratuito dopo il lancio e' normale, e se il valore e' sparso in venti file
/// diventa un refactoring invece che una riga. In piu' il paywall costruisce l'elenco
/// dei benefici leggendo la stessa mappa, cosi' non esistono due testi che dicono cose
/// diverse sullo stesso limite.
@immutable
class FeatureGate {
  const FeatureGate({required this.limits, required this.isPro});

  /// Un cancello che lascia passare tutto. Utile nei test e nelle anteprime.
  const FeatureGate.unlimited() : limits = const <FeatureKey, FeatureLimit>{}, isPro = true;

  final FeatureLimits limits;
  final bool isPro;

  /// Il limite dichiarato per [key].
  ///
  /// Una chiave non dichiarata vale [FeatureLimit.open]. La scelta e' deliberata:
  /// dimenticare una dichiarazione regala una funzione a tutti, il che costa ricavi ma
  /// non rompe niente; il contrario toglierebbe agli utenti gratuiti una funzione che
  /// doveva essere loro, cioe' un difetto visibile. In debug un assert segnala comunque
  /// le chiavi non dichiarate.
  FeatureLimit limitOf(FeatureKey key) {
    final limit = limits[key];
    assert(
      limit != null || limits.isEmpty,
      'FeatureKey.${key.name} non e dichiarata nella mappa dei limiti di questa app. '
      'Aggiungila a lib/app/feature_limits.dart (ADR-017).',
    );
    return limit ?? const FeatureLimit.open();
  }

  /// `true` se la funzione e' accessibile almeno in parte.
  ///
  /// Per una funzione a quantita' risponde `true` anche senza Pro: l'utente gratuito
  /// puo' averne fino al tetto. Per sapere se puo' aggiungerne un'altra si usa
  /// [withinLimit].
  bool allows(FeatureKey key) => isPro || !limitOf(key).isLockedForFree;

  /// Il tetto del piano gratuito, oppure `null` se la funzione non si conta.
  int? freeLimitOf(FeatureKey key) => limitOf(key).freeMax;

  /// `true` se l'utente puo' aggiungerne un altro, avendone gia' [currentCount].
  bool withinLimit(FeatureKey key, int currentCount) {
    if (isPro) return true;
    final limit = limitOf(key);
    if (limit.isOpen) return true;
    return currentCount < (limit.freeMax ?? 0);
  }

  /// Quanti altri elementi puo' aggiungere, oppure `null` se non c'e' un tetto.
  int? remaining(FeatureKey key, int currentCount) {
    if (isPro) return null;
    final limit = limitOf(key);
    if (limit.isOpen) return null;
    final max = limit.freeMax ?? 0;
    final left = max - currentCount;
    return left < 0 ? 0 : left;
  }

  /// La verifica completa, con il motivo del rifiuto.
  ///
  /// E' quella che usano le pagine: il [GateBlocked] restituito contiene tutto quello
  /// che serve al foglio di spiegazione e al paywall.
  GateVerdict check(FeatureKey key, {int currentCount = 0}) {
    if (isPro) return const GateAllowed();
    final limit = limitOf(key);
    if (limit.isOpen) return const GateAllowed();
    if (limit.isLockedForFree) {
      return GateBlocked(key: key, reason: BlockReason.proOnly);
    }
    final max = limit.freeMax ?? 0;
    if (currentCount < max) return const GateAllowed();
    return GateBlocked(key: key, reason: BlockReason.limitReached, freeMax: max);
  }

  /// Le funzioni che il piano gratuito non offre affatto: l'elenco che il paywall
  /// mostra come "cosa sblocchi".
  List<FeatureKey> get proOnlyFeatures => limits.entries
      .where((e) => e.value.isLockedForFree)
      .map((e) => e.key)
      .toList(growable: false);

  /// Le funzioni che il piano gratuito offre con un tetto.
  List<FeatureKey> get limitedFeatures =>
      limits.entries.where((e) => e.value.isCounted).map((e) => e.key).toList(growable: false);

  /// Lo stesso cancello con un altro stato di abbonamento.
  FeatureGate copyWith({bool? isPro}) => FeatureGate(limits: limits, isPro: isPro ?? this.isPro);

  @override
  String toString() => 'FeatureGate(isPro: $isPro, ${limits.length} limiti)';
}

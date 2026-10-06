import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import 'categories.dart';

/// Quanto e' "vecchio" un alimento rispetto al suo promemoria.
enum AgingLevel {
  /// Lontano dal promemoria, o senza promemoria.
  fresh,

  /// Dall'80% del promemoria in su: da tenere d'occhio.
  watch,

  /// Promemoria superato.
  old,
}

@immutable
class AgingInfo {
  const AgingInfo({
    required this.days,
    required this.level,
    required this.reminderDays,
    required this.overdueBy,
  });

  /// Giorni nel freezer (0 il giorno del congelamento).
  final int days;

  final AgingLevel level;

  /// Il promemoria che si e' usato: quello dell'alimento, o quello della categoria, o null.
  final int? reminderDays;

  /// Giorni oltre il promemoria; null se non e' superato o non c'e' promemoria.
  final int? overdueBy;

  @override
  bool operator ==(Object other) =>
      other is AgingInfo &&
      other.days == days &&
      other.level == level &&
      other.reminderDays == reminderDays &&
      other.overdueBy == overdueBy;

  @override
  int get hashCode => Object.hash(days, level, reminderDays, overdueBy);

  @override
  String toString() => 'AgingInfo($days giorni, $level, promemoria $reminderDays)';
}

/// Il calcolo dell'anzianita' (develop_microapps.md F4.3).
///
/// Dart puro: niente Flutter, niente database, il "oggi" si puo' passare. E' il pezzo su cui
/// si regge la promessa dell'app ("il piu' vecchio per primo") e va provato da solo.
class AgingCalculator {
  const AgingCalculator({this.watchFraction = 0.8});

  /// Da quale frazione del promemoria un alimento diventa `watch`.
  final double watchFraction;

  /// Giorni fra il congelamento e oggi. Mai negativo: una data nel futuro (errore di
  /// inserimento, o fuso orario a cavallo della mezzanotte) vale 0, non "-1 giorni".
  int daysInFreezer(CivilDate frozenAt, {CivilDate? today}) {
    final d = frozenAt.daysUntil(today ?? CivilDate.today());
    return d < 0 ? 0 : d;
  }

  /// Il promemoria suggerito per una categoria; null per categorie sconosciute (le
  /// personalizzate portano il loro, che la UI passa come [AgingCalculator.evaluate]).
  int? defaultReminderFor(String? categoryKey) =>
      ItemCategories.byKey(categoryKey)?.defaultReminderDays;

  /// Valuta un alimento.
  ///
  /// [reminderAfterDays] e' quello personalizzato dell'alimento; se manca si usa quello
  /// della categoria ([categoryKey]); se manca anche quello, il livello e' sempre `fresh`.
  AgingInfo evaluate({
    required CivilDate frozenAt,
    int? reminderAfterDays,
    String? categoryKey,
    CivilDate? today,
  }) {
    final days = daysInFreezer(frozenAt, today: today);
    final reminder = reminderAfterDays ?? defaultReminderFor(categoryKey);
    if (reminder == null || reminder <= 0) {
      return AgingInfo(days: days, level: AgingLevel.fresh, reminderDays: null, overdueBy: null);
    }
    final AgingLevel level;
    if (days >= reminder) {
      level = AgingLevel.old;
    } else if (days >= reminder * watchFraction) {
      level = AgingLevel.watch;
    } else {
      level = AgingLevel.fresh;
    }
    return AgingInfo(
      days: days,
      level: level,
      reminderDays: reminder,
      overdueBy: days > reminder ? days - reminder : null,
    );
  }
}

/// L'ordinamento "il piu' vecchio per primo".
///
/// ⚑ **Non dipende dal livello** (F4.3): ordinare per livello e poi per data farebbe
/// scendere un alimento vecchissimo senza promemoria sotto uno appena entrato in `watch`,
/// e quello senza promemoria e' proprio quello che l'utente ha dimenticato. A parita' di
/// data vince il confronto fra [tieA] e [tieB] (l'id: l'inserito prima).
int compareOldestFirst(CivilDate a, CivilDate b, {int tieA = 0, int tieB = 0}) {
  final byDate = a.compareTo(b);
  return byDate != 0 ? byDate : tieA.compareTo(tieB);
}

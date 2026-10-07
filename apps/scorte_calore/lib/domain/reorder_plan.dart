import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import 'consumption.dart';
import 'fuel_source.dart';

/// I due avvisi per fonte (develop_microapps.md F5.8).
enum ReorderNotificationKind {
  /// Alla `reorderDate`: "Il pellet potrebbe terminare tra circa 7 giorni. Ti restano circa
  /// 12 sacchi."
  reorder(1),

  /// 3 giorni dopo la `reorderDate`, se nel frattempo non e' arrivata nessuna misurazione:
  /// "Hai superato la data prevista di riordino del GPL."
  overdue(2);

  const ReorderNotificationKind(this.slot);

  /// L'ultima cifra dell'id di notifica (vedi [ReorderPlanner.notificationId]).
  final int slot;
}

/// Una notifica da pianificare: **valori, non testi**.
///
/// ⚑ Il testo lo compone `lib/services/scorte_scheduler.dart` dagli ARB con questi campi
/// (nome del combustibile da [fuelTypeKey], unita' da [unitKey], numeri gia' qui). Una frase
/// italiana costruita nel dominio non si traduce.
@immutable
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.fireAt,
    required this.sourceId,
    required this.sourceName,
    required this.fuelTypeKey,
    required this.unitKey,
    required this.reorderDate,
    required this.depletionDate,
    required this.daysUntilDepletion,
    required this.projectedQuantity,
  });

  /// Id stabile per fonte e tipo: ripianificare sostituisce, non duplica.
  final int id;

  final ReorderNotificationKind kind;

  /// Data e ora **locali** (costruite da CivilDate, mai UTC): alle 10:00 dell'utente.
  final DateTime fireAt;

  final int sourceId;

  /// Il nome dato dall'utente alla fonte ("Stufa soggiorno"): e' un dato, non un testo.
  final String sourceName;

  final String fuelTypeKey;
  final String unitKey;
  final CivilDate reorderDate;
  final CivilDate depletionDate;

  /// Giorni fra il giorno della notifica e l'esaurimento stimato (mai negativo).
  final int daysUntilDepletion;

  /// Quantita' stimata il giorno della notifica, nell'unita' della fonte.
  final double projectedQuantity;

  @override
  bool operator ==(Object other) =>
      other is PlannedNotification &&
      other.id == id &&
      other.kind == kind &&
      other.fireAt == fireAt &&
      other.sourceId == sourceId &&
      other.sourceName == sourceName &&
      other.fuelTypeKey == fuelTypeKey &&
      other.unitKey == unitKey &&
      other.reorderDate == reorderDate &&
      other.depletionDate == depletionDate &&
      other.daysUntilDepletion == daysUntilDepletion &&
      other.projectedQuantity == projectedQuantity;

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    fireAt,
    sourceId,
    sourceName,
    fuelTypeKey,
    unitKey,
    reorderDate,
    depletionDate,
    daysUntilDepletion,
    projectedQuantity,
  );

  @override
  String toString() => 'PlannedNotification($id, ${kind.name}, $fireAt)';
}

/// La parte pura delle notifiche di riordino (F5.8): quando e con quali valori.
///
/// Chi la usa (lo scheduler) a ogni nuova misurazione: cancella [idsFor] della fonte e
/// pianifica quello che [plan] restituisce. Cosi' la regola "si ripianificano a ogni nuova
/// misurazione" e "superamento solo se non ci sono nuove misurazioni" vengono da sole: una
/// misurazione nuova ricalcola la stima e cancella il superamento vecchio.
class ReorderPlanner {
  const ReorderPlanner({this.hour = 10, this.minute = 0, this.overdueAfterDays = 3});

  final int hour;
  final int minute;

  /// Giorni dopo la `reorderDate` per l'avviso di superamento.
  final int overdueAfterDays;

  /// Il piu' grande id di fonte che lo schema degli id regge (vedi [notificationId]).
  static const int maxSourceId = 214748363;

  /// Id della notifica: `sourceId x 10 + kind.slot` (riordino 1, superamento 2).
  ///
  /// ⚑ Stabile per fonte, cosi' ripianificare **sostituisce** la notifica invece di
  /// accumularne. Le cifre 0 e 3-9 restano libere per altri avvisi della stessa fonte.
  /// ☠ Gli id delle notifiche locali sono interi a 32 bit con segno (Android): oltre
  /// [maxSourceId] l'id traboccherebbe, e si lancia [ArgumentError] invece di collidere in
  /// silenzio con un'altra fonte.
  static int notificationId(int sourceId, ReorderNotificationKind kind) {
    if (sourceId < 0 || sourceId > maxSourceId) {
      throw ArgumentError.value(sourceId, 'sourceId', 'Fuori dallo schema degli id di notifica');
    }
    return sourceId * 10 + kind.slot;
  }

  /// Tutti gli id che una fonte puo' avere: da cancellare prima di ripianificare, o quando
  /// la fonte viene eliminata o disattivata.
  static List<int> idsFor(int sourceId) => ReorderNotificationKind.values
      .map((k) => notificationId(sourceId, k))
      .toList(growable: false);

  /// Le notifiche da pianificare per [source] con la stima [estimate], adesso ([now],
  /// iniettabile; ora locale).
  ///
  /// - `insufficient`: **nessuna**. Avvisare su una stima non calcolabile e' peggio che
  ///   tacere (F5.8).
  /// - Riordino alla `reorderDate`, alle [hour]:[minute].
  /// - Superamento alla `reorderDate + overdueAfterDays`, stessa ora, solo se l'ultima
  ///   misurazione non e' successiva alla `reorderDate` (chi ha misurato dopo sa gia' come
  ///   sta).
  /// - Un avviso il cui momento e' gia' passato non si pianifica: i plugin di notifica
  ///   rifiutano le date nel passato, e la dashboard mostra gia' il ritardo.
  List<PlannedNotification> plan({
    required FuelSourceSpec source,
    required ConsumptionEstimate estimate,
    DateTime? now,
  }) {
    final reorder = estimate.reorderDate;
    final depletion = estimate.depletionDate;
    if (!estimate.isActionable || reorder == null || depletion == null) return const [];
    final at = now ?? DateTime.now();
    final out = <PlannedNotification>[];

    PlannedNotification build(ReorderNotificationKind kind, CivilDate day) {
      final left = day.daysUntil(depletion);
      return PlannedNotification(
        id: notificationId(source.id, kind),
        kind: kind,
        fireAt: day.toLocalDateTime(hour, minute),
        sourceId: source.id,
        sourceName: source.name,
        fuelTypeKey: source.fuelType.key,
        unitKey: source.unitKey,
        reorderDate: reorder,
        depletionDate: depletion,
        daysUntilDepletion: left < 0 ? 0 : left,
        projectedQuantity: estimate.projectedQuantityOn(day) ?? estimate.currentQuantity,
      );
    }

    final first = build(ReorderNotificationKind.reorder, reorder);
    if (first.fireAt.isAfter(at)) out.add(first);

    final last = estimate.lastMeasurementDate;
    if (last == null || last.isSameOrBefore(reorder)) {
      final late = build(ReorderNotificationKind.overdue, reorder.addDays(overdueAfterDays));
      if (late.fireAt.isAfter(at)) out.add(late);
    }
    return out;
  }
}

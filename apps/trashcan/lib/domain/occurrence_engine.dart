import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import 'recurrence.dart';

/// Da dove viene una raccolta comparsa nel calendario.
enum OccurrenceOrigin {
  /// Generata dalla regola ricorrente.
  regular,

  /// Generata dalla regola ma spostata da un'eccezione.
  moved,

  /// Non prevista dalla regola: aggiunta a mano dall'utente.
  extra,
}

/// Una singola raccolta, in una data precisa, per un tipo di rifiuto.
@immutable
class CollectionOccurrence {
  const CollectionOccurrence({
    required this.wasteTypeId,
    required this.date,
    required this.origin,
    this.originalDate,
    this.note,
  });

  final int wasteTypeId;
  final CivilDate date;
  final OccurrenceOrigin origin;

  /// Per le raccolte spostate: la data in cui sarebbe caduta senza eccezione.
  final CivilDate? originalDate;

  final String? note;

  bool get isRegular => origin == OccurrenceOrigin.regular;

  @override
  bool operator ==(Object other) =>
      other is CollectionOccurrence &&
      other.wasteTypeId == wasteTypeId &&
      other.date == date &&
      other.origin == origin &&
      other.originalDate == originalDate;

  @override
  int get hashCode => Object.hash(wasteTypeId, date, origin, originalDate);

  @override
  String toString() => 'Occurrence(#$wasteTypeId, $date, ${origin.name})';
}

/// Una deroga alla regola, decisa dall'utente.
///
/// Le tre forme ammesse, e nessun'altra:
///
/// | Caso | originalDate | replacementDate | skipped |
/// |---|---|---|---|
/// | Salta | data | null | true |
/// | Sposta | data | data | false |
/// | Straordinaria | null | data | false |
@immutable
class CollectionException {
  const CollectionException({
    required this.id,
    required this.wasteTypeId,
    this.originalDate,
    this.replacementDate,
    this.skipped = false,
    this.note,
  });

  /// Salta la raccolta prevista in [date].
  factory CollectionException.skip({
    required int id,
    required int wasteTypeId,
    required CivilDate date,
    String? note,
  }) => CollectionException(
    id: id,
    wasteTypeId: wasteTypeId,
    originalDate: date,
    skipped: true,
    note: note,
  );

  /// Sposta la raccolta da [from] a [to].
  factory CollectionException.move({
    required int id,
    required int wasteTypeId,
    required CivilDate from,
    required CivilDate to,
    String? note,
  }) => CollectionException(
    id: id,
    wasteTypeId: wasteTypeId,
    originalDate: from,
    replacementDate: to,
    note: note,
  );

  /// Aggiunge una raccolta non prevista in [date].
  factory CollectionException.extra({
    required int id,
    required int wasteTypeId,
    required CivilDate date,
    String? note,
  }) => CollectionException(id: id, wasteTypeId: wasteTypeId, replacementDate: date, note: note);

  final int id;
  final int wasteTypeId;
  final CivilDate? originalDate;
  final CivilDate? replacementDate;
  final bool skipped;
  final String? note;

  bool get isSkip => skipped && originalDate != null;
  bool get isMove => !skipped && originalDate != null && replacementDate != null;
  bool get isExtra => !skipped && originalDate == null && replacementDate != null;

  /// `true` se la combinazione di campi e' una delle tre ammesse.
  bool get isWellFormed => isSkip || isMove || isExtra;

  @override
  String toString() =>
      'Exception(#$id, tipo $wasteTypeId, '
      '${isSkip
          ? "salta $originalDate"
          : isMove
          ? "sposta $originalDate -> $replacementDate"
          : "extra $replacementDate"})';
}

/// Una regola con le sue eccezioni, pronta per il motore.
@immutable
class RuleWithExceptions {
  const RuleWithExceptions({
    required this.wasteTypeId,
    required this.recurrence,
    this.exceptions = const <CollectionException>[],
    this.sortOrder = 0,
  });

  final int wasteTypeId;
  final Recurrence recurrence;
  final List<CollectionException> exceptions;

  /// Ordine di visualizzazione del tipo di rifiuto: a parita' di data decide la
  /// sequenza, cosi' che la home elenchi sempre i tipi nello stesso ordine.
  final int sortOrder;
}

/// Espande le regole in raccolte concrete, applicando le eccezioni.
///
/// E' il cuore di TrashCan. Un errore qui non produce un crash: produce un giorno
/// sbagliato, che l'utente scopre quando il camion e' gia' passato. Per questo il
/// motore e' puro (nessuna dipendenza da Flutter, dal database o dall'ora di sistema
/// se non passata) e ogni suo ramo e' coperto da un test.
class OccurrenceEngine {
  const OccurrenceEngine();

  /// Tutte le raccolte tra [from] e [to], estremi inclusi, ordinate per data.
  ///
  /// L'ordine delle fasi e' vincolante:
  ///
  /// 1. genera le occorrenze base dalle regole;
  /// 2. applica i **salti**, togliendo le date annullate;
  /// 3. applica gli **spostamenti**, togliendo l'originale e aggiungendo la nuova data;
  /// 4. aggiunge le **straordinarie**;
  /// 5. deduplica per (tipo, data) con priorita' extra > moved > regular;
  /// 6. ordina per data, poi per `sortOrder` del tipo.
  ///
  /// Il passo 2 deve precedere il 3: uno spostamento su una data gia' saltata non deve
  /// far riapparire la raccolta. Invertendo i due passi si otterrebbe quel
  /// comportamento, che e' sbagliato e quasi impossibile da diagnosticare dopo.
  List<CollectionOccurrence> expand({
    required List<RuleWithExceptions> rules,
    required CivilDate from,
    required CivilDate to,
  }) {
    if (to.isBefore(from)) return const <CollectionOccurrence>[];

    final result = <CollectionOccurrence>[];
    final sortOrderByType = <int, int>{};

    for (final rule in rules) {
      sortOrderByType[rule.wasteTypeId] = rule.sortOrder;

      final skipped = <CivilDate>{};
      final movedAway = <CivilDate>{};
      final moves = <CollectionException>[];
      final extras = <CollectionException>[];

      for (final exception in rule.exceptions) {
        if (!exception.isWellFormed) continue;
        if (exception.isSkip) {
          skipped.add(exception.originalDate!);
        } else if (exception.isMove) {
          moves.add(exception);
        } else if (exception.isExtra) {
          extras.add(exception);
        }
      }

      // Fase 1 e 2: occorrenze base, meno i salti.
      for (final date in rule.recurrence.occurrencesIn(from, to)) {
        if (skipped.contains(date)) continue;
        result.add(
          CollectionOccurrence(
            wasteTypeId: rule.wasteTypeId,
            date: date,
            origin: OccurrenceOrigin.regular,
          ),
        );
      }

      // Fase 3: spostamenti. L'originale sparisce anche se la nuova data cade fuori
      // dalla finestra richiesta: e' corretto, la raccolta quel giorno non c'e' piu'.
      for (final move in moves) {
        final original = move.originalDate!;
        final replacement = move.replacementDate!;
        if (skipped.contains(original)) continue;
        movedAway.add(original);
        if (replacement.isSameOrAfter(from) &&
            replacement.isSameOrBefore(to) &&
            rule.recurrence.occursOn(original)) {
          result.add(
            CollectionOccurrence(
              wasteTypeId: rule.wasteTypeId,
              date: replacement,
              origin: OccurrenceOrigin.moved,
              originalDate: original,
              note: move.note,
            ),
          );
        }
      }
      result.removeWhere(
        (o) =>
            o.wasteTypeId == rule.wasteTypeId &&
            o.origin == OccurrenceOrigin.regular &&
            movedAway.contains(o.date),
      );

      // Fase 4: straordinarie.
      for (final extra in extras) {
        final date = extra.replacementDate!;
        if (date.isBefore(from) || date.isAfter(to)) continue;
        result.add(
          CollectionOccurrence(
            wasteTypeId: rule.wasteTypeId,
            date: date,
            origin: OccurrenceOrigin.extra,
            note: extra.note,
          ),
        );
      }
    }

    // Fase 5: deduplica. Due regole sullo stesso tipo possono generare la stessa data,
    // e una straordinaria puo' coincidere con una raccolta ordinaria.
    final byKey = <String, CollectionOccurrence>{};
    for (final occurrence in result) {
      final key = '${occurrence.wasteTypeId}@${occurrence.date.toIso()}';
      final existing = byKey[key];
      if (existing == null || _priority(occurrence.origin) > _priority(existing.origin)) {
        byKey[key] = occurrence;
      }
    }

    // Fase 6: ordinamento stabile.
    final ordered = byKey.values.toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        final orderA = sortOrderByType[a.wasteTypeId] ?? 0;
        final orderB = sortOrderByType[b.wasteTypeId] ?? 0;
        if (orderA != orderB) return orderA.compareTo(orderB);
        return a.wasteTypeId.compareTo(b.wasteTypeId);
      });
    return ordered;
  }

  /// Le raccolte in una singola data.
  List<CollectionOccurrence> onDate(CivilDate date, {required List<RuleWithExceptions> rules}) =>
      expand(rules: rules, from: date, to: date);

  /// Cosa va portato fuori **stasera**.
  ///
  /// Attenzione all'asimmetria, che e' la regola di prodotto piu' importante dell'app:
  /// stasera si porta fuori quello che raccolgono **domani**. Quindi
  /// `tonight()` corrisponde a `onDate(oggi + 1)`, non a `onDate(oggi)`.
  /// Sembra un errore e prima o poi qualcuno vorra' "correggerlo": non e' un errore.
  List<CollectionOccurrence> tonight({required List<RuleWithExceptions> rules, CivilDate? today}) {
    final base = today ?? CivilDate.today();
    return onDate(base.addDays(1), rules: rules);
  }

  /// La prima raccolta a partire da [from] incluso, oppure `null` entro [horizonDays].
  CollectionOccurrence? next({
    required List<RuleWithExceptions> rules,
    CivilDate? from,
    int horizonDays = 400,
  }) {
    final start = from ?? CivilDate.today();
    final found = expand(rules: rules, from: start, to: start.addDays(horizonDays));
    return found.isEmpty ? null : found.first;
  }

  /// Le prime [count] raccolte a partire da [from].
  ///
  /// L'orizzonte e' ampio di proposito: una regola mensile in un calendario con poche
  /// regole puo' avere bisogno di piu' di un anno per produrre sei date, e l'anteprima
  /// dell'editor delle regole (F3.6) mostra sempre sei date.
  List<CollectionOccurrence> nextN(
    int count, {
    required List<RuleWithExceptions> rules,
    CivilDate? from,
    int horizonDays = 800,
  }) {
    if (count <= 0) return const <CollectionOccurrence>[];
    final start = from ?? CivilDate.today();
    final found = expand(rules: rules, from: start, to: start.addDays(horizonDays));
    return found.length <= count ? found : found.sublist(0, count);
  }

  static int _priority(OccurrenceOrigin origin) => switch (origin) {
    OccurrenceOrigin.extra => 3,
    OccurrenceOrigin.moved => 2,
    OccurrenceOrigin.regular => 1,
  };
}

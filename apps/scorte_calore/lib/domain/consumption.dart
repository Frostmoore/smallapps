import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import 'fuel_source.dart';

/// Quanto ci si puo' fidare di una stima (develop_microapps.md F5.3, F5.6).
enum EstimateQuality {
  /// Niente stima: la UI mostra "Inserisci un'altra misurazione", mai "∞ giorni".
  insufficient,

  /// Stima provvisoria: un solo intervallo, o meno di 10 giorni di dati.
  low,

  good,
}

/// Un tratto fra due misurazioni consecutive in cui la scorta e' scesa (o rimasta uguale).
@immutable
class ConsumptionInterval {
  const ConsumptionInterval({
    required this.from,
    required this.to,
    required this.consumed,
    required this.days,
  });

  final CivilDate from;
  final CivilDate to;

  /// Quantita' consumata, nell'unita' della fonte. Mai negativa: i tratti in salita sono
  /// rifornimenti e non diventano intervalli.
  final double consumed;

  /// Giorni fra [from] e [to]; sempre >= `minIntervalDays`.
  final int days;

  /// Unita' al giorno in questo tratto.
  double get rate => consumed / days;

  @override
  bool operator ==(Object other) =>
      other is ConsumptionInterval &&
      other.from == from &&
      other.to == to &&
      other.consumed == consumed &&
      other.days == days;

  @override
  int get hashCode => Object.hash(from, to, consumed, days);

  @override
  String toString() => 'ConsumptionInterval($from -> $to, $consumed in $days gg)';
}

/// La stima di consumo e autonomia di una fonte.
///
/// Con `quality == insufficient` tutti i campi della previsione ([dailyRate],
/// [daysRemaining], [depletionDate], [reorderDate]) sono null: niente da mostrare e niente
/// da notificare (F5.8).
@immutable
class ConsumptionEstimate {
  const ConsumptionEstimate({
    required this.dailyRate,
    required this.currentQuantity,
    required this.daysRemaining,
    required this.depletionDate,
    required this.reorderDate,
    required this.quality,
    required this.intervalsUsed,
    required this.spanDays,
    required this.lastMeasurementDate,
    required this.referenceQuantity,
  });

  /// Unita' al giorno; null se non calcolabile.
  final double? dailyRate;

  /// L'ultima quantita' misurata (0 senza misurazioni). E' un dato, non una proiezione:
  /// la quantita' stimata a una data la da' [projectedQuantityOn].
  final double currentQuantity;

  /// Giorni da oggi all'esaurimento stimato; 0 se la data e' gia' passata.
  final int? daysRemaining;

  final CivilDate? depletionDate;

  /// `depletionDate - warningDays`. Puo' essere nel passato: il riordino e' in ritardo.
  final CivilDate? reorderDate;

  final EstimateQuality quality;

  /// Quanti intervalli sono entrati nella media (al massimo `maxIntervals`).
  final int intervalsUsed;

  /// Somma dei giorni degli intervalli usati: quanti giorni di dati reggono la stima.
  final int spanDays;

  /// La data dell'ultima misurazione; null senza misurazioni.
  final CivilDate? lastMeasurementDate;

  /// La quantita' subito dopo l'ultimo rifornimento (o la prima misurazione, se non ce ne
  /// sono stati): il "pieno" rispetto a cui l'anello della dashboard misura il residuo
  /// (F5.6). Null senza misurazioni.
  final double? referenceQuantity;

  bool get isActionable => quality != EstimateQuality.insufficient;

  /// Il residuo rispetto all'ultimo rifornimento, 0..1, per `MicroProgressRing`. Null se
  /// non c'e' un riferimento positivo. Tagliato a 0..1: un'ultima misura piu' alta del
  /// riferimento non esiste (sarebbe a sua volta un rifornimento), ma un arrotondamento si'.
  double? get fractionRemaining {
    final ref = referenceQuantity;
    if (ref == null || ref <= 0) return null;
    return (currentQuantity / ref).clamp(0.0, 1.0);
  }

  /// [fractionRemaining] in percentuale intera (0..100).
  int? get percentRemaining {
    final f = fractionRemaining;
    return f == null ? null : (f * 100).round();
  }

  /// La quantita' stimata alla data [date]: ultima misura meno il consumo dei giorni
  /// trascorsi, mai sotto zero. Null se la stima non e' utilizzabile. Serve al testo della
  /// notifica di riordino ("Ti restano circa 12 sacchi", F5.8).
  double? projectedQuantityOn(CivilDate date) {
    final rate = dailyRate;
    final last = lastMeasurementDate;
    if (rate == null || last == null) return null;
    final elapsed = last.daysUntil(date);
    final q = currentQuantity - rate * (elapsed < 0 ? 0 : elapsed);
    return q < 0 ? 0 : q;
  }

  @override
  String toString() =>
      'ConsumptionEstimate($quality, rate $dailyRate, $daysRemaining gg, fine $depletionDate, '
      'riordino $reorderDate, $intervalsUsed intervalli su $spanDays gg)';
}

/// Il calcolo del consumo (develop_microapps.md F5.3). Dart puro, "oggi" iniettabile.
class ConsumptionCalculator {
  const ConsumptionCalculator({this.maxIntervals = 5, this.minIntervalDays = 1});

  /// ⚑ **Una finestra di 5 intervalli**: il consumo dipende dalla temperatura esterna, che
  /// cambia nell'arco di settimane. Una finestra lunga porterebbe il consumo di ottobre
  /// dentro la previsione di gennaio.
  final int maxIntervals;

  /// Gli intervalli piu' corti di cosi' si scartano.
  final int minIntervalDays;

  /// Sotto questi giorni di dati la stima e' `insufficient`.
  static const int minSpanDays = 3;

  /// Sotto questi giorni di dati (o con un solo intervallo) la stima e' `low`.
  static const int goodSpanDays = 10;

  /// Una misurazione per data, ordinate per data crescente.
  ///
  /// ☠ **Una misura al giorno** (`UNIQUE(fuelSourceId, date)` nel database, F5.2): se ne
  /// arrivano due con la stessa data vince **l'ultima della lista**, come la seconda
  /// sovrascrive la prima nel database. Senza, nascerebbe un intervallo di zero giorni e
  /// una divisione per zero.
  List<Measurement> normalize(Iterable<Measurement> measurements) {
    final byDay = <CivilDate, Measurement>{};
    for (final m in measurements) {
      byDay[m.date] = m;
    }
    return byDay.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Gli intervalli validi di tutta la serie, dal piu' vecchio (passi 1-3 di F5.3).
  ///
  /// Scarta i tratti in cui la quantita' e' **aumentata** (un rifornimento: quel salto non
  /// e' consumo) e quelli piu' corti di [minIntervalDays]. Un tratto con la quantita'
  /// invariata resta: zero consumo in quei giorni e' un dato vero (stufa spenta).
  List<ConsumptionInterval> buildIntervals(List<Measurement> measurements) {
    final sorted = normalize(measurements);
    final out = <ConsumptionInterval>[];
    for (var i = 1; i < sorted.length; i++) {
      final a = sorted[i - 1];
      final b = sorted[i];
      if (b.quantity > a.quantity) continue;
      final days = a.date.daysUntil(b.date);
      if (days < minIntervalDays || days <= 0) continue;
      out.add(
        ConsumptionInterval(
          from: a.date,
          to: b.date,
          consumed: a.quantity - b.quantity,
          days: days,
        ),
      );
    }
    return out;
  }

  /// La quantita' subito dopo l'ultimo rifornimento, o la prima misurazione se non ce ne
  /// sono stati. Null con la lista vuota. [sorted] deve venire da [normalize].
  double? referenceQuantity(List<Measurement> sorted) {
    if (sorted.isEmpty) return null;
    for (var i = sorted.length - 1; i >= 1; i--) {
      if (sorted[i].quantity > sorted[i - 1].quantity) return sorted[i].quantity;
    }
    return sorted.first.quantity;
  }

  /// La stima (F5.3, passi 1-8).
  ///
  /// ☠ **La data di esaurimento si conta dall'ultima misurazione, non da oggi.** Il piano
  /// dice `oggi + daysRemaining`, che coincide quando l'ultima misura e' di oggi; ma se
  /// l'utente non misura per dieci giorni, "oggi + N" sposterebbe in avanti di un giorno al
  /// giorno l'esaurimento, il riordino e la notifica, e il widget (che conta i giorni dalla
  /// data, ADR-018) non scenderebbe mai. Quindi:
  /// `depletionDate = ultimaMisura + floor(currentQuantity / dailyRate)` e
  /// `daysRemaining = giorni da oggi a depletionDate` (mai negativo).
  ///
  /// ⚑ **Media ponderata per la durata** (`sum(consumed) / sum(days)`), non la media delle
  /// velocita': un intervallo di due giorni e uno di venti non pesano uguale, e una
  /// misurazione ravvicinata e rumorosa non deve dominare la stima.
  ///
  /// ☠ **Velocita' <= 0** (misure tutte uguali): `daysRemaining` sarebbe infinito. Si
  /// restituisce `dailyRate: null` e `insufficient`, e la UI mostra "Servono altre
  /// misurazioni", mai "∞ giorni".
  ConsumptionEstimate estimate({
    required List<Measurement> measurements,
    required FuelSourceSpec source,
    CivilDate? today,
  }) {
    final now = today ?? CivilDate.today();
    final sorted = normalize(measurements);
    final current = sorted.isEmpty ? 0.0 : sorted.last.quantity;
    final lastDate = sorted.isEmpty ? null : sorted.last.date;
    final reference = referenceQuantity(sorted);

    final all = buildIntervals(sorted);
    final used = all.length > maxIntervals ? all.sublist(all.length - maxIntervals) : all;
    final spanDays = used.fold<int>(0, (s, i) => s + i.days);
    final consumed = used.fold<double>(0, (s, i) => s + i.consumed);
    final rate = spanDays > 0 ? consumed / spanDays : 0.0;

    ConsumptionEstimate insufficient() => ConsumptionEstimate(
      dailyRate: null,
      currentQuantity: current,
      daysRemaining: null,
      depletionDate: null,
      reorderDate: null,
      quality: EstimateQuality.insufficient,
      intervalsUsed: used.length,
      spanDays: spanDays,
      lastMeasurementDate: lastDate,
      referenceQuantity: reference,
    );

    if (used.isEmpty || spanDays < minSpanDays || rate <= 0 || lastDate == null) {
      return insufficient();
    }

    final quality = used.length == 1 || spanDays < goodSpanDays
        ? EstimateQuality.low
        : EstimateQuality.good;
    final daysFromLast = current <= 0 ? 0 : (current / rate).floor();
    final depletion = lastDate.addDays(daysFromLast);
    final left = now.daysUntil(depletion);
    return ConsumptionEstimate(
      dailyRate: rate,
      currentQuantity: current,
      daysRemaining: left < 0 ? 0 : left,
      depletionDate: depletion,
      reorderDate: depletion.addDays(-source.warningDays),
      quality: quality,
      intervalsUsed: used.length,
      spanDays: spanDays,
      lastMeasurementDate: lastDate,
      referenceQuantity: reference,
    );
  }
}

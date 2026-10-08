import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

/// Acquisti e costi (develop_microapps.md F5.11, Pro). Dart puro: niente Flutter, niente
/// Drift. La pagina converte le righe `Purchase` in [PurchaseEntry] nel punto in cui servono,
/// come fa il calcolatore del consumo con `toMeasurements()`.
///
/// ⚑ Tutto in **centesimi interi** in entrata e in uscita (`totalCostCents`, come nel
/// database): sommare euro in `double` porta a 419,99999 dopo dieci acquisti. L'unica
/// divisione e' il costo medio per unita', che resta `double` perche' un sacco a 5,195 € e'
/// un dato vero (720 € / 138,6 sacchi), e lo arrotonda solo chi lo mostra.

/// Un acquisto, per i calcoli dei costi.
@immutable
class PurchaseEntry {
  const PurchaseEntry({required this.date, required this.quantity, this.totalCostCents});

  final CivilDate date;

  /// Nell'unita' della fonte, sempre > 0 (vincolo CHECK di `purchases`).
  final double quantity;

  /// Null se il costo non e' stato scritto (legna regalata, scontrino perso): l'acquisto
  /// conta nelle quantita' ma **non** nel costo medio, che altrimenti scenderebbe a torto.
  final int? totalCostCents;

  bool get hasCost => totalCostCents != null;

  @override
  bool operator ==(Object other) =>
      other is PurchaseEntry &&
      other.date == date &&
      other.quantity == quantity &&
      other.totalCostCents == totalCostCents;

  @override
  int get hashCode => Object.hash(date, quantity, totalCostCents);

  @override
  String toString() => 'PurchaseEntry($date, $quantity, $totalCostCents c)';
}

/// Una stagione di riscaldamento: dal 1 ottobre al 31 marzo dell'anno dopo, estremi compresi
/// (F5.11).
///
/// ⚑ Si identifica con l'anno in cui **comincia** ("inverno 2025/26" e' `HeatingSeason(2025)`):
/// cosi' due stagioni si confrontano con un intero e non esiste una stagione "a cavallo"
/// ambigua.
///
/// ⚑ Aprile-settembre non appartengono a nessuna stagione ([containing] restituisce null):
/// la definizione e' quella del piano. Un acquisto estivo (il pellet costa meno in agosto)
/// resta negli acquisti e nel costo medio, ma non nella spesa di una stagione.
@immutable
class HeatingSeason implements Comparable<HeatingSeason> {
  const HeatingSeason(this.startYear);

  /// L'anno del 1 ottobre con cui comincia.
  final int startYear;

  /// Primo giorno della stagione: 1 ottobre di [startYear].
  CivilDate get start => CivilDate(startYear, 10, 1);

  /// Ultimo giorno della stagione: 31 marzo dell'anno dopo.
  CivilDate get end => CivilDate(startYear + 1, 3, 31);

  /// `true` se [date] cade fra [start] e [end] compresi.
  bool contains(CivilDate date) => date.isSameOrAfter(start) && date.isSameOrBefore(end);

  /// La stagione che contiene [date], o null se [date] e' fra aprile e settembre.
  static HeatingSeason? containing(CivilDate date) {
    if (date.month >= 10) return HeatingSeason(date.year);
    if (date.month <= 3) return HeatingSeason(date.year - 1);
    return null;
  }

  /// La stagione da mostrare "adesso": quella in corso o, fra aprile e settembre, quella
  /// appena finita.
  ///
  /// ⚑ In estate non si mostra la stagione che deve ancora cominciare: avrebbe sempre zero
  /// euro, mentre il conto dell'inverno appena chiuso e' quello che interessa (e il nuovo
  /// prende il suo posto il 1 ottobre da solo).
  static HeatingSeason latest(CivilDate today) =>
      HeatingSeason(today.month >= 10 ? today.year : today.year - 1);

  /// "2025/26": l'etichetta corta, uguale in tutte le lingue.
  String get shortLabel => '$startYear/${((startYear + 1) % 100).toString().padLeft(2, '0')}';

  @override
  int compareTo(HeatingSeason other) => startYear.compareTo(other.startYear);

  @override
  bool operator ==(Object other) => other is HeatingSeason && other.startYear == startYear;

  @override
  int get hashCode => startYear.hashCode;

  @override
  String toString() => 'HeatingSeason($shortLabel)';
}

/// I totali di un gruppo di acquisti.
@immutable
class PurchaseTotals {
  const PurchaseTotals({
    required this.count,
    required this.quantity,
    required this.costedCount,
    required this.costedQuantity,
    required this.totalCostCents,
  });

  /// I totali di [entries] (anche vuoto: tutto zero, costo medio null).
  factory PurchaseTotals.of(Iterable<PurchaseEntry> entries) {
    var count = 0;
    var quantity = 0.0;
    var costedCount = 0;
    var costedQuantity = 0.0;
    var cents = 0;
    for (final e in entries) {
      count++;
      quantity += e.quantity;
      final c = e.totalCostCents;
      if (c != null) {
        costedCount++;
        costedQuantity += e.quantity;
        cents += c;
      }
    }
    return PurchaseTotals(
      count: count,
      quantity: quantity,
      costedCount: costedCount,
      costedQuantity: costedQuantity,
      totalCostCents: cents,
    );
  }

  static const PurchaseTotals empty = PurchaseTotals(
    count: 0,
    quantity: 0,
    costedCount: 0,
    costedQuantity: 0,
    totalCostCents: 0,
  );

  /// Quanti acquisti.
  final int count;

  /// Quantita' comprata in tutto, nell'unita' della fonte (anche quella senza costo).
  final double quantity;

  /// Quanti acquisti hanno un costo.
  final int costedCount;

  /// La quantita' degli acquisti con un costo: il denominatore del costo medio.
  final double costedQuantity;

  /// Spesa totale in centesimi (gli acquisti senza costo contano zero).
  final int totalCostCents;

  /// Il costo medio per unita', in centesimi; null se nessun acquisto ha un costo.
  ///
  /// ⚑ **Media ponderata per la quantita'** (`somma costi / somma quantita'` dei soli
  /// acquisti con costo), non la media dei prezzi unitari: 100 sacchi a 5 € e 2 sacchi a
  /// 8 € dal benzinaio fanno 5,06 € al sacco, non 6,50.
  double? get averageCentsPerUnit => costedQuantity > 0 ? totalCostCents / costedQuantity : null;

  /// Acquisti senza costo: la pagina lo dice, perche' la spesa mostrata e' per difetto.
  int get uncostedCount => count - costedCount;

  bool get isEmpty => count == 0;

  @override
  bool operator ==(Object other) =>
      other is PurchaseTotals &&
      other.count == count &&
      other.quantity == quantity &&
      other.costedCount == costedCount &&
      other.costedQuantity == costedQuantity &&
      other.totalCostCents == totalCostCents;

  @override
  int get hashCode => Object.hash(count, quantity, costedCount, costedQuantity, totalCostCents);

  @override
  String toString() =>
      'PurchaseTotals($count acquisti, $quantity, $totalCostCents c su $costedQuantity)';
}

/// I totali degli acquisti di [entries] che cadono nella stagione [season].
PurchaseTotals seasonTotals(Iterable<PurchaseEntry> entries, HeatingSeason season) =>
    PurchaseTotals.of(entries.where((e) => season.contains(e.date)));

/// I totali per stagione, **dalla piu' recente**; solo le stagioni con almeno un acquisto.
/// Gli acquisti fuori stagione (aprile-settembre) non compaiono.
List<(HeatingSeason, PurchaseTotals)> totalsBySeason(Iterable<PurchaseEntry> entries) {
  final groups = <HeatingSeason, List<PurchaseEntry>>{};
  for (final e in entries) {
    final s = HeatingSeason.containing(e.date);
    if (s != null) (groups[s] ??= []).add(e);
  }
  final seasons = groups.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final s in seasons) (s, PurchaseTotals.of(groups[s]!))];
}

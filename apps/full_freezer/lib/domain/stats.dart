import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';

/// Il periodo delle statistiche.
enum StatsPeriod { month, year, all }

/// Un mese della serie: quante uscite consumate e buttate.
@immutable
class MonthBar {
  const MonthBar({required this.year, required this.month, required this.consumed, required this.discarded});

  final int year;
  final int month;
  final int consumed;
  final int discarded;

  int get total => consumed + discarded;
}

/// I numeri dello spreco (Pro, develop_microapps.md F4.10 "Statistiche").
@immutable
class WasteStats {
  const WasteStats({
    required this.consumed,
    required this.discarded,
    required this.averageDays,
    required this.mostWastedCategory,
    required this.mostWastedCount,
    required this.months,
  });

  final int consumed;
  final int discarded;

  /// Quanti giorni resta in media un alimento nel freezer prima di uscire; null senza uscite.
  final double? averageDays;

  /// La categoria buttata piu' spesso (chiave), e quante volte; null se nulla e' stato buttato.
  final String? mostWastedCategory;
  final int mostWastedCount;

  /// Gli ultimi sei mesi, dal piu' vecchio al piu' recente (per il grafico).
  final List<MonthBar> months;

  int get total => consumed + discarded;

  /// La quota buttata, 0..1; 0 senza uscite.
  double get wasteRate => total == 0 ? 0 : discarded / total;

  bool get isEmpty => total == 0;
}

/// Quanti mesi mostra il grafico.
const int statsMonths = 6;

/// Calcola le statistiche dagli alimenti usciti. Funzione pura: niente database, niente
/// orologio (il "oggi" si passa).
///
/// ⚑ Si contano le **righe** uscite, non le quantita': "ho buttato 1 confezione e 500 g"
/// non si somma in modo onesto. Una riga e' "una cosa che e' uscita dal freezer", ed e' il
/// numero che una persona riconosce.
WasteStats computeStats(Iterable<Item> removed, {required StatsPeriod period, required DateTime now}) {
  final today = CivilDate.fromDateTime(now);
  final from = switch (period) {
    StatsPeriod.month => today.addDays(-30),
    StatsPeriod.year => today.addDays(-365),
    StatsPeriod.all => null,
  };

  var consumed = 0;
  var discarded = 0;
  var daysSum = 0;
  var daysCount = 0;
  final wastedByCategory = <String, int>{};

  for (final item in removed) {
    final at = item.removedAt;
    if (at == null || item.status == ItemStatus.stored) continue;
    final out = CivilDate.fromDateTime(DateTime.fromMillisecondsSinceEpoch(at, isUtc: true).toLocal());
    if (from != null && out.isBefore(from)) continue;
    if (item.status == ItemStatus.consumed) {
      consumed++;
    } else {
      discarded++;
      final key = item.category ?? 'other';
      wastedByCategory[key] = (wastedByCategory[key] ?? 0) + 1;
    }
    final frozen = CivilDate.tryParse(item.frozenAt);
    if (frozen != null) {
      final d = frozen.daysUntil(out);
      daysSum += d < 0 ? 0 : d;
      daysCount++;
    }
  }

  String? worst;
  var worstCount = 0;
  for (final e in wastedByCategory.entries) {
    if (e.value > worstCount) {
      worst = e.key;
      worstCount = e.value;
    }
  }

  // Il grafico mostra sempre gli ultimi sei mesi, qualunque sia il periodo scelto: e'
  // l'andamento, non un riassunto.
  final months = <MonthBar>[];
  for (var i = statsMonths - 1; i >= 0; i--) {
    final first = today.firstDayOfMonth.addMonths(-i);
    var c = 0;
    var d = 0;
    for (final item in removed) {
      final at = item.removedAt;
      if (at == null) continue;
      final out = DateTime.fromMillisecondsSinceEpoch(at, isUtc: true).toLocal();
      if (out.year != first.year || out.month != first.month) continue;
      if (item.status == ItemStatus.consumed) c++;
      if (item.status == ItemStatus.discarded) d++;
    }
    months.add(MonthBar(year: first.year, month: first.month, consumed: c, discarded: d));
  }

  return WasteStats(
    consumed: consumed,
    discarded: discarded,
    averageDays: daysCount == 0 ? null : daysSum / daysCount,
    mostWastedCategory: worst,
    mostWastedCount: worstCount,
    months: months,
  );
}

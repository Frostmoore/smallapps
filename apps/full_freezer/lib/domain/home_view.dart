import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import 'aging.dart';
import 'capacity.dart';

/// Un alimento pronto da disegnare: la riga del database con la sua anzianita'.
@immutable
class ItemRow {
  const ItemRow({required this.item, required this.aging, required this.freezerName});

  final Item item;
  final AgingInfo aging;

  /// Il nome del freezer, mostrato solo quando la home guarda "Tutti".
  final String freezerName;
}

/// Un freezer con il suo conteggio e il suo riempimento, per la sezione "Dove sono".
@immutable
class FreezerSummary {
  const FreezerSummary({required this.freezer, required this.count, required this.fill});

  final Freezer freezer;
  final int count;
  final FillInfo fill;
}

/// Tutto quello che la home mostra (develop_microapps.md F4.4).
@immutable
class HomeView {
  const HomeView({
    required this.selectedFreezer,
    required this.useSoonAll,
    required this.rest,
    required this.freezers,
  });

  /// Il freezer guardato, o null per "Tutti".
  final Freezer? selectedFreezer;

  /// Tutti gli alimenti watch/old, **i piu' vecchi per primi** (la pagina "vedi tutti").
  final List<ItemRow> useSoonAll;

  /// "Da usare prima" in home: i primi [useSoonPreview].
  List<ItemRow> get useSoon => useSoonAll.take(useSoonPreview).toList();

  /// Quanti sono in tutto quelli da usare presto (il contatore della testata).
  int get useSoonTotal => useSoonAll.length;

  /// "Tutto il resto": dal piu' vecchio al piu' nuovo.
  final List<ItemRow> rest;

  final List<FreezerSummary> freezers;

  int get totalCount => useSoonTotal + rest.length;

  /// Il riempimento del freezer guardato; null con "Tutti" (ogni freezer ha il suo).
  FillInfo? get selectedFill {
    final sel = selectedFreezer;
    if (sel == null) return null;
    for (final s in freezers) {
      if (s.freezer.id == sel.id) return s.fill;
    }
    return null;
  }

  bool get isEmpty => totalCount == 0;
}

/// Quanti alimenti mostra "Da usare prima" prima del "vedi tutti".
const int useSoonPreview = 5;

/// Costruisce la home dai dati grezzi. Funzione pura: niente Flutter, niente database.
///
/// ⚑ "Da usare prima" e "Tutto il resto" si dividono gli alimenti **senza ripetizioni**:
/// "Tutto il resto" contiene solo i `fresh`, e i `watch`/`old` oltre i primi cinque stanno
/// dietro al "vedi tutti" di "Da usare prima". Mostrare un alimento in due sezioni farebbe
/// sembrare il freezer piu' pieno di quello che e'.
HomeView buildHomeView({
  required List<Freezer> freezers,
  required List<Item> storedItems,
  required int? selectedFreezerId,
  required CivilDate today,
  AgingCalculator aging = const AgingCalculator(),
  CapacityEstimator capacity = const CapacityEstimator(),
}) {
  final byId = {for (final f in freezers) f.id: f};
  final selected = selectedFreezerId == null ? null : byId[selectedFreezerId];

  final rows = <ItemRow>[];
  for (final item in storedItems) {
    if (selected != null && item.freezerId != selected.id) continue;
    rows.add(
      ItemRow(
        item: item,
        aging: aging.evaluate(
          frozenAt: CivilDate.parse(item.frozenAt),
          reminderAfterDays: item.reminderAfterDays,
          categoryKey: item.category,
          today: today,
        ),
        freezerName: byId[item.freezerId]?.name ?? '',
      ),
    );
  }
  // Il repository li da' gia' in ordine, ma la funzione non si fida: e' la promessa dell'app.
  rows.sort(
    (a, b) => compareOldestFirst(
      CivilDate.parse(a.item.frozenAt),
      CivilDate.parse(b.item.frozenAt),
      tieA: a.item.id,
      tieB: b.item.id,
    ),
  );

  final soon = [for (final r in rows) if (r.aging.level != AgingLevel.fresh) r];
  final rest = [for (final r in rows) if (r.aging.level == AgingLevel.fresh) r];

  final summaries = <FreezerSummary>[
    for (final f in freezers)
      FreezerSummary(
        freezer: f,
        count: storedItems.where((i) => i.freezerId == f.id).length,
        fill: capacity.fill(
          capacityLiters: f.capacityLiters,
          calibration: f.calibration,
          itemLiters: [for (final i in storedItems) if (i.freezerId == f.id) i.volumeLiters],
        ),
      ),
  ];

  return HomeView(
    selectedFreezer: selected,
    useSoonAll: soon,
    rest: rest,
    freezers: summaries,
  );
}

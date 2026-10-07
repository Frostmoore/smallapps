import 'dart:io';

import 'package:micro_core/micro_core.dart';

import '../app/formats.dart';
import '../data/database.dart';
import '../domain/aging.dart';
import '../features/items/item_pickers.dart';
import '../l10n/generated/app_localizations.dart';

/// L'elenco di cosa c'e' nel freezer in un foglio di calcolo (Pro, `FeatureKey.csvExport`).
///
/// ⚑ Separatore `;` e BOM UTF-8, le impostazioni di `CsvWriter`: e' il formato che Excel in
/// italiano apre con un doppio clic, accenti compresi. Con la virgola e senza BOM Excel
/// mette tutto in una colonna e scrive "PurÃ¨".
///
/// Le colonne sono quelle che servono a stampare la lista o a fare la spesa: niente id,
/// niente litri stimati.
Future<File> exportStoredCsv({
  required AppPaths paths,
  required L l,
  required List<Item> items,
  required List<Freezer> freezers,
  required Map<int, List<Compartment>> compartments,
  required CivilDate today,
  List<CustomCategory> customCategories = const [],
}) {
  final csv = buildStoredCsv(
    l: l,
    items: items,
    freezers: freezers,
    compartments: compartments,
    today: today,
    customCategories: customCategories,
  );
  return csv.writeTo(paths.file(paths.exports, 'full-freezer-${today.toIso()}.csv'));
}

/// Il contenuto del CSV, separato dalla scrittura su file perche' si possa provare senza
/// disco (`AppPaths` vuole `path_provider`, che nei test non c'e').
CsvWriter buildStoredCsv({
  required L l,
  required List<Item> items,
  required List<Freezer> freezers,
  required Map<int, List<Compartment>> compartments,
  required CivilDate today,
  List<CustomCategory> customCategories = const [],
}) {
  final names = {for (final f in freezers) f.id: f.name};
  final csv = CsvWriter()
    ..addHeader([
      l.csv_name,
      l.item_category,
      l.item_quantity,
      l.csv_unit,
      l.item_frozenAt,
      l.csv_days,
      l.csv_freezer,
      l.csv_compartment,
      l.item_note,
    ]);
  const aging = AgingCalculator();
  for (final i in items) {
    final compartment = (compartments[i.freezerId] ?? const <Compartment>[])
        .where((c) => c.id == i.compartmentId)
        .firstOrNull;
    csv.addRow([
      i.name,
      categoryName(l, i.category, customCategories),
      formatQuantity(i.quantity, l.localeName),
      unitName(l, i.unit, i.quantity),
      i.frozenAt,
      aging.daysInFreezer(CivilDate.parse(i.frozenAt), today: today),
      names[i.freezerId] ?? '',
      compartment?.name ?? '',
      i.note ?? '',
    ]);
  }
  return csv;
}

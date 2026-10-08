import 'dart:io';

import 'package:micro_core/micro_core.dart';

import '../app/labels.dart';
import '../data/database.dart';
import '../domain/fuel_source.dart';
import '../l10n/generated/app_localizations.dart';

/// Misurazioni e acquisti in un foglio di calcolo (F5.11, Pro, `FeatureKey.csvExport`).
///
/// ⚑ **Un file solo, con una colonna "Tipo"** (Misurazione / Acquisto), e non due file:
/// 1. il foglio di condivisione (`BackupService.shareBackup`) manda un file alla volta: con
///    due file l'utente dovrebbe esportare due volte e ricordarsi di farlo;
/// 2. in Excel il filtro sulla colonna "Tipo" separa le due cose con un clic, mentre
///    ricucire due file per vedere "ho comprato il 3, il 10 restavano 40 sacchi" non lo fa
///    nessuno;
/// 3. le colonne in comune (fonte, data, quantita', unita') sono la maggior parte; quelle
///    proprie di un tipo (lettura %, costo, fornitore) restano vuote nelle righe dell'altro.
///
/// ⚑ Separatore `;` e BOM UTF-8, le impostazioni di `CsvWriter`: e' il formato che Excel in
/// italiano apre con un doppio clic, accenti compresi.
///
/// ⚑ **I numeri sono numeri, non testo formattato**: niente separatore delle migliaia e
/// virgola decimale sempre (come fa `CsvWriter` con i `double`). `formatQuantity` in inglese
/// scriverebbe "1,200" per milleduecento litri, che Excel italiano legge 1,2. Il costo e' in
/// euro con due decimali ("12,50"), senza simbolo, perche' Excel possa sommarlo.

/// Scrive il CSV nella cartella delle esportazioni e ne restituisce il file.
Future<File> exportScorteCsv({
  required AppPaths paths,
  required L l,
  required List<FuelSource> sources,
  required List<StockMeasurement> measurements,
  required List<Purchase> purchases,
  required CivilDate today,
}) {
  final csv = buildScorteCsv(l: l, sources: sources, measurements: measurements, purchases: purchases);
  return csv.writeTo(paths.file(paths.exports, 'scorte-calore-${today.toIso()}.csv'));
}

/// Il contenuto del CSV, separato dalla scrittura su file perche' si possa provare senza
/// disco (`AppPaths` vuole `path_provider`, che nei test non c'e').
///
/// Righe raggruppate per fonte (nell'ordine di [sources]), e dentro la fonte in ordine di
/// data; a parita' di data prima la misurazione. Misurazioni e acquisti di fonti che non sono
/// in [sources] si saltano: senza la fonte non c'e' ne' nome ne' unita'.
CsvWriter buildScorteCsv({
  required L l,
  required List<FuelSource> sources,
  required List<StockMeasurement> measurements,
  required List<Purchase> purchases,
}) {
  final csv = CsvWriter()
    ..addHeader([
      l.csv_kind,
      l.csv_source,
      l.csv_date,
      l.csv_quantity,
      l.csv_unit,
      l.csv_reading,
      l.csv_cost,
      l.csv_supplier,
      l.csv_note,
    ]);
  for (final s in sources) {
    final rows = <(String, int, List<Object?>)>[
      for (final m in measurements.where((m) => m.fuelSourceId == s.id))
        (
          m.date,
          0,
          [
            l.csv_kindMeasurement,
            s.name,
            m.date,
            csvDecimal(m.quantity),
            unitName(l, s.unit, m.quantity),
            // La lettura del manometro solo se l'utente ha digitato una percentuale: per una
            // misura assoluta il rawInput e' la quantita' stessa, ripeterlo confonderebbe.
            m.enteredAs == EnteredAs.percentage.key ? csvDecimal(m.rawInput) : null,
            null,
            null,
            m.note,
          ],
        ),
      for (final p in purchases.where((p) => p.fuelSourceId == s.id))
        (
          p.date,
          1,
          [
            l.csv_kindPurchase,
            s.name,
            p.date,
            csvDecimal(p.quantity),
            unitName(l, s.unit, p.quantity),
            null,
            p.totalCostCents == null ? null : csvDecimal(p.totalCostCents! / 100, fixed: true),
            p.supplier,
            p.note,
          ],
        ),
    ]..sort((a, b) {
      final byDate = a.$1.compareTo(b.$1);
      return byDate != 0 ? byDate : a.$2.compareTo(b.$2);
    });
    for (final r in rows) {
      csv.addRow(r.$3);
    }
  }
  return csv;
}

/// Un numero come lo legge Excel italiano: virgola decimale, niente migliaia, al massimo due
/// decimali ("12,5", "344", "0,25"). Con [fixed] sempre due decimali ("12,50"), per i soldi.
///
/// ⚑ Una stringa e non il `double` grezzo a `CsvWriter`: `343.99999999999994.toString()`
/// finirebbe nel foglio cosi' com'e', e "70.0" diventerebbe "70,0".
String csvDecimal(double value, {bool fixed = false}) {
  var s = value.toStringAsFixed(2);
  if (!fixed) {
    s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    if (s == '-0') s = '0';
  }
  return s.replaceAll('.', ',');
}

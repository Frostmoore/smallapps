import 'dart:io';

import 'package:micro_core/micro_core.dart';

import '../app/labels.dart';
import '../data/database.dart';
import '../data/film_repository.dart';
import '../domain/film_types.dart';
import '../domain/roll_status.dart';
import '../l10n/generated/app_localizations.dart';

/// I rullini in un foglio di calcolo (F6.11, Pro, `FeatureKey.csvExport`).
///
/// ⚑ **Una riga per rullino**, e non una per evento come in Scorte Calore: in Film Tracker
/// l'unita' che l'utente ragiona e' il rullino (il "#17"), e sviluppo (uno al massimo) e
/// stampe (N) ne sono attributi. Le stampe si riassumono in quattro colonne (ordini, copie,
/// laboratori, costo): una colonna per ordine renderebbe il numero di colonne variabile, e
/// Excel non sa sommare una colonna che cambia posto da un file all'altro.
///
/// ⚑ Separatore `;` e BOM UTF-8, le impostazioni di `CsvWriter`: e' il formato che Excel in
/// italiano apre con un doppio clic, accenti compresi.
///
/// ⚑ **I numeri sono numeri**: costi in euro con due decimali e virgola ("6,50"), senza
/// simbolo, perche' Excel possa sommarli; ISO e fotogrammi interi. Le date restano ISO
/// (`2026-09-01`): Excel le riconosce come date in qualunque lingua, "1 set 2026" no.
///
/// ⚑ Costo totale **vuoto** (non 0) per un rullino senza nessun costo scritto: e' la stessa
/// regola delle statistiche (`StatsRoll.hasAnyCost`), per cui un rullino regalato o senza
/// scontrino non e' "gratis", e' "non saputo".

/// Scrive il CSV nella cartella delle esportazioni e ne restituisce il file.
Future<File> exportRollsCsv({
  required AppPaths paths,
  required L l,
  required List<RollListItem> items,
  required CivilDate today,
}) {
  final csv = buildRollsCsv(l: l, items: items);
  return csv.writeTo(paths.file(paths.exports, 'film-tracker-${today.toIso()}.csv'));
}

/// Il contenuto del CSV, separato dalla scrittura su file perche' si possa provare senza
/// disco.
///
/// Righe **dal numero piu' basso** (`sequenceNumber` crescente): un registro si legge in
/// ordine cronologico, al contrario della home che mostra prima l'ultimo rullino.
CsvWriter buildRollsCsv({required L l, required List<RollListItem> items}) {
  final csv = CsvWriter()
    ..addHeader([
      l.csv_number,
      l.csv_title,
      l.csv_film,
      l.csv_format,
      l.csv_nominalIso,
      l.csv_exposedIso,
      l.csv_camera,
      l.csv_status,
      l.csv_loadedAt,
      l.csv_finishedAt,
      l.csv_frames,
      l.csv_filmCost,
      l.csv_lab,
      l.csv_devSubmitted,
      l.csv_devReturned,
      l.csv_process,
      l.csv_selfDeveloped,
      l.csv_devCost,
      l.csv_scanCost,
      l.csv_printOrders,
      l.csv_printCount,
      l.csv_printLabs,
      l.csv_printCost,
      l.csv_totalCost,
      l.csv_note,
    ]);

  final sorted = [...items]..sort((a, b) => a.roll.sequenceNumber.compareTo(b.roll.sequenceNumber));
  for (final item in sorted) {
    final r = item.roll;
    final d = item.development;
    final prints = item.prints;

    // Le stampe riassunte: quante copie (solo se almeno un ordine le dice), quali
    // laboratori (senza doppioni, nella grafia vista per prima), quanto in tutto (solo se
    // almeno un ordine ha un costo).
    final copies = prints.any((p) => p.numberOfPrints != null)
        ? prints.fold<int>(0, (s, p) => s + (p.numberOfPrints ?? 0))
        : null;
    final labs = <String>[];
    for (final p in prints) {
      final lab = p.laboratory?.trim();
      if (lab == null || lab.isEmpty) continue;
      if (!labs.any((x) => x.toLowerCase() == lab.toLowerCase())) labs.add(lab);
    }
    final printCost = prints.any((p) => p.costCents != null)
        ? prints.fold<int>(0, (s, p) => s + (p.costCents ?? 0))
        : null;

    final costs = [r.costCents, d?.developmentCostCents, d?.scanCostCents, printCost];
    final total = costs.any((c) => c != null) ? costs.fold<int>(0, (s, c) => s + (c ?? 0)) : null;

    csv.addRow([
      r.sequenceNumber,
      r.title,
      r.filmName,
      _formatName(l, r.format),
      r.nominalIso,
      r.exposedIso,
      item.camera?.displayName,
      _statusName(l, r),
      r.loadedAt,
      r.finishedAt,
      r.frames,
      _euros(r.costCents),
      d?.laboratory,
      d?.submittedAt,
      d?.returnedAt,
      d == null || d.process == null ? null : _processName(l, d.process!),
      d == null ? null : (d.selfDeveloped ? l.csv_yes : l.csv_no),
      _euros(d?.developmentCostCents),
      _euros(d?.scanCostCents),
      prints.isEmpty ? null : prints.length,
      copies,
      labs.isEmpty ? null : labs.join(', '),
      _euros(printCost),
      _euros(total),
      r.note,
    ]);
  }
  return csv;
}

/// Centesimi in euro come li legge Excel italiano: sempre due decimali, virgola, niente
/// simbolo ("6,50"). Null resta cella vuota.
///
/// ⚑ Dagli interi e non da un `double`: 650 / 100 in virgola mobile puo' dare 6.499999...,
/// e un costo nel foglio deve essere esattamente quello scritto nell'app.
String? _euros(int? cents) {
  if (cents == null) return null;
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  return '$sign${abs ~/ 100},${(abs % 100).toString().padLeft(2, '0')}';
}

/// ☠ Le chiavi sconosciute (un backup di una versione futura) finiscono nel foglio cosi'
/// come sono invece di far fallire tutto l'export: il CSV e' un'uscita, non deve mai essere
/// il punto in cui l'app si rompe.
String _formatName(L l, String key) {
  final f = FilmFormat.byKey(key);
  return f == null ? key : formatName(l, f);
}

String _processName(L l, String key) {
  final p = FilmProcess.byKey(key);
  return p == null ? key : processName(l, p);
}

String _statusName(L l, FilmRoll r) {
  final s = RollStatus.byKey(r.status);
  return s == null ? r.status : statusName(l, s);
}

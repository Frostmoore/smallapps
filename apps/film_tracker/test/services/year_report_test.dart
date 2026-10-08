import 'dart:io';
import 'dart:typed_data';

import 'package:film_tracker/data/database.dart';
import 'package:film_tracker/data/film_repository.dart';
import 'package:film_tracker/domain/film_stats.dart';
import 'package:film_tracker/l10n/generated/app_localizations.dart';
import 'package:film_tracker/services/year_report.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:intl/date_symbol_data_local.dart';
import 'package:micro_core/micro_core.dart';
import 'package:pdf/widgets.dart' as pw;

/// F6.11: il PDF di riepilogo annuale si genera con il font dell'app, ha una copertina e una
/// pagina per rullino, e non fallisce per una foto sparita.
void main() {
  final l = lookupL(const Locale('it'));
  late pw.Font font;
  final jpeg = Uint8List.fromList(img.encodeJpg(img.Image(width: 400, height: 267)));

  setUpAll(() async {
    await initializeDateFormatting('it');
    // Il file vero degli asset: e' proprio lui che deve reggere accenti, € e virgolette.
    final bytes = File('assets/fonts/PlusJakartaSans-Variable.ttf').readAsBytesSync();
    font = pw.Font.ttf(ByteData.sublistView(bytes));
  });

  FilmRoll roll(int id, {String loadedAt = '2026-03-01', int? cost}) => FilmRoll(
    id: id,
    sequenceNumber: id,
    filmName: 'Kodak Portra 400',
    format: '35mm',
    nominalIso: 400,
    exposedIso: id == 2 ? 800 : 400,
    loadedAt: loadedAt,
    frames: 36,
    title: id == 2 ? 'Praga — “settembre”' : null,
    note: id == 2 ? 'Perché sì: città più bella d’Europa' : null,
    status: 'archived',
    costCents: cost,
    createdAt: 0,
  );

  RollImage image(int id, int rollId) => RollImage(
    id: id,
    filmRollId: rollId,
    path: 'images/rolls/$id.jpg',
    thumbPath: 'images/thumbs/rolls/$id.jpg',
    width: 1600,
    height: 1067,
    bytes: 1,
    kind: 'contactSheet',
    sortOrder: id,
    createdAt: 0,
  );

  YearStats stats(List<RollListItem> items) => const FilmStatsCalculator().forYear(2026, [
    for (final i in items)
      StatsRoll(date: reportDateOf(i.roll), frames: i.roll.frames, filmName: i.roll.filmName, costCents: i.roll.costCents),
  ]);

  test('rollsOfYear tiene solo l\'anno chiesto, dal numero piu\' basso', () {
    final items = [
      RollListItem(roll: roll(3)),
      RollListItem(roll: roll(1)),
      RollListItem(roll: roll(2, loadedAt: '2025-12-30')),
    ];
    expect(rollsOfYear(items, 2026).map((i) => i.roll.id), [1, 3]);
    expect(rollsOfYear(items, 2025).map((i) => i.roll.id), [2]);
  });

  test('copertina piu\' una pagina per rullino; una foto mancante non lo fa fallire', () async {
    final items = [
      RollListItem(roll: roll(1, cost: 1590)),
      RollListItem(
        roll: roll(2, cost: 1200),
        development: const Development(
          id: 1,
          filmRollId: 2,
          laboratory: 'Fotoservice',
          submittedAt: '2026-03-21',
          returnedAt: '2026-03-30',
          developmentCostCents: 900,
          selfDeveloped: false,
        ),
        prints: const [PrintOrder(id: 1, filmRollId: 2, laboratory: 'Lab Roma', numberOfPrints: 10, costCents: 450)],
      ),
    ];
    final letti = <String>[];
    final doc = await buildYearReportDocument(
      l: l,
      stats: stats(items),
      rolls: [
        YearReportRoll(item: items[0]),
        YearReportRoll(item: items[1], images: [image(10, 2), image(11, 2), image(12, 2), image(13, 2)]),
      ],
      font: font,
      // La 13 "manca dal disco".
      readImage: (rel) async {
        letti.add(rel);
        return rel.contains('/13.') ? null : jpeg;
      },
      today: CivilDate(2026, 10, 8),
      topCameraName: 'Olympus OM-2',
    );
    final bytes = await doc.save();

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(doc.document.pdfPageList.pages, hasLength(3), reason: 'copertina + due rullini');
    expect(letti, everyElement(startsWith('images/thumbs/')), reason: 'nel PDF vanno le miniature');
  });

  test('un rullino con molte foto continua sulle pagine dopo, senza far fallire il documento', () async {
    final items = [RollListItem(roll: roll(1))];
    final doc = await buildYearReportDocument(
      l: l,
      stats: stats(items),
      rolls: [
        YearReportRoll(item: items[0], images: [for (var i = 0; i < 30; i++) image(i, 1)]),
      ],
      font: font,
      readImage: (_) async => jpeg,
      today: CivilDate(2026, 10, 8),
    );
    final bytes = await doc.save();
    expect(bytes, isNotEmpty);
    // 30 foto = 10 righe da 128 pt: non stanno in un A4 con l'intestazione del rullino.
    expect(doc.document.pdfPageList.pages.length, greaterThanOrEqualTo(3));
  });

  test('buildYearReport restituisce i byte di un anno senza costi', () async {
    final items = [RollListItem(roll: roll(1))];
    final bytes = await buildYearReport(
      l: l,
      stats: stats(items),
      rolls: [YearReportRoll(item: items[0])],
      font: font,
      readImage: (_) async => null,
      today: CivilDate(2026, 10, 8),
    );
    expect(bytes.length, greaterThan(1000));
  });
}

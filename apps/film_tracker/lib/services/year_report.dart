import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../app/labels.dart';
import '../data/database.dart';
import '../data/film_repository.dart';
import '../domain/film_stats.dart';
import '../domain/film_types.dart';
import '../l10n/generated/app_localizations.dart';

/// Il PDF di riepilogo annuale (F6.11, Pro, `FeatureKey.pdfReport`): una copertina con
/// l'anno e i totali, poi **una pagina per rullino** con date, costi e la griglia delle foto.
///
/// ⚑ **Qui nell'app e non `PdfReportBuilder` in micro_core** (DT-10): il debito diceva di
/// costruirlo "quando si sa che forma deve avere il riepilogo". Scritto, la forma e' tutta di
/// Film Tracker (rullini, timeline, foto): le altre tre app non hanno un PDF e non ne avranno
/// (F6.11, ⚑ "perche' il PDF e' Pro qui e non nelle altre app"). Un builder generico in
/// micro_core oggi sarebbe un'astrazione con un utente solo; il giorno che servisse a una
/// seconda app, si estraggono da qui pagina, tema e piede (le funzioni `_theme`, `_footer`).
///
/// ⚑ **Il carattere e' Plus Jakarta Sans, lo stesso dell'app**, dal file variabile in
/// `assets/fonts`. Il pacchetto `pdf` non sa istanziare un font variabile, ma il file ha i
/// contorni `glyf` della sua istanza di default, che e' il peso 400 (verificato con fontTools:
/// asse `wght` 200-800, default 400): letto cosi' e' un Regular normale, con accenti italiani,
/// `€`, virgolette tipografiche e `≈`. Il grassetto non esiste (servirebbe un'istanza statica
/// a parte): la gerarchia si fa con corpo e colore, e il tema usa lo stesso file anche per
/// `bold` perche' un `fontWeight: bold` non ricada sull'Helvetica senza accenti.
///
/// ☠ **Helvetica (il font di base del PDF) non va**: e' in codifica WinAnsi, e senza un TTF
/// incorporato `pdf` disegna i caratteri fuori codifica come quadrati o lancia; la frase
/// "Nessun costo registrato per quest’anno" ha gia' l'apostrofo tipografico.
///
/// ☠ U+202F (spazio stretto indivisibile) non e' nel font e `intl` lo usa in alcune lingue
/// fra numero e simbolo: ogni testo passa da [_t], che lo sostituisce con U+00A0.
///
/// ⚑ Le foto sono le **miniature** (400 px di lato lungo, F6.9): in una griglia a tre colonne
/// su A4 una cella e' larga circa 5,5 cm, cioe' ~180 dpi, abbastanza per la stampa. Con le
/// immagini grandi un anno da 100 rullini peserebbe quasi 100 MB.

/// I dati di un rullino nel PDF: la sua riga completa e le sue immagini, nell'ordine
/// dell'utente.
@immutable
class YearReportRoll {
  const YearReportRoll({required this.item, this.images = const []});

  final RollListItem item;
  final List<RollImage> images;
}

/// La data con cui un rullino cade in un anno: `loadedAt`, o il giorno (locale) di
/// creazione se manca.
///
/// ⚑ **La stessa regola di `FilmRepository.statsRolls`** (F6.10): copertina e statistiche
/// devono contare gli stessi rullini, altrimenti il PDF dice "12 rullini" e ne mostra 11.
CivilDate reportDateOf(FilmRoll roll) => roll.loadedDate ?? CivilDate.fromDateTime(roll.createdAtUtc);

/// I rullini dell'anno [year], **dal numero piu' basso**: il PDF si sfoglia in ordine
/// cronologico, come un quaderno.
List<RollListItem> rollsOfYear(Iterable<RollListItem> items, int year) =>
    [for (final i in items) if (reportDateOf(i.roll).year == year) i]
      ..sort((a, b) => a.roll.sequenceNumber.compareTo(b.roll.sequenceNumber));

/// Il font del PDF, dagli asset dell'app.
Future<pw.Font> loadReportFont() async =>
    pw.Font.ttf(await rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));

/// Il documento del riepilogo, pronto da salvare (`await doc.save()`).
///
/// [readImage] riceve un percorso relativo (`RollImage.thumbPath`) e restituisce i byte del
/// file, o null se manca: una foto sparita diventa un riquadro vuoto, mai un PDF che fallisce.
/// [topCameraName] e' il nome della macchina piu' usata (`YearStats.topCameraId` risolto dalla
/// UI). [today] e' la data scritta in copertina.
///
/// Separato da [buildYearReport] perche' i test contino le pagine
/// (`doc.document.pdfPageList.pages`) dopo il salvataggio.
Future<pw.Document> buildYearReportDocument({
  required L l,
  required YearStats stats,
  required List<YearReportRoll> rolls,
  required pw.Font font,
  required Future<Uint8List?> Function(String relativePath) readImage,
  required CivilDate today,
  String? topCameraName,
}) async {
  final doc = pw.Document(
    title: l.report_subject(stats.year.toString()),
    author: l.appTitle,
    creator: l.appTitle,
    theme: _theme(font),
  );
  final year = stats.year.toString();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: _margin,
      footer: (c) => _footer(c, l, year),
      build: (_) => _cover(l, stats, rolls, today, topCameraName),
    ),
  );

  for (final r in rolls) {
    final images = <pw.ImageProvider?>[];
    for (final i in r.images) {
      final bytes = await readImage(i.thumbPath);
      images.add(bytes == null || bytes.isEmpty ? null : pw.MemoryImage(bytes));
    }
    // ⚑ Un MultiPage per rullino e non un Page: ogni rullino comincia su una pagina sua, ma
    // uno con venti foto continua sulla successiva invece di far fallire il documento.
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: _margin,
        footer: (c) => _footer(c, l, year),
        build: (_) => _rollPage(l, r.item, images),
      ),
    );
  }
  return doc;
}

/// Il PDF in byte, pronto da stampare (`Printing.layoutPdf`) o condividere.
Future<Uint8List> buildYearReport({
  required L l,
  required YearStats stats,
  required List<YearReportRoll> rolls,
  required pw.Font font,
  required Future<Uint8List?> Function(String relativePath) readImage,
  required CivilDate today,
  String? topCameraName,
}) async {
  final doc = await buildYearReportDocument(
    l: l,
    stats: stats,
    rolls: rolls,
    font: font,
    readImage: readImage,
    today: today,
    topCameraName: topCameraName,
  );
  return doc.save();
}

// ── Stile ────────────────────────────────────────────────────────────────────

const pw.EdgeInsets _margin = pw.EdgeInsets.fromLTRB(40, 44, 40, 36);

/// Inchiostro, grigio e ambra (il seme dell'app, F6.1). ⚑ Fondo bianco anche se l'app e'
/// scura: e' carta, e un fondo scuro stampato consuma una cartuccia per pagina.
const PdfColor _ink = PdfColor.fromInt(0xFF1E1B18);
const PdfColor _muted = PdfColor.fromInt(0xFF6B6259);
const PdfColor _accent = PdfColor.fromInt(0xFFB5782A);
const PdfColor _rule = PdfColor.fromInt(0xFFE4DDD3);
const PdfColor _cell = PdfColor.fromInt(0xFFF3EFE9);

pw.ThemeData _theme(pw.Font font) => pw.ThemeData.withFont(
  base: font,
  bold: font,
  italic: font,
  boldItalic: font,
).copyWith(defaultTextStyle: pw.TextStyle(font: font, fontSize: 10.5, color: _ink, lineSpacing: 2));

/// Ogni testo del PDF passa da qui: vedi U+202F nel commento in testa al file.
String _t(String s) => s.replaceAll(' ', ' ');

pw.Widget _text(String s, {double size = 10.5, PdfColor color = _ink}) =>
    pw.Text(_t(s), style: pw.TextStyle(fontSize: size, color: color));

pw.Widget _footer(pw.Context c, L l, String year) => pw.Container(
  alignment: pw.Alignment.centerRight,
  margin: const pw.EdgeInsets.only(top: 12),
  child: _text('${l.appTitle} · $year · ${c.pageNumber}/${c.pagesCount}', size: 8, color: _muted),
);

pw.Widget _sectionTitle(String s) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
  child: _text(s.toUpperCase(), size: 9, color: _accent),
);

/// Una riga "etichetta ........ valore".
pw.Widget _row(String label, String value, {bool strong = false}) => pw.Container(
  padding: const pw.EdgeInsets.symmetric(vertical: 3),
  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.5))),
  child: pw.Row(
    children: [
      pw.Expanded(child: _text(label, color: strong ? _ink : _muted, size: strong ? 12 : 10.5)),
      _text(value, size: strong ? 12 : 10.5),
    ],
  ),
);

// ── Copertina ────────────────────────────────────────────────────────────────

List<pw.Widget> _cover(L l, YearStats s, List<YearReportRoll> rolls, CivilDate today, String? topCamera) {
  final perFrame = s.estimatedCentsPerFrame;
  return [
    pw.SizedBox(height: 40),
    _text(l.report_coverTitle, size: 16, color: _muted),
    _text(s.year.toString(), size: 72, color: _accent),
    pw.SizedBox(height: 8),
    _text(
      '${l.stats_rollsCount(s.rollCount)} · ${l.roll_framesCount(s.potentialFrames)}',
      size: 14,
    ),
    _text(l.report_generated(formatDay(l, today)), size: 9, color: _muted),
    _sectionTitle(l.stats_spending),
    if (s.totalCents == 0)
      _text(l.stats_noCosts, color: _muted)
    else ...[
      _row(l.stats_film, formatCents(l, s.filmCents)),
      _row(l.stats_development, formatCents(l, s.developmentCents)),
      _row(l.stats_scans, formatCents(l, s.scanCents)),
      _row(l.stats_prints, formatCents(l, s.printCents)),
      _row(l.stats_total, formatCents(l, s.totalCents), strong: true),
    ],
    if (s.averageCentsPerRoll != null) ...[
      _sectionTitle(l.stats_averages),
      _row(l.stats_perRoll, formatCents(l, s.averageCentsPerRoll!)),
      if (perFrame != null) _row(l.stats_perFrame, l.stats_perFrameValue(formatCents(l, perFrame.round()))),
      // ☠ F6.10: e' una stima, e il PDF lo dice come la pagina.
      pw.Padding(padding: const pw.EdgeInsets.only(top: 4), child: _text(l.stats_perFrameHint, size: 8.5, color: _muted)),
    ],
    _sectionTitle(l.stats_mostUsed),
    _row(l.stats_topEmulsion, _ranked(l, s.topEmulsion?.name, s.topEmulsion?.count, rolls: true)),
    _row(l.stats_topCamera, _ranked(l, topCamera, s.topCameraRolls, rolls: true)),
    _row(l.stats_topLab, _ranked(l, s.topLaboratory?.name, s.topLaboratory?.count, rolls: false)),
    if (rolls.isNotEmpty) ...[
      _sectionTitle(l.report_rollsIndex),
      for (final r in rolls)
        _row(
          '#${r.item.roll.sequenceNumber}  ${r.item.roll.title ?? r.item.roll.filmName}',
          formatPeriod(l, r.item.roll.loadedDate, r.item.roll.finishedDate) ?? '',
        ),
    ],
  ];
}

/// "Kodak Portra 400 · 4 rullini"; "Nessuno, per ora" se manca.
String _ranked(L l, String? name, int? count, {required bool rolls}) {
  if (name == null || count == null || count == 0) return l.stats_noneYet;
  return '$name · ${rolls ? l.stats_rollsCount(count) : l.stats_timesCount(count)}';
}

// ── Pagina del rullino ───────────────────────────────────────────────────────

List<pw.Widget> _rollPage(L l, RollListItem item, List<pw.ImageProvider?> images) {
  final r = item.roll;
  final d = item.development;
  final iso = r.isPushPull ? 'ISO ${r.nominalIso} → ${r.exposedIso}' : 'ISO ${r.nominalIso}';
  final subtitle = [
    if (r.title != null) r.filmName,
    _formatLabel(l, r),
    iso,
    l.roll_framesCount(r.frames),
    ?item.camera?.displayName,
  ].join(' · ');

  String day(CivilDate? date) => date == null ? l.roll_eventNotYet : formatDay(l, date);

  final costs = <(String, int)>[
    if (r.costCents != null) (l.stats_film, r.costCents!),
    if (d?.developmentCostCents != null) (l.stats_development, d!.developmentCostCents!),
    if (d?.scanCostCents != null) (l.stats_scans, d!.scanCostCents!),
    for (final p in item.prints)
      if (p.costCents != null) ('${l.stats_prints}${p.laboratory == null ? '' : ' · ${p.laboratory}'}', p.costCents!),
  ];

  return [
    _text(l.roll_detailTitle(r.sequenceNumber), size: 11, color: _accent),
    _text(r.title ?? r.filmName, size: 22),
    pw.SizedBox(height: 2),
    _text(subtitle, color: _muted),
    if (r.note != null && r.note!.trim().isNotEmpty)
      pw.Padding(padding: const pw.EdgeInsets.only(top: 6), child: _text(r.note!, size: 9.5, color: _muted)),

    _sectionTitle(l.roll_timeline),
    _row(l.roll_eventLoaded, day(r.loadedDate)),
    _row(l.roll_eventFinished, day(r.finishedDate)),
    if (d != null && d.selfDeveloped)
      _row(l.roll_eventSelfDeveloped, day(d.returnedDate ?? d.submittedDate))
    else ...[
      _row(
        '${l.roll_eventDelivered}${d?.laboratory == null ? '' : ' · ${d!.laboratory}'}',
        day(d?.submittedDate),
      ),
      _row(l.roll_eventDeveloped, day(d?.returnedDate)),
    ],
    for (final p in item.prints) ...[
      _row('${l.roll_eventPrintOrdered}${p.laboratory == null ? '' : ' · ${p.laboratory}'}', day(p.submittedDate)),
      _row(
        '${l.roll_eventPrintBack}${p.numberOfPrints == null ? '' : ' · ${l.roll_printsCount(p.numberOfPrints!)}'}',
        day(p.returnedDate),
      ),
    ],

    _sectionTitle(l.report_costs),
    if (costs.isEmpty)
      _text(l.report_noCosts, color: _muted)
    else ...[
      for (final (label, cents) in costs) _row(label, formatCents(l, cents)),
      _row(l.stats_total, formatCents(l, costs.fold<int>(0, (s, c) => s + c.$2)), strong: true),
    ],

    _sectionTitle(l.report_photos),
    if (images.isEmpty) _text(l.report_noPhotos, color: _muted) else ..._grid(images),
  ];
}

String _formatLabel(L l, FilmRoll r) {
  final f = FilmFormat.byKey(r.format);
  return f == null ? r.format : formatName(l, f);
}

/// La griglia delle foto, **una riga di tre alla volta**: ogni riga e' un figlio del
/// MultiPage, cosi' il salto pagina cade fra due righe e non taglia una foto a meta'.
List<pw.Widget> _grid(List<pw.ImageProvider?> images) {
  const columns = 3;
  const gap = 8.0;
  const height = 120.0;
  return [
    for (var start = 0; start < images.length; start += columns)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: gap),
        child: pw.Row(
          children: [
            for (var c = 0; c < columns; c++) ...[
              if (c > 0) pw.SizedBox(width: gap),
              pw.Expanded(
                child: pw.Container(
                  height: height,
                  color: start + c < images.length ? _cell : null,
                  alignment: pw.Alignment.center,
                  child: start + c < images.length && images[start + c] != null
                      ? pw.Image(images[start + c]!, fit: pw.BoxFit.contain)
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
  ];
}

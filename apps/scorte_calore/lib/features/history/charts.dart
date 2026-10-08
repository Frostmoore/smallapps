import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:micro_core/micro_core.dart';

import '../../app/formats.dart';
import '../../app/scorte_palette.dart';
import '../../domain/consumption.dart';
import '../../domain/fuel_source.dart';

/// I due grafici dello storico (develop_microapps.md F5.9, Pro): la scorta nel tempo con i
/// rifornimenti marcati, e il consumo medio giornaliero di ogni intervallo.
///
/// ⚑ **Disegnati a mano con `CustomPainter`, niente `fl_chart`** (il piano lo chiedeva;
/// decisione del 2026-10-08): due grafici semplici non valgono un pacchetto in piu' da
/// compilare e tenere aggiornato su Android e iOS. Stessa scelta delle statistiche di Full
/// Freezer (`apps/full_freezer/lib/features/history/stats_page.dart`).
///
/// ⚑ **Lo stesso asse del tempo per i due grafici**: tutti e due vanno dalla prima
/// all'ultima misurazione, con lo stesso margine sinistro ([chartLeftGutter]); cosi' la barra
/// del consumo di gennaio sta esattamente sotto il tratto di gennaio della scorta, e si legge
/// "qui scendeva in fretta perche' consumavo di piu'" senza cercare.

/// Il margine sinistro dei due grafici, dove stanno i numeri dell'asse verticale. Fisso e
/// uguale per tutti e due: vedi sopra. L'unita' non sta qui (non ci entrerebbe "quintali"):
/// la scrive il titolo del grafico.
const double chartLeftGutter = 40;

/// Il margine in basso, per le date della prima e dell'ultima misura.
const double _bottomGutter = 20;
const double _topGutter = 8;
const double _rightGutter = 8;

/// Le date in cui la scorta e' **salita** rispetto alla misura precedente: i rifornimenti
/// marcati sul grafico. [sorted] deve venire da `ConsumptionCalculator.normalize`.
///
/// ⚑ Dalle misure e non dagli acquisti: un rifornimento e' visibile anche a chi gli acquisti
/// non li registra, ed e' la stessa definizione con cui `buildIntervals` scarta i tratti in
/// salita (un rifornimento non e' consumo).
List<CivilDate> refillDates(List<Measurement> sorted) => [
  for (var i = 1; i < sorted.length; i++)
    if (sorted[i].quantity > sorted[i - 1].quantity) sorted[i].date,
];

/// Il primo valore "tondo" (1, 2, 2,5, 5 per una potenza di 10) >= [v]: il tetto dell'asse
/// verticale. Con [v] <= 0 restituisce 1, perche' un asse alto zero divide per zero.
double niceCeiling(double v) {
  if (v <= 0 || v.isNaN || v.isInfinite) return 1;
  final exp = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    // La tolleranza evita che 5 diventi 10 per un errore di arrotondamento di `log`.
    if (m * exp >= v - 1e-9) return m * exp;
  }
  return 10 * exp;
}

/// La scorta nel tempo: una linea per le misure, l'area sotto in arancio tenue, i
/// rifornimenti come cerchi blu notte (e il tratto in salita tratteggiato, perche' non e'
/// consumo e non si sa quando sia arrivata la consegna).
class StockChart extends StatelessWidget {
  const StockChart({required this.measurements, this.height = 180, super.key});

  /// Le misure da disegnare, in qualunque ordine; servono almeno due date diverse.
  final List<Measurement> measurements;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = ScortePalette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final sorted = const ConsumptionCalculator().normalize(measurements);
    final top = niceCeiling(sorted.fold<double>(0, (m, e) => math.max(m, e.quantity)));
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _StockPainter(
          points: sorted,
          refills: refillDates(sorted).toSet(),
          ceiling: top,
          yLabels: [formatQuantity(0, locale), formatQuantity(top / 2, locale), formatQuantity(top, locale)],
          xLabels: _edgeDates(sorted.map((m) => m.date), locale),
          line: p.ember,
          fill: p.ember.withValues(alpha: 0.14),
          refill: p.night,
          ring: p.card,
          grid: p.inkMuted.withValues(alpha: 0.18),
          text: p.inkMuted,
        ),
      ),
    );
  }
}

/// Il consumo medio giornaliero di ogni intervallo fra due misure: una barra larga quanto
/// l'intervallo, alta quanto il suo consumo al giorno. In tratteggio la stima attuale.
///
/// ⚑ Larga quanto l'intervallo e non una barra uguale per tutti: un intervallo di venti
/// giorni pesa venti volte uno di un giorno nella stima (media ponderata, F5.3), e il grafico
/// deve far vedere la stessa cosa.
class RateChart extends StatelessWidget {
  const RateChart({
    required this.intervals,
    required this.firstDay,
    required this.lastDay,
    this.estimateRate,
    this.height = 140,
    super.key,
  });

  final List<ConsumptionInterval> intervals;

  /// Gli estremi dell'asse del tempo: la prima e l'ultima misura, come in [StockChart].
  final CivilDate firstDay;
  final CivilDate lastDay;

  /// La velocita' della stima attuale (unita' al giorno), disegnata come riferimento.
  final double? estimateRate;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = ScortePalette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final peak = intervals.fold<double>(estimateRate ?? 0, (m, i) => math.max(m, i.rate));
    final top = niceCeiling(peak);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _RatePainter(
          intervals: intervals,
          firstDay: firstDay.epochDay,
          lastDay: lastDay.epochDay,
          ceiling: top,
          estimate: estimateRate,
          yLabels: [formatQuantity(0, locale), formatQuantity(top / 2, locale), formatQuantity(top, locale)],
          xLabels: _edgeDates([firstDay, lastDay], locale),
          bar: p.ember,
          estimateColor: p.night,
          grid: p.inkMuted.withValues(alpha: 0.18),
          text: p.inkMuted,
        ),
      ),
    );
  }
}

/// "3 ott" e "8 gen": la prima e l'ultima data, sotto l'asse.
(String, String) _edgeDates(Iterable<CivilDate> dates, String locale) {
  final list = dates.toList();
  if (list.isEmpty) return ('', '');
  final f = DateFormat.MMMd(locale);
  return (f.format(list.first.toLocalMidnight()), f.format(list.last.toLocalMidnight()));
}

/// Lo spazio del disegno e le conversioni data -> x e valore -> y, comuni ai due grafici.
class _Frame {
  _Frame(Size size, {required this.firstDay, required this.lastDay, required this.ceiling})
    : plot = Rect.fromLTRB(chartLeftGutter, _topGutter, size.width - _rightGutter, size.height - _bottomGutter);

  final Rect plot;
  final int firstDay;
  final int lastDay;
  final double ceiling;

  double x(int epochDay) {
    final span = lastDay - firstDay;
    // Un giorno solo: tutto al centro invece di una divisione per zero.
    if (span <= 0) return plot.center.dx;
    return plot.left + plot.width * (epochDay - firstDay) / span;
  }

  double y(double value) => plot.bottom - plot.height * (value / ceiling).clamp(0.0, 1.0);

  /// Le tre righe orizzontali (0, meta', tetto) con i loro numeri, e le due date in basso.
  void paintAxes(Canvas canvas, List<String> yLabels, (String, String) xLabels, Color grid, Color text) {
    final line = Paint()
      ..color = grid
      ..strokeWidth = 1;
    final style = TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w600);
    for (var i = 0; i < yLabels.length; i++) {
      final v = ceiling * i / (yLabels.length - 1);
      final yy = y(v);
      canvas.drawLine(Offset(plot.left, yy), Offset(plot.right, yy), line);
      _text(canvas, yLabels[i], style, Offset(plot.left - 6, yy), _Anchor.rightMiddle);
    }
    _text(canvas, xLabels.$1, style, Offset(plot.left, plot.bottom + 4), _Anchor.leftTop);
    _text(canvas, xLabels.$2, style, Offset(plot.right, plot.bottom + 4), _Anchor.rightTop);
  }
}

enum _Anchor { rightMiddle, leftTop, rightTop }

void _text(Canvas canvas, String s, TextStyle style, Offset at, _Anchor anchor) {
  if (s.isEmpty) return;
  final tp = TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final o = switch (anchor) {
    _Anchor.rightMiddle => Offset(at.dx - tp.width, at.dy - tp.height / 2),
    _Anchor.leftTop => at,
    _Anchor.rightTop => Offset(at.dx - tp.width, at.dy),
  };
  tp.paint(canvas, o);
  tp.dispose();
}

/// Una linea tratteggiata da [a] a [b].
void _dashed(Canvas canvas, Offset a, Offset b, Paint paint, {double dash = 5, double gap = 4}) {
  final total = (b - a).distance;
  if (total == 0) return;
  final dir = (b - a) / total;
  for (var d = 0.0; d < total; d += dash + gap) {
    canvas.drawLine(a + dir * d, a + dir * math.min(d + dash, total), paint);
  }
}

class _StockPainter extends CustomPainter {
  _StockPainter({
    required this.points,
    required this.refills,
    required this.ceiling,
    required this.yLabels,
    required this.xLabels,
    required this.line,
    required this.fill,
    required this.refill,
    required this.ring,
    required this.grid,
    required this.text,
  });

  final List<Measurement> points;
  final Set<CivilDate> refills;
  final double ceiling;
  final List<String> yLabels;
  final (String, String) xLabels;
  final Color line;
  final Color fill;
  final Color refill;
  final Color ring;
  final Color grid;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final f = _Frame(size, firstDay: points.first.date.epochDay, lastDay: points.last.date.epochDay, ceiling: ceiling);
    f.paintAxes(canvas, yLabels, xLabels, grid, text);

    final offsets = [for (final m in points) Offset(f.x(m.date.epochDay), f.y(m.quantity))];

    // L'area sotto la linea.
    final area = Path()..moveTo(offsets.first.dx, f.plot.bottom);
    for (final o in offsets) {
      area.lineTo(o.dx, o.dy);
    }
    area
      ..lineTo(offsets.last.dx, f.plot.bottom)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);

    // La linea: piena dove si consuma, tratteggiata dove sale (la consegna).
    final stroke = Paint()
      ..color = line
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < offsets.length; i++) {
      if (refills.contains(points[i].date)) {
        _dashed(canvas, offsets[i - 1], offsets[i], stroke..color = refill);
        stroke.color = line;
      } else {
        canvas.drawLine(offsets[i - 1], offsets[i], stroke);
      }
    }

    // I punti: piccoli per le misure, grandi e blu notte per i rifornimenti.
    for (var i = 0; i < points.length; i++) {
      final isRefill = refills.contains(points[i].date);
      final r = isRefill ? 6.0 : 3.5;
      canvas
        ..drawCircle(offsets[i], r + 2, Paint()..color = ring)
        ..drawCircle(offsets[i], r, Paint()..color = isRefill ? refill : line);
    }
  }

  @override
  bool shouldRepaint(_StockPainter old) =>
      old.points != points || old.ceiling != ceiling || old.line != line || old.ring != ring || old.yLabels != yLabels;
}

class _RatePainter extends CustomPainter {
  _RatePainter({
    required this.intervals,
    required this.firstDay,
    required this.lastDay,
    required this.ceiling,
    required this.estimate,
    required this.yLabels,
    required this.xLabels,
    required this.bar,
    required this.estimateColor,
    required this.grid,
    required this.text,
  });

  final List<ConsumptionInterval> intervals;
  final int firstDay;
  final int lastDay;
  final double ceiling;
  final double? estimate;
  final List<String> yLabels;
  final (String, String) xLabels;
  final Color bar;
  final Color estimateColor;
  final Color grid;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    final f = _Frame(size, firstDay: firstDay, lastDay: lastDay, ceiling: ceiling);
    f.paintAxes(canvas, yLabels, xLabels, grid, text);

    final paint = Paint()..color = bar;
    for (final i in intervals) {
      // Un pixel di stacco fra due barre vicine; almeno 2 px di larghezza per gli intervalli
      // di un giorno su una stagione intera, altrimenti sparirebbero.
      final left = f.x(i.from.epochDay) + 0.5;
      final right = math.max(left + 2, f.x(i.to.epochDay) - 0.5);
      // Anche zero consumo si vede come un trattino: la stufa spenta e' un dato (come in
      // Full Freezer), non un buco nel grafico.
      final top = math.min(f.y(i.rate), f.plot.bottom - 2);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(left, top, right, f.plot.bottom),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        paint,
      );
    }

    final e = estimate;
    if (e != null && e > 0) {
      final yy = f.y(e);
      _dashed(
        canvas,
        Offset(f.plot.left, yy),
        Offset(f.plot.right, yy),
        Paint()
          ..color = estimateColor
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_RatePainter old) =>
      old.intervals != intervals ||
      old.estimate != estimate ||
      old.ceiling != ceiling ||
      old.firstDay != firstDay ||
      old.lastDay != lastDay ||
      old.bar != bar;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Le icone delle categorie, **disegnate** (decisione del 2026-10-07).
///
/// ☠ Erano icone di Material, e la carne era rappresentata da spiedini perche' Material non
/// ha una bistecca: il proprietario l'ha notato al primo giro. Disegnarle tutte qui le rende
/// coerenti fra loro (stesso tratto, stessi raccordi) e indipendenti da quello che una
/// libreria di icone offre o smette di offrire.
///
/// Si disegnano su una griglia 24x24, tratto 2 con estremi arrotondati, come le icone
/// "outlined" che stanno loro accanto.
class CategoryGlyph extends StatelessWidget {
  const CategoryGlyph({required this.iconKey, this.size = 22, this.color, super.key});

  /// `ItemCategory.iconKey` (`meat`, `poultry`, `fish`, `vegetables`, `fruit`, `bread`,
  /// `prepared`, `ice_cream`, `other`); qualunque altra chiave disegna `other`.
  final String? iconKey;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GlyphPainter(iconKey ?? 'other', c)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.key, this.color);

  final String key;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.scale(k);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (key) {
      case 'meat':
        // Bistecca: la sagoma del taglio, il bordo di grasso che ne segue il lato alto, una
        // venatura e l'occhio dell'osso. (Prima un ovale con un cerchio, poi una T-bone che
        // sembrava la lettera T: nessuna delle due si leggeva come carne.)
        final steak = Path()
          ..moveTo(4.5, 7)
          ..cubicTo(8.5, 3, 17.5, 2.5, 20.5, 7.5)
          ..cubicTo(22.5, 11, 21, 15, 17.5, 16.5)
          ..cubicTo(14, 18, 13, 21.5, 8.5, 20.5)
          ..cubicTo(3.5, 19.5, 2, 12, 4.5, 7)
          ..close();
        canvas.drawPath(steak, p);
        canvas.drawPath(Path()..moveTo(7, 8)..cubicTo(10, 5.5, 16, 5.3, 18.3, 8.5), p);
        canvas.drawCircle(const Offset(9, 15), 1.8, p);
        canvas.drawPath(Path()..moveTo(13, 11.5)..cubicTo(14.5, 11, 16, 11.5, 17, 12.5), p);
      case 'poultry':
        // Coscia di pollo: la polpa a goccia e un osso CON SPESSORE (un rettangolo arrotondato
        // e due nocche). Con l'osso di una linea sola sembrava un lecca-lecca o una chiave.
        final leg = Path()
          ..moveTo(13.4, 13.4)
          ..cubicTo(9, 16.8, 1.8, 13.2, 2.5, 7.5)
          ..cubicTo(3.2, 2, 11, 0.8, 14.8, 4.6)
          ..cubicTo(17.8, 7.6, 17, 11.6, 13.4, 13.4)
          ..close();
        canvas.drawPath(leg, p);
        canvas.save();
        canvas.translate(16, 16);
        canvas.rotate(math.pi / 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 5.5, height: 3), const Radius.circular(1.5)),
          p,
        );
        canvas.restore();
        canvas.drawCircle(const Offset(19.6, 17.4), 1.7, p);
        canvas.drawCircle(const Offset(17.4, 19.6), 1.7, p);
      case 'fish':
        final body = Path()
          ..moveTo(3, 12)
          ..cubicTo(6, 6.5, 13, 5.5, 17, 12)
          ..cubicTo(13, 18.5, 6, 17.5, 3, 12)
          ..close();
        canvas.drawPath(body, p);
        canvas.drawPath(Path()..moveTo(17, 12)..lineTo(21.5, 8)..lineTo(21.5, 16)..close(), p);
        canvas.drawCircle(const Offset(7.5, 11), 0.6, p..style = PaintingStyle.fill);
      case 'vegetables':
        // Carota con il ciuffo, abbastanza larga da leggersi a 22 px.
        final carrot = Path()
          ..moveTo(17, 9)
          ..cubicTo(15, 13, 9.5, 18.5, 4.5, 20.5)
          ..cubicTo(5.5, 15.5, 10, 9.5, 13.5, 7)
          ..cubicTo(15, 6, 16.5, 7, 17, 9)
          ..close();
        canvas.drawPath(carrot, p);
        canvas.drawLine(const Offset(16, 7), const Offset(20, 3), p);
        canvas.drawLine(const Offset(16.5, 7.5), const Offset(21, 7.5), p);
        canvas.drawLine(const Offset(15.5, 6.5), const Offset(15.5, 2.5), p);
        canvas.drawLine(const Offset(8.5, 15), const Offset(10.5, 16.5), p);
        canvas.drawLine(const Offset(11, 11.5), const Offset(13, 13), p);
      case 'fruit':
        // Fragola: il corpo a cuore, la corona di foglie e i semi.
        final berry = Path()
          ..moveTo(12, 21)
          ..cubicTo(6, 17, 3.5, 12, 6, 8.5)
          ..cubicTo(8, 6.5, 10.5, 7.5, 12, 8.5)
          ..cubicTo(13.5, 7.5, 16, 6.5, 18, 8.5)
          ..cubicTo(20.5, 12, 18, 17, 12, 21)
          ..close();
        canvas.drawPath(berry, p);
        canvas.drawPath(Path()..moveTo(9, 6)..lineTo(12, 8.5)..lineTo(15, 6), p);
        canvas.drawLine(const Offset(12, 8.5), const Offset(12, 3.5), p);
        final seme = Paint()..color = color;
        for (final o in const [Offset(9.5, 12), Offset(14.5, 12), Offset(12, 15), Offset(10, 16.5), Offset(14, 16.5)]) {
          canvas.drawCircle(o, 0.7, seme);
        }
      case 'bread':
        // Pagnotta con i tagli.
        final loaf = Path()
          ..moveTo(4, 18)
          ..cubicTo(2.5, 11, 6, 6, 12, 6)
          ..cubicTo(18, 6, 21.5, 11, 20, 18)
          ..close();
        canvas.drawPath(loaf, p);
        canvas.drawLine(const Offset(8, 13), const Offset(10, 10), p);
        canvas.drawLine(const Offset(11.5, 13), const Offset(13.5, 10), p);
        canvas.drawLine(const Offset(15, 13), const Offset(17, 10), p);
      case 'prepared':
        // Vaschetta con coperchio: gli avanzi e i piatti pronti.
        canvas.drawRRect(RRect.fromLTRBR(4, 10, 20, 19, const Radius.circular(2.5)), p);
        canvas.drawRRect(RRect.fromLTRBR(3, 7, 21, 10, const Radius.circular(1.5)), p);
        canvas.drawLine(const Offset(10, 7), const Offset(10.5, 5), p);
        canvas.drawLine(const Offset(14, 7), const Offset(13.5, 5), p);
      case 'ice_cream':
        canvas.drawPath(Path()..moveTo(7, 11)..lineTo(12, 21.5)..lineTo(17, 11), p);
        canvas.drawArc(const Rect.fromLTRB(7, 3, 17, 13), math.pi, math.pi, false, p);
        canvas.drawLine(const Offset(7, 11), const Offset(17, 11), p);
        canvas.drawLine(const Offset(9.5, 13.5), const Offset(14, 17.5), p);
      default:
        // Scatola: "altro".
        canvas.drawRRect(RRect.fromLTRBR(4, 8, 20, 20, const Radius.circular(2)), p);
        canvas.drawPath(Path()..moveTo(3, 8)..lineTo(6, 4)..lineTo(18, 4)..lineTo(21, 8), p);
        canvas.drawLine(const Offset(10, 12), const Offset(14, 12), p);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.key != key || old.color != color;
}

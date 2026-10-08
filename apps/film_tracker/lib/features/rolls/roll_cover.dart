import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../photos/image_store_provider.dart';

/// La copertina di un rullino: la miniatura dell'immagine scelta come copertina, oppure la
/// striscia di pellicola disegnata in codice.
///
/// ⚑ Il file lo disegna `RollImageThumb` delle foto (F6.9): percorso **relativo** risolto con
/// `AppPaths` a ogni disegno, decodifica alla dimensione mostrata, file sparito che torna al
/// segnaposto invece di un errore. Qui si sceglie solo il segnaposto. `appPathsProvider` si
/// legge solo se c'e' una copertina: la home senza foto si prova nei test senza cartelle vere.
class RollCover extends StatelessWidget {
  const RollCover({required this.cover, this.edgeLabel, super.key});

  /// L'immagine di copertina (`RollListItem.cover`); null per il segnaposto.
  final RollImage? cover;

  /// La scritta sul bordo della striscia, quando non c'e' la foto ("KODAK PORTRA 400 · 17").
  final String? edgeLabel;

  @override
  Widget build(BuildContext context) => RollImageThumb(
    image: cover,
    placeholder: FilmStripPlaceholder(edgeLabel: edgeLabel),
  );
}

/// Il segnaposto di un rullino senza foto: una striscia di negativo con le perforazioni, i
/// fotogrammi e la scritta sul bordo.
///
/// ⚑ **Disegnato e non un rettangolo grigio** (F6.8): l'archivio e' la sezione che da'
/// identita' all'app, e un rullino senza foto deve sembrare comunque un rullino. Disegnato in
/// codice e non un'immagine negli asset: si adatta a qualunque proporzione e ai colori del
/// tema, senza pesare sull'app.
class FilmStripPlaceholder extends StatelessWidget {
  const FilmStripPlaceholder({this.edgeLabel, super.key});

  final String? edgeLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _FilmStripPainter(
        base: Color.alphaBlend(scheme.primary.withValues(alpha: 0.10), const Color(0xFF17130E)),
        hole: Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.06), const Color(0xFF07060A)),
        frame: scheme.primary.withValues(alpha: 0.16),
        frameBorder: scheme.primary.withValues(alpha: 0.35),
        edgeText: scheme.primary.withValues(alpha: 0.75),
        edgeLabel: edgeLabel,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _FilmStripPainter extends CustomPainter {
  _FilmStripPainter({
    required this.base,
    required this.hole,
    required this.frame,
    required this.frameBorder,
    required this.edgeText,
    this.edgeLabel,
  });

  final Color base;
  final Color hole;
  final Color frame;
  final Color frameBorder;
  final Color edgeText;
  final String? edgeLabel;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    // Le bande con le perforazioni, in alto e in basso: un ottavo dell'altezza ciascuna.
    final band = (size.height / 8).clamp(8.0, 22.0);
    final holeH = band * 0.48;
    final holeW = holeH * 1.35;
    final step = holeW * 2;
    final holePaint = Paint()..color = hole;
    for (var x = step / 4; x < size.width; x += step) {
      for (final y in [(band - holeH) / 2, size.height - band + (band - holeH) / 2]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, holeW, holeH), Radius.circular(holeH / 4)),
          holePaint,
        );
      }
    }

    // I fotogrammi, nello spazio fra le bande: proporzione 3:2 come il 35 mm.
    final top = band + 3;
    final frameH = size.height - 2 * band - 6;
    if (frameH > 8) {
      final frameW = frameH * 1.5;
      final gap = frameH * 0.12;
      final fill = Paint()..color = frame;
      final border = Paint()
        ..color = frameBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (var x = gap - frameW * 0.35; x < size.width; x += frameW + gap) {
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, frameW, frameH),
          const Radius.circular(3),
        );
        canvas
          ..drawRRect(r, fill)
          ..drawRRect(r, border);
      }
    }

    // La scritta sul bordo, come quella stampata dal fabbricante fra le perforazioni.
    final label = edgeLabel;
    if (label != null && label.isNotEmpty && band >= 10) {
      final tp = TextPainter(
        text: TextSpan(
          text: label.toUpperCase(),
          style: TextStyle(
            color: edgeText,
            fontSize: band * 0.42,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: size.width - 16);
      final y = size.height - band - tp.height - 2;
      if (y > band) {
        // Una fascia del colore di fondo dietro la scritta, per staccarla dai fotogrammi.
        canvas.drawRect(
          Rect.fromLTWH(6, y - 1, tp.width + 4, tp.height + 2),
          Paint()..color = base.withValues(alpha: 0.85),
        );
        tp.paint(canvas, Offset(8, y));
      }
    }
  }

  @override
  bool shouldRepaint(_FilmStripPainter old) =>
      old.base != base ||
      old.hole != hole ||
      old.frame != frame ||
      old.frameBorder != frameBorder ||
      old.edgeText != edgeText ||
      old.edgeLabel != edgeLabel;
}

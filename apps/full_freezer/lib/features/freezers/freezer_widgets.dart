import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

import '../../domain/capacity.dart';
import '../../l10n/generated/app_localizations.dart';

/// Il disegno stilizzato di un modello di freezer (F4.3b: "una griglia di carte [...]
/// ciascuna con disegno, nome e litri").
///
/// ⚑ Disegnato e non un'icona: le icone di Material hanno un frigorifero solo, e la scelta
/// del modello si fa proprio guardando la forma (pozzetto basso e largo, verticale alto,
/// cassetti sotto il frigo). Il vano congelatore e' colorato, il resto dell'apparecchio no.
class FreezerSilhouette extends StatelessWidget {
  const FreezerSilhouette({required this.iconKey, this.size = 56, super.key});

  /// `FreezerModel.iconKey`, oppure `custom`.
  final String iconKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SilhouettePainter(
          iconKey: iconKey,
          body: scheme.outline,
          freezer: scheme.primary,
          freezerFill: scheme.primaryContainer,
        ),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter({
    required this.iconKey,
    required this.body,
    required this.freezer,
    required this.freezerFill,
  });

  final String iconKey;
  final Color body;
  final Color freezer;
  final Color freezerFill;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.045;
    final linea = Paint()
      ..color = body
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round;
    final vano = Paint()..color = freezerFill;
    final bordoVano = Paint()
      ..color = freezer
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Rettangolo dell'apparecchio, centrato, con le proporzioni del modello.
    Rect corpo(double w, double h) => Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: s * w,
      height: s * h,
    );
    RRect r(Rect rect) => RRect.fromRectAndRadius(rect, Radius.circular(s * 0.06));
    void zona(Rect rect) {
      canvas.drawRRect(r(rect), vano);
      canvas.drawRRect(r(rect), bordoVano);
    }

    void cassetti(Rect rect, int n) {
      for (var i = 1; i < n; i++) {
        final y = rect.top + rect.height * i / n;
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), bordoVano);
      }
    }

    switch (iconKey) {
      case 'ice_box':
        final c = corpo(0.5, 0.9);
        canvas.drawRRect(r(c), linea);
        zona(Rect.fromLTWH(c.left + c.width * 0.12, c.top + c.height * 0.08, c.width * 0.76, c.height * 0.2));
      case 'fridge_top':
        final c = corpo(0.5, 0.9);
        zona(Rect.fromLTWH(c.left, c.top, c.width, c.height * 0.3));
        canvas.drawRRect(r(Rect.fromLTWH(c.left, c.top + c.height * 0.3, c.width, c.height * 0.7)), linea);
      case 'combi':
        final c = corpo(0.5, 0.9);
        canvas.drawRRect(r(Rect.fromLTWH(c.left, c.top, c.width, c.height * 0.6)), linea);
        final z = Rect.fromLTWH(c.left, c.top + c.height * 0.6, c.width, c.height * 0.4);
        zona(z);
        cassetti(z, 3);
      case 'undercounter':
        final c = corpo(0.62, 0.62);
        zona(c);
        cassetti(c, 3);
      case 'chest':
        final c = corpo(0.92, 0.5);
        zona(c);
        final y = c.top + c.height * 0.22;
        canvas.drawLine(Offset(c.left, y), Offset(c.right, y), bordoVano);
      case 'side_by_side':
        final c = corpo(0.82, 0.9);
        final z = Rect.fromLTWH(c.left, c.top, c.width * 0.45, c.height);
        zona(z);
        canvas.drawRRect(r(Rect.fromLTWH(c.left + c.width * 0.45, c.top, c.width * 0.55, c.height)), linea);
      case 'upright':
        final c = corpo(0.5, 0.92);
        zona(c);
        cassetti(c, 5);
      default:
        // `custom`: un riquadro tratteggiato con il segno dei litri scritti a mano.
        final c = corpo(0.62, 0.62);
        canvas.drawRRect(r(c), bordoVano);
        final tp = TextPainter(
          text: TextSpan(
            text: 'L',
            style: TextStyle(color: freezer, fontSize: s * 0.32, fontWeight: FontWeight.w700),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, c.center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) =>
      old.iconKey != iconKey || old.body != body || old.freezer != freezer;
}

/// La barra di riempimento (F4.3b): verde fino al 70%, ambra fino all'85%, rossa oltre.
class FillBar extends StatelessWidget {
  const FillBar({required this.fill, this.height = 10, this.showLabel = true, super.key});

  final FillInfo fill;
  final double height;
  final bool showLabel;

  /// Il colore della barra per una frazione. Pubblico per i test.
  ///
  /// I colori vengono dalle estensioni di `MicroColorScheme`, che si adattano al tema scuro.
  static Color colorFor(double fraction, ColorScheme scheme) {
    if (fraction >= 0.85) return scheme.danger;
    if (fraction >= 0.70) return scheme.warning;
    return scheme.success;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = L.of(context);
    final value = fill.fraction.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: l.fill_semantics(fill.percent),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: LinearProgressIndicator(
              value: value,
              minHeight: height,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(colorFor(fill.fraction, scheme)),
            ),
          ),
        ),
        if (showLabel) ...[
          MicroSpacing.gapXS,
          Text(
            l.fill_label(fill.percent),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.mutedText),
          ),
        ],
      ],
    );
  }
}

/// L'asticella verticale della testata (interfaccia "Ghiaccio"): si riempie dal basso.
class FillGauge extends StatelessWidget {
  const FillGauge({
    required this.fill,
    required this.track,
    required this.color,
    this.height = 92,
    this.width = 14,
    super.key,
  });

  final FillInfo fill;
  final Color track;
  final Color color;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final value = fill.fraction.clamp(0.0, 1.0);
    // Oltre l'85% l'asticella diventa del colore d'allarme: e' lo stesso confine degli
    // avvisi "quasi pieno" (F4.9).
    final scheme = Theme.of(context).colorScheme;
    final c = fill.fraction >= 0.85 ? scheme.danger : color;
    return Semantics(
      label: l.fill_semantics(fill.percent),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(width / 2)),
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: value == 0 ? 0 : value.clamp(width / height, 1.0),
          child: Container(
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(width / 2)),
          ),
        ),
      ),
    );
  }
}

/// Il nome visibile di un modello di freezer.
String freezerModelName(L l, String key) => switch (key) {
  'ice_box' => l.freezerModel_ice_box,
  'fridge_top' => l.freezerModel_fridge_top,
  'combi_compact' => l.freezerModel_combi_compact,
  'undercounter' => l.freezerModel_undercounter,
  'combi_large' => l.freezerModel_combi_large,
  'chest_small' => l.freezerModel_chest_small,
  'side_by_side' => l.freezerModel_side_by_side,
  'chest_medium' => l.freezerModel_chest_medium,
  'upright_tall' => l.freezerModel_upright_tall,
  'chest_large' => l.freezerModel_chest_large,
  _ => l.freezerModel_custom,
};

/// La silhouette di un modello salvato, anche `custom`.
String silhouetteKeyFor(String modelKey) => FreezerModels.byKey(modelKey)?.iconKey ?? 'custom';

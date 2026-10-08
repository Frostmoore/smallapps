import 'package:flutter/material.dart';

import '../../app/film_palette.dart';

/// I pezzi di pellicola di "C · Provino" (F6.0 punto 6): la fila di perforazioni, la striscia
/// che contiene un rullino, la scritta a bordo, l'etichetta di sezione.
///
/// ⚑ Disegnati con widget e non con un'immagine: si adattano alla larghezza, ai due temi e al
/// carattere ingrandito dell'utente senza sgranarsi.

/// Una fila di perforazioni lungo tutta la larghezza: rettangolini arrotondati del colore del
/// fondo, come i fori della pellicola che lasciano vedere quello che c'e' dietro.
class SprocketRow extends StatelessWidget {
  const SprocketRow({super.key});

  static const double _w = 14;
  static const double _h = 8;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final p = FilmPalette.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        height: _h,
        child: LayoutBuilder(
          builder: (context, c) {
            final n = ((c.maxWidth + _gap) / (_w + _gap)).floor().clamp(1, 60);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < n; i++)
                  Container(
                    width: _w,
                    height: _h,
                    decoration: BoxDecoration(color: p.ground, borderRadius: BorderRadius.circular(2)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Una striscia di pellicola con le perforazioni sopra e sotto e la scritta a bordo
/// ("ILFORD HP5+ 800 ▸ 12") appena sopra la fila in basso.
class FilmStrip extends StatelessWidget {
  const FilmStrip({required this.child, this.edgeText, this.onTap, this.semanticLabel, super.key});

  final Widget child;
  final String? edgeText;
  final VoidCallback? onTap;

  /// Cosa dice il lettore di schermo toccando la striscia; senza, legge il contenuto.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = FilmPalette.of(context);
    final scritta = edgeText;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: p.strip,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SprocketRow()),
                Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: child),
                if (scritta != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: EdgeText(scritta, size: 10),
                  ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SprocketRow()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La scritta a bordo pellicola: Space Mono, maiuscola, arancio.
class EdgeText extends StatelessWidget {
  const EdgeText(this.text, {this.size = 11, this.color, this.bold = false, this.maxLines = 1, super.key});

  final String text;
  final double size;
  final Color? color;
  final bool bold;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    style: FilmPalette.of(context).edgeText(
      size: size,
      color: color,
      weight: bold ? FontWeight.w700 : FontWeight.w400,
    ),
  );
}

/// L'etichetta di una sezione ("IN MACCHINA · 3"), monospaziata e spenta.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.count, super.key});

  final String text;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final p = FilmPalette.of(context);
    return Semantics(
      header: true,
      child: Row(
        children: [
          Expanded(child: EdgeText(text, color: p.inkFaint)),
          if (count != null && count! > 0) EdgeText('$count', color: p.inkFaint),
        ],
      ),
    );
  }
}

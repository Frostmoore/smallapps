import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/labels.dart';
import '../../app/sr_palette.dart';
import '../../domain/statistiche.dart';
import '../../l10n/generated/app_localizations.dart';

/// Il grafico a barre degli ultimi 6 mesi (develop_microapps.md F12.1.12, `StatistichePage`).
///
/// ⚑ `CustomPainter` e non `fl_chart` (F12.1.2: niente dipendenze per sei barre), come Film
/// Tracker e Scorte Calore. ⚑ Il disegno e' muto per i lettori di schermo: la `Semantics` legge i
/// valori mese per mese («ottobre 182,40 euro»), che e' quello che il grafico dice.
class GraficoMesi extends StatelessWidget {
  const GraficoMesi({required this.mesi, this.evidenziato, super.key});

  /// Dal piu' vecchio al piu' recente (`StatisticheSpesa.ultimiMesi`).
  final List<MeseSpesa> mesi;

  /// (anno, mese) della barra in evidenza (il mese scelto).
  final (int, int)? evidenziato;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final nomi = [for (final m in mesi) DateFormat.MMM(locale).format(DateTime(m.anno, m.mese))];
    final lettura = [
      for (final m in mesi) l.grafico_mese(DateFormat.MMMM(locale).format(DateTime(m.anno, m.mese)), importo(m.totale)),
    ].join(', ');
    return Semantics(
      label: l.grafico_titolo(lettura),
      excludeSemantics: true,
      child: SizedBox(
        height: 160,
        child: CustomPaint(
          painter: _Barre(
            valori: [for (final m in mesi) m.totale.cents],
            etichette: nomi,
            evidenziata: [for (final m in mesi) evidenziato == (m.anno, m.mese)],
            colore: p.accento,
            coloreSpento: p.superficieOp,
            testo: p.testoSecondario,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Barre extends CustomPainter {
  _Barre({
    required this.valori,
    required this.etichette,
    required this.evidenziata,
    required this.colore,
    required this.coloreSpento,
    required this.testo,
  });

  final List<int> valori;
  final List<String> etichette;
  final List<bool> evidenziata;
  final Color colore;
  final Color coloreSpento;
  final Color testo;

  @override
  void paint(Canvas canvas, Size size) {
    if (valori.isEmpty) return;
    const fascia = 20.0;
    final alto = size.height - fascia;
    final massimo = math.max(1, valori.reduce(math.max));
    final passo = size.width / valori.length;
    final larghezza = passo * 0.56;
    for (var i = 0; i < valori.length; i++) {
      final h = valori[i] == 0 ? 2.0 : math.max(4.0, alto * valori[i] / massimo);
      final x = passo * i + (passo - larghezza) / 2;
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, alto - h, larghezza, h), const Radius.circular(6));
      canvas.drawRRect(r, Paint()..color = evidenziata[i] ? colore : colore.withValues(alpha: 0.45));
      final tp = TextPainter(
        text: TextSpan(text: etichette[i], style: TextStyle(color: testo, fontSize: 11)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: passo);
      tp.paint(canvas, Offset(passo * i + (passo - tp.width) / 2, alto + 4));
    }
    canvas.drawLine(Offset(0, alto), Offset(size.width, alto), Paint()..color = coloreSpento);
  }

  @override
  bool shouldRepaint(_Barre old) =>
      old.valori != valori || old.evidenziata != evidenziata || old.colore != colore;
}

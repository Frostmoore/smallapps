import 'package:flutter/material.dart';

import '../../app/sr_palette.dart';
import '../../domain/tastierino.dart';
import '../../l10n/generated/app_localizations.dart';

/// Che aspetto ha un tasto: cifra (`superficie`), operazione (`superficieOp`), conferma (`accento`).
enum TipoTasto { cifra, operazione, conferma }

/// Un tasto della griglia 4×4.
@immutable
class TastoGriglia {
  const TastoGriglia({
    required this.etichetta,
    required this.semantica,
    required this.tipo,
    required this.onTap,
    this.onLongPress,
    this.chiave,
    this.icona,
  });

  final String etichetta;

  /// Cosa legge TalkBack/VoiceOver («cancella», «per», «virgola»…).
  final String semantica;
  final TipoTasto tipo;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Key? chiave;

  /// Al posto dell'etichetta (⌫).
  final IconData? icona;
}

/// La griglia 4×4 del tastierino: spaziatura 6, tasti alti 48 e raggio 14, Space Grotesk 20
/// (F12.1.12 punto 6). La usano la spesa (prezzi) e il foglio del peso (grammi): ⚑ stessa griglia
/// perche' il pollice impari un posto solo per ogni tasto.
///
/// ⚑ **I tasti non si rimpiccioliscono mai** (F12.1.12: al 130% si riducono prima la lista e il
/// totale): altezza fissa 48 e testo dentro un `FittedBox`, cosi' a qualunque scala l'etichetta
/// sta nel tasto invece di tagliarsi.
class GrigliaTasti extends StatelessWidget {
  const GrigliaTasti({required this.tasti, super.key}) : assert(tasti.length == 16, '4×4');

  final List<TastoGriglia> tasti;

  static const double altezzaTasto = 48;
  static const double spazio = 6;

  /// L'altezza della griglia intera (4 righe e 3 spazi).
  static const double altezza = altezzaTasto * 4 + spazio * 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var riga = 0; riga < 4; riga++) ...[
          if (riga > 0) const SizedBox(height: spazio),
          Row(
            children: [
              for (var col = 0; col < 4; col++) ...[
                if (col > 0) const SizedBox(width: spazio),
                Expanded(child: _Tasto(tasti[riga * 4 + col])),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Tasto extends StatelessWidget {
  const _Tasto(this.t);

  final TastoGriglia t;

  @override
  Widget build(BuildContext context) {
    final p = SrPalette.of(context);
    final (fondo, testo) = switch (t.tipo) {
      TipoTasto.cifra => (p.superficie, p.testo),
      TipoTasto.operazione => (p.superficieOp, p.testo),
      TipoTasto.conferma => (p.accento, p.suAccento),
    };
    final icona = t.icona;
    return Semantics(
      button: true,
      label: t.semantica,
      excludeSemantics: true,
      child: Material(
        key: t.chiave,
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: t.onTap,
          onLongPress: t.onLongPress,
          child: SizedBox(
            height: GrigliaTasti.altezzaTasto,
            child: Center(
              child: icona != null
                  ? Icon(icona, color: testo, size: 22)
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(t.etichetta, style: p.numeri(size: 20, color: testo)),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// I 16 tasti del tastierino della spesa (F12.1.12 punto 6):
/// ```
/// 7  8  9  ⌫
/// 4  5  6  ×
/// 1  2  3  −
/// 0  00 ,  +
/// ```
/// [onTasto] riceve il tasto; la pressione lunga su ⌫ chiama [onSvuota].
List<TastoGriglia> tastiDellaSpesa(L l, {required ValueChanged<TastoTastierino> onTasto, required VoidCallback onSvuota}) {
  TastoGriglia cifra(TastoTastierino t, String e, [String? sem]) => TastoGriglia(
    etichetta: e,
    semantica: sem ?? e,
    tipo: TipoTasto.cifra,
    onTap: () => onTasto(t),
    chiave: ValueKey('tasto_${t.name}'),
  );
  TastoGriglia op(TastoTastierino t, String e, String sem, {IconData? icona, VoidCallback? lungo}) => TastoGriglia(
    etichetta: e,
    semantica: sem,
    tipo: TipoTasto.operazione,
    onTap: () => onTasto(t),
    onLongPress: lungo,
    chiave: ValueKey('tasto_${t.name}'),
    icona: icona,
  );
  return [
    cifra(TastoTastierino.c7, '7'),
    cifra(TastoTastierino.c8, '8'),
    cifra(TastoTastierino.c9, '9'),
    op(TastoTastierino.cancella, '⌫', l.tasto_cancella, icona: Icons.backspace_outlined, lungo: onSvuota),
    cifra(TastoTastierino.c4, '4'),
    cifra(TastoTastierino.c5, '5'),
    cifra(TastoTastierino.c6, '6'),
    op(TastoTastierino.per, '×', l.tasto_per),
    cifra(TastoTastierino.c1, '1'),
    cifra(TastoTastierino.c2, '2'),
    cifra(TastoTastierino.c3, '3'),
    op(TastoTastierino.meno, '−', l.tasto_meno),
    cifra(TastoTastierino.c0, '0'),
    cifra(TastoTastierino.c00, '00', l.tasto_doppioZero),
    cifra(TastoTastierino.virgola, ',', l.tasto_virgola),
    TastoGriglia(
      etichetta: '+',
      semantica: l.tasto_aggiungi,
      tipo: TipoTasto.conferma,
      onTap: () => onTasto(TastoTastierino.piu),
      chiave: const ValueKey('tasto_piu'),
    ),
  ];
}

/// Il pannello del tastierino: fondo `fondoProfondo`, raggio 22, padding 10; riga «Prezzo a mano»
/// col display a destra (Space Grotesk 24); sotto la griglia.
class PannelloTastierino extends StatelessWidget {
  const PannelloTastierino({required this.etichetta, required this.display, required this.tasti, super.key});

  final String etichetta;
  final String display;
  final List<TastoGriglia> tasti;

  @override
  Widget build(BuildContext context) {
    final p = SrPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: p.fondoProfondo, borderRadius: BorderRadius.circular(22)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
            child: Row(
              children: [
                Text(
                  etichetta,
                  style: TextStyle(
                    fontSize: 13,
                    color: p.testoSecondario,
                    fontWeight: FontWeight.w600,
                    fontVariations: const [FontVariation('wght', 600)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    label: display,
                    excludeSemantics: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      // ⚑ Display vuoto = uno spazio: l'altezza della riga non salta al primo tasto.
                      child: Text(
                        display.isEmpty ? ' ' : display,
                        key: const ValueKey('display_tastierino'),
                        style: p.numeri(size: 24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GrigliaTasti(tasti: tasti),
        ],
      ),
    );
  }
}

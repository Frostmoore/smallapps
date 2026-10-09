import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/qr_palette.dart';
import '../../data/database.dart';

/// I mattoni della grafica «A · Neon» (F17.6), usati da tutte le pagine.
///
/// ⚑ Qui e non in `micro_core`: sono la grafica di QR Me, e le altre app hanno la loro. Il
/// `ThemeData` (`withQrLook`) fa il resto: un `FilledButton` qualunque e' gia' una pillola verde.

/// Il pulsante primario: pillola alta 46, verde, testo 800, con l'alone verde.
///
/// ⚑ L'alone solo quando e' attivo: un pulsante spento che brilla sembra premibile.
class NeonButton extends StatelessWidget {
  const NeonButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final p = QrPalette.of(context);
    final button = FilledButton(
      onPressed: onPressed,
      // ☠ Larghezza minima finita: il tema di micro_core la dava infinita (Size.fromHeight) e un
      // pulsante non espanso in una Row non si disegnava (lezione di Full Freezer).
      style: FilledButton.styleFrom(minimumSize: const Size(64, 46)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), MicroSpacing.hGapS],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    final glowing = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        boxShadow: onPressed == null ? null : [BoxShadow(color: p.glow, blurRadius: 24)],
      ),
      child: button,
    );
    return expanded ? SizedBox(width: double.infinity, child: glowing) : glowing;
  }
}

/// L'etichetta di una sezione in maiuscolo, con un'azione facoltativa a destra («Vedi tutti»).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: MicroSpacing.l, bottom: MicroSpacing.s),
    child: Row(
      children: [
        Expanded(child: Text(text.toUpperCase(), style: QrPalette.of(context).sectionLabel)),
        ?trailing,
      ],
    ),
  );
}

/// Il pannello del QR: sempre il colore di sfondo del codice (bianco per lo stile semplice),
/// raggio 26, con l'alone verde. ⚑ Anche nel tema scuro: il riquadro chiaro e' cio' che la
/// fotocamera cerca, e il nero attorno lo fa risaltare.
class QrPanel extends StatelessWidget {
  const QrPanel({
    required this.background,
    required this.child,
    this.padding = 22,
    this.glow = true,
    super.key,
  });

  final Color background;
  final Widget child;
  final double padding;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final p = QrPalette.of(context);
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(26),
        boxShadow: glow
            ? [
                BoxShadow(color: p.accent.withValues(alpha: 0.35), spreadRadius: 4),
                BoxShadow(color: p.accent.withValues(alpha: 0.35), blurRadius: 60),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// La miniatura di un QR salvato in una riga: il codice vero (senza logo) su un quadrato chiaro
/// 34×34 di raggio 8.
class QrThumb extends ConsumerWidget {
  const QrThumb({required this.code, this.size = 34, super.key});

  final QrCode code;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = code.style;
    final renderer = ref.watch(qrRendererProvider);
    final fits = !renderer.choose(code.payload, style).tooLong;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: size,
        child: fits
            ? renderer.widget(payload: code.payload, style: style, size: size)
            : ColoredBox(color: Color(style.background)),
      ),
    );
  }
}

/// Una riga di elenco (cronologia, preferiti): superficie, raggio 16, miniatura, titolo 15/700,
/// meta 12 grigia.
class QrRow extends StatelessWidget {
  const QrRow({required this.code, required this.meta, this.onTap, this.trailing, super.key});

  final QrCode code;
  final String meta;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = QrPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MicroSpacing.s),
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MicroSpacing.m,
              MicroSpacing.m,
              MicroSpacing.s,
              MicroSpacing.m,
            ),
            child: Row(
              children: [
                QrThumb(code: code),
                MicroSpacing.hGapM,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation('wght', 700)],
                          color: p.ink,
                        ),
                      ),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.inkMuted),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un'azione della griglia sotto il QR: alta 72, raggio 18, superficie con bordo, l'icona, un
/// pallino verde e l'etichetta. Con [locked] il pallino diventa un lucchetto: e' Pro.
class ActionTile extends StatelessWidget {
  const ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.locked = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final p = QrPalette.of(context);
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: p.ink),
              const SizedBox(height: 5),
              // ⚑ Pallino e lucchetto nello stesso spazio alto 9: le etichette restano allineate.
              SizedBox(
                height: 9,
                child: Center(
                  child: locked
                      ? Icon(Icons.lock, size: 9, color: p.inkMuted, key: const ValueKey('lock'))
                      : Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontVariations: const [FontVariation('wght', 600)],
                    color: p.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

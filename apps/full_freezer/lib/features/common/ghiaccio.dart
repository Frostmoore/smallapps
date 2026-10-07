import 'package:flutter/material.dart';

import '../../app/freezer_palette.dart';

/// I mattoni dell'interfaccia "A · Ghiaccio" usati da piu' pagine (decisione del
/// 2026-10-07). Stanno qui perche' home, pagina del freezer e impostazioni devono avere
/// le stesse etichette e le stesse righe: copiati in ogni pagina divergerebbero al primo
/// ritocco.

/// L'etichetta di sezione: maiuscolo, spaziata, grigio-blu, con un'azione opzionale a destra.
class GhiaccioSectionLabel extends StatelessWidget {
  const GhiaccioSectionLabel({
    required this.text,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(22, 22, 22, 10),
    super.key,
  });

  final String text;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = FreezerPalette.of(context);
    return Padding(
      padding: trailing == null ? padding : padding.copyWith(right: 8, bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(color: p.inkMuted, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.8),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// La riga bianca arrotondata: icona in un riquadro azzurro, titolo, sottotitolo, coda.
class GhiaccioTile extends StatelessWidget {
  const GhiaccioTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Di solito un'icona: finisce nel riquadro azzurro.
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = FreezerPalette.of(context);
    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: p.iconTile, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: IconTheme.merge(data: IconThemeData(color: p.onIconTile, size: 20), child: leading!),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.inkMuted),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

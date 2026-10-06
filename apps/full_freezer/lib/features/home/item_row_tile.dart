import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/formats.dart';
import '../../app/freezer_palette.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../domain/aging.dart';
import '../../domain/home_view.dart';
import '../../l10n/generated/app_localizations.dart';
import '../items/item_pickers.dart';

/// I gesti comuni a schede e righe (develop_microapps.md F4.4).
///
/// Swipe a destra "Consumato", a sinistra "Buttato", entrambi con "Annulla" nello snackbar;
/// tocco: la pagina dell'alimento; pressione lunga: "Ne ho congelato un altro uguale".
///
/// ⚑ Niente conferma modale sullo swipe: l'uscita e' il gesto piu' frequente dopo l'entrata,
/// una domanda a ogni uscita la rende fastidiosa, e l'annullamento rimette tutto com'era.
class _ItemGestures extends ConsumerWidget {
  const _ItemGestures({required this.row, required this.radius, required this.child});

  final ItemRow row;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final item = row.item;
    return Dismissible(
      key: ValueKey('item-${item.id}'),
      background: _SwipeBackground(
        color: scheme.success,
        icon: Icons.check_circle_outline,
        label: l.item_consume,
        alignment: Alignment.centerLeft,
        radius: radius,
      ),
      secondaryBackground: _SwipeBackground(
        color: scheme.warning,
        icon: Icons.delete_outline,
        label: l.item_discard,
        alignment: Alignment.centerRight,
        radius: radius,
      ),
      onDismissed: (direction) {
        final consumed = direction == DismissDirection.startToEnd;
        final repo = ref.read(repositoryProvider);
        unawaited(repo.removeItem(item.id, consumed: consumed));
        MicroSnack.show(
          context,
          consumed ? l.item_consumed(item.name) : l.item_discarded(item.name),
          actionLabel: l.common_undo,
          onAction: () => unawaited(repo.undoRemoval(item.id)),
        );
      },
      // ☠ Dismissible mette il contenuto in uno Stack, che ALLENTA i vincoli: senza questa
      // larghezza piena le schede si stringono sul testo e due schede affiancate escono di
      // larghezze diverse (visto sull'emulatore il 2026-10-07).
      child: SizedBox(
        width: double.infinity,
        child: Material(
        color: FreezerPalette.of(context).card,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: () => context.push(Routes.itemEditOf(item.id)),
          onLongPress: () async {
            await ref.read(repositoryProvider).duplicateAsToday(item.id, today: ref.read(todayProvider));
            if (context.mounted) MicroSnack.success(context, l.item_duplicated(item.name));
          },
          child: child,
        ),
      ),
      ),
    );
  }
}

/// Il colore dei giorni secondo l'anzianita'.
Color daysColor(AgingLevel level, FreezerPalette p) => switch (level) {
  AgingLevel.old => p.old,
  AgingLevel.watch => p.watch,
  AgingLevel.fresh => p.inkMuted,
};

/// Il sottotitolo di un alimento: quantita', e dove sta se serve saperlo.
String itemSubtitle(BuildContext context, ItemRow row, {required bool showFreezer, String? compartment}) {
  final l = L.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final item = row.item;
  return [
    '${formatQuantity(item.quantity, locale)} ${unitName(l, item.unit, item.quantity)}',
    if (compartment != null) compartment,
    if (showFreezer) row.freezerName,
  ].join(' · ');
}

/// La scheda di "Da usare prima": i giorni in grande, nel colore dell'anzianita'.
class UseSoonCard extends StatelessWidget {
  const UseSoonCard({required this.row, required this.subtitle, super.key});

  final ItemRow row;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = FreezerPalette.of(context);
    final days = row.aging.days;
    return _ItemGestures(
      row: row,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$days',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1),
                  ),
                  TextSpan(
                    text: ' ${l.home_daysUnit(days)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              style: TextStyle(color: daysColor(row.aging.level, p)),
            ),
            const SizedBox(height: 8),
            Text(
              row.item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: p.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// La riga di "Tutto il resto": icona della categoria, nome, quantita', giorni.
class ItemRowTile extends StatelessWidget {
  const ItemRowTile({required this.row, required this.subtitle, super.key});

  final ItemRow row;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = FreezerPalette.of(context);
    return _ItemGestures(
      row: row,
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: p.iconTile, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: categoryGlyph(row.item.category, size: 22, color: p.onIconTile),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: p.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l.item_daysShort(row.aging.days),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: daysColor(row.aging.level, p)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
    required this.radius,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: MicroSpacing.l),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          MicroSpacing.hGapS,
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

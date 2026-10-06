import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/formats.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../domain/aging.dart';
import '../../domain/home_view.dart';
import '../../l10n/generated/app_localizations.dart';
import '../items/item_pickers.dart';

/// Una riga della home (develop_microapps.md F4.4).
///
/// Swipe a destra "Consumato" (verde), a sinistra "Buttato" (arancio), entrambi con
/// "Annulla" nello snackbar. Tocco: la pagina dell'alimento. Pressione lunga: "Ne ho
/// congelato un altro uguale".
///
/// ⚑ Niente conferma modale sullo swipe (develop_microapps.md F1, "perche' lo swipe con
/// undo e non la conferma"): l'uscita e' il gesto piu' frequente dopo l'entrata, una domanda
/// a ogni uscita la rende fastidiosa, e l'annullamento rimette tutto com'era.
class ItemRowTile extends ConsumerWidget {
  const ItemRowTile({required this.row, this.showFreezer = false, super.key});

  final ItemRow row;
  final bool showFreezer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final item = row.item;
    final accent = switch (row.aging.level) {
      AgingLevel.old => scheme.danger,
      AgingLevel.watch => scheme.warning,
      AgingLevel.fresh => null,
    };
    final quantity = '${formatQuantity(item.quantity, locale)} ${unitName(l, item.unit, item.quantity)}';
    final subtitle = [quantity, if (showFreezer) row.freezerName].join(' · ');

    return Dismissible(
      key: ValueKey('item-${item.id}'),
      background: _SwipeBackground(
        color: scheme.success,
        icon: Icons.check_circle_outline,
        label: l.item_consume,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeBackground(
        color: scheme.warning,
        icon: Icons.delete_outline,
        label: l.item_discard,
        alignment: Alignment.centerRight,
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
      child: GestureDetector(
        onLongPress: () async {
          await ref.read(repositoryProvider).duplicateAsToday(item.id, today: ref.read(todayProvider));
          if (context.mounted) MicroSnack.success(context, l.item_duplicated(item.name));
        },
        child: MicroListTile(
          leading: Icon(categoryIcon(item.category), color: accent ?? scheme.primary),
          title: item.name,
          subtitle: subtitle,
          trailingText: l.item_daysShort(row.aging.days),
          accent: accent,
          onTap: () => context.push(Routes.itemEditOf(item.id)),
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
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: MicroSpacing.l),
      decoration: BoxDecoration(color: color, borderRadius: MicroRadius.card),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          MicroSpacing.hGapS,
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

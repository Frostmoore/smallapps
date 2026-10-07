import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/freezer_palette.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/ghiaccio.dart';
import '../items/item_pickers.dart';

/// Lo storico di consumati e buttati (Pro, F4.7), i piu' recenti per primi, a gruppi per
/// mese. Toccando una riga si apre l'alimento, da cui lo si puo' rimettere nel freezer.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = FreezerPalette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final removed = ref.watch(removedItemsProvider).value ?? const <Item>[];

    final children = <Widget>[];
    String? currentMonth;
    for (final item in removed) {
      final out = DateTime.fromMillisecondsSinceEpoch(item.removedAt ?? 0, isUtc: true).toLocal();
      final month = DateFormat.yMMMM(locale).format(out);
      if (month != currentMonth) {
        currentMonth = month;
        children.add(GhiaccioSectionLabel(text: month, padding: const EdgeInsets.fromLTRB(4, 18, 4, 8)));
      }
      final consumed = item.status == ItemStatus.consumed;
      final frozen = CivilDate.tryParse(item.frozenAt);
      final days = frozen?.daysUntil(CivilDate.fromDateTime(out));
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GhiaccioTile(
            leading: categoryGlyph(item.category, size: 22, color: p.onIconTile),
            title: item.name,
            subtitle: '${consumed ? l.item_consume : l.item_discard} · ${DateFormat.MMMd(locale).format(out)}'
                '${days == null ? '' : ' · ${l.history_stayed(days < 0 ? 0 : days)}'}',
            trailing: Icon(
              consumed ? Icons.check_circle_outline : Icons.delete_outline,
              color: consumed ? Theme.of(context).colorScheme.success : p.old,
            ),
            onTap: () => context.push(Routes.itemEditOf(item.id)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.history_title)),
      body: removed.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l.history_empty, textAlign: TextAlign.center, style: TextStyle(color: p.inkMuted, height: 1.4)),
            )
          : ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 40), children: children),
    );
  }
}

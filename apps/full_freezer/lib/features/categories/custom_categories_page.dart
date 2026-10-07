import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/category_glyphs.dart';
import '../../app/freezer_palette.dart';
import '../../app/providers.dart';
import '../../data/database.dart';
import '../../domain/categories.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/ghiaccio.dart';
import 'custom_category_editor.dart';

/// Le categorie personalizzate (Pro, `FeatureKey.customCategories`): elenco, modifica,
/// cancellazione. Ci si arriva dalle impostazioni con `openProFeature`, quindi qui il Pro
/// e' gia' verificato. Si possono creare anche dal foglio delle categorie di un alimento
/// (`chooseCategory`), che e' il posto dove servono davvero.
class CustomCategoriesPage extends ConsumerWidget {
  const CustomCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = FreezerPalette.of(context);
    final categories = ref.watch(customCategoriesProvider).value ?? const <CustomCategory>[];

    return Scaffold(
      appBar: AppBar(title: Text(l.categories_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(l.categories_empty, textAlign: TextAlign.center, style: TextStyle(color: p.inkMuted, height: 1.4)),
            ),
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GhiaccioTile(
                leading: CategoryGlyph(iconKey: c.iconKey, color: p.onIconTile),
                title: c.name,
                subtitle: c.defaultReminderDays == null ? null : l.category_reminderDays(c.defaultReminderDays!),
                trailing: IconButton(
                  tooltip: l.categories_delete,
                  icon: Icon(Icons.delete_outline, color: p.inkMuted),
                  onPressed: () => unawaited(_delete(context, ref, c)),
                ),
                onTap: () => unawaited(_edit(context, ref, c)),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(_create(context, ref)),
        icon: const Icon(Icons.add),
        label: Text(l.categories_new),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final draft = await showCustomCategoryEditor(context);
    if (draft == null) return;
    await ref
        .read(repositoryProvider)
        .addCustomCategory(name: draft.name, iconKey: draft.iconKey, defaultReminderDays: draft.reminderDays);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, CustomCategory c) async {
    final draft = await showCustomCategoryEditor(context, existing: c);
    if (draft == null) return;
    await ref
        .read(repositoryProvider)
        .updateCustomCategory(c.id, name: draft.name, iconKey: draft.iconKey, defaultReminderDays: draft.reminderDays);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, CustomCategory c) async {
    final l = L.of(context);
    final key = customCategoryKey(c.id);
    final inUse = (ref.read(storedItemsProvider).value ?? const <Item>[]).where((i) => i.category == key).length;
    final ok = await MicroConfirmSheet.show(
      context,
      title: l.categories_deleteTitle(c.name),
      message: l.categories_deleteBody(inUse),
      confirmLabel: l.categories_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!ok) return;
    await ref.read(repositoryProvider).deleteCustomCategory(c.id);
  }
}

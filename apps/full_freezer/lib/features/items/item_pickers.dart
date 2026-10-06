import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/formats.dart';
import '../../app/freezer_icons.dart';
import '../../data/database.dart';
import '../../domain/capacity.dart';
import '../../domain/categories.dart';
import '../../domain/units.dart';
import '../../l10n/generated/app_localizations.dart';

/// Il nome visibile di un'unita', con la quantita' (per il plurale).
String unitName(L l, String key, double quantity) {
  final n = quantity == quantity.roundToDouble() ? quantity.round() : 2;
  return switch (key) {
    Units.portions => l.unit_portions(n),
    Units.pieces => l.unit_pieces(n),
    Units.packs => l.unit_packs(n),
    Units.grams => 'g',
    Units.kilograms => 'kg',
    Units.liters => 'L',
    _ => key,
  };
}

/// Il nome visibile di una categoria predefinita.
String categoryName(L l, String? key) => switch (key) {
  'meat_red' => l.category_meat_red,
  'meat_white' => l.category_meat_white,
  'fish' => l.category_fish,
  'vegetables' => l.category_vegetables,
  'fruit' => l.category_fruit,
  'bread' => l.category_bread,
  'prepared' => l.category_prepared,
  'ice_cream' => l.category_ice_cream,
  'other' => l.category_other,
  _ => l.category_none,
};

IconData categoryIcon(String? key) => CategoryIcons.resolve(ItemCategories.byKey(key)?.iconKey);

/// Sceglie la categoria. Restituisce la chiave, `''` per "nessuna", null se chiuso.
Future<String?> pickCategory(BuildContext context, String? current) {
  final l = L.of(context);
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final c in ItemCategories.all)
            ListTile(
              leading: Icon(CategoryIcons.resolve(c.iconKey)),
              title: Text(categoryName(l, c.key)),
              subtitle: Text(l.category_reminderDays(c.defaultReminderDays)),
              trailing: current == c.key ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(sheet).pop(c.key),
            ),
          ListTile(
            leading: const Icon(Icons.block),
            title: Text(l.category_none),
            trailing: current == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(sheet).pop(''),
          ),
        ],
      ),
    ),
  );
}

/// L'esito di [pickSize]: litri scelti, oppure "torna alla stima".
sealed class SizeChoice {
  const SizeChoice();
}

final class SizeLiters extends SizeChoice {
  const SizeLiters(this.liters);
  final double liters;
}

final class SizeAuto extends SizeChoice {
  const SizeAuto();
}

/// Corregge l'ingombro di un alimento (F4.3b, prima correzione): quattro misure rapide per
/// unita', un valore libero, o la stima automatica.
Future<SizeChoice?> pickSize(
  BuildContext context, {
  required double quantity,
  required double estimate,
  required bool manual,
}) {
  final l = L.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final custom = TextEditingController();
  String label(String key) => switch (key) {
    'small' => l.size_small,
    'medium' => l.size_medium,
    'large' => l.size_large,
    _ => l.size_xlarge,
  };
  return showModalBottomSheet<SizeChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(MicroSpacing.l, 0, MicroSpacing.l, MicroSpacing.l),
          children: [
            Text(l.size_title, style: Theme.of(sheet).textTheme.titleMedium),
            MicroSpacing.gapXS,
            Text(l.size_body, style: Theme.of(sheet).textTheme.bodySmall),
            MicroSpacing.gapM,
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(l.size_auto),
              subtitle: Text(formatLiters(estimate, locale)),
              trailing: manual ? null : const Icon(Icons.check),
              onTap: () => Navigator.of(sheet).pop(const SizeAuto()),
            ),
            for (final e in CapacityEstimator.quickSizes.entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.straighten),
                title: Text(label(e.key)),
                subtitle: Text(
                  l.size_perUnit(formatLiters(e.value, locale), formatLiters(e.value * quantity, locale)),
                ),
                onTap: () => Navigator.of(sheet).pop(SizeLiters(e.value * quantity)),
              ),
            MicroSpacing.gapS,
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: custom,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l.size_customLabel, suffixText: 'L'),
                  ),
                ),
                MicroSpacing.hGapM,
                FilledButton(
                  onPressed: () {
                    final v = parseUserNumber(custom.text);
                    if (v != null && v > 0) Navigator.of(sheet).pop(SizeLiters(v));
                  },
                  child: Text(l.common_ok),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Sceglie dove mettere l'alimento: freezer e, se ce ne sono, scomparto.
Future<({int freezerId, int? compartmentId})?> pickLocation(
  BuildContext context, {
  required List<Freezer> freezers,
  required Map<int, List<Compartment>> compartments,
  required int freezerId,
  required int? compartmentId,
}) {
  final l = L.of(context);
  return showModalBottomSheet<({int freezerId, int? compartmentId})>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final f in freezers) ...[
            ListTile(
              leading: const Icon(Icons.kitchen_outlined),
              title: Text(f.name),
              subtitle: (compartments[f.id] ?? const []).isEmpty ? null : Text(l.location_noCompartment),
              trailing: f.id == freezerId && compartmentId == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(sheet).pop((freezerId: f.id, compartmentId: null)),
            ),
            for (final c in compartments[f.id] ?? const <Compartment>[])
              ListTile(
                contentPadding: const EdgeInsets.only(left: MicroSpacing.xxxl, right: MicroSpacing.l),
                title: Text(c.name),
                trailing: c.id == compartmentId ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheet).pop((freezerId: f.id, compartmentId: c.id)),
              ),
          ],
        ],
      ),
    ),
  );
}

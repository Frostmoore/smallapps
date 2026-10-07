import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/category_glyphs.dart';
import '../../app/formats.dart';
import '../../data/database.dart';
import '../../l10n/generated/app_localizations.dart';

/// Quello che l'editor restituisce: il resto (id, colore) lo decide il repository.
@immutable
class CustomCategoryDraft {
  const CustomCategoryDraft({required this.name, required this.iconKey, this.reminderDays});

  final String name;
  final String iconKey;
  final int? reminderDays;
}

/// Le icone fra cui scegliere: le stesse delle categorie predefinite.
///
/// ⚑ Niente icone di Material qui: le categorie dell'utente stanno nelle stesse righe di
/// quelle predefinite, e un'icona di un'altra famiglia si noterebbe subito (decisione delle
/// icone disegnate, 2026-10-07).
const List<String> customCategoryIcons = <String>[
  'meat',
  'poultry',
  'fish',
  'vegetables',
  'fruit',
  'bread',
  'prepared',
  'ice_cream',
  'other',
];

/// Crea o modifica una categoria personalizzata. null se annullato.
Future<CustomCategoryDraft?> showCustomCategoryEditor(BuildContext context, {CustomCategory? existing}) =>
    showDialog<CustomCategoryDraft>(
      context: context,
      builder: (_) => _CustomCategoryDialog(existing: existing),
    );

class _CustomCategoryDialog extends StatefulWidget {
  const _CustomCategoryDialog({this.existing});

  final CustomCategory? existing;

  @override
  State<_CustomCategoryDialog> createState() => _CustomCategoryDialogState();
}

class _CustomCategoryDialogState extends State<_CustomCategoryDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _days = TextEditingController(
    text: widget.existing?.defaultReminderDays?.toString() ?? '',
  );
  late String _icon = widget.existing?.iconKey ?? 'other';

  @override
  void dispose() {
    _name.dispose();
    _days.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty;

  void _save() {
    if (!_valid) return;
    final days = parseUserNumber(_days.text)?.round();
    Navigator.of(context).pop(
      CustomCategoryDraft(name: _name.text.trim(), iconKey: _icon, reminderDays: days != null && days > 0 ? days : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.existing == null ? l.categories_new : l.categories_edit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.existing == null,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.categories_name),
              onChanged: (_) => setState(() {}),
            ),
            MicroSpacing.gapS,
            Text(l.categories_icon, style: Theme.of(context).textTheme.labelLarge),
            MicroSpacing.gapS,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in customCategoryIcons)
                  Semantics(
                    button: true,
                    selected: key == _icon,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _icon = key),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: key == _icon ? scheme.primaryContainer : null,
                          border: Border.all(color: key == _icon ? scheme.primary : scheme.outlineVariant),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CategoryGlyph(
                          iconKey: key,
                          color: key == _icon ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            MicroSpacing.gapM,
            TextField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.item_reminder,
                suffixText: l.item_reminderSuffix,
                helperText: l.categories_reminderHelp,
                helperMaxLines: 3,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.common_cancel)),
        TextButton(onPressed: _valid ? _save : null, child: Text(l.common_save)),
      ],
    );
  }
}

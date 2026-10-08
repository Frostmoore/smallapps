import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../data/database.dart';
import '../../data/film_repository.dart';
import '../../domain/film_types.dart';
import '../../l10n/generated/app_localizations.dart';
import '../lab/lab_fields.dart' show SuggestionTextField;

/// Apre il foglio per creare una pellicola personalizzata (F6.4: marca, nome, ISO, processo,
/// formato) e restituisce il suo id; null se si chiude senza salvare.
///
/// ⚑ **Se la pellicola esiste gia'** (stessa marca, nome e formato a meno delle maiuscole,
/// `DuplicateFilmStockException`) il foglio lo dice sotto il nome e offre "Usa questa", che
/// restituisce l'id di quella **esistente**: dal form del rullino e' quello che serve, una
/// pellicola da scegliere, non un doppione.
///
/// Lo usa anche il form del rullino ("Pellicola personalizzata").
Future<int?> showCustomStockSheet(BuildContext context, WidgetRef ref) => showModalBottomSheet<int>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => const _CustomStockSheet(),
);

/// Apre lo stesso foglio per modificare una pellicola personalizzata. `true` se salvata.
///
/// ⚑ I rullini gia' scattati con questa pellicola **non** cambiano nome (`filmName` e'
/// denormalizzato): il foglio lo dice, perche' chi corregge un refuso si aspetterebbe il
/// contrario.
Future<bool> showEditCustomStockSheet(BuildContext context, WidgetRef ref, FilmStock stock) async {
  assert(stock.isCustom, 'Le pellicole del catalogo non si modificano');
  final id = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CustomStockSheet(stock: stock),
  );
  return id != null;
}

class _CustomStockSheet extends ConsumerStatefulWidget {
  const _CustomStockSheet({this.stock});

  /// Null per una pellicola nuova.
  final FilmStock? stock;

  @override
  ConsumerState<_CustomStockSheet> createState() => _CustomStockSheetState();
}

class _CustomStockSheetState extends ConsumerState<_CustomStockSheet> {
  final _brand = TextEditingController();
  final _name = TextEditingController();
  final _iso = TextEditingController();
  FilmProcess _process = FilmProcess.c41;
  FilmFormat _format = FilmFormat.mm35;
  bool _saving = false;

  /// La pellicola uguale trovata all'ultimo salvataggio; si azzera appena si cambia un campo.
  FilmStock? _duplicate;

  bool get _editing => widget.stock != null;

  @override
  void initState() {
    super.initState();
    final s = widget.stock;
    if (s != null) {
      _brand.text = s.brand;
      _name.text = s.name;
      _iso.text = '${s.iso}';
      _process = FilmProcess.byKey(s.process) ?? FilmProcess.other;
      _format = FilmFormat.byKey(s.format) ?? FilmFormat.other;
    }
  }

  @override
  void dispose() {
    for (final c in [_brand, _name, _iso]) {
      c.dispose();
    }
    super.dispose();
  }

  int? get _isoValue {
    final v = int.tryParse(_iso.text.trim());
    // Gli stessi limiti del CHECK di `film_stocks.iso`.
    return v == null || v < 1 || v > 100000 ? null : v;
  }

  bool get _valid => _brand.text.trim().isNotEmpty && _name.text.trim().isNotEmpty && _isoValue != null;

  void _changed() => setState(() => _duplicate = null);

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    try {
      final old = widget.stock;
      final int id;
      if (old == null) {
        id = await repo.addCustomStock(
          brand: _brand.text,
          name: _name.text,
          iso: _isoValue!,
          process: _process,
          format: _format,
        );
      } else {
        await repo.updateCustomStock(
          old.copyWith(
            brand: _brand.text.trim(),
            name: _name.text.trim(),
            iso: _isoValue,
            process: _process.key,
            format: _format.key,
          ),
        );
        id = old.id;
      }
      if (mounted) Navigator.of(context).pop(id);
    } on DuplicateFilmStockException catch (e) {
      final existing = await repo.stockById(e.existingId);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _duplicate =
            existing ??
            FilmStock(
              id: e.existingId,
              brand: _brand.text.trim(),
              name: _name.text.trim(),
              iso: _isoValue ?? 0,
              process: _process.key,
              format: _format.key,
              isCustom: false,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final stocks = ref.watch(filmStocksProvider).value ?? const <FilmStock>[];
    // Le marche gia' presenti, una volta sola: "kodak" non deve diventare una marca nuova.
    final brands = <String>[];
    final seen = <String>{};
    for (final s in stocks) {
      if (seen.add(s.brand.toLowerCase())) brands.add(s.brand);
    }
    final dup = _duplicate;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(MicroSpacing.l, 0, MicroSpacing.l, MicroSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_editing ? l.stock_editTitle : l.stock_newTitle, style: text.titleLarge),
              if (_editing) ...[
                MicroSpacing.gapXS,
                Text(l.stock_editKeepsRolls, style: text.bodySmall),
              ],
              MicroSpacing.gapM,
              SuggestionTextField(
                fieldKey: const ValueKey('stock_brand'),
                controller: _brand,
                suggestions: brands,
                label: l.stock_brand,
                maxLength: 60,
                onChanged: _changed,
              ),
              TextField(
                key: const ValueKey('stock_name'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: l.stock_name,
                  hintText: l.stock_nameHint,
                  errorText: dup == null ? null : l.stock_duplicate('${dup.brand} ${dup.name}', formatName(l, _format)),
                  errorMaxLines: 3,
                ),
                onChanged: (_) => _changed(),
              ),
              if (dup != null && !_editing)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(dup.id),
                    icon: const Icon(Icons.check),
                    label: Text(l.stock_useExisting),
                  ),
                ),
              TextField(
                key: const ValueKey('stock_iso'),
                controller: _iso,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'ISO'),
                onChanged: (_) => _changed(),
              ),
              MicroSpacing.gapL,
              Text(l.stock_process, style: text.titleSmall),
              MicroSpacing.gapS,
              Wrap(
                spacing: MicroSpacing.s,
                runSpacing: MicroSpacing.s,
                children: [
                  for (final p in FilmProcess.values)
                    ChoiceChip(
                      label: Text(processName(l, p)),
                      selected: p == _process,
                      onSelected: (_) => setState(() {
                        _process = p;
                        _duplicate = null;
                      }),
                    ),
                ],
              ),
              MicroSpacing.gapL,
              Text(l.stock_format, style: text.titleSmall),
              MicroSpacing.gapS,
              Wrap(
                spacing: MicroSpacing.s,
                runSpacing: MicroSpacing.s,
                children: [
                  for (final f in FilmFormat.values)
                    ChoiceChip(
                      label: Text(formatName(l, f)),
                      selected: f == _format,
                      onSelected: (_) => setState(() {
                        _format = f;
                        _duplicate = null;
                      }),
                    ),
                ],
              ),
              MicroSpacing.gapXL,
              MicroPrimaryButton(
                label: l.common_save,
                loading: _saving,
                onPressed: _valid && !_saving ? () => unawaited(_save()) : null,
              ),
              if (dup != null) ...[
                MicroSpacing.gapS,
                Text(
                  l.stock_duplicateHelp,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

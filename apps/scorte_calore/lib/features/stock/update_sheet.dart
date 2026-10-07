import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/formats.dart';
import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../data/database.dart';
import '../../domain/fuel_source.dart';
import '../../domain/fuel_units.dart';
import '../../domain/quantity_converter.dart';
import '../../l10n/generated/app_localizations.dart';

/// Apre il foglio di aggiornamento della scorta (F5.7), il gesto piu' frequente dell'app.
///
/// ⚑ Salvare costa un tocco: la data e' oggi, la quantita' e' gia' quella dell'ultima volta
/// (si corregge solo il numero), e per GPL e gasolio si sceglie fra litri e lettura del
/// manometro, con la conversione scritta mentre si digita.
Future<void> showUpdateSheet(BuildContext context, FuelSource source) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _UpdateSheet(source: source),
);

class _UpdateSheet extends ConsumerStatefulWidget {
  const _UpdateSheet({required this.source});

  final FuelSource source;

  @override
  ConsumerState<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends ConsumerState<_UpdateSheet> {
  final _quantity = TextEditingController();
  late CivilDate _date = ref.read(todayProvider);
  late final FuelSourceSpec _spec = widget.source.toSpec();
  late final QuantityConverter _converter = QuantityConverter(_spec);
  bool _asPercent = false;
  double? _last;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_prefill());
  }

  /// La quantita' dell'ultima misura: si corregge un numero invece di scriverlo da zero.
  Future<void> _prefill() async {
    final last = await ref.read(repositoryProvider).latestMeasurement(_spec.id);
    if (last == null || !mounted) return;
    _last = last.quantity;
    final percent = last.enteredAs == EnteredAs.percentage.key && _converter.supportsPercentage;
    setState(() {
      _asPercent = percent;
      _quantity.text = _fmt(percent ? last.rawInput : last.quantity);
    });
  }

  String _fmt(double v) => formatQuantity(v, Localizations.localeOf(context).toLanguageTag());

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  double? get _value => parseUserNumber(_quantity.text);

  /// La quantita' che verra' salvata, nell'unita' della fonte.
  double? get _resulting {
    final v = _value;
    if (v == null || v < 0) return null;
    if (_asPercent) return v <= 100 ? _converter.fromPercentage(v) : null;
    return v;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.toLocalMidnight(),
      firstDate: DateTime(2020),
      lastDate: ref.read(todayProvider).toLocalMidnight(),
    );
    if (picked != null) setState(() => _date = CivilDate.fromDateTime(picked));
  }

  Future<void> _save() async {
    final v = _value;
    if (v == null || _resulting == null || _saving) return;
    setState(() => _saving = true);
    final m = _asPercent
        ? Measurement(date: _date, quantity: _resulting!, enteredAs: EnteredAs.percentage, rawInput: v)
        : Measurement.absolute(date: _date, quantity: v);
    await ref.read(repositoryProvider).upsertMeasurement(_spec.id, m);
    if (!mounted) return;
    final l = L.of(context);
    Navigator.of(context).pop();
    MicroSnack.success(context, l.update_saved);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final resulting = _resulting;
    final refill = resulting != null && _last != null && resulting > _last! + 0.0001;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MicroSpacing.l, 0, MicroSpacing.l, MicroSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${l.update_title} · ${_spec.name}', style: text.titleLarge),
              MicroSpacing.gapS,
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(l.update_date),
                subtitle: Text(DateFormat.yMMMMd(locale).format(_date.toLocalMidnight())),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
              if (_converter.supportsPercentage && _spec.unitKey != FuelUnits.percent)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.update_asPercent),
                  value: _asPercent,
                  onChanged: (v) => setState(() {
                    _asPercent = v;
                    _quantity.clear();
                  }),
                ),
              TextField(
                controller: _quantity,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: text.headlineSmall,
                decoration: InputDecoration(
                  labelText: l.update_quantity,
                  suffixText: _asPercent ? '%' : unitName(l, _spec.unitKey, 2),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => unawaited(_save()),
              ),
              if (_asPercent && resulting != null) ...[
                MicroSpacing.gapS,
                Text(
                  l.update_conversion(
                    _fmt(_value!),
                    _fmt(_spec.tankCapacity ?? 0),
                    formatQuantity(resulting.roundToDouble(), locale),
                  ),
                  style: text.bodyMedium,
                ),
              ],
              if (refill) ...[
                MicroSpacing.gapS,
                Text(l.update_refill, style: text.bodySmall),
              ],
              MicroSpacing.gapL,
              MicroPrimaryButton(
                label: l.common_save,
                onPressed: resulting != null && !_saving ? () => unawaited(_save()) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

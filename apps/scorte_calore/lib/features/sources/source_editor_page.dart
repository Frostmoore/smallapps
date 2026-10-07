import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/formats.dart';
import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../domain/fuel_source.dart';
import '../../domain/fuel_units.dart';
import '../../l10n/generated/app_localizations.dart';

/// Configurazione di una fonte di calore (F5.5): nuova (anche al primo avvio) o esistente.
///
/// ⚑ **Una pagina sola e non una procedura a passi** come diceva il piano: i campi sono pochi
/// e quasi tutti hanno un valore gia' giusto; otto schermate con "Avanti" farebbero sembrare
/// lunga una cosa che si fa in venti secondi. I campi che non servono non compaiono: il
/// serbatoio solo per GPL e gasolio, il peso solo per sacchi, bancali e cassette.
class SourceEditorPage extends ConsumerStatefulWidget {
  const SourceEditorPage({this.sourceId, this.firstRun = false, super.key});

  /// Null per una fonte nuova.
  final int? sourceId;
  final bool firstRun;

  @override
  ConsumerState<SourceEditorPage> createState() => _SourceEditorPageState();
}

class _SourceEditorPageState extends ConsumerState<SourceEditorPage> {
  final _name = TextEditingController();
  final _tank = TextEditingController();
  final _weight = TextEditingController();
  final _stock = TextEditingController();
  final _cost = TextEditingController();
  FuelType _fuel = FuelType.pellet;
  String _unit = FuelType.pellet.defaultUnitKey;
  double _usable = FuelType.pellet.defaultUsableFraction;
  int _warningDays = FuelType.defaultWarningDays;
  bool _loaded = false;
  bool _saving = false;

  bool get _isNew => widget.sourceId == null;

  @override
  void initState() {
    super.initState();
    if (!_isNew) unawaited(_load());
  }

  Future<void> _load() async {
    final s = await ref.read(repositoryProvider).sourceById(widget.sourceId!);
    if (s == null || !mounted) return;
    final spec = s.toSpec();
    setState(() {
      _name.text = spec.name;
      _fuel = spec.fuelType;
      _unit = spec.unitKey;
      _usable = spec.usableFraction;
      _warningDays = spec.warningDays;
      _tank.text = spec.tankCapacity == null ? '' : _num(spec.tankCapacity!);
      _weight.text = spec.unitWeightKg == null ? '' : _num(spec.unitWeightKg!);
      _cost.text = spec.costPerUnitCents == null ? '' : _num(spec.costPerUnitCents! / 100);
      _loaded = true;
    });
  }

  String _num(double v) => formatQuantity(v, Localizations.localeOf(context).toLanguageTag());

  @override
  void dispose() {
    for (final c in [_name, _tank, _weight, _stock, _cost]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setFuel(FuelType fuel) => setState(() {
    _fuel = fuel;
    if (!FuelUnits.isAllowed(fuel, _unit)) _unit = fuel.defaultUnitKey;
    _usable = fuel.defaultUsableFraction;
  });

  bool get _valid {
    if (_name.text.trim().isEmpty) return false;
    if (_fuel.usesTank && (parseUserNumber(_tank.text) ?? 0) <= 0) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final tank = _fuel.usesTank ? parseUserNumber(_tank.text) : null;
    final unit = FuelUnits.byKey(_unit);
    final weight = unit.supportsWeight ? parseUserNumber(_weight.text) : null;
    final cost = parseUserNumber(_cost.text);
    final costCents = cost == null ? null : (cost * 100).round();
    final name = _name.text.trim();

    if (_isNew) {
      final id = await repo.addSource(
        name: name,
        fuelType: _fuel,
        unitKey: _unit,
        unitWeightKg: weight,
        tankCapacity: tank,
        usableFraction: _usable,
        warningDays: _warningDays,
        costPerUnitCents: costCents,
      );
      final stock = parseUserNumber(_stock.text);
      if (stock != null && stock >= 0) {
        await repo.upsertMeasurement(id, Measurement.absolute(date: ref.read(todayProvider), quantity: stock));
      }
      await ref.read(settingsProvider).setBool(SettingKeys.onboardingDone, true);
      ref.invalidate(onboardingDoneProvider);
    } else {
      await repo.updateSource(
        FuelSourceSpec(
          id: widget.sourceId!,
          name: name,
          fuelType: _fuel,
          unitKey: _unit,
          unitWeightKg: weight,
          tankCapacity: tank,
          usableFraction: _usable,
          warningDays: _warningDays,
          costPerUnitCents: costCents,
        ),
      );
    }
    if (!mounted) return;
    if (widget.firstRun) {
      context.go(Routes.home);
    } else {
      context.pop();
    }
  }

  Future<void> _delete() async {
    final l = L.of(context);
    final ok = await MicroConfirmSheet.show(
      context,
      title: l.source_deleteTitle(_name.text.trim()),
      message: l.source_deleteBody,
      confirmLabel: l.source_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await ref.read(repositoryProvider).deleteSource(widget.sourceId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final text = Theme.of(context).textTheme;
    if (!_isNew && !_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final unit = FuelUnits.byKey(_unit);
    final unitLabel = unitName(l, _unit, 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l.source_newTitle : l.source_editTitle),
        automaticallyImplyLeading: !widget.firstRun,
        actions: [
          if (!_isNew) IconButton(tooltip: l.source_delete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          if (widget.firstRun) ...[Text(l.source_intro, style: text.bodyLarge), MicroSpacing.gapL],
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            decoration: InputDecoration(labelText: l.source_name, hintText: l.source_nameHint),
            onChanged: (_) => setState(() {}),
          ),
          MicroSpacing.gapS,
          Text(l.source_fuel, style: text.titleSmall),
          MicroSpacing.gapS,
          Wrap(
            spacing: MicroSpacing.s,
            runSpacing: MicroSpacing.s,
            children: [
              for (final f in FuelType.values)
                ChoiceChip(label: Text(fuelName(l, f)), selected: f == _fuel, onSelected: (_) => _setFuel(f)),
            ],
          ),
          MicroSpacing.gapL,
          Text(l.source_unit, style: text.titleSmall),
          MicroSpacing.gapS,
          Wrap(
            spacing: MicroSpacing.s,
            runSpacing: MicroSpacing.s,
            children: [
              for (final u in FuelUnits.forType(_fuel))
                ChoiceChip(
                  label: Text(unitName(l, u.key, 2)),
                  selected: u.key == _unit,
                  onSelected: (_) => setState(() => _unit = u.key),
                ),
            ],
          ),
          if (_fuel.usesTank) ...[
            MicroSpacing.gapL,
            TextField(
              controller: _tank,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.source_tank, suffixText: 'L', helperText: l.source_tankHelp),
              onChanged: (_) => setState(() {}),
            ),
            MicroSpacing.gapM,
            Text('${l.source_usable}: ${(_usable * 100).round()} %', style: text.titleSmall),
            Slider(
              value: _usable,
              min: 0.5,
              max: 1,
              divisions: 10,
              label: '${(_usable * 100).round()} %',
              onChanged: (v) => setState(() => _usable = v),
            ),
            Text(l.source_usableHelp, style: text.bodySmall),
          ],
          if (unit.supportsWeight) ...[
            MicroSpacing.gapL,
            TextField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.source_weight(unitLabel),
                suffixText: 'kg',
                helperText: l.source_weightHelp,
              ),
            ),
          ],
          if (_isNew) ...[
            MicroSpacing.gapL,
            TextField(
              controller: _stock,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.source_stock, suffixText: unitName(l, _unit, 2)),
            ),
          ],
          MicroSpacing.gapL,
          TextField(
            controller: _cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.source_cost(unitLabel),
              suffixText: '€',
              helperText: l.common_optional,
            ),
          ),
          MicroSpacing.gapL,
          Text(l.source_warning, style: text.titleSmall),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _warningDays > 1 ? () => setState(() => _warningDays--) : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(child: Text(l.source_warningDays(_warningDays), textAlign: TextAlign.center)),
              IconButton.filledTonal(
                onPressed: _warningDays < 60 ? () => setState(() => _warningDays++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          MicroSpacing.gapXL,
          MicroPrimaryButton(label: l.source_save, onPressed: _valid && !_saving ? () => unawaited(_save()) : null),
        ],
      ),
    );
  }
}

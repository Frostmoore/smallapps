import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/formats.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../domain/capacity.dart';
import '../../l10n/generated/app_localizations.dart';
import 'freezer_widgets.dart';

/// Crea o modifica un freezer: nome e modello (develop_microapps.md F4.6).
///
/// La stessa pagina serve al primo avvio ([firstRun]): li' il pulsante dice "Inizia" e,
/// salvando, segna l'onboarding come fatto e porta alla home.
class FreezerEditorPage extends ConsumerStatefulWidget {
  const FreezerEditorPage({this.freezerId, this.firstRun = false, super.key});

  /// Null per un freezer nuovo.
  final int? freezerId;
  final bool firstRun;

  @override
  ConsumerState<FreezerEditorPage> createState() => _FreezerEditorPageState();
}

class _FreezerEditorPageState extends ConsumerState<FreezerEditorPage> {
  final _name = TextEditingController();
  final _liters = TextEditingController();
  String? _modelKey;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final id = widget.freezerId;
    if (id != null) {
      final f = await ref.read(repositoryProvider).freezerById(id);
      if (f != null) {
        _name.text = f.name;
        _modelKey = f.modelKey;
        if (f.modelKey == FreezerModels.customKey) {
          _liters.text = f.capacityLiters.round().toString();
        }
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Il nome proposto si scrive solo per un freezer nuovo e solo se il campo e' vuoto: va
    // fatto qui e non in initState perche' serve la lingua.
    if (widget.freezerId == null && _name.text.isEmpty) {
      _name.text = L.of(context).freezer_defaultName;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _liters.dispose();
    super.dispose();
  }

  double? get _capacity {
    final key = _modelKey;
    if (key == null) return null;
    if (key == FreezerModels.customKey) {
      final v = parseUserNumber(_liters.text);
      return (v != null && v > 0 && v <= 2000) ? v : null;
    }
    return FreezerModels.byKey(key)?.liters;
  }

  bool get _valid => _name.text.trim().isNotEmpty && _capacity != null;

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final id = widget.freezerId;
    if (id == null) {
      final newId = await repo.addFreezer(
        name: _name.text,
        modelKey: _modelKey!,
        capacityLiters: _capacity!,
      );
      if (widget.firstRun) {
        await ref.read(settingsProvider).setBool(SettingKeys.onboardingDone, true);
        ref.invalidate(onboardingDoneProvider);
      }
      await ref.read(settingsProvider).setInt(FreezerSettingKeys.lastFreezer, newId);
    } else {
      await repo.updateFreezer(id, name: _name.text, modelKey: _modelKey, capacityLiters: _capacity);
    }
    if (!mounted) return;
    if (widget.firstRun) {
      context.go(Routes.home);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.firstRun
              ? l.onboarding_title
              : widget.freezerId == null
              ? l.freezer_newTitle
              : l.freezer_editTitle,
        ),
        automaticallyImplyLeading: !widget.firstRun,
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : ListView(
              padding: MicroSpacing.page,
              children: [
                if (widget.firstRun) ...[
                  Text(l.onboarding_body, style: theme.textTheme.bodyLarge),
                  MicroSpacing.gapL,
                ],
                TextField(
                  controller: _name,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l.freezer_nameLabel),
                  onChanged: (_) => setState(() {}),
                ),
                MicroSpacing.gapM,
                Text(l.freezer_modelLabel, style: theme.textTheme.titleMedium),
                MicroSpacing.gapXS,
                Text(l.freezer_modelHint, style: theme.textTheme.bodySmall),
                MicroSpacing.gapM,
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: MicroSpacing.s,
                  crossAxisSpacing: MicroSpacing.s,
                  childAspectRatio: 1.05,
                  children: [
                    for (final m in FreezerModels.all)
                      _ModelCard(
                        silhouette: m.iconKey,
                        name: freezerModelName(l, m.key),
                        liters: formatLiters(m.liters, locale),
                        selected: _modelKey == m.key,
                        onTap: () => setState(() => _modelKey = m.key),
                      ),
                    _ModelCard(
                      silhouette: 'custom',
                      name: l.freezerModel_custom,
                      liters: l.freezer_customLitersShort,
                      selected: _modelKey == FreezerModels.customKey,
                      onTap: () => setState(() => _modelKey = FreezerModels.customKey),
                    ),
                  ],
                ),
                if (_modelKey == FreezerModels.customKey) ...[
                  MicroSpacing.gapM,
                  TextField(
                    controller: _liters,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l.freezer_customLitersLabel,
                      helperText: l.freezer_customLitersHelp,
                      suffixText: 'L',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                MicroSpacing.gapXL,
                MicroPrimaryButton(
                  label: widget.firstRun ? l.onboarding_start : l.common_save,
                  loading: _saving,
                  onPressed: _valid ? _save : null,
                ),
              ],
            ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.silhouette,
    required this.name,
    required this.liters,
    required this.selected,
    required this.onTap,
  });

  final String silhouette;
  final String name;
  final String liters;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer.withValues(alpha: 0.45) : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: MicroRadius.card,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: MicroRadius.card,
          onTap: onTap,
          child: Padding(
            padding: MicroSpacing.cardTight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FreezerSilhouette(iconKey: silhouette),
                MicroSpacing.gapS,
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge,
                ),
                MicroSpacing.gapXS,
                Text(liters, style: text.bodySmall?.copyWith(color: scheme.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/formats.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../domain/capacity.dart';
import '../../domain/units.dart';
import '../../domain/voice_parser.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/voice_input.dart';
import 'item_draft.dart';
import 'item_photo.dart';
import 'item_pickers.dart';

/// Apre l'inserimento rapido (develop_microapps.md F4.5).
///
/// ⚑ **Il vincolo dell'app**: dall'apertura al prodotto salvato, meno di 5 secondi e meno di
/// 4 tocchi. Il percorso piu' corto e': pulsante "+" (1), scrivere il nome, "Salva" (2).
/// Con un suggerimento dell'autocompletamento: 3. Tutto il resto e' gia' compilato con le
/// scelte dell'ultima volta (freezer, scomparto, unita'), la data e' oggi, la categoria e
/// l'ingombro si deducono dal nome. Ogni campo in piu' visibile qui e' un motivo per non
/// usare l'app.
Future<void> showQuickAdd(BuildContext context, WidgetRef ref) async {
  final freezers = ref.read(freezersProvider).value ?? const <Freezer>[];
  if (freezers.isEmpty) return;
  final settings = ref.read(settingsProvider);

  // Dove mettere: il freezer guardato in home, altrimenti l'ultimo usato, altrimenti il primo.
  final selected = ref.read(selectedFreezerProvider);
  final last = settings.getInt(FreezerSettingKeys.lastFreezer, orElse: -1);
  final freezerId = [selected, last, freezers.first.id].firstWhere(
    (id) => id != null && freezers.any((f) => f.id == id),
    orElse: () => freezers.first.id,
  )!;
  final lastCompartment = settings.getInt(FreezerSettingKeys.lastCompartment, orElse: -1);
  final compartments = ref.read(compartmentsByFreezerProvider).value?[freezerId] ?? const <Compartment>[];
  final unit = settings.getString(FreezerSettingKeys.lastUnit);

  final draft = ItemDraft(
    freezerId: freezerId,
    compartmentId: compartments.any((c) => c.id == lastCompartment) ? lastCompartment : null,
    frozenAt: ref.read(todayProvider),
    unit: Units.isKnown(unit) ? unit! : Units.fallback,
  )..quantity = defaultQuantity(Units.isKnown(unit) ? unit! : Units.fallback);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => QuickAddSheet(draft: draft),
  );
}

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({required this.draft, super.key});

  final ItemDraft draft;

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _name = TextEditingController();
  List<String> _suggestions = const <String>[];
  bool _saving = false;
  int _query = 0;

  /// True quando la bozza ha lasciato il foglio (salvata, o passata ad "Altri dettagli"):
  /// da li' in poi la foto non e' piu' affare del foglio.
  bool _handedOff = false;
  late final AppPaths _paths = ref.read(appPathsProvider);

  /// Il microfono (F4.12). Creato solo al primo tocco: chi non lo usa non paga
  /// l'inizializzazione del riconoscitore, ne' vede la richiesta di permesso.
  VoiceInput? _voice;
  bool _listening = false;

  ItemDraft get d => widget.draft;

  @override
  void dispose() {
    // Foglio chiuso senza salvare: la foto scattata non serve a nessuno.
    final photo = d.photoPath;
    if (!_handedOff && photo != null) unawaited(deleteItemPhoto(_paths, photo));
    unawaited(_voice?.cancel());
    _name.dispose();
    super.dispose();
  }

  Future<void> _onName(String value) async {
    setState(() => d.setName(value));
    final ticket = ++_query;
    final found = await ref.read(repositoryProvider).suggestNames(value, limit: 6);
    // Una risposta arrivata dopo una piu' recente non deve sovrascriverla.
    if (!mounted || ticket != _query) return;
    setState(() => _suggestions = found.where((s) => s != value.trim()).toList());
  }

  void _useSuggestion(String name) {
    _name
      ..text = name
      ..selection = TextSelection.collapsed(offset: name.length);
    setState(() {
      d.setName(name);
      _suggestions = const <String>[];
    });
  }

  /// Tocco sul microfono: ascolta, mostra il testo man mano, poi lo interpreta.
  Future<void> _toggleVoice() async {
    final voice = _voice ??= VoiceInput();
    if (_listening) {
      await voice.stop();
      return;
    }
    final l = L.of(context);
    final ready = await voice.prepare(
      onStatus: (status) {
        // "done"/"notListening": il motore ha chiuso da se' (pausa o limite di tempo).
        if (mounted && status != 'listening') setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    if (!ready) {
      MicroSnack.show(context, l.voice_unavailable);
      return;
    }
    final language = Localizations.localeOf(context).languageCode;
    setState(() => _listening = true);
    await voice.listen(
      languageTag: language,
      onWords: (words, {required isFinal}) {
        if (!mounted) return;
        if (!isFinal) {
          // Il testo provvisorio si vede nel campo: chi parla capisce che lo si sta
          // ascoltando, e cosa si e' capito.
          _name.text = words;
          return;
        }
        _applyVoice(words, language);
      },
    );
  }

  /// Mette nel foglio quello che si e' capito.
  ///
  /// ⚑ Con confidenza zero la frase intera va nel nome, cosi' com'e': il ripiego non e' mai
  /// un errore (F4.12). Quantita' e unita' cambiano solo se la frase le dice.
  void _applyVoice(String words, String language) {
    final parsed = VoiceItemParser(locale: language).parse(words);
    final name = parsed.name.isEmpty ? words.trim() : parsed.name;
    _name
      ..text = name
      ..selection = TextSelection.collapsed(offset: name.length);
    setState(() {
      _listening = false;
      d.setName(name);
      if (parsed.quantity != null && parsed.unit != null) {
        d
          ..unit = parsed.unit!
          ..quantity = parsed.quantity!;
      }
    });
    unawaited(_onName(name));
  }

  Future<void> _save() async {
    if (!d.isValid || _saving) return;
    setState(() => _saving = true);
    await ref.read(repositoryProvider).addItem(d.toNewItem());
    _handedOff = true;
    final settings = ref.read(settingsProvider);
    await settings.setInt(FreezerSettingKeys.lastFreezer, d.freezerId);
    if (d.compartmentId == null) {
      await settings.remove(FreezerSettingKeys.lastCompartment);
    } else {
      await settings.setInt(FreezerSettingKeys.lastCompartment, d.compartmentId!);
    }
    await settings.setString(FreezerSettingKeys.lastUnit, d.unit);
    if (!mounted) return;
    final l = L.of(context);
    final name = d.name.trim();
    Navigator.of(context).pop();
    MicroSnack.success(context, l.quickAdd_saved(name));
  }

  void _moreDetails() {
    _handedOff = true;
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    unawaited(router.push(Routes.itemNew, extra: d));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final freezers = ref.watch(freezersProvider).value ?? const <Freezer>[];
    final compartments = ref.watch(compartmentsByFreezerProvider).value ?? const <int, List<Compartment>>{};
    final items = ref.watch(storedItemsProvider).value ?? const <Item>[];
    final freezer = freezers.where((f) => f.id == d.freezerId).firstOrNull;
    final compartment =
        (compartments[d.freezerId] ?? const <Compartment>[]).where((c) => c.id == d.compartmentId).firstOrNull;

    // Il riempimento DOPO l'inserimento: e' la frase che fa capire la capienza.
    final after = freezer == null
        ? null
        : const CapacityEstimator().fill(
            capacityLiters: freezer.capacityLiters,
            calibration: freezer.calibration,
            itemLiters: [
              for (final i in items) if (i.freezerId == freezer.id) i.volumeLiters,
              d.volumeLiters,
            ],
          );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(MicroSpacing.l, 0, MicroSpacing.l, MicroSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.quickAdd_title, style: text.titleLarge),
              MicroSpacing.gapM,
              TextField(
                controller: _name,
                // La tastiera e' gia' aperta: scrivere e' la prima cosa che si fa (F4.5).
                autofocus: true,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l.quickAdd_nameLabel,
                  hintText: _listening ? l.voice_listening : l.quickAdd_nameHint,
                  counterText: '',
                  // La foto e' facoltativa e non aggiunge tocchi al percorso minimo (F4.5).
                  // Microfono e foto: tutti e due facoltativi, nessuno aggiunge tocchi al
                  // percorso minimo (F4.5).
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: _listening ? l.voice_stop : l.voice_start,
                        icon: Icon(_listening ? Icons.mic : Icons.mic_none_outlined),
                        color: _listening ? scheme.error : null,
                        onPressed: () => unawaited(_toggleVoice()),
                      ),
                      if (d.photoPath == null)
                        IconButton(
                          tooltip: l.photo_add,
                          icon: const Icon(Icons.photo_camera_outlined),
                          onPressed: () async {
                            final added = await pickItemPhoto(context, ref);
                            if (added != null) setState(() => d.photoPath = added);
                          },
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: ItemPhotoThumb(
                            photoPath: d.photoPath!,
                            size: 36,
                            radius: 8,
                            fallback: const Icon(Icons.photo_outlined),
                          ),
                        ),
                    ],
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: categoryGlyph(d.category),
                  ),
                ),
                onChanged: (v) => unawaited(_onName(v)),
                onSubmitted: (_) => unawaited(_save()),
              ),
              if (_suggestions.isNotEmpty) ...[
                MicroSpacing.gapS,
                Wrap(
                  spacing: MicroSpacing.s,
                  runSpacing: MicroSpacing.xs,
                  children: [
                    for (final s in _suggestions)
                      ActionChip(
                        avatar: const Icon(Icons.history, size: 18),
                        label: Text(s),
                        onPressed: () => _useSuggestion(s),
                      ),
                  ],
                ),
              ],
              MicroSpacing.gapM,
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: l.quickAdd_less,
                    icon: const Icon(Icons.remove),
                    onPressed: d.quantity - quantityStep(d.unit) > 0
                        ? () => setState(() => d.quantity -= quantityStep(d.unit))
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      '${formatQuantity(d.quantity, locale)} ${unitName(l, d.unit, d.quantity)}',
                      textAlign: TextAlign.center,
                      style: text.titleLarge,
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: l.quickAdd_more,
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => d.quantity += quantityStep(d.unit)),
                  ),
                ],
              ),
              MicroSpacing.gapS,
              Wrap(
                spacing: MicroSpacing.s,
                runSpacing: MicroSpacing.xs,
                alignment: WrapAlignment.center,
                children: [
                  for (final u in Units.all)
                    ChoiceChip(
                      label: Text(unitName(l, u, 2)),
                      selected: d.unit == u,
                      onSelected: (_) => setState(() {
                        if (d.unit != u) d.quantity = defaultQuantity(u);
                        d.unit = u;
                      }),
                    ),
                ],
              ),
              MicroSpacing.gapM,
              _InfoRow(
                icon: Icons.kitchen_outlined,
                label: compartment == null ? (freezer?.name ?? '') : '${freezer?.name} · ${compartment.name}',
                onTap: freezers.length > 1 || (compartments[d.freezerId] ?? const []).isNotEmpty
                    ? () async {
                        final picked = await pickLocation(
                          context,
                          freezers: freezers,
                          compartments: compartments,
                          freezerId: d.freezerId,
                          compartmentId: d.compartmentId,
                        );
                        if (picked != null) {
                          setState(() {
                            d.freezerId = picked.freezerId;
                            d.compartmentId = picked.compartmentId;
                          });
                        }
                      }
                    : null,
              ),
              _InfoRow(
                icon: Icons.inventory_2_outlined,
                label: after == null
                    ? formatLiters(d.volumeLiters, locale)
                    : l.quickAdd_volumeLine(formatLiters(d.volumeLiters, locale), after.percent),
                color: after != null && after.fraction >= 0.85 ? scheme.danger : null,
                onTap: () async {
                  final choice = await pickSize(
                    context,
                    quantity: d.quantity,
                    estimate: const CapacityEstimator().estimateLiters(
                      quantity: d.quantity,
                      unit: d.unit,
                      categoryKey: d.category,
                    ),
                    manual: d.volumeManual,
                  );
                  if (choice == null) return;
                  setState(() {
                    switch (choice) {
                      case SizeLiters(:final liters):
                        d.setManualVolume(liters);
                      case SizeAuto():
                        d.resetVolume();
                    }
                  });
                },
              ),
              MicroSpacing.gapL,
              // Interfaccia "Ghiaccio": il salvataggio e' il pulsante largo, come "Metti nel
              // freezer" in home; "Altri dettagli" e' la via secondaria, sopra, in piccolo.
              Center(child: TextButton(onPressed: _moreDetails, child: Text(l.quickAdd_moreDetails))),
              MicroSpacing.gapS,
              MicroPrimaryButton(
                label: l.common_save,
                icon: Icons.ac_unit,
                loading: _saving,
                onPressed: d.isValid ? () => unawaited(_save()) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: MicroRadius.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MicroSpacing.s),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? scheme.mutedText),
            MicroSpacing.hGapM,
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right, color: scheme.mutedText),
          ],
        ),
      ),
    );
  }
}

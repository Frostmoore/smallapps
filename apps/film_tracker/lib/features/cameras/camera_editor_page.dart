import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../data/database.dart';
import '../../domain/film_types.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/pro_gate.dart';

/// La rotta di creazione di una macchina (`Routes.cameraNew`), protetta sulla pagina:
/// senza il Pro, con gia' una macchina, mostra il lucchetto di [ProGate] invece del modulo.
///
/// ⚑ **Perche' un widget e non il solo `ProGate` nel router** (come la fonte nuova di Scorte
/// Calore): li' `allowed` legge il conteggio con `ref.read(...).value`, che e' null finche'
/// lo stream non e' arrivato, cioe' "zero macchine", cioe' via libera. Qui si **aspetta** il
/// conteggio e lo si **congela** all'apertura: dopo il salvataggio le macchine diventano
/// due, e un conteggio vivo farebbe lampeggiare il lucchetto sulla pagina che si sta
/// chiudendo. Se il Pro arriva mentre la pagina e' aperta, `ProGate` si ridisegna da solo.
class NewCameraGate extends ConsumerStatefulWidget {
  const NewCameraGate({super.key});

  @override
  ConsumerState<NewCameraGate> createState() => _NewCameraGateState();
}

class _NewCameraGateState extends ConsumerState<NewCameraGate> {
  int? _countAtOpen;

  @override
  Widget build(BuildContext context) {
    if (_countAtOpen == null) {
      final count = ref.watch(cameraCountProvider).value;
      if (count == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      _countAtOpen = count;
    }
    final count = _countAtOpen!;
    return ProGate(
      feature: FeatureKey.secondaryEntities,
      allowed: (gate) => gate.withinLimit(FeatureKey.secondaryEntities, count),
      child: const CameraEditorPage(),
    );
  }
}

/// Una macchina fotografica, nuova ([cameraId] null) o esistente (F6.5).
///
/// Campi: produttore, modello, formato, nota. **Nient'altro**, di proposito (F6.5: "non deve
/// diventare un'app per collezionisti"). Salvando una macchina nuova la pagina si chiude
/// restituendo il suo id (`context.push<int>(Routes.cameraNew)`): il form del rullino la
/// seleziona subito.
class CameraEditorPage extends ConsumerStatefulWidget {
  const CameraEditorPage({this.cameraId, super.key});

  /// Null per una macchina nuova.
  final int? cameraId;

  @override
  ConsumerState<CameraEditorPage> createState() => _CameraEditorPageState();
}

class _CameraEditorPageState extends ConsumerState<CameraEditorPage> {
  final _manufacturer = TextEditingController();
  final _model = TextEditingController();
  final _note = TextEditingController();
  FilmFormat _format = FilmFormat.mm35;
  Camera? _camera;

  /// Null finche' non si e' letto; false se la macchina non esiste (cancellata, link vecchio).
  bool? _found;
  bool _saving = false;

  bool get _isNew => widget.cameraId == null;

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      _found = true;
    } else {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final c = await ref.read(repositoryProvider).cameraById(widget.cameraId!);
    if (!mounted) return;
    setState(() {
      _found = c != null;
      if (c == null) return;
      _camera = c;
      _manufacturer.text = c.manufacturer;
      _model.text = c.model;
      _note.text = c.note ?? '';
      _format = FilmFormat.byKey(c.format) ?? FilmFormat.other;
    });
  }

  @override
  void dispose() {
    for (final c in [_manufacturer, _model, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => _manufacturer.text.trim().isNotEmpty && _model.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final old = _camera;
    final int id;
    if (old == null) {
      id = await repo.addCamera(
        manufacturer: _manufacturer.text,
        model: _model.text,
        format: _format,
        note: _note.text,
      );
    } else {
      await repo.updateCamera(
        old.copyWith(
          manufacturer: _manufacturer.text.trim(),
          model: _model.text.trim(),
          format: _format.key,
          note: Value(_note.text),
        ),
      );
      id = old.id;
    }
    if (!mounted) return;
    // Se la pagina non si puo' chiudere (e' la prima della pila) torna modificabile.
    final closed = await Navigator.of(context).maybePop(id);
    if (!closed && mounted) setState(() => _saving = false);
  }

  Future<void> _delete() async {
    final l = L.of(context);
    final repo = ref.read(repositoryProvider);
    final rolls = (await repo.rollCountByCamera())[widget.cameraId] ?? 0;
    if (!mounted) return;
    final ok = await MicroConfirmSheet.show(
      context,
      title: l.camera_deleteTitle('${_manufacturer.text.trim()} ${_model.text.trim()}'),
      // ⚑ L'avviso dice cosa succede ai rullini: restano, senza macchina (setNull). Chi
      // vende una macchina non deve temere di perdere la storia dei rullini che ha scattato.
      message: rolls == 0 ? l.camera_deleteBodyNoRolls : l.camera_deleteBody(rolls),
      confirmLabel: l.common_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await repo.deleteCamera(widget.cameraId!);
    if (!mounted) return;
    MicroSnack.show(context, l.camera_deleted);
    await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final text = Theme.of(context).textTheme;
    final found = _found;
    if (found == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!found) {
      return Scaffold(
        appBar: AppBar(),
        body: MicroEmptyState(icon: Icons.help_outline, title: l.camera_missingTitle, message: l.camera_missingBody),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l.camera_newTitle : l.camera_editTitle),
        actions: [
          if (!_isNew)
            IconButton(tooltip: l.common_delete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          TextField(
            key: const ValueKey('camera_manufacturer'),
            controller: _manufacturer,
            autofocus: _isNew,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            decoration: InputDecoration(labelText: l.camera_manufacturer, hintText: l.camera_manufacturerHint),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            key: const ValueKey('camera_model'),
            controller: _model,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            decoration: InputDecoration(labelText: l.camera_model, hintText: l.camera_modelHint),
            onChanged: (_) => setState(() {}),
          ),
          MicroSpacing.gapS,
          Text(l.camera_format, style: text.titleSmall),
          MicroSpacing.gapS,
          Wrap(
            spacing: MicroSpacing.s,
            runSpacing: MicroSpacing.s,
            children: [
              for (final f in FilmFormat.values)
                ChoiceChip(
                  label: Text(formatName(l, f)),
                  selected: f == _format,
                  onSelected: (_) => setState(() => _format = f),
                ),
            ],
          ),
          MicroSpacing.gapL,
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(labelText: l.camera_note, helperText: l.common_optional),
          ),
          MicroSpacing.gapXL,
          MicroPrimaryButton(
            label: l.common_save,
            loading: _saving,
            onPressed: _valid && !_saving ? () => unawaited(_save()) : null,
          ),
        ],
      ),
    );
  }
}

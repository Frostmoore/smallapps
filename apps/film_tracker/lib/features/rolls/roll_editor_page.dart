import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../domain/film_types.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/film_strip.dart';
import '../stocks/custom_stock_sheet.dart';

/// Creazione e modifica di un rullino (F6.6).
///
/// L'ordine dei campi e' quello del piano: pellicola → macchina → ISO esposto (preimpostato
/// al nominale) → fotogrammi (preimpostati dal formato) → data di caricamento. Titolo, nota e
/// costo stanno sotto, in "Dettagli facoltativi": chi carica un rullino al volo li salta.
///
/// ⚑ **Una pagina sola e non una procedura a passi**: i campi obbligatori sono uno (la
/// pellicola), gli altri arrivano gia' giusti. Cinque schermate con "Avanti" farebbero
/// sembrare lunga una cosa che si fa in cinque secondi (stessa scelta di Scorte Calore).
///
/// ⚑ **I preimpostati seguono le scelte finche' l'utente non li tocca**: cambiare pellicola
/// riporta l'ISO al nominale nuovo, cambiare macchina riporta formato e fotogrammi a quelli
/// della macchina. Un campo modificato a mano invece resta: sovrascriverlo sarebbe perdere
/// quello che l'utente ha scritto.
class RollEditorPage extends ConsumerStatefulWidget {
  const RollEditorPage({this.rollId, super.key});

  /// Null per un rullino nuovo.
  final int? rollId;

  @override
  ConsumerState<RollEditorPage> createState() => _RollEditorPageState();
}

class _RollEditorPageState extends ConsumerState<RollEditorPage> {
  final _iso = TextEditingController();
  final _frames = TextEditingController();
  final _title = TextEditingController();
  final _note = TextEditingController();
  final _cost = TextEditingController();

  /// Il rullino com'era, in modifica: `updateRoll` riceve una sua copia.
  FilmRoll? _original;

  int? _filmStockId;
  String _filmName = '';
  int? _nominalIso;
  int? _cameraId;
  String? _cameraName;
  FilmFormat _format = FilmFormat.mm35;
  CivilDate? _loadedAt;
  CivilDate? _finishedAt;

  /// L'utente ha scritto a mano l'ISO o i fotogrammi: da li' in poi non si preimpostano piu'.
  bool _isoTouched = false;
  bool _framesTouched = false;

  bool _loaded = false;

  /// Il rullino da modificare non c'e' (id illeggibile o cancellato nel frattempo).
  bool _missing = false;
  bool _saving = false;

  bool get _isNew => widget.rollId == null;

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      _loadedAt = ref.read(todayProvider);
      _frames.text = '${_format.defaultFrames}';
      _loaded = true;
    } else {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final repo = ref.read(repositoryProvider);
    final r = await repo.rollById(widget.rollId!);
    if (!mounted) return;
    if (r == null) {
      // ☠ Senza questo la pagina restava sulla rotellina per sempre (trovato con l'atlante,
      //   2026-10-08): `_loaded` non diventava mai vero.
      setState(() => _missing = true);
      return;
    }
    final camera = r.cameraId == null ? null : await repo.cameraById(r.cameraId!);
    if (!mounted) return;
    final locale = Localizations.localeOf(context).toLanguageTag();
    setState(() {
      _original = r;
      _filmStockId = r.filmStockId;
      _filmName = r.filmName;
      _nominalIso = r.nominalIso;
      _cameraId = r.cameraId;
      _cameraName = camera?.displayName;
      _format = r.formatEnum;
      _loadedAt = r.loadedDate;
      _finishedAt = r.finishedDate;
      _iso.text = '${r.exposedIso}';
      _frames.text = '${r.frames}';
      _title.text = r.title ?? '';
      _note.text = r.note ?? '';
      _cost.text = r.costCents == null ? '' : Money.cents(r.costCents!).formatPlain(locale: locale);
      // In modifica i valori sono dell'utente: non si preimpostano piu'.
      _isoTouched = r.exposedIso != r.nominalIso;
      _framesTouched = r.frames != r.formatEnum.defaultFrames;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    for (final c in [_iso, _frames, _title, _note, _cost]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Scelte ────────────────────────────────────────────────────────────────

  void _setStock(FilmStock s) => setState(() {
    _filmStockId = s.id;
    _filmName = s.displayName;
    _nominalIso = s.iso;
    if (!_isoTouched) _iso.text = '${s.iso}';
    // Il formato lo decide la macchina, se c'e'; altrimenti quello della pellicola.
    if (_cameraId == null) _setFormat(s.formatEnum);
  });

  void _setCamera(Camera? c) => setState(() {
    _cameraId = c?.id;
    _cameraName = c?.displayName;
    if (c != null) _setFormat(c.formatEnum);
  });

  /// Cambia formato e, se l'utente non li ha toccati, i fotogrammi. Da chiamare in setState.
  void _setFormat(FilmFormat f) {
    _format = f;
    if (!_framesTouched) _frames.text = '${f.defaultFrames}';
  }

  Future<void> _pickStock() async {
    final s = await showModalBottomSheet<FilmStock>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _StockPickerSheet(selectedId: _filmStockId),
    );
    if (s != null && mounted) _setStock(s);
  }

  Future<void> _pickCamera() async {
    final pick = await showModalBottomSheet<_CameraPick>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _CameraPickerSheet(selectedId: _cameraId),
    );
    if (pick != null && mounted) _setCamera(pick.camera);
  }

  Future<void> _pickDate({required bool finished}) async {
    final today = ref.read(todayProvider);
    final current = (finished ? _finishedAt : _loadedAt) ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.toLocalMidnight(),
      firstDate: DateTime(1950),
      lastDate: today.addYears(1).toLocalMidnight(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final d = CivilDate.fromDateTime(picked);
      if (finished) {
        _finishedAt = d;
      } else {
        _loadedAt = d;
      }
    });
  }

  // ── Salvataggio ───────────────────────────────────────────────────────────

  int? get _isoValue {
    final v = int.tryParse(_iso.text.trim());
    return v != null && v >= 1 && v <= 100000 ? v : null;
  }

  int? get _framesValue {
    final v = int.tryParse(_frames.text.trim());
    return v != null && v >= 1 && v <= 1000 ? v : null;
  }

  /// Il costo in centesimi; null se vuoto. ⚑ `Money.tryParse` accetta "6,50", "6.50 €" e
  /// "1.234,56": chi scrive il prezzo come lo legge sullo scontrino non deve correggerlo.
  int? get _costCents => _cost.text.trim().isEmpty ? null : Money.tryParse(_cost.text)?.cents;

  bool get _costValid => _cost.text.trim().isEmpty || (_costCents != null && _costCents! >= 0);

  bool get _valid =>
      _filmName.trim().isNotEmpty &&
      _nominalIso != null &&
      _isoValue != null &&
      _framesValue != null &&
      _costValid;

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final l = L.of(context);
    final repo = ref.read(repositoryProvider);
    try {
      if (_isNew) {
        final id = await repo.addRoll(
          filmStockId: _filmStockId,
          filmName: _filmName,
          format: _format,
          nominalIso: _nominalIso!,
          exposedIso: _isoValue,
          cameraId: _cameraId,
          loadedAt: _loadedAt,
          frames: _framesValue!,
          title: _title.text,
          note: _note.text,
          costCents: _costCents,
        );
        // ⚑ Dopo la creazione si va al dettaglio, non alla home: il passo successivo
        // (foto, QR da attaccare al contenitore) si fa li'.
        if (mounted) context.pushReplacement(Routes.rollOf(id));
      } else {
        await repo.updateRoll(
          _original!.copyWith(
            filmStockId: Value(_filmStockId),
            filmName: _filmName,
            format: _format.key,
            nominalIso: _nominalIso,
            exposedIso: _isoValue,
            cameraId: Value(_cameraId),
            loadedAt: Value(_loadedAt?.toIso()),
            finishedAt: Value(_finishedAt?.toIso()),
            frames: _framesValue,
            title: Value(_title.text),
            note: Value(_note.text),
            costCents: Value(_costCents),
          ),
        );
        if (mounted) context.pop();
      }
    } on Object catch (e, st) {
      // Il caso atteso e' il CHECK `finishedAt >= loadedAt` dello schema.
      MicroLog.e('salvataggio rullino', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _saving = false);
      MicroSnack.error(context, l.roll_saveError);
    }
  }

  // ── Pagina ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.mutedText;
    if (_missing) {
      return Scaffold(
        appBar: AppBar(),
        body: MicroEmptyState(icon: Icons.search_off, title: l.roll_notFound, message: ''),
      );
    }
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? l.roll_newTitle : l.roll_editTitle)),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          // 1. Pellicola
          _FieldTile(
            key: const ValueKey('roll-film'),
            icon: Icons.camera_roll_outlined,
            label: l.roll_film,
            value: _filmName.isEmpty ? null : _filmName,
            placeholder: l.roll_filmChoose,
            onTap: () => unawaited(_pickStock()),
          ),
          // 2. Macchina (facoltativa)
          _FieldTile(
            key: const ValueKey('roll-camera'),
            icon: Icons.photo_camera_outlined,
            label: l.roll_camera,
            value: _cameraName,
            placeholder: l.roll_cameraNone,
            onTap: () => unawaited(_pickCamera()),
          ),
          MicroSpacing.gapM,
          Text(l.roll_format, style: theme.textTheme.titleSmall),
          MicroSpacing.gapS,
          Wrap(
            spacing: MicroSpacing.s,
            runSpacing: MicroSpacing.s,
            children: [
              for (final f in FilmFormat.values)
                ChoiceChip(
                  label: Text(formatName(l, f)),
                  selected: f == _format,
                  onSelected: (_) => setState(() => _setFormat(f)),
                ),
            ],
          ),
          MicroSpacing.gapL,
          // 3. ISO esposto
          TextField(
            key: const ValueKey('roll-iso'),
            controller: _iso,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l.roll_exposedIso,
              helperText: _nominalIso == null ? null : l.roll_exposedIsoHelp(_nominalIso!),
            ),
            onChanged: (_) => setState(() => _isoTouched = true),
          ),
          MicroSpacing.gapL,
          // 4. Fotogrammi
          TextField(
            key: const ValueKey('roll-frames'),
            controller: _frames,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l.roll_frames),
            onChanged: (_) => setState(() => _framesTouched = true),
          ),
          MicroSpacing.gapM,
          // 5. Data di caricamento
          _FieldTile(
            icon: Icons.event_outlined,
            label: l.roll_loadedAt,
            value: _loadedAt == null ? null : formatDay(l, _loadedAt!),
            placeholder: l.roll_noDate,
            onTap: () => unawaited(_pickDate(finished: false)),
          ),
          // In modifica, la fine si corregge qui ("Rullino terminato" mette la data di oggi).
          if (!_isNew && _finishedAt != null)
            _FieldTile(
              icon: Icons.event_available_outlined,
              label: l.roll_finishedAt,
              value: formatDay(l, _finishedAt!),
              placeholder: l.roll_noDate,
              onTap: () => unawaited(_pickDate(finished: true)),
            ),
          MicroSpacing.gapXL,
          Text(l.roll_details, style: theme.textTheme.titleSmall?.copyWith(color: muted)),
          MicroSpacing.gapS,
          TextField(
            controller: _title,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.roll_title, hintText: l.roll_titleHint),
          ),
          TextField(
            controller: _cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.roll_cost,
              suffixText: '€',
              errorText: _costValid ? null : l.roll_costInvalid,
            ),
            onChanged: (_) => setState(() {}),
          ),
          MicroSpacing.gapL,
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.roll_note),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(MicroSpacing.l, 0, MicroSpacing.l, MicroSpacing.l),
        child: FilledButton(
          key: const ValueKey('roll-save'),
          onPressed: _valid && !_saving ? () => unawaited(_save()) : null,
          child: Text(l.common_save),
        ),
      ),
    );
  }
}

/// Una riga del form che si tocca per scegliere: etichetta sopra, valore (o invito) sotto.
class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: theme.textTheme.bodySmall),
      subtitle: Text(
        value ?? placeholder,
        style: theme.textTheme.titleMedium?.copyWith(
          color: value == null ? theme.colorScheme.primary : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ── Scelta della pellicola ──────────────────────────────────────────────────

/// Il foglio della pellicola: le cinque piu' usate in cima, la ricerca nel catalogo
/// raggruppato per marca, e "Pellicola personalizzata" (F6.4).
///
/// ⚑ "Pellicola personalizzata" apre il foglio del catalogo (`showCustomStockSheet`, scritto
/// con la pagina delle pellicole) e non un form suo: un solo posto crea le pellicole, con la
/// stessa gestione dei doppioni (restituisce l'id di quella che c'era gia').
class _StockPickerSheet extends ConsumerStatefulWidget {
  const _StockPickerSheet({required this.selectedId});

  final int? selectedId;

  @override
  ConsumerState<_StockPickerSheet> createState() => _StockPickerSheetState();
}

class _StockPickerSheetState extends ConsumerState<_StockPickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _custom() async {
    final id = await showCustomStockSheet(context, ref);
    if (id == null || !mounted) return;
    final stock = await ref.read(repositoryProvider).stockById(id);
    if (stock != null && mounted) Navigator.of(context).pop(stock);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final all = ref.watch(filmStocksProvider).value ?? const <FilmStock>[];
    final mostUsed = ref.watch(mostUsedStocksProvider).value ?? const <FilmStock>[];
    final q = _query.text.trim().toLowerCase();
    final found = q.isEmpty
        ? all
        : [
            for (final s in all)
              if (s.displayName.toLowerCase().contains(q)) s,
          ];

    // Raggruppate per marca, nell'ordine del repository (marca, nome).
    final byBrand = <String, List<FilmStock>>{};
    for (final s in found) {
      (byBrand[s.brand] ??= []).add(s);
    }

    Widget tile(FilmStock s) => ListTile(
      key: ValueKey('stock-${s.id}'),
      title: Text(s.displayName),
      subtitle: Text('ISO ${s.iso} · ${processName(l, s.processEnum)}'),
      trailing: s.id == widget.selectedId ? const Icon(Icons.check) : null,
      onTap: () => Navigator.of(context).pop(s),
    );

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(MicroSpacing.l, MicroSpacing.l, MicroSpacing.l, 0),
      child: SectionLabel(text),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scroll) => ListView(
        controller: scroll,
        children: [
          Padding(
            padding: MicroSpacing.pageH,
            child: TextField(
              controller: _query,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.roll_stockSearch,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: Text(l.roll_stockCustom),
            subtitle: Text(l.roll_stockCustomHelp),
            onTap: () => unawaited(_custom()),
          ),
          if (q.isEmpty && mostUsed.isNotEmpty) ...[
            header(l.roll_stockMostUsed),
            for (final s in mostUsed) tile(s),
          ],
          if (found.isEmpty)
            Padding(
              padding: MicroSpacing.card,
              child: Text(
                l.roll_stockNoResults(_query.text.trim()),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.mutedText),
              ),
            ),
          for (final entry in byBrand.entries) ...[
            header(entry.key),
            for (final s in entry.value) tile(s),
          ],
          MicroSpacing.gapXL,
        ],
      ),
    );
  }
}

// ── Scelta della macchina ───────────────────────────────────────────────────

/// Il risultato del foglio della macchina. ⚑ Un oggetto e non `Camera?`: "nessuna macchina"
/// (una scelta) e "foglio chiuso" (nessuna scelta) devono restare distinguibili.
class _CameraPick {
  const _CameraPick(this.camera);

  final Camera? camera;
}

/// Il foglio della macchina: facoltativa. Senza macchine offre di crearne una.
class _CameraPickerSheet extends ConsumerWidget {
  const _CameraPickerSheet({required this.selectedId});

  final int? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final cameras = ref.watch(activeCamerasProvider).value;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.block),
            title: Text(l.roll_cameraNone),
            trailing: selectedId == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(context).pop(const _CameraPick(null)),
          ),
          if (cameras == null)
            const Padding(padding: MicroSpacing.card, child: LinearProgressIndicator())
          else if (cameras.isEmpty) ...[
            Padding(
              padding: MicroSpacing.card,
              child: Text(
                l.roll_cameraEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.mutedText),
              ),
            ),
            Padding(
              padding: MicroSpacing.pageH,
              // La macchina appena creata si sceglie da sola: chi la crea da qui la vuole
              // per questo rullino (prima andava toccata a mano, trovato con l'atlante).
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  final id = await context.push<int>(Routes.cameraNew);
                  if (id == null) return;
                  final nuova = await ref.read(repositoryProvider).cameraById(id);
                  if (nuova != null && context.mounted) Navigator.of(context).pop(_CameraPick(nuova));
                },
                icon: const Icon(Icons.add),
                label: Text(l.roll_cameraAdd),
              ),
            ),
            MicroSpacing.gapL,
          ] else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in cameras)
                    ListTile(
                      leading: const Icon(Icons.photo_camera_outlined),
                      title: Text(c.displayName),
                      subtitle: Text(formatName(l, c.formatEnum)),
                      trailing: c.id == selectedId ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.of(context).pop(_CameraPick(c)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

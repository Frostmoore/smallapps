import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/qr_palette.dart';
import '../../app/routes.dart';
import '../../domain/contrast.dart';
import '../../domain/qr_style.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/readability_check.dart';
import '../common/neon.dart';
import 'logo_picker.dart';

/// I 12 colori pronti, per il primo piano e per lo sfondo (F17.1.6). ⚑ Scuri e chiari insieme:
/// la stessa fila serve ai due campi, e la scelta "sbagliata" (chiaro su chiaro) la segnalano
/// gli avvisi di contrasto invece di impedirla.
const List<int> kSwatches = [
  0xFF000000, 0xFFFFFFFF, 0xFF1B2A4A, 0xFF1565C0, 0xFF00796B, 0xFF2E7D32, //
  0xFF3BD13B, 0xFFC62828, 0xFF6A1B9A, 0xFFE65100, 0xFF5D4037, 0xFFFFF3C4,
];

/// Dopo quanto dall'ultima modifica si rifa' la verifica di leggibilita' (F17.1.6). ⚑ Non a
/// ogni tocco: la verifica genera un PNG e lo passa allo scanner, e trascinando fra i colori
/// partirebbero dieci verifiche di cui nove inutili.
const Duration kReadabilityDelay = Duration(milliseconds: 600);

/// Lo stile del QR (Pro, `themeCustomization`; il `ProGate` e' sulla rotta): anteprima grande,
/// colori, forme, logo, avvisi di contrasto e la verifica vera di leggibilita'
/// (develop_microapps.md F17.1.6).
///
/// «Applica» scrive lo stile sulla riga se il QR e' salvato (cronologia o preferito), e torna
/// indietro restituendo lo stile (la pagina del QR in memoria lo usa).
class StylePage extends ConsumerStatefulWidget {
  const StylePage({required this.args, super.key});

  final StyleArgs args;

  @override
  ConsumerState<StylePage> createState() => _StylePageState();
}

class _StylePageState extends ConsumerState<StylePage> {
  late QrStyle _style = widget.args.display.style;
  Readability? _readability;
  Timer? _debounce;
  int _checkSeq = 0;

  String get _payload => widget.args.display.payload;

  @override
  void initState() {
    super.initState();
    _scheduleCheck();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _update(QrStyle style) {
    setState(() {
      _style = style;
      _readability = null;
    });
    _scheduleCheck();
  }

  void _scheduleCheck() {
    _debounce?.cancel();
    _debounce = Timer(kReadabilityDelay, () => unawaited(_check()));
  }

  Future<void> _check() async {
    // ☠ Il numero di sequenza: una verifica lenta partita prima di una modifica non deve
    // sovrascrivere l'esito di quella partita dopo.
    final seq = ++_checkSeq;
    final style = _style;
    final logo = await ref.read(logoImageProvider(logoKeyOf(style)).future);
    final result = await ref
        .read(readabilityCheckProvider)
        .check(payload: _payload, style: style, logo: logo);
    if (mounted && seq == _checkSeq) setState(() => _readability = result);
  }

  Future<void> _apply() async {
    final id = widget.args.qrId;
    if (id != null) await ref.read(repositoryProvider).updateStyle(id, _style);
    if (mounted) context.pop(_style);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    final renderer = ref.watch(qrRendererProvider);
    final choice = renderer.choose(_payload, _style);
    final logo = ref.watch(logoImageProvider(logoKeyOf(_style))).value;
    final ratio = Contrast.ratio(_style.foreground, _style.background);
    final inverted = Contrast.inverted(_style.foreground, _style.background);

    return Scaffold(
      appBar: AppBar(title: Text(l.style_title)),
      // ⚑ L'anteprima e la riga di verifica restano ferme in alto e si scorre solo il resto:
      // cambiando il colore o il logo in fondo alla pagina si deve vedere l'effetto (sull'emulatore,
      // con l'anteprima nella lista, scegliendo il logo il QR era gia' fuori schermo).
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MicroSpacing.l,
              MicroSpacing.m,
              MicroSpacing.l,
              MicroSpacing.s,
            ),
            child: Column(
              children: [
                QrPanel(
                  background: Color(_style.background),
                  padding: 12,
                  child: choice.tooLong
                      ? const SizedBox.square(dimension: 150)
                      : renderer.widget(payload: _payload, style: _style, size: 150, logo: logo),
                ),
                MicroSpacing.gapM,
                _ReadabilityRow(readability: _readability),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: MicroSpacing.page,
              children: [
                if (ratio < Contrast.minRatio)
                  _Warning(
                    key: const ValueKey('warn_contrast'),
                    text: l.style_lowContrast,
                    color: Theme.of(context).colorScheme.error,
                  ),
                if (inverted)
                  _Warning(
                    key: const ValueKey('warn_inverted'),
                    text: l.style_inverted,
                    color: Theme.of(context).colorScheme.warning,
                  ),
                if (choice.logoDropped)
                  _Warning(
                    text: l.display_logoDropped,
                    color: Theme.of(context).colorScheme.warning,
                  ),
                SectionLabel(l.style_foreground),
                _ColorRow(
                  prefix: 'fg',
                  value: _style.foreground,
                  onChanged: (c) => _update(_style.copyWith(foreground: c)),
                ),
                SectionLabel(l.style_background),
                _ColorRow(
                  prefix: 'bg',
                  value: _style.background,
                  onChanged: (c) => _update(_style.copyWith(background: c)),
                ),
                SectionLabel(l.style_modules),
                SegmentedButton<QrModuleShape>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: QrModuleShape.square,
                      label: Text(l.style_square),
                      icon: const Icon(Icons.crop_square),
                    ),
                    ButtonSegment(
                      value: QrModuleShape.circle,
                      label: Text(l.style_round),
                      icon: const Icon(Icons.circle_outlined),
                    ),
                  ],
                  selected: {_style.moduleShape},
                  onSelectionChanged: (s) => _update(_style.copyWith(moduleShape: s.first)),
                ),
                SectionLabel(l.style_eyes),
                SegmentedButton<QrEyeShape>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: QrEyeShape.square,
                      label: Text(l.style_square),
                      icon: const Icon(Icons.crop_square),
                    ),
                    ButtonSegment(
                      value: QrEyeShape.circle,
                      label: Text(l.style_round),
                      icon: const Icon(Icons.circle_outlined),
                    ),
                  ],
                  selected: {_style.eyeShape},
                  onSelectionChanged: (s) => _update(_style.copyWith(eyeShape: s.first)),
                ),
                SectionLabel(l.style_logo),
                LogoPicker(
                  logo: _style.logo,
                  onChanged: (logo) => _update(_style.copyWith(logo: logo)),
                ),
                MicroSpacing.gapL,
                TextButton(
                  onPressed: _style.isPlain ? null : () => _update(QrStyle.plain),
                  child: Text(l.style_reset),
                ),
                MicroSpacing.gapS,
                NeonButton(
                  key: const ValueKey('style_apply'),
                  label: l.style_apply,
                  onPressed: () => unawaited(_apply()),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: MicroSpacing.s),
                  child: Text(
                    l.style_note,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: p.inkMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «✓ Leggibile» / «⚠ Non riesco a leggerlo» / «Verifica non disponibile» / «Verifico…».
class _ReadabilityRow extends StatelessWidget {
  const _ReadabilityRow({required this.readability});

  final Readability? readability;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (icon, text, color) = switch (readability) {
      null => (Icons.hourglass_empty, l.style_checking, scheme.onSurfaceVariant),
      Readability.readable => (Icons.check_circle_outline, l.style_readable, scheme.success),
      Readability.unreadable => (Icons.warning_amber, l.style_unreadable, scheme.error),
      // ⚑ Grigio e non rosso: su un emulatore senza scanner non sappiamo, e dire "illeggibile"
      // farebbe buttare uno stile buono.
      Readability.unknown => (Icons.help_outline, l.style_unknown, scheme.onSurfaceVariant),
    };
    return Row(
      key: const ValueKey('readability'),
      children: [
        Icon(icon, size: 18, color: color),
        MicroSpacing.hGapS,
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontVariations: const [FontVariation('wght', 600)],
            ),
          ),
        ),
      ],
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text, required this.color, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: MicroSpacing.s),
    padding: const EdgeInsets.all(MicroSpacing.m),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Row(
      children: [
        Icon(Icons.warning_amber, color: color, size: 20),
        MicroSpacing.hGapM,
        Expanded(
          child: Text(text, style: TextStyle(color: color)),
        ),
      ],
    ),
  );
}

/// I 12 colori pronti e il campo esadecimale.
class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.prefix, required this.value, required this.onChanged});

  final String prefix;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = QrPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in kSwatches)
              InkWell(
                key: ValueKey('${prefix}_${c.toRadixString(16)}'),
                customBorder: const CircleBorder(),
                onTap: () => onChanged(c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c == value ? p.accent : p.border,
                      width: c == value ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        MicroSpacing.gapS,
        _HexField(key: ValueKey('${prefix}_hex'), value: value, onChanged: onChanged),
      ],
    );
  }
}

/// Il colore scritto: `#RRGGBB` o `RRGGBB`. Sempre opaco (lo sfondo di un QR non e' mai
/// trasparente).
class _HexField extends StatefulWidget {
  const _HexField({required this.value, required this.onChanged, super.key});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_HexField> createState() => _HexFieldState();
}

class _HexFieldState extends State<_HexField> {
  late final _c = TextEditingController(text: _hex(widget.value));

  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// Il colore da un testo esadecimale, o null se non lo e'.
  static int? parse(String s) {
    final t = s.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(t)) return null;
    return 0xFF000000 | int.parse(t, radix: 16);
  }

  @override
  void didUpdateWidget(_HexField old) {
    super.didUpdateWidget(old);
    // Un colore scelto fra i pronti aggiorna il campo, ma non mentre l'utente sta scrivendo un
    // colore valido diverso (si perderebbe il cursore).
    if (old.value != widget.value && parse(_c.text) != widget.value) _c.text = _hex(widget.value);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _c,
    decoration: InputDecoration(labelText: L.of(context).style_hex, isDense: true),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
      LengthLimitingTextInputFormatter(7),
    ],
    onChanged: (v) {
      final c = parse(v);
      if (c != null) widget.onChanged(c);
    },
  );
}

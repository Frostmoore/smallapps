import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/qr_palette.dart';
import '../../app/routes.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/label_renderer.dart';
import '../common/neon.dart';

/// «Genera etichetta» (`/label`, Pro `imageExport`; develop_microapps.md F17.10 punto 5): il QR
/// con il suo stile (colori, logo) e del **testo sotto**, da stampare o condividere come PNG.
///
/// - Anteprima dal vivo: lo stesso [LabelPainter] che disegna il PNG, quindi identica.
/// - Testo: di partenza il titolo del QR, modificabile, una o due righe (oltre si rimpicciolisce,
///   poi si taglia con «…»). Vuoto: solo il QR.
/// - Formati: quadrata e rettangolare ([LabelFormat]).
/// - «Stampa»: il dialogo di sistema (`printing`), l'etichetta alla sua misura vera sul foglio.
/// - «Condividi immagine»: il PNG ad alta risoluzione (1200 px di larghezza) col foglio di sistema.
///
/// ⚑ Stessa chiave Pro di «Condividi immagine» (`imageExport`): e' la stessa famiglia, il QR che
/// esce dall'app. Il `ProGate` e' sulla rotta; il pulsante della pagina del QR controlla prima.
class LabelPage extends ConsumerStatefulWidget {
  const LabelPage({required this.args, super.key});

  final LabelArgs args;

  @override
  ConsumerState<LabelPage> createState() => _LabelPageState();
}

class _LabelPageState extends ConsumerState<LabelPage> {
  late final TextEditingController _text = TextEditingController(text: widget.args.title);
  LabelFormat _format = LabelFormat.square;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Il PNG dell'etichetta come si vede nell'anteprima, alla risoluzione piena.
  Future<Uint8List> _png() async {
    final d = widget.args.display;
    final logo = await ref.read(logoImageProvider(logoKeyOf(d.style)).future);
    return ref
        .read(labelRendererProvider)
        .png(
          payload: d.payload,
          style: d.style,
          text: _text.text,
          format: _format,
          logo: logo,
          fontFamily: kTitleFont,
        );
  }

  /// Un'uscita (stampa o condivisione) alla volta, con l'errore detto e scritto nel log.
  Future<void> _run(String what, Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (error, stack) {
      MicroLog.e('etichetta: $what', error: error, stackTrace: stack);
      if (mounted) MicroSnack.error(context, L.of(context).label_failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() => _run('stampa', () async {
    final png = await _png();
    final format = _format;
    final renderer = ref.read(labelRendererProvider);
    await ref
        .read(labelOutputProvider)
        .printPdf(
          name: widget.args.title,
          buildPdf: (page) => renderer.pdf(png: png, format: format, page: page),
        );
  });

  Future<void> _share() => _run('condivisione', () async {
    final png = await _png();
    await ref.read(labelOutputProvider).sharePng(png: png, title: widget.args.title);
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final d = widget.args.display;
    final logo = ref.watch(logoImageProvider(logoKeyOf(d.style))).value;
    return Scaffold(
      appBar: AppBar(title: Text(l.label_title)),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280, maxHeight: 340),
              child: AspectRatio(
                aspectRatio: _format.aspect,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: QrPalette.of(context).border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomPaint(
                      key: const ValueKey('label_preview'),
                      painter: LabelPainter(
                        renderer: ref.watch(qrRendererProvider),
                        payload: d.payload,
                        style: d.style,
                        text: _text.text,
                        logo: logo,
                        fontFamily: kTitleFont,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          MicroSpacing.gapL,
          TextField(
            key: const ValueKey('label_text'),
            controller: _text,
            minLines: 1,
            maxLines: 2,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.label_textLabel, helperText: l.label_textHelp),
          ),
          MicroSpacing.gapM,
          SegmentedButton<LabelFormat>(
            key: const ValueKey('label_format'),
            segments: [
              ButtonSegment(
                value: LabelFormat.square,
                icon: const Icon(Icons.crop_square),
                label: Text(l.label_square),
              ),
              ButtonSegment(
                value: LabelFormat.tall,
                icon: const Icon(Icons.crop_portrait),
                label: Text(l.label_tall),
              ),
            ],
            selected: {_format},
            // Come il selettore della sicurezza del Wi-Fi: l'icona del formato basta, niente spunta.
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          MicroSpacing.gapL,
          NeonButton(
            key: const ValueKey('label_print'),
            label: l.label_print,
            icon: Icons.print_outlined,
            onPressed: _busy ? null : () => unawaited(_print()),
          ),
          MicroSpacing.gapS,
          OutlinedButton.icon(
            key: const ValueKey('label_share'),
            onPressed: _busy ? null : () => unawaited(_share()),
            icon: const Icon(Icons.ios_share),
            label: Text(l.label_share),
          ),
        ],
      ),
    );
  }
}

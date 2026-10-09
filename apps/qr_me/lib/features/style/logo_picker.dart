import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/qr_palette.dart';
import '../../domain/qr_style.dart';
import '../../l10n/generated/app_localizations.dart';

/// Il catalogo delle icone pronte per il logo: id **stabile** → icona (F17.1.3).
///
/// ☠ Le chiavi devono essere **esattamente** `kLogoIconIds` del dominio (lo verifica
/// test/widget/style_page_test.dart): un id salvato in un preferito o in un backup che qui manca
/// mostrerebbe un QR senza logo. Un id pubblicato non si toglie e non si rinomina; l'icona dietro
/// un id si puo' cambiare (e' il motivo per cui si salva l'id e non il codePoint).
const Map<String, IconData> kLogoIcons = {
  'wifi': Icons.wifi,
  'phone': Icons.phone,
  'email': Icons.email,
  'sms': Icons.sms,
  'home': Icons.home,
  'work': Icons.work,
  'heart': Icons.favorite,
  'star': Icons.star,
  'shop': Icons.shopping_bag,
  'restaurant': Icons.restaurant,
  'coffee': Icons.local_cafe,
  'music': Icons.music_note,
  'camera': Icons.photo_camera,
  'link': Icons.link,
  'person': Icons.person,
  'group': Icons.group,
  'event': Icons.event,
  'location': Icons.place,
  'car': Icons.directions_car,
  'pets': Icons.pets,
  'school': Icons.school,
  'info': Icons.info,
  'gift': Icons.card_giftcard,
  'payment': Icons.payment,
};

enum _Source { none, photo, icon, text }

/// Il logo da tre fonti (F17.0 punto 5): foto dalla galleria, icona pronta, emoji o testo corto.
class LogoPicker extends ConsumerStatefulWidget {
  const LogoPicker({required this.logo, required this.onChanged, super.key});

  final QrLogo logo;
  final ValueChanged<QrLogo> onChanged;

  @override
  ConsumerState<LogoPicker> createState() => _LogoPickerState();
}

class _LogoPickerState extends ConsumerState<LogoPicker> {
  late _Source _source = switch (widget.logo) {
    NoLogo() => _Source.none,
    PhotoLogo() => _Source.photo,
    IconLogo() => _Source.icon,
    TextLogo() => _Source.text,
  };
  late final _text = TextEditingController(
    text: switch (widget.logo) {
      TextLogo(:final text) => text,
      _ => '',
    },
  );
  bool _importing = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _select(_Source s) {
    setState(() => _source = s);
    // Passando a "Nessuno" il logo sparisce subito; le altre fonti aspettano una scelta.
    if (s == _Source.none) widget.onChanged(const NoLogo());
    if (s == _Source.text && TextLogo.isValidText(_text.text)) {
      widget.onChanged(TextLogo(_text.text.trim()));
    }
  }

  Future<void> _pickPhoto() async {
    final l = L.of(context);
    final path = await ref.read(pickImageProvider)();
    if (path == null || !mounted) return;
    setState(() => _importing = true);
    final result = await ref
        .read(logoRendererProvider)
        .importPhoto(await File(path).readAsBytes(), ref.read(imageStoreProvider));
    if (!mounted) return;
    setState(() => _importing = false);
    result.fold(
      ok: (name) => widget.onChanged(PhotoLogo(imageName: name, round: _round)),
      err: (_) => MicroSnack.error(context, l.logo_photoFailed),
    );
  }

  bool get _round => switch (widget.logo) {
    PhotoLogo(:final round) => round,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_Source>(
          key: const ValueKey('logo_source'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: _Source.none, label: _SegmentLabel(l.logo_none)),
            ButtonSegment(value: _Source.photo, label: _SegmentLabel(l.logo_photo)),
            ButtonSegment(value: _Source.icon, label: _SegmentLabel(l.logo_icon)),
            ButtonSegment(value: _Source.text, label: _SegmentLabel(l.logo_text)),
          ],
          selected: {_source},
          onSelectionChanged: (s) => _select(s.first),
        ),
        MicroSpacing.gapM,
        switch (_source) {
          _Source.none => const SizedBox.shrink(),
          _Source.photo => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _importing ? null : () => unawaited(_pickPhoto()),
                icon: _importing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_outlined),
                label: Text(widget.logo is PhotoLogo ? l.logo_photoChange : l.logo_photoPick),
              ),
              if (widget.logo case PhotoLogo(:final imageName, :final round))
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.logo_round),
                  value: round,
                  onChanged: (v) => widget.onChanged(PhotoLogo(imageName: imageName, round: v)),
                ),
            ],
          ),
          _Source.icon => Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in kLogoIcons.entries)
                _IconChoice(
                  key: ValueKey('logo_icon_${e.key}'),
                  icon: e.value,
                  selected: widget.logo == IconLogo(e.key),
                  onTap: () => widget.onChanged(IconLogo(e.key)),
                ),
            ],
          ),
          _Source.text => TextField(
            key: const ValueKey('logo_text'),
            controller: _text,
            decoration: InputDecoration(labelText: l.logo_textLabel, helperText: l.logo_textHelp),
            onChanged: (v) {
              if (TextLogo.isValidText(v)) widget.onChanged(TextLogo(v.trim()));
              setState(() {});
            },
            // ⚑ Il limite e' in grafemi (una bandiera conta uno), non in caratteri: maxLength
            // di TextField conterebbe i code unit e taglierebbe un'emoji a meta'.
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                Text(
                  '${_text.text.trim().characters.length}/${TextLogo.maxGraphemes}',
                  style: TextStyle(color: p.inkMuted, fontSize: 12),
                ),
          ),
        },
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({required this.icon, required this.selected, required this.onTap, super.key});

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = QrPalette.of(context);
    return Material(
      color: selected ? p.accent : p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 44,
          child: Icon(icon, color: selected ? p.onAccent : p.ink),
        ),
      ),
    );
  }
}

/// L'etichetta di un segmento: su una riga sola, rimpicciolita se non ci sta.
///
/// ☠ Trovato in F17.7 con il testo al 130%: quattro segmenti larghi uguali su un telefono
/// medio, e «Nessuno» andava a capo a meta' parola («Nessun / o»). Rimpicciolire di poco e'
/// meglio che spezzare la parola; e il testo grande resta grande ovunque ci sia spazio.
class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, softWrap: false),
  );
}

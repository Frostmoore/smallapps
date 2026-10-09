import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/qr_palette.dart';
import '../../domain/qr_content.dart';
import '../../l10n/generated/app_localizations.dart';
import 'form_fields.dart';

/// Il modulo Wi-Fi: SSID (obbligatorio), password (obbligatoria se la rete non e' aperta),
/// sicurezza WPA / WEP / nessuna, rete nascosta (F17.1.6).
///
/// ⚑ La password si scrive nascosta con l'occhio, come la mostra la pagina del QR: chi compila
/// il modulo spesso lo fa con un ospite accanto.
///
/// ⚑ Con [pasteHelp] (la strada «La rete a cui sei connesso», F17.10 punto 1) il nome arriva gia'
/// letto dal telefono e la password **si incolla**: un bottone «Incolla la password» grande e
/// due righe su dove copiarla (iPhone: Impostazioni › Wi-Fi › (i) › Password; Android:
/// Impostazioni › Wi-Fi › Condividi). ☠ Nessuna app puo' leggere la password: incollarla e'
/// l'unica strada che non obbliga a scriverla.
class WifiForm extends QrFormWidget<WifiContent> {
  const WifiForm({required super.onChanged, super.initial, this.pasteHelp = false, super.key});

  /// Il bottone «Incolla la password» e le istruzioni per copiarla.
  final bool pasteHelp;

  @override
  State<WifiForm> createState() => _WifiFormState();
}

class _WifiFormState extends State<WifiForm> {
  late final _ssid = TextEditingController(text: widget.initial?.ssid ?? '');
  late final _password = TextEditingController(text: widget.initial?.password ?? '');
  late WifiSecurity _security = widget.initial?.security ?? WifiSecurity.wpa;
  late bool _hidden = widget.initial?.hidden ?? false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_ssid, _password]) {
      c.addListener(_emit);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    super.dispose();
  }

  void _emit() {
    if (!mounted) return;
    final l = L.of(context);
    final open = _security == WifiSecurity.none;
    final ok =
        requiredText(l, _ssid.text) == null && (open || requiredText(l, _password.text) == null);
    // ⚑ SSID e password NON si rifilano: uno spazio in coda puo' far parte del nome della rete o
    // della password, e toglierlo darebbe un QR che non si connette.
    widget.onChanged(
      ok
          ? WifiContent(
              ssid: _ssid.text,
              password: open ? '' : _password.text,
              security: _security,
              hidden: _hidden,
            )
          : null,
    );
  }

  /// «Incolla la password»: dagli appunti, senza ritocchi tranne gli a capo in coda (che una
  /// copia da un'altra app puo' aggiungere e che nessuna password contiene).
  Future<void> _paste() async {
    final l = L.of(context);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.replaceAll(RegExp(r'[\r\n]+$'), '');
    if (!mounted) return;
    if (text == null || text.isEmpty) {
      MicroSnack.show(context, l.home_clipboardEmpty);
      return;
    }
    setState(() {
      if (_security == WifiSecurity.none) _security = WifiSecurity.wpa;
    });
    _password
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QrTextField(
          key: const ValueKey('wifi_ssid'),
          controller: _ssid,
          label: l.wifi_ssid,
          validator: (v) => requiredText(l, v),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SegmentedButton<WifiSecurity>(
            key: const ValueKey('wifi_security'),
            segments: [
              ButtonSegment(value: WifiSecurity.wpa, label: Text(l.wifi_wpa)),
              ButtonSegment(value: WifiSecurity.wep, label: Text(l.wifi_wep)),
              ButtonSegment(value: WifiSecurity.none, label: Text(l.wifi_open)),
            ],
            selected: {_security},
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              setState(() => _security = s.first);
              _emit();
            },
          ),
        ),
        if (widget.pasteHelp && _security != WifiSecurity.none) ...[
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              key: const ValueKey('wifi_paste'),
              onPressed: () => unawaited(_paste()),
              icon: const Icon(Icons.content_paste),
              label: Text(l.wifiSource_pastePassword),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, MicroSpacing.s, 4, MicroSpacing.m),
            child: Text(
              ios ? l.wifiSource_whereIos : l.wifiSource_whereAndroid,
              key: const ValueKey('wifi_pasteHelp'),
              style: TextStyle(fontSize: 13, color: p.inkMuted, height: 1.35),
            ),
          ),
        ],
        if (_security != WifiSecurity.none)
          QrTextField(
            key: const ValueKey('wifi_password'),
            controller: _password,
            label: l.wifi_passwordLabel,
            obscure: !_showPassword,
            validator: (v) => requiredText(l, v),
            suffix: IconButton(
              tooltip: _showPassword ? l.display_hidePassword : l.display_showPassword,
              icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        SwitchListTile(
          key: const ValueKey('wifi_hidden'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.wifi_hidden),
          subtitle: Text(l.wifi_hiddenBody),
          value: _hidden,
          onChanged: (v) {
            setState(() => _hidden = v);
            _emit();
          },
        ),
      ],
    );
  }
}

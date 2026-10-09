import 'package:flutter/material.dart';

import '../../domain/qr_content.dart';
import '../../l10n/generated/app_localizations.dart';
import 'form_fields.dart';

/// Il modulo Wi-Fi: SSID (obbligatorio), password (obbligatoria se la rete non e' aperta),
/// sicurezza WPA / WEP / nessuna, rete nascosta (F17.1.6).
///
/// ⚑ La password si scrive nascosta con l'occhio, come la mostra la pagina del QR: chi compila
/// il modulo spesso lo fa con un ospite accanto.
class WifiForm extends QrFormWidget<WifiContent> {
  const WifiForm({required super.onChanged, super.initial, super.key});

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

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
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

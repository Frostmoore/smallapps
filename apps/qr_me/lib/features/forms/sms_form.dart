import 'package:flutter/material.dart';

import '../../domain/qr_content.dart';
import '../../l10n/generated/app_localizations.dart';
import 'form_fields.dart';

/// Il modulo SMS: numero (obbligatorio) e testo precompilato (F17.1.6). Diventa `SMSTO:`.
class SmsForm extends QrFormWidget<SmsContent> {
  const SmsForm({required super.onChanged, super.initial, super.key});

  @override
  State<SmsForm> createState() => _SmsFormState();
}

class _SmsFormState extends State<SmsForm> {
  late final _number = TextEditingController(text: widget.initial?.number ?? '');
  late final _body = TextEditingController(text: widget.initial?.body ?? '');

  @override
  void initState() {
    super.initState();
    for (final c in [_number, _body]) {
      c.addListener(_emit);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _number.dispose();
    _body.dispose();
    super.dispose();
  }

  void _emit() {
    if (!mounted) return;
    final ok = phoneText(L.of(context), _number.text) == null;
    widget.onChanged(ok ? SmsContent(number: _number.text.trim(), body: _body.text) : null);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QrTextField(
          key: const ValueKey('sms_number'),
          controller: _number,
          label: l.sms_number,
          keyboardType: TextInputType.phone,
          validator: (v) => phoneText(l, v),
        ),
        QrTextField(
          controller: _body,
          label: l.sms_body,
          maxLines: 4,
          capitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}

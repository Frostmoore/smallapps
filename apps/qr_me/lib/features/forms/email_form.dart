import 'package:flutter/material.dart';

import '../../domain/qr_content.dart';
import '../../l10n/generated/app_localizations.dart';
import 'form_fields.dart';

/// Il modulo email: destinatario (obbligatorio, formato email), oggetto, testo (F17.1.6).
/// Diventa un `mailto:` con oggetto e testo precompilati.
class EmailForm extends QrFormWidget<EmailContent> {
  const EmailForm({required super.onChanged, super.initial, super.key});

  @override
  State<EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<EmailForm> {
  late final _to = TextEditingController(text: widget.initial?.to ?? '');
  late final _subject = TextEditingController(text: widget.initial?.subject ?? '');
  late final _body = TextEditingController(text: widget.initial?.body ?? '');

  @override
  void initState() {
    super.initState();
    for (final c in [_to, _subject, _body]) {
      c.addListener(_emit);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _to.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  void _emit() {
    if (!mounted) return;
    final ok = emailText(L.of(context), _to.text) == null;
    widget.onChanged(
      ok ? EmailContent(to: _to.text.trim(), subject: _subject.text, body: _body.text) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QrTextField(
          key: const ValueKey('email_to'),
          controller: _to,
          label: l.email_to,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => emailText(l, v),
        ),
        QrTextField(
          controller: _subject,
          label: l.email_subject,
          capitalization: TextCapitalization.sentences,
        ),
        QrTextField(
          controller: _body,
          label: l.email_body,
          maxLines: 5,
          capitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}

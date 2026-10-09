import 'package:flutter/material.dart';

import '../../domain/qr_content.dart';
import '../../l10n/generated/app_localizations.dart';
import 'form_fields.dart';

/// Le righe sempre visibili del testo dell'email precompilata (F17.10 punto 3: «almeno 6»).
const int kEmailBodyMinLines = 6;

/// Il modulo «Email precompilata»: destinatario (obbligatorio, formato email), oggetto, testo
/// (F17.1.6). Diventa un `mailto:` con oggetto e testo precompilati.
///
/// ⚑ Serve a creare un QR che **apre un'email gia' scritta**, non a condividere il proprio
/// indirizzo (F17.10 punto 3): per questo il testo e' un campo grande, almeno 6 righe visibili,
/// che cresce con quello che si scrive.
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
          key: const ValueKey('email_subject'),
          controller: _subject,
          label: l.email_subject,
          capitalization: TextCapitalization.sentences,
        ),
        QrTextField(
          key: const ValueKey('email_body'),
          controller: _body,
          label: l.email_body,
          keyboardType: TextInputType.multiline,
          minLines: kEmailBodyMinLines,
          maxLines: null,
          capitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}

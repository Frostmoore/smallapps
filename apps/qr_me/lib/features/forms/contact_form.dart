import 'package:flutter/material.dart';

import '../../domain/qr_content.dart';
import '../../l10n/generated/app_localizations.dart';
import 'form_fields.dart';

/// Il modulo contatto: nome (obbligatorio), telefono, email, azienda, sito, nota (F17.1.6).
/// Diventa una vCard 3.0 (`QrEncoder`), che le fotocamere di iOS e Android importano.
class ContactForm extends QrFormWidget<ContactContent> {
  const ContactForm({required super.onChanged, super.initial, super.key});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _phone = TextEditingController(text: widget.initial?.phone ?? '');
  late final _email = TextEditingController(text: widget.initial?.email ?? '');
  late final _org = TextEditingController(text: widget.initial?.organization ?? '');
  late final _url = TextEditingController(text: widget.initial?.url ?? '');
  late final _note = TextEditingController(text: widget.initial?.note ?? '');

  List<TextEditingController> get _all => [_name, _phone, _email, _org, _url, _note];

  @override
  void initState() {
    super.initState();
    for (final c in _all) {
      c.addListener(_emit);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  static String? _opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  void _emit() {
    if (!mounted) return;
    final l = L.of(context);
    final ok =
        requiredText(l, _name.text) == null &&
        phoneText(l, _phone.text, required: false) == null &&
        emailText(l, _email.text, required: false) == null;
    widget.onChanged(
      ok
          ? ContactContent(
              name: _name.text.trim(),
              phone: _opt(_phone),
              email: _opt(_email),
              organization: _opt(_org),
              url: _opt(_url),
              note: _opt(_note),
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
          key: const ValueKey('contact_name'),
          controller: _name,
          label: l.contact_name,
          capitalization: TextCapitalization.words,
          validator: (v) => requiredText(l, v),
        ),
        QrTextField(
          key: const ValueKey('contact_phone'),
          controller: _phone,
          label: l.contact_phone,
          keyboardType: TextInputType.phone,
          validator: (v) => phoneText(l, v, required: false),
        ),
        QrTextField(
          key: const ValueKey('contact_email'),
          controller: _email,
          label: l.contact_email,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => emailText(l, v, required: false),
        ),
        QrTextField(
          controller: _org,
          label: l.contact_organization,
          capitalization: TextCapitalization.words,
        ),
        QrTextField(controller: _url, label: l.contact_url, keyboardType: TextInputType.url),
        QrTextField(
          controller: _note,
          label: l.contact_note,
          maxLines: 3,
          capitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}

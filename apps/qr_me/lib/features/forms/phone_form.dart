import 'package:flutter/material.dart';

import '../../domain/qr_content.dart';
import '../../l10n/generated/app_localizations.dart';
import 'form_fields.dart';

/// Il modulo telefono: il numero (F17.1.6). Diventa `tel:` normalizzato (il `+` iniziale resta).
class PhoneForm extends QrFormWidget<PhoneContent> {
  const PhoneForm({required super.onChanged, super.initial, super.key});

  @override
  State<PhoneForm> createState() => _PhoneFormState();
}

class _PhoneFormState extends State<PhoneForm> {
  late final _number = TextEditingController(text: widget.initial?.number ?? '');

  @override
  void initState() {
    super.initState();
    _number.addListener(_emit);
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  void _emit() {
    if (!mounted) return;
    final ok = phoneText(L.of(context), _number.text) == null;
    widget.onChanged(ok ? PhoneContent(_number.text.trim()) : null);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return QrTextField(
      key: const ValueKey('phone_number'),
      controller: _number,
      label: l.phone_number,
      keyboardType: TextInputType.phone,
      validator: (v) => phoneText(l, v),
    );
  }
}

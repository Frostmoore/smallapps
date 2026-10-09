import 'package:flutter/material.dart';

import '../../domain/qr_content.dart';
import '../../l10n/generated/app_localizations.dart';

/// I pezzi comuni dei cinque moduli speciali (F17.1.6): validazione e campo di testo.
///
/// ⚑ Ogni validatore e' una funzione pura che restituisce il messaggio d'errore o null: lo usa
/// il campo (errore in linea) **e** il modulo per decidere se il contenuto e' valido (anteprima e
/// «Mostra QR»). Una sola regola, due usi: l'anteprima non puo' mostrare un QR che il campo dice
/// sbagliato.

/// Un indirizzo email plausibile: qualcosa@qualcosa.dominio, senza spazi.
final RegExp kEmailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? requiredText(L l, String v) => v.trim().isEmpty ? l.form_required : null;

String? emailText(L l, String v, {bool required = true}) {
  final t = v.trim();
  if (t.isEmpty) return required ? l.form_required : null;
  return kEmailPattern.hasMatch(t) ? null : l.form_invalidEmail;
}

/// Un numero di telefono: cifre (con `+` iniziale), almeno 3, dopo aver tolto spazi e trattini.
String? phoneText(L l, String v, {bool required = true}) {
  final n = normalizePhone(v);
  if (n.isEmpty) return required ? l.form_required : null;
  return RegExp(r'^\+?[0-9]{3,}$').hasMatch(n) ? null : l.form_invalidPhone;
}

/// Un campo di testo dei moduli: etichetta, errore in linea dopo il primo tocco.
class QrTextField extends StatelessWidget {
  const QrTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.obscure = false,
    this.suffix,
    this.capitalization = TextCapitalization.none,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String value)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool obscure;
  final Widget? suffix;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: obscure ? 1 : maxLines,
      minLines: 1,
      obscureText: obscure,
      autocorrect: !obscure,
      enableSuggestions: !obscure,
      textCapitalization: capitalization,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator == null ? null : (v) => validator!(v ?? ''),
      decoration: InputDecoration(labelText: label, suffixIcon: suffix),
    ),
  );
}

/// L'interfaccia comune dei cinque moduli: un contenuto iniziale (modifica di un preferito) e la
/// notifica di ogni cambiamento con il contenuto valido, o null se il modulo non lo e' ancora.
abstract class QrFormWidget<T extends QrContent> extends StatefulWidget {
  const QrFormWidget({required this.onChanged, this.initial, super.key});

  final T? initial;
  final ValueChanged<QrContent?> onChanged;
}

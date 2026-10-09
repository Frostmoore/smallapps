import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../domain/qr_content.dart';
import '../l10n/generated/app_localizations.dart';

/// I nomi visibili dei tipi di QR, dagli ARB.
///
/// ⚑ Il dominio (`lib/domain/`) conosce solo le chiavi: i nomi stanno qui perche' cambiano con
/// la lingua, e il dominio resta Dart puro (stesso schema di Film Tracker). Lo switch e'
/// esaustivo di proposito: un tipo nuovo non compila finche' non ha la sua etichetta.
String kindName(L l, QrKind k) => switch (k) {
  QrKind.text => l.kind_text,
  QrKind.url => l.kind_url,
  QrKind.wifi => l.kind_wifi,
  QrKind.contact => l.kind_contact,
  QrKind.email => l.kind_email,
  QrKind.sms => l.kind_sms,
  QrKind.phone => l.kind_phone,
};

/// L'icona di un tipo di QR (righe, risultato della lettura, chip dei moduli).
IconData kindIcon(QrKind k) => switch (k) {
  QrKind.text => Icons.notes,
  QrKind.url => Icons.link,
  QrKind.wifi => Icons.wifi,
  QrKind.contact => Icons.person_outline,
  QrKind.email => Icons.mail_outline,
  QrKind.sms => Icons.sms_outlined,
  QrKind.phone => Icons.call_outlined,
};

/// Il contenuto in chiaro, come si legge sotto il QR e come si copia con «Copia testo».
///
/// ⚑ Non il payload: per un contatto il payload e' una vCard (`BEGIN:VCARD…`), illeggibile per
/// una persona. Qui una riga per campo. La password del Wi-Fi c'e' solo con [withPassword]: la
/// pagina del QR la nasconde finche' non si tocca l'occhio.
String plainText(L l, QrContent c, {bool withPassword = true}) => switch (c) {
  TextContent(:final text) => text,
  UrlContent(:final uri) => uri.toString(),
  WifiContent(:final ssid, :final password, :final security) => [
    l.wifi_network(ssid),
    if (security != WifiSecurity.none) l.wifi_password(withPassword ? password : kMaskedPassword),
  ].join('\n'),
  ContactContent(
    :final name,
    :final phone,
    :final email,
    :final organization,
    :final url,
    :final note,
  ) =>
    [
      name,
      for (final v in [phone, email, organization, url, note])
        if (v != null && v.isNotEmpty) v,
    ].join('\n'),
  EmailContent(:final to, :final subject, :final body) => [
    to,
    if (subject.isNotEmpty) subject,
    if (body.isNotEmpty) body,
  ].join('\n'),
  SmsContent(:final number, :final body) => [number, if (body.isNotEmpty) body].join('\n'),
  PhoneContent(:final number) => number,
};

/// La password nascosta: sempre otto pallini, qualunque sia la lunghezza vera (anche la
/// lunghezza e' un indizio).
const String kMaskedPassword = '••••••••';

/// La riga grigia sotto il titolo di una riga salvata: tipo e data dell'ultimo uso.
String rowMeta(L l, QrCode code) {
  final kind = QrKind.values.asNameMap()[code.kind];
  final when = DateFormat.MMMd(l.localeName).format(code.lastUsedAtUtc.toLocal());
  return '${kind == null ? code.kind : kindName(l, kind)} · $when';
}

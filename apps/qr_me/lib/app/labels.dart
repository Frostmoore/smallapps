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

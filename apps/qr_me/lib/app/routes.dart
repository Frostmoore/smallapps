import '../domain/qr_content.dart';
import '../domain/qr_style.dart';

/// I percorsi di navigazione di QR Me, in un posto solo (develop_microapps.md F17.1.5).
///
/// ⚑ Fissati tutti insieme con il bootstrap (F17.2c), prima delle schermate: F17.4 le scrive
/// in parallelo, e chi fa la home deve sapere dove sta il QR a tutto schermo senza aspettare
/// chi lo scrive.
abstract final class Routes {
  static const String home = '/';

  /// Il QR a tutto schermo di un contenuto **non salvato** (cronologia spenta, o appena letto):
  /// argomenti in `extra: QrDisplayArgs`.
  static const String show = '/show';

  /// Il QR a tutto schermo di una riga salvata (cronologia o preferiti).
  static const String qr = '/qr/:id';
  static String qrOf(int id) => '/qr/$id';

  static const String scan = '/scan';

  /// ⚑ Dopo `/scan` nell'elenco delle rotte non serve: e' un percorso diverso, non un figlio.
  /// `extra: ScanResultArgs`.
  static const String scanResult = '/scan/result';

  /// Un modulo speciale (Pro, `customCategories`): `/form/wifi`, `/form/contact?id=3`.
  static const String form = '/form/:kind';
  static String formOf(QrKind kind, {int? id}) => '/form/${kind.name}${id == null ? '' : '?id=$id'}';

  /// Lo stile (Pro, `themeCustomization`): `extra: StyleArgs`.
  static const String style = '/style';

  static const String saved = '/saved';
  static const String history = '/history';
  static const String settings = '/settings';

  /// Il paywall come pagina (§8.T). Dal codice si preferisce `showQrPaywall`, che evidenzia la
  /// funzione che l'ha innescato.
  static const String pro = '/pro';
}

/// I tipi che hanno un modulo (`/form/:kind`): i moduli speciali di F17.0 punto 3. Testo e link
/// si scrivono nel campo della home.
const List<QrKind> kFormKinds = [QrKind.wifi, QrKind.contact, QrKind.email, QrKind.sms, QrKind.phone];

/// Cio' che serve a `/show`: un QR da mostrare senza che sia (necessariamente) salvato.
///
/// ⚑ Con la cronologia spenta il QR si mostra da questo oggetto in memoria e non tocca il
/// database (F17.1.4). Se e' gia' in cronologia, [qrId] lo dice (per «Salva» e «Stile»).
final class QrDisplayArgs {
  const QrDisplayArgs({
    required this.content,
    required this.payload,
    required this.source,
    this.style = QrStyle.plain,
    this.qrId,
  });

  final QrContent content;

  /// La stringa esatta da codificare (`QrEncoder.encode(content)`, o quella letta).
  final String payload;

  /// Una delle chiavi di `QrSource`.
  final String source;
  final QrStyle style;
  final int? qrId;
}

/// Cio' che serve a `/scan/result`: la stringa letta e da dove (`QrSource.scanned` o `image`).
final class ScanResultArgs {
  const ScanResultArgs({required this.raw, required this.source});

  final String raw;
  final String source;
}

/// Cio' che serve a `/style`: il QR da restilizzare e, se e' salvato, il suo id.
final class StyleArgs {
  const StyleArgs({required this.display});

  final QrDisplayArgs display;

  /// L'id se il QR e' salvato: «Applica» scrive lo stile sulla riga invece di tornare a `/show`.
  int? get qrId => display.qrId;
}

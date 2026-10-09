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

  /// La lettura **solo Wi-Fi** del modulo Wi-Fi (F17.10 punto 1): la stessa `ScanPage` in modalita'
  /// `wifiOnly`, che non apre il risultato ma **torna** (`pop`) con il `WifiContent` letto. Un QR
  /// che non e' di una rete lo dice e continua a inquadrare.
  static const String scanWifi = '/scan/wifi';

  /// Un modulo speciale (Pro, `customCategories`): `/form/wifi`, `/form/contact?id=3`.
  static const String form = '/form/:kind';
  static String formOf(QrKind kind, {int? id}) =>
      '/form/${kind.name}${id == null ? '' : '?id=$id'}';

  /// Lo stile (Pro, `themeCustomization`): `extra: StyleArgs`.
  static const String style = '/style';

  /// L'etichetta da stampare (Pro, `imageExport`; F17.10 punto 5): `extra: LabelArgs`.
  static const String label = '/label';

  /// La scheda «Io» del modulo Contatto (Pro, `customCategories`; F17.10 punto 2), dalle
  /// impostazioni o dal modulo.
  static const String myContact = '/me';

  static const String saved = '/saved';
  static const String history = '/history';
  static const String settings = '/settings';

  // ⚑ Nessuna rotta `/pro`: il paywall si apre sempre con `showQrPaywall` (un
  // `Navigator.push` di `PaywallPage.show`, micro_core), che evidenzia la funzione che l'ha
  // innescato. La rotta c'era e nessuno la apriva: tolta il 2026-10-09.
}

/// I tipi che hanno un modulo (`/form/:kind`). Testo e link si scrivono nel campo della home.
///
/// ⚑ **SMS e Telefono tolti** (F17.10 punto 4, revisione del proprietario: Telefono e' ridondante
/// con Contatto, SMS non serve). Si tolgono i **moduli**, non la lettura: `QrKind.sms` e
/// `QrKind.phone` restano nel dominio, un QR `SMSTO:`/`tel:` letto si riconosce e offre ancora
/// «Manda SMS»/«Chiama», e i QR gia' salvati di quei tipi si mostrano (senza «Modifica», che
/// guarda questa lista). `/form/sms` e `/form/phone` ora dicono «Non trovato».
const List<QrKind> kFormKinds = [QrKind.wifi, QrKind.contact, QrKind.email];

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

  /// La stringa esatta da codificare: `QrEncoder.encode(content)` per un modulo,
  /// `QrEncoder.payloadOfTyped` per un testo scritto o condiviso, quella letta per un QR letto.
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

/// Cio' che serve a `/label`: il QR (con il suo stile) e il testo di partenza sotto il QR.
final class LabelArgs {
  const LabelArgs({required this.display, required this.title});

  final QrDisplayArgs display;

  /// Il testo iniziale dell'etichetta: il titolo del QR (F17.10 punto 5), modificabile.
  final String title;
}

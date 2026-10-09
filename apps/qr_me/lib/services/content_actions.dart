import 'package:micro_core/micro_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/qr_content.dart';

/// Apre cio' che c'e' in un QR letto con l'app giusta: link, chiamata, email, SMS
/// (develop_microapps.md F17.1.7, F17.1.6).
///
/// ⚑ Il lanciatore e' iniettabile: i test della pagina del risultato verificano **quale** URI
/// si apre senza aprire niente.
///
/// ⚑ `false` (e non un'eccezione) quando nessuna app sa aprirlo: la pagina mostra uno snack.
/// ☠ Su Android 11+ senza le `<queries>` del manifest il sistema risponde sempre "nessuna app":
/// sono gia' nel manifest (F17.1.10).
class ContentActions {
  const ContentActions({this._launcher});

  final Future<bool> Function(Uri uri)? _launcher;

  /// L'URI da aprire per [content], o null se non c'e' niente da aprire (testo, Wi-Fi,
  /// contatto: si copiano, non si aprono).
  ///
  /// ⚑ L'SMS si apre con `sms:` e non con `SMSTO:`: `SMSTO:` e' la forma del QR (quella che le
  /// fotocamere capiscono), `sms:...?body=` quella che le app dei messaggi accettano da un link.
  static Uri? uriFor(QrContent content) => switch (content) {
    UrlContent(:final uri) => uri,
    PhoneContent(:final number) => Uri(scheme: 'tel', path: normalizePhone(number)),
    EmailContent(:final to, :final subject, :final body) => Uri.parse(
      'mailto:${to.trim()}${_query({'subject': subject, 'body': body})}',
    ),
    SmsContent(:final number, :final body) => Uri.parse(
      'sms:${normalizePhone(number)}${_query({'body': body})}',
    ),
    TextContent() || WifiContent() || ContactContent() => null,
  };

  /// ⚑ `encodeComponent` e non `Uri(queryParameters:)`: quest'ultimo scrive gli spazi come `+`,
  /// e in un mailto o in un sms il `+` resta un `+` («Ciao+a+tutti»).
  static String _query(Map<String, String> params) {
    final parts = [
      for (final e in params.entries)
        if (e.value.isNotEmpty) '${e.key}=${Uri.encodeComponent(e.value)}',
    ];
    return parts.isEmpty ? '' : '?${parts.join('&')}';
  }

  /// Apre [content]; `false` se non c'e' niente da aprire, l'URI non si costruisce o nessuna app
  /// lo sa fare. Non lancia mai.
  ///
  /// ☠ [uriFor] sta **dentro** il try: il destinatario di un'email letta da un QR e' testo
  /// arbitrario, e `Uri.parse` ne rifiuta alcuni con FormatException (`//posta:sconti` diventa
  /// un'autorita' con porta non numerica). Fuori dal try l'eccezione arrivava al pulsante invece
  /// dello snack «nessuna app». Un `%` nudo invece passa (`Uri.parse` lo scrive `%25`).
  Future<bool> open(QrContent content) async {
    Uri? uri;
    try {
      uri = uriFor(content);
      if (uri == null) return false;
      final launcher = _launcher;
      if (launcher != null) return await launcher(uri);
      // ⚑ Sempre in un'app esterna: un link letto da un QR non si apre dentro QR Me (non e' un
      // browser, e l'utente deve vedere la barra degli indirizzi del suo).
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object catch (error, stack) {
      MicroLog.e(
        'apertura di ${uri?.scheme ?? content.kind.name}: non riuscita',
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }
}

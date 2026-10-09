import 'qr_content.dart';

/// Da [QrContent] alla stringa che va dentro il QR (develop_microapps.md F17.1.3).
///
/// ⚑ Le codifiche sono **esattamente** quelle della tabella di F17.1.3: sono quelle che le
/// fotocamere di sistema di Android e iOS riconoscono. Altre varianti esistono (MECARD, `sms:`,
/// `WIFI:` con i campi in altro ordine) ma alcune fotocamere non le capiscono: il decoder le
/// accetta in ingresso, l'encoder non le produce mai.
abstract final class QrEncoder {
  /// La stringa da codificare.
  ///
  /// ☠ Lancia [ArgumentError] per un [UrlContent] con uno schema diverso da `http`/`https` (o
  /// senza schema e senza l'aspetto di un dominio): per costruirlo da un testo scritto c'e'
  /// `UrlContent.tryParse`, che non lo produce mai.
  static String encode(QrContent content) => switch (content) {
    // Nessuna trasformazione, nemmeno il trim: un testo condiviso si mostra identico.
    TextContent(:final text) => text,
    UrlContent(:final uri) => _url(uri),
    WifiContent() => _wifi(content),
    ContactContent() => _vcard(content),
    EmailContent() => _mailto(content),
    // ⚑ SMSTO: e non sms:, e' quella che entrambe le fotocamere di sistema aprono con il testo
    // precompilato. Il testo non si escapa: tutto cio' che segue il secondo ":" e' il messaggio.
    SmsContent(:final number, :final body) => 'SMSTO:${normalizePhone(number)}:$body',
    PhoneContent(:final number) => 'tel:${normalizePhone(number)}',
  };

  static String _url(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') return uri.toString();
    if (scheme.isEmpty) {
      final normalized = UrlContent.tryParse(uri.toString());
      if (normalized != null) return normalized.uri.toString();
    }
    throw ArgumentError.value(uri.toString(), 'uri', 'Solo link http/https');
  }

  /// `WIFI:T:WPA;S:<ssid>;P:<password>;H:true;;`
  ///
  /// ☠ **Escape con backslash di `\ ; , : "`** in SSID e password. Senza, una password con `;`
  /// produce un QR che si legge ma connette con la password sbagliata, e l'errore sembra della
  /// rete (F17.1.11 punto 1).
  static String _wifi(WifiContent c) {
    final b = StringBuffer('WIFI:');
    switch (c.security) {
      case WifiSecurity.wpa:
        b.write('T:WPA;');
      case WifiSecurity.wep:
        b.write('T:WEP;');
      case WifiSecurity.none:
        b.write('T:nopass;');
    }
    b.write('S:${wifiEscape(c.ssid)};');
    // Rete aperta: niente P:, alcune fotocamere altrimenti chiedono una password vuota.
    if (c.security != WifiSecurity.none) b.write('P:${wifiEscape(c.password)};');
    if (c.hidden) b.write('H:true;');
    b.write(';');
    return b.toString();
  }

  /// Escape dei campi di `WIFI:` (e di MECARD/MATMSG, stessa grammatica): `\ ; , : "`.
  static String wifiEscape(String s) => s.replaceAllMapped(RegExp(r'[\\;,:"]'), (m) => '\\${m[0]}');

  /// vCard **3.0** con CRLF. ⚑ 3.0 e non 4.0: le fotocamere di iOS e Android la importano
  /// entrambe; MECARD e' piu' corta ma iOS la tratta come testo.
  static String _vcard(ContactContent c) {
    final name = c.name.trim();
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    // N si ricava da FN: l'ultima parola e' il cognome, il resto il nome.
    final family = words.isEmpty ? '' : words.last;
    final given = words.length > 1 ? words.sublist(0, words.length - 1).join(' ') : '';
    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'N:${vcardEscape(family)};${vcardEscape(given)};;;',
      'FN:${vcardEscape(c.name)}',
      // Righe vuote omesse: un "TEL:" vuoto crea un numero vuoto nella rubrica.
      if ((c.phone ?? '').isNotEmpty) 'TEL:${vcardEscape(normalizePhone(c.phone!))}',
      if ((c.email ?? '').isNotEmpty) 'EMAIL:${vcardEscape(c.email!)}',
      if ((c.organization ?? '').isNotEmpty) 'ORG:${vcardEscape(c.organization!)}',
      if ((c.url ?? '').isNotEmpty) 'URL:${vcardEscape(c.url!)}',
      if ((c.note ?? '').isNotEmpty) 'NOTE:${vcardEscape(c.note!)}',
      'END:VCARD',
    ];
    return lines.join('\r\n');
  }

  /// Escape vCard: `\` → `\\`, `,` → `\,`, `;` → `\;`, a-capo → `\n`.
  static String vcardEscape(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll(',', r'\,')
      .replaceAll(';', r'\;')
      .replaceAll('\r\n', r'\n')
      .replaceAll(RegExp(r'[\r\n]'), r'\n');

  /// `mailto:<to>?subject=<s>&body=<b>`, parametri vuoti omessi.
  ///
  /// ⚑ `Uri.encodeComponent` (spazi come `%20`) e non `Uri(queryParameters:)`, che li scrive
  /// `+`: in un mailto il `+` resta un `+` e l'oggetto arriverebbe «Ciao+a+tutti».
  static String _mailto(EmailContent c) {
    final params = [
      if (c.subject.isNotEmpty) 'subject=${Uri.encodeComponent(c.subject)}',
      if (c.body.isNotEmpty) 'body=${Uri.encodeComponent(c.body)}',
    ];
    return 'mailto:${c.to.trim()}${params.isEmpty ? '' : '?${params.join('&')}'}';
  }
}

import 'qr_content.dart';

/// Da una stringa letta (fotocamera, immagine, condivisione) a [QrContent]
/// (develop_microapps.md F17.1.3).
///
/// ⚑ **Tollerante in ingresso, rigido in uscita**: legge anche le varianti che l'encoder non
/// produce mai (MECARD, MATMSG, `sms:`, vCard 4.0, campi `WIFI:` in qualunque ordine), perche'
/// un QR letto puo' venire da qualunque generatore. Il prefisso si riconosce senza badare a
/// maiuscole e minuscole.
///
/// ☠ **Non lancia mai**: un QR e' un dato esterno, e qualunque cosa non si riconosca (o si
/// riconosca ma sia rotta, come un `WIFI:` senza SSID) diventa [TextContent] con la stringa
/// intatta. Una pagina che crasha su un QR strano e' peggio di una che lo mostra come testo.
abstract final class QrDecoder {
  /// Riconosce il tipo da una stringa letta. Proprieta': per ogni contenuto valido,
  /// `decode(QrEncoder.encode(c)) == c`.
  static QrContent decode(String raw) {
    try {
      return _decode(raw) ?? TextContent(raw);
    } on Object {
      // Difesa in profondita': nessun formato malato deve uscire di qui come eccezione.
      return TextContent(raw);
    }
  }

  /// Come [decode], ma per cio' che l'utente **scrive o incolla** (e per i testi condivisi):
  /// un link senza schema (`esempio.it`) diventa un [UrlContent] con `https://`.
  ///
  /// ⚑ Separato da [decode] di proposito: un QR letto che contiene «esempio.it» e' un testo (chi
  /// l'ha generato non l'ha fatto link), e cambiarlo romperebbe il round-trip di [TextContent].
  /// Cio' che scrive l'utente invece e' un'intenzione: se sembra un sito, lo e'.
  static QrContent decodeTyped(String raw) {
    final c = decode(raw);
    if (c is TextContent) return UrlContent.tryParse(raw) ?? c;
    return c;
  }

  static QrContent? _decode(String raw) {
    // ⚑ Solo a sinistra: a destra c'e' il testo di un SMS o di una nota, e tagliarlo romperebbe
    // il round-trip («Ciao » tornerebbe «Ciao»). Il link si controlla a parte, tutto rifilato.
    final s = raw.trimLeft();
    final lower = s.toLowerCase();
    if (lower.startsWith('wifi:')) return _wifi(s.substring(5));
    if (lower.startsWith('begin:vcard')) return _vcard(s);
    if (lower.startsWith('mecard:')) return _mecard(s.substring(7));
    if (lower.startsWith('mailto:')) return _mailto(s.substring(7));
    if (lower.startsWith('matmsg:')) return _matmsg(s.substring(7));
    if (lower.startsWith('smsto:')) return _smsto(s.substring(6));
    if (lower.startsWith('sms:')) return _sms(s.substring(4));
    if (lower.startsWith('tel:')) return _tel(s.substring(4));
    final link = s.trimRight();
    if ((lower.startsWith('http://') || lower.startsWith('https://')) && !link.contains(RegExp(r'\s'))) {
      final uri = Uri.tryParse(link);
      if (uri != null && uri.host.isNotEmpty) return UrlContent(uri);
    }
    return null;
  }

  // ── Grammatica "chiave:valore;" con escape a backslash (WIFI, MECARD, MATMSG) ──

  /// Divide sui `;` non preceduti da backslash e toglie l'escape: `[("S", "Casa;1"), ...]`.
  /// La chiave e' cio' che precede il primo `:` non escapato, in maiuscolo.
  static List<(String, String)> _fields(String body) {
    final out = <(String, String)>[];
    final key = StringBuffer();
    final value = StringBuffer();
    var inKey = true;
    void flush() {
      if (key.isNotEmpty || value.isNotEmpty) out.add((key.toString().trim().toUpperCase(), value.toString()));
      key.clear();
      value.clear();
      inKey = true;
    }

    for (var i = 0; i < body.length; i++) {
      final ch = body[i];
      if (ch == r'\' && i + 1 < body.length) {
        (inKey ? key : value).write(body[++i]);
      } else if (ch == ';') {
        flush();
      } else if (ch == ':' && inKey) {
        inKey = false;
      } else {
        (inKey ? key : value).write(ch);
      }
    }
    flush();
    return out;
  }

  static String? _first(List<(String, String)> fields, String key) {
    for (final (k, v) in fields) {
      if (k == key) return v;
    }
    return null;
  }

  static WifiContent? _wifi(String body) {
    final f = _fields(body);
    final ssid = _first(f, 'S');
    if (ssid == null || ssid.isEmpty) return null;
    final password = _first(f, 'P') ?? '';
    final t = (_first(f, 'T') ?? '').trim().toUpperCase();
    final security = switch (t) {
      'WEP' => WifiSecurity.wep,
      'NOPASS' || 'NONE' => WifiSecurity.none,
      // Senza T: aperta, a meno che una password ci sia (alcuni generatori omettono T).
      '' => password.isEmpty ? WifiSecurity.none : WifiSecurity.wpa,
      // WPA, WPA2, WPA3, SAE, WPA2-EAP...: per la stringa WIFI: sono tutte "WPA".
      _ => WifiSecurity.wpa,
    };
    final hidden = (_first(f, 'H') ?? '').trim().toLowerCase() == 'true';
    return WifiContent(
      ssid: ssid,
      password: security == WifiSecurity.none ? '' : password,
      security: security,
      hidden: hidden,
    );
  }

  static ContactContent? _mecard(String body) {
    final f = _fields(body);
    final n = _first(f, 'N');
    if (n == null || n.trim().isEmpty) return null;
    // MECARD: "Cognome,Nome". ⚑ La virgola qui e' gia' stata tolta dall'escape solo se era
    // escapata; una virgola nuda separa cognome e nome.
    final parts = n.split(',');
    final name = parts.length >= 2
        ? '${parts.sublist(1).join(' ').trim()} ${parts.first.trim()}'.trim()
        : n.trim();
    return ContactContent(
      name: name,
      phone: _nonEmpty(_first(f, 'TEL')),
      email: _nonEmpty(_first(f, 'EMAIL')),
      organization: _nonEmpty(_first(f, 'ORG')),
      url: _nonEmpty(_first(f, 'URL')),
      note: _nonEmpty(_first(f, 'NOTE')),
    );
  }

  static EmailContent? _matmsg(String body) {
    final f = _fields(body);
    final to = _first(f, 'TO');
    if (to == null || to.trim().isEmpty) return null;
    return EmailContent(to: to.trim(), subject: _first(f, 'SUB') ?? '', body: _first(f, 'BODY') ?? '');
  }

  // ── vCard 3.0 e 4.0 ──

  static ContactContent? _vcard(String s) {
    // Riga ripiegata (RFC 6350 §3.2): una riga che inizia con spazio o tab continua la precedente.
    final unfolded = s.replaceAll(RegExp(r'\r?\n[ \t]'), '');
    String? fn, n, tel, email, org, url, note;
    for (final line in unfolded.split(RegExp(r'\r?\n|\r'))) {
      final colon = _unescapedIndex(line, ':');
      if (colon <= 0) continue;
      var prop = line.substring(0, colon);
      final value = line.substring(colon + 1);
      // "item1.TEL;TYPE=CELL" -> "TEL": il gruppo e i parametri non contano.
      final semi = prop.indexOf(';');
      if (semi >= 0) prop = prop.substring(0, semi);
      final dot = prop.lastIndexOf('.');
      if (dot >= 0) prop = prop.substring(dot + 1);
      switch (prop.trim().toUpperCase()) {
        case 'FN':
          fn ??= _vcardUnescape(value);
        case 'N':
          n ??= value;
        case 'TEL':
          // vCard 4.0 puo' scriverlo come URI: "tel:+39...".
          tel ??= _vcardUnescape(value).replaceFirst(RegExp('^tel:', caseSensitive: false), '');
        case 'EMAIL':
          email ??= _vcardUnescape(value);
        case 'ORG':
          // I componenti di ORG sono separati da ";" non escapati (azienda;reparto).
          org ??= _splitUnescaped(value, ';').map(_vcardUnescape).where((p) => p.isNotEmpty).join(', ');
        case 'URL':
          url ??= _vcardUnescape(value);
        case 'NOTE':
          note ??= _vcardUnescape(value);
      }
    }
    var name = fn?.trim() ?? '';
    if (name.isEmpty && n != null) {
      // N: cognome;nome;secondi nomi;prefissi;suffissi.
      final p = _splitUnescaped(n, ';').map(_vcardUnescape).toList();
      final family = p.isNotEmpty ? p[0] : '';
      final given = p.length > 1 ? p[1] : '';
      name = '$given $family'.trim();
    }
    if (name.isEmpty) return null;
    return ContactContent(
      name: fn ?? name,
      phone: _nonEmpty(tel),
      email: _nonEmpty(email),
      organization: _nonEmpty(org),
      url: _nonEmpty(url),
      note: _nonEmpty(note),
    );
  }

  static int _unescapedIndex(String s, String ch) {
    for (var i = 0; i < s.length; i++) {
      if (s[i] == r'\') {
        i++;
      } else if (s[i] == ch) {
        return i;
      }
    }
    return -1;
  }

  static List<String> _splitUnescaped(String s, String sep) {
    final out = <String>[];
    var start = 0;
    for (var i = 0; i < s.length; i++) {
      if (s[i] == r'\') {
        i++;
      } else if (s[i] == sep) {
        out.add(s.substring(start, i));
        start = i + 1;
      }
    }
    out.add(s.substring(start));
    return out;
  }

  static String _vcardUnescape(String s) {
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == r'\' && i + 1 < s.length) {
        final next = s[++i];
        b.write(next == 'n' || next == 'N' ? '\n' : next);
      } else {
        b.write(ch);
      }
    }
    return b.toString();
  }

  // ── mailto, SMS, telefono ──

  static EmailContent? _mailto(String rest) {
    final q = rest.indexOf('?');
    final to = Uri.decodeComponent(q < 0 ? rest : rest.substring(0, q)).trim();
    final params = q < 0 ? const <String, String>{} : _query(rest.substring(q + 1));
    if (to.isEmpty) return null;
    return EmailContent(to: to, subject: params['subject'] ?? '', body: params['body'] ?? '');
  }

  /// I parametri di una query, decodificati con `decodeComponent`.
  /// ⚑ Non `Uri.splitQueryString`: trasforma `+` in spazio, ma in un mailto o in un sms il `+`
  /// e' un `+` (un oggetto «1+1» diventerebbe «1 1»). Chiavi in minuscolo, prima occorrenza.
  static Map<String, String> _query(String q) {
    final out = <String, String>{};
    for (final pair in q.split('&')) {
      if (pair.isEmpty) continue;
      final eq = pair.indexOf('=');
      final k = (eq < 0 ? pair : pair.substring(0, eq)).toLowerCase();
      final v = eq < 0 ? '' : pair.substring(eq + 1);
      out.putIfAbsent(k, () => Uri.decodeComponent(v));
    }
    return out;
  }

  static SmsContent? _smsto(String rest) {
    final colon = rest.indexOf(':');
    final number = (colon < 0 ? rest : rest.substring(0, colon)).trim();
    if (number.isEmpty) return null;
    return SmsContent(number: number, body: colon < 0 ? '' : rest.substring(colon + 1));
  }

  /// `sms:+39333?body=Ciao` (RFC 5724) oppure, da alcuni generatori, `SMS:+39333:Ciao`.
  static SmsContent? _sms(String rest) {
    final q = rest.indexOf('?');
    if (q < 0 && rest.contains(':')) return _smsto(rest);
    final number = Uri.decodeComponent(q < 0 ? rest : rest.substring(0, q)).trim();
    if (number.isEmpty) return null;
    final params = q < 0 ? const <String, String>{} : _query(rest.substring(q + 1));
    return SmsContent(number: number, body: params['body'] ?? '');
  }

  static PhoneContent? _tel(String rest) {
    final number = normalizePhone(Uri.decodeComponent(rest));
    if (number.isEmpty || !RegExp(r'^\+?[0-9*#,;pPwW]+$').hasMatch(number)) return null;
    return PhoneContent(number);
  }

  static String? _nonEmpty(String? s) => (s == null || s.trim().isEmpty) ? null : s;
}

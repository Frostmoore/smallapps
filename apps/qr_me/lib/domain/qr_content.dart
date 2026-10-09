/// Cosa c'e' dentro un QR, come oggetto e non come stringa (develop_microapps.md F17.1.3).
///
/// ⚑ **Dart puro, zero Flutter** (§8.T): codifica e decodifica sono il punto in cui un errore
/// e' invisibile (un QR del Wi-Fi che "si legge" ma connette con la password sbagliata) e
/// costoso. Senza Flutter si testano in millisecondi, round-trip compreso.
///
/// ⚑ **Uguaglianza per valore** su ogni sottoclasse: serve al round-trip
/// (`decode(encode(c)) == c`) e al repository. I campi facoltativi vuoti (`''`) e assenti
/// (`null`) sono **uguali**: un QR letto non distingue "nessuna email" da "email vuota", e la
/// differenza farebbe fallire il round-trip senza nessun significato per l'utente. I numeri di
/// telefono si confrontano **normalizzati** ([normalizePhone]) per lo stesso motivo.
library;

/// Il tipo di contenuto. `name` e' la chiave salvata in `qr_codes.kind`: **non si rinomina**.
enum QrKind { text, url, wifi, contact, email, sms, phone }

/// La sicurezza della rete. `wpa` copre WPA/WPA2/WPA3: nella stringa `WIFI:` sono tutte `T:WPA`.
enum WifiSecurity { wpa, wep, none }

/// Toglie spazi, trattini, punti e parentesi da un numero di telefono; il `+` iniziale resta.
///
/// ⚑ Anche i punti (la spec cita spazi, trattini e parentesi): «333.123.4567» e' una grafia
/// comune e un punto in un `tel:` fa fallire la chiamata su alcuni Android.
String normalizePhone(String number) => number.trim().replaceAll(RegExp(r'[\s\-().]'), '');

/// Il lato lungo massimo di un titolo automatico: `qr_codes.title` e' 1..80, e in un elenco
/// oltre i 40 caratteri si taglia comunque.
const int _kTitleMax = 40;

String _clip(String s) {
  final t = s.trim();
  if (t.isEmpty) return '…';
  // ⚑ Si taglia sui code unit ma senza spezzare una coppia surrogata (un'emoji a meta' si
  // vedrebbe come un rombo con il punto di domanda).
  if (t.length <= _kTitleMax) return t;
  var end = _kTitleMax;
  final c = t.codeUnitAt(end - 1);
  if (c >= 0xD800 && c <= 0xDBFF) end--;
  return '${t.substring(0, end).trimRight()}…';
}

bool _same(String? a, String? b) => (a ?? '') == (b ?? '');

String? _orNull(String? s) => (s == null || s.isEmpty) ? null : s;

sealed class QrContent {
  const QrContent();

  QrKind get kind;

  /// Titolo automatico per la cronologia: il dominio di un link, il nome della rete, il nome
  /// del contatto, il destinatario... Mai vuoto, al massimo 41 caratteri (40 + «…»).
  String get autoTitle;

  /// I campi per la colonna `fields_json`, per riaprire il modulo. Solo tipi JSON.
  Map<String, Object?> toFields();

  /// L'inverso di [toFields]. ☠ Lancia [FormatException] su campi mancanti o del tipo sbagliato:
  /// succede solo con un database o un backup rovinati, e un dato sbagliato in silenzio e'
  /// peggio di un errore visibile.
  static QrContent fromFields(QrKind kind, Map<String, Object?> fields) {
    String req(String key) {
      final v = fields[key];
      if (v is String) return v;
      throw FormatException('QrContent ${kind.name}: campo "$key" mancante o non testo ($v)');
    }

    String opt(String key) {
      final v = fields[key];
      if (v == null) return '';
      if (v is String) return v;
      throw FormatException('QrContent ${kind.name}: campo "$key" non testo ($v)');
    }

    String? optN(String key) => _orNull(opt(key));

    return switch (kind) {
      QrKind.text => TextContent(req('text')),
      QrKind.url => UrlContent(
        Uri.tryParse(req('url')) ?? (throw FormatException('QrContent url: "${fields['url']}" non e\' un URL')),
      ),
      QrKind.wifi => WifiContent(
        ssid: req('ssid'),
        password: opt('password'),
        security: WifiSecurity.values.asNameMap()[opt('security')] ??
            (throw FormatException('QrContent wifi: sicurezza "${fields['security']}" sconosciuta')),
        hidden: fields['hidden'] == true,
      ),
      QrKind.contact => ContactContent(
        name: req('name'),
        phone: optN('phone'),
        email: optN('email'),
        organization: optN('organization'),
        url: optN('url'),
        note: optN('note'),
      ),
      QrKind.email => EmailContent(to: req('to'), subject: opt('subject'), body: opt('body')),
      QrKind.sms => SmsContent(number: req('number'), body: opt('body')),
      QrKind.phone => PhoneContent(req('number')),
    };
  }
}

/// Testo libero, mostrato e codificato **identico** (nemmeno il trim): un testo condiviso si
/// mostra com'e'.
final class TextContent extends QrContent {
  const TextContent(this.text);

  final String text;

  @override
  QrKind get kind => QrKind.text;

  /// La prima riga non vuota.
  @override
  String get autoTitle =>
      _clip(text.split(RegExp(r'\r?\n')).firstWhere((l) => l.trim().isNotEmpty, orElse: () => ''));

  @override
  Map<String, Object?> toFields() => {'text': text};

  @override
  bool operator ==(Object other) => other is TextContent && other.text == text;

  @override
  int get hashCode => Object.hash(QrKind.text, text);

  @override
  String toString() => 'TextContent($text)';
}

/// Un link `http`/`https`.
///
/// ⚑ Il costruttore e' `const` e non valida: per un testo scritto a mano si usa [tryParse],
/// che applica la regola dei link senza schema. `QrEncoder.encode` rifiuta gli altri schemi.
final class UrlContent extends QrContent {
  const UrlContent(this.uri);

  final Uri uri;

  /// Un link da un testo scritto o incollato, o null se non lo e'.
  ///
  /// - `http://…` / `https://…` senza spazi: com'e';
  /// - senza schema (`esempio.it/pagina`): diventa `https://esempio.it/pagina` **solo** se
  ///   contiene un punto e nessuno spazio (F17.1.3). ⚑ Il punto distingue un dominio da una
  ///   parola; senza la regola «ciao» diventerebbe `https://ciao`.
  /// - qualunque altro schema (`ftp:`, `javascript:`): null.
  static UrlContent? tryParse(String input) {
    final s = input.trim();
    if (s.isEmpty || s.contains(RegExp(r'\s'))) return null;
    final lower = s.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      final uri = Uri.tryParse(s);
      return (uri == null || uri.host.isEmpty) ? null : UrlContent(uri);
    }
    // Uno schema diverso ("mailto:", "ftp://"): non e' un link da aprire nel browser.
    if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*:').hasMatch(s) && !RegExp(r'^[^:/]+:\d').hasMatch(s)) {
      return null;
    }
    if (!s.contains('.')) return null;
    final uri = Uri.tryParse('https://$s');
    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) return null;
    return UrlContent(uri);
  }

  @override
  QrKind get kind => QrKind.url;

  /// Il dominio senza `www.`: e' cio' che dice dove porta il link.
  @override
  String get autoTitle {
    final host = uri.host.toLowerCase();
    return _clip(host.startsWith('www.') ? host.substring(4) : (host.isEmpty ? uri.toString() : host));
  }

  @override
  Map<String, Object?> toFields() => {'url': uri.toString()};

  @override
  bool operator ==(Object other) => other is UrlContent && other.uri == uri;

  @override
  int get hashCode => Object.hash(QrKind.url, uri);

  @override
  String toString() => 'UrlContent($uri)';
}

/// Una rete Wi-Fi. Con [WifiSecurity.none] la password non si codifica (e quindi un contenuto
/// valido ha password vuota).
final class WifiContent extends QrContent {
  const WifiContent({required this.ssid, this.password = '', this.security = WifiSecurity.wpa, this.hidden = false});

  final String ssid;
  final String password;
  final WifiSecurity security;
  final bool hidden;

  @override
  QrKind get kind => QrKind.wifi;

  @override
  String get autoTitle => _clip(ssid);

  @override
  Map<String, Object?> toFields() => {'ssid': ssid, 'password': password, 'security': security.name, 'hidden': hidden};

  @override
  bool operator ==(Object other) =>
      other is WifiContent &&
      other.ssid == ssid &&
      other.password == password &&
      other.security == security &&
      other.hidden == hidden;

  @override
  int get hashCode => Object.hash(QrKind.wifi, ssid, password, security, hidden);

  // ☠ La password non si stampa: un toString finisce nei log.
  @override
  String toString() => 'WifiContent($ssid, ${security.name}, hidden: $hidden)';
}

/// Un contatto (vCard 3.0 in uscita). Solo il nome e' obbligatorio.
final class ContactContent extends QrContent {
  const ContactContent({required this.name, this.phone, this.email, this.organization, this.url, this.note});

  /// Il nome completo (`FN`). `N` si ricava da qui: l'ultima parola e' il cognome.
  final String name;
  final String? phone;
  final String? email;
  final String? organization;
  final String? url;
  final String? note;

  @override
  QrKind get kind => QrKind.contact;

  @override
  String get autoTitle => _clip(name);

  @override
  Map<String, Object?> toFields() => {
    'name': name,
    'phone': _orNull(phone),
    'email': _orNull(email),
    'organization': _orNull(organization),
    'url': _orNull(url),
    'note': _orNull(note),
  };

  @override
  bool operator ==(Object other) =>
      other is ContactContent &&
      other.name == name &&
      normalizePhone(other.phone ?? '') == normalizePhone(phone ?? '') &&
      _same(other.email, email) &&
      _same(other.organization, organization) &&
      _same(other.url, url) &&
      _same(other.note, note);

  @override
  int get hashCode => Object.hash(
    QrKind.contact,
    name,
    normalizePhone(phone ?? ''),
    email ?? '',
    organization ?? '',
    url ?? '',
    note ?? '',
  );

  @override
  String toString() => 'ContactContent($name)';
}

/// Un'email da scrivere: destinatario, oggetto e testo precompilati.
final class EmailContent extends QrContent {
  const EmailContent({required this.to, this.subject = '', this.body = ''});

  final String to;
  final String subject;
  final String body;

  @override
  QrKind get kind => QrKind.email;

  @override
  String get autoTitle => _clip(to);

  @override
  Map<String, Object?> toFields() => {'to': to, 'subject': subject, 'body': body};

  @override
  bool operator ==(Object other) =>
      other is EmailContent && other.to == to && other.subject == subject && other.body == body;

  @override
  int get hashCode => Object.hash(QrKind.email, to, subject, body);

  @override
  String toString() => 'EmailContent($to)';
}

/// Un SMS da mandare: numero e testo precompilato.
final class SmsContent extends QrContent {
  const SmsContent({required this.number, this.body = ''});

  final String number;
  final String body;

  @override
  QrKind get kind => QrKind.sms;

  @override
  String get autoTitle => _clip(number);

  @override
  Map<String, Object?> toFields() => {'number': number, 'body': body};

  @override
  bool operator ==(Object other) =>
      other is SmsContent && normalizePhone(other.number) == normalizePhone(number) && other.body == body;

  @override
  int get hashCode => Object.hash(QrKind.sms, normalizePhone(number), body);

  @override
  String toString() => 'SmsContent($number)';
}

/// Un numero da chiamare.
final class PhoneContent extends QrContent {
  const PhoneContent(this.number);

  final String number;

  @override
  QrKind get kind => QrKind.phone;

  @override
  String get autoTitle => _clip(number);

  @override
  Map<String, Object?> toFields() => {'number': number};

  @override
  bool operator ==(Object other) => other is PhoneContent && normalizePhone(other.number) == normalizePhone(number);

  @override
  int get hashCode => Object.hash(QrKind.phone, normalizePhone(number));

  @override
  String toString() => 'PhoneContent($number)';
}

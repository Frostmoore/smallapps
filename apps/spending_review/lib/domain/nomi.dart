import 'quantita.dart';

/// Nomi dei prodotti: normalizzazione, similarita' fra cartellino e scontrino, formato della
/// confezione (develop_microapps.md F12.1.3).
abstract final class Nomi {
  static const Map<String, String> _accenti = {
    'À': 'A', 'Á': 'A', 'Â': 'A', 'Ä': 'A', 'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', //
    'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I', 'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Ö': 'O', //
    'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U', 'Ç': 'C', 'Ñ': 'N',
  };

  static const String _unita = r'(?:KG|GR|G|ML|CL|LT|L)';

  /// I formati da togliere dal nome: «200 G», «0,5 L», «6X180 ML», «GR.600», «LT 1», «X2», «2X».
  static final List<RegExp> _formati = [
    RegExp('\\b\\d+\\s*[X×]\\s*\\d+(?:[.,]\\d+)?\\s*$_unita\\b'),
    RegExp('\\b\\d+(?:[.,]\\d+)?\\s*$_unita\\b'),
    RegExp('\\b(?:GR|LT|KG|ML|CL)\\.?\\s*\\d+(?:[.,]\\d+)?\\b'),
    RegExp(r'\bX\s*\d+\b'),
    RegExp(r'\b\d+\s*X\b'),
  ];

  /// Maiuscolo, senza accenti, punteggiatura → spazio, spazi singoli, formati («200 G», «GR.600»,
  /// «LT 1», «X2») tolti. "Crema NUTKAO bicch.birra gr.600" → "CREMA NUTKAO BICCH BIRRA".
  ///
  /// ⚑ I formati si tolgono PRIMA della punteggiatura: «GR.600» e' un formato solo finche' il punto
  /// c'e'; dopo, «GR 600» sembrerebbe una parola e un numero.
  static String normalizza(String nome) {
    var s = nome.toUpperCase();
    s = s.split('').map((c) => _accenti[c] ?? c).join();
    for (final f in _formati) {
      s = s.replaceAll(f, ' ');
    }
    s = s.replaceAll(RegExp(r'[^A-Z0-9]+'), ' ');
    return s.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Similarita' 0..1 fra un nome di cartellino e una descrizione di scontrino (troncata,
  /// abbreviata): il massimo fra Jaccard sulle parole e «prefissi».
  ///
  /// «Prefissi»: due parole valgono uguali se coincidono o se la piu' corta, di almeno 3 lettere,
  /// e' l'inizio dell'altra ("MINER" ~ "MINERALE"); si contano le coppie (ogni parola una volta
  /// sola) e si divide per il numero di parole del nome piu' LUNGO. "PR COTTO" ~ "PROSCIUTTO COTTO"
  /// vale 0,5 (COTTO si', PR no: 2 lettere sono troppo poche per non abbinare a caso).
  /// ⚑ Diviso per il piu' lungo e non per il piu' corto: «ACQUA» non deve valere 1 contro
  /// «ACQUA MINERALE NATURALE 6X1,5 L».
  static double similarita(String a, String b) {
    final pa = _parole(a);
    final pb = _parole(b);
    if (pa.isEmpty || pb.isEmpty) return 0;
    final sa = pa.toSet();
    final sb = pb.toSet();
    final jaccard = sa.intersection(sb).length / sa.union(sb).length;

    final libere = [...pb];
    var coppie = 0;
    for (final p in pa) {
      final i = libere.indexWhere((q) => _simili(p, q));
      if (i >= 0) {
        coppie++;
        libere.removeAt(i);
      }
    }
    final prefissi = coppie / (pa.length > pb.length ? pa.length : pb.length);
    return jaccard > prefissi ? jaccard : prefissi;
  }

  static List<String> _parole(String s) =>
      normalizza(s).split(' ').where((p) => p.isNotEmpty).toList();

  static bool _simili(String p, String q) {
    if (p == q) return true;
    final (corta, lunga) = p.length <= q.length ? (p, q) : (q, p);
    return corta.length >= 3 && RegExp(r'^[A-Z]+$').hasMatch(corta) && lunga.startsWith(corta);
  }

  /// Il formato della confezione, se c'e' nel nome: "200 g" → AMisura(200, kg); "LT 1" →
  /// AMisura(1000, l); "6x180 ml" → AMisura(1080, l); "50 cl" → AMisura(500, l); "GR.600" →
  /// AMisura(600, kg). Serve al controllo prezzo/formato ≈ €/kg del cartellino (F12.1.4 passo 5).
  static AMisura? formato(String nome) {
    final s = nome.toUpperCase();
    final multiplo = RegExp('(\\d+)\\s*[X×]\\s*(\\d+(?:[.,]\\d+)?)\\s*($_unita)\\b').firstMatch(s);
    if (multiplo != null) {
      final uno = _millesimi(multiplo.group(2)!, multiplo.group(3)!);
      if (uno != null) return _limite(AMisura(uno.millesimi * int.parse(multiplo.group(1)!), uno.unita));
    }
    final dopo = RegExp('(?<![\\d.,])(\\d+(?:[.,]\\d+)?)\\s*($_unita)\\b').firstMatch(s);
    if (dopo != null) return _limite(_millesimi(dopo.group(1)!, dopo.group(2)!));
    final prima = RegExp(r'\b(GR|LT|KG|ML|CL)\.?\s*(\d+(?:[.,]\d+)?)\b').firstMatch(s);
    if (prima != null) return _limite(_millesimi(prima.group(2)!, prima.group(1)!));
    return null;
  }

  static AMisura? _limite(AMisura? m) =>
      (m == null || m.millesimi < 1 || m.millesimi > AMisura.massimo) ? null : m;

  /// "0,5" + "L" → 500 ml; "200" + "G" → 200 g. Interi: niente double.
  static AMisura? _millesimi(String numero, String unita) {
    final parti = numero.replaceAll('.', ',').split(',');
    final intero = int.parse(parti[0]);
    final decimali = parti.length > 1 ? parti[1] : '';
    // Il valore × 1000 in interi: "0,5" → 500, "1,25" → 1250.
    final perMille = intero * 1000 + (decimali.isEmpty ? 0 : int.parse(decimali.padRight(3, '0').substring(0, 3)));
    return switch (unita) {
      'G' || 'GR' => AMisura(perMille ~/ 1000, UnitaMisura.kg),
      'KG' => AMisura(perMille, UnitaMisura.kg),
      'ML' => AMisura(perMille ~/ 1000, UnitaMisura.l),
      'CL' => AMisura(perMille * 10 ~/ 1000, UnitaMisura.l),
      'L' || 'LT' => AMisura(perMille, UnitaMisura.l),
      _ => null,
    };
  }
}

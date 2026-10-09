import 'dart:convert';

/// Il livello di correzione d'errore di un QR: quanta parte dei moduli si puo' perdere (o
/// coprire con un logo) e il QR si legge ancora. L ~7%, M ~15%, Q ~25%, H ~30%.
enum QrErrorLevel { low, medium, quartile, high }

/// Quanto ci sta in un QR (develop_microapps.md F17.1.3).
///
/// ☠ **Si controlla PRIMA di disegnare** (F17.1.11 punto 7): un testo lungo condiviso (un
/// articolo intero) farebbe lanciare a qr_flutter `InputTooLongException` dentro il build di un
/// widget. Qui si decide prima, e la pagina mostra un messaggio invece di un errore.
abstract final class QrCapacity {
  /// Byte massimi in modalita' byte (UTF-8) alla versione 40: L 2953, M 2331, Q 1663, H 1273.
  ///
  /// ⚑ Sempre modalita' byte, anche per un testo di sole cifre (che in modalita' numerica ne
  /// conterrebbe di piu'): qr_flutter sceglie la modalita' da solo, ma il limite prudente e'
  /// questo, e un QR numerico da 7.000 cifre non e' comunque leggibile da un telefono.
  static int maxBytes(QrErrorLevel level) => switch (level) {
    QrErrorLevel.low => 2953,
    QrErrorLevel.medium => 2331,
    QrErrorLevel.quartile => 1663,
    QrErrorLevel.high => 1273,
  };

  /// I byte UTF-8 del contenuto: un'emoji ne conta 4, una lettera accentata 2.
  static int bytesOf(String payload) => utf8.encode(payload).length;

  static bool fits(String payload, QrErrorLevel level) => bytesOf(payload) <= maxBytes(level);

  /// Oltre questa soglia il QR si genera ma e' fitto: avviso morbido «avvicina il telefono».
  static const int denseBytes = 1000;

  /// Il livello per un contenuto, con la regola di F17.1.3: **M** senza logo, **H** con il
  /// logo (il logo copre fino al ~22% dei moduli e H ne recupera il 30%). Se il contenuto non
  /// sta in H il logo si toglie (con avviso); se non sta in M si prova L; se non sta in L il QR
  /// non si genera: [QrLevelChoice.tooLong].
  ///
  /// ⚑ Qui e non solo in `QrRenderer.levelFor` (F17.1.7): e' una regola, e Dart puro si testa
  /// senza Flutter. Il renderer la chiama.
  static QrLevelChoice choose(String payload, {required bool wantsLogo}) {
    final bytes = bytesOf(payload);
    if (wantsLogo && bytes <= maxBytes(QrErrorLevel.high)) {
      return QrLevelChoice._(QrErrorLevel.high, bytes: bytes, logoAllowed: true, logoDropped: false);
    }
    final dropped = wantsLogo;
    if (bytes <= maxBytes(QrErrorLevel.medium)) {
      return QrLevelChoice._(QrErrorLevel.medium, bytes: bytes, logoAllowed: false, logoDropped: dropped);
    }
    if (bytes <= maxBytes(QrErrorLevel.low)) {
      return QrLevelChoice._(QrErrorLevel.low, bytes: bytes, logoAllowed: false, logoDropped: dropped);
    }
    return QrLevelChoice._(null, bytes: bytes, logoAllowed: false, logoDropped: dropped);
  }
}

/// L'esito di [QrCapacity.choose].
final class QrLevelChoice {
  const QrLevelChoice._(this.level, {required this.bytes, required this.logoAllowed, required this.logoDropped});

  /// Null se il contenuto non sta in nessun QR.
  final QrErrorLevel? level;

  /// I byte UTF-8 del contenuto: servono al messaggio «Troppo lungo: N caratteri».
  final int bytes;

  /// True se il logo si puo' disegnare (livello H).
  final bool logoAllowed;

  /// True se il logo era chiesto ma non ci sta: «Testo troppo lungo per il logo».
  final bool logoDropped;

  bool get tooLong => level == null;

  /// Oltre [QrCapacity.denseBytes]: «QR molto fitto: avvicina il telefono».
  bool get dense => bytes > QrCapacity.denseBytes;
}

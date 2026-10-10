import 'package:meta/meta.dart';

/// Un rettangolo in coordinate NORMALIZZATE 0..1 rispetto all'immagine passata al motore,
/// origine in ALTO a sinistra, asse y verso il basso.
///
/// ⚑ Normalizzato e non in pixel: Vision restituisce gia' 0..1, PP-OCR lavora su
/// un'immagine ridotta; il parser dell'app ragiona in proporzioni («il prezzo e' il
/// riquadro piu' alto»), e cosi' non dipende dalla risoluzione della foto.
@immutable
final class Riquadro {
  const Riquadro({
    required this.sinistra,
    required this.alto,
    required this.larghezza,
    required this.altezza,
  });

  /// Da Vision: `boundingBox` normalizzato con origine in BASSO a sinistra.
  /// `alto = 1 − (y + h)`.
  ///
  /// ☠ La conversione vive qui, in Dart, e non in Swift: cosi' e' coperta da
  /// `riga_ocr_test.dart` e l'asse y capovolto non si nasconde in un file che nessun
  /// test tocca (F12.1.4).
  factory Riquadro.daVision(double x, double y, double w, double h) =>
      Riquadro(sinistra: x, alto: 1 - (y + h), larghezza: w, altezza: h);

  /// Da `{"x":..,"y":..,"w":..,"h":..}` (tollerante: numeri interi o decimali).
  factory Riquadro.fromJson(Map<String, Object?> json) => Riquadro(
    sinistra: _num(json['x']),
    alto: _num(json['y']),
    larghezza: _num(json['w']),
    altezza: _num(json['h']),
  );

  final double sinistra;
  final double alto;
  final double larghezza;
  final double altezza;

  double get destra => sinistra + larghezza;
  double get basso => alto + altezza;
  double get centroX => sinistra + larghezza / 2;
  double get centroY => alto + altezza / 2;

  /// Sovrapposizione verticale 0..1, misurata sul piu' BASSO (di altezza) dei due:
  /// serve a dire «stessa riga».
  ///
  /// ⚑ Divisa per l'altezza minore e non per l'unione: i centesimi in apice sono alti
  /// la meta' degli euro ma stanno tutti dentro la loro fascia, e devono valere 1.
  double sovrapposizioneVerticale(Riquadro altro) {
    final comune = (basso < altro.basso ? basso : altro.basso) -
        (alto > altro.alto ? alto : altro.alto);
    if (comune <= 0) return 0;
    final minore = altezza < altro.altezza ? altezza : altro.altezza;
    if (minore <= 0) return 0;
    final r = comune / minore;
    return r > 1 ? 1 : r;
  }

  /// `{"x":..,"y":..,"w":..,"h":..}`.
  Map<String, double> toJson() => {'x': sinistra, 'y': alto, 'w': larghezza, 'h': altezza};

  @override
  bool operator ==(Object other) =>
      other is Riquadro &&
      other.sinistra == sinistra &&
      other.alto == alto &&
      other.larghezza == larghezza &&
      other.altezza == altezza;

  @override
  int get hashCode => Object.hash(sinistra, alto, larghezza, altezza);

  @override
  String toString() => 'Riquadro(x: $sinistra, y: $alto, w: $larghezza, h: $altezza)';
}

/// Una riga di testo letta dal motore: testo, riquadro e confidenza 0..1.
@immutable
final class RigaOcr {
  const RigaOcr({required this.testo, required this.riquadro, required this.confidenza});

  /// Da `{"t":..,"x":..,"y":..,"w":..,"h":..,"c":..}` (il formato delle fixture,
  /// F12.1.17). `c` mancante vale 1.
  factory RigaOcr.fromJson(Map<String, Object?> json) => RigaOcr(
    testo: (json['t'] as String?) ?? '',
    riquadro: Riquadro.fromJson(json),
    confidenza: json['c'] == null ? 1 : _num(json['c']),
  );

  final String testo;
  final Riquadro riquadro;

  /// 0..1.
  final double confidenza;

  /// `{"t":..,"x":..,"y":..,"w":..,"h":..,"c":..}` (piatto, come le fixture).
  Map<String, Object?> toJson() => {'t': testo, ...riquadro.toJson(), 'c': confidenza};

  @override
  bool operator ==(Object other) =>
      other is RigaOcr &&
      other.testo == testo &&
      other.riquadro == riquadro &&
      other.confidenza == confidenza;

  @override
  int get hashCode => Object.hash(testo, riquadro, confidenza);

  @override
  String toString() => 'RigaOcr("$testo", $riquadro, c: $confidenza)';
}

/// Cosa si sta leggendo: cambia la strategia del motore (Android: immagine intera
/// contro strisce sovrapposte; iOS: `minimumTextHeight`).
enum OcrModo { cartellino, scontrino }

double _num(Object? v) => switch (v) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s) ?? 0,
  _ => 0,
};

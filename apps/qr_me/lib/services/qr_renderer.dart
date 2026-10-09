import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
// ☠ Con prefisso: qr_flutter esporta `QrEyeShape` (come il nostro dominio) e, tramite il
// pacchetto `qr`, `QrCode` (come la riga di Drift). Senza prefisso i nomi si scontrano.
import 'package:qr_flutter/qr_flutter.dart' as qf;

import '../domain/qr_capacity.dart';
import '../domain/qr_style.dart';

/// Il QR disegnato: a schermo ([widget]) e come PNG ([png]) con **gli stessi parametri**
/// (develop_microapps.md F17.1.7).
///
/// ⚑ **Un solo punto traduce `QrStyle` nei parametri di qr_flutter**: [painter]. Il widget e il
/// PNG lo chiamano entrambi; se lo traducessero separatamente, prima o poi l'immagine condivisa
/// differirebbe da quella vista (un colore, una forma, la misura del logo).
///
/// ⚑ Si usa `QrPainter` anche per il widget, e non `QrImageView`: `QrImageView` vuole il logo
/// come `ImageProvider` e lo ricarica a ogni build con un `FutureBuilder` (un fotogramma vuoto a
/// ogni cambio di stile), e il suo `padding` non sa quanto e' grande un modulo. Qui la zona di
/// rispetto si calcola in moduli veri.
///
/// ⚑ **Zona di rispetto sempre piena del colore di sfondo** ([quietModules] moduli per lato, come
/// vuole lo standard): con uno sfondo trasparente, sopra una pagina scura, la fotocamera non
/// trova il bordo chiaro di cui ha bisogno.
class QrRenderer {
  const QrRenderer();

  /// La zona di rispetto, in moduli, per lato (ISO/IEC 18004: 4).
  static const int quietModules = 4;

  /// Il lato del logo rispetto al lato del codice (zona di rispetto esclusa). ☠ Fisso: con H il
  /// QR regge il ~30% di moduli persi, e il 22% del lato e' ~5% dell'area, ben dentro anche
  /// contando il piatto del logo (F17.1.11 punto 4). La prova vera e' `ReadabilityCheck`.
  static const double logoFraction = 0.22;

  /// La scelta del livello per [payload] con [style]: M, H con il logo, ripiego L, o
  /// `tooLong` (F17.1.3). Le pagine la leggono **prima** di disegnare (F17.1.11 punto 7).
  QrLevelChoice choose(String payload, QrStyle style) =>
      QrCapacity.choose(payload, wantsLogo: style.hasLogo);

  /// Il livello di correzione per [payload] con [style].
  ///
  /// ☠ Lancia [ArgumentError] se il contenuto non sta in nessun QR: chi chiama deve aver
  /// guardato [choose] prima.
  QrErrorLevel levelFor(String payload, QrStyle style) =>
      choose(payload, style).level ??
      (throw ArgumentError.value(payload.length, 'payload', 'Troppo lungo per un QR'));

  /// Il QR come widget quadrato di lato [size], zona di rispetto inclusa. [logo] e' l'immagine
  /// di `LogoRenderer` (con il suo piatto); si disegna solo se il livello lo permette.
  Widget widget({
    required String payload,
    required QrStyle style,
    required double size,
    ui.Image? logo,
    String? semanticsLabel,
  }) {
    final layout = _layout(payload, style, logo);
    final quiet = size * quietModules / (layout.qr.moduleCount + 2 * quietModules);
    final codeSide = size - 2 * quiet;
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: Color(style.background),
          child: Padding(
            padding: EdgeInsets.all(quiet),
            child: CustomPaint(
              size: Size.square(codeSide),
              painter: painter(qr: layout.qr, style: style, logo: layout.logo, codeSide: codeSide),
            ),
          ),
        ),
      ),
    );
  }

  /// Il PNG quadrato di [pixels] lato, zona di rispetto inclusa: per «Condividi immagine» e per
  /// la verifica di leggibilita'.
  Future<Uint8List> png({
    required String payload,
    required QrStyle style,
    int pixels = 1024,
    ui.Image? logo,
  }) async {
    final layout = _layout(payload, style, logo);
    final side = pixels.toDouble();
    final quiet = side * quietModules / (layout.qr.moduleCount + 2 * quietModules);
    final codeSide = side - 2 * quiet;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(Rect.fromLTWH(0, 0, side, side), Paint()..color = Color(style.background));
    canvas.translate(quiet, quiet);
    painter(
      qr: layout.qr,
      style: style,
      logo: layout.logo,
      codeSide: codeSide,
    ).paint(canvas, Size.square(codeSide));
    final picture = recorder.endRecording();
    final image = await picture.toImage(pixels, pixels);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG del QR non generato');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  /// **Il** punto che traduce [style] nei parametri di qr_flutter. Pubblico perche' i test
  /// possano verificare la traduzione senza disegnare.
  qf.QrPainter painter({
    required qf.QrCode qr,
    required QrStyle style,
    required double codeSide,
    ui.Image? logo,
  }) {
    final fg = Color(style.foreground);
    final logoSide = codeSide * logoFraction;
    return qf.QrPainter.withQr(
      qr: qr,
      // ⚑ Senza fessure: con le fessure fra i moduli quadrati il colore di sfondo passa in righe
      // sottili, che ad alcune fotocamere sembrano moduli chiari.
      gapless: true,
      eyeStyle: qf.QrEyeStyle(
        eyeShape: switch (style.eyeShape) {
          QrEyeShape.square => qf.QrEyeShape.square,
          QrEyeShape.circle => qf.QrEyeShape.circle,
        },
        color: fg,
      ),
      dataModuleStyle: qf.QrDataModuleStyle(
        dataModuleShape: switch (style.moduleShape) {
          QrModuleShape.square => qf.QrDataModuleShape.square,
          QrModuleShape.circle => qf.QrDataModuleShape.circle,
        },
        color: fg,
      ),
      embeddedImage: logo,
      embeddedImageStyle: logo == null
          ? null
          : qf.QrEmbeddedImageStyle(size: Size.square(logoSide)),
    );
  }

  /// Il codice per [payload] al livello scelto, e il logo solo se il livello lo regge.
  ({qf.QrCode qr, ui.Image? logo}) _layout(String payload, QrStyle style, ui.Image? logo) {
    final choice = choose(payload, style);
    final level =
        choice.level ??
        (throw ArgumentError.value(payload.length, 'payload', 'Troppo lungo per un QR'));
    final qr = qf.QrCode.fromData(data: payload, errorCorrectLevel: errorCorrectLevelOf(level));
    return (qr: qr, logo: choice.logoAllowed ? logo : null);
  }

  /// Da [QrErrorLevel] del dominio alla costante di qr_flutter.
  static int errorCorrectLevelOf(QrErrorLevel level) => switch (level) {
    QrErrorLevel.low => qf.QrErrorCorrectLevel.L,
    QrErrorLevel.medium => qf.QrErrorCorrectLevel.M,
    QrErrorLevel.quartile => qf.QrErrorCorrectLevel.Q,
    QrErrorLevel.high => qf.QrErrorCorrectLevel.H,
  };
}

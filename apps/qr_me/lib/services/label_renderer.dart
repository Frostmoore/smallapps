import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/qr_style.dart';
import 'qr_renderer.dart';

/// «Genera etichetta» (Pro, `imageExport`; develop_microapps.md F17.10 punto 5): il QR con il
/// suo stile e del testo sotto, da stampare o da condividere come PNG.
///
/// ⚑ **Un solo disegno, tre usi**: [LabelPainter] disegna l'etichetta su una tela qualunque.
/// L'anteprima della pagina lo usa con un `CustomPaint`, il PNG ([LabelRenderer.png]) con un
/// `PictureRecorder`, e il PDF da stampare mette quel PNG su un foglio. L'anteprima non puo'
/// differire da cio' che esce dalla stampante (stessa regola di `QrRenderer`).

/// I formati dell'etichetta. `name` non si salva da nessuna parte: si puo' rinominare.
enum LabelFormat {
  /// Quadrata: QR grande, una riga di testo sotto. 70 × 70 mm stampata.
  square(aspect: 1, widthMm: 70, heightMm: 70),

  /// Rettangolare (verticale, 2:3): piu' spazio per il testo sotto. 60 × 90 mm stampata.
  ///
  /// ⚑ Verticale e non orizzontale: il testo resta **sotto** il QR come nella quadrata (F17.10),
  /// e su un foglio A4 ci si ritaglia attorno con le forbici senza girare niente.
  tall(aspect: 2 / 3, widthMm: 60, heightMm: 90);

  const LabelFormat({required this.aspect, required this.widthMm, required this.heightMm});

  /// Larghezza / altezza.
  final double aspect;

  /// La misura vera sul foglio stampato.
  final double widthMm;
  final double heightMm;
}

/// Disegna l'etichetta su una tela di qualunque misura: sfondo del colore dello stile, il QR
/// (con logo e colori, tramite [QrRenderer.paintSquare]) e il testo sotto, centrato, al massimo
/// due righe, rimpicciolito finche' ci sta.
///
/// ⚑ Il testo e' del colore del QR sul suo sfondo: il contrasto e' gia' quello che la pagina
/// Stile ha controllato per il codice (`contrast.dart`), quindi si legge.
class LabelPainter extends CustomPainter {
  const LabelPainter({
    required this.renderer,
    required this.payload,
    required this.style,
    required this.text,
    this.logo,
    this.fontFamily,
  });

  final QrRenderer renderer;
  final String payload;
  final QrStyle style;
  final String text;
  final ui.Image? logo;

  /// Il font del testo (nell'app Space Grotesk, quello dei titoli). Null: il font di sistema.
  final String? fontFamily;

  /// Il margine attorno a tutto, come frazione della larghezza.
  static const double padFraction = 0.05;

  /// Quanta altezza va al testo nell'etichetta quadrata.
  static const double squareTextFraction = 0.2;

  /// Dove stanno il QR e il testo in una tela di [size]. Pubblica per i test.
  static ({Rect qr, Rect text}) layout(Size size, {required bool hasText}) {
    final pad = size.width * padFraction;
    if (!hasText) {
      final side = size.shortestSide - 2 * pad;
      return (
        qr: Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side),
        text: Rect.zero,
      );
    }
    final textHeight = size.width >= size.height
        ? size.height * squareTextFraction
        : size.height - size.width; // ⚑ verticale: il QR prende tutta la larghezza
    final side = (size.height - textHeight - 2 * pad).clamp(0.0, size.width - 2 * pad);
    final qr = Rect.fromLTWH((size.width - side) / 2, pad, side, side);
    final text = Rect.fromLTRB(pad, qr.bottom, size.width - pad, size.height - pad);
    return (qr: qr, text: text);
  }

  /// Il testo impaginato per stare in [box]: due righe al massimo, rimpicciolito fino a ~1/6
  /// dell'altezza del riquadro, poi tagliato con «…».
  ///
  /// ⚑ Il punto di partenza ha anche un tetto sulla larghezza: nell'etichetta verticale il
  /// riquadro del testo e' alto, e una parola corta («Bar») uscirebbe enorme, fuori scala col QR.
  TextPainter layoutText(Rect box) {
    var size = box.height * 0.42 < box.width * 0.11 ? box.height * 0.42 : box.width * 0.11;
    final min = box.height * 0.16;
    while (true) {
      final tp = TextPainter(
        text: TextSpan(
          text: text.trim(),
          style: TextStyle(
            color: Color(style.foreground),
            fontSize: size,
            height: 1.15,
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation('wght', 700)],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(minWidth: box.width, maxWidth: box.width);
      if ((!tp.didExceedMaxLines && tp.height <= box.height) || size <= min) return tp;
      tp.dispose();
      size *= 0.92;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Color(style.background));
    final hasText = text.trim().isNotEmpty;
    final l = layout(size, hasText: hasText);
    renderer.paintSquare(
      canvas,
      l.qr.topLeft,
      payload: payload,
      style: style,
      side: l.qr.width,
      logo: logo,
    );
    if (!hasText) return;
    final tp = layoutText(l.text);
    tp.paint(canvas, Offset(l.text.left, l.text.top + (l.text.height - tp.height) / 2));
    tp.dispose();
  }

  @override
  bool shouldRepaint(LabelPainter old) =>
      old.payload != payload ||
      old.style != style ||
      old.text != text ||
      old.logo != logo ||
      old.fontFamily != fontFamily;
}

/// Il PNG e il PDF dell'etichetta.
class LabelRenderer {
  const LabelRenderer({this.renderer = const QrRenderer()});

  final QrRenderer renderer;

  /// La larghezza in pixel del PNG: 1200 su 60-70 mm sono ~450-500 dpi, nitido anche stampato.
  static const int defaultWidthPx = 1200;

  /// Il PNG dell'etichetta, largo [widthPx].
  Future<Uint8List> png({
    required String payload,
    required QrStyle style,
    required String text,
    required LabelFormat format,
    ui.Image? logo,
    String? fontFamily,
    int widthPx = defaultWidthPx,
  }) async {
    final size = Size(widthPx.toDouble(), (widthPx / format.aspect).roundToDouble());
    final recorder = ui.PictureRecorder();
    LabelPainter(
      renderer: renderer,
      payload: payload,
      style: style,
      text: text,
      logo: logo,
      fontFamily: fontFamily,
    ).paint(Canvas(recorder), size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG dell\'etichetta non generato');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  /// Il PDF da stampare: l'etichetta [png] alla sua misura vera ([LabelFormat.widthMm] ×
  /// [LabelFormat.heightMm]), in alto al centro del foglio [page] scelto nel dialogo di stampa,
  /// con un filo grigio attorno per ritagliarla.
  ///
  /// ⚑ Alla misura vera e non «adatta al foglio»: un'etichetta grande come un A4 non e'
  /// un'etichetta, e la stessa misura a ogni stampa la rende prevedibile.
  Future<Uint8List> pdf({
    required Uint8List png,
    required LabelFormat format,
    required PdfPageFormat page,
  }) async {
    final doc = pw.Document(title: 'QR Me', creator: 'QR Me');
    final image = pw.MemoryImage(png);
    doc.addPage(
      pw.Page(
        pageFormat: page,
        build: (_) => pw.Align(
          alignment: pw.Alignment.topCenter,
          child: pw.Container(
            width: format.widthMm * PdfPageFormat.mm,
            height: format.heightMm * PdfPageFormat.mm,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.3),
            ),
            child: pw.Image(image, fit: pw.BoxFit.fill),
          ),
        ),
      ),
    );
    return doc.save();
  }
}

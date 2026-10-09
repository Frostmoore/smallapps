import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:micro_core/micro_core.dart';

import '../data/qr_repository.dart';
import '../domain/qr_style.dart';
import '../features/style/logo_picker.dart' show kLogoIcons;

/// Il logo al centro del QR come immagine quadrata (develop_microapps.md F17.1.7).
///
/// ⚑ **Il piatto**: il logo si disegna sopra un quadrato (o un cerchio, per la foto rotonda)
/// del **colore di sfondo** dello stile, con il contenuto rientrato del [plateMargin] per lato.
/// Senza piatto i moduli sotto il logo si vedono a pezzi attorno al disegno, e la fotocamera
/// prova a leggerli come dati e si confonde. Con il piatto l'area e' semplicemente "persa", e
/// la correzione H la recupera.
///
/// ⚑ Testo, emoji e icone si disegnano con `TextPainter`: un'icona Material e' un carattere del
/// font MaterialIcons, e cosi' passa dalla stessa strada di un'emoji.
class LogoRenderer {
  const LogoRenderer({this._icons});

  final Map<String, IconData>? _icons;

  /// Il margine del contenuto dentro il piatto, per lato.
  static const double plateMargin = 0.12;

  /// Il lato della foto del logo salvata in `ImageStore`, una volta sola all'import.
  static const int photoSide = 512;

  /// Il logo per [logo] su un piatto di colore [backgroundArgb], lato [sizePx]. Icone e testo
  /// nel colore [foregroundArgb] (quello dei moduli: il logo "appartiene" al QR).
  ///
  /// Null per [NoLogo], per un'icona sconosciuta e per una foto che non si legge piu' (file
  /// cancellato a mano, backup senza immagini): meglio un QR senza logo che un errore.
  Future<ui.Image?> render(
    QrLogo logo, {
    required int backgroundArgb,
    required int sizePx,
    required ImageStore images,
    int foregroundArgb = 0xFF000000,
  }) async {
    switch (logo) {
      case NoLogo():
        return null;
      case TextLogo(:final text):
        return _glyph(
          text,
          null,
          backgroundArgb: backgroundArgb,
          foregroundArgb: foregroundArgb,
          sizePx: sizePx,
        );
      case IconLogo(:final iconId):
        final icon = (_icons ?? kLogoIcons)[iconId];
        if (icon == null) return null;
        return _glyph(
          String.fromCharCode(icon.codePoint),
          icon,
          backgroundArgb: backgroundArgb,
          foregroundArgb: foregroundArgb,
          sizePx: sizePx,
        );
      case PhotoLogo(:final imageName, :final round):
        try {
          final bytes = await images.resolve(imageName).readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          codec.dispose();
          try {
            return await _photo(
              frame.image,
              round: round,
              backgroundArgb: backgroundArgb,
              sizePx: sizePx,
            );
          } finally {
            frame.image.dispose();
          }
        } on Object catch (error, stack) {
          MicroLog.e('logo foto illeggibile: $imageName', error: error, stackTrace: stack);
          return null;
        }
    }
  }

  Future<ui.Image> _glyph(
    String text,
    IconData? icon, {
    required int backgroundArgb,
    required int foregroundArgb,
    required int sizePx,
  }) {
    final side = sizePx.toDouble();
    final inner = side * (1 - 2 * plateMargin);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _plate(canvas, side, backgroundArgb, round: false);

    // Si parte da un corpo che riempie il riquadro interno e si rimpicciolisce finche' il testo
    // ci sta: tre lettere larghe ("WWW") o un'emoji "alta" restano dentro il piatto.
    var fontSize = inner;
    late TextPainter tp;
    for (var i = 0; i < 12; i++) {
      tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            color: Color(foregroundArgb),
            fontFamily: icon?.fontFamily,
            package: icon?.fontPackage,
            fontWeight: icon == null ? FontWeight.w800 : null,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tp.width <= inner && tp.height <= inner) break;
      fontSize *= 0.85;
    }
    tp.paint(canvas, Offset((side - tp.width) / 2, (side - tp.height) / 2));
    final picture = recorder.endRecording();
    return picture.toImage(sizePx, sizePx).whenComplete(picture.dispose);
  }

  Future<ui.Image> _photo(
    ui.Image photo, {
    required bool round,
    required int backgroundArgb,
    required int sizePx,
  }) {
    final side = sizePx.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _plate(canvas, side, backgroundArgb, round: round);
    final inset = side * plateMargin;
    final dst = Rect.fromLTWH(inset, inset, side - 2 * inset, side - 2 * inset);
    // La foto e' gia' quadrata (ritagliata all'import); qui si centra comunque, per sicurezza.
    final s = photo.width < photo.height ? photo.width : photo.height;
    final src = Rect.fromLTWH(
      (photo.width - s) / 2,
      (photo.height - s) / 2,
      s.toDouble(),
      s.toDouble(),
    );
    canvas.save();
    if (round) {
      canvas.clipPath(Path()..addOval(dst));
    } else {
      canvas.clipRRect(RRect.fromRectAndRadius(dst, Radius.circular(dst.width * 0.12)));
    }
    canvas.drawImageRect(photo, src, dst, Paint()..filterQuality = FilterQuality.high);
    canvas.restore();
    final picture = recorder.endRecording();
    return picture.toImage(sizePx, sizePx).whenComplete(picture.dispose);
  }

  void _plate(Canvas canvas, double side, int backgroundArgb, {required bool round}) {
    final paint = Paint()..color = Color(backgroundArgb);
    final rect = Rect.fromLTWH(0, 0, side, side);
    if (round) {
      canvas.drawOval(rect, paint);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(side * 0.18)), paint);
    }
  }

  /// Importa una foto della galleria come logo: ritaglio **quadrato al centro** a [photoSide]
  /// px, salvata in `ImageStore` (bucket `QrLogoFiles.bucket`). Restituisce il percorso
  /// relativo per `PhotoLogo.imageName`.
  ///
  /// ⚑ **Il ritaglio rotondo non si "cuoce" nel file**: `ImageStore` salva JPEG, che non ha
  /// trasparenza, e un cerchio diventerebbe un cerchio su fondo nero. Il file e' il quadrato,
  /// e `PhotoLogo.round` lo ritaglia al disegno ([render]): cosi' l'utente puo' anche passare da
  /// quadrato a rotondo senza reimportare.
  ///
  /// ⚑ Una volta sola, all'import: decodificare una foto da 12 megapixel a ogni disegno del QR
  /// costerebbe secondi su un telefono economico.
  Future<Result<String>> importPhoto(Uint8List bytes, ImageStore images) async {
    final Uint8List square;
    try {
      // In un isolate: decodificare una foto grande sul thread della UI congela l'app.
      square = await compute(_cropSquare, bytes);
    } on Object catch (error, stack) {
      MicroLog.e('logo: foto non ritagliabile', error: error, stackTrace: stack);
      return Err(MicroError.unexpected(error, stack));
    }
    final stored = await images.importBytes(
      square,
      bucket: QrLogoFiles.bucket,
      maxLongSide: photoSide,
      thumbLongSide: 128,
      quality: 90,
    );
    return stored.fold<Result<String>>(ok: (s) => Ok(s.path), err: Err.new);
  }

  static Uint8List _cropSquare(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('Formato immagine non riconosciuto');
    // L'orientamento EXIF prima del ritaglio: una foto verticale scattata col telefono
    // girato sarebbe altrimenti ritagliata di lato.
    final oriented = img.bakeOrientation(decoded);
    final s = oriented.width < oriented.height ? oriented.width : oriented.height;
    final cropped = img.copyCrop(
      oriented,
      x: (oriented.width - s) ~/ 2,
      y: (oriented.height - s) ~/ 2,
      width: s,
      height: s,
    );
    final resized = s > photoSide
        ? img.copyResize(cropped, width: photoSide, height: photoSide)
        : cropped;
    return Uint8List.fromList(img.encodePng(resized));
  }
}

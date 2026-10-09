import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:micro_core/micro_core.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/qr_style.dart';
import 'qr_renderer.dart';

/// Lo scanner su un file immagine non c'e' (emulatore senza ML Kit, simulatore, piattaforma
/// senza implementazione). ⚑ Diverso da "nessun QR trovato": chi lo riceve deve dire "non
/// verificato", non "illeggibile".
class QrReaderUnavailable implements Exception {
  const QrReaderUnavailable(this.cause);

  final Object cause;

  @override
  String toString() => 'QrReaderUnavailable($cause)';
}

/// Legge i QR da un file immagine. Interfaccia perche' i test (condivisione, "Da immagine",
/// verifica di leggibilita') non hanno una piattaforma su cui gira lo scanner.
abstract interface class QrImageReader {
  /// I `rawValue` dei QR trovati in [path], nell'ordine dello scanner; vuota se non ce ne sono.
  /// Lancia [QrReaderUnavailable] se lo scanner non e' disponibile.
  Future<List<String>> read(String path);
}

/// [QrImageReader] su `MobileScannerController.analyzeImage` (ML Kit su Android, Vision su iOS).
///
/// ⚑ Solo QR (`BarcodeFormat.qrCode`), come la fotocamera: un codice a barre in uno screenshot
/// non e' il mestiere dell'app.
class MobileScannerImageReader implements QrImageReader {
  const MobileScannerImageReader();

  @override
  Future<List<String>> read(String path) async {
    // ⚑ Un controller usa e getta: `analyzeImage` non ha bisogno della fotocamera accesa, e non
    // si tocca quello della pagina di scansione (che potrebbe non esistere).
    final controller = MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.qrCode],
    );
    try {
      final capture = await controller.analyzeImage(path, formats: const [BarcodeFormat.qrCode]);
      return [
        for (final b in capture?.barcodes ?? const <Barcode>[])
          if (b.rawValue case final String raw when raw.isNotEmpty) raw,
      ];
    } on MissingPluginException catch (e) {
      throw QrReaderUnavailable(e);
    } on UnimplementedError catch (e) {
      throw QrReaderUnavailable(e);
    } on UnsupportedError catch (e) {
      throw QrReaderUnavailable(e);
    } on MobileScannerBarcodeException catch (e) {
      // ☠ Un'immagine che lo scanner non sa decodificare (o in cui non trova nulla) arriva come
      // eccezione e non come lista vuota: per chi chiama e' "nessun QR", non "non disponibile".
      MicroLog.w('analyzeImage: ${e.message}');
      return const [];
    } on MobileScannerException catch (e) {
      if (e.errorCode == MobileScannerErrorCode.unsupported) throw QrReaderUnavailable(e);
      MicroLog.w('analyzeImage: ${e.errorCode.name}', error: e.errorDetails?.message);
      return const [];
    } on PlatformException catch (e) {
      throw QrReaderUnavailable(e);
    } finally {
      await controller.dispose();
    }
  }
}

/// L'esito della verifica: [unknown] e' "non verificato" (grigio), **non** "illeggibile".
enum Readability { readable, unreadable, unknown }

/// Rilegge il PNG del QR con lo scanner vero (develop_microapps.md F17.1.7).
///
/// ⚑ E' la difesa vera contro i QR «carini ma illeggibili»: le regole di contrasto
/// (`Contrast`) sono euristiche, questo e' il test. Si confronta il `rawValue` con il payload
/// **esattamente**: un QR che si legge come un'altra stringa e' peggio di uno che non si legge.
///
/// ☠ Su emulatore/simulatore `analyzeImage` puo' non esserci: il risultato e'
/// [Readability.unknown], mai [Readability.unreadable] (F17.1.7).
class ReadabilityCheck {
  ReadabilityCheck(
    this._reader, {
    this._renderer = const QrRenderer(),
    Future<Directory> Function()? tempDir,
  }) : _tempDir = tempDir ?? getTemporaryDirectory;

  final QrImageReader _reader;
  final QrRenderer _renderer;
  final Future<Directory> Function() _tempDir;

  /// Il lato del PNG di prova. ⚑ Piu' piccolo di quello condiviso (1024): basta allo scanner, e
  /// la verifica gira a ogni pausa dell'utente mentre cambia stile.
  static const int pixels = 720;

  Future<Readability> check({
    required String payload,
    required QrStyle style,
    ui.Image? logo,
  }) async {
    File? file;
    try {
      if (_renderer.choose(payload, style).tooLong) return Readability.unreadable;
      final png = await _renderer.png(payload: payload, style: style, pixels: pixels, logo: logo);
      final dir = await _tempDir();
      file = File(p.join(dir.path, 'qrme_check_${DateTime.now().microsecondsSinceEpoch}.png'));
      await file.writeAsBytes(png, flush: true);
      final values = await _reader.read(file.path);
      return values.contains(payload) ? Readability.readable : Readability.unreadable;
    } on QrReaderUnavailable catch (e) {
      MicroLog.i('verifica di leggibilita\' non disponibile', data: e.cause.toString());
      return Readability.unknown;
    } on Object catch (error, stack) {
      // Qualunque altro guasto (disco, rendering): non e' una prova che il QR sia illeggibile.
      MicroLog.e('verifica di leggibilita\' fallita', error: error, stackTrace: stack);
      return Readability.unknown;
    } finally {
      try {
        await file?.delete();
      } on Object {
        // Un file temporaneo rimasto lo pulisce il sistema.
      }
    }
  }
}

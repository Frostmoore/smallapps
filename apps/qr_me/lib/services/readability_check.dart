import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/qr_style.dart';
import 'qr_renderer.dart';

/// Il lettore su un file immagine non c'e' (libreria nativa di ZXing non caricabile: sotto
/// `flutter test` sul PC, o su una piattaforma senza il plugin). ⚑ Diverso da "nessun QR
/// trovato": chi lo riceve deve dire "non verificato", non "illeggibile".
class QrReaderUnavailable implements Exception {
  const QrReaderUnavailable(this.cause);

  final Object cause;

  @override
  String toString() => 'QrReaderUnavailable($cause)';
}

/// Legge i QR da un file immagine. Interfaccia perche' i test (condivisione, "Da immagine",
/// verifica di leggibilita') non hanno una piattaforma su cui gira il lettore nativo.
abstract interface class QrImageReader {
  /// I testi dei QR trovati in [path], nell'ordine del lettore; vuota se non ce ne sono.
  /// Lancia [QrReaderUnavailable] se il lettore non e' disponibile.
  Future<List<String>> read(String path);
}

/// [QrImageReader] su ZXing C++ (`flutter_zxing`, FFI), uguale su Android e iOS.
///
/// ⚑ ZXing e non ML Kit/Vision (2026-10-09, decisione del proprietario): la decodifica gira
/// tutta dentro l'app, nessun dato esce dal telefono (develop_microapps.md F17.1.10). E a
/// differenza di ML Kit legge anche sull'emulatore: [QrReaderUnavailable] resta per i guasti veri.
///
/// ⚑ Solo QR (`Format.qrCode`), come la fotocamera: un codice a barre in uno screenshot non e'
/// il mestiere dell'app.
class ZxingImageReader implements QrImageReader {
  /// [tryInverted]: legge anche i QR chiari su fondo scuro. Si' per quello che l'utente vuole
  /// leggere («Da immagine», condivisione); no per la verifica di leggibilita' (vedi
  /// [ZxingImageReader.strict]).
  const ZxingImageReader({this.tryInverted = true});

  /// Il lettore della verifica di leggibilita' (F17.1.7): niente QR invertiti.
  ///
  /// ☠ Molti lettori (la fotocamera di diversi Android, varie app) non leggono un QR invertito:
  /// dire «Leggibile» perche' ZXing ci riesce provando anche l'inverso sarebbe una promessa
  /// falsa. Lo stile invertito ha gia' il suo avviso da `Contrast.inverted`.
  const ZxingImageReader.strict() : tryInverted = false;

  final bool tryInverted;

  /// Il lato massimo a cui ZXing riduce l'immagine prima di cercare. ⚑ Piu' del default (768):
  /// uno screenshot intero di un telefono (1080x2400) ridotto a 768 lascia un QR piccolo con
  /// moduli di 1-2 pixel. 1600 resta sotto il decimo di secondo su un telefono medio.
  static const int maxSize = 1600;

  @override
  Future<List<String>> read(String path) async {
    final inverted = tryInverted;
    try {
      // ⚑ In un isolate a parte: decodificare il PNG e cercare il QR sono decine di millisecondi
      // di CPU, e la verifica di leggibilita' gira a ogni pausa mentre l'utente cambia stile.
      // La libreria nativa si apre in ogni isolate per conto suo (`DynamicLibrary`), va bene.
      // Si restituiscono solo stringhe: tutto il resto di `Codes` non serve fuori.
      final (texts, error) = await Isolate.run(() async {
        final codes = await zx.readBarcodesImagePathString(
          path,
          DecodeParams(
            format: Format.qrCode,
            tryHarder: true,
            tryInverted: inverted,
            tryDownscale: true,
            maxSize: maxSize,
            isMultiScan: true,
          ),
        );
        return (
          [
            for (final c in codes.codes)
              if (c.isValid && (c.text ?? '').isNotEmpty) c.text!,
          ],
          codes.error,
        );
      });
      // ☠ Un file che non e' un'immagine (o e' troncato) torna come `error` e non come
      // eccezione: per chi chiama e' "nessun QR", non "non disponibile".
      if (texts.isEmpty && error != null) MicroLog.w('lettura QR da file: $error');
      return texts;
    } on ArgumentError catch (e) {
      // `DynamicLibrary.open` fallito: la libreria nativa non c'e' (test sul PC).
      throw QrReaderUnavailable(e);
    } on UnsupportedError catch (e) {
      throw QrReaderUnavailable(e);
    } on MissingPluginException catch (e) {
      throw QrReaderUnavailable(e);
    }
  }
}

/// L'esito della verifica: [unknown] e' "non verificato" (grigio), **non** "illeggibile".
enum Readability { readable, unreadable, unknown }

/// Rilegge il PNG del QR con il lettore vero, ZXing (develop_microapps.md F17.1.7).
///
/// ⚑ E' la difesa vera contro i QR «carini ma illeggibili»: le regole di contrasto
/// (`Contrast`) sono euristiche, questo e' il test. Si confronta il `rawValue` con il payload
/// **esattamente**: un QR che si legge come un'altra stringa e' peggio di uno che non si legge.
///
/// ☠ Se il lettore non c'e' ([QrReaderUnavailable]: libreria nativa non caricata) il risultato
/// e' [Readability.unknown], mai [Readability.unreadable] (F17.1.7). Con ZXing succede solo per
/// guasti veri: legge anche sull'emulatore e sul simulatore.
class ReadabilityCheck {
  ReadabilityCheck(
    this._reader, {
    this._renderer = const QrRenderer(),
    Future<Directory> Function()? tempDir,
  }) : _tempDir = tempDir ?? getTemporaryDirectory;

  final QrImageReader _reader;
  final QrRenderer _renderer;
  final Future<Directory> Function() _tempDir;

  /// Il lato del PNG di prova. ⚑ Piu' piccolo di quello condiviso (1024): basta al lettore, e
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

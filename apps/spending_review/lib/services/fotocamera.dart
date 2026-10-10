import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:micro_core/micro_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Scatto e ritaglio al mirino (develop_microapps.md F12.1.13).
///
/// ⚑ **Perche' si ritaglia prima dell'OCR**: il caso in cui il motore rende e' **un** cartellino
/// inquadrato da vicino (f12-ocr.md §7: le foto larghe del web sono il caso sfavorevole, il 78%
/// delle cifre). Passare al motore la foto intera vorrebbe dire fargli leggere anche i cartellini
/// vicini, gli scaffali, i prezzi dei prodotti accanto, e far scegliere al parser quello giusto.
abstract final class Fotocamera {
  /// Il margine aggiunto al mirino su ogni lato, come frazione del suo lato: perdona un
  /// cartellino inquadrato di poco storto o un centesimo in apice che sfiora l'angolo.
  static const double margine = 0.04;

  /// Ritaglia la foto al rettangolo del mirino ([mirino] in frazioni 0..1 dell'[anteprima],
  /// convertite tenendo conto del rapporto foto/anteprima e della rotazione EXIF) e la salva JPEG
  /// 92 in [cartella] (default `getTemporaryDirectory()`). Ritorna il percorso del ritaglio.
  ///
  /// ⚑ In `Isolate.run`: decodificare una foto da 12 MP sul thread dell'interfaccia lo blocca
  /// per 300-800 ms, e la fotocamera resta montata (si puo' scattare di nuovo subito).
  /// ☠ **La foto originale si cancella qui**, nel `finally`, ritaglio riuscito o no: e' la regola
  /// di privacy di F12.1.13 (nessuna foto resta sul telefono). Il ritaglio lo cancella
  /// `LetturaService` dopo averlo letto.
  static Future<String> ritagliaAlMirino(
    String percorsoFoto,
    Rect mirino, {
    required Size anteprima,
    String? cartella,
  }) async {
    final dir = cartella ?? (await getTemporaryDirectory()).path;
    final uscita = p.join(dir, 'sr_ritaglio_${DateTime.now().microsecondsSinceEpoch}.jpg');
    try {
      final f = (l: mirino.left, t: mirino.top, r: mirino.right, b: mirino.bottom);
      final a = (w: anteprima.width, h: anteprima.height);
      await Isolate.run(() => _ritaglia(percorsoFoto, uscita, f, a));
      return uscita;
    } finally {
      await cancellaSeEsiste(percorsoFoto);
    }
  }

  static void _ritaglia(
    String ingresso,
    String uscita,
    ({double l, double t, double r, double b}) f,
    ({double w, double h}) a,
  ) {
    final decodificata = img.decodeImage(File(ingresso).readAsBytesSync());
    if (decodificata == null) throw const FormatException('foto illeggibile');
    // ☠ L'orientamento EXIF va applicato PRIMA di calcolare il ritaglio: una foto verticale
    // salvata coricata con il flag di rotazione (quasi tutti i telefoni) ritaglierebbe la zona
    // sbagliata (F12.1.16 punto 3).
    final foto = img.bakeOrientation(decodificata);
    final r = rettangoloNellaFoto(
      Size(foto.width.toDouble(), foto.height.toDouble()),
      Size(a.w, a.h),
      Rect.fromLTRB(f.l, f.t, f.r, f.b),
    );
    final ritaglio = img.copyCrop(
      foto,
      x: r.left.round(),
      y: r.top.round(),
      width: math.max(1, r.width.round()),
      height: math.max(1, r.height.round()),
    );
    File(uscita).writeAsBytesSync(img.encodeJpg(ritaglio, quality: 92));
  }

  /// Il rettangolo della foto (in pixel) che corrisponde al [mirino] (frazioni 0..1 dell'area
  /// di [anteprima]), con l'anteprima mostrata **a riempimento** (`BoxFit.cover`, centrata): la
  /// foto e' piu' grande dello schermo in una delle due direzioni e ne deborda in parti uguali.
  /// Aggiunge [margineFrazione] del lato del mirino su ogni lato e resta dentro la foto.
  ///
  /// ⚑ Funzione pura e pubblica per i test (test/services/fotocamera_test.dart): e' il conto che,
  /// sbagliato, fa leggere al motore la meta' di un cartellino.
  static Rect rettangoloNellaFoto(Size foto, Size anteprima, Rect mirino, {double margineFrazione = margine}) {
    final scala = math.max(anteprima.width / foto.width, anteprima.height / foto.height);
    final debordaX = (foto.width * scala - anteprima.width) / 2;
    final debordaY = (foto.height * scala - anteprima.height) / 2;
    Offset inFoto(double fx, double fy) =>
        Offset((fx * anteprima.width + debordaX) / scala, (fy * anteprima.height + debordaY) / scala);
    final a = inFoto(mirino.left, mirino.top);
    final b = inFoto(mirino.right, mirino.bottom);
    final mx = (b.dx - a.dx) * margineFrazione;
    final my = (b.dy - a.dy) * margineFrazione;
    return Rect.fromLTRB(
      (a.dx - mx).clamp(0, foto.width),
      (a.dy - my).clamp(0, foto.height),
      (b.dx + mx).clamp(0, foto.width),
      (b.dy + my).clamp(0, foto.height),
    );
  }

  /// Cancella [percorso] se c'e'; non lancia mai (un file gia' sparito va bene).
  static Future<void> cancellaSeEsiste(String percorso) async {
    try {
      final f = File(percorso);
      if (f.existsSync()) await f.delete();
    } on Object catch (e) {
      MicroLog.w('foto non cancellata: $e');
    }
  }
}

/// La fotocamera vista da una pagina con il mirino (Cartellino, Scontrino).
///
/// ⚑ Un'interfaccia sopra il plugin `camera` e non il `CameraController` usato direttamente:
/// i test di widget non hanno una fotocamera, e con `ObiettivoFinto` (test/widget/
/// sr_test_harness.dart) la pagina si prova intera (mirino, scatto, «Leggo…», risultato).
abstract interface class Obiettivo {
  /// Chiede il permesso e accende la fotocamera posteriore. Lancia se non si puo' (permesso
  /// negato: `CameraException` con codice `CameraAccessDenied…`; nessuna fotocamera: StateError).
  Future<void> apri();

  /// L'anteprima a riempimento dello spazio dato (`BoxFit.cover`, centrata: e' l'ipotesi di
  /// [Fotocamera.rettangoloNellaFoto]).
  Widget anteprima();

  /// Scatta e ritorna il percorso del JPEG (nella cartella temporanea del plugin).
  Future<String> scatta();

  /// Accende o spegne la torcia; false se non c'e' (emulatore, molti telefoni economici).
  Future<bool> torcia(bool accesa);

  /// Spegne la fotocamera. Idempotente.
  Future<void> chiudi();
}

/// L'[Obiettivo] vero, sopra il plugin `camera` (CameraX su Android, AVFoundation su iOS).
class ObiettivoCamera implements Obiettivo {
  CameraController? _controller;

  @override
  Future<void> apri() async {
    final camere = await availableCameras();
    if (camere.isEmpty) throw StateError('nessuna fotocamera');
    final posteriore = camere.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => camere.first,
    );
    // ⚑ veryHigh (F12.1.12): i centesimi in apice dei cartellini sono piccoli; il motore riduce
    // comunque il lato lungo a 2000 px. ⚑ enableAudio: false: niente microfono, ne' permesso ne'
    // NSMicrophoneUsageDescription (F12.1.15).
    final c = CameraController(posteriore, ResolutionPreset.veryHigh, enableAudio: false);
    _controller = c;
    await c.initialize();
    try {
      await c.setFlashMode(FlashMode.off);
    } on Object {
      // Senza flash: va bene, lo scatto non lo usa.
    }
  }

  @override
  Widget anteprima() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return const ColoredBox(color: Colors.black);
    final dimensione = c.value.previewSize;
    // ☠ `previewSize` e' in orizzontale (lato lungo come larghezza) anche col telefono in
    // verticale: per riempire lo schermo verticale si scambiano i lati.
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: dimensione?.height ?? 3,
          height: dimensione?.width ?? 4,
          child: CameraPreview(c),
        ),
      ),
    );
  }

  @override
  Future<String> scatta() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) throw StateError('fotocamera spenta');
    final foto = await c.takePicture();
    return foto.path;
  }

  @override
  Future<bool> torcia(bool accesa) async {
    final c = _controller;
    if (c == null) return false;
    try {
      await c.setFlashMode(accesa ? FlashMode.torch : FlashMode.off);
      return true;
    } on Object catch (e) {
      MicroLog.w('torcia: $e');
      return false;
    }
  }

  @override
  Future<void> chiudi() async {
    final c = _controller;
    _controller = null;
    await c?.dispose();
  }
}

/// «Da una foto»: il selettore di sistema. Ritorna i percorsi delle **copie** temporanee che il
/// plugin crea (mai gli originali dell'utente), vuoto se annullato.
typedef ScegliFoto = Future<List<String>> Function({required bool multiple});

/// Il selettore vero (`image_picker`, photo picker di sistema: nessun permesso su Android 13+ e
/// iOS). ⚑ Fino a 4 foto per lo scontrino (F12.1.12), una per il cartellino.
Future<List<String>> scegliFotoDiSistema({required bool multiple}) async {
  final picker = ImagePicker();
  if (multiple) {
    final foto = await picker.pickMultiImage(limit: 4);
    return [for (final f in foto.take(4)) f.path];
  }
  final foto = await picker.pickImage(source: ImageSource.gallery);
  return foto == null ? const [] : [foto.path];
}

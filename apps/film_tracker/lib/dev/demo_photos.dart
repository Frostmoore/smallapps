import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../data/film_repository.dart';
import '../domain/film_types.dart';
import '../domain/roll_status.dart';
import '../features/photos/image_store_provider.dart';
import 'demo_data.dart';

/// Le foto dei dati di esempio: paesaggi stilizzati disegnati in codice, tre per ogni rullino
/// dell'archivio, in bianco e nero per le pellicole in bianco e nero.
///
/// ⚑ Perche' esistono: il foglio provini e il PDF dell'anno senza foto mostrano solo le
/// strisce segnaposto, e gli screenshot degli store devono far vedere l'app com'e' davvero
/// usata. Disegnate e non foto vere nel repository: niente diritti da chiarire, niente
/// megabyte negli asset, e passano dallo stesso `ImageStore` delle foto dell'utente
/// (ridimensionamento, miniature, percorsi relativi).
///
/// ☠ Solo in debug con `FT_DEMO=true`, come `seedDemoData`.
Future<void> seedDemoPhotos(AppDatabase db, ImageStore store) async {
  if (!demoEnabled) return;
  final repo = FilmRepository(db);
  final archivio = await repo.allRolls(section: RollSection.archive);
  for (final roll in archivio) {
    if ((await repo.imagesFor(roll.id)).isNotEmpty) continue;
    final biancoNero = await _isBlackAndWhite(repo, roll);
    for (var i = 0; i < 3; i++) {
      final bytes = demoLandscape(seed: roll.sequenceNumber * 10 + i, blackAndWhite: biancoNero);
      final stored = await store.importBytes(bytes, bucket: rollImageBucket);
      final image = stored.valueOrNull;
      if (image != null) await repo.addImage(rollId: roll.id, image: image);
    }
  }
}

Future<bool> _isBlackAndWhite(FilmRepository repo, FilmRoll roll) async {
  final id = roll.filmStockId;
  if (id == null) return false;
  return (await repo.stockById(id))?.processEnum == FilmProcess.bw;
}

/// Un paesaggio da cartolina, 1200×800 JPEG: cielo sfumato, sole, due catene di montagne e
/// un prato, con i colori scelti dal [seed]. Puro: stesso seme, stessa immagine.
Uint8List demoLandscape({required int seed, bool blackAndWhite = false}) {
  const w = 1200;
  const h = 800;
  final r = Random(seed);
  const tavolozze = <List<int>>[
    // cielo alto, cielo basso, montagne lontane, montagne vicine, prato, sole
    [0xF2B36B, 0xF9E1B5, 0x9C7A8E, 0x4E3B4C, 0x3D4A2E, 0xFFF1D0],
    [0x6FA3C7, 0xD8E7EF, 0x8EA3B5, 0x3F5466, 0x5B6B3A, 0xFFFFFF],
    [0xC9706A, 0xF4C49B, 0x7A5C6E, 0x3B2E3A, 0x2F3A2A, 0xFFE2B8],
    [0x2E3A5C, 0x8C7BA6, 0x4A4F70, 0x23263A, 0x1C2230, 0xF7E7C6],
    [0xA8C3B0, 0xE9EFD9, 0x7E9488, 0x3E5247, 0x6B7A3C, 0xFFFFF0],
  ];
  final t = tavolozze[r.nextInt(tavolozze.length)];
  img.ColorRgb8 c(int rgb) => img.ColorRgb8((rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF);
  int mix(int a, int b, double k) {
    int ch(int s) => (((a >> s) & 0xFF) * (1 - k) + ((b >> s) & 0xFF) * k).round();
    return (ch(16) << 16) | (ch(8) << 8) | ch(0);
  }

  final im = img.Image(width: w, height: h);
  // Il cielo, riga per riga.
  for (var y = 0; y < h; y++) {
    img.drawLine(im, x1: 0, y1: y, x2: w - 1, y2: y, color: c(mix(t[0], t[1], y / (h * 0.7))));
  }
  img.fillCircle(im, x: 200 + r.nextInt(800), y: 150 + r.nextInt(180), radius: 40 + r.nextInt(40), color: c(t[5]), antialias: true);

  List<img.Point> catena(double base, double altezza, int punti) {
    final v = <img.Point>[img.Point(0, h)];
    for (var i = 0; i <= punti; i++) {
      final x = w * i / punti;
      final y = h * base - r.nextDouble() * h * altezza;
      v.add(img.Point(x, y));
    }
    return v..add(img.Point(w, h));
  }

  img.fillPolygon(im, vertices: catena(0.62, 0.28, 7), color: c(t[2]));
  img.fillPolygon(im, vertices: catena(0.74, 0.22, 5), color: c(t[3]));
  img.fillPolygon(im, vertices: catena(0.88, 0.06, 4), color: c(t[4]));

  final finale = blackAndWhite ? img.grayscale(im) : im;
  return Uint8List.fromList(img.encodeJpg(finale, quality: 88));
}

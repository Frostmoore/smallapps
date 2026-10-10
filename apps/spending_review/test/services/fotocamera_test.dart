import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:spending_review/features/cartellino/cartellino_camera_page.dart';
import 'package:spending_review/features/common/mirino.dart';
import 'package:spending_review/services/fotocamera.dart';

/// Il ritaglio al mirino (develop_microapps.md F12.1.13): il conto che, sbagliato, fa leggere al
/// motore meta' cartellino; e la regola di privacy (la foto originale si cancella sempre).
void main() {
  group('rettangoloNellaFoto (anteprima a riempimento)', () {
    test('foto e anteprima con lo stesso rapporto: le frazioni passano dritte', () {
      final r = Fotocamera.rettangoloNellaFoto(
        const Size(3000, 4000),
        const Size(300, 400),
        const Rect.fromLTRB(0.1, 0.25, 0.9, 0.75),
        margineFrazione: 0,
      );
      expect(r, const Rect.fromLTRB(300, 1000, 2700, 3000));
    });

    test('foto 3:4 su uno schermo piu\' stretto (9:19,5): i lati della foto debordano, il centro resta', () {
      // Schermo 390×845: scala = max(390/3000, 845/4000) = 0,21125; la foto mostrata e' 633,75 di
      // larghezza, deborda di 121,875 dp per lato.
      final r = Fotocamera.rettangoloNellaFoto(
        const Size(3000, 4000),
        const Size(390, 845),
        const Rect.fromLTRB(0, 0.5, 1, 0.5),
        margineFrazione: 0,
      );
      expect(r.left, closeTo(121.875 / 0.21125, 0.01));
      expect(r.right, closeTo(3000 - 121.875 / 0.21125, 0.01));
      expect(r.top, closeTo(2000, 0.01));
    });

    test('il margine allarga il mirino senza uscire dalla foto', () {
      final r = Fotocamera.rettangoloNellaFoto(
        const Size(1000, 1000),
        const Size(100, 100),
        const Rect.fromLTRB(0, 0, 0.5, 0.5),
      );
      expect(r.left, 0);
      expect(r.top, 0);
      expect(r.right, closeTo(500 + 500 * Fotocamera.margine, 0.001));
    });
  });

  test('il mirino del cartellino e\' 86% della larghezza e 4:3', () {
    final m = CartellinoCameraPage.mirino(const Size(412, 800));
    expect(m.width, closeTo(412 * 0.86, 0.001));
    expect(m.width / m.height, closeTo(4 / 3, 0.001));
    final f = inFrazioni(m, const Size(412, 800));
    expect(f.left, closeTo(0.07, 0.001));
  });

  test('ritagliaAlMirino: JPEG del ritaglio scritto, foto originale cancellata', () async {
    final dir = Directory.systemTemp.createTempSync('sr_ritaglio_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final foto = File('${dir.path}/foto.jpg')..writeAsBytesSync(img.encodeJpg(img.Image(width: 400, height: 300)));
    final ritaglio = await Fotocamera.ritagliaAlMirino(
      foto.path,
      const Rect.fromLTRB(0.25, 0.25, 0.75, 0.75),
      anteprima: const Size(400, 300),
      cartella: dir.path,
    );
    expect(foto.existsSync(), isFalse);
    final letto = img.decodeJpg(File(ritaglio).readAsBytesSync())!;
    expect(letto.width, closeTo(200 * (1 + 2 * Fotocamera.margine), 1));
    expect(letto.height, closeTo(150 * (1 + 2 * Fotocamera.margine), 1));
  });

  test('☠ foto illeggibile: errore, ma l\'originale si cancella lo stesso', () async {
    final dir = Directory.systemTemp.createTempSync('sr_ritaglio_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final foto = File('${dir.path}/rotta.jpg')..writeAsBytesSync([1, 2, 3]);
    await expectLater(
      Fotocamera.ritagliaAlMirino(foto.path, const Rect.fromLTRB(0, 0, 1, 1), anteprima: const Size(1, 1), cartella: dir.path),
      throwsA(anything),
    );
    expect(foto.existsSync(), isFalse);
  });
}

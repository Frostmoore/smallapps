import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:trashcan/app/waste_presets.dart';
import 'package:trashcan/services/trashcan_widget.dart';

/// L'icona del widget di sistema.
///
/// ⚑ Perché questi test esistono: il widget non può disegnare un glifo, quindi l'icona del
/// tipo di rifiuto viene rasterizzata in un PNG dal lato Dart. Se la rasterizzazione
/// producesse un'immagine **vuota** non ci sarebbe nessun errore da nessuna parte: il
/// provider mostrerebbe un quadratino trasparente e il widget sembrerebbe semplicemente
/// senza icona. È esattamente il tipo di difetto che nessuno segnala e che si scopre da una
/// recensione.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// I pixel con alpha maggiore di zero: quanto inchiostro c'è davvero nell'immagine.
  Future<int> inkedPixels(Uint8List png) async {
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final raw = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    frame.image.dispose();
    codec.dispose();

    var inked = 0;
    for (var i = 3; i < raw!.lengthInBytes; i += 4) {
      if (raw.getUint8(i) > 0) inked++;
    }
    return inked;
  }

  group('icona del widget', () {
    test('ogni icona della mappa produce un PNG con dentro qualcosa', () async {
      for (final entry in WasteIcons.byKey.entries) {
        final png = await TrashcanWidget.renderIcon(entry.value);

        // La firma PNG: se il formato cambiasse, BitmapFactory.decodeFile restituirebbe
        // null e l'icona sparirebbe senza errori.
        expect(
          png.sublist(0, 8),
          <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
          reason: '${entry.key} non e un PNG',
        );

        final inked = await inkedPixels(png);
        expect(
          inked,
          greaterThan(200),
          reason: "l'icona ${entry.key} e quasi vuota: il glifo non e stato disegnato",
        );
      }
    });

    test('il glifo sta dentro il riquadro e non lo riempie tutto', () async {
      final png = await TrashcanWidget.renderIcon(WasteIcons.resolve('recycle'));
      final inked = await inkedPixels(png);
      final total = TrashcanWidget.iconSide * TrashcanWidget.iconSide;

      // Un glifo che copre tutto il riquadro vuol dire che si sta disegnando un rettangolo
      // pieno, cioe' il carattere di ripiego "tofu" del font mancante.
      expect(inked, lessThan(total * 0.9));
    });

    test('il glifo e bianco, perche a tingerlo e il provider Kotlin', () async {
      final png = await TrashcanWidget.renderIcon(WasteIcons.resolve('trash'));
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      final raw = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      frame.image.dispose();
      codec.dispose();

      // Il pixel piu' opaco che si trova deve essere bianco. Se Dart lo colorasse gia', il
      // setColorFilter del provider lavorerebbe su una base sbagliata.
      var found = false;
      for (var i = 0; i < raw!.lengthInBytes; i += 4) {
        if (raw.getUint8(i + 3) == 255) {
          expect(raw.getUint8(i), 255, reason: 'canale rosso');
          expect(raw.getUint8(i + 1), 255, reason: 'canale verde');
          expect(raw.getUint8(i + 2), 255, reason: 'canale blu');
          found = true;
          break;
        }
      }
      expect(found, isTrue, reason: 'nessun pixel completamente opaco');
    });

    test('una chiave sconosciuta ripiega su un icona vera, non su un vuoto', () async {
      final png = await TrashcanWidget.renderIcon(
        WasteIcons.resolve('chiave-che-non-esiste'),
      );
      expect(await inkedPixels(png), greaterThan(200));
    });
  });

  group('coerenza con la card della home', () {
    test('ogni preset del wizard punta a un icona che esiste nella mappa', () {
      for (final preset in kWastePresets) {
        expect(
          WasteIcons.byKey.containsKey(preset.iconKey),
          isTrue,
          reason:
              'il preset ${preset.nameKey} usa "${preset.iconKey}", che non e nella mappa: '
              'la card mostrerebbe il ripiego e il widget pure, ma nessuno se ne accorgerebbe',
        );
      }
    });
  });
}

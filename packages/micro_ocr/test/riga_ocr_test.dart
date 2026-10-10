import 'package:flutter_test/flutter_test.dart';
import 'package:micro_ocr/riga_ocr.dart';

void main() {
  group('Riquadro', () {
    test('JSON andata e ritorno', () {
      const r = Riquadro(sinistra: 0.1, alto: 0.2, larghezza: 0.3, altezza: 0.05);
      expect(r.toJson(), {'x': 0.1, 'y': 0.2, 'w': 0.3, 'h': 0.05});
      expect(Riquadro.fromJson(r.toJson()), r);
    });

    test('fromJson accetta interi', () {
      final r = Riquadro.fromJson({'x': 0, 'y': 1, 'w': 1, 'h': 0});
      expect(r, const Riquadro(sinistra: 0, alto: 1, larghezza: 1, altezza: 0));
    });

    test('derivati', () {
      const r = Riquadro(sinistra: 0.1, alto: 0.2, larghezza: 0.4, altezza: 0.2);
      expect(r.destra, closeTo(0.5, 1e-12));
      expect(r.basso, closeTo(0.4, 1e-12));
      expect(r.centroX, closeTo(0.3, 1e-12));
      expect(r.centroY, closeTo(0.3, 1e-12));
    });

    // ☠ Vision ha l'origine in BASSO a sinistra (F12.1.16 trappola 3).
    group('daVision capovolge l\'asse y', () {
      test('riquadro in basso a sinistra', () {
        final r = Riquadro.daVision(0, 0, 0.2, 0.1);
        expect(r.alto, closeTo(0.9, 1e-12));
        expect(r.basso, closeTo(1.0, 1e-12));
      });
      test('riquadro in alto a destra', () {
        final r = Riquadro.daVision(0.8, 0.9, 0.2, 0.1);
        expect(r.sinistra, 0.8);
        expect(r.alto, closeTo(0, 1e-12));
      });
      test('riquadro al centro resta al centro', () {
        final r = Riquadro.daVision(0.4, 0.45, 0.2, 0.1);
        expect(r.centroY, closeTo(0.5, 1e-12));
      });
      test('immagine intera', () {
        final r = Riquadro.daVision(0, 0, 1, 1);
        expect(r, const Riquadro(sinistra: 0, alto: 0, larghezza: 1, altezza: 1));
      });
    });

    group('sovrapposizioneVerticale', () {
      const euro = Riquadro(sinistra: 0.1, alto: 0.4, larghezza: 0.2, altezza: 0.2);
      test('apice dentro la fascia degli euro vale 1', () {
        const centesimi = Riquadro(sinistra: 0.3, alto: 0.4, larghezza: 0.1, altezza: 0.08);
        expect(euro.sovrapposizioneVerticale(centesimi), 1);
        expect(centesimi.sovrapposizioneVerticale(euro), 1);
      });
      test('meta\' sovrapposti', () {
        const altro = Riquadro(sinistra: 0, alto: 0.5, larghezza: 0.1, altezza: 0.2);
        expect(euro.sovrapposizioneVerticale(altro), closeTo(0.5, 1e-12));
      });
      test('righe distinte valgono 0', () {
        const sotto = Riquadro(sinistra: 0, alto: 0.7, larghezza: 0.1, altezza: 0.1);
        expect(euro.sovrapposizioneVerticale(sotto), 0);
      });
      test('altezza nulla vale 0', () {
        const piatto = Riquadro(sinistra: 0, alto: 0.5, larghezza: 0.1, altezza: 0);
        expect(euro.sovrapposizioneVerticale(piatto), 0);
      });
    });
  });

  group('RigaOcr', () {
    test('JSON piatto andata e ritorno', () {
      const riga = RigaOcr(
        testo: '2,49',
        riquadro: Riquadro(sinistra: 0.41, alto: 0.38, larghezza: 0.22, altezza: 0.12),
        confidenza: 0.97,
      );
      final json = riga.toJson();
      expect(json, {'t': '2,49', 'x': 0.41, 'y': 0.38, 'w': 0.22, 'h': 0.12, 'c': 0.97});
      expect(RigaOcr.fromJson(json), riga);
    });

    test('confidenza mancante vale 1, testo mancante e\' vuoto', () {
      final riga = RigaOcr.fromJson({'x': 0, 'y': 0, 'w': 1, 'h': 1});
      expect(riga.confidenza, 1);
      expect(riga.testo, '');
    });
  });

  test('OcrModo ha i nomi usati dal canale', () {
    expect(OcrModo.values.map((m) => m.name), ['cartellino', 'scontrino']);
  });
}

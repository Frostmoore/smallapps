import 'package:flutter_test/flutter_test.dart';
import 'package:micro_ocr/micro_ocr.dart';

void main() {
  const riga = RigaOcr(
    testo: '1,99',
    riquadro: Riquadro(sinistra: 0, alto: 0, larghezza: 1, altezza: 1),
    confidenza: 1,
  );

  test('restituisce le righe e registra percorsi e modi', () async {
    final f = FakeOcrEngine(righe: [riga]);
    expect(await f.nome(), 'fake');
    expect(await f.leggi('a.jpg', modo: OcrModo.cartellino), [riga]);
    expect(await f.leggi('b.jpg', modo: OcrModo.scontrino), [riga]);
    expect(f.letti, ['a.jpg', 'b.jpg']);
    expect(f.modi, [OcrModo.cartellino, OcrModo.scontrino]);
  });

  test('righe modificabili fra un leggi e l\'altro', () async {
    final f = FakeOcrEngine();
    expect(await f.leggi('a', modo: OcrModo.cartellino), isEmpty);
    f.righe = [riga];
    expect(await f.leggi('a', modo: OcrModo.cartellino), [riga]);
  });

  test('errore lanciato, anche dopo il ritardo', () async {
    final f = FakeOcrEngine(
      errore: const OcrNonDisponibile('assente'),
      ritardo: const Duration(milliseconds: 5),
    );
    await expectLater(f.leggi('a', modo: OcrModo.cartellino), throwsA(isA<OcrNonDisponibile>()));
    expect(f.letti, ['a']);
  });

  test('conta prepara e rilascia', () async {
    final f = FakeOcrEngine();
    await f.prepara();
    await f.prepara();
    await f.rilascia();
    expect(f.preparazioni, 2);
    expect(f.rilasci, 1);
  });
}

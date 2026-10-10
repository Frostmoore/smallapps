import 'package:flutter_test/flutter_test.dart';
import 'package:spending_review/domain/nomi.dart';
import 'package:spending_review/domain/quantita.dart';

/// F12.1.3: normalizzazione, formati, similarita' con le abbreviazioni dello scontrino.
void main() {
  group('normalizza', () {
    test('l\'esempio della specsheet', () {
      expect(Nomi.normalizza('Crema NUTKAO bicch.birra gr.600'), 'CREMA NUTKAO BICCH BIRRA');
    });
    test('accenti, punteggiatura, spazi', () {
      expect(Nomi.normalizza('  Caffè   «Qualità» - oro! '), 'CAFFE QUALITA ORO');
    });
    test('formati tolti: 200 G, LT 1, X2, 6x180 ml, 50 cl', () {
      expect(Nomi.normalizza('SAPONE BOROTALCO X2 200 g'), 'SAPONE BOROTALCO');
      expect(Nomi.normalizza('COCA COLA V.A.P. LT 1'), 'COCA COLA V A P');
      expect(Nomi.normalizza('TONICA 6x180 ml'), 'TONICA');
      expect(Nomi.normalizza('DISTILLATO PERE 50 cl'), 'DISTILLATO PERE');
    });
  });

  group('formato', () {
    test('200 g', () => expect(Nomi.formato('SAPONE X2 200 g'), const AMisura(200, UnitaMisura.kg)));
    test('GR.600', () => expect(Nomi.formato('CREMA BICCH.BIRRA GR.600'), const AMisura(600, UnitaMisura.kg)));
    test('LT 1', () => expect(Nomi.formato('COCA COLA LT 1'), const AMisura(1000, UnitaMisura.l)));
    test('6x180 ml', () => expect(Nomi.formato('TONICA 6x180 ml'), const AMisura(1080, UnitaMisura.l)));
    test('50 cl', () => expect(Nomi.formato('DISTILLATO 50 cl'), const AMisura(500, UnitaMisura.l)));
    test('0,5 L e 1,5 kg', () {
      expect(Nomi.formato('ACQUA 0,5 L'), const AMisura(500, UnitaMisura.l));
      expect(Nomi.formato('PATATE 1,5 KG'), const AMisura(1500, UnitaMisura.kg));
    });
    test('niente formato', () => expect(Nomi.formato('PANE INTEGRALE'), isNull));
  });

  group('similarita', () {
    test('uguali → 1; niente in comune → 0', () {
      expect(Nomi.similarita('PASTA SEMOLA', 'pasta semola'), 1);
      expect(Nomi.similarita('PASTA', 'BISCOTTI'), 0);
      expect(Nomi.similarita('', 'BISCOTTI'), 0);
    });
    test('abbreviazioni dello scontrino: «PR COTTO» ~ «PROSCIUTTO COTTO» = 0,5', () {
      expect(Nomi.similarita('PROSCIUTTO COTTO', 'PR COTTO'), closeTo(0.5, 1e-9));
    });
    test('troncature: «ACQUA MINER. NATURAL» ~ «Acqua minerale naturale» = 1', () {
      expect(Nomi.similarita('Acqua minerale naturale', 'ACQUA MINER. NATURAL'), 1);
    });
    test('«PARMIGIANO REGG» ~ «Parmigiano Reggiano» ≥ 0,6 (prezzo diverso nel confronto)', () {
      expect(Nomi.similarita('Parmigiano Reggiano', 'PARMIGIANO REGG'), greaterThanOrEqualTo(0.6));
    });
    test('una parola sola non vale quanto il nome intero', () {
      expect(Nomi.similarita('ACQUA', 'ACQUA MINERALE NATURALE'), lessThan(0.5));
    });
  });
}

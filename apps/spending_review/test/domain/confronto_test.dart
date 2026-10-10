import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/domain/confronto.dart';
import 'package:spending_review/domain/lettura/scontrino_parser.dart';
import 'package:spending_review/domain/quantita.dart';
import 'package:spending_review/domain/riga_spesa.dart';

/// F12.1.7: il confronto fra il contato e lo scontrino.
void main() {
  Money e(int c) => Money.cents(c);
  RigaSpesa contata(String nome, int cents, {int pezzi = 1}) =>
      RigaSpesa(nome: nome, quantita: Pezzi(pezzi), prezzoUnitario: e(cents), origine: OrigineRiga.tastierino);
  RigaScontrino art(String d, int cents, {bool stornata = false}) =>
      RigaScontrino(descrizione: d, importo: e(cents), tipo: TipoRigaScontrino.articolo, stornata: stornata);
  RigaScontrino sconto(int cents) => RigaScontrino(descrizione: 'SCONTO', importo: e(cents), tipo: TipoRigaScontrino.sconto);
  LetturaScontrino lettura(List<RigaScontrino> righe, {int? totale}) =>
      LetturaScontrino(righe: righe, totale: totale == null ? null : e(totale), righeIgnorate: 0);

  test('l\'esempio della tavola «C · Una mano»: +1,65, Parmigiano 7,90 vs 9,40 e il sacchetto', () {
    final contate = [
      contata('Latte intero', 159),
      contata('Parmigiano Reggiano', 790),
      contata('Pasta di semola', 89, pezzi: 3),
      contata('Biscotti', 233),
      contata('Caffe macinato', 2921),
    ];
    final s = lettura([
      art('LATTE INTERO', 159),
      art('PARMIGIANO REGG', 940),
      art('PASTA SEMOLA', 267),
      art('BISCOTTI FROLL', 233),
      art('CAFFE MACINATO', 2921),
      art('SACCHETTO', 15),
    ], totale: 4535);
    final esito = Confronto.confronta(contate, s);
    expect(esito.totaleContato, e(4370));
    expect(esito.totaleScontrino, e(4535));
    expect(esito.differenza, e(165));
    expect(esito.tuttoTorna, isFalse);
    expect(esito.sospette, hasLength(2));
    final prima = esito.sospette[0] as PrezzoDiverso;
    expect(prima.contata.nome, 'Parmigiano Reggiano');
    expect(prima.delta, e(150));
    final seconda = esito.sospette[1] as SoloSulloScontrino;
    expect(seconda.scontrino.descrizione, 'SACCHETTO');
    expect(seconda.delta, e(15));
    expect(esito.abbinate, hasLength(4));
  });

  test('quantita\' contata contro riga unica: «3 × 0,35» = «ACQUA 1,05»', () {
    final esito = Confronto.confronta([contata('', 35, pezzi: 3)], lettura([art('ACQUA MINER. NATURAL', 105)], totale: 105));
    expect(esito.tuttoTorna, isTrue);
    expect(esito.abbinate.single.scontrino.importo, e(105));
  });

  test('lo sconto dello scontrino si somma all\'articolo che lo precede (s06)', () {
    final esito = Confronto.confronta(
      [contata('Cornetti', 179), contata('Biscotti', 129)],
      lettura([art('CORNETTI GR.270', 219), sconto(-40), art('BISCOTTI', 129)], totale: 308),
    );
    expect(esito.tuttoTorna, isTrue);
  });

  test('articolo battuto due volte → ForseDoppia', () {
    final esito = Confronto.confronta(
      [contata('Yogurt limone', 89)],
      lettura([art('YOG LIMONE X2', 89), art('YOG LIMONE X2', 89)], totale: 178),
    );
    expect(esito.sospette.single, isA<ForseDoppia>());
    expect(esito.differenza, e(89));
  });

  test('contato vuoto (registrazione pura): tutte SoloSulloScontrino, differenza = totale', () {
    final esito = Confronto.confronta(const [], lettura([art('PANE', 120), art('LATTE', 150)], totale: 270));
    expect(esito.sospette, everyElement(isA<SoloSulloScontrino>()));
    expect(esito.differenza, e(270));
  });

  test('contato ma non sullo scontrino → NonSulloScontrino con delta negativo', () {
    final esito = Confronto.confronta([contata('Pane', 120), contata('Miele', 490)], lettura([art('PANE', 120)], totale: 120));
    final s = esito.sospette.single as NonSulloScontrino;
    expect(s.contata.nome, 'Miele');
    expect(s.delta, e(-490));
  });

  test('la riga stornata non conta', () {
    final esito = Confronto.confronta(
      [contata('Scatolame dolce', 239)],
      lettura([
        art('LATTE BIO', 249, stornata: true),
        const RigaScontrino(descrizione: 'STORNO', importo: Money.cents(-249), tipo: TipoRigaScontrino.storno),
        art('SCATOLAME DOLCE', 239),
      ], totale: 239),
    );
    expect(esito.tuttoTorna, isTrue);
  });

  test('senza TOTALE stampato si usa la somma delle righe', () {
    final esito = Confronto.confronta([contata('Pane', 120)], lettura([art('PANE', 120)]));
    expect(esito.totaleScontrino, e(120));
    expect(esito.tuttoTorna, isTrue);
  });
}

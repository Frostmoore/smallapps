import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/domain/offerta.dart';
import 'package:spending_review/domain/quantita.dart';
import 'package:spending_review/domain/riga_spesa.dart';

/// F12.1.3: il totale di una riga (pezzi, misura, offerta, totale stampato, sconto).
void main() {
  RigaSpesa riga(int cents, {Quantita q = const Pezzi(1), Offerta? o, int? stampato}) => RigaSpesa(
    nome: '',
    quantita: q,
    prezzoUnitario: Money.cents(cents),
    offerta: o,
    totaleStampato: stampato == null ? null : Money.cents(stampato),
    origine: OrigineRiga.tastierino,
  );

  group('RigaSpesa.totale', () {
    test('a pezzi: p × q', () => expect(riga(249, q: const Pezzi(3)).totale, Money.cents(747)));
    test('a misura: half-up sui millesimi', () {
      expect(riga(750, q: const AMisura(126, UnitaMisura.kg)).totale, Money.cents(95));
    });
    test('con offerta NxM: la regola dell\'offerta', () {
      expect(riga(189, q: const Pezzi(4), o: const OffertaNxM(prendi: 3, paghi: 2)).totale, Money.cents(567));
    });
    test('a misura le NxM si ignorano, la percentuale si applica all\'importo pesato', () {
      expect(
        riga(1000, q: const AMisura(500, UnitaMisura.kg), o: const OffertaNxM(prendi: 3, paghi: 2)).totale,
        Money.cents(500),
      );
      expect(riga(1000, q: const AMisura(500, UnitaMisura.kg), o: const OffertaPercentuale(30)).totale, Money.cents(350));
    });
    test('il totale stampato (bilancia) vince sul calcolo, anche se non torna', () {
      expect(riga(2990, q: const AMisura(258, UnitaMisura.kg), stampato: 799).totale, Money.cents(799));
    });
    test('sconto battuto con «−»: negativo, eSconto', () {
      final r = riga(-150);
      expect(r.totale, Money.cents(-150));
      expect(r.eSconto, isTrue);
      expect(riga(150).eSconto, isFalse);
    });
    test('copyWith: null lascia, togli* toglie', () {
      final r = riga(189, o: const OffertaNxM(prendi: 3, paghi: 2), stampato: 100);
      expect(r.copyWith(nome: 'X').offerta, isNotNull);
      expect(r.copyWith(togliOfferta: true).offerta, isNull);
      expect(r.copyWith(togliTotaleStampato: true).totaleStampato, isNull);
    });
  });
}

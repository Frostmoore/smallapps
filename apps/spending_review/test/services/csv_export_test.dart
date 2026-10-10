import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/domain/offerta.dart';
import 'package:spending_review/domain/quantita.dart';
import 'package:spending_review/domain/riga_spesa.dart';
import 'package:spending_review/domain/spesa.dart';
import 'package:spending_review/l10n/generated/app_localizations.dart';
import 'package:spending_review/services/csv_export.dart';

/// Il CSV (Pro, develop_microapps.md F12.1.13, F12.1.17 `csv_export_test.dart`): colonne, virgola
/// decimale, BOM, e nessun testo OCR grezzo (non esiste nel dominio: si esportano solo le righe
/// confermate).
void main() {
  final l = lookupL(const Locale('it'));

  Spesa chiusa(int id, CivilDate data, {int? negozio, FonteRighe fonte = FonteRighe.contate, List<RigaSpesa> righe = const [], List<RigaSpesa> scontrino = const [], Money? budget}) =>
      Spesa(
        id: id,
        stato: StatoSpesa.chiusa,
        negozioId: negozio,
        iniziataIl: DateTime.utc(2026, 10, 1),
        dataSpesa: data,
        budget: budget,
        righe: righe,
        righeScontrino: scontrino,
        fonte: fonte,
        totaleSalvato: Money.sum([for (final r in fonte == FonteRighe.contate ? righe : scontrino) r.totale]),
      );

  final pasta = RigaSpesa(
    nome: 'Pasta',
    quantita: const Pezzi(3),
    prezzoUnitario: const Money.cents(189),
    offerta: const OffertaNxM(prendi: 3, paghi: 2),
    origine: OrigineRiga.cartellino,
  );
  const mele = RigaSpesa(
    nome: 'Mele',
    quantita: AMisura(1258, UnitaMisura.kg),
    prezzoUnitario: Money.cents(199),
    origine: OrigineRiga.tastierino,
  );

  test('BOM, intestazione con le 12 colonne nell\'ordine della specsheet, punto e virgola', () {
    final csv = const CsvExport().costruisci([], {}, l: l);
    expect(csv.startsWith('﻿'), isTrue);
    expect(csv.substring(1).split('\r\n').first.split(';'), [
      'Data', 'Negozio', 'Spesa n.', 'Articolo', 'Quantità', 'Unità', 'Prezzo unitario', 'Offerta',
      'Totale riga', 'Totale spesa', 'Budget', 'Origine',
    ]);
  });

  test('una riga per riga di spesa, virgola decimale, peso in kg con tre decimali, offerta breve', () {
    final s = chiusa(7, CivilDate(2026, 10, 3), negozio: 1, righe: [pasta, mele], budget: const Money.cents(5000));
    final righe = const CsvExport().costruisci([s], {1: 'Esselunga'}, l: l).substring(1).split('\r\n');
    expect(righe[1], '2026-10-03;Esselunga;7;Pasta;3;pz;1,89;3x2;3,78;6,28;50,00;cartellino');
    expect(righe[2], '2026-10-03;Esselunga;7;Mele;1,258;kg;1,99;;2,50;6,28;50,00;tastierino');
  });

  test('con fonte scontrino escono le righe dello scontrino, non le contate', () {
    final dalloScontrino = RigaSpesa(
      nome: 'PASTA DIVELLA',
      quantita: const Pezzi(1),
      prezzoUnitario: const Money.cents(99),
      totaleStampato: const Money.cents(99),
      origine: OrigineRiga.scontrino,
    );
    final s = chiusa(8, CivilDate(2026, 10, 4), fonte: FonteRighe.scontrino, righe: [pasta], scontrino: [dalloScontrino]);
    final csv = const CsvExport().costruisci([s], {}, l: l);
    expect(csv, contains('PASTA DIVELLA'));
    expect(csv, isNot(contains(';Pasta;')));
  });

  test('una spesa senza righe esce lo stesso, col suo totale', () {
    final s = Spesa(
      id: 9,
      stato: StatoSpesa.chiusa,
      iniziataIl: DateTime.utc(2026),
      dataSpesa: CivilDate(2026, 10, 5),
      righe: const [],
      totaleSalvato: const Money.cents(1234),
    );
    final righe = const CsvExport().costruisci([s], {}, l: l).substring(1).split('\r\n');
    expect(righe[1], contains(';12,34;'));
  });

  test('il nome del file porta la data', () {
    expect(CsvExport.nomeFile(CivilDate(2026, 10, 11)), 'spending-review-2026-10-11.csv');
  });
}

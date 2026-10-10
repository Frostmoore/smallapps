import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/data/database.dart';
import 'package:spending_review/data/spesa_repository.dart';
import 'package:spending_review/domain/lettura/scontrino_parser.dart';
import 'package:spending_review/domain/offerta.dart';
import 'package:spending_review/domain/quantita.dart';
import 'package:spending_review/domain/riga_spesa.dart';
import 'package:spending_review/domain/spesa.dart';

/// F12.1.10: le regole dei dati che SQL non sa esprimere, e i vincoli che invece esprime.
void main() {
  late SpendingDatabase db;
  late SpesaRepository repo;
  var adesso = DateTime.utc(2026, 10, 10, 17, 30);

  setUp(() {
    db = SpendingDatabase.memory();
    adesso = DateTime.utc(2026, 10, 10, 17, 30);
    repo = SpesaRepository(db, ora: () => adesso);
  });
  tearDown(() => db.close());

  Money e(int c) => Money.cents(c);
  RigaSpesa riga(String nome, int cents, {Quantita q = const Pezzi(1), Offerta? o}) =>
      RigaSpesa(nome: nome, quantita: q, prezzoUnitario: e(cents), offerta: o, origine: OrigineRiga.tastierino);
  Future<Spesa> inCorso() async => (await repo.osservaInCorso().first)!;

  group('una sola spesa in corso', () {
    test('assicuraInCorso crea una volta, poi restituisce la stessa', () async {
      final a = await repo.assicuraInCorso(budgetPredefinito: e(6000));
      final b = await repo.assicuraInCorso();
      expect(a, b);
      expect((await inCorso()).budget, e(6000));
    });

    test('anche con due chiamate concorrenti (due tocchi veloci su «+»)', () async {
      final ids = await Future.wait([repo.assicuraInCorso(), repo.assicuraInCorso(), repo.aggiungiRiga(riga('A', 100))]);
      expect(ids[0], ids[1]);
      final n = await db.customSelect("SELECT COUNT(*) AS n FROM spese WHERE stato = 'in_corso'").getSingle();
      expect(n.read<int>('n'), 1);
    });

    test('l\'indice unico lo garantisce anche senza il repository', () async {
      await repo.assicuraInCorso();
      expect(
        () => db.into(db.spese).insert(SpeseCompanion.insert(stato: 'in_corso', iniziataIl: 0)),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('righe', () {
    test('aggiungiRiga crea la spesa pigramente, scrive il totale e l\'ordine', () async {
      expect(await repo.osservaInCorso().first, isNull);
      await repo.aggiungiRiga(riga('Pane', 120));
      await repo.aggiungiRiga(riga('Pasta', 189, q: const Pezzi(4), o: const OffertaNxM(prendi: 3, paghi: 2)));
      final s = await inCorso();
      expect([for (final r in s.righe) r.nome], ['Pane', 'Pasta']);
      expect(s.totaleContato, e(120 + 567));
      expect(s.righe[1].offerta, const OffertaNxM(prendi: 3, paghi: 2));
      final salvati = await db.select(db.righe).get();
      expect([for (final r in salvati) r.totaleCents], [120, 567]);
    });

    test('aggiornaRiga ricalcola totale_cents', () async {
      final id = await repo.aggiungiRiga(riga('Pane', 120));
      await repo.aggiornaRiga(riga('Pane nero', 150, q: const Pezzi(2)).copyWith(id: id));
      final r = await (db.select(db.righe)..where((x) => x.id.equals(id))).getSingle();
      expect(r.nome, 'Pane nero');
      expect(r.totaleCents, 300);
    });

    test('eliminaRiga e ripristinaRiga («Annulla»): torna con id e posizione', () async {
      await repo.aggiungiRiga(riga('A', 100));
      final id = await repo.aggiungiRiga(riga('B', 200));
      await repo.aggiungiRiga(riga('C', 300));
      final eliminata = (await inCorso()).righe[1];
      await repo.eliminaRiga(id);
      expect([for (final r in (await inCorso()).righe) r.nome], ['A', 'C']);
      await repo.ripristinaRiga(eliminata, posizione: 1);
      final s = await inCorso();
      expect([for (final r in s.righe) r.nome], ['A', 'B', 'C']);
      expect(s.righe[1].id, id);
    });

    test('incrementaUltima: +1 pezzo all\'ultima a pezzi; no su misura, sconto, niente spesa', () async {
      expect(await repo.incrementaUltima(), isFalse);
      await repo.aggiungiRiga(riga('Acqua', 35, q: const Pezzi(2)));
      expect(await repo.incrementaUltima(), isTrue);
      expect((await inCorso()).righe.last.quantita, const Pezzi(3));
      expect((await inCorso()).totaleContato, e(105));
      await repo.aggiungiRiga(riga('Mele', 250, q: const AMisura(612, UnitaMisura.kg)));
      expect(await repo.incrementaUltima(), isFalse);
      await repo.aggiungiRiga(riga('', -150));
      expect(await repo.incrementaUltima(), isFalse);
    });

    test('i vincoli: prezzo zero, pezzi fuori limite, nome troppo lungo → eccezione', () async {
      final spesa = await repo.assicuraInCorso();
      RigheCompanion base({int prezzo = 100, int? pezzi = 1, String nome = ''}) => RigheCompanion.insert(
        spesaId: spesa,
        insieme: 'contate',
        posizione: 0,
        nome: Value(nome),
        pezzi: Value(pezzi),
        prezzoUnitarioCents: prezzo,
        totaleCents: prezzo,
        origine: 'tastierino',
        creataIl: 0,
      );
      expect(() => db.into(db.righe).insert(base(prezzo: 0)), throwsA(isA<Exception>()));
      expect(() => db.into(db.righe).insert(base(pezzi: 1000)), throwsA(isA<Exception>()));
      expect(() => db.into(db.righe).insert(base(pezzi: null)), throwsA(isA<Exception>())); // ne' pezzi ne' peso
      expect(() => db.into(db.righe).insert(base(nome: 'x' * 81)), throwsA(isA<Exception>()));
    });
  });

  group('budget', () {
    test('impostaBudget crea la spesa se serve, null lo toglie', () async {
      await repo.impostaBudget(e(6000));
      expect((await inCorso()).budget, e(6000));
      await repo.impostaBudget(null);
      expect((await inCorso()).budget, isNull);
    });
  });

  group('chiusura e storico', () {
    test('chiudi scrive totale, data, negozio e fonte; il totale non si ricalcola piu\'', () async {
      await repo.aggiungiRiga(riga('Pane', 120));
      await repo.aggiungiRiga(riga('Latte', 150));
      final negozio = await repo.negozioPerNome('Bottega');
      final id = await repo.chiudi(data: CivilDate(2026, 10, 10), negozioId: negozio, fonte: FonteRighe.contate);
      expect(await repo.osservaInCorso().first, isNull);
      final s = (await repo.perId(id))!;
      expect(s.stato, StatoSpesa.chiusa);
      expect(s.totale, e(270));
      expect(s.dataSpesa, CivilDate(2026, 10, 10));
      expect(s.negozioId, negozio);
      // Una riga cambiata dopo (a mano nel database) non cambia il totale scritto.
      await db.customStatement('UPDATE righe SET totale_cents = 999');
      expect((await repo.perId(id))!.totale, e(270));
    });

    test('senza spesa in corso chiudi e\' un errore', () async {
      expect(() => repo.chiudi(data: CivilDate(2026, 10, 10), fonte: FonteRighe.contate), throwsStateError);
    });

    test('righe dello scontrino affiancate alle contate; chiusura con fonte scontrino', () async {
      await repo.aggiungiRiga(riga('Parmigiano', 790));
      final spesaId = await repo.assicuraInCorso();
      const lettura = LetturaScontrino(
        righe: [
          RigaScontrino(descrizione: 'PARMIGIANO REGG', importo: Money.cents(940), tipo: TipoRigaScontrino.articolo),
          RigaScontrino(descrizione: 'SACCHETTO', importo: Money.cents(15), tipo: TipoRigaScontrino.articolo),
        ],
        totale: Money.cents(955),
        righeIgnorate: 0,
      );
      await repo.salvaScontrino(spesaId, lettura);
      await repo.salvaScontrino(spesaId, lettura); // la seconda lettura sostituisce la prima
      var s = await inCorso();
      expect(s.righe, hasLength(1));
      expect(s.righeScontrino, hasLength(2));
      expect(s.totaleScontrino, e(955));
      final id = await repo.chiudi(data: CivilDate(2026, 10, 10), fonte: FonteRighe.scontrino);
      s = (await repo.perId(id))!;
      expect(s.totale, e(955));
      expect(s.fonte, FonteRighe.scontrino);
    });

    test('registraDaScontrino: una spesa gia\' chiusa, fonte scontrino, nessuna spesa in corso', () async {
      const lettura = LetturaScontrino(
        righe: [
          RigaScontrino(descrizione: 'PANE', importo: Money.cents(120), tipo: TipoRigaScontrino.articolo),
          RigaScontrino(
            descrizione: 'MELE',
            importo: Money.cents(153),
            tipo: TipoRigaScontrino.articolo,
            quantita: AMisura(612, UnitaMisura.kg),
            prezzoUnitario: Money.cents(250),
          ),
        ],
        totale: Money.cents(273),
        righeIgnorate: 0,
      );
      final id = await repo.registraDaScontrino(lettura, data: CivilDate(2026, 10, 9));
      final s = (await repo.perId(id))!;
      expect(s.stato, StatoSpesa.chiusa);
      expect(s.totale, e(273));
      expect(s.righeScontrino[1].quantita, const AMisura(612, UnitaMisura.kg));
      expect(s.righeScontrino[1].totale, e(153));
      expect(await repo.osservaInCorso().first, isNull);
    });

    test('scartaInCorso butta la spesa e le sue righe', () async {
      await repo.aggiungiRiga(riga('Pane', 120));
      await repo.scartaInCorso();
      expect(await repo.osservaInCorso().first, isNull);
      expect(await db.select(db.righe).get(), isEmpty);
    });

    test('spese oltre le 5 CONSERVATE: il gratis ne vede 5, il Pro tutte (risposta D1)', () async {
      for (var g = 1; g <= 7; g++) {
        await repo.aggiungiRiga(riga('Spesa $g', 100 * g));
        await repo.chiudi(data: CivilDate(2026, 10, g), fonte: FonteRighe.contate);
      }
      expect(await repo.contaChiuse(), 7);
      final gratis = await repo.osservaChiuse(limite: 5).first;
      expect(gratis, hasLength(5));
      expect(gratis.first.dataSpesa, CivilDate(2026, 10, 7)); // la piu' recente prima
      expect(await repo.osservaChiuse().first, hasLength(7));
      expect(await db.select(db.spese).get(), hasLength(7)); // nessuna cancellata
    });

    test('eliminaSpesa: cascata sulle righe', () async {
      await repo.aggiungiRiga(riga('Pane', 120));
      final id = await repo.chiudi(data: CivilDate(2026, 10, 10), fonte: FonteRighe.contate);
      await repo.eliminaSpesa(id);
      expect(await repo.perId(id), isNull);
      expect(await db.select(db.righe).get(), isEmpty);
    });
  });

  group('negozi', () {
    test('negozioPerNome: trova senza distinguere le maiuscole, o crea', () async {
      final a = await repo.negozioPerNome('Esselunga');
      final b = await repo.negozioPerNome('  ESSELUNGA ');
      expect(a, b);
      expect(await repo.osservaNegozi().first, hasLength(1));
      expect(() => repo.negozioPerNome('   '), throwsArgumentError);
    });

    test('negozio eliminato → le sue spese restano «senza negozio»', () async {
      final n = await repo.negozioPerNome('Bottega');
      await repo.aggiungiRiga(riga('Pane', 120));
      final id = await repo.chiudi(data: CivilDate(2026, 10, 10), negozioId: n, fonte: FonteRighe.contate);
      await repo.eliminaNegozio(n);
      final s = (await repo.perId(id))!;
      expect(s.negozioId, isNull);
      expect(s.totale, e(120));
    });

    test('rinomina e ordine per nome', () async {
      final b = await repo.negozioPerNome('bottega');
      await repo.negozioPerNome('Alimentari');
      await repo.rinominaNegozio(b, 'Zanzibar');
      expect([for (final n in await repo.osservaNegozi().first) n.nome], ['Alimentari', 'Zanzibar']);
    });
  });
}

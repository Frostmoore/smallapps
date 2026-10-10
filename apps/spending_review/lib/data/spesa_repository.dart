import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:micro_core/micro_core.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../domain/lettura/scontrino_parser.dart';
import '../domain/offerta.dart';
import '../domain/quantita.dart';
import '../domain/riga_spesa.dart';
import '../domain/spesa.dart';
import 'database.dart';

/// Le regole dei dati di Spending Review che SQL non sa esprimere (develop_microapps.md F12.1.10).
///
/// ⚑ **Le spese chiuse oltre le 5 nel gratis restano nel database** (risposta D1 del
/// proprietario): il limite lo applica la LETTURA (`osservaChiuse(limite: 5)` se non Pro), mai una
/// cancellazione. Qui non c'e' nessuna «potatura», e non deve esserci.
/// ⚑ **Una sola spesa in corso** la garantisce l'indice unico parziale `spese_una_in_corso`, non
/// questo codice: due tocchi veloci su «+» all'avvio non possono creare due spese.
/// ⚑ I totali (`righe.totale_cents`, `spese.totale_cents`) si scrivono quando la riga si scrive o la
/// spesa si chiude, e non si ricalcolano: un cambiamento delle regole non cambia lo storico.
class SpesaRepository {
  // ignore: prefer_initializing_formals
  SpesaRepository(this._db, {DateTime Function() ora = DateTime.now}) : _ora = ora;

  final SpendingDatabase _db;
  final DateTime Function() _ora;

  static const String _inCorso = 'in_corso';
  static const String _chiusa = 'chiusa';
  static const String _contate = 'contate';
  static const String _scontrino = 'scontrino';

  int get _adesso => _ora().toUtc().millisecondsSinceEpoch;

  // ── La spesa in corso ─────────────────────────────────────────────────────────────────────

  /// La spesa in corso con le righe; null se non c'e'. Riemette a ogni scrittura su spese o righe.
  Stream<Spesa?> osservaInCorso() => _db
      .customSelect('SELECT 1', readsFrom: {_db.spese, _db.righe})
      .watch()
      .asyncMap((_) => _caricaInCorso());

  Future<Spesa?> _caricaInCorso() async {
    final row = await (_db.select(_db.spese)..where((s) => s.stato.equals(_inCorso))).getSingleOrNull();
    return row == null ? null : _spesa(row);
  }

  /// La spesa in corso, creata se non c'e' (budget = [budgetPredefinito]). Ritorna l'id.
  ///
  /// ☠ Due chiamate ravvicinate (due tocchi su «+») sono serializzate da drift, ma su un database
  /// condiviso da piu' connessioni non basterebbe: per questo l'inserimento che viola l'indice
  /// unico si recupera rileggendo la spesa che l'altra chiamata ha appena creato.
  Future<int> assicuraInCorso({Money? budgetPredefinito}) => _db.transaction(() async {
    final esistente = await (_db.select(_db.spese)..where((s) => s.stato.equals(_inCorso))).getSingleOrNull();
    if (esistente != null) return esistente.id;
    try {
      return await _db
          .into(_db.spese)
          .insert(SpeseCompanion.insert(
            stato: _inCorso,
            iniziataIl: _adesso,
            budgetCents: Value(budgetPredefinito == null || budgetPredefinito.cents <= 0 ? null : budgetPredefinito.cents),
          ));
    } on SqliteException {
      final altra = await (_db.select(_db.spese)..where((s) => s.stato.equals(_inCorso))).getSingle();
      return altra.id;
    }
  });

  /// Aggiunge una riga contata alla spesa in corso (creandola se serve). Ritorna l'id della riga.
  Future<int> aggiungiRiga(RigaSpesa riga) => _db.transaction(() async {
    final spesaId = await assicuraInCorso();
    final posizione = await _prossimaPosizione(spesaId, _contate);
    return _db.into(_db.righe).insert(_companion(riga, spesaId: spesaId, insieme: _contate, posizione: posizione));
  });

  /// Modifica una riga (nome, quantita', prezzo, offerta) e ne ricalcola `totale_cents`.
  Future<void> aggiornaRiga(RigaSpesa riga) async {
    final id = riga.id;
    if (id == null) throw ArgumentError('aggiornaRiga: riga senza id');
    final esistente = await (_db.select(_db.righe)..where((r) => r.id.equals(id))).getSingle();
    await (_db.update(_db.righe)..where((r) => r.id.equals(id))).write(
      _companion(riga, spesaId: esistente.spesaId, insieme: esistente.insieme, posizione: esistente.posizione)
          .copyWith(creataIl: Value(esistente.creataIl), id: const Value.absent()),
    );
  }

  Future<void> eliminaRiga(int rigaId) => (_db.delete(_db.righe)..where((r) => r.id.equals(rigaId))).go();

  /// La posizione di una riga, da leggere PRIMA di [eliminaRiga] per poterla rimettere al suo
  /// posto con [ripristinaRiga] («Annulla»). null se la riga non c'e'.
  /// ⚑ Metodo in piu' rispetto alla specsheet (F12.4): `RigaSpesa` non porta la posizione, e
  /// l'indice nella lista non basta (le posizioni possono avere buchi dopo un'eliminazione).
  Future<int?> posizioneDi(int rigaId) async =>
      (await (_db.select(_db.righe)..where((r) => r.id.equals(rigaId))).getSingleOrNull())?.posizione;

  /// «Annulla» dopo l'eliminazione: la riga torna con il suo id e la sua posizione (le altre non si
  /// spostano: la posizione e' solo un ordine, i buchi non contano).
  Future<void> ripristinaRiga(RigaSpesa riga, {required int posizione}) => _db.transaction(() async {
    final spesaId = await assicuraInCorso();
    await _db.into(_db.righe).insert(
      _companion(riga, spesaId: spesaId, insieme: _contate, posizione: posizione)
          .copyWith(id: riga.id == null ? const Value.absent() : Value(riga.id!)),
    );
  });

  /// +1 pezzo all'ultima riga contata a pezzi (il «+» a display vuoto del tastierino).
  /// ⚑ Ritorna `false` (e non tocca niente) se non c'e' una spesa in corso, se l'ultima riga e' a
  /// misura o uno sconto, o se e' gia' a 999 pezzi: il tasto va rifiutato con la vibrazione
  /// d'errore. Firma con `bool` e non `void` (specsheet): senza, l'interfaccia non saprebbe
  /// quando vibrare.
  Future<bool> incrementaUltima() => _db.transaction(() async {
    final spesa = await (_db.select(_db.spese)..where((s) => s.stato.equals(_inCorso))).getSingleOrNull();
    if (spesa == null) return false;
    final ultima = await (_db.select(_db.righe)
          ..where((r) => r.spesaId.equals(spesa.id) & r.insieme.equals(_contate))
          ..orderBy([(r) => OrderingTerm.desc(r.posizione), (r) => OrderingTerm.desc(r.id)])
          ..limit(1))
        .getSingleOrNull();
    if (ultima == null) return false;
    final riga = _riga(ultima);
    final pezzi = riga.pezzi;
    if (pezzi == null || riga.eSconto || pezzi >= Pezzi.massimo || riga.totaleStampato != null) return false;
    final nuova = riga.copyWith(quantita: Pezzi(pezzi + 1));
    await (_db.update(_db.righe)..where((r) => r.id.equals(ultima.id))).write(
      RigheCompanion(pezzi: Value(pezzi + 1), totaleCents: Value(nuova.totale.cents)),
    );
    return true;
  });

  /// Il budget della spesa in corso (creata se serve: il foglio del budget si apre anche prima del
  /// primo articolo). null = nessun budget.
  Future<void> impostaBudget(Money? budget) => _db.transaction(() async {
    final id = await assicuraInCorso();
    await (_db.update(_db.spese)..where((s) => s.id.equals(id))).write(
      SpeseCompanion(budgetCents: Value(budget == null || budget.cents <= 0 ? null : budget.cents)),
    );
  });

  /// Le righe dello scontrino della spesa [spesaId] (insieme 'scontrino'), al posto di quelle di
  /// una lettura precedente, e il TOTALE stampato.
  Future<void> salvaScontrino(int spesaId, LetturaScontrino lettura) => _db.transaction(() async {
    await (_db.delete(_db.righe)..where((r) => r.spesaId.equals(spesaId) & r.insieme.equals(_scontrino))).go();
    await _inserisciScontrino(spesaId, lettura);
    await (_db.update(_db.spese)..where((s) => s.id.equals(spesaId))).write(
      SpeseCompanion(totaleScontrinoCents: Value(lettura.totale?.cents)),
    );
  });

  /// Chiude la spesa in corso: scrive `totale_cents` (che non cambiera' piu'), data, negozio,
  /// fonte. Ritorna l'id. ☠ StateError se non c'e' una spesa in corso.
  Future<int> chiudi({required CivilDate data, int? negozioId, required FonteRighe fonte}) => _db.transaction(() async {
    final row = await (_db.select(_db.spese)..where((s) => s.stato.equals(_inCorso))).getSingleOrNull();
    if (row == null) throw StateError('Nessuna spesa in corso da chiudere');
    final spesa = await _spesa(row);
    final totale = Spesa(
      stato: StatoSpesa.inCorso,
      iniziataIl: spesa.iniziataIl,
      righe: spesa.righe,
      righeScontrino: spesa.righeScontrino,
      totaleScontrino: spesa.totaleScontrino,
      fonte: fonte,
    ).totale;
    await (_db.update(_db.spese)..where((s) => s.id.equals(row.id))).write(
      SpeseCompanion(
        stato: const Value(_chiusa),
        chiusaIl: Value(_adesso),
        dataSpesa: Value(data.toIso()),
        negozioId: Value(negozioId),
        fonte: Value(fonte.name),
        totaleCents: Value(totale.cents),
      ),
    );
    return row.id;
  });

  /// Registrazione pura dallo scontrino (nessuna spesa contata): crea una spesa gia' CHIUSA, con
  /// fonte scontrino e totale = TOTALE stampato (o la somma delle righe se manca).
  Future<int> registraDaScontrino(LetturaScontrino lettura, {required CivilDate data, int? negozioId}) =>
      _db.transaction(() async {
        final adesso = _adesso;
        final id = await _db
            .into(_db.spese)
            .insert(SpeseCompanion.insert(
              stato: _chiusa,
              iniziataIl: adesso,
              chiusaIl: Value(adesso),
              dataSpesa: Value(data.toIso()),
              negozioId: Value(negozioId),
              fonte: const Value(_scontrino),
              totaleScontrinoCents: Value(lettura.totale?.cents),
              totaleCents: Value((lettura.totale ?? lettura.sommaRighe).cents),
            ));
        await _inserisciScontrino(id, lettura);
        return id;
      });

  /// Butta la spesa in corso (vuota alla chiusura, o «Butta via»), righe comprese (CASCADE).
  Future<void> scartaInCorso() => (_db.delete(_db.spese)..where((s) => s.stato.equals(_inCorso))).go();

  // ── Lo storico ────────────────────────────────────────────────────────────────────────────

  /// Le spese chiuse, `data_spesa DESC, id DESC`. [limite] null = tutte (Pro); 5 nel gratis.
  Stream<List<Spesa>> osservaChiuse({int? limite}) {
    final q = _db.select(_db.spese)
      ..where((s) => s.stato.equals(_chiusa))
      ..orderBy([(s) => OrderingTerm.desc(s.dataSpesa), (s) => OrderingTerm.desc(s.id)]);
    if (limite != null) q.limit(limite);
    return _db
        .customSelect('SELECT 1', readsFrom: {_db.spese, _db.righe})
        .watch()
        .asyncMap((_) async => [for (final row in await q.get()) await _spesa(row)]);
  }

  /// Quante spese chiuse ci sono (anche quelle nascoste nel gratis), aggiornato a ogni scrittura.
  /// ⚑ In piu' rispetto alla specsheet (F12.4): la card «Le altre N spese sono sul telefono»
  /// dello storico gratis la legge senza caricare le righe di tutte le spese.
  Stream<int> osservaNumeroChiuse() => _db
      .customSelect("SELECT COUNT(*) AS n FROM spese WHERE stato = 'chiusa'", readsFrom: {_db.spese})
      .watch()
      .map((righe) => righe.isEmpty ? 0 : righe.first.read<int>('n'));

  /// Cambia negozio e data di una spesa CHIUSA (dettaglio dello storico). ⚑ Il totale scritto
  /// alla chiusura non si tocca: negozio e data non cambiano cosa si e' pagato.
  Future<void> modificaChiusa(int id, {required CivilDate data, int? negozioId}) =>
      (_db.update(_db.spese)..where((s) => s.id.equals(id) & s.stato.equals(_chiusa))).write(
        SpeseCompanion(dataSpesa: Value(data.toIso()), negozioId: Value(negozioId)),
      );

  Future<int> contaChiuse() async {
    final n = _db.spese.id.count();
    final q = _db.selectOnly(_db.spese)
      ..addColumns([n])
      ..where(_db.spese.stato.equals(_chiusa));
    return (await q.getSingle()).read(n) ?? 0;
  }

  Future<Spesa?> perId(int id) async {
    final row = await (_db.select(_db.spese)..where((s) => s.id.equals(id))).getSingleOrNull();
    return row == null ? null : _spesa(row);
  }

  Future<void> eliminaSpesa(int id) => (_db.delete(_db.spese)..where((s) => s.id.equals(id))).go();

  // ── I negozi ──────────────────────────────────────────────────────────────────────────────

  /// Per nome, senza distinguere le maiuscole.
  Stream<List<Negozio>> osservaNegozi() =>
      (_db.select(_db.negozi)..orderBy([(n) => OrderingTerm(expression: n.nome.collate(Collate.noCase))])).watch();

  /// Trova il negozio per nome (senza distinguere le maiuscole) o lo crea. Il nome si ripulisce
  /// (spazi) e si tronca a 60 caratteri. ☠ ArgumentError se vuoto.
  Future<int> negozioPerNome(String nome) => _db.transaction(() async {
    final pulito = _nomeNegozio(nome);
    final esistente = await (_db.select(_db.negozi)..where((n) => n.nome.collate(Collate.noCase).equals(pulito))).getSingleOrNull();
    if (esistente != null) return esistente.id;
    return _db.into(_db.negozi).insert(NegoziCompanion.insert(nome: pulito, creatoIl: _adesso));
  });

  Future<void> rinominaNegozio(int id, String nome) =>
      (_db.update(_db.negozi)..where((n) => n.id.equals(id))).write(NegoziCompanion(nome: Value(_nomeNegozio(nome))));

  /// Le spese del negozio restano, «senza negozio» (ON DELETE SET NULL).
  Future<void> eliminaNegozio(int id) => (_db.delete(_db.negozi)..where((n) => n.id.equals(id))).go();

  static String _nomeNegozio(String nome) {
    final s = nome.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.isEmpty) throw ArgumentError('Nome del negozio vuoto');
    return s.length > 60 ? s.substring(0, 60).trimRight() : s;
  }

  // ── Dalle righe al dominio e ritorno ──────────────────────────────────────────────────────

  Future<int> _prossimaPosizione(int spesaId, String insieme) async {
    final massimo = _db.righe.posizione.max();
    final q = _db.selectOnly(_db.righe)
      ..addColumns([massimo])
      ..where(_db.righe.spesaId.equals(spesaId) & _db.righe.insieme.equals(insieme));
    return ((await q.getSingle()).read(massimo) ?? -1) + 1;
  }

  Future<void> _inserisciScontrino(int spesaId, LetturaScontrino lettura) async {
    var posizione = 0;
    for (final r in lettura.righe) {
      final riga = rigaDaScontrino(r);
      if (riga == null) continue;
      await _db.into(_db.righe).insert(
        _companion(riga, spesaId: spesaId, insieme: _scontrino, posizione: posizione++)
            .copyWith(stornata: Value(r.stornata)),
      );
    }
  }

  /// Una riga dello scontrino come `RigaSpesa` (origine scontrino): l'importo stampato e' il
  /// totale della riga (`totaleStampato`), la quantita' quella letta (o 1 pezzo). null per un
  /// importo zero (il CHECK `prezzo_unitario_cents <> 0` non lo ammetterebbe, e non conta).
  /// ⚑ La descrizione si tronca a 80 caratteri (limite della colonna).
  static RigaSpesa? rigaDaScontrino(RigaScontrino r) {
    if (r.importo.isZero) return null;
    final q = r.quantita;
    final unitario = r.prezzoUnitario;
    final usaUnitario = unitario != null && !unitario.isZero && !r.importo.isNegative;
    return RigaSpesa(
      nome: r.descrizione.length > RigaSpesa.nomeMassimo ? r.descrizione.substring(0, RigaSpesa.nomeMassimo) : r.descrizione,
      quantita: usaUnitario && q != null ? q : const Pezzi(1),
      prezzoUnitario: usaUnitario && q != null ? unitario : r.importo,
      totaleStampato: r.importo,
      origine: OrigineRiga.scontrino,
    );
  }

  RigheCompanion _companion(RigaSpesa r, {required int spesaId, required String insieme, required int posizione}) {
    final (pezzi, millesimi, unita) = switch (r.quantita) {
      Pezzi(:final n) => (n, null, null),
      AMisura(:final millesimi, :final unita) => (null, millesimi, unita.name),
    };
    return RigheCompanion.insert(
      spesaId: spesaId,
      insieme: insieme,
      posizione: posizione,
      nome: Value(r.nome.length > RigaSpesa.nomeMassimo ? r.nome.substring(0, RigaSpesa.nomeMassimo) : r.nome),
      pezzi: Value(pezzi),
      millesimi: Value(millesimi),
      unita: Value(unita),
      prezzoUnitarioCents: r.prezzoUnitario.cents,
      totaleCents: r.totale.cents,
      offertaJson: Value(r.offerta == null ? null : jsonEncode(r.offerta!.toJson())),
      prezzoRifCents: Value(r.prezzoRiferimento?.cents),
      unitaRif: Value(r.unitaRiferimento?.name),
      totaleStampatoCents: Value(r.totaleStampato?.cents),
      origine: r.origine.name,
      creataIl: _adesso,
    );
  }

  Future<Spesa> _spesa(SpesaRow row) async {
    final righe = await (_db.select(_db.righe)
          ..where((r) => r.spesaId.equals(row.id))
          ..orderBy([(r) => OrderingTerm(expression: r.posizione), (r) => OrderingTerm(expression: r.id)]))
        .get();
    return spesaDaRiga(row, righe);
  }

  /// La spesa di dominio dalle righe del database (usata anche dal backup e dai test).
  static Spesa spesaDaRiga(SpesaRow row, List<RigaRow> righe) {
    final chiusa = row.stato == _chiusa;
    return Spesa(
      id: row.id,
      stato: chiusa ? StatoSpesa.chiusa : StatoSpesa.inCorso,
      negozioId: row.negozioId,
      iniziataIl: DateTime.fromMillisecondsSinceEpoch(row.iniziataIl, isUtc: true),
      chiusaIl: row.chiusaIl == null ? null : DateTime.fromMillisecondsSinceEpoch(row.chiusaIl!, isUtc: true),
      dataSpesa: CivilDate.tryParse(row.dataSpesa),
      budget: row.budgetCents == null ? null : Money.cents(row.budgetCents!),
      righe: [for (final r in righe) if (r.insieme == _contate) _riga(r)],
      // ⚑ Anche le stornate: lo storno (negativo) le compensa, e la somma torna quella stampata.
      righeScontrino: [for (final r in righe) if (r.insieme == _scontrino) _riga(r)],
      totaleScontrino: row.totaleScontrinoCents == null ? null : Money.cents(row.totaleScontrinoCents!),
      fonte: row.fonte == _scontrino ? FonteRighe.scontrino : FonteRighe.contate,
      totaleSalvato: chiusa ? Money.cents(row.totaleCents) : null,
    );
  }

  static RigaSpesa _riga(RigaRow r) {
    Offerta? offerta;
    final json = r.offertaJson;
    if (json != null) {
      try {
        final m = jsonDecode(json);
        if (m is Map<String, Object?>) offerta = Offerta.fromJson(m);
      } on FormatException {
        offerta = null; // illeggibile: la riga resta, senza offerta (il totale salvato non cambia)
      }
    }
    UnitaMisura? unita(String? u) => switch (u) {
      'kg' => UnitaMisura.kg,
      'l' => UnitaMisura.l,
      _ => null,
    };
    final pezzi = r.pezzi;
    return RigaSpesa(
      id: r.id,
      nome: r.nome,
      quantita: pezzi != null ? Pezzi(pezzi) : AMisura(r.millesimi!, unita(r.unita)!),
      prezzoUnitario: Money.cents(r.prezzoUnitarioCents),
      offerta: offerta,
      prezzoRiferimento: r.prezzoRifCents == null ? null : Money.cents(r.prezzoRifCents!),
      unitaRiferimento: unita(r.unitaRif),
      totaleStampato: r.totaleStampatoCents == null ? null : Money.cents(r.totaleStampatoCents!),
      origine: OrigineRiga.values.asNameMap()[r.origine] ?? OrigineRiga.tastierino,
    );
  }
}

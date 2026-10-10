// I vincoli `check(...)` di Drift citano la colonna dentro il suo stesso getter: e' la forma
// documentata da Drift (il getter non viene mai eseguito a runtime, lo legge il generatore), e il
// lint `recursive_getters` lo scambia per una ricorsione. Stessa riga di Film Tracker.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

/// Le tabelle di Spending Review (develop_microapps.md F12.1.10).
///
/// ⚑ **Nessuna tabella per le foto e nessuna colonna per il testo OCR grezzo**: la foto si
/// cancella appena letta (F12.1.13), il testo OCR vive solo in memoria. Si salvano solo le righe
/// interpretate e confermate. ☠ E' la garanzia che i dati della carta degli scontrini (s13) non
/// finiscano mai nel database, nel backup o nel CSV.
///
/// ⚑ Tutti i vincoli che SQL sa esprimere stanno QUI (CHECK, UNIQUE, chiavi esterne, indice
/// unico parziale): un errore di programmazione nel repository diventa un'eccezione, non un dato
/// sbagliato salvato in silenzio. Le regole che SQL non sa esprimere stanno in `SpesaRepository`.

/// I negozi, scritti dall'utente o ricavati dalla testata dello scontrino.
@DataClassName('Negozio')
class Negozi extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// ⚑ UNIQUE COLLATE NOCASE: «Esselunga» ed «ESSELUNGA» sono lo stesso negozio (lo scontrino e'
  /// in maiuscolo, l'utente scrive come vuole).
  TextColumn get nome =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE CHECK (length(nome) BETWEEN 1 AND 60)')();

  /// Epoch ms UTC.
  IntColumn get creatoIl => integer()();
}

/// Le spese: una sola in corso (indice unico parziale), le altre chiuse.
@DataClassName('SpesaRow')
@TableIndex.sql("CREATE UNIQUE INDEX spese_una_in_corso ON spese (stato) WHERE stato = 'in_corso'")
@TableIndex.sql('CREATE INDEX idx_spese_storico ON spese (stato, data_spesa DESC, id DESC)')
@TableIndex.sql('CREATE INDEX idx_spese_negozio ON spese (negozio_id)')
class Spese extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'in_corso' | 'chiusa'.
  TextColumn get stato => text().check(stato.isIn(const ['in_corso', 'chiusa']))();

  /// ON DELETE SET NULL: eliminare un negozio lascia le spese «senza negozio».
  IntColumn get negozioId => integer().nullable().references(Negozi, #id, onDelete: KeyAction.setNull)();

  /// Epoch ms UTC.
  IntColumn get iniziataIl => integer()();

  /// Epoch ms UTC; presente se e solo se chiusa (CHECK di tabella).
  IntColumn get chiusaIl => integer().nullable()();

  /// `YYYY-MM-DD` (`CivilDate`, ADR-008): il giorno della spesa, dallo scontrino se letto.
  /// Obbligatoria quando chiusa (CHECK di tabella).
  TextColumn get dataSpesa => text().nullable()();

  IntColumn get budgetCents => integer().nullable().check(budgetCents.isBiggerThanValue(0))();

  /// ⚑ Scritto alla CHIUSURA (`Spesa.totale`) e mai ricalcolato: un aggiornamento delle regole di
  /// calcolo non deve cambiare lo storico. Per la spesa in corso vale 0: si calcola dalle righe.
  IntColumn get totaleCents => integer().withDefault(const Constant(0))();

  /// Il TOTALE stampato sullo scontrino, se letto.
  IntColumn get totaleScontrinoCents => integer().nullable()();

  /// 'contate' | 'scontrino': quale insieme di righe fa fede.
  TextColumn get fonte =>
      text().withDefault(const Constant('contate')).check(fonte.isIn(const ['contate', 'scontrino']))();

  @override
  List<String> get customConstraints => [
    "CHECK ((stato = 'chiusa') = (chiusa_il IS NOT NULL))",
    "CHECK (stato <> 'chiusa' OR data_spesa IS NOT NULL)",
  ];
}

/// Le righe: le contate e quelle dello scontrino, affiancate (`insieme`).
@DataClassName('RigaRow')
@TableIndex.sql('CREATE INDEX idx_righe_spesa ON righe (spesa_id, insieme, posizione)')
class Righe extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get spesaId => integer().references(Spese, #id, onDelete: KeyAction.cascade)();

  /// ⚑ 'contate' | 'scontrino': le righe dello scontrino si AFFIANCANO a quelle contate, non le
  /// sostituiscono (nel dettaglio si vedono entrambe).
  TextColumn get insieme => text().check(insieme.isIn(const ['contate', 'scontrino']))();

  /// Ordine di inserimento dentro l'insieme.
  IntColumn get posizione => integer()();

  TextColumn get nome => text().withDefault(const Constant('')).check(nome.length.isSmallerOrEqualValue(80))();

  IntColumn get pezzi => integer().nullable().check(pezzi.isBetweenValues(1, 999))();

  /// Grammi o millilitri.
  IntColumn get millesimi => integer().nullable().check(millesimi.isBetweenValues(1, 99999))();

  TextColumn get unita => text().nullable().check(unita.isIn(const ['kg', 'l']))();

  /// Negativo solo per gli sconti; mai zero.
  IntColumn get prezzoUnitarioCents => integer().check(prezzoUnitarioCents.equals(0).not())();

  /// `RigaSpesa.totale` al momento dell'inserimento (stesso motivo di `spese.totale_cents`).
  IntColumn get totaleCents => integer()();

  /// `Offerta.toJson()`.
  TextColumn get offertaJson => text().nullable()();

  /// €/kg o €/l stampato sul cartellino di un prodotto a pezzi.
  IntColumn get prezzoRifCents => integer().nullable()();

  TextColumn get unitaRif => text().nullable().check(unitaRif.isIn(const ['kg', 'l']))();

  /// Bilancia (e righe dello scontrino): l'importo stampato, che vince sul calcolo.
  IntColumn get totaleStampatoCents => integer().nullable()();

  TextColumn get origine =>
      text().check(origine.isIn(const ['tastierino', 'cartellino', 'bilancia', 'scontrino']))();

  /// Solo `insieme = 'scontrino'`: un articolo annullato da uno storno.
  BoolColumn get stornata => boolean().withDefault(const Constant(false))();

  /// Epoch ms UTC.
  IntColumn get creataIl => integer()();

  @override
  List<String> get customConstraints => [
    'CHECK ((pezzi IS NOT NULL AND millesimi IS NULL AND unita IS NULL) '
        'OR (pezzi IS NULL AND millesimi IS NOT NULL AND unita IS NOT NULL))',
  ];
}

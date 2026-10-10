import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/data/database.dart';
import 'package:spending_review/data/spending_backup_source.dart';
import 'package:spending_review/data/spesa_repository.dart';
import 'package:spending_review/domain/lettura/scontrino_parser.dart';
import 'package:spending_review/domain/offerta.dart';
import 'package:spending_review/domain/quantita.dart';
import 'package:spending_review/domain/riga_spesa.dart';
import 'package:spending_review/domain/spesa.dart';

/// F12.1.13: il backup fa andata e ritorno con il file vero di `BackupService`, scritto e riletto
/// da disco fra due «telefoni» (due database in memoria e due cartelle diverse), nelle due modalita'.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late SpendingDatabase vecchioDb;
  late SpesaRepository vecchio;
  late AppPaths vecchiePaths;
  late SpendingDatabase nuovoDb;
  late SpesaRepository nuovo;
  late AppPaths nuovePaths;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('sr_backup_');
    vecchiePaths = AppPaths.underRoot(Directory('${tmp.path}/vecchio'));
    nuovePaths = AppPaths.underRoot(Directory('${tmp.path}/nuovo'));
    await vecchiePaths.ensureAll();
    await nuovePaths.ensureAll();
    vecchioDb = SpendingDatabase.memory();
    vecchio = SpesaRepository(vecchioDb, ora: () => DateTime.utc(2026, 10, 9, 18));
    nuovoDb = SpendingDatabase.memory();
    nuovo = SpesaRepository(nuovoDb, ora: () => DateTime.utc(2026, 10, 10, 9));
  });

  tearDown(() async {
    await vecchioDb.close();
    await nuovoDb.close();
    await tmp.delete(recursive: true);
  });

  RigaSpesa riga(String nome, int cents, {Quantita q = const Pezzi(1), Offerta? o}) =>
      RigaSpesa(nome: nome, quantita: q, prezzoUnitario: Money.cents(cents), offerta: o, origine: OrigineRiga.tastierino);

  /// Sul vecchio telefono: una spesa chiusa dall'Esselunga con offerta e riga pesata, una registrata
  /// dallo scontrino, e una IN CORSO.
  Future<void> riempiVecchio() async {
    final negozio = await vecchio.negozioPerNome('Esselunga');
    await vecchio.impostaBudget(Money.cents(5000));
    await vecchio.aggiungiRiga(riga('Pasta', 189, q: const Pezzi(3), o: const OffertaNxM(prendi: 3, paghi: 2)));
    await vecchio.aggiungiRiga(riga('Mele', 250, q: const AMisura(612, UnitaMisura.kg)));
    await vecchio.chiudi(data: CivilDate(2026, 10, 8), negozioId: negozio, fonte: FonteRighe.contate);
    await vecchio.registraDaScontrino(
      const LetturaScontrino(
        righe: [RigaScontrino(descrizione: 'PANE', importo: Money.cents(120), tipo: TipoRigaScontrino.articolo)],
        totale: Money.cents(120),
        righeIgnorate: 0,
      ),
      data: CivilDate(2026, 10, 9),
      negozioId: negozio,
    );
    await vecchio.aggiungiRiga(riga('Latte', 150));
  }

  Future<File> backup() async {
    final r = await BackupService(paths: vecchiePaths, appVersion: '1.0.0').createBackup(SpendingBackupSource(vecchioDb));
    return r.valueOrNull!;
  }

  Future<void> ripristina(File f, ImportMode mode) async {
    final r = await BackupService(paths: nuovePaths, appVersion: '1.0.0').restore(f, SpendingBackupSource(nuovoDb), mode: mode);
    expect(r.isOk, isTrue, reason: '$r');
  }

  test('counts e nessuna immagine', () async {
    await riempiVecchio();
    final s = SpendingBackupSource(vecchioDb);
    expect(await s.counts(), {'spese': 3, 'righe': 4, 'negozi': 1});
    expect(await s.imagePaths(), isEmpty);
  });

  test('replaceAll: tutto uguale, anche la spesa in corso, e i totali scritti', () async {
    await riempiVecchio();
    // Il nuovo telefono ha gia' qualcosa: sparisce.
    await nuovo.aggiungiRiga(riga('Da buttare', 999));
    await ripristina(await backup(), ImportMode.replaceAll);

    final chiuse = await nuovo.osservaChiuse().first;
    expect([for (final s in chiuse) s.totale.cents], [120, 189 * 2 + 153]);
    expect(chiuse[1].righe[0].offerta, const OffertaNxM(prendi: 3, paghi: 2));
    expect(chiuse[1].righe[1].quantita, const AMisura(612, UnitaMisura.kg));
    expect(chiuse[1].budget, Money.cents(5000));
    expect(chiuse[0].fonte, FonteRighe.scontrino);
    final negozi = await nuovo.osservaNegozi().first;
    expect([for (final n in negozi) n.nome], ['Esselunga']);
    expect(chiuse.every((s) => s.negozioId == negozi.single.id), isTrue);
    final inCorso = await nuovo.osservaInCorso().first;
    expect([for (final r in inCorso!.righe) r.nome], ['Latte']);
  });

  test('mergeKeepExisting: negozi uniti per nome, la spesa in corso del file diventa chiusa', () async {
    await riempiVecchio();
    await nuovo.negozioPerNome('ESSELUNGA');
    await nuovo.aggiungiRiga(riga('Caffe', 300)); // la spesa in corso del telefono vince
    await ripristina(await backup(), ImportMode.mergeKeepExisting);

    expect(await nuovo.osservaNegozi().first, hasLength(1));
    final chiuse = await nuovo.osservaChiuse().first;
    expect(chiuse, hasLength(3));
    final exInCorso = chiuse.firstWhere((s) => s.righe.any((r) => r.nome == 'Latte'));
    expect(exInCorso.stato, StatoSpesa.chiusa);
    expect(exInCorso.dataSpesa, CivilDate(2026, 10, 9));
    expect(exInCorso.totale, Money.cents(150));
    final inCorso = await nuovo.osservaInCorso().first;
    expect([for (final r in inCorso!.righe) r.nome], ['Caffe']);
  });

  test('mergeKeepExisting: una spesa in corso del file SENZA righe si scarta', () async {
    await vecchio.assicuraInCorso();
    await ripristina(await backup(), ImportMode.mergeKeepExisting);
    expect(await nuovo.osservaChiuse().first, isEmpty);
    expect(await nuovo.osservaInCorso().first, isNull);
  });

  test('un file rotto non tocca il database, nemmeno con replaceAll', () async {
    await nuovo.aggiungiRiga(riga('Resta', 100));
    final source = SpendingBackupSource(nuovoDb);
    await expectLater(
      source.importPayload({
        'negozi': <Object?>[],
        'spese': [
          {'id': 1, 'stato': 'chiusa'},
        ],
        'righe': <Object?>[],
      }, mode: ImportMode.replaceAll),
      throwsFormatException,
    );
    expect((await nuovo.osservaInCorso().first)!.righe.single.nome, 'Resta');
  });
}

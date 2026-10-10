import 'package:drift/drift.dart';
import 'package:micro_core/micro_core.dart';

import 'database.dart';

/// Come Spending Review si esporta e si reimporta (develop_microapps.md F12.1.13). Creare il backup
/// e' Pro (`FeatureKey.backupRestore`), ripristinarlo e' gratis (come in tutte le app).
///
/// Il file e' quello di `BackupService.createBackup` (JSON, **nessuna immagine**: l'app non ne
/// conserva). Forma del payload, schema 1:
/// ```
/// negozi: [{id, nome, creatoIl}]
/// spese:  [{id, stato, negozioId?, iniziataIl, chiusaIl?, dataSpesa?, budget?, totale,
///           totaleScontrino?, fonte}]
/// righe:  [{spesaId, insieme, posizione, nome, pezzi?, millesimi?, unita?, prezzoUnitario, totale,
///           offerta?, prezzoRif?, unitaRif?, totaleStampato?, origine, stornata, creataIl}]
/// ```
/// Gli importi in centesimi interi, le date come nel database (epoch ms UTC, `YYYY-MM-DD`).
/// ⚑ Gli `id` nel file servono SOLO a collegare righe → spese → negozi dentro il file: al
/// ripristino si riassegnano.
/// ☠ Niente testo OCR e niente foto, perche' il database non ne ha (F12.1.10): il backup non puo'
/// portarsi dietro i dati della carta di uno scontrino.
///
/// Ripristino:
/// - `replaceAll`: svuota e riscrive tutto in una transazione (anche la spesa in corso del file).
/// - `mergeKeepExisting`: negozi uniti per nome (senza distinguere le maiuscole); spese aggiunte
///   con id nuovi; ⚑ una spesa IN CORSO del file diventa CHIUSA (data = giorno di `iniziataIl`) se
///   ha righe, altrimenti si scarta: l'indice unico ne vuole una sola, e quella del telefono vince.
class SpendingBackupSource implements BackupSource {
  SpendingBackupSource(this._db);

  final SpendingDatabase _db;

  static const String id = 'spending_review';

  @override
  String get schemaId => id;

  @override
  int get schemaVersion => 1;

  @override
  Future<Map<String, Object?>> exportPayload() async {
    final negozi = await _db.select(_db.negozi).get();
    final spese = await _db.select(_db.spese).get();
    final righe = await (_db.select(_db.righe)..orderBy([(r) => OrderingTerm(expression: r.id)])).get();
    return {
      'negozi': [for (final n in negozi) {'id': n.id, 'nome': n.nome, 'creatoIl': n.creatoIl}],
      'spese': [
        for (final s in spese)
          {
            'id': s.id,
            'stato': s.stato,
            'negozioId': s.negozioId,
            'iniziataIl': s.iniziataIl,
            'chiusaIl': s.chiusaIl,
            'dataSpesa': s.dataSpesa,
            'budget': s.budgetCents,
            'totale': s.totaleCents,
            'totaleScontrino': s.totaleScontrinoCents,
            'fonte': s.fonte,
          },
      ],
      'righe': [
        for (final r in righe)
          {
            'spesaId': r.spesaId,
            'insieme': r.insieme,
            'posizione': r.posizione,
            'nome': r.nome,
            'pezzi': r.pezzi,
            'millesimi': r.millesimi,
            'unita': r.unita,
            'prezzoUnitario': r.prezzoUnitarioCents,
            'totale': r.totaleCents,
            'offerta': r.offertaJson,
            'prezzoRif': r.prezzoRifCents,
            'unitaRif': r.unitaRif,
            'totaleStampato': r.totaleStampatoCents,
            'origine': r.origine,
            'stornata': r.stornata,
            'creataIl': r.creataIl,
          },
      ],
    };
  }

  @override
  Future<Map<String, int>> counts() async {
    Future<int> conta(TableInfo<Table, Object?> t) async {
      final n = countAll();
      final q = _db.selectOnly(t)..addColumns([n]);
      return (await q.getSingle()).read(n) ?? 0;
    }

    return {'spese': await conta(_db.spese), 'righe': await conta(_db.righe), 'negozi': await conta(_db.negozi)};
  }

  @override
  Future<List<String>> imagePaths() async => const [];

  /// ☠ Un file rotto (campo mancante, tipo sbagliato) lancia FormatException DENTRO la transazione:
  /// il database resta com'era, anche con `replaceAll`.
  @override
  Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode}) async {
    final negozi = _lista(payload, 'negozi');
    final spese = _lista(payload, 'spese');
    final righe = _lista(payload, 'righe');

    await _db.transaction(() async {
      if (mode == ImportMode.replaceAll) {
        await _db.delete(_db.righe).go();
        await _db.delete(_db.spese).go();
        await _db.delete(_db.negozi).go();
      }

      // Negozi: per nome, senza distinguere le maiuscole (anche in replaceAll il file potrebbe
      // averne due uguali scritti in modo diverso, e l'indice UNIQUE NOCASE li rifiuterebbe).
      final mappaNegozi = <int, int>{};
      for (final n in negozi) {
        final nome = _testo(n, 'nome').trim();
        if (nome.isEmpty) continue;
        final esistente =
            await (_db.select(_db.negozi)..where((x) => x.nome.collate(Collate.noCase).equals(nome))).getSingleOrNull();
        mappaNegozi[_intero(n, 'id')] = esistente?.id ??
            await _db.into(_db.negozi).insert(NegoziCompanion.insert(nome: nome, creatoIl: _intero(n, 'creatoIl')));
      }

      final inCorsoNelTelefono =
          await (_db.select(_db.spese)..where((s) => s.stato.equals('in_corso'))).getSingleOrNull() != null;
      final righePerSpesa = <int, List<Map<String, Object?>>>{};
      for (final r in righe) {
        (righePerSpesa[_intero(r, 'spesaId')] ??= []).add(r);
      }

      for (var s in spese) {
        final idFile = _intero(s, 'id');
        var stato = _testo(s, 'stato');
        int? chiusaIl = _interoONull(s, 'chiusaIl');
        String? dataSpesa = s['dataSpesa'] as String?;
        final sueRighe = righePerSpesa[idFile] ?? const [];
        if (stato == 'in_corso' && (mode == ImportMode.mergeKeepExisting || inCorsoNelTelefono)) {
          if (sueRighe.isEmpty) continue;
          // Diventa chiusa: la data e' il giorno in cui era iniziata, il totale quello delle righe
          // contate del file (scritte con il loro totale_cents).
          final iniziata = DateTime.fromMillisecondsSinceEpoch(_intero(s, 'iniziataIl'), isUtc: true);
          stato = 'chiusa';
          chiusaIl = iniziata.millisecondsSinceEpoch;
          dataSpesa = CivilDate.fromDateTime(iniziata.toLocal()).toIso();
          s = {...s, 'totale': sueRighe.where((r) => r['insieme'] == 'contate').fold<int>(0, (a, r) => a + _intero(r, 'totale'))};
        }
        final negozioFile = _interoONull(s, 'negozioId');
        final nuovoId = await _db.into(_db.spese).insert(SpeseCompanion.insert(
          stato: stato,
          negozioId: Value(negozioFile == null ? null : mappaNegozi[negozioFile]),
          iniziataIl: _intero(s, 'iniziataIl'),
          chiusaIl: Value(chiusaIl),
          dataSpesa: Value(dataSpesa),
          budgetCents: Value(_interoONull(s, 'budget')),
          totaleCents: Value(_intero(s, 'totale')),
          totaleScontrinoCents: Value(_interoONull(s, 'totaleScontrino')),
          fonte: Value(_testo(s, 'fonte')),
        ));
        for (final r in sueRighe) {
          await _db.into(_db.righe).insert(RigheCompanion.insert(
            spesaId: nuovoId,
            insieme: _testo(r, 'insieme'),
            posizione: _intero(r, 'posizione'),
            nome: Value(_testo(r, 'nome')),
            pezzi: Value(_interoONull(r, 'pezzi')),
            millesimi: Value(_interoONull(r, 'millesimi')),
            unita: Value(r['unita'] as String?),
            prezzoUnitarioCents: _intero(r, 'prezzoUnitario'),
            totaleCents: _intero(r, 'totale'),
            offertaJson: Value(r['offerta'] as String?),
            prezzoRifCents: Value(_interoONull(r, 'prezzoRif')),
            unitaRif: Value(r['unitaRif'] as String?),
            totaleStampatoCents: Value(_interoONull(r, 'totaleStampato')),
            origine: _testo(r, 'origine'),
            stornata: Value(r['stornata'] == true),
            creataIl: _intero(r, 'creataIl'),
          ));
        }
      }
    });
  }

  static List<Map<String, Object?>> _lista(Map<String, Object?> payload, String chiave) {
    final v = payload[chiave];
    if (v is! List) throw FormatException('backup: «$chiave» mancante');
    return [
      for (final x in v)
        if (x is Map<String, Object?>) x else throw FormatException('backup: elemento di «$chiave» non valido'),
    ];
  }

  static int _intero(Map<String, Object?> m, String k) =>
      _interoONull(m, k) ?? (throw FormatException('backup: «$k» mancante'));

  static int? _interoONull(Map<String, Object?> m, String k) => switch (m[k]) {
    null => null,
    final int v => v,
    final num v when v == v.roundToDouble() => v.toInt(),
    _ => throw FormatException('backup: «$k» non e\' un intero'),
  };

  static String _testo(Map<String, Object?> m, String k) =>
      m[k] is String ? m[k]! as String : throw FormatException('backup: «$k» mancante');
}

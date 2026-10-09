import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/qr_content.dart';
import '../domain/qr_decoder.dart';
import '../domain/qr_style.dart';
import 'tables.dart';

export 'tables.dart' show QrSource, qrKindKeys;

part 'database.g.dart';

/// Il database di QR Me: la sola tabella `qr_codes` (F17.1.4).
///
/// Le query e le regole (niente doppioni in cronologia, potatura, logo orfano) vivono in
/// `QrRepository`, non qui: il database dichiara la forma dei dati, il repository le regole
/// che nessun vincolo SQL puo' esprimere. Stesso schema di Film Tracker.
@DriftDatabase(tables: [QrCodes])
class QrDatabase extends _$QrDatabase {
  QrDatabase(super.e);

  /// Database su file, nella cartella documenti dell'app.
  factory QrDatabase.open() => QrDatabase(_openConnection());

  /// Database in memoria, per i test. Non tocca il disco.
  factory QrDatabase.memory() => QrDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Alla versione 1 non esistono migrazioni. Il ramo resta scritto perche' la prima
    // modifica di schema dovra' incrementare schemaVersion E aggiungere qui il passo, con il
    // suo test: senza, il primo aggiornamento in produzione cancella i dati degli utenti.
    onUpgrade: (m, from, to) async {
      throw UnsupportedError(
        'Migrazione da schema $from a $to non implementata. '
        'Aggiungere il passo in QrDatabase.migration e il relativo test.',
      );
    },
  );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'qr_me.sqlite'));

  // ☠ Su Android la cartella temporanea di sistema non e' scrivibile dal processo dell'app:
  // senza questa riga VACUUM e alcuni ORDER BY grandi falliscono con "unable to open
  // database file", e solo su dispositivo, mai in test. Vedi apps/trashcan.
  sqlite3.tempDirectory = (await getTemporaryDirectory()).path;

  // ☠ Debito (F17.1.4): su iOS la cartella del database va esclusa dal backup iCloud con
  // NSURLIsExcludedFromBackupKey (password del Wi-Fi). Da Dart non si imposta senza un canale
  // nativo: si fa in F17.4/F17.7 nell'AppDelegate. Su Android basta allowBackup="false".

  // Su un isolate separato: le query non bloccano il thread della UI.
  return NativeDatabase.createInBackground(file);
});

// ── Dalle righe al dominio ──────────────────────────────────────────────────
//
// ⚑ Le righe restano righe (le schermate hanno bisogno di id, titolo, preferito) e il dominio
// si chiede esplicitamente dove serve, come in Film Tracker.

extension QrCodeToDomain on QrCode {
  /// ☠ StateError su una chiave sconosciuta: con il CHECK succede solo con un dato scritto da
  /// una versione futura, e un dato sbagliato in silenzio e' peggio di un errore visibile.
  QrKind get kindEnum => QrKind.values.asNameMap()[kind] ?? (throw StateError('QR $id: tipo "$kind"'));

  /// Il contenuto: dai campi salvati se ci sono (riaprono il modulo esattamente), altrimenti
  /// dal payload (testo, link, o un fields_json illeggibile).
  ///
  /// ⚑ Per testo e link il payload e' decodificato con `decode` e non `decodeTyped`: e' la
  /// stringa gia' nel QR, e deve tornare lo stesso contenuto che si e' mostrato.
  QrContent get content {
    final f = fieldsJson;
    if (f != null) {
      try {
        final map = jsonDecode(f);
        if (map is Map<String, Object?>) return QrContent.fromFields(kindEnum, map);
      } on FormatException {
        // Campi rotti: si ripiega sul payload, che e' la verita' del QR.
      }
    }
    final decoded = QrDecoder.decode(payload);
    // Un testo che "sembra" un altro tipo resta testo se cosi' era stato salvato.
    return (kindEnum == QrKind.text && decoded is! TextContent) ? TextContent(payload) : decoded;
  }

  /// Lo stile; [QrStyle.plain] se null o illeggibile (`QrStyle.fromJson` e' tollerante).
  QrStyle get style {
    final s = styleJson;
    if (s == null) return QrStyle.plain;
    try {
      final map = jsonDecode(s);
      return map is Map<String, Object?> ? QrStyle.fromJson(map) : QrStyle.plain;
    } on FormatException {
      return QrStyle.plain;
    }
  }

  DateTime get createdAtUtc => DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true);

  DateTime get lastUsedAtUtc => DateTime.fromMillisecondsSinceEpoch(lastUsedAt, isUtc: true);
}

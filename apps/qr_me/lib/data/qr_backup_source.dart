import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:micro_core/micro_core.dart';

import '../domain/qr_content.dart';
import '../domain/qr_style.dart';
import 'database.dart';
import 'qr_repository.dart';

/// Come QR Me si esporta e si reimporta, **con i loghi foto** (develop_microapps.md F17.1.1).
/// Creare il backup e' Pro (`FeatureKey.backupRestore`), ripristinarlo e' gratis (come nelle
/// altre app).
///
/// Il file e' lo ZIP di `BackupService.createBackup(includeImages: true)`: `data.json` con il
/// payload qui sotto, piu' i file dei loghi ([imagePaths]) agli stessi percorsi relativi.
///
/// Forma del payload:
/// ```
/// codes: [{kind, payload, fields?, title, source, style?, favorite, createdAt, lastUsedAt}]
/// ```
/// `fields` e `style` viaggiano come oggetti JSON e non come stringhe: il file resta leggibile
/// con un editor.
///
/// ⚑ Niente id: non significano niente su un altro telefono, e nessuno li referenzia.
///
/// ☠ **"Sostituisci tutto" cancella anche i loghi che il backup non riporta**: le righe
/// spariscono, i file no. Si cancellano **dopo** la transazione riuscita, e solo quelli che il
/// file non riscrivera' (stessa regola di `FilmBackupSource`).
///
/// ⚑ Il limite di 5 in cronologia del piano gratuito **non** si applica al ripristino: riporta
/// i dati come erano. Lo riapplica la prossima `pruneHistory` dopo un QR mostrato.
class QrBackupSource implements BackupSource {
  const QrBackupSource(this.db, {this.paths, this.clock});

  final QrDatabase db;

  /// Le cartelle dell'app, per cancellare i loghi orfani dopo un "sostituisci tutto". Null nei
  /// test che provano solo il database.
  final AppPaths? paths;

  /// Per i test: l'ora usata quando il file non porta le date.
  final DateTime Function()? clock;

  static const String id = 'qr_me';

  @override
  String get schemaId => id;

  @override
  int get schemaVersion => 1;

  // ── Esportazione ─────────────────────────────────────────────────────────

  @override
  Future<Map<String, Object?>> exportPayload() async {
    final rows = await (db.select(db.qrCodes)..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
    return <String, Object?>{
      'codes': [
        for (final r in rows)
          <String, Object?>{
            'kind': r.kind,
            'payload': r.payload,
            'fields': r.fieldsJson == null ? null : jsonDecode(r.fieldsJson!),
            'title': r.title,
            'source': r.source,
            'style': r.styleJson == null ? null : jsonDecode(r.styleJson!),
            'favorite': r.isFavorite,
            'createdAt': r.createdAt,
            'lastUsedAt': r.lastUsedAt,
          },
      ],
    };
  }

  /// I file dei loghi foto (immagine e miniatura), relativi alla cartella documenti.
  @override
  Future<List<String>> imagePaths() async {
    final used = await QrRepository(db).usedLogoImages();
    return [for (final name in used.toList()..sort()) ...QrLogoFiles.filesOf(name)];
  }

  @override
  Future<Map<String, int>> counts() async => <String, int>{
    'favorites': await db.qrCodes.count(where: (t) => t.isFavorite.equals(true)).getSingle(),
    'history': await db.qrCodes.count(where: (t) => t.isFavorite.equals(false)).getSingle(),
  };

  // ── Ripristino ───────────────────────────────────────────────────────────

  /// Scrive il contenuto di [payload] nel database, tutto in una transazione.
  ///
  /// - `replaceAll`: cancella tutti i QR e mette quelli del file.
  /// - `mergeKeepExisting`: aggiunge quelli che mancano. Uno **gia' presente** (stesso
  ///   payload, stesso stile, stesso flag di preferito e stesso `createdAt`: lo stesso QR
  ///   ripristinato due volte) si salta.
  ///
  /// ☠ Lancia [FormatException] (mai un `Error`) su un file con tipi sconosciuti, campi del tipo
  /// sbagliato o percorsi di logo sospetti: `BackupService.restore` intercetta solo le
  /// `Exception`. La transazione intanto e' gia' annullata: niente ripristini a meta'.
  @override
  Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode}) async {
    final now = (clock ?? DateTime.now)().toUtc().millisecondsSinceEpoch;
    final orphans = <String>{};
    try {
      await db.transaction(() async {
        if (mode == ImportMode.replaceAll) {
          orphans.addAll(await QrRepository(db).usedLogoImages());
          await db.delete(db.qrCodes).go();
        }
        final existing = await db.select(db.qrCodes).get();
        final seen = {for (final r in existing) (r.payload, r.styleJson, r.isFavorite, r.createdAt)};

        for (final c in _list(payload['codes'])) {
          final kind = c['kind'];
          if (kind is! String || !qrKindKeys.contains(kind)) throw FormatException('Tipo di QR sconosciuto ($kind)');
          final source = c['source'];
          if (source is! String || !QrSource.all.contains(source)) {
            throw FormatException('Provenienza sconosciuta ($source)');
          }
          final fields = c['fields'];
          if (fields != null) {
            if (fields is! Map) throw FormatException('Campi del QR non validi ($fields)');
            // Si verifica che si rileggano: un fields_json rotto renderebbe il QR non riapribile.
            QrContent.fromFields(QrKind.values.byName(kind), fields.cast<String, Object?>());
          }
          final styleRaw = c['style'];
          String? styleJson;
          if (styleRaw != null) {
            if (styleRaw is! Map) throw FormatException('Stile del QR non valido ($styleRaw)');
            final style = QrStyle.fromJson(styleRaw.cast<String, Object?>());
            if (style.logo case PhotoLogo(:final imageName)) {
              _logoPath(imageName);
              orphans.remove(imageName);
            }
            // ⚑ Si riscrive dalla forma letta: chiavi sconosciute di una versione futura cadono
            // qui, e il database resta coerente con quello che l'app sa leggere.
            styleJson = style.isPlain ? null : jsonEncode(style.toJson());
          }
          final favorite = c['favorite'] == true;
          final createdAt = (c['createdAt'] as num?)?.toInt() ?? now;
          final p = c['payload']! as String;
          if (!seen.add((p, styleJson, favorite, createdAt))) continue;
          await db.into(db.qrCodes).insert(
            QrCodesCompanion.insert(
              kind: kind,
              payload: p,
              fieldsJson: Value(fields == null ? null : jsonEncode(fields)),
              title: c['title']! as String,
              source: source,
              styleJson: Value(styleJson),
              isFavorite: Value(favorite),
              createdAt: createdAt,
              lastUsedAt: (c['lastUsedAt'] as num?)?.toInt() ?? createdAt,
            ),
          );
        }
      });
    } on TypeError catch (error) {
      throw FormatException('Backup di QR Me malformato: $error');
    } on InvalidDataException catch (error) {
      // Un titolo vuoto o un payload troppo lungo: i vincoli di Drift.
      throw FormatException('Backup di QR Me non valido: ${error.message}');
    }

    // Solo a transazione riuscita: con un file rotto i loghi del telefono restano.
    final pa = paths;
    if (pa != null && mode == ImportMode.replaceAll) {
      final images = ImageStore(paths: pa);
      for (final name in orphans) {
        try {
          await images.delete(
            StoredImage(
              path: name,
              thumbPath: QrLogoFiles.thumbOf(name),
              width: 0,
              height: 0,
              bytes: 0,
              createdAt: DateTime.now().toUtc(),
            ),
          );
        } on Object catch (error, stack) {
          MicroLog.e('logo orfano non cancellato: $name', error: error, stackTrace: stack);
        }
      }
    }
  }

  /// Un percorso di logo relativo, sotto `images/`.
  ///
  /// ☠ Un file di backup e' un dato esterno: un percorso con `..` o assoluto, scritto nel
  /// database, farebbe leggere (e cancellare, con "sostituisci tutto") un file fuori dalla
  /// cartella dell'app.
  static String _logoPath(String path) {
    if (!path.startsWith('images/') || path.contains('..') || path.contains(r'\') || path.contains(':')) {
      throw FormatException('Percorso del logo non ammesso ($path)');
    }
    return path;
  }

  static List<Map<String, Object?>> _list(Object? raw) =>
      raw is List ? [for (final e in raw) if (e is Map) e.cast<String, Object?>()] : const [];
}

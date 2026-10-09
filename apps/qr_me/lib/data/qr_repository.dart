import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:micro_core/micro_core.dart';

import '../domain/qr_content.dart';
import '../domain/qr_style.dart';
import 'database.dart';

/// I file del logo foto in `ImageStore` (bucket `logos`).
///
/// ⚑ `PhotoLogo.imageName` e' il percorso relativo dell'immagine (`StoredImage.path`); la
/// miniatura che `ImageStore.importBytes` scrive accanto si ricava da li', cosi' lo stile salva
/// una stringa sola invece di uno `StoredImage` intero.
abstract final class QrLogoFiles {
  /// Il bucket di `ImageStore.importBytes(bucket: ...)` per i loghi.
  static const String bucket = 'logos';

  /// `images/logos/x.jpg` -> `images/thumbs/logos/x.jpg` (la regola di `ImageStore`).
  static String thumbOf(String imageName) =>
      imageName.startsWith('images/') ? 'images/thumbs/${imageName.substring(7)}' : imageName;

  /// I due file di un logo, relativi alla cartella documenti.
  static List<String> filesOf(String imageName) => [imageName, thumbOf(imageName)];
}

/// Cronologia e preferiti (develop_microapps.md F17.1.4).
///
/// Regole che vivono qui e non nello schema:
/// - **niente doppioni in cronologia**: un QR non preferito con lo stesso payload e lo stesso
///   stile si "tocca" invece di aggiungersi (`recordShown`, `unfavorite`, `updateStyle`);
/// - **la potatura non tocca i preferiti** (`pruneHistory`);
/// - **un logo foto che nessuno usa piu' si cancella dal disco** (`delete`, `clearHistory`,
///   `pruneHistory`, `updateStyle`).
///
/// ⚑ **Nessuna scrittura implicita**: ogni metodo scrive solo quando e' chiamato. "Cronologia
/// spenta = nessuna scrittura" (F17.0 punto 7) e' una regola del chiamante: con la cronologia
/// spenta la pagina non chiama [recordShown] e mostra il QR da un oggetto in memoria.
///
/// ⚑ I limiti del piano gratuito (5 in cronologia, 1 preferito) **non** sono qui: li decide
/// `FeatureGate`. Il repository offre [pruneHistory] e [countFavorites] e non sa chi e' Pro.
class QrRepository {
  QrRepository(this._db, {this.images, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final QrDatabase _db;

  /// Per cancellare i loghi orfani. Null nei test che provano solo il database: allora i file
  /// non si toccano (li raccoglierebbe `ImageStore.pruneOrphans`).
  final ImageStore? images;

  final DateTime Function() _clock;

  int _now() => _clock().toUtc().millisecondsSinceEpoch;

  // ── Letture ──────────────────────────────────────────────────────────────

  /// I non preferiti, dal piu' recente (`last_used_at DESC`, poi id per stabilita').
  Stream<List<QrCode>> watchHistory() => (_db.select(_db.qrCodes)
        ..where((t) => t.isFavorite.equals(false))
        ..orderBy([
          (t) => OrderingTerm(expression: t.lastUsedAt, mode: OrderingMode.desc),
          (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
        ]))
      .watch();

  /// I preferiti per titolo, senza badare alle maiuscole.
  Stream<List<QrCode>> watchFavorites() => (_db.select(_db.qrCodes)
        ..where((t) => t.isFavorite.equals(true))
        ..orderBy([
          (t) => OrderingTerm(expression: t.title.collate(Collate.noCase)),
          (t) => OrderingTerm(expression: t.id),
        ]))
      .watch();

  Future<QrCode?> byId(int id) => (_db.select(_db.qrCodes)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Una riga per id, che segue le modifiche (la pagina del QR mostrato): null se cancellata.
  Stream<QrCode?> watchById(int id) =>
      (_db.select(_db.qrCodes)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> countFavorites() =>
      _db.qrCodes.count(where: (t) => t.isFavorite.equals(true)).getSingle();

  /// Il conteggio dei preferiti che segue le modifiche: il limite del piano gratuito.
  Stream<int> watchFavoriteCount() =>
      _db.qrCodes.count(where: (t) => t.isFavorite.equals(true)).watchSingle();

  // ── Scritture ────────────────────────────────────────────────────────────

  /// Registra un QR mostrato e ne restituisce l'id. Se esiste gia' un NON preferito con lo
  /// stesso payload e lo stesso `style_json`, aggiorna solo `last_used_at` (niente doppioni in
  /// cronologia). Lancia [ArgumentError] su una [source] che non e' in [QrSource.all].
  ///
  /// ⚑ Un preferito con lo stesso contenuto **non** si tocca: il preferito resta dov'e', e la
  /// visualizzazione dal campo di testo entra in cronologia come cosa a se'.
  Future<int> recordShown({
    required QrContent content,
    required String payload,
    required String source,
    QrStyle style = QrStyle.plain,
  }) {
    if (!QrSource.all.contains(source)) {
      throw ArgumentError.value(source, 'source', 'Una di ${QrSource.all}');
    }
    final styleJson = _styleJson(style);
    return _db.transaction(() async {
      final now = _now();
      final same = await _historyTwins(payload, styleJson).get();
      if (same.isNotEmpty) {
        final id = same.first.id;
        await (_db.update(_db.qrCodes)..where((t) => t.id.equals(id))).write(QrCodesCompanion(lastUsedAt: Value(now)));
        return id;
      }
      return _db.into(_db.qrCodes).insert(
        QrCodesCompanion.insert(
          kind: content.kind.name,
          payload: payload,
          // Testo e link si riaprono dal payload: niente campi (F17.1.4).
          fieldsJson: Value(_fieldsJson(content)),
          title: _title(content.autoTitle),
          source: source,
          styleJson: Value(styleJson),
          createdAt: now,
          lastUsedAt: now,
        ),
      );
    });
  }

  /// `last_used_at = now`: il QR torna in cima alla cronologia.
  Future<void> touch(int id) =>
      (_db.update(_db.qrCodes)..where((t) => t.id.equals(id))).write(QrCodesCompanion(lastUsedAt: Value(_now())));

  /// Lo salva nei preferiti con un nome. Il limite del piano gratuito lo controlla il chiamante
  /// (`FeatureKey.unlimitedEntities` con [countFavorites]).
  Future<void> saveAsFavorite(int id, {required String title}) => (_db.update(_db.qrCodes)
        ..where((t) => t.id.equals(id)))
      .write(QrCodesCompanion(isFavorite: const Value(true), title: Value(_title(title))));

  /// Lo toglie dai preferiti: torna in cima alla cronologia. Se in cronologia c'era gia' il
  /// suo gemello (stesso payload e stile), il gemello si cancella: niente doppioni.
  Future<void> unfavorite(int id) => _db.transaction(() async {
    await (_db.update(_db.qrCodes)..where((t) => t.id.equals(id)))
        .write(QrCodesCompanion(isFavorite: const Value(false), lastUsedAt: Value(_now())));
    await _dropHistoryTwinsOf(id);
  });

  /// Cambia lo stile. Il vecchio logo foto, se nessun altro QR lo usa piu', si cancella.
  Future<void> updateStyle(int id, QrStyle style) async {
    final before = await byId(id);
    if (before == null) return;
    final removed = await _db.transaction(() async {
      await (_db.update(_db.qrCodes)..where((t) => t.id.equals(id)))
          .write(QrCodesCompanion(styleJson: Value(_styleJson(style))));
      return _dropHistoryTwinsOf(id);
    });
    await _deleteOrphanLogos([before, ...removed]);
  }

  /// Cambia il contenuto (la «Modifica» di un preferito dal suo modulo, F17.4). Il titolo resta
  /// quello dato dall'utente; `last_used_at` torna adesso.
  ///
  /// ⚑ Il payload lo passa il chiamante (`QrEncoder.encode(content)`), come in [recordShown]: il
  /// repository non codifica, salva la stringa esatta che e' nel QR.
  Future<void> updateContent(int id, {required QrContent content, required String payload}) =>
      (_db.update(_db.qrCodes)..where((t) => t.id.equals(id))).write(
        QrCodesCompanion(
          kind: Value(content.kind.name),
          payload: Value(payload),
          fieldsJson: Value(_fieldsJson(content)),
          lastUsedAt: Value(_now()),
        ),
      );

  Future<void> rename(int id, String title) =>
      (_db.update(_db.qrCodes)..where((t) => t.id.equals(id))).write(QrCodesCompanion(title: Value(_title(title))));

  /// Cancella il QR e il suo logo foto in `ImageStore`, se nessun altro lo usa.
  Future<void> delete(int id) async {
    final row = await byId(id);
    if (row == null) return;
    await (_db.delete(_db.qrCodes)..where((t) => t.id.equals(id))).go();
    await _deleteOrphanLogos([row]);
  }

  /// Svuota la cronologia: solo i non preferiti.
  Future<void> clearHistory() async {
    final rows = await (_db.select(_db.qrCodes)..where((t) => t.isFavorite.equals(false))).get();
    await (_db.delete(_db.qrCodes)..where((t) => t.isFavorite.equals(false))).go();
    await _deleteOrphanLogos(rows);
  }

  /// Tiene solo gli ultimi [keep] non preferiti (per `last_used_at`) e restituisce quanti ne ha
  /// cancellati. `null` = nessun limite (Pro).
  ///
  /// ⚑ **Cancella davvero** (F17.1.4): nascondere le righe in eccesso e rivelarle al Pro
  /// vorrebbe dire trattenere password del Wi-Fi che l'utente crede sparite.
  Future<int> pruneHistory({required int? keep}) async {
    if (keep == null) return 0;
    if (keep < 0) throw ArgumentError.value(keep, 'keep', 'Non negativo');
    final rows = await (_db.select(_db.qrCodes)
          ..where((t) => t.isFavorite.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.lastUsedAt, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .get();
    if (rows.length <= keep) return 0;
    final extra = rows.sublist(keep);
    await (_db.delete(_db.qrCodes)..where((t) => t.id.isIn([for (final r in extra) r.id]))).go();
    await _deleteOrphanLogos(extra);
    return extra.length;
  }

  // ── Interni ──────────────────────────────────────────────────────────────

  /// Testo e link si riaprono dal payload: niente campi (F17.1.4).
  static String? _fieldsJson(QrContent content) => switch (content) {
    TextContent() || UrlContent() => null,
    _ => jsonEncode(content.toFields()),
  };

  static String? _styleJson(QrStyle style) => style.isPlain ? null : jsonEncode(style.toJson());

  /// Un titolo valido per la colonna (1..80): rifilato, tagliato, mai vuoto.
  static String _title(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '…';
    return t.length <= 80 ? t : t.substring(0, 80);
  }

  SimpleSelectStatement<$QrCodesTable, QrCode> _historyTwins(String payload, String? styleJson) =>
      _db.select(_db.qrCodes)
        ..where(
          (t) =>
              t.isFavorite.equals(false) &
              t.payload.equals(payload) &
              (styleJson == null ? t.styleJson.isNull() : t.styleJson.equals(styleJson)),
        )
        ..orderBy([(t) => OrderingTerm(expression: t.lastUsedAt, mode: OrderingMode.desc)]);

  /// Se [id] e' un non preferito, cancella gli ALTRI non preferiti identici e li restituisce.
  Future<List<QrCode>> _dropHistoryTwinsOf(int id) async {
    final row = await byId(id);
    if (row == null || row.isFavorite) return const [];
    final twins = [for (final r in await _historyTwins(row.payload, row.styleJson).get()) if (r.id != id) r];
    if (twins.isEmpty) return const [];
    await (_db.delete(_db.qrCodes)..where((t) => t.id.isIn([for (final r in twins) r.id]))).go();
    return twins;
  }

  /// Cancella i file dei loghi foto di [rows] che nessuna riga rimasta usa piu'.
  ///
  /// ⚑ Si guarda ogni `style_json` rimasto: due QR possono condividere lo stesso logo (uno
  /// stile copiato), e cancellarne il file perche' uno dei due e' sparito rovinerebbe l'altro.
  /// ☠ Un errore del disco non fa fallire l'operazione: il dato e' gia' cancellato, e il file
  /// orfano lo raccoglie `ImageStore.pruneOrphans`.
  Future<void> _deleteOrphanLogos(Iterable<QrCode> rows) async {
    final images = this.images;
    if (images == null) return;
    final candidates = {
      for (final r in rows)
        if (r.style.logo case PhotoLogo(:final imageName)) imageName,
    };
    if (candidates.isEmpty) return;
    final inUse = await usedLogoImages();
    for (final name in candidates.difference(inUse)) {
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

  /// I loghi foto usati da almeno un QR: per `ImageStore.pruneOrphans` e per il backup.
  Future<Set<String>> usedLogoImages() async {
    final styled = await (_db.select(_db.qrCodes)..where((t) => t.styleJson.isNotNull())).get();
    return {
      for (final r in styled)
        if (r.style.logo case PhotoLogo(:final imageName)) imageName,
    };
  }
}

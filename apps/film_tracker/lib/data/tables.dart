// I vincoli `check(...)` di Drift citano la colonna dentro il suo stesso getter: e' la forma
// documentata da Drift, che legge la definizione senza mai eseguirla. Il lint la scambia per
// una ricorsione infinita.
// ignore_for_file: recursive_getters
import 'package:drift/drift.dart';

import '../domain/film_types.dart';
import '../domain/roll_status.dart';

/// Le tabelle di Film Tracker (develop_microapps.md F6.2).
///
/// Convenzioni comuni a tutto il monorepo (ADR-008): le **date di calendario** sono TEXT
/// `YYYY-MM-DD` (`loadedAt`, `submittedAt`...), perche' "caricato il 3 marzo" non ha fuso
/// orario; gli **istanti** (`createdAt`) sono millisecondi UTC; i **soldi** sono centesimi
/// interi, mai `double`.
///
/// ⚑ **Le chiavi ammesse nei CHECK vengono dal dominio** (`FilmFormat.key`,
/// `FilmProcess.key`, `RollStatus.key`, `RollImageKind.key`), non da una lista copiata qui.
/// ☠ Il CHECK entra nello schema alla creazione della tabella: aggiungere una chiave dopo il
/// rilascio richiede una migrazione che ricrei la tabella (SQLite non modifica i CHECK).

/// Le chiavi di `format` (macchine, pellicole, rullini).
final List<String> filmFormatKeys = [for (final f in FilmFormat.values) f.key];

/// Le chiavi di `process` (pellicole, sviluppi).
final List<String> filmProcessKeys = [for (final p in FilmProcess.values) p.key];

/// Le chiavi di `film_rolls.status`.
final List<String> rollStatusKeys = [for (final s in RollStatus.values) s.key];

/// Le chiavi di `roll_images.kind`.
final List<String> rollImageKindKeys = [for (final k in RollImageKind.values) k.key];

/// Una macchina fotografica (F6.5). ⚑ Niente numero di serie, anno, valore, obiettivi: la
/// spec avverte che non deve diventare un'app per collezionisti.
class Cameras extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// "Olympus". Dato dell'utente, non testo dell'app.
  TextColumn get manufacturer => text().withLength(min: 1, max: 60)();

  /// "OM-2".
  TextColumn get model => text().withLength(min: 1, max: 60)();

  /// `FilmFormat.key`. Preimposta il formato dei rullini caricati in questa macchina.
  TextColumn get format => text().check(format.isIn(filmFormatKeys))();

  TextColumn get note => text().nullable()();

  /// Una macchina venduta sparisce dalla scelta nel form ma resta sui rullini che ha
  /// scattato. Cancellarla invece stacca i rullini (`cameraId` -> NULL).
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// Ordine nell'elenco (trascinamento).
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Il catalogo delle pellicole: le 25 precaricate (`kFilmCatalog`) e quelle dell'utente.
///
/// ☠ `UNIQUE(brand, name, format)`: due "Kodak Portra 400 35mm" renderebbero ambigua la
/// selezione rapida e spezzerebbero il conteggio delle piu' usate. Il controllo senza
/// maiuscole lo fa `FilmRepository.addCustomStock`; questo e' l'ultimo argine.
class FilmStocks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get brand => text().withLength(min: 1, max: 60)();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// Sensibilita' nominale. Il tetto e' largo (le Delta 3200 si tirano a 25600) ma toglie gli
  /// errori di battitura a sei cifre.
  IntColumn get iso => integer().check(iso.isBetweenValues(1, 100000))();

  TextColumn get process => text().check(process.isIn(filmProcessKeys))();

  TextColumn get format => text().check(format.isIn(filmFormatKeys))();

  /// True per le pellicole aggiunte dall'utente: solo queste si modificano e si cancellano.
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {brand, name, format},
  ];
}

/// Le immagini di un rullino: provini, stampe, scansioni (F6.9).
///
/// ☠ Cancellare la riga non cancella il file: vedi `FilmRepository.deleteImage` e
/// `deleteRollAndCollectImagePaths`, che restituiscono i percorsi da passare a `ImageStore`.
@TableIndex(name: 'idx_roll_images_roll', columns: {#filmRollId, #sortOrder})
class RollImages extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get filmRollId => integer().references(FilmRolls, #id, onDelete: KeyAction.cascade)();

  /// Percorsi **relativi** alla cartella documenti (F1.11, `StoredImage.path`): un percorso
  /// assoluto si rompe al primo aggiornamento dell'app su Android.
  TextColumn get path => text().withLength(min: 1, max: 255)();

  TextColumn get thumbPath => text().withLength(min: 1, max: 255)();

  IntColumn get width => integer().check(width.isBiggerThanValue(0))();

  IntColumn get height => integer().check(height.isBiggerThanValue(0))();

  IntColumn get bytes => integer().check(bytes.isBiggerOrEqualValue(0))();

  /// `RollImageKind.key`.
  TextColumn get kind => text().check(kind.isIn(rollImageKindKeys))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();
}

/// Il rullino: l'entita' principale (F6.2).
@TableIndex(name: 'idx_film_rolls_status', columns: {#status})
@TableIndex(name: 'idx_film_rolls_camera', columns: {#cameraId})
@TableIndex(name: 'idx_film_rolls_stock', columns: {#filmStockId})
class FilmRolls extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Il "#17": `max + 1`, assegnato da `FilmRepository.addRoll`. E' anche l'indirizzo del QR
  /// (`filmtracker://roll/<n>`, F6.12), quindi non si riusa: UNIQUE.
  IntColumn get sequenceNumber => integer().unique().check(sequenceNumber.isBiggerThanValue(0))();

  IntColumn get filmStockId =>
      integer().nullable().references(FilmStocks, #id, onDelete: KeyAction.setNull)();

  /// ⚑ Denormalizzato ("Kodak Portra 400"): se l'utente cancella una pellicola
  /// personalizzata, i rullini continuano a dire che cosa erano.
  TextColumn get filmName => text().withLength(min: 1, max: 120)();

  TextColumn get format => text().check(format.isIn(filmFormatKeys))();

  IntColumn get nominalIso => integer().check(nominalIso.isBetweenValues(1, 100000))();

  /// Push/pull: se diverso da [nominalIso] la UI lo evidenzia.
  IntColumn get exposedIso => integer().check(exposedIso.isBetweenValues(1, 100000))();

  IntColumn get cameraId =>
      integer().nullable().references(Cameras, #id, onDelete: KeyAction.setNull)();

  /// `YYYY-MM-DD`.
  TextColumn get loadedAt => text().nullable().withLength(min: 10, max: 10)();

  /// `YYYY-MM-DD`. Non prima del caricamento (il confronto fra testi ISO e' cronologico).
  TextColumn get finishedAt => text()
      .nullable()
      .withLength(min: 10, max: 10)
      .check(finishedAt.isNull() | loadedAt.isNull() | finishedAt.isBiggerOrEqual(loadedAt))();

  /// Fotogrammi nominali: 36, 24, 12, 16...
  IntColumn get frames => integer().check(frames.isBetweenValues(1, 1000))();

  /// "Praga - settembre 2026".
  TextColumn get title => text().nullable().withLength(max: 120)();

  TextColumn get note => text().nullable()();

  /// `RollStatus.key`.
  TextColumn get status => text().check(status.isIn(rollStatusKeys))();

  /// Costo della pellicola.
  IntColumn get costCents => integer().nullable().check(costCents.isBiggerOrEqualValue(0))();

  /// La copertina dell'archivio. ⚑ Che sia un'immagine **di questo rullino** lo controlla
  /// `FilmRepository.setCoverImage`: un CHECK non puo' leggere un'altra tabella.
  IntColumn get coverImageId =>
      integer().nullable().references(RollImages, #id, onDelete: KeyAction.setNull)();

  IntColumn get createdAt => integer()();
}

/// Lo sviluppo di un rullino. ⚑ **Al massimo uno** per rullino (F6.7): `filmRollId` UNIQUE.
///
/// ⚑ Tabella separata e non colonne del rullino, come le stampe: il rullino puo' avere uno
/// sviluppo e tre ordini di stampa a mesi di distanza da laboratori diversi (F6.2).
class Developments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get filmRollId =>
      integer().unique().references(FilmRolls, #id, onDelete: KeyAction.cascade)();

  /// ⚑ Nullable, anche se F6.2 lo da' obbligatorio: lo sviluppo in casa non ha un
  /// laboratorio, e chi ha dimenticato il nome deve poter registrare lo stesso le date.
  TextColumn get laboratory => text().nullable().withLength(max: 80)();

  TextColumn get submittedAt => text().nullable().withLength(min: 10, max: 10)();

  TextColumn get returnedAt => text()
      .nullable()
      .withLength(min: 10, max: 10)
      .check(
        returnedAt.isNull() | submittedAt.isNull() | returnedAt.isBiggerOrEqual(submittedAt),
      )();

  IntColumn get developmentCostCents =>
      integer().nullable().check(developmentCostCents.isBiggerOrEqualValue(0))();

  IntColumn get scanCostCents =>
      integer().nullable().check(scanCostCents.isBiggerOrEqualValue(0))();

  /// `FilmProcess.key`; null se non indicato.
  TextColumn get process => text().nullable().check(process.isIn(filmProcessKeys))();

  BoolColumn get selfDeveloped => boolean().withDefault(const Constant(false))();

  TextColumn get note => text().nullable()();
}

/// Un ordine di stampa: **N** per rullino (F6.7).
@TableIndex(name: 'idx_print_orders_roll', columns: {#filmRollId})
class PrintOrders extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get filmRollId => integer().references(FilmRolls, #id, onDelete: KeyAction.cascade)();

  /// Nullable per la stessa ragione di `Developments.laboratory`.
  TextColumn get laboratory => text().nullable().withLength(max: 80)();

  TextColumn get submittedAt => text().nullable().withLength(min: 10, max: 10)();

  TextColumn get returnedAt => text()
      .nullable()
      .withLength(min: 10, max: 10)
      .check(
        returnedAt.isNull() | submittedAt.isNull() | returnedAt.isBiggerOrEqual(submittedAt),
      )();

  /// Testo libero: "10x15", "13x18 opaco".
  TextColumn get format => text().nullable().withLength(max: 40)();

  IntColumn get numberOfPrints => integer().nullable().check(numberOfPrints.isBiggerThanValue(0))();

  IntColumn get costCents => integer().nullable().check(costCents.isBiggerOrEqualValue(0))();

  TextColumn get note => text().nullable()();
}

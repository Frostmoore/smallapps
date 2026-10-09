// I vincoli `check(...)` di Drift citano la colonna dentro il suo stesso getter: e' la forma
// documentata da Drift, che legge la definizione senza mai eseguirla. Il lint la scambia per
// una ricorsione infinita.
// ignore_for_file: recursive_getters
import 'package:drift/drift.dart';

import '../domain/qr_content.dart';

/// Le tabelle di QR Me (develop_microapps.md F17.1.4): **una sola**, perche' cronologia e
/// preferiti sono lo stesso oggetto con un flag. Un QR della cronologia salvato nei preferiti
/// non si copia: cambia `is_favorite` e smette di essere potabile.
///
/// Istanti in millisecondi UTC (ADR-008), come in tutto il monorepo.

/// Le chiavi di `qr_codes.kind`: i nomi di [QrKind], dal dominio e non copiati qui.
/// ☠ Il CHECK entra nello schema alla creazione: una chiave nuova dopo il rilascio richiede una
/// migrazione che ricrei la tabella (SQLite non modifica i CHECK).
final List<String> qrKindKeys = [for (final k in QrKind.values) k.name];

/// Da dove e' arrivato un QR (`qr_codes.source`).
abstract final class QrSource {
  /// Dalla condivisione di un'altra app (Share Sheet).
  static const String shared = 'shared';

  /// Scritto o incollato nel campo della home.
  static const String typed = 'typed';

  /// Compilato in un modulo speciale (Pro).
  static const String form = 'form';

  /// Letto con la fotocamera.
  static const String scanned = 'scanned';

  /// Letto da un'immagine (galleria o immagine condivisa).
  static const String image = 'image';

  static const List<String> all = [shared, typed, form, scanned, image];
}

/// Un QR mostrato (cronologia) o salvato con nome (preferito).
///
/// ⚑ Niente UNIQUE su `payload`: due preferiti con lo stesso contenuto e stili diversi sono
/// legittimi (il Wi-Fi di casa in verde per la cucina e in nero per l'ingresso). I doppioni
/// **in cronologia** li evita `QrRepository.recordShown`.
@TableIndex.sql('CREATE INDEX idx_qr_codes_favorite_used ON qr_codes (is_favorite, last_used_at DESC)')
class QrCodes extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// `QrKind.name`.
  TextColumn get kind => text().check(kind.isIn(qrKindKeys))();

  /// La stringa **esatta** codificata nel QR (quella di `QrEncoder.encode`, o quella letta).
  /// ⚑ 4000 e non 2953: il limite del QR e' in byte UTF-8, questo in caratteri, ed e' solo un
  /// argine contro un dato assurdo. Il controllo vero e' `QrCapacity` prima di disegnare.
  TextColumn get payload => text().withLength(min: 1, max: 4000)();

  /// `QrContent.toFields()` in JSON, per riaprire il modulo; null per testo e link (il
  /// payload basta).
  TextColumn get fieldsJson => text().nullable()();

  /// `autoTitle` o il nome dato dall'utente.
  TextColumn get title => text().withLength(min: 1, max: 80)();

  /// Una delle chiavi di [QrSource].
  TextColumn get source => text().check(source.isIn(QrSource.all))();

  /// `QrStyle.toJson()` in JSON; null = `QrStyle.plain`.
  TextColumn get styleJson => text().nullable()();

  /// Preferito = salvato con nome, escluso dalla potatura della cronologia.
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();

  /// Aggiornato a ogni visualizzazione: ordina la cronologia.
  IntColumn get lastUsedAt => integer()();
}

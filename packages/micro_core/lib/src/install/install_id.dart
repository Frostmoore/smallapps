import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../util/micro_log.dart';

/// L'identità di un'installazione: un UUID generato al primo avvio.
///
/// ⚑ Perché non un account: le specifiche di tutte e quattro le app ripetono "nessun
/// login". Un'app che chiede la mail per usare il calendario dell'immondizia perde metà
/// degli utenti all'onboarding. Questo UUID dà tutto quello che serve, cioè associare un
/// acquisto a un dispositivo, senza raccogliere alcun dato personale.
class InstallId {
  const InstallId._(this.value);

  /// Costruttore per i test, con un valore fissato.
  factory InstallId.fixed(String value) => InstallId._(value);

  static const String _keyPrefix = 'micro_install_id';

  /// Opzioni Android esplicite anche se coincidono con i default.
  ///
  /// In `flutter_secure_storage` 11 il costruttore di default usa già AES-GCM con
  /// wrapping RSA-OAEP e `resetOnError: true`, che è esattamente il comportamento voluto:
  /// se il Keystore restituisce dati illeggibili, la libreria azzera invece di lanciare.
  /// Scriverle qui serve a rendere la scelta visibile, così un aggiornamento che cambiasse
  /// i default si nota in diff invece che in produzione.
  static const AndroidOptions _android = AndroidOptions(
    resetOnError: true,
    migrateOnAlgorithmChange: true,
  );

  static Future<InstallId> load({
    required String appId,
    FlutterSecureStorage storage = const FlutterSecureStorage(aOptions: _android),
  }) async {
    final key = '$_keyPrefix.$appId';

    try {
      final existing = await storage.read(key: key);
      if (existing != null && existing.length >= 32) return InstallId._(existing);
      final created = const Uuid().v4();
      await storage.write(key: key, value: created);
      return InstallId._(created);
    } on Exception catch (error, stack) {
      // ☠ Su Android `flutter_secure_storage` si appoggia al Keystore, che in casi rari
      // restituisce dati illeggibili: dopo un backup-and-restore del dispositivo, o dopo
      // un cambio del blocco schermo su certe ROM. Qui si rigenera e si prosegue.
      //
      // Cosa si perde: l'associazione con il License Server, quindi il ripristino
      // dell'acquisto passa da Play invece che dal nostro registro. Cosa NON si perde:
      // l'entitlement locale, che vive in un file suo (ADR-007). L'utente non se ne
      // accorge, e soprattutto l'app non crasha all'avvio per un problema di portachiavi.
      MicroLog.w('install id illeggibile, ne genero uno nuovo', error: error);
      MicroLog.d('stack install id', data: stack);
      final regenerated = const Uuid().v4();
      try {
        await storage.write(key: key, value: regenerated);
      } on Exception {
        // Se nemmeno la scrittura funziona, l'id vive solo per questa sessione: l'app
        // resta usabile e il Pro locale resta valido.
      }
      return InstallId._(regenerated);
    }
  }

  final String value;

  /// L'identificatore da passare a Google Play Billing.
  ///
  /// ⚑ Perché derivato e non l'UUID diretto: Google chiede che l'identificatore associato
  /// all'acquisto non sia un dato personale né ricostruibile. L'hash tronca il legame e
  /// resta stabile, il che permette comunque al server di correlare un acquisto Play a un
  /// `install_id` senza esporlo. Play limita il campo a 64 caratteri, che è esattamente la
  /// lunghezza di uno SHA-256 in esadecimale.
  String get obfuscatedAccountId => sha256.convert(utf8.encode(value)).toString();

  /// Forma breve per la UI, quando l'utente deve leggerla o dettarla al supporto.
  String get short => value.substring(0, 8).toUpperCase();

  @override
  bool operator ==(Object other) => other is InstallId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'InstallId($short…)';
}

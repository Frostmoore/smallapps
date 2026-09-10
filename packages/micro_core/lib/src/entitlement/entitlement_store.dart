import 'dart:convert';
import 'dart:io';

import '../storage/app_paths.dart';
import '../util/micro_log.dart';
import 'entitlement.dart';

/// Dove vive la verità sull'entitlement: un file JSON scritto in modo atomico.
///
/// ⚑ Perché un file e non `shared_preferences`: le preferenze si perdono con un
/// "cancella dati" e non sono atomiche. Qui serve la garanzia che il file o è intero o è
/// quello di prima, perché un file troncato significa che un utente pagante si ritrova
/// gratuito al riavvio.
class EntitlementStore {
  const EntitlementStore({required this.file});

  static Future<EntitlementStore> open({required AppPaths paths}) async {
    if (!paths.support.existsSync()) await paths.support.create(recursive: true);
    return EntitlementStore(file: paths.file(paths.support, 'entitlement.json'));
  }

  final File file;

  /// Lo stato salvato, oppure "gratuito" se non c'è o è illeggibile.
  ///
  /// ⚑ Un file corrotto degrada a gratuito **in lettura**, non in scrittura: alla prima
  /// occasione utile Play o il server rimetteranno le cose a posto. È l'unico caso in cui
  /// un utente pagante vede temporaneamente la versione gratuita, ed è preferibile a un
  /// crash all'avvio.
  Future<Entitlement> read(String appId) async {
    final raw = await AtomicFile.readStringOrNull(file);
    if (raw == null || raw.isEmpty) return Entitlement.free(appId);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return Entitlement.free(appId);
      final entitlement = Entitlement.fromJson(decoded);
      // Un file appartenente a un'altra app non vale: può succedere solo con un
      // ripristino di backup sbagliato, ma non deve concedere niente.
      if (entitlement.appId != appId) {
        MicroLog.w('entitlement di un\'altra app: ${entitlement.appId} invece di $appId');
        return Entitlement.free(appId);
      }
      return entitlement;
    } on FormatException catch (error) {
      MicroLog.w('entitlement.json illeggibile', error: error);
      return Entitlement.free(appId);
    } on ArgumentError catch (error) {
      // Uno stato o una fonte sconosciuti: file scritto da una versione più recente.
      MicroLog.w('entitlement.json con valori sconosciuti', error: error);
      return Entitlement.free(appId);
    }
  }

  Future<void> write(Entitlement entitlement) =>
      AtomicFile.writeString(file, jsonEncode(entitlement.toJson()));

  Future<void> clear() async {
    if (file.existsSync()) await file.delete();
  }
}

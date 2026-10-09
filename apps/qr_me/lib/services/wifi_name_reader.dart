import 'package:flutter/foundation.dart';
import 'package:micro_core/micro_core.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Il nome (SSID) della rete Wi-Fi a cui il telefono e' connesso, per il modulo Wi-Fi
/// (develop_microapps.md F17.10 punto 1, «La rete a cui sei connesso»).
///
/// ☠ **La password nessuna app la puo' leggere**, ne' su Android ne' su iOS: e' un limite dei
/// sistemi. Qui si legge solo il nome; la password l'utente la incolla.
///
/// Cosa serve per leggere il nome:
/// - **Android** (10+): il permesso di posizione **precisa** (`ACCESS_FINE_LOCATION`, dichiarato
///   nel manifest) **e** la localizzazione accesa. Con la posizione «approssimativa» il sistema
///   risponde `<unknown ssid>`.
/// - **iOS**: l'entitlement `com.apple.developer.networking.wifi-info` (capability «Access Wi-Fi
///   Information» sull'App ID) **e** l'autorizzazione alla posizione «mentre usi l'app»
///   (`NSLocationWhenInUseUsageDescription` in Info.plist). Sul simulatore il nome non c'e' mai.
///
/// ⚑ Il permesso si chiede **solo quando si tocca il bottone**, dopo una spiegazione dell'app
/// ([needsPermission] dice se mostrarla): chiederlo all'avvio, senza contesto, fa dire di no.
///
/// ⚑ Pacchetti (F17.10, controllati il 2026-10-09 nel sorgente in pub cache: nessun SDK di
/// analytics, telemetria o Firebase, nessuna chiamata di rete): `network_info_plus` (Android
/// `WifiManager.connectionInfo`, iOS `NEHotspotNetwork.fetchCurrent`) e `permission_handler`.
///
/// Un'interfaccia perche' sotto `flutter test` non c'e' nessun plugin: i test di widget usano
/// un doppio finto ([wifiNameReaderProvider] in lib/app/providers.dart).
abstract interface class WifiNameReader {
  /// `true` se per leggere il nome bisogna ancora chiedere il permesso (e quindi spiegare
  /// prima perche'). `false` se e' gia' concesso, o negato per sempre (il dialogo del sistema
  /// non comparirebbe comunque).
  Future<bool> needsPermission();

  /// Chiede il permesso se serve, poi legge il nome. Non lancia mai.
  Future<WifiNameLookup> lookup();
}

/// Come e' andata la lettura del nome della rete.
enum WifiNameStatus {
  /// Letto: [WifiNameLookup.ssid] c'e'.
  found,

  /// Permesso di posizione negato (si puo' richiedere).
  denied,

  /// Negato per sempre (o limitato): solo le impostazioni dell'app lo riaccendono.
  deniedForever,

  /// La localizzazione del telefono e' spenta (Android: senza, l'SSID non si legge).
  locationOff,

  /// Nessun nome: non connesso a un Wi-Fi, posizione solo approssimativa, simulatore, o un
  /// errore del sistema.
  unavailable,
}

/// L'esito di [WifiNameReader.lookup].
@immutable
final class WifiNameLookup {
  const WifiNameLookup(this.status, [this.ssid]);

  const WifiNameLookup.found(String this.ssid) : status = WifiNameStatus.found;

  final WifiNameStatus status;

  /// Il nome della rete, solo con [WifiNameStatus.found].
  final String? ssid;

  @override
  bool operator ==(Object other) =>
      other is WifiNameLookup && other.status == status && other.ssid == ssid;

  @override
  int get hashCode => Object.hash(status, ssid);

  @override
  String toString() => 'WifiNameLookup($status, $ssid)';
}

/// Il nome della rete come arriva dal sistema, ripulito; null se non e' un nome vero.
///
/// ☠ Android lo restituisce **tra virgolette** (`"Casa"`) quando e' un testo UTF-8, e senza
/// virgolette quando e' una sequenza esadecimale; senza permesso o senza Wi-Fi risponde
/// `<unknown ssid>`. Con le virgolette dentro, il QR avrebbe un nome di rete sbagliato e non si
/// connetterebbe. ⚑ Nessun trim: uno spazio puo' far parte del nome.
String? cleanSsid(String? raw) {
  if (raw == null) return null;
  var s = raw;
  if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) s = s.substring(1, s.length - 1);
  if (s.isEmpty || s == '<unknown ssid>' || s == '0x') return null;
  return s;
}

/// L'implementazione vera: `permission_handler` per il permesso, `network_info_plus` per il nome.
class PluginWifiNameReader implements WifiNameReader {
  const PluginWifiNameReader();

  /// ⚑ `locationWhenInUse` e non `location`: su iOS basta «mentre usi l'app» (e chiedere
  /// «sempre» sarebbe ingiustificabile); su Android i due sono lo stesso gruppo e il plugin
  /// chiede insieme posizione precisa e approssimativa, come vuole Android 12.
  static const PermissionWithService _permission = Permission.locationWhenInUse;

  @override
  Future<bool> needsPermission() async {
    try {
      final status = await _permission.status;
      return !(status.isGranted || status.isLimited || status.isPermanentlyDenied);
    } on Object catch (error, stack) {
      MicroLog.e('permesso posizione: stato illeggibile', error: error, stackTrace: stack);
      return true;
    }
  }

  @override
  Future<WifiNameLookup> lookup() async {
    try {
      var status = await _permission.status;
      if (!status.isGranted && !status.isLimited) status = await _permission.request();
      if (status.isPermanentlyDenied || status.isRestricted) {
        return const WifiNameLookup(WifiNameStatus.deniedForever);
      }
      if (!status.isGranted && !status.isLimited) {
        return const WifiNameLookup(WifiNameStatus.denied);
      }
      // ⚑ Su Android, senza localizzazione accesa il sistema da' `<unknown ssid>` anche con il
      // permesso: lo si dice prima, con un messaggio che spiega cosa fare.
      if (defaultTargetPlatform == TargetPlatform.android &&
          await _permission.serviceStatus == ServiceStatus.disabled) {
        return const WifiNameLookup(WifiNameStatus.locationOff);
      }
      final ssid = cleanSsid(await NetworkInfo().getWifiName());
      return ssid == null
          ? const WifiNameLookup(WifiNameStatus.unavailable)
          : WifiNameLookup.found(ssid);
    } on Object catch (error, stack) {
      MicroLog.e('nome della rete Wi-Fi non letto', error: error, stackTrace: stack);
      return const WifiNameLookup(WifiNameStatus.unavailable);
    }
  }
}

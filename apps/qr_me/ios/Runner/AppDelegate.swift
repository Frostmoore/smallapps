import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ⚑ Prima di avviare Flutter: il database si apre (pigramente) dal lato Dart, e tutto cio'
    // che scrive deve trovare la cartella gia' esclusa dal backup.
    excludeUserDataFromBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  /// Toglie dal backup automatico di iCloud (e da quello sul computer) i dati di QR Me
  /// (develop_microapps.md F17.1.4).
  ///
  /// ⚑ Perche': nel database ci sono password del Wi-Fi e testi privati. Il backup
  /// automatico li porterebbe su iCloud senza che l'utente l'abbia scelto; il backup lo fa
  /// solo lui, col Pro, in un file che vede. E' l'equivalente di `allowBackup="false"` nel
  /// manifest Android.
  ///
  /// Dove scrive il lato Dart (tutto sotto `Documents/` dell'app, cioe'
  /// `getApplicationDocumentsDirectory()` di path_provider = `NSDocumentDirectory`):
  /// - `Documents/qr_me.sqlite` (+ `-wal`, `-shm`, `-journal` di SQLite) — `QrDatabase.open()`;
  /// - `Documents/qr_me/images/...` — i loghi foto (`AppPaths.documents` + `ImageStore`).
  /// `Library/Application Support/qr_me/` (entitlement, log) resta nel backup: non contiene
  /// contenuti dell'utente, e l'entitlement salvato aiuta dopo un cambio di telefono.
  ///
  /// ⚑ Si esclude **la cartella `Documents/` intera**, non solo i file: l'attributo sta
  /// sul singolo file, e SQLite (journal e WAL) e le scritture atomiche (file temporaneo +
  /// rinomina) creano file nuovi che non lo erediterebbero. Una cartella esclusa esclude tutto
  /// cio' che contiene, anche i file creati dopo. I file noti si marcano comunque, per scrupolo.
  /// ⚑ Si rifa' a ogni avvio: costa pochissimo e ripara un attributo perso (ripristino del
  /// dispositivo, migrazione). `Documents/` contiene solo dati di QR Me (la sandbox e'
  /// dell'app), quindi escluderla intera non toglie niente di altrui.
  /// ☠ Un errore non deve impedire l'avvio: si scrive nel log di sistema e si prosegue.
  private func excludeUserDataFromBackup() {
    let fileManager = FileManager.default
    guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    else { return }

    var targets: [URL] = [
      documents,
      documents.appendingPathComponent("qr_me", isDirectory: true),
    ]
    for suffix in ["", "-wal", "-shm", "-journal"] {
      targets.append(documents.appendingPathComponent("qr_me.sqlite" + suffix, isDirectory: false))
    }

    for target in targets where fileManager.fileExists(atPath: target.path) {
      var url = target
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try url.setResourceValues(values)
      } catch {
        NSLog("QR Me: esclusione dal backup non riuscita per %@: %@", url.path, "\(error)")
      }
    }
  }
}

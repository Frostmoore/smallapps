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

  /// Toglie dal backup automatico di iCloud (e da quello sul computer) i dati di Spending Review
  /// (develop_microapps.md F12.1.15). Copia di quella di QR Me (F17.7.3).
  ///
  /// ⚑ Perche': nel database c'e' la cronologia della spesa (dove e quando si compra, quanto si
  /// spende). Il backup automatico la porterebbe su iCloud senza che l'utente l'abbia scelto
  /// (regola «dati solo sul telefono»); il backup lo fa solo lui, col Pro, in un file che vede.
  /// E' l'equivalente di `allowBackup="false"` nel manifest Android.
  ///
  /// Dove scrive il lato Dart (sotto `Documents/` dell'app, cioe'
  /// `getApplicationDocumentsDirectory()` di path_provider = `NSDocumentDirectory`):
  /// - `Documents/spending_review.sqlite` (+ `-wal`, `-shm`, `-journal`) — `SpendingDatabase.open()`;
  /// - `Documents/spending_review/...` — le cartelle di `AppPaths` (nessuna foto: le foto dei
  ///   cartellini e degli scontrini stanno nella cartella temporanea e si cancellano dopo la
  ///   lettura, F12.1.13).
  ///
  /// ⚑ Si esclude **la cartella `Documents/` intera**, non solo i file: SQLite (journal e WAL)
  /// crea file nuovi che non erediterebbero l'attributo; una cartella esclusa esclude tutto cio'
  /// che contiene, anche i file creati dopo. Si rifa' a ogni avvio (costa pochissimo e ripara un
  /// attributo perso). ☠ Un errore non deve impedire l'avvio: si scrive nel log e si prosegue.
  private func excludeUserDataFromBackup() {
    let fileManager = FileManager.default
    guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    else { return }

    var targets: [URL] = [
      documents,
      documents.appendingPathComponent("spending_review", isDirectory: true),
    ]
    for suffix in ["", "-wal", "-shm", "-journal"] {
      targets.append(
        documents.appendingPathComponent("spending_review.sqlite" + suffix, isDirectory: false))
    }

    for target in targets where fileManager.fileExists(atPath: target.path) {
      var url = target
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try url.setResourceValues(values)
      } catch {
        NSLog("Spending Review: esclusione dal backup non riuscita per %@: %@", url.path, "\(error)")
      }
    }
  }
}

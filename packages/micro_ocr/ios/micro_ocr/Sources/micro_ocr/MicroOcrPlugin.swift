import Flutter
import UIKit

/// Canale "micro_ocr" su iOS: `nome`, `prepara`, `leggi` {percorso, modo}, `rilascia`.
///
/// ⚑ Lo stesso canale e le stesse mappe di Android (MicroOcrPlugin.kt): l'app Dart non sa
/// quale motore c'e' sotto. Qui il motore e' Vision, di sistema: niente da caricare ne' da
/// liberare, quindi `prepara` e `rilascia` non fanno nulla.
/// Ogni errore torna come FlutterError code "non_disponibile" → OcrNonDisponibile in Dart.
public class MicroOcrPlugin: NSObject, FlutterPlugin {
  /// Una sola coda seriale: le letture si mettono in fila, mai sul thread principale.
  private let coda = DispatchQueue(label: "micro_ocr", qos: .userInitiated)

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "micro_ocr", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(MicroOcrPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "nome":
      result(VisionOcr.nome)
    case "prepara", "rilascia":
      result(nil)
    case "leggi":
      let argomenti = call.arguments as? [String: Any]
      guard let percorso = argomenti?["percorso"] as? String, !percorso.isEmpty else {
        result(FlutterError(code: "non_disponibile", message: "percorso mancante", details: nil))
        return
      }
      let modo = (argomenti?["modo"] as? String) ?? "cartellino"
      coda.async {
        do {
          let righe = try VisionOcr.leggi(percorso: percorso, modo: modo)
          DispatchQueue.main.async { result(righe) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "non_disponibile", message: "\(error)", details: nil))
          }
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

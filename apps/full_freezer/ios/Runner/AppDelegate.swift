import Flutter
import Speech
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Tenuto qui perche' viva quanto l'app.
  private var voiceChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "full_freezer/voice", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "onDeviceAvailable":
        let args = call.arguments as? [String: Any]
        let localeId = args?["localeId"] as? String ?? "en_US"
        result(AppDelegate.onDeviceRecognitionAvailable(localeId: localeId))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    voiceChannel = channel
  }

  /// La dettatura e' solo sul telefono (regola "dati solo sul telefono", 2026-10-10).
  ///
  /// ☠ speech_to_text 7.5.0 con `onDevice: true` su un riconoscitore senza modello locale
  /// risponde `onDeviceError` ma non esce dal metodo e risponde una seconda volta al canale.
  /// Per non arrivarci, l'app chiede prima: se qui e' falso, Dart non chiama mai `listen`.
  ///
  /// ⚑ Per lingua: un iPad puo' avere il modello dell'inglese e non quello dell'italiano.
  /// Non chiede permessi: si chiama all'apertura del foglio.
  static func onDeviceRecognitionAvailable(localeId: String) -> Bool {
    // Il target minimo e' iOS 15: `supportsOnDeviceRecognition` (iOS 13) c'e' sempre.
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId)) else {
      return false
    }
    return recognizer.supportsOnDeviceRecognition
  }
}

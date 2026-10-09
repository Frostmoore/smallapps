import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:micro_core/micro_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Apre la pagina delle impostazioni **di QR Me** nel sistema, dove si riaccende la fotocamera
/// negata (develop_microapps.md F17.1.6, schermata di lettura).
///
/// - **iOS**: lo schema `app-settings:` con `url_launcher` (documentato da Apple).
/// - **Android**: un `MethodChannel` nostro ([channel], metodo `open`) che in `MainActivity.kt`
///   lancia `Settings.ACTION_APPLICATION_DETAILS_SETTINGS` con `package:com.smp.qrme`.
///
/// ⚑ Un canale scritto da noi e non `permission_handler` o `app_settings`: un solo pulsante non
/// vale una dipendenza in piu' (e un SDK in piu' da dichiarare nella scheda dello store). Android
/// non ha uno schema URL standard per «le impostazioni di quest'app», quindi `url_launcher` da
/// solo non basta: serve l'Intent, e l'Intent si lancia solo dal lato nativo.
///
/// ☠ Senza questo, su Android un permesso negato **per sempre** (due rifiuti, o «Non chiedere
/// piu'») lasciava solo «Riprova», che richiede il permesso al sistema; il sistema non mostra
/// piu' il dialogo e si tornava allo stesso stato vuoto, senza via d'uscita dall'app.
///
/// ⚑ [open] non lancia mai: `false` se la pagina non si apre (piattaforma senza supporto, canale
/// assente nei test, Intent rifiutato). Una classe concreta: i test la sostituiscono con una
/// sottoclasse o le iniettano [launcher] e [platform].
class AppSettings {
  const AppSettings({this._launcher, this._platform});

  final Future<bool> Function(Uri uri)? _launcher;
  final TargetPlatform? _platform;

  /// Il canale verso `MainActivity.kt`. ⚑ Il nome deve restare identico a `SETTINGS_CHANNEL`
  /// in android/app/src/main/kotlin/com/smp/qrme/MainActivity.kt.
  static const MethodChannel channel = MethodChannel('com.smp.qrme/app_settings');

  /// Apre le impostazioni dell'app; `true` se il sistema ha accettato.
  Future<bool> open() async {
    try {
      switch (_platform ?? defaultTargetPlatform) {
        case TargetPlatform.iOS:
          final uri = Uri.parse('app-settings:');
          final launcher = _launcher;
          return launcher != null ? await launcher(uri) : await launchUrl(uri);
        case TargetPlatform.android:
          return await channel.invokeMethod<bool>('open') ?? false;
        case _:
          return false;
      }
    } on Object catch (error, stack) {
      MicroLog.e('impostazioni dell\'app non aperte', error: error, stackTrace: stack);
      return false;
    }
  }
}

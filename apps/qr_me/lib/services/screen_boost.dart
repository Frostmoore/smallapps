import 'package:micro_core/micro_core.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Luminosita' al massimo e schermo acceso mentre il QR e' mostrato, con ripristino
/// (develop_microapps.md F17.1.7).
///
/// ⚑ Luminosita' **dell'app** (`setApplicationScreenBrightness`) e non di sistema: nessun
/// permesso, e se l'app muore il sistema torna da solo alla luminosita' dell'utente.
///
/// ⚑ **Errori ingoiati e loggati**: un telefono che non permette di cambiare la luminosita' (o
/// un plugin che fallisce) deve comunque mostrare il QR. Per questo [enable] e [disable] non
/// lanciano mai.
///
/// Una classe concreta e non un'interfaccia: i test la sostituiscono con una sottoclasse
/// (`implements`) che conta le chiamate.
class ScreenBoost {
  const ScreenBoost();

  Future<void> enable() async {
    await _quiet(
      'luminosita\' al massimo',
      () => ScreenBrightness.instance.setApplicationScreenBrightness(1),
    );
    await _quiet('schermo sempre acceso', WakelockPlus.enable);
  }

  Future<void> disable() async {
    await _quiet(
      'luminosita\' ripristinata',
      ScreenBrightness.instance.resetApplicationScreenBrightness,
    );
    await _quiet('schermo libero di spegnersi', WakelockPlus.disable);
  }

  static Future<void> _quiet(String what, Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error, stack) {
      MicroLog.e('ScreenBoost: $what non riuscito', error: error, stackTrace: stack);
    }
  }
}

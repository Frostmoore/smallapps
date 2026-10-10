import 'package:flutter/services.dart';
import 'package:micro_core/micro_core.dart';

/// Apre la pagina delle impostazioni **di Spending Review** nel sistema, dove si riaccende la
/// fotocamera negata (develop_microapps.md F12.1.12, `CartellinoCameraPage`: «La fotocamera e'
/// spenta» + «Apri le impostazioni»).
///
/// ⚑ Un `MethodChannel` nostro su **entrambe** le piattaforme (Android: `MainActivity.kt` con
/// `Settings.ACTION_APPLICATION_DETAILS_SETTINGS`; iOS: `AppDelegate.swift` con
/// `UIApplication.openSettingsURLString`) e non `url_launcher` + canale come QR Me: qui
/// `url_launcher` non c'e', e un pulsante non vale una dipendenza in piu' (ne' un SDK in piu' da
/// dichiarare). Ne' `permission_handler` (F12.1.2: non si usa).
///
/// ☠ Senza, un permesso negato **per sempre** (due rifiuti su Android, uno su iOS) lascerebbe solo
/// «Riprova», che il sistema ignora: nessuna via d'uscita dall'app (lezione di QR Me).
/// ⚑ [apri] non lancia mai: `false` se la pagina non si apre (canale assente nei test, piattaforma
/// senza supporto).
class ImpostazioniSistema {
  const ImpostazioniSistema();

  /// ⚑ Identico a `CANALE_IMPOSTAZIONI` in MainActivity.kt e a `canaleImpostazioni` in
  /// AppDelegate.swift.
  static const MethodChannel canale = MethodChannel('com.smp.spendingreview/impostazioni');

  Future<bool> apri() async {
    try {
      return await canale.invokeMethod<bool>('apri') ?? false;
    } on Object catch (error, stack) {
      MicroLog.e("impostazioni dell'app non aperte", error: error, stackTrace: stack);
      return false;
    }
  }
}

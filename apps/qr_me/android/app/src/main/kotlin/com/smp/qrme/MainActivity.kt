package com.smp.qrme

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /**
     * ☠ Con `launchMode="singleTask"` una condivisione che arriva con l'app gia' aperta (o
     * chiusa ma ancora nei recenti) non ricrea l'attivita': Android consegna l'intent nuovo con
     * `onNewIntent` e `getIntent()` resterebbe quello vecchio del launcher. Rimpiazzarlo fa
     * leggere quello giusto a chi lo cerca (il plugin di condivisione di micro_share, F17.2b).
     * Stessa riga di Film Tracker, pagata con il widget di Full Freezer (2026-10-07).
     */
    override fun onNewIntent(intent: Intent) {
        setIntent(intent)
        super.onNewIntent(intent)
    }

    /**
     * «Apri le impostazioni» dalla lettura con la fotocamera negata (lib/services/app_settings.dart).
     *
     * ⚑ Codice nostro e non un plugin (`permission_handler`, `app_settings`): un solo Intent non
     * vale una dipendenza. Android non ha uno schema URL per «le impostazioni di quest'app»,
     * quindi serve l'Intent `ACTION_APPLICATION_DETAILS_SETTINGS` con `package:<id>`.
     * ☠ Risponde sempre (true/false), mai un errore: il lato Dart mostra lo stato vuoto lo stesso.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    startActivity(
                        Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", packageName, null),
                        ),
                    )
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }
    }

    private companion object {
        /** ⚑ Identico a `AppSettings.channel` in lib/services/app_settings.dart. */
        const val SETTINGS_CHANNEL = "com.smp.qrme/app_settings"
    }
}

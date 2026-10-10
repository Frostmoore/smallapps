package com.smp.spendingreview

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * L'attivita' di Spending Review. L'OCR vive nel plugin `micro_ocr` (F12.1.9), che si registra da
 * solo; qui c'e' solo il canale «Apri le impostazioni» della fotocamera negata
 * (lib/services/impostazioni_sistema.dart, F12.1.12).
 *
 * ⚑ Codice nostro e non un plugin (`permission_handler`, `app_settings`): un solo Intent non vale
 * una dipendenza. Android non ha uno schema URL per «le impostazioni di quest'app», quindi serve
 * l'Intent `ACTION_APPLICATION_DETAILS_SETTINGS` con `package:<id>` (come QR Me).
 * ☠ Risponde sempre (true/false), mai un errore: il lato Dart mostra lo stato vuoto lo stesso.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANALE_IMPOSTAZIONI)
            .setMethodCallHandler { call, result ->
                if (call.method != "apri") {
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
        /** ⚑ Identico a `ImpostazioniSistema.canale` in lib/services/impostazioni_sistema.dart. */
        const val CANALE_IMPOSTAZIONI = "com.smp.spendingreview/impostazioni"
    }
}

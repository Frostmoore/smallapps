package com.smp.fullfreezer

import android.content.Intent
import android.os.Build
import android.speech.SpeechRecognizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "full_freezer/voice")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "onDeviceAvailable" -> result.success(onDeviceRecognitionAvailable())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * La dettatura e' solo sul telefono (regola "dati solo sul telefono", 2026-10-10).
     *
     * ☠ speech_to_text 7.5.0, con `onDevice: true`, crea il riconoscitore sul telefono solo
     * se questo stesso controllo e' vero; altrimenti crea **in silenzio** quello normale, che
     * manda l'audio ai server di Google. Per questo la domanda la fa l'app, prima di
     * ascoltare: se qui e' falso, Dart non chiama mai `listen`.
     *
     * Sotto API 31 il riconoscitore sul telefono non esiste come API pubblica: falso.
     * La lingua non si controlla qui (servirebbe `checkRecognitionSupport`, API 33): se il
     * modello della lingua manca, il riconoscitore risponde `ERROR_LANGUAGE_UNAVAILABLE` e
     * Dart lo spiega all'utente.
     */
    private fun onDeviceRecognitionAvailable(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            SpeechRecognizer.isOnDeviceRecognitionAvailable(this)

    /**
     * ☠ Il tocco sul widget con l'app chiusa ma ancora nei recenti (visto sull'emulatore il
     * 2026-10-07): Android ricrea l'attivita' con l'intent **vecchio** del launcher e consegna
     * quello del widget con `onNewIntent`, prima che Dart abbia aperto lo stream del plugin.
     * Il plugin lo inoltra a nessuno, e `initiallyLaunchedFromHomeWidget` legge l'intent
     * vecchio: l'app si apriva sulla home invece che su "Da usare prima".
     *
     * Rimpiazzare l'intent dell'attivita' fa leggere a `initiallyLaunchedFromHomeWidget`
     * quello giusto. Con l'app gia' aperta lo stream lo riceve comunque, come prima.
     */
    override fun onNewIntent(intent: Intent) {
        setIntent(intent)
        super.onNewIntent(intent)
    }
}

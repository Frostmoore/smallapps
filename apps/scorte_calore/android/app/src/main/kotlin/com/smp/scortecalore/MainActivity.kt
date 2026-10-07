package com.smp.scortecalore

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    /**
     * ☠ Il tocco sul widget con l'app chiusa ma ancora nei recenti (visto sull'emulatore il
     * 2026-10-07): Android ricrea l'attivita' con l'intent **vecchio** del launcher e consegna
     * quello del widget con `onNewIntent`, prima che Dart abbia aperto lo stream del plugin.
     * Il plugin lo inoltra a nessuno, e `initiallyLaunchedFromHomeWidget` legge l'intent
     * vecchio: l'app si apriva sulla home invece che su la pagina giusta.
     *
     * Rimpiazzare l'intent dell'attivita' fa leggere a `initiallyLaunchedFromHomeWidget`
     * quello giusto. Con l'app gia' aperta lo stream lo riceve comunque, come prima.
     */
    override fun onNewIntent(intent: Intent) {
        setIntent(intent)
        super.onNewIntent(intent)
    }
}

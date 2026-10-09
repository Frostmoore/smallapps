package com.smp.qrme

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

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
}

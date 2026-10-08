package com.smp.filmtracker

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    /**
     * ☠ Un link aperto con l'app chiusa ma ancora nei recenti (visto con il widget di Full
     * Freezer, 2026-10-07): Android ricrea l'attivita' con l'intent **vecchio** del launcher e
     * consegna quello nuovo con `onNewIntent`. Rimpiazzarlo fa leggere quello giusto a chi lo
     * cerca all'avvio. Servira' al QR del rullino (F6.12).
     */
    override fun onNewIntent(intent: Intent) {
        setIntent(intent)
        super.onNewIntent(intent)
    }
}

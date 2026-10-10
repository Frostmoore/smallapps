package com.smp.micro_ocr

import kotlin.math.max
import kotlin.math.min

/**
 * Scontrini lunghi: il rilevatore lavora su fasce orizzontali sovrapposte invece che
 * sull'immagine intera.
 *
 * ⚑ Perche': uno scontrino 1 : 5 ridotto tutto insieme lascerebbe righe di 3-4 px che il
 * rilevatore non vede. A fasce, ogni pezzo e' circa quadrato e conserva la risoluzione.
 * La sovrapposizione garantisce che ogni riga stia INTERA in almeno una fascia; i doppioni
 * (la stessa riga vista da due fasce) li toglie [unisci].
 */
object Strisce {

    /**
     * Fasce alte ≈ [larghezza], sovrapposte di [sovrapposizione], che coprono tutta l'altezza;
     * l'ultima e' allineata al fondo. Un'immagine non piu' alta che larga e' una fascia sola.
     */
    fun tagli(larghezza: Int, altezza: Int, sovrapposizione: Float = 0.15f): List<IntRange> {
        require(larghezza > 0 && altezza > 0)
        val alta = max(1, larghezza)
        if (altezza <= alta) return listOf(0 until altezza)
        val passo = max(1, (alta * (1 - sovrapposizione)).toInt())
        val out = ArrayList<IntRange>()
        var inizio = 0
        while (inizio + alta < altezza) {
            out.add(inizio until inizio + alta)
            inizio += passo
        }
        out.add(altezza - alta until altezza)
        return out
    }

    /**
     * Toglie i doppioni delle sovrapposizioni: due quadrilateri i cui rettangoli contenitori si
     * intersecano per almeno [soglia] del PIU' PICCOLO sono la stessa riga, e resta il piu' grande.
     *
     * ⚑ Intersezione sul piu' piccolo e non IoU (come la specsheet diceva): al bordo di una fascia
     * la riga puo' uscire tagliata (meta' altezza) e l'IoU con quella intera resterebbe sotto 0,5
     * pur essendo un doppione evidente.
     */
    fun unisci(riquadri: List<Quadrilatero>, soglia: Float = 0.5f): List<Quadrilatero> {
        val ordinati = riquadri.sortedByDescending { it.contenitore().area }
        val tenuti = ArrayList<Quadrilatero>()
        for (q in ordinati) {
            val r = q.contenitore()
            if (tenuti.none { contenimento(it.contenitore(), r) >= soglia }) tenuti.add(q)
        }
        return tenuti
    }

    internal fun contenimento(a: Rettangolo, b: Rettangolo): Float {
        val iw = min(a.destra, b.destra) - max(a.sinistra, b.sinistra)
        val ih = min(a.basso, b.basso) - max(a.alto, b.alto)
        if (iw <= 0 || ih <= 0) return 0f
        val minore = min(a.area, b.area)
        return if (minore <= 0) 0f else (iw.toLong() * ih).toFloat() / minore
    }
}

package com.smp.micro_ocr

/**
 * Decodifica CTC dell'uscita del riconoscitore (`CTCLabelDecode` di RapidOCR).
 *
 * Classi: indice **0 = blank**, poi `dizionario[i − 1]`, l'ultima classe e' lo **spazio**
 * (RapidOCR la aggiunge in coda al dizionario). ☠ Un dizionario spostato di una posizione da'
 * testo plausibile ma sbagliato: per questo PpOcrEngine.prepara() verifica che le classi del
 * modello siano esattamente `dizionario.size + 2` (F12.1.16 trappola 4).
 */
class CtcDecoder(private val dizionario: List<String>) {

    /** Il numero di classi che il modello deve avere con questo dizionario. */
    val classi: Int get() = dizionario.size + 2

    /**
     * @param uscita probabilita' `[passi · classi]` (softmax per passo) a partire da [inizio].
     * @return testo e confidenza = media delle probabilita' dei caratteri tenuti (0 se nessuno).
     */
    fun decodifica(uscita: FloatArray, passi: Int, classi: Int, inizio: Int = 0): Pair<String, Float> {
        require(classi == this.classi) { "classi del modello $classi != dizionario ${dizionario.size} + 2" }
        val sb = StringBuilder()
        var somma = 0.0
        var tenuti = 0
        var precedente = -1
        for (t in 0 until passi) {
            val base = inizio + t * classi
            var migliore = 0
            var p = uscita[base]
            for (c in 1 until classi) {
                if (uscita[base + c] > p) { p = uscita[base + c]; migliore = c }
            }
            // Ripetizioni fuse (stesso indice del passo prima) e blank tolti.
            if (migliore != 0 && migliore != precedente) {
                sb.append(if (migliore == classi - 1) " " else dizionario[migliore - 1])
                somma += p
                tenuti++
            }
            precedente = migliore
        }
        return Pair(sb.toString(), if (tenuti == 0) 0f else (somma / tenuti).toFloat())
    }
}

package com.smp.micro_ocr

import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

/**
 * Tensori d'ingresso del rilevatore e del riconoscitore, con i parametri di RapidOCR 3.10
 * (il banco che ha dato le misure di f12-ocr.md §7, letti nel suo `config.yaml` il 2026-10-10).
 *
 * ☠ Canali in ordine **BGR**: RapidOCR carica le immagini con OpenCV (BGR) e i modelli
 * PP-OCR sono addestrati cosi'. RGB non da' errori: legge un po' peggio, in silenzio.
 * ⚑ Normalizzazione 0,5/0,5 anche per il rilevatore (config.yaml `Det.mean/std`), NON
 * quella ImageNet che la specsheet ipotizzava: vince cio' che il banco ha davvero usato.
 */
object Preprocess {
    /** `Det.limit_side_len` con `limit_type: min`: il lato CORTO portato almeno a 736. */
    const val LATO_MIN_DET = 736
    const val ALTEZZA_REC = 48
    /** `rec_img_shape` [3, 48, 320]: la larghezza minima del tensore del riconoscitore. */
    const val LARGHEZZA_BASE_REC = 320

    /**
     * Dimensioni dell'ingresso del rilevatore: se il lato corto e' sotto [latoMin] si
     * ingrandisce (stesso rapporto), poi ogni lato al multiplo di 32 piu' vicino, ≥ 32.
     */
    fun dimensioniDet(w: Int, h: Int, latoMin: Int = LATO_MIN_DET): Pair<Int, Int> {
        val r = if (min(w, h) < latoMin) latoMin.toDouble() / min(w, h) else 1.0
        return Pair(Immagine.multiplo32((w * r).toInt()), Immagine.multiplo32((h * r).toInt()))
    }

    /** Tensore `[1, 3, H, W]` (CHW, BGR) di un'immagine gia' alle dimensioni del rilevatore. */
    fun tensoreDet(img: ImmagineRgb): FloatArray {
        val n = img.larghezza * img.altezza
        val out = FloatArray(3 * n)
        for (i in 0 until n) {
            val p = img.pixel[i]
            out[i] = norm(p and 0xFF)                    // B
            out[n + i] = norm((p shr 8) and 0xFF)        // G
            out[2 * n + i] = norm((p shr 16) and 0xFF)   // R
        }
        return out
    }

    /**
     * Larghezza del tensore per un lotto di ritagli: `int(48 · max(320/48, rapporti))`, come
     * RapidOCR (tutti i ritagli del lotto sono riempiti fino alla stessa larghezza).
     */
    fun larghezzaLotto(ritagli: List<ImmagineRgb>, larghezzaMax: Int = 3200): Int {
        var rapporto = LARGHEZZA_BASE_REC.toDouble() / ALTEZZA_REC
        for (c in ritagli) rapporto = max(rapporto, c.larghezza.toDouble() / c.altezza)
        return min(larghezzaMax, (ALTEZZA_REC * rapporto).toInt())
    }

    /**
     * Un ritaglio portato ad altezza 48 mantenendo il rapporto (larghezza ≤ [larghezza]),
     * `(px/255 − 0,5)/0,5`, CHW BGR, riempito a destra con 0 fino a [larghezza].
     * Restituisce il tensore `[3, 48, larghezza]` e la larghezza utile.
     */
    fun tensoreRec(crop: ImmagineRgb, larghezza: Int): Pair<FloatArray, Int> {
        val h = ALTEZZA_REC
        val utile = min(larghezza, ceil(h * crop.larghezza.toDouble() / crop.altezza).toInt()).coerceAtLeast(1)
        val r = Immagine.ridimensiona(crop, utile, h)
        val piano = h * larghezza
        val out = FloatArray(3 * piano)          // 0 = grigio medio dopo la normalizzazione
        for (y in 0 until h) for (x in 0 until utile) {
            val p = r.pixel[y * utile + x]
            val i = y * larghezza + x
            out[i] = norm(p and 0xFF)
            out[piano + i] = norm((p shr 8) and 0xFF)
            out[2 * piano + i] = norm((p shr 16) and 0xFF)
        }
        return Pair(out, utile)
    }

    private fun norm(v: Int): Float = (v / 255f - 0.5f) / 0.5f
}

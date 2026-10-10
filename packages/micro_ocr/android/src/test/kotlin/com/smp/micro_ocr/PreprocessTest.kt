package com.smp.micro_ocr

import kotlin.test.Test
import kotlin.test.assertEquals

class PreprocessTest {
    @Test fun `dimensioni del rilevatore - multipli di 32 e rapporto conservato`() {
        // Lato corto 1504 ≥ 736: niente ingrandimento.
        assertEquals(Pair(1984, 1504), Preprocess.dimensioniDet(1984, 1504))
        // Lato corto 400 → 736: 400×1000 → 736×1840 → 1840/32 = 57,5 → 58 (al pari) → 1856.
        assertEquals(Pair(736, 1856), Preprocess.dimensioniDet(400, 1000))
        // Arrotondamento al pari come round() di Python: 1000/32 = 31,25 → 992; 1020/32 = 31,875 → 1024.
        assertEquals(Pair(992, 1024), Preprocess.dimensioniDet(1000, 1020))
        assertEquals(64, Immagine.multiplo32(48))   // 1,5 → 2 (pari)
        assertEquals(32, Immagine.multiplo32(16))   // 0,5 → 0 (pari), ma mai sotto 32
        assertEquals(1984, Immagine.multiplo32(2000))   // 62,5 → 62 (pari)
        for ((w, h) in listOf(Pair(37, 999), Pair(3000, 4000), Pair(736, 736))) {
            val (dw, dh) = Preprocess.dimensioniDet(w, h)
            assertEquals(0, dw % 32)
            assertEquals(0, dh % 32)
            assertEquals(w.toDouble() / h, dw.toDouble() / dh, 0.1)
        }
    }

    @Test fun `tensore del rilevatore - BGR, normalizzato 0,5`() {
        // Un pixel R=255, G=0, B=51.
        val t = Preprocess.tensoreDet(ImmagineRgb(1, 1, intArrayOf(0xFFFF0033.toInt())))
        assertEquals(51 / 255f * 2 - 1, t[0], 1e-6f)   // B
        assertEquals(-1f, t[1], 1e-6f)                 // G
        assertEquals(1f, t[2], 1e-6f)                  // R
    }

    @Test fun `tensore del riconoscitore - altezza 48, larghezza minima 320, riempimento a 0`() {
        val crop = ImmagineRgb(100, 50, IntArray(5000) { 0xFFFFFFFF.toInt() })   // bianco
        val larghezza = Preprocess.larghezzaLotto(listOf(crop))
        assertEquals(320, larghezza)
        val (t, utile) = Preprocess.tensoreRec(crop, larghezza)
        assertEquals(96, utile)                         // ceil(48 · 2)
        assertEquals(3 * 48 * 320, t.size)
        assertEquals(1f, t[0], 1e-6f)                   // bianco → +1
        assertEquals(0f, t[100], 1e-6f)                 // oltre la parte utile: 0
    }

    @Test fun `larghezza del lotto dal rapporto piu largo`() {
        val corto = ImmagineRgb(10, 10, IntArray(100))
        val lungo = ImmagineRgb(400, 20, IntArray(8000))    // rapporto 20 → 960
        assertEquals(960, Preprocess.larghezzaLotto(listOf(corto, lungo)))
        assertEquals(500, Preprocess.larghezzaLotto(listOf(lungo), larghezzaMax = 500))
    }
}

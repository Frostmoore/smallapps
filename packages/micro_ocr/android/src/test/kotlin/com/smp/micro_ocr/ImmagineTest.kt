package com.smp.micro_ocr

import kotlin.test.Test
import kotlin.test.assertEquals

class ImmagineTest {
    private fun grigio(v: Int) = (0xFF shl 24) or (v shl 16) or (v shl 8) or v

    @Test fun `riduzione a meta uguale alla media 2x2 come cv2 INTER_LINEAR`() {
        val src = ImmagineRgb(2, 2, intArrayOf(grigio(0), grigio(100), grigio(200), grigio(100)))
        assertEquals(grigio(100), Immagine.ridimensiona(src, 1, 1).pixel[0])
    }

    @Test fun `stesse dimensioni uguale copia`() {
        val src = ImmagineRgb(1, 2, intArrayOf(grigio(1), grigio(2)))
        assertEquals(src.pixel.toList(), Immagine.ridimensiona(src, 1, 2).pixel.toList())
    }

    @Test fun `ritaglio esclude destra e basso`() {
        val src = ImmagineRgb(3, 2, IntArray(6) { grigio(it) })
        val c = Immagine.ritaglia(src, Rettangolo(1, 0, 3, 2))
        assertEquals(listOf(grigio(1), grigio(2), grigio(4), grigio(5)), c.pixel.toList())
    }

    @Test fun `rotazione antioraria come np rot90`() {
        // [[0,1,2],[3,4,5]] → [[2,5],[1,4],[0,3]]
        val src = ImmagineRgb(3, 2, IntArray(6) { grigio(it) })
        val r = Immagine.ruota90Antiorario(src)
        assertEquals(2, r.larghezza)
        assertEquals(3, r.altezza)
        assertEquals(listOf(2, 5, 1, 4, 0, 3).map { grigio(it) }, r.pixel.toList())
    }

    @Test fun `rotazione di 180 gradi`() {
        val src = ImmagineRgb(3, 2, IntArray(6) { grigio(it) })
        assertEquals(listOf(5, 4, 3, 2, 1, 0).map { grigio(it) }, Immagine.ruota180(src).pixel.toList())
    }

    @Test fun `entro limiti - lato lungo a 2000 e multipli di 32 come RapidOCR`() {
        val r = Immagine.entroLimiti(ImmagineRgb(4000, 3000, IntArray(12_000_000)))
        assertEquals(1984, r.larghezza)     // int(4000·0,5) = 2000 → round(62,5) = 62 (pari) → 1984
        assertEquals(1504, r.altezza)       // 1500 → round(46,875) = 47 → 1504
    }

    @Test fun `entro limiti - piccola resta com e`() {
        val src = ImmagineRgb(100, 50, IntArray(5000))
        assertEquals(src, Immagine.entroLimiti(src))
    }
}

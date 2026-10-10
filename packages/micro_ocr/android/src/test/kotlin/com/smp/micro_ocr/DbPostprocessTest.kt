package com.smp.micro_ocr

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class DbPostprocessTest {
    /** Mappa w×h a 0 con i rettangoli [x0,x1)×[y0,y1) a [valore]. */
    private fun mappa(w: Int, h: Int, valore: Float, vararg blocchi: IntArray): FloatArray {
        val m = FloatArray(w * h)
        for (b in blocchi) for (y in b[1] until b[3]) for (x in b[0] until b[2]) m[y * w + x] = valore
        return m
    }

    @Test fun `due blocchi danno due rettangoli`() {
        val m = mappa(100, 60, 0.9f, intArrayOf(10, 10, 50, 20), intArrayOf(10, 40, 80, 52))
        assertEquals(2, DbPostprocess.riquadri(m, 100, 60, dilata = false).size)
    }

    @Test fun `sotto la soglia di binarizzazione niente`() {
        val m = mappa(100, 60, 0.25f, intArrayOf(10, 10, 50, 20))
        assertTrue(DbPostprocess.riquadri(m, 100, 60).isEmpty())
    }

    @Test fun `punteggio medio sotto sogliaRiquadro scartato`() {
        // Binarizzato (0,4 > 0,3) ma con media 0,4 < 0,5.
        val m = mappa(100, 60, 0.4f, intArrayOf(10, 10, 50, 20))
        assertTrue(DbPostprocess.riquadri(m, 100, 60).isEmpty())
        assertEquals(1, DbPostprocess.riquadri(m, 100, 60, sogliaRiquadro = 0.35f).size)
    }

    @Test fun `unclip allarga di area per 1,6 su perimetro per lato`() {
        // Pixel 20..59 × 20..29: lati 39 × 9 → d = 39·9·1,6/(2·48) = 5,85.
        // 20 − 5,85 = 14,15 → 14; 59 + 5,85 = 64,85 → 65; 29 + 5,85 = 34,85 → 35.
        val m = mappa(100, 60, 0.9f, intArrayOf(20, 20, 60, 30))
        val r = DbPostprocess.riquadri(m, 100, 60, dilata = false).single().contenitore()
        assertEquals(Rettangolo(14, 14, 65, 35), r)
    }

    @Test fun `lati minimi - una riga alta 2 pixel non passa`() {
        val m = mappa(100, 60, 0.9f, intArrayOf(10, 10, 60, 13))   // lati 49 × 2 < 3
        assertTrue(DbPostprocess.riquadri(m, 100, 60, dilata = false).isEmpty())
    }

    @Test fun `riportati nelle dimensioni di destinazione`() {
        val m = mappa(100, 60, 0.9f, intArrayOf(20, 20, 60, 30))
        val r = DbPostprocess.riquadri(m, 100, 60, dilata = false, larghezzaDest = 200, altezzaDest = 120).single().contenitore()
        // 14,15·2 = 28,3 → 28; 64,85·2 = 129,7 → 130; 34,85·2 = 69,7 → 70.
        assertEquals(Rettangolo(28, 28, 130, 70), r)
    }

    @Test fun `limitati ai bordi`() {
        val m = mappa(100, 60, 0.9f, intArrayOf(0, 0, 40, 10))
        val r = DbPostprocess.riquadri(m, 100, 60, dilata = false).single().contenitore()
        assertEquals(0, r.sinistra)
        assertEquals(0, r.alto)
    }

    @Test fun `8 vicini - blocchi che si toccano in diagonale sono una componente`() {
        val m = mappa(100, 60, 0.9f, intArrayOf(10, 10, 30, 20), intArrayOf(30, 20, 50, 30))
        // Una componente sola: il rettangolo 40×20 e' pieno a meta' (media 0,45), quindi per
        // vederla si abbassa sogliaRiquadro; con due componenti ne uscirebbero due.
        assertEquals(1, DbPostprocess.riquadri(m, 100, 60, dilata = false, sogliaRiquadro = 0.3f).size)
    }

    @Test fun `dilatazione 2x2 verso destra e in basso`() {
        val m = FloatArray(9); m[4] = 1f       // centro di 3×3
        val d = DbPostprocess.maschera(m, 3, 3, 0.3f, dilata = true)
        assertEquals(listOf(4, 5, 7, 8), d.indices.filter { d[it] })
    }

    @Test fun `ordina - righe dall alto, stessa riga da sinistra`() {
        val a = Quadrilatero.da(Rettangolo(50, 12, 90, 30))   // stessa riga di b (alto entro 10 px)
        val b = Quadrilatero.da(Rettangolo(5, 10, 40, 30))
        val c = Quadrilatero.da(Rettangolo(0, 40, 50, 60))
        assertEquals(listOf(b, a, c), DbPostprocess.ordina(listOf(c, a, b)))
    }

    @Test fun `riga inclinata - quadrilatero ruotato, non scartata`() {
        // Una banda alta 8 px inclinata di circa 10 gradi: il rettangolo allineato agli assi
        // sarebbe pieno per meno di meta' e verrebbe scartato (il caso c26 del banco).
        val w = 200; val h = 100
        val m = FloatArray(w * h)
        for (x in 20 until 180) {
            val yc = 30 + (x - 20) * 0.18f
            for (y in 0 until h) if (kotlin.math.abs(y - yc) <= 4) m[y * w + x] = 0.9f
        }
        val q = DbPostprocess.riquadri(m, w, h, dilata = false).single()
        val pendenza = (q.ad.y - q.as_.y) / (q.ad.x - q.as_.x)
        assertEquals(0.18f, pendenza, 0.03f)
        // 8 px di banda + 2·unclip (d = 160·8·1,6/(2·168) ≈ 6): circa 20, non i ~50 del rettangolo dritto.
        assertTrue(q.bs.y - q.as_.y <= 22, "altezza della riga contenuta: ${q.bs.y - q.as_.y}")
    }

    @Test fun `grande blocco senza stack overflow`() {
        val m = mappa(1000, 1000, 0.9f, intArrayOf(0, 0, 1000, 1000))
        assertEquals(1, DbPostprocess.riquadri(m, 1000, 1000).size)
    }
}

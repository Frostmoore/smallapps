package com.smp.micro_ocr

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class StrisceTest {
    @Test fun `immagine non piu alta che larga - una fascia`() {
        assertEquals(listOf(0 until 800), Strisce.tagli(1000, 800))
    }

    @Test fun `tagli sovrapposti che coprono tutta l altezza`() {
        val t = Strisce.tagli(800, 4000)
        assertEquals(0, t.first().first)
        assertEquals(3999, t.last().last)
        for (f in t) assertEquals(800, f.last - f.first + 1)
        for (i in 1 until t.size) {
            val sovrapposti = t[i - 1].last - t[i].first + 1
            assertTrue(sovrapposti >= 120, "fasce $i sovrapposte di $sovrapposti px")
        }
    }

    @Test fun `fusione dei doppioni - resta il piu grande`() {
        val intera = Quadrilatero.da(Rettangolo(10, 790, 300, 830))
        val tagliata = Quadrilatero.da(Rettangolo(10, 790, 300, 800))    // la stessa riga al bordo della fascia
        val altra = Quadrilatero.da(Rettangolo(10, 900, 300, 940))
        assertEquals(setOf(intera, altra), Strisce.unisci(listOf(tagliata, intera, altra)).toSet())
    }

    @Test fun `righe vicine ma distinte restano`() {
        val a = Quadrilatero.da(Rettangolo(0, 0, 100, 20))
        val b = Quadrilatero.da(Rettangolo(0, 18, 100, 38))     // sovrapposte di 2 px su 20
        assertEquals(2, Strisce.unisci(listOf(a, b)).size)
    }
}

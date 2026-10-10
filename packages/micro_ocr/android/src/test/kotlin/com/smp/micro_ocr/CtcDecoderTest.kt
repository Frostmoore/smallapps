package com.smp.micro_ocr

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class CtcDecoderTest {
    // Dizionario di prova: classi = 0 blank, 1 "a", 2 "b", 3 "€", 4 spazio.
    private val decoder = CtcDecoder(listOf("a", "b", "€"))

    /** Una riga [passi × 5] con probabilita' [p] sull'indice scelto a ogni passo. */
    private fun uscita(indici: IntArray, p: Float = 0.9f): FloatArray {
        val out = FloatArray(indici.size * 5) { (1 - p) / 4 }
        for ((t, i) in indici.withIndex()) out[t * 5 + i] = p
        return out
    }

    @Test fun `blank tolti e ripetizioni fuse`() {
        val (testo, _) = decoder.decodifica(uscita(intArrayOf(0, 1, 1, 0, 1, 2, 2, 0)), 8, 5)
        assertEquals("aab", testo)
    }

    @Test fun `ultima classe e lo spazio`() {
        val (testo, _) = decoder.decodifica(uscita(intArrayOf(1, 4, 3, 4)), 4, 5)
        assertEquals("a € ", testo)
    }

    @Test fun `confidenza media dei soli caratteri tenuti`() {
        val u = uscita(intArrayOf(1, 0, 2))
        u[0 * 5 + 1] = 0.8f; u[2 * 5 + 2] = 0.6f
        val (testo, conf) = decoder.decodifica(u, 3, 5)
        assertEquals("ab", testo)
        assertEquals(0.7f, conf, 1e-6f)
    }

    @Test fun `solo blank da testo vuoto e confidenza 0`() {
        assertEquals(Pair("", 0f), decoder.decodifica(uscita(intArrayOf(0, 0, 0)), 3, 5))
    }

    @Test fun `inizio sposta la lettura nel lotto`() {
        val lotto = uscita(intArrayOf(1, 1)) + uscita(intArrayOf(2, 3))
        assertEquals("b€", decoder.decodifica(lotto, 2, 5, inizio = 10).first)
    }

    @Test fun `classi sbagliate rifiutate`() {
        assertFailsWith<IllegalArgumentException> { decoder.decodifica(FloatArray(12), 2, 6) }
        assertEquals(5, decoder.classi)
    }

    @Test fun `dizionario letto senza trim`() {
        assertEquals(listOf("a", " ", "€"), MotorePpOcr.dizionario("a\n \n€\n"))
        assertEquals(listOf("a", "b"), MotorePpOcr.dizionario("a\nb"))
    }
}

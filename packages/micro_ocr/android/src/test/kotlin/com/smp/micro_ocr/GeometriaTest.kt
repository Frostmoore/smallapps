package com.smp.micro_ocr

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class GeometriaTest {
    @Test fun `inviluppo convesso di un quadrato con punti interni`() {
        val p = listOf(Punto(0f, 0f), Punto(2f, 0f), Punto(2f, 2f), Punto(0f, 2f), Punto(1f, 1f), Punto(1f, 0f))
        assertEquals(4, Geometria.inviluppo(p).size)
    }

    @Test fun `rettangolo minimo di un rettangolo ruotato di 45 gradi`() {
        // Rombo con diagonali 10 e 4 → rettangolo minimo con lati 10/√2·... si verifica l'area.
        val p = listOf(Punto(0f, 0f), Punto(5f, 5f), Punto(3f, 7f), Punto(-2f, 2f))
        val r = Geometria.rettangoloMinimo(p)
        assertEquals(kotlin.math.sqrt(50f), maxOf(r.lato1, r.lato2), 1e-3f)
        assertEquals(kotlin.math.sqrt(8f), minOf(r.lato1, r.lato2), 1e-3f)
    }

    @Test fun `allarga di d per lato`() {
        val r = Geometria.rettangoloMinimo(listOf(Punto(0f, 0f), Punto(10f, 0f), Punto(10f, 4f), Punto(0f, 4f)))
        val g = Geometria.allarga(r, 1f)
        assertEquals(setOf(12f, 6f), setOf(g.lato1, g.lato2))
        val q = Geometria.ordinaVertici(g.vertici)
        assertEquals(Punto(-1f, -1f), q.as_)
        assertEquals(Punto(11f, 5f), q.bd)
    }

    @Test fun `ordine dei vertici alto-sinistra, alto-destra, basso-destra, basso-sinistra`() {
        val q = Geometria.ordinaVertici(listOf(Punto(10f, 5f), Punto(0f, 0f), Punto(0f, 5f), Punto(10f, 0f)))
        assertEquals(Quadrilatero(Punto(0f, 0f), Punto(10f, 0f), Punto(10f, 5f), Punto(0f, 5f)), q)
    }

    @Test fun `dentro un poligono convesso, bordo compreso`() {
        val poli = listOf(Punto(0f, 0f), Punto(4f, 0f), Punto(4f, 4f), Punto(0f, 4f))
        assertTrue(Geometria.dentro(poli, 2f, 2f))
        assertTrue(Geometria.dentro(poli, 4f, 2f))
        assertFalse(Geometria.dentro(poli, 5f, 2f))
    }

    @Test fun `omografia - traslazione e scala`() {
        val da = listOf(Punto(0f, 0f), Punto(1f, 0f), Punto(1f, 1f), Punto(0f, 1f))
        val a = listOf(Punto(10f, 20f), Punto(12f, 20f), Punto(12f, 23f), Punto(10f, 23f))
        val m = Geometria.omografia(da, a)
        assertEquals(2.0, m[0], 1e-9); assertEquals(10.0, m[2], 1e-9)
        assertEquals(3.0, m[4], 1e-9); assertEquals(20.0, m[5], 1e-9)
    }

    @Test fun `ritaglio di un quadrilatero allineato = ritaglio semplice`() {
        val src = ImmagineRgb(6, 4, IntArray(24) { (0xFF shl 24) or (it * 10) })
        val q = Quadrilatero.da(Rettangolo(1, 1, 4, 3))
        val c = Immagine.ritagliaQuadrilatero(src, q)
        assertEquals(3, c.larghezza); assertEquals(2, c.altezza)
        // I vertici vanno in (0,0)..(W,H): il pixel (0,0) del ritaglio e' il (1,1) della sorgente.
        assertEquals(src.pixel[1 * 6 + 1], c.pixel[0])
    }
}

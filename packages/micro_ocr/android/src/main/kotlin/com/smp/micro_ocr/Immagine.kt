package com.smp.micro_ocr

import kotlin.math.floor
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.round

/**
 * Un'immagine in memoria: pixel ARGB impacchettati (0xAARRGGBB), riga per riga.
 *
 * ⚑ Tutta la catena PP-OCR lavora su questa classe e NON su android.graphics.Bitmap: cosi'
 * gira identica sulla JVM del PC (test unitari e banco di parita' con RapidOCR, ParitaJvmTest)
 * e sul telefono. L'unico punto che tocca Bitmap e' ImmagineIngresso (decodifica + EXIF).
 */
class ImmagineRgb(val larghezza: Int, val altezza: Int, val pixel: IntArray) {
    init {
        require(larghezza > 0 && altezza > 0) { "immagine vuota ${larghezza}x$altezza" }
        require(pixel.size == larghezza * altezza) { "pixel ${pixel.size} != ${larghezza}x$altezza" }
    }
}

/** Operazioni pure sulle immagini, scritte per dare gli stessi numeri di OpenCV in RapidOCR. */
object Immagine {

    /**
     * Ridimensionamento bilineare con i centri dei pixel a meta' (come `cv2.resize` con
     * INTER_LINEAR, il default usato da RapidOCR): `src = (dst + 0,5) · scala − 0,5`, bordi
     * replicati, valori arrotondati all'intero (uint8).
     */
    fun ridimensiona(src: ImmagineRgb, larghezza: Int, altezza: Int): ImmagineRgb {
        require(larghezza > 0 && altezza > 0)
        if (larghezza == src.larghezza && altezza == src.altezza) {
            return ImmagineRgb(larghezza, altezza, src.pixel.copyOf())
        }
        val sx = src.larghezza.toDouble() / larghezza
        val sy = src.altezza.toDouble() / altezza
        // Indici e pesi delle colonne calcolati una volta sola (riga per riga cambia solo y).
        val x0 = IntArray(larghezza); val x1 = IntArray(larghezza); val fx = FloatArray(larghezza)
        for (x in 0 until larghezza) {
            var u = (x + 0.5) * sx - 0.5
            if (u < 0) u = 0.0
            val i = floor(u).toInt()
            x0[x] = min(i, src.larghezza - 1)
            x1[x] = min(i + 1, src.larghezza - 1)
            fx[x] = (u - i).toFloat()
        }
        val out = IntArray(larghezza * altezza)
        val p = src.pixel
        for (y in 0 until altezza) {
            var v = (y + 0.5) * sy - 0.5
            if (v < 0) v = 0.0
            val j = floor(v).toInt()
            val r0 = min(j, src.altezza - 1) * src.larghezza
            val r1 = min(j + 1, src.altezza - 1) * src.larghezza
            val fy = (v - j).toFloat()
            val riga = y * larghezza
            for (x in 0 until larghezza) {
                val a = p[r0 + x0[x]]; val b = p[r0 + x1[x]]
                val c = p[r1 + x0[x]]; val d = p[r1 + x1[x]]
                val wx = fx[x]
                out[riga + x] = (0xFF shl 24) or
                    (canale(a, b, c, d, 16, wx, fy) shl 16) or
                    (canale(a, b, c, d, 8, wx, fy) shl 8) or
                    canale(a, b, c, d, 0, wx, fy)
            }
        }
        return ImmagineRgb(larghezza, altezza, out)
    }

    private fun canale(a: Int, b: Int, c: Int, d: Int, s: Int, wx: Float, wy: Float): Int {
        val va = (a shr s) and 0xFF; val vb = (b shr s) and 0xFF
        val vc = (c shr s) and 0xFF; val vd = (d shr s) and 0xFF
        val alto = va + (vb - va) * wx
        val basso = vc + (vd - vc) * wx
        val v = alto + (basso - alto) * wy
        return min(255, max(0, (v + 0.5f).toInt()))
    }

    /** Ritaglio [r] (destra e basso ESCLUSI), limitato ai bordi dell'immagine. */
    fun ritaglia(src: ImmagineRgb, r: Rettangolo): ImmagineRgb {
        val x0 = r.sinistra.coerceIn(0, src.larghezza - 1)
        val y0 = r.alto.coerceIn(0, src.altezza - 1)
        val x1 = r.destra.coerceIn(x0 + 1, src.larghezza)
        val y1 = r.basso.coerceIn(y0 + 1, src.altezza)
        val w = x1 - x0; val h = y1 - y0
        val out = IntArray(w * h)
        for (y in 0 until h) System.arraycopy(src.pixel, (y0 + y) * src.larghezza + x0, out, y * w, w)
        return ImmagineRgb(w, h, out)
    }

    /**
     * Ritaglio «raddrizzato» di un quadrilatero (`get_rotate_crop_image` di RapidOCR): larghezza
     * e altezza = i lati piu' lunghi, trasformazione prospettica che porta i vertici in
     * (0,0) (W,0) (W,H) (0,H), interpolazione bicubica (INTER_CUBIC, a = −0,75), bordi replicati.
     */
    fun ritagliaQuadrilatero(src: ImmagineRgb, q: Quadrilatero): ImmagineRgb {
        fun d(a: Punto, b: Punto) = hypot(a.x - b.x, a.y - b.y)
        val w = max(d(q.as_, q.ad), d(q.bd, q.bs)).toInt().coerceAtLeast(1)
        val h = max(d(q.as_, q.bs), d(q.ad, q.bd)).toInt().coerceAtLeast(1)
        val dst = listOf(Punto(0f, 0f), Punto(w.toFloat(), 0f), Punto(w.toFloat(), h.toFloat()), Punto(0f, h.toFloat()))
        val m = Geometria.omografia(dst, q.punti)      // destinazione → sorgente
        val out = IntArray(w * h)
        for (v in 0 until h) for (u in 0 until w) {
            val den = m[6] * u + m[7] * v + m[8]
            val sx = (m[0] * u + m[1] * v + m[2]) / den
            val sy = (m[3] * u + m[4] * v + m[5]) / den
            out[v * w + u] = bicubico(src, sx, sy)
        }
        return ImmagineRgb(w, h, out)
    }

    private fun pesiCubici(t: Double, pesi: DoubleArray) {
        val a = -0.75
        val t1 = t + 1; val u = 1 - t
        pesi[0] = ((a * t1 - 5 * a) * t1 + 8 * a) * t1 - 4 * a
        pesi[1] = ((a + 2) * t - (a + 3)) * t * t + 1
        pesi[2] = ((a + 2) * u - (a + 3)) * u * u + 1
        pesi[3] = 1 - pesi[0] - pesi[1] - pesi[2]
    }

    private fun bicubico(src: ImmagineRgb, x: Double, y: Double): Int {
        val x0 = floor(x).toInt(); val y0 = floor(y).toInt()
        val wx = DoubleArray(4); val wy = DoubleArray(4)
        pesiCubici(x - x0, wx); pesiCubici(y - y0, wy)
        var r = 0.0; var g = 0.0; var b = 0.0
        for (j in 0 until 4) {
            val yy = (y0 - 1 + j).coerceIn(0, src.altezza - 1) * src.larghezza
            var rr = 0.0; var gg = 0.0; var bb = 0.0
            for (i in 0 until 4) {
                val p = src.pixel[yy + (x0 - 1 + i).coerceIn(0, src.larghezza - 1)]
                rr += wx[i] * ((p shr 16) and 0xFF); gg += wx[i] * ((p shr 8) and 0xFF); bb += wx[i] * (p and 0xFF)
            }
            r += wy[j] * rr; g += wy[j] * gg; b += wy[j] * bb
        }
        fun sat(v: Double) = min(255, max(0, round(v).toInt()))
        return (0xFF shl 24) or (sat(r) shl 16) or (sat(g) shl 8) or sat(b)
    }

    /** Rotazione di 90° in senso ANTIORARIO (come `np.rot90`), per le righe verticali. */
    fun ruota90Antiorario(src: ImmagineRgb): ImmagineRgb {
        val w = src.altezza; val h = src.larghezza
        val out = IntArray(w * h)
        // dst(y, x) = src(x, W−1−y), con W la larghezza della sorgente.
        for (y in 0 until h) for (x in 0 until w) {
            out[y * w + x] = src.pixel[x * src.larghezza + (src.larghezza - 1 - y)]
        }
        return ImmagineRgb(w, h, out)
    }

    /** Rotazione di 180°. */
    fun ruota180(src: ImmagineRgb): ImmagineRgb =
        ImmagineRgb(src.larghezza, src.altezza, src.pixel.reversedArray())

    /**
     * Come `resize_image_within_bounds` di RapidOCR: se il lato lungo supera [latoMax] si
     * riduce, poi se il corto e' sotto [latoMin] si ingrandisce; in entrambi i casi i lati
     * diventano multipli di 32 (arrotondamento «al pari» come `round()` di Python).
     */
    fun entroLimiti(src: ImmagineRgb, latoMin: Int = 30, latoMax: Int = 2000): ImmagineRgb {
        var img = src
        if (max(img.larghezza, img.altezza) > latoMax) {
            val r = latoMax.toDouble() / max(img.larghezza, img.altezza)
            img = ridimensiona(img, multiplo32((img.larghezza * r).toInt()), multiplo32((img.altezza * r).toInt()))
        }
        if (min(img.larghezza, img.altezza) < latoMin) {
            val r = latoMin.toDouble() / min(img.larghezza, img.altezza)
            img = ridimensiona(img, multiplo32((img.larghezza * r).toInt()), multiplo32((img.altezza * r).toInt()))
        }
        return img
    }

    /** `round(n / 32) * 32` di Python (meta' al pari), mai sotto 32. */
    fun multiplo32(n: Int): Int = max(32, (round(n / 32.0) * 32).toInt())
}

package com.smp.micro_ocr

import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.round

/** Rettangolo in pixel, allineato agli assi; [destra] e [basso] esclusi. */
data class Rettangolo(val sinistra: Int, val alto: Int, val destra: Int, val basso: Int) {
    val larghezza get() = destra - sinistra
    val altezza get() = basso - alto
    val area get() = larghezza.toLong() * altezza
}

/**
 * Post-elaborazione DB (Differentiable Binarization) del rilevatore: mappa di probabilita' →
 * quadrilateri (rettangoli ruotati) delle righe di testo. Riscrive `DBPostProcess` di RapidOCR
 * 3.10 senza OpenCV (≈ 20 MB risparmiati).
 *
 * ⚑ Rettangoli RUOTATI di area minima, come `minAreaRect` di RapidOCR (vedi Geometria: con quelli
 * allineati agli assi le righe inclinate sparivano).
 * ⚑ Componenti connesse a 8 vicini (come i contorni esterni di `cv2.findContours`), con BFS
 * iterativa e una coda IntArray: niente ricorsione (stack overflow su un blocco grande).
 * Dell'insieme dei pixel servono solo il primo e l'ultimo di ogni riga: l'inviluppo convesso
 * (e quindi il rettangolo minimo) e' lo stesso del contorno di OpenCV.
 */
object DbPostprocess {

    /**
     * @param mappa uscita del rilevatore `[H·W]` (probabilita' 0..1), riga per riga.
     * @param soglia binarizzazione (`thresh` 0,3).
     * @param sogliaRiquadro punteggio minimo = media della mappa nel quadrilatero (`box_thresh`,
     *   0,5 nel config.yaml di RapidOCR 3.10; la specsheet ipotizzava 0,6).
     * @param unclip espansione di `area · unclip / perimetro` per lato (`unclip_ratio` 1,6).
     * @param latoMin lato corto minimo prima dell'espansione (`min_size` 3; dopo: latoMin + 2).
     * @param larghezzaDest, altezzaDest dimensioni dell'immagine in cui riportare i quadrilateri.
     * @param dilata dilatazione 2x2 della maschera (`use_dilation: true`).
     */
    fun riquadri(
        mappa: FloatArray, w: Int, h: Int,
        soglia: Float = 0.3f, sogliaRiquadro: Float = 0.5f, unclip: Float = 1.6f, latoMin: Int = 3,
        larghezzaDest: Int = w, altezzaDest: Int = h, dilata: Boolean = true, maxCandidati: Int = 1000,
    ): List<Quadrilatero> {
        require(mappa.size >= w * h)
        val maschera = maschera(mappa, w, h, soglia, dilata)
        val etichetta = IntArray(w * h)          // 0 = non visitato
        val coda = IntArray(w * h)
        val primoX = IntArray(h); val ultimoX = IntArray(h)
        val out = ArrayList<Quadrilatero>()
        var componenti = 0
        for (inizio in 0 until w * h) {
            if (!maschera[inizio] || etichetta[inizio] != 0) continue
            componenti++
            if (componenti > maxCandidati) break
            // BFS: per ogni riga toccata, il pixel piu' a sinistra e quello piu' a destra.
            var testa = 0; var fondo = 0
            coda[fondo++] = inizio; etichetta[inizio] = componenti
            // La scansione e' per righe: nessun pixel della componente sta sopra quello d'inizio.
            val y0 = inizio / w
            var y1 = y0 - 1
            while (testa < fondo) {
                val i = coda[testa++]
                val x = i % w; val y = i / w
                while (y1 < y) { y1++; primoX[y1] = Int.MAX_VALUE; ultimoX[y1] = -1 }
                if (x < primoX[y]) primoX[y] = x
                if (x > ultimoX[y]) ultimoX[y] = x
                for (dy in -1..1) {
                    val ny = y + dy
                    if (ny < 0 || ny >= h) continue
                    for (dx in -1..1) {
                        val nx = x + dx
                        if (nx < 0 || nx >= w || (dx == 0 && dy == 0)) continue
                        val j = ny * w + nx
                        if (maschera[j] && etichetta[j] == 0) { etichetta[j] = componenti; coda[fondo++] = j }
                    }
                }
            }
            val punti = ArrayList<Punto>(2 * (y1 - y0 + 1))
            for (r in y0..y1) if (ultimoX[r] >= 0) {
                punti.add(Punto(primoX[r].toFloat(), r.toFloat()))
                if (ultimoX[r] != primoX[r]) punti.add(Punto(ultimoX[r].toFloat(), r.toFloat()))
            }
            val q = quadrilatero(
                punti, mappa, w, h, sogliaRiquadro, unclip, latoMin, larghezzaDest, altezzaDest,
            ) ?: continue
            out.add(q)
        }
        return out
    }

    /** Dai punti di una componente al quadrilatero finale, o null se va scartata. */
    internal fun quadrilatero(
        punti: List<Punto>, mappa: FloatArray, w: Int, h: Int,
        sogliaRiquadro: Float, unclip: Float, latoMin: Int, larghezzaDest: Int, altezzaDest: Int,
    ): Quadrilatero? {
        val r = Geometria.rettangoloMinimo(punti)
        if (r.latoCorto < latoMin) return null
        if (punteggio(mappa, w, h, Geometria.ordinaVertici(r.vertici).punti) < sogliaRiquadro) return null
        // unclip: offset tondo di distanza d (pyclipper JT_ROUND) → il rettangolo minimo del
        // risultato e' lo stesso rettangolo allargato di d per lato.
        val d = r.lato1 * r.lato2 * unclip / (2 * (r.lato1 + r.lato2))
        val grande = Geometria.allarga(r, d)
        if (grande.latoCorto < latoMin + 2) return null
        val sx = larghezzaDest.toFloat() / w; val sy = altezzaDest.toFloat() / h
        // Come RapidOCR: round(x / w · W) limitato a [0, W], poi a [0, W − 1] intero (clip_det_res).
        val scalati = Geometria.ordinaVertici(grande.vertici).punti.map { p ->
            Punto(
                min(larghezzaDest - 1, round((p.x * sx).toDouble()).toInt().coerceIn(0, larghezzaDest)).toFloat(),
                min(altezzaDest - 1, round((p.y * sy).toDouble()).toInt().coerceIn(0, altezzaDest)).toFloat(),
            )
        }
        val q = ordinaOrario(scalati)
        if (hypot(q.ad.x - q.as_.x, q.ad.y - q.as_.y).toInt() <= 3) return null
        if (hypot(q.bs.x - q.as_.x, q.bs.y - q.as_.y).toInt() <= 3) return null
        return q
    }

    /** `order_points_clockwise` di RapidOCR: i due piu' a sinistra (per x) danno alto/basso-sinistra. */
    internal fun ordinaOrario(p: List<Punto>): Quadrilatero {
        val perX = p.sortedBy { it.x }
        val sx = perX.take(2).sortedBy { it.y }; val dx = perX.drop(2).sortedBy { it.y }
        return Quadrilatero(sx[0], dx[0], dx[1], sx[1])
    }

    /** Binarizzazione (> soglia) e dilatazione 2x2 di `cv2.dilate` (ancora al centro: il pixel,
     *  quello a sinistra, quello sopra e quello in alto a sinistra). */
    internal fun maschera(mappa: FloatArray, w: Int, h: Int, soglia: Float, dilata: Boolean): BooleanArray {
        val bin = BooleanArray(w * h) { mappa[it] > soglia }
        if (!dilata) return bin
        val out = BooleanArray(w * h)
        for (y in 0 until h) for (x in 0 until w) {
            val i = y * w + x
            out[i] = bin[i] || (x > 0 && bin[i - 1]) || (y > 0 && bin[i - w]) || (x > 0 && y > 0 && bin[i - w - 1])
        }
        return out
    }

    /**
     * Media della mappa dentro il poligono (`box_score_fast`: vertici troncati all'intero come
     * `astype(np.int32)`, bordo compreso).
     */
    internal fun punteggio(mappa: FloatArray, w: Int, h: Int, poli: List<Punto>): Float {
        val x0 = floor(poli.minOf { it.x }).toInt().coerceIn(0, w - 1)
        val x1 = ceil(poli.maxOf { it.x }).toInt().coerceIn(0, w - 1)
        val y0 = floor(poli.minOf { it.y }).toInt().coerceIn(0, h - 1)
        val y1 = ceil(poli.maxOf { it.y }).toInt().coerceIn(0, h - 1)
        val tronco = poli.map { Punto((it.x - x0).toInt().toFloat() + x0, (it.y - y0).toInt().toFloat() + y0) }
        var s = 0.0; var n = 0
        for (y in y0..y1) for (x in x0..x1) {
            if (Geometria.dentro(tronco, x.toFloat(), y.toFloat())) { s += mappa[y * w + x]; n++ }
        }
        return if (n == 0) 0f else (s / n).toFloat()
    }

    /**
     * Ordine di lettura come `sorted_boxes` di RapidOCR: per y del vertice alto-sinistra
     * (stabile), poi i quadrilateri il cui vertice dista meno di [sogliaY] px dal precedente sono
     * la stessa riga visiva e si ordinano per x.
     */
    fun ordina(riquadri: List<Quadrilatero>, sogliaY: Float = 10f): List<Quadrilatero> {
        if (riquadri.isEmpty()) return riquadri
        val perY = riquadri.sortedBy { it.as_.y }
        val riga = IntArray(perY.size)
        for (i in 1 until perY.size) {
            riga[i] = riga[i - 1] + if (perY[i].as_.y - perY[i - 1].as_.y >= sogliaY) 1 else 0
        }
        return perY.indices.sortedWith(compareBy<Int>({ riga[it] }, { perY[it].as_.x })).map { perY[it] }
    }
}

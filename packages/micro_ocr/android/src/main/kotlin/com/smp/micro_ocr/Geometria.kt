package com.smp.micro_ocr

import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min

/** Un punto in pixel (virgola mobile). */
data class Punto(val x: Float, val y: Float)

/**
 * Un quadrilatero (in pratica un rettangolo ruotato) con i vertici in ordine
 * alto-sinistra, alto-destra, basso-destra, basso-sinistra (come RapidOCR dopo
 * `order_points_clockwise`).
 */
data class Quadrilatero(val as_: Punto, val ad: Punto, val bd: Punto, val bs: Punto) {
    val punti: List<Punto> get() = listOf(as_, ad, bd, bs)

    /** Il rettangolo allineato agli assi che lo contiene (destra/basso esclusi). */
    fun contenitore(): Rettangolo {
        val xs = punti.map { it.x }; val ys = punti.map { it.y }
        return Rettangolo(
            floor(xs.min()).toInt(), floor(ys.min()).toInt(),
            ceil(xs.max()).toInt(), ceil(ys.max()).toInt(),
        )
    }

    /** Lo stesso quadrilatero spostato di ([dx], [dy]). */
    fun sposta(dx: Float, dy: Float) = Quadrilatero(
        Punto(as_.x + dx, as_.y + dy), Punto(ad.x + dx, ad.y + dy),
        Punto(bd.x + dx, bd.y + dy), Punto(bs.x + dx, bs.y + dy),
    )

    companion object {
        /** Da un rettangolo allineato agli assi. */
        fun da(r: Rettangolo) = Quadrilatero(
            Punto(r.sinistra.toFloat(), r.alto.toFloat()), Punto(r.destra.toFloat(), r.alto.toFloat()),
            Punto(r.destra.toFloat(), r.basso.toFloat()), Punto(r.sinistra.toFloat(), r.basso.toFloat()),
        )
    }
}

/** Rettangolo di area minima: i quattro vertici (in un ordine qualunque, lungo il perimetro) e i lati. */
data class RettangoloMinimo(val vertici: List<Punto>, val lato1: Float, val lato2: Float) {
    val latoCorto: Float get() = min(lato1, lato2)
}

/**
 * Geometria che RapidOCR prende da OpenCV (`minAreaRect`, `boxPoints`, ordinamento dei vertici),
 * riscritta qui.
 *
 * ⚑ Perche' i rettangoli RUOTATI e non quelli allineati agli assi (come la specsheet proponeva):
 * il banco di parita' del 2026-10-10 ha mostrato che con le righe inclinate di 5–10° (cartellini
 * sul bordo dello scaffale, foto storte) il rettangolo allineato contiene molto «vuoto», la sua
 * media scende sotto la soglia e la riga sparisce (c26: 1 riga letta contro 16 di RapidOCR).
 */
object Geometria {

    /** Inviluppo convesso (catena monotona di Andrew), senso antiorario, senza punti collineari. */
    fun inviluppo(punti: List<Punto>): List<Punto> {
        val p = punti.distinct().sortedWith(compareBy<Punto>({ it.x }, { it.y }))
        if (p.size <= 2) return p
        fun croce(o: Punto, a: Punto, b: Punto) = (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
        val basso = ArrayList<Punto>()
        for (q in p) {
            while (basso.size >= 2 && croce(basso[basso.size - 2], basso.last(), q) <= 0) basso.removeAt(basso.size - 1)
            basso.add(q)
        }
        val alto = ArrayList<Punto>()
        for (q in p.asReversed()) {
            while (alto.size >= 2 && croce(alto[alto.size - 2], alto.last(), q) <= 0) alto.removeAt(alto.size - 1)
            alto.add(q)
        }
        basso.removeAt(basso.size - 1); alto.removeAt(alto.size - 1)
        return basso + alto
    }

    /**
     * Rettangolo di area minima che contiene [punti] (calibri rotanti sui lati dell'inviluppo:
     * il rettangolo minimo ha sempre un lato allineato a un lato dell'inviluppo).
     */
    fun rettangoloMinimo(punti: List<Punto>): RettangoloMinimo {
        val h = inviluppo(punti)
        if (h.size == 1) return RettangoloMinimo(List(4) { h[0] }, 0f, 0f)
        var migliore: RettangoloMinimo? = null
        var areaMin = Double.MAX_VALUE
        for (i in h.indices) {
            val a = h[i]; val b = h[(i + 1) % h.size]
            val lung = hypot((b.x - a.x).toDouble(), (b.y - a.y).toDouble())
            if (lung == 0.0) continue
            val ux = (b.x - a.x) / lung; val uy = (b.y - a.y) / lung
            var minU = Double.MAX_VALUE; var maxU = -Double.MAX_VALUE
            var minV = Double.MAX_VALUE; var maxV = -Double.MAX_VALUE
            for (q in h) {
                val dx = (q.x - a.x).toDouble(); val dy = (q.y - a.y).toDouble()
                val u = dx * ux + dy * uy; val v = -dx * uy + dy * ux
                minU = min(minU, u); maxU = max(maxU, u); minV = min(minV, v); maxV = max(maxV, v)
            }
            val area = (maxU - minU) * (maxV - minV)
            if (area < areaMin - 1e-9) {
                areaMin = area
                fun pt(u: Double, v: Double) = Punto((a.x + u * ux - v * uy).toFloat(), (a.y + u * uy + v * ux).toFloat())
                migliore = RettangoloMinimo(
                    listOf(pt(minU, minV), pt(maxU, minV), pt(maxU, maxV), pt(minU, maxV)),
                    (maxU - minU).toFloat(), (maxV - minV).toFloat(),
                )
            }
        }
        return migliore!!
    }

    /** Il rettangolo allargato di [d] su ogni lato (stesso centro e orientamento). */
    fun allarga(r: RettangoloMinimo, d: Float): RettangoloMinimo {
        val cx = r.vertici.map { it.x }.average().toFloat()
        val cy = r.vertici.map { it.y }.average().toFloat()
        // Gli assi del rettangolo: dal vertice 0 al 1 (lato1) e dal 1 al 2 (lato2).
        val (p0, p1, p2) = r.vertici
        val l1 = hypot(p1.x - p0.x, p1.y - p0.y); val l2 = hypot(p2.x - p1.x, p2.y - p1.y)
        val u = if (l1 > 0) Punto((p1.x - p0.x) / l1, (p1.y - p0.y) / l1) else Punto(1f, 0f)
        val v = if (l2 > 0) Punto((p2.x - p1.x) / l2, (p2.y - p1.y) / l2) else Punto(-u.y, u.x)
        val a = l1 / 2 + d; val b = l2 / 2 + d
        fun pt(su: Float, sv: Float) = Punto(cx + su * a * u.x + sv * b * v.x, cy + su * a * u.y + sv * b * v.y)
        return RettangoloMinimo(listOf(pt(-1f, -1f), pt(1f, -1f), pt(1f, 1f), pt(-1f, 1f)), l1 + 2 * d, l2 + 2 * d)
    }

    /**
     * Vertici in ordine alto-sinistra, alto-destra, basso-destra, basso-sinistra, come
     * `get_mini_boxes` di RapidOCR: ordinati per x; dei due piu' a sinistra quello piu' in alto
     * e' alto-sinistra; dei due piu' a destra quello piu' in alto e' alto-destra.
     */
    fun ordinaVertici(v: List<Punto>): Quadrilatero {
        val p = v.sortedBy { it.x }
        val (as_, bs) = if (p[1].y > p[0].y) Pair(p[0], p[1]) else Pair(p[1], p[0])
        val (ad, bd) = if (p[3].y > p[2].y) Pair(p[2], p[3]) else Pair(p[3], p[2])
        return Quadrilatero(as_, ad, bd, bs)
    }

    /** Il pixel (x, y) e' dentro o sul bordo del poligono convesso [poli]? */
    fun dentro(poli: List<Punto>, x: Float, y: Float): Boolean {
        var segno = 0
        for (i in poli.indices) {
            val a = poli[i]; val b = poli[(i + 1) % poli.size]
            val c = (b.x - a.x) * (y - a.y) - (b.y - a.y) * (x - a.x)
            if (abs(c) < 1e-4f) continue
            val s = if (c > 0) 1 else -1
            if (segno == 0) segno = s else if (s != segno) return false
        }
        return true
    }

    /**
     * Omografia che porta i quattro punti [da] nei quattro punti [a] (8 incognite, h33 = 1),
     * risolta con l'eliminazione di Gauss. Restituisce i 9 coefficienti riga per riga.
     */
    fun omografia(da: List<Punto>, a: List<Punto>): DoubleArray {
        val m = Array(8) { DoubleArray(9) }
        for (i in 0 until 4) {
            val x = da[i].x.toDouble(); val y = da[i].y.toDouble()
            val u = a[i].x.toDouble(); val v = a[i].y.toDouble()
            m[2 * i] = doubleArrayOf(x, y, 1.0, 0.0, 0.0, 0.0, -u * x, -u * y, u)
            m[2 * i + 1] = doubleArrayOf(0.0, 0.0, 0.0, x, y, 1.0, -v * x, -v * y, v)
        }
        for (c in 0 until 8) {
            var piv = c
            for (r in c + 1 until 8) if (abs(m[r][c]) > abs(m[piv][c])) piv = r
            val t = m[c]; m[c] = m[piv]; m[piv] = t
            if (abs(m[c][c]) < 1e-12) return doubleArrayOf(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0)
            for (r in 0 until 8) {
                if (r == c) continue
                val f = m[r][c] / m[c][c]
                if (f != 0.0) for (k in c..8) m[r][k] -= f * m[c][k]
            }
        }
        return DoubleArray(9) { if (it == 8) 1.0 else m[it][8] / m[it][it] }
    }
}

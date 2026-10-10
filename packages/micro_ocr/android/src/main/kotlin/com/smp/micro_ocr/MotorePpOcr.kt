package com.smp.micro_ocr

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import ai.onnxruntime.TensorInfo
import java.nio.FloatBuffer

/** Una riga letta: testo, rettangolo NORMALIZZATO 0..1 (origine in alto a sinistra), confidenza. */
data class RigaRiconosciuta(
    val testo: String, val sinistra: Float, val alto: Float,
    val larghezza: Float, val altezza: Float, val confidenza: Float,
)

/**
 * La catena PP-OCR (rilevatore → ritagli → riconoscitore) su due sessioni ONNX Runtime.
 *
 * ⚑ Separata da PpOcrEngine (che legge gli asset Android e i Bitmap) perche' usa solo
 * `ai.onnxruntime.*` e ImmagineRgb: la stessa classe gira nel test di parita' sulla JVM del PC
 * (ParitaJvmTest, ORT desktop 1.28.0) e sul telefono.
 *
 * Non thread-safe: MicroOcrPlugin la usa da un solo thread.
 */
class MotorePpOcr(
    private val env: OrtEnvironment,
    private val det: OrtSession,
    private val rec: OrtSession,
    dizionario: List<String>,
) : AutoCloseable {

    private val decoder = CtcDecoder(dizionario)

    init {
        // ☠ F12.1.16 trappola 4: dizionario disallineato = testo plausibile ma sbagliato.
        val forma = (rec.outputInfo.values.first().info as TensorInfo).shape
        val classi = forma.last().toInt()
        check(classi == decoder.classi) {
            "il riconoscitore ha $classi classi, il dizionario ne vuole ${decoder.classi} (${dizionario.size} + blank + spazio)"
        }
    }

    /**
     * Legge [img] (gia' ruotata secondo l'EXIF). [modo] = "cartellino" | "scontrino".
     * Righe in ordine di lettura; coordinate normalizzate sull'immagine.
     */
    fun leggi(img: ImmagineRgb, modo: String): List<RigaRiconosciuta> {
        // ⚑ Come RapidOCR (`max_side_len` 2000) tranne gli scontrini lunghi che la riduzione a
        // 2000 impoverirebbe: quelli tengono piu' risoluzione e vanno a strisce (F12.1.9 punto 2).
        // Se l'immagine sta gia' entro 2000 px la riduzione non c'e', e le strisce non servono:
        // si resta identici al banco.
        val lunga = modo == "scontrino" && img.altezza > RAPPORTO_STRISCE * img.larghezza &&
            maxOf(img.larghezza, img.altezza) > LATO_MAX
        val lavoro = Immagine.entroLimiti(img, 30, if (lunga) LATO_MAX_SCONTRINO else LATO_MAX)
        val quadri = if (lunga) {
            val tutti = ArrayList<Quadrilatero>()
            for (fascia in Strisce.tagli(lavoro.larghezza, lavoro.altezza)) {
                val pezzo = Immagine.ritaglia(lavoro, Rettangolo(0, fascia.first, lavoro.larghezza, fascia.last + 1))
                for (q in rileva(pezzo)) tutti.add(q.sposta(0f, fascia.first.toFloat()))
            }
            Strisce.unisci(tutti)
        } else {
            rileva(lavoro)
        }
        val ordinati = DbPostprocess.ordina(quadri)
        val testi = riconosci(lavoro, ordinati)
        val w = lavoro.larghezza.toFloat(); val h = lavoro.altezza.toFloat()
        val out = ArrayList<RigaRiconosciuta>()
        for ((i, q) in ordinati.withIndex()) {
            val (testo, conf) = testi[i]
            // Come RapidOCR: via le righe vuote e quelle sotto `text_score` 0,5.
            if (testo.isBlank() || conf < SOGLIA_TESTO) continue
            // Il quadrilatero diventa il rettangolo che lo contiene (come le fixture, F12.1.17).
            val r = q.contenitore()
            val x0 = r.sinistra.coerceIn(0, lavoro.larghezza); val y0 = r.alto.coerceIn(0, lavoro.altezza)
            val x1 = r.destra.coerceIn(x0, lavoro.larghezza); val y1 = r.basso.coerceIn(y0, lavoro.altezza)
            out.add(RigaRiconosciuta(testo, x0 / w, y0 / h, (x1 - x0) / w, (y1 - y0) / h, conf))
        }
        return out
    }

    /** Rilevatore su [img]: quadrilateri in pixel di [img]. */
    fun rileva(img: ImmagineRgb): List<Quadrilatero> {
        val (dw, dh) = Preprocess.dimensioniDet(img.larghezza, img.altezza)
        val ingresso = Preprocess.tensoreDet(Immagine.ridimensiona(img, dw, dh))
        val mappa = esegui(det, ingresso, longArrayOf(1, 3, dh.toLong(), dw.toLong())).first
        return DbPostprocess.riquadri(mappa, dw, dh, larghezzaDest = img.larghezza, altezzaDest = img.altezza)
    }

    /**
     * Riconoscitore: un ritaglio raddrizzato per quadrilatero (verticale se alto ≥ 1,5 volte la larghezza →
     * ruotato), a lotti di [LOTTO_REC] in ordine di rapporto larghezza/altezza, come RapidOCR.
     * ⚑ I lotti (non un'inferenza per riga come diceva la specsheet) perche' il riempimento a
     * destra dipende dal lotto: per la parita' con il banco conta farlo uguale.
     */
    fun riconosci(img: ImmagineRgb, quadri: List<Quadrilatero>): List<Pair<String, Float>> {
        val verticali = HashSet<Int>()
        val ritagli = quadri.mapIndexed { i, q ->
            val c = Immagine.ritagliaQuadrilatero(img, q)
            if (c.altezza >= 1.5 * c.larghezza) { verticali.add(i); Immagine.ruota90Antiorario(c) } else c
        }
        val risultati = riconosciRitagli(ritagli).toMutableList()
        // ⚑ Le righe verticali possono essere ruotate di 90° in un senso o nell'altro: RapidOCR
        // decide con un terzo modello (classificatore 0°/180°); qui, senza modelli in piu', si
        // rilegge il ritaglio capovolto e si tiene la lettura piu' sicura. Costa un'inferenza
        // solo per le righe verticali (rare: etichette girate, b09 del banco).
        if (verticali.isNotEmpty()) {
            val indici = verticali.sorted()
            val capovolti = riconosciRitagli(indici.map { Immagine.ruota180(ritagli[it]) })
            for ((k, i) in indici.withIndex()) {
                if (capovolti[k].second > risultati[i].second) risultati[i] = capovolti[k]
            }
        }
        return risultati
    }

    /** Il riconoscitore su una lista di ritagli, a lotti in ordine di rapporto larghezza/altezza. */
    private fun riconosciRitagli(ritagli: List<ImmagineRgb>): List<Pair<String, Float>> {
        val ordine = ritagli.indices.sortedBy { ritagli[it].larghezza.toDouble() / ritagli[it].altezza }
        val risultati = arrayOfNulls<Pair<String, Float>>(ritagli.size)
        for (lotto in ordine.chunked(LOTTO_REC)) {
            val larghezza = Preprocess.larghezzaLotto(lotto.map { ritagli[it] })
            val piano = 3 * Preprocess.ALTEZZA_REC * larghezza
            val ingresso = FloatArray(lotto.size * piano)
            for ((k, i) in lotto.withIndex()) {
                val (t, _) = Preprocess.tensoreRec(ritagli[i], larghezza)
                System.arraycopy(t, 0, ingresso, k * piano, piano)
            }
            val (uscita, forma) = esegui(
                rec, ingresso,
                longArrayOf(lotto.size.toLong(), 3, Preprocess.ALTEZZA_REC.toLong(), larghezza.toLong()),
            )
            val passi = forma[1].toInt(); val classi = forma[2].toInt()
            for ((k, i) in lotto.withIndex()) {
                risultati[i] = decoder.decodifica(uscita, passi, classi, k * passi * classi)
            }
        }
        return risultati.map { it!! }
    }

    private fun esegui(s: OrtSession, dati: FloatArray, forma: LongArray): Pair<FloatArray, LongArray> {
        OnnxTensor.createTensor(env, FloatBuffer.wrap(dati), forma).use { t ->
            s.run(mapOf(s.inputNames.first() to t)).use { r ->
                val tensore = r.get(0) as OnnxTensor
                val buf = tensore.floatBuffer
                val out = FloatArray(buf.remaining())
                buf.get(out)
                return Pair(out, tensore.info.shape)
            }
        }
    }

    override fun close() {
        det.close()
        rec.close()
    }

    companion object {
        /** Finisce nelle fixture (OcrEngine.nome()). */
        const val NOME = "ppocrv5-ort-1.28.0"
        /** La versione di ORT che deve risultare caricata a runtime (oltre a `strictly` in Gradle). */
        const val VERSIONE_ORT = "1.28.0"
        /** `Global.max_side_len` di RapidOCR. */
        const val LATO_MAX = 2000
        /** Scontrini lunghi a strisce: lato lungo fino a 4000 px per non perdere le righe. */
        const val LATO_MAX_SCONTRINO = 4000
        /** Uno scontrino si legge a strisce quando e' alto piu' di [RAPPORTO_STRISCE] volte la larghezza. */
        const val RAPPORTO_STRISCE = 2.5
        /** `Global.text_score` di RapidOCR. */
        const val SOGLIA_TESTO = 0.5f
        /** `Rec.rec_batch_num` di RapidOCR. */
        const val LOTTO_REC = 6

        /** Opzioni di sessione: 4 thread, ottimizzazioni piene, nessun execution provider extra. */
        fun opzioni(): OrtSession.SessionOptions = OrtSession.SessionOptions().apply {
            setIntraOpNumThreads(4)
            setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
        }

        /** Legge il dizionario: una riga per simbolo, SENZA trim (☠ lo spazio e' un simbolo valido). */
        fun dizionario(testo: String): List<String> = testo.split('\n').let { if (it.last().isEmpty()) it.dropLast(1) else it }

        /** Crea il motore dai byte dei modelli e del dizionario. */
        fun crea(env: OrtEnvironment, det: ByteArray, rec: ByteArray, dizionario: String): MotorePpOcr {
            check(env.version == VERSIONE_ORT) { "ONNX Runtime ${env.version} caricato, ammessa solo $VERSIONE_ORT" }
            val o = opzioni()
            val sDet = env.createSession(det, o)
            val sRec = try { env.createSession(rec, o) } catch (e: Exception) { sDet.close(); throw e }
            return try {
                MotorePpOcr(env, sDet, sRec, dizionario(dizionario))
            } catch (e: Exception) {
                sDet.close(); sRec.close(); throw e
            }
        }
    }
}

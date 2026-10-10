package com.smp.micro_ocr

import ai.onnxruntime.OrtEnvironment
import android.content.res.AssetManager

/**
 * Il motore Android: carica modelli e dizionario dagli asset del plugin
 * (`android/src/main/assets/ppocrv5/`, finiscono SOLO nell'APK) e delega a MotorePpOcr.
 */
class PpOcrEngine(private val assets: AssetManager) : AutoCloseable {

    private var motore: MotorePpOcr? = null

    /** Crea le due OrtSession e legge latin_dict.txt. Idempotente. Lancia se qualcosa manca. */
    fun prepara() {
        if (motore != null) return
        val env = OrtEnvironment.getEnvironment()
        motore = MotorePpOcr.crea(
            env,
            leggi("ppocrv5/det.onnx"),
            leggi("ppocrv5/rec_latin.onnx"),
            String(leggi("ppocrv5/latin_dict.txt"), Charsets.UTF_8),
        )
    }

    /** Legge la foto su [percorso]; prepara() se serve. */
    fun leggi(percorso: String, modo: String): List<RigaRiconosciuta> {
        prepara()
        return motore!!.leggi(ImmagineIngresso.carica(percorso), modo)
    }

    override fun close() {
        motore?.close()
        motore = null
    }

    private fun leggi(nome: String): ByteArray = assets.open(nome).use { it.readBytes() }
}

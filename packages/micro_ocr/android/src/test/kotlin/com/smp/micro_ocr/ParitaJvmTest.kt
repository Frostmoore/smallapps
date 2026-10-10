package com.smp.micro_ocr

import ai.onnxruntime.OrtEnvironment
import java.io.File
import java.io.DataInputStream
import kotlin.test.Test

/**
 * Banco di parita' con RapidOCR SULLA JVM DEL PC (F12.2b): la stessa MotorePpOcr del telefono,
 * con ORT desktop 1.28.0, sulle immagini dei campioni. Scrive un JSON per immagine; il confronto
 * con RapidOCR lo fa lo script Python del banco.
 *
 * Si accende solo con due variabili d'ambiente (altrimenti non fa nulla e passa):
 * - MICRO_OCR_PARITA_IN: cartella di file `.rgb` gia' raddrizzati secondo l'EXIF, preparati
 *   dallo script Python del banco con `ImageOps.exif_transpose` come fa RapidOCR (formato:
 *   larghezza e altezza int32 big-endian, poi i pixel RGB a 8 bit riga per riga). ⚑ Grezzi e
 *   non PNG: nei test unitari Android `javax.imageio` non c'e' (classpath di android.jar).
 *   I nomi che iniziano con "s" si leggono in modo scontrino, gli altri cartellino.
 * - MICRO_OCR_PARITA_OUT: cartella dove scrivere `<nome>.json`.
 * ☠ Su Windows serve anche MICRO_OCR_JAVA (vedi build.gradle.kts): i JDK portano un
 *   msvcp140.dll vecchio e onnxruntime.dll desktop fallisce l'inizializzazione; precaricare le
 *   DLL di System32 da qui NON basta (provato), serve un java con quelle DLL nella sua bin/.
 *
 * ⚑ Perche' esiste oltre al test sull'emulatore: gira in secondi, senza dispositivo, e misura
 * la catena Kotlin isolata dalla decodifica Android. Le immagini non entrano mai nel repo.
 */
class ParitaJvmTest {
    @Test fun `banco di parita sulla JVM`() {
        val ingresso = System.getenv("MICRO_OCR_PARITA_IN") ?: return
        val uscita = File(System.getenv("MICRO_OCR_PARITA_OUT") ?: return).apply { mkdirs() }
        val assets = File("src/main/assets/ppocrv5")
        val env = OrtEnvironment.getEnvironment()
        MotorePpOcr.crea(
            env,
            File(assets, "det.onnx").readBytes(),
            File(assets, "rec_latin.onnx").readBytes(),
            File(assets, "latin_dict.txt").readText(Charsets.UTF_8),
        ).use { motore ->
            val immagini = File(ingresso).listFiles { f -> f.extension.lowercase() == "rgb" }!!.sortedBy { it.name }
            for (f in immagini) {
                val img = leggiRgb(f)
                val modo = if (f.name.startsWith("s")) "scontrino" else "cartellino"
                val t0 = System.nanoTime()
                val righe = motore.leggi(img, modo)
                val ms = (System.nanoTime() - t0) / 1_000_000
                File(uscita, f.nameWithoutExtension + ".json").writeText(json(righe, ms), Charsets.UTF_8)
                System.err.println("${f.name} ${img.larghezza}x${img.altezza} $modo: ${righe.size} righe in $ms ms")
            }
        }
    }

    private fun leggiRgb(f: File): ImmagineRgb = DataInputStream(f.inputStream().buffered()).use { d ->
        val w = d.readInt(); val h = d.readInt()
        val rgb = ByteArray(w * h * 3)
        d.readFully(rgb)
        ImmagineRgb(w, h, IntArray(w * h) { i ->
            (0xFF shl 24) or ((rgb[3 * i].toInt() and 0xFF) shl 16) or
                ((rgb[3 * i + 1].toInt() and 0xFF) shl 8) or (rgb[3 * i + 2].toInt() and 0xFF)
        })
    }

    private fun json(righe: List<RigaRiconosciuta>, ms: Long): String = buildString {
        append("{\"ms\":").append(ms).append(",\"righe\":[")
        righe.forEachIndexed { i, r ->
            if (i > 0) append(',')
            append("{\"t\":\"").append(r.testo.replace("\\", "\\\\").replace("\"", "\\\"")).append("\",")
            append("\"x\":").append(r.sinistra).append(",\"y\":").append(r.alto)
            append(",\"w\":").append(r.larghezza).append(",\"h\":").append(r.altezza)
            append(",\"c\":").append(r.confidenza).append('}')
        }
        append("]}")
    }
}

package com.smp.micro_ocr

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Canale "micro_ocr": metodi `nome`, `prepara`, `leggi` {percorso, modo}, `rilascia`.
 *
 * ⚑ Un solo thread di lavoro (newSingleThreadExecutor): le chiamate si mettono in fila, mai due
 * OCR insieme (memoria: un OCR tiene ~150 MB di tensori) e mai sul thread dell'interfaccia.
 * Ogni errore torna come PlatformException code "non_disponibile": il lato Dart lo trasforma in
 * OcrNonDisponibile e l'app ripiega sul tastierino.
 */
class MicroOcrPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var canale: MethodChannel
    private var motore: PpOcrEngine? = null
    private var lavoro: ExecutorService? = null
    private val principale = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        canale = MethodChannel(binding.binaryMessenger, "micro_ocr")
        canale.setMethodCallHandler(this)
        motore = PpOcrEngine(binding.applicationContext.assets)
        lavoro = Executors.newSingleThreadExecutor { r -> Thread(r, "micro_ocr") }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        canale.setMethodCallHandler(null)
        val m = motore
        lavoro?.execute { m?.close() }
        lavoro?.shutdown()
        lavoro = null
        motore = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "nome" -> result.success(MotorePpOcr.NOME)
            "prepara" -> inFila(result) { motore!!.prepara(); null }
            "rilascia" -> inFila(result) { motore!!.close(); null }
            "leggi" -> {
                val percorso = call.argument<String>("percorso")
                val modo = call.argument<String>("modo") ?: "cartellino"
                if (percorso.isNullOrEmpty()) {
                    result.error("non_disponibile", "percorso mancante", null)
                    return
                }
                inFila(result) {
                    motore!!.leggi(percorso, modo).map {
                        mapOf(
                            "t" to it.testo, "x" to it.sinistra.toDouble(), "y" to it.alto.toDouble(),
                            "w" to it.larghezza.toDouble(), "h" to it.altezza.toDouble(), "c" to it.confidenza.toDouble(),
                        )
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun inFila(result: MethodChannel.Result, compito: () -> Any?) {
        val esecutore = lavoro
        if (esecutore == null) {
            result.error("non_disponibile", "plugin staccato", null)
            return
        }
        esecutore.execute {
            try {
                val valore = compito()
                principale.post { result.success(valore) }
            } catch (t: Throwable) {
                // Throwable e non Exception: un UnsatisfiedLinkError (libreria nativa assente su
                // un ABI) o un OutOfMemoryError non devono far morire l'app, ma il solo OCR.
                principale.post { result.error("non_disponibile", t.toString(), null) }
            }
        }
    }
}

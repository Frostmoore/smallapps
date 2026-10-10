package com.smp.micro_ocr

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.exifinterface.media.ExifInterface
import java.io.IOException

/** Decodifica di una foto su disco: riduzione in decodifica + rotazione EXIF → ImmagineRgb. */
object ImmagineIngresso {

    /**
     * Decodifica con `inSampleSize` (potenze di 2) finche' il lato lungo ≤ [latoMax], ruota
     * secondo `ExifInterface.TAG_ORIENTATION`, restituisce i pixel ARGB.
     *
     * ☠ Senza la rotazione EXIF le foto fatte in verticale arrivano coricate e il rilevatore
     * legge pochissimo (F12.1.16 trappola 3).
     * ⚑ [latoMax] 4000 (non i 2400 della specsheet): lo scontrino lungo a strisce lavora fino a
     * 4000 px di lato lungo (MotorePpOcr.LATO_MAX_SCONTRINO); il cartellino lo riduce poi a 2000
     * con lo stesso filtro bilineare di RapidOCR, che e' cio' che rende confrontabili le letture.
     */
    fun carica(percorso: String, latoMax: Int = 4000): ImmagineRgb {
        val bitmap = decodifica(percorso, latoMax)
        val ruotata = ruota(bitmap, orientamento(percorso))
        try {
            val w = ruotata.width; val h = ruotata.height
            val pixel = IntArray(w * h)
            ruotata.getPixels(pixel, 0, w, 0, 0, w, h)
            return ImmagineRgb(w, h, pixel)
        } finally {
            if (ruotata !== bitmap) ruotata.recycle()
            bitmap.recycle()
        }
    }

    private fun decodifica(percorso: String, latoMax: Int): Bitmap {
        val limiti = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(percorso, limiti)
        if (limiti.outWidth <= 0 || limiti.outHeight <= 0) throw IOException("immagine illeggibile: $percorso")
        var campione = 1
        while (maxOf(limiti.outWidth, limiti.outHeight) / campione > latoMax) campione *= 2
        val opzioni = BitmapFactory.Options().apply {
            inSampleSize = campione
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        return BitmapFactory.decodeFile(percorso, opzioni) ?: throw IOException("immagine illeggibile: $percorso")
    }

    private fun orientamento(percorso: String): Int = try {
        ExifInterface(percorso).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
    } catch (_: IOException) {
        ExifInterface.ORIENTATION_NORMAL   // PNG senza EXIF o file strano: come sta
    }

    private fun ruota(b: Bitmap, o: Int): Bitmap {
        val m = Matrix()
        when (o) {
            ExifInterface.ORIENTATION_ROTATE_90 -> m.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> m.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> m.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> m.postScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> m.postScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> { m.postRotate(90f); m.postScale(-1f, 1f) }
            ExifInterface.ORIENTATION_TRANSVERSE -> { m.postRotate(270f); m.postScale(-1f, 1f) }
            else -> return b
        }
        return Bitmap.createBitmap(b, 0, 0, b.width, b.height, m, true)
    }
}

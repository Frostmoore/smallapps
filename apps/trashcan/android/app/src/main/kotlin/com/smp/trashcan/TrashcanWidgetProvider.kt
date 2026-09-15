package com.smp.trashcan

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.LocalDate

/**
 * Il widget della schermata iniziale di TrashCan.
 *
 * Due fasce: sopra, su fondo colorato del tipo di rifiuto, cosa si butta stasera in grande;
 * sotto, su fondo bianco, i prossimi giorni in piccolo.
 *
 * ☠ **Non calcola niente, ma sceglie.** Il lato Dart scrive un anno di stati gia' pronti,
 * uno per giorno, e questo provider prende quello che porta la data di oggi. E' l'unica
 * decisione che gli compete, e basta un confronto fra stringhe: niente calendari, niente
 * ricorrenze, niente lingue. Tutta la logica resta in Dart, dove e' testabile.
 *
 * ⚑ **Perche' gli stati sono precalcolati.** Il widget si ridisegna a mezzanotte e cinque
 * grazie a un allarme, ma il ridisegno non puo' far girare Flutter: un widget Android vive
 * in un processo di sistema e Dart gira solo quando l'app e' aperta. Prima di questa
 * riscrittura il risveglio notturno rileggeva le stesse stringhe del giorno prima, e il
 * widget continuava a dire "stasera: organico" riferendosi alla sera passata finche'
 * qualcuno non apriva l'app.
 *
 * NON convertire questo layout a ConstraintLayout: RemoteViews accetta solo un
 * sottoinsieme ristretto di view, e un ConstraintLayout produce un widget che non si
 * disegna affatto, senza nessun errore in logcat.
 */
class TrashcanWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        // ☠ Tutto dentro un try. Android esegue onUpdate in un BroadcastReceiver, e
        // un'eccezione li' non rompe il widget: fa cadere il processo dell'app con
        // "TrashCan continua a bloccarsi". Un widget che resta indietro di un aggiornamento
        // e' un fastidio; un'app che non si apre piu' e' una disinstallazione.
        try {
            update(context, appWidgetManager, appWidgetIds, widgetData)
        } catch (error: Exception) {
            Log.e("TrashcanWidget", "aggiornamento del widget fallito", error)
        }
    }

    private fun update(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val stato = statoDiOggi(widgetData)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.trashcan_widget)

            views.setTextViewText(R.id.widget_label, widgetData.getString(KEY_LABEL, "") ?: "")
            views.setTextViewText(R.id.widget_text, stato.testo)

            val calendarName = widgetData.getString(KEY_CALENDAR, "").orEmpty()
            views.setTextViewText(R.id.widget_calendar, calendarName)
            views.setViewVisibility(
                R.id.widget_calendar,
                if (calendarName.isEmpty()) View.GONE else View.VISIBLE,
            )

            // Il colore arriva come intero ARGB; 0 significa "nessun tipo stasera", e si
            // usa il verde neutro.
            val header = if (stato.colore == 0) NEUTRAL else stato.colore

            // ☠ Il colore si applica tingendo l'ImageView di sfondo, non con
            // setBackgroundColor sulla view: quest'ultimo sostituisce il drawable e con lui
            // gli angoli arrotondati in alto, e il widget viene fuori squadrato sopra e
            // tondo sotto.
            views.setInt(R.id.widget_header_bg, "setColorFilter", header)

            // Il testo va scelto in base alla luminosita' dello sfondo: il nero su un colore
            // scuro e' illeggibile proprio nel caso che conta, di sera e da lontano.
            val foreground = if (isDark(header)) Color.WHITE else Color.BLACK
            views.setTextColor(R.id.widget_text, foreground)
            views.setTextColor(R.id.widget_label, translucent(foreground))
            views.setTextColor(R.id.widget_calendar, translucent(foreground))

            // L'icona del tipo di rifiuto, la stessa della card "Stasera" nell'app. La riga
            // porta la **chiave** dell'icona; il percorso del PNG sta in una preferenza a
            // parte, perche' e' lungo settanta caratteri e si ripeterebbe in ognuna delle
            // trecentosessantacinque righe.
            //
            // ☠ Il glifo nel PNG e' bianco su trasparente e si tinge qui con lo **stesso**
            // `foreground` del testo. Se lo colorasse Dart, la scelta fra chiaro e scuro
            // starebbe in due posti e prima o poi divergerebbero, dando un'icona nera su
            // fondo nero senza che niente segnali un errore.
            //
            // ☠ `decodeFile` restituisce **null** invece di lanciare se il file non c'e'
            // piu', per esempio dopo una pulizia dello spazio. Passare null a
            // setImageViewBitmap lascerebbe l'icona dell'aggiornamento precedente, cioe'
            // quella sbagliata.
            val percorsoIcona = if (stato.chiaveIcona.isEmpty()) {
                ""
            } else {
                widgetData.getString(ICON_PREFIX + stato.chiaveIcona, "").orEmpty()
            }
            val icona = if (percorsoIcona.isEmpty()) null else BitmapFactory.decodeFile(percorsoIcona)
            if (icona != null) {
                views.setImageViewBitmap(R.id.widget_icon, icona)
                views.setInt(R.id.widget_icon, "setColorFilter", foreground)
                views.setViewVisibility(R.id.widget_icon, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_icon, View.GONE)
            }

            // Il corpo: i prossimi giorni, o una riga che spiega che non ce ne sono. Una
            // meta' bianca e vuota si legge come "il widget non ha caricato".
            val prossimi = stato.prossimi
            val ciSonoProssimi = prossimi.isNotEmpty()
            views.setTextViewText(R.id.widget_upcoming, prossimi)
            views.setViewVisibility(
                R.id.widget_upcoming,
                if (ciSonoProssimi) View.VISIBLE else View.GONE,
            )
            views.setTextViewText(R.id.widget_empty, stato.vuoto)
            views.setViewVisibility(
                R.id.widget_empty,
                if (ciSonoProssimi) View.GONE else View.VISIBLE,
            )

            // Toccare il widget apre l'app. FLAG_IMMUTABLE e' obbligatorio da Android 12:
            // senza, il sistema rifiuta il PendingIntent e il widget diventa inerte.
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launch != null) {
                val pending = PendingIntent.getActivity(
                    context,
                    0,
                    launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /**
     * Lo stato scritto da Dart per la data di oggi.
     *
     * ⚑ Si cerca **una riga**, non si analizza tutto. Le righe sono separate da un a capo e
     * cominciano con la data in forma `AAAA-MM-GG`, quindi trovare quella giusta e' una
     * ricerca di sottostringa: il costo non dipende da quanti giorni sono stati
     * precalcolati. Analizzare un anno di JSON a ogni ridisegno costerebbe invece l'intero
     * anno, dentro un BroadcastReceiver che ha un budget di tempo stretto.
     *
     * ☠ Si usa `LocalDate.now()`, cioe' la data **locale** del dispositivo, la stessa
     * nozione di giorno che usa `CivilDate` in Dart. Con un istante UTC, chi vive a est di
     * Greenwich vedrebbe cambiare il widget con ore di ritardo, e a ovest in anticipo.
     */
    private fun statoDiOggi(widgetData: SharedPreferences): Stato {
        val vuoto = widgetData.getString(KEY_UPCOMING_EMPTY, "").orEmpty()
        val nonAggiornato = widgetData.getString(KEY_STALE, "").orEmpty()

        val righe = widgetData.getString(KEY_DAYS, "").orEmpty()
        val oggi = LocalDate.now().toString()

        val inizio = righe.indexOf("\n$oggi$FIELD")
        if (inizio < 0) {
            // Nessuna riga per oggi: o l'app non e' mai stata aperta dopo un aggiornamento,
            // o non la si apre da piu' di un anno. In entrambi i casi si dice la verita'
            // invece di mostrare il giorno sbagliato con sicurezza.
            return Stato(
                testo = nonAggiornato,
                colore = 0,
                chiaveIcona = "",
                prossimi = "",
                vuoto = "",
            )
        }

        val fine = righe.indexOf('\n', inizio + 1).let { if (it < 0) righe.length else it }
        val campi = righe.substring(inizio + 1, fine).split(FIELD)

        // Una riga malformata non deve far cadere il processo: se i campi non ci sono tutti
        // si ripiega sul messaggio, che e' brutto ma vero.
        if (campi.size < 5) {
            return Stato(nonAggiornato, 0, "", "", "")
        }

        return Stato(
            testo = campi[1],
            colore = campi[2].toLongOrNull()?.toInt() ?: 0,
            chiaveIcona = campi[3],
            prossimi = campi[4].replace(LINE, "\n"),
            vuoto = vuoto,
        )
    }

    private data class Stato(
        val testo: String,
        val colore: Int,
        val chiaveIcona: String,
        val prossimi: String,
        val vuoto: String,
    )

    private companion object {
        // Devono coincidere con le costanti in lib/services/trashcan_widget.dart.
        const val KEY_DAYS = "days"
        const val KEY_LABEL = "tonight_label"
        const val KEY_CALENDAR = "calendar_name"
        const val KEY_UPCOMING_EMPTY = "upcoming_empty"
        const val KEY_STALE = "stale"
        const val ICON_PREFIX = "icon_"

        /** Separatore fra i campi di una riga: US, unit separator. */
        const val FIELD = "\u001F"

        /** Separatore fra le righe dell'elenco, dentro un campo: RS, record separator. */
        const val LINE = "\u001E"

        /** Il verde di TrashCan, per quando stasera non si raccoglie niente. */
        const val NEUTRAL = 0xFF2E7D5B.toInt()

        fun isDark(color: Int): Boolean {
            // Luminanza percettiva: il verde pesa piu' del rosso e molto piu' del blu.
            val luminance =
                (0.299 * Color.red(color) + 0.587 * Color.green(color) + 0.114 * Color.blue(color))
            return luminance < 150
        }

        fun translucent(color: Int): Int =
            Color.argb(190, Color.red(color), Color.green(color), Color.blue(color))
    }
}

package com.smp.trashcan

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Il widget della schermata iniziale di TrashCan.
 *
 * Non decide niente: legge le stringhe gia' pronte che il lato Dart ha salvato
 * (vedi lib/services/trashcan_widget.dart) e le mette nel layout. Tutta la logica di
 * calendario, di lingua e di Pro sta in Dart, dove e' testabile.
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
        // un'eccezione qui non rompe il widget: fa cadere il processo dell'app con
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
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.trashcan_widget)

            views.setTextViewText(R.id.widget_label, widgetData.getString(KEY_LABEL, "") ?: "")
            views.setTextViewText(R.id.widget_text, widgetData.getString(KEY_TEXT, "") ?: "")

            val next = widgetData.getString(KEY_NEXT, "").orEmpty()
            views.setTextViewText(R.id.widget_next, next)
            views.setViewVisibility(R.id.widget_next, if (next.isEmpty()) View.GONE else View.VISIBLE)

            val calendarName = widgetData.getString(KEY_CALENDAR, "").orEmpty()
            views.setTextViewText(R.id.widget_calendar, calendarName)
            views.setViewVisibility(
                R.id.widget_calendar,
                if (calendarName.isEmpty()) View.GONE else View.VISIBLE,
            )

            // Il colore arriva come intero ARGB; 0 significa "nessun tipo stasera", e si
            // usa il verde neutro. Il testo va scelto in base alla luminosita' dello
            // sfondo, altrimenti il nero su un colore scuro e' illeggibile proprio nel
            // caso che conta: di sera, di fretta, guardando lo schermo da lontano.
            //
            // ☠ Si legge dalla mappa e si accetta sia Int sia Long. Il canale fra Dart e
            // Android codifica un intero come Integer se sta in 32 bit con segno e come Long
            // altrimenti: **il tipo dipende dal valore**. Un ARGB con alpha 0xFF supera
            // 2^31 e arriva come Long; lo zero che si manda quando stasera non si raccoglie
            // niente arriva come Integer.
            //
            // Quindi getInt() e getLong() sbagliano **a turno**, e non c'e' un momento in
            // cui si possa dire di aver scelto quello giusto. Peggio: un receiver che lancia
            // fa cadere l'intero processo dell'app, non solo il widget. Il sintomo e'
            // "TrashCan continua a bloccarsi", e si presenta la prima sera in cui non si
            // raccoglie niente, cioe' dopo giorni di funzionamento perfetto.
            val stored = when (val raw = widgetData.all[KEY_COLOR]) {
                is Long -> raw.toInt()
                is Int -> raw
                else -> 0
            }
            val background = if (stored == 0) NEUTRAL else stored
            views.setInt(R.id.widget_root, "setBackgroundColor", background)
            val foreground = if (isDark(background)) Color.WHITE else Color.BLACK
            views.setTextColor(R.id.widget_text, foreground)
            views.setTextColor(R.id.widget_label, translucent(foreground))
            views.setTextColor(R.id.widget_next, translucent(foreground))
            views.setTextColor(R.id.widget_calendar, translucent(foreground))
            views.setTextColor(R.id.widget_upcoming, translucent(foreground))

            // I prossimi giorni sono la parte Pro. Chi non ha il Pro non vede una riga
            // vuota: vede un widget piu' corto, che e' il comportamento giusto.
            val showUpcoming = widgetData.getBoolean(KEY_SHOW_UPCOMING, false)
            val upcoming = widgetData.getString(KEY_UPCOMING, "").orEmpty()
            views.setTextViewText(R.id.widget_upcoming, upcoming)
            views.setViewVisibility(
                R.id.widget_upcoming,
                if (showUpcoming && upcoming.isNotEmpty()) View.VISIBLE else View.GONE,
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

    private companion object {
        // Devono coincidere con le costanti in lib/services/trashcan_widget.dart.
        const val KEY_LABEL = "tonight_label"
        const val KEY_TEXT = "tonight_text"
        const val KEY_COLOR = "tonight_color"
        const val KEY_NEXT = "next_text"
        const val KEY_CALENDAR = "calendar_name"
        const val KEY_UPCOMING = "upcoming"
        const val KEY_SHOW_UPCOMING = "show_upcoming"

        /** Il verde del tema, per quando stasera non si raccoglie niente. */
        const val NEUTRAL = 0xFF2E7D5B.toInt()

        fun isDark(color: Int): Boolean {
            // Luminanza percettiva: il verde pesa piu' del rosso e molto piu' del blu.
            val luminance =
                (0.299 * Color.red(color) + 0.587 * Color.green(color) + 0.114 * Color.blue(color))
            return luminance < 150
        }

        fun translucent(color: Int): Int = Color.argb(190, Color.red(color), Color.green(color), Color.blue(color))
    }
}

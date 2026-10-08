package com.smp.scortecalore

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.LocalDate
import java.time.temporal.ChronoUnit

/**
 * Il widget di Scorte Calore (develop_microapps.md F5.0 punto 3): per ogni fonte, i giorni di
 * autonomia e la data di riordino, su blu notte come la testata della home ("A · Brace").
 *
 * ⚑ **I giorni li calcola questo provider** (ADR-018), dalla data di esaurimento che Dart
 * scrive nel payload, confrontata con `LocalDate.now()`: a mezzanotte e cinque, quando
 * l'allarme fa ridisegnare il widget, i giorni scendono anche se l'app non e' stata aperta.
 * Stesso schema di FullFreezerWidgetProvider.
 *
 * NON usare ConstraintLayout nel layout: RemoteViews non lo disegna, senza errori.
 */
class ScorteCaloreWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        // ☠ Tutto dentro un try: un'eccezione in un BroadcastReceiver fa cadere l'app.
        try {
            update(context, appWidgetManager, appWidgetIds, widgetData)
        } catch (error: Exception) {
            Log.e("ScorteCaloreWidget", "aggiornamento del widget fallito", error)
        }
    }

    private fun update(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val righe = widgetData.getString(KEY_ROWS, null)
        val oggi = LocalDate.now()
        val elenco = righe?.split('\n')?.filter { it.isNotEmpty() }.orEmpty()

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.scorte_calore_widget)
            widgetData.getString(KEY_TITLE, null)?.let { views.setTextViewText(R.id.widget_title, it) }

            for ((indice, id) in ROW_IDS.withIndex()) {
                val campi = elenco.getOrNull(indice)?.split(FIELD)
                if (campi == null || campi.size < 4) {
                    views.setViewVisibility(id.row, View.GONE)
                    continue
                }
                views.setViewVisibility(id.row, View.VISIBLE)
                views.setTextViewText(id.name, campi[0])
                val esaurimento = data(campi[1])
                val riordino = data(campi[2])
                if (esaurimento == null) {
                    // Stima non ancora calcolabile: niente numeri inventati.
                    views.setTextViewText(id.days, "–")
                    views.setTextColor(id.days, MUTED)
                    views.setTextViewText(id.detail, widgetData.getString(KEY_NEED_MORE, "").orEmpty())
                    continue
                }
                val giorni = ChronoUnit.DAYS.between(oggi, esaurimento).coerceAtLeast(0)
                views.setTextViewText(id.days, testoGiorni(giorni, widgetData))
                val scaduto = riordino != null && !oggi.isBefore(riordino)
                views.setTextColor(id.days, if (scaduto) ALARM else EMBER)
                views.setTextViewText(
                    id.detail,
                    if (scaduto) {
                        widgetData.getString(KEY_REORDER_NOW, "").orEmpty()
                    } else if (campi[3].isEmpty()) {
                        // Come VistaScorte.swift: senza data niente "Riordina entro il " monco.
                        ""
                    } else {
                        widgetData.getString(KEY_REORDER_TEMPLATE, "").orEmpty().replace("{d}", campi[3])
                    },
                )
            }

            val vuoto = righe != null && elenco.isEmpty()
            views.setViewVisibility(R.id.widget_empty, if (vuoto || righe == null) View.VISIBLE else View.GONE)
            widgetData.getString(KEY_EMPTY, null)?.let { views.setTextViewText(R.id.widget_empty, it) }

            // Il tocco apre l'app sulla home. FLAG_IMMUTABLE e' obbligatorio da Android 12.
            context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { launch ->
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

    private fun data(testo: String): LocalDate? = if (testo.isEmpty()) null else try {
        LocalDate.parse(testo)
    } catch (error: Exception) {
        null
    }

    private fun testoGiorni(giorni: Long, widgetData: SharedPreferences): String =
        if (giorni == 0L) {
            widgetData.getString(KEY_TODAY, "").orEmpty()
        } else {
            widgetData.getString(KEY_DAYS_TEMPLATE, "{n}").orEmpty().replace("{n}", giorni.toString())
        }

    private data class Riga(val row: Int, val name: Int, val detail: Int, val days: Int)

    private companion object {
        // Devono coincidere con le costanti di lib/services/scorte_widget.dart.
        const val KEY_TITLE = "title"
        const val KEY_ROWS = "rows"
        const val KEY_TODAY = "days_today"
        const val KEY_DAYS_TEMPLATE = "days_template"
        const val KEY_REORDER_TEMPLATE = "reorder_template"
        const val KEY_REORDER_NOW = "reorder_now"
        const val KEY_NEED_MORE = "need_more"
        const val KEY_EMPTY = "empty"
        const val FIELD = "\u001F"

        // ScortePalette (lib/app/scorte_palette.dart): brace, ambra d'allarme, testo spento.
        const val EMBER = 0xFFFF7A3D.toInt()
        const val ALARM = 0xFFFFB547.toInt()
        const val MUTED = 0xFFC9D3E6.toInt()

        val ROW_IDS = listOf(
            Riga(R.id.widget_row1, R.id.widget_name1, R.id.widget_detail1, R.id.widget_days1),
            Riga(R.id.widget_row2, R.id.widget_name2, R.id.widget_detail2, R.id.widget_days2),
            Riga(R.id.widget_row3, R.id.widget_name3, R.id.widget_detail3, R.id.widget_days3),
        )
    }
}

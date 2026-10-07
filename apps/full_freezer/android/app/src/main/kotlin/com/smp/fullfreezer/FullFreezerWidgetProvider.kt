package com.smp.fullfreezer

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.LocalDate
import java.time.temporal.ChronoUnit

/**
 * Il widget della schermata iniziale di Full Freezer (develop_microapps.md F4.11).
 *
 * I tre alimenti che stanno nel freezer da piu' tempo, con i giorni, e quanti ce ne sono in
 * tutto. Su fondo blu notte, come la testata della home ("A · Ghiaccio").
 *
 * ⚑ **I giorni li calcola questo provider**, non Dart (ADR-018): il payload porta la data di
 * congelamento di ogni riga, e qui la si confronta con `LocalDate.now()`, cioe' la data
 * **locale** del telefono, la stessa nozione di giorno di `CivilDate`. Cosi' a mezzanotte e
 * cinque, quando l'allarme fa ridisegnare il widget, i numeri crescono di uno senza che
 * l'app sia aperta.
 *
 * NON usare ConstraintLayout nel layout: RemoteViews accetta solo un sottoinsieme ristretto
 * di view, e un ConstraintLayout produce un widget che non si disegna, senza errori.
 */
class FullFreezerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        // ☠ Tutto dentro un try: onUpdate gira in un BroadcastReceiver, e un'eccezione qui
        // fa cadere il processo dell'app ("Full Freezer continua a bloccarsi").
        try {
            update(context, appWidgetManager, appWidgetIds, widgetData)
        } catch (error: Exception) {
            Log.e("FullFreezerWidget", "aggiornamento del widget fallito", error)
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

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.full_freezer_widget)

            // Prima di qualunque pubblicazione (widget aggiunto senza aver mai aperto l'app)
            // si usano i testi di riserva del layout: mai un widget vuoto.
            widgetData.getString(KEY_TITLE, null)?.let { views.setTextViewText(R.id.widget_title, it) }
            views.setTextViewText(R.id.widget_count, widgetData.getString(KEY_COUNT, "").orEmpty())

            val elenco = righe?.split('\n')?.filter { it.isNotEmpty() }.orEmpty()
            for ((indice, id) in ROW_IDS.withIndex()) {
                val campi = elenco.getOrNull(indice)?.split(FIELD)
                if (campi == null || campi.size < 4) {
                    views.setViewVisibility(id.row, View.GONE)
                    continue
                }
                views.setViewVisibility(id.row, View.VISIBLE)
                views.setTextViewText(id.name, campi[1])

                val giorni = giorniDa(campi[0], oggi)
                views.setTextViewText(id.days, testoGiorni(giorni, widgetData))
                // Arancione quando si e' superato il promemoria, come i badge della home.
                val promemoria = campi[3].toIntOrNull()
                val vecchio = giorni != null && promemoria != null && promemoria > 0 && giorni >= promemoria
                views.setTextColor(id.days, if (vecchio) OLD else DAYS)

                // ☠ decodeFile restituisce null se il PNG non c'e' piu' (pulizia della cache):
                // si nasconde l'icona invece di lasciare quella della riga precedente.
                val percorso = widgetData.getString(ICON_PREFIX + campi[2], null)
                val icona = percorso?.let { BitmapFactory.decodeFile(it) }
                if (icona != null) {
                    views.setImageViewBitmap(id.icon, icona)
                    views.setInt(id.icon, "setColorFilter", ICON)
                    views.setViewVisibility(id.icon, View.VISIBLE)
                } else {
                    views.setViewVisibility(id.icon, View.INVISIBLE)
                }
            }

            val vuoto = righe != null && elenco.isEmpty()
            views.setViewVisibility(R.id.widget_empty, if (vuoto) View.VISIBLE else View.GONE)
            widgetData.getString(KEY_EMPTY, null)?.let { views.setTextViewText(R.id.widget_empty, it) }
            views.setViewVisibility(R.id.widget_stale, if (righe == null) View.VISIBLE else View.GONE)

            // Il tocco apre "Da usare prima": l'URI lo intercetta l'app (app.dart). Il plugin
            // costruisce il PendingIntent con FLAG_IMMUTABLE, obbligatorio da Android 12.
            val tocco = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("fullfreezer:///use-soon"),
            )
            views.setOnClickPendingIntent(R.id.widget_root, tocco)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /** I giorni passati da [congelato] (AAAA-MM-GG); null se la data non si legge. */
    private fun giorniDa(congelato: String, oggi: LocalDate): Long? = try {
        ChronoUnit.DAYS.between(LocalDate.parse(congelato), oggi).coerceAtLeast(0)
    } catch (error: Exception) {
        null
    }

    private fun testoGiorni(giorni: Long?, widgetData: SharedPreferences): String = when (giorni) {
        null -> ""
        0L -> widgetData.getString(KEY_TODAY, "").orEmpty()
        else -> widgetData.getString(KEY_DAYS_TEMPLATE, "{n}").orEmpty().replace("{n}", giorni.toString())
    }

    private data class Riga(val row: Int, val icon: Int, val name: Int, val days: Int)

    private companion object {
        // Devono coincidere con le costanti di lib/services/freezer_widget.dart.
        const val KEY_TITLE = "title"
        const val KEY_COUNT = "count"
        const val KEY_EMPTY = "empty"
        const val KEY_ROWS = "rows"
        const val KEY_TODAY = "days_today"
        const val KEY_DAYS_TEMPLATE = "days_template"
        const val ICON_PREFIX = "icon_"
        const val FIELD = "\u001F"

        // I colori della testata blu notte (lib/app/freezer_palette.dart): onNightMuted, badge, ice.
        const val DAYS = 0xFFB9CBE8.toInt()
        const val OLD = 0xFFFFB547.toInt()
        const val ICON = 0xFF8FB8FF.toInt()

        val ROW_IDS = listOf(
            Riga(R.id.widget_row1, R.id.widget_icon1, R.id.widget_name1, R.id.widget_days1),
            Riga(R.id.widget_row2, R.id.widget_icon2, R.id.widget_name2, R.id.widget_days2),
            Riga(R.id.widget_row3, R.id.widget_icon3, R.id.widget_name3, R.id.widget_days3),
        )
    }
}

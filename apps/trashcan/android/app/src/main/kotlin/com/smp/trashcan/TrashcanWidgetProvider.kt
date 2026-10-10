package com.smp.trashcan

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetScheduler
import java.time.LocalDate
import java.time.ZoneId

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
 * ⚑ **Perche' gli stati sono precalcolati.** Il widget si ridisegna dopo mezzanotte grazie
 * agli allarmi programmati da Dart (vedi `TrashcanWidget.istantiDiRisveglio`) e a
 * `updatePeriodMillis`, ma il ridisegno non puo' far girare Flutter: un widget Android vive
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

    /**
     * Le trasmissioni di sistema che cambiano **quale giorno e' oggi**, oltre a quelle del
     * widget: `TIME_SET`, `TIMEZONE_CHANGED` e l'aggiornamento dell'app. Ridisegnano subito e
     * ricalcolano gli istanti dei risvegli, vedi [riarmaMezzanotti].
     *
     * ☠ **Contesto: la correzione del 2026-10-10** («alle 00:00 deve cambiare da solo»).
     * Misurato sull'emulatore (Android 15, targetSdk 36):
     *
     * 1. l'allarme era alle **00:05**;
     * 2. era **inesatto**: da Android 14 `SCHEDULE_EXACT_ALARM` non e' piu' concesso di
     *    default, e il plugin ripiega su `setAndAllowWhileIdle`, con una finestra di un'ora
     *    (`dumpsys alarm`: `window=+1h0m0s flags=0x20`) **consegnata alla fine**: il widget
     *    cambiava verso l'una di notte. Il rimedio, un preavviso tarato sulla finestra, e' in
     *    `TrashcanWidget.istantiDiRisveglio` (Dart);
     * 3. gli istanti sono **assoluti**, calcolati nel fuso di quando l'app era aperta:
     *    passando da GMT a Europe/Rome l'allarme delle 00:05 e' diventato quello delle 02:05.
     *    E' il motivo di questo metodo.
     *
     * ☠ **`DATE_CHANGED` NON si usa, ed e' stato provato.** Sembrava la soluzione perfetta:
     * la mezzanotte annunciata dal sistema, senza permessi. Ma non e' fra le trasmissioni
     * esenti dai limiti in background di Android 8: dichiarata nel manifest, `dumpsys
     * activity broadcasts` mostrava "skipped by policy at enqueue: Background execution not
     * allowed" per questo receiver. `TIME_SET` e `TIMEZONE_CHANGED` invece sono esenti, e
     * arrivano (verificato: "ridisegno per android.intent.action.TIME_SET" con l'app chiusa).
     *
     * ☠ `super.onReceive` per primo e sempre: e' li' che `AppWidgetProvider` smista
     * `APPWIDGET_UPDATE`, `APPWIDGET_ENABLED` e gli altri. Le azioni di qui non le conosce e
     * le ignora.
     */
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val azione = intent.action ?: return
        if (azione !in AZIONI_OROLOGIO) return

        // Stesso principio di onUpdate: un'eccezione in un receiver fa cadere il processo.
        try {
            Log.i(TAG, "ridisegno per $azione")
            riarmaMezzanotti(context)
            ridisegnaTutti(context)
        } catch (error: Exception) {
            Log.e(TAG, "ridisegno per $azione fallito", error)
        }
    }

    /**
     * Il primo widget e' stato appena aggiunto.
     *
     * ⚑ Il plugin, in `super`, riarma l'allarme dagli istanti salvati. Qui li si
     * **ricalcola**: chi aggiunge il widget dopo un aggiornamento dell'app senza averla
     * riaperta avrebbe ancora gli istanti vecchi (le 00:05) o, con un fuso cambiato nel
     * frattempo, istanti sfasati. Il ridisegno iniziale lo fa gia' il sistema.
     */
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        try {
            riarmaMezzanotti(context)
        } catch (error: Exception) {
            Log.e(TAG, "risvegli non riarmati", error)
        }
    }

    private fun ridisegnaTutti(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, TrashcanWidgetProvider::class.java))
        if (ids.isEmpty()) return
        onUpdate(context, manager, ids, HomeWidgetPlugin.getData(context))
    }

    /**
     * Ricalcola gli istanti del plugin nel fuso **di adesso**: per ognuno dei prossimi
     * [GIORNI_DI_RISVEGLI] giorni un preavviso tarato perche' la finestra dell'allarme
     * inesatto finisca a mezzanotte e [SECONDI_FINE_FINESTRA] secondi, e un risveglio finale
     * a mezzanotte e [SECONDI_DOPO_MEZZANOTTE] secondi.
     *
     * ☠ E' **la stessa regola** di `TrashcanWidget.istantiDiRisveglio` in Dart, dove e'
     * spiegata e testata, ripetuta qui perche' quando cambia il fuso Dart non gira. Le
     * costanti devono restare uguali a quelle Dart con lo stesso significato.
     *
     * ⚑ `atStartOfDay(zona)` e non "mezzanotte di ieri piu' 24 ore": il 25 ottobre in Italia
     * dura 25 ore, e sommando ore tutti i risvegli dell'inverno cadrebbero alle 23:00.
     */
    private fun riarmaMezzanotti(context: Context) {
        val zona = ZoneId.systemDefault()
        val adesso = System.currentTimeMillis()
        val oggi = LocalDate.now(zona)
        val istanti = mutableListOf<Long>()
        for (giorno in 1..GIORNI_DI_RISVEGLI) {
            val mezzanotte =
                oggi.plusDays(giorno.toLong()).atStartOfDay(zona).toInstant().toEpochMilli()
            val fineFinestra = mezzanotte + SECONDI_FINE_FINESTRA * 1000
            val preavviso = if (giorno == 1) {
                preavvisoArmatoAlle(adesso, fineFinestra)
            } else {
                fineFinestra - FINESTRA_MASSIMA_MS
            }
            if (preavviso != null) istanti.add(preavviso)
            istanti.add(mezzanotte + SECONDI_DOPO_MEZZANOTTE * 1000)
        }
        HomeWidgetScheduler.schedule(context, TrashcanWidgetProvider::class.java.name, istanti)
    }

    /** Come `TrashcanWidget.preavvisoArmatoAlle` in Dart. */
    private fun preavvisoArmatoAlle(adesso: Long, fineFinestra: Long): Long? {
        val mancano = fineFinestra - adesso
        if (mancano < 60_000L) return null
        val anticipoPerTetto = (FINESTRA_MASSIMA_MS * (1 + 1 / QUOTA_FINESTRA)).toLong()
        if (mancano >= anticipoPerTetto) return fineFinestra - FINESTRA_MASSIMA_MS
        return adesso + (mancano / (1 + QUOTA_FINESTRA)).toLong()
    }

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
            Log.e(TAG, "aggiornamento del widget fallito", error)
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
        const val TAG = "TrashcanWidget"

        /** Uguale a `TrashcanWidget.secondiDopoMezzanotte` in Dart. */
        const val SECONDI_DOPO_MEZZANOTTE = 5L

        /** Uguale a `TrashcanWidget.secondiFineFinestra` in Dart. */
        const val SECONDI_FINE_FINESTRA = 30L

        /** Uguale a `TrashcanWidget.finestraMassima` in Dart: un'ora. */
        const val FINESTRA_MASSIMA_MS = 3_600_000L

        /** Uguale a `TrashcanWidget.quotaFinestra` in Dart. */
        const val QUOTA_FINESTRA = 0.75

        /** Uguale a `TrashcanWidget.giorniPrecalcolati` in Dart. */
        const val GIORNI_DI_RISVEGLI = 3650

        /**
         * Le azioni che spostano "oggi". Devono comparire anche nell'intent-filter del
         * receiver nel manifest, altrimenti non arrivano.
         */
        val AZIONI_OROLOGIO = setOf(
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
        )

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

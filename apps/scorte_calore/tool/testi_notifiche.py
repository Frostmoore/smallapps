"""I testi delle notifiche di riordino (F5.8) e della loro sezione nelle impostazioni.

Li raccoglie tool/testi.py (tutti_i_testi): stesso formato, chiave: (inglese, italiano).
Virgolette e apostrofi tipografici anche in inglese (’ “ ”), come nel resto dell'app.

⚑ Il combustibile arriva gia' tradotto da `fuelName` (lib/app/labels.dart) e la quantita' da
`formatAmount` ("14 sacchi"): qui non si ripetono i nomi dei combustibili. In italiano si usa
"Pellet: potrebbe terminare..." e non "Il pellet potrebbe...": l'articolo cambia con il
combustibile (il pellet, la legna, l'altra biomassa) e `fuelName` non lo porta.
"""

# chiave: (inglese, italiano)
TESTI = {
    # ── Canale Android (Impostazioni di sistema → Notifiche) ──
    'notif_channelName': ('Reorder reminders', 'Promemoria di riordino'),
    'notif_channelDescription': ('When to reorder fuel, and when the reorder date has passed',
                                 'Quando riordinare il combustibile, e quando la data di riordino è passata'),

    # ── Notifica di riordino, alla data di riordino ──
    'notif_reorderTitle': ('{source}: time to reorder', '{source}: è ora di riordinare'),
    'notif_reorderBody': ('{fuel} could run out {days, plural, =0{today} =1{in about 1 day} other{in about {days} days}}. About {amount} left.',
                          '{fuel}: potrebbe terminare {days, plural, =0{oggi} =1{tra circa 1 giorno} other{tra circa {days} giorni}}. Ti restano circa {amount}.'),

    # ── Notifica di superamento, 3 giorni dopo, se non ci sono misure nuove ──
    'notif_overdueTitle': ('{source}: reorder date passed', '{source}: data di riordino superata'),
    'notif_overdueBody': ('You’ve passed the expected reorder date ({fuel}). If you’ve already refilled, update the stock and the estimate starts again from there.',
                          'Hai superato la data prevista di riordino ({fuel}). Se hai già rifornito, aggiorna la scorta: la stima ripartirà da lì.'),

    # ── Impostazioni ──
    'settings_notifTitle': ('Reorder reminders', 'Promemoria di riordino'),
    'settings_notifBody': ('A notification on the day to reorder, and another if the date passes without an update.',
                           'Una notifica il giorno in cui riordinare, e un’altra se la data passa senza aggiornamenti.'),
    'settings_notifDenied': ('Notifications are blocked for Scorte Calore. Allow them in the phone’s settings.',
                             'Le notifiche di Scorte Calore sono bloccate. Consentile dalle impostazioni del telefono.'),
}

# 'days' e' gia' int in tool/testi.py; ripetuto qui perche' questo file non dipenda dall'ordine.
TIPI = {
    'days': 'int',
}

"""Testi dell'evento di riordino nel calendario del telefono (F5.10, Pro). Vedi tool/testi.py."""

TESTI = {
    'calendar_add': ('Add to calendar', 'Aggiungi al calendario'),
    'calendar_inCalendar': ('In your calendar', 'Nel calendario'),
    'calendar_drift': ('The estimate has moved: the event still says {date}.',
                       'La stima è cambiata: l’evento dice ancora {date}.'),
    'calendar_update': ('Update event', 'Aggiorna evento'),
    'calendar_remove': ('Remove from calendar', 'Togli dal calendario'),
    'calendar_pick': ('Which calendar?', 'In quale calendario?'),
    'calendar_added': ('Added to your calendar on {date}', 'Aggiunto al calendario il {date}'),
    'calendar_updated': ('Event moved to {date}', 'Evento spostato al {date}'),
    'calendar_removed': ('Removed from your calendar', 'Tolto dal calendario'),
    'calendar_denied': ('Scorte Calore can’t use the calendar. Allow it in the phone’s settings.',
                        'Scorte Calore non può usare il calendario. Consentilo dalle impostazioni del telefono.'),
    'calendar_none': ('There’s no calendar to write in on this phone.',
                      'Su questo telefono non c’è un calendario in cui scrivere.'),
    'calendar_failed': ('The calendar didn’t respond. Try again.', 'Il calendario non ha risposto. Riprova.'),
    'calendar_eventTitle': ('Reorder {fuel} · {source}', 'Riordino {fuel} · {source}'),
    'calendar_eventBody': ('Estimated to last until {date}. Created by Scorte Calore.',
                           'Autonomia stimata fino al {date}. Creato da Scorte Calore.'),
}

"""Genera lib/l10n/app_en.arb e app_it.arb da un'unica tabella.

    python apps/scorte_calore/tool/testi.py

Perche' una tabella sola: con due file ARB scritti a mano, una chiave aggiunta a una lingua
sola compila lo stesso (gen_l10n ripiega sull'inglese) e l'app italiana mostra una frase
inglese senza che nessuno se ne accorga. Qui ogni chiave ha le due lingue sulla stessa riga.
Stesso sistema di apps/full_freezer/tool/testi.py.

Segnaposto: {nome} nel testo. Il tipo si dichiara in TIPI quando non e' String. I plurali
usano la sintassi ICU ({n, plural, =1{...} other{...}}). Virgolette tipografiche anche in
inglese (“…”): con quelle dritte gli script adb non trovano piu' i riquadri.
"""
import json
from pathlib import Path

QUI = Path(__file__).resolve().parent.parent / 'lib' / 'l10n'

# chiave: (inglese, italiano)
TESTI = {
    'appTitle': ('Scorte Calore', 'Scorte Calore'),

    # ── Comuni ──
    'common_save': ('Save', 'Salva'),
    'common_cancel': ('Cancel', 'Annulla'),
    'common_edit': ('Edit', 'Modifica'),
    'common_ok': ('OK', 'OK'),
    'common_next': ('Next', 'Avanti'),
    'common_back': ('Back', 'Indietro'),
    'common_retry': ('Try again', 'Riprova'),
    'common_delete': ('Delete', 'Elimina'),
    'common_optional': ('Optional', 'Facoltativo'),

    # ── Combustibili e unita' ──
    'fuel_pellet': ('Pellets', 'Pellet'),
    'fuel_lpg': ('LPG', 'GPL'),
    'fuel_diesel': ('Heating oil', 'Gasolio'),
    'fuel_wood': ('Firewood', 'Legna'),
    'fuel_biomass': ('Other biomass', 'Altra biomassa'),
    'unit_bags': ('{n, plural, =1{bag} other{bags}}', '{n, plural, =1{sacco} other{sacchi}}'),
    'unit_kg': ('kg', 'kg'),
    'unit_pallets': ('{n, plural, =1{pallet} other{pallets}}', '{n, plural, =1{bancale} other{bancali}}'),
    'unit_liters': ('L', 'L'),
    'unit_percent': ('%', '%'),
    'unit_quintals': ('{n, plural, =1{quintal} other{quintals}}', '{n, plural, =1{quintale} other{quintali}}'),
    'unit_steres': ('{n, plural, =1{stere} other{steres}}', '{n, plural, =1{stero} other{steri}}'),
    'unit_crates': ('{n, plural, =1{crate} other{crates}}', '{n, plural, =1{cassetta} other{cassette}}'),

    # ── Pro e paywall ──
    'paywall_headline': ('Scorte Calore Pro', 'Scorte Calore Pro'),
    'paywall_subhead': ('One payment. No subscription. Yours for good.', 'Un pagamento unico. Nessun abbonamento. Tuo per sempre.'),
    'paywall_buy': ('Unlock Pro', 'Sblocca Pro'),
    'paywall_buyWithPrice': ('Unlock Pro — {price}', 'Sblocca Pro — {price}'),
    'paywall_restore': ('Restore purchase', 'Ripristina acquisto'),
    'paywall_pending': ("Payment is being processed. We'll unlock Pro as soon as it goes through.",
                        'Il pagamento è in elaborazione. Sbloccheremo il Pro appena va a buon fine.'),
    'paywall_thanks': ('Thank you. Pro is unlocked.', 'Grazie. Pro è sbloccato.'),
    'paywall_restoredNothing': ('No previous purchase found on this account.', 'Nessun acquisto precedente trovato su questo account.'),
    'paywall_unavailable': ("The store isn't responding on this device. Check your connection and try again.",
                            'Lo store non risponde su questo dispositivo. Controlla la connessione e riprova.'),
    'paywall_productUnavailable': ("The Pro price hasn't arrived from the store. Try again in a moment.",
                                   'Il prezzo del Pro non è arrivato dallo store. Riprova tra un momento.'),
    'paywall_benefitAlertsTitle': ('A reminder before you run out', 'Il promemoria prima che finisca'),
    'paywall_benefitAlertsBody': ('A notification on the day to reorder, and another if the date passes and you haven’t updated.',
                                  'Una notifica il giorno in cui riordinare, e un’altra se la data passa e non hai aggiornato.'),
    'paywall_benefitSourcesTitle': ('Every heat source you have', 'Tutte le fonti che hai'),
    'paywall_benefitSourcesBody': ('The pellet stove and the LPG tank, home and the holiday house.',
                                   'La stufa a pellet e il bombolone, la casa e la seconda casa.'),
    'paywall_benefitHistoryTitle': ('Full history and charts', 'Storico completo e grafici'),
    'paywall_benefitHistoryBody': ('Compare winters: how much you burn and when.', 'Confronta gli inverni: quanto consumi e quando.'),
    'paywall_benefitCalendarTitle': ('In your calendar', 'Nel tuo calendario'),
    'paywall_benefitCalendarBody': ('The reorder date as an event, updated only when you say so.',
                                    'La data di riordino come evento, aggiornato solo quando lo dici tu.'),
    'paywall_benefitCostsTitle': ('Purchases and costs', 'Acquisti e costi'),
    'paywall_benefitCostsBody': ('What you spend per season, average price per unit.', 'Quanto spendi a stagione, prezzo medio per unità.'),
    'paywall_benefitBackupTitle': ('Backup and new phone', 'Backup e telefono nuovo'),
    'paywall_benefitBackupBody': ('Move everything to a new phone with one file.', 'Sposti tutto su un telefono nuovo con un file.'),
    'paywall_benefitCsvTitle': ('Export to a spreadsheet', 'Esporta in un foglio di calcolo'),
    'paywall_benefitCsvBody': ('Readings and purchases, ready to open in Excel.', 'Misurazioni e acquisti, pronti da aprire in Excel.'),
    'pro_locked': ('This is part of Scorte Calore Pro.', 'Questa funzione fa parte di Scorte Calore Pro.'),

    # ── Impostazioni ──
    'settings_title': ('Settings', 'Impostazioni'),
    'settings_purchase': ('Purchase', 'Acquisto'),
    'settings_restoreGoogle': ('Bought Pro on another phone with the same Google account?', 'Hai comprato il Pro su un altro telefono con lo stesso account Google?'),
    'settings_restoreApple': ('Bought Pro on another iPhone with the same Apple ID?', 'Hai comprato il Pro su un altro iPhone con lo stesso ID Apple?'),
    'settings_appearance': ('Appearance', 'Aspetto'),
    'settings_theme': ('Theme', 'Tema'),
    'theme_system': ('Like the phone', 'Come il telefono'),
    'theme_light': ('Light', 'Chiaro'),
    'theme_dark': ('Dark', 'Scuro'),
    'settings_version': ('Scorte Calore {version}', 'Scorte Calore {version}'),
    'settings_proActive': ('Scorte Calore Pro is active', 'Scorte Calore Pro è attivo'),
    'settings_proCta': ('Discover Scorte Calore Pro', 'Scopri Scorte Calore Pro'),
}

TIPI = {
    'n': 'int', 'count': 'int', 'days': 'int', 'percent': 'int',
}


def segnaposti(testo):
    import re
    nomi = []
    # Un segnaposto e' "{nome}" o "{nome, plural": non quello dopo "=1" o "other", che e'
    # il testo di un ramo del plurale ("=1{sacco}").
    for m in re.finditer(r'(?<![=\w])\{(\w+)(?:\}|,\s*plural)', testo):
        if m.group(1) not in nomi:
            nomi.append(m.group(1))
    return nomi


def main():
    en, it = {'@@locale': 'en'}, {'@@locale': 'it'}
    for chiave, valori in TESTI.items():
        inglese, italiano = valori[0], valori[1]
        en[chiave] = inglese
        it[chiave] = italiano
        nomi = segnaposti(inglese)
        if nomi:
            en['@' + chiave] = {
                'placeholders': {n: {'type': TIPI.get(n, 'String')} for n in nomi},
            }
    QUI.mkdir(parents=True, exist_ok=True)
    for nome, dati in (('app_en.arb', en), ('app_it.arb', it)):
        (QUI / nome).write_text(json.dumps(dati, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    print(f'{len(TESTI)} chiavi scritte')


if __name__ == '__main__':
    main()

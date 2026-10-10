"""Genera lib/l10n/app_en.arb e app_it.arb da un'unica tabella.

    python apps/spending_review/tool/testi.py

Perche' una tabella sola: con due file ARB scritti a mano, una chiave aggiunta a una lingua
sola compila lo stesso (gen_l10n ripiega sull'inglese) e l'app italiana mostra una frase
inglese senza che nessuno se ne accorga. Qui ogni chiave ha le due lingue sulla stessa riga.
Stesso sistema di QR Me, Film Tracker, Scorte Calore e Full Freezer.

Segnaposto: {nome} nel testo. Il tipo si dichiara in TIPI quando non e' String. I plurali
usano la sintassi ICU ({n, plural, =1{...} other{...}}). Virgolette tipografiche anche in
inglese (“…”, ’): con quelle dritte gli script adb non trovano piu' i riquadri. ☠ Nessun glifo
✓ ⚠ ✗ nei testi (guardia texts_glyphs_test.dart): le icone sono icone, non caratteri.
"""
import json
from pathlib import Path

QUI = Path(__file__).resolve().parent.parent / 'lib' / 'l10n'

# chiave: (inglese, italiano)
# ⚑ Qui i testi comuni del bootstrap (F12.2c). Le schermate (F12.4) aggiungono i loro in
# tool/testi_<parte>.py: un file per parte, cosi' piu' passi lavorano senza toccare lo stesso file.
TESTI = {
    # «Spending Review» e' uguale nelle due lingue (F12.0 punto 1).
    'appTitle': ('Spending Review', 'Spending Review'),

    # ── Comuni ──
    'common_save': ('Save', 'Salva'),
    'common_cancel': ('Cancel', 'Annulla'),
    'common_edit': ('Edit', 'Modifica'),
    'common_retry': ('Try again', 'Riprova'),
    'common_delete': ('Delete', 'Elimina'),
    'common_undo': ('Undo', 'Annulla'),
    'common_notFound': ('This shopping trip doesn’t exist any more.', 'Questa spesa non esiste più.'),

    # ── Nomi di riga di default (lib/app/labels.dart) ──
    'riga_senzaNome': ('Item', 'Articolo'),
    'riga_sconto': ('Discount', 'Sconto'),
    'negozio_nessuno': ('No shop', 'Senza negozio'),

    # ── Titoli delle schermate (F12.1.11) ──
    'spesa_title': ('Shopping', 'Spesa'),
    'storico_title': ('Past shopping', 'Le spese'),
    'statistiche_title': ('Statistics', 'Statistiche'),
    'impostazioni_title': ('Settings', 'Impostazioni'),

    # ── Pro (F12.0 punto 5, F12.1.14): una riga per chiave limitata, in quest'ordine ──
    'paywall_headline': ('Spending Review Pro', 'Spending Review Pro'),
    'paywall_subhead': ('Once only, for good. No subscription.', 'Una volta sola, per sempre. Nessun abbonamento.'),
    'paywall_buy': ('Unlock Pro', 'Sblocca Pro'),
    'paywall_buyWithPrice': ('Unlock Pro — {price}', 'Sblocca Pro — {price}'),
    'paywall_restore': ('Restore purchase', 'Ripristina acquisto'),
    'paywall_pending': ('Payment is being processed. We’ll unlock Pro as soon as it goes through.',
                        'Il pagamento è in elaborazione. Sbloccheremo il Pro appena va a buon fine.'),
    'paywall_thanks': ('Thank you. Pro is unlocked.', 'Grazie. Pro è sbloccato.'),
    'paywall_restoredNothing': ('No previous purchase found on this account.', 'Nessun acquisto precedente trovato su questo account.'),
    'paywall_unavailable': ('The store isn’t responding on this device. Check your connection and try again.',
                            'Lo store non risponde su questo dispositivo. Controlla la connessione e riprova.'),
    'paywall_productUnavailable': ('The Pro price hasn’t arrived from the store. Try again in a moment.',
                                   'Il prezzo del Pro non è arrivato dallo store. Riprova tra un momento.'),
    'paywall_benefitReceiptTitle': ('Receipt', 'Scontrino'),
    'paywall_benefitReceiptBody': ('Check the till against what you counted, and record a shopping trip straight from the receipt.',
                                   'Controlla la cassa contro il tuo conto, e registra la spesa direttamente dallo scontrino.'),
    'paywall_benefitHistoryTitle': ('Every shopping trip', 'Tutte le spese'),
    'paywall_benefitHistoryBody': ('Not just the last 5: the older ones are already on your phone.',
                                   'Non solo le ultime 5: le altre sono già sul telefono.'),
    # ⚑ Il budget del mese sta qui (risposta D3 del proprietario: «budget mensile si', nel Pro»).
    'paywall_benefitStatsTitle': ('Statistics and monthly budget', 'Statistiche e budget del mese'),
    'paywall_benefitStatsBody': ('By month and by shop, average spend, budgets you went over, and a ceiling for the whole month.',
                                 'Per mese e per negozio, spesa media, sforamenti del budget, e un tetto per tutto il mese.'),
    'paywall_benefitCsvTitle': ('CSV export', 'Export CSV'),
    'paywall_benefitCsvBody': ('Every item of every shopping trip, ready for a spreadsheet.',
                               'Ogni articolo di ogni spesa, pronto per un foglio di calcolo.'),
    'paywall_benefitBackupTitle': ('Backup', 'Backup'),
    'paywall_benefitBackupBody': ('Your shopping history in one file, to keep or move to a new phone.',
                                  'Lo storico della spesa in un file, da tenere o portare su un telefono nuovo.'),
    'pro_locked': ('This is part of Spending Review Pro.', 'Questa funzione fa parte di Spending Review Pro.'),

    # ── Impostazioni (le prime, F12.2c) ──
    'settings_theme': ('Theme', 'Tema'),
    'theme_system': ('Like the phone', 'Come il telefono'),
    'theme_light': ('Light', 'Chiaro'),
    'theme_dark': ('Dark', 'Scuro'),
    'settings_version': ('Spending Review {version}', 'Spending Review {version}'),
    'settings_proActive': ('Spending Review Pro is active', 'Spending Review Pro è attivo'),
    'settings_proCta': ('Discover Spending Review Pro', 'Scopri Spending Review Pro'),
    'settings_restoreGoogle': ('Bought Pro on another phone with the same Google account?', 'Hai comprato il Pro su un altro telefono con lo stesso account Google?'),
    'settings_restoreApple': ('Bought Pro on another iPhone with the same Apple ID?', 'Hai comprato il Pro su un altro iPhone con lo stesso ID Apple?'),
}

TIPI = {
    'n': 'int', 'count': 'int', 'days': 'int',
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


def tutti_i_testi():
    """TESTI piu' quelli dei file tool/testi_<parte>.py (ognuno con un suo dizionario TESTI e,
    se serve, TIPI). ⚑ Un file per parte dell'app: piu' persone possono aggiungere testi nello
    stesso momento senza toccare lo stesso file. Una chiave ripetuta in due file e' un errore."""
    import importlib.util
    tutti = dict(TESTI)
    for f in sorted(Path(__file__).resolve().parent.glob('testi_*.py')):
        spec = importlib.util.spec_from_file_location(f.stem, f)
        modulo = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(modulo)
        for chiave in modulo.TESTI:
            if chiave in tutti:
                raise SystemExit(f'chiave {chiave} ripetuta in {f.name}')
        tutti.update(modulo.TESTI)
        TIPI.update(getattr(modulo, 'TIPI', {}))
    return tutti


def main():
    en, it = {'@@locale': 'en'}, {'@@locale': 'it'}
    testi = tutti_i_testi()
    for chiave, valori in testi.items():
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
    print(f'{len(testi)} chiavi scritte')


if __name__ == '__main__':
    main()

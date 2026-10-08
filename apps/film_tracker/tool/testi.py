"""Genera lib/l10n/app_en.arb e app_it.arb da un'unica tabella.

    python apps/film_tracker/tool/testi.py

Perche' una tabella sola: con due file ARB scritti a mano, una chiave aggiunta a una lingua
sola compila lo stesso (gen_l10n ripiega sull'inglese) e l'app italiana mostra una frase
inglese senza che nessuno se ne accorga. Qui ogni chiave ha le due lingue sulla stessa riga.
Stesso sistema di Scorte Calore e Full Freezer.

Segnaposto: {nome} nel testo. Il tipo si dichiara in TIPI quando non e' String. I plurali
usano la sintassi ICU ({n, plural, =1{...} other{...}}). Virgolette tipografiche anche in
inglese (“…”): con quelle dritte gli script adb non trovano piu' i riquadri.
"""
import json
from pathlib import Path

QUI = Path(__file__).resolve().parent.parent / 'lib' / 'l10n'

# chiave: (inglese, italiano)
TESTI = {
    'appTitle': ('Film Tracker', 'Film Tracker'),

    # ── Comuni ──
    'common_save': ('Save', 'Salva'),
    'common_cancel': ('Cancel', 'Annulla'),
    'common_edit': ('Edit', 'Modifica'),
    'common_retry': ('Try again', 'Riprova'),
    'common_delete': ('Delete', 'Elimina'),
    'common_optional': ('Optional', 'Facoltativo'),

    # ── Home (F6.8; per ora lo scheletro) ──
    'home_inCamera': ('In camera', 'In macchina'),
    'home_atLab': ('At the lab', 'In laboratorio'),
    'home_archive': ('Archive', 'Archivio'),
    'home_emptySection': ('Nothing here yet.', 'Ancora niente qui.'),

    # ── Pro ──
    'paywall_headline': ('Film Tracker Pro', 'Film Tracker Pro'),
    'paywall_subhead': ('One payment. No subscription. Yours for good.', 'Un pagamento unico. Nessun abbonamento. Tuo per sempre.'),
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
    'paywall_benefitStatsTitle': ('What you shoot and what it costs', 'Cosa scatti e quanto ti costa'),
    'paywall_benefitStatsBody': ('Rolls per year, spending on film, developing and prints, cost per roll.',
                                 'Rullini all’anno, spesa in pellicola, sviluppo e stampe, costo per rullino.'),
    'paywall_benefitPdfTitle': ('Your year on paper', 'Il tuo anno su carta'),
    'paywall_benefitPdfBody': ('A printable summary with every roll, its dates and its photos.',
                               'Un riepilogo da stampare con ogni rullino, le sue date e le sue foto.'),
    'paywall_benefitCamerasTitle': ('All your cameras', 'Tutte le tue macchine'),
    'paywall_benefitCamerasBody': ('Every camera you shoot with, each with its own rolls.',
                                   'Ogni macchina con cui scatti, ciascuna con i suoi rullini.'),
    'paywall_benefitBackupTitle': ('Backup and new phone', 'Backup e telefono nuovo'),
    'paywall_benefitBackupBody': ('Rolls and photos in one file, to keep or move to a new phone.',
                                  'Rullini e foto in un file, da tenere o portare su un telefono nuovo.'),
    'paywall_benefitCsvTitle': ('Export to a spreadsheet', 'Esporta in un foglio di calcolo'),
    'paywall_benefitCsvBody': ('Every roll with its costs, ready to open in Excel.', 'Ogni rullino con i suoi costi, pronto da aprire in Excel.'),
    'pro_locked': ('This is part of Film Tracker Pro.', 'Questa funzione fa parte di Film Tracker Pro.'),

    # ── Impostazioni ──
    'settings_title': ('Settings', 'Impostazioni'),
    'settings_restoreGoogle': ('Bought Pro on another phone with the same Google account?', 'Hai comprato il Pro su un altro telefono con lo stesso account Google?'),
    'settings_restoreApple': ('Bought Pro on another iPhone with the same Apple ID?', 'Hai comprato il Pro su un altro iPhone con lo stesso ID Apple?'),
    'settings_theme': ('Theme', 'Tema'),
    'theme_system': ('Like the phone', 'Come il telefono'),
    'theme_light': ('Light', 'Chiaro'),
    'theme_dark': ('Dark', 'Scuro'),
    'settings_version': ('Film Tracker {version}', 'Film Tracker {version}'),
    'settings_proActive': ('Film Tracker Pro is active', 'Film Tracker Pro è attivo'),
    'settings_proCta': ('Discover Film Tracker Pro', 'Scopri Film Tracker Pro'),
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

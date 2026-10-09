"""Genera lib/l10n/app_en.arb e app_it.arb da un'unica tabella.

    python apps/qr_me/tool/testi.py

Perche' una tabella sola: con due file ARB scritti a mano, una chiave aggiunta a una lingua
sola compila lo stesso (gen_l10n ripiega sull'inglese) e l'app italiana mostra una frase
inglese senza che nessuno se ne accorga. Qui ogni chiave ha le due lingue sulla stessa riga.
Stesso sistema di Film Tracker, Scorte Calore e Full Freezer.

Segnaposto: {nome} nel testo. Il tipo si dichiara in TIPI quando non e' String. I plurali
usano la sintassi ICU ({n, plural, =1{...} other{...}}). Virgolette tipografiche anche in
inglese (“…”): con quelle dritte gli script adb non trovano piu' i riquadri.
"""
import json
from pathlib import Path

QUI = Path(__file__).resolve().parent.parent / 'lib' / 'l10n'

# chiave: (inglese, italiano)
# ⚑ Qui i testi comuni (bootstrap F17.2c). Le schermate (F17.4) aggiungono i loro in
# tool/testi_<parte>.py: un file per parte, cosi' piu' passi lavorano senza toccare lo stesso file.
TESTI = {
    # «QR Me» e' uguale nelle due lingue (F17.0 punto 1).
    'appTitle': ('QR Me', 'QR Me'),

    # ── Comuni ──
    'common_save': ('Save', 'Salva'),
    'common_cancel': ('Cancel', 'Annulla'),
    'common_edit': ('Edit', 'Modifica'),
    'common_retry': ('Try again', 'Riprova'),
    'common_delete': ('Delete', 'Elimina'),
    'common_copy': ('Copy', 'Copia'),
    'common_copied': ('Copied', 'Copiato'),
    'common_notFound': ('This QR code doesn’t exist any more.', 'Questo QR non esiste più.'),

    # ── I tipi di contenuto (lib/app/labels.dart) ──
    'kind_text': ('Text', 'Testo'),
    'kind_url': ('Link', 'Link'),
    'kind_wifi': ('Wi-Fi', 'Wi-Fi'),
    'kind_contact': ('Contact', 'Contatto'),
    # ⚑ «Email precompilata» e non «Email» (F17.10 punto 3): il modulo crea un QR che apre
    # un'email gia' scritta, non un modo di condividere il proprio indirizzo.
    'kind_email': ('Pre-filled email', 'Email precompilata'),
    'kind_sms': ('SMS', 'SMS'),
    'kind_phone': ('Phone', 'Telefono'),

    # ── Titoli delle schermate (F17.1.5) ──
    'scan_title': ('Read a QR code', 'Leggi un QR'),
    'scanResult_title': ('What the QR code says', 'Cosa dice il QR'),
    'style_title': ('Style', 'Stile'),
    'saved_title': ('Favourites', 'Preferiti'),
    'history_title': ('History', 'Cronologia'),

    # ── Pro (F17.0 punto 6, F17.1.9) ──
    'paywall_headline': ('QR Me Pro', 'QR Me Pro'),
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
    'paywall_benefitStyleTitle': ('Colours and a logo in the QR code', 'Stile: colori e logo nel QR'),
    'paywall_benefitStyleBody': ('Your colours, round dots and eyes, and a photo, an icon or an emoji in the middle.',
                                 'I tuoi colori, puntini ed occhi rotondi, e una foto, un’icona o un’emoji al centro.'),
    # ⚑ Da F17.10: niente piu' SMS e telefono, e niente «compili un modulo» (il Wi-Fi si legge dal
    # suo QR o dal telefono, il contatto dalla rubrica).
    'paywall_benefitFormsTitle': ('Wi-Fi, contacts and pre-filled emails', 'Wi-Fi, contatti ed email precompilate'),
    'paywall_benefitFormsBody': ('Your Wi-Fi from its QR code or from the phone, a contact from your address book: guests join or save you just by pointing their camera.',
                                 'Il Wi-Fi dal suo QR o dal telefono, un contatto dalla rubrica: gli ospiti entrano o ti salvano solo inquadrando.'),
    'paywall_benefitFavoritesTitle': ('Unlimited favourites', 'Preferiti senza limite'),
    'paywall_benefitFavoritesBody': ('Keep every QR code you use often, each with its own name.',
                                     'Tieni ogni QR che usi spesso, ognuno con il suo nome.'),
    'paywall_benefitHistoryTitle': ('Unlimited history', 'Cronologia senza limite'),
    'paywall_benefitHistoryBody': ('Every QR code you show or read, from now on. The free history keeps the last 5.',
                                   'Ogni QR che mostri o leggi, da adesso in poi. Quella gratuita tiene gli ultimi 5.'),
    # ⚑ Stessa chiave `imageExport` per immagine ed etichetta (F17.10 punto 5): una riga sola.
    'paywall_benefitImageTitle': ('Share the QR code as a picture or as a printable label', 'Condividi il QR come immagine o come etichetta da stampare'),
    'paywall_benefitImageBody': ('A sharp image to send in a chat, or a label with your text underneath, ready for the printer.',
                                 'Un’immagine nitida da mandare in chat, o un’etichetta con il tuo testo sotto, pronta per la stampante.'),
    'paywall_benefitBackupTitle': ('Backup and new phone', 'Backup e telefono nuovo'),
    'paywall_benefitBackupBody': ('Favourites, history and logos in one file, to keep or move to a new phone.',
                                  'Preferiti, cronologia e loghi in un file, da tenere o portare su un telefono nuovo.'),
    'pro_locked': ('This is part of QR Me Pro.', 'Questa funzione fa parte di QR Me Pro.'),

    # ── Impostazioni ──
    'settings_title': ('Settings', 'Impostazioni'),
    'settings_restoreGoogle': ('Bought Pro on another phone with the same Google account?', 'Hai comprato il Pro su un altro telefono con lo stesso account Google?'),
    'settings_restoreApple': ('Bought Pro on another iPhone with the same Apple ID?', 'Hai comprato il Pro su un altro iPhone con lo stesso ID Apple?'),
    'settings_theme': ('Theme', 'Tema'),
    'theme_system': ('Like the phone', 'Come il telefono'),
    'theme_light': ('Light', 'Chiaro'),
    'theme_dark': ('Dark', 'Scuro'),
    'settings_version': ('QR Me {version}', 'QR Me {version}'),
    'settings_proActive': ('QR Me Pro is active', 'QR Me Pro è attivo'),
    'settings_proCta': ('Discover QR Me Pro', 'Scopri QR Me Pro'),
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

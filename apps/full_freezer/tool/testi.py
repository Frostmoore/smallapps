"""Genera lib/l10n/app_en.arb e app_it.arb da un'unica tabella.

    python apps/full_freezer/tool/testi.py

Perche' una tabella sola: con due file ARB scritti a mano, una chiave aggiunta a una lingua
sola compila lo stesso (gen_l10n ripiega sull'inglese) e l'app italiana mostra una frase
inglese senza che nessuno se ne accorga. Qui ogni chiave ha le due lingue sulla stessa riga.

Segnaposto: {nome} nel testo. Il tipo si dichiara in TIPI quando non e' String. I plurali
usano la sintassi ICU ({n, plural, =1{...} other{...}}).
"""
import json
from pathlib import Path

QUI = Path(__file__).resolve().parent.parent / 'lib' / 'l10n'

# chiave: (inglese, italiano, descrizione opzionale)
TESTI = {
    'appTitle': ('Full Freezer', 'Full Freezer'),

    # ── Comuni ──
    'common_save': ('Save', 'Salva'),
    'common_cancel': ('Cancel', 'Annulla'),
    'common_edit': ('Edit', 'Modifica'),
    'common_rename': ('Rename', 'Rinomina'),
    'common_ok': ('OK', 'OK'),
    'common_undo': ('Undo', 'Annulla'),

    # ── Primo avvio ──
    'onboarding_title': ('Your freezer', 'Il tuo freezer'),
    'onboarding_body': ('Pick the freezer that looks most like yours: Full Freezer uses its size to tell you how full it is.',
                        'Scegli il freezer che somiglia di più al tuo: Full Freezer usa la sua capienza per dirti quanto è pieno.'),
    'onboarding_start': ('Start', 'Inizia'),

    # ── Home ──
    'home_emptyTitle': ('Your freezer is empty', 'Il freezer è vuoto'),
    'home_emptyBody': ('Add what you put in the freezer: the oldest will always be at the top.',
                       'Aggiungi quello che metti nel freezer: il più vecchio sarà sempre in cima.'),
    'home_add': ('Put in freezer', 'Metti nel freezer'),
    'home_addFreezer': ('Add a freezer', 'Aggiungi un freezer'),
    'home_allFreezers': ('All freezers', 'Tutti i freezer'),
    'home_itemCount': ('{count, plural, =0{Nothing inside} =1{1 item} other{{count} items}}',
                       '{count, plural, =0{Niente dentro} =1{1 prodotto} other{{count} prodotti}}'),
    'home_useSoonCount': ('{count, plural, =1{1 to use soon} other{{count} to use soon}}',
                          '{count, plural, =1{1 da usare presto} other{{count} da usare presto}}'),
    'home_useSoon': ('Use first', 'Da usare prima'),
    'home_seeAll': ('See all', 'Vedi tutti'),
    'home_rest': ('Everything else', 'Tutto il resto'),
    'home_where': ('Where they are', 'Dove sono'),
    'home_badgeLabel': ('to use', 'da usare'),
    'home_allFreezersHint': ('Pick a freezer to see how full it is.', 'Scegli un freezer per vedere quanto è pieno.'),
    'home_daysUnit': ('{days, plural, =1{day} other{days}}', '{days, plural, =1{giorno} other{gg}}'),

    # ── Riempimento ──
    'fill_label': ('{percent}% full', 'Pieno al {percent}%'),
    'fill_semantics': ('Freezer {percent}% full', 'Freezer pieno al {percent}%'),
    'fill_percentBig': ('{percent}%', '{percent}%'),
    'fill_liters': ('{used} of {usable} usable', '{used} su {usable} utili'),
    'fill_headerLine': ('full · {used} of {usable} usable', 'pieno · {used} su {usable} utili'),

    # ── Freezer ──
    'freezer_defaultName': ('Kitchen freezer', 'Freezer cucina'),
    'freezer_defaultNameN': ('Freezer {n}', 'Freezer {n}'),
    'freezer_newTitle': ('New freezer', 'Nuovo freezer'),
    'freezer_editTitle': ('Edit freezer', 'Modifica freezer'),
    'freezer_nameLabel': ('Name', 'Nome'),
    'freezer_modelLabel': ('What kind of freezer?', 'Che freezer è?'),
    'freezer_modelHint': ('Typical sizes from product data sheets. If you know your litres, choose "Other".',
                          'Capienze tipiche delle schede tecniche. Se conosci i litri del tuo, scegli «Altro».'),
    'freezer_customLitersShort': ('your litres', 'i tuoi litri'),
    'freezer_customLitersLabel': ('Freezer litres', 'Litri del congelatore'),
    'freezer_customLitersHelp': ('Printed on the energy label, next to the snowflake.',
                                 'Sono scritti sull’etichetta energetica, accanto al fiocco di neve.'),
    'freezer_delete': ('Delete freezer', 'Elimina freezer'),
    'freezer_deleteTitle': ('Delete "{name}"?', 'Eliminare «{name}»?'),
    'freezer_deleteEmpty': ('It is empty: nothing else will be lost.', 'È vuoto: non si perde nient’altro.'),
    'freezer_deleteBody': ('{count, plural, =1{The item inside will be deleted too.} other{The {count} items inside will be deleted too.}}',
                           '{count, plural, =1{Verrà eliminato anche il prodotto che contiene.} other{Verranno eliminati anche i {count} prodotti che contiene.}}'),

    'freezerModel_ice_box': ('Fridge ice box', 'Celletta del frigo'),
    'freezerModel_fridge_top': ('Top freezer (two doors)', 'Freezer sopra il frigo'),
    'freezerModel_combi_compact': ('Fridge-freezer, 180 cm', 'Frigo combinato 180 cm'),
    'freezerModel_undercounter': ('Under-counter drawers', 'Sottopiano a cassetti'),
    'freezerModel_combi_large': ('Fridge-freezer, 200 cm', 'Frigo combinato 200 cm'),
    'freezerModel_chest_small': ('Small chest freezer', 'Pozzetto piccolo'),
    'freezerModel_side_by_side': ('American side by side', 'Frigo americano'),
    'freezerModel_chest_medium': ('Medium chest freezer', 'Pozzetto medio'),
    'freezerModel_upright_tall': ('Tall upright freezer', 'Verticale alto'),
    'freezerModel_chest_large': ('Large chest freezer', 'Pozzetto grande'),
    'freezerModel_custom': ('Other', 'Altro'),

    # ── Taratura ──
    'calibrate_button': ('How full is it really?', 'Quanto è pieno davvero?'),
    'calibrate_reset': ('Go back to the estimate', 'Torna alla stima'),
    'calibrate_hint': ('Open the door and set the bar to what you see.', 'Apri lo sportello e porta la barra a quello che vedi.'),
    'calibrate_active': ('Adjusted by you: the bar follows what you told it.', 'Tarato da te: la barra segue quello che le hai detto.'),
    'calibrate_title': ('How full is it really?', 'Quanto è pieno davvero?'),
    'calibrate_body': ('Open the door and tell the app what you see: from now on the bar will match it.',
                       'Apri lo sportello e di’ all’app quello che vedi: da qui in poi la barra corrisponderà.'),

    # ── Scomparti ──
    'compartments_title': ('Compartments', 'Scomparti'),
    'compartments_add': ('Add compartment', 'Aggiungi scomparto'),
    'compartments_hint': ('Drawer 2', 'Cassetto 2'),
    'compartments_empty': ('No compartments: items just go in the freezer.',
                           'Nessuno scomparto: i prodotti stanno semplicemente nel freezer.'),
    'compartments_delete': ('Delete compartment', 'Elimina scomparto'),
    'compartments_deleteHint': ('Its items stay in the freezer.', 'I suoi prodotti restano nel freezer.'),
    'location_noCompartment': ('No compartment', 'Senza scomparto'),

    # ── Unità ──
    'unit_portions': ('{n, plural, =1{portion} other{portions}}', '{n, plural, =1{porzione} other{porzioni}}'),
    'unit_pieces': ('{n, plural, =1{piece} other{pieces}}', '{n, plural, =1{pezzo} other{pezzi}}'),
    'unit_packs': ('{n, plural, =1{pack} other{packs}}', '{n, plural, =1{confezione} other{confezioni}}'),

    # ── Categorie ──
    'category_meat_red': ('Red meat', 'Carne rossa'),
    'category_meat_white': ('White meat', 'Carne bianca'),
    'category_fish': ('Fish', 'Pesce'),
    'category_vegetables': ('Vegetables', 'Verdura'),
    'category_fruit': ('Fruit', 'Frutta'),
    'category_bread': ('Bread and dough', 'Pane e lievitati'),
    'category_prepared': ('Meals and leftovers', 'Preparati e avanzi'),
    'category_ice_cream': ('Ice cream', 'Gelati'),
    'category_other': ('Other', 'Altro'),
    'category_none': ('No category', 'Nessuna categoria'),
    'category_reminderDays': ('Reminder after {days} days', 'Promemoria dopo {days} giorni'),

    # ── Ingombro ──
    'size_title': ('How much space does it take?', 'Quanto spazio occupa?'),
    'size_body': ('Used to work out how full the freezer is. It does not need to be exact.',
                  'Serve a calcolare quanto è pieno il freezer. Non deve essere preciso.'),
    'size_auto': ('Automatic estimate', 'Stima automatica'),
    'size_small': ('Small', 'Piccolo'),
    'size_medium': ('Medium', 'Medio'),
    'size_large': ('Large', 'Grande'),
    'size_xlarge': ('Very large', 'Molto grande'),
    'size_perUnit': ('{perUnit} each · {inAll} in all', '{perUnit} l’uno · {inAll} in tutto'),
    'size_customLabel': ('Litres in all', 'Litri in tutto'),

    # ── Inserimento rapido ──
    'quickAdd_title': ('Put in freezer', 'Metti nel freezer'),
    'quickAdd_nameLabel': ('What is it?', 'Che cos’è?'),
    'quickAdd_nameHint': ('Beef stew, peas, lasagne…', 'Spezzatino, piselli, lasagne…'),
    'quickAdd_less': ('Less', 'Meno'),
    'quickAdd_more': ('More', 'Di più'),
    'quickAdd_volumeLine': ('≈ {liters} · freezer will be {percent}% full',
                            '≈ {liters} · il freezer sarà pieno al {percent}%'),
    'quickAdd_moreDetails': ('More details', 'Altri dettagli'),
    'quickAdd_saved': ('{name} is in the freezer', '{name} è nel freezer'),

    # ── Pro e paywall ──
    'paywall_headline': ('Full Freezer Pro', 'Full Freezer Pro'),
    'paywall_subhead': ('One payment. No subscription. Yours for good.', 'Un pagamento unico. Nessun abbonamento. Tuo per sempre.'),
    'paywall_buy': ('Unlock Pro', 'Sblocca Pro'),
    'paywall_buyWithPrice': ('Unlock Pro — {price}', 'Sblocca Pro — {price}'),
    'paywall_restore': ('Restore purchase', 'Ripristina acquisto'),
    'paywall_pending': ("Payment is being processed. We'll unlock Pro as soon as it goes through.",
                        'Il pagamento è in elaborazione. Sbloccheremo Pro appena andrà a buon fine.'),
    'paywall_thanks': ('Thank you. Pro is unlocked.', 'Grazie. Pro è sbloccato.'),
    'paywall_restoredNothing': ('No previous purchase found on this account.', 'Nessun acquisto precedente trovato su questo account.'),
    'paywall_unavailable': ("The store isn't responding on this device. Check your connection and try again.",
                            'Lo store degli acquisti non risponde su questo dispositivo. Controlla la connessione e riprova.'),
    'paywall_productUnavailable': ("The Pro price hasn't arrived from the store. Try again in a moment.",
                                   'Il prezzo del Pro non è arrivato dallo store. Riprova fra poco.'),
    'common_retry': ('Try again', 'Riprova'),
    'paywall_benefitFreezersTitle': ('Every freezer you have', 'Tutti i freezer che hai'),
    'paywall_benefitFreezersBody': ("The chest freezer in the garage, the one at your parents': each with its own fill level.",
                                    'Il pozzetto in garage, quello dai tuoi: ognuno con il suo riempimento.'),
    'paywall_benefitAlertsTitle': ('The freezer tells you', 'Il freezer ti avvisa'),
    'paywall_benefitAlertsBody': ("A weekly reminder of what's been in too long, and a heads-up when it's nearly full or nearly empty.",
                                  'Ogni settimana ti dice cosa c’è da troppo, e ti avvisa quando è quasi pieno o quasi vuoto.'),
    'paywall_benefitStatsTitle': ('How much you waste', 'Quanto sprechi'),
    'paywall_benefitStatsBody': ('Eaten versus thrown away, how long things stay in, what you waste most.',
                                 'Consumato contro buttato, quanto restano dentro le cose, cosa sprechi di più.'),
    'paywall_benefitHistoryTitle': ('The history', 'Lo storico'),
    'paywall_benefitHistoryBody': ('Everything you ate and threw away, day by day.', 'Tutto quello che hai consumato e buttato, giorno per giorno.'),
    'paywall_benefitBackupTitle': ('Backup and new phone', 'Backup e telefono nuovo'),
    'paywall_benefitBackupBody': ('Move everything to a new phone with one file.', 'Sposti tutto su un telefono nuovo con un file.'),
    'paywall_benefitCsvTitle': ('Export to a spreadsheet', 'Esporta in un foglio di calcolo'),
    'paywall_benefitCsvBody': ("What's in the freezer, ready to print or share.", 'Quello che c’è nel freezer, pronto da stampare o condividere.'),
    'paywall_benefitCategoriesTitle': ('Your own categories', 'Categorie tue'),
    'paywall_benefitCategoriesBody': ('Beyond the ready-made ones, with their own reminder.', 'Oltre a quelle pronte, ognuna con il suo promemoria.'),
    'pro_activeTitle': ('Full Freezer Pro is active', 'Full Freezer Pro è attivo'),
    'pro_ctaBody': ('Every freezer, the alerts and the numbers on what you waste. One payment.',
                    'Tutti i freezer, gli avvisi e i numeri dello spreco. Un pagamento solo.'),

    # ── Impostazioni ──
    'settings_title': ('Settings', 'Impostazioni'),
    'settings_freezers': ('Your freezers', 'I tuoi freezer'),
    'settings_addFreezerPro': ('The free version has one freezer.', 'La versione gratuita ha un freezer.'),
    'settings_purchase': ('Purchase', 'Acquisto'),
    'settings_restoreGoogle': ('Bought Pro on another phone with the same Google account?', 'Hai comprato il Pro su un altro telefono con lo stesso account Google?'),
    'settings_restoreApple': ('Bought Pro on another iPhone with the same Apple ID?', 'Hai comprato il Pro su un altro iPhone con lo stesso ID Apple?'),
    'settings_appearance': ('Appearance', 'Aspetto'),
    'settings_theme': ('Theme', 'Tema'),
    'theme_system': ('Like the phone', 'Come il telefono'),
    'theme_light': ('Light', 'Chiaro'),
    'theme_dark': ('Dark', 'Scuro'),
    'settings_version': ('Full Freezer {version}', 'Full Freezer {version}'),

    # ── Notifiche ──
    'notif_digestTitle': ('In the freezer for too long', 'Nel freezer da troppo tempo'),
    'notif_digestOne': ('{name} has been in the freezer for {days} days.', '{name} è nel freezer da {days} giorni.'),
    'notif_digestMany': ('{count} things have been in the freezer too long. The oldest is {name}, frozen {days} days ago.',
                         'Hai {count} prodotti nel freezer da troppo tempo. Il più vecchio è {name}, congelato {days} giorni fa.'),
    'notif_fullTitle': ('{name} is nearly full', '{name} è quasi pieno'),
    'notif_fullBody': ("It's {percent}% full: before freezing anything else, use something up.",
                       'È pieno al {percent}%: prima di congelare altro, consuma qualcosa.'),
    'notif_emptyTitle': ('{name} is nearly empty', '{name} è quasi vuoto'),
    'notif_emptyBody': ("It's only {percent}% full: a good weekend to cook something to freeze.",
                        'È pieno solo al {percent}%: buon fine settimana per cucinare qualcosa da congelare.'),
    'settings_alerts': ('Alerts', 'Avvisi'),
    'settings_alertsToggle': ('Freezer alerts', 'Avvisi del freezer'),
    'settings_alertsBody': ("What's been in too long, and when it's nearly full or nearly empty.",
                            'Cosa c’è da troppo, e quando è quasi pieno o quasi vuoto.'),
    'settings_alertsDenied': ('Notifications are off for Full Freezer in the phone settings.',
                              'Le notifiche di Full Freezer sono spente nelle impostazioni del telefono.'),
    'settings_frequency': ('Reminder of old things', 'Promemoria delle cose vecchie'),
    'freq_weekly': ('Every Sunday at 6 pm', 'Ogni domenica alle 18'),
    'freq_biweekly': ('Every other Sunday at 6 pm', 'Una domenica sì e una no, alle 18'),
    'freq_monthly': ('Every four weeks, on Sunday at 6 pm', 'Ogni quattro settimane, la domenica alle 18'),

    # ── Storico e statistiche ──
    'settings_numbers': ('Your numbers', 'I tuoi numeri'),
    'stats_title': ('Statistics', 'Statistiche'),
    'stats_subtitle': ('What you eat, what you throw away, how long things stay in.', 'Cosa consumi, cosa butti, quanto restano dentro le cose.'),
    'stats_lockedSubtitle': ('{count, plural, =0{Unlock them to see what you waste.} =1{You already have 1 item out: unlock the statistics to see it.} other{You already have {count} items out: unlock the statistics to see them.}}',
                             '{count, plural, =0{Sbloccale per vedere cosa sprechi.} =1{Hai già 1 uscita registrata: sblocca le statistiche per vederla.} other{Hai già {count} uscite registrate: sblocca le statistiche per vederle.}}'),
    'stats_month': ('30 days', '30 giorni'),
    'stats_year': ('12 months', '12 mesi'),
    'stats_all': ('All time', 'Sempre'),
    'stats_empty': ('Nothing has come out of the freezer in this period yet.', 'In questo periodo dal freezer non è ancora uscito niente.'),
    'stats_wastedLabel': ('Thrown away', 'Buttato'),
    'stats_wastedLine': ('{discarded} of the {total} things taken out were thrown away', '{discarded} buttati su {total} usciti dal freezer'),
    'stats_averageStay': ('average time in the freezer', 'in media nel freezer'),
    'stats_mostWasted': ('most thrown away', 'il più buttato'),
    'stats_months': ('Last six months', 'Ultimi sei mesi'),
    'history_title': ('History', 'Storico'),
    'history_count': ('{count, plural, =0{Nothing out yet} =1{1 item out} other{{count} items out}}',
                      '{count, plural, =0{Ancora nessuna uscita} =1{1 uscita} other{{count} uscite}}'),
    'history_empty': ("When you mark something as eaten or thrown away, you'll find it here.", 'Quando segni qualcosa come consumato o buttato, lo trovi qui.'),
    'history_stayed': ('{days, plural, =0{same day} =1{1 day inside} other{{days} days inside}}', '{days, plural, =0{in giornata} =1{1 giorno dentro} other{{days} giorni dentro}}'),
    'item_wasConsumed': ('This was eaten.', 'Questo è stato consumato.'),
    'item_wasDiscarded': ('This was thrown away.', 'Questo è stato buttato.'),
    'item_putBack': ('Put back', 'Rimetti dentro'),

    # ── Ricerca ──
    'search_hint': ('Search the freezer', 'Cerca nel freezer'),
    'search_clear': ('Clear', 'Cancella'),
    'search_empty': ("Type a name or a word from the notes: accents and capitals don't matter.",
                     'Scrivi un nome o una parola delle note: accenti e maiuscole non contano.'),
    'search_noResults': ('Nothing in the freezer matches "{query}".', 'Nel freezer non c’è niente che corrisponda a «{query}».'),

    # ── Foto ──
    'photo_add': ('Add a photo', 'Aggiungi una foto'),
    'photo_camera': ('Take a photo', 'Scatta una foto'),
    'photo_gallery': ('Choose from gallery', 'Scegli dalla galleria'),
    'photo_change': ('Change', 'Cambia'),
    'photo_remove': ('Remove', 'Togli'),
    'photo_failed': ("The photo couldn't be loaded.", 'Non è stato possibile caricare la foto.'),

    # ── Alimento ──
    'item_newTitle': ('New item', 'Nuovo prodotto'),
    'item_editTitle': ('Item', 'Prodotto'),
    'item_category': ('Category', 'Categoria'),
    'item_quantity': ('Quantity', 'Quantità'),
    'item_frozenAt': ('Frozen on', 'Congelato il'),
    'item_daysAgo': ('{days, plural, =0{today} =1{1 day ago} other{{days} days ago}}',
                     '{days, plural, =0{oggi} =1{1 giorno fa} other{{days} giorni fa}}'),
    'item_daysShort': ('{days, plural, =0{today} other{{days} d}}', '{days, plural, =0{oggi} other{{days} gg}}'),
    'item_location': ('Where', 'Dove'),
    'item_volume': ('Space it takes', 'Spazio occupato'),
    'item_volumeAuto': ('{liters} (estimated)', '{liters} (stimato)'),
    'item_volumeManual': ('{liters} (set by you)', '{liters} (scelto da te)'),
    'item_reminder': ('Reminder after', 'Promemoria dopo'),
    'item_reminderSuffix': ('days', 'giorni'),
    'item_reminderHelp': ('Leave empty to use the category one: {days} days.',
                          'Lascia vuoto per usare quello della categoria: {days} giorni.'),
    'item_reminderHelpNone': ('Leave empty for no reminder.', 'Lascia vuoto per nessun promemoria.'),
    'item_reminderDisclaimer': ('A reminder to help you get organised, not an expiry date or a food safety guarantee.',
                                'È un promemoria organizzativo, non una scadenza né una garanzia di sicurezza alimentare.'),
    'item_note': ('Note', 'Nota'),
    'item_duplicate': ('I froze another one', 'Ne ho congelato un altro uguale'),
    'item_duplicated': ('Another {name} added, frozen today', 'Aggiunto un altro {name}, congelato oggi'),
    'item_consume': ('Eaten', 'Consumato'),
    'item_discard': ('Thrown away', 'Buttato'),
    'item_consumed': ('{name}: eaten', '{name}: consumato'),
    'item_discarded': ('{name}: thrown away', '{name}: buttato'),
    # ── Dati: CSV e backup ──
    'settings_data': ('Your data', 'I tuoi dati'),
    'csv_export': ('Export to a spreadsheet', 'Esporta in un foglio di calcolo'),
    'csv_exportBody': ("What's in the freezer, as a CSV file that opens in Excel.", "Cosa c'è nel freezer, in un file CSV che si apre con Excel."),
    'csv_subject': ('Full Freezer - what is in the freezer', 'Full Freezer - cosa c’è nel freezer'),
    'csv_name': ('Name', 'Nome'),
    'csv_unit': ('Unit', 'Unità'),
    'csv_days': ('Days in the freezer', 'Giorni nel freezer'),
    'csv_freezer': ('Freezer', 'Freezer'),
    'csv_compartment': ('Compartment', 'Scomparto'),
    'backup_create': ('Back up everything', 'Fai un backup di tutto'),
    'backup_createBody': ('Freezers, items, photos and history in one file, to keep or move to a new phone.',
                          'Freezer, prodotti, foto e storico in un solo file, da conservare o portare su un telefono nuovo.'),
    'backup_subject': ('Full Freezer backup', 'Backup di Full Freezer'),
    'backup_restore': ('Restore from a backup', 'Ripristina da un backup'),
    'backup_restoreBody': ('Bring back the data from a file made with "Back up everything".',
                           'Riporta i dati da un file fatto con «Fai un backup di tutto».'),
    'backup_restoreTitle': ('What to do with this backup?', 'Cosa faccio con questo backup?'),
    'backup_restoreSummary': ('It contains {freezers} freezers, {items} items inside and {history} in the history.',
                              'Contiene {freezers} freezer, {items} prodotti dentro e {history} nello storico.'),
    'backup_modeReplace': ('Replace everything', 'Sostituisci tutto'),
    'backup_modeReplaceBody': ("What's on this phone now is deleted and replaced by the backup.",
                               'Quello che c’è ora su questo telefono si cancella e al suo posto va il backup.'),
    'backup_modeMerge': ('Add to what I have', 'Aggiungi a quello che ho'),
    'backup_modeMergeBody': ('Freezers with the same name as one already here are skipped.',
                             'I freezer con lo stesso nome di uno già presente vengono saltati.'),
    'backup_restored': ('Backup restored', 'Backup ripristinato'),
    'backup_failed': ("That file isn't a Full Freezer backup, or it's damaged.", 'Quel file non è un backup di Full Freezer, o è rovinato.'),
}

TIPI = {
    'percent': 'int', 'count': 'int', 'n': 'int', 'days': 'int', 'discarded': 'int', 'total': 'int',
    'freezers': 'int', 'items': 'int', 'history': 'int',
}


def segnaposti(testo):
    import re
    nomi = []
    # Un segnaposto e' "{nome}" o "{nome, plural": non quello dopo "=1" o "other", che e'
    # il testo di un ramo del plurale ("=1{porzione}").
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
    for nome, dati in (('app_en.arb', en), ('app_it.arb', it)):
        (QUI / nome).write_text(json.dumps(dati, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    print(f'{len(TESTI)} chiavi scritte')


if __name__ == '__main__':
    main()

"""Carica su App Store Connect la scheda di QR Me e crea il prodotto Pro.

Gira **sul Mac** (usa tool/asc_api.py e la chiave API che vive solo li'):

    ssh mac 'cd ~/microapps && python3 -u apps/qr_me/tool/scheda_app_store.py'

Copia di apps/film_tracker/tool/scheda_app_store.py con i valori di QR Me:
- il **prodotto in-app** `qrme_pro_lifetime` (nome, descrizioni it/en, 1,99 EUR con territorio
  base Italia, tutti i paesi, screenshot per la revisione);
- le **anteprime video** iPhone 6,5" per lingua (saltate se il file manca);
- i diritti sui contenuti e la disponibilita' in tutti i paesi;
- in piu' rispetto a Film Tracker: **collega la build** `1.0.0 (BUILD)` alla versione se Apple
  l'ha gia' elaborata (`processingState == VALID`), e alla fine **stampa lo stato** di tutto
  (`verifica()`), cosi' un giro solo dice cosa manca.

Testi da store/scheda-app-store.md. E' **idempotente**: aggiorna quello che c'e', crea quello
che manca. Screenshot, anteprime e screenshot di revisione dell'IAP si confrontano per nome **e
contenuto** (`sourceFileChecksum`): se l'insieme remoto non e' identico ai file locali lo si
svuota e lo si ricarica in ordine (`gia_uguale`, `svuota`), cosi' un giro **sostituisce** e non
aggiunge doppioni. La build `BUILD` prende il posto di quella collegata quando e' VALID.

**Non invia in revisione**: lo fa il proprietario dopo la prova su iPad.

Restano a mano: etichetta privacy ("Dati non raccolti"), classificazione per eta', le risorse
"Intestazione" e "Risultati della ricerca", la spunta dell'acquisto in-app nella pagina della
versione (FIRST_NON_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION).
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

RADICE = Path(__file__).resolve().parents[3]
QUI = Path(__file__).resolve().parent.parent
APP = '6821086416'
VERSIONE = '1.0.0'
VERSIONE_TRASHCAN = 'c682f9c7-cf2a-4f46-9c1f-871adb0be6b3'
# ⚑ La 2 (F17.10: moduli rifatti, etichetta): `collega_build` sostituisce la build gia' collegata
#   se e' un'altra.
BUILD = '2'
LINGUE = {'it': 'it', 'en-GB': 'en'}
# ☠ «QR Me» in inglese e' gia' di un altro account (409 DUPLICATE.DIFFERENT_ACCOUNT, 2026-10-09,
#   come per Full Freezer e Film Tracker): in en-GB il ripiego gia' deciso in F17.0 punto 1,
#   «QR Me – Share & Scan». In italiano «QR Me» passa. Sotto l'icona resta «QR Me»
#   (CFBundleDisplayName): questo cambia solo lo store.
NOMI = {'it': 'QR Me', 'en-GB': 'QR Me – Share & Scan'}
CATEGORIE = ('UTILITIES', 'PRODUCTIVITY')

IAP_ID = 'qrme_pro_lifetime'
IAP_PREZZO = '1.99'
IAP_TESTI = {
    'it': ('QR Me Pro', 'Moduli, stile e logo, immagine ed etichetta, backup'),
    'en-GB': ('QR Me Pro', 'Forms, style and logo, image and label, backup'),
}
IAP_NOTA = ('One-time purchase that unlocks: the Wi-Fi, contact and pre-filled email forms, QR '
            'style (colours, shapes, logo), sharing the QR as an image or as a printable label, '
            'unlimited favourites and history, full backup. To test: tap any Forms chip on the home '
            'screen (e.g. Wi-Fi), or Settings > Discover QR Me Pro.')


def md5(file):
    return hashlib.md5(file.read_bytes()).hexdigest()


def gia_uguale(remoti, locali):
    """True se l'insieme remoto ha esattamente i file locali, nello stesso ordine e con lo stesso
    contenuto (nome e `sourceFileChecksum`). Altrimenti l'insieme va svuotato e ricaricato.

    ⚑ Confronto sul contenuto e non solo sul nome: dopo F17.10 gli scatti si chiamano come prima
    (`01-qr.png`) ma sono diversi, e il vecchio controllo «gia' presente per nome» li saltava.
    """
    return [(r['attributes'].get('fileName'), r['attributes'].get('sourceFileChecksum')) for r in remoti] == \
        [(f.name, md5(f)) for f in locali]


def svuota(tipo_risorsa, remoti):
    """Cancella gli asset di un insieme (screenshot o anteprime), uno per uno."""
    for r in remoti:
        api('DELETE', f"/v1/{tipo_risorsa}/{r['id']}")
        print('   tolto', r['attributes'].get('fileName'))


def api(metodo, percorso, corpo=None, tentativi=4):
    """asc_api.py con qualche tentativo: la rete del Mac verso Apple ogni tanto cade."""
    for i in range(tentativi):
        argomenti = ['python3', 'tool/asc_api.py', metodo, percorso] + ([json.dumps(corpo)] if corpo else [])
        out = subprocess.run(argomenti, capture_output=True, text=True, cwd=RADICE).stdout
        j = out.find('{')
        if j >= 0:
            return json.loads(out[j:])
        if metodo == 'DELETE' and 'HTTP 204' in out:
            return {}
        time.sleep(5 * (i + 1))
    raise RuntimeError(f'{metodo} {percorso}: nessuna risposta')


def controlla(r, cosa):
    if 'errors' in r:
        print('!!', cosa, json.dumps(r['errors'], ensure_ascii=False)[:600])
        return False
    print('ok', cosa)
    return True


def testi():
    s = (QUI / 'store' / 'scheda-app-store.md').read_text(encoding='utf-8')
    b = re.findall(r'```\n(.*?)\n```', s, re.S)
    sotto = dict(re.findall(r"\| Sottotitolo \((it|en-GB)\) \| `([^`]+)`", s))
    return {
        'it': {'promo': b[0], 'desc': b[1], 'kw': b[2], 'sottotitolo': sotto['it']},
        'en-GB': {'promo': b[3], 'desc': b[4], 'kw': b[5], 'sottotitolo': sotto['en-GB']},
        'note': b[6],
    }


def carica_file(percorso_risorsa, tipo, relazione, rel_tipo, rel_id, file, extra=None):
    dati = file.read_bytes()
    r = api('POST', percorso_risorsa, {'data': {'type': tipo,
        'attributes': {'fileName': file.name, 'fileSize': len(dati), **(extra or {})},
        'relationships': {relazione: {'data': {'type': rel_tipo, 'id': rel_id}}}}})
    if not controlla(r, f'prenotazione {file.name}'):
        return
    rid = r['data']['id']
    for op in r['data']['attributes']['uploadOperations']:
        req = urllib.request.Request(op['url'], data=dati[op['offset']:op['offset'] + op['length']], method=op['method'])
        for h in op['requestHeaders']:
            req.add_header(h['name'], h['value'])
        for prova in range(4):
            try:
                urllib.request.urlopen(req, timeout=300).read()
                break
            except Exception as e:  # la rete del Mac verso Apple cade: si riprova lo stesso pezzo
                if prova == 3:
                    raise
                print('   riprovo un pezzo di', file.name, e)
                time.sleep(5 * (prova + 1))
    r = api('PATCH', f'{percorso_risorsa}/{rid}', {'data': {'type': tipo, 'id': rid,
        'attributes': {'uploaded': True, 'sourceFileChecksum': hashlib.md5(dati).hexdigest()}}})
    controlla(r, f'caricato {file.name}')


def tutti_i_territori():
    r = api('GET', '/v1/territories?limit=200')
    return [t['id'] for t in r['data']]


def prodotto_pro():
    """Il non consumabile: crea, traduce, prezza, rende disponibile, screenshot per la revisione."""
    trovati = api('GET', f'/v1/apps/{APP}/inAppPurchasesV2?filter[productId]={IAP_ID}')['data']
    if trovati:
        iap = trovati[0]['id']
        print('ok prodotto gia presente', iap)
    else:
        r = api('POST', '/v2/inAppPurchases', {'data': {'type': 'inAppPurchases', 'attributes': {
            'name': 'QR Me Pro', 'productId': IAP_ID, 'inAppPurchaseType': 'NON_CONSUMABLE',
            'familySharable': False, 'reviewNote': IAP_NOTA},
            'relationships': {'app': {'data': {'type': 'apps', 'id': APP}}}}})
        if not controlla(r, 'prodotto creato'):
            return
        iap = r['data']['id']

    righe = api('GET', f'/v2/inAppPurchases/{iap}/inAppPurchaseLocalizations')['data']
    locs = {l['attributes']['locale']: l['id'] for l in righe}
    attuali = {l['attributes']['locale']: l['attributes'] for l in righe}
    for loc, (nome, desc) in IAP_TESTI.items():
        attr = {'name': nome, 'description': desc}
        # ☠ Una PATCH con gli stessi valori, a prodotto READY_TO_SUBMIT, risponde 409
        #   ENTITY_ERROR.ATTRIBUTE.INVALID.UNMODIFIABLE (2026-10-09): se sono gia' giusti non si tocca.
        if loc in attuali and attuali[loc].get('name') == nome and attuali[loc].get('description') == desc:
            print('ok prodotto, testi gia giusti', loc)
            continue
        if loc in locs:
            r = api('PATCH', f'/v1/inAppPurchaseLocalizations/{locs[loc]}',
                    {'data': {'type': 'inAppPurchaseLocalizations', 'id': locs[loc], 'attributes': attr}})
        else:
            r = api('POST', '/v1/inAppPurchaseLocalizations', {'data': {'type': 'inAppPurchaseLocalizations',
                'attributes': {'locale': loc, **attr},
                'relationships': {'inAppPurchaseV2': {'data': {'type': 'inAppPurchases', 'id': iap}}}}})
        controlla(r, f'prodotto, testi {loc}')

    if api('GET', f'/v2/inAppPurchases/{iap}/iapPriceSchedule').get('data'):
        print('ok prezzo gia impostato')
    else:
        punti = api('GET', f'/v2/inAppPurchases/{iap}/pricePoints?filter[territory]=ITA&limit=200')['data']
        punto = next(p for p in punti if p['attributes']['customerPrice'] == IAP_PREZZO)
        controlla(api('POST', '/v1/inAppPurchasePriceSchedules', {'data': {'type': 'inAppPurchasePriceSchedules',
            'relationships': {
                'inAppPurchase': {'data': {'type': 'inAppPurchases', 'id': iap}},
                'baseTerritory': {'data': {'type': 'territories', 'id': 'ITA'}},
                'manualPrices': {'data': [{'type': 'inAppPurchasePrices', 'id': '${p0}'}]}}},
            'included': [{'type': 'inAppPurchasePrices', 'id': '${p0}', 'attributes': {'startDate': None},
                          'relationships': {'inAppPurchasePricePoint': {'data': {
                              'type': 'inAppPurchasePricePoints', 'id': punto['id']}}}}]}),
            f'prezzo {IAP_PREZZO} EUR')

    if api('GET', f'/v2/inAppPurchases/{iap}/inAppPurchaseAvailability').get('data'):
        print('ok disponibilita prodotto gia impostata')
    else:
        controlla(api('POST', '/v1/inAppPurchaseAvailabilities', {'data': {'type': 'inAppPurchaseAvailabilities',
            'attributes': {'availableInNewTerritories': True},
            'relationships': {
                'inAppPurchase': {'data': {'type': 'inAppPurchases', 'id': iap}},
                'availableTerritories': {'data': [{'type': 'territories', 'id': t} for t in tutti_i_territori()]}}}}),
            'prodotto disponibile ovunque')

    attuale = api('GET', f'/v2/inAppPurchases/{iap}').get('data', {}).get('attributes', {})
    if attuale.get('reviewNote') == IAP_NOTA:
        print('ok nota di revisione del prodotto gia giusta')
    else:
        controlla(api('PATCH', f'/v2/inAppPurchases/{iap}', {'data': {'type': 'inAppPurchases', 'id': iap,
            'attributes': {'reviewNote': IAP_NOTA}}}), 'prodotto, nota di revisione')

    # ⚑ Lo screenshot del paywall si sostituisce se e' cambiato (F17.10: riga dell'etichetta).
    paywall = QUI / 'store' / 'screenshots' / 'ios' / 'it' / 'paywall-revisione.png'
    sc = api('GET', f'/v2/inAppPurchases/{iap}/appStoreReviewScreenshot').get('data')
    if sc and sc['attributes'].get('sourceFileChecksum') == md5(paywall):
        print('ok screenshot di revisione gia uguale')
    else:
        # ☠ Con il prodotto READY_TO_SUBMIT Apple NON lascia toccare via API ne' lo screenshot di
        #   revisione (DELETE 409 MEDIA_ASSET_DELETE_NOT_ALLOWED, POST 409 reviewScreenshot
        #   UNMODIFIABLE) ne' nome/descrizione localizzati (409 UNMODIFIABLE anche con la sola
        #   descrizione): si sostituiscono a mano in App Store Connect (2026-10-09). La reviewNote
        #   invece passa (anche se a volte la PATCH risponde 500: rileggere).
        if sc:
            r = api('DELETE', f"/v1/inAppPurchaseAppStoreReviewScreenshots/{sc['id']}")
            if 'errors' in r:
                print('!! screenshot di revisione: Apple non lo lascia sostituire via API in stato',
                      attuale.get('state'), '- va cambiato a mano con', paywall.name)
                return
            print('   tolto lo screenshot di revisione vecchio')
        carica_file('/v1/inAppPurchaseAppStoreReviewScreenshots', 'inAppPurchaseAppStoreReviewScreenshots',
                    'inAppPurchaseV2', 'inAppPurchases', iap,
                    QUI / 'store' / 'screenshots' / 'ios' / 'it' / 'paywall-revisione.png')


def main():
    t = testi()

    # ── Diritti sui contenuti e disponibilita' ──────────────────────────────────
    controlla(api('PATCH', f'/v1/apps/{APP}', {'data': {'type': 'apps', 'id': APP,
        'attributes': {'contentRightsDeclaration': 'DOES_NOT_USE_THIRD_PARTY_CONTENT'}}}), 'diritti sui contenuti')
    disp = api('GET', f'/v1/apps/{APP}/appAvailabilityV2')
    if disp.get('data'):
        print('ok disponibilita app gia impostata')
    else:
        territori = tutti_i_territori()
        controlla(api('POST', '/v2/appAvailabilities', {'data': {'type': 'appAvailabilities',
            'attributes': {'availableInNewTerritories': True},
            'relationships': {
                'app': {'data': {'type': 'apps', 'id': APP}},
                'territoryAvailabilities': {'data': [{'type': 'territoryAvailabilities', 'id': f'${{t{i}}}'}
                                                     for i in range(len(territori))]}}},
            'included': [{'type': 'territoryAvailabilities', 'id': f'${{t{i}}}', 'attributes': {'available': True},
                          'relationships': {'territory': {'data': {'type': 'territories', 'id': tid}}}}
                         for i, tid in enumerate(territori)]}), f'app disponibile in {len(territori)} paesi')

    # ── Informazioni sull'app: categorie, nomi, sottotitoli, privacy ────────────
    info = [i for i in api('GET', f'/v1/apps/{APP}/appInfos')['data']
            if i['attributes'].get('appStoreState', i['attributes'].get('state')) in ('PREPARE_FOR_SUBMISSION', None)
            or i['attributes'].get('state') == 'PREPARE_FOR_SUBMISSION'][0]
    controlla(api('PATCH', f"/v1/appInfos/{info['id']}", {'data': {'type': 'appInfos', 'id': info['id'], 'relationships': {
        'primaryCategory': {'data': {'type': 'appCategories', 'id': CATEGORIE[0]}},
        'secondaryCategory': {'data': {'type': 'appCategories', 'id': CATEGORIE[1]}}}}}), 'categorie')
    loc_info = {l['attributes']['locale']: l for l in api('GET', f"/v1/appInfos/{info['id']}/appInfoLocalizations")['data']}
    for loc in LINGUE:
        attr = {'name': NOMI[loc], 'subtitle': t[loc]['sottotitolo'],
                'privacyPolicyUrl': 'https://smpmicroapps.it/legale/privacy'}
        if loc in loc_info:
            r = api('PATCH', f"/v1/appInfoLocalizations/{loc_info[loc]['id']}",
                    {'data': {'type': 'appInfoLocalizations', 'id': loc_info[loc]['id'], 'attributes': attr}})
        else:
            r = api('POST', '/v1/appInfoLocalizations', {'data': {'type': 'appInfoLocalizations',
                'attributes': {'locale': loc, **attr},
                'relationships': {'appInfo': {'data': {'type': 'appInfos', 'id': info['id']}}}}})
        controlla(r, f'informazioni app {loc}')

    # ── La versione: numero, copyright, rilascio manuale ────────────────────────
    ver = [v for v in api('GET', f'/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS')['data']
           if v['attributes']['appStoreState'] == 'PREPARE_FOR_SUBMISSION'][0]
    controlla(api('PATCH', f"/v1/appStoreVersions/{ver['id']}", {'data': {'type': 'appStoreVersions', 'id': ver['id'],
        'attributes': {'versionString': VERSIONE, 'copyright': '2026 SeeMyPage di Ronconi Riccardo',
                       'releaseType': 'MANUAL'}}}), f'versione {VERSIONE}')

    # ── Testi, screenshot e anteprime, per lingua ───────────────────────────────
    loc_ver = {l['attributes']['locale']: l for l in api('GET', f"/v1/appStoreVersions/{ver['id']}/appStoreVersionLocalizations")['data']}
    for loc, cartella in LINGUE.items():
        attr = {'description': t[loc]['desc'], 'keywords': t[loc]['kw'], 'promotionalText': t[loc]['promo'],
                'supportUrl': 'https://smpmicroapps.it/contatti', 'marketingUrl': 'https://smpmicroapps.it'}
        if loc in loc_ver:
            lid = loc_ver[loc]['id']
            r = api('PATCH', f'/v1/appStoreVersionLocalizations/{lid}',
                    {'data': {'type': 'appStoreVersionLocalizations', 'id': lid, 'attributes': attr}})
        else:
            r = api('POST', '/v1/appStoreVersionLocalizations', {'data': {'type': 'appStoreVersionLocalizations',
                'attributes': {'locale': loc, **attr},
                'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': ver['id']}}}}})
            lid = r.get('data', {}).get('id')
        if not controlla(r, f'testi versione {loc}') or not lid:
            continue

        # ⚑ Due spazi: 6,5" (obbligatorio, 1284x2778) e 6,9" (APP_IPHONE_67, 1320x2868). Film
        #   Tracker caricava solo il 6,5"; qui anche il 6,9", cosi' i telefoni grandi non
        #   ricavano le schede rimpicciolendo.
        insiemi = api('GET', f'/v1/appStoreVersionLocalizations/{lid}/appScreenshotSets')['data']
        for tipo, sorgente in (('APP_IPHONE_65', 'appstore-6.5'), ('APP_IPHONE_67', 'appstore')):
            insieme = next((s for s in insiemi if s['attributes']['screenshotDisplayType'] == tipo), None)
            if insieme is None:
                r = api('POST', '/v1/appScreenshotSets', {'data': {'type': 'appScreenshotSets',
                    'attributes': {'screenshotDisplayType': tipo},
                    'relationships': {'appStoreVersionLocalization': {'data': {'type': 'appStoreVersionLocalizations', 'id': lid}}}}})
                if not controlla(r, f'insieme screenshot {tipo} {loc}'):
                    continue
                insieme = r['data']
            remoti = api('GET', f"/v1/appScreenshotSets/{insieme['id']}/appScreenshots?limit=50")['data']
            locali = sorted((QUI / 'store' / 'grafiche' / sorgente / cartella).glob('*.png'))
            if gia_uguale(remoti, locali):
                print('screenshot gia uguali', loc, tipo, len(locali))
                continue
            # ⚑ Sostituire, non aggiungere: si svuota l'insieme e si ricarica tutto in ordine (la
            #   posizione in App Store Connect e' l'ordine di caricamento).
            svuota('appScreenshots', remoti)
            for f in locali:
                carica_file('/v1/appScreenshots', 'appScreenshots', 'appScreenshotSet', 'appScreenshotSets', insieme['id'], f)

        # Il video: 886x1920, va nello spazio iPhone 6,5".
        video = QUI / 'store' / 'video' / f'anteprima-886x1920-{cartella}.mp4'
        if not video.exists():
            print('!! manca', video.name, '- anteprima saltata')
            continue
        insiemi = api('GET', f'/v1/appStoreVersionLocalizations/{lid}/appPreviewSets')['data']
        insieme = next((s for s in insiemi if s['attributes']['previewType'] == 'IPHONE_65'), None)
        if insieme is None:
            r = api('POST', '/v1/appPreviewSets', {'data': {'type': 'appPreviewSets',
                'attributes': {'previewType': 'IPHONE_65'},
                'relationships': {'appStoreVersionLocalization': {'data': {'type': 'appStoreVersionLocalizations', 'id': lid}}}}})
            if not controlla(r, f'insieme anteprime 6,5" {loc}'):
                continue
            insieme = r['data']
        remoti = api('GET', f"/v1/appPreviewSets/{insieme['id']}/appPreviews")['data']
        if gia_uguale(remoti, [video]):
            print('anteprima gia uguale', loc, video.name)
        else:
            svuota('appPreviews', remoti)
            carica_file('/v1/appPreviews', 'appPreviews', 'appPreviewSet', 'appPreviewSets', insieme['id'], video,
                        extra={'mimeType': 'video/mp4', 'previewFrameTimeCode': '00:00:01:00'})

    # ── Revisione: contatti (da TrashCan) e note ────────────────────────────────
    tc = api('GET', f'/v1/appStoreVersions/{VERSIONE_TRASHCAN}/appStoreReviewDetail')['data']['attributes']
    attr = {k: tc[k] for k in ('contactFirstName', 'contactLastName', 'contactPhone')}
    attr.update({'contactEmail': 'info@smp-digital.it', 'demoAccountRequired': False, 'notes': t['note']})
    esistente = api('GET', f"/v1/appStoreVersions/{ver['id']}/appStoreReviewDetail").get('data')
    if esistente:
        r = api('PATCH', f"/v1/appStoreReviewDetails/{esistente['id']}",
                {'data': {'type': 'appStoreReviewDetails', 'id': esistente['id'], 'attributes': attr}})
    else:
        r = api('POST', '/v1/appStoreReviewDetails', {'data': {'type': 'appStoreReviewDetails', 'attributes': attr,
            'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': ver['id']}}}}})
    controlla(r, 'informazioni per la revisione')

    # ── Classificazione per eta': tutto "Nessuno"/"No" (4+) ──────────────────────
    eta(info['id'])

    # ── Prezzo dell'app: gratuita ───────────────────────────────────────────────
    # ☠ Il listino si legge da /v1/appPriceSchedules/{id}/manualPrices: il percorso annidato
    #   /v1/apps/{id}/appPriceSchedule/manualPrices risponde con un errore e il listino veniva
    #   ricreato a ogni giro (innocuo ma inutile; stesso difetto nello script di Film Tracker).
    listino = api('GET', f'/v1/apps/{APP}/appPriceSchedule').get('data', {}).get('id')
    if listino and api('GET', f'/v1/appPriceSchedules/{listino}/manualPrices').get('data'):
        print('ok prezzo app gia impostato')
    else:
        punti = api('GET', f'/v1/apps/{APP}/appPricePoints?filter[territory]=ITA&limit=5')['data']
        gratis = next(p for p in punti if float(p['attributes']['customerPrice']) == 0)
        controlla(api('POST', '/v1/appPriceSchedules', {'data': {'type': 'appPriceSchedules', 'relationships': {
            'app': {'data': {'type': 'apps', 'id': APP}},
            'baseTerritory': {'data': {'type': 'territories', 'id': 'ITA'}},
            'manualPrices': {'data': [{'type': 'appPrices', 'id': '${p0}'}]}}},
            'included': [{'type': 'appPrices', 'id': '${p0}', 'attributes': {'startDate': None},
                          'relationships': {'appPricePoint': {'data': {'type': 'appPricePoints', 'id': gratis['id']}}}}]}),
            'prezzo gratuito')

    # ── Il prodotto Pro ─────────────────────────────────────────────────────────
    prodotto_pro()

    # ── La build, se Apple l'ha gia' elaborata ──────────────────────────────────
    collega_build(ver['id'])

    verifica(ver['id'])


def eta(info_id):
    """La dichiarazione per l'eta' dell'appInfo: ogni campo a "NONE" (frequenza) o False (si/no).

    ⚑ Si leggono gli attributi che Apple restituisce e si scrive il "no" per ciascuno secondo il
    tipo del valore gia' presente o del nome: cosi' i campi nuovi del questionario (Apple lo
    allunga) non restano vuoti. `kidsAgeBand` e i campi di livello non si toccano.
    """
    r = api('GET', f'/v1/appInfos/{info_id}/ageRatingDeclaration')
    if not r.get('data'):
        print('!! dichiarazione per l eta non trovata')
        return
    d = r['data']
    attr = {}
    for k, v in d['attributes'].items():
        # ☠ `gracRatingClassificationNumber` (Corea) si puo' scrivere solo con un override coreano:
        #   scriverlo a NONE da' 409 KOREA_AGE_RATING_OVERRIDE_INVALID (2026-10-09). Fuori.
        if k in ('kidsAgeBand', 'ageRatingOverride', 'ageRatingOverrideV2', 'koreaAgeRatingOverride',
                 'developerAgeRatingInfoUrl', 'gracRatingClassificationNumber'):
            continue
        if isinstance(v, bool) or (v is None and (k.startswith('is') or k in (
                'gambling', 'lootBox', 'unrestrictedWebAccess', 'seventeenPlus', 'messagingAndChat',
                'parentalControls', 'ageAssurance', 'userGeneratedContent', 'advertising',
                'healthOrWellnessTopics'))):
            attr[k] = False
        elif v is None or isinstance(v, str):
            attr[k] = 'NONE'
    controlla(api('PATCH', f"/v1/ageRatingDeclarations/{d['id']}",
                  {'data': {'type': 'ageRatingDeclarations', 'id': d['id'], 'attributes': attr}}),
              f'classificazione per eta ({len(attr)} campi)')


def collega_build(versione_id):
    """Collega la build `VERSIONE (BUILD)` alla versione, solo se e' gia' VALID."""
    gia = api('GET', f'/v1/appStoreVersions/{versione_id}/build').get('data')
    if gia and gia['attributes'].get('version') == BUILD:
        print('ok build gia collegata', gia['id'], gia['attributes'].get('version'))
        return
    if gia:
        # ⚑ Un'altra build (la 1 dopo F17.10): si sostituisce, ma solo quando la nuova e' VALID;
        #   fino ad allora resta collegata la vecchia (la versione non resta mai senza build).
        print('build collegata', gia['attributes'].get('version'), '-> da sostituire con la', BUILD)
    builds = api('GET', f'/v1/builds?filter[app]={APP}&filter[version]={BUILD}'
                        f'&filter[preReleaseVersion.version]={VERSIONE}&limit=5')['data']
    if not builds:
        print('!! build', VERSIONE, f'({BUILD})', 'non ancora su App Store Connect: rilanciare piu tardi')
        return
    b = builds[0]
    stato = b['attributes'].get('processingState')
    if stato != 'VALID':
        print('!! build', b['id'], 'in stato', stato, ': rilanciare quando e VALID')
        return
    # ⚑ La relazione si scrive con una PATCH della versione stessa (risposta JSON), non con
    #   /relationships/build: quella risponde 204 senza corpo e asc_api non la leggeva (2026-10-09).
    r = api('PATCH', f'/v1/appStoreVersions/{versione_id}', {'data': {'type': 'appStoreVersions',
        'id': versione_id, 'relationships': {'build': {'data': {'type': 'builds', 'id': b['id']}}}}})
    if not controlla(r, 'build collegata (risposta)'):
        return
    ora = api('GET', f'/v1/appStoreVersions/{versione_id}/build').get('data')
    print('ok build collegata' if ora and ora['id'] == b['id'] else '!! build NON collegata', b['id'])


def verifica(versione_id):
    """Lo stato di tutto, letto da Apple: screenshot, anteprime, prodotto, build."""
    print('\n-- verifica --')
    doppioni = []
    vecchi = []
    v = api('GET', f'/v1/appStoreVersions/{versione_id}')['data']['attributes']
    print('versione', v['versionString'], v['appStoreState'], 'rilascio', v.get('releaseType'))
    for l in api('GET', f'/v1/appStoreVersions/{versione_id}/appStoreVersionLocalizations')['data']:
        lid = l['id']
        a = l['attributes']
        print(a['locale'], 'testi:', len(a.get('description') or ''), 'desc,',
              len(a.get('keywords') or ''), 'kw,', len(a.get('promotionalText') or ''), 'promo')
        for s in api('GET', f'/v1/appStoreVersionLocalizations/{lid}/appScreenshotSets')['data']:
            righe = api('GET', f"/v1/appScreenshotSets/{s['id']}/appScreenshots?limit=50")['data']
            nomi = [x['attributes'].get('fileName') for x in righe]
            stati = [x['attributes']['assetDeliveryState']['state'] for x in righe]
            print('   screenshot', s['attributes']['screenshotDisplayType'], len(righe), nomi, stati)
            if len(set(nomi)) != len(nomi):
                doppioni.append(f"{a['locale']} {s['attributes']['screenshotDisplayType']}")
        for s in api('GET', f'/v1/appStoreVersionLocalizations/{lid}/appPreviewSets')['data']:
            righe = api('GET', f"/v1/appPreviewSets/{s['id']}/appPreviews")['data']
            stati = [(x['attributes'].get('fileName'), x['attributes']['assetDeliveryState']['state']) for x in righe]
            print('   anteprime', s['attributes']['previewType'], stati)
            if len(righe) != 1:
                doppioni.append(f"{a['locale']} anteprime {s['attributes']['previewType']} ({len(righe)})")
    for p in api('GET', f'/v1/apps/{APP}/inAppPurchasesV2?filter[productId]={IAP_ID}')['data']:
        print('prodotto', p['id'], p['attributes']['productId'], p['attributes']['state'])
    b = api('GET', f'/v1/appStoreVersions/{versione_id}/build').get('data')
    print('build', (b['id'], b['attributes'].get('version'), b['attributes'].get('processingState')) if b else 'nessuna')

    vuoti = []

    def campo(cosa, valore):
        print('  ', cosa, '=', repr(valore)[:90])
        if valore in (None, '', [], {}):
            vuoti.append(cosa)

    print('\n-- campo per campo --')
    a = api('GET', f'/v1/apps/{APP}')['data']['attributes']
    campo('app.contentRightsDeclaration', a.get('contentRightsDeclaration'))
    campo('app.primaryLocale', a.get('primaryLocale'))
    info = [i for i in api('GET', f'/v1/apps/{APP}/appInfos')['data']
            if i['attributes'].get('state') != 'READY_FOR_DISTRIBUTION'][0]
    campo('appInfo.primaryCategory', (api('GET', f"/v1/appInfos/{info['id']}/primaryCategory").get('data') or {}).get('id'))
    campo('appInfo.secondaryCategory', (api('GET', f"/v1/appInfos/{info['id']}/secondaryCategory").get('data') or {}).get('id'))
    eta_d = api('GET', f"/v1/appInfos/{info['id']}/ageRatingDeclaration").get('data') or {}
    nulli = [k for k, v in (eta_d.get('attributes') or {}).items() if v is None and k not in (
        'kidsAgeBand', 'ageRatingOverride', 'ageRatingOverrideV2', 'koreaAgeRatingOverride', 'developerAgeRatingInfoUrl',
        'gracRatingClassificationNumber')]
    campo('eta: campi ancora vuoti', nulli or 'nessuno')
    if nulli:
        vuoti.append('eta')
    for l in api('GET', f"/v1/appInfos/{info['id']}/appInfoLocalizations")['data']:
        la = l['attributes']
        for k in ('name', 'subtitle', 'privacyPolicyUrl'):
            campo(f"appInfo[{la['locale']}].{k}", la.get(k))
    for l in api('GET', f'/v1/appStoreVersions/{versione_id}/appStoreVersionLocalizations')['data']:
        la = l['attributes']
        for k in ('description', 'keywords', 'promotionalText', 'supportUrl', 'marketingUrl'):
            campo(f"versione[{la['locale']}].{k}", la.get(k))
    va = api('GET', f'/v1/appStoreVersions/{versione_id}')['data']['attributes']
    for k in ('versionString', 'copyright', 'releaseType'):
        campo(f'versione.{k}', va.get(k))
    rd = (api('GET', f'/v1/appStoreVersions/{versione_id}/appStoreReviewDetail').get('data') or {}).get('attributes') or {}
    for k in ('contactFirstName', 'contactLastName', 'contactPhone', 'contactEmail', 'notes'):
        campo(f'revisione.{k}', rd.get(k))
    campo('revisione.demoAccountRequired', rd.get('demoAccountRequired'))
    listino = api('GET', f'/v1/apps/{APP}/appPriceSchedule').get('data', {}).get('id')
    prezzi = api('GET', f'/v1/appPriceSchedules/{listino}/manualPrices?include=appPricePoint')
    campo('app.prezzo', [x['attributes'].get('customerPrice') for x in prezzi.get('included', [])
                         if x['type'] == 'appPricePoints'])
    disp = api('GET', f'/v1/apps/{APP}/appAvailabilityV2').get('data') or {}
    campo('app.disponibilita', (disp.get('attributes') or {}).get('availableInNewTerritories'))
    for p in api('GET', f'/v1/apps/{APP}/inAppPurchasesV2?filter[productId]={IAP_ID}')['data']:
        pa = p['attributes']
        for k in ('name', 'productId', 'inAppPurchaseType', 'state', 'reviewNote'):
            campo(f'iap.{k}', pa.get(k))
        for l in api('GET', f"/v2/inAppPurchases/{p['id']}/inAppPurchaseLocalizations")['data']:
            campo(f"iap[{l['attributes']['locale']}]", (l['attributes'].get('name'), l['attributes'].get('description')))
            atteso = IAP_TESTI.get(l['attributes']['locale'])
            if atteso and atteso != (l['attributes'].get('name'), l['attributes'].get('description')):
                vecchi.append(f"iap[{l['attributes']['locale']}] testi (atteso {atteso[1]!r}: a mano)")
        campo('iap.prezzo', bool(api('GET', f"/v2/inAppPurchases/{p['id']}/iapPriceSchedule").get('data')))
        campo('iap.disponibilita', bool(api('GET', f"/v2/inAppPurchases/{p['id']}/inAppPurchaseAvailability").get('data')))
        sc = (api('GET', f"/v2/inAppPurchases/{p['id']}/appStoreReviewScreenshot").get('data') or {}).get('attributes') or {}
        campo('iap.screenshot revisione', (sc.get('fileName'), (sc.get('assetDeliveryState') or {}).get('state')))
        if sc.get('sourceFileChecksum') != md5(QUI / 'store' / 'screenshots' / 'ios' / 'it' / 'paywall-revisione.png'):
            vecchi.append('iap.screenshot revisione diverso da paywall-revisione.png (a mano)')
    if not b or b['attributes'].get('version') != BUILD:
        vuoti.append(f'build collegata diversa dalla {BUILD}')
    print('\nVUOTI:', vuoti or 'nessuno')
    print('DOPPIONI:', doppioni or 'nessuno')
    print('DA FARE A MANO (Apple non li lascia cambiare via API):', vecchi or 'nessuno')


if __name__ == '__main__':
    os.chdir(RADICE)
    sys.exit(main())

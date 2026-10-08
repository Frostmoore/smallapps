"""Carica su App Store Connect la scheda di Scorte Calore e crea il prodotto Pro.

Gira **sul Mac** (usa tool/asc_api.py e la chiave API che vive solo li'):

    ssh mac 'cd ~/microapps && python3 apps/scorte_calore/tool/scheda_app_store.py'

Ricalcato su apps/full_freezer/tool/scheda_app_store.py, piu':
- il **prodotto in-app** `scortecalore_pro_lifetime` (nome, descrizioni it/en, 2,99 € con
  territorio base Italia, tutti i paesi, screenshot per la revisione);
- le **anteprime video** iPhone 6,5" per lingua;
- i diritti sui contenuti e la disponibilita' in tutti i paesi.

Testi da store/scheda-app-store.md. E' **idempotente**: aggiorna quello che c'e', crea quello
che manca, non ricarica un file gia' presente con lo stesso nome.

Restano a mano: etichetta privacy ("Dati non raccolti"), classificazione per eta', le risorse
"Intestazione" e "Risultati della ricerca", il collegamento di build e acquisto in-app alla
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
APP = '6820405604'
VERSIONE = '1.0.0'
VERSIONE_TRASHCAN = 'c682f9c7-cf2a-4f46-9c1f-871adb0be6b3'
LINGUE = {'it': 'it', 'en-GB': 'en'}
NOMI = {'it': 'Scorte Calore', 'en-GB': 'Scorte Calore – Fuel Tracker'}

IAP_ID = 'scortecalore_pro_lifetime'
IAP_PREZZO = '2.99'
IAP_TESTI = {
    'it': ('Scorte Calore Pro', 'Tutte le fonti, notifiche, storico, costi e calendario'),
    'en-GB': ('Scorte Calore Pro', 'All heat sources, alerts, history, costs and calendar'),
}
IAP_NOTA = ('One-time purchase that unlocks: more than one heat source, reorder notifications, '
            'full history and charts, purchases and costs, the reorder date in the calendar, CSV '
            'export and full backup. To test: Settings > Scorte Calore Pro, or tap any item marked PRO.')


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
            'name': 'Scorte Calore Pro', 'productId': IAP_ID, 'inAppPurchaseType': 'NON_CONSUMABLE',
            'familySharable': False, 'reviewNote': IAP_NOTA},
            'relationships': {'app': {'data': {'type': 'apps', 'id': APP}}}}})
        if not controlla(r, 'prodotto creato'):
            return
        iap = r['data']['id']

    locs = {l['attributes']['locale']: l['id'] for l in
            api('GET', f'/v2/inAppPurchases/{iap}/inAppPurchaseLocalizations')['data']}
    for loc, (nome, desc) in IAP_TESTI.items():
        attr = {'name': nome, 'description': desc}
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

    if api('GET', f'/v2/inAppPurchases/{iap}/appStoreReviewScreenshot').get('data'):
        print('ok screenshot di revisione gia presente')
    else:
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
        'primaryCategory': {'data': {'type': 'appCategories', 'id': 'UTILITIES'}},
        'secondaryCategory': {'data': {'type': 'appCategories', 'id': 'LIFESTYLE'}}}}}), 'categorie')
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

        insiemi = api('GET', f'/v1/appStoreVersionLocalizations/{lid}/appScreenshotSets')['data']
        insieme = next((s for s in insiemi if s['attributes']['screenshotDisplayType'] == 'APP_IPHONE_65'), None)
        if insieme is None:
            r = api('POST', '/v1/appScreenshotSets', {'data': {'type': 'appScreenshotSets',
                'attributes': {'screenshotDisplayType': 'APP_IPHONE_65'},
                'relationships': {'appStoreVersionLocalization': {'data': {'type': 'appStoreVersionLocalizations', 'id': lid}}}}})
            if not controlla(r, f'insieme screenshot 6,5" {loc}'):
                continue
            insieme = r['data']
        presenti = {s['attributes']['fileName'] for s in api('GET', f"/v1/appScreenshotSets/{insieme['id']}/appScreenshots")['data']}
        for f in sorted((QUI / 'store' / 'grafiche' / 'appstore-6.5' / cartella).glob('*.png')):
            if f.name in presenti:
                print('gia presente', loc, f.name)
                continue
            carica_file('/v1/appScreenshots', 'appScreenshots', 'appScreenshotSet', 'appScreenshotSets', insieme['id'], f)

        # Il video: 886x1920, va nello spazio iPhone 6,5".
        video = QUI / 'store' / 'video' / f'anteprima-886x1920-{cartella}.mp4'
        insiemi = api('GET', f'/v1/appStoreVersionLocalizations/{lid}/appPreviewSets')['data']
        insieme = next((s for s in insiemi if s['attributes']['previewType'] == 'IPHONE_65'), None)
        if insieme is None:
            r = api('POST', '/v1/appPreviewSets', {'data': {'type': 'appPreviewSets',
                'attributes': {'previewType': 'IPHONE_65'},
                'relationships': {'appStoreVersionLocalization': {'data': {'type': 'appStoreVersionLocalizations', 'id': lid}}}}})
            if not controlla(r, f'insieme anteprime 6,5" {loc}'):
                continue
            insieme = r['data']
        presenti = {s['attributes']['fileName'] for s in api('GET', f"/v1/appPreviewSets/{insieme['id']}/appPreviews")['data']}
        if video.name in presenti:
            print('gia presente', loc, video.name)
        else:
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

    # ── Prezzo dell'app: gratuita ───────────────────────────────────────────────
    if api('GET', f'/v1/apps/{APP}/appPriceSchedule').get('data', {}).get('id') and \
            api('GET', f'/v1/apps/{APP}/appPriceSchedule/manualPrices').get('data'):
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


if __name__ == '__main__':
    os.chdir(RADICE)
    sys.exit(main())

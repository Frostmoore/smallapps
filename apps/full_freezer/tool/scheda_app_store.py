"""Carica su App Store Connect la scheda di Full Freezer, dai testi di store/scheda-app-store.md.

Gira **sul Mac** (usa tool/asc_api.py e la chiave API che vive solo li'):

    ssh mac 'cd ~/microapps && python3 apps/full_freezer/tool/scheda_app_store.py'

Fa via API tutto quello che l'API permette: categorie, sottotitoli e URL della privacy,
numero di versione e copyright, testi della versione in italiano e inglese, screenshot iPhone
6,5", note e contatti per la revisione, prezzo gratuito. E' **idempotente**: aggiorna quello
che c'e', crea quello che manca, e non ricarica uno screenshot gia' presente con lo stesso nome.

Restano a mano (l'API non li fa, o non bene): etichetta privacy ("Dati non raccolti"),
classificazione per eta', diritti sui contenuti, disponibilita' nei paesi, e il collegamento
di build e acquisto in-app alla versione (il primo non consumabile si allega dalla pagina
della versione: FIRST_NON_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION).

I recapiti per la revisione si copiano da quelli di TrashCan, cosi' il telefono non sta nel repo.
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
APP = '6820155659'
VERSIONE = '1.0.0'
VERSIONE_TRASHCAN = 'c682f9c7-cf2a-4f46-9c1f-871adb0be6b3'
LINGUE = {'it': 'it', 'en-GB': 'en'}

# ☠ In inglese "Full Freezer" e' gia' usato da un altro sviluppatore (409
#   DUPLICATE.DIFFERENT_ACCOUNT, 2026-10-07): il nome della scheda inglese e' diverso.
#   Sotto l'icona resta "Full Freezer" (CFBundleDisplayName), questo cambia solo lo store.
NOMI = {'it': 'Full Freezer', 'en-GB': 'Full Freezer – Freezer Tracker'}


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


def carica_file(percorso_risorsa, tipo, relazione, rel_tipo, rel_id, file):
    dati = file.read_bytes()
    r = api('POST', percorso_risorsa, {'data': {'type': tipo,
        'attributes': {'fileName': file.name, 'fileSize': len(dati)},
        'relationships': {relazione: {'data': {'type': rel_tipo, 'id': rel_id}}}}})
    if not controlla(r, f'prenotazione {file.name}'):
        return
    rid = r['data']['id']
    for op in r['data']['attributes']['uploadOperations']:
        req = urllib.request.Request(op['url'], data=dati[op['offset']:op['offset'] + op['length']], method=op['method'])
        for h in op['requestHeaders']:
            req.add_header(h['name'], h['value'])
        urllib.request.urlopen(req, timeout=180).read()
    r = api('PATCH', f'{percorso_risorsa}/{rid}', {'data': {'type': tipo, 'id': rid,
        'attributes': {'uploaded': True, 'sourceFileChecksum': hashlib.md5(dati).hexdigest()}}})
    controlla(r, f'caricato {file.name}')


def main():
    t = testi()

    # ── Informazioni sull'app: categorie, sottotitoli, privacy ──────────────────
    info = [i for i in api('GET', f'/v1/apps/{APP}/appInfos')['data']
            if i['attributes'].get('appStoreState', i['attributes'].get('state')) in ('PREPARE_FOR_SUBMISSION', None)
            or i['attributes'].get('state') == 'PREPARE_FOR_SUBMISSION'][0]
    controlla(api('PATCH', f"/v1/appInfos/{info['id']}", {'data': {'type': 'appInfos', 'id': info['id'], 'relationships': {
        'primaryCategory': {'data': {'type': 'appCategories', 'id': 'FOOD_AND_DRINK'}},
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

    # ── Testi della versione e screenshot, per lingua ───────────────────────────
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

    # ── Prezzo: gratuita ────────────────────────────────────────────────────────
    punti = api('GET', f'/v1/apps/{APP}/appPricePoints?filter[territory]=ITA&limit=5')['data']
    gratis = next(p for p in punti if float(p['attributes']['customerPrice']) == 0)
    controlla(api('POST', '/v1/appPriceSchedules', {'data': {'type': 'appPriceSchedules', 'relationships': {
        'app': {'data': {'type': 'apps', 'id': APP}},
        'baseTerritory': {'data': {'type': 'territories', 'id': 'ITA'}},
        'manualPrices': {'data': [{'type': 'appPrices', 'id': '${p0}'}]}}},
        'included': [{'type': 'appPrices', 'id': '${p0}', 'attributes': {'startDate': None},
                      'relationships': {'appPricePoint': {'data': {'type': 'appPricePoints', 'id': gratis['id']}}}}]}),
        'prezzo gratuito')


if __name__ == '__main__':
    os.chdir(RADICE)
    sys.exit(main())

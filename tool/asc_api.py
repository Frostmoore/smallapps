#!/usr/bin/env python3
"""Interroga l'API di App Store Connect con la chiave di ~/.microapps-ios.env.

    python3 tool/asc_api.py GET /v1/apps/6818986320/inAppPurchasesV2

Gira sul Mac, dove stanno la chiave e i tre identificativi. Stampa la risposta JSON.

⚑ Senza dipendenze: il token JWT si firma con `openssl`, che c'e' su ogni Mac, e non con la
  libreria `cryptography`, che sul Python di sistema non c'e'. L'unico passaggio non banale e'
  convertire la firma ECDSA dal formato DER, che produce openssl, al formato r||s di 64 byte
  che pretende il JWT.

☠ Il file della chiave non si legge mai qui dentro: lo legge openssl. Questo script non stampa
  ne' la chiave ne' il token.
"""
import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request


def env():
    valori = {}
    with open(os.path.expanduser('~/.microapps-ios.env')) as f:
        for riga in f:
            riga = riga.strip()
            if riga and not riga.startswith('#') and '=' in riga:
                k, v = riga.split('=', 1)
                valori[k] = v
    return valori


def b64(dati):
    return base64.urlsafe_b64encode(dati).rstrip(b'=').decode()


def der_a_rs(der):
    """Firma ECDSA da DER (SEQUENCE di due INTEGER) a r||s di 32 byte ciascuno."""
    assert der[0] == 0x30
    i = 2 if der[1] < 0x80 else 2 + (der[1] & 0x7F)
    parti = []
    for _ in range(2):
        assert der[i] == 0x02
        lunghezza = der[i + 1]
        valore = der[i + 2:i + 2 + lunghezza].lstrip(b'\x00')
        parti.append(valore.rjust(32, b'\x00'))
        i += 2 + lunghezza
    return parti[0] + parti[1]


def token(v):
    testata = {'alg': 'ES256', 'kid': v['ASC_KEY_ID'], 'typ': 'JWT'}
    ora = int(time.time())
    corpo = {'iss': v['ASC_ISSUER_ID'], 'iat': ora, 'exp': ora + 1200, 'aud': 'appstoreconnect-v1'}
    da_firmare = (b64(json.dumps(testata).encode()) + '.' + b64(json.dumps(corpo).encode())).encode()
    chiave = os.path.expanduser('~/.appstoreconnect/private_keys/AuthKey_%s.p8' % v['ASC_KEY_ID'])
    der = subprocess.run(['openssl', 'dgst', '-sha256', '-sign', chiave],
                         input=da_firmare, capture_output=True, check=True).stdout
    return da_firmare.decode() + '.' + b64(der_a_rs(der))


def main():
    metodo, percorso = sys.argv[1], sys.argv[2]
    corpo = sys.argv[3].encode() if len(sys.argv) > 3 else None
    richiesta = urllib.request.Request('https://api.appstoreconnect.apple.com' + percorso,
                                       data=corpo, method=metodo)
    richiesta.add_header('Authorization', 'Bearer ' + token(env()))
    if corpo:
        richiesta.add_header('Content-Type', 'application/json')
    try:
        with urllib.request.urlopen(richiesta) as r:
            print(json.dumps(json.loads(r.read() or b'{}'), indent=1))
    except urllib.error.HTTPError as e:
        print('HTTP', e.code)
        print(e.read().decode())
        sys.exit(1)


if __name__ == '__main__':
    main()

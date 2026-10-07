"""Genera le icone di Scorte Calore dall'immagine originale del proprietario.

    python apps/scorte_calore/tool/genera_icone.py

Sorgente: assets/icons/source/scortecalore_originale.png (1254x1254, RGB). Un quadrato
arrotondato blu notte con fiamma, pellet, manometro e calendario, e **angoli neri** fuori
dall'arrotondamento. Stesso metodo di apps/full_freezer/tool/genera_icone.py, con due
differenze dette sotto.

Produce in assets/icons/:

| File | A cosa serve |
|---|---|
| scortecalore_fullbleed.png | quadrato pieno senza angoli neri: icona iOS, icona Play 512, legacy Android |
| scortecalore_logo.png      | il quadrato arrotondato con gli angoli trasparenti: sito, schede |
| adaptive_background.png    | Android 8+: l'icona stessa, alla scala del primo piano, bordi allungati |
| adaptive_foreground.png    | Android 8+: solo il disegno, nella zona sicura |
| adaptive_monochrome.png    | Android 13+: sagoma piatta per le icone a tema |
| splash_logo.png            | splash (Android fino a 11 e iOS) |
| splash_android12.png       | splash di Android 12+, nei due terzi centrali |

Differenze da Full Freezer:

- **Il disegno si separa con la luminosita' massima dei canali**, non col solo rosso: lo
  sfondo e' blu notte (canale piu' alto sotto 90), mentre fiamma, pellet, calendario e
  quadrante sono chiari o saturi. Il quadrante scuro del manometro somiglia allo sfondo e
  diventa trasparente, ma sotto il primo piano c'e' l'icona stessa alla stessa scala, quindi
  non si vede (stesso trucco di Full Freezer).
- **Il disegno arriva quasi ai bordi** (la fiamma a sinistra, il calendario a destra): nella
  zona sicura di Android va rimpicciolito di piu', e il blu dello sfondo si allunga intorno.
- **Splash e monocromatica vengono dal ritaglio automatico**: per Full Freezer il proprietario
  ha preferito il suo ritaglio a mano. Se arriva `source/scortecalore_senza_sfondo.png`, lo
  script lo usa al posto di quello automatico.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

QUI = Path(__file__).resolve().parent.parent
ICONE = QUI / 'assets' / 'icons'
ORIGINALE = ICONE / 'source' / 'scortecalore_originale.png'
SENZA_SFONDO = ICONE / 'source' / 'scortecalore_senza_sfondo.png'

TELA = 1080            # Android: 108 dp a 10 px/dp
RAGGIO_SICURO = 330    # cerchio di 66 dp
MARGINE = 0.95

L_SFONDO, L_DISEGNO = 95, 150   # rampa sul canale piu' alto: sotto e' sfondo, sopra disegno


def carica():
    return np.array(Image.open(ORIGINALE).convert('RGB')).astype(np.float32)


def maschera_quadrato(rgb):
    """True dentro il quadrato arrotondato, False negli angoli neri."""
    dentro = rgb.sum(axis=2) > 40
    dentro = ndimage.binary_fill_holes(dentro)
    return ndimage.binary_erosion(dentro, iterations=4)


def blu_notte(rgb, dentro):
    """Il blu dello sfondo, misurato in una fascia appena dentro il bordo lucido."""
    fascia = ndimage.binary_erosion(dentro, iterations=70) & ~ndimage.binary_erosion(dentro, iterations=110)
    pixel = rgb[fascia]
    scuri = pixel[pixel.max(axis=1) < 90]
    return np.median(scuri, axis=0)


def fullbleed(rgb, dentro):
    """Riempie gli angoli col blu notte pieno.

    ☠ Non allungando i pixel del bordo come in Full Freezer: qui il quadrato ha un bordo
    lucido (azzurro in alto a destra, arancio in basso a sinistra) e allungarlo disegnava
    strisce chiare negli angoli (visto nelle anteprime del 2026-10-07).
    """
    colore = blu_notte(rgb, dentro)
    fuori = np.broadcast_to(colore, rgb.shape)
    peso = np.clip(ndimage.distance_transform_edt(~dentro) / 6.0, 0, 1)[..., None]
    return rgb * (1 - peso) + fuori * peso


def sfondo_adattivo(rgb, dentro):
    """Lo sfondo adattivo: un alone blu notte, senza il quadrato e il suo bordo lucido.

    ⚑ In Full Freezer lo sfondo era l'icona stessa; qui il disegno arriva ai bordi e va
    rimpicciolito di meta', e il quadrato originale restava visibile dentro il cerchio del
    launcher come una cornice. Un alone dal blu piu' chiaro al centro al blu notte ai bordi
    ripete lo sfondo dell'icona senza la cornice.
    """
    colore = blu_notte(rgb, dentro)
    chiaro = np.array([24, 52, 80], dtype=np.float32)       # #183450, il blu piu' chiaro dell'icona
    yy, xx = np.mgrid[0:TELA, 0:TELA]
    t = np.clip(np.hypot(xx - TELA / 2, yy - TELA / 2) / (TELA * 0.62), 0, 1)[..., None]
    return Image.fromarray((chiaro * (1 - t) + colore * t).astype(np.uint8))


def alfa_disegno(rgb, dentro):
    alfa = np.clip((rgb.max(axis=2) - L_SFONDO) / (L_DISEGNO - L_SFONDO), 0, 1)
    # Il bordo del quadrato ha un riflesso chiaro: non e' disegno.
    alfa *= ndimage.binary_erosion(dentro, iterations=40)
    # Via i frammenti isolati (riflessi, rumore): resta il disegno connesso.
    etichette, quante = ndimage.label(alfa > 0.5)
    if quante:
        grandezze = ndimage.sum(alfa > 0.5, etichette, range(1, quante + 1))
        tieni = np.isin(etichette, 1 + np.nonzero(grandezze >= 2000)[0])
        alfa *= ndimage.binary_dilation(tieni, iterations=3)
    return alfa


def raggio_disegno(alfa):
    lato = alfa.shape[0]
    yy, xx = np.nonzero(alfa > 0.5)
    return float(np.percentile(np.hypot(xx - lato / 2, yy - lato / 2), 99.7))


def su_tela(img, scala, tela, modo):
    lato = round(img.width * scala)
    piccola = img.resize((lato, lato), Image.LANCZOS)
    if modo == 'bordo':
        a = np.array(piccola)
        pad = (tela - lato) // 2
        a = np.pad(a, ((pad, tela - lato - pad), (pad, tela - lato - pad), (0, 0)), mode='edge')
        return Image.fromarray(a)
    out = Image.new('RGBA', (tela, tela), (0, 0, 0, 0))
    out.paste(piccola, ((tela - lato) // 2, (tela - lato) // 2), piccola)
    return out


def main():
    rgb = carica()
    dentro = maschera_quadrato(rgb)
    pieno = fullbleed(rgb, dentro)
    lato = rgb.shape[0]


    alfa_q = np.clip(rgb.sum(axis=2) / 120.0, 0, 1)
    alfa_q = ndimage.binary_fill_holes(alfa_q > 0.05) * alfa_q
    alfa_q[ndimage.binary_erosion(dentro, iterations=2)] = 1
    Image.fromarray(np.dstack([rgb, alfa_q * 255]).astype(np.uint8), 'RGBA').save(ICONE / 'scortecalore_logo.png')

    alfa = alfa_disegno(rgb, dentro)
    raggio = raggio_disegno(alfa)
    scala = RAGGIO_SICURO * MARGINE / raggio
    print(f'raggio del disegno {raggio:.0f}px su {lato}px, scala Android {scala:.3f}')

    sfondo = sfondo_adattivo(rgb, dentro)
    sfondo.convert('RGB').save(ICONE / 'adaptive_background.png')
    primo = Image.fromarray(np.dstack([rgb, alfa * 255]).astype(np.uint8), 'RGBA')
    su_tela(primo, scala, TELA, 'trasparente').save(ICONE / 'adaptive_foreground.png')

    # iOS (e icona Play 512, legacy Android): lo stesso alone con il disegno alla sua scala
    # originale. ☠ Non il quadrato originale riempito: dentro la maschera di Apple si vedeva
    # il suo bordo lucido come una seconda cornice (anteprima del 2026-10-07).
    ios = sfondo_adattivo(rgb, dentro).resize((lato, lato), Image.LANCZOS).convert('RGBA')
    ios.alpha_composite(primo)
    ios.convert('RGB').resize((1024, 1024), Image.LANCZOS).save(ICONE / 'scortecalore_fullbleed.png')

    # Il disegno da solo, per splash e monocromatica.
    if SENZA_SFONDO.exists():
        disegno = Image.open(SENZA_SFONDO).convert('RGBA')
    else:
        disegno = primo
    disegno = disegno.crop(disegno.getbbox())

    def centrato(tela, occupato):
        k = occupato / max(disegno.size)
        piccolo = disegno.resize((round(disegno.width * k), round(disegno.height * k)), Image.LANCZOS)
        out = Image.new('RGBA', (tela, tela), (0, 0, 0, 0))
        out.paste(piccolo, ((tela - piccolo.width) // 2, (tela - piccolo.height) // 2), piccolo)
        return out

    centrato(1024, 1024).save(ICONE / 'splash_logo.png')
    centrato(1152, round(768 * MARGINE)).save(ICONE / 'splash_android12.png')

    # Monocromatica: sagoma piatta a due toni, piena dove il disegno e' chiaro, vuota nelle
    # linee scure di separazione; sfocatura e nuova soglia per bordi da tracciato vettoriale,
    # via i frammenti che a 48 dp sarebbero rumore (stesso procedimento di Full Freezer).
    a = np.array(disegno).astype(np.float32)
    lum = 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]
    pieno_m = (lum > 135) & (a[..., 3] > 127)
    morbido = ndimage.gaussian_filter(pieno_m.astype(np.float32), 4.0) > 0.5
    etichette, quante = ndimage.label(morbido)
    if quante:
        grandezze = ndimage.sum(morbido, etichette, range(1, quante + 1))
        morbido = np.isin(etichette, 1 + np.nonzero(grandezze >= 1500)[0])
    alfa_mono = np.clip(ndimage.gaussian_filter(morbido.astype(np.float32), 1.0), 0, 1)
    sagoma = Image.fromarray(np.dstack([np.full_like(alfa_mono, 255)] * 3 + [alfa_mono * 255]).astype(np.uint8), 'RGBA')
    lato_mono = round(2 * RAGGIO_SICURO * MARGINE * 0.92)
    k = lato_mono / max(sagoma.size)
    sagoma = sagoma.resize((round(sagoma.width * k), round(sagoma.height * k)), Image.LANCZOS)
    mono = Image.new('RGBA', (TELA, TELA), (0, 0, 0, 0))
    mono.paste(sagoma, ((TELA - sagoma.width) // 2, (TELA - sagoma.height) // 2), sagoma)
    mono.save(ICONE / 'adaptive_monochrome.png')

    # Anteprime per controllare a occhio.
    anteprime = ICONE / 'source' / 'anteprime'
    anteprime.mkdir(exist_ok=True)
    composto = sfondo.convert('RGBA')
    composto.alpha_composite(Image.open(ICONE / 'adaptive_foreground.png'))
    visibile = composto.crop((180, 180, 900, 900))
    for nome, raggio_angolo in (('cerchio', 360), ('squircle', 160)):
        m = Image.new('L', visibile.size, 0)
        ImageDraw.Draw(m).rounded_rectangle((0, 0, 719, 719), raggio_angolo, fill=255)
        prova = Image.new('RGBA', visibile.size, (240, 240, 240, 255))
        prova.paste(visibile, (0, 0), m)
        prova.save(anteprime / f'android_{nome}.png')
    ios = Image.open(ICONE / 'scortecalore_fullbleed.png').convert('RGBA')
    m = Image.new('L', ios.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, 1023, 1023), 230, fill=255)
    prova = Image.new('RGBA', ios.size, (240, 240, 240, 255))
    prova.paste(ios, (0, 0), m)
    prova.save(anteprime / 'ios.png')
    m = Image.open(ICONE / 'adaptive_monochrome.png')
    prova = Image.new('RGBA', m.size, (60, 70, 90, 255))
    prova.alpha_composite(m)
    prova.crop((180, 180, 900, 900)).save(anteprime / 'android_monocromatica.png')
    splash = Image.new('RGBA', (1024, 1024), (24, 52, 80, 255))
    splash.alpha_composite(Image.open(ICONE / 'splash_logo.png'))
    splash.save(anteprime / 'splash.png')


if __name__ == '__main__':
    main()

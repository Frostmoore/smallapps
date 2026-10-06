"""Genera le icone di Full Freezer dall'immagine originale del proprietario.

    python apps/full_freezer/tool/genera_icone.py

Sorgente: assets/icons/source/fullfreezer_originale.png (1254x1254, RGB). E' un quadrato
arrotondato blu con il disegno al centro, e **angoli neri** fuori dall'arrotondamento.

Produce in assets/icons/:

| File | A cosa serve |
|---|---|
| fullfreezer_fullbleed.png   | quadrato pieno senza angoli neri: icona iOS, icona Play 512, icona legacy Android |
| fullfreezer_logo.png        | il quadrato arrotondato originale con gli angoli trasparenti: sito, splash iOS |
| adaptive_background.png     | Android 8+: livello di sfondo, 1080x1080 (108 dp) |
| adaptive_foreground.png     | Android 8+: solo il disegno, su trasparente, nella zona sicura |
| adaptive_monochrome.png     | Android 13+: il disegno in bianco, per le icone a tema |
| splash_logo.png             | splash (Android fino a 11 e iOS): il disegno senza sfondo del proprietario, su tela quadrata |
| splash_android12.png        | splash di Android 12+: lo stesso disegno, nei due terzi centrali |

☠ Le splash NON usano il ritaglio automatico del disegno (`alfa_disegno`): le sfaccettature
blu scure del fiocco hanno lo stesso colore dello sfondo, il ritaglio le rende trasparenti e
il disegno appare «svuotato» (osservazione del proprietario, 2026-10-06). Per le splash si usa
il ritaglio fatto a mano dal proprietario, `source/fullfreezer_senza_sfondo.png`. Nell'icona
adattiva il problema non si vede perche' sotto c'e' lo sfondo originale.

Perche' cosi':

- iOS **non accetta trasparenza** nell'icona (App Store Connect la rifiuta a caricamento
  finito) e applica da solo la maschera arrotondata: vuole un quadrato pieno. Gli angoli
  neri dell'originale finirebbero dentro la maschera di iOS come quattro spigoli scuri.
  Si riempiono allungando verso l'esterno il blu del bordo (pixel interno piu' vicino),
  poi si sfuma la parte riempita perche' non si vedano le striature.
- Android adattiva ritaglia il livello a cerchio, goccia o quadrato a seconda del
  produttore, e mostra solo i 72 dp centrali dei 108: il disegno deve stare in un cerchio di
  66 dp. L'originale ha l'anello delle frecce quasi al bordo, quindi va rimpicciolito.
- **Lo sfondo adattivo e' l'immagine stessa**, alla stessa scala del primo piano. Cosi' dove
  il ritaglio del disegno sbaglia (le sfaccettature blu scure al centro del fiocco, che hanno
  lo stesso colore dello sfondo) sotto si vede esattamente l'originale, e l'insieme coincide
  con l'icona che il proprietario ha disegnato.
- Il primo piano si ottiene dal canale rosso: lo sfondo blu ha R quasi nullo (0-40), il
  bianco del fiocco e del freezer e l'azzurro dell'anello stanno sopra 150.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

QUI = Path(__file__).resolve().parent.parent
ICONE = QUI / 'assets' / 'icons'
ORIGINALE = ICONE / 'source' / 'fullfreezer_originale.png'
SENZA_SFONDO = ICONE / 'source' / 'fullfreezer_senza_sfondo.png'

# Android: tela di 108 dp a 10 px/dp; la zona sicura e' un cerchio di 66 dp di diametro.
TELA = 1080
RAGGIO_SICURO = 330
MARGINE = 0.94          # il disegno occupa il 94% della zona sicura, non tocca il bordo

R_SFONDO, R_DISEGNO = 60, 160   # rampa del canale rosso: sotto e' sfondo, sopra e' disegno


def carica():
    return np.array(Image.open(ORIGINALE).convert('RGB')).astype(np.float32)


def maschera_quadrato(rgb):
    """True dentro il quadrato arrotondato, False negli angoli neri."""
    dentro = rgb.sum(axis=2) > 40
    dentro = ndimage.binary_fill_holes(dentro)
    # Il bordo antialias e' mezzo nero: lo si scarta, se no il riempimento lo allunga.
    return ndimage.binary_erosion(dentro, iterations=4)


def fullbleed(rgb, dentro):
    """Riempie gli angoli col blu del bordo e sfuma la sola parte riempita."""
    _, (iy, ix) = ndimage.distance_transform_edt(~dentro, return_indices=True)
    pieno = rgb[iy, ix]
    sfumato = np.array(Image.fromarray(pieno.astype(np.uint8)).filter(ImageFilter.GaussianBlur(18))).astype(np.float32)
    # Raccordo morbido fra originale e parte riempita, su una fascia di 6 px.
    peso = np.clip(ndimage.distance_transform_edt(~dentro) / 6.0, 0, 1)[..., None]
    return pieno * (1 - peso) + sfumato * peso


def alfa_disegno(rgb):
    lato = rgb.shape[0]
    alfa = np.clip((rgb[..., 0] - R_SFONDO) / (R_DISEGNO - R_SFONDO), 0, 1)
    # Il riflesso azzurro sul bordo del quadrato ha R alto ma non e' disegno: si tiene
    # solo il cerchio centrale, dove sta l'anello delle frecce.
    yy, xx = np.mgrid[0:lato, 0:lato]
    r = np.hypot(xx - lato / 2, yy - lato / 2)
    alfa *= np.clip((0.47 * lato - r) / 12, 0, 1)
    return alfa


def raggio_disegno(alfa):
    lato = alfa.shape[0]
    yy, xx = np.nonzero(alfa > 0.5)
    return float(np.max(np.hypot(xx - lato / 2, yy - lato / 2)))


def su_tela(img, scala, tela, modo):
    """Scala l'immagine e la centra su una tela quadrata. modo: 'bordo' allunga i bordi."""
    lato = round(img.width * scala)
    piccola = img.resize((lato, lato), Image.LANCZOS)
    if modo == 'bordo':
        a = np.array(piccola)
        pad = (tela - lato) // 2
        a = np.pad(a, ((pad, tela - lato - pad), (pad, tela - lato - pad), (0, 0)), mode='edge')
        piena = Image.fromarray(a).filter(ImageFilter.GaussianBlur(0))
        return piena
    out = Image.new('RGBA', (tela, tela), (0, 0, 0, 0))
    out.paste(piccola, ((tela - lato) // 2, (tela - lato) // 2), piccola)
    return out


def main():
    rgb = carica()
    dentro = maschera_quadrato(rgb)
    pieno = fullbleed(rgb, dentro)
    lato = rgb.shape[0]

    Image.fromarray(pieno.astype(np.uint8)).resize((1024, 1024), Image.LANCZOS).save(ICONE / 'fullfreezer_fullbleed.png')

    # Logo con angoli trasparenti, alfa antialias dalla maschera non erosa.
    alfa_q = np.clip(rgb.sum(axis=2) / 120.0, 0, 1)
    alfa_q = ndimage.binary_fill_holes(alfa_q > 0.05) * alfa_q
    alfa_q[ndimage.binary_erosion(dentro, iterations=2)] = 1
    logo = np.dstack([rgb, alfa_q * 255]).astype(np.uint8)
    Image.fromarray(logo, 'RGBA').save(ICONE / 'fullfreezer_logo.png')

    alfa = alfa_disegno(rgb)
    raggio = raggio_disegno(alfa)
    scala = RAGGIO_SICURO * MARGINE / raggio
    print(f'raggio del disegno {raggio:.0f}px su {lato}px, scala Android {scala:.3f}')

    sfondo = su_tela(Image.fromarray(pieno.astype(np.uint8)), scala, TELA, 'bordo')
    sfondo.convert('RGB').save(ICONE / 'adaptive_background.png')

    primo = np.dstack([rgb, alfa * 255]).astype(np.uint8)
    su_tela(Image.fromarray(primo, 'RGBA'), scala, TELA, 'trasparente').save(ICONE / 'adaptive_foreground.png')

    # ☠ La monocromatica non puo' usare l'alfa sfumato del primo piano: il sistema la
    # tinge in base all'alfa, e le sfumature del disegno 3D diventano macchie grigie
    # metalliche. Serve una sagoma piena: soglia piu' alta e rampa corta.
    alfa_mono = np.clip((rgb[..., 0] - 110) / 30, 0, 1) * (alfa > 0)
    mono = np.dstack([np.full_like(alfa, 255)] * 3 + [alfa_mono * 255]).astype(np.uint8)
    su_tela(Image.fromarray(mono, 'RGBA'), scala, TELA, 'trasparente').save(ICONE / 'adaptive_monochrome.png')

    # Splash dal ritaglio del proprietario. Il disegno non e' quadrato (1323x1189): lo si
    # centra su una tela quadrata, col lato piu' lungo che occupa la frazione voluta.
    disegno = Image.open(SENZA_SFONDO).convert('RGBA')
    disegno = disegno.crop(disegno.getbbox())

    def centrato(tela, occupato):
        scala = occupato / max(disegno.size)
        piccolo = disegno.resize((round(disegno.width * scala), round(disegno.height * scala)), Image.LANCZOS)
        out = Image.new('RGBA', (tela, tela), (0, 0, 0, 0))
        out.paste(piccolo, ((tela - piccolo.width) // 2, (tela - piccolo.height) // 2), piccolo)
        return out

    centrato(1024, 1024).save(ICONE / 'splash_logo.png')
    # Android 12+: tela 1152, sopravvive il cerchio dei 768 px centrali. Il disegno e' quasi
    # un cerchio (l'anello), quindi il lato lungo puo' stare a filo del 94% del diametro.
    centrato(1152, round(768 * MARGINE)).save(ICONE / 'splash_android12.png')

    # Anteprime per controllare a occhio: cerchio e squircle come li mostrano i launcher.
    anteprime = ICONE / 'source' / 'anteprime'
    anteprime.mkdir(exist_ok=True)
    composto = sfondo.convert('RGBA')
    composto.alpha_composite(Image.open(ICONE / 'adaptive_foreground.png'))
    visibile = composto.crop((180, 180, 900, 900))       # i 72 dp centrali
    for nome, raggio_angolo in (('cerchio', 360), ('squircle', 160)):
        m = Image.new('L', visibile.size, 0)
        from PIL import ImageDraw
        ImageDraw.Draw(m).rounded_rectangle((0, 0, 719, 719), raggio_angolo, fill=255)
        prova = Image.new('RGBA', visibile.size, (240, 240, 240, 255))
        prova.paste(visibile, (0, 0), m)
        prova.save(anteprime / f'android_{nome}.png')
    ios = Image.open(ICONE / 'fullfreezer_fullbleed.png').convert('RGBA')
    m = Image.new('L', ios.size, 0)
    from PIL import ImageDraw
    ImageDraw.Draw(m).rounded_rectangle((0, 0, 1023, 1023), 230, fill=255)
    prova = Image.new('RGBA', ios.size, (240, 240, 240, 255))
    prova.paste(ios, (0, 0), m)
    prova.save(anteprime / 'ios.png')
    m = Image.open(ICONE / 'adaptive_monochrome.png')
    prova = Image.new('RGBA', m.size, (60, 70, 90, 255))
    prova.alpha_composite(m)
    prova.crop((180, 180, 900, 900)).save(anteprime / 'android_monocromatica.png')


if __name__ == '__main__':
    main()

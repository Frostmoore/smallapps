"""Genera le icone di Film Tracker dall'immagine originale del proprietario.

    python apps/film_tracker/tool/genera_icone.py

Sorgente: assets/icons/source/filmtracker_originale.png (1254x1254, RGB). Un quadrato
arrotondato (raggio ~24%) con un gradiente grigio-azzurro, il rullino, la striscia di
pellicola e il bollino della lista, posato su un fondo blu notte (#192634).

Produce in assets/icons/:

| File | A cosa serve |
|---|---|
| filmtracker_fullbleed.png | quadrato pieno 1024: icona iOS, icona Play 512, legacy Android |
| filmtracker_logo.png      | il quadrato arrotondato con gli angoli trasparenti: sito, schede, splash |
| adaptive_background.png   | Android 8+: l'icona intera nella zona sicura, bordi prolungati |
| adaptive_foreground.png   | Android 8+: trasparente (tutto sta nello sfondo, vedi sotto) |
| splash_logo.png           | splash (Android fino a 11 e iOS): il quadrato arrotondato |
| splash_android12.png      | splash di Android 12+, nei due terzi centrali |

⚑ **Perche' non il metodo di Scorte Calore e Full Freezer** (disegno ritagliato per
luminosita' e sfondo separato): qui lo sfondo del quadrato e' un gradiente **chiaro**
(grigio-azzurro, dal 145 al 190 sul blu) e il disegno ha parti scure (il coperchio del
rullino) e parti chiare (l'etichetta, il bollino): nessuna soglia li separa. Ma il quadrato
ha un bordo lucido **sottile** (10-15 px) e angoli con un raggio (24%) quasi uguale a quello
della maschera di Apple (22,4%): rifilato appena dentro il bordo, e' gia' un'icona iOS.
- iOS: il quadrato rifilato di 34 px per lato, angoli riempiti col colore del pixel di
  quadrato piu' vicino e sfocati (sotto la maschera di Apple se ne vede al piu' un filo).
- Android: l'icona intera, rifilata allo stesso modo, nei 700 px centrali della tela da 1080
  (la parte che i launcher mostrano e' 720; il cerchio sicuro e' 660, e il disegno arriva a
  ~0,46 del lato dal centro, quindi resta dentro), con i bordi prolungati fino alla tela.
  Primo piano trasparente: niente parallasse fra i livelli, che con un disegno non
  separabile non avrebbe niente da muovere.

☠ Manca l'icona **monocromatica** di Android 13 (icone a tema): senza un ritaglio del disegno
non c'e' una sagoma. Il launcher mostra l'icona a colori, che e' il comportamento previsto
quando manca. Se il proprietario fornisce `source/filmtracker_senza_sfondo.png`, si aggiunge.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

QUI = Path(__file__).resolve().parent.parent
ICONE = QUI / 'assets' / 'icons'
ORIGINALE = ICONE / 'source' / 'filmtracker_originale.png'

FONDO = np.array([25, 38, 52])   # il blu notte attorno al quadrato, misurato negli angoli
RIFILO = 34                      # px tolti per lato: il bordo lucido e un margine
TELA = 1080                      # Android: 108 dp a 10 px/dp
LATO_ANDROID = 700               # l'icona dentro i 720 px visibili


def carica():
    return np.array(Image.open(ORIGINALE).convert('RGB')).astype(np.float32)


def maschera_quadrato(rgb):
    """True dentro il quadrato arrotondato, False sul fondo blu notte."""
    dentro = np.abs(rgb - FONDO).sum(axis=2) > 40
    dentro = ndimage.binary_fill_holes(dentro)
    return ndimage.binary_erosion(dentro, iterations=3)


def riempi_angoli(rgb, dentro):
    """Fuori dal quadrato, il colore del pixel di quadrato piu' vicino, poi sfocato.

    ⚑ Non il blu notte del fondo: sotto la maschera di Apple resterebbe un filo scuro agli
    angoli, che si legge come una cornice.
    """
    # Un po' dentro il bordo lucido, cosi' il colore di riempimento non e' il riflesso.
    pieno_dentro = ndimage.binary_erosion(dentro, iterations=RIFILO // 2)
    _, (iy, ix) = ndimage.distance_transform_edt(~pieno_dentro, return_indices=True)
    esteso = rgb[iy, ix]
    morbido = np.stack([ndimage.gaussian_filter(esteso[..., c], 12) for c in range(3)], axis=-1)
    peso = np.clip(ndimage.distance_transform_edt(~pieno_dentro) / 8.0, 0, 1)[..., None]
    return rgb * (1 - peso) + morbido * peso


def main():
    rgb = carica()
    dentro = maschera_quadrato(rgb)
    lato = rgb.shape[0]

    # Il logo: il quadrato con gli angoli trasparenti, bordo antialias.
    alfa = np.clip(ndimage.gaussian_filter(dentro.astype(np.float32), 1.2), 0, 1)
    logo = Image.fromarray(np.dstack([rgb, alfa * 255]).astype(np.uint8), 'RGBA')
    logo = logo.crop(logo.getbbox())
    logo.save(ICONE / 'filmtracker_logo.png')

    # iOS e icona Play: il quadrato rifilato, angoli riempiti.
    pieno = riempi_angoli(rgb, dentro)
    ys, xs = np.nonzero(dentro)
    x0, x1, y0, y1 = xs.min() + RIFILO, xs.max() - RIFILO, ys.min() + RIFILO, ys.max() - RIFILO
    l = min(x1 - x0, y1 - y0)
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    quadro = Image.fromarray(pieno.astype(np.uint8)).crop((cx - l // 2, cy - l // 2, cx - l // 2 + l, cy - l // 2 + l))
    quadro.resize((1024, 1024), Image.LANCZOS).save(ICONE / 'filmtracker_fullbleed.png')

    # Android: l'icona nei 700 px centrali, bordi prolungati.
    a = np.array(quadro.resize((LATO_ANDROID, LATO_ANDROID), Image.LANCZOS))
    pad = (TELA - LATO_ANDROID) // 2
    a = np.pad(a, ((pad, TELA - LATO_ANDROID - pad), (pad, TELA - LATO_ANDROID - pad), (0, 0)), mode='edge')
    sfondo = Image.fromarray(a).filter(ImageFilter.GaussianBlur(0))
    # Il prolungamento a bordo ripetuto fa strisce: si sfuma con una versione molto sfocata.
    sfocato = sfondo.filter(ImageFilter.GaussianBlur(40))
    m = Image.new('L', (TELA, TELA), 0)
    ImageDraw.Draw(m).rectangle((pad, pad, pad + LATO_ANDROID - 1, pad + LATO_ANDROID - 1), fill=255)
    m = m.filter(ImageFilter.GaussianBlur(6))
    sfocato.paste(sfondo, (0, 0), m)
    sfocato.save(ICONE / 'adaptive_background.png')
    Image.new('RGBA', (TELA, TELA), (0, 0, 0, 0)).save(ICONE / 'adaptive_foreground.png')

    # Splash: il quadrato arrotondato.
    def centrato(tela, occupato):
        k = occupato / max(logo.size)
        piccolo = logo.resize((round(logo.width * k), round(logo.height * k)), Image.LANCZOS)
        out = Image.new('RGBA', (tela, tela), (0, 0, 0, 0))
        out.paste(piccolo, ((tela - piccolo.width) // 2, (tela - piccolo.height) // 2), piccolo)
        return out

    centrato(1024, 1024).save(ICONE / 'splash_logo.png')
    # Android 12: cerchio di 768 su 1152; il quadrato arrotondato deve starci dentro.
    centrato(1152, 560).save(ICONE / 'splash_android12.png')

    # Anteprime per controllare a occhio.
    anteprime = ICONE / 'source' / 'anteprime'
    anteprime.mkdir(exist_ok=True)
    visibile = sfocato.crop((180, 180, 900, 900))
    for nome, raggio_angolo in (('cerchio', 360), ('squircle', 160)):
        mk = Image.new('L', visibile.size, 0)
        ImageDraw.Draw(mk).rounded_rectangle((0, 0, 719, 719), raggio_angolo, fill=255)
        prova = Image.new('RGBA', visibile.size, (240, 240, 240, 255))
        prova.paste(visibile, (0, 0), mk)
        prova.save(anteprime / f'android_{nome}.png')
    ios = Image.open(ICONE / 'filmtracker_fullbleed.png').convert('RGBA')
    mk = Image.new('L', ios.size, 0)
    ImageDraw.Draw(mk).rounded_rectangle((0, 0, 1023, 1023), 230, fill=255)
    prova = Image.new('RGBA', ios.size, (240, 240, 240, 255))
    prova.paste(ios, (0, 0), mk)
    prova.save(anteprime / 'ios.png')
    print(f'quadrato {xs.min()}-{xs.max()}, rifilato a {l}px')


if __name__ == '__main__':
    main()

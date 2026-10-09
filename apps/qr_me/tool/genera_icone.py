"""Genera le icone e la splash di QR Me dall'immagine originale del proprietario.

    python apps/qr_me/tool/genera_icone.py

Sorgente: assets/icon/originale.png (1254x1254, RGBA, **sfondo trasparente**; arrivato il
2026-10-09 in Download come file «QR Me» senza estensione). Un QR stilizzato a moduli scuri
arrotondati con gli occhi verde acceso e, in basso a destra, il simbolo di condivisione verde.
Intorno ai moduli c'e' un alone verde semitrasparente.

Produce in assets/icon/:

| File | A cosa serve |
|---|---|
| icona_ios.png         | 1024 pieno, senza alfa: icona iOS, icona Play 512, legacy Android |
| adaptive_background.png | Android 8+: il fondo pieno (solo colore) |
| adaptive_foreground.png | Android 8+: il disegno, trasparente, nella zona sicura |
| adaptive_monochrome.png | Android 13+ (icone a tema): la sagoma del disegno |
| splash_logo.png       | splash (Android fino a 11 e iOS): il disegno su trasparente |
| splash_android12.png  | splash di Android 12+, dentro il cerchio che sopravvive |
| anteprime/*.png       | prove a occhio con le maschere di iOS e dei launcher (non usate dall'app) |

⚑ **Perche' il metodo di Scorte Calore e Full Freezer e non quello di Film Tracker**: qui il
disegno arriva GIA' separato dallo sfondo (canale alfa), quindi si posa su un fondo pieno
scelto da noi e si ha gratis anche il primo piano separato (parallasse dei launcher) e la
sagoma monocromatica di Android 13, che a Film Tracker mancano.

⚑ **Fondo chiarissimo (FONDO) e non scuro**: i moduli del disegno sono quasi neri; su un fondo
scuro sparirebbero e resterebbero solo gli occhi verdi. Un grigio-verde chiarissimo e non il
bianco puro: sulla griglia bianca di iOS in tema chiaro un'icona bianca perde il bordo.

☠ **iOS non accetta il canale alfa**: App Store Connect rifiuta la build a caricamento finito.
Per questo l'icona iOS si compone qui su fondo pieno (e flutter_launcher_icons ha comunque
`remove_alpha_ios: true` come seconda cintura).

☠ **Zona sicura di Android**: la tela adattiva e' 108 dp (1080 px qui), il launcher ne mostra
72 (720 px) e con la maschera rotonda garantisce solo il cerchio di 66 dp (660 px). Il disegno e'
quasi quadrato, con gli occhi negli angoli: per non tagliarli col cerchio la sua diagonale deve
stare nei 660 px, quindi il lato lungo e' al massimo ~466 px (LATO_ANDROID).
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

QUI = Path(__file__).resolve().parent.parent
ICONE = QUI / 'assets' / 'icon'
ORIGINALE = ICONE / 'originale.png'

FONDO = (243, 247, 243)   # grigio-verde chiarissimo, #F3F7F3 (vedi l'intestazione)
TELA = 1080               # Android: 108 dp a 10 px/dp
LATO_ANDROID = 460        # lato lungo del disegno: la diagonale resta nel cerchio sicuro da 660
LATO_IOS = 780            # disegno nell'icona iOS da 1024: margine ~12% per lato
ALFA_SAGOMA = 140         # soglia dell'alfa per la monocromatica: l'alone verde resta fuori
GAP_SIMBOLO = 40          # px tolti intorno al simbolo di condivisione nella sagoma: il bordo scuro, l alone e uno stacco


def carica():
    """Il disegno ritagliato al suo riquadro (alone compreso), in RGBA."""
    im = Image.open(ORIGINALE).convert('RGBA')
    alfa = np.array(im)[..., 3]
    ys, xs = np.nonzero(alfa > 8)
    return im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def scala(disegno, lato_lungo):
    k = lato_lungo / max(disegno.size)
    return disegno.resize((round(disegno.width * k), round(disegno.height * k)), Image.LANCZOS)


def al_centro(disegno, tela, lato_lungo, fondo=(0, 0, 0, 0)):
    piccolo = scala(disegno, lato_lungo)
    out = Image.new('RGBA', (tela, tela), fondo)
    out.alpha_composite(piccolo, ((tela - piccolo.width) // 2, (tela - piccolo.height) // 2))
    return out


def sagoma(primo):
    """La sagoma per le icone a tema di Android 13, bianca su trasparente.

    ☠ La sola soglia sull'alfa fonde il simbolo di condivisione in una macchia: il suo bordo
    scuro tocca i moduli del QR. Si tiene il verde del simbolo (la componente verde piu'
    grande) e si toglie lo scuro che gli sta intorno, cosi' resta staccato dai moduli.
    """
    px = np.array(primo).astype(int)
    r, g, a = px[..., 0], px[..., 1], px[..., 3]
    pieno = a > ALFA_SAGOMA
    verde = (g > 150) & (g - r > 60) & pieno
    etichette, n = ndimage.label(verde)
    if n:
        dimensioni = ndimage.sum(verde, etichette, range(1, n + 1))
        simbolo = etichette == (int(np.argmax(dimensioni)) + 1)
        # I riflessi chiari e i bordi verde scuro non passano la soglia del verde: si chiudono.
        simbolo = ndimage.binary_fill_holes(ndimage.binary_closing(simbolo, iterations=6))
        intorno = ndimage.binary_dilation(simbolo, iterations=GAP_SIMBOLO)
        pieno = (pieno & ~intorno) | simbolo
    out = np.zeros(px.shape, np.uint8)
    out[..., :3] = 255
    out[..., 3] = np.where(pieno, 255, 0)
    return out


def main():
    disegno = carica()

    # iOS (e Play, e legacy Android): fondo pieno, niente alfa.
    ios = al_centro(disegno, 1024, LATO_IOS, FONDO + (255,)).convert('RGB')
    ios.save(ICONE / 'icona_ios.png')

    # Android adattiva: fondo pieno + primo piano trasparente nella zona sicura.
    Image.new('RGB', (TELA, TELA), FONDO).save(ICONE / 'adaptive_background.png')
    primo = al_centro(disegno, TELA, LATO_ANDROID)
    primo.save(ICONE / 'adaptive_foreground.png')

    # Android 13: la sagoma, bianca su trasparente (il launcher la ricolora).
    Image.fromarray(sagoma(primo), 'RGBA').save(ICONE / 'adaptive_monochrome.png')

    # Splash: il disegno sul colore FONDO (lo mette flutter_native_splash).
    al_centro(disegno, 1024, 900).save(ICONE / 'splash_logo.png')
    # Android 12: tela 1152, sopravvive il cerchio di 768: diagonale del disegno dentro.
    al_centro(disegno, 1152, 520).save(ICONE / 'splash_android12.png')

    # Anteprime a occhio.
    anteprime = ICONE / 'anteprime'
    anteprime.mkdir(exist_ok=True)
    adattiva = Image.new('RGBA', (TELA, TELA), FONDO + (255,))
    adattiva.alpha_composite(primo)
    visibile = adattiva.crop((180, 180, 900, 900))
    for nome, raggio in (('cerchio', 360), ('squircle', 160)):
        mk = Image.new('L', visibile.size, 0)
        ImageDraw.Draw(mk).rounded_rectangle((0, 0, 719, 719), raggio, fill=255)
        prova = Image.new('RGBA', visibile.size, (60, 60, 60, 255))
        prova.paste(visibile, (0, 0), mk)
        prova.save(anteprime / f'android_{nome}.png')
    mk = Image.new('L', ios.size, 0)
    ImageDraw.Draw(mk).rounded_rectangle((0, 0, 1023, 1023), 230, fill=255)
    prova = Image.new('RGBA', ios.size, (60, 60, 60, 255))
    prova.paste(ios, (0, 0), mk)
    prova.save(anteprime / 'ios.png')
    print(f'disegno {disegno.size[0]}x{disegno.size[1]}')


if __name__ == '__main__':
    main()

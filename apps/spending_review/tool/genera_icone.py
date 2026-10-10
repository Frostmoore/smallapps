"""Genera le icone e la splash di Spending Review dall'immagine originale del proprietario.

    python apps/spending_review/tool/genera_icone.py

Sorgente: assets/icon/originale.png (copia di docs/specs/icona-spending-review.png, 1254x1254,
RGBA, **sfondo trasparente**; F12.0 punto 7). Uno scontrino bianco arrotolato con le righe grigie
e il simbolo dell'euro scuro, dentro quattro angoli verdi da mirino.

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

⚑ **Metodo di QR Me** (da cui lo script e' copiato): il disegno arriva gia' separato dallo sfondo,
quindi si posa su un fondo pieno scelto da noi, e si ha gratis il primo piano separato (parallasse
dei launcher) e la sagoma monocromatica di Android 13.

⚑ **Fondo SCURO (FONDO = #161B22, lo «sfondo» di «C · Una mano») e non chiaro come QR Me**: qui il
disegno e' uno scontrino BIANCO con angoli verdi; su un fondo chiaro lo scontrino sparirebbe e
resterebbero quattro angoli. Sul fondo scuro dell'app lo scontrino e' la cosa piu' chiara, e l'icona
continua nella splash e nell'app (scura di default).

⚑ **Sagoma monocromatica**: non la sola soglia sull'alfa, che darebbe un rettangolo pieno senza le
righe dello scontrino; si tolgono anche i pixel grigi e scuri (righe e simbolo dell'euro), cosi'
nella sagoma restano come «buchi» e l'icona a tema si riconosce.

☠ **iOS non accetta il canale alfa**: App Store Connect rifiuta la build a caricamento finito. Per
questo l'icona iOS si compone qui su fondo pieno (e flutter_launcher_icons ha comunque
`remove_alpha_ios: true` come seconda cintura).

☠ **Zona sicura di Android**: la tela adattiva e' 108 dp (1080 px qui), il launcher ne mostra 72 (720
px) e con la maschera rotonda garantisce solo il cerchio di 66 dp (660 px). Il disegno e' quasi
quadrato, con gli angoli verdi proprio negli angoli: per non tagliarli col cerchio la sua diagonale
deve stare nei 660 px, quindi il lato lungo e' al massimo ~466 px (LATO_ANDROID).
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

QUI = Path(__file__).resolve().parent.parent
ICONE = QUI / 'assets' / 'icon'
ORIGINALE = ICONE / 'originale.png'

FONDO = (22, 27, 34)      # #161B22, lo sfondo di «C · Una mano» (vedi l'intestazione)
TELA = 1080               # Android: 108 dp a 10 px/dp
LATO_ANDROID = 460        # lato lungo del disegno: la diagonale resta nel cerchio sicuro da 660
LATO_IOS = 800            # disegno nell'icona iOS da 1024: margine ~11% per lato
ALFA_SAGOMA = 140         # soglia dell'alfa per la monocromatica: i bordi sfumati restano fuori
SCURO_SAGOMA = 165        # sotto questo valore del canale piu' chiaro un pixel e' riga grigia o euro: buco nella sagoma


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
    """La sagoma per le icone a tema di Android 13, bianca su trasparente: il disegno pieno meno le
    righe grigie e il simbolo dell'euro (vedi l'intestazione). Si tolgono i puntini isolati."""
    px = np.array(primo).astype(int)
    a = px[..., 3]
    chiaro = px[..., :3].max(axis=2)
    pieno = (a > ALFA_SAGOMA) & (chiaro >= SCURO_SAGOMA)
    pieno = ndimage.binary_opening(pieno, iterations=2)
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

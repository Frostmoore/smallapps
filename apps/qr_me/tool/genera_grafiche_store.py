"""Le grafiche delle schede degli store di QR Me, in stile «A · Neon» (ricalcato su Film Tracker).

    python tool/genera_grafiche_store.py        (dalla cartella apps/qr_me)

Legge gli screenshot veri (store/screenshots/ios/<lingua>/, fatti da
integration_test/screenshots_test.dart con tool/screenshots_ios.sh) e scrive in store/grafiche/:

- testata-1024x500-<lingua>.png      la "grafica in primo piano" di Google Play;
- appstore/<lingua>/NN-nome.png      1320x2868, iPhone 6,9";
- appstore-6.5/<lingua>/NN-nome.png  1284x2778, iPhone 6,5": quella che App Store Connect
                                     pretende davvero nello spazio obbligatorio;
- play/<lingua>/NN-nome.png          1080x2160: Play non accetta proporzioni oltre 2:1;
- apple/intestazione-3840x1646-<lingua>.png e apple/ricerca-3840x2560-<lingua>.png: le risorse
  "Intestazione" e "Risultati della ricerca" della pagina prodotto (si caricano a mano).

Ogni scheda: titolo grande in Space Grotesk bianco e una riga sotto in Plus Jakarta Sans verde
neon, sul fondo quasi nero dell'app con un alone verde, e la schermata vera dentro la sagoma di
un telefono con un filo d'alone. Le prime tre sono quelle che si vedono nei risultati di
ricerca, quindi da sole devono dire cos'e' l'app: in ordine, il QR a tutto schermo (il gesto
principale), la home con i preferiti, la lettura. Poi il Wi-Fi senza scrivere (le tre strade di
F17.10), lo stile e l'etichetta da stampare. Niente SMS ne' Telefono: tolti in F17.10.

Prima di scrivere si cancellano i PNG vecchi di ogni cartella: i nomi hanno il numero d'ordine
(`05-modulo.png`), e una scheda spostata o tolta lascerebbe un file orfano che lo script di
caricamento manderebbe ad Apple.

Perche' composte qui e non con uno strumento grafico: le schermate sono quelle vere, i testi
stanno in questo file accanto alla traduzione, e rifarle dopo una modifica all'app e' un
comando, non un pomeriggio.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

QUI = Path(__file__).resolve().parent.parent
SCREEN = QUI / 'store' / 'screenshots' / 'ios'
USCITA = QUI / 'store' / 'grafiche'
CORPO = QUI / 'assets' / 'fonts' / 'PlusJakartaSans-Variable.ttf'
TITOLI = QUI / 'assets' / 'fonts' / 'SpaceGrotesk-Variable.ttf'
ICONA = QUI / 'assets' / 'icon' / 'icona_ios.png'

# QrPalette.dark (lib/app/qr_palette.dart), grafica «A · Neon».
FONDO = (14, 17, 16)        # #0E1110
SUPERFICIE = (21, 26, 22)   # #151A16
BORDO = (42, 51, 44)        # #2A332C
TESTO = (234, 242, 234)     # #EAF2EA
SPENTO = (143, 163, 148)    # #8FA394
NEON = (59, 209, 59)        # #3BD13B

# (file della schermata, titolo, riga sotto) per lingua, nell'ordine della scheda.
SCHEDE = {
    'it': [
        ('qr', 'Condividi.\nEcco il tuo QR.', '▸ A tutto schermo, luminoso'),
        ('home', 'Il Wi-Fi di casa,\nsempre a portata', '▸ Preferiti e cronologia'),
        ('lettura', 'Legge anche\ni QR, gratis', '▸ Dalla fotocamera o da una foto'),
        ('modulo', 'Il Wi-Fi senza\nscrivere niente', '▸ Dal suo QR, da una foto o dal telefono'),
        ('stile', 'Il tuo stile,\nsempre leggibile', '▸ Colori, forme e logo con Pro'),
        ('etichetta', "Un'etichetta\nda stampare", '▸ Il tuo QR con il testo sotto'),
    ],
    'en': [
        ('qr', 'Share it.\nHere is your QR.', '▸ Full screen and bright'),
        ('home', 'Your home Wi-Fi,\nalways at hand', '▸ Favourites and history'),
        ('lettura', 'It reads QR codes\ntoo, for free', '▸ From the camera or a photo'),
        ('modulo', 'Wi-Fi without\ntyping a thing', '▸ From its QR, a photo or your phone'),
        ('stile', 'Your style,\nstill scannable', '▸ Colours, shapes and logo with Pro'),
        ('etichetta', 'A label,\nready to print', '▸ Your QR with your text below'),
    ],
}

TESTATA = {
    'it': ('QR Me', 'Condividi qualunque cosa:\necco il suo QR.', '▸ E legge i QR, gratis'),
    'en': ('QR Me', 'Share anything:\nhere is its QR.', '▸ And it reads QR codes, free'),
}

FRASI_APPLE = {
    # (intestazione, risultati di ricerca: titolo, righe sotto). Frasi brevi: Apple chiede che
    # accompagnino l'immagine invece di descriverla, e vieta prezzi, URL e simbolo del copyright.
    'it': ('Condividi. Ecco il tuo QR.', ('Tutto diventa\nun QR', '▸ Condividi e mostra\n▸ E leggi, gratis')),
    'en': ('Share it. Here is your QR.', ('Anything becomes\na QR code', '▸ Share and show\n▸ And scan, for free')),
}


def titoli(size: int, peso: int = 700) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(TITOLI), size)
    f.set_variation_by_axes([peso])
    return f


def corpo(size: int, peso: int = 700) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(CORPO), size)
    f.set_variation_by_axes([peso])
    return f


def fondo(w: int, h: int, alone_y: float = 0.12, forza: int = 70) -> Image.Image:
    """Il nero dell'app con un alone verde dietro il titolo, e un secondo, piu' debole, in basso."""
    img = Image.new('RGB', (w, h), FONDO)
    alone = Image.new('L', (w, h), 0)
    d = ImageDraw.Draw(alone)
    d.ellipse((-w * 0.25, h * (alone_y - 0.2), w * 1.25, h * (alone_y + 0.22)), fill=forza)
    d.ellipse((w * 0.1, h * 0.72, w * 0.9, h * 1.15), fill=forza // 3)
    alone = alone.filter(ImageFilter.GaussianBlur(max(w, h) // 9))
    img.paste(Image.new('RGB', (w, h), NEON), (0, 0), alone)
    return img


def angoli(img: Image.Image, r: int) -> Image.Image:
    m = Image.new('L', img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, img.width - 1, img.height - 1), r, fill=255)
    out = img.convert('RGBA')
    out.putalpha(m)
    return out


def telefono(schermata: Image.Image, larghezza: int) -> Image.Image:
    """La schermata vera dentro una cornice scura arrotondata con il filo del bordo Neon."""
    bordo = round(larghezza * 0.022)
    interno = larghezza - 2 * bordo
    s = schermata.convert('RGB').resize((interno, round(schermata.height * interno / schermata.width)), Image.LANCZOS)
    r_int = round(interno * 0.11)
    cornice = Image.new('RGBA', (larghezza, s.height + 2 * bordo), (0, 0, 0, 0))
    d = ImageDraw.Draw(cornice)
    d.rounded_rectangle((0, 0, cornice.width - 1, cornice.height - 1), r_int + bordo, fill=SUPERFICIE + (255,),
                        outline=BORDO + (255,), width=max(2, bordo // 5))
    cornice.alpha_composite(angoli(s, r_int), (bordo, bordo))
    return cornice


def con_alone(base: Image.Image, oggetto: Image.Image, xy, sfoc: int):
    """Un alone verde attorno alla sagoma (il «glow» dei pannelli dell'app), poi l'oggetto."""
    alone = Image.new('RGBA', base.size, (0, 0, 0, 0))
    sagoma = Image.new('RGBA', oggetto.size, NEON + (0,))
    sagoma.putalpha(oggetto.getchannel('A').point(lambda a: a * 90 // 255))
    alone.alpha_composite(sagoma, (xy[0], xy[1]))
    alone = alone.filter(ImageFilter.GaussianBlur(sfoc))
    base.alpha_composite(alone)
    base.alpha_composite(oggetto, xy)


def riga_a_bordo(d: ImageDraw.ImageDraw, x: float, y: float, riga: str, f, colore) -> None:
    """Una riga; il "▸" iniziale lo disegna come triangolino pieno.

    ☠ Come in Film Tracker: non tutti i caratteri hanno il glifo ▸ (U+25B8) e Pillow, senza il
    ripiego di Flutter, disegnerebbe un quadratino. Disegnarlo non dipende dal font.
    """
    if riga.startswith('▸'):
        lato = f.size * 0.55
        top = y + f.size * 0.36
        d.polygon([(x, top), (x + lato * 0.9, top + lato / 2), (x, top + lato)], fill=colore)
        x += f.size * 0.9
        riga = riga[1:].lstrip()
    d.text((x, y), riga, font=f, fill=colore)


def larghezza_a_bordo(d: ImageDraw.ImageDraw, riga: str, f) -> float:
    if riga.startswith('▸'):
        resto = riga[1:].lstrip()
        box = d.textbbox((0, 0), resto, font=f)
        return f.size * 0.9 + (box[2] - box[0])
    box = d.textbbox((0, 0), riga, font=f)
    return box[2] - box[0]


def testo_centrato(d: ImageDraw.ImageDraw, w: int, y: int, testo: str, f, colore, interlinea=1.1) -> int:
    for riga in testo.split('\n'):
        if riga.startswith('▸'):
            riga_a_bordo(d, (w - larghezza_a_bordo(d, riga, f)) / 2, y, riga, f, colore)
        else:
            box = d.textbbox((0, 0), riga, font=f)
            d.text(((w - (box[2] - box[0])) / 2 - box[0], y), riga, font=f, fill=colore)
        y += round(f.size * interlinea)
    return y


def scheda(lingua: str, nome: str, titolo: str, sotto: str, w: int, h: int) -> Image.Image:
    img = fondo(w, h).convert('RGBA')
    d = ImageDraw.Draw(img)
    k = w / 1320
    y = testo_centrato(d, w, round(190 * k), titolo, titoli(round(116 * k)), (255, 255, 255))
    y = testo_centrato(d, w, y + round(26 * k), sotto, corpo(round(46 * k), 700), NEON)
    schermata = Image.open(SCREEN / lingua / f'{nome}.png')
    lt = round(w * 0.78)
    tel = telefono(schermata, lt)
    ty = y + round(70 * k)
    con_alone(img, tel, ((w - lt) // 2, ty), round(40 * k))
    return img.convert('RGB')


def icona(lato: int) -> Image.Image:
    return angoli(Image.open(ICONA).convert('RGB').resize((lato, lato), Image.LANCZOS), round(lato * 0.225))


def testata(lingua: str) -> Image.Image:
    w, h = 1024, 500
    img = fondo(w, h, alone_y=0.5, forza=55).convert('RGBA')
    d = ImageDraw.Draw(img)
    nome, frase, sotto = TESTATA[lingua]
    d.text((72, 110), nome, font=titoli(72), fill=(255, 255, 255))
    y = 214
    for riga in frase.split('\n'):
        d.text((74, y), riga, font=corpo(32, 600), fill=TESTO)
        y += 44
    riga_a_bordo(d, 74, y + 18, sotto, corpo(24, 700), NEON)
    con_alone(img, icona(280), (w - 280 - 100, (h - 280) // 2), 30)
    return img.convert('RGB')


def fila_di_telefoni(img, lingua, nomi, altezza, cx, cy, passo, scala_lati=0.86):
    """Telefoni affiancati, quello centrale piu' grande e davanti: profondita' senza prospettive finte."""
    centro = len(nomi) // 2
    ordine = sorted(range(len(nomi)), key=lambda i: -abs(i - centro))
    for i in ordine:
        sch = Image.open(SCREEN / lingua / f'{nomi[i]}.png')
        h = altezza if i == centro else round(altezza * scala_lati)
        tel = telefono(sch, round(h * sch.width / sch.height))
        x = round(cx + (i - centro) * passo - tel.width / 2)
        y = round(cy - tel.height / 2)
        con_alone(img, tel, (x, y), round(altezza * 0.03))


def intestazione_apple(lingua: str) -> Image.Image:
    """La testata della pagina prodotto: 3840x1646 (21:9), senza trasparenza.

    Apple taglia i bordi a seconda del dispositivo: tutto l'importante sta nel centro, i
    telefoni laterali possono perdere un pezzo senza danno.
    """
    w, h = 3840, 1646
    img = fondo(w, h, alone_y=0.05, forza=60).convert('RGBA')
    d = ImageDraw.Draw(img)
    frase = FRASI_APPLE[lingua][0]
    f = titoli(118)
    box = d.textbbox((0, 0), frase, font=f)
    d.text(((w - (box[2] - box[0])) / 2 - box[0], 120), frase, font=f, fill=(255, 255, 255))
    fila_di_telefoni(img, lingua, ['lettura', 'qr', 'home'], altezza=1420, cx=w // 2, cy=1080, passo=760)
    return img.convert('RGB')


def ricerca_apple(lingua: str) -> Image.Image:
    """La risorsa dei risultati di ricerca: 3:2 a 3840x2560, senza trasparenza.

    "State the obvious": a sinistra cosa fa l'app in due righe, a destra l'interfaccia vera.
    """
    w, h = 3840, 2560
    img = fondo(w, h, alone_y=0.45, forza=50).convert('RGBA')
    d = ImageDraw.Draw(img)
    titolo, sotto = FRASI_APPLE[lingua][1]
    y = 860
    for riga in titolo.split('\n'):
        d.text((260, y), riga, font=titoli(160), fill=(255, 255, 255))
        y += 186
    y += 70
    for riga in sotto.split('\n'):
        riga_a_bordo(d, 264, y, riga, corpo(72, 700), NEON)
        y += 108
    fila_di_telefoni(img, lingua, ['home', 'qr'], altezza=2240, cx=2860, cy=h // 2 + 40, passo=560, scala_lati=0.9)
    return img.convert('RGB')


def main():
    for lingua in ('it', 'en'):
        USCITA.mkdir(parents=True, exist_ok=True)
        testata(lingua).save(USCITA / f'testata-1024x500-{lingua}.png')
        (USCITA / 'apple').mkdir(exist_ok=True)
        intestazione_apple(lingua).save(USCITA / 'apple' / f'intestazione-3840x1646-{lingua}.png')
        ricerca_apple(lingua).save(USCITA / 'apple' / f'ricerca-3840x2560-{lingua}.png')
        # ☠ App Store Connect chiede la misura da 6,5" (1284x2778) e rifiuta le 6,9" trascinate in
        #   quello spazio (lezione di TrashCan, 2026-10-05): si compongono tutte e due, native.
        for cartella, (w, h) in (('appstore', (1320, 2868)), ('appstore-6.5', (1284, 2778)), ('play', (1080, 2160))):
            dest = USCITA / cartella / lingua
            dest.mkdir(parents=True, exist_ok=True)
            for vecchio in dest.glob('*.png'):
                vecchio.unlink()
            for i, (nome, titolo, sotto) in enumerate(SCHEDE[lingua], 1):
                scheda(lingua, nome, titolo, sotto, w, h).save(dest / f'{i:02d}-{nome}.png')
        print(f'{lingua}: testata, intestazione, ricerca e {len(SCHEDE[lingua])} schede per store')


if __name__ == '__main__':
    main()

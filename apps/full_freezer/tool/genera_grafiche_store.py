"""Le grafiche delle schede degli store di Full Freezer.

    python tool/genera_grafiche_store.py

Legge gli screenshot veri (store/screenshots/ios/<lingua>/, fatti da
integration_test/screenshots_test.dart con tool/screenshots_ios.sh) e il widget disegnato
dall'anteprima Mac (store/grafiche/sorgenti/widget_<lingua>.png, da
tool/anteprima_widget_ios.swift --vetrina), e scrive in store/grafiche/:

- testata-1024x500-<lingua>.png      la "grafica in primo piano" di Google Play;
- appstore/<lingua>/NN-nome.png      1320x2868, la misura da 6,9" che App Store Connect
                                     pretende (le altre le ricava da sola);
- play/<lingua>/NN-nome.png          1080x2160: Play non accetta proporzioni oltre 2:1.

Ogni scheda: titolo grande e una riga sotto, sul blu dell'app, e la schermata vera dentro
la sagoma di un telefono. Le prime tre sono quelle che si vedono nei risultati di ricerca,
quindi da sole devono dire cos'e' l'app: in ordine, la home, l'inserimento, il widget.

Perche' composte qui e non con uno strumento grafico: le schermate sono quelle vere, i
testi stanno in questo file accanto alla traduzione, e rifarle dopo una modifica all'app
e' un comando, non un pomeriggio.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

QUI = Path(__file__).resolve().parent.parent
SCREEN = QUI / 'store' / 'screenshots' / 'ios'
USCITA = QUI / 'store' / 'grafiche'
FONT = QUI / 'assets' / 'fonts' / 'PlusJakartaSans-Variable.ttf'
LOGO = QUI / 'assets' / 'icons' / 'fullfreezer_logo.png'

BLU = (4, 97, 229)
NOTTE = (11, 26, 51)
GHIACCIO = (143, 184, 255)
SPENTO = (207, 224, 255)

# (file della schermata, titolo, sottotitolo) per lingua. None = il widget.
SCHEDE = {
    'it': [
        ('home', 'Il più vecchio,\nsempre in cima', "E quanto è pieno il freezer, a colpo d'occhio"),
        ('inserimento', 'Dentro in tre tocchi', 'Anche a voce o con una foto'),
        (None, "Lo vedi senza\naprire l'app", 'Il widget conta i giorni da solo'),
        ('freezer', 'Sai quanto\nspazio resta', 'Dal cassetto del frigo al pozzetto da 350 litri'),
        ('storico', 'Cosa hai mangiato,\ncosa hai buttato', 'Ogni uscita dal freezer, giorno per giorno'),
        ('statistiche', 'Scopri cosa\nsprechi', 'Storico e statistiche con Pro'),
    ],
    'en': [
        ('home', 'The oldest,\nalways on top', 'And how full your freezer is, at a glance'),
        ('inserimento', 'In the freezer\nin three taps', 'Or by voice, or with a photo'),
        (None, 'See it without\nopening the app', 'The widget counts the days by itself'),
        ('freezer', 'Know how much\nroom is left', 'From the fridge drawer to a 350-litre chest'),
        ('storico', 'What you ate,\nwhat you threw away', 'Everything that left the freezer, day by day'),
        ('statistiche', 'See what\nyou waste', 'History and statistics with Pro'),
    ],
}

TESTATA = {
    'it': ('Full Freezer', "Cosa c'è nel freezer,\ne da quanto tempo.", 'Il più vecchio sempre in cima.'),
    'en': ('Full Freezer', "What's in your freezer,\nand since when.", 'The oldest always on top.'),
}


def font(size: int, peso: int) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(FONT), size)
    f.set_variation_by_axes([peso])
    return f


def sfumatura(w: int, h: int, alto=BLU, basso=NOTTE) -> Image.Image:
    """Dal blu dell'app in alto al blu notte in basso, con un alone chiaro dietro il titolo."""
    g = Image.new('RGB', (1, h))
    for y in range(h):
        t = min(1.0, max(0.0, (y / h - 0.05) / 0.85))
        g.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(alto, basso)))
    img = g.resize((w, h))
    alone = Image.new('L', (w, h), 0)
    ImageDraw.Draw(alone).ellipse((-w * 0.2, -h * 0.12, w * 1.2, h * 0.32), fill=70)
    alone = alone.filter(ImageFilter.GaussianBlur(w // 6))
    img.paste(Image.new('RGB', (w, h), (120, 175, 255)), (0, 0), alone)
    return img


def angoli(img: Image.Image, r: int) -> Image.Image:
    m = Image.new('L', img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, img.width - 1, img.height - 1), r, fill=255)
    out = img.convert('RGBA')
    out.putalpha(m)
    return out


def telefono(schermata: Image.Image, larghezza: int) -> Image.Image:
    """La schermata vera dentro una cornice scura arrotondata, come un iPhone di fronte."""
    bordo = round(larghezza * 0.022)
    interno = larghezza - 2 * bordo
    s = schermata.convert('RGB').resize((interno, round(schermata.height * interno / schermata.width)), Image.LANCZOS)
    r_int = round(interno * 0.11)
    cornice = Image.new('RGBA', (larghezza, s.height + 2 * bordo), (0, 0, 0, 0))
    ImageDraw.Draw(cornice).rounded_rectangle(
        (0, 0, cornice.width - 1, cornice.height - 1), r_int + bordo, fill=(8, 14, 28, 255))
    cornice.alpha_composite(angoli(s, r_int), (bordo, bordo))
    return cornice


def con_ombra(base: Image.Image, oggetto: Image.Image, xy, sfoc: int):
    ombra = Image.new('RGBA', base.size, (0, 0, 0, 0))
    sagoma = Image.new('RGBA', oggetto.size, (0, 0, 0, 120))
    sagoma.putalpha(oggetto.getchannel('A').point(lambda a: a * 120 // 255))
    ombra.alpha_composite(sagoma, (xy[0], xy[1] + sfoc // 2))
    ombra = ombra.filter(ImageFilter.GaussianBlur(sfoc))
    base.alpha_composite(ombra)
    base.alpha_composite(oggetto, xy)


def testo_centrato(d: ImageDraw.ImageDraw, w: int, y: int, testo: str, f, colore, interlinea=1.08) -> int:
    for riga in testo.split('\n'):
        box = d.textbbox((0, 0), riga, font=f)
        d.text(((w - (box[2] - box[0])) / 2 - box[0], y), riga, font=f, fill=colore)
        y += round(f.size * interlinea)
    return y


def scheda(lingua: str, nome, titolo: str, sotto: str, w: int, h: int) -> Image.Image:
    img = sfumatura(w, h).convert('RGBA')
    d = ImageDraw.Draw(img)
    k = w / 1320
    y = testo_centrato(d, w, round(190 * k), titolo, font(round(118 * k), 800), (255, 255, 255))
    y = testo_centrato(d, w, y + round(28 * k), sotto, font(round(54 * k), 500), SPENTO)

    if nome is None:
        # Il widget, grande, su una finta schermata di casa sfocata: si capisce che sta fuori
        # dall'app senza disegnare un iPhone intero.
        widget = Image.open(USCITA / 'sorgenti' / f'widget_{lingua}.png').convert('RGBA')
        lw = round(w * 0.86)
        widget = widget.resize((lw, round(widget.height * lw / widget.width)), Image.LANCZOS)
        piccolo = widget.resize((round(lw * 0.47), round(widget.height * 0.47)), Image.LANCZOS)
        cy = y + round((h - y) * 0.2)
        con_ombra(img, widget, ((w - lw) // 2, cy), round(40 * k))
        # Le icone di app finte sotto il widget: quadrati sfumati, come una schermata Home.
        lato = round(150 * k)
        passo = round((lw - 4 * lato) / 3)
        icone_y = cy + widget.height + round(120 * k)
        for riga in range(3):
            for col in range(4):
                x0 = (w - lw) // 2 + col * (lato + passo)
                y0 = icone_y + riga * (lato + round(110 * k))
                tinta = [(255, 255, 255, 46), (143, 184, 255, 60), (255, 255, 255, 34), (79, 155, 255, 70)][(col + riga) % 4]
                quad = Image.new('RGBA', (lato, lato), (0, 0, 0, 0))
                ImageDraw.Draw(quad).rounded_rectangle((0, 0, lato - 1, lato - 1), round(lato * 0.23), fill=tinta)
                img.alpha_composite(quad, (x0, y0))
        del piccolo
        return img.convert('RGB')

    schermata = Image.open(SCREEN / lingua / f'{nome}.png')
    lt = round(w * 0.78)
    tel = telefono(schermata, lt)
    ty = y + round(70 * k)
    con_ombra(img, tel, ((w - lt) // 2, ty), round(36 * k))
    return img.convert('RGB')


def testata(lingua: str) -> Image.Image:
    w, h = 1024, 500
    img = sfumatura(w, h, alto=(7, 84, 214), basso=NOTTE).convert('RGBA')
    d = ImageDraw.Draw(img)
    nome, frase, sotto = TESTATA[lingua]
    d.text((72, 120), nome, font=font(64, 800), fill=(255, 255, 255))
    y = 214
    for riga in frase.split('\n'):
        d.text((74, y), riga, font=font(34, 600), fill=GHIACCIO)
        y += 44
    d.text((74, y + 18), sotto, font=font(26, 500), fill=SPENTO)
    logo = Image.open(LOGO).convert('RGBA').resize((300, 300), Image.LANCZOS)
    logo = angoli(logo, 66)
    con_ombra(img, logo, (w - 300 - 92, (h - 300) // 2), 26)
    return img.convert('RGB')


def main():
    for lingua in ('it', 'en'):
        testata(lingua).save(USCITA / f'testata-1024x500-{lingua}.png')
        for cartella, (w, h) in (('appstore', (1320, 2868)), ('play', (1080, 2160))):
            dest = USCITA / cartella / lingua
            dest.mkdir(parents=True, exist_ok=True)
            for i, (nome, titolo, sotto) in enumerate(SCHEDE[lingua], 1):
                scheda(lingua, nome, titolo, sotto, w, h).save(dest / f'{i:02d}-{nome or "widget"}.png')
        print(f'{lingua}: testata e {len(SCHEDE[lingua])} schede per store')


if __name__ == '__main__':
    main()

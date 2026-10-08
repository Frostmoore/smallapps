"""Le grafiche delle schede degli store di Film Tracker (ricalcato su Scorte Calore).

    python tool/genera_grafiche_store.py

Legge gli screenshot veri (store/screenshots/ios/<lingua>/, fatti da
integration_test/screenshots_test.dart con tool/screenshots_ios.sh) e il widget disegnato
dall'anteprima Mac (qui non serve: Film Tracker non ha widget), e scrive in store/grafiche/:

- testata-1024x500-<lingua>.png      la "grafica in primo piano" di Google Play;
- appstore/<lingua>/NN-nome.png      1320x2868, iPhone 6,9";
- appstore-6.5/<lingua>/NN-nome.png  1284x2778, iPhone 6,5": quella che App Store Connect
                                     pretende davvero nello spazio obbligatorio;
- play/<lingua>/NN-nome.png          1080x2160: Play non accetta proporzioni oltre 2:1.

Ogni scheda: titolo grande e una riga sotto a bordo pellicola (Space Mono arancio), sul nero della
pellicola con un alone d'arancio, e la schermata vera dentro
la sagoma di un telefono. Le prime tre sono quelle che si vedono nei risultati di ricerca,
quindi da sole devono dire cos'e' l'app: in ordine, il provino, la home, il dettaglio.

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
LOGO = QUI / 'assets' / 'icons' / 'filmtracker_logo.png'
MONO = QUI / 'assets' / 'fonts' / 'SpaceMono-Bold.ttf'

# FilmPalette.dark (lib/app/film_palette.dart): nero pellicola e arancio a bordo.
BLU = (34, 29, 24)
NOTTE = (13, 12, 11)
GHIACCIO = (240, 163, 59)
SPENTO = (237, 230, 218)
BRACE = (240, 163, 59)

# (file della schermata, titolo, sottotitolo) per lingua. None = il widget.
SCHEDE = {
    'it': [
        ('provino', 'Il tuo archivio,\ncome un provino', '▸ Ogni rullino con le sue foto'),
        ('home', 'Dalla macchina\nal laboratorio', "▸ Sai sempre dov'è ogni rullino"),
        ('dettaglio', 'Ogni rullino\nha la sua storia', '▸ Date, sviluppo, stampe e costi'),
        ('qr', "Un'etichetta\nper il barattolo", '▸ Inquadrala e si apre il rullino'),
        ('statistiche', 'Quanto scatti,\nquanto spendi', "▸ Statistiche dell'anno con Pro"),
    ],
    'en': [
        ('provino', 'Your archive,\nas a contact sheet', '▸ Every roll with its photos'),
        ('home', 'From the camera\nto the lab', '▸ Always know where each roll is'),
        ('dettaglio', 'Every roll\nhas its story', '▸ Dates, developing, prints, costs'),
        ('qr', 'A label\nfor the canister', '▸ Scan it to open the roll'),
        ('statistiche', 'What you shoot,\nwhat you spend', '▸ Yearly statistics with Pro'),
    ],
}

TESTATA = {
    'it': ('Film Tracker', 'Il diario dei tuoi\nrullini analogici.', '▸ Dalla macchina al provino'),
    'en': ('Film Tracker', 'The diary of your\nfilm rolls.', '▸ From the camera to the contact sheet'),
}


def mono(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(MONO), size)


def font(size: int, peso: int) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(FONT), size)
    f.set_variation_by_axes([peso])
    return f


def sfumatura(w: int, h: int, alto=BLU, basso=NOTTE) -> Image.Image:
    """Dal blu notte chiaro in alto al blu notte in basso, con un alone di brace dietro il titolo."""
    g = Image.new('RGB', (1, h))
    for y in range(h):
        t = min(1.0, max(0.0, (y / h - 0.05) / 0.85))
        g.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(alto, basso)))
    img = g.resize((w, h))
    alone = Image.new('L', (w, h), 0)
    ImageDraw.Draw(alone).ellipse((-w * 0.2, -h * 0.12, w * 1.2, h * 0.32), fill=60)
    alone = alone.filter(ImageFilter.GaussianBlur(w // 6))
    img.paste(Image.new('RGB', (w, h), BRACE), (0, 0), alone)
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


def riga_a_bordo(d: ImageDraw.ImageDraw, x: float, y: float, riga: str, f, colore) -> None:
    """Una riga in Space Mono; il "▸" iniziale lo disegna come triangolino pieno.

    ☠ Space Mono non ha il glifo ▸ (U+25B8): Pillow lo disegna come un quadratino. Nell'app
    non si vede perche' Flutter ripiega su un altro carattere; qui il ripiego non c'e'.
    """
    if riga.startswith('▸'):
        lato = f.size * 0.55
        top = y + f.size * 0.38
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


def testo_centrato(d: ImageDraw.ImageDraw, w: int, y: int, testo: str, f, colore, interlinea=1.08) -> int:
    for riga in testo.split('\n'):
        if riga.startswith('▸'):
            riga_a_bordo(d, (w - larghezza_a_bordo(d, riga, f)) / 2, y, riga, f, colore)
        else:
            box = d.textbbox((0, 0), riga, font=f)
            d.text(((w - (box[2] - box[0])) / 2 - box[0], y), riga, font=f, fill=colore)
        y += round(f.size * interlinea)
    return y


def scheda(lingua: str, nome, titolo: str, sotto: str, w: int, h: int) -> Image.Image:
    img = sfumatura(w, h).convert('RGBA')
    d = ImageDraw.Draw(img)
    k = w / 1320
    y = testo_centrato(d, w, round(190 * k), titolo, font(round(118 * k), 800), (255, 255, 255))
    y = testo_centrato(d, w, y + round(30 * k), sotto.upper(), mono(round(40 * k)), GHIACCIO)

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
                tinta = [(255, 255, 255, 40), (255, 154, 98, 60), (255, 255, 255, 30), (244, 81, 30, 70)][(col + riga) % 4]
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
    img = sfumatura(w, h, alto=BLU, basso=NOTTE).convert('RGBA')
    d = ImageDraw.Draw(img)
    nome, frase, sotto = TESTATA[lingua]
    d.text((72, 120), nome, font=font(64, 800), fill=(255, 255, 255))
    y = 214
    for riga in frase.split('\n'):
        d.text((74, y), riga, font=font(34, 600), fill=SPENTO)
        y += 44
    riga_a_bordo(d, 74, y + 18, sotto.upper(), mono(20), GHIACCIO)
    logo = Image.open(LOGO).convert('RGBA').resize((300, 300), Image.LANCZOS)
    con_ombra(img, logo, (w - 300 - 92, (h - 300) // 2), 26)
    return img.convert('RGB')


FRASI_APPLE = {
    # (intestazione, risultati di ricerca: titolo, riga sotto). Frasi brevi: Apple chiede che
    # accompagnino l'immagine invece di descriverla, e vieta prezzi, URL e simbolo del copyright.
    'it': ('Il diario dei tuoi rullini', ('Ogni rullino,\ndal carico al provino', '▸ Sviluppo, stampe e costi\n▸ Le foto in archivio')),
    'en': ('The diary of your film rolls', ('Every roll, from\nloading to contact sheet', '▸ Developing, prints, costs\n▸ Photos in the archive')),
}


def fila_di_telefoni(img, lingua, nomi, altezza, cx, cy, passo, scala_lati=0.86):
    """Telefoni affiancati, quello centrale piu' grande e davanti: profondita' senza prospettive finte."""
    centro = len(nomi) // 2
    ordine = sorted(range(len(nomi)), key=lambda i: -abs(i - centro))
    for i in ordine:
        sch = Image.open(SCREEN / lingua / f'{nomi[i]}.png')
        h = altezza if i == centro else round(altezza * scala_lati)
        w = round(h * sch.width / sch.height)
        tel = telefono(sch, round(w / (1 - 2 * 0.022) * (1 - 2 * 0.022)))
        x = round(cx + (i - centro) * passo - tel.width / 2)
        y = round(cy - tel.height / 2)
        con_ombra(img, tel, (x, y), round(altezza * 0.03))


def intestazione_apple(lingua: str) -> Image.Image:
    """La testata della pagina prodotto: 3840x1646 (21:9), senza trasparenza.

    Apple taglia i bordi a seconda del dispositivo: tutto l'importante sta nel centro, i
    telefoni laterali possono perdere un pezzo senza danno.
    """
    w, h = 3840, 1646
    img = sfumatura(w, h, alto=BLU, basso=NOTTE).convert('RGBA')
    d = ImageDraw.Draw(img)
    frase = FRASI_APPLE[lingua][0]
    f = font(118, 800)
    box = d.textbbox((0, 0), frase, font=f)
    d.text(((w - (box[2] - box[0])) / 2 - box[0], 120), frase, font=f, fill=(255, 255, 255))
    fila_di_telefoni(img, lingua, ['dettaglio', 'provino', 'home'], altezza=1420, cx=w // 2, cy=1080, passo=760)
    return img.convert('RGB')


def ricerca_apple(lingua: str) -> Image.Image:
    """La risorsa dei risultati di ricerca: 3:2 a 3840x2560, senza trasparenza.

    "State the obvious": a sinistra cosa fa l'app in due righe, a destra l'interfaccia vera.
    """
    w, h = 3840, 2560
    img = sfumatura(w, h, alto=BLU, basso=NOTTE).convert('RGBA')
    d = ImageDraw.Draw(img)
    titolo, sotto = FRASI_APPLE[lingua][1]
    y = 860
    for riga in titolo.split('\n'):
        d.text((260, y), riga, font=font(150, 800), fill=(255, 255, 255))
        y += 176
    y += 70
    for riga in sotto.split('\n'):
        riga_a_bordo(d, 264, y, riga.upper(), mono(64), GHIACCIO)
        y += 100
    fila_di_telefoni(img, lingua, ['home', 'provino'], altezza=2240, cx=2860, cy=h // 2 + 40, passo=560, scala_lati=0.9)
    return img.convert('RGB')


def main():
    for lingua in ('it', 'en'):
        testata(lingua).save(USCITA / f'testata-1024x500-{lingua}.png')
        (USCITA / 'apple').mkdir(exist_ok=True)
        intestazione_apple(lingua).save(USCITA / 'apple' / f'intestazione-3840x1646-{lingua}.png')
        ricerca_apple(lingua).save(USCITA / 'apple' / f'ricerca-3840x2560-{lingua}.png')
        # ☠ App Store Connect chiede la misura da 6,5" (1284x2778) e rifiuta le 6,9" trascinate in
        #   quello spazio (lezione di TrashCan, 2026-10-05): si compongono tutte e due, native.
        for cartella, (w, h) in (('appstore', (1320, 2868)), ('appstore-6.5', (1284, 2778)), ('play', (1080, 2160))):
            dest = USCITA / cartella / lingua
            dest.mkdir(parents=True, exist_ok=True)
            for i, (nome, titolo, sotto) in enumerate(SCHEDE[lingua], 1):
                scheda(lingua, nome, titolo, sotto, w, h).save(dest / f'{i:02d}-{nome or "widget"}.png')
        print(f'{lingua}: testata e {len(SCHEDE[lingua])} schede per store')


if __name__ == '__main__':
    main()

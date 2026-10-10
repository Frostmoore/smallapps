"""Crea le fixture del banco di regressione del parser (develop_microapps.md F12.1.17).

    set ORT_DISABLE_TELEMETRY=1
    <venv>\\Scripts\\python -I esporta_fixture_ocr.py <cartella_campioni> \\
        --licenze-libere <repo>/apps/spending_review/test/fixtures/ocr \\
        --altre <cartella_campioni>/fixture

Legge <cartella_campioni>/campioni.csv (file;tipo;fonte_url;licenza;autore;negozio;verita;note),
fa girare RapidOCR 3.10 con **gli stessi modelli dell'app Android** (rilevatore
`ch_PP-OCRv5_det_mobile`, riconoscitore `latin_PP-OCRv5_rec_mobile`) su ogni immagine e scrive,
per ognuna, `ppocrv5/<nome-campione>.json` con le righe lette (testo, riquadro normalizzato,
confidenza) e la verita' del CSV. Nessuna immagine esce dalla cartella dei campioni.

⚑ **Dove finisce ogni fixture**: i campioni a licenza libera (pubblico dominio, CC BY, CC BY-SA:
33 su 60) vanno nel repo (`--licenze-libere`), con `LICENZE.md` accanto (autore, fonte, licenza:
CC BY e BY-SA chiedono l'attribuzione, e una trascrizione si distribuisce con la stessa licenza);
gli altri (CC BY-NC, licenza sconosciuta) vanno FUORI dal repo (`--altre`), e il banco li legge
solo con la variabile d'ambiente `SR_CAMPIONI`.

⚑ **Classificatore dell'angolo (cls) ACCESO, come RapidOCR di default**: e' la configurazione con
cui sono state fatte le misure di f12-ocr.md §7 (bilance e scontrini al 100% sul totale). Spento,
b09 (etichetta capovolta) non si legge piu'. ☠ La catena Kotlin di F12.1.9 NON ha il cls: il test di
parita' di F12.2b lo dira' sulle foto capovolte; nell'app l'utente inquadra dritto nel mirino.

⚑ **Riquadro**: RapidOCR da' 4 punti (quadrilatero, anche inclinato); qui diventa il rettangolo
allineato agli assi che lo contiene, normalizzato 0..1 sull'immagine DOPO la rotazione EXIF
(come fa il motore Kotlin, F12.1.9 punto 6), origine in alto a sinistra.

☠ **Dati della carta** (s13 e simili): le righe che combaciano con RIPULISCI si tolgono PRIMA di
scrivere, su tutti i tipi, e negli scontrini si taglia tutto dalla prima riga di INIZIO_POS in giu'
(lo scontrino del POS stampato in coda); le righe si scrivono ordinate dall'alto in basso; il banco Dart fallisce se in una fixture del repo trova `\\*{4}\\d{4}`.

Modalita' MIRINO (F12.7): con `--ritagli test/fixtures/ocr/ritagli_mirino.json` lo script non
legge le foto intere ma i **ritagli dei singoli cartellini**, come li fa il mirino dell'app (4:3
orizzontale), e scrive `ppocrv5-mirino/<campione>_r<k>.json` con UNA verita' per file (quella del
cartellino ritagliato). ⚑ Perche': le foto del web sono larghe (scaffali interi, piu' cartellini),
mentre nell'app l'utente inquadra un cartellino solo; misurare il parser solo sulle foto larghe
vuol dire tararlo sul caso sbagliato. Il banco Dart tratta `ppocrv5-mirino` come un motore a se'
(cricchetto separato). Il ritaglio si fa in memoria: nessuna immagine viene scritta su disco.

Modalita' LOG (F12.7): `--log <file> --motore vision-sim [--ritagli ritagli_mirino.json]` converte
il log del banco sul dispositivo (`MICRO_OCR|<json>`, da
`packages/micro_ocr/example/integration_test/ocr_parita_test.dart`) nelle fixture di quel motore:
`vision-sim/` per le foto intere e `vision-sim-mirino/` per i ritagli (`<campione>_r<k>.jpg`). Vedi
`da_log()`.
"""
import argparse
import csv
import datetime as dt
import json
import os
import re
import sys
from pathlib import Path

os.environ.setdefault("ORT_DISABLE_TELEMETRY", "1")  # onnxruntime >= 1.29: 1DS acceso di default

RIPULISCI = re.compile(
    r"\*{3,}\d{3,4}|aut(orizzazione)?\.?\s*\d|terminale|term\.|id\s*trans|n\.?\s*operazione|stan\b|a\.?i\.?d\.?|"
    # ☠ F12.7: Vision legge il PAN mascherato con le «x» («673703xxxxxxxxx7034», s13), non con gli
    # asterischi di RapidOCR; e i codici del POS («S/E-CE 0001…», «CASSA 004 ID 0690…»).
    r"x{4,}\d{3,4}|\d{4,}x{4,}|s/e-ce|\bid\s*\d{6,}",
    re.IGNORECASE,
)
# ⚑ Oltre alle righe singole: lo scontrino del POS stampato in coda al documento commerciale
# (s13: «DETTAGLIO PAGAMENTI», «EDC-MAESTRO», PAN mascherato, codici EMV) si taglia INTERO, dalla
# prima riga che lo annuncia in giu'. Il parser butta comunque il piede, ma qui si parla di cosa
# finisce nel repo: dati di una carta non ci devono stare nemmeno «tanto non li legge nessuno».
INIZIO_POS = re.compile(
    r"dettaglio\s*pagament|edc-|cod\.?\s*aut|transazione\s*autorizzata|esercente|acquirer|\*\d{4}|"
    # ☠ F12.7 (Vision su s13): «Paganento Maestro» / «Paaamento Maestrc» aprono la ricevuta del POS.
    r"pag\w{2,6}to\s+maestr|\bmaestr[oc]\b|x{4,}\d{4}",
    re.IGNORECASE,
)
MOTORE = "ppocrv5-mobile-latin/rapidocr-3.10"


def licenza_libera(licenza: str) -> bool:
    l = licenza.strip().lower()
    if l.startswith("public domain") or l.startswith("pubblico dominio"):
        return True
    return l.startswith("cc by") and "nc" not in l and "nd" not in l


def verita(testo: str):
    """`k=v|k=v || k=v` → [{k: v}, ...] (una voce per cartellino della foto)."""
    voci = []
    for blocco in testo.split("||"):
        voce = {}
        for coppia in blocco.split("|"):
            if "=" in coppia:
                k, v = coppia.split("=", 1)
                voce[k.strip()] = v.strip()
        if voce:
            voci.append(voce)
    return voci


def motore():
    from rapidocr import LangDet, LangRec, ModelType, OCRVersion, RapidOCR

    params = {
        "Det.ocr_version": OCRVersion.PPOCRV5, "Det.model_type": ModelType.MOBILE, "Det.lang_type": LangDet.CH,
        "Rec.ocr_version": OCRVersion.PPOCRV5, "Rec.model_type": ModelType.MOBILE, "Rec.lang_type": LangRec.LATIN,
    }
    return RapidOCR(params=params)


def ritaglio_px(larghezza: int, altezza: int, rit: dict):
    """Il rettangolo in pixel di un ritaglio di `ritagli_mirino.json`: 4:3 orizzontale, spostato
    dentro l'immagine se sfora, ridotto (sempre 4:3) se e' piu' alto dell'immagine."""
    w = rit["w"] * larghezza
    h = w * 3 / 4
    if h > altezza:
        h = altezza
        w = h * 4 / 3
    w = min(w, larghezza)
    x0 = min(max(rit["cx"] * larghezza - w / 2, 0), larghezza - w)
    y0 = min(max(rit["cy"] * altezza - h / 2, 0), altezza - h)
    return int(round(x0)), int(round(y0)), int(round(x0 + w)), int(round(y0 + h))


def righe_ocr(eng, percorso: Path, rit: dict | None = None):
    import numpy as np
    from PIL import Image, ImageOps

    with Image.open(percorso) as im:
        im = ImageOps.exif_transpose(im).convert("RGB")
        if rit is not None:
            im = im.crop(ritaglio_px(im.width, im.height, rit))
        larghezza, altezza = im.size
        # ⚑ RapidOCR vuole un ndarray BGR (convenzione OpenCV): con un percorso converte da solo,
        # con un array no. Passare l'array evita di scrivere il ritaglio su disco.
        bgr = np.ascontiguousarray(np.array(im)[:, :, ::-1])
    r = eng(bgr)
    if r is None or r.boxes is None or r.txts is None:
        return []
    out = []
    for box, testo, conf in zip(r.boxes, r.txts, r.scores):
        xs = [float(p[0]) for p in box]
        ys = [float(p[1]) for p in box]
        x0, x1 = max(0.0, min(xs)), min(float(larghezza), max(xs))
        y0, y1 = max(0.0, min(ys)), min(float(altezza), max(ys))
        out.append({
            "t": testo,
            "x": round(x0 / larghezza, 4),
            "y": round(y0 / altezza, 4),
            "w": round((x1 - x0) / larghezza, 4),
            "h": round((y1 - y0) / altezza, 4),
            "c": round(float(conf), 3),
        })
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cartella")
    ap.add_argument("--licenze-libere", required=True, help="cartella test/fixtures/ocr del repo")
    ap.add_argument("--altre", required=True, help="cartella fuori dal repo per le fixture private")
    ap.add_argument("--ritagli", help="ritagli_mirino.json: modalita' mirino (un cartellino per fixture)")
    ap.add_argument("--log", help="log con le righe MICRO_OCR|<json> di un altro motore (es. Vision)")
    ap.add_argument("--motore", default="vision-sim", help="nome della cartella del motore del --log")
    a = ap.parse_args()
    if a.log:
        return da_log(a)
    if a.ritagli:
        return mirino(a)

    base = Path(a.cartella)
    righe_csv = list(csv.DictReader((base / "campioni.csv").read_text(encoding="utf-8-sig").splitlines(), delimiter=";"))
    oggi = dt.date.today().isoformat()
    eng = motore()
    libere = []
    tolte = 0
    for riga in righe_csv:
        file = riga["file"].strip()
        percorso = base / file
        nome = Path(file).stem
        libera = licenza_libera(riga["licenza"])
        dest = Path(a.licenze_libere if libera else a.altre) / "ppocrv5"
        dest.mkdir(parents=True, exist_ok=True)
        lette = righe_ocr(eng, percorso)
        lette.sort(key=lambda r: (r["y"], r["x"]))
        if riga["tipo"].strip() == "scontrino":
            taglio = next((i for i, r in enumerate(lette) if INIZIO_POS.search(r["t"])), len(lette))
            lette_tenute = lette[:taglio]
        else:
            lette_tenute = lette
        pulite = [r for r in lette_tenute if not RIPULISCI.search(r["t"])]
        tolte += len(lette) - len(pulite)
        fixture = {
            "campione": Path(file).name,
            "tipo": riga["tipo"].strip(),
            "licenza": riga["licenza"].strip(),
            "motore": MOTORE,
            "creato": oggi,
            "righe": pulite,
            "verita": verita(riga["verita"]),
        }
        (dest / f"{nome}.json").write_text(json.dumps(fixture, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")
        if libera:
            libere.append(riga)
        print(f"{'repo ' if libera else 'fuori'} {nome}: {len(pulite)} righe", flush=True)

    # Le attribuzioni, accanto alle fixture del repo.
    testo = [
        "# Fixture OCR del banco del parser: fonti e licenze",
        "",
        "Generato da `apps/spending_review/tool/esporta_fixture_ocr.py` (non modificare a mano).",
        "",
        "Ogni file in `ppocrv5/` contiene **solo il testo letto** dall'OCR (righe, riquadri, confidenza)",
        "e la verita' trascritta, non l'immagine. Le trascrizioni derivano dalle fotografie elencate qui",
        "sotto e si distribuiscono con la **stessa licenza** della fotografia (CC BY-SA: stessa licenza;",
        "CC BY: con attribuzione). Le immagini restano fuori dal repo",
        "(`microapps-campioni/f12/`, vedi `LEGGIMI.md` dei campioni).",
        "",
        "Le fixture in `ppocrv5-mirino/` (`<nome>_r<k>.json`) sono la lettura di un **ritaglio** della",
        "stessa fotografia (il cartellino come lo inquadra il mirino, coordinate in `ritagli_mirino.json`):",
        "stessa fonte, stesso autore, stessa licenza della riga qui sotto con lo stesso nome.",
        "",
        "| Fixture | Autore | Licenza | Fonte |",
        "|---|---|---|---|",
    ]
    for riga in libere:
        testo.append(f"| `{Path(riga['file']).stem}.json` | {riga['autore'].strip()} | {riga['licenza'].strip()} | {riga['fonte_url'].strip()} |")
    testo += ["", f"Modificate dall'originale: trascrizione OCR automatica ({MOTORE}) e rimozione delle righe con dati di pagamento.", ""]
    (Path(a.licenze_libere) / "LICENZE.md").write_text("\n".join(testo), encoding="utf-8", newline="\n")
    print(f"\n{len(libere)} fixture nel repo, {len(righe_csv) - len(libere)} fuori; {tolte} righe di pagamento tolte")


def mirino(a):
    """Modalita' mirino: un file per ogni ritaglio di `ritagli_mirino.json` (vedi in cima)."""
    base = Path(a.cartella)
    righe_csv = {Path(r["file"].strip()).name: r for r in csv.DictReader(
        (base / "campioni.csv").read_text(encoding="utf-8-sig").splitlines(), delimiter=";")}
    ritagli = json.loads(Path(a.ritagli).read_text(encoding="utf-8"))["ritagli"]
    oggi = dt.date.today().isoformat()
    eng = motore()
    for nome_file, lista in ritagli.items():
        riga = righe_csv[nome_file]
        libera = licenza_libera(riga["licenza"])
        dest = Path(a.licenze_libere if libera else a.altre) / "ppocrv5-mirino"
        dest.mkdir(parents=True, exist_ok=True)
        voci = verita(riga["verita"])
        for k, rit in enumerate(lista):
            lette = righe_ocr(eng, base / riga["file"].strip(), rit)
            lette.sort(key=lambda r: (r["y"], r["x"]))
            pulite = [r for r in lette if not RIPULISCI.search(r["t"])]
            fixture = {
                "campione": nome_file,
                "tipo": "cartellino",
                "licenza": riga["licenza"].strip(),
                "motore": MOTORE + " (ritaglio del mirino)",
                "creato": oggi,
                "ritaglio": rit,
                "righe": pulite,
                "verita": [voci[rit["verita"]]],
            }
            stem = Path(nome_file).stem
            (dest / f"{stem}_r{k}.json").write_text(
                json.dumps(fixture, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")
            print(f"{'repo ' if libera else 'fuori'} {stem}_r{k}: {len(pulite)} righe", flush=True)


def da_log(a):
    """Modalita' LOG (F12.7): le fixture di un motore che gira sul dispositivo (Vision su iOS).

    Il log e' quello di `packages/micro_ocr/example/integration_test/ocr_parita_test.dart`: una
    riga `MICRO_OCR|{"file", "ms", "righe": [{t, x, y, w, h, c}]}` per immagine, riquadri gia'
    normalizzati con l'origine in alto (`Riquadro.daVision` l'ha convertita in Dart). I file
    `<campione>.jpg` diventano `<motore>/<campione>.json`, i ritagli `<campione>_r<k>.jpg` (scritti
    con `ritaglio_px` da `ritagli_mirino.json`) diventano `<motore>-mirino/<campione>_r<k>.json`.
    Stessa pulizia dei dati della carta e stessa divisione repo/fuori delle fixture di RapidOCR.
    """
    base = Path(a.cartella)
    righe_csv = {Path(r["file"].strip()).stem: r for r in csv.DictReader(
        (base / "campioni.csv").read_text(encoding="utf-8-sig").splitlines(), delimiter=";")}
    ritagli = json.loads(Path(a.ritagli).read_text(encoding="utf-8"))["ritagli"] if a.ritagli else {}
    oggi = dt.date.today().isoformat()
    scritte = 0
    for linea in Path(a.log).read_text(encoding="utf-8", errors="replace").splitlines():
        i = linea.find("MICRO_OCR|")
        if i < 0:
            continue
        lettura = json.loads(linea[i + len("MICRO_OCR|"):])
        stem = Path(lettura["file"]).stem
        m = re.match(r"^(.*)_r(\d+)$", stem)
        campione, k = (m[1], int(m[2])) if m and m[1] in righe_csv else (stem, None)
        riga = righe_csv.get(campione)
        if riga is None:
            continue
        nome_file = Path(riga["file"].strip()).name
        libera = licenza_libera(riga["licenza"])
        cartella = a.motore if k is None else a.motore + "-mirino"
        dest = Path(a.licenze_libere if libera else a.altre) / cartella
        dest.mkdir(parents=True, exist_ok=True)
        lette = [{
            "t": r["t"], "x": round(r["x"], 4), "y": round(r["y"], 4),
            "w": round(r["w"], 4), "h": round(r["h"], 4), "c": round(r["c"], 3),
        } for r in lettura["righe"]]
        lette.sort(key=lambda r: (r["y"], r["x"]))
        if riga["tipo"].strip() == "scontrino":
            taglio = next((j for j, r in enumerate(lette) if INIZIO_POS.search(r["t"])), len(lette))
            lette = lette[:taglio]
        pulite = [r for r in lette if not RIPULISCI.search(r["t"])]
        voci = verita(riga["verita"])
        fixture = {
            "campione": nome_file,
            "tipo": riga["tipo"].strip(),
            "licenza": riga["licenza"].strip(),
            "motore": a.motore + ("" if k is None else " (ritaglio del mirino)"),
            "creato": oggi,
            "ms": lettura.get("ms"),
            **({} if k is None else {"ritaglio": ritagli[nome_file][k]}),
            "righe": pulite,
            "verita": voci if k is None else [voci[ritagli[nome_file][k]["verita"]]],
        }
        (dest / f"{stem}.json").write_text(
            json.dumps(fixture, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")
        scritte += 1
    print(f"{scritte} fixture del motore {a.motore} scritte")


if __name__ == "__main__":
    sys.exit(main())

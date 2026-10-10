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
    r"\*{3,}\d{3,4}|aut(orizzazione)?\.?\s*\d|terminale|term\.|id\s*trans|n\.?\s*operazione|stan\b|a\.?i\.?d\.?",
    re.IGNORECASE,
)
# ⚑ Oltre alle righe singole: lo scontrino del POS stampato in coda al documento commerciale
# (s13: «DETTAGLIO PAGAMENTI», «EDC-MAESTRO», PAN mascherato, codici EMV) si taglia INTERO, dalla
# prima riga che lo annuncia in giu'. Il parser butta comunque il piede, ma qui si parla di cosa
# finisce nel repo: dati di una carta non ci devono stare nemmeno «tanto non li legge nessuno».
INIZIO_POS = re.compile(
    r"dettaglio\s*pagament|edc-|cod\.?\s*aut|transazione\s*autorizzata|esercente|acquirer|\*\d{4}",
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


def righe_ocr(eng, percorso: Path):
    from PIL import Image, ImageOps

    with Image.open(percorso) as im:
        larghezza, altezza = ImageOps.exif_transpose(im).size
    r = eng(str(percorso))
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
    a = ap.parse_args()

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
        "| Fixture | Autore | Licenza | Fonte |",
        "|---|---|---|---|",
    ]
    for riga in libere:
        testo.append(f"| `{Path(riga['file']).stem}.json` | {riga['autore'].strip()} | {riga['licenza'].strip()} | {riga['fonte_url'].strip()} |")
    testo += ["", f"Modificate dall'originale: trascrizione OCR automatica ({MOTORE}) e rimozione delle righe con dati di pagamento.", ""]
    (Path(a.licenze_libere) / "LICENZE.md").write_text("\n".join(testo), encoding="utf-8", newline="\n")
    print(f"\n{len(libere)} fixture nel repo, {len(righe_csv) - len(libere)} fuori; {tolte} righe di pagamento tolte")


if __name__ == "__main__":
    sys.exit(main())

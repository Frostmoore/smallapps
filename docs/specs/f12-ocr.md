# F12 · Spending Review — OCR on-device per cartellini, scontrini, etichette bilancia

> Ricerca tecnica del 2026-10-10. Scopo: scegliere il motore OCR che legge con la fotocamera
> **cartellini del prezzo**, **scontrini** ed **etichette della bilancia** dei supermercati
> italiani, **interamente sul telefono**, senza nessuna libreria che invii qualcosa a Google o a
> terzi (regola «Dati solo sul telefono», `memory/decisioni.md`, voce del 2026-10-09).
> Niente immagini in questo file: solo testo, numeri e fonti.

## 0. In una riga

**iOS: Vision di Apple. Android: PaddleOCR PP-OCRv5 mobile (rilevatore + riconoscitore «latin»)
su ONNX Runtime 1.28.x, versione bloccata, perché da ONNX Runtime 1.29.0 il pacchetto Android
ufficiale contiene telemetria Microsoft accesa di default (verificato aprendo l'AAR).
Ripiego: gli stessi modelli su NCNN (Tencent, BSD-3, senza telemetria per costruzione).**
Il parser (prezzo, prezzo barrato, €/kg, 3x2, -30%, totale, righe) è **unico, in Dart**, e lavora
sulle righe di testo con i loro riquadri, qualunque sia il motore.

---

## 1. Il vincolo e cosa è escluso a priori

| Escluso | Perché |
|---|---|
| **ML Kit Text Recognition** (anche bundled) | Invia a Google metriche d'uso/diagnostica e un id per installazione; non si spegne in modo supportato. Già tolto da QR Me per lo stesso motivo (`memory/decisioni.md`, 2026-10-09). |
| **LiteRT / TFLite via Google Play services** (`play-services-tflite-*`) | Il runtime arriva da Play services: è codice Google che gira fuori dal nostro controllo. |
| **ONNX Runtime ufficiale ≥ 1.29.0** (Maven `com.microsoft.onnxruntime:onnxruntime-android`, CocoaPods `onnxruntime-objc`) | Contiene la telemetria **1DS** di Microsoft, **accesa di default** (vedi §3). |
| OCR cloud di qualunque tipo | Ovvio. |

Regola già fissata nel progetto e che vale anche qui: **niente trucchi non documentati** (togliere
servizi dal manifest unito, ecc.) per zittire una libreria che telefona. Se una libreria telefona,
si cambia libreria o si usa un'opzione **documentata** di build.

---

## 2. iOS: Vision di Apple

- API: `VNRecognizeTextRequest` (iOS 13+; da iOS 18 anche la nuova API Swift `RecognizeTextRequest`).
- **Italiano supportato** dalla revisione 2 (iOS 14+) sia in `.accurate` sia in `.fast`
  (lingue rev. 2 accurate: en, zh, pt, fr, **it**, de, es). In codice: `recognitionLanguages = ["it-IT"]`,
  e conviene interrogare `supportedRecognitionLanguages()` a runtime invece di fidarsi di una lista.
- **Locale**: il riconoscimento gira sul dispositivo con i modelli del sistema operativo; Vision
  non ha una modalità cloud né un'opzione di rete. Peso aggiunto all'app: **0 MB**.
- `usesLanguageCorrection = false` per i prezzi (la correzione linguistica «aggiusta» i numeri),
  `customWords` utile per parole fisse (TOTALE, SCONTO, €/KG, PREZZO AL KG).
- Restituisce testo **e riquadro** di ogni riga (`boundingBox`): il parser ne ha bisogno per capire
  qual è il numero grande (prezzo) e quale quello barrato/piccolo.
- QR Me usa già Vision su iOS tramite `mobile_scanner`: stessa famiglia, stessa garanzia.

Collegamento a Flutter: un piccolo plugin locale (MethodChannel o FFI Swift) nel monorepo, che
restituisce `List<RigaOcr{testo, riquadro, confidenza}>`. Non serve un pacchetto pub.dev.

---

## 3. Android: le opzioni realistiche (ottobre 2026)

### 3.1 Tabella

| Opzione | Licenza | Peso aggiunto (arm64, compresso) | Velocità (telefono medio) | Qualità su cartellini/scontrini | Italiano / € | Manutenzione | Rete / telemetria (verificato) |
|---|---|---|---|---|---|---|---|
| **A. PP-OCRv5 mobile su ONNX Runtime 1.28.x** (es. `flutter_onnxruntime` 1.9.0, che fissa `onnxruntime-android:1.28.0`) | Apache-2.0 (modelli PaddleOCR e RapidOCR), MIT (ORT e plugin) | ORT ≈ 10 MB + modelli ≈ 12,7 MB (det 4,8 + rec latin 7,9; i pesi float si comprimono poco) → **≈ 22 MB** | Stima 0,3–1 s per foto in CPU (da misurare, §6.3) | **Alta**: deep learning, regge sfondi colorati, font grandi, termica, leggera rotazione | rec «latin»: italiano incluso, **€ nel dizionario** (verificato) | ORT: rilasci mensili; PaddleOCR molto attivo; plugin aggiornato 4 giorni fa | **1.28.0: pulito** (manifest senza INTERNET, nessun endpoint). **1.29.0, 1.30.0, 1.31.0: telemetria** (vedi 3.2) |
| **A'. Come A ma ORT compilato da noi** (`--no_telemetry`, eventualmente *minimal build* con solo gli operatori dei due modelli) | come A | ORT minimal ≈ 2–4 MB (stima) + modelli | come A | come A | come A | dipende da noi (build da rifare a ogni aggiornamento) | **Pulito per costruzione** (opzione di build **documentata** da Microsoft) |
| **B. PP-OCRv5 mobile su NCNN** (Tencent; esempio ufficiale `nihui/ncnn-android-ppocrv5`) | BSD-3 (ncnn); modelli Apache-2.0. **Attenzione**: il repo d'esempio di nihui **non ha file di licenza** → si prende il codice da `Tencent/ncnn/examples/ppocrv5.cpp` (BSD-3) | `libncnn.so` vulkan ≈ 3,6 MB + modelli ≈ 10,6 MB (det 2,4 + rec 8,2) → **≈ 14 MB** | Comparabile o migliore di A; Vulkan opzionale sulla GPU | **Alta** (stessi modelli di A) | come A (stesso modello: verificare che sia il rec «latin», l'esempio usa quello cinese/inglese) | ncnn: rilascio 2026-05-26, molto attivo | **Pulito**: nessuna telemetria, nessun permesso |
| **C. Tesseract** (`Tesseract4Android` 4.9.0 = Tesseract 5.5.1; in Flutter `flutter_tesseract_ocr` / `tesseract_ocr` usano Tesseract4Android) | Apache-2.0 (Tesseract, Tesseract4Android); BSD-3 (plugin) | librerie ≈ 3,1 MB + `ita.traineddata` fast 2,7 MB (best 8,9 MB) → **≈ 6–12 MB** | 1–3 s per foto, molto variabile | **Bassa-media sulle foto**: nato per scansioni piatte; soffre sfondi colorati, numeri grandi da display, carta termica sbiadita, prospettiva. Serve pre-elaborazione pesante (binarizzazione, raddrizzamento, ritaglio) | `ita` ufficiale; € presente | Tesseract4Android: ultimo commit 2026-02, tag 4.9.0; il plugin Flutter usa ancora 4.8.0 | **Pulito**: POM dipende solo da `androidx.annotation`, manifest senza permessi |
| **D. Modelli OCR su LiteRT standalone** (`com.google.ai.edge.litert:litert`) | Apache-2.0 | `libLiteRt.so` ≈ 2,3 MB + modelli | buona | dipende dal modello: **non esiste un OCR latino pronto** in .tflite di qualità; bisognerebbe convertire PP-OCR (onnx2tf) | — | attivo | **1.4.x pulito** (nessuna dipendenza, nessun endpoint nel .so). **2.x trascina `com.google.android.play:ai-delivery` → `play-services-basement`, `play-services-tasks`, `asset-delivery`, `core-common`**: niente telemetria trovata, ma è codice Google Play dentro l'app → **da evitare** |
| E. Paddle Lite (`flutter_paddle_ocr`) | Apache-2.0 | ~ 10 MB | buona | modelli vecchi (PP-OCRv2/v3) | debole su latino | Paddle Lite fermo alla 2.10 nel plugin | pulito, ma obsoleto: **scartato** |
| F. Pacchetti pub.dev «tutto incluso» con PP-OCR (`pdf_ocr_ondevice`, `thrivexai_paddle_ocr_precompiled`) | vari | — | — | — | — | il secondo è **discontinued**; il primo **scarica il modello da internet al primo uso** e dipende da ORT ufficiale | **Scartati** (rete al primo avvio; ORT ufficiale) |

### 3.2 La scoperta che cambia le carte: ONNX Runtime ≥ 1.29 telefona a Microsoft

Verificato il 2026-10-10 scaricando gli AAR ufficiali da Maven Central e aprendoli:

| Versione `onnxruntime-android` | Permessi nel manifest | `TelemetryInitializer` (ContentProvider avviato da solo all'apertura dell'app) | Endpoint nel `libonnxruntime.so` |
|---|---|---|---|
| 1.28.0 (2026-07-25) | nessuno | no | nessuno |
| 1.29.0 | `INTERNET` (+ `ACCESS_NETWORK_STATE` dalla 1.31) | **sì** | `mobile.events.data.microsoft.com/OneCollector/1.0` |
| 1.30.0 | `INTERNET` | **sì** | idem |
| 1.31.0 (2026-10-08) | `INTERNET`, `ACCESS_NETWORK_STATE` | **sì** | idem |

Origine: PR microsoft/onnxruntime #27379 «Add POSIX telemetry» (2026-07-24) e #29872 (2026-08-09)
che rende la telemetria **opt-out** su Windows, Linux, macOS, **Android e iOS**. Il `docs/Privacy.md`
attuale: *«Telemetry is turned ON by default in the official builds»*; su Android e iOS
*«retain the SDK's platform device IDs»*. Si spegne: (1) a build time con `--no_telemetry`,
(2) a runtime con `ORT_DISABLE_TELEMETRY=1` **prima** dell'inizializzazione, (3) via API, ma
*«a minimal initialization event may still be emitted»*.

Conseguenze per noi:
- La variabile d'ambiente non basta: il ContentProvider parte prima del codice Dart, e il permesso
  `INTERNET` finirebbe comunque nel manifest unito (le nostre app non lo hanno).
- Quindi: **ORT ufficiale solo ≤ 1.28.x**, oppure **ORT compilato da noi con `--no_telemetry`**
  (opzione documentata, non un trucco).
- `flutter_onnxruntime` 1.9.0 fissa **esattamente** `onnxruntime-android:1.28.0` e
  `onnxruntime-objc 1.28.0`: va bene **oggi**, ma il prossimo aggiornamento del plugin porterà
  quasi certamente la 1.29+. → versione del plugin **bloccata** nel `pubspec.yaml` (niente `^`)
  **e** un controllo automatico (§5.3).

### 3.3 Note di qualità sui modelli

- `latin_PP-OCRv5_mobile_rec`: 84,7 % di accuratezza sul set latino di PaddleOCR (+46,8 % sulla
  generazione precedente); copre italiano, francese, tedesco, spagnolo, portoghese ecc.; il
  dizionario `ppocrv5_latin_dict.txt` (502 simboli) contiene `€`.
- **PP-OCRv6** (agosto 2026): tre taglie (tiny 1,5 M, small 7,7 M, medium 34,5 M parametri);
  la *small* è un modello unico per 50 lingue, 46 latine. In ONNX la small pesa det 9,9 MB +
  rec 21,2 MB ≈ 31 MB: **più del doppio** di v5 mobile. Da provare sul PC con i campioni veri
  (il banco lo supporta: `--motore rapid6`); si adotta solo se migliora in modo netto.
- Rotazione: PP-OCR gestisce bene inclinazioni piccole; per testo ruotato di 90/180° c'è il
  classificatore di orientamento (`PP-LCNet_x1_0_textline_ori`, 6,8 MB) — **non incluso** di
  base: si chiede all'utente di inquadrare dritto e si aggiunge solo se i campioni lo esigono.

---

## 4. Una soluzione unica per Android e iOS?

| | Vision su iOS + PP-OCR su Android (**consigliato**) | PP-OCR (ONNX) su entrambi |
|---|---|---|
| Peso su iOS | 0 MB | +≈ 22 MB (ORT iOS + modelli) |
| Privacy iOS | sistema operativo, nessuna terza parte | `onnxruntime-objc` ≥ 1.29 ha la stessa telemetria → bloccare 1.28 o compilare |
| Qualità iOS | Vision `.accurate` è eccellente su testo stampato | buona, ma non migliore di Vision |
| Coerenza dei risultati | due motori → piccole differenze di segmentazione delle righe | identica sui due sistemi |
| Lavoro | due ponti nativi piccoli, **un solo parser Dart** | un ponte, un parser |

Conclusione: **non conviene** la soluzione unica. La coerenza si ottiene comunque facendo
lavorare il parser su una struttura comune (`RigaOcr{testo, riquadro, confidenza}`) e collaudandolo
sugli stessi campioni con entrambi i motori. L'unico caso in cui ripensarci: se i campioni
mostrassero che Vision sbaglia in modo sistematico su un tipo di cartellino che PP-OCR legge.

---

## 5. Raccomandazione

### 5.1 Prima scelta (Android)

**PP-OCRv5 mobile — `PP-OCRv5_mobile_det` + `latin_PP-OCRv5_mobile_rec` — su ONNX Runtime 1.28.0**,
tramite `flutter_onnxruntime: 1.9.0` (versione esatta) e pre/post-elaborazione in Dart (o presa
da RapidOCR, Apache-2.0). Perché:
1. qualità di gran lunga superiore a Tesseract sulle **foto** (non scansioni) con sfondi colorati;
2. italiano ed € coperti dal modello latino;
3. ≈ 22 MB per ABI, accettabile con AAB/split per ABI;
4. tutto Apache/MIT, compatibile con app commerciale chiusa (va citata la licenza nei «crediti»);
5. 1.28.0 verificata pulita a livello di manifest e binario.

**Evoluzione prevista (A')**: quando servirà aggiornare ORT, compilarlo da noi con
`--no_telemetry` e *minimal build* ristretta agli operatori dei due modelli: si stacca dalla scelta
di default di Microsoft e il binario scende a pochi MB.

### 5.2 Ripiego

**Gli stessi modelli PP-OCRv5 su NCNN** (BSD-3, nessuna telemetria per costruzione, ≈ 14 MB,
Vulkan opzionale). Stessa precisione, perché i modelli sono gli stessi; costa un ponte C++ (FFI)
scritto da noi partendo da `Tencent/ncnn/examples/ppocrv5.cpp`. Si passa qui se ORT 1.28 diventa
un problema (requisiti Play, 16 KB page size, bug) e non si vuole mantenere una build ORT propria.

**Tesseract** resta l'ultima spiaggia: pulito e leggero, ma sulle foto dei cartellini rende
nettamente peggio e chiede molta pre-elaborazione. **LiteRT 2.x** no (trascina Play services).

### 5.3 Guardie da mettere nel codice quando si implementa

- `pubspec.yaml`: `flutter_onnxruntime: 1.9.0` **senza** `^`.
- Controllo in CI/script di build: il manifest **unito** dell'APK di Spending Review **non** deve
  contenere `android.permission.INTERNET` né `ai.onnxruntime.TelemetryInitializer`
  (`aapt2 dump xmltree --file AndroidManifest.xml app.apk` + grep). Se compare, la build fallisce.
- Grep sul `.so` incluso: nessuna stringa `events.data.microsoft.com`.
- I modelli si **impacchettano negli asset** (nessun download al primo avvio).

---

## 6. Prova di precisione

### 6.1 Stato dei campioni

Al 2026-10-10 ore 13:05 la cartella `E:/coding/XAMPP/htdocs/microapps-campioni/f12/` contiene solo
le sottocartelle vuote `bilancia/`, `cartellini/`, `scontrini/` e **nessun `campioni.csv`**: un
altro agente li sta raccogliendo. **Nessuna misura su campioni veri è stata fatta.**
Tesseract **non è installato** sul PC (nessun `tesseract.exe` nel PATH): non è stato installato.

### 6.2 Collaudo del banco su immagini sintetiche (NON è una misura di precisione)

Per verificare che il banco funzioni, 18 immagini **generate al PC** (12 cartellini con prezzo
grande rosso, prezzo barrato, prezzo al kg, sfondo bianco/giallo/rosa, rotazione ±6°; 6 scontrini
in font monospazio, sfocati per imitare la termica). RapidOCR 3.10.0, onnxruntime 1.31.0 Python
(con `ORT_DISABLE_TELEMETRY=1`), CPU del PC:

| Motore | prezzo | prezzo barrato | prezzo al kg | totale scontrino | Totale | Tempo medio (PC) |
|---|---|---|---|---|---|---|
| PP-OCRv5 mobile det + rec latin | 12/12 | 11/12 | 12/12 | 6/6 | **41/42 (98 %)** | 0,24 s |
| PP-OCRv6 small | 12/12 | 10/12 | 12/12 | 6/6 | **40/42 (95 %)** | 0,23 s |

Gli errori sono tutti sul **prezzo barrato** (la riga che attraversa le cifre). Su foto vere ci si
aspetta molto meno: questi numeri dicono solo che la catena funziona.

### 6.3 Piano di misura sui campioni veri

1. **Ambiente** (nessuna installazione di sistema):
   `python -m venv venv && venv\Scripts\python -m pip install rapidocr onnxruntime pillow`
   (per Tesseract serve in più il binario di sistema + `ita.traineddata` + `pip install pytesseract`:
   **chiedere prima** di installarlo).
2. **Formato atteso di `campioni.csv`** (il banco è tollerante): una colonna con il percorso
   dell'immagine (`file`/`immagine`/`path`…), una colonna `tipo` (altrimenti usa il nome della
   sottocartella), e le colonne di verità il cui nome contiene `prezzo`, `totale`, `importo`,
   `euro`, `kg` o `sconto`. Separatore `,` o `;`, UTF-8.
3. **Esecuzione**: `venv\Scripts\python -I bench_f12.py E:/coding/XAMPP/htdocs/microapps-campioni/f12 --motore rapid --out ris_v5.csv`,
   poi `--motore rapid6` (e `--motore tess` se Tesseract viene installato).
4. **Metrica 1 — richiamo OCR**: per ogni valore di verità, compare tra i numeri `\d+[.,]\d\d` letti?
   Per tipo (cartellino/scontrino/bilancia) e per campo. È il tetto massimo del parser.
5. **Metrica 2 — parser** (quando esisterà il parser Dart): il numero che il parser *sceglie* come
   prezzo/totale è quello giusto? Si misura sullo stesso CSV con il testo + riquadri salvati.
6. **Soglie per decidere**: prezzo del cartellino ≥ 95 %, totale dello scontrino ≥ 95 %,
   prezzo al kg ≥ 90 %, prezzo barrato ≥ 80 %. Sotto soglia: prima pre-elaborazione (ritaglio,
   contrasto), poi modello più grande (v6 small / v5 server), poi cambio motore.
7. **iOS**: stessi campioni in un'app di prova su iPad con Vision (`.accurate`, `it-IT`,
   correzione linguistica spenta), stessa metrica, per confrontare i due motori.
8. **Velocità vera**: misurare su un Android di fascia media (tempo det + rec per foto, a freddo
   e a caldo) prima di fissare la risoluzione d'ingresso del rilevatore.

### 6.4 Il banco di prova (`bench_f12.py`)

Copiare in un file e lanciarlo con `python -I`. Il codice è questo:

```python
"""Banco di prova OCR per F12 (Spending Review).

Uso:  python -I bench_f12.py <cartella_campioni> [--motore rapid|tess] [--out risultati.csv]

Legge <cartella_campioni>/campioni.csv, fa girare l'OCR su ogni immagine e
controlla se ogni valore "prezzo-like" della verita' (colonne il cui nome
contiene prezzo/totale/importo/euro/kg) compare fra i numeri estratti dal testo.
Misura il RICHIAMO DELL'OCR (il numero e' stato letto?), non il parser
semantico (quale numero e' il prezzo): quello si misura dopo, sul testo.
"""
import csv, os, re, sys, time, argparse
from pathlib import Path

os.environ.setdefault("ORT_DISABLE_TELEMETRY", "1")  # onnxruntime >= 1.29 ha 1DS acceso di default

PREZZO_RE = re.compile(r"(?<![\d])(\d{1,4})\s?[.,]\s?(\d{2})(?![\d])")
COL_IMG = ("file", "immagine", "image", "path", "percorso", "nome_file", "filename")
COL_NUM_KEYS = ("prezzo", "totale", "importo", "euro", "kg", "sconto")


def norm_prezzo(v: str):
    v = (v or "").strip().replace("€", "").replace(" ", "")
    if not v:
        return None
    m = PREZZO_RE.search(v)
    if m:
        return f"{int(m.group(1))}.{m.group(2)}"
    if re.fullmatch(r"\d+", v):
        return f"{int(v)}.00"
    return None


def prezzi_nel_testo(testo: str):
    return {f"{int(a)}.{b}" for a, b in PREZZO_RE.findall(testo)}


def motore_rapid(v6=False):
    from rapidocr import RapidOCR, LangRec, OCRVersion, ModelType, LangDet
    if v6:  # PP-OCRv6 small: modello unico multilingue (50 lingue)
        params = {"Det.ocr_version": OCRVersion.PPOCRV6, "Det.model_type": ModelType.SMALL,
                  "Rec.ocr_version": OCRVersion.PPOCRV6, "Rec.model_type": ModelType.SMALL}
    else:   # PP-OCRv5 mobile: det generico + rec "latin" (italiano, simbolo euro nel dizionario)
        params = {"Det.ocr_version": OCRVersion.PPOCRV5, "Det.model_type": ModelType.MOBILE, "Det.lang_type": LangDet.CH,
                  "Rec.ocr_version": OCRVersion.PPOCRV5, "Rec.model_type": ModelType.MOBILE, "Rec.lang_type": LangRec.LATIN}
    eng = RapidOCR(params=params)
    def run(p):
        r = eng(str(p))
        return "\n".join(r.txts or ()) if r is not None else ""
    return run


def motore_tess():
    import pytesseract
    from PIL import Image
    def run(p):
        return pytesseract.image_to_string(Image.open(p), lang="ita", config="--psm 11")
    return run


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cartella")
    ap.add_argument("--motore", default="rapid", choices=["rapid", "rapid6", "tess"])
    ap.add_argument("--out", default=None)
    a = ap.parse_args()
    base = Path(a.cartella)
    raw = (base / "campioni.csv").read_text(encoding="utf-8-sig")
    sep = ";" if raw.splitlines()[0].count(";") > raw.splitlines()[0].count(",") else ","
    righe = list(csv.DictReader(raw.splitlines(), delimiter=sep))
    if not righe:
        sys.exit("campioni.csv vuoto")
    cols = list(righe[0].keys())
    col_img = next((c for c in cols if c.strip().lower() in COL_IMG), cols[0])
    col_num = [c for c in cols if any(k in c.lower() for k in COL_NUM_KEYS)]
    col_tipo = next((c for c in cols if c.lower() in ("tipo", "categoria")), None)
    print(f"colonna immagine={col_img}  colonne verificate={col_num}  tipo={col_tipo}")
    run = motore_tess() if a.motore == "tess" else motore_rapid(v6=(a.motore == "rapid6"))

    stat = {}  # (tipo, colonna) -> [giusti, totali]
    tempi, dettagli = [], []
    for r in righe:
        rel = (r.get(col_img) or "").strip()
        p = base / rel
        if not p.exists():
            cand = list(base.rglob(Path(rel).name)) if rel else []
            if not cand:
                print("manca:", rel); continue
            p = cand[0]
        tipo = (r.get(col_tipo) or p.parent.name) if col_tipo else p.parent.name
        t0 = time.perf_counter(); testo = run(p); dt = time.perf_counter() - t0
        tempi.append(dt)
        trovati = prezzi_nel_testo(testo)
        for c in col_num:
            v = norm_prezzo(r.get(c))
            if v is None:
                continue
            ok = v in trovati
            s = stat.setdefault((tipo, c), [0, 0]); s[0] += ok; s[1] += 1
            dettagli.append({"file": rel, "tipo": tipo, "campo": c, "verita": v, "ok": int(ok),
                             "letti": " ".join(sorted(trovati)), "sec": f"{dt:.2f}"})
    print(f"\nmotore={a.motore}  immagini={len(tempi)}  tempo medio={sum(tempi)/max(len(tempi),1):.2f}s (PC)")
    print(f"{'tipo':<14}{'campo':<20}{'giusti':>8}{'totali':>8}{'%':>7}")
    G = T = 0
    for (tipo, c), (g, t) in sorted(stat.items()):
        G += g; T += t
        print(f"{tipo:<14}{c:<20}{g:>8}{t:>8}{100*g/t:>6.0f}%")
    if T:
        print(f"{'TOTALE':<34}{G:>8}{T:>8}{100*G/T:>6.0f}%")
    if a.out and dettagli:
        with open(a.out, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=list(dettagli[0].keys())); w.writeheader(); w.writerows(dettagli)


if __name__ == "__main__":
    main()
```

---

## 7. Fonti

- Regola del progetto: `memory/decisioni.md`, voci del 2026-10-09 (ML Kit tolto da QR Me; «Dati solo sul telefono»).
- ML Kit, invio di metriche: https://developers.google.com/ml-kit/terms
- Vision, lingue di `VNRecognizeTextRequest` (rev. 2 include l'italiano): https://developer.apple.com/forums/thread/121048 ; https://developer.apple.com/documentation/vision/recognizing-text-in-images ; https://developer.apple.com/tutorials/data/documentation/vision/vnrecognizetextrequest/recognitionlanguages.md
- ONNX Runtime, privacy e telemetria: https://github.com/microsoft/onnxruntime/blob/main/docs/Privacy.md ; PR https://github.com/microsoft/onnxruntime/pull/27379 , https://github.com/microsoft/onnxruntime/pull/29872 , https://github.com/microsoft/onnxruntime/pull/32384
- ONNX Runtime Android su Maven Central (AAR aperti e verificati): https://repo1.maven.org/maven2/com/microsoft/onnxruntime/onnxruntime-android/
- Impostazioni di build AAR: https://github.com/microsoft/onnxruntime/blob/v1.31.0/tools/ci_build/github/android/default_full_aar_build_settings.json
- `flutter_onnxruntime`: https://pub.dev/packages/flutter_onnxruntime ; https://github.com/masicai/flutter_onnxruntime (android/build.gradle fissa `onnxruntime-android:1.28.0`)
- `onnxruntime` (pub.dev, vecchio, fermo da 2 anni): https://pub.dev/packages/onnxruntime
- RapidOCR: https://github.com/RapidAI/RapidOCR
- PaddleOCR PP-OCRv5 multilingue: https://www.paddleocr.ai/latest/en/version3.x/algorithm/PP-OCRv5/PP-OCRv5_multi_languages.html
- PP-OCRv6: https://www.paddleocr.ai/latest/en/version3.x/algorithm/PP-OCRv6/PP-OCRv6.html
- Modelli ONNX e dizionario latino: https://huggingface.co/monkt/paddleocr-onnx ; https://github.com/PaddlePaddle/PaddleOCR/blob/main/ppocr/utils/dict/ppocrv5_latin_dict.txt
- NCNN: https://github.com/Tencent/ncnn (LICENSE.txt BSD-3; release 20260526) ; esempio https://github.com/Tencent/ncnn/blob/master/examples/ppocrv5.cpp ; app d'esempio https://github.com/nihui/ncnn-android-ppocrv5
- Tesseract4Android: https://github.com/adaptech-cz/Tesseract4Android (POM su https://jitpack.io/cz/adaptech/tesseract4android/tesseract4android/4.9.0/)
- `flutter_tesseract_ocr`: https://pub.dev/packages/flutter_tesseract_ocr ; https://github.com/arrrrny/tesseract_ocr
- Modelli Tesseract italiano: https://github.com/tesseract-ocr/tessdata_fast , https://github.com/tesseract-ocr/tessdata_best
- LiteRT: https://dl.google.com/android/maven2/com/google/ai/edge/litert/ (POM `litert-api` 2.3.0 → `ai-delivery`) ; https://developers.google.com/edge/litert/android/play_services ; `tflite_flutter` usa `litert:1.4.0`: https://github.com/tensorflow/flutter-tflite
- Pacchetti scartati: https://pub.dev/packages/pdf_ocr_ondevice , https://pub.dev/packages/thrivexai_paddle_ocr_precompiled , https://pub.dev/documentation/flutter_paddle_ocr/latest/

## 7. Prima misura sui campioni veri (2026-10-10)

60 campioni raccolti dal web (35 cartellini, 16 scontrini, 9 etichette della bilancia; cartella
`E:/coding/XAMPP/htdocs/microapps-campioni/f12/`, fuori dal repo), 80 righe di verita' (una per
cartellino quando la foto ne contiene piu' d'uno). Banco: `bench_f12.py` con `--csv` su
`verita_espansa.csv` (script `espandi_verita.py`), PC, RapidOCR 3.10.

**Richiamo stretto** (il valore compare nel testo come `x,yy`):

| Tipo | Campo | PP-OCRv5 mobile latin | PP-OCRv6 small |
|---|---|---|---|
| bilancia | al kg | 9/9 (100%) | 9/9 |
| bilancia | totale | 9/9 (100%) | 9/9 |
| scontrino | totale | 16/16 (100%) | 16/16 |
| cartellino | prezzo al kg/l | 22/27 (81%) | 22/27 |
| cartellino | prezzo | 30/45 (67%) | 32/45 |
| cartellino | prezzo barrato | 4/6 | 2/6 |

**Richiamo delle cifre** (PP-OCRv5; il valore c'e' anche senza separatore, es. «229» per 2,29, o
spezzato in due pezzi adiacenti, es. «1» + «06»): cartellino prezzo **35/45 (78%)**, prezzo barrato
**6/6**, al kg 22/27, bilancia e scontrino 100%.

**Lettura dei numeri:**
- ⚑ **Il lettore non e' il collo di bottiglia per bilancia e scontrino**: 100% sul totale.
- ⚑ Sui **prezzi grandi con i centesimi in apice** il lettore restituisce le cifre senza virgola o in
  due riquadri separati (`229`, `1 | 06`, `16..50`): l'interpretazione va fatta dal **parser con le
  posizioni dei riquadri** (cifre grandi + cifre piccole in alto a destra = euro + centesimi), non con
  una regex sul testo.
- ☠ **Non letti:** i cartellini **scritti a mano** (c04, c05, c25: zero cifre), gli **LCD tedeschi** e
  due foto di duty-free sfocate o con il cartellino minuscolo; molte foto del web sono **inquadrature
  larghe** con il cartellino piccolo. Nell'app l'utente inquadra **un** cartellino da vicino dentro un
  mirino (ritaglio), che e' il caso favorevole.
- PP-OCRv6 small non e' nettamente migliore: **si resta su PP-OCRv5 mobile latin** (piu' piccolo).
- Decisione di prodotto conseguente: il cartellino letto **si propone sempre** (prezzo evidenziato,
  modificabile con un tocco) e non si aggiunge mai da solo; lo scritto a mano e' dichiarato non
  supportato (si usa il tastierino).

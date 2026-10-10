# Modelli PP-OCRv5 di micro_ocr (Android)

Provenienza, impronte e licenza dei file di questa cartella. ⚑ Sono **gli stessi file** con cui
RapidOCR 3.10.0 ha misurato i 60 campioni di `docs/specs/f12-ocr.md` §7 (copiati il 2026-10-10 dal
venv del banco, `venv/Lib/site-packages/rapidocr/models/`), non scaricati di nuovo da un'altra
pagina: cosi' le misure valgono anche per l'app.

☠ `packages/micro_ocr/test/modelli_test.dart` ricalcola gli SHA-256 e li confronta con la tabella
qui sotto (formato: una riga per file, colonna SHA-256 fra backtick). Un modello cambiato per
sbaglio fa fallire i test, non le letture in silenzio. Se si cambia modello **di proposito**:
nuova voce in `memory/decisioni.md`, nuovi SHA-256 qui, nuovo test di parita'.

| File | Origine | Byte | SHA-256 |
|---|---|---|---|
| `det.onnx` | `PP-OCRv5_mobile_det` in ONNX (RapidOCR `ch_PP-OCRv5_det_mobile.onnx`), https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/v3.10.0/onnx/PP-OCRv5/det/ch_PP-OCRv5_det_mobile.onnx | 4819576 | `4d97c44a20d30a81aad087d6a396b08f786c4635742afc391f6621f5c6ae78ae` |
| `rec_latin.onnx` | `latin_PP-OCRv5_mobile_rec` in ONNX (RapidOCR `latin_PP-OCRv5_rec_mobile.onnx`), https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/v3.10.0/onnx/PP-OCRv5/rec/latin_PP-OCRv5_rec_mobile.onnx | 7904513 | `b20bd37c168a570f583afbc8cd7925603890efbcdc000a59e22c269d160b5f5a` |
| `latin_dict.txt` | metadato `character` di `rec_latin.onnx` (quello che RapidOCR usa davvero: `get_character_list()` = `splitlines()`), 502 righe UTF-8 con `\n` finale | 1634 | `3c0a8a79b612653c25f765271714f71281e4e955962c153e272b7b8c1d2b13ff` |

Gli SHA-256 dei due `.onnx` coincidono con quelli dichiarati da RapidOCR 3.10.0 nel suo
`default_models.yaml` (verificato il 2026-10-10).

**Forma dei modelli** (letta con onnxruntime):
- `det.onnx`: ingresso `x` `[N, 3, H, W]` float (H, W multipli di 32), uscita `[N, 1, H, W]`
  (mappa di probabilita' del testo).
- `rec_latin.onnx`: ingresso `x` `[N, 3, 48, W]` float, uscita `[N, T, 504]` (softmax per passo).
  504 = 502 simboli del dizionario + blank (indice 0) + spazio (ultimo indice). `€` c'e' (riga 330).

**Licenza**: Apache-2.0 (modelli di PaddleOCR, Baidu; conversione ONNX di RapidOCR). Testo e
attribuzione in `LICENSE-PaddleOCR.txt`; l'app che usa `micro_ocr` deve citarli nelle sue licenze
(Impostazioni › Informazioni, F12.1.12).

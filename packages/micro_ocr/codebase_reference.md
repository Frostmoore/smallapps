# codebase_reference.md — `micro_ocr`

Atlante del plugin Flutter **`packages/micro_ocr`** (F12.2b): l'OCR **solo sul telefono** delle
MicroApps. iOS legge con **Vision** (di sistema, 0 MB); Android con **PaddleOCR PP-OCRv5 mobile
latin** su **ONNX Runtime 1.28.0 esatta** (dalla 1.29 c'e' la telemetria Microsoft). Una sola API
Dart (`OcrEngine`) per i due motori e un `FakeOcrEngine` per i test delle app.

Specsheet: `develop_microapps.md` F12.1.2, F12.1.4, F12.1.9, F12.1.16, F12.1.17. Ricerca:
`docs/specs/f12-ocr.md`. Decisioni: `memory/decisioni.md`, voci del 2026-10-10 (OCR e scelte tecniche).

Stato al 2026-10-10: **F12.2b fatta** (lato Dart, Android, iOS, guardie, parita' con RapidOCR
99,6%, 16 KB verificato). **La usa Spending Review** (`apps/spending_review`, da F12.2c; il suo
atlante e' `apps/spending_review/codebase_reference.md`): `CanaleOcrEngine` dietro
`ocrEngineProvider`, `FakeOcrEngine` nei test di widget, `RigaOcr`/`Riquadro` in tutti i parser del
dominio, guardia `privacy_ocr.gradle` applicata dal suo `build.gradle.kts`.
Aggiornato al 2026-10-10 (F12.8): ultime modifiche al codice in F12.7 (`example/lib/main.dart` con
`print` al posto di `debugPrint`, regola «1DS» di `tool/verifica_privacy_android.ps1`); il lato Dart,
Kotlin e Swift non e' cambiato da F12.2b.

---

## 1. Dove sta cosa

| Cerchi | File |
|---|---|
| I tipi che il **dominio** dell'app importa (Dart puro) | `lib/riga_ocr.dart` → `lib/src/riga_ocr.dart` (`Riquadro`, `RigaOcr`, `OcrModo`) |
| Tutto il resto dell'API (barrel, porta `flutter/services`) | `lib/micro_ocr.dart` |
| L'interfaccia del motore, l'eccezione | `lib/src/ocr_engine.dart` (`OcrEngine`, `OcrNonDisponibile`) |
| Il motore vero dietro il canale | `lib/src/canale_ocr_engine.dart` (`CanaleOcrEngine`) |
| Il finto per i test delle app | `lib/src/fake_ocr_engine.dart` (`FakeOcrEngine`) |
| Il canale Android, il thread di lavoro | `android/src/main/kotlin/com/smp/micro_ocr/MicroOcrPlugin.kt` |
| La catena PP-OCR (det → ritagli → rec) | `android/.../MotorePpOcr.kt` |
| Caricamento modelli dagli asset | `android/.../PpOcrEngine.kt` |
| Decodifica foto + rotazione EXIF | `android/.../ImmagineIngresso.kt` |
| Ridimensionamento, ritagli, rotazioni (puro) | `android/.../Immagine.kt` |
| Tensori di det e rec | `android/.../Preprocess.kt` |
| Mappa del rilevatore → quadrilateri | `android/.../DbPostprocess.kt` |
| Rettangolo minimo, inviluppo, omografia | `android/.../Geometria.kt` |
| Decodifica CTC | `android/.../CtcDecoder.kt` |
| Scontrini lunghi a strisce | `android/.../Strisce.kt` |
| I modelli, il dizionario, SHA-256, licenza | `android/src/main/assets/ppocrv5/` (`MODELLI.md`) |
| ORT `strictly("1.28.0")` | `android/build.gradle.kts` |
| Keep R8 di ORT | `android/consumer-rules.pro` |
| **Guardia Gradle per le app** (`verificaPrivacyOcr`) | `android/privacy_ocr.gradle` |
| Guardia sul binario (stringhe di telemetria nel `.so`) | `tool/verifica_privacy_android.ps1` |
| Il canale iOS | `ios/micro_ocr/Sources/micro_ocr/MicroOcrPlugin.swift` |
| La lettura con Vision | `ios/micro_ocr/Sources/micro_ocr/VisionOcr.swift` |
| App di prova, test sul dispositivo | `example/lib/main.dart`, `example/integration_test/` |
| Banco di parita' con RapidOCR sulla JVM | `android/src/test/kotlin/com/smp/micro_ocr/ParitaJvmTest.kt` |

## 2. Albero dei file (solo codice nostro)

```
packages/micro_ocr/
├─ pubspec.yaml                 plugin: android (com.smp.micro_ocr, MicroOcrPlugin), ios (MicroOcrPlugin); deps: flutter, meta; dev: crypto, flutter_lints, flutter_test
├─ analysis_options.yaml        include le lint del monorepo; esclude build, android, ios
├─ codebase_reference.md        questo file
├─ lib/
│  ├─ micro_ocr.dart            barrel: esporta src/{canale_ocr_engine,fake_ocr_engine,ocr_engine,riga_ocr}.dart
│  ├─ riga_ocr.dart             libreria PURA: esporta solo src/riga_ocr.dart (la importa il dominio)
│  └─ src/
│     ├─ riga_ocr.dart          Riquadro, RigaOcr, OcrModo (dipende solo da package:meta)
│     ├─ ocr_engine.dart        OcrEngine, OcrNonDisponibile
│     ├─ canale_ocr_engine.dart CanaleOcrEngine (MethodChannel 'micro_ocr')
│     └─ fake_ocr_engine.dart   FakeOcrEngine
├─ test/
│  ├─ riga_ocr_test.dart, canale_ocr_engine_test.dart, fake_ocr_engine_test.dart, modelli_test.dart
├─ tool/verifica_privacy_android.ps1
├─ android/
│  ├─ build.gradle.kts          ORT strictly 1.28.0, exifinterface 1.4.1, test: kotlin-test + ORT desktop 1.28.0
│  ├─ privacy_ocr.gradle        task verificaPrivacyOcr, applicato DALLE APP (Groovy, vedi §8)
│  ├─ consumer-rules.pro        -keep class ai.onnxruntime.** { *; }
│  ├─ settings.gradle.kts       generato
│  └─ src/
│     ├─ main/AndroidManifest.xml   VUOTO di permessi
│     ├─ main/assets/ppocrv5/{det.onnx, rec_latin.onnx, latin_dict.txt, MODELLI.md, LICENSE-PaddleOCR.txt}
│     ├─ main/kotlin/com/smp/micro_ocr/{MicroOcrPlugin,PpOcrEngine,MotorePpOcr,ImmagineIngresso,Immagine,Preprocess,DbPostprocess,Geometria,CtcDecoder,Strisce}.kt
│     └─ test/kotlin/com/smp/micro_ocr/{CtcDecoderTest,DbPostprocessTest,PreprocessTest,StrisceTest,ImmagineTest,GeometriaTest,ParitaJvmTest}.kt
├─ ios/
│  ├─ micro_ocr.podspec         frameworks Vision, ImageIO; nessuna dipendenza esterna
│  └─ micro_ocr/{Package.swift, Sources/micro_ocr/{MicroOcrPlugin.swift, VisionOcr.swift, PrivacyInfo.xcprivacy}}
└─ example/                     app di prova (com.smp.micro_ocr_example), MAI pubblicata
   ├─ lib/main.dart             legge tutte le immagini di F12_DIR, mostra testo e tempi e stampa
   │                            una riga «MICRO_OCR|<json>» per immagine con print() (☠ non debugPrint, §9)
   ├─ integration_test/ocr_motore_test.dart   PNG disegnato dal test → «2,49» (Android e iOS)
   ├─ integration_test/ocr_parita_test.dart   legge F12_DIR e stampa MICRO_OCR|<json> per il banco
   └─ android/app/build.gradle.kts            noCompress onnx + apply(from = privacy_ocr.gradle): come un'app vera
```

## 3. Dipendenze e versioni

| Dove | Cosa | Versione | Perche' |
|---|---|---|---|
| pubspec | `flutter`, `meta` | SDK, `^1.16.0` | nient'altro: plugin interno, niente `plugin_platform_interface` |
| pubspec dev | `crypto` | `^3.0.6` | SHA-256 dei modelli in `modelli_test.dart` |
| Android | `com.microsoft.onnxruntime:onnxruntime-android` | **`strictly("1.28.0")`** | ☠ 1.29+ = telemetria. `strictly` fa FALLIRE la risoluzione se qualcuno chiede altro |
| Android | `androidx.exifinterface:exifinterface` | 1.4.1 | rotazione EXIF delle foto |
| Android test | `com.microsoft.onnxruntime:onnxruntime` (desktop) | `strictly("1.28.0")` | solo per `ParitaJvmTest` sul PC; l'AAR Android e' escluso dal classpath dei test (classi doppie) |
| Android test | `org.jetbrains.kotlin:kotlin-test` | dal plugin Kotlin | JUnit 5 (`useJUnitPlatform`), non JUnit 4 come diceva la specsheet: il template di Flutter 3.47 usa questo |
| iOS | Vision, ImageIO | sistema | 0 MB nell'app |

⚑ **Niente `flutter_onnxruntime`** (decisione 2026-10-10): porterebbe `onnxruntime-objc` (~10 MB) anche
su iPhone e la versione la deciderebbe un pacchetto di terzi.

**Peso misurato** (APK di release arm64 dell'esempio, 2026-10-10): `libonnxruntime.so` 28,6 MB +
`libonnxruntime4j_jni.so` 0,08 MB + modelli 12,7 MB = **41,4 MB su disco** (le `.so` e i `.onnx` sono
salvati non compressi), **≈ 22,4 MB compressi** (stima del download da Play, deflate 9). In linea con
il «≈ +23 MB» di F12.1.18. iOS: 0 MB.

## 4. API Dart

### `lib/src/riga_ocr.dart` — Dart puro

#### `final class Riquadro` (`@immutable`)
Rettangolo in coordinate **normalizzate 0..1** sull'immagine passata al motore, origine in **alto a
sinistra**, y verso il basso.

| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `const Riquadro({required this.sinistra, required this.alto, required this.larghezza, required this.altezza})` | i quattro campi `double` |
| `Riquadro.daVision` | `factory Riquadro.daVision(double x, double y, double w, double h)` | da `boundingBox` di Vision (origine in BASSO): `alto = 1 − (y + h)` |
| `Riquadro.fromJson` | `factory Riquadro.fromJson(Map<String, Object?> json)` | da `{"x","y","w","h"}`; accetta int, double e stringhe numeriche; mancanti = 0 |
| campi | `final double sinistra, alto, larghezza, altezza` | |
| `destra`, `basso`, `centroX`, `centroY` | `double get …` | derivati |
| `sovrapposizioneVerticale` | `double sovrapposizioneVerticale(Riquadro altro)` | parte verticale in comune / altezza del **piu' basso** dei due, 0..1. ⚑ Sul minore e non sull'unione: i centesimi in apice dentro la fascia degli euro valgono 1 |
| `toJson` | `Map<String, double> toJson()` | `{"x","y","w","h"}` |
| `==`, `hashCode`, `toString` | | per valore |

#### `final class RigaOcr` (`@immutable`)
| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `const RigaOcr({required this.testo, required this.riquadro, required this.confidenza})` | campi `final String testo`, `final Riquadro riquadro`, `final double confidenza` (0..1) |
| `RigaOcr.fromJson` | `factory RigaOcr.fromJson(Map<String, Object?> json)` | formato **piatto** delle fixture `{"t","x","y","w","h","c"}`; `c` mancante = 1, `t` mancante = `''` |
| `toJson` | `Map<String, Object?> toJson()` | `{"t", "x", "y", "w", "h", "c"}` |
| `==`, `hashCode`, `toString` | | per valore |

#### `enum OcrModo { cartellino, scontrino }`
Il `name` viaggia sul canale (`'cartellino'`, `'scontrino'`). Android: lo scontrino molto lungo e
grande va a strisce (§6.3); iOS: `minimumTextHeight` 0,008 per lo scontrino.

### `lib/src/ocr_engine.dart`

#### `abstract interface class OcrEngine`
| Metodo | Firma | Contratto |
|---|---|---|
| `nome` | `Future<String> nome()` | `'vision'` (iOS), `'ppocrv5-ort-1.28.0'` (Android), `'fake'`. Finisce nelle fixture |
| `prepara` | `Future<void> prepara()` | carica i modelli (Android ~0,2 s su emulatore); idempotente; da chiamare dopo il primo frame |
| `leggi` | `Future<List<RigaOcr>> leggi(String percorsoImmagine, {required OcrModo modo})` | legge un JPEG/PNG su disco; l'ordine delle righe **non e' garantito** (di fatto Android le da' in ordine di lettura) |
| `rilascia` | `Future<void> rilascia()` | libera le sessioni (Android); il prossimo `leggi` le ricarica |

#### `class OcrNonDisponibile implements Exception`
`const OcrNonDisponibile(this.causa)`; `final Object causa`; `toString()`. L'**unica** eccezione
che l'app deve gestire: plugin assente, modelli non caricabili, immagine illeggibile, errore nativo.

### `lib/src/canale_ocr_engine.dart`

#### `class CanaleOcrEngine implements OcrEngine`
| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `CanaleOcrEngine({this.canale = const MethodChannel('micro_ocr')})` | campo pubblico `final MethodChannel canale` (iniettabile nei test) |
| `nome` | `Future<String> nome()` | `invokeMethod('nome')`; null → `'sconosciuto'` |
| `prepara`, `rilascia` | `Future<void> …()` | `invokeMethod` |
| `leggi` | come l'interfaccia | `invokeListMethod<Map>('leggi', {'percorso': p, 'modo': modo.name})` → `rigaDaMappa`; null → `[]` |
| `rigaDaMappa` | `@visibleForTesting static RigaOcr rigaDaMappa(Map<Object?, Object?> m)` | mappa del canale → `RigaOcr`; con `'origine': 'basso'` (iOS) converte con `Riquadro.daVision` |

`PlatformException` (qualunque codice; i nativi usano `non_disponibile`) e `MissingPluginException` →
`OcrNonDisponibile(e)`, in **tutti** i metodi.

### `lib/src/fake_ocr_engine.dart`

#### `class FakeOcrEngine implements OcrEngine`
| Membro | Firma | Effetto |
|---|---|---|
| costruttore | `FakeOcrEngine({List<RigaOcr> righe = const [], this.ritardo = Duration.zero, this.errore})` (campi `final Duration ritardo`, `final Object? errore`) | copia `righe` in una lista modificabile |
| `righe` | `List<RigaOcr> righe` | modificabile fra un `leggi` e l'altro |
| `ritardo`, `errore` | `final Duration ritardo; final Object? errore` | `leggi` aspetta `ritardo`, poi lancia `errore` se non nullo |
| `letti`, `modi` | `final List<String> letti; final List<OcrModo> modi` | percorsi e modi richiesti, per le asserzioni (registrati anche se poi lancia) |
| `preparazioni`, `rilasci` | `int` | contatori di `prepara` / `rilascia` |
| `nome` | | `'fake'` |
| `leggi` | | restituisce una copia **non modificabile** di `righe` |

## 5. Canale `micro_ocr` (contratto fra Dart e nativo)

| Metodo | Argomenti | Risposta | Errori |
|---|---|---|---|
| `nome` | — | `String` | — |
| `prepara` | — | `null` | `non_disponibile` (modelli assenti, classi sbagliate, ORT ≠ 1.28.0) |
| `leggi` | `{percorso: String, modo: 'cartellino'\|'scontrino'}` | `List<Map>`: Android `{t, x, y, w, h, c}` origine in alto; iOS `{t, c, x, y, w, h, origine: 'basso'}` | `non_disponibile` (percorso mancante, immagine illeggibile, qualunque `Throwable`/`Error` nativo) |
| `rilascia` | — | `null` | — |

## 6. Android (Kotlin, `com.smp.micro_ocr`)

### 6.1 `MicroOcrPlugin : FlutterPlugin, MethodChannel.MethodCallHandler`
`onAttachedToEngine(binding)`: canale, `PpOcrEngine(applicationContext.assets)`, un
`Executors.newSingleThreadExecutor` (thread «micro_ocr»). `onDetachedFromEngine(binding)`: chiude il
motore **sul thread di lavoro** e spegne l'esecutore. `onMethodCall(call, result)`: tabella §5; ogni
lavoro va in fila (`inFila`), il risultato torna con `Handler(Looper.getMainLooper())`. Cattura
`Throwable` (⚑ anche `UnsatisfiedLinkError`/`OutOfMemoryError`: muore l'OCR, non l'app).

### 6.2 `PpOcrEngine(assets: AssetManager) : AutoCloseable`
| Metodo | Firma | Effetto |
|---|---|---|
| `prepara` | `fun prepara()` | idempotente; legge `ppocrv5/det.onnx`, `rec_latin.onnx`, `latin_dict.txt` dagli asset e chiama `MotorePpOcr.crea` |
| `leggi` | `fun leggi(percorso: String, modo: String): List<RigaRiconosciuta>` | `prepara()` + `ImmagineIngresso.carica(percorso)` + `MotorePpOcr.leggi`. ⚑ Prende il **percorso** (non un `Bitmap` come nella specsheet): la decodifica resta qui, il motore puro non vede mai classi Android |
| `close` | `override fun close()` | chiude le sessioni; il prossimo `leggi` le ricrea |

### 6.3 `MotorePpOcr(env: OrtEnvironment, det: OrtSession, rec: OrtSession, dizionario: List<String>) : AutoCloseable`
Puro JVM (solo `ai.onnxruntime.*`): gira uguale sul telefono e nel banco sul PC.

| Membro | Firma | Effetto |
|---|---|---|
| `init` | | ☠ verifica che l'ultima dimensione dell'uscita del riconoscitore = `dizionario.size + 2` (504), altrimenti `IllegalStateException` |
| `leggi` | `fun leggi(img: ImmagineRgb, modo: String): List<RigaRiconosciuta>` | catena completa, sotto |
| `rileva` | `fun rileva(img: ImmagineRgb): List<Quadrilatero>` | `dimensioniDet` → `ridimensiona` → `tensoreDet` → sessione det → `DbPostprocess.riquadri` riportati in pixel di `img` |
| `riconosci` | `fun riconosci(img: ImmagineRgb, quadri: List<Quadrilatero>): List<Pair<String, Float>>` | ritagli raddrizzati; verticali (h ≥ 1,5·w) ruotati di 90° antiorari e **riletti anche capovolti** (vince la confidenza piu' alta); lotti di 6 in ordine di rapporto |
| `close` | `override fun close()` | chiude le due sessioni |
| `companion NOME` | `const val NOME = "ppocrv5-ort-1.28.0"` | |
| `VERSIONE_ORT` | `"1.28.0"` | verificata a runtime in `crea` (`env.version`) |
| `LATO_MAX` | `2000` | `Global.max_side_len` di RapidOCR |
| `LATO_MAX_SCONTRINO` | `4000` | scontrini lunghi a strisce |
| `RAPPORTO_STRISCE` | `2.5` | |
| `SOGLIA_TESTO` | `0.5f` | `Global.text_score` |
| `LOTTO_REC` | `6` | `rec_batch_num` |
| `opzioni` | `fun opzioni(): OrtSession.SessionOptions` | `setIntraOpNumThreads(4)`, `ALL_OPT`, nessun execution provider extra |
| `dizionario` | `fun dizionario(testo: String): List<String>` | split su `\n`, toglie solo l'ultima riga vuota, **niente trim** (lo spazio e' un simbolo) |
| `crea` | `fun crea(env: OrtEnvironment, det: ByteArray, rec: ByteArray, dizionario: String): MotorePpOcr` | controlla la versione di ORT, crea le sessioni (chiude quelle aperte se qualcosa fallisce) |

**Catena di `leggi`** (parametri letti nel `config.yaml` di RapidOCR 3.10 il 2026-10-10 e confermati
dal banco di parita'):
1. Immagine di lavoro = `Immagine.entroLimiti(img, 30, 2000)`: lato lungo ≤ 2000, lati multipli di 32
   (arrotondamento al pari, come `round()` di Python). Eccezione: `scontrino` con altezza > 2,5 ×
   larghezza **e** lato lungo > 2000 → limite 4000 e rilevatore a strisce (`Strisce.tagli`, poi
   `Strisce.unisci`). ⚑ Sotto i 2000 px le strisce non servono e il risultato resta identico al banco.
2. Rilevatore: lato **corto** portato almeno a **736** (`limit_type: min`), multipli di 32;
   normalizzazione `(px/255 − 0,5)/0,5`; canali **BGR**.
3. `DbPostprocess.riquadri`: soglia 0,3, dilatazione 2x2, componenti a 8 vicini, rettangolo minimo
   ruotato, punteggio ≥ **0,5**, unclip 1,6, lati minimi 3 / 5, riportati e limitati all'immagine.
4. `DbPostprocess.ordina` (ordine di lettura, soglia 10 px).
5. Ritagli con `Immagine.ritagliaQuadrilatero` (prospettica + bicubica), verticali ruotati.
6. Riconoscitore a lotti: altezza 48, larghezza del lotto `int(48 · max(320/48, rapporti))`,
   riempimento a 0; `CtcDecoder`.
7. Via le righe vuote e quelle con confidenza < 0,5; ogni quadrilatero diventa il **rettangolo che lo
   contiene**, normalizzato sull'immagine di lavoro (come le fixture di F12.1.17).

#### `data class RigaRiconosciuta(testo: String, sinistra: Float, alto: Float, larghezza: Float, altezza: Float, confidenza: Float)`
Coordinate normalizzate 0..1, origine in alto a sinistra.

### 6.4 `ImmagineIngresso` (object)
`fun carica(percorso: String, latoMax: Int = 4000): ImmagineRgb` — `BitmapFactory` con `inSampleSize`
(potenze di 2) finche' il lato lungo ≤ `latoMax`, rotazione/specchio secondo
`ExifInterface.TAG_ORIENTATION` (tutti gli 8 casi), `getPixels` → ARGB; ricicla i `Bitmap`. Lancia
`IOException` se il file non si decodifica. ⚑ 4000 e non 2400 (specsheet): lo scontrino lungo lavora
fino a 4000; il cartellino viene poi ridotto a 2000 col bilineare «alla OpenCV».

### 6.5 `ImmagineRgb(larghezza: Int, altezza: Int, pixel: IntArray)` e `Immagine` (object)
`ImmagineRgb`: pixel ARGB riga per riga; `init` rifiuta dimensioni ≤ 0 o array di misura sbagliata.

| Metodo di `Immagine` | Firma | Effetto |
|---|---|---|
| `ridimensiona` | `fun ridimensiona(src: ImmagineRgb, larghezza: Int, altezza: Int): ImmagineRgb` | bilineare con centri a meta' pixel (= `cv2.INTER_LINEAR`), bordi replicati; stesse misure → copia |
| `ritaglia` | `fun ritaglia(src: ImmagineRgb, r: Rettangolo): ImmagineRgb` | sotto-immagine (destra/basso esclusi), limitata ai bordi |
| `ritagliaQuadrilatero` | `fun ritagliaQuadrilatero(src: ImmagineRgb, q: Quadrilatero): ImmagineRgb` | `get_rotate_crop_image`: W/H = lati piu' lunghi, omografia vertici → (0,0)(W,0)(W,H)(0,H), bicubica a = −0,75, bordi replicati |
| `ruota90Antiorario` | `fun ruota90Antiorario(src: ImmagineRgb): ImmagineRgb` | come `np.rot90` |
| `ruota180` | `fun ruota180(src: ImmagineRgb): ImmagineRgb` | per la rilettura delle righe verticali |
| `entroLimiti` | `fun entroLimiti(src: ImmagineRgb, latoMin: Int = 30, latoMax: Int = 2000): ImmagineRgb` | `resize_image_within_bounds`; se non serve restituisce **la stessa istanza** |
| `multiplo32` | `fun multiplo32(n: Int): Int` | `round(n/32)·32` al pari, mai sotto 32 |

### 6.6 `Preprocess` (object)
| Membro | Firma | Effetto |
|---|---|---|
| costanti | `LATO_MIN_DET = 736`, `ALTEZZA_REC = 48`, `LARGHEZZA_BASE_REC = 320` | |
| `dimensioniDet` | `fun dimensioniDet(w: Int, h: Int, latoMin: Int = LATO_MIN_DET): Pair<Int, Int>` | ⚑ lato **corto** ≥ 736 (RapidOCR `limit_type: min`), non «lato lungo 960» come ipotizzava la specsheet |
| `tensoreDet` | `fun tensoreDet(img: ImmagineRgb): FloatArray` | CHW **BGR**, `(px/255 − 0,5)/0,5` (non ImageNet: e' il `config.yaml` del banco) |
| `larghezzaLotto` | `fun larghezzaLotto(ritagli: List<ImmagineRgb>, larghezzaMax: Int = 3200): Int` | `int(48 · max(320/48, rapporti))`, al massimo `larghezzaMax` |
| `tensoreRec` | `fun tensoreRec(crop: ImmagineRgb, larghezza: Int): Pair<FloatArray, Int>` | `[3, 48, larghezza]` + larghezza utile `min(larghezza, ceil(48·w/h))`; resto a 0 |

### 6.7 `DbPostprocess` (object) e `Rettangolo`
`data class Rettangolo(sinistra: Int, alto: Int, destra: Int, basso: Int)` (destra/basso esclusi),
con `larghezza`, `altezza`, `area: Long`.

| Metodo | Firma | Effetto |
|---|---|---|
| `riquadri` | `fun riquadri(mappa: FloatArray, w: Int, h: Int, soglia: Float = 0.3f, sogliaRiquadro: Float = 0.5f, unclip: Float = 1.6f, latoMin: Int = 3, larghezzaDest: Int = w, altezzaDest: Int = h, dilata: Boolean = true, maxCandidati: Int = 1000): List<Quadrilatero>` | la post-elaborazione DB completa (sopra). BFS iterativa con coda `IntArray`; per riga tiene solo il primo e l'ultimo pixel (bastano per l'inviluppo) |
| `quadrilatero` | `internal fun quadrilatero(punti: List<Punto>, mappa: FloatArray, w: Int, h: Int, sogliaRiquadro: Float, unclip: Float, latoMin: Int, larghezzaDest: Int, altezzaDest: Int): Quadrilatero?` | da una componente al quadrilatero, o null |
| `ordinaOrario` | `internal fun ordinaOrario(p: List<Punto>): Quadrilatero` | `order_points_clockwise` |
| `maschera` | `internal fun maschera(mappa: FloatArray, w: Int, h: Int, soglia: Float, dilata: Boolean): BooleanArray` | `> soglia` + dilatazione 2x2 di `cv2.dilate` (pixel, sinistra, sopra, alto-sinistra) |
| `punteggio` | `internal fun punteggio(mappa: FloatArray, w: Int, h: Int, poli: List<Punto>): Float` | media della mappa nel poligono (vertici troncati, bordo compreso) |
| `ordina` | `fun ordina(riquadri: List<Quadrilatero>, sogliaY: Float = 10f): List<Quadrilatero>` | `sorted_boxes`: per y del vertice alto-sinistra, stessa riga se Δy < 10, poi per x |

### 6.8 `Geometria` (object), `Punto`, `Quadrilatero`, `RettangoloMinimo`
- `data class Punto(x: Float, y: Float)`.
- `data class Quadrilatero(as_: Punto, ad: Punto, bd: Punto, bs: Punto)` — alto-sinistra, alto-destra,
  basso-destra, basso-sinistra (`as_` col trattino basso: `as` e' parola riservata). `punti: List<Punto>`;
  `fun contenitore(): Rettangolo` (floor/ceil); `fun sposta(dx: Float, dy: Float): Quadrilatero`;
  `companion fun da(r: Rettangolo): Quadrilatero`.
- `data class RettangoloMinimo(vertici: List<Punto>, lato1: Float, lato2: Float)`, `latoCorto: Float`.

| Metodo di `Geometria` | Firma | Effetto |
|---|---|---|
| `inviluppo` | `fun inviluppo(punti: List<Punto>): List<Punto>` | catena monotona di Andrew, senza collineari |
| `rettangoloMinimo` | `fun rettangoloMinimo(punti: List<Punto>): RettangoloMinimo` | calibri rotanti sui lati dell'inviluppo (= `cv2.minAreaRect`) |
| `allarga` | `fun allarga(r: RettangoloMinimo, d: Float): RettangoloMinimo` | +d per lato, stesso centro e orientamento (= unclip tondo + `minAreaRect`) |
| `ordinaVertici` | `fun ordinaVertici(v: List<Punto>): Quadrilatero` | `get_mini_boxes` |
| `dentro` | `fun dentro(poli: List<Punto>, x: Float, y: Float): Boolean` | poligono convesso, bordo compreso |
| `omografia` | `fun omografia(da: List<Punto>, a: List<Punto>): DoubleArray` | 4 corrispondenze → 9 coefficienti (h33 = 1), Gauss con pivot; degenere → identita' |

### 6.9 `CtcDecoder(dizionario: List<String>)`
`val classi: Int` (= `dizionario.size + 2`). `fun decodifica(uscita: FloatArray, passi: Int, classi: Int, inizio: Int = 0): Pair<String, Float>`
— argmax per passo, ripetizioni fuse, 0 = blank, `i` → `dizionario[i − 1]`, ultima classe = spazio;
confidenza = media delle probabilita' dei caratteri tenuti (0 se nessuno); `require(classi == this.classi)`.

### 6.10 `Strisce` (object)
| Metodo | Firma | Effetto |
|---|---|---|
| `tagli` | `fun tagli(larghezza: Int, altezza: Int, sovrapposizione: Float = 0.15f): List<IntRange>` | fasce alte = larghezza, passo 85%, l'ultima allineata al fondo; immagine non piu' alta che larga = una fascia |
| `unisci` | `fun unisci(riquadri: List<Quadrilatero>, soglia: Float = 0.5f): List<Quadrilatero>` | doppioni: intersezione dei contenitori ≥ `soglia` del **piu' piccolo** → resta il piu' grande. ⚑ Non IoU (specsheet): la riga tagliata al bordo di una fascia ha IoU basso con quella intera |
| `contenimento` | `internal fun contenimento(a: Rettangolo, b: Rettangolo): Float` | intersezione / area minore |

## 7. iOS (Swift)

- `MicroOcrPlugin` (`NSObject, FlutterPlugin`): `register(with:)`, `handle(_:result:)` (§5);
  `prepara`/`rilascia` non fanno nulla (Vision e' di sistema); `leggi` su
  `DispatchQueue(label: "micro_ocr", qos: .userInitiated)` seriale, risposta sul main thread; errori →
  `FlutterError(code: "non_disponibile")`.
- `enum VisionOcr`: `static let nome = "vision"`; `static let paroleUtili` (TOTALE, SUBTOTALE,
  COMPLESSIVO, SCONTO, ANZICHÉ, €/KG, €/LT, IMPORTO, TARA, NETTO, STORNO);
  `static func leggi(percorso: String, modo: String) throws -> [[String: Any]]`:
  `CGImageSourceCreateWithURL` + `kCGImagePropertyOrientation` → `VNImageRequestHandler(cgImage:orientation:options:)`;
  `VNRecognizeTextRequest` con `.accurate`, revisione massima, `recognitionLanguages` = `["it-IT", "en-US"]`
  filtrate per `supportedRecognitionLanguages()`, `usesLanguageCorrection = false`, `customWords`,
  `minimumTextHeight` 0,008 (scontrino) / 0 (cartellino); per osservazione `topCandidates(1)` →
  `{t, c, x, y, w, h, origine: "basso"}`.
- `enum ErroreVision: Error` — `.immagineIlleggibile(String)`.
- `PrivacyInfo.xcprivacy` vuoto (nessun dato, nessun tracking) incluso da podspec e `Package.swift`.

## 8. Come un'app aggancia `micro_ocr` (Android)

In `apps/<app>/android/app/build.gradle.kts`:
```kotlin
android {
    // ...
    // Modelli non compressi nell'APK (☠ nel plugin non ha effetto: decide il modulo app).
    androidResources { noCompress += "onnx" }
}
// Guardie di privacy (F12.1.2): fa fallire ogni build di release se arriva telemetria ORT,
// INTERNET/ACCESS_NETWORK_STATE da fonti diverse da Play Billing, ORT ≠ 1.28.0, ML Kit/LiteRT...
apply(from = "../../../../packages/micro_ocr/android/privacy_ocr.gradle")
```

**Cosa controlla `privacy_ocr.gradle`** (task `verificaPrivacyOcr`, `finalizedBy` di
`processReleaseMainManifest`: gira a ogni build di release, mai in debug):

| Controllo | Dove legge | Fallisce se |
|---|---|---|
| a. telemetria ORT | manifest unito di release (`intermediates/merged_manifest/release`) | `ai.onnxruntime.TelemetryInitializer` o un `<provider>` con `ai.onnxruntime` |
| b. chi porta la rete | report di fusione `outputs/logs/manifest-merger-release-report.txt` | una riga `ADDED/MERGED/IMPLIED/INJECTED from` del blocco `uses-permission#…INTERNET` che non contenga `[com.google.android.datatransport:` ; del blocco `…ACCESS_NETWORK_STATE` che non contenga `[com.google.android.datatransport:` **ne'** `[androidx.media3:`; una riga `provider#…ai.onnxruntime` |
| c. dipendenze | `releaseRuntimeClasspath` risolto | `com.microsoft.onnxruntime` ≠ 1.28.0; `com.google.mlkit:*`, `firebase-analytics`, `play-services-tflite*`, `com.google.ai.edge.litert:*` |

⚑ **Fonti ammesse, allineate il 2026-10-10 (F12.4) a cio' che Spending Review porta davvero**:
- gruppo **`com.google.android.datatransport`** intero (Play Billing porta sia `transport-backend-cct`
  sia `transport-runtime`; fino al 2026-10-10 lo script ammetteva solo il primo e avrebbe fatto
  fallire la release dell'app) per INTERNET e ACCESS_NETWORK_STATE;
- **`androidx.media3`** solo per ACCESS_NETWORK_STATE: lo porta la fotocamera (`camera_android_camerax`
  → `androidx.camera:camera-video` → `media3-container` → `media3-common`), e' un permesso «normale»
  per lo streaming video, che qui non c'e'; senza INTERNET da altre fonti non puo' mandare niente.
  Toglierlo con `tools:node="remove"` lo toglierebbe anche a Play Billing.
- ☠ **INTERNET resta stretto**: nessuna eccezione per media3, nessuna per `src/debug` (il report e'
  quello di release).
- Il blocco di un elemento del report finisce alla prima riga che non inizia con un prefisso di fonte:
  le righe indentate che seguono sono attributi (`android:name`), non fonti.

**Prova (Spending Review, 2026-10-10)**: `flutter build apk --release` verde; con un
`<uses-permission INTERNET>` aggiunto per prova in `src/main` rosso con
«INTERNET portato da una fonte non ammessa: ADDED from …\src\main\AndroidManifest.xml:11:5-66»
(riga tolta subito dopo).
e dopo `flutter build apk --release`:
`pwsh packages/micro_ocr/tool/verifica_privacy_android.ps1 -Apk <apk>` (esce con 1 se trova
`events.data.microsoft.com`, `OneCollector`, `TelemetryInitializer`, o `1DS` nei `.so` di ORT; stampa
`aapt2 dump permissions`). ⚑ **Regola delle stringhe corte (F12.7, 2026-10-10)**: le stringhe vietate
di **5 caratteri o meno** («1DS») contano **solo dentro una stringa stampabile di almeno 8 caratteri**
(`[ -~]{8,}`, come fa `strings`), e solo nei `.so`; le stringhe lunghe (gli indirizzi veri della
telemetria) si cercano ancora **ovunque**, in Latin1 e in UTF-16. Perche': nel `.so` di ORT 1.28.0 per
`armeabi-v7a` la sequenza «1DS» compare ~20 volte **dentro il codice macchina** (istruzioni Thumb,
« 1DSDS ø»), non come stringa del programma: la vecchia ricerca dava un falso positivo e
faceva fallire una release pulita. Provato rosso su un APK finto con «Microsoft 1DS SDK» (stringa
stampabile) e verde sull'APK vero di Spending Review (167 MB, tre ABI). Provato sull'esempio: verde sull'APK vero, rosso su un APK finto con
l'indirizzo di telemetria; il task Gradle rosso con `INTERNET` aggiunto al manifest dell'app.

## 9. Regole non negoziabili e trappole disinnescate

### Regole
1. ☠ **ONNX Runtime solo 1.28.0** (`strictly` in Gradle, controllo a runtime in `MotorePpOcr.crea`,
   `verificaPrivacyOcr`, script sul binario). Un'altra versione richiede una voce nuova in
   `memory/decisioni.md`.
2. **Nessun permesso** nel manifest del plugin; nessuna rete, nessun download dei modelli.
3. **Modelli nel repo**, SHA-256 in `MODELLI.md` verificati da `modelli_test.dart`; `.gitattributes`:
   `*.onnx binary`, `latin_dict.txt -text`.
4. **Un solo canale, un solo tipo Dart** per i due motori; l'app non ha `if (Platform.isIOS)`.
5. La conversione dell'asse y di Vision vive in Dart (`Riquadro.daVision`), coperta da test.
6. Le immagini dei campioni **non entrano mai** nel repo (ne' nell'esempio): push temporanei e cancellati.

### Trappole, con la causa tecnica
| Trappola | Causa | Difesa |
|---|---|---|
| Righe inclinate che spariscono | rettangolo allineato agli assi pieno a meta' → punteggio < 0,5 (c26: 1 riga contro 16) | rettangoli ruotati (`Geometria`) |
| Canali RGB invece di BGR | PP-OCR addestrato su immagini OpenCV (BGR) | `tensoreDet`/`tensoreRec` scrivono B, G, R |
| Normalizzazione ImageNet sul det | ipotesi della specsheet, ma RapidOCR 3.10 usa 0,5/0,5 | `Preprocess` segue il `config.yaml` |
| Dizionario disallineato | testo plausibile ma sbagliato | `init` di `MotorePpOcr` (504 = 502 + 2), SHA-256 |
| `round()` di Python | arrotonda al pari (1840/32 = 57,5 → 58) | `kotlin.math.round` (al pari), non `roundToInt` |
| Etichette girate di 90° | `rot90` le rende leggibili solo in un verso; RapidOCR usa un classificatore 0/180 | rilettura capovolta delle righe verticali (b09: 0/4 → 4/4) |
| `noCompress` nel plugin | ignorato: la compressione la decide l'app | riga nell'app (§8) |
| `.gradle.kts` applicato con `apply(from)` | crash di `lintVitalAnalyzeRelease` (AGP 9.1, FIR) | guardia in **Groovy** (`privacy_ocr.gradle`) |
| ORT desktop su Windows nei test | i JDK portano un `msvcp140.dll` vecchio (14.29/14.36): `onnxruntime.dll` non si inizializza; precaricare le DLL di System32 da Kotlin NON basta | `MICRO_OCR_JAVA` = un java con le DLL di System32 nella sua `bin/` (solo per il banco) |
| Campioni in `/sdcard/Android/data/<pkg>` | se la cartella la crea `adb shell` l'app non la puo' leggere (errno 13) | `adb push` in `/data/local/tmp` + `run-as <pkg> cp` in `files/f12` (app di debug) |
| `flutter test` disinstalla l'app alla fine | i campioni copiati con run-as spariscono con lei | installare, copiare, lanciare il test (che reinstalla con `-r` e poi disinstalla: pulizia automatica) |
| Foto verticali coricate | EXIF ignorato | `ImmagineIngresso` (Android), orientamento a `VNImageRequestHandler` (iOS) |
| R8 e JNI di ORT | classi rinominate → crash solo in release | `consumer-rules.pro`; provato: APK di release sull'emulatore, `prepara()` 216 ms |
| «1DS» nel `.so` ARMv7 di ORT (F12.7) | la sequenza di byte compare per caso nel codice macchina Thumb: falso positivo della guardia sul binario | stringhe corte contate solo dentro stringhe stampabili di 8+ caratteri (§8) |
| Ultime righe del banco perse sul dispositivo (F12.7) | `debugPrint` e' «throttled»: accoda e scrive poco alla volta; il test d'integrazione finiva prima che la coda si svuotasse (s15 e s16 sparivano dal log del simulatore) | `example/lib/main.dart` usa `print('MICRO_OCR|$json')` (con `// ignore: avoid_print`) |

## 10. Catalogo dei test

| File | Cosa dimostra |
|---|---|
| `test/riga_ocr_test.dart` (14) | JSON di andata e ritorno; `fromJson` con interi; derivati; `daVision` su 4 casi (y capovolto); `sovrapposizioneVerticale` (apice = 1, meta', distinte, altezza nulla); `RigaOcr` piatto e default; nomi di `OcrModo` |
| `test/canale_ocr_engine_test.dart` (6) | argomenti di `leggi`; conversione mappe Android; `origine: basso`; null → `[]`; `nome/prepara/rilascia`; `PlatformException` e `MissingPluginException` → `OcrNonDisponibile` |
| `test/fake_ocr_engine_test.dart` (4) | righe, percorsi e modi registrati; righe modificabili; errore dopo il ritardo; contatori |
| `test/modelli_test.dart` (5) | SHA-256 dei 3 file = `MODELLI.md`; dizionario 502 simboli, € compreso, nessuna riga vuota |
| `android/src/test/.../CtcDecoderTest.kt` (7) | blank, ripetizioni, spazio finale, confidenza media, vuoto, offset nel lotto, classi sbagliate, dizionario senza trim |
| `.../DbPostprocessTest.kt` (12) | due blocchi → due; sotto soglia; punteggio < 0,5; unclip esatto; lati minimi; riporto in destinazione; bordi; 8 vicini; dilatazione 2x2; ordine di lettura; riga inclinata → quadrilatero ruotato; blocco 1000×1000 senza stack overflow |
| `.../PreprocessTest.kt` (4) | multipli di 32 e rapporto; arrotondamento al pari; BGR e 0,5; tensore rec 48×320 con riempimento; larghezza del lotto |
| `.../StrisceTest.kt` (4) | fascia unica; copertura e sovrapposizione ≥ 15%; doppione tagliato fuso; righe vicine distinte restano |
| `.../ImmagineTest.kt` (7) | media 2x2; copia; ritaglio; `rot90`; 180°; `entroLimiti` 4000×3000 → 1984×1504; piccola invariata |
| `.../GeometriaTest.kt` (7) | inviluppo; rettangolo minimo di un rombo; allarga; ordine dei vertici; `dentro`; omografia; ritaglio allineato = ritaglio semplice |
| `.../ParitaJvmTest.kt` (1) | **banco** di parita' (si accende con `MICRO_OCR_PARITA_IN/OUT`): la stessa catena del telefono sulla JVM, un JSON per immagine |
| `example/integration_test/ocr_motore_test.dart` (2) | **sul dispositivo**: PNG disegnato con «PASTA 500 g» e «2,49» → contiene «2,49», riquadri in 0..1, «2,49» sotto «PASTA» (asse y); file inesistente → `OcrNonDisponibile`. Verde su emulatore Android (477 ms) e simulatore iPhone (765 ms) |
| `example/integration_test/ocr_parita_test.dart` (1) | legge `F12_DIR` e stampa `MICRO_OCR|<json>`; salta se la cartella non c'e' |

Comandi: `flutter test` (nel package); `gradlew.bat :micro_ocr:testDebugUnitTest` da `example/android`
(dopo un `flutter build apk --config-only` o una build qualunque dell'esempio);
`flutter test integration_test/ocr_motore_test.dart -d <dispositivo>` da `example/`.

**Esiti del banco (2026-10-10)**, metrica di F12.1.9 = numeri `x,yy` della lettura RapidOCR 3.10
ritrovati nella lettura nostra (script `confronta.py` nello scratchpad della sessione, non nel repo):

| Dove | 33 campioni liberi | tutti i 60 |
|---|---|---|
| JVM (PC, ORT desktop 1.28.0) | **242/243 = 99,6%** | 322/326 = 98,8% |
| Emulatore Android API 35 x86_64 | **242/243 = 99,6%** | — (solo i liberi copiati) |
| Simulatore iPhone (Vision) | 164/212 = 77,4% (31 letture nel log) | — |

Vision non e' tenuto alla parita' con RapidOCR (motore diverso: le sue fixture arrivano in F12.7
dall'iPad); il numero e' informativo. Tempi sull'emulatore (CPU del PC, non rappresentativi):
cartellini 0,2–4 s (tipico ~1 s), scontrini 0,9–3,3 s; simulatore 0,13–0,7 s.

## 11. Cosa NON esiste ancora

- **Classificatore 0°/180°** (`ch_ppocr_mobile_v2.0_cls`, 0,6 MB) che RapidOCR usa: qui solo la
  rilettura capovolta delle righe verticali. Le righe orizzontali capovolte (foto a testa in giu')
  non si raddrizzano.
- **Batch/threads tarati su un telefono vero**, XNNPACK: da misurare in F12.7 (F12.1.18).
- Le **fixture di Vision lette su un iPad vero**: oggi ci sono solo quelle del **simulatore**
  (`apps/spending_review/test/fixtures/ocr/vision-sim/` e `vision-sim-mirino/`, F12.7, 33 + 20 nel
  repo); quelle dell'iPad arrivano con TestFlight (F12.7, aperto).
- `integration_test/ocr_parita_test.dart` che confronti da solo con le fixture (≥ 95%): oggi stampa e il
  confronto lo fa lo script del banco; le fixture nascono in F12.3.
- Il «padding verticale» di RapidOCR per immagini larghissime (rapporto > 8) o basse ≤ 30 px.

## 12. Debito tecnico aperto

| Debito | Perche' rimandato | Quando |
|---|---|---|
| Tempi su Android vero di fascia media | l'emulatore x86_64 non e' rappresentativo; nessun telefono Android vero disponibile al 2026-10-10 | F12.7 (ancora aperto: misure F12.1.18 di Spending Review) |
| Classificatore 0/180 | cambierebbe il set dei modelli (decisione); +0,6 MB | se le foto vere del proprietario lo chiedono |
| Il banco di PARITA' (`prepara_parita.py`, `confronta.py`) vive ancora nello scratchpad | le fixture del PARSER invece sono nel repo dell'app da F12.3 (`apps/spending_review/tool/esporta_fixture_ocr.py`, anche `--ritagli` e `--log`); la parita' con RapidOCR non si rimisura finche' i modelli non cambiano | quando si toccano modelli o parametri |
| Vision su simulatore 77% sui numeri; sul **parser** (F12.7) sotto PP-OCRv5 (ritagli prezzo 33/40 contro 36/40, totali bilancia 7/9 contro 9/9, scontrino 14/16 contro 16/16) | il simulatore non usa il Neural Engine; misura vera su iPad | F12.7 (TestFlight); se il distacco resta, ORT 1.28 anche su iOS (+22 MB) — decide il proprietario |

## 13. Il perche' delle scelte non ovvie

- **Catena su `ImmagineRgb` e non su `Bitmap`**: la stessa classe gira sulla JVM del PC; il banco di
  parita' gira in 25 s senza dispositivo, ed e' cosi' che i rettangoli ruotati e la rilettura capovolta
  sono stati trovati e misurati.
- **Lotti di 6 nel riconoscitore** (la specsheet diceva una inferenza per riga): il riempimento a destra
  dipende dal lotto; per la parita' conta farlo come RapidOCR, ed e' anche piu' veloce.
- **Parametri del banco, non quelli della specsheet** (736 lato corto, 0,5/0,5, box_thresh 0,5): la
  specsheet stessa chiedeva di ricontrollarli nel `config.yaml` di RapidOCR 3.10; le misure di
  f12-ocr.md §7 valgono solo con questi.
- **Guardia come script condiviso nel plugin**, non scritta nell'app: una regola, un posto.

import Foundation
import ImageIO
import Vision

/// Errori della lettura con Vision.
enum ErroreVision: Error, CustomStringConvertible {
  case immagineIlleggibile(String)

  var description: String {
    switch self {
    case .immagineIlleggibile(let p): return "immagine illeggibile: \(p)"
    }
  }
}

/// OCR con `VNRecognizeTextRequest` (F12.1.9, lato iOS). Tutto sul telefono, 0 MB nell'app.
enum VisionOcr {
  static let nome = "vision"

  /// Parole che Vision privilegia (efficaci solo con la correzione linguistica accesa, che qui
  /// e' SPENTA: si mettono comunque, costano zero).
  static let paroleUtili = [
    "TOTALE", "SUBTOTALE", "COMPLESSIVO", "SCONTO", "ANZICHÉ", "€/KG", "€/LT", "IMPORTO",
    "TARA", "NETTO", "STORNO",
  ]

  /// Legge l'immagine su [percorso]. Restituisce le righe come mappe
  /// `{"t", "c", "x", "y", "w", "h", "origine": "basso"}`: il riquadro e' quello di Vision,
  /// normalizzato con origine in BASSO a sinistra.
  ///
  /// ⚑ La conversione dell'asse y si fa in Dart (`Riquadro.daVision`), dove un test la copre.
  static func leggi(percorso: String, modo: String) throws -> [[String: Any]] {
    let url = URL(fileURLWithPath: percorso)
    guard let sorgente = CGImageSourceCreateWithURL(url as CFURL, nil),
      let immagine = CGImageSourceCreateImageAtIndex(sorgente, 0, nil)
    else { throw ErroreVision.immagineIlleggibile(percorso) }

    // ☠ Senza l'orientamento EXIF le foto in verticale arrivano coricate e Vision legge
    // pochissimo (F12.1.16 trappola 3). Le coordinate restituite sono gia' nello spazio
    // dell'immagine RADDRIZZATA.
    var orientamento = CGImagePropertyOrientation.up
    if let proprieta = CGImageSourceCopyPropertiesAtIndex(sorgente, 0, nil) as? [CFString: Any],
      let valore = proprieta[kCGImagePropertyOrientation] as? UInt32,
      let o = CGImagePropertyOrientation(rawValue: valore)
    {
      orientamento = o
    }

    let richiesta = VNRecognizeTextRequest()
    richiesta.recognitionLevel = .accurate
    if let massima = VNRecognizeTextRequest.supportedRevisions.max() {
      richiesta.revision = massima
    }
    // L'italiano c'e' dalla revisione 2 (f12-ocr.md §2): si chiede a Vision cosa supporta
    // invece di fidarsi di una lista.
    let supportate = (try? richiesta.supportedRecognitionLanguages()) ?? []
    let lingue = ["it-IT", "en-US"].filter { supportate.contains($0) }
    if !lingue.isEmpty { richiesta.recognitionLanguages = lingue }
    // ⚑ Spenta: la correzione linguistica «aggiusta» i numeri dei prezzi.
    richiesta.usesLanguageCorrection = false
    richiesta.customWords = paroleUtili
    richiesta.minimumTextHeight = modo == "scontrino" ? 0.008 : 0

    let gestore = VNImageRequestHandler(cgImage: immagine, orientation: orientamento, options: [:])
    try gestore.perform([richiesta])

    var righe: [[String: Any]] = []
    for osservazione in richiesta.results ?? [] {
      guard let migliore = osservazione.topCandidates(1).first else { continue }
      let r = osservazione.boundingBox
      righe.append([
        "t": migliore.string,
        "c": Double(migliore.confidence),
        "x": Double(r.origin.x),
        "y": Double(r.origin.y),
        "w": Double(r.size.width),
        "h": Double(r.size.height),
        "origine": "basso",
      ])
    }
    return righe
  }
}

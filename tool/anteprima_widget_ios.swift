// Renderizza il widget iOS di TrashCan sul Mac, per guardarlo prima di spedirlo.
//
//   swiftc -parse-as-library -O \
//     apps/trashcan/ios/TrashcanWidget/VistaTrashcan.swift tool/anteprima_widget_ios.swift \
//     -o /tmp/anteprima && /tmp/anteprima /tmp/anteprima.png [contenitore.plist]
//
// ☠ **Perché esiste.** Un widget non si mette sulla schermata da riga di comando, e il
//   4 ottobre 2026 ne è arrivato al proprietario uno mai guardato: un riquadro bianco con
//   una fascia verde e nessuna parola. Da allora ogni modifica a `VistaTrashcan.swift` si
//   guarda qui prima di finire su TestFlight.
//
// ⚑ Compila **la stessa vista** del widget, non una copia: per questo `VistaTrashcan.swift`
//   non usa niente che esista solo su iOS. Le dimensioni sono fisse in punti e i caratteri
//   hanno dimensioni esplicite, quindi Mac e iPhone disegnano uguale.
//
// ⚑ Col secondo argomento legge il contenitore vero copiato dal simulatore: verifica in
//   un colpo solo la catena intera, da Dart che scrive le righe alla vista che le disegna.

import AppKit
import SwiftUI
import WidgetKit

@main
struct Anteprima {
    @MainActor
    static func main() {
        let argomenti = CommandLine.arguments
        let uscita = argomenti.count > 1 ? argomenti[1] : "/tmp/anteprima.png"

        var casi: [(String, StatoGiorno)] = esempi()
        if argomenti.count > 2, let reale = daContenitore(argomenti[2]) {
            casi.insert(("dal simulatore, oggi", reale), at: 0)
        }

        let foglio = Foglio(casi: casi)
        let render = ImageRenderer(content: foglio)
        render.scale = 2
        guard let immagine = render.nsImage,
              let tiff = immagine.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else {
            FileHandle.standardError.write("rendering fallito\n".data(using: .utf8)!)
            exit(1)
        }
        try? png.write(to: URL(fileURLWithPath: uscita))
        print("scritta \(uscita): \(casi.count) casi")
    }

    /// Lo stato di oggi letto da un `.plist` del contenitore condiviso.
    static func daContenitore(_ percorso: String) -> StatoGiorno? {
        guard let dizionario = NSDictionary(contentsOfFile: percorso) as? [String: Any] else {
            return nil
        }
        let deposito = Deposito { dizionario[$0] as? String }
        return deposito.stato(per: Date()) ?? deposito.statoAssente(al: Date())
    }

    /// I casi che devono reggere tutti: colore scuro, colore chiaro, niente stasera,
    /// nome lungo, nessun dato.
    static func esempi() -> [(String, StatoGiorno)] {
        let foglia = icona("leaf.fill")
        let bottiglia = icona("drop.fill")
        let elenco = ["mar 6   Carta", "mer 7   Plastica", "gio 8   Vetro"]

        func stato(_ testo: String, _ argb: Int?, _ icona: String?, _ prossimi: [String]) -> StatoGiorno {
            StatoGiorno(
                date: Date(), etichetta: "Stasera", cosaStasera: testo, argb: argb,
                percorsoIcona: icona, prossimi: prossimi,
                elencoVuoto: "Nessuna raccolta nei prossimi giorni", senzaDati: false
            )
        }

        return [
            ("organico", stato("Organico", 0xFF627D36, foglia, elenco)),
            ("plastica, colore chiaro", stato("Plastica", 0xFFC9A227, bottiglia, elenco)),
            ("niente stasera", stato("Stasera non devi buttare nulla", nil, nil, elenco)),
            ("nome lungo", stato("Indifferenziato, Carta, Vetro", 0xFF5A5A5A, foglia, elenco)),
            ("elenco vuoto", stato("Organico", 0xFF627D36, foglia, [])),
            ("nessun dato", Deposito { _ in nil }.statoAssente(al: Date())),
        ]
    }

    /// Un PNG bianco su trasparente, come quelli che Dart disegna per il widget.
    static func icona(_ simbolo: String) -> String? {
        let percorso = "/tmp/anteprima_\(simbolo).png"
        let config = NSImage.SymbolConfiguration(pointSize: 64, weight: .semibold)
            .applying(.init(paletteColors: [.white]))
        guard let simbolo = NSImage(systemSymbolName: simbolo, accessibilityDescription: nil)?
            .withSymbolConfiguration(config),
              let tiff = simbolo.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else { return nil }
        try? png.write(to: URL(fileURLWithPath: percorso))
        return percorso
    }
}

/// Tutti i casi in una sola immagine, piccolo e medio affiancati.
///
/// ⚑ Il piccolo si disegna in due misure: 170 punti, l'iPhone grande, e 141, il riquadro
/// piccolo di un iPad mini, che è il caso peggiore e quello che il proprietario usa.
struct Foglio: View {
    let casi: [(String, StatoGiorno)]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(Array(casi.enumerated()), id: \.offset) { _, caso in
                VStack(alignment: .leading, spacing: 6) {
                    Text(caso.0).font(.system(size: 13, weight: .medium)).foregroundColor(.white)
                    HStack(alignment: .top, spacing: 18) {
                        tessera(caso.1, .systemSmall, 170, 170)
                        tessera(caso.1, .systemSmall, 141, 141)
                        tessera(caso.1, .systemMedium, 364, 170)
                    }
                }
            }
        }
        .padding(28)
        .background(Color(red: 0.24, green: 0.27, blue: 0.33))
        .environment(\.colorScheme, .light)
    }

    private func tessera(_ s: StatoGiorno, _ f: WidgetFamily, _ w: CGFloat, _ h: CGFloat) -> some View {
        VistaTrashcan(entry: s, famiglia: f)
            .frame(width: w, height: h)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

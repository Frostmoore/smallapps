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

        // `--vetrina it|en <file>`: l'immagine del widget per la scheda dell'App Store.
        if argomenti.count > 3, argomenti[1] == "--vetrina" {
            scrivi(Vetrina(italiano: argomenti[2] == "it"), in: argomenti[3], scala: 3)
            return
        }

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

    /// Scrive una vista come PNG, alla misura esatta in pixel.
    @MainActor
    static func scrivi<V: View>(_ vista: V, in percorso: String, scala: CGFloat) {
        let render = ImageRenderer(content: vista)
        render.scale = scala
        guard let cg = render.cgImage else {
            FileHandle.standardError.write("rendering fallito\n".data(using: .utf8)!)
            exit(1)
        }
        // ⚑ Da `CGImage` e non da `NSImage`: la seconda passa per una rappresentazione TIFF
        //   che sugli schermi Retina può raddoppiare i pixel, e App Store Connect rifiuta
        //   qualunque misura che non sia esattamente una di quelle ammesse.
        let bitmap = NSBitmapImageRep(cgImage: cg)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
        try? png.write(to: URL(fileURLWithPath: percorso))
        print("scritta \(percorso): \(cg.width)x\(cg.height)")
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

/// L'immagine del widget per la scheda dell'App Store: 440x956 punti, cioè 1320x2868 a
/// scala 3, la misura da 6,9 pollici che App Store Connect pretende.
///
/// ⚑ È **composta**, non fotografata, e va detto: un widget non si mette sulla schermata da
/// riga di comando. Ma i widget dentro sono la vista vera, `VistaTrashcan`, con dati
/// realistici: quello che si vede è esattamente quello che il telefono disegna.
struct Vetrina: View {
    let italiano: Bool

    private func stato(_ testo: String, _ argb: Int, _ simbolo: String, _ prossimi: [String]) -> StatoGiorno {
        StatoGiorno(
            date: Date(), etichetta: italiano ? "Stasera" : "Tonight", cosaStasera: testo,
            argb: argb, percorsoIcona: Anteprima.icona(simbolo), prossimi: prossimi,
            elencoVuoto: "", senzaDati: false
        )
    }

    var body: some View {
        let organico = stato(
            italiano ? "Organico" : "Organic", 0xFF627D36, "leaf.fill",
            italiano
                ? ["mar 7   Carta", "mer 8   Plastica", "gio 9   Indifferenziato"]
                : ["Tue 7   Paper", "Wed 8   Plastic", "Thu 9   Unsorted"]
        )
        let plastica = stato(
            italiano ? "Plastica" : "Plastic", 0xFFC9A227, "drop.fill",
            italiano ? ["gio 9   Indifferenziato", "ven 10   Organico", "sab 11   Vetro"]
                : ["Thu 9   Unsorted", "Fri 10   Organic", "Sat 11   Glass"]
        )
        let carta = stato(
            italiano ? "Carta" : "Paper", 0xFF2E6F9E, "doc.fill",
            italiano ? ["mer 8   Plastica", "gio 9   Indifferenziato", "ven 10   Organico"]
                : ["Wed 8   Plastic", "Thu 9   Unsorted", "Fri 10   Organic"]
        )

        VStack(spacing: 0) {
            VStack(spacing: 14) {
                Text(italiano ? "Cosa si butta stasera,\nsenza aprire l'app." :
                        "What goes out tonight,\nwithout opening the app.")
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(italiano ? "Il widget si aggiorna da solo ogni sera." :
                        "The widget updates itself every evening.")
                    .font(.system(size: 18, weight: .medium))
                    .opacity(0.8)
            }
            .foregroundColor(.white)
            .padding(.top, 120)
            .padding(.horizontal, 24)

            Spacer(minLength: 0)

            // ⚑ Ingranditi del 15%: a misura reale, su una vetrina vista come miniatura nella
            //   pagina dello store, il testo dell'elenco non si legge. Il disegno resta quello.
            VStack(spacing: 26) {
                tessera(organico, .systemMedium, 364, 170)
                HStack(spacing: 24) {
                    tessera(plastica, .systemSmall, 170, 170)
                    tessera(carta, .systemSmall, 170, 170)
                }
            }
            .scaleEffect(1.15)

            Spacer(minLength: 0)
            Spacer(minLength: 0)
        }
        .frame(width: 440, height: 956)
        .background(
            LinearGradient(
                colors: [Color(argb: 0xFF1F5A41), Color(argb: 0xFF16241E)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .environment(\.colorScheme, .light)
    }

    private func tessera(_ s: StatoGiorno, _ f: WidgetFamily, _ w: CGFloat, _ h: CGFloat) -> some View {
        VistaTrashcan(entry: s, famiglia: f)
            .frame(width: w, height: h)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            // ☠ `compositingGroup` prima dell'ombra: senza, SwiftUI proietta l'ombra di ogni
            //   elemento interno, e la testata ne getta una sulla colonna colorata e i testi
            //   prendono un alone. Il widget vero non ce l'ha: era solo la vetrina a mentire.
            .compositingGroup()
            .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
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

// Renderizza il widget iOS di Full Freezer sul Mac, per guardarlo prima di spedirlo.
//
//   swiftc -parse-as-library -O \
//     apps/full_freezer/ios/FullFreezerWidget/VistaFreezer.swift \
//     apps/full_freezer/tool/anteprima_widget_ios.swift -o /tmp/anteprima_ff \
//     && /tmp/anteprima_ff /tmp/anteprima_ff.png [contenitore.plist]
//
// ⚑ Col secondo argomento legge il contenitore vero del simulatore
//   (`<AppGroup>/Library/Preferences/group.com.smp.fullfreezer.plist`): verifica in un colpo
//   solo la catena intera, da Dart che scrive alla vista che disegna, icone comprese.
//
// ☠ Perche' esiste: un widget non si mette sulla schermata da riga di comando, e in TrashCan
//   ne era arrivato al proprietario uno mai guardato (4 ottobre 2026). Compila **la stessa
//   vista** del widget, non una copia.

import AppKit
import SwiftUI
import WidgetKit

@main
struct Anteprima {
    @MainActor
    static func main() {
        let uscita = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/anteprima_ff.png"
        var reale: Deposito?
        if CommandLine.arguments.count > 2,
           let dati = NSDictionary(contentsOfFile: CommandLine.arguments[2]) as? [String: Any] {
            reale = Deposito { dati[$0] as? String }
        }
        let render = ImageRenderer(content: Foglio(reale: reale))
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
        print("scritta \(uscita)")
    }
}

/// Un contenitore finto, con le stesse chiavi che scrive Dart.
func deposito(_ righe: String?) -> Deposito {
    let valori: [String: String] = [
        Chiavi.titolo: "DA USARE PRIMA",
        Chiavi.conteggio: "23 prodotti",
        Chiavi.vuoto: "Il freezer è vuoto",
        Chiavi.oggi: "oggi",
        Chiavi.modelloGiorni: "{n} gg",
    ]
    return Deposito { chiave in chiave == Chiavi.righe ? righe : valori[chiave] }
}

struct Foglio: View {
    let reale: Deposito?
    let oggi = Deposito.formatoData.date(from: "2026-10-07")!
    let piena = "2026-05-23\u{1F}Spezzatino di manzo con piselli\u{1F}meat\u{1F}180\n"
        + "2026-06-05\u{1F}Merluzzo\u{1F}fish\u{1F}120\n"
        + "2026-10-07\u{1F}Pane\u{1F}bread\u{1F}90"

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let reale {
                caso("dal simulatore, oggi", reale.voce(al: Date()), .systemMedium, 338, 158)
            }
            caso("medio, pieno", deposito(piena).voce(al: oggi), .systemMedium, 338, 158)
            caso("medio, 8 giorni dopo (timeline)",
                 deposito(piena).voce(al: Calendar.current.date(byAdding: .day, value: 8, to: oggi)!),
                 .systemMedium, 338, 158)
            HStack(spacing: 18) {
                caso("piccolo", deposito(piena).voce(al: oggi), .systemSmall, 158, 158)
                caso("vuoto", deposito("").voce(al: oggi), .systemSmall, 158, 158)
                caso("mai aperta", deposito(nil).voce(al: oggi), .systemSmall, 158, 158)
            }
        }
        .padding(24)
        .background(Color(white: 0.85))
    }

    func caso(_ titolo: String, _ voce: VoceFreezer, _ famiglia: WidgetFamily, _ w: CGFloat, _ h: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titolo).font(.system(size: 11)).foregroundColor(.black)
            VistaFreezer(entry: voce, famiglia: famiglia)
                .frame(width: w, height: h)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}

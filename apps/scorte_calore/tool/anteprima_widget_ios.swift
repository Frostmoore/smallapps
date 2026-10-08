// Renderizza il widget iOS di Scorte Calore sul Mac, per guardarlo prima di spedirlo.
//
//   swiftc -parse-as-library -O \
//     apps/scorte_calore/ios/ScorteCaloreWidget/VistaScorte.swift \
//     apps/scorte_calore/tool/anteprima_widget_ios.swift -o /tmp/anteprima_sc \
//     && /tmp/anteprima_sc /tmp/anteprima_sc.png [contenitore.plist]
//
// ⚑ Col secondo argomento legge il contenitore vero del simulatore
//   (`<AppGroup>/Library/Preferences/group.com.smp.scortecalore.plist`): verifica in un colpo
//   solo la catena intera, da Dart che scrive alla vista che disegna.
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
        // `--vetrina it|en <file>`: il widget medio da solo, grande e su fondo trasparente, per
        // le grafiche delle schede degli store (tool/genera_grafiche_store.py).
        if CommandLine.arguments.count > 3, CommandLine.arguments[1] == "--vetrina" {
            let it = CommandLine.arguments[2] == "it"
            let righe = [
                "\(it ? "Stufa soggiorno" : "Living room stove")\u{1F}2026-12-09\u{1F}2026-12-02\u{1F}\(it ? "2 dic" : "Dec 2")",
                "\(it ? "Bombolone GPL" : "LPG tank")\u{1F}2026-11-26\u{1F}2026-11-19\u{1F}\(it ? "19 nov" : "Nov 19")",
            ].joined(separator: "\n")
            let valori: [String: String] = [
                Chiavi.titolo: it ? "SCORTE" : "HEATING STOCK",
                Chiavi.oggi: it ? "oggi" : "today",
                Chiavi.modelloGiorni: it ? "{n} giorni" : "{n} days",
                Chiavi.modelloRiordino: it ? "Riordina entro il {d}" : "Reorder by {d}",
                Chiavi.riordinaOra: it ? "Riordina ora" : "Reorder now",
                Chiavi.servonoMisure: "",
                Chiavi.righe: righe,
            ]
            let voce = Deposito { valori[$0] }.voce(al: Deposito.formatoData.date(from: "2026-10-08")!)
            let vista = VistaScorte(entry: voce, famiglia: .systemMedium)
                .frame(width: 338, height: 158)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            let render = ImageRenderer(content: vista)
            render.scale = 4
            guard let img = render.nsImage, let tiff = img.tiffRepresentation,
                  let bmp = NSBitmapImageRep(data: tiff),
                  let png = bmp.representation(using: .png, properties: [:])
            else { exit(1) }
            try? png.write(to: URL(fileURLWithPath: CommandLine.arguments[3]))
            print("vetrina scritta")
            return
        }
        let uscita = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/anteprima_sc.png"
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
        Chiavi.titolo: "SCORTE",
        Chiavi.vuoto: "Nessuna fonte di calore",
        Chiavi.oggi: "oggi",
        Chiavi.modelloGiorni: "{n} giorni",
        Chiavi.modelloRiordino: "Riordina entro il {d}",
        Chiavi.riordinaOra: "Riordina ora",
        Chiavi.servonoMisure: "Servono altre misure",
    ]
    return Deposito { chiave in chiave == Chiavi.righe ? righe : valori[chiave] }
}

struct Foglio: View {
    let reale: Deposito?
    let oggi = Deposito.formatoData.date(from: "2026-10-08")!
    let piena = "Stufa soggiorno\u{1F}2026-12-09\u{1F}2026-12-01\u{1F}1 dic\n"
        + "Bombolone GPL\u{1F}2026-10-20\u{1F}2026-10-06\u{1F}6 ott\n"
        + "Caldaia pellet\u{1F}\u{1F}\u{1F}"

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

    func caso(_ titolo: String, _ voce: VoceScorte, _ famiglia: WidgetFamily, _ w: CGFloat, _ h: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titolo).font(.system(size: 12, weight: .semibold)).foregroundColor(.black)
            VistaScorte(entry: voce, famiglia: famiglia)
                .frame(width: w, height: h)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}

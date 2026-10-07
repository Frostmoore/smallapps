import SwiftUI
import WidgetKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// La parte del widget che si vede: lettura del contenitore e disegno (F4.11).
//
// ⚑ **In un file separato da `FullFreezerWidget.swift` per poterla guardare sul Mac** con
// `apps/full_freezer/tool/anteprima_widget_ios.swift`: un widget non si mette sulla
// schermata da riga di comando, e in TrashCan ne era arrivato al proprietario uno mai
// guardato (4 ottobre 2026). Quindi qui niente che esista solo su iOS.
//
// ⚑ **I giorni si calcolano qui** (ADR-018), dalla data di congelamento di ogni riga e dalla
// data della voce della timeline: cosi' il widget del giorno dopo dice "13 gg" senza che
// l'app sia stata aperta. Il formato delle righe e' lo stesso del provider Kotlin su
// Android, scritto da `lib/services/freezer_widget.dart`: se divergono, il difetto si vede su
// una piattaforma sola e lo si cerca nel posto sbagliato.

enum Chiavi {
    /// Uguale a `FreezerWidget.iosGroup` e ai due `.entitlements`.
    static let gruppo = "group.com.smp.fullfreezer"

    static let titolo = "title"
    static let conteggio = "count"
    static let vuoto = "empty"
    static let righe = "rows"
    static let oggi = "days_today"
    static let modelloGiorni = "days_template"
    static let prefissoIcona = "icon_"
}

/// Separatore fra i campi di una riga: US, come in Dart e in Kotlin.
let separatoreCampo: Character = "\u{1F}"

/// I testi che l'estensione deve saper dire **da sola**: se il contenitore e' vuoto, e' vuoto
/// anche qualunque testo messo li' dentro (lezione di TrashCan).
enum Ripiego {
    static var italiano: Bool { (Locale.preferredLanguages.first ?? "en").hasPrefix("it") }
    static var titolo: String { italiano ? "DA USARE PRIMA" : "USE FIRST" }
    static var apri: String {
        italiano ? "Apri Full Freezer per vedere cosa c’è dentro." : "Open Full Freezer to see what’s inside."
    }
}

/// Un alimento come lo scrive Dart: `frozenAt US nome US iconKey US promemoria`.
struct RigaAlimento: Hashable {
    let congelato: Date
    let nome: String
    let chiaveIcona: String
    let promemoria: Int?
}

struct VoceFreezer: TimelineEntry {
    let date: Date
    let titolo: String
    let conteggio: String
    let righe: [RigaAlimento]
    let vuoto: String
    let oggi: String
    let modelloGiorni: String
    /// I percorsi dei PNG delle icone, per chiave.
    let icone: [String: String]
    /// `true` se l'app non ha mai scritto niente (o il gruppo non e' condiviso).
    let senzaDati: Bool

    /// I giorni nel freezer alla data di questa voce, non a quella di adesso.
    func giorni(_ riga: RigaAlimento) -> Int {
        let calendario = Calendar.current
        let da = calendario.startOfDay(for: riga.congelato)
        let a = calendario.startOfDay(for: date)
        return max(0, calendario.dateComponents([.day], from: da, to: a).day ?? 0)
    }

    func testoGiorni(_ riga: RigaAlimento) -> String {
        let n = giorni(riga)
        return n == 0 ? oggi : modelloGiorni.replacingOccurrences(of: "{n}", with: String(n))
    }

    /// Arancione quando si e' superato il promemoria, come i badge della home.
    func vecchio(_ riga: RigaAlimento) -> Bool {
        guard let p = riga.promemoria, p > 0 else { return false }
        return giorni(riga) >= p
    }
}

// MARK: - Lettura

struct Deposito {
    /// Un'astrazione su `UserDefaults` perche' l'anteprima legge lo stesso contenuto da un
    /// dizionario o da un `.plist` copiato dal simulatore.
    let leggi: (String) -> String?

    static var condiviso: Deposito {
        let difese = UserDefaults(suiteName: Chiavi.gruppo)
        return Deposito { difese?.string(forKey: $0) }
    }

    static let formatoData: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func voce(al giorno: Date) -> VoceFreezer {
        guard let testo = leggi(Chiavi.righe) else {
            return VoceFreezer(
                date: giorno, titolo: Ripiego.titolo, conteggio: "", righe: [], vuoto: Ripiego.apri,
                oggi: "", modelloGiorni: "{n}", icone: [:], senzaDati: true
            )
        }
        let righe: [RigaAlimento] = testo.split(separator: "\n").compactMap { riga in
            let campi = riga.split(separator: separatoreCampo, omittingEmptySubsequences: false)
            // Una riga piu' corta e' un formato cambiato da un'app piu' recente: meglio
            // saltarla che disegnare campi sfasati.
            guard campi.count >= 4, let data = Self.formatoData.date(from: String(campi[0])) else { return nil }
            return RigaAlimento(
                congelato: data, nome: String(campi[1]), chiaveIcona: String(campi[2]), promemoria: Int(campi[3])
            )
        }
        var icone: [String: String] = [:]
        for riga in righe {
            if let percorso = leggi(Chiavi.prefissoIcona + riga.chiaveIcona) { icone[riga.chiaveIcona] = percorso }
        }
        return VoceFreezer(
            date: giorno,
            titolo: leggi(Chiavi.titolo) ?? Ripiego.titolo,
            conteggio: leggi(Chiavi.conteggio) ?? "",
            righe: righe,
            vuoto: leggi(Chiavi.vuoto) ?? "",
            oggi: leggi(Chiavi.oggi) ?? "",
            modelloGiorni: leggi(Chiavi.modelloGiorni) ?? "{n}",
            icone: icone,
            senzaDati: false
        )
    }
}

// MARK: - Colori (FreezerPalette, testata blu notte)

extension Color {
    init(argb: UInt32) {
        self.init(
            .sRGB,
            red: Double((argb >> 16) & 0xFF) / 255,
            green: Double((argb >> 8) & 0xFF) / 255,
            blue: Double(argb & 0xFF) / 255,
            opacity: Double((argb >> 24) & 0xFF) / 255
        )
    }

    static let notte = Color(argb: 0xFF0B1A33)
    static let ghiaccio = Color(argb: 0xFF8FB8FF)
    static let suNotteSpento = Color(argb: 0xFFB9CBE8)
    static let badge = Color(argb: 0xFFFFB547)
}

// MARK: - Disegno

struct VistaFreezer: View {
    let entry: VoceFreezer
    let famiglia: WidgetFamily

    /// Le stesse tre righe di Android (`FreezerWidget.rowCount`); nel piccolo due.
    private var righeMassime: Int { famiglia == .systemSmall ? 2 : 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.titolo)
                    .font(.system(size: 11, weight: .bold))
                    .kerning(1.2)
                    .foregroundColor(.ghiaccio)
                    .lineLimit(1)
                Spacer(minLength: 6)
                if famiglia != .systemSmall {
                    Text(entry.conteggio)
                        .font(.system(size: 11))
                        .foregroundColor(.suNotteSpento)
                        .lineLimit(1)
                }
            }
            .padding(.bottom, 6)

            if entry.righe.isEmpty {
                Spacer(minLength: 0)
                Text(entry.vuoto)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            } else {
                // ⚑ Le righe si dividono l'altezza: ammassate in alto lasciavano mezzo widget
                //   vuoto, che si legge come "non ha caricato" (visto su Android il 2026-10-07).
                ForEach(Array(entry.righe.prefix(righeMassime).enumerated()), id: \.offset) { _, riga in
                    rigaAlimento(riga)
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.notte)
    }

    @ViewBuilder
    private func rigaAlimento(_ riga: RigaAlimento) -> some View {
        if famiglia == .systemSmall {
            // ⚑ Nel piccolo i giorni vanno sotto il nome: affiancati, il nome restava a
            //   cinque lettere ("Spezz…"), visto nell'anteprima del 2026-10-07.
            VStack(alignment: .leading, spacing: 1) {
                Text(riga.nome)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(entry.testoGiorni(riga))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(entry.vecchio(riga) ? .badge : .suNotteSpento)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            rigaLarga(riga)
        }
    }

    private func rigaLarga(_ riga: RigaAlimento) -> some View {
        HStack(spacing: 10) {
            if let immagine = Self.carica(entry.icone[riga.chiaveIcona]) {
                // Il PNG di Dart e' bianco su trasparente: lo tinge il colore ghiaccio.
                immagine
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.ghiaccio)
            }
            Text(riga.nome)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer(minLength: 6)
            Text(entry.testoGiorni(riga))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(entry.vecchio(riga) ? .badge : .suNotteSpento)
                .lineLimit(1)
                .fixedSize()
        }
    }

    static func carica(_ percorso: String?) -> Image? {
        guard let percorso else { return nil }
        #if canImport(UIKit)
        guard let immagine = UIImage(contentsOfFile: percorso) else { return nil }
        return Image(uiImage: immagine)
        #else
        guard let immagine = NSImage(contentsOfFile: percorso) else { return nil }
        return Image(nsImage: immagine)
        #endif
    }
}

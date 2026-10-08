import SwiftUI
import WidgetKit

// La parte del widget che si vede: lettura del contenitore e disegno (F5, widget).
//
// ⚑ **In un file separato da `ScorteCaloreWidget.swift` per poterla guardare sul Mac** con
// `apps/scorte_calore/tool/anteprima_widget_ios.swift`: un widget non si mette sulla
// schermata da riga di comando (lezione di TrashCan, 4 ottobre 2026). Quindi qui niente che
// esista solo su iOS.
//
// ⚑ **I giorni si calcolano qui** (ADR-018), dalla data di esaurimento di ogni fonte e dalla
// data della voce della timeline: il widget di domani dice un giorno in meno senza che l'app
// sia stata aperta. Il formato delle righe e' lo stesso di ScorteCaloreWidgetProvider.kt,
// scritto da `lib/services/scorte_widget.dart`.

enum Chiavi {
    /// Uguale a `ScorteWidget.iosGroup` e ai due `.entitlements`.
    static let gruppo = "group.com.smp.scortecalore"

    static let titolo = "title"
    static let righe = "rows"
    static let oggi = "days_today"
    static let modelloGiorni = "days_template"
    static let modelloRiordino = "reorder_template"
    static let riordinaOra = "reorder_now"
    static let servonoMisure = "need_more"
    static let vuoto = "empty"
}

/// Separatore fra i campi di una riga: US, come in Dart e in Kotlin.
let separatoreCampo: Character = "\u{1F}"

/// I testi che l'estensione deve saper dire **da sola**: se il contenitore e' vuoto, e' vuoto
/// anche qualunque testo messo li' dentro (lezione di TrashCan).
enum Ripiego {
    static var italiano: Bool { (Locale.preferredLanguages.first ?? "en").hasPrefix("it") }
    static var titolo: String { italiano ? "SCORTE" : "HEATING STOCK" }
    static var apri: String {
        italiano ? "Apri Scorte Calore per aggiungere una fonte." : "Open Scorte Calore to add a heat source."
    }
}

/// Una fonte come la scrive Dart: `nome US esaurimento US riordino US riordinoBreve`.
struct RigaFonte: Hashable {
    let nome: String
    /// `nil` se la stima non c'e' ancora (servono altre misure).
    let esaurimento: Date?
    let riordino: Date?
    /// La data di riordino gia' scritta nella lingua dell'app ("1 dic").
    let riordinoBreve: String
}

struct VoceScorte: TimelineEntry {
    let date: Date
    let titolo: String
    let righe: [RigaFonte]
    let vuoto: String
    let oggi: String
    let modelloGiorni: String
    let modelloRiordino: String
    let riordinaOra: String
    let servonoMisure: String
    /// `true` se l'app non ha mai scritto niente (o il gruppo non e' condiviso).
    let senzaDati: Bool

    /// I giorni di autonomia alla data di questa voce, non a quella di adesso.
    func giorni(_ riga: RigaFonte) -> Int? {
        guard let fine = riga.esaurimento else { return nil }
        let calendario = Calendar.current
        let da = calendario.startOfDay(for: date)
        let a = calendario.startOfDay(for: fine)
        return max(0, calendario.dateComponents([.day], from: da, to: a).day ?? 0)
    }

    func testoGiorni(_ riga: RigaFonte) -> String {
        guard let n = giorni(riga) else { return "–" }
        return n == 0 ? oggi : modelloGiorni.replacingOccurrences(of: "{n}", with: String(n))
    }

    /// La data di riordino e' arrivata (o passata) alla data di questa voce.
    func daRiordinare(_ riga: RigaFonte) -> Bool {
        guard let r = riga.riordino else { return false }
        let calendario = Calendar.current
        return calendario.startOfDay(for: date) >= calendario.startOfDay(for: r)
    }

    func dettaglio(_ riga: RigaFonte) -> String {
        if riga.esaurimento == nil { return servonoMisure }
        if daRiordinare(riga) { return riordinaOra }
        if riga.riordinoBreve.isEmpty { return "" }
        return modelloRiordino.replacingOccurrences(of: "{d}", with: riga.riordinoBreve)
    }

    func coloreGiorni(_ riga: RigaFonte) -> Color {
        if riga.esaurimento == nil { return .suNotteSpento }
        return daRiordinare(riga) ? .ambra : .brace
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

    func voce(al giorno: Date) -> VoceScorte {
        guard let testo = leggi(Chiavi.righe) else {
            return VoceScorte(
                date: giorno, titolo: Ripiego.titolo, righe: [], vuoto: Ripiego.apri, oggi: "",
                modelloGiorni: "{n}", modelloRiordino: "{d}", riordinaOra: "", servonoMisure: "", senzaDati: true
            )
        }
        let righe: [RigaFonte] = testo.split(separator: "\n").compactMap { riga in
            let campi = riga.split(separator: separatoreCampo, omittingEmptySubsequences: false)
            // Una riga piu' corta e' un formato cambiato da un'app piu' recente: meglio
            // saltarla che disegnare campi sfasati.
            guard campi.count >= 4 else { return nil }
            return RigaFonte(
                nome: String(campi[0]),
                esaurimento: Self.formatoData.date(from: String(campi[1])),
                riordino: Self.formatoData.date(from: String(campi[2])),
                riordinoBreve: String(campi[3])
            )
        }
        return VoceScorte(
            date: giorno,
            titolo: leggi(Chiavi.titolo) ?? Ripiego.titolo,
            righe: righe,
            vuoto: leggi(Chiavi.vuoto) ?? Ripiego.apri,
            oggi: leggi(Chiavi.oggi) ?? "",
            modelloGiorni: leggi(Chiavi.modelloGiorni) ?? "{n}",
            modelloRiordino: leggi(Chiavi.modelloRiordino) ?? "{d}",
            riordinaOra: leggi(Chiavi.riordinaOra) ?? "",
            servonoMisure: leggi(Chiavi.servonoMisure) ?? "",
            senzaDati: false
        )
    }
}

// MARK: - Colori (ScortePalette, testata blu notte "A · Brace")

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

    static let notte = Color(argb: 0xFF14213A)
    static let brace = Color(argb: 0xFFFF7A3D)
    static let braceChiara = Color(argb: 0xFFFF9A62)
    static let ambra = Color(argb: 0xFFFFB547)
    static let suNotteSpento = Color(argb: 0xFFC9D3E6)
}

// MARK: - Disegno

struct VistaScorte: View {
    let entry: VoceScorte
    let famiglia: WidgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.titolo)
                .font(.system(size: 11, weight: .bold))
                .kerning(1.2)
                .foregroundColor(.braceChiara)
                .lineLimit(1)
                .padding(.bottom, 6)

            if entry.righe.isEmpty {
                Spacer(minLength: 0)
                Text(entry.vuoto)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            } else if famiglia == .systemSmall, let prima = entry.righe.first {
                piccolo(prima)
            } else {
                // ⚑ Le righe si dividono l'altezza: ammassate in alto lasciavano mezzo widget
                //   vuoto, che si legge come "non ha caricato" (lezione di Full Freezer).
                ForEach(Array(entry.righe.prefix(3).enumerated()), id: \.offset) { _, riga in
                    rigaLarga(riga)
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.notte)
    }

    /// Nel piccolo una fonte sola, quella in testata nell'app: il numero grande, come la home.
    private func piccolo(_ riga: RigaFonte) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Spacer(minLength: 0)
            Text(riga.nome)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            Text(entry.testoGiorni(riga))
                .font(.system(size: 30, weight: .heavy))
                .foregroundColor(entry.coloreGiorni(riga))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(entry.dettaglio(riga))
                .font(.system(size: 12))
                .foregroundColor(.suNotteSpento)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rigaLarga(_ riga: RigaFonte) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(riga.nome)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(entry.dettaglio(riga))
                    .font(.system(size: 12))
                    .foregroundColor(.suNotteSpento)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            Text(entry.testoGiorni(riga))
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(entry.coloreGiorni(riga))
                .lineLimit(1)
                .fixedSize()
        }
    }
}

import SwiftUI
import WidgetKit

// Il widget di TrashCan per iOS.
//
// ⚑ **Questo file non calcola niente, e deve restare così.** Le righe che legge le ha
// preparate Dart in `lib/services/trashcan_widget.dart`: una riga per giorno, 3650 giorni,
// con i campi separati da caratteri di controllo. Qui si cerca la riga che porta la data
// giusta e si disegna. Nessun calendario, nessuna ricorrenza, nessuna lingua: tutto il
// testo arriva già tradotto.
//
// ☠ È lo stesso formato del provider Kotlin su Android, e **deve restare lo stesso**. Se un
// giorno i due divergono, il difetto si vedrà su una piattaforma sola e verrà cercato nel
// posto sbagliato.

private enum Chiavi {
    /// Il gruppo condiviso fra app ed estensione. Senza, qui non si legge niente.
    static let gruppo = "group.com.smp.trashcan"

    static let giorni = "days"
    static let etichettaStasera = "tonight_label"
    static let nomeCalendario = "calendar_name"
    static let elencoVuoto = "upcoming_empty"
    static let scaduto = "stale"
    static let prefissoIcona = "icon_"
}

private enum Separatori {
    /// US, "unit separator": divide i campi dentro una riga.
    static let campo: Character = "\u{1F}"
    /// RS, "record separator": divide le raccolte elencate nella fascia inferiore.
    static let riga: Character = "\u{1E}"
}

/// Lo stato di un giorno, già pronto da disegnare.
struct StatoGiorno: TimelineEntry {
    let date: Date
    let etichetta: String
    let cosaStasera: String
    let colore: Color?
    let percorsoIcona: String?
    let prossimi: [String]
    let nomeCalendario: String
}

// MARK: - Lettura

private struct Deposito {
    let difese: UserDefaults?

    init() {
        difese = UserDefaults(suiteName: Chiavi.gruppo)
    }

    func stringa(_ chiave: String) -> String? {
        difese?.string(forKey: chiave)
    }

    /// Lo stato del giorno indicato, oppure `nil` se quel giorno non è fra le righe.
    ///
    /// ⚑ **Si cerca una sottostringa, non si analizza tutto.** Le righe sono 3650 e girano
    /// dentro un'estensione, che ha un budget di tempo e di memoria stretto. Cercare
    /// `"\n2026-10-04\u{1F}"` costa quanto una ricerca di testo; interpretare l'intero
    /// decennio costerebbe quanto il decennio. È per questo che il formato è a righe e non
    /// strutturato.
    func stato(per giorno: Date) -> StatoGiorno? {
        guard let righe = stringa(Chiavi.giorni) else { return nil }

        let formato = DateFormatter()
        formato.dateFormat = "yyyy-MM-dd"
        formato.locale = Locale(identifier: "en_US_POSIX")
        formato.timeZone = TimeZone.current
        let data = formato.string(from: giorno)

        guard let inizio = righe.range(of: "\n\(data)\(Separatori.campo)") else { return nil }
        let resto = righe[inizio.upperBound...]
        let fine = resto.firstIndex(of: "\n") ?? resto.endIndex
        let campi = resto[..<fine].split(separator: Separatori.campo, omittingEmptySubsequences: false)

        // La riga ha quattro campi dopo la data. Una riga più corta significa un formato
        // cambiato da una versione dell'app più recente di questa estensione: meglio non
        // disegnare niente che disegnare i campi sfasati.
        guard campi.count >= 4 else { return nil }

        let colore = Int(campi[1]).flatMap { $0 == 0 ? nil : Color(argb: $0) }
        let chiaveIcona = String(campi[2])
        let percorso = chiaveIcona.isEmpty
            ? nil
            : stringa(Chiavi.prefissoIcona + chiaveIcona)

        let elenco = campi[3]
            .split(separator: Separatori.riga, omittingEmptySubsequences: true)
            .map(String.init)

        return StatoGiorno(
            date: giorno,
            etichetta: stringa(Chiavi.etichettaStasera) ?? "",
            cosaStasera: String(campi[0]),
            colore: colore,
            percorsoIcona: percorso,
            prossimi: elenco,
            nomeCalendario: stringa(Chiavi.nomeCalendario) ?? ""
        )
    }

    /// Cosa mostrare quando le righe sono finite o non ci sono ancora.
    func statoAssente(al giorno: Date) -> StatoGiorno {
        StatoGiorno(
            date: giorno,
            etichetta: stringa(Chiavi.etichettaStasera) ?? "",
            cosaStasera: stringa(Chiavi.scaduto) ?? "",
            colore: nil,
            percorsoIcona: nil,
            prossimi: [],
            nomeCalendario: stringa(Chiavi.nomeCalendario) ?? ""
        )
    }
}

// MARK: - Timeline

struct Fornitore: TimelineProvider {
    func placeholder(in context: Context) -> StatoGiorno {
        Deposito().statoAssente(al: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (StatoGiorno) -> Void) {
        let deposito = Deposito()
        completion(deposito.stato(per: Date()) ?? deposito.statoAssente(al: Date()))
    }

    /// ⚑ **Su iOS non servono sveglie.** Su Android il widget si aggiorna perché l'app arma
    /// un allarme per ogni mezzanotte; qui è WidgetKit a chiedere la prossima manciata di
    /// giorni e a cambiare da solo la schermata all'ora giusta. Le righe precalcolate
    /// rendono la cosa gratuita: la timeline si costruisce senza far girare Dart e senza
    /// aprire il database.
    ///
    /// ⚑ Una settimana per volta, non tutti i 3650 giorni: WidgetKit tiene in memoria le
    /// voci che gli si danno, e un decennio sarebbe uno spreco senza nessun vantaggio.
    /// Con `.atEnd` il sistema richiama questo metodo quando le finisce.
    func getTimeline(in context: Context, completion: @escaping (Timeline<StatoGiorno>) -> Void) {
        let deposito = Deposito()
        let calendario = Calendar.current
        let oggi = calendario.startOfDay(for: Date())

        var voci: [StatoGiorno] = []
        for scarto in 0..<7 {
            guard let giorno = calendario.date(byAdding: .day, value: scarto, to: oggi) else { continue }
            voci.append(deposito.stato(per: giorno) ?? deposito.statoAssente(al: giorno))
        }

        completion(Timeline(entries: voci, policy: .atEnd))
    }
}

// MARK: - Disegno

struct VistaTrashcan: View {
    var entry: StatoGiorno

    private var coloreTestata: Color {
        entry.colore ?? Color(.sRGB, red: 0.18, green: 0.49, blue: 0.36)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            testata
            elenco
        }
        .sfondoContenitore()
    }

    private var testata: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if let percorso = entry.percorsoIcona,
                   let immagine = UIImage(contentsOfFile: percorso) {
                    // ☠ `.renderingMode(.template)` e poi `.foregroundColor(.white)`: il PNG
                    // che Dart disegna è **bianco su trasparente**, ed è giusto così, ma su
                    // una testata chiara sparirebbe. Tingerlo qui lo rende indipendente dal
                    // colore del tipo di rifiuto.
                    Image(uiImage: immagine)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.white)
                }
                Text(entry.etichetta)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
            Text(entry.cosaStasera)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(coloreTestata)
    }

    private var elenco: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(entry.prossimi, id: \.self) { riga in
                Text(riga)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
}

@main
struct TrashcanWidget: Widget {
    // ☠ Questa stringa è il **nome che Dart passa a `updateWidget(iOSName:)`**. Se le due
    // divergono, l'app chiede a WidgetKit di ricaricare un widget che non esiste: niente
    // errore, niente aggiornamento, e nessun indizio su dove guardare.
    let kind = "TrashcanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Fornitore()) { entry in
            VistaTrashcan(entry: entry)
        }
        .configurationDisplayName("TrashCan")
        .description("Cosa si butta stasera.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Dettagli

private extension Color {
    /// Costruisce il colore da un intero ARGB, che è come Dart lo manda.
    init(argb: Int) {
        self.init(
            .sRGB,
            red: Double((argb >> 16) & 0xFF) / 255,
            green: Double((argb >> 8) & 0xFF) / 255,
            blue: Double(argb & 0xFF) / 255,
            opacity: Double((argb >> 24) & 0xFF) / 255
        )
    }
}

private extension View {
    /// Lo sfondo del widget, nel modo che il sistema si aspetta.
    ///
    /// ☠ Da iOS 17 un widget **deve** dichiarare il proprio sfondo con
    /// `containerBackground`, altrimenti il sistema lo disegna senza e il risultato è un
    /// riquadro trasparente sopra lo sfondo della schermata. Sotto iOS 17 quel modificatore
    /// non esiste, quindi serve il controllo di disponibilità: non è pignoleria, senza il
    /// progetto non compila con il bersaglio a iOS 15.
    @ViewBuilder
    func sfondoContenitore() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { Color(.systemBackground) }
        } else {
            background(Color(.systemBackground))
        }
    }
}

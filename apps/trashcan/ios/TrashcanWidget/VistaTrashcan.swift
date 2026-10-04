import SwiftUI
import WidgetKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// La parte del widget che si vede: lettura delle righe e disegno.
//
// ⚑ **Sta in un file separato da `TrashcanWidget.swift` per poterla guardare.** Un widget
// non si mette sulla schermata da riga di comando, quindi l'unico modo di vederlo prima di
// spedirlo è renderizzare questa vista sul Mac con `tool/anteprima_widget_ios.swift`. Per
// questo qui non c'è niente che esista solo su iOS: le due righe che toccano UIKit hanno
// il loro equivalente AppKit.
//
// ☠ **Il 4 ottobre 2026 è arrivata al proprietario una versione mai guardata**: un riquadro
// bianco con dentro una fascia verde e nessuna parola. Non c'era un errore, c'era un
// disegno che nessuno aveva visto. L'anteprima esiste perché non si ripeta.
//
// ⚑ **Questo file non calcola niente, e deve restare così.** Le righe le ha preparate Dart
// in `lib/services/trashcan_widget.dart`: una per giorno, 3650 giorni, campi separati da
// caratteri di controllo. È lo stesso formato del provider Kotlin su Android, e deve
// restare lo stesso: se i due divergono, il difetto si vede su una piattaforma sola e
// viene cercato nel posto sbagliato.

enum Chiavi {
    /// Il gruppo condiviso fra app ed estensione. Uguale a `TrashcanWidget.gruppoIos`.
    static let gruppo = "group.com.smp.trashcan"

    static let giorni = "days"
    static let etichettaStasera = "tonight_label"
    static let nomeCalendario = "calendar_name"
    static let elencoVuoto = "upcoming_empty"
    static let scaduto = "stale"
    static let prefissoIcona = "icon_"
}

enum Separatori {
    /// US, "unit separator": divide i campi dentro una riga.
    static let campo: Character = "\u{1F}"
    /// RS, "record separator": divide le raccolte elencate nella fascia inferiore.
    static let riga: Character = "\u{1E}"
    /// Fra il giorno e il nome del rifiuto in una riga dell'elenco. Lo mette Dart.
    static let giornoNome = "   "
}

/// Quello che l'estensione deve saper dire **da sola**, senza l'app.
///
/// ☠ Prima questi testi venivano letti dallo stesso contenitore dei dati. Quando il
/// contenitore era vuoto, era vuoto anche il testo che doveva spiegare perché: il widget
/// non diceva niente, ed è proprio il caso in cui deve dire qualcosa. Un testo di ripiego
/// non può dipendere dalla cosa di cui è il ripiego.
///
/// ⚑ Italiano sui dispositivi italiani, inglese altrove: la stessa regola dell'app
/// (ADR-011). Due lingue in tre righe non giustificano un catalogo di traduzioni.
enum Ripiego {
    static var italiano: Bool {
        (Locale.preferredLanguages.first ?? "en").hasPrefix("it")
    }

    static var stasera: String { italiano ? "Stasera" : "Tonight" }
    static var titolo: String { "TrashCan" }
    static var apri: String { italiano ? "Apri l'app" : "Open the app" }
    static var apriApp: String {
        italiano
            ? "Ti dirà qui ogni sera cosa portare fuori."
            : "Every evening it will tell you here what goes out."
    }
}

/// Lo stato di un giorno, già pronto da disegnare.
struct StatoGiorno: TimelineEntry {
    let date: Date
    let etichetta: String
    let cosaStasera: String
    /// Il colore del tipo di rifiuto come intero ARGB, `nil` per il verde di TrashCan.
    let argb: Int?
    let percorsoIcona: String?
    let prossimi: [String]
    let elencoVuoto: String

    /// `true` quando non c'è nessun dato: app mai aperta, o contenitore non condiviso.
    let senzaDati: Bool
}

// MARK: - Lettura

struct Deposito {
    /// Legge una chiave. Un'astrazione invece di `UserDefaults` diretto perché l'anteprima
    /// legge lo stesso contenuto da un file `.plist` copiato dal simulatore.
    let leggi: (String) -> String?

    /// Il contenitore condiviso vero, quello che l'app scrive.
    static var condiviso: Deposito {
        let difese = UserDefaults(suiteName: Chiavi.gruppo)
        return Deposito { difese?.string(forKey: $0) }
    }

    /// Lo stato del giorno indicato, oppure `nil` se quel giorno non è fra le righe.
    ///
    /// ⚑ **Si cerca una sottostringa, non si analizza tutto.** Le righe sono 3650 e girano
    /// dentro un'estensione, che ha un budget stretto di tempo e di memoria. Cercare
    /// `"\n2026-10-04\u{1F}"` costa quanto una ricerca di testo; interpretare il decennio
    /// costerebbe quanto il decennio.
    func stato(per giorno: Date) -> StatoGiorno? {
        guard let righe = leggi(Chiavi.giorni) else { return nil }

        let formato = DateFormatter()
        formato.calendar = Calendar(identifier: .gregorian)
        formato.locale = Locale(identifier: "en_US_POSIX")
        formato.timeZone = TimeZone.current
        formato.dateFormat = "yyyy-MM-dd"
        let data = formato.string(from: giorno)

        guard let inizio = righe.range(of: "\n\(data)\(Separatori.campo)") else { return nil }
        let resto = righe[inizio.upperBound...]
        let fine = resto.firstIndex(of: "\n") ?? resto.endIndex
        let campi = resto[..<fine].split(separator: Separatori.campo, omittingEmptySubsequences: false)

        // Dopo la data vengono quattro campi. Una riga più corta vuol dire un formato
        // cambiato da una versione dell'app più recente di questa estensione: meglio il
        // ripiego che i campi disegnati sfasati.
        guard campi.count >= 4 else { return nil }

        let argb = Int(campi[1]).flatMap { $0 == 0 ? nil : $0 }
        let chiaveIcona = String(campi[2])

        return StatoGiorno(
            date: giorno,
            etichetta: leggi(Chiavi.etichettaStasera) ?? Ripiego.stasera,
            cosaStasera: String(campi[0]),
            argb: argb,
            percorsoIcona: chiaveIcona.isEmpty ? nil : leggi(Chiavi.prefissoIcona + chiaveIcona),
            prossimi: campi[3]
                .split(separator: Separatori.riga, omittingEmptySubsequences: true)
                .map(String.init),
            elencoVuoto: leggi(Chiavi.elencoVuoto) ?? "",
            senzaDati: false
        )
    }

    /// Cosa mostrare quando per quel giorno non c'è una riga.
    ///
    /// Due casi diversi, e vanno distinti. Se non c'è **nessun** dato, l'app non ha mai
    /// scritto qui: si invita ad aprirla. Se i dati ci sono ma il giorno è oltre l'ultima
    /// riga, si mostra il testo di scadenza che ha preparato l'app.
    func statoAssente(al giorno: Date) -> StatoGiorno {
        let mai = leggi(Chiavi.giorni) == nil
        // ⚑ Senza dati l'etichetta è il nome dell'app e non "Stasera": sopra un invito
        //   ad aprire l'app, "Stasera" prometterebbe un'informazione che non c'è.
        return StatoGiorno(
            date: giorno,
            etichetta: mai ? Ripiego.titolo : (leggi(Chiavi.etichettaStasera) ?? Ripiego.stasera),
            cosaStasera: mai ? Ripiego.apri : (leggi(Chiavi.scaduto) ?? Ripiego.apriApp),
            argb: nil,
            percorsoIcona: nil,
            prossimi: [],
            elencoVuoto: mai ? Ripiego.apriApp : "",
            senzaDati: mai
        )
    }
}

// MARK: - Colori

extension StatoGiorno {
    /// Il verde di TrashCan: lo stesso dell'icona e della testata su Android.
    static let verdeARGB = 0xFF2E7D5B

    private var argbTestata: Int { argb ?? Self.verdeARGB }

    var coloreTestata: Color { Color(argb: argbTestata) }

    /// Bianco o scuro, quello che si legge meglio sulla testata.
    ///
    /// ☠ **Non sempre bianco.** La tavolozza ha colori chiari, come il giallo della
    /// plastica, su cui il bianco non si legge: l'app li scrive in scuro, e il test
    /// `palette_contrast_test.dart` verifica che ognuno regga 4.5:1 col testo giusto. Qui si
    /// sceglie con lo stesso criterio, il rapporto di contrasto WCAG, invece di fissare il
    /// bianco e lasciare una plastica illeggibile sulla schermata di casa.
    var coloreTesto: Color { Contrasto.testoMigliore(su: argbTestata) }
}

enum Contrasto {
    /// Bianco o quasi-nero, quello col contrasto più alto su `argb`.
    static func testoMigliore(su argb: Int) -> Color {
        let l = luminanza(argb)
        let controBianco = (1.0 + 0.05) / (l + 0.05)
        let controNero = (l + 0.05) / (0.0 + 0.05)
        return controBianco >= controNero ? .white : Color(argb: 0xFF1B1F1A)
    }

    /// Luminanza relativa secondo WCAG 2.
    static func luminanza(_ argb: Int) -> Double {
        func canale(_ v: Int) -> Double {
            let c = Double(v) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * canale((argb >> 16) & 0xFF)
            + 0.7152 * canale((argb >> 8) & 0xFF)
            + 0.0722 * canale(argb & 0xFF)
    }
}

extension Color {
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

    /// Il fondo chiaro o scuro del sistema, sotto la testata.
    static var fondoSistema: Color {
        #if canImport(UIKit)
        Color(UIColor.systemBackground)
        #else
        Color(NSColor.windowBackgroundColor)
        #endif
    }
}

// MARK: - Disegno

struct VistaTrashcan: View {
    let entry: StatoGiorno
    let famiglia: WidgetFamily

    /// Quante raccolte si elencano: le stesse tre di Android (`giorniElencati`).
    private let righeMassime = 3

    var body: some View {
        Group {
            if famiglia == .systemMedium {
                // ⚑ Nel medio la testata diventa una colonna a tutta altezza e l'elenco le
                //   sta accanto. Impilati come nel piccolo, metà del riquadro restava un
                //   vuoto bianco in basso a destra: l'anteprima l'ha mostrato subito.
                HStack(spacing: 0) {
                    testata
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                        .background(entry.coloreTestata)
                        .frame(width: 150)
                    elenco
                        .padding(.top, 4)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    testata
                    elenco
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.fondoSistema)
    }

    // ☠ La testata arriva ai bordi del widget, sopra e ai lati. Quando stava dentro i
    //   margini di sistema, il risultato era una fascia colorata che galleggiava in un
    //   riquadro bianco: "un quadrato con dentro un rettangolo colorato", che è come il
    //   proprietario l'ha descritta. I margini li toglie `contentMarginsDisabled` in
    //   `TrashcanWidget.swift`, e il respiro lo danno i padding qui sotto.
    private var testata: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                icona
                Text(entry.etichetta.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(0.6)
                    .lineLimit(1)
            }
            .opacity(0.85)

            Text(entry.cosaStasera)
                .font(.system(size: 18, weight: .bold))
                .lineLimit(famiglia == .systemMedium ? 4 : 2)
                .minimumScaleFactor(0.65)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(entry.coloreTesto)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.top, 13)
        .padding(.bottom, 11)
        .background(entry.coloreTestata)
    }

    @ViewBuilder
    private var icona: some View {
        if let immagine = Self.carica(entry.percorsoIcona) {
            // Il PNG di Dart è bianco su trasparente: lo si tinge col colore del testo,
            // così resta leggibile anche sulle testate chiare.
            immagine
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 13, height: 13)
        } else if entry.senzaDati {
            Image(systemName: "trash.fill")
                .font(.system(size: 10, weight: .semibold))
        }
    }

    private var elenco: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.prossimi.isEmpty {
                Text(entry.elencoVuoto)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            } else {
                ForEach(Array(entry.prossimi.prefix(righeMassime).enumerated()), id: \.offset) { _, riga in
                    rigaElenco(riga)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.top, 9)
        .padding(.bottom, 10)
    }

    /// Una raccolta: il giorno in colonna, poi il nome.
    ///
    /// ⚑ Dart scrive "dom 20   Carta", con tre spazi in mezzo. Si separa lì per mettere i
    /// giorni in colonna: allineati si leggono come un calendario, a bandiera come una
    /// frase. Se la separazione non riesce si mostra la riga intera.
    @ViewBuilder
    private func rigaElenco(_ riga: String) -> some View {
        if let taglio = riga.range(of: Separatori.giornoNome) {
            HStack(spacing: 6) {
                Text(String(riga[..<taglio.lowerBound]))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 42, alignment: .leading)
                Text(String(riga[taglio.upperBound...]).trimmingCharacters(in: .whitespaces))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        } else {
            Text(riga)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
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

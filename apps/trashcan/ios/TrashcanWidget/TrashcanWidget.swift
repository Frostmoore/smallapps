import SwiftUI
import WidgetKit

// Il widget di TrashCan per iOS: configurazione e timeline.
//
// La lettura delle righe e il disegno stanno in `VistaTrashcan.swift`, separati apposta
// per poterli renderizzare sul Mac prima di spedirli. Vedi l'intestazione di quel file.

struct Fornitore: TimelineProvider {
    func placeholder(in context: Context) -> StatoGiorno {
        Deposito.condiviso.statoAssente(al: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (StatoGiorno) -> Void) {
        let deposito = Deposito.condiviso
        completion(deposito.stato(per: Date()) ?? deposito.statoAssente(al: Date()))
    }

    /// ⚑ **Su iOS non servono sveglie.** Su Android il widget si aggiorna perché l'app arma
    /// un allarme per ogni mezzanotte; qui è WidgetKit a chiedere la prossima manciata di
    /// giorni e a cambiare da solo la schermata all'ora giusta. Le righe precalcolate
    /// rendono la cosa gratuita: la timeline si costruisce senza far girare Dart.
    ///
    /// ⚑ Una settimana per volta, non tutti i 3650 giorni: WidgetKit tiene in memoria le
    /// voci che gli si danno, e un decennio sarebbe uno spreco senza vantaggi. Con `.atEnd`
    /// il sistema richiama questo metodo quando le ha consumate.
    func getTimeline(in context: Context, completion: @escaping (Timeline<StatoGiorno>) -> Void) {
        let deposito = Deposito.condiviso
        let calendario = Calendar.current
        let oggi = calendario.startOfDay(for: Date())

        let voci: [StatoGiorno] = (0..<7).compactMap { scarto in
            guard let giorno = calendario.date(byAdding: .day, value: scarto, to: oggi) else {
                return nil
            }
            return deposito.stato(per: giorno) ?? deposito.statoAssente(al: giorno)
        }

        completion(Timeline(entries: voci, policy: .atEnd))
    }
}

/// Passa alla vista la famiglia del widget, che si legge solo dall'ambiente.
///
/// ⚑ La vista la riceve come parametro invece di leggerla da sola perché l'anteprima sul
/// Mac deve poterla impostare, e `widgetFamily` nell'ambiente è di sola lettura.
struct VistaConFamiglia: View {
    @Environment(\.widgetFamily) private var famiglia
    let entry: StatoGiorno

    var body: some View {
        VistaTrashcan(entry: entry, famiglia: famiglia)
            .sfondoWidget()
    }
}

@main
struct TrashcanWidget: Widget {
    // ☠ Questa stringa è il **nome che Dart passa a `updateWidget(iOSName:)`**, cioè
    // `TrashcanWidget.nomeIos`. Se le due divergono, l'app chiede a WidgetKit di ricaricare
    // un widget che non esiste: niente errore, niente aggiornamento.
    let kind = "TrashcanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Fornitore()) { entry in
            VistaConFamiglia(entry: entry)
        }
        .configurationDisplayName("TrashCan")
        .description(Ripiego.italiano ? "Cosa si butta stasera." : "What goes out tonight.")
        .supportedFamilies([.systemSmall, .systemMedium])
        // ☠ Senza, da iOS 17 il sistema aggiunge un margine attorno al contenuto e la
        //   testata colorata resta staccata dai bordi, dentro un riquadro bianco. È il
        //   difetto che il proprietario ha visto sul suo iPad.
        .contentMarginsDisabled()
    }
}

private extension View {
    /// Lo sfondo del widget, nel modo che il sistema si aspetta.
    ///
    /// ☠ Da iOS 17 un widget **deve** dichiarare il proprio sfondo con
    /// `containerBackground`, altrimenti il sistema lo considera senza sfondo e lo disegna
    /// con un avviso. Sotto iOS 17 quel modificatore non esiste: senza il controllo di
    /// disponibilità il progetto non compila col bersaglio a iOS 15.
    @ViewBuilder
    func sfondoWidget() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { Color.fondoSistema }
        } else {
            self
        }
    }
}

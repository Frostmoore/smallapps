import SwiftUI
import WidgetKit

// Il widget di Full Freezer per iOS: configurazione e timeline (F4.11).
// Lettura e disegno stanno in `VistaFreezer.swift`, per poterli guardare sul Mac.

struct Fornitore: TimelineProvider {
    func placeholder(in context: Context) -> VoceFreezer {
        Deposito.condiviso.voce(al: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (VoceFreezer) -> Void) {
        completion(Deposito.condiviso.voce(al: Date()))
    }

    /// ⚑ **Una voce per ciascuno dei prossimi sette giorni, a mezzanotte.** Su Android il
    /// ridisegno lo sveglia un allarme alle 00:05; qui e' WidgetKit a passare da una voce
    /// all'altra all'ora giusta, e ogni voce calcola i giorni rispetto alla **propria** data.
    /// Niente sveglie, niente Dart. Con `.atEnd` il sistema richiede la timeline quando le
    /// voci finiscono; l'app la fa ricaricare a ogni modifica (`updateWidget`).
    func getTimeline(in context: Context, completion: @escaping (Timeline<VoceFreezer>) -> Void) {
        let deposito = Deposito.condiviso
        let calendario = Calendar.current
        let adesso = Date()
        let oggi = calendario.startOfDay(for: adesso)
        var voci = [deposito.voce(al: adesso)]
        for scarto in 1..<8 {
            if let giorno = calendario.date(byAdding: .day, value: scarto, to: oggi) {
                voci.append(deposito.voce(al: giorno))
            }
        }
        completion(Timeline(entries: voci, policy: .atEnd))
    }
}

/// Passa alla vista la famiglia, che si legge solo dall'ambiente (l'anteprima la imposta).
struct VistaConFamiglia: View {
    @Environment(\.widgetFamily) private var famiglia
    let entry: VoceFreezer

    var body: some View {
        VistaFreezer(entry: entry, famiglia: famiglia)
            // ☠ Il parametro `homeWidget` e' quello che il plugin cerca per riconoscere un
            //   tocco sul widget (HomeWidgetPlugin.isWidgetUrl): senza, l'URL arriva all'app
            //   e nessuno lo inoltra a Dart. Il percorso e' `Routes.useSoon`.
            .widgetURL(URL(string: "fullfreezer:///use-soon?homeWidget"))
            .sfondoWidget()
    }
}

@main
struct FullFreezerWidget: Widget {
    // ☠ Il nome che Dart passa a `updateWidget(iOSName:)`, cioe' `FreezerWidget.iosName`.
    let kind = "FullFreezerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Fornitore()) { entry in
            VistaConFamiglia(entry: entry)
        }
        .configurationDisplayName("Full Freezer")
        .description(
            Ripiego.italiano
                ? "Le cose più vecchie del freezer."
                : "The oldest things in your freezer."
        )
        .supportedFamilies([.systemSmall, .systemMedium])
        // ☠ Senza, da iOS 17 il sistema aggiunge un margine e il fondo blu resta staccato
        //   dai bordi dentro un riquadro bianco (lezione di TrashCan).
        .contentMarginsDisabled()
    }
}

private extension View {
    /// ☠ Da iOS 17 lo sfondo va dichiarato con `containerBackground`; sotto non esiste.
    @ViewBuilder
    func sfondoWidget() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { Color.notte }
        } else {
            self
        }
    }
}

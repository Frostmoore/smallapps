import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/sr_palette.dart';

/// I pezzi grafici comuni di «C · Una mano» (develop_microapps.md F12.1.12): testata con il
/// bottone indietro bordato, card dei numeri, barra del budget, etichette.
///
/// ⚑ In un file solo e non sparsi nelle pagine: la tavola li ripete identici (confronto,
/// chiusura, statistiche), e una misura cambiata deve cambiare dappertutto.

/// La pagina secondaria di «C · Una mano»: testata (indietro 44×44 bordato, titolo 18/800, azioni a
/// destra), corpo, e in fondo i bottoni (fuori dallo scorrimento, raggiungibili col pollice).
class PaginaUnaMano extends StatelessWidget {
  const PaginaUnaMano({
    required this.titolo,
    required this.corpo,
    this.azioni = const [],
    this.fondo,
    this.indietro = true,
    super.key,
  });

  final String titolo;
  final Widget corpo;
  final List<Widget> azioni;

  /// I bottoni in fondo (Chiudi la spesa, Salva…).
  final Widget? fondo;

  /// Mostra il bottone indietro (se la pila lo permette).
  final bool indietro;

  @override
  Widget build(BuildContext context) {
    final p = SrPalette.of(context);
    final f = fondo;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
              child: Row(
                children: [
                  if (indietro && (ModalRoute.of(context)?.canPop ?? false)) ...[
                    BottoneIndietro(onTap: () => context.canPop() ? context.pop() : Navigator.of(context).maybePop()),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(titolo, style: stileTitolo(p), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  ...azioni,
                ],
              ),
            ),
            Expanded(child: corpo),
            if (f != null) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: f),
          ],
        ),
      ),
    );
  }
}

/// Lo stile dei titoli della tavola: 18, 800.
TextStyle stileTitolo(SrPalette p) => TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w800,
  fontVariations: const [FontVariation('wght', 800)],
  color: p.testo,
);

/// Le etichette piccole (13, 700, testo secondario): «9 articoli · budget 60 €», «Scontrino».
TextStyle stileEtichetta(SrPalette p, {Color? colore}) => TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  fontVariations: const [FontVariation('wght', 700)],
  color: colore ?? p.testoSecondario,
);

/// Il bottone indietro della tavola: 44×44, bordo `bordo`, raggio 14.
class BottoneIndietro extends StatelessWidget {
  const BottoneIndietro({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = SrPalette.of(context);
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: p.bordo)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(Icons.arrow_back, color: p.testo, size: 22)),
        ),
      ),
    );
  }
}

/// Una card con un'etichetta e un numero grande (Space Grotesk): «Scontrino 45,35».
class CardNumero extends StatelessWidget {
  const CardNumero({required this.etichetta, required this.valore, this.colore, this.dimensione = 28, super.key});

  final String etichetta;
  final String valore;
  final Color? colore;
  final double dimensione;

  @override
  Widget build(BuildContext context) {
    final p = SrPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.superficie, borderRadius: BorderRadius.circular(18)),
      child: Semantics(
        label: '$etichetta $valore',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(etichetta, style: stileEtichetta(p)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valore, style: p.numeri(size: dimensione, color: colore)),
            ),
          ],
        ),
      ),
    );
  }
}

/// La barra del budget: alta 6, raggio 3, traccia `superficieOp`, riempimento del colore del
/// livello (F12.1.12 punto 3). [frazione] oltre 1 = piena.
class BarraBudget extends StatelessWidget {
  const BarraBudget({required this.frazione, required this.colore, super.key});

  final double frazione;
  final Color colore;

  @override
  Widget build(BuildContext context) {
    final p = SrPalette.of(context);
    final f = frazione.isNaN ? 0.0 : frazione.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: p.superficieOp),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: f,
              child: ColoredBox(key: const ValueKey('barra_riempimento'), color: colore),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il riquadro ambra della tavola («Differenza da guardare», «Controlla il prezzo»).
class AvvisoAmbra extends StatelessWidget {
  const AvvisoAmbra({required this.testo, this.icona = Icons.info_outline, super.key});

  final String testo;
  final IconData icona;

  @override
  Widget build(BuildContext context) {
    final p = SrPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.ambraFondo,
        border: Border.all(color: p.ambraBordo),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icona, color: p.ambraTesto, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              testo,
              style: TextStyle(
                color: p.ambraTesto,
                fontWeight: FontWeight.w700,
                fontVariations: const [FontVariation('wght', 700)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Il bottone secondario della tavola: alto 48, trasparente con bordo («Rifotografa lo scontrino»).
class BottoneSecondario extends StatelessWidget {
  const BottoneSecondario({required this.etichetta, required this.onPressed, this.icona, super.key});

  final String etichetta;
  final VoidCallback? onPressed;
  final IconData? icona;

  @override
  Widget build(BuildContext context) {
    final p = SrPalette.of(context);
    final stile = OutlinedButton.styleFrom(
      minimumSize: const Size(64, 48),
      backgroundColor: Colors.transparent,
      foregroundColor: p.testo,
      side: BorderSide(color: p.bordo),
    );
    final i = icona;
    return i == null
        ? OutlinedButton(style: stile, onPressed: onPressed, child: Text(etichetta))
        : OutlinedButton.icon(style: stile, onPressed: onPressed, icon: Icon(i), label: Text(etichetta));
  }
}

/// La maniglia e il titolo di un foglio dal basso, con lo stesso passo in tutti i fogli.
class TitoloFoglio extends StatelessWidget {
  const TitoloFoglio(this.testo, {super.key});

  final String testo;

  @override
  Widget build(BuildContext context) {
    final p = SrPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(header: true, child: Text(testo, style: stileTitolo(p))),
    );
  }
}

/// Apre un foglio dal basso di «C · Una mano»: scorrevole (la tastiera non lo copre), con la
/// maniglia, sopra la superficie.
Future<T?> mostraFoglio<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: builder(ctx),
    ),
  ),
);

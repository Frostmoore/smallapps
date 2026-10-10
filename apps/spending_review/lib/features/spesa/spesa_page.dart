import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/sr_palette.dart';
import '../../domain/quantita.dart';
import '../../domain/riga_spesa.dart';
import '../../domain/spesa.dart';
import '../../domain/tastierino.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/una_mano.dart';
import 'azioni_spesa.dart';
import 'budget_sheet.dart';
import 'riga_sheet.dart';
import 'tastierino_widget.dart';

/// LA schermata (develop_microapps.md F12.1.12, `/`): tutto in una colonna senza scorrimento della
/// pagina, solo la lista scorre. Dall'alto: barra discreta (Storico, Chiudi la spesa,
/// Impostazioni), riga di stato, **totale enorme**, barra del budget, lista (piu' recente in alto),
/// **Cartellino** e **Scontrino**, **tastierino sempre visibile**.
///
/// ⚑ Il gesto principale e' «batti il prezzo → il totale sale subito»: il tastierino non e' mai
/// dietro un tocco, e il totale non si colora (resta `testo`, massimo contrasto): il colore lo
/// portano la barra e il residuo.
/// ⚑ Al 130% di testo la pagina sta in 390×844 senza tagliare il tastierino: si riduce prima la
/// lista (e' l'unica parte elastica), poi il totale (64 → 48 sotto i 700 dp di altezza), **mai** i
/// tasti (altezza fissa, `GrigliaTasti`). Il totale non segue la scala del testo: a 64 e' gia'
/// enorme, e a 83 spingerebbe fuori il tastierino.
class SpesaPage extends ConsumerStatefulWidget {
  const SpesaPage({super.key});

  /// Sotto quest'altezza (dp) il totale passa da 64 a 48.
  static const double altezzaCompatta = 700;

  /// Dopo quante ore una spesa aperta fa comparire «Spesa iniziata ieri alle 18:32».
  static const Duration spesaVecchia = Duration(hours: 12);

  @override
  ConsumerState<SpesaPage> createState() => _SpesaPageState();
}

class _SpesaPageState extends ConsumerState<SpesaPage> {
  /// Le righe gia' scorse via ma non ancora sparite dallo stream: ☠ un `Dismissible` scorso deve
  /// uscire dall'albero subito, prima che il database risponda, o Flutter si ferma con «A dismissed
  /// Dismissible widget is still part of the tree».
  final Set<int> _scorse = {};

  /// Per ogni spesa, le soglie del budget gia' segnalate con la vibrazione (una per soglia).
  final Map<int, Set<LivelloBudget>> _soglie = {};

  /// «Continua» toccato sul banner della spesa vecchia (per la spesa con quell'id).
  int? _bannerChiusoPer;

  AzioniSpesa get _azioni => AzioniSpesa(ref);

  Future<void> _tasto(TastoTastierino t) async {
    final effetto = ref.read(tastierinoProvider.notifier).premi(t);
    final aptica = ref.read(apticaProvider);
    switch (effetto) {
      case NessunEffetto(rifiutato: true):
        aptica.rifiuto();
      case NessunEffetto():
        aptica.tasto();
      case AggiungiRiga(:final prezzo, :final pezzi):
        await _azioni.aggiungi(
          RigaSpesa(nome: '', quantita: Pezzi(pezzi), prezzoUnitario: prezzo, origine: OrigineRiga.tastierino),
        );
      case IncrementaUltima():
        final ok = await ref.read(spesaRepositoryProvider).incrementaUltima();
        ok ? aptica.aggiunto() : aptica.rifiuto();
    }
  }

  /// Una vibrazione media al passaggio dell'80% e del 100%, una volta per soglia e per spesa.
  void _controllaSoglie(Spesa? prima, Spesa? dopo) {
    final id = dopo?.id;
    if (dopo == null || id == null) return;
    final livello = dopo.livelloBudget;
    if (livello != LivelloBudget.vicino && livello != LivelloBudget.sforato) return;
    if (prima?.id != id || prima!.livelloBudget.index >= livello.index) return;
    final viste = _soglie.putIfAbsent(id, () => {});
    if (viste.add(livello)) ref.read(apticaProvider).soglia();
  }

  Future<void> _apriBudget(Spesa? spesa) async {
    final l = L.of(context);
    final scelta = await BudgetSheet.show(
      context,
      titolo: l.budget_titoloSpesa,
      attuale: spesa?.budget,
      chiediAbituale: true,
    );
    if (scelta == null) return;
    await ref.read(spesaRepositoryProvider).impostaBudget(scelta.budget);
    if (scelta.abituale) await ref.read(budgetPredefinitoProvider.notifier).set(scelta.budget);
  }

  Future<void> _apriRiga(RigaSpesa riga) async {
    final esito = await RigaSheet.show(context, riga);
    if (!mounted) return;
    switch (esito) {
      case RigaSalvata(:final riga):
        await ref.read(spesaRepositoryProvider).aggiornaRiga(riga);
      case RigaEliminata():
        await _elimina(riga);
      case null:
        break;
    }
  }

  /// Elimina con «Annulla» (5 s): la riga torna con il suo id e la sua posizione.
  Future<void> _elimina(RigaSpesa riga) async {
    final id = riga.id;
    if (id == null) return;
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(spesaRepositoryProvider);
    setState(() => _scorse.add(id));
    final posizione = await repo.posizioneDi(id) ?? 0;
    await repo.eliminaRiga(id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.spesa_eliminato),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: l.common_undo,
            onPressed: () => unawaited(repo.ripristinaRiga(riga, posizione: posizione)),
          ),
        ),
      );
  }

  /// ⚑ Comprato il Pro dal paywall aperto qui, lo Scontrino si apre subito: chi ha toccato
  /// «Scontrino» alla cassa voleva quello, non tornare alla spesa e ritoccare.
  Future<void> _scontrino() async {
    if (ref.read(featureGateProvider).allows(FeatureKey.documentScan) ||
        await showSrPaywall(context, ref, highlight: FeatureKey.documentScan)) {
      if (mounted) unawaited(context.push(Routes.scontrino));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(spesaInCorsoProvider, (prima, dopo) => _controllaSoglie(prima?.value, dopo.value));
    final l = L.of(context);
    final p = SrPalette.of(context);
    final spesa = ref.watch(spesaInCorsoProvider).value;
    // Le righe scorse che lo stream ha gia' tolto non servono piu'.
    _scorse.removeWhere((id) => !(spesa?.righe.any((r) => r.id == id) ?? false));
    final righe = [
      for (final r in (spesa?.righe ?? const <RigaSpesa>[]).reversed)
        if (!_scorse.contains(r.id)) r,
    ];
    final tastierino = ref.watch(tastierinoProvider);
    final pro = ref.watch(featureGateProvider).allows(FeatureKey.documentScan);
    final adesso = ref.watch(oraProvider)();
    final vecchia = spesa != null &&
        spesa.righe.isNotEmpty &&
        _bannerChiusoPer != spesa.id &&
        adesso.difference(spesa.iniziataIl.toLocal()) > SpesaPage.spesaVecchia;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, vincoli) {
            final compatta = vincoli.maxHeight < SpesaPage.altezzaCompatta;
            final budget = spesa?.budget;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BarraAlta(
                    chiudiAttivo: spesa != null && spesa.righe.isNotEmpty,
                    onChiudi: () => unawaited(context.push(Routes.chiudi, extra: const ChiusuraArgs())),
                  ),
                  if (vecchia)
                    _BannerSpesaVecchia(
                      iniziata: spesa.iniziataIl.toLocal(),
                      adesso: adesso,
                      onChiudi: () => unawaited(context.push(Routes.chiudi, extra: const ChiusuraArgs())),
                      onContinua: () => setState(() => _bannerChiusoPer = spesa.id),
                    ),
                  _RigaStato(spesa: spesa, onBudget: () => unawaited(_apriBudget(spesa))),
                  _Totale(spesa: spesa, dimensione: compatta ? 48 : 64),
                  const SizedBox(height: 10),
                  if (spesa != null && budget != null) ...[
                    BarraBudget(
                      frazione: spesa.totale.cents / budget.cents,
                      colore: p.coloreBudget(spesa.livelloBudget) ?? p.accento,
                    ),
                    const SizedBox(height: 6),
                  ],
                  Expanded(
                    child: righe.isEmpty
                        ? Center(
                            child: Text(
                              l.spesa_vuota,
                              key: const ValueKey('spesa_vuota'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: p.testoSecondario, fontSize: 15),
                            ),
                          )
                        : ListView.separated(
                            key: const ValueKey('spesa_lista'),
                            padding: EdgeInsets.zero,
                            itemCount: righe.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: p.superficieOp),
                            itemBuilder: (_, i) {
                              final r = righe[i];
                              return Dismissible(
                                key: ValueKey('riga_${r.id}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: p.rosso.withValues(alpha: 0.25),
                                  child: Icon(Icons.delete_outline, color: p.rosso),
                                ),
                                onDismissed: (_) => unawaited(_elimina(r)),
                                child: _RigaLista(riga: r, onTap: () => unawaited(_apriRiga(r))),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey('spesa_cartellino'),
                          onPressed: () => unawaited(flussoCartellino(context, ref)),
                          icon: const Icon(Icons.sell_outlined),
                          label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.spesa_cartellino)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('spesa_scontrino'),
                          style: OutlinedButton.styleFrom(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontVariations: [FontVariation('wght', 800)],
                            ),
                          ),
                          onPressed: () => unawaited(_scontrino()),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 20),
                              const SizedBox(width: 8),
                              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(l.spesa_scontrino))),
                              if (!pro) ...[const SizedBox(width: 6), const ProBadge(compact: true)],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PannelloTastierino(
                    etichetta: l.spesa_prezzoAMano,
                    display: tastierino.display,
                    tasti: tastiDellaSpesa(
                      l,
                      onTasto: (t) => unawaited(_tasto(t)),
                      onSvuota: () {
                        ref.read(tastierinoProvider.notifier).svuota();
                        ref.read(apticaProvider).tasto();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// La barra in alto, discreta: il nome dell'app **solo** come titolo accessibile; a destra
/// Storico, Chiudi la spesa (attiva con almeno una riga), Impostazioni.
/// ⚑ In alto, lontane dal pollice: sono azioni rare, e una chiusura per sbaglio costa una spesa.
class _BarraAlta extends StatelessWidget {
  const _BarraAlta({required this.chiudiAttivo, required this.onChiudi});

  final bool chiudiAttivo;
  final VoidCallback onChiudi;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Semantics(header: true, label: l.appTitle, child: const SizedBox(width: 1, height: 1)),
          const Spacer(),
          IconButton(
            key: const ValueKey('spesa_storico'),
            tooltip: l.storico_title,
            color: p.testoSecondario,
            onPressed: () => unawaited(context.push(Routes.storico)),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            key: const ValueKey('spesa_chiudi'),
            tooltip: l.chiusura_titolo,
            color: p.testoSecondario,
            onPressed: chiudiAttivo ? onChiudi : null,
            icon: const Icon(Icons.task_alt),
          ),
          IconButton(
            key: const ValueKey('spesa_impostazioni'),
            tooltip: l.impostazioni_title,
            color: p.testoSecondario,
            onPressed: () => unawaited(context.push(Routes.impostazioni)),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}

/// «9 articoli · budget 60 €» a sinistra (tocco → budget), il residuo a destra.
class _RigaStato extends StatelessWidget {
  const _RigaStato({required this.spesa, required this.onBudget});

  final Spesa? spesa;
  final VoidCallback onBudget;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final s = spesa;
    final articoli = s?.articoli ?? 0;
    final budget = s?.budget;
    final sinistra = budget == null
        ? l.spesa_statoSenzaBudget(articoli)
        : l.spesa_statoConBudget(articoli, importoTondo(budget));
    final residuo = s?.residuoBudget;
    final livello = s?.livelloBudget ?? LivelloBudget.nessuno;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            key: const ValueKey('spesa_stato'),
            onTap: onBudget,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(sinistra, style: stileEtichetta(p), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        if (residuo != null)
          Text(
            // ⚑ «−16,30» = quanto manca (sotto budget), «+3,20» = di quanto si e' sforato.
            importoConSegno(Money.zero - residuo),
            key: const ValueKey('spesa_residuo'),
            style: stileEtichetta(p, colore: p.coloreBudget(livello) ?? p.accento),
          ),
      ],
    );
  }
}

/// Il totale enorme: «43,70» e «€». Annunciato a ogni cambio (`liveRegion`).
class _Totale extends StatelessWidget {
  const _Totale({required this.spesa, required this.dimensione});

  final Spesa? spesa;
  final double dimensione;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final totale = spesa?.totale ?? Money.zero;
    final residuo = spesa?.residuoBudget;
    String euroECent(Money m) => l.semantica_euro(m.cents.abs() ~/ 100, m.cents.abs() % 100);
    final semantica = residuo == null
        ? l.semantica_totale(euroECent(totale))
        : residuo.isNegative
            ? l.semantica_totaleSforato(euroECent(totale), euroECent(residuo))
            : l.semantica_totaleResiduo(euroECent(totale), euroECent(residuo));
    return Semantics(
      liveRegion: true,
      label: semantica,
      excludeSemantics: true,
      child: MediaQuery.withNoTextScaling(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                importo(totale),
                key: const ValueKey('spesa_totale'),
                style: p.numeri(size: dimensione, letterSpacing: -dimensione * 0.03),
              ),
              const SizedBox(width: 6),
              Text('€', style: p.numeri(size: dimensione * 30 / 64, color: p.testoSecondario)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una riga della lista: nome (con sotto «3 × 2,49», «0,258 kg × 29,90 €/kg», «3x2») e totale.
class _RigaLista extends StatelessWidget {
  const _RigaLista({required this.riga, required this.onTap});

  final RigaSpesa riga;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final dettaglio = dettaglioRiga(riga);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nomeRiga(l, riga),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.testoLista, fontSize: 15),
                    ),
                    if (dettaglio != null)
                      Text(
                        dettaglio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.testoSecondario, fontSize: 12),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(importo(riga.totale), style: p.numeri(size: 17, color: riga.eSconto ? p.accento : p.testo)),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Spesa iniziata ieri alle 18:32» con **Chiudila** e **Continua** (spesa aperta da piu' di 12 ore).
class _BannerSpesaVecchia extends StatelessWidget {
  const _BannerSpesaVecchia({
    required this.iniziata,
    required this.adesso,
    required this.onChiudi,
    required this.onContinua,
  });

  final DateTime iniziata;
  final DateTime adesso;
  final VoidCallback onChiudi;
  final VoidCallback onContinua;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final ora = DateFormat.Hm(locale).format(iniziata);
    final giorno = CivilDate.fromDateTime(iniziata);
    final oggi = CivilDate.fromDateTime(adesso);
    final testo = giorno.addDays(1) == oggi
        ? l.spesa_iniziataIeri(ora)
        : l.spesa_iniziataIl(DateFormat.MMMd(locale).format(iniziata), ora);
    return Container(
      key: const ValueKey('spesa_banner'),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: p.ambraFondo,
        border: Border.all(color: p.ambraBordo),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: Text(testo, style: TextStyle(color: p.ambraTesto, fontWeight: FontWeight.w700))),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: p.ambraTesto),
            onPressed: onChiudi,
            child: Text(l.spesa_chiudila),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: p.ambraTesto),
            onPressed: onContinua,
            child: Text(l.spesa_continua),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../app/sr_palette.dart';
import '../../data/database.dart' show Negozio;
import '../../domain/riga_spesa.dart';
import '../../domain/spesa.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/scelte.dart';
import '../common/una_mano.dart';

/// Una spesa per id, riletta a ogni modifica (negozio, data). ⚑ `autoDispose`: aperta una
/// pagina, chiusa la pagina; nessuna spesa resta in memoria.
final spesaPerIdProvider = FutureProvider.autoDispose.family<Spesa?, int>(
  (ref, id) => ref.watch(spesaRepositoryProvider).perId(id),
);

/// Il dettaglio di una spesa chiusa (develop_microapps.md F12.1.12, `/storico/:id`): le righe
/// dell'insieme che fa fede, «Mostra anche le righe contate/dello scontrino» se ci sono entrambe,
/// totale, budget, negozio e data **modificabili**, **Elimina** con conferma.
///
/// ☠ **Una spesa nascosta (oltre le 5 del gratis) non si apre senza il Pro**: al suo posto il
/// lucchetto col paywall (`fullHistory`). Un link diretto, un id battuto a mano, una pagina scritta
/// domani: la regola la applica la pagina, non la porta (lezione del ProGate di Full Freezer).
class DettaglioSpesaPage extends ConsumerStatefulWidget {
  const DettaglioSpesaPage({required this.id, super.key});

  final int id;

  @override
  ConsumerState<DettaglioSpesaPage> createState() => _DettaglioSpesaPageState();
}

class _DettaglioSpesaPageState extends ConsumerState<DettaglioSpesaPage> {
  bool _altre = false;

  Future<void> _modifica(Spesa s, {String? negozio, CivilDate? data, bool togliNegozio = false}) async {
    final repo = ref.read(spesaRepositoryProvider);
    final nome = negozio?.trim();
    final negozioId = togliNegozio
        ? null
        : (nome != null && nome.isNotEmpty ? await repo.negozioPerNome(nome) : s.negozioId);
    await repo.modificaChiusa(widget.id, data: data ?? s.dataSpesa!, negozioId: negozioId);
    ref.invalidate(spesaPerIdProvider(widget.id));
  }

  Future<void> _elimina() async {
    final l = L.of(context);
    final ok = await MicroConfirmSheet.show(
      context,
      title: l.dettaglio_eliminaTitolo,
      message: l.dettaglio_eliminaTesto,
      confirmLabel: l.common_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!ok) return;
    await ref.read(spesaRepositoryProvider).eliminaSpesa(widget.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final gate = ref.watch(featureGateProvider);
    final visibili = ref.watch(speseChiuseProvider);
    // ⚑ Nel gratis si apre solo una spesa fra quelle visibili; finche' la lista non e' arrivata
    // non si decide (niente lucchetto lampeggiante).
    if (!gate.isPro) {
      final lista = visibili.value;
      if (lista == null) return const Scaffold(body: SizedBox.shrink());
      if (!lista.any((s) => s.id == widget.id)) {
        return PaginaUnaMano(
          titolo: l.dettaglio_titolo,
          corpo: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: p.testoSecondario),
                  const SizedBox(height: 12),
                  Text(l.dettaglio_nascosta, key: const ValueKey('dettaglio_nascosta'), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => unawaited(showSrPaywall(context, ref, highlight: FeatureKey.fullHistory)),
                    child: Text(l.paywall_buy),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    final spesa = ref.watch(spesaPerIdProvider(widget.id));
    final s = spesa.value;
    if (spesa.isLoading && s == null) return const Scaffold(body: SizedBox.shrink());
    if (s == null || s.stato != StatoSpesa.chiusa) {
      return PaginaUnaMano(titolo: l.dettaglio_titolo, corpo: Center(child: Text(l.common_notFound)));
    }
    final negozi = {for (final Negozio n in ref.watch(negoziProvider).value ?? const []) n.id: n.nome};
    final negozio = s.negozioId == null ? null : negozi[s.negozioId];
    final principali = s.fonte == FonteRighe.scontrino ? s.righeScontrino : s.righe;
    final altre = s.fonte == FonteRighe.scontrino ? s.righe : s.righeScontrino;
    final residuo = s.residuoBudget;
    return PaginaUnaMano(
      titolo: l.dettaglio_titolo,
      azioni: [
        IconButton(
          key: const ValueKey('dettaglio_elimina'),
          tooltip: l.common_delete,
          onPressed: () => unawaited(_elimina()),
          icon: Icon(Icons.delete_outline, color: p.rosso),
        ),
      ],
      corpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(importo(s.totale), key: const ValueKey('dettaglio_totale'), style: p.numeri(size: 48)),
              const SizedBox(width: 6),
              Text('€', style: p.numeri(size: 22, color: p.testoSecondario)),
            ],
          ),
          if (residuo != null)
            Text(
              residuo.isNegative
                  ? l.dettaglio_budgetSforato(importo(s.budget!), importo(Money.zero - residuo))
                  : l.dettaglio_budgetDentro(importo(s.budget!), importo(residuo)),
              style: stileEtichetta(p, colore: p.coloreBudget(s.livelloBudget)),
            ),
          Sezione(l.chiusura_negozio),
          SceltaNegozio(
            valore: negozio,
            onCambia: (v) => unawaited(v == null ? _modifica(s, togliNegozio: true) : _modifica(s, negozio: v)),
          ),
          Sezione(l.chiusura_data),
          SceltaData(data: s.dataSpesa!, onCambia: (d) => unawaited(_modifica(s, data: d))),
          Sezione(s.fonte == FonteRighe.scontrino ? l.dettaglio_righeScontrino : l.dettaglio_righeContate),
          for (final r in principali) _Riga(riga: r),
          if (altre.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('dettaglio_altre'),
              onPressed: () => setState(() => _altre = !_altre),
              child: Text(
                _altre
                    ? l.dettaglio_nascondiAltre
                    : (s.fonte == FonteRighe.scontrino ? l.dettaglio_mostraContate : l.dettaglio_mostraScontrino),
              ),
            ),
            if (_altre) ...[
              Sezione(s.fonte == FonteRighe.scontrino ? l.dettaglio_righeContate : l.dettaglio_righeScontrino),
              for (final r in altre) _Riga(riga: r),
            ],
          ],
        ],
      ),
    );
  }
}

class _Riga extends StatelessWidget {
  const _Riga({required this.riga});

  final RigaSpesa riga;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final dettaglio = dettaglioRiga(riga);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nomeRiga(l, riga), style: TextStyle(color: p.testoLista, fontSize: 15)),
                if (dettaglio != null) Text(dettaglio, style: TextStyle(color: p.testoSecondario, fontSize: 12)),
              ],
            ),
          ),
          Text(importo(riga.totale), style: p.numeri(size: 16)),
        ],
      ),
    );
  }
}

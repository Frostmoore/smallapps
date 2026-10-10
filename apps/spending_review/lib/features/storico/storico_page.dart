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
import '../../data/database.dart' show Negozio;
import '../../domain/spesa.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/una_mano.dart';

/// Le spese chiuse (develop_microapps.md F12.1.12, `/storico`), raggruppate per mese («Ottobre
/// 2026 · 4 spese · 182,40 €»); per riga giorno, negozio (o «Senza negozio»), totale, pallino
/// ambra/rosso se il budget e' stato sforato o quasi.
///
/// ⚑ **Gratis: le ultime 5**, e in fondo la card «Le altre N spese sono sul telefono: con il Pro
/// le rivedi tutte, con le statistiche» → paywall (`fullHistory`). Le altre **non sono
/// cancellate** (risposta D1 del proprietario): le nasconde la lettura (`speseChiuseProvider`).
/// In alto l'icona **Statistiche** (badge PRO senza Pro).
class StoricoPage extends ConsumerWidget {
  const StoricoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final gate = ref.watch(featureGateProvider);
    final statistiche = gate.allows(FeatureKey.statistics);
    final spese = ref.watch(speseChiuseProvider).value ?? const <Spesa>[];
    final totali = ref.watch(numeroChiuseProvider).value ?? spese.length;
    final nascoste = gate.isPro ? 0 : (totali - spese.length).clamp(0, 1 << 30);
    final negozi = {for (final Negozio n in ref.watch(negoziProvider).value ?? const []) n.id: n.nome};
    final locale = Localizations.localeOf(context).toLanguageTag();

    // Raggruppate per mese, nell'ordine dello storico (data piu' recente prima).
    final gruppi = <(int, int), List<Spesa>>{};
    for (final s in spese) {
      final d = s.dataSpesa;
      if (d == null) continue;
      gruppi.putIfAbsent((d.year, d.month), () => []).add(s);
    }

    return PaginaUnaMano(
      titolo: l.storico_title,
      azioni: [
        IconButton(
          key: const ValueKey('storico_statistiche'),
          tooltip: l.statistiche_title,
          onPressed: () => statistiche
              ? unawaited(context.push(Routes.statistiche))
              : unawaited(showSrPaywall(context, ref, highlight: FeatureKey.statistics)),
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bar_chart),
              if (!statistiche) ...[const SizedBox(width: 4), const ProBadge(compact: true)],
            ],
          ),
        ),
      ],
      corpo: spese.isEmpty && nascoste == 0
          ? MicroEmptyState(
              key: const ValueKey('storico_vuoto'),
              icon: Icons.receipt_long_outlined,
              title: l.storico_vuotoTitolo,
              message: l.storico_vuotoTesto,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                for (final MapEntry(key: (anno, mese), value: lista) in gruppi.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
                    child: Semantics(
                      header: true,
                      child: Text(
                        l.storico_mese(
                          toBeginningOfSentenceCase(DateFormat.yMMMM(locale).format(DateTime(anno, mese))),
                          lista.length,
                          importo(Money.sum(lista.map((s) => s.totale))),
                        ),
                        style: stileEtichetta(p),
                      ),
                    ),
                  ),
                  for (final s in lista)
                    _RigaStorico(
                      spesa: s,
                      negozio: s.negozioId == null ? null : negozi[s.negozioId],
                      locale: locale,
                    ),
                ],
                if (nascoste > 0) ...[
                  const SizedBox(height: 16),
                  Material(
                    color: p.superficie,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      key: const ValueKey('storico_nascoste'),
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => unawaited(showSrPaywall(context, ref, highlight: FeatureKey.fullHistory)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, color: p.accento),
                            const SizedBox(width: 12),
                            Expanded(child: Text(l.storico_altre(nascoste))),
                            const SizedBox(width: 8),
                            const ProBadge(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _RigaStorico extends StatelessWidget {
  const _RigaStorico({required this.spesa, required this.negozio, required this.locale});

  final Spesa spesa;
  final String? negozio;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final d = spesa.dataSpesa!;
    final pallino = switch (spesa.livelloBudget) {
      LivelloBudget.sforato => p.rosso,
      LivelloBudget.vicino => p.ambraValore,
      _ => null,
    };
    return InkWell(
      key: ValueKey('storico_spesa_${spesa.id}'),
      onTap: () => unawaited(context.push(Routes.dettaglioDi(spesa.id!))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  Text('${d.day}', style: p.numeri(size: 20)),
                  Text(DateFormat.E(locale).format(d.toLocalMidnight()), style: TextStyle(fontSize: 11, color: p.testoSecondario)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                negozio ?? l.negozio_nessuno,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: negozio == null ? p.testoSecondario : p.testoLista, fontSize: 15),
              ),
            ),
            if (pallino != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Semantics(
                  label: spesa.sforata ? l.storico_sforata : l.storico_vicina,
                  child: Container(key: ValueKey('storico_pallino_${spesa.id}'), width: 10, height: 10, decoration: BoxDecoration(color: pallino, shape: BoxShape.circle)),
                ),
              ),
            Text(importo(spesa.totale), style: p.numeri(size: 18)),
          ],
        ),
      ),
    );
  }
}
